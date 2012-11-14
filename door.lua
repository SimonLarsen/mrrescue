Door = {}
Door.__index = Door

local GRAVITY = 550

function Door.create(x,y,dir)
	local self = setmetatable({}, Door)	

	self.alive = true
	self.solid = true
	self.x = x
	self.y = y
	self.state = 0 -- 0 = closed, 1 = off hinges
	self.dir = dir

	self.xspeed = 0
	self.yspeed = 0

	-- Create bbox
	if dir == "left" then
		self.bbox = {x = x+12, y=y, w=4, h=47}
	else
		self.bbox = {x = x, y=y, w=4, h=47}
	end

	return self
end

function Door:update(dt)
	if self.state == 1 then
		self.yspeed = self.yspeed + GRAVITY*dt

		self.x = self.x + self.xspeed*dt
		self.y = self.y + self.yspeed*dt

		self.solid = false

		if self.y > MAPH then
			self.alive = false
		end
	end
end

function Door:shot(dir)
	self.state = 1
	self.xspeed = 50*dir
	self.yspeed = -100
end

function Door:draw()
	if self.dir == "left" then
		love.graphics.drawq(img.door, quad.door_closed, self.x+10, self.y)
	else
		love.graphics.drawq(img.door, quad.door_closed, self.x-2,  self.y)
	end
end

function Door:getBBox()
	return self.bbox
end

function Door:collide(box)
	if self.state == 0 then
		return collideBoxes(self.bbox,box)
	else
		return false
	end
end
