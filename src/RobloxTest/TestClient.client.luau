--!strict
-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local _Bin = ReplicatedFirst:WaitForChild("Bin")

-- Packages
local Transulator = require(ReplicatedStorage:WaitForChild("Xuau").Engine)

-- CodeToTest
local _Test = require("./Bin/TestCode")
local exampleLine = { "int x = 5;" }

Transulator.CompileToLuau(exampleLine)
