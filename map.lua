Map = {}
Map.__index = Map

local lg = love.graphics

local floor_files = {
	"1-1-1.lua",
	"1-2.lua",
	"2-1.lua",
	"2-2.lua"
}

function Map.create()
	local self = setmetatable({}, Map)

	local file = love.filesystem.load("maps/base.lua")()

	for i,v in ipairs(file.layers) do
		if v.name == "main" then
			self.data = v.data
			break
		end
	end
	self.width = file.width
	self.height = file.height

	self.batch = lg.newSpriteBatch(img.tiles, 256)
	self.redraw = true

	self.viewX, self.viewY, self.viewW, self.viewH = 0,0,0,0

	self.objects = {}
	self.particles = {}
	self.enemies = {}
	self.humans = {}

	for i=1,3 do
		self:addFloor(i)
	end

	self.background = table.random(BACKGROUND_FILES)

	table.insert(self.humans, Human.create(80,80,1))

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

	-- Update enemies
	for i=#self.enemies,1,-1 do
		if self.enemies[i].alive == false then
			table.remove(self.objects, i)
		else
			self.enemies[i]:update(dt)
		end
	end

	-- Update humans
	for i=#self.humans,1,-1 do
		if self.humans[i].alive == false then
			table.remove(self.humans, i)
		else
			self.humans[i]:update(dt)
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
	-- Draw background
	local xin = translate_x/(MAPW-WIDTH)
	local yin = translate_y/(MAPH-HEIGHT)
	lg.draw(img[self.background], translate_x-xin*(512-WIDTH), translate_y-yin*(256-HEIGHT))

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

	-- Draw entities, enemies and particles
	for i,v in ipairs(self.objects) do
		v:draw()
	end

	for i,v in ipairs(self.humans) do
		v:draw()
	end

	for i,v in ipairs(self.enemies) do
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
	local yoffset = 5*(floor-1) -- 0, 5 or 10

	local file = love.filesystem.load("maps/floors/"..table.random(floor_files))()
	for i,v in ipairs(file.layers) do
		-- Load tiles
		if v.name == "main" then
			for iy = 0,file.height-1 do
				for ix = 0,file.width-1 do
					local tile = v.data[iy*file.width+ix+1]
					self:set(ix,iy+yoffset, tile)
				end
			end

		-- Load objects
		elseif v.name == "objects" then
			for j,o in ipairs(v.objects) do
				if o.type == "door" then
					table.insert(self.objects, Door.create(o.x, o.y+yoffset*16, o.properties.dir))
				end
			end
		end
	end
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

function Map:getWidth()
	return self.width
end

function Map:getHeight()
	return self.height
end
