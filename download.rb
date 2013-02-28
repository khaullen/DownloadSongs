#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'optparse'

def parse_input_string(string)
	string.gsub!(/\W/, ' ')					# Remove non-word characters
	string.strip!										# Remove excess whitespace
	string.gsub!(/\s+/, '_')				# Delimit terms with underscore
end

def parse_turntable(songs=$stdin.readlines)
	puts "Parsing Turntable.FM input..." if options[:verbose]
	songs.map do |song|
		song.sub!(/\s*\(\d+\)$/, '')											# Remove popularity index
		parse_input_string(song).sub!('_by_', '_')				# Remove song/artist delimiter
	end
end

def parse_mp3_skull(search_term)
	puts "Downloading search results for #{search_term}..." if options[:verbose]
	uri = "http://mp3skull.com/mp3/#{search_term}.html"
	doc = Nokogiri::HTML(open(uri))
	puts "Parsing HTML..." if options[:verbose]
	array = doc.css('div#song_html').map do |song_element|
		hash = {}
		hash[:name] = song_element.css('#right_song div b').first.content.chomp(" mp3")
		hash[:uri] = URI.escape(song_element.css('#right_song a').first['href'])
		hash[:extra_words] = hash[:name].scan(/\b/).size/2 - search_term.split("_").count
		hash.merge(parse_left_content(song_element.css('div.left').first.content))
	end
	array.reject! { |hash| (hash[:quality] || 160) < 160 }
	array.sort_by { |hash| [hash[:extra_words], -(hash[:quality] || 0)] }
end

def parse_left_content(content)
	m = content.match(/(\d+)\s*kbps/)
	kbps = m && m[1].to_i
	m = content.match(/(?<hours>\d{1,2})?:?(?<minutes>\d{1,2}):(?<seconds>\d{2})/)
	seconds = m && m[:seconds].to_i + m[:minutes].to_i * 60 + m[:hours].to_i * 60 * 60
	m = content.match(/(?:\d:\d{2})?([\d\.]+) mb/)
	mb = m && m[1].to_f
	{:quality => kbps, :time => seconds, :size => mb}
end

def download_to_path(songs, path="~/Downloads")
	song = songs.shift
	puts "Downloading #{song[:name]} from #{song[:uri]}..."
	File.open(File.expand_path(song[:name] << ".mp3", path), "wb") do |saved_file|
		open(song[:uri], 'rb') do |read_file|
			saved_file.write(read_file.read)
		end
	end
end


options = {}

optparse = OptionParser.new do |opts|
	opts.banner = "Usage: download.rb [options] song1 song2 ..."
	
	options[:play] = false
	opts.on( '-p', '--play', 'Play song after downloading' ) do
		options[:play] = true
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
	
	opts.on( '-h', '--help', 'Display help' ) do
		puts opts
		exit
	end
end


optparse.parse!

puts "Verbose mode enabled" if options[:verbose]
puts "Logging output to #{options[:log]}" if options[:verbose]
puts "Minimum quality: #{options[:quality]}kbps" if options[:quality] > 0
puts "Search result for \"#{ARGV.last}\" will begin playing after download is complete" if options[:play]

ARGV.each do |song|
	search_term = parse_input_string(song)
	search_results = parse_mp3_skull(search_string)
	
end




# TODO
# - automatically start playing song after download
# - output download info to log file
# - output activity to stdout
# - add support for download progress viewer
# - recover from errors and download next song in array
# - accept argument for download path using ARGV
# - accept argument for search string
# - add threads for concurrent downloads?
# - add songs to iTunes playlist


#file_to_open = "/path/to/file.txt"
#system %{open "#{file_to_open}"}