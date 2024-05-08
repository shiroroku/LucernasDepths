---An object which as a name, uuid, and optionally data
---@class Entity
---@field name string ex: "Luna", "Beth", "Skeleton"
---@field uuid string Unique string for looking up entities in a table
---@field data table Dynamic data which is saved, loaded, and synced (Position, Speed, Inventory, etc.)
Entity = {}

---@return Entity
function Entity:new(name, uuid, data)
    local o = {}
    setmetatable(o, { __index = self })
    o.name = name or "Unknown"
    o.uuid = uuid or "None"
    o.data = data or {}
    return o
end

---Unique string for looking up entities in a table
---@return string
function Entity:getUUID()
    return self.uuid
end

---Entity X and Y, may be nil (the client doesnt need x and y for entities which it cant see/isnt near)
---@return number x
---@return number y
function Entity:getPos()
    return self.data.x, self.data.y
end

---@param x number
---@param y number
function Entity:setPos(x, y)
    self.data.x = x
    self.data.y = y
end

---ex: "Luna", "Beth", "Skeleton"
---@return string
function Entity:getName()
    return self.name
end

---Dynamic data which is saved, loaded, and synced (Position, Speed, Inventory, etc.)
---@return table
function Entity:getData()
    return self.data
end

---@param data table
function Entity:setData(data)
    self.data = data
end
