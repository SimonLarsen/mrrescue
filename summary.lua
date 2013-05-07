summary = {}

local lg = love.graphics

function summary.enter()
	state = STATE_SUMMARY
	stopMusic()
end

function summary.update(dt)
end

function summary.draw()
	lg.push()
	lg.scale(config.scale)

	lg.printf("YOUR SCORE:", 0, 32, WIDTH, "center")
	lg.printf(score, 0, 48, WIDTH, "center")

	lg.printf("YOU SAVED "..saved.." CIVILIANS", 0, 80, WIDTH, "center")
	lg.printf("LONGEST COMBO: " .. max_combo, 0, 96, WIDTH, "center")
	lg.printf("TOTAL TIME: ".. secondsToString(time), 0, 112, WIDTH, "center")
	lg.printf("FLOORS CLEARED: " .. (section-1)*3, 0, 128, WIDTH, "center")

	lg.printf("PRESS RETURN TO CONTINUE", 0, 160, WIDTH, "center")
	lg.pop()
end

function summary.keypressed(k, uni)
	if k == " " or k == "return" then
		highscore_entry.enter()
	end
end

function summary.action(k)
	if k == "jump" or k == "action" or k == "pause" then
		highscore_entry.enter()
	end
end
