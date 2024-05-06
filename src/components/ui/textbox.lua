require "src.components.ui.panel"
require "src.helperFunctions"
local utf8 = require("utf8")

TextBox = {}

local beam_blink_duration = 40
local focused_tint = 0.4

function TextBox:new(params)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = params.x or 0
    o.y = params.y or 0
    o.w = params.w or 0
    o.h = params.h or 16
    o.default_text = params.default_text or ""
    o.text = params.text or ""
    o.beam_blink = beam_blink_duration
    o.onSubmit = params.onSubmit or function() end
    return o
end

function TextBox:Flash(color)
    self.flash_color = color
    self.flash = 10
end

function TextBox:draw()
    local tint = 0.3
    if self.focused then
        tint = focused_tint
    end
    love.graphics.setColor({ tint, tint, tint, 1 })
    DrawPanel(self.x, self.y, self.w, self.h, PanelIn)
    love.graphics.setColor({ 1, 1, 1, 1 })
    love.graphics.setScissor(self.x + 2, self.y + 2, self.w - 2, self.h - 2)
    local text = self.text
    local textcolor = { 1, 1, 1, 1 }

    if self.flash ~= 0 then textcolor = self.flash_color end

    local text_x_offset = 0
    if GetTextWidth(text) >= self.w - 10 then
        text_x_offset = self.w - GetTextWidth(text) - 10
    end

    if not self.focused and self.default_text ~= "" and text == "" then
        text = self.default_text
        textcolor = { 0.6, 0.6, 0.6, 1 }
    end
    if self.focused and self.beam then text = text .. "|" end
    DrawText(text, self.x + 4 + text_x_offset, self.y + FontRegular:getHeight() * 0.5 - 1, textcolor)
    love.graphics.setScissor()
end

function TextBox:update(dt)
    if self.flash and self.flash > 0 then self.flash = self.flash - 1 end

    if self.focused then
        self.beam = self.beam_blink >= 0
        if self.beam_blink <= -beam_blink_duration then
            self.beam_blink = beam_blink_duration
        end
        self.beam_blink = self.beam_blink - 1
    elseif self.beam_blink ~= 0 then
        self.beam_blink = beam_blink_duration
        self.beam = false
    end
end

function TextBox:textInput(text)
    if self.focused then self.text = self.text .. text end
end

function TextBox:keyPress(key, scancode, isrepeat)
    if self.focused then
        if key == "backspace" and love.keyboard.isDown("lctrl", "rctrl") then
            self.text = ""
            return true
        end
        if key == "backspace" then
            local byteoffset = utf8.offset(self.text, -1)
            if byteoffset then
                self.text = string.sub(self.text, 1, byteoffset - 1)
            end
            return true
        end
        if key == CLIENT_CONFIG.key_binds.back then
            self.focused = false
            return true
        end
        if key == CLIENT_CONFIG.key_binds.select then
            self.onSubmit(self)
            return true
        end
        if key == "v" and love.keyboard.isDown("lctrl", "rctrl") then
            self.text = self.text .. love.system.getClipboardText():gsub("\n", "")
            self:Flash({ 0.2, 1, 0.2 })
            return true
        end
        if key == "c" and love.keyboard.isDown("lctrl", "rctrl") then
            love.system.setClipboardText(self.text)
            self:Flash({ 1, 0.2, 0.2 })
            return true
        end
    end
    return false
end

function TextBox:mousePress(x, y, mouse_button)
    if IsMouseWithin(x, y, self.x, self.y, self.w, self.h) then self.focused = true else self.focused = false end
end
