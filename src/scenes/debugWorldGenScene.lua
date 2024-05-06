require "src.components.scene"
require "src.components.ui.panel"
require "src.world.world"
local Camera = require "libraries.Camera"

local function GenChunk(script, world, chunk_x, chunk_y)
    local chunk = {}
    local seed = world.properties.noise_seed
    for x = 0, CHUNK_WIDTH - 1 do
        for y = 0, CHUNK_HEIGHT - 1 do
            script(chunk, seed, chunk_x, chunk_y, x, y, CHUNK_WIDTH, CHUNK_HEIGHT)
        end
    end
    return chunk
end

local function generateLocalWorld(chunks, random_seed)
    local fake_world = {
        properties = {
            noise_seed = math.random(9999)
        }
    }
    if not random_seed then
        fake_world.properties.noise_seed = 1
    end
    local genScript, err = love.filesystem.load("resources/scripts/chunkGen.lua")
    if err then error(err) end
    for x = -3, 3 do
        for y = -3, 3 do
            chunks[XYToCoordKey(x, y)] = GenChunk(genScript, fake_world, x, y)
        end
    end
    local autotile_thread = coroutine.create(function() AutoTileChunks(chunks) end)
    coroutine.resume(autotile_thread)
end

DebugWorldGenSceneConstructor = Scene:extend {
    init = function(self)
        Scene.init(self, "WorldGen Debugger")
    end,

    Load = function(self)
        Scene.Load(self)
        self.local_world = {
            chunks = {},
        }
        self.camera_x, self.camera_y = 0, 0
        ClientCamera = Camera(0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, 0.2)
        generateLocalWorld(self.local_world.chunks, false)
    end,

    Update = function(self, dt)
        if Scene.Update(self, dt) then return true end
        ClientCamera:update()
        if love.keyboard.isDown(CLIENT_CONFIG.key_binds.up) then
            self.camera_y = self.camera_y - 1 * dt * 256
        end
        if love.keyboard.isDown(CLIENT_CONFIG.key_binds.down) then
            self.camera_y = self.camera_y + 1 * dt * 256
        end
        if love.keyboard.isDown(CLIENT_CONFIG.key_binds.left) then
            self.camera_x = self.camera_x - 1 * dt * 256
        end
        if love.keyboard.isDown(CLIENT_CONFIG.key_binds.right) then
            self.camera_x = self.camera_x + 1 * dt * 256
        end
        ClientCamera:follow(Round(self.camera_x), Round(self.camera_y))
    end,

    Draw = function(self)
        ClientCamera:attach()
        C_ClearTileSBs()
        for chunk_coord, chunk_data in pairs(self.local_world.chunks) do
            for tile_coord, tile_instance in pairs(chunk_data) do
                local chunk_x, chunk_y = SplitKey(chunk_coord)
                local tile_x, tile_y = SplitKey(tile_coord)
                TILE_REGISTRY[tile_instance.tile_key]:C_AddSpriteBatch(chunk_x * CHUNK_WIDTH * 16 + tile_x * 16, chunk_y * CHUNK_HEIGHT * 16 + tile_y * 16, tile_instance.bit)
            end
        end
        C_DrawTileSBs()

        if CLIENT_CONFIG.render_debug then
            local mx, my = GetMousePositionWorld(ClientCamera)
            local m_tx, m_ty = math.floor(mx / 16) % CHUNK_WIDTH, math.floor(my / 16) % CHUNK_HEIGHT
            local m_cx, m_cy = PointToChunkPos(mx, my)
            local chunk = self.local_world.chunks[m_cx .. ":" .. m_cy]
            local tile_instance = chunk and chunk[m_tx .. ":" .. m_ty]
            if chunk and tile_instance then
                local text = string.format("[%d,%d][%s]", math.floor(mx / 16), math.floor(my / 16), tile_instance.tile_key)
                if tile_instance.bit then
                    text = string.format("<#8888FF>%d<#FFFFFF>:%s", tile_instance.bit, text)
                end
                DrawText(text, mx - GetTextWidth(text, FontRegular), my - FontRegular:getHeight())
            end
        end
        ClientCamera:detach()
        if ClientCamera.scale == 1 then DrawDebugRenderer() end
        Scene.Draw(self)
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if Scene.KeyPress(self, key, scancode, isrepeat) then return true end
        if key == "z" then
            generateLocalWorld(self.local_world.chunks, false)
        end
        if key == "x" then
            generateLocalWorld(self.local_world.chunks, true)
        end
        if key == "q" then
            ClientCamera.scale = 0.2
        end
        if key == "e" then
            ClientCamera.scale = 1
        end

        if key == CLIENT_CONFIG.key_binds.toggle_debug then
            -- reloads tiles
            LoadTileRegistry()
            AutoTileChunks(self.local_world.chunks)
        end
    end,
}
