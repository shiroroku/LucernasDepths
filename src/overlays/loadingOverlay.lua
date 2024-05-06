require "src.helperFunctions"
require "src.lang"

local defaultFadeDuration = 40 -- How long it takes to fade out

local visible = false          -- When false, it lets fadeTimer tick down
local fadeTimer = 0            -- When 0 nothing will be rendered or updated
local spinnySprite = love.graphics.newImage("resources/textures/ui/loading.png")
local spriteAngle = 0

function DrawLoadingScreen()
    if fadeTimer > 0 then
        local fade = fadeTimer / defaultFadeDuration
        -- Set transparency and background rect (clear doesnt work with alpha)
        love.graphics.setColor(0.05, 0.05, 0.05, fade)
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)

        -- Draw spinny sprite thingy
        love.graphics.setColor(1, 1, 1, fade)
        love.graphics.draw(spinnySprite, INTERNAL_RES_WIDTH / 2, INTERNAL_RES_HEIGHT / 2, spriteAngle, 1, 1, 8, 8)
        DrawText(GetTranslation("loading_screen.loading"), INTERNAL_RES_WIDTH / 2 - GetTextWidth(GetTranslation("loading_screen.loading")) / 2, INTERNAL_RES_HEIGHT / 2 + 30, { 1, 1, 1, fade }, { 0, 0, 0, fade })
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function UpdateLoadingScreen(dt)
    if fadeTimer > 0 then
        spriteAngle = spriteAngle + 8 * math.pi * dt
        if not visible then
            fadeTimer = fadeTimer - 1
        end
    end
end

function ShowLoadingScreen()
    visible = true
    fadeTimer = defaultFadeDuration
end

function HideLoadingScreen(dont_fade)
    visible = false
    if dont_fade then
        fadeTimer = 0
    end
end
