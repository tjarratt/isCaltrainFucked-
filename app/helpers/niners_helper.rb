require 'httparty'
require 'ri_cal'

module NinersHelper
  def sf_49ers_play_today?(now)
    false
    # this is broken right now.
    #begin
    #  year = now.strftime('%Y')
    #  ics_url = "http://www.49ers.com/cda-web/schedule-ics-module.ics?year=#{year}"
    #  ics_file = HTTParty.get(ics_url)

    #  calendars = RiCal.parse_string(ics_file)
    #  calendars.each do |cal|
    #    cal.events.each do |event|
    #      event.occurrences.each do |e|
    #        start_time = e.start_time.to_time
    #        next unless start_time.day == now.day && start_time.month == now.month

    #        puts e.summary
    #        return e.summary.match /at San Francisco/
    #      end
    #    end
    #  end
    #rescue Exception => e
    #  puts "rescued an exception for sf_49ers_play_today"
    #  puts e.message
    #  puts e.backtrace.join("\n")
    #  return false
    #end
  end
end
