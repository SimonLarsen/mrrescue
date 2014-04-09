Fire = { max_health = 0.4 }
Fire.__index = Fire

local REGEN_RATE = 0.05
local SCORE = 20

function Fire.create(x,y,map,health)
	local self = setmetatable({}, Fire)

	self.alive = true
	self.health = health or Fire.max_health/4
	self.cx, self.cy = x,y
	self.x, self.y = x*16, y*16
	self.frame = math.random()*5
	self.flframe = 0
	self.MIN_SPREAD_WAIT = math.round(8 - map.section*(6/LAST_SECTION))
	self.MAX_SPREAD_WAIT = math.round(14 - map.section*(10/LAST_SECTION))
	self.nextSpread = math.random(self.MIN_SPREAD_WAIT, self.MAX_SPREAD_WAIT)
	self.bbox = {x=self.x+4, y=self.y+4, w=8, h=8}

	self.ceiling = map:collideCell(self.cx, self.cy-1)
	self.ground = map:collideCell(self.cx, self.cy+1)

	return self
end

function Fire:update(dt)
	if self.health < Fire.max_health then
		self.health = math.min(self.health+dt*REGEN_RATE, Fire.max_health)
	else
		self.nextSpread = self.nextSpread - dt
	end

	if self.nextSpread <= 0 then
		self.nextSpread = math.random(self.MIN_SPREAD_WAIT, self.MAX_SPREAD_WAIT)
		local cx,cy = self.cx, self.cy
		while (cx == self.cx and cy == self.cy) do
			if math.random(0,1) == 0 then -- vertically
				if math.random(0,1) == 0 then -- up
					cx, cy = self.cx, self.cy-1
					if cy > 0 and map:canBurnCell(cx,cy) == false and math.random(0,4) == 0 then
						cy = cy-1 -- burn through ceiling
					end
				else
					cx, cy = self.cx, self.cy+1 -- down
					if cy < 14 and map:canBurnCell(cx,cy) == false and math.random(0,4) == 0 then
						cy = cy+1 -- burn through floor
					end
				end
			else
				if math.random(0,1) == 0 then -- horizontally
					cx, cy = self.cx-1, self.cy -- left
				else
					cx, cy = self.cx+1, self.cy -- right
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
		score = score + SCORE
		stats[1] = stats[1] + 1
		playSound("pss")
	end
end

function Fire:drawFront()
	if self.ground == true then
		love.graphics.draw(img.fire_floor, quad.fire_floor[self.flframe%4], self.x, self.y+1)
	end
	if self.ceiling == true then
		love.graphics.draw(img.fire_floor, quad.fire_floor[self.flframe%4], self.x, self.y-1, 0,1,-1,0,16)
	end
end

function Fire:drawBack()
	self.flframe = math.floor(self.frame)
	if self.health < Fire.max_health/2 then
		love.graphics.draw(img.fire_wall_small, quad.fire_wall[self.flframe%5], self.x, self.y, 0,1,1,4,16)
	else
		love.graphics.draw(img.fire_wall, quad.fire_wall[self.flframe%5], self.x, self.y, 0,1,1,4,16)
	end
end

function Fire:collideBox(box)
	return collideBoxes(self.bbox,box)
end

function Fire:getBBox()
	return self.bbox
end
