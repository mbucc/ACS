# From https://raw.github.com/mragray/octo-ipsum/master/octo-ipsum.rb
$future_action = [
	'Deep dive into',
	'Plunge beneath',
	'Explore the depths of',
	'Cast off into',
	'Jump overboard into',
	'Set a course to',
	'Set adrift on',
	'Bail out of',
	'Learn the ropes in',
	'Whistle for the wind in',
	'Fall afoul of'
	]
$past_action = [
	'deep dove into',
	'plunged beneath',
	'explored the depths of',
	'cast off into',
	'jumped overboard into',
	'set a course to',
	'set adrift on',
	'bail out of',
	'learned the ropes of',
	'whistled for the wind in',
	'fell foul of'
	]
$adjectives = [ 
	'watertight',
	'seaworthy and broad in the beam',
	'unforgiving',
	'relentless and uncharted',
	'cold and wet',
	'high and dry'
	]
$nouns = [
	'ship yards of the sea',
	'deep blue sea',
	'Davy Jone\'s Locker',
	'beachcomber\'s saloon',
	'current of fierce waters'
	]
$misc = [
	'with all hands on deck.',
	'as anchor\'s aweigh.',
	'to battle down.',
	'until the bitter end.',
	'... Gangway!',
	'and stem the tide.',
	'with three sheets to the wind.',
	'as a loose cannon.',
	'before one\'s ship comes home.',
	'before your sails give in.'
	]
$article = ['The', 'A', 'A score of', 'As a', 'When the']

def octo_title() 
	s = $past_action.shuffle.first.to_s + ' ' + $nouns.shuffle.first.to_s  + '.'
	return s.strip
end

def octo_ipsum(paragraphs_n = 1)
	paragraphs = Array.new 

	paragraphs_n.times do

		sentences = Array.new

		rand(2..5).times do 
			sentences.push $future_action.shuffle.first.to_s + ' the ' + 
				$adjectives.shuffle.first.to_s  + ' '     +
				$nouns.shuffle.first.to_s       + ' '     +
				$misc.shuffle.first.to_s
		end
		paragraphs.push sentences.join("  ")
	end

	return paragraphs.join("\n\n")
end
