local chunk, seed, chunk_x, chunk_y, tile_x, tile_y, CHUNK_WIDTH, CHUNK_HEIGHT = ...
local size = 24

local n = love.math.noise((chunk_x * CHUNK_WIDTH + tile_x + seed) / size, (chunk_y * CHUNK_HEIGHT + tile_y + seed) / size)

---@type TileInstance
local tile_instance = { key = "dirt_wall" }
if n < 0.9 then tile_instance.key = "grass" end
if n < 0.8 then tile_instance.key = "dirt" end
if n < 0.65 then tile_instance.key = "grass" end
if n < 0.5 then tile_instance.key = "dirt_wall" end
if n < 0.3 then tile_instance.key = "stone_wall" end

-- spawn circle
if chunk_x == 0 and chunk_y == 0 then
    local d = math.sqrt((math.floor(CHUNK_WIDTH / 2) - tile_x) ^ 2 + (math.floor(CHUNK_HEIGHT / 2) - tile_y) ^ 2)
    if d <= 5 then tile_instance.key = "grass" end
    if d <= 3 then tile_instance.key = "dirt" end
    if d == 5 then tile_instance.key = "stone_wall" end
end

chunk[tile_x .. ":" .. tile_y] = tile_instance
