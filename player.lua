Player = {}
Player.__index = Player

local RUN_SPEED = 500
local MAX_SPEED = 160
local BRAKE_SPEED = 250
local GRAVITY = 350
local JUMP_POWER = 130
local CLIMB_SPEED = 60
local STREAM_SPEED = 400 -- stream growth speed
local MAX_STREAM = 200 -- maximum stream length

local COL_OFFSETS = {{-6,-0.0001}, {5,-0.0001}, {-6,-22}, {5,-22}} -- Collision point offsets

local PL_RUN, PL_CLIMB = 0,1

function Player.create(x,y)
	local self = setmetatable({}, Player)

	self.x, self.y = x, y

	self.xspeed = 0
	self.yspeed = 0
	self.onGround = false

	self.shooting = false
	self.streamLength = 0
	self.streamCollided = false

	self.state = PL_RUN
	self.gundir = 2 -- gun direction

	self.dir = 1 -- -1 for left, 1 for right

	self.animRun =  newAnimation(img.player_running, 15, 22, 0.12, 4)
	self.animClimbUp   = newAnimation(img.player_climb_up,   14, 23, 0.12, 4)
	self.animClimbDown = newAnimation(img.player_climb_down, 14, 23, 0.12, 4)
	self.anim = self.animRun
	self.waterFrame = 0
	
	return self
end

--- Updates the player
-- Called once once each love.update
-- @param dt Time passed since last update
function Player:update(dt)
	self.shooting = false

	-- RUNNING STATE
	if self.state == PL_RUN then
		self:updateRunning(dt)
	elseif self.state == PL_CLIMB then
		self:updateClimbing(dt)
	end

	-- Update animations
	self.anim:update(dt)
	self.waterFrame = self.waterFrame + dt*10
end

--- Called each update if current state is PL_RUN
-- @param dt Time passed since laste update
function Player:updateRunning(dt)
	local changedDir = false -- true if player changed horizontal direction
	-- Handle input
	if love.keyboard.isDown("d")  then
		self.xspeed = self.xspeed + RUN_SPEED*dt

		if self.dir == -1 then
			self.dir = 1
			changedDir = true
		end

		if self.xspeed > MAX_SPEED then self.xspeed = MAX_SPEED end

	elseif love.keyboard.isDown("a") then
		self.xspeed = self.xspeed - RUN_SPEED*dt

		if self.dir == 1 then
			self.dir = -1
			changedDir = true
		end

		if self.xspeed < -MAX_SPEED then self.xspeed = -MAX_SPEED end
	end

	-- Cap speeds
	if self.xspeed < 0 then
		self.xspeed = self.xspeed + math.max(dt*BRAKE_SPEED, self.xspeed)
	elseif self.xspeed > 0 then
		self.xspeed = self.xspeed - math.min(dt*BRAKE_SPEED, self.xspeed)
	end

	-- Update gravity
	self.yspeed = self.yspeed + GRAVITY*dt
	-- Move in x axis
	self:moveX(self.xspeed*dt)
	-- Move in y axis
	self:moveY(self.yspeed*dt)

	-- Find gundirection
	local old_gundir = self.gundir
	self.gundir = 2
	if love.keyboard.isDown("w") then
		self.gundir = 0
	elseif love.keyboard.isDown("s") then
		self.gundir = 4
	end
	if self.gundir ~= old_gundir or changedDir and self.gundir == 2 then
		self.streamLength = 0
	end

	-- Update stream length and collide it with entities/walls
	self:updateStream(dt)

	-- Set animation speeds
	self.anim:setSpeed(math.abs(self.xspeed)/MAX_SPEED)
end

--- Updates the water stream
-- Updates the length of the water stream
-- and performs collision with walls and other entities
function Player:updateStream(dt)
	-- Shoot
	if love.keyboard.isDown("j") then
		self.shooting = true
		self.streamLength = math.min(self.streamLength + STREAM_SPEED*dt, MAX_STREAM)
	else
		self.shooting = false
		self.streamLength = 0
		return
	end

	-- Collide with walls
	local span = math.ceil((self.streamLength+12)/16)
	local cx = math.floor(self.x/16)
	local cy = math.floor((self.y-6)/16)
	self.streamCollided = false

	if self.gundir == 0 then -- up
		for i = 1,span do
			cy = cy - 1
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy)
				self.streamLength = self.y-(cy+1)*16-20
				self.streamCollided = true
				break
			end
		end
	elseif self.gundir == 4 then -- down
		for i = 1,span do
			cy = cy + 1
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy)
				self.streamLength = cy*16-self.y-2
				self.streamCollided = true
				break
			end
		end
	elseif self.gundir == 2 then -- horizontal
		--cx = cx - self.dir
		for i = 1,span do
			cx = cx + self.dir
			if map:collideCell(cx,cy) == true then
				map:hitCell(cx,cy)
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
	if self.gundir == 0 then -- up
		sbox = {x = self.x-4.5, y = self.y-15-self.streamLength, w = 9, h = self.streamLength}
	elseif self.gundir == 2 then -- horizontal
		if self.dir == -1 then
			sbox = {x = self.x-8-self.streamLength, y = self.y-10, w = self.streamLength, h = 9}
		else
			sbox = {x = self.x+8, y = self.y-10, w = self.streamLength, h = 9}
		end
	elseif self.gundir == 4 then -- down
		sbox = {x = self.x-4.5, y = self.y+1, w = 9, h = self.streamLength}
	end
	-- Collide with entities
	for i,v in ipairs(map.objects) do
		if v:collide(sbox) then
			v:shot(self.dir)
		end
	end
end

--- Called each update if the current state is PL_CLIMB
-- @param dt Time passed since last update
function Player:updateClimbing(dt)
	local oldy = self.y
	-- Move up and down ladder
	local animSpeed = 0
	if love.keyboard.isDown("s") then
		self.y = self.y + CLIMB_SPEED*dt
		self.anim = self.animClimbDown
		animSpeed = 1
	end
	if love.keyboard.isDown("w") then
		self.y = self.y - CLIMB_SPEED*dt
		self.anim = self.animClimbUp
		animSpeed = 1
	end
	self.anim:setSpeed(animSpeed)

	-- Check if player has moved off ladder
	local idBottom = map:getPointId(self.x, self.y)
	local idMid = map:getPointId(self.x, self.y-11)
	local idTop = map:getPointId(self.x, self.y-22)
	if idBottom == 2 then
		self.y = oldy
		self:setState(PL_RUN)
	elseif idBottom ~= 5 and idBottom ~= 137 and idBottom ~= 153 then
		self:setState(PL_RUN)
	end

	-- Check if player tries to move to a side
	if love.keyboard.isDown("a","d"," ") then
		if idBottom ~= 5 and idMid ~= 5 and idTop ~= 5 then
			self:setState(PL_RUN)
		end
	end
end

function Player:keypressed(k)
	if k == " " then
		self:jump()
	elseif k == "k" and self.state == PL_RUN then
		self:climb()
	end
end

--- Changes the current state and resets current animation
function Player:setState(state)
	if state == PL_RUN then
		self.state = PL_RUN
		self.anim = self.animRun
		self.xspeed, self.yspeed = 0, 0

	elseif state == PL_CLIMB then
		self.state = PL_CLIMB
		self.anim = self.animClimbDown
		self.yspeed = 0
		self.x = math.floor(self.x/16)*16+8
	end

	self.anim:reset()
end

function Player:jump()
	if self.onGround == true then
		self.yspeed = -JUMP_POWER
	end
end

function Player:climb()
	if self.gundir == 0 or self.gundir == 4 then -- UP
		local below = map:getPointId(self.x, self.y+1)
		local top    = map:getPointId(self.x, self.y-22)
		if below == 5 or below == 137 or below == 153
		or top == 5 or top == 137 or top == 153 then
			self:setState(PL_CLIMB)
		end
	end
end

function Player:moveX(dist)
	if self.xspeed == 0 then return end

	local collision = false
	self.x = self.x + dist
	
	-- Collide with solid tiles
	for i=1,#COL_OFFSETS do
		if map:collidePoint(self.x+COL_OFFSETS[i][1], self.y+COL_OFFSETS[i][2]) then
			collision = true
			local cx = math.floor((self.x+COL_OFFSETS[i][1])/16)*16
			if self.xspeed > 0 then
				self.x = cx-5.0001
			else
				self.x = cx+22
			end
		end
	end

	-- Collide with solid objects
	for i,v in ipairs(map.objects) do
		if v.solid == true then
			if self:collideBox(v:getBBox()) then
				collision = true
				local bbox = v:getBBox()
				if self.xspeed > 0 then
					self.x = bbox.x-5.0001
				else
					self.x = bbox.x+bbox.w+6
				end
			end
		end
	end

	-- Bounce off walls if collision
	if collision == true then
		self.xspeed = -1.0*self.xspeed
	end
end

function Player:moveY(dist)
	self.onGround = false
	if self.yspeed == 0 then return end

	local collision = false
	self.y = self.y + dist

	for i=1,#COL_OFFSETS do
		if map:collidePoint(self.x+COL_OFFSETS[i][1], self.y+COL_OFFSETS[i][2]) then
			collision = true
			local cy = math.floor((self.y+COL_OFFSETS[i][2])/16)*16
			if self.yspeed > 0 then
				self.y = cy
				self.onGround = true
			else
				self.y = cy+38
			end
		end
	end

	if collision == true then
		self.yspeed = 0
	end
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

	if self.state == PL_RUN then
		-- Draw player
		if self.onGround == false then
			love.graphics.drawq(img.player_running, quad.player_jump, self.flx, self.fly, 0, self.dir, 1, 7, 22)
		elseif math.abs(self.xspeed) < 30 then
			love.graphics.drawq(img.player_running, quad.player_idle, self.flx, self.fly, 0, self.dir, 1, 7, 22)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 7, 22)
		end

		-- Draw gun
		love.graphics.drawq(img.player_gun, quad.player_gun[self.gundir], self.flx, self.fly-16, 0, self.dir, 1, 3, 0)

		-- Draw water
		if self.shooting == true then
			self:drawWater()
		end

	elseif self.state == PL_CLIMB then
		self.anim:draw(self.flx, self.fly, 0, 1,1, 7, 22)
	end
end

function Player:drawWater()
	local quadx = 8-math.floor((self.waterFrame*8)%8)
	local wquad = love.graphics.newQuad(quadx, 0, math.floor(self.streamLength), 9, 16,16)
	local frame = math.floor(self.waterFrame%2)

	if self.gundir == 0 then -- up
		love.graphics.drawq(img.stream, wquad, self.flx, self.fly, -math.pi/2, 1, self.dir, -19, 4)
		if self.streamCollided == false then
			love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly-20-math.floor(self.streamLength), -math.pi/2, 1,1, 8, 7.5)
		else
			love.graphics.drawq(img.water, quad.water_hit[frame], self.flx+self.dir*0.5, self.fly-13-math.floor(self.streamLength), -math.pi/2, 1,1, 8, 9.5)
		end
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly-16, -math.pi/2, 1,1, 0,7.5)

	elseif self.gundir == 2 then -- horizontal
		love.graphics.drawq(img.stream, wquad, self.flx+self.dir*12, self.fly-10, 0, self.dir, 1)
		if self.streamCollided == false then
			love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*(12+math.floor(self.streamLength)), self.fly-5, 0, self.dir,1, 7.5, 8)
		else
			love.graphics.drawq(img.water, quad.water_hit[frame], self.flx+self.dir*(6.5+math.floor(self.streamLength))-1, self.fly-8, 0, self.dir,1, 9.5, 8)
		end
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx, self.fly, 0, self.dir,1, -9,13)
	
	elseif self.gundir == 4 then -- down
		love.graphics.drawq(img.stream, wquad, self.flx, self.fly, -math.pi/2, -1, self.dir, -5, 4)
		if self.streamCollided == false then
			love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly+math.floor(self.streamLength), math.pi/2, 1,1, 5, 7.5)
		else
			love.graphics.drawq(img.water, quad.water_hit[frame], self.flx+self.dir*0.5, self.fly+math.floor(self.streamLength), math.pi/2, 1,1, 11, 9.5)
		end
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly+2, math.pi/2, 1,1, 0,7.5)
	end
end
