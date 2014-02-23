Player = { corners = {-6, 5, -22, -0.5} }
Player.__index = Player

local RUN_SPEED = 500 -- Run acceleration
local MAX_SPEED = 160 -- Maximum running speed
local MAX_SPEED_CARRY = 100 -- Maximum running speed when carrying human
local BRAKE_SPEED = 250
local GRAVITY = 350
local JUMP_POWER = 135 -- initial yspeed when jumping
local CLIMB_SPEED = 60 -- climbing speed
local STREAM_SPEED = 400 -- stream growth speed
local MAX_STREAM = 100 -- maximum stream length
local USE_RATE   = 2.5
local BURN_DAMAGE = 0.5 -- Damage over time when touching enemies
local TIME_DAMAGE = 0.008
local FIRE_DIST = 1600

PS_RUN, PS_CLIMB, PS_CARRY, PS_THROW, PS_DEAD = 0,1,2,3,4 -- Player states
local GD_UP, GD_HORIZONTAL, GD_DOWN = 0,2,4 -- Gun directions

local lg = love.graphics

function Player.create(x,y,level)
	local self = setmetatable({}, Player)

	self.x, self.y = x, y

	self.xspeed = 0
	self.yspeed = 0
	self.onGround = false
	self.time = 0
	self.lastDir = 1
	self.state = PS_RUN
	self.dir = 1 -- -1 for left, 1 for right

	self.gundir = GD_HORIZONTAL -- gun direction
	self.shooting = false
	self.streamLength = 0
	self.streamCollided = false
	self.wquad = love.graphics.newQuad(0,0,10,10, 16,16) -- water stream quad

	self.regen_rate = 3.0
	self.water_capacity = 5
	self.water = self.water_capacity
	self.overloaded = false
	self.hasReserve = false

	-- Number of powerups collected
	self.num_regens = 0
	self.num_suits = 0
	self.num_tanks = 0

	-- Temperature stats
	self.temperature = 0 -- current temperature
	if level == 1 then
		self.max_temperature = 1.5 -- temperature player can withstand
	elseif level == 2 then
		self.max_temperature = 1.2
	else
		self.max_temperature = 1.0
	end
	self.heat = 0 -- how much heat is currently taken

	-- Grabbing civilians
	self.canGrab = false
	self.grabbed = nil -- grabbed human

	-- Animations
	self.animRun 	    = newAnimation(img.player_running, 16, 22, 0.12, 4)
	self.animThrow      = newAnimation(img.player_throw, 16,32, 0.12, 4)
	self.animClimb      = newAnimation(img.player_climb_down, 14, 23, 0.12, 4)
	self.animCarryLeft  = newAnimation(img.human_1_carry_left,  22, 32, 0.12, 4)
	self.animCarryRight = newAnimation(img.human_1_carry_right, 22, 32, 0.12, 4)

	self.anim = self.animRun
	self.waterFrame = 0 -- water stream's frame
	
	return self
end

--- Moves the player to position x,y
--  and resets velocity in both axes
function Player:warp(x,y)
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.streamLength = 0
	self.shooting = false
end

--- Updates the player
-- Called once once each love.update
-- @param dt Time passed since last update
function Player:update(dt)
	self.shooting = false

	-- RUNNING STATE
	if self.state == PS_RUN then
		self:updateRunning(dt)
		self:updateGun(dt)
	-- CLIMBING STATE
	elseif self.state == PS_CLIMB then
		self:updateClimbing(dt)
	-- CARRYING STATE
	elseif self.state == PS_CARRY then
		self:updateRunning(dt)
		if self.dir == -1 then
			self.anim = self.animCarryLeft
			self.anim.img = img.human_carry_left[self.grabbed.id]
		else
			self.anim = self.animCarryRight
			self.anim.img = img.human_carry_right[self.grabbed.id]
		end
	-- THROWING STATE
	elseif self.state == PS_THROW then
		self:updateRunning(dt)
		self.time = self.time - dt
		if self.time <= 0 then
			self:setState(PS_RUN)
		end
	-- DEAD STATE
	elseif self.state == PS_DEAD then
		self.yspeed = self.yspeed + GRAVITY*dt
		self.time = self.time + dt*self.yspeed
		if self.time > MAPH+32 then
			ingame_state = INGAME_GAMEOVER_OUT
			transition_time = 0
		end
	end

	-- Regen water
	if self.overloaded == true then
		self.water = cap(self.water+0.5*self.regen_rate*dt, 0, self.water_capacity)
		if self.water >= self.water_capacity then
			self.overloaded = false
		end
	else
		self.water = cap(self.water+self.regen_rate*dt, 0, self.water_capacity)
	end

	-- Update animations
	self.anim:update(dt)
	self.waterFrame = self.waterFrame + dt*10

	-- Collide items
	for i,v in ipairs(map.items) do
		if self:collideBox(v:getBBox()) == true then
			self:applyItem(v)
			map:addParticle(Sparkles.create(v.x+6, v.y+10, 15, 2))
			map:addParticle(PopupText.create(v.id))
			playSound("powerup")
			v.alive = false
			score = score + 500
		end
	end

	-- Collide fire
	self:collideFire(dt)
	-- Add temperature over time
	if map.type == MT_NORMAL then
		self.temperature = self.temperature + TIME_DAMAGE*dt
	end
	self.temperature = cap(self.temperature, 0, self.max_temperature)

	-- Detect death
	if self.temperature >= self.max_temperature and self.state ~= PS_DEAD then
		self.time = self.fly
		self.yspeed = -230
		self.state = PS_DEAD
	end

	-- Count up distance moved stat (16 pixels per meter)
	local dist = (math.sqrt(self.xspeed^2 + self.yspeed^2)*dt)/16
	stats[3] = stats[3] + dist
end

--- Called each update if current state is PS_RUN
-- @param dt Time passed since laste update
function Player:updateRunning(dt)
	local changedDir = false -- true if player changed horizontal direction

	-- Check if both directions are held for handling conflicts
	local both = keystate.right and keystate.left
	-- Walk left
	if (both == false and keystate.right) or (both == true and self.lastDir == 1) then
		self.xspeed = self.xspeed + RUN_SPEED*dt

		if self.dir == -1 then
			self.dir = 1
			changedDir = true
		end
	-- Walk right
	elseif (both == false and keystate.left) or (both == true and self.lastDir == -1) then
		self.xspeed = self.xspeed - RUN_SPEED*dt

		if self.dir == 1 then
			self.dir = -1
			changedDir = true
		end
	end

	-- Slow speed if carring human
	if self.state == PS_CARRY then
		self.xspeed = cap(self.xspeed, -MAX_SPEED_CARRY, MAX_SPEED_CARRY)
	else
		self.xspeed = cap(self.xspeed, -MAX_SPEED, MAX_SPEED)
	end

	-- Cut stream if direction has changed
	if changedDir == true and self.gundir == GD_HORIZONTAL then
		self.streamLength = 0
	end

	-- Cap speeds
	if self.xspeed < 0 then
		self.xspeed = self.xspeed + math.max(dt*BRAKE_SPEED, self.xspeed)
	elseif self.xspeed > 0 then
		self.xspeed = self.xspeed - math.min(dt*BRAKE_SPEED, self.xspeed)
	end

	-- Move in x axis
	self.x = self.x + self.xspeed*dt
	if collideX(self) == true then
		self.xspeed = -1.0*self.xspeed
	end
	-- Update gravity
	self.yspeed = self.yspeed + GRAVITY*dt
	-- Move in y axis
	self.y = self.y + self.yspeed*dt
	if collideY(self) == true then
		self.yspeed = 0
	end

	self.canGrab = false
	for i,v in ipairs(map.humans) do
		if self:collideBox(v:getBBox()) and v:canGrab() == true then
			self.canGrab = true
		end
	end

	-- Set animation speeds
	self.anim:setSpeed(math.abs(self.xspeed)/MAX_SPEED)
end

function Player:collideFire(dt)
	self.heat = 0
	-- Check collision with enemies
	for i,v in ipairs(map.enemies) do
		if self:collideBox(v:getBBox()) == true then
			self.heat = 1
			break
		end
	end

	-- Check collision with boss
	if map.type == MT_BOSS and map.boss.state ~= BS_DEAD then
		if self:collideBox(map.boss:getBBox()) == true then
			self.heat = 1
		elseif map.boss.shockwaveActive == true then
			if self:collideBox(map.boss:getShockwaveBBox()) == true then
				self.heat = 1.0
				self.xspeed = self.xspeed + math.sign(self.x-map.boss.x)*100
			end
		end
	end

	local cx = math.floor(self.x/16)
	local cy = math.floor((self.y-11)/16)

	-- Calculate heat contribution from nearby flames
	local fireHeat = 0
	for ix = cx-2,cx+2 do
		for iy = cy-2,cy+2 do
			if map:hasFire(ix,iy) == true then
				local fx, fy = ix*16+8, iy*16+8
				local dist = math.pow(self.x-fx,2) + math.pow(self.y-fy-11,2)

				if dist <= FIRE_DIST then
					-- Calculate damage based on flame's health
					local damage = map:getFire(ix,iy).health/Fire.max_health
					if damage > 0 then
						local contrib = math.pow(1-dist/FIRE_DIST, 2)*damage*0.5
						fireHeat = fireHeat + contrib
					end
				end
			end
		end
	end

	self.heat = cap(self.heat + fireHeat, 0, self.max_temperature)
	self.temperature = self.temperature + self.heat*BURN_DAMAGE*dt
end

--- Updates gun direction and stream
function Player:updateGun(dt)
	-- Find gundirection
	local old_gundir = self.gundir
	self.gundir = GD_HORIZONTAL
	if keystate.up then
		self.gundir = GD_UP
	elseif keystate.down then
		self.gundir = GD_DOWN
	end
	if self.gundir ~= old_gundir or changedDir and self.gundir == HORIZONTAL then
		self.streamLength = 0
	end

	-- Update stream length and collide it with entities/walls
	self:updateStream(dt)
end

--- Updates the water stream
-- Updates the length of the water stream
-- and performs collision with walls and other entities
function Player:updateStream(dt)
	-- Shoot
	if keystate.shoot and self.overloaded == false then
		self.shooting = true
		self.streamLength = math.min(self.streamLength + STREAM_SPEED*dt, MAX_STREAM)
		stats[2] = stats[2] + 20*dt
	else
		self.shooting = false
		self.streamLength = 0
		return
	end

	self.water = self.water - (USE_RATE+self.regen_rate)*dt
	if self.water <= 0 then
		if self.hasReserve == true then
			self.hasReserve = false
			self.water = self.water_capacity
		else
			self.overloaded = true
		end
	end

	-- Collide with walls
	local span = math.ceil((self.streamLength+12)/16)
	local cx = math.floor(self.x/16)
	local cy = math.floor((self.y-6)/16)
	self.streamCollided = false

	if self.gundir == GD_UP then -- up
		for i = 1,span do
			cy = cy - 1
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy,self.dir)
				self.streamLength = self.y-(cy+1)*16-20
				self.streamCollided = true
				break
			end
		end
	elseif self.gundir == GD_DOWN then -- down
		for i = 1,span do
			cy = cy + 1
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy,self.dir)
				self.streamLength = cy*16-self.y-4
				self.streamCollided = true
				break
			end
		end
	elseif self.gundir == GD_HORIZONTAL then -- horizontal
		for i = 1,span do
			cx = cx + self.dir
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy,self.dir)
				if self.dir == -1 then
					self.streamLength = self.x-(cx+1)*16-13
				else
					self.streamLength = cx*16-self.x-10
				end
				self.streamCollided = true
				break
			end
		end
	end

	-- Collide with entities
	-- Calculate stream's collision box (table creation each frame!)
	local sbox
	if self.gundir == GD_UP then -- up
		sbox = {x = self.x-4.5, y = self.y-17-self.streamLength, w = 9, h = self.streamLength}
	elseif self.gundir == GD_HORIZONTAL then -- horizontal
		if self.dir == -1 then
			sbox = {x = self.x-9-self.streamLength, y = self.y-10, w = self.streamLength, h = 9}
		else
			sbox = {x = self.x+9, y = self.y-10, w = self.streamLength, h = 9}
		end
	elseif self.gundir == GD_DOWN then -- down
		sbox = {x = self.x-4.5, y = self.y+1, w = 9, h = self.streamLength}
	end

	-- Collide with enemies
	local closestHit = nil
	local min = 9999
	-- Collide with objects and entities
	for j,w in ipairs({map.humans, map.objects, map.enemies}) do
		for i,v in ipairs(w) do
			if v:collideBox(sbox) == true then
				local dist = self:cutStream(v:getBBox())
				if dist < min then 
					closestHit = v
					min = dist
				end
				self.streamCollided = true
			end
		end
	end
	-- Collide with boss
	if map.type == MT_BOSS then
		if map.boss:collideBox(sbox) == true then
			local dist = self:cutStream(map.boss:getBBox())
			if dist < min then
				closestHit = map.boss
				min = dist
			end
			self.streamCollided = true
		end
	end
	-- Collide with fire
	for j,w in pairs(map.fire) do
		for i,v in pairs(w) do
			if v:collideBox(sbox) == true then
				local dist = self:cutStream(v:getBBox())
				if dist < min then
					closestHit = v
					min = dist
				end
				self.streamCollided = true
			end
		end
	end
	-- If an object was hit, cut stream and hit object
	if closestHit ~= nil then
		closestHit:shot(dt,self.dir)
		self.streamLength = min
	end
	-- Cap stream length
	self.streamLength = math.max(0, self.streamLength)
end

--- Cuts the stream off after colliding with a bounding box
-- @param box Bounding box stream collided with
function Player:cutStream(box)
	if self.gundir == GD_HORIZONTAL then -- horizontal
		if self.dir == -1 then -- left
			return self.x - (box.x+box.w)-12
		else
			return box.x - self.x-9
		end
	elseif self.gundir == GD_UP then -- up
		return self.y - (box.y+box.h+18)
	elseif self.gundir == GD_DOWN then -- down
		return box.y - self.y-4
	else
		return 0
	end
end

--- Called each update if the current state is PS_CLIMB
-- @param dt Time passed since last update
function Player:updateClimbing(dt)
	local oldy = self.y
	-- Move up and down ladder
	local animSpeed = 0
	if keystate.down then
		self.y = self.y + CLIMB_SPEED*dt
		self.animClimb.direction = 1
		animSpeed = 1
	end
	if keystate.up then
		self.y = self.y - CLIMB_SPEED*dt
		self.animClimb.direction = -1
		animSpeed = 1
	end
	self.anim:setSpeed(animSpeed)

	-- Check if player has moved off ladder
	local idBottom = map:getPoint(self.x, self.y)
	local idMid = map:getPoint(self.x, self.y-11)
	local idTop = map:getPoint(self.x, self.y-22)
	if idBottom == 2 or idBottom == 26 or idBottom == nil then -- over ladder
		self.y = oldy
		self:setState(PS_RUN)
	elseif idBottom ~= 5 and idBottom ~= 8 and idBottom ~= 137
	and idBottom ~= 153 and idBottom ~= 247
	and idBottom ~= 13 and idBottom ~= 63 and idBottom ~= 79 then
		self:setState(PS_RUN)
	end
end

function Player:leaveLadder()
	local idBottom = map:getPoint(self.x, self.y)
	local idMid = map:getPoint(self.x, self.y-11)
	local idTop = map:getPoint(self.x, self.y-22)
	if  idBottom ~= 5 and idMid ~= 5 and idTop ~= 5
	and idBottom ~= 8 and idMid ~= 8 and idTop ~= 8
	and idBottom ~= 13 and idMid ~= 13 and idTop ~= 13 then
		self:setState(PS_RUN)
	end
end

function Player:action(action)
	if action == "jump" then
		self:jump()
	elseif action == "action" then
		if self.state == PS_RUN then
			self:grab()
		elseif self.state == PS_CARRY then
			self:setState(PS_THROW)
			self.grabbed:throw(self.x, self.y, self.dir)
			self.grabbed = nil
		elseif self.state == PS_CLIMB then
			self:leaveLadder()
		end
	elseif (action == "up" or action == "down") and self.shooting == false then
		if self.state == PS_RUN then
			self:climb()
		end

	elseif action == "left" or action == "right" then
		-- Save last direction for conflicts
		if action == "left" then
			self.lastDir = -1
		else
			self.lastDir = 1
		end

		-- Leave ladder if currently climbing
		if self.state == PS_CLIMB then
			self:leaveLadder()
		end
	elseif action == "shoot" then
		if self.state == PS_RUN and self.overloaded == true then
			playSound("empty")
		end
	end
end

--- Changes the current state and resets current animation
-- @param state New state
function Player:setState(state)
	if state == PS_RUN then
		self.state = PS_RUN
		self.anim = self.animRun
	elseif state == PS_CLIMB then
		self.state = PS_CLIMB
		self.anim = self.animClimb
		self.xspeed, self.yspeed = 0,0
	elseif state == PS_CARRY then
		self.state = PS_CARRY
	elseif state == PS_THROW then
		self.state = PS_THROW
		self.anim = self.animThrow
		self.time = 0.4
	end

	self.streamLength = 0
	self.anim:reset()
end

--- Applies the effect of a given item
-- @param item The item to apply
function Player:applyItem(item)
	if item.id == "coolant" then
		self.temperature = cap(self.temperature - 0.25, 0, self.max_temperature)
	elseif item.id == "reserve" then
		self.hasReserve = true
	elseif item.id == "suit" then
		self.num_suits = cap(self.num_suits + 1, 0, 3)
		self.max_temperature = cap(self.max_temperature + 0.2, 1, 1.6)
	elseif item.id == "tank" then
		self.num_tanks = cap(self.num_tanks + 1, 0, 3)
		self.water_capacity = cap(self.water_capacity + 1, 5, 8)
	elseif item.id == "regen" then
		self.num_regens = cap(self.num_regens + 1, 0, 3)
		self.regen_rate = cap(self.regen_rate + 0.5, 3, 4.5)
	end
end

function Player:stealItem()
	local sum = self.num_suits + self.num_tanks + self.num_regens
	if sum == 0 then return false end

	local val = math.random(1,sum)
	if self.num_suits > 0 and val <= self.num_suits then
		self.num_suits = cap(self.num_suits - 1, 0, 3)
		self.max_temperature = self.max_temperature - 0.2
	elseif self.num_tanks > 0 and val <= self.num_suits+self.num_tanks then
		self.num_tanks = cap(self.num_tanks - 1, 0, 3)
		self.water_capacity = self.water_capacity - 1
	else
		self.num_regens = cap(self.num_regens - 1, 0, 3)
		self.regen_rate = self.regen_rate - 0.5
	end

	return true
end

--- Makes the player jump
function Player:jump()
	if self.state == PS_CLIMB then
		self:leaveLadder()
	elseif self.onGround == true and self.state ~= PS_DEAD then
		playSound("jump")
		self.yspeed = -JUMP_POWER
	end
end

--- Called when player tries to grab a ladder
-- @return True if a ladder was grabbed
function Player:climb()
	local below = map:getPoint(self.x, self.y+1)
	local top    = map:getPoint(self.x, self.y-22)
	if below == 5 or below == 137 or below == 153 or below == 8 or below == 247
	or top == 5 or top == 137 or top == 153 or top == 8 or top == 247
	or top == 63 or top == 79 or below == 13 then
		self:setState(PS_CLIMB)
		self.x = math.floor(self.x/16)*16+8 -- Align with middle of ladder
		return true
	end
	return false
end

function Player:grab()
	for i,v in ipairs(map.humans) do
		if self:collideBox(v:getBBox()) and v:canGrab() == true then
			self.grabbed = v
			self:setState(PS_CARRY)
			v:grab()
			return
		end
	end
end

function Player:isDying()
	return self.temperature > self.max_temperature*0.75
end

function Player:collideBox(bbox)
	if self.x-6  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-22 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function Player:draw()
	-- Floor position
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == PS_RUN then
		-- Draw player
		if self.onGround == false then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 8, 22, 2)
		elseif math.abs(self.xspeed) < 30 then
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 8, 22, 4)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 8, 22)
		end

		-- Draw gun
		lg.draw(img.player_gun, quad.player_gun[self.gundir], self.flx, self.fly-16, 0, self.dir, 1, 3, 0)

		-- Draw water
		if self.shooting == true then
			self:drawWater()
		end

		-- Draw exclamation
		if self.canGrab == true then
			lg.draw(img.exclamation, self.flx, self.fly, 0, 1,1, 2, 40)
		end
	-- Climbing
	elseif self.state == PS_CLIMB then
		self.anim:draw(self.flx, self.fly, 0, 1,1, 7, 20)
	-- Carrying a human
	elseif self.state == PS_CARRY then
		if math.abs(self.xspeed) < 30 then
			if self.dir == -1 then
				self.anim:draw(self.flx, self.fly, 0, 1,1, 12, 32, 1)
			else
				self.anim:draw(self.flx, self.fly, 0, 1,1, 12, 32, 1)
			end
		else
			self.anim:draw(self.flx, self.fly, 0, 1,1, 12, 32)
		end
	-- Throwing human
	elseif self.state == PS_THROW then
		if self.onGround == false then
			self.anim:draw(self.flx, self.fly, 0,self.dir,1, 8, 22, 2)
		elseif math.abs(self.xspeed) < 30 then
			self.anim:draw(self.flx, self.fly, 0,self.dir,1, 8, 22, 4)
		else
			self.anim:draw(self.flx, self.fly, 0,self.dir,1, 8, 22)
		end
	-- Dead from overheating
	elseif self.state == PS_DEAD then
		if self.yspeed < 0 then
			lg.draw(img.player_death, quad.player_death_up, self.flx, self.time, 0,self.dir,1, 8, 24)
			lg.draw(img.player_death, quad.player_death_suit, self.flx, self.fly, 0,self.dir,1, 7, 10)
		else
			lg.draw(img.player_death, quad.player_death_suit, self.flx, self.fly, 0,self.dir,1, 7, 10)
			lg.draw(img.player_death, quad.player_death_down, self.flx, self.time, 0,self.dir,1, 8,25)
		end
	end
end

function Player:drawWater()
	local quadx = 8-math.floor((self.waterFrame*8)%8)
	self.wquad:setViewport(quadx, 0, math.floor(self.streamLength), 9)
	local frame = math.floor(self.waterFrame%2)

	if self.gundir == GD_UP then -- up
		if self.streamLength > 0 then
			lg.draw(img.stream, self.wquad, self.flx, self.fly, -math.pi/2, 1, self.dir, -19, 4)
			if self.streamCollided == false then
				lg.draw(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly-20-math.floor(self.streamLength), -math.pi/2, 1,1, 8, 7.5)
			else
				lg.draw(img.water, quad.water_hit[frame], self.flx+self.dir*0.5, self.fly-13-math.floor(self.streamLength), -math.pi/2, 1,1, 8, 9.5)
			end
		end
		lg.draw(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly-16, -math.pi/2, 1,1, 0,7.5)

	elseif self.gundir == GD_HORIZONTAL then -- horizontal
		if self.streamLength > 0 then
			lg.draw(img.stream, self.wquad, self.flx+self.dir*11, self.fly-10, 0, self.dir, 1)
			if self.streamCollided == false then
				lg.draw(img.water, quad.water_end[frame], self.flx+self.dir*(11+math.floor(self.streamLength)), self.fly-5, 0, self.dir,1, 7.5, 8)
			else
				lg.draw(img.water, quad.water_hit[frame], self.flx+self.dir*(6.5+math.floor(self.streamLength))-1, self.fly-7, 0, self.dir,1, 9.5, 8)
			end
		end
		lg.draw(img.water, quad.water_out[frame], self.flx, self.fly, 0, self.dir,1, -9,13)
	
	elseif self.gundir == GD_DOWN then -- down
		if self.streamLength > 0 then
			lg.draw(img.stream, self.wquad, self.flx, self.fly, -math.pi/2, -1, self.dir, -5, 4)
			if self.streamCollided == false then
				lg.draw(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly+math.floor(self.streamLength), math.pi/2, 1,1, 5, 7.5)
			else
				lg.draw(img.water, quad.water_hit[frame], self.flx+self.dir*0.5, self.fly+math.floor(self.streamLength)+1, math.pi/2, 1,1, 11, 9.5)
			end
		end
		lg.draw(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly+2, math.pi/2, 1,1, 0,7.5)
	end
end
