require 'net/http'
require 'rest-client'
require 'json'
require 'uri'
require 'rest-client'

module GiantsHelper
  def sf_giants_play_today?(now)
    begin
      uri = sf_giants_request_uri(today_str(now))
      response = RestClient.get uri

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
end
