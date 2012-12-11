Human = { corners = {-5, 5, -18, -0.5} }
Human.__index = Human

local MOVE_SPEED = 50
local RUN_SPEED = 100
local THROW_SPEED = 250
local PUSH_SPEED  = 100
local NUM_HUMANS = 4
local GRAVITY = 350
local COL_OFFSETS = {{-5,-0.9001}, {5,-0.9001}, {-5,-18}, {5,-18}} -- Collision point offsets

HS_WALK, HS_CARRIED, HS_FLY, HS_BURN = 0,1,2,3

function Human.create(x,y,id)
	local self = setmetatable({}, Human)

	self.alive = true
	self.x, self.y = x,y
	self.xspeed, self.yspeed = 0,0
	self.dir = 1
	self.id = id or math.random(1, NUM_HUMANS)

	self.state = HS_WALK

	self.anims = {}
	self.anims[HS_WALK] = newAnimation(img.human_run[self.id], 20,32, 0.22, 4)
	self.anims[HS_BURN] = newAnimation(img.human_burn[self.id], 20, 32, 0.10, 4)
	self.anims[HS_FLY]  = newAnimation(img.human_fly[self.id], 20, 32, 0, 4)

	self.anim = self.anims[self.state]

	return self
end

function Human:update(dt)
	-- Walking state
	if self.state == HS_WALK then
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

		for j,w in pairs(map.fire) do
			for i,v in pairs(w) do
				if self:collideBox(v:getBBox()) == true then
					self:setState(HS_BURN)
				end
			end
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
				last:shot(0.1, self.dir)
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

	if self.anim then
		self.anim:update(dt)
	end
end

function Human:setState(state)
	self.state = state
	self.anim = self.anims[self.state]
end

function Human:shot(dt,dir)
	if self.state == HS_BURN then
		self:setState(HS_WALK)
	end

	if self.state == HS_BURN or self.state == HS_WALK then
		self:push(self.x, self.y, dir)
	end
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
	self:setState(HS_FLY)
	self.x = x
	self.y = y
	self.xspeed = THROW_SPEED*dir
	self.yspeed = -100
	self.dir = dir
	self.buttHit = 0
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

	if self.state == HS_WALK or self.state == HS_BURN then
		self.anim:draw(self.flx, self.fly, 0,self.dir,1, 10, 32)
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
	or self.y-18 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function Human:getBBox()
	return {x = self.x-5, y = self.y-18, w = 10, h = 18}
end
