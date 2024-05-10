local enet = require "enet"
require "src.helperFunctions"

UdpServer = {}

function UdpServer:getClients()
    return self.clients
end

function UdpServer:new(ip, event_table)
    local o = {}
    setmetatable(o, { __index = self })
    self.udp = enet.host_create(ip or "0.0.0.0:12345")
    self.clients = {}
    self.event_table = event_table or {}
    return o
end

function UdpServer:update()
    repeat
        local event = self.udp:service()
        if event then
            -- receive, connect, and disconnect are enet values
            if event.type == "receive" then
                local success, data = pcall(DecompressAndDecode, event.data)
                if success then
                    if self.event_table[data.event] then self.event_table[data.event](event, data) end
                else
                    Log(string.format("Recived malformed packet from %s!", tostring(event.peer)), COLORS.red)
                end
            elseif event.type == "connect" then
                Log(tostring(event.peer) .. " connected", COLORS.grey)
                table.insert(self.clients, event.peer)
                if self.event_table["connected"] then self.event_table["connected"](event) end
            elseif event.type == "disconnect" then
                Log(tostring(event.peer) .. " disconnected", COLORS.grey)
                for key, value in pairs(self.clients) do
                    if value == event.peer then table.remove(self.clients, key) end
                end
                if self.event_table["disconnected"] then self.event_table["disconnected"](event) end
            end
        end
    until event == nil
end

function UdpServer:send(peer, table_data) peer:send(EncodeAndCompress(table_data)) end

function UdpServer:broadcast(table_data) self.udp:broadcast(EncodeAndCompress(table_data)) end

function UdpServer:quit()
    self.udp:flush()
    for _, value in pairs(self.clients) do value:disconnect_now() end
    self.udp:destroy()
end
