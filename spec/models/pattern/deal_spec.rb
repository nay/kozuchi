# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Pattern::Deal do
  describe ".new" do
    it do
      expect{Pattern::Deal.new}.not_to raise_error
    end
  end
end
