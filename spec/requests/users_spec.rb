# -*- encoding : utf-8 -*-
require 'spec_helper'

describe UsersController do
  fixtures :users
  describe "GET /signup" do
    context "when not logged in" do
      before do
        visit '/signup'
      end
      it_behaves_like 'users/new'
    end
  end
end