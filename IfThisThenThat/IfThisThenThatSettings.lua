local IFTTT = IfThisThenThat

local LAM = LibHarvensAddonSettings

if not LibHarvensAddonSettings then
    return
end

function IFTTT:BuildMenu()

  self.panel = LAM:AddAddon(TITW.Name, {
    allowDefaults = false,  -- Show "Reset to Defaults" button
    allowRefresh = true    -- Enable automatic control updates
  })
  for i = 1, 5 do
    for key, item in pairs(IFTTT.CV.Triggers.items) do
      self.panel:AddSetting {
        type = LAM.ST_LABEL,
        label = IFTTT.Lang.TRIGGER_HEADING
      }
      self.panel:AddSetting {
        type = LAM.ST_DROPDOWN,
        label = key,
        items = item.available,
        getFunction = function() 
          if #item.selections > 0 then
            item.selections[1].name
          else
            item.available[1].name
          end
        end,
        setFunction = function(var, itemName, itemData)
          table.insert(item.selections, {category=key, name=itemName, data=itemData.data}
        end,
        default = "",
      }
    end
    self.panel:AddSetting {
        type = LAM.ST_LABEL,
        label = IFTTT.Lang.EFFECT_HEADING
      }
    for key, item in pairs(IFTTT.CV.Outcomes.items) do
      self.panel:AddSetting {
        type = LAM.ST_DROPDOWN,
        label = key,
        items = item.categories,
        getFunction = function() 
          if #item.selectedCategory > 0 then
            item.selectedCategory[1].name
          else
            item.categories[1].name
          end
        end,
        setFunction = function(var, itemName, itemData)
          table.insert(item.selectedCategory, {triggerCategory=key, triggerName=item.selections[1].name, triggerData=item.selections[1].data, name=itemName, data=itemData.data}
          item:callbacks()
        end,
        default = ""
      }
    end
  end
end
