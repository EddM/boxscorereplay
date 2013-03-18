(function() {
  var Player, data, formatted_pct, shooting_stats_cell, stats_to_time, update_team_stats;

  formatted_pct = function(value) {
    if (isNaN(value)) {
      return ".000";
    } else {
      if (value >= 1) {
        return "1.000";
      } else {
        return value.toFixed(3).substr(1);
      }
    }
  };

  Player = (function() {

    function Player(id, name, pts, oreb, dreb, ast, blk, stl, pf, to, fga2, fgm2, fga3, fgm3, fta, ftm) {
      this.id = id;
      this.name = name;
      this.pts = pts;
      this.oreb = oreb;
      this.dreb = dreb;
      this.ast = ast;
      this.blk = blk;
      this.stl = stl;
      this.pf = pf;
      this.to = to;
      this.fga2 = fga2;
      this.fgm2 = fgm2;
      this.fga3 = fga3;
      this.fgm3 = fgm3;
      this.fta = fta;
      this.ftm = ftm;
      this.pts = this.oreb = this.dreb = this.ast = this.blk = this.stl = this.pf = this.to = this.fga2 = this.fgm2 = this.fga3 = this.fgm3 = this.fta = this.ftm = 0;
      this.appears = false;
    }

    Player.prototype.reb = function() {
      return this.oreb + this.dreb;
    };

    Player.prototype.points = function() {
      return (this.fgm3 * 3) + (this.fgm2 * 2) + (this.ftm * 1);
    };

    Player.prototype.fgpc = function() {
      return formatted_pct((this.fgm2 + this.fgm3) / (this.fga2 + this.fga3));
    };

    Player.prototype.fg3pc = function() {
      return formatted_pct(this.fgm3 / this.fga3);
    };

    Player.prototype.ftpc = function() {
      return formatted_pct(this.ftm / this.fta);
    };

    return Player;

  })();

  data = null;

  window.sort_by_name = function(a, b) {
    if (a.name.substr(2) > b.name.substr(2)) {
      return 1;
    } else {
      return -1;
    }
  };

  stats_to_time = function(time, data) {
    var event, filtered, player, team, teams, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _player, _ref;
    teams = (function() {
      var _i, _len, _ref, _results;
      _ref = data.players;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        team = _ref[_i];
        _results.push((function() {
          var _j, _len1, _results1;
          _results1 = [];
          for (_j = 0, _len1 = team.length; _j < _len1; _j++) {
            player = team[_j];
            _results1.push(new Player(player.id, player.name));
          }
          return _results1;
        })());
      }
      return _results;
    })();
    _ref = data.events;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      event = _ref[_i];
      if (event.time > time) {
        break;
      }
      player = null;
      for (_j = 0, _len1 = teams.length; _j < _len1; _j++) {
        team = teams[_j];
        for (_k = 0, _len2 = team.length; _k < _len2; _k++) {
          _player = team[_k];
          if (_player.id === event.player) {
            player = _player;
          }
        }
      }
      switch (event.type) {
        case "dreb":
          player.dreb++;
          break;
        case "oreb":
          player.oreb++;
          break;
        case "assist":
          player.ast++;
          break;
        case "block":
          player.blk++;
          break;
        case "foul":
          player.pf++;
          break;
        case "to":
          player.to++;
          break;
        case "stl":
          player.stl++;
          break;
        case "fga3":
          player.fga3++;
          break;
        case "fga2":
          player.fga2++;
          break;
        case "fta":
          player.fta++;
          break;
        case "fgm3":
          player.fga3++;
          player.fgm3++;
          player.pts += 3;
          break;
        case "fgm2":
          player.fga2++;
          player.fgm2++;
          player.pts += 2;
          break;
        case "ftm":
          player.fta++;
          player.ftm++;
          player.pts += 1;
      }
      player.appears = true;
    }
    if (time <= 1440) {
      for (_l = 0, _len3 = teams.length; _l < _len3; _l++) {
        team = teams[_l];
        for (_m = 0, _len4 = team.length; _m < _len4; _m++) {
          player = team[_m];
          filtered = data.events.filter(function(ev) {
            return ev.time <= 1440 && ev.player === player.id;
          });
          if (filtered.length > 0) {
            player.appears = true;
          }
        }
      }
    }
    return teams;
  };

  shooting_stats_cell = function(made, attempts) {
    return $("<td class=\"fraction\"><span title=\"" + (formatted_pct(made / attempts)) + "\">" + made + "/" + attempts + "</span></td>");
  };

  update_team_stats = function(team_stats, player) {
    team_stats.orebs += player.oreb;
    team_stats.drebs += player.dreb;
    team_stats.asts += player.ast;
    team_stats.stls += player.stl;
    team_stats.blks += player.blk;
    team_stats.pfs += player.pf;
    team_stats.tos += player.to;
    team_stats.ftm += player.ftm;
    team_stats.fta += player.fta;
    team_stats.fgm += player.fgm2 + player.fgm3;
    team_stats.fga += player.fga2 + player.fga3;
    team_stats.fgm3 += player.fgm3;
    return team_stats.fga3 += player.fga3;
  };

  window.update_table = function(time) {
    var stats, tbody;
    tbody = $("table#stats tbody").html("");
    stats = stats_to_time(time, window.data);
    stats.forEach(function(team, team_i) {
      var key, team_stats, team_tr, _i, _len, _ref;
      team_stats = {
        points: 0,
        orebs: 0,
        drebs: 0,
        rebs: 0,
        asts: 0,
        stls: 0,
        blks: 0,
        pfs: 0,
        tos: 0,
        ftm: 0,
        fta: 0,
        fgm: 0,
        fga: 0,
        fgm3: 0,
        fga3: 0
      };
      tbody.append("<tr class=\"header\"><td colspan=\"13\">" + window.data.teams[team_i] + " <span id=\"score-" + team_i + "\">&nbsp;</span></td></tr>");
      team.sort(sort_by_name).forEach(function(player) {
        var total_points, total_rebounds, tr;
        if (player.appears) {
          total_points = player.points();
          total_rebounds = player.reb();
          update_team_stats(team_stats, player);
          team_stats.points += total_points;
          team_stats.rebs += total_rebounds;
          tr = $("<tr class=\"player\"></tr>");
          tr.append("<td class=\"string\">" + player.name + "</td>");
          tr.append("<td class=\"numeric\">" + total_points + "</td>");
          tr.append("<td class=\"numeric misc\">" + player.oreb + "</td>");
          tr.append("<td class=\"numeric misc\">" + player.dreb + "</td>");
          tr.append("<td class=\"numeric\">" + total_rebounds + "</td>");
          tr.append("<td class=\"numeric\">" + player.ast + "</td>");
          tr.append("<td class=\"numeric\">" + player.stl + "</td>");
          tr.append("<td class=\"numeric\">" + player.blk + "</td>");
          tr.append("<td class=\"numeric\">" + player.pf + "</td>");
          tr.append("<td class=\"numeric\">" + player.to + "</td>");
          tr.append("<td class=\"fraction\"><span title=\"" + (player.fgpc()) + "\">" + (player.fgm2 + player.fgm3) + "/" + (player.fga2 + player.fga3) + "</span></td>");
          tr.append("<td class=\"fraction\"><span title=\"" + (player.fg3pc()) + "\">" + player.fgm3 + "/" + player.fga3 + "</span></td>");
          tr.append("<td class=\"fraction\"><span title=\"" + (player.ftpc()) + "\">" + player.ftm + "/" + player.fta + "</span></td>");
          return tbody.append(tr);
        }
      });
      team_tr = $("<tr class=\"team\"><td colspan=\"2\">&nbsp;</td></tr>");
      _ref = ["orebs", "drebs", "rebs", "asts", "stls", "blks", "pfs", "tos"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        team_tr.append("<td class=\"numeric " + (key === 'orebs' || key === 'drebs' ? "misc" : void 0) + "\">" + team_stats[key] + "</td>");
      }
      team_tr.append(shooting_stats_cell(team_stats.fgm, team_stats.fga));
      team_tr.append(shooting_stats_cell(team_stats.fgm3, team_stats.fga3));
      team_tr.append(shooting_stats_cell(team_stats.ftm, team_stats.fta));
      tbody.append(team_tr);
      return $("#score-" + team_i).html(team_stats.points);
    });
    return $("span[title]").each(function() {
      $(this).data('title', $(this).attr('title'));
      $(this).attr('title', '');
      $(this).mouseover(function() {
        var tooltip;
        tooltip = $("<span class=\"tooltip\">" + ($(this).data('title')) + "</span>");
        return $(this).after(tooltip);
      });
      return $(this).mouseout(function() {
        return $(".tooltip").remove();
      });
    });
  };

  $(function() {
    var update_stats;
    update_stats = function(ev, ui) {
      var minutes_remaining_in_quarter, quarter, seconds, seconds_remaining_in_quarter;
      seconds = ui.value;
      update_table(seconds);
      if (seconds === 0) {
        quarter = 1;
        minutes_remaining_in_quarter = 12;
        seconds_remaining_in_quarter = 0;
      } else {
        quarter = Math.ceil(seconds / 720);
        seconds_remaining_in_quarter = 720 - (seconds - ((quarter - 1) * 720));
        minutes_remaining_in_quarter = 0;
        while (seconds_remaining_in_quarter >= 60) {
          seconds_remaining_in_quarter -= 60;
          minutes_remaining_in_quarter++;
        }
      }
      seconds = seconds_remaining_in_quarter.toString().length === 1 ? "0" + seconds_remaining_in_quarter : seconds_remaining_in_quarter;
      return $("#time").text("" + quarter + "Q " + minutes_remaining_in_quarter + ":" + seconds);
    };
    $("#slider").slider({
      min: 0,
      max: 2880,
      slide: update_stats,
      change: update_stats
    });
    return update_table(0);
  });

}).call(this);
