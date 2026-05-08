export module my_class;

export class MyClass
{
private:
    int value_ = 0;

public:
    MyClass() = default;
    MyClass(int value) : value_(value) {}

    [[nodiscard]] auto getValue() const -> int;

    void setValue(int value);
};
