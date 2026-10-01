require 'spec_helper'

describe VagueDate do
  describe ".new" do
    context "日を指定しないとき" do
      it "日のない年月になる" do
        expect(VagueDate.new(2026, 9).day).to be_nil
      end
    end

    context "日に空文字列を指定したとき" do
      it "日のない年月になる" do
        expect(VagueDate.new('2026', '9', '').day).to be_nil
      end
    end

    context "月にない日を指定したとき" do
      it "その月の近い日に直る" do
        expect(VagueDate.new(2026, 9, 31).day).to eq 30
        expect(VagueDate.new(2026, 9, 0).day).to eq 1
      end
    end
  end

  describe ".from" do
    it "VagueDate、Date、[年, 月]、[年, 月, 日] から作れる" do
      expect(VagueDate.from(VagueDate.new(2026, 9))).to eq VagueDate.new(2026, 9)
      expect(VagueDate.from(Date.new(2026, 9, 26))).to eq VagueDate.new(2026, 9, 26)
      expect(VagueDate.from([2026, 9])).to eq VagueDate.new(2026, 9)
      expect(VagueDate.from([2026, 9, 26])).to eq VagueDate.new(2026, 9, 26)
    end

    context "それ以外の値を渡したとき" do
      it "ArgumentError になる" do
        expect { VagueDate.from("2026-09") }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#to_date" do
    context "日があるとき" do
      it "その日の Date を返す" do
        expect(VagueDate.new(2026, 9, 26).to_date).to eq Date.new(2026, 9, 26)
      end
    end

    context "日がないとき" do
      it "NoDayError になる" do
        expect { VagueDate.new(2026, 9).to_date }.to raise_error(VagueDate::NoDayError)
      end
    end
  end

  describe "#range" do
    context "日があるとき" do
      it "その日だけの期間を返す" do
        expect(VagueDate.new(2026, 9, 26).range).to eq Date.new(2026, 9, 26)..Date.new(2026, 9, 26)
      end
    end

    context "日がないとき" do
      it "その月全体の期間を返す" do
        expect(VagueDate.new(2026, 9).range).to eq Date.new(2026, 9, 1)..Date.new(2026, 9, 30)
      end
    end
  end

  describe "#to_s と .parse" do
    it "日があれば年月日、なければ年月の文字列になり、その文字列から同じ値に戻せる" do
      [VagueDate.new(2026, 9, 26), VagueDate.new(2026, 9)].each do |vague_date|
        expect(VagueDate.parse(vague_date.to_s)).to eq vague_date
      end
      expect(VagueDate.new(2026, 9, 6).to_s).to eq "2026-09-06"
      expect(VagueDate.new(2026, 9).to_s).to eq "2026-09"
    end
  end
end
