require "src.helperFunctions"
require "src.network.server"
require "src.components.scene"
require "src.world.world"
require "src.world.entities.playerEntity"

local udpServer

-- for sending player data back to the owner client
local function sendPlayerData(peer, player_data)
    udpServer:send(peer, {
        event = "player_data",
        player_data = player_data
    })
end

local function sendChunks(peer, chunks)
    udpServer:send(peer, {
        event = "load_chunks",
        chunks = chunks
    })
end

-- sends the chunk data that this tile is in to players within 1 chunk away
local function sendTileChanged(world, tile_x, tile_y)
    -- tell all the clients that need it, that this chunk updated
    local cx, cy = TilePosToChunkPos(tile_x, tile_y)
    local updated_chunks = {}
    updated_chunks[XYToCoordKey(cx, cy)] = world.chunks[XYToCoordKey(cx, cy)]
    for _, player in pairs(world.players) do
        local player_chunk_x, player_chunk_y = PointToChunkPos(player:getPos())
        local chunk_distance                 = 1
        if player_chunk_x - cx <= chunk_distance and player_chunk_y - cy <= chunk_distance then
            sendChunks(player.peer, updated_chunks)
        end
    end
end


ServerSceneConstructor = Scene:extend {

    init = function(self)
        Scene.init(self, "Server")
    end,

    GetPlayerFromPeer = function(self, peer)
        for token, player in pairs(self.world.players) do if player.peer == peer then return player, token end end
        return nil
    end,

    Load = function(self)
        Log("Server Starting!", COLORS.green)
        Scene.Load(self)
        self.time = 0
        self.update_interval = 0
        self.update_rate = SERVER_CONFIG.update_rate
        self.world = LoadOrGenWorld(SERVER_CONFIG.world_file)
        local ServerEvents = {
            input = function(event, data)
                local player = self:GetPlayerFromPeer(event.peer)
                if player then
                    player.inputs = {
                        up = data.inputs.up or false,
                        down = data.inputs.down or false,
                        left = data.inputs.left or false,
                        right = data.inputs.right or false
                    }
                end
            end,
            player_auth = function(event, data)
                -- someone tried to connect with a player id/token that is already connected
                for token, player in pairs(self.world.players) do
                    if tostring(token) == data.token or data.uuid == player:getUUID() then
                        event.peer:disconnect(2)
                        return
                    end
                end

                local player = PlayerEntity:new(data.name, data.uuid, {}) -- new player object

                local loaded_player = player:S_load(self.world.name, data.token)
                if not loaded_player then
                    player:setPos(CHUNK_WIDTH / 2 * 16, CHUNK_HEIGHT / 2 * 16)
                    player:setInventorySlot(4, { key = "stone_pickaxe" })
                    Log(string.format("%s! A new player!", data.name), COLORS.green)
                    player:S_save(self.world.name, data.token)
                end
                player:setSkin(data.skin)
                player:setSkinColors(data.skin_colors)

                player.peer = event.peer                     -- link ip to player
                self.world.players[data.token] = player      -- insert player into the world!
                sendPlayerData(event.peer, player:getData()) -- send their player data back to owner

                -- send chunks to player
                local player_chunk_x, player_chunk_y = PointToChunkPos(player:getPos())
                local load_distance = 1
                local chunks_to_send = {}
                for x = -load_distance, load_distance do
                    for y = -load_distance, load_distance do
                        chunks_to_send[XYToCoordKey(player_chunk_x + x, player_chunk_y + y)] = GetChunk(self.world, player_chunk_x + x, player_chunk_y + y)
                    end
                end
                sendChunks(event.peer, chunks_to_send)
                player.last_chunk_x, player.last_chunk_y = player_chunk_x, player_chunk_y -- initializes last_chunk

                -- send client the other connected players
                local player_list = {}
                for _, p in pairs(self.world.players) do
                    player_list[p:getUUID()] = { name = p:getName(), uuid = p:getUUID(), data = {} } -- no data shared, only names/uuid
                end
                udpServer:broadcast({
                    event = "update_players",
                    players = player_list
                })

                -- let all clients know they connected
                udpServer:broadcast({
                    event = "broadcast_player_connect",
                    name = data.name
                })
                Log(string.format("%s(%s) Joined", data.name, data.token), COLORS.green)
            end,
            break_block = function(event, data)
                -- player sends this to try to break a block
                local player = self:GetPlayerFromPeer(event.peer)
                if player then
                    local px, py = player:getPos()
                    local hit, hit_x, hit_y = RayCast(px, py, data.x, data.y, player:getReach(), function(x, y)
                        return GetTileFromPoint(self.world, x, y):hasProperty("toughness")
                    end)
                    if hit then
                        local tx, ty = PointToTilePos(hit_x, hit_y)
                        local tile = GetTileFromPoint(self.world, hit_x, hit_y)
                        local tile_instance = GetTileInstanceFromPoint(self.world, hit_x, hit_y)
                        if tile_instance then
                            local item_mining_damage = 1 / tile:getProperty("toughness")
                            local tile_damage = (tile_instance.damage or 0) + item_mining_damage
                            if tile_damage >= 1 then
                                SetTile(self.world, tx, ty, { key = tile:getProperty("break_tile") or "dirt" })
                                sendTileChanged(self.world, tx, ty)
                            else
                                tile_instance.damage = tile_damage
                                tile_instance.last_damaged = self.world.properties.ticks
                                SetTile(self.world, tx, ty, tile_instance)
                                sendTileChanged(self.world, tx, ty)
                            end
                        end
                    end
                end
            end,
            player_inventory_move = function(event, data)
                local player = self:GetPlayerFromPeer(event.peer)
                if player then
                    local picking_up = player:getInventorySlot(data.clicked_slot)
                    player:setInventorySlot(data.clicked_slot, player:getInventorySlot(data.held_slot))
                    player:setInventorySlot(data.held_slot, picking_up)
                    sendPlayerData(player.peer, player:getData())
                end
            end,
            disconnected = function(event)
                -- find which player our peer is

                local player, token = self:GetPlayerFromPeer(event.peer)
                if player then
                    player:S_save(self.world.name, token) -- save their data
                    Log(string.format("%s(%s) Left", player:getName(), token), COLORS.green)
                    self.world.players[token] = nil       -- unload them

                    -- let all clients know they disconnected
                    udpServer:broadcast({
                        event = "broadcast_player_disconnect",
                        name = player:getName(),
                        uuid = player:getUUID()
                    })
                end
            end
        }
        udpServer = GameServer:new(SERVER_CONFIG.hosting_ip, ServerEvents)
    end,

    Update = function(self, dt)
        udpServer:update()

        -- MOVE PLAYERS
        for _, player in pairs(self.world.players) do
            if player.inputs then
                local dx, dy = 0, 0
                if player.inputs.up then dy = dy - 1 end
                if player.inputs.down then dy = dy + 1 end
                if player.inputs.left then dx = dx - 1 end
                if player.inputs.right then dx = dx + 1 end
                player:move(self.world, dx, dy, dt)
            end
        end

        self.world.properties.ticks = self.world.properties.ticks + dt
        self.time = self.time + dt
        if self.time > self.update_rate then
            for token, player in pairs(self.world.players) do
                local px_c, py_c     = PointToChunkPos(player:getPos())

                -- PROVIDE SURROUNDING CHUNKS
                local chunks_to_send = {}
                local load_distance  = 1
                for x = -load_distance, load_distance do
                    for y = -load_distance, load_distance do
                        -- if player changed chunks, they need new ones
                        if player.last_chunk_x ~= px_c or player.last_chunk_y ~= py_c then
                            chunks_to_send[XYToCoordKey(px_c + x, py_c + y)] = GetChunk(self.world, px_c + x, py_c + y)
                        end
                    end
                end
                if next(chunks_to_send) then sendChunks(player.peer, chunks_to_send) end
                player.last_chunk_x, player.last_chunk_y = px_c, py_c


                -- PROVIDE SURROUNDING PLAYER DATA
                local nearby_players = {}
                for otoken, op in pairs(self.world.players) do
                    if otoken ~= token then
                        local opx_c, opy_c = PointToChunkPos(op:getPos())
                        if math.abs(px_c - opx_c) <= 1 and math.abs(py_c - opy_c) <= 1 then -- if players are within 1 chunk away (3x3)
                            nearby_players[op:getUUID()] = {
                                name = op:getName(),
                                uuid = op:getUUID(),
                                data = op:getData()
                            }
                        else
                            -- if they arent nearby we want the client to delete the old data is has
                            nearby_players[op:getUUID()] = { name = op:getName(), uuid = op:getUUID(), data = {} }
                        end
                    end
                end
                if next(nearby_players) then
                    udpServer:send(player.peer, {
                        event = "update_players",
                        players = nearby_players
                    })
                end

                -- PROVIDE PLAYERS OWN DATA
                sendPlayerData(player.peer, player:getData())
            end
            self.time = self.time - self.update_rate
        end

        -- CHUNK UNLOADING
        self.unload_tick = (self.unload_tick or 0) + dt
        if self.unload_tick > SERVER_CONFIG.chunk_unload_interval then -- unload chunks every 1 sec
            local unload_thread = coroutine.create(function()
                local needed_chunks = {}                               -- chunks that the player is in and surrounds them
                for _, player in pairs(self.world.players) do
                    local player_chunk_x, player_chunk_y = PointToChunkPos(player:getPos())
                    local load_distance = 1
                    for x = -load_distance, load_distance do
                        for y = -load_distance, load_distance do
                            table.insert(needed_chunks, { x = player_chunk_x + x, y = player_chunk_y + y })
                        end
                    end
                end
                -- for every loaded chunk, check to see if its in our needed list
                for chunk_coord_key, _ in pairs(self.world.chunks) do
                    local needed = false
                    local chunk_x, chunk_y = CoordKeyToXY(chunk_coord_key)
                    for _, loaded_chunk in pairs(needed_chunks) do
                        if loaded_chunk.x == chunk_x and loaded_chunk.y == chunk_y then
                            needed = true
                            break
                        end
                    end
                    if not needed then UnloadChunk(self.world, chunk_x, chunk_y) end
                end
            end)
            coroutine.resume(unload_thread)
            self.unload_tick = self.unload_tick - SERVER_CONFIG.chunk_unload_interval
        end

        -- TILE DAMAGE HEALING
        for chunk_coord, chunk_data in pairs(self.world.chunks) do
            for tile_coord, tile_instance in pairs(chunk_data) do
                if tile_instance.damage and tile_instance.last_damaged then
                    if self.world.properties.ticks - tile_instance.last_damaged >= 3 then
                        local tile_damage = tile_instance.damage - 0.25 -- heal 25% every 3 seconds
                        if tile_damage <= 0 then
                            tile_instance.damage = nil
                            tile_instance.last_damaged = nil
                        else
                            tile_instance.damage = tile_damage
                            tile_instance.last_damaged = self.world.properties.ticks
                        end
                        local tx, ty = SplitKey(tile_coord)
                        local cx, cy = SplitKey(chunk_coord)
                        sendTileChanged(self.world, tx + cx * CHUNK_WIDTH, ty + cy * CHUNK_HEIGHT)
                    end
                end
            end
        end
    end,

    Draw = function(self)
        DrawText("Clients:", 3, 0, { 0.3, 0.3, 1 })
        local number_of_chunks = 0
        for _, _ in pairs(self.world.chunks) do number_of_chunks = number_of_chunks + 1 end
        DrawText("Chunks Loaded: " .. number_of_chunks, INTERNAL_RES_WIDTH - GetTextWidth("Chunks Loaded: " .. number_of_chunks, FontRegular) - 2, 0, { 0.3, 0.3, 1 })
        local connectedClients = udpServer:getClients()
        if connectedClients then
            local io = 1
            for _, peer in pairs(connectedClients) do
                local player = self:GetPlayerFromPeer(peer)
                local text = string.format("<#FFFFFF>[%s][%s]", tostring(peer), peer:state())
                if player then
                    text = string.format("%s[<#00FF00>%s<#FFFFFF>][%sms]", text, player:getName(), tostring(peer:round_trip_time()))
                end
                DrawText(text, 3, io * 11, { 0.7, 0.7, 0.7 })
                io = io + 1
            end
        end
    end,

    Quit = function(self)
        UnloadWorld(self.world)
        Log("Server Stopping.", COLORS.grey)
        udpServer:quit()
    end
}
