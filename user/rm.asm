
user/_rm:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  int i;

  if(argc < 2){
   e:	4785                	li	a5,1
  10:	02a7d763          	bge	a5,a0,3e <main+0x3e>
  14:	00858493          	addi	s1,a1,8
  18:	ffe5091b          	addiw	s2,a0,-2
  1c:	1902                	slli	s2,s2,0x20
  1e:	02095913          	srli	s2,s2,0x20
  22:	090e                	slli	s2,s2,0x3
  24:	05c1                	addi	a1,a1,16
  26:	992e                	add	s2,s2,a1
    fprintf(2, "Usage: rm files...\n");
    exit(1);
  }

  for(i = 1; i < argc; i++){
    if(unlink(argv[i]) < 0){
  28:	6088                	ld	a0,0(s1)
  2a:	00000097          	auipc	ra,0x0
  2e:	326080e7          	jalr	806(ra) # 350 <unlink>
  32:	02054463          	bltz	a0,5a <main+0x5a>
  for(i = 1; i < argc; i++){
  36:	04a1                	addi	s1,s1,8
  38:	ff2498e3          	bne	s1,s2,28 <main+0x28>
  3c:	a80d                	j	6e <main+0x6e>
    fprintf(2, "Usage: rm files...\n");
  3e:	00001597          	auipc	a1,0x1
  42:	80258593          	addi	a1,a1,-2046 # 840 <malloc+0xea>
  46:	4509                	li	a0,2
  48:	00000097          	auipc	ra,0x0
  4c:	622080e7          	jalr	1570(ra) # 66a <fprintf>
    exit(1);
  50:	4505                	li	a0,1
  52:	00000097          	auipc	ra,0x0
  56:	2ae080e7          	jalr	686(ra) # 300 <exit>
      fprintf(2, "rm: %s failed to delete\n", argv[i]);
  5a:	6090                	ld	a2,0(s1)
  5c:	00000597          	auipc	a1,0x0
  60:	7fc58593          	addi	a1,a1,2044 # 858 <malloc+0x102>
  64:	4509                	li	a0,2
  66:	00000097          	auipc	ra,0x0
  6a:	604080e7          	jalr	1540(ra) # 66a <fprintf>
      break;
    }
  }

  exit(0);
  6e:	4501                	li	a0,0
  70:	00000097          	auipc	ra,0x0
  74:	290080e7          	jalr	656(ra) # 300 <exit>

0000000000000078 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  78:	1141                	addi	sp,sp,-16
  7a:	e406                	sd	ra,8(sp)
  7c:	e022                	sd	s0,0(sp)
  7e:	0800                	addi	s0,sp,16
  extern int main();
  main();
  80:	00000097          	auipc	ra,0x0
  84:	f80080e7          	jalr	-128(ra) # 0 <main>
  exit(0);
  88:	4501                	li	a0,0
  8a:	00000097          	auipc	ra,0x0
  8e:	276080e7          	jalr	630(ra) # 300 <exit>

0000000000000092 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  92:	1141                	addi	sp,sp,-16
  94:	e422                	sd	s0,8(sp)
  96:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  98:	87aa                	mv	a5,a0
  9a:	0585                	addi	a1,a1,1
  9c:	0785                	addi	a5,a5,1
  9e:	fff5c703          	lbu	a4,-1(a1)
  a2:	fee78fa3          	sb	a4,-1(a5)
  a6:	fb75                	bnez	a4,9a <strcpy+0x8>
    ;
  return os;
}
  a8:	6422                	ld	s0,8(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret

00000000000000ae <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ae:	1141                	addi	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	cb91                	beqz	a5,cc <strcmp+0x1e>
  ba:	0005c703          	lbu	a4,0(a1)
  be:	00f71763          	bne	a4,a5,cc <strcmp+0x1e>
    p++, q++;
  c2:	0505                	addi	a0,a0,1
  c4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	fbe5                	bnez	a5,ba <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  cc:	0005c503          	lbu	a0,0(a1)
}
  d0:	40a7853b          	subw	a0,a5,a0
  d4:	6422                	ld	s0,8(sp)
  d6:	0141                	addi	sp,sp,16
  d8:	8082                	ret

00000000000000da <strlen>:

uint
strlen(const char *s)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  e0:	00054783          	lbu	a5,0(a0)
  e4:	cf91                	beqz	a5,100 <strlen+0x26>
  e6:	0505                	addi	a0,a0,1
  e8:	87aa                	mv	a5,a0
  ea:	4685                	li	a3,1
  ec:	9e89                	subw	a3,a3,a0
  ee:	00f6853b          	addw	a0,a3,a5
  f2:	0785                	addi	a5,a5,1
  f4:	fff7c703          	lbu	a4,-1(a5)
  f8:	fb7d                	bnez	a4,ee <strlen+0x14>
    ;
  return n;
}
  fa:	6422                	ld	s0,8(sp)
  fc:	0141                	addi	sp,sp,16
  fe:	8082                	ret
  for(n = 0; s[n]; n++)
 100:	4501                	li	a0,0
 102:	bfe5                	j	fa <strlen+0x20>

0000000000000104 <memset>:

void*
memset(void *dst, int c, uint n)
{
 104:	1141                	addi	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 10a:	ca19                	beqz	a2,120 <memset+0x1c>
 10c:	87aa                	mv	a5,a0
 10e:	1602                	slli	a2,a2,0x20
 110:	9201                	srli	a2,a2,0x20
 112:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 116:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 11a:	0785                	addi	a5,a5,1
 11c:	fee79de3          	bne	a5,a4,116 <memset+0x12>
  }
  return dst;
}
 120:	6422                	ld	s0,8(sp)
 122:	0141                	addi	sp,sp,16
 124:	8082                	ret

0000000000000126 <strchr>:

char*
strchr(const char *s, char c)
{
 126:	1141                	addi	sp,sp,-16
 128:	e422                	sd	s0,8(sp)
 12a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 12c:	00054783          	lbu	a5,0(a0)
 130:	cb99                	beqz	a5,146 <strchr+0x20>
    if(*s == c)
 132:	00f58763          	beq	a1,a5,140 <strchr+0x1a>
  for(; *s; s++)
 136:	0505                	addi	a0,a0,1
 138:	00054783          	lbu	a5,0(a0)
 13c:	fbfd                	bnez	a5,132 <strchr+0xc>
      return (char*)s;
  return 0;
 13e:	4501                	li	a0,0
}
 140:	6422                	ld	s0,8(sp)
 142:	0141                	addi	sp,sp,16
 144:	8082                	ret
  return 0;
 146:	4501                	li	a0,0
 148:	bfe5                	j	140 <strchr+0x1a>

000000000000014a <gets>:

char*
gets(char *buf, int max)
{
 14a:	711d                	addi	sp,sp,-96
 14c:	ec86                	sd	ra,88(sp)
 14e:	e8a2                	sd	s0,80(sp)
 150:	e4a6                	sd	s1,72(sp)
 152:	e0ca                	sd	s2,64(sp)
 154:	fc4e                	sd	s3,56(sp)
 156:	f852                	sd	s4,48(sp)
 158:	f456                	sd	s5,40(sp)
 15a:	f05a                	sd	s6,32(sp)
 15c:	ec5e                	sd	s7,24(sp)
 15e:	1080                	addi	s0,sp,96
 160:	8baa                	mv	s7,a0
 162:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 164:	892a                	mv	s2,a0
 166:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 168:	4aa9                	li	s5,10
 16a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 16c:	89a6                	mv	s3,s1
 16e:	2485                	addiw	s1,s1,1
 170:	0344d863          	bge	s1,s4,1a0 <gets+0x56>
    cc = read(0, &c, 1);
 174:	4605                	li	a2,1
 176:	faf40593          	addi	a1,s0,-81
 17a:	4501                	li	a0,0
 17c:	00000097          	auipc	ra,0x0
 180:	19c080e7          	jalr	412(ra) # 318 <read>
    if(cc < 1)
 184:	00a05e63          	blez	a0,1a0 <gets+0x56>
    buf[i++] = c;
 188:	faf44783          	lbu	a5,-81(s0)
 18c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 190:	01578763          	beq	a5,s5,19e <gets+0x54>
 194:	0905                	addi	s2,s2,1
 196:	fd679be3          	bne	a5,s6,16c <gets+0x22>
  for(i=0; i+1 < max; ){
 19a:	89a6                	mv	s3,s1
 19c:	a011                	j	1a0 <gets+0x56>
 19e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1a0:	99de                	add	s3,s3,s7
 1a2:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a6:	855e                	mv	a0,s7
 1a8:	60e6                	ld	ra,88(sp)
 1aa:	6446                	ld	s0,80(sp)
 1ac:	64a6                	ld	s1,72(sp)
 1ae:	6906                	ld	s2,64(sp)
 1b0:	79e2                	ld	s3,56(sp)
 1b2:	7a42                	ld	s4,48(sp)
 1b4:	7aa2                	ld	s5,40(sp)
 1b6:	7b02                	ld	s6,32(sp)
 1b8:	6be2                	ld	s7,24(sp)
 1ba:	6125                	addi	sp,sp,96
 1bc:	8082                	ret

00000000000001be <stat>:

int
stat(const char *n, struct stat *st)
{
 1be:	1101                	addi	sp,sp,-32
 1c0:	ec06                	sd	ra,24(sp)
 1c2:	e822                	sd	s0,16(sp)
 1c4:	e426                	sd	s1,8(sp)
 1c6:	e04a                	sd	s2,0(sp)
 1c8:	1000                	addi	s0,sp,32
 1ca:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1cc:	4581                	li	a1,0
 1ce:	00000097          	auipc	ra,0x0
 1d2:	172080e7          	jalr	370(ra) # 340 <open>
  if(fd < 0)
 1d6:	02054563          	bltz	a0,200 <stat+0x42>
 1da:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1dc:	85ca                	mv	a1,s2
 1de:	00000097          	auipc	ra,0x0
 1e2:	17a080e7          	jalr	378(ra) # 358 <fstat>
 1e6:	892a                	mv	s2,a0
  close(fd);
 1e8:	8526                	mv	a0,s1
 1ea:	00000097          	auipc	ra,0x0
 1ee:	13e080e7          	jalr	318(ra) # 328 <close>
  return r;
}
 1f2:	854a                	mv	a0,s2
 1f4:	60e2                	ld	ra,24(sp)
 1f6:	6442                	ld	s0,16(sp)
 1f8:	64a2                	ld	s1,8(sp)
 1fa:	6902                	ld	s2,0(sp)
 1fc:	6105                	addi	sp,sp,32
 1fe:	8082                	ret
    return -1;
 200:	597d                	li	s2,-1
 202:	bfc5                	j	1f2 <stat+0x34>

0000000000000204 <atoi>:

int
atoi(const char *s)
{
 204:	1141                	addi	sp,sp,-16
 206:	e422                	sd	s0,8(sp)
 208:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 20a:	00054603          	lbu	a2,0(a0)
 20e:	fd06079b          	addiw	a5,a2,-48
 212:	0ff7f793          	andi	a5,a5,255
 216:	4725                	li	a4,9
 218:	02f76963          	bltu	a4,a5,24a <atoi+0x46>
 21c:	86aa                	mv	a3,a0
  n = 0;
 21e:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 220:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 222:	0685                	addi	a3,a3,1
 224:	0025179b          	slliw	a5,a0,0x2
 228:	9fa9                	addw	a5,a5,a0
 22a:	0017979b          	slliw	a5,a5,0x1
 22e:	9fb1                	addw	a5,a5,a2
 230:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 234:	0006c603          	lbu	a2,0(a3)
 238:	fd06071b          	addiw	a4,a2,-48
 23c:	0ff77713          	andi	a4,a4,255
 240:	fee5f1e3          	bgeu	a1,a4,222 <atoi+0x1e>
  return n;
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
  n = 0;
 24a:	4501                	li	a0,0
 24c:	bfe5                	j	244 <atoi+0x40>

000000000000024e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e422                	sd	s0,8(sp)
 252:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 254:	02b57463          	bgeu	a0,a1,27c <memmove+0x2e>
    while(n-- > 0)
 258:	00c05f63          	blez	a2,276 <memmove+0x28>
 25c:	1602                	slli	a2,a2,0x20
 25e:	9201                	srli	a2,a2,0x20
 260:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 264:	872a                	mv	a4,a0
      *dst++ = *src++;
 266:	0585                	addi	a1,a1,1
 268:	0705                	addi	a4,a4,1
 26a:	fff5c683          	lbu	a3,-1(a1)
 26e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 272:	fee79ae3          	bne	a5,a4,266 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 276:	6422                	ld	s0,8(sp)
 278:	0141                	addi	sp,sp,16
 27a:	8082                	ret
    dst += n;
 27c:	00c50733          	add	a4,a0,a2
    src += n;
 280:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 282:	fec05ae3          	blez	a2,276 <memmove+0x28>
 286:	fff6079b          	addiw	a5,a2,-1
 28a:	1782                	slli	a5,a5,0x20
 28c:	9381                	srli	a5,a5,0x20
 28e:	fff7c793          	not	a5,a5
 292:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 294:	15fd                	addi	a1,a1,-1
 296:	177d                	addi	a4,a4,-1
 298:	0005c683          	lbu	a3,0(a1)
 29c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2a0:	fee79ae3          	bne	a5,a4,294 <memmove+0x46>
 2a4:	bfc9                	j	276 <memmove+0x28>

00000000000002a6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a6:	1141                	addi	sp,sp,-16
 2a8:	e422                	sd	s0,8(sp)
 2aa:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ac:	ca05                	beqz	a2,2dc <memcmp+0x36>
 2ae:	fff6069b          	addiw	a3,a2,-1
 2b2:	1682                	slli	a3,a3,0x20
 2b4:	9281                	srli	a3,a3,0x20
 2b6:	0685                	addi	a3,a3,1
 2b8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ba:	00054783          	lbu	a5,0(a0)
 2be:	0005c703          	lbu	a4,0(a1)
 2c2:	00e79863          	bne	a5,a4,2d2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c6:	0505                	addi	a0,a0,1
    p2++;
 2c8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ca:	fed518e3          	bne	a0,a3,2ba <memcmp+0x14>
  }
  return 0;
 2ce:	4501                	li	a0,0
 2d0:	a019                	j	2d6 <memcmp+0x30>
      return *p1 - *p2;
 2d2:	40e7853b          	subw	a0,a5,a4
}
 2d6:	6422                	ld	s0,8(sp)
 2d8:	0141                	addi	sp,sp,16
 2da:	8082                	ret
  return 0;
 2dc:	4501                	li	a0,0
 2de:	bfe5                	j	2d6 <memcmp+0x30>

00000000000002e0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e406                	sd	ra,8(sp)
 2e4:	e022                	sd	s0,0(sp)
 2e6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2e8:	00000097          	auipc	ra,0x0
 2ec:	f66080e7          	jalr	-154(ra) # 24e <memmove>
}
 2f0:	60a2                	ld	ra,8(sp)
 2f2:	6402                	ld	s0,0(sp)
 2f4:	0141                	addi	sp,sp,16
 2f6:	8082                	ret

00000000000002f8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2f8:	4885                	li	a7,1
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <exit>:
.global exit
exit:
 li a7, SYS_exit
 300:	4889                	li	a7,2
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <wait>:
.global wait
wait:
 li a7, SYS_wait
 308:	488d                	li	a7,3
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 310:	4891                	li	a7,4
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <read>:
.global read
read:
 li a7, SYS_read
 318:	4895                	li	a7,5
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <write>:
.global write
write:
 li a7, SYS_write
 320:	48c1                	li	a7,16
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <close>:
.global close
close:
 li a7, SYS_close
 328:	48d5                	li	a7,21
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <kill>:
.global kill
kill:
 li a7, SYS_kill
 330:	4899                	li	a7,6
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <exec>:
.global exec
exec:
 li a7, SYS_exec
 338:	489d                	li	a7,7
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <open>:
.global open
open:
 li a7, SYS_open
 340:	48bd                	li	a7,15
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 348:	48c5                	li	a7,17
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 350:	48c9                	li	a7,18
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 358:	48a1                	li	a7,8
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <link>:
.global link
link:
 li a7, SYS_link
 360:	48cd                	li	a7,19
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 368:	48d1                	li	a7,20
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 370:	48a5                	li	a7,9
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <dup>:
.global dup
dup:
 li a7, SYS_dup
 378:	48a9                	li	a7,10
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 380:	48ad                	li	a7,11
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 388:	48b1                	li	a7,12
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 390:	48b5                	li	a7,13
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 398:	48b9                	li	a7,14
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <getHelloWorld>:
.global getHelloWorld
getHelloWorld:
 li a7, SYS_getHelloWorld
 3a0:	48d9                	li	a7,22
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <getProcTick>:
.global getProcTick
getProcTick:
 li a7, SYS_getProcTick
 3a8:	48dd                	li	a7,23
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <getProcInfo>:
.global getProcInfo
getProcInfo:
 li a7, SYS_getProcInfo
 3b0:	48e1                	li	a7,24
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 3b8:	48e5                	li	a7,25
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c0:	1101                	addi	sp,sp,-32
 3c2:	ec06                	sd	ra,24(sp)
 3c4:	e822                	sd	s0,16(sp)
 3c6:	1000                	addi	s0,sp,32
 3c8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3cc:	4605                	li	a2,1
 3ce:	fef40593          	addi	a1,s0,-17
 3d2:	00000097          	auipc	ra,0x0
 3d6:	f4e080e7          	jalr	-178(ra) # 320 <write>
}
 3da:	60e2                	ld	ra,24(sp)
 3dc:	6442                	ld	s0,16(sp)
 3de:	6105                	addi	sp,sp,32
 3e0:	8082                	ret

00000000000003e2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e2:	7139                	addi	sp,sp,-64
 3e4:	fc06                	sd	ra,56(sp)
 3e6:	f822                	sd	s0,48(sp)
 3e8:	f426                	sd	s1,40(sp)
 3ea:	f04a                	sd	s2,32(sp)
 3ec:	ec4e                	sd	s3,24(sp)
 3ee:	0080                	addi	s0,sp,64
 3f0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3f2:	c299                	beqz	a3,3f8 <printint+0x16>
 3f4:	0805c863          	bltz	a1,484 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3f8:	2581                	sext.w	a1,a1
  neg = 0;
 3fa:	4881                	li	a7,0
 3fc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 400:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 402:	2601                	sext.w	a2,a2
 404:	00000517          	auipc	a0,0x0
 408:	47c50513          	addi	a0,a0,1148 # 880 <digits>
 40c:	883a                	mv	a6,a4
 40e:	2705                	addiw	a4,a4,1
 410:	02c5f7bb          	remuw	a5,a1,a2
 414:	1782                	slli	a5,a5,0x20
 416:	9381                	srli	a5,a5,0x20
 418:	97aa                	add	a5,a5,a0
 41a:	0007c783          	lbu	a5,0(a5)
 41e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 422:	0005879b          	sext.w	a5,a1
 426:	02c5d5bb          	divuw	a1,a1,a2
 42a:	0685                	addi	a3,a3,1
 42c:	fec7f0e3          	bgeu	a5,a2,40c <printint+0x2a>
  if(neg)
 430:	00088b63          	beqz	a7,446 <printint+0x64>
    buf[i++] = '-';
 434:	fd040793          	addi	a5,s0,-48
 438:	973e                	add	a4,a4,a5
 43a:	02d00793          	li	a5,45
 43e:	fef70823          	sb	a5,-16(a4)
 442:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 446:	02e05863          	blez	a4,476 <printint+0x94>
 44a:	fc040793          	addi	a5,s0,-64
 44e:	00e78933          	add	s2,a5,a4
 452:	fff78993          	addi	s3,a5,-1
 456:	99ba                	add	s3,s3,a4
 458:	377d                	addiw	a4,a4,-1
 45a:	1702                	slli	a4,a4,0x20
 45c:	9301                	srli	a4,a4,0x20
 45e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 462:	fff94583          	lbu	a1,-1(s2)
 466:	8526                	mv	a0,s1
 468:	00000097          	auipc	ra,0x0
 46c:	f58080e7          	jalr	-168(ra) # 3c0 <putc>
  while(--i >= 0)
 470:	197d                	addi	s2,s2,-1
 472:	ff3918e3          	bne	s2,s3,462 <printint+0x80>
}
 476:	70e2                	ld	ra,56(sp)
 478:	7442                	ld	s0,48(sp)
 47a:	74a2                	ld	s1,40(sp)
 47c:	7902                	ld	s2,32(sp)
 47e:	69e2                	ld	s3,24(sp)
 480:	6121                	addi	sp,sp,64
 482:	8082                	ret
    x = -xx;
 484:	40b005bb          	negw	a1,a1
    neg = 1;
 488:	4885                	li	a7,1
    x = -xx;
 48a:	bf8d                	j	3fc <printint+0x1a>

000000000000048c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 48c:	7119                	addi	sp,sp,-128
 48e:	fc86                	sd	ra,120(sp)
 490:	f8a2                	sd	s0,112(sp)
 492:	f4a6                	sd	s1,104(sp)
 494:	f0ca                	sd	s2,96(sp)
 496:	ecce                	sd	s3,88(sp)
 498:	e8d2                	sd	s4,80(sp)
 49a:	e4d6                	sd	s5,72(sp)
 49c:	e0da                	sd	s6,64(sp)
 49e:	fc5e                	sd	s7,56(sp)
 4a0:	f862                	sd	s8,48(sp)
 4a2:	f466                	sd	s9,40(sp)
 4a4:	f06a                	sd	s10,32(sp)
 4a6:	ec6e                	sd	s11,24(sp)
 4a8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4aa:	0005c903          	lbu	s2,0(a1)
 4ae:	18090f63          	beqz	s2,64c <vprintf+0x1c0>
 4b2:	8aaa                	mv	s5,a0
 4b4:	8b32                	mv	s6,a2
 4b6:	00158493          	addi	s1,a1,1
  state = 0;
 4ba:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4bc:	02500a13          	li	s4,37
      if(c == 'd'){
 4c0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4c4:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4c8:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4cc:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4d0:	00000b97          	auipc	s7,0x0
 4d4:	3b0b8b93          	addi	s7,s7,944 # 880 <digits>
 4d8:	a839                	j	4f6 <vprintf+0x6a>
        putc(fd, c);
 4da:	85ca                	mv	a1,s2
 4dc:	8556                	mv	a0,s5
 4de:	00000097          	auipc	ra,0x0
 4e2:	ee2080e7          	jalr	-286(ra) # 3c0 <putc>
 4e6:	a019                	j	4ec <vprintf+0x60>
    } else if(state == '%'){
 4e8:	01498f63          	beq	s3,s4,506 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4ec:	0485                	addi	s1,s1,1
 4ee:	fff4c903          	lbu	s2,-1(s1)
 4f2:	14090d63          	beqz	s2,64c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4f6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4fa:	fe0997e3          	bnez	s3,4e8 <vprintf+0x5c>
      if(c == '%'){
 4fe:	fd479ee3          	bne	a5,s4,4da <vprintf+0x4e>
        state = '%';
 502:	89be                	mv	s3,a5
 504:	b7e5                	j	4ec <vprintf+0x60>
      if(c == 'd'){
 506:	05878063          	beq	a5,s8,546 <vprintf+0xba>
      } else if(c == 'l') {
 50a:	05978c63          	beq	a5,s9,562 <vprintf+0xd6>
      } else if(c == 'x') {
 50e:	07a78863          	beq	a5,s10,57e <vprintf+0xf2>
      } else if(c == 'p') {
 512:	09b78463          	beq	a5,s11,59a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 516:	07300713          	li	a4,115
 51a:	0ce78663          	beq	a5,a4,5e6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 51e:	06300713          	li	a4,99
 522:	0ee78e63          	beq	a5,a4,61e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 526:	11478863          	beq	a5,s4,636 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 52a:	85d2                	mv	a1,s4
 52c:	8556                	mv	a0,s5
 52e:	00000097          	auipc	ra,0x0
 532:	e92080e7          	jalr	-366(ra) # 3c0 <putc>
        putc(fd, c);
 536:	85ca                	mv	a1,s2
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e86080e7          	jalr	-378(ra) # 3c0 <putc>
      }
      state = 0;
 542:	4981                	li	s3,0
 544:	b765                	j	4ec <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 546:	008b0913          	addi	s2,s6,8
 54a:	4685                	li	a3,1
 54c:	4629                	li	a2,10
 54e:	000b2583          	lw	a1,0(s6)
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e8e080e7          	jalr	-370(ra) # 3e2 <printint>
 55c:	8b4a                	mv	s6,s2
      state = 0;
 55e:	4981                	li	s3,0
 560:	b771                	j	4ec <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 562:	008b0913          	addi	s2,s6,8
 566:	4681                	li	a3,0
 568:	4629                	li	a2,10
 56a:	000b2583          	lw	a1,0(s6)
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e72080e7          	jalr	-398(ra) # 3e2 <printint>
 578:	8b4a                	mv	s6,s2
      state = 0;
 57a:	4981                	li	s3,0
 57c:	bf85                	j	4ec <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 57e:	008b0913          	addi	s2,s6,8
 582:	4681                	li	a3,0
 584:	4641                	li	a2,16
 586:	000b2583          	lw	a1,0(s6)
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	e56080e7          	jalr	-426(ra) # 3e2 <printint>
 594:	8b4a                	mv	s6,s2
      state = 0;
 596:	4981                	li	s3,0
 598:	bf91                	j	4ec <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 59a:	008b0793          	addi	a5,s6,8
 59e:	f8f43423          	sd	a5,-120(s0)
 5a2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a6:	03000593          	li	a1,48
 5aa:	8556                	mv	a0,s5
 5ac:	00000097          	auipc	ra,0x0
 5b0:	e14080e7          	jalr	-492(ra) # 3c0 <putc>
  putc(fd, 'x');
 5b4:	85ea                	mv	a1,s10
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	e08080e7          	jalr	-504(ra) # 3c0 <putc>
 5c0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c2:	03c9d793          	srli	a5,s3,0x3c
 5c6:	97de                	add	a5,a5,s7
 5c8:	0007c583          	lbu	a1,0(a5)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	df2080e7          	jalr	-526(ra) # 3c0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d6:	0992                	slli	s3,s3,0x4
 5d8:	397d                	addiw	s2,s2,-1
 5da:	fe0914e3          	bnez	s2,5c2 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5de:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	b721                	j	4ec <vprintf+0x60>
        s = va_arg(ap, char*);
 5e6:	008b0993          	addi	s3,s6,8
 5ea:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5ee:	02090163          	beqz	s2,610 <vprintf+0x184>
        while(*s != 0){
 5f2:	00094583          	lbu	a1,0(s2)
 5f6:	c9a1                	beqz	a1,646 <vprintf+0x1ba>
          putc(fd, *s);
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	dc6080e7          	jalr	-570(ra) # 3c0 <putc>
          s++;
 602:	0905                	addi	s2,s2,1
        while(*s != 0){
 604:	00094583          	lbu	a1,0(s2)
 608:	f9e5                	bnez	a1,5f8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 60a:	8b4e                	mv	s6,s3
      state = 0;
 60c:	4981                	li	s3,0
 60e:	bdf9                	j	4ec <vprintf+0x60>
          s = "(null)";
 610:	00000917          	auipc	s2,0x0
 614:	26890913          	addi	s2,s2,616 # 878 <malloc+0x122>
        while(*s != 0){
 618:	02800593          	li	a1,40
 61c:	bff1                	j	5f8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 61e:	008b0913          	addi	s2,s6,8
 622:	000b4583          	lbu	a1,0(s6)
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	d98080e7          	jalr	-616(ra) # 3c0 <putc>
 630:	8b4a                	mv	s6,s2
      state = 0;
 632:	4981                	li	s3,0
 634:	bd65                	j	4ec <vprintf+0x60>
        putc(fd, c);
 636:	85d2                	mv	a1,s4
 638:	8556                	mv	a0,s5
 63a:	00000097          	auipc	ra,0x0
 63e:	d86080e7          	jalr	-634(ra) # 3c0 <putc>
      state = 0;
 642:	4981                	li	s3,0
 644:	b565                	j	4ec <vprintf+0x60>
        s = va_arg(ap, char*);
 646:	8b4e                	mv	s6,s3
      state = 0;
 648:	4981                	li	s3,0
 64a:	b54d                	j	4ec <vprintf+0x60>
    }
  }
}
 64c:	70e6                	ld	ra,120(sp)
 64e:	7446                	ld	s0,112(sp)
 650:	74a6                	ld	s1,104(sp)
 652:	7906                	ld	s2,96(sp)
 654:	69e6                	ld	s3,88(sp)
 656:	6a46                	ld	s4,80(sp)
 658:	6aa6                	ld	s5,72(sp)
 65a:	6b06                	ld	s6,64(sp)
 65c:	7be2                	ld	s7,56(sp)
 65e:	7c42                	ld	s8,48(sp)
 660:	7ca2                	ld	s9,40(sp)
 662:	7d02                	ld	s10,32(sp)
 664:	6de2                	ld	s11,24(sp)
 666:	6109                	addi	sp,sp,128
 668:	8082                	ret

000000000000066a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 66a:	715d                	addi	sp,sp,-80
 66c:	ec06                	sd	ra,24(sp)
 66e:	e822                	sd	s0,16(sp)
 670:	1000                	addi	s0,sp,32
 672:	e010                	sd	a2,0(s0)
 674:	e414                	sd	a3,8(s0)
 676:	e818                	sd	a4,16(s0)
 678:	ec1c                	sd	a5,24(s0)
 67a:	03043023          	sd	a6,32(s0)
 67e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 682:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 686:	8622                	mv	a2,s0
 688:	00000097          	auipc	ra,0x0
 68c:	e04080e7          	jalr	-508(ra) # 48c <vprintf>
}
 690:	60e2                	ld	ra,24(sp)
 692:	6442                	ld	s0,16(sp)
 694:	6161                	addi	sp,sp,80
 696:	8082                	ret

0000000000000698 <printf>:

void
printf(const char *fmt, ...)
{
 698:	711d                	addi	sp,sp,-96
 69a:	ec06                	sd	ra,24(sp)
 69c:	e822                	sd	s0,16(sp)
 69e:	1000                	addi	s0,sp,32
 6a0:	e40c                	sd	a1,8(s0)
 6a2:	e810                	sd	a2,16(s0)
 6a4:	ec14                	sd	a3,24(s0)
 6a6:	f018                	sd	a4,32(s0)
 6a8:	f41c                	sd	a5,40(s0)
 6aa:	03043823          	sd	a6,48(s0)
 6ae:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6b2:	00840613          	addi	a2,s0,8
 6b6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ba:	85aa                	mv	a1,a0
 6bc:	4505                	li	a0,1
 6be:	00000097          	auipc	ra,0x0
 6c2:	dce080e7          	jalr	-562(ra) # 48c <vprintf>
}
 6c6:	60e2                	ld	ra,24(sp)
 6c8:	6442                	ld	s0,16(sp)
 6ca:	6125                	addi	sp,sp,96
 6cc:	8082                	ret

00000000000006ce <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6ce:	1141                	addi	sp,sp,-16
 6d0:	e422                	sd	s0,8(sp)
 6d2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d8:	00001797          	auipc	a5,0x1
 6dc:	9287b783          	ld	a5,-1752(a5) # 1000 <freep>
 6e0:	a805                	j	710 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6e2:	4618                	lw	a4,8(a2)
 6e4:	9db9                	addw	a1,a1,a4
 6e6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ea:	6398                	ld	a4,0(a5)
 6ec:	6318                	ld	a4,0(a4)
 6ee:	fee53823          	sd	a4,-16(a0)
 6f2:	a091                	j	736 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6f4:	ff852703          	lw	a4,-8(a0)
 6f8:	9e39                	addw	a2,a2,a4
 6fa:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6fc:	ff053703          	ld	a4,-16(a0)
 700:	e398                	sd	a4,0(a5)
 702:	a099                	j	748 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 704:	6398                	ld	a4,0(a5)
 706:	00e7e463          	bltu	a5,a4,70e <free+0x40>
 70a:	00e6ea63          	bltu	a3,a4,71e <free+0x50>
{
 70e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 710:	fed7fae3          	bgeu	a5,a3,704 <free+0x36>
 714:	6398                	ld	a4,0(a5)
 716:	00e6e463          	bltu	a3,a4,71e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71a:	fee7eae3          	bltu	a5,a4,70e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 71e:	ff852583          	lw	a1,-8(a0)
 722:	6390                	ld	a2,0(a5)
 724:	02059713          	slli	a4,a1,0x20
 728:	9301                	srli	a4,a4,0x20
 72a:	0712                	slli	a4,a4,0x4
 72c:	9736                	add	a4,a4,a3
 72e:	fae60ae3          	beq	a2,a4,6e2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 732:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 736:	4790                	lw	a2,8(a5)
 738:	02061713          	slli	a4,a2,0x20
 73c:	9301                	srli	a4,a4,0x20
 73e:	0712                	slli	a4,a4,0x4
 740:	973e                	add	a4,a4,a5
 742:	fae689e3          	beq	a3,a4,6f4 <free+0x26>
  } else
    p->s.ptr = bp;
 746:	e394                	sd	a3,0(a5)
  freep = p;
 748:	00001717          	auipc	a4,0x1
 74c:	8af73c23          	sd	a5,-1864(a4) # 1000 <freep>
}
 750:	6422                	ld	s0,8(sp)
 752:	0141                	addi	sp,sp,16
 754:	8082                	ret

0000000000000756 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 756:	7139                	addi	sp,sp,-64
 758:	fc06                	sd	ra,56(sp)
 75a:	f822                	sd	s0,48(sp)
 75c:	f426                	sd	s1,40(sp)
 75e:	f04a                	sd	s2,32(sp)
 760:	ec4e                	sd	s3,24(sp)
 762:	e852                	sd	s4,16(sp)
 764:	e456                	sd	s5,8(sp)
 766:	e05a                	sd	s6,0(sp)
 768:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 76a:	02051493          	slli	s1,a0,0x20
 76e:	9081                	srli	s1,s1,0x20
 770:	04bd                	addi	s1,s1,15
 772:	8091                	srli	s1,s1,0x4
 774:	0014899b          	addiw	s3,s1,1
 778:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 77a:	00001517          	auipc	a0,0x1
 77e:	88653503          	ld	a0,-1914(a0) # 1000 <freep>
 782:	c515                	beqz	a0,7ae <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 784:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 786:	4798                	lw	a4,8(a5)
 788:	02977f63          	bgeu	a4,s1,7c6 <malloc+0x70>
 78c:	8a4e                	mv	s4,s3
 78e:	0009871b          	sext.w	a4,s3
 792:	6685                	lui	a3,0x1
 794:	00d77363          	bgeu	a4,a3,79a <malloc+0x44>
 798:	6a05                	lui	s4,0x1
 79a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 79e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7a2:	00001917          	auipc	s2,0x1
 7a6:	85e90913          	addi	s2,s2,-1954 # 1000 <freep>
  if(p == (char*)-1)
 7aa:	5afd                	li	s5,-1
 7ac:	a88d                	j	81e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7ae:	00001797          	auipc	a5,0x1
 7b2:	86278793          	addi	a5,a5,-1950 # 1010 <base>
 7b6:	00001717          	auipc	a4,0x1
 7ba:	84f73523          	sd	a5,-1974(a4) # 1000 <freep>
 7be:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7c0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7c4:	b7e1                	j	78c <malloc+0x36>
      if(p->s.size == nunits)
 7c6:	02e48b63          	beq	s1,a4,7fc <malloc+0xa6>
        p->s.size -= nunits;
 7ca:	4137073b          	subw	a4,a4,s3
 7ce:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7d0:	1702                	slli	a4,a4,0x20
 7d2:	9301                	srli	a4,a4,0x20
 7d4:	0712                	slli	a4,a4,0x4
 7d6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7d8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7dc:	00001717          	auipc	a4,0x1
 7e0:	82a73223          	sd	a0,-2012(a4) # 1000 <freep>
      return (void*)(p + 1);
 7e4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e8:	70e2                	ld	ra,56(sp)
 7ea:	7442                	ld	s0,48(sp)
 7ec:	74a2                	ld	s1,40(sp)
 7ee:	7902                	ld	s2,32(sp)
 7f0:	69e2                	ld	s3,24(sp)
 7f2:	6a42                	ld	s4,16(sp)
 7f4:	6aa2                	ld	s5,8(sp)
 7f6:	6b02                	ld	s6,0(sp)
 7f8:	6121                	addi	sp,sp,64
 7fa:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7fc:	6398                	ld	a4,0(a5)
 7fe:	e118                	sd	a4,0(a0)
 800:	bff1                	j	7dc <malloc+0x86>
  hp->s.size = nu;
 802:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 806:	0541                	addi	a0,a0,16
 808:	00000097          	auipc	ra,0x0
 80c:	ec6080e7          	jalr	-314(ra) # 6ce <free>
  return freep;
 810:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 814:	d971                	beqz	a0,7e8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 816:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 818:	4798                	lw	a4,8(a5)
 81a:	fa9776e3          	bgeu	a4,s1,7c6 <malloc+0x70>
    if(p == freep)
 81e:	00093703          	ld	a4,0(s2)
 822:	853e                	mv	a0,a5
 824:	fef719e3          	bne	a4,a5,816 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 828:	8552                	mv	a0,s4
 82a:	00000097          	auipc	ra,0x0
 82e:	b5e080e7          	jalr	-1186(ra) # 388 <sbrk>
  if(p == (char*)-1)
 832:	fd5518e3          	bne	a0,s5,802 <malloc+0xac>
        return 0;
 836:	4501                	li	a0,0
 838:	bf45                	j	7e8 <malloc+0x92>
