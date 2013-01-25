splash = {}

lg = love.graphics

function splash.draw()
	lg.push()
	lg.scale(SCALE)

	if transition_time < 1.3 then
		local alpha = math.min(math.floor(0.8*transition_time*8)/8, 1)
		lg.setColor(255,255,255,alpha*255)
		lg.drawq(img.splash, quad.splash, 0,0)
		lg.setColor(255,255,255,255)
	else
		lg.drawq(img.splash, quad.splash, 0,0)
		lg.setFont(font.bold)
		if transition_time % 1.6 < 0.8 then
			lg.print("PRESS START", 150, 140)
		end
	end

	lg.pop()
end

function splash.update(dt)
	transition_time = transition_time + dt
end
