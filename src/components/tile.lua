local class = require "libraries.clasp"

--- @class Tile
--- @field HasProperty function
--- @field GetProperty function
--- @field GetDisplayName function
--- @field C_BitmaskCanConnect function
--- @field C_AddSpriteBatch function
--- @field bitmasked_quads love.Quad[]
Tile = class {
    --- @param key string ex: "dirt", "stone_wall"
    --- @param properties table properties decoded from tiles json file
    init = function(self, key, properties)
        self.key = key
        self.properties = properties or {}
    end,

    GetProperty = function(self, property)
        return self.properties[property]
    end,

    HasProperty = function(self, property)
        return self.properties[property] ~= nil
    end,

    GetDisplayName = function(self)
        return GetTranslation("tile." .. self.key)
    end,

    C_BitmaskCanConnect = function(self, other_tile_key) -- this function is actually inverted?
        if self.bitmask_connects_to then
            for _, key in pairs(self.bitmask_connects_to) do
                if other_tile_key == key then return false end
            end
        end
        return self.key ~= other_tile_key
    end,

    ---@param self any
    ---@param x number
    ---@param y number
    ---@param tile_instance TileInstance
    C_AddSpriteBatch = function(self, x, y, tile_instance)
        if self.bitmasked_quads and tile_instance.bit then
            if self.bitmasked_quads[tile_instance.bit] then
                self.sprite_batch:add(self.bitmasked_quads[tile_instance.bit], x, y)
            else
                Log(string.format("%s at %d,%d is missing bitmask %d!", self.key, x, y, tile_instance.bit))
            end
        end
        if self.quad then self.sprite_batch:add(self.quad, x, y) end
        if tile_instance.damage then TILE_REGISTRY["tile_break_overlay"]:C_AddSpriteBatch(x, y, { bit = math.floor(math.min(tile_instance.damage, 1) * 5) }) end
    end,

    __ = {
        tostring = function(self)
            return self.key
        end
    }
}
