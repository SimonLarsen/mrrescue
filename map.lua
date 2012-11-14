Map = {}
Map.__index = Map

local loader = require("atl/Loader")
loader.path = "maps/"

local floor_files = { "1-1-1.tmx", "1-2.tmx", "2-1.tmx", "2-2.tmx" }

function Map.create()
	local self = setmetatable({}, Map)
	
	self.data = loader.load("base.tmx")
	self.objects = {}
	self.particles = {}

	for i=1,3 do
		self:addFloor(i)
	end

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

function Map:draw()
	self.data:setDrawRange(translate_x, translate_y, WIDTH, HEIGHT)
	self.data:draw()

	for i,v in ipairs(self.objects) do
		v:draw()
	end

	for i,v in ipairs(self.particles) do
		v:draw()
	end
end

function Map:collidePoint(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)

	local tile = self.data("main"):get(cx,cy)
	if tile and tile.id < 128 then
		return true
	end
	return false
end

function Map:collideCell(cx,cy)
	local tile = self.data("main"):get(cx,cy)
	if tile and tile.id < 128 then
		return true
	end
	return false
end

--- Called when stream is stopped by cell
-- @param cx X coordinate of the cell
-- @param cy Y coordinate of the cell
function Map:hitCell(cx,cy,dir)
	local tile = self.data("main"):get(cx,cy)
	if tile then
		if tile.id == 38 or tile.id == 39 then
			self:destroyWindow(cx,cy-1,tile.id,dir)
		end
	end
end

function Map:destroyWindow(cx,cy,id,dir)
	if id == 38 then -- left window
		self.data("main"):set(cx,cy,   self.data.tiles[239])
		self.data("main"):set(cx,cy+1, self.data.tiles[255])
		table.insert(self.particles, Shards.create(cx*16+6, cy*16, dir))
	elseif id == 39 then -- right window
		self.data("main"):set(cx,cy,   self.data.tiles[240])
		self.data("main"):set(cx,cy+1, self.data.tiles[256])
		table.insert(self.particles, Shards.create(cx*16+10, cy*16, dir))
	end
	self.data:forceRedraw()
end

function Map:addFloor(floor)
	local yoffset = 5*(floor-1) -- either 0, 5 or 10

	local floor_data = loader.load("floors/"..floor_files[math.random(#floor_files)])

	for x,y,tile in floor_data("main"):iterate() do
		self.data("main"):set(x,y+yoffset,tile)
	end

	if floor_data("objects") then
		for i,v in pairs(floor_data("objects").objects) do
			if v.type == "door" then
				table.insert(self.objects, Door.create(v.x, v.y+yoffset*16, v.properties.dir))
			end
		end
	end
end

function Map:getId(x,y)
	return self.data("main"):get(x,y).id
end

function Map:getPointId(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)

	local tile = self.data("main"):get(cx,cy)
	return tile and tile.id
end
