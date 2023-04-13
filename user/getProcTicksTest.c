#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

// int main(void){
//     getProcTick();
//     printf("  successful!\n");
//     exit(0);
// }

int
main(int argc, char **argv)
{
  int i;

  if(argc < 2){
    fprintf(2, "usage: get ticks ...\n");
    exit(1);
  }
  for(i=1; i<argc; i++)
    getProcTick(atoi(argv[i]));
    // printf("successful!\n");
  exit(0);
}
