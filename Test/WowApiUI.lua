local frames, FrameClass = {}, {}

FrameClass.methods = {
    "SetScript", "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents", "Show", "Hide", "IsShown",
    "ClearAllPoints", "SetParent", "GetName", "SetOwner", "SetHyperlink", "NumLines", "SetPoint", "SetSize", "SetFrameStrata",
    "SetBackdrop", "CreateFontString", "SetNormalFontObject", "SetHighlightFontObject", "SetNormalTexture", "GetNormalTexture",
    "SetPushedTexture", "GetPushedTexture", "SetHighlightTexture", "GetHighlightTexture", "SetText", "GetScript",
    "EnableMouse", "SetAllPoints", "SetBackdropColor", "SetBackdropBorderColor", "SetWidth", "SetHeight", "GetParent",
    "GetFrameLevel", "SetFrameLevel", "CreateTexture", "SetFontString", "SetDisabledFontObject", "SetID", "SetToplevel",
    "GetFont", "SetWordWrap", "SetJustifyH", "SetMotionScriptsWhileDisabled", "SetDisabledTexture",
    "SetAttribute", "SetScale", "GetObjectType", "IsVisible", "EnableKeyboard", "SetJustifyV", "GetHeight",
    "GetObjectType", "SetMovable", "RegisterForDrag", "HookScript", "SetTextColor", "RegisterForClicks", "GetFontString",
    "SetPushedTextOffset", "GetWidth"
}

function FrameClass:New(name)
    local frame = {}
    for _,method in ipairs(self.methods) do
        frame[method] = self[method]
    end
    local frameProps = {
        events = {},
        scripts = {},
        timer = GetTime(),
        name = name,
        isShow = true,
        parent = nil,
        text = nil,
        textures = {}
    }
    return frame, frameProps
end

function FrameClass:SetID(id)

end

function FrameClass:SetToplevel(top)

end

function FrameClass:GetObjectType()
    return "Frame"
end

function FrameClass:SetMovable()

end

function FrameClass:RegisterForDrag()

end

function FrameClass:RegisterForClicks()

end

function FrameClass:SetText(text)
    frames[self].text = text
end

function FrameClass:SetTextColor()

end


function FrameClass:SetScript(script,handler)
    frames[self].scripts[script] = handler
end

function FrameClass:HookScript()

end

function FrameClass:GetScript(script)
    return frames[self].scripts[script]
end

function FrameClass:RegisterEvent(event)
    frames[self].events[event] = true
end

function FrameClass:UnregisterEvent(event)
    frames[self].events[event] = nil
end

function FrameClass:UnregisterAllEvents(frame)
    for event in pairs(frames[self].events) do
        frames[self].events[event] = nil
    end
end

function FrameClass:Show()
    frames[self].isShow = true
end

function FrameClass:Hide()
    frames[self].isShow = false
end

function FrameClass:IsShown()
    return frames[self].isShow
end

function FrameClass:IsVisible()
    return self:IsShown()
end

function FrameClass:ClearAllPoints()

end

function FrameClass:SetParent(parent)
    frames[self].parent = parent
end

function FrameClass:GetParent()
    return frames[self].parent
end

function FrameClass:GetFontString()

end

function FrameClass:SetPushedTextOffset()

end

function FrameClass:SetFrameLevel(l)
end

function FrameClass:EnableKeyboard() end

function FrameClass:SetJustifyV()

end

function FrameClass:GetFrameLevel()
    return 0
end

function FrameClass:GetName()
    return frames[self].name
end

function FrameClass:SetOwner(owner, anchor)

end

function FrameClass:SetHyperlink(link)

end

function FrameClass:NumLines()
    return 0
end

function FrameClass:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)

end

function FrameClass:SetSize(x, y)

end

function FrameClass:GetHeight()
    return 250
end

function FrameClass:SetFrameStrata(strata)

end

function FrameClass:SetBackdrop(bgFile, edgeFile, tile, tileSize, edgeSize, insets)

end

function FrameClass:CreateFontString(name, layer, inheritsFrom)
    return CreateFrame("FontString", name)
end

function FrameClass:SetWidth(width)

end

function FrameClass:GetWidth()
    return 100
end

function FrameClass:SetHeight(width)

end

function FrameClass:SetNormalFontObject(font)

end

function FrameClass:SetHighlightFontObject(font)

end

function FrameClass:SetFontString(font)

end

function FrameClass:GetFont()
    return nil, nil, nil
end

function FrameClass:SetDisabledFontObject(font)

end

function FrameClass:SetWordWrap(wrap)

end

function FrameClass:SetJustifyH(just)

end

function FrameClass:SetMotionScriptsWhileDisabled(enabled)

end

function FrameClass:SetDisabledTexture(texture)

end

function FrameClass:SetAttribute(k, v)

end

function FrameClass:SetScale(scale)

end

function FrameClass:GetObjectType()
    return frames[self].type
end


function CreateFrame(kind, name, parent)
    local frame,internal = FrameClass:New(name)
    internal.parent = parent
    internal.type = kind
    frame[0] = '(userdata)'
    frames[frame] = internal
    if name then
        _G[name] = frame
        -- print('CreateFrame() _G[' .. name .. ' ] set')
    end
    return frame
end