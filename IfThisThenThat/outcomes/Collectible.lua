local IFTTT = IFTTT

local Outcomes = IFTTT.Outcomes
local Collectible = Outcomes.items.Collectible
Collectible.categories = {}
Collectible.subcategories = {}
Collectible.collectibles = {}
Collectible.available = {}
Collectible.previous = {}
Collectible.changes = {}
Collectible.selectedCategory = {}
Collectible.selectedSubcategory = {}
Collectible.selected = {}
Collectible.selections = {}
Collectible.snapshot = {}
DM = ZO_COLLECTIBLE_DATA_MANAGER

local nonUsableCategories = {
  [1] = true, -- Stories
  [2] = true, -- Patrons
  [3] = true, -- Upgrade
  [5] = true, -- Housing
  [6] = true, -- Furnishings
  [7] = true, -- Fragments
  [10] = true, -- Tools
  [11] = true, -- Mounts
  [13] = true, -- Customized Actions
  [15] = true, -- Armor Styles
  [16] = true, -- Weapon Styles
  [19] = true, -- Houses
  [22] = true, -- Chapters
  [25] = true, -- House Banks
  [26] = true, -- Fragments
}


function Collectible:GetCategoryNames()
    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryName, numSubcategories = GetCollectibleCategoryInfo(categoryIndex)
        if not nonUsableCategories[categoryIndex] then
          table.insert(self.categories, {name=categoryName, data=tostring(categoryIndex).."-"..tostring(numSubcategories).."-category"} )
        end
    end
    table.sort(self.categories, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    return self.categories
end

function Collectible:GetSubcategoryNames()
    if not self.selectedCategory.data then return end
    self.subcategories = {}
    local parts = IFTTT.Split(self.selectedCategory.data, "-")
    for subcategoryIndex = 1, parts[2] do
        local subcategoryName, numCollectibles = GetCollectibleSubCategoryInfo(parts[1], subcategoryIndex)
        table.insert(self.subcategories, {name=subcategoryName, data=tostring(subcategoryIndex).."-"..tostring(numCollectibles).."-subcategory"} )
    end
    table.sort(self.subcategories, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    return self.subcategories
end

function Collectible:GetCollectibles()
  if not self.selectedSubcategory.data then return end
  self.collectibles = {}
  local parts = IFTTT.Split(self.selectedCategory.data, "-")
  local subparts = IFTTT.Split(self.selectedSubcategory.data, "-")
  for collectibleIndex = 1, tonumber(subparts[2]) do
    local id = GetCollectibleId(parts[1], subparts[1], collectibleIndex)
    local category = GetCollectibleCategoryType(id)
    local name, description, iconFile, _, unlocked, _, purchasable, active = GetCollectibleInfo(id)
    if unlocked then
        table.insert(self.collectibles, {
            data          = id.."-"..parts[1].."_"..category.."_"..subparts[1].."-collectible",
            name        = name
        })
    end
  end
  table.sort(self.collectibles, function(a, b)
      return a.name:lower() < b.name:lower()
  end)
  return self.collectibles
end

function Collectible:RefreshCategories()
  self.categories = self:GetCategoryNames()
  if next(Collectible.selectedCategory) then
    self.subcategories = self:GetSubcategoryNames(Collectible.selectedCategory)
  end
end

function Collectible:PollUsable(activeCollectible, desiredCollectibleId, toggleOn)
  -- Switch on or off desired
  if (toggleOn or activeCollectible == 0) and IsCollectibleUsable(desiredCollectibleId) and IsCollectibleValidForPlayer(desiredCollectibleId) then
    UseCollectible(desiredCollectibleId)
    -- Switch on case but did not succeed
    zo_callLater(function()
      if toggleOn and activeCollectible ~= 0 and not IsCollectibleActive(desiredCollectibleId) then
        zo_callLater(function()
          self:PollUsable(activeCollectible, desiredCollectibleId, toggleOn)
        end, 1000)
      end
    end, 1000)
  end
  -- Switch back to previous collectible
  if not toggleOn and activeCollectible ~= 0 and not IsCollectibleActive(activeCollectible) and IsCollectibleUsable(activeCollectible) and IsCollectibleValidForPlayer(activeCollectible) then
    UseCollectible(activeCollectible)
    zo_callLater(function()
      if not IsCollectibleActive(activeCollectible) then
        zo_callLater(function()
          self:PollUsable(activeCollectible, desiredCollectibleId, toggleOn)
        end, 1500)
      end
    end, 1500)
  end
end

function Collectible:DoOutcome(outcome, toggleOn)
  for i = 1, #outcome do
    local outcomeparts = IFTTT.Split(outcome[i].data)
    local categoryparts = IFTTT.Split(outcomeparts[2], "_")
    local desiredCollectibleId = tonumber(outcomeparts[1])
    local categoryId = tonumber(categoryparts[2])
    local backupCategoryId = tonumber(categoryparts[1])
    if IsCollectibleCategoryUsable(categoryId, GAMEPLAY_ACTOR_CATEGORY_PLAYER) then
      if toggleOn then
        local activeCollectible = GetActiveCollectibleByType(categoryId, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
        if activeCollectible ~= desiredCollectibleId then
          self.snapshot[categoryId] = activeCollectible
        end
      end
      self:PollUsable(self.snapshot[categoryId], desiredCollectibleId, toggleOn)
    end
  end
end