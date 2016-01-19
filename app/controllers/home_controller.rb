class HomeController < ApplicationController
  include TwitterHelper
  include GiantsHelper
  include NinersHelper

  def index
    sentiment = twitter_sentiment
    now = Time.now
    if sf_giants_play_today?(now)
      @message = 'YEP'
      @description = 'Lousy SF Giants'
    elsif sf_49ers_play_today?(now)
      @message = 'YEP'
      @description = 'Lousy SF 49ers'
    elsif sentiment[:fatality]
      @message = 'YEP'
      @description = 'Someone was hit by a train'
    elsif sentiment[:delay]
      @message = 'YEP'
      @description = 'Trains are mad delayed, yo'
    elsif sentiment[:disruption]
      @message = 'YEP'
      @description = 'Trains are running late'
    elsif sentiment[:sum] <= -1
      @message = 'PROBABLY'
      @description = 'I hear the grumblings on twitter'
    elsif sentiment[:sum] >= 1
      @message = 'NOPE'
      @description = 'Everything seems fine and dandy'
    else
      @message = 'Maybe'
      @description = 'Hard to say.'
    end

    @tweets = sentiment[:tweets]
  end
end
