local _, AddOn = ...
local Logging, L, C, Util = AddOn:GetLibrary('Logging'), AddOn.Locale, AddOn.Constants, AddOn:GetLibrary('Util')
local UIUtil = AddOn.Require('UI.Util')

function AddOn.UpdateMoreInfo(enabled, frame, data, row)
    if not frame and frame.moreInfo then return end
    Logging:Debug('UpdateMoreInfo(%s) : %s', tostring(enabled), tostring(frame.moreInfo:GetName()))

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
        return frame.moreInfo:Hide()
    end

    local class = AddOn:UnitClass(name)
    Logging:Debug('UpdateMoreInfo(%s) : %s', name, class)

    local c = UIUtil.GetClassColor(class)
    local tip = frame.moreInfo
    tip:SetOwner(frame, "ANCHOR_RIGHT")
    tip:AddLine(AddOn.Ambiguate(name), c.r, c.g, c.b)
    tip:AddLine(L["no_entries_in_loot_history"])
    tip:Show()
    tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
end
