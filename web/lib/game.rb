require 'nokogiri'
require 'time'

class Game
  include DataMapper::Resource

  property :id,         Serial
  property :home_team,  String
  property :away_team,  String
  property :bbref_key,  String
  property :slug,       String
  property :date,       DateTime
  property :quality,    Integer

  has n, :events

  attr_reader :players, :score

  def build_from_html(src = nil)
    @doc = Nokogiri::HTML(src)
    @players = [[], []]
    @events = []

    parse!
  end

  def insert_into_db(bbref_key)
    time = Time.parse(@date)
    slug = "#{time.month}#{time.day}-#{@team0}-#{@team1}".downcase.gsub(" ", "-")
    game = self.class.create(:home_team => @team1, :away_team => @team0, :date => @date, :bbref_key => bbref_key, :slug => slug)
    @events.each do |event|
      Event.create(:game_id => game.id, :player => event.player.id, :type => event.type, :time => event.time, :name => event.player.name, :team => event.player.team)
    end
  end

  def parse!
    period = 0
    header = @doc.css('h1').text.split(" Play-By-Play, ")
    @team0, @team1 = header[0].split(" at ")
    @date = header[1]
    table = @doc.css('table.no_highlight.stats_table').last
    events = table.css('tr').each do |tr|
      period += 1 if tr.text =~ /(start of)/i
      next unless tr.css('td').size == 6
      parse_row(tr, period)
    end
  end

  def assess!
    @score = 0
    fetch_events
    @score += 35 if overtime?
    @score += 20 if close_game?
    @score += 15 if high_shooting_pct?
    @score += 20 if very_high_scorer?
    high_scorers_bonus = (high_scorers * 5)
    high_scorers_bonus = 10 if high_scorers_bonus > 10
    @score += high_scorers_bonus
    
    self.quality = @score
    self.save
  end

  def parse_row(tr, period)
    cells = tr.css('td')
    timestamp = timestamp_to_integer(cells[0].content, period)

    parse_action(timestamp, cells[1],  0) if cells[1].text != " "
    parse_action(timestamp, cells[-1], 1) if cells[-1].text != " "
  end

  def parse_action(timestamp, cell, team)
    case cell.text
    when /defensive rebound/i
      reb(timestamp, cell, team, :d)
    when /offensive rebound/i
      reb(timestamp, cell, team, :o)
    when /makes 2-pt shot/i
      fga(timestamp, cell, team, true, 2)
    when /misses 2-pt shot/i
      fga(timestamp, cell, team, false, 2)
    when /makes 3-pt shot/i
      fga(timestamp, cell, team, true, 3)
    when /misses 3-pt shot/i
      fga(timestamp, cell, team, false, 3)
    when /makes free throw/i
      fta(timestamp, cell, team, true)
    when /makes technical free throw/i
      fta(timestamp, cell, team, true)
    when /misses free throw/i
      fta(timestamp, cell, team, false)
    when /turnover by/i
      to(timestamp, cell, team)
    when /foul by/i
      foul(timestamp, cell, team)
    end
  end

  def player_by_id(id)
    @players.flatten.select { |p| p.id == id }[0]
  end

  def player_by_element(element, team)
    return unless element
    id, name = player_id(element), element.text

    if player = @players.flatten.select { |p| p.id == id }[0]
      player
    else
      player = Player.new(name, id, team)
      @players[team] << player
      player
    end
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
  
  # private

  def reb(timestamp, cell, team, type = :o)
    player_link = cell.css('a')
    if player_link.size > 0 && player = player_by_element(player_link, team)
      @events << FlatEvent.new(player, :"#{type}reb", timestamp)
    end
  end

  def foul(timestamp, cell, team)
    return if cell.text =~ /technical/i
    if cell.text =~ /offensive foul by/i
      player = player_by_element(cell.css('a:first-of-type'), team)
    else
      player = player_by_element(cell.css('a:first-of-type').first, team == 1 ? 0 : 1)
    end

    @events << FlatEvent.new(player, :foul, timestamp) if player
  end

  def to(timestamp, cell, team)
    players = cell.css('a')
    if players.size > 1
      player = player_by_element(players[0], team)
      stealer = player_by_element(players[1], team == 1 ? 0 : 1)
      @events << FlatEvent.new(player, :to, timestamp)
      @events << FlatEvent.new(stealer, :stl, timestamp)
    elsif players.size == 1
      if player = player_by_element(players, team)
        @events << FlatEvent.new(player, :to, timestamp)
      end
    end
  end

  def fga(timestamp, cell, team, made = true, points = 2)
    players = cell.css('a')
    if players.size > 1
      scorer = player_by_element(players[0], team)
      @events << FlatEvent.new(scorer, :"fg#{made ? "m" : "a"}#{points}", timestamp)
      if cell.text =~ /assist/i
        other_player = player_by_element(players[1], team)
        @events << FlatEvent.new(other_player, :assist, timestamp)
      elsif cell.text =~ /block/i
        other_player = player_by_element(players[1], team == 1 ? 0 : 1)
        @events << FlatEvent.new(other_player, :block, timestamp)
      end
    else
      scorer = player_by_element(players, team)
      @events << FlatEvent.new(scorer, :"fg#{made ? "m" : "a"}#{points}", timestamp)
    end
  end

  def fta(timestamp, cell, team, made = true)
    player = player_by_element(cell.css('a'), team)
    @events << FlatEvent.new(player, :"ft#{made ? "m" : "a"}", timestamp)
  end

  def timestamp_to_integer(timestamp, period)
    mins, seconds = timestamp.split(".")[0].split(":").collect { |t| t.to_i }
    if period > 4
      2880 + ((4 - mins) * 60) + (60 - seconds)
    else
      ((11 - mins) * 60) + (60 - seconds) + ((period - 1) * 720)
    end
  end

  def player_id(element)
    element.attr('href').to_s.split("/")[-1].split(".")[0]
  end

  def fetch_events
    unless @team0_events && @team1_events
      @team0_events = self.events.all(:team => 0, :unique => true)
      @team1_events = self.events.all(:team => 1, :unique => true)
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
    most_points >= 30
  end

  def very_high_scorer?
    most_points >= 40
  end

  def high_scorers
    players_with_points.values.select { |pts| pts >= 30 }.size
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
