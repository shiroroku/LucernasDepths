local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.lang"
require "src.components.item"

--- @type table<string, love.SpriteBatch>
local item_sprite_batches = {}

--- @type table<string, Item>
ITEM_REGISTRY = {}

function LoadItemRegistry()
    ITEM_REGISTRY = {}
    item_sprite_batches = {}

    -- loop through item folder
    local path = "resources/items/"
    for _, item_filename in pairs(love.filesystem.getDirectoryItems(path)) do
        if not string.find(item_filename, ".json") then goto continue end -- we only want .json
        local item_json = json.decode(love.filesystem.read(string.format("%s%s", path, item_filename)))

        -- COMMON
        local properties = item_json.properties
        local key = item_filename:gsub(".json", "")
        local item = Item(key, properties)

        -- CLIENT
        local item_atlas = string.format("resources/textures/%s", item_json.texture.atlas)
        local atlas_texture = love.graphics.newImage(item_atlas)
        if not item_sprite_batches[item_atlas] then
            item_sprite_batches[item_atlas] = love.graphics.newSpriteBatch(atlas_texture)
        end
        item.sprite_batch = item_sprite_batches[item_atlas]
        item.quad = love.graphics.newQuad(item_json.texture.u * 16, item_json.texture.v * 16, 16, 16, atlas_texture:getDimensions())

        ITEM_REGISTRY[key] = item
        ::continue::
    end
end

-- clears all item sprite batches
function C_ClearItemSBs()
    for _, sb in pairs(item_sprite_batches) do sb:clear() end
end

-- draws all item sprite batches
function C_DrawItemSBs()
    for _, sb in pairs(item_sprite_batches) do love.graphics.draw(sb) end
end
