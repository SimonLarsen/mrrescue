options = {}

local lg = love.graphics

function options.enter()
	state = STATE_OPTIONS
	options.selection = 1
end

function options.update(dt)
	updateKeys()
end

function options.draw()
	lg.push()
	lg.scale(config.scale)

	lg.setFont(font.bold)

	drawBox(40, 59, 176, 110)

	lg.printf("OPTIONS", 0, 37, WIDTH, "center")
	lg.print("SCALE:", 65, 71)		lg.print(config.scale, 167, 71)
	lg.print("VSYNC:", 65, 84)		lg.print(config.vsync and "ON" or "OFF", 167, 84)
	lg.print("SOUND VOL:", 65, 97)	lg.print(math.floor(config.sfx_volume*10), 167, 97)
	lg.print("MUSIC VOL:", 65, 110)	lg.print(math.floor(config.music_volume*10), 167, 110)
	lg.print("KEYBOARD", 65, 123)
	lg.print("JOYSTICK", 65, 136)
	lg.print("BACK", 65, 149)

	lg.print(">", 52, 57+options.selection*13)

	lg.pop()
end

function options.keypressed(k, uni)
	if k == "down" then
		options.selection = wrap(options.selection + 1, 1,7)
		playSound("blip")
	elseif k == "up" then
		options.selection = wrap(options.selection - 1, 1,7)
		playSound("blip")

	elseif k == "left" or k == "right" then
		if options.selection == 1 then -- SCALE
			if k == "left" then
				config.scale = cap(config.scale - 1, 1, 10)
			else
				config.scale = cap(config.scale + 1, 1, 10)
			end
			setMode()
			playSound("blip")
		elseif options.selection == 2 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 3 then -- SFX VOLUME
			if k == "left" then
				config.sfx_volume = cap(config.sfx_volume - 0.1, 0,1)
			else
				config.sfx_volume = cap(config.sfx_volume + 0.1, 0,1)
			end
			love.audio.tags.sfx.setVolume(config.sfx_volume)
			playSound("blip")
		elseif options.selection == 4 then -- MUSIC VOLUME
			if k == "left" then
				config.music_volume = cap(config.music_volume - 0.1, 0,1)
			else
				config.music_volume = cap(config.music_volume + 0.1, 0,1)
			end
			love.audio.tags.music.setVolume(config.music_volume)
			playSound("blip")
		end

	elseif k == "return" then
		if options.selection == 2 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 5 then -- KEYBOARD
			playSound("confirm")
			keyboard.enter()
		elseif options.selection == 6 then -- JOYSTICK
			playSound("confirm")
			joystick.enter()
		elseif options.selection == 7 then -- BACK
			playSound("confirm")
			mainmenu.enter()
			saveConfig()
		end
	elseif k == "escape" then
		playSound("confirm")
		mainmenu.enter()
		saveConfig()
	end
end

function options.joystickpressed(joy, k)
	if k == 3 then
		if options.selection == 2 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 5 then -- KEYBOARD
			playSound("confirm")
			keyboard.enter()
		elseif options.selection == 6 then -- JOYSTICK
			playSound("confirm")
			joystick.enter()
		elseif options.selection == 7 then -- BACK
			playSound("confirm")
			mainmenu.enter()
			saveConfig()
		end
	end
end

function options.action(k)
	if k == "down" then
		options.selection = wrap(options.selection + 1, 1,7)
		playSound("blip")
	elseif k == "up" then
		options.selection = wrap(options.selection - 1, 1,7)
		playSound("blip")

	elseif k == "left" or k == "right" then
		if options.selection == 1 then -- SCALE
			if k == "left" then
				config.scale = cap(config.scale - 1, 1, 10)
			else
				config.scale = cap(config.scale + 1, 1, 10)
			end
			setMode()
			playSound("blip")
		elseif options.selection == 2 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 3 then -- SFX VOLUME
			if k == "left" then
				config.sfx_volume = cap(config.sfx_volume - 0.1, 0,1)
			else
				config.sfx_volume = cap(config.sfx_volume + 0.1, 0,1)
			end
			love.audio.tags.sfx.setVolume(config.sfx_volume)
			playSound("blip")
		elseif options.selection == 4 then -- MUSIC VOLUME
			if k == "left" then
				config.music_volume = cap(config.music_volume - 0.1, 0,1)
			else
				config.music_volume = cap(config.music_volume + 0.1, 0,1)
			end
			love.audio.tags.music.setVolume(config.music_volume)
			playSound("blip")
		end
	end
end
