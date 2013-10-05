require 'sinatra'
require 'sinatra/contrib'
require 'data_mapper'
require '../lib/config.rb'

config = BSR::Config.new("#{File.dirname __FILE__}/../config/database.json")
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")

require './lib/game.rb'
require './lib/event.rb'
require './lib/player.rb'

DataMapper.finalize

enable :sessions

before do
  @seen_animation = session[:seen_animation]
  session[:seen_animation] = true
end

get '/' do
  @games = Game.all(:limit => 50, :order => [:date.desc])
  erb :index
end

get '/about' do
  @section = :about
  erb :about
end

get '/:id' do
  if @game = Game.first(:slug => params[:id])
    @game_data = @game.to_json
    erb :game
  else
    erb :game_not_found
  end
end
