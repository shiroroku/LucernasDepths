require "src.tileRegistry"

-- if x and y are out of chunk bounds, it tries to look into neighboring chunks, x and y are in chunk coords, todo: clean this up if possible
local function GetTileRelative(loaded_chunks, chunk, chunk_x, chunk_y, x, y)
    -- within main chunk
    if x >= 0 and x < CHUNK_WIDTH and y >= 0 and y < CHUNK_HEIGHT then
        return chunk[x .. ":" .. y]
    end

    -- within top chunk
    if (x >= 0 and x < CHUNK_WIDTH) and y < 0 and loaded_chunks[chunk_x .. ":" .. chunk_y - 1] then
        return loaded_chunks[chunk_x .. ":" .. chunk_y - 1][x .. ":" .. y % CHUNK_HEIGHT]
    end

    -- within bottom chunk
    if (x >= 0 and x < CHUNK_WIDTH) and y >= CHUNK_HEIGHT and loaded_chunks[chunk_x .. ":" .. chunk_y + 1] then
        return loaded_chunks[chunk_x .. ":" .. chunk_y + 1][x .. ":" .. y % CHUNK_HEIGHT]
    end

    -- within left chunk
    if x < 0 and (y >= 0 and y < CHUNK_HEIGHT) and loaded_chunks[chunk_x - 1 .. ":" .. chunk_y] then
        return loaded_chunks[chunk_x - 1 .. ":" .. chunk_y][x % CHUNK_WIDTH .. ":" .. y]
    end

    -- within right chunk
    if x >= CHUNK_WIDTH and (y >= 0 and y < CHUNK_HEIGHT) and loaded_chunks[chunk_x + 1 .. ":" .. chunk_y] then
        return loaded_chunks[chunk_x + 1 .. ":" .. chunk_y][x % CHUNK_WIDTH .. ":" .. y]
    end

    -- within top left chunk
    if x < 0 and y < 0 and loaded_chunks[chunk_x - 1 .. ":" .. chunk_y - 1] then
        return loaded_chunks[chunk_x - 1 .. ":" .. chunk_y - 1][x % CHUNK_WIDTH .. ":" .. y % CHUNK_HEIGHT]
    end

    -- within bottom left chunk
    if x < 0 and y >= CHUNK_HEIGHT and loaded_chunks[chunk_x - 1 .. ":" .. chunk_y + 1] then
        return loaded_chunks[chunk_x - 1 .. ":" .. chunk_y + 1][x % CHUNK_WIDTH .. ":" .. y % CHUNK_HEIGHT]
    end

    -- within top right chunk
    if x >= CHUNK_WIDTH and y < 0 and loaded_chunks[chunk_x + 1 .. ":" .. chunk_y - 1] then
        return loaded_chunks[chunk_x + 1 .. ":" .. chunk_y - 1][x % CHUNK_WIDTH .. ":" .. y % CHUNK_HEIGHT]
    end

    -- within bottom right chunk
    if x >= CHUNK_WIDTH and y >= CHUNK_HEIGHT and loaded_chunks[chunk_x + 1 .. ":" .. chunk_y + 1] then
        return loaded_chunks[chunk_x + 1 .. ":" .. chunk_y + 1][x % CHUNK_WIDTH .. ":" .. y % CHUNK_HEIGHT]
    end
end

function AutoTileChunks(chunks)
    local autotiled_chunks = {}
    for chunk_coords, chunk in pairs(chunks) do -- loop through all chunks
        local cx, cy = CoordKeyToXY(chunk_coords)
        for x = 0, CHUNK_WIDTH - 1 do
            for y = 0, CHUNK_HEIGHT - 1 do -- loop through all tiles within the chunk
                local tile_key = chunk[x .. ":" .. y].tile_key
                local tile = TILE_REGISTRY[tile_key]
                if tile.bitmasked_quads then -- if the tile has a bitmask, then we calculate it
                    local t_tile = GetTileRelative(chunks, chunk, cx, cy, x, y - 1)
                    local t = (t_tile ~= nil and tile:C_BitmaskCanConnect(t_tile.tile_key)) and 1 or 0
                    local r_tile = GetTileRelative(chunks, chunk, cx, cy, x + 1, y)
                    local r = (r_tile ~= nil and tile:C_BitmaskCanConnect(r_tile.tile_key)) and 1 or 0
                    local b_tile = GetTileRelative(chunks, chunk, cx, cy, x, y + 1)
                    local b = (b_tile ~= nil and tile:C_BitmaskCanConnect(b_tile.tile_key)) and 1 or 0
                    local l_tile = GetTileRelative(chunks, chunk, cx, cy, x - 1, y)
                    local l = (l_tile ~= nil and tile:C_BitmaskCanConnect(l_tile.tile_key)) and 1 or 0
                    local tl_tile = GetTileRelative(chunks, chunk, cx, cy, x - 1, y - 1)
                    local tl = (tl_tile ~= nil and tile:C_BitmaskCanConnect(tl_tile.tile_key) and ((t == 1 and l == 1) or (t == 0 and l == 0))) and 1 or 0
                    local tr_tile = GetTileRelative(chunks, chunk, cx, cy, x + 1, y - 1)
                    local tr = (tr_tile ~= nil and tile:C_BitmaskCanConnect(tr_tile.tile_key) and ((t == 1 and r == 1) or (t == 0 and r == 0))) and 1 or 0
                    local bl_tile = GetTileRelative(chunks, chunk, cx, cy, x - 1, y + 1)
                    local bl = (bl_tile ~= nil and tile:C_BitmaskCanConnect(bl_tile.tile_key) and ((b == 1 and l == 1) or (b == 0 and l == 0))) and 1 or 0
                    local br_tile = GetTileRelative(chunks, chunk, cx, cy, x + 1, y + 1)
                    local br = (br_tile ~= nil and tile:C_BitmaskCanConnect(br_tile.tile_key) and ((b == 1 and r == 1) or (b == 0 and r == 0))) and 1 or 0
                    chunk[x .. ":" .. y].bit = tl * 1 + t * 2 + tr * 4 + l * 8 + r * 16 + bl * 32 + b * 64 + br * 128
                end
            end
        end
    end
    return autotiled_chunks
end
