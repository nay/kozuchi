# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Pattern::Deal do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base
  
  describe ".new" do
    it do
      expect{Pattern::Deal.new}.not_to raise_error
    end
  end

  describe "#to_s" do
    context "with code and name" do
      let(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => 'SALARY', :name => '給与') }
      subject {deal_pattern.to_s}

      it { should == 'SALARY 給与'}
    end

    context "with name and without code" do
      let(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => nil, :name => '給与') }
      subject {deal_pattern.to_s}

      it { should == '給与'}
    end

    context "with code and without name" do
      let(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => 'SALARY', :name => '') }
      subject {deal_pattern.to_s}

      it { should == 'SALARY *給料'}
    end

    context "without code and name" do
      let(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => nil, :name => '') }
      subject {deal_pattern.to_s}

      it { should == '*給料'}
    end
  end

  describe "#assignable_attributes" do
    let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :overwrites_code => '1') }
    subject{deal_pattern.assignable_attributes.keys}
    it "column のほか、summary_mode と summaryも含まれる" do
      should be_include('name') # column代表で

      should be_include('summary_mode')
      should be_include('summary')

      should be_include('debtor_entries_attributes')
      should be_include('creditor_entries_attributes')
    end
  end

  describe "#overwrites_code?" do
    context "overwrites_code が '1' のとき" do
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :overwrites_code => '1') }
      it { deal_pattern.overwrites_code?.should be_truthy }
    end
    context "overwrites_code が nil のとき" do
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :overwrites_code => nil) }
      it { deal_pattern.overwrites_code?.should be_falsey }
    end
    context "overwrites_code が '0' のとき" do
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :overwrites_code => '0') }
      it { deal_pattern.overwrites_code?.should be_falsey }
    end
  end

  describe "create" do
    context "空のコード" do
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => '', :name => 'TEST PATTERN 2') }
      it "空のコードを保存するとコードはNULLになる" do
        deal_pattern.save.should be_truthy
        deal_pattern.code.should be_nil
        deal_pattern.reload
        deal_pattern.code.should be_nil
      end
      it "検証なしで空のコードを保存してもコードはNULLになる" do
        deal_pattern.save(:validate => false).should be_truthy
        deal_pattern.code.should be_nil
        deal_pattern.reload
        deal_pattern.code.should be_nil
      end
    end
    describe "コードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN') }
      context "大文字小文字の異なる重複コードが登録されており、overwrites_codeが指定されていないとき" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'codeX', :name => 'TEST PATTERN 2') }
        it do
          deal_pattern.save.should be_truthy
        end
      end
      context "重複コードが登録されており、overwrites_codeが指定されているとき" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN 2', :overwrites_code => '1') }
        it "saveできる" do
          deal_pattern.save.should be_truthy
          deal_pattern.id.should == existing.id
          deal_pattern.debtor_entries.size.should == 2
          deal_pattern.creditor_entries.size.should == 1
          deal_pattern.reload
          deal_pattern.id.should == existing.id
          deal_pattern.debtor_entries.size.should == 2
          deal_pattern.creditor_entries.size.should == 1
        end
      end
    end
  end

  describe "#prepare_overwrite" do
    describe "コードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN') }
      context "登録時" do
        context "重複コードが登録されており、overwrites_codeが指定されているとき" do
          let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN 2', :overwrites_code => '1') }
          it "id が変更され、編集内容が反映される" do
            deal_pattern.prepare_overwrite.should be_truthy
            deal_pattern.id.should == existing.id # 既存のものを更新しようとする状態になる
            deal_pattern.debtor_entries.not_marked.size.should == 2
            deal_pattern.creditor_entries.not_marked.size.should == 1
          end
        end
      end
      context "更新時" do
        context "重複コードが登録されており、overwrites_codeが指定されているとき" do
          let(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => 'CODEZ', :name => 'ANOTHER TEST PATTERN') }
          before do
            deal_pattern.code = 'CODEX' # 既存のものに変更
            deal_pattern.overwrites_code = '1'
          end
          it "id が変更され、編集内容が反映される" do
            deal_pattern.prepare_overwrite.should be_truthy
            deal_pattern.id.should == existing.id # 既存のものを更新しようとする状態になる
            deal_pattern.debtor_entries.not_marked.size.should == 2
            deal_pattern.creditor_entries.not_marked.size.should == 1
          end
        end
      end
    end
    describe "NULLコードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => nil, :name => 'TEST PATTERN') }
      context "２つめのNULLコードが上書き指定で登録される場合" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => nil, :name => 'TEST PATTERN 2', :overwrites_code => '1') }
        it "上書きにならない" do
          deal_pattern.save.should be_truthy
          deal_pattern.id.should_not == existing.id
        end
      end
    end
  end

  describe "udpate" do
    let(:deal_pattern) { FactoryGirl.create(:deal_pattern) }
    describe "code" do
      before do
        deal_pattern.code = 'NEWCODE'
      end
      it "変更できる" do
        deal_pattern.save.should be_truthy
        deal_pattern.reload
        deal_pattern.code.should == 'NEWCODE'
      end
      it "コードを空文字列にするとNULLになる" do
        deal_pattern.code = ''
        deal_pattern.save.should be_truthy
        deal_pattern.code.should be_nil
        deal_pattern.reload
        deal_pattern.code.should be_nil
      end

    end
    describe "コードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN') }
      context "重複コードが登録されており、overwrites_codeが指定されているとき" do
        let!(:deal_pattern) { FactoryGirl.create(:deal_pattern, :code => 'CODEZ', :name => 'ANOTHER TEST PATTERN') }
        let!(:old_id) {deal_pattern.id}
        before do
          deal_pattern.code = 'CODEX'
          deal_pattern.overwrites_code = '1'
        end
        it "saveでき、もとのオブジェクトが削除される" do
          deal_pattern.save.should be_truthy
          deal_pattern.id.should == existing.id
          deal_pattern.debtor_entries.size.should == 2
          deal_pattern.creditor_entries.size.should == 1
          deal_pattern.reload
          deal_pattern.id.should == existing.id
          deal_pattern.debtor_entries.size.should == 2
          deal_pattern.creditor_entries.size.should == 1
          Pattern::Deal.find_by(id: old_id).should be_nil
        end
      end
    end
  end

  describe "#valid?" do
    context "Entryがないとき" do
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :debtor_entries_attributes => [], :creditor_entries_attributes => []) }
      it do
        deal_pattern.should_not be_valid
      end
    end
    describe "コードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN') }
      context "重複したコードが登録されており、overwrites_codeが指定されていないとき" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN 2') }
        it do
          deal_pattern.should_not be_valid
        end
      end
      context "大文字小文字の異なる重複コードが登録されており、overwrites_codeが指定されていないとき" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'codeX', :name => 'TEST PATTERN 2') }
        it do
          deal_pattern.should be_valid
        end
      end
      context "重複したコードが登録されており、overwrites_codeが指定されているとき" do
        let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => 'CODEX', :name => 'TEST PATTERN 2', :overwrites_code => '1') }
        it do
          deal_pattern.should be_valid
        end
      end
    end
    describe "NULLコードの重複" do
      let!(:existing) { FactoryGirl.create(:deal_pattern, :code => nil, :name => 'TEST PATTERN') }
      let(:deal_pattern) { FactoryGirl.build(:deal_pattern, :code => nil, :name => 'TEST PATTERN 2') }

      it "２つめのNULLコードが検証エラーとならない" do
        deal_pattern.should be_valid
      end
    end

  end
end
