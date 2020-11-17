local AddOnName, AddOn,  Util, Subject, Award

describe("Point", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Player')
        Util, Subject, Award = AddOn:GetLibrary('Util'), AddOn.Package('Models').Subject, AddOn.Package('Models').Award
    end)

    teardown(function()
        After()
    end)

    describe("Subject", function()
        it("fails with invalid arguments", function()
            assert.has.errors(function() Subject('name', nil) end, "Must specify 'class' (either display name or upper-case name)")
            assert.has.errors(function() Subject('name', 'WARRIOR') end, "Must specify 'ep' as number")
            assert.has.errors(function() Subject('name', 'WARRIOR', nil, nil, 10) end, "Must specify 'gp' as number")
        end)
        it("succeeds with raw arguments", function()
            assert(Subject('name', 'WARRIOR', nil, nil, 10, 10))
            assert(Subject('name', 'WARRIOR', 'rank', 1, 10, 10))
        end)
        it("succeeds with object argument", function()
            assert(Subject:FromGuildMember({
                name = 'NAME',
                class = 'WARLOCK',
                rank = 'RANK',
                rankIndex = 3,
                officerNote = '10,2',
            }))
        end)
        it("provides points", function()
            local s =  Subject:FromGuildMember({
                name = 'NAME',
                class = 'WARLOCK',
                rank = 'RANK',
                rankIndex = 3,
                officerNote = '123,12',
            })
            local expectedPr = Util.Numbers.Round(123 / 12, 2)
            local ep, gp, pr = s:Points()
            assert(ep == 123)
            assert(gp == 12)
            assert(pr == expectedPr)
            assert(s:GetPR() ==  expectedPr)
            assert(s:ToNote() == "123,12")
        end)
    end)

    describe("Award", function()

        local function NewAwardData(
                actionType, subjectType, subjects,
                resourceType, resourceQuantity, description
        )
            return {
                actionType = actionType,
                subjectType = subjectType,
                subjects = subjects,
                resourceType = resourceType,
                resourceQuantity = resourceQuantity,
                description = description
            }
        end

        it("fails with invalid arguments", function()
            assert.has.errors(function() Award('a') end, "the specified data was not of the appropriate type : string")
        end)

        it("succeeds with table argument", function()
            assert(Award(NewAwardData()))
            assert(Award(NewAwardData(Award.ActionType.Add)))
        end)

        it("instance methods", function()
            local a = Award(NewAwardData(Award.ActionType.Add, Award.SubjectType.Character, {}))
            assert(a:GetSubjectOriginText() == 'Character')
            a = Award(NewAwardData(Award.ActionType.Add, Award.SubjectType.Guild, {'a', 'b', 'c'}))
            assert(a:GetSubjectOriginText() == 'Guild(3)')
            a = Award(NewAwardData())
            a:SetAction(Award.ActionType.Add)
            assert(a.actionType == Award.ActionType.Add)
            assert.has.errors(function() a:SetAction(-11) end, "Invalid Action Type specified")
            a = Award(NewAwardData())
            a:SetResource(Award.ResourceType.Ep, 10)
            assert(a.resourceType == Award.ResourceType.Ep)
            assert(a.resourceQuantity == 10)
            assert.has.errors(function() a:SetResource(-1, 10) end, "Invalid Resource Type specified")
            assert.has.errors(function() a:SetResource(Award.ResourceType.Gp, "10") end, "Resource Quantity must be a number")
        end)

        it("populates character subjects", function()
            local a = Award(NewAwardData(Award.ActionType.Add))
            a:SetSubjects(Award.SubjectType.Character, 'Eliovak-Atiesh')
            assert.is.same(a.subjects, {{'Eliovak-Atiesh', 'ROGUE'}})
            a:SetSubjects(Award.SubjectType.Character, 'Player1')
            assert.is.same(a.subjects, {{'Player1-Realm1', 'WARRIOR'}})
            GuildRosterUpdate()
            a:SetSubjects(Award.SubjectType.Guild)
            assert(#a.subjects == GetNumGuildMembers())
            for _, e in pairs(a.subjects) do
                local player, class = e[1], e[2]
                assert(player)
                assert(class)
                assert(strmatch(player, '[^-]*-.*'))
                assert(AddOn:UnitClass(player) == class)
            end
        end)

        it("populates standby subjects", function()
            local a = Award(NewAwardData(Award.ActionType.Add))
            a:SetSubjects(Award.SubjectType.Standby, 'Eliovak-Atiesh')
            assert.is.same(a.subjects, {{'Eliovak-Atiesh', 'ROGUE'}})
        end)


        it("populates guild subjects", function()
            local a = Award(NewAwardData(Award.ActionType.Add))
            a:SetResource(Award.ResourceType.Ep, 10)
            GuildRosterUpdate()
            a:SetSubjects(Award.SubjectType.Guild)
            print(a:ToAnnouncement())
            assert(#a.subjects == GetNumGuildMembers())
            for _, e in pairs(a.subjects) do
                local player, class = e[1], e[2]
                assert(player)
                assert(class)
                assert(strmatch(player, '[^-]*-.*'))
                assert(AddOn:UnitClass(player) == class)
            end
        end)

        it("populates raid subjects", function()
            local a = Award(NewAwardData(Award.ActionType.Add))
            a:SetSubjects(Award.SubjectType.Raid)
            assert(#a.subjects == GetNumGroupMembers())

            for _, e in pairs(a.subjects) do
                local player, class = e[1], e[2]
                assert(player)
                assert(class)
                assert(strmatch(player, '[^-]*-.*'))
                assert(AddOn:UnitClass(player) == class)
            end
        end)
    end)
end)