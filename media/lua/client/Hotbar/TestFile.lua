

local baseISHotbarAttachItem = ISHotbar.attachItem
function ISHotbar:attachItem(item, slot, slotIndex, slotDef, doAnim)
    baseISHotbarAttachItem(self, item, slot, slotIndex, slotDef, doAnim)

    print("Item attached to hotbar: " .. item:getType())
    print("Slot: " .. slot)
    print("Slot Index: " .. slotIndex)
    print("Slot Def: " .. slotDef.type)
end