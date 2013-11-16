require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'time'
require 'data_mapper'
require 'dm-migrations'
require './lib/config.rb'
require './lib/parse_task.rb'
require './lib/provider.rb'
require './lib/providers/nba.rb'
require './lib/providers/bbref.rb'
require './web/lib/game.rb'
require './web/lib/event.rb'
require './web/lib/player.rb'

# rake run
# rake run[24] # previous 24-hour offset
task :run, :offset do |t, args|
  args.with_defaults :offset => "0"
  config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")
  task = ParseTask.new(config, NBA)
  task.run(Time.now - (args.offset.to_i * 60 * 60))
end

task :assess do
  config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")
  DataMapper.finalize

  total = Game.count
  page_size = 10
  page = 0

  while (page * page_size) < total
    Game.all(:offset => page * page_size, :limit => page_size).each do |g| 
      g.assess!
    end
    
    page += 1
  end
end

namespace :db do
  task :migrate do
    require 'dm-migrations/migration_runner'
    require './config/migrations.rb'

    config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")
    DataMapper.finalize

    puts "Migrating database..."
    migrate_up!
  end

  task :backup do
    puts "Backing up database..."
    config = BSR::Config.new("#{File.dirname __FILE__}/config/database.json")
    dump_file = "./bsr_#{Time.now.to_i}_dump.sql.gz"
    cmd = "mysqldump --quick --single-transaction -u#{config.user}"
    cmd += " -p'#{config.password}'" if config.password
    cmd += " #{config.database} | gzip > #{dump_file}"
    `#{cmd}`
  end
end
