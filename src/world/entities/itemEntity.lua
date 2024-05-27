require "src.world.entities.entity"

---@class ItemEntity :Entity
---@field item Item
ItemEntity = Entity:new()

---@return LivingEntity
function ItemEntity:new(item, uuid, data)
    local o = Entity:new(item:getKey(), uuid, data)
    setmetatable(o, { __index = self })
    self.item = item or nil
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

---@return Item
function ItemEntity:getItem()
    return ITEM_REGISTRY[self.item:getKey()]
end
