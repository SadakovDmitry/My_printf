#include <stdio.h>

extern long long int my_printf(char* format_str, ...);

int main ()
{
    //my_printf("\nHello world!! %x %o %b %d %d %c %c %d <%s> [%d] euebcue", -15, 44, 128, 0, 400, '$', 'S', 1, "meaw", 1000);
    //my_printf("%d %d %d %d %d [%d] [%d] [%d] [%d]\n", 52, 3547, 4683, 2974, 84, 56, 234, 88878, 999);
    //my_printf("%d %d %d %d %d %d \n", 357262, 1, 2, 3, 4, 5);
    my_printf("%d %c %s %x %d%% %c\n", -1, 'I', "love", 3802, 100, '!');
    //printf("%u\n", (unsigned)(~0));
}

