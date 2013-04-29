GasLeak = { MAX_HEALTH = 12, WALK_SPEED = 40, PUSHED_COOLDOWN = 0.2,
		    PUSHED_SPEED = 40, DEAD_TIME = 5, DEAD_SMOKE_INTERVAL = 0.5,
			GHOST_DELAY = 2.5, GHOST_DELAY_ANGRY = 1.5, HAS_SHOT_TIME = 0.4, SCORE = 5000 }
GasLeak.__index = GasLeak
setmetatable(GasLeak, Boss)

function GasLeak.create(x,y)
	local self = setmetatable({}, GasLeak)
	self.alive = true
	self.hit = false
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0, 0
	self.time = self.IDLE_TIME
	self.dir = -1
	self.health = self.MAX_HEALTH
	self.shockwaveActive = false
	self.angry = false
	self.nextGhost = self.GHOST_DELAY
	self.hasShot = 0

	self.anims = {}
	self.anims[BS_IDLE] = newAnimation(img.gasleak_idle, 40, 128, 1, 1)
	self.anims[BS_WALK] = newAnimation(img.gasleak_walk, 40, 128, 0.14, 8)
	self.anims[BS_PUSHED] = newAnimation(img.gasleak_hit, 40, 64, 0.1, 2)
	self.anims[BS_TRANSITION] = newAnimation(img.gasleak_transition, 40, 128, 0.17, 10,
		function()
			self.angry = true
			self:setState(BS_WALK)
		end
	)
	self.anims[BS_DEAD] = newAnimation(img.gasleak_transition, 40, 128, 0.17, 2)

	self:setState(BS_IDLE)

	return self
end

function GasLeak:update(dt)
	if self.anim then
		self.anim:update(dt)
	end

	if self.hasShot > 0 then self.hasShot = self.hasShot - dt end

	map.boss.hit = false

	if self.state == BS_IDLE then
		self.time = self.time - dt
		if self.time <= 0 then
			self:setState(BS_WALK)
		end
	elseif self.state == BS_WALK then
		self.x = self.x + self.dir*self.WALK_SPEED*dt
		self.nextGhost = self.nextGhost - dt
		if self.nextGhost < 0 then
			if self.angry == false then
				self.nextGhost = self.GHOST_DELAY
				table.insert(map.enemies, GasGhost.create(self.x+self.dir*14, self.y-46, self.dir))
			else
				local rand = math.random(1,5)
				if rand >= 4 then
					table.insert(map.enemies, GasGhost.create(self.x+self.dir*14, self.y-46, self.dir))
				elseif rand >= 2 then
					table.insert(map.enemies, GasGhost.create(self.x+self.dir*14, self.y-46, self.dir, 1.67))
				else
					table.insert(map.enemies, GasGhost.create(self.x+self.dir*14, self.y-46, self.dir))
					table.insert(map.enemies, GasGhost.create(self.x+self.dir*14, self.y-46, self.dir, 1.67))
				end
				self.nextGhost = self.GHOST_DELAY_ANGRY
			end
			self.hasShot = self.HAS_SHOT_TIME
			playSound("shoot")
		end

		-- Move towards player
		local dist = player.x - self.x
		if math.abs(dist) > 32 then
			self.dir = math.sign(dist)
		end

		-- Check if dead or ready to get angry
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
			playSound("transform")
		end
	elseif self.state == BS_PUSHED then
		self.hit = true
		self.time = self.time - dt
		self.x = self.x - self.dir*self.PUSHED_SPEED*dt
		if self.time <= 0 then
			self:setState(BS_WALK)
		end

		-- Check if dead or ready to get angry
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
			playSound("transform")
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

	self.x = cap(self.x, 194, 462)
	self.health = cap(self.health, 0, self.MAX_HEALTH)
end

function GasLeak:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == BS_WALK then
		if self.angry == false then
			if self.x <= 194 or self.x >= 462 then
				if self.hasShot > 0 then
					self.anims[BS_IDLE]:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_idle_shot)
				else
					self.anims[BS_IDLE]:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128)
				end
			else
				if self.hasShot > 0 then
					self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_shot_walk)
				else
					self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128)
				end
			end
		else
			if self.x <= 194 or self.x >= 462 then
				if self.hasShot > 0 then
					self.anims[BS_IDLE]:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_rage_idle_shot)
				else
					self.anims[BS_IDLE]:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_rage_idle)
				end
			else
				if self.hasShot > 0 then
					self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_rage_shot_walk)
				else
					self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128, nil, img.gasleak_rage_walk)
				end
			end
		end
	elseif self.state == BS_IDLE then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128)
	elseif self.state == BS_PUSHED then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 64)
	elseif self.state == BS_TRANSITION or self.state == BS_DEAD then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 20, 128)
	end
end

function GasLeak:collideBox(bbox)
	if self.x-10 > bbox.x+bbox.w or self.x+10 < bbox.x
	or self.y-60 > bbox.y+bbox.h or self.y < bbox.y then
		return false
	else
		return true
	end
end

function GasLeak:getBBox()
	return {x = self.x-10, y = self.y-60, w = 20, h = 60}
end

function GasLeak:setState(state)
	self.state = state
	self.anim = self.anims[state]
	if self.anim then
		self.anim:reset()
	end
end

function GasLeak:shot(dt,dir)
	if self.state ~= BS_TRANSITION and self.state ~= BS_DEAD then
		self.health = self.health - dt
		self.hit = true
		self.dir = -dir
		self.time = self.PUSHED_COOLDOWN
		if self.state ~= BS_PUSHED then
			self:setState(BS_PUSHED)
		end
	end
end

function GasLeak:getPortraitImage()
	return img.gasleak_portrait
end
