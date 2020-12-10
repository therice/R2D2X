--- @type AddOn
local _, AddOn = ...
local Logging, L, C, Util = AddOn:GetLibrary('Logging'), AddOn.Locale, AddOn.Constants, AddOn:GetLibrary('Util')
local UIUtil = AddOn.Require('UI.Util')

local function UpdateMoreInfo(frame, data, row)
    if not frame and frame.moreInfo then
        return false, nil
    end

    local name
    if data and row then
        name = data[row].name
    end

    if Util.Strings.IsEmpty(name) and frame.st then
        local selection = frame.st:GetSelection()
        local r = frame.st:GetRow()
        if selection and r then name = r.name end
    end

    if Util.Strings.IsEmpty(name) then
        frame.moreInfo:Hide()
        return false, nil
    end

    return true, name
end

function AddOn.UpdateMoreInfoWithLootStats(frame, data, row)
    local proceed, name = UpdateMoreInfo(frame, data, row)
    if proceed then
        local class = AddOn:UnitClass(name)
        local c = UIUtil.GetClassColor(class)
        local tip = frame.moreInfo
        tip:SetOwner(frame, "ANCHOR_RIGHT")
        tip:AddLine(AddOn.Ambiguate(name), c.r, c.g, c.b)
        -- todo
        tip:AddLine(L["no_entries_in_loot_history"])
        tip:Show()
        tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
    end
end

function AddOn:GetResponseColor(name)
    return self:GetResponse(name).color:GetRGBA()
end

function AddOn.GetDiffColor(num)
    if not num or num == "" then num = 0 end
    if num > 0 then return C.Colors.Green:GetRGBA() end
    if num < 0 then return C.Colors.LuminousOrange:GetRGBA() end
    return C.Colors.Aluminum:GetRGBA()
end