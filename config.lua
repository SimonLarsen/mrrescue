default_config = {
	scale = 3,
	vsync = true,
	sfx_volume = 1.0,
	music_volume = 0.5
}

function loadConfig()
	config = {}
	for i,v in pairs(default_config) do
		config[i] = v
	end
end

function setMode()
	love.graphics.setMode(WIDTH*config.scale, HEIGHT*config.scale, false, config.vsync)
end

function toggleVSync()
	config.vsync = not config.vsync
	setMode()
end
