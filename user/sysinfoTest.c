#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/sysinfo.h"
#include "user.h"


int main(void){ 
    int ms_per_tick = 100;
    struct sysinfo info;

    sysinfo(&info);
    printf("number of processs: %d\n", info.nproc);
    printf("total ram:\n %dbyte\n %dkb\n %dmb\n",\
        info.totalram, info.totalram / 1024, info.totalram / 1048576);
    printf("available ram:\n %dbyte\n %dkb\n %dmb\n",\
        info.freemem, info.freemem / 1024, info.freemem / 1048576);
    printf("uptime: %dms=%ds\n",\
     info.uptime * ms_per_tick, info.uptime / 100);
   
    return 0;
}
