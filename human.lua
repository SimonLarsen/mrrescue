Human = { corners = {-5, 5, -16, -0.5} }
Human.__index = Human

local MOVE_SPEED = 50
local RUN_SPEED = 100
local THROW_SPEED = 250
local PUSH_SPEED  = 100
local NUM_HUMANS = 4
local GRAVITY = 350
local PANIC_RADIUS = 29
local MAX_HEALTH = 5
local SCORE = 250

local IDLE_TIME = 2
local WALK_TIME = 3

HS_WALK, HS_CARRIED, HS_FLY, HS_BURN, HS_IDLE, HS_PANIC = 0,1,2,3,4,5

function Human.create(x,y,id)
	local self = setmetatable({}, Human)

	self.alive = true
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.dir = 1
	self.id = id or math.random(1, NUM_HUMANS)
	self.health = MAX_HEALTH

	self.anims = {}
	self.anims[HS_WALK]  = newAnimation(img.human_run[self.id], 20,32, 0.22, 4)
	self.anims[HS_FLY]   = newAnimation(img.human_fly[self.id], 20, 32, 0, 4)
	self.anims[HS_BURN]  = newAnimation(img.human_burn[self.id], 20, 32, 0.10, 4)
	self.anims[HS_IDLE]  = self.anims[HS_WALK]
	self.anims[HS_PANIC] = newAnimation(img.human_panic[self.id], 20, 32, 0.10, 6)

	self:setState(HS_IDLE)
	self.time = math.random()*4

	return self
end

function Human:update(dt)
	-- Idle state
	if self.state == HS_IDLE then
		self.time = self.time - dt
		-- Go to walk state if idle time is over
		if self.time <= 0 then
			self:setState(HS_WALK)
		end

		self:collideFire()
		self:collideEnemies()

	-- Walking state
	elseif self.state == HS_WALK then
		self.xspeed = self.dir*MOVE_SPEED
		self.yspeed = self.yspeed + GRAVITY*dt

		self.x = self.x + self.xspeed*dt
		if collideX(self) == true then
			self.dir = self.dir*-1
		end
		self.y = self.y + self.yspeed*dt
		if collideY(self) == true then
			self.yspeed = 0 
		end

		-- Avoid walking into fire
		local isTrapped, fire_left, fire_right = self:isTrapped()
		if isTrapped == true then
			self:setState(HS_PANIC)
		elseif fire_left == true then
			self.dir = 1
		elseif fire_right == true then
			self.dir = -1
		end

		self.time = self.time - dt
		-- Go to idle state if walk time if over
		if self.time <= 0 then
			self:setState(HS_IDLE)
		end

		self:collideFire()
		self:collideEnemies()
	
	-- Panic state
	elseif self.state == HS_PANIC then
		self:collideFire()
		self:collideEnemies()
		
		-- Check if it is safe to continue
		if self:isTrapped() == false then
			self:setState(HS_IDLE)
		end
	
	-- Burning panic state
	elseif self.state == HS_BURN then
		self.xspeed = self.dir*RUN_SPEED
		self.yspeed = self.yspeed + GRAVITY*dt

		self.x = self.x + self.xspeed*dt
		if collideX(self) == true then
			self.dir = self.dir*-1
		end
		self.y = self.y + self.yspeed*dt
		if collideY(self) == true then
			self.yspeed = 0 
		end

		self.health = self.health - dt
		if self.health <= 0 then
			self.alive = false
			casualties = casualties + 1
			map:addParticle(Ashes.create(self.x, self.y))
		end
	-- Flying state
	elseif self.state == HS_FLY then
		if self.xspeed < 0 then
			self.xspeed = self.xspeed + dt*150
		elseif self.xspeed > 0 then
			self.xspeed = self.xspeed - dt*150
		end
		self.yspeed = self.yspeed + GRAVITY*dt

		self.x = self.x + self.xspeed*dt
		self:collideWindows()
		local col, last = collideX(self)
		if col == true then
			self.xspeed = self.xspeed*-0.6
			if last then
				last:shot(0.16, self.dir)
				if last.health >= 0 then
					playSound("door")
				end
			end
		end
		self.y = self.y + self.yspeed*dt
		if collideY(self) == true then
			self.buttHit = self.buttHit + 1
			self.yspeed = self.yspeed*-0.6
		end
		if self.buttHit >= 3 then
			self:setState(HS_WALK)
		end
	end

	-- Check if thrown out of window
	if self.x < -16 or self.x > MAPW+16 or self.y > MAPH+64 then
		saved = saved + 1
		self.alive = false

		last_rescue = 0
		combo = combo + 1
		if combo < 3 then
			map:addParticle(PopupText.create("rescue"))
			score = score + SCORE
		elseif combo >= 3 and combo <= 5 then
			map:addParticle(PopupText.create(combo.."combo"))
			score = score + (combo-1)*SCORE
		elseif combo > 5 then
			score = score + (combo-1)*SCORE
			map:addParticle(PopupText.create("megacombo"))
		end
		playSound("rescue")
		stats[4] = stats[4] + 1
	end

	-- Update animation
	if self.anim then
		self.anim:update(dt)
	end
end

function Human:collideFire()
	-- Check collision with fire
	for j,w in pairs(map.fire) do
		for i,v in pairs(w) do
			if self:collideBox(v:getBBox()) == true then
				self:setState(HS_BURN)
				return
			end
		end
	end
end

function Human:collideEnemies()
	for i,v in ipairs(map.enemies) do
		if self:collideBox(v:getBBox()) == true then
			self:setState(HS_BURN)
			return
		end
	end
end

function Human:isTrapped()
	local lx = math.floor((self.x-PANIC_RADIUS)/16)
	local rx = math.floor((self.x+PANIC_RADIUS)/16)
	local cy = math.floor((self.y-8)/16)
	local fire_left  = map:hasFire(lx, cy)
	local fire_right = map:hasFire(rx, cy)

	if fire_left == true then
		if fire_right == true or map:collideCell(rx,cy) then
			return true, fire_left, fire_right
		end
	elseif fire_right == true then
		if fire_left == true or map:collideCell(lx,cy) then
			return true, fire_left, fire_right
		end
	end
	return false, fire_left, fire_right
end

function Human:setState(state)
	self.state = state
	self.anim = self.anims[self.state]
	if self.anim then
		self.anim:reset()
	end

	if state == HS_IDLE then
		self.time = IDLE_TIME
	elseif self.state == HS_WALK then
		self.time = WALK_TIME
	end
end

function Human:shot(dt,dir)
	if self.state == HS_BURN then
		self:setState(HS_WALK)
	end

	if self.state == HS_IDLE or self.state == HS_PANIC
	or self.state == HS_BURN or self.state == HS_WALK then
		self:push(self.x, self.y, dir)
	end
end

function Human:collideWindows()
	for i=1,2 do
		local tile = map:getPoint(self.x+self.corners[i], self.y+self.corners[4])
		if tile == 38 or tile == 39 then
			local cx = math.floor((self.x+self.corners[i])/16)
			local cy = math.floor((self.y+self.corners[4])/16)
			map:hitCell(cx,cy,math.sign(self.xspeed))
		end
	end
end

function Human:throw(x,y,dir)
	self:setState(HS_FLY)
	self.x = x
	self.y = y
	self.xspeed = THROW_SPEED*dir
	self.yspeed = -130
	self.dir = dir
	self.buttHit = 0
	playSound("throw")
end

function Human:push(x,y,dir,intensity)
	self:setState(HS_FLY)
	self.x = x
	self.y = y
	self.xspeed = PUSH_SPEED*dir
	self.yspeed = -50
	self.buttHit = 0
end

function Human:canGrab()
	return self.state ~= HS_BURN
end

function Human:grab()
	self:setState(HS_CARRIED)
end

function Human:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == HS_WALK or self.state == HS_BURN or self.state == HS_PANIC then
		self.anim:draw(self.flx, self.fly, 0,self.dir,1, 10, 32)
	elseif self.state == HS_IDLE then
		self.anim:draw(self.flx, self.fly, 0,self.dir,1, 10, 32, 1)
	elseif self.state == HS_FLY then
		if self.buttHit < 2 then
			if self.yspeed > -20 then
				self.anim:draw(self.flx, self.fly, 0, self.dir, 1,10,32, 1)
			else
				self.anim:draw(self.flx, self.fly, 0, self.dir, 1,10,32, 2)
			end
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1,10,32, 3)
		end
	end
end


function Human:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-16 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function Human:getBBox()
	return {x = self.x-5, y = self.y-16, w = 10, h = 16}
end
