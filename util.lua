--- Collides two AABBs
-- @param b1 First bounding box
-- @param b2 Second bounding box
-- @return True if they overlap
function collideBoxes(b1,b2)
	if b1.x > b2.x+b2.w or b1.x+b1.w < b2.x
	or b1.y > b2.y+b2.h or b1.y+b1.h < b2.y then
		return false
	else
		return true
	end
end

function table.random(t)
	return t[math.random(#t)]
end

function math.sign(n)
	if n < 0 then
		return -1
	elseif n > 0 then
		return 1
	else
		return 0
	end
end
