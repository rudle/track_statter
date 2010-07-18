#! /usr/bin/env ruby

CONSUMER_KEY = 'dj0yJmk9aHd5dWwyY050WlllJmQ9WVdrOU4zVXlUVEJRTXpZbWNHbzlPVGMwTlRrMk16WXkmcz1jb25zdW1lcnNlY3JldCZ4PTY4'
CONSUMER_SECRET = '008221b626a980931f6b63877b4d6f2c8b681989'

require 'rubygems'
require 'oauth'
require 'oauth/client/em_http'
require 'em-http'
require 'cgi'
require 'ruby-debug'
require 'sinatra'
require 'rest-client'

BASE_API_URL = "https://fantasysports.yahooapis.com/fantasy/v2/"

get '/' do
	$consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://api.login.yahoo.com/", :request_token_path => "/oauth/v2/get_request_token", :authorize_path => "/oauth/v2/request_auth", :oauth_callback => "http://localhost:4567/callback", :access_token_path => "/oauth/v2/get_token")
	$request_token = $consumer.get_request_token({:oauth_callback => "http://localhost:4567/callback/"})
	session[:request_token] = $request_token
	redirect $request_token.authorize_url({:oauth_callback => "http://localhost:4567/callback/"})
end

get '*' do
	#{"splat"=>["/callback"], "oauth_verifier"=>"btkxte", "oauth_token"=>"evfhecf"}
#http://fantasysports.yahooapis.com/fantasy/v2/leagues;league_keys=238.l.627060]
	#http://fantasysports.yahooapis.com/fantasy/v2/leagues;league_keys=238.l.173220
	#$consumer.options[:site] = "http://fantasysports.yahooapis.com/fantasy/v2/"

	query = ("/leagues;league_keys=238.l.173220")

	$access_token = $request_token.get_access_token({:oauth_verifier => params["oauth_verifier"], :oauth_token => params["oauth_token"]}, :request_uri => BASE_API_URL  + query)


	response = $access_token.get("/")

	puts "hello"
end

