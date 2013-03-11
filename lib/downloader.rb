require 'song'
require 'source'
require 'logger'

class Downloader
	def initialize(songs, options)
		@log = Logger.new(options[:log])
		@log.datetime_format = "%Y-%m-%d %H:%M:%S"
		@download_path = options[:path]
		@songs = songs.map { |str| Song.new(str, :log => @log) }
		@sources = [Source::MP3Skull].map { |klass| klass.new(options) }
	end
	
	def match_songs
		@songs.each do |song|
			@sources.each do |source|
				song.find_matches(source)
			end
			$stderr << "No matches found for #{song}, bummer" if song.matches.empty?
		end
	end
	
	def download_songs
		@songs.each do |song|
			song.download_to_path(@download_path)
		end		
		@songs.last
	end
end