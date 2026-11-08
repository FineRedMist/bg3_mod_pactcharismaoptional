local DefaultTickWait = 30
-- After applying the status, a number of ticks will be set here and progressively decremented each tick before checking again.
local IdTickWait = {}

---Whether the character id has either of the passives that grant the PACT_BLADE_CHARISMA status.
---@param char GUIDSTRING
---@return boolean
local function CharacterHasPactPassive(char)
    local entity = Ext.Entity.Get(char)
    if not entity then
        return false
    end

    local passiveContainer = entity.PassiveContainer
    if passiveContainer == nil then
        return false
    end
    local playerPassives = passiveContainer.Passives
    if playerPassives == nil then
        return false
    end
    for _, playerPassiveObject in ipairs(playerPassives) do
        local playerPassive = playerPassiveObject.Passive
        if not playerPassive == nil then
            local id = playerPassive.PassiveId
            if id == "PactOfTheBlade" or id == "HexWarrior" then
                return true
            end
        end
    end
    return false
end

---Whether a given character has a passive.
---@param id GUIDSTRING Id of the character.
---@param passiveId string Id of the passive to check for.
---@return boolean
local function HasPassive(id, passiveId)
    local hasPassive = Osi.HasPassive(id, passiveId)
    if not hasPassive or hasPassive == 0 then
        return false
    end
    return true
end

---Whether the player with id has the given status id applied.
---@param id GUIDSTRING Id of the character.
---@param statusId string Id of the status to check for.
---@return boolean
local function HasAppliedStatus(id, statusId)
    local hasStatus = Osi.HasAppliedStatus(id, statusId)
    if not hasStatus or hasStatus == 0 then
        return false
    end
    return true
end

---Conditioanlly applies the PACT_BLADE_CHARISMA if the character guid has the PactOfTheBlade passive.
---@param char GUIDSTRING
local function ConditionalApplyToggleStatus(char)
    -- Applying a status can take some time to register, so we wait a few ticks before checking again to avoid applying it multiple times.
    local tickWait = IdTickWait[char]
    if tickWait ~= nil then
        if tickWait > 0 then
            IdTickWait[char] = tickWait - 1
            return
        else
            IdTickWait[char] = nil
        end
    end
    --_P("Testing " .. char .. " for pact of the blade or hex warrior")
    if HasPassive(char, "PactOfTheBlade") or HasPassive(char, "PactOfTheBlade_Hex") or HasPassive(char, "HexWarrior") then
        if not HasAppliedStatus(char, "PACT_BLADE_CHARISMA") then
            --_P("Applying PACT_BLADE_CHARISMA to " .. char)
            Osi.ApplyStatus(char, "PACT_BLADE_CHARISMA", -1)
            IdTickWait[char] = DefaultTickWait
        end
    end
end

---Go through all players each tick to see if they need the status applied.
---@param tickParams any
local function UpdatePlayerPacts(tickParams)
    if not Osi then
        return
    end

    if not Osi.DB_Players then
        return
    end

    local rows = Osi.DB_Players:Get(nil)

    for _, row in pairs(rows) do
        ConditionalApplyToggleStatus(row[1])
    end
end

local function ListPassives(_, char)
    if not char then
        char = Osi.GetHostCharacter()
    end
    ---@type EntityHandle
    local entity = Ext.Entity.Get(char)
    if not entity then
        _P("Entity not found for " .. char)
        return
    end

    local passiveContainer = entity.PassiveContainer
    if passiveContainer == nil then
        _P("Passive container component not found for " .. char)
        return
    end
    local playerPassives = passiveContainer.Passives
    if playerPassives == nil then
        _P("No passives found for " .. char)
        return
    end
    _P("Passives for " .. char .. ":")
    for _, playerPassiveObject in ipairs(playerPassives) do
        local playerPassive = playerPassiveObject.Passive
        if playerPassive then
            local passiveId = playerPassive.PassiveId
            _P(" - " .. passiveId .. " (" .. tostring(HasPassive(char, passiveId)) .. ")")
        end
    end
end

function Init_PactCharismaOptional()
    -- Processes any pending background goals to apply.
    Ext.Events.Tick:Subscribe(UpdatePlayerPacts)

    -- Handles identifying when background goals fail and succeed to refine the queue.
    --Ext.Osiris.RegisterListener("Activated", 1, "after", ConditionalApplyToggleStatus)

    Ext.RegisterConsoleCommand("ListPassives", ListPassives)
end
