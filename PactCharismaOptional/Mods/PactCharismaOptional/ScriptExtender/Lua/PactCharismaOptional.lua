---Conditioanlly applies the PACT_BLADE_CHARISMA if the character guid has the PactOfTheBlade passive.
---@param char GUIDSTRING
function ConditionalApplyToggleStatus(char)
    if Osi.HasPassive(char, "PactOfTheBlade") or Osi.HasPassive(char, 'HexWarrior') then
        Osi.ApplyStatus(char, "PACT_BLADE_CHARISMA", 100, -1)
    end
end

function OnActivateCreature(char)
    ConditionalApplyToggleStatus(char)
end

function UpdatePlayerPacts(tickParams)
    if not Osi then
        return
    end

    local rows = Osi.DB_IsPlayer:Get(nil)

    for _, row in pairs(rows) do
        ConditionalApplyToggleStatus(row[1])
    end
end

function Init_PactCharismaOptional()
    -- Processes any pending background goals to apply.
    Ext.Events.Tick:Subscribe(UpdatePlayerPacts)

    -- Handles identifying when background goals fail and succeed to refine the queue.
    Ext.Osiris.RegisterListener("Activate", 1, "after", OnActivateCreature)
end
