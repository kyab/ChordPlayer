#
#  Controller.rb
#  ChordPlayer
#
#  Created by 吉岡 紘二 on 12/05/13.
#  Copyright 2012年 __MyCompanyName__. All rights reserved.
#

class NSString		
	def play
		Chords.new(self).play
	end
end

class Chord
	attr_accessor :notes
	def initialize(base,on,subpart)
		puts "new Chord #{base},#{subpart},/#{on}"
		@notes = []
		if (on != "")
			@notes << baseName2NoteNumber(on)
		else
			@notes << baseName2NoteNumber(base)
		end
		
		relatives = case subpart		#you shold have knowledge to understand this!
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
		when "M7","M"
			[4,7,11]
		when "6"
			[4,9]
		when "69"
			[4,9,14]
		when "7b5"
			[4,6,10]
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
		else
			raise "#{subpart}not supported"
		end
		
		relatives.each do |r|
			@notes << baseName2NoteNumber(base) + r
		end
		
			
	end
end

class Chords

	def initialize(str)
		@notes = []
		@chords = []
		parse(str)
	end
	
	def parse(str)
		str.each_line do |line|
			p line
			parseLine(line.gsub("　"," ").strip)
		end
	end	
	
	def parseLine(line)
		line.strip!
		
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
					if line[nextCode_index] =~/[ABCDEFG]/
						if (line[nextCode_index-1] == "/")			#on code
							puts "on code detected"
							nextCode_index += 1
							next
						else
							break
						end
					end
					nextCode_index += 1
				end
				
				subpart_and_duration = line[i..nextCode_index-1]
				subpart = ""
				
				if (subpart_and_duration =~ /([^ -]*)(.*)/)

					subpart = $1
					if ($2.include?("-9") || $2.include?("-13"))
						target = $2[1..$2.size-1]
						if (target =~ /([^ -]*)(.*)/)
							subpart << "-" << $1
						end
					end
					
				end
				
				if (subpart =~ /(.*)\/(.*)/)
					on = $2
					onIgai = $1
				else
					on = ""
					onIgai = subpart
				end
				c = Chord.new(currentBase, on, onIgai)

				@chords << c
				i = nextCode_index
				state = :none
			end
		end
	end
	
	def play
		@chords.each do |chord|
			chord.notes.each do |note|
				$scheduler.noteOn(note)
			end
			
			sleep(1.0)
			
			chord.notes.each do |note|
				$scheduler.noteOff(note)
			end
		end
	end
			
end

def baseName2NoteNumber(baseName)
	case baseName
	when "C"
		63
	when "C#", "Db"
		64
	when "D", "D"
		65
	when "D#", "Eb"
		66
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
	else
		raise "#{baseName} can't be recognized as base note name."
	end
end
	
def noteName2noteNumber(noteName)

	case noteName
	when "c"
		63
	when "c#", "db"
		64
	when "d"
		65
	when "d#", "eb"
		66
	when "e"
		67
	when "f"
		68
	when "f#","gb"
		69
	when "g"
		70
	when "g#", "ab"
		71
	when "a"
		72
	when "a#","bb"
		73
	when "b"
		74
	else
		raise "#{noteName} can't be recognized as note name."
	end
end


$soundDelegate = SoundDelegate.new
$scheduler = MyScheduler.sharedMyScheduler
$scheduler.soundDelegate = $soundDelegate
				 
class Controller
	attr_accessor :field				   
					   
	def awakeFromNib
		puts"ChordPlayer awaken"
		initAudioEngine()
		initSoundDelegate()
		@audioEngine.start()
		
		@field.setFont(NSFont.fontWithName("Osaka-Mono", size:18))
		
	end
	
	def initAudioEngine
		@audioEngine = AudioOutputEngine.new
		@audioEngine.initCoreAudio
	end
	
	def initSoundDelegate
		@soundDelegate = $soundDelegate
		@audioEngine.delegate = @soundDelegate
	end
	
	def doplay(sender)
	
		#Here is what things happen.
		@field.string.play
	end

end