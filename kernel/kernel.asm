
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	bac78793          	addi	a5,a5,-1108 # 80005c10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca9f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	386080e7          	jalr	902(ra) # 800024b2 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	75078793          	addi	a5,a5,1872 # 80020bc8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07a323          	sw	zero,1446(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72923          	sw	a5,818(a4) # 800088b0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	536dad83          	lw	s11,1334(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4e050513          	addi	a0,a0,1248 # 80010ad8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	38250513          	addi	a0,a0,898 # 80010ad8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	36648493          	addi	s1,s1,870 # 80010ad8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	32650513          	addi	a0,a0,806 # 80010af8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0b27a783          	lw	a5,178(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0827b783          	ld	a5,130(a5) # 800088b8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	08273703          	ld	a4,130(a4) # 800088c0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	298a0a13          	addi	s4,s4,664 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	05048493          	addi	s1,s1,80 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	05098993          	addi	s3,s3,80 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	826080e7          	jalr	-2010(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	22a50513          	addi	a0,a0,554 # 80010af8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fd27a783          	lw	a5,-46(a5) # 800088b0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fd873703          	ld	a4,-40(a4) # 800088c0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fc87b783          	ld	a5,-56(a5) # 800088b8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1fc98993          	addi	s3,s3,508 # 80010af8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fb448493          	addi	s1,s1,-76 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fb490913          	addi	s2,s2,-76 # 800088c0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	738080e7          	jalr	1848(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1c648493          	addi	s1,s1,454 # 80010af8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7bd23          	sd	a4,-134(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	13c48493          	addi	s1,s1,316 # 80010af8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	36278793          	addi	a5,a5,866 # 80021d60 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	11290913          	addi	s2,s2,274 # 80010b30 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	07650513          	addi	a0,a0,118 # 80010b30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	29250513          	addi	a0,a0,658 # 80021d60 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	04048493          	addi	s1,s1,64 # 80010b30 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	02850513          	addi	a0,a0,40 # 80010b30 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	ffc50513          	addi	a0,a0,-4 # 80010b30 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a4070713          	addi	a4,a4,-1472 # 800088c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7d6080e7          	jalr	2006(ra) # 80002694 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	d8a080e7          	jalr	-630(ra) # 80005c50 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	736080e7          	jalr	1846(ra) # 8000266c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	756080e7          	jalr	1878(ra) # 80002694 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	cf4080e7          	jalr	-780(ra) # 80005c3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d02080e7          	jalr	-766(ra) # 80005c50 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	eac080e7          	jalr	-340(ra) # 80002e02 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	550080e7          	jalr	1360(ra) # 800034ae <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	4ee080e7          	jalr	1262(ra) # 80004454 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	dea080e7          	jalr	-534(ra) # 80005d58 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72223          	sw	a5,-1724(a4) # 800088c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9387b783          	ld	a5,-1736(a5) # 800088d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	66a7be23          	sd	a0,1660(a5) # 800088d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	11aa0a13          	addi	s4,s4,282 # 80016980 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	26850513          	addi	a0,a0,616 # 80010b50 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	26850513          	addi	a0,a0,616 # 80010b68 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	67048493          	addi	s1,s1,1648 # 80010f80 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	04e98993          	addi	s3,s3,78 # 80016980 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1e450513          	addi	a0,a0,484 # 80010b80 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	18c70713          	addi	a4,a4,396 # 80010b50 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	ca6080e7          	jalr	-858(ra) # 800026ac <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	a0e080e7          	jalr	-1522(ra) # 8000342e <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	11a90913          	addi	s2,s2,282 # 80010b50 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3be48493          	addi	s1,s1,958 # 80010f80 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	db690913          	addi	s2,s2,-586 # 80016980 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c4a7b023          	sd	a0,-960(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bcc58593          	addi	a1,a1,-1076 # 80008870 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	16e080e7          	jalr	366(ra) # 80003e50 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7ce080e7          	jalr	1998(ra) # 80001564 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	6d4080e7          	jalr	1748(ra) # 800044e6 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	848080e7          	jalr	-1976(ra) # 8000366c <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d1848493          	addi	s1,s1,-744 # 80010b68 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	c9270713          	addi	a4,a4,-878 # 80010b50 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cbc70713          	addi	a4,a4,-836 # 80010b88 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	c74a0a13          	addi	s4,s4,-908 # 80010b50 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	a9a90913          	addi	s2,s2,-1382 # 80016980 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	08648493          	addi	s1,s1,134 # 80010f80 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	6ce080e7          	jalr	1742(ra) # 80002602 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	be670713          	addi	a4,a4,-1050 # 80010b50 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	bc090913          	addi	s2,s2,-1088 # 80010b50 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	be058593          	addi	a1,a1,-1056 # 80010b88 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	64c080e7          	jalr	1612(ra) # 80002602 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0b37a623          	sw	s3,172(a5)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	eb448493          	addi	s1,s1,-332 # 80010f80 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	8a890913          	addi	s2,s2,-1880 # 80016980 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e4048493          	addi	s1,s1,-448 # 80010f80 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	790a0a13          	addi	s4,s4,1936 # 800088d8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	83098993          	addi	s3,s3,-2000 # 80016980 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7347b783          	ld	a5,1844(a5) # 800088d8 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	370080e7          	jalr	880(ra) # 80004538 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	e8c080e7          	jalr	-372(ra) # 8000406c <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	678080e7          	jalr	1656(ra) # 80003864 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	ef8080e7          	jalr	-264(ra) # 800040ec <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	96848493          	addi	s1,s1,-1688 # 80010b68 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2e8080e7          	jalr	744(ra) # 8000053e <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d1248493          	addi	s1,s1,-750 # 80010f80 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	70a98993          	addi	s3,s3,1802 # 80016980 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	81650513          	addi	a0,a0,-2026 # 80010b68 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	61898993          	addi	s3,s3,1560 # 80016980 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000ec17          	auipc	s8,0xe
    80002374:	7f8c0c13          	addi	s8,s8,2040 # 80010b68 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c0648493          	addi	s1,s1,-1018 # 80010f80 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d0080e7          	jalr	720(ra) # 80001668 <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7b050513          	addi	a0,a0,1968 # 80010b68 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	79450513          	addi	a0,a0,1940 # 80010b68 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	74650513          	addi	a0,a0,1862 # 80010b68 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e2080e7          	jalr	482(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	218080e7          	jalr	536(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	062080e7          	jalr	98(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	baa48493          	addi	s1,s1,-1110 # 800110d8 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	5a290913          	addi	s2,s2,1442 # 80016ad8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d80b8b93          	addi	s7,s7,-640 # 800082d8 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	020080e7          	jalr	32(ra) # 80000588 <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	016080e7          	jalr	22(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248163          	beq	s1,s2,800025a0 <procdump+0x98>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	1782                	slli	a5,a5,0x20
    80002592:	9381                	srli	a5,a5,0x20
    80002594:	078e                	slli	a5,a5,0x3
    80002596:	97de                	add	a5,a5,s7
    80002598:	6390                	ld	a2,0(a5)
    8000259a:	f661                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259c:	864e                	mv	a2,s3
    8000259e:	b7d1                	j	80002562 <procdump+0x5a>
  }
}
    800025a0:	60a6                	ld	ra,72(sp)
    800025a2:	6406                	ld	s0,64(sp)
    800025a4:	74e2                	ld	s1,56(sp)
    800025a6:	7942                	ld	s2,48(sp)
    800025a8:	79a2                	ld	s3,40(sp)
    800025aa:	7a02                	ld	s4,32(sp)
    800025ac:	6ae2                	ld	s5,24(sp)
    800025ae:	6b42                	ld	s6,16(sp)
    800025b0:	6ba2                	ld	s7,8(sp)
    800025b2:	6161                	addi	sp,sp,80
    800025b4:	8082                	ret

00000000800025b6 <getHelloWorld>:

uint64 
getHelloWorld(void)
{
    800025b6:	1141                	addi	sp,sp,-16
    800025b8:	e406                	sd	ra,8(sp)
    800025ba:	e022                	sd	s0,0(sp)
    800025bc:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    800025be:	00006517          	auipc	a0,0x6
    800025c2:	cda50513          	addi	a0,a0,-806 # 80008298 <digits+0x258>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	fc2080e7          	jalr	-62(ra) # 80000588 <printf>
  return 0;
}
    800025ce:	4501                	li	a0,0
    800025d0:	60a2                	ld	ra,8(sp)
    800025d2:	6402                	ld	s0,0(sp)
    800025d4:	0141                	addi	sp,sp,16
    800025d6:	8082                	ret

00000000800025d8 <getProcTick>:

int 
getProcTick(void){
    800025d8:	1141                	addi	sp,sp,-16
    800025da:	e406                	sd	ra,8(sp)
    800025dc:	e022                	sd	s0,0(sp)
    800025de:	0800                	addi	s0,sp,16
  printf("%d\n", ticks);
    800025e0:	00006597          	auipc	a1,0x6
    800025e4:	3005a583          	lw	a1,768(a1) # 800088e0 <ticks>
    800025e8:	00006517          	auipc	a0,0x6
    800025ec:	e5850513          	addi	a0,a0,-424 # 80008440 <states.0+0x168>
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	f98080e7          	jalr	-104(ra) # 80000588 <printf>
  return 0;
    800025f8:	4501                	li	a0,0
    800025fa:	60a2                	ld	ra,8(sp)
    800025fc:	6402                	ld	s0,0(sp)
    800025fe:	0141                	addi	sp,sp,16
    80002600:	8082                	ret

0000000080002602 <swtch>:
    80002602:	00153023          	sd	ra,0(a0)
    80002606:	00253423          	sd	sp,8(a0)
    8000260a:	e900                	sd	s0,16(a0)
    8000260c:	ed04                	sd	s1,24(a0)
    8000260e:	03253023          	sd	s2,32(a0)
    80002612:	03353423          	sd	s3,40(a0)
    80002616:	03453823          	sd	s4,48(a0)
    8000261a:	03553c23          	sd	s5,56(a0)
    8000261e:	05653023          	sd	s6,64(a0)
    80002622:	05753423          	sd	s7,72(a0)
    80002626:	05853823          	sd	s8,80(a0)
    8000262a:	05953c23          	sd	s9,88(a0)
    8000262e:	07a53023          	sd	s10,96(a0)
    80002632:	07b53423          	sd	s11,104(a0)
    80002636:	0005b083          	ld	ra,0(a1)
    8000263a:	0085b103          	ld	sp,8(a1)
    8000263e:	6980                	ld	s0,16(a1)
    80002640:	6d84                	ld	s1,24(a1)
    80002642:	0205b903          	ld	s2,32(a1)
    80002646:	0285b983          	ld	s3,40(a1)
    8000264a:	0305ba03          	ld	s4,48(a1)
    8000264e:	0385ba83          	ld	s5,56(a1)
    80002652:	0405bb03          	ld	s6,64(a1)
    80002656:	0485bb83          	ld	s7,72(a1)
    8000265a:	0505bc03          	ld	s8,80(a1)
    8000265e:	0585bc83          	ld	s9,88(a1)
    80002662:	0605bd03          	ld	s10,96(a1)
    80002666:	0685bd83          	ld	s11,104(a1)
    8000266a:	8082                	ret

000000008000266c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e406                	sd	ra,8(sp)
    80002670:	e022                	sd	s0,0(sp)
    80002672:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002674:	00006597          	auipc	a1,0x6
    80002678:	c9458593          	addi	a1,a1,-876 # 80008308 <states.0+0x30>
    8000267c:	00014517          	auipc	a0,0x14
    80002680:	30450513          	addi	a0,a0,772 # 80016980 <tickslock>
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	4c2080e7          	jalr	1218(ra) # 80000b46 <initlock>
}
    8000268c:	60a2                	ld	ra,8(sp)
    8000268e:	6402                	ld	s0,0(sp)
    80002690:	0141                	addi	sp,sp,16
    80002692:	8082                	ret

0000000080002694 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e422                	sd	s0,8(sp)
    80002698:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269a:	00003797          	auipc	a5,0x3
    8000269e:	4e678793          	addi	a5,a5,1254 # 80005b80 <kernelvec>
    800026a2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026a6:	6422                	ld	s0,8(sp)
    800026a8:	0141                	addi	sp,sp,16
    800026aa:	8082                	ret

00000000800026ac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ac:	1141                	addi	sp,sp,-16
    800026ae:	e406                	sd	ra,8(sp)
    800026b0:	e022                	sd	s0,0(sp)
    800026b2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	2f8080e7          	jalr	760(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026c6:	00005617          	auipc	a2,0x5
    800026ca:	93a60613          	addi	a2,a2,-1734 # 80007000 <_trampoline>
    800026ce:	00005697          	auipc	a3,0x5
    800026d2:	93268693          	addi	a3,a3,-1742 # 80007000 <_trampoline>
    800026d6:	8e91                	sub	a3,a3,a2
    800026d8:	040007b7          	lui	a5,0x4000
    800026dc:	17fd                	addi	a5,a5,-1
    800026de:	07b2                	slli	a5,a5,0xc
    800026e0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026e6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026e8:	180026f3          	csrr	a3,satp
    800026ec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026ee:	6d38                	ld	a4,88(a0)
    800026f0:	6134                	ld	a3,64(a0)
    800026f2:	6585                	lui	a1,0x1
    800026f4:	96ae                	add	a3,a3,a1
    800026f6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026f8:	6d38                	ld	a4,88(a0)
    800026fa:	00000697          	auipc	a3,0x0
    800026fe:	13068693          	addi	a3,a3,304 # 8000282a <usertrap>
    80002702:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002704:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002706:	8692                	mv	a3,tp
    80002708:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000270e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002712:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002716:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000271a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000271c:	6f18                	ld	a4,24(a4)
    8000271e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002722:	6928                	ld	a0,80(a0)
    80002724:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002726:	00005717          	auipc	a4,0x5
    8000272a:	97670713          	addi	a4,a4,-1674 # 8000709c <userret>
    8000272e:	8f11                	sub	a4,a4,a2
    80002730:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002732:	577d                	li	a4,-1
    80002734:	177e                	slli	a4,a4,0x3f
    80002736:	8d59                	or	a0,a0,a4
    80002738:	9782                	jalr	a5
}
    8000273a:	60a2                	ld	ra,8(sp)
    8000273c:	6402                	ld	s0,0(sp)
    8000273e:	0141                	addi	sp,sp,16
    80002740:	8082                	ret

0000000080002742 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002742:	1101                	addi	sp,sp,-32
    80002744:	ec06                	sd	ra,24(sp)
    80002746:	e822                	sd	s0,16(sp)
    80002748:	e426                	sd	s1,8(sp)
    8000274a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000274c:	00014497          	auipc	s1,0x14
    80002750:	23448493          	addi	s1,s1,564 # 80016980 <tickslock>
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	480080e7          	jalr	1152(ra) # 80000bd6 <acquire>
  ticks++;
    8000275e:	00006517          	auipc	a0,0x6
    80002762:	18250513          	addi	a0,a0,386 # 800088e0 <ticks>
    80002766:	411c                	lw	a5,0(a0)
    80002768:	2785                	addiw	a5,a5,1
    8000276a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	94c080e7          	jalr	-1716(ra) # 800020b8 <wakeup>
  release(&tickslock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	514080e7          	jalr	1300(ra) # 80000c8a <release>
}
    8000277e:	60e2                	ld	ra,24(sp)
    80002780:	6442                	ld	s0,16(sp)
    80002782:	64a2                	ld	s1,8(sp)
    80002784:	6105                	addi	sp,sp,32
    80002786:	8082                	ret

0000000080002788 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002788:	1101                	addi	sp,sp,-32
    8000278a:	ec06                	sd	ra,24(sp)
    8000278c:	e822                	sd	s0,16(sp)
    8000278e:	e426                	sd	s1,8(sp)
    80002790:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002792:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002796:	00074d63          	bltz	a4,800027b0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000279a:	57fd                	li	a5,-1
    8000279c:	17fe                	slli	a5,a5,0x3f
    8000279e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027a2:	06f70363          	beq	a4,a5,80002808 <devintr+0x80>
  }
}
    800027a6:	60e2                	ld	ra,24(sp)
    800027a8:	6442                	ld	s0,16(sp)
    800027aa:	64a2                	ld	s1,8(sp)
    800027ac:	6105                	addi	sp,sp,32
    800027ae:	8082                	ret
     (scause & 0xff) == 9){
    800027b0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027b4:	46a5                	li	a3,9
    800027b6:	fed792e3          	bne	a5,a3,8000279a <devintr+0x12>
    int irq = plic_claim();
    800027ba:	00003097          	auipc	ra,0x3
    800027be:	4ce080e7          	jalr	1230(ra) # 80005c88 <plic_claim>
    800027c2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027c4:	47a9                	li	a5,10
    800027c6:	02f50763          	beq	a0,a5,800027f4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ca:	4785                	li	a5,1
    800027cc:	02f50963          	beq	a0,a5,800027fe <devintr+0x76>
    return 1;
    800027d0:	4505                	li	a0,1
    } else if(irq){
    800027d2:	d8f1                	beqz	s1,800027a6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027d4:	85a6                	mv	a1,s1
    800027d6:	00006517          	auipc	a0,0x6
    800027da:	b3a50513          	addi	a0,a0,-1222 # 80008310 <states.0+0x38>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	daa080e7          	jalr	-598(ra) # 80000588 <printf>
      plic_complete(irq);
    800027e6:	8526                	mv	a0,s1
    800027e8:	00003097          	auipc	ra,0x3
    800027ec:	4c4080e7          	jalr	1220(ra) # 80005cac <plic_complete>
    return 1;
    800027f0:	4505                	li	a0,1
    800027f2:	bf55                	j	800027a6 <devintr+0x1e>
      uartintr();
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	1a6080e7          	jalr	422(ra) # 8000099a <uartintr>
    800027fc:	b7ed                	j	800027e6 <devintr+0x5e>
      virtio_disk_intr();
    800027fe:	00004097          	auipc	ra,0x4
    80002802:	97a080e7          	jalr	-1670(ra) # 80006178 <virtio_disk_intr>
    80002806:	b7c5                	j	800027e6 <devintr+0x5e>
    if(cpuid() == 0){
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	178080e7          	jalr	376(ra) # 80001980 <cpuid>
    80002810:	c901                	beqz	a0,80002820 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002812:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002816:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002818:	14479073          	csrw	sip,a5
    return 2;
    8000281c:	4509                	li	a0,2
    8000281e:	b761                	j	800027a6 <devintr+0x1e>
      clockintr();
    80002820:	00000097          	auipc	ra,0x0
    80002824:	f22080e7          	jalr	-222(ra) # 80002742 <clockintr>
    80002828:	b7ed                	j	80002812 <devintr+0x8a>

000000008000282a <usertrap>:
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	e04a                	sd	s2,0(sp)
    80002834:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002836:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000283a:	1007f793          	andi	a5,a5,256
    8000283e:	e3b1                	bnez	a5,80002882 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002840:	00003797          	auipc	a5,0x3
    80002844:	34078793          	addi	a5,a5,832 # 80005b80 <kernelvec>
    80002848:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	160080e7          	jalr	352(ra) # 800019ac <myproc>
    80002854:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002856:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002858:	14102773          	csrr	a4,sepc
    8000285c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000285e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002862:	47a1                	li	a5,8
    80002864:	02f70763          	beq	a4,a5,80002892 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	f20080e7          	jalr	-224(ra) # 80002788 <devintr>
    80002870:	892a                	mv	s2,a0
    80002872:	c151                	beqz	a0,800028f6 <usertrap+0xcc>
  if(killed(p))
    80002874:	8526                	mv	a0,s1
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	a86080e7          	jalr	-1402(ra) # 800022fc <killed>
    8000287e:	c929                	beqz	a0,800028d0 <usertrap+0xa6>
    80002880:	a099                	j	800028c6 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002882:	00006517          	auipc	a0,0x6
    80002886:	aae50513          	addi	a0,a0,-1362 # 80008330 <states.0+0x58>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
    if(killed(p))
    80002892:	00000097          	auipc	ra,0x0
    80002896:	a6a080e7          	jalr	-1430(ra) # 800022fc <killed>
    8000289a:	e921                	bnez	a0,800028ea <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000289c:	6cb8                	ld	a4,88(s1)
    8000289e:	6f1c                	ld	a5,24(a4)
    800028a0:	0791                	addi	a5,a5,4
    800028a2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ac:	10079073          	csrw	sstatus,a5
    syscall();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	2d4080e7          	jalr	724(ra) # 80002b84 <syscall>
  if(killed(p))
    800028b8:	8526                	mv	a0,s1
    800028ba:	00000097          	auipc	ra,0x0
    800028be:	a42080e7          	jalr	-1470(ra) # 800022fc <killed>
    800028c2:	c911                	beqz	a0,800028d6 <usertrap+0xac>
    800028c4:	4901                	li	s2,0
    exit(-1);
    800028c6:	557d                	li	a0,-1
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	8c0080e7          	jalr	-1856(ra) # 80002188 <exit>
  if(which_dev == 2)
    800028d0:	4789                	li	a5,2
    800028d2:	04f90f63          	beq	s2,a5,80002930 <usertrap+0x106>
  usertrapret();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	dd6080e7          	jalr	-554(ra) # 800026ac <usertrapret>
}
    800028de:	60e2                	ld	ra,24(sp)
    800028e0:	6442                	ld	s0,16(sp)
    800028e2:	64a2                	ld	s1,8(sp)
    800028e4:	6902                	ld	s2,0(sp)
    800028e6:	6105                	addi	sp,sp,32
    800028e8:	8082                	ret
      exit(-1);
    800028ea:	557d                	li	a0,-1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	89c080e7          	jalr	-1892(ra) # 80002188 <exit>
    800028f4:	b765                	j	8000289c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028fa:	5890                	lw	a2,48(s1)
    800028fc:	00006517          	auipc	a0,0x6
    80002900:	a5450513          	addi	a0,a0,-1452 # 80008350 <states.0+0x78>
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c84080e7          	jalr	-892(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002910:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002914:	00006517          	auipc	a0,0x6
    80002918:	a6c50513          	addi	a0,a0,-1428 # 80008380 <states.0+0xa8>
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	c6c080e7          	jalr	-916(ra) # 80000588 <printf>
    setkilled(p);
    80002924:	8526                	mv	a0,s1
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	9aa080e7          	jalr	-1622(ra) # 800022d0 <setkilled>
    8000292e:	b769                	j	800028b8 <usertrap+0x8e>
    yield();
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	6e8080e7          	jalr	1768(ra) # 80002018 <yield>
    80002938:	bf79                	j	800028d6 <usertrap+0xac>

000000008000293a <kerneltrap>:
{
    8000293a:	7179                	addi	sp,sp,-48
    8000293c:	f406                	sd	ra,40(sp)
    8000293e:	f022                	sd	s0,32(sp)
    80002940:	ec26                	sd	s1,24(sp)
    80002942:	e84a                	sd	s2,16(sp)
    80002944:	e44e                	sd	s3,8(sp)
    80002946:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002948:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002950:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002954:	1004f793          	andi	a5,s1,256
    80002958:	cb85                	beqz	a5,80002988 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000295e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002960:	ef85                	bnez	a5,80002998 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002962:	00000097          	auipc	ra,0x0
    80002966:	e26080e7          	jalr	-474(ra) # 80002788 <devintr>
    8000296a:	cd1d                	beqz	a0,800029a8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000296c:	4789                	li	a5,2
    8000296e:	06f50a63          	beq	a0,a5,800029e2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002972:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002976:	10049073          	csrw	sstatus,s1
}
    8000297a:	70a2                	ld	ra,40(sp)
    8000297c:	7402                	ld	s0,32(sp)
    8000297e:	64e2                	ld	s1,24(sp)
    80002980:	6942                	ld	s2,16(sp)
    80002982:	69a2                	ld	s3,8(sp)
    80002984:	6145                	addi	sp,sp,48
    80002986:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	a1850513          	addi	a0,a0,-1512 # 800083a0 <states.0+0xc8>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	a3050513          	addi	a0,a0,-1488 # 800083c8 <states.0+0xf0>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029a8:	85ce                	mv	a1,s3
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	a3e50513          	addi	a0,a0,-1474 # 800083e8 <states.0+0x110>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd6080e7          	jalr	-1066(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029be:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	a3650513          	addi	a0,a0,-1482 # 800083f8 <states.0+0x120>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	bbe080e7          	jalr	-1090(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	a3e50513          	addi	a0,a0,-1474 # 80008410 <states.0+0x138>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	fca080e7          	jalr	-54(ra) # 800019ac <myproc>
    800029ea:	d541                	beqz	a0,80002972 <kerneltrap+0x38>
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800029f4:	4d18                	lw	a4,24(a0)
    800029f6:	4791                	li	a5,4
    800029f8:	f6f71de3          	bne	a4,a5,80002972 <kerneltrap+0x38>
    yield();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	61c080e7          	jalr	1564(ra) # 80002018 <yield>
    80002a04:	b7bd                	j	80002972 <kerneltrap+0x38>

0000000080002a06 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	1000                	addi	s0,sp,32
    80002a10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	f9a080e7          	jalr	-102(ra) # 800019ac <myproc>
  switch (n) {
    80002a1a:	4795                	li	a5,5
    80002a1c:	0497e163          	bltu	a5,s1,80002a5e <argraw+0x58>
    80002a20:	048a                	slli	s1,s1,0x2
    80002a22:	00006717          	auipc	a4,0x6
    80002a26:	a2670713          	addi	a4,a4,-1498 # 80008448 <states.0+0x170>
    80002a2a:	94ba                	add	s1,s1,a4
    80002a2c:	409c                	lw	a5,0(s1)
    80002a2e:	97ba                	add	a5,a5,a4
    80002a30:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a32:	6d3c                	ld	a5,88(a0)
    80002a34:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a36:	60e2                	ld	ra,24(sp)
    80002a38:	6442                	ld	s0,16(sp)
    80002a3a:	64a2                	ld	s1,8(sp)
    80002a3c:	6105                	addi	sp,sp,32
    80002a3e:	8082                	ret
    return p->trapframe->a1;
    80002a40:	6d3c                	ld	a5,88(a0)
    80002a42:	7fa8                	ld	a0,120(a5)
    80002a44:	bfcd                	j	80002a36 <argraw+0x30>
    return p->trapframe->a2;
    80002a46:	6d3c                	ld	a5,88(a0)
    80002a48:	63c8                	ld	a0,128(a5)
    80002a4a:	b7f5                	j	80002a36 <argraw+0x30>
    return p->trapframe->a3;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	67c8                	ld	a0,136(a5)
    80002a50:	b7dd                	j	80002a36 <argraw+0x30>
    return p->trapframe->a4;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	6bc8                	ld	a0,144(a5)
    80002a56:	b7c5                	j	80002a36 <argraw+0x30>
    return p->trapframe->a5;
    80002a58:	6d3c                	ld	a5,88(a0)
    80002a5a:	6fc8                	ld	a0,152(a5)
    80002a5c:	bfe9                	j	80002a36 <argraw+0x30>
  panic("argraw");
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	9c250513          	addi	a0,a0,-1598 # 80008420 <states.0+0x148>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080002a6e <fetchaddr>:
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	e04a                	sd	s2,0(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84aa                	mv	s1,a0
    80002a7c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	f2e080e7          	jalr	-210(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a86:	653c                	ld	a5,72(a0)
    80002a88:	02f4f863          	bgeu	s1,a5,80002ab8 <fetchaddr+0x4a>
    80002a8c:	00848713          	addi	a4,s1,8
    80002a90:	02e7e663          	bltu	a5,a4,80002abc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a94:	46a1                	li	a3,8
    80002a96:	8626                	mv	a2,s1
    80002a98:	85ca                	mv	a1,s2
    80002a9a:	6928                	ld	a0,80(a0)
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	c58080e7          	jalr	-936(ra) # 800016f4 <copyin>
    80002aa4:	00a03533          	snez	a0,a0
    80002aa8:	40a00533          	neg	a0,a0
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6902                	ld	s2,0(sp)
    80002ab4:	6105                	addi	sp,sp,32
    80002ab6:	8082                	ret
    return -1;
    80002ab8:	557d                	li	a0,-1
    80002aba:	bfcd                	j	80002aac <fetchaddr+0x3e>
    80002abc:	557d                	li	a0,-1
    80002abe:	b7fd                	j	80002aac <fetchaddr+0x3e>

0000000080002ac0 <fetchstr>:
{
    80002ac0:	7179                	addi	sp,sp,-48
    80002ac2:	f406                	sd	ra,40(sp)
    80002ac4:	f022                	sd	s0,32(sp)
    80002ac6:	ec26                	sd	s1,24(sp)
    80002ac8:	e84a                	sd	s2,16(sp)
    80002aca:	e44e                	sd	s3,8(sp)
    80002acc:	1800                	addi	s0,sp,48
    80002ace:	892a                	mv	s2,a0
    80002ad0:	84ae                	mv	s1,a1
    80002ad2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	ed8080e7          	jalr	-296(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002adc:	86ce                	mv	a3,s3
    80002ade:	864a                	mv	a2,s2
    80002ae0:	85a6                	mv	a1,s1
    80002ae2:	6928                	ld	a0,80(a0)
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	c9e080e7          	jalr	-866(ra) # 80001782 <copyinstr>
    80002aec:	00054e63          	bltz	a0,80002b08 <fetchstr+0x48>
  return strlen(buf);
    80002af0:	8526                	mv	a0,s1
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	35c080e7          	jalr	860(ra) # 80000e4e <strlen>
}
    80002afa:	70a2                	ld	ra,40(sp)
    80002afc:	7402                	ld	s0,32(sp)
    80002afe:	64e2                	ld	s1,24(sp)
    80002b00:	6942                	ld	s2,16(sp)
    80002b02:	69a2                	ld	s3,8(sp)
    80002b04:	6145                	addi	sp,sp,48
    80002b06:	8082                	ret
    return -1;
    80002b08:	557d                	li	a0,-1
    80002b0a:	bfc5                	j	80002afa <fetchstr+0x3a>

0000000080002b0c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	1000                	addi	s0,sp,32
    80002b16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	eee080e7          	jalr	-274(ra) # 80002a06 <argraw>
    80002b20:	c088                	sw	a0,0(s1)
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret

0000000080002b2c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	1000                	addi	s0,sp,32
    80002b36:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	ece080e7          	jalr	-306(ra) # 80002a06 <argraw>
    80002b40:	e088                	sd	a0,0(s1)
}
    80002b42:	60e2                	ld	ra,24(sp)
    80002b44:	6442                	ld	s0,16(sp)
    80002b46:	64a2                	ld	s1,8(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret

0000000080002b4c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b4c:	7179                	addi	sp,sp,-48
    80002b4e:	f406                	sd	ra,40(sp)
    80002b50:	f022                	sd	s0,32(sp)
    80002b52:	ec26                	sd	s1,24(sp)
    80002b54:	e84a                	sd	s2,16(sp)
    80002b56:	1800                	addi	s0,sp,48
    80002b58:	84ae                	mv	s1,a1
    80002b5a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b5c:	fd840593          	addi	a1,s0,-40
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	fcc080e7          	jalr	-52(ra) # 80002b2c <argaddr>
  return fetchstr(addr, buf, max);
    80002b68:	864a                	mv	a2,s2
    80002b6a:	85a6                	mv	a1,s1
    80002b6c:	fd843503          	ld	a0,-40(s0)
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	f50080e7          	jalr	-176(ra) # 80002ac0 <fetchstr>
}
    80002b78:	70a2                	ld	ra,40(sp)
    80002b7a:	7402                	ld	s0,32(sp)
    80002b7c:	64e2                	ld	s1,24(sp)
    80002b7e:	6942                	ld	s2,16(sp)
    80002b80:	6145                	addi	sp,sp,48
    80002b82:	8082                	ret

0000000080002b84 <syscall>:
[SYS_getProcTick] sys_getProcTick,
};

void
syscall(void)
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	e04a                	sd	s2,0(sp)
    80002b8e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	e1c080e7          	jalr	-484(ra) # 800019ac <myproc>
    80002b98:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b9a:	05853903          	ld	s2,88(a0)
    80002b9e:	0a893783          	ld	a5,168(s2)
    80002ba2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ba6:	37fd                	addiw	a5,a5,-1
    80002ba8:	4759                	li	a4,22
    80002baa:	00f76f63          	bltu	a4,a5,80002bc8 <syscall+0x44>
    80002bae:	00369713          	slli	a4,a3,0x3
    80002bb2:	00006797          	auipc	a5,0x6
    80002bb6:	8ae78793          	addi	a5,a5,-1874 # 80008460 <syscalls>
    80002bba:	97ba                	add	a5,a5,a4
    80002bbc:	639c                	ld	a5,0(a5)
    80002bbe:	c789                	beqz	a5,80002bc8 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002bc0:	9782                	jalr	a5
    80002bc2:	06a93823          	sd	a0,112(s2)
    80002bc6:	a839                	j	80002be4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bc8:	15848613          	addi	a2,s1,344
    80002bcc:	588c                	lw	a1,48(s1)
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	85a50513          	addi	a0,a0,-1958 # 80008428 <states.0+0x150>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b2080e7          	jalr	-1614(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bde:	6cbc                	ld	a5,88(s1)
    80002be0:	577d                	li	a4,-1
    80002be2:	fbb8                	sd	a4,112(a5)
  }
}
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	64a2                	ld	s1,8(sp)
    80002bea:	6902                	ld	s2,0(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret

0000000080002bf0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bf8:	fec40593          	addi	a1,s0,-20
    80002bfc:	4501                	li	a0,0
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	f0e080e7          	jalr	-242(ra) # 80002b0c <argint>
  exit(n);
    80002c06:	fec42503          	lw	a0,-20(s0)
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	57e080e7          	jalr	1406(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002c12:	4501                	li	a0,0
    80002c14:	60e2                	ld	ra,24(sp)
    80002c16:	6442                	ld	s0,16(sp)
    80002c18:	6105                	addi	sp,sp,32
    80002c1a:	8082                	ret

0000000080002c1c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c1c:	1141                	addi	sp,sp,-16
    80002c1e:	e406                	sd	ra,8(sp)
    80002c20:	e022                	sd	s0,0(sp)
    80002c22:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	d88080e7          	jalr	-632(ra) # 800019ac <myproc>
}
    80002c2c:	5908                	lw	a0,48(a0)
    80002c2e:	60a2                	ld	ra,8(sp)
    80002c30:	6402                	ld	s0,0(sp)
    80002c32:	0141                	addi	sp,sp,16
    80002c34:	8082                	ret

0000000080002c36 <sys_fork>:

uint64
sys_fork(void)
{
    80002c36:	1141                	addi	sp,sp,-16
    80002c38:	e406                	sd	ra,8(sp)
    80002c3a:	e022                	sd	s0,0(sp)
    80002c3c:	0800                	addi	s0,sp,16
  return fork();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	124080e7          	jalr	292(ra) # 80001d62 <fork>
}
    80002c46:	60a2                	ld	ra,8(sp)
    80002c48:	6402                	ld	s0,0(sp)
    80002c4a:	0141                	addi	sp,sp,16
    80002c4c:	8082                	ret

0000000080002c4e <sys_wait>:

uint64
sys_wait(void)
{
    80002c4e:	1101                	addi	sp,sp,-32
    80002c50:	ec06                	sd	ra,24(sp)
    80002c52:	e822                	sd	s0,16(sp)
    80002c54:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c56:	fe840593          	addi	a1,s0,-24
    80002c5a:	4501                	li	a0,0
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	ed0080e7          	jalr	-304(ra) # 80002b2c <argaddr>
  return wait(p);
    80002c64:	fe843503          	ld	a0,-24(s0)
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	6c6080e7          	jalr	1734(ra) # 8000232e <wait>
}
    80002c70:	60e2                	ld	ra,24(sp)
    80002c72:	6442                	ld	s0,16(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c82:	fdc40593          	addi	a1,s0,-36
    80002c86:	4501                	li	a0,0
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	e84080e7          	jalr	-380(ra) # 80002b0c <argint>
  addr = myproc()->sz;
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d1c080e7          	jalr	-740(ra) # 800019ac <myproc>
    80002c98:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c9a:	fdc42503          	lw	a0,-36(s0)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	068080e7          	jalr	104(ra) # 80001d06 <growproc>
    80002ca6:	00054863          	bltz	a0,80002cb6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002caa:	8526                	mv	a0,s1
    80002cac:	70a2                	ld	ra,40(sp)
    80002cae:	7402                	ld	s0,32(sp)
    80002cb0:	64e2                	ld	s1,24(sp)
    80002cb2:	6145                	addi	sp,sp,48
    80002cb4:	8082                	ret
    return -1;
    80002cb6:	54fd                	li	s1,-1
    80002cb8:	bfcd                	j	80002caa <sys_sbrk+0x32>

0000000080002cba <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cba:	7139                	addi	sp,sp,-64
    80002cbc:	fc06                	sd	ra,56(sp)
    80002cbe:	f822                	sd	s0,48(sp)
    80002cc0:	f426                	sd	s1,40(sp)
    80002cc2:	f04a                	sd	s2,32(sp)
    80002cc4:	ec4e                	sd	s3,24(sp)
    80002cc6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cc8:	fcc40593          	addi	a1,s0,-52
    80002ccc:	4501                	li	a0,0
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	e3e080e7          	jalr	-450(ra) # 80002b0c <argint>
  acquire(&tickslock);
    80002cd6:	00014517          	auipc	a0,0x14
    80002cda:	caa50513          	addi	a0,a0,-854 # 80016980 <tickslock>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	ef8080e7          	jalr	-264(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ce6:	00006917          	auipc	s2,0x6
    80002cea:	bfa92903          	lw	s2,-1030(s2) # 800088e0 <ticks>
  while(ticks - ticks0 < n){
    80002cee:	fcc42783          	lw	a5,-52(s0)
    80002cf2:	cf9d                	beqz	a5,80002d30 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cf4:	00014997          	auipc	s3,0x14
    80002cf8:	c8c98993          	addi	s3,s3,-884 # 80016980 <tickslock>
    80002cfc:	00006497          	auipc	s1,0x6
    80002d00:	be448493          	addi	s1,s1,-1052 # 800088e0 <ticks>
    if(killed(myproc())){
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	ca8080e7          	jalr	-856(ra) # 800019ac <myproc>
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	5f0080e7          	jalr	1520(ra) # 800022fc <killed>
    80002d14:	ed15                	bnez	a0,80002d50 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d16:	85ce                	mv	a1,s3
    80002d18:	8526                	mv	a0,s1
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	33a080e7          	jalr	826(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002d22:	409c                	lw	a5,0(s1)
    80002d24:	412787bb          	subw	a5,a5,s2
    80002d28:	fcc42703          	lw	a4,-52(s0)
    80002d2c:	fce7ece3          	bltu	a5,a4,80002d04 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d30:	00014517          	auipc	a0,0x14
    80002d34:	c5050513          	addi	a0,a0,-944 # 80016980 <tickslock>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f52080e7          	jalr	-174(ra) # 80000c8a <release>
  return 0;
    80002d40:	4501                	li	a0,0
}
    80002d42:	70e2                	ld	ra,56(sp)
    80002d44:	7442                	ld	s0,48(sp)
    80002d46:	74a2                	ld	s1,40(sp)
    80002d48:	7902                	ld	s2,32(sp)
    80002d4a:	69e2                	ld	s3,24(sp)
    80002d4c:	6121                	addi	sp,sp,64
    80002d4e:	8082                	ret
      release(&tickslock);
    80002d50:	00014517          	auipc	a0,0x14
    80002d54:	c3050513          	addi	a0,a0,-976 # 80016980 <tickslock>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	f32080e7          	jalr	-206(ra) # 80000c8a <release>
      return -1;
    80002d60:	557d                	li	a0,-1
    80002d62:	b7c5                	j	80002d42 <sys_sleep+0x88>

0000000080002d64 <sys_kill>:

uint64
sys_kill(void)
{ 
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d6c:	fec40593          	addi	a1,s0,-20
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	d9a080e7          	jalr	-614(ra) # 80002b0c <argint>
  return kill(pid);
    80002d7a:	fec42503          	lw	a0,-20(s0)
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	4e0080e7          	jalr	1248(ra) # 8000225e <kill>
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	6105                	addi	sp,sp,32
    80002d8c:	8082                	ret

0000000080002d8e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d8e:	1101                	addi	sp,sp,-32
    80002d90:	ec06                	sd	ra,24(sp)
    80002d92:	e822                	sd	s0,16(sp)
    80002d94:	e426                	sd	s1,8(sp)
    80002d96:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d98:	00014517          	auipc	a0,0x14
    80002d9c:	be850513          	addi	a0,a0,-1048 # 80016980 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	e36080e7          	jalr	-458(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002da8:	00006497          	auipc	s1,0x6
    80002dac:	b384a483          	lw	s1,-1224(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002db0:	00014517          	auipc	a0,0x14
    80002db4:	bd050513          	addi	a0,a0,-1072 # 80016980 <tickslock>
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	ed2080e7          	jalr	-302(ra) # 80000c8a <release>
  return xticks;
}
    80002dc0:	02049513          	slli	a0,s1,0x20
    80002dc4:	9101                	srli	a0,a0,0x20
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <sys_getHelloWorld>:

int 
sys_getHelloWorld(void)
{
    80002dd0:	1141                	addi	sp,sp,-16
    80002dd2:	e406                	sd	ra,8(sp)
    80002dd4:	e022                	sd	s0,0(sp)
    80002dd6:	0800                	addi	s0,sp,16
  return getHelloWorld();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	7de080e7          	jalr	2014(ra) # 800025b6 <getHelloWorld>
}
    80002de0:	2501                	sext.w	a0,a0
    80002de2:	60a2                	ld	ra,8(sp)
    80002de4:	6402                	ld	s0,0(sp)
    80002de6:	0141                	addi	sp,sp,16
    80002de8:	8082                	ret

0000000080002dea <sys_getProcTick>:

int
sys_getProcTick(void)
{
    80002dea:	1141                	addi	sp,sp,-16
    80002dec:	e406                	sd	ra,8(sp)
    80002dee:	e022                	sd	s0,0(sp)
    80002df0:	0800                	addi	s0,sp,16
  return getProcTick();
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	7e6080e7          	jalr	2022(ra) # 800025d8 <getProcTick>
    80002dfa:	60a2                	ld	ra,8(sp)
    80002dfc:	6402                	ld	s0,0(sp)
    80002dfe:	0141                	addi	sp,sp,16
    80002e00:	8082                	ret

0000000080002e02 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	e052                	sd	s4,0(sp)
    80002e10:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e12:	00005597          	auipc	a1,0x5
    80002e16:	70e58593          	addi	a1,a1,1806 # 80008520 <syscalls+0xc0>
    80002e1a:	00014517          	auipc	a0,0x14
    80002e1e:	b7e50513          	addi	a0,a0,-1154 # 80016998 <bcache>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	d24080e7          	jalr	-732(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e2a:	0001c797          	auipc	a5,0x1c
    80002e2e:	b6e78793          	addi	a5,a5,-1170 # 8001e998 <bcache+0x8000>
    80002e32:	0001c717          	auipc	a4,0x1c
    80002e36:	dce70713          	addi	a4,a4,-562 # 8001ec00 <bcache+0x8268>
    80002e3a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e3e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e42:	00014497          	auipc	s1,0x14
    80002e46:	b6e48493          	addi	s1,s1,-1170 # 800169b0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e4a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e4c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e4e:	00005a17          	auipc	s4,0x5
    80002e52:	6daa0a13          	addi	s4,s4,1754 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002e56:	2b893783          	ld	a5,696(s2)
    80002e5a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e5c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e60:	85d2                	mv	a1,s4
    80002e62:	01048513          	addi	a0,s1,16
    80002e66:	00001097          	auipc	ra,0x1
    80002e6a:	4c4080e7          	jalr	1220(ra) # 8000432a <initsleeplock>
    bcache.head.next->prev = b;
    80002e6e:	2b893783          	ld	a5,696(s2)
    80002e72:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e74:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e78:	45848493          	addi	s1,s1,1112
    80002e7c:	fd349de3          	bne	s1,s3,80002e56 <binit+0x54>
  }
}
    80002e80:	70a2                	ld	ra,40(sp)
    80002e82:	7402                	ld	s0,32(sp)
    80002e84:	64e2                	ld	s1,24(sp)
    80002e86:	6942                	ld	s2,16(sp)
    80002e88:	69a2                	ld	s3,8(sp)
    80002e8a:	6a02                	ld	s4,0(sp)
    80002e8c:	6145                	addi	sp,sp,48
    80002e8e:	8082                	ret

0000000080002e90 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	1800                	addi	s0,sp,48
    80002e9e:	892a                	mv	s2,a0
    80002ea0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	af650513          	addi	a0,a0,-1290 # 80016998 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	d2c080e7          	jalr	-724(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eb2:	0001c497          	auipc	s1,0x1c
    80002eb6:	d9e4b483          	ld	s1,-610(s1) # 8001ec50 <bcache+0x82b8>
    80002eba:	0001c797          	auipc	a5,0x1c
    80002ebe:	d4678793          	addi	a5,a5,-698 # 8001ec00 <bcache+0x8268>
    80002ec2:	02f48f63          	beq	s1,a5,80002f00 <bread+0x70>
    80002ec6:	873e                	mv	a4,a5
    80002ec8:	a021                	j	80002ed0 <bread+0x40>
    80002eca:	68a4                	ld	s1,80(s1)
    80002ecc:	02e48a63          	beq	s1,a4,80002f00 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ed0:	449c                	lw	a5,8(s1)
    80002ed2:	ff279ce3          	bne	a5,s2,80002eca <bread+0x3a>
    80002ed6:	44dc                	lw	a5,12(s1)
    80002ed8:	ff3799e3          	bne	a5,s3,80002eca <bread+0x3a>
      b->refcnt++;
    80002edc:	40bc                	lw	a5,64(s1)
    80002ede:	2785                	addiw	a5,a5,1
    80002ee0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ee2:	00014517          	auipc	a0,0x14
    80002ee6:	ab650513          	addi	a0,a0,-1354 # 80016998 <bcache>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	da0080e7          	jalr	-608(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ef2:	01048513          	addi	a0,s1,16
    80002ef6:	00001097          	auipc	ra,0x1
    80002efa:	46e080e7          	jalr	1134(ra) # 80004364 <acquiresleep>
      return b;
    80002efe:	a8b9                	j	80002f5c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f00:	0001c497          	auipc	s1,0x1c
    80002f04:	d484b483          	ld	s1,-696(s1) # 8001ec48 <bcache+0x82b0>
    80002f08:	0001c797          	auipc	a5,0x1c
    80002f0c:	cf878793          	addi	a5,a5,-776 # 8001ec00 <bcache+0x8268>
    80002f10:	00f48863          	beq	s1,a5,80002f20 <bread+0x90>
    80002f14:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f16:	40bc                	lw	a5,64(s1)
    80002f18:	cf81                	beqz	a5,80002f30 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f1a:	64a4                	ld	s1,72(s1)
    80002f1c:	fee49de3          	bne	s1,a4,80002f16 <bread+0x86>
  panic("bget: no buffers");
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	61050513          	addi	a0,a0,1552 # 80008530 <syscalls+0xd0>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	616080e7          	jalr	1558(ra) # 8000053e <panic>
      b->dev = dev;
    80002f30:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f34:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f38:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f3c:	4785                	li	a5,1
    80002f3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	a5850513          	addi	a0,a0,-1448 # 80016998 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d42080e7          	jalr	-702(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f50:	01048513          	addi	a0,s1,16
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	410080e7          	jalr	1040(ra) # 80004364 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f5c:	409c                	lw	a5,0(s1)
    80002f5e:	cb89                	beqz	a5,80002f70 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f60:	8526                	mv	a0,s1
    80002f62:	70a2                	ld	ra,40(sp)
    80002f64:	7402                	ld	s0,32(sp)
    80002f66:	64e2                	ld	s1,24(sp)
    80002f68:	6942                	ld	s2,16(sp)
    80002f6a:	69a2                	ld	s3,8(sp)
    80002f6c:	6145                	addi	sp,sp,48
    80002f6e:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f70:	4581                	li	a1,0
    80002f72:	8526                	mv	a0,s1
    80002f74:	00003097          	auipc	ra,0x3
    80002f78:	fd0080e7          	jalr	-48(ra) # 80005f44 <virtio_disk_rw>
    b->valid = 1;
    80002f7c:	4785                	li	a5,1
    80002f7e:	c09c                	sw	a5,0(s1)
  return b;
    80002f80:	b7c5                	j	80002f60 <bread+0xd0>

0000000080002f82 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	1000                	addi	s0,sp,32
    80002f8c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f8e:	0541                	addi	a0,a0,16
    80002f90:	00001097          	auipc	ra,0x1
    80002f94:	46e080e7          	jalr	1134(ra) # 800043fe <holdingsleep>
    80002f98:	cd01                	beqz	a0,80002fb0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f9a:	4585                	li	a1,1
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	00003097          	auipc	ra,0x3
    80002fa2:	fa6080e7          	jalr	-90(ra) # 80005f44 <virtio_disk_rw>
}
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret
    panic("bwrite");
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	59850513          	addi	a0,a0,1432 # 80008548 <syscalls+0xe8>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	586080e7          	jalr	1414(ra) # 8000053e <panic>

0000000080002fc0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	e04a                	sd	s2,0(sp)
    80002fca:	1000                	addi	s0,sp,32
    80002fcc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fce:	01050913          	addi	s2,a0,16
    80002fd2:	854a                	mv	a0,s2
    80002fd4:	00001097          	auipc	ra,0x1
    80002fd8:	42a080e7          	jalr	1066(ra) # 800043fe <holdingsleep>
    80002fdc:	c92d                	beqz	a0,8000304e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fde:	854a                	mv	a0,s2
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	3da080e7          	jalr	986(ra) # 800043ba <releasesleep>

  acquire(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	9b050513          	addi	a0,a0,-1616 # 80016998 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	be6080e7          	jalr	-1050(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	37fd                	addiw	a5,a5,-1
    80002ffc:	0007871b          	sext.w	a4,a5
    80003000:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003002:	eb05                	bnez	a4,80003032 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003004:	68bc                	ld	a5,80(s1)
    80003006:	64b8                	ld	a4,72(s1)
    80003008:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000300a:	64bc                	ld	a5,72(s1)
    8000300c:	68b8                	ld	a4,80(s1)
    8000300e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003010:	0001c797          	auipc	a5,0x1c
    80003014:	98878793          	addi	a5,a5,-1656 # 8001e998 <bcache+0x8000>
    80003018:	2b87b703          	ld	a4,696(a5)
    8000301c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000301e:	0001c717          	auipc	a4,0x1c
    80003022:	be270713          	addi	a4,a4,-1054 # 8001ec00 <bcache+0x8268>
    80003026:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003028:	2b87b703          	ld	a4,696(a5)
    8000302c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000302e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	96650513          	addi	a0,a0,-1690 # 80016998 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c50080e7          	jalr	-944(ra) # 80000c8a <release>
}
    80003042:	60e2                	ld	ra,24(sp)
    80003044:	6442                	ld	s0,16(sp)
    80003046:	64a2                	ld	s1,8(sp)
    80003048:	6902                	ld	s2,0(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret
    panic("brelse");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	50250513          	addi	a0,a0,1282 # 80008550 <syscalls+0xf0>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>

000000008000305e <bpin>:

void
bpin(struct buf *b) {
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	e426                	sd	s1,8(sp)
    80003066:	1000                	addi	s0,sp,32
    80003068:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	92e50513          	addi	a0,a0,-1746 # 80016998 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	b64080e7          	jalr	-1180(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000307a:	40bc                	lw	a5,64(s1)
    8000307c:	2785                	addiw	a5,a5,1
    8000307e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003080:	00014517          	auipc	a0,0x14
    80003084:	91850513          	addi	a0,a0,-1768 # 80016998 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	c02080e7          	jalr	-1022(ra) # 80000c8a <release>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret

000000008000309a <bunpin>:

void
bunpin(struct buf *b) {
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a6:	00014517          	auipc	a0,0x14
    800030aa:	8f250513          	addi	a0,a0,-1806 # 80016998 <bcache>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	b28080e7          	jalr	-1240(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030b6:	40bc                	lw	a5,64(s1)
    800030b8:	37fd                	addiw	a5,a5,-1
    800030ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	8dc50513          	addi	a0,a0,-1828 # 80016998 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bc6080e7          	jalr	-1082(ra) # 80000c8a <release>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	e04a                	sd	s2,0(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030e4:	00d5d59b          	srliw	a1,a1,0xd
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	f8c7a783          	lw	a5,-116(a5) # 8001f074 <sb+0x1c>
    800030f0:	9dbd                	addw	a1,a1,a5
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	d9e080e7          	jalr	-610(ra) # 80002e90 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030fa:	0074f713          	andi	a4,s1,7
    800030fe:	4785                	li	a5,1
    80003100:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003104:	14ce                	slli	s1,s1,0x33
    80003106:	90d9                	srli	s1,s1,0x36
    80003108:	00950733          	add	a4,a0,s1
    8000310c:	05874703          	lbu	a4,88(a4)
    80003110:	00e7f6b3          	and	a3,a5,a4
    80003114:	c69d                	beqz	a3,80003142 <bfree+0x6c>
    80003116:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003118:	94aa                	add	s1,s1,a0
    8000311a:	fff7c793          	not	a5,a5
    8000311e:	8ff9                	and	a5,a5,a4
    80003120:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003124:	00001097          	auipc	ra,0x1
    80003128:	120080e7          	jalr	288(ra) # 80004244 <log_write>
  brelse(bp);
    8000312c:	854a                	mv	a0,s2
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	e92080e7          	jalr	-366(ra) # 80002fc0 <brelse>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6902                	ld	s2,0(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret
    panic("freeing free block");
    80003142:	00005517          	auipc	a0,0x5
    80003146:	41650513          	addi	a0,a0,1046 # 80008558 <syscalls+0xf8>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>

0000000080003152 <balloc>:
{
    80003152:	711d                	addi	sp,sp,-96
    80003154:	ec86                	sd	ra,88(sp)
    80003156:	e8a2                	sd	s0,80(sp)
    80003158:	e4a6                	sd	s1,72(sp)
    8000315a:	e0ca                	sd	s2,64(sp)
    8000315c:	fc4e                	sd	s3,56(sp)
    8000315e:	f852                	sd	s4,48(sp)
    80003160:	f456                	sd	s5,40(sp)
    80003162:	f05a                	sd	s6,32(sp)
    80003164:	ec5e                	sd	s7,24(sp)
    80003166:	e862                	sd	s8,16(sp)
    80003168:	e466                	sd	s9,8(sp)
    8000316a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	ef07a783          	lw	a5,-272(a5) # 8001f05c <sb+0x4>
    80003174:	10078163          	beqz	a5,80003276 <balloc+0x124>
    80003178:	8baa                	mv	s7,a0
    8000317a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000317c:	0001cb17          	auipc	s6,0x1c
    80003180:	edcb0b13          	addi	s6,s6,-292 # 8001f058 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003184:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003186:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003188:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000318a:	6c89                	lui	s9,0x2
    8000318c:	a061                	j	80003214 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000318e:	974a                	add	a4,a4,s2
    80003190:	8fd5                	or	a5,a5,a3
    80003192:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003196:	854a                	mv	a0,s2
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	0ac080e7          	jalr	172(ra) # 80004244 <log_write>
        brelse(bp);
    800031a0:	854a                	mv	a0,s2
    800031a2:	00000097          	auipc	ra,0x0
    800031a6:	e1e080e7          	jalr	-482(ra) # 80002fc0 <brelse>
  bp = bread(dev, bno);
    800031aa:	85a6                	mv	a1,s1
    800031ac:	855e                	mv	a0,s7
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	ce2080e7          	jalr	-798(ra) # 80002e90 <bread>
    800031b6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031b8:	40000613          	li	a2,1024
    800031bc:	4581                	li	a1,0
    800031be:	05850513          	addi	a0,a0,88
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b10080e7          	jalr	-1264(ra) # 80000cd2 <memset>
  log_write(bp);
    800031ca:	854a                	mv	a0,s2
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	078080e7          	jalr	120(ra) # 80004244 <log_write>
  brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	dea080e7          	jalr	-534(ra) # 80002fc0 <brelse>
}
    800031de:	8526                	mv	a0,s1
    800031e0:	60e6                	ld	ra,88(sp)
    800031e2:	6446                	ld	s0,80(sp)
    800031e4:	64a6                	ld	s1,72(sp)
    800031e6:	6906                	ld	s2,64(sp)
    800031e8:	79e2                	ld	s3,56(sp)
    800031ea:	7a42                	ld	s4,48(sp)
    800031ec:	7aa2                	ld	s5,40(sp)
    800031ee:	7b02                	ld	s6,32(sp)
    800031f0:	6be2                	ld	s7,24(sp)
    800031f2:	6c42                	ld	s8,16(sp)
    800031f4:	6ca2                	ld	s9,8(sp)
    800031f6:	6125                	addi	sp,sp,96
    800031f8:	8082                	ret
    brelse(bp);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	dc4080e7          	jalr	-572(ra) # 80002fc0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003204:	015c87bb          	addw	a5,s9,s5
    80003208:	00078a9b          	sext.w	s5,a5
    8000320c:	004b2703          	lw	a4,4(s6)
    80003210:	06eaf363          	bgeu	s5,a4,80003276 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003214:	41fad79b          	sraiw	a5,s5,0x1f
    80003218:	0137d79b          	srliw	a5,a5,0x13
    8000321c:	015787bb          	addw	a5,a5,s5
    80003220:	40d7d79b          	sraiw	a5,a5,0xd
    80003224:	01cb2583          	lw	a1,28(s6)
    80003228:	9dbd                	addw	a1,a1,a5
    8000322a:	855e                	mv	a0,s7
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	c64080e7          	jalr	-924(ra) # 80002e90 <bread>
    80003234:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003236:	004b2503          	lw	a0,4(s6)
    8000323a:	000a849b          	sext.w	s1,s5
    8000323e:	8662                	mv	a2,s8
    80003240:	faa4fde3          	bgeu	s1,a0,800031fa <balloc+0xa8>
      m = 1 << (bi % 8);
    80003244:	41f6579b          	sraiw	a5,a2,0x1f
    80003248:	01d7d69b          	srliw	a3,a5,0x1d
    8000324c:	00c6873b          	addw	a4,a3,a2
    80003250:	00777793          	andi	a5,a4,7
    80003254:	9f95                	subw	a5,a5,a3
    80003256:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000325a:	4037571b          	sraiw	a4,a4,0x3
    8000325e:	00e906b3          	add	a3,s2,a4
    80003262:	0586c683          	lbu	a3,88(a3)
    80003266:	00d7f5b3          	and	a1,a5,a3
    8000326a:	d195                	beqz	a1,8000318e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	2605                	addiw	a2,a2,1
    8000326e:	2485                	addiw	s1,s1,1
    80003270:	fd4618e3          	bne	a2,s4,80003240 <balloc+0xee>
    80003274:	b759                	j	800031fa <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	2fa50513          	addi	a0,a0,762 # 80008570 <syscalls+0x110>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	30a080e7          	jalr	778(ra) # 80000588 <printf>
  return 0;
    80003286:	4481                	li	s1,0
    80003288:	bf99                	j	800031de <balloc+0x8c>

000000008000328a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	e052                	sd	s4,0(sp)
    80003298:	1800                	addi	s0,sp,48
    8000329a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000329c:	47ad                	li	a5,11
    8000329e:	02b7e763          	bltu	a5,a1,800032cc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800032a2:	02059493          	slli	s1,a1,0x20
    800032a6:	9081                	srli	s1,s1,0x20
    800032a8:	048a                	slli	s1,s1,0x2
    800032aa:	94aa                	add	s1,s1,a0
    800032ac:	0504a903          	lw	s2,80(s1)
    800032b0:	06091e63          	bnez	s2,8000332c <bmap+0xa2>
      addr = balloc(ip->dev);
    800032b4:	4108                	lw	a0,0(a0)
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	e9c080e7          	jalr	-356(ra) # 80003152 <balloc>
    800032be:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032c2:	06090563          	beqz	s2,8000332c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800032c6:	0524a823          	sw	s2,80(s1)
    800032ca:	a08d                	j	8000332c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032cc:	ff45849b          	addiw	s1,a1,-12
    800032d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032d4:	0ff00793          	li	a5,255
    800032d8:	08e7e563          	bltu	a5,a4,80003362 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032dc:	08052903          	lw	s2,128(a0)
    800032e0:	00091d63          	bnez	s2,800032fa <bmap+0x70>
      addr = balloc(ip->dev);
    800032e4:	4108                	lw	a0,0(a0)
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	e6c080e7          	jalr	-404(ra) # 80003152 <balloc>
    800032ee:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032f2:	02090d63          	beqz	s2,8000332c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032f6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800032fa:	85ca                	mv	a1,s2
    800032fc:	0009a503          	lw	a0,0(s3)
    80003300:	00000097          	auipc	ra,0x0
    80003304:	b90080e7          	jalr	-1136(ra) # 80002e90 <bread>
    80003308:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000330a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000330e:	02049593          	slli	a1,s1,0x20
    80003312:	9181                	srli	a1,a1,0x20
    80003314:	058a                	slli	a1,a1,0x2
    80003316:	00b784b3          	add	s1,a5,a1
    8000331a:	0004a903          	lw	s2,0(s1)
    8000331e:	02090063          	beqz	s2,8000333e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003322:	8552                	mv	a0,s4
    80003324:	00000097          	auipc	ra,0x0
    80003328:	c9c080e7          	jalr	-868(ra) # 80002fc0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000332c:	854a                	mv	a0,s2
    8000332e:	70a2                	ld	ra,40(sp)
    80003330:	7402                	ld	s0,32(sp)
    80003332:	64e2                	ld	s1,24(sp)
    80003334:	6942                	ld	s2,16(sp)
    80003336:	69a2                	ld	s3,8(sp)
    80003338:	6a02                	ld	s4,0(sp)
    8000333a:	6145                	addi	sp,sp,48
    8000333c:	8082                	ret
      addr = balloc(ip->dev);
    8000333e:	0009a503          	lw	a0,0(s3)
    80003342:	00000097          	auipc	ra,0x0
    80003346:	e10080e7          	jalr	-496(ra) # 80003152 <balloc>
    8000334a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000334e:	fc090ae3          	beqz	s2,80003322 <bmap+0x98>
        a[bn] = addr;
    80003352:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003356:	8552                	mv	a0,s4
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	eec080e7          	jalr	-276(ra) # 80004244 <log_write>
    80003360:	b7c9                	j	80003322 <bmap+0x98>
  panic("bmap: out of range");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	22650513          	addi	a0,a0,550 # 80008588 <syscalls+0x128>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080003372 <iget>:
{
    80003372:	7179                	addi	sp,sp,-48
    80003374:	f406                	sd	ra,40(sp)
    80003376:	f022                	sd	s0,32(sp)
    80003378:	ec26                	sd	s1,24(sp)
    8000337a:	e84a                	sd	s2,16(sp)
    8000337c:	e44e                	sd	s3,8(sp)
    8000337e:	e052                	sd	s4,0(sp)
    80003380:	1800                	addi	s0,sp,48
    80003382:	89aa                	mv	s3,a0
    80003384:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003386:	0001c517          	auipc	a0,0x1c
    8000338a:	cf250513          	addi	a0,a0,-782 # 8001f078 <itable>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
  empty = 0;
    80003396:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003398:	0001c497          	auipc	s1,0x1c
    8000339c:	cf848493          	addi	s1,s1,-776 # 8001f090 <itable+0x18>
    800033a0:	0001d697          	auipc	a3,0x1d
    800033a4:	78068693          	addi	a3,a3,1920 # 80020b20 <log>
    800033a8:	a039                	j	800033b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033aa:	02090b63          	beqz	s2,800033e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033ae:	08848493          	addi	s1,s1,136
    800033b2:	02d48a63          	beq	s1,a3,800033e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033b6:	449c                	lw	a5,8(s1)
    800033b8:	fef059e3          	blez	a5,800033aa <iget+0x38>
    800033bc:	4098                	lw	a4,0(s1)
    800033be:	ff3716e3          	bne	a4,s3,800033aa <iget+0x38>
    800033c2:	40d8                	lw	a4,4(s1)
    800033c4:	ff4713e3          	bne	a4,s4,800033aa <iget+0x38>
      ip->ref++;
    800033c8:	2785                	addiw	a5,a5,1
    800033ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033cc:	0001c517          	auipc	a0,0x1c
    800033d0:	cac50513          	addi	a0,a0,-852 # 8001f078 <itable>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
      return ip;
    800033dc:	8926                	mv	s2,s1
    800033de:	a03d                	j	8000340c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e0:	f7f9                	bnez	a5,800033ae <iget+0x3c>
    800033e2:	8926                	mv	s2,s1
    800033e4:	b7e9                	j	800033ae <iget+0x3c>
  if(empty == 0)
    800033e6:	02090c63          	beqz	s2,8000341e <iget+0xac>
  ip->dev = dev;
    800033ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033f2:	4785                	li	a5,1
    800033f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033fc:	0001c517          	auipc	a0,0x1c
    80003400:	c7c50513          	addi	a0,a0,-900 # 8001f078 <itable>
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	886080e7          	jalr	-1914(ra) # 80000c8a <release>
}
    8000340c:	854a                	mv	a0,s2
    8000340e:	70a2                	ld	ra,40(sp)
    80003410:	7402                	ld	s0,32(sp)
    80003412:	64e2                	ld	s1,24(sp)
    80003414:	6942                	ld	s2,16(sp)
    80003416:	69a2                	ld	s3,8(sp)
    80003418:	6a02                	ld	s4,0(sp)
    8000341a:	6145                	addi	sp,sp,48
    8000341c:	8082                	ret
    panic("iget: no inodes");
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	18250513          	addi	a0,a0,386 # 800085a0 <syscalls+0x140>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	118080e7          	jalr	280(ra) # 8000053e <panic>

000000008000342e <fsinit>:
fsinit(int dev) {
    8000342e:	7179                	addi	sp,sp,-48
    80003430:	f406                	sd	ra,40(sp)
    80003432:	f022                	sd	s0,32(sp)
    80003434:	ec26                	sd	s1,24(sp)
    80003436:	e84a                	sd	s2,16(sp)
    80003438:	e44e                	sd	s3,8(sp)
    8000343a:	1800                	addi	s0,sp,48
    8000343c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000343e:	4585                	li	a1,1
    80003440:	00000097          	auipc	ra,0x0
    80003444:	a50080e7          	jalr	-1456(ra) # 80002e90 <bread>
    80003448:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000344a:	0001c997          	auipc	s3,0x1c
    8000344e:	c0e98993          	addi	s3,s3,-1010 # 8001f058 <sb>
    80003452:	02000613          	li	a2,32
    80003456:	05850593          	addi	a1,a0,88
    8000345a:	854e                	mv	a0,s3
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	8d2080e7          	jalr	-1838(ra) # 80000d2e <memmove>
  brelse(bp);
    80003464:	8526                	mv	a0,s1
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	b5a080e7          	jalr	-1190(ra) # 80002fc0 <brelse>
  if(sb.magic != FSMAGIC)
    8000346e:	0009a703          	lw	a4,0(s3)
    80003472:	102037b7          	lui	a5,0x10203
    80003476:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000347a:	02f71263          	bne	a4,a5,8000349e <fsinit+0x70>
  initlog(dev, &sb);
    8000347e:	0001c597          	auipc	a1,0x1c
    80003482:	bda58593          	addi	a1,a1,-1062 # 8001f058 <sb>
    80003486:	854a                	mv	a0,s2
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	b40080e7          	jalr	-1216(ra) # 80003fc8 <initlog>
}
    80003490:	70a2                	ld	ra,40(sp)
    80003492:	7402                	ld	s0,32(sp)
    80003494:	64e2                	ld	s1,24(sp)
    80003496:	6942                	ld	s2,16(sp)
    80003498:	69a2                	ld	s3,8(sp)
    8000349a:	6145                	addi	sp,sp,48
    8000349c:	8082                	ret
    panic("invalid file system");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	11250513          	addi	a0,a0,274 # 800085b0 <syscalls+0x150>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	098080e7          	jalr	152(ra) # 8000053e <panic>

00000000800034ae <iinit>:
{
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034bc:	00005597          	auipc	a1,0x5
    800034c0:	10c58593          	addi	a1,a1,268 # 800085c8 <syscalls+0x168>
    800034c4:	0001c517          	auipc	a0,0x1c
    800034c8:	bb450513          	addi	a0,a0,-1100 # 8001f078 <itable>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	67a080e7          	jalr	1658(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034d4:	0001c497          	auipc	s1,0x1c
    800034d8:	bcc48493          	addi	s1,s1,-1076 # 8001f0a0 <itable+0x28>
    800034dc:	0001d997          	auipc	s3,0x1d
    800034e0:	65498993          	addi	s3,s3,1620 # 80020b30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034e4:	00005917          	auipc	s2,0x5
    800034e8:	0ec90913          	addi	s2,s2,236 # 800085d0 <syscalls+0x170>
    800034ec:	85ca                	mv	a1,s2
    800034ee:	8526                	mv	a0,s1
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	e3a080e7          	jalr	-454(ra) # 8000432a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034f8:	08848493          	addi	s1,s1,136
    800034fc:	ff3498e3          	bne	s1,s3,800034ec <iinit+0x3e>
}
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret

000000008000350e <ialloc>:
{
    8000350e:	715d                	addi	sp,sp,-80
    80003510:	e486                	sd	ra,72(sp)
    80003512:	e0a2                	sd	s0,64(sp)
    80003514:	fc26                	sd	s1,56(sp)
    80003516:	f84a                	sd	s2,48(sp)
    80003518:	f44e                	sd	s3,40(sp)
    8000351a:	f052                	sd	s4,32(sp)
    8000351c:	ec56                	sd	s5,24(sp)
    8000351e:	e85a                	sd	s6,16(sp)
    80003520:	e45e                	sd	s7,8(sp)
    80003522:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003524:	0001c717          	auipc	a4,0x1c
    80003528:	b4072703          	lw	a4,-1216(a4) # 8001f064 <sb+0xc>
    8000352c:	4785                	li	a5,1
    8000352e:	04e7fa63          	bgeu	a5,a4,80003582 <ialloc+0x74>
    80003532:	8aaa                	mv	s5,a0
    80003534:	8bae                	mv	s7,a1
    80003536:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003538:	0001ca17          	auipc	s4,0x1c
    8000353c:	b20a0a13          	addi	s4,s4,-1248 # 8001f058 <sb>
    80003540:	00048b1b          	sext.w	s6,s1
    80003544:	0044d793          	srli	a5,s1,0x4
    80003548:	018a2583          	lw	a1,24(s4)
    8000354c:	9dbd                	addw	a1,a1,a5
    8000354e:	8556                	mv	a0,s5
    80003550:	00000097          	auipc	ra,0x0
    80003554:	940080e7          	jalr	-1728(ra) # 80002e90 <bread>
    80003558:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000355a:	05850993          	addi	s3,a0,88
    8000355e:	00f4f793          	andi	a5,s1,15
    80003562:	079a                	slli	a5,a5,0x6
    80003564:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003566:	00099783          	lh	a5,0(s3)
    8000356a:	c3a1                	beqz	a5,800035aa <ialloc+0x9c>
    brelse(bp);
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	a54080e7          	jalr	-1452(ra) # 80002fc0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003574:	0485                	addi	s1,s1,1
    80003576:	00ca2703          	lw	a4,12(s4)
    8000357a:	0004879b          	sext.w	a5,s1
    8000357e:	fce7e1e3          	bltu	a5,a4,80003540 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	05650513          	addi	a0,a0,86 # 800085d8 <syscalls+0x178>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	ffe080e7          	jalr	-2(ra) # 80000588 <printf>
  return 0;
    80003592:	4501                	li	a0,0
}
    80003594:	60a6                	ld	ra,72(sp)
    80003596:	6406                	ld	s0,64(sp)
    80003598:	74e2                	ld	s1,56(sp)
    8000359a:	7942                	ld	s2,48(sp)
    8000359c:	79a2                	ld	s3,40(sp)
    8000359e:	7a02                	ld	s4,32(sp)
    800035a0:	6ae2                	ld	s5,24(sp)
    800035a2:	6b42                	ld	s6,16(sp)
    800035a4:	6ba2                	ld	s7,8(sp)
    800035a6:	6161                	addi	sp,sp,80
    800035a8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035aa:	04000613          	li	a2,64
    800035ae:	4581                	li	a1,0
    800035b0:	854e                	mv	a0,s3
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	720080e7          	jalr	1824(ra) # 80000cd2 <memset>
      dip->type = type;
    800035ba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035be:	854a                	mv	a0,s2
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	c84080e7          	jalr	-892(ra) # 80004244 <log_write>
      brelse(bp);
    800035c8:	854a                	mv	a0,s2
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	9f6080e7          	jalr	-1546(ra) # 80002fc0 <brelse>
      return iget(dev, inum);
    800035d2:	85da                	mv	a1,s6
    800035d4:	8556                	mv	a0,s5
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	d9c080e7          	jalr	-612(ra) # 80003372 <iget>
    800035de:	bf5d                	j	80003594 <ialloc+0x86>

00000000800035e0 <iupdate>:
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ee:	415c                	lw	a5,4(a0)
    800035f0:	0047d79b          	srliw	a5,a5,0x4
    800035f4:	0001c597          	auipc	a1,0x1c
    800035f8:	a7c5a583          	lw	a1,-1412(a1) # 8001f070 <sb+0x18>
    800035fc:	9dbd                	addw	a1,a1,a5
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	890080e7          	jalr	-1904(ra) # 80002e90 <bread>
    80003608:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000360a:	05850793          	addi	a5,a0,88
    8000360e:	40c8                	lw	a0,4(s1)
    80003610:	893d                	andi	a0,a0,15
    80003612:	051a                	slli	a0,a0,0x6
    80003614:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003616:	04449703          	lh	a4,68(s1)
    8000361a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000361e:	04649703          	lh	a4,70(s1)
    80003622:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003626:	04849703          	lh	a4,72(s1)
    8000362a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000362e:	04a49703          	lh	a4,74(s1)
    80003632:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003636:	44f8                	lw	a4,76(s1)
    80003638:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000363a:	03400613          	li	a2,52
    8000363e:	05048593          	addi	a1,s1,80
    80003642:	0531                	addi	a0,a0,12
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	6ea080e7          	jalr	1770(ra) # 80000d2e <memmove>
  log_write(bp);
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	bf6080e7          	jalr	-1034(ra) # 80004244 <log_write>
  brelse(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	968080e7          	jalr	-1688(ra) # 80002fc0 <brelse>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6902                	ld	s2,0(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret

000000008000366c <idup>:
{
    8000366c:	1101                	addi	sp,sp,-32
    8000366e:	ec06                	sd	ra,24(sp)
    80003670:	e822                	sd	s0,16(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	1000                	addi	s0,sp,32
    80003676:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003678:	0001c517          	auipc	a0,0x1c
    8000367c:	a0050513          	addi	a0,a0,-1536 # 8001f078 <itable>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	556080e7          	jalr	1366(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003688:	449c                	lw	a5,8(s1)
    8000368a:	2785                	addiw	a5,a5,1
    8000368c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000368e:	0001c517          	auipc	a0,0x1c
    80003692:	9ea50513          	addi	a0,a0,-1558 # 8001f078 <itable>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	5f4080e7          	jalr	1524(ra) # 80000c8a <release>
}
    8000369e:	8526                	mv	a0,s1
    800036a0:	60e2                	ld	ra,24(sp)
    800036a2:	6442                	ld	s0,16(sp)
    800036a4:	64a2                	ld	s1,8(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret

00000000800036aa <ilock>:
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	e04a                	sd	s2,0(sp)
    800036b4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036b6:	c115                	beqz	a0,800036da <ilock+0x30>
    800036b8:	84aa                	mv	s1,a0
    800036ba:	451c                	lw	a5,8(a0)
    800036bc:	00f05f63          	blez	a5,800036da <ilock+0x30>
  acquiresleep(&ip->lock);
    800036c0:	0541                	addi	a0,a0,16
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	ca2080e7          	jalr	-862(ra) # 80004364 <acquiresleep>
  if(ip->valid == 0){
    800036ca:	40bc                	lw	a5,64(s1)
    800036cc:	cf99                	beqz	a5,800036ea <ilock+0x40>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6902                	ld	s2,0(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("ilock");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	f1650513          	addi	a0,a0,-234 # 800085f0 <syscalls+0x190>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e5c080e7          	jalr	-420(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ea:	40dc                	lw	a5,4(s1)
    800036ec:	0047d79b          	srliw	a5,a5,0x4
    800036f0:	0001c597          	auipc	a1,0x1c
    800036f4:	9805a583          	lw	a1,-1664(a1) # 8001f070 <sb+0x18>
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	4088                	lw	a0,0(s1)
    800036fc:	fffff097          	auipc	ra,0xfffff
    80003700:	794080e7          	jalr	1940(ra) # 80002e90 <bread>
    80003704:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003706:	05850593          	addi	a1,a0,88
    8000370a:	40dc                	lw	a5,4(s1)
    8000370c:	8bbd                	andi	a5,a5,15
    8000370e:	079a                	slli	a5,a5,0x6
    80003710:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003712:	00059783          	lh	a5,0(a1)
    80003716:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000371a:	00259783          	lh	a5,2(a1)
    8000371e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003722:	00459783          	lh	a5,4(a1)
    80003726:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000372a:	00659783          	lh	a5,6(a1)
    8000372e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003732:	459c                	lw	a5,8(a1)
    80003734:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003736:	03400613          	li	a2,52
    8000373a:	05b1                	addi	a1,a1,12
    8000373c:	05048513          	addi	a0,s1,80
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	5ee080e7          	jalr	1518(ra) # 80000d2e <memmove>
    brelse(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	876080e7          	jalr	-1930(ra) # 80002fc0 <brelse>
    ip->valid = 1;
    80003752:	4785                	li	a5,1
    80003754:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003756:	04449783          	lh	a5,68(s1)
    8000375a:	fbb5                	bnez	a5,800036ce <ilock+0x24>
      panic("ilock: no type");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	e9c50513          	addi	a0,a0,-356 # 800085f8 <syscalls+0x198>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>

000000008000376c <iunlock>:
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	e04a                	sd	s2,0(sp)
    80003776:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003778:	c905                	beqz	a0,800037a8 <iunlock+0x3c>
    8000377a:	84aa                	mv	s1,a0
    8000377c:	01050913          	addi	s2,a0,16
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	c7c080e7          	jalr	-900(ra) # 800043fe <holdingsleep>
    8000378a:	cd19                	beqz	a0,800037a8 <iunlock+0x3c>
    8000378c:	449c                	lw	a5,8(s1)
    8000378e:	00f05d63          	blez	a5,800037a8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	c26080e7          	jalr	-986(ra) # 800043ba <releasesleep>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6902                	ld	s2,0(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret
    panic("iunlock");
    800037a8:	00005517          	auipc	a0,0x5
    800037ac:	e6050513          	addi	a0,a0,-416 # 80008608 <syscalls+0x1a8>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>

00000000800037b8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037b8:	7179                	addi	sp,sp,-48
    800037ba:	f406                	sd	ra,40(sp)
    800037bc:	f022                	sd	s0,32(sp)
    800037be:	ec26                	sd	s1,24(sp)
    800037c0:	e84a                	sd	s2,16(sp)
    800037c2:	e44e                	sd	s3,8(sp)
    800037c4:	e052                	sd	s4,0(sp)
    800037c6:	1800                	addi	s0,sp,48
    800037c8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037ca:	05050493          	addi	s1,a0,80
    800037ce:	08050913          	addi	s2,a0,128
    800037d2:	a021                	j	800037da <itrunc+0x22>
    800037d4:	0491                	addi	s1,s1,4
    800037d6:	01248d63          	beq	s1,s2,800037f0 <itrunc+0x38>
    if(ip->addrs[i]){
    800037da:	408c                	lw	a1,0(s1)
    800037dc:	dde5                	beqz	a1,800037d4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037de:	0009a503          	lw	a0,0(s3)
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	8f4080e7          	jalr	-1804(ra) # 800030d6 <bfree>
      ip->addrs[i] = 0;
    800037ea:	0004a023          	sw	zero,0(s1)
    800037ee:	b7dd                	j	800037d4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037f0:	0809a583          	lw	a1,128(s3)
    800037f4:	e185                	bnez	a1,80003814 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037f6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037fa:	854e                	mv	a0,s3
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	de4080e7          	jalr	-540(ra) # 800035e0 <iupdate>
}
    80003804:	70a2                	ld	ra,40(sp)
    80003806:	7402                	ld	s0,32(sp)
    80003808:	64e2                	ld	s1,24(sp)
    8000380a:	6942                	ld	s2,16(sp)
    8000380c:	69a2                	ld	s3,8(sp)
    8000380e:	6a02                	ld	s4,0(sp)
    80003810:	6145                	addi	sp,sp,48
    80003812:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003814:	0009a503          	lw	a0,0(s3)
    80003818:	fffff097          	auipc	ra,0xfffff
    8000381c:	678080e7          	jalr	1656(ra) # 80002e90 <bread>
    80003820:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003822:	05850493          	addi	s1,a0,88
    80003826:	45850913          	addi	s2,a0,1112
    8000382a:	a021                	j	80003832 <itrunc+0x7a>
    8000382c:	0491                	addi	s1,s1,4
    8000382e:	01248b63          	beq	s1,s2,80003844 <itrunc+0x8c>
      if(a[j])
    80003832:	408c                	lw	a1,0(s1)
    80003834:	dde5                	beqz	a1,8000382c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003836:	0009a503          	lw	a0,0(s3)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	89c080e7          	jalr	-1892(ra) # 800030d6 <bfree>
    80003842:	b7ed                	j	8000382c <itrunc+0x74>
    brelse(bp);
    80003844:	8552                	mv	a0,s4
    80003846:	fffff097          	auipc	ra,0xfffff
    8000384a:	77a080e7          	jalr	1914(ra) # 80002fc0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000384e:	0809a583          	lw	a1,128(s3)
    80003852:	0009a503          	lw	a0,0(s3)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	880080e7          	jalr	-1920(ra) # 800030d6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000385e:	0809a023          	sw	zero,128(s3)
    80003862:	bf51                	j	800037f6 <itrunc+0x3e>

0000000080003864 <iput>:
{
    80003864:	1101                	addi	sp,sp,-32
    80003866:	ec06                	sd	ra,24(sp)
    80003868:	e822                	sd	s0,16(sp)
    8000386a:	e426                	sd	s1,8(sp)
    8000386c:	e04a                	sd	s2,0(sp)
    8000386e:	1000                	addi	s0,sp,32
    80003870:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003872:	0001c517          	auipc	a0,0x1c
    80003876:	80650513          	addi	a0,a0,-2042 # 8001f078 <itable>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	35c080e7          	jalr	860(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003882:	4498                	lw	a4,8(s1)
    80003884:	4785                	li	a5,1
    80003886:	02f70363          	beq	a4,a5,800038ac <iput+0x48>
  ip->ref--;
    8000388a:	449c                	lw	a5,8(s1)
    8000388c:	37fd                	addiw	a5,a5,-1
    8000388e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003890:	0001b517          	auipc	a0,0x1b
    80003894:	7e850513          	addi	a0,a0,2024 # 8001f078 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	3f2080e7          	jalr	1010(ra) # 80000c8a <release>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ac:	40bc                	lw	a5,64(s1)
    800038ae:	dff1                	beqz	a5,8000388a <iput+0x26>
    800038b0:	04a49783          	lh	a5,74(s1)
    800038b4:	fbf9                	bnez	a5,8000388a <iput+0x26>
    acquiresleep(&ip->lock);
    800038b6:	01048913          	addi	s2,s1,16
    800038ba:	854a                	mv	a0,s2
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	aa8080e7          	jalr	-1368(ra) # 80004364 <acquiresleep>
    release(&itable.lock);
    800038c4:	0001b517          	auipc	a0,0x1b
    800038c8:	7b450513          	addi	a0,a0,1972 # 8001f078 <itable>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	3be080e7          	jalr	958(ra) # 80000c8a <release>
    itrunc(ip);
    800038d4:	8526                	mv	a0,s1
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	ee2080e7          	jalr	-286(ra) # 800037b8 <itrunc>
    ip->type = 0;
    800038de:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038e2:	8526                	mv	a0,s1
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	cfc080e7          	jalr	-772(ra) # 800035e0 <iupdate>
    ip->valid = 0;
    800038ec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	ac8080e7          	jalr	-1336(ra) # 800043ba <releasesleep>
    acquire(&itable.lock);
    800038fa:	0001b517          	auipc	a0,0x1b
    800038fe:	77e50513          	addi	a0,a0,1918 # 8001f078 <itable>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	2d4080e7          	jalr	724(ra) # 80000bd6 <acquire>
    8000390a:	b741                	j	8000388a <iput+0x26>

000000008000390c <iunlockput>:
{
    8000390c:	1101                	addi	sp,sp,-32
    8000390e:	ec06                	sd	ra,24(sp)
    80003910:	e822                	sd	s0,16(sp)
    80003912:	e426                	sd	s1,8(sp)
    80003914:	1000                	addi	s0,sp,32
    80003916:	84aa                	mv	s1,a0
  iunlock(ip);
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	e54080e7          	jalr	-428(ra) # 8000376c <iunlock>
  iput(ip);
    80003920:	8526                	mv	a0,s1
    80003922:	00000097          	auipc	ra,0x0
    80003926:	f42080e7          	jalr	-190(ra) # 80003864 <iput>
}
    8000392a:	60e2                	ld	ra,24(sp)
    8000392c:	6442                	ld	s0,16(sp)
    8000392e:	64a2                	ld	s1,8(sp)
    80003930:	6105                	addi	sp,sp,32
    80003932:	8082                	ret

0000000080003934 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003934:	1141                	addi	sp,sp,-16
    80003936:	e422                	sd	s0,8(sp)
    80003938:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000393a:	411c                	lw	a5,0(a0)
    8000393c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000393e:	415c                	lw	a5,4(a0)
    80003940:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003942:	04451783          	lh	a5,68(a0)
    80003946:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000394a:	04a51783          	lh	a5,74(a0)
    8000394e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003952:	04c56783          	lwu	a5,76(a0)
    80003956:	e99c                	sd	a5,16(a1)
}
    80003958:	6422                	ld	s0,8(sp)
    8000395a:	0141                	addi	sp,sp,16
    8000395c:	8082                	ret

000000008000395e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000395e:	457c                	lw	a5,76(a0)
    80003960:	0ed7e963          	bltu	a5,a3,80003a52 <readi+0xf4>
{
    80003964:	7159                	addi	sp,sp,-112
    80003966:	f486                	sd	ra,104(sp)
    80003968:	f0a2                	sd	s0,96(sp)
    8000396a:	eca6                	sd	s1,88(sp)
    8000396c:	e8ca                	sd	s2,80(sp)
    8000396e:	e4ce                	sd	s3,72(sp)
    80003970:	e0d2                	sd	s4,64(sp)
    80003972:	fc56                	sd	s5,56(sp)
    80003974:	f85a                	sd	s6,48(sp)
    80003976:	f45e                	sd	s7,40(sp)
    80003978:	f062                	sd	s8,32(sp)
    8000397a:	ec66                	sd	s9,24(sp)
    8000397c:	e86a                	sd	s10,16(sp)
    8000397e:	e46e                	sd	s11,8(sp)
    80003980:	1880                	addi	s0,sp,112
    80003982:	8b2a                	mv	s6,a0
    80003984:	8bae                	mv	s7,a1
    80003986:	8a32                	mv	s4,a2
    80003988:	84b6                	mv	s1,a3
    8000398a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000398c:	9f35                	addw	a4,a4,a3
    return 0;
    8000398e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003990:	0ad76063          	bltu	a4,a3,80003a30 <readi+0xd2>
  if(off + n > ip->size)
    80003994:	00e7f463          	bgeu	a5,a4,8000399c <readi+0x3e>
    n = ip->size - off;
    80003998:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399c:	0a0a8963          	beqz	s5,80003a4e <readi+0xf0>
    800039a0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039a6:	5c7d                	li	s8,-1
    800039a8:	a82d                	j	800039e2 <readi+0x84>
    800039aa:	020d1d93          	slli	s11,s10,0x20
    800039ae:	020ddd93          	srli	s11,s11,0x20
    800039b2:	05890793          	addi	a5,s2,88
    800039b6:	86ee                	mv	a3,s11
    800039b8:	963e                	add	a2,a2,a5
    800039ba:	85d2                	mv	a1,s4
    800039bc:	855e                	mv	a0,s7
    800039be:	fffff097          	auipc	ra,0xfffff
    800039c2:	a9e080e7          	jalr	-1378(ra) # 8000245c <either_copyout>
    800039c6:	05850d63          	beq	a0,s8,80003a20 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039ca:	854a                	mv	a0,s2
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	5f4080e7          	jalr	1524(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d4:	013d09bb          	addw	s3,s10,s3
    800039d8:	009d04bb          	addw	s1,s10,s1
    800039dc:	9a6e                	add	s4,s4,s11
    800039de:	0559f763          	bgeu	s3,s5,80003a2c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039e2:	00a4d59b          	srliw	a1,s1,0xa
    800039e6:	855a                	mv	a0,s6
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	8a2080e7          	jalr	-1886(ra) # 8000328a <bmap>
    800039f0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039f4:	cd85                	beqz	a1,80003a2c <readi+0xce>
    bp = bread(ip->dev, addr);
    800039f6:	000b2503          	lw	a0,0(s6)
    800039fa:	fffff097          	auipc	ra,0xfffff
    800039fe:	496080e7          	jalr	1174(ra) # 80002e90 <bread>
    80003a02:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a04:	3ff4f613          	andi	a2,s1,1023
    80003a08:	40cc87bb          	subw	a5,s9,a2
    80003a0c:	413a873b          	subw	a4,s5,s3
    80003a10:	8d3e                	mv	s10,a5
    80003a12:	2781                	sext.w	a5,a5
    80003a14:	0007069b          	sext.w	a3,a4
    80003a18:	f8f6f9e3          	bgeu	a3,a5,800039aa <readi+0x4c>
    80003a1c:	8d3a                	mv	s10,a4
    80003a1e:	b771                	j	800039aa <readi+0x4c>
      brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	59e080e7          	jalr	1438(ra) # 80002fc0 <brelse>
      tot = -1;
    80003a2a:	59fd                	li	s3,-1
  }
  return tot;
    80003a2c:	0009851b          	sext.w	a0,s3
}
    80003a30:	70a6                	ld	ra,104(sp)
    80003a32:	7406                	ld	s0,96(sp)
    80003a34:	64e6                	ld	s1,88(sp)
    80003a36:	6946                	ld	s2,80(sp)
    80003a38:	69a6                	ld	s3,72(sp)
    80003a3a:	6a06                	ld	s4,64(sp)
    80003a3c:	7ae2                	ld	s5,56(sp)
    80003a3e:	7b42                	ld	s6,48(sp)
    80003a40:	7ba2                	ld	s7,40(sp)
    80003a42:	7c02                	ld	s8,32(sp)
    80003a44:	6ce2                	ld	s9,24(sp)
    80003a46:	6d42                	ld	s10,16(sp)
    80003a48:	6da2                	ld	s11,8(sp)
    80003a4a:	6165                	addi	sp,sp,112
    80003a4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	89d6                	mv	s3,s5
    80003a50:	bff1                	j	80003a2c <readi+0xce>
    return 0;
    80003a52:	4501                	li	a0,0
}
    80003a54:	8082                	ret

0000000080003a56 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a56:	457c                	lw	a5,76(a0)
    80003a58:	10d7e863          	bltu	a5,a3,80003b68 <writei+0x112>
{
    80003a5c:	7159                	addi	sp,sp,-112
    80003a5e:	f486                	sd	ra,104(sp)
    80003a60:	f0a2                	sd	s0,96(sp)
    80003a62:	eca6                	sd	s1,88(sp)
    80003a64:	e8ca                	sd	s2,80(sp)
    80003a66:	e4ce                	sd	s3,72(sp)
    80003a68:	e0d2                	sd	s4,64(sp)
    80003a6a:	fc56                	sd	s5,56(sp)
    80003a6c:	f85a                	sd	s6,48(sp)
    80003a6e:	f45e                	sd	s7,40(sp)
    80003a70:	f062                	sd	s8,32(sp)
    80003a72:	ec66                	sd	s9,24(sp)
    80003a74:	e86a                	sd	s10,16(sp)
    80003a76:	e46e                	sd	s11,8(sp)
    80003a78:	1880                	addi	s0,sp,112
    80003a7a:	8aaa                	mv	s5,a0
    80003a7c:	8bae                	mv	s7,a1
    80003a7e:	8a32                	mv	s4,a2
    80003a80:	8936                	mv	s2,a3
    80003a82:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a84:	00e687bb          	addw	a5,a3,a4
    80003a88:	0ed7e263          	bltu	a5,a3,80003b6c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a8c:	00043737          	lui	a4,0x43
    80003a90:	0ef76063          	bltu	a4,a5,80003b70 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a94:	0c0b0863          	beqz	s6,80003b64 <writei+0x10e>
    80003a98:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a9e:	5c7d                	li	s8,-1
    80003aa0:	a091                	j	80003ae4 <writei+0x8e>
    80003aa2:	020d1d93          	slli	s11,s10,0x20
    80003aa6:	020ddd93          	srli	s11,s11,0x20
    80003aaa:	05848793          	addi	a5,s1,88
    80003aae:	86ee                	mv	a3,s11
    80003ab0:	8652                	mv	a2,s4
    80003ab2:	85de                	mv	a1,s7
    80003ab4:	953e                	add	a0,a0,a5
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	9fc080e7          	jalr	-1540(ra) # 800024b2 <either_copyin>
    80003abe:	07850263          	beq	a0,s8,80003b22 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ac2:	8526                	mv	a0,s1
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	780080e7          	jalr	1920(ra) # 80004244 <log_write>
    brelse(bp);
    80003acc:	8526                	mv	a0,s1
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	4f2080e7          	jalr	1266(ra) # 80002fc0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad6:	013d09bb          	addw	s3,s10,s3
    80003ada:	012d093b          	addw	s2,s10,s2
    80003ade:	9a6e                	add	s4,s4,s11
    80003ae0:	0569f663          	bgeu	s3,s6,80003b2c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ae4:	00a9559b          	srliw	a1,s2,0xa
    80003ae8:	8556                	mv	a0,s5
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	7a0080e7          	jalr	1952(ra) # 8000328a <bmap>
    80003af2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af6:	c99d                	beqz	a1,80003b2c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003af8:	000aa503          	lw	a0,0(s5)
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	394080e7          	jalr	916(ra) # 80002e90 <bread>
    80003b04:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b06:	3ff97513          	andi	a0,s2,1023
    80003b0a:	40ac87bb          	subw	a5,s9,a0
    80003b0e:	413b073b          	subw	a4,s6,s3
    80003b12:	8d3e                	mv	s10,a5
    80003b14:	2781                	sext.w	a5,a5
    80003b16:	0007069b          	sext.w	a3,a4
    80003b1a:	f8f6f4e3          	bgeu	a3,a5,80003aa2 <writei+0x4c>
    80003b1e:	8d3a                	mv	s10,a4
    80003b20:	b749                	j	80003aa2 <writei+0x4c>
      brelse(bp);
    80003b22:	8526                	mv	a0,s1
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	49c080e7          	jalr	1180(ra) # 80002fc0 <brelse>
  }

  if(off > ip->size)
    80003b2c:	04caa783          	lw	a5,76(s5)
    80003b30:	0127f463          	bgeu	a5,s2,80003b38 <writei+0xe2>
    ip->size = off;
    80003b34:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b38:	8556                	mv	a0,s5
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	aa6080e7          	jalr	-1370(ra) # 800035e0 <iupdate>

  return tot;
    80003b42:	0009851b          	sext.w	a0,s3
}
    80003b46:	70a6                	ld	ra,104(sp)
    80003b48:	7406                	ld	s0,96(sp)
    80003b4a:	64e6                	ld	s1,88(sp)
    80003b4c:	6946                	ld	s2,80(sp)
    80003b4e:	69a6                	ld	s3,72(sp)
    80003b50:	6a06                	ld	s4,64(sp)
    80003b52:	7ae2                	ld	s5,56(sp)
    80003b54:	7b42                	ld	s6,48(sp)
    80003b56:	7ba2                	ld	s7,40(sp)
    80003b58:	7c02                	ld	s8,32(sp)
    80003b5a:	6ce2                	ld	s9,24(sp)
    80003b5c:	6d42                	ld	s10,16(sp)
    80003b5e:	6da2                	ld	s11,8(sp)
    80003b60:	6165                	addi	sp,sp,112
    80003b62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	89da                	mv	s3,s6
    80003b66:	bfc9                	j	80003b38 <writei+0xe2>
    return -1;
    80003b68:	557d                	li	a0,-1
}
    80003b6a:	8082                	ret
    return -1;
    80003b6c:	557d                	li	a0,-1
    80003b6e:	bfe1                	j	80003b46 <writei+0xf0>
    return -1;
    80003b70:	557d                	li	a0,-1
    80003b72:	bfd1                	j	80003b46 <writei+0xf0>

0000000080003b74 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b74:	1141                	addi	sp,sp,-16
    80003b76:	e406                	sd	ra,8(sp)
    80003b78:	e022                	sd	s0,0(sp)
    80003b7a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b7c:	4639                	li	a2,14
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	224080e7          	jalr	548(ra) # 80000da2 <strncmp>
}
    80003b86:	60a2                	ld	ra,8(sp)
    80003b88:	6402                	ld	s0,0(sp)
    80003b8a:	0141                	addi	sp,sp,16
    80003b8c:	8082                	ret

0000000080003b8e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b8e:	7139                	addi	sp,sp,-64
    80003b90:	fc06                	sd	ra,56(sp)
    80003b92:	f822                	sd	s0,48(sp)
    80003b94:	f426                	sd	s1,40(sp)
    80003b96:	f04a                	sd	s2,32(sp)
    80003b98:	ec4e                	sd	s3,24(sp)
    80003b9a:	e852                	sd	s4,16(sp)
    80003b9c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b9e:	04451703          	lh	a4,68(a0)
    80003ba2:	4785                	li	a5,1
    80003ba4:	00f71a63          	bne	a4,a5,80003bb8 <dirlookup+0x2a>
    80003ba8:	892a                	mv	s2,a0
    80003baa:	89ae                	mv	s3,a1
    80003bac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bae:	457c                	lw	a5,76(a0)
    80003bb0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bb2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb4:	e79d                	bnez	a5,80003be2 <dirlookup+0x54>
    80003bb6:	a8a5                	j	80003c2e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	a5850513          	addi	a0,a0,-1448 # 80008610 <syscalls+0x1b0>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	97e080e7          	jalr	-1666(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	a6050513          	addi	a0,a0,-1440 # 80008628 <syscalls+0x1c8>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd8:	24c1                	addiw	s1,s1,16
    80003bda:	04c92783          	lw	a5,76(s2)
    80003bde:	04f4f763          	bgeu	s1,a5,80003c2c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003be2:	4741                	li	a4,16
    80003be4:	86a6                	mv	a3,s1
    80003be6:	fc040613          	addi	a2,s0,-64
    80003bea:	4581                	li	a1,0
    80003bec:	854a                	mv	a0,s2
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	d70080e7          	jalr	-656(ra) # 8000395e <readi>
    80003bf6:	47c1                	li	a5,16
    80003bf8:	fcf518e3          	bne	a0,a5,80003bc8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bfc:	fc045783          	lhu	a5,-64(s0)
    80003c00:	dfe1                	beqz	a5,80003bd8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c02:	fc240593          	addi	a1,s0,-62
    80003c06:	854e                	mv	a0,s3
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	f6c080e7          	jalr	-148(ra) # 80003b74 <namecmp>
    80003c10:	f561                	bnez	a0,80003bd8 <dirlookup+0x4a>
      if(poff)
    80003c12:	000a0463          	beqz	s4,80003c1a <dirlookup+0x8c>
        *poff = off;
    80003c16:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c1a:	fc045583          	lhu	a1,-64(s0)
    80003c1e:	00092503          	lw	a0,0(s2)
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	750080e7          	jalr	1872(ra) # 80003372 <iget>
    80003c2a:	a011                	j	80003c2e <dirlookup+0xa0>
  return 0;
    80003c2c:	4501                	li	a0,0
}
    80003c2e:	70e2                	ld	ra,56(sp)
    80003c30:	7442                	ld	s0,48(sp)
    80003c32:	74a2                	ld	s1,40(sp)
    80003c34:	7902                	ld	s2,32(sp)
    80003c36:	69e2                	ld	s3,24(sp)
    80003c38:	6a42                	ld	s4,16(sp)
    80003c3a:	6121                	addi	sp,sp,64
    80003c3c:	8082                	ret

0000000080003c3e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c3e:	711d                	addi	sp,sp,-96
    80003c40:	ec86                	sd	ra,88(sp)
    80003c42:	e8a2                	sd	s0,80(sp)
    80003c44:	e4a6                	sd	s1,72(sp)
    80003c46:	e0ca                	sd	s2,64(sp)
    80003c48:	fc4e                	sd	s3,56(sp)
    80003c4a:	f852                	sd	s4,48(sp)
    80003c4c:	f456                	sd	s5,40(sp)
    80003c4e:	f05a                	sd	s6,32(sp)
    80003c50:	ec5e                	sd	s7,24(sp)
    80003c52:	e862                	sd	s8,16(sp)
    80003c54:	e466                	sd	s9,8(sp)
    80003c56:	1080                	addi	s0,sp,96
    80003c58:	84aa                	mv	s1,a0
    80003c5a:	8aae                	mv	s5,a1
    80003c5c:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c5e:	00054703          	lbu	a4,0(a0)
    80003c62:	02f00793          	li	a5,47
    80003c66:	02f70363          	beq	a4,a5,80003c8c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c6a:	ffffe097          	auipc	ra,0xffffe
    80003c6e:	d42080e7          	jalr	-702(ra) # 800019ac <myproc>
    80003c72:	15053503          	ld	a0,336(a0)
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	9f6080e7          	jalr	-1546(ra) # 8000366c <idup>
    80003c7e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c80:	02f00913          	li	s2,47
  len = path - s;
    80003c84:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c86:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c88:	4b85                	li	s7,1
    80003c8a:	a865                	j	80003d42 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c8c:	4585                	li	a1,1
    80003c8e:	4505                	li	a0,1
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	6e2080e7          	jalr	1762(ra) # 80003372 <iget>
    80003c98:	89aa                	mv	s3,a0
    80003c9a:	b7dd                	j	80003c80 <namex+0x42>
      iunlockput(ip);
    80003c9c:	854e                	mv	a0,s3
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	c6e080e7          	jalr	-914(ra) # 8000390c <iunlockput>
      return 0;
    80003ca6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ca8:	854e                	mv	a0,s3
    80003caa:	60e6                	ld	ra,88(sp)
    80003cac:	6446                	ld	s0,80(sp)
    80003cae:	64a6                	ld	s1,72(sp)
    80003cb0:	6906                	ld	s2,64(sp)
    80003cb2:	79e2                	ld	s3,56(sp)
    80003cb4:	7a42                	ld	s4,48(sp)
    80003cb6:	7aa2                	ld	s5,40(sp)
    80003cb8:	7b02                	ld	s6,32(sp)
    80003cba:	6be2                	ld	s7,24(sp)
    80003cbc:	6c42                	ld	s8,16(sp)
    80003cbe:	6ca2                	ld	s9,8(sp)
    80003cc0:	6125                	addi	sp,sp,96
    80003cc2:	8082                	ret
      iunlock(ip);
    80003cc4:	854e                	mv	a0,s3
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	aa6080e7          	jalr	-1370(ra) # 8000376c <iunlock>
      return ip;
    80003cce:	bfe9                	j	80003ca8 <namex+0x6a>
      iunlockput(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	c3a080e7          	jalr	-966(ra) # 8000390c <iunlockput>
      return 0;
    80003cda:	89e6                	mv	s3,s9
    80003cdc:	b7f1                	j	80003ca8 <namex+0x6a>
  len = path - s;
    80003cde:	40b48633          	sub	a2,s1,a1
    80003ce2:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ce6:	099c5463          	bge	s8,s9,80003d6e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cea:	4639                	li	a2,14
    80003cec:	8552                	mv	a0,s4
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	040080e7          	jalr	64(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003cf6:	0004c783          	lbu	a5,0(s1)
    80003cfa:	01279763          	bne	a5,s2,80003d08 <namex+0xca>
    path++;
    80003cfe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d00:	0004c783          	lbu	a5,0(s1)
    80003d04:	ff278de3          	beq	a5,s2,80003cfe <namex+0xc0>
    ilock(ip);
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	9a0080e7          	jalr	-1632(ra) # 800036aa <ilock>
    if(ip->type != T_DIR){
    80003d12:	04499783          	lh	a5,68(s3)
    80003d16:	f97793e3          	bne	a5,s7,80003c9c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d1a:	000a8563          	beqz	s5,80003d24 <namex+0xe6>
    80003d1e:	0004c783          	lbu	a5,0(s1)
    80003d22:	d3cd                	beqz	a5,80003cc4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d24:	865a                	mv	a2,s6
    80003d26:	85d2                	mv	a1,s4
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	e64080e7          	jalr	-412(ra) # 80003b8e <dirlookup>
    80003d32:	8caa                	mv	s9,a0
    80003d34:	dd51                	beqz	a0,80003cd0 <namex+0x92>
    iunlockput(ip);
    80003d36:	854e                	mv	a0,s3
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	bd4080e7          	jalr	-1068(ra) # 8000390c <iunlockput>
    ip = next;
    80003d40:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d42:	0004c783          	lbu	a5,0(s1)
    80003d46:	05279763          	bne	a5,s2,80003d94 <namex+0x156>
    path++;
    80003d4a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d4c:	0004c783          	lbu	a5,0(s1)
    80003d50:	ff278de3          	beq	a5,s2,80003d4a <namex+0x10c>
  if(*path == 0)
    80003d54:	c79d                	beqz	a5,80003d82 <namex+0x144>
    path++;
    80003d56:	85a6                	mv	a1,s1
  len = path - s;
    80003d58:	8cda                	mv	s9,s6
    80003d5a:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d5c:	01278963          	beq	a5,s2,80003d6e <namex+0x130>
    80003d60:	dfbd                	beqz	a5,80003cde <namex+0xa0>
    path++;
    80003d62:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d64:	0004c783          	lbu	a5,0(s1)
    80003d68:	ff279ce3          	bne	a5,s2,80003d60 <namex+0x122>
    80003d6c:	bf8d                	j	80003cde <namex+0xa0>
    memmove(name, s, len);
    80003d6e:	2601                	sext.w	a2,a2
    80003d70:	8552                	mv	a0,s4
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	fbc080e7          	jalr	-68(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d7a:	9cd2                	add	s9,s9,s4
    80003d7c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d80:	bf9d                	j	80003cf6 <namex+0xb8>
  if(nameiparent){
    80003d82:	f20a83e3          	beqz	s5,80003ca8 <namex+0x6a>
    iput(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	adc080e7          	jalr	-1316(ra) # 80003864 <iput>
    return 0;
    80003d90:	4981                	li	s3,0
    80003d92:	bf19                	j	80003ca8 <namex+0x6a>
  if(*path == 0)
    80003d94:	d7fd                	beqz	a5,80003d82 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	85a6                	mv	a1,s1
    80003d9c:	b7d1                	j	80003d60 <namex+0x122>

0000000080003d9e <dirlink>:
{
    80003d9e:	7139                	addi	sp,sp,-64
    80003da0:	fc06                	sd	ra,56(sp)
    80003da2:	f822                	sd	s0,48(sp)
    80003da4:	f426                	sd	s1,40(sp)
    80003da6:	f04a                	sd	s2,32(sp)
    80003da8:	ec4e                	sd	s3,24(sp)
    80003daa:	e852                	sd	s4,16(sp)
    80003dac:	0080                	addi	s0,sp,64
    80003dae:	892a                	mv	s2,a0
    80003db0:	8a2e                	mv	s4,a1
    80003db2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003db4:	4601                	li	a2,0
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	dd8080e7          	jalr	-552(ra) # 80003b8e <dirlookup>
    80003dbe:	e93d                	bnez	a0,80003e34 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc0:	04c92483          	lw	s1,76(s2)
    80003dc4:	c49d                	beqz	s1,80003df2 <dirlink+0x54>
    80003dc6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc8:	4741                	li	a4,16
    80003dca:	86a6                	mv	a3,s1
    80003dcc:	fc040613          	addi	a2,s0,-64
    80003dd0:	4581                	li	a1,0
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	b8a080e7          	jalr	-1142(ra) # 8000395e <readi>
    80003ddc:	47c1                	li	a5,16
    80003dde:	06f51163          	bne	a0,a5,80003e40 <dirlink+0xa2>
    if(de.inum == 0)
    80003de2:	fc045783          	lhu	a5,-64(s0)
    80003de6:	c791                	beqz	a5,80003df2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de8:	24c1                	addiw	s1,s1,16
    80003dea:	04c92783          	lw	a5,76(s2)
    80003dee:	fcf4ede3          	bltu	s1,a5,80003dc8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003df2:	4639                	li	a2,14
    80003df4:	85d2                	mv	a1,s4
    80003df6:	fc240513          	addi	a0,s0,-62
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	fe4080e7          	jalr	-28(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e02:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e06:	4741                	li	a4,16
    80003e08:	86a6                	mv	a3,s1
    80003e0a:	fc040613          	addi	a2,s0,-64
    80003e0e:	4581                	li	a1,0
    80003e10:	854a                	mv	a0,s2
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	c44080e7          	jalr	-956(ra) # 80003a56 <writei>
    80003e1a:	1541                	addi	a0,a0,-16
    80003e1c:	00a03533          	snez	a0,a0
    80003e20:	40a00533          	neg	a0,a0
}
    80003e24:	70e2                	ld	ra,56(sp)
    80003e26:	7442                	ld	s0,48(sp)
    80003e28:	74a2                	ld	s1,40(sp)
    80003e2a:	7902                	ld	s2,32(sp)
    80003e2c:	69e2                	ld	s3,24(sp)
    80003e2e:	6a42                	ld	s4,16(sp)
    80003e30:	6121                	addi	sp,sp,64
    80003e32:	8082                	ret
    iput(ip);
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	a30080e7          	jalr	-1488(ra) # 80003864 <iput>
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	b7dd                	j	80003e24 <dirlink+0x86>
      panic("dirlink read");
    80003e40:	00004517          	auipc	a0,0x4
    80003e44:	7f850513          	addi	a0,a0,2040 # 80008638 <syscalls+0x1d8>
    80003e48:	ffffc097          	auipc	ra,0xffffc
    80003e4c:	6f6080e7          	jalr	1782(ra) # 8000053e <panic>

0000000080003e50 <namei>:

struct inode*
namei(char *path)
{
    80003e50:	1101                	addi	sp,sp,-32
    80003e52:	ec06                	sd	ra,24(sp)
    80003e54:	e822                	sd	s0,16(sp)
    80003e56:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e58:	fe040613          	addi	a2,s0,-32
    80003e5c:	4581                	li	a1,0
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	de0080e7          	jalr	-544(ra) # 80003c3e <namex>
}
    80003e66:	60e2                	ld	ra,24(sp)
    80003e68:	6442                	ld	s0,16(sp)
    80003e6a:	6105                	addi	sp,sp,32
    80003e6c:	8082                	ret

0000000080003e6e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e6e:	1141                	addi	sp,sp,-16
    80003e70:	e406                	sd	ra,8(sp)
    80003e72:	e022                	sd	s0,0(sp)
    80003e74:	0800                	addi	s0,sp,16
    80003e76:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e78:	4585                	li	a1,1
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	dc4080e7          	jalr	-572(ra) # 80003c3e <namex>
}
    80003e82:	60a2                	ld	ra,8(sp)
    80003e84:	6402                	ld	s0,0(sp)
    80003e86:	0141                	addi	sp,sp,16
    80003e88:	8082                	ret

0000000080003e8a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	e426                	sd	s1,8(sp)
    80003e92:	e04a                	sd	s2,0(sp)
    80003e94:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e96:	0001d917          	auipc	s2,0x1d
    80003e9a:	c8a90913          	addi	s2,s2,-886 # 80020b20 <log>
    80003e9e:	01892583          	lw	a1,24(s2)
    80003ea2:	02892503          	lw	a0,40(s2)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	fea080e7          	jalr	-22(ra) # 80002e90 <bread>
    80003eae:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eb0:	02c92683          	lw	a3,44(s2)
    80003eb4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eb6:	02d05763          	blez	a3,80003ee4 <write_head+0x5a>
    80003eba:	0001d797          	auipc	a5,0x1d
    80003ebe:	c9678793          	addi	a5,a5,-874 # 80020b50 <log+0x30>
    80003ec2:	05c50713          	addi	a4,a0,92
    80003ec6:	36fd                	addiw	a3,a3,-1
    80003ec8:	1682                	slli	a3,a3,0x20
    80003eca:	9281                	srli	a3,a3,0x20
    80003ecc:	068a                	slli	a3,a3,0x2
    80003ece:	0001d617          	auipc	a2,0x1d
    80003ed2:	c8660613          	addi	a2,a2,-890 # 80020b54 <log+0x34>
    80003ed6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ed8:	4390                	lw	a2,0(a5)
    80003eda:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003edc:	0791                	addi	a5,a5,4
    80003ede:	0711                	addi	a4,a4,4
    80003ee0:	fed79ce3          	bne	a5,a3,80003ed8 <write_head+0x4e>
  }
  bwrite(buf);
    80003ee4:	8526                	mv	a0,s1
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	09c080e7          	jalr	156(ra) # 80002f82 <bwrite>
  brelse(buf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	0d0080e7          	jalr	208(ra) # 80002fc0 <brelse>
}
    80003ef8:	60e2                	ld	ra,24(sp)
    80003efa:	6442                	ld	s0,16(sp)
    80003efc:	64a2                	ld	s1,8(sp)
    80003efe:	6902                	ld	s2,0(sp)
    80003f00:	6105                	addi	sp,sp,32
    80003f02:	8082                	ret

0000000080003f04 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f04:	0001d797          	auipc	a5,0x1d
    80003f08:	c487a783          	lw	a5,-952(a5) # 80020b4c <log+0x2c>
    80003f0c:	0af05d63          	blez	a5,80003fc6 <install_trans+0xc2>
{
    80003f10:	7139                	addi	sp,sp,-64
    80003f12:	fc06                	sd	ra,56(sp)
    80003f14:	f822                	sd	s0,48(sp)
    80003f16:	f426                	sd	s1,40(sp)
    80003f18:	f04a                	sd	s2,32(sp)
    80003f1a:	ec4e                	sd	s3,24(sp)
    80003f1c:	e852                	sd	s4,16(sp)
    80003f1e:	e456                	sd	s5,8(sp)
    80003f20:	e05a                	sd	s6,0(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	8b2a                	mv	s6,a0
    80003f26:	0001da97          	auipc	s5,0x1d
    80003f2a:	c2aa8a93          	addi	s5,s5,-982 # 80020b50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f30:	0001d997          	auipc	s3,0x1d
    80003f34:	bf098993          	addi	s3,s3,-1040 # 80020b20 <log>
    80003f38:	a00d                	j	80003f5a <install_trans+0x56>
    brelse(lbuf);
    80003f3a:	854a                	mv	a0,s2
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	084080e7          	jalr	132(ra) # 80002fc0 <brelse>
    brelse(dbuf);
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	07a080e7          	jalr	122(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f4e:	2a05                	addiw	s4,s4,1
    80003f50:	0a91                	addi	s5,s5,4
    80003f52:	02c9a783          	lw	a5,44(s3)
    80003f56:	04fa5e63          	bge	s4,a5,80003fb2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f5a:	0189a583          	lw	a1,24(s3)
    80003f5e:	014585bb          	addw	a1,a1,s4
    80003f62:	2585                	addiw	a1,a1,1
    80003f64:	0289a503          	lw	a0,40(s3)
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	f28080e7          	jalr	-216(ra) # 80002e90 <bread>
    80003f70:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f72:	000aa583          	lw	a1,0(s5)
    80003f76:	0289a503          	lw	a0,40(s3)
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	f16080e7          	jalr	-234(ra) # 80002e90 <bread>
    80003f82:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f84:	40000613          	li	a2,1024
    80003f88:	05890593          	addi	a1,s2,88
    80003f8c:	05850513          	addi	a0,a0,88
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	d9e080e7          	jalr	-610(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f98:	8526                	mv	a0,s1
    80003f9a:	fffff097          	auipc	ra,0xfffff
    80003f9e:	fe8080e7          	jalr	-24(ra) # 80002f82 <bwrite>
    if(recovering == 0)
    80003fa2:	f80b1ce3          	bnez	s6,80003f3a <install_trans+0x36>
      bunpin(dbuf);
    80003fa6:	8526                	mv	a0,s1
    80003fa8:	fffff097          	auipc	ra,0xfffff
    80003fac:	0f2080e7          	jalr	242(ra) # 8000309a <bunpin>
    80003fb0:	b769                	j	80003f3a <install_trans+0x36>
}
    80003fb2:	70e2                	ld	ra,56(sp)
    80003fb4:	7442                	ld	s0,48(sp)
    80003fb6:	74a2                	ld	s1,40(sp)
    80003fb8:	7902                	ld	s2,32(sp)
    80003fba:	69e2                	ld	s3,24(sp)
    80003fbc:	6a42                	ld	s4,16(sp)
    80003fbe:	6aa2                	ld	s5,8(sp)
    80003fc0:	6b02                	ld	s6,0(sp)
    80003fc2:	6121                	addi	sp,sp,64
    80003fc4:	8082                	ret
    80003fc6:	8082                	ret

0000000080003fc8 <initlog>:
{
    80003fc8:	7179                	addi	sp,sp,-48
    80003fca:	f406                	sd	ra,40(sp)
    80003fcc:	f022                	sd	s0,32(sp)
    80003fce:	ec26                	sd	s1,24(sp)
    80003fd0:	e84a                	sd	s2,16(sp)
    80003fd2:	e44e                	sd	s3,8(sp)
    80003fd4:	1800                	addi	s0,sp,48
    80003fd6:	892a                	mv	s2,a0
    80003fd8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fda:	0001d497          	auipc	s1,0x1d
    80003fde:	b4648493          	addi	s1,s1,-1210 # 80020b20 <log>
    80003fe2:	00004597          	auipc	a1,0x4
    80003fe6:	66658593          	addi	a1,a1,1638 # 80008648 <syscalls+0x1e8>
    80003fea:	8526                	mv	a0,s1
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	b5a080e7          	jalr	-1190(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003ff4:	0149a583          	lw	a1,20(s3)
    80003ff8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003ffa:	0109a783          	lw	a5,16(s3)
    80003ffe:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004000:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004004:	854a                	mv	a0,s2
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	e8a080e7          	jalr	-374(ra) # 80002e90 <bread>
  log.lh.n = lh->n;
    8000400e:	4d34                	lw	a3,88(a0)
    80004010:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004012:	02d05563          	blez	a3,8000403c <initlog+0x74>
    80004016:	05c50793          	addi	a5,a0,92
    8000401a:	0001d717          	auipc	a4,0x1d
    8000401e:	b3670713          	addi	a4,a4,-1226 # 80020b50 <log+0x30>
    80004022:	36fd                	addiw	a3,a3,-1
    80004024:	1682                	slli	a3,a3,0x20
    80004026:	9281                	srli	a3,a3,0x20
    80004028:	068a                	slli	a3,a3,0x2
    8000402a:	06050613          	addi	a2,a0,96
    8000402e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004030:	4390                	lw	a2,0(a5)
    80004032:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004034:	0791                	addi	a5,a5,4
    80004036:	0711                	addi	a4,a4,4
    80004038:	fed79ce3          	bne	a5,a3,80004030 <initlog+0x68>
  brelse(buf);
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	f84080e7          	jalr	-124(ra) # 80002fc0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004044:	4505                	li	a0,1
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	ebe080e7          	jalr	-322(ra) # 80003f04 <install_trans>
  log.lh.n = 0;
    8000404e:	0001d797          	auipc	a5,0x1d
    80004052:	ae07af23          	sw	zero,-1282(a5) # 80020b4c <log+0x2c>
  write_head(); // clear the log
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	e34080e7          	jalr	-460(ra) # 80003e8a <write_head>
}
    8000405e:	70a2                	ld	ra,40(sp)
    80004060:	7402                	ld	s0,32(sp)
    80004062:	64e2                	ld	s1,24(sp)
    80004064:	6942                	ld	s2,16(sp)
    80004066:	69a2                	ld	s3,8(sp)
    80004068:	6145                	addi	sp,sp,48
    8000406a:	8082                	ret

000000008000406c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000406c:	1101                	addi	sp,sp,-32
    8000406e:	ec06                	sd	ra,24(sp)
    80004070:	e822                	sd	s0,16(sp)
    80004072:	e426                	sd	s1,8(sp)
    80004074:	e04a                	sd	s2,0(sp)
    80004076:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004078:	0001d517          	auipc	a0,0x1d
    8000407c:	aa850513          	addi	a0,a0,-1368 # 80020b20 <log>
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	b56080e7          	jalr	-1194(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	a9848493          	addi	s1,s1,-1384 # 80020b20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004090:	4979                	li	s2,30
    80004092:	a039                	j	800040a0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004094:	85a6                	mv	a1,s1
    80004096:	8526                	mv	a0,s1
    80004098:	ffffe097          	auipc	ra,0xffffe
    8000409c:	fbc080e7          	jalr	-68(ra) # 80002054 <sleep>
    if(log.committing){
    800040a0:	50dc                	lw	a5,36(s1)
    800040a2:	fbed                	bnez	a5,80004094 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a4:	509c                	lw	a5,32(s1)
    800040a6:	0017871b          	addiw	a4,a5,1
    800040aa:	0007069b          	sext.w	a3,a4
    800040ae:	0027179b          	slliw	a5,a4,0x2
    800040b2:	9fb9                	addw	a5,a5,a4
    800040b4:	0017979b          	slliw	a5,a5,0x1
    800040b8:	54d8                	lw	a4,44(s1)
    800040ba:	9fb9                	addw	a5,a5,a4
    800040bc:	00f95963          	bge	s2,a5,800040ce <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040c0:	85a6                	mv	a1,s1
    800040c2:	8526                	mv	a0,s1
    800040c4:	ffffe097          	auipc	ra,0xffffe
    800040c8:	f90080e7          	jalr	-112(ra) # 80002054 <sleep>
    800040cc:	bfd1                	j	800040a0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ce:	0001d517          	auipc	a0,0x1d
    800040d2:	a5250513          	addi	a0,a0,-1454 # 80020b20 <log>
    800040d6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040d8:	ffffd097          	auipc	ra,0xffffd
    800040dc:	bb2080e7          	jalr	-1102(ra) # 80000c8a <release>
      break;
    }
  }
}
    800040e0:	60e2                	ld	ra,24(sp)
    800040e2:	6442                	ld	s0,16(sp)
    800040e4:	64a2                	ld	s1,8(sp)
    800040e6:	6902                	ld	s2,0(sp)
    800040e8:	6105                	addi	sp,sp,32
    800040ea:	8082                	ret

00000000800040ec <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ec:	7139                	addi	sp,sp,-64
    800040ee:	fc06                	sd	ra,56(sp)
    800040f0:	f822                	sd	s0,48(sp)
    800040f2:	f426                	sd	s1,40(sp)
    800040f4:	f04a                	sd	s2,32(sp)
    800040f6:	ec4e                	sd	s3,24(sp)
    800040f8:	e852                	sd	s4,16(sp)
    800040fa:	e456                	sd	s5,8(sp)
    800040fc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040fe:	0001d497          	auipc	s1,0x1d
    80004102:	a2248493          	addi	s1,s1,-1502 # 80020b20 <log>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	ace080e7          	jalr	-1330(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004110:	509c                	lw	a5,32(s1)
    80004112:	37fd                	addiw	a5,a5,-1
    80004114:	0007891b          	sext.w	s2,a5
    80004118:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000411a:	50dc                	lw	a5,36(s1)
    8000411c:	e7b9                	bnez	a5,8000416a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000411e:	04091e63          	bnez	s2,8000417a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004122:	0001d497          	auipc	s1,0x1d
    80004126:	9fe48493          	addi	s1,s1,-1538 # 80020b20 <log>
    8000412a:	4785                	li	a5,1
    8000412c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	b5a080e7          	jalr	-1190(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004138:	54dc                	lw	a5,44(s1)
    8000413a:	06f04763          	bgtz	a5,800041a8 <end_op+0xbc>
    acquire(&log.lock);
    8000413e:	0001d497          	auipc	s1,0x1d
    80004142:	9e248493          	addi	s1,s1,-1566 # 80020b20 <log>
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	a8e080e7          	jalr	-1394(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004150:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004154:	8526                	mv	a0,s1
    80004156:	ffffe097          	auipc	ra,0xffffe
    8000415a:	f62080e7          	jalr	-158(ra) # 800020b8 <wakeup>
    release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	b2a080e7          	jalr	-1238(ra) # 80000c8a <release>
}
    80004168:	a03d                	j	80004196 <end_op+0xaa>
    panic("log.committing");
    8000416a:	00004517          	auipc	a0,0x4
    8000416e:	4e650513          	addi	a0,a0,1254 # 80008650 <syscalls+0x1f0>
    80004172:	ffffc097          	auipc	ra,0xffffc
    80004176:	3cc080e7          	jalr	972(ra) # 8000053e <panic>
    wakeup(&log);
    8000417a:	0001d497          	auipc	s1,0x1d
    8000417e:	9a648493          	addi	s1,s1,-1626 # 80020b20 <log>
    80004182:	8526                	mv	a0,s1
    80004184:	ffffe097          	auipc	ra,0xffffe
    80004188:	f34080e7          	jalr	-204(ra) # 800020b8 <wakeup>
  release(&log.lock);
    8000418c:	8526                	mv	a0,s1
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	afc080e7          	jalr	-1284(ra) # 80000c8a <release>
}
    80004196:	70e2                	ld	ra,56(sp)
    80004198:	7442                	ld	s0,48(sp)
    8000419a:	74a2                	ld	s1,40(sp)
    8000419c:	7902                	ld	s2,32(sp)
    8000419e:	69e2                	ld	s3,24(sp)
    800041a0:	6a42                	ld	s4,16(sp)
    800041a2:	6aa2                	ld	s5,8(sp)
    800041a4:	6121                	addi	sp,sp,64
    800041a6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a8:	0001da97          	auipc	s5,0x1d
    800041ac:	9a8a8a93          	addi	s5,s5,-1624 # 80020b50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041b0:	0001da17          	auipc	s4,0x1d
    800041b4:	970a0a13          	addi	s4,s4,-1680 # 80020b20 <log>
    800041b8:	018a2583          	lw	a1,24(s4)
    800041bc:	012585bb          	addw	a1,a1,s2
    800041c0:	2585                	addiw	a1,a1,1
    800041c2:	028a2503          	lw	a0,40(s4)
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	cca080e7          	jalr	-822(ra) # 80002e90 <bread>
    800041ce:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041d0:	000aa583          	lw	a1,0(s5)
    800041d4:	028a2503          	lw	a0,40(s4)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	cb8080e7          	jalr	-840(ra) # 80002e90 <bread>
    800041e0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e2:	40000613          	li	a2,1024
    800041e6:	05850593          	addi	a1,a0,88
    800041ea:	05848513          	addi	a0,s1,88
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	b40080e7          	jalr	-1216(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800041f6:	8526                	mv	a0,s1
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	d8a080e7          	jalr	-630(ra) # 80002f82 <bwrite>
    brelse(from);
    80004200:	854e                	mv	a0,s3
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	dbe080e7          	jalr	-578(ra) # 80002fc0 <brelse>
    brelse(to);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	db4080e7          	jalr	-588(ra) # 80002fc0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	2905                	addiw	s2,s2,1
    80004216:	0a91                	addi	s5,s5,4
    80004218:	02ca2783          	lw	a5,44(s4)
    8000421c:	f8f94ee3          	blt	s2,a5,800041b8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004220:	00000097          	auipc	ra,0x0
    80004224:	c6a080e7          	jalr	-918(ra) # 80003e8a <write_head>
    install_trans(0); // Now install writes to home locations
    80004228:	4501                	li	a0,0
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	cda080e7          	jalr	-806(ra) # 80003f04 <install_trans>
    log.lh.n = 0;
    80004232:	0001d797          	auipc	a5,0x1d
    80004236:	9007ad23          	sw	zero,-1766(a5) # 80020b4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	c50080e7          	jalr	-944(ra) # 80003e8a <write_head>
    80004242:	bdf5                	j	8000413e <end_op+0x52>

0000000080004244 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004244:	1101                	addi	sp,sp,-32
    80004246:	ec06                	sd	ra,24(sp)
    80004248:	e822                	sd	s0,16(sp)
    8000424a:	e426                	sd	s1,8(sp)
    8000424c:	e04a                	sd	s2,0(sp)
    8000424e:	1000                	addi	s0,sp,32
    80004250:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004252:	0001d917          	auipc	s2,0x1d
    80004256:	8ce90913          	addi	s2,s2,-1842 # 80020b20 <log>
    8000425a:	854a                	mv	a0,s2
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	97a080e7          	jalr	-1670(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004264:	02c92603          	lw	a2,44(s2)
    80004268:	47f5                	li	a5,29
    8000426a:	06c7c563          	blt	a5,a2,800042d4 <log_write+0x90>
    8000426e:	0001d797          	auipc	a5,0x1d
    80004272:	8ce7a783          	lw	a5,-1842(a5) # 80020b3c <log+0x1c>
    80004276:	37fd                	addiw	a5,a5,-1
    80004278:	04f65e63          	bge	a2,a5,800042d4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000427c:	0001d797          	auipc	a5,0x1d
    80004280:	8c47a783          	lw	a5,-1852(a5) # 80020b40 <log+0x20>
    80004284:	06f05063          	blez	a5,800042e4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004288:	4781                	li	a5,0
    8000428a:	06c05563          	blez	a2,800042f4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000428e:	44cc                	lw	a1,12(s1)
    80004290:	0001d717          	auipc	a4,0x1d
    80004294:	8c070713          	addi	a4,a4,-1856 # 80020b50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004298:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000429a:	4314                	lw	a3,0(a4)
    8000429c:	04b68c63          	beq	a3,a1,800042f4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042a0:	2785                	addiw	a5,a5,1
    800042a2:	0711                	addi	a4,a4,4
    800042a4:	fef61be3          	bne	a2,a5,8000429a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042a8:	0621                	addi	a2,a2,8
    800042aa:	060a                	slli	a2,a2,0x2
    800042ac:	0001d797          	auipc	a5,0x1d
    800042b0:	87478793          	addi	a5,a5,-1932 # 80020b20 <log>
    800042b4:	963e                	add	a2,a2,a5
    800042b6:	44dc                	lw	a5,12(s1)
    800042b8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042ba:	8526                	mv	a0,s1
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	da2080e7          	jalr	-606(ra) # 8000305e <bpin>
    log.lh.n++;
    800042c4:	0001d717          	auipc	a4,0x1d
    800042c8:	85c70713          	addi	a4,a4,-1956 # 80020b20 <log>
    800042cc:	575c                	lw	a5,44(a4)
    800042ce:	2785                	addiw	a5,a5,1
    800042d0:	d75c                	sw	a5,44(a4)
    800042d2:	a835                	j	8000430e <log_write+0xca>
    panic("too big a transaction");
    800042d4:	00004517          	auipc	a0,0x4
    800042d8:	38c50513          	addi	a0,a0,908 # 80008660 <syscalls+0x200>
    800042dc:	ffffc097          	auipc	ra,0xffffc
    800042e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800042e4:	00004517          	auipc	a0,0x4
    800042e8:	39450513          	addi	a0,a0,916 # 80008678 <syscalls+0x218>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042f4:	00878713          	addi	a4,a5,8
    800042f8:	00271693          	slli	a3,a4,0x2
    800042fc:	0001d717          	auipc	a4,0x1d
    80004300:	82470713          	addi	a4,a4,-2012 # 80020b20 <log>
    80004304:	9736                	add	a4,a4,a3
    80004306:	44d4                	lw	a3,12(s1)
    80004308:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000430a:	faf608e3          	beq	a2,a5,800042ba <log_write+0x76>
  }
  release(&log.lock);
    8000430e:	0001d517          	auipc	a0,0x1d
    80004312:	81250513          	addi	a0,a0,-2030 # 80020b20 <log>
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	974080e7          	jalr	-1676(ra) # 80000c8a <release>
}
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6902                	ld	s2,0(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
    80004336:	84aa                	mv	s1,a0
    80004338:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000433a:	00004597          	auipc	a1,0x4
    8000433e:	35e58593          	addi	a1,a1,862 # 80008698 <syscalls+0x238>
    80004342:	0521                	addi	a0,a0,8
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	802080e7          	jalr	-2046(ra) # 80000b46 <initlock>
  lk->name = name;
    8000434c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004350:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004354:	0204a423          	sw	zero,40(s1)
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004364:	1101                	addi	sp,sp,-32
    80004366:	ec06                	sd	ra,24(sp)
    80004368:	e822                	sd	s0,16(sp)
    8000436a:	e426                	sd	s1,8(sp)
    8000436c:	e04a                	sd	s2,0(sp)
    8000436e:	1000                	addi	s0,sp,32
    80004370:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004372:	00850913          	addi	s2,a0,8
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004380:	409c                	lw	a5,0(s1)
    80004382:	cb89                	beqz	a5,80004394 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004384:	85ca                	mv	a1,s2
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	ccc080e7          	jalr	-820(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004390:	409c                	lw	a5,0(s1)
    80004392:	fbed                	bnez	a5,80004384 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004394:	4785                	li	a5,1
    80004396:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	614080e7          	jalr	1556(ra) # 800019ac <myproc>
    800043a0:	591c                	lw	a5,48(a0)
    800043a2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043a4:	854a                	mv	a0,s2
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	8e4080e7          	jalr	-1820(ra) # 80000c8a <release>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	808080e7          	jalr	-2040(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800043d6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043da:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffe097          	auipc	ra,0xffffe
    800043e4:	cd8080e7          	jalr	-808(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	8a0080e7          	jalr	-1888(ra) # 80000c8a <release>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043fe:	7179                	addi	sp,sp,-48
    80004400:	f406                	sd	ra,40(sp)
    80004402:	f022                	sd	s0,32(sp)
    80004404:	ec26                	sd	s1,24(sp)
    80004406:	e84a                	sd	s2,16(sp)
    80004408:	e44e                	sd	s3,8(sp)
    8000440a:	1800                	addi	s0,sp,48
    8000440c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000440e:	00850913          	addi	s2,a0,8
    80004412:	854a                	mv	a0,s2
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	7c2080e7          	jalr	1986(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	ef99                	bnez	a5,8000443c <holdingsleep+0x3e>
    80004420:	4481                	li	s1,0
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
  return r;
}
    8000442c:	8526                	mv	a0,s1
    8000442e:	70a2                	ld	ra,40(sp)
    80004430:	7402                	ld	s0,32(sp)
    80004432:	64e2                	ld	s1,24(sp)
    80004434:	6942                	ld	s2,16(sp)
    80004436:	69a2                	ld	s3,8(sp)
    80004438:	6145                	addi	sp,sp,48
    8000443a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443c:	0284a983          	lw	s3,40(s1)
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	56c080e7          	jalr	1388(ra) # 800019ac <myproc>
    80004448:	5904                	lw	s1,48(a0)
    8000444a:	413484b3          	sub	s1,s1,s3
    8000444e:	0014b493          	seqz	s1,s1
    80004452:	bfc1                	j	80004422 <holdingsleep+0x24>

0000000080004454 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004454:	1141                	addi	sp,sp,-16
    80004456:	e406                	sd	ra,8(sp)
    80004458:	e022                	sd	s0,0(sp)
    8000445a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	24c58593          	addi	a1,a1,588 # 800086a8 <syscalls+0x248>
    80004464:	0001d517          	auipc	a0,0x1d
    80004468:	80450513          	addi	a0,a0,-2044 # 80020c68 <ftable>
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	6da080e7          	jalr	1754(ra) # 80000b46 <initlock>
}
    80004474:	60a2                	ld	ra,8(sp)
    80004476:	6402                	ld	s0,0(sp)
    80004478:	0141                	addi	sp,sp,16
    8000447a:	8082                	ret

000000008000447c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004486:	0001c517          	auipc	a0,0x1c
    8000448a:	7e250513          	addi	a0,a0,2018 # 80020c68 <ftable>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	748080e7          	jalr	1864(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004496:	0001c497          	auipc	s1,0x1c
    8000449a:	7ea48493          	addi	s1,s1,2026 # 80020c80 <ftable+0x18>
    8000449e:	0001d717          	auipc	a4,0x1d
    800044a2:	78270713          	addi	a4,a4,1922 # 80021c20 <disk>
    if(f->ref == 0){
    800044a6:	40dc                	lw	a5,4(s1)
    800044a8:	cf99                	beqz	a5,800044c6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044aa:	02848493          	addi	s1,s1,40
    800044ae:	fee49ce3          	bne	s1,a4,800044a6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044b2:	0001c517          	auipc	a0,0x1c
    800044b6:	7b650513          	addi	a0,a0,1974 # 80020c68 <ftable>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
  return 0;
    800044c2:	4481                	li	s1,0
    800044c4:	a819                	j	800044da <filealloc+0x5e>
      f->ref = 1;
    800044c6:	4785                	li	a5,1
    800044c8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ca:	0001c517          	auipc	a0,0x1c
    800044ce:	79e50513          	addi	a0,a0,1950 # 80020c68 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
}
    800044da:	8526                	mv	a0,s1
    800044dc:	60e2                	ld	ra,24(sp)
    800044de:	6442                	ld	s0,16(sp)
    800044e0:	64a2                	ld	s1,8(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044f2:	0001c517          	auipc	a0,0x1c
    800044f6:	77650513          	addi	a0,a0,1910 # 80020c68 <ftable>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004502:	40dc                	lw	a5,4(s1)
    80004504:	02f05263          	blez	a5,80004528 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004508:	2785                	addiw	a5,a5,1
    8000450a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000450c:	0001c517          	auipc	a0,0x1c
    80004510:	75c50513          	addi	a0,a0,1884 # 80020c68 <ftable>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	776080e7          	jalr	1910(ra) # 80000c8a <release>
  return f;
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret
    panic("filedup");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	18850513          	addi	a0,a0,392 # 800086b0 <syscalls+0x250>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>

0000000080004538 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004538:	7139                	addi	sp,sp,-64
    8000453a:	fc06                	sd	ra,56(sp)
    8000453c:	f822                	sd	s0,48(sp)
    8000453e:	f426                	sd	s1,40(sp)
    80004540:	f04a                	sd	s2,32(sp)
    80004542:	ec4e                	sd	s3,24(sp)
    80004544:	e852                	sd	s4,16(sp)
    80004546:	e456                	sd	s5,8(sp)
    80004548:	0080                	addi	s0,sp,64
    8000454a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000454c:	0001c517          	auipc	a0,0x1c
    80004550:	71c50513          	addi	a0,a0,1820 # 80020c68 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	682080e7          	jalr	1666(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000455c:	40dc                	lw	a5,4(s1)
    8000455e:	06f05163          	blez	a5,800045c0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004562:	37fd                	addiw	a5,a5,-1
    80004564:	0007871b          	sext.w	a4,a5
    80004568:	c0dc                	sw	a5,4(s1)
    8000456a:	06e04363          	bgtz	a4,800045d0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000456e:	0004a903          	lw	s2,0(s1)
    80004572:	0094ca83          	lbu	s5,9(s1)
    80004576:	0104ba03          	ld	s4,16(s1)
    8000457a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000457e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004582:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004586:	0001c517          	auipc	a0,0x1c
    8000458a:	6e250513          	addi	a0,a0,1762 # 80020c68 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6fc080e7          	jalr	1788(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004596:	4785                	li	a5,1
    80004598:	04f90d63          	beq	s2,a5,800045f2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000459c:	3979                	addiw	s2,s2,-2
    8000459e:	4785                	li	a5,1
    800045a0:	0527e063          	bltu	a5,s2,800045e0 <fileclose+0xa8>
    begin_op();
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	ac8080e7          	jalr	-1336(ra) # 8000406c <begin_op>
    iput(ff.ip);
    800045ac:	854e                	mv	a0,s3
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	2b6080e7          	jalr	694(ra) # 80003864 <iput>
    end_op();
    800045b6:	00000097          	auipc	ra,0x0
    800045ba:	b36080e7          	jalr	-1226(ra) # 800040ec <end_op>
    800045be:	a00d                	j	800045e0 <fileclose+0xa8>
    panic("fileclose");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	0f850513          	addi	a0,a0,248 # 800086b8 <syscalls+0x258>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>
    release(&ftable.lock);
    800045d0:	0001c517          	auipc	a0,0x1c
    800045d4:	69850513          	addi	a0,a0,1688 # 80020c68 <ftable>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6b2080e7          	jalr	1714(ra) # 80000c8a <release>
  }
}
    800045e0:	70e2                	ld	ra,56(sp)
    800045e2:	7442                	ld	s0,48(sp)
    800045e4:	74a2                	ld	s1,40(sp)
    800045e6:	7902                	ld	s2,32(sp)
    800045e8:	69e2                	ld	s3,24(sp)
    800045ea:	6a42                	ld	s4,16(sp)
    800045ec:	6aa2                	ld	s5,8(sp)
    800045ee:	6121                	addi	sp,sp,64
    800045f0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045f2:	85d6                	mv	a1,s5
    800045f4:	8552                	mv	a0,s4
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	34c080e7          	jalr	844(ra) # 80004942 <pipeclose>
    800045fe:	b7cd                	j	800045e0 <fileclose+0xa8>

0000000080004600 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004600:	715d                	addi	sp,sp,-80
    80004602:	e486                	sd	ra,72(sp)
    80004604:	e0a2                	sd	s0,64(sp)
    80004606:	fc26                	sd	s1,56(sp)
    80004608:	f84a                	sd	s2,48(sp)
    8000460a:	f44e                	sd	s3,40(sp)
    8000460c:	0880                	addi	s0,sp,80
    8000460e:	84aa                	mv	s1,a0
    80004610:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004612:	ffffd097          	auipc	ra,0xffffd
    80004616:	39a080e7          	jalr	922(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000461a:	409c                	lw	a5,0(s1)
    8000461c:	37f9                	addiw	a5,a5,-2
    8000461e:	4705                	li	a4,1
    80004620:	04f76763          	bltu	a4,a5,8000466e <filestat+0x6e>
    80004624:	892a                	mv	s2,a0
    ilock(f->ip);
    80004626:	6c88                	ld	a0,24(s1)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	082080e7          	jalr	130(ra) # 800036aa <ilock>
    stati(f->ip, &st);
    80004630:	fb840593          	addi	a1,s0,-72
    80004634:	6c88                	ld	a0,24(s1)
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	2fe080e7          	jalr	766(ra) # 80003934 <stati>
    iunlock(f->ip);
    8000463e:	6c88                	ld	a0,24(s1)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	12c080e7          	jalr	300(ra) # 8000376c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004648:	46e1                	li	a3,24
    8000464a:	fb840613          	addi	a2,s0,-72
    8000464e:	85ce                	mv	a1,s3
    80004650:	05093503          	ld	a0,80(s2)
    80004654:	ffffd097          	auipc	ra,0xffffd
    80004658:	014080e7          	jalr	20(ra) # 80001668 <copyout>
    8000465c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004660:	60a6                	ld	ra,72(sp)
    80004662:	6406                	ld	s0,64(sp)
    80004664:	74e2                	ld	s1,56(sp)
    80004666:	7942                	ld	s2,48(sp)
    80004668:	79a2                	ld	s3,40(sp)
    8000466a:	6161                	addi	sp,sp,80
    8000466c:	8082                	ret
  return -1;
    8000466e:	557d                	li	a0,-1
    80004670:	bfc5                	j	80004660 <filestat+0x60>

0000000080004672 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004672:	7179                	addi	sp,sp,-48
    80004674:	f406                	sd	ra,40(sp)
    80004676:	f022                	sd	s0,32(sp)
    80004678:	ec26                	sd	s1,24(sp)
    8000467a:	e84a                	sd	s2,16(sp)
    8000467c:	e44e                	sd	s3,8(sp)
    8000467e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004680:	00854783          	lbu	a5,8(a0)
    80004684:	c3d5                	beqz	a5,80004728 <fileread+0xb6>
    80004686:	84aa                	mv	s1,a0
    80004688:	89ae                	mv	s3,a1
    8000468a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000468c:	411c                	lw	a5,0(a0)
    8000468e:	4705                	li	a4,1
    80004690:	04e78963          	beq	a5,a4,800046e2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004694:	470d                	li	a4,3
    80004696:	04e78d63          	beq	a5,a4,800046f0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000469a:	4709                	li	a4,2
    8000469c:	06e79e63          	bne	a5,a4,80004718 <fileread+0xa6>
    ilock(f->ip);
    800046a0:	6d08                	ld	a0,24(a0)
    800046a2:	fffff097          	auipc	ra,0xfffff
    800046a6:	008080e7          	jalr	8(ra) # 800036aa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046aa:	874a                	mv	a4,s2
    800046ac:	5094                	lw	a3,32(s1)
    800046ae:	864e                	mv	a2,s3
    800046b0:	4585                	li	a1,1
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	2aa080e7          	jalr	682(ra) # 8000395e <readi>
    800046bc:	892a                	mv	s2,a0
    800046be:	00a05563          	blez	a0,800046c8 <fileread+0x56>
      f->off += r;
    800046c2:	509c                	lw	a5,32(s1)
    800046c4:	9fa9                	addw	a5,a5,a0
    800046c6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	0a2080e7          	jalr	162(ra) # 8000376c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046d2:	854a                	mv	a0,s2
    800046d4:	70a2                	ld	ra,40(sp)
    800046d6:	7402                	ld	s0,32(sp)
    800046d8:	64e2                	ld	s1,24(sp)
    800046da:	6942                	ld	s2,16(sp)
    800046dc:	69a2                	ld	s3,8(sp)
    800046de:	6145                	addi	sp,sp,48
    800046e0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046e2:	6908                	ld	a0,16(a0)
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	3c6080e7          	jalr	966(ra) # 80004aaa <piperead>
    800046ec:	892a                	mv	s2,a0
    800046ee:	b7d5                	j	800046d2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046f0:	02451783          	lh	a5,36(a0)
    800046f4:	03079693          	slli	a3,a5,0x30
    800046f8:	92c1                	srli	a3,a3,0x30
    800046fa:	4725                	li	a4,9
    800046fc:	02d76863          	bltu	a4,a3,8000472c <fileread+0xba>
    80004700:	0792                	slli	a5,a5,0x4
    80004702:	0001c717          	auipc	a4,0x1c
    80004706:	4c670713          	addi	a4,a4,1222 # 80020bc8 <devsw>
    8000470a:	97ba                	add	a5,a5,a4
    8000470c:	639c                	ld	a5,0(a5)
    8000470e:	c38d                	beqz	a5,80004730 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004710:	4505                	li	a0,1
    80004712:	9782                	jalr	a5
    80004714:	892a                	mv	s2,a0
    80004716:	bf75                	j	800046d2 <fileread+0x60>
    panic("fileread");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	fb050513          	addi	a0,a0,-80 # 800086c8 <syscalls+0x268>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e1e080e7          	jalr	-482(ra) # 8000053e <panic>
    return -1;
    80004728:	597d                	li	s2,-1
    8000472a:	b765                	j	800046d2 <fileread+0x60>
      return -1;
    8000472c:	597d                	li	s2,-1
    8000472e:	b755                	j	800046d2 <fileread+0x60>
    80004730:	597d                	li	s2,-1
    80004732:	b745                	j	800046d2 <fileread+0x60>

0000000080004734 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004734:	715d                	addi	sp,sp,-80
    80004736:	e486                	sd	ra,72(sp)
    80004738:	e0a2                	sd	s0,64(sp)
    8000473a:	fc26                	sd	s1,56(sp)
    8000473c:	f84a                	sd	s2,48(sp)
    8000473e:	f44e                	sd	s3,40(sp)
    80004740:	f052                	sd	s4,32(sp)
    80004742:	ec56                	sd	s5,24(sp)
    80004744:	e85a                	sd	s6,16(sp)
    80004746:	e45e                	sd	s7,8(sp)
    80004748:	e062                	sd	s8,0(sp)
    8000474a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000474c:	00954783          	lbu	a5,9(a0)
    80004750:	10078663          	beqz	a5,8000485c <filewrite+0x128>
    80004754:	892a                	mv	s2,a0
    80004756:	8aae                	mv	s5,a1
    80004758:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475a:	411c                	lw	a5,0(a0)
    8000475c:	4705                	li	a4,1
    8000475e:	02e78263          	beq	a5,a4,80004782 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004762:	470d                	li	a4,3
    80004764:	02e78663          	beq	a5,a4,80004790 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004768:	4709                	li	a4,2
    8000476a:	0ee79163          	bne	a5,a4,8000484c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000476e:	0ac05d63          	blez	a2,80004828 <filewrite+0xf4>
    int i = 0;
    80004772:	4981                	li	s3,0
    80004774:	6b05                	lui	s6,0x1
    80004776:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000477a:	6b85                	lui	s7,0x1
    8000477c:	c00b8b9b          	addiw	s7,s7,-1024
    80004780:	a861                	j	80004818 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004782:	6908                	ld	a0,16(a0)
    80004784:	00000097          	auipc	ra,0x0
    80004788:	22e080e7          	jalr	558(ra) # 800049b2 <pipewrite>
    8000478c:	8a2a                	mv	s4,a0
    8000478e:	a045                	j	8000482e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004790:	02451783          	lh	a5,36(a0)
    80004794:	03079693          	slli	a3,a5,0x30
    80004798:	92c1                	srli	a3,a3,0x30
    8000479a:	4725                	li	a4,9
    8000479c:	0cd76263          	bltu	a4,a3,80004860 <filewrite+0x12c>
    800047a0:	0792                	slli	a5,a5,0x4
    800047a2:	0001c717          	auipc	a4,0x1c
    800047a6:	42670713          	addi	a4,a4,1062 # 80020bc8 <devsw>
    800047aa:	97ba                	add	a5,a5,a4
    800047ac:	679c                	ld	a5,8(a5)
    800047ae:	cbdd                	beqz	a5,80004864 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047b0:	4505                	li	a0,1
    800047b2:	9782                	jalr	a5
    800047b4:	8a2a                	mv	s4,a0
    800047b6:	a8a5                	j	8000482e <filewrite+0xfa>
    800047b8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	8b0080e7          	jalr	-1872(ra) # 8000406c <begin_op>
      ilock(f->ip);
    800047c4:	01893503          	ld	a0,24(s2)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	ee2080e7          	jalr	-286(ra) # 800036aa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047d0:	8762                	mv	a4,s8
    800047d2:	02092683          	lw	a3,32(s2)
    800047d6:	01598633          	add	a2,s3,s5
    800047da:	4585                	li	a1,1
    800047dc:	01893503          	ld	a0,24(s2)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	276080e7          	jalr	630(ra) # 80003a56 <writei>
    800047e8:	84aa                	mv	s1,a0
    800047ea:	00a05763          	blez	a0,800047f8 <filewrite+0xc4>
        f->off += r;
    800047ee:	02092783          	lw	a5,32(s2)
    800047f2:	9fa9                	addw	a5,a5,a0
    800047f4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047f8:	01893503          	ld	a0,24(s2)
    800047fc:	fffff097          	auipc	ra,0xfffff
    80004800:	f70080e7          	jalr	-144(ra) # 8000376c <iunlock>
      end_op();
    80004804:	00000097          	auipc	ra,0x0
    80004808:	8e8080e7          	jalr	-1816(ra) # 800040ec <end_op>

      if(r != n1){
    8000480c:	009c1f63          	bne	s8,s1,8000482a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004810:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004814:	0149db63          	bge	s3,s4,8000482a <filewrite+0xf6>
      int n1 = n - i;
    80004818:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000481c:	84be                	mv	s1,a5
    8000481e:	2781                	sext.w	a5,a5
    80004820:	f8fb5ce3          	bge	s6,a5,800047b8 <filewrite+0x84>
    80004824:	84de                	mv	s1,s7
    80004826:	bf49                	j	800047b8 <filewrite+0x84>
    int i = 0;
    80004828:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000482a:	013a1f63          	bne	s4,s3,80004848 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000482e:	8552                	mv	a0,s4
    80004830:	60a6                	ld	ra,72(sp)
    80004832:	6406                	ld	s0,64(sp)
    80004834:	74e2                	ld	s1,56(sp)
    80004836:	7942                	ld	s2,48(sp)
    80004838:	79a2                	ld	s3,40(sp)
    8000483a:	7a02                	ld	s4,32(sp)
    8000483c:	6ae2                	ld	s5,24(sp)
    8000483e:	6b42                	ld	s6,16(sp)
    80004840:	6ba2                	ld	s7,8(sp)
    80004842:	6c02                	ld	s8,0(sp)
    80004844:	6161                	addi	sp,sp,80
    80004846:	8082                	ret
    ret = (i == n ? n : -1);
    80004848:	5a7d                	li	s4,-1
    8000484a:	b7d5                	j	8000482e <filewrite+0xfa>
    panic("filewrite");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e8c50513          	addi	a0,a0,-372 # 800086d8 <syscalls+0x278>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cea080e7          	jalr	-790(ra) # 8000053e <panic>
    return -1;
    8000485c:	5a7d                	li	s4,-1
    8000485e:	bfc1                	j	8000482e <filewrite+0xfa>
      return -1;
    80004860:	5a7d                	li	s4,-1
    80004862:	b7f1                	j	8000482e <filewrite+0xfa>
    80004864:	5a7d                	li	s4,-1
    80004866:	b7e1                	j	8000482e <filewrite+0xfa>

0000000080004868 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004868:	7179                	addi	sp,sp,-48
    8000486a:	f406                	sd	ra,40(sp)
    8000486c:	f022                	sd	s0,32(sp)
    8000486e:	ec26                	sd	s1,24(sp)
    80004870:	e84a                	sd	s2,16(sp)
    80004872:	e44e                	sd	s3,8(sp)
    80004874:	e052                	sd	s4,0(sp)
    80004876:	1800                	addi	s0,sp,48
    80004878:	84aa                	mv	s1,a0
    8000487a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000487c:	0005b023          	sd	zero,0(a1)
    80004880:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004884:	00000097          	auipc	ra,0x0
    80004888:	bf8080e7          	jalr	-1032(ra) # 8000447c <filealloc>
    8000488c:	e088                	sd	a0,0(s1)
    8000488e:	c551                	beqz	a0,8000491a <pipealloc+0xb2>
    80004890:	00000097          	auipc	ra,0x0
    80004894:	bec080e7          	jalr	-1044(ra) # 8000447c <filealloc>
    80004898:	00aa3023          	sd	a0,0(s4)
    8000489c:	c92d                	beqz	a0,8000490e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	248080e7          	jalr	584(ra) # 80000ae6 <kalloc>
    800048a6:	892a                	mv	s2,a0
    800048a8:	c125                	beqz	a0,80004908 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048aa:	4985                	li	s3,1
    800048ac:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048b0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048b4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048b8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048bc:	00004597          	auipc	a1,0x4
    800048c0:	e2c58593          	addi	a1,a1,-468 # 800086e8 <syscalls+0x288>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	282080e7          	jalr	642(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800048cc:	609c                	ld	a5,0(s1)
    800048ce:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048d2:	609c                	ld	a5,0(s1)
    800048d4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048d8:	609c                	ld	a5,0(s1)
    800048da:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048de:	609c                	ld	a5,0(s1)
    800048e0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048e4:	000a3783          	ld	a5,0(s4)
    800048e8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ec:	000a3783          	ld	a5,0(s4)
    800048f0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048f4:	000a3783          	ld	a5,0(s4)
    800048f8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048fc:	000a3783          	ld	a5,0(s4)
    80004900:	0127b823          	sd	s2,16(a5)
  return 0;
    80004904:	4501                	li	a0,0
    80004906:	a025                	j	8000492e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004908:	6088                	ld	a0,0(s1)
    8000490a:	e501                	bnez	a0,80004912 <pipealloc+0xaa>
    8000490c:	a039                	j	8000491a <pipealloc+0xb2>
    8000490e:	6088                	ld	a0,0(s1)
    80004910:	c51d                	beqz	a0,8000493e <pipealloc+0xd6>
    fileclose(*f0);
    80004912:	00000097          	auipc	ra,0x0
    80004916:	c26080e7          	jalr	-986(ra) # 80004538 <fileclose>
  if(*f1)
    8000491a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000491e:	557d                	li	a0,-1
  if(*f1)
    80004920:	c799                	beqz	a5,8000492e <pipealloc+0xc6>
    fileclose(*f1);
    80004922:	853e                	mv	a0,a5
    80004924:	00000097          	auipc	ra,0x0
    80004928:	c14080e7          	jalr	-1004(ra) # 80004538 <fileclose>
  return -1;
    8000492c:	557d                	li	a0,-1
}
    8000492e:	70a2                	ld	ra,40(sp)
    80004930:	7402                	ld	s0,32(sp)
    80004932:	64e2                	ld	s1,24(sp)
    80004934:	6942                	ld	s2,16(sp)
    80004936:	69a2                	ld	s3,8(sp)
    80004938:	6a02                	ld	s4,0(sp)
    8000493a:	6145                	addi	sp,sp,48
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	b7fd                	j	8000492e <pipealloc+0xc6>

0000000080004942 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004942:	1101                	addi	sp,sp,-32
    80004944:	ec06                	sd	ra,24(sp)
    80004946:	e822                	sd	s0,16(sp)
    80004948:	e426                	sd	s1,8(sp)
    8000494a:	e04a                	sd	s2,0(sp)
    8000494c:	1000                	addi	s0,sp,32
    8000494e:	84aa                	mv	s1,a0
    80004950:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	284080e7          	jalr	644(ra) # 80000bd6 <acquire>
  if(writable){
    8000495a:	02090d63          	beqz	s2,80004994 <pipeclose+0x52>
    pi->writeopen = 0;
    8000495e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004962:	21848513          	addi	a0,s1,536
    80004966:	ffffd097          	auipc	ra,0xffffd
    8000496a:	752080e7          	jalr	1874(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000496e:	2204b783          	ld	a5,544(s1)
    80004972:	eb95                	bnez	a5,800049a6 <pipeclose+0x64>
    release(&pi->lock);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	314080e7          	jalr	788(ra) # 80000c8a <release>
    kfree((char*)pi);
    8000497e:	8526                	mv	a0,s1
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	06a080e7          	jalr	106(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004988:	60e2                	ld	ra,24(sp)
    8000498a:	6442                	ld	s0,16(sp)
    8000498c:	64a2                	ld	s1,8(sp)
    8000498e:	6902                	ld	s2,0(sp)
    80004990:	6105                	addi	sp,sp,32
    80004992:	8082                	ret
    pi->readopen = 0;
    80004994:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004998:	21c48513          	addi	a0,s1,540
    8000499c:	ffffd097          	auipc	ra,0xffffd
    800049a0:	71c080e7          	jalr	1820(ra) # 800020b8 <wakeup>
    800049a4:	b7e9                	j	8000496e <pipeclose+0x2c>
    release(&pi->lock);
    800049a6:	8526                	mv	a0,s1
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	2e2080e7          	jalr	738(ra) # 80000c8a <release>
}
    800049b0:	bfe1                	j	80004988 <pipeclose+0x46>

00000000800049b2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049b2:	711d                	addi	sp,sp,-96
    800049b4:	ec86                	sd	ra,88(sp)
    800049b6:	e8a2                	sd	s0,80(sp)
    800049b8:	e4a6                	sd	s1,72(sp)
    800049ba:	e0ca                	sd	s2,64(sp)
    800049bc:	fc4e                	sd	s3,56(sp)
    800049be:	f852                	sd	s4,48(sp)
    800049c0:	f456                	sd	s5,40(sp)
    800049c2:	f05a                	sd	s6,32(sp)
    800049c4:	ec5e                	sd	s7,24(sp)
    800049c6:	e862                	sd	s8,16(sp)
    800049c8:	1080                	addi	s0,sp,96
    800049ca:	84aa                	mv	s1,a0
    800049cc:	8aae                	mv	s5,a1
    800049ce:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049d0:	ffffd097          	auipc	ra,0xffffd
    800049d4:	fdc080e7          	jalr	-36(ra) # 800019ac <myproc>
    800049d8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	1fa080e7          	jalr	506(ra) # 80000bd6 <acquire>
  while(i < n){
    800049e4:	0b405663          	blez	s4,80004a90 <pipewrite+0xde>
  int i = 0;
    800049e8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ea:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049ec:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049f0:	21c48b93          	addi	s7,s1,540
    800049f4:	a089                	j	80004a36 <pipewrite+0x84>
      release(&pi->lock);
    800049f6:	8526                	mv	a0,s1
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	292080e7          	jalr	658(ra) # 80000c8a <release>
      return -1;
    80004a00:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a02:	854a                	mv	a0,s2
    80004a04:	60e6                	ld	ra,88(sp)
    80004a06:	6446                	ld	s0,80(sp)
    80004a08:	64a6                	ld	s1,72(sp)
    80004a0a:	6906                	ld	s2,64(sp)
    80004a0c:	79e2                	ld	s3,56(sp)
    80004a0e:	7a42                	ld	s4,48(sp)
    80004a10:	7aa2                	ld	s5,40(sp)
    80004a12:	7b02                	ld	s6,32(sp)
    80004a14:	6be2                	ld	s7,24(sp)
    80004a16:	6c42                	ld	s8,16(sp)
    80004a18:	6125                	addi	sp,sp,96
    80004a1a:	8082                	ret
      wakeup(&pi->nread);
    80004a1c:	8562                	mv	a0,s8
    80004a1e:	ffffd097          	auipc	ra,0xffffd
    80004a22:	69a080e7          	jalr	1690(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a26:	85a6                	mv	a1,s1
    80004a28:	855e                	mv	a0,s7
    80004a2a:	ffffd097          	auipc	ra,0xffffd
    80004a2e:	62a080e7          	jalr	1578(ra) # 80002054 <sleep>
  while(i < n){
    80004a32:	07495063          	bge	s2,s4,80004a92 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a36:	2204a783          	lw	a5,544(s1)
    80004a3a:	dfd5                	beqz	a5,800049f6 <pipewrite+0x44>
    80004a3c:	854e                	mv	a0,s3
    80004a3e:	ffffe097          	auipc	ra,0xffffe
    80004a42:	8be080e7          	jalr	-1858(ra) # 800022fc <killed>
    80004a46:	f945                	bnez	a0,800049f6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a48:	2184a783          	lw	a5,536(s1)
    80004a4c:	21c4a703          	lw	a4,540(s1)
    80004a50:	2007879b          	addiw	a5,a5,512
    80004a54:	fcf704e3          	beq	a4,a5,80004a1c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a58:	4685                	li	a3,1
    80004a5a:	01590633          	add	a2,s2,s5
    80004a5e:	faf40593          	addi	a1,s0,-81
    80004a62:	0509b503          	ld	a0,80(s3)
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	c8e080e7          	jalr	-882(ra) # 800016f4 <copyin>
    80004a6e:	03650263          	beq	a0,s6,80004a92 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a72:	21c4a783          	lw	a5,540(s1)
    80004a76:	0017871b          	addiw	a4,a5,1
    80004a7a:	20e4ae23          	sw	a4,540(s1)
    80004a7e:	1ff7f793          	andi	a5,a5,511
    80004a82:	97a6                	add	a5,a5,s1
    80004a84:	faf44703          	lbu	a4,-81(s0)
    80004a88:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a8c:	2905                	addiw	s2,s2,1
    80004a8e:	b755                	j	80004a32 <pipewrite+0x80>
  int i = 0;
    80004a90:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004a92:	21848513          	addi	a0,s1,536
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	622080e7          	jalr	1570(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	1ea080e7          	jalr	490(ra) # 80000c8a <release>
  return i;
    80004aa8:	bfa9                	j	80004a02 <pipewrite+0x50>

0000000080004aaa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aaa:	715d                	addi	sp,sp,-80
    80004aac:	e486                	sd	ra,72(sp)
    80004aae:	e0a2                	sd	s0,64(sp)
    80004ab0:	fc26                	sd	s1,56(sp)
    80004ab2:	f84a                	sd	s2,48(sp)
    80004ab4:	f44e                	sd	s3,40(sp)
    80004ab6:	f052                	sd	s4,32(sp)
    80004ab8:	ec56                	sd	s5,24(sp)
    80004aba:	e85a                	sd	s6,16(sp)
    80004abc:	0880                	addi	s0,sp,80
    80004abe:	84aa                	mv	s1,a0
    80004ac0:	892e                	mv	s2,a1
    80004ac2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	ee8080e7          	jalr	-280(ra) # 800019ac <myproc>
    80004acc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	106080e7          	jalr	262(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ad8:	2184a703          	lw	a4,536(s1)
    80004adc:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ae0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae4:	02f71763          	bne	a4,a5,80004b12 <piperead+0x68>
    80004ae8:	2244a783          	lw	a5,548(s1)
    80004aec:	c39d                	beqz	a5,80004b12 <piperead+0x68>
    if(killed(pr)){
    80004aee:	8552                	mv	a0,s4
    80004af0:	ffffe097          	auipc	ra,0xffffe
    80004af4:	80c080e7          	jalr	-2036(ra) # 800022fc <killed>
    80004af8:	e941                	bnez	a0,80004b88 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004afa:	85a6                	mv	a1,s1
    80004afc:	854e                	mv	a0,s3
    80004afe:	ffffd097          	auipc	ra,0xffffd
    80004b02:	556080e7          	jalr	1366(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b06:	2184a703          	lw	a4,536(s1)
    80004b0a:	21c4a783          	lw	a5,540(s1)
    80004b0e:	fcf70de3          	beq	a4,a5,80004ae8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b12:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b14:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b16:	05505363          	blez	s5,80004b5c <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004b1a:	2184a783          	lw	a5,536(s1)
    80004b1e:	21c4a703          	lw	a4,540(s1)
    80004b22:	02f70d63          	beq	a4,a5,80004b5c <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b26:	0017871b          	addiw	a4,a5,1
    80004b2a:	20e4ac23          	sw	a4,536(s1)
    80004b2e:	1ff7f793          	andi	a5,a5,511
    80004b32:	97a6                	add	a5,a5,s1
    80004b34:	0187c783          	lbu	a5,24(a5)
    80004b38:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b3c:	4685                	li	a3,1
    80004b3e:	fbf40613          	addi	a2,s0,-65
    80004b42:	85ca                	mv	a1,s2
    80004b44:	050a3503          	ld	a0,80(s4)
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	b20080e7          	jalr	-1248(ra) # 80001668 <copyout>
    80004b50:	01650663          	beq	a0,s6,80004b5c <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b54:	2985                	addiw	s3,s3,1
    80004b56:	0905                	addi	s2,s2,1
    80004b58:	fd3a91e3          	bne	s5,s3,80004b1a <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b5c:	21c48513          	addi	a0,s1,540
    80004b60:	ffffd097          	auipc	ra,0xffffd
    80004b64:	558080e7          	jalr	1368(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	120080e7          	jalr	288(ra) # 80000c8a <release>
  return i;
}
    80004b72:	854e                	mv	a0,s3
    80004b74:	60a6                	ld	ra,72(sp)
    80004b76:	6406                	ld	s0,64(sp)
    80004b78:	74e2                	ld	s1,56(sp)
    80004b7a:	7942                	ld	s2,48(sp)
    80004b7c:	79a2                	ld	s3,40(sp)
    80004b7e:	7a02                	ld	s4,32(sp)
    80004b80:	6ae2                	ld	s5,24(sp)
    80004b82:	6b42                	ld	s6,16(sp)
    80004b84:	6161                	addi	sp,sp,80
    80004b86:	8082                	ret
      release(&pi->lock);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	100080e7          	jalr	256(ra) # 80000c8a <release>
      return -1;
    80004b92:	59fd                	li	s3,-1
    80004b94:	bff9                	j	80004b72 <piperead+0xc8>

0000000080004b96 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004b96:	1141                	addi	sp,sp,-16
    80004b98:	e422                	sd	s0,8(sp)
    80004b9a:	0800                	addi	s0,sp,16
    80004b9c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004b9e:	8905                	andi	a0,a0,1
    80004ba0:	c111                	beqz	a0,80004ba4 <flags2perm+0xe>
      perm = PTE_X;
    80004ba2:	4521                	li	a0,8
    if(flags & 0x2)
    80004ba4:	8b89                	andi	a5,a5,2
    80004ba6:	c399                	beqz	a5,80004bac <flags2perm+0x16>
      perm |= PTE_W;
    80004ba8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bac:	6422                	ld	s0,8(sp)
    80004bae:	0141                	addi	sp,sp,16
    80004bb0:	8082                	ret

0000000080004bb2 <exec>:

int
exec(char *path, char **argv)
{
    80004bb2:	de010113          	addi	sp,sp,-544
    80004bb6:	20113c23          	sd	ra,536(sp)
    80004bba:	20813823          	sd	s0,528(sp)
    80004bbe:	20913423          	sd	s1,520(sp)
    80004bc2:	21213023          	sd	s2,512(sp)
    80004bc6:	ffce                	sd	s3,504(sp)
    80004bc8:	fbd2                	sd	s4,496(sp)
    80004bca:	f7d6                	sd	s5,488(sp)
    80004bcc:	f3da                	sd	s6,480(sp)
    80004bce:	efde                	sd	s7,472(sp)
    80004bd0:	ebe2                	sd	s8,464(sp)
    80004bd2:	e7e6                	sd	s9,456(sp)
    80004bd4:	e3ea                	sd	s10,448(sp)
    80004bd6:	ff6e                	sd	s11,440(sp)
    80004bd8:	1400                	addi	s0,sp,544
    80004bda:	892a                	mv	s2,a0
    80004bdc:	dea43423          	sd	a0,-536(s0)
    80004be0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	dc8080e7          	jalr	-568(ra) # 800019ac <myproc>
    80004bec:	84aa                	mv	s1,a0

  begin_op();
    80004bee:	fffff097          	auipc	ra,0xfffff
    80004bf2:	47e080e7          	jalr	1150(ra) # 8000406c <begin_op>

  if((ip = namei(path)) == 0){
    80004bf6:	854a                	mv	a0,s2
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	258080e7          	jalr	600(ra) # 80003e50 <namei>
    80004c00:	c93d                	beqz	a0,80004c76 <exec+0xc4>
    80004c02:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	aa6080e7          	jalr	-1370(ra) # 800036aa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c0c:	04000713          	li	a4,64
    80004c10:	4681                	li	a3,0
    80004c12:	e5040613          	addi	a2,s0,-432
    80004c16:	4581                	li	a1,0
    80004c18:	8556                	mv	a0,s5
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	d44080e7          	jalr	-700(ra) # 8000395e <readi>
    80004c22:	04000793          	li	a5,64
    80004c26:	00f51a63          	bne	a0,a5,80004c3a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c2a:	e5042703          	lw	a4,-432(s0)
    80004c2e:	464c47b7          	lui	a5,0x464c4
    80004c32:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c36:	04f70663          	beq	a4,a5,80004c82 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c3a:	8556                	mv	a0,s5
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	cd0080e7          	jalr	-816(ra) # 8000390c <iunlockput>
    end_op();
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	4a8080e7          	jalr	1192(ra) # 800040ec <end_op>
  }
  return -1;
    80004c4c:	557d                	li	a0,-1
}
    80004c4e:	21813083          	ld	ra,536(sp)
    80004c52:	21013403          	ld	s0,528(sp)
    80004c56:	20813483          	ld	s1,520(sp)
    80004c5a:	20013903          	ld	s2,512(sp)
    80004c5e:	79fe                	ld	s3,504(sp)
    80004c60:	7a5e                	ld	s4,496(sp)
    80004c62:	7abe                	ld	s5,488(sp)
    80004c64:	7b1e                	ld	s6,480(sp)
    80004c66:	6bfe                	ld	s7,472(sp)
    80004c68:	6c5e                	ld	s8,464(sp)
    80004c6a:	6cbe                	ld	s9,456(sp)
    80004c6c:	6d1e                	ld	s10,448(sp)
    80004c6e:	7dfa                	ld	s11,440(sp)
    80004c70:	22010113          	addi	sp,sp,544
    80004c74:	8082                	ret
    end_op();
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	476080e7          	jalr	1142(ra) # 800040ec <end_op>
    return -1;
    80004c7e:	557d                	li	a0,-1
    80004c80:	b7f9                	j	80004c4e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffd097          	auipc	ra,0xffffd
    80004c88:	dec080e7          	jalr	-532(ra) # 80001a70 <proc_pagetable>
    80004c8c:	8b2a                	mv	s6,a0
    80004c8e:	d555                	beqz	a0,80004c3a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c90:	e7042783          	lw	a5,-400(s0)
    80004c94:	e8845703          	lhu	a4,-376(s0)
    80004c98:	c735                	beqz	a4,80004d04 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c9a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c9c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ca0:	6a05                	lui	s4,0x1
    80004ca2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ca6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004caa:	6d85                	lui	s11,0x1
    80004cac:	7d7d                	lui	s10,0xfffff
    80004cae:	a481                	j	80004eee <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cb0:	00004517          	auipc	a0,0x4
    80004cb4:	a4050513          	addi	a0,a0,-1472 # 800086f0 <syscalls+0x290>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	886080e7          	jalr	-1914(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cc0:	874a                	mv	a4,s2
    80004cc2:	009c86bb          	addw	a3,s9,s1
    80004cc6:	4581                	li	a1,0
    80004cc8:	8556                	mv	a0,s5
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	c94080e7          	jalr	-876(ra) # 8000395e <readi>
    80004cd2:	2501                	sext.w	a0,a0
    80004cd4:	1aa91a63          	bne	s2,a0,80004e88 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004cd8:	009d84bb          	addw	s1,s11,s1
    80004cdc:	013d09bb          	addw	s3,s10,s3
    80004ce0:	1f74f763          	bgeu	s1,s7,80004ece <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004ce4:	02049593          	slli	a1,s1,0x20
    80004ce8:	9181                	srli	a1,a1,0x20
    80004cea:	95e2                	add	a1,a1,s8
    80004cec:	855a                	mv	a0,s6
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	36e080e7          	jalr	878(ra) # 8000105c <walkaddr>
    80004cf6:	862a                	mv	a2,a0
    if(pa == 0)
    80004cf8:	dd45                	beqz	a0,80004cb0 <exec+0xfe>
      n = PGSIZE;
    80004cfa:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004cfc:	fd49f2e3          	bgeu	s3,s4,80004cc0 <exec+0x10e>
      n = sz - i;
    80004d00:	894e                	mv	s2,s3
    80004d02:	bf7d                	j	80004cc0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d04:	4901                	li	s2,0
  iunlockput(ip);
    80004d06:	8556                	mv	a0,s5
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	c04080e7          	jalr	-1020(ra) # 8000390c <iunlockput>
  end_op();
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	3dc080e7          	jalr	988(ra) # 800040ec <end_op>
  p = myproc();
    80004d18:	ffffd097          	auipc	ra,0xffffd
    80004d1c:	c94080e7          	jalr	-876(ra) # 800019ac <myproc>
    80004d20:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d22:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d26:	6785                	lui	a5,0x1
    80004d28:	17fd                	addi	a5,a5,-1
    80004d2a:	993e                	add	s2,s2,a5
    80004d2c:	77fd                	lui	a5,0xfffff
    80004d2e:	00f977b3          	and	a5,s2,a5
    80004d32:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d36:	4691                	li	a3,4
    80004d38:	6609                	lui	a2,0x2
    80004d3a:	963e                	add	a2,a2,a5
    80004d3c:	85be                	mv	a1,a5
    80004d3e:	855a                	mv	a0,s6
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80004d48:	8c2a                	mv	s8,a0
  ip = 0;
    80004d4a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d4c:	12050e63          	beqz	a0,80004e88 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d50:	75f9                	lui	a1,0xffffe
    80004d52:	95aa                	add	a1,a1,a0
    80004d54:	855a                	mv	a0,s6
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	8e0080e7          	jalr	-1824(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d5e:	7afd                	lui	s5,0xfffff
    80004d60:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d62:	df043783          	ld	a5,-528(s0)
    80004d66:	6388                	ld	a0,0(a5)
    80004d68:	c925                	beqz	a0,80004dd8 <exec+0x226>
    80004d6a:	e9040993          	addi	s3,s0,-368
    80004d6e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d72:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d74:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	0d8080e7          	jalr	216(ra) # 80000e4e <strlen>
    80004d7e:	0015079b          	addiw	a5,a0,1
    80004d82:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d86:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d8a:	13596663          	bltu	s2,s5,80004eb6 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d8e:	df043d83          	ld	s11,-528(s0)
    80004d92:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004d96:	8552                	mv	a0,s4
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	0b6080e7          	jalr	182(ra) # 80000e4e <strlen>
    80004da0:	0015069b          	addiw	a3,a0,1
    80004da4:	8652                	mv	a2,s4
    80004da6:	85ca                	mv	a1,s2
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	8be080e7          	jalr	-1858(ra) # 80001668 <copyout>
    80004db2:	10054663          	bltz	a0,80004ebe <exec+0x30c>
    ustack[argc] = sp;
    80004db6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dba:	0485                	addi	s1,s1,1
    80004dbc:	008d8793          	addi	a5,s11,8
    80004dc0:	def43823          	sd	a5,-528(s0)
    80004dc4:	008db503          	ld	a0,8(s11)
    80004dc8:	c911                	beqz	a0,80004ddc <exec+0x22a>
    if(argc >= MAXARG)
    80004dca:	09a1                	addi	s3,s3,8
    80004dcc:	fb3c95e3          	bne	s9,s3,80004d76 <exec+0x1c4>
  sz = sz1;
    80004dd0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dd4:	4a81                	li	s5,0
    80004dd6:	a84d                	j	80004e88 <exec+0x2d6>
  sp = sz;
    80004dd8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dda:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ddc:	00349793          	slli	a5,s1,0x3
    80004de0:	f9040713          	addi	a4,s0,-112
    80004de4:	97ba                	add	a5,a5,a4
    80004de6:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd1a0>
  sp -= (argc+1) * sizeof(uint64);
    80004dea:	00148693          	addi	a3,s1,1
    80004dee:	068e                	slli	a3,a3,0x3
    80004df0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004df4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004df8:	01597663          	bgeu	s2,s5,80004e04 <exec+0x252>
  sz = sz1;
    80004dfc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e00:	4a81                	li	s5,0
    80004e02:	a059                	j	80004e88 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e04:	e9040613          	addi	a2,s0,-368
    80004e08:	85ca                	mv	a1,s2
    80004e0a:	855a                	mv	a0,s6
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	85c080e7          	jalr	-1956(ra) # 80001668 <copyout>
    80004e14:	0a054963          	bltz	a0,80004ec6 <exec+0x314>
  p->trapframe->a1 = sp;
    80004e18:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e1c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e20:	de843783          	ld	a5,-536(s0)
    80004e24:	0007c703          	lbu	a4,0(a5)
    80004e28:	cf11                	beqz	a4,80004e44 <exec+0x292>
    80004e2a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e2c:	02f00693          	li	a3,47
    80004e30:	a039                	j	80004e3e <exec+0x28c>
      last = s+1;
    80004e32:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e36:	0785                	addi	a5,a5,1
    80004e38:	fff7c703          	lbu	a4,-1(a5)
    80004e3c:	c701                	beqz	a4,80004e44 <exec+0x292>
    if(*s == '/')
    80004e3e:	fed71ce3          	bne	a4,a3,80004e36 <exec+0x284>
    80004e42:	bfc5                	j	80004e32 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e44:	4641                	li	a2,16
    80004e46:	de843583          	ld	a1,-536(s0)
    80004e4a:	158b8513          	addi	a0,s7,344
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e56:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e5a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e5e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e62:	058bb783          	ld	a5,88(s7)
    80004e66:	e6843703          	ld	a4,-408(s0)
    80004e6a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e6c:	058bb783          	ld	a5,88(s7)
    80004e70:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e74:	85ea                	mv	a1,s10
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	c96080e7          	jalr	-874(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e7e:	0004851b          	sext.w	a0,s1
    80004e82:	b3f1                	j	80004c4e <exec+0x9c>
    80004e84:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e88:	df843583          	ld	a1,-520(s0)
    80004e8c:	855a                	mv	a0,s6
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	c7e080e7          	jalr	-898(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004e96:	da0a92e3          	bnez	s5,80004c3a <exec+0x88>
  return -1;
    80004e9a:	557d                	li	a0,-1
    80004e9c:	bb4d                	j	80004c4e <exec+0x9c>
    80004e9e:	df243c23          	sd	s2,-520(s0)
    80004ea2:	b7dd                	j	80004e88 <exec+0x2d6>
    80004ea4:	df243c23          	sd	s2,-520(s0)
    80004ea8:	b7c5                	j	80004e88 <exec+0x2d6>
    80004eaa:	df243c23          	sd	s2,-520(s0)
    80004eae:	bfe9                	j	80004e88 <exec+0x2d6>
    80004eb0:	df243c23          	sd	s2,-520(s0)
    80004eb4:	bfd1                	j	80004e88 <exec+0x2d6>
  sz = sz1;
    80004eb6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eba:	4a81                	li	s5,0
    80004ebc:	b7f1                	j	80004e88 <exec+0x2d6>
  sz = sz1;
    80004ebe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec2:	4a81                	li	s5,0
    80004ec4:	b7d1                	j	80004e88 <exec+0x2d6>
  sz = sz1;
    80004ec6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eca:	4a81                	li	s5,0
    80004ecc:	bf75                	j	80004e88 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ece:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	e0843783          	ld	a5,-504(s0)
    80004ed6:	0017869b          	addiw	a3,a5,1
    80004eda:	e0d43423          	sd	a3,-504(s0)
    80004ede:	e0043783          	ld	a5,-512(s0)
    80004ee2:	0387879b          	addiw	a5,a5,56
    80004ee6:	e8845703          	lhu	a4,-376(s0)
    80004eea:	e0e6dee3          	bge	a3,a4,80004d06 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eee:	2781                	sext.w	a5,a5
    80004ef0:	e0f43023          	sd	a5,-512(s0)
    80004ef4:	03800713          	li	a4,56
    80004ef8:	86be                	mv	a3,a5
    80004efa:	e1840613          	addi	a2,s0,-488
    80004efe:	4581                	li	a1,0
    80004f00:	8556                	mv	a0,s5
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	a5c080e7          	jalr	-1444(ra) # 8000395e <readi>
    80004f0a:	03800793          	li	a5,56
    80004f0e:	f6f51be3          	bne	a0,a5,80004e84 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80004f12:	e1842783          	lw	a5,-488(s0)
    80004f16:	4705                	li	a4,1
    80004f18:	fae79de3          	bne	a5,a4,80004ed2 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80004f1c:	e4043483          	ld	s1,-448(s0)
    80004f20:	e3843783          	ld	a5,-456(s0)
    80004f24:	f6f4ede3          	bltu	s1,a5,80004e9e <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f28:	e2843783          	ld	a5,-472(s0)
    80004f2c:	94be                	add	s1,s1,a5
    80004f2e:	f6f4ebe3          	bltu	s1,a5,80004ea4 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80004f32:	de043703          	ld	a4,-544(s0)
    80004f36:	8ff9                	and	a5,a5,a4
    80004f38:	fbad                	bnez	a5,80004eaa <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f3a:	e1c42503          	lw	a0,-484(s0)
    80004f3e:	00000097          	auipc	ra,0x0
    80004f42:	c58080e7          	jalr	-936(ra) # 80004b96 <flags2perm>
    80004f46:	86aa                	mv	a3,a0
    80004f48:	8626                	mv	a2,s1
    80004f4a:	85ca                	mv	a1,s2
    80004f4c:	855a                	mv	a0,s6
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	4c2080e7          	jalr	1218(ra) # 80001410 <uvmalloc>
    80004f56:	dea43c23          	sd	a0,-520(s0)
    80004f5a:	d939                	beqz	a0,80004eb0 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f5c:	e2843c03          	ld	s8,-472(s0)
    80004f60:	e2042c83          	lw	s9,-480(s0)
    80004f64:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f68:	f60b83e3          	beqz	s7,80004ece <exec+0x31c>
    80004f6c:	89de                	mv	s3,s7
    80004f6e:	4481                	li	s1,0
    80004f70:	bb95                	j	80004ce4 <exec+0x132>

0000000080004f72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f72:	7179                	addi	sp,sp,-48
    80004f74:	f406                	sd	ra,40(sp)
    80004f76:	f022                	sd	s0,32(sp)
    80004f78:	ec26                	sd	s1,24(sp)
    80004f7a:	e84a                	sd	s2,16(sp)
    80004f7c:	1800                	addi	s0,sp,48
    80004f7e:	892e                	mv	s2,a1
    80004f80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f82:	fdc40593          	addi	a1,s0,-36
    80004f86:	ffffe097          	auipc	ra,0xffffe
    80004f8a:	b86080e7          	jalr	-1146(ra) # 80002b0c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f8e:	fdc42703          	lw	a4,-36(s0)
    80004f92:	47bd                	li	a5,15
    80004f94:	02e7eb63          	bltu	a5,a4,80004fca <argfd+0x58>
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	a14080e7          	jalr	-1516(ra) # 800019ac <myproc>
    80004fa0:	fdc42703          	lw	a4,-36(s0)
    80004fa4:	01a70793          	addi	a5,a4,26
    80004fa8:	078e                	slli	a5,a5,0x3
    80004faa:	953e                	add	a0,a0,a5
    80004fac:	611c                	ld	a5,0(a0)
    80004fae:	c385                	beqz	a5,80004fce <argfd+0x5c>
    return -1;
  if(pfd)
    80004fb0:	00090463          	beqz	s2,80004fb8 <argfd+0x46>
    *pfd = fd;
    80004fb4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fb8:	4501                	li	a0,0
  if(pf)
    80004fba:	c091                	beqz	s1,80004fbe <argfd+0x4c>
    *pf = f;
    80004fbc:	e09c                	sd	a5,0(s1)
}
    80004fbe:	70a2                	ld	ra,40(sp)
    80004fc0:	7402                	ld	s0,32(sp)
    80004fc2:	64e2                	ld	s1,24(sp)
    80004fc4:	6942                	ld	s2,16(sp)
    80004fc6:	6145                	addi	sp,sp,48
    80004fc8:	8082                	ret
    return -1;
    80004fca:	557d                	li	a0,-1
    80004fcc:	bfcd                	j	80004fbe <argfd+0x4c>
    80004fce:	557d                	li	a0,-1
    80004fd0:	b7fd                	j	80004fbe <argfd+0x4c>

0000000080004fd2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fd2:	1101                	addi	sp,sp,-32
    80004fd4:	ec06                	sd	ra,24(sp)
    80004fd6:	e822                	sd	s0,16(sp)
    80004fd8:	e426                	sd	s1,8(sp)
    80004fda:	1000                	addi	s0,sp,32
    80004fdc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	9ce080e7          	jalr	-1586(ra) # 800019ac <myproc>
    80004fe6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fe8:	0d050793          	addi	a5,a0,208
    80004fec:	4501                	li	a0,0
    80004fee:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ff0:	6398                	ld	a4,0(a5)
    80004ff2:	cb19                	beqz	a4,80005008 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ff4:	2505                	addiw	a0,a0,1
    80004ff6:	07a1                	addi	a5,a5,8
    80004ff8:	fed51ce3          	bne	a0,a3,80004ff0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ffc:	557d                	li	a0,-1
}
    80004ffe:	60e2                	ld	ra,24(sp)
    80005000:	6442                	ld	s0,16(sp)
    80005002:	64a2                	ld	s1,8(sp)
    80005004:	6105                	addi	sp,sp,32
    80005006:	8082                	ret
      p->ofile[fd] = f;
    80005008:	01a50793          	addi	a5,a0,26
    8000500c:	078e                	slli	a5,a5,0x3
    8000500e:	963e                	add	a2,a2,a5
    80005010:	e204                	sd	s1,0(a2)
      return fd;
    80005012:	b7f5                	j	80004ffe <fdalloc+0x2c>

0000000080005014 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005014:	715d                	addi	sp,sp,-80
    80005016:	e486                	sd	ra,72(sp)
    80005018:	e0a2                	sd	s0,64(sp)
    8000501a:	fc26                	sd	s1,56(sp)
    8000501c:	f84a                	sd	s2,48(sp)
    8000501e:	f44e                	sd	s3,40(sp)
    80005020:	f052                	sd	s4,32(sp)
    80005022:	ec56                	sd	s5,24(sp)
    80005024:	e85a                	sd	s6,16(sp)
    80005026:	0880                	addi	s0,sp,80
    80005028:	8b2e                	mv	s6,a1
    8000502a:	89b2                	mv	s3,a2
    8000502c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000502e:	fb040593          	addi	a1,s0,-80
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	e3c080e7          	jalr	-452(ra) # 80003e6e <nameiparent>
    8000503a:	84aa                	mv	s1,a0
    8000503c:	14050f63          	beqz	a0,8000519a <create+0x186>
    return 0;

  ilock(dp);
    80005040:	ffffe097          	auipc	ra,0xffffe
    80005044:	66a080e7          	jalr	1642(ra) # 800036aa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005048:	4601                	li	a2,0
    8000504a:	fb040593          	addi	a1,s0,-80
    8000504e:	8526                	mv	a0,s1
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	b3e080e7          	jalr	-1218(ra) # 80003b8e <dirlookup>
    80005058:	8aaa                	mv	s5,a0
    8000505a:	c931                	beqz	a0,800050ae <create+0x9a>
    iunlockput(dp);
    8000505c:	8526                	mv	a0,s1
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	8ae080e7          	jalr	-1874(ra) # 8000390c <iunlockput>
    ilock(ip);
    80005066:	8556                	mv	a0,s5
    80005068:	ffffe097          	auipc	ra,0xffffe
    8000506c:	642080e7          	jalr	1602(ra) # 800036aa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005070:	000b059b          	sext.w	a1,s6
    80005074:	4789                	li	a5,2
    80005076:	02f59563          	bne	a1,a5,800050a0 <create+0x8c>
    8000507a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2e4>
    8000507e:	37f9                	addiw	a5,a5,-2
    80005080:	17c2                	slli	a5,a5,0x30
    80005082:	93c1                	srli	a5,a5,0x30
    80005084:	4705                	li	a4,1
    80005086:	00f76d63          	bltu	a4,a5,800050a0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000508a:	8556                	mv	a0,s5
    8000508c:	60a6                	ld	ra,72(sp)
    8000508e:	6406                	ld	s0,64(sp)
    80005090:	74e2                	ld	s1,56(sp)
    80005092:	7942                	ld	s2,48(sp)
    80005094:	79a2                	ld	s3,40(sp)
    80005096:	7a02                	ld	s4,32(sp)
    80005098:	6ae2                	ld	s5,24(sp)
    8000509a:	6b42                	ld	s6,16(sp)
    8000509c:	6161                	addi	sp,sp,80
    8000509e:	8082                	ret
    iunlockput(ip);
    800050a0:	8556                	mv	a0,s5
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	86a080e7          	jalr	-1942(ra) # 8000390c <iunlockput>
    return 0;
    800050aa:	4a81                	li	s5,0
    800050ac:	bff9                	j	8000508a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050ae:	85da                	mv	a1,s6
    800050b0:	4088                	lw	a0,0(s1)
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	45c080e7          	jalr	1116(ra) # 8000350e <ialloc>
    800050ba:	8a2a                	mv	s4,a0
    800050bc:	c539                	beqz	a0,8000510a <create+0xf6>
  ilock(ip);
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	5ec080e7          	jalr	1516(ra) # 800036aa <ilock>
  ip->major = major;
    800050c6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050ca:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050ce:	4905                	li	s2,1
    800050d0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050d4:	8552                	mv	a0,s4
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	50a080e7          	jalr	1290(ra) # 800035e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050de:	000b059b          	sext.w	a1,s6
    800050e2:	03258b63          	beq	a1,s2,80005118 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e6:	004a2603          	lw	a2,4(s4)
    800050ea:	fb040593          	addi	a1,s0,-80
    800050ee:	8526                	mv	a0,s1
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	cae080e7          	jalr	-850(ra) # 80003d9e <dirlink>
    800050f8:	06054f63          	bltz	a0,80005176 <create+0x162>
  iunlockput(dp);
    800050fc:	8526                	mv	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	80e080e7          	jalr	-2034(ra) # 8000390c <iunlockput>
  return ip;
    80005106:	8ad2                	mv	s5,s4
    80005108:	b749                	j	8000508a <create+0x76>
    iunlockput(dp);
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	800080e7          	jalr	-2048(ra) # 8000390c <iunlockput>
    return 0;
    80005114:	8ad2                	mv	s5,s4
    80005116:	bf95                	j	8000508a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005118:	004a2603          	lw	a2,4(s4)
    8000511c:	00003597          	auipc	a1,0x3
    80005120:	5f458593          	addi	a1,a1,1524 # 80008710 <syscalls+0x2b0>
    80005124:	8552                	mv	a0,s4
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	c78080e7          	jalr	-904(ra) # 80003d9e <dirlink>
    8000512e:	04054463          	bltz	a0,80005176 <create+0x162>
    80005132:	40d0                	lw	a2,4(s1)
    80005134:	00003597          	auipc	a1,0x3
    80005138:	5e458593          	addi	a1,a1,1508 # 80008718 <syscalls+0x2b8>
    8000513c:	8552                	mv	a0,s4
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	c60080e7          	jalr	-928(ra) # 80003d9e <dirlink>
    80005146:	02054863          	bltz	a0,80005176 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000514a:	004a2603          	lw	a2,4(s4)
    8000514e:	fb040593          	addi	a1,s0,-80
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	c4a080e7          	jalr	-950(ra) # 80003d9e <dirlink>
    8000515c:	00054d63          	bltz	a0,80005176 <create+0x162>
    dp->nlink++;  // for ".."
    80005160:	04a4d783          	lhu	a5,74(s1)
    80005164:	2785                	addiw	a5,a5,1
    80005166:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000516a:	8526                	mv	a0,s1
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	474080e7          	jalr	1140(ra) # 800035e0 <iupdate>
    80005174:	b761                	j	800050fc <create+0xe8>
  ip->nlink = 0;
    80005176:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000517a:	8552                	mv	a0,s4
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	464080e7          	jalr	1124(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005184:	8552                	mv	a0,s4
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	786080e7          	jalr	1926(ra) # 8000390c <iunlockput>
  iunlockput(dp);
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	77c080e7          	jalr	1916(ra) # 8000390c <iunlockput>
  return 0;
    80005198:	bdcd                	j	8000508a <create+0x76>
    return 0;
    8000519a:	8aaa                	mv	s5,a0
    8000519c:	b5fd                	j	8000508a <create+0x76>

000000008000519e <sys_dup>:
{
    8000519e:	7179                	addi	sp,sp,-48
    800051a0:	f406                	sd	ra,40(sp)
    800051a2:	f022                	sd	s0,32(sp)
    800051a4:	ec26                	sd	s1,24(sp)
    800051a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051a8:	fd840613          	addi	a2,s0,-40
    800051ac:	4581                	li	a1,0
    800051ae:	4501                	li	a0,0
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	dc2080e7          	jalr	-574(ra) # 80004f72 <argfd>
    return -1;
    800051b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ba:	02054363          	bltz	a0,800051e0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051be:	fd843503          	ld	a0,-40(s0)
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	e10080e7          	jalr	-496(ra) # 80004fd2 <fdalloc>
    800051ca:	84aa                	mv	s1,a0
    return -1;
    800051cc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ce:	00054963          	bltz	a0,800051e0 <sys_dup+0x42>
  filedup(f);
    800051d2:	fd843503          	ld	a0,-40(s0)
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	310080e7          	jalr	784(ra) # 800044e6 <filedup>
  return fd;
    800051de:	87a6                	mv	a5,s1
}
    800051e0:	853e                	mv	a0,a5
    800051e2:	70a2                	ld	ra,40(sp)
    800051e4:	7402                	ld	s0,32(sp)
    800051e6:	64e2                	ld	s1,24(sp)
    800051e8:	6145                	addi	sp,sp,48
    800051ea:	8082                	ret

00000000800051ec <sys_read>:
{
    800051ec:	7179                	addi	sp,sp,-48
    800051ee:	f406                	sd	ra,40(sp)
    800051f0:	f022                	sd	s0,32(sp)
    800051f2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800051f4:	fd840593          	addi	a1,s0,-40
    800051f8:	4505                	li	a0,1
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	932080e7          	jalr	-1742(ra) # 80002b2c <argaddr>
  argint(2, &n);
    80005202:	fe440593          	addi	a1,s0,-28
    80005206:	4509                	li	a0,2
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	904080e7          	jalr	-1788(ra) # 80002b0c <argint>
  if(argfd(0, 0, &f) < 0)
    80005210:	fe840613          	addi	a2,s0,-24
    80005214:	4581                	li	a1,0
    80005216:	4501                	li	a0,0
    80005218:	00000097          	auipc	ra,0x0
    8000521c:	d5a080e7          	jalr	-678(ra) # 80004f72 <argfd>
    80005220:	87aa                	mv	a5,a0
    return -1;
    80005222:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005224:	0007cc63          	bltz	a5,8000523c <sys_read+0x50>
  return fileread(f, p, n);
    80005228:	fe442603          	lw	a2,-28(s0)
    8000522c:	fd843583          	ld	a1,-40(s0)
    80005230:	fe843503          	ld	a0,-24(s0)
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	43e080e7          	jalr	1086(ra) # 80004672 <fileread>
}
    8000523c:	70a2                	ld	ra,40(sp)
    8000523e:	7402                	ld	s0,32(sp)
    80005240:	6145                	addi	sp,sp,48
    80005242:	8082                	ret

0000000080005244 <sys_write>:
{
    80005244:	7179                	addi	sp,sp,-48
    80005246:	f406                	sd	ra,40(sp)
    80005248:	f022                	sd	s0,32(sp)
    8000524a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000524c:	fd840593          	addi	a1,s0,-40
    80005250:	4505                	li	a0,1
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	8da080e7          	jalr	-1830(ra) # 80002b2c <argaddr>
  argint(2, &n);
    8000525a:	fe440593          	addi	a1,s0,-28
    8000525e:	4509                	li	a0,2
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	8ac080e7          	jalr	-1876(ra) # 80002b0c <argint>
  if(argfd(0, 0, &f) < 0)
    80005268:	fe840613          	addi	a2,s0,-24
    8000526c:	4581                	li	a1,0
    8000526e:	4501                	li	a0,0
    80005270:	00000097          	auipc	ra,0x0
    80005274:	d02080e7          	jalr	-766(ra) # 80004f72 <argfd>
    80005278:	87aa                	mv	a5,a0
    return -1;
    8000527a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000527c:	0007cc63          	bltz	a5,80005294 <sys_write+0x50>
  return filewrite(f, p, n);
    80005280:	fe442603          	lw	a2,-28(s0)
    80005284:	fd843583          	ld	a1,-40(s0)
    80005288:	fe843503          	ld	a0,-24(s0)
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	4a8080e7          	jalr	1192(ra) # 80004734 <filewrite>
}
    80005294:	70a2                	ld	ra,40(sp)
    80005296:	7402                	ld	s0,32(sp)
    80005298:	6145                	addi	sp,sp,48
    8000529a:	8082                	ret

000000008000529c <sys_close>:
{
    8000529c:	1101                	addi	sp,sp,-32
    8000529e:	ec06                	sd	ra,24(sp)
    800052a0:	e822                	sd	s0,16(sp)
    800052a2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052a4:	fe040613          	addi	a2,s0,-32
    800052a8:	fec40593          	addi	a1,s0,-20
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	cc4080e7          	jalr	-828(ra) # 80004f72 <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052b8:	02054463          	bltz	a0,800052e0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052bc:	ffffc097          	auipc	ra,0xffffc
    800052c0:	6f0080e7          	jalr	1776(ra) # 800019ac <myproc>
    800052c4:	fec42783          	lw	a5,-20(s0)
    800052c8:	07e9                	addi	a5,a5,26
    800052ca:	078e                	slli	a5,a5,0x3
    800052cc:	97aa                	add	a5,a5,a0
    800052ce:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052d2:	fe043503          	ld	a0,-32(s0)
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	262080e7          	jalr	610(ra) # 80004538 <fileclose>
  return 0;
    800052de:	4781                	li	a5,0
}
    800052e0:	853e                	mv	a0,a5
    800052e2:	60e2                	ld	ra,24(sp)
    800052e4:	6442                	ld	s0,16(sp)
    800052e6:	6105                	addi	sp,sp,32
    800052e8:	8082                	ret

00000000800052ea <sys_fstat>:
{
    800052ea:	1101                	addi	sp,sp,-32
    800052ec:	ec06                	sd	ra,24(sp)
    800052ee:	e822                	sd	s0,16(sp)
    800052f0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800052f2:	fe040593          	addi	a1,s0,-32
    800052f6:	4505                	li	a0,1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	834080e7          	jalr	-1996(ra) # 80002b2c <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005300:	fe840613          	addi	a2,s0,-24
    80005304:	4581                	li	a1,0
    80005306:	4501                	li	a0,0
    80005308:	00000097          	auipc	ra,0x0
    8000530c:	c6a080e7          	jalr	-918(ra) # 80004f72 <argfd>
    80005310:	87aa                	mv	a5,a0
    return -1;
    80005312:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005314:	0007ca63          	bltz	a5,80005328 <sys_fstat+0x3e>
  return filestat(f, st);
    80005318:	fe043583          	ld	a1,-32(s0)
    8000531c:	fe843503          	ld	a0,-24(s0)
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	2e0080e7          	jalr	736(ra) # 80004600 <filestat>
}
    80005328:	60e2                	ld	ra,24(sp)
    8000532a:	6442                	ld	s0,16(sp)
    8000532c:	6105                	addi	sp,sp,32
    8000532e:	8082                	ret

0000000080005330 <sys_link>:
{
    80005330:	7169                	addi	sp,sp,-304
    80005332:	f606                	sd	ra,296(sp)
    80005334:	f222                	sd	s0,288(sp)
    80005336:	ee26                	sd	s1,280(sp)
    80005338:	ea4a                	sd	s2,272(sp)
    8000533a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533c:	08000613          	li	a2,128
    80005340:	ed040593          	addi	a1,s0,-304
    80005344:	4501                	li	a0,0
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	806080e7          	jalr	-2042(ra) # 80002b4c <argstr>
    return -1;
    8000534e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005350:	10054e63          	bltz	a0,8000546c <sys_link+0x13c>
    80005354:	08000613          	li	a2,128
    80005358:	f5040593          	addi	a1,s0,-176
    8000535c:	4505                	li	a0,1
    8000535e:	ffffd097          	auipc	ra,0xffffd
    80005362:	7ee080e7          	jalr	2030(ra) # 80002b4c <argstr>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005368:	10054263          	bltz	a0,8000546c <sys_link+0x13c>
  begin_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	d00080e7          	jalr	-768(ra) # 8000406c <begin_op>
  if((ip = namei(old)) == 0){
    80005374:	ed040513          	addi	a0,s0,-304
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	ad8080e7          	jalr	-1320(ra) # 80003e50 <namei>
    80005380:	84aa                	mv	s1,a0
    80005382:	c551                	beqz	a0,8000540e <sys_link+0xde>
  ilock(ip);
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	326080e7          	jalr	806(ra) # 800036aa <ilock>
  if(ip->type == T_DIR){
    8000538c:	04449703          	lh	a4,68(s1)
    80005390:	4785                	li	a5,1
    80005392:	08f70463          	beq	a4,a5,8000541a <sys_link+0xea>
  ip->nlink++;
    80005396:	04a4d783          	lhu	a5,74(s1)
    8000539a:	2785                	addiw	a5,a5,1
    8000539c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	23e080e7          	jalr	574(ra) # 800035e0 <iupdate>
  iunlock(ip);
    800053aa:	8526                	mv	a0,s1
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	3c0080e7          	jalr	960(ra) # 8000376c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053b4:	fd040593          	addi	a1,s0,-48
    800053b8:	f5040513          	addi	a0,s0,-176
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	ab2080e7          	jalr	-1358(ra) # 80003e6e <nameiparent>
    800053c4:	892a                	mv	s2,a0
    800053c6:	c935                	beqz	a0,8000543a <sys_link+0x10a>
  ilock(dp);
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	2e2080e7          	jalr	738(ra) # 800036aa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053d0:	00092703          	lw	a4,0(s2)
    800053d4:	409c                	lw	a5,0(s1)
    800053d6:	04f71d63          	bne	a4,a5,80005430 <sys_link+0x100>
    800053da:	40d0                	lw	a2,4(s1)
    800053dc:	fd040593          	addi	a1,s0,-48
    800053e0:	854a                	mv	a0,s2
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	9bc080e7          	jalr	-1604(ra) # 80003d9e <dirlink>
    800053ea:	04054363          	bltz	a0,80005430 <sys_link+0x100>
  iunlockput(dp);
    800053ee:	854a                	mv	a0,s2
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	51c080e7          	jalr	1308(ra) # 8000390c <iunlockput>
  iput(ip);
    800053f8:	8526                	mv	a0,s1
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	46a080e7          	jalr	1130(ra) # 80003864 <iput>
  end_op();
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	cea080e7          	jalr	-790(ra) # 800040ec <end_op>
  return 0;
    8000540a:	4781                	li	a5,0
    8000540c:	a085                	j	8000546c <sys_link+0x13c>
    end_op();
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	cde080e7          	jalr	-802(ra) # 800040ec <end_op>
    return -1;
    80005416:	57fd                	li	a5,-1
    80005418:	a891                	j	8000546c <sys_link+0x13c>
    iunlockput(ip);
    8000541a:	8526                	mv	a0,s1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	4f0080e7          	jalr	1264(ra) # 8000390c <iunlockput>
    end_op();
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	cc8080e7          	jalr	-824(ra) # 800040ec <end_op>
    return -1;
    8000542c:	57fd                	li	a5,-1
    8000542e:	a83d                	j	8000546c <sys_link+0x13c>
    iunlockput(dp);
    80005430:	854a                	mv	a0,s2
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	4da080e7          	jalr	1242(ra) # 8000390c <iunlockput>
  ilock(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	26e080e7          	jalr	622(ra) # 800036aa <ilock>
  ip->nlink--;
    80005444:	04a4d783          	lhu	a5,74(s1)
    80005448:	37fd                	addiw	a5,a5,-1
    8000544a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000544e:	8526                	mv	a0,s1
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	190080e7          	jalr	400(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	4b2080e7          	jalr	1202(ra) # 8000390c <iunlockput>
  end_op();
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	c8a080e7          	jalr	-886(ra) # 800040ec <end_op>
  return -1;
    8000546a:	57fd                	li	a5,-1
}
    8000546c:	853e                	mv	a0,a5
    8000546e:	70b2                	ld	ra,296(sp)
    80005470:	7412                	ld	s0,288(sp)
    80005472:	64f2                	ld	s1,280(sp)
    80005474:	6952                	ld	s2,272(sp)
    80005476:	6155                	addi	sp,sp,304
    80005478:	8082                	ret

000000008000547a <sys_unlink>:
{
    8000547a:	7151                	addi	sp,sp,-240
    8000547c:	f586                	sd	ra,232(sp)
    8000547e:	f1a2                	sd	s0,224(sp)
    80005480:	eda6                	sd	s1,216(sp)
    80005482:	e9ca                	sd	s2,208(sp)
    80005484:	e5ce                	sd	s3,200(sp)
    80005486:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005488:	08000613          	li	a2,128
    8000548c:	f3040593          	addi	a1,s0,-208
    80005490:	4501                	li	a0,0
    80005492:	ffffd097          	auipc	ra,0xffffd
    80005496:	6ba080e7          	jalr	1722(ra) # 80002b4c <argstr>
    8000549a:	18054163          	bltz	a0,8000561c <sys_unlink+0x1a2>
  begin_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	bce080e7          	jalr	-1074(ra) # 8000406c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054a6:	fb040593          	addi	a1,s0,-80
    800054aa:	f3040513          	addi	a0,s0,-208
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	9c0080e7          	jalr	-1600(ra) # 80003e6e <nameiparent>
    800054b6:	84aa                	mv	s1,a0
    800054b8:	c979                	beqz	a0,8000558e <sys_unlink+0x114>
  ilock(dp);
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	1f0080e7          	jalr	496(ra) # 800036aa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054c2:	00003597          	auipc	a1,0x3
    800054c6:	24e58593          	addi	a1,a1,590 # 80008710 <syscalls+0x2b0>
    800054ca:	fb040513          	addi	a0,s0,-80
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	6a6080e7          	jalr	1702(ra) # 80003b74 <namecmp>
    800054d6:	14050a63          	beqz	a0,8000562a <sys_unlink+0x1b0>
    800054da:	00003597          	auipc	a1,0x3
    800054de:	23e58593          	addi	a1,a1,574 # 80008718 <syscalls+0x2b8>
    800054e2:	fb040513          	addi	a0,s0,-80
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	68e080e7          	jalr	1678(ra) # 80003b74 <namecmp>
    800054ee:	12050e63          	beqz	a0,8000562a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054f2:	f2c40613          	addi	a2,s0,-212
    800054f6:	fb040593          	addi	a1,s0,-80
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	692080e7          	jalr	1682(ra) # 80003b8e <dirlookup>
    80005504:	892a                	mv	s2,a0
    80005506:	12050263          	beqz	a0,8000562a <sys_unlink+0x1b0>
  ilock(ip);
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	1a0080e7          	jalr	416(ra) # 800036aa <ilock>
  if(ip->nlink < 1)
    80005512:	04a91783          	lh	a5,74(s2)
    80005516:	08f05263          	blez	a5,8000559a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000551a:	04491703          	lh	a4,68(s2)
    8000551e:	4785                	li	a5,1
    80005520:	08f70563          	beq	a4,a5,800055aa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005524:	4641                	li	a2,16
    80005526:	4581                	li	a1,0
    80005528:	fc040513          	addi	a0,s0,-64
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	7a6080e7          	jalr	1958(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005534:	4741                	li	a4,16
    80005536:	f2c42683          	lw	a3,-212(s0)
    8000553a:	fc040613          	addi	a2,s0,-64
    8000553e:	4581                	li	a1,0
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	514080e7          	jalr	1300(ra) # 80003a56 <writei>
    8000554a:	47c1                	li	a5,16
    8000554c:	0af51563          	bne	a0,a5,800055f6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005550:	04491703          	lh	a4,68(s2)
    80005554:	4785                	li	a5,1
    80005556:	0af70863          	beq	a4,a5,80005606 <sys_unlink+0x18c>
  iunlockput(dp);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	3b0080e7          	jalr	944(ra) # 8000390c <iunlockput>
  ip->nlink--;
    80005564:	04a95783          	lhu	a5,74(s2)
    80005568:	37fd                	addiw	a5,a5,-1
    8000556a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000556e:	854a                	mv	a0,s2
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	070080e7          	jalr	112(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005578:	854a                	mv	a0,s2
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	392080e7          	jalr	914(ra) # 8000390c <iunlockput>
  end_op();
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	b6a080e7          	jalr	-1174(ra) # 800040ec <end_op>
  return 0;
    8000558a:	4501                	li	a0,0
    8000558c:	a84d                	j	8000563e <sys_unlink+0x1c4>
    end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	b5e080e7          	jalr	-1186(ra) # 800040ec <end_op>
    return -1;
    80005596:	557d                	li	a0,-1
    80005598:	a05d                	j	8000563e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000559a:	00003517          	auipc	a0,0x3
    8000559e:	18650513          	addi	a0,a0,390 # 80008720 <syscalls+0x2c0>
    800055a2:	ffffb097          	auipc	ra,0xffffb
    800055a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055aa:	04c92703          	lw	a4,76(s2)
    800055ae:	02000793          	li	a5,32
    800055b2:	f6e7f9e3          	bgeu	a5,a4,80005524 <sys_unlink+0xaa>
    800055b6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ba:	4741                	li	a4,16
    800055bc:	86ce                	mv	a3,s3
    800055be:	f1840613          	addi	a2,s0,-232
    800055c2:	4581                	li	a1,0
    800055c4:	854a                	mv	a0,s2
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	398080e7          	jalr	920(ra) # 8000395e <readi>
    800055ce:	47c1                	li	a5,16
    800055d0:	00f51b63          	bne	a0,a5,800055e6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055d4:	f1845783          	lhu	a5,-232(s0)
    800055d8:	e7a1                	bnez	a5,80005620 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055da:	29c1                	addiw	s3,s3,16
    800055dc:	04c92783          	lw	a5,76(s2)
    800055e0:	fcf9ede3          	bltu	s3,a5,800055ba <sys_unlink+0x140>
    800055e4:	b781                	j	80005524 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055e6:	00003517          	auipc	a0,0x3
    800055ea:	15250513          	addi	a0,a0,338 # 80008738 <syscalls+0x2d8>
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
    panic("unlink: writei");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	15a50513          	addi	a0,a0,346 # 80008750 <syscalls+0x2f0>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    dp->nlink--;
    80005606:	04a4d783          	lhu	a5,74(s1)
    8000560a:	37fd                	addiw	a5,a5,-1
    8000560c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	fce080e7          	jalr	-50(ra) # 800035e0 <iupdate>
    8000561a:	b781                	j	8000555a <sys_unlink+0xe0>
    return -1;
    8000561c:	557d                	li	a0,-1
    8000561e:	a005                	j	8000563e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	2ea080e7          	jalr	746(ra) # 8000390c <iunlockput>
  iunlockput(dp);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	2e0080e7          	jalr	736(ra) # 8000390c <iunlockput>
  end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	ab8080e7          	jalr	-1352(ra) # 800040ec <end_op>
  return -1;
    8000563c:	557d                	li	a0,-1
}
    8000563e:	70ae                	ld	ra,232(sp)
    80005640:	740e                	ld	s0,224(sp)
    80005642:	64ee                	ld	s1,216(sp)
    80005644:	694e                	ld	s2,208(sp)
    80005646:	69ae                	ld	s3,200(sp)
    80005648:	616d                	addi	sp,sp,240
    8000564a:	8082                	ret

000000008000564c <sys_open>:

uint64
sys_open(void)
{
    8000564c:	7131                	addi	sp,sp,-192
    8000564e:	fd06                	sd	ra,184(sp)
    80005650:	f922                	sd	s0,176(sp)
    80005652:	f526                	sd	s1,168(sp)
    80005654:	f14a                	sd	s2,160(sp)
    80005656:	ed4e                	sd	s3,152(sp)
    80005658:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000565a:	f4c40593          	addi	a1,s0,-180
    8000565e:	4505                	li	a0,1
    80005660:	ffffd097          	auipc	ra,0xffffd
    80005664:	4ac080e7          	jalr	1196(ra) # 80002b0c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005668:	08000613          	li	a2,128
    8000566c:	f5040593          	addi	a1,s0,-176
    80005670:	4501                	li	a0,0
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	4da080e7          	jalr	1242(ra) # 80002b4c <argstr>
    8000567a:	87aa                	mv	a5,a0
    return -1;
    8000567c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000567e:	0a07c963          	bltz	a5,80005730 <sys_open+0xe4>

  begin_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	9ea080e7          	jalr	-1558(ra) # 8000406c <begin_op>

  if(omode & O_CREATE){
    8000568a:	f4c42783          	lw	a5,-180(s0)
    8000568e:	2007f793          	andi	a5,a5,512
    80005692:	cfc5                	beqz	a5,8000574a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005694:	4681                	li	a3,0
    80005696:	4601                	li	a2,0
    80005698:	4589                	li	a1,2
    8000569a:	f5040513          	addi	a0,s0,-176
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	976080e7          	jalr	-1674(ra) # 80005014 <create>
    800056a6:	84aa                	mv	s1,a0
    if(ip == 0){
    800056a8:	c959                	beqz	a0,8000573e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056aa:	04449703          	lh	a4,68(s1)
    800056ae:	478d                	li	a5,3
    800056b0:	00f71763          	bne	a4,a5,800056be <sys_open+0x72>
    800056b4:	0464d703          	lhu	a4,70(s1)
    800056b8:	47a5                	li	a5,9
    800056ba:	0ce7ed63          	bltu	a5,a4,80005794 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	dbe080e7          	jalr	-578(ra) # 8000447c <filealloc>
    800056c6:	89aa                	mv	s3,a0
    800056c8:	10050363          	beqz	a0,800057ce <sys_open+0x182>
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	906080e7          	jalr	-1786(ra) # 80004fd2 <fdalloc>
    800056d4:	892a                	mv	s2,a0
    800056d6:	0e054763          	bltz	a0,800057c4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056da:	04449703          	lh	a4,68(s1)
    800056de:	478d                	li	a5,3
    800056e0:	0cf70563          	beq	a4,a5,800057aa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056e4:	4789                	li	a5,2
    800056e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056ee:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056f2:	f4c42783          	lw	a5,-180(s0)
    800056f6:	0017c713          	xori	a4,a5,1
    800056fa:	8b05                	andi	a4,a4,1
    800056fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005700:	0037f713          	andi	a4,a5,3
    80005704:	00e03733          	snez	a4,a4
    80005708:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000570c:	4007f793          	andi	a5,a5,1024
    80005710:	c791                	beqz	a5,8000571c <sys_open+0xd0>
    80005712:	04449703          	lh	a4,68(s1)
    80005716:	4789                	li	a5,2
    80005718:	0af70063          	beq	a4,a5,800057b8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	04e080e7          	jalr	78(ra) # 8000376c <iunlock>
  end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	9c6080e7          	jalr	-1594(ra) # 800040ec <end_op>

  return fd;
    8000572e:	854a                	mv	a0,s2
}
    80005730:	70ea                	ld	ra,184(sp)
    80005732:	744a                	ld	s0,176(sp)
    80005734:	74aa                	ld	s1,168(sp)
    80005736:	790a                	ld	s2,160(sp)
    80005738:	69ea                	ld	s3,152(sp)
    8000573a:	6129                	addi	sp,sp,192
    8000573c:	8082                	ret
      end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	9ae080e7          	jalr	-1618(ra) # 800040ec <end_op>
      return -1;
    80005746:	557d                	li	a0,-1
    80005748:	b7e5                	j	80005730 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000574a:	f5040513          	addi	a0,s0,-176
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	702080e7          	jalr	1794(ra) # 80003e50 <namei>
    80005756:	84aa                	mv	s1,a0
    80005758:	c905                	beqz	a0,80005788 <sys_open+0x13c>
    ilock(ip);
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	f50080e7          	jalr	-176(ra) # 800036aa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005762:	04449703          	lh	a4,68(s1)
    80005766:	4785                	li	a5,1
    80005768:	f4f711e3          	bne	a4,a5,800056aa <sys_open+0x5e>
    8000576c:	f4c42783          	lw	a5,-180(s0)
    80005770:	d7b9                	beqz	a5,800056be <sys_open+0x72>
      iunlockput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	198080e7          	jalr	408(ra) # 8000390c <iunlockput>
      end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	970080e7          	jalr	-1680(ra) # 800040ec <end_op>
      return -1;
    80005784:	557d                	li	a0,-1
    80005786:	b76d                	j	80005730 <sys_open+0xe4>
      end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	964080e7          	jalr	-1692(ra) # 800040ec <end_op>
      return -1;
    80005790:	557d                	li	a0,-1
    80005792:	bf79                	j	80005730 <sys_open+0xe4>
    iunlockput(ip);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	176080e7          	jalr	374(ra) # 8000390c <iunlockput>
    end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	94e080e7          	jalr	-1714(ra) # 800040ec <end_op>
    return -1;
    800057a6:	557d                	li	a0,-1
    800057a8:	b761                	j	80005730 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057aa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057ae:	04649783          	lh	a5,70(s1)
    800057b2:	02f99223          	sh	a5,36(s3)
    800057b6:	bf25                	j	800056ee <sys_open+0xa2>
    itrunc(ip);
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	ffe080e7          	jalr	-2(ra) # 800037b8 <itrunc>
    800057c2:	bfa9                	j	8000571c <sys_open+0xd0>
      fileclose(f);
    800057c4:	854e                	mv	a0,s3
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	d72080e7          	jalr	-654(ra) # 80004538 <fileclose>
    iunlockput(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	13c080e7          	jalr	316(ra) # 8000390c <iunlockput>
    end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	914080e7          	jalr	-1772(ra) # 800040ec <end_op>
    return -1;
    800057e0:	557d                	li	a0,-1
    800057e2:	b7b9                	j	80005730 <sys_open+0xe4>

00000000800057e4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057e4:	7175                	addi	sp,sp,-144
    800057e6:	e506                	sd	ra,136(sp)
    800057e8:	e122                	sd	s0,128(sp)
    800057ea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	880080e7          	jalr	-1920(ra) # 8000406c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057f4:	08000613          	li	a2,128
    800057f8:	f7040593          	addi	a1,s0,-144
    800057fc:	4501                	li	a0,0
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	34e080e7          	jalr	846(ra) # 80002b4c <argstr>
    80005806:	02054963          	bltz	a0,80005838 <sys_mkdir+0x54>
    8000580a:	4681                	li	a3,0
    8000580c:	4601                	li	a2,0
    8000580e:	4585                	li	a1,1
    80005810:	f7040513          	addi	a0,s0,-144
    80005814:	00000097          	auipc	ra,0x0
    80005818:	800080e7          	jalr	-2048(ra) # 80005014 <create>
    8000581c:	cd11                	beqz	a0,80005838 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	0ee080e7          	jalr	238(ra) # 8000390c <iunlockput>
  end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	8c6080e7          	jalr	-1850(ra) # 800040ec <end_op>
  return 0;
    8000582e:	4501                	li	a0,0
}
    80005830:	60aa                	ld	ra,136(sp)
    80005832:	640a                	ld	s0,128(sp)
    80005834:	6149                	addi	sp,sp,144
    80005836:	8082                	ret
    end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	8b4080e7          	jalr	-1868(ra) # 800040ec <end_op>
    return -1;
    80005840:	557d                	li	a0,-1
    80005842:	b7fd                	j	80005830 <sys_mkdir+0x4c>

0000000080005844 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005844:	7135                	addi	sp,sp,-160
    80005846:	ed06                	sd	ra,152(sp)
    80005848:	e922                	sd	s0,144(sp)
    8000584a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	820080e7          	jalr	-2016(ra) # 8000406c <begin_op>
  argint(1, &major);
    80005854:	f6c40593          	addi	a1,s0,-148
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	2b2080e7          	jalr	690(ra) # 80002b0c <argint>
  argint(2, &minor);
    80005862:	f6840593          	addi	a1,s0,-152
    80005866:	4509                	li	a0,2
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	2a4080e7          	jalr	676(ra) # 80002b0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005870:	08000613          	li	a2,128
    80005874:	f7040593          	addi	a1,s0,-144
    80005878:	4501                	li	a0,0
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	2d2080e7          	jalr	722(ra) # 80002b4c <argstr>
    80005882:	02054b63          	bltz	a0,800058b8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005886:	f6841683          	lh	a3,-152(s0)
    8000588a:	f6c41603          	lh	a2,-148(s0)
    8000588e:	458d                	li	a1,3
    80005890:	f7040513          	addi	a0,s0,-144
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	780080e7          	jalr	1920(ra) # 80005014 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000589c:	cd11                	beqz	a0,800058b8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	06e080e7          	jalr	110(ra) # 8000390c <iunlockput>
  end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	846080e7          	jalr	-1978(ra) # 800040ec <end_op>
  return 0;
    800058ae:	4501                	li	a0,0
}
    800058b0:	60ea                	ld	ra,152(sp)
    800058b2:	644a                	ld	s0,144(sp)
    800058b4:	610d                	addi	sp,sp,160
    800058b6:	8082                	ret
    end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	834080e7          	jalr	-1996(ra) # 800040ec <end_op>
    return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	b7fd                	j	800058b0 <sys_mknod+0x6c>

00000000800058c4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058c4:	7135                	addi	sp,sp,-160
    800058c6:	ed06                	sd	ra,152(sp)
    800058c8:	e922                	sd	s0,144(sp)
    800058ca:	e526                	sd	s1,136(sp)
    800058cc:	e14a                	sd	s2,128(sp)
    800058ce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058d0:	ffffc097          	auipc	ra,0xffffc
    800058d4:	0dc080e7          	jalr	220(ra) # 800019ac <myproc>
    800058d8:	892a                	mv	s2,a0
  
  begin_op();
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	792080e7          	jalr	1938(ra) # 8000406c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058e2:	08000613          	li	a2,128
    800058e6:	f6040593          	addi	a1,s0,-160
    800058ea:	4501                	li	a0,0
    800058ec:	ffffd097          	auipc	ra,0xffffd
    800058f0:	260080e7          	jalr	608(ra) # 80002b4c <argstr>
    800058f4:	04054b63          	bltz	a0,8000594a <sys_chdir+0x86>
    800058f8:	f6040513          	addi	a0,s0,-160
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	554080e7          	jalr	1364(ra) # 80003e50 <namei>
    80005904:	84aa                	mv	s1,a0
    80005906:	c131                	beqz	a0,8000594a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	da2080e7          	jalr	-606(ra) # 800036aa <ilock>
  if(ip->type != T_DIR){
    80005910:	04449703          	lh	a4,68(s1)
    80005914:	4785                	li	a5,1
    80005916:	04f71063          	bne	a4,a5,80005956 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	e50080e7          	jalr	-432(ra) # 8000376c <iunlock>
  iput(p->cwd);
    80005924:	15093503          	ld	a0,336(s2)
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	f3c080e7          	jalr	-196(ra) # 80003864 <iput>
  end_op();
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	7bc080e7          	jalr	1980(ra) # 800040ec <end_op>
  p->cwd = ip;
    80005938:	14993823          	sd	s1,336(s2)
  return 0;
    8000593c:	4501                	li	a0,0
}
    8000593e:	60ea                	ld	ra,152(sp)
    80005940:	644a                	ld	s0,144(sp)
    80005942:	64aa                	ld	s1,136(sp)
    80005944:	690a                	ld	s2,128(sp)
    80005946:	610d                	addi	sp,sp,160
    80005948:	8082                	ret
    end_op();
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	7a2080e7          	jalr	1954(ra) # 800040ec <end_op>
    return -1;
    80005952:	557d                	li	a0,-1
    80005954:	b7ed                	j	8000593e <sys_chdir+0x7a>
    iunlockput(ip);
    80005956:	8526                	mv	a0,s1
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	fb4080e7          	jalr	-76(ra) # 8000390c <iunlockput>
    end_op();
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	78c080e7          	jalr	1932(ra) # 800040ec <end_op>
    return -1;
    80005968:	557d                	li	a0,-1
    8000596a:	bfd1                	j	8000593e <sys_chdir+0x7a>

000000008000596c <sys_exec>:

uint64
sys_exec(void)
{
    8000596c:	7145                	addi	sp,sp,-464
    8000596e:	e786                	sd	ra,456(sp)
    80005970:	e3a2                	sd	s0,448(sp)
    80005972:	ff26                	sd	s1,440(sp)
    80005974:	fb4a                	sd	s2,432(sp)
    80005976:	f74e                	sd	s3,424(sp)
    80005978:	f352                	sd	s4,416(sp)
    8000597a:	ef56                	sd	s5,408(sp)
    8000597c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000597e:	e3840593          	addi	a1,s0,-456
    80005982:	4505                	li	a0,1
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	1a8080e7          	jalr	424(ra) # 80002b2c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000598c:	08000613          	li	a2,128
    80005990:	f4040593          	addi	a1,s0,-192
    80005994:	4501                	li	a0,0
    80005996:	ffffd097          	auipc	ra,0xffffd
    8000599a:	1b6080e7          	jalr	438(ra) # 80002b4c <argstr>
    8000599e:	87aa                	mv	a5,a0
    return -1;
    800059a0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059a2:	0c07c263          	bltz	a5,80005a66 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059a6:	10000613          	li	a2,256
    800059aa:	4581                	li	a1,0
    800059ac:	e4040513          	addi	a0,s0,-448
    800059b0:	ffffb097          	auipc	ra,0xffffb
    800059b4:	322080e7          	jalr	802(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059b8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059bc:	89a6                	mv	s3,s1
    800059be:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059c0:	02000a13          	li	s4,32
    800059c4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059c8:	00391793          	slli	a5,s2,0x3
    800059cc:	e3040593          	addi	a1,s0,-464
    800059d0:	e3843503          	ld	a0,-456(s0)
    800059d4:	953e                	add	a0,a0,a5
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	098080e7          	jalr	152(ra) # 80002a6e <fetchaddr>
    800059de:	02054a63          	bltz	a0,80005a12 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059e2:	e3043783          	ld	a5,-464(s0)
    800059e6:	c3b9                	beqz	a5,80005a2c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059e8:	ffffb097          	auipc	ra,0xffffb
    800059ec:	0fe080e7          	jalr	254(ra) # 80000ae6 <kalloc>
    800059f0:	85aa                	mv	a1,a0
    800059f2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059f6:	cd11                	beqz	a0,80005a12 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059f8:	6605                	lui	a2,0x1
    800059fa:	e3043503          	ld	a0,-464(s0)
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	0c2080e7          	jalr	194(ra) # 80002ac0 <fetchstr>
    80005a06:	00054663          	bltz	a0,80005a12 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a0a:	0905                	addi	s2,s2,1
    80005a0c:	09a1                	addi	s3,s3,8
    80005a0e:	fb491be3          	bne	s2,s4,800059c4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a12:	10048913          	addi	s2,s1,256
    80005a16:	6088                	ld	a0,0(s1)
    80005a18:	c531                	beqz	a0,80005a64 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a1a:	ffffb097          	auipc	ra,0xffffb
    80005a1e:	fd0080e7          	jalr	-48(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a22:	04a1                	addi	s1,s1,8
    80005a24:	ff2499e3          	bne	s1,s2,80005a16 <sys_exec+0xaa>
  return -1;
    80005a28:	557d                	li	a0,-1
    80005a2a:	a835                	j	80005a66 <sys_exec+0xfa>
      argv[i] = 0;
    80005a2c:	0a8e                	slli	s5,s5,0x3
    80005a2e:	fc040793          	addi	a5,s0,-64
    80005a32:	9abe                	add	s5,s5,a5
    80005a34:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a38:	e4040593          	addi	a1,s0,-448
    80005a3c:	f4040513          	addi	a0,s0,-192
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	172080e7          	jalr	370(ra) # 80004bb2 <exec>
    80005a48:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4a:	10048993          	addi	s3,s1,256
    80005a4e:	6088                	ld	a0,0(s1)
    80005a50:	c901                	beqz	a0,80005a60 <sys_exec+0xf4>
    kfree(argv[i]);
    80005a52:	ffffb097          	auipc	ra,0xffffb
    80005a56:	f98080e7          	jalr	-104(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a5a:	04a1                	addi	s1,s1,8
    80005a5c:	ff3499e3          	bne	s1,s3,80005a4e <sys_exec+0xe2>
  return ret;
    80005a60:	854a                	mv	a0,s2
    80005a62:	a011                	j	80005a66 <sys_exec+0xfa>
  return -1;
    80005a64:	557d                	li	a0,-1
}
    80005a66:	60be                	ld	ra,456(sp)
    80005a68:	641e                	ld	s0,448(sp)
    80005a6a:	74fa                	ld	s1,440(sp)
    80005a6c:	795a                	ld	s2,432(sp)
    80005a6e:	79ba                	ld	s3,424(sp)
    80005a70:	7a1a                	ld	s4,416(sp)
    80005a72:	6afa                	ld	s5,408(sp)
    80005a74:	6179                	addi	sp,sp,464
    80005a76:	8082                	ret

0000000080005a78 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a78:	7139                	addi	sp,sp,-64
    80005a7a:	fc06                	sd	ra,56(sp)
    80005a7c:	f822                	sd	s0,48(sp)
    80005a7e:	f426                	sd	s1,40(sp)
    80005a80:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a82:	ffffc097          	auipc	ra,0xffffc
    80005a86:	f2a080e7          	jalr	-214(ra) # 800019ac <myproc>
    80005a8a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005a8c:	fd840593          	addi	a1,s0,-40
    80005a90:	4501                	li	a0,0
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	09a080e7          	jalr	154(ra) # 80002b2c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005a9a:	fc840593          	addi	a1,s0,-56
    80005a9e:	fd040513          	addi	a0,s0,-48
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	dc6080e7          	jalr	-570(ra) # 80004868 <pipealloc>
    return -1;
    80005aaa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aac:	0c054463          	bltz	a0,80005b74 <sys_pipe+0xfc>
  fd0 = -1;
    80005ab0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ab4:	fd043503          	ld	a0,-48(s0)
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	51a080e7          	jalr	1306(ra) # 80004fd2 <fdalloc>
    80005ac0:	fca42223          	sw	a0,-60(s0)
    80005ac4:	08054b63          	bltz	a0,80005b5a <sys_pipe+0xe2>
    80005ac8:	fc843503          	ld	a0,-56(s0)
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	506080e7          	jalr	1286(ra) # 80004fd2 <fdalloc>
    80005ad4:	fca42023          	sw	a0,-64(s0)
    80005ad8:	06054863          	bltz	a0,80005b48 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005adc:	4691                	li	a3,4
    80005ade:	fc440613          	addi	a2,s0,-60
    80005ae2:	fd843583          	ld	a1,-40(s0)
    80005ae6:	68a8                	ld	a0,80(s1)
    80005ae8:	ffffc097          	auipc	ra,0xffffc
    80005aec:	b80080e7          	jalr	-1152(ra) # 80001668 <copyout>
    80005af0:	02054063          	bltz	a0,80005b10 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005af4:	4691                	li	a3,4
    80005af6:	fc040613          	addi	a2,s0,-64
    80005afa:	fd843583          	ld	a1,-40(s0)
    80005afe:	0591                	addi	a1,a1,4
    80005b00:	68a8                	ld	a0,80(s1)
    80005b02:	ffffc097          	auipc	ra,0xffffc
    80005b06:	b66080e7          	jalr	-1178(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b0c:	06055463          	bgez	a0,80005b74 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b10:	fc442783          	lw	a5,-60(s0)
    80005b14:	07e9                	addi	a5,a5,26
    80005b16:	078e                	slli	a5,a5,0x3
    80005b18:	97a6                	add	a5,a5,s1
    80005b1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b1e:	fc042503          	lw	a0,-64(s0)
    80005b22:	0569                	addi	a0,a0,26
    80005b24:	050e                	slli	a0,a0,0x3
    80005b26:	94aa                	add	s1,s1,a0
    80005b28:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b2c:	fd043503          	ld	a0,-48(s0)
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	a08080e7          	jalr	-1528(ra) # 80004538 <fileclose>
    fileclose(wf);
    80005b38:	fc843503          	ld	a0,-56(s0)
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	9fc080e7          	jalr	-1540(ra) # 80004538 <fileclose>
    return -1;
    80005b44:	57fd                	li	a5,-1
    80005b46:	a03d                	j	80005b74 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b48:	fc442783          	lw	a5,-60(s0)
    80005b4c:	0007c763          	bltz	a5,80005b5a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b50:	07e9                	addi	a5,a5,26
    80005b52:	078e                	slli	a5,a5,0x3
    80005b54:	94be                	add	s1,s1,a5
    80005b56:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b5a:	fd043503          	ld	a0,-48(s0)
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	9da080e7          	jalr	-1574(ra) # 80004538 <fileclose>
    fileclose(wf);
    80005b66:	fc843503          	ld	a0,-56(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	9ce080e7          	jalr	-1586(ra) # 80004538 <fileclose>
    return -1;
    80005b72:	57fd                	li	a5,-1
}
    80005b74:	853e                	mv	a0,a5
    80005b76:	70e2                	ld	ra,56(sp)
    80005b78:	7442                	ld	s0,48(sp)
    80005b7a:	74a2                	ld	s1,40(sp)
    80005b7c:	6121                	addi	sp,sp,64
    80005b7e:	8082                	ret

0000000080005b80 <kernelvec>:
    80005b80:	7111                	addi	sp,sp,-256
    80005b82:	e006                	sd	ra,0(sp)
    80005b84:	e40a                	sd	sp,8(sp)
    80005b86:	e80e                	sd	gp,16(sp)
    80005b88:	ec12                	sd	tp,24(sp)
    80005b8a:	f016                	sd	t0,32(sp)
    80005b8c:	f41a                	sd	t1,40(sp)
    80005b8e:	f81e                	sd	t2,48(sp)
    80005b90:	fc22                	sd	s0,56(sp)
    80005b92:	e0a6                	sd	s1,64(sp)
    80005b94:	e4aa                	sd	a0,72(sp)
    80005b96:	e8ae                	sd	a1,80(sp)
    80005b98:	ecb2                	sd	a2,88(sp)
    80005b9a:	f0b6                	sd	a3,96(sp)
    80005b9c:	f4ba                	sd	a4,104(sp)
    80005b9e:	f8be                	sd	a5,112(sp)
    80005ba0:	fcc2                	sd	a6,120(sp)
    80005ba2:	e146                	sd	a7,128(sp)
    80005ba4:	e54a                	sd	s2,136(sp)
    80005ba6:	e94e                	sd	s3,144(sp)
    80005ba8:	ed52                	sd	s4,152(sp)
    80005baa:	f156                	sd	s5,160(sp)
    80005bac:	f55a                	sd	s6,168(sp)
    80005bae:	f95e                	sd	s7,176(sp)
    80005bb0:	fd62                	sd	s8,184(sp)
    80005bb2:	e1e6                	sd	s9,192(sp)
    80005bb4:	e5ea                	sd	s10,200(sp)
    80005bb6:	e9ee                	sd	s11,208(sp)
    80005bb8:	edf2                	sd	t3,216(sp)
    80005bba:	f1f6                	sd	t4,224(sp)
    80005bbc:	f5fa                	sd	t5,232(sp)
    80005bbe:	f9fe                	sd	t6,240(sp)
    80005bc0:	d7bfc0ef          	jal	ra,8000293a <kerneltrap>
    80005bc4:	6082                	ld	ra,0(sp)
    80005bc6:	6122                	ld	sp,8(sp)
    80005bc8:	61c2                	ld	gp,16(sp)
    80005bca:	7282                	ld	t0,32(sp)
    80005bcc:	7322                	ld	t1,40(sp)
    80005bce:	73c2                	ld	t2,48(sp)
    80005bd0:	7462                	ld	s0,56(sp)
    80005bd2:	6486                	ld	s1,64(sp)
    80005bd4:	6526                	ld	a0,72(sp)
    80005bd6:	65c6                	ld	a1,80(sp)
    80005bd8:	6666                	ld	a2,88(sp)
    80005bda:	7686                	ld	a3,96(sp)
    80005bdc:	7726                	ld	a4,104(sp)
    80005bde:	77c6                	ld	a5,112(sp)
    80005be0:	7866                	ld	a6,120(sp)
    80005be2:	688a                	ld	a7,128(sp)
    80005be4:	692a                	ld	s2,136(sp)
    80005be6:	69ca                	ld	s3,144(sp)
    80005be8:	6a6a                	ld	s4,152(sp)
    80005bea:	7a8a                	ld	s5,160(sp)
    80005bec:	7b2a                	ld	s6,168(sp)
    80005bee:	7bca                	ld	s7,176(sp)
    80005bf0:	7c6a                	ld	s8,184(sp)
    80005bf2:	6c8e                	ld	s9,192(sp)
    80005bf4:	6d2e                	ld	s10,200(sp)
    80005bf6:	6dce                	ld	s11,208(sp)
    80005bf8:	6e6e                	ld	t3,216(sp)
    80005bfa:	7e8e                	ld	t4,224(sp)
    80005bfc:	7f2e                	ld	t5,232(sp)
    80005bfe:	7fce                	ld	t6,240(sp)
    80005c00:	6111                	addi	sp,sp,256
    80005c02:	10200073          	sret
    80005c06:	00000013          	nop
    80005c0a:	00000013          	nop
    80005c0e:	0001                	nop

0000000080005c10 <timervec>:
    80005c10:	34051573          	csrrw	a0,mscratch,a0
    80005c14:	e10c                	sd	a1,0(a0)
    80005c16:	e510                	sd	a2,8(a0)
    80005c18:	e914                	sd	a3,16(a0)
    80005c1a:	6d0c                	ld	a1,24(a0)
    80005c1c:	7110                	ld	a2,32(a0)
    80005c1e:	6194                	ld	a3,0(a1)
    80005c20:	96b2                	add	a3,a3,a2
    80005c22:	e194                	sd	a3,0(a1)
    80005c24:	4589                	li	a1,2
    80005c26:	14459073          	csrw	sip,a1
    80005c2a:	6914                	ld	a3,16(a0)
    80005c2c:	6510                	ld	a2,8(a0)
    80005c2e:	610c                	ld	a1,0(a0)
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	30200073          	mret
	...

0000000080005c3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c3a:	1141                	addi	sp,sp,-16
    80005c3c:	e422                	sd	s0,8(sp)
    80005c3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c40:	0c0007b7          	lui	a5,0xc000
    80005c44:	4705                	li	a4,1
    80005c46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c48:	c3d8                	sw	a4,4(a5)
}
    80005c4a:	6422                	ld	s0,8(sp)
    80005c4c:	0141                	addi	sp,sp,16
    80005c4e:	8082                	ret

0000000080005c50 <plicinithart>:

void
plicinithart(void)
{
    80005c50:	1141                	addi	sp,sp,-16
    80005c52:	e406                	sd	ra,8(sp)
    80005c54:	e022                	sd	s0,0(sp)
    80005c56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d28080e7          	jalr	-728(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c60:	0085171b          	slliw	a4,a0,0x8
    80005c64:	0c0027b7          	lui	a5,0xc002
    80005c68:	97ba                	add	a5,a5,a4
    80005c6a:	40200713          	li	a4,1026
    80005c6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c72:	00d5151b          	slliw	a0,a0,0xd
    80005c76:	0c2017b7          	lui	a5,0xc201
    80005c7a:	953e                	add	a0,a0,a5
    80005c7c:	00052023          	sw	zero,0(a0)
}
    80005c80:	60a2                	ld	ra,8(sp)
    80005c82:	6402                	ld	s0,0(sp)
    80005c84:	0141                	addi	sp,sp,16
    80005c86:	8082                	ret

0000000080005c88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c88:	1141                	addi	sp,sp,-16
    80005c8a:	e406                	sd	ra,8(sp)
    80005c8c:	e022                	sd	s0,0(sp)
    80005c8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c90:	ffffc097          	auipc	ra,0xffffc
    80005c94:	cf0080e7          	jalr	-784(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c98:	00d5179b          	slliw	a5,a0,0xd
    80005c9c:	0c201537          	lui	a0,0xc201
    80005ca0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ca2:	4148                	lw	a0,4(a0)
    80005ca4:	60a2                	ld	ra,8(sp)
    80005ca6:	6402                	ld	s0,0(sp)
    80005ca8:	0141                	addi	sp,sp,16
    80005caa:	8082                	ret

0000000080005cac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cac:	1101                	addi	sp,sp,-32
    80005cae:	ec06                	sd	ra,24(sp)
    80005cb0:	e822                	sd	s0,16(sp)
    80005cb2:	e426                	sd	s1,8(sp)
    80005cb4:	1000                	addi	s0,sp,32
    80005cb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	cc8080e7          	jalr	-824(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cc0:	00d5151b          	slliw	a0,a0,0xd
    80005cc4:	0c2017b7          	lui	a5,0xc201
    80005cc8:	97aa                	add	a5,a5,a0
    80005cca:	c3c4                	sw	s1,4(a5)
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret

0000000080005cd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cd6:	1141                	addi	sp,sp,-16
    80005cd8:	e406                	sd	ra,8(sp)
    80005cda:	e022                	sd	s0,0(sp)
    80005cdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cde:	479d                	li	a5,7
    80005ce0:	04a7cc63          	blt	a5,a0,80005d38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ce4:	0001c797          	auipc	a5,0x1c
    80005ce8:	f3c78793          	addi	a5,a5,-196 # 80021c20 <disk>
    80005cec:	97aa                	add	a5,a5,a0
    80005cee:	0187c783          	lbu	a5,24(a5)
    80005cf2:	ebb9                	bnez	a5,80005d48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005cf4:	00451613          	slli	a2,a0,0x4
    80005cf8:	0001c797          	auipc	a5,0x1c
    80005cfc:	f2878793          	addi	a5,a5,-216 # 80021c20 <disk>
    80005d00:	6394                	ld	a3,0(a5)
    80005d02:	96b2                	add	a3,a3,a2
    80005d04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d08:	6398                	ld	a4,0(a5)
    80005d0a:	9732                	add	a4,a4,a2
    80005d0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d18:	953e                	add	a0,a0,a5
    80005d1a:	4785                	li	a5,1
    80005d1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005d20:	0001c517          	auipc	a0,0x1c
    80005d24:	f1850513          	addi	a0,a0,-232 # 80021c38 <disk+0x18>
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	390080e7          	jalr	912(ra) # 800020b8 <wakeup>
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret
    panic("free_desc 1");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	a2850513          	addi	a0,a0,-1496 # 80008760 <syscalls+0x300>
    80005d40:	ffffa097          	auipc	ra,0xffffa
    80005d44:	7fe080e7          	jalr	2046(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d48:	00003517          	auipc	a0,0x3
    80005d4c:	a2850513          	addi	a0,a0,-1496 # 80008770 <syscalls+0x310>
    80005d50:	ffffa097          	auipc	ra,0xffffa
    80005d54:	7ee080e7          	jalr	2030(ra) # 8000053e <panic>

0000000080005d58 <virtio_disk_init>:
{
    80005d58:	1101                	addi	sp,sp,-32
    80005d5a:	ec06                	sd	ra,24(sp)
    80005d5c:	e822                	sd	s0,16(sp)
    80005d5e:	e426                	sd	s1,8(sp)
    80005d60:	e04a                	sd	s2,0(sp)
    80005d62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d64:	00003597          	auipc	a1,0x3
    80005d68:	a1c58593          	addi	a1,a1,-1508 # 80008780 <syscalls+0x320>
    80005d6c:	0001c517          	auipc	a0,0x1c
    80005d70:	fdc50513          	addi	a0,a0,-36 # 80021d48 <disk+0x128>
    80005d74:	ffffb097          	auipc	ra,0xffffb
    80005d78:	dd2080e7          	jalr	-558(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d7c:	100017b7          	lui	a5,0x10001
    80005d80:	4398                	lw	a4,0(a5)
    80005d82:	2701                	sext.w	a4,a4
    80005d84:	747277b7          	lui	a5,0x74727
    80005d88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d8c:	14f71c63          	bne	a4,a5,80005ee4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005d90:	100017b7          	lui	a5,0x10001
    80005d94:	43dc                	lw	a5,4(a5)
    80005d96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d98:	4709                	li	a4,2
    80005d9a:	14e79563          	bne	a5,a4,80005ee4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d9e:	100017b7          	lui	a5,0x10001
    80005da2:	479c                	lw	a5,8(a5)
    80005da4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005da6:	12e79f63          	bne	a5,a4,80005ee4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005daa:	100017b7          	lui	a5,0x10001
    80005dae:	47d8                	lw	a4,12(a5)
    80005db0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db2:	554d47b7          	lui	a5,0x554d4
    80005db6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dba:	12f71563          	bne	a4,a5,80005ee4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dc6:	4705                	li	a4,1
    80005dc8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dca:	470d                	li	a4,3
    80005dcc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dce:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dd0:	c7ffe737          	lui	a4,0xc7ffe
    80005dd4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ff>
    80005dd8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dda:	2701                	sext.w	a4,a4
    80005ddc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dde:	472d                	li	a4,11
    80005de0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005de2:	5bbc                	lw	a5,112(a5)
    80005de4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005de8:	8ba1                	andi	a5,a5,8
    80005dea:	10078563          	beqz	a5,80005ef4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dee:	100017b7          	lui	a5,0x10001
    80005df2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005df6:	43fc                	lw	a5,68(a5)
    80005df8:	2781                	sext.w	a5,a5
    80005dfa:	10079563          	bnez	a5,80005f04 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dfe:	100017b7          	lui	a5,0x10001
    80005e02:	5bdc                	lw	a5,52(a5)
    80005e04:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e06:	10078763          	beqz	a5,80005f14 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005e0a:	471d                	li	a4,7
    80005e0c:	10f77c63          	bgeu	a4,a5,80005f24 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	cd6080e7          	jalr	-810(ra) # 80000ae6 <kalloc>
    80005e18:	0001c497          	auipc	s1,0x1c
    80005e1c:	e0848493          	addi	s1,s1,-504 # 80021c20 <disk>
    80005e20:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e22:	ffffb097          	auipc	ra,0xffffb
    80005e26:	cc4080e7          	jalr	-828(ra) # 80000ae6 <kalloc>
    80005e2a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e2c:	ffffb097          	auipc	ra,0xffffb
    80005e30:	cba080e7          	jalr	-838(ra) # 80000ae6 <kalloc>
    80005e34:	87aa                	mv	a5,a0
    80005e36:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e38:	6088                	ld	a0,0(s1)
    80005e3a:	cd6d                	beqz	a0,80005f34 <virtio_disk_init+0x1dc>
    80005e3c:	0001c717          	auipc	a4,0x1c
    80005e40:	dec73703          	ld	a4,-532(a4) # 80021c28 <disk+0x8>
    80005e44:	cb65                	beqz	a4,80005f34 <virtio_disk_init+0x1dc>
    80005e46:	c7fd                	beqz	a5,80005f34 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005e48:	6605                	lui	a2,0x1
    80005e4a:	4581                	li	a1,0
    80005e4c:	ffffb097          	auipc	ra,0xffffb
    80005e50:	e86080e7          	jalr	-378(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e54:	0001c497          	auipc	s1,0x1c
    80005e58:	dcc48493          	addi	s1,s1,-564 # 80021c20 <disk>
    80005e5c:	6605                	lui	a2,0x1
    80005e5e:	4581                	li	a1,0
    80005e60:	6488                	ld	a0,8(s1)
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	e70080e7          	jalr	-400(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e6a:	6605                	lui	a2,0x1
    80005e6c:	4581                	li	a1,0
    80005e6e:	6888                	ld	a0,16(s1)
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	e62080e7          	jalr	-414(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e78:	100017b7          	lui	a5,0x10001
    80005e7c:	4721                	li	a4,8
    80005e7e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e80:	4098                	lw	a4,0(s1)
    80005e82:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005e86:	40d8                	lw	a4,4(s1)
    80005e88:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005e8c:	6498                	ld	a4,8(s1)
    80005e8e:	0007069b          	sext.w	a3,a4
    80005e92:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005e96:	9701                	srai	a4,a4,0x20
    80005e98:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005e9c:	6898                	ld	a4,16(s1)
    80005e9e:	0007069b          	sext.w	a3,a4
    80005ea2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ea6:	9701                	srai	a4,a4,0x20
    80005ea8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eac:	4705                	li	a4,1
    80005eae:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005eb0:	00e48c23          	sb	a4,24(s1)
    80005eb4:	00e48ca3          	sb	a4,25(s1)
    80005eb8:	00e48d23          	sb	a4,26(s1)
    80005ebc:	00e48da3          	sb	a4,27(s1)
    80005ec0:	00e48e23          	sb	a4,28(s1)
    80005ec4:	00e48ea3          	sb	a4,29(s1)
    80005ec8:	00e48f23          	sb	a4,30(s1)
    80005ecc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ed0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed4:	0727a823          	sw	s2,112(a5)
}
    80005ed8:	60e2                	ld	ra,24(sp)
    80005eda:	6442                	ld	s0,16(sp)
    80005edc:	64a2                	ld	s1,8(sp)
    80005ede:	6902                	ld	s2,0(sp)
    80005ee0:	6105                	addi	sp,sp,32
    80005ee2:	8082                	ret
    panic("could not find virtio disk");
    80005ee4:	00003517          	auipc	a0,0x3
    80005ee8:	8ac50513          	addi	a0,a0,-1876 # 80008790 <syscalls+0x330>
    80005eec:	ffffa097          	auipc	ra,0xffffa
    80005ef0:	652080e7          	jalr	1618(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005ef4:	00003517          	auipc	a0,0x3
    80005ef8:	8bc50513          	addi	a0,a0,-1860 # 800087b0 <syscalls+0x350>
    80005efc:	ffffa097          	auipc	ra,0xffffa
    80005f00:	642080e7          	jalr	1602(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80005f04:	00003517          	auipc	a0,0x3
    80005f08:	8cc50513          	addi	a0,a0,-1844 # 800087d0 <syscalls+0x370>
    80005f0c:	ffffa097          	auipc	ra,0xffffa
    80005f10:	632080e7          	jalr	1586(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f14:	00003517          	auipc	a0,0x3
    80005f18:	8dc50513          	addi	a0,a0,-1828 # 800087f0 <syscalls+0x390>
    80005f1c:	ffffa097          	auipc	ra,0xffffa
    80005f20:	622080e7          	jalr	1570(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f24:	00003517          	auipc	a0,0x3
    80005f28:	8ec50513          	addi	a0,a0,-1812 # 80008810 <syscalls+0x3b0>
    80005f2c:	ffffa097          	auipc	ra,0xffffa
    80005f30:	612080e7          	jalr	1554(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80005f34:	00003517          	auipc	a0,0x3
    80005f38:	8fc50513          	addi	a0,a0,-1796 # 80008830 <syscalls+0x3d0>
    80005f3c:	ffffa097          	auipc	ra,0xffffa
    80005f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>

0000000080005f44 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f44:	7119                	addi	sp,sp,-128
    80005f46:	fc86                	sd	ra,120(sp)
    80005f48:	f8a2                	sd	s0,112(sp)
    80005f4a:	f4a6                	sd	s1,104(sp)
    80005f4c:	f0ca                	sd	s2,96(sp)
    80005f4e:	ecce                	sd	s3,88(sp)
    80005f50:	e8d2                	sd	s4,80(sp)
    80005f52:	e4d6                	sd	s5,72(sp)
    80005f54:	e0da                	sd	s6,64(sp)
    80005f56:	fc5e                	sd	s7,56(sp)
    80005f58:	f862                	sd	s8,48(sp)
    80005f5a:	f466                	sd	s9,40(sp)
    80005f5c:	f06a                	sd	s10,32(sp)
    80005f5e:	ec6e                	sd	s11,24(sp)
    80005f60:	0100                	addi	s0,sp,128
    80005f62:	8aaa                	mv	s5,a0
    80005f64:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f66:	00c52d03          	lw	s10,12(a0)
    80005f6a:	001d1d1b          	slliw	s10,s10,0x1
    80005f6e:	1d02                	slli	s10,s10,0x20
    80005f70:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f74:	0001c517          	auipc	a0,0x1c
    80005f78:	dd450513          	addi	a0,a0,-556 # 80021d48 <disk+0x128>
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	c5a080e7          	jalr	-934(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005f84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f86:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f88:	0001cb97          	auipc	s7,0x1c
    80005f8c:	c98b8b93          	addi	s7,s7,-872 # 80021c20 <disk>
  for(int i = 0; i < 3; i++){
    80005f90:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f92:	0001cc97          	auipc	s9,0x1c
    80005f96:	db6c8c93          	addi	s9,s9,-586 # 80021d48 <disk+0x128>
    80005f9a:	a08d                	j	80005ffc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005f9c:	00fb8733          	add	a4,s7,a5
    80005fa0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fa4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fa6:	0207c563          	bltz	a5,80005fd0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005faa:	2905                	addiw	s2,s2,1
    80005fac:	0611                	addi	a2,a2,4
    80005fae:	05690c63          	beq	s2,s6,80006006 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005fb2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fb4:	0001c717          	auipc	a4,0x1c
    80005fb8:	c6c70713          	addi	a4,a4,-916 # 80021c20 <disk>
    80005fbc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fbe:	01874683          	lbu	a3,24(a4)
    80005fc2:	fee9                	bnez	a3,80005f9c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fc4:	2785                	addiw	a5,a5,1
    80005fc6:	0705                	addi	a4,a4,1
    80005fc8:	fe979be3          	bne	a5,s1,80005fbe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005fcc:	57fd                	li	a5,-1
    80005fce:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fd0:	01205d63          	blez	s2,80005fea <virtio_disk_rw+0xa6>
    80005fd4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fd6:	000a2503          	lw	a0,0(s4)
    80005fda:	00000097          	auipc	ra,0x0
    80005fde:	cfc080e7          	jalr	-772(ra) # 80005cd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe2:	2d85                	addiw	s11,s11,1
    80005fe4:	0a11                	addi	s4,s4,4
    80005fe6:	ffb918e3          	bne	s2,s11,80005fd6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fea:	85e6                	mv	a1,s9
    80005fec:	0001c517          	auipc	a0,0x1c
    80005ff0:	c4c50513          	addi	a0,a0,-948 # 80021c38 <disk+0x18>
    80005ff4:	ffffc097          	auipc	ra,0xffffc
    80005ff8:	060080e7          	jalr	96(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    80005ffc:	f8040a13          	addi	s4,s0,-128
{
    80006000:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006002:	894e                	mv	s2,s3
    80006004:	b77d                	j	80005fb2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006006:	f8042583          	lw	a1,-128(s0)
    8000600a:	00a58793          	addi	a5,a1,10
    8000600e:	0792                	slli	a5,a5,0x4

  if(write)
    80006010:	0001c617          	auipc	a2,0x1c
    80006014:	c1060613          	addi	a2,a2,-1008 # 80021c20 <disk>
    80006018:	00f60733          	add	a4,a2,a5
    8000601c:	018036b3          	snez	a3,s8
    80006020:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006022:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006026:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000602a:	f6078693          	addi	a3,a5,-160
    8000602e:	6218                	ld	a4,0(a2)
    80006030:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006032:	00878513          	addi	a0,a5,8
    80006036:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006038:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000603a:	6208                	ld	a0,0(a2)
    8000603c:	96aa                	add	a3,a3,a0
    8000603e:	4741                	li	a4,16
    80006040:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006042:	4705                	li	a4,1
    80006044:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006048:	f8442703          	lw	a4,-124(s0)
    8000604c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006050:	0712                	slli	a4,a4,0x4
    80006052:	953a                	add	a0,a0,a4
    80006054:	058a8693          	addi	a3,s5,88
    80006058:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000605a:	6208                	ld	a0,0(a2)
    8000605c:	972a                	add	a4,a4,a0
    8000605e:	40000693          	li	a3,1024
    80006062:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006064:	001c3c13          	seqz	s8,s8
    80006068:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000606a:	001c6c13          	ori	s8,s8,1
    8000606e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006072:	f8842603          	lw	a2,-120(s0)
    80006076:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000607a:	0001c697          	auipc	a3,0x1c
    8000607e:	ba668693          	addi	a3,a3,-1114 # 80021c20 <disk>
    80006082:	00258713          	addi	a4,a1,2
    80006086:	0712                	slli	a4,a4,0x4
    80006088:	9736                	add	a4,a4,a3
    8000608a:	587d                	li	a6,-1
    8000608c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006090:	0612                	slli	a2,a2,0x4
    80006092:	9532                	add	a0,a0,a2
    80006094:	f9078793          	addi	a5,a5,-112
    80006098:	97b6                	add	a5,a5,a3
    8000609a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000609c:	629c                	ld	a5,0(a3)
    8000609e:	97b2                	add	a5,a5,a2
    800060a0:	4605                	li	a2,1
    800060a2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060a4:	4509                	li	a0,2
    800060a6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800060aa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060ae:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060b2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060b6:	6698                	ld	a4,8(a3)
    800060b8:	00275783          	lhu	a5,2(a4)
    800060bc:	8b9d                	andi	a5,a5,7
    800060be:	0786                	slli	a5,a5,0x1
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060c6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060ca:	6698                	ld	a4,8(a3)
    800060cc:	00275783          	lhu	a5,2(a4)
    800060d0:	2785                	addiw	a5,a5,1
    800060d2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060d6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060da:	100017b7          	lui	a5,0x10001
    800060de:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060e2:	004aa783          	lw	a5,4(s5)
    800060e6:	02c79163          	bne	a5,a2,80006108 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800060ea:	0001c917          	auipc	s2,0x1c
    800060ee:	c5e90913          	addi	s2,s2,-930 # 80021d48 <disk+0x128>
  while(b->disk == 1) {
    800060f2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060f4:	85ca                	mv	a1,s2
    800060f6:	8556                	mv	a0,s5
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	f5c080e7          	jalr	-164(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    80006100:	004aa783          	lw	a5,4(s5)
    80006104:	fe9788e3          	beq	a5,s1,800060f4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006108:	f8042903          	lw	s2,-128(s0)
    8000610c:	00290793          	addi	a5,s2,2
    80006110:	00479713          	slli	a4,a5,0x4
    80006114:	0001c797          	auipc	a5,0x1c
    80006118:	b0c78793          	addi	a5,a5,-1268 # 80021c20 <disk>
    8000611c:	97ba                	add	a5,a5,a4
    8000611e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006122:	0001c997          	auipc	s3,0x1c
    80006126:	afe98993          	addi	s3,s3,-1282 # 80021c20 <disk>
    8000612a:	00491713          	slli	a4,s2,0x4
    8000612e:	0009b783          	ld	a5,0(s3)
    80006132:	97ba                	add	a5,a5,a4
    80006134:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006138:	854a                	mv	a0,s2
    8000613a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000613e:	00000097          	auipc	ra,0x0
    80006142:	b98080e7          	jalr	-1128(ra) # 80005cd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006146:	8885                	andi	s1,s1,1
    80006148:	f0ed                	bnez	s1,8000612a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000614a:	0001c517          	auipc	a0,0x1c
    8000614e:	bfe50513          	addi	a0,a0,-1026 # 80021d48 <disk+0x128>
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	b38080e7          	jalr	-1224(ra) # 80000c8a <release>
}
    8000615a:	70e6                	ld	ra,120(sp)
    8000615c:	7446                	ld	s0,112(sp)
    8000615e:	74a6                	ld	s1,104(sp)
    80006160:	7906                	ld	s2,96(sp)
    80006162:	69e6                	ld	s3,88(sp)
    80006164:	6a46                	ld	s4,80(sp)
    80006166:	6aa6                	ld	s5,72(sp)
    80006168:	6b06                	ld	s6,64(sp)
    8000616a:	7be2                	ld	s7,56(sp)
    8000616c:	7c42                	ld	s8,48(sp)
    8000616e:	7ca2                	ld	s9,40(sp)
    80006170:	7d02                	ld	s10,32(sp)
    80006172:	6de2                	ld	s11,24(sp)
    80006174:	6109                	addi	sp,sp,128
    80006176:	8082                	ret

0000000080006178 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006178:	1101                	addi	sp,sp,-32
    8000617a:	ec06                	sd	ra,24(sp)
    8000617c:	e822                	sd	s0,16(sp)
    8000617e:	e426                	sd	s1,8(sp)
    80006180:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006182:	0001c497          	auipc	s1,0x1c
    80006186:	a9e48493          	addi	s1,s1,-1378 # 80021c20 <disk>
    8000618a:	0001c517          	auipc	a0,0x1c
    8000618e:	bbe50513          	addi	a0,a0,-1090 # 80021d48 <disk+0x128>
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000619a:	10001737          	lui	a4,0x10001
    8000619e:	533c                	lw	a5,96(a4)
    800061a0:	8b8d                	andi	a5,a5,3
    800061a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061a8:	689c                	ld	a5,16(s1)
    800061aa:	0204d703          	lhu	a4,32(s1)
    800061ae:	0027d783          	lhu	a5,2(a5)
    800061b2:	04f70863          	beq	a4,a5,80006202 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800061b6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061ba:	6898                	ld	a4,16(s1)
    800061bc:	0204d783          	lhu	a5,32(s1)
    800061c0:	8b9d                	andi	a5,a5,7
    800061c2:	078e                	slli	a5,a5,0x3
    800061c4:	97ba                	add	a5,a5,a4
    800061c6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061c8:	00278713          	addi	a4,a5,2
    800061cc:	0712                	slli	a4,a4,0x4
    800061ce:	9726                	add	a4,a4,s1
    800061d0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800061d4:	e721                	bnez	a4,8000621c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061d6:	0789                	addi	a5,a5,2
    800061d8:	0792                	slli	a5,a5,0x4
    800061da:	97a6                	add	a5,a5,s1
    800061dc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800061de:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	ed6080e7          	jalr	-298(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    800061ea:	0204d783          	lhu	a5,32(s1)
    800061ee:	2785                	addiw	a5,a5,1
    800061f0:	17c2                	slli	a5,a5,0x30
    800061f2:	93c1                	srli	a5,a5,0x30
    800061f4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061f8:	6898                	ld	a4,16(s1)
    800061fa:	00275703          	lhu	a4,2(a4)
    800061fe:	faf71ce3          	bne	a4,a5,800061b6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006202:	0001c517          	auipc	a0,0x1c
    80006206:	b4650513          	addi	a0,a0,-1210 # 80021d48 <disk+0x128>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a80080e7          	jalr	-1408(ra) # 80000c8a <release>
}
    80006212:	60e2                	ld	ra,24(sp)
    80006214:	6442                	ld	s0,16(sp)
    80006216:	64a2                	ld	s1,8(sp)
    80006218:	6105                	addi	sp,sp,32
    8000621a:	8082                	ret
      panic("virtio_disk_intr status");
    8000621c:	00002517          	auipc	a0,0x2
    80006220:	62c50513          	addi	a0,a0,1580 # 80008848 <syscalls+0x3e8>
    80006224:	ffffa097          	auipc	ra,0xffffa
    80006228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
