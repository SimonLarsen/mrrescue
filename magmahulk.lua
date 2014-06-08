MagmaHulk = { MAX_HEALTH = 12, GRAVITY = 350, JUMP_POWER = 200, MAX_JUMP = 128,
		 TRANSITION_TIME = 2, SCORE = 5000 }
MagmaHulk.__index = MagmaHulk
setmetatable(MagmaHulk, Boss)

function MagmaHulk.create(x,y)
	local self = setmetatable({}, MagmaHulk)

	self.alive = true
	self.hit = false
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.time = self.IDLE_TIME
	self.dir = 1
	self.health = self.MAX_HEALTH
	self.angry = false
	self.hitGround = false
	self.shockwaveActive = false
	self.shockwaveFrame = 0
	self.shockwaveX = 0

	self.anims = {}
	self.anims[BS_JUMP] = newAnimation(img.magmahulk_jump, 58, 64, 0.14, 5,
		function() 
			self:setState(BS_FLY)
			self.yspeed = -self.JUMP_POWER
			self.xspeed = 0.93*cap(cap(player.x,194,464) - self.x, -self.MAX_JUMP, self.MAX_JUMP)
			self.hitGround = false
			playSound("bossjump")
		end
	)
	self.anims[BS_LAND] = newAnimation(img.magmahulk_land, 58, 64, 0.14, 7,
		function()
			if self.state ~= BS_TRANSITION then
				self:setState(BS_JUMP)
			end
		end
	)

	self:setState(BS_IDLE)

	return self
end

function MagmaHulk:update(dt)
	if self.anim then
		self.anim:update(dt)
	end

	map.boss.hit = false

	if self.state == BS_IDLE then
		self.time = self.time - dt
		if self.time <= 0 then
			self:setState(BS_JUMP)
		end
	elseif self.state == BS_FLY then
		self.yspeed = self.yspeed + self.GRAVITY*dt
		self.x = self.x + self.xspeed*dt
		self.y = self.y + self.yspeed*dt

		if self.yspeed > 0 and self.y > MAPH-48 then
			self:setState(BS_LAND)
		end
	elseif self.state == BS_LAND then
		self.yspeed = self.yspeed + self.GRAVITY*dt
		self.y = self.y + self.yspeed*dt

		if self.y > MAPH-16 then
			self.y = MAPH-16
			self.yspeed = 0
			if self.hitGround == false then
				-- Add fire
				map:addFire(math.floor((self.x-8)/16), math.floor((self.y-5)/16))
				map:addFire(math.floor((self.x+8)/16), math.floor((self.y-5)/16))
				self.hitGround = true
				-- Set shake
				ingame.shake = 0.4
				-- Play sound
				playSound("crash")
				-- Add shockwave
				if self.angry == true then
					self.shockwaveX = math.floor(self.x)
					self.shockwaveFrame = 0
					self.shockwaveActive = true
				end
			end
		else
			self.x = self.x + self.xspeed*dt
		end
	elseif self.state == BS_JUMP then
		if self.health <= 0 then
			self.time = self.DEAD_TIME
			self.yspeed = self.DEAD_SMOKE_INTERVAL
			ingame.shake = self.DEAD_TIME
			self:setState(BS_DEAD)
			map:clearFire()
			map:clearEnemies()
			score = score + self.SCORE
			stopMusic()
		elseif self.angry == false and self.health < self.MAX_HEALTH*0.75 then
			self:setState(BS_TRANSITION)
			self.time = self.TRANSITION_TIME
			playSound("transform")
		end
	elseif self.state == BS_TRANSITION then
		self.time = self.time - dt
		if self.time <= 0 then
			self.angry = true
			self:setState(BS_LAND)
			self.hitGround = true
		end
	elseif self.state == BS_DEAD then
		self.time = self.time - dt
		self.yspeed = self.yspeed + dt
		if self.yspeed > self.DEAD_SMOKE_INTERVAL then
			self.yspeed = 0
			if ingame_state ~= INGAME_WON then
				map:addParticle(BlackSmoke.create(self.x+math.random(-16,16),self.y-math.random(0,40)))
				playSound("endexplosion")
			end
		end
		if self.time <= 0 and ingame_state ~= INGAME_WON then
			ingame_state = INGAME_WON
			playMusic("victory", false)
		end
	end

	self.x = cap(self.x, 194, 464)

	-- Update shockwave if active
	if self.shockwaveActive == true then
		self.shockwaveFrame = self.shockwaveFrame + dt*24
		if self.shockwaveFrame >= 10 then
			self.shockwaveFrame = 0
			self.shockwaveActive = false
		end
	end

	self.health = cap(self.health, 0, self.MAX_HEALTH)
end

function MagmaHulk:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)
	
	-- Draw shockwave
	if self.shockwaveActive == true then
		local frame = math.floor(self.shockwaveFrame)
		lg.draw(img.shockwave, quad.shockwave[frame], self.shockwaveX, 240, 0, 1,1, 82, 32)
		lg.draw(img.shockwave, quad.shockwave[frame], self.shockwaveX, 240, 0,-1,1, 82, 32)
	end

	-- Draw boss
	if self.state == BS_TRANSITION or self.state == BS_DEAD then
		self.anims[BS_LAND]:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, 1,
		(self.time*16) % 2 < 1 and img.magmahulk_rage_land)
	elseif self.hit == false then
		if self.state == BS_IDLE then
			self.anims[BS_JUMP]:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, 1,
			self.angry == true and img.magmahulk_rage_jump)
		elseif self.state == BS_FLY then
			self.anims[BS_LAND]:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, 1,
			self.angry == true and img.magmahulk_rage_land)
		elseif self.state == BS_JUMP then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, nil,
			self.angry == true and img.magmahulk_rage_jump)
		elseif self.state == BS_LAND then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, nil,
			self.angry == true and img.magmahulk_rage_land)
		end
	else
		if self.state == BS_IDLE then
			self.anims[BS_JUMP]:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, 1, img.magmahulk_jump_hit)
		elseif self.state == BS_FLY then
			self.anims[BS_LAND]:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, 1, img.magmahulk_land_hit)
		elseif self.state == BS_JUMP then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, nil, img.magmahulk_jump_hit)
		elseif self.state == BS_LAND then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 27, 64, nil, img.magmahulk_land_hit)
		end
	end
end

function MagmaHulk:collideBox(bbox)
	if self.x-11 > bbox.x+bbox.w or self.x+11 < bbox.x
	or self.y-33 > bbox.y+bbox.h or self.y-7 < bbox.y then
		return false
	else
		return true
	end
end

function MagmaHulk:getBBox()
	return {x = self.x-11, y = self.y-33, w = 22, h = 26}
end

function MagmaHulk:getShockwaveBBox()
	local swwidth = self.shockwaveFrame*6.08
	return {x = self.x-swwidth, y = 235, w = 2*swwidth, h = 5}
end

function MagmaHulk:setState(state)
	self.state = state
	self.anim = self.anims[state]
	if self.anim then
		self.anim:reset()
	end
end

function MagmaHulk:shot(dt,dir)
	if self.state ~= BS_TRANSITION and self.state ~= BS_DEAD then
		self.health = self.health - dt
		self.hit = true
	end
end

function MagmaHulk:getPortraitImage()
	return img.magmahulk_portrait
end
