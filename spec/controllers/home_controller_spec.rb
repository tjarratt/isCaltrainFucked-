require 'rails_helper'

RSpec.describe HomeController, :type => :controller do
  describe 'GET #index' do
    before do
      get :index
    end

    it 'responds successfully with HTTP 200' do
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it 'renders the index template' do
      expect(response).to render_template('index')
    end

    it 'assigns a default value' do
      expect(assigns(:message)).to eq('Maybe')
      expect(assigns(:description)).to eq('Hard to say.')
    end
  end
end
