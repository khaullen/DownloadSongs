#! /usr/bin/env ruby

$LOAD_PATH << './lib'

require 'optparse'
require 'downloader'

def parse_turntable(songs=$stdin.readlines)
	puts "Parsing Turntable.FM input..." if options[:verbose]
	songs.map do |song|
		song.sub!(/\s*\(\d+\)$/, '')											# Remove popularity index
		parse_input_string(song).sub!('_by_', '_')				# Remove song/artist delimiter
	end
end

options = {}

OptionParser.new do |opts|
	opts.banner = "Usage: download.rb [options] song1 song2 ..."
	
	options[:play] = false
	opts.on( '-p', '--play', 'Play song after downloading' ) do
		options[:play] = true
	end
	
	options[:open] = false
	opts.on( '-o', '--open', 'Open song after downloading' ) do
		options[:open] = true
	end
	
	options[:quality] = 0
	opts.on( '-q', '--quality [KBPS]', Integer, 'Minimum quality mp3 in KBPS' ) do |kbps|
		options[:quality] = kbps || 160
	end
	
	options[:verbose] = false
	opts.on( '-v', '--verbose', 'Output more information' ) do
		options[:verbose] = true
	end
	
	options[:log] = "log.txt"
	opts.on( '-l', '--logfile FILE', 'Write log to FILE' ) do |file|
		options[:log] = file
	end
	
	options[:path] = "~/Downloads"
	opts.on( '-d', '--path PATH', 'Save mp3 file to PATH' ) do |path|
		options[:path] = path
	end
	
	opts.on( '-h', '--help', 'Display help' ) do
		puts opts
		exit
	end
end.parse!

raise(ArgumentError, "No search terms specified") if ARGV.empty?
puts "Verbose mode enabled" if options[:verbose]
puts "Logging output to #{options[:log]}" if options[:verbose]
puts "Minimum quality: #{options[:quality]}kbps" if options[:quality] > 0
puts "Search result for \"#{ARGV.last}\" will begin playing after download is complete" if options[:play]

# downloader.match_songs returns a thread, block it to wait for all songs to match

downloader = Downloader.new(ARGV, options)
match_thread = downloader.match_songs
last_song = downloader.download_songs

if options[:play] && last_song.file_path
	program = case `printf $(command -v afplay >/dev/null 2>&1)$?`
						when "0"; "afplay"
						else "open"
						end
	if program == 'afplay'
		puts "Press Control-C to stop playback"
		begin
			`#{program} "#{last_song.file_path}"`
		rescue Interrupt
			puts
			exit(0)
		end
	end
end

if options[:open] && last_song.file_path
	puts 'Opening the file...'
	`open "#{last_song.file_path}"`
end

# TODO
# - add support for download progress viewer
# - add songs to iTunes playlist
# - add dilandau.eu, tinysong as source
# - streaming support
# - check validity of mp3, retry if invalid
# - test matches for equality (by URI, or better yet by accurate file size?)
# - improve match.fit calculation (look for keywords live, cover, remix, etc; add the)
# - create log file if it doesn't already exist
# - expand file path passed in for log
