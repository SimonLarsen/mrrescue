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

	drawBox(40, 51, 176, 123)

	lg.printf("OPTIONS", 0, 37, WIDTH, "center")
	lg.print("SCALE:", 65, 63)		lg.print(config.scale, 167, 63)
	lg.print("FULLSCREEN:", 65, 76)
	if config.fullscreen == 0 then		lg.print("OFF", 167, 76)
	elseif config.fullscreen == 1 then	lg.print("FILL", 167, 76)
	elseif config.fullscreen == 2 then	lg.print("ZOOM", 167, 76)
	else								lg.print("SCALE", 167, 76)
	end
	lg.print("VSYNC:", 65, 89)		lg.print(config.vsync and "ON" or "OFF", 167, 89)
	lg.print("SOUND VOL:", 65, 102)	lg.print(math.floor(config.sfx_volume*10+0.01), 167, 102)
	lg.print("MUSIC VOL:", 65, 115)	lg.print(math.floor(config.music_volume*10+0.01), 167, 115)
	lg.print("KEYBOARD", 65, 128)
	lg.print("JOYSTICK", 65, 141)
	lg.print("BACK", 65, 154)

	lg.print(">", 52, 49+options.selection*13)

	lg.pop()
end

function options.keypressed(k, uni)
	if k == "down" then
		options.selection = wrap(options.selection + 1, 1,8)
		playSound("blip")
	elseif k == "up" then
		options.selection = wrap(options.selection - 1, 1,8)
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
		elseif options.selection == 2 then -- FULLSCREEN
			if k == "left" then
				if config.fullscreen > 0 then
					config.fullscreen = cap(config.fullscreen - 1, 0, 3)
					setMode()
				end
			else
				if config.fullscreen < 3 then
					config.fullscreen = cap(config.fullscreen + 1, 0, 3)
					setMode()
				end
			end
			playSound("blip")
		elseif options.selection == 3 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 4 then -- SFX VOLUME
			if k == "left" then
				config.sfx_volume = cap(config.sfx_volume - 0.1, 0,1)
			else
				config.sfx_volume = cap(config.sfx_volume + 0.1, 0,1)
			end
			love.audio.tags.sfx.setVolume(config.sfx_volume)
			playSound("blip")
		elseif options.selection == 5 then -- MUSIC VOLUME
			if k == "left" then
				config.music_volume = cap(config.music_volume - 0.1, 0,1)
			else
				config.music_volume = cap(config.music_volume + 0.1, 0,1)
			end
			love.audio.tags.music.setVolume(config.music_volume)
			playSound("blip")
		end

	elseif k == "return" then
		if options.selection == 3 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 6 then -- KEYBOARD
			playSound("confirm")
			keyboard.enter()
		elseif options.selection == 7 then -- JOYSTICK
			playSound("confirm")
			joystick.enter()
		elseif options.selection == 8 then -- BACK
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

function options.action(k)
	if k == "down" then
		options.selection = wrap(options.selection + 1, 1,8)
		playSound("blip")
	elseif k == "up" then
		options.selection = wrap(options.selection - 1, 1,8)
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
		elseif options.selection == 2 then -- FULLSCREEN
			if k == "left" then
				if config.fullscreen > 0 then
					config.fullscreen = cap(config.fullscreen - 1, 0, 3)
					setMode()
				end
			else
				if config.fullscreen < 3 then
					config.fullscreen = cap(config.fullscreen + 1, 0, 3)
					setMode()
				end
			end
			playSound("blip")
		elseif options.selection == 3 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 4 then -- SFX VOLUME
			if k == "left" then
				config.sfx_volume = cap(config.sfx_volume - 0.1, 0,1)
			else
				config.sfx_volume = cap(config.sfx_volume + 0.1, 0,1)
			end
			love.audio.tags.sfx.setVolume(config.sfx_volume)
			playSound("blip")
		elseif options.selection == 5 then -- MUSIC VOLUME
			if k == "left" then
				config.music_volume = cap(config.music_volume - 0.1, 0,1)
			else
				config.music_volume = cap(config.music_volume + 0.1, 0,1)
			end
			love.audio.tags.music.setVolume(config.music_volume)
			playSound("blip")
		end
	elseif k == "jump" then
		if options.selection == 2 then -- FULLSCREEN
			toggleFullscreen()
			playSound("blip")
		elseif options.selection == 3 then -- VSYNC
			toggleVSync()
			playSound("blip")
		elseif options.selection == 6 then -- KEYBOARD
			playSound("confirm")
			keyboard.enter()
		elseif options.selection == 7 then -- JOYSTICK
			playSound("confirm")
			joystick.enter()
		elseif options.selection == 8 then -- BACK
			playSound("confirm")
			mainmenu.enter()
			saveConfig()
		end
	elseif k == "action" then
		playSound("confirm")
		mainmenu.enter()
		saveConfig()
	end
end
