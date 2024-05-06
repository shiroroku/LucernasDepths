require "src.components.scene"
require "src.components.ui.panel"
require "src.itemRegistry"

PlayerInventoryMenuConstructor = Scene:extend {
    init = function(self, local_player, udp_client, return_function)
        Scene.init(self, "Inventory")

        self.number_sprites = {
            love.graphics.newImage("resources/textures/ui/inventory/1.png"),
            love.graphics.newImage("resources/textures/ui/inventory/2.png"),
            love.graphics.newImage("resources/textures/ui/inventory/3.png"),
            love.graphics.newImage("resources/textures/ui/inventory/4.png"),
            love.graphics.newImage("resources/textures/ui/inventory/5.png")
        }

        self.equipment_sprites = {
            love.graphics.newImage("resources/textures/ui/inventory/trinket.png"),
            love.graphics.newImage("resources/textures/ui/inventory/torso.png"),
            love.graphics.newImage("resources/textures/ui/inventory/legs.png"),
            love.graphics.newImage("resources/textures/ui/inventory/bag.png")
        }
        self.color_sprite = love.graphics.newImage("resources/textures/ui/inventory/color.png")
        self.menu_padding = 4


        self.udp_client = udp_client
        self.return_function = return_function

        self.local_player = local_player
        self.inv_tier = local_player:GetInventoryTier() -- get from server

        self.held_slot = nil
        self.inv_w, self.inv_h = 3 + self.inv_tier, 4
        self.menu_w, self.menu_h = 19 * (6 + self.inv_tier) + 2 + self.menu_padding * 2, 19 * self.inv_h + self.menu_padding * 2
        self.menu_x, self.menu_y = Round(INTERNAL_RES_WIDTH / 2 - self.menu_w / 2), Round(INTERNAL_RES_HEIGHT / 2 - self.menu_h / 2)
        LoadItemRegistry()
    end,

    ClickSlot = function(self, slot)
        if self.held_slot then
            -- we clicked on a slot with an item
            if self.local_player:CanSetInventorySlot(slot, self.local_player:GetInventorySlot(self.held_slot).item) then
                if self.held_slot ~= slot then -- we picked up and placed in same location, no need to update
                    self.udp_client:send({
                        event = "player_inventory_move",
                        clicked_slot = slot,
                        held_slot = self.held_slot
                    })
                end
                -- we move the item client side, when the server gets the above packet it will send us a patch
                local picking_up = self.local_player:GetInventorySlot(slot)
                self.local_player:SetInventorySlot(slot, self.local_player:GetInventorySlot(self.held_slot))
                self.local_player:SetInventorySlot(self.held_slot, picking_up)
                self.held_slot = nil
            end
        else
            if self.local_player:GetInventorySlot(slot) then -- we clicked on an item with an empty hand
                self.held_slot = slot
            end
        end
    end,

    Draw = function(self)
        love.graphics.setColor({ 0, 0, 0, 0.75 })
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
        love.graphics.setColor({ 1, 1, 1, 1 })


        DrawPanel(self.menu_x - self.menu_padding, self.menu_y - self.menu_padding, self.menu_w, self.menu_h)
        C_ClearItemSBs()

        local slot = 0
        local mouse_x, mouse_y = GetMousePosition()

        -- equipment
        for y = 0, 3 do
            local sx, sy = self.menu_x, self.menu_y + y * 19
            DrawPanel(sx, sy, 18, 18, PanelIn)
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.rectangle("fill", sx, sy, 18, 18)
            love.graphics.setColor(1, 1, 1, 1)
            local slot_instance = self.local_player:GetInventorySlot(slot)
            if slot_instance and slot ~= self.held_slot then
                print(slot_instance)
                ITEM_REGISTRY[slot_instance.item]:C_AddSpriteBatch(sx + 1, sy + 1)
                goto continue
            end
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.draw(self.equipment_sprites[y + 1], sx, sy)
            love.graphics.setColor(1, 1, 1, 1)
            ::continue::

            -- mouse highlight
            if IsMouseWithin(mouse_x, mouse_y, sx, sy, 18, 18) then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.15)
                love.graphics.rectangle("fill", sx, sy, 18, 18)
                love.graphics.setColor(1, 1, 1, 1)
            end

            slot = slot + 1
        end

        -- bag inv
        for y = 0, self.inv_h - 1 do
            for x = 0, self.inv_w - 1 do
                local sx, sy = self.menu_x + self.menu_w + x * 19 - self.inv_w * 19 - self.menu_padding * 2, self.menu_y + self.menu_h + y * 19 - self.inv_h * 19 - self.menu_padding * 2
                DrawPanel(sx, sy, 18, 18, PanelIn)
                local slot_instance = self.local_player:GetInventorySlot(slot)
                if slot_instance and slot ~= self.held_slot then
                    ITEM_REGISTRY[slot_instance.item]:C_AddSpriteBatch(sx + 1, sy + 1)
                end
                if y == 0 then
                    love.graphics.setColor(0, 0, 0, 0.4)
                    love.graphics.rectangle("fill", sx, sy, 18, 18)
                    if not slot_instance or slot == self.held_slot then
                        love.graphics.setColor(1, 1, 1, 0.6)
                        love.graphics.draw(self.number_sprites[x + 1], sx, sy)
                    end
                    love.graphics.setColor(1, 1, 1, 1)
                end

                -- mouse highlight
                if IsMouseWithin(mouse_x, mouse_y, sx, sy, 18, 18) then
                    love.graphics.setColor(0.5, 0.5, 0.5, 0.15)
                    love.graphics.rectangle("fill", sx, sy, 18, 18)
                    love.graphics.setColor(1, 1, 1, 1)
                end

                slot = slot + 1
            end
        end

        -- player colors button
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", self.menu_x + 19, self.menu_y, 19 * 2, self.menu_h - self.menu_padding * 2 - 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.color_sprite, self.menu_x + 19 + 19 * 2 - 4, self.menu_y)

        -- draws held item
        if self.held_slot and self.local_player:GetInventorySlot(self.held_slot) then
            ITEM_REGISTRY[self.local_player:GetInventorySlot(self.held_slot).item]:C_AddSpriteBatch(mouse_x - 8, mouse_y - 8)
        end

        C_DrawItemSBs()
        Scene.Draw(self)
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if Scene.KeyPress(self, key, scancode, isrepeat) then return true end
        if key == CLIENT_CONFIG.key_binds.back or key == CLIENT_CONFIG.key_binds.inventory then
            self.return_function()
            return true
        end
    end,

    MousePress = function(self, mx, my, mouse_button)
        Scene.MousePress(self, mx, my, mouse_button)
        local slot = 0

        -- equipment
        for y = 0, 3 do
            local sx, sy = self.menu_x, self.menu_y + y * 19
            if IsMouseWithin(mx, my, sx, sy, 18, 18) then
                self:ClickSlot(slot)
            end
            slot = slot + 1
        end

        -- bag inv
        for y = 0, self.inv_h - 1 do
            for x = 0, self.inv_w - 1 do
                local sx, sy = self.menu_x + self.menu_w + x * 19 - self.inv_w * 19 - self.menu_padding * 2, self.menu_y + self.menu_h + y * 19 - self.inv_h * 19 - self.menu_padding * 2
                if IsMouseWithin(mx, my, sx, sy, 18, 18) then
                    self:ClickSlot(slot)
                end
                slot = slot + 1
            end
        end

        return true
    end
}
