local AddOnName, AddOn, Util, Award


describe("Standings", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_SlashCommands')
        Util, Award = AddOn:GetLibrary('Util'), AddOn.Package('Models').Award
        AddOnLoaded(AddOnName, true)
    end)

    teardown(function()
        After()
    end)

    describe("lifecycle", function()
        it("is disabled on startup", function()
            local standings = AddOn:StandingsModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
        it("can be enabled", function()
            AddOn:ToggleModule("Standings")
            local standings = AddOn:StandingsModule()
            assert(standings)
            assert(standings:IsEnabled())
        end)
        it("can be disabled", function()
            AddOn:ToggleModule("Standings")
            local standings = AddOn:StandingsModule()
            assert(standings)
            assert(not standings:IsEnabled())
        end)
    end)

    describe("operations", function()
        local standings

        before_each(function()
            AddOn:ToggleModule("Standings")
            standings = AddOn:StandingsModule()
            PlayerEnteredWorld()
            GuildRosterUpdate()
        end)

        teardown(function()
            AddOn:ToggleModule("Standings")
            standings = nil
        end)

        it("builds data", function()
            standings:BuildData()
            local ep, gp, pr = standings.Points('Player101-Realm1')
            assert(ep == 1240)
            assert(gp == 34)
            assert(pr == Util.Numbers.Round(ep/gp, 2))
        end)

        it("performs adjustment", function()
            local award = Award()
            award:SetAction(Award.ActionType.Add)
            award:SetResource(Award.ResourceType.Ep, 50)
            award:SetSubjects(Award.SubjectType.Character, 'Player102-Realm1')
            standings:Adjust(award)
            local ep, gp, pr = standings.Points('Player102-Realm1')
            assert(ep == 1290)
            assert(gp == 34)
            assert(pr == Util.Numbers.Round(ep/gp, 2))
        end)

        it("performs bulk adjustment", function()
            local awards = {}
            local award = Award()
            award:SetAction(Award.ActionType.Decay)
            award:SetResource(Award.ResourceType.Ep, 0.10)
            award:SetSubjects(Award.SubjectType.Guild)
            tinsert(awards, award)
            award = award:clone()
            award:SetResource(Award.ResourceType.Gp, 0.10)
            tinsert(awards, award)
            standings:BulkAdjust(unpack(awards))

            local ep, gp, pr = standings.Points('Player101-Realm1')
            --print(format('%d, %d, %d', ep, gp, pr))
            assert(ep == 1116)
            assert(gp == 31)
            assert(pr == Util.Numbers.Round(ep/gp, 2))
            ep, gp, pr = standings.Points('Player107-Realm1')
            assert(ep == 1116)
            assert(gp == 31)
            assert(pr == Util.Numbers.Round(ep/gp, 2))
        end)
    end)

    describe("ui", function()
        local standings

        local function NewAward()
            local award = Award()
            award:SetAction(Award.ActionType.Add)
            award:SetResource(Award.ResourceType.Gp, 10)
            award:SetSubjects(Award.SubjectType.Character, 'Player102-Realm1')
            return award
        end

        local function Popup()
            local p = CreateFrame("Frame")
            p.text = {value = ''}
            p.text.SetText = function(v) p.text.value = v end
            return p
        end

        before_each(function()
            AddOn:ToggleModule("Standings")
            standings = AddOn:StandingsModule()
        end)

        teardown(function()
            AddOn:ToggleModule("Standings")
            standings = nil
        end)

        it("builds main frame", function()
            standings:GetFrame()
            assert(standings.frame)
            MSA_DropDownMenu_CreateFrames(1, 20)
            standings.FilterMenu(_, 1)
        end)
        it("builds adjust frame", function()
            local f = standings:GetAdjustFrame()
            assert(standings.adjustFrame)
            f.Validate()
            f.UpdateSubjectTooltip({{'Player101-Realm1', 'ROGUE'}})
            f.Update(Award.SubjectType.Character, Award.ResourceType.Ep, 'Player101-Realm1')
            standings.AdjustOnShow(Popup(), NewAward())
            standings:AdjustAction(Award.SubjectType.Character, Award.ResourceType.Ep, {name='Player101-Realm1'})
        end)
        it("builds decay frame", function()
            local f = standings:GetDecayFrame()
            assert(standings.decayFrame)
            f.Validate()
            f.Update()
            standings.DecayOnShow(Popup(), {NewAward()})
        end)
    end)
end)