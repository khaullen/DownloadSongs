require 'open-uri'
require 'nokogiri'
require 'match'

module Source
# Every source object must implement the method find_matches(search_terms) that returns an array of Match objects
	
	def self.check_connectivity
		#check specific host
	end

	class MP3Skull
		def initialize(options = {})
			@quality = options[:quality]
			@verbose = options[:verbose]
		end
		
		def find_matches(search_terms)
			Source.check_connectivity
			matches = parse_mp3_skull(search_string(search_terms))
			matches.empty? ? parse_mp3_skull(search_string(search_terms, true)) : matches
		end

		private
		def search_string(array, rev = false)
			array = array.reverse if rev
			array.join("_")
		end
	
		def results(search_string)
			printf "Downloading search results for #{search_string}...\n" if @verbose
			uri = "http://mp3skull.com/mp3/#{search_string}.html"
			begin
				Nokogiri::HTML(open(uri))
			rescue SocketError => error
				raise(error, "Check your internet connection")
			end
		end

		def parse_mp3_skull(search_string)
			doc = results(search_string)
			printf "Parsing HTML for #{search_string}...\n" if @verbose
			array = doc.css('div#song_html').map do |song_element|
				name = song_element.css('#right_song div b').first.content.encode('UTF-16', :invalid => :replace).encode('UTF-8').chomp(" mp3")
				uri = URI.escape(song_element.css('#right_song a').first['href'])
				q, t, s = parse_left_content(song_element.css('div.left').first.content)
				Match.new(name, uri, q, t, s)
			end
			array.reject { |match| (match.quality || 320) < @quality }
		end
	
		def parse_left_content(content)
			m = content.match(/(\d+)\s*kbps/)
			kbps = m && m[1].to_i
			m = content.match(/(?<hours>\d{1,2})?:?(?<minutes>\d{1,2}):(?<seconds>\d{2})/)
			seconds = m && m[:seconds].to_i + m[:minutes].to_i * 60 + m[:hours].to_i * 60 * 60
			m = content.match(/(?:\d:\d{2})?([\d\.]+) mb/)
			mb = m && m[1].to_f
			[kbps, seconds, mb]
		end
	end
end
