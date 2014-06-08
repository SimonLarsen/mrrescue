default_config = {
	scale = 3,
	fullscreen = 0,
	vsync = true,
	sfx_volume = 1.0,
	music_volume = 0.5,
	keys = {
			up = "up", down = "down", left = "left", right = "right", jump = "s", shoot = "d", action = "a"
	},
	joykeys = {
		jump = 1, shoot = 3, action = 2, pause = 8
	}
}

keynames = {"up","down","left","right","jump","shoot","action"}
joykeynames = {"jump","shoot","action","pause"}

highscores = { {}, {}, {} }

stats = { 0, 0, 0, 0, 0, 0 }

keystate = {
	up = false, down = false, left = false, right = false,
	jump = false, shoot = false, action = false,
	oldaxis1 = 0, oldaxis2 = 0
}

function loadConfig()
	-- Read default settings first
	config = {}
	for i,v in pairs(default_config) do
		if type(v) == "table" then
			config[i] = {}
			for j,w in pairs(v) do
				config[i][j] = w
			end
		else
			config[i] = v
		end
	end
	if love.filesystem.exists("settings") then
		local data = love.filesystem.read("settings")
		local file = TSerial.unpack(data)
		for i,v in pairs(file) do
			config[i] = v
		end
	end
	-- Avoid crash if fullscreen is a boolean from old version
	if type(config.fullscreen) == "boolean" then
		config.fullscreen = 0
	end
end

function loadHighscores()
	if love.filesystem.exists("highscores") then
		local data = love.filesystem.read("highscores")
		local file = TSerial.unpack(data)
		for i=1,3 do
			if file[i] then
				highscores[i] = file[i]
			end
		end
	end
end

function loadStats()
	if love.filesystem.exists("stats") then
		local data = love.filesystem.read("stats")
		stats = TSerial.unpack(data)
	end
end

function saveConfig()
	local data = TSerial.pack(config)
	love.filesystem.write("settings", data)
end

function saveHighscores()
	local data = TSerial.pack(highscores)
	love.filesystem.write("highscores", data)
end

function saveStats()
	local data = TSerial.pack(stats)
	love.filesystem.write("stats", data)
end

function setMode()
	if config.fullscreen == 0 then
		love.window.setMode(WIDTH*config.scale, HEIGHT*config.scale, {fullscreen=false, vsync=config.vsync})
		love.graphics.setScissor()
	elseif config.fullscreen > 0 and config.fullscreen <= 3 then
		love.window.setMode(0,0, {fullscreen=true, vsync=config.vsync})
		love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {fullscreen=true, vsync=config.vsync})
	end
	fs_translatex = (love.graphics.getWidth()-WIDTH*config.scale)/2
	fs_translatey = (love.graphics.getHeight()-HEIGHT*config.scale)/2
end

function toggleVSync()
	config.vsync = not config.vsync
	setMode()
end

function defaultKeys()
	for i,v in pairs(default_config.keys) do
		config.keys[i] = v
	end
end

function defaultJoyKeys()
	for i,v in pairs(default_config.joykeys) do
		config.joykeys[i] = v
	end
end
