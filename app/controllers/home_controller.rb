require 'uri'
require 'json'
require 'twitter'
require 'net/http'
require 'sentimental'

class HomeController < ApplicationController
  def index
    is_there_a_sports_today = sf_giants_play_today?
    sentiment = twitter_sentiment
    if is_there_a_sports_today
      @message = 'YEP'
      @description = 'Lousy SF Giants'
    elsif sentiment[:fatality]
      @message = 'YEP'
      @description = 'Someone was hit by a train'
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

    @whom = 'SF Giants'
  end

  def twitter_sentiment
    analyzer = Sentimental.new
    tweets = Twitter.search('caltrain', :count => 10, :recent_type => 'recent').results.map(&:text)
    sentiments = tweets.map {|t| puts t.inspect; val = analyzer.get_score(t); puts val.inspect; val }.inject(:+)

    return {
      :tweets => tweets,
      :sum => sentiments,
      :fatality => tweets.any? {|t| t.downcase.match(/fatality/) || t.downcase.match(/death/)},
      :disruption => tweets.any? {|t| t.downcase.match /disruption/ },
    }
  end

  def sf_giants
    URI.parse("http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=#{today_str}&events=1")
  end

  def today_str
    now = Time.now
    [now.year, now.month, now.day].map(&:to_s).join('')
  end

  def today_regexp
    "^#{Time.now.to_s.split(' ').first}"
  end

  def sf_giants_json_feed
    req = Net::HTTP::Get.new(sf_giants.request_uri)
    req['Host'] = "sanfrancisco.giants.mlb.com" # hax
    req['Connection'] = 'keep-alive'
    req['X-Requested-With'] = 'XMLHttpRequest'
    req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.43 Safari/536.11'
    req['Accept'] = 'application/json, text/javascript, */*; q=0.01'
    req['Referer'] = 'http://sanfrancisco.giants.mlb.com/schedule/index.jsp?c_id=sf'
    req['Accept-Language'] = 'en-US,en;q=0.8'
    req['Accept-Charset'] = 'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
    req['Cookie'] = 's_vi=[CS]v1|27F91CFF85013AB4-4000010960456750[CE]; stUtil_cookie=1%7C%7C1910263221341274622649; s_cc=true; s_sq=%5B%5BB%5D%5D'
    req
  end

  def sf_giants_play_today?
    uri = sf_giants
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sf_giants_json_feed)
    end

    schedule = JSON[response.body]
    first_event = schedule['events']['game']
    is_sf = first_event['home_name_abbrev'] == 'SF'
    next_game_is_today = ! first_event['game_date'].match(today_regexp).nil?

    return is_sf && next_game_is_today
  end

  # todo: add support for 49ers
  # fetch http://www.49ers.com/gameday/season-schedule.html
  # look for div.game-info containing div.item-date and div.stadium
  # check that the item-date is today and stadium is HOME
end
