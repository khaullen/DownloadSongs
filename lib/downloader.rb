require 'song'
require 'source'
require 'logger'

class Downloader
	@@source_classes = [Source::MP3Skull]

	def initialize(songs, options)
		@log = Logger.new(options[:log])
		@log.datetime_format = "%Y-%m-%d %H:%M:%S"
		@download_path = options[:path]
		@songs = songs.map { |str| Song.new(str, :log => @log) }
		@sources = @@source_classes.map { |klass| klass.new(options) }
	end
	
	def match_songs
		@queue = Queue.new
		Thread.new do
			song_threads = []
			@songs.each do |song|
				song_threads << Thread.new do
					source_threads = []
					@sources.each do |source|
						source_threads << Thread.new do
							song.find_matches(source)
						end
					end
					source_threads.each { |t| t.join }
					$stderr << "No matches found for #{song}, bummer\n" if song.matches.empty?
					@queue << song
				end
			end
			song_threads.each { |t| t.join }
			@queue << nil
		end
	end
	
	def download_songs
		download_threads = []
		while song = @queue.pop
			download_threads << Thread.new(song) do |s|
				s.download_to_path(@download_path)
			end
		end
		download_threads.each { |t| t.join }
		@songs.last
	end
end
