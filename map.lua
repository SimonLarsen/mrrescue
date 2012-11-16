Map = {}
Map.__index = Map

local lg = love.graphics

function Map.create()
	local self = setmetatable({}, Map)

	local file = dofile("maps/base.lua")

	self.data = file.layers[1].data
	self.width = file.width
	self.height = file.height

	self.batch = lg.newSpriteBatch(img.tiles, 256)
	self.redraw = true

	self.viewX, self.viewY, self.viewW, self.viewH = 0,0,0,0

	self.objects = {}
	self.particles = {}

	return self
end

function Map:update(dt)
	-- Update entities
	for i=#self.objects,1,-1 do
		if self.objects[i].alive == false then
			table.remove(self.objects, i)
		else
			self.objects[i]:update(dt)
		end
	end

	-- Update particles
	for i=#self.particles,1,-1 do
		if self.particles[i].alive == false then
			table.remove(self.particles, i)
		else
			self.particles[i]:update(dt)
		end
	end
end

function Map:setDrawRange(x,y,w,h)
	if x ~= self.viewX or y ~= self.viewY
	or w ~= self.viewW or h ~= self.viewH then
		self:forceRedraw()
	end

	self.viewX, self.viewY = x,y
	self.viewW, self.viewH = w,h
end

function Map:draw()
	-- Recreate sprite batch if redraw is set
	if self.redraw == true then
		self.batch:clear()

		local sx = math.floor(self.viewX/16)
		local sy = math.floor(self.viewY/16)
		local ex = sx+math.ceil(self.viewW/16)
		local ey = sy+math.ceil(self.viewH/16)

		for iy = sy, ex do
			for ix = sx, ex do
				local id = self:get(ix,iy)
				if id and id > 0 then
					self.batch:addq(quad.tile[self:get(ix,iy)], ix*16, iy*16)
				end
			end
		end

		self.redraw = false
	end

	-- Draw sprite batch
	lg.draw(self.batch, 0,0)

	-- Draw entities and particles
	for i,v in ipairs(self.objects) do
		v:draw()
	end

	for i,v in ipairs(self.particles) do
		v:draw()
	end
end

--- Forces the map to redraw sprite batch next frame
function Map:forceRedraw()
	self.redraw = true
end

function Map:addFloor(floor)
	return -- TODO IMPLEMENT
end

function Map:collidePoint(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)

	return self:collideCell(cx,cy)
end

function Map:collideCell(cx,cy)
	local tile = self:get(cx,cy)
	if tile and tile > 0 and tile < 128 then
		return true
	else
		return false
	end
end

--- Called when stream is stopped by cell
-- @param cx X coordinate of the cell
-- @param cy Y coordinate of the cell
function Map:hitCell(cx,cy,dir)
	local id = self:get(cx,cy)
	if id == 38 or id == 39 then
		self:destroyWindow(cx,cy-1,id,dir)
	end
end

--- Destroy a window and adds shards particle effect
--@param cx X-position of window
--@param cy Y-position of upper tile of window
--@param id ID of the tile that was hit triggered
--@param dir Direction of the water stream upon collision
function Map:destroyWindow(cx,cy,id,dir)
	if id == 38 then -- left window
		self:set(cx,cy,   239)
		self:set(cx,cy+1, 255)
		table.insert(self.particles, Shards.create(cx*16+6, cy*16, dir))
	elseif id == 39 then -- right window
		self:set(cx,cy,   240)
		self:set(cx,cy+1, 256)
		table.insert(self.particles, Shards.create(cx*16+10, cy*16, dir))
	end
	self:forceRedraw()
end

function Map:get(x,y)
	return self.data[y*self.width+x+1]
end

function Map:getPoint(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)
	return self:get(cx,cy)
end

function Map:set(x,y,val)
	self.data[y*self.width+x+1] = val
end
