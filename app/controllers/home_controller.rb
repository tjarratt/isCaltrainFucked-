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
    tweets = Twitter.search('caltrain',
      :count => 10,
      :recent_type => 'recent'
    ).results.map(&:text).map {|t| [t, analyzer.get_score(t)] }

    return {
      :tweets => tweets,
      :sum => tweets.map(&:last).inject(:+),
      :fatality => tweets.any? {|t| t.first.downcase.match(/fatal/) || t.first.downcase.match(/death/)},
      :disruption => tweets.any? {|t| t.first.downcase.match /disruption/ },
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
    return req
  end

  def sf_49ers_request_headers
    req = Net::HTTP::Get.new(sf_49ers.request_uri)
    req['Host'] = '49ers.com'
    req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.43 Safari/536.11'

    return req
  end

  def sf_49ers_request_uri
    @sf_49ers_uri ||= URI.parse('http://www.49ers.com/gameday/season-schedule.html')
  end

  def sf_giants_play_today?
    uri = sf_giants
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sf_giants_json_feed)
    end

    schedule = JSON[response.body]
    unless schedule && schedule['events'] && schedule['events']['game']
      return false
    end

    first_event = schedule['events']['game']
    is_sf = first_event['home_name_abbrev'] == 'SF'
    next_game_is_today = ! first_event['game_date'].match(today_regexp).nil?

    return is_sf && next_game_is_today
  end

  def sf_49ers_play_today?
    uri = sf_49ers_request_uri
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sf_49ers_request_headers)
    end

    # TODO
    # look for div.game-info containing div.item-date and div.stadium
    # check that the item-date is today and stadium is HOME

    return false
  end
end
