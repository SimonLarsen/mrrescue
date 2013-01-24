splash = {}

lg = love.graphics

function splash.draw()
	lg.push()
	lg.scale(SCALE)

	local alpha = math.min(math.floor(0.8*transition_time*8)/8, 1)
	lg.setColor(255,255,255,alpha*255)
	lg.drawq(img.splash, quad.splash, 0,0)
	lg.setColor(255,255,255,255)

	lg.pop()
end

function splash.update(dt)
	transition_time = transition_time + dt
end
