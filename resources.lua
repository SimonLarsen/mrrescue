local lg = love.graphics

img = {}  	-- global Image objects
quad = {}	-- global Quads
font = {}   -- global Fonts
local snd = {}	-- sound Sources

local IMAGE_FILES = {
	"splash", "tangram", "lovesplashpixel", "howto",
	"tiles", "door", "boldfont", "captain_dialog", "captain_dialog_sad",
	"boss_health", "highscore_panes", "exclamation", "stats_screen",
	"awards", "hud", "hud2", "hud_people", "item_slots", "water_bar",
	"reserve_bar", "overloaded_bar", "temperature_bar", "temperature_bar_blink",
	"stream", "water", "shards", "level_buildings", "menu_box", "countdown",

	"fire_wall", "fire_wall_small", "fire_floor",

	"black_smoke", "black_smoke_small", "ashes", "sparkles",
	"red_screen", "circles", "warning_icons", "popup_text",
	
	"light_player", "light_fire", "light_fireball",
	"item_coolant", "item_reserve", "item_suit", "item_tank", "item_regen",

	"player_gun", "player_throw", "player_climb_down",
	"player_climb_up", "player_running", "player_death",

	"enemy_healthbar",
	"enemy_normal_run", "enemy_normal_hit", "enemy_normal_recover",
	"enemy_thief_run", "enemy_thief_hit", "enemy_thief_recover",
	"enemy_angrynormal_run", "enemy_angrynormal_hit", "enemy_angrynormal_recover",
	"enemy_jumper_hit", "enemy_jumper_jump",
	"enemy_angryjumper_hit", "enemy_angryjumper_jump",
	"enemy_volcano_run", "enemy_volcano_shoot", "enemy_volcano_hit",
	"enemy_angryvolcano_run", "enemy_angryvolcano_shoot", "enemy_angryvolcano_hit", "enemy_fireball",

	"magmahulk_jump", "magmahulk_land", "magmahulk_jump_hit", "magmahulk_land_hit",
	"magmahulk_rage_jump", "magmahulk_rage_land", "shockwave", "magmahulk_portrait",

	"gasleak_idle", "gasleak_hit", "gasleak_walk", "gasleak_shot_walk",
	"gasleak_rage_walk", "gasleak_rage_shot_walk", "gasleak_idle_shot",
	"gasleak_rage_idle_shot", "gasleak_rage_idle",
	"gasleak_transition", "gasleak_portrait", "gasghost", "gasghost_hit",

	"charcoal_bump", "charcoal_daze", "charcoal_daze_hit", "charcoal_idle",
	"charcoal_projectile", "charcoal_roll", "charcoal_shards",
	"charcoal_transform", "charcoal_transition", "charcoal_portrait",
	"charcoal_transform_rage", "charcoal_daze_rage", "charcoal_roll_rage",

	"human_1_run", "human_2_run", "human_3_run", "human_4_run",
	"human_1_carry_left", "human_2_carry_left", "human_3_carry_left", "human_4_carry_left",
	"human_1_carry_right", "human_2_carry_right", "human_3_carry_right", "human_4_carry_right",
	"human_1_fly", "human_2_fly", "human_3_fly", "human_4_fly",
	"human_1_burn", "human_2_burn", "human_3_burn", "human_4_burn",
	"human_1_panic", "human_2_panic", "human_3_panic", "human_4_panic"
}

local BACKGROUND_FILES = { "mountains", "night" }

local SOUND_FILES = { "powerup", "door", "empty", "blip", "confirm", "shoot",
					  "jump", "pss", "endexplosion", "countdown", "transform",
					  "rescue", "glass", "throw", "crash", "bossjump", "enemydie" }

NUM_ROOMS = { [10] = 6, [11] = 6, [17] = 6, [24] = 6 }

NO_CASUALTIES_MESSAGES = {
	"REMEMBER: YOUR JOB IS TO RESCUE PEOPLE.\nNOT TO PUT OUT FIRE!",
	"KEEP UP THE GOOD WORK, BUDDY!\nYOU'RE ON FIRE.\nHE HE HE",
	"REMEMBER TO SCOUT FOR VALUABLE POWERUPS.\nTHEY WILL COME IN HANDY LATER",
	"DON'T WANT TO WASTE WATER ON OPENING DOORS?\nTRY THROWING PEOPLE AT THEM",
	"RESCUING 3 OR MORE PEOPLE IN SHORT SUCCESSION NETS YOU A SMALL BONUS",
	"REMEMBER: COLLECTING COOLANTS IS ESSENTIAL FOR YOUR SURVIVAL"
}

WON_MESSAGES = {
	{"CONGRATULATIONS!","","YOU HAVE BEATEN MR. MAGMA HULK","AND RESCUED THE SMALL BUSINESS",
	 "","NOW TRY TO RESCUE","THE APARTMENT COMPLEX!","","PRESS RETURN TO CONTINUE"},
	{"CONGRATULATIONS!","","YOU HAVE BEATEN MR. GAS LEAK","AND RESCUED THE APARTMENT COMPLEX",
	 "","NOW TRY TO RESCUE","THE BIG CORPORATION!","","PRESS RETURN TO CONTINUE"},
	{"CONGRATULATIONS!","","YOU HAVE BEATEN MR. CHARCOAL","AND RESCUED THE BIG CORPORATION",
	 "","YOU ARE NOW TRUE","MR. RESCUE STAR IN HEART!","","PRESS RETURN TO CONTINUE"}
}

BOSS_MESSAGE = {
	"WATCH OUT,\nMR. RESCUE!\n\nIT'S THE EVIL\nMR. MAGMA HULK!",
	"WATCH OUT,\nMR. RESCUE!\n\nIT'S THE VICIOUS\nMR. GAS LEAK!",
	"WATCH OUT,\nMR. RESCUE!\n\nIT'S THE MALICIOUS\nMR. CHARCOAL!"
}

BUILDING_NAMES = {{"SMALL","BUSINESS"},{"APARTMENT","COMPLEX"},{"BIG","CORPORATION"}}
DIFFICULTY_NAMES = {"EASY", "NORMAL", "HARD"}

KEYBOARD = "ABCDEFGHIJKLMNOPQRSTUVWXYZ_-<&"

stats_interval = {
	{ 300, 900, 2000 },
	{ 30000, 60000, 120000 },
	{ 4000, 8000, 20000 },
	{ 80, 160, 400 },
	{ 18000, 35000, 90000 },
	{ 80, 160, 500 }
}

stats_names = {
	"FIRES EXTINGUISHED", -- 1
	"WATER USED",         -- 2
	"DISTANCE MOVED",     -- 3
	"PEOPLE RESCUED",     -- 4
	"PROPERTY DAMAGE",    -- 5
	"FLOORS SCALED"       -- 6
}

stats_units = { nil, " LITERS", " METERS", nil, " $", nil }

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
	-- Load all sound files
	for i,v in ipairs(SOUND_FILES) do
		snd[v] = love.audio.newSource("data/sfx/"..v..".wav","static")
		snd[v]:addTags("sfx")
	end

	img.human_run = { img.human_1_run, img.human_2_run, img.human_3_run, img.human_4_run }
	img.human_carry_left = { img.human_1_carry_left, img.human_2_carry_left, img.human_3_carry_left, img.human_4_carry_left }
	img.human_carry_right = { img.human_1_carry_right, img.human_2_carry_right, img.human_3_carry_right, img.human_4_carry_right }
	img.human_fly = { img.human_1_fly, img.human_2_fly, img.human_3_fly, img.human_4_fly }
	img.human_burn = { img.human_1_burn, img.human_2_burn, img.human_3_burn, img.human_4_burn }
	img.human_panic = { img.human_1_panic, img.human_2_panic, img.human_3_panic, img.human_4_panic }

	-- Set special image attributes
	img.stream:setWrap("repeat", "clamp")

	-- Create fonts
	font.bold = lg.newImageFont(img.boldfont, " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!'-:*@<>+/_$&?")
	lg.setFont(font.bold)

	-- Create quads
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

	quad.fireball = {}
	quad.light_fireball = {}
	for i=0,3 do
		quad.fireball[i] = lg.newQuad(i*8, 0, 8, 8, getSize(img.enemy_fireball))
		quad.light_fireball[i] = lg.newQuad(i*32, 0, 32, 32, getSize(img.light_fireball))
	end

	quad.water_bar = lg.newQuad(0,0, 1,1, getSize(img.water_bar))
	quad.temperature_bar = lg.newQuad(0,0,1,1, getSize(img.temperature_bar))
	quad.temperature_bar_end = lg.newQuad(82,0,2,6, getSize(img.temperature_bar))

	quad.red_screen = lg.newQuad(0,0, 256,169, 256,256)

	quad.hud_people_red = lg.newQuad(0,0, 4,8, 8,8)
	quad.hud_people_green = lg.newQuad(4,0,4,8, 8,8)

	quad.item_slot_regen = lg.newQuad(0,0,3,6, getSize(img.item_slots))
	quad.item_slot_tank  = lg.newQuad(3,0,3,6, getSize(img.item_slots))
	quad.item_slot_suit  = lg.newQuad(6,0,3,6, getSize(img.item_slots))

	quad.sparkles = {}
	for i=0,2 do
		quad.sparkles[i] = lg.newQuad(i*8, 0, 7, 7, getSize(img.sparkles))
	end

	quad.circles = {}
	for i=0,6 do
		quad.circles[i] = lg.newQuad(i*32, 0, 32, 32, getSize(img.circles))
	end

	quad.warning_icons = {}
	for i=0,4 do
		quad.warning_icons[i] = lg.newQuad(i*22, 0, 22, 20, getSize(img.warning_icons))
	end

	quad.captain_dialog = {}
	quad.captain_dialog[0] = lg.newQuad(0,0,200,56, getSize(img.captain_dialog))
	quad.captain_dialog[1] = lg.newQuad(0,64,200,56, getSize(img.captain_dialog))

	quad.prescreen_music = lg.newQuad(224, 0, 26, 11, getSize(img.captain_dialog))

	quad.screen = lg.newQuad(0, 0, 256, 200, getSize(img.splash))

	quad.player_death_up   = lg.newQuad( 0, 0, 16, 24, getSize(img.player_death))
	quad.player_death_down = lg.newQuad(16, 0, 16, 24, getSize(img.player_death))
	quad.player_death_suit = lg.newQuad(32, 0, 16, 10, getSize(img.player_death))

	quad.popup_text = {}
	for i=0,9 do
		quad.popup_text[i] = lg.newQuad(0,i*8, 64,8, getSize(img.popup_text))
	end
	quad.popup_text[10] = lg.newQuad(0,80,64,16, getSize(img.popup_text))

	quad.level_buildings = lg.newQuad(0,0, 134,159, getSize(img.level_buildings))
	quad.building_outline1 = lg.newQuad(144,0, 37,40, getSize(img.level_buildings))
	quad.building_outline2 = lg.newQuad(192,0, 43,75, getSize(img.level_buildings))
	quad.building_outline3 = lg.newQuad(144,80, 64,83, getSize(img.level_buildings))

	quad.box_corner = lg.newQuad(0,0, 6,6, getSize(img.menu_box))
	quad.box_left   = lg.newQuad(0,6, 4,1, getSize(img.menu_box))
	quad.box_top    = lg.newQuad(6,0, 1,4, getSize(img.menu_box))

	quad.boss_health = lg.newQuad(0, 0, 256, 38, getSize(img.boss_health))
	quad.boss_bar = lg.newQuad(0,48, 1,5, getSize(img.boss_health))
	quad.boss_bar_end = lg.newQuad(1,48, 1,5, getSize(img.boss_health))

	quad.boss_portrait = {}
	for i=0,3 do
		quad.boss_portrait[i] = lg.newQuad(i*48, 0, 46, 30, getSize(img.magmahulk_portrait))
	end

	quad.shockwave = {}
	for i=0,9 do
		quad.shockwave[i] = lg.newQuad(0, i*32, 73, 32, getSize(img.shockwave))
	end

	quad.highscore_pane = {}
	for i=1,3 do
		quad.highscore_pane[i] = lg.newQuad(0, (i-1)*12, 256, 12, getSize(img.highscore_panes))
	end

	quad.enemy_healthbar_base = lg.newQuad(0, 0, 20, 8, getSize(img.enemy_healthbar))
	quad.enemy_healthbar_bar  = lg.newQuad(21, 2, 1, 4, getSize(img.enemy_healthbar))

	quad.stats_pane = {}
	for i=1,3 do
		quad.stats_pane[i] = lg.newQuad((i-1)*36, 200, 36, 11, getSize(img.stats_screen))
	end

	quad.award_none = {}
	quad.award_bronze = {}
	quad.award_silver = {}
	quad.award_gold = {}
	for i = 1,6 do
		quad.award_none[i]   = lg.newQuad((i-1)*24,  0, 24, 25, getSize(img.awards))
		quad.award_bronze[i] = lg.newQuad((i-1)*24, 25, 24, 25, getSize(img.awards))
		quad.award_silver[i] = lg.newQuad((i-1)*24, 50, 24, 25, getSize(img.awards))
		quad.award_gold[i]   = lg.newQuad((i-1)*24, 75, 24, 25, getSize(img.awards))
	end

	quad.countdown = {}
	for i=0,3 do
		quad.countdown[i] = lg.newQuad(0, i*26, 64, 26, getSize(img.countdown))
	end

	-- Set audio tag volumes
	love.audio.tags.sfx.setVolume(config.sfx_volume)
end

function playSound(name)
	love.audio.play(snd[name])
end

function playMusic(name, loop)
	-- Stop previously playing music if any
	if music then
		music:stop()
	end
	-- Play new file
	music_name = name
	music = love.audio.newSource("data/sfx/"..name..".ogg", "stream")
	music:addTags("music")
	if loop ~= nil then
		music:setLooping(loop)
	else
		music:setLooping(true)
	end
	love.audio.tags.music.setVolume(config.music_volume)
	love.audio.play(music)
end

function stopMusic()
	if music then
		music:stop()
	end
end

function nextSong()
	if music_name == "rockerronni" then
		playMusic("bundesliga")
	elseif music_name == "bundesliga" then
		playMusic("scooterfest")
	elseif music_name == "scooterfest" then
		playMusic("rockerronni")
	end
end

function prevSong()
	if music_name == "bundesliga" then
		playMusic("rockerronni")
	elseif music_name == "scooterfest" then
		playMusic("bundesliga")
	elseif music_name == "rockerronni" then
		playMusic("scooterfest")
	end
end
