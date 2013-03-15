require 'data_mapper'
require 'dm-migrations'
require './parse.rb'

task :run do
	task = ParseTask.new
	task.run
end

namespace :db do
  task :migrate do
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, 'mysql://root@localhost/boxscores')

    require './web/lib/game.rb'
    require './web/lib/event.rb'
    require './web/lib/player.rb'

    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end
