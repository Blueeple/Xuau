local Xuau = require("./src/Xuau/Engine")
local Test = require("./src/RobloxTest/Bin/TestCode")

Xuau.Init()
Xuau.CompileToLuau("cpp", Test)
