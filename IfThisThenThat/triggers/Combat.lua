local IFTTT = IFTTT

local Triggers = IFTTT.Triggers
local Combat = Triggers.items.Combat
Combat.categories = {}
Combat.subcategories = {}
Combat.collectibles = {}
Combat.available = {}
Combat.previous = {}
Combat.changes = {}
Combat.selectedSubcategory = nil
Combat.selections = {}
Combat.selected = {}
Combat.activeLock = {}
Combat.categoryLock = {}
Combat.existingCooldown = 0
Combat.timeRemaining = {}
Combat.snapshot = {}
Combat.hookGuard = {}
local EM = EVENT_MANAGER

local lockKey = "Combat"

function Combat:GetAvailable()
  self.available = {{
      data          = "0-0_0_0-combat",
      name        = IFTTT.Lang.ANY_COMBAT
  },
  {
      data          = "0-1_1_1-combat",
      name        = IFTTT.Lang.ANY_BOSS_COMBAT
  }
--   ,
--   {
--       data          = "0-2_4_4-combat",
--       name        = IFTTT.Lang.PVP_COMBAT
--   }
  }
  return self.available
end

function Combat:Refresh()
  self.available = self:GetAvailable()
end

function Combat:removeCallbacks()
  Combat.hookGuard = {}
  EM:UnregisterForEvent(IFTTT.Name.."CombatCallback", EVENT_PLAYER_Combat)
end

function Combat:Hook(links, incombat, unitTag)
  local callbackTable = {}
  if (not incombat) or not self.hookGuard[unitTag] then
    for key, link in pairs(links) do
      callbackTable = {}
      local triggerparts = IFTTT.Split(link.trigger.data)
      local outcomeparts = IFTTT.Split(link.outcome.data)
      local desiredCombatLevel = tonumber(IFTTT.Split(triggerparts[2], "_")[1])
      local desiredCollectibleId = tonumber(triggerparts[1])
      local bossLevel = tonumber(IFTTT.Split(triggerparts[2], "_")[2])
      local type = IFTTT.toCapitalized(outcomeparts[3])
      local isBoss = (string.find(unitTag, "boss") ~= nil)
      local bossNumber = tonumber(string.match(unitTag, "boss(%d)$"))
      link.trigger.active = link.trigger.active or {}
      if (not incombat) or desiredCollectibleId == 0 or (IsCollectibleActive(desiredCollectibleId) and GetCollectibleCooldownAndDuration(desiredCollectibleId) == 0) then
        if (not incombat) or desiredCombatLevel == 0 or (desiredCombatLevel == 1 and isBoss) or (bossNumber and (bossNumber >= bossLevel)) then
          if incombat then
            self.hookGuard[unitTag] = true
          else
            self.hookGuard[unitTag] = false
          end
          local slotKey = triggerparts[1].."-"..triggerparts[2].."-"..outcomeparts[1]
          self.snapshot = desiredCollectibleId
          callbackTable[type] = callbackTable[type] or {}
          table.insert(callbackTable[type], link.outcome)
          for k, obj in pairs(callbackTable) do
            IFTTT.Outcomes.items[k]:DoOutcome(obj, incombat, self.categoryLock[lockKey])
            if not self.categoryLock[lockKey] then
              self.categoryLock[lockKey] = true
            end
          end
        end
      end
    end
  end
end

function Combat:removeCallbacks(links)
  EM:UnregisterForEvent(IFTTT.Name.."CombatTargetCallback", EVENT_TARGET_CHANGED)
  EM:UnregisterForEvent(IFTTT.Name.."CombatCallback", EVENT_PLAYER_COMBAT_STATE)
end

function Combat:callbacks(links)
  local origSelf = self
  EM:UnregisterForEvent(IFTTT.Name.."CombatTargetCallback", EVENT_TARGET_CHANGED)
  EM:UnregisterForEvent(IFTTT.Name.."CombatCallback", EVENT_PLAYER_COMBAT_STATE)
  EM:RegisterForEvent(IFTTT.Name.."CombatTargetCallback", EVENT_TARGET_CHANGED, function(_, unitTag)
    if IsUnitInCombat("player") and not (IsInCampaign() or IsActiveWorldBattleground()) then
      origSelf:Hook(links, true, unitTag)
      EM:RegisterForEvent(IFTTT.Name.."CombatCallback", EVENT_PLAYER_COMBAT_STATE, function(_, incombat)
        if not incombat then
          origSelf:Hook(links, false, unitTag)
          EM:UnregisterForEvent(IFTTT.Name.."CombatCallback", EVENT_PLAYER_COMBAT_STATE)
        end
      end)
    end
  end)
  ZO_UnitFrames:AddFilterForEvent(EVENT_TARGET_CHANGED, REGISTER_FILTER_UNIT_TAG, "reticleover")
end
