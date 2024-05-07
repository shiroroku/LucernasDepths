local class = require "libraries.clasp"

-- An object which has a name and optionally a positon
Entity = class {
    -- data is things that can change, and can be saved/loaded
    init = function(self, name, uuid, data)
        self.name = assert(name, "Entity must be named")
        self.uuid = assert(uuid, "Entity must have UUID")
        self.data = data or {}
    end,

    GetUUID = function(self)
        return self.uuid
    end,

    -- may be nil (server keeps it private (nil on client) until youre near them)
    GetPos = function(self)
        return self.data.x, self.data.y
    end,

    GetName = function(self)
        return self.name
    end,

    SetPos = function(self, x, y)
        self.data.x, self.data.y = x, y
    end,

    GetData = function(self)
        return self.data
    end,

    SetData = function(self, data)
        self.data = data
    end,

    __ = {
        tostring = function(self)
            return self.name
        end
    }
}
