require 'source'
require 'match'

class Match
	attr_accessor :fit

	include Comparable
	def <=>(other)
		return nil unless other.instance_of?(self.class)
		[other.fit, other.quality || 0] <=> [@fit, @quality || 0]
	end
end

class Song
	attr_reader :search_terms, :matches, :log, :file_path

	def initialize(str, opts = {})
		@search_terms = self.class.parse_input_string(str)
		@matches = []
		@log = opts[:log]
		@lock = Mutex.new
	end
	
	def self.parse_input_string(string)
		string.gsub(/\W/, ' ').split
	end
	
	def find_matches(source)
		matches = source.find_matches(@search_terms)
		matches.each do |match| 
			match_l, search_l = match.name.scan(/\b/).size/2.0, @search_terms.count
			match.fit = 1 - (match_l - search_l)/match_l
		end
		@lock.synchronize {
			@matches = (@matches + matches).sort!
		}
	end
	
	def download_to_path(path)
		m = @matches.find do |match|
			begin
				puts match.description
				mp3_file = File.expand_path(match.name << ".mp3", path)
				File.open(mp3_file, "wb") do |saved_file|
					printf "Downloading to #{mp3_file}...\n"
					open(match.uri, 'rb') do |read_file|
						saved_file.write(read_file.read)
					end
				end
			rescue => error
				puts error.message, "Trying next song match..."
				File.delete(mp3_file) if File.exists?(mp3_file)
				false
			else
				@file_path = mp3_file
				@log.info "\"url\":\"#{match.uri}\",\"file\":\"#{@file_path}\"" if @log
				return self
			end
		end
		printf "No matches left to try for #{@search_terms.join(" ")}, sorry brah\n" if m.nil?
	end
	
	def ==(s)
		s.is_a?(Song) && @search_terms.sort == s.search_terms.sort
	end
	
	def to_s
		@search_terms.join(" ")
	end
end
