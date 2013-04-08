keyboard = {}

local lg = love.graphics

function keyboard.enter()
	state = STATE_KEYBOARD
	keyboard.selection = 1
	keyboard.waiting = false
end

function keyboard.update(dt)
	updateKeys()
end

function keyboard.draw()
	lg.push()
	lg.scale(config.scale)
	lg.setFont(font.bold)

	drawBox(40, 41, 176, 134)

	lg.printf("SET KEYBOARD", 0, 26, WIDTH, "center")
	for i,v in ipairs(keynames) do
		if keyboard.waiting == true and i == keyboard.selection then
			lg.setColor(195,52,41)
		end
		lg.print(string.upper(v), 65, 40+i*13)
		if config.keys[v] == " " then
			lg.print("SPACE", 154, 40+i*13)
		elseif config.keys[v] == "none" then
			lg.setColor(118,31,25)
			lg.print("NONE", 154, 40+i*13)
			lg.setColor(255,255,255)
		else
			lg.print(string.upper(config.keys[v]:sub(1,7)), 154, 40+i*13)
		end
		lg.setColor(255,255,255)
	end
	lg.print("DEFAULT", 65, 144)
	lg.print("BACK", 65, 157)

	lg.print(">", 52, 40+keyboard.selection*13)

	lg.pop()
end

function keyboard.keypressed(k, uni)
	if keyboard.waiting == false then
		if k == "down" then
			keyboard.selection = wrap(keyboard.selection + 1, 1, 9)
			playSound("blip")
		elseif k == "up" then
			keyboard.selection = wrap(keyboard.selection - 1, 1, 9)
			playSound("blip")
		
		elseif k == "return" then
			if keyboard.selection >= 1 and keyboard.selection <= 7 then
				playSound("blip")
				keyboard.waiting = true
			elseif keyboard.selection == 8 then -- DEFAULT
				playSound("confirm")
				defaultKeys()
			elseif keyboard.selection == 9 then -- BACK
				playSound("confirm")
				options.enter()
			end
		elseif k == "escape" then
			playSound("confirm")
			options.enter()
		end
	else
		if k ~= "escape" then
			for i,v in ipairs(keynames) do
				if config.keys[v] == k then
					config.keys[v] = "none"
				end
			end
			config.keys[keynames[keyboard.selection]] = k
		end
		playSound("blip")
		keyboard.waiting = false
	end
end

function keyboard.action(k)
	if keyboard.waiting == false then
		if k == "down" then
			keyboard.selection = wrap(keyboard.selection + 1, 1, 9)
			playSound("blip")
		elseif k == "up" then
			keyboard.selection = wrap(keyboard.selection - 1, 1, 9)
			playSound("blip")
		elseif k == "jump" then
			if keyboard.selection >= 1 and keyboard.selection <= 7 then
				playSound("blip")
				keyboard.waiting = true
			elseif keyboard.selection == 8 then -- DEFAULT
				playSound("confirm")
				defaultKeys()
			elseif keyboard.selection == 9 then -- BACK
				playSound("confirm")
				options.enter()
			end
		elseif k == "action" then
			playSound("confirm")
			options.enter()
		end
	end
end
