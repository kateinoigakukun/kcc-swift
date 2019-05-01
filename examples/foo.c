void foo(int value1, int value2) {
    print_char(48);
    bar(value2);
}
void bar(int baz) {
    print_char(49);
    foo(baz, 21);
}
int main() {
    foo(61, 65);
}
