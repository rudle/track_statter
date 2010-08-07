#! /usr/bin/env ruby

CONSUMER_KEY = 'dj0yJmk9aHd5dWwyY050WlllJmQ9WVdrOU4zVXlUVEJRTXpZbWNHbzlPVGMwTlRrMk16WXkmcz1jb25zdW1lcnNlY3JldCZ4PTY4'
CONSUMER_SECRET = '008221b626a980931f6b63877b4d6f2c8b681989'

require 'rubygems'
require 'active_support'
require 'haml'
require 'oauth'
require 'cgi'
require 'json' 
require 'sinatra'

require 'ruby-debug'

BASE_API_URL = "http://fantasysports.yahooapis.com/fantasy/v2/"
#set :root, File.dirname(__FILE__)

def output_stats stats, stat_info
	stats.map do |stat|
		id = stat['stat']['stat_id']
		info = stat_info[id].first['stat']
		{:name => info['display_name'], :value => stat['stat']['value']}.to_json
	end
end

def league_teams
	"league/#{@league_key}/teams"
end

def team_roster
	"team/#{@team_key}/roster"
end

def updated_team_stats
	old_stats = team_stats(true)
	new_stats = team_stats

	stats = old_stats.inject([]) do |stats, stat| 
		stat_id = stat['stat']['stat_id']

		stats[stat_id] = combine_stats(new_stats.find {|stat| stat['stat']['stat_id'] == stat_id }['stat']['value'], stat['stat']['value'])
	end

end

def combine_stats new, old, id
	case id
		when (7 or 12 or 13 or 16 or 50 or 28 or 32 or 42)
			new + old
		when 60 # H/AB
			new = new.split("/")
			old = old.split("/")
			"#{new.first + old.first} / #{new.last + old.last}"
		when 3 # AVG
			@stats
		when 26 # ERA
			#TODO get IPs 
			
		end
end

def team_stats include_today = false
	make_query("team/#{@team_key}/stats;type=date;date=" + (include_today ? Time.now.strftime("%Y-%m-%d") : 1.day.ago.strftime("%Y-%m-%d")))['fantasy_content']['team'].last['team_stats']['stats'].sort_by {|stat| stat['stat']['stat_id'] }
end

def scoring_settings
	"league/#{@league_key}/settings"
end

def player_stats player_key, score_settings
	query = "player/#{player_key}/stats\;type\=date\;date=#{Time.now.strftime("%Y-%m-%d")}/\?format=json"
	resp = make_query query

	league_stat_ids = score_settings.map {|score| score['stat']['stat_id'] }
	player_stats = resp['fantasy_content']['player'].last['player_stats']['stats']
	good_stats = player_stats.select {|stat| league_stat_ids.include? stat['stat']['stat_id'].to_i }
end

def scoreboard
	@scoreboard ||= make_query "league/#{@league_key}/standings\;type=date\;date=#{Time.now.strftime("%Y-%m-%d")}"
end

def user_teams
	"users\;use_login=1/games\;game_keys=mlb/teams" 
end

def user_leagues
	"users\;use_login=1/games\;game_keys=mlb/leagues"
end

def make_query q
	begin
		ret = JSON.parse($access_token.get("#{BASE_API_URL + q}?format=json").body)
	rescue Exception => e
		debugger
	end

	ret
end

get '/' do
	host = 'trackstatter.heroku.com/'
	#host = 'http://localhost:4567/'
	$consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://api.login.yahoo.com/", :request_token_path => "/oauth/v2/get_request_token", :authorize_path => "/oauth/v2/request_auth", :oauth_callback => "#{host}callback", :access_token_path => "/oauth/v2/get_token")
	$request_token = $consumer.get_request_token({:oauth_callback => "#{host}callback/"})
	session[:request_token] = $request_token
	redirect $request_token.authorize_url({:oauth_callback => "#{host}callback/"})
end

get '/callback' do
	$access_token = $request_token.get_access_token({:oauth_verifier => params["oauth_verifier"], :oauth_token => params["oauth_token"]})

	team_blob =  make_query user_teams
	league_blob = make_query user_leagues

user_leagues = league_blob['fantasy_content']['users']['0']['user'][1]['games']['0']['game'].last['leagues']

	@leagues = (0..user_leagues['count'] - 1).map do |user_league_id|
		league = user_leagues[user_league_id.to_s]['league'].first
		{league['league_key'] => league['name']}
	end

	user_teams = team_blob['fantasy_content']['users']['0']['user'][1]['games']['0']['game'].last['teams']

	@teams = (0..user_teams['count'] - 1).map do |user_team_id|
		user_teams[user_team_id.to_s]
	end
	haml :team_list
end

get '/team/*' do |team_key|
	@team_key = team_key 
	@league_key = team_key.match(/(.*)\.t/)[1]

	teams = make_query league_teams
	scores = make_query scoring_settings

	full_stats = team_stats

	todays_stats = team_stats(true) - team_stats(false)

	debugger
	#data['fantasy_content']['users']['0']['user'].last['teams']['2']['team'].join("<br/>")
	stat_categories = scores['fantasy_content']['league'][1]['settings'].first['stat_categories']['stats'].group_by { |stat| stat['stat']['stat_id'] }

	todays_stats.to_json
	output_stats(todays_stats, stat_categories).join("<br/>")
end
