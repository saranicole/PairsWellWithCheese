local IFTTT = IFTTT

local Triggers = IFTTT.Triggers
local FastTravel = Triggers.items.FastTravel
FastTravel.categories = {}
FastTravel.subcategories = {}
FastTravel.collectibles = {}
FastTravel.available = {}
FastTravel.previous = {}
FastTravel.changes = {}
FastTravel.selectedSubcategory = nil
FastTravel.selections = {}
FastTravel.selected = {}
FastTravel.activeLock = {}
FastTravel.categoryLock = {}
FastTravel.existingCooldown = 0
FastTravel.timeRemaining = {}
FastTravel.snapshot = {}
FastTravel.hookGuard = {}
local EM = EVENT_MANAGER

local customizedActionCategory = 13
local recallSubcategory = 3

local jumpFunctions = {
    "FastTravelToNode",
    "JumpToFriend",
    "JumpToGroupMember",
    "JumpToGroupLeader",
    "JumpToGuildMember",
    "JumpToSpecificHouse",
    "RequestJumpToHouse",
}

function FastTravel:GetAvailable()
  self.available = {}
  local subcategoryName, numCollectibles, unlockedCollectibles = GetCollectibleSubCategoryInfo(customizedActionCategory, recallSubcategory)
  local unlockedCounter = 0
  if unlockedCollectibles > 0 then
    for collectibleIndex = 1, numCollectibles do
      local id = GetCollectibleId(customizedActionCategory, recallSubcategory, collectibleIndex)
      local category = GetCollectibleCategoryType(id)
      local name, description, iconFile, _, unlocked, _, purchasable, active = GetCollectibleInfo(id)
      if unlocked then
          table.insert(self.available, {
              data          = id.."-"..customizedActionCategory.."_"..category.."_"..recallSubcategory.."-fastTravel",
              name        = name
          })
          unlockedCounter = unlockedCounter + 1
          if unlockedCounter == unlockedCollectibles then
            break
          end
      end
    end
  end
  table.insert(self.available, {
      data          = "0-0_0_0-fastTravel",
      name        = IFTTT.Lang.BASE_FAST_TRAVEL
  })
  table.sort(self.available, function(a, b)
      return a.name:lower() < b.name:lower()
  end)
  return self.available
end

function FastTravel:Refresh()
  self.available = self:GetAvailable()
end

function FastTravel:removeCallbacks()
  FastTravel.hookGuard = {}
  EM:UnregisterForEvent(IFTTT.Name.."FastTravelCallback", EVENT_PLAYER_ACTIVATED)
end

function FastTravel:HookJump(links)
  local callbackTable = {}
  for key, link in pairs(links) do
    callbackTable = {}
    local triggerparts = IFTTT.Split(link.trigger.data)
    local outcomeparts = IFTTT.Split(link.outcome.data)
    local desiredCollectibleId = tonumber(triggerparts[1])
    local type = IFTTT.toCapitalized(outcomeparts[3])
    link.trigger.active = link.trigger.active or {}
    if desiredCollectibleId == 0 or IsCollectibleActive(desiredCollectibleId) then
      local slotKey = triggerparts[1].."-"..triggerparts[2].."-"..outcomeparts[1]
      self.snapshot = desiredCollectibleId
      callbackTable[type] = callbackTable[type] or {}
      table.insert(callbackTable[type], link.outcome)
      for k, obj in pairs(callbackTable) do
        IFTTT.Outcomes.items[k]:DoOutcome(obj, true, self.categoryLock[customizedActionCategory])
        if not self.categoryLock[customizedActionCategory] then
          self.categoryLock[customizedActionCategory] = true
        end
      end
    end
  end
end

function FastTravel:PostJump(links)
  local callbackTable = {}
  for key, link in pairs(links) do
    callbackTable = {}
    local triggerparts = IFTTT.Split(link.trigger.data)
    local outcomeparts = IFTTT.Split(link.outcome.data)
    local activeCollectibleId = tonumber(triggerparts[1])
    local desiredCollectibleId = tonumber(outcomeparts[1])
    local type = IFTTT.toCapitalized(outcomeparts[3])
    link.trigger.active = link.trigger.active or {}
    -- GetCollectibleCooldownAndDuration == 0 means it is a toggled collectible
    if IsCollectibleActive(desiredCollectibleId) and GetCollectibleCooldownAndDuration(desiredCollectibleId) == 0 then
      local slotKey = triggerparts[1].."-"..triggerparts[2].."-"..outcomeparts[1]
      callbackTable[type] = callbackTable[type] or {}
      table.insert(callbackTable[type], link.outcome)
      for k, obj in pairs(callbackTable) do
        IFTTT.Outcomes.items[k]:DoOutcome(obj, false, self.categoryLock[customizedActionCategory])
        if not self.categoryLock[customizedActionCategory] then
          self.categoryLock[customizedActionCategory] = true
        end
      end
    end
  end
end

function FastTravel:callbacks(links)
  local origSelf = self
  FastTravel.hookGuard = false
  for _, funcName in ipairs(jumpFunctions) do
      ZO_PreHook(funcName, function(...)
          origSelf:HookJump(links)
          zo_callLater(function()
            origSelf:PostJump(links)
          end, 14000)
          return false
      end)
  end
end
