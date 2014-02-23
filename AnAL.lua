--[[
Copyright (c) 2009-2013 Bart Bes

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
function newAnimation(image, fw, fh, delay, frames)
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
	a.mode = 1
	a.direction = 1
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
		self.position = self.position + 1 * self.direction
		if self.position > #self.frames then
			if self.mode == 1 then
				self.position = 1
			elseif self.mode == 2 then
				self.position = self.position - 1
				self:stop()
			elseif self.mode == 3 then
				self.direction = -1
				self.position = self.position - 1
			end
		elseif self.position < 1 and self.mode == 3 then
			self.direction = 1
			self.position = self.position + 1
		elseif self.position < 1 and self.mode == 4 then
			self.position = #self.frames
		end
	end
end

--- Draw the animation
local drawq = love.graphics.drawq or love.graphics.draw
function animation:draw(...)
	return drawq(self.img, self.frames[self.position], ...)
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
	return self:seek(1)
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
	return (select(3, self.frames[self.position]:getViewport()))
end

--- Get the height of the current frame
-- @return The height of the current frame
function animation:getHeight()
	return (select(4, self.frames[self.position]:getViewport()))
end

--- Set the play mode
-- Could be "loop" to loop it, "once" to play it once, or "bounce" to play it, reverse it, and play it again (looping)
-- @param mode The mode: one of the above
function animation:setMode(mode)
	if mode == "loop" then
		self.mode = 1
		self.direction = 1
	elseif mode == "once" then
		self.mode = 2
		self.direction = 1
	elseif mode == "bounce" then
		self.mode = 3
	elseif mode == "reverse" then
		self.mode = 4
		self.direction = -1
	end
end

--- Animations_legacy_support
-- @usage Add legacy support, basically set love.graphics.newAnimation again, and allow you to use love.graphics.draw
if Animations_legacy_support then
	love.graphics.newAnimation = newAnimation
	local oldLGDraw = love.graphics.draw
	function love.graphics.draw(item, ...)
		if type(item) == "table" and item.draw then
			return item:draw(...)
		else
			return oldLGDraw(item, ...)
		end
	end
end
