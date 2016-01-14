require 'uri'
require 'json'
require 'ri_cal'
require 'twitter'
require 'tzinfo'
require 'net/http'
require 'httparty'
require 'sentimental'

class HomeController < ApplicationController
  def index
    sentiment = twitter_sentiment
    if sf_giants_play_today?
      @message = 'YEP'
      @description = 'Lousy SF Giants'
    elsif sf_49ers_play_today?
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

    @whom = 'SF Giants'
  end

  def twitter_sentiment
    analyzer = Sentimental.new
    search_results = twitter_client.search('caltrain',
      :count => 10,
      :recent_type => 'recent',
    )
    search_results.attrs[:search_metadata][:next_results] = nil

    tweets = search_results.map(&:text).map {|t| [t, analyzer.get_score(t)] }

    return {
      :tweets => tweets,
      :sum => tweets.map(&:last).inject(:+),
      :fatality => tweets.any? {|t| t.first.downcase.match(/fatal/) || t.first.downcase.match(/death/)},
      :disruption => tweets.any? {|t| t.first.downcase.match /disruption/ },
      :delay => tweets.any? {|t| t.first.downcase.match /delay/ }
    }
  end

  def sf_giants_request_uri
    @sf_giants_uri ||= URI.parse("http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=#{today_str}&events=1")
  end

  def today_str
    now = Time.now
    [now.year, now.month, now.day].map(&:to_s).join('')
  end

  def today_regexp
    "^#{Time.now.to_s.split(' ').first}"
  end

  def sf_giants_json_feed
    req = Net::HTTP::Get.new(sf_giants_request_uri)
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

  def sf_giants_play_today?
    begin
      uri = sf_giants_request_uri
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
    rescue Exception => e
      puts "rescued an exception for sf_giants_play_today"
      puts e.message
      puts e.backtrace.join("\n")
      return false
    end
  end

  def sf_49ers_request_headers
    req = Net::HTTP::Get.new(sf_49ers_request_url)
    req['Host'] = '49ers.com'
    req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.43 Safari/536.11'
    req['Connecton'] = 'kee-alive'
    req['Referer'] = 'http://www.49ers.com'
    req['Accept-Language'] = 'en-US,en;q=0.8'
    req['Accept-Charset'] = 'ISO-8859-1,utf-8;q=0.7,*;q=0.3'
    req['Cache-Control'] = 'no-cache'
    req['Connection'] = 'keep-alive'
    req['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    req['Pragma'] = 'no-cache'
    req['DNT'] = 1
    req['Accept-Encoding'] = 'gzip,deflate,sdch'
    req['Accept-Language'] = 'en-US,en;q=0.8'
    req['Cookie'] = 'adblocker=true; s_nr=1377539027203; s_lastvisit=1377658086460; s_cc=true; s_gsc=1377661156929; s_sq=%5B%5BB%5D%5D'

    return req
  end

  def sf_49ers_play_today?
    begin
      year = Time.now.strftime('%Y')
      ics_url = "http://www.49ers.com/cda-web/schedule-ics-module.ics?year=#{year}"
      ics_file = HTTParty.get(ics_url)
      now = Time.now

      calendars = RiCal.parse_string(ics_file)
      calendars.each do |cal|
        cal.events.each do |event|
          event.occurrences.each do |e|
            start_time = e.start_time.to_time
            next unless start_time.day == now.day && start_time.month == now.month

            puts e.summary
            return e.summary.match /at San Francisco/
          end
        end
      end
    rescue Exception => e
      puts "rescued an exception for sf_49ers_play_today"
      puts e.message
      puts e.backtrace.join("\n")
      return false
    end
  end
end

def Time.get_zone(id)
  return TZInfo::Timezone.get('America/Los_Angeles')
end
