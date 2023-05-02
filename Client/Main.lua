--[[
  _____   _                                 _   _   _
 |_   _| (_)  _ __    _   _   ___          | \ | | | |
   | |   | | | '_ \  | | | | / __|         |  \| | | |    
   | |   | | | | | | | |_| | \__ \         | |\  | | |___ 
   |_|   |_| |_| |_|  \__,_| |___/  _____  |_| \_| |_____|
                                   |_____|
]]--

local LastVehicle = nil
local LastStatus = false
local LastAttach = false
local Busy = false

function GetVehicleInfo(VehicleHash)
    for Index, CurrentFlatbed in pairs(Config.Flatbeds) do
        if VehicleHash == GetHashKey(CurrentFlatbed.Hash) then
            return CurrentFlatbed
        end
    end
end

function Notify(Text)
    SetNotificationTextEntry("STRING")
	AddTextComponentString(Text)
	DrawNotification(0,1)
end

function GetVehicles()
    local AllVehicles = {}
    local CurrentHandle, CurrentVehicle = FindFirstVehicle()
    local IsNext = true

    repeat
        table.insert(AllVehicles, CurrentVehicle)
        IsNext, CurrentVehicle = FindNextVehicle()
    until not IsNext

    EndFindVehicle(CurrentHandle)

    return AllVehicles
end

function IsAllowed(Vehicle)
    local VehicleClass = GetVehicleClass(Vehicle)

    for Index, CurrentClass in pairs(Config.Blacklist) do
        if VehicleClass == CurrentClass then
            return false
        end
    end

    return true
end

function GetNearestVehicle(CheckCoords, CheckRadius)
    local ClosestVehicle = nil
    local ClosestDistance = math.huge

    for Index, CurrentVehicle in pairs(GetVehicles()) do
        if DoesEntityExist(CurrentVehicle) and IsAllowed(CurrentVehicle) then
            local CurrentCoords = GetEntityCoords(CurrentVehicle)
            local CurrentDistance = Vdist2(CheckCoords, CurrentCoords, false)

            if CurrentDistance < CheckRadius and CurrentDistance < ClosestDistance then
                ClosestVehicle = CurrentVehicle
                ClosestDistance = CurrentDistance
            end
        end
    end

    return ClosestVehicle
end

RegisterNetEvent('ti_flatbed:getProp')
AddEventHandler('ti_flatbed:getProp', function(BedInfo)
    if not BedInfo or not DoesEntityExist(NetworkGetEntityFromNetworkId(BedInfo.Prop)) then
        local VehicleInfo = GetVehicleInfo(GetEntityModel(LastVehicle))
        local NewBed = CreateObjectNoOffset(GetHashKey(Config.BedProp), GetEntityCoords(LastVehicle), true, false, false)

        AttachEntityToEntity(NewBed, LastVehicle, nil, VehicleInfo.Default.Pos, VehicleInfo.Default.Rot, true, false, true, false, nil, true)

        TriggerServerEvent("ti_flatbed:editProp", NetworkGetNetworkIdFromEntity(LastVehicle), "Prop", NetworkGetNetworkIdFromEntity(NewBed))

        LastStatus = false
        LastAttach = nil
    else
        LastStatus = BedInfo.Status
        LastAttach = NetworkGetEntityFromNetworkId(BedInfo.Attached)
    end
end)

RegisterNetEvent('ti_flatbed:action')
AddEventHandler('ti_flatbed:action', function(BedInfo, Action)
    if BedInfo and DoesEntityExist(NetworkGetEntityFromNetworkId(BedInfo.Prop)) then
        local VehicleInfo = GetVehicleInfo(GetEntityModel(LastVehicle))
        local PropID = NetworkGetEntityFromNetworkId(BedInfo.Prop)

        if Action == "lower" then
            if not BedInfo.Status then
                local BedPos = VehicleInfo.Default.Pos
                local BedRot = VehicleInfo.Default.Rot

                repeat
                    Wait(10)
                    BedPos = math.floor((BedPos - vector3(0.0, 0.02, 0.0)) * 1000) / 1000

                    if BedPos.y < VehicleInfo.Active.Pos.y then
                        BedPos = vector3(BedPos.x, VehicleInfo.Active.Pos.y, BedPos.z)
                    end

                    DetachEntity(PropID, false, false)
                    AttachEntityToEntity(PropID, LastVehicle, nil, BedPos, BedRot, true, false, true, false, nil, true)
                until BedPos.y == VehicleInfo.Active.Pos.y

                repeat
                    Wait(10)
                    if BedPos.z ~= VehicleInfo.Active.Pos.z then
                        BedPos = math.floor((BedPos - vector3(0.0, 0.0, 0.0105)) * 1000) / 1000

                        if BedPos.z < VehicleInfo.Active.Pos.z then
                            BedPos = vector3(BedPos.x, BedPos.y, VehicleInfo.Active.Pos.z)
                        end
                    end
                    if BedRot.x ~= VehicleInfo.Active.Rot.x then
                        BedRot = math.floor((BedRot + vector3(0.15, 0, 0.0)) * 1000) / 1000
                        
                        if BedRot.x > VehicleInfo.Active.Rot.x then
                            BedRot = vector3(VehicleInfo.Active.Rot.x, 0.0, 0.0)
                        end
                    end

                    DetachEntity(PropID, false, false)
                    AttachEntityToEntity(PropID, LastVehicle, nil, BedPos, BedRot, true, false, true, false, nil, true)
                until BedRot.x == VehicleInfo.Active.Rot.x and BedPos.z == VehicleInfo.Active.Pos.z
            end

            LastStatus = true
        elseif Action == "raise" then
            if not BedInfo.Status then
                local BedPos = VehicleInfo.Active.Pos
                local BedRot = VehicleInfo.Active.Rot

                repeat
                    Wait(10)
                    if BedPos.z ~= VehicleInfo.Default.Pos.z then
                        BedPos = math.floor((BedPos + vector3(0.0, 0.0, 0.0105)) * 1000) / 1000

                        if BedPos.z > VehicleInfo.Default.Pos.z then
                            BedPos = vector3(BedPos.x, BedPos.y, VehicleInfo.Default.Pos.z)
                        end
                    end
                    if BedRot.x ~= VehicleInfo.Default.Rot.x then
                        BedRot = math.floor((BedRot - vector3(0.15, 0, 0.0)) * 1000) / 1000
                        
                        if BedRot.x < VehicleInfo.Default.Rot.x then
                            BedRot = vector3(VehicleInfo.Default.Rot.x, 0.0, 0.0)
                        end
                    end

                    DetachEntity(PropID, false, false)
                    AttachEntityToEntity(PropID, LastVehicle, nil, BedPos, BedRot, true, false, true, false, nil, true)
                until BedRot.x == VehicleInfo.Default.Rot.x and BedPos.z == VehicleInfo.Default.Pos.z

                repeat
                    Wait(10)
                    BedPos = math.floor((BedPos + vector3(0.0, 0.02, 0.0)) * 1000) / 1000

                    if BedPos.y > VehicleInfo.Default.Pos.y then
                        BedPos = vector3(BedPos.x, VehicleInfo.Default.Pos.y, BedPos.z)
                    end

                    DetachEntity(PropID, false, false)
                    AttachEntityToEntity(PropID, LastVehicle, nil, BedPos, BedRot, true, false, true, false, nil, true)
                until BedPos.y == VehicleInfo.Default.Pos.y
            end

            LastStatus = false
        elseif Action == "attach" then
            if not BedInfo.Attached then
                local AttachCoords = GetOffsetFromEntityInWorldCoords(PropID, vector3(VehicleInfo.Attach.x, VehicleInfo.Attach.y, 0.0))
                --local ClosestVehicle = GetNearestVehicle(AttachCoords, VehicleInfo.Radius)
                local ClosestVehicle, vehicleCoords = lib.getClosestVehicle(AttachCoords, VehicleInfo.Radius, false)

                if DoesEntityExist(ClosestVehicle) and ClosestVehicle ~= LastVehicle then
                    local VehicleCoords = GetEntityCoords(ClosestVehicle)

                    AttachEntityToEntity(ClosestVehicle, PropID, nil, GetOffsetFromEntityGivenWorldCoords(PropID, VehicleCoords), vector3(0.0, 0.0, 0.0), true, false, true, false, nil, true)

                    TriggerServerEvent("ti_flatbed:editProp", NetworkGetNetworkIdFromEntity(LastVehicle), "Attached", NetworkGetNetworkIdFromEntity(ClosestVehicle))
                end
            end

            LastAttach = NetworkGetEntityFromNetworkId(BedInfo.Attached)
        elseif Action == "detach" then
            if BedInfo.Attached then
                local AttachedVehicle = NetworkGetEntityFromNetworkId(BedInfo.Attached)

                DetachEntity(AttachedVehicle, true, true)

                TriggerServerEvent("ti_flatbed:editProp", NetworkGetNetworkIdFromEntity(LastVehicle), "Attached", nil)
            end

            LastAttach = nil
        end
    else
        TriggerServerEvent("ti_flatbed:getProp", NetworkGetNetworkIdFromEntity(LastVehicle))
    end

    Busy = false
end)

CreateThread(function()
    while true do
        Wait(1)

        if not DoesEntityExist(LastVehicle) or NetworkGetEntityOwner(LastVehicle) ~= PlayerId() then
            LastVehicle = nil
            LastStatus = false
            LastAttach = nil
        end

        local PlayerVehicle = GetVehiclePedIsIn(cache.ped or PlayerPedId(), false)

        if PlayerVehicle ~= 0 then
            if PlayerVehicle ~= LastVehicle then
                local VehicleModel = GetEntityModel(PlayerVehicle)

                for Index, CurrentFlatbed in pairs(Config.Flatbeds) do
                    if VehicleModel == GetHashKey(CurrentFlatbed.Hash) then
                        LastVehicle = PlayerVehicle
                        
                        TriggerServerEvent("ti_flatbed:getProp", NetworkGetNetworkIdFromEntity(PlayerVehicle))
                        break
                    end
                end
            else
                if LastAttach and DoesEntityExist(LastAttach) then
                    DisableCamCollisionForEntity(LastAttach)
                end
            end
        else
            if LastVehicle then
                local PlayerCoords = GetEntityCoords(cache.ped or PlayerPedId())
                local VehicleInfo = GetVehicleInfo(GetEntityModel(LastVehicle))
                local MarkerCoords = GetOffsetFromEntityInWorldCoords(LastVehicle, VehicleInfo.Marker)

                for ExtraId, ExtraValue in pairs(VehicleInfo.Extras) do
                    if ExtraValue then
                        if not IsVehicleExtraTurnedOn(LastVehicle, ExtraId) then
                            SetVehicleExtra(LastVehicle, ExtraId, false)
                        end
                    else
                        if IsVehicleExtraTurnedOn(LastVehicle, ExtraId) then
                            SetVehicleExtra(LastVehicle, ExtraId, true)
                        end
                    end
                end

                if Vdist2(PlayerCoords, MarkerCoords) <= 50.0 and not Busy then
                    DrawMarker(
                        43,
                        MarkerCoords,
                        0.0, 0.0, 0.0,
                        GetEntityRotation(LastVehicle),
                        1.0, 1.0, 1.0,
                        255, 255, 255, 155,
                        false, false, 2, false, nil, nil, false
                    )

                    if Vdist2(PlayerCoords, MarkerCoords) <= 2.0 then
                        if not LastStatus then
                            BeginTextCommandDisplayHelp("STRING")
                            AddTextComponentSubstringPlayerName(Config.Translation.LOWER)
                            EndTextCommandDisplayHelp(0, 0, 1, -1)

                            if IsControlJustReleased(1, Config.Keys.Lower) then
                                Busy = true
                                TriggerServerEvent("ti_flatbed:action", NetworkGetNetworkIdFromEntity(LastVehicle), "lower")
                            end
                        else
                            local HelpMsg = Config.Translation.RAISE

                            if LastAttach then
                                HelpMsg = HelpMsg.."\n"..Config.Translation.DETACH
                            else
                                local BedCoords = GetOffsetFromEntityInWorldCoords(LastVehicle, VehicleInfo.Active.Pos)
                                --local ClosestVehicle = GetNearestVehicle(BedCoords - vector3(0.0, 1.0, 0.0), VehicleInfo.Radius)
                                local ClosestVehicle, vehicleCoords = lib.getClosestVehicle(BedCoords - vector3(0.0, 1.0, 0.0), VehicleInfo.Radius, false)
                                
                                if DoesEntityExist(ClosestVehicle) and ClosestVehicle ~= LastVehicle then
                                    HelpMsg = HelpMsg.."\n"..Config.Translation.ATTACH
                                end
                            end

                            BeginTextCommandDisplayHelp("STRING")
                            AddTextComponentSubstringPlayerName(HelpMsg)
                            EndTextCommandDisplayHelp(0, 0, 1, -1)

                            if IsControlJustReleased(1, Config.Keys.Raise) then
                                Busy = true
                                TriggerServerEvent("ti_flatbed:action", NetworkGetNetworkIdFromEntity(LastVehicle), "raise")
                            end

                            if IsControlJustReleased(1, Config.Keys.Attach_Detach) then
                                Busy = true
                                if LastAttach then
                                    TriggerServerEvent("ti_flatbed:action", NetworkGetNetworkIdFromEntity(LastVehicle), "detach")
                                else
                                    TriggerServerEvent("ti_flatbed:action", NetworkGetNetworkIdFromEntity(LastVehicle), "attach")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)