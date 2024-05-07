require "src.components.ui.panel"
require "src.lang"

--- @class MessageBox
--- @field text string
--- @field x number
--- @field y number
--- @field visible boolean
--- @field onClose function
--- @field button Button
MessageBox = {}

function MessageBox:new(params)
    local o = {}
    setmetatable(o, { __index = self })
    o.x = params.x or INTERNAL_RES_WIDTH / 2
    o.y = params.y or INTERNAL_RES_HEIGHT / 2
    o.text = params.text or "Message Key!"
    o.visible = params.visible or false
    o.onClose = params.onClose or function() end
    o.button = params.button or Button:new {
        name = GetTranslation("messagebox.ok"),
        centered = true,
        x = o.x,
        y = o.y + FontRegular:getHeight(),
        onClick = function()
            self:hide()
            o.onClose()
        end
    }
    return o
end

function MessageBox:draw()
    if not self.visible then return end
    local panel_w = 180
    DrawPanel(self.x - panel_w / 2, self.y - 30, panel_w, 60)
    DrawText(self.text, self.x - FontRegular:getWidth(self.text) / 2, self.y - FontRegular:getHeight() * 1.5)
    self.button:draw()
end

function MessageBox:hide()
    self.visible = false
end

function MessageBox:show()
    self.visible = true
end

function MessageBox:keyPress(key, scancode, isrepeat)
    if not self.visible then return end
    if key == CLIENT_CONFIG.key_binds.back then
        self:hide()
        self.onClose()
    end
    return true
end

function MessageBox:mousePress(x, y, mouse_button)
    if not self.visible then return end
    self.button:mousePress(x, y, mouse_button)
    return true
end
