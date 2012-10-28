---------------------------------------------------------------------------------------------------
-- -= TileLayer =-
---------------------------------------------------------------------------------------------------
-- Setup
TILED_LOADER_PATH = TILED_LOADER_PATH or ({...})[1]:gsub("[%.\\/][Tt]ile[Ll]ayer$", "") .. '.'
local math = math
local type = type
local love = love
local Grid = require(TILED_LOADER_PATH .. "Grid")
local TileLayer = {class = "TileLayer"}
TileLayer.__index = function(t, i) return TileLayer[i] or Grid[i] end
TileLayer.__call = Grid.__call

----------------------------------------------------------------------------------------------------
-- Returns a new TileLayer
function TileLayer:new(map, name, opacity, prop)
    if not map or not name then 
        error("TileLayer:new - Needs at least 2 parameters for the map and name.")
    end
    
    local tl = setmetatable(Grid:new(), TileLayer)
    
    prop = prop or {}
    
    -- Public:
    tl.name = name                              -- The name of the tile layer
    tl.map = map                                -- The map that this layer belongs to
    tl.opacity = opacity or 1                   -- The opacity to draw the tiles (0-1)
    tl.properties = prop                        -- Properties set by Tiled
    tl.visible = true                           -- If false then the layer will not be drawn
    
    tl.useSpriteBatch = prop.alt_useSpriteBatch -- If true then the layer is rendered with sprite 
                                                -- batches. If false then the layer will not use 
                                                -- sprite batches. If nil then map.useSpriteBatch 
                                                -- will be used. 
    
    tl.parallaxX = prop.atl_parallaxX or 1      -- The horizontal speed of the parallax. 1 is normal
    tl.parallaxY = prop.atl_parallaxX or 1      -- The vertical speed of the parallax. 1 is normal
    tl.offsetX = prop.atl_offsetX or 0          -- Drawing offset X
    tl.offsetY = prop.atl_offsetY or 0          -- Drawing offset Y
    
    -- Private:
    tl._redraw = true                   -- If true then the layer needs to redraw tis sprite batches.
    tl._tileRange = {0,0,0,0}           -- Keeps the drawn tile range for the layer
    tl._previousTileRange = {0,0,0,0}   -- Previous _tileRange
    tl._batches = {}                    -- Keeps track of the sprite batches for each tileset
    tl._flippedTiles = Grid:new()       -- Stores the flipped tile locations. 
                                            -- 1 = flipped X, 2 = flipped Y, 3 = both
    tl._afterTileFunctions = Grid:new() -- Functions that must happen right after a tile is drawn.
    tl._previousUseSpriteBatch = false  -- The previous useSpriteBatch. If this is different then we 
                                            -- need to force a special redraw
    return tl
end

----------------------------------------------------------------------------------------------------
-- Clears the draw list of any functions
function TileLayer:clearAfterTile()
    for x,y,v in self._afterTileFunctions:iterate() do
        self._afterTileFunctions:set(x,y,nil)
    end
end

----------------------------------------------------------------------------------------------------
-- Adds a function to the tile's draw list
function TileLayer:drawAfterTile(x, y, funct)
    if self.useSpriteBatch ~= nil and self.useSpriteBatch or self.map.useSpriteBatch then 
        error("TileLayer:drawAfterTile - This function is not possible with sprite batches enabled")
    end
    self._afterTileFunctions:set(x, y, funct)
end

----------------------------------------------------------------------------------------------------
-- These are used in TileLayer:draw() but since that function is called so often we'll define them
-- outside to prevent them from being created and destroyed all the time.
local map, tile, tiles, postDraw, useSpriteBatch, tile, width, height
local at, drawX, drawY, flipX, flipY, r, g, b, a, halfW, halfH
local x1, y1, x2, y2
-- Draws the TileLayer.
function TileLayer:draw()

    -- Early exit of the layer is not visible
    if not self.visible then return end

    -- We access these a lot so we'll shorted them a bit. 
    map, tiles = self.map, self.map.tiles
    postDraw = self.postDraw
    
    -- If useSpriteBatch was changed then we need to force the sprite batches to redraw.
    if self.useSpriteBatch ~= self._previousUseSpriteBatch then map:forceRedraw() end
    
    -- Set the previous useSpriteBatch
    self._previousUseSpriteBatch = self.useSpriteBatch
    
    -- If useSpriteBatch is set for this layer then use that, otherwise use the map's setting.
    useSpriteBatch = self.useSpriteBatch ~= nil and self.useSpriteBatch or map.useSpriteBatch
    
    -- We'll blend the set alpha in with the current alpha
    r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(r,g,b, a*self.opacity)
    
    -- Clear sprite batches if the screen has changed.
    if self._redraw and useSpriteBatch then
        for k,v in pairs(self._batches) do
            v:clear()
        end
    end
    
    -- Get the tile range
    x1, y1, x2, y2 = self._tileRange[1], self._tileRange[2], self._tileRange[3], self._tileRange[4]
    
    -- Translate for the parallax
    if self.parallaxX ~= 1 or self.parallaxY ~= 1 then
        love.graphics.push()
        love.graphics.translate(math.floor(map.viewX - map.viewX*self.parallaxX), 
                                math.floor(map.viewY - map.viewY*self.parallaxY))
    end
    
    -- Only draw if we're not using sprite batches or we need to update the sprite batches.
    if self._redraw or not useSpriteBatch then
    
        -- Bind the sprite batches
        if useSpriteBatch then 
            for k, batch in pairs(self._batches) do
                batch:bind()
            end
        end
    
        -- Orthogonal tiles
        if map.orientation == "orthogonal" then
            -- Go through each tile
            for x,y,tile in self:rectangle(x1,y1,x2,y2) do
                -- Get the half-width and half-height
                halfW, halfH = tile.width*0.5, tile.height*0.5
                -- Draw the tile from the bottom left corner
                drawX, drawY = (x)*map.tileWidth, (y+1)*map.tileHeight
                -- Apply the offset
                drawX = drawX - map.offsetX - self.offsetX
                drawY = drawY - map.offsetY - self.offsetY
                -- Get the flipped tiles
                if self._flippedTiles(x,y) then
                    rot =  (self._flippedTiles(x,y) % 2) == 1 and true or false
                    flipY = (self._flippedTiles(x,y) % 4) >= 2 and -1 or 1
                    flipX = self._flippedTiles(x,y) >= 4 and -1 or 1
                    if rot then flipX, flipY = -flipY, flipX end
                else
                    rot, flipX, flipY = false, 1, 1
                end
                
                -- If we are using spritebatches
                if useSpriteBatch then
                    -- If we dont have a spritebatch for the current tile's tileset then make one
                    if not self._batches[tile.tileset] then 
                        self._batches[tile.tileset] = love.graphics.newSpriteBatch(
                                                        tile.tileset.image, map.width * map.height)
                        self._batches[tile.tileset]:bind()
                    end
                    -- Add the quad to the spritebatch
                    self._batches[tile.tileset]:addq(tile.quad, drawX + halfW, 
                                    drawY - halfH, 
                                    rot and math.pi*1.5 or 0, 
                                    flipX, flipY, halfW, halfH)
                                    
                -- If we are not using spritebatches
                else
                    -- Draw the tile
                    tile:draw(drawX + halfW,
                          drawY - halfH, 
                          rot and math.pi*1.5 or 0, 
                          flipX, flipY, halfW, halfH)
                    -- If there's something in the _afterTileFunctions for this tile then call it
                    if self._afterTileFunctions(x,y) then
                        at = self._afterTileFunctions(x,y)
                        if type(at) == "function" then at(drawX, drawY)
                        elseif type(at) == "table" then for i=1,#at do at[i](drawX, drawY) end end
                    end
                end
                
            end
        end
        
        -- Isometric tiles
        if map.orientation == "isometric" then
            local x,y
            -- Get the starting x drawing location
            draw_start = map.height * map.tileWidth/2
            -- Draw each tile starting from the top left tile. Make sure we have enough
            -- room to draw the widest and tallest tile in the map.
            for down=0,y2 do 
                for layer=0,1 do
                    for right=0,x2 do
                        x = x1 + right + down + layer - 1
                        y = y1 - right + down - 1
                        -- If there is a tile row
                        if self(x,y) then
                            -- Check and see if the tile is flipped
                            if self._flippedTiles(x,y) then
                                rot =  (self._flippedTiles(x,y) % 2) == 1 and true or false
                                flipY = (self._flippedTiles(x,y) % 4) >= 2 and -1 or 1
                                flipX = self._flippedTiles(x,y) >= 4 and -1 or 1
                                if rot then flipX, flipY = -flipY, flipX end
                            else
                                rot, flipX, flipY = false, 1, 1
                            end
                            -- Get the tile
                            tile = self(x,y)
                            -- If the tile exists then draw the tile
                            if tile then 
                                -- Get the half-width and half-height
                                halfW, halfH = tile.width*0.5, tile.height*0.5
                                -- Get the tile draw location
                                drawX = math.floor(draw_start + map.tileWidth/2 * (x - y-2))
                                drawY = math.floor(map.tileHeight/2 * (x + y+2))
                                -- Apply the offset
                                drawX = drawX - map.offsetX - self.offsetX
                                drawY = drawY - map.offsetY - self.offsetY
                                
                                -- Using sprite batches
                                if useSpriteBatch then
                                    -- If we dont have a spritebatch for the current tile's tileset 
                                    -- then make one
                                    if not self._batches[tile.tileset] then 
                                        self._batches[tile.tileset] = love.graphics.newSpriteBatch(
                                                                            tile.tileset.image, 
                                                                            map.width * map.height)
                                    end
                                    -- Add the tile to the sprite batch.
                                    self._batches[tile.tileset]:addq(tile.quad, drawX + halfW + 
                                                                (rot and halfW or 0), 
                                                                drawY-halfH+(rot and halfW or 0), 
                                                                rot and math.pi*1.5 or 0, 
                                                                flipX, flipY, halfW, halfH)
                                    -- Bind the sprite batch
                                    self._batches[tile.tileset]:bind()
                                                                    
                                -- Not using sprite batches
                                else
                                    tile:draw(drawX + halfW + (rot and halfW or 0), 
                                                drawY - halfH + (rot and halfW or 0), 
                                                rot and math.pi*1.5 or 0, 
                                                flipX, flipY, halfW, halfH)
                                    -- If there's something in the _afterTileFunctions for 
                                    -- this tile then call it
                                    at = self._afterTileFunctions(x,y)
                                    if type(at) == "function" then 
                                        at(drawX, drawY)
                                    elseif type(at) == "table" then 
                                        for i=1,#at do at[i](drawX, drawY) end 
                                    end
                                end -- sprite batches
                                
                            end -- tile drawable
                        end -- tile row
                    end -- right
                end -- layer
            end -- down
        end --isometric
        
        -- Unbind the sprite batches
         if useSpriteBatch then 
            for k, batch in pairs(self._batches) do
                batch:unbind()
            end
        end
        
    end
    
    -- We finished redrawing
    self._redraw = false
    
    -- If sprite batches are turned on then render them
    if useSpriteBatch then
        for k, batch in pairs(self._batches) do
            love.graphics.draw(batch)
        end
    end
    
    -- If we applied a translation for our parallax then remove it
    if self.parallaxX ~= 1 or self.parallaxY ~= 1 then
        love.graphics.pop()
    end
    
    -- Clears the draw list
    self:clearAfterTile()
    
    -- Change the color back
    love.graphics.setColor(r,g,b,a)
end

----------------------------------------------------------------------------------------------------
-- This copies a tile so that you can paste it in another spot. The pasted tile will keep the
-- rotation and flipped status. You can copy and paste between layers.
local flippedVal = 2^29
function TileLayer:tileCopy(x,y)
    if not self(x,y) then 
        self.map._tileClipboard = 0 
    else
        self.map._tileClipboard = self(x,y).id + (self._flippedTiles(x,y) or 0) * flippedVal
    end
end

----------------------------------------------------------------------------------------------------
-- Paste a copied tile.
function TileLayer:tilePaste(x,y)
    self._redraw = true
    if not self.map._tileClipboard then
        error("TileLayer:tilePaste() - A tile must be copied with tileCopy() before pasting")
    end
    local clip = self.map._tileClipboard 
    if clip / flippedVal > 0 then
        self._flippedTiles:set(x, y, math.floor(clip / flippedVal))
    end
    self:set(x, y, self.map.tiles[clip % flippedVal])
end

----------------------------------------------------------------------------------------------------
-- Flip the tile's X. If doFlip is not specified then the flip is toggled.
function TileLayer:tileFlipX(x, y, doFlip)
    self._redraw = true
    local flip = self._flippedTiles(x,y) or 0
    if doFlip ~= false and flip < 4 then 
        flip = flip + 4
    elseif doFlip ~= true and flip >= 4 then 
        flip = flip - 4
    end
    self._flippedTiles:set(x, y, flip ~= 0 and flip or nil)
end

----------------------------------------------------------------------------------------------------
-- Flip the tile's Y. If doFlip is not specified then the flip is toggled.
function TileLayer:tileFlipY(x, y, doFlip)
    self.redraw = true
    local flip = self._flippedTiles(x,y) or 0
    if doFlip ~= false and flip % 4 < 2 then 
        flip = flip + 2
    elseif doFlip ~= true and flip % 4 >= 2 then 
        flip = flip - 2
    end
    self._flippedTiles:set(x, y, flip ~= 0 and flip or nil)
end

----------------------------------------------------------------------------------------------------
-- Rotate the tile.
function TileLayer:tileRotate(x, y, rot)
    local flip = self._flippedTiles(x,y) or 0
    if rot then flip = rot % 8
    elseif flip == 0 then flip = 5
    elseif flip == 1 then flip = 4 
    elseif flip == 2 then flip = 1
    elseif flip == 3 then flip = 0 
    elseif flip == 4 then flip = 7
    elseif flip == 5 then flip = 6
    elseif flip == 6 then flip = 3
    elseif flip == 7 then flip = 2 
    end
    self._flippedTiles:set(x, y, flip ~= 0 and flip or nil)
end

----------------------------------------------------------------------------------------------------
-- Private
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Creates the tile data from a table containing each tile id in sequential order
-- from left-to-right, top-to-bottom.
str = ""
function TileLayer:_populate(t)

    str = ""
    local lasty = 0
    for i=1,#t do
        str = str .. t[i]
        if lasty ~= math.floor(i/self.map.width) then
            str = str .. "\n"
            lasty = math.floor(i/self.map.width)
        end
    end
    
    -- Some temporary storage
    local width, height =  self.map.width, self.map.height
    local tileID
    
    -- The values that indicate flipped tiles are in the last three binary digits. We need
    -- to seperate those.
    local flipped = 2^29
    
    -- Clear the tiles
    self:clear()
    
    -- Go through every tile
    for x,y,v in self:rectangle(0,0,width-1,height-1,true) do
        tileID = t[width*y+x+1] or 0
        
        -- If the tile has a value in the last three binary digits then we seperate them
        if tileID >= flipped then 
            self._flippedTiles:set(x, y, math.floor(tileID / flipped))
            tileID = tileID % flipped
        end
        
        -- Set the tile
        self:set(x, y, self.map.tiles[tileID])
    end
end

----------------------------------------------------------------------------------------------------
-- Return the TileLayer class
return TileLayer


--[[Copyright (c) 2011-2012 Casey Baxter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.--]]

