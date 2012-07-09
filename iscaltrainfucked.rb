#!/usr/bin/env ruby
require 'uri'
require 'json'
require 'pony'
require 'net/http'
require 'sinatra/base'
require File.dirname(__FILE__) + '/rediscache'

class HTTPServer < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  set :environment, :production

  def initialize
    super
    RedisCache.connect
  end

  error do
    # aww hell naw
    error = env['sinatra.error']
    @error_type = error.class.name
    @error_message = error.message
    @backtrace = error.backtrace.join("\n")

    views = File.dirname(__FILE__) + '/views'
    email_erb = ERB.new(File.read(views + '/email.html.erb'))
    email_body = email_erb.result(binding)

    Pony.mail(
      :to => 'tjarratt+crash@gmail.com',
      :from => 'do-not-reply@iscaltrainfucked.com',
      :subject => 'IsCaltrainFucked Broke',
      :body => body,
    )

    erb :error
  end

  def today_str
    now = Time.now
    [now.year, now.month, now.day].map(&:to_s).join('')
  end

  def today_regexp
    "^#{Time.now.to_s.split(' ').first}"
  end

  def json_feed_url
    URI.parse("http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=#{today_str}&events=1")
  end

  def json_feed
    req = Net::HTTP::Get.new(json_feed_url.request_uri)
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

  get '/' do
    @is_there_a_sports_today = RedisCache.get(today_str) do
      uri = json_feed_url
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(json_feed)
      end
      schedule = JSON[response.body]
      first_event = schedule['events']['game']
      is_sf = first_event['home_name_abbrev'] == 'SF'
      next_game_is_today = ! first_event['game_date'].match(today_regexp).nil?

      is_sf && next_game_is_today
    end

    erb :index
  end

  get '/*' do
    not_found
  end
end
