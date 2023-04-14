#include "types.h"

struct sysinfo
{
    long uptime;
    unsigned long totalram;
    // unsigned long freemem;
    // unsigned short nproc;
    uint64 freemem;
    uint64 nproc;
};
