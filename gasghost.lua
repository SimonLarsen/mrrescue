GasGhost = { MAX_HEALTH = 0.25, SPEED = 100, SCORE = 50 }
GasGhost.__index = GasGhost

function GasGhost.create(x,y,dir,time)
	local self = setmetatable({}, GasGhost)
	self.x, self.y = x,y
	self.starty = y
	self.alive = true
	self.hit = false
	self.dir = dir
	self.time = time or 0
	self.health = self.MAX_HEALTH
	self.anim = newAnimation(img.gasghost, 24, 32, 0.15, 3)
	return self
end

function GasGhost:update(dt)
	self.anim:update(dt)
	self.time = self.time + dt*2.8

	self.hit = false

	self.x = self.x + self.dir*self.SPEED*dt
	if self.x < -32 or self.x > MAPW+32 then
		self.alive = false
	end

	if player:collideBox(self:getBBox()) == true then
		local cx, cy = math.floor(self.x/16), math.floor(self.y/16)
		map:addFire(cx,   cy)
		map:addFire(cx-1, cy)
		map:addFire(cx+1, cy)
		map:addFire(cx, cy-1)
		map:addFire(cx, cy+1)

		map:addParticle(BlackSmoke.create(self.x, self.y-8))
		map:addParticle(BlackSmoke.create(self.x-6, self.y-18))
		map:addParticle(BlackSmoke.create(self.x+6, self.y-18))
		self.alive = false
		playSound("endexplosion")
	end

	self.y = self.starty + (-math.cos(self.time)+1)*20
end

function GasGhost:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 16, 25, nil, self.hit and img.gasghost_hit)
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
	if self.x-6 > bbox.x+bbox.w or self.x+6 < bbox.x
	or self.y-5 > bbox.y+bbox.h or self.y+5 < bbox.y then
		return false
	else
		return true
	end
end

function GasGhost:getBBox()
	return {x = self.x-6, y = self.y-5, w = 12, h = 10}
end
