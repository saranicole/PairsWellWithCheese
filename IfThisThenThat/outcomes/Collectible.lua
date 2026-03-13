local IFTTT = IfThisThenThat

local Outcomes = IFTTT.CV.Outcomes
local Collectible = {}
Collectible.categories = {}
Collectible.available = {}
Collectible.previous = {}
Collectible.changes = {}
Collectible.selectedCategory = {}
Collectible.selections = {}
DM = ZO_COLLECTIBLE_DATA_MANAGER

function Collectible:RefreshCategories()
  if DM:HasAnyUnlockedCollectibles() then
    local numCategories = DM:GetNumCategories()
    for i = 1, #numCategories do
      for _, categoryData in DM:CategoryIterator({ ZO_CollectibleCategoryData.IsStandardCategory }, { ZO_CollectibleData.IsUnlocked })
        table.insert(Collectible.categories, categoryData)
      end
    end
  end
end

Outcomes.items.Collectible = Collectible
