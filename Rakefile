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
