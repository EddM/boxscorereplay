formatted_pct = (value) ->
  return ".000" if isNaN(value)
  if value >= 1 then "1.000" else value.toFixed(3).substr(1)

class Player
  constructor: (@id, @name, @pts, @oreb, @dreb, @ast, @blk, @stl, @pf, @to, @fga2, @fgm2, @fga3, @fgm3, @fta, @ftm) ->
    @pts = @oreb = @dreb = @ast = @blk = @stl = @pf = @to = @fga2 = @fgm2 = @fga3 = @fgm3 = @fta = @ftm = 0

  reb: -> @oreb + @dreb
  points: -> (@fgm3 * 3) + (@fgm2 * 2) + (@ftm * 1)
  fgpc: -> formatted_pct((@fgm2 + @fgm3) / (@fga2 + @fga3))
  fg3pc: -> formatted_pct(@fgm3 / @fga3)
  ftpc: -> formatted_pct(@ftm / @fta)

create_initial_list = (data) ->
  list = {}
  for team in data.players
    for id, player of team
      filtered = data.events.filter (ev) -> ev.time <= 1440 && ev.player == id
      list[id] = { name: player.name, team: player.team } if filtered.length > 0
  list

stats_to_time = (time, data) ->
  teams = [{}, {}]

  if time <= 1440
    teams[player.team][id] = new Player(id, player.name) for id, player of initial_list

  for event in data.events
    break if event.time > time

    if teams[event.team] && teams[event.team][event.player]
      player = teams[event.team][event.player]
    else
      object = data.players[event.team][event.player]
      player = new Player(event.player, object.name)
      teams[event.team][event.player] = player

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

shooting_stats_cell = (made, attempts) -> 
  $("<td class=\"fraction\"><span title=\"#{formatted_pct(made / attempts)}\">#{made}/#{attempts}</span></td>")

set_quarter_markers = () ->
  max = $("#slider").slider "option", "max"
  $(".quarter-markers .q2").css 'left', "#{100 / (max / 720)}%"
  $(".quarter-markers .q3").css 'left', "#{100 / (max / 1440)}%"
  $(".quarter-markers .q4").css 'left', "#{100 / (max / 2160)}%"
  $(".quarter-markers .ot").css 'left', "#{100 / (max / 2880)}%"

update_team_stats = (team_stats, player) ->
  team_stats.orebs += player.oreb
  team_stats.drebs += player.dreb
  team_stats.asts += player.ast
  team_stats.stls += player.stl
  team_stats.blks += player.blk
  team_stats.pfs += player.pf
  team_stats.tos += player.to
  team_stats.ftm += player.ftm
  team_stats.fta += player.fta
  team_stats.fgm += (player.fgm2 + player.fgm3)
  team_stats.fga += (player.fga2 + player.fga3)
  team_stats.fgm3 += player.fgm3
  team_stats.fga3 += player.fga3

update_table = (time, data) ->
  tbody = $("table#stats tbody").html ""
  stats = stats_to_time time, data

  stats.forEach (team, team_i) ->
    team_stats = 
      points: 0, orebs: 0, drebs: 0, rebs: 0,
      asts: 0, stls: 0, blks: 0, pfs: 0, tos: 0,
      ftm: 0, fta: 0, fgm: 0, fga: 0, fgm3: 0, fga3: 0

    tbody.append "<tr class=\"header\"><td colspan=\"13\">#{data.teams[team_i]} <span id=\"score-#{team_i}\">&nbsp;</span></td></tr>"

    for id, player of team
      total_points = player.points()
      total_rebounds = player.reb()
      update_team_stats team_stats, player
      team_stats.points += total_points
      team_stats.rebs += total_rebounds

      tr = $("<tr class=\"player\"></tr>")
      tr.append "<td class=\"string\">#{player.name}</td>"
      tr.append "<td class=\"numeric\">#{total_points}</td>"
      tr.append "<td class=\"numeric misc\">#{player.oreb}</td>"
      tr.append "<td class=\"numeric misc\">#{player.dreb}</td>"
      tr.append "<td class=\"numeric\">#{total_rebounds}</td>"
      tr.append "<td class=\"numeric\">#{player.ast}</td>"
      tr.append "<td class=\"numeric\">#{player.stl}</td>"
      tr.append "<td class=\"numeric\">#{player.blk}</td>"
      tr.append "<td class=\"numeric\">#{player.pf}</td>"
      tr.append "<td class=\"numeric\">#{player.to}</td>"
      tr.append "<td class=\"fraction align-right\"><span title=\"#{player.fgpc()}\">#{player.fgm2 + player.fgm3}/#{player.fga2 + player.fga3}</span></td>"
      tr.append "<td class=\"fraction align-right\"><span title=\"#{player.fg3pc()}\">#{player.fgm3}/#{player.fga3}</span></td>"
      tr.append "<td class=\"fraction align-right\"><span title=\"#{player.ftpc()}\">#{player.ftm}/#{player.fta}</span></td>"
      tbody.append tr

    team_tr = $("<tr class=\"team\"><td colspan=\"2\">&nbsp;</td></tr>")
    for key in ["orebs", "drebs", "rebs", "asts", "stls", "blks", "pfs", "tos"]
      team_tr.append "<td class=\"numeric #{"misc" if key == 'orebs' || key == 'drebs'}\">#{team_stats[key]}</td>"
    team_tr.append shooting_stats_cell team_stats.fgm, team_stats.fga
    team_tr.append shooting_stats_cell team_stats.fgm3, team_stats.fga3
    team_tr.append shooting_stats_cell team_stats.ftm, team_stats.fta
    tbody.append team_tr
    $("#score-#{team_i}").html(team_stats.points)
  
  $("span[title]").each ->
    $(this).data 'title', $(this).attr('title')
    $(this).attr 'title', ''
    $(this).mouseover ->
      tooltip = $("<span class=\"tooltip\">#{$(this).data('title')}</span>")
      $(this).after tooltip
    $(this).mouseout -> $(".tooltip").remove()

update_clock = (seconds) ->
  $("a#time").attr("href", "##{seconds}")
  if seconds == 0
      quarter = "1Q"
      minutes_remaining_in_quarter = 12
      seconds_remaining_in_quarter = 0
    else
      if seconds > 2880
        ot_seconds = seconds - 2880
        ot_period = Math.ceil(ot_seconds / 300)
        seconds_remaining_in_quarter = (300 * ot_period) - ot_seconds
        minutes_remaining_in_quarter = 0
        while seconds_remaining_in_quarter >= 60
          seconds_remaining_in_quarter -= 60
          minutes_remaining_in_quarter++
        quarter = "#{if ot_period >= 2 then ot_period else ""}OT"
      else
        quarter = Math.ceil(seconds / 720)
        seconds_remaining_in_quarter = 720 - (seconds - ((quarter - 1) * 720))
        minutes_remaining_in_quarter = 0
        while seconds_remaining_in_quarter >= 60
          seconds_remaining_in_quarter -= 60
          minutes_remaining_in_quarter++
        quarter = "#{quarter}Q"
    seconds = if seconds_remaining_in_quarter.toString().length == 1 then "0#{seconds_remaining_in_quarter}" else seconds_remaining_in_quarter
    $("a#time").text("#{quarter} #{minutes_remaining_in_quarter}:#{seconds}")

update_overtime = (seconds) ->
  max = $("#slider").slider "option", "max"
  if seconds == max && data.events[data.events.length - 1].time > seconds
    ot_seconds = seconds - 2880
    ot_period = Math.ceil ot_seconds / 300
    $("#slider, .quarter-markers").addClass "overtime ot#{ot_period}"
    $(".quarter-markers").append $("<a class=\"ot\">OT</a>") unless $(".quarter-markers .ot").length > 0
    $("#slider").slider "option", "max", max + 300
    set_quarter_markers()

$ ->

  update_stats = (ev, ui) -> 
    seconds = ui.value
    update_overtime seconds if ev.type == "slidechange"
    update_table seconds, window.data
    update_clock seconds

  $("#slider").slider
    min: 0, max: 2880, animate: true,
    slide: update_stats
    change: update_stats

  $("#slider").after $("<div class=\"quarter-markers\"><a href=\"#\" class=\"q2\">Q2</a><a class=\"q3\">Q3</a><a class=\"q4\">Q4</a></div>")
  window.initial_list = create_initial_list(window.data)
  $("#slider").slider "option", "value", (if window.location.hash? && window.location.hash != '' then parseInt(window.location.hash.substr(1)) else 0)
  update_table $("#slider").slider("option", "value"), window.data
  set_quarter_markers()
