env :PATH, ENV['PATH']
every(30.minutes) do 
  rake "run" # get today's
  rake "run[24]" # get yesterday's
end
