require "src.config.clientConfig"
require "src.menus.pauseMenu"
require "src.helperFunctions"
require "src.network.client"
require "src.components.scene"
require "src.world.entities.playerEntity"
require "src.world.characters"
require "src.world.autotiler"
require "src.components.ui.messagebox"
require "src.tileRegistry"
local Camera = require "libraries.Camera"

local client --todo make this less annoying to access

local num_tiles_drawn = 0
function GetNumberTilesDrawn()
	return num_tiles_drawn
end

function GetServerConnection()
	return client
end

InGameSceneConstructor = Scene:extend {

	init = function(self)
		Scene.init(self, "In-Game")
	end,

	Load = function(self)
		ShowLoadingScreen()
		Scene.Load(self)
		self.update_rate = 0.01 -- 100Hz, the rate that the client sends inputs to the server
		self.local_world = {
			chunks = {},
			---@type {[string]: PlayerEntity}
			players = {}, -- [uuid]{player class}
			entities = {} -- [uuid]{extends entity}
		}
		---@type PlayerEntity
		self.local_player = PlayerEntity:new(CLIENT_CONFIG.multiplayer_name, NewUUID(), {})
		self.local_player:setSkinColors(CLIENT_CONFIG.player_skin_colors)
		self.local_player:setSkin(CLIENT_CONFIG.player_skin)
		self.local_player:C_setCharacter(CHARACTERS[CLIENT_CONFIG.player_skin](
			CLIENT_CONFIG.player_skin_colors.skin,
			CLIENT_CONFIG.player_skin_colors.clothes,
			CLIENT_CONFIG.player_skin_colors.primary,
			CLIENT_CONFIG.player_skin_colors.secondary
		))


		ClientEvents = {
			update_players = function(_, data) -- patches players which are not us
				-- data is [uuid]{data}
				for uuid, player_data in pairs(data.players) do
					if uuid ~= self.local_player:getUUID() then -- not us
						if self.local_world.players[uuid] then -- we have old data already, replace it
							self.local_world.players[uuid]:setData(player_data.data)
						else                     -- make a new player
							self.local_world.players[uuid] = PlayerEntity:new(player_data.name, player_data.uuid, player_data.data)
						end
						-- if we dont have a character made, but we can see them, then make one
						if self.local_world.players[uuid]:isLoaded() and not self.local_world.players[uuid]:C_hasCharacter() then
							local char = "chroma"
							if CHARACTERS[self.local_world.players[uuid]:getSkin()] then -- make sure we have this skin, else use chroma as default
								char = self.local_world.players[uuid]:getSkin()
							end
							local skin_colors = self.local_world.players[uuid]:getSkinColors()
							self.local_world.players[uuid]:C_setCharacter(CHARACTERS[char](
								skin_colors.skin,
								skin_colors.clothes,
								skin_colors.primary,
								skin_colors.secondary))
						end
					end
				end
			end,
			broadcast_player_connect = function(_, data)
				Log(string.format("%s Joined!", data.name), COLORS.green)
			end,
			broadcast_player_disconnect = function(_, data)
				Log(string.format("%s Left.", data.name), COLORS.green)
				self.local_world.players[data.uuid] = nil
			end,
			load_chunks = function(_, data)
				for chunk_coords, chunk_data in pairs(data.chunks) do
					self.local_world.chunks[chunk_coords] = chunk_data
				end
				local autotile_thread = coroutine.create(function() AutoTileChunks(self.local_world.chunks) end)
				coroutine.resume(autotile_thread)
			end,
			connected = function()
				Log(string.format("We connected! sending client data..."), COLORS.green)
				client:send({
					event = "player_auth",
					token = CLIENT_CONFIG.multiplayer_token, -- should be encrypted, and only sent here this one time
					uuid = self.local_player:getUUID(),
					name = CLIENT_CONFIG.multiplayer_name,
					skin = CLIENT_CONFIG.player_skin,
					skin_colors = CLIENT_CONFIG.player_skin_colors
				})
				HideLoadingScreen()
			end,
			player_data = function(_, data)
				-- patches our player
				self.local_player:setData(data.player_data)
			end
		}

		self.message_box = MessageBox:new {
			text = GetTranslation("messagebox.disconnect_closed"),
			onClose = function()
				SetScene(MainMenuScene)
			end
		}

		-- UDP Client setup
		client = GameClient:new(string.format("%s:%d", CLIENT_CONFIG.server_ip, CLIENT_CONFIG.server_port), function(code)
			HideLoadingScreen()
			if code == 1 then self.message_box.text = GetTranslation("messagebox.disconnect_timeout") end
			if code == 2 then self.message_box.text = GetTranslation("messagebox.disconnect_already_joined") end
			self.message_box:show()
		end, ClientEvents, CLIENT_CONFIG.server_timeout)


		-- Camera setup
		ClientCamera = Camera(0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
	end,

	Update = function(self, dt)
		-- dont execute more until the client is connected
		if not client:update(dt) then return end
		Scene.Update(self, dt) -- no return here

		ClientCamera:update()
		ClientCamera:follow(Round(self.local_player.client_x or 0), Round(self.local_player.client_y or 0)) -- round so we are pixel perfect

		-- only run rest of function if our player is loaded
		if not self.local_player:isLoaded() then return end

		local player_x, player_y = self.local_player:getPos()

		-- GAME TICK
		self.tick = (self.tick or 0) + dt
		if self.tick > self.update_rate then
			-- INPUT
			local inputPacket = {
				event = "input",
				inputs = {}
			}

			local dx = 0
			local dy = 0
			if love.keyboard.isDown(CLIENT_CONFIG.key_binds.up) then
				inputPacket.inputs.up = true
				dy = dy - 1
			end
			if love.keyboard.isDown(CLIENT_CONFIG.key_binds.down) then
				inputPacket.inputs.down = true
				dy = dy + 1
			end
			if love.keyboard.isDown(CLIENT_CONFIG.key_binds.left) then
				inputPacket.inputs.left = true
				dx = dx - 1
			end
			if love.keyboard.isDown(CLIENT_CONFIG.key_binds.right) then
				inputPacket.inputs.right = true
				dx = dx + 1
			end
			if not SHOW_CONSOLE and not Scene.IsSubSceneOpen(self) then -- because we cant cancel the update function in console
				client:send(inputPacket)
				self.local_player:move(self.local_world, dx, dy, dt)
			end
			self.tick = self.tick - self.update_rate
		end

		-- lerp our client player pos to keep things lookin smooth
		self.local_player.client_x = Lerp(self.local_player.client_x or 0, player_x, 0.1)
		self.local_player.client_y = Lerp(self.local_player.client_y or 0, player_y, 0.1)

		-- CHUNK UNLOADING
		self.unload_tick = (self.unload_tick or 0) + dt
		if self.unload_tick > 1 then -- unload chunks every 1 sec
			local unload_thread = coroutine.create(function()
				local needed_chunks = {} -- chunks that the player is in and surrounds them
				local player_chunk_x, player_chunk_y = PointToChunkPos(player_x, player_y)
				local chunk_distance = 1
				for x = -chunk_distance, chunk_distance do
					for y = -chunk_distance, chunk_distance do
						table.insert(needed_chunks, { x = player_chunk_x + x, y = player_chunk_y + y })
					end
				end
				-- for every loaded chunk, check to see if its in our needed list
				for chunk_coord_key, _ in pairs(self.local_world.chunks) do
					local needed = false
					local chunk_x, chunk_y = CoordKeyToXY(chunk_coord_key)
					for _, loaded_chunk in pairs(needed_chunks) do
						if loaded_chunk.x == chunk_x and loaded_chunk.y == chunk_y then
							needed = true
							break
						end
					end
					if not needed then self.local_world.chunks[chunk_coord_key] = nil end
				end
			end)
			coroutine.resume(unload_thread)

			self.unload_tick = self.unload_tick - 1
		end

		-- CLIENT SPRITES
		if self.local_player:C_hasCharacter() then
			UpdateCharacter(self.local_player:C_getCharacter(), dt, self.local_player.client_x, self.local_player.client_y)
		end
		for _, p in pairs(self.local_world.players) do
			if p:isLoaded() and p:C_hasCharacter() then
				local px, py = p:getPos()
				p.client_x, p.client_y = Lerp(p.client_x or 0, px, 0.1), Lerp(p.client_y or 0, py, 0.1)
				UpdateCharacter(p:C_getCharacter(), dt, p.client_x, p.client_y)
			end
		end
	end,

	Draw = function(self)
		love.graphics.clear(0.05, 0.05, 0.05);

		ClientCamera:attach()
		if self.local_player:isLoaded() then
			local mouse_x, mouse_y = GetMousePositionWorld(ClientCamera)
			local px, py = self.local_player:getPos()

			--TILES
			C_ClearTileSBs()
			local t_n = 0
			for chunk_coord, chunk_data in pairs(self.local_world.chunks) do
				local chunk_x, chunk_y = SplitKey(chunk_coord)
				for tile_coord, tile_instance in pairs(chunk_data) do
					local tile_x, tile_y = SplitKey(tile_coord)
					local padding = 2 -- how many extra tiles should be rendered outside the view
					local view_x, view_y = px - INTERNAL_RES_WIDTH * 0.5 - padding * 16, py - INTERNAL_RES_HEIGHT * 0.5 - padding * 16
					local view_x2, view_y2 = px + INTERNAL_RES_WIDTH * 0.5 + padding * 16, py + INTERNAL_RES_HEIGHT * 0.5 + padding * 16
					local tx, ty = (chunk_x * CHUNK_WIDTH + tile_x) * 16, (chunk_y * CHUNK_HEIGHT + tile_y) * 16
					if tx >= view_x and ty >= view_y and tx <= view_x2 and ty <= view_y2 then
						t_n = t_n + 1
						TILE_REGISTRY[tile_instance.key]:C_addToSpriteBatch(chunk_x * CHUNK_WIDTH * 16 + tile_x * 16, chunk_y * CHUNK_HEIGHT * 16 + tile_y * 16, tile_instance)
					end
				end
			end
			C_DrawTileSBs()
			num_tiles_drawn = t_n


			--TILE HIGHLIGHT (for block breaking/selecting)
			local hit, hit_x, hit_y = RayCast(px, py, mouse_x, mouse_y, self.local_player:getReach(), function(x, y) return GetTileFromPoint(self.local_world, x, y):hasProperty("solid") end)
			if hit then
				local tx, ty = PointToTilePos(hit_x, hit_y)
				love.graphics.setColor(1, 1, 1, 0.3)
				love.graphics.rectangle("line", tx * 16, ty * 16, 16, 16)
				love.graphics.setColor(1, 1, 1, 1)
			end
			if CLIENT_CONFIG.render_debug then
				if hit then
					love.graphics.setColor(0.5, 1, 0.5, 0.7)
				else
					love.graphics.setColor(1, 0.5, 0.5, 0.7)
				end
				love.graphics.rectangle("fill", hit_x - 2.5, hit_y - 2.5, 5, 5)
				love.graphics.setColor(1, 1, 1, 1)
			end

			--OTHER PLAYERS (behind player)
			local players_front = {}
			for _, player in pairs(self.local_world.players) do
				if player:isLoaded() and player:C_hasCharacter() then -- if we have player xy then draw them
					if (player.client_y or 0) > self.local_player.client_y then
						table.insert(players_front, player)
					else
						DrawCharacter(player:C_getCharacter())
					end
				end
			end

			--LOCAL PLAYER
			ClientCamera:detach()
			if self.local_player:isLoaded() and self.local_player:C_hasCharacter() then
				DrawCharacter(self.local_player:C_getCharacter(), INTERNAL_RES_WIDTH * 0.5, INTERNAL_RES_HEIGHT * 0.5)
			end
			ClientCamera:attach()

			--OTHER PLAYERS (in front of player)
			for _, player in pairs(players_front) do
				DrawCharacter(player:C_getCharacter())
			end

			--NAME PLATES
			for uuid, player in pairs(self.local_world.players) do
				if player:isLoaded() then -- if we have player xy then draw them
					local name = CLIENT_CONFIG.render_debug and string.format("<#88FF88>%s<#AAAAAA>(%s)", player:getName(), uuid) or "<#88FF88>" .. player:getName()
					DrawText(name, (player.client_x or 0) - GetTextWidth(name, FontRegular) / 2, (player.client_y or 0) - FontRegular:getHeight() / 2 - 20)
				end
			end

			--DEBUG
			if CLIENT_CONFIG.render_debug then
				local mx, my = GetMousePositionWorld(ClientCamera)
				local m_tx, m_ty = math.floor(mx / 16) % CHUNK_WIDTH, math.floor(my / 16) % CHUNK_HEIGHT
				local m_cx, m_cy = PointToChunkPos(mx, my)
				local chunk = self.local_world.chunks[XYToCoordKey(m_cx, m_cy)]
				local tile_instance = chunk and chunk[XYToCoordKey(m_tx, m_ty)]
				if chunk and tile_instance then
					local text = string.format("[%d,%d][%s]", math.floor(mx / 16), math.floor(my / 16), tile_instance.key)
					if tile_instance.bit then
						text = string.format("<#8888FF>%d<#FFFFFF>:%s", tile_instance.bit, text)
					end
					DrawText(text, mx - GetTextWidth(text, FontRegular), my - FontRegular:getHeight())
				end
			end
		end
		ClientCamera:detach()

		if self.local_player:isLoaded() then DrawDebugRenderer() end
		Scene.Draw(self)
		self.message_box:draw()
	end,

	Quit = function(self)
		Scene.Quit(self)
		client:quit()
		client = nil -- so GetServerConnection returns nil
	end,

	KeyPress = function(self, key, scancode, isrepeat)
		if self.message_box:keyPress(key, scancode, isrepeat) then return true end
		if Scene.KeyPress(self, key, scancode, isrepeat) then return true end

		-- open pause menu
		if key == CLIENT_CONFIG.key_binds.pause then
			Scene.ChangeSubScene(self, PauseMenuConstructor(function()
				Scene.ChangeSubScene(self, {})
			end))
		end

		-- open inventory
		if key == CLIENT_CONFIG.key_binds.inventory then
			Scene.ChangeSubScene(self, PlayerInventoryMenuConstructor(self.local_player, client, function()
				Scene.ChangeSubScene(self, {})
			end))
		end

		if key == CLIENT_CONFIG.key_binds.toggle_debug then
			-- reloads tiles
			LoadTileRegistry()
			AutoTileChunks(self.local_world.chunks)
		end

		if key == "p" then
			ClientCamera.scale = ClientCamera.scale == 0.2 and 1 or 0.2
		end
	end,

	MousePress = function(self, x, y, mouse_button)
		if self.message_box:mousePress(x, y, mouse_button) then return true end
		if Scene.MousePress(self, x, y, mouse_button) then return true end

		-- breaks a block
		if self.local_player:isLoaded() and client then
			local px, py = self.local_player:getPos()
			local mx, my = GetMousePositionWorld(ClientCamera)
			local hit, hit_x, hit_y = RayCast(px, py, mx, my, self.local_player:getReach(), function(tx, ty) return GetTileFromPoint(self.local_world, tx, ty):hasProperty("toughness") end)
			if hit then
				client:send({
					event = "break_block",
					x = hit_x,
					y = hit_y
				})
			end
		end
	end
}
