import std;
import my_class;

auto main() -> int
{
    std::println("Hello, world!");

    MyClass obj(10);
    std::println("Value: {}", obj.getValue());

    obj.setValue(100);
    std::println("Updated Value: {}", obj.getValue());
}
