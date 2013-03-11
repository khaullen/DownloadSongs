class Match
	
	attr_reader :name, :uri
	attr_accessor :quality, :time, :size
	
	def initialize(name, uri, q, t, s)
		@name, @uri, @quality, @time, @size = name, uri, q, t, s
	end
	
	def description
		"Song match: #{@name}\nURL: #{@uri}\nQuality: #{@quality}kbps\nTime: #{@time/60}:#{@time%60}\nSize: #{@size} mb"
	end
	
	def to_s
		@name
	end
	
end