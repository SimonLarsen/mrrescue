Player = {}
Player.__index = Player

local RUN_SPEED = 500
local MAX_SPEED = 160
local BRAKE_SPEED = 250
local GRAVITY = 350
local JUMP_POWER = 130
local CLIMB_SPEED = 60
local STREAM_SPEED = 400

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

function Player:update(dt)
	self.shooting = false

	-- RUNNING STATE
	local changedDir = false -- true if player changed horizontal direction
	if self.state == PL_RUN then
		-- Handle input
		if love.keyboard.isDown("d") then
			self.xspeed = self.xspeed + RUN_SPEED*dt

			if self.dir == -1 then
				self.dir = 1
				changedDir = true
			end

			if self.xspeed > MAX_SPEED then self.xspeed = MAX_SPEED end
		end
		if love.keyboard.isDown("a") then
			self.xspeed = self.xspeed - RUN_SPEED*dt

			if self.dir == 1 then
				self.dir = -1
				changedDir = true
			end

			if self.xspeed < -MAX_SPEED then self.xspeed = -MAX_SPEED end
		end

		-- Shoot
		if love.keyboard.isDown("j") then
			self.shooting = true
			self.streamLength = self.streamLength + STREAM_SPEED*dt
		else
			self.shooting = false
			self.streamLength = 0
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

		-- Set animation speeds
		self.anim:setSpeed(math.abs(self.xspeed)/MAX_SPEED)

	-- CLIMBING STATE
	elseif self.state == PL_CLIMB then
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

	-- Update animations
	self.anim:update(dt)
	self.waterFrame = self.waterFrame + dt*10
end

function Player:keypressed(k)
	if k == " " then
		self:jump()
	elseif k == "j" and self.state == PL_RUN then
		self:shoot()
	elseif k == "k" and self.state == PL_RUN then
		self:climb()
	end
end

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

function Player:shoot()
	local waterdir = 0
	if self.gundir == 0 then -- straight up
		waterdir = math.pi/2
	elseif self.gundir == 4 then -- straight down
		waterdir = -math.pi/2
	elseif self.gundir == 1 then -- diagonally up
		if self.dir == 1 then waterdir = math.pi/4
		else waterdir = (3*math.pi)/4 end
	elseif self.gundir == 2 then -- forward
		if self.dir == -1 then waterdir = math.pi end
	else						 -- diagonally down
		if self.dir == 1 then waterdir = -math.pi/4
		else waterdir = -(3*math.pi)/4 end
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
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly-16, -math.pi/2, 1,1, 0,7.5)
		love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly-20-math.floor(self.streamLength), -math.pi/2, 1,1, 8, 7.5)

	elseif self.gundir == 2 then -- horizontal
		love.graphics.drawq(img.stream, wquad, self.flx+self.dir*12, self.fly-10, 0, self.dir, 1)
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx, self.fly, 0, self.dir,1, -9,13)
		love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*(12+math.floor(self.streamLength)), self.fly-5, 0, self.dir,1, 7.5, 8)
	
	elseif self.gundir == 4 then -- down
		love.graphics.drawq(img.stream, wquad, self.flx, self.fly, -math.pi/2, -1, self.dir, -5, 4)
		love.graphics.drawq(img.water, quad.water_out[frame], self.flx+self.dir*0.5, self.fly+2, math.pi/2, 1,1, 0,7.5)
		love.graphics.drawq(img.water, quad.water_end[frame], self.flx+self.dir*0.5, self.fly+math.floor(self.streamLength), math.pi/2, 1,1, 5, 7.5)
	end
end
