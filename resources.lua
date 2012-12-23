local lg = love.graphics

img = {}  	-- global Image objects
quad = {}	-- global Quads

IMAGE_FILES = {
	"tiles", "door",
	"hud", "hud2", "water_bar", "overloaded_bar",
	"stream", "water",
	"shards",
	"fire_wall", "fire_wall_small", "fire_floor",
	"black_smoke", "ashes",
	"light_player", "light_fire",

	"player_gun",
	"player_throw",
	"player_climb_down",
	"player_climb_up",
	"player_running",

	"enemy_normal_run", "enemy_normal_hit", "enemy_normal_recover", "enemy_jumper_hit",
	"enemy_jumper_jump", "enemy_jumper_recover", 

	"human_1_run", "human_2_run", "human_3_run", "human_4_run",
	"human_1_carry_left", "human_2_carry_left", "human_3_carry_left", "human_4_carry_left",
	"human_1_carry_right", "human_2_carry_right", "human_3_carry_right", "human_4_carry_right",
	"human_1_fly", "human_2_fly", "human_3_fly", "human_4_fly",
	"human_1_burn", "human_2_burn", "human_3_burn", "human_4_burn",
	"human_1_panic", "human_2_panic", "human_3_panic", "human_4_panic"
}

BACKGROUND_FILES = {
	"mountains", "night"
}

--- Returns size of an Image as two return values
-- Saves some typing when creating quads
function getSize(img)
	return img:getWidth(), img:getHeight()
end

--- Load all resources including images, quads sound effects etc.
function loadResources()
	-- Create canvas for lighting effects
	canvas = lg.newCanvas(256,256)
	canvas:setFilter("nearest","nearest")

	-- Load all images
	for i,v in ipairs(IMAGE_FILES) do
		img[v] = lg.newImage("data/"..v..".png")
	end
	for i,v in ipairs(BACKGROUND_FILES) do
		img[v] = lg.newImage("data/backgrounds/"..v..".png")
	end

	img.human_run = { img.human_1_run, img.human_2_run, img.human_3_run, img.human_4_run }
	img.human_carry_left = { img.human_1_carry_left, img.human_2_carry_left, img.human_3_carry_left, img.human_4_carry_left }
	img.human_carry_right = { img.human_1_carry_right, img.human_2_carry_right, img.human_3_carry_right, img.human_4_carry_right }
	img.human_fly = { img.human_1_fly, img.human_2_fly, img.human_3_fly, img.human_4_fly }
	img.human_burn = { img.human_1_burn, img.human_2_burn, img.human_3_burn, img.human_4_burn }
	img.human_panic = { img.human_1_panic, img.human_2_panic, img.human_3_panic, img.human_4_panic }

	-- Set special image attributes
	img.stream:setWrap("repeat", "clamp")

	quad.player_gun = {}
	for i=0,4 do
		quad.player_gun[i] = lg.newQuad(i*12,0,12,18, getSize(img.player_gun))
	end

	quad.door_normal  = lg.newQuad( 0,0, 8,48, getSize(img.door))
	quad.door_damaged = lg.newQuad(16,0, 8,48, getSize(img.door))

	quad.water_out = {}
	quad.water_out[0] = lg.newQuad(0,0, 8,15, getSize(img.water))
	quad.water_out[1] = lg.newQuad(16,0, 8,15, getSize(img.water))

	quad.water_end = {}
	quad.water_end[0] = lg.newQuad(32,0, 16,15, getSize(img.water))
	quad.water_end[1] = lg.newQuad(48,0, 16,15, getSize(img.water))

	quad.water_hit = {}
	for i=0,2 do
		quad.water_hit[i] = lg.newQuad(i*16, 16, 16, 19, getSize(img.water))
	end

	quad.shard = {}
	for i=0,7 do
		quad.shard[i] = lg.newQuad(i*8,0,8,8, getSize(img.shards))
	end

	quad.tile = {}
	local id = 1
	for iy = 0,15 do
		for ix = 0,15 do
			quad.tile[id] = lg.newQuad(ix*16, iy*16, 16, 16, getSize(img.tiles))
			id = id + 1
		end
	end

	quad.fire_wall = {}
	for i=0,4 do
		quad.fire_wall[i] = lg.newQuad(i*24, 0, 24, 32, getSize(img.fire_wall))
	end
	quad.fire_floor = {}
	for i=0,3 do
		quad.fire_floor[i] = lg.newQuad(i*16, 0, 16, 16, getSize(img.fire_floor))
	end

	quad.light_fire = {}
	for i=0,4 do
		quad.light_fire[i] = lg.newQuad(i*85, 0, 85, 85, getSize(img.light_fire))
	end

	quad.water_bar = lg.newQuad(0,0, 1,1, getSize(img.water_bar))
end
