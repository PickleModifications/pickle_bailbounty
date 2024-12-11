if GetResourceState('ox_inventory') ~= 'started' then return end

Inventory = {}

Inventory.Items = {}

Inventory.Ready = false

RegisterNetEvent("pickle_bailbounty:setupInventory", function(data)
    Inventory.Items = data.items
    Inventory.Ready = true
end)

RegisterNetEvent("pickle_bailbounty:updateInventory", function(inventory) 
    -- RefreshInventory(inventory)
end)

function InitializeInventory()
end