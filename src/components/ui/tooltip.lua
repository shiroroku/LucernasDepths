require "src.components.ui.panel"

ToolTip = {}

function ToolTip:new(params)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.text = params.text or ""
    -- x, y, w, h, are for packing tooltip within that space, location and size are calculated
    o.x = params.x or 0
    o.y = params.y or 0
    o.w = params.w or INTERNAL_RES_WIDTH
    o.h = params.h or INTERNAL_RES_HEIGHT
    o.padding = params.padding or 8
    o.visible = false
    o.delay = 100
    o._delay_time = -1
    return o
end

function ToolTip:draw()
    -- parent component tells us where to draw
    if self.visible then
        local mx, my    = GetMousePosition()
        --calculate newline sizes
        local _, lines  = self.text:gsub("\n", "")
        lines           = lines + 1

        local tooltip_w = GetTextWidth(self.text) + self.padding
        local tooltip_h = FontRegular:getHeight() * lines + self.padding
        local x, y      = mx - tooltip_w, my - tooltip_h

        if mx <= self.x + tooltip_w then x = self.x end
        if my <= self.y + tooltip_h then y = self.y end

        love.graphics.setColor({ 0.3, 0.3, 0.3, 0.75 })
        DrawPanel(x, y, tooltip_w, tooltip_h)
        love.graphics.setColor({ 1, 1, 1, 1 })
        DrawText(self.text, x + self.padding / 2, y + self.padding / 2)
    end
end

-- todo: should use dt
function ToolTip:update(dt)
    if self._delay_time == -1 then return end

    if self._delay_time >= self.delay then
        self.visible = true
    else
        self._delay_time = self._delay_time + 1
    end
end

function ToolTip:onHoverEnter()
    if not self.visible and self._delay_time == -1 then
        self._delay_time = 0
    end
end

function ToolTip:onHoverExit()
    self.visible = false
    self._delay_time = -1
end
