Door = {}
Door.__index = Door

local GRAVITY = 550

function Door.create(x,y,dir)
	local self = setmetatable({}, Door)	

	self.alive = true
	self.solid = true

	self.x = x
	if dir == "left" then
		self.x = self.x+12
	end
	self.y = y

	self.state = 0 -- 0 = closed, 1 = off hinges
	self.dir = dir

	self.xspeed = 0
	self.yspeed = 0
	self.bbox = {x=self.x, y=self.y, w=4, h=47}

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
	love.graphics.drawq(img.door, quad.door_closed, self.x-2,  self.y+24, self.state*(100+self.yspeed)*self.xspeed*0.0005, 1,1, 0, 24)
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
