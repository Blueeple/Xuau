local Xuau = require("./src/Xuau/Engine")
local _CodeToTest = require("./src/RobloxTest/Bin/TestCode")

local exampleLine = { "int x = 5;" }

--Xuau.Init()
Xuau.CompileToLuau(exampleLine)
