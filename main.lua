require("resources")
require("util")
require("AnAL")
require("map")
require("player")
require("entity")
require("human")
require("enemy")
require("door")
require("fire")
require("particles")

WIDTH = 256
HEIGHT = 200
MAPW = 41*16
MAPH = 16*16
translate_x, translate_y = 0,0
show_debug = false

local SCALE = 3
local FRAMERATE_CAP = 1/15

local lg = love.graphics

function love.load()
	lg.setBackgroundColor(82,117,176)
	lg.setMode(WIDTH*SCALE, HEIGHT*SCALE, false, true)
	lg.setDefaultImageFilter("nearest","nearest")

	lg.setFont(lg.newFont(16))

	loadResources()

	map = Map.create()
	player = Player.create(map:getStart())
end

function nextLevel()
	map = Map.create()
	player.x, player.y = map.startx, map.starty
end

function love.update(dt)
	-- Cap framerate
	if dt > FRAMERATE_CAP then dt = FRAMERATE_CAP end

	if love.keyboard.isDown("l") then
		dt = dt/4
	end

	-- Update entities
	player:update(dt)

	-- Calculate translation offest
	translate_x = math.min(math.max(0, player.x-WIDTH/2), MAPW-WIDTH)
	translate_y = math.min(math.max(0, player.y-11-HEIGHT/2), MAPH-HEIGHT+30)

	map:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
	map:update(dt)

	if player.y < 0 then
		nextLevel()
	end
end

function love.draw()
	-- Scale screen
	lg.push()
	lg.scale(SCALE,SCALE)
	-- Translate to center player
	lg.push()
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))

	-- Draw back
	map:drawBack()
	-- Draw player
	player:draw()
	-- Draw front
	map:drawFront()

	-- Update lightmap
	lg.pop()
	lg.pop()	
	lg.push()
	lg.translate(-math.floor(translate_x), -math.floor(translate_y))
	updateLightmap()
	lg.pop()

	-- Draw canvas with lighting
	lg.push()
	lg.scale(SCALE,SCALE)
	lg.setBlendMode("multiplicative")
	lg.draw(canvas, 0,0)
	lg.setBlendMode("alpha")

	-- Draw red screen if hit
	if player.hit == true then
		lg.setColor(255,255,255,128)
		lg.drawq(img.red_screen, quad.red_screen, 0,0)
		lg.setColor(255,255,255,255)
	end

	-- Draw hud
	drawHUD()

	-- Draw debug information
	lg.pop()
	if show_debug == true then
		drawDebug()
	end
end

function drawHUD()
	lg.draw(img.hud, 0, HEIGHT-32)

	local water_ratio = player.water / player.water_capacity
	quad.water_bar:setViewport(0, 0, math.floor(water_ratio*55+0.5), 11)
	if player.overloaded == false then
		lg.drawq(img.water_bar, quad.water_bar, 10, HEIGHT-22)
	else
		lg.drawq(img.overloaded_bar, quad.water_bar, 10, HEIGHT-22)
	end

	local temp_length = math.floor(player.temperature*81+0.5)
	quad.temperature_bar:setViewport(0,0, temp_length, 6)
	lg.drawq(img.temperature_bar, quad.temperature_bar, 90, HEIGHT-20)
	lg.drawq(img.temperature_bar, quad.temperature_bar_end, 90+temp_length, HEIGHT-20)

	lg.draw(img.hud2, 0, HEIGHT-32)
end

function updateLightmap()
	canvas:clear(0,0,0,255)
	lg.setCanvas(canvas)
	lg.setBlendMode("additive")

	lg.draw(img.light_player, player.flx-128, player.fly-138)
	map:drawFireLight()
	for i,v in ipairs(map.enemies) do
		v:drawLight()
	end
	
	-- Light up outside building
	lg.rectangle("fill", 0,0, 32, MAPH)
	lg.rectangle("fill", MAPW-32, 0, 32, MAPH)
	lg.setBlendMode("alpha")
	lg.setCanvas()
end

function drawDebug()
	for i,v in ipairs({{0,0,0,255},{255,255,255,255}}) do
		lg.setColor(v)
		lg.print("x: "..player.flx.."   y: "..player.fly,10+i,10+i)
		lg.print("xspeed: "..math.floor(player.xspeed).."   yspeed: "..math.floor(player.yspeed),10+i,30+i)
		lg.print("streamLength: "..math.floor(player.streamLength).."   streamCollided: ".. (player.streamCollided and "true" or "false"),10+i,50+i)
		lg.print("enemies: "..#map.enemies.."  humans: "..#map.humans,10+i,70+i)
		lg.print("objects: "..#map.objects.."  particles: "..#map.particles,10+i,90+i)
	end
end

function love.keypressed(k, uni)
	if k == "escape" then
		love.event.quit()
	elseif k == "f1" then
		show_debug = not show_debug
	elseif k == "i" then
		map:addFire(math.floor(player.x/16), math.floor((player.y-8)/16))
	else
		player:keypressed(k)
	end
end
