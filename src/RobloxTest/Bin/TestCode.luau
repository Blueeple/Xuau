-- Test c++ code to run in our funny transpiler thing.
return {[[
//@prag LuauProton = { squB = eLineCheck } || can be "dLineCheck"
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

    std::cout << result << std::endl;
    return 0;
}
]]}
