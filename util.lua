--- Collides two AABBs
-- @param b1 First bounding box
-- @param b2 Second bounding box
-- @return True if they overlap
function collideBoxes(b1,b2)
	if b1.x > b2.x+b2.w or b1.x+b1.w < b2.x
	or b1.y > b2.y+b2.h or b1.y+b1.h < b2.y then
		return false
	else
		return true
	end
end

--- Returns a random entry in a table
function table.random(t)
	return t[math.random(#t)]
end

function math.sign(n)
	if n < 0 then
		return -1
	elseif n > 0 then
		return 1
	else
		return 0
	end
end

function math.round(x)
	return math.floor(x+0.5)
end

function collideX(self)
	if self.xspeed == 0 then return end

	local collision = false
	
	local last -- Last object collision detected

	for _, yoff in ipairs({self.corners[3], (self.corners[3]+self.corners[4])/2, self.corners[4]}) do
		for _, xoff in ipairs({self.corners[1], self.corners[2]}) do
			-- Collide with solid tiles
			if map:collidePoint(self.x+xoff, self.y+yoff) then
				collision = true
				local cx = math.floor((self.x+xoff)/16)*16
				if self.xspeed > 0 then
					self.x = cx-self.corners[2]-0.0001
				else
					self.x = cx+16-self.corners[1]
				end
			end
			-- Collide with objects
			for i,v in ipairs(map.objects) do
				if v.solid == true and self:collideBox(v:getBBox()) then
					collision = true
					last = v
					local bbox = v:getBBox()
					if self.xspeed > 0 then
						self.x = bbox.x-self.corners[2]-0.0001
					else
						self.x = bbox.x+bbox.w-self.corners[1]+0.0001
					end
				end
			end
		end
	end
	
	return collision, last
end

function collideY(self)
	if self.yspeed == 0 then return end
	self.onGround = false

	local collision = false

	for _, yoff in ipairs({self.corners[3], self.corners[4]}) do
		for _, xoff in ipairs({self.corners[1], self.corners[2]}) do
			-- Collide with solid tiles
			if map:collidePoint(self.x+xoff, self.y+yoff) then
				collision = true
				local cy = math.floor((self.y+yoff)/16)*16
				if self.yspeed > 0 then
					self.y = cy-self.corners[4]-0.0001
					self.onGround = true
				else
					self.y = cy+16-self.corners[3]
				end
			end
		end
	end

	return collision
end

function cap(val, min, max)
	return math.max(math.min(val, max), min)
end

function wrap(val, min, max)
	if val < min then val = max end
	if val > max then val = min end
	return val
end


function drawBox(x,y,w,h)
	lg.setColor(30,23,18)
	lg.rectangle("fill",x+1,y+1,w-2,h-2)
	lg.setColor(255,255,255)
	-- Draw sides
	lg.draw(img.menu_box, quad.box_left, x, y+1, 0, 1, (h-2))
	lg.draw(img.menu_box, quad.box_left, x+w, y+1, 0, -1, (h-2))
	lg.draw(img.menu_box, quad.box_top,  x+1, y, 0, (w-2), 1)
	lg.draw(img.menu_box, quad.box_top,  x+1, y+h, 0, (w-2), -1)
	-- Draw corners
	lg.draw(img.menu_box, quad.box_corner, x,y)
	lg.draw(img.menu_box, quad.box_corner, x+w,y, 0, -1, 1)
	lg.draw(img.menu_box, quad.box_corner, x,y+h, 0, 1, -1)
	lg.draw(img.menu_box, quad.box_corner, x+w,y+h, 0, -1, -1)
end

function secondsToString(time)
	local hours =   string.format("%02d", math.floor(time / 60^2))
	local minutes = string.format("%02d", math.floor((time % 60^2) / 60))
	local seconds = string.format("%02d", math.floor(time % 60))

	return hours .. ":" .. minutes .. ":" .. seconds
end
