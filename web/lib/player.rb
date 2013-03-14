class Player
	attr_reader :name, :id, :team, :events

	def initialize(name, id, team)
		@name, @id, @team, @events = name, id, team, []
	end

	def to_s
		@name
	end
end