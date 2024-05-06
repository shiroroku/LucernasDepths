local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.world.entities.playerEntity"

-- tile in the chunk is not the same as a tile in the tilemap
-- tiles in chunks are called tile_instances, which only contain data relevant to its existence (to reduce file and packet size)
-- tile_instances have a tile_key (tilemap:tile) for looking up additional static info such as quads, bitmasks, and default properties
-- tiles in tilesmaps are the json elements found within the tilemaps tiles array in the json file

CHUNK_WIDTH = 16
CHUNK_HEIGHT = 16

-- converts x, y to "x:y"
function XYToCoordKey(x, y)
    return x .. ":" .. y
end

---@class TileInstance
---@field tile_key string the tiles name, ex "dirt", "stone_wall"
---@field damage number? how much health the tile has, 0.0-1.0, nil if full health
---@field bit number? added by the autotiler for rendering the bitmask
---@field last_damaged number? last server tick that this tile was damaged
TileInstance = {}

---@class Chunk
---@alias coordKey string a string which contains coords "x:y"
---@type table<coordKey, TileInstance>
Chunk = {}

-- Converts "x:y" to x, y
function CoordKeyToXY(coords)
    local parsed_coords = {}
    for str in string.gmatch(coords, "([^:]+)") do table.insert(parsed_coords, str) end
    return tonumber(parsed_coords[1]), tonumber(parsed_coords[2])
end

local genScript, err = love.filesystem.load("resources/scripts/chunkGen.lua")
if err then error(err) end

---Generates the chunk at xy, this calls the chunkGen script in resources
---@param world any
---@param chunk_x integer
---@param chunk_y integer
---@return Chunk
local function GenChunk(world, chunk_x, chunk_y)
    local chunk = {}
    local seed = world.properties.noise_seed
    for x = 0, CHUNK_WIDTH - 1 do
        for y = 0, CHUNK_HEIGHT - 1 do
            genScript(chunk, seed, chunk_x, chunk_y, x, y, CHUNK_WIDTH, CHUNK_HEIGHT)
        end
    end
    return chunk
end

-- saves chunk data to world folder
local function SaveChunk(world_name, chunk_x, chunk_y, chunk_data)
    local region = string.format("[%d][%d]", math.floor(chunk_x / CHUNK_WIDTH), math.floor(chunk_y / CHUNK_HEIGHT))
    local chunk_folder = string.format("worlds/%s/chunks/%s/", world_name, region)
    if not love.filesystem.createDirectory(chunk_folder) then
        error(string.format("Failed to save chunk (%d:%d) for world \"%s\"!", chunk_x, chunk_y, world_name))
    end
    local chunk_file = string.format("%s[%d][%d].bin", chunk_folder, chunk_x, chunk_y)
    if not love.filesystem.write(chunk_file, EncodeAndCompress(chunk_data)) then
        error(string.format("Failed to save chunk (%d:%d) for world \"%s\"!", chunk_x, chunk_y, world_name))
    end
end

local function LoadOrGenChunk(world, chunk_x, chunk_y)
    local chunk = {}
    local region = string.format("[%d][%d]", math.floor(chunk_x / CHUNK_WIDTH), math.floor(chunk_y / CHUNK_HEIGHT))
    local chunk_folder = string.format("worlds/%s/chunks/%s/", world.name, region)
    local chunk_file = string.format("%s[%d][%d].bin", chunk_folder, chunk_x, chunk_y)
    local chunk_data = love.filesystem.read(chunk_file)
    if chunk_data then
        chunk = DecompressAndDecode(chunk_data)
    else
        -- generate
        chunk = GenChunk(world, chunk_x, chunk_y)
        SaveChunk(world.name, chunk_x, chunk_y, chunk)
    end
    return chunk
end

function LoadOrGenWorld(world_name)
    local world = {
        players = {},
        name = world_name
    }
    local path = string.format("worlds/%s/", world_name)

    -- file directories
    if not love.filesystem.createDirectory(path) then
        error(string.format("Failed to create world folder for world \"%s\"!", world_name))
    end
    if not love.filesystem.createDirectory(string.format("worlds/%s/chunks/", world_name)) then
        error(string.format("Failed to create chunk folder for world \"%s\"!", world_name))
    end
    if not love.filesystem.createDirectory(string.format("worlds/%s/players/", world_name)) then
        error(string.format("Failed to create player data folder for world \"%s\"!", world_name))
    end

    -- load properties
    local world_properties = love.filesystem.read(path .. "properties.json")
    if world_properties then
        world.properties = json.decode(world_properties)
    else
        -- default world properties
        world.properties = {
            noise_seed = math.random(999999),
            ticks = 0
        }
        if not love.filesystem.write(path .. "properties.json", json.beautify(world.properties)) then
            error(string.format("Failed to create properties file for world \"%s\"!", world_name))
        end
    end

    -- load chunks
    local preload_distance = 1 -- 1 in each direction
    for x = -preload_distance, preload_distance do
        for y = -preload_distance, preload_distance do
            if not world.chunks then world.chunks = {} end
            world.chunks[XYToCoordKey(x, y)] = LoadOrGenChunk(world, x, y)
        end
    end

    Log(string.format("Loaded world \"%s\"!", world_name, COLORS.green))
    return world
end

function GetChunk(world, chunk_x, chunk_y)
    -- try to get loaded chunk
    local chunk = world.chunks[XYToCoordKey(chunk_x, chunk_y)]
    if not chunk then
        -- loads chunk into world, if it doesnt exist then returns it
        chunk = LoadOrGenChunk(world, chunk_x, chunk_y)
        world.chunks[XYToCoordKey(chunk_x, chunk_y)] = chunk
        Log(string.format("Loaded in chunk (%d:%d)", chunk_x, chunk_y))
    end
    return chunk
end

-- removes chunk from world table, saves it to file
function UnloadChunk(world, chunk_x, chunk_y)
    SaveChunk(world.name, chunk_x, chunk_y, world.chunks[XYToCoordKey(chunk_x, chunk_y)])
    world.chunks[XYToCoordKey(chunk_x, chunk_y)] = nil
    Log(string.format("Unloaded chunk (%d:%d)", chunk_x, chunk_y), COLORS.grey)
end

function UnloadWorld(world)
    if not love.filesystem.write(string.format("worlds/%s/%s", world.name, "properties.json"), json.beautify(world.properties)) then
        error(string.format("Failed to save world properties file for world \"%s\"!", world.name))
    end
    for chunk_coords, _ in pairs(world.chunks) do
        UnloadChunk(world, CoordKeyToXY(chunk_coords))
    end
end

---Gets chunk xy from a pixel xy
---@param x number
---@param y number
---@return integer
---@return integer
function PointToChunkPos(x, y)
    return math.floor((x / 16) / CHUNK_WIDTH), math.floor((y / 16) / CHUNK_HEIGHT)
end

---Gets a tiles xy from a pixel xy
---@param x number
---@param y number
---@return integer
---@return integer
function PointToTilePos(x, y)
    return math.floor((x / 16)), math.floor((y / 16))
end

---Gets chunk xy from a tiles xy
---@param x integer
---@param y integer
---@return integer
---@return integer
function TilePosToChunkPos(x, y)
    return math.floor(x / CHUNK_WIDTH), math.floor(y / CHUNK_HEIGHT)
end

---Returns TileInstance from the pixel xy
---@param world any
---@param x number
---@param y number
---@return TileInstance | nil
function GetTileInstanceFromPoint(world, x, y)
    local chunk_x, chunk_y = PointToChunkPos(x, y)
    local chunk = world.chunks[XYToCoordKey(chunk_x, chunk_y)]
    if not chunk then return nil end
    return chunk[XYToCoordKey(math.floor((x / 16) % CHUNK_WIDTH), math.floor((y / 16) % CHUNK_HEIGHT))]
end

---Returns Tile from the pixel xy
---@param world any
---@param x number
---@param y number
---@return Tile
function GetTileFromPoint(world, x, y)
    local tile_instance = GetTileInstanceFromPoint(world, x, y)
    if tile_instance then
        return TILE_REGISTRY[tile_instance.tile_key]
    end
    return TILE_REGISTRY["missing"]
end

---Sets the TileInstance in a world
---@param world any
---@param tile_x integer
---@param tile_y integer
---@param tile_instance TileInstance
function SetTile(world, tile_x, tile_y, tile_instance)
    Log("set block at " .. tile_x .. ":" .. tile_y)
    local txr, tyr = TilePosToChunkPos(tile_x, tile_y)
    world.chunks[XYToCoordKey(txr, tyr)][XYToCoordKey(tile_x % CHUNK_WIDTH, tile_y % CHUNK_HEIGHT)] = tile_instance
end
