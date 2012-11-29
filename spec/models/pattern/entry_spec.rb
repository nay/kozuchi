# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Pattern::Entry do
  describe ".new" do
    it do
      expect{Pattern::Entry.new}.not_to raise_error
    end
  end
end
