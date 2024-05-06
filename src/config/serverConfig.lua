local json = require "libraries.json.json"
require "libraries.json.json-beautify"

SERVER_CONFIG_FILE = "server_config.json"

function DefaultServerConfig()
    return {
        hosting_ip = "0.0.0.0:12345",
        world_file = "test_world",
        update_rate = 0.05,       -- 20hz
        chunk_unload_interval = 1 -- every 1 second, unload old chunks
    }
end

SERVER_CONFIG = DefaultServerConfig()

function SaveServerConfig()
    local success, error = love.filesystem.write(SERVER_CONFIG_FILE, json.beautify(SERVER_CONFIG))
    if not success then
        error(string.format("Failed to save server config json: \"%s\"", error))
    end
end

function LoadServerConfig()
    local config_file = love.filesystem.read(SERVER_CONFIG_FILE)
    if config_file then
        local loaded = json.decode(config_file)
        for key, value in pairs(loaded) do SERVER_CONFIG[key] = value end
    end
    SaveServerConfig()
end

LoadServerConfig()
