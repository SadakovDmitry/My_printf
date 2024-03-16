#include <stdio.h>

extern long long int my_printf(char* format_str, ...);

int main ()
{
    my_printf(" Hello world!!\n %x %o %b %d %d %c %c %d <%s> [%d] euebcue", -17, 44, 128, 0, 400, '$', 'S', 1, "meaw", 1000);
    //my_printf("%d %d %d %d %d [%d] [%d] [%d] [%d]\n", 527, 3547, 4683, 2974, 84, 56, 234, 888, 999);
}
