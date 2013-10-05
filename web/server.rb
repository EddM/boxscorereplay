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
  @page_title = "About"
  erb :about
end

get '/:id' do
  if @game = Game.first(:slug => params[:id].downcase)
    @game_data = @game.to_json
    @page_title = "#{@game.away_team} @ #{@game.home_team}, #{@game.date.strftime("%D")}"
    erb :game
  else
    erb :game_not_found
  end
end
