class Player
	constructor: (@id, @name, @pts, @oreb, @dreb, @ast, @blk, @stl, @pf, @to, @fga2, @fgm2, @fga3, @fgm3, @fta, @ftm) ->
		@pts = @oreb = @dreb = @ast = @blk = @stl = @pf = @to = @fga2 = @fgm2 = @fga3 = @fgm3 = @fta = @ftm = 0

	reb: -> @oreb + @dreb
	fg: -> "#{@fgm2 + @fgm3}/#{@fga2 + @fga3}"
	fg3: -> "#{@fgm3}/#{@fga3}"
	ft: -> "#{@ftm}/#{@fta}"
	points: -> (@fgm3 * 3) + (@fgm2 * 2) + (@ftm * 1)
	fgpc: -> @pct((@fgm2 + @fgm3) / (@fga2 + @fga3))
	fg3pc: -> @pct(@fgm3 / @fga3)
	ftpc: -> @pct(@ftm / @fta)

	pct: (value) ->
		if isNaN(value)
			".000"
		else
			if value >= 1 then "1.000" else value.toFixed(3).substr(1)

data = null

window.sort_by_name = (a, b) -> 
	if a.name.substr(2) > b.name.substr(2) then 1 else -1

stats_to_time = (time, data) ->
	teams = ((new Player(player.id, player.name) for player in team) for team in data.players) #TODO: make more readable
	for event in data.events
		player = null
		for team in teams
			for _player in team
				player = _player if _player.id == event.player
		break if event.time > time
		switch event.type
			when "dreb" then player.dreb++ 	
			when "oreb" then player.oreb++
			when "assist" then player.ast++
			when "block" then player.blk++
			when "foul" then player.pf++
			when "to" then player.to++
			when "stl" then player.stl++
			when "fga3" then player.fga3++
			when "fga2" then player.fga2++
			when "fta" then player.fta++
			when "fgm3"
				player.fga3++
				player.fgm3++
				player.pts += 3
			when "fgm2"
				player.fga2++
				player.fgm2++
				player.pts += 2
			when "ftm"
				player.fta++
				player.ftm++
				player.pts += 1
	teams

window.update_table = (time) ->
	team_i = 0
	tbody = $("table#stats tbody").html("")
	stats = stats_to_time(time, window.data)
	stats.forEach (team) ->
		tbody.append "<tr class=\"team\"><td colspan=\"11\">#{window.data.teams[team_i]}</td></tr>"
		team_i++
		team.sort(sort_by_name).forEach (player) ->

			fgpc = player.fgpc()
			# fgpc_color = "normal"
			# fgpc_color = "good" if fgpc >= 0.5
			# fgpc_color = "great" if fgpc >= 0.55
			# fgpc_color = "awesome" if fgpc >= 0.6

			tr = $("<tr class=\"player\"></tr>")
			tr.append "<td>#{player.name}</td>"
			tr.append "<td class=\"numeric\">#{player.points()}</td>"
			tr.append "<td class=\"numeric misc\">#{player.oreb}</td>"
			tr.append "<td class=\"numeric misc\">#{player.dreb}</td>"
			tr.append "<td class=\"numeric\">#{player.reb()}</td>"
			tr.append "<td class=\"numeric\">#{player.ast}</td>"
			tr.append "<td class=\"numeric\">#{player.stl}</td>"
			tr.append "<td class=\"numeric\">#{player.blk}</td>"
			tr.append "<td class=\"numeric\">#{player.to}</td>"
			tr.append "<td class=\"fraction\"><span title=\"#{fgpc}\">#{player.fg()}</span></td>"
			tr.append "<td class=\"fraction\"><span title=\"#{player.fg3pc()}\">#{player.fg3()}</span></td>"
			tr.append "<td class=\"fraction\"><span title=\"#{player.ftpc()}\">#{player.ft()}</span></td>"
			tbody.append tr

fetch_game = (id) ->
	$.ajax "/game/#{id}.json",
		complete: (jqxhr) -> 
			data = jQuery.parseJSON(jqxhr.responseText)
			update_table 600

$ ->

	update_stats = (ev, ui) -> 
		seconds = ui.value
		update_table seconds
		if seconds == 0
			quarter = 1
			minutes_remaining_in_quarter = 12
		else
			quarter = Math.ceil(seconds / 720)
			seconds_remaining_in_quarter = 720 - (seconds - ((quarter - 1) * 720))
			minutes_remaining_in_quarter = 0
			while seconds_remaining_in_quarter >= 60
				seconds_remaining_in_quarter -= 60
				minutes_remaining_in_quarter++
		seconds = if seconds_remaining_in_quarter.toString().length == 1 then "0#{seconds_remaining_in_quarter}" else seconds_remaining_in_quarter
		$("#time").text("#{quarter}Q #{minutes_remaining_in_quarter}:#{seconds}")

	$("#slider").slider
		min: 0, max: 2880,
		slide: update_stats
		change: update_stats

	update_table 0
