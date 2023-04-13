#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main(void){
    getProcTick();
    printf("successful!\n");
    exit(0);
}