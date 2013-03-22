env :PATH, ENV['PATH']
every(30.minutes) { rake("run") }