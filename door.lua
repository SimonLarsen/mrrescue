Door = {}
Door.__index = Door

function Door.create(x,y,dir)
	local self = setmetatable({}, Door)	

	self.alive = true
	self.solid = true
	self.x = x
	self.y = y
	self.state = 0 -- 0 = closed, 1 = off hinges
	self.dir = dir

	-- Create bbox
	if dir == "left" then
		self.bbox = {x = x+12, y=y, w=4, h=47}
	else
		self.bbox = {x = x, y=y, w=4, h=47}
	end

	return self
end

function Door:update(dt)
	
end

function Door:draw()
	if self.state == 0 then
		if self.dir == "left" then
			love.graphics.drawq(img.door, quad.door_closed, self.x+10, self.y)
		else
			love.graphics.drawq(img.door, quad.door_closed, self.x-2,  self.y)
		end
	end
end

function Door:getBBox()
	return self.bbox
end
