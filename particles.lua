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
