#include <stdio.h>

extern long long int my_printf(char* format_str, ...);

int main ()
{
    my_printf(" Hello%c w%crld%%!!%s %c %b", ':', 'u', " goodby", '$', -31);
}
