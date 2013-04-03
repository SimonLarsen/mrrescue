CoalBall = { MAX_HEALTH = 0.25, SPEED = 100, SCORE = 50 }
CoalBall.__index = CoalBall

function CoalBall.create(x,y)
	local self = setmetatable({}, CoalBall)
	self.x, self.y = x,y
	self.alive = true
	self.health = self.MAX_HEALTH
	self.anim = newAnimation(img.charcoal_projectile, 15, 15, 0.15, 12)
	return self
end

function CoalBall:update(dt)
	self.anim:update(dt)
	self.y = self.y + self.SPEED*dt

	if self.y >= MAPH-22 then
		self.alive = false
	end
end

function CoalBall:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, 1, 1, 7, 7)
end

function CoalBall:shot(dt,dir)
	self.health = self.health - dt
	if self.health <= 0 then
		self.alive = false
		score = score + self.SCORE
		map:addParticle(BlackSmoke.create(self.x, self.y))
	end
end

function CoalBall:collideBox(bbox)
	if self.x-7 > bbox.x+bbox.w or self.x+7 < bbox.x
	or self.y-7 > bbox.y+bbox.h or self.y+7 < bbox.y then
		return false
	else
		return true
	end
end

function CoalBall:getBBox()
	return {x = self.x-7, y = self.y-7, w = 14, h = 14}
end
