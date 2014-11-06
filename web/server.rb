require 'sinatra'
require 'sinatra/respond_to'
require 'sinatra/contrib'
require 'coffee-script'
require 'data_mapper'

require '../lib/config.rb'

config = BSR::Config.new("#{File.dirname __FILE__}/../config/database.json")
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")

require './lib/game.rb'
require './lib/event.rb'
require './lib/player.rb'

DataMapper.finalize

Sinatra::Application.register Sinatra::RespondTo
enable :sessions

before do
  unless params[:lets_bounce]
    @seen_animation = session[:seen_animation]
    session[:seen_animation] = true
  end
end

get '/' do
  @games = Game.all(:limit => 50, :order => [:date.desc])

  respond_to do |wants|
    wants.html { erb :index }
  end
end

get '/games' do
  @games = Game.all(:slug.not => nil, :limit => 50, :order => [:date.desc])

  @json_data = @games.map do |game|
    {
      "home_team" => game.home_team,
      "away_team" => game.away_team,
      "slug" => game.slug,
      "quality" => game.quality,
      "date" => game.date
    }
  end

  respond_to do |wants|
    wants.json { erb :games }
  end
end

get '/about' do
  @section = :about
  @page_title = "About"
  erb :about
end

get '/about/update-2013' do
  @section = :about
  @page_title = "About - 2013-14 Update"
  erb :update_2013
end

get '/assets/main' do
  coffee :main
end

get '/:id' do
  if @game = Game.first(:slug => params[:id].downcase)
    @seen_tutorial = cookies[:seen_tutorial]
    cookies[:seen_tutorial] = true

    @game_data = @game.to_json
    @page_title = "#{@game.away_team} @ #{@game.home_team}, #{@game.date.strftime("%D")}"

    respond_to do |wants|
      wants.html { erb :game }
      wants.json { erb :game }
    end
  else
    respond_to do |wants|
      wants.html { erb :game_not_found }
      wants.json { { :error => "Not found" } }
    end
  end
end
