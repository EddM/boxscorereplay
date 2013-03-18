class ParseTask

  def initialize(config)
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")
    DataMapper.finalize
  end

  def run
    puts "Starting at #{Time.now}"

    today = Time.now
    url = "http://www.basketball-reference.com/boxscores/index.cgi?month=#{today.month}&day=#{today.day}&year=#{today.year}"
    puts "Fetching #{url}"
    doc = Nokogiri::HTML open(url)
    sleep(2)
    parse_doc(doc)

    yesterday = Time.now - 86400 #- 86400
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
          begin
            game = Game.new
            url = "http://www.basketball-reference.com#{link.attr('href')}"
            puts "Fetching #{url}"
            game.build_from_html open(url)
            game.insert_into_db(key)
          rescue => e
            puts "*** Failed for #{key}"
            puts e.inspect
            puts e.backtrace
          end
        end
      end
      sleep(3)
    end
  end

end
