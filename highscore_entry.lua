highscore_entry = {}

local lg = love.graphics

function highscore_entry.enter()
	state = STATE_HIGHSCORE_ENTRY

	local scores = highscores[level]
	local position = 0
	for i=1,10 do
		if scores[i] then
			if scores[i].score < score then
				table.insert(scores, i, {name="BUBBA", score=score})
				position = i
				break
			end
		else
			table.insert(scores, i, {name="GUBBI", score=score})
			position = i
			break
		end
	end

	highscore_list.enter(level,position)
end

function highscore_entry.update(dt)
	
end

function highscore_entry.draw()
	
end

function highscore_entry.keypressed(k, uni)
	
end

function highscore_entry.joystickpressed()
	
end

function highscore_entry.action(k)
	
end
