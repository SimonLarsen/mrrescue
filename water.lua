Water = {}
Water.__index = Water

local SPEED = 300

--- Creates a water projectile
-- @param x X-coordinate
-- @param y Y-coordinate
-- @param dir Direction in radians
function Water.create(x,y,dir,radius)
	local self = setmetatable({}, Water)

	self.alive = true
	self.x = x
	self.y = y

	self.xspeed = math.cos(dir)*SPEED
	self.yspeed = -math.sin(dir)*SPEED

	return self
end

function Water:update(dt)
	self.x = self.x + self.xspeed*dt
	self.y = self.y + self.yspeed*dt

	if self.x < -16 or self.x > MAPW+16
	or self.y < -16 or self.y > MAPH+16 then
		self.alive = false
	end
end

function Water:draw()
	love.graphics.draw(img.water, math.floor(self.x-8), math.floor(self.y-8))
end
