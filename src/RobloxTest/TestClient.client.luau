--!strict
-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local _Bin = ReplicatedFirst:WaitForChild("Bin")

-- Packages
local Transulator = require(ReplicatedStorage:WaitForChild("Xuau").Engine)

-- CodeToTest
local Test = require("./Bin/TestCode")
Transulator.CompileToLuau("cpp", Test)
