int rec(int count) {
    print_char(count);
    if(count-100) {
        rec(count+1);
    }
    return;
}
void main() {
    rec(97);
}
