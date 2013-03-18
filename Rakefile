require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'time'
require 'data_mapper'
require 'dm-migrations'
require './lib/config.rb'
require './lib/parse_task.rb'

require './web/lib/game.rb'
require './web/lib/event.rb'
require './web/lib/player.rb'

task :run do
  config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")

	task = ParseTask.new(config)
	task.run
end

namespace :db do
  task :migrate do
    config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")

    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end
