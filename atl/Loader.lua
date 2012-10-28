---------------------------------------------------------------------------------------------------
-- -= Loader =-
---------------------------------------------------------------------------------------------------

-- Define path so lua knows where to look for files.
TILED_LOADER_PATH = TILED_LOADER_PATH or ({...})[1]:gsub("[%.\\/][Ll]oader$", "") .. '.'

-- A cache to store tileset images so we don't load them multiple times. Filepaths are keys.
local cache = setmetatable({}, {__mode = "v"})

-- This stores cached images' original dimensions. Images are weak keys.
local cache_imagesize = setmetatable({}, {__mode="k"})

-- Decompresses gzip and zlib
local decompress = require(TILED_LOADER_PATH .. "external/deflatelua")

-- XML parser
local xml = require(TILED_LOADER_PATH .. "external/xml")

-- Base64 parser, Turns base64 strings into other data formats
local base64 = require(TILED_LOADER_PATH .. "Base64")

-- Get the map classes
local Map = require(TILED_LOADER_PATH .. "Map")
local TileSet = require(TILED_LOADER_PATH .. "TileSet")
local TileLayer = require(TILED_LOADER_PATH .. "TileLayer")
local Tile = require(TILED_LOADER_PATH .. "Tile")
local Object = require(TILED_LOADER_PATH .. "Object")
local ObjectLayer = require(TILED_LOADER_PATH .. "ObjectLayer")

local Loader = {
    path = "",                      -- The path to tmx files.
    filterMin = "nearest",          -- The default min filter for image:setFilter()
    filterMag = "nearest",          -- The default mag filter for image:setFilter()
    useSpriteBatch = true,          -- The default setting for map.useSpriteBatch
    drawObjects = true,             -- The default setting for map.drawObjects. 
    saveDirectory = "Saved Maps",   -- The directory to use for Loader.save()
}

local filename  -- The name of the tmx file
local fullpath  -- The full path to the tmx file minus the name

----------------------------------------------------------------------------------------------------
-- Loads a Map from a tmx file and returns it.
function Loader.load(tofile)
    
    -- Get the raw path
    fullpath = Loader.path .. tofile
    
    -- Process directory up
    while string.find(fullpath, "[/\\][^/^\\]+[/\\]%.%.[/\\]") do
        fullpath = string.gsub(fullpath, "[/\\][^/^\\]+[/\\]%.%.[/\\]", "/", 1)
    end
    
    -- Get the file name
    filename = string.match(fullpath, "[^/^\\]+$")
    
    -- Get the path to the file
    fullpath = string.gsub(fullpath, "[^/^\\]+$", "")
    
    -- Find out if the file is in the game or save directory
    if love.filesystem.exists(fullpath .. filename) then
    elseif love.filesystem.exists(fullpath .. filename .. ".tmx") then
        filename = filename .. ".tmx"
    elseif love.filesystem.exists(Loader.saveDirectory.."/"..filename) then
        fullpath = Loader.saveDirectory .. "/"
    elseif love.filesystem.exists(Loader.saveDirectory .. "/" .. filename .. ".tmx") then
        fullpath = Loader.saveDirectory .. "/"
        filename = filename .. ".tmx"
    else
        error("Loader.load() Could not find find the file in these locations:\n" ..
            "\nGame Directory: " .. fullpath .. filename ..
            "\nGame Directory: " .. fullpath .. filename .. ".tmx" ..
            "\nSave Directory: " .. Loader.saveDirectory.."/"..filename ..
            "\nSave Directory: " .. Loader.saveDirectory.."/"..filename .. ".tmx")
    end
    
    -- Read the file and parse it into a table
    local t = love.filesystem.read(fullpath .. filename)
    t = xml.string_to_table(t)
    
    -- Get the map and expand it
    for _, v in pairs(t) do
        if v.label == "map" then
            return Loader._expandMap(fullpath .. filename, v)
        end
    end
    
    -- If we made this this far then there wasn't a map tag
    error("Loader.load - No map found in file " .. fullpath .. filename)
end

----------------------------------------------------------------------------------------------------
-- Saves a map to a file.
function Loader.save(map, filename)
    local mapx = Loader._compactMap(map)
    if not love.filesystem.exists(Loader.saveDirectory) then
        love.filesystem.mkdir(Loader.saveDirectory)
    end
    love.filesystem.write( Loader.saveDirectory .. "/" .. filename, xml.table_to_string(mapx) )
end

----------------------------------------------------------------------------------------------------
-- Checks to see if a saved map exists
function Loader.savedMapExists(filename)
    if love.filesystem.exists(Loader.saveDirectory.."/"..filename) then
        return true
    elseif love.filesystem.exists(Loader.saveDirectory .. "/" .. filename .. ".tmx") then
        return true
    end
    return false
end

----------------------------------------------------------------------------------------------------
-- Private
----------------------------------------------------------------------------------------------------

-- Returns a new image from the filename. 
function Loader._newImage(source)
    return love.graphics.newImage(source), source:getWidth(), source:getHeight()
end

----------------------------------------------------------------------------------------------------
-- Checks to see if the table is a valid XML table
function Loader._checkXML(t)
    assert(type(t) == "table", "Loader._checkXML - Passed value is not a table")
    assert(t ~= Loader, "Loader._checkXML - Passed table is the Loader class. " ..
                        "You probably used a : instead of a .")
    assert(t.label, "Loader._checkXML - Table does not contain a label value")
    assert(t.xarg, "Loader._checkXML - Table does not contain an xarg table")
end

----------------------------------------------------------------------------------------------------
-- This is used to eliminate naming conflicts. It checks to see if the string is inside the table and
-- continues to rename it until there isn't a conflict.
function Loader._checkName(t, str)
    while t[str] do
        if string.find(str, "%(%d+%)$") == nil then str = str .. "(1)" end
        str = string.gsub(str, "%(%d+%)$", function(a) return "(" .. 
                                tonumber( string.sub(a, string.find(a, "%d+")) ) + 1 .. ")" end)
    end
    return str
end

----------------------------------------------------------------------------------------------------
-- Processes a properties table and returns it
function Loader._expandProperties(t)

    -- Do some checking
    Loader._checkXML(t)
    if t.label ~= "properties" then
        error("Loader._expandProperties - Passed value is not a properties table")
    end
    
    -- Create a properties table and populate it. Will attempt to convert the property to
    -- the appropriate type.
    local prop = {}
    for _,v in pairs(t) do
        Loader._checkXML(t)
        if v.label == "property" then
            if v.xarg.value == "true" then
                prop[v.xarg.name] = true
            elseif v.xarg.value == "false" then
                prop[v.xarg.name] = false
            else
                prop[v.xarg.name] = tonumber(v.xarg.value) or v.xarg.value
            end
        end
    end
    
    -- Return the properties
    return prop
end

----------------------------------------------------------------------------------------------------
-- Process Map data from xml table
function Loader._expandMap(name, t)
    
    -- Do some checking
    Loader._checkXML(t)
    assert(t.label == "map", "Loader._expandMap - Passed table is not a map")
    assert(t.xarg.width, t.xarg.height, t.xarg.tilewidth, t.xarg.tileheight,
           "Loader._expandMap - Map data is corrupt")

    -- We'll use these for temporary storage
    local map, tileset, tilelayer, objectlayer, props
    local props = {}
    
    -- Get the properties
    for _, v in ipairs(t) do
        if v.label == "properties" then
            props = Loader._expandProperties(v)
        end
    end
    
    -- Create the map from the settings
    local map = Map:new(name, tonumber(t.xarg.width),tonumber(t.xarg.height), 
                        tonumber(t.xarg.tilewidth), tonumber(t.xarg.tileheight), 
                        t.xarg.orientation, props.atl_directory or fullpath, props)

    -- Apply the loader settings if atl_useSpriteBatch or atl_drawObjects was not set
    map.useSpriteBatch = map.useSpriteBatch == nil and Loader.useSpriteBatch or map.useSpriteBatch 
    map.drawObjects = map.drawObjects == nil and  Loader.drawObjects or map.drawObjects
    
    -- Now we fill it with the content
    for _, v in ipairs(t) do
        
        -- Process TileSet
        if v.label == "tileset" then 
            tileset = Loader._expandTileSet(v, map)
            map.tilesets[tileset.name] = tileset
            map:updateTiles()
        end
            
        -- Process TileLayer
        if v.label == "layer" then
            tilelayer = Loader._expandTileLayer(v, map)
            map.layers[tilelayer.name] = tilelayer
            map.layerOrder[#map.layerOrder + 1] = tilelayer
        end
        
        -- Process ObjectLayer
        if v.label == "objectgroup" then
            objectlayer = Loader._expandObjectLayer(v, map)
            map.layers[objectlayer.name] = objectlayer
            map.layerOrder[#map.layerOrder + 1] = objectlayer
        end
        
        -- Process CustomLayer
        if v.label == "customlayer" then
            map:newCustomLayer(v.xarg.name)
            for _, v2 in ipairs(v) do
                if v2.label == "data" then
                    map(v.xarg.name).data = v2[1]
                end
            end
        end
        
    end
    
    -- Return our map
    return map
end

----------------------------------------------------------------------------------------------------
-- Process TileSet from xml table
function Loader._expandTileSet(t, map)

    -- Do some checking
    Loader._checkXML(t)
    assert(t.label == "tileset", "Loader._expandTileSet - Passed table is not a tileset")
    
    -- If the tileset is an external one then replace it as the tileset. The firstgid is 
    -- stored in the tileset tag in the original file while the rest of the tileset information 
    -- is stored in the external file.
    if t.xarg.source then 
        local gid = t.xarg.firstgid
        t = love.filesystem.read(map._directory .. t.xarg.source)
        for _,v in pairs(xml.string_to_table(t)) do if v.label == "tileset" then t = v end end
        t.xarg.firstgid = gid
    end
    
    if not t.xarg.name or not t.xarg.tilewidth or not t.xarg.tileheight or not t.xarg.firstgid then
        error("Loader._expandTileSet - Tileset data is corrupt")
    end

    
    -- Temporary storage
    local image, imagePath, imageWidth, imageHeight, path, prop, tileSetProperties, trans
    local tileProperties = {}
    local offsetX, offsetY = 0, 0
    
    -- Process elements
    for _, v in ipairs(t) do
        -- Process image
        if v.label == "image" then 
            imagePath = v.xarg.source
            path = map._directory .. v.xarg.source
            -- Process directory up
            while string.find(path, "[^/^\\]+[/\\]%.%.[/\\]") do
                path = string.gsub(path, "[^/^\\]+[/\\]%.%.[/\\]", "", 1)
            end
            -- If the image is in the cache then load it
            if cache[path] then
                image = cache[path]
                imageWidth = cache_imagesize[image].width
                imageHeight = cache_imagesize[image].height
            -- Else load it and store in the cache
            else
                image = love.image.newImageData(path) 
                -- transparent color
                if v.xarg.trans then
                    trans = { tonumber( "0x" .. v.xarg.trans:sub(1,2) ), 
                              tonumber( "0x" .. v.xarg.trans:sub(3,4) ), 
                              tonumber( "0x" .. v.xarg.trans:sub(5,6) )}
                    image:mapPixel( function(x,y,r,g,b,a)
                    return r,g,b, (trans[1] == r and trans[2] == g and trans[3] ==b and 0) or a  end
                    )
                end
                -- Set the image information
                image, imageWidth, imageHeight = Loader._newImage(image)
                image:setFilter(Loader.filterMin, Loader.filterMag)
                -- Cache the created image
                cache[path] = image
                cache_imagesize[image] = {width = imageWidth, height = imageHeight}
            end
        end
        
        -- Process tile properties
        if v.label == "tile" then 
            for _, v2 in ipairs(v) do
                if v2.label == "properties" then
                    -- Store the property. We must increase the id the starting gid
                    if not v.xarg.id then error(v.xarg.id) end
                    tileProperties[v.xarg.id+t.xarg.firstgid] = Loader._expandProperties(v2)
                end
            end
        end
        
        -- Process tile set properties
        if v.label == "properties" then
            tileSetProperties = Loader._expandProperties(v)
        end
        
        -- Get the tile offset if there is one.
        if v.label == "tileoffset" then
            offsetX, offsetY = tonumber(v.xarg.x or 0), tonumber(v.xarg.y or 0)
        end

    end
    
    -- Make sure that an image was loaded
    assert(image, "Loader._expandTileSet - Tileset did not contain an image")

    -- Return the TileSet
    local tileset = TileSet:new(image, imagePath, Loader._checkName(map.tilesets, t.xarg.name), 
                       tonumber(t.xarg.tilewidth), tonumber(t.xarg.tileheight),
                       tonumber(imageWidth), tonumber(imageHeight),
                       tonumber(t.xarg.firstgid), tonumber(t.xarg.spacing), tonumber(t.xarg.margin),
                       offsetX, offsetY, trans, tileProperties, tileSetProperties)
    return tileset
end

----------------------------------------------------------------------------------------------------
-- Process TileLayer from xml table
function Loader._expandTileLayer(t, map)

    -- Do some checking
    Loader._checkXML(t)
    assert(t.label == "layer", "Loader._expandTileLayer - Passed table is not a tileset")
    
    -- Process elements
    local data, properties
    for _, v in ipairs(t) do
        Loader._checkXML(t)
        
        -- Process data
        if v.label == "data" then 
            data = Loader._expandTileLayerData(v) 
        end
        
        -- Process TileLayer properties
        if v.label == "properties" then
            properties = Loader._expandProperties(v)
        end
    end
    
    -- Create the new layer
    local layer = TileLayer:new(map, t.xarg.name, t.xarg.opacity, properties)
    
    -- Set the visibility
    layer.visible = not (t.xarg.visible == "0")
    
    -- Populate the tiles and return the layer
    layer:_populate(data)
    return layer
end

----------------------------------------------------------------------------------------------------
-- Process TileLayer data from xml table
function Loader._expandTileLayerData(t)

    -- Do some checking
    Loader._checkXML(t)
    assert(t.label == "data", "Loader._expandTileLayerData - Passed table is not TileLayer data")
    
    local data = {}
    
    -- If encoded by comma seperated value (csv) then cut each value out and put it into a table.
    if t.xarg.encoding == "csv" then
            string.gsub(t[1], "[%-%d]+", function(a) data[#data+1] = tonumber(a) or 0 end)
    end
    
    -- Base64 encoding. See base64.lua for more details.
    if t.xarg.encoding == "base64" then
    
        -- If a compression method is used
        if t.xarg.compression == "gzip" or t.xarg.compression == "zlib"  then
            -- Select the appropriate function
            local decomp = t.xarg.compression == "gzip" and decompress.gunzip or decompress.inflate_zlib
            -- Decompress the string into bytes
            local bytes = {}
            decomp({input = base64.decode("string", t[1]), output = function(b) bytes[#bytes+1] = b end})
            -- Glue the bytes into ints
            for i=1,#bytes,4 do
                data[#data+1] = base64.glueInt(bytes[i],bytes[i+1],bytes[i+2],bytes[i+3])
            end
        -- If there is no compression then just convert to ints
        else
            data = base64.decode("int", t[1])
        end
    end
    
    -- If there is no encoding then the file is probably saved as XML
    if t.xarg.encoding == nil then
        for k,v in ipairs(t) do
            if v.label == "tile" then 
                data[#data+1] = tonumber(v.xarg.gid)
            end
        end
    end
    
    -- Return the data
    return data
end

----------------------------------------------------------------------------------------------------
-- Process ObjectLayer from xml table
function Loader._expandObjectLayer(t, map)

    -- Do some checking
    Loader._checkXML(t)
    if t.label ~= "objectgroup" then
        error("Loader._expandObjectLayer - Passed table is not ObjectLayer data")
    end
    
    -- Tiled stores colors in hexidecimal format that looks like "#FFFFFF" 
    -- We need go convert them into base 10 RGB format
    if t.xarg.color == nil then t.xarg.color = "#000000" end
    local color = { tonumber( "0x" .. t.xarg.color:sub(2,3) ), 
                    tonumber( "0x" .. t.xarg.color:sub(4,5) ), 
                    tonumber( "0x" .. t.xarg.color:sub(6,7) )}
    
    -- Create a new layer
    local layer = ObjectLayer:new(map, Loader._checkName(map.layers, t.xarg.name), color, 
                                  t.xarg.opacity)
                    
    -- Process elements
    local objects = {}
    local prop, obj, poly
    for _, v in ipairs(t) do
    
        -- Process objects
        local obj
        if v.label == "object" then
            obj = Object:new(layer, v.xarg.name, v.xarg.type, tonumber(v.xarg.x), 
                                tonumber(v.xarg.y), tonumber(v.xarg.width), 
                                tonumber(v.xarg.height), tonumber(v.xarg.gid) )
            objects[#objects+1] = obj
            for _, v2 in ipairs(v) do
            
                -- Process object properties
                if v2.label == "properties" then 
                    obj.properties = Loader._expandProperties(v2)
                end
                
                -- Process polyline objects
                local polylineFunct = function(a) 
                    obj.polyline[#obj.polyline+1] = tonumber(a) or 0 
                end
                if v2.label == "polyline" then
                    obj.polyline = {}
                    string.gsub(v2.xarg.points, "[%-%d]+", polylineFunct)
                end
                
                -- Process polyline objects
                local polygonFunct = function(a) 
                    obj.polygon[#obj.polygon+1] = tonumber(a) or 0 
                end
                if v2.label == "polygon" then
                    obj.polygon = {}
                    string.gsub(v2.xarg.points, "[%-%d]+", polygonFunct)
                end
            
            end
            obj:updateDrawInfo()
        end
        
        -- Process properties
        if v.label == "properties" then
            prop = Loader._expandProperties(v)
        end
        
    end
    
    -- Set the properties and object tables
    layer.properties = prop or {}
    layer.objects = objects
    
    -- Set the visibility
    layer.visible = not (t.xarg.visible == "0")
    
    -- Return the layer
    return layer
end

----------------------------------------------------------------------------------------------------
-- Compact a Map 
function Loader._compactMap(map)

    -- Set the ATL properties
    map.properties.atl_directory = map._directory
    map.properties.atl_useSpritebatch = map.useSpriteBatch
    map.properties.atl_viewX = map.viewX
    map.properties.atl_viewY = map.viewY
    map.properties.atl_viewW = map.viewW
    map.properties.atl_viewH = map.viewH
    map.properties.atl_viewScaling = map.viewScaling
    map.properties.atl_viewPadding = map.viewPadding
    map.properties.atl_drawObjects = map.drawObjects

    -- <map>
    local mapx = {label="map", xarg = {
        version = "1.0",
        orientation = map.orientation,
        width = map.width,
        height = map.height,
        tilewidth = map.tileWidth,
        tileheight = map.tileHeight,
    }}
    
    -- <tileset>
    for k,tileset in pairs(map.tilesets) do
        mapx[#mapx+1] = Loader._compactTileSet(tileset)
    end
    
    local layer, layerx
    for i = 1,#map.layerOrder do
        layer = map.layerOrder[i]
        
        -- <layer>
        if layer.class == "TileLayer" then
            mapx[#mapx+1] = Loader._compactTileLayer(layer)
            
        -- <objectgroup>
        elseif layer.class == "ObjectLayer" then
            mapx[#mapx+1] = Loader._compactObjectLayer(layer)
            
        -- <custom>
        elseif layer.encode then
            local layerx = {label="customlayer", xarg={name=layer.name}}
            layerx[1] = {label="data", xarg={}}
            layerx[1][1] = layer:encode()
            mapx[#mapx+1] = layerx
        end
        
    end
    
    -- <properties>
    mapx[#mapx+1] = Loader._compactProperties(map.properties)
    return mapx
end

----------------------------------------------------------------------------------------------------
-- Compact a TileSet
function Loader._compactTileSet(tileset)

    -- <Tileset>
    local tilesetx = {label="tileset", xarg = {
        firstgid = tileset.firstgid,
        name = tileset.name,
        tilewidth = tileset.tileWidth,
        tileheight = tileset.tileHeight,
        spacing = tileset.spacing,
        margin = tileset.margin
    }}
    
    -- <image>
    tilesetx[1] = {label="image", xarg = {
        source = tileset.imagePath,
        trans = tileset.trans,
    }}
    
    -- <tileoffset>
    if tileset.offsetX ~= 0 or tileset.offsetY ~= 0 then
        tilesetx[2] =  {label="tileoffset", xarg={x = tileset.offsetX, y = tileset.offsetY}}
    end
    
    -- <properties>
    if next(tileset.properties) then
        tilesetx[#tilesetx+1] = Loader._compactProperties(tileset.properties)
    end
    
    -- <tile>
    if  next(tileset.tileProperties) then
        local tilex
        for k,props in pairs(tileset.tileProperties) do
            tilex = {label = "tile", xarg = {id = k - tileset.firstgid}}
            tilex[1] = Loader._compactProperties(props)
            tilesetx[#tilesetx+1] = tilex
        end
    end
    
    return tilesetx
end

----------------------------------------------------------------------------------------------------
-- Compact a TileLayer
function Loader._compactTileLayer(layer)

    -- Set the ATL properties
    layer.properties.atl_useSpriteBatch = layer.useSpriteBatch
    layer.properties.atl_parallaxX = layer.parallaxX
    layer.properties.atl_parallaxY = layer.parallaxY
    layer.properties.atl_offsetX = layer.offsetX
    layer.properties.atl_offsetY = layer.offsetY

    -- <layer>
    local layerx = {label="layer", xarg = {
        name = layer.name,
        opacity = layer.opacity,
        visible = layer.visible and 1 or 0,
        width = layer.map.width,
        height = layer.map.height,
    }}
    
    -- <data>
    local tiles = {}
    local flipBits = 2^29
    local flipValue 
    for x, y, tile in layer:rectangle(0, 0, layer.map.width-1, layer.map.height-1, true) do
        if tile then
            flipValue = layer._flippedTiles(x,y) and layer._flippedTiles(x,y) * flipBits or 0
            tiles[#tiles+1] = tile.id + flipValue
        else
            tiles[#tiles+1] = 0
        end
    end
    layerx[1] = {label ="data", xarg = {encoding="csv"}, [1] = table.concat(tiles,",")}

    -- <properties>
    if next(layer.properties) then
        layerx[2] = Loader._compactProperties(layer.properties)
    end

    return layerx
end

----------------------------------------------------------------------------------------------------
-- Compact an ObjectLayer
function Loader._compactObjectLayer(layer)

    -- <objectgroup>
    local layerx = {label = "objectgroup", xarg = {
        name = layer.name,
        color = string.format("#%x%x%x", layer.color[1], layer.color[2], layer.color[3]),
        opacity = layer.opacity,
        visible = layer.visible and 1 or 0,
    }}
    
    -- <object>
    for i = 1,#layer.objects do
        object = layer.objects[i]
        layerx[#layerx+1] = Loader._compactObject(layer.objects[i])
    end

    -- <properties>
    if next(layer.properties) then
        layerx[#layerx+1] = Loader._compactProperties(layer.properties)
    end

    return layerx
end

----------------------------------------------------------------------------------------------------
-- Compact an Object
function Loader._compactObject(object)

    -- <object>
    local objectx = {label="object", xarg = {
        name = object.name,
        type = object.type,
        x = object.x,
        y = object.y,
        width = object.width,
        height = object.height,
        gid = object.gid,
        visible = object.visible,
    }}
    
    -- <polyline>
    if object.polyline then
        local polylinex = {label="polyline", xarg = {}}
        local points = {}
        for i = 1,#object.polyline,2 do
            points[#points+1] = object.polyline[i] .. "," .. object.polyline[i+1]
        end
        polylinex.xarg.points = table.concat(points, " ")
        objectx[#objectx+1] = polylinex
    end
    
    -- <polygon>
    if object.polygon then
        local polygonx = {label="polygon", xarg = {}}
        local points = {}
        for i = 1,#object.polygon,2 do
            points[#points+1] = object.polygon[i] .. "," .. object.polygon[i+1]
        end
        polygonx.xarg.points = table.concat(points, " ")
        objectx[#objectx+1] = polygonx
    end

    -- <properties>
    if next(object.properties) then
        objectx[#objectx+1] = Loader.compactProperties(object.properties)
    end
    
    return objectx
end

----------------------------------------------------------------------------------------------------
-- Compact Properties
function Loader._compactProperties(prop)
    
    if not prop then return end
    
    -- <properties>
    local propx = {label="properties", xarg={}}
    
    -- <property>
    for k,v in pairs(prop) do
        propx[#propx+1] = {label="property", xarg={name=k, value=v}}
    end

    return propx
end

----------------------------------------------------------------------------------------------------
-- Return the loader
return Loader


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


