Entity = {alive = false, solid = false}
Entity.__index = Entity

function Entity:update(dt)

end

function Entity:shot(dir)

end

function Entity:draw()

end

function Entity:collide(box)
	return false
end
