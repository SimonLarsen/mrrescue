--[[
The following module has been heavily modified for Mr. Rescue
does not represent the quality of the original module.

Copyright (c) 2009-2010 Bart Bes

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
]]

local animation = {}
animation.__index = animation

--- Create a new animation
-- Replaces love.graphics.newAnimation
-- @param image The image that contains the frames
-- @param fw The frame width
-- @param fh The frame height
-- @param delay The delay between two frames
-- @param frames The number of frames, 0 for autodetect
-- @return The created animation
function newAnimation(image, fw, fh, delay, frames, callback)
	local a = {}
	a.img = image
	a.frames = {}
	a.delays = {}
	a.timer = 0
	a.position = 1
	a.fw = fw
	a.fh = fh
	a.playing = true
	a.speed = 1
	a.direction = 1
	a.callback = callback
	local imgw = image:getWidth()
	local imgh = image:getHeight()
	if frames == 0 then
		frames = imgw / fw * imgh / fh
	end
	local rowsize = imgw/fw
	for i = 1, frames do
		local row = math.floor((i-1)/rowsize)
		local column = (i-1)%rowsize
		local frame = love.graphics.newQuad(column*fw, row*fh, fw, fh, imgw, imgh)
		table.insert(a.frames, frame)
		table.insert(a.delays, delay)
	end
	return setmetatable(a, animation)
end

--- Update the animation
-- @param dt Time that has passed since last call
function animation:update(dt)
	if not self.playing then return end
	self.timer = self.timer + dt * self.speed
	if self.timer > self.delays[self.position] then
		self.timer = self.timer - self.delays[self.position]
		self.position = self.position + self.direction
		if self.position > #self.frames then
			if self.callback then self.callback() end
			self.position = 1
		elseif self.position < 1 then
			if self.callback then self.callback() end
			self.position = #self.frames
		end
	end
end

--- Draw the animation
-- @param x The X coordinate
-- @param y The Y coordinate
-- @param angle The angle to draw at (radians)
-- @param sx The scale on the X axis
-- @param sy The scale on the Y axis
-- @param ox The X coordinate of the origin
-- @param oy The Y coordinate of the origin
-- @param frame Optional frame to draw instead of current position
-- @param altimg Optional alternative image to draw instead
function animation:draw(x, y, angle, sx, sy, ox, oy, frame, altimg)
	love.graphics.draw(altimg or self.img, self.frames[frame or self.position], x, y, angle, sx, sy, ox, oy)
end

--- Add a frame
-- @param x The X coordinate of the frame on the original image
-- @param y The Y coordinate of the frame on the original image
-- @param w The width of the frame
-- @param h The height of the frame
-- @param delay The delay before the next frame is shown
function animation:addFrame(x, y, w, h, delay)
	local frame = love.graphics.newQuad(x, y, w, h, self.img:getWidth(), self.img:getHeight())
	table.insert(self.frames, frame)
	table.insert(self.delays, delay)
end

--- Play the animation
-- Starts it if it was stopped.
-- Basically makes sure it uses the delays
-- to switch to the next frame.
function animation:play()
	self.playing = true
end

--- Stop the animation
function animation:stop()
	self.playing = false
end

--- Reset
-- Go back to the first frame.
function animation:reset()
	self:seek(1)
end

--- Seek to a frame
-- @param frame The frame to display now
function animation:seek(frame)
	self.position = frame
	self.timer = 0
end

--- Get the currently shown frame
-- @return The current frame
function animation:getCurrentFrame()
	return self.position
end

--- Get the number of frames
-- @return The number of frames
function animation:getSize()
	return #self.frames
end

--- Set the delay between frames
-- @param frame Which frame to set the delay for
-- @param delay The delay
function animation:setDelay(frame, delay)
	self.delays[frame] = delay
end

--- Set the speed
-- @param speed The speed to play at (1 is normal, 2 is double, etc)
function animation:setSpeed(speed)
	self.speed = speed
end

--- Get the width of the current frame
-- @return The width of the current frame
function animation:getWidth()
	return self.frames[self.position]:getWidth()
end

--- Get the height of the current frame
-- @return The height of the current frame
function animation:getHeight()
	return self.frames[self.position]:getHeight()
end

--- Animations_legacy_support
-- @usage Add legacy support, basically set love.graphics.newAnimation again, and allow you to use love.graphics.draw
if Animations_legacy_support then
	love.graphics.newAnimation = newAnimation
	local oldLGDraw = love.graphics.draw
	function love.graphics.draw(item, ...)
		if type(item) == "table" and item.draw then
			item:draw(...)
		else
			oldLGDraw(item, ...)
		end
	end
end
