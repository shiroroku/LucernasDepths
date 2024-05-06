local json = require "libraries.json.json"
require "libraries.json.json-beautify"

-- this class is not compatible anymore, keeping it around incase i want to do skeleton rigged sprites

local catModel = {}
local testTime = 0

function ApplyAnimation(animation)
    catModel.animation = animation
end

function ResetAnimation(animation)
    catModel.animation = nil
end

DebugScene = {
    load = function()
        local file = io.open("resources/models/cat/cat.json", "r")
        if file ~= nil then
            catModel = json.decode(file:read("a"))
            file:close()
        end

        local catSpriteSheet = love.graphics.newImage("resources/models/cat/cat.png")
        catModel.sprite_batch = love.graphics.newSpriteBatch(catSpriteSheet)


        for _, v in pairs(catModel.bones) do
            v.quad = love.graphics.newQuad(v.u, v.v, v.w, v.h, catSpriteSheet:getDimensions())
        end

        local animation_file = io.open("resources/models/cat/animation_tail.json", "r")
        if animation_file ~= nil then
            ApplyAnimation(json.decode(animation_file:read("a")))
            animation_file:close()
        end
    end,

    update = function()
        testTime = testTime + 1
        if catModel.animation then
            local current_frame = Round((testTime * 0.1) % catModel.animation.total_frames, 0)
            for a_name, animation_override in pairs(catModel.animation.frames[current_frame + 1]) do
                for b_name, bone in pairs(catModel.bones) do
                    if a_name == b_name then
                        bone.rotation = animation_override.rotation or bone.rotation
                    end
                end
            end
        end
    end,

    draw = function()
        love.graphics.clear({ 0.4, 0.4, 0.7 })
        local cat_x, cat_y = GetMousePosition()
        cat_x = Round(cat_x, 0)
        cat_y = Round(cat_y, 0)
        catModel.sprite_batch:clear()
        for i = 0, catModel.layers, 1 do
            for _, v in pairs(catModel.bones) do
                if v.layer == i then
                    -- where on the parent that our origin should match up to
                    local parent_connector_origin_x = v.origin_connector and v.origin_connector.x or 0
                    local parent_connector_origin_y = v.origin_connector and v.origin_connector.y or 0

                    local total_rotation = v.rotation or 0
                    if v.parent then
                        local bone = catModel.bones[v.parent]
                        while 1 do
                            total_rotation = total_rotation + (bone.rotation or 0)
                            if bone.parent == nil then
                                break
                            else
                                bone = catModel.bones[bone.parent]
                            end
                        end
                    end

                    local rotated_x = 0
                    local rotated_y = 0
                    -- move x and y using sin and cos around parents origin point
                    if v.parent then
                        local x_offset = parent_connector_origin_x - catModel.bones[v.parent].origin.x
                        local y_offset = parent_connector_origin_y - catModel.bones[v.parent].origin.y
                        local parents_rotation = math.rad(catModel.bones[v.parent].rotation or 0)
                        rotated_x = x_offset * math.cos(parents_rotation) - y_offset * math.sin(parents_rotation)
                        rotated_y = y_offset * math.cos(parents_rotation) + x_offset * math.sin(parents_rotation)
                    end
                    catModel.sprite_batch:add(v.quad, cat_x + rotated_x, cat_y + rotated_y, math.rad(total_rotation), 1, 1, v.origin.x, v.origin.y)
                end
            end
        end
        love.graphics.draw(catModel.sprite_batch)
    end,

    quit = function()

    end
}
