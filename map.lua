Map = {}
Map.__index = Map

local loader = require("atl/Loader")
loader.path = "maps/"

local floor_files = {"2.tmx"}

function Map.create()
	local self = setmetatable({}, Map)
	
	self.data = loader.load("base.tmx")

	for i=1,3 do
		Map:addFloor(i)
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
	local floor_map = loader.load("floors/" .. floor_files[math.random(#floor_files)])
end
