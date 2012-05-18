#
#  Controller.rb
#  ChordPlayer
#
#  Created by 吉岡 紘二 on 12/05/13.
#  Copyright 2012年 __MyCompanyName__. All rights reserved.
#

class ChordSyntaxError < StandardError; end

class NSString		
	def play
		ce = ChordsExtractor.new(self)
		chords = ce.chords 
		
		chords.each do |chord|
			chord.notes.each do |note|
				$scheduler.noteOn(note)
			end
			
			sleep(chord.duration * 0.5)
			
			chord.notes.each do |note|
				$scheduler.noteOff(note)
			end
		end
	end
end

def baseName2NoteNumber(baseName)
	case baseName
	when "E"
		67
	when "F"
		68
	when "F#","Gb"
		69
	when "G"
		70
	when "G#", "Ab"
		71
	when "A"
		72
	when "A#","Bb"
		73
	when "B"
		74
	when "C"
		75
	when "C#", "Db"
		76
	when "D", "D"
		77
	when "D#", "Eb"
		78
	else
		raise "#{baseName} can't be recognized as base note name."
	end
end


#needs test!!!!!!!!!!!!!!!!!
def transpose(baseName, num)

	normalizedBaseName = case baseName
	when "Db"
		"C#"
	when "Eb"
		"D#"
	when "Gb"
		"F#"
	when "Ab"
		"G#"
	when "Bb"
		"A#"
	else 
		baseName
	end	
		
	chords_array= ["C","C#","D","D#","E","F","F#","G", "G#","A","A#","B"] #=>size = 12
	fromC = chords_array.index(normalizedBaseName)
	raise "basename error. \"#{baseName}\"" if fromC == nil
	
	if (fromC + num) > chords_array.size-1
		num -= chords_array.size - fromC
		fromC = 0
	elsif (fromC + num) < 0
		num += fromC
		fromC = chords_array.size
	end
	
	#raise IndexError for out of range transpose value
	ret = chords_array.fetch(fromC + num)		
	 
end

puts transpose("C", 3) #=>D# or Eb
puts transpose("C#",3) #=>E
puts transpose("F#", 4) #=>A#
puts transpose("F#", 5) #=>B
puts transpose("A#", 6) #=>E
puts transpose("A#", 7) #=>F
puts transpose("C#", -1) #=>C
puts transpose("C#", -2) #=>B
puts transpose("C#", -11) #=> D
puts transpose("C",12) #=>C
puts transpose("C",-12) #=>C

begin
	puts transpose("B", 13) #=>IndexError
rescue IndexError =>e
	puts "OK IndexError"
end
begin 
	puts transpose("B", -13) #=>IndexError
	puts "nono, here"
rescue IndexError =>e
	puts "OK IndexError"
end


class Chord
	attr_accessor :notes, :duration
	attr_accessor :base_str, :on_str, :subpart_str
	
	def initialize(base_str, on_str, subpart_str, duration = 4)
		puts "new Chord #{base_str},#{subpart_str},/#{on_str},duration = #{duration}"
		
		@base_str = base_str
		@on_str = on_str
		@subpart_str = subpart_str
		@duration = duration
		parse
	end
	

	def parse
		@notes = []
		if (!on_str.empty?)
			@notes << baseName2NoteNumber(@on_str)
		else
			@notes << baseName2NoteNumber(@base_str)
		end
		
		relatives = case @subpart_str		#you shold have knowledge to understand this!
		when ""
			[4,7]
		when "7"
			[4,7,10]
		when "m"
			[3,7]
		when "m7"
			[3,7,10]
		when "m7(9)"
			[3,7,10,14]
		when "m7b5"
			[3,6,10]
		when "dim", "dim7"
			[3,6,9]
		when "m6"
			[3,7,9]
		when "m9"
			[3,7,14]
		when "M7","M"
			[4,7,11]
		when "6"
			[4,9]
		when "69"
			[4,9,14]
		when "7b5"
			[4,6,10]
		when "9"
			[4,7,14]
		when "7(9)"
			[4,7,10,14]
		when "7+9"
			[4,7,10,15]
		when "7-9"
			[4,7,10,13]
		when "7(13)", "(13)"
			[4,7,10,21]
		when "7(-13)"
			[4,7,10,20]
		when "7(+13)"
			[4,7,10,22]
		else
			raise "\"#{@subpart_str}\"not supported"
		end
		
		relatives.each do |r|
			@notes << baseName2NoteNumber(@base_str) + r
		end		
	end

	def to_s
		ret = case @duration 
		when 1
			""
		when 2
			" "
		when 4
			"  "
		end
		ret << "#{@base_str}#{@subpart_str}"
		ret << "/#{@on_str}" unless @on_str.empty?
		ret << case @duration
		when 1
			""
		when 2
			" "
		when 4
			"  "
		end
	end
	
	def transpose!(num)
		@duration = @duration
		@base_str = transpose(@base_str, num)
		@on_str = transpose(@on_str, num) unless @on_str.empty?
		@subpart_str = @subpart_str
		parse
		#more to be done...
		self
	end
end


p Chord.new("C#","","m7",2).to_s
p Chord.new("C#","","m7",2).transpose!(2).to_s #=>
p Chord.new("Eb","","m6",2).transpose!(2).to_s #=>F


#TODO: Consider this to be singleton class
class ChordsExtractor
	attr_reader :chords
	
	def initialize(str)
		@notes = []
		@chords = []
		parse(str)
	end
	
private
	def parse(str)
		str.each_line.each_with_index do |line, lineNo|
			begin
				parseLine line.gsub("　"," ")
			rescue =>e
				p e
				raise ChordSyntaxError,"(parse) syntax error at line:#{lineNo + 1},:#{line}"
			end
		end
	end	
	
	def parseLine(line)
		#sanitize
		line = line.lstrip.gsub("\n","")
		
		i = 0
		state  = :none #:none,:after_base

		while(true)
			if (i >= line.size)
				break if state == :none
			end
			
			case state
			when :none
				currentBase = ""
				case line[i..-1]
				when /(Ab|A#|A|Bb|B|C#|C|Db|D#|D|Eb|E|F#|F|Gb|G#|G)(.*)/
					currentBase = $1
					state = :after_base
					i += $1.size
				else
					raise "base can't recognized:#{line[i..-1]}"
				end
				
			when :after_base
				nextCode_index = i
				while(true)
					break if (nextCode_index > line.size)
					if line[nextCode_index] =~/(Ab|A#|A|Bb|B|C#|C|Db|D#|D|Eb|E|F#|F|Gb|G#|G)(.*)/
						if (line[nextCode_index-1] == "/")			#on code
							puts "on code detected"
							nextCode_index += $1.size
							next
						else
							break
						end
					end
					nextCode_index += 1
				end
				
				subpart_and_duration = line[i..nextCode_index-1]
				subpart = ""
				duration = " "
				if (subpart_and_duration =~ /([^ -]*)(.*)/)
					subpart = $1
					if ($2.include?("-9") || $2.include?("-13"))
						if ($2[1..$2.size-1] =~ /([^ -]*).*/)
							subpart << "-" << $1
						end
					end
					duration = subpart_and_duration[subpart.size..-1]
				end
				
				if (duration =~ /([ ]*).*/)
					duration  = case $1.size
					when 2
						4
					when 1
						2
					when 0
						1
					end
				end

				p subpart
				p duration
				
				if (subpart =~ /(.*)\/(.*)/)
					on = $2
					onIgai = $1
				else
					on = ""
					onIgai = subpart
				end
				c = Chord.new(currentBase, on, onIgai, duration)
				@chords << c
				
				i = nextCode_index
				state = :none
			end
		end
		@chords
	end
end

$soundDelegate = SoundDelegate.new
$scheduler = MyScheduler.sharedMyScheduler
$scheduler.soundDelegate = $soundDelegate
				 
class Controller
	attr_accessor :field				   
					   
	def awakeFromNib
		puts"ChordPlayer awaken"
		
		@field.setFont(NSFont.fontWithName("Osaka-Mono", size:18))
		@field.string = <<-END.gsub(/^\t\t\t/,"")
			AM7/C# - Cdim - Bm7 - Cdim 
			C#m7 - C#7 - DM7 - Dm6 
			Bm7 - Bm7b5 - G#m7 - Ebdim7 
			Bm7 - Bm7b5 
			A#m7b5-Gm6-B7-Fdim7
			C#m7b5-F#-Gm6-F#7+9
			Bm7 - F#m6 - Fdim7 
		END
		
		initAudioEngine()
		initSoundDelegate()
		@audioEngine.start()	
	end
	
	def initAudioEngine
		@audioEngine = AudioOutputEngine.new
		@audioEngine.initCoreAudio
	end
	
	def initSoundDelegate
		@soundDelegate = $soundDelegate
		@audioEngine.delegate = @soundDelegate
	end
		
	def transpose(num)
		string = @field.string

		string = string.each_line.map do |line|
			line_chords = ChordsExtractor.new(line).chords
			line_chords.map do |chord|
				chord.transpose!(num).to_s
			end.join("-").lstrip
		end.join("\n")
		@field.string = string
	end
	
	def up(sender)
		begin
			transpose(1)
		rescue =>e
			NSLog("error occured")
		end
	end
	
	def down(sender)
		begin
			transpose(-1)
		rescue =>e
			NSLog("error occured")
		end
	end
	
	def doplay(sender)
		#Here is what things happen.
		begin
			@field.string.play
		rescue ChordSyntaxError => e
			p e
			alert = NSAlert.alertWithMessageText("error",
					defaultButton:"OK",
					alternateButton:nil,
					otherButton:nil,
					informativeTextWithFormat:"syntax error.#{e.description})")
			alert.alertStyle = NSWarningAlertStyle
			alert.runModal
		else
			
		end
		
	end

end