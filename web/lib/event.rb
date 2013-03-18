class FlatEvent

	attr_reader :type, :player, :time

	def initialize(player, type, time)
		@player, @type, @time = player, type, time
		@player.events << self
	end

	def to_s
		"#{@type} at #{@time}"
	end
end

class Event
	include DataMapper::Resource
	
	property :id, 			Serial
	property :game_id,	Integer
	property :player,		String
	property :type,			String
	property :time,			Integer
	property :name,			String
	property :team,			Integer

end
