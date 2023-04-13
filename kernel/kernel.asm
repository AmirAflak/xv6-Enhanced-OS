
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a7010113          	addi	sp,sp,-1424 # 80008a70 <stack0>
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
    80000056:	8de70713          	addi	a4,a4,-1826 # 80008930 <timer_scratch>
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
    80000068:	cdc78793          	addi	a5,a5,-804 # 80005d40 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc85f>
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
    80000130:	392080e7          	jalr	914(ra) # 800024be <either_copyin>
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
    8000018e:	8e650513          	addi	a0,a0,-1818 # 80010a70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8d648493          	addi	s1,s1,-1834 # 80010a70 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	96690913          	addi	s2,s2,-1690 # 80010b08 <cons+0x98>
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
    800001cc:	140080e7          	jalr	320(ra) # 80002308 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e8a080e7          	jalr	-374(ra) # 80002060 <sleep>
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
    80000216:	256080e7          	jalr	598(ra) # 80002468 <either_copyout>
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
    8000022a:	84a50513          	addi	a0,a0,-1974 # 80010a70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	83450513          	addi	a0,a0,-1996 # 80010a70 <cons>
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
    80000276:	88f72b23          	sw	a5,-1898(a4) # 80010b08 <cons+0x98>
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
    800002d0:	7a450513          	addi	a0,a0,1956 # 80010a70 <cons>
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
    800002f6:	222080e7          	jalr	546(ra) # 80002514 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	77650513          	addi	a0,a0,1910 # 80010a70 <cons>
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
    80000322:	75270713          	addi	a4,a4,1874 # 80010a70 <cons>
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
    8000034c:	72878793          	addi	a5,a5,1832 # 80010a70 <cons>
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
    8000037a:	7927a783          	lw	a5,1938(a5) # 80010b08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6e670713          	addi	a4,a4,1766 # 80010a70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6d648493          	addi	s1,s1,1750 # 80010a70 <cons>
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
    800003da:	69a70713          	addi	a4,a4,1690 # 80010a70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72223          	sw	a5,1828(a4) # 80010b10 <cons+0xa0>
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
    80000416:	65e78793          	addi	a5,a5,1630 # 80010a70 <cons>
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
    8000043a:	6cc7ab23          	sw	a2,1750(a5) # 80010b0c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ca50513          	addi	a0,a0,1738 # 80010b08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c7e080e7          	jalr	-898(ra) # 800020c4 <wakeup>
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
    80000464:	61050513          	addi	a0,a0,1552 # 80010a70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	99078793          	addi	a5,a5,-1648 # 80020e08 <devsw>
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
    8000054e:	5e07a323          	sw	zero,1510(a5) # 80010b30 <pr+0x18>
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
    80000582:	36f72923          	sw	a5,882(a4) # 800088f0 <panicked>
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
    800005be:	576dad83          	lw	s11,1398(s11) # 80010b30 <pr+0x18>
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
    800005fc:	52050513          	addi	a0,a0,1312 # 80010b18 <pr>
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
    8000075a:	3c250513          	addi	a0,a0,962 # 80010b18 <pr>
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
    80000776:	3a648493          	addi	s1,s1,934 # 80010b18 <pr>
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
    800007d6:	36650513          	addi	a0,a0,870 # 80010b38 <uart_tx_lock>
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
    80000802:	0f27a783          	lw	a5,242(a5) # 800088f0 <panicked>
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
    8000083a:	0c27b783          	ld	a5,194(a5) # 800088f8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0c273703          	ld	a4,194(a4) # 80008900 <uart_tx_w>
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
    80000864:	2d8a0a13          	addi	s4,s4,728 # 80010b38 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	09048493          	addi	s1,s1,144 # 800088f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	09098993          	addi	s3,s3,144 # 80008900 <uart_tx_w>
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
    80000896:	832080e7          	jalr	-1998(ra) # 800020c4 <wakeup>
    
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
    800008d2:	26a50513          	addi	a0,a0,618 # 80010b38 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0127a783          	lw	a5,18(a5) # 800088f0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	01873703          	ld	a4,24(a4) # 80008900 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0087b783          	ld	a5,8(a5) # 800088f8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	23c98993          	addi	s3,s3,572 # 80010b38 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	ff448493          	addi	s1,s1,-12 # 800088f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	ff490913          	addi	s2,s2,-12 # 80008900 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	744080e7          	jalr	1860(ra) # 80002060 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	20648493          	addi	s1,s1,518 # 80010b38 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7bd23          	sd	a4,-70(a5) # 80008900 <uart_tx_w>
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
    800009c0:	17c48493          	addi	s1,s1,380 # 80010b38 <uart_tx_lock>
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
    80000a02:	5a278793          	addi	a5,a5,1442 # 80021fa0 <end>
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
    80000a22:	15290913          	addi	s2,s2,338 # 80010b70 <kmem>
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
    80000abe:	0b650513          	addi	a0,a0,182 # 80010b70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	4d250513          	addi	a0,a0,1234 # 80021fa0 <end>
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
    80000af4:	08048493          	addi	s1,s1,128 # 80010b70 <kmem>
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
    80000b0c:	06850513          	addi	a0,a0,104 # 80010b70 <kmem>
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
    80000b38:	03c50513          	addi	a0,a0,60 # 80010b70 <kmem>
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
    80000e8c:	a8070713          	addi	a4,a4,-1408 # 80008908 <started>
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
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	8c0080e7          	jalr	-1856(ra) # 8000277e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	eba080e7          	jalr	-326(ra) # 80005d80 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe0080e7          	jalr	-32(ra) # 80001eae <scheduler>
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
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	820080e7          	jalr	-2016(ra) # 80002756 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	840080e7          	jalr	-1984(ra) # 8000277e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e24080e7          	jalr	-476(ra) # 80005d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e32080e7          	jalr	-462(ra) # 80005d80 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	fd8080e7          	jalr	-40(ra) # 80002f2e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	67c080e7          	jalr	1660(ra) # 800035da <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	61a080e7          	jalr	1562(ra) # 80004580 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f1a080e7          	jalr	-230(ra) # 80005e88 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d1a080e7          	jalr	-742(ra) # 80001c90 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	98f72223          	sw	a5,-1660(a4) # 80008908 <started>
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
    80000f9c:	9787b783          	ld	a5,-1672(a5) # 80008910 <kernel_pagetable>
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
    80001258:	6aa7be23          	sd	a0,1724(a5) # 80008910 <kernel_pagetable>
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
    80001850:	77448493          	addi	s1,s1,1908 # 80010fc0 <proc>
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
    8000186a:	35aa0a13          	addi	s4,s4,858 # 80016bc0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
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
    800018a0:	17048493          	addi	s1,s1,368
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
    800018ec:	2a850513          	addi	a0,a0,680 # 80010b90 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2a850513          	addi	a0,a0,680 # 80010ba8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6b048493          	addi	s1,s1,1712 # 80010fc0 <proc>
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
    80001936:	28e98993          	addi	s3,s3,654 # 80016bc0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
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
    800019a0:	22450513          	addi	a0,a0,548 # 80010bc0 <cpus>
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
    800019c8:	1cc70713          	addi	a4,a4,460 # 80010b90 <pid_lock>
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
    80001a00:	ea47a783          	lw	a5,-348(a5) # 800088a0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d90080e7          	jalr	-624(ra) # 80002796 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e807a523          	sw	zero,-374(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b3a080e7          	jalr	-1222(ra) # 8000355a <fsinit>
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
    80001a3a:	15a90913          	addi	s2,s2,346 # 80010b90 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e5c78793          	addi	a5,a5,-420 # 800088a4 <nextpid>
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
    80001bc6:	3fe48493          	addi	s1,s1,1022 # 80010fc0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	ff690913          	addi	s2,s2,-10 # 80016bc0 <tickslock>
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
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a8b9                	j	80001c52 <allocproc+0x9c>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	d1c7a783          	lw	a5,-740(a5) # 80008920 <ticks>
    80001c0c:	16f4a423          	sw	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	ed6080e7          	jalr	-298(ra) # 80000ae6 <kalloc>
    80001c18:	892a                	mv	s2,a0
    80001c1a:	eca8                	sd	a0,88(s1)
    80001c1c:	c131                	beqz	a0,80001c60 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e50080e7          	jalr	-432(ra) # 80001a70 <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2c:	c531                	beqz	a0,80001c78 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c2e:	07000613          	li	a2,112
    80001c32:	4581                	li	a1,0
    80001c34:	06048513          	addi	a0,s1,96
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	09a080e7          	jalr	154(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c40:	00000797          	auipc	a5,0x0
    80001c44:	da478793          	addi	a5,a5,-604 # 800019e4 <forkret>
    80001c48:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4a:	60bc                	ld	a5,64(s1)
    80001c4c:	6705                	lui	a4,0x1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	f4bc                	sd	a5,104(s1)
}
    80001c52:	8526                	mv	a0,s1
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
    freeproc(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	efc080e7          	jalr	-260(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	01e080e7          	jalr	30(ra) # 80000c8a <release>
    return 0;
    80001c74:	84ca                	mv	s1,s2
    80001c76:	bff1                	j	80001c52 <allocproc+0x9c>
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ee4080e7          	jalr	-284(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	006080e7          	jalr	6(ra) # 80000c8a <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b7d1                	j	80001c52 <allocproc+0x9c>

0000000080001c90 <userinit>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	f1c080e7          	jalr	-228(ra) # 80001bb6 <allocproc>
    80001ca2:	84aa                	mv	s1,a0
  initproc = p;
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	c6a7ba23          	sd	a0,-908(a5) # 80008918 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cac:	03400613          	li	a2,52
    80001cb0:	00007597          	auipc	a1,0x7
    80001cb4:	c0058593          	addi	a1,a1,-1024 # 800088b0 <initcode>
    80001cb8:	6928                	ld	a0,80(a0)
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	69c080e7          	jalr	1692(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cc2:	6785                	lui	a5,0x1
    80001cc4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ccc:	6cb8                	ld	a4,88(s1)
    80001cce:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd0:	4641                	li	a2,16
    80001cd2:	00006597          	auipc	a1,0x6
    80001cd6:	52e58593          	addi	a1,a1,1326 # 80008200 <digits+0x1c0>
    80001cda:	15848513          	addi	a0,s1,344
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	13e080e7          	jalr	318(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001ce6:	00006517          	auipc	a0,0x6
    80001cea:	52a50513          	addi	a0,a0,1322 # 80008210 <digits+0x1d0>
    80001cee:	00002097          	auipc	ra,0x2
    80001cf2:	28e080e7          	jalr	654(ra) # 80003f7c <namei>
    80001cf6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfa:	478d                	li	a5,3
    80001cfc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	f8a080e7          	jalr	-118(ra) # 80000c8a <release>
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6105                	addi	sp,sp,32
    80001d10:	8082                	ret

0000000080001d12 <growproc>:
{
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	e04a                	sd	s2,0(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	c8c080e7          	jalr	-884(ra) # 800019ac <myproc>
    80001d28:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d2a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d2c:	01204c63          	bgtz	s2,80001d44 <growproc+0x32>
  } else if(n < 0){
    80001d30:	02094663          	bltz	s2,80001d5c <growproc+0x4a>
  p->sz = sz;
    80001d34:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d36:	4501                	li	a0,0
}
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6902                	ld	s2,0(sp)
    80001d40:	6105                	addi	sp,sp,32
    80001d42:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d44:	4691                	li	a3,4
    80001d46:	00b90633          	add	a2,s2,a1
    80001d4a:	6928                	ld	a0,80(a0)
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	6c4080e7          	jalr	1732(ra) # 80001410 <uvmalloc>
    80001d54:	85aa                	mv	a1,a0
    80001d56:	fd79                	bnez	a0,80001d34 <growproc+0x22>
      return -1;
    80001d58:	557d                	li	a0,-1
    80001d5a:	bff9                	j	80001d38 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d5c:	00b90633          	add	a2,s2,a1
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	666080e7          	jalr	1638(ra) # 800013c8 <uvmdealloc>
    80001d6a:	85aa                	mv	a1,a0
    80001d6c:	b7e1                	j	80001d34 <growproc+0x22>

0000000080001d6e <fork>:
{
    80001d6e:	7139                	addi	sp,sp,-64
    80001d70:	fc06                	sd	ra,56(sp)
    80001d72:	f822                	sd	s0,48(sp)
    80001d74:	f426                	sd	s1,40(sp)
    80001d76:	f04a                	sd	s2,32(sp)
    80001d78:	ec4e                	sd	s3,24(sp)
    80001d7a:	e852                	sd	s4,16(sp)
    80001d7c:	e456                	sd	s5,8(sp)
    80001d7e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	c2c080e7          	jalr	-980(ra) # 800019ac <myproc>
    80001d88:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	e2c080e7          	jalr	-468(ra) # 80001bb6 <allocproc>
    80001d92:	10050c63          	beqz	a0,80001eaa <fork+0x13c>
    80001d96:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d98:	048ab603          	ld	a2,72(s5)
    80001d9c:	692c                	ld	a1,80(a0)
    80001d9e:	050ab503          	ld	a0,80(s5)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	7c2080e7          	jalr	1986(ra) # 80001564 <uvmcopy>
    80001daa:	04054863          	bltz	a0,80001dfa <fork+0x8c>
  np->sz = p->sz;
    80001dae:	048ab783          	ld	a5,72(s5)
    80001db2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db6:	058ab683          	ld	a3,88(s5)
    80001dba:	87b6                	mv	a5,a3
    80001dbc:	058a3703          	ld	a4,88(s4)
    80001dc0:	12068693          	addi	a3,a3,288
    80001dc4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc8:	6788                	ld	a0,8(a5)
    80001dca:	6b8c                	ld	a1,16(a5)
    80001dcc:	6f90                	ld	a2,24(a5)
    80001dce:	01073023          	sd	a6,0(a4)
    80001dd2:	e708                	sd	a0,8(a4)
    80001dd4:	eb0c                	sd	a1,16(a4)
    80001dd6:	ef10                	sd	a2,24(a4)
    80001dd8:	02078793          	addi	a5,a5,32
    80001ddc:	02070713          	addi	a4,a4,32
    80001de0:	fed792e3          	bne	a5,a3,80001dc4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001de4:	058a3783          	ld	a5,88(s4)
    80001de8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dec:	0d0a8493          	addi	s1,s5,208
    80001df0:	0d0a0913          	addi	s2,s4,208
    80001df4:	150a8993          	addi	s3,s5,336
    80001df8:	a00d                	j	80001e1a <fork+0xac>
    freeproc(np);
    80001dfa:	8552                	mv	a0,s4
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	d62080e7          	jalr	-670(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e04:	8552                	mv	a0,s4
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	e84080e7          	jalr	-380(ra) # 80000c8a <release>
    return -1;
    80001e0e:	597d                	li	s2,-1
    80001e10:	a059                	j	80001e96 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e12:	04a1                	addi	s1,s1,8
    80001e14:	0921                	addi	s2,s2,8
    80001e16:	01348b63          	beq	s1,s3,80001e2c <fork+0xbe>
    if(p->ofile[i])
    80001e1a:	6088                	ld	a0,0(s1)
    80001e1c:	d97d                	beqz	a0,80001e12 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1e:	00002097          	auipc	ra,0x2
    80001e22:	7f4080e7          	jalr	2036(ra) # 80004612 <filedup>
    80001e26:	00a93023          	sd	a0,0(s2)
    80001e2a:	b7e5                	j	80001e12 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e2c:	150ab503          	ld	a0,336(s5)
    80001e30:	00002097          	auipc	ra,0x2
    80001e34:	968080e7          	jalr	-1688(ra) # 80003798 <idup>
    80001e38:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3c:	4641                	li	a2,16
    80001e3e:	158a8593          	addi	a1,s5,344
    80001e42:	158a0513          	addi	a0,s4,344
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	fd6080e7          	jalr	-42(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e4e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e52:	8552                	mv	a0,s4
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	e36080e7          	jalr	-458(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e5c:	0000f497          	auipc	s1,0xf
    80001e60:	d4c48493          	addi	s1,s1,-692 # 80010ba8 <wait_lock>
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	d70080e7          	jalr	-656(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e6e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e16080e7          	jalr	-490(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e7c:	8552                	mv	a0,s4
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d58080e7          	jalr	-680(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e86:	478d                	li	a5,3
    80001e88:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e8c:	8552                	mv	a0,s4
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	dfc080e7          	jalr	-516(ra) # 80000c8a <release>
}
    80001e96:	854a                	mv	a0,s2
    80001e98:	70e2                	ld	ra,56(sp)
    80001e9a:	7442                	ld	s0,48(sp)
    80001e9c:	74a2                	ld	s1,40(sp)
    80001e9e:	7902                	ld	s2,32(sp)
    80001ea0:	69e2                	ld	s3,24(sp)
    80001ea2:	6a42                	ld	s4,16(sp)
    80001ea4:	6aa2                	ld	s5,8(sp)
    80001ea6:	6121                	addi	sp,sp,64
    80001ea8:	8082                	ret
    return -1;
    80001eaa:	597d                	li	s2,-1
    80001eac:	b7ed                	j	80001e96 <fork+0x128>

0000000080001eae <scheduler>:
{
    80001eae:	7139                	addi	sp,sp,-64
    80001eb0:	fc06                	sd	ra,56(sp)
    80001eb2:	f822                	sd	s0,48(sp)
    80001eb4:	f426                	sd	s1,40(sp)
    80001eb6:	f04a                	sd	s2,32(sp)
    80001eb8:	ec4e                	sd	s3,24(sp)
    80001eba:	e852                	sd	s4,16(sp)
    80001ebc:	e456                	sd	s5,8(sp)
    80001ebe:	e05a                	sd	s6,0(sp)
    80001ec0:	0080                	addi	s0,sp,64
    80001ec2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec6:	00779a93          	slli	s5,a5,0x7
    80001eca:	0000f717          	auipc	a4,0xf
    80001ece:	cc670713          	addi	a4,a4,-826 # 80010b90 <pid_lock>
    80001ed2:	9756                	add	a4,a4,s5
    80001ed4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed8:	0000f717          	auipc	a4,0xf
    80001edc:	cf070713          	addi	a4,a4,-784 # 80010bc8 <cpus+0x8>
    80001ee0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee2:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee4:	4b11                	li	s6,4
        c->proc = p;
    80001ee6:	079e                	slli	a5,a5,0x7
    80001ee8:	0000fa17          	auipc	s4,0xf
    80001eec:	ca8a0a13          	addi	s4,s4,-856 # 80010b90 <pid_lock>
    80001ef0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef2:	00015917          	auipc	s2,0x15
    80001ef6:	cce90913          	addi	s2,s2,-818 # 80016bc0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001efa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f02:	10079073          	csrw	sstatus,a5
    80001f06:	0000f497          	auipc	s1,0xf
    80001f0a:	0ba48493          	addi	s1,s1,186 # 80010fc0 <proc>
    80001f0e:	a811                	j	80001f22 <scheduler+0x74>
      release(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d78080e7          	jalr	-648(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f1a:	17048493          	addi	s1,s1,368
    80001f1e:	fd248ee3          	beq	s1,s2,80001efa <scheduler+0x4c>
      acquire(&p->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	cb2080e7          	jalr	-846(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f2c:	4c9c                	lw	a5,24(s1)
    80001f2e:	ff3791e3          	bne	a5,s3,80001f10 <scheduler+0x62>
        p->state = RUNNING;
    80001f32:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f36:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f3a:	06048593          	addi	a1,s1,96
    80001f3e:	8556                	mv	a0,s5
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	7ac080e7          	jalr	1964(ra) # 800026ec <swtch>
        c->proc = 0;
    80001f48:	020a3823          	sd	zero,48(s4)
    80001f4c:	b7d1                	j	80001f10 <scheduler+0x62>

0000000080001f4e <sched>:
{
    80001f4e:	7179                	addi	sp,sp,-48
    80001f50:	f406                	sd	ra,40(sp)
    80001f52:	f022                	sd	s0,32(sp)
    80001f54:	ec26                	sd	s1,24(sp)
    80001f56:	e84a                	sd	s2,16(sp)
    80001f58:	e44e                	sd	s3,8(sp)
    80001f5a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	a50080e7          	jalr	-1456(ra) # 800019ac <myproc>
    80001f64:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	bf6080e7          	jalr	-1034(ra) # 80000b5c <holding>
    80001f6e:	c93d                	beqz	a0,80001fe4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f70:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f72:	2781                	sext.w	a5,a5
    80001f74:	079e                	slli	a5,a5,0x7
    80001f76:	0000f717          	auipc	a4,0xf
    80001f7a:	c1a70713          	addi	a4,a4,-998 # 80010b90 <pid_lock>
    80001f7e:	97ba                	add	a5,a5,a4
    80001f80:	0a87a703          	lw	a4,168(a5)
    80001f84:	4785                	li	a5,1
    80001f86:	06f71763          	bne	a4,a5,80001ff4 <sched+0xa6>
  if(p->state == RUNNING)
    80001f8a:	4c98                	lw	a4,24(s1)
    80001f8c:	4791                	li	a5,4
    80001f8e:	06f70b63          	beq	a4,a5,80002004 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f98:	efb5                	bnez	a5,80002014 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9c:	0000f917          	auipc	s2,0xf
    80001fa0:	bf490913          	addi	s2,s2,-1036 # 80010b90 <pid_lock>
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	97ca                	add	a5,a5,s2
    80001faa:	0ac7a983          	lw	s3,172(a5)
    80001fae:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb0:	2781                	sext.w	a5,a5
    80001fb2:	079e                	slli	a5,a5,0x7
    80001fb4:	0000f597          	auipc	a1,0xf
    80001fb8:	c1458593          	addi	a1,a1,-1004 # 80010bc8 <cpus+0x8>
    80001fbc:	95be                	add	a1,a1,a5
    80001fbe:	06048513          	addi	a0,s1,96
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	72a080e7          	jalr	1834(ra) # 800026ec <swtch>
    80001fca:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fcc:	2781                	sext.w	a5,a5
    80001fce:	079e                	slli	a5,a5,0x7
    80001fd0:	97ca                	add	a5,a5,s2
    80001fd2:	0b37a623          	sw	s3,172(a5)
}
    80001fd6:	70a2                	ld	ra,40(sp)
    80001fd8:	7402                	ld	s0,32(sp)
    80001fda:	64e2                	ld	s1,24(sp)
    80001fdc:	6942                	ld	s2,16(sp)
    80001fde:	69a2                	ld	s3,8(sp)
    80001fe0:	6145                	addi	sp,sp,48
    80001fe2:	8082                	ret
    panic("sched p->lock");
    80001fe4:	00006517          	auipc	a0,0x6
    80001fe8:	23450513          	addi	a0,a0,564 # 80008218 <digits+0x1d8>
    80001fec:	ffffe097          	auipc	ra,0xffffe
    80001ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
    panic("sched locks");
    80001ff4:	00006517          	auipc	a0,0x6
    80001ff8:	23450513          	addi	a0,a0,564 # 80008228 <digits+0x1e8>
    80001ffc:	ffffe097          	auipc	ra,0xffffe
    80002000:	542080e7          	jalr	1346(ra) # 8000053e <panic>
    panic("sched running");
    80002004:	00006517          	auipc	a0,0x6
    80002008:	23450513          	addi	a0,a0,564 # 80008238 <digits+0x1f8>
    8000200c:	ffffe097          	auipc	ra,0xffffe
    80002010:	532080e7          	jalr	1330(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002014:	00006517          	auipc	a0,0x6
    80002018:	23450513          	addi	a0,a0,564 # 80008248 <digits+0x208>
    8000201c:	ffffe097          	auipc	ra,0xffffe
    80002020:	522080e7          	jalr	1314(ra) # 8000053e <panic>

0000000080002024 <yield>:
{
    80002024:	1101                	addi	sp,sp,-32
    80002026:	ec06                	sd	ra,24(sp)
    80002028:	e822                	sd	s0,16(sp)
    8000202a:	e426                	sd	s1,8(sp)
    8000202c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	97e080e7          	jalr	-1666(ra) # 800019ac <myproc>
    80002036:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	b9e080e7          	jalr	-1122(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002040:	478d                	li	a5,3
    80002042:	cc9c                	sw	a5,24(s1)
  sched();
    80002044:	00000097          	auipc	ra,0x0
    80002048:	f0a080e7          	jalr	-246(ra) # 80001f4e <sched>
  release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
}
    80002056:	60e2                	ld	ra,24(sp)
    80002058:	6442                	ld	s0,16(sp)
    8000205a:	64a2                	ld	s1,8(sp)
    8000205c:	6105                	addi	sp,sp,32
    8000205e:	8082                	ret

0000000080002060 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002060:	7179                	addi	sp,sp,-48
    80002062:	f406                	sd	ra,40(sp)
    80002064:	f022                	sd	s0,32(sp)
    80002066:	ec26                	sd	s1,24(sp)
    80002068:	e84a                	sd	s2,16(sp)
    8000206a:	e44e                	sd	s3,8(sp)
    8000206c:	1800                	addi	s0,sp,48
    8000206e:	89aa                	mv	s3,a0
    80002070:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	93a080e7          	jalr	-1734(ra) # 800019ac <myproc>
    8000207a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b5a080e7          	jalr	-1190(ra) # 80000bd6 <acquire>
  release(lk);
    80002084:	854a                	mv	a0,s2
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000208e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002092:	4789                	li	a5,2
    80002094:	cc9c                	sw	a5,24(s1)

  sched();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	eb8080e7          	jalr	-328(ra) # 80001f4e <sched>

  // Tidy up.
  p->chan = 0;
    8000209e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	be6080e7          	jalr	-1050(ra) # 80000c8a <release>
  acquire(lk);
    800020ac:	854a                	mv	a0,s2
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b28080e7          	jalr	-1240(ra) # 80000bd6 <acquire>
}
    800020b6:	70a2                	ld	ra,40(sp)
    800020b8:	7402                	ld	s0,32(sp)
    800020ba:	64e2                	ld	s1,24(sp)
    800020bc:	6942                	ld	s2,16(sp)
    800020be:	69a2                	ld	s3,8(sp)
    800020c0:	6145                	addi	sp,sp,48
    800020c2:	8082                	ret

00000000800020c4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020c4:	7139                	addi	sp,sp,-64
    800020c6:	fc06                	sd	ra,56(sp)
    800020c8:	f822                	sd	s0,48(sp)
    800020ca:	f426                	sd	s1,40(sp)
    800020cc:	f04a                	sd	s2,32(sp)
    800020ce:	ec4e                	sd	s3,24(sp)
    800020d0:	e852                	sd	s4,16(sp)
    800020d2:	e456                	sd	s5,8(sp)
    800020d4:	0080                	addi	s0,sp,64
    800020d6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	0000f497          	auipc	s1,0xf
    800020dc:	ee848493          	addi	s1,s1,-280 # 80010fc0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020e0:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020e2:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e4:	00015917          	auipc	s2,0x15
    800020e8:	adc90913          	addi	s2,s2,-1316 # 80016bc0 <tickslock>
    800020ec:	a811                	j	80002100 <wakeup+0x3c>
      }
      release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b9a080e7          	jalr	-1126(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f8:	17048493          	addi	s1,s1,368
    800020fc:	03248663          	beq	s1,s2,80002128 <wakeup+0x64>
    if(p != myproc()){
    80002100:	00000097          	auipc	ra,0x0
    80002104:	8ac080e7          	jalr	-1876(ra) # 800019ac <myproc>
    80002108:	fea488e3          	beq	s1,a0,800020f8 <wakeup+0x34>
      acquire(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002116:	4c9c                	lw	a5,24(s1)
    80002118:	fd379be3          	bne	a5,s3,800020ee <wakeup+0x2a>
    8000211c:	709c                	ld	a5,32(s1)
    8000211e:	fd4798e3          	bne	a5,s4,800020ee <wakeup+0x2a>
        p->state = RUNNABLE;
    80002122:	0154ac23          	sw	s5,24(s1)
    80002126:	b7e1                	j	800020ee <wakeup+0x2a>
    }
  }
}
    80002128:	70e2                	ld	ra,56(sp)
    8000212a:	7442                	ld	s0,48(sp)
    8000212c:	74a2                	ld	s1,40(sp)
    8000212e:	7902                	ld	s2,32(sp)
    80002130:	69e2                	ld	s3,24(sp)
    80002132:	6a42                	ld	s4,16(sp)
    80002134:	6aa2                	ld	s5,8(sp)
    80002136:	6121                	addi	sp,sp,64
    80002138:	8082                	ret

000000008000213a <reparent>:
{
    8000213a:	7179                	addi	sp,sp,-48
    8000213c:	f406                	sd	ra,40(sp)
    8000213e:	f022                	sd	s0,32(sp)
    80002140:	ec26                	sd	s1,24(sp)
    80002142:	e84a                	sd	s2,16(sp)
    80002144:	e44e                	sd	s3,8(sp)
    80002146:	e052                	sd	s4,0(sp)
    80002148:	1800                	addi	s0,sp,48
    8000214a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000214c:	0000f497          	auipc	s1,0xf
    80002150:	e7448493          	addi	s1,s1,-396 # 80010fc0 <proc>
      pp->parent = initproc;
    80002154:	00006a17          	auipc	s4,0x6
    80002158:	7c4a0a13          	addi	s4,s4,1988 # 80008918 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000215c:	00015997          	auipc	s3,0x15
    80002160:	a6498993          	addi	s3,s3,-1436 # 80016bc0 <tickslock>
    80002164:	a029                	j	8000216e <reparent+0x34>
    80002166:	17048493          	addi	s1,s1,368
    8000216a:	01348d63          	beq	s1,s3,80002184 <reparent+0x4a>
    if(pp->parent == p){
    8000216e:	7c9c                	ld	a5,56(s1)
    80002170:	ff279be3          	bne	a5,s2,80002166 <reparent+0x2c>
      pp->parent = initproc;
    80002174:	000a3503          	ld	a0,0(s4)
    80002178:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	f4a080e7          	jalr	-182(ra) # 800020c4 <wakeup>
    80002182:	b7d5                	j	80002166 <reparent+0x2c>
}
    80002184:	70a2                	ld	ra,40(sp)
    80002186:	7402                	ld	s0,32(sp)
    80002188:	64e2                	ld	s1,24(sp)
    8000218a:	6942                	ld	s2,16(sp)
    8000218c:	69a2                	ld	s3,8(sp)
    8000218e:	6a02                	ld	s4,0(sp)
    80002190:	6145                	addi	sp,sp,48
    80002192:	8082                	ret

0000000080002194 <exit>:
{
    80002194:	7179                	addi	sp,sp,-48
    80002196:	f406                	sd	ra,40(sp)
    80002198:	f022                	sd	s0,32(sp)
    8000219a:	ec26                	sd	s1,24(sp)
    8000219c:	e84a                	sd	s2,16(sp)
    8000219e:	e44e                	sd	s3,8(sp)
    800021a0:	e052                	sd	s4,0(sp)
    800021a2:	1800                	addi	s0,sp,48
    800021a4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	806080e7          	jalr	-2042(ra) # 800019ac <myproc>
    800021ae:	89aa                	mv	s3,a0
  if(p == initproc)
    800021b0:	00006797          	auipc	a5,0x6
    800021b4:	7687b783          	ld	a5,1896(a5) # 80008918 <initproc>
    800021b8:	0d050493          	addi	s1,a0,208
    800021bc:	15050913          	addi	s2,a0,336
    800021c0:	02a79363          	bne	a5,a0,800021e6 <exit+0x52>
    panic("init exiting");
    800021c4:	00006517          	auipc	a0,0x6
    800021c8:	09c50513          	addi	a0,a0,156 # 80008260 <digits+0x220>
    800021cc:	ffffe097          	auipc	ra,0xffffe
    800021d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
      fileclose(f);
    800021d4:	00002097          	auipc	ra,0x2
    800021d8:	490080e7          	jalr	1168(ra) # 80004664 <fileclose>
      p->ofile[fd] = 0;
    800021dc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021e0:	04a1                	addi	s1,s1,8
    800021e2:	01248563          	beq	s1,s2,800021ec <exit+0x58>
    if(p->ofile[fd]){
    800021e6:	6088                	ld	a0,0(s1)
    800021e8:	f575                	bnez	a0,800021d4 <exit+0x40>
    800021ea:	bfdd                	j	800021e0 <exit+0x4c>
  begin_op();
    800021ec:	00002097          	auipc	ra,0x2
    800021f0:	fac080e7          	jalr	-84(ra) # 80004198 <begin_op>
  iput(p->cwd);
    800021f4:	1509b503          	ld	a0,336(s3)
    800021f8:	00001097          	auipc	ra,0x1
    800021fc:	798080e7          	jalr	1944(ra) # 80003990 <iput>
  end_op();
    80002200:	00002097          	auipc	ra,0x2
    80002204:	018080e7          	jalr	24(ra) # 80004218 <end_op>
  p->cwd = 0;
    80002208:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000220c:	0000f497          	auipc	s1,0xf
    80002210:	99c48493          	addi	s1,s1,-1636 # 80010ba8 <wait_lock>
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9c0080e7          	jalr	-1600(ra) # 80000bd6 <acquire>
  reparent(p);
    8000221e:	854e                	mv	a0,s3
    80002220:	00000097          	auipc	ra,0x0
    80002224:	f1a080e7          	jalr	-230(ra) # 8000213a <reparent>
  wakeup(p->parent);
    80002228:	0389b503          	ld	a0,56(s3)
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	e98080e7          	jalr	-360(ra) # 800020c4 <wakeup>
  acquire(&p->lock);
    80002234:	854e                	mv	a0,s3
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	9a0080e7          	jalr	-1632(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000223e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002242:	4795                	li	a5,5
    80002244:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a40080e7          	jalr	-1472(ra) # 80000c8a <release>
  sched();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	cfc080e7          	jalr	-772(ra) # 80001f4e <sched>
  panic("zombie exit");
    8000225a:	00006517          	auipc	a0,0x6
    8000225e:	01650513          	addi	a0,a0,22 # 80008270 <digits+0x230>
    80002262:	ffffe097          	auipc	ra,0xffffe
    80002266:	2dc080e7          	jalr	732(ra) # 8000053e <panic>

000000008000226a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000226a:	7179                	addi	sp,sp,-48
    8000226c:	f406                	sd	ra,40(sp)
    8000226e:	f022                	sd	s0,32(sp)
    80002270:	ec26                	sd	s1,24(sp)
    80002272:	e84a                	sd	s2,16(sp)
    80002274:	e44e                	sd	s3,8(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000227a:	0000f497          	auipc	s1,0xf
    8000227e:	d4648493          	addi	s1,s1,-698 # 80010fc0 <proc>
    80002282:	00015997          	auipc	s3,0x15
    80002286:	93e98993          	addi	s3,s3,-1730 # 80016bc0 <tickslock>
    acquire(&p->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	94a080e7          	jalr	-1718(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002294:	589c                	lw	a5,48(s1)
    80002296:	01278d63          	beq	a5,s2,800022b0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	9ee080e7          	jalr	-1554(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022a4:	17048493          	addi	s1,s1,368
    800022a8:	ff3491e3          	bne	s1,s3,8000228a <kill+0x20>
  }
  return -1;
    800022ac:	557d                	li	a0,-1
    800022ae:	a829                	j	800022c8 <kill+0x5e>
      p->killed = 1;
    800022b0:	4785                	li	a5,1
    800022b2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022b4:	4c98                	lw	a4,24(s1)
    800022b6:	4789                	li	a5,2
    800022b8:	00f70f63          	beq	a4,a5,800022d6 <kill+0x6c>
      release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
      return 0;
    800022c6:	4501                	li	a0,0
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret
        p->state = RUNNABLE;
    800022d6:	478d                	li	a5,3
    800022d8:	cc9c                	sw	a5,24(s1)
    800022da:	b7cd                	j	800022bc <kill+0x52>

00000000800022dc <setkilled>:

void
setkilled(struct proc *p)
{
    800022dc:	1101                	addi	sp,sp,-32
    800022de:	ec06                	sd	ra,24(sp)
    800022e0:	e822                	sd	s0,16(sp)
    800022e2:	e426                	sd	s1,8(sp)
    800022e4:	1000                	addi	s0,sp,32
    800022e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	8ee080e7          	jalr	-1810(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022f0:	4785                	li	a5,1
    800022f2:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	994080e7          	jalr	-1644(ra) # 80000c8a <release>
}
    800022fe:	60e2                	ld	ra,24(sp)
    80002300:	6442                	ld	s0,16(sp)
    80002302:	64a2                	ld	s1,8(sp)
    80002304:	6105                	addi	sp,sp,32
    80002306:	8082                	ret

0000000080002308 <killed>:

int
killed(struct proc *p)
{
    80002308:	1101                	addi	sp,sp,-32
    8000230a:	ec06                	sd	ra,24(sp)
    8000230c:	e822                	sd	s0,16(sp)
    8000230e:	e426                	sd	s1,8(sp)
    80002310:	e04a                	sd	s2,0(sp)
    80002312:	1000                	addi	s0,sp,32
    80002314:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8c0080e7          	jalr	-1856(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000231e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	966080e7          	jalr	-1690(ra) # 80000c8a <release>
  return k;
}
    8000232c:	854a                	mv	a0,s2
    8000232e:	60e2                	ld	ra,24(sp)
    80002330:	6442                	ld	s0,16(sp)
    80002332:	64a2                	ld	s1,8(sp)
    80002334:	6902                	ld	s2,0(sp)
    80002336:	6105                	addi	sp,sp,32
    80002338:	8082                	ret

000000008000233a <wait>:
{
    8000233a:	715d                	addi	sp,sp,-80
    8000233c:	e486                	sd	ra,72(sp)
    8000233e:	e0a2                	sd	s0,64(sp)
    80002340:	fc26                	sd	s1,56(sp)
    80002342:	f84a                	sd	s2,48(sp)
    80002344:	f44e                	sd	s3,40(sp)
    80002346:	f052                	sd	s4,32(sp)
    80002348:	ec56                	sd	s5,24(sp)
    8000234a:	e85a                	sd	s6,16(sp)
    8000234c:	e45e                	sd	s7,8(sp)
    8000234e:	e062                	sd	s8,0(sp)
    80002350:	0880                	addi	s0,sp,80
    80002352:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	658080e7          	jalr	1624(ra) # 800019ac <myproc>
    8000235c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000235e:	0000f517          	auipc	a0,0xf
    80002362:	84a50513          	addi	a0,a0,-1974 # 80010ba8 <wait_lock>
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	870080e7          	jalr	-1936(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000236e:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002370:	4a15                	li	s4,5
        havekids = 1;
    80002372:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002374:	00015997          	auipc	s3,0x15
    80002378:	84c98993          	addi	s3,s3,-1972 # 80016bc0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237c:	0000fc17          	auipc	s8,0xf
    80002380:	82cc0c13          	addi	s8,s8,-2004 # 80010ba8 <wait_lock>
    havekids = 0;
    80002384:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002386:	0000f497          	auipc	s1,0xf
    8000238a:	c3a48493          	addi	s1,s1,-966 # 80010fc0 <proc>
    8000238e:	a0bd                	j	800023fc <wait+0xc2>
          pid = pp->pid;
    80002390:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002394:	000b0e63          	beqz	s6,800023b0 <wait+0x76>
    80002398:	4691                	li	a3,4
    8000239a:	02c48613          	addi	a2,s1,44
    8000239e:	85da                	mv	a1,s6
    800023a0:	05093503          	ld	a0,80(s2)
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	2c4080e7          	jalr	708(ra) # 80001668 <copyout>
    800023ac:	02054563          	bltz	a0,800023d6 <wait+0x9c>
          freeproc(pp);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	7ac080e7          	jalr	1964(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8ce080e7          	jalr	-1842(ra) # 80000c8a <release>
          release(&wait_lock);
    800023c4:	0000e517          	auipc	a0,0xe
    800023c8:	7e450513          	addi	a0,a0,2020 # 80010ba8 <wait_lock>
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
          return pid;
    800023d4:	a0b5                	j	80002440 <wait+0x106>
            release(&pp->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8b2080e7          	jalr	-1870(ra) # 80000c8a <release>
            release(&wait_lock);
    800023e0:	0000e517          	auipc	a0,0xe
    800023e4:	7c850513          	addi	a0,a0,1992 # 80010ba8 <wait_lock>
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8a2080e7          	jalr	-1886(ra) # 80000c8a <release>
            return -1;
    800023f0:	59fd                	li	s3,-1
    800023f2:	a0b9                	j	80002440 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f4:	17048493          	addi	s1,s1,368
    800023f8:	03348463          	beq	s1,s3,80002420 <wait+0xe6>
      if(pp->parent == p){
    800023fc:	7c9c                	ld	a5,56(s1)
    800023fe:	ff279be3          	bne	a5,s2,800023f4 <wait+0xba>
        acquire(&pp->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	7d2080e7          	jalr	2002(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000240c:	4c9c                	lw	a5,24(s1)
    8000240e:	f94781e3          	beq	a5,s4,80002390 <wait+0x56>
        release(&pp->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
        havekids = 1;
    8000241c:	8756                	mv	a4,s5
    8000241e:	bfd9                	j	800023f4 <wait+0xba>
    if(!havekids || killed(p)){
    80002420:	c719                	beqz	a4,8000242e <wait+0xf4>
    80002422:	854a                	mv	a0,s2
    80002424:	00000097          	auipc	ra,0x0
    80002428:	ee4080e7          	jalr	-284(ra) # 80002308 <killed>
    8000242c:	c51d                	beqz	a0,8000245a <wait+0x120>
      release(&wait_lock);
    8000242e:	0000e517          	auipc	a0,0xe
    80002432:	77a50513          	addi	a0,a0,1914 # 80010ba8 <wait_lock>
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	854080e7          	jalr	-1964(ra) # 80000c8a <release>
      return -1;
    8000243e:	59fd                	li	s3,-1
}
    80002440:	854e                	mv	a0,s3
    80002442:	60a6                	ld	ra,72(sp)
    80002444:	6406                	ld	s0,64(sp)
    80002446:	74e2                	ld	s1,56(sp)
    80002448:	7942                	ld	s2,48(sp)
    8000244a:	79a2                	ld	s3,40(sp)
    8000244c:	7a02                	ld	s4,32(sp)
    8000244e:	6ae2                	ld	s5,24(sp)
    80002450:	6b42                	ld	s6,16(sp)
    80002452:	6ba2                	ld	s7,8(sp)
    80002454:	6c02                	ld	s8,0(sp)
    80002456:	6161                	addi	sp,sp,80
    80002458:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000245a:	85e2                	mv	a1,s8
    8000245c:	854a                	mv	a0,s2
    8000245e:	00000097          	auipc	ra,0x0
    80002462:	c02080e7          	jalr	-1022(ra) # 80002060 <sleep>
    havekids = 0;
    80002466:	bf39                	j	80002384 <wait+0x4a>

0000000080002468 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002468:	7179                	addi	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	e052                	sd	s4,0(sp)
    80002476:	1800                	addi	s0,sp,48
    80002478:	84aa                	mv	s1,a0
    8000247a:	892e                	mv	s2,a1
    8000247c:	89b2                	mv	s3,a2
    8000247e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	52c080e7          	jalr	1324(ra) # 800019ac <myproc>
  if(user_dst){
    80002488:	c08d                	beqz	s1,800024aa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000248a:	86d2                	mv	a3,s4
    8000248c:	864e                	mv	a2,s3
    8000248e:	85ca                	mv	a1,s2
    80002490:	6928                	ld	a0,80(a0)
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	1d6080e7          	jalr	470(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6a02                	ld	s4,0(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret
    memmove((char *)dst, src, len);
    800024aa:	000a061b          	sext.w	a2,s4
    800024ae:	85ce                	mv	a1,s3
    800024b0:	854a                	mv	a0,s2
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	87c080e7          	jalr	-1924(ra) # 80000d2e <memmove>
    return 0;
    800024ba:	8526                	mv	a0,s1
    800024bc:	bff9                	j	8000249a <either_copyout+0x32>

00000000800024be <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
    800024d0:	84ae                	mv	s1,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	4d6080e7          	jalr	1238(ra) # 800019ac <myproc>
  if(user_src){
    800024de:	c08d                	beqz	s1,80002500 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6928                	ld	a0,80(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	20c080e7          	jalr	524(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	826080e7          	jalr	-2010(ra) # 80000d2e <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyin+0x32>

0000000080002514 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002514:	715d                	addi	sp,sp,-80
    80002516:	e486                	sd	ra,72(sp)
    80002518:	e0a2                	sd	s0,64(sp)
    8000251a:	fc26                	sd	s1,56(sp)
    8000251c:	f84a                	sd	s2,48(sp)
    8000251e:	f44e                	sd	s3,40(sp)
    80002520:	f052                	sd	s4,32(sp)
    80002522:	ec56                	sd	s5,24(sp)
    80002524:	e85a                	sd	s6,16(sp)
    80002526:	e45e                	sd	s7,8(sp)
    80002528:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000252a:	00006517          	auipc	a0,0x6
    8000252e:	b9e50513          	addi	a0,a0,-1122 # 800080c8 <digits+0x88>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	056080e7          	jalr	86(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253a:	0000f497          	auipc	s1,0xf
    8000253e:	bde48493          	addi	s1,s1,-1058 # 80011118 <proc+0x158>
    80002542:	00014917          	auipc	s2,0x14
    80002546:	7d690913          	addi	s2,s2,2006 # 80016d18 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000254c:	00006997          	auipc	s3,0x6
    80002550:	d3498993          	addi	s3,s3,-716 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002554:	00006a97          	auipc	s5,0x6
    80002558:	d34a8a93          	addi	s5,s5,-716 # 80008288 <digits+0x248>
    printf("\n");
    8000255c:	00006a17          	auipc	s4,0x6
    80002560:	b6ca0a13          	addi	s4,s4,-1172 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002564:	00006b97          	auipc	s7,0x6
    80002568:	da4b8b93          	addi	s7,s7,-604 # 80008308 <states.0>
    8000256c:	a00d                	j	8000258e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256e:	ed86a583          	lw	a1,-296(a3)
    80002572:	8556                	mv	a0,s5
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	014080e7          	jalr	20(ra) # 80000588 <printf>
    printf("\n");
    8000257c:	8552                	mv	a0,s4
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	00a080e7          	jalr	10(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002586:	17048493          	addi	s1,s1,368
    8000258a:	03248163          	beq	s1,s2,800025ac <procdump+0x98>
    if(p->state == UNUSED)
    8000258e:	86a6                	mv	a3,s1
    80002590:	ec04a783          	lw	a5,-320(s1)
    80002594:	dbed                	beqz	a5,80002586 <procdump+0x72>
      state = "???";
    80002596:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	fcfb6be3          	bltu	s6,a5,8000256e <procdump+0x5a>
    8000259c:	1782                	slli	a5,a5,0x20
    8000259e:	9381                	srli	a5,a5,0x20
    800025a0:	078e                	slli	a5,a5,0x3
    800025a2:	97de                	add	a5,a5,s7
    800025a4:	6390                	ld	a2,0(a5)
    800025a6:	f661                	bnez	a2,8000256e <procdump+0x5a>
      state = "???";
    800025a8:	864e                	mv	a2,s3
    800025aa:	b7d1                	j	8000256e <procdump+0x5a>
  }
}
    800025ac:	60a6                	ld	ra,72(sp)
    800025ae:	6406                	ld	s0,64(sp)
    800025b0:	74e2                	ld	s1,56(sp)
    800025b2:	7942                	ld	s2,48(sp)
    800025b4:	79a2                	ld	s3,40(sp)
    800025b6:	7a02                	ld	s4,32(sp)
    800025b8:	6ae2                	ld	s5,24(sp)
    800025ba:	6b42                	ld	s6,16(sp)
    800025bc:	6ba2                	ld	s7,8(sp)
    800025be:	6161                	addi	sp,sp,80
    800025c0:	8082                	ret

00000000800025c2 <getHelloWorld>:

uint64 
getHelloWorld(void)
{
    800025c2:	1141                	addi	sp,sp,-16
    800025c4:	e406                	sd	ra,8(sp)
    800025c6:	e022                	sd	s0,0(sp)
    800025c8:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    800025ca:	00006517          	auipc	a0,0x6
    800025ce:	cce50513          	addi	a0,a0,-818 # 80008298 <digits+0x258>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	fb6080e7          	jalr	-74(ra) # 80000588 <printf>
  return 0;
}
    800025da:	4501                	li	a0,0
    800025dc:	60a2                	ld	ra,8(sp)
    800025de:	6402                	ld	s0,0(sp)
    800025e0:	0141                	addi	sp,sp,16
    800025e2:	8082                	ret

00000000800025e4 <getProcTick>:

int 
getProcTick(int pid){
    800025e4:	7139                	addi	sp,sp,-64
    800025e6:	fc06                	sd	ra,56(sp)
    800025e8:	f822                	sd	s0,48(sp)
    800025ea:	f426                	sd	s1,40(sp)
    800025ec:	f04a                	sd	s2,32(sp)
    800025ee:	ec4e                	sd	s3,24(sp)
    800025f0:	e852                	sd	s4,16(sp)
    800025f2:	e456                	sd	s5,8(sp)
    800025f4:	e05a                	sd	s6,0(sp)
    800025f6:	0080                	addi	s0,sp,64
    800025f8:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++){
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	9c648493          	addi	s1,s1,-1594 # 80010fc0 <proc>
   // acquire(&p->lock);
    acquire(&tickslock);
    80002602:	00014917          	auipc	s2,0x14
    80002606:	5be90913          	addi	s2,s2,1470 # 80016bc0 <tickslock>
    if(pid == p->pid){
      int diff = ticks - p->ctime;
    8000260a:	00006b17          	auipc	s6,0x6
    8000260e:	316b0b13          	addi	s6,s6,790 # 80008920 <ticks>
      if (diff < 0){
        diff = diff * -1; 
      }
      printf("%d\n", diff);
    80002612:	00006a97          	auipc	s5,0x6
    80002616:	e5ea8a93          	addi	s5,s5,-418 # 80008470 <states.0+0x168>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261a:	00014a17          	auipc	s4,0x14
    8000261e:	5a6a0a13          	addi	s4,s4,1446 # 80016bc0 <tickslock>
    80002622:	a811                	j	80002636 <getProcTick+0x52>
    }
   // release(&p->lock);
   release(&tickslock);
    80002624:	854a                	mv	a0,s2
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	664080e7          	jalr	1636(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262e:	17048493          	addi	s1,s1,368
    80002632:	03448a63          	beq	s1,s4,80002666 <getProcTick+0x82>
    acquire(&tickslock);
    80002636:	854a                	mv	a0,s2
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	59e080e7          	jalr	1438(ra) # 80000bd6 <acquire>
    if(pid == p->pid){
    80002640:	589c                	lw	a5,48(s1)
    80002642:	ff3791e3          	bne	a5,s3,80002624 <getProcTick+0x40>
      int diff = ticks - p->ctime;
    80002646:	000b2783          	lw	a5,0(s6)
    8000264a:	1684a583          	lw	a1,360(s1)
    8000264e:	9f8d                	subw	a5,a5,a1
      printf("%d\n", diff);
    80002650:	41f7d59b          	sraiw	a1,a5,0x1f
    80002654:	8fad                	xor	a5,a5,a1
    80002656:	40b785bb          	subw	a1,a5,a1
    8000265a:	8556                	mv	a0,s5
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	f2c080e7          	jalr	-212(ra) # 80000588 <printf>
    80002664:	b7c1                	j	80002624 <getProcTick+0x40>
  }
  // printf("%d\n", ticks);
  return 0;
}
    80002666:	4501                	li	a0,0
    80002668:	70e2                	ld	ra,56(sp)
    8000266a:	7442                	ld	s0,48(sp)
    8000266c:	74a2                	ld	s1,40(sp)
    8000266e:	7902                	ld	s2,32(sp)
    80002670:	69e2                	ld	s3,24(sp)
    80002672:	6a42                	ld	s4,16(sp)
    80002674:	6aa2                	ld	s5,8(sp)
    80002676:	6b02                	ld	s6,0(sp)
    80002678:	6121                	addi	sp,sp,64
    8000267a:	8082                	ret

000000008000267c <getProcInfo>:

int 
getProcInfo(void){
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    8000268a:	0000f497          	auipc	s1,0xf
    8000268e:	93648493          	addi	s1,s1,-1738 # 80010fc0 <proc>
  
  // for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    80002692:	00006997          	auipc	s3,0x6
    80002696:	c1698993          	addi	s3,s3,-1002 # 800082a8 <digits+0x268>
  for(p = proc; p < &proc[NPROC]; p++){
    8000269a:	00014917          	auipc	s2,0x14
    8000269e:	52690913          	addi	s2,s2,1318 # 80016bc0 <tickslock>
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    800026a2:	1684a603          	lw	a2,360(s1)
    800026a6:	588c                	lw	a1,48(s1)
    800026a8:	854e                	mv	a0,s3
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	ede080e7          	jalr	-290(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b2:	17048493          	addi	s1,s1,368
    800026b6:	ff2496e3          	bne	s1,s2,800026a2 <getProcInfo+0x26>
    // if(p->state == SLEEPING){
    //   cprintf("-pid = %d, create time = %d\n", p->pid, p->ctime);
    // }
  }
  return 0;
}
    800026ba:	4501                	li	a0,0
    800026bc:	70a2                	ld	ra,40(sp)
    800026be:	7402                	ld	s0,32(sp)
    800026c0:	64e2                	ld	s1,24(sp)
    800026c2:	6942                	ld	s2,16(sp)
    800026c4:	69a2                	ld	s3,8(sp)
    800026c6:	6145                	addi	sp,sp,48
    800026c8:	8082                	ret

00000000800026ca <sysinfo>:

int 
sysinfo(void)
{
    800026ca:	1141                	addi	sp,sp,-16
    800026cc:	e406                	sd	ra,8(sp)
    800026ce:	e022                	sd	s0,0(sp)
    800026d0:	0800                	addi	s0,sp,16
  printf("sysinfo ?????\n");
    800026d2:	00006517          	auipc	a0,0x6
    800026d6:	bf650513          	addi	a0,a0,-1034 # 800082c8 <digits+0x288>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	eae080e7          	jalr	-338(ra) # 80000588 <printf>
  return 0;
    800026e2:	4501                	li	a0,0
    800026e4:	60a2                	ld	ra,8(sp)
    800026e6:	6402                	ld	s0,0(sp)
    800026e8:	0141                	addi	sp,sp,16
    800026ea:	8082                	ret

00000000800026ec <swtch>:
    800026ec:	00153023          	sd	ra,0(a0)
    800026f0:	00253423          	sd	sp,8(a0)
    800026f4:	e900                	sd	s0,16(a0)
    800026f6:	ed04                	sd	s1,24(a0)
    800026f8:	03253023          	sd	s2,32(a0)
    800026fc:	03353423          	sd	s3,40(a0)
    80002700:	03453823          	sd	s4,48(a0)
    80002704:	03553c23          	sd	s5,56(a0)
    80002708:	05653023          	sd	s6,64(a0)
    8000270c:	05753423          	sd	s7,72(a0)
    80002710:	05853823          	sd	s8,80(a0)
    80002714:	05953c23          	sd	s9,88(a0)
    80002718:	07a53023          	sd	s10,96(a0)
    8000271c:	07b53423          	sd	s11,104(a0)
    80002720:	0005b083          	ld	ra,0(a1)
    80002724:	0085b103          	ld	sp,8(a1)
    80002728:	6980                	ld	s0,16(a1)
    8000272a:	6d84                	ld	s1,24(a1)
    8000272c:	0205b903          	ld	s2,32(a1)
    80002730:	0285b983          	ld	s3,40(a1)
    80002734:	0305ba03          	ld	s4,48(a1)
    80002738:	0385ba83          	ld	s5,56(a1)
    8000273c:	0405bb03          	ld	s6,64(a1)
    80002740:	0485bb83          	ld	s7,72(a1)
    80002744:	0505bc03          	ld	s8,80(a1)
    80002748:	0585bc83          	ld	s9,88(a1)
    8000274c:	0605bd03          	ld	s10,96(a1)
    80002750:	0685bd83          	ld	s11,104(a1)
    80002754:	8082                	ret

0000000080002756 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002756:	1141                	addi	sp,sp,-16
    80002758:	e406                	sd	ra,8(sp)
    8000275a:	e022                	sd	s0,0(sp)
    8000275c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000275e:	00006597          	auipc	a1,0x6
    80002762:	bda58593          	addi	a1,a1,-1062 # 80008338 <states.0+0x30>
    80002766:	00014517          	auipc	a0,0x14
    8000276a:	45a50513          	addi	a0,a0,1114 # 80016bc0 <tickslock>
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	3d8080e7          	jalr	984(ra) # 80000b46 <initlock>
}
    80002776:	60a2                	ld	ra,8(sp)
    80002778:	6402                	ld	s0,0(sp)
    8000277a:	0141                	addi	sp,sp,16
    8000277c:	8082                	ret

000000008000277e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000277e:	1141                	addi	sp,sp,-16
    80002780:	e422                	sd	s0,8(sp)
    80002782:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002784:	00003797          	auipc	a5,0x3
    80002788:	52c78793          	addi	a5,a5,1324 # 80005cb0 <kernelvec>
    8000278c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002790:	6422                	ld	s0,8(sp)
    80002792:	0141                	addi	sp,sp,16
    80002794:	8082                	ret

0000000080002796 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002796:	1141                	addi	sp,sp,-16
    80002798:	e406                	sd	ra,8(sp)
    8000279a:	e022                	sd	s0,0(sp)
    8000279c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000279e:	fffff097          	auipc	ra,0xfffff
    800027a2:	20e080e7          	jalr	526(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ac:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027b0:	00005617          	auipc	a2,0x5
    800027b4:	85060613          	addi	a2,a2,-1968 # 80007000 <_trampoline>
    800027b8:	00005697          	auipc	a3,0x5
    800027bc:	84868693          	addi	a3,a3,-1976 # 80007000 <_trampoline>
    800027c0:	8e91                	sub	a3,a3,a2
    800027c2:	040007b7          	lui	a5,0x4000
    800027c6:	17fd                	addi	a5,a5,-1
    800027c8:	07b2                	slli	a5,a5,0xc
    800027ca:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027cc:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027d2:	180026f3          	csrr	a3,satp
    800027d6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027d8:	6d38                	ld	a4,88(a0)
    800027da:	6134                	ld	a3,64(a0)
    800027dc:	6585                	lui	a1,0x1
    800027de:	96ae                	add	a3,a3,a1
    800027e0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027e2:	6d38                	ld	a4,88(a0)
    800027e4:	00000697          	auipc	a3,0x0
    800027e8:	13068693          	addi	a3,a3,304 # 80002914 <usertrap>
    800027ec:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027ee:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f0:	8692                	mv	a3,tp
    800027f2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027f8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027fc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002800:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002804:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002806:	6f18                	ld	a4,24(a4)
    80002808:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000280c:	6928                	ld	a0,80(a0)
    8000280e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002810:	00005717          	auipc	a4,0x5
    80002814:	88c70713          	addi	a4,a4,-1908 # 8000709c <userret>
    80002818:	8f11                	sub	a4,a4,a2
    8000281a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000281c:	577d                	li	a4,-1
    8000281e:	177e                	slli	a4,a4,0x3f
    80002820:	8d59                	or	a0,a0,a4
    80002822:	9782                	jalr	a5
}
    80002824:	60a2                	ld	ra,8(sp)
    80002826:	6402                	ld	s0,0(sp)
    80002828:	0141                	addi	sp,sp,16
    8000282a:	8082                	ret

000000008000282c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000282c:	1101                	addi	sp,sp,-32
    8000282e:	ec06                	sd	ra,24(sp)
    80002830:	e822                	sd	s0,16(sp)
    80002832:	e426                	sd	s1,8(sp)
    80002834:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002836:	00014497          	auipc	s1,0x14
    8000283a:	38a48493          	addi	s1,s1,906 # 80016bc0 <tickslock>
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	396080e7          	jalr	918(ra) # 80000bd6 <acquire>
  ticks++;
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	0d850513          	addi	a0,a0,216 # 80008920 <ticks>
    80002850:	411c                	lw	a5,0(a0)
    80002852:	2785                	addiw	a5,a5,1
    80002854:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	86e080e7          	jalr	-1938(ra) # 800020c4 <wakeup>
  release(&tickslock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	42a080e7          	jalr	1066(ra) # 80000c8a <release>
}
    80002868:	60e2                	ld	ra,24(sp)
    8000286a:	6442                	ld	s0,16(sp)
    8000286c:	64a2                	ld	s1,8(sp)
    8000286e:	6105                	addi	sp,sp,32
    80002870:	8082                	ret

0000000080002872 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002872:	1101                	addi	sp,sp,-32
    80002874:	ec06                	sd	ra,24(sp)
    80002876:	e822                	sd	s0,16(sp)
    80002878:	e426                	sd	s1,8(sp)
    8000287a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002880:	00074d63          	bltz	a4,8000289a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002884:	57fd                	li	a5,-1
    80002886:	17fe                	slli	a5,a5,0x3f
    80002888:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000288a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000288c:	06f70363          	beq	a4,a5,800028f2 <devintr+0x80>
  }
}
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6105                	addi	sp,sp,32
    80002898:	8082                	ret
     (scause & 0xff) == 9){
    8000289a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000289e:	46a5                	li	a3,9
    800028a0:	fed792e3          	bne	a5,a3,80002884 <devintr+0x12>
    int irq = plic_claim();
    800028a4:	00003097          	auipc	ra,0x3
    800028a8:	514080e7          	jalr	1300(ra) # 80005db8 <plic_claim>
    800028ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ae:	47a9                	li	a5,10
    800028b0:	02f50763          	beq	a0,a5,800028de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028b4:	4785                	li	a5,1
    800028b6:	02f50963          	beq	a0,a5,800028e8 <devintr+0x76>
    return 1;
    800028ba:	4505                	li	a0,1
    } else if(irq){
    800028bc:	d8f1                	beqz	s1,80002890 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028be:	85a6                	mv	a1,s1
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a8050513          	addi	a0,a0,-1408 # 80008340 <states.0+0x38>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc0080e7          	jalr	-832(ra) # 80000588 <printf>
      plic_complete(irq);
    800028d0:	8526                	mv	a0,s1
    800028d2:	00003097          	auipc	ra,0x3
    800028d6:	50a080e7          	jalr	1290(ra) # 80005ddc <plic_complete>
    return 1;
    800028da:	4505                	li	a0,1
    800028dc:	bf55                	j	80002890 <devintr+0x1e>
      uartintr();
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	0bc080e7          	jalr	188(ra) # 8000099a <uartintr>
    800028e6:	b7ed                	j	800028d0 <devintr+0x5e>
      virtio_disk_intr();
    800028e8:	00004097          	auipc	ra,0x4
    800028ec:	9c0080e7          	jalr	-1600(ra) # 800062a8 <virtio_disk_intr>
    800028f0:	b7c5                	j	800028d0 <devintr+0x5e>
    if(cpuid() == 0){
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	08e080e7          	jalr	142(ra) # 80001980 <cpuid>
    800028fa:	c901                	beqz	a0,8000290a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002900:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002902:	14479073          	csrw	sip,a5
    return 2;
    80002906:	4509                	li	a0,2
    80002908:	b761                	j	80002890 <devintr+0x1e>
      clockintr();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	f22080e7          	jalr	-222(ra) # 8000282c <clockintr>
    80002912:	b7ed                	j	800028fc <devintr+0x8a>

0000000080002914 <usertrap>:
{
    80002914:	1101                	addi	sp,sp,-32
    80002916:	ec06                	sd	ra,24(sp)
    80002918:	e822                	sd	s0,16(sp)
    8000291a:	e426                	sd	s1,8(sp)
    8000291c:	e04a                	sd	s2,0(sp)
    8000291e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002924:	1007f793          	andi	a5,a5,256
    80002928:	e3b1                	bnez	a5,8000296c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000292a:	00003797          	auipc	a5,0x3
    8000292e:	38678793          	addi	a5,a5,902 # 80005cb0 <kernelvec>
    80002932:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	076080e7          	jalr	118(ra) # 800019ac <myproc>
    8000293e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002940:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002942:	14102773          	csrr	a4,sepc
    80002946:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002948:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000294c:	47a1                	li	a5,8
    8000294e:	02f70763          	beq	a4,a5,8000297c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002952:	00000097          	auipc	ra,0x0
    80002956:	f20080e7          	jalr	-224(ra) # 80002872 <devintr>
    8000295a:	892a                	mv	s2,a0
    8000295c:	c151                	beqz	a0,800029e0 <usertrap+0xcc>
  if(killed(p))
    8000295e:	8526                	mv	a0,s1
    80002960:	00000097          	auipc	ra,0x0
    80002964:	9a8080e7          	jalr	-1624(ra) # 80002308 <killed>
    80002968:	c929                	beqz	a0,800029ba <usertrap+0xa6>
    8000296a:	a099                	j	800029b0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	9f450513          	addi	a0,a0,-1548 # 80008360 <states.0+0x58>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	bca080e7          	jalr	-1078(ra) # 8000053e <panic>
    if(killed(p))
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	98c080e7          	jalr	-1652(ra) # 80002308 <killed>
    80002984:	e921                	bnez	a0,800029d4 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002986:	6cb8                	ld	a4,88(s1)
    80002988:	6f1c                	ld	a5,24(a4)
    8000298a:	0791                	addi	a5,a5,4
    8000298c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002992:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002996:	10079073          	csrw	sstatus,a5
    syscall();
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	2d4080e7          	jalr	724(ra) # 80002c6e <syscall>
  if(killed(p))
    800029a2:	8526                	mv	a0,s1
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	964080e7          	jalr	-1692(ra) # 80002308 <killed>
    800029ac:	c911                	beqz	a0,800029c0 <usertrap+0xac>
    800029ae:	4901                	li	s2,0
    exit(-1);
    800029b0:	557d                	li	a0,-1
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	7e2080e7          	jalr	2018(ra) # 80002194 <exit>
  if(which_dev == 2)
    800029ba:	4789                	li	a5,2
    800029bc:	04f90f63          	beq	s2,a5,80002a1a <usertrap+0x106>
  usertrapret();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	dd6080e7          	jalr	-554(ra) # 80002796 <usertrapret>
}
    800029c8:	60e2                	ld	ra,24(sp)
    800029ca:	6442                	ld	s0,16(sp)
    800029cc:	64a2                	ld	s1,8(sp)
    800029ce:	6902                	ld	s2,0(sp)
    800029d0:	6105                	addi	sp,sp,32
    800029d2:	8082                	ret
      exit(-1);
    800029d4:	557d                	li	a0,-1
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	7be080e7          	jalr	1982(ra) # 80002194 <exit>
    800029de:	b765                	j	80002986 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029e4:	5890                	lw	a2,48(s1)
    800029e6:	00006517          	auipc	a0,0x6
    800029ea:	99a50513          	addi	a0,a0,-1638 # 80008380 <states.0+0x78>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b9a080e7          	jalr	-1126(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029fa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	9b250513          	addi	a0,a0,-1614 # 800083b0 <states.0+0xa8>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b82080e7          	jalr	-1150(ra) # 80000588 <printf>
    setkilled(p);
    80002a0e:	8526                	mv	a0,s1
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	8cc080e7          	jalr	-1844(ra) # 800022dc <setkilled>
    80002a18:	b769                	j	800029a2 <usertrap+0x8e>
    yield();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	60a080e7          	jalr	1546(ra) # 80002024 <yield>
    80002a22:	bf79                	j	800029c0 <usertrap+0xac>

0000000080002a24 <kerneltrap>:
{
    80002a24:	7179                	addi	sp,sp,-48
    80002a26:	f406                	sd	ra,40(sp)
    80002a28:	f022                	sd	s0,32(sp)
    80002a2a:	ec26                	sd	s1,24(sp)
    80002a2c:	e84a                	sd	s2,16(sp)
    80002a2e:	e44e                	sd	s3,8(sp)
    80002a30:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a32:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a36:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a3e:	1004f793          	andi	a5,s1,256
    80002a42:	cb85                	beqz	a5,80002a72 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a44:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a48:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a4a:	ef85                	bnez	a5,80002a82 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	e26080e7          	jalr	-474(ra) # 80002872 <devintr>
    80002a54:	cd1d                	beqz	a0,80002a92 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a56:	4789                	li	a5,2
    80002a58:	06f50a63          	beq	a0,a5,80002acc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a5c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a60:	10049073          	csrw	sstatus,s1
}
    80002a64:	70a2                	ld	ra,40(sp)
    80002a66:	7402                	ld	s0,32(sp)
    80002a68:	64e2                	ld	s1,24(sp)
    80002a6a:	6942                	ld	s2,16(sp)
    80002a6c:	69a2                	ld	s3,8(sp)
    80002a6e:	6145                	addi	sp,sp,48
    80002a70:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	95e50513          	addi	a0,a0,-1698 # 800083d0 <states.0+0xc8>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	97650513          	addi	a0,a0,-1674 # 800083f8 <states.0+0xf0>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a92:	85ce                	mv	a1,s3
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	98450513          	addi	a0,a0,-1660 # 80008418 <states.0+0x110>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	aec080e7          	jalr	-1300(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aac:	00006517          	auipc	a0,0x6
    80002ab0:	97c50513          	addi	a0,a0,-1668 # 80008428 <states.0+0x120>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	ad4080e7          	jalr	-1324(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	98450513          	addi	a0,a0,-1660 # 80008440 <states.0+0x138>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	a7a080e7          	jalr	-1414(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	ee0080e7          	jalr	-288(ra) # 800019ac <myproc>
    80002ad4:	d541                	beqz	a0,80002a5c <kerneltrap+0x38>
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	ed6080e7          	jalr	-298(ra) # 800019ac <myproc>
    80002ade:	4d18                	lw	a4,24(a0)
    80002ae0:	4791                	li	a5,4
    80002ae2:	f6f71de3          	bne	a4,a5,80002a5c <kerneltrap+0x38>
    yield();
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	53e080e7          	jalr	1342(ra) # 80002024 <yield>
    80002aee:	b7bd                	j	80002a5c <kerneltrap+0x38>

0000000080002af0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002af0:	1101                	addi	sp,sp,-32
    80002af2:	ec06                	sd	ra,24(sp)
    80002af4:	e822                	sd	s0,16(sp)
    80002af6:	e426                	sd	s1,8(sp)
    80002af8:	1000                	addi	s0,sp,32
    80002afa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	eb0080e7          	jalr	-336(ra) # 800019ac <myproc>
  switch (n) {
    80002b04:	4795                	li	a5,5
    80002b06:	0497e163          	bltu	a5,s1,80002b48 <argraw+0x58>
    80002b0a:	048a                	slli	s1,s1,0x2
    80002b0c:	00006717          	auipc	a4,0x6
    80002b10:	96c70713          	addi	a4,a4,-1684 # 80008478 <states.0+0x170>
    80002b14:	94ba                	add	s1,s1,a4
    80002b16:	409c                	lw	a5,0(s1)
    80002b18:	97ba                	add	a5,a5,a4
    80002b1a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b1c:	6d3c                	ld	a5,88(a0)
    80002b1e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret
    return p->trapframe->a1;
    80002b2a:	6d3c                	ld	a5,88(a0)
    80002b2c:	7fa8                	ld	a0,120(a5)
    80002b2e:	bfcd                	j	80002b20 <argraw+0x30>
    return p->trapframe->a2;
    80002b30:	6d3c                	ld	a5,88(a0)
    80002b32:	63c8                	ld	a0,128(a5)
    80002b34:	b7f5                	j	80002b20 <argraw+0x30>
    return p->trapframe->a3;
    80002b36:	6d3c                	ld	a5,88(a0)
    80002b38:	67c8                	ld	a0,136(a5)
    80002b3a:	b7dd                	j	80002b20 <argraw+0x30>
    return p->trapframe->a4;
    80002b3c:	6d3c                	ld	a5,88(a0)
    80002b3e:	6bc8                	ld	a0,144(a5)
    80002b40:	b7c5                	j	80002b20 <argraw+0x30>
    return p->trapframe->a5;
    80002b42:	6d3c                	ld	a5,88(a0)
    80002b44:	6fc8                	ld	a0,152(a5)
    80002b46:	bfe9                	j	80002b20 <argraw+0x30>
  panic("argraw");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	90850513          	addi	a0,a0,-1784 # 80008450 <states.0+0x148>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>

0000000080002b58 <fetchaddr>:
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	e04a                	sd	s2,0(sp)
    80002b62:	1000                	addi	s0,sp,32
    80002b64:	84aa                	mv	s1,a0
    80002b66:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e44080e7          	jalr	-444(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b70:	653c                	ld	a5,72(a0)
    80002b72:	02f4f863          	bgeu	s1,a5,80002ba2 <fetchaddr+0x4a>
    80002b76:	00848713          	addi	a4,s1,8
    80002b7a:	02e7e663          	bltu	a5,a4,80002ba6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b7e:	46a1                	li	a3,8
    80002b80:	8626                	mv	a2,s1
    80002b82:	85ca                	mv	a1,s2
    80002b84:	6928                	ld	a0,80(a0)
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	b6e080e7          	jalr	-1170(ra) # 800016f4 <copyin>
    80002b8e:	00a03533          	snez	a0,a0
    80002b92:	40a00533          	neg	a0,a0
}
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6902                	ld	s2,0(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret
    return -1;
    80002ba2:	557d                	li	a0,-1
    80002ba4:	bfcd                	j	80002b96 <fetchaddr+0x3e>
    80002ba6:	557d                	li	a0,-1
    80002ba8:	b7fd                	j	80002b96 <fetchaddr+0x3e>

0000000080002baa <fetchstr>:
{
    80002baa:	7179                	addi	sp,sp,-48
    80002bac:	f406                	sd	ra,40(sp)
    80002bae:	f022                	sd	s0,32(sp)
    80002bb0:	ec26                	sd	s1,24(sp)
    80002bb2:	e84a                	sd	s2,16(sp)
    80002bb4:	e44e                	sd	s3,8(sp)
    80002bb6:	1800                	addi	s0,sp,48
    80002bb8:	892a                	mv	s2,a0
    80002bba:	84ae                	mv	s1,a1
    80002bbc:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	dee080e7          	jalr	-530(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bc6:	86ce                	mv	a3,s3
    80002bc8:	864a                	mv	a2,s2
    80002bca:	85a6                	mv	a1,s1
    80002bcc:	6928                	ld	a0,80(a0)
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	bb4080e7          	jalr	-1100(ra) # 80001782 <copyinstr>
    80002bd6:	00054e63          	bltz	a0,80002bf2 <fetchstr+0x48>
  return strlen(buf);
    80002bda:	8526                	mv	a0,s1
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	272080e7          	jalr	626(ra) # 80000e4e <strlen>
}
    80002be4:	70a2                	ld	ra,40(sp)
    80002be6:	7402                	ld	s0,32(sp)
    80002be8:	64e2                	ld	s1,24(sp)
    80002bea:	6942                	ld	s2,16(sp)
    80002bec:	69a2                	ld	s3,8(sp)
    80002bee:	6145                	addi	sp,sp,48
    80002bf0:	8082                	ret
    return -1;
    80002bf2:	557d                	li	a0,-1
    80002bf4:	bfc5                	j	80002be4 <fetchstr+0x3a>

0000000080002bf6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bf6:	1101                	addi	sp,sp,-32
    80002bf8:	ec06                	sd	ra,24(sp)
    80002bfa:	e822                	sd	s0,16(sp)
    80002bfc:	e426                	sd	s1,8(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	eee080e7          	jalr	-274(ra) # 80002af0 <argraw>
    80002c0a:	c088                	sw	a0,0(s1)
}
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	64a2                	ld	s1,8(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	1000                	addi	s0,sp,32
    80002c20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	ece080e7          	jalr	-306(ra) # 80002af0 <argraw>
    80002c2a:	e088                	sd	a0,0(s1)
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret

0000000080002c36 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c36:	7179                	addi	sp,sp,-48
    80002c38:	f406                	sd	ra,40(sp)
    80002c3a:	f022                	sd	s0,32(sp)
    80002c3c:	ec26                	sd	s1,24(sp)
    80002c3e:	e84a                	sd	s2,16(sp)
    80002c40:	1800                	addi	s0,sp,48
    80002c42:	84ae                	mv	s1,a1
    80002c44:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c46:	fd840593          	addi	a1,s0,-40
    80002c4a:	00000097          	auipc	ra,0x0
    80002c4e:	fcc080e7          	jalr	-52(ra) # 80002c16 <argaddr>
  return fetchstr(addr, buf, max);
    80002c52:	864a                	mv	a2,s2
    80002c54:	85a6                	mv	a1,s1
    80002c56:	fd843503          	ld	a0,-40(s0)
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	f50080e7          	jalr	-176(ra) # 80002baa <fetchstr>
}
    80002c62:	70a2                	ld	ra,40(sp)
    80002c64:	7402                	ld	s0,32(sp)
    80002c66:	64e2                	ld	s1,24(sp)
    80002c68:	6942                	ld	s2,16(sp)
    80002c6a:	6145                	addi	sp,sp,48
    80002c6c:	8082                	ret

0000000080002c6e <syscall>:
[SYS_sysinfo] sys_sysinfo,
};

void
syscall(void)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	e04a                	sd	s2,0(sp)
    80002c78:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d32080e7          	jalr	-718(ra) # 800019ac <myproc>
    80002c82:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c84:	05853903          	ld	s2,88(a0)
    80002c88:	0a893783          	ld	a5,168(s2)
    80002c8c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c90:	37fd                	addiw	a5,a5,-1
    80002c92:	4761                	li	a4,24
    80002c94:	00f76f63          	bltu	a4,a5,80002cb2 <syscall+0x44>
    80002c98:	00369713          	slli	a4,a3,0x3
    80002c9c:	00005797          	auipc	a5,0x5
    80002ca0:	7f478793          	addi	a5,a5,2036 # 80008490 <syscalls>
    80002ca4:	97ba                	add	a5,a5,a4
    80002ca6:	639c                	ld	a5,0(a5)
    80002ca8:	c789                	beqz	a5,80002cb2 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002caa:	9782                	jalr	a5
    80002cac:	06a93823          	sd	a0,112(s2)
    80002cb0:	a839                	j	80002cce <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cb2:	15848613          	addi	a2,s1,344
    80002cb6:	588c                	lw	a1,48(s1)
    80002cb8:	00005517          	auipc	a0,0x5
    80002cbc:	7a050513          	addi	a0,a0,1952 # 80008458 <states.0+0x150>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	8c8080e7          	jalr	-1848(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cc8:	6cbc                	ld	a5,88(s1)
    80002cca:	577d                	li	a4,-1
    80002ccc:	fbb8                	sd	a4,112(a5)
  }
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6902                	ld	s2,0(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ce2:	fec40593          	addi	a1,s0,-20
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	f0e080e7          	jalr	-242(ra) # 80002bf6 <argint>
  exit(n);
    80002cf0:	fec42503          	lw	a0,-20(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	4a0080e7          	jalr	1184(ra) # 80002194 <exit>
  return 0;  // not reached
}
    80002cfc:	4501                	li	a0,0
    80002cfe:	60e2                	ld	ra,24(sp)
    80002d00:	6442                	ld	s0,16(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret

0000000080002d06 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d06:	1141                	addi	sp,sp,-16
    80002d08:	e406                	sd	ra,8(sp)
    80002d0a:	e022                	sd	s0,0(sp)
    80002d0c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	c9e080e7          	jalr	-866(ra) # 800019ac <myproc>
}
    80002d16:	5908                	lw	a0,48(a0)
    80002d18:	60a2                	ld	ra,8(sp)
    80002d1a:	6402                	ld	s0,0(sp)
    80002d1c:	0141                	addi	sp,sp,16
    80002d1e:	8082                	ret

0000000080002d20 <sys_fork>:

uint64
sys_fork(void)
{
    80002d20:	1141                	addi	sp,sp,-16
    80002d22:	e406                	sd	ra,8(sp)
    80002d24:	e022                	sd	s0,0(sp)
    80002d26:	0800                	addi	s0,sp,16
  return fork();
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	046080e7          	jalr	70(ra) # 80001d6e <fork>
}
    80002d30:	60a2                	ld	ra,8(sp)
    80002d32:	6402                	ld	s0,0(sp)
    80002d34:	0141                	addi	sp,sp,16
    80002d36:	8082                	ret

0000000080002d38 <sys_wait>:

uint64
sys_wait(void)
{
    80002d38:	1101                	addi	sp,sp,-32
    80002d3a:	ec06                	sd	ra,24(sp)
    80002d3c:	e822                	sd	s0,16(sp)
    80002d3e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d40:	fe840593          	addi	a1,s0,-24
    80002d44:	4501                	li	a0,0
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	ed0080e7          	jalr	-304(ra) # 80002c16 <argaddr>
  return wait(p);
    80002d4e:	fe843503          	ld	a0,-24(s0)
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	5e8080e7          	jalr	1512(ra) # 8000233a <wait>
}
    80002d5a:	60e2                	ld	ra,24(sp)
    80002d5c:	6442                	ld	s0,16(sp)
    80002d5e:	6105                	addi	sp,sp,32
    80002d60:	8082                	ret

0000000080002d62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d62:	7179                	addi	sp,sp,-48
    80002d64:	f406                	sd	ra,40(sp)
    80002d66:	f022                	sd	s0,32(sp)
    80002d68:	ec26                	sd	s1,24(sp)
    80002d6a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d6c:	fdc40593          	addi	a1,s0,-36
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	e84080e7          	jalr	-380(ra) # 80002bf6 <argint>
  addr = myproc()->sz;
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	c32080e7          	jalr	-974(ra) # 800019ac <myproc>
    80002d82:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d84:	fdc42503          	lw	a0,-36(s0)
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	f8a080e7          	jalr	-118(ra) # 80001d12 <growproc>
    80002d90:	00054863          	bltz	a0,80002da0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d94:	8526                	mv	a0,s1
    80002d96:	70a2                	ld	ra,40(sp)
    80002d98:	7402                	ld	s0,32(sp)
    80002d9a:	64e2                	ld	s1,24(sp)
    80002d9c:	6145                	addi	sp,sp,48
    80002d9e:	8082                	ret
    return -1;
    80002da0:	54fd                	li	s1,-1
    80002da2:	bfcd                	j	80002d94 <sys_sbrk+0x32>

0000000080002da4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002da4:	7139                	addi	sp,sp,-64
    80002da6:	fc06                	sd	ra,56(sp)
    80002da8:	f822                	sd	s0,48(sp)
    80002daa:	f426                	sd	s1,40(sp)
    80002dac:	f04a                	sd	s2,32(sp)
    80002dae:	ec4e                	sd	s3,24(sp)
    80002db0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002db2:	fcc40593          	addi	a1,s0,-52
    80002db6:	4501                	li	a0,0
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	e3e080e7          	jalr	-450(ra) # 80002bf6 <argint>
  acquire(&tickslock);
    80002dc0:	00014517          	auipc	a0,0x14
    80002dc4:	e0050513          	addi	a0,a0,-512 # 80016bc0 <tickslock>
    80002dc8:	ffffe097          	auipc	ra,0xffffe
    80002dcc:	e0e080e7          	jalr	-498(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002dd0:	00006917          	auipc	s2,0x6
    80002dd4:	b5092903          	lw	s2,-1200(s2) # 80008920 <ticks>
  while(ticks - ticks0 < n){
    80002dd8:	fcc42783          	lw	a5,-52(s0)
    80002ddc:	cf9d                	beqz	a5,80002e1a <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dde:	00014997          	auipc	s3,0x14
    80002de2:	de298993          	addi	s3,s3,-542 # 80016bc0 <tickslock>
    80002de6:	00006497          	auipc	s1,0x6
    80002dea:	b3a48493          	addi	s1,s1,-1222 # 80008920 <ticks>
    if(killed(myproc())){
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	bbe080e7          	jalr	-1090(ra) # 800019ac <myproc>
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	512080e7          	jalr	1298(ra) # 80002308 <killed>
    80002dfe:	ed15                	bnez	a0,80002e3a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e00:	85ce                	mv	a1,s3
    80002e02:	8526                	mv	a0,s1
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	25c080e7          	jalr	604(ra) # 80002060 <sleep>
  while(ticks - ticks0 < n){
    80002e0c:	409c                	lw	a5,0(s1)
    80002e0e:	412787bb          	subw	a5,a5,s2
    80002e12:	fcc42703          	lw	a4,-52(s0)
    80002e16:	fce7ece3          	bltu	a5,a4,80002dee <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e1a:	00014517          	auipc	a0,0x14
    80002e1e:	da650513          	addi	a0,a0,-602 # 80016bc0 <tickslock>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	e68080e7          	jalr	-408(ra) # 80000c8a <release>
  return 0;
    80002e2a:	4501                	li	a0,0
}
    80002e2c:	70e2                	ld	ra,56(sp)
    80002e2e:	7442                	ld	s0,48(sp)
    80002e30:	74a2                	ld	s1,40(sp)
    80002e32:	7902                	ld	s2,32(sp)
    80002e34:	69e2                	ld	s3,24(sp)
    80002e36:	6121                	addi	sp,sp,64
    80002e38:	8082                	ret
      release(&tickslock);
    80002e3a:	00014517          	auipc	a0,0x14
    80002e3e:	d8650513          	addi	a0,a0,-634 # 80016bc0 <tickslock>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e48080e7          	jalr	-440(ra) # 80000c8a <release>
      return -1;
    80002e4a:	557d                	li	a0,-1
    80002e4c:	b7c5                	j	80002e2c <sys_sleep+0x88>

0000000080002e4e <sys_kill>:

uint64
sys_kill(void)
{ 
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e56:	fec40593          	addi	a1,s0,-20
    80002e5a:	4501                	li	a0,0
    80002e5c:	00000097          	auipc	ra,0x0
    80002e60:	d9a080e7          	jalr	-614(ra) # 80002bf6 <argint>
  return kill(pid);
    80002e64:	fec42503          	lw	a0,-20(s0)
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	402080e7          	jalr	1026(ra) # 8000226a <kill>
}
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e82:	00014517          	auipc	a0,0x14
    80002e86:	d3e50513          	addi	a0,a0,-706 # 80016bc0 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	d4c080e7          	jalr	-692(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e92:	00006497          	auipc	s1,0x6
    80002e96:	a8e4a483          	lw	s1,-1394(s1) # 80008920 <ticks>
  release(&tickslock);
    80002e9a:	00014517          	auipc	a0,0x14
    80002e9e:	d2650513          	addi	a0,a0,-730 # 80016bc0 <tickslock>
    80002ea2:	ffffe097          	auipc	ra,0xffffe
    80002ea6:	de8080e7          	jalr	-536(ra) # 80000c8a <release>
  return xticks;
}
    80002eaa:	02049513          	slli	a0,s1,0x20
    80002eae:	9101                	srli	a0,a0,0x20
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <sys_getHelloWorld>:

int 
sys_getHelloWorld(void)
{
    80002eba:	1141                	addi	sp,sp,-16
    80002ebc:	e406                	sd	ra,8(sp)
    80002ebe:	e022                	sd	s0,0(sp)
    80002ec0:	0800                	addi	s0,sp,16
  return getHelloWorld();
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	700080e7          	jalr	1792(ra) # 800025c2 <getHelloWorld>
}
    80002eca:	2501                	sext.w	a0,a0
    80002ecc:	60a2                	ld	ra,8(sp)
    80002ece:	6402                	ld	s0,0(sp)
    80002ed0:	0141                	addi	sp,sp,16
    80002ed2:	8082                	ret

0000000080002ed4 <sys_getProcTick>:

int
sys_getProcTick(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    80002edc:	fec40593          	addi	a1,s0,-20
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	d14080e7          	jalr	-748(ra) # 80002bf6 <argint>
  return getProcTick(pid);
    80002eea:	fec42503          	lw	a0,-20(s0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	6f6080e7          	jalr	1782(ra) # 800025e4 <getProcTick>
 // return getProcTick();
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_getProcInfo>:

int
sys_getProcInfo(void)
{
    80002efe:	1141                	addi	sp,sp,-16
    80002f00:	e406                	sd	ra,8(sp)
    80002f02:	e022                	sd	s0,0(sp)
    80002f04:	0800                	addi	s0,sp,16
  return getProcInfo();
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	776080e7          	jalr	1910(ra) # 8000267c <getProcInfo>
}
    80002f0e:	60a2                	ld	ra,8(sp)
    80002f10:	6402                	ld	s0,0(sp)
    80002f12:	0141                	addi	sp,sp,16
    80002f14:	8082                	ret

0000000080002f16 <sys_sysinfo>:

int
sys_sysinfo(void)
{
    80002f16:	1141                	addi	sp,sp,-16
    80002f18:	e406                	sd	ra,8(sp)
    80002f1a:	e022                	sd	s0,0(sp)
    80002f1c:	0800                	addi	s0,sp,16
  return sysinfo();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	7ac080e7          	jalr	1964(ra) # 800026ca <sysinfo>
  // return 0;
    80002f26:	60a2                	ld	ra,8(sp)
    80002f28:	6402                	ld	s0,0(sp)
    80002f2a:	0141                	addi	sp,sp,16
    80002f2c:	8082                	ret

0000000080002f2e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f2e:	7179                	addi	sp,sp,-48
    80002f30:	f406                	sd	ra,40(sp)
    80002f32:	f022                	sd	s0,32(sp)
    80002f34:	ec26                	sd	s1,24(sp)
    80002f36:	e84a                	sd	s2,16(sp)
    80002f38:	e44e                	sd	s3,8(sp)
    80002f3a:	e052                	sd	s4,0(sp)
    80002f3c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f3e:	00005597          	auipc	a1,0x5
    80002f42:	62258593          	addi	a1,a1,1570 # 80008560 <syscalls+0xd0>
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	c9250513          	addi	a0,a0,-878 # 80016bd8 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	bf8080e7          	jalr	-1032(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f56:	0001c797          	auipc	a5,0x1c
    80002f5a:	c8278793          	addi	a5,a5,-894 # 8001ebd8 <bcache+0x8000>
    80002f5e:	0001c717          	auipc	a4,0x1c
    80002f62:	ee270713          	addi	a4,a4,-286 # 8001ee40 <bcache+0x8268>
    80002f66:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f6a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f6e:	00014497          	auipc	s1,0x14
    80002f72:	c8248493          	addi	s1,s1,-894 # 80016bf0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f76:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f78:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f7a:	00005a17          	auipc	s4,0x5
    80002f7e:	5eea0a13          	addi	s4,s4,1518 # 80008568 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002f82:	2b893783          	ld	a5,696(s2)
    80002f86:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f88:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f8c:	85d2                	mv	a1,s4
    80002f8e:	01048513          	addi	a0,s1,16
    80002f92:	00001097          	auipc	ra,0x1
    80002f96:	4c4080e7          	jalr	1220(ra) # 80004456 <initsleeplock>
    bcache.head.next->prev = b;
    80002f9a:	2b893783          	ld	a5,696(s2)
    80002f9e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fa0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fa4:	45848493          	addi	s1,s1,1112
    80002fa8:	fd349de3          	bne	s1,s3,80002f82 <binit+0x54>
  }
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6942                	ld	s2,16(sp)
    80002fb4:	69a2                	ld	s3,8(sp)
    80002fb6:	6a02                	ld	s4,0(sp)
    80002fb8:	6145                	addi	sp,sp,48
    80002fba:	8082                	ret

0000000080002fbc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fbc:	7179                	addi	sp,sp,-48
    80002fbe:	f406                	sd	ra,40(sp)
    80002fc0:	f022                	sd	s0,32(sp)
    80002fc2:	ec26                	sd	s1,24(sp)
    80002fc4:	e84a                	sd	s2,16(sp)
    80002fc6:	e44e                	sd	s3,8(sp)
    80002fc8:	1800                	addi	s0,sp,48
    80002fca:	892a                	mv	s2,a0
    80002fcc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	c0a50513          	addi	a0,a0,-1014 # 80016bd8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c00080e7          	jalr	-1024(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fde:	0001c497          	auipc	s1,0x1c
    80002fe2:	eb24b483          	ld	s1,-334(s1) # 8001ee90 <bcache+0x82b8>
    80002fe6:	0001c797          	auipc	a5,0x1c
    80002fea:	e5a78793          	addi	a5,a5,-422 # 8001ee40 <bcache+0x8268>
    80002fee:	02f48f63          	beq	s1,a5,8000302c <bread+0x70>
    80002ff2:	873e                	mv	a4,a5
    80002ff4:	a021                	j	80002ffc <bread+0x40>
    80002ff6:	68a4                	ld	s1,80(s1)
    80002ff8:	02e48a63          	beq	s1,a4,8000302c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ffc:	449c                	lw	a5,8(s1)
    80002ffe:	ff279ce3          	bne	a5,s2,80002ff6 <bread+0x3a>
    80003002:	44dc                	lw	a5,12(s1)
    80003004:	ff3799e3          	bne	a5,s3,80002ff6 <bread+0x3a>
      b->refcnt++;
    80003008:	40bc                	lw	a5,64(s1)
    8000300a:	2785                	addiw	a5,a5,1
    8000300c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	bca50513          	addi	a0,a0,-1078 # 80016bd8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	c74080e7          	jalr	-908(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000301e:	01048513          	addi	a0,s1,16
    80003022:	00001097          	auipc	ra,0x1
    80003026:	46e080e7          	jalr	1134(ra) # 80004490 <acquiresleep>
      return b;
    8000302a:	a8b9                	j	80003088 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302c:	0001c497          	auipc	s1,0x1c
    80003030:	e5c4b483          	ld	s1,-420(s1) # 8001ee88 <bcache+0x82b0>
    80003034:	0001c797          	auipc	a5,0x1c
    80003038:	e0c78793          	addi	a5,a5,-500 # 8001ee40 <bcache+0x8268>
    8000303c:	00f48863          	beq	s1,a5,8000304c <bread+0x90>
    80003040:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003042:	40bc                	lw	a5,64(s1)
    80003044:	cf81                	beqz	a5,8000305c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003046:	64a4                	ld	s1,72(s1)
    80003048:	fee49de3          	bne	s1,a4,80003042 <bread+0x86>
  panic("bget: no buffers");
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	52450513          	addi	a0,a0,1316 # 80008570 <syscalls+0xe0>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>
      b->dev = dev;
    8000305c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003060:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003064:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003068:	4785                	li	a5,1
    8000306a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	b6c50513          	addi	a0,a0,-1172 # 80016bd8 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c16080e7          	jalr	-1002(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000307c:	01048513          	addi	a0,s1,16
    80003080:	00001097          	auipc	ra,0x1
    80003084:	410080e7          	jalr	1040(ra) # 80004490 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003088:	409c                	lw	a5,0(s1)
    8000308a:	cb89                	beqz	a5,8000309c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000308c:	8526                	mv	a0,s1
    8000308e:	70a2                	ld	ra,40(sp)
    80003090:	7402                	ld	s0,32(sp)
    80003092:	64e2                	ld	s1,24(sp)
    80003094:	6942                	ld	s2,16(sp)
    80003096:	69a2                	ld	s3,8(sp)
    80003098:	6145                	addi	sp,sp,48
    8000309a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000309c:	4581                	li	a1,0
    8000309e:	8526                	mv	a0,s1
    800030a0:	00003097          	auipc	ra,0x3
    800030a4:	fd4080e7          	jalr	-44(ra) # 80006074 <virtio_disk_rw>
    b->valid = 1;
    800030a8:	4785                	li	a5,1
    800030aa:	c09c                	sw	a5,0(s1)
  return b;
    800030ac:	b7c5                	j	8000308c <bread+0xd0>

00000000800030ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	1000                	addi	s0,sp,32
    800030b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ba:	0541                	addi	a0,a0,16
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	46e080e7          	jalr	1134(ra) # 8000452a <holdingsleep>
    800030c4:	cd01                	beqz	a0,800030dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c6:	4585                	li	a1,1
    800030c8:	8526                	mv	a0,s1
    800030ca:	00003097          	auipc	ra,0x3
    800030ce:	faa080e7          	jalr	-86(ra) # 80006074 <virtio_disk_rw>
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("bwrite");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	4ac50513          	addi	a0,a0,1196 # 80008588 <syscalls+0xf8>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	45a080e7          	jalr	1114(ra) # 8000053e <panic>

00000000800030ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	e04a                	sd	s2,0(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030fa:	01050913          	addi	s2,a0,16
    800030fe:	854a                	mv	a0,s2
    80003100:	00001097          	auipc	ra,0x1
    80003104:	42a080e7          	jalr	1066(ra) # 8000452a <holdingsleep>
    80003108:	c92d                	beqz	a0,8000317a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000310a:	854a                	mv	a0,s2
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	3da080e7          	jalr	986(ra) # 800044e6 <releasesleep>

  acquire(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	ac450513          	addi	a0,a0,-1340 # 80016bd8 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	aba080e7          	jalr	-1350(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	37fd                	addiw	a5,a5,-1
    80003128:	0007871b          	sext.w	a4,a5
    8000312c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000312e:	eb05                	bnez	a4,8000315e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003130:	68bc                	ld	a5,80(s1)
    80003132:	64b8                	ld	a4,72(s1)
    80003134:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003136:	64bc                	ld	a5,72(s1)
    80003138:	68b8                	ld	a4,80(s1)
    8000313a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000313c:	0001c797          	auipc	a5,0x1c
    80003140:	a9c78793          	addi	a5,a5,-1380 # 8001ebd8 <bcache+0x8000>
    80003144:	2b87b703          	ld	a4,696(a5)
    80003148:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000314a:	0001c717          	auipc	a4,0x1c
    8000314e:	cf670713          	addi	a4,a4,-778 # 8001ee40 <bcache+0x8268>
    80003152:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003154:	2b87b703          	ld	a4,696(a5)
    80003158:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000315a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000315e:	00014517          	auipc	a0,0x14
    80003162:	a7a50513          	addi	a0,a0,-1414 # 80016bd8 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6902                	ld	s2,0(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret
    panic("brelse");
    8000317a:	00005517          	auipc	a0,0x5
    8000317e:	41650513          	addi	a0,a0,1046 # 80008590 <syscalls+0x100>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>

000000008000318a <bpin>:

void
bpin(struct buf *b) {
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	a4250513          	addi	a0,a0,-1470 # 80016bd8 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a38080e7          	jalr	-1480(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	a2c50513          	addi	a0,a0,-1492 # 80016bd8 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	ad6080e7          	jalr	-1322(ra) # 80000c8a <release>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <bunpin>:

void
bunpin(struct buf *b) {
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d2:	00014517          	auipc	a0,0x14
    800031d6:	a0650513          	addi	a0,a0,-1530 # 80016bd8 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	9fc080e7          	jalr	-1540(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031e2:	40bc                	lw	a5,64(s1)
    800031e4:	37fd                	addiw	a5,a5,-1
    800031e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e8:	00014517          	auipc	a0,0x14
    800031ec:	9f050513          	addi	a0,a0,-1552 # 80016bd8 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	a9a080e7          	jalr	-1382(ra) # 80000c8a <release>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	e04a                	sd	s2,0(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003210:	00d5d59b          	srliw	a1,a1,0xd
    80003214:	0001c797          	auipc	a5,0x1c
    80003218:	0a07a783          	lw	a5,160(a5) # 8001f2b4 <sb+0x1c>
    8000321c:	9dbd                	addw	a1,a1,a5
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	d9e080e7          	jalr	-610(ra) # 80002fbc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003226:	0074f713          	andi	a4,s1,7
    8000322a:	4785                	li	a5,1
    8000322c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003230:	14ce                	slli	s1,s1,0x33
    80003232:	90d9                	srli	s1,s1,0x36
    80003234:	00950733          	add	a4,a0,s1
    80003238:	05874703          	lbu	a4,88(a4)
    8000323c:	00e7f6b3          	and	a3,a5,a4
    80003240:	c69d                	beqz	a3,8000326e <bfree+0x6c>
    80003242:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003244:	94aa                	add	s1,s1,a0
    80003246:	fff7c793          	not	a5,a5
    8000324a:	8ff9                	and	a5,a5,a4
    8000324c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003250:	00001097          	auipc	ra,0x1
    80003254:	120080e7          	jalr	288(ra) # 80004370 <log_write>
  brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	e92080e7          	jalr	-366(ra) # 800030ec <brelse>
}
    80003262:	60e2                	ld	ra,24(sp)
    80003264:	6442                	ld	s0,16(sp)
    80003266:	64a2                	ld	s1,8(sp)
    80003268:	6902                	ld	s2,0(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret
    panic("freeing free block");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	32a50513          	addi	a0,a0,810 # 80008598 <syscalls+0x108>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000327e <balloc>:
{
    8000327e:	711d                	addi	sp,sp,-96
    80003280:	ec86                	sd	ra,88(sp)
    80003282:	e8a2                	sd	s0,80(sp)
    80003284:	e4a6                	sd	s1,72(sp)
    80003286:	e0ca                	sd	s2,64(sp)
    80003288:	fc4e                	sd	s3,56(sp)
    8000328a:	f852                	sd	s4,48(sp)
    8000328c:	f456                	sd	s5,40(sp)
    8000328e:	f05a                	sd	s6,32(sp)
    80003290:	ec5e                	sd	s7,24(sp)
    80003292:	e862                	sd	s8,16(sp)
    80003294:	e466                	sd	s9,8(sp)
    80003296:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003298:	0001c797          	auipc	a5,0x1c
    8000329c:	0047a783          	lw	a5,4(a5) # 8001f29c <sb+0x4>
    800032a0:	10078163          	beqz	a5,800033a2 <balloc+0x124>
    800032a4:	8baa                	mv	s7,a0
    800032a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a8:	0001cb17          	auipc	s6,0x1c
    800032ac:	ff0b0b13          	addi	s6,s6,-16 # 8001f298 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b6:	6c89                	lui	s9,0x2
    800032b8:	a061                	j	80003340 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032ba:	974a                	add	a4,a4,s2
    800032bc:	8fd5                	or	a5,a5,a3
    800032be:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00001097          	auipc	ra,0x1
    800032c8:	0ac080e7          	jalr	172(ra) # 80004370 <log_write>
        brelse(bp);
    800032cc:	854a                	mv	a0,s2
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	e1e080e7          	jalr	-482(ra) # 800030ec <brelse>
  bp = bread(dev, bno);
    800032d6:	85a6                	mv	a1,s1
    800032d8:	855e                	mv	a0,s7
    800032da:	00000097          	auipc	ra,0x0
    800032de:	ce2080e7          	jalr	-798(ra) # 80002fbc <bread>
    800032e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032e4:	40000613          	li	a2,1024
    800032e8:	4581                	li	a1,0
    800032ea:	05850513          	addi	a0,a0,88
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	9e4080e7          	jalr	-1564(ra) # 80000cd2 <memset>
  log_write(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	078080e7          	jalr	120(ra) # 80004370 <log_write>
  brelse(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00000097          	auipc	ra,0x0
    80003306:	dea080e7          	jalr	-534(ra) # 800030ec <brelse>
}
    8000330a:	8526                	mv	a0,s1
    8000330c:	60e6                	ld	ra,88(sp)
    8000330e:	6446                	ld	s0,80(sp)
    80003310:	64a6                	ld	s1,72(sp)
    80003312:	6906                	ld	s2,64(sp)
    80003314:	79e2                	ld	s3,56(sp)
    80003316:	7a42                	ld	s4,48(sp)
    80003318:	7aa2                	ld	s5,40(sp)
    8000331a:	7b02                	ld	s6,32(sp)
    8000331c:	6be2                	ld	s7,24(sp)
    8000331e:	6c42                	ld	s8,16(sp)
    80003320:	6ca2                	ld	s9,8(sp)
    80003322:	6125                	addi	sp,sp,96
    80003324:	8082                	ret
    brelse(bp);
    80003326:	854a                	mv	a0,s2
    80003328:	00000097          	auipc	ra,0x0
    8000332c:	dc4080e7          	jalr	-572(ra) # 800030ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003330:	015c87bb          	addw	a5,s9,s5
    80003334:	00078a9b          	sext.w	s5,a5
    80003338:	004b2703          	lw	a4,4(s6)
    8000333c:	06eaf363          	bgeu	s5,a4,800033a2 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003340:	41fad79b          	sraiw	a5,s5,0x1f
    80003344:	0137d79b          	srliw	a5,a5,0x13
    80003348:	015787bb          	addw	a5,a5,s5
    8000334c:	40d7d79b          	sraiw	a5,a5,0xd
    80003350:	01cb2583          	lw	a1,28(s6)
    80003354:	9dbd                	addw	a1,a1,a5
    80003356:	855e                	mv	a0,s7
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	c64080e7          	jalr	-924(ra) # 80002fbc <bread>
    80003360:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003362:	004b2503          	lw	a0,4(s6)
    80003366:	000a849b          	sext.w	s1,s5
    8000336a:	8662                	mv	a2,s8
    8000336c:	faa4fde3          	bgeu	s1,a0,80003326 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003370:	41f6579b          	sraiw	a5,a2,0x1f
    80003374:	01d7d69b          	srliw	a3,a5,0x1d
    80003378:	00c6873b          	addw	a4,a3,a2
    8000337c:	00777793          	andi	a5,a4,7
    80003380:	9f95                	subw	a5,a5,a3
    80003382:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003386:	4037571b          	sraiw	a4,a4,0x3
    8000338a:	00e906b3          	add	a3,s2,a4
    8000338e:	0586c683          	lbu	a3,88(a3)
    80003392:	00d7f5b3          	and	a1,a5,a3
    80003396:	d195                	beqz	a1,800032ba <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003398:	2605                	addiw	a2,a2,1
    8000339a:	2485                	addiw	s1,s1,1
    8000339c:	fd4618e3          	bne	a2,s4,8000336c <balloc+0xee>
    800033a0:	b759                	j	80003326 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	20e50513          	addi	a0,a0,526 # 800085b0 <syscalls+0x120>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	1de080e7          	jalr	478(ra) # 80000588 <printf>
  return 0;
    800033b2:	4481                	li	s1,0
    800033b4:	bf99                	j	8000330a <balloc+0x8c>

00000000800033b6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033b6:	7179                	addi	sp,sp,-48
    800033b8:	f406                	sd	ra,40(sp)
    800033ba:	f022                	sd	s0,32(sp)
    800033bc:	ec26                	sd	s1,24(sp)
    800033be:	e84a                	sd	s2,16(sp)
    800033c0:	e44e                	sd	s3,8(sp)
    800033c2:	e052                	sd	s4,0(sp)
    800033c4:	1800                	addi	s0,sp,48
    800033c6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c8:	47ad                	li	a5,11
    800033ca:	02b7e763          	bltu	a5,a1,800033f8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033ce:	02059493          	slli	s1,a1,0x20
    800033d2:	9081                	srli	s1,s1,0x20
    800033d4:	048a                	slli	s1,s1,0x2
    800033d6:	94aa                	add	s1,s1,a0
    800033d8:	0504a903          	lw	s2,80(s1)
    800033dc:	06091e63          	bnez	s2,80003458 <bmap+0xa2>
      addr = balloc(ip->dev);
    800033e0:	4108                	lw	a0,0(a0)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	e9c080e7          	jalr	-356(ra) # 8000327e <balloc>
    800033ea:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ee:	06090563          	beqz	s2,80003458 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033f2:	0524a823          	sw	s2,80(s1)
    800033f6:	a08d                	j	80003458 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033f8:	ff45849b          	addiw	s1,a1,-12
    800033fc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003400:	0ff00793          	li	a5,255
    80003404:	08e7e563          	bltu	a5,a4,8000348e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003408:	08052903          	lw	s2,128(a0)
    8000340c:	00091d63          	bnez	s2,80003426 <bmap+0x70>
      addr = balloc(ip->dev);
    80003410:	4108                	lw	a0,0(a0)
    80003412:	00000097          	auipc	ra,0x0
    80003416:	e6c080e7          	jalr	-404(ra) # 8000327e <balloc>
    8000341a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000341e:	02090d63          	beqz	s2,80003458 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003422:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003426:	85ca                	mv	a1,s2
    80003428:	0009a503          	lw	a0,0(s3)
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	b90080e7          	jalr	-1136(ra) # 80002fbc <bread>
    80003434:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003436:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000343a:	02049593          	slli	a1,s1,0x20
    8000343e:	9181                	srli	a1,a1,0x20
    80003440:	058a                	slli	a1,a1,0x2
    80003442:	00b784b3          	add	s1,a5,a1
    80003446:	0004a903          	lw	s2,0(s1)
    8000344a:	02090063          	beqz	s2,8000346a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000344e:	8552                	mv	a0,s4
    80003450:	00000097          	auipc	ra,0x0
    80003454:	c9c080e7          	jalr	-868(ra) # 800030ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003458:	854a                	mv	a0,s2
    8000345a:	70a2                	ld	ra,40(sp)
    8000345c:	7402                	ld	s0,32(sp)
    8000345e:	64e2                	ld	s1,24(sp)
    80003460:	6942                	ld	s2,16(sp)
    80003462:	69a2                	ld	s3,8(sp)
    80003464:	6a02                	ld	s4,0(sp)
    80003466:	6145                	addi	sp,sp,48
    80003468:	8082                	ret
      addr = balloc(ip->dev);
    8000346a:	0009a503          	lw	a0,0(s3)
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	e10080e7          	jalr	-496(ra) # 8000327e <balloc>
    80003476:	0005091b          	sext.w	s2,a0
      if(addr){
    8000347a:	fc090ae3          	beqz	s2,8000344e <bmap+0x98>
        a[bn] = addr;
    8000347e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003482:	8552                	mv	a0,s4
    80003484:	00001097          	auipc	ra,0x1
    80003488:	eec080e7          	jalr	-276(ra) # 80004370 <log_write>
    8000348c:	b7c9                	j	8000344e <bmap+0x98>
  panic("bmap: out of range");
    8000348e:	00005517          	auipc	a0,0x5
    80003492:	13a50513          	addi	a0,a0,314 # 800085c8 <syscalls+0x138>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	0a8080e7          	jalr	168(ra) # 8000053e <panic>

000000008000349e <iget>:
{
    8000349e:	7179                	addi	sp,sp,-48
    800034a0:	f406                	sd	ra,40(sp)
    800034a2:	f022                	sd	s0,32(sp)
    800034a4:	ec26                	sd	s1,24(sp)
    800034a6:	e84a                	sd	s2,16(sp)
    800034a8:	e44e                	sd	s3,8(sp)
    800034aa:	e052                	sd	s4,0(sp)
    800034ac:	1800                	addi	s0,sp,48
    800034ae:	89aa                	mv	s3,a0
    800034b0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034b2:	0001c517          	auipc	a0,0x1c
    800034b6:	e0650513          	addi	a0,a0,-506 # 8001f2b8 <itable>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	71c080e7          	jalr	1820(ra) # 80000bd6 <acquire>
  empty = 0;
    800034c2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034c4:	0001c497          	auipc	s1,0x1c
    800034c8:	e0c48493          	addi	s1,s1,-500 # 8001f2d0 <itable+0x18>
    800034cc:	0001e697          	auipc	a3,0x1e
    800034d0:	89468693          	addi	a3,a3,-1900 # 80020d60 <log>
    800034d4:	a039                	j	800034e2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d6:	02090b63          	beqz	s2,8000350c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034da:	08848493          	addi	s1,s1,136
    800034de:	02d48a63          	beq	s1,a3,80003512 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034e2:	449c                	lw	a5,8(s1)
    800034e4:	fef059e3          	blez	a5,800034d6 <iget+0x38>
    800034e8:	4098                	lw	a4,0(s1)
    800034ea:	ff3716e3          	bne	a4,s3,800034d6 <iget+0x38>
    800034ee:	40d8                	lw	a4,4(s1)
    800034f0:	ff4713e3          	bne	a4,s4,800034d6 <iget+0x38>
      ip->ref++;
    800034f4:	2785                	addiw	a5,a5,1
    800034f6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034f8:	0001c517          	auipc	a0,0x1c
    800034fc:	dc050513          	addi	a0,a0,-576 # 8001f2b8 <itable>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	78a080e7          	jalr	1930(ra) # 80000c8a <release>
      return ip;
    80003508:	8926                	mv	s2,s1
    8000350a:	a03d                	j	80003538 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000350c:	f7f9                	bnez	a5,800034da <iget+0x3c>
    8000350e:	8926                	mv	s2,s1
    80003510:	b7e9                	j	800034da <iget+0x3c>
  if(empty == 0)
    80003512:	02090c63          	beqz	s2,8000354a <iget+0xac>
  ip->dev = dev;
    80003516:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000351a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000351e:	4785                	li	a5,1
    80003520:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003524:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003528:	0001c517          	auipc	a0,0x1c
    8000352c:	d9050513          	addi	a0,a0,-624 # 8001f2b8 <itable>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	75a080e7          	jalr	1882(ra) # 80000c8a <release>
}
    80003538:	854a                	mv	a0,s2
    8000353a:	70a2                	ld	ra,40(sp)
    8000353c:	7402                	ld	s0,32(sp)
    8000353e:	64e2                	ld	s1,24(sp)
    80003540:	6942                	ld	s2,16(sp)
    80003542:	69a2                	ld	s3,8(sp)
    80003544:	6a02                	ld	s4,0(sp)
    80003546:	6145                	addi	sp,sp,48
    80003548:	8082                	ret
    panic("iget: no inodes");
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	09650513          	addi	a0,a0,150 # 800085e0 <syscalls+0x150>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	fec080e7          	jalr	-20(ra) # 8000053e <panic>

000000008000355a <fsinit>:
fsinit(int dev) {
    8000355a:	7179                	addi	sp,sp,-48
    8000355c:	f406                	sd	ra,40(sp)
    8000355e:	f022                	sd	s0,32(sp)
    80003560:	ec26                	sd	s1,24(sp)
    80003562:	e84a                	sd	s2,16(sp)
    80003564:	e44e                	sd	s3,8(sp)
    80003566:	1800                	addi	s0,sp,48
    80003568:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000356a:	4585                	li	a1,1
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	a50080e7          	jalr	-1456(ra) # 80002fbc <bread>
    80003574:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003576:	0001c997          	auipc	s3,0x1c
    8000357a:	d2298993          	addi	s3,s3,-734 # 8001f298 <sb>
    8000357e:	02000613          	li	a2,32
    80003582:	05850593          	addi	a1,a0,88
    80003586:	854e                	mv	a0,s3
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	7a6080e7          	jalr	1958(ra) # 80000d2e <memmove>
  brelse(bp);
    80003590:	8526                	mv	a0,s1
    80003592:	00000097          	auipc	ra,0x0
    80003596:	b5a080e7          	jalr	-1190(ra) # 800030ec <brelse>
  if(sb.magic != FSMAGIC)
    8000359a:	0009a703          	lw	a4,0(s3)
    8000359e:	102037b7          	lui	a5,0x10203
    800035a2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035a6:	02f71263          	bne	a4,a5,800035ca <fsinit+0x70>
  initlog(dev, &sb);
    800035aa:	0001c597          	auipc	a1,0x1c
    800035ae:	cee58593          	addi	a1,a1,-786 # 8001f298 <sb>
    800035b2:	854a                	mv	a0,s2
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	b40080e7          	jalr	-1216(ra) # 800040f4 <initlog>
}
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret
    panic("invalid file system");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	02650513          	addi	a0,a0,38 # 800085f0 <syscalls+0x160>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>

00000000800035da <iinit>:
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e8:	00005597          	auipc	a1,0x5
    800035ec:	02058593          	addi	a1,a1,32 # 80008608 <syscalls+0x178>
    800035f0:	0001c517          	auipc	a0,0x1c
    800035f4:	cc850513          	addi	a0,a0,-824 # 8001f2b8 <itable>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	54e080e7          	jalr	1358(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003600:	0001c497          	auipc	s1,0x1c
    80003604:	ce048493          	addi	s1,s1,-800 # 8001f2e0 <itable+0x28>
    80003608:	0001d997          	auipc	s3,0x1d
    8000360c:	76898993          	addi	s3,s3,1896 # 80020d70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003610:	00005917          	auipc	s2,0x5
    80003614:	00090913          	mv	s2,s2
    80003618:	85ca                	mv	a1,s2
    8000361a:	8526                	mv	a0,s1
    8000361c:	00001097          	auipc	ra,0x1
    80003620:	e3a080e7          	jalr	-454(ra) # 80004456 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003624:	08848493          	addi	s1,s1,136
    80003628:	ff3498e3          	bne	s1,s3,80003618 <iinit+0x3e>
}
    8000362c:	70a2                	ld	ra,40(sp)
    8000362e:	7402                	ld	s0,32(sp)
    80003630:	64e2                	ld	s1,24(sp)
    80003632:	6942                	ld	s2,16(sp)
    80003634:	69a2                	ld	s3,8(sp)
    80003636:	6145                	addi	sp,sp,48
    80003638:	8082                	ret

000000008000363a <ialloc>:
{
    8000363a:	715d                	addi	sp,sp,-80
    8000363c:	e486                	sd	ra,72(sp)
    8000363e:	e0a2                	sd	s0,64(sp)
    80003640:	fc26                	sd	s1,56(sp)
    80003642:	f84a                	sd	s2,48(sp)
    80003644:	f44e                	sd	s3,40(sp)
    80003646:	f052                	sd	s4,32(sp)
    80003648:	ec56                	sd	s5,24(sp)
    8000364a:	e85a                	sd	s6,16(sp)
    8000364c:	e45e                	sd	s7,8(sp)
    8000364e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003650:	0001c717          	auipc	a4,0x1c
    80003654:	c5472703          	lw	a4,-940(a4) # 8001f2a4 <sb+0xc>
    80003658:	4785                	li	a5,1
    8000365a:	04e7fa63          	bgeu	a5,a4,800036ae <ialloc+0x74>
    8000365e:	8aaa                	mv	s5,a0
    80003660:	8bae                	mv	s7,a1
    80003662:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003664:	0001ca17          	auipc	s4,0x1c
    80003668:	c34a0a13          	addi	s4,s4,-972 # 8001f298 <sb>
    8000366c:	00048b1b          	sext.w	s6,s1
    80003670:	0044d793          	srli	a5,s1,0x4
    80003674:	018a2583          	lw	a1,24(s4)
    80003678:	9dbd                	addw	a1,a1,a5
    8000367a:	8556                	mv	a0,s5
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	940080e7          	jalr	-1728(ra) # 80002fbc <bread>
    80003684:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003686:	05850993          	addi	s3,a0,88
    8000368a:	00f4f793          	andi	a5,s1,15
    8000368e:	079a                	slli	a5,a5,0x6
    80003690:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003692:	00099783          	lh	a5,0(s3)
    80003696:	c3a1                	beqz	a5,800036d6 <ialloc+0x9c>
    brelse(bp);
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	a54080e7          	jalr	-1452(ra) # 800030ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a0:	0485                	addi	s1,s1,1
    800036a2:	00ca2703          	lw	a4,12(s4)
    800036a6:	0004879b          	sext.w	a5,s1
    800036aa:	fce7e1e3          	bltu	a5,a4,8000366c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	f6a50513          	addi	a0,a0,-150 # 80008618 <syscalls+0x188>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	ed2080e7          	jalr	-302(ra) # 80000588 <printf>
  return 0;
    800036be:	4501                	li	a0,0
}
    800036c0:	60a6                	ld	ra,72(sp)
    800036c2:	6406                	ld	s0,64(sp)
    800036c4:	74e2                	ld	s1,56(sp)
    800036c6:	7942                	ld	s2,48(sp)
    800036c8:	79a2                	ld	s3,40(sp)
    800036ca:	7a02                	ld	s4,32(sp)
    800036cc:	6ae2                	ld	s5,24(sp)
    800036ce:	6b42                	ld	s6,16(sp)
    800036d0:	6ba2                	ld	s7,8(sp)
    800036d2:	6161                	addi	sp,sp,80
    800036d4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036d6:	04000613          	li	a2,64
    800036da:	4581                	li	a1,0
    800036dc:	854e                	mv	a0,s3
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	5f4080e7          	jalr	1524(ra) # 80000cd2 <memset>
      dip->type = type;
    800036e6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ea:	854a                	mv	a0,s2
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	c84080e7          	jalr	-892(ra) # 80004370 <log_write>
      brelse(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	9f6080e7          	jalr	-1546(ra) # 800030ec <brelse>
      return iget(dev, inum);
    800036fe:	85da                	mv	a1,s6
    80003700:	8556                	mv	a0,s5
    80003702:	00000097          	auipc	ra,0x0
    80003706:	d9c080e7          	jalr	-612(ra) # 8000349e <iget>
    8000370a:	bf5d                	j	800036c0 <ialloc+0x86>

000000008000370c <iupdate>:
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	e04a                	sd	s2,0(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000371a:	415c                	lw	a5,4(a0)
    8000371c:	0047d79b          	srliw	a5,a5,0x4
    80003720:	0001c597          	auipc	a1,0x1c
    80003724:	b905a583          	lw	a1,-1136(a1) # 8001f2b0 <sb+0x18>
    80003728:	9dbd                	addw	a1,a1,a5
    8000372a:	4108                	lw	a0,0(a0)
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	890080e7          	jalr	-1904(ra) # 80002fbc <bread>
    80003734:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003736:	05850793          	addi	a5,a0,88
    8000373a:	40c8                	lw	a0,4(s1)
    8000373c:	893d                	andi	a0,a0,15
    8000373e:	051a                	slli	a0,a0,0x6
    80003740:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003742:	04449703          	lh	a4,68(s1)
    80003746:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000374a:	04649703          	lh	a4,70(s1)
    8000374e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003752:	04849703          	lh	a4,72(s1)
    80003756:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000375a:	04a49703          	lh	a4,74(s1)
    8000375e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003762:	44f8                	lw	a4,76(s1)
    80003764:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003766:	03400613          	li	a2,52
    8000376a:	05048593          	addi	a1,s1,80
    8000376e:	0531                	addi	a0,a0,12
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	5be080e7          	jalr	1470(ra) # 80000d2e <memmove>
  log_write(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	bf6080e7          	jalr	-1034(ra) # 80004370 <log_write>
  brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	968080e7          	jalr	-1688(ra) # 800030ec <brelse>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret

0000000080003798 <idup>:
{
    80003798:	1101                	addi	sp,sp,-32
    8000379a:	ec06                	sd	ra,24(sp)
    8000379c:	e822                	sd	s0,16(sp)
    8000379e:	e426                	sd	s1,8(sp)
    800037a0:	1000                	addi	s0,sp,32
    800037a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037a4:	0001c517          	auipc	a0,0x1c
    800037a8:	b1450513          	addi	a0,a0,-1260 # 8001f2b8 <itable>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	42a080e7          	jalr	1066(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037b4:	449c                	lw	a5,8(s1)
    800037b6:	2785                	addiw	a5,a5,1
    800037b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037ba:	0001c517          	auipc	a0,0x1c
    800037be:	afe50513          	addi	a0,a0,-1282 # 8001f2b8 <itable>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
}
    800037ca:	8526                	mv	a0,s1
    800037cc:	60e2                	ld	ra,24(sp)
    800037ce:	6442                	ld	s0,16(sp)
    800037d0:	64a2                	ld	s1,8(sp)
    800037d2:	6105                	addi	sp,sp,32
    800037d4:	8082                	ret

00000000800037d6 <ilock>:
{
    800037d6:	1101                	addi	sp,sp,-32
    800037d8:	ec06                	sd	ra,24(sp)
    800037da:	e822                	sd	s0,16(sp)
    800037dc:	e426                	sd	s1,8(sp)
    800037de:	e04a                	sd	s2,0(sp)
    800037e0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037e2:	c115                	beqz	a0,80003806 <ilock+0x30>
    800037e4:	84aa                	mv	s1,a0
    800037e6:	451c                	lw	a5,8(a0)
    800037e8:	00f05f63          	blez	a5,80003806 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ec:	0541                	addi	a0,a0,16
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	ca2080e7          	jalr	-862(ra) # 80004490 <acquiresleep>
  if(ip->valid == 0){
    800037f6:	40bc                	lw	a5,64(s1)
    800037f8:	cf99                	beqz	a5,80003816 <ilock+0x40>
}
    800037fa:	60e2                	ld	ra,24(sp)
    800037fc:	6442                	ld	s0,16(sp)
    800037fe:	64a2                	ld	s1,8(sp)
    80003800:	6902                	ld	s2,0(sp)
    80003802:	6105                	addi	sp,sp,32
    80003804:	8082                	ret
    panic("ilock");
    80003806:	00005517          	auipc	a0,0x5
    8000380a:	e2a50513          	addi	a0,a0,-470 # 80008630 <syscalls+0x1a0>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003816:	40dc                	lw	a5,4(s1)
    80003818:	0047d79b          	srliw	a5,a5,0x4
    8000381c:	0001c597          	auipc	a1,0x1c
    80003820:	a945a583          	lw	a1,-1388(a1) # 8001f2b0 <sb+0x18>
    80003824:	9dbd                	addw	a1,a1,a5
    80003826:	4088                	lw	a0,0(s1)
    80003828:	fffff097          	auipc	ra,0xfffff
    8000382c:	794080e7          	jalr	1940(ra) # 80002fbc <bread>
    80003830:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003832:	05850593          	addi	a1,a0,88
    80003836:	40dc                	lw	a5,4(s1)
    80003838:	8bbd                	andi	a5,a5,15
    8000383a:	079a                	slli	a5,a5,0x6
    8000383c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000383e:	00059783          	lh	a5,0(a1)
    80003842:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003846:	00259783          	lh	a5,2(a1)
    8000384a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000384e:	00459783          	lh	a5,4(a1)
    80003852:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003856:	00659783          	lh	a5,6(a1)
    8000385a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000385e:	459c                	lw	a5,8(a1)
    80003860:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003862:	03400613          	li	a2,52
    80003866:	05b1                	addi	a1,a1,12
    80003868:	05048513          	addi	a0,s1,80
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	4c2080e7          	jalr	1218(ra) # 80000d2e <memmove>
    brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	876080e7          	jalr	-1930(ra) # 800030ec <brelse>
    ip->valid = 1;
    8000387e:	4785                	li	a5,1
    80003880:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003882:	04449783          	lh	a5,68(s1)
    80003886:	fbb5                	bnez	a5,800037fa <ilock+0x24>
      panic("ilock: no type");
    80003888:	00005517          	auipc	a0,0x5
    8000388c:	db050513          	addi	a0,a0,-592 # 80008638 <syscalls+0x1a8>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>

0000000080003898 <iunlock>:
{
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	e04a                	sd	s2,0(sp)
    800038a2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038a4:	c905                	beqz	a0,800038d4 <iunlock+0x3c>
    800038a6:	84aa                	mv	s1,a0
    800038a8:	01050913          	addi	s2,a0,16
    800038ac:	854a                	mv	a0,s2
    800038ae:	00001097          	auipc	ra,0x1
    800038b2:	c7c080e7          	jalr	-900(ra) # 8000452a <holdingsleep>
    800038b6:	cd19                	beqz	a0,800038d4 <iunlock+0x3c>
    800038b8:	449c                	lw	a5,8(s1)
    800038ba:	00f05d63          	blez	a5,800038d4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038be:	854a                	mv	a0,s2
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	c26080e7          	jalr	-986(ra) # 800044e6 <releasesleep>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6902                	ld	s2,0(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret
    panic("iunlock");
    800038d4:	00005517          	auipc	a0,0x5
    800038d8:	d7450513          	addi	a0,a0,-652 # 80008648 <syscalls+0x1b8>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>

00000000800038e4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038e4:	7179                	addi	sp,sp,-48
    800038e6:	f406                	sd	ra,40(sp)
    800038e8:	f022                	sd	s0,32(sp)
    800038ea:	ec26                	sd	s1,24(sp)
    800038ec:	e84a                	sd	s2,16(sp)
    800038ee:	e44e                	sd	s3,8(sp)
    800038f0:	e052                	sd	s4,0(sp)
    800038f2:	1800                	addi	s0,sp,48
    800038f4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038f6:	05050493          	addi	s1,a0,80
    800038fa:	08050913          	addi	s2,a0,128
    800038fe:	a021                	j	80003906 <itrunc+0x22>
    80003900:	0491                	addi	s1,s1,4
    80003902:	01248d63          	beq	s1,s2,8000391c <itrunc+0x38>
    if(ip->addrs[i]){
    80003906:	408c                	lw	a1,0(s1)
    80003908:	dde5                	beqz	a1,80003900 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000390a:	0009a503          	lw	a0,0(s3)
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	8f4080e7          	jalr	-1804(ra) # 80003202 <bfree>
      ip->addrs[i] = 0;
    80003916:	0004a023          	sw	zero,0(s1)
    8000391a:	b7dd                	j	80003900 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000391c:	0809a583          	lw	a1,128(s3)
    80003920:	e185                	bnez	a1,80003940 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003922:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003926:	854e                	mv	a0,s3
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	de4080e7          	jalr	-540(ra) # 8000370c <iupdate>
}
    80003930:	70a2                	ld	ra,40(sp)
    80003932:	7402                	ld	s0,32(sp)
    80003934:	64e2                	ld	s1,24(sp)
    80003936:	6942                	ld	s2,16(sp)
    80003938:	69a2                	ld	s3,8(sp)
    8000393a:	6a02                	ld	s4,0(sp)
    8000393c:	6145                	addi	sp,sp,48
    8000393e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003940:	0009a503          	lw	a0,0(s3)
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	678080e7          	jalr	1656(ra) # 80002fbc <bread>
    8000394c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000394e:	05850493          	addi	s1,a0,88
    80003952:	45850913          	addi	s2,a0,1112
    80003956:	a021                	j	8000395e <itrunc+0x7a>
    80003958:	0491                	addi	s1,s1,4
    8000395a:	01248b63          	beq	s1,s2,80003970 <itrunc+0x8c>
      if(a[j])
    8000395e:	408c                	lw	a1,0(s1)
    80003960:	dde5                	beqz	a1,80003958 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003962:	0009a503          	lw	a0,0(s3)
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	89c080e7          	jalr	-1892(ra) # 80003202 <bfree>
    8000396e:	b7ed                	j	80003958 <itrunc+0x74>
    brelse(bp);
    80003970:	8552                	mv	a0,s4
    80003972:	fffff097          	auipc	ra,0xfffff
    80003976:	77a080e7          	jalr	1914(ra) # 800030ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000397a:	0809a583          	lw	a1,128(s3)
    8000397e:	0009a503          	lw	a0,0(s3)
    80003982:	00000097          	auipc	ra,0x0
    80003986:	880080e7          	jalr	-1920(ra) # 80003202 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000398a:	0809a023          	sw	zero,128(s3)
    8000398e:	bf51                	j	80003922 <itrunc+0x3e>

0000000080003990 <iput>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	e04a                	sd	s2,0(sp)
    8000399a:	1000                	addi	s0,sp,32
    8000399c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000399e:	0001c517          	auipc	a0,0x1c
    800039a2:	91a50513          	addi	a0,a0,-1766 # 8001f2b8 <itable>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	230080e7          	jalr	560(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ae:	4498                	lw	a4,8(s1)
    800039b0:	4785                	li	a5,1
    800039b2:	02f70363          	beq	a4,a5,800039d8 <iput+0x48>
  ip->ref--;
    800039b6:	449c                	lw	a5,8(s1)
    800039b8:	37fd                	addiw	a5,a5,-1
    800039ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039bc:	0001c517          	auipc	a0,0x1c
    800039c0:	8fc50513          	addi	a0,a0,-1796 # 8001f2b8 <itable>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	2c6080e7          	jalr	710(ra) # 80000c8a <release>
}
    800039cc:	60e2                	ld	ra,24(sp)
    800039ce:	6442                	ld	s0,16(sp)
    800039d0:	64a2                	ld	s1,8(sp)
    800039d2:	6902                	ld	s2,0(sp)
    800039d4:	6105                	addi	sp,sp,32
    800039d6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d8:	40bc                	lw	a5,64(s1)
    800039da:	dff1                	beqz	a5,800039b6 <iput+0x26>
    800039dc:	04a49783          	lh	a5,74(s1)
    800039e0:	fbf9                	bnez	a5,800039b6 <iput+0x26>
    acquiresleep(&ip->lock);
    800039e2:	01048913          	addi	s2,s1,16
    800039e6:	854a                	mv	a0,s2
    800039e8:	00001097          	auipc	ra,0x1
    800039ec:	aa8080e7          	jalr	-1368(ra) # 80004490 <acquiresleep>
    release(&itable.lock);
    800039f0:	0001c517          	auipc	a0,0x1c
    800039f4:	8c850513          	addi	a0,a0,-1848 # 8001f2b8 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	292080e7          	jalr	658(ra) # 80000c8a <release>
    itrunc(ip);
    80003a00:	8526                	mv	a0,s1
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	ee2080e7          	jalr	-286(ra) # 800038e4 <itrunc>
    ip->type = 0;
    80003a0a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a0e:	8526                	mv	a0,s1
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	cfc080e7          	jalr	-772(ra) # 8000370c <iupdate>
    ip->valid = 0;
    80003a18:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a1c:	854a                	mv	a0,s2
    80003a1e:	00001097          	auipc	ra,0x1
    80003a22:	ac8080e7          	jalr	-1336(ra) # 800044e6 <releasesleep>
    acquire(&itable.lock);
    80003a26:	0001c517          	auipc	a0,0x1c
    80003a2a:	89250513          	addi	a0,a0,-1902 # 8001f2b8 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	1a8080e7          	jalr	424(ra) # 80000bd6 <acquire>
    80003a36:	b741                	j	800039b6 <iput+0x26>

0000000080003a38 <iunlockput>:
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	1000                	addi	s0,sp,32
    80003a42:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	e54080e7          	jalr	-428(ra) # 80003898 <iunlock>
  iput(ip);
    80003a4c:	8526                	mv	a0,s1
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	f42080e7          	jalr	-190(ra) # 80003990 <iput>
}
    80003a56:	60e2                	ld	ra,24(sp)
    80003a58:	6442                	ld	s0,16(sp)
    80003a5a:	64a2                	ld	s1,8(sp)
    80003a5c:	6105                	addi	sp,sp,32
    80003a5e:	8082                	ret

0000000080003a60 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a60:	1141                	addi	sp,sp,-16
    80003a62:	e422                	sd	s0,8(sp)
    80003a64:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a66:	411c                	lw	a5,0(a0)
    80003a68:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a6a:	415c                	lw	a5,4(a0)
    80003a6c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a6e:	04451783          	lh	a5,68(a0)
    80003a72:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a76:	04a51783          	lh	a5,74(a0)
    80003a7a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a7e:	04c56783          	lwu	a5,76(a0)
    80003a82:	e99c                	sd	a5,16(a1)
}
    80003a84:	6422                	ld	s0,8(sp)
    80003a86:	0141                	addi	sp,sp,16
    80003a88:	8082                	ret

0000000080003a8a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a8a:	457c                	lw	a5,76(a0)
    80003a8c:	0ed7e963          	bltu	a5,a3,80003b7e <readi+0xf4>
{
    80003a90:	7159                	addi	sp,sp,-112
    80003a92:	f486                	sd	ra,104(sp)
    80003a94:	f0a2                	sd	s0,96(sp)
    80003a96:	eca6                	sd	s1,88(sp)
    80003a98:	e8ca                	sd	s2,80(sp)
    80003a9a:	e4ce                	sd	s3,72(sp)
    80003a9c:	e0d2                	sd	s4,64(sp)
    80003a9e:	fc56                	sd	s5,56(sp)
    80003aa0:	f85a                	sd	s6,48(sp)
    80003aa2:	f45e                	sd	s7,40(sp)
    80003aa4:	f062                	sd	s8,32(sp)
    80003aa6:	ec66                	sd	s9,24(sp)
    80003aa8:	e86a                	sd	s10,16(sp)
    80003aaa:	e46e                	sd	s11,8(sp)
    80003aac:	1880                	addi	s0,sp,112
    80003aae:	8b2a                	mv	s6,a0
    80003ab0:	8bae                	mv	s7,a1
    80003ab2:	8a32                	mv	s4,a2
    80003ab4:	84b6                	mv	s1,a3
    80003ab6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ab8:	9f35                	addw	a4,a4,a3
    return 0;
    80003aba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003abc:	0ad76063          	bltu	a4,a3,80003b5c <readi+0xd2>
  if(off + n > ip->size)
    80003ac0:	00e7f463          	bgeu	a5,a4,80003ac8 <readi+0x3e>
    n = ip->size - off;
    80003ac4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac8:	0a0a8963          	beqz	s5,80003b7a <readi+0xf0>
    80003acc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ace:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ad2:	5c7d                	li	s8,-1
    80003ad4:	a82d                	j	80003b0e <readi+0x84>
    80003ad6:	020d1d93          	slli	s11,s10,0x20
    80003ada:	020ddd93          	srli	s11,s11,0x20
    80003ade:	05890793          	addi	a5,s2,88 # 80008668 <syscalls+0x1d8>
    80003ae2:	86ee                	mv	a3,s11
    80003ae4:	963e                	add	a2,a2,a5
    80003ae6:	85d2                	mv	a1,s4
    80003ae8:	855e                	mv	a0,s7
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	97e080e7          	jalr	-1666(ra) # 80002468 <either_copyout>
    80003af2:	05850d63          	beq	a0,s8,80003b4c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003af6:	854a                	mv	a0,s2
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	5f4080e7          	jalr	1524(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b00:	013d09bb          	addw	s3,s10,s3
    80003b04:	009d04bb          	addw	s1,s10,s1
    80003b08:	9a6e                	add	s4,s4,s11
    80003b0a:	0559f763          	bgeu	s3,s5,80003b58 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b0e:	00a4d59b          	srliw	a1,s1,0xa
    80003b12:	855a                	mv	a0,s6
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	8a2080e7          	jalr	-1886(ra) # 800033b6 <bmap>
    80003b1c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b20:	cd85                	beqz	a1,80003b58 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b22:	000b2503          	lw	a0,0(s6)
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	496080e7          	jalr	1174(ra) # 80002fbc <bread>
    80003b2e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b30:	3ff4f613          	andi	a2,s1,1023
    80003b34:	40cc87bb          	subw	a5,s9,a2
    80003b38:	413a873b          	subw	a4,s5,s3
    80003b3c:	8d3e                	mv	s10,a5
    80003b3e:	2781                	sext.w	a5,a5
    80003b40:	0007069b          	sext.w	a3,a4
    80003b44:	f8f6f9e3          	bgeu	a3,a5,80003ad6 <readi+0x4c>
    80003b48:	8d3a                	mv	s10,a4
    80003b4a:	b771                	j	80003ad6 <readi+0x4c>
      brelse(bp);
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	fffff097          	auipc	ra,0xfffff
    80003b52:	59e080e7          	jalr	1438(ra) # 800030ec <brelse>
      tot = -1;
    80003b56:	59fd                	li	s3,-1
  }
  return tot;
    80003b58:	0009851b          	sext.w	a0,s3
}
    80003b5c:	70a6                	ld	ra,104(sp)
    80003b5e:	7406                	ld	s0,96(sp)
    80003b60:	64e6                	ld	s1,88(sp)
    80003b62:	6946                	ld	s2,80(sp)
    80003b64:	69a6                	ld	s3,72(sp)
    80003b66:	6a06                	ld	s4,64(sp)
    80003b68:	7ae2                	ld	s5,56(sp)
    80003b6a:	7b42                	ld	s6,48(sp)
    80003b6c:	7ba2                	ld	s7,40(sp)
    80003b6e:	7c02                	ld	s8,32(sp)
    80003b70:	6ce2                	ld	s9,24(sp)
    80003b72:	6d42                	ld	s10,16(sp)
    80003b74:	6da2                	ld	s11,8(sp)
    80003b76:	6165                	addi	sp,sp,112
    80003b78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7a:	89d6                	mv	s3,s5
    80003b7c:	bff1                	j	80003b58 <readi+0xce>
    return 0;
    80003b7e:	4501                	li	a0,0
}
    80003b80:	8082                	ret

0000000080003b82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b82:	457c                	lw	a5,76(a0)
    80003b84:	10d7e863          	bltu	a5,a3,80003c94 <writei+0x112>
{
    80003b88:	7159                	addi	sp,sp,-112
    80003b8a:	f486                	sd	ra,104(sp)
    80003b8c:	f0a2                	sd	s0,96(sp)
    80003b8e:	eca6                	sd	s1,88(sp)
    80003b90:	e8ca                	sd	s2,80(sp)
    80003b92:	e4ce                	sd	s3,72(sp)
    80003b94:	e0d2                	sd	s4,64(sp)
    80003b96:	fc56                	sd	s5,56(sp)
    80003b98:	f85a                	sd	s6,48(sp)
    80003b9a:	f45e                	sd	s7,40(sp)
    80003b9c:	f062                	sd	s8,32(sp)
    80003b9e:	ec66                	sd	s9,24(sp)
    80003ba0:	e86a                	sd	s10,16(sp)
    80003ba2:	e46e                	sd	s11,8(sp)
    80003ba4:	1880                	addi	s0,sp,112
    80003ba6:	8aaa                	mv	s5,a0
    80003ba8:	8bae                	mv	s7,a1
    80003baa:	8a32                	mv	s4,a2
    80003bac:	8936                	mv	s2,a3
    80003bae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb0:	00e687bb          	addw	a5,a3,a4
    80003bb4:	0ed7e263          	bltu	a5,a3,80003c98 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bb8:	00043737          	lui	a4,0x43
    80003bbc:	0ef76063          	bltu	a4,a5,80003c9c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc0:	0c0b0863          	beqz	s6,80003c90 <writei+0x10e>
    80003bc4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bca:	5c7d                	li	s8,-1
    80003bcc:	a091                	j	80003c10 <writei+0x8e>
    80003bce:	020d1d93          	slli	s11,s10,0x20
    80003bd2:	020ddd93          	srli	s11,s11,0x20
    80003bd6:	05848793          	addi	a5,s1,88
    80003bda:	86ee                	mv	a3,s11
    80003bdc:	8652                	mv	a2,s4
    80003bde:	85de                	mv	a1,s7
    80003be0:	953e                	add	a0,a0,a5
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	8dc080e7          	jalr	-1828(ra) # 800024be <either_copyin>
    80003bea:	07850263          	beq	a0,s8,80003c4e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	780080e7          	jalr	1920(ra) # 80004370 <log_write>
    brelse(bp);
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	4f2080e7          	jalr	1266(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c02:	013d09bb          	addw	s3,s10,s3
    80003c06:	012d093b          	addw	s2,s10,s2
    80003c0a:	9a6e                	add	s4,s4,s11
    80003c0c:	0569f663          	bgeu	s3,s6,80003c58 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c10:	00a9559b          	srliw	a1,s2,0xa
    80003c14:	8556                	mv	a0,s5
    80003c16:	fffff097          	auipc	ra,0xfffff
    80003c1a:	7a0080e7          	jalr	1952(ra) # 800033b6 <bmap>
    80003c1e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c22:	c99d                	beqz	a1,80003c58 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c24:	000aa503          	lw	a0,0(s5)
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	394080e7          	jalr	916(ra) # 80002fbc <bread>
    80003c30:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c32:	3ff97513          	andi	a0,s2,1023
    80003c36:	40ac87bb          	subw	a5,s9,a0
    80003c3a:	413b073b          	subw	a4,s6,s3
    80003c3e:	8d3e                	mv	s10,a5
    80003c40:	2781                	sext.w	a5,a5
    80003c42:	0007069b          	sext.w	a3,a4
    80003c46:	f8f6f4e3          	bgeu	a3,a5,80003bce <writei+0x4c>
    80003c4a:	8d3a                	mv	s10,a4
    80003c4c:	b749                	j	80003bce <writei+0x4c>
      brelse(bp);
    80003c4e:	8526                	mv	a0,s1
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	49c080e7          	jalr	1180(ra) # 800030ec <brelse>
  }

  if(off > ip->size)
    80003c58:	04caa783          	lw	a5,76(s5)
    80003c5c:	0127f463          	bgeu	a5,s2,80003c64 <writei+0xe2>
    ip->size = off;
    80003c60:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c64:	8556                	mv	a0,s5
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	aa6080e7          	jalr	-1370(ra) # 8000370c <iupdate>

  return tot;
    80003c6e:	0009851b          	sext.w	a0,s3
}
    80003c72:	70a6                	ld	ra,104(sp)
    80003c74:	7406                	ld	s0,96(sp)
    80003c76:	64e6                	ld	s1,88(sp)
    80003c78:	6946                	ld	s2,80(sp)
    80003c7a:	69a6                	ld	s3,72(sp)
    80003c7c:	6a06                	ld	s4,64(sp)
    80003c7e:	7ae2                	ld	s5,56(sp)
    80003c80:	7b42                	ld	s6,48(sp)
    80003c82:	7ba2                	ld	s7,40(sp)
    80003c84:	7c02                	ld	s8,32(sp)
    80003c86:	6ce2                	ld	s9,24(sp)
    80003c88:	6d42                	ld	s10,16(sp)
    80003c8a:	6da2                	ld	s11,8(sp)
    80003c8c:	6165                	addi	sp,sp,112
    80003c8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c90:	89da                	mv	s3,s6
    80003c92:	bfc9                	j	80003c64 <writei+0xe2>
    return -1;
    80003c94:	557d                	li	a0,-1
}
    80003c96:	8082                	ret
    return -1;
    80003c98:	557d                	li	a0,-1
    80003c9a:	bfe1                	j	80003c72 <writei+0xf0>
    return -1;
    80003c9c:	557d                	li	a0,-1
    80003c9e:	bfd1                	j	80003c72 <writei+0xf0>

0000000080003ca0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ca0:	1141                	addi	sp,sp,-16
    80003ca2:	e406                	sd	ra,8(sp)
    80003ca4:	e022                	sd	s0,0(sp)
    80003ca6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ca8:	4639                	li	a2,14
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	0f8080e7          	jalr	248(ra) # 80000da2 <strncmp>
}
    80003cb2:	60a2                	ld	ra,8(sp)
    80003cb4:	6402                	ld	s0,0(sp)
    80003cb6:	0141                	addi	sp,sp,16
    80003cb8:	8082                	ret

0000000080003cba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cba:	7139                	addi	sp,sp,-64
    80003cbc:	fc06                	sd	ra,56(sp)
    80003cbe:	f822                	sd	s0,48(sp)
    80003cc0:	f426                	sd	s1,40(sp)
    80003cc2:	f04a                	sd	s2,32(sp)
    80003cc4:	ec4e                	sd	s3,24(sp)
    80003cc6:	e852                	sd	s4,16(sp)
    80003cc8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cca:	04451703          	lh	a4,68(a0)
    80003cce:	4785                	li	a5,1
    80003cd0:	00f71a63          	bne	a4,a5,80003ce4 <dirlookup+0x2a>
    80003cd4:	892a                	mv	s2,a0
    80003cd6:	89ae                	mv	s3,a1
    80003cd8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cda:	457c                	lw	a5,76(a0)
    80003cdc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cde:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce0:	e79d                	bnez	a5,80003d0e <dirlookup+0x54>
    80003ce2:	a8a5                	j	80003d5a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	96c50513          	addi	a0,a0,-1684 # 80008650 <syscalls+0x1c0>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	852080e7          	jalr	-1966(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cf4:	00005517          	auipc	a0,0x5
    80003cf8:	97450513          	addi	a0,a0,-1676 # 80008668 <syscalls+0x1d8>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d04:	24c1                	addiw	s1,s1,16
    80003d06:	04c92783          	lw	a5,76(s2)
    80003d0a:	04f4f763          	bgeu	s1,a5,80003d58 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d0e:	4741                	li	a4,16
    80003d10:	86a6                	mv	a3,s1
    80003d12:	fc040613          	addi	a2,s0,-64
    80003d16:	4581                	li	a1,0
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	d70080e7          	jalr	-656(ra) # 80003a8a <readi>
    80003d22:	47c1                	li	a5,16
    80003d24:	fcf518e3          	bne	a0,a5,80003cf4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d28:	fc045783          	lhu	a5,-64(s0)
    80003d2c:	dfe1                	beqz	a5,80003d04 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d2e:	fc240593          	addi	a1,s0,-62
    80003d32:	854e                	mv	a0,s3
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	f6c080e7          	jalr	-148(ra) # 80003ca0 <namecmp>
    80003d3c:	f561                	bnez	a0,80003d04 <dirlookup+0x4a>
      if(poff)
    80003d3e:	000a0463          	beqz	s4,80003d46 <dirlookup+0x8c>
        *poff = off;
    80003d42:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d46:	fc045583          	lhu	a1,-64(s0)
    80003d4a:	00092503          	lw	a0,0(s2)
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	750080e7          	jalr	1872(ra) # 8000349e <iget>
    80003d56:	a011                	j	80003d5a <dirlookup+0xa0>
  return 0;
    80003d58:	4501                	li	a0,0
}
    80003d5a:	70e2                	ld	ra,56(sp)
    80003d5c:	7442                	ld	s0,48(sp)
    80003d5e:	74a2                	ld	s1,40(sp)
    80003d60:	7902                	ld	s2,32(sp)
    80003d62:	69e2                	ld	s3,24(sp)
    80003d64:	6a42                	ld	s4,16(sp)
    80003d66:	6121                	addi	sp,sp,64
    80003d68:	8082                	ret

0000000080003d6a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d6a:	711d                	addi	sp,sp,-96
    80003d6c:	ec86                	sd	ra,88(sp)
    80003d6e:	e8a2                	sd	s0,80(sp)
    80003d70:	e4a6                	sd	s1,72(sp)
    80003d72:	e0ca                	sd	s2,64(sp)
    80003d74:	fc4e                	sd	s3,56(sp)
    80003d76:	f852                	sd	s4,48(sp)
    80003d78:	f456                	sd	s5,40(sp)
    80003d7a:	f05a                	sd	s6,32(sp)
    80003d7c:	ec5e                	sd	s7,24(sp)
    80003d7e:	e862                	sd	s8,16(sp)
    80003d80:	e466                	sd	s9,8(sp)
    80003d82:	1080                	addi	s0,sp,96
    80003d84:	84aa                	mv	s1,a0
    80003d86:	8aae                	mv	s5,a1
    80003d88:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d8a:	00054703          	lbu	a4,0(a0)
    80003d8e:	02f00793          	li	a5,47
    80003d92:	02f70363          	beq	a4,a5,80003db8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d96:	ffffe097          	auipc	ra,0xffffe
    80003d9a:	c16080e7          	jalr	-1002(ra) # 800019ac <myproc>
    80003d9e:	15053503          	ld	a0,336(a0)
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	9f6080e7          	jalr	-1546(ra) # 80003798 <idup>
    80003daa:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dac:	02f00913          	li	s2,47
  len = path - s;
    80003db0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003db2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003db4:	4b85                	li	s7,1
    80003db6:	a865                	j	80003e6e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003db8:	4585                	li	a1,1
    80003dba:	4505                	li	a0,1
    80003dbc:	fffff097          	auipc	ra,0xfffff
    80003dc0:	6e2080e7          	jalr	1762(ra) # 8000349e <iget>
    80003dc4:	89aa                	mv	s3,a0
    80003dc6:	b7dd                	j	80003dac <namex+0x42>
      iunlockput(ip);
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	c6e080e7          	jalr	-914(ra) # 80003a38 <iunlockput>
      return 0;
    80003dd2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	60e6                	ld	ra,88(sp)
    80003dd8:	6446                	ld	s0,80(sp)
    80003dda:	64a6                	ld	s1,72(sp)
    80003ddc:	6906                	ld	s2,64(sp)
    80003dde:	79e2                	ld	s3,56(sp)
    80003de0:	7a42                	ld	s4,48(sp)
    80003de2:	7aa2                	ld	s5,40(sp)
    80003de4:	7b02                	ld	s6,32(sp)
    80003de6:	6be2                	ld	s7,24(sp)
    80003de8:	6c42                	ld	s8,16(sp)
    80003dea:	6ca2                	ld	s9,8(sp)
    80003dec:	6125                	addi	sp,sp,96
    80003dee:	8082                	ret
      iunlock(ip);
    80003df0:	854e                	mv	a0,s3
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	aa6080e7          	jalr	-1370(ra) # 80003898 <iunlock>
      return ip;
    80003dfa:	bfe9                	j	80003dd4 <namex+0x6a>
      iunlockput(ip);
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	c3a080e7          	jalr	-966(ra) # 80003a38 <iunlockput>
      return 0;
    80003e06:	89e6                	mv	s3,s9
    80003e08:	b7f1                	j	80003dd4 <namex+0x6a>
  len = path - s;
    80003e0a:	40b48633          	sub	a2,s1,a1
    80003e0e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e12:	099c5463          	bge	s8,s9,80003e9a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e16:	4639                	li	a2,14
    80003e18:	8552                	mv	a0,s4
    80003e1a:	ffffd097          	auipc	ra,0xffffd
    80003e1e:	f14080e7          	jalr	-236(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	01279763          	bne	a5,s2,80003e34 <namex+0xca>
    path++;
    80003e2a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e2c:	0004c783          	lbu	a5,0(s1)
    80003e30:	ff278de3          	beq	a5,s2,80003e2a <namex+0xc0>
    ilock(ip);
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	9a0080e7          	jalr	-1632(ra) # 800037d6 <ilock>
    if(ip->type != T_DIR){
    80003e3e:	04499783          	lh	a5,68(s3)
    80003e42:	f97793e3          	bne	a5,s7,80003dc8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e46:	000a8563          	beqz	s5,80003e50 <namex+0xe6>
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	d3cd                	beqz	a5,80003df0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e50:	865a                	mv	a2,s6
    80003e52:	85d2                	mv	a1,s4
    80003e54:	854e                	mv	a0,s3
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	e64080e7          	jalr	-412(ra) # 80003cba <dirlookup>
    80003e5e:	8caa                	mv	s9,a0
    80003e60:	dd51                	beqz	a0,80003dfc <namex+0x92>
    iunlockput(ip);
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	bd4080e7          	jalr	-1068(ra) # 80003a38 <iunlockput>
    ip = next;
    80003e6c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	05279763          	bne	a5,s2,80003ec0 <namex+0x156>
    path++;
    80003e76:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e78:	0004c783          	lbu	a5,0(s1)
    80003e7c:	ff278de3          	beq	a5,s2,80003e76 <namex+0x10c>
  if(*path == 0)
    80003e80:	c79d                	beqz	a5,80003eae <namex+0x144>
    path++;
    80003e82:	85a6                	mv	a1,s1
  len = path - s;
    80003e84:	8cda                	mv	s9,s6
    80003e86:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e88:	01278963          	beq	a5,s2,80003e9a <namex+0x130>
    80003e8c:	dfbd                	beqz	a5,80003e0a <namex+0xa0>
    path++;
    80003e8e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e90:	0004c783          	lbu	a5,0(s1)
    80003e94:	ff279ce3          	bne	a5,s2,80003e8c <namex+0x122>
    80003e98:	bf8d                	j	80003e0a <namex+0xa0>
    memmove(name, s, len);
    80003e9a:	2601                	sext.w	a2,a2
    80003e9c:	8552                	mv	a0,s4
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	e90080e7          	jalr	-368(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003ea6:	9cd2                	add	s9,s9,s4
    80003ea8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003eac:	bf9d                	j	80003e22 <namex+0xb8>
  if(nameiparent){
    80003eae:	f20a83e3          	beqz	s5,80003dd4 <namex+0x6a>
    iput(ip);
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	adc080e7          	jalr	-1316(ra) # 80003990 <iput>
    return 0;
    80003ebc:	4981                	li	s3,0
    80003ebe:	bf19                	j	80003dd4 <namex+0x6a>
  if(*path == 0)
    80003ec0:	d7fd                	beqz	a5,80003eae <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ec2:	0004c783          	lbu	a5,0(s1)
    80003ec6:	85a6                	mv	a1,s1
    80003ec8:	b7d1                	j	80003e8c <namex+0x122>

0000000080003eca <dirlink>:
{
    80003eca:	7139                	addi	sp,sp,-64
    80003ecc:	fc06                	sd	ra,56(sp)
    80003ece:	f822                	sd	s0,48(sp)
    80003ed0:	f426                	sd	s1,40(sp)
    80003ed2:	f04a                	sd	s2,32(sp)
    80003ed4:	ec4e                	sd	s3,24(sp)
    80003ed6:	e852                	sd	s4,16(sp)
    80003ed8:	0080                	addi	s0,sp,64
    80003eda:	892a                	mv	s2,a0
    80003edc:	8a2e                	mv	s4,a1
    80003ede:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ee0:	4601                	li	a2,0
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	dd8080e7          	jalr	-552(ra) # 80003cba <dirlookup>
    80003eea:	e93d                	bnez	a0,80003f60 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eec:	04c92483          	lw	s1,76(s2)
    80003ef0:	c49d                	beqz	s1,80003f1e <dirlink+0x54>
    80003ef2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef4:	4741                	li	a4,16
    80003ef6:	86a6                	mv	a3,s1
    80003ef8:	fc040613          	addi	a2,s0,-64
    80003efc:	4581                	li	a1,0
    80003efe:	854a                	mv	a0,s2
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	b8a080e7          	jalr	-1142(ra) # 80003a8a <readi>
    80003f08:	47c1                	li	a5,16
    80003f0a:	06f51163          	bne	a0,a5,80003f6c <dirlink+0xa2>
    if(de.inum == 0)
    80003f0e:	fc045783          	lhu	a5,-64(s0)
    80003f12:	c791                	beqz	a5,80003f1e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f14:	24c1                	addiw	s1,s1,16
    80003f16:	04c92783          	lw	a5,76(s2)
    80003f1a:	fcf4ede3          	bltu	s1,a5,80003ef4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f1e:	4639                	li	a2,14
    80003f20:	85d2                	mv	a1,s4
    80003f22:	fc240513          	addi	a0,s0,-62
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	eb8080e7          	jalr	-328(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f2e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f32:	4741                	li	a4,16
    80003f34:	86a6                	mv	a3,s1
    80003f36:	fc040613          	addi	a2,s0,-64
    80003f3a:	4581                	li	a1,0
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	c44080e7          	jalr	-956(ra) # 80003b82 <writei>
    80003f46:	1541                	addi	a0,a0,-16
    80003f48:	00a03533          	snez	a0,a0
    80003f4c:	40a00533          	neg	a0,a0
}
    80003f50:	70e2                	ld	ra,56(sp)
    80003f52:	7442                	ld	s0,48(sp)
    80003f54:	74a2                	ld	s1,40(sp)
    80003f56:	7902                	ld	s2,32(sp)
    80003f58:	69e2                	ld	s3,24(sp)
    80003f5a:	6a42                	ld	s4,16(sp)
    80003f5c:	6121                	addi	sp,sp,64
    80003f5e:	8082                	ret
    iput(ip);
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	a30080e7          	jalr	-1488(ra) # 80003990 <iput>
    return -1;
    80003f68:	557d                	li	a0,-1
    80003f6a:	b7dd                	j	80003f50 <dirlink+0x86>
      panic("dirlink read");
    80003f6c:	00004517          	auipc	a0,0x4
    80003f70:	70c50513          	addi	a0,a0,1804 # 80008678 <syscalls+0x1e8>
    80003f74:	ffffc097          	auipc	ra,0xffffc
    80003f78:	5ca080e7          	jalr	1482(ra) # 8000053e <panic>

0000000080003f7c <namei>:

struct inode*
namei(char *path)
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f84:	fe040613          	addi	a2,s0,-32
    80003f88:	4581                	li	a1,0
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	de0080e7          	jalr	-544(ra) # 80003d6a <namex>
}
    80003f92:	60e2                	ld	ra,24(sp)
    80003f94:	6442                	ld	s0,16(sp)
    80003f96:	6105                	addi	sp,sp,32
    80003f98:	8082                	ret

0000000080003f9a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f9a:	1141                	addi	sp,sp,-16
    80003f9c:	e406                	sd	ra,8(sp)
    80003f9e:	e022                	sd	s0,0(sp)
    80003fa0:	0800                	addi	s0,sp,16
    80003fa2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fa4:	4585                	li	a1,1
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	dc4080e7          	jalr	-572(ra) # 80003d6a <namex>
}
    80003fae:	60a2                	ld	ra,8(sp)
    80003fb0:	6402                	ld	s0,0(sp)
    80003fb2:	0141                	addi	sp,sp,16
    80003fb4:	8082                	ret

0000000080003fb6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb6:	1101                	addi	sp,sp,-32
    80003fb8:	ec06                	sd	ra,24(sp)
    80003fba:	e822                	sd	s0,16(sp)
    80003fbc:	e426                	sd	s1,8(sp)
    80003fbe:	e04a                	sd	s2,0(sp)
    80003fc0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fc2:	0001d917          	auipc	s2,0x1d
    80003fc6:	d9e90913          	addi	s2,s2,-610 # 80020d60 <log>
    80003fca:	01892583          	lw	a1,24(s2)
    80003fce:	02892503          	lw	a0,40(s2)
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	fea080e7          	jalr	-22(ra) # 80002fbc <bread>
    80003fda:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fdc:	02c92683          	lw	a3,44(s2)
    80003fe0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fe2:	02d05763          	blez	a3,80004010 <write_head+0x5a>
    80003fe6:	0001d797          	auipc	a5,0x1d
    80003fea:	daa78793          	addi	a5,a5,-598 # 80020d90 <log+0x30>
    80003fee:	05c50713          	addi	a4,a0,92
    80003ff2:	36fd                	addiw	a3,a3,-1
    80003ff4:	1682                	slli	a3,a3,0x20
    80003ff6:	9281                	srli	a3,a3,0x20
    80003ff8:	068a                	slli	a3,a3,0x2
    80003ffa:	0001d617          	auipc	a2,0x1d
    80003ffe:	d9a60613          	addi	a2,a2,-614 # 80020d94 <log+0x34>
    80004002:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004004:	4390                	lw	a2,0(a5)
    80004006:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004008:	0791                	addi	a5,a5,4
    8000400a:	0711                	addi	a4,a4,4
    8000400c:	fed79ce3          	bne	a5,a3,80004004 <write_head+0x4e>
  }
  bwrite(buf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	09c080e7          	jalr	156(ra) # 800030ae <bwrite>
  brelse(buf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	0d0080e7          	jalr	208(ra) # 800030ec <brelse>
}
    80004024:	60e2                	ld	ra,24(sp)
    80004026:	6442                	ld	s0,16(sp)
    80004028:	64a2                	ld	s1,8(sp)
    8000402a:	6902                	ld	s2,0(sp)
    8000402c:	6105                	addi	sp,sp,32
    8000402e:	8082                	ret

0000000080004030 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004030:	0001d797          	auipc	a5,0x1d
    80004034:	d5c7a783          	lw	a5,-676(a5) # 80020d8c <log+0x2c>
    80004038:	0af05d63          	blez	a5,800040f2 <install_trans+0xc2>
{
    8000403c:	7139                	addi	sp,sp,-64
    8000403e:	fc06                	sd	ra,56(sp)
    80004040:	f822                	sd	s0,48(sp)
    80004042:	f426                	sd	s1,40(sp)
    80004044:	f04a                	sd	s2,32(sp)
    80004046:	ec4e                	sd	s3,24(sp)
    80004048:	e852                	sd	s4,16(sp)
    8000404a:	e456                	sd	s5,8(sp)
    8000404c:	e05a                	sd	s6,0(sp)
    8000404e:	0080                	addi	s0,sp,64
    80004050:	8b2a                	mv	s6,a0
    80004052:	0001da97          	auipc	s5,0x1d
    80004056:	d3ea8a93          	addi	s5,s5,-706 # 80020d90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000405c:	0001d997          	auipc	s3,0x1d
    80004060:	d0498993          	addi	s3,s3,-764 # 80020d60 <log>
    80004064:	a00d                	j	80004086 <install_trans+0x56>
    brelse(lbuf);
    80004066:	854a                	mv	a0,s2
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	084080e7          	jalr	132(ra) # 800030ec <brelse>
    brelse(dbuf);
    80004070:	8526                	mv	a0,s1
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	07a080e7          	jalr	122(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407a:	2a05                	addiw	s4,s4,1
    8000407c:	0a91                	addi	s5,s5,4
    8000407e:	02c9a783          	lw	a5,44(s3)
    80004082:	04fa5e63          	bge	s4,a5,800040de <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004086:	0189a583          	lw	a1,24(s3)
    8000408a:	014585bb          	addw	a1,a1,s4
    8000408e:	2585                	addiw	a1,a1,1
    80004090:	0289a503          	lw	a0,40(s3)
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	f28080e7          	jalr	-216(ra) # 80002fbc <bread>
    8000409c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000409e:	000aa583          	lw	a1,0(s5)
    800040a2:	0289a503          	lw	a0,40(s3)
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	f16080e7          	jalr	-234(ra) # 80002fbc <bread>
    800040ae:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b0:	40000613          	li	a2,1024
    800040b4:	05890593          	addi	a1,s2,88
    800040b8:	05850513          	addi	a0,a0,88
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	c72080e7          	jalr	-910(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	fe8080e7          	jalr	-24(ra) # 800030ae <bwrite>
    if(recovering == 0)
    800040ce:	f80b1ce3          	bnez	s6,80004066 <install_trans+0x36>
      bunpin(dbuf);
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	0f2080e7          	jalr	242(ra) # 800031c6 <bunpin>
    800040dc:	b769                	j	80004066 <install_trans+0x36>
}
    800040de:	70e2                	ld	ra,56(sp)
    800040e0:	7442                	ld	s0,48(sp)
    800040e2:	74a2                	ld	s1,40(sp)
    800040e4:	7902                	ld	s2,32(sp)
    800040e6:	69e2                	ld	s3,24(sp)
    800040e8:	6a42                	ld	s4,16(sp)
    800040ea:	6aa2                	ld	s5,8(sp)
    800040ec:	6b02                	ld	s6,0(sp)
    800040ee:	6121                	addi	sp,sp,64
    800040f0:	8082                	ret
    800040f2:	8082                	ret

00000000800040f4 <initlog>:
{
    800040f4:	7179                	addi	sp,sp,-48
    800040f6:	f406                	sd	ra,40(sp)
    800040f8:	f022                	sd	s0,32(sp)
    800040fa:	ec26                	sd	s1,24(sp)
    800040fc:	e84a                	sd	s2,16(sp)
    800040fe:	e44e                	sd	s3,8(sp)
    80004100:	1800                	addi	s0,sp,48
    80004102:	892a                	mv	s2,a0
    80004104:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004106:	0001d497          	auipc	s1,0x1d
    8000410a:	c5a48493          	addi	s1,s1,-934 # 80020d60 <log>
    8000410e:	00004597          	auipc	a1,0x4
    80004112:	57a58593          	addi	a1,a1,1402 # 80008688 <syscalls+0x1f8>
    80004116:	8526                	mv	a0,s1
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	a2e080e7          	jalr	-1490(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004120:	0149a583          	lw	a1,20(s3)
    80004124:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004126:	0109a783          	lw	a5,16(s3)
    8000412a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000412c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004130:	854a                	mv	a0,s2
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	e8a080e7          	jalr	-374(ra) # 80002fbc <bread>
  log.lh.n = lh->n;
    8000413a:	4d34                	lw	a3,88(a0)
    8000413c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000413e:	02d05563          	blez	a3,80004168 <initlog+0x74>
    80004142:	05c50793          	addi	a5,a0,92
    80004146:	0001d717          	auipc	a4,0x1d
    8000414a:	c4a70713          	addi	a4,a4,-950 # 80020d90 <log+0x30>
    8000414e:	36fd                	addiw	a3,a3,-1
    80004150:	1682                	slli	a3,a3,0x20
    80004152:	9281                	srli	a3,a3,0x20
    80004154:	068a                	slli	a3,a3,0x2
    80004156:	06050613          	addi	a2,a0,96
    8000415a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000415c:	4390                	lw	a2,0(a5)
    8000415e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004160:	0791                	addi	a5,a5,4
    80004162:	0711                	addi	a4,a4,4
    80004164:	fed79ce3          	bne	a5,a3,8000415c <initlog+0x68>
  brelse(buf);
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	f84080e7          	jalr	-124(ra) # 800030ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004170:	4505                	li	a0,1
    80004172:	00000097          	auipc	ra,0x0
    80004176:	ebe080e7          	jalr	-322(ra) # 80004030 <install_trans>
  log.lh.n = 0;
    8000417a:	0001d797          	auipc	a5,0x1d
    8000417e:	c007a923          	sw	zero,-1006(a5) # 80020d8c <log+0x2c>
  write_head(); // clear the log
    80004182:	00000097          	auipc	ra,0x0
    80004186:	e34080e7          	jalr	-460(ra) # 80003fb6 <write_head>
}
    8000418a:	70a2                	ld	ra,40(sp)
    8000418c:	7402                	ld	s0,32(sp)
    8000418e:	64e2                	ld	s1,24(sp)
    80004190:	6942                	ld	s2,16(sp)
    80004192:	69a2                	ld	s3,8(sp)
    80004194:	6145                	addi	sp,sp,48
    80004196:	8082                	ret

0000000080004198 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004198:	1101                	addi	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	e04a                	sd	s2,0(sp)
    800041a2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041a4:	0001d517          	auipc	a0,0x1d
    800041a8:	bbc50513          	addi	a0,a0,-1092 # 80020d60 <log>
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	a2a080e7          	jalr	-1494(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041b4:	0001d497          	auipc	s1,0x1d
    800041b8:	bac48493          	addi	s1,s1,-1108 # 80020d60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041bc:	4979                	li	s2,30
    800041be:	a039                	j	800041cc <begin_op+0x34>
      sleep(&log, &log.lock);
    800041c0:	85a6                	mv	a1,s1
    800041c2:	8526                	mv	a0,s1
    800041c4:	ffffe097          	auipc	ra,0xffffe
    800041c8:	e9c080e7          	jalr	-356(ra) # 80002060 <sleep>
    if(log.committing){
    800041cc:	50dc                	lw	a5,36(s1)
    800041ce:	fbed                	bnez	a5,800041c0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d0:	509c                	lw	a5,32(s1)
    800041d2:	0017871b          	addiw	a4,a5,1
    800041d6:	0007069b          	sext.w	a3,a4
    800041da:	0027179b          	slliw	a5,a4,0x2
    800041de:	9fb9                	addw	a5,a5,a4
    800041e0:	0017979b          	slliw	a5,a5,0x1
    800041e4:	54d8                	lw	a4,44(s1)
    800041e6:	9fb9                	addw	a5,a5,a4
    800041e8:	00f95963          	bge	s2,a5,800041fa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ec:	85a6                	mv	a1,s1
    800041ee:	8526                	mv	a0,s1
    800041f0:	ffffe097          	auipc	ra,0xffffe
    800041f4:	e70080e7          	jalr	-400(ra) # 80002060 <sleep>
    800041f8:	bfd1                	j	800041cc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041fa:	0001d517          	auipc	a0,0x1d
    800041fe:	b6650513          	addi	a0,a0,-1178 # 80020d60 <log>
    80004202:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	a86080e7          	jalr	-1402(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000420c:	60e2                	ld	ra,24(sp)
    8000420e:	6442                	ld	s0,16(sp)
    80004210:	64a2                	ld	s1,8(sp)
    80004212:	6902                	ld	s2,0(sp)
    80004214:	6105                	addi	sp,sp,32
    80004216:	8082                	ret

0000000080004218 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004218:	7139                	addi	sp,sp,-64
    8000421a:	fc06                	sd	ra,56(sp)
    8000421c:	f822                	sd	s0,48(sp)
    8000421e:	f426                	sd	s1,40(sp)
    80004220:	f04a                	sd	s2,32(sp)
    80004222:	ec4e                	sd	s3,24(sp)
    80004224:	e852                	sd	s4,16(sp)
    80004226:	e456                	sd	s5,8(sp)
    80004228:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000422a:	0001d497          	auipc	s1,0x1d
    8000422e:	b3648493          	addi	s1,s1,-1226 # 80020d60 <log>
    80004232:	8526                	mv	a0,s1
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	9a2080e7          	jalr	-1630(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000423c:	509c                	lw	a5,32(s1)
    8000423e:	37fd                	addiw	a5,a5,-1
    80004240:	0007891b          	sext.w	s2,a5
    80004244:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004246:	50dc                	lw	a5,36(s1)
    80004248:	e7b9                	bnez	a5,80004296 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000424a:	04091e63          	bnez	s2,800042a6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000424e:	0001d497          	auipc	s1,0x1d
    80004252:	b1248493          	addi	s1,s1,-1262 # 80020d60 <log>
    80004256:	4785                	li	a5,1
    80004258:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	a2e080e7          	jalr	-1490(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004264:	54dc                	lw	a5,44(s1)
    80004266:	06f04763          	bgtz	a5,800042d4 <end_op+0xbc>
    acquire(&log.lock);
    8000426a:	0001d497          	auipc	s1,0x1d
    8000426e:	af648493          	addi	s1,s1,-1290 # 80020d60 <log>
    80004272:	8526                	mv	a0,s1
    80004274:	ffffd097          	auipc	ra,0xffffd
    80004278:	962080e7          	jalr	-1694(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000427c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004280:	8526                	mv	a0,s1
    80004282:	ffffe097          	auipc	ra,0xffffe
    80004286:	e42080e7          	jalr	-446(ra) # 800020c4 <wakeup>
    release(&log.lock);
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	9fe080e7          	jalr	-1538(ra) # 80000c8a <release>
}
    80004294:	a03d                	j	800042c2 <end_op+0xaa>
    panic("log.committing");
    80004296:	00004517          	auipc	a0,0x4
    8000429a:	3fa50513          	addi	a0,a0,1018 # 80008690 <syscalls+0x200>
    8000429e:	ffffc097          	auipc	ra,0xffffc
    800042a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    wakeup(&log);
    800042a6:	0001d497          	auipc	s1,0x1d
    800042aa:	aba48493          	addi	s1,s1,-1350 # 80020d60 <log>
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	e14080e7          	jalr	-492(ra) # 800020c4 <wakeup>
  release(&log.lock);
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9d0080e7          	jalr	-1584(ra) # 80000c8a <release>
}
    800042c2:	70e2                	ld	ra,56(sp)
    800042c4:	7442                	ld	s0,48(sp)
    800042c6:	74a2                	ld	s1,40(sp)
    800042c8:	7902                	ld	s2,32(sp)
    800042ca:	69e2                	ld	s3,24(sp)
    800042cc:	6a42                	ld	s4,16(sp)
    800042ce:	6aa2                	ld	s5,8(sp)
    800042d0:	6121                	addi	sp,sp,64
    800042d2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d4:	0001da97          	auipc	s5,0x1d
    800042d8:	abca8a93          	addi	s5,s5,-1348 # 80020d90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042dc:	0001da17          	auipc	s4,0x1d
    800042e0:	a84a0a13          	addi	s4,s4,-1404 # 80020d60 <log>
    800042e4:	018a2583          	lw	a1,24(s4)
    800042e8:	012585bb          	addw	a1,a1,s2
    800042ec:	2585                	addiw	a1,a1,1
    800042ee:	028a2503          	lw	a0,40(s4)
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	cca080e7          	jalr	-822(ra) # 80002fbc <bread>
    800042fa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042fc:	000aa583          	lw	a1,0(s5)
    80004300:	028a2503          	lw	a0,40(s4)
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	cb8080e7          	jalr	-840(ra) # 80002fbc <bread>
    8000430c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000430e:	40000613          	li	a2,1024
    80004312:	05850593          	addi	a1,a0,88
    80004316:	05848513          	addi	a0,s1,88
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	a14080e7          	jalr	-1516(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	d8a080e7          	jalr	-630(ra) # 800030ae <bwrite>
    brelse(from);
    8000432c:	854e                	mv	a0,s3
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	dbe080e7          	jalr	-578(ra) # 800030ec <brelse>
    brelse(to);
    80004336:	8526                	mv	a0,s1
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	db4080e7          	jalr	-588(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004340:	2905                	addiw	s2,s2,1
    80004342:	0a91                	addi	s5,s5,4
    80004344:	02ca2783          	lw	a5,44(s4)
    80004348:	f8f94ee3          	blt	s2,a5,800042e4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	c6a080e7          	jalr	-918(ra) # 80003fb6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004354:	4501                	li	a0,0
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	cda080e7          	jalr	-806(ra) # 80004030 <install_trans>
    log.lh.n = 0;
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	a207a723          	sw	zero,-1490(a5) # 80020d8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	c50080e7          	jalr	-944(ra) # 80003fb6 <write_head>
    8000436e:	bdf5                	j	8000426a <end_op+0x52>

0000000080004370 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004370:	1101                	addi	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	e04a                	sd	s2,0(sp)
    8000437a:	1000                	addi	s0,sp,32
    8000437c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000437e:	0001d917          	auipc	s2,0x1d
    80004382:	9e290913          	addi	s2,s2,-1566 # 80020d60 <log>
    80004386:	854a                	mv	a0,s2
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004390:	02c92603          	lw	a2,44(s2)
    80004394:	47f5                	li	a5,29
    80004396:	06c7c563          	blt	a5,a2,80004400 <log_write+0x90>
    8000439a:	0001d797          	auipc	a5,0x1d
    8000439e:	9e27a783          	lw	a5,-1566(a5) # 80020d7c <log+0x1c>
    800043a2:	37fd                	addiw	a5,a5,-1
    800043a4:	04f65e63          	bge	a2,a5,80004400 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a8:	0001d797          	auipc	a5,0x1d
    800043ac:	9d87a783          	lw	a5,-1576(a5) # 80020d80 <log+0x20>
    800043b0:	06f05063          	blez	a5,80004410 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043b4:	4781                	li	a5,0
    800043b6:	06c05563          	blez	a2,80004420 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043ba:	44cc                	lw	a1,12(s1)
    800043bc:	0001d717          	auipc	a4,0x1d
    800043c0:	9d470713          	addi	a4,a4,-1580 # 80020d90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c6:	4314                	lw	a3,0(a4)
    800043c8:	04b68c63          	beq	a3,a1,80004420 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043cc:	2785                	addiw	a5,a5,1
    800043ce:	0711                	addi	a4,a4,4
    800043d0:	fef61be3          	bne	a2,a5,800043c6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043d4:	0621                	addi	a2,a2,8
    800043d6:	060a                	slli	a2,a2,0x2
    800043d8:	0001d797          	auipc	a5,0x1d
    800043dc:	98878793          	addi	a5,a5,-1656 # 80020d60 <log>
    800043e0:	963e                	add	a2,a2,a5
    800043e2:	44dc                	lw	a5,12(s1)
    800043e4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	da2080e7          	jalr	-606(ra) # 8000318a <bpin>
    log.lh.n++;
    800043f0:	0001d717          	auipc	a4,0x1d
    800043f4:	97070713          	addi	a4,a4,-1680 # 80020d60 <log>
    800043f8:	575c                	lw	a5,44(a4)
    800043fa:	2785                	addiw	a5,a5,1
    800043fc:	d75c                	sw	a5,44(a4)
    800043fe:	a835                	j	8000443a <log_write+0xca>
    panic("too big a transaction");
    80004400:	00004517          	auipc	a0,0x4
    80004404:	2a050513          	addi	a0,a0,672 # 800086a0 <syscalls+0x210>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	136080e7          	jalr	310(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004410:	00004517          	auipc	a0,0x4
    80004414:	2a850513          	addi	a0,a0,680 # 800086b8 <syscalls+0x228>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	126080e7          	jalr	294(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004420:	00878713          	addi	a4,a5,8
    80004424:	00271693          	slli	a3,a4,0x2
    80004428:	0001d717          	auipc	a4,0x1d
    8000442c:	93870713          	addi	a4,a4,-1736 # 80020d60 <log>
    80004430:	9736                	add	a4,a4,a3
    80004432:	44d4                	lw	a3,12(s1)
    80004434:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004436:	faf608e3          	beq	a2,a5,800043e6 <log_write+0x76>
  }
  release(&log.lock);
    8000443a:	0001d517          	auipc	a0,0x1d
    8000443e:	92650513          	addi	a0,a0,-1754 # 80020d60 <log>
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
}
    8000444a:	60e2                	ld	ra,24(sp)
    8000444c:	6442                	ld	s0,16(sp)
    8000444e:	64a2                	ld	s1,8(sp)
    80004450:	6902                	ld	s2,0(sp)
    80004452:	6105                	addi	sp,sp,32
    80004454:	8082                	ret

0000000080004456 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004456:	1101                	addi	sp,sp,-32
    80004458:	ec06                	sd	ra,24(sp)
    8000445a:	e822                	sd	s0,16(sp)
    8000445c:	e426                	sd	s1,8(sp)
    8000445e:	e04a                	sd	s2,0(sp)
    80004460:	1000                	addi	s0,sp,32
    80004462:	84aa                	mv	s1,a0
    80004464:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004466:	00004597          	auipc	a1,0x4
    8000446a:	27258593          	addi	a1,a1,626 # 800086d8 <syscalls+0x248>
    8000446e:	0521                	addi	a0,a0,8
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	6d6080e7          	jalr	1750(ra) # 80000b46 <initlock>
  lk->name = name;
    80004478:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000447c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004480:	0204a423          	sw	zero,40(s1)
}
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6902                	ld	s2,0(sp)
    8000448c:	6105                	addi	sp,sp,32
    8000448e:	8082                	ret

0000000080004490 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004490:	1101                	addi	sp,sp,-32
    80004492:	ec06                	sd	ra,24(sp)
    80004494:	e822                	sd	s0,16(sp)
    80004496:	e426                	sd	s1,8(sp)
    80004498:	e04a                	sd	s2,0(sp)
    8000449a:	1000                	addi	s0,sp,32
    8000449c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000449e:	00850913          	addi	s2,a0,8
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044ac:	409c                	lw	a5,0(s1)
    800044ae:	cb89                	beqz	a5,800044c0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044b0:	85ca                	mv	a1,s2
    800044b2:	8526                	mv	a0,s1
    800044b4:	ffffe097          	auipc	ra,0xffffe
    800044b8:	bac080e7          	jalr	-1108(ra) # 80002060 <sleep>
  while (lk->locked) {
    800044bc:	409c                	lw	a5,0(s1)
    800044be:	fbed                	bnez	a5,800044b0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044c0:	4785                	li	a5,1
    800044c2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	4e8080e7          	jalr	1256(ra) # 800019ac <myproc>
    800044cc:	591c                	lw	a5,48(a0)
    800044ce:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
}
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	64a2                	ld	s1,8(sp)
    800044e0:	6902                	ld	s2,0(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
    800044f2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f4:	00850913          	addi	s2,a0,8
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004502:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004506:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000450a:	8526                	mv	a0,s1
    8000450c:	ffffe097          	auipc	ra,0xffffe
    80004510:	bb8080e7          	jalr	-1096(ra) # 800020c4 <wakeup>
  release(&lk->lk);
    80004514:	854a                	mv	a0,s2
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	774080e7          	jalr	1908(ra) # 80000c8a <release>
}
    8000451e:	60e2                	ld	ra,24(sp)
    80004520:	6442                	ld	s0,16(sp)
    80004522:	64a2                	ld	s1,8(sp)
    80004524:	6902                	ld	s2,0(sp)
    80004526:	6105                	addi	sp,sp,32
    80004528:	8082                	ret

000000008000452a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000452a:	7179                	addi	sp,sp,-48
    8000452c:	f406                	sd	ra,40(sp)
    8000452e:	f022                	sd	s0,32(sp)
    80004530:	ec26                	sd	s1,24(sp)
    80004532:	e84a                	sd	s2,16(sp)
    80004534:	e44e                	sd	s3,8(sp)
    80004536:	1800                	addi	s0,sp,48
    80004538:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000453a:	00850913          	addi	s2,a0,8
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	696080e7          	jalr	1686(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004548:	409c                	lw	a5,0(s1)
    8000454a:	ef99                	bnez	a5,80004568 <holdingsleep+0x3e>
    8000454c:	4481                	li	s1,0
  release(&lk->lk);
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	73a080e7          	jalr	1850(ra) # 80000c8a <release>
  return r;
}
    80004558:	8526                	mv	a0,s1
    8000455a:	70a2                	ld	ra,40(sp)
    8000455c:	7402                	ld	s0,32(sp)
    8000455e:	64e2                	ld	s1,24(sp)
    80004560:	6942                	ld	s2,16(sp)
    80004562:	69a2                	ld	s3,8(sp)
    80004564:	6145                	addi	sp,sp,48
    80004566:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004568:	0284a983          	lw	s3,40(s1)
    8000456c:	ffffd097          	auipc	ra,0xffffd
    80004570:	440080e7          	jalr	1088(ra) # 800019ac <myproc>
    80004574:	5904                	lw	s1,48(a0)
    80004576:	413484b3          	sub	s1,s1,s3
    8000457a:	0014b493          	seqz	s1,s1
    8000457e:	bfc1                	j	8000454e <holdingsleep+0x24>

0000000080004580 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004580:	1141                	addi	sp,sp,-16
    80004582:	e406                	sd	ra,8(sp)
    80004584:	e022                	sd	s0,0(sp)
    80004586:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004588:	00004597          	auipc	a1,0x4
    8000458c:	16058593          	addi	a1,a1,352 # 800086e8 <syscalls+0x258>
    80004590:	0001d517          	auipc	a0,0x1d
    80004594:	91850513          	addi	a0,a0,-1768 # 80020ea8 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	5ae080e7          	jalr	1454(ra) # 80000b46 <initlock>
}
    800045a0:	60a2                	ld	ra,8(sp)
    800045a2:	6402                	ld	s0,0(sp)
    800045a4:	0141                	addi	sp,sp,16
    800045a6:	8082                	ret

00000000800045a8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045a8:	1101                	addi	sp,sp,-32
    800045aa:	ec06                	sd	ra,24(sp)
    800045ac:	e822                	sd	s0,16(sp)
    800045ae:	e426                	sd	s1,8(sp)
    800045b0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045b2:	0001d517          	auipc	a0,0x1d
    800045b6:	8f650513          	addi	a0,a0,-1802 # 80020ea8 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	61c080e7          	jalr	1564(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c2:	0001d497          	auipc	s1,0x1d
    800045c6:	8fe48493          	addi	s1,s1,-1794 # 80020ec0 <ftable+0x18>
    800045ca:	0001e717          	auipc	a4,0x1e
    800045ce:	89670713          	addi	a4,a4,-1898 # 80021e60 <disk>
    if(f->ref == 0){
    800045d2:	40dc                	lw	a5,4(s1)
    800045d4:	cf99                	beqz	a5,800045f2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d6:	02848493          	addi	s1,s1,40
    800045da:	fee49ce3          	bne	s1,a4,800045d2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045de:	0001d517          	auipc	a0,0x1d
    800045e2:	8ca50513          	addi	a0,a0,-1846 # 80020ea8 <ftable>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6a4080e7          	jalr	1700(ra) # 80000c8a <release>
  return 0;
    800045ee:	4481                	li	s1,0
    800045f0:	a819                	j	80004606 <filealloc+0x5e>
      f->ref = 1;
    800045f2:	4785                	li	a5,1
    800045f4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	8b250513          	addi	a0,a0,-1870 # 80020ea8 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	68c080e7          	jalr	1676(ra) # 80000c8a <release>
}
    80004606:	8526                	mv	a0,s1
    80004608:	60e2                	ld	ra,24(sp)
    8000460a:	6442                	ld	s0,16(sp)
    8000460c:	64a2                	ld	s1,8(sp)
    8000460e:	6105                	addi	sp,sp,32
    80004610:	8082                	ret

0000000080004612 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004612:	1101                	addi	sp,sp,-32
    80004614:	ec06                	sd	ra,24(sp)
    80004616:	e822                	sd	s0,16(sp)
    80004618:	e426                	sd	s1,8(sp)
    8000461a:	1000                	addi	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	88a50513          	addi	a0,a0,-1910 # 80020ea8 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	5b0080e7          	jalr	1456(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000462e:	40dc                	lw	a5,4(s1)
    80004630:	02f05263          	blez	a5,80004654 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004634:	2785                	addiw	a5,a5,1
    80004636:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004638:	0001d517          	auipc	a0,0x1d
    8000463c:	87050513          	addi	a0,a0,-1936 # 80020ea8 <ftable>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	64a080e7          	jalr	1610(ra) # 80000c8a <release>
  return f;
}
    80004648:	8526                	mv	a0,s1
    8000464a:	60e2                	ld	ra,24(sp)
    8000464c:	6442                	ld	s0,16(sp)
    8000464e:	64a2                	ld	s1,8(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret
    panic("filedup");
    80004654:	00004517          	auipc	a0,0x4
    80004658:	09c50513          	addi	a0,a0,156 # 800086f0 <syscalls+0x260>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	ee2080e7          	jalr	-286(ra) # 8000053e <panic>

0000000080004664 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004664:	7139                	addi	sp,sp,-64
    80004666:	fc06                	sd	ra,56(sp)
    80004668:	f822                	sd	s0,48(sp)
    8000466a:	f426                	sd	s1,40(sp)
    8000466c:	f04a                	sd	s2,32(sp)
    8000466e:	ec4e                	sd	s3,24(sp)
    80004670:	e852                	sd	s4,16(sp)
    80004672:	e456                	sd	s5,8(sp)
    80004674:	0080                	addi	s0,sp,64
    80004676:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004678:	0001d517          	auipc	a0,0x1d
    8000467c:	83050513          	addi	a0,a0,-2000 # 80020ea8 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	556080e7          	jalr	1366(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004688:	40dc                	lw	a5,4(s1)
    8000468a:	06f05163          	blez	a5,800046ec <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000468e:	37fd                	addiw	a5,a5,-1
    80004690:	0007871b          	sext.w	a4,a5
    80004694:	c0dc                	sw	a5,4(s1)
    80004696:	06e04363          	bgtz	a4,800046fc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000469a:	0004a903          	lw	s2,0(s1)
    8000469e:	0094ca83          	lbu	s5,9(s1)
    800046a2:	0104ba03          	ld	s4,16(s1)
    800046a6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046aa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046ae:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046b2:	0001c517          	auipc	a0,0x1c
    800046b6:	7f650513          	addi	a0,a0,2038 # 80020ea8 <ftable>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5d0080e7          	jalr	1488(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046c2:	4785                	li	a5,1
    800046c4:	04f90d63          	beq	s2,a5,8000471e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046c8:	3979                	addiw	s2,s2,-2
    800046ca:	4785                	li	a5,1
    800046cc:	0527e063          	bltu	a5,s2,8000470c <fileclose+0xa8>
    begin_op();
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	ac8080e7          	jalr	-1336(ra) # 80004198 <begin_op>
    iput(ff.ip);
    800046d8:	854e                	mv	a0,s3
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	2b6080e7          	jalr	694(ra) # 80003990 <iput>
    end_op();
    800046e2:	00000097          	auipc	ra,0x0
    800046e6:	b36080e7          	jalr	-1226(ra) # 80004218 <end_op>
    800046ea:	a00d                	j	8000470c <fileclose+0xa8>
    panic("fileclose");
    800046ec:	00004517          	auipc	a0,0x4
    800046f0:	00c50513          	addi	a0,a0,12 # 800086f8 <syscalls+0x268>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046fc:	0001c517          	auipc	a0,0x1c
    80004700:	7ac50513          	addi	a0,a0,1964 # 80020ea8 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	586080e7          	jalr	1414(ra) # 80000c8a <release>
  }
}
    8000470c:	70e2                	ld	ra,56(sp)
    8000470e:	7442                	ld	s0,48(sp)
    80004710:	74a2                	ld	s1,40(sp)
    80004712:	7902                	ld	s2,32(sp)
    80004714:	69e2                	ld	s3,24(sp)
    80004716:	6a42                	ld	s4,16(sp)
    80004718:	6aa2                	ld	s5,8(sp)
    8000471a:	6121                	addi	sp,sp,64
    8000471c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000471e:	85d6                	mv	a1,s5
    80004720:	8552                	mv	a0,s4
    80004722:	00000097          	auipc	ra,0x0
    80004726:	34c080e7          	jalr	844(ra) # 80004a6e <pipeclose>
    8000472a:	b7cd                	j	8000470c <fileclose+0xa8>

000000008000472c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000472c:	715d                	addi	sp,sp,-80
    8000472e:	e486                	sd	ra,72(sp)
    80004730:	e0a2                	sd	s0,64(sp)
    80004732:	fc26                	sd	s1,56(sp)
    80004734:	f84a                	sd	s2,48(sp)
    80004736:	f44e                	sd	s3,40(sp)
    80004738:	0880                	addi	s0,sp,80
    8000473a:	84aa                	mv	s1,a0
    8000473c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000473e:	ffffd097          	auipc	ra,0xffffd
    80004742:	26e080e7          	jalr	622(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004746:	409c                	lw	a5,0(s1)
    80004748:	37f9                	addiw	a5,a5,-2
    8000474a:	4705                	li	a4,1
    8000474c:	04f76763          	bltu	a4,a5,8000479a <filestat+0x6e>
    80004750:	892a                	mv	s2,a0
    ilock(f->ip);
    80004752:	6c88                	ld	a0,24(s1)
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	082080e7          	jalr	130(ra) # 800037d6 <ilock>
    stati(f->ip, &st);
    8000475c:	fb840593          	addi	a1,s0,-72
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	2fe080e7          	jalr	766(ra) # 80003a60 <stati>
    iunlock(f->ip);
    8000476a:	6c88                	ld	a0,24(s1)
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	12c080e7          	jalr	300(ra) # 80003898 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004774:	46e1                	li	a3,24
    80004776:	fb840613          	addi	a2,s0,-72
    8000477a:	85ce                	mv	a1,s3
    8000477c:	05093503          	ld	a0,80(s2)
    80004780:	ffffd097          	auipc	ra,0xffffd
    80004784:	ee8080e7          	jalr	-280(ra) # 80001668 <copyout>
    80004788:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000478c:	60a6                	ld	ra,72(sp)
    8000478e:	6406                	ld	s0,64(sp)
    80004790:	74e2                	ld	s1,56(sp)
    80004792:	7942                	ld	s2,48(sp)
    80004794:	79a2                	ld	s3,40(sp)
    80004796:	6161                	addi	sp,sp,80
    80004798:	8082                	ret
  return -1;
    8000479a:	557d                	li	a0,-1
    8000479c:	bfc5                	j	8000478c <filestat+0x60>

000000008000479e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000479e:	7179                	addi	sp,sp,-48
    800047a0:	f406                	sd	ra,40(sp)
    800047a2:	f022                	sd	s0,32(sp)
    800047a4:	ec26                	sd	s1,24(sp)
    800047a6:	e84a                	sd	s2,16(sp)
    800047a8:	e44e                	sd	s3,8(sp)
    800047aa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047ac:	00854783          	lbu	a5,8(a0)
    800047b0:	c3d5                	beqz	a5,80004854 <fileread+0xb6>
    800047b2:	84aa                	mv	s1,a0
    800047b4:	89ae                	mv	s3,a1
    800047b6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b8:	411c                	lw	a5,0(a0)
    800047ba:	4705                	li	a4,1
    800047bc:	04e78963          	beq	a5,a4,8000480e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c0:	470d                	li	a4,3
    800047c2:	04e78d63          	beq	a5,a4,8000481c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c6:	4709                	li	a4,2
    800047c8:	06e79e63          	bne	a5,a4,80004844 <fileread+0xa6>
    ilock(f->ip);
    800047cc:	6d08                	ld	a0,24(a0)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	008080e7          	jalr	8(ra) # 800037d6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047d6:	874a                	mv	a4,s2
    800047d8:	5094                	lw	a3,32(s1)
    800047da:	864e                	mv	a2,s3
    800047dc:	4585                	li	a1,1
    800047de:	6c88                	ld	a0,24(s1)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	2aa080e7          	jalr	682(ra) # 80003a8a <readi>
    800047e8:	892a                	mv	s2,a0
    800047ea:	00a05563          	blez	a0,800047f4 <fileread+0x56>
      f->off += r;
    800047ee:	509c                	lw	a5,32(s1)
    800047f0:	9fa9                	addw	a5,a5,a0
    800047f2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047f4:	6c88                	ld	a0,24(s1)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	0a2080e7          	jalr	162(ra) # 80003898 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047fe:	854a                	mv	a0,s2
    80004800:	70a2                	ld	ra,40(sp)
    80004802:	7402                	ld	s0,32(sp)
    80004804:	64e2                	ld	s1,24(sp)
    80004806:	6942                	ld	s2,16(sp)
    80004808:	69a2                	ld	s3,8(sp)
    8000480a:	6145                	addi	sp,sp,48
    8000480c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000480e:	6908                	ld	a0,16(a0)
    80004810:	00000097          	auipc	ra,0x0
    80004814:	3c6080e7          	jalr	966(ra) # 80004bd6 <piperead>
    80004818:	892a                	mv	s2,a0
    8000481a:	b7d5                	j	800047fe <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000481c:	02451783          	lh	a5,36(a0)
    80004820:	03079693          	slli	a3,a5,0x30
    80004824:	92c1                	srli	a3,a3,0x30
    80004826:	4725                	li	a4,9
    80004828:	02d76863          	bltu	a4,a3,80004858 <fileread+0xba>
    8000482c:	0792                	slli	a5,a5,0x4
    8000482e:	0001c717          	auipc	a4,0x1c
    80004832:	5da70713          	addi	a4,a4,1498 # 80020e08 <devsw>
    80004836:	97ba                	add	a5,a5,a4
    80004838:	639c                	ld	a5,0(a5)
    8000483a:	c38d                	beqz	a5,8000485c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000483c:	4505                	li	a0,1
    8000483e:	9782                	jalr	a5
    80004840:	892a                	mv	s2,a0
    80004842:	bf75                	j	800047fe <fileread+0x60>
    panic("fileread");
    80004844:	00004517          	auipc	a0,0x4
    80004848:	ec450513          	addi	a0,a0,-316 # 80008708 <syscalls+0x278>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	cf2080e7          	jalr	-782(ra) # 8000053e <panic>
    return -1;
    80004854:	597d                	li	s2,-1
    80004856:	b765                	j	800047fe <fileread+0x60>
      return -1;
    80004858:	597d                	li	s2,-1
    8000485a:	b755                	j	800047fe <fileread+0x60>
    8000485c:	597d                	li	s2,-1
    8000485e:	b745                	j	800047fe <fileread+0x60>

0000000080004860 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004860:	715d                	addi	sp,sp,-80
    80004862:	e486                	sd	ra,72(sp)
    80004864:	e0a2                	sd	s0,64(sp)
    80004866:	fc26                	sd	s1,56(sp)
    80004868:	f84a                	sd	s2,48(sp)
    8000486a:	f44e                	sd	s3,40(sp)
    8000486c:	f052                	sd	s4,32(sp)
    8000486e:	ec56                	sd	s5,24(sp)
    80004870:	e85a                	sd	s6,16(sp)
    80004872:	e45e                	sd	s7,8(sp)
    80004874:	e062                	sd	s8,0(sp)
    80004876:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004878:	00954783          	lbu	a5,9(a0)
    8000487c:	10078663          	beqz	a5,80004988 <filewrite+0x128>
    80004880:	892a                	mv	s2,a0
    80004882:	8aae                	mv	s5,a1
    80004884:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004886:	411c                	lw	a5,0(a0)
    80004888:	4705                	li	a4,1
    8000488a:	02e78263          	beq	a5,a4,800048ae <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000488e:	470d                	li	a4,3
    80004890:	02e78663          	beq	a5,a4,800048bc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004894:	4709                	li	a4,2
    80004896:	0ee79163          	bne	a5,a4,80004978 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000489a:	0ac05d63          	blez	a2,80004954 <filewrite+0xf4>
    int i = 0;
    8000489e:	4981                	li	s3,0
    800048a0:	6b05                	lui	s6,0x1
    800048a2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048a6:	6b85                	lui	s7,0x1
    800048a8:	c00b8b9b          	addiw	s7,s7,-1024
    800048ac:	a861                	j	80004944 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048ae:	6908                	ld	a0,16(a0)
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	22e080e7          	jalr	558(ra) # 80004ade <pipewrite>
    800048b8:	8a2a                	mv	s4,a0
    800048ba:	a045                	j	8000495a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048bc:	02451783          	lh	a5,36(a0)
    800048c0:	03079693          	slli	a3,a5,0x30
    800048c4:	92c1                	srli	a3,a3,0x30
    800048c6:	4725                	li	a4,9
    800048c8:	0cd76263          	bltu	a4,a3,8000498c <filewrite+0x12c>
    800048cc:	0792                	slli	a5,a5,0x4
    800048ce:	0001c717          	auipc	a4,0x1c
    800048d2:	53a70713          	addi	a4,a4,1338 # 80020e08 <devsw>
    800048d6:	97ba                	add	a5,a5,a4
    800048d8:	679c                	ld	a5,8(a5)
    800048da:	cbdd                	beqz	a5,80004990 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048dc:	4505                	li	a0,1
    800048de:	9782                	jalr	a5
    800048e0:	8a2a                	mv	s4,a0
    800048e2:	a8a5                	j	8000495a <filewrite+0xfa>
    800048e4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	8b0080e7          	jalr	-1872(ra) # 80004198 <begin_op>
      ilock(f->ip);
    800048f0:	01893503          	ld	a0,24(s2)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	ee2080e7          	jalr	-286(ra) # 800037d6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048fc:	8762                	mv	a4,s8
    800048fe:	02092683          	lw	a3,32(s2)
    80004902:	01598633          	add	a2,s3,s5
    80004906:	4585                	li	a1,1
    80004908:	01893503          	ld	a0,24(s2)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	276080e7          	jalr	630(ra) # 80003b82 <writei>
    80004914:	84aa                	mv	s1,a0
    80004916:	00a05763          	blez	a0,80004924 <filewrite+0xc4>
        f->off += r;
    8000491a:	02092783          	lw	a5,32(s2)
    8000491e:	9fa9                	addw	a5,a5,a0
    80004920:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004924:	01893503          	ld	a0,24(s2)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	f70080e7          	jalr	-144(ra) # 80003898 <iunlock>
      end_op();
    80004930:	00000097          	auipc	ra,0x0
    80004934:	8e8080e7          	jalr	-1816(ra) # 80004218 <end_op>

      if(r != n1){
    80004938:	009c1f63          	bne	s8,s1,80004956 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000493c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004940:	0149db63          	bge	s3,s4,80004956 <filewrite+0xf6>
      int n1 = n - i;
    80004944:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004948:	84be                	mv	s1,a5
    8000494a:	2781                	sext.w	a5,a5
    8000494c:	f8fb5ce3          	bge	s6,a5,800048e4 <filewrite+0x84>
    80004950:	84de                	mv	s1,s7
    80004952:	bf49                	j	800048e4 <filewrite+0x84>
    int i = 0;
    80004954:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004956:	013a1f63          	bne	s4,s3,80004974 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000495a:	8552                	mv	a0,s4
    8000495c:	60a6                	ld	ra,72(sp)
    8000495e:	6406                	ld	s0,64(sp)
    80004960:	74e2                	ld	s1,56(sp)
    80004962:	7942                	ld	s2,48(sp)
    80004964:	79a2                	ld	s3,40(sp)
    80004966:	7a02                	ld	s4,32(sp)
    80004968:	6ae2                	ld	s5,24(sp)
    8000496a:	6b42                	ld	s6,16(sp)
    8000496c:	6ba2                	ld	s7,8(sp)
    8000496e:	6c02                	ld	s8,0(sp)
    80004970:	6161                	addi	sp,sp,80
    80004972:	8082                	ret
    ret = (i == n ? n : -1);
    80004974:	5a7d                	li	s4,-1
    80004976:	b7d5                	j	8000495a <filewrite+0xfa>
    panic("filewrite");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	da050513          	addi	a0,a0,-608 # 80008718 <syscalls+0x288>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>
    return -1;
    80004988:	5a7d                	li	s4,-1
    8000498a:	bfc1                	j	8000495a <filewrite+0xfa>
      return -1;
    8000498c:	5a7d                	li	s4,-1
    8000498e:	b7f1                	j	8000495a <filewrite+0xfa>
    80004990:	5a7d                	li	s4,-1
    80004992:	b7e1                	j	8000495a <filewrite+0xfa>

0000000080004994 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004994:	7179                	addi	sp,sp,-48
    80004996:	f406                	sd	ra,40(sp)
    80004998:	f022                	sd	s0,32(sp)
    8000499a:	ec26                	sd	s1,24(sp)
    8000499c:	e84a                	sd	s2,16(sp)
    8000499e:	e44e                	sd	s3,8(sp)
    800049a0:	e052                	sd	s4,0(sp)
    800049a2:	1800                	addi	s0,sp,48
    800049a4:	84aa                	mv	s1,a0
    800049a6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049a8:	0005b023          	sd	zero,0(a1)
    800049ac:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	bf8080e7          	jalr	-1032(ra) # 800045a8 <filealloc>
    800049b8:	e088                	sd	a0,0(s1)
    800049ba:	c551                	beqz	a0,80004a46 <pipealloc+0xb2>
    800049bc:	00000097          	auipc	ra,0x0
    800049c0:	bec080e7          	jalr	-1044(ra) # 800045a8 <filealloc>
    800049c4:	00aa3023          	sd	a0,0(s4)
    800049c8:	c92d                	beqz	a0,80004a3a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	11c080e7          	jalr	284(ra) # 80000ae6 <kalloc>
    800049d2:	892a                	mv	s2,a0
    800049d4:	c125                	beqz	a0,80004a34 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049d6:	4985                	li	s3,1
    800049d8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049dc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049e0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049e4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e8:	00004597          	auipc	a1,0x4
    800049ec:	d4058593          	addi	a1,a1,-704 # 80008728 <syscalls+0x298>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	156080e7          	jalr	342(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049f8:	609c                	ld	a5,0(s1)
    800049fa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049fe:	609c                	ld	a5,0(s1)
    80004a00:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a04:	609c                	ld	a5,0(s1)
    80004a06:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a0a:	609c                	ld	a5,0(s1)
    80004a0c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a10:	000a3783          	ld	a5,0(s4)
    80004a14:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a18:	000a3783          	ld	a5,0(s4)
    80004a1c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a20:	000a3783          	ld	a5,0(s4)
    80004a24:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a28:	000a3783          	ld	a5,0(s4)
    80004a2c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a30:	4501                	li	a0,0
    80004a32:	a025                	j	80004a5a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a34:	6088                	ld	a0,0(s1)
    80004a36:	e501                	bnez	a0,80004a3e <pipealloc+0xaa>
    80004a38:	a039                	j	80004a46 <pipealloc+0xb2>
    80004a3a:	6088                	ld	a0,0(s1)
    80004a3c:	c51d                	beqz	a0,80004a6a <pipealloc+0xd6>
    fileclose(*f0);
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	c26080e7          	jalr	-986(ra) # 80004664 <fileclose>
  if(*f1)
    80004a46:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a4a:	557d                	li	a0,-1
  if(*f1)
    80004a4c:	c799                	beqz	a5,80004a5a <pipealloc+0xc6>
    fileclose(*f1);
    80004a4e:	853e                	mv	a0,a5
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	c14080e7          	jalr	-1004(ra) # 80004664 <fileclose>
  return -1;
    80004a58:	557d                	li	a0,-1
}
    80004a5a:	70a2                	ld	ra,40(sp)
    80004a5c:	7402                	ld	s0,32(sp)
    80004a5e:	64e2                	ld	s1,24(sp)
    80004a60:	6942                	ld	s2,16(sp)
    80004a62:	69a2                	ld	s3,8(sp)
    80004a64:	6a02                	ld	s4,0(sp)
    80004a66:	6145                	addi	sp,sp,48
    80004a68:	8082                	ret
  return -1;
    80004a6a:	557d                	li	a0,-1
    80004a6c:	b7fd                	j	80004a5a <pipealloc+0xc6>

0000000080004a6e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a6e:	1101                	addi	sp,sp,-32
    80004a70:	ec06                	sd	ra,24(sp)
    80004a72:	e822                	sd	s0,16(sp)
    80004a74:	e426                	sd	s1,8(sp)
    80004a76:	e04a                	sd	s2,0(sp)
    80004a78:	1000                	addi	s0,sp,32
    80004a7a:	84aa                	mv	s1,a0
    80004a7c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	158080e7          	jalr	344(ra) # 80000bd6 <acquire>
  if(writable){
    80004a86:	02090d63          	beqz	s2,80004ac0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a8a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a8e:	21848513          	addi	a0,s1,536
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	632080e7          	jalr	1586(ra) # 800020c4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a9a:	2204b783          	ld	a5,544(s1)
    80004a9e:	eb95                	bnez	a5,80004ad2 <pipeclose+0x64>
    release(&pi->lock);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	1e8080e7          	jalr	488(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	f3e080e7          	jalr	-194(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	64a2                	ld	s1,8(sp)
    80004aba:	6902                	ld	s2,0(sp)
    80004abc:	6105                	addi	sp,sp,32
    80004abe:	8082                	ret
    pi->readopen = 0;
    80004ac0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ac4:	21c48513          	addi	a0,s1,540
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	5fc080e7          	jalr	1532(ra) # 800020c4 <wakeup>
    80004ad0:	b7e9                	j	80004a9a <pipeclose+0x2c>
    release(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1b6080e7          	jalr	438(ra) # 80000c8a <release>
}
    80004adc:	bfe1                	j	80004ab4 <pipeclose+0x46>

0000000080004ade <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ade:	711d                	addi	sp,sp,-96
    80004ae0:	ec86                	sd	ra,88(sp)
    80004ae2:	e8a2                	sd	s0,80(sp)
    80004ae4:	e4a6                	sd	s1,72(sp)
    80004ae6:	e0ca                	sd	s2,64(sp)
    80004ae8:	fc4e                	sd	s3,56(sp)
    80004aea:	f852                	sd	s4,48(sp)
    80004aec:	f456                	sd	s5,40(sp)
    80004aee:	f05a                	sd	s6,32(sp)
    80004af0:	ec5e                	sd	s7,24(sp)
    80004af2:	e862                	sd	s8,16(sp)
    80004af4:	1080                	addi	s0,sp,96
    80004af6:	84aa                	mv	s1,a0
    80004af8:	8aae                	mv	s5,a1
    80004afa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	eb0080e7          	jalr	-336(ra) # 800019ac <myproc>
    80004b04:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	0ce080e7          	jalr	206(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b10:	0b405663          	blez	s4,80004bbc <pipewrite+0xde>
  int i = 0;
    80004b14:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b16:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b18:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b1c:	21c48b93          	addi	s7,s1,540
    80004b20:	a089                	j	80004b62 <pipewrite+0x84>
      release(&pi->lock);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	166080e7          	jalr	358(ra) # 80000c8a <release>
      return -1;
    80004b2c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b2e:	854a                	mv	a0,s2
    80004b30:	60e6                	ld	ra,88(sp)
    80004b32:	6446                	ld	s0,80(sp)
    80004b34:	64a6                	ld	s1,72(sp)
    80004b36:	6906                	ld	s2,64(sp)
    80004b38:	79e2                	ld	s3,56(sp)
    80004b3a:	7a42                	ld	s4,48(sp)
    80004b3c:	7aa2                	ld	s5,40(sp)
    80004b3e:	7b02                	ld	s6,32(sp)
    80004b40:	6be2                	ld	s7,24(sp)
    80004b42:	6c42                	ld	s8,16(sp)
    80004b44:	6125                	addi	sp,sp,96
    80004b46:	8082                	ret
      wakeup(&pi->nread);
    80004b48:	8562                	mv	a0,s8
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	57a080e7          	jalr	1402(ra) # 800020c4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b52:	85a6                	mv	a1,s1
    80004b54:	855e                	mv	a0,s7
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	50a080e7          	jalr	1290(ra) # 80002060 <sleep>
  while(i < n){
    80004b5e:	07495063          	bge	s2,s4,80004bbe <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b62:	2204a783          	lw	a5,544(s1)
    80004b66:	dfd5                	beqz	a5,80004b22 <pipewrite+0x44>
    80004b68:	854e                	mv	a0,s3
    80004b6a:	ffffd097          	auipc	ra,0xffffd
    80004b6e:	79e080e7          	jalr	1950(ra) # 80002308 <killed>
    80004b72:	f945                	bnez	a0,80004b22 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b74:	2184a783          	lw	a5,536(s1)
    80004b78:	21c4a703          	lw	a4,540(s1)
    80004b7c:	2007879b          	addiw	a5,a5,512
    80004b80:	fcf704e3          	beq	a4,a5,80004b48 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b84:	4685                	li	a3,1
    80004b86:	01590633          	add	a2,s2,s5
    80004b8a:	faf40593          	addi	a1,s0,-81
    80004b8e:	0509b503          	ld	a0,80(s3)
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	b62080e7          	jalr	-1182(ra) # 800016f4 <copyin>
    80004b9a:	03650263          	beq	a0,s6,80004bbe <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b9e:	21c4a783          	lw	a5,540(s1)
    80004ba2:	0017871b          	addiw	a4,a5,1
    80004ba6:	20e4ae23          	sw	a4,540(s1)
    80004baa:	1ff7f793          	andi	a5,a5,511
    80004bae:	97a6                	add	a5,a5,s1
    80004bb0:	faf44703          	lbu	a4,-81(s0)
    80004bb4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bb8:	2905                	addiw	s2,s2,1
    80004bba:	b755                	j	80004b5e <pipewrite+0x80>
  int i = 0;
    80004bbc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004bbe:	21848513          	addi	a0,s1,536
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	502080e7          	jalr	1282(ra) # 800020c4 <wakeup>
  release(&pi->lock);
    80004bca:	8526                	mv	a0,s1
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	0be080e7          	jalr	190(ra) # 80000c8a <release>
  return i;
    80004bd4:	bfa9                	j	80004b2e <pipewrite+0x50>

0000000080004bd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bd6:	715d                	addi	sp,sp,-80
    80004bd8:	e486                	sd	ra,72(sp)
    80004bda:	e0a2                	sd	s0,64(sp)
    80004bdc:	fc26                	sd	s1,56(sp)
    80004bde:	f84a                	sd	s2,48(sp)
    80004be0:	f44e                	sd	s3,40(sp)
    80004be2:	f052                	sd	s4,32(sp)
    80004be4:	ec56                	sd	s5,24(sp)
    80004be6:	e85a                	sd	s6,16(sp)
    80004be8:	0880                	addi	s0,sp,80
    80004bea:	84aa                	mv	s1,a0
    80004bec:	892e                	mv	s2,a1
    80004bee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	dbc080e7          	jalr	-580(ra) # 800019ac <myproc>
    80004bf8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fda080e7          	jalr	-38(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	2184a703          	lw	a4,536(s1)
    80004c08:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c10:	02f71763          	bne	a4,a5,80004c3e <piperead+0x68>
    80004c14:	2244a783          	lw	a5,548(s1)
    80004c18:	c39d                	beqz	a5,80004c3e <piperead+0x68>
    if(killed(pr)){
    80004c1a:	8552                	mv	a0,s4
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	6ec080e7          	jalr	1772(ra) # 80002308 <killed>
    80004c24:	e941                	bnez	a0,80004cb4 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c26:	85a6                	mv	a1,s1
    80004c28:	854e                	mv	a0,s3
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	436080e7          	jalr	1078(ra) # 80002060 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	2184a703          	lw	a4,536(s1)
    80004c36:	21c4a783          	lw	a5,540(s1)
    80004c3a:	fcf70de3          	beq	a4,a5,80004c14 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c3e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c40:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c42:	05505363          	blez	s5,80004c88 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004c46:	2184a783          	lw	a5,536(s1)
    80004c4a:	21c4a703          	lw	a4,540(s1)
    80004c4e:	02f70d63          	beq	a4,a5,80004c88 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ac23          	sw	a4,536(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	0187c783          	lbu	a5,24(a5)
    80004c64:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c68:	4685                	li	a3,1
    80004c6a:	fbf40613          	addi	a2,s0,-65
    80004c6e:	85ca                	mv	a1,s2
    80004c70:	050a3503          	ld	a0,80(s4)
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	9f4080e7          	jalr	-1548(ra) # 80001668 <copyout>
    80004c7c:	01650663          	beq	a0,s6,80004c88 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c80:	2985                	addiw	s3,s3,1
    80004c82:	0905                	addi	s2,s2,1
    80004c84:	fd3a91e3          	bne	s5,s3,80004c46 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c88:	21c48513          	addi	a0,s1,540
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	438080e7          	jalr	1080(ra) # 800020c4 <wakeup>
  release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
  return i;
}
    80004c9e:	854e                	mv	a0,s3
    80004ca0:	60a6                	ld	ra,72(sp)
    80004ca2:	6406                	ld	s0,64(sp)
    80004ca4:	74e2                	ld	s1,56(sp)
    80004ca6:	7942                	ld	s2,48(sp)
    80004ca8:	79a2                	ld	s3,40(sp)
    80004caa:	7a02                	ld	s4,32(sp)
    80004cac:	6ae2                	ld	s5,24(sp)
    80004cae:	6b42                	ld	s6,16(sp)
    80004cb0:	6161                	addi	sp,sp,80
    80004cb2:	8082                	ret
      release(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	fd4080e7          	jalr	-44(ra) # 80000c8a <release>
      return -1;
    80004cbe:	59fd                	li	s3,-1
    80004cc0:	bff9                	j	80004c9e <piperead+0xc8>

0000000080004cc2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cc2:	1141                	addi	sp,sp,-16
    80004cc4:	e422                	sd	s0,8(sp)
    80004cc6:	0800                	addi	s0,sp,16
    80004cc8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cca:	8905                	andi	a0,a0,1
    80004ccc:	c111                	beqz	a0,80004cd0 <flags2perm+0xe>
      perm = PTE_X;
    80004cce:	4521                	li	a0,8
    if(flags & 0x2)
    80004cd0:	8b89                	andi	a5,a5,2
    80004cd2:	c399                	beqz	a5,80004cd8 <flags2perm+0x16>
      perm |= PTE_W;
    80004cd4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cd8:	6422                	ld	s0,8(sp)
    80004cda:	0141                	addi	sp,sp,16
    80004cdc:	8082                	ret

0000000080004cde <exec>:

int
exec(char *path, char **argv)
{
    80004cde:	de010113          	addi	sp,sp,-544
    80004ce2:	20113c23          	sd	ra,536(sp)
    80004ce6:	20813823          	sd	s0,528(sp)
    80004cea:	20913423          	sd	s1,520(sp)
    80004cee:	21213023          	sd	s2,512(sp)
    80004cf2:	ffce                	sd	s3,504(sp)
    80004cf4:	fbd2                	sd	s4,496(sp)
    80004cf6:	f7d6                	sd	s5,488(sp)
    80004cf8:	f3da                	sd	s6,480(sp)
    80004cfa:	efde                	sd	s7,472(sp)
    80004cfc:	ebe2                	sd	s8,464(sp)
    80004cfe:	e7e6                	sd	s9,456(sp)
    80004d00:	e3ea                	sd	s10,448(sp)
    80004d02:	ff6e                	sd	s11,440(sp)
    80004d04:	1400                	addi	s0,sp,544
    80004d06:	892a                	mv	s2,a0
    80004d08:	dea43423          	sd	a0,-536(s0)
    80004d0c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	c9c080e7          	jalr	-868(ra) # 800019ac <myproc>
    80004d18:	84aa                	mv	s1,a0

  begin_op();
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	47e080e7          	jalr	1150(ra) # 80004198 <begin_op>

  if((ip = namei(path)) == 0){
    80004d22:	854a                	mv	a0,s2
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	258080e7          	jalr	600(ra) # 80003f7c <namei>
    80004d2c:	c93d                	beqz	a0,80004da2 <exec+0xc4>
    80004d2e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	aa6080e7          	jalr	-1370(ra) # 800037d6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d38:	04000713          	li	a4,64
    80004d3c:	4681                	li	a3,0
    80004d3e:	e5040613          	addi	a2,s0,-432
    80004d42:	4581                	li	a1,0
    80004d44:	8556                	mv	a0,s5
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	d44080e7          	jalr	-700(ra) # 80003a8a <readi>
    80004d4e:	04000793          	li	a5,64
    80004d52:	00f51a63          	bne	a0,a5,80004d66 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d56:	e5042703          	lw	a4,-432(s0)
    80004d5a:	464c47b7          	lui	a5,0x464c4
    80004d5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d62:	04f70663          	beq	a4,a5,80004dae <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d66:	8556                	mv	a0,s5
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	cd0080e7          	jalr	-816(ra) # 80003a38 <iunlockput>
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	4a8080e7          	jalr	1192(ra) # 80004218 <end_op>
  }
  return -1;
    80004d78:	557d                	li	a0,-1
}
    80004d7a:	21813083          	ld	ra,536(sp)
    80004d7e:	21013403          	ld	s0,528(sp)
    80004d82:	20813483          	ld	s1,520(sp)
    80004d86:	20013903          	ld	s2,512(sp)
    80004d8a:	79fe                	ld	s3,504(sp)
    80004d8c:	7a5e                	ld	s4,496(sp)
    80004d8e:	7abe                	ld	s5,488(sp)
    80004d90:	7b1e                	ld	s6,480(sp)
    80004d92:	6bfe                	ld	s7,472(sp)
    80004d94:	6c5e                	ld	s8,464(sp)
    80004d96:	6cbe                	ld	s9,456(sp)
    80004d98:	6d1e                	ld	s10,448(sp)
    80004d9a:	7dfa                	ld	s11,440(sp)
    80004d9c:	22010113          	addi	sp,sp,544
    80004da0:	8082                	ret
    end_op();
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	476080e7          	jalr	1142(ra) # 80004218 <end_op>
    return -1;
    80004daa:	557d                	li	a0,-1
    80004dac:	b7f9                	j	80004d7a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	cc0080e7          	jalr	-832(ra) # 80001a70 <proc_pagetable>
    80004db8:	8b2a                	mv	s6,a0
    80004dba:	d555                	beqz	a0,80004d66 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dbc:	e7042783          	lw	a5,-400(s0)
    80004dc0:	e8845703          	lhu	a4,-376(s0)
    80004dc4:	c735                	beqz	a4,80004e30 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dcc:	6a05                	lui	s4,0x1
    80004dce:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dd2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dd6:	6d85                	lui	s11,0x1
    80004dd8:	7d7d                	lui	s10,0xfffff
    80004dda:	a481                	j	8000501a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ddc:	00004517          	auipc	a0,0x4
    80004de0:	95450513          	addi	a0,a0,-1708 # 80008730 <syscalls+0x2a0>
    80004de4:	ffffb097          	auipc	ra,0xffffb
    80004de8:	75a080e7          	jalr	1882(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dec:	874a                	mv	a4,s2
    80004dee:	009c86bb          	addw	a3,s9,s1
    80004df2:	4581                	li	a1,0
    80004df4:	8556                	mv	a0,s5
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	c94080e7          	jalr	-876(ra) # 80003a8a <readi>
    80004dfe:	2501                	sext.w	a0,a0
    80004e00:	1aa91a63          	bne	s2,a0,80004fb4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e04:	009d84bb          	addw	s1,s11,s1
    80004e08:	013d09bb          	addw	s3,s10,s3
    80004e0c:	1f74f763          	bgeu	s1,s7,80004ffa <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004e10:	02049593          	slli	a1,s1,0x20
    80004e14:	9181                	srli	a1,a1,0x20
    80004e16:	95e2                	add	a1,a1,s8
    80004e18:	855a                	mv	a0,s6
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	242080e7          	jalr	578(ra) # 8000105c <walkaddr>
    80004e22:	862a                	mv	a2,a0
    if(pa == 0)
    80004e24:	dd45                	beqz	a0,80004ddc <exec+0xfe>
      n = PGSIZE;
    80004e26:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e28:	fd49f2e3          	bgeu	s3,s4,80004dec <exec+0x10e>
      n = sz - i;
    80004e2c:	894e                	mv	s2,s3
    80004e2e:	bf7d                	j	80004dec <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e30:	4901                	li	s2,0
  iunlockput(ip);
    80004e32:	8556                	mv	a0,s5
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	c04080e7          	jalr	-1020(ra) # 80003a38 <iunlockput>
  end_op();
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	3dc080e7          	jalr	988(ra) # 80004218 <end_op>
  p = myproc();
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	b68080e7          	jalr	-1176(ra) # 800019ac <myproc>
    80004e4c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e4e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e52:	6785                	lui	a5,0x1
    80004e54:	17fd                	addi	a5,a5,-1
    80004e56:	993e                	add	s2,s2,a5
    80004e58:	77fd                	lui	a5,0xfffff
    80004e5a:	00f977b3          	and	a5,s2,a5
    80004e5e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e62:	4691                	li	a3,4
    80004e64:	6609                	lui	a2,0x2
    80004e66:	963e                	add	a2,a2,a5
    80004e68:	85be                	mv	a1,a5
    80004e6a:	855a                	mv	a0,s6
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	5a4080e7          	jalr	1444(ra) # 80001410 <uvmalloc>
    80004e74:	8c2a                	mv	s8,a0
  ip = 0;
    80004e76:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e78:	12050e63          	beqz	a0,80004fb4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e7c:	75f9                	lui	a1,0xffffe
    80004e7e:	95aa                	add	a1,a1,a0
    80004e80:	855a                	mv	a0,s6
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	7b4080e7          	jalr	1972(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e8a:	7afd                	lui	s5,0xfffff
    80004e8c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e8e:	df043783          	ld	a5,-528(s0)
    80004e92:	6388                	ld	a0,0(a5)
    80004e94:	c925                	beqz	a0,80004f04 <exec+0x226>
    80004e96:	e9040993          	addi	s3,s0,-368
    80004e9a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e9e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ea0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	fac080e7          	jalr	-84(ra) # 80000e4e <strlen>
    80004eaa:	0015079b          	addiw	a5,a0,1
    80004eae:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eb2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eb6:	13596663          	bltu	s2,s5,80004fe2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eba:	df043d83          	ld	s11,-528(s0)
    80004ebe:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	f8a080e7          	jalr	-118(ra) # 80000e4e <strlen>
    80004ecc:	0015069b          	addiw	a3,a0,1
    80004ed0:	8652                	mv	a2,s4
    80004ed2:	85ca                	mv	a1,s2
    80004ed4:	855a                	mv	a0,s6
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	792080e7          	jalr	1938(ra) # 80001668 <copyout>
    80004ede:	10054663          	bltz	a0,80004fea <exec+0x30c>
    ustack[argc] = sp;
    80004ee2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ee6:	0485                	addi	s1,s1,1
    80004ee8:	008d8793          	addi	a5,s11,8
    80004eec:	def43823          	sd	a5,-528(s0)
    80004ef0:	008db503          	ld	a0,8(s11)
    80004ef4:	c911                	beqz	a0,80004f08 <exec+0x22a>
    if(argc >= MAXARG)
    80004ef6:	09a1                	addi	s3,s3,8
    80004ef8:	fb3c95e3          	bne	s9,s3,80004ea2 <exec+0x1c4>
  sz = sz1;
    80004efc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f00:	4a81                	li	s5,0
    80004f02:	a84d                	j	80004fb4 <exec+0x2d6>
  sp = sz;
    80004f04:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f06:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f08:	00349793          	slli	a5,s1,0x3
    80004f0c:	f9040713          	addi	a4,s0,-112
    80004f10:	97ba                	add	a5,a5,a4
    80004f12:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcf60>
  sp -= (argc+1) * sizeof(uint64);
    80004f16:	00148693          	addi	a3,s1,1
    80004f1a:	068e                	slli	a3,a3,0x3
    80004f1c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f20:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f24:	01597663          	bgeu	s2,s5,80004f30 <exec+0x252>
  sz = sz1;
    80004f28:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f2c:	4a81                	li	s5,0
    80004f2e:	a059                	j	80004fb4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f30:	e9040613          	addi	a2,s0,-368
    80004f34:	85ca                	mv	a1,s2
    80004f36:	855a                	mv	a0,s6
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	730080e7          	jalr	1840(ra) # 80001668 <copyout>
    80004f40:	0a054963          	bltz	a0,80004ff2 <exec+0x314>
  p->trapframe->a1 = sp;
    80004f44:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f48:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f4c:	de843783          	ld	a5,-536(s0)
    80004f50:	0007c703          	lbu	a4,0(a5)
    80004f54:	cf11                	beqz	a4,80004f70 <exec+0x292>
    80004f56:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f58:	02f00693          	li	a3,47
    80004f5c:	a039                	j	80004f6a <exec+0x28c>
      last = s+1;
    80004f5e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f62:	0785                	addi	a5,a5,1
    80004f64:	fff7c703          	lbu	a4,-1(a5)
    80004f68:	c701                	beqz	a4,80004f70 <exec+0x292>
    if(*s == '/')
    80004f6a:	fed71ce3          	bne	a4,a3,80004f62 <exec+0x284>
    80004f6e:	bfc5                	j	80004f5e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f70:	4641                	li	a2,16
    80004f72:	de843583          	ld	a1,-536(s0)
    80004f76:	158b8513          	addi	a0,s7,344
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	ea2080e7          	jalr	-350(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f82:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f86:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f8a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f8e:	058bb783          	ld	a5,88(s7)
    80004f92:	e6843703          	ld	a4,-408(s0)
    80004f96:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f98:	058bb783          	ld	a5,88(s7)
    80004f9c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fa0:	85ea                	mv	a1,s10
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	b6a080e7          	jalr	-1174(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004faa:	0004851b          	sext.w	a0,s1
    80004fae:	b3f1                	j	80004d7a <exec+0x9c>
    80004fb0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fb4:	df843583          	ld	a1,-520(s0)
    80004fb8:	855a                	mv	a0,s6
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	b52080e7          	jalr	-1198(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004fc2:	da0a92e3          	bnez	s5,80004d66 <exec+0x88>
  return -1;
    80004fc6:	557d                	li	a0,-1
    80004fc8:	bb4d                	j	80004d7a <exec+0x9c>
    80004fca:	df243c23          	sd	s2,-520(s0)
    80004fce:	b7dd                	j	80004fb4 <exec+0x2d6>
    80004fd0:	df243c23          	sd	s2,-520(s0)
    80004fd4:	b7c5                	j	80004fb4 <exec+0x2d6>
    80004fd6:	df243c23          	sd	s2,-520(s0)
    80004fda:	bfe9                	j	80004fb4 <exec+0x2d6>
    80004fdc:	df243c23          	sd	s2,-520(s0)
    80004fe0:	bfd1                	j	80004fb4 <exec+0x2d6>
  sz = sz1;
    80004fe2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe6:	4a81                	li	s5,0
    80004fe8:	b7f1                	j	80004fb4 <exec+0x2d6>
  sz = sz1;
    80004fea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fee:	4a81                	li	s5,0
    80004ff0:	b7d1                	j	80004fb4 <exec+0x2d6>
  sz = sz1;
    80004ff2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ff6:	4a81                	li	s5,0
    80004ff8:	bf75                	j	80004fb4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ffa:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ffe:	e0843783          	ld	a5,-504(s0)
    80005002:	0017869b          	addiw	a3,a5,1
    80005006:	e0d43423          	sd	a3,-504(s0)
    8000500a:	e0043783          	ld	a5,-512(s0)
    8000500e:	0387879b          	addiw	a5,a5,56
    80005012:	e8845703          	lhu	a4,-376(s0)
    80005016:	e0e6dee3          	bge	a3,a4,80004e32 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000501a:	2781                	sext.w	a5,a5
    8000501c:	e0f43023          	sd	a5,-512(s0)
    80005020:	03800713          	li	a4,56
    80005024:	86be                	mv	a3,a5
    80005026:	e1840613          	addi	a2,s0,-488
    8000502a:	4581                	li	a1,0
    8000502c:	8556                	mv	a0,s5
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	a5c080e7          	jalr	-1444(ra) # 80003a8a <readi>
    80005036:	03800793          	li	a5,56
    8000503a:	f6f51be3          	bne	a0,a5,80004fb0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000503e:	e1842783          	lw	a5,-488(s0)
    80005042:	4705                	li	a4,1
    80005044:	fae79de3          	bne	a5,a4,80004ffe <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005048:	e4043483          	ld	s1,-448(s0)
    8000504c:	e3843783          	ld	a5,-456(s0)
    80005050:	f6f4ede3          	bltu	s1,a5,80004fca <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005054:	e2843783          	ld	a5,-472(s0)
    80005058:	94be                	add	s1,s1,a5
    8000505a:	f6f4ebe3          	bltu	s1,a5,80004fd0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000505e:	de043703          	ld	a4,-544(s0)
    80005062:	8ff9                	and	a5,a5,a4
    80005064:	fbad                	bnez	a5,80004fd6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005066:	e1c42503          	lw	a0,-484(s0)
    8000506a:	00000097          	auipc	ra,0x0
    8000506e:	c58080e7          	jalr	-936(ra) # 80004cc2 <flags2perm>
    80005072:	86aa                	mv	a3,a0
    80005074:	8626                	mv	a2,s1
    80005076:	85ca                	mv	a1,s2
    80005078:	855a                	mv	a0,s6
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	396080e7          	jalr	918(ra) # 80001410 <uvmalloc>
    80005082:	dea43c23          	sd	a0,-520(s0)
    80005086:	d939                	beqz	a0,80004fdc <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005088:	e2843c03          	ld	s8,-472(s0)
    8000508c:	e2042c83          	lw	s9,-480(s0)
    80005090:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005094:	f60b83e3          	beqz	s7,80004ffa <exec+0x31c>
    80005098:	89de                	mv	s3,s7
    8000509a:	4481                	li	s1,0
    8000509c:	bb95                	j	80004e10 <exec+0x132>

000000008000509e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000509e:	7179                	addi	sp,sp,-48
    800050a0:	f406                	sd	ra,40(sp)
    800050a2:	f022                	sd	s0,32(sp)
    800050a4:	ec26                	sd	s1,24(sp)
    800050a6:	e84a                	sd	s2,16(sp)
    800050a8:	1800                	addi	s0,sp,48
    800050aa:	892e                	mv	s2,a1
    800050ac:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050ae:	fdc40593          	addi	a1,s0,-36
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	b44080e7          	jalr	-1212(ra) # 80002bf6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ba:	fdc42703          	lw	a4,-36(s0)
    800050be:	47bd                	li	a5,15
    800050c0:	02e7eb63          	bltu	a5,a4,800050f6 <argfd+0x58>
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	8e8080e7          	jalr	-1816(ra) # 800019ac <myproc>
    800050cc:	fdc42703          	lw	a4,-36(s0)
    800050d0:	01a70793          	addi	a5,a4,26
    800050d4:	078e                	slli	a5,a5,0x3
    800050d6:	953e                	add	a0,a0,a5
    800050d8:	611c                	ld	a5,0(a0)
    800050da:	c385                	beqz	a5,800050fa <argfd+0x5c>
    return -1;
  if(pfd)
    800050dc:	00090463          	beqz	s2,800050e4 <argfd+0x46>
    *pfd = fd;
    800050e0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050e4:	4501                	li	a0,0
  if(pf)
    800050e6:	c091                	beqz	s1,800050ea <argfd+0x4c>
    *pf = f;
    800050e8:	e09c                	sd	a5,0(s1)
}
    800050ea:	70a2                	ld	ra,40(sp)
    800050ec:	7402                	ld	s0,32(sp)
    800050ee:	64e2                	ld	s1,24(sp)
    800050f0:	6942                	ld	s2,16(sp)
    800050f2:	6145                	addi	sp,sp,48
    800050f4:	8082                	ret
    return -1;
    800050f6:	557d                	li	a0,-1
    800050f8:	bfcd                	j	800050ea <argfd+0x4c>
    800050fa:	557d                	li	a0,-1
    800050fc:	b7fd                	j	800050ea <argfd+0x4c>

00000000800050fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050fe:	1101                	addi	sp,sp,-32
    80005100:	ec06                	sd	ra,24(sp)
    80005102:	e822                	sd	s0,16(sp)
    80005104:	e426                	sd	s1,8(sp)
    80005106:	1000                	addi	s0,sp,32
    80005108:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	8a2080e7          	jalr	-1886(ra) # 800019ac <myproc>
    80005112:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005114:	0d050793          	addi	a5,a0,208
    80005118:	4501                	li	a0,0
    8000511a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000511c:	6398                	ld	a4,0(a5)
    8000511e:	cb19                	beqz	a4,80005134 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005120:	2505                	addiw	a0,a0,1
    80005122:	07a1                	addi	a5,a5,8
    80005124:	fed51ce3          	bne	a0,a3,8000511c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005128:	557d                	li	a0,-1
}
    8000512a:	60e2                	ld	ra,24(sp)
    8000512c:	6442                	ld	s0,16(sp)
    8000512e:	64a2                	ld	s1,8(sp)
    80005130:	6105                	addi	sp,sp,32
    80005132:	8082                	ret
      p->ofile[fd] = f;
    80005134:	01a50793          	addi	a5,a0,26
    80005138:	078e                	slli	a5,a5,0x3
    8000513a:	963e                	add	a2,a2,a5
    8000513c:	e204                	sd	s1,0(a2)
      return fd;
    8000513e:	b7f5                	j	8000512a <fdalloc+0x2c>

0000000080005140 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005140:	715d                	addi	sp,sp,-80
    80005142:	e486                	sd	ra,72(sp)
    80005144:	e0a2                	sd	s0,64(sp)
    80005146:	fc26                	sd	s1,56(sp)
    80005148:	f84a                	sd	s2,48(sp)
    8000514a:	f44e                	sd	s3,40(sp)
    8000514c:	f052                	sd	s4,32(sp)
    8000514e:	ec56                	sd	s5,24(sp)
    80005150:	e85a                	sd	s6,16(sp)
    80005152:	0880                	addi	s0,sp,80
    80005154:	8b2e                	mv	s6,a1
    80005156:	89b2                	mv	s3,a2
    80005158:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000515a:	fb040593          	addi	a1,s0,-80
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	e3c080e7          	jalr	-452(ra) # 80003f9a <nameiparent>
    80005166:	84aa                	mv	s1,a0
    80005168:	14050f63          	beqz	a0,800052c6 <create+0x186>
    return 0;

  ilock(dp);
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	66a080e7          	jalr	1642(ra) # 800037d6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005174:	4601                	li	a2,0
    80005176:	fb040593          	addi	a1,s0,-80
    8000517a:	8526                	mv	a0,s1
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	b3e080e7          	jalr	-1218(ra) # 80003cba <dirlookup>
    80005184:	8aaa                	mv	s5,a0
    80005186:	c931                	beqz	a0,800051da <create+0x9a>
    iunlockput(dp);
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	8ae080e7          	jalr	-1874(ra) # 80003a38 <iunlockput>
    ilock(ip);
    80005192:	8556                	mv	a0,s5
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	642080e7          	jalr	1602(ra) # 800037d6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000519c:	000b059b          	sext.w	a1,s6
    800051a0:	4789                	li	a5,2
    800051a2:	02f59563          	bne	a1,a5,800051cc <create+0x8c>
    800051a6:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0a4>
    800051aa:	37f9                	addiw	a5,a5,-2
    800051ac:	17c2                	slli	a5,a5,0x30
    800051ae:	93c1                	srli	a5,a5,0x30
    800051b0:	4705                	li	a4,1
    800051b2:	00f76d63          	bltu	a4,a5,800051cc <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051b6:	8556                	mv	a0,s5
    800051b8:	60a6                	ld	ra,72(sp)
    800051ba:	6406                	ld	s0,64(sp)
    800051bc:	74e2                	ld	s1,56(sp)
    800051be:	7942                	ld	s2,48(sp)
    800051c0:	79a2                	ld	s3,40(sp)
    800051c2:	7a02                	ld	s4,32(sp)
    800051c4:	6ae2                	ld	s5,24(sp)
    800051c6:	6b42                	ld	s6,16(sp)
    800051c8:	6161                	addi	sp,sp,80
    800051ca:	8082                	ret
    iunlockput(ip);
    800051cc:	8556                	mv	a0,s5
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	86a080e7          	jalr	-1942(ra) # 80003a38 <iunlockput>
    return 0;
    800051d6:	4a81                	li	s5,0
    800051d8:	bff9                	j	800051b6 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051da:	85da                	mv	a1,s6
    800051dc:	4088                	lw	a0,0(s1)
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	45c080e7          	jalr	1116(ra) # 8000363a <ialloc>
    800051e6:	8a2a                	mv	s4,a0
    800051e8:	c539                	beqz	a0,80005236 <create+0xf6>
  ilock(ip);
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	5ec080e7          	jalr	1516(ra) # 800037d6 <ilock>
  ip->major = major;
    800051f2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051f6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051fa:	4905                	li	s2,1
    800051fc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005200:	8552                	mv	a0,s4
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	50a080e7          	jalr	1290(ra) # 8000370c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000520a:	000b059b          	sext.w	a1,s6
    8000520e:	03258b63          	beq	a1,s2,80005244 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005212:	004a2603          	lw	a2,4(s4)
    80005216:	fb040593          	addi	a1,s0,-80
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	cae080e7          	jalr	-850(ra) # 80003eca <dirlink>
    80005224:	06054f63          	bltz	a0,800052a2 <create+0x162>
  iunlockput(dp);
    80005228:	8526                	mv	a0,s1
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	80e080e7          	jalr	-2034(ra) # 80003a38 <iunlockput>
  return ip;
    80005232:	8ad2                	mv	s5,s4
    80005234:	b749                	j	800051b6 <create+0x76>
    iunlockput(dp);
    80005236:	8526                	mv	a0,s1
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	800080e7          	jalr	-2048(ra) # 80003a38 <iunlockput>
    return 0;
    80005240:	8ad2                	mv	s5,s4
    80005242:	bf95                	j	800051b6 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005244:	004a2603          	lw	a2,4(s4)
    80005248:	00003597          	auipc	a1,0x3
    8000524c:	50858593          	addi	a1,a1,1288 # 80008750 <syscalls+0x2c0>
    80005250:	8552                	mv	a0,s4
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c78080e7          	jalr	-904(ra) # 80003eca <dirlink>
    8000525a:	04054463          	bltz	a0,800052a2 <create+0x162>
    8000525e:	40d0                	lw	a2,4(s1)
    80005260:	00003597          	auipc	a1,0x3
    80005264:	4f858593          	addi	a1,a1,1272 # 80008758 <syscalls+0x2c8>
    80005268:	8552                	mv	a0,s4
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	c60080e7          	jalr	-928(ra) # 80003eca <dirlink>
    80005272:	02054863          	bltz	a0,800052a2 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005276:	004a2603          	lw	a2,4(s4)
    8000527a:	fb040593          	addi	a1,s0,-80
    8000527e:	8526                	mv	a0,s1
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	c4a080e7          	jalr	-950(ra) # 80003eca <dirlink>
    80005288:	00054d63          	bltz	a0,800052a2 <create+0x162>
    dp->nlink++;  // for ".."
    8000528c:	04a4d783          	lhu	a5,74(s1)
    80005290:	2785                	addiw	a5,a5,1
    80005292:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005296:	8526                	mv	a0,s1
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	474080e7          	jalr	1140(ra) # 8000370c <iupdate>
    800052a0:	b761                	j	80005228 <create+0xe8>
  ip->nlink = 0;
    800052a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052a6:	8552                	mv	a0,s4
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	464080e7          	jalr	1124(ra) # 8000370c <iupdate>
  iunlockput(ip);
    800052b0:	8552                	mv	a0,s4
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	786080e7          	jalr	1926(ra) # 80003a38 <iunlockput>
  iunlockput(dp);
    800052ba:	8526                	mv	a0,s1
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	77c080e7          	jalr	1916(ra) # 80003a38 <iunlockput>
  return 0;
    800052c4:	bdcd                	j	800051b6 <create+0x76>
    return 0;
    800052c6:	8aaa                	mv	s5,a0
    800052c8:	b5fd                	j	800051b6 <create+0x76>

00000000800052ca <sys_dup>:
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	ec26                	sd	s1,24(sp)
    800052d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052d4:	fd840613          	addi	a2,s0,-40
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	dc2080e7          	jalr	-574(ra) # 8000509e <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052e6:	02054363          	bltz	a0,8000530c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052ea:	fd843503          	ld	a0,-40(s0)
    800052ee:	00000097          	auipc	ra,0x0
    800052f2:	e10080e7          	jalr	-496(ra) # 800050fe <fdalloc>
    800052f6:	84aa                	mv	s1,a0
    return -1;
    800052f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052fa:	00054963          	bltz	a0,8000530c <sys_dup+0x42>
  filedup(f);
    800052fe:	fd843503          	ld	a0,-40(s0)
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	310080e7          	jalr	784(ra) # 80004612 <filedup>
  return fd;
    8000530a:	87a6                	mv	a5,s1
}
    8000530c:	853e                	mv	a0,a5
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	64e2                	ld	s1,24(sp)
    80005314:	6145                	addi	sp,sp,48
    80005316:	8082                	ret

0000000080005318 <sys_read>:
{
    80005318:	7179                	addi	sp,sp,-48
    8000531a:	f406                	sd	ra,40(sp)
    8000531c:	f022                	sd	s0,32(sp)
    8000531e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005320:	fd840593          	addi	a1,s0,-40
    80005324:	4505                	li	a0,1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	8f0080e7          	jalr	-1808(ra) # 80002c16 <argaddr>
  argint(2, &n);
    8000532e:	fe440593          	addi	a1,s0,-28
    80005332:	4509                	li	a0,2
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	8c2080e7          	jalr	-1854(ra) # 80002bf6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000533c:	fe840613          	addi	a2,s0,-24
    80005340:	4581                	li	a1,0
    80005342:	4501                	li	a0,0
    80005344:	00000097          	auipc	ra,0x0
    80005348:	d5a080e7          	jalr	-678(ra) # 8000509e <argfd>
    8000534c:	87aa                	mv	a5,a0
    return -1;
    8000534e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005350:	0007cc63          	bltz	a5,80005368 <sys_read+0x50>
  return fileread(f, p, n);
    80005354:	fe442603          	lw	a2,-28(s0)
    80005358:	fd843583          	ld	a1,-40(s0)
    8000535c:	fe843503          	ld	a0,-24(s0)
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	43e080e7          	jalr	1086(ra) # 8000479e <fileread>
}
    80005368:	70a2                	ld	ra,40(sp)
    8000536a:	7402                	ld	s0,32(sp)
    8000536c:	6145                	addi	sp,sp,48
    8000536e:	8082                	ret

0000000080005370 <sys_write>:
{
    80005370:	7179                	addi	sp,sp,-48
    80005372:	f406                	sd	ra,40(sp)
    80005374:	f022                	sd	s0,32(sp)
    80005376:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005378:	fd840593          	addi	a1,s0,-40
    8000537c:	4505                	li	a0,1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	898080e7          	jalr	-1896(ra) # 80002c16 <argaddr>
  argint(2, &n);
    80005386:	fe440593          	addi	a1,s0,-28
    8000538a:	4509                	li	a0,2
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	86a080e7          	jalr	-1942(ra) # 80002bf6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005394:	fe840613          	addi	a2,s0,-24
    80005398:	4581                	li	a1,0
    8000539a:	4501                	li	a0,0
    8000539c:	00000097          	auipc	ra,0x0
    800053a0:	d02080e7          	jalr	-766(ra) # 8000509e <argfd>
    800053a4:	87aa                	mv	a5,a0
    return -1;
    800053a6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a8:	0007cc63          	bltz	a5,800053c0 <sys_write+0x50>
  return filewrite(f, p, n);
    800053ac:	fe442603          	lw	a2,-28(s0)
    800053b0:	fd843583          	ld	a1,-40(s0)
    800053b4:	fe843503          	ld	a0,-24(s0)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	4a8080e7          	jalr	1192(ra) # 80004860 <filewrite>
}
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	6145                	addi	sp,sp,48
    800053c6:	8082                	ret

00000000800053c8 <sys_close>:
{
    800053c8:	1101                	addi	sp,sp,-32
    800053ca:	ec06                	sd	ra,24(sp)
    800053cc:	e822                	sd	s0,16(sp)
    800053ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053d0:	fe040613          	addi	a2,s0,-32
    800053d4:	fec40593          	addi	a1,s0,-20
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	cc4080e7          	jalr	-828(ra) # 8000509e <argfd>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053e4:	02054463          	bltz	a0,8000540c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	5c4080e7          	jalr	1476(ra) # 800019ac <myproc>
    800053f0:	fec42783          	lw	a5,-20(s0)
    800053f4:	07e9                	addi	a5,a5,26
    800053f6:	078e                	slli	a5,a5,0x3
    800053f8:	97aa                	add	a5,a5,a0
    800053fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053fe:	fe043503          	ld	a0,-32(s0)
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	262080e7          	jalr	610(ra) # 80004664 <fileclose>
  return 0;
    8000540a:	4781                	li	a5,0
}
    8000540c:	853e                	mv	a0,a5
    8000540e:	60e2                	ld	ra,24(sp)
    80005410:	6442                	ld	s0,16(sp)
    80005412:	6105                	addi	sp,sp,32
    80005414:	8082                	ret

0000000080005416 <sys_fstat>:
{
    80005416:	1101                	addi	sp,sp,-32
    80005418:	ec06                	sd	ra,24(sp)
    8000541a:	e822                	sd	s0,16(sp)
    8000541c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000541e:	fe040593          	addi	a1,s0,-32
    80005422:	4505                	li	a0,1
    80005424:	ffffd097          	auipc	ra,0xffffd
    80005428:	7f2080e7          	jalr	2034(ra) # 80002c16 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000542c:	fe840613          	addi	a2,s0,-24
    80005430:	4581                	li	a1,0
    80005432:	4501                	li	a0,0
    80005434:	00000097          	auipc	ra,0x0
    80005438:	c6a080e7          	jalr	-918(ra) # 8000509e <argfd>
    8000543c:	87aa                	mv	a5,a0
    return -1;
    8000543e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005440:	0007ca63          	bltz	a5,80005454 <sys_fstat+0x3e>
  return filestat(f, st);
    80005444:	fe043583          	ld	a1,-32(s0)
    80005448:	fe843503          	ld	a0,-24(s0)
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	2e0080e7          	jalr	736(ra) # 8000472c <filestat>
}
    80005454:	60e2                	ld	ra,24(sp)
    80005456:	6442                	ld	s0,16(sp)
    80005458:	6105                	addi	sp,sp,32
    8000545a:	8082                	ret

000000008000545c <sys_link>:
{
    8000545c:	7169                	addi	sp,sp,-304
    8000545e:	f606                	sd	ra,296(sp)
    80005460:	f222                	sd	s0,288(sp)
    80005462:	ee26                	sd	s1,280(sp)
    80005464:	ea4a                	sd	s2,272(sp)
    80005466:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005468:	08000613          	li	a2,128
    8000546c:	ed040593          	addi	a1,s0,-304
    80005470:	4501                	li	a0,0
    80005472:	ffffd097          	auipc	ra,0xffffd
    80005476:	7c4080e7          	jalr	1988(ra) # 80002c36 <argstr>
    return -1;
    8000547a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547c:	10054e63          	bltz	a0,80005598 <sys_link+0x13c>
    80005480:	08000613          	li	a2,128
    80005484:	f5040593          	addi	a1,s0,-176
    80005488:	4505                	li	a0,1
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	7ac080e7          	jalr	1964(ra) # 80002c36 <argstr>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005494:	10054263          	bltz	a0,80005598 <sys_link+0x13c>
  begin_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	d00080e7          	jalr	-768(ra) # 80004198 <begin_op>
  if((ip = namei(old)) == 0){
    800054a0:	ed040513          	addi	a0,s0,-304
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	ad8080e7          	jalr	-1320(ra) # 80003f7c <namei>
    800054ac:	84aa                	mv	s1,a0
    800054ae:	c551                	beqz	a0,8000553a <sys_link+0xde>
  ilock(ip);
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	326080e7          	jalr	806(ra) # 800037d6 <ilock>
  if(ip->type == T_DIR){
    800054b8:	04449703          	lh	a4,68(s1)
    800054bc:	4785                	li	a5,1
    800054be:	08f70463          	beq	a4,a5,80005546 <sys_link+0xea>
  ip->nlink++;
    800054c2:	04a4d783          	lhu	a5,74(s1)
    800054c6:	2785                	addiw	a5,a5,1
    800054c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	23e080e7          	jalr	574(ra) # 8000370c <iupdate>
  iunlock(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	3c0080e7          	jalr	960(ra) # 80003898 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054e0:	fd040593          	addi	a1,s0,-48
    800054e4:	f5040513          	addi	a0,s0,-176
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	ab2080e7          	jalr	-1358(ra) # 80003f9a <nameiparent>
    800054f0:	892a                	mv	s2,a0
    800054f2:	c935                	beqz	a0,80005566 <sys_link+0x10a>
  ilock(dp);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	2e2080e7          	jalr	738(ra) # 800037d6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054fc:	00092703          	lw	a4,0(s2)
    80005500:	409c                	lw	a5,0(s1)
    80005502:	04f71d63          	bne	a4,a5,8000555c <sys_link+0x100>
    80005506:	40d0                	lw	a2,4(s1)
    80005508:	fd040593          	addi	a1,s0,-48
    8000550c:	854a                	mv	a0,s2
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	9bc080e7          	jalr	-1604(ra) # 80003eca <dirlink>
    80005516:	04054363          	bltz	a0,8000555c <sys_link+0x100>
  iunlockput(dp);
    8000551a:	854a                	mv	a0,s2
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	51c080e7          	jalr	1308(ra) # 80003a38 <iunlockput>
  iput(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	46a080e7          	jalr	1130(ra) # 80003990 <iput>
  end_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	cea080e7          	jalr	-790(ra) # 80004218 <end_op>
  return 0;
    80005536:	4781                	li	a5,0
    80005538:	a085                	j	80005598 <sys_link+0x13c>
    end_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	cde080e7          	jalr	-802(ra) # 80004218 <end_op>
    return -1;
    80005542:	57fd                	li	a5,-1
    80005544:	a891                	j	80005598 <sys_link+0x13c>
    iunlockput(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	4f0080e7          	jalr	1264(ra) # 80003a38 <iunlockput>
    end_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	cc8080e7          	jalr	-824(ra) # 80004218 <end_op>
    return -1;
    80005558:	57fd                	li	a5,-1
    8000555a:	a83d                	j	80005598 <sys_link+0x13c>
    iunlockput(dp);
    8000555c:	854a                	mv	a0,s2
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	4da080e7          	jalr	1242(ra) # 80003a38 <iunlockput>
  ilock(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	26e080e7          	jalr	622(ra) # 800037d6 <ilock>
  ip->nlink--;
    80005570:	04a4d783          	lhu	a5,74(s1)
    80005574:	37fd                	addiw	a5,a5,-1
    80005576:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	190080e7          	jalr	400(ra) # 8000370c <iupdate>
  iunlockput(ip);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	4b2080e7          	jalr	1202(ra) # 80003a38 <iunlockput>
  end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	c8a080e7          	jalr	-886(ra) # 80004218 <end_op>
  return -1;
    80005596:	57fd                	li	a5,-1
}
    80005598:	853e                	mv	a0,a5
    8000559a:	70b2                	ld	ra,296(sp)
    8000559c:	7412                	ld	s0,288(sp)
    8000559e:	64f2                	ld	s1,280(sp)
    800055a0:	6952                	ld	s2,272(sp)
    800055a2:	6155                	addi	sp,sp,304
    800055a4:	8082                	ret

00000000800055a6 <sys_unlink>:
{
    800055a6:	7151                	addi	sp,sp,-240
    800055a8:	f586                	sd	ra,232(sp)
    800055aa:	f1a2                	sd	s0,224(sp)
    800055ac:	eda6                	sd	s1,216(sp)
    800055ae:	e9ca                	sd	s2,208(sp)
    800055b0:	e5ce                	sd	s3,200(sp)
    800055b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055b4:	08000613          	li	a2,128
    800055b8:	f3040593          	addi	a1,s0,-208
    800055bc:	4501                	li	a0,0
    800055be:	ffffd097          	auipc	ra,0xffffd
    800055c2:	678080e7          	jalr	1656(ra) # 80002c36 <argstr>
    800055c6:	18054163          	bltz	a0,80005748 <sys_unlink+0x1a2>
  begin_op();
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	bce080e7          	jalr	-1074(ra) # 80004198 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	f3040513          	addi	a0,s0,-208
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	9c0080e7          	jalr	-1600(ra) # 80003f9a <nameiparent>
    800055e2:	84aa                	mv	s1,a0
    800055e4:	c979                	beqz	a0,800056ba <sys_unlink+0x114>
  ilock(dp);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	1f0080e7          	jalr	496(ra) # 800037d6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ee:	00003597          	auipc	a1,0x3
    800055f2:	16258593          	addi	a1,a1,354 # 80008750 <syscalls+0x2c0>
    800055f6:	fb040513          	addi	a0,s0,-80
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	6a6080e7          	jalr	1702(ra) # 80003ca0 <namecmp>
    80005602:	14050a63          	beqz	a0,80005756 <sys_unlink+0x1b0>
    80005606:	00003597          	auipc	a1,0x3
    8000560a:	15258593          	addi	a1,a1,338 # 80008758 <syscalls+0x2c8>
    8000560e:	fb040513          	addi	a0,s0,-80
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	68e080e7          	jalr	1678(ra) # 80003ca0 <namecmp>
    8000561a:	12050e63          	beqz	a0,80005756 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000561e:	f2c40613          	addi	a2,s0,-212
    80005622:	fb040593          	addi	a1,s0,-80
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	692080e7          	jalr	1682(ra) # 80003cba <dirlookup>
    80005630:	892a                	mv	s2,a0
    80005632:	12050263          	beqz	a0,80005756 <sys_unlink+0x1b0>
  ilock(ip);
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	1a0080e7          	jalr	416(ra) # 800037d6 <ilock>
  if(ip->nlink < 1)
    8000563e:	04a91783          	lh	a5,74(s2)
    80005642:	08f05263          	blez	a5,800056c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005646:	04491703          	lh	a4,68(s2)
    8000564a:	4785                	li	a5,1
    8000564c:	08f70563          	beq	a4,a5,800056d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005650:	4641                	li	a2,16
    80005652:	4581                	li	a1,0
    80005654:	fc040513          	addi	a0,s0,-64
    80005658:	ffffb097          	auipc	ra,0xffffb
    8000565c:	67a080e7          	jalr	1658(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005660:	4741                	li	a4,16
    80005662:	f2c42683          	lw	a3,-212(s0)
    80005666:	fc040613          	addi	a2,s0,-64
    8000566a:	4581                	li	a1,0
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	514080e7          	jalr	1300(ra) # 80003b82 <writei>
    80005676:	47c1                	li	a5,16
    80005678:	0af51563          	bne	a0,a5,80005722 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000567c:	04491703          	lh	a4,68(s2)
    80005680:	4785                	li	a5,1
    80005682:	0af70863          	beq	a4,a5,80005732 <sys_unlink+0x18c>
  iunlockput(dp);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	3b0080e7          	jalr	944(ra) # 80003a38 <iunlockput>
  ip->nlink--;
    80005690:	04a95783          	lhu	a5,74(s2)
    80005694:	37fd                	addiw	a5,a5,-1
    80005696:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	070080e7          	jalr	112(ra) # 8000370c <iupdate>
  iunlockput(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	392080e7          	jalr	914(ra) # 80003a38 <iunlockput>
  end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	b6a080e7          	jalr	-1174(ra) # 80004218 <end_op>
  return 0;
    800056b6:	4501                	li	a0,0
    800056b8:	a84d                	j	8000576a <sys_unlink+0x1c4>
    end_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	b5e080e7          	jalr	-1186(ra) # 80004218 <end_op>
    return -1;
    800056c2:	557d                	li	a0,-1
    800056c4:	a05d                	j	8000576a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056c6:	00003517          	auipc	a0,0x3
    800056ca:	09a50513          	addi	a0,a0,154 # 80008760 <syscalls+0x2d0>
    800056ce:	ffffb097          	auipc	ra,0xffffb
    800056d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d6:	04c92703          	lw	a4,76(s2)
    800056da:	02000793          	li	a5,32
    800056de:	f6e7f9e3          	bgeu	a5,a4,80005650 <sys_unlink+0xaa>
    800056e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056e6:	4741                	li	a4,16
    800056e8:	86ce                	mv	a3,s3
    800056ea:	f1840613          	addi	a2,s0,-232
    800056ee:	4581                	li	a1,0
    800056f0:	854a                	mv	a0,s2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	398080e7          	jalr	920(ra) # 80003a8a <readi>
    800056fa:	47c1                	li	a5,16
    800056fc:	00f51b63          	bne	a0,a5,80005712 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005700:	f1845783          	lhu	a5,-232(s0)
    80005704:	e7a1                	bnez	a5,8000574c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005706:	29c1                	addiw	s3,s3,16
    80005708:	04c92783          	lw	a5,76(s2)
    8000570c:	fcf9ede3          	bltu	s3,a5,800056e6 <sys_unlink+0x140>
    80005710:	b781                	j	80005650 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005712:	00003517          	auipc	a0,0x3
    80005716:	06650513          	addi	a0,a0,102 # 80008778 <syscalls+0x2e8>
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	e24080e7          	jalr	-476(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005722:	00003517          	auipc	a0,0x3
    80005726:	06e50513          	addi	a0,a0,110 # 80008790 <syscalls+0x300>
    8000572a:	ffffb097          	auipc	ra,0xffffb
    8000572e:	e14080e7          	jalr	-492(ra) # 8000053e <panic>
    dp->nlink--;
    80005732:	04a4d783          	lhu	a5,74(s1)
    80005736:	37fd                	addiw	a5,a5,-1
    80005738:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000573c:	8526                	mv	a0,s1
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	fce080e7          	jalr	-50(ra) # 8000370c <iupdate>
    80005746:	b781                	j	80005686 <sys_unlink+0xe0>
    return -1;
    80005748:	557d                	li	a0,-1
    8000574a:	a005                	j	8000576a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	2ea080e7          	jalr	746(ra) # 80003a38 <iunlockput>
  iunlockput(dp);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	2e0080e7          	jalr	736(ra) # 80003a38 <iunlockput>
  end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	ab8080e7          	jalr	-1352(ra) # 80004218 <end_op>
  return -1;
    80005768:	557d                	li	a0,-1
}
    8000576a:	70ae                	ld	ra,232(sp)
    8000576c:	740e                	ld	s0,224(sp)
    8000576e:	64ee                	ld	s1,216(sp)
    80005770:	694e                	ld	s2,208(sp)
    80005772:	69ae                	ld	s3,200(sp)
    80005774:	616d                	addi	sp,sp,240
    80005776:	8082                	ret

0000000080005778 <sys_open>:

uint64
sys_open(void)
{
    80005778:	7131                	addi	sp,sp,-192
    8000577a:	fd06                	sd	ra,184(sp)
    8000577c:	f922                	sd	s0,176(sp)
    8000577e:	f526                	sd	s1,168(sp)
    80005780:	f14a                	sd	s2,160(sp)
    80005782:	ed4e                	sd	s3,152(sp)
    80005784:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005786:	f4c40593          	addi	a1,s0,-180
    8000578a:	4505                	li	a0,1
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	46a080e7          	jalr	1130(ra) # 80002bf6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005794:	08000613          	li	a2,128
    80005798:	f5040593          	addi	a1,s0,-176
    8000579c:	4501                	li	a0,0
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	498080e7          	jalr	1176(ra) # 80002c36 <argstr>
    800057a6:	87aa                	mv	a5,a0
    return -1;
    800057a8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057aa:	0a07c963          	bltz	a5,8000585c <sys_open+0xe4>

  begin_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	9ea080e7          	jalr	-1558(ra) # 80004198 <begin_op>

  if(omode & O_CREATE){
    800057b6:	f4c42783          	lw	a5,-180(s0)
    800057ba:	2007f793          	andi	a5,a5,512
    800057be:	cfc5                	beqz	a5,80005876 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057c0:	4681                	li	a3,0
    800057c2:	4601                	li	a2,0
    800057c4:	4589                	li	a1,2
    800057c6:	f5040513          	addi	a0,s0,-176
    800057ca:	00000097          	auipc	ra,0x0
    800057ce:	976080e7          	jalr	-1674(ra) # 80005140 <create>
    800057d2:	84aa                	mv	s1,a0
    if(ip == 0){
    800057d4:	c959                	beqz	a0,8000586a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057d6:	04449703          	lh	a4,68(s1)
    800057da:	478d                	li	a5,3
    800057dc:	00f71763          	bne	a4,a5,800057ea <sys_open+0x72>
    800057e0:	0464d703          	lhu	a4,70(s1)
    800057e4:	47a5                	li	a5,9
    800057e6:	0ce7ed63          	bltu	a5,a4,800058c0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	dbe080e7          	jalr	-578(ra) # 800045a8 <filealloc>
    800057f2:	89aa                	mv	s3,a0
    800057f4:	10050363          	beqz	a0,800058fa <sys_open+0x182>
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	906080e7          	jalr	-1786(ra) # 800050fe <fdalloc>
    80005800:	892a                	mv	s2,a0
    80005802:	0e054763          	bltz	a0,800058f0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005806:	04449703          	lh	a4,68(s1)
    8000580a:	478d                	li	a5,3
    8000580c:	0cf70563          	beq	a4,a5,800058d6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005810:	4789                	li	a5,2
    80005812:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005816:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000581a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000581e:	f4c42783          	lw	a5,-180(s0)
    80005822:	0017c713          	xori	a4,a5,1
    80005826:	8b05                	andi	a4,a4,1
    80005828:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000582c:	0037f713          	andi	a4,a5,3
    80005830:	00e03733          	snez	a4,a4
    80005834:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005838:	4007f793          	andi	a5,a5,1024
    8000583c:	c791                	beqz	a5,80005848 <sys_open+0xd0>
    8000583e:	04449703          	lh	a4,68(s1)
    80005842:	4789                	li	a5,2
    80005844:	0af70063          	beq	a4,a5,800058e4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	04e080e7          	jalr	78(ra) # 80003898 <iunlock>
  end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9c6080e7          	jalr	-1594(ra) # 80004218 <end_op>

  return fd;
    8000585a:	854a                	mv	a0,s2
}
    8000585c:	70ea                	ld	ra,184(sp)
    8000585e:	744a                	ld	s0,176(sp)
    80005860:	74aa                	ld	s1,168(sp)
    80005862:	790a                	ld	s2,160(sp)
    80005864:	69ea                	ld	s3,152(sp)
    80005866:	6129                	addi	sp,sp,192
    80005868:	8082                	ret
      end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	9ae080e7          	jalr	-1618(ra) # 80004218 <end_op>
      return -1;
    80005872:	557d                	li	a0,-1
    80005874:	b7e5                	j	8000585c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005876:	f5040513          	addi	a0,s0,-176
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	702080e7          	jalr	1794(ra) # 80003f7c <namei>
    80005882:	84aa                	mv	s1,a0
    80005884:	c905                	beqz	a0,800058b4 <sys_open+0x13c>
    ilock(ip);
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	f50080e7          	jalr	-176(ra) # 800037d6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000588e:	04449703          	lh	a4,68(s1)
    80005892:	4785                	li	a5,1
    80005894:	f4f711e3          	bne	a4,a5,800057d6 <sys_open+0x5e>
    80005898:	f4c42783          	lw	a5,-180(s0)
    8000589c:	d7b9                	beqz	a5,800057ea <sys_open+0x72>
      iunlockput(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	198080e7          	jalr	408(ra) # 80003a38 <iunlockput>
      end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	970080e7          	jalr	-1680(ra) # 80004218 <end_op>
      return -1;
    800058b0:	557d                	li	a0,-1
    800058b2:	b76d                	j	8000585c <sys_open+0xe4>
      end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	964080e7          	jalr	-1692(ra) # 80004218 <end_op>
      return -1;
    800058bc:	557d                	li	a0,-1
    800058be:	bf79                	j	8000585c <sys_open+0xe4>
    iunlockput(ip);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	176080e7          	jalr	374(ra) # 80003a38 <iunlockput>
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	94e080e7          	jalr	-1714(ra) # 80004218 <end_op>
    return -1;
    800058d2:	557d                	li	a0,-1
    800058d4:	b761                	j	8000585c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058d6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058da:	04649783          	lh	a5,70(s1)
    800058de:	02f99223          	sh	a5,36(s3)
    800058e2:	bf25                	j	8000581a <sys_open+0xa2>
    itrunc(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	ffe080e7          	jalr	-2(ra) # 800038e4 <itrunc>
    800058ee:	bfa9                	j	80005848 <sys_open+0xd0>
      fileclose(f);
    800058f0:	854e                	mv	a0,s3
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	d72080e7          	jalr	-654(ra) # 80004664 <fileclose>
    iunlockput(ip);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	13c080e7          	jalr	316(ra) # 80003a38 <iunlockput>
    end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	914080e7          	jalr	-1772(ra) # 80004218 <end_op>
    return -1;
    8000590c:	557d                	li	a0,-1
    8000590e:	b7b9                	j	8000585c <sys_open+0xe4>

0000000080005910 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005910:	7175                	addi	sp,sp,-144
    80005912:	e506                	sd	ra,136(sp)
    80005914:	e122                	sd	s0,128(sp)
    80005916:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	880080e7          	jalr	-1920(ra) # 80004198 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005920:	08000613          	li	a2,128
    80005924:	f7040593          	addi	a1,s0,-144
    80005928:	4501                	li	a0,0
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	30c080e7          	jalr	780(ra) # 80002c36 <argstr>
    80005932:	02054963          	bltz	a0,80005964 <sys_mkdir+0x54>
    80005936:	4681                	li	a3,0
    80005938:	4601                	li	a2,0
    8000593a:	4585                	li	a1,1
    8000593c:	f7040513          	addi	a0,s0,-144
    80005940:	00000097          	auipc	ra,0x0
    80005944:	800080e7          	jalr	-2048(ra) # 80005140 <create>
    80005948:	cd11                	beqz	a0,80005964 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	0ee080e7          	jalr	238(ra) # 80003a38 <iunlockput>
  end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	8c6080e7          	jalr	-1850(ra) # 80004218 <end_op>
  return 0;
    8000595a:	4501                	li	a0,0
}
    8000595c:	60aa                	ld	ra,136(sp)
    8000595e:	640a                	ld	s0,128(sp)
    80005960:	6149                	addi	sp,sp,144
    80005962:	8082                	ret
    end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	8b4080e7          	jalr	-1868(ra) # 80004218 <end_op>
    return -1;
    8000596c:	557d                	li	a0,-1
    8000596e:	b7fd                	j	8000595c <sys_mkdir+0x4c>

0000000080005970 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005970:	7135                	addi	sp,sp,-160
    80005972:	ed06                	sd	ra,152(sp)
    80005974:	e922                	sd	s0,144(sp)
    80005976:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	820080e7          	jalr	-2016(ra) # 80004198 <begin_op>
  argint(1, &major);
    80005980:	f6c40593          	addi	a1,s0,-148
    80005984:	4505                	li	a0,1
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	270080e7          	jalr	624(ra) # 80002bf6 <argint>
  argint(2, &minor);
    8000598e:	f6840593          	addi	a1,s0,-152
    80005992:	4509                	li	a0,2
    80005994:	ffffd097          	auipc	ra,0xffffd
    80005998:	262080e7          	jalr	610(ra) # 80002bf6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599c:	08000613          	li	a2,128
    800059a0:	f7040593          	addi	a1,s0,-144
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	290080e7          	jalr	656(ra) # 80002c36 <argstr>
    800059ae:	02054b63          	bltz	a0,800059e4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059b2:	f6841683          	lh	a3,-152(s0)
    800059b6:	f6c41603          	lh	a2,-148(s0)
    800059ba:	458d                	li	a1,3
    800059bc:	f7040513          	addi	a0,s0,-144
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	780080e7          	jalr	1920(ra) # 80005140 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c8:	cd11                	beqz	a0,800059e4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	06e080e7          	jalr	110(ra) # 80003a38 <iunlockput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	846080e7          	jalr	-1978(ra) # 80004218 <end_op>
  return 0;
    800059da:	4501                	li	a0,0
}
    800059dc:	60ea                	ld	ra,152(sp)
    800059de:	644a                	ld	s0,144(sp)
    800059e0:	610d                	addi	sp,sp,160
    800059e2:	8082                	ret
    end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	834080e7          	jalr	-1996(ra) # 80004218 <end_op>
    return -1;
    800059ec:	557d                	li	a0,-1
    800059ee:	b7fd                	j	800059dc <sys_mknod+0x6c>

00000000800059f0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059f0:	7135                	addi	sp,sp,-160
    800059f2:	ed06                	sd	ra,152(sp)
    800059f4:	e922                	sd	s0,144(sp)
    800059f6:	e526                	sd	s1,136(sp)
    800059f8:	e14a                	sd	s2,128(sp)
    800059fa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059fc:	ffffc097          	auipc	ra,0xffffc
    80005a00:	fb0080e7          	jalr	-80(ra) # 800019ac <myproc>
    80005a04:	892a                	mv	s2,a0
  
  begin_op();
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	792080e7          	jalr	1938(ra) # 80004198 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a0e:	08000613          	li	a2,128
    80005a12:	f6040593          	addi	a1,s0,-160
    80005a16:	4501                	li	a0,0
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	21e080e7          	jalr	542(ra) # 80002c36 <argstr>
    80005a20:	04054b63          	bltz	a0,80005a76 <sys_chdir+0x86>
    80005a24:	f6040513          	addi	a0,s0,-160
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	554080e7          	jalr	1364(ra) # 80003f7c <namei>
    80005a30:	84aa                	mv	s1,a0
    80005a32:	c131                	beqz	a0,80005a76 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	da2080e7          	jalr	-606(ra) # 800037d6 <ilock>
  if(ip->type != T_DIR){
    80005a3c:	04449703          	lh	a4,68(s1)
    80005a40:	4785                	li	a5,1
    80005a42:	04f71063          	bne	a4,a5,80005a82 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	e50080e7          	jalr	-432(ra) # 80003898 <iunlock>
  iput(p->cwd);
    80005a50:	15093503          	ld	a0,336(s2)
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	f3c080e7          	jalr	-196(ra) # 80003990 <iput>
  end_op();
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	7bc080e7          	jalr	1980(ra) # 80004218 <end_op>
  p->cwd = ip;
    80005a64:	14993823          	sd	s1,336(s2)
  return 0;
    80005a68:	4501                	li	a0,0
}
    80005a6a:	60ea                	ld	ra,152(sp)
    80005a6c:	644a                	ld	s0,144(sp)
    80005a6e:	64aa                	ld	s1,136(sp)
    80005a70:	690a                	ld	s2,128(sp)
    80005a72:	610d                	addi	sp,sp,160
    80005a74:	8082                	ret
    end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	7a2080e7          	jalr	1954(ra) # 80004218 <end_op>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	b7ed                	j	80005a6a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	fb4080e7          	jalr	-76(ra) # 80003a38 <iunlockput>
    end_op();
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	78c080e7          	jalr	1932(ra) # 80004218 <end_op>
    return -1;
    80005a94:	557d                	li	a0,-1
    80005a96:	bfd1                	j	80005a6a <sys_chdir+0x7a>

0000000080005a98 <sys_exec>:

uint64
sys_exec(void)
{
    80005a98:	7145                	addi	sp,sp,-464
    80005a9a:	e786                	sd	ra,456(sp)
    80005a9c:	e3a2                	sd	s0,448(sp)
    80005a9e:	ff26                	sd	s1,440(sp)
    80005aa0:	fb4a                	sd	s2,432(sp)
    80005aa2:	f74e                	sd	s3,424(sp)
    80005aa4:	f352                	sd	s4,416(sp)
    80005aa6:	ef56                	sd	s5,408(sp)
    80005aa8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005aaa:	e3840593          	addi	a1,s0,-456
    80005aae:	4505                	li	a0,1
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	166080e7          	jalr	358(ra) # 80002c16 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab8:	08000613          	li	a2,128
    80005abc:	f4040593          	addi	a1,s0,-192
    80005ac0:	4501                	li	a0,0
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	174080e7          	jalr	372(ra) # 80002c36 <argstr>
    80005aca:	87aa                	mv	a5,a0
    return -1;
    80005acc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ace:	0c07c263          	bltz	a5,80005b92 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ad2:	10000613          	li	a2,256
    80005ad6:	4581                	li	a1,0
    80005ad8:	e4040513          	addi	a0,s0,-448
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	1f6080e7          	jalr	502(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ae4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ae8:	89a6                	mv	s3,s1
    80005aea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aec:	02000a13          	li	s4,32
    80005af0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005af4:	00391793          	slli	a5,s2,0x3
    80005af8:	e3040593          	addi	a1,s0,-464
    80005afc:	e3843503          	ld	a0,-456(s0)
    80005b00:	953e                	add	a0,a0,a5
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	056080e7          	jalr	86(ra) # 80002b58 <fetchaddr>
    80005b0a:	02054a63          	bltz	a0,80005b3e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b0e:	e3043783          	ld	a5,-464(s0)
    80005b12:	c3b9                	beqz	a5,80005b58 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	fd2080e7          	jalr	-46(ra) # 80000ae6 <kalloc>
    80005b1c:	85aa                	mv	a1,a0
    80005b1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b22:	cd11                	beqz	a0,80005b3e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b24:	6605                	lui	a2,0x1
    80005b26:	e3043503          	ld	a0,-464(s0)
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	080080e7          	jalr	128(ra) # 80002baa <fetchstr>
    80005b32:	00054663          	bltz	a0,80005b3e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b36:	0905                	addi	s2,s2,1
    80005b38:	09a1                	addi	s3,s3,8
    80005b3a:	fb491be3          	bne	s2,s4,80005af0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3e:	10048913          	addi	s2,s1,256
    80005b42:	6088                	ld	a0,0(s1)
    80005b44:	c531                	beqz	a0,80005b90 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	ea4080e7          	jalr	-348(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4e:	04a1                	addi	s1,s1,8
    80005b50:	ff2499e3          	bne	s1,s2,80005b42 <sys_exec+0xaa>
  return -1;
    80005b54:	557d                	li	a0,-1
    80005b56:	a835                	j	80005b92 <sys_exec+0xfa>
      argv[i] = 0;
    80005b58:	0a8e                	slli	s5,s5,0x3
    80005b5a:	fc040793          	addi	a5,s0,-64
    80005b5e:	9abe                	add	s5,s5,a5
    80005b60:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b64:	e4040593          	addi	a1,s0,-448
    80005b68:	f4040513          	addi	a0,s0,-192
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	172080e7          	jalr	370(ra) # 80004cde <exec>
    80005b74:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b76:	10048993          	addi	s3,s1,256
    80005b7a:	6088                	ld	a0,0(s1)
    80005b7c:	c901                	beqz	a0,80005b8c <sys_exec+0xf4>
    kfree(argv[i]);
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	e6c080e7          	jalr	-404(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	04a1                	addi	s1,s1,8
    80005b88:	ff3499e3          	bne	s1,s3,80005b7a <sys_exec+0xe2>
  return ret;
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	a011                	j	80005b92 <sys_exec+0xfa>
  return -1;
    80005b90:	557d                	li	a0,-1
}
    80005b92:	60be                	ld	ra,456(sp)
    80005b94:	641e                	ld	s0,448(sp)
    80005b96:	74fa                	ld	s1,440(sp)
    80005b98:	795a                	ld	s2,432(sp)
    80005b9a:	79ba                	ld	s3,424(sp)
    80005b9c:	7a1a                	ld	s4,416(sp)
    80005b9e:	6afa                	ld	s5,408(sp)
    80005ba0:	6179                	addi	sp,sp,464
    80005ba2:	8082                	ret

0000000080005ba4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ba4:	7139                	addi	sp,sp,-64
    80005ba6:	fc06                	sd	ra,56(sp)
    80005ba8:	f822                	sd	s0,48(sp)
    80005baa:	f426                	sd	s1,40(sp)
    80005bac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	dfe080e7          	jalr	-514(ra) # 800019ac <myproc>
    80005bb6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bb8:	fd840593          	addi	a1,s0,-40
    80005bbc:	4501                	li	a0,0
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	058080e7          	jalr	88(ra) # 80002c16 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bc6:	fc840593          	addi	a1,s0,-56
    80005bca:	fd040513          	addi	a0,s0,-48
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	dc6080e7          	jalr	-570(ra) # 80004994 <pipealloc>
    return -1;
    80005bd6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bd8:	0c054463          	bltz	a0,80005ca0 <sys_pipe+0xfc>
  fd0 = -1;
    80005bdc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be0:	fd043503          	ld	a0,-48(s0)
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	51a080e7          	jalr	1306(ra) # 800050fe <fdalloc>
    80005bec:	fca42223          	sw	a0,-60(s0)
    80005bf0:	08054b63          	bltz	a0,80005c86 <sys_pipe+0xe2>
    80005bf4:	fc843503          	ld	a0,-56(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	506080e7          	jalr	1286(ra) # 800050fe <fdalloc>
    80005c00:	fca42023          	sw	a0,-64(s0)
    80005c04:	06054863          	bltz	a0,80005c74 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c08:	4691                	li	a3,4
    80005c0a:	fc440613          	addi	a2,s0,-60
    80005c0e:	fd843583          	ld	a1,-40(s0)
    80005c12:	68a8                	ld	a0,80(s1)
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	a54080e7          	jalr	-1452(ra) # 80001668 <copyout>
    80005c1c:	02054063          	bltz	a0,80005c3c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c20:	4691                	li	a3,4
    80005c22:	fc040613          	addi	a2,s0,-64
    80005c26:	fd843583          	ld	a1,-40(s0)
    80005c2a:	0591                	addi	a1,a1,4
    80005c2c:	68a8                	ld	a0,80(s1)
    80005c2e:	ffffc097          	auipc	ra,0xffffc
    80005c32:	a3a080e7          	jalr	-1478(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c38:	06055463          	bgez	a0,80005ca0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c3c:	fc442783          	lw	a5,-60(s0)
    80005c40:	07e9                	addi	a5,a5,26
    80005c42:	078e                	slli	a5,a5,0x3
    80005c44:	97a6                	add	a5,a5,s1
    80005c46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c4a:	fc042503          	lw	a0,-64(s0)
    80005c4e:	0569                	addi	a0,a0,26
    80005c50:	050e                	slli	a0,a0,0x3
    80005c52:	94aa                	add	s1,s1,a0
    80005c54:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c58:	fd043503          	ld	a0,-48(s0)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	a08080e7          	jalr	-1528(ra) # 80004664 <fileclose>
    fileclose(wf);
    80005c64:	fc843503          	ld	a0,-56(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	9fc080e7          	jalr	-1540(ra) # 80004664 <fileclose>
    return -1;
    80005c70:	57fd                	li	a5,-1
    80005c72:	a03d                	j	80005ca0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c74:	fc442783          	lw	a5,-60(s0)
    80005c78:	0007c763          	bltz	a5,80005c86 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c7c:	07e9                	addi	a5,a5,26
    80005c7e:	078e                	slli	a5,a5,0x3
    80005c80:	94be                	add	s1,s1,a5
    80005c82:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c86:	fd043503          	ld	a0,-48(s0)
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	9da080e7          	jalr	-1574(ra) # 80004664 <fileclose>
    fileclose(wf);
    80005c92:	fc843503          	ld	a0,-56(s0)
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	9ce080e7          	jalr	-1586(ra) # 80004664 <fileclose>
    return -1;
    80005c9e:	57fd                	li	a5,-1
}
    80005ca0:	853e                	mv	a0,a5
    80005ca2:	70e2                	ld	ra,56(sp)
    80005ca4:	7442                	ld	s0,48(sp)
    80005ca6:	74a2                	ld	s1,40(sp)
    80005ca8:	6121                	addi	sp,sp,64
    80005caa:	8082                	ret
    80005cac:	0000                	unimp
	...

0000000080005cb0 <kernelvec>:
    80005cb0:	7111                	addi	sp,sp,-256
    80005cb2:	e006                	sd	ra,0(sp)
    80005cb4:	e40a                	sd	sp,8(sp)
    80005cb6:	e80e                	sd	gp,16(sp)
    80005cb8:	ec12                	sd	tp,24(sp)
    80005cba:	f016                	sd	t0,32(sp)
    80005cbc:	f41a                	sd	t1,40(sp)
    80005cbe:	f81e                	sd	t2,48(sp)
    80005cc0:	fc22                	sd	s0,56(sp)
    80005cc2:	e0a6                	sd	s1,64(sp)
    80005cc4:	e4aa                	sd	a0,72(sp)
    80005cc6:	e8ae                	sd	a1,80(sp)
    80005cc8:	ecb2                	sd	a2,88(sp)
    80005cca:	f0b6                	sd	a3,96(sp)
    80005ccc:	f4ba                	sd	a4,104(sp)
    80005cce:	f8be                	sd	a5,112(sp)
    80005cd0:	fcc2                	sd	a6,120(sp)
    80005cd2:	e146                	sd	a7,128(sp)
    80005cd4:	e54a                	sd	s2,136(sp)
    80005cd6:	e94e                	sd	s3,144(sp)
    80005cd8:	ed52                	sd	s4,152(sp)
    80005cda:	f156                	sd	s5,160(sp)
    80005cdc:	f55a                	sd	s6,168(sp)
    80005cde:	f95e                	sd	s7,176(sp)
    80005ce0:	fd62                	sd	s8,184(sp)
    80005ce2:	e1e6                	sd	s9,192(sp)
    80005ce4:	e5ea                	sd	s10,200(sp)
    80005ce6:	e9ee                	sd	s11,208(sp)
    80005ce8:	edf2                	sd	t3,216(sp)
    80005cea:	f1f6                	sd	t4,224(sp)
    80005cec:	f5fa                	sd	t5,232(sp)
    80005cee:	f9fe                	sd	t6,240(sp)
    80005cf0:	d35fc0ef          	jal	ra,80002a24 <kerneltrap>
    80005cf4:	6082                	ld	ra,0(sp)
    80005cf6:	6122                	ld	sp,8(sp)
    80005cf8:	61c2                	ld	gp,16(sp)
    80005cfa:	7282                	ld	t0,32(sp)
    80005cfc:	7322                	ld	t1,40(sp)
    80005cfe:	73c2                	ld	t2,48(sp)
    80005d00:	7462                	ld	s0,56(sp)
    80005d02:	6486                	ld	s1,64(sp)
    80005d04:	6526                	ld	a0,72(sp)
    80005d06:	65c6                	ld	a1,80(sp)
    80005d08:	6666                	ld	a2,88(sp)
    80005d0a:	7686                	ld	a3,96(sp)
    80005d0c:	7726                	ld	a4,104(sp)
    80005d0e:	77c6                	ld	a5,112(sp)
    80005d10:	7866                	ld	a6,120(sp)
    80005d12:	688a                	ld	a7,128(sp)
    80005d14:	692a                	ld	s2,136(sp)
    80005d16:	69ca                	ld	s3,144(sp)
    80005d18:	6a6a                	ld	s4,152(sp)
    80005d1a:	7a8a                	ld	s5,160(sp)
    80005d1c:	7b2a                	ld	s6,168(sp)
    80005d1e:	7bca                	ld	s7,176(sp)
    80005d20:	7c6a                	ld	s8,184(sp)
    80005d22:	6c8e                	ld	s9,192(sp)
    80005d24:	6d2e                	ld	s10,200(sp)
    80005d26:	6dce                	ld	s11,208(sp)
    80005d28:	6e6e                	ld	t3,216(sp)
    80005d2a:	7e8e                	ld	t4,224(sp)
    80005d2c:	7f2e                	ld	t5,232(sp)
    80005d2e:	7fce                	ld	t6,240(sp)
    80005d30:	6111                	addi	sp,sp,256
    80005d32:	10200073          	sret
    80005d36:	00000013          	nop
    80005d3a:	00000013          	nop
    80005d3e:	0001                	nop

0000000080005d40 <timervec>:
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	e10c                	sd	a1,0(a0)
    80005d46:	e510                	sd	a2,8(a0)
    80005d48:	e914                	sd	a3,16(a0)
    80005d4a:	6d0c                	ld	a1,24(a0)
    80005d4c:	7110                	ld	a2,32(a0)
    80005d4e:	6194                	ld	a3,0(a1)
    80005d50:	96b2                	add	a3,a3,a2
    80005d52:	e194                	sd	a3,0(a1)
    80005d54:	4589                	li	a1,2
    80005d56:	14459073          	csrw	sip,a1
    80005d5a:	6914                	ld	a3,16(a0)
    80005d5c:	6510                	ld	a2,8(a0)
    80005d5e:	610c                	ld	a1,0(a0)
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	30200073          	mret
	...

0000000080005d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d6a:	1141                	addi	sp,sp,-16
    80005d6c:	e422                	sd	s0,8(sp)
    80005d6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d70:	0c0007b7          	lui	a5,0xc000
    80005d74:	4705                	li	a4,1
    80005d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d78:	c3d8                	sw	a4,4(a5)
}
    80005d7a:	6422                	ld	s0,8(sp)
    80005d7c:	0141                	addi	sp,sp,16
    80005d7e:	8082                	ret

0000000080005d80 <plicinithart>:

void
plicinithart(void)
{
    80005d80:	1141                	addi	sp,sp,-16
    80005d82:	e406                	sd	ra,8(sp)
    80005d84:	e022                	sd	s0,0(sp)
    80005d86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	bf8080e7          	jalr	-1032(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d90:	0085171b          	slliw	a4,a0,0x8
    80005d94:	0c0027b7          	lui	a5,0xc002
    80005d98:	97ba                	add	a5,a5,a4
    80005d9a:	40200713          	li	a4,1026
    80005d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005da2:	00d5151b          	slliw	a0,a0,0xd
    80005da6:	0c2017b7          	lui	a5,0xc201
    80005daa:	953e                	add	a0,a0,a5
    80005dac:	00052023          	sw	zero,0(a0)
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	addi	sp,sp,16
    80005db6:	8082                	ret

0000000080005db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005db8:	1141                	addi	sp,sp,-16
    80005dba:	e406                	sd	ra,8(sp)
    80005dbc:	e022                	sd	s0,0(sp)
    80005dbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	bc0080e7          	jalr	-1088(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dc8:	00d5179b          	slliw	a5,a0,0xd
    80005dcc:	0c201537          	lui	a0,0xc201
    80005dd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dd2:	4148                	lw	a0,4(a0)
    80005dd4:	60a2                	ld	ra,8(sp)
    80005dd6:	6402                	ld	s0,0(sp)
    80005dd8:	0141                	addi	sp,sp,16
    80005dda:	8082                	ret

0000000080005ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ddc:	1101                	addi	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	addi	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	b98080e7          	jalr	-1128(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005df0:	00d5151b          	slliw	a0,a0,0xd
    80005df4:	0c2017b7          	lui	a5,0xc201
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	c3c4                	sw	s1,4(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret

0000000080005e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e06:	1141                	addi	sp,sp,-16
    80005e08:	e406                	sd	ra,8(sp)
    80005e0a:	e022                	sd	s0,0(sp)
    80005e0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e0e:	479d                	li	a5,7
    80005e10:	04a7cc63          	blt	a5,a0,80005e68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e14:	0001c797          	auipc	a5,0x1c
    80005e18:	04c78793          	addi	a5,a5,76 # 80021e60 <disk>
    80005e1c:	97aa                	add	a5,a5,a0
    80005e1e:	0187c783          	lbu	a5,24(a5)
    80005e22:	ebb9                	bnez	a5,80005e78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e24:	00451613          	slli	a2,a0,0x4
    80005e28:	0001c797          	auipc	a5,0x1c
    80005e2c:	03878793          	addi	a5,a5,56 # 80021e60 <disk>
    80005e30:	6394                	ld	a3,0(a5)
    80005e32:	96b2                	add	a3,a3,a2
    80005e34:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e38:	6398                	ld	a4,0(a5)
    80005e3a:	9732                	add	a4,a4,a2
    80005e3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e48:	953e                	add	a0,a0,a5
    80005e4a:	4785                	li	a5,1
    80005e4c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e50:	0001c517          	auipc	a0,0x1c
    80005e54:	02850513          	addi	a0,a0,40 # 80021e78 <disk+0x18>
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	26c080e7          	jalr	620(ra) # 800020c4 <wakeup>
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret
    panic("free_desc 1");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	93850513          	addi	a0,a0,-1736 # 800087a0 <syscalls+0x310>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6ce080e7          	jalr	1742(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	93850513          	addi	a0,a0,-1736 # 800087b0 <syscalls+0x320>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6be080e7          	jalr	1726(ra) # 8000053e <panic>

0000000080005e88 <virtio_disk_init>:
{
    80005e88:	1101                	addi	sp,sp,-32
    80005e8a:	ec06                	sd	ra,24(sp)
    80005e8c:	e822                	sd	s0,16(sp)
    80005e8e:	e426                	sd	s1,8(sp)
    80005e90:	e04a                	sd	s2,0(sp)
    80005e92:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e94:	00003597          	auipc	a1,0x3
    80005e98:	92c58593          	addi	a1,a1,-1748 # 800087c0 <syscalls+0x330>
    80005e9c:	0001c517          	auipc	a0,0x1c
    80005ea0:	0ec50513          	addi	a0,a0,236 # 80021f88 <disk+0x128>
    80005ea4:	ffffb097          	auipc	ra,0xffffb
    80005ea8:	ca2080e7          	jalr	-862(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	4398                	lw	a4,0(a5)
    80005eb2:	2701                	sext.w	a4,a4
    80005eb4:	747277b7          	lui	a5,0x74727
    80005eb8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ebc:	14f71c63          	bne	a4,a5,80006014 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec0:	100017b7          	lui	a5,0x10001
    80005ec4:	43dc                	lw	a5,4(a5)
    80005ec6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec8:	4709                	li	a4,2
    80005eca:	14e79563          	bne	a5,a4,80006014 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	479c                	lw	a5,8(a5)
    80005ed4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ed6:	12e79f63          	bne	a5,a4,80006014 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	47d8                	lw	a4,12(a5)
    80005ee0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee2:	554d47b7          	lui	a5,0x554d4
    80005ee6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eea:	12f71563          	bne	a4,a5,80006014 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef6:	4705                	li	a4,1
    80005ef8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efa:	470d                	li	a4,3
    80005efc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005efe:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f00:	c7ffe737          	lui	a4,0xc7ffe
    80005f04:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7bf>
    80005f08:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f0a:	2701                	sext.w	a4,a4
    80005f0c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0e:	472d                	li	a4,11
    80005f10:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f12:	5bbc                	lw	a5,112(a5)
    80005f14:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f18:	8ba1                	andi	a5,a5,8
    80005f1a:	10078563          	beqz	a5,80006024 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f26:	43fc                	lw	a5,68(a5)
    80005f28:	2781                	sext.w	a5,a5
    80005f2a:	10079563          	bnez	a5,80006034 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2e:	100017b7          	lui	a5,0x10001
    80005f32:	5bdc                	lw	a5,52(a5)
    80005f34:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f36:	10078763          	beqz	a5,80006044 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005f3a:	471d                	li	a4,7
    80005f3c:	10f77c63          	bgeu	a4,a5,80006054 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	ba6080e7          	jalr	-1114(ra) # 80000ae6 <kalloc>
    80005f48:	0001c497          	auipc	s1,0x1c
    80005f4c:	f1848493          	addi	s1,s1,-232 # 80021e60 <disk>
    80005f50:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	b94080e7          	jalr	-1132(ra) # 80000ae6 <kalloc>
    80005f5a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	b8a080e7          	jalr	-1142(ra) # 80000ae6 <kalloc>
    80005f64:	87aa                	mv	a5,a0
    80005f66:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f68:	6088                	ld	a0,0(s1)
    80005f6a:	cd6d                	beqz	a0,80006064 <virtio_disk_init+0x1dc>
    80005f6c:	0001c717          	auipc	a4,0x1c
    80005f70:	efc73703          	ld	a4,-260(a4) # 80021e68 <disk+0x8>
    80005f74:	cb65                	beqz	a4,80006064 <virtio_disk_init+0x1dc>
    80005f76:	c7fd                	beqz	a5,80006064 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005f78:	6605                	lui	a2,0x1
    80005f7a:	4581                	li	a1,0
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	d56080e7          	jalr	-682(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f84:	0001c497          	auipc	s1,0x1c
    80005f88:	edc48493          	addi	s1,s1,-292 # 80021e60 <disk>
    80005f8c:	6605                	lui	a2,0x1
    80005f8e:	4581                	li	a1,0
    80005f90:	6488                	ld	a0,8(s1)
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	d40080e7          	jalr	-704(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f9a:	6605                	lui	a2,0x1
    80005f9c:	4581                	li	a1,0
    80005f9e:	6888                	ld	a0,16(s1)
    80005fa0:	ffffb097          	auipc	ra,0xffffb
    80005fa4:	d32080e7          	jalr	-718(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	4721                	li	a4,8
    80005fae:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fb0:	4098                	lw	a4,0(s1)
    80005fb2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fb6:	40d8                	lw	a4,4(s1)
    80005fb8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fbc:	6498                	ld	a4,8(s1)
    80005fbe:	0007069b          	sext.w	a3,a4
    80005fc2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fc6:	9701                	srai	a4,a4,0x20
    80005fc8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fcc:	6898                	ld	a4,16(s1)
    80005fce:	0007069b          	sext.w	a3,a4
    80005fd2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fd6:	9701                	srai	a4,a4,0x20
    80005fd8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fdc:	4705                	li	a4,1
    80005fde:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fe0:	00e48c23          	sb	a4,24(s1)
    80005fe4:	00e48ca3          	sb	a4,25(s1)
    80005fe8:	00e48d23          	sb	a4,26(s1)
    80005fec:	00e48da3          	sb	a4,27(s1)
    80005ff0:	00e48e23          	sb	a4,28(s1)
    80005ff4:	00e48ea3          	sb	a4,29(s1)
    80005ff8:	00e48f23          	sb	a4,30(s1)
    80005ffc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006000:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	0727a823          	sw	s2,112(a5)
}
    80006008:	60e2                	ld	ra,24(sp)
    8000600a:	6442                	ld	s0,16(sp)
    8000600c:	64a2                	ld	s1,8(sp)
    8000600e:	6902                	ld	s2,0(sp)
    80006010:	6105                	addi	sp,sp,32
    80006012:	8082                	ret
    panic("could not find virtio disk");
    80006014:	00002517          	auipc	a0,0x2
    80006018:	7bc50513          	addi	a0,a0,1980 # 800087d0 <syscalls+0x340>
    8000601c:	ffffa097          	auipc	ra,0xffffa
    80006020:	522080e7          	jalr	1314(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006024:	00002517          	auipc	a0,0x2
    80006028:	7cc50513          	addi	a0,a0,1996 # 800087f0 <syscalls+0x360>
    8000602c:	ffffa097          	auipc	ra,0xffffa
    80006030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006034:	00002517          	auipc	a0,0x2
    80006038:	7dc50513          	addi	a0,a0,2012 # 80008810 <syscalls+0x380>
    8000603c:	ffffa097          	auipc	ra,0xffffa
    80006040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006044:	00002517          	auipc	a0,0x2
    80006048:	7ec50513          	addi	a0,a0,2028 # 80008830 <syscalls+0x3a0>
    8000604c:	ffffa097          	auipc	ra,0xffffa
    80006050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006054:	00002517          	auipc	a0,0x2
    80006058:	7fc50513          	addi	a0,a0,2044 # 80008850 <syscalls+0x3c0>
    8000605c:	ffffa097          	auipc	ra,0xffffa
    80006060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006064:	00003517          	auipc	a0,0x3
    80006068:	80c50513          	addi	a0,a0,-2036 # 80008870 <syscalls+0x3e0>
    8000606c:	ffffa097          	auipc	ra,0xffffa
    80006070:	4d2080e7          	jalr	1234(ra) # 8000053e <panic>

0000000080006074 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006074:	7119                	addi	sp,sp,-128
    80006076:	fc86                	sd	ra,120(sp)
    80006078:	f8a2                	sd	s0,112(sp)
    8000607a:	f4a6                	sd	s1,104(sp)
    8000607c:	f0ca                	sd	s2,96(sp)
    8000607e:	ecce                	sd	s3,88(sp)
    80006080:	e8d2                	sd	s4,80(sp)
    80006082:	e4d6                	sd	s5,72(sp)
    80006084:	e0da                	sd	s6,64(sp)
    80006086:	fc5e                	sd	s7,56(sp)
    80006088:	f862                	sd	s8,48(sp)
    8000608a:	f466                	sd	s9,40(sp)
    8000608c:	f06a                	sd	s10,32(sp)
    8000608e:	ec6e                	sd	s11,24(sp)
    80006090:	0100                	addi	s0,sp,128
    80006092:	8aaa                	mv	s5,a0
    80006094:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006096:	00c52d03          	lw	s10,12(a0)
    8000609a:	001d1d1b          	slliw	s10,s10,0x1
    8000609e:	1d02                	slli	s10,s10,0x20
    800060a0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800060a4:	0001c517          	auipc	a0,0x1c
    800060a8:	ee450513          	addi	a0,a0,-284 # 80021f88 <disk+0x128>
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	b2a080e7          	jalr	-1238(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060b6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060b8:	0001cb97          	auipc	s7,0x1c
    800060bc:	da8b8b93          	addi	s7,s7,-600 # 80021e60 <disk>
  for(int i = 0; i < 3; i++){
    800060c0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c2:	0001cc97          	auipc	s9,0x1c
    800060c6:	ec6c8c93          	addi	s9,s9,-314 # 80021f88 <disk+0x128>
    800060ca:	a08d                	j	8000612c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060cc:	00fb8733          	add	a4,s7,a5
    800060d0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060d4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060d6:	0207c563          	bltz	a5,80006100 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060da:	2905                	addiw	s2,s2,1
    800060dc:	0611                	addi	a2,a2,4
    800060de:	05690c63          	beq	s2,s6,80006136 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060e2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060e4:	0001c717          	auipc	a4,0x1c
    800060e8:	d7c70713          	addi	a4,a4,-644 # 80021e60 <disk>
    800060ec:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060ee:	01874683          	lbu	a3,24(a4)
    800060f2:	fee9                	bnez	a3,800060cc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060f4:	2785                	addiw	a5,a5,1
    800060f6:	0705                	addi	a4,a4,1
    800060f8:	fe979be3          	bne	a5,s1,800060ee <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060fc:	57fd                	li	a5,-1
    800060fe:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006100:	01205d63          	blez	s2,8000611a <virtio_disk_rw+0xa6>
    80006104:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006106:	000a2503          	lw	a0,0(s4)
    8000610a:	00000097          	auipc	ra,0x0
    8000610e:	cfc080e7          	jalr	-772(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    80006112:	2d85                	addiw	s11,s11,1
    80006114:	0a11                	addi	s4,s4,4
    80006116:	ffb918e3          	bne	s2,s11,80006106 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000611a:	85e6                	mv	a1,s9
    8000611c:	0001c517          	auipc	a0,0x1c
    80006120:	d5c50513          	addi	a0,a0,-676 # 80021e78 <disk+0x18>
    80006124:	ffffc097          	auipc	ra,0xffffc
    80006128:	f3c080e7          	jalr	-196(ra) # 80002060 <sleep>
  for(int i = 0; i < 3; i++){
    8000612c:	f8040a13          	addi	s4,s0,-128
{
    80006130:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006132:	894e                	mv	s2,s3
    80006134:	b77d                	j	800060e2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006136:	f8042583          	lw	a1,-128(s0)
    8000613a:	00a58793          	addi	a5,a1,10
    8000613e:	0792                	slli	a5,a5,0x4

  if(write)
    80006140:	0001c617          	auipc	a2,0x1c
    80006144:	d2060613          	addi	a2,a2,-736 # 80021e60 <disk>
    80006148:	00f60733          	add	a4,a2,a5
    8000614c:	018036b3          	snez	a3,s8
    80006150:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006152:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006156:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000615a:	f6078693          	addi	a3,a5,-160
    8000615e:	6218                	ld	a4,0(a2)
    80006160:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006162:	00878513          	addi	a0,a5,8
    80006166:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006168:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000616a:	6208                	ld	a0,0(a2)
    8000616c:	96aa                	add	a3,a3,a0
    8000616e:	4741                	li	a4,16
    80006170:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006172:	4705                	li	a4,1
    80006174:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f8442703          	lw	a4,-124(s0)
    8000617c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006180:	0712                	slli	a4,a4,0x4
    80006182:	953a                	add	a0,a0,a4
    80006184:	058a8693          	addi	a3,s5,88
    80006188:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000618a:	6208                	ld	a0,0(a2)
    8000618c:	972a                	add	a4,a4,a0
    8000618e:	40000693          	li	a3,1024
    80006192:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006194:	001c3c13          	seqz	s8,s8
    80006198:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619a:	001c6c13          	ori	s8,s8,1
    8000619e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800061a2:	f8842603          	lw	a2,-120(s0)
    800061a6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061aa:	0001c697          	auipc	a3,0x1c
    800061ae:	cb668693          	addi	a3,a3,-842 # 80021e60 <disk>
    800061b2:	00258713          	addi	a4,a1,2
    800061b6:	0712                	slli	a4,a4,0x4
    800061b8:	9736                	add	a4,a4,a3
    800061ba:	587d                	li	a6,-1
    800061bc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061c0:	0612                	slli	a2,a2,0x4
    800061c2:	9532                	add	a0,a0,a2
    800061c4:	f9078793          	addi	a5,a5,-112
    800061c8:	97b6                	add	a5,a5,a3
    800061ca:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800061cc:	629c                	ld	a5,0(a3)
    800061ce:	97b2                	add	a5,a5,a2
    800061d0:	4605                	li	a2,1
    800061d2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d4:	4509                	li	a0,2
    800061d6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800061da:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061de:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800061e2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061e6:	6698                	ld	a4,8(a3)
    800061e8:	00275783          	lhu	a5,2(a4)
    800061ec:	8b9d                	andi	a5,a5,7
    800061ee:	0786                	slli	a5,a5,0x1
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061f6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061fa:	6698                	ld	a4,8(a3)
    800061fc:	00275783          	lhu	a5,2(a4)
    80006200:	2785                	addiw	a5,a5,1
    80006202:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006206:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000620a:	100017b7          	lui	a5,0x10001
    8000620e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006212:	004aa783          	lw	a5,4(s5)
    80006216:	02c79163          	bne	a5,a2,80006238 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000621a:	0001c917          	auipc	s2,0x1c
    8000621e:	d6e90913          	addi	s2,s2,-658 # 80021f88 <disk+0x128>
  while(b->disk == 1) {
    80006222:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006224:	85ca                	mv	a1,s2
    80006226:	8556                	mv	a0,s5
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	e38080e7          	jalr	-456(ra) # 80002060 <sleep>
  while(b->disk == 1) {
    80006230:	004aa783          	lw	a5,4(s5)
    80006234:	fe9788e3          	beq	a5,s1,80006224 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006238:	f8042903          	lw	s2,-128(s0)
    8000623c:	00290793          	addi	a5,s2,2
    80006240:	00479713          	slli	a4,a5,0x4
    80006244:	0001c797          	auipc	a5,0x1c
    80006248:	c1c78793          	addi	a5,a5,-996 # 80021e60 <disk>
    8000624c:	97ba                	add	a5,a5,a4
    8000624e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006252:	0001c997          	auipc	s3,0x1c
    80006256:	c0e98993          	addi	s3,s3,-1010 # 80021e60 <disk>
    8000625a:	00491713          	slli	a4,s2,0x4
    8000625e:	0009b783          	ld	a5,0(s3)
    80006262:	97ba                	add	a5,a5,a4
    80006264:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006268:	854a                	mv	a0,s2
    8000626a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000626e:	00000097          	auipc	ra,0x0
    80006272:	b98080e7          	jalr	-1128(ra) # 80005e06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006276:	8885                	andi	s1,s1,1
    80006278:	f0ed                	bnez	s1,8000625a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000627a:	0001c517          	auipc	a0,0x1c
    8000627e:	d0e50513          	addi	a0,a0,-754 # 80021f88 <disk+0x128>
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
}
    8000628a:	70e6                	ld	ra,120(sp)
    8000628c:	7446                	ld	s0,112(sp)
    8000628e:	74a6                	ld	s1,104(sp)
    80006290:	7906                	ld	s2,96(sp)
    80006292:	69e6                	ld	s3,88(sp)
    80006294:	6a46                	ld	s4,80(sp)
    80006296:	6aa6                	ld	s5,72(sp)
    80006298:	6b06                	ld	s6,64(sp)
    8000629a:	7be2                	ld	s7,56(sp)
    8000629c:	7c42                	ld	s8,48(sp)
    8000629e:	7ca2                	ld	s9,40(sp)
    800062a0:	7d02                	ld	s10,32(sp)
    800062a2:	6de2                	ld	s11,24(sp)
    800062a4:	6109                	addi	sp,sp,128
    800062a6:	8082                	ret

00000000800062a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062a8:	1101                	addi	sp,sp,-32
    800062aa:	ec06                	sd	ra,24(sp)
    800062ac:	e822                	sd	s0,16(sp)
    800062ae:	e426                	sd	s1,8(sp)
    800062b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062b2:	0001c497          	auipc	s1,0x1c
    800062b6:	bae48493          	addi	s1,s1,-1106 # 80021e60 <disk>
    800062ba:	0001c517          	auipc	a0,0x1c
    800062be:	cce50513          	addi	a0,a0,-818 # 80021f88 <disk+0x128>
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	914080e7          	jalr	-1772(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ca:	10001737          	lui	a4,0x10001
    800062ce:	533c                	lw	a5,96(a4)
    800062d0:	8b8d                	andi	a5,a5,3
    800062d2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062d4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062d8:	689c                	ld	a5,16(s1)
    800062da:	0204d703          	lhu	a4,32(s1)
    800062de:	0027d783          	lhu	a5,2(a5)
    800062e2:	04f70863          	beq	a4,a5,80006332 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062e6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ea:	6898                	ld	a4,16(s1)
    800062ec:	0204d783          	lhu	a5,32(s1)
    800062f0:	8b9d                	andi	a5,a5,7
    800062f2:	078e                	slli	a5,a5,0x3
    800062f4:	97ba                	add	a5,a5,a4
    800062f6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062f8:	00278713          	addi	a4,a5,2
    800062fc:	0712                	slli	a4,a4,0x4
    800062fe:	9726                	add	a4,a4,s1
    80006300:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006304:	e721                	bnez	a4,8000634c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006306:	0789                	addi	a5,a5,2
    80006308:	0792                	slli	a5,a5,0x4
    8000630a:	97a6                	add	a5,a5,s1
    8000630c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000630e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	db2080e7          	jalr	-590(ra) # 800020c4 <wakeup>

    disk.used_idx += 1;
    8000631a:	0204d783          	lhu	a5,32(s1)
    8000631e:	2785                	addiw	a5,a5,1
    80006320:	17c2                	slli	a5,a5,0x30
    80006322:	93c1                	srli	a5,a5,0x30
    80006324:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006328:	6898                	ld	a4,16(s1)
    8000632a:	00275703          	lhu	a4,2(a4)
    8000632e:	faf71ce3          	bne	a4,a5,800062e6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006332:	0001c517          	auipc	a0,0x1c
    80006336:	c5650513          	addi	a0,a0,-938 # 80021f88 <disk+0x128>
    8000633a:	ffffb097          	auipc	ra,0xffffb
    8000633e:	950080e7          	jalr	-1712(ra) # 80000c8a <release>
}
    80006342:	60e2                	ld	ra,24(sp)
    80006344:	6442                	ld	s0,16(sp)
    80006346:	64a2                	ld	s1,8(sp)
    80006348:	6105                	addi	sp,sp,32
    8000634a:	8082                	ret
      panic("virtio_disk_intr status");
    8000634c:	00002517          	auipc	a0,0x2
    80006350:	53c50513          	addi	a0,a0,1340 # 80008888 <syscalls+0x3f8>
    80006354:	ffffa097          	auipc	ra,0xffffa
    80006358:	1ea080e7          	jalr	490(ra) # 8000053e <panic>
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
