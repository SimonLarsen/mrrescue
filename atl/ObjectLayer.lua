---------------------------------------------------------------------------------------------------
-- -= ObjectLayer =-
---------------------------------------------------------------------------------------------------
-- Setup
TILED_LOADER_PATH = TILED_LOADER_PATH or ({...})[1]:gsub("[%.\\/][Oo]bject[Ll]ayer$", "") .. '.'
local love = love
local unpack = unpack
local pairs = pairs
local ipairs = ipairs
local Object = require( TILED_LOADER_PATH .. "Object")
local ObjectLayer = {class = "ObjectLayer"}
local grey = {128,128,128,255}
ObjectLayer.__index = ObjectLayer

---------------------------------------------------------------------------------------------------
-- Creates and returns a new ObjectLayer
function ObjectLayer:new(map, name, color, opacity, prop)
    
    -- Create a new table for our object layer and do some error checking.
    local layer = setmetatable({}, ObjectLayer)
    
    layer.map = map                             -- The map this layer belongs to
    layer.name = name or "Unnamed ObjectLayer"  -- The name of this layer
    layer.color = color or grey                 -- The color theme
    layer.opacity = opacity or 1                -- The opacity
    layer.objects = {}                          -- The layer's objects indexed numerically
    layer.properties = prop or {}               -- Properties set by Tiled.
    layer.visible = true                        -- If false then the layer will not be drawn
    
    -- Return the new object layer
    return layer
end

---------------------------------------------------------------------------------------------------
-- Creates a new object, automatically inserts it into the layer, and then returns it
function ObjectLayer:newObject(name, type, x, y, width, height, gid, prop)
    local obj = Object:new(self, name, type, x, y, width, height, gid, prop)
    self.objects[#self.objects+1] = obj
    return obj
end

---------------------------------------------------------------------------------------------------
-- Sorting function for objects. We'll use this below in ObjectLayer:draw()
local function drawSort(o1, o2) 
    return o1.drawInfo.order < o2.drawInfo.order 
end

---------------------------------------------------------------------------------------------------
-- Draws the object layer. The way the objects are drawn depends on the map orientation and
-- if the object has an associated tile. It tries to draw the objects as closely to the way
-- Tiled does it as possible.
local di, dr, drawList, r, g, b, a, line, obj, offsetX, offsetY
function ObjectLayer:draw()

    -- Early exit if the layer is not visible.
    if not self.visible then return end

    -- Exit if objects are not suppose to be drawn
    if not self.map.drawObjects then return end

    di = nil                            -- The draw info
    dr = {self.map:getDrawRange()}      -- The drawing range. [1-4] = x, y, width, height
    drawList = {}                       -- A list of the objects to be drawn
    r,g,b,a = 255, 255, 255, 255 ---love.graphics.getColor()    -- Save the color so we can set it back at the end
    line = love.graphics.getLineWidth() -- Save the line width too
    self.color[4] = 255 * self.opacity  -- Set the opacity
    
    -- Put only objects that are on the screen in the draw list. If the screen range isn't defined
    -- add all objects
    for i = 1, #self.objects do
        obj = self.objects[i]
        obj:updateDrawInfo()
        di = obj.drawInfo
        if dr[1] and dr[2] and dr[3] and dr[4] then
            if  di.right > dr[1]-20 and 
                di.bottom > dr[2]-20 and 
                di.left < dr[1]+dr[3]+20 and 
                di.top < dr[2]+dr[4]+20 then 
                    drawList[#drawList+1] = obj
            end
        else
            drawList[#drawList+1] = obj
        end
    end
    
    -- Sort the draw list by the object's draw order
    table.sort(drawList, drawSort)

    -- Draw all the objects in the draw list.
    offsetX, offsetY = self.map.offsetX, self.map.offsetY
    for i = 1, #drawList do 
        obj = drawList[i]
        love.graphics.setColor(r,b,g,a)
        drawList[i]:draw(di.x, di.y, unpack(self.color or neutralColor))
    end
    
    -- Reset the color and line width
    love.graphics.setColor(r,b,g,a)
    love.graphics.setLineWidth(line)
end

---------------------------------------------------------------------------------------------------
-- Changes an object layer into a custom layer. A function can be passed to convert objects.
function ObjectLayer:toCustomLayer(convert)
    if convert then
        for i = 1, #self.objects do
            self.objects[i] = convert(self.objects[i])
        end
    end
    self.class = "CustomLayer"
    return setmetatable(self, nil)
end

---------------------------------------------------------------------------------------------------
-- Return the ObjectLayer class
return ObjectLayer


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
