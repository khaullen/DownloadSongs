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
			$stderr << "No matches found for #{song}, bummer\n" if song.matches.empty?
		end
	end
	
	def download_songs
		@songs.each do |song|
			song.download_to_path(@download_path)
		end		
		@songs.last
	end
	
	def match_and_download
		@songs.each do |song|
			t = Thread.new do
				source_threads = []
				@sources.each do |source|
					source_threads << Thread.new do
						song.find_matches(source)
					end
				end
				source_threads.each { |s_thread| s_thread.join }
				song.download_to_path(@download_path)
			end
		end
		Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current}
		@songs.last
	end
end
