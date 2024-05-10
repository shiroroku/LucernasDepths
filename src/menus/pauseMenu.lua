require "src.components.ui.button"
require "src.menus.optionsMenu"
require "src.lang"



---@class PauseMenuScene : Scene
---@field return_function function
PauseMenuScene = Scene:new()

---@param return_function function
---@return PauseMenuScene
function PauseMenuScene:new(return_function)
    local o = Scene:new()
    setmetatable(o, { __index = self })
    self.return_function = return_function
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

function PauseMenuScene:load()
    Scene.load(self)
    self.buttons = {
        Button:new {
            name = GetTranslation("pause.continue"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 110,
            w = 130,
            onClick = self.return_function,
            centered = true,
            text_border_color = { 0, 0, 0, 1 },
            background_color = { 0, 0, 0, 0.5 }
        },
        Button:new {
            name = GetTranslation("pause.options"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 130,
            w = 130,
            onClick = function() Scene.changeSubScene(self, OptionsMenuScene:new(function() Scene.changeSubScene(self, nil) end)) end,
            centered = true,
            text_border_color = { 0, 0, 0, 1 },
            background_color = { 0, 0, 0, 0.5 }
        },
        Button:new {
            name = GetTranslation("pause.quit_to_menu"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 170,
            w = 130,
            onClick = function()
                self.return_function() -- so the pause menu isnt open if we reconnect
                SetScene(MainMenuScene)
            end,
            centered = true,
            text_border_color = { 0, 0, 0, 1 },
            background_color = { 0, 0, 0, 0.5 }
        },
        Button:new {
            name = GetTranslation("pause.quit_to_desktop"),
            x = INTERNAL_RES_WIDTH / 2,
            y = 190,
            w = 130,
            onClick = function() love.event.quit() end,
            centered = true,
            text_border_color = { 0, 0, 0, 1 },
            background_color = { 0, 0, 0, 0.5 }
        }
    }
end

function PauseMenuScene:update(dt)
    Scene.update(self, dt)
    return true
end

function PauseMenuScene:draw()
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

    Scene.draw(self)
end

function PauseMenuScene:keyPress(key, scancode, isrepeat)
    if Scene.keyPress(self, key, scancode, isrepeat) then return true end
    if key == CLIENT_CONFIG.key_binds.back then self.return_function() end
    return true
end

function PauseMenuScene:mousePress(x, y, mouse_button)
    if Scene.mousePress(self, x, y, mouse_button) then return true end
    for _, button in pairs(self.buttons) do button:mousePress(x, y, mouse_button) end
    return true
end
