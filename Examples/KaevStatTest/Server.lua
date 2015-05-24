local AIO = AIO or require("AIO")

local MyHandlers = AIO.AddHandlers("Kaev", {})
local AttributesPointsLeft = {}
local AttributesPointsSpend = {}
local AttributesAuraIds = { 7464, 7471, 7477, 7468, 7474 } -- Strength, Agility, Stamina, Intellect, Spirit

local function AddPlayerStats(msg, player)
    local guid = player:GetGUIDLow()
    local spend, left = AttributesPointsSpend[guid], AttributesPointsLeft[guid]
    return msg:Add("Kaev", "SetStats", left, AIO.unpack(spend))
end
AIO.AddOnInit(AddPlayerStats)

local function UpdatePlayerStats(player)
    AddPlayerStats(AIO.Msg(), player):Send(player)
end

local function AttributesInitPoints(guid)
    AttributesPointsLeft[guid] = 5
    AttributesPointsSpend[guid] = { 0, 0, 0, 0, 0 }
end
local function AttributesDeinitPoints(guid)
    AttributesPointsLeft[guid] = nil
    AttributesPointsSpend[guid] = nil
end

local function OnLogin(event, player)
    AttributesInitPoints(player:GetGUIDLow())
end
local function OnLogout(event, player)
    AttributesDeinitPoints(player:GetGUIDLow())
end

RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(4, OnLogout)
for k,v in ipairs(GetPlayersInWorld()) do
    OnLogin(3, v)
end

function MyHandlers.AttributesIncrease(player, statId)
    if (player:IsInCombat()) then
        player:SendBroadcastMessage("Du kannst während einem Kampfes keine Attributspunkte verteilen.")
    else
        local guid = player:GetGUIDLow()
        local spend, left = AttributesPointsSpend[guid], AttributesPointsLeft[guid]
        if not spend or not left then
            return
        end
        if not statId or not spend[statId] then
            return
        end
        if (left <= 0) then
            player:SendBroadcastMessage("Du hast nicht genuegend Attributspunkte.")
        else
            AttributesPointsLeft[guid] = left - 1
            spend[statId] = spend[statId] + 1
            local aura = player:GetAura(AttributesAuraIds[statId])
            if (aura) then
                aura:SetStackAmount(spend[statId])
            else
                player:AddAura(AttributesAuraIds[statId], player)
            end
            UpdatePlayerStats(player)
        end
    end
end

function MyHandlers.AttributesDecrease(player, statId)
    if (player:IsInCombat()) then
        player:SendBroadcastMessage("Du kannst während einem Kampfes keine Attributspunkte verteilen.")
    else
        local guid = player:GetGUIDLow()
        local spend, left = AttributesPointsSpend[guid], AttributesPointsLeft[guid]
        if not spend or not left then
            return
        end
        if not statId or not spend[statId] then
            return
        end
        if (spend[statId] <= 0) then
            player:SendBroadcastMessage("Es sind keine Punkte auf diesem Attribut verteilt.")
        else
            AttributesPointsLeft[guid] = left + 1
            spend[statId] = spend[statId] - 1
            local aura = player:GetAura(AttributesAuraIds[statId])
            if (aura) then
                aura:SetStackAmount(spend[statId])
            else
                player:AddAura(AttributesAuraIds[statId], player)
            end
            UpdatePlayerStats(player)
        end
    end
end

local function AttributesOnCommand(event, player, command)
    if(command == "para") then
        AIO.Handle(player, "Kaev", "ShowAttributes")
        return false
    end
end
RegisterPlayerEvent(42, AttributesOnCommand)
