local IFTTT = IFTTT

local LAM = LibHarvensAddonSettings

if not LibHarvensAddonSettings then
    return
end

IFTTT.triggerSelected = {}
IFTTT.commitTrigger = {}
IFTTT.outcomeSelected = {}
IFTTT.deleteSelected = {}
IFTTT.subcategorySettings = {}
IFTTT.collectibleSettings = {}

local function warnMessage(commitTrigger, commitEffect)
  local problem = ""
  if not next(commitTrigger) or not next(commitEffect) then
    if not next(commitTrigger) then
      problem = problem..IFTTT.Lang.TRIGGER
    end
    if not next(commitEffect) then
      if not next(commitTrigger) then
        problem = problem..IFTTT.Lang.AND.." "
      end
      problem =  IFTTT.Lang.EFFECT
    end
  end
  return problem
end

local function RefreshSetting(setting, previousSibling)
  if IsInGamepadPreferredMode() or IsConsoleUI() then
    setting:UpdateControl()
  else
    setting:UpdateControl(previousSibling)
  end
end

local function RefreshHeight(numlines)
  if not (IsInGamepadPreferredMode() or IsConsoleUI()) then
    LAM:SetContainerHeightPercentage(1 + (0.1 * numlines))
  end
end

function IFTTT:BuildMenu()
  
  local panel = LAM:AddAddon(self.Name, {
    allowDefaults = false,  -- Show "Reset to Defaults" button
    allowRefresh = false    -- Enable automatic control updates
  })

  panel:AddSetting {
    type = LAM.ST_SECTION,
    label = IFTTT.Lang.TRIGGER_HEADING
  }
  panel:AddSetting {
    type = LAM.ST_SECTION,
    label = IFTTT.Lang.MOUNT_HEADING
  }
  
  local triggerMountItem = IFTTT.Triggers.items.TriggerMounts

  panel:AddSetting {
    type = LAM.ST_DROPDOWN,
    label = IFTTT.Lang.MOUNT_HEADING,
    items = triggerMountItem.subcategories,
    getFunction = function() 
      return triggerMountItem.selectedSubcategory.name or ""
    end,
    setFunction = function(control, itemName, itemData)
      triggerMountItem.selectedSubcategory = { name = itemName, data = itemData.data }
      triggerMountItem:GetCollectibles()
      RefreshSetting(self.collectibleSettings["TriggerMounts"], control)
    end,
  }
    self.collectibleSettings["TriggerMounts"] = panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = function()
        return triggerMountItem.collectibles
      end,
      getFunction = function() 
        if next(triggerMountItem.selected) then
          return triggerMountItem.selected.name
        end
        if triggerMountItem.collectibles and next(triggerMountItem.collectibles) then
          local index, first = next(select(1, triggerMountItem.collectibles))
          return first.name
        end
      end,
      setFunction = function(var, itemName, itemData)
        triggerMountItem.selected.name = itemName
        triggerMountItem.selected.data = itemData.data
        self.triggerSelected = triggerMountItem.selected
      end,
    }
  local triggerCollectibleItem = IFTTT.Triggers.items.TriggerCollectibles
  panel:AddSetting {
    type = LAM.ST_SECTION,
    label = IFTTT.Lang.TRIGGERCOLLECTIBLE_HEADING
  }

  panel:AddSetting {
    type = LAM.ST_DROPDOWN,
    label = IFTTT.Lang.TRIGGERCOLLECTIBLE_HEADING,
    items = triggerCollectibleItem.categories,
    getFunction = function() 
      return triggerCollectibleItem.selectedCategory.name or triggerCollectibleItem.categories[1].name or ""
    end,
    setFunction = function(setting, itemName, itemData)
      triggerCollectibleItem.selectedCategory = { name = itemName, data = itemData.data }
      RefreshSetting(self.subcategorySettings["TriggerCollectibles"], setting.m_container:GetParent())
      RefreshSetting(self.collectibleSettings["TriggerCollectibles"], self.subcategorySettings["TriggerCollectibles"].control)
    end,
  }

    IFTTT.subcategorySettings["TriggerCollectibles"] = panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.SUBCATEGORY,
      items = function()
        return triggerCollectibleItem:GetSubcategoryNames()
      end,
      getFunction = function() 
        if triggerCollectibleItem.selectedSubcategory then
          return triggerCollectibleItem.selectedSubcategory.name
        end
        return ""
      end,
      setFunction = function(setting, itemName, itemData)
        triggerCollectibleItem.selectedSubcategory = { name = itemName, data = itemData.data }
        RefreshSetting(self.collectibleSettings["TriggerCollectibles"], setting.m_container:GetParent())
      end,
    }
    self.collectibleSettings["TriggerCollectibles"] = panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = function()
        return triggerCollectibleItem:GetCollectibles()
      end,
      getFunction = function() 
        if triggerCollectibleItem.collectibles and next(triggerCollectibleItem.collectibles) then
          return triggerCollectibleItem.selected.name or triggerCollectibleItem.collectibles[1].name
        end
        return  ""
      end,
      setFunction = function(var, itemName, itemData)
        triggerCollectibleItem.selected = { name = itemName, data = itemData.data }
        self.triggerSelected = triggerCollectibleItem.selected
      end,
    }
  for k, triggerItem in pairs(IFTTT.Triggers.items) do
    if k ~= "TriggerCollectibles" and k ~= "TriggerMounts" then
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang[string.upper(k).."_HEADING"]
    }
    panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang[string.upper(k).."_HEADING"],
      items = function()
        return triggerItem.available
      end,
      getFunction = function() 
        if next(triggerItem.selected) then
          return triggerItem.selected.name
        end
        return triggerItem.available[1].name or ""
      end,
      setFunction = function(var, itemName, itemData)
        triggerItem.selected = {name=itemName, data=itemData.data}
        self.triggerSelected = triggerItem.selected
      end,
      default = "",
    }
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang.COMMIT
    }
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.SELECT_TRIGGER,
      buttonText = IFTTT.Lang.SELECT_TRIGGER,
      clickHandler = function()
        self.commitTrigger = self.triggerSelected
        panel:UpdateControls()
      end
    })
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.CLEAR.." "..IFTTT.Lang.TRIGGER,
      buttonText = IFTTT.Lang.CLEAR.." "..IFTTT.Lang.TRIGGER,
      clickHandler = function()
        self.commitTrigger = nil
        panel:UpdateControls()
      end
    })
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang.SELECTED_TRIGGER
    }
    panel:AddSetting {
      type = LAM.ST_LABEL,
      label = function()
        if self.commitTrigger and next(self.commitTrigger) then
          return "|cebc034"..self.commitTrigger.name.."|r"
        end
        return "" 
      end
    }
  panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang.EFFECT_HEADING
    }
    local collectibleItem = IFTTT.Outcomes.items.Collectible

    panel:AddSetting({
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = collectibleItem.categories,
      getFunction = function() 
        return collectibleItem.selectedCategory.name or collectibleItem.categories[1].name or ""
      end,
      setFunction = function(setting, itemName, itemData)
        collectibleItem.selectedCategory = { name = itemName, data = itemData.data }
        RefreshSetting(self.subcategorySettings["Collectible"], setting.m_container:GetParent())
        RefreshSetting(self.collectibleSettings["Collectible"], self.subcategorySettings["Collectible"].control)
      end,
    })

    self.subcategorySettings["Collectible"] = panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = function()
        return collectibleItem:GetSubcategoryNames()
      end,
      getFunction = function() 
        if collectibleItem.selectedSubcategory then
          return collectibleItem.selectedSubcategory.name
        end
        return ""
      end,
      setFunction = function(setting, itemName, itemData)
        collectibleItem.selectedSubcategory = { name = itemName, data = itemData.data }
        RefreshSetting(self.collectibleSettings["Collectible"], setting.m_container:GetParent())
      end,
    }
    self.collectibleSettings["Collectible"] = panel:AddSetting {
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = function()
        return collectibleItem:GetCollectibles()
      end,
      getFunction = function() 
        if collectibleItem.collectibles and next(collectibleItem.collectibles) then
          return collectibleItem.selected.name or collectibleItem.collectibles[1].name
        end
        return  ""
      end,
      setFunction = function(var, itemName, itemData)
        collectibleItem.selected.name = itemName
        collectibleItem.selected.data = itemData.data
        self.outcomeSelected = collectibleItem.selected
      end,
    }
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang.COMMIT
    }
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.SELECT_EFFECT,
      buttonText = "|cffffff"..IFTTT.Lang.SELECT_EFFECT.."|r",
      clickHandler = function()
        self.commitEffect = self.outcomeSelected
        panel:UpdateControls()
      end
    })
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.CLEAR.." "..IFTTT.Lang.EFFECT,
      buttonText = "|cffffff"..IFTTT.Lang.CLEAR.." "..IFTTT.Lang.EFFECT.."|r",
      clickHandler = function()
        self.commitEffect = nil
        panel:UpdateControls()
      end
    })
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = IFTTT.Lang.SELECTED_EFFECT
    }
    panel:AddSetting {
      type = LAM.ST_LABEL,
      label = function()
        if self.commitEffect and next(self.commitEffect) then
          return "|cebc034"..self.commitEffect.name.."|r"
        end
        return "" 
      end
    }
    panel:AddSetting {
      type = LAM.ST_SECTION,
      label = ""
    }
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.ADD_LINK,
      buttonText = IFTTT.Lang.ADD,
      tooltip = IFTTT.Lang.ADD_TOOLTIP,
      clickHandler = function()
        local warn = warnMessage(self.commitTrigger, self.commitEffect)
        if warn ~= "" then
          d(warn)
          return
        end
        local linkTrigger = { trigger = self.commitTrigger, outcome = self.commitEffect }
        table.insert(self.Links.savedVarsChar.links, linkTrigger)
        self:AddCallbacks()
        panel:UpdateControls()
      end
    })
    panel:AddSetting({
      type = LAM.ST_BUTTON,
      label = IFTTT.Lang.ACC_ADD_LINK,
      buttonText = IFTTT.Lang.ACC_ADD,
      tooltip = IFTTT.Lang.ACC_ADD_TOOLTIP,
      clickHandler = function()
        local warn = warnMessage(self.commitTrigger, self.commitEffect)
        if warn ~= "" then
          d(warn)
          return
        end
        local linkTrigger = { trigger = self.commitTrigger, outcome = self.commitEffect }
        table.insert(self.Links.savedVarsAcc.links, linkTrigger)
        self:AddCallbacks()
        panel:UpdateControls()
      end
    })
  end
end
  panel:AddSetting({
    type = LAM.ST_SECTION,
    label = IFTTT.Lang.EXISTING_LINKS
  })
  panel:AddSetting({
    type = LAM.ST_LABEL,
    label = function()
      local linkText = ""
      local linkCounter = 1
      for key, linkItem in pairs(self.Links.savedVarsChar.links) do
        linkText = linkText.."\n"..IFTTT.Lang.CHARACTER.."   "..key.."   "..linkItem.trigger.name.."|r |cf2a705 → |r |c05f2a7"..linkItem.outcome.name
        linkCounter = linkCounter + 1
      end
      RefreshHeight(linkCounter)
      return "|c05f2a7"..linkText.."|r"
    end
  })
  panel:AddSetting({
    type = LAM.ST_LABEL,
    label = function()
      local linkText = ""
      local linkCounter = 1
      for key, linkItem in pairs(self.Links.savedVarsAcc.links) do
        linkText = linkText.."\n"..IFTTT.Lang.ACCOUNT.."   "..key.."   "..linkItem.trigger.name.."|r |c05f2a7 → |r |cf29f05"..linkItem.outcome.name
        linkCounter = linkCounter + 1
      end
      RefreshHeight(linkCounter)
      return "|cf29f05"..linkText.."|r"
    end
  })
  panel:AddSetting({
      type = LAM.ST_DROPDOWN,
      label = IFTTT.Lang.COLLECTIBLE_HEADING,
      items = function() 
        local deleteItems = {}
        for key, linkItem in pairs(self.Links.savedVarsAcc.links) do
          table.insert(deleteItems, { name = IFTTT.Lang.ACCOUNT.."   "..key.."   "..linkItem.trigger.name.." → "..linkItem.outcome.name, data = IFTTT.Lang.ACCOUNT.."-"..key })
        end
        for key, linkItem in pairs(self.Links.savedVarsChar.links) do
          table.insert(deleteItems, { name = IFTTT.Lang.CHARACTER.."   "..key.."   "..linkItem.trigger.name.." → "..linkItem.outcome.name, data = IFTTT.Lang.CHARACTER.."-"..key })
        end
        return deleteItems
      end,
      getFunction = function() 
        return self.deleteSelected.name or ""
      end,
      setFunction = function(var, itemName, itemData)
        self.deleteSelected.name = itemName
        self.deleteSelected.data = itemData.data
      end
  })
  panel:AddSetting({
    type = LAM.ST_BUTTON,
    label = IFTTT.Lang.REMOVE_LINK,
    buttonText = IFTTT.Lang.REMOVE,
    tooltip = IFTTT.Lang.REMOVE_LINK,
    clickHandler = function()
      local deleteParts = self.Split(self.deleteSelected.data)
      if deleteParts[1] == IFTTT.Lang.ACCOUNT then
        self.Links.savedVarsAcc.links[tonumber(deleteParts[2])] = nil
      end
      if deleteParts[1] == IFTTT.Lang.CHARACTER then
        self.Links.savedVarsChar.links[tonumber(deleteParts[2])] = nil
      end
      self.deleteSelected = {}
      panel:UpdateControls()
    end
  })
  panel:AddSetting({
    type = LAM.ST_BUTTON,
    label = IFTTT.Lang.CLEAR_ALL,
    buttonText = IFTTT.Lang.CLEAR,
    tooltip = IFTTT.Lang.CLEAR_ALL,
    clickHandler = function()
      self:RemoveCallbacks()
      self.Links.savedVarsChar.links = {}
      self.Links.savedVarsAcc.links = {}
      panel:UpdateControls()
    end
  })
  self.panel = panel
end
