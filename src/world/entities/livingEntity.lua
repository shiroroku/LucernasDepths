require "src.world.entities.entity"

-- An Entity which has health and movement
LivingEntity = Entity:extend {
    init = function(self, name, uuid, data)
        Entity.init(self, name, uuid, data)
    end,

    -- assume nil as invulnerable
    GetHealth = function(self)
        return self.data.health
    end,

    SetHealth = function(self, amt)
        self.data.health = amt
    end,

    GetSpeed = function(self)
        return self.data.speed or 80
    end,

    SetSpeed = function(self, amt)
        self.data.speed = amt
    end

}
