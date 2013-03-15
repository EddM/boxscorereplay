require 'sinatra'
require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/boxscores')

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

