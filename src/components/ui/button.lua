require "src.helperFunctions"

--- @alias text_align
--- | "center"
--- | "left"
--- | "right"

--- @class Button
--- @field name string
--- @field x number
--- @field y number
--- @field w number
--- @field h number
--- @field color table
--- @field centered boolean
--- @field padding number
--- @field text_align text_align
--- @field background_color table
--- @field text_border_color table
--- @field onClick fun(x : number, y : number, mouse_button : number)
Button = {}

function Button:new(params)
    local o = {}
    setmetatable(o, { __index = self })
    o.name = params.name or "Button"
    o.x = params.x or 0
    o.y = params.y or 0
    o.w = params.w or GetTextWidth(params.name)
    o.h = params.h or FontRegular:getHeight() + 6
    o.color = params.color or { 1, 1, 1, 1 }
    o.centered = params.centered or false
    o.padding = params.padding or 0
    o.text_align = params.text_align or "center"
    o.background_color = params.background_color or { 0, 0, 0, 0.3 }
    o.text_border_color = params.text_border_color or { 0, 0, 0, 0.5 }
    o.onClick = params.onClick or function() end
    return o
end

function Button:draw(highlightable)
    local color = self.color or { 1, 1, 1 }
    if highlightable == nil then highlightable = true end

    local x, y = self.x, self.y
    if self.centered then x, y = self.x - self.w / 2, self.y - self.h / 2 end

    love.graphics.setColor(self.background_color)
    love.graphics.rectangle("fill", x - 1, y, self.w + 1, self.h)
    love.graphics.setColor({ 1, 1, 1, 1 })

    local mx, my = GetMousePosition()
    if highlightable and IsMouseWithin(mx, my, x, y, self.w, self.h) then color = { 0.5, 0.5, 1 } end

    y = y + self.h / 2 - FontRegular:getHeight() / 2
    if self.text_align == "left" then x = x + self.padding end
    if self.text_align == "center" then x = x + self.w / 2 - GetTextWidth(self.name) / 2 end
    if self.text_align == "right" then x = x + self.w - GetTextWidth(self.name) - self.padding end
    DrawText(self.name, x, y, color, self.text_border_color)
    love.graphics.setColor({ 1, 1, 1, 1 })
end

function Button:mousePress(x, y, mouse_button)
    local bx, by = self.x, self.y
    if self.centered then bx, by = self.x - self.w / 2, self.y - self.h / 2 end
    if IsMouseWithin(x, y, bx, by, self.w, self.h) then self.onClick(x, y, mouse_button) end
end
