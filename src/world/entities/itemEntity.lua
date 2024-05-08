require "src.world.entities.entity"

---@class ItemEntity
---@field item Item
ItemEntity = Entity:new()

---@param item Item
---@param uuid string
---@param data table
function ItemEntity:new(item, uuid, data)
    local o = Entity:new(item:GetKey(), uuid, data)
    setmetatable(o, { __index = self })
    o.item = item or nil
    return o
end

---@return Item
function ItemEntity:getItem()
    return ITEM_REGISTRY[self.item:GetKey()]
end
