---@diagnostic disable: param-type-mismatch
require "src.helperFunctions"
require "src.components.ui.button"
require "src.menus.optionsMenu"
require "src.components.ui.textbox"
require "src.lang"
require "src.components.scene"

MainMenuSceneConstructor = Scene:extend {
    init = function(self)
        Scene.init(self, "Main Menu")
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
                onClick = function() SetScene(InGameSceneConstructor()) end,
            },
            Button:new {
                name = GetTranslation("main_menu.options"),
                x = INTERNAL_RES_WIDTH / 2,
                y = 130,
                w = 100,
                centered = true,
                onClick = function() Scene.ChangeSubScene(self, OptionsMenuConstructor(function() Scene.ChangeSubScene(self, {}) end)) end,
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
    end,

    Update = function(self, dt)
        if Scene.Update(self, dt) then return true end

        self.bg_scroll = self.bg_scroll + dt * 60
        if self.bg_scroll >= 999999 then self.bg_scroll = 0 end
    end,

    Draw = function(self)
        love.graphics.draw(self.bgTexture, love.graphics.newQuad(self.bg_scroll * 0.25, self.bg_scroll * 0.2, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, self.bgTexture:getDimensions()))
        love.graphics.setColor({ 1, 1, 1, 0.5 })
        love.graphics.draw(self.bgTextureOverlay, love.graphics.newQuad(self.bg_scroll * 0.1, self.bg_scroll * 0.1, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, self.bgTextureOverlay:getDimensions()))
        love.graphics.setColor({ 1, 1, 1, 1 })

        love.graphics.setFont(FontBig)
        DrawText("Lucerna's Depths", INTERNAL_RES_WIDTH * 0.5 - FontBig:getWidth("Lucerna's Depths") * 0.5, 35)
        love.graphics.setFont(FontRegular)

        for _, button in pairs(self.buttons) do button:draw(true) end

        Scene.Draw(self)
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if Scene.KeyPress(self, key, scancode, isrepeat) then return true end
        --todo key controls for ui elements

        if key == "f5" and love.keyboard.isDown("lctrl", "rctrl") then
            SetScene(DebugWorldGenScene)
        end
    end,

    MousePress = function(self, x, y, mouse_button)
        if Scene.MousePress(self, x, y, mouse_button) then return true end

        -- buttons
        for _, button in pairs(self.buttons) do button:mousePress(x, y, mouse_button) end
    end,
}
