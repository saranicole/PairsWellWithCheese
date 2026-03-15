local IFTTT = IFTTT

local Triggers = IFTTT.Triggers
local Skills = Triggers.items.Skills
Skills.available = {}
Skills.previous = {}
Skills.changes = {}
Skills.selections = {}
Skills.selected = {}
Skills.activeLock = {}
local EM = EVENT_MANAGER



function Skills:Refresh()
  ZO_DeepTableCopy(Skills.available, Skills.previous)
  Skills.available = {}
  for slot = 3, 8 do
      local abilityId = GetSlotBoundId(slot, HOTBAR_CATEGORY_PRIMARY)
      if abilityId and abilityId ~= 0 then
          local name = GetAbilityName(abilityId)
          table.insert(Skills.available, { name=name, bar=HOTBAR_CATEGORY_PRIMARY, slotId=slot, data=HOTBAR_CATEGORY_PRIMARY.."-"..tostring(slot).."-skills" })
      end
  end
  for slot = 3, 8 do
      local abilityId = GetSlotBoundId(slot, HOTBAR_CATEGORY_BACKUP)
      if abilityId and abilityId ~= 0 then
          local name = GetAbilityName(abilityId)
          table.insert(Skills.available, { name=name, bar=HOTBAR_CATEGORY_BACKUP, slotId=slot, data=HOTBAR_CATEGORY_BACKUP.."-"..tostring(slot).."-skills" })
      end
  end
  Skills.changes = IFTTT.DiffTables(Skills.previous, Skills.hotbar)
end

function Skills:removeCallbacks(links)
  EM:UnregisterForEvent(IFTTT.Name.."SkillCallback", EVENT_ACTION_SLOT_ABILITY_USED)
end

function Skills:callbacks(links)
  local function pollSkillFinished(slotNum, hotbarCategory, slotKey, key, obj, toggleOn, wait)
    local timeRemaining = GetActionSlotEffectTimeRemaining(slotNum, hotbarCategory)
    if timeRemaining <= 0 then
      Skills.activeLock[slotKey] = false
      IFTTT.Outcomes.items[key]:DoOutcome(obj, toggleOn)
    else
      zo_callLater(function()
        pollSkillFinished(slotNum, hotbarCategory, slotKey, key, obj, toggleOn, timeRemaining)
      end, timeRemaining)
    end
  end

  EM:UnregisterForEvent(IFTTT.Name.."SkillCallback", EVENT_ACTION_SLOT_ABILITY_USED)
  EM:RegisterForEvent(IFTTT.Name.."SkillCallback", EVENT_ACTION_SLOT_ABILITY_USED, function(_, actionSlotIndex) 
    local callbackTable = {}
    for key, link in pairs(links) do
      callbackTable = {}
      local triggerparts = IFTTT.Split(link.trigger.data)
      local outcomeparts = IFTTT.Split(link.outcome.data)
      local type = IFTTT.toCapitalized(outcomeparts[3])
      link.trigger.active = link.trigger.active or {}
      local slotNum = tonumber(triggerparts[2])
      local hotbarCategory = tonumber(triggerparts[1])
      if actionSlotIndex == slotNum and GetActiveHotbarCategory() == hotbarCategory then
        local slotKey = triggerparts[1].."-"..triggerparts[2].."-"..outcomeparts[1]
        callbackTable[type] = callbackTable[type] or {}
        table.insert(callbackTable[type], link.outcome)
        for k, obj in pairs(callbackTable) do
          local cooldown
          zo_callLater(function()
            if not Skills.activeLock[slotKey] then
              IFTTT.Outcomes.items[k]:DoOutcome(obj, true)
              Skills.activeLock[slotKey] = true
              cooldown = GetActionSlotEffectDuration(slotNum, hotbarCategory)
              zo_callLater(function()
                  pollSkillFinished(slotNum, hotbarCategory, slotKey, k, obj, false, 300)
              end, cooldown)
            end
          end, 500)
        end
      end
    end
  end)
end
