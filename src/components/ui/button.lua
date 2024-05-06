require "src.helperFunctions"

Button = {}

function Button:new(params)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = params.name or "Button"
    o.x = params.x or 0
    o.y = params.y or 0
    o.color = params.color or { 1, 1, 1, 1 }
    o.centered = params.centered
    o.onClick = params.onClick or function() end
    return o
end

function Button:draw(highlightable)
    local color = self.color or { 1, 1, 1 }
    if highlightable == nil then highlightable = true end

    local x, y = self.x, self.y
    if self.centered == true then x = self.x - GetTextWidth(self.name) / 2 end

    love.graphics.setColor({ 0, 0, 0, 0.15 })
    love.graphics.rectangle("fill", x - 2, y - 2, GetTextWidth(self.name) + 4, FontRegular:getHeight() + 4)
    love.graphics.setColor({ 1, 1, 1, 1 })

    local mx, my = GetMousePosition()
    if highlightable and IsMouseWithin(mx, my, x, y, GetTextWidth(self.name), FontRegular:getHeight()) then
        color = { 0.5, 0.5, 1 }
    end

    DrawText(self.name, x, y, color)
    love.graphics.setColor({ 1, 1, 1, 1 })
end

function Button:mousePress(x, y, mouse_button)
    local bx, by = self.x, self.y
    if self.centered == true then bx = self.x - GetTextWidth(self.name) / 2 end
    if IsMouseWithin(x, y, bx, by, GetTextWidth(self.name), FontRegular:getHeight()) then self.onClick(x, y, mouse_button) end
end
