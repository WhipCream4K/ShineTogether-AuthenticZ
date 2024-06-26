require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISDropWorldItemAction"

LuaEventManager.AddEvent("onItemRemovedFromSquare")

local baseTransferItem = ISInventoryTransferAction.transferItem
function ISInventoryTransferAction:transferItem(item)
    baseTransferItem(self,item)
    
    if item:getWorldItem() ~= nil then
        triggerEvent("onItemFall", item)
    end

    if self.srcContainer:getType() == "floor" and item:getWorldItem() == nil then
        triggerEvent("onItemRemovedFromSquare", item)
    end
end

local baseISDropWorldItemActionPerform = ISDropWorldItemAction.perform
function ISDropWorldItemAction:perform()
    baseISDropWorldItemActionPerform(self)
    triggerEvent("onItemFall", self.item)
end