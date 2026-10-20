local Xuau = require("./src/Xuau")
local Path = "./src/RobloxTest/test.cpp"

Xuau.Init()
local ExampleCode = Xuau.ReadExternalFile(Path)
Xuau.CompileToLuau("cpp", ExampleCode, "TestCode")
