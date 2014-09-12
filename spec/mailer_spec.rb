require 'rack/test'
require 'json'
require_relative '../mailer'

API_KEY = '123'
EMAIL = 'demo@test.it'

def app
  Sinatra::Application
end

describe 'Mailer' do
  include Rack::Test::Methods

  it 'should fail if there is no api key' do
    post '/send'
    body = JSON.parse last_response.body
    last_response.should_not be_ok
    body['message'].should match /api key not valid/i
  end

  it 'should fail silently if the body is not json' do
    post '/send', 'not % a & json', 'CONTENT_TYPE' => 'application/json'
    body = JSON.parse last_response.body
    last_response.should_not be_ok
    body['message'].should match /invalid json/i
  end

  it 'should fail if the api key is not correct' do
    post '/send', { api_key: 'wrongapi_key' }.to_json
    body = JSON.parse last_response.body
    last_response.should_not be_ok
    body['message'].should match /api key not valid/i
  end

  it 'should fail if the email is not correct' do
    post '/send', { api_key: API_KEY, email: 'wrongemail' }.to_json
    body = JSON.parse last_response.body
    last_response.should_not be_ok
    body['message'].should match /email not valid/i
  end

  it 'should fail if template is empty' do
    post '/send', { api_key: API_KEY, email: EMAIL, subject: 'blabla' }.to_json
    body = JSON.parse last_response.body
    last_response.should_not be_ok
    body['message'].should match /invalid template or subject/i
  end

  it 'should send an email' do
    post '/send', { api_key: API_KEY, email: EMAIL, template: 'blabla', subject: 'blabla' }.to_json
    body = JSON.parse last_response.body
    last_response.should be_ok
    body['ok'].should be true
  end

  it 'should correctly parse the template and send an email' do
    Pony.stub(:deliver)
    Pony.should_receive(:deliver) do |mail|
      mail.to.should == [ EMAIL ]
      mail.subject.should == 'this is the subject'
      mail.body.parts.first.body.include? 'Clark Kent'
    end
    post '/send', { api_key: API_KEY, email: EMAIL, template: 'Hello {{ name }}', subject: 'this is the subject', data: { name: 'Clark Kent' }}.to_json
    body = JSON.parse last_response.body
    last_response.should be_ok
    body['ok'].should be true
  end

end
