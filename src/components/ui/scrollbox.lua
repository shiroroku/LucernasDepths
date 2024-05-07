require "src.helperFunctions"
require "src.components.ui.button"
require "src.components.ui.panel"

--- @alias item_type
--- | "boolean"
--- | "key"

--- @class ScrollBoxItem
--- @field name string
--- @field centered boolean
--- @field type item_type
--- @field tooltip ToolTip
--- @field onChange fun(scrollbox : ScrollBox, item : ScrollBoxItem)
--- @field enabled boolean?
--- @field key string?

--- @class ScrollBox
--- @field x number
--- @field y number
--- @field w number
--- @field h number
--- @field percent number
--- @field item_constructor fun() : ScrollBoxItem[]
--- @field items ScrollBoxItem[]
--- @field _up_sprite love.Image
--- @field _down_sprite love.Image
--- @field _x_sprite love.Image
ScrollBox = {}

local _item_height = 18
local _sprite_res = 16
local _scroll_amount = 0.2

function ScrollBox:new(params)
    local o = {}
    setmetatable(o, { __index = self })
    o._up_sprite = love.graphics.newImage("resources/textures/ui/arrow_up.png")
    o._down_sprite = love.graphics.newImage("resources/textures/ui/arrow_down.png")
    o._x_sprite = love.graphics.newImage("resources/textures/ui/x.png")
    o.x = params.x or 0
    o.y = params.y or 0
    o.w = params.w or 0
    o.h = params.h or 0
    o.percent = params.percent or 0
    o.item_constructor = params.item_constructor
    o.items = params.item_constructor()
    return o
end

local function ItemOverflowAmount(scrollbox)
    local count = 0
    for _ in pairs(scrollbox.items) do count = count + 1 end
    local item_height = _item_height * count
    if item_height < scrollbox.h then
        return 0
    end
    return item_height - scrollbox.h + 4
end


local function CantScroll(scrollbox)
    if ItemOverflowAmount(scrollbox) == 0 then
        return true
    end
end


local function Scroll(scrollbox, percent)
    scrollbox.percent = math.min(1.0, math.max(0.0, scrollbox.percent + percent))
end


function ScrollBox:refreshItems()
    self.refresh = true
end

function ScrollBox:draw()
    -- main panel
    DrawPanel(self.x, self.y, self.w - _sprite_res, self.h, PanelIn)

    -- items
    local scroll_offset = 2 - ((ItemOverflowAmount(self)) * self.percent)
    love.graphics.setScissor(self.x + 2, self.y + 1, self.w - 2, self.h - 3)
    local dark_panel = false
    for _, item in pairs(self.items) do
        dark_panel = not dark_panel
        if dark_panel then -- alternating background panel
            love.graphics.setColor({ 0, 0, 0, 0.15 })
            love.graphics.rectangle("fill", self.x, self.y + scroll_offset, self.w, _item_height)
            love.graphics.setColor({ 1, 1, 1, 1 })
        end

        -- item types
        local x_offset = 6
        if item.centered then
            x_offset = self.w * 0.5 - GetTextWidth(item.name) * 0.5
        end
        DrawText(item.name, self.x + x_offset,
            self.y + scroll_offset + (_item_height * 0.5 - FontRegular:getHeight() * 0.5))

        -- check box/boolean
        if item.type == "boolean" then
            local y_offset = _item_height * 0.5 - _sprite_res * 0.5
            local x_offset = -3
            DrawPanel(self.x + self.w - _sprite_res * 2 + x_offset, self.y + scroll_offset + y_offset, _sprite_res, _sprite_res,
                PanelIn)
            if item.enabled == true then
                love.graphics.draw(self._x_sprite, self.x + self.w - _sprite_res * 2 + x_offset, self.y + scroll_offset + y_offset)
            end
        end

        -- control input
        if item.type == "key" then
            local box_width = 64
            local y_offset = self.y + scroll_offset + 1
            local x_offset = self.x + self.w - box_width - 16 - 3
            love.graphics.setColor({ 0.3, 0.3, 0.3, 1 })
            DrawPanel(x_offset, y_offset, box_width, 16, PanelIn)
            love.graphics.setColor({ 1, 1, 1, 1 })
            local key = item.key or "none"
            DrawText(key, x_offset + box_width * 0.5 - GetTextWidth(key) * 0.5,
                y_offset + FontRegular:getHeight() * 0.5 - 2)
        end

        scroll_offset = scroll_offset + _item_height
    end

    -- tooltips, logic is handled in update
    for _, item in pairs(self.items) do
        if item.tooltip then
            item.tooltip:draw()
        end
    end

    love.graphics.setScissor()

    -- fade top and bottom
    love.graphics.setColor({ 0, 0, 0, 0.15 })
    love.graphics.rectangle("fill", self.x, self.y, self.w, 8)
    love.graphics.rectangle("fill", self.x, self.y, self.w, 4)
    love.graphics.rectangle("fill", self.x, self.y + self.h - 8, self.w, 8)
    love.graphics.rectangle("fill", self.x, self.y + self.h - 4, self.w, 4)
    love.graphics.setColor({ 1, 1, 1, 1 })

    -- scrollbar
    DrawPanel(self.x + self.w - _sprite_res, self.y + _sprite_res, _sprite_res, self.h - _sprite_res * 2, PanelIn)
    DrawPanel(self.x + self.w - _sprite_res, self.y, _sprite_res, _sprite_res)
    love.graphics.draw(self._up_sprite, self.x + self.w - _sprite_res, self.y)
    DrawPanel(self.x + self.w - _sprite_res, self.y + self.h - _sprite_res, _sprite_res, _sprite_res)
    love.graphics.draw(self._down_sprite, self.x + self.w - _sprite_res, self.y + self.h - _sprite_res)

    -- scroll control
    local control_size = 32
    if CantScroll(self) then
        control_size = self.h - _sprite_res * 2
    end
    local control_y = (self.h - _sprite_res * 2 - control_size) * self.percent
    DrawPanel(self.x + self.w - _sprite_res, self.y + control_y + _sprite_res, _sprite_res, control_size)

    -- select key overlay
    if self.capture_key ~= nil then
        love.graphics.setColor({ 0, 0, 0, 0.5 })
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
        love.graphics.setColor({ 1, 1, 1, 1 })
        local text = "Press a key..."
        DrawText(text, INTERNAL_RES_WIDTH * 0.5 - GetTextWidth(text) * 0.5,
            INTERNAL_RES_HEIGHT * 0.5 + FontRegular:getHeight() * 0.5 - 3)
    end
end

function ScrollBox:update(dt)
    local mx, my = GetMousePosition()

    -- scrollbar dragging
    if love.mouse.isDown(1) then
        if CantScroll(self) then
            return
        end
        local control_size = 32
        if self.grabbed or IsMouseWithin(mx, my, self.x + self.w - _sprite_res, self.y + _sprite_res, _sprite_res, self.h - _sprite_res * 2) then
            local mouse_y = my + (self.percent - 1) * control_size / 2
            self.percent = math.min(1.0, math.max(0.0, (mouse_y - control_size) / (self.h - _sprite_res * 2 - control_size + self.y)))
            if self.grabbed ~= true then self.grabbed = true end -- ? grabbed will be true?
        end
    else
        if self.grabbed then
            self.grabbed = false
        end
    end

    -- hacky method to refresh items next frame for stuff like fullscreen
    if self.refresh then
        self.items = self.item_constructor()
        self.refresh = false
    end

    -- tooltips
    local scroll_offset = 2 - ((ItemOverflowAmount(self)) * self.percent)
    for _, item in pairs(self.items) do
        if item.tooltip then
            item.tooltip:update(dt)
            if IsMouseWithin(mx, my, self.x, self.y + scroll_offset, self.w - 16, _item_height) then
                item.tooltip:onHoverEnter()
            else
                item.tooltip:onHoverExit()
            end
        end
        scroll_offset = scroll_offset + _item_height
    end
end

function ScrollBox:mouseWheelScroll(x, y)
    -- scrollbar mouse scrolling
    if CantScroll(self) then
        return
    end
    local mx, my = GetMousePosition()
    if IsMouseWithin(mx, my, self.x, self.y, self.w, self.h) then
        if y > 0 then
            Scroll(self, -_scroll_amount)
        elseif y < 0 then
            Scroll(self, _scroll_amount)
        end
    end
end

function ScrollBox:keyPress(key, scancode, isrepeat)
    --key input for setting controls
    if self.capture_key ~= nil then
        self.items[self.capture_key].key = key
        self.items[self.capture_key].onChange(self, self.items[self.capture_key])
        self.capture_key = nil
        return true
    end

    return false
end

function ScrollBox:mousePress(x, y, mouse_button)
    local scroll_offset = 2 - ((ItemOverflowAmount(self)) * self.percent)
    for k, item in pairs(self.items) do
        -- boolean boxes
        if item.type == "boolean" then
            local check_y_offset = _item_height * 0.5 - _sprite_res * 0.5
            local check_x_offset = -3
            local y_pos = self.y + scroll_offset + check_y_offset
            if y_pos <= self.h then
                if IsMouseWithin(x, y, self.x + self.w - _sprite_res * 2 + check_x_offset, y_pos, _sprite_res, _sprite_res) then
                    if item.enabled ~= true then
                        item.enabled = true
                    else
                        item.enabled = false
                    end
                    if item.onChange ~= nil then
                        item.onChange(self, item)
                    end
                end
            end
        end

        if item.type == "key" then
            local box_width = 64
            local y_offset = self.y + scroll_offset + 1
            if y_offset <= self.h then
                local x_offset = self.x + self.w - box_width - 16 - 3
                if IsMouseWithin(x, y, x_offset, y_offset, box_width, 16) then
                    self.capture_key = k
                end
            end
        end
        scroll_offset = scroll_offset + _item_height
    end

    -- scrollbar arrow presses
    if CantScroll(self) then
        return
    end
    if IsMouseWithin(x, y, self.x + self.w - _sprite_res, self.y, _sprite_res, _sprite_res) then
        Scroll(self, -_scroll_amount)
    end
    if IsMouseWithin(x, y, self.x + self.w - _sprite_res, self.y + self.h - _sprite_res, _sprite_res, _sprite_res) then
        Scroll(self, _scroll_amount)
    end
end
