---@class CharacterInstance
---@field animations table
---@field held_item ItemInstance
---@field character_sheet_texture love.Image
CharacterInstance = {}

function CharacterInstance:new(character)
    local o = character
    setmetatable(o, { __index = self })
    return o
end

---@param x number
---@param y number
function CharacterInstance:setPos(x, y)
    self.xo, self.yo = self.x or 0, self.y or 0
    self.x, self.y = x or 0, y or 0
end

function CharacterInstance:update(dt)
    -- we check if we moved and which way to update sprite facing direction
    self.is_moving = false
    if self.x - self.xo > 0.1 then -- moved right
        self.is_moving = true
        self.facing_left = false
        self.facing_up = false      -- so we dont look like we are strafing
    end
    if self.x - self.xo < -0.1 then -- moved left
        self.is_moving = true
        self.facing_left = true
        self.facing_up = false
    end
    if self.y - self.yo > 0.1 then -- moved down
        self.is_moving = true
        self.facing_up = false
    end
    if self.y - self.yo < -0.1 then -- moved up
        self.is_moving = true
        self.facing_up = true
    end

    -- ye big ol animation state tree
    if self.facing_left then
        if self.facing_up then
            if self.is_moving then
                self.current_animation = self.animations.up_l_walk
            else -- left up not moving
                self.current_animation = self.animations.up_l_idle
            end
        else -- left, down
            if self.is_moving then
                self.current_animation = self.animations.down_l_walk
            else
                if not self.held_item then
                    self.current_animation = self.animations.down_l_idle
                else
                    self.current_animation = self.animations.down_l_weilding
                end
            end
        end
    else
        if self.facing_up then
            if self.is_moving then
                self.current_animation = self.animations.up_r_walk
            else
                self.current_animation = self.animations.up_r_idle
            end
        else -- right, down
            if self.is_moving then
                self.current_animation = self.animations.down_r_walk
            else
                if not self.held_item then
                    self.current_animation = self.animations.down_r_idle
                else
                    self.current_animation = self.animations.down_r_weilding
                end
            end
        end
    end
    self.current_animation:update(dt)
end

---Draws character, x and y are optional for drawing in specific locations
---@param x number?
---@param y number?
function CharacterInstance:draw(x, y)
    x, y = Round(x or self.x) - 18 / 2, Round(y or self.y) - 18 / 2 - 5 -- sprite size
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", x + 5, y + 17, 8, 2)                -- shadow
    love.graphics.setColor(1, 1, 1, 1)
    self.current_animation:draw(self.character_sheet_texture, x, y)
end
