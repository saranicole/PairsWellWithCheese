--Name Space
IfThisThenThat = {}

--Basic Info
IFTTT.Name = "IfThisThenThat"

local EM = EVENT_MANAGER

function IFTTT.DiffTables(old, new, path)
    path = path or ""
    local changes = {}

    -- Check for removed or changed keys
    for k, oldVal in pairs(old) do
        local newVal = new[k]
        local keyPath = path .. (path == "" and "" or ".") .. tostring(k)

        if newVal == nil then
            table.insert(changes, { type = "removed", path = keyPath, oldValue = oldVal })
        elseif type(oldVal) == "table" and type(newVal) == "table" then
            local nested = DiffTables(oldVal, newVal, keyPath)
            for _, change in ipairs(nested) do
                table.insert(changes, change)
            end
        elseif oldVal ~= newVal then
            table.insert(changes, { type = "changed", path = keyPath, oldValue = oldVal, newValue = newVal })
        end
    end

    -- Check for added keys
    for k, newVal in pairs(new) do
        if old[k] == nil then
            local keyPath = path .. (path == "" and "" or ".") .. tostring(k)
            table.insert(changes, { type = "added", path = keyPath, newValue = newVal })
        end
    end

    return changes
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName ~= IFTTT.Name then return end
	EVENT_MANAGER:UnregisterForEvent(IFTTT.Name, EVENT_ADD_ON_LOADED)
	
	local ns = GetDisplayName()..GetWorldName()
	IFTTT.AV = ZO_SavedVars:NewAccountWide("IfThisThenThat_Vars", 1, ns, IFTTT.Default)
  IFTTT.CV = ZO_SavedVars:NewCharacterIdSettings("IfThisThenThat_Vars", 1, ns, IFTTT.Default)
end


EM:RegisterForEvent(IFTTT.Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
