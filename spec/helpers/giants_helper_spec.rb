require 'rails_helper'
require 'rest-client'

RSpec.describe GiantsHelper, type: :helper do
  describe 'sf_giants_play_today?' do
    it 'returns true if the giants are playing at all today' do
      now = Time.utc(2016,"mar",2,4,10,0)

      response = IO.read("spec/helpers/giants_response.json")
      giants_playing_response = instance_double('RestClient::Response', body: response)

      allow(RestClient).to receive(:get).and_return(giants_playing_response)
      expect(RestClient).to receive(:get).with(URI.parse('http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=201632&events=1'))

      expect(helper.sf_giants_play_today?(now)).to be_truthy

    end

    it 'returns false if the giants are not playing today' do
      now = Time.utc(2016,"feb",2,4,10,0)

      response = IO.read("spec/helpers/giants_response.json")
      giants_playing_response = instance_double('RestClient::Response', body: response)

      allow(RestClient).to receive(:get).and_return(giants_playing_response)
      expect(RestClient).to receive(:get).with(URI.parse('http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=201622&events=1'))

      expect(helper.sf_giants_play_today?(now)).to be_falsy
    end

    it 'returns false if we receive bad data from the network' do
      now = Time.utc(2016,"feb",2,4,10,0)

      giants_playing_response = instance_double('RestClient::Response', body: '')

      allow(RestClient).to receive(:get).and_return(giants_playing_response)
      expect(RestClient).to receive(:get).with(URI.parse('http://sanfrancisco.giants.mlb.com/ticketing-client/json/Game.tiksrv?team_id=137&site_section=SCHEDULE&sport_id=1&start_date=201622&events=1'))

      expect(helper.sf_giants_play_today?(now)).to be_falsy

    end

    it 'returns false if we received network error' do
      now = Time.now
      giants_playing_yesterday_response = instance_double('RestClient::Response', body: '')
      allow(RestClient).to receive(:get).and_throw(:sad)

      expect(helper.sf_giants_play_today?(now)).to be_falsy
    end
  end
end
