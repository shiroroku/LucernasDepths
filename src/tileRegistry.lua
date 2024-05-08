local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.lang"
require "src.components.tile"

--- @type table<string, love.SpriteBatch>
local tile_sprite_batches = {}

--- @type table<string, Tile>
TILE_REGISTRY = {}

function LoadTileRegistry()
    TILE_REGISTRY = {}
    tile_sprite_batches = {}

    -- loop through item folder
    local path = "resources/tiles/"
    for _, tile_filename in pairs(love.filesystem.getDirectoryItems(path)) do
        if not string.find(tile_filename, ".json") then goto continue end -- we only want .json
        local tile_json = json.decode(love.filesystem.read(string.format("%s%s", path, tile_filename)))

        -- COMMON
        local properties = tile_json.properties
        local key = tile_filename:gsub(".json", "")
        local tile = Tile:new(key, properties)

        -- CLIENT
        local tile_atlas = string.format("resources/textures/%s", tile_json.texture.atlas)
        local atlas_texture = love.graphics.newImage(tile_atlas)
        if not tile_sprite_batches[tile_atlas] then
            tile_sprite_batches[tile_atlas] = love.graphics.newSpriteBatch(atlas_texture)
        end
        tile.sprite_batch = tile_sprite_batches[tile_atlas]
        if tile_json.texture.bitmask then
            tile.bitmask_connects_to = tile_json.texture.bitmask.connects_to
            tile.bitmasked_quads = {}
            for bit, tile_coords in pairs(json.decode(love.filesystem.read(string.format("resources/textures/%s", tile_json.texture.bitmask.mapping)))) do
                tile.bitmasked_quads[tonumber(bit)] = love.graphics.newQuad(tile_coords.u * 16, tile_coords.v * 16, 16, 16, atlas_texture:getDimensions())
            end
        else
            tile.quad = love.graphics.newQuad(tile_json.texture.u * 16, tile_json.texture.v * 16, 16, 16, atlas_texture:getDimensions())
        end

        TILE_REGISTRY[key] = tile
        ::continue::
    end
end

-- clears all tile sprite batches
function C_ClearTileSBs()
    for _, sb in pairs(tile_sprite_batches) do sb:clear() end
end

-- draws all tile sprite batches
function C_DrawTileSBs()
    for _, sb in pairs(tile_sprite_batches) do love.graphics.draw(sb) end
end
