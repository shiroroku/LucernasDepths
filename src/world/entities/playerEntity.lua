local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.world.entities.livingEntity"

PlayerEntity = LivingEntity:extend {

    init = function(self, name, uuid, data)
        LivingEntity.init(self, name, uuid, data)
        self.data.inventory = data.inventory or {}
    end,

    -- checks to see if the player has a position, basically loaded
    IsLoaded = function(self)
        local x, y = self:GetPos()
        return x and y
    end,

    CanSetInventorySlot = function(self, slot, item_key)
        if item_key == nil then
            return true
        end
        if not ITEM_REGISTRY[item_key] then -- so the client cant crash the server sending invalid item
            Log(string.format("Inventory trying to set unknown item \"%s\"", item_key))
            return false
        end
        if slot == 0 then
            return ITEM_REGISTRY[item_key]:HasProperty("equipment_trinket")
        end
        if slot == 1 then
            return ITEM_REGISTRY[item_key]:HasProperty("equipment_torso")
        end
        if slot == 2 then
            return ITEM_REGISTRY[item_key]:HasProperty("equipment_legs")
        end
        if slot == 3 then
            return ITEM_REGISTRY[item_key]:HasProperty("equipment_bag")
        end
        return true
    end,

    GetInventoryTier = function(self)
        return math.min(2, math.max(0, self.data.inventory_tier or 0))
    end,

    SetInventorySlot = function(self, slot, item_instance)
        if slot == nil then return end
        if self:CanSetInventorySlot(slot, item_instance and item_instance.item or nil) then
            local inv = self:GetInventory()
            -- we use tostring because our packet encoding converts number tables wrong for some reason
            inv[tostring(Clamp(slot, 0, self:GetInventorySize()))] = item_instance
            self.data.inventory = inv
        end
    end,

    GetInventorySize = function(self)
        return 16 + 4 * self:GetInventoryTier()
    end,

    GetInventorySlot = function(self, slot)
        return self:GetInventory()[tostring(Clamp(slot, 0, self:GetInventorySize()))]
    end,

    GetInventory = function(self)
        return self.data.inventory or {}
    end,

    SetSkin = function(self, skin)
        self.data.skin = skin
    end,

    GetSkin = function(self)
        return self.data.skin or "chroma"
    end,

    SetSkinColors = function(self, colors)
        self.data.skin_colors = colors
    end,

    GetSkinColors = function(self)
        return self.data.skin_colors or {
            skin = {
                h = 0,
                s = 0,
                l = 0
            },
            clothes = {
                h = 0,
                s = 0,
                l = 0
            },
            primary = {
                h = 0,
                s = 0,
                l = 0
            },
            secondary = {
                h = 0,
                s = 0,
                l = 0
            }
        }
    end,

    GetReach = function(self)
        return self.data.reach or 32
    end,

    -- handles player collision
    MovePlayer = function(self, world, dx, dy, dt)
        local speed = self:GetSpeed()
        local mag = math.sqrt(dx ^ 2 + dy ^ 2)
        if mag > 0 then
            local dxn, dyn = dx / mag, dy / mag -- normalize
            local oldx, oldy = self:GetPos()
            local newx, newy = oldx + dxn * speed * dt, oldy + dyn * speed * dt

            -- player hitbox
            local p_tl_x, p_tl_y = -5, -5
            local p_tr_x, p_tr_y = 5, -5
            local p_bl_x, p_bl_y = -5, 5
            local p_br_x, p_br_y = 5, 5

            -- tile collisions
            local tl_col = GetTileFromPoint(world, (dy == -1 and oldx or newx) + p_tl_x, (dx == -1 and oldy or newy) + p_tl_y)
            local tr_col = GetTileFromPoint(world, (dy == -1 and oldx or newx) + p_tr_x, (dx == 1 and oldy or newy) + p_tr_y)
            local bl_col = GetTileFromPoint(world, (dy == 1 and oldx or newx) + p_bl_x, (dx == -1 and oldy or newy) + p_bl_y)
            local br_col = GetTileFromPoint(world, (dy == 1 and oldx or newx) + p_br_x, (dx == 1 and oldy or newy) + p_br_y)

            if tl_col:HasProperty("solid") or tr_col:HasProperty("solid") then -- top
                if dy == -1 then newy = oldy end                               -- moving up
            end
            if bl_col:HasProperty("solid") or br_col:HasProperty("solid") then -- bottom
                if dy == 1 then newy = oldy end                                -- moving down
            end
            if tl_col:HasProperty("solid") or bl_col:HasProperty("solid") then -- left
                if dx == -1 then newx = oldx end                               -- moving left
            end
            if tr_col:HasProperty("solid") or br_col:HasProperty("solid") then -- right
                if dx == 1 then newx = oldx end                                -- moving right
            end

            self:SetPos(newx, newy)
        end
    end,

    Server_Save = function(self, world_folder, file_name)
        local player_save = {
            name = self.name,
            data = self.data
        }
        local success, err = love.filesystem.write(string.format("worlds/%s/players/%s.json", world_folder, file_name), json.beautify(player_save))
        if not success then
            error(string.format("%s", err))
        end
    end,

    -- tries to load save data, and overrides itself, returns false if there was no save
    Server_Load = function(self, world_folder, file_name)
        local player_file = love.filesystem.read(string.format("worlds/%s/players/%s.json", world_folder, file_name))
        if player_file then
            local decoded = json.decode(player_file)
            self.name = decoded.name
            self.data = decoded.data
            return true
        end
        return false
    end,

    Client_HasCharacter = function(self)
        return self.character ~= nil
    end,

    Client_GetCharacter = function(self)
        if not self:Client_HasCharacter() then
            error("Getting character before it was set")
        end
        return self.character
    end,

    Client_SetCharacter = function(self, character)
        self.character = character
    end,

}
