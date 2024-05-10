require "src.helperFunctions"
require "src.components.ui.button"
require "src.menus.optionsMenu"
require "src.lang"
require "src.components.scene"
require "src.scenes.inGameScene"

---@class MainMenuScene : Scene
MainMenuScene = Scene:new()

function MainMenuScene:new()
    local o = Scene:new()
    setmetatable(o, { __index = self })
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

function MainMenuScene:load()
    Scene.load(self)
    self.bgTexture = love.graphics.newImage("resources/textures/bg.png")
    self.bgTextureOverlay = love.graphics.newImage("resources/textures/bg_1.png")
    self.bgTexture:setWrap("repeat")
    self.bgTextureOverlay:setWrap("repeat")
    self.bg_scroll = 0
    self.buttons = {
        Button:new {
            name = GetTranslation("main_menu.connect"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 110,
            w = 100,
            centered = true,
            onClick = function() SetScene(InGameScene:new()) end,
        },
        Button:new {
            name = GetTranslation("main_menu.options"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 130,
            w = 100,
            centered = true,
            onClick = function() Scene.changeSubScene(self, OptionsMenuScene:new(function() Scene.changeSubScene(self, nil) end)) end,
        },
        Button:new {
            name = GetTranslation("main_menu.quit"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 150,
            w = 100,
            centered = true,
            onClick = function() love.event.quit() end,
        }
    }
end

function MainMenuScene:update(dt)
    if Scene.update(self, dt) then return true end
    self.bg_scroll = self.bg_scroll + dt * 60
    if self.bg_scroll >= 999999 then self.bg_scroll = 0 end
end

function MainMenuScene:draw()
    ---@diagnostic disable-next-line: param-type-mismatch
    love.graphics.draw(self.bgTexture, love.graphics.newQuad(self.bg_scroll * 0.25, self.bg_scroll * 0.2, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, self.bgTexture:getDimensions()))
    love.graphics.setColor({ 1, 1, 1, 0.5 })
    ---@diagnostic disable-next-line: param-type-mismatch
    love.graphics.draw(self.bgTextureOverlay, love.graphics.newQuad(self.bg_scroll * 0.1, self.bg_scroll * 0.1, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, self.bgTextureOverlay:getDimensions()))
    love.graphics.setColor({ 1, 1, 1, 1 })

    love.graphics.setFont(FontBig)
    DrawText("Lucerna's Depths", INTERNAL_RES_WIDTH * 0.5 - FontBig:getWidth("Lucerna's Depths") * 0.5, 35)
    love.graphics.setFont(FontRegular)

    for _, button in pairs(self.buttons) do button:draw(true) end
    Scene.draw(self)
end

function MainMenuScene:keyPress(key, scancode, isrepeat)
    if Scene.keyPress(self, key, scancode, isrepeat) then return true end
    if key == "f5" and love.keyboard.isDown("lctrl", "rctrl") then
        SetScene(DebugWorldGenScene:new())
    end
end

function MainMenuScene:mousePress(x, y, mouse_button)
    if Scene.mousePress(self, x, y, mouse_button) then return true end
    for _, button in pairs(self.buttons) do button:mousePress(x, y, mouse_button) end
end
