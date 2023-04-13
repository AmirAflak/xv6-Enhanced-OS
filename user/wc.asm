
user/_wc:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <wc>:

char buf[512];

void
wc(int fd, char *name)
{
   0:	7119                	addi	sp,sp,-128
   2:	fc86                	sd	ra,120(sp)
   4:	f8a2                	sd	s0,112(sp)
   6:	f4a6                	sd	s1,104(sp)
   8:	f0ca                	sd	s2,96(sp)
   a:	ecce                	sd	s3,88(sp)
   c:	e8d2                	sd	s4,80(sp)
   e:	e4d6                	sd	s5,72(sp)
  10:	e0da                	sd	s6,64(sp)
  12:	fc5e                	sd	s7,56(sp)
  14:	f862                	sd	s8,48(sp)
  16:	f466                	sd	s9,40(sp)
  18:	f06a                	sd	s10,32(sp)
  1a:	ec6e                	sd	s11,24(sp)
  1c:	0100                	addi	s0,sp,128
  1e:	f8a43423          	sd	a0,-120(s0)
  22:	f8b43023          	sd	a1,-128(s0)
  int i, n;
  int l, w, c, inword;

  l = w = c = 0;
  inword = 0;
  26:	4981                	li	s3,0
  l = w = c = 0;
  28:	4c81                	li	s9,0
  2a:	4c01                	li	s8,0
  2c:	4b81                	li	s7,0
  2e:	00001d97          	auipc	s11,0x1
  32:	fe3d8d93          	addi	s11,s11,-29 # 1011 <buf+0x1>
  while((n = read(fd, buf, sizeof(buf))) > 0){
    for(i=0; i<n; i++){
      c++;
      if(buf[i] == '\n')
  36:	4aa9                	li	s5,10
        l++;
      if(strchr(" \r\t\n\v", buf[i]))
  38:	00001a17          	auipc	s4,0x1
  3c:	928a0a13          	addi	s4,s4,-1752 # 960 <malloc+0xec>
        inword = 0;
  40:	4b01                	li	s6,0
  while((n = read(fd, buf, sizeof(buf))) > 0){
  42:	a805                	j	72 <wc+0x72>
      if(strchr(" \r\t\n\v", buf[i]))
  44:	8552                	mv	a0,s4
  46:	00000097          	auipc	ra,0x0
  4a:	1fe080e7          	jalr	510(ra) # 244 <strchr>
  4e:	c919                	beqz	a0,64 <wc+0x64>
        inword = 0;
  50:	89da                	mv	s3,s6
    for(i=0; i<n; i++){
  52:	0485                	addi	s1,s1,1
  54:	01248d63          	beq	s1,s2,6e <wc+0x6e>
      if(buf[i] == '\n')
  58:	0004c583          	lbu	a1,0(s1)
  5c:	ff5594e3          	bne	a1,s5,44 <wc+0x44>
        l++;
  60:	2b85                	addiw	s7,s7,1
  62:	b7cd                	j	44 <wc+0x44>
      else if(!inword){
  64:	fe0997e3          	bnez	s3,52 <wc+0x52>
        w++;
  68:	2c05                	addiw	s8,s8,1
        inword = 1;
  6a:	4985                	li	s3,1
  6c:	b7dd                	j	52 <wc+0x52>
      c++;
  6e:	01ac8cbb          	addw	s9,s9,s10
  while((n = read(fd, buf, sizeof(buf))) > 0){
  72:	20000613          	li	a2,512
  76:	00001597          	auipc	a1,0x1
  7a:	f9a58593          	addi	a1,a1,-102 # 1010 <buf>
  7e:	f8843503          	ld	a0,-120(s0)
  82:	00000097          	auipc	ra,0x0
  86:	3b4080e7          	jalr	948(ra) # 436 <read>
  8a:	00a05f63          	blez	a0,a8 <wc+0xa8>
    for(i=0; i<n; i++){
  8e:	00001497          	auipc	s1,0x1
  92:	f8248493          	addi	s1,s1,-126 # 1010 <buf>
  96:	00050d1b          	sext.w	s10,a0
  9a:	fff5091b          	addiw	s2,a0,-1
  9e:	1902                	slli	s2,s2,0x20
  a0:	02095913          	srli	s2,s2,0x20
  a4:	996e                	add	s2,s2,s11
  a6:	bf4d                	j	58 <wc+0x58>
      }
    }
  }
  if(n < 0){
  a8:	02054e63          	bltz	a0,e4 <wc+0xe4>
    printf("wc: read error\n");
    exit(1);
  }
  printf("%d %d %d %s\n", l, w, c, name);
  ac:	f8043703          	ld	a4,-128(s0)
  b0:	86e6                	mv	a3,s9
  b2:	8662                	mv	a2,s8
  b4:	85de                	mv	a1,s7
  b6:	00001517          	auipc	a0,0x1
  ba:	8c250513          	addi	a0,a0,-1854 # 978 <malloc+0x104>
  be:	00000097          	auipc	ra,0x0
  c2:	6f8080e7          	jalr	1784(ra) # 7b6 <printf>
}
  c6:	70e6                	ld	ra,120(sp)
  c8:	7446                	ld	s0,112(sp)
  ca:	74a6                	ld	s1,104(sp)
  cc:	7906                	ld	s2,96(sp)
  ce:	69e6                	ld	s3,88(sp)
  d0:	6a46                	ld	s4,80(sp)
  d2:	6aa6                	ld	s5,72(sp)
  d4:	6b06                	ld	s6,64(sp)
  d6:	7be2                	ld	s7,56(sp)
  d8:	7c42                	ld	s8,48(sp)
  da:	7ca2                	ld	s9,40(sp)
  dc:	7d02                	ld	s10,32(sp)
  de:	6de2                	ld	s11,24(sp)
  e0:	6109                	addi	sp,sp,128
  e2:	8082                	ret
    printf("wc: read error\n");
  e4:	00001517          	auipc	a0,0x1
  e8:	88450513          	addi	a0,a0,-1916 # 968 <malloc+0xf4>
  ec:	00000097          	auipc	ra,0x0
  f0:	6ca080e7          	jalr	1738(ra) # 7b6 <printf>
    exit(1);
  f4:	4505                	li	a0,1
  f6:	00000097          	auipc	ra,0x0
  fa:	328080e7          	jalr	808(ra) # 41e <exit>

00000000000000fe <main>:

int
main(int argc, char *argv[])
{
  fe:	7179                	addi	sp,sp,-48
 100:	f406                	sd	ra,40(sp)
 102:	f022                	sd	s0,32(sp)
 104:	ec26                	sd	s1,24(sp)
 106:	e84a                	sd	s2,16(sp)
 108:	e44e                	sd	s3,8(sp)
 10a:	e052                	sd	s4,0(sp)
 10c:	1800                	addi	s0,sp,48
  int fd, i;

  if(argc <= 1){
 10e:	4785                	li	a5,1
 110:	04a7d763          	bge	a5,a0,15e <main+0x60>
 114:	00858493          	addi	s1,a1,8
 118:	ffe5099b          	addiw	s3,a0,-2
 11c:	1982                	slli	s3,s3,0x20
 11e:	0209d993          	srli	s3,s3,0x20
 122:	098e                	slli	s3,s3,0x3
 124:	05c1                	addi	a1,a1,16
 126:	99ae                	add	s3,s3,a1
    wc(0, "");
    exit(0);
  }

  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
 128:	4581                	li	a1,0
 12a:	6088                	ld	a0,0(s1)
 12c:	00000097          	auipc	ra,0x0
 130:	332080e7          	jalr	818(ra) # 45e <open>
 134:	892a                	mv	s2,a0
 136:	04054263          	bltz	a0,17a <main+0x7c>
      printf("wc: cannot open %s\n", argv[i]);
      exit(1);
    }
    wc(fd, argv[i]);
 13a:	608c                	ld	a1,0(s1)
 13c:	00000097          	auipc	ra,0x0
 140:	ec4080e7          	jalr	-316(ra) # 0 <wc>
    close(fd);
 144:	854a                	mv	a0,s2
 146:	00000097          	auipc	ra,0x0
 14a:	300080e7          	jalr	768(ra) # 446 <close>
  for(i = 1; i < argc; i++){
 14e:	04a1                	addi	s1,s1,8
 150:	fd349ce3          	bne	s1,s3,128 <main+0x2a>
  }
  exit(0);
 154:	4501                	li	a0,0
 156:	00000097          	auipc	ra,0x0
 15a:	2c8080e7          	jalr	712(ra) # 41e <exit>
    wc(0, "");
 15e:	00001597          	auipc	a1,0x1
 162:	82a58593          	addi	a1,a1,-2006 # 988 <malloc+0x114>
 166:	4501                	li	a0,0
 168:	00000097          	auipc	ra,0x0
 16c:	e98080e7          	jalr	-360(ra) # 0 <wc>
    exit(0);
 170:	4501                	li	a0,0
 172:	00000097          	auipc	ra,0x0
 176:	2ac080e7          	jalr	684(ra) # 41e <exit>
      printf("wc: cannot open %s\n", argv[i]);
 17a:	608c                	ld	a1,0(s1)
 17c:	00001517          	auipc	a0,0x1
 180:	81450513          	addi	a0,a0,-2028 # 990 <malloc+0x11c>
 184:	00000097          	auipc	ra,0x0
 188:	632080e7          	jalr	1586(ra) # 7b6 <printf>
      exit(1);
 18c:	4505                	li	a0,1
 18e:	00000097          	auipc	ra,0x0
 192:	290080e7          	jalr	656(ra) # 41e <exit>

0000000000000196 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 196:	1141                	addi	sp,sp,-16
 198:	e406                	sd	ra,8(sp)
 19a:	e022                	sd	s0,0(sp)
 19c:	0800                	addi	s0,sp,16
  extern int main();
  main();
 19e:	00000097          	auipc	ra,0x0
 1a2:	f60080e7          	jalr	-160(ra) # fe <main>
  exit(0);
 1a6:	4501                	li	a0,0
 1a8:	00000097          	auipc	ra,0x0
 1ac:	276080e7          	jalr	630(ra) # 41e <exit>

00000000000001b0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 1b0:	1141                	addi	sp,sp,-16
 1b2:	e422                	sd	s0,8(sp)
 1b4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1b6:	87aa                	mv	a5,a0
 1b8:	0585                	addi	a1,a1,1
 1ba:	0785                	addi	a5,a5,1
 1bc:	fff5c703          	lbu	a4,-1(a1)
 1c0:	fee78fa3          	sb	a4,-1(a5)
 1c4:	fb75                	bnez	a4,1b8 <strcpy+0x8>
    ;
  return os;
}
 1c6:	6422                	ld	s0,8(sp)
 1c8:	0141                	addi	sp,sp,16
 1ca:	8082                	ret

00000000000001cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1cc:	1141                	addi	sp,sp,-16
 1ce:	e422                	sd	s0,8(sp)
 1d0:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1d2:	00054783          	lbu	a5,0(a0)
 1d6:	cb91                	beqz	a5,1ea <strcmp+0x1e>
 1d8:	0005c703          	lbu	a4,0(a1)
 1dc:	00f71763          	bne	a4,a5,1ea <strcmp+0x1e>
    p++, q++;
 1e0:	0505                	addi	a0,a0,1
 1e2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1e4:	00054783          	lbu	a5,0(a0)
 1e8:	fbe5                	bnez	a5,1d8 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1ea:	0005c503          	lbu	a0,0(a1)
}
 1ee:	40a7853b          	subw	a0,a5,a0
 1f2:	6422                	ld	s0,8(sp)
 1f4:	0141                	addi	sp,sp,16
 1f6:	8082                	ret

00000000000001f8 <strlen>:

uint
strlen(const char *s)
{
 1f8:	1141                	addi	sp,sp,-16
 1fa:	e422                	sd	s0,8(sp)
 1fc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1fe:	00054783          	lbu	a5,0(a0)
 202:	cf91                	beqz	a5,21e <strlen+0x26>
 204:	0505                	addi	a0,a0,1
 206:	87aa                	mv	a5,a0
 208:	4685                	li	a3,1
 20a:	9e89                	subw	a3,a3,a0
 20c:	00f6853b          	addw	a0,a3,a5
 210:	0785                	addi	a5,a5,1
 212:	fff7c703          	lbu	a4,-1(a5)
 216:	fb7d                	bnez	a4,20c <strlen+0x14>
    ;
  return n;
}
 218:	6422                	ld	s0,8(sp)
 21a:	0141                	addi	sp,sp,16
 21c:	8082                	ret
  for(n = 0; s[n]; n++)
 21e:	4501                	li	a0,0
 220:	bfe5                	j	218 <strlen+0x20>

0000000000000222 <memset>:

void*
memset(void *dst, int c, uint n)
{
 222:	1141                	addi	sp,sp,-16
 224:	e422                	sd	s0,8(sp)
 226:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 228:	ca19                	beqz	a2,23e <memset+0x1c>
 22a:	87aa                	mv	a5,a0
 22c:	1602                	slli	a2,a2,0x20
 22e:	9201                	srli	a2,a2,0x20
 230:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 234:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 238:	0785                	addi	a5,a5,1
 23a:	fee79de3          	bne	a5,a4,234 <memset+0x12>
  }
  return dst;
}
 23e:	6422                	ld	s0,8(sp)
 240:	0141                	addi	sp,sp,16
 242:	8082                	ret

0000000000000244 <strchr>:

char*
strchr(const char *s, char c)
{
 244:	1141                	addi	sp,sp,-16
 246:	e422                	sd	s0,8(sp)
 248:	0800                	addi	s0,sp,16
  for(; *s; s++)
 24a:	00054783          	lbu	a5,0(a0)
 24e:	cb99                	beqz	a5,264 <strchr+0x20>
    if(*s == c)
 250:	00f58763          	beq	a1,a5,25e <strchr+0x1a>
  for(; *s; s++)
 254:	0505                	addi	a0,a0,1
 256:	00054783          	lbu	a5,0(a0)
 25a:	fbfd                	bnez	a5,250 <strchr+0xc>
      return (char*)s;
  return 0;
 25c:	4501                	li	a0,0
}
 25e:	6422                	ld	s0,8(sp)
 260:	0141                	addi	sp,sp,16
 262:	8082                	ret
  return 0;
 264:	4501                	li	a0,0
 266:	bfe5                	j	25e <strchr+0x1a>

0000000000000268 <gets>:

char*
gets(char *buf, int max)
{
 268:	711d                	addi	sp,sp,-96
 26a:	ec86                	sd	ra,88(sp)
 26c:	e8a2                	sd	s0,80(sp)
 26e:	e4a6                	sd	s1,72(sp)
 270:	e0ca                	sd	s2,64(sp)
 272:	fc4e                	sd	s3,56(sp)
 274:	f852                	sd	s4,48(sp)
 276:	f456                	sd	s5,40(sp)
 278:	f05a                	sd	s6,32(sp)
 27a:	ec5e                	sd	s7,24(sp)
 27c:	1080                	addi	s0,sp,96
 27e:	8baa                	mv	s7,a0
 280:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 282:	892a                	mv	s2,a0
 284:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 286:	4aa9                	li	s5,10
 288:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 28a:	89a6                	mv	s3,s1
 28c:	2485                	addiw	s1,s1,1
 28e:	0344d863          	bge	s1,s4,2be <gets+0x56>
    cc = read(0, &c, 1);
 292:	4605                	li	a2,1
 294:	faf40593          	addi	a1,s0,-81
 298:	4501                	li	a0,0
 29a:	00000097          	auipc	ra,0x0
 29e:	19c080e7          	jalr	412(ra) # 436 <read>
    if(cc < 1)
 2a2:	00a05e63          	blez	a0,2be <gets+0x56>
    buf[i++] = c;
 2a6:	faf44783          	lbu	a5,-81(s0)
 2aa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2ae:	01578763          	beq	a5,s5,2bc <gets+0x54>
 2b2:	0905                	addi	s2,s2,1
 2b4:	fd679be3          	bne	a5,s6,28a <gets+0x22>
  for(i=0; i+1 < max; ){
 2b8:	89a6                	mv	s3,s1
 2ba:	a011                	j	2be <gets+0x56>
 2bc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2be:	99de                	add	s3,s3,s7
 2c0:	00098023          	sb	zero,0(s3)
  return buf;
}
 2c4:	855e                	mv	a0,s7
 2c6:	60e6                	ld	ra,88(sp)
 2c8:	6446                	ld	s0,80(sp)
 2ca:	64a6                	ld	s1,72(sp)
 2cc:	6906                	ld	s2,64(sp)
 2ce:	79e2                	ld	s3,56(sp)
 2d0:	7a42                	ld	s4,48(sp)
 2d2:	7aa2                	ld	s5,40(sp)
 2d4:	7b02                	ld	s6,32(sp)
 2d6:	6be2                	ld	s7,24(sp)
 2d8:	6125                	addi	sp,sp,96
 2da:	8082                	ret

00000000000002dc <stat>:

int
stat(const char *n, struct stat *st)
{
 2dc:	1101                	addi	sp,sp,-32
 2de:	ec06                	sd	ra,24(sp)
 2e0:	e822                	sd	s0,16(sp)
 2e2:	e426                	sd	s1,8(sp)
 2e4:	e04a                	sd	s2,0(sp)
 2e6:	1000                	addi	s0,sp,32
 2e8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2ea:	4581                	li	a1,0
 2ec:	00000097          	auipc	ra,0x0
 2f0:	172080e7          	jalr	370(ra) # 45e <open>
  if(fd < 0)
 2f4:	02054563          	bltz	a0,31e <stat+0x42>
 2f8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2fa:	85ca                	mv	a1,s2
 2fc:	00000097          	auipc	ra,0x0
 300:	17a080e7          	jalr	378(ra) # 476 <fstat>
 304:	892a                	mv	s2,a0
  close(fd);
 306:	8526                	mv	a0,s1
 308:	00000097          	auipc	ra,0x0
 30c:	13e080e7          	jalr	318(ra) # 446 <close>
  return r;
}
 310:	854a                	mv	a0,s2
 312:	60e2                	ld	ra,24(sp)
 314:	6442                	ld	s0,16(sp)
 316:	64a2                	ld	s1,8(sp)
 318:	6902                	ld	s2,0(sp)
 31a:	6105                	addi	sp,sp,32
 31c:	8082                	ret
    return -1;
 31e:	597d                	li	s2,-1
 320:	bfc5                	j	310 <stat+0x34>

0000000000000322 <atoi>:

int
atoi(const char *s)
{
 322:	1141                	addi	sp,sp,-16
 324:	e422                	sd	s0,8(sp)
 326:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 328:	00054603          	lbu	a2,0(a0)
 32c:	fd06079b          	addiw	a5,a2,-48
 330:	0ff7f793          	andi	a5,a5,255
 334:	4725                	li	a4,9
 336:	02f76963          	bltu	a4,a5,368 <atoi+0x46>
 33a:	86aa                	mv	a3,a0
  n = 0;
 33c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 33e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 340:	0685                	addi	a3,a3,1
 342:	0025179b          	slliw	a5,a0,0x2
 346:	9fa9                	addw	a5,a5,a0
 348:	0017979b          	slliw	a5,a5,0x1
 34c:	9fb1                	addw	a5,a5,a2
 34e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 352:	0006c603          	lbu	a2,0(a3)
 356:	fd06071b          	addiw	a4,a2,-48
 35a:	0ff77713          	andi	a4,a4,255
 35e:	fee5f1e3          	bgeu	a1,a4,340 <atoi+0x1e>
  return n;
}
 362:	6422                	ld	s0,8(sp)
 364:	0141                	addi	sp,sp,16
 366:	8082                	ret
  n = 0;
 368:	4501                	li	a0,0
 36a:	bfe5                	j	362 <atoi+0x40>

000000000000036c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 372:	02b57463          	bgeu	a0,a1,39a <memmove+0x2e>
    while(n-- > 0)
 376:	00c05f63          	blez	a2,394 <memmove+0x28>
 37a:	1602                	slli	a2,a2,0x20
 37c:	9201                	srli	a2,a2,0x20
 37e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 382:	872a                	mv	a4,a0
      *dst++ = *src++;
 384:	0585                	addi	a1,a1,1
 386:	0705                	addi	a4,a4,1
 388:	fff5c683          	lbu	a3,-1(a1)
 38c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 390:	fee79ae3          	bne	a5,a4,384 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 394:	6422                	ld	s0,8(sp)
 396:	0141                	addi	sp,sp,16
 398:	8082                	ret
    dst += n;
 39a:	00c50733          	add	a4,a0,a2
    src += n;
 39e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3a0:	fec05ae3          	blez	a2,394 <memmove+0x28>
 3a4:	fff6079b          	addiw	a5,a2,-1
 3a8:	1782                	slli	a5,a5,0x20
 3aa:	9381                	srli	a5,a5,0x20
 3ac:	fff7c793          	not	a5,a5
 3b0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3b2:	15fd                	addi	a1,a1,-1
 3b4:	177d                	addi	a4,a4,-1
 3b6:	0005c683          	lbu	a3,0(a1)
 3ba:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3be:	fee79ae3          	bne	a5,a4,3b2 <memmove+0x46>
 3c2:	bfc9                	j	394 <memmove+0x28>

00000000000003c4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3c4:	1141                	addi	sp,sp,-16
 3c6:	e422                	sd	s0,8(sp)
 3c8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3ca:	ca05                	beqz	a2,3fa <memcmp+0x36>
 3cc:	fff6069b          	addiw	a3,a2,-1
 3d0:	1682                	slli	a3,a3,0x20
 3d2:	9281                	srli	a3,a3,0x20
 3d4:	0685                	addi	a3,a3,1
 3d6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3d8:	00054783          	lbu	a5,0(a0)
 3dc:	0005c703          	lbu	a4,0(a1)
 3e0:	00e79863          	bne	a5,a4,3f0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3e4:	0505                	addi	a0,a0,1
    p2++;
 3e6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3e8:	fed518e3          	bne	a0,a3,3d8 <memcmp+0x14>
  }
  return 0;
 3ec:	4501                	li	a0,0
 3ee:	a019                	j	3f4 <memcmp+0x30>
      return *p1 - *p2;
 3f0:	40e7853b          	subw	a0,a5,a4
}
 3f4:	6422                	ld	s0,8(sp)
 3f6:	0141                	addi	sp,sp,16
 3f8:	8082                	ret
  return 0;
 3fa:	4501                	li	a0,0
 3fc:	bfe5                	j	3f4 <memcmp+0x30>

00000000000003fe <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3fe:	1141                	addi	sp,sp,-16
 400:	e406                	sd	ra,8(sp)
 402:	e022                	sd	s0,0(sp)
 404:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 406:	00000097          	auipc	ra,0x0
 40a:	f66080e7          	jalr	-154(ra) # 36c <memmove>
}
 40e:	60a2                	ld	ra,8(sp)
 410:	6402                	ld	s0,0(sp)
 412:	0141                	addi	sp,sp,16
 414:	8082                	ret

0000000000000416 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 416:	4885                	li	a7,1
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <exit>:
.global exit
exit:
 li a7, SYS_exit
 41e:	4889                	li	a7,2
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <wait>:
.global wait
wait:
 li a7, SYS_wait
 426:	488d                	li	a7,3
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 42e:	4891                	li	a7,4
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <read>:
.global read
read:
 li a7, SYS_read
 436:	4895                	li	a7,5
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <write>:
.global write
write:
 li a7, SYS_write
 43e:	48c1                	li	a7,16
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <close>:
.global close
close:
 li a7, SYS_close
 446:	48d5                	li	a7,21
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <kill>:
.global kill
kill:
 li a7, SYS_kill
 44e:	4899                	li	a7,6
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <exec>:
.global exec
exec:
 li a7, SYS_exec
 456:	489d                	li	a7,7
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <open>:
.global open
open:
 li a7, SYS_open
 45e:	48bd                	li	a7,15
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 466:	48c5                	li	a7,17
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 46e:	48c9                	li	a7,18
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 476:	48a1                	li	a7,8
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <link>:
.global link
link:
 li a7, SYS_link
 47e:	48cd                	li	a7,19
 ecall
 480:	00000073          	ecall
 ret
 484:	8082                	ret

0000000000000486 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 486:	48d1                	li	a7,20
 ecall
 488:	00000073          	ecall
 ret
 48c:	8082                	ret

000000000000048e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 48e:	48a5                	li	a7,9
 ecall
 490:	00000073          	ecall
 ret
 494:	8082                	ret

0000000000000496 <dup>:
.global dup
dup:
 li a7, SYS_dup
 496:	48a9                	li	a7,10
 ecall
 498:	00000073          	ecall
 ret
 49c:	8082                	ret

000000000000049e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 49e:	48ad                	li	a7,11
 ecall
 4a0:	00000073          	ecall
 ret
 4a4:	8082                	ret

00000000000004a6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4a6:	48b1                	li	a7,12
 ecall
 4a8:	00000073          	ecall
 ret
 4ac:	8082                	ret

00000000000004ae <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4ae:	48b5                	li	a7,13
 ecall
 4b0:	00000073          	ecall
 ret
 4b4:	8082                	ret

00000000000004b6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4b6:	48b9                	li	a7,14
 ecall
 4b8:	00000073          	ecall
 ret
 4bc:	8082                	ret

00000000000004be <getHelloWorld>:
.global getHelloWorld
getHelloWorld:
 li a7, SYS_getHelloWorld
 4be:	48d9                	li	a7,22
 ecall
 4c0:	00000073          	ecall
 ret
 4c4:	8082                	ret

00000000000004c6 <getProcTick>:
.global getProcTick
getProcTick:
 li a7, SYS_getProcTick
 4c6:	48dd                	li	a7,23
 ecall
 4c8:	00000073          	ecall
 ret
 4cc:	8082                	ret

00000000000004ce <getProcInfo>:
.global getProcInfo
getProcInfo:
 li a7, SYS_getProcInfo
 4ce:	48e1                	li	a7,24
 ecall
 4d0:	00000073          	ecall
 ret
 4d4:	8082                	ret

00000000000004d6 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 4d6:	48e5                	li	a7,25
 ecall
 4d8:	00000073          	ecall
 ret
 4dc:	8082                	ret

00000000000004de <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4de:	1101                	addi	sp,sp,-32
 4e0:	ec06                	sd	ra,24(sp)
 4e2:	e822                	sd	s0,16(sp)
 4e4:	1000                	addi	s0,sp,32
 4e6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4ea:	4605                	li	a2,1
 4ec:	fef40593          	addi	a1,s0,-17
 4f0:	00000097          	auipc	ra,0x0
 4f4:	f4e080e7          	jalr	-178(ra) # 43e <write>
}
 4f8:	60e2                	ld	ra,24(sp)
 4fa:	6442                	ld	s0,16(sp)
 4fc:	6105                	addi	sp,sp,32
 4fe:	8082                	ret

0000000000000500 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 500:	7139                	addi	sp,sp,-64
 502:	fc06                	sd	ra,56(sp)
 504:	f822                	sd	s0,48(sp)
 506:	f426                	sd	s1,40(sp)
 508:	f04a                	sd	s2,32(sp)
 50a:	ec4e                	sd	s3,24(sp)
 50c:	0080                	addi	s0,sp,64
 50e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 510:	c299                	beqz	a3,516 <printint+0x16>
 512:	0805c863          	bltz	a1,5a2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 516:	2581                	sext.w	a1,a1
  neg = 0;
 518:	4881                	li	a7,0
 51a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 51e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 520:	2601                	sext.w	a2,a2
 522:	00000517          	auipc	a0,0x0
 526:	48e50513          	addi	a0,a0,1166 # 9b0 <digits>
 52a:	883a                	mv	a6,a4
 52c:	2705                	addiw	a4,a4,1
 52e:	02c5f7bb          	remuw	a5,a1,a2
 532:	1782                	slli	a5,a5,0x20
 534:	9381                	srli	a5,a5,0x20
 536:	97aa                	add	a5,a5,a0
 538:	0007c783          	lbu	a5,0(a5)
 53c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 540:	0005879b          	sext.w	a5,a1
 544:	02c5d5bb          	divuw	a1,a1,a2
 548:	0685                	addi	a3,a3,1
 54a:	fec7f0e3          	bgeu	a5,a2,52a <printint+0x2a>
  if(neg)
 54e:	00088b63          	beqz	a7,564 <printint+0x64>
    buf[i++] = '-';
 552:	fd040793          	addi	a5,s0,-48
 556:	973e                	add	a4,a4,a5
 558:	02d00793          	li	a5,45
 55c:	fef70823          	sb	a5,-16(a4)
 560:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 564:	02e05863          	blez	a4,594 <printint+0x94>
 568:	fc040793          	addi	a5,s0,-64
 56c:	00e78933          	add	s2,a5,a4
 570:	fff78993          	addi	s3,a5,-1
 574:	99ba                	add	s3,s3,a4
 576:	377d                	addiw	a4,a4,-1
 578:	1702                	slli	a4,a4,0x20
 57a:	9301                	srli	a4,a4,0x20
 57c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 580:	fff94583          	lbu	a1,-1(s2)
 584:	8526                	mv	a0,s1
 586:	00000097          	auipc	ra,0x0
 58a:	f58080e7          	jalr	-168(ra) # 4de <putc>
  while(--i >= 0)
 58e:	197d                	addi	s2,s2,-1
 590:	ff3918e3          	bne	s2,s3,580 <printint+0x80>
}
 594:	70e2                	ld	ra,56(sp)
 596:	7442                	ld	s0,48(sp)
 598:	74a2                	ld	s1,40(sp)
 59a:	7902                	ld	s2,32(sp)
 59c:	69e2                	ld	s3,24(sp)
 59e:	6121                	addi	sp,sp,64
 5a0:	8082                	ret
    x = -xx;
 5a2:	40b005bb          	negw	a1,a1
    neg = 1;
 5a6:	4885                	li	a7,1
    x = -xx;
 5a8:	bf8d                	j	51a <printint+0x1a>

00000000000005aa <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5aa:	7119                	addi	sp,sp,-128
 5ac:	fc86                	sd	ra,120(sp)
 5ae:	f8a2                	sd	s0,112(sp)
 5b0:	f4a6                	sd	s1,104(sp)
 5b2:	f0ca                	sd	s2,96(sp)
 5b4:	ecce                	sd	s3,88(sp)
 5b6:	e8d2                	sd	s4,80(sp)
 5b8:	e4d6                	sd	s5,72(sp)
 5ba:	e0da                	sd	s6,64(sp)
 5bc:	fc5e                	sd	s7,56(sp)
 5be:	f862                	sd	s8,48(sp)
 5c0:	f466                	sd	s9,40(sp)
 5c2:	f06a                	sd	s10,32(sp)
 5c4:	ec6e                	sd	s11,24(sp)
 5c6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5c8:	0005c903          	lbu	s2,0(a1)
 5cc:	18090f63          	beqz	s2,76a <vprintf+0x1c0>
 5d0:	8aaa                	mv	s5,a0
 5d2:	8b32                	mv	s6,a2
 5d4:	00158493          	addi	s1,a1,1
  state = 0;
 5d8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5da:	02500a13          	li	s4,37
      if(c == 'd'){
 5de:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5e2:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5e6:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5ea:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ee:	00000b97          	auipc	s7,0x0
 5f2:	3c2b8b93          	addi	s7,s7,962 # 9b0 <digits>
 5f6:	a839                	j	614 <vprintf+0x6a>
        putc(fd, c);
 5f8:	85ca                	mv	a1,s2
 5fa:	8556                	mv	a0,s5
 5fc:	00000097          	auipc	ra,0x0
 600:	ee2080e7          	jalr	-286(ra) # 4de <putc>
 604:	a019                	j	60a <vprintf+0x60>
    } else if(state == '%'){
 606:	01498f63          	beq	s3,s4,624 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 60a:	0485                	addi	s1,s1,1
 60c:	fff4c903          	lbu	s2,-1(s1)
 610:	14090d63          	beqz	s2,76a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 614:	0009079b          	sext.w	a5,s2
    if(state == 0){
 618:	fe0997e3          	bnez	s3,606 <vprintf+0x5c>
      if(c == '%'){
 61c:	fd479ee3          	bne	a5,s4,5f8 <vprintf+0x4e>
        state = '%';
 620:	89be                	mv	s3,a5
 622:	b7e5                	j	60a <vprintf+0x60>
      if(c == 'd'){
 624:	05878063          	beq	a5,s8,664 <vprintf+0xba>
      } else if(c == 'l') {
 628:	05978c63          	beq	a5,s9,680 <vprintf+0xd6>
      } else if(c == 'x') {
 62c:	07a78863          	beq	a5,s10,69c <vprintf+0xf2>
      } else if(c == 'p') {
 630:	09b78463          	beq	a5,s11,6b8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 634:	07300713          	li	a4,115
 638:	0ce78663          	beq	a5,a4,704 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 63c:	06300713          	li	a4,99
 640:	0ee78e63          	beq	a5,a4,73c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 644:	11478863          	beq	a5,s4,754 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 648:	85d2                	mv	a1,s4
 64a:	8556                	mv	a0,s5
 64c:	00000097          	auipc	ra,0x0
 650:	e92080e7          	jalr	-366(ra) # 4de <putc>
        putc(fd, c);
 654:	85ca                	mv	a1,s2
 656:	8556                	mv	a0,s5
 658:	00000097          	auipc	ra,0x0
 65c:	e86080e7          	jalr	-378(ra) # 4de <putc>
      }
      state = 0;
 660:	4981                	li	s3,0
 662:	b765                	j	60a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 664:	008b0913          	addi	s2,s6,8
 668:	4685                	li	a3,1
 66a:	4629                	li	a2,10
 66c:	000b2583          	lw	a1,0(s6)
 670:	8556                	mv	a0,s5
 672:	00000097          	auipc	ra,0x0
 676:	e8e080e7          	jalr	-370(ra) # 500 <printint>
 67a:	8b4a                	mv	s6,s2
      state = 0;
 67c:	4981                	li	s3,0
 67e:	b771                	j	60a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 680:	008b0913          	addi	s2,s6,8
 684:	4681                	li	a3,0
 686:	4629                	li	a2,10
 688:	000b2583          	lw	a1,0(s6)
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	e72080e7          	jalr	-398(ra) # 500 <printint>
 696:	8b4a                	mv	s6,s2
      state = 0;
 698:	4981                	li	s3,0
 69a:	bf85                	j	60a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 69c:	008b0913          	addi	s2,s6,8
 6a0:	4681                	li	a3,0
 6a2:	4641                	li	a2,16
 6a4:	000b2583          	lw	a1,0(s6)
 6a8:	8556                	mv	a0,s5
 6aa:	00000097          	auipc	ra,0x0
 6ae:	e56080e7          	jalr	-426(ra) # 500 <printint>
 6b2:	8b4a                	mv	s6,s2
      state = 0;
 6b4:	4981                	li	s3,0
 6b6:	bf91                	j	60a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6b8:	008b0793          	addi	a5,s6,8
 6bc:	f8f43423          	sd	a5,-120(s0)
 6c0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6c4:	03000593          	li	a1,48
 6c8:	8556                	mv	a0,s5
 6ca:	00000097          	auipc	ra,0x0
 6ce:	e14080e7          	jalr	-492(ra) # 4de <putc>
  putc(fd, 'x');
 6d2:	85ea                	mv	a1,s10
 6d4:	8556                	mv	a0,s5
 6d6:	00000097          	auipc	ra,0x0
 6da:	e08080e7          	jalr	-504(ra) # 4de <putc>
 6de:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6e0:	03c9d793          	srli	a5,s3,0x3c
 6e4:	97de                	add	a5,a5,s7
 6e6:	0007c583          	lbu	a1,0(a5)
 6ea:	8556                	mv	a0,s5
 6ec:	00000097          	auipc	ra,0x0
 6f0:	df2080e7          	jalr	-526(ra) # 4de <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6f4:	0992                	slli	s3,s3,0x4
 6f6:	397d                	addiw	s2,s2,-1
 6f8:	fe0914e3          	bnez	s2,6e0 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6fc:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 700:	4981                	li	s3,0
 702:	b721                	j	60a <vprintf+0x60>
        s = va_arg(ap, char*);
 704:	008b0993          	addi	s3,s6,8
 708:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 70c:	02090163          	beqz	s2,72e <vprintf+0x184>
        while(*s != 0){
 710:	00094583          	lbu	a1,0(s2)
 714:	c9a1                	beqz	a1,764 <vprintf+0x1ba>
          putc(fd, *s);
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	dc6080e7          	jalr	-570(ra) # 4de <putc>
          s++;
 720:	0905                	addi	s2,s2,1
        while(*s != 0){
 722:	00094583          	lbu	a1,0(s2)
 726:	f9e5                	bnez	a1,716 <vprintf+0x16c>
        s = va_arg(ap, char*);
 728:	8b4e                	mv	s6,s3
      state = 0;
 72a:	4981                	li	s3,0
 72c:	bdf9                	j	60a <vprintf+0x60>
          s = "(null)";
 72e:	00000917          	auipc	s2,0x0
 732:	27a90913          	addi	s2,s2,634 # 9a8 <malloc+0x134>
        while(*s != 0){
 736:	02800593          	li	a1,40
 73a:	bff1                	j	716 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 73c:	008b0913          	addi	s2,s6,8
 740:	000b4583          	lbu	a1,0(s6)
 744:	8556                	mv	a0,s5
 746:	00000097          	auipc	ra,0x0
 74a:	d98080e7          	jalr	-616(ra) # 4de <putc>
 74e:	8b4a                	mv	s6,s2
      state = 0;
 750:	4981                	li	s3,0
 752:	bd65                	j	60a <vprintf+0x60>
        putc(fd, c);
 754:	85d2                	mv	a1,s4
 756:	8556                	mv	a0,s5
 758:	00000097          	auipc	ra,0x0
 75c:	d86080e7          	jalr	-634(ra) # 4de <putc>
      state = 0;
 760:	4981                	li	s3,0
 762:	b565                	j	60a <vprintf+0x60>
        s = va_arg(ap, char*);
 764:	8b4e                	mv	s6,s3
      state = 0;
 766:	4981                	li	s3,0
 768:	b54d                	j	60a <vprintf+0x60>
    }
  }
}
 76a:	70e6                	ld	ra,120(sp)
 76c:	7446                	ld	s0,112(sp)
 76e:	74a6                	ld	s1,104(sp)
 770:	7906                	ld	s2,96(sp)
 772:	69e6                	ld	s3,88(sp)
 774:	6a46                	ld	s4,80(sp)
 776:	6aa6                	ld	s5,72(sp)
 778:	6b06                	ld	s6,64(sp)
 77a:	7be2                	ld	s7,56(sp)
 77c:	7c42                	ld	s8,48(sp)
 77e:	7ca2                	ld	s9,40(sp)
 780:	7d02                	ld	s10,32(sp)
 782:	6de2                	ld	s11,24(sp)
 784:	6109                	addi	sp,sp,128
 786:	8082                	ret

0000000000000788 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 788:	715d                	addi	sp,sp,-80
 78a:	ec06                	sd	ra,24(sp)
 78c:	e822                	sd	s0,16(sp)
 78e:	1000                	addi	s0,sp,32
 790:	e010                	sd	a2,0(s0)
 792:	e414                	sd	a3,8(s0)
 794:	e818                	sd	a4,16(s0)
 796:	ec1c                	sd	a5,24(s0)
 798:	03043023          	sd	a6,32(s0)
 79c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7a0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7a4:	8622                	mv	a2,s0
 7a6:	00000097          	auipc	ra,0x0
 7aa:	e04080e7          	jalr	-508(ra) # 5aa <vprintf>
}
 7ae:	60e2                	ld	ra,24(sp)
 7b0:	6442                	ld	s0,16(sp)
 7b2:	6161                	addi	sp,sp,80
 7b4:	8082                	ret

00000000000007b6 <printf>:

void
printf(const char *fmt, ...)
{
 7b6:	711d                	addi	sp,sp,-96
 7b8:	ec06                	sd	ra,24(sp)
 7ba:	e822                	sd	s0,16(sp)
 7bc:	1000                	addi	s0,sp,32
 7be:	e40c                	sd	a1,8(s0)
 7c0:	e810                	sd	a2,16(s0)
 7c2:	ec14                	sd	a3,24(s0)
 7c4:	f018                	sd	a4,32(s0)
 7c6:	f41c                	sd	a5,40(s0)
 7c8:	03043823          	sd	a6,48(s0)
 7cc:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7d0:	00840613          	addi	a2,s0,8
 7d4:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7d8:	85aa                	mv	a1,a0
 7da:	4505                	li	a0,1
 7dc:	00000097          	auipc	ra,0x0
 7e0:	dce080e7          	jalr	-562(ra) # 5aa <vprintf>
}
 7e4:	60e2                	ld	ra,24(sp)
 7e6:	6442                	ld	s0,16(sp)
 7e8:	6125                	addi	sp,sp,96
 7ea:	8082                	ret

00000000000007ec <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ec:	1141                	addi	sp,sp,-16
 7ee:	e422                	sd	s0,8(sp)
 7f0:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7f2:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f6:	00001797          	auipc	a5,0x1
 7fa:	80a7b783          	ld	a5,-2038(a5) # 1000 <freep>
 7fe:	a805                	j	82e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 800:	4618                	lw	a4,8(a2)
 802:	9db9                	addw	a1,a1,a4
 804:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 808:	6398                	ld	a4,0(a5)
 80a:	6318                	ld	a4,0(a4)
 80c:	fee53823          	sd	a4,-16(a0)
 810:	a091                	j	854 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 812:	ff852703          	lw	a4,-8(a0)
 816:	9e39                	addw	a2,a2,a4
 818:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 81a:	ff053703          	ld	a4,-16(a0)
 81e:	e398                	sd	a4,0(a5)
 820:	a099                	j	866 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 822:	6398                	ld	a4,0(a5)
 824:	00e7e463          	bltu	a5,a4,82c <free+0x40>
 828:	00e6ea63          	bltu	a3,a4,83c <free+0x50>
{
 82c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 82e:	fed7fae3          	bgeu	a5,a3,822 <free+0x36>
 832:	6398                	ld	a4,0(a5)
 834:	00e6e463          	bltu	a3,a4,83c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 838:	fee7eae3          	bltu	a5,a4,82c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 83c:	ff852583          	lw	a1,-8(a0)
 840:	6390                	ld	a2,0(a5)
 842:	02059713          	slli	a4,a1,0x20
 846:	9301                	srli	a4,a4,0x20
 848:	0712                	slli	a4,a4,0x4
 84a:	9736                	add	a4,a4,a3
 84c:	fae60ae3          	beq	a2,a4,800 <free+0x14>
    bp->s.ptr = p->s.ptr;
 850:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 854:	4790                	lw	a2,8(a5)
 856:	02061713          	slli	a4,a2,0x20
 85a:	9301                	srli	a4,a4,0x20
 85c:	0712                	slli	a4,a4,0x4
 85e:	973e                	add	a4,a4,a5
 860:	fae689e3          	beq	a3,a4,812 <free+0x26>
  } else
    p->s.ptr = bp;
 864:	e394                	sd	a3,0(a5)
  freep = p;
 866:	00000717          	auipc	a4,0x0
 86a:	78f73d23          	sd	a5,1946(a4) # 1000 <freep>
}
 86e:	6422                	ld	s0,8(sp)
 870:	0141                	addi	sp,sp,16
 872:	8082                	ret

0000000000000874 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 874:	7139                	addi	sp,sp,-64
 876:	fc06                	sd	ra,56(sp)
 878:	f822                	sd	s0,48(sp)
 87a:	f426                	sd	s1,40(sp)
 87c:	f04a                	sd	s2,32(sp)
 87e:	ec4e                	sd	s3,24(sp)
 880:	e852                	sd	s4,16(sp)
 882:	e456                	sd	s5,8(sp)
 884:	e05a                	sd	s6,0(sp)
 886:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 888:	02051493          	slli	s1,a0,0x20
 88c:	9081                	srli	s1,s1,0x20
 88e:	04bd                	addi	s1,s1,15
 890:	8091                	srli	s1,s1,0x4
 892:	0014899b          	addiw	s3,s1,1
 896:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 898:	00000517          	auipc	a0,0x0
 89c:	76853503          	ld	a0,1896(a0) # 1000 <freep>
 8a0:	c515                	beqz	a0,8cc <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a4:	4798                	lw	a4,8(a5)
 8a6:	02977f63          	bgeu	a4,s1,8e4 <malloc+0x70>
 8aa:	8a4e                	mv	s4,s3
 8ac:	0009871b          	sext.w	a4,s3
 8b0:	6685                	lui	a3,0x1
 8b2:	00d77363          	bgeu	a4,a3,8b8 <malloc+0x44>
 8b6:	6a05                	lui	s4,0x1
 8b8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8bc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8c0:	00000917          	auipc	s2,0x0
 8c4:	74090913          	addi	s2,s2,1856 # 1000 <freep>
  if(p == (char*)-1)
 8c8:	5afd                	li	s5,-1
 8ca:	a88d                	j	93c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8cc:	00001797          	auipc	a5,0x1
 8d0:	94478793          	addi	a5,a5,-1724 # 1210 <base>
 8d4:	00000717          	auipc	a4,0x0
 8d8:	72f73623          	sd	a5,1836(a4) # 1000 <freep>
 8dc:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8de:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8e2:	b7e1                	j	8aa <malloc+0x36>
      if(p->s.size == nunits)
 8e4:	02e48b63          	beq	s1,a4,91a <malloc+0xa6>
        p->s.size -= nunits;
 8e8:	4137073b          	subw	a4,a4,s3
 8ec:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8ee:	1702                	slli	a4,a4,0x20
 8f0:	9301                	srli	a4,a4,0x20
 8f2:	0712                	slli	a4,a4,0x4
 8f4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8f6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8fa:	00000717          	auipc	a4,0x0
 8fe:	70a73323          	sd	a0,1798(a4) # 1000 <freep>
      return (void*)(p + 1);
 902:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 906:	70e2                	ld	ra,56(sp)
 908:	7442                	ld	s0,48(sp)
 90a:	74a2                	ld	s1,40(sp)
 90c:	7902                	ld	s2,32(sp)
 90e:	69e2                	ld	s3,24(sp)
 910:	6a42                	ld	s4,16(sp)
 912:	6aa2                	ld	s5,8(sp)
 914:	6b02                	ld	s6,0(sp)
 916:	6121                	addi	sp,sp,64
 918:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 91a:	6398                	ld	a4,0(a5)
 91c:	e118                	sd	a4,0(a0)
 91e:	bff1                	j	8fa <malloc+0x86>
  hp->s.size = nu;
 920:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 924:	0541                	addi	a0,a0,16
 926:	00000097          	auipc	ra,0x0
 92a:	ec6080e7          	jalr	-314(ra) # 7ec <free>
  return freep;
 92e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 932:	d971                	beqz	a0,906 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 934:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 936:	4798                	lw	a4,8(a5)
 938:	fa9776e3          	bgeu	a4,s1,8e4 <malloc+0x70>
    if(p == freep)
 93c:	00093703          	ld	a4,0(s2)
 940:	853e                	mv	a0,a5
 942:	fef719e3          	bne	a4,a5,934 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 946:	8552                	mv	a0,s4
 948:	00000097          	auipc	ra,0x0
 94c:	b5e080e7          	jalr	-1186(ra) # 4a6 <sbrk>
  if(p == (char*)-1)
 950:	fd5518e3          	bne	a0,s5,920 <malloc+0xac>
        return 0;
 954:	4501                	li	a0,0
 956:	bf45                	j	906 <malloc+0x92>
