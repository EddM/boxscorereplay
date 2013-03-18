require 'sinatra'
require 'data_mapper'
require '../lib/config.rb'

config = BSR::Config.new("#{File.dirname __FILE__}/../config/database.json")
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")

require './lib/game.rb'
require './lib/event.rb'
require './lib/player.rb'

DataMapper.finalize

get '/' do
	@games = Game.all(:limit => 50, :order => [:date.desc])
	erb :index
end

get '/about' do
	erb :about
end

get '/:id' do
	@game = Game.first(:slug => params[:id])
	@game_data = @game.to_json
	erb :game
end

