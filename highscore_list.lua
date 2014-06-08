highscore_list = {}

local lg = love.graphics

function highscore_list.enter(hllevel, hlpos)
	state = STATE_HIGHSCORE_LIST
	playMusic("happyfeerings")
	highscore_list.level = hllevel or 1
	highscore_list.hllevel = hllevel or 0
	highscore_list.hlpos = hlpos or 0
end

function highscore_list.update(dt)
	updateKeys()
end

function highscore_list.draw()
	lg.push()
	lg.scale(config.scale)

	drawBox(12, 19, 233, 172)
	lg.draw(img.highscore_panes, quad.highscore_pane[highscore_list.level], 0, 9)

	local scores = highscores[highscore_list.level]
	for i=1, 10 do
		if i < 10 then
			lg.print(i..".", 31, 14+i*16)
		else
			lg.print(i..".", 23, 14+i*16)
		end
		if scores[i] then
			if highscore_list.level == highscore_list.hllevel
			and highscore_list.hlpos == i then
				lg.setColor(25,118,115,255)
				lg.print(scores[i].name,   48, 14+i*16)
				lg.print(scores[i].score, 105, 14+i*16)
				lg.setColor(255,255,255,255)
			else
				lg.print(scores[i].name,   48, 14+i*16)
				lg.print(scores[i].score, 105, 14+i*16)
			end
		else
			lg.print("---", 48, 14+i*16)
		end
	end

	lg.pop()
end

function highscore_list.keypressed(k, uni)
	if k == "right" then
		highscore_list.level = wrap(highscore_list.level + 1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		highscore_list.level = wrap(highscore_list.level - 1, 1, 3)
		playSound("blip")
	elseif k == "return" or k == "escape" then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end

function highscore_list.action(k)
	if k == "right" then
		highscore_list.level = wrap(highscore_list.level + 1, 1, 3)
		playSound("blip")
	elseif k == "left" then
		highscore_list.level = wrap(highscore_list.level - 1, 1, 3)
		playSound("blip")
	elseif k == "jump" or k == "action" then
		playSound("confirm")
		playMusic("opening")
		mainmenu.enter()
	end
end
