# class BBRef < Provider

#   def parse_doc(doc)
#     games = doc.css('#boxes > table table.stats_table')
#     games.each do |table|
#       if link = table.css('a').select { |a| a.text =~ /Play-by-Play/i }.first
#         key = link.attr('href').split("/")[-1].split(".")[0]
#         unless Game.count(:bbref_key => key) > 0
#           begin
#             game = Game.new
#             url = "http://www.basketball-reference.com#{link.attr('href')}"
#             puts "Fetching #{url}"
#             game.build_from_html open(url)
#             game.insert_into_db(key)
#             game.assess!
#           rescue => e
#             puts "*** Failed for #{key}"
#             puts e.inspect
#             puts e.backtrace
#           end
#         end
#       end
#       sleep(3)
#     end
#   end
  
# end
