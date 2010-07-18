#! /usr/bin/env ruby

CONSUMER_KEY = 'dj0yJmk9aHd5dWwyY050WlllJmQ9WVdrOU4zVXlUVEJRTXpZbWNHbzlPVGMwTlRrMk16WXkmcz1jb25zdW1lcnNlY3JldCZ4PTY4'
CONSUMER_SECRET = '008221b626a980931f6b63877b4d6f2c8b681989'

require 'rubygems'
require 'haml'
require 'oauth'
require 'cgi'
require 'json' 
require 'sinatra'

require 'ruby-debug'

class TrackStatter
BASE_API_URL = "http://fantasysports.yahooapis.com/fantasy/v2/"
set :root, File.dirname(__FILE__)

get '/' do
	host = 'http://quiet-light-99.heroku.com/'
	host = 'http://localhost:4567/'
	$consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://api.login.yahoo.com/", :request_token_path => "/oauth/v2/get_request_token", :authorize_path => "/oauth/v2/request_auth", :oauth_callback => "#{host}callback", :access_token_path => "/oauth/v2/get_token")
	$request_token = $consumer.get_request_token({:oauth_callback => "#{host}callback/"})
	session[:request_token] = $request_token
	redirect $request_token.authorize_url({:oauth_callback => "#{host}callback/"})
end

get '*' do

	query = "leagues\;league_keys=238.l.173220"
	query = "users\;use_login=1/teams"


	begin
		$access_token = $request_token.get_access_token({:oauth_verifier => params["oauth_verifier"], :oauth_token => params["oauth_token"]})
		uri = BASE_API_URL + query + "\?format=json"
		resp = $access_token.get(uri)
	rescue Exception => 
		debugger
	end

	data = JSON.parse(resp.body)

	p data

	haml :json, :locals => {:data => data}
	
end
end
