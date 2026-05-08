module my_class;

auto MyClass::getValue() const -> int
{
    return value_;
}

void MyClass::setValue(int value)
{
    value_ = value;
}
