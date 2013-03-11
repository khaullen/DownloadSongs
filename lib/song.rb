require 'source'
require 'match'

class Match
	attr_accessor :fit

	include Comparable
	def <=>(other)
		return nil unless other.instance_of?(self.class)
		self.fit <=> other.fit
	end
end

class Song
	attr_reader :search_terms, :matches, :log, :mp3_file

	def initialize(str, opts = {})
		@search_terms = self.class.parse_input_string(str)
		@matches = []
		@log = opts[:log]
	end
	
	def self.parse_input_string(string)
		string.gsub(/\W/, ' ').split
	end
	
	def find_matches(source)
		matches = source.find_matches(@search_terms)
		matches.each { |match| match.fit = match.name.scan(/\b/).size/2 - @search_terms.count }
		@matches = (@matches + matches).sort!
	end
	
	def download_to_path(path)
		@matches.find do |match|
			begin
				puts match.description
				@mp3_file = File.expand_path(match.name << ".mp3", path)
				File.open(@mp3_file, "wb") do |saved_file|
					puts "Downloading to #{@mp3_file}..."
					open(match.uri, 'rb') do |read_file|
						saved_file.write(read_file.read)
					end
				end
			rescue => error
				puts error.message, "Trying next song match..."
				false
			else
				@log.info "\"url\":\"#{match.uri}\",\"file\":\"#{@mp3_file}\"" if @log
				return self
			end
		end
	end
	
	def ==(s)
		s.is_a? Song && @search_terms.sort == s.search_terms.sort
	end
	
	def to_s
		@search_terms.join(" ")
	end
end