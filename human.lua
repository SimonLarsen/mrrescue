Human = { MOVE_SPEED = 60 }
Human.__index = Human

function Human.create(x,y,id)
	local self = setmetatable({}, Human)

	self.alive = true
	self.x, self.y = x,y
	self.dir = 1
	self.id = id

	self.state = 1 -- 1 = walking, 2 = carried, 3 = flying

	self.animRun = newAnimation(img.human_1_run, 20,32, 0.22, 4)
	self.anim = self.animRun

	return self
end

function Human:update(dt)
	-- Walking state
	if self.state == 1 then
		local oldx = self.x
		self.x = self.x + self.dir*self.MOVE_SPEED*dt

		if map:collidePoint(self.x + self.dir*5, self.y - 9) == true then
			self.x = oldx
			self.dir = self.dir*-1
		end

		for i,v in ipairs(map.objects) do
			if self:collideBox(v:getBBox()) then
				self.x = oldx
				self.dir = self.dir*-1
			end
		end
	end

	self.anim:update(dt)
end

function Human:putDown(x,y)
	self.state = 1
	self.x, self.y = x,y
end

function Human:grab()
	self.state = 2
end

function Human:draw()
	self.flx = math.floor(self.x)
	self.fly = math.floor(self.y)

	if self.state == 1 then
		self.anim:draw(self.flx, self.fly, 0,self.dir,1, 10, 32)
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
