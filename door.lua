Door = {solid = true}
Door.__index = Door
--setmetatable(Door,Entity)

local GRAVITY = 550
local SCORE = 50

function Door.create(x,y,dir)
	local self = setmetatable({}, Door)	

	self.alive = true
	self.health = 0.3

	self.x = x
	if dir == "left" then
		self.x = self.x+12
	end
	self.y = y
	self.cx = math.floor(x/16)
	self.cy = math.floor(y/16)

	self.state = 0 -- 0 = closed, 1 = off hinges
	self.dir = dir

	self.xspeed = 0
	self.yspeed = 0
	self.bbox = {x=self.x, y=self.y, w=4, h=47}

	return self
end

function Door:update(dt)
	if self.state == 0 then
		if map:hasFire(self.cx, self.cy) or map:hasFire(self.cx, self.cy+1)
		or map:hasFire(self.cx, self.cy+2) then
			self.health = self.health - dt*0.2
		end

		if self.health < 0 then
			self.state = 1
			self.xspeed = math.random(-50,50)
			self.yspeed = -100
			playSound("door")
		end

	elseif self.state == 1 then
		self.yspeed = self.yspeed + GRAVITY*dt

		self.x = self.x + self.xspeed*dt
		self.y = self.y + self.yspeed*dt

		self.solid = false

		if self.y > MAPH then
			self.alive = false
		end
	end
end

function Door:shot(dt,dir)
	self.health = self.health - dt

	if self.health < 0 then
		self.state = 1
		self.xspeed = 50*dir
		self.yspeed = -100
		score = score + SCORE
		playSound("door")
		stats[5] = stats[5] + math.random(80,120)
	end
end

function Door:draw()
	if self.health > 0.20 then
		love.graphics.draw(img.door, quad.door_normal, self.x-2,  self.y+24, self.state*(100+self.yspeed)*self.xspeed*0.0005, 1,1, 0, 24)
	else
		love.graphics.draw(img.door, quad.door_damaged, self.x-2,  self.y+24, self.state*(100+self.yspeed)*self.xspeed*0.0005, 1,1, 0, 24)
	end
end

function Door:getBBox()
	return self.bbox
end

function Door:collideBox(box)
	if self.state == 0 then
		return collideBoxes(self.bbox,box)
	else
		return false
	end
end
