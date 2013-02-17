class HomeController < ApplicationController
  def index
    @is_there_a_sports_today = rand(2) == 1
    @whom = 'SF Giants'
  end
end
