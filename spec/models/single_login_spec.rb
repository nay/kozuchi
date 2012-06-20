# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SingleLogin do
  describe "attributes=" do
    it "user_id は一括代入できない" do
      expect{SingleLogin.new(:user_id => 3)}.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end
    it "encrypted_passwordは一括代入できない" do
      expect{SingleLogin.new(:crypted_password => "xa12")}.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
    end
  end
end
