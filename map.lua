Map = {}
Map.__index = Map

LAST_SECTION = 26

MT_NORMAL, MT_BOSS = 0,1

local lg = love.graphics

local floor_files = {
	"1-1-1.lua",
	"1-2.lua",
	"2-1.lua",
	"2-2.lua"
}

function Map.create(section, level)
	local self = setmetatable({}, Map)

	-- Load base file
	local file
	if (level == 1 and section == 8)
	or (level == 2 and section == 11)
	or (level == 3 and section == 15) then
		self.type = MT_BOSS
	else
		self.type = MT_NORMAL
	end

	if self.type == MT_NORMAL then
		file = love.filesystem.load("maps/base.lua")()
	else
		file = love.filesystem.load("maps/top_base.lua")()
	end

	for i,v in ipairs(file.layers) do
		if v.name == "main" then
			self.data = v.data
			break
		end
	end
	self.width = file.width
	self.height = file.height
	self.section = section + (level-1)*5

	self.front_batch = lg.newSpriteBatch(img.tiles, 256)
	self.back_batch  = lg.newSpriteBatch(img.tiles, 256)
	self.redraw = true

	self.viewX, self.viewY, self.viewW, self.viewH = 0,0,0,0

	self.objects = {}
	self.particles = {}
	self.enemies = {}
	self.humans = {}
	self.items = {}
	self.fire = {}
	for ix = 0,self.width-1 do
		self.fire[ix] = {}
	end

	self.background = img.night

	if self.type == MT_NORMAL then
		self.minenemy = 1
		self.maxenemy = 1

		-- easy:   section 1  - 8
		-- medium: section 6  - 16
		-- hard:   section 11 - 25
		if self.section >= 20 then
			self.maxenemy = 7 -- Allow Thief
			self.minenemy = 4 -- Disallow Volcano
		elseif self.section >= 14 then
			self.maxenemy = 6 -- Allow Angry Volcano
			self.minenemy = 3 -- Disallow Jumper
		elseif self.section >= 10 then
			self.maxenemy = 5 -- Allow Angry Jumper
			self.minenemy = 2 -- Disallow Normal
		elseif self.section >= 8 then
			self.maxenemy = 4 -- Allow Angry Normal
		elseif self.section >= 4 then
			self.maxenemy = 3 -- Allow Volcano
		elseif self.section >= 2 then
			self.maxenemy = 2 -- allow Jumper
		end
		self:populate()
	else
		self.startx = 280
		self.starty = 240
		if level == 1 then
			self.boss = MagmaHulk.create((self.width*16)/2, MAPH-16)
		elseif level == 2 then
			self.boss = GasLeak.create(368, MAPH-16)
		else
			self.boss = Charcoal.create(368, MAPH-16)
		end
		table.insert(self.items, Item.create(16*16, 8*16, "coolant"))
		table.insert(self.items, Item.create(24*16, 10*16, "coolant"))
	end

	return self
end

function Map:populate()
	self.rooms = {}
	self.starts = {}

	for i=1,3 do
		self:addFloor(i)
	end

	local start = table.random(self.starts)
	self.startx = start.x + 8
	self.starty = start.y + 176

	-- Add coolants
	for i=1,2 do
		local roomindex = math.random(#self.rooms)
		local room = self.rooms[roomindex]
		local pos = table.random(room.objects)

		table.insert(self.items, Item.create(room.x+pos.x, pos.y+room.y, "coolant"))
		table.remove(self.rooms, roomindex)
	end

	-- Add powerup
	local roomindex = math.random(#self.rooms)
	local room = self.rooms[roomindex]
	local pos = table.random(room.objects)

	table.insert(self.items, Item.create(room.x+pos.x, room.y+pos.y, table.random(ITEM_IDS)))
	table.remove(self.rooms, roomindex)

	self.rooms = nil
	self.starts = nil
end

--- Updates all entities in the map and recreates
--  sprite batches if necessary
--  @param dt Time since last update in seconds
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
			table.remove(self.enemies, i)
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

	-- Update items
	for i=#self.items,1,-1 do
		if self.items[i].alive == false then
			table.remove(self.items, i)
		else
			self.items[i]:update(dt)
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

	-- Update fire
	for ix=0,self.width-1 do
		for iy=self.height-1,0,-1 do
			if self.fire[ix][iy] then
				if self.fire[ix][iy].alive == false then
					self.fire[ix][iy] = nil
					self:addParticle(BlackSmoke.create(ix*16+8,iy*16+8))
				else
					self.fire[ix][iy]:update(dt)
				end
			end
		end
	end

	-- Update boss if any
	if self.type == MT_BOSS then
		self.boss:update(dt)
	end
end

function Map:clearFire()
	for iy=0,self.height-1 do
		for ix=0,self.width-1 do
			if self.fire[ix][iy] then
				self.fire[ix][iy].alive = false
			end
		end
	end
end

function Map:clearEnemies()
	for i,v in ipairs(self.enemies) do
		v:shot(120, 1)
	end
end

function Map:recreateSpriteBatches()
	-- Recreate sprite batches if redraw is set
	if self.redraw == true then
		self:fillBatch(self.back_batch,  function(id) return id > 60 end)
		self:fillBatch(self.front_batch, function(id) return id <= 60 end)
		self.redraw = false
	end
	
end

--- Adds a fire block if possible
function Map:addFire(x,y,health)
	if self:canBurnCell(x,y) == false or x < 3 or x > 37 then
		return nil
	end

	if self.fire[x][y] == nil then
		self.fire[x][y] = Fire.create(x,y,self,health)
		return self.fire[x][y]
	end
end

--- Checks if a tile is on fire
function Map:hasFire(x,y)
	return self.fire[x] and self.fire[x][y] ~= nil
end

function Map:getFire(x,y)
	return self.fire[x] and self.fire[x][y]
end

--- Sets the drawing range for the map
-- @param x X coordinate of upper left corner
-- @param y Y coordinate of upper left corner
-- @param w Width of screen
-- @param h Height of screen
function Map:setDrawRange(x,y,w,h)
	if x ~= self.viewX or y ~= self.viewY
	or w ~= self.viewW or h ~= self.viewH then
		self:forceRedraw()
	end

	self.viewX, self.viewY = x,y
	self.viewW, self.viewH = w,h

	-- Recreate sprite batches
	self:recreateSpriteBatches()
end

--- Draws the background layer of the map.
--  Includes background tiles, humans and enemies
function Map:drawBack()
	-- Draw background
	local xin = translate_x/(MAPW-WIDTH)
	local yin = translate_y/(MAPH-HEIGHT)
	if translate_y < 0 then
		lg.draw(self.background, translate_x-xin*(512-WIDTH), math.floor(translate_y))
	else
		lg.draw(self.background, translate_x-xin*(512-WIDTH), translate_y-yin*(228-HEIGHT))
	end

	-- Draw back tiles
	lg.draw(self.back_batch, 0,0)

	-- Draw fire
	for iy=0,self.height-1 do
		for ix=0,self.width-1 do
			if self.fire[ix][iy] then
				self.fire[ix][iy]:drawBack()
			end
		end
	end

	-- Draw front tiles
	lg.draw(self.front_batch, 0,0)

	-- Draw entities, enemies and particles
	for i,v in ipairs(self.humans) do
		v:draw()
	end
	if self.type == MT_BOSS then
		self.boss:draw()
	end
	for i,v in ipairs(self.enemies) do
		v:draw()
	end
end

--- Draws the foreground layer of the map.
--  Includes everything in front of the player
--  like particles, objects and front tiles.
function Map:drawFront()
	-- Draw objects and particles
	for i,v in ipairs(self.objects) do
		v:draw() end
	for i,v in ipairs(self.items) do
		v:draw() end
	for i,v in ipairs(self.particles) do
		v:draw() end
	
	-- Draw front fire
	for iy=0,self.height-1 do
		for ix=0,self.width-1 do
			if self.fire[ix][iy] then
				self.fire[ix][iy]:drawFront()
			end
		end
	end
end

--- Fills a given sprite batch with all tiles
--  that pass a given test.
--  @param batch Sprite batch to fill
--  @param test Function on the id of a tile. Must return true or false.
function Map:fillBatch(batch, test)
	batch:clear()
	local sx = math.floor(self.viewX/16)
	local sy = math.floor(self.viewY/16)
	local ex = sx+math.ceil(self.viewW/16)
	local ey = sy+math.ceil(self.viewH/16)

	for iy = sy, ex do
		for ix = sx, ex do
			local id = self:get(ix,iy)
			if id and id > 0 and test(id) == true then
				batch:add(quad.tile[self:get(ix,iy)], ix*16, iy*16)
			end
		end
	end
end

function Map:drawFireLight()
	local sx = math.floor(self.viewX/16)-2
	local sy = math.floor(self.viewY/16)-2
	local ex = sx+math.ceil(self.viewW/16)+2
	local ey = sy+math.ceil(self.viewH/16)+2

	for iy = sy, ex do
		for ix = sx, ex do
			if self.fire[ix] and self.fire[ix][iy] then
				local inst = self.fire[ix][iy]
				lg.draw(img.light_fire, quad.light_fire[inst.flframe%5], inst.x-34, inst.y-42)
			end
		end
	end
end

--- Forces the map to redraw sprite batch next frame
function Map:forceRedraw()
	self.redraw = true
end

--- Adds rooms to a floor
-- @param floor Floor to fill. Value between 1 and 3.
function Map:addFloor(floor)
	local yoffset = 5*(floor-1) -- 0, 5 or 10

	local file = love.filesystem.load("maps/floors/"..table.random(floor_files))()
	-- Load tiles
	for i,v in ipairs(file.layers) do
		if v.name == "main" then
			for iy = 0,file.height-1 do
				for ix = 3,file.width-4 do
					local tile = v.data[iy*file.width+ix+1]
					self:set(ix,iy+yoffset, tile)
				end
			end
		end
	end
	-- Load objects
	for i,v in ipairs(file.layers) do
		if v.name == "objects" then
			for j,o in ipairs(v.objects) do
				if o.type == "door" then
					table.insert(self.objects, Door.create(o.x, o.y+yoffset*16, o.properties.dir))
				elseif o.type == "room" then
					o.y = o.y+yoffset*16
					table.insert(self.rooms, o)
					self:addRoom(o.x/16, o.y/16, o.width/16, o)
				elseif o.type == "start" and floor == 3 then
					table.insert(self.starts, o)
				end
			end
		end
	end
end

--- Fills the inside of a room with the contents of a room file.
-- @param x X position of room in tiles
-- @param y Y position of room in tiles
-- @param width Width of room in tiles
function Map:addRoom(x,y,width,room)
	local file = love.filesystem.load("maps/room/"..width.."/"..math.random(NUM_ROOMS[width])..".lua")()
	for i,v in ipairs(file.layers) do
		if v.name == "main" then
			for iy = 0,file.height-1 do
				for ix = 0,file.width-1 do
					if self:collideCell(x+ix, y+iy) == false then
						local tile = v.data[iy*file.width+ix+1]
						self:set(x+ix, y+iy, tile)
					end
				end
			end
		elseif v.name == "objects" then
			room.objects = v.objects
		end
	end

	local random = math.random(1,2)
	-- Human/fire room
	if random == 1 then
		local count = math.floor(width/5)
		local sep = math.floor(width/(count+1))
		for i=1,count do
			if math.random(1,2) == 1 then
				table.insert(self.humans, Human.create((x+i*sep)*16+8, (y+4)*16))
			else
				self:addFire(x+i*sep, y+3)
			end
		end

	-- Enemy room
	elseif random == 2 then
		local count = 1
		if self.section >= 20 then
			if math.random(1,3) == 1 then
				count = 2
			end
		elseif self.section >= 12 and math.random(1,5) == 1 then
			count = 2
		end
		local sep = math.floor(width/(count+1))

		for i=1,count do
			random = math.random(self.minenemy, self.maxenemy)
			local rx = (x+i*sep)*16+8
			if random == 1 then
				table.insert(self.enemies, NormalEnemy.create(rx, (y+4)*16))
			elseif random == 2 then
				table.insert(self.enemies, JumperEnemy.create(rx, (y+4)*16))
			elseif random == 3 then
				table.insert(self.enemies, VolcanoEnemy.create(rx, (y+4)*16))
			elseif random == 4 then
				table.insert(self.enemies, AngryNormalEnemy.create(rx, (y+4)*16))
			elseif random == 5 then
				table.insert(self.enemies, AngryJumperEnemy.create(rx, (y+4)*16))
			elseif random == 6 then
				table.insert(self.enemies, AngryVolcanoEnemy.create(rx, (y+4)*16))
			elseif random == 7 then
				table.insert(self.enemies, ThiefEnemy.create(rx, (y+4)*16))
			end
		end
	end
end

--- Adds a particle to the map
-- @param particle Particle to add
function Map:addParticle(particle)
	table.insert(map.particles, particle)
end

--- Checks if a point is inside a solid block
-- @param x X coordinate of point
-- @param y Y coordinate of point
-- @return True if the point is solid
function Map:collidePoint(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)

	return self:collideCell(cx,cy)
end

--- Checks if a cell is solid
-- @param cx X coordinate of cell in tiles
-- @param cy Y coordinate of cell in tiles
function Map:collideCell(cx,cy)
	local tile = self:get(cx,cy)
	if tile and tile > 0 and tile < 60 then
		return true
	else
		return false
	end
end

--- Checks whether a cell can burn or not
-- @param cx X coordinate of cell
-- @param cy Y coordinate of cell
function Map:canBurnCell(cx,cy)
	if self:collideCell(cx,cy) == true then
		return false
	end
	local tile = self:get(cx,cy)
	local below = self:get(cx,cy+1)
	if tile == 239 or tile == 240 -- window top
	or tile == 255 or tile == 256 -- window bottom
	or tile == 137 or tile == 153 or tile == 21 -- inside ladders
	or below == 5 then			  -- above ladder
		return false
	end
	return true
end

--- Called when some object (stream, flying NPC...) collides
--  with a solid tile.
-- @param cx X coordinate of the cell
-- @param cy Y coordinate of the cell
function Map:hitCell(cx,cy,dir)
	local id = self:get(cx,cy)
	if id == 38 or id == 39 then
		self:destroyWindow(cx,cy,id,dir)
	end
end

function Map:lineOfSight(x1,y1,x2,y2)
	local minx = math.min(x1,x2)
	local miny = math.min(y1,y2)
	local width = math.abs(x1-x2)
	local height = math.abs(y1-y2)

	-- Collide with tiles
	local cx,cy = math.floor(minx/16), math.floor(miny/16)
	local endx = math.floor((minx+width)/16)
	local endy = math.floor((miny+height)/16)
	for iy=cy,endy do
		for ix=cx,endx do
			if map:collideCell(ix,iy) == true then
				return false
			end
		end
	end

	-- Collide with objects
	local bbox = {x=minx, y=miny, w=width, h=height}
	for i,v in ipairs(map.objects) do
		if v:collideBox(bbox) == true then
			return false
		end
	end

	return true
end

--- Destroy a window and adds shards particle effect
--@param cx X-position of window
--@param cy Y-position of upper tile of window
--@param id ID of the tile that was hit triggered
--@param dir Direction of the water stream upon collision
function Map:destroyWindow(cx,cy,id,dir)
	if id == 38 then -- left lower window
		self:set(cx,cy-1, 239)
		self:set(cx,cy,   255)
		table.insert(self.particles, Shards.create(cx*16+6, (cy-1)*16, dir))
		stats[5] = stats[5] + math.random(100,200)
		playSound("glass")
	elseif id == 39 then -- right lower window
		self:set(cx,cy-1, 240)
		self:set(cx,cy,   256)
		table.insert(self.particles, Shards.create(cx*16+10, (cy-1)*16, dir))
		stats[5] = stats[5] + math.random(100,200)
		playSound("glass")
	end
	self:forceRedraw()
end

--- Returns the id of the tile (x,y)
function Map:get(x,y)
	if x < 0 or y < 0 or x > self.width or y > self.height then
		return 0
	else
		return self.data[y*self.width+x+1]
	end
end

--- Returns the id of the tile the point (x,y) belongs to
function Map:getPoint(x,y)
	local cx = math.floor(x/16)
	local cy = math.floor(y/16)
	return self:get(cx,cy)
end

--- Sets the id of the tile (x,y)
function Map:set(x,y,val)
	if x < 0 or y < 0 or x > self.width or y > self.height then
		return
	end
	self.data[y*self.width+x+1] = val
end

function Map:getWidth()
	return self.width
end

function Map:getHeight()
	return self.height
end

function Map:getStart()
	if self.type == MT_NORMAL then
		return self.startx, self.starty
	else
		if ingame_state == INGAME_PRESCREEN then
			return self.startx, self.starty
		else
			if player.x < MAPW/2 then
				return 168, 224
			else
				return 488, 224
			end
		end
	end
end
