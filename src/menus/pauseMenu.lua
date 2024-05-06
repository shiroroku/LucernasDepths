require "src.components.ui.button"
require "src.menus.optionsMenu"
require "src.lang"

PauseMenuConstructor = Scene:extend {
    init = function(self, return_function)
        Scene.init(self, "Pause Menu")
        self.return_function = return_function
        self.buttons = {
            Button:new {
                name = GetTranslation("pause.continue"),
                x = INTERNAL_RES_WIDTH / 2,
                y = 110,
                onClick = self.return_function,
                centered = true
            },
            Button:new {
                name = GetTranslation("pause.options"),
                x = INTERNAL_RES_WIDTH / 2,
                y = 130,
                onClick = function() Scene.ChangeSubScene(self, OptionsMenuConstructor(function() Scene.ChangeSubScene(self, {}) end)) end,
                centered = true
            },
            Button:new {
                name = GetTranslation("pause.quit_to_menu"),
                x = INTERNAL_RES_WIDTH / 2,
                y = 170,
                onClick = function()
                    self.return_function() -- so the pause menu isnt open if we reconnect
                    SetScene(MainMenuScene)
                end,
                centered = true
            },
            Button:new {
                name = GetTranslation("pause.quit_to_desktop"),
                x = INTERNAL_RES_WIDTH / 2,
                y = 190,
                onClick = function() love.event.quit() end,
                centered = true
            }
        }
    end,

    Update = function(self, dt)
        Scene.Update(self, dt)
        return true
    end,

    Draw = function(self)
        -- background tint
        love.graphics.setColor({ 0, 0, 0, 0.75 })
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
        love.graphics.setColor({ 1, 1, 1, 1 })

        -- title
        love.graphics.setFont(FontBig)
        local paused_text = GetTranslation("pause.paused")
        DrawText(paused_text, INTERNAL_RES_WIDTH / 2 - GetTextWidth(paused_text, FontBig) / 2, 50)
        love.graphics.setFont(FontRegular)

        for _, button in pairs(self.buttons) do button:draw() end

        Scene.Draw(self)
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if Scene.KeyPress(self, key, scancode, isrepeat) then return true end
        if key == CLIENT_CONFIG.key_binds.back then self.return_function() end
        return true
    end,

    MousePress = function(self, x, y, mouse_button)
        if Scene.MousePress(self, x, y, mouse_button) then return true end
        for _, button in pairs(self.buttons) do button:mousePress(x, y, mouse_button) end
        return true
    end,

}
