img = {}  	-- global Image objects
quad = {}	-- global Quads

local IMAGE_FILES = {
	"player_gun",
	"player_climb_down",
	"player_climb_up",
	"player_running",
	"door",
	"stream",
	"water"
}

--- Returns size of an Image as two return values
-- Saves some typing when creating quads
local function getSize(img)
	return img:getWidth(), img:getHeight()
end

--- Load all resources including images, quads sound effects etc.
function loadResources()
	-- Load all images
	for i,v in ipairs(IMAGE_FILES) do
		img[v] = love.graphics.newImage("data/"..v..".png")
	end

	-- Set special image attributes
	img.stream:setWrap("repeat", "clamp")

	-- Create quads
	quad.player_idle = love.graphics.newQuad(45,0,15,22, getSize(img.player_running))
	quad.player_jump = love.graphics.newQuad(15,0,15,22, getSize(img.player_running))

	quad.player_gun = {}
	for i=0,4 do
		quad.player_gun[i] = love.graphics.newQuad(i*12,0,12,18, getSize(img.player_gun))
	end

	quad.door_closed = love.graphics.newQuad(0,0, 8,48, getSize(img.door))
	quad.door_open   = love.graphics.newQuad(16,0, 24,48, getSize(img.door))

	quad.water_out = {}
	quad.water_out[0] = love.graphics.newQuad(0,0, 8,15, getSize(img.water))
	quad.water_out[1] = love.graphics.newQuad(16,0, 8,15, getSize(img.water))

	quad.water_end = {}
	quad.water_end[0] = love.graphics.newQuad(32,0, 16,15, getSize(img.water))
	quad.water_end[1] = love.graphics.newQuad(48,0, 16,15, getSize(img.water))

	quad.water_hit = {}
	for i=0,2 do
		quad.water_hit[i] = love.graphics.newQuad(i*16, 16, 16, 19, getSize(img.water))
	end
end
