class NBA < Provider

  def run(initial_time = Time.now)
    @dateline = "#{initial_time.year}#{initial_time.month}#{initial_time.day-1}"
    url = "http://www.nba.com/gameline/#{@dateline}/"
    puts "+ Fetching #{url}"
    doc = Nokogiri::HTML open(url)
    parse_doc(doc)
  end

  def parse_doc(doc)
    games = doc.css('.GameLine')

    games.each do |game|
      unless game.css('.nbaLiveMnGame2').any?
        if link = game.css('a').select { |a| a.text =~ /recap/i && a.attr('href') =~ /gameinfo\.html/i }.first
          @key = "#{@dateline}_#{link.attr('href').split("/")[3].scan(/.{3}/).join("-")}"
          unless Game.count(:bbref_key => @key) > 0
            game_obj = game_from_url "http://www.nba.com#{link.attr('href')}"
            game_obj.provider = 'nba'
            game_obj.insert_into_db
            game_obj.assess!
          end
        end

        sleep(1)
      end
    end

  end

  private

  def game_from_url(url)
    @doc = Nokogiri::HTML open(url)
    @players = [[], []]
    @events = []

    period = 0
    @team0, @team1 = @doc.css('tr.nbaGIPBPTeams').first.text.chomp.gsub(/\s{2,}+/, "").split(/\(.*?\)/)

    table = @doc.css('#nbaGIPBP > table').last
    events = table.css('tr').each do |tr|
      period += 1 if tr.text =~ /(start of)/i
      next unless tr.css('td').size == 3
      parse_row(tr, period)
    end

    year, month, day = @dateline[0..3], @dateline[4..5], @dateline[6..7]
    game = Game.new(:home_team => @team1, :away_team => @team0, :bbref_key => @key, :date => Time.new(year, month, day))
    game.players = @players
    game.events = @events

    game
  end

  def parse_row(tr, period)
    cells = tr.css('td')
    timestamp = timestamp_to_integer(cells[1].content, period)

    parse_action(timestamp, cells[0], 0) if cells[0].text != " "
    parse_action(timestamp, cells[2], 1) if cells[2].text != " "
  end

  def parse_action(timestamp, cell, team)
    foul(timestamp, cell, team) if cell.text =~ /foul\:/i
    reb(timestamp, cell, team) if cell.text =~ /rebound/i
    ast(timestamp, cell, team) if cell.text =~ /assist/i
    blk(timestamp, cell, team) if cell.text =~ /block\:/i
    fga(timestamp, cell, team, true) if cell.text =~ /shot: made/i
    fga(timestamp, cell, team, false) if cell.text =~ /shot: missed/i
    fta(timestamp, cell, team) if cell.text =~ /free throw/i
    to(timestamp, cell, team) if cell.text =~ /turnover/i
    stl(timestamp, cell, team) if cell.text =~ /steal\:/i
  end

  # Events

  def to(timestamp, cell, team)
    return if cell.text =~ /team turnover/i
    player_name = cell.text.split(/turnover/i).first
    player = player_by_name(player_name, team)

    @events << FlatEvent.new(player, :to, timestamp)
  end

  def stl(timestamp, cell, team)
    player_name = cell.text.split(/steal\:/i).last.split(/\(/).first
    player = player_by_name(player_name, team == 1 ? 0 : 1)
    @events << FlatEvent.new(player, :stl, timestamp)
  end

  def ast(timestamp, cell, team)
    player_name = cell.text.split(/assist\:/i).last.split(/\(/).first
    player = player_by_name(player_name, team)

    @events << FlatEvent.new(player, :assist, timestamp)
  end

  def blk(timestamp, cell, team)
    player_name = cell.text.split(/block\:/i).last.split(/\(/).first
    player = player_by_name(player_name, team == 1 ? 0 : 1)

    @events << FlatEvent.new(player, :block, timestamp)
  end

  def fga(timestamp, cell, team, made = false)
    points = cell.text =~ /3pt/i ? 3 : 2
    player_name = cell.text.split(/((driving|pullup|turnaround|finger roll|step back|running|jump|putback|reverse|floating|alley oop|fadeaway|bank|layup|tip|(slam )?dunk|jump|3pt|hook)\s)+shot\: (made|missed)/i).first
    player = player_by_name(player_name, team)

    @events << FlatEvent.new(player, :"fg#{made ? "m" : "a"}#{points}", timestamp)
  end

  def fta(timestamp, cell, team)
    missed = cell.text =~ /missed/i
    player_name = cell.text.split(/free throw ?(technical|clear path)? ([0-3] of [0-3])?/i).first
    player = player_by_name(player_name, team)

    @events << FlatEvent.new(player, :"ft#{!missed ? "m" : "a"}", timestamp)
  end

  def foul(timestamp, cell, team)
    player_name = cell.text.split(/foul\:/i).first

    if cell.text =~ /offensive/i
      player = player_by_name(player_name, team)
    else
      player = player_by_name(player_name, team)
    end

    @events << FlatEvent.new(player, :foul, timestamp) if player
  end

  def reb(timestamp, cell, team)
    return if cell.text =~ /team rebound/i
    type = :d
    player_name = cell.text.split(/rebound/i).first
    player = player_by_name(player_name, team)

    @events << FlatEvent.new(player, :"#{type}reb", timestamp)
  end

  # Utility

  def player_by_name(name, team)
    name = name.chomp.strip
    id = player_id_from_name(name)

    if player = @players.flatten.select { |p| p.id == id }[0]
      player
    else
      player = Player.new(name, id, team)
      @players[team] << player
      player
    end
  end

  def player_id_from_name(name)
    name.downcase
  end

  def timestamp_to_integer(timestamp, period)
    mins, seconds = timestamp.split(".")[0].split(":").collect { |t| t.to_i }
    if period > 4
      2880 + ((4 - mins) * 60) + (60 - seconds)
    else
      ((11 - mins) * 60) + (60 - seconds) + ((period - 1) * 720)
    end
  end

end
