Human = {}
Human.__index = Human

local MOVE_SPEED = 60
local THROW_SPEED = 250
local NUM_HUMANS = 4
local GRAVITY = 350
local COL_OFFSETS = {{-5,-0.9001}, {5,-0.9001}, {-5,-18}, {5,-18}} -- Collision point offsets

local HS_WALK, HS_CARRIED, HS_FLY = 0,1,2

function Human.create(x,y,id)
	local self = setmetatable({}, Human)

	self.alive = true
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.dir = 1
	self.id = id or math.random(1, NUM_HUMANS)

	self.state = HS_WALK

	self.animRun = newAnimation(img.human_run[self.id], 20,32, 0.22, 4)
	self.anim = self.animRun

	return self
end

function Human:update(dt)
	-- Walking state
	if self.state == HS_WALK then
		self.xspeed = self.dir*MOVE_SPEED
		self.yspeed = self.yspeed + GRAVITY*dt

		if self:moveX(self.xspeed*dt) == true then
			self.dir = self.dir*-1
		end
		if self:moveY(self.yspeed*dt) == true then
			self.yspeed = 0 
		end

	elseif self.state == HS_FLY then
		if self.xspeed < 0 then
			self.xspeed = self.xspeed + dt*150
		elseif self.xspeed > 0 then
			self.xspeed = self.xspeed - dt*150
		end
		self.yspeed = self.yspeed + GRAVITY*dt

		if self:moveX(self.xspeed*dt) == true then
			self.xspeed = self.xspeed*-0.6
		end
		if self:moveY(self.yspeed*dt) == true then
			self.yspeed = self.yspeed*-0.6
		end
		if math.abs(self.xspeed) < 10 then
			self.state = HS_WALK
		end
	end

	self.anim:update(dt)
end

function Human:moveX(dist)
	if self.xspeed == 0 then return end

	local collision = false
	self.x = self.x + dist

	self:collideWindows()
	
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
					self.x = bbox.x+bbox.w+5
				end
			end
		end
	end
	
	return collision
end

function Human:moveY(dist)
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

	return collision
end

function Human:collideWindows()
	for i=1,2 do
		local cx = math.floor((self.x+COL_OFFSETS[i][1])/16)
		local cy = math.floor((self.y+COL_OFFSETS[i][2])/16)
		local tile = map:getPoint(self.x+COL_OFFSETS[i][1], self.y+COL_OFFSETS[i][2])
		if tile == 38 or tile == 39 then
			map:hitCell(cx,cy,math.sign(self.xspeed))
		end
	end
end

function Human:throw(x,y,dir)
	self.state = HS_FLY
	self.x = x
	self.y = y
	self.xspeed = THROW_SPEED*dir
	self.yspeed = -100
	self.dir = dir
end

function Human:grab()
	self.state = HS_CARRIED
end

function Human:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == HS_WALK then
		self.anim:draw(self.flx, self.fly, 0,self.dir,1, 10, 32)
	elseif self.state == HS_FLY then
		if math.abs(self.xspeed) > 50 then
			if self.yspeed > -20 then
				love.graphics.drawq(img.human_fly[self.id], quad.human_fly[0], self.flx, self.fly, 0, self.dir,1, 10, 32)
			else
				love.graphics.drawq(img.human_fly[self.id], quad.human_fly[1], self.flx, self.fly, 0, self.dir,1, 10, 32)
			end
		else
			love.graphics.drawq(img.human_fly[self.id], quad.human_fly[2], self.flx, self.fly, 0, self.dir,1, 10, 32)
		end
	end
end

function Human:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-18 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function Human:getBBox()
	return {x = self.x-5, y = self.y-18, w = 10, h = 18}
end
