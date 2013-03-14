require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'data_mapper'
require 'dm-migrations'
require 'time'

require './web/lib/game.rb'
require './web/lib/event.rb'
require './web/lib/player.rb'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/boxscores')
DataMapper.finalize

class ParseTask

	def run
		puts "Starting at #{Time.now}"

		today = Time.now
		url = "http://www.basketball-reference.com/boxscores/index.cgi?month=#{today.month}&day=#{today.day}&year=#{today.year}"
		puts "Fetching #{url}"
		doc = Nokogiri::HTML open(url)
		sleep(2)
		parse_doc(doc)

		yesterday = Time.now - 86400 - 86400
		url = "http://www.basketball-reference.com/boxscores/index.cgi?month=#{yesterday.month}&day=#{yesterday.day}&year=#{yesterday.year}"
		puts "Fetching #{url}"
		doc = Nokogiri::HTML open(url)
		sleep(2)
		parse_doc(doc)

		puts "All done"
	end

	def parse_doc(doc)
		games = doc.css('#boxes > table table.stats_table')
		games.each do |table|
			if link = table.css('a').select { |a| a.text =~ /Play-by-Play/i }.first
				key = link.attr('href').split("/")[-1].split(".")[0]
				unless Game.count(:bbref_key => key) > 0
					game = Game.new
					url = "http://www.basketball-reference.com#{link.attr('href')}"
					puts "Fetching #{url}"
					game.build_from_html open(url)
					game.insert_into_db(key)
				end
			end
			sleep(3)
		end
	end

end
