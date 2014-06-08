Shards = {}
Shards.__index = Shards

local GRAVITY = 350

function Shards.create(x,y,dir)
	local self = setmetatable({}, Shards)

	self.alive = true

	self.shards = {}
	for i = 0,7 do
		self.shards[i] = {}
		self.shards[i].x = x
		self.shards[i].y = y+i*3+4
		self.shards[i].xspeed = dir*math.random(100,200)
		self.shards[i].yspeed = math.random(-50,50)
		self.shards[i].rot = 0
	end

	return self
end

function Shards:update(dt)
	local allOut = true

	for i,v in ipairs(self.shards) do
		v.x = v.x + v.xspeed*dt
		v.yspeed = v.yspeed + GRAVITY*dt
		v.y = v.y + v.yspeed*dt
		v.rot = v.rot + v.xspeed*dt*0.2

		if v.y < MAPH+4 then
			allOut = false
		end
	end

	self.alive = not allOut
end

function Shards:draw()
	for i,v in ipairs(self.shards) do
		love.graphics.draw(img.shards, quad.shard[i], v.x, v.y, v.rot, 1,1, 4,4)
	end
end

BlackSmoke = {}
BlackSmoke.__index = BlackSmoke

function BlackSmoke.create(x,y)
	local self = setmetatable({}, BlackSmoke)
	self.x = math.floor(x)
	self.y = math.floor(y)
	self.alive = true
	self.anim = newAnimation(img.black_smoke, 20, 20, 0.10, 6, function() self.alive = false end)
	return self
end

function BlackSmoke:update(dt)
	self.anim:update(dt)
end

function BlackSmoke:draw()
	if self.alive == true then
		self.anim:draw(self.x, self.y, 0, 1,1, 10, 10)
	end
end

SmallBlackSmoke = {}
SmallBlackSmoke.__index = SmallBlackSmoke

function SmallBlackSmoke.create(x,y)
	local self = setmetatable({}, SmallBlackSmoke)
	self.x = math.floor(x)
	self.y = math.floor(y)
	self.alive = true
	self.anim = newAnimation(img.black_smoke_small, 8, 8, 0.12, 4, function() self.alive = false end)
	return self
end

function SmallBlackSmoke:update(dt)
	self.anim:update(dt)
end

function SmallBlackSmoke:draw()
	if self.alive == true then
		self.anim:draw(self.x, self.y, 0, 1,1, 4, 4)
	end
end

Ashes = { isAshes = true }
Ashes.__index = Ashes

function Ashes.create(x,y)
	local self = setmetatable({}, Ashes)

	self.alive = true
	self.x = math.floor(x)
	self.y = math.floor(y)
	self.anim = newAnimation(img.ashes, 20, 20, 0.17, 8, function() self.alive = false end)
	return self
end

function Ashes:update(dt)
	self.anim:update(dt)
end

function Ashes:draw()
	if self.alive == true then
		self.anim:draw(self.x, self.y, 0, 1,1, 10, 20)
	end
end

Sparkles = {}
Sparkles.__index = Sparkles

function Sparkles.create(x,y,count,time)
	local self = setmetatable({}, Sparkles)
	self.alive = true
	self.particles = {}
	self.time = time or 2
	if count == nil then count = 8 end

	for i=1,count do
		table.insert(self.particles, {x=x, y=y, xspeed=math.random(-100,100), yspeed=math.random(-200,-50), size=i%3})
	end

	return self
end

function Sparkles:update(dt)
	self.time = self.time - dt
	if self.time < 0 then
		self.alive = false
		return
	end

	for i,v in ipairs(self.particles) do
		v.yspeed = v.yspeed + 500*dt
		v.x = v.x + v.xspeed*dt
		v.y = v.y + v.yspeed*dt
	end
end

function Sparkles:draw()
	for i,v in ipairs(self.particles) do
		love.graphics.draw(img.sparkles, quad.sparkles[v.size], v.x, v.y, 0,1,1, 3.5, 3.5)
	end
end

SaveBeam = {}
SaveBeam.__index = SaveBeam

function SaveBeam.create(x,y,dir)
	local self = setmetatable({}, SaveBeam)
	self.alive = true
	self.time = 0
	self.x, self.y = x, math.floor(y)
	self.dir = dir

	return self
end

function SaveBeam:update(dt)
	self.time = self.time + dt*18
	if self.time >= 8 then
		self.time = 7
		self.alive = false
	end
end

function SaveBeam:draw()
	local frame = math.floor(self.time)
	lg.draw(img.savebeam, quad.savebeam[frame], self.x, self.y, 0, self.dir, 1, 1, 16)
end

PopupText = {}
PopupText.__index = PopupText

function PopupText.create(text)
	local self = setmetatable({}, PopupText)
	self.alive = true
	self.time = 0
	self.x = player.flx
	self.y = player.fly-24

	if text == "rescue" then
		self.id = 0
	elseif text == "coolant" then
		self.id = 1
	elseif text == "suit" then
		self.id = 2
	elseif text == "tank" then
		self.id = 3
	elseif text == "reserve" then
		self.id = 4
	elseif text == "regen" then
		self.id = 5
	elseif text == "theft" then
		self.id = 6
	elseif text == "3combo" then
		self.id = 7
	elseif text == "4combo" then
		self.id = 8
	elseif text == "5combo" then
		self.id = 9
	elseif text == "megacombo" then
		self.id = 10
	end

	return self
end

function PopupText:update(dt)
	self.time = self.time + dt
	if self.time > 0.7 then
		self.alive = false
	end
end

function PopupText:draw()
	lg.draw(img.popup_text, quad.popup_text[self.id], self.x, self.y-math.sqrt(self.time)*32, 0, 1, 1, 32, 0)
end

CoalBallBreak = {}
CoalBallBreak.__index = CoalBallBreak

function CoalBallBreak.create(x,y)
	local self = setmetatable({}, CoalBallBreak)
	self.alive = true
	self.x, self.y = math.floor(x), math.floor(y)
	return self
end

function CoalBallBreak:update(dt)
	
end

function CoalBallBreak:draw()
	
end
