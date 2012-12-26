Item = {}
Item.__index = Item

function Item.create(x,y,id)
	local self = setmetatable({}, Item)

	self.alive = true
	self.x, self.y = x,y
	self.id = id
	self.bbox = {x = x+4, y = y, w = 7, h = 16}

	if id == "coolant" then
		self.anim = newAnimation(img.item_coolant, 16, 20, 0.12, 6)
	elseif id == "suit" then
		self.anim = newAnimation(img.item_suit,    16, 20, 0.12, 6)
	elseif id == "tank" then
		self.anim = newAnimation(img.item_tank,    16, 20, 0.12, 6)
	elseif id == "reserve" then
		self.anim = newAnimation(img.item_reserve, 16, 20, 0.12, 6)
	end

	return self
end

function Item:update(dt)
	self.anim:update(dt)
end

function Item:draw()
	self.anim:draw(self.x, self.y)
end

function Item:getBBox()
	return self.bbox
end
