Map = {}
Map.__index = Map

local loader = require("atl/Loader")
loader.path = "maps/"

local floor_files = { "1-1-1.tmx", "1-2.tmx", "2-1.tmx", "2-2.tmx" }

function Map.create()
	local self = setmetatable({}, Map)
	
	self.data = loader.load("base.tmx")

	for i=1,3 do
		self:addFloor(i)
	end

	return self
end

function Map:draw()
	self.data:draw()
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

function Map:addFloor(floor)
	local yoffset = 5*(floor-1) -- either 0, 5 or 10

	local floor_data = loader.load("floors/"..floor_files[math.random(#floor_files)])

	for x,y,tile in floor_data("main"):iterate() do
		self.data("main"):set(x,y+yoffset,tile)
	end
end

function Map:getId(x,y)
	return self.data("main"):get(x,y).id
end

function Map:getPointId(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)

	return self.data("main"):get(cx,cy).id
end
