class HomeController < ApplicationController
  
  def index
    today = Date.today
    redirect_to :controller => 'deals', :year => today.year, :month => today.month
  end
end
