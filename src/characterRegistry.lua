local anim8 = require "libraries.anim8"
require "src.itemRegistry"

-- converts each pixel to hsl, adds shift values, converts back to rgb and then sets the pixels
local function ColorShift(image_data, hue_shift, sat_shift, lum_shift)
    for x = 0, image_data:getWidth() - 1 do
        for y = 0, image_data:getHeight() - 1 do
            local r, g, b, a = image_data:getPixel(x, y)
            local h, s, l = RGBToHSL(r, g, b)
            r, g, b = HSLToRGB((h + hue_shift) % 1, math.min(1, math.max(0, s + sat_shift)), math.min(1, math.max(0, l + lum_shift)))
            image_data:setPixel(x, y, r, g, b, a)
        end
    end
end

-- loads all 4 layers of the character, colorizes it and returns a flattened image
local function ColorizePlayerTexture(character_name, skin_hsl, clothes_hsl, primary_hsl, secondary_hsl)
    local skin      = love.image.newImageData(string.format("resources/textures/characters/%s/skin.png", character_name))
    local clothes   = love.image.newImageData(string.format("resources/textures/characters/%s/clothes.png", character_name))
    local primary   = love.image.newImageData(string.format("resources/textures/characters/%s/primary.png", character_name))
    local secondary = love.image.newImageData(string.format("resources/textures/characters/%s/secondary.png", character_name))

    ColorShift(skin, skin_hsl.h, skin_hsl.s, skin_hsl.l)
    ColorShift(clothes, clothes_hsl.h, clothes_hsl.s, clothes_hsl.l)
    ColorShift(primary, primary_hsl.h, primary_hsl.s, primary_hsl.l)
    ColorShift(secondary, secondary_hsl.h, secondary_hsl.s, secondary_hsl.l)

    -- flattens layers into one image
    local layers = { clothes, primary, secondary }
    skin:mapPixel(function(x, y, r, g, b, a)
        for _, image_data in pairs(layers) do
            local r1, g1, b1, a1 = image_data:getPixel(x, y)
            if a1 == 1 then r, b, g, a = r1, b1, g1, a1 end
        end
        return r, g, b, a
    end)
    return love.graphics.newImage(skin)
end

-- characters are the client side rendering of entities like players, and mobs
CHARACTER_REGISTRY = {
    chroma = function(skin_hsl, clothes_hsl, primary_hsl, secondary_hsl)
        local chroma_sheet_texture = ColorizePlayerTexture("chroma", skin_hsl, clothes_hsl, primary_hsl, secondary_hsl)
        local chroma_sheet = anim8.newGrid(18, 18, chroma_sheet_texture:getWidth(), chroma_sheet_texture:getHeight())

        local up_l_idle_animation = anim8.newAnimation(chroma_sheet(2, 2), 0.1)
        local up_r_idle_animation = up_l_idle_animation:clone():flipH()
        local up_l_walk_animation = anim8.newAnimation(chroma_sheet(5, "1-5"), { 0.1, 0.05, 0.1, 0.05, 0.1 })
        local up_r_walk_animation = up_l_walk_animation:clone():flipH()
        local up_swing_l_animation = anim8.newAnimation(chroma_sheet(7, "1-3"), 0.08)
        local up_swing_r_animation = up_swing_l_animation:clone():flipH()
        local down_l_idle_anim = anim8.newAnimation(chroma_sheet(1, 1, 3, "1-2", 3, 1, 1, 1), { ["1-5"] = 0.1, ["5-5"] = 2 })
        local down_r_idle_anim = down_l_idle_anim:clone():flipH()
        local down_l_walk_animation = anim8.newAnimation(chroma_sheet(4, "1-5"), { 0.1, 0.05, 0.1, 0.05, 0.1 })
        local down_r_walk_animation = down_l_walk_animation:clone():flipH()
        local down_l_weilding_animation = anim8.newAnimation(chroma_sheet(6, 1), 0.1)
        local down_r_weilding_animation = down_l_weilding_animation:clone():flipH()
        local down_swing_l_animation = anim8.newAnimation(chroma_sheet(6, "1-3", 6, "3-1"), 0.1)
        local down_swing_r_animation = down_swing_l_animation:clone():flipH()
        return {
            character_sheet_texture = chroma_sheet_texture,
            current_animation       = down_l_idle_anim,
            x                       = 0,
            y                       = 0,
            xo                      = 0,
            yo                      = 0,
            is_moving               = false,
            facing_left             = true,
            facing_up               = false,
            animations              = {
                up_l_idle = up_l_idle_animation,
                up_r_idle = up_r_idle_animation,
                up_l_walk = up_l_walk_animation,
                up_r_walk = up_r_walk_animation,
                up_swing_l = up_swing_l_animation,
                up_swing_r = up_swing_r_animation,
                down_l_idle = down_l_idle_anim,
                down_r_idle = down_r_idle_anim,
                down_l_walk = down_l_walk_animation,
                down_r_walk = down_r_walk_animation,
                down_l_weilding = down_l_weilding_animation,
                down_r_weilding = down_r_weilding_animation,
                down_swing_l = down_swing_l_animation,
                down_swing_r = down_swing_r_animation,
            },
            -- held_item               = {
            --     item = ITEMS["items.stone_pickaxe"](),
            --     swing = 0,
            --     offset_x = 9,
            --     offset_y = 16,
            --     x = 0,
            --     y = 0,
            --     r = 0,
            --     ox = 0,
            --     oy = 16,
            --     front = false
            -- }
        }
    end
}

-- function UpdateCharacter(c, dt, x, y)
--     --c.held_item.front = not c.facing_up

--     -- local target_r = 0
--     -- local target_x, target_y = c.held_item.offset_x, c.held_item.offset_y
--     -- if c.facing_left then
--     --     c.held_item.item.current_animation = c.held_item.item.animations.left
--     --     target_r = 0
--     -- else
--     --     c.held_item.item.current_animation = c.held_item.item.animations.right
--     --     target_r = -90
--     -- end
--     -- if c.held_item.swing > 0 then
--     --     --c.held_item.swing = c.held_item.swing - dt * 150 -- swing speed
--     --     local swing_distance = 45
--     --     target_r = c.held_item.swing * (c.facing_left and -1 or 1) + (c.facing_left and -swing_distance or swing_distance - 90)
--     -- end

--     -- if c.sheath then
--     --     target_r = 180
--     --     target_x = 17
--     --     target_y = 2
--     --     c.held_item.front = c.facing_up
--     -- end
--     -- c.held_item.r = Lerp(c.held_item.r, target_r, 0.2)
--     -- c.held_item.x = Lerp(c.held_item.x, target_x, 0.4)
--     -- c.held_item.y = Lerp(c.held_item.y, target_y, 0.4)

--     -- set previous xy for our sprite
--     c.xo, c.yo = c.x or 0, c.y or 0
--     c.x, c.y = x or 0, y or 0

--     -- we check if we moved and which way to update sprite facing direction
--     c.is_moving = false
--     if c.x - c.xo > 0.1 then -- moved right
--         c.is_moving = true
--         c.facing_left = false
--         c.facing_up = false   -- so we dont look like we are strafing
--     end
--     if c.x - c.xo < -0.1 then -- moved left
--         c.is_moving = true
--         c.facing_left = true
--         c.facing_up = false
--     end
--     if c.y - c.yo > 0.1 then -- moved down
--         c.is_moving = true
--         c.facing_up = false
--     end
--     if c.y - c.yo < -0.1 then -- moved up
--         c.is_moving = true
--         c.facing_up = true
--     end

--     -- ye big ol animation state tree
--     if c.facing_left then
--         if c.facing_up then
--             if c.is_moving then
--                 c.current_animation = c.animations.up_l_walk
--             else -- left up not moving
--                 c.current_animation = c.animations.up_l_idle
--             end
--         else -- left, down
--             if c.is_moving then
--                 c.current_animation = c.animations.down_l_walk
--             else
--                 if c.held_item then
--                     c.current_animation = c.animations.down_l_idle
--                 else
--                     c.current_animation = c.animations.down_l_weilding
--                 end
--             end
--         end
--     else
--         if c.facing_up then
--             if c.is_moving then
--                 c.current_animation = c.animations.up_r_walk
--             else
--                 c.current_animation = c.animations.up_r_idle
--             end
--         else -- right, down
--             if c.is_moving then
--                 c.current_animation = c.animations.down_r_walk
--             else
--                 if c.held_item then
--                     c.current_animation = c.animations.down_r_idle
--                 else
--                     c.current_animation = c.animations.down_r_weilding
--                 end
--             end
--         end
--     end
--     c.current_animation:update(dt)
-- end

-- function DrawCharacter(c, x, y)
--     x, y = Round(x or c.x) - 18 / 2, Round(y or c.y) - 18 / 2 - 5 -- sprite size
--     love.graphics.setColor(0, 0, 0, 0.2)
--     love.graphics.rectangle("fill", x + 5, y + 17, 8, 2)          -- shadow
--     love.graphics.setColor(1, 1, 1, 1)
--     c.current_animation:draw(c.character_sheet_texture, x, y)
--     -- if c.held_item.front then
--     --     c.current_animation:draw(c.character_sheet_texture, x, y)
--     --     c.held_item.item.current_animation:draw(
--     --         c.held_item.item.item_sheet_texture,
--     --         x + c.held_item.x,
--     --         y + s_bob + c.held_item.y,
--     --         math.rad(c.held_item.r),
--     --         1,
--     --         1,
--     --         c.held_item.ox,
--     --         c.held_item.oy)
--     -- else
--     --     c.held_item.item.current_animation:draw(
--     --         c.held_item.item.item_sheet_texture,
--     --         x + c.held_item.x,
--     --         y + s_bob + c.held_item.y,
--     --         math.rad(c.held_item.r),
--     --         1,
--     --         1,
--     --         c.held_item.ox,
--     --         c.held_item.oy)
--     --     c.current_animation:draw(c.character_sheet_texture, x, y)
--     -- end
-- end
