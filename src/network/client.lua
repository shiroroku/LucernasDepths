local enet = require "enet"

---@class GameClient
GameClient = {}

-- disconnect numbers:
-- 1 - timeout
-- 2 - closed

---Creates a new enet client connection
---@param ip string
---@param disconnect_callback function called when the client is disconnected by the server or times out
---@param event_table function[] events that are called when receiving data
---@param timeout number how many ticks until we give up on trying to connect
---@return GameClient
function GameClient:new(ip, disconnect_callback, event_table, timeout)
    local o = {}
    setmetatable(o, { __index = self })
    self.timeout_duration = timeout or 10
    self.timeout = 0
    self.connected = false
    self.event_table = event_table or {}
    self.udpHost = enet.host_create()
    self.udpPeer = self.udpHost:connect(ip)
    self.udpPeer:ping_interval(1)
    self.disconnect_callback = disconnect_callback or function() end
    ShowLoadingScreen() --might not be needed
    return o
end

function GameClient:update(dt)
    repeat
        local event = self.udpHost:service()
        if event then
            if event.type == "receive" then
                local success, data = pcall(DecompressAndDecode, event.data)
                if success then
                    if self.event_table[data.event] then self.event_table[data.event](event, data) end
                else
                    Log(string.format("Recived malformed packet from %s!", tostring(event.peer)), COLORS.red)
                end
            elseif event.type == "connect" then
                self.connected = true
                Log(string.format("Connected to %s", tostring(self.udpPeer)), COLORS.green)
                if self.event_table["connected"] then self.event_table["connected"](event) end
                HideLoadingScreen() --might not be needed
            elseif event.type == "disconnect" then
                self.connected = false
                Log(string.format("Disconnected from %s", tostring(self.udpPeer)), COLORS.red)
                if self.event_table["disconnected"] then self.event_table["disconnected"](event) end
                self.disconnect_callback(event.data)
            end
        end
    until event == nil

    if not self.connected then -- ensure we are connected
        if self.timeout >= self.timeout_duration then
            self.timeout = -1
            Log(string.format("Connection to %s timed out", tostring(self.udpPeer)), COLORS.red)
            self.disconnect_callback(1)
        elseif self.timeout >= 0 then
            self.timeout = self.timeout + dt
        end
        return false
    end

    return true
end

function GameClient:quit()
    self.udpPeer:disconnect_now()
    self.udpPeer = nil
    self.udpHost:flush()
    --self.udpHost:destroy() ?
end

function GameClient:send(table_data) self.udpPeer:send(EncodeAndCompress(table_data)) end

function GameClient:getPing() return self.udpPeer:round_trip_time() end
