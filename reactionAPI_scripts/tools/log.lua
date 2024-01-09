local module = {}

local ModName = "ReactionAPI"

local function Print(String)
    Isaac.ConsoleOutput(String .. "\n")
    Isaac.DebugString(String)
end

local function ConsolePrint(String)
    Isaac.ConsoleOutput(String .. "\n")
end

local function PrintError(String, FunctionName)
    if FunctionName then
        Print("[ERROR in " .. ModName .. "." .. FunctionName .. "]: " .. String)
    else
        Print("[ERROR in " .. ModName .. "]: " .. String)
    end
end

local function Diagnostic(Diagnose, String)
    if ReactionAPI.Diagnostics[Diagnose] then
        Print("[DIAGNOSTICS ".. ModName .."]: " .. String)
    end
end

module.print = Print
module.console = ConsolePrint
module.error = PrintError
module.diagnostic = Diagnostic

return module