local IFTTT = IfThisThenThat

local Triggers = IFTTT.CV.Triggers
local Skills = {}
Skills.available = {}
Skills.previous = {}
Skills.changes = {}
Skills.selections = {}
local EM = EVENT_MANAGER

function Skills:Refresh()
  ZO_DeepTableCopy(Skills.available, Skills.previous)
  Skills.available = {}
  for slot = 1, 8 do
      local abilityId = GetSlotBoundId(slot, HOTBAR_CATEGORY_PRIMARY)
      if abilityId and abilityId ~= 0 then
          local name = GetAbilityName(abilityId)
          table.insert(Skills.available, { name=name, bar=HOTBAR_CATEGORY_PRIMARY, slotId=slot, data=HOTBAR_CATEGORY_PRIMARY..slotId })
      end
  end
  for slot = 1, 8 do
      local abilityId = GetSlotBoundId(slot, HOTBAR_CATEGORY_BACKUP)
      if abilityId and abilityId ~= 0 then
          local name = GetAbilityName(abilityId)
          table.insert(Skills.available, { name=name, bar=HOTBAR_CATEGORY_BACKUP, slotId=slot, data=HOTBAR_CATEGORY_BACKUP..slotId })
      end
  end
  Skills.changes = IFTTT.DiffTables(Skills.previous, Skills.hotbar)
end

function Skills:callbacks()
  for key, item pairs(self.parent.CV.Outcomes.items) do
    for i = 1, #item.selectedCategory do
      d(item.selectedCategory[i].triggerName)
    end
  end
end

function Skills:RegisterEvents()
  EM:UnregisterForEvent(IFTTT.Name, EVENT_ACTION_SLOT_ABILITY_USED)
  EM:RegisterForEvent(IFTTT.Name, EVENT_ACTION_SLOT_ABILITY_USED, function() 
    Skills:callbacks()
  end)
end

Triggers.items.Skills = Skills
