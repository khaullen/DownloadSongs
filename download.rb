#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

def parse_turntable(songs=$stdin.readlines)
	songs.map do |song|
		song.sub!(/\s*\(\d+\)$/, '')
		song.gsub!(/\W/, ' ')
		song.strip!
		song.gsub!(/\s+/, '_')
		song.split('_by_')
	end
end

def parse_mp3_skull(search_term)
	uri = "http://mp3skull.com/mp3/#{search_term}.html"
	doc = Nokogiri::HTML(open(uri))
	array = doc.css('div#song_html').map do |song_element|
		hash = {}
		hash[:name] = song_element.css('#right_song div b').first.content.chomp(" mp3")
		hash[:uri] = URI.escape(song_element.css('#right_song a').first['href'])
		hash[:extra_words] = hash[:name].scan(/\b/).size/2 - search_term.split("_").count
		hash.merge(parse_left_content(song_element.css('div.left').first.content))
	end
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
	File.open(File.expand_path(song[:name] << ".mp3", path), "wb") do |saved_file|
  	open(song[:uri], 'rb') do |read_file|
  		saved_file.write(read_file.read)
  	end
  end
end


search_string = 'lcd_soundsystem_someone_great'

#puts parse_turntable
puts parse_mp3_skull(search_string)
#download_to_path(parse_mp3_skull(search_string))




# TODO
# - recover from errors and download next song in array
# - accept argument for download path using ARGV
# - accept argument for reading list of songs from file
# - add threads for concurrent downloads?
# - add songs to iTunes playlist