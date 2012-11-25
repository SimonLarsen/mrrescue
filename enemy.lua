-- Normal enemy
NormalEnemy = { MOVE_SPEED = 100 }
NormalEnemy.__index = NormalEnemy

local EN_RUN, EN_HIT, EN_RECOVER = 0,1,2

function NormalEnemy.create(x,y)
	local self = setmetatable({}, NormalEnemy)

	self.alive = true
	self.hit = false -- true if hit since last update
	self.x = x
	self.y = y
	self.dir = 1
	self.health = 1.2
	self.state = EN_RUN

	self.animRun = newAnimation(img.enemy_normal_run, 16, 26, 0.12, 4)
	self.animHit = newAnimation(img.enemy_normal_hit, 16, 26, 0.12, 2)
	self.animRecover = newAnimation(img.enemy_normal_recover, 16, 26, 0.07, 4)

	self.anim = self.animRun

	return self
end

function NormalEnemy:update(dt)
	-- Normal state
	if self.state == EN_RUN then
		local oldx = self.x
		self.x = self.x + self.dir*self.MOVE_SPEED*dt
		
		if map:collidePoint(self.x + self.dir*7, self.y-13) == true then
			self.dir = self.dir*-1
		end
		
		for i,v in ipairs(map.objects) do
			if v.solid == true then
				if self:collideBox(v:getBBox()) then
					self.x = oldx
					self.dir = self.dir*-1
					break
				end
			end
		end
	-- Getting hit
	elseif self.state == EN_HIT then
		if self.hit == false then
			self.state = EN_RECOVER
			self.anim = self.animRecover
			self.recoverTime = 0.7
		end
	-- Recovering
	elseif self.state == EN_RECOVER then
		self.recoverTime = self.recoverTime - dt
		if self.recoverTime < 0 then
			self.state = EN_RUN
			self.anim = self.animRun
		end
	end

	self.hit = false

	self.anim:update(dt)
end

function NormalEnemy:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	self.anim:draw(self.flx, self.fly, 0, self.dir,1, 8, 26)
end

function NormalEnemy:collideBox(bbox)
	if self.x-5  > bbox.x+bbox.w or self.x+5 < bbox.x
	or self.y-15 > bbox.y+bbox.h or self.y   < bbox.y then
		return false
	else
		return true
	end
end

function NormalEnemy:shot(dt,dir)
	self.dir = -1*dir
	self.state = EN_HIT
	self.anim = self.animHit
	self.hit = true

	self.health = self.health - dt
	if self.health <= 0 then
		self.alive = false
	end
end

function NormalEnemy:getBBox()
	return {x = self.x-5, y = self.y-15, w = 10, y = 15}
end
