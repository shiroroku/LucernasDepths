---@class TileInstance
---@field key string the tiles name, ex "dirt", "stone_wall"
---@field damage number? how much health the tile has, 0.0-1.0, nil if full health
---@field bit number? client, added by the autotiler for rendering the bitmask
---@field last_damaged number? server, last server tick that this tile was damaged
TileInstance = {}

---@class Tile
---@field key string
---@field properties {[string]: any}
---@field sprite_batch love.SpriteBatch client
---@field quad love.Quad client
---@field bitmasked_quads {[number]: love.Quad} client
---@field bitmask_connects_to string[] client
Tile = {}

function Tile:new(key, properties)
    local o = {}
    setmetatable(o, { __index = self })
    o.key = key
    o.properties = properties or {}
    return o
end

---ex: "dirt", "grass", etc.
---@return string
function Tile:getKey()
    return self.key
end

---@param property string
---@return any
function Tile:getProperty(property)
    return self.properties[property]
end

---@param property string
---@return boolean
function Tile:hasProperty(property)
    return self.properties[property] ~= nil
end

---Translates the tiles key and returns it for display
---@return string
function Tile:getDisplayName()
    return GetTranslation("tile." .. self:getKey())
end

---@param other_tile_key string
---@return boolean
function Tile:C_bitmaskCanConnect(other_tile_key)
    if self.bitmask_connects_to then
        for _, key in pairs(self.bitmask_connects_to) do
            if other_tile_key == key then return false end
        end
    end
    return self.key ~= other_tile_key
end

---@param x number
---@param y number
---@param tile_instance TileInstance
function Tile:C_addToSpriteBatch(x, y, tile_instance)
    if self.bitmasked_quads and tile_instance.bit then
        if self.bitmasked_quads[tile_instance.bit] then
            self.sprite_batch:add(self.bitmasked_quads[tile_instance.bit], x, y)
        else
            Log(string.format("%s at %d,%d is missing bitmask %d!", self.key, x, y, tile_instance.bit))
        end
    end
    if self.quad then self.sprite_batch:add(self.quad, x, y) end
    if tile_instance.damage then
        TILE_REGISTRY["tile_break_overlay"]:C_addToSpriteBatch(x, y, {
            key = "tile_break_overlay",
            bit = math.floor(math.min(tile_instance.damage, 1) * 5)
        })
    end
end
