Player = {}
Player.__index = Player

local RUN_SPEED = 500
local MAX_SPEED = 160
local BRAKE_SPEED = 250
local GRAVITY = 350
local JUMP_POWER = 140

local COL_OFFSETS = {{-6,-0.0001}, {5,-0.0001}, {-6,-22}, {5,-22}} -- Collision point offsets

local animRun

function Player.create(x,y)
	local self = setmetatable({}, Player)

	animRun =  newAnimation(img.player_running, 15, 22, 0.12, 4)

	self.x = x
	self.y = y

	self.xspeed = 0
	self.yspeed = 0
	self.onGround = false

	self.dir = 1 -- -1 for left, 1 for right
	self.anim = animRun
	
	return self
end

function Player:update(dt)
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

	-- Update animations
	self.anim:setSpeed(math.abs(self.xspeed)/MAX_SPEED)
	self.anim:update(dt)
end

function Player:keypressed(k)
	if k == " " then
		self:jump()
	end
end

function Player:jump()
	if self.onGround == true then
		self.yspeed = -JUMP_POWER
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
	if math.abs(self.xspeed) < 30 then
		love.graphics.drawq(img.player_running, quad.player_idle, math.floor(self.x), math.floor(self.y), 0, self.dir, 1, 7, 22)
	else
		self.anim:draw(math.floor(self.x), math.floor(self.y), 0, self.dir, 1, 7, 22)
	end
end
