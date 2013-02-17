Boss = { MAX_HEALTH = 10 }

local BS_IDLE, BS_JUMP = 0,1

function Boss.create(x,y)
	local self = setmetatable({}, Boss)

	self.alive = true
	self.health = self.MAX_HEALTH
	self.state = BS_IDLE

	return self
end

function Boss:update(dt)
	
end

function Boss:draw()
	
end

function Boss:collideBox(bbox)
	return false
end

function Boss:getBBox()
	return {x = 0, y = 0, w = 0, h = 0}
end
