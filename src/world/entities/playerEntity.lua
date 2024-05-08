local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.world.entities.livingEntity"


---@class PlayerEntity : LivingEntity
PlayerEntity = LivingEntity:new()

---@alias inventory {[string]: ItemInstance}

---@return PlayerEntity
function PlayerEntity:new(name, uuid, data)
    local o = LivingEntity:new(name, uuid, data)
    setmetatable(o, { __index = self })
    --self.data.inventory = data.inventory or {}
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

---@return integer
function PlayerEntity:getReach()
    return self.data.reach or 46
end

---If a player has a position then we consider it loaded
---@return boolean
function PlayerEntity:isLoaded()
    local x, y = self:getPos()
    return x ~= nil and y ~= nil
end

---Returns player inventory. string(slot_number) = item_instance
---@return inventory
function PlayerEntity:getInventory()
    return self.data.inventory or {}
end

---Tier (size) of player inventory, 0 = no upgrades, 2 = max
---@return integer
function PlayerEntity:getInventoryTier()
    return math.min(2, math.max(0, self.data.inventory_tier or 0))
end

---Total number of slots this player has available
---@return integer
function PlayerEntity:getInventorySize()
    return 16 + 4 * self:getInventoryTier()
end

---@param slot number
---@return ItemInstance
function PlayerEntity:getInventorySlot(slot)
    return self:getInventory()[tostring(Clamp(slot, 0, self:getInventorySize()))]
end

---If the given item can be set in the slot
---@param slot number
---@param item_key any item key "stone_pickaxe"
function PlayerEntity:canSetInventorySlot(slot, item_key)
    if item_key == nil then return true end -- nothing can always go in
    if not ITEM_REGISTRY[item_key] then     -- so the client cant crash the server sending invalid item
        Log(string.format("Inventory trying to set unknown item \"%s\"", item_key))
        return false
    end
    if slot == 0 then return ITEM_REGISTRY[item_key]:hasProperty("equipment_trinket") end
    if slot == 1 then return ITEM_REGISTRY[item_key]:hasProperty("equipment_torso") end
    if slot == 2 then return ITEM_REGISTRY[item_key]:hasProperty("equipment_legs") end
    if slot == 3 then return ITEM_REGISTRY[item_key]:hasProperty("equipment_bag") end
    return true
end

---@param slot number
---@param item_instance ItemInstance
function PlayerEntity:setInventorySlot(slot, item_instance)
    if slot == nil then return end
    if self:canSetInventorySlot(slot, item_instance and item_instance.key or nil) then
        local inv = self:getInventory()
        -- we use tostring because our packet encoding converts number tables wrong for some reason
        inv[tostring(Clamp(slot, 0, self:getInventorySize()))] = item_instance
        self.data.inventory = inv
    end
end

---@return string
function PlayerEntity:getSkin()
    return self.data.skin or "chroma"
end

---@param skin string
function PlayerEntity:setSkin(skin)
    self.data.skin = skin
end

---@return table
function PlayerEntity:getSkinColors()
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
end

---@param colors table
function PlayerEntity:setSkinColors(colors)
    self.data.skin_colors = colors
end

---Moves player and handles collision
---@param world table
---@param dx number
---@param dy number
---@param dt number
function PlayerEntity:move(world, dx, dy, dt)
    local speed = self:getSpeed()
    local mag = math.sqrt(dx ^ 2 + dy ^ 2)
    if mag > 0 then
        local dxn, dyn = dx / mag, dy / mag -- normalize
        local oldx, oldy = self:getPos()
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

        if tl_col:hasProperty("solid") or tr_col:hasProperty("solid") then -- top
            if dy == -1 then newy = oldy end                               -- moving up
        end
        if bl_col:hasProperty("solid") or br_col:hasProperty("solid") then -- bottom
            if dy == 1 then newy = oldy end                                -- moving down
        end
        if tl_col:hasProperty("solid") or bl_col:hasProperty("solid") then -- left
            if dx == -1 then newx = oldx end                               -- moving left
        end
        if tr_col:hasProperty("solid") or br_col:hasProperty("solid") then -- right
            if dx == 1 then newx = oldx end                                -- moving right
        end

        self:setPos(newx, newy)
    end
end

---Server Side, saves the player to the world folder
---@param world_folder string
---@param file_name string
function PlayerEntity:S_save(world_folder, file_name)
    local player_save = {
        name = self.name,
        data = self.data
    }
    local success, err = love.filesystem.write(string.format("worlds/%s/players/%s.json", world_folder, file_name), json.beautify(player_save))
    if not success then error(string.format("%s", err)) end
end

---Server Side, loads the player from the world folder
---@param world_folder string
---@param file_name string
---@return boolean loaded true if a player save existed and was loaded
function PlayerEntity:S_load(world_folder, file_name)
    local player_file = love.filesystem.read(string.format("worlds/%s/players/%s.json", world_folder, file_name))
    if player_file then
        local decoded = json.decode(player_file)
        self.name = decoded.name
        self.data = decoded.data
        return true
    end
    return false
end

function PlayerEntity:C_hasCharacter()
    return self.character ~= nil
end

function PlayerEntity:C_getCharacter()
    if not self:C_hasCharacter() then error("Getting character before it was set") end
    return self.character
end

function PlayerEntity:C_setCharacter(character)
    self.character = character
end
