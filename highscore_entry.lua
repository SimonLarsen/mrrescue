highscore_entry = {}

local lg = love.graphics

function highscore_entry.enter()
	state = STATE_HIGHSCORE_ENTRY
	highscore_entry.name = "_____"
	highscore_entry.selection = 1
	highscore_entry.position = 1

	local scores = highscores[level]
	local rank = 0
	for i=1,10 do
		if scores[i] then
			if scores[i].score < score then
				rank = i
				break
			end
		else
			rank = i
			break
		end
	end

	if rank == 0 then
		highscore_list.enter(level,rank)
	else
		highscore_entry.rank = rank
	end
end

function highscore_entry.update(dt)
	updateKeys()
end

function highscore_entry.draw()
	lg.push()
	lg.scale(config.scale)

	lg.printf("NEW HIGHSCORE!", 0, 32, WIDTH, "center")
	lg.printf("PLEASE ENTER YOUR NAME", 0, 48, 256, "center")

	local char = 1
	for iy = 1,3 do
		for ix = 1,10 do
			if highscore_entry.selection == char then
				lg.rectangle("fill", 33+ix*16, 66+iy*16, 14, 14)
				lg.setColor(0,0,0,255)
				lg.print(KEYBOARD:sub(char,char), 37+ix*16, 70+iy*16)
				lg.setColor(255,255,255,255)
			else
				lg.print(KEYBOARD:sub(char,char), 37+ix*16, 70+iy*16)
			end
			char = char + 1
		end
	end

	for i=1,5 do
		lg.print(highscore_entry.name:sub(i,i), 86+i*14, 158)
	end

	lg.pop()
end

function highscore_entry.addChar(c)
	local char = c or KEYBOARD:sub(highscore_entry.selection,highscore_entry.selection)
	local head = highscore_entry.name:sub(1,highscore_entry.position-1)
	local tail = highscore_entry.name:sub(highscore_entry.position+1, 5)
	highscore_entry.name = head .. char .. tail
	highscore_entry.position = cap(highscore_entry.position + 1, 1, 6)
	playSound("confirm")
end

function highscore_entry.delete()
	highscore_entry.position = cap(highscore_entry.position - 1, 1, 6)
	local head = highscore_entry.name:sub(1,highscore_entry.position-1)
	highscore_entry.name = head .. string.rep("_", 6-highscore_entry.position)
	playSound("blip")
end

function highscore_entry.confirm()
	local newname = highscore_entry.name:gsub("_"," ")
	local entry = {name=newname, score=score}
	table.insert(highscores[level], highscore_entry.rank, entry)
	highscore_list.enter(level,highscore_entry.rank)
	playSound("confirm")
end

function highscore_entry.keypressed(k)
	if k == "right" then
		if highscore_entry.selection % 10 == 0 then
			highscore_entry.selection = highscore_entry.selection - 9
		else
			highscore_entry.selection = highscore_entry.selection + 1
		end
		playSound("blip")
	elseif k == "left" then
		if highscore_entry.selection % 10 == 1 then
			highscore_entry.selection = highscore_entry.selection + 9
		else
			highscore_entry.selection = highscore_entry.selection - 1
		end
		playSound("blip")
	elseif k == "down" then
		if highscore_entry.selection >= 21 then
			highscore_entry.selection = highscore_entry.selection - 20
		else
			highscore_entry.selection = highscore_entry.selection + 10
		end
		playSound("blip")
	elseif k == "up" then
		if highscore_entry.selection <= 10 then
			highscore_entry.selection = highscore_entry.selection + 20
		else
			highscore_entry.selection = highscore_entry.selection - 10
		end
		playSound("blip")
	elseif k == "return" then
		if highscore_entry.selection <= 28 then
			if highscore_entry.position <= 5 then
				highscore_entry.addChar()
			end
		elseif highscore_entry.selection == 29 then
			highscore_entry.delete()
		else
			highscore_entry.confirm()
		end
	elseif k == "backspace" then
		highscore_entry.delete()
	end
end

function highscore_entry.textinput(k)
	local uni = k:byte()
	if (uni >= 97 and uni <= 122) or k == " " or k == "-" then
		if highscore_entry.position <= 5 then
			if k == " " then
				highscore_entry.addChar("_")
			else
				highscore_entry.addChar(string.upper(k))
			end
		end
		highscore_entry.selection = 30
	end
end

function highscore_entry.action(k)
	if k == "right" then
		if highscore_entry.selection % 10 == 0 then
			highscore_entry.selection = highscore_entry.selection - 9
		else
			highscore_entry.selection = highscore_entry.selection + 1
		end
		playSound("blip")
	elseif k == "left" then
		if highscore_entry.selection % 10 == 1 then
			highscore_entry.selection = highscore_entry.selection + 9
		else
			highscore_entry.selection = highscore_entry.selection - 1
		end
		playSound("blip")
	elseif k == "down" then
		if highscore_entry.selection >= 21 then
			highscore_entry.selection = highscore_entry.selection - 20
		else
			highscore_entry.selection = highscore_entry.selection + 10
		end
		playSound("blip")
	elseif k == "up" then
		if highscore_entry.selection <= 10 then
			highscore_entry.selection = highscore_entry.selection + 20
		else
			highscore_entry.selection = highscore_entry.selection - 10
		end
		playSound("blip")
	elseif k == "jump" then
		if highscore_entry.selection <= 28 then
			if highscore_entry.position <= 5 then
				highscore_entry.addChar()
			end
		elseif highscore_entry.selection == 29 then
			highscore_entry.delete()
		else
			highscore_entry.confirm()
		end
	elseif k == "pause" then
		highscore_entry.confirm()
	elseif k == "action" then
		highscore_entry.delete()
	end
end
