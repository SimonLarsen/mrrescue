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
		love.graphics.drawq(img.shards, quad.shard[i], v.x, v.y, v.rot, 1,1, 4,4)
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

Ashes = {}
Ashes.__index = Ashes

function Ashes.create(x,y)
	local self = setmetatable({}, Ashes)

	self.alive = true
	self.x = math.floor(x)
	self.y = math.floor(y)
	self.anim = newAnimation(img.ashes, 20, 20, 0.16, 8, function() self.alive = false end)
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
