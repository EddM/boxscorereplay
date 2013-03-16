(function() {
  var Player, data, stats_to_time;

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
    }

    Player.prototype.reb = function() {
      return this.oreb + this.dreb;
    };

    Player.prototype.points = function() {
      return (this.fgm3 * 3) + (this.fgm2 * 2) + (this.ftm * 1);
    };

    Player.prototype.fgpc = function() {
      return this.pct((this.fgm2 + this.fgm3) / (this.fga2 + this.fga3));
    };

    Player.prototype.fg3pc = function() {
      return this.pct(this.fgm3 / this.fga3);
    };

    Player.prototype.ftpc = function() {
      return this.pct(this.ftm / this.fta);
    };

    Player.prototype.pct = function(value) {
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
    var event, player, team, teams, _i, _j, _k, _len, _len1, _len2, _player, _ref;
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
      if (event.time > time) {
        break;
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
    }
    return teams;
  };

  window.update_table = function(time) {
    var stats, tbody, team_i, team_scores;
    team_i = 0;
    team_scores = [];
    tbody = $("table#stats tbody").html("");
    stats = stats_to_time(time, window.data);
    stats.forEach(function(team) {
      team_scores[team_i] = 0;
      tbody.append("<tr class=\"team\"><td colspan=\"13\">" + window.data.teams[team_i] + " <span id=\"score-" + team_i + "\">&nbsp;</span></td></tr>");
      team.sort(sort_by_name).forEach(function(player) {
        var fgpc, tr;
        team_scores[team_i] += player.points();
        fgpc = player.fgpc();
        tr = $("<tr class=\"player\"></tr>");
        tr.append("<td class=\"string\">" + player.name + "</td>");
        tr.append("<td class=\"numeric\">" + (player.points()) + "</td>");
        tr.append("<td class=\"numeric misc\">" + player.oreb + "</td>");
        tr.append("<td class=\"numeric misc\">" + player.dreb + "</td>");
        tr.append("<td class=\"numeric\">" + (player.reb()) + "</td>");
        tr.append("<td class=\"numeric\">" + player.ast + "</td>");
        tr.append("<td class=\"numeric\">" + player.stl + "</td>");
        tr.append("<td class=\"numeric\">" + player.blk + "</td>");
        tr.append("<td class=\"numeric\">" + player.pf + "</td>");
        tr.append("<td class=\"numeric\">" + player.to + "</td>");
        tr.append("<td class=\"fraction\"><span title=\"" + fgpc + "\">" + (player.fgm2 + player.fgm3) + "/" + (player.fga2 + player.fga3) + "</span></td>");
        tr.append("<td class=\"fraction\"><span title=\"" + (player.fg3pc()) + "\">" + player.fgm3 + "/" + player.fga3 + "</span></td>");
        tr.append("<td class=\"fraction\"><span title=\"" + (player.ftpc()) + "\">" + player.ftm + "/" + player.fta + "</span></td>");
        return tbody.append(tr);
      });
      return team_i++;
    });
    $("#score-0").html(team_scores[0]);
    $("#score-1").html(team_scores[1]);
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
