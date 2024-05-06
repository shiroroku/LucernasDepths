require "src.helperFunctions"

function ErrorScreen(msg)
    love.graphics.reset()
    love.graphics.setFont(FontRegular)
    love.window.setMode(INTERNAL_RES_WIDTH * 2, INTERNAL_RES_HEIGHT, {fullscreen = false, centered =true})
    local err = {}
    local trace = debug.traceback()
    for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") and not l:match("errorScreen.lua") and not l:match("callbacks.lua") and not l:match("xpcall") then
			l = l:gsub("stack traceback:", "")
			table.insert(err, l)
		end
	end
    local p = table.concat(err, "\n")
	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

    return function()
        love.event.pump()

        for e, a, b, c in love.event.poll() do
            if e == "quit" then
                return 1
            elseif e == "keypressed" and a == "escape" then
                return 1
            end
        end

        love.graphics.clear(0, 0, 0)
        DrawText("Oh no! ;-;", 20, 20)
        DrawText(tostring(msg), 20, 45, {0.5,0.5,1})
        DrawText("Trace:", 20, 70, {0.5,0.5,0.5})
        DrawText(tostring(p), 20, 80)
        love.graphics.present()

        if love.timer then
            love.timer.sleep(0.1)
        end
    end
end
