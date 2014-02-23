function drawHealthBar(x,y, health, max_health)
	local length = math.floor((health/max_health)*16+0.5)
	lg.draw(img.enemy_healthbar, quad.enemy_healthbar_base, x-10, y, 0, 1, 1, 0, 4)
	lg.draw(img.enemy_healthbar, quad.enemy_healthbar_bar,  x-8, y, 0, length, 1, 0, 2)
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %           Normal enemy           %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NormalEnemy = { MOVE_SPEED = 80, FIRE_SPAWN_MIN = 7,FIRE_SPAWN_MAX = 25,
				MAX_HEALTH = 1.3, SCORE = 100, RECOVER_TIME = 0.7 }
NormalEnemy.__index = NormalEnemy

local EN_RUN, EN_HIT, EN_RECOVER, EN_IDLE, EN_JUMPING, EN_SHOOT = 0,1,2,3,4,5

local lg = love.graphics

function NormalEnemy.create(x,y)
	local self = setmetatable({}, NormalEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.dir = 1
	self.health = self.MAX_HEALTH
	self.state = EN_RUN
	self.time = 0
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
		
		-- Collide with walls
		if map:collidePoint(self.x + self.dir*7, self.y-13) == true then
			self.dir = self.dir*-1
			self.x = oldx
		end
		
		-- Collide with objects
		for i,v in ipairs(map.objects) do
			if v.solid == true then
				if self:collideBox(v:getBBox()) then
					self.x = oldx
					self.dir = self.dir*-1
					break
				end
			end
		end

		-- Check if it can spawn a fire
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
			self.time = self.RECOVER_TIME
		end
	-- Recovering
	elseif self.state == EN_RECOVER then
		self.time = self.time - dt
		if self.time < 0 then
			self.state = EN_RUN
			self.anim = self.anims[EN_RUN]
		end
	end

	self.anim:update(dt)

	self.hit = false
end

function NormalEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 26)

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 30, self.health, self.MAX_HEALTH)
	end
end

function NormalEnemy:drawLight()
	lg.draw(img.light_fire, quad.light_fire[(self.anim.position-1)%5], self.x-45, self.y-57)
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
		map:addParticle(BlackSmoke.create(self.x, self.y-8))
		self.alive = false
		playSound("enemydie")
		score = score + self.SCORE
		stats[1] = stats[1] + 1
	end
end

function NormalEnemy:getBBox()
	return {x = self.x-5, y = self.y-15, w = 10, h = 15}
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %        Angry Normal enemy        %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AngryNormalEnemy = { SCORE = 200, MAX_HEALTH = 1.8, RECOVER_TIME = 0.35 }
AngryNormalEnemy.__index = AngryNormalEnemy
setmetatable(AngryNormalEnemy, NormalEnemy)

function AngryNormalEnemy.create(x,y)
	local self = NormalEnemy.create(x,y)
	setmetatable(self, AngryNormalEnemy)

	self.health = self.MAX_HEALTH
	self.anims[EN_RUN].img = img.enemy_angrynormal_run
	self.anims[EN_HIT].img = img.enemy_angrynormal_hit
	self.anims[EN_RECOVER].img = img.enemy_angrynormal_recover

	self.anim = self.anims[self.state]

	return self
end

function AngryNormalEnemy:update(dt)
	NormalEnemy.update(self,dt)
	
	if self.state == EN_RUN then
		-- Follow player if in line of sight
		local xdist = math.abs(self.x-player.x)
		local ydist = math.abs(self.y-player.y)
		if ydist < 64 and xdist < 256 and xdist > 16 then
			if map:lineOfSight(self.x,self.y-12, player.x,player.y-12) then
				self.dir = math.sign(player.x-self.x)
			end
		end
	end
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %           Jumper enemy           %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
JumperEnemy = { MOVE_SPEED = 100, JUMP_DELAY = 1, JUMP_POWER = 150, MAX_HEALTH = 1.3, SCORE = 125,
				GRAVITY = 350, corners = {-6, 6, -24, -0.5 }, MIN_FIRE_TIME = 3, MAX_FIRE_TIME = 13}
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
	self.nextFire = math.random(self.MIN_FIRE_TIME, self.MAX_FIRE_TIME)

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
				self.nextFire = self.nextFire - 1
				if self.nextFire <= 0 then
					self.nextFire = math.random(self.MIN_FIRE_TIME, self.MAX_FIRE_TIME)
					map:addFire(math.floor(self.x/16), math.floor((self.y-8)/16))
				end
				self.state = EN_IDLE
				self.nextJump = self.JUMP_DELAY
			end
			self.yspeed = 0
		end
	end

	self.anim:update(dt)

	self.hit = false
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

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 36, self.health, self.MAX_HEALTH)
	end
end

function JumperEnemy:drawLight()
	lg.draw(img.light_fire, quad.light_fire[(self.anim.position-1)%5], self.x-45, self.y-62)
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
		playSound("enemydie")
		map:addParticle(BlackSmoke.create(self.x, self.y-14))
		score = score + self.SCORE
		stats[1] = stats[1] + 1
	end
end

function JumperEnemy:getBBox()
	return {x = self.x-5, y = self.y-23, w = 10, h = 23}
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %     Angry Jumper enemy     %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AngryJumperEnemy = { MAX_HEALTH = 1.8, MIN_FIRE_TIME = 3, MAX_FIRE_TIME = 8, SCORE = 200 }
AngryJumperEnemy.__index = AngryJumperEnemy
setmetatable(AngryJumperEnemy, JumperEnemy)

function AngryJumperEnemy.create(x,y)
	local self = JumperEnemy.create(x,y)
	setmetatable(self, AngryJumperEnemy)

	self.health = self.MAX_HEALTH
	self.anims[EN_JUMPING].img = img.enemy_angryjumper_jump

	return self
end

function AngryJumperEnemy:update(dt)
	JumperEnemy.update(self,dt)

	if self.state == EN_IDLE then
		-- Follow player if in line of sight
		local xdist = math.abs(self.x-player.x)
		local ydist = math.abs(self.y-player.y)
		if ydist < 64 and xdist < 256 and xdist > 16 then
			if map:lineOfSight(self.x,self.y-12, player.x,player.y-12) then
				self.dir = math.sign(player.x-self.x)
			end
		end
	end
end

function AngryJumperEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == EN_IDLE then
		if self.nextJump < self.JUMP_DELAY/1.5 then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 2, self.hit and img.enemy_angryjumper_hit)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 3, self.hit and img.enemy_angryjumper_hit)
		end
	elseif self.state == EN_JUMPING then
		self.anim:draw(self.flx, self.fly, 0, self.dir, 1,8, 32, 1, self.hit and img.enemy_angryjumper_hit)
	end

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 36, self.health, self.MAX_HEALTH)
	end
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %          Volcano enemy          %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VolcanoEnemy = { MOVE_SPEED = 60, MAX_HEALTH = 1.6, SHOOT_DELAY = 2, SHOT_COUNT = 4, SCORE = 200 }
VolcanoEnemy.__index = VolcanoEnemy

function VolcanoEnemy.create(x,y)
	local self = setmetatable({}, VolcanoEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.dir = 1
	self.nextShot = math.random()*2*self.SHOOT_DELAY
	self.health = self.MAX_HEALTH
	self.state = EN_RUN

	self.anims = {}
	self.anims[EN_RUN]   = newAnimation(img.enemy_volcano_run,   16, 32, 0.17, 4)

	self.anim = self.anims[self.state]

	return self
end

function VolcanoEnemy:update(dt)
	-- Running state
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

	self.nextShot = self.nextShot - dt
	if self.nextShot < 0 then
		self.nextShot = self.SHOOT_DELAY
		for i=0,self.SHOT_COUNT-1 do
			local xsp = self.dir*self.MOVE_SPEED - 60+i*40
			table.insert(map.enemies, Fireball.create(self.x, self.y-27, xsp))
		end
	end

	self.anim:update(dt)

	self.hit = false
end

function VolcanoEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.nextShot < 0.05 or self.nextShot > self.SHOOT_DELAY-0.5 then
		self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32, nil, img.enemy_volcano_shoot)
	else
		if self.hit == false then
			self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32, nil, img.enemy_volcano_hit)
		end
	end

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 36, self.health, self.MAX_HEALTH)
	end
end

function VolcanoEnemy:drawLight()
	lg.draw(img.light_fire, quad.light_fire[(self.anim.position-1)%5], self.x-45, self.y-60)
end

function VolcanoEnemy:shot(dt,dir)
	self.hit = true
	self.health = self.health - dt
	if self.health <= 0 then
		map:addParticle(BlackSmoke.create(self.x, self.y-8))
		self.alive = false
		playSound("enemydie")
		score = score + self.SCORE
		stats[1] = stats[1] + 1
	end
end

function VolcanoEnemy:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-15 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function VolcanoEnemy:getBBox()
	return {x = self.x-5, y = self.y-15, w = 10, h = 15}
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %    Angry Volcano enemy    %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
AngryVolcanoEnemy = { MAX_HEALTH = 1.9, SCORE = 300 }
AngryVolcanoEnemy.__index = AngryVolcanoEnemy
setmetatable(AngryVolcanoEnemy, VolcanoEnemy)

function AngryVolcanoEnemy.create(x,y)
	local self = VolcanoEnemy.create(x,y)
	setmetatable(self, AngryVolcanoEnemy)

	self.health = self.MAX_HEALTH
	self.anims[EN_RUN].img = img.enemy_angryvolcano_run

	return self
end

function AngryVolcanoEnemy:update(dt)
	VolcanoEnemy.update(self,dt)

	-- Shoot faster if player is in line of sight
	local xdist = math.abs(self.x-player.x)
	local ydist = math.abs(self.y-player.y)
	if ydist < 64 and xdist < 256 and xdist > 16 then
		if map:lineOfSight(self.x,self.y-12, player.x,player.y-12) then
			self.nextShot = self.nextShot - dt
		end
	end
end

function AngryVolcanoEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.nextShot < 0.05 or self.nextShot > self.SHOOT_DELAY-0.5 then
		self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32, nil, img.enemy_angryvolcano_shoot)
	else
		if self.hit == false then
			self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 32, nil, img.enemy_angryvolcano_hit)
		end
	end

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 36, self.health, self.MAX_HEALTH)
	end
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%
-- %      Thief enemy      %
-- %%%%%%%%%%%%%%%%%%%%%%%%%
ThiefEnemy = { MOVE_SPEED = 120, MAX_HEALTH = 1.5, SCORE = 350 }
ThiefEnemy.__index = ThiefEnemy
setmetatable(ThiefEnemy, NormalEnemy)

function ThiefEnemy.create(x,y)
	local self = setmetatable({}, ThiefEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.dir = 1
	self.health = self.MAX_HEALTH
	self.state = EN_RUN
	self.time = 0
	self.nextFire = math.random(self.FIRE_SPAWN_MIN, self.FIRE_SPAWN_MAX)

	self.anims = {}
	self.anims[EN_RUN]     = newAnimation(img.enemy_thief_run, 18, 32, 0.13, 4)
	self.anims[EN_HIT]     = newAnimation(img.enemy_thief_hit, 18, 32, 0.12, 2)
	self.anims[EN_RECOVER] = newAnimation(img.enemy_thief_recover, 18, 32, 0.07, 4)

	self.anim = self.anims[self.state]

	return self
end

function ThiefEnemy:update(dt)
	NormalEnemy.update(self,dt)
	
	if self.state == EN_RUN then
		-- Follow player if in line of sight
		local xdist = math.abs(self.x-player.x)
		local ydist = math.abs(self.y-player.y)
		if ydist < 64 and xdist < 256 and xdist > 16 then
			if map:lineOfSight(self.x,self.y-12, player.x,player.y-12) then
				self.dir = math.sign(player.x-self.x)
			end
		end

		-- Check collision with player
		if player:collideBox(self:getBBox()) == true then
			if player:stealItem() == true then
				map:addParticle(PopupText.create("theft"))
			end
			map:addFire(math.floor(self.x/16), math.floor((self.y-4)/16))
			map:addParticle(BlackSmoke.create(self.x, self.y-8))
			map:addParticle(BlackSmoke.create(self.x-6, self.y-18))
			map:addParticle(BlackSmoke.create(self.x+6, self.y-18))
			self.alive = false
		end
	end
end

function ThiefEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, self.dir,1, 9, 32)

	if self.hit == true then
		drawHealthBar(self.flx, self.fly - 36, self.health, self.MAX_HEALTH)
	end
end

-- %%%%%%%%%%%%%%%%%%%%%%%%%%
-- %        Fireball        %
-- %%%%%%%%%%%%%%%%%%%%%%%%%%
Fireball = { FIRE_ODDS = 25, SCORE = 10, GRAVITY = 350 }
Fireball.__index = Fireball

function Fireball.create(x,y,xspeed)
	local self = setmetatable({}, Fireball)
	self.alive = true
	self.x = x
	self.y = y
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)
	self.frame = math.random(0,3)
	self.frametime = math.random()*0.10
	self.xspeed = xspeed or math.random(-60,60)
	self.yspeed = yspeed or -math.random(100,150)

	return self
end

function Fireball:update(dt)
	-- Update position
	self.yspeed = self.yspeed + self.GRAVITY*dt

	self.x = self.x + self.xspeed*dt
	self.y = self.y + self.yspeed*dt

	-- Check collision with walls/floor and bounds
	local cx, cy = math.floor(self.x/16), math.floor(self.y/16)
	if self.y > MAPH+32 or map:collideCell(cx, cy) == true then
		if self.yspeed > 0 then
			local id = map:get(cx, cy)
			if id >= 1 and id <= 5 and math.random(self.FIRE_ODDS) == 1 then
				map:addFire(cx, cy-1)
			end
		end
		self.alive = false
		map:addParticle(SmallBlackSmoke.create(self.x, self.y-1))
	end

	-- Check collision with objects
	for i,v in ipairs(map.objects) do
		if v.solid == true then
			if self:collideBox(v:getBBox()) then
				self.alive = false
				map:addParticle(SmallBlackSmoke.create(self.x, self.y))
			end
		end
	end

	-- Update frame
	self.frametime = self.frametime + dt
	if self.frametime > 0.10 then
		self.frametime = self.frametime % 0.10
		self.frame = (self.frame + 1) % 4
	end
end

function Fireball:shot()
	self.alive = false
	map:addParticle(SmallBlackSmoke.create(self.x, self.y-1))
	score = score + self.SCORE
	stats[1] = stats[1] + 1
end

function Fireball:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)
	lg.draw(img.enemy_fireball, quad.fireball[self.frame], self.x, self.y, 0, 1, 1, 4, 4)
end

function Fireball:drawLight()
	lg.draw(img.light_fireball, quad.light_fireball[self.frame], self.x, self.y, 0, 1,1, 16, 16)
end

function Fireball:collideBox(bbox)
	if self.x-3 > bbox.x+bbox.w or self.x+3 < bbox.x
	or self.y-3 > bbox.y+bbox.h or self.y+3 < bbox.y then
		return false
	else
		return true
	end
end

function Fireball:getBBox()
	return {x = self.x-3, y = self.y-3, w = 6, h = 6}
end
