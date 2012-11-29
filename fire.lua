Fire = {}
Fire.__index = Fire

local MIN_SPREAD_WAIT = 1
local MAX_SPREAD_WAIT = 20
local FIRE_HEALTH = 0.5
local REGEN_RATE = 0.05

function Fire.create(x,y,map)
	local self = setmetatable({}, Fire)

	self.alive = true
	self.health = FIRE_HEALTH
	self.cx, self.cy = x,y
	self.x, self.y = x*16, y*16
	self.frame = math.random()*5
	self.flframe = 0
	self.nextSpread = math.random(MIN_SPREAD_WAIT, MAX_SPREAD_WAIT)
	self.bbox = {x=self.x+4, y=self.y+4, w=8, h=8}

	self.ceiling = map:collideCell(self.cx, self.cy-1)
	self.ground = map:collideCell(self.cx, self.cy+1)

	return self
end

function Fire:update(dt)
	if self.health < FIRE_HEALTH then
		self.health = math.min(self.health+dt*REGEN_RATE, FIRE_HEALTH)
	end

	self.nextSpread = self.nextSpread - dt
	if self.nextSpread <= 0 then
		self.nextSpread = math.random(MIN_SPREAD_WAIT, MAX_SPREAD_WAIT)
		local cx,cy = self.cx, self.cy
		while (cx == self.cx and cy == self.cy) or map:canBurnCell(cx,cy) == false do
			if math.random(0,2) == 0 then -- spread upwards
				cx, cy = self.cx, self.cy-1
			else
				if math.random(0,1) == 0 then
					cx, cy = self.cx-1, self.cy
				else
					cx, cy = self.cx+1, self.cy
				end
			end
		end

		map:addFire(cx,cy)
	end

	self.frame = self.frame + 12*dt
end

function Fire:shot(dt,dir)
	self.health = self.health - dt
	if self.health < 0 then
		self.alive = false
	end
end

function Fire:drawFront()
	if self.ground == true then
		love.graphics.drawq(img.fire_floor, quad.fire_floor[self.flframe%4], self.x, self.y+1)
	end
	if self.ceiling == true then
		love.graphics.drawq(img.fire_floor, quad.fire_floor[self.flframe%4], self.x, self.y-1, 0,1,-1,0,16)
	end
end

function Fire:drawBack()
	self.flframe = math.floor(self.frame)
	if self.health < FIRE_HEALTH/2 then
		love.graphics.drawq(img.fire_wall_small, quad.fire_wall[self.flframe%5], self.x, self.y, 0,1,1,4,16)
	else
		love.graphics.drawq(img.fire_wall, quad.fire_wall[self.flframe%5], self.x, self.y, 0,1,1,4,16)
	end
end

function Fire:collideBox(box)
	return collideBoxes(self.bbox,box)
end

function Fire:getBBox()
	return self.bbox
end
