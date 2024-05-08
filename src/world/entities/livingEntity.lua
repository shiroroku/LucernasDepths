require "src.world.entities.entity"

---An Entity which has speed and health
---@class LivingEntity : Entity
LivingEntity = Entity:new()

function LivingEntity:new(name, uuid, data)
    local o = Entity:new(name, uuid, data)
    setmetatable(o, { __index = self })
    return o
end

---Current Health, nil is invulnerable
---@return number?
function LivingEntity:getHealth()
    return self.data.health
end

---@param amt number
function LivingEntity:setHealth(amt)
    self.data.health = amt
end

---@return number?
function LivingEntity:getMaxHealth()
    return self.data.max_health
end

---@param amt number
function LivingEntity:setMaxHealth(amt)
    self.data.max_health = amt
end

---@return integer
function LivingEntity:getSpeed()
    return self.data.speed or 80
end

---@param amt number
function LivingEntity:setSpeed(amt)
    self.data.speed = amt
end
