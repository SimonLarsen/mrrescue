GasGhost = { MAX_HEALTH = 0.25, SPEED = 80, SCORE = 50 }
GasGhost.__index = GasGhost

function GasGhost.create(x,y,dir)
	local self = setmetatable({}, GasGhost)
	self.x, self.y = x,y
	self.starty = y
	self.alive = true
	self.hit = false
	self.dir = dir
	self.time = 0
	self.health = self.MAX_HEALTH
	self.anim = newAnimation(img.gasghost, 24, 32, 0.15, 3)
	return self
end

function GasGhost:update(dt)
	self.anim:update(dt)
	self.time = self.time + dt*2.5

	self.x = self.x + self.dir*self.SPEED*dt
	if self.x < -32 or self.x > MAPW+32 then
		self.alive = false
	end

	self.y = self.starty + (-math.cos(self.time)+1)*20
end

function GasGhost:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 16, 25, nil, self.hit and img.gasghost_hit)
	self.hit = false
end

function GasGhost:shot(dt,dir)
	self.hit = true
	self.health = self.health - dt
	if self.health <= 0 then
		self.alive = false
		score = score + self.SCORE
		map:addParticle(BlackSmoke.create(self.x, self.y))
	end
end

function GasGhost:collideBox(bbox)
	if self.x-7 > bbox.x+bbox.w or self.x+7 < bbox.x
	or self.y-6 > bbox.y+bbox.h or self.y+6 < bbox.y then
		return false
	else
		return true
	end
end

function GasGhost:getBBox()
	return {x = self.x-8, y = self.y-7, w = 14, h = 12}
end
