local AddOnName, AddOn, ACB, Util

describe("AceConfig", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_AceConfig')
        ACB = AddOn.ImportPackage('UI.AceConfig').ConfigBuilder
        Util = AddOn:GetLibrary('Util')
    end)

    teardown(function()
        After()
    end)

    describe("builder", function()
        it("from template", function()
            local config = ACB({ name = AddOnName}):build()
            assert.are.same({ name = AddOnName}, config)
        end)
        it("header", function()
            local config =
                ACB()
                    :header('header_param', 'header_name'):order(2)
                    :build()
            local header = config['header_param']
            assert(header)
            assert.are.same(header,
                    {
                        name = 'header_name',
                        type = 'header',
                        order = 2
                    }
            )
        end)
        it("args no children", function()
            local config =
                ACB():args():build()
            assert.are.same(
                    config,
                    { args = {} }
            )
        end)
        it("args with children", function()
            local config =
                ACB()
                    :args()
                        :header('header_param1', 'header_name1'):order(0)
                    :build()
            assert.are.same(
                    config,
                    {args = {header_param1 = {order = 0, type = 'header', name = 'header_name1'}}}
            )
            --print(Util.Objects.ToString(config, 10))
        end)
        it("nested", function()
            local config =
                ACB()
                    :header('header_param1', 'header_name1'):order(0)
                    :group('group_param1', 'group_name1'):order(1)
                        :args()
                            :group('group_param2', 'group_name2'):order(0)
                                :args()
                                    :toggle('toggle_param1', "toggle_name1"):order(1):desc("toggle_desc1")
                                    :toggle('toggle_param2', "toggle_name2"):order(2):desc("toggle_desc2")
                                    :header('header_param2', "header_name2"):order(3)
                                    :execute('execute_param1', "execute_name1"):order(4):desc("execute_desc1")
                                    :execute('execute_param2', "execute_name2"):order(5):desc("execute_desc2")
                                    :execute('execute_param3', "execute_name3"):order(6):desc("execute_desc3")
                    :build()

            assert.are.same(
                    config,
                    { group_param1 = { order = 1, type = 'group', name = 'group_name1', args = { group_param2 = { order = 0, type = 'group', name = 'group_name2', args = { execute_param3 = { order = 6, type = 'execute', name = 'execute_name3', desc = 'execute_desc3' }, toggle_param2 = { order = 2, type = 'toggle', name = 'toggle_name2', desc = 'toggle_desc2' }, execute_param2 = { order = 5, type = 'execute', name = 'execute_name2', desc = 'execute_desc2' }, header_param2 = { order = 3, type = 'header', name = 'header_name2' }, toggle_param1 = { order = 1, type = 'toggle', name = 'toggle_name1', desc = 'toggle_desc1' }, execute_param1 = { order = 4, type = 'execute', name = 'execute_name1', desc = 'execute_desc1' } } } } }, header_param1 = { order = 0, type = 'header', name = 'header_name1' } }
            )
        end)
    end)
end)