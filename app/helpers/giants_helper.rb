require 'net/http'
require 'json'
require 'uri'

module GiantsHelper
  def sf_giants_play_today?(now)
    begin
      uri = sf_giants_request_uri(today_str(now))
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(json_feed(uri))
      end

      schedule = JSON[response.body]
      unless schedule && schedule['events'] && schedule['events']['game']
        return false
      end

      first_event = schedule['events']['game']
      is_sf = first_event['home_name_abbrev'] == 'SF'

      today_regexp = "^#{now.to_s.split(' ').first}"

      next_game_is_today = ! first_event['game_date'].match(today_regexp).nil?

      return is_sf && next_game_is_today
    rescue Exception => e
      puts "rescued an exception for sf_giants_play_today"
      puts e.message
      puts e.backtrace.join("\n")
      return false
    end
  end

  private

  def today_str(now)
    [now.year, now.month, now.day].map(&:to_s).join('')
  end

  def sf_giants_request_uri(today_str)
    URI.parse("http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=#{today_str}&events=1")
  end

  def json_feed(giants_uri)
    req = Net::HTTP::Get.new(giants_uri)
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
end
