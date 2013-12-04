require 'nokogiri'
require 'time'

class Game
  include DataMapper::Resource

  property :id,         Serial
  property :home_team,  String
  property :away_team,  String
  property :bbref_key,  String # not necessarily bbref any more
  property :slug,       String
  property :date,       DateTime
  property :quality,    Integer
  property :provider,   String

  has n, :events

  attr_reader :players, :score

  def players=(players)
    @players = players
  end

  def events=(events)
    @events = events
  end

  def insert_into_db
    slug = "#{@date.month}#{@date.day}-#{@away_team}-#{@home_team}".downcase.gsub(" ", "-")
    game = self.class.create(:home_team => @home_team, :away_team => @away_team, :date => @date, :bbref_key => @bbref_key, :slug => slug, :provider => @provider)
    @events.each do |event|
      Event.create(:game_id => game.id, :player => event.player.id, :type => event.type, :time => event.time, :name => event.player.name, :team => event.player.team)
    end

    game
  end

  def assess!
    @score = 0
    fetch_events
    @score += 40 if overtime?
    @score += 35 if close_game?
    @score += 5 if high_shooting_pct?
    @score += 10 if very_high_scorer?
    high_scorers_bonus = (high_scorers * 5)
    high_scorers_bonus = 10 if high_scorers_bonus > 10
    @score += high_scorers_bonus
    
    self.update(:quality => @score)
  end

  def to_json
    fetch_events

    team_strings = []
    players = [@team0_events.map { |p| Player.new(p.name, p.player, 0) }, @team1_events.map { |p| Player.new(p.name, p.player, 1) }]
    players.each do |team|
      str = team.map { |player| "\"#{player.id}\" : { \"name\" : \"#{player.name}\", \"team\" : #{player.team} }" }.join(",")
      team_strings << "{ #{str} }"
    end

    events_string = events.all.map { |event| "{ \"player\" : \"#{event.player}\", \"type\" : \"#{event.type}\", \"time\" : #{event.time}, \"team\" : #{event.team} }" }
    "{ \"teams\" : [\"#{away_team}\", \"#{home_team}\"], \"players\" : [#{team_strings.join(',')}], \"events\" : [#{events_string.join(',')}] }"
  end

  def day
    Time.new(date.year, date.month, date.day)
  end

  def fetch_events
    unless @team0_events && @team1_events
      @team0_events = Event.all(:game_id => self.id, :team => 0, :unique => true)
      @team1_events = Event.all(:game_id => self.id, :team => 1, :unique => true)
    end
  end

  def close_game?
    team0_score = @team0_events.reduce(0) do |score, event|
      score + value = case event.type.to_sym
        when :ftm then 1
        when :fgm then 2
        when :fgm3 then 3
        else 
          0
      end
    end

    team1_score = @team1_events.reduce(0) do |score, event|
      score + value = case event.type.to_sym
        when :ftm then 1
        when :fgm then 2
        when :fgm3 then 3
        else 
          0
      end
    end

    (team0_score - team1_score).abs <= 5
  end

  def overtime?
    @team0_events.any? { |e| e.time > 2880 }
  end

  def players_with_points
    return @players_with_points if @players_with_points
    values = {}

    (@team0_events + @team1_events).each do |event|
      value = case event.type.to_sym
        when :ftm then 1
        when :fgm2 then 2
        when :fgm3 then 3
      end

      values[event.player] ||= 0
      values[event.player] += value if value
    end

    @players_with_points = values
  end

  def most_points
    players_with_points.values.max
  end

  def high_scorer?
    most_points.to_i >= 30
  end

  def very_high_scorer?
    most_points.to_i >= 40
  end

  def high_scorers
    players_with_points.values.select { |pts| pts >= 25 }.size
  end

  def high_shooting_pct?
    players_with_shooting_pct = {}

    (@team0_events + @team1_events).each do |event|
      type = event.type.to_sym
      players_with_shooting_pct[event.player] ||= { :fga => 0, :fgm => 0, :pct => 0 }

      players_with_shooting_pct[event.player][:fga] += 1 if type == :fga2 || type == :fga3
      if type == :fgm2 || type == :fgm3
        players_with_shooting_pct[event.player][:fgm] += 1
        players_with_shooting_pct[event.player][:fga] += 1
      end

      if players_with_shooting_pct[event.player][:fgm] > 0 && players_with_shooting_pct[event.player][:fga] > 0
        players_with_shooting_pct[event.player][:pct] = (players_with_shooting_pct[event.player][:fgm] / players_with_shooting_pct[event.player][:fga].to_f)
      end
    end

    players_with_shooting_pct.values.any? { |v| v[:pct] >= 0.825 && v[:fga] >= 12 }    
  end

end
