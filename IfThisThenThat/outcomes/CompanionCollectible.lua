local IFTTT = IFTTT

local Outcomes = IFTTT.Outcomes
local CompanionCollectible = Outcomes.items.CompanionCollectible
CompanionCollectible.categories = {}
CompanionCollectible.subcategories = {}
CompanionCollectible.CompanionCollectibles = {}
CompanionCollectible.available = {}
CompanionCollectible.previous = {}
CompanionCollectible.changes = {}
CompanionCollectible.selectedCategory = nil
CompanionCollectible.selectedSubcategory = nil
CompanionCollectible.selected = {}
CompanionCollectible.selections = {}
CompanionCollectible.snapshot = {}
CompanionCollectible.companionsUnlocked = false

local companionCategoryType = 27

local nonUsableCategories = {
  [1] = true, -- Stories
  [2] = true, -- Patrons
  [3] = true, -- Upgrade
  [5] = true, -- Housing
  [6] = true, -- Furnishings
  [7] = true, -- Fragments
  [10] = true, -- Tools
  [12] = true, -- Non combat pets
  [13] = true, -- Customized Actions
  [15] = true, -- Armor Styles
  [16] = true, -- Weapon Styles
  [19] = true, -- Houses
  [22] = true, -- Chapters
  [25] = true, -- House Banks
  [26] = true, -- Fragments
  [27] = true, -- Companions
}

local usableSubcategories = {
  [4] = { -- Appearance
    [7] = true, -- Costumes
  },
  [11] = { -- Mounts
    [99] = true, -- All
  },
}


function CompanionCollectible:GetCategoryNames()
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubcategories, numCompanionCollectibles, unlockedCompanionCollectibles, totalCompanionCollectibles = GetCollectibleCategoryInfo(categoryIndex)
        if not nonUsableCategories[categoryIndex] and unlockedCompanionCollectibles > 0  then
          table.insert(self.categories, {name=categoryName, data=tostring(categoryIndex).."-"..tostring(numSubcategories).."_"..tostring(totalCompanionCollectibles).."-category"} )
        end
    end
    table.sort(self.categories, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    self.selectedCategory = self.categories[1]
    return self.categories
end

function CompanionCollectible:GetSubcategoryNames()
    if not self.selectedCategory then return end
    self.subcategories = {}
    local parts = IFTTT.Split(self.selectedCategory.data, "-")
    local partsCat = IFTTT.Split(parts[2], "_")
    for subcategoryIndex = 1, tonumber(partsCat[1]) do
        local subcategoryName, numCompanionCollectibles, unlockedCompanionCollectibles = GetCollectibleSubCategoryInfo(parts[1], subcategoryIndex)
        if unlockedCompanionCollectibles > 0 and usableSubcategories[tonumber(parts[1])] and (usableSubcategories[tonumber(parts[1])][subcategoryIndex] or usableSubcategories[tonumber(parts[1])][99])  then
          table.insert(self.subcategories, {name=subcategoryName, data=tostring(subcategoryIndex).."-"..tostring(numCompanionCollectibles).."-subcategory"} )
        end
    end
    table.sort(self.subcategories, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    self.selectedSubcategory = self.subcategories[1]
    return self.subcategories
end

function CompanionCollectible:GetCollectibles()
  self.collectibles = {}
  local parts = IFTTT.Split(self.selectedCategory.data, "-")
  local partsCat = IFTTT.Split(parts[2], "_")
  local subcategoryIndex
  local numCompanionCollectibles = tonumber(partsCat[2])
  if self.selectedSubcategory and self.selectedSubcategory.data then
    local subparts = IFTTT.Split(self.selectedSubcategory.data, "-")
    subcategoryIndex = tonumber(subparts[1])
    numCompanionCollectibles = tonumber(subparts[2])
  end
  for CompanionCollectibleIndex = 1, numCompanionCollectibles do
    local id = GetCollectibleId(tonumber(parts[1]), subcategoryIndex, CompanionCollectibleIndex)
    local category = GetCategoryInfoFromCollectibleId(id)
    local name, description, iconFile, _, unlocked, _, purchasable, active = GetCollectibleInfo(id)

    if unlocked then
      table.insert(self.collectibles, {
          data          = id.."-"..partsCat[1].."_"..category.."_"..tostring(subcategoryIndex).."-companionCollectible",
          name        = name
      })
    end
  end
  table.sort(self.collectibles, function(a, b)
      return a.name:lower() < b.name:lower()
  end)
  return self.collectibles
end

function CompanionCollectible:RefreshCategories()
  self.companionsUnlocked =  HasAnyUnlockedCollectiblesByCategoryType(companionCategoryType)
  self.categories = self:GetCategoryNames()
  self.subcategories = self:GetSubcategoryNames()
  self.collectibles = self:GetCollectibles()
end

function CompanionCollectible:PollUsable(activeCompanionCollectible, desiredCompanionCollectibleId, toggleOn)
  local category, subcategory =  GetCategoryInfoFromCollectibleId(desiredCompanionCollectibleId)
  -- Switch on or off desired
  if (toggleOn or activeCompanionCollectible == 0) and IsCollectibleUsable(desiredCompanionCollectibleId) and  IsCollectibleAvailableToActorCategory(desiredCompanionCollectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
    UseCollectible(desiredCompanionCollectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    -- Switch on case but did not succeed
    zo_callLater(function()
      if toggleOn and activeCompanionCollectible ~= 0 and not IsCollectibleActive(desiredCompanionCollectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
        zo_callLater(function()
          self:PollUsable(activeCompanionCollectible, desiredCompanionCollectibleId, toggleOn)
        end, 1000)
      -- Trying to toggle off desired CompanionCollectible
      elseif not toggleOn and (activeCompanionCollectible == 0 or isPolymorph) and IsCollectibleActive(desiredCompanionCollectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
        zo_callLater(function()
          self:PollUsable(activeCompanionCollectible, desiredCompanionCollectibleId, toggleOn)
        end, 1000)
      end
    end, 1000)
  end
  -- Switch back to previous CompanionCollectible
  if not toggleOn and activeCompanionCollectible ~= 0 and not IsCollectibleActive(activeCompanionCollectible, GAMEPLAY_ACTOR_CATEGORY_COMPANION) and IsCollectibleUsable(activeCompanionCollectible) and IsCollectibleAvailableToActorCategory(desiredCompanionCollectibleId, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
    UseCollectible(activeCompanionCollectible, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    zo_callLater(function()
      if not IsCollectibleActive(activeCompanionCollectible, GAMEPLAY_ACTOR_CATEGORY_COMPANION) then
        zo_callLater(function()
          self:PollUsable(activeCompanionCollectible, desiredCompanionCollectibleId, toggleOn)
        end, 1500)
      end
    end, 1500)
  end
end

function CompanionCollectible:DoOutcome(outcome, toggleOn, categoryLock)
  for i = 1, #outcome do
    local outcomeparts = IFTTT.Split(outcome[i].data)
    local categoryparts = IFTTT.Split(outcomeparts[2], "_")
    local desiredCompanionCollectibleId = tonumber(outcomeparts[1])
    local categoryId = tonumber(categoryparts[2])
    if not categoryId or categoryId == 0 then
      categoryId = tonumber(categoryparts[1])
    end
    if toggleOn then
      local activeCompanionCollectible = GetActiveCollectibleByType(categoryId, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
      if activeCompanionCollectible ~= desiredCompanionCollectibleId and not categoryLock then
        self.snapshot[categoryId] = activeCompanionCollectible
      end
    end
    self:PollUsable(self.snapshot[categoryId], desiredCompanionCollectibleId, toggleOn)
  end
end