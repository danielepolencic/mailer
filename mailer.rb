require 'sinatra'
require 'sinatra/json'
require 'liquid'
require 'liquid_blocks'
require 'pony'
require 'mail'
require 'json'
require 'multi_json'
require './config.rb'

before do
  begin
    if request.body.size > 0
      request.body.rewind
      @params = JSON.parse request.body.read, :symbolize_names => true
    end
  rescue Exception => e
    halt 500, {'Content-Type' => 'application/json'}, {:ok => false, :message => "Invalid JSON. Error #{ e.to_s.force_encoding('ISO-8859-1') }"}.to_json
  end
end

before '/send' do
  unless params[:api_key] && ( /#{settings.api_key}/.match params[:api_key] )
    halt 403, {'Content-Type' => 'application/json'}, {:ok => false, :message => 'API KEY not valid.'}.to_json
  end
end

get '/' do
  erb :usage
end

post '/send' do

  unless validEmail?( params[:email] )
    status 403
    return json :ok => false, :message => 'Email not valid.'
  end

  if params[:template].nil? || params[:subject].nil?
    status 403
    return json :ok => false, :message => 'Invalid template or subject.'
  end

  html = liquid params[:template], :locals => params[:data] || {}
  text = if params[:text] then params[:text] else html end

  begin
    Pony.mail(
      :from => "#{ params[:from_name] } <#{ params[:from_email] }>",
      :to => "#{ params[:email] }",
      :subject => "#{ params[:subject] }",
      :body => text,
      :html_body => html,
      :port => '587',
      :via => settings.mail_settings[:via],
      :via_options => settings.mail_settings[:via_options])
  rescue Exception => e
    status 403
    return json :ok => false, :message => "#{ e.to_s }"
  end

  json :ok => true

end

def validEmail?( email )
  begin
   return false if email == ''
   parsed = Mail::Address.new( email )
   return parsed.address == email && parsed.local != parsed.address
  rescue Mail::Field::ParseError
    return false
  end
end
