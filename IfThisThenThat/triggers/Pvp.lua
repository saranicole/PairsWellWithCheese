local IFTTT = IFTTT

local Triggers = IFTTT.Triggers
local Pvp = Triggers.items.Pvp
Pvp.categories = {}
Pvp.subcategories = {}
Pvp.collectibles = {}
Pvp.available = {}
Pvp.previous = {}
Pvp.changes = {}
Pvp.selectedSubcategory = nil
Pvp.selections = {}
Pvp.selected = {}
Pvp.activeLock = {}
Pvp.categoryLock = {}
Pvp.existingCooldown = 0
Pvp.timeRemaining = {}
Pvp.snapshot = {}
Pvp.hookGuard = {}
Pvp.leavingPvpZone = false
local EM = EVENT_MANAGER

local lockKey = "Pvp"

function Pvp:GetAvailable()
  self.available = {{
      data          = "0-0_0_0-pvp",
      name        = IFTTT.Lang.PVP_ZONE
  },
  {
      data          = "0-1_1_1-pvp",
      name        = IFTTT.Lang.DUEL_ACCEPT
  }}
  return self.available
end

function Pvp:Refresh()
  self.available = self:GetAvailable()
end

function Pvp:removeCallbacks()
  Pvp.hookGuard = {}
  EM:UnregisterForEvent(IFTTT.Name.."PvpCallback",  EVENT_DUEL_COUNTDOWN)
end

function Pvp:Hook(links, incombat)
  local callbackTable = {}
  for key, link in pairs(links) do
    callbackTable = {}
    local triggerparts = IFTTT.Split(link.trigger.data)
    local outcomeparts = IFTTT.Split(link.outcome.data)
    local desiredPvpLevel = tonumber(IFTTT.Split(triggerparts[2], "_")[1])
    local desiredCollectibleId = tonumber(triggerparts[1])
    local type = IFTTT.toCapitalized(outcomeparts[3])
    link.trigger.active = link.trigger.active or {}
    if desiredCollectibleId == 0 or (IsCollectibleActive(desiredCollectibleId) and GetCollectibleCooldownAndDuration(desiredCollectibleId) == 0) then
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

function Pvp:removeCallbacks(links)
  EM:UnregisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_COUNTDOWN)
  EM:UnregisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_FINISHED)
  EM:UnregisterForEvent(IFTTT.Name.."PvpZoneCallback", EVENT_ZONE_CHANGED)
end

function Pvp:callbacks(links)
  local origSelf = self
  -- Dueling
  EM:UnregisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_COUNTDOWN)
  EM:RegisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_COUNTDOWN, function()
    origSelf:Hook(links, true)
      EM:RegisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_FINISHED, function()
          origSelf:Hook(links, false)
          EM:UnregisterForEvent(IFTTT.Name.."PvpDuelCallback", EVENT_DUEL_FINISHED)
      end)
  end)
  -- Pvp Zone
  EM:RegisterForEvent(IFTTT.Name.."PvpZoneCallback", EVENT_ZONE_CHANGED, function()
    if (IsInCampaign() or IsActiveWorldBattleground()) and not origSelf.leavingPvpZone then
      origSelf.leavingPvpZone = true
      origSelf:Hook(links, true)
    elseif origSelf.leavingPvpZone and not (IsInCampaign() or IsActiveWorldBattleground()) then
      origSelf.leavingPvpZone = false
      origSelf:Hook(links, false)
    end
  end)
end
