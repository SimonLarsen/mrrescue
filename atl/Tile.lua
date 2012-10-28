---------------------------------------------------------------------------------------------------
-- -= Tile =-
---------------------------------------------------------------------------------------------------

-- Setup
local assert = assert
local Tile = {class = "Tile"}
Tile.__index = Tile

-- Creates a new tile and returns it.
function Tile:new(id, tileset, quad, width, height, prop)
    if not id or not tileset or not quad then
        error("Tile:new - Needs at least 3 parameters for id, tileset and quad.")
    end
    local tile = setmetatable({}, Tile)
    tile.id = id                    -- The id of the tile
    tile.tileset = tileset          -- The tileset this tile belongs to
    tile.quad = quad                -- The of the tileset that defines the tile
    tile.width = width or 0         -- The width of the tile in pixels
    tile.height = height or 0       -- The height of the tile in pixels
    tile.properties = prop or {}    -- The properties of the tile set in Tiled
    return tile
end

-- Draws the tile at the given location 
function Tile:draw(x, y, rotation, scaleX, scaleY, offsetX, offsetY)
    love.graphics.drawq(self.tileset.image, self.quad, self.tileset.offsetX + x, 
                        self.tileset.offsetY + y, rotation, scaleX, scaleY, offsetX, offsetY)
end

-- Return the Tile class
return Tile


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