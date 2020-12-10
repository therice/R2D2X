local AddOnName, AddOn, Util


describe("LootSession", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootSession')
        Util = AddOn:GetLibrary('Util')
        AddOnLoaded(AddOnName, true)
    end)

    teardown(function()
        After()
    end)

    describe("lifecycle", function()
        teardown(function()
            AddOn:YieldModule("LootSession")
        end)

        it("is disabled on startup", function()
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
        it("can be enabled", function()
            AddOn:ToggleModule("LootSession")
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(standings:IsEnabled())
        end)
        it("can be disabled", function()
            AddOn:ToggleModule("LootSession")
            local standings = AddOn:LootSessionModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
    end)

    describe("operations", function()
        local module

        before_each(function()
            AddOn:ToggleModule("LootSession")
            module = AddOn:LootSessionModule()
            PlayerEnteredWorld()
            GuildRosterUpdate()
        end)

        teardown(function()
            AddOn:ToggleModule("LootSession")
            module = nil
        end)

        it("fails to start when loading items", function()
            module.loadingItems = true
            module:Start()
        end)
        it("fails to start without loot table", function()
            module.loadingItems = false
            module:Start()
        end)
        it("fails to start in combat lockdown", function()
            module.loadingItems = false
            module.ml.lootTable = {1, 2, 3}
            _G.InCombatLockdown = function() return true end
            module:Start()
        end)
        it("disables after starting", function()
            module.loadingItems = false
            module.ml.lootTable = {1, 2, 3}
            _G.InCombatLockdown = function() return false end
            module.ml.StartSession = function() end
            module:Start()
            assert(not module:IsEnabled())
        end)
        it("disables after cacnel", function()
            module:Enable()
            assert(module:IsEnabled())
            module:Cancel()
            assert(not module:IsEnabled())
        end)
    end)

    --describe("ui", function()
    --    local standings
    --
    --    local function NewAward()
    --        local award = Award()
    --        award:SetAction(Award.ActionType.Add)
    --        award:SetResource(Award.ResourceType.Gp, 10)
    --        award:SetSubjects(Award.SubjectType.Character, 'Player102-Realm1')
    --        return award
    --    end
    --
    --    local function Popup()
    --        local p = CreateFrame("Frame")
    --        p.text = {value = ''}
    --        p.text.SetText = function(self, v)
    --            self.value = v
    --        end
    --        p.text.GetText = function(self)
    --            return self.value
    --        end
    --        return p
    --    end
    --
    --    before_each(function()
    --        AddOn:ToggleModule("Standings")
    --        standings = AddOn:StandingsModule()
    --    end)
    --
    --    teardown(function()
    --        AddOn:ToggleModule("Standings")
    --        standings = nil
    --    end)
    --
    --    it("builds main frame", function()
    --        standings:GetFrame()
    --        assert(standings.frame)
    --        MSA_DropDownMenu_CreateFrames(1, 20)
    --        standings.FilterMenu(_, 1)
    --    end)
    --    it("builds adjust frame", function()
    --        local f = standings:GetAdjustFrame()
    --        assert(standings.adjustFrame)
    --        local award, errors = f.Validate()
    --        assert(award)
    --        assert(#errors > 0)
    --        f.UpdateSubjectTooltip({{'Player101-Realm1', 'ROGUE'}})
    --        f.Update(Award.SubjectType.Character, Award.ResourceType.Ep, 'Player101-Realm1')
    --        assert(f:IsVisible())
    --        standings.AdjustOnShow(Popup(), NewAward())
    --        assert(f:IsVisible())
    --        standings:AdjustAction(Award.SubjectType.Character, Award.ResourceType.Ep, {name='Player101-Realm1'})
    --        assert(f:IsVisible())
    --    end)
    --    it("builds decay frame", function()
    --        local f = standings:GetDecayFrame()
    --        assert(standings.decayFrame)
    --        local award, errors = f.Validate()
    --        assert(award)
    --        assert(#errors > 0)
    --        f.Update()
    --        assert(f:IsVisible())
    --        local p = Popup()
    --        standings.DecayOnShow(p, {NewAward()})
    --        assert(p.text:GetText() == "Are you certain you want to decay |cFF87CEFAGP|r by |cff33ff991000|r percent for |cffff0000the Character|r?")
    --    end)
    --end)
end)