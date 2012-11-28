Fire = {}
Fire.__index = Fire

function Fire.create(x,y,map)
	local self = setmetatable({}, Fire)

	self.alive = true
	self.x, self.y = x,y
	self.frame = math.random()*5
	self.flframe = 0

	if map:collidePoint(self.x,self.y+16) then
		self.ground = true
	else
		self.ground = false
	end

	return self
end

function Fire:update(dt)
	self.frame = self.frame + 12*dt
end

function Fire:drawFront()
	if self.ground == true then
		love.graphics.drawq(img.fire_floor, quad.fire_floor[self.flframe%4], self.x, self.y+1)
	end
end

function Fire:drawBack()
	self.flframe = math.floor(self.frame)
	love.graphics.drawq(img.fire_wall, quad.fire_wall[self.flframe%5], self.x, self.y, 0,1,1,4,16)
end
