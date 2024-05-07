require "src.world.entities.entity"

ItemEntity = Entity:extend {
    init = function(self, name, data)
        Entity.init(self, name, data)
    end,

    GetItem = function(self)
        return ITEM_REGISTRY[self.name]
    end
}
