
user/_echo:     file format elf64-littleriscv


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
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  int i;

  for(i = 1; i < argc; i++){
  10:	4785                	li	a5,1
  12:	06a7d463          	bge	a5,a0,7a <main+0x7a>
  16:	00858493          	addi	s1,a1,8
  1a:	ffe5099b          	addiw	s3,a0,-2
  1e:	1982                	slli	s3,s3,0x20
  20:	0209d993          	srli	s3,s3,0x20
  24:	098e                	slli	s3,s3,0x3
  26:	05c1                	addi	a1,a1,16
  28:	99ae                	add	s3,s3,a1
    write(1, argv[i], strlen(argv[i]));
    if(i + 1 < argc){
      write(1, " ", 1);
  2a:	00001a17          	auipc	s4,0x1
  2e:	826a0a13          	addi	s4,s4,-2010 # 850 <malloc+0xe6>
    write(1, argv[i], strlen(argv[i]));
  32:	0004b903          	ld	s2,0(s1)
  36:	854a                	mv	a0,s2
  38:	00000097          	auipc	ra,0x0
  3c:	0ae080e7          	jalr	174(ra) # e6 <strlen>
  40:	0005061b          	sext.w	a2,a0
  44:	85ca                	mv	a1,s2
  46:	4505                	li	a0,1
  48:	00000097          	auipc	ra,0x0
  4c:	2e4080e7          	jalr	740(ra) # 32c <write>
    if(i + 1 < argc){
  50:	04a1                	addi	s1,s1,8
  52:	01348a63          	beq	s1,s3,66 <main+0x66>
      write(1, " ", 1);
  56:	4605                	li	a2,1
  58:	85d2                	mv	a1,s4
  5a:	4505                	li	a0,1
  5c:	00000097          	auipc	ra,0x0
  60:	2d0080e7          	jalr	720(ra) # 32c <write>
  for(i = 1; i < argc; i++){
  64:	b7f9                	j	32 <main+0x32>
    } else {
      write(1, "\n", 1);
  66:	4605                	li	a2,1
  68:	00000597          	auipc	a1,0x0
  6c:	7f058593          	addi	a1,a1,2032 # 858 <malloc+0xee>
  70:	4505                	li	a0,1
  72:	00000097          	auipc	ra,0x0
  76:	2ba080e7          	jalr	698(ra) # 32c <write>
    }
  }
  exit(0);
  7a:	4501                	li	a0,0
  7c:	00000097          	auipc	ra,0x0
  80:	290080e7          	jalr	656(ra) # 30c <exit>

0000000000000084 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  84:	1141                	addi	sp,sp,-16
  86:	e406                	sd	ra,8(sp)
  88:	e022                	sd	s0,0(sp)
  8a:	0800                	addi	s0,sp,16
  extern int main();
  main();
  8c:	00000097          	auipc	ra,0x0
  90:	f74080e7          	jalr	-140(ra) # 0 <main>
  exit(0);
  94:	4501                	li	a0,0
  96:	00000097          	auipc	ra,0x0
  9a:	276080e7          	jalr	630(ra) # 30c <exit>

000000000000009e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  9e:	1141                	addi	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  a4:	87aa                	mv	a5,a0
  a6:	0585                	addi	a1,a1,1
  a8:	0785                	addi	a5,a5,1
  aa:	fff5c703          	lbu	a4,-1(a1)
  ae:	fee78fa3          	sb	a4,-1(a5)
  b2:	fb75                	bnez	a4,a6 <strcpy+0x8>
    ;
  return os;
}
  b4:	6422                	ld	s0,8(sp)
  b6:	0141                	addi	sp,sp,16
  b8:	8082                	ret

00000000000000ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
  ba:	1141                	addi	sp,sp,-16
  bc:	e422                	sd	s0,8(sp)
  be:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  c0:	00054783          	lbu	a5,0(a0)
  c4:	cb91                	beqz	a5,d8 <strcmp+0x1e>
  c6:	0005c703          	lbu	a4,0(a1)
  ca:	00f71763          	bne	a4,a5,d8 <strcmp+0x1e>
    p++, q++;
  ce:	0505                	addi	a0,a0,1
  d0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  d2:	00054783          	lbu	a5,0(a0)
  d6:	fbe5                	bnez	a5,c6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  d8:	0005c503          	lbu	a0,0(a1)
}
  dc:	40a7853b          	subw	a0,a5,a0
  e0:	6422                	ld	s0,8(sp)
  e2:	0141                	addi	sp,sp,16
  e4:	8082                	ret

00000000000000e6 <strlen>:

uint
strlen(const char *s)
{
  e6:	1141                	addi	sp,sp,-16
  e8:	e422                	sd	s0,8(sp)
  ea:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ec:	00054783          	lbu	a5,0(a0)
  f0:	cf91                	beqz	a5,10c <strlen+0x26>
  f2:	0505                	addi	a0,a0,1
  f4:	87aa                	mv	a5,a0
  f6:	4685                	li	a3,1
  f8:	9e89                	subw	a3,a3,a0
  fa:	00f6853b          	addw	a0,a3,a5
  fe:	0785                	addi	a5,a5,1
 100:	fff7c703          	lbu	a4,-1(a5)
 104:	fb7d                	bnez	a4,fa <strlen+0x14>
    ;
  return n;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret
  for(n = 0; s[n]; n++)
 10c:	4501                	li	a0,0
 10e:	bfe5                	j	106 <strlen+0x20>

0000000000000110 <memset>:

void*
memset(void *dst, int c, uint n)
{
 110:	1141                	addi	sp,sp,-16
 112:	e422                	sd	s0,8(sp)
 114:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 116:	ca19                	beqz	a2,12c <memset+0x1c>
 118:	87aa                	mv	a5,a0
 11a:	1602                	slli	a2,a2,0x20
 11c:	9201                	srli	a2,a2,0x20
 11e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 122:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 126:	0785                	addi	a5,a5,1
 128:	fee79de3          	bne	a5,a4,122 <memset+0x12>
  }
  return dst;
}
 12c:	6422                	ld	s0,8(sp)
 12e:	0141                	addi	sp,sp,16
 130:	8082                	ret

0000000000000132 <strchr>:

char*
strchr(const char *s, char c)
{
 132:	1141                	addi	sp,sp,-16
 134:	e422                	sd	s0,8(sp)
 136:	0800                	addi	s0,sp,16
  for(; *s; s++)
 138:	00054783          	lbu	a5,0(a0)
 13c:	cb99                	beqz	a5,152 <strchr+0x20>
    if(*s == c)
 13e:	00f58763          	beq	a1,a5,14c <strchr+0x1a>
  for(; *s; s++)
 142:	0505                	addi	a0,a0,1
 144:	00054783          	lbu	a5,0(a0)
 148:	fbfd                	bnez	a5,13e <strchr+0xc>
      return (char*)s;
  return 0;
 14a:	4501                	li	a0,0
}
 14c:	6422                	ld	s0,8(sp)
 14e:	0141                	addi	sp,sp,16
 150:	8082                	ret
  return 0;
 152:	4501                	li	a0,0
 154:	bfe5                	j	14c <strchr+0x1a>

0000000000000156 <gets>:

char*
gets(char *buf, int max)
{
 156:	711d                	addi	sp,sp,-96
 158:	ec86                	sd	ra,88(sp)
 15a:	e8a2                	sd	s0,80(sp)
 15c:	e4a6                	sd	s1,72(sp)
 15e:	e0ca                	sd	s2,64(sp)
 160:	fc4e                	sd	s3,56(sp)
 162:	f852                	sd	s4,48(sp)
 164:	f456                	sd	s5,40(sp)
 166:	f05a                	sd	s6,32(sp)
 168:	ec5e                	sd	s7,24(sp)
 16a:	1080                	addi	s0,sp,96
 16c:	8baa                	mv	s7,a0
 16e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 170:	892a                	mv	s2,a0
 172:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 174:	4aa9                	li	s5,10
 176:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 178:	89a6                	mv	s3,s1
 17a:	2485                	addiw	s1,s1,1
 17c:	0344d863          	bge	s1,s4,1ac <gets+0x56>
    cc = read(0, &c, 1);
 180:	4605                	li	a2,1
 182:	faf40593          	addi	a1,s0,-81
 186:	4501                	li	a0,0
 188:	00000097          	auipc	ra,0x0
 18c:	19c080e7          	jalr	412(ra) # 324 <read>
    if(cc < 1)
 190:	00a05e63          	blez	a0,1ac <gets+0x56>
    buf[i++] = c;
 194:	faf44783          	lbu	a5,-81(s0)
 198:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 19c:	01578763          	beq	a5,s5,1aa <gets+0x54>
 1a0:	0905                	addi	s2,s2,1
 1a2:	fd679be3          	bne	a5,s6,178 <gets+0x22>
  for(i=0; i+1 < max; ){
 1a6:	89a6                	mv	s3,s1
 1a8:	a011                	j	1ac <gets+0x56>
 1aa:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ac:	99de                	add	s3,s3,s7
 1ae:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b2:	855e                	mv	a0,s7
 1b4:	60e6                	ld	ra,88(sp)
 1b6:	6446                	ld	s0,80(sp)
 1b8:	64a6                	ld	s1,72(sp)
 1ba:	6906                	ld	s2,64(sp)
 1bc:	79e2                	ld	s3,56(sp)
 1be:	7a42                	ld	s4,48(sp)
 1c0:	7aa2                	ld	s5,40(sp)
 1c2:	7b02                	ld	s6,32(sp)
 1c4:	6be2                	ld	s7,24(sp)
 1c6:	6125                	addi	sp,sp,96
 1c8:	8082                	ret

00000000000001ca <stat>:

int
stat(const char *n, struct stat *st)
{
 1ca:	1101                	addi	sp,sp,-32
 1cc:	ec06                	sd	ra,24(sp)
 1ce:	e822                	sd	s0,16(sp)
 1d0:	e426                	sd	s1,8(sp)
 1d2:	e04a                	sd	s2,0(sp)
 1d4:	1000                	addi	s0,sp,32
 1d6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1d8:	4581                	li	a1,0
 1da:	00000097          	auipc	ra,0x0
 1de:	172080e7          	jalr	370(ra) # 34c <open>
  if(fd < 0)
 1e2:	02054563          	bltz	a0,20c <stat+0x42>
 1e6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1e8:	85ca                	mv	a1,s2
 1ea:	00000097          	auipc	ra,0x0
 1ee:	17a080e7          	jalr	378(ra) # 364 <fstat>
 1f2:	892a                	mv	s2,a0
  close(fd);
 1f4:	8526                	mv	a0,s1
 1f6:	00000097          	auipc	ra,0x0
 1fa:	13e080e7          	jalr	318(ra) # 334 <close>
  return r;
}
 1fe:	854a                	mv	a0,s2
 200:	60e2                	ld	ra,24(sp)
 202:	6442                	ld	s0,16(sp)
 204:	64a2                	ld	s1,8(sp)
 206:	6902                	ld	s2,0(sp)
 208:	6105                	addi	sp,sp,32
 20a:	8082                	ret
    return -1;
 20c:	597d                	li	s2,-1
 20e:	bfc5                	j	1fe <stat+0x34>

0000000000000210 <atoi>:

int
atoi(const char *s)
{
 210:	1141                	addi	sp,sp,-16
 212:	e422                	sd	s0,8(sp)
 214:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 216:	00054603          	lbu	a2,0(a0)
 21a:	fd06079b          	addiw	a5,a2,-48
 21e:	0ff7f793          	andi	a5,a5,255
 222:	4725                	li	a4,9
 224:	02f76963          	bltu	a4,a5,256 <atoi+0x46>
 228:	86aa                	mv	a3,a0
  n = 0;
 22a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 22c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 22e:	0685                	addi	a3,a3,1
 230:	0025179b          	slliw	a5,a0,0x2
 234:	9fa9                	addw	a5,a5,a0
 236:	0017979b          	slliw	a5,a5,0x1
 23a:	9fb1                	addw	a5,a5,a2
 23c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 240:	0006c603          	lbu	a2,0(a3)
 244:	fd06071b          	addiw	a4,a2,-48
 248:	0ff77713          	andi	a4,a4,255
 24c:	fee5f1e3          	bgeu	a1,a4,22e <atoi+0x1e>
  return n;
}
 250:	6422                	ld	s0,8(sp)
 252:	0141                	addi	sp,sp,16
 254:	8082                	ret
  n = 0;
 256:	4501                	li	a0,0
 258:	bfe5                	j	250 <atoi+0x40>

000000000000025a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 25a:	1141                	addi	sp,sp,-16
 25c:	e422                	sd	s0,8(sp)
 25e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 260:	02b57463          	bgeu	a0,a1,288 <memmove+0x2e>
    while(n-- > 0)
 264:	00c05f63          	blez	a2,282 <memmove+0x28>
 268:	1602                	slli	a2,a2,0x20
 26a:	9201                	srli	a2,a2,0x20
 26c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 270:	872a                	mv	a4,a0
      *dst++ = *src++;
 272:	0585                	addi	a1,a1,1
 274:	0705                	addi	a4,a4,1
 276:	fff5c683          	lbu	a3,-1(a1)
 27a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 27e:	fee79ae3          	bne	a5,a4,272 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret
    dst += n;
 288:	00c50733          	add	a4,a0,a2
    src += n;
 28c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 28e:	fec05ae3          	blez	a2,282 <memmove+0x28>
 292:	fff6079b          	addiw	a5,a2,-1
 296:	1782                	slli	a5,a5,0x20
 298:	9381                	srli	a5,a5,0x20
 29a:	fff7c793          	not	a5,a5
 29e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2a0:	15fd                	addi	a1,a1,-1
 2a2:	177d                	addi	a4,a4,-1
 2a4:	0005c683          	lbu	a3,0(a1)
 2a8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ac:	fee79ae3          	bne	a5,a4,2a0 <memmove+0x46>
 2b0:	bfc9                	j	282 <memmove+0x28>

00000000000002b2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b2:	1141                	addi	sp,sp,-16
 2b4:	e422                	sd	s0,8(sp)
 2b6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2b8:	ca05                	beqz	a2,2e8 <memcmp+0x36>
 2ba:	fff6069b          	addiw	a3,a2,-1
 2be:	1682                	slli	a3,a3,0x20
 2c0:	9281                	srli	a3,a3,0x20
 2c2:	0685                	addi	a3,a3,1
 2c4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2c6:	00054783          	lbu	a5,0(a0)
 2ca:	0005c703          	lbu	a4,0(a1)
 2ce:	00e79863          	bne	a5,a4,2de <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d2:	0505                	addi	a0,a0,1
    p2++;
 2d4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2d6:	fed518e3          	bne	a0,a3,2c6 <memcmp+0x14>
  }
  return 0;
 2da:	4501                	li	a0,0
 2dc:	a019                	j	2e2 <memcmp+0x30>
      return *p1 - *p2;
 2de:	40e7853b          	subw	a0,a5,a4
}
 2e2:	6422                	ld	s0,8(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret
  return 0;
 2e8:	4501                	li	a0,0
 2ea:	bfe5                	j	2e2 <memcmp+0x30>

00000000000002ec <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e406                	sd	ra,8(sp)
 2f0:	e022                	sd	s0,0(sp)
 2f2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2f4:	00000097          	auipc	ra,0x0
 2f8:	f66080e7          	jalr	-154(ra) # 25a <memmove>
}
 2fc:	60a2                	ld	ra,8(sp)
 2fe:	6402                	ld	s0,0(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret

0000000000000304 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 304:	4885                	li	a7,1
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <exit>:
.global exit
exit:
 li a7, SYS_exit
 30c:	4889                	li	a7,2
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <wait>:
.global wait
wait:
 li a7, SYS_wait
 314:	488d                	li	a7,3
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31c:	4891                	li	a7,4
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <read>:
.global read
read:
 li a7, SYS_read
 324:	4895                	li	a7,5
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <write>:
.global write
write:
 li a7, SYS_write
 32c:	48c1                	li	a7,16
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <close>:
.global close
close:
 li a7, SYS_close
 334:	48d5                	li	a7,21
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <kill>:
.global kill
kill:
 li a7, SYS_kill
 33c:	4899                	li	a7,6
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <exec>:
.global exec
exec:
 li a7, SYS_exec
 344:	489d                	li	a7,7
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <open>:
.global open
open:
 li a7, SYS_open
 34c:	48bd                	li	a7,15
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 354:	48c5                	li	a7,17
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35c:	48c9                	li	a7,18
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 364:	48a1                	li	a7,8
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <link>:
.global link
link:
 li a7, SYS_link
 36c:	48cd                	li	a7,19
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 374:	48d1                	li	a7,20
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37c:	48a5                	li	a7,9
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <dup>:
.global dup
dup:
 li a7, SYS_dup
 384:	48a9                	li	a7,10
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38c:	48ad                	li	a7,11
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 394:	48b1                	li	a7,12
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 39c:	48b5                	li	a7,13
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a4:	48b9                	li	a7,14
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <getHelloWorld>:
.global getHelloWorld
getHelloWorld:
 li a7, SYS_getHelloWorld
 3ac:	48d9                	li	a7,22
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <getProcTick>:
.global getProcTick
getProcTick:
 li a7, SYS_getProcTick
 3b4:	48dd                	li	a7,23
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <getProcInfo>:
.global getProcInfo
getProcInfo:
 li a7, SYS_getProcInfo
 3bc:	48e1                	li	a7,24
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 3c4:	48e5                	li	a7,25
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <changeSch>:
.global changeSch
changeSch:
 li a7, SYS_changeSch
 3cc:	48e9                	li	a7,26
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d4:	1101                	addi	sp,sp,-32
 3d6:	ec06                	sd	ra,24(sp)
 3d8:	e822                	sd	s0,16(sp)
 3da:	1000                	addi	s0,sp,32
 3dc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e0:	4605                	li	a2,1
 3e2:	fef40593          	addi	a1,s0,-17
 3e6:	00000097          	auipc	ra,0x0
 3ea:	f46080e7          	jalr	-186(ra) # 32c <write>
}
 3ee:	60e2                	ld	ra,24(sp)
 3f0:	6442                	ld	s0,16(sp)
 3f2:	6105                	addi	sp,sp,32
 3f4:	8082                	ret

00000000000003f6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3f6:	7139                	addi	sp,sp,-64
 3f8:	fc06                	sd	ra,56(sp)
 3fa:	f822                	sd	s0,48(sp)
 3fc:	f426                	sd	s1,40(sp)
 3fe:	f04a                	sd	s2,32(sp)
 400:	ec4e                	sd	s3,24(sp)
 402:	0080                	addi	s0,sp,64
 404:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 406:	c299                	beqz	a3,40c <printint+0x16>
 408:	0805c863          	bltz	a1,498 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 40c:	2581                	sext.w	a1,a1
  neg = 0;
 40e:	4881                	li	a7,0
 410:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 414:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 416:	2601                	sext.w	a2,a2
 418:	00000517          	auipc	a0,0x0
 41c:	45050513          	addi	a0,a0,1104 # 868 <digits>
 420:	883a                	mv	a6,a4
 422:	2705                	addiw	a4,a4,1
 424:	02c5f7bb          	remuw	a5,a1,a2
 428:	1782                	slli	a5,a5,0x20
 42a:	9381                	srli	a5,a5,0x20
 42c:	97aa                	add	a5,a5,a0
 42e:	0007c783          	lbu	a5,0(a5)
 432:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 436:	0005879b          	sext.w	a5,a1
 43a:	02c5d5bb          	divuw	a1,a1,a2
 43e:	0685                	addi	a3,a3,1
 440:	fec7f0e3          	bgeu	a5,a2,420 <printint+0x2a>
  if(neg)
 444:	00088b63          	beqz	a7,45a <printint+0x64>
    buf[i++] = '-';
 448:	fd040793          	addi	a5,s0,-48
 44c:	973e                	add	a4,a4,a5
 44e:	02d00793          	li	a5,45
 452:	fef70823          	sb	a5,-16(a4)
 456:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 45a:	02e05863          	blez	a4,48a <printint+0x94>
 45e:	fc040793          	addi	a5,s0,-64
 462:	00e78933          	add	s2,a5,a4
 466:	fff78993          	addi	s3,a5,-1
 46a:	99ba                	add	s3,s3,a4
 46c:	377d                	addiw	a4,a4,-1
 46e:	1702                	slli	a4,a4,0x20
 470:	9301                	srli	a4,a4,0x20
 472:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 476:	fff94583          	lbu	a1,-1(s2)
 47a:	8526                	mv	a0,s1
 47c:	00000097          	auipc	ra,0x0
 480:	f58080e7          	jalr	-168(ra) # 3d4 <putc>
  while(--i >= 0)
 484:	197d                	addi	s2,s2,-1
 486:	ff3918e3          	bne	s2,s3,476 <printint+0x80>
}
 48a:	70e2                	ld	ra,56(sp)
 48c:	7442                	ld	s0,48(sp)
 48e:	74a2                	ld	s1,40(sp)
 490:	7902                	ld	s2,32(sp)
 492:	69e2                	ld	s3,24(sp)
 494:	6121                	addi	sp,sp,64
 496:	8082                	ret
    x = -xx;
 498:	40b005bb          	negw	a1,a1
    neg = 1;
 49c:	4885                	li	a7,1
    x = -xx;
 49e:	bf8d                	j	410 <printint+0x1a>

00000000000004a0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a0:	7119                	addi	sp,sp,-128
 4a2:	fc86                	sd	ra,120(sp)
 4a4:	f8a2                	sd	s0,112(sp)
 4a6:	f4a6                	sd	s1,104(sp)
 4a8:	f0ca                	sd	s2,96(sp)
 4aa:	ecce                	sd	s3,88(sp)
 4ac:	e8d2                	sd	s4,80(sp)
 4ae:	e4d6                	sd	s5,72(sp)
 4b0:	e0da                	sd	s6,64(sp)
 4b2:	fc5e                	sd	s7,56(sp)
 4b4:	f862                	sd	s8,48(sp)
 4b6:	f466                	sd	s9,40(sp)
 4b8:	f06a                	sd	s10,32(sp)
 4ba:	ec6e                	sd	s11,24(sp)
 4bc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4be:	0005c903          	lbu	s2,0(a1)
 4c2:	18090f63          	beqz	s2,660 <vprintf+0x1c0>
 4c6:	8aaa                	mv	s5,a0
 4c8:	8b32                	mv	s6,a2
 4ca:	00158493          	addi	s1,a1,1
  state = 0;
 4ce:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d0:	02500a13          	li	s4,37
      if(c == 'd'){
 4d4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4d8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4dc:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4e0:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4e4:	00000b97          	auipc	s7,0x0
 4e8:	384b8b93          	addi	s7,s7,900 # 868 <digits>
 4ec:	a839                	j	50a <vprintf+0x6a>
        putc(fd, c);
 4ee:	85ca                	mv	a1,s2
 4f0:	8556                	mv	a0,s5
 4f2:	00000097          	auipc	ra,0x0
 4f6:	ee2080e7          	jalr	-286(ra) # 3d4 <putc>
 4fa:	a019                	j	500 <vprintf+0x60>
    } else if(state == '%'){
 4fc:	01498f63          	beq	s3,s4,51a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 500:	0485                	addi	s1,s1,1
 502:	fff4c903          	lbu	s2,-1(s1)
 506:	14090d63          	beqz	s2,660 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 50a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 50e:	fe0997e3          	bnez	s3,4fc <vprintf+0x5c>
      if(c == '%'){
 512:	fd479ee3          	bne	a5,s4,4ee <vprintf+0x4e>
        state = '%';
 516:	89be                	mv	s3,a5
 518:	b7e5                	j	500 <vprintf+0x60>
      if(c == 'd'){
 51a:	05878063          	beq	a5,s8,55a <vprintf+0xba>
      } else if(c == 'l') {
 51e:	05978c63          	beq	a5,s9,576 <vprintf+0xd6>
      } else if(c == 'x') {
 522:	07a78863          	beq	a5,s10,592 <vprintf+0xf2>
      } else if(c == 'p') {
 526:	09b78463          	beq	a5,s11,5ae <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 52a:	07300713          	li	a4,115
 52e:	0ce78663          	beq	a5,a4,5fa <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 532:	06300713          	li	a4,99
 536:	0ee78e63          	beq	a5,a4,632 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 53a:	11478863          	beq	a5,s4,64a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 53e:	85d2                	mv	a1,s4
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	e92080e7          	jalr	-366(ra) # 3d4 <putc>
        putc(fd, c);
 54a:	85ca                	mv	a1,s2
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e86080e7          	jalr	-378(ra) # 3d4 <putc>
      }
      state = 0;
 556:	4981                	li	s3,0
 558:	b765                	j	500 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 55a:	008b0913          	addi	s2,s6,8
 55e:	4685                	li	a3,1
 560:	4629                	li	a2,10
 562:	000b2583          	lw	a1,0(s6)
 566:	8556                	mv	a0,s5
 568:	00000097          	auipc	ra,0x0
 56c:	e8e080e7          	jalr	-370(ra) # 3f6 <printint>
 570:	8b4a                	mv	s6,s2
      state = 0;
 572:	4981                	li	s3,0
 574:	b771                	j	500 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 576:	008b0913          	addi	s2,s6,8
 57a:	4681                	li	a3,0
 57c:	4629                	li	a2,10
 57e:	000b2583          	lw	a1,0(s6)
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	e72080e7          	jalr	-398(ra) # 3f6 <printint>
 58c:	8b4a                	mv	s6,s2
      state = 0;
 58e:	4981                	li	s3,0
 590:	bf85                	j	500 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 592:	008b0913          	addi	s2,s6,8
 596:	4681                	li	a3,0
 598:	4641                	li	a2,16
 59a:	000b2583          	lw	a1,0(s6)
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e56080e7          	jalr	-426(ra) # 3f6 <printint>
 5a8:	8b4a                	mv	s6,s2
      state = 0;
 5aa:	4981                	li	s3,0
 5ac:	bf91                	j	500 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5ae:	008b0793          	addi	a5,s6,8
 5b2:	f8f43423          	sd	a5,-120(s0)
 5b6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5ba:	03000593          	li	a1,48
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e14080e7          	jalr	-492(ra) # 3d4 <putc>
  putc(fd, 'x');
 5c8:	85ea                	mv	a1,s10
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	e08080e7          	jalr	-504(ra) # 3d4 <putc>
 5d4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5d6:	03c9d793          	srli	a5,s3,0x3c
 5da:	97de                	add	a5,a5,s7
 5dc:	0007c583          	lbu	a1,0(a5)
 5e0:	8556                	mv	a0,s5
 5e2:	00000097          	auipc	ra,0x0
 5e6:	df2080e7          	jalr	-526(ra) # 3d4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ea:	0992                	slli	s3,s3,0x4
 5ec:	397d                	addiw	s2,s2,-1
 5ee:	fe0914e3          	bnez	s2,5d6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5f2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5f6:	4981                	li	s3,0
 5f8:	b721                	j	500 <vprintf+0x60>
        s = va_arg(ap, char*);
 5fa:	008b0993          	addi	s3,s6,8
 5fe:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 602:	02090163          	beqz	s2,624 <vprintf+0x184>
        while(*s != 0){
 606:	00094583          	lbu	a1,0(s2)
 60a:	c9a1                	beqz	a1,65a <vprintf+0x1ba>
          putc(fd, *s);
 60c:	8556                	mv	a0,s5
 60e:	00000097          	auipc	ra,0x0
 612:	dc6080e7          	jalr	-570(ra) # 3d4 <putc>
          s++;
 616:	0905                	addi	s2,s2,1
        while(*s != 0){
 618:	00094583          	lbu	a1,0(s2)
 61c:	f9e5                	bnez	a1,60c <vprintf+0x16c>
        s = va_arg(ap, char*);
 61e:	8b4e                	mv	s6,s3
      state = 0;
 620:	4981                	li	s3,0
 622:	bdf9                	j	500 <vprintf+0x60>
          s = "(null)";
 624:	00000917          	auipc	s2,0x0
 628:	23c90913          	addi	s2,s2,572 # 860 <malloc+0xf6>
        while(*s != 0){
 62c:	02800593          	li	a1,40
 630:	bff1                	j	60c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 632:	008b0913          	addi	s2,s6,8
 636:	000b4583          	lbu	a1,0(s6)
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	d98080e7          	jalr	-616(ra) # 3d4 <putc>
 644:	8b4a                	mv	s6,s2
      state = 0;
 646:	4981                	li	s3,0
 648:	bd65                	j	500 <vprintf+0x60>
        putc(fd, c);
 64a:	85d2                	mv	a1,s4
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	d86080e7          	jalr	-634(ra) # 3d4 <putc>
      state = 0;
 656:	4981                	li	s3,0
 658:	b565                	j	500 <vprintf+0x60>
        s = va_arg(ap, char*);
 65a:	8b4e                	mv	s6,s3
      state = 0;
 65c:	4981                	li	s3,0
 65e:	b54d                	j	500 <vprintf+0x60>
    }
  }
}
 660:	70e6                	ld	ra,120(sp)
 662:	7446                	ld	s0,112(sp)
 664:	74a6                	ld	s1,104(sp)
 666:	7906                	ld	s2,96(sp)
 668:	69e6                	ld	s3,88(sp)
 66a:	6a46                	ld	s4,80(sp)
 66c:	6aa6                	ld	s5,72(sp)
 66e:	6b06                	ld	s6,64(sp)
 670:	7be2                	ld	s7,56(sp)
 672:	7c42                	ld	s8,48(sp)
 674:	7ca2                	ld	s9,40(sp)
 676:	7d02                	ld	s10,32(sp)
 678:	6de2                	ld	s11,24(sp)
 67a:	6109                	addi	sp,sp,128
 67c:	8082                	ret

000000000000067e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 67e:	715d                	addi	sp,sp,-80
 680:	ec06                	sd	ra,24(sp)
 682:	e822                	sd	s0,16(sp)
 684:	1000                	addi	s0,sp,32
 686:	e010                	sd	a2,0(s0)
 688:	e414                	sd	a3,8(s0)
 68a:	e818                	sd	a4,16(s0)
 68c:	ec1c                	sd	a5,24(s0)
 68e:	03043023          	sd	a6,32(s0)
 692:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 696:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 69a:	8622                	mv	a2,s0
 69c:	00000097          	auipc	ra,0x0
 6a0:	e04080e7          	jalr	-508(ra) # 4a0 <vprintf>
}
 6a4:	60e2                	ld	ra,24(sp)
 6a6:	6442                	ld	s0,16(sp)
 6a8:	6161                	addi	sp,sp,80
 6aa:	8082                	ret

00000000000006ac <printf>:

void
printf(const char *fmt, ...)
{
 6ac:	711d                	addi	sp,sp,-96
 6ae:	ec06                	sd	ra,24(sp)
 6b0:	e822                	sd	s0,16(sp)
 6b2:	1000                	addi	s0,sp,32
 6b4:	e40c                	sd	a1,8(s0)
 6b6:	e810                	sd	a2,16(s0)
 6b8:	ec14                	sd	a3,24(s0)
 6ba:	f018                	sd	a4,32(s0)
 6bc:	f41c                	sd	a5,40(s0)
 6be:	03043823          	sd	a6,48(s0)
 6c2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c6:	00840613          	addi	a2,s0,8
 6ca:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ce:	85aa                	mv	a1,a0
 6d0:	4505                	li	a0,1
 6d2:	00000097          	auipc	ra,0x0
 6d6:	dce080e7          	jalr	-562(ra) # 4a0 <vprintf>
}
 6da:	60e2                	ld	ra,24(sp)
 6dc:	6442                	ld	s0,16(sp)
 6de:	6125                	addi	sp,sp,96
 6e0:	8082                	ret

00000000000006e2 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e2:	1141                	addi	sp,sp,-16
 6e4:	e422                	sd	s0,8(sp)
 6e6:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6e8:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ec:	00001797          	auipc	a5,0x1
 6f0:	9147b783          	ld	a5,-1772(a5) # 1000 <freep>
 6f4:	a805                	j	724 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f6:	4618                	lw	a4,8(a2)
 6f8:	9db9                	addw	a1,a1,a4
 6fa:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6fe:	6398                	ld	a4,0(a5)
 700:	6318                	ld	a4,0(a4)
 702:	fee53823          	sd	a4,-16(a0)
 706:	a091                	j	74a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 708:	ff852703          	lw	a4,-8(a0)
 70c:	9e39                	addw	a2,a2,a4
 70e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 710:	ff053703          	ld	a4,-16(a0)
 714:	e398                	sd	a4,0(a5)
 716:	a099                	j	75c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 718:	6398                	ld	a4,0(a5)
 71a:	00e7e463          	bltu	a5,a4,722 <free+0x40>
 71e:	00e6ea63          	bltu	a3,a4,732 <free+0x50>
{
 722:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 724:	fed7fae3          	bgeu	a5,a3,718 <free+0x36>
 728:	6398                	ld	a4,0(a5)
 72a:	00e6e463          	bltu	a3,a4,732 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72e:	fee7eae3          	bltu	a5,a4,722 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 732:	ff852583          	lw	a1,-8(a0)
 736:	6390                	ld	a2,0(a5)
 738:	02059713          	slli	a4,a1,0x20
 73c:	9301                	srli	a4,a4,0x20
 73e:	0712                	slli	a4,a4,0x4
 740:	9736                	add	a4,a4,a3
 742:	fae60ae3          	beq	a2,a4,6f6 <free+0x14>
    bp->s.ptr = p->s.ptr;
 746:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 74a:	4790                	lw	a2,8(a5)
 74c:	02061713          	slli	a4,a2,0x20
 750:	9301                	srli	a4,a4,0x20
 752:	0712                	slli	a4,a4,0x4
 754:	973e                	add	a4,a4,a5
 756:	fae689e3          	beq	a3,a4,708 <free+0x26>
  } else
    p->s.ptr = bp;
 75a:	e394                	sd	a3,0(a5)
  freep = p;
 75c:	00001717          	auipc	a4,0x1
 760:	8af73223          	sd	a5,-1884(a4) # 1000 <freep>
}
 764:	6422                	ld	s0,8(sp)
 766:	0141                	addi	sp,sp,16
 768:	8082                	ret

000000000000076a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 76a:	7139                	addi	sp,sp,-64
 76c:	fc06                	sd	ra,56(sp)
 76e:	f822                	sd	s0,48(sp)
 770:	f426                	sd	s1,40(sp)
 772:	f04a                	sd	s2,32(sp)
 774:	ec4e                	sd	s3,24(sp)
 776:	e852                	sd	s4,16(sp)
 778:	e456                	sd	s5,8(sp)
 77a:	e05a                	sd	s6,0(sp)
 77c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 77e:	02051493          	slli	s1,a0,0x20
 782:	9081                	srli	s1,s1,0x20
 784:	04bd                	addi	s1,s1,15
 786:	8091                	srli	s1,s1,0x4
 788:	0014899b          	addiw	s3,s1,1
 78c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 78e:	00001517          	auipc	a0,0x1
 792:	87253503          	ld	a0,-1934(a0) # 1000 <freep>
 796:	c515                	beqz	a0,7c2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 798:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 79a:	4798                	lw	a4,8(a5)
 79c:	02977f63          	bgeu	a4,s1,7da <malloc+0x70>
 7a0:	8a4e                	mv	s4,s3
 7a2:	0009871b          	sext.w	a4,s3
 7a6:	6685                	lui	a3,0x1
 7a8:	00d77363          	bgeu	a4,a3,7ae <malloc+0x44>
 7ac:	6a05                	lui	s4,0x1
 7ae:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7b2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b6:	00001917          	auipc	s2,0x1
 7ba:	84a90913          	addi	s2,s2,-1974 # 1000 <freep>
  if(p == (char*)-1)
 7be:	5afd                	li	s5,-1
 7c0:	a88d                	j	832 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7c2:	00001797          	auipc	a5,0x1
 7c6:	84e78793          	addi	a5,a5,-1970 # 1010 <base>
 7ca:	00001717          	auipc	a4,0x1
 7ce:	82f73b23          	sd	a5,-1994(a4) # 1000 <freep>
 7d2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d8:	b7e1                	j	7a0 <malloc+0x36>
      if(p->s.size == nunits)
 7da:	02e48b63          	beq	s1,a4,810 <malloc+0xa6>
        p->s.size -= nunits;
 7de:	4137073b          	subw	a4,a4,s3
 7e2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e4:	1702                	slli	a4,a4,0x20
 7e6:	9301                	srli	a4,a4,0x20
 7e8:	0712                	slli	a4,a4,0x4
 7ea:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ec:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7f0:	00001717          	auipc	a4,0x1
 7f4:	80a73823          	sd	a0,-2032(a4) # 1000 <freep>
      return (void*)(p + 1);
 7f8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7fc:	70e2                	ld	ra,56(sp)
 7fe:	7442                	ld	s0,48(sp)
 800:	74a2                	ld	s1,40(sp)
 802:	7902                	ld	s2,32(sp)
 804:	69e2                	ld	s3,24(sp)
 806:	6a42                	ld	s4,16(sp)
 808:	6aa2                	ld	s5,8(sp)
 80a:	6b02                	ld	s6,0(sp)
 80c:	6121                	addi	sp,sp,64
 80e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 810:	6398                	ld	a4,0(a5)
 812:	e118                	sd	a4,0(a0)
 814:	bff1                	j	7f0 <malloc+0x86>
  hp->s.size = nu;
 816:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 81a:	0541                	addi	a0,a0,16
 81c:	00000097          	auipc	ra,0x0
 820:	ec6080e7          	jalr	-314(ra) # 6e2 <free>
  return freep;
 824:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 828:	d971                	beqz	a0,7fc <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82c:	4798                	lw	a4,8(a5)
 82e:	fa9776e3          	bgeu	a4,s1,7da <malloc+0x70>
    if(p == freep)
 832:	00093703          	ld	a4,0(s2)
 836:	853e                	mv	a0,a5
 838:	fef719e3          	bne	a4,a5,82a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 83c:	8552                	mv	a0,s4
 83e:	00000097          	auipc	ra,0x0
 842:	b56080e7          	jalr	-1194(ra) # 394 <sbrk>
  if(p == (char*)-1)
 846:	fd5518e3          	bne	a0,s5,816 <malloc+0xac>
        return 0;
 84a:	4501                	li	a0,0
 84c:	bf45                	j	7fc <malloc+0x92>
