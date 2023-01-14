local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local isLoggedIn = LocalPlayer.state.isLoggedIn
local playerPed = PlayerPedId()
local playerCoords = GetEntityCoords(playerPed)
local closestCityhall = nil
local inCityhallPage = false
local inRangeCityhall = false
local pedsSpawned = false
local table_clone = table.clone
local blips = {}

-- Functions

local function getClosestHall()
    local distance = #(playerCoords - Config.Cityhalls[1].coords)
    local closest = 1
    for i = 1, #Config.Cityhalls do
        local hall = Config.Cityhalls[i]
        local dist = #(playerCoords - hall.coords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

local function setCityhallPageState(bool, message)
    if message then
        TriggerEvent('qb-cityhall:client:CityHallMenu')
    end
    inCityhallPage = bool
    if not Config.UseTarget or bool then return end
    inRangeCityhall = false
end

local function createBlip(options)
    if not options.coords or type(options.coords) ~= 'table' and type(options.coords) ~= 'vector3' then return error(('createBlip() expected coords in a vector3 or table but received %s'):format(options.coords)) end
    local blip = AddBlipForCoord(options.coords.x, options.coords.y, options.coords.z)
    SetBlipSprite(blip, options.sprite or 1)
    SetBlipDisplay(blip, options.display or 4)
    SetBlipScale(blip, options.scale or 1.0)
    SetBlipColour(blip, options.colour or 1)
    SetBlipAsShortRange(blip, options.shortRange or false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(options.title or 'No Title Given')
    EndTextCommandSetBlipName(blip)
    return blip
end

local function deleteBlips()
    if not next(blips) then return end
    for i = 1, #blips do
        local blip = blips[i]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

local function initBlips()
    for i = 1, #Config.Cityhalls do
        local hall = Config.Cityhalls[i]
        if hall.showBlip then
            blips[#blips+1] = createBlip({
                coords = hall.coords,
                sprite = hall.blipData.sprite,
                display = hall.blipData.display,
                scale = hall.blipData.scale,
                colour = hall.blipData.colour,
                shortRange = true,
                title = hall.blipData.title
            })
        end
    end
end

local function spawnPeds()
    if not Config.Peds or not next(Config.Peds) or pedsSpawned then return end
    for i = 1, #Config.Peds do
        local current = Config.Peds[i]
        current.model = type(current.model) == 'string' and joaat(current.model) or current.model
        RequestModel(current.model)
        while not HasModelLoaded(current.model) do
            Wait(0)
        end
        local ped = CreatePed(0, current.model, current.coords.x, current.coords.y, current.coords.z, current.coords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskStartScenarioInPlace(ped, current.scenario, true, true)
        current.pedHandle = ped
        if Config.UseTarget then
            local opts = nil
            if current.cityhall then
                opts = {
                    label = 'Open Cityhall',
                    icon = 'fa-solid fa-city',
                    action = function()
                        inRangeCityhall = true
                        setCityhallPageState(true, true)
                    end
                }
            end
            if opts then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {opts},
                    distance = 2.0
                })
            end
        else
            local options = current.zoneOptions
            if options then
                local zone = BoxZone:Create(current.coords.xyz, options.length, options.width, {
                    name = "zone_cityhall_"..ped,
                    heading = current.coords.w,
                    debugPoly = false,
                    minZ = current.coords.z - 3.0,
                    maxZ = current.coords.z + 2.0
                })
                zone:onPlayerInOut(function(inside)
                    if isLoggedIn and closestCityhall then
                        if inside then
                            if current.cityhall then
                                inRangeCityhall = true
                                exports['qb-core']:DrawText('[E] Open Cityhall')
                            end
                        else
                            exports['qb-core']:HideText()
                            if current.cityhall then
                                inRangeCityhall = false
                            end
                        end
                    end
                end)
            end
        end
    end
    pedsSpawned = true
end

local function deletePeds()
    if not Config.Peds or not next(Config.Peds) or not pedsSpawned then return end
    for i = 1, #Config.Peds do
        local current = Config.Peds[i]
        if current.pedHandle then
            DeletePed(current.pedHandle)
        end
    end
    pedsSpawned = false
end

-- Menus

RegisterNetEvent('qb-cityhall:client:CityHallMenu', function()
    exports['qb-menu']:openMenu({
        {
            header = 'City Hall',
            icon = 'fas fa-building',
            isMenuHeader = true,
        },
        {
            header = 'IDENTITY',
            txt = 'Get Your Identity Cards',
            icon = 'fas fa-address-card',
            params = {
                event = 'qb-cityhall:client:CardsMenu',
            }
        },
        {
            header = 'EMPLOYMENT',
            txt = 'City Jobs',
            icon = 'fas fa-briefcase',
            params = {
                event = 'qb-cityhall:client:JobMenu',
            }
        },
        {
            header = 'Close',
            txt = '',
            icon = 'fas fa-x',
            params = {
                event = 'qb-menu:client:closeMenu',
            }
        },
    })
end)

RegisterNetEvent('qb-cityhall:client:JobMenu', function()
    local staffList = {}
    inRangeCityhall = true

    staffList[#staffList + 1] = {
        isMenuHeader = true,
        header = 'City Hall',
        icon = 'fas fa-building'
    }

    for k,v in pairs(Config.Cityhalls[closestCityhall].jobs) do
        staffList[#staffList + 1] = {
            header = v .. ' >',
            txt = k,
            icon = 'fas fa-briefcase',
            params = {
                event = 'qb-cityhall:client:ApplyJob',
                args = {
                    job = k
                }
            }
        }
    end

    staffList[#staffList + 1] = {
        header = 'back',
        txt = '',
        icon = 'fas fa-angle-left',
        params = {
            event = 'qb-cityhall:client:CityHallMenu',
        }
    }
    exports['qb-menu']:openMenu(staffList)
end)

RegisterNetEvent('qb-cityhall:client:CardsMenu', function()
    local staffList = {}
    inRangeCityhall = true

    staffList[#staffList + 1] = {
        isMenuHeader = true,
        header = 'City Hall',
        icon = 'fas fa-building'
    }

    for k,v in pairs(Config.Cityhalls[closestCityhall].licenses) do
        staffList[#staffList + 1] = {
            header = v.label .. ' >',
            txt =  "$" .. v.cost,
            icon = 'fas fa-address-card',
            params = {
                event = 'qb-cityhall:client:requestId',
                args = {
                    type = k,
                    data = v
                }
            }
        }
    end

    staffList[#staffList + 1] = {
        header = 'back',
        txt = '',
        icon = 'fas fa-angle-left',
        params = {
            event = 'qb-cityhall:client:CityHallMenu',
        }
    }
    exports['qb-menu']:openMenu(staffList)
end)

-- Events

RegisterNetEvent('qb-cityhall:client:ApplyJob', function(data)
    if inRangeCityhall then
        TriggerServerEvent('qb-cityhall:server:ApplyJob', data.job, Config.Cityhalls[closestCityhall].coords)
    else
        QBCore.Functions.Notify(Lang:t('error.not_in_range'), 'error')
    end
end)

RegisterNetEvent('qb-cityhall:client:requestId', function(data)
    local license = Config.Cityhalls[closestCityhall].licenses[data.type]
    if inRangeCityhall and license then
        TriggerServerEvent('qb-cityhall:server:requestId', data.type, closestCityhall)
        QBCore.Functions.Notify(('You have received your %s for $%s'):format(license.label, data.cost), 'success', 3500)
    else
        QBCore.Functions.Notify(Lang:t('error.not_in_range'), 'error')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    spawnPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
    deletePeds()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('qb-cityhall:client:getIds', function()
    TriggerServerEvent('qb-cityhall:server:getIDs')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteBlips()
    deletePeds()
end)

-- Threads

CreateThread(function()
    while true do
        if isLoggedIn then
            playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
            closestCityhall = getClosestHall()
        end
        Wait(1000)
    end
end)

CreateThread(function()
    initBlips()
    spawnPeds()
    QBCore.Functions.TriggerCallback('qb-cityhall:server:receiveJobs', function(result)
    end)
    if not Config.UseTarget then
        while true do
            local sleep = 1000
            if isLoggedIn and closestCityhall then
                if inRangeCityhall then
                    if not inCityhallPage then
                        sleep = 0
                        if IsControlJustPressed(0, 38) then
                            setCityhallPageState(true, true)
                            exports['qb-core']:KeyPressed()
                            Wait(500)
                            exports['qb-core']:HideText()
                            sleep = 1000
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end
end)