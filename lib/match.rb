class Match
	
	attr_reader :name, :uri
	attr_accessor :quality, :time, :size
	
	def initialize(name, uri, q, t, s)
		@name, @uri, @quality, @time, @size = name, uri, q, t, s
	end
	
	def description
		string = ""
		instance_variables.each do |var|
			if value = instance_variable_get(var)
				string << case var
									when :@name; "Song match: #{value}\n"
									when :@uri; "URL: #{value}\n"
									when :@quality; "Quality: #{value}kbps\n"
									when :@time; "Time: #{value/60}:#{sprintf('%02d', value%60)}\n"
									when :@size; "Size: #{value} mb\n"
									else; ""
									end
			end
		end
		string
	end
	
	def to_s
		@name
	end
end
