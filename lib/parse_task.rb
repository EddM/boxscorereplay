class ParseTask

  def initialize(config, provider)
    @provider = provider.new
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, "mysql://#{config.user}@#{config.host}/#{config.database}")
    DataMapper.finalize
  end

  def run(today = Time.now)
    puts "Starting parse (provider: #{@provider.class.to_s}) at #{today}"
    @provider.run(today)
    puts "All done"
  end

end
