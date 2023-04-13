#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main(void){ 
    // getProcInfo();
    sysinfo();
    printf("Successful!\n");
    exit(0);
}
