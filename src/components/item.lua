---@class ItemInstance
---@field key string ex: "stone_pickaxe", "iron_sword", etc.
ItemInstance = {}

---@class Item
---@field key string
---@field properties {[string]: any}
---@field sprite_batch love.SpriteBatch client
---@field quad love.Quad client
Item = {}

function Item:new(key, properties)
    local o = {}
    setmetatable(o, { __index = self })
    o.key = key
    o.properties = properties or {}
    return o
end

---ex: "stone_pickaxe", "iron_sword", etc.
---@return string
function Item:getKey()
    return self.key
end

---@param property string
---@return any
function Item:getProperty(property)
    return self.properties[property]
end

---@param property string
---@return boolean
function Item:hasProperty(property)
    return self.properties[property] ~= nil
end

---Translates the items key and returns it for display
---@return string
function Item:getDisplayName()
    return GetTranslation("item." .. self:getKey())
end

function Item:C_addToSpriteBatch(x, y, r, sx, sy, ox, oy, kx, ky)
    self.sprite_batch:add(self.quad, x, y, r, sx, sy, ox, oy, kx, ky)
end
