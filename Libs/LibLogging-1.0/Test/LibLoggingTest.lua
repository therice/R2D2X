local Logging

_G.pcall = pcall

describe("LibLogging", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibLogging')
        loadfile("Test/WowXmlParser.lua")()
        ParseXmlAndLoad('Libs/LibLogging-1.0/LibLogging-1.0.xml')
        Logging = LibStub:GetLibrary('LibLogging-1.0')
    end)
    teardown(function()
        After()
    end)
    describe("logging levels", function()
        it("define thresholds", function()
            local min =  Logging:GetMinThreshold()
            local max =  Logging:GetMaxThreshold()

            for key, value in pairs(Logging.Level) do
                local threshold = Logging:GetThreshold(value)
                assert.is_number(threshold)
                assert(threshold >= min,format("%s(%s) not greater than min threshold %s", key, threshold, min))
                assert(threshold <= max,format("%s(%s) not less than max threshold %s", key, threshold, max))
            end
        end)
    end)
    describe("root threshold", function()
        it("can be specified", function()
            Logging:SetRootThreshold(Logging.Level.Info)
            assert(Logging:GetRootThreshold() == Logging:GetThreshold(Logging.Level.Info))
            assert(not Logging:IsEnabledFor(Logging.Level.Trace))
            assert(not Logging:IsEnabledFor(Logging.Level.Debug))
            assert(Logging:IsEnabledFor(Logging.Level.Info))
            assert(Logging:IsEnabledFor(Logging.Level.Warn))
            assert(Logging:IsEnabledFor(Logging.Level.Error))
            assert(Logging:IsEnabledFor(Logging.Level.Fatal))
            Logging:Enable()
            assert(Logging:GetRootThreshold()== Logging:GetThreshold(Logging.Level.Debug))
            assert(not Logging:IsEnabledFor(Logging.Level.Trace))
            assert(Logging:IsEnabledFor(Logging.Level.Debug))
            assert(Logging:IsEnabledFor(Logging.Level.Info))
            assert(Logging:IsEnabledFor(Logging.Level.Warn))
            assert(Logging:IsEnabledFor(Logging.Level.Error))
            assert(Logging:IsEnabledFor(Logging.Level.Fatal))
            Logging:Disable()
            assert(Logging:GetRootThreshold()== Logging:GetThreshold(Logging.Level.Disabled))
            assert(not Logging:IsEnabledFor(Logging.Level.Trace))
            assert(not Logging:IsEnabledFor(Logging.Level.Debug))
            assert(not Logging:IsEnabledFor(Logging.Level.Info))
            assert(not Logging:IsEnabledFor(Logging.Level.Warn))
            assert(not Logging:IsEnabledFor(Logging.Level.Error))
            assert(not  Logging:IsEnabledFor(Logging.Level.Fatal))
        end)
    end)
    describe("incorrect format and arguments", function()
        it("prevents error", function()
            Logging:SetRootThreshold(Logging.Level.Debug)
            assert.no.error(function() Logging:Debug("%s %s", 1) end)
            assert.no.error(function() Logging:Debug("%s %s", 1) end)
            assert.no.error(function() Logging:Debug("%s %s", 1, nil) end)
            assert.no.error(function() Logging:Debug("%d", "str") end)
            Logging:ResetWriter()
        end)
    end)
    describe("write output to", function()
        it("specified handler", function()
            local logging_output = ""
            local CaptureOutput = function(msg)
                logging_output = msg
            end
            Logging:SetRootThreshold(Logging.Level.Debug)
            Logging:SetWriter(CaptureOutput)
            Logging:Log(Logging.Level.Info, "InfoTest")
            assert.matches("INFO.*(LibLoggingTest.lua.*): InfoTest",logging_output)
            logging_output = ""
            Logging:Debug("DebugTest")
            assert.matches("DEBUG.*(LibLoggingTest.lua.*): DebugTest",logging_output)
            logging_output = ""
            Logging:Trace("TraceTest")
            assert(logging_output == '')
            Logging:ResetWriter()
        end)
    end)
end)