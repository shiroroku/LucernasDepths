local class = require "libraries.clasp"

--- @class Item
--- @field GetKey function
--- @field HasProperty function
--- @field GetProperty function
--- @field GetDisplayName function
--- @field C_AddSpriteBatch function
Item = class {
    --- @param key string ex: "stone_pickaxe", "iron_sword"
    --- @param properties table properties decoded from items json file
    init = function(self, key, properties)
        self.key = key
        self.properties = properties or {}
    end,

    GetKey = function(self)
        return self.key
    end,

    GetProperty = function(self, property)
        return self.properties[property]
    end,

    HasProperty = function(self, property)
        return self.properties[property] ~= nil
    end,

    GetDisplayName = function(self)
        return GetTranslation("item." .. self.key)
    end,

    C_AddSpriteBatch = function(self, x, y, r, sx, sy, ox, oy, kx, ky)
        self.sprite_batch:add(self.quad, x, y, r, sx, sy, ox, oy, kx, ky)
    end,

    __ = {
        tostring = function(self)
            return self.key
        end
    }
}
