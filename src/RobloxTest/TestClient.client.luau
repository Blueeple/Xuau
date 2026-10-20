--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Transulator = require(ReplicatedStorage:WaitForChild("Xuau"))

-- CodeToTest
local Test = [[
#include <iostream>

int add(int a, int b) {
    return a + b;
}

int main() {
    int x = 5;
    int y = 10;
    int result = add(x, y);

    for (int i = 0; i < 3; i++) {
        result += i;
    }

    std::cout << result << '\n';
    return result;
}

]]
Transulator.CompileToLuau("cpp", Test, "Test")
