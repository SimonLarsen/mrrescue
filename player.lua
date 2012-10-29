Player = {}
Player.__index = Player

local RUN_SPEED = 500
local MAX_SPEED = 160
local BRAKE_SPEED = 250
local GRAVITY = 350
local JUMP_POWER = 130
local CLIMB_SPEED = 60

local COL_OFFSETS = {{-6,-0.0001}, {5,-0.0001}, {-6,-22}, {5,-22}} -- Collision point offsets

local PL_RUN, PL_CLIMB = 0,1

function Player.create(x,y)
	local self = setmetatable({}, Player)

	self.x, self.y = x, y

	self.xspeed = 0
	self.yspeed = 0
	self.onGround = false

	self.state = PL_RUN
	self.gundir = 2 -- gun direction

	self.water = {}

	self.dir = 1 -- -1 for left, 1 for right

	self.animRun =  newAnimation(img.player_running, 15, 22, 0.12, 4)
	self.animClimbUp   = newAnimation(img.player_climb_up,   14, 23, 0.12, 4)
	self.animClimbDown = newAnimation(img.player_climb_down, 14, 23, 0.12, 4)
	self.anim = self.animRun
	
	return self
end

function Player:update(dt)
	-- RUNNING STATE
	if self.state == PL_RUN then
		-- Handle input
		if love.keyboard.isDown("d") then
			self.xspeed = self.xspeed + RUN_SPEED*dt
			self.dir = 1

			if self.xspeed > MAX_SPEED then self.xspeed = MAX_SPEED end
		end
		if love.keyboard.isDown("a") then
			self.xspeed = self.xspeed - RUN_SPEED*dt
			self.dir = -1

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
		self.gundir = 2
		if love.keyboard.isDown("w") then
			if love.keyboard.isDown("a","d") then self.gundir = 1
			else self.gundir = 0 end
		elseif love.keyboard.isDown("s") then
			if love.keyboard.isDown("a","d") then self.gundir = 3
			else self.gundir = 4 end
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
		if idBottom == 2
		or idBottom ~= 5 and idBottom ~= 137 and idBottom ~= 153 then
			self.y = oldy
			self:setState(PL_RUN)
		end
	end

	-- Update animations
	self.anim:update(dt)


	-- Update water
	for i=#self.water,1,-1 do
		if self.water[i].alive == true then
			self.water[i]:update(dt)
		else
			table.remove(self.water, i)
		end
	end
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

	table.insert(self.water, Water.create(self.x+8*math.cos(waterdir), self.y-5-8*math.sin(waterdir), waterdir))
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

	if collision == true then
		self.xspeed = -0.6*self.xspeed
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

function Player:draw()
	-- Floor position
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == PL_RUN then
		-- Draw player
		if math.abs(self.xspeed) < 30 then
			love.graphics.drawq(img.player_running, quad.player_idle, self.flx, self.fly, 0, self.dir, 1, 7, 22)
		else
			self.anim:draw(self.flx, self.fly, 0, self.dir, 1, 7, 22)
		end

		-- Draw gun
		love.graphics.drawq(img.player_gun, quad.player_gun[self.gundir], self.flx, self.fly-16, 0, self.dir, 1, 3, 0)
	elseif self.state == PL_CLIMB then
		self.anim:draw(self.flx, self.fly, 0, 1,1, 7, 22)
	end

	-- Draw water (DEBUGGING)
	for i,v in ipairs(self.water) do
		v:draw()
	end
end
