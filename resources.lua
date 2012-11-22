img = {}  	-- global Image objects
quad = {}	-- global Quads

IMAGE_FILES = {
	-- Sprites
	"tiles",
	"player_gun",
	"player_climb_down",
	"player_climb_up",
	"player_running",
	"door",
	"stream",
	"water",
	"shards",
	"enemy_normal_run",
	"enemy_normal_hit",
	"enemy_normal_recover"
}

BACKGROUND_FILES = {
	"mountains"
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
	for i,v in ipairs(BACKGROUND_FILES) do
		img[v] = love.graphics.newImage("data/backgrounds/"..v..".png")
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

	quad.door_normal  = love.graphics.newQuad( 0,0, 8,48, getSize(img.door))
	quad.door_damaged = love.graphics.newQuad(16,0, 8,48, getSize(img.door))

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

	quad.shard = {}
	for i=0,7 do
		quad.shard[i] = love.graphics.newQuad(i*8,0,8,8, getSize(img.shards))
	end

	quad.tile = {}
	local id = 1
	for iy = 0,15 do
		for ix = 0,15 do
			quad.tile[id] = love.graphics.newQuad(ix*16, iy*16, 16, 16, getSize(img.tiles))
			id = id + 1
		end
	end
end
