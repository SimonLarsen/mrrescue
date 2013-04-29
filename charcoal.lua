Charcoal = { MAX_HEALTH = 10, GRAVITY = 350, ROLL_SPEED = 100, DAZED_TIME = 3,
			 TRANSITION_TIME = 2, SHOT_TIME = 1, SCORE = 5000 }
Charcoal.__index = Charcoal
setmetatable(Charcoal, Boss)

Charcoal.bbox_dazed = {x = -12, y = -26, w = 24, h = 25}

function Charcoal.create(x,y)
	local self = setmetatable({}, Charcoal)

	self.alive = true
	self.hit = false
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.time = self.IDLE_TIME
	self.dir = -1
	self.health = self.MAX_HEALTH
	self.shockwaveAction = false
	self.angry = false

	self.anims = {}
	self.anims[BS_IDLE] = newAnimation(img.charcoal_idle, 64, 64, 1, 1)
	self.anims[BS_TRANSFORM] = newAnimation(img.charcoal_transform, 40, 64, 0.14, 19,
	function()
		self:setState(BS_ROLL)
		self.nextShot = 0
	end)
	self.anims[BS_TRANSITION] = newAnimation(img.charcoal_transition, 40, 64, 0.14, 2)
	self.anims[BS_DEAD] = self.anims[BS_TRANSITION]
	self.anims[BS_ROLL] = newAnimation(img.charcoal_roll, 32, 32, 0.034, 19)
	self.anims[BS_DAZED] = newAnimation(img.charcoal_daze, 40, 64, 0.14, 4)

	self:setState(BS_IDLE)

	return self
end

function Charcoal:update(dt)
	if self.anim then
		self.anim:update(dt)
	end

	map.boss.hit = false

	if self.state == BS_IDLE then
		self.time = self.time - dt
		if self.time <= 0 then
			self:setState(BS_TRANSFORM)
			self.time = self.TRANSITION_TIME
			playSound("transform")
		end

	elseif self.state == BS_TRANSITION then
		self.time = self.time - dt
		if self.time <= 0 then
			self.angry = true
			self:setState(BS_TRANSFORM)
			playSound("transform")
		end

	elseif self.state == BS_ROLL then
		self.x = self.x + self.dir * self.ROLL_SPEED * dt

		if self.angry == true then
			ingame.shake = 0.1
			self.nextShot = self.nextShot - dt
			if self.nextShot <= 0 then
				table.insert(map.enemies, CoalBall.create(player.x, 0))
				self.nextShot = self.SHOT_TIME
			end
		end

		if self.x < 190 or self.x > 466 then
			self.y = MAPH-16
			self.yspeed = -100
			self.dir = -self.dir
			self.xspeed = self.dir*40
			ingame.shake = 0.4
			playSound("crash")
			self:setState(BS_DAZED)
			self.time = self.DAZED_TIME
			local ballcount = self.angry == true and 10 or 6
			for i=1,ballcount do
				local ball = CoalBall.create(168+(320/(ballcount-1))*(i-1), math.random(-100,0))
				table.insert(map.enemies, ball)
			end
		end

	elseif self.state == BS_DAZED then
		self.time = self.time - dt
		self.yspeed = self.yspeed + self.GRAVITY*dt
		self.x = self.x + self.xspeed*dt
		self.y = self.y + self.yspeed*dt
		if self.y > MAPH-16 then
			self.xspeed = 0
			self.yspeed = 0
			self.y = MAPH-16
		end
		if self.health <= 0 then
			self.time = self.DEAD_TIME
			self.yspeed = self.DEAD_SMOKE_INTERVAL
			ingame.shake = self.DEAD_TIME
			self:setState(BS_DEAD)
			map:clearFire()
			map:clearEnemies()
			score = score + self.SCORE
			stopMusic()
		elseif self.time <= 0 then
			self.y = MAPH-16
			self:setState(BS_TRANSFORM)
		elseif self.angry == false and self.health < self.MAX_HEALTH*0.75 then
			self:setState(BS_TRANSITION)
			self.time = self.TRANSITION_TIME
			playSound("transform")
		end

	elseif self.state == BS_DEAD then
		self.time = self.time - dt
		self.yspeed = self.yspeed + dt
		if self.yspeed > self.DEAD_SMOKE_INTERVAL then
			self.yspeed = 0
			if ingame_state ~= INGAME_WON then
				map:addParticle(BlackSmoke.create(self.x+math.random(-16,16),self.y-math.random(0,32)))
				playSound("endexplosion")
			end
		end
		if self.time <= 0 and ingame_state ~= INGAME_WON then
			ingame_state = INGAME_WON
			playMusic("victory", false)
		end
	end

	self.x = cap(self.x, 190, 466)
	self.health = cap(self.health, 0, self.MAX_HEALTH)
end

function Charcoal:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == BS_IDLE then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 32, 64)
	elseif self.state == BS_DAZED then
		if self.hit == true then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 64, nil, img.charcoal_daze_hit)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 64, nil,
			self.angry == true and img.charcoal_daze_rage)
		end
	elseif self.state == BS_TRANSFORM then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 64, nil,
		self.angry == true and img.charcoal_transform_rage)
	elseif self.state == BS_ROLL then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 16, 32, nil,
		self.angry == true and img.charcoal_roll_rage)
	elseif self.state == BS_TRANSITION or self.state == BS_DEAD then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 64)
	end
end

function Charcoal:collideBox(bbox)
	if self.state == BS_ROLL then
		if self.x-12 > bbox.x+bbox.w or self.x+12 < bbox.x
		or self.y-22 > bbox.y+bbox.h or self.y < bbox.y then
			return false
		else
			return true
		end
	else
		if self.x-12 > bbox.x+bbox.w or self.x+12 < bbox.x
		or self.y-34 > bbox.y+bbox.h or self.y < bbox.y then
			return false
		else
			return true
		end
	end
	return false
end

function Charcoal:getBBox()
	return {x = self.x-12, y = self.y-22, w = 24, h = 22}
end

function Charcoal:setState(state)
	self.state = state
	self.anim = self.anims[state]
	if self.anim then
		self.anim:reset()
	end
end

function Charcoal:shot(dt,dir)
	if self.state == BS_DAZED then
		self.hit = true
		self.health = self.health - dt
	end
end

function Charcoal:getPortraitImage()
	return img.charcoal_portrait
end
