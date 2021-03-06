--[[
    Sonaran CAD Plugins

    Plugin Name: wraithv2
    Creator: SonoranCAD
    Description: Implements plate auto-lookup for the wraithv2 plate reader by WolfKnight

    Put all server-side logic in this file.
]]

local pluginConfig = Config.GetPluginConfig("wraithv2")

if pluginConfig.enabled then

    if pluginConfig.useExpires == nil then
        pluginConfig.useExpires = true
    end
    if pluginConfig.useMiddleInitial == nil then
        pluginConfig.useMiddleInitial = true
    end

    wraithLastPlates = { locked = nil, scanned = nil }

    exports('cadGetLastPlates', function() return wraithLastPlates end)

    CreateThread(function()
        if pluginConfig.isPluginEnabled then
            RegisterNetEvent("wk:onPlateLocked")
            AddEventHandler("wk:onPlateLocked", function(cam, plate, index)
                debugLog(("plate lock: %s - %s - %s"):format(cam, plate, index))
                local source = source
                local ids = GetIdentifiers(source)
                plate = plate:gsub("%s+", "")
                wraithLastPlates.locked = { cam = cam, plate = plate, index = index, vehicle = cam.vehicle }
                cadPlateLookup(plate, false, function(data)
                    if cam == "front" then
                        camCapitalized = "Front"
                    elseif cam == "rear" then
                        camCapitalized = "Rear"
                    end
                    if data == nil or data.vehicleRegistrations == nil then
                        debugLog("No data returned")
                        return
                    end
                    local reg = false
                    for _, veh in pairs(data.vehicleRegistrations) do
                        if veh.vehicle.plate:lower() == plate:lower() then
                            reg = veh
                            break
                        end
                    end
                    local bolos = #data.bolos and data.bolos or false
                    if reg then
                        TriggerEvent("SonoranCAD::wraithv2:PlateLocked", source, reg, cam, plate, index)
                        local plate = reg.vehicle.plate
                        local status = reg.status
                        local expires = (reg.expiration and pluginConfig.useExpires) and ("Expires: %s<br/>"):format(reg.expiration) or ""
                        local owner = pluginConfig.useMiddleInitial and ("%s %s, %s"):format(reg.person.first, reg.person.last, reg.person.mi) or ("%s %s"):format(reg.person.first, reg.person.last)
                        TriggerClientEvent("pNotify:SendNotification", source, {
                            text = ("<b style='color:yellow'>"..camCapitalized.." ALPR</b><br/>Plate: %s<br/>Status: %s<br/>%sOwner: %s"):format(plate:upper(), status, expires, owner),
                            type = "success",
                            queue = "alpr",
                            timeout = 30000,
                            layout = "centerLeft"
                        })
                        if #bolos > 0 then
                            if bolos[1].flags then
                                local flags = table.concat(bolos[1].flags, ",")
                                TriggerClientEvent("pNotify:SendNotification", source, {
                                    text = ("<b style='color:red'>BOLO ALERT!<br/>Plate: %s<br/>Flags: %s"):format(reg.vehicle.plate:upper(), flags),
                                    type = "error",
                                    queue = "bolo",
                                    timeout = 20000,
                                    layout = "centerLeft"
                                })
                            end
                        end
                    else
                        TriggerClientEvent("pNotify:SendNotification", source, {
                            text = "<b style='color:yellow'>"..camCapitalized.." ALPR</b><br/>Plate: "..plate:upper().."<br/>Status: Not Registered",
                            type = "error",
                            queue = "alpr",
                            timeout = 15000,
                            layout = "centerLeft"
                        })
                    end
                end, ids[Config.primaryIdentifier])
            end)

            RegisterNetEvent("wk:onPlateScanned")
            AddEventHandler("wk:onPlateScanned", function(cam, plate, index)
                if cam == "front" then
                    camCapitalized = "Front"
                elseif cam == "rear" then
                    camCapitalized = "Rear"
                end
                debugLog(("plate scan: %s - %s - %s"):format(cam, plate, index))
                local source = source
                plate = plate:gsub("%s+", "")
                wraithLastPlates.scanned = { cam = cam, plate = plate, index = index, vehicle = cam.vehicle }
                TriggerEvent("SonoranCAD::wraithv2:PlateScanned", source, reg, cam, plate, index)
                cadPlateLookup(plate, true, function(data)
                    if data ~= nil and data.vehicleRegistrations ~= nil then
                        local reg = false
                        for _, veh in pairs(data.vehicleRegistrations) do
                            if veh.vehicle.plate:lower() == plate:lower() then
                                reg = veh
                                break
                            end
                        end
                        if reg then
                            local mi = reg.person.mi ~= "" and ", "..reg.person.mi or ""
                            local plate = reg.vehicle.plate
                            local status = reg.status
                            local expires = (reg.expiration and pluginConfig.useExpires) and ("Expires: %s<br/>"):format(reg.expiration) or ""
                            local owner = pluginConfig.useMiddleInitial and ("%s %s, %s"):format(reg.person.first, reg.person.last, reg.person.mi) or ("%s %s"):format(reg.person.first, reg.person.last)
                            if status ~= "VALID" then
                                TriggerClientEvent("pNotify:SendNotification", source, {
                                    text = ("<b style='color:yellow'>"..camCapitalized.." ALPR</b><br/>Plate: %s<br/>Status: %s<br/>%sOwner: %s"):format(plate:upper(), status, expires, owner),
                                    type = "success",
                                    queue = "alpr",
                                    timeout = 30000,
                                    layout = "centerLeft"
                                })
                            end
                        else
                            TriggerClientEvent("pNotify:SendNotification", source, {
                                text = "<b style='color:yellow'>"..camCapitalized.." ALPR</b><br/>Plate: "..plate:upper().."<br/>Status: Not Registered",
                                type = "error",
                                queue = "alpr",
                                timeout = 15000,
                                layout = "centerLeft"
                            })
                        end
                    end
                end)
            end)
        end
    end)

end
