# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Pattern::Deal do
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

  describe "udpate" do
    let(:deal_pattern) { FactoryGirl.create(:deal_pattern) }
    describe "code" do
      before do
        deal_pattern.code = 'NEWCODE'
      end
      it "変更できる" do
        deal_pattern.save.should be_true
        deal_pattern.reload
        deal_pattern.code.should == 'NEWCODE'
      end
    end
  end
end
