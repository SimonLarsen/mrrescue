default_config = {
	scale = 3,
	vsync = true,
	sfx_volume = 1.0,
	music_volume = 0.5
}

function loadConfig()
	-- Read default settings first
	config = {}
	for i,v in pairs(default_config) do
		config[i] = v
	end
	if love.filesystem.exists("settings") then
		local data = love.filesystem.read("settings")
		local file = TSerial.unpack(data)
		for i,v in pairs(file) do
			config[i] = v
		end
	end
end

function saveConfig()
	local data = TSerial.pack(config)
	love.filesystem.write("settings", data)
end

function setMode()
	love.graphics.setMode(WIDTH*config.scale, HEIGHT*config.scale, false, config.vsync)
end

function toggleVSync()
	config.vsync = not config.vsync
	setMode()
end
