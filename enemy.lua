-- Normal enemy
NormalEnemy = { MOVE_SPEED = 80, FIRE_SPAWN_MIN = 10, FIRE_SPAWN_MAX = 30, MAX_HEALTH = 1.2 }
NormalEnemy.__index = NormalEnemy

local EN_RUN, EN_HIT, EN_RECOVER, EN_IDLE, EN_JUMPING = 0,1,2,3,4

function NormalEnemy.create(x,y)
	local self = setmetatable({}, NormalEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.dir = 1
	self.health = self.MAX_HEALTH
	self.state = EN_RUN
	self.time = math.random(1,2)
	self.nextFire = math.random(self.FIRE_SPAWN_MIN, self.FIRE_SPAWN_MAX)

	self.anims = {}
	self.anims[EN_RUN]     = newAnimation(img.enemy_normal_run, 16, 26, 0.13, 4)
	self.anims[EN_HIT]     = newAnimation(img.enemy_normal_hit, 16, 26, 0.12, 2)
	self.anims[EN_RECOVER] = newAnimation(img.enemy_normal_recover, 16, 26, 0.07, 4)

	self.anim = self.anims[self.state]

	return self
end

function NormalEnemy:update(dt)
	-- Running state
	if self.state == EN_RUN then
		local oldx = self.x
		self.x = self.x + self.dir*self.MOVE_SPEED*dt
		
		if map:collidePoint(self.x + self.dir*7, self.y-13) == true then
			self.dir = self.dir*-1
			self.x = oldx
		end
		
		for i,v in ipairs(map.objects) do
			if v.solid == true then
				if self:collideBox(v:getBBox()) then
					self.x = oldx
					self.dir = self.dir*-1
					break
				end
			end
		end

		self.nextFire = self.nextFire - dt
		if self.nextFire <= 0 then
			map:addFire(math.floor(self.x/16), math.floor((self.y-4)/16))
			self.nextFire = math.random(self.FIRE_SPAWN_MIN, self.FIRE_SPAWN_MAX)
		end

	-- Getting hit
	elseif self.state == EN_HIT then
		if self.hit == false then
			self.state = EN_RECOVER
			self.anim = self.anims[EN_RECOVER]
			self.time = 0.7
		end
	-- Recovering
	elseif self.state == EN_RECOVER then
		self.time = self.time - dt
		if self.time < 0 then
			self.state = EN_RUN
			self.anim = self.anims[EN_RUN]
		end
	end

	self.hit = false

	self.anim:update(dt)
end

function NormalEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == EN_IDLE then
		self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 26, 2)
	else
		self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 26)
	end
end

function NormalEnemy:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-15 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function NormalEnemy:shot(dt,dir)
	self.dir = -1*dir
	self.state = EN_HIT
	self.anim = self.anims[EN_HIT]
	self.hit = true

	self.health = self.health - dt
	if self.health <= 0 then
		self.alive = false
	end
end

function NormalEnemy:getBBox()
	return {x = self.x-5, y = self.y-15, w = 10, y = 15}
end

-- Jumper enemy
JumperEnemy = { MOVE_SPEED = 100, JUMP_DELAY = 1, JUMP_POWER = 150, MAX_HEALTH = 1.0,
				GRAVITY = 350, corners = {-6, 6, -24, -0.5 } }
JumperEnemy.__index = JumperEnemy

function JumperEnemy.create(x,y)
	local self = setmetatable({}, JumperEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.speed = 0
	self.yspeed = 0
	self.dir = (math.random(2)-1)*-2+1 -- either 1 or -1
	self.health = self.MAX_HEALTH

	self.state = EN_IDLE
	self.nextJump = self.JUMP_DELAY*math.random()

	self.anims = {}
	self.anims[EN_JUMPING] = newAnimation(img.enemy_jumper_jump, 16, 32, 0.12, 3)
	self.anims[EN_IDLE]    = self.anims[EN_JUMPING]

	self.anim = self.anims[self.state]

	return self
end

function JumperEnemy:update(dt)
	if self.state == EN_IDLE then
		self.nextJump = self.nextJump - dt
		if self.nextJump <= 0 then
			self.state = EN_JUMPING
			self.yspeed = -self.JUMP_POWER
		end

	elseif self.state == EN_JUMPING then
		self.xspeed = self.MOVE_SPEED*self.dir
		self.x = self.x + self.xspeed*dt
		if collideX(self) == true then
			self.dir = self.dir*-1
		end

		self.yspeed = self.yspeed + self.GRAVITY*dt
		self.y = self.y + self.yspeed*dt
		if collideY(self) == true then
			if self.yspeed > 0 then
				self.state = EN_IDLE
				self.nextJump = self.JUMP_DELAY
			end
			self.yspeed = 0
		end
	end

	self.anim:update(dt)
end

function JumperEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == EN_IDLE then
		if self.nextJump < self.JUMP_DELAY/1.5 then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 2, self.hit and img.enemy_jumper_hit)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 3, self.hit and img.enemy_jumper_hit)
		end
	elseif self.state == EN_JUMPING then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 1, self.hit and img.enemy_jumper_hit)
	end
	self.hit = false
end

function JumperEnemy:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-23 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function JumperEnemy:shot(dt,dir)
	self.hit = true
	self.health = self.health - dt
	if self.health <= 0 then
		self.alive = false
	end
end

function JumperEnemy:getBBox()
	return {x = self.x-5, y = self.y-23, w = 10, y = 23}
end
