
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6010113          	addi	sp,sp,-1440 # 80008a60 <stack0>
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
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
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
    80000068:	dec78793          	addi	a5,a5,-532 # 80005e50 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc86f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e2678793          	addi	a5,a5,-474 # 80000ed4 <main>
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
    80000130:	3ee080e7          	jalr	1006(ra) # 8000251a <either_copyin>
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
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	aa0080e7          	jalr	-1376(ra) # 80000c32 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	848080e7          	jalr	-1976(ra) # 80001a08 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	19c080e7          	jalr	412(ra) # 80002364 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ee6080e7          	jalr	-282(ra) # 800020bc <sleep>
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
    80000216:	2b2080e7          	jalr	690(ra) # 800024c4 <either_copyout>
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
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	ab8080e7          	jalr	-1352(ra) # 80000ce6 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	aa2080e7          	jalr	-1374(ra) # 80000ce6 <release>
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
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
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
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	95e080e7          	jalr	-1698(ra) # 80000c32 <acquire>

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
    800002f6:	27e080e7          	jalr	638(ra) # 80002570 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9e4080e7          	jalr	-1564(ra) # 80000ce6 <release>
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
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
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
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
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
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
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
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
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
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
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
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cda080e7          	jalr	-806(ra) # 80002120 <wakeup>
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
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	73a080e7          	jalr	1850(ra) # 80000ba2 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	98078793          	addi	a5,a5,-1664 # 80020df8 <devsw>
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
    8000054e:	5c07ab23          	sw	zero,1494(a5) # 80010b20 <pr+0x18>
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
    80000582:	36f72123          	sw	a5,866(a4) # 800088e0 <panicked>
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
    800005be:	566dad83          	lw	s11,1382(s11) # 80010b20 <pr+0x18>
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
    800005fc:	51050513          	addi	a0,a0,1296 # 80010b08 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	632080e7          	jalr	1586(ra) # 80000c32 <acquire>
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
    8000075a:	3b250513          	addi	a0,a0,946 # 80010b08 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	588080e7          	jalr	1416(ra) # 80000ce6 <release>
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
    80000776:	39648493          	addi	s1,s1,918 # 80010b08 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	41e080e7          	jalr	1054(ra) # 80000ba2 <initlock>
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
    800007d6:	35650513          	addi	a0,a0,854 # 80010b28 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	3c8080e7          	jalr	968(ra) # 80000ba2 <initlock>
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
    800007fa:	3f0080e7          	jalr	1008(ra) # 80000be6 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0e27a783          	lw	a5,226(a5) # 800088e0 <panicked>
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
    80000828:	462080e7          	jalr	1122(ra) # 80000c86 <pop_off>
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
    8000083a:	0b27b783          	ld	a5,178(a5) # 800088e8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0b273703          	ld	a4,178(a4) # 800088f0 <uart_tx_w>
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
    80000864:	2c8a0a13          	addi	s4,s4,712 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	08048493          	addi	s1,s1,128 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	08098993          	addi	s3,s3,128 # 800088f0 <uart_tx_w>
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
    80000896:	88e080e7          	jalr	-1906(ra) # 80002120 <wakeup>
    
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
    800008d2:	25a50513          	addi	a0,a0,602 # 80010b28 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	35c080e7          	jalr	860(ra) # 80000c32 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0027a783          	lw	a5,2(a5) # 800088e0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	00873703          	ld	a4,8(a4) # 800088f0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	ff87b783          	ld	a5,-8(a5) # 800088e8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	22c98993          	addi	s3,s3,556 # 80010b28 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fe448493          	addi	s1,s1,-28 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fe490913          	addi	s2,s2,-28 # 800088f0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7a0080e7          	jalr	1952(ra) # 800020bc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1f648493          	addi	s1,s1,502 # 80010b28 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7b523          	sd	a4,-86(a5) # 800088f0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	38e080e7          	jalr	910(ra) # 80000ce6 <release>
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
    800009c0:	16c48493          	addi	s1,s1,364 # 80010b28 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	26c080e7          	jalr	620(ra) # 80000c32 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	30e080e7          	jalr	782(ra) # 80000ce6 <release>
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
    80000a02:	59278793          	addi	a5,a5,1426 # 80021f90 <end>
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
    80000a1a:	318080e7          	jalr	792(ra) # 80000d2e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	14290913          	addi	s2,s2,322 # 80010b60 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	20a080e7          	jalr	522(ra) # 80000c32 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2aa080e7          	jalr	682(ra) # 80000ce6 <release>
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
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0e0080e7          	jalr	224(ra) # 80000ba2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	4c250513          	addi	a0,a0,1218 # 80021f90 <end>
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
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	138080e7          	jalr	312(ra) # 80000c32 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1d4080e7          	jalr	468(ra) # 80000ce6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	20e080e7          	jalr	526(ra) # 80000d2e <memset>
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
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	1aa080e7          	jalr	426(ra) # 80000ce6 <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <nfreemem>:
//   return n * 4096;
// }

uint64
nfreemem()
{
    80000b46:	1101                	addi	sp,sp,-32
    80000b48:	ec06                	sd	ra,24(sp)
    80000b4a:	e822                	sd	s0,16(sp)
    80000b4c:	e426                	sd	s1,8(sp)
    80000b4e:	e04a                	sd	s2,0(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r = kmem.freelist;
    80000b52:	00010517          	auipc	a0,0x10
    80000b56:	00e50513          	addi	a0,a0,14 # 80010b60 <kmem>
    80000b5a:	6d04                	ld	s1,24(a0)
  uint64 nbytes = 0;

  acquire(&kmem.lock);
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0d6080e7          	jalr	214(ra) # 80000c32 <acquire>
  while (r) {
    80000b64:	c48d                	beqz	s1,80000b8e <nfreemem+0x48>
  uint64 nbytes = 0;
    80000b66:	4901                	li	s2,0
    nbytes += PGSIZE;
    80000b68:	6785                	lui	a5,0x1
    80000b6a:	993e                	add	s2,s2,a5
    r = r->next;
    80000b6c:	6084                	ld	s1,0(s1)
  while (r) {
    80000b6e:	fcf5                	bnez	s1,80000b6a <nfreemem+0x24>
  }
  release(&kmem.lock);
    80000b70:	00010517          	auipc	a0,0x10
    80000b74:	ff050513          	addi	a0,a0,-16 # 80010b60 <kmem>
    80000b78:	00000097          	auipc	ra,0x0
    80000b7c:	16e080e7          	jalr	366(ra) # 80000ce6 <release>

  return nbytes;
}
    80000b80:	854a                	mv	a0,s2
    80000b82:	60e2                	ld	ra,24(sp)
    80000b84:	6442                	ld	s0,16(sp)
    80000b86:	64a2                	ld	s1,8(sp)
    80000b88:	6902                	ld	s2,0(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret
  uint64 nbytes = 0;
    80000b8e:	4901                	li	s2,0
    80000b90:	b7c5                	j	80000b70 <nfreemem+0x2a>

0000000080000b92 <getTotalRam>:

uint64
getTotalRam()
{
    80000b92:	1141                	addi	sp,sp,-16
    80000b94:	e422                	sd	s0,8(sp)
    80000b96:	0800                	addi	s0,sp,16
  return KERNBASE - PHYSTOP;
    80000b98:	f8000537          	lui	a0,0xf8000
    80000b9c:	6422                	ld	s0,8(sp)
    80000b9e:	0141                	addi	sp,sp,16
    80000ba0:	8082                	ret

0000000080000ba2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba2:	1141                	addi	sp,sp,-16
    80000ba4:	e422                	sd	s0,8(sp)
    80000ba6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ba8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000baa:	00052023          	sw	zero,0(a0) # fffffffff8000000 <end+0xffffffff77fde070>
  lk->cpu = 0;
    80000bae:	00053823          	sd	zero,16(a0)
}
    80000bb2:	6422                	ld	s0,8(sp)
    80000bb4:	0141                	addi	sp,sp,16
    80000bb6:	8082                	ret

0000000080000bb8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	411c                	lw	a5,0(a0)
    80000bba:	e399                	bnez	a5,80000bc0 <holding+0x8>
    80000bbc:	4501                	li	a0,0
  return r;
}
    80000bbe:	8082                	ret
{
    80000bc0:	1101                	addi	sp,sp,-32
    80000bc2:	ec06                	sd	ra,24(sp)
    80000bc4:	e822                	sd	s0,16(sp)
    80000bc6:	e426                	sd	s1,8(sp)
    80000bc8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bca:	6904                	ld	s1,16(a0)
    80000bcc:	00001097          	auipc	ra,0x1
    80000bd0:	e20080e7          	jalr	-480(ra) # 800019ec <mycpu>
    80000bd4:	40a48533          	sub	a0,s1,a0
    80000bd8:	00153513          	seqz	a0,a0
}
    80000bdc:	60e2                	ld	ra,24(sp)
    80000bde:	6442                	ld	s0,16(sp)
    80000be0:	64a2                	ld	s1,8(sp)
    80000be2:	6105                	addi	sp,sp,32
    80000be4:	8082                	ret

0000000080000be6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf0:	100024f3          	csrr	s1,sstatus
    80000bf4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bf8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bfa:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bfe:	00001097          	auipc	ra,0x1
    80000c02:	dee080e7          	jalr	-530(ra) # 800019ec <mycpu>
    80000c06:	5d3c                	lw	a5,120(a0)
    80000c08:	cf89                	beqz	a5,80000c22 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c0a:	00001097          	auipc	ra,0x1
    80000c0e:	de2080e7          	jalr	-542(ra) # 800019ec <mycpu>
    80000c12:	5d3c                	lw	a5,120(a0)
    80000c14:	2785                	addiw	a5,a5,1
    80000c16:	dd3c                	sw	a5,120(a0)
}
    80000c18:	60e2                	ld	ra,24(sp)
    80000c1a:	6442                	ld	s0,16(sp)
    80000c1c:	64a2                	ld	s1,8(sp)
    80000c1e:	6105                	addi	sp,sp,32
    80000c20:	8082                	ret
    mycpu()->intena = old;
    80000c22:	00001097          	auipc	ra,0x1
    80000c26:	dca080e7          	jalr	-566(ra) # 800019ec <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8085                	srli	s1,s1,0x1
    80000c2c:	8885                	andi	s1,s1,1
    80000c2e:	dd64                	sw	s1,124(a0)
    80000c30:	bfe9                	j	80000c0a <push_off+0x24>

0000000080000c32 <acquire>:
{
    80000c32:	1101                	addi	sp,sp,-32
    80000c34:	ec06                	sd	ra,24(sp)
    80000c36:	e822                	sd	s0,16(sp)
    80000c38:	e426                	sd	s1,8(sp)
    80000c3a:	1000                	addi	s0,sp,32
    80000c3c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	fa8080e7          	jalr	-88(ra) # 80000be6 <push_off>
  if(holding(lk))
    80000c46:	8526                	mv	a0,s1
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	f70080e7          	jalr	-144(ra) # 80000bb8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c50:	4705                	li	a4,1
  if(holding(lk))
    80000c52:	e115                	bnez	a0,80000c76 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c54:	87ba                	mv	a5,a4
    80000c56:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c5a:	2781                	sext.w	a5,a5
    80000c5c:	ffe5                	bnez	a5,80000c54 <acquire+0x22>
  __sync_synchronize();
    80000c5e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	d8a080e7          	jalr	-630(ra) # 800019ec <mycpu>
    80000c6a:	e888                	sd	a0,16(s1)
}
    80000c6c:	60e2                	ld	ra,24(sp)
    80000c6e:	6442                	ld	s0,16(sp)
    80000c70:	64a2                	ld	s1,8(sp)
    80000c72:	6105                	addi	sp,sp,32
    80000c74:	8082                	ret
    panic("acquire");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	3fa50513          	addi	a0,a0,1018 # 80008070 <digits+0x30>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8c0080e7          	jalr	-1856(ra) # 8000053e <panic>

0000000080000c86 <pop_off>:

void
pop_off(void)
{
    80000c86:	1141                	addi	sp,sp,-16
    80000c88:	e406                	sd	ra,8(sp)
    80000c8a:	e022                	sd	s0,0(sp)
    80000c8c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	d5e080e7          	jalr	-674(ra) # 800019ec <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c96:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c9a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c9c:	e78d                	bnez	a5,80000cc6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c9e:	5d3c                	lw	a5,120(a0)
    80000ca0:	02f05b63          	blez	a5,80000cd6 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ca4:	37fd                	addiw	a5,a5,-1
    80000ca6:	0007871b          	sext.w	a4,a5
    80000caa:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cac:	eb09                	bnez	a4,80000cbe <pop_off+0x38>
    80000cae:	5d7c                	lw	a5,124(a0)
    80000cb0:	c799                	beqz	a5,80000cbe <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cba:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cbe:	60a2                	ld	ra,8(sp)
    80000cc0:	6402                	ld	s0,0(sp)
    80000cc2:	0141                	addi	sp,sp,16
    80000cc4:	8082                	ret
    panic("pop_off - interruptible");
    80000cc6:	00007517          	auipc	a0,0x7
    80000cca:	3b250513          	addi	a0,a0,946 # 80008078 <digits+0x38>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>
    panic("pop_off");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3ba50513          	addi	a0,a0,954 # 80008090 <digits+0x50>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>

0000000080000ce6 <release>:
{
    80000ce6:	1101                	addi	sp,sp,-32
    80000ce8:	ec06                	sd	ra,24(sp)
    80000cea:	e822                	sd	s0,16(sp)
    80000cec:	e426                	sd	s1,8(sp)
    80000cee:	1000                	addi	s0,sp,32
    80000cf0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	ec6080e7          	jalr	-314(ra) # 80000bb8 <holding>
    80000cfa:	c115                	beqz	a0,80000d1e <release+0x38>
  lk->cpu = 0;
    80000cfc:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d00:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d04:	0f50000f          	fence	iorw,ow
    80000d08:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	f7a080e7          	jalr	-134(ra) # 80000c86 <pop_off>
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    panic("release");
    80000d1e:	00007517          	auipc	a0,0x7
    80000d22:	37a50513          	addi	a0,a0,890 # 80008098 <digits+0x58>
    80000d26:	00000097          	auipc	ra,0x0
    80000d2a:	818080e7          	jalr	-2024(ra) # 8000053e <panic>

0000000080000d2e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d34:	ca19                	beqz	a2,80000d4a <memset+0x1c>
    80000d36:	87aa                	mv	a5,a0
    80000d38:	1602                	slli	a2,a2,0x20
    80000d3a:	9201                	srli	a2,a2,0x20
    80000d3c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d40:	00b78023          	sb	a1,0(a5) # 1000 <_entry-0x7ffff000>
  for(i = 0; i < n; i++){
    80000d44:	0785                	addi	a5,a5,1
    80000d46:	fee79de3          	bne	a5,a4,80000d40 <memset+0x12>
  }
  return dst;
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	addi	sp,sp,16
    80000d4e:	8082                	ret

0000000080000d50 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d50:	1141                	addi	sp,sp,-16
    80000d52:	e422                	sd	s0,8(sp)
    80000d54:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d56:	ca05                	beqz	a2,80000d86 <memcmp+0x36>
    80000d58:	fff6069b          	addiw	a3,a2,-1
    80000d5c:	1682                	slli	a3,a3,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	0685                	addi	a3,a3,1
    80000d62:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d64:	00054783          	lbu	a5,0(a0)
    80000d68:	0005c703          	lbu	a4,0(a1)
    80000d6c:	00e79863          	bne	a5,a4,80000d7c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d70:	0505                	addi	a0,a0,1
    80000d72:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d74:	fed518e3          	bne	a0,a3,80000d64 <memcmp+0x14>
  }

  return 0;
    80000d78:	4501                	li	a0,0
    80000d7a:	a019                	j	80000d80 <memcmp+0x30>
      return *s1 - *s2;
    80000d7c:	40e7853b          	subw	a0,a5,a4
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  return 0;
    80000d86:	4501                	li	a0,0
    80000d88:	bfe5                	j	80000d80 <memcmp+0x30>

0000000080000d8a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e422                	sd	s0,8(sp)
    80000d8e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d90:	c205                	beqz	a2,80000db0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d92:	02a5e263          	bltu	a1,a0,80000db6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d96:	1602                	slli	a2,a2,0x20
    80000d98:	9201                	srli	a2,a2,0x20
    80000d9a:	00c587b3          	add	a5,a1,a2
{
    80000d9e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da0:	0585                	addi	a1,a1,1
    80000da2:	0705                	addi	a4,a4,1
    80000da4:	fff5c683          	lbu	a3,-1(a1)
    80000da8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dac:	fef59ae3          	bne	a1,a5,80000da0 <memmove+0x16>

  return dst;
}
    80000db0:	6422                	ld	s0,8(sp)
    80000db2:	0141                	addi	sp,sp,16
    80000db4:	8082                	ret
  if(s < d && s + n > d){
    80000db6:	02061693          	slli	a3,a2,0x20
    80000dba:	9281                	srli	a3,a3,0x20
    80000dbc:	00d58733          	add	a4,a1,a3
    80000dc0:	fce57be3          	bgeu	a0,a4,80000d96 <memmove+0xc>
    d += n;
    80000dc4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dc6:	fff6079b          	addiw	a5,a2,-1
    80000dca:	1782                	slli	a5,a5,0x20
    80000dcc:	9381                	srli	a5,a5,0x20
    80000dce:	fff7c793          	not	a5,a5
    80000dd2:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dd4:	177d                	addi	a4,a4,-1
    80000dd6:	16fd                	addi	a3,a3,-1
    80000dd8:	00074603          	lbu	a2,0(a4)
    80000ddc:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de0:	fee79ae3          	bne	a5,a4,80000dd4 <memmove+0x4a>
    80000de4:	b7f1                	j	80000db0 <memmove+0x26>

0000000080000de6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000de6:	1141                	addi	sp,sp,-16
    80000de8:	e406                	sd	ra,8(sp)
    80000dea:	e022                	sd	s0,0(sp)
    80000dec:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	f9c080e7          	jalr	-100(ra) # 80000d8a <memmove>
}
    80000df6:	60a2                	ld	ra,8(sp)
    80000df8:	6402                	ld	s0,0(sp)
    80000dfa:	0141                	addi	sp,sp,16
    80000dfc:	8082                	ret

0000000080000dfe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dfe:	1141                	addi	sp,sp,-16
    80000e00:	e422                	sd	s0,8(sp)
    80000e02:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e04:	ce11                	beqz	a2,80000e20 <strncmp+0x22>
    80000e06:	00054783          	lbu	a5,0(a0)
    80000e0a:	cf89                	beqz	a5,80000e24 <strncmp+0x26>
    80000e0c:	0005c703          	lbu	a4,0(a1)
    80000e10:	00f71a63          	bne	a4,a5,80000e24 <strncmp+0x26>
    n--, p++, q++;
    80000e14:	367d                	addiw	a2,a2,-1
    80000e16:	0505                	addi	a0,a0,1
    80000e18:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e1a:	f675                	bnez	a2,80000e06 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e1c:	4501                	li	a0,0
    80000e1e:	a809                	j	80000e30 <strncmp+0x32>
    80000e20:	4501                	li	a0,0
    80000e22:	a039                	j	80000e30 <strncmp+0x32>
  if(n == 0)
    80000e24:	ca09                	beqz	a2,80000e36 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e26:	00054503          	lbu	a0,0(a0)
    80000e2a:	0005c783          	lbu	a5,0(a1)
    80000e2e:	9d1d                	subw	a0,a0,a5
}
    80000e30:	6422                	ld	s0,8(sp)
    80000e32:	0141                	addi	sp,sp,16
    80000e34:	8082                	ret
    return 0;
    80000e36:	4501                	li	a0,0
    80000e38:	bfe5                	j	80000e30 <strncmp+0x32>

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	872a                	mv	a4,a0
    80000e42:	8832                	mv	a6,a2
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	01005963          	blez	a6,80000e58 <strncpy+0x1e>
    80000e4a:	0705                	addi	a4,a4,1
    80000e4c:	0005c783          	lbu	a5,0(a1)
    80000e50:	fef70fa3          	sb	a5,-1(a4)
    80000e54:	0585                	addi	a1,a1,1
    80000e56:	f7f5                	bnez	a5,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	86ba                	mv	a3,a4
    80000e5a:	00c05c63          	blez	a2,80000e72 <strncpy+0x38>
    *s++ = 0;
    80000e5e:	0685                	addi	a3,a3,1
    80000e60:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e64:	fff6c793          	not	a5,a3
    80000e68:	9fb9                	addw	a5,a5,a4
    80000e6a:	010787bb          	addw	a5,a5,a6
    80000e6e:	fef048e3          	bgtz	a5,80000e5e <strncpy+0x24>
  return os;
}
    80000e72:	6422                	ld	s0,8(sp)
    80000e74:	0141                	addi	sp,sp,16
    80000e76:	8082                	ret

0000000080000e78 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e422                	sd	s0,8(sp)
    80000e7c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7e:	02c05363          	blez	a2,80000ea4 <safestrcpy+0x2c>
    80000e82:	fff6069b          	addiw	a3,a2,-1
    80000e86:	1682                	slli	a3,a3,0x20
    80000e88:	9281                	srli	a3,a3,0x20
    80000e8a:	96ae                	add	a3,a3,a1
    80000e8c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8e:	00d58963          	beq	a1,a3,80000ea0 <safestrcpy+0x28>
    80000e92:	0585                	addi	a1,a1,1
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff5c703          	lbu	a4,-1(a1)
    80000e9a:	fee78fa3          	sb	a4,-1(a5)
    80000e9e:	fb65                	bnez	a4,80000e8e <safestrcpy+0x16>
    ;
  *s = 0;
    80000ea0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea4:	6422                	ld	s0,8(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret

0000000080000eaa <strlen>:

int
strlen(const char *s)
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e422                	sd	s0,8(sp)
    80000eae:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eb0:	00054783          	lbu	a5,0(a0)
    80000eb4:	cf91                	beqz	a5,80000ed0 <strlen+0x26>
    80000eb6:	0505                	addi	a0,a0,1
    80000eb8:	87aa                	mv	a5,a0
    80000eba:	4685                	li	a3,1
    80000ebc:	9e89                	subw	a3,a3,a0
    80000ebe:	00f6853b          	addw	a0,a3,a5
    80000ec2:	0785                	addi	a5,a5,1
    80000ec4:	fff7c703          	lbu	a4,-1(a5)
    80000ec8:	fb7d                	bnez	a4,80000ebe <strlen+0x14>
    ;
  return n;
}
    80000eca:	6422                	ld	s0,8(sp)
    80000ecc:	0141                	addi	sp,sp,16
    80000ece:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ed0:	4501                	li	a0,0
    80000ed2:	bfe5                	j	80000eca <strlen+0x20>

0000000080000ed4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed4:	1141                	addi	sp,sp,-16
    80000ed6:	e406                	sd	ra,8(sp)
    80000ed8:	e022                	sd	s0,0(sp)
    80000eda:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000edc:	00001097          	auipc	ra,0x1
    80000ee0:	b00080e7          	jalr	-1280(ra) # 800019dc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee4:	00008717          	auipc	a4,0x8
    80000ee8:	a1470713          	addi	a4,a4,-1516 # 800088f8 <started>
  if(cpuid() == 0){
    80000eec:	c139                	beqz	a0,80000f32 <main+0x5e>
    while(started == 0)
    80000eee:	431c                	lw	a5,0(a4)
    80000ef0:	2781                	sext.w	a5,a5
    80000ef2:	dff5                	beqz	a5,80000eee <main+0x1a>
      ;
    __sync_synchronize();
    80000ef4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef8:	00001097          	auipc	ra,0x1
    80000efc:	ae4080e7          	jalr	-1308(ra) # 800019dc <cpuid>
    80000f00:	85aa                	mv	a1,a0
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1b650513          	addi	a0,a0,438 # 800080b8 <digits+0x78>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	67e080e7          	jalr	1662(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	0d8080e7          	jalr	216(ra) # 80000fea <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f1a:	00002097          	auipc	ra,0x2
    80000f1e:	90a080e7          	jalr	-1782(ra) # 80002824 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f22:	00005097          	auipc	ra,0x5
    80000f26:	f6e080e7          	jalr	-146(ra) # 80005e90 <plicinithart>
  }

  scheduler();        
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	fe0080e7          	jalr	-32(ra) # 80001f0a <scheduler>
    consoleinit();
    80000f32:	fffff097          	auipc	ra,0xfffff
    80000f36:	51e080e7          	jalr	1310(ra) # 80000450 <consoleinit>
    printfinit();
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	82e080e7          	jalr	-2002(ra) # 80000768 <printfinit>
    printf("\n");
    80000f42:	00007517          	auipc	a0,0x7
    80000f46:	18650513          	addi	a0,a0,390 # 800080c8 <digits+0x88>
    80000f4a:	fffff097          	auipc	ra,0xfffff
    80000f4e:	63e080e7          	jalr	1598(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f52:	00007517          	auipc	a0,0x7
    80000f56:	14e50513          	addi	a0,a0,334 # 800080a0 <digits+0x60>
    80000f5a:	fffff097          	auipc	ra,0xfffff
    80000f5e:	62e080e7          	jalr	1582(ra) # 80000588 <printf>
    printf("\n");
    80000f62:	00007517          	auipc	a0,0x7
    80000f66:	16650513          	addi	a0,a0,358 # 800080c8 <digits+0x88>
    80000f6a:	fffff097          	auipc	ra,0xfffff
    80000f6e:	61e080e7          	jalr	1566(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	b38080e7          	jalr	-1224(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	326080e7          	jalr	806(ra) # 800012a0 <kvminit>
    kvminithart();   // turn on paging
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	068080e7          	jalr	104(ra) # 80000fea <kvminithart>
    procinit();      // process table
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	99e080e7          	jalr	-1634(ra) # 80001928 <procinit>
    trapinit();      // trap vectors
    80000f92:	00002097          	auipc	ra,0x2
    80000f96:	86a080e7          	jalr	-1942(ra) # 800027fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	88a080e7          	jalr	-1910(ra) # 80002824 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	ed8080e7          	jalr	-296(ra) # 80005e7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000faa:	00005097          	auipc	ra,0x5
    80000fae:	ee6080e7          	jalr	-282(ra) # 80005e90 <plicinithart>
    binit();         // buffer cache
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	082080e7          	jalr	130(ra) # 80003034 <binit>
    iinit();         // inode table
    80000fba:	00002097          	auipc	ra,0x2
    80000fbe:	726080e7          	jalr	1830(ra) # 800036e0 <iinit>
    fileinit();      // file table
    80000fc2:	00003097          	auipc	ra,0x3
    80000fc6:	6c4080e7          	jalr	1732(ra) # 80004686 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fca:	00005097          	auipc	ra,0x5
    80000fce:	fce080e7          	jalr	-50(ra) # 80005f98 <virtio_disk_init>
    userinit();      // first user process
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	d1a080e7          	jalr	-742(ra) # 80001cec <userinit>
    __sync_synchronize();
    80000fda:	0ff0000f          	fence
    started = 1;
    80000fde:	4785                	li	a5,1
    80000fe0:	00008717          	auipc	a4,0x8
    80000fe4:	90f72c23          	sw	a5,-1768(a4) # 800088f8 <started>
    80000fe8:	b789                	j	80000f2a <main+0x56>

0000000080000fea <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fea:	1141                	addi	sp,sp,-16
    80000fec:	e422                	sd	s0,8(sp)
    80000fee:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ff4:	00008797          	auipc	a5,0x8
    80000ff8:	90c7b783          	ld	a5,-1780(a5) # 80008900 <kernel_pagetable>
    80000ffc:	83b1                	srli	a5,a5,0xc
    80000ffe:	577d                	li	a4,-1
    80001000:	177e                	slli	a4,a4,0x3f
    80001002:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001004:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001008:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000100c:	6422                	ld	s0,8(sp)
    8000100e:	0141                	addi	sp,sp,16
    80001010:	8082                	ret

0000000080001012 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001012:	7139                	addi	sp,sp,-64
    80001014:	fc06                	sd	ra,56(sp)
    80001016:	f822                	sd	s0,48(sp)
    80001018:	f426                	sd	s1,40(sp)
    8000101a:	f04a                	sd	s2,32(sp)
    8000101c:	ec4e                	sd	s3,24(sp)
    8000101e:	e852                	sd	s4,16(sp)
    80001020:	e456                	sd	s5,8(sp)
    80001022:	e05a                	sd	s6,0(sp)
    80001024:	0080                	addi	s0,sp,64
    80001026:	84aa                	mv	s1,a0
    80001028:	89ae                	mv	s3,a1
    8000102a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000102c:	57fd                	li	a5,-1
    8000102e:	83e9                	srli	a5,a5,0x1a
    80001030:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001032:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001034:	04b7f263          	bgeu	a5,a1,80001078 <walk+0x66>
    panic("walk");
    80001038:	00007517          	auipc	a0,0x7
    8000103c:	09850513          	addi	a0,a0,152 # 800080d0 <digits+0x90>
    80001040:	fffff097          	auipc	ra,0xfffff
    80001044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001048:	060a8663          	beqz	s5,800010b4 <walk+0xa2>
    8000104c:	00000097          	auipc	ra,0x0
    80001050:	a9a080e7          	jalr	-1382(ra) # 80000ae6 <kalloc>
    80001054:	84aa                	mv	s1,a0
    80001056:	c529                	beqz	a0,800010a0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001058:	6605                	lui	a2,0x1
    8000105a:	4581                	li	a1,0
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	cd2080e7          	jalr	-814(ra) # 80000d2e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001064:	00c4d793          	srli	a5,s1,0xc
    80001068:	07aa                	slli	a5,a5,0xa
    8000106a:	0017e793          	ori	a5,a5,1
    8000106e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001072:	3a5d                	addiw	s4,s4,-9
    80001074:	036a0063          	beq	s4,s6,80001094 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001078:	0149d933          	srl	s2,s3,s4
    8000107c:	1ff97913          	andi	s2,s2,511
    80001080:	090e                	slli	s2,s2,0x3
    80001082:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001084:	00093483          	ld	s1,0(s2)
    80001088:	0014f793          	andi	a5,s1,1
    8000108c:	dfd5                	beqz	a5,80001048 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000108e:	80a9                	srli	s1,s1,0xa
    80001090:	04b2                	slli	s1,s1,0xc
    80001092:	b7c5                	j	80001072 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001094:	00c9d513          	srli	a0,s3,0xc
    80001098:	1ff57513          	andi	a0,a0,511
    8000109c:	050e                	slli	a0,a0,0x3
    8000109e:	9526                	add	a0,a0,s1
}
    800010a0:	70e2                	ld	ra,56(sp)
    800010a2:	7442                	ld	s0,48(sp)
    800010a4:	74a2                	ld	s1,40(sp)
    800010a6:	7902                	ld	s2,32(sp)
    800010a8:	69e2                	ld	s3,24(sp)
    800010aa:	6a42                	ld	s4,16(sp)
    800010ac:	6aa2                	ld	s5,8(sp)
    800010ae:	6b02                	ld	s6,0(sp)
    800010b0:	6121                	addi	sp,sp,64
    800010b2:	8082                	ret
        return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7ed                	j	800010a0 <walk+0x8e>

00000000800010b8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b8:	57fd                	li	a5,-1
    800010ba:	83e9                	srli	a5,a5,0x1a
    800010bc:	00b7f463          	bgeu	a5,a1,800010c4 <walkaddr+0xc>
    return 0;
    800010c0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c2:	8082                	ret
{
    800010c4:	1141                	addi	sp,sp,-16
    800010c6:	e406                	sd	ra,8(sp)
    800010c8:	e022                	sd	s0,0(sp)
    800010ca:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010cc:	4601                	li	a2,0
    800010ce:	00000097          	auipc	ra,0x0
    800010d2:	f44080e7          	jalr	-188(ra) # 80001012 <walk>
  if(pte == 0)
    800010d6:	c105                	beqz	a0,800010f6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010da:	0117f693          	andi	a3,a5,17
    800010de:	4745                	li	a4,17
    return 0;
    800010e0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e2:	00e68663          	beq	a3,a4,800010ee <walkaddr+0x36>
}
    800010e6:	60a2                	ld	ra,8(sp)
    800010e8:	6402                	ld	s0,0(sp)
    800010ea:	0141                	addi	sp,sp,16
    800010ec:	8082                	ret
  pa = PTE2PA(*pte);
    800010ee:	00a7d513          	srli	a0,a5,0xa
    800010f2:	0532                	slli	a0,a0,0xc
  return pa;
    800010f4:	bfcd                	j	800010e6 <walkaddr+0x2e>
    return 0;
    800010f6:	4501                	li	a0,0
    800010f8:	b7fd                	j	800010e6 <walkaddr+0x2e>

00000000800010fa <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010fa:	715d                	addi	sp,sp,-80
    800010fc:	e486                	sd	ra,72(sp)
    800010fe:	e0a2                	sd	s0,64(sp)
    80001100:	fc26                	sd	s1,56(sp)
    80001102:	f84a                	sd	s2,48(sp)
    80001104:	f44e                	sd	s3,40(sp)
    80001106:	f052                	sd	s4,32(sp)
    80001108:	ec56                	sd	s5,24(sp)
    8000110a:	e85a                	sd	s6,16(sp)
    8000110c:	e45e                	sd	s7,8(sp)
    8000110e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001110:	c639                	beqz	a2,8000115e <mappages+0x64>
    80001112:	8aaa                	mv	s5,a0
    80001114:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001116:	77fd                	lui	a5,0xfffff
    80001118:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000111c:	15fd                	addi	a1,a1,-1
    8000111e:	00c589b3          	add	s3,a1,a2
    80001122:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001126:	8952                	mv	s2,s4
    80001128:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112c:	6b85                	lui	s7,0x1
    8000112e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001132:	4605                	li	a2,1
    80001134:	85ca                	mv	a1,s2
    80001136:	8556                	mv	a0,s5
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	eda080e7          	jalr	-294(ra) # 80001012 <walk>
    80001140:	cd1d                	beqz	a0,8000117e <mappages+0x84>
    if(*pte & PTE_V)
    80001142:	611c                	ld	a5,0(a0)
    80001144:	8b85                	andi	a5,a5,1
    80001146:	e785                	bnez	a5,8000116e <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001148:	80b1                	srli	s1,s1,0xc
    8000114a:	04aa                	slli	s1,s1,0xa
    8000114c:	0164e4b3          	or	s1,s1,s6
    80001150:	0014e493          	ori	s1,s1,1
    80001154:	e104                	sd	s1,0(a0)
    if(a == last)
    80001156:	05390063          	beq	s2,s3,80001196 <mappages+0x9c>
    a += PGSIZE;
    8000115a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115c:	bfc9                	j	8000112e <mappages+0x34>
    panic("mappages: size");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f7a50513          	addi	a0,a0,-134 # 800080d8 <digits+0x98>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000116e:	00007517          	auipc	a0,0x7
    80001172:	f7a50513          	addi	a0,a0,-134 # 800080e8 <digits+0xa8>
    80001176:	fffff097          	auipc	ra,0xfffff
    8000117a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>
      return -1;
    8000117e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001180:	60a6                	ld	ra,72(sp)
    80001182:	6406                	ld	s0,64(sp)
    80001184:	74e2                	ld	s1,56(sp)
    80001186:	7942                	ld	s2,48(sp)
    80001188:	79a2                	ld	s3,40(sp)
    8000118a:	7a02                	ld	s4,32(sp)
    8000118c:	6ae2                	ld	s5,24(sp)
    8000118e:	6b42                	ld	s6,16(sp)
    80001190:	6ba2                	ld	s7,8(sp)
    80001192:	6161                	addi	sp,sp,80
    80001194:	8082                	ret
  return 0;
    80001196:	4501                	li	a0,0
    80001198:	b7e5                	j	80001180 <mappages+0x86>

000000008000119a <kvmmap>:
{
    8000119a:	1141                	addi	sp,sp,-16
    8000119c:	e406                	sd	ra,8(sp)
    8000119e:	e022                	sd	s0,0(sp)
    800011a0:	0800                	addi	s0,sp,16
    800011a2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011a4:	86b2                	mv	a3,a2
    800011a6:	863e                	mv	a2,a5
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	f52080e7          	jalr	-174(ra) # 800010fa <mappages>
    800011b0:	e509                	bnez	a0,800011ba <kvmmap+0x20>
}
    800011b2:	60a2                	ld	ra,8(sp)
    800011b4:	6402                	ld	s0,0(sp)
    800011b6:	0141                	addi	sp,sp,16
    800011b8:	8082                	ret
    panic("kvmmap");
    800011ba:	00007517          	auipc	a0,0x7
    800011be:	f3e50513          	addi	a0,a0,-194 # 800080f8 <digits+0xb8>
    800011c2:	fffff097          	auipc	ra,0xfffff
    800011c6:	37c080e7          	jalr	892(ra) # 8000053e <panic>

00000000800011ca <kvmmake>:
{
    800011ca:	1101                	addi	sp,sp,-32
    800011cc:	ec06                	sd	ra,24(sp)
    800011ce:	e822                	sd	s0,16(sp)
    800011d0:	e426                	sd	s1,8(sp)
    800011d2:	e04a                	sd	s2,0(sp)
    800011d4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	910080e7          	jalr	-1776(ra) # 80000ae6 <kalloc>
    800011de:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011e0:	6605                	lui	a2,0x1
    800011e2:	4581                	li	a1,0
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	b4a080e7          	jalr	-1206(ra) # 80000d2e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	6685                	lui	a3,0x1
    800011f0:	10000637          	lui	a2,0x10000
    800011f4:	100005b7          	lui	a1,0x10000
    800011f8:	8526                	mv	a0,s1
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	fa0080e7          	jalr	-96(ra) # 8000119a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001202:	4719                	li	a4,6
    80001204:	6685                	lui	a3,0x1
    80001206:	10001637          	lui	a2,0x10001
    8000120a:	100015b7          	lui	a1,0x10001
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f8a080e7          	jalr	-118(ra) # 8000119a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001218:	4719                	li	a4,6
    8000121a:	004006b7          	lui	a3,0x400
    8000121e:	0c000637          	lui	a2,0xc000
    80001222:	0c0005b7          	lui	a1,0xc000
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f72080e7          	jalr	-142(ra) # 8000119a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001230:	00007917          	auipc	s2,0x7
    80001234:	dd090913          	addi	s2,s2,-560 # 80008000 <etext>
    80001238:	4729                	li	a4,10
    8000123a:	80007697          	auipc	a3,0x80007
    8000123e:	dc668693          	addi	a3,a3,-570 # 8000 <_entry-0x7fff8000>
    80001242:	4605                	li	a2,1
    80001244:	067e                	slli	a2,a2,0x1f
    80001246:	85b2                	mv	a1,a2
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f50080e7          	jalr	-176(ra) # 8000119a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001252:	4719                	li	a4,6
    80001254:	46c5                	li	a3,17
    80001256:	06ee                	slli	a3,a3,0x1b
    80001258:	412686b3          	sub	a3,a3,s2
    8000125c:	864a                	mv	a2,s2
    8000125e:	85ca                	mv	a1,s2
    80001260:	8526                	mv	a0,s1
    80001262:	00000097          	auipc	ra,0x0
    80001266:	f38080e7          	jalr	-200(ra) # 8000119a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000126a:	4729                	li	a4,10
    8000126c:	6685                	lui	a3,0x1
    8000126e:	00006617          	auipc	a2,0x6
    80001272:	d9260613          	addi	a2,a2,-622 # 80007000 <_trampoline>
    80001276:	040005b7          	lui	a1,0x4000
    8000127a:	15fd                	addi	a1,a1,-1
    8000127c:	05b2                	slli	a1,a1,0xc
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f1a080e7          	jalr	-230(ra) # 8000119a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001288:	8526                	mv	a0,s1
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	608080e7          	jalr	1544(ra) # 80001892 <proc_mapstacks>
}
    80001292:	8526                	mv	a0,s1
    80001294:	60e2                	ld	ra,24(sp)
    80001296:	6442                	ld	s0,16(sp)
    80001298:	64a2                	ld	s1,8(sp)
    8000129a:	6902                	ld	s2,0(sp)
    8000129c:	6105                	addi	sp,sp,32
    8000129e:	8082                	ret

00000000800012a0 <kvminit>:
{
    800012a0:	1141                	addi	sp,sp,-16
    800012a2:	e406                	sd	ra,8(sp)
    800012a4:	e022                	sd	s0,0(sp)
    800012a6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f22080e7          	jalr	-222(ra) # 800011ca <kvmmake>
    800012b0:	00007797          	auipc	a5,0x7
    800012b4:	64a7b823          	sd	a0,1616(a5) # 80008900 <kernel_pagetable>
}
    800012b8:	60a2                	ld	ra,8(sp)
    800012ba:	6402                	ld	s0,0(sp)
    800012bc:	0141                	addi	sp,sp,16
    800012be:	8082                	ret

00000000800012c0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c0:	715d                	addi	sp,sp,-80
    800012c2:	e486                	sd	ra,72(sp)
    800012c4:	e0a2                	sd	s0,64(sp)
    800012c6:	fc26                	sd	s1,56(sp)
    800012c8:	f84a                	sd	s2,48(sp)
    800012ca:	f44e                	sd	s3,40(sp)
    800012cc:	f052                	sd	s4,32(sp)
    800012ce:	ec56                	sd	s5,24(sp)
    800012d0:	e85a                	sd	s6,16(sp)
    800012d2:	e45e                	sd	s7,8(sp)
    800012d4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012d6:	03459793          	slli	a5,a1,0x34
    800012da:	e795                	bnez	a5,80001306 <uvmunmap+0x46>
    800012dc:	8a2a                	mv	s4,a0
    800012de:	892e                	mv	s2,a1
    800012e0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	0632                	slli	a2,a2,0xc
    800012e4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ea:	6b05                	lui	s6,0x1
    800012ec:	0735e263          	bltu	a1,s3,80001350 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012f0:	60a6                	ld	ra,72(sp)
    800012f2:	6406                	ld	s0,64(sp)
    800012f4:	74e2                	ld	s1,56(sp)
    800012f6:	7942                	ld	s2,48(sp)
    800012f8:	79a2                	ld	s3,40(sp)
    800012fa:	7a02                	ld	s4,32(sp)
    800012fc:	6ae2                	ld	s5,24(sp)
    800012fe:	6b42                	ld	s6,16(sp)
    80001300:	6ba2                	ld	s7,8(sp)
    80001302:	6161                	addi	sp,sp,80
    80001304:	8082                	ret
    panic("uvmunmap: not aligned");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	dfa50513          	addi	a0,a0,-518 # 80008100 <digits+0xc0>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	230080e7          	jalr	560(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e0250513          	addi	a0,a0,-510 # 80008118 <digits+0xd8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	220080e7          	jalr	544(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	e0250513          	addi	a0,a0,-510 # 80008128 <digits+0xe8>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	210080e7          	jalr	528(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001336:	00007517          	auipc	a0,0x7
    8000133a:	e0a50513          	addi	a0,a0,-502 # 80008140 <digits+0x100>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    *pte = 0;
    80001346:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	995a                	add	s2,s2,s6
    8000134c:	fb3972e3          	bgeu	s2,s3,800012f0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001350:	4601                	li	a2,0
    80001352:	85ca                	mv	a1,s2
    80001354:	8552                	mv	a0,s4
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	cbc080e7          	jalr	-836(ra) # 80001012 <walk>
    8000135e:	84aa                	mv	s1,a0
    80001360:	d95d                	beqz	a0,80001316 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001362:	6108                	ld	a0,0(a0)
    80001364:	00157793          	andi	a5,a0,1
    80001368:	dfdd                	beqz	a5,80001326 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136a:	3ff57793          	andi	a5,a0,1023
    8000136e:	fd7784e3          	beq	a5,s7,80001336 <uvmunmap+0x76>
    if(do_free){
    80001372:	fc0a8ae3          	beqz	s5,80001346 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001376:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001378:	0532                	slli	a0,a0,0xc
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	670080e7          	jalr	1648(ra) # 800009ea <kfree>
    80001382:	b7d1                	j	80001346 <uvmunmap+0x86>

0000000080001384 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001384:	1101                	addi	sp,sp,-32
    80001386:	ec06                	sd	ra,24(sp)
    80001388:	e822                	sd	s0,16(sp)
    8000138a:	e426                	sd	s1,8(sp)
    8000138c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	758080e7          	jalr	1880(ra) # 80000ae6 <kalloc>
    80001396:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001398:	c519                	beqz	a0,800013a6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000139a:	6605                	lui	a2,0x1
    8000139c:	4581                	li	a1,0
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	990080e7          	jalr	-1648(ra) # 80000d2e <memset>
  return pagetable;
}
    800013a6:	8526                	mv	a0,s1
    800013a8:	60e2                	ld	ra,24(sp)
    800013aa:	6442                	ld	s0,16(sp)
    800013ac:	64a2                	ld	s1,8(sp)
    800013ae:	6105                	addi	sp,sp,32
    800013b0:	8082                	ret

00000000800013b2 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b2:	7179                	addi	sp,sp,-48
    800013b4:	f406                	sd	ra,40(sp)
    800013b6:	f022                	sd	s0,32(sp)
    800013b8:	ec26                	sd	s1,24(sp)
    800013ba:	e84a                	sd	s2,16(sp)
    800013bc:	e44e                	sd	s3,8(sp)
    800013be:	e052                	sd	s4,0(sp)
    800013c0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c2:	6785                	lui	a5,0x1
    800013c4:	04f67863          	bgeu	a2,a5,80001414 <uvmfirst+0x62>
    800013c8:	8a2a                	mv	s4,a0
    800013ca:	89ae                	mv	s3,a1
    800013cc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	718080e7          	jalr	1816(ra) # 80000ae6 <kalloc>
    800013d6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	952080e7          	jalr	-1710(ra) # 80000d2e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e4:	4779                	li	a4,30
    800013e6:	86ca                	mv	a3,s2
    800013e8:	6605                	lui	a2,0x1
    800013ea:	4581                	li	a1,0
    800013ec:	8552                	mv	a0,s4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	d0c080e7          	jalr	-756(ra) # 800010fa <mappages>
  memmove(mem, src, sz);
    800013f6:	8626                	mv	a2,s1
    800013f8:	85ce                	mv	a1,s3
    800013fa:	854a                	mv	a0,s2
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	98e080e7          	jalr	-1650(ra) # 80000d8a <memmove>
}
    80001404:	70a2                	ld	ra,40(sp)
    80001406:	7402                	ld	s0,32(sp)
    80001408:	64e2                	ld	s1,24(sp)
    8000140a:	6942                	ld	s2,16(sp)
    8000140c:	69a2                	ld	s3,8(sp)
    8000140e:	6a02                	ld	s4,0(sp)
    80001410:	6145                	addi	sp,sp,48
    80001412:	8082                	ret
    panic("uvmfirst: more than a page");
    80001414:	00007517          	auipc	a0,0x7
    80001418:	d4450513          	addi	a0,a0,-700 # 80008158 <digits+0x118>
    8000141c:	fffff097          	auipc	ra,0xfffff
    80001420:	122080e7          	jalr	290(ra) # 8000053e <panic>

0000000080001424 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001424:	1101                	addi	sp,sp,-32
    80001426:	ec06                	sd	ra,24(sp)
    80001428:	e822                	sd	s0,16(sp)
    8000142a:	e426                	sd	s1,8(sp)
    8000142c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000142e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001430:	00b67d63          	bgeu	a2,a1,8000144a <uvmdealloc+0x26>
    80001434:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001436:	6785                	lui	a5,0x1
    80001438:	17fd                	addi	a5,a5,-1
    8000143a:	00f60733          	add	a4,a2,a5
    8000143e:	767d                	lui	a2,0xfffff
    80001440:	8f71                	and	a4,a4,a2
    80001442:	97ae                	add	a5,a5,a1
    80001444:	8ff1                	and	a5,a5,a2
    80001446:	00f76863          	bltu	a4,a5,80001456 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000144a:	8526                	mv	a0,s1
    8000144c:	60e2                	ld	ra,24(sp)
    8000144e:	6442                	ld	s0,16(sp)
    80001450:	64a2                	ld	s1,8(sp)
    80001452:	6105                	addi	sp,sp,32
    80001454:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001456:	8f99                	sub	a5,a5,a4
    80001458:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000145a:	4685                	li	a3,1
    8000145c:	0007861b          	sext.w	a2,a5
    80001460:	85ba                	mv	a1,a4
    80001462:	00000097          	auipc	ra,0x0
    80001466:	e5e080e7          	jalr	-418(ra) # 800012c0 <uvmunmap>
    8000146a:	b7c5                	j	8000144a <uvmdealloc+0x26>

000000008000146c <uvmalloc>:
  if(newsz < oldsz)
    8000146c:	0ab66563          	bltu	a2,a1,80001516 <uvmalloc+0xaa>
{
    80001470:	7139                	addi	sp,sp,-64
    80001472:	fc06                	sd	ra,56(sp)
    80001474:	f822                	sd	s0,48(sp)
    80001476:	f426                	sd	s1,40(sp)
    80001478:	f04a                	sd	s2,32(sp)
    8000147a:	ec4e                	sd	s3,24(sp)
    8000147c:	e852                	sd	s4,16(sp)
    8000147e:	e456                	sd	s5,8(sp)
    80001480:	e05a                	sd	s6,0(sp)
    80001482:	0080                	addi	s0,sp,64
    80001484:	8aaa                	mv	s5,a0
    80001486:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001488:	6985                	lui	s3,0x1
    8000148a:	19fd                	addi	s3,s3,-1
    8000148c:	95ce                	add	a1,a1,s3
    8000148e:	79fd                	lui	s3,0xfffff
    80001490:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001494:	08c9f363          	bgeu	s3,a2,8000151a <uvmalloc+0xae>
    80001498:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000149a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	648080e7          	jalr	1608(ra) # 80000ae6 <kalloc>
    800014a6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014a8:	c51d                	beqz	a0,800014d6 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014aa:	6605                	lui	a2,0x1
    800014ac:	4581                	li	a1,0
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	880080e7          	jalr	-1920(ra) # 80000d2e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	875a                	mv	a4,s6
    800014b8:	86a6                	mv	a3,s1
    800014ba:	6605                	lui	a2,0x1
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	c3a080e7          	jalr	-966(ra) # 800010fa <mappages>
    800014c8:	e90d                	bnez	a0,800014fa <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ca:	6785                	lui	a5,0x1
    800014cc:	993e                	add	s2,s2,a5
    800014ce:	fd4968e3          	bltu	s2,s4,8000149e <uvmalloc+0x32>
  return newsz;
    800014d2:	8552                	mv	a0,s4
    800014d4:	a809                	j	800014e6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014d6:	864e                	mv	a2,s3
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	f48080e7          	jalr	-184(ra) # 80001424 <uvmdealloc>
      return 0;
    800014e4:	4501                	li	a0,0
}
    800014e6:	70e2                	ld	ra,56(sp)
    800014e8:	7442                	ld	s0,48(sp)
    800014ea:	74a2                	ld	s1,40(sp)
    800014ec:	7902                	ld	s2,32(sp)
    800014ee:	69e2                	ld	s3,24(sp)
    800014f0:	6a42                	ld	s4,16(sp)
    800014f2:	6aa2                	ld	s5,8(sp)
    800014f4:	6b02                	ld	s6,0(sp)
    800014f6:	6121                	addi	sp,sp,64
    800014f8:	8082                	ret
      kfree(mem);
    800014fa:	8526                	mv	a0,s1
    800014fc:	fffff097          	auipc	ra,0xfffff
    80001500:	4ee080e7          	jalr	1262(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001504:	864e                	mv	a2,s3
    80001506:	85ca                	mv	a1,s2
    80001508:	8556                	mv	a0,s5
    8000150a:	00000097          	auipc	ra,0x0
    8000150e:	f1a080e7          	jalr	-230(ra) # 80001424 <uvmdealloc>
      return 0;
    80001512:	4501                	li	a0,0
    80001514:	bfc9                	j	800014e6 <uvmalloc+0x7a>
    return oldsz;
    80001516:	852e                	mv	a0,a1
}
    80001518:	8082                	ret
  return newsz;
    8000151a:	8532                	mv	a0,a2
    8000151c:	b7e9                	j	800014e6 <uvmalloc+0x7a>

000000008000151e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000151e:	7179                	addi	sp,sp,-48
    80001520:	f406                	sd	ra,40(sp)
    80001522:	f022                	sd	s0,32(sp)
    80001524:	ec26                	sd	s1,24(sp)
    80001526:	e84a                	sd	s2,16(sp)
    80001528:	e44e                	sd	s3,8(sp)
    8000152a:	e052                	sd	s4,0(sp)
    8000152c:	1800                	addi	s0,sp,48
    8000152e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001530:	84aa                	mv	s1,a0
    80001532:	6905                	lui	s2,0x1
    80001534:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001536:	4985                	li	s3,1
    80001538:	a821                	j	80001550 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000153a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000153c:	0532                	slli	a0,a0,0xc
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	fe0080e7          	jalr	-32(ra) # 8000151e <freewalk>
      pagetable[i] = 0;
    80001546:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000154a:	04a1                	addi	s1,s1,8
    8000154c:	03248163          	beq	s1,s2,8000156e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001550:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	00f57793          	andi	a5,a0,15
    80001556:	ff3782e3          	beq	a5,s3,8000153a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000155a:	8905                	andi	a0,a0,1
    8000155c:	d57d                	beqz	a0,8000154a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000155e:	00007517          	auipc	a0,0x7
    80001562:	c1a50513          	addi	a0,a0,-998 # 80008178 <digits+0x138>
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	fd8080e7          	jalr	-40(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000156e:	8552                	mv	a0,s4
    80001570:	fffff097          	auipc	ra,0xfffff
    80001574:	47a080e7          	jalr	1146(ra) # 800009ea <kfree>
}
    80001578:	70a2                	ld	ra,40(sp)
    8000157a:	7402                	ld	s0,32(sp)
    8000157c:	64e2                	ld	s1,24(sp)
    8000157e:	6942                	ld	s2,16(sp)
    80001580:	69a2                	ld	s3,8(sp)
    80001582:	6a02                	ld	s4,0(sp)
    80001584:	6145                	addi	sp,sp,48
    80001586:	8082                	ret

0000000080001588 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001588:	1101                	addi	sp,sp,-32
    8000158a:	ec06                	sd	ra,24(sp)
    8000158c:	e822                	sd	s0,16(sp)
    8000158e:	e426                	sd	s1,8(sp)
    80001590:	1000                	addi	s0,sp,32
    80001592:	84aa                	mv	s1,a0
  if(sz > 0)
    80001594:	e999                	bnez	a1,800015aa <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001596:	8526                	mv	a0,s1
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	f86080e7          	jalr	-122(ra) # 8000151e <freewalk>
}
    800015a0:	60e2                	ld	ra,24(sp)
    800015a2:	6442                	ld	s0,16(sp)
    800015a4:	64a2                	ld	s1,8(sp)
    800015a6:	6105                	addi	sp,sp,32
    800015a8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015aa:	6605                	lui	a2,0x1
    800015ac:	167d                	addi	a2,a2,-1
    800015ae:	962e                	add	a2,a2,a1
    800015b0:	4685                	li	a3,1
    800015b2:	8231                	srli	a2,a2,0xc
    800015b4:	4581                	li	a1,0
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	d0a080e7          	jalr	-758(ra) # 800012c0 <uvmunmap>
    800015be:	bfe1                	j	80001596 <uvmfree+0xe>

00000000800015c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015c0:	c679                	beqz	a2,8000168e <uvmcopy+0xce>
{
    800015c2:	715d                	addi	sp,sp,-80
    800015c4:	e486                	sd	ra,72(sp)
    800015c6:	e0a2                	sd	s0,64(sp)
    800015c8:	fc26                	sd	s1,56(sp)
    800015ca:	f84a                	sd	s2,48(sp)
    800015cc:	f44e                	sd	s3,40(sp)
    800015ce:	f052                	sd	s4,32(sp)
    800015d0:	ec56                	sd	s5,24(sp)
    800015d2:	e85a                	sd	s6,16(sp)
    800015d4:	e45e                	sd	s7,8(sp)
    800015d6:	0880                	addi	s0,sp,80
    800015d8:	8b2a                	mv	s6,a0
    800015da:	8aae                	mv	s5,a1
    800015dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015e0:	4601                	li	a2,0
    800015e2:	85ce                	mv	a1,s3
    800015e4:	855a                	mv	a0,s6
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	a2c080e7          	jalr	-1492(ra) # 80001012 <walk>
    800015ee:	c531                	beqz	a0,8000163a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015f0:	6118                	ld	a4,0(a0)
    800015f2:	00177793          	andi	a5,a4,1
    800015f6:	cbb1                	beqz	a5,8000164a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015f8:	00a75593          	srli	a1,a4,0xa
    800015fc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001600:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	4e2080e7          	jalr	1250(ra) # 80000ae6 <kalloc>
    8000160c:	892a                	mv	s2,a0
    8000160e:	c939                	beqz	a0,80001664 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001610:	6605                	lui	a2,0x1
    80001612:	85de                	mv	a1,s7
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	776080e7          	jalr	1910(ra) # 80000d8a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000161c:	8726                	mv	a4,s1
    8000161e:	86ca                	mv	a3,s2
    80001620:	6605                	lui	a2,0x1
    80001622:	85ce                	mv	a1,s3
    80001624:	8556                	mv	a0,s5
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	ad4080e7          	jalr	-1324(ra) # 800010fa <mappages>
    8000162e:	e515                	bnez	a0,8000165a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001630:	6785                	lui	a5,0x1
    80001632:	99be                	add	s3,s3,a5
    80001634:	fb49e6e3          	bltu	s3,s4,800015e0 <uvmcopy+0x20>
    80001638:	a081                	j	80001678 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	b4e50513          	addi	a0,a0,-1202 # 80008188 <digits+0x148>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000164a:	00007517          	auipc	a0,0x7
    8000164e:	b5e50513          	addi	a0,a0,-1186 # 800081a8 <digits+0x168>
    80001652:	fffff097          	auipc	ra,0xfffff
    80001656:	eec080e7          	jalr	-276(ra) # 8000053e <panic>
      kfree(mem);
    8000165a:	854a                	mv	a0,s2
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	38e080e7          	jalr	910(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001664:	4685                	li	a3,1
    80001666:	00c9d613          	srli	a2,s3,0xc
    8000166a:	4581                	li	a1,0
    8000166c:	8556                	mv	a0,s5
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	c52080e7          	jalr	-942(ra) # 800012c0 <uvmunmap>
  return -1;
    80001676:	557d                	li	a0,-1
}
    80001678:	60a6                	ld	ra,72(sp)
    8000167a:	6406                	ld	s0,64(sp)
    8000167c:	74e2                	ld	s1,56(sp)
    8000167e:	7942                	ld	s2,48(sp)
    80001680:	79a2                	ld	s3,40(sp)
    80001682:	7a02                	ld	s4,32(sp)
    80001684:	6ae2                	ld	s5,24(sp)
    80001686:	6b42                	ld	s6,16(sp)
    80001688:	6ba2                	ld	s7,8(sp)
    8000168a:	6161                	addi	sp,sp,80
    8000168c:	8082                	ret
  return 0;
    8000168e:	4501                	li	a0,0
}
    80001690:	8082                	ret

0000000080001692 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001692:	1141                	addi	sp,sp,-16
    80001694:	e406                	sd	ra,8(sp)
    80001696:	e022                	sd	s0,0(sp)
    80001698:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000169a:	4601                	li	a2,0
    8000169c:	00000097          	auipc	ra,0x0
    800016a0:	976080e7          	jalr	-1674(ra) # 80001012 <walk>
  if(pte == 0)
    800016a4:	c901                	beqz	a0,800016b4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016a6:	611c                	ld	a5,0(a0)
    800016a8:	9bbd                	andi	a5,a5,-17
    800016aa:	e11c                	sd	a5,0(a0)
}
    800016ac:	60a2                	ld	ra,8(sp)
    800016ae:	6402                	ld	s0,0(sp)
    800016b0:	0141                	addi	sp,sp,16
    800016b2:	8082                	ret
    panic("uvmclear");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	b1450513          	addi	a0,a0,-1260 # 800081c8 <digits+0x188>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e82080e7          	jalr	-382(ra) # 8000053e <panic>

00000000800016c4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c4:	c6bd                	beqz	a3,80001732 <copyout+0x6e>
{
    800016c6:	715d                	addi	sp,sp,-80
    800016c8:	e486                	sd	ra,72(sp)
    800016ca:	e0a2                	sd	s0,64(sp)
    800016cc:	fc26                	sd	s1,56(sp)
    800016ce:	f84a                	sd	s2,48(sp)
    800016d0:	f44e                	sd	s3,40(sp)
    800016d2:	f052                	sd	s4,32(sp)
    800016d4:	ec56                	sd	s5,24(sp)
    800016d6:	e85a                	sd	s6,16(sp)
    800016d8:	e45e                	sd	s7,8(sp)
    800016da:	e062                	sd	s8,0(sp)
    800016dc:	0880                	addi	s0,sp,80
    800016de:	8b2a                	mv	s6,a0
    800016e0:	8c2e                	mv	s8,a1
    800016e2:	8a32                	mv	s4,a2
    800016e4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016e6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016e8:	6a85                	lui	s5,0x1
    800016ea:	a015                	j	8000170e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ec:	9562                	add	a0,a0,s8
    800016ee:	0004861b          	sext.w	a2,s1
    800016f2:	85d2                	mv	a1,s4
    800016f4:	41250533          	sub	a0,a0,s2
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	692080e7          	jalr	1682(ra) # 80000d8a <memmove>

    len -= n;
    80001700:	409989b3          	sub	s3,s3,s1
    src += n;
    80001704:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001706:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170a:	02098263          	beqz	s3,8000172e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000170e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001712:	85ca                	mv	a1,s2
    80001714:	855a                	mv	a0,s6
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	9a2080e7          	jalr	-1630(ra) # 800010b8 <walkaddr>
    if(pa0 == 0)
    8000171e:	cd01                	beqz	a0,80001736 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001720:	418904b3          	sub	s1,s2,s8
    80001724:	94d6                	add	s1,s1,s5
    if(n > len)
    80001726:	fc99f3e3          	bgeu	s3,s1,800016ec <copyout+0x28>
    8000172a:	84ce                	mv	s1,s3
    8000172c:	b7c1                	j	800016ec <copyout+0x28>
  }
  return 0;
    8000172e:	4501                	li	a0,0
    80001730:	a021                	j	80001738 <copyout+0x74>
    80001732:	4501                	li	a0,0
}
    80001734:	8082                	ret
      return -1;
    80001736:	557d                	li	a0,-1
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret

0000000080001750 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001750:	caa5                	beqz	a3,800017c0 <copyin+0x70>
{
    80001752:	715d                	addi	sp,sp,-80
    80001754:	e486                	sd	ra,72(sp)
    80001756:	e0a2                	sd	s0,64(sp)
    80001758:	fc26                	sd	s1,56(sp)
    8000175a:	f84a                	sd	s2,48(sp)
    8000175c:	f44e                	sd	s3,40(sp)
    8000175e:	f052                	sd	s4,32(sp)
    80001760:	ec56                	sd	s5,24(sp)
    80001762:	e85a                	sd	s6,16(sp)
    80001764:	e45e                	sd	s7,8(sp)
    80001766:	e062                	sd	s8,0(sp)
    80001768:	0880                	addi	s0,sp,80
    8000176a:	8b2a                	mv	s6,a0
    8000176c:	8a2e                	mv	s4,a1
    8000176e:	8c32                	mv	s8,a2
    80001770:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001772:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001774:	6a85                	lui	s5,0x1
    80001776:	a01d                	j	8000179c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001778:	018505b3          	add	a1,a0,s8
    8000177c:	0004861b          	sext.w	a2,s1
    80001780:	412585b3          	sub	a1,a1,s2
    80001784:	8552                	mv	a0,s4
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	604080e7          	jalr	1540(ra) # 80000d8a <memmove>

    len -= n;
    8000178e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001792:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001794:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001798:	02098263          	beqz	s3,800017bc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000179c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a0:	85ca                	mv	a1,s2
    800017a2:	855a                	mv	a0,s6
    800017a4:	00000097          	auipc	ra,0x0
    800017a8:	914080e7          	jalr	-1772(ra) # 800010b8 <walkaddr>
    if(pa0 == 0)
    800017ac:	cd01                	beqz	a0,800017c4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ae:	418904b3          	sub	s1,s2,s8
    800017b2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017b4:	fc99f2e3          	bgeu	s3,s1,80001778 <copyin+0x28>
    800017b8:	84ce                	mv	s1,s3
    800017ba:	bf7d                	j	80001778 <copyin+0x28>
  }
  return 0;
    800017bc:	4501                	li	a0,0
    800017be:	a021                	j	800017c6 <copyin+0x76>
    800017c0:	4501                	li	a0,0
}
    800017c2:	8082                	ret
      return -1;
    800017c4:	557d                	li	a0,-1
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6c02                	ld	s8,0(sp)
    800017da:	6161                	addi	sp,sp,80
    800017dc:	8082                	ret

00000000800017de <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017de:	c6c5                	beqz	a3,80001886 <copyinstr+0xa8>
{
    800017e0:	715d                	addi	sp,sp,-80
    800017e2:	e486                	sd	ra,72(sp)
    800017e4:	e0a2                	sd	s0,64(sp)
    800017e6:	fc26                	sd	s1,56(sp)
    800017e8:	f84a                	sd	s2,48(sp)
    800017ea:	f44e                	sd	s3,40(sp)
    800017ec:	f052                	sd	s4,32(sp)
    800017ee:	ec56                	sd	s5,24(sp)
    800017f0:	e85a                	sd	s6,16(sp)
    800017f2:	e45e                	sd	s7,8(sp)
    800017f4:	0880                	addi	s0,sp,80
    800017f6:	8a2a                	mv	s4,a0
    800017f8:	8b2e                	mv	s6,a1
    800017fa:	8bb2                	mv	s7,a2
    800017fc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017fe:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001800:	6985                	lui	s3,0x1
    80001802:	a035                	j	8000182e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001804:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001808:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000180a:	0017b793          	seqz	a5,a5
    8000180e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001812:	60a6                	ld	ra,72(sp)
    80001814:	6406                	ld	s0,64(sp)
    80001816:	74e2                	ld	s1,56(sp)
    80001818:	7942                	ld	s2,48(sp)
    8000181a:	79a2                	ld	s3,40(sp)
    8000181c:	7a02                	ld	s4,32(sp)
    8000181e:	6ae2                	ld	s5,24(sp)
    80001820:	6b42                	ld	s6,16(sp)
    80001822:	6ba2                	ld	s7,8(sp)
    80001824:	6161                	addi	sp,sp,80
    80001826:	8082                	ret
    srcva = va0 + PGSIZE;
    80001828:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000182c:	c8a9                	beqz	s1,8000187e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000182e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001832:	85ca                	mv	a1,s2
    80001834:	8552                	mv	a0,s4
    80001836:	00000097          	auipc	ra,0x0
    8000183a:	882080e7          	jalr	-1918(ra) # 800010b8 <walkaddr>
    if(pa0 == 0)
    8000183e:	c131                	beqz	a0,80001882 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001840:	41790833          	sub	a6,s2,s7
    80001844:	984e                	add	a6,a6,s3
    if(n > max)
    80001846:	0104f363          	bgeu	s1,a6,8000184c <copyinstr+0x6e>
    8000184a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000184c:	955e                	add	a0,a0,s7
    8000184e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001852:	fc080be3          	beqz	a6,80001828 <copyinstr+0x4a>
    80001856:	985a                	add	a6,a6,s6
    80001858:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000185a:	41650633          	sub	a2,a0,s6
    8000185e:	14fd                	addi	s1,s1,-1
    80001860:	9b26                	add	s6,s6,s1
    80001862:	00f60733          	add	a4,a2,a5
    80001866:	00074703          	lbu	a4,0(a4)
    8000186a:	df49                	beqz	a4,80001804 <copyinstr+0x26>
        *dst = *p;
    8000186c:	00e78023          	sb	a4,0(a5)
      --max;
    80001870:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001874:	0785                	addi	a5,a5,1
    while(n > 0){
    80001876:	ff0796e3          	bne	a5,a6,80001862 <copyinstr+0x84>
      dst++;
    8000187a:	8b42                	mv	s6,a6
    8000187c:	b775                	j	80001828 <copyinstr+0x4a>
    8000187e:	4781                	li	a5,0
    80001880:	b769                	j	8000180a <copyinstr+0x2c>
      return -1;
    80001882:	557d                	li	a0,-1
    80001884:	b779                	j	80001812 <copyinstr+0x34>
  int got_null = 0;
    80001886:	4781                	li	a5,0
  if(got_null){
    80001888:	0017b793          	seqz	a5,a5
    8000188c:	40f00533          	neg	a0,a5
}
    80001890:	8082                	ret

0000000080001892 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001892:	7139                	addi	sp,sp,-64
    80001894:	fc06                	sd	ra,56(sp)
    80001896:	f822                	sd	s0,48(sp)
    80001898:	f426                	sd	s1,40(sp)
    8000189a:	f04a                	sd	s2,32(sp)
    8000189c:	ec4e                	sd	s3,24(sp)
    8000189e:	e852                	sd	s4,16(sp)
    800018a0:	e456                	sd	s5,8(sp)
    800018a2:	e05a                	sd	s6,0(sp)
    800018a4:	0080                	addi	s0,sp,64
    800018a6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	0000f497          	auipc	s1,0xf
    800018ac:	70848493          	addi	s1,s1,1800 # 80010fb0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	8b26                	mv	s6,s1
    800018b2:	00006a97          	auipc	s5,0x6
    800018b6:	74ea8a93          	addi	s5,s5,1870 # 80008000 <etext>
    800018ba:	04000937          	lui	s2,0x4000
    800018be:	197d                	addi	s2,s2,-1
    800018c0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c2:	00015a17          	auipc	s4,0x15
    800018c6:	2eea0a13          	addi	s4,s4,750 # 80016bb0 <tickslock>
    char *pa = kalloc();
    800018ca:	fffff097          	auipc	ra,0xfffff
    800018ce:	21c080e7          	jalr	540(ra) # 80000ae6 <kalloc>
    800018d2:	862a                	mv	a2,a0
    if(pa == 0)
    800018d4:	c131                	beqz	a0,80001918 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018d6:	416485b3          	sub	a1,s1,s6
    800018da:	8591                	srai	a1,a1,0x4
    800018dc:	000ab783          	ld	a5,0(s5)
    800018e0:	02f585b3          	mul	a1,a1,a5
    800018e4:	2585                	addiw	a1,a1,1
    800018e6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ea:	4719                	li	a4,6
    800018ec:	6685                	lui	a3,0x1
    800018ee:	40b905b3          	sub	a1,s2,a1
    800018f2:	854e                	mv	a0,s3
    800018f4:	00000097          	auipc	ra,0x0
    800018f8:	8a6080e7          	jalr	-1882(ra) # 8000119a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	17048493          	addi	s1,s1,368
    80001900:	fd4495e3          	bne	s1,s4,800018ca <proc_mapstacks+0x38>
  }
}
    80001904:	70e2                	ld	ra,56(sp)
    80001906:	7442                	ld	s0,48(sp)
    80001908:	74a2                	ld	s1,40(sp)
    8000190a:	7902                	ld	s2,32(sp)
    8000190c:	69e2                	ld	s3,24(sp)
    8000190e:	6a42                	ld	s4,16(sp)
    80001910:	6aa2                	ld	s5,8(sp)
    80001912:	6b02                	ld	s6,0(sp)
    80001914:	6121                	addi	sp,sp,64
    80001916:	8082                	ret
      panic("kalloc");
    80001918:	00007517          	auipc	a0,0x7
    8000191c:	8c050513          	addi	a0,a0,-1856 # 800081d8 <digits+0x198>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	c1e080e7          	jalr	-994(ra) # 8000053e <panic>

0000000080001928 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001928:	7139                	addi	sp,sp,-64
    8000192a:	fc06                	sd	ra,56(sp)
    8000192c:	f822                	sd	s0,48(sp)
    8000192e:	f426                	sd	s1,40(sp)
    80001930:	f04a                	sd	s2,32(sp)
    80001932:	ec4e                	sd	s3,24(sp)
    80001934:	e852                	sd	s4,16(sp)
    80001936:	e456                	sd	s5,8(sp)
    80001938:	e05a                	sd	s6,0(sp)
    8000193a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000193c:	00007597          	auipc	a1,0x7
    80001940:	8a458593          	addi	a1,a1,-1884 # 800081e0 <digits+0x1a0>
    80001944:	0000f517          	auipc	a0,0xf
    80001948:	23c50513          	addi	a0,a0,572 # 80010b80 <pid_lock>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	256080e7          	jalr	598(ra) # 80000ba2 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001954:	00007597          	auipc	a1,0x7
    80001958:	89458593          	addi	a1,a1,-1900 # 800081e8 <digits+0x1a8>
    8000195c:	0000f517          	auipc	a0,0xf
    80001960:	23c50513          	addi	a0,a0,572 # 80010b98 <wait_lock>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	23e080e7          	jalr	574(ra) # 80000ba2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	0000f497          	auipc	s1,0xf
    80001970:	64448493          	addi	s1,s1,1604 # 80010fb0 <proc>
      initlock(&p->lock, "proc");
    80001974:	00007b17          	auipc	s6,0x7
    80001978:	884b0b13          	addi	s6,s6,-1916 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000197c:	8aa6                	mv	s5,s1
    8000197e:	00006a17          	auipc	s4,0x6
    80001982:	682a0a13          	addi	s4,s4,1666 # 80008000 <etext>
    80001986:	04000937          	lui	s2,0x4000
    8000198a:	197d                	addi	s2,s2,-1
    8000198c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	00015997          	auipc	s3,0x15
    80001992:	22298993          	addi	s3,s3,546 # 80016bb0 <tickslock>
      initlock(&p->lock, "proc");
    80001996:	85da                	mv	a1,s6
    80001998:	8526                	mv	a0,s1
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	208080e7          	jalr	520(ra) # 80000ba2 <initlock>
      p->state = UNUSED;
    800019a2:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019a6:	415487b3          	sub	a5,s1,s5
    800019aa:	8791                	srai	a5,a5,0x4
    800019ac:	000a3703          	ld	a4,0(s4)
    800019b0:	02e787b3          	mul	a5,a5,a4
    800019b4:	2785                	addiw	a5,a5,1
    800019b6:	00d7979b          	slliw	a5,a5,0xd
    800019ba:	40f907b3          	sub	a5,s2,a5
    800019be:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c0:	17048493          	addi	s1,s1,368
    800019c4:	fd3499e3          	bne	s1,s3,80001996 <procinit+0x6e>
  }
}
    800019c8:	70e2                	ld	ra,56(sp)
    800019ca:	7442                	ld	s0,48(sp)
    800019cc:	74a2                	ld	s1,40(sp)
    800019ce:	7902                	ld	s2,32(sp)
    800019d0:	69e2                	ld	s3,24(sp)
    800019d2:	6a42                	ld	s4,16(sp)
    800019d4:	6aa2                	ld	s5,8(sp)
    800019d6:	6b02                	ld	s6,0(sp)
    800019d8:	6121                	addi	sp,sp,64
    800019da:	8082                	ret

00000000800019dc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019dc:	1141                	addi	sp,sp,-16
    800019de:	e422                	sd	s0,8(sp)
    800019e0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019e4:	2501                	sext.w	a0,a0
    800019e6:	6422                	ld	s0,8(sp)
    800019e8:	0141                	addi	sp,sp,16
    800019ea:	8082                	ret

00000000800019ec <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e422                	sd	s0,8(sp)
    800019f0:	0800                	addi	s0,sp,16
    800019f2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019f4:	2781                	sext.w	a5,a5
    800019f6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019f8:	0000f517          	auipc	a0,0xf
    800019fc:	1b850513          	addi	a0,a0,440 # 80010bb0 <cpus>
    80001a00:	953e                	add	a0,a0,a5
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a08:	1101                	addi	sp,sp,-32
    80001a0a:	ec06                	sd	ra,24(sp)
    80001a0c:	e822                	sd	s0,16(sp)
    80001a0e:	e426                	sd	s1,8(sp)
    80001a10:	1000                	addi	s0,sp,32
  push_off();
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1d4080e7          	jalr	468(ra) # 80000be6 <push_off>
    80001a1a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a1c:	2781                	sext.w	a5,a5
    80001a1e:	079e                	slli	a5,a5,0x7
    80001a20:	0000f717          	auipc	a4,0xf
    80001a24:	16070713          	addi	a4,a4,352 # 80010b80 <pid_lock>
    80001a28:	97ba                	add	a5,a5,a4
    80001a2a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	25a080e7          	jalr	602(ra) # 80000c86 <pop_off>
  return p;
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6105                	addi	sp,sp,32
    80001a3e:	8082                	ret

0000000080001a40 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a40:	1141                	addi	sp,sp,-16
    80001a42:	e406                	sd	ra,8(sp)
    80001a44:	e022                	sd	s0,0(sp)
    80001a46:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	fc0080e7          	jalr	-64(ra) # 80001a08 <myproc>
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	296080e7          	jalr	662(ra) # 80000ce6 <release>

  if (first) {
    80001a58:	00007797          	auipc	a5,0x7
    80001a5c:	e387a783          	lw	a5,-456(a5) # 80008890 <first.1>
    80001a60:	eb89                	bnez	a5,80001a72 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a62:	00001097          	auipc	ra,0x1
    80001a66:	dda080e7          	jalr	-550(ra) # 8000283c <usertrapret>
}
    80001a6a:	60a2                	ld	ra,8(sp)
    80001a6c:	6402                	ld	s0,0(sp)
    80001a6e:	0141                	addi	sp,sp,16
    80001a70:	8082                	ret
    first = 0;
    80001a72:	00007797          	auipc	a5,0x7
    80001a76:	e007af23          	sw	zero,-482(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001a7a:	4505                	li	a0,1
    80001a7c:	00002097          	auipc	ra,0x2
    80001a80:	be4080e7          	jalr	-1052(ra) # 80003660 <fsinit>
    80001a84:	bff9                	j	80001a62 <forkret+0x22>

0000000080001a86 <allocpid>:
{
    80001a86:	1101                	addi	sp,sp,-32
    80001a88:	ec06                	sd	ra,24(sp)
    80001a8a:	e822                	sd	s0,16(sp)
    80001a8c:	e426                	sd	s1,8(sp)
    80001a8e:	e04a                	sd	s2,0(sp)
    80001a90:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a92:	0000f917          	auipc	s2,0xf
    80001a96:	0ee90913          	addi	s2,s2,238 # 80010b80 <pid_lock>
    80001a9a:	854a                	mv	a0,s2
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	196080e7          	jalr	406(ra) # 80000c32 <acquire>
  pid = nextpid;
    80001aa4:	00007797          	auipc	a5,0x7
    80001aa8:	df078793          	addi	a5,a5,-528 # 80008894 <nextpid>
    80001aac:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aae:	0014871b          	addiw	a4,s1,1
    80001ab2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ab4:	854a                	mv	a0,s2
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	230080e7          	jalr	560(ra) # 80000ce6 <release>
}
    80001abe:	8526                	mv	a0,s1
    80001ac0:	60e2                	ld	ra,24(sp)
    80001ac2:	6442                	ld	s0,16(sp)
    80001ac4:	64a2                	ld	s1,8(sp)
    80001ac6:	6902                	ld	s2,0(sp)
    80001ac8:	6105                	addi	sp,sp,32
    80001aca:	8082                	ret

0000000080001acc <proc_pagetable>:
{
    80001acc:	1101                	addi	sp,sp,-32
    80001ace:	ec06                	sd	ra,24(sp)
    80001ad0:	e822                	sd	s0,16(sp)
    80001ad2:	e426                	sd	s1,8(sp)
    80001ad4:	e04a                	sd	s2,0(sp)
    80001ad6:	1000                	addi	s0,sp,32
    80001ad8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	8aa080e7          	jalr	-1878(ra) # 80001384 <uvmcreate>
    80001ae2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ae4:	c121                	beqz	a0,80001b24 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae6:	4729                	li	a4,10
    80001ae8:	00005697          	auipc	a3,0x5
    80001aec:	51868693          	addi	a3,a3,1304 # 80007000 <_trampoline>
    80001af0:	6605                	lui	a2,0x1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	600080e7          	jalr	1536(ra) # 800010fa <mappages>
    80001b02:	02054863          	bltz	a0,80001b32 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b06:	4719                	li	a4,6
    80001b08:	05893683          	ld	a3,88(s2)
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	020005b7          	lui	a1,0x2000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b6                	slli	a1,a1,0xd
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	5e2080e7          	jalr	1506(ra) # 800010fa <mappages>
    80001b20:	02054163          	bltz	a0,80001b42 <proc_pagetable+0x76>
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6902                	ld	s2,0(sp)
    80001b2e:	6105                	addi	sp,sp,32
    80001b30:	8082                	ret
    uvmfree(pagetable, 0);
    80001b32:	4581                	li	a1,0
    80001b34:	8526                	mv	a0,s1
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	a52080e7          	jalr	-1454(ra) # 80001588 <uvmfree>
    return 0;
    80001b3e:	4481                	li	s1,0
    80001b40:	b7d5                	j	80001b24 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b42:	4681                	li	a3,0
    80001b44:	4605                	li	a2,1
    80001b46:	040005b7          	lui	a1,0x4000
    80001b4a:	15fd                	addi	a1,a1,-1
    80001b4c:	05b2                	slli	a1,a1,0xc
    80001b4e:	8526                	mv	a0,s1
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	770080e7          	jalr	1904(ra) # 800012c0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b58:	4581                	li	a1,0
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	00000097          	auipc	ra,0x0
    80001b60:	a2c080e7          	jalr	-1492(ra) # 80001588 <uvmfree>
    return 0;
    80001b64:	4481                	li	s1,0
    80001b66:	bf7d                	j	80001b24 <proc_pagetable+0x58>

0000000080001b68 <proc_freepagetable>:
{
    80001b68:	1101                	addi	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	e04a                	sd	s2,0(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
    80001b76:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b78:	4681                	li	a3,0
    80001b7a:	4605                	li	a2,1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	73c080e7          	jalr	1852(ra) # 800012c0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b8c:	4681                	li	a3,0
    80001b8e:	4605                	li	a2,1
    80001b90:	020005b7          	lui	a1,0x2000
    80001b94:	15fd                	addi	a1,a1,-1
    80001b96:	05b6                	slli	a1,a1,0xd
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	726080e7          	jalr	1830(ra) # 800012c0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba2:	85ca                	mv	a1,s2
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	9e2080e7          	jalr	-1566(ra) # 80001588 <uvmfree>
}
    80001bae:	60e2                	ld	ra,24(sp)
    80001bb0:	6442                	ld	s0,16(sp)
    80001bb2:	64a2                	ld	s1,8(sp)
    80001bb4:	6902                	ld	s2,0(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <freeproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	1000                	addi	s0,sp,32
    80001bc4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc6:	6d28                	ld	a0,88(a0)
    80001bc8:	c509                	beqz	a0,80001bd2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	e20080e7          	jalr	-480(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bd2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd6:	68a8                	ld	a0,80(s1)
    80001bd8:	c511                	beqz	a0,80001be4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bda:	64ac                	ld	a1,72(s1)
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	f8c080e7          	jalr	-116(ra) # 80001b68 <proc_freepagetable>
  p->pagetable = 0;
    80001be4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bec:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bf4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bfc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c00:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c04:	0004ac23          	sw	zero,24(s1)
}
    80001c08:	60e2                	ld	ra,24(sp)
    80001c0a:	6442                	ld	s0,16(sp)
    80001c0c:	64a2                	ld	s1,8(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret

0000000080001c12 <allocproc>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1e:	0000f497          	auipc	s1,0xf
    80001c22:	39248493          	addi	s1,s1,914 # 80010fb0 <proc>
    80001c26:	00015917          	auipc	s2,0x15
    80001c2a:	f8a90913          	addi	s2,s2,-118 # 80016bb0 <tickslock>
    acquire(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	002080e7          	jalr	2(ra) # 80000c32 <acquire>
    if(p->state == UNUSED) {
    80001c38:	4c9c                	lw	a5,24(s1)
    80001c3a:	cf81                	beqz	a5,80001c52 <allocproc+0x40>
      release(&p->lock);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	0a8080e7          	jalr	168(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	17048493          	addi	s1,s1,368
    80001c4a:	ff2492e3          	bne	s1,s2,80001c2e <allocproc+0x1c>
  return 0;
    80001c4e:	4481                	li	s1,0
    80001c50:	a8b9                	j	80001cae <allocproc+0x9c>
  p->pid = allocpid();
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	e34080e7          	jalr	-460(ra) # 80001a86 <allocpid>
    80001c5a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c5c:	4785                	li	a5,1
    80001c5e:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	cb07a783          	lw	a5,-848(a5) # 80008910 <ticks>
    80001c68:	16f4a423          	sw	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	e7a080e7          	jalr	-390(ra) # 80000ae6 <kalloc>
    80001c74:	892a                	mv	s2,a0
    80001c76:	eca8                	sd	a0,88(s1)
    80001c78:	c131                	beqz	a0,80001cbc <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	e50080e7          	jalr	-432(ra) # 80001acc <proc_pagetable>
    80001c84:	892a                	mv	s2,a0
    80001c86:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c88:	c531                	beqz	a0,80001cd4 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c8a:	07000613          	li	a2,112
    80001c8e:	4581                	li	a1,0
    80001c90:	06048513          	addi	a0,s1,96
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	09a080e7          	jalr	154(ra) # 80000d2e <memset>
  p->context.ra = (uint64)forkret;
    80001c9c:	00000797          	auipc	a5,0x0
    80001ca0:	da478793          	addi	a5,a5,-604 # 80001a40 <forkret>
    80001ca4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ca6:	60bc                	ld	a5,64(s1)
    80001ca8:	6705                	lui	a4,0x1
    80001caa:	97ba                	add	a5,a5,a4
    80001cac:	f4bc                	sd	a5,104(s1)
}
    80001cae:	8526                	mv	a0,s1
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6902                	ld	s2,0(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret
    freeproc(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	efc080e7          	jalr	-260(ra) # 80001bba <freeproc>
    release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	01e080e7          	jalr	30(ra) # 80000ce6 <release>
    return 0;
    80001cd0:	84ca                	mv	s1,s2
    80001cd2:	bff1                	j	80001cae <allocproc+0x9c>
    freeproc(p);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	ee4080e7          	jalr	-284(ra) # 80001bba <freeproc>
    release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	006080e7          	jalr	6(ra) # 80000ce6 <release>
    return 0;
    80001ce8:	84ca                	mv	s1,s2
    80001cea:	b7d1                	j	80001cae <allocproc+0x9c>

0000000080001cec <userinit>:
{
    80001cec:	1101                	addi	sp,sp,-32
    80001cee:	ec06                	sd	ra,24(sp)
    80001cf0:	e822                	sd	s0,16(sp)
    80001cf2:	e426                	sd	s1,8(sp)
    80001cf4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	f1c080e7          	jalr	-228(ra) # 80001c12 <allocproc>
    80001cfe:	84aa                	mv	s1,a0
  initproc = p;
    80001d00:	00007797          	auipc	a5,0x7
    80001d04:	c0a7b423          	sd	a0,-1016(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d08:	03400613          	li	a2,52
    80001d0c:	00007597          	auipc	a1,0x7
    80001d10:	b9458593          	addi	a1,a1,-1132 # 800088a0 <initcode>
    80001d14:	6928                	ld	a0,80(a0)
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	69c080e7          	jalr	1692(ra) # 800013b2 <uvmfirst>
  p->sz = PGSIZE;
    80001d1e:	6785                	lui	a5,0x1
    80001d20:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d28:	6cb8                	ld	a4,88(s1)
    80001d2a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d2c:	4641                	li	a2,16
    80001d2e:	00006597          	auipc	a1,0x6
    80001d32:	4d258593          	addi	a1,a1,1234 # 80008200 <digits+0x1c0>
    80001d36:	15848513          	addi	a0,s1,344
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	13e080e7          	jalr	318(ra) # 80000e78 <safestrcpy>
  p->cwd = namei("/");
    80001d42:	00006517          	auipc	a0,0x6
    80001d46:	4ce50513          	addi	a0,a0,1230 # 80008210 <digits+0x1d0>
    80001d4a:	00002097          	auipc	ra,0x2
    80001d4e:	338080e7          	jalr	824(ra) # 80004082 <namei>
    80001d52:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d56:	478d                	li	a5,3
    80001d58:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f8a080e7          	jalr	-118(ra) # 80000ce6 <release>
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret

0000000080001d6e <growproc>:
{
    80001d6e:	1101                	addi	sp,sp,-32
    80001d70:	ec06                	sd	ra,24(sp)
    80001d72:	e822                	sd	s0,16(sp)
    80001d74:	e426                	sd	s1,8(sp)
    80001d76:	e04a                	sd	s2,0(sp)
    80001d78:	1000                	addi	s0,sp,32
    80001d7a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	c8c080e7          	jalr	-884(ra) # 80001a08 <myproc>
    80001d84:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d86:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d88:	01204c63          	bgtz	s2,80001da0 <growproc+0x32>
  } else if(n < 0){
    80001d8c:	02094663          	bltz	s2,80001db8 <growproc+0x4a>
  p->sz = sz;
    80001d90:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d92:	4501                	li	a0,0
}
    80001d94:	60e2                	ld	ra,24(sp)
    80001d96:	6442                	ld	s0,16(sp)
    80001d98:	64a2                	ld	s1,8(sp)
    80001d9a:	6902                	ld	s2,0(sp)
    80001d9c:	6105                	addi	sp,sp,32
    80001d9e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001da0:	4691                	li	a3,4
    80001da2:	00b90633          	add	a2,s2,a1
    80001da6:	6928                	ld	a0,80(a0)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	6c4080e7          	jalr	1732(ra) # 8000146c <uvmalloc>
    80001db0:	85aa                	mv	a1,a0
    80001db2:	fd79                	bnez	a0,80001d90 <growproc+0x22>
      return -1;
    80001db4:	557d                	li	a0,-1
    80001db6:	bff9                	j	80001d94 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db8:	00b90633          	add	a2,s2,a1
    80001dbc:	6928                	ld	a0,80(a0)
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	666080e7          	jalr	1638(ra) # 80001424 <uvmdealloc>
    80001dc6:	85aa                	mv	a1,a0
    80001dc8:	b7e1                	j	80001d90 <growproc+0x22>

0000000080001dca <fork>:
{
    80001dca:	7139                	addi	sp,sp,-64
    80001dcc:	fc06                	sd	ra,56(sp)
    80001dce:	f822                	sd	s0,48(sp)
    80001dd0:	f426                	sd	s1,40(sp)
    80001dd2:	f04a                	sd	s2,32(sp)
    80001dd4:	ec4e                	sd	s3,24(sp)
    80001dd6:	e852                	sd	s4,16(sp)
    80001dd8:	e456                	sd	s5,8(sp)
    80001dda:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	c2c080e7          	jalr	-980(ra) # 80001a08 <myproc>
    80001de4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	e2c080e7          	jalr	-468(ra) # 80001c12 <allocproc>
    80001dee:	10050c63          	beqz	a0,80001f06 <fork+0x13c>
    80001df2:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df4:	048ab603          	ld	a2,72(s5)
    80001df8:	692c                	ld	a1,80(a0)
    80001dfa:	050ab503          	ld	a0,80(s5)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	7c2080e7          	jalr	1986(ra) # 800015c0 <uvmcopy>
    80001e06:	04054863          	bltz	a0,80001e56 <fork+0x8c>
  np->sz = p->sz;
    80001e0a:	048ab783          	ld	a5,72(s5)
    80001e0e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	058ab683          	ld	a3,88(s5)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	058a3703          	ld	a4,88(s4)
    80001e1c:	12068693          	addi	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	addi	a5,a5,32
    80001e38:	02070713          	addi	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e40:	058a3783          	ld	a5,88(s4)
    80001e44:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e48:	0d0a8493          	addi	s1,s5,208
    80001e4c:	0d0a0913          	addi	s2,s4,208
    80001e50:	150a8993          	addi	s3,s5,336
    80001e54:	a00d                	j	80001e76 <fork+0xac>
    freeproc(np);
    80001e56:	8552                	mv	a0,s4
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	d62080e7          	jalr	-670(ra) # 80001bba <freeproc>
    release(&np->lock);
    80001e60:	8552                	mv	a0,s4
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e84080e7          	jalr	-380(ra) # 80000ce6 <release>
    return -1;
    80001e6a:	597d                	li	s2,-1
    80001e6c:	a059                	j	80001ef2 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e6e:	04a1                	addi	s1,s1,8
    80001e70:	0921                	addi	s2,s2,8
    80001e72:	01348b63          	beq	s1,s3,80001e88 <fork+0xbe>
    if(p->ofile[i])
    80001e76:	6088                	ld	a0,0(s1)
    80001e78:	d97d                	beqz	a0,80001e6e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e7a:	00003097          	auipc	ra,0x3
    80001e7e:	89e080e7          	jalr	-1890(ra) # 80004718 <filedup>
    80001e82:	00a93023          	sd	a0,0(s2)
    80001e86:	b7e5                	j	80001e6e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e88:	150ab503          	ld	a0,336(s5)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	a12080e7          	jalr	-1518(ra) # 8000389e <idup>
    80001e94:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	158a8593          	addi	a1,s5,344
    80001e9e:	158a0513          	addi	a0,s4,344
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	fd6080e7          	jalr	-42(ra) # 80000e78 <safestrcpy>
  pid = np->pid;
    80001eaa:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eae:	8552                	mv	a0,s4
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	e36080e7          	jalr	-458(ra) # 80000ce6 <release>
  acquire(&wait_lock);
    80001eb8:	0000f497          	auipc	s1,0xf
    80001ebc:	ce048493          	addi	s1,s1,-800 # 80010b98 <wait_lock>
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d70080e7          	jalr	-656(ra) # 80000c32 <acquire>
  np->parent = p;
    80001eca:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	e16080e7          	jalr	-490(ra) # 80000ce6 <release>
  acquire(&np->lock);
    80001ed8:	8552                	mv	a0,s4
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d58080e7          	jalr	-680(ra) # 80000c32 <acquire>
  np->state = RUNNABLE;
    80001ee2:	478d                	li	a5,3
    80001ee4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ee8:	8552                	mv	a0,s4
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	dfc080e7          	jalr	-516(ra) # 80000ce6 <release>
}
    80001ef2:	854a                	mv	a0,s2
    80001ef4:	70e2                	ld	ra,56(sp)
    80001ef6:	7442                	ld	s0,48(sp)
    80001ef8:	74a2                	ld	s1,40(sp)
    80001efa:	7902                	ld	s2,32(sp)
    80001efc:	69e2                	ld	s3,24(sp)
    80001efe:	6a42                	ld	s4,16(sp)
    80001f00:	6aa2                	ld	s5,8(sp)
    80001f02:	6121                	addi	sp,sp,64
    80001f04:	8082                	ret
    return -1;
    80001f06:	597d                	li	s2,-1
    80001f08:	b7ed                	j	80001ef2 <fork+0x128>

0000000080001f0a <scheduler>:
{
    80001f0a:	7139                	addi	sp,sp,-64
    80001f0c:	fc06                	sd	ra,56(sp)
    80001f0e:	f822                	sd	s0,48(sp)
    80001f10:	f426                	sd	s1,40(sp)
    80001f12:	f04a                	sd	s2,32(sp)
    80001f14:	ec4e                	sd	s3,24(sp)
    80001f16:	e852                	sd	s4,16(sp)
    80001f18:	e456                	sd	s5,8(sp)
    80001f1a:	e05a                	sd	s6,0(sp)
    80001f1c:	0080                	addi	s0,sp,64
    80001f1e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f20:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f22:	00779a93          	slli	s5,a5,0x7
    80001f26:	0000f717          	auipc	a4,0xf
    80001f2a:	c5a70713          	addi	a4,a4,-934 # 80010b80 <pid_lock>
    80001f2e:	9756                	add	a4,a4,s5
    80001f30:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f34:	0000f717          	auipc	a4,0xf
    80001f38:	c8470713          	addi	a4,a4,-892 # 80010bb8 <cpus+0x8>
    80001f3c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f3e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f40:	4b11                	li	s6,4
        c->proc = p;
    80001f42:	079e                	slli	a5,a5,0x7
    80001f44:	0000fa17          	auipc	s4,0xf
    80001f48:	c3ca0a13          	addi	s4,s4,-964 # 80010b80 <pid_lock>
    80001f4c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4e:	00015917          	auipc	s2,0x15
    80001f52:	c6290913          	addi	s2,s2,-926 # 80016bb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5e:	10079073          	csrw	sstatus,a5
    80001f62:	0000f497          	auipc	s1,0xf
    80001f66:	04e48493          	addi	s1,s1,78 # 80010fb0 <proc>
    80001f6a:	a811                	j	80001f7e <scheduler+0x74>
      release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d78080e7          	jalr	-648(ra) # 80000ce6 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f76:	17048493          	addi	s1,s1,368
    80001f7a:	fd248ee3          	beq	s1,s2,80001f56 <scheduler+0x4c>
      acquire(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	cb2080e7          	jalr	-846(ra) # 80000c32 <acquire>
      if(p->state == RUNNABLE) {
    80001f88:	4c9c                	lw	a5,24(s1)
    80001f8a:	ff3791e3          	bne	a5,s3,80001f6c <scheduler+0x62>
        p->state = RUNNING;
    80001f8e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f92:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f96:	06048593          	addi	a1,s1,96
    80001f9a:	8556                	mv	a0,s5
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	7f6080e7          	jalr	2038(ra) # 80002792 <swtch>
        c->proc = 0;
    80001fa4:	020a3823          	sd	zero,48(s4)
    80001fa8:	b7d1                	j	80001f6c <scheduler+0x62>

0000000080001faa <sched>:
{
    80001faa:	7179                	addi	sp,sp,-48
    80001fac:	f406                	sd	ra,40(sp)
    80001fae:	f022                	sd	s0,32(sp)
    80001fb0:	ec26                	sd	s1,24(sp)
    80001fb2:	e84a                	sd	s2,16(sp)
    80001fb4:	e44e                	sd	s3,8(sp)
    80001fb6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	a50080e7          	jalr	-1456(ra) # 80001a08 <myproc>
    80001fc0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	bf6080e7          	jalr	-1034(ra) # 80000bb8 <holding>
    80001fca:	c93d                	beqz	a0,80002040 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fcc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	0000f717          	auipc	a4,0xf
    80001fd6:	bae70713          	addi	a4,a4,-1106 # 80010b80 <pid_lock>
    80001fda:	97ba                	add	a5,a5,a4
    80001fdc:	0a87a703          	lw	a4,168(a5)
    80001fe0:	4785                	li	a5,1
    80001fe2:	06f71763          	bne	a4,a5,80002050 <sched+0xa6>
  if(p->state == RUNNING)
    80001fe6:	4c98                	lw	a4,24(s1)
    80001fe8:	4791                	li	a5,4
    80001fea:	06f70b63          	beq	a4,a5,80002060 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ff4:	efb5                	bnez	a5,80002070 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff8:	0000f917          	auipc	s2,0xf
    80001ffc:	b8890913          	addi	s2,s2,-1144 # 80010b80 <pid_lock>
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	97ca                	add	a5,a5,s2
    80002006:	0ac7a983          	lw	s3,172(a5)
    8000200a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f597          	auipc	a1,0xf
    80002014:	ba858593          	addi	a1,a1,-1112 # 80010bb8 <cpus+0x8>
    80002018:	95be                	add	a1,a1,a5
    8000201a:	06048513          	addi	a0,s1,96
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	774080e7          	jalr	1908(ra) # 80002792 <swtch>
    80002026:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	97ca                	add	a5,a5,s2
    8000202e:	0b37a623          	sw	s3,172(a5)
}
    80002032:	70a2                	ld	ra,40(sp)
    80002034:	7402                	ld	s0,32(sp)
    80002036:	64e2                	ld	s1,24(sp)
    80002038:	6942                	ld	s2,16(sp)
    8000203a:	69a2                	ld	s3,8(sp)
    8000203c:	6145                	addi	sp,sp,48
    8000203e:	8082                	ret
    panic("sched p->lock");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1d850513          	addi	a0,a0,472 # 80008218 <digits+0x1d8>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>
    panic("sched locks");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1d850513          	addi	a0,a0,472 # 80008228 <digits+0x1e8>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4e6080e7          	jalr	1254(ra) # 8000053e <panic>
    panic("sched running");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1d850513          	addi	a0,a0,472 # 80008238 <digits+0x1f8>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4d6080e7          	jalr	1238(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1d850513          	addi	a0,a0,472 # 80008248 <digits+0x208>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>

0000000080002080 <yield>:
{
    80002080:	1101                	addi	sp,sp,-32
    80002082:	ec06                	sd	ra,24(sp)
    80002084:	e822                	sd	s0,16(sp)
    80002086:	e426                	sd	s1,8(sp)
    80002088:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	97e080e7          	jalr	-1666(ra) # 80001a08 <myproc>
    80002092:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b9e080e7          	jalr	-1122(ra) # 80000c32 <acquire>
  p->state = RUNNABLE;
    8000209c:	478d                	li	a5,3
    8000209e:	cc9c                	sw	a5,24(s1)
  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	f0a080e7          	jalr	-246(ra) # 80001faa <sched>
  release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	c3c080e7          	jalr	-964(ra) # 80000ce6 <release>
}
    800020b2:	60e2                	ld	ra,24(sp)
    800020b4:	6442                	ld	s0,16(sp)
    800020b6:	64a2                	ld	s1,8(sp)
    800020b8:	6105                	addi	sp,sp,32
    800020ba:	8082                	ret

00000000800020bc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020bc:	7179                	addi	sp,sp,-48
    800020be:	f406                	sd	ra,40(sp)
    800020c0:	f022                	sd	s0,32(sp)
    800020c2:	ec26                	sd	s1,24(sp)
    800020c4:	e84a                	sd	s2,16(sp)
    800020c6:	e44e                	sd	s3,8(sp)
    800020c8:	1800                	addi	s0,sp,48
    800020ca:	89aa                	mv	s3,a0
    800020cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	93a080e7          	jalr	-1734(ra) # 80001a08 <myproc>
    800020d6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	b5a080e7          	jalr	-1190(ra) # 80000c32 <acquire>
  release(lk);
    800020e0:	854a                	mv	a0,s2
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	c04080e7          	jalr	-1020(ra) # 80000ce6 <release>

  // Go to sleep.
  p->chan = chan;
    800020ea:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ee:	4789                	li	a5,2
    800020f0:	cc9c                	sw	a5,24(s1)

  sched();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	eb8080e7          	jalr	-328(ra) # 80001faa <sched>

  // Tidy up.
  p->chan = 0;
    800020fa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	be6080e7          	jalr	-1050(ra) # 80000ce6 <release>
  acquire(lk);
    80002108:	854a                	mv	a0,s2
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	b28080e7          	jalr	-1240(ra) # 80000c32 <acquire>
}
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6145                	addi	sp,sp,48
    8000211e:	8082                	ret

0000000080002120 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002120:	7139                	addi	sp,sp,-64
    80002122:	fc06                	sd	ra,56(sp)
    80002124:	f822                	sd	s0,48(sp)
    80002126:	f426                	sd	s1,40(sp)
    80002128:	f04a                	sd	s2,32(sp)
    8000212a:	ec4e                	sd	s3,24(sp)
    8000212c:	e852                	sd	s4,16(sp)
    8000212e:	e456                	sd	s5,8(sp)
    80002130:	0080                	addi	s0,sp,64
    80002132:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002134:	0000f497          	auipc	s1,0xf
    80002138:	e7c48493          	addi	s1,s1,-388 # 80010fb0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000213c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000213e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002140:	00015917          	auipc	s2,0x15
    80002144:	a7090913          	addi	s2,s2,-1424 # 80016bb0 <tickslock>
    80002148:	a811                	j	8000215c <wakeup+0x3c>
      }
      release(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b9a080e7          	jalr	-1126(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002154:	17048493          	addi	s1,s1,368
    80002158:	03248663          	beq	s1,s2,80002184 <wakeup+0x64>
    if(p != myproc()){
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	8ac080e7          	jalr	-1876(ra) # 80001a08 <myproc>
    80002164:	fea488e3          	beq	s1,a0,80002154 <wakeup+0x34>
      acquire(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	ac8080e7          	jalr	-1336(ra) # 80000c32 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002172:	4c9c                	lw	a5,24(s1)
    80002174:	fd379be3          	bne	a5,s3,8000214a <wakeup+0x2a>
    80002178:	709c                	ld	a5,32(s1)
    8000217a:	fd4798e3          	bne	a5,s4,8000214a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000217e:	0154ac23          	sw	s5,24(s1)
    80002182:	b7e1                	j	8000214a <wakeup+0x2a>
    }
  }
}
    80002184:	70e2                	ld	ra,56(sp)
    80002186:	7442                	ld	s0,48(sp)
    80002188:	74a2                	ld	s1,40(sp)
    8000218a:	7902                	ld	s2,32(sp)
    8000218c:	69e2                	ld	s3,24(sp)
    8000218e:	6a42                	ld	s4,16(sp)
    80002190:	6aa2                	ld	s5,8(sp)
    80002192:	6121                	addi	sp,sp,64
    80002194:	8082                	ret

0000000080002196 <reparent>:
{
    80002196:	7179                	addi	sp,sp,-48
    80002198:	f406                	sd	ra,40(sp)
    8000219a:	f022                	sd	s0,32(sp)
    8000219c:	ec26                	sd	s1,24(sp)
    8000219e:	e84a                	sd	s2,16(sp)
    800021a0:	e44e                	sd	s3,8(sp)
    800021a2:	e052                	sd	s4,0(sp)
    800021a4:	1800                	addi	s0,sp,48
    800021a6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021a8:	0000f497          	auipc	s1,0xf
    800021ac:	e0848493          	addi	s1,s1,-504 # 80010fb0 <proc>
      pp->parent = initproc;
    800021b0:	00006a17          	auipc	s4,0x6
    800021b4:	758a0a13          	addi	s4,s4,1880 # 80008908 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b8:	00015997          	auipc	s3,0x15
    800021bc:	9f898993          	addi	s3,s3,-1544 # 80016bb0 <tickslock>
    800021c0:	a029                	j	800021ca <reparent+0x34>
    800021c2:	17048493          	addi	s1,s1,368
    800021c6:	01348d63          	beq	s1,s3,800021e0 <reparent+0x4a>
    if(pp->parent == p){
    800021ca:	7c9c                	ld	a5,56(s1)
    800021cc:	ff279be3          	bne	a5,s2,800021c2 <reparent+0x2c>
      pp->parent = initproc;
    800021d0:	000a3503          	ld	a0,0(s4)
    800021d4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	f4a080e7          	jalr	-182(ra) # 80002120 <wakeup>
    800021de:	b7d5                	j	800021c2 <reparent+0x2c>
}
    800021e0:	70a2                	ld	ra,40(sp)
    800021e2:	7402                	ld	s0,32(sp)
    800021e4:	64e2                	ld	s1,24(sp)
    800021e6:	6942                	ld	s2,16(sp)
    800021e8:	69a2                	ld	s3,8(sp)
    800021ea:	6a02                	ld	s4,0(sp)
    800021ec:	6145                	addi	sp,sp,48
    800021ee:	8082                	ret

00000000800021f0 <exit>:
{
    800021f0:	7179                	addi	sp,sp,-48
    800021f2:	f406                	sd	ra,40(sp)
    800021f4:	f022                	sd	s0,32(sp)
    800021f6:	ec26                	sd	s1,24(sp)
    800021f8:	e84a                	sd	s2,16(sp)
    800021fa:	e44e                	sd	s3,8(sp)
    800021fc:	e052                	sd	s4,0(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	806080e7          	jalr	-2042(ra) # 80001a08 <myproc>
    8000220a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000220c:	00006797          	auipc	a5,0x6
    80002210:	6fc7b783          	ld	a5,1788(a5) # 80008908 <initproc>
    80002214:	0d050493          	addi	s1,a0,208
    80002218:	15050913          	addi	s2,a0,336
    8000221c:	02a79363          	bne	a5,a0,80002242 <exit+0x52>
    panic("init exiting");
    80002220:	00006517          	auipc	a0,0x6
    80002224:	04050513          	addi	a0,a0,64 # 80008260 <digits+0x220>
    80002228:	ffffe097          	auipc	ra,0xffffe
    8000222c:	316080e7          	jalr	790(ra) # 8000053e <panic>
      fileclose(f);
    80002230:	00002097          	auipc	ra,0x2
    80002234:	53a080e7          	jalr	1338(ra) # 8000476a <fileclose>
      p->ofile[fd] = 0;
    80002238:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000223c:	04a1                	addi	s1,s1,8
    8000223e:	01248563          	beq	s1,s2,80002248 <exit+0x58>
    if(p->ofile[fd]){
    80002242:	6088                	ld	a0,0(s1)
    80002244:	f575                	bnez	a0,80002230 <exit+0x40>
    80002246:	bfdd                	j	8000223c <exit+0x4c>
  begin_op();
    80002248:	00002097          	auipc	ra,0x2
    8000224c:	056080e7          	jalr	86(ra) # 8000429e <begin_op>
  iput(p->cwd);
    80002250:	1509b503          	ld	a0,336(s3)
    80002254:	00002097          	auipc	ra,0x2
    80002258:	842080e7          	jalr	-1982(ra) # 80003a96 <iput>
  end_op();
    8000225c:	00002097          	auipc	ra,0x2
    80002260:	0c2080e7          	jalr	194(ra) # 8000431e <end_op>
  p->cwd = 0;
    80002264:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	93048493          	addi	s1,s1,-1744 # 80010b98 <wait_lock>
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	9c0080e7          	jalr	-1600(ra) # 80000c32 <acquire>
  reparent(p);
    8000227a:	854e                	mv	a0,s3
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	f1a080e7          	jalr	-230(ra) # 80002196 <reparent>
  wakeup(p->parent);
    80002284:	0389b503          	ld	a0,56(s3)
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	e98080e7          	jalr	-360(ra) # 80002120 <wakeup>
  acquire(&p->lock);
    80002290:	854e                	mv	a0,s3
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9a0080e7          	jalr	-1632(ra) # 80000c32 <acquire>
  p->xstate = status;
    8000229a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000229e:	4795                	li	a5,5
    800022a0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	a40080e7          	jalr	-1472(ra) # 80000ce6 <release>
  sched();
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	cfc080e7          	jalr	-772(ra) # 80001faa <sched>
  panic("zombie exit");
    800022b6:	00006517          	auipc	a0,0x6
    800022ba:	fba50513          	addi	a0,a0,-70 # 80008270 <digits+0x230>
    800022be:	ffffe097          	auipc	ra,0xffffe
    800022c2:	280080e7          	jalr	640(ra) # 8000053e <panic>

00000000800022c6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022c6:	7179                	addi	sp,sp,-48
    800022c8:	f406                	sd	ra,40(sp)
    800022ca:	f022                	sd	s0,32(sp)
    800022cc:	ec26                	sd	s1,24(sp)
    800022ce:	e84a                	sd	s2,16(sp)
    800022d0:	e44e                	sd	s3,8(sp)
    800022d2:	1800                	addi	s0,sp,48
    800022d4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022d6:	0000f497          	auipc	s1,0xf
    800022da:	cda48493          	addi	s1,s1,-806 # 80010fb0 <proc>
    800022de:	00015997          	auipc	s3,0x15
    800022e2:	8d298993          	addi	s3,s3,-1838 # 80016bb0 <tickslock>
    acquire(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	94a080e7          	jalr	-1718(ra) # 80000c32 <acquire>
    if(p->pid == pid){
    800022f0:	589c                	lw	a5,48(s1)
    800022f2:	01278d63          	beq	a5,s2,8000230c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9ee080e7          	jalr	-1554(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002300:	17048493          	addi	s1,s1,368
    80002304:	ff3491e3          	bne	s1,s3,800022e6 <kill+0x20>
  }
  return -1;
    80002308:	557d                	li	a0,-1
    8000230a:	a829                	j	80002324 <kill+0x5e>
      p->killed = 1;
    8000230c:	4785                	li	a5,1
    8000230e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002310:	4c98                	lw	a4,24(s1)
    80002312:	4789                	li	a5,2
    80002314:	00f70f63          	beq	a4,a5,80002332 <kill+0x6c>
      release(&p->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	9cc080e7          	jalr	-1588(ra) # 80000ce6 <release>
      return 0;
    80002322:	4501                	li	a0,0
}
    80002324:	70a2                	ld	ra,40(sp)
    80002326:	7402                	ld	s0,32(sp)
    80002328:	64e2                	ld	s1,24(sp)
    8000232a:	6942                	ld	s2,16(sp)
    8000232c:	69a2                	ld	s3,8(sp)
    8000232e:	6145                	addi	sp,sp,48
    80002330:	8082                	ret
        p->state = RUNNABLE;
    80002332:	478d                	li	a5,3
    80002334:	cc9c                	sw	a5,24(s1)
    80002336:	b7cd                	j	80002318 <kill+0x52>

0000000080002338 <setkilled>:

void
setkilled(struct proc *p)
{
    80002338:	1101                	addi	sp,sp,-32
    8000233a:	ec06                	sd	ra,24(sp)
    8000233c:	e822                	sd	s0,16(sp)
    8000233e:	e426                	sd	s1,8(sp)
    80002340:	1000                	addi	s0,sp,32
    80002342:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	8ee080e7          	jalr	-1810(ra) # 80000c32 <acquire>
  p->killed = 1;
    8000234c:	4785                	li	a5,1
    8000234e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	994080e7          	jalr	-1644(ra) # 80000ce6 <release>
}
    8000235a:	60e2                	ld	ra,24(sp)
    8000235c:	6442                	ld	s0,16(sp)
    8000235e:	64a2                	ld	s1,8(sp)
    80002360:	6105                	addi	sp,sp,32
    80002362:	8082                	ret

0000000080002364 <killed>:

int
killed(struct proc *p)
{
    80002364:	1101                	addi	sp,sp,-32
    80002366:	ec06                	sd	ra,24(sp)
    80002368:	e822                	sd	s0,16(sp)
    8000236a:	e426                	sd	s1,8(sp)
    8000236c:	e04a                	sd	s2,0(sp)
    8000236e:	1000                	addi	s0,sp,32
    80002370:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	8c0080e7          	jalr	-1856(ra) # 80000c32 <acquire>
  k = p->killed;
    8000237a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	966080e7          	jalr	-1690(ra) # 80000ce6 <release>
  return k;
}
    80002388:	854a                	mv	a0,s2
    8000238a:	60e2                	ld	ra,24(sp)
    8000238c:	6442                	ld	s0,16(sp)
    8000238e:	64a2                	ld	s1,8(sp)
    80002390:	6902                	ld	s2,0(sp)
    80002392:	6105                	addi	sp,sp,32
    80002394:	8082                	ret

0000000080002396 <wait>:
{
    80002396:	715d                	addi	sp,sp,-80
    80002398:	e486                	sd	ra,72(sp)
    8000239a:	e0a2                	sd	s0,64(sp)
    8000239c:	fc26                	sd	s1,56(sp)
    8000239e:	f84a                	sd	s2,48(sp)
    800023a0:	f44e                	sd	s3,40(sp)
    800023a2:	f052                	sd	s4,32(sp)
    800023a4:	ec56                	sd	s5,24(sp)
    800023a6:	e85a                	sd	s6,16(sp)
    800023a8:	e45e                	sd	s7,8(sp)
    800023aa:	e062                	sd	s8,0(sp)
    800023ac:	0880                	addi	s0,sp,80
    800023ae:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	658080e7          	jalr	1624(ra) # 80001a08 <myproc>
    800023b8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ba:	0000e517          	auipc	a0,0xe
    800023be:	7de50513          	addi	a0,a0,2014 # 80010b98 <wait_lock>
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	870080e7          	jalr	-1936(ra) # 80000c32 <acquire>
    havekids = 0;
    800023ca:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023cc:	4a15                	li	s4,5
        havekids = 1;
    800023ce:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023d0:	00014997          	auipc	s3,0x14
    800023d4:	7e098993          	addi	s3,s3,2016 # 80016bb0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023d8:	0000ec17          	auipc	s8,0xe
    800023dc:	7c0c0c13          	addi	s8,s8,1984 # 80010b98 <wait_lock>
    havekids = 0;
    800023e0:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e2:	0000f497          	auipc	s1,0xf
    800023e6:	bce48493          	addi	s1,s1,-1074 # 80010fb0 <proc>
    800023ea:	a0bd                	j	80002458 <wait+0xc2>
          pid = pp->pid;
    800023ec:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023f0:	000b0e63          	beqz	s6,8000240c <wait+0x76>
    800023f4:	4691                	li	a3,4
    800023f6:	02c48613          	addi	a2,s1,44
    800023fa:	85da                	mv	a1,s6
    800023fc:	05093503          	ld	a0,80(s2)
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	2c4080e7          	jalr	708(ra) # 800016c4 <copyout>
    80002408:	02054563          	bltz	a0,80002432 <wait+0x9c>
          freeproc(pp);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	7ac080e7          	jalr	1964(ra) # 80001bba <freeproc>
          release(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8ce080e7          	jalr	-1842(ra) # 80000ce6 <release>
          release(&wait_lock);
    80002420:	0000e517          	auipc	a0,0xe
    80002424:	77850513          	addi	a0,a0,1912 # 80010b98 <wait_lock>
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	8be080e7          	jalr	-1858(ra) # 80000ce6 <release>
          return pid;
    80002430:	a0b5                	j	8000249c <wait+0x106>
            release(&pp->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	8b2080e7          	jalr	-1870(ra) # 80000ce6 <release>
            release(&wait_lock);
    8000243c:	0000e517          	auipc	a0,0xe
    80002440:	75c50513          	addi	a0,a0,1884 # 80010b98 <wait_lock>
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	8a2080e7          	jalr	-1886(ra) # 80000ce6 <release>
            return -1;
    8000244c:	59fd                	li	s3,-1
    8000244e:	a0b9                	j	8000249c <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002450:	17048493          	addi	s1,s1,368
    80002454:	03348463          	beq	s1,s3,8000247c <wait+0xe6>
      if(pp->parent == p){
    80002458:	7c9c                	ld	a5,56(s1)
    8000245a:	ff279be3          	bne	a5,s2,80002450 <wait+0xba>
        acquire(&pp->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	7d2080e7          	jalr	2002(ra) # 80000c32 <acquire>
        if(pp->state == ZOMBIE){
    80002468:	4c9c                	lw	a5,24(s1)
    8000246a:	f94781e3          	beq	a5,s4,800023ec <wait+0x56>
        release(&pp->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	876080e7          	jalr	-1930(ra) # 80000ce6 <release>
        havekids = 1;
    80002478:	8756                	mv	a4,s5
    8000247a:	bfd9                	j	80002450 <wait+0xba>
    if(!havekids || killed(p)){
    8000247c:	c719                	beqz	a4,8000248a <wait+0xf4>
    8000247e:	854a                	mv	a0,s2
    80002480:	00000097          	auipc	ra,0x0
    80002484:	ee4080e7          	jalr	-284(ra) # 80002364 <killed>
    80002488:	c51d                	beqz	a0,800024b6 <wait+0x120>
      release(&wait_lock);
    8000248a:	0000e517          	auipc	a0,0xe
    8000248e:	70e50513          	addi	a0,a0,1806 # 80010b98 <wait_lock>
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	854080e7          	jalr	-1964(ra) # 80000ce6 <release>
      return -1;
    8000249a:	59fd                	li	s3,-1
}
    8000249c:	854e                	mv	a0,s3
    8000249e:	60a6                	ld	ra,72(sp)
    800024a0:	6406                	ld	s0,64(sp)
    800024a2:	74e2                	ld	s1,56(sp)
    800024a4:	7942                	ld	s2,48(sp)
    800024a6:	79a2                	ld	s3,40(sp)
    800024a8:	7a02                	ld	s4,32(sp)
    800024aa:	6ae2                	ld	s5,24(sp)
    800024ac:	6b42                	ld	s6,16(sp)
    800024ae:	6ba2                	ld	s7,8(sp)
    800024b0:	6c02                	ld	s8,0(sp)
    800024b2:	6161                	addi	sp,sp,80
    800024b4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024b6:	85e2                	mv	a1,s8
    800024b8:	854a                	mv	a0,s2
    800024ba:	00000097          	auipc	ra,0x0
    800024be:	c02080e7          	jalr	-1022(ra) # 800020bc <sleep>
    havekids = 0;
    800024c2:	bf39                	j	800023e0 <wait+0x4a>

00000000800024c4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c4:	7179                	addi	sp,sp,-48
    800024c6:	f406                	sd	ra,40(sp)
    800024c8:	f022                	sd	s0,32(sp)
    800024ca:	ec26                	sd	s1,24(sp)
    800024cc:	e84a                	sd	s2,16(sp)
    800024ce:	e44e                	sd	s3,8(sp)
    800024d0:	e052                	sd	s4,0(sp)
    800024d2:	1800                	addi	s0,sp,48
    800024d4:	84aa                	mv	s1,a0
    800024d6:	892e                	mv	s2,a1
    800024d8:	89b2                	mv	s3,a2
    800024da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	52c080e7          	jalr	1324(ra) # 80001a08 <myproc>
  if(user_dst){
    800024e4:	c08d                	beqz	s1,80002506 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e6:	86d2                	mv	a3,s4
    800024e8:	864e                	mv	a2,s3
    800024ea:	85ca                	mv	a1,s2
    800024ec:	6928                	ld	a0,80(a0)
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	1d6080e7          	jalr	470(ra) # 800016c4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f6:	70a2                	ld	ra,40(sp)
    800024f8:	7402                	ld	s0,32(sp)
    800024fa:	64e2                	ld	s1,24(sp)
    800024fc:	6942                	ld	s2,16(sp)
    800024fe:	69a2                	ld	s3,8(sp)
    80002500:	6a02                	ld	s4,0(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret
    memmove((char *)dst, src, len);
    80002506:	000a061b          	sext.w	a2,s4
    8000250a:	85ce                	mv	a1,s3
    8000250c:	854a                	mv	a0,s2
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	87c080e7          	jalr	-1924(ra) # 80000d8a <memmove>
    return 0;
    80002516:	8526                	mv	a0,s1
    80002518:	bff9                	j	800024f6 <either_copyout+0x32>

000000008000251a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000251a:	7179                	addi	sp,sp,-48
    8000251c:	f406                	sd	ra,40(sp)
    8000251e:	f022                	sd	s0,32(sp)
    80002520:	ec26                	sd	s1,24(sp)
    80002522:	e84a                	sd	s2,16(sp)
    80002524:	e44e                	sd	s3,8(sp)
    80002526:	e052                	sd	s4,0(sp)
    80002528:	1800                	addi	s0,sp,48
    8000252a:	892a                	mv	s2,a0
    8000252c:	84ae                	mv	s1,a1
    8000252e:	89b2                	mv	s3,a2
    80002530:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	4d6080e7          	jalr	1238(ra) # 80001a08 <myproc>
  if(user_src){
    8000253a:	c08d                	beqz	s1,8000255c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000253c:	86d2                	mv	a3,s4
    8000253e:	864e                	mv	a2,s3
    80002540:	85ca                	mv	a1,s2
    80002542:	6928                	ld	a0,80(a0)
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	20c080e7          	jalr	524(ra) # 80001750 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000254c:	70a2                	ld	ra,40(sp)
    8000254e:	7402                	ld	s0,32(sp)
    80002550:	64e2                	ld	s1,24(sp)
    80002552:	6942                	ld	s2,16(sp)
    80002554:	69a2                	ld	s3,8(sp)
    80002556:	6a02                	ld	s4,0(sp)
    80002558:	6145                	addi	sp,sp,48
    8000255a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000255c:	000a061b          	sext.w	a2,s4
    80002560:	85ce                	mv	a1,s3
    80002562:	854a                	mv	a0,s2
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	826080e7          	jalr	-2010(ra) # 80000d8a <memmove>
    return 0;
    8000256c:	8526                	mv	a0,s1
    8000256e:	bff9                	j	8000254c <either_copyin+0x32>

0000000080002570 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002570:	715d                	addi	sp,sp,-80
    80002572:	e486                	sd	ra,72(sp)
    80002574:	e0a2                	sd	s0,64(sp)
    80002576:	fc26                	sd	s1,56(sp)
    80002578:	f84a                	sd	s2,48(sp)
    8000257a:	f44e                	sd	s3,40(sp)
    8000257c:	f052                	sd	s4,32(sp)
    8000257e:	ec56                	sd	s5,24(sp)
    80002580:	e85a                	sd	s6,16(sp)
    80002582:	e45e                	sd	s7,8(sp)
    80002584:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002586:	00006517          	auipc	a0,0x6
    8000258a:	b4250513          	addi	a0,a0,-1214 # 800080c8 <digits+0x88>
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	ffa080e7          	jalr	-6(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002596:	0000f497          	auipc	s1,0xf
    8000259a:	b7248493          	addi	s1,s1,-1166 # 80011108 <proc+0x158>
    8000259e:	00014917          	auipc	s2,0x14
    800025a2:	76a90913          	addi	s2,s2,1898 # 80016d08 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a8:	00006997          	auipc	s3,0x6
    800025ac:	cd898993          	addi	s3,s3,-808 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025b0:	00006a97          	auipc	s5,0x6
    800025b4:	cd8a8a93          	addi	s5,s5,-808 # 80008288 <digits+0x248>
    printf("\n");
    800025b8:	00006a17          	auipc	s4,0x6
    800025bc:	b10a0a13          	addi	s4,s4,-1264 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c0:	00006b97          	auipc	s7,0x6
    800025c4:	d38b8b93          	addi	s7,s7,-712 # 800082f8 <states.0>
    800025c8:	a00d                	j	800025ea <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ca:	ed86a583          	lw	a1,-296(a3)
    800025ce:	8556                	mv	a0,s5
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	fb8080e7          	jalr	-72(ra) # 80000588 <printf>
    printf("\n");
    800025d8:	8552                	mv	a0,s4
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	fae080e7          	jalr	-82(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e2:	17048493          	addi	s1,s1,368
    800025e6:	03248163          	beq	s1,s2,80002608 <procdump+0x98>
    if(p->state == UNUSED)
    800025ea:	86a6                	mv	a3,s1
    800025ec:	ec04a783          	lw	a5,-320(s1)
    800025f0:	dbed                	beqz	a5,800025e2 <procdump+0x72>
      state = "???";
    800025f2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	fcfb6be3          	bltu	s6,a5,800025ca <procdump+0x5a>
    800025f8:	1782                	slli	a5,a5,0x20
    800025fa:	9381                	srli	a5,a5,0x20
    800025fc:	078e                	slli	a5,a5,0x3
    800025fe:	97de                	add	a5,a5,s7
    80002600:	6390                	ld	a2,0(a5)
    80002602:	f661                	bnez	a2,800025ca <procdump+0x5a>
      state = "???";
    80002604:	864e                	mv	a2,s3
    80002606:	b7d1                	j	800025ca <procdump+0x5a>
  }
}
    80002608:	60a6                	ld	ra,72(sp)
    8000260a:	6406                	ld	s0,64(sp)
    8000260c:	74e2                	ld	s1,56(sp)
    8000260e:	7942                	ld	s2,48(sp)
    80002610:	79a2                	ld	s3,40(sp)
    80002612:	7a02                	ld	s4,32(sp)
    80002614:	6ae2                	ld	s5,24(sp)
    80002616:	6b42                	ld	s6,16(sp)
    80002618:	6ba2                	ld	s7,8(sp)
    8000261a:	6161                	addi	sp,sp,80
    8000261c:	8082                	ret

000000008000261e <getHelloWorld>:

uint64 
getHelloWorld(void)
{
    8000261e:	1141                	addi	sp,sp,-16
    80002620:	e406                	sd	ra,8(sp)
    80002622:	e022                	sd	s0,0(sp)
    80002624:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    80002626:	00006517          	auipc	a0,0x6
    8000262a:	c7250513          	addi	a0,a0,-910 # 80008298 <digits+0x258>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f5a080e7          	jalr	-166(ra) # 80000588 <printf>
  return 0;
}
    80002636:	4501                	li	a0,0
    80002638:	60a2                	ld	ra,8(sp)
    8000263a:	6402                	ld	s0,0(sp)
    8000263c:	0141                	addi	sp,sp,16
    8000263e:	8082                	ret

0000000080002640 <getProcTick>:

int 
getProcTick(int pid){
    80002640:	7139                	addi	sp,sp,-64
    80002642:	fc06                	sd	ra,56(sp)
    80002644:	f822                	sd	s0,48(sp)
    80002646:	f426                	sd	s1,40(sp)
    80002648:	f04a                	sd	s2,32(sp)
    8000264a:	ec4e                	sd	s3,24(sp)
    8000264c:	e852                	sd	s4,16(sp)
    8000264e:	e456                	sd	s5,8(sp)
    80002650:	0080                	addi	s0,sp,64
    80002652:	892a                	mv	s2,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002654:	0000f497          	auipc	s1,0xf
    80002658:	95c48493          	addi	s1,s1,-1700 # 80010fb0 <proc>
   acquire(&p->lock);
    // acquire(&tickslock);
    if(pid == p->pid){
      int diff = ticks - p->ctime;
    8000265c:	00006a97          	auipc	s5,0x6
    80002660:	2b4a8a93          	addi	s5,s5,692 # 80008910 <ticks>
      if (diff < 0){
        diff = diff * -1; 
      }
      printf("%d\n", diff);
    80002664:	00006a17          	auipc	s4,0x6
    80002668:	dfca0a13          	addi	s4,s4,-516 # 80008460 <states.0+0x168>
  for(p = proc; p < &proc[NPROC]; p++){
    8000266c:	00014997          	auipc	s3,0x14
    80002670:	54498993          	addi	s3,s3,1348 # 80016bb0 <tickslock>
    80002674:	a811                	j	80002688 <getProcTick+0x48>
    }
   release(&p->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	66e080e7          	jalr	1646(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002680:	17048493          	addi	s1,s1,368
    80002684:	03348a63          	beq	s1,s3,800026b8 <getProcTick+0x78>
   acquire(&p->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	5a8080e7          	jalr	1448(ra) # 80000c32 <acquire>
    if(pid == p->pid){
    80002692:	589c                	lw	a5,48(s1)
    80002694:	ff2791e3          	bne	a5,s2,80002676 <getProcTick+0x36>
      int diff = ticks - p->ctime;
    80002698:	000aa783          	lw	a5,0(s5)
    8000269c:	1684a583          	lw	a1,360(s1)
    800026a0:	9f8d                	subw	a5,a5,a1
      printf("%d\n", diff);
    800026a2:	41f7d59b          	sraiw	a1,a5,0x1f
    800026a6:	8fad                	xor	a5,a5,a1
    800026a8:	40b785bb          	subw	a1,a5,a1
    800026ac:	8552                	mv	a0,s4
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	eda080e7          	jalr	-294(ra) # 80000588 <printf>
    800026b6:	b7c1                	j	80002676 <getProcTick+0x36>
  //  release(&tickslock);
  }
  // printf("%d\n", ticks);
  return 0;
}
    800026b8:	4501                	li	a0,0
    800026ba:	70e2                	ld	ra,56(sp)
    800026bc:	7442                	ld	s0,48(sp)
    800026be:	74a2                	ld	s1,40(sp)
    800026c0:	7902                	ld	s2,32(sp)
    800026c2:	69e2                	ld	s3,24(sp)
    800026c4:	6a42                	ld	s4,16(sp)
    800026c6:	6aa2                	ld	s5,8(sp)
    800026c8:	6121                	addi	sp,sp,64
    800026ca:	8082                	ret

00000000800026cc <getProcInfo>:

int 
getProcInfo(void){
    800026cc:	7179                	addi	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	ec26                	sd	s1,24(sp)
    800026d4:	e84a                	sd	s2,16(sp)
    800026d6:	e44e                	sd	s3,8(sp)
    800026d8:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800026da:	0000f497          	auipc	s1,0xf
    800026de:	8d648493          	addi	s1,s1,-1834 # 80010fb0 <proc>
  
  // for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  if(p->state != UNUSED)
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    800026e2:	00006997          	auipc	s3,0x6
    800026e6:	bc698993          	addi	s3,s3,-1082 # 800082a8 <digits+0x268>
  for(p = proc; p < &proc[NPROC]; p++){
    800026ea:	00014917          	auipc	s2,0x14
    800026ee:	4c690913          	addi	s2,s2,1222 # 80016bb0 <tickslock>
    800026f2:	a029                	j	800026fc <getProcInfo+0x30>
    800026f4:	17048493          	addi	s1,s1,368
    800026f8:	01248d63          	beq	s1,s2,80002712 <getProcInfo+0x46>
  if(p->state != UNUSED)
    800026fc:	4c9c                	lw	a5,24(s1)
    800026fe:	dbfd                	beqz	a5,800026f4 <getProcInfo+0x28>
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    80002700:	1684a603          	lw	a2,360(s1)
    80002704:	588c                	lw	a1,48(s1)
    80002706:	854e                	mv	a0,s3
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	e80080e7          	jalr	-384(ra) # 80000588 <printf>
    80002710:	b7d5                	j	800026f4 <getProcInfo+0x28>
    // if(p->state == SLEEPING){
    //   cprintf("-pid = %d, create time = %d\n", p->pid, p->ctime);
    // }
  }
  return 0;
}
    80002712:	4501                	li	a0,0
    80002714:	70a2                	ld	ra,40(sp)
    80002716:	7402                	ld	s0,32(sp)
    80002718:	64e2                	ld	s1,24(sp)
    8000271a:	6942                	ld	s2,16(sp)
    8000271c:	69a2                	ld	s3,8(sp)
    8000271e:	6145                	addi	sp,sp,48
    80002720:	8082                	ret

0000000080002722 <nproc>:
//   printf("sysinfo ?????\n");
//   return 0;
// }
uint64
nproc(struct sysinfo *addr)
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	e052                	sd	s4,0(sp)
    80002730:	1800                	addi	s0,sp,48
  uint64 cnt = 0;

  for (int i = 0; i < NPROC; i++) {
    80002732:	0000f497          	auipc	s1,0xf
    80002736:	87e48493          	addi	s1,s1,-1922 # 80010fb0 <proc>
    8000273a:	00014a17          	auipc	s4,0x14
    8000273e:	476a0a13          	addi	s4,s4,1142 # 80016bb0 <tickslock>
  uint64 cnt = 0;
    80002742:	4901                	li	s2,0
    acquire(&proc[i].lock); 
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	4ec080e7          	jalr	1260(ra) # 80000c32 <acquire>
    if (proc[i].state != UNUSED)
    8000274e:	4c9c                	lw	a5,24(s1)
      cnt++;
    80002750:	00f037b3          	snez	a5,a5
    80002754:	993e                	add	s2,s2,a5
    release(&proc[i].lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	58e080e7          	jalr	1422(ra) # 80000ce6 <release>
  for (int i = 0; i < NPROC; i++) {
    80002760:	17048493          	addi	s1,s1,368
    80002764:	ff4490e3          	bne	s1,s4,80002744 <nproc+0x22>
  }

  return cnt;
}
    80002768:	854a                	mv	a0,s2
    8000276a:	70a2                	ld	ra,40(sp)
    8000276c:	7402                	ld	s0,32(sp)
    8000276e:	64e2                	ld	s1,24(sp)
    80002770:	6942                	ld	s2,16(sp)
    80002772:	69a2                	ld	s3,8(sp)
    80002774:	6a02                	ld	s4,0(sp)
    80002776:	6145                	addi	sp,sp,48
    80002778:	8082                	ret

000000008000277a <getTicks>:

double 
getTicks(void){
    8000277a:	1141                	addi	sp,sp,-16
    8000277c:	e422                	sd	s0,8(sp)
    8000277e:	0800                	addi	s0,sp,16

  // printf("%d\n", ticks);

  // release(&p->lock);
  return ticks;
}
    80002780:	00006797          	auipc	a5,0x6
    80002784:	1907a783          	lw	a5,400(a5) # 80008910 <ticks>
    80002788:	d2178553          	fcvt.d.wu	fa0,a5
    8000278c:	6422                	ld	s0,8(sp)
    8000278e:	0141                	addi	sp,sp,16
    80002790:	8082                	ret

0000000080002792 <swtch>:
    80002792:	00153023          	sd	ra,0(a0)
    80002796:	00253423          	sd	sp,8(a0)
    8000279a:	e900                	sd	s0,16(a0)
    8000279c:	ed04                	sd	s1,24(a0)
    8000279e:	03253023          	sd	s2,32(a0)
    800027a2:	03353423          	sd	s3,40(a0)
    800027a6:	03453823          	sd	s4,48(a0)
    800027aa:	03553c23          	sd	s5,56(a0)
    800027ae:	05653023          	sd	s6,64(a0)
    800027b2:	05753423          	sd	s7,72(a0)
    800027b6:	05853823          	sd	s8,80(a0)
    800027ba:	05953c23          	sd	s9,88(a0)
    800027be:	07a53023          	sd	s10,96(a0)
    800027c2:	07b53423          	sd	s11,104(a0)
    800027c6:	0005b083          	ld	ra,0(a1)
    800027ca:	0085b103          	ld	sp,8(a1)
    800027ce:	6980                	ld	s0,16(a1)
    800027d0:	6d84                	ld	s1,24(a1)
    800027d2:	0205b903          	ld	s2,32(a1)
    800027d6:	0285b983          	ld	s3,40(a1)
    800027da:	0305ba03          	ld	s4,48(a1)
    800027de:	0385ba83          	ld	s5,56(a1)
    800027e2:	0405bb03          	ld	s6,64(a1)
    800027e6:	0485bb83          	ld	s7,72(a1)
    800027ea:	0505bc03          	ld	s8,80(a1)
    800027ee:	0585bc83          	ld	s9,88(a1)
    800027f2:	0605bd03          	ld	s10,96(a1)
    800027f6:	0685bd83          	ld	s11,104(a1)
    800027fa:	8082                	ret

00000000800027fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027fc:	1141                	addi	sp,sp,-16
    800027fe:	e406                	sd	ra,8(sp)
    80002800:	e022                	sd	s0,0(sp)
    80002802:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002804:	00006597          	auipc	a1,0x6
    80002808:	b2458593          	addi	a1,a1,-1244 # 80008328 <states.0+0x30>
    8000280c:	00014517          	auipc	a0,0x14
    80002810:	3a450513          	addi	a0,a0,932 # 80016bb0 <tickslock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	38e080e7          	jalr	910(ra) # 80000ba2 <initlock>
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e422                	sd	s0,8(sp)
    80002828:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	59678793          	addi	a5,a5,1430 # 80005dc0 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002836:	6422                	ld	s0,8(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000283c:	1141                	addi	sp,sp,-16
    8000283e:	e406                	sd	ra,8(sp)
    80002840:	e022                	sd	s0,0(sp)
    80002842:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	1c4080e7          	jalr	452(ra) # 80001a08 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002850:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002852:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002856:	00004617          	auipc	a2,0x4
    8000285a:	7aa60613          	addi	a2,a2,1962 # 80007000 <_trampoline>
    8000285e:	00004697          	auipc	a3,0x4
    80002862:	7a268693          	addi	a3,a3,1954 # 80007000 <_trampoline>
    80002866:	8e91                	sub	a3,a3,a2
    80002868:	040007b7          	lui	a5,0x4000
    8000286c:	17fd                	addi	a5,a5,-1
    8000286e:	07b2                	slli	a5,a5,0xc
    80002870:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002876:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002878:	180026f3          	csrr	a3,satp
    8000287c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000287e:	6d38                	ld	a4,88(a0)
    80002880:	6134                	ld	a3,64(a0)
    80002882:	6585                	lui	a1,0x1
    80002884:	96ae                	add	a3,a3,a1
    80002886:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002888:	6d38                	ld	a4,88(a0)
    8000288a:	00000697          	auipc	a3,0x0
    8000288e:	13068693          	addi	a3,a3,304 # 800029ba <usertrap>
    80002892:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002896:	8692                	mv	a3,tp
    80002898:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000289e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ac:	6f18                	ld	a4,24(a4)
    800028ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b2:	6928                	ld	a0,80(a0)
    800028b4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028b6:	00004717          	auipc	a4,0x4
    800028ba:	7e670713          	addi	a4,a4,2022 # 8000709c <userret>
    800028be:	8f11                	sub	a4,a4,a2
    800028c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028c2:	577d                	li	a4,-1
    800028c4:	177e                	slli	a4,a4,0x3f
    800028c6:	8d59                	or	a0,a0,a4
    800028c8:	9782                	jalr	a5
}
    800028ca:	60a2                	ld	ra,8(sp)
    800028cc:	6402                	ld	s0,0(sp)
    800028ce:	0141                	addi	sp,sp,16
    800028d0:	8082                	ret

00000000800028d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028d2:	1101                	addi	sp,sp,-32
    800028d4:	ec06                	sd	ra,24(sp)
    800028d6:	e822                	sd	s0,16(sp)
    800028d8:	e426                	sd	s1,8(sp)
    800028da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028dc:	00014497          	auipc	s1,0x14
    800028e0:	2d448493          	addi	s1,s1,724 # 80016bb0 <tickslock>
    800028e4:	8526                	mv	a0,s1
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	34c080e7          	jalr	844(ra) # 80000c32 <acquire>
  ticks++;
    800028ee:	00006517          	auipc	a0,0x6
    800028f2:	02250513          	addi	a0,a0,34 # 80008910 <ticks>
    800028f6:	411c                	lw	a5,0(a0)
    800028f8:	2785                	addiw	a5,a5,1
    800028fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	824080e7          	jalr	-2012(ra) # 80002120 <wakeup>
  release(&tickslock);
    80002904:	8526                	mv	a0,s1
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	3e0080e7          	jalr	992(ra) # 80000ce6 <release>
}
    8000290e:	60e2                	ld	ra,24(sp)
    80002910:	6442                	ld	s0,16(sp)
    80002912:	64a2                	ld	s1,8(sp)
    80002914:	6105                	addi	sp,sp,32
    80002916:	8082                	ret

0000000080002918 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002918:	1101                	addi	sp,sp,-32
    8000291a:	ec06                	sd	ra,24(sp)
    8000291c:	e822                	sd	s0,16(sp)
    8000291e:	e426                	sd	s1,8(sp)
    80002920:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002922:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002926:	00074d63          	bltz	a4,80002940 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000292a:	57fd                	li	a5,-1
    8000292c:	17fe                	slli	a5,a5,0x3f
    8000292e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002930:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002932:	06f70363          	beq	a4,a5,80002998 <devintr+0x80>
  }
}
    80002936:	60e2                	ld	ra,24(sp)
    80002938:	6442                	ld	s0,16(sp)
    8000293a:	64a2                	ld	s1,8(sp)
    8000293c:	6105                	addi	sp,sp,32
    8000293e:	8082                	ret
     (scause & 0xff) == 9){
    80002940:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002944:	46a5                	li	a3,9
    80002946:	fed792e3          	bne	a5,a3,8000292a <devintr+0x12>
    int irq = plic_claim();
    8000294a:	00003097          	auipc	ra,0x3
    8000294e:	57e080e7          	jalr	1406(ra) # 80005ec8 <plic_claim>
    80002952:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002954:	47a9                	li	a5,10
    80002956:	02f50763          	beq	a0,a5,80002984 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000295a:	4785                	li	a5,1
    8000295c:	02f50963          	beq	a0,a5,8000298e <devintr+0x76>
    return 1;
    80002960:	4505                	li	a0,1
    } else if(irq){
    80002962:	d8f1                	beqz	s1,80002936 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002964:	85a6                	mv	a1,s1
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	9ca50513          	addi	a0,a0,-1590 # 80008330 <states.0+0x38>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c1a080e7          	jalr	-998(ra) # 80000588 <printf>
      plic_complete(irq);
    80002976:	8526                	mv	a0,s1
    80002978:	00003097          	auipc	ra,0x3
    8000297c:	574080e7          	jalr	1396(ra) # 80005eec <plic_complete>
    return 1;
    80002980:	4505                	li	a0,1
    80002982:	bf55                	j	80002936 <devintr+0x1e>
      uartintr();
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	016080e7          	jalr	22(ra) # 8000099a <uartintr>
    8000298c:	b7ed                	j	80002976 <devintr+0x5e>
      virtio_disk_intr();
    8000298e:	00004097          	auipc	ra,0x4
    80002992:	a2a080e7          	jalr	-1494(ra) # 800063b8 <virtio_disk_intr>
    80002996:	b7c5                	j	80002976 <devintr+0x5e>
    if(cpuid() == 0){
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	044080e7          	jalr	68(ra) # 800019dc <cpuid>
    800029a0:	c901                	beqz	a0,800029b0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029a2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a8:	14479073          	csrw	sip,a5
    return 2;
    800029ac:	4509                	li	a0,2
    800029ae:	b761                	j	80002936 <devintr+0x1e>
      clockintr();
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	f22080e7          	jalr	-222(ra) # 800028d2 <clockintr>
    800029b8:	b7ed                	j	800029a2 <devintr+0x8a>

00000000800029ba <usertrap>:
{
    800029ba:	1101                	addi	sp,sp,-32
    800029bc:	ec06                	sd	ra,24(sp)
    800029be:	e822                	sd	s0,16(sp)
    800029c0:	e426                	sd	s1,8(sp)
    800029c2:	e04a                	sd	s2,0(sp)
    800029c4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ca:	1007f793          	andi	a5,a5,256
    800029ce:	e3b1                	bnez	a5,80002a12 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d0:	00003797          	auipc	a5,0x3
    800029d4:	3f078793          	addi	a5,a5,1008 # 80005dc0 <kernelvec>
    800029d8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	02c080e7          	jalr	44(ra) # 80001a08 <myproc>
    800029e4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e8:	14102773          	csrr	a4,sepc
    800029ec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029f2:	47a1                	li	a5,8
    800029f4:	02f70763          	beq	a4,a5,80002a22 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	f20080e7          	jalr	-224(ra) # 80002918 <devintr>
    80002a00:	892a                	mv	s2,a0
    80002a02:	c151                	beqz	a0,80002a86 <usertrap+0xcc>
  if(killed(p))
    80002a04:	8526                	mv	a0,s1
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	95e080e7          	jalr	-1698(ra) # 80002364 <killed>
    80002a0e:	c929                	beqz	a0,80002a60 <usertrap+0xa6>
    80002a10:	a099                	j	80002a56 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	93e50513          	addi	a0,a0,-1730 # 80008350 <states.0+0x58>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b24080e7          	jalr	-1244(ra) # 8000053e <panic>
    if(killed(p))
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	942080e7          	jalr	-1726(ra) # 80002364 <killed>
    80002a2a:	e921                	bnez	a0,80002a7a <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a2c:	6cb8                	ld	a4,88(s1)
    80002a2e:	6f1c                	ld	a5,24(a4)
    80002a30:	0791                	addi	a5,a5,4
    80002a32:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	2d4080e7          	jalr	724(ra) # 80002d14 <syscall>
  if(killed(p))
    80002a48:	8526                	mv	a0,s1
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	91a080e7          	jalr	-1766(ra) # 80002364 <killed>
    80002a52:	c911                	beqz	a0,80002a66 <usertrap+0xac>
    80002a54:	4901                	li	s2,0
    exit(-1);
    80002a56:	557d                	li	a0,-1
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	798080e7          	jalr	1944(ra) # 800021f0 <exit>
  if(which_dev == 2)
    80002a60:	4789                	li	a5,2
    80002a62:	04f90f63          	beq	s2,a5,80002ac0 <usertrap+0x106>
  usertrapret();
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	dd6080e7          	jalr	-554(ra) # 8000283c <usertrapret>
}
    80002a6e:	60e2                	ld	ra,24(sp)
    80002a70:	6442                	ld	s0,16(sp)
    80002a72:	64a2                	ld	s1,8(sp)
    80002a74:	6902                	ld	s2,0(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret
      exit(-1);
    80002a7a:	557d                	li	a0,-1
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	774080e7          	jalr	1908(ra) # 800021f0 <exit>
    80002a84:	b765                	j	80002a2c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a86:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a8a:	5890                	lw	a2,48(s1)
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	8e450513          	addi	a0,a0,-1820 # 80008370 <states.0+0x78>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	af4080e7          	jalr	-1292(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	8fc50513          	addi	a0,a0,-1796 # 800083a0 <states.0+0xa8>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	adc080e7          	jalr	-1316(ra) # 80000588 <printf>
    setkilled(p);
    80002ab4:	8526                	mv	a0,s1
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	882080e7          	jalr	-1918(ra) # 80002338 <setkilled>
    80002abe:	b769                	j	80002a48 <usertrap+0x8e>
    yield();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	5c0080e7          	jalr	1472(ra) # 80002080 <yield>
    80002ac8:	bf79                	j	80002a66 <usertrap+0xac>

0000000080002aca <kerneltrap>:
{
    80002aca:	7179                	addi	sp,sp,-48
    80002acc:	f406                	sd	ra,40(sp)
    80002ace:	f022                	sd	s0,32(sp)
    80002ad0:	ec26                	sd	s1,24(sp)
    80002ad2:	e84a                	sd	s2,16(sp)
    80002ad4:	e44e                	sd	s3,8(sp)
    80002ad6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002adc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ae4:	1004f793          	andi	a5,s1,256
    80002ae8:	cb85                	beqz	a5,80002b18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002af0:	ef85                	bnez	a5,80002b28 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	e26080e7          	jalr	-474(ra) # 80002918 <devintr>
    80002afa:	cd1d                	beqz	a0,80002b38 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002afc:	4789                	li	a5,2
    80002afe:	06f50a63          	beq	a0,a5,80002b72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b06:	10049073          	csrw	sstatus,s1
}
    80002b0a:	70a2                	ld	ra,40(sp)
    80002b0c:	7402                	ld	s0,32(sp)
    80002b0e:	64e2                	ld	s1,24(sp)
    80002b10:	6942                	ld	s2,16(sp)
    80002b12:	69a2                	ld	s3,8(sp)
    80002b14:	6145                	addi	sp,sp,48
    80002b16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	8a850513          	addi	a0,a0,-1880 # 800083c0 <states.0+0xc8>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a1e080e7          	jalr	-1506(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	8c050513          	addi	a0,a0,-1856 # 800083e8 <states.0+0xf0>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b38:	85ce                	mv	a1,s3
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	8ce50513          	addi	a0,a0,-1842 # 80008408 <states.0+0x110>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a46080e7          	jalr	-1466(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b52:	00006517          	auipc	a0,0x6
    80002b56:	8c650513          	addi	a0,a0,-1850 # 80008418 <states.0+0x120>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	a2e080e7          	jalr	-1490(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	8ce50513          	addi	a0,a0,-1842 # 80008430 <states.0+0x138>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	e96080e7          	jalr	-362(ra) # 80001a08 <myproc>
    80002b7a:	d541                	beqz	a0,80002b02 <kerneltrap+0x38>
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	e8c080e7          	jalr	-372(ra) # 80001a08 <myproc>
    80002b84:	4d18                	lw	a4,24(a0)
    80002b86:	4791                	li	a5,4
    80002b88:	f6f71de3          	bne	a4,a5,80002b02 <kerneltrap+0x38>
    yield();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	4f4080e7          	jalr	1268(ra) # 80002080 <yield>
    80002b94:	b7bd                	j	80002b02 <kerneltrap+0x38>

0000000080002b96 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	e426                	sd	s1,8(sp)
    80002b9e:	1000                	addi	s0,sp,32
    80002ba0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e66080e7          	jalr	-410(ra) # 80001a08 <myproc>
  switch (n) {
    80002baa:	4795                	li	a5,5
    80002bac:	0497e163          	bltu	a5,s1,80002bee <argraw+0x58>
    80002bb0:	048a                	slli	s1,s1,0x2
    80002bb2:	00006717          	auipc	a4,0x6
    80002bb6:	8b670713          	addi	a4,a4,-1866 # 80008468 <states.0+0x170>
    80002bba:	94ba                	add	s1,s1,a4
    80002bbc:	409c                	lw	a5,0(s1)
    80002bbe:	97ba                	add	a5,a5,a4
    80002bc0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bc2:	6d3c                	ld	a5,88(a0)
    80002bc4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	64a2                	ld	s1,8(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret
    return p->trapframe->a1;
    80002bd0:	6d3c                	ld	a5,88(a0)
    80002bd2:	7fa8                	ld	a0,120(a5)
    80002bd4:	bfcd                	j	80002bc6 <argraw+0x30>
    return p->trapframe->a2;
    80002bd6:	6d3c                	ld	a5,88(a0)
    80002bd8:	63c8                	ld	a0,128(a5)
    80002bda:	b7f5                	j	80002bc6 <argraw+0x30>
    return p->trapframe->a3;
    80002bdc:	6d3c                	ld	a5,88(a0)
    80002bde:	67c8                	ld	a0,136(a5)
    80002be0:	b7dd                	j	80002bc6 <argraw+0x30>
    return p->trapframe->a4;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	6bc8                	ld	a0,144(a5)
    80002be6:	b7c5                	j	80002bc6 <argraw+0x30>
    return p->trapframe->a5;
    80002be8:	6d3c                	ld	a5,88(a0)
    80002bea:	6fc8                	ld	a0,152(a5)
    80002bec:	bfe9                	j	80002bc6 <argraw+0x30>
  panic("argraw");
    80002bee:	00006517          	auipc	a0,0x6
    80002bf2:	85250513          	addi	a0,a0,-1966 # 80008440 <states.0+0x148>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	948080e7          	jalr	-1720(ra) # 8000053e <panic>

0000000080002bfe <fetchaddr>:
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84aa                	mv	s1,a0
    80002c0c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	dfa080e7          	jalr	-518(ra) # 80001a08 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c16:	653c                	ld	a5,72(a0)
    80002c18:	02f4f863          	bgeu	s1,a5,80002c48 <fetchaddr+0x4a>
    80002c1c:	00848713          	addi	a4,s1,8
    80002c20:	02e7e663          	bltu	a5,a4,80002c4c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c24:	46a1                	li	a3,8
    80002c26:	8626                	mv	a2,s1
    80002c28:	85ca                	mv	a1,s2
    80002c2a:	6928                	ld	a0,80(a0)
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	b24080e7          	jalr	-1244(ra) # 80001750 <copyin>
    80002c34:	00a03533          	snez	a0,a0
    80002c38:	40a00533          	neg	a0,a0
}
    80002c3c:	60e2                	ld	ra,24(sp)
    80002c3e:	6442                	ld	s0,16(sp)
    80002c40:	64a2                	ld	s1,8(sp)
    80002c42:	6902                	ld	s2,0(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret
    return -1;
    80002c48:	557d                	li	a0,-1
    80002c4a:	bfcd                	j	80002c3c <fetchaddr+0x3e>
    80002c4c:	557d                	li	a0,-1
    80002c4e:	b7fd                	j	80002c3c <fetchaddr+0x3e>

0000000080002c50 <fetchstr>:
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	e84a                	sd	s2,16(sp)
    80002c5a:	e44e                	sd	s3,8(sp)
    80002c5c:	1800                	addi	s0,sp,48
    80002c5e:	892a                	mv	s2,a0
    80002c60:	84ae                	mv	s1,a1
    80002c62:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	da4080e7          	jalr	-604(ra) # 80001a08 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c6c:	86ce                	mv	a3,s3
    80002c6e:	864a                	mv	a2,s2
    80002c70:	85a6                	mv	a1,s1
    80002c72:	6928                	ld	a0,80(a0)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	b6a080e7          	jalr	-1174(ra) # 800017de <copyinstr>
    80002c7c:	00054e63          	bltz	a0,80002c98 <fetchstr+0x48>
  return strlen(buf);
    80002c80:	8526                	mv	a0,s1
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	228080e7          	jalr	552(ra) # 80000eaa <strlen>
}
    80002c8a:	70a2                	ld	ra,40(sp)
    80002c8c:	7402                	ld	s0,32(sp)
    80002c8e:	64e2                	ld	s1,24(sp)
    80002c90:	6942                	ld	s2,16(sp)
    80002c92:	69a2                	ld	s3,8(sp)
    80002c94:	6145                	addi	sp,sp,48
    80002c96:	8082                	ret
    return -1;
    80002c98:	557d                	li	a0,-1
    80002c9a:	bfc5                	j	80002c8a <fetchstr+0x3a>

0000000080002c9c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
    80002ca6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	eee080e7          	jalr	-274(ra) # 80002b96 <argraw>
    80002cb0:	c088                	sw	a0,0(s1)
}
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	64a2                	ld	s1,8(sp)
    80002cb8:	6105                	addi	sp,sp,32
    80002cba:	8082                	ret

0000000080002cbc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{ 
    80002cbc:	1101                	addi	sp,sp,-32
    80002cbe:	ec06                	sd	ra,24(sp)
    80002cc0:	e822                	sd	s0,16(sp)
    80002cc2:	e426                	sd	s1,8(sp)
    80002cc4:	1000                	addi	s0,sp,32
    80002cc6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	ece080e7          	jalr	-306(ra) # 80002b96 <argraw>
    80002cd0:	e088                	sd	a0,0(s1)
  // return 0;
}
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	64a2                	ld	s1,8(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cdc:	7179                	addi	sp,sp,-48
    80002cde:	f406                	sd	ra,40(sp)
    80002ce0:	f022                	sd	s0,32(sp)
    80002ce2:	ec26                	sd	s1,24(sp)
    80002ce4:	e84a                	sd	s2,16(sp)
    80002ce6:	1800                	addi	s0,sp,48
    80002ce8:	84ae                	mv	s1,a1
    80002cea:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002cec:	fd840593          	addi	a1,s0,-40
    80002cf0:	00000097          	auipc	ra,0x0
    80002cf4:	fcc080e7          	jalr	-52(ra) # 80002cbc <argaddr>
  return fetchstr(addr, buf, max);
    80002cf8:	864a                	mv	a2,s2
    80002cfa:	85a6                	mv	a1,s1
    80002cfc:	fd843503          	ld	a0,-40(s0)
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	f50080e7          	jalr	-176(ra) # 80002c50 <fetchstr>
}
    80002d08:	70a2                	ld	ra,40(sp)
    80002d0a:	7402                	ld	s0,32(sp)
    80002d0c:	64e2                	ld	s1,24(sp)
    80002d0e:	6942                	ld	s2,16(sp)
    80002d10:	6145                	addi	sp,sp,48
    80002d12:	8082                	ret

0000000080002d14 <syscall>:
[SYS_sysinfo] sys_sysinfo,
};

void
syscall(void)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	e04a                	sd	s2,0(sp)
    80002d1e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	ce8080e7          	jalr	-792(ra) # 80001a08 <myproc>
    80002d28:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d2a:	05853903          	ld	s2,88(a0)
    80002d2e:	0a893783          	ld	a5,168(s2)
    80002d32:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d36:	37fd                	addiw	a5,a5,-1
    80002d38:	4761                	li	a4,24
    80002d3a:	00f76f63          	bltu	a4,a5,80002d58 <syscall+0x44>
    80002d3e:	00369713          	slli	a4,a3,0x3
    80002d42:	00005797          	auipc	a5,0x5
    80002d46:	73e78793          	addi	a5,a5,1854 # 80008480 <syscalls>
    80002d4a:	97ba                	add	a5,a5,a4
    80002d4c:	639c                	ld	a5,0(a5)
    80002d4e:	c789                	beqz	a5,80002d58 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d50:	9782                	jalr	a5
    80002d52:	06a93823          	sd	a0,112(s2)
    80002d56:	a839                	j	80002d74 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d58:	15848613          	addi	a2,s1,344
    80002d5c:	588c                	lw	a1,48(s1)
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	6ea50513          	addi	a0,a0,1770 # 80008448 <states.0+0x150>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	822080e7          	jalr	-2014(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6e:	6cbc                	ld	a5,88(s1)
    80002d70:	577d                	li	a4,-1
    80002d72:	fbb8                	sd	a4,112(a5)
  }
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6902                	ld	s2,0(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <sys_exit>:
#include "sysinfo.h"
// #include "kalloc.c"

uint64
sys_exit(void)
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d88:	fec40593          	addi	a1,s0,-20
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	f0e080e7          	jalr	-242(ra) # 80002c9c <argint>
  exit(n);
    80002d96:	fec42503          	lw	a0,-20(s0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	456080e7          	jalr	1110(ra) # 800021f0 <exit>
  return 0;  // not reached
}
    80002da2:	4501                	li	a0,0
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dac:	1141                	addi	sp,sp,-16
    80002dae:	e406                	sd	ra,8(sp)
    80002db0:	e022                	sd	s0,0(sp)
    80002db2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	c54080e7          	jalr	-940(ra) # 80001a08 <myproc>
}
    80002dbc:	5908                	lw	a0,48(a0)
    80002dbe:	60a2                	ld	ra,8(sp)
    80002dc0:	6402                	ld	s0,0(sp)
    80002dc2:	0141                	addi	sp,sp,16
    80002dc4:	8082                	ret

0000000080002dc6 <sys_fork>:

uint64
sys_fork(void)
{
    80002dc6:	1141                	addi	sp,sp,-16
    80002dc8:	e406                	sd	ra,8(sp)
    80002dca:	e022                	sd	s0,0(sp)
    80002dcc:	0800                	addi	s0,sp,16
  return fork();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	ffc080e7          	jalr	-4(ra) # 80001dca <fork>
}
    80002dd6:	60a2                	ld	ra,8(sp)
    80002dd8:	6402                	ld	s0,0(sp)
    80002dda:	0141                	addi	sp,sp,16
    80002ddc:	8082                	ret

0000000080002dde <sys_wait>:

uint64
sys_wait(void)
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002de6:	fe840593          	addi	a1,s0,-24
    80002dea:	4501                	li	a0,0
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	ed0080e7          	jalr	-304(ra) # 80002cbc <argaddr>
  return wait(p);
    80002df4:	fe843503          	ld	a0,-24(s0)
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	59e080e7          	jalr	1438(ra) # 80002396 <wait>
}
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e08:	7179                	addi	sp,sp,-48
    80002e0a:	f406                	sd	ra,40(sp)
    80002e0c:	f022                	sd	s0,32(sp)
    80002e0e:	ec26                	sd	s1,24(sp)
    80002e10:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e12:	fdc40593          	addi	a1,s0,-36
    80002e16:	4501                	li	a0,0
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	e84080e7          	jalr	-380(ra) # 80002c9c <argint>
  addr = myproc()->sz;
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	be8080e7          	jalr	-1048(ra) # 80001a08 <myproc>
    80002e28:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e2a:	fdc42503          	lw	a0,-36(s0)
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	f40080e7          	jalr	-192(ra) # 80001d6e <growproc>
    80002e36:	00054863          	bltz	a0,80002e46 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	70a2                	ld	ra,40(sp)
    80002e3e:	7402                	ld	s0,32(sp)
    80002e40:	64e2                	ld	s1,24(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret
    return -1;
    80002e46:	54fd                	li	s1,-1
    80002e48:	bfcd                	j	80002e3a <sys_sbrk+0x32>

0000000080002e4a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e4a:	7139                	addi	sp,sp,-64
    80002e4c:	fc06                	sd	ra,56(sp)
    80002e4e:	f822                	sd	s0,48(sp)
    80002e50:	f426                	sd	s1,40(sp)
    80002e52:	f04a                	sd	s2,32(sp)
    80002e54:	ec4e                	sd	s3,24(sp)
    80002e56:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e58:	fcc40593          	addi	a1,s0,-52
    80002e5c:	4501                	li	a0,0
    80002e5e:	00000097          	auipc	ra,0x0
    80002e62:	e3e080e7          	jalr	-450(ra) # 80002c9c <argint>
  acquire(&tickslock);
    80002e66:	00014517          	auipc	a0,0x14
    80002e6a:	d4a50513          	addi	a0,a0,-694 # 80016bb0 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	dc4080e7          	jalr	-572(ra) # 80000c32 <acquire>
  ticks0 = ticks;
    80002e76:	00006917          	auipc	s2,0x6
    80002e7a:	a9a92903          	lw	s2,-1382(s2) # 80008910 <ticks>
  while(ticks - ticks0 < n){
    80002e7e:	fcc42783          	lw	a5,-52(s0)
    80002e82:	cf9d                	beqz	a5,80002ec0 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e84:	00014997          	auipc	s3,0x14
    80002e88:	d2c98993          	addi	s3,s3,-724 # 80016bb0 <tickslock>
    80002e8c:	00006497          	auipc	s1,0x6
    80002e90:	a8448493          	addi	s1,s1,-1404 # 80008910 <ticks>
    if(killed(myproc())){
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	b74080e7          	jalr	-1164(ra) # 80001a08 <myproc>
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	4c8080e7          	jalr	1224(ra) # 80002364 <killed>
    80002ea4:	ed15                	bnez	a0,80002ee0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ea6:	85ce                	mv	a1,s3
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	212080e7          	jalr	530(ra) # 800020bc <sleep>
  while(ticks - ticks0 < n){
    80002eb2:	409c                	lw	a5,0(s1)
    80002eb4:	412787bb          	subw	a5,a5,s2
    80002eb8:	fcc42703          	lw	a4,-52(s0)
    80002ebc:	fce7ece3          	bltu	a5,a4,80002e94 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	cf050513          	addi	a0,a0,-784 # 80016bb0 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	e1e080e7          	jalr	-482(ra) # 80000ce6 <release>
  return 0;
    80002ed0:	4501                	li	a0,0
}
    80002ed2:	70e2                	ld	ra,56(sp)
    80002ed4:	7442                	ld	s0,48(sp)
    80002ed6:	74a2                	ld	s1,40(sp)
    80002ed8:	7902                	ld	s2,32(sp)
    80002eda:	69e2                	ld	s3,24(sp)
    80002edc:	6121                	addi	sp,sp,64
    80002ede:	8082                	ret
      release(&tickslock);
    80002ee0:	00014517          	auipc	a0,0x14
    80002ee4:	cd050513          	addi	a0,a0,-816 # 80016bb0 <tickslock>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	dfe080e7          	jalr	-514(ra) # 80000ce6 <release>
      return -1;
    80002ef0:	557d                	li	a0,-1
    80002ef2:	b7c5                	j	80002ed2 <sys_sleep+0x88>

0000000080002ef4 <sys_kill>:

uint64
sys_kill(void)
{ 
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002efc:	fec40593          	addi	a1,s0,-20
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	d9a080e7          	jalr	-614(ra) # 80002c9c <argint>
  return kill(pid);
    80002f0a:	fec42503          	lw	a0,-20(s0)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	3b8080e7          	jalr	952(ra) # 800022c6 <kill>
}
    80002f16:	60e2                	ld	ra,24(sp)
    80002f18:	6442                	ld	s0,16(sp)
    80002f1a:	6105                	addi	sp,sp,32
    80002f1c:	8082                	ret

0000000080002f1e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	e426                	sd	s1,8(sp)
    80002f26:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f28:	00014517          	auipc	a0,0x14
    80002f2c:	c8850513          	addi	a0,a0,-888 # 80016bb0 <tickslock>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	d02080e7          	jalr	-766(ra) # 80000c32 <acquire>
  xticks = ticks;
    80002f38:	00006497          	auipc	s1,0x6
    80002f3c:	9d84a483          	lw	s1,-1576(s1) # 80008910 <ticks>
  release(&tickslock);
    80002f40:	00014517          	auipc	a0,0x14
    80002f44:	c7050513          	addi	a0,a0,-912 # 80016bb0 <tickslock>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d9e080e7          	jalr	-610(ra) # 80000ce6 <release>
  return xticks;
}
    80002f50:	02049513          	slli	a0,s1,0x20
    80002f54:	9101                	srli	a0,a0,0x20
    80002f56:	60e2                	ld	ra,24(sp)
    80002f58:	6442                	ld	s0,16(sp)
    80002f5a:	64a2                	ld	s1,8(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <sys_getHelloWorld>:

int 
sys_getHelloWorld(void)
{
    80002f60:	1141                	addi	sp,sp,-16
    80002f62:	e406                	sd	ra,8(sp)
    80002f64:	e022                	sd	s0,0(sp)
    80002f66:	0800                	addi	s0,sp,16
  return getHelloWorld();
    80002f68:	fffff097          	auipc	ra,0xfffff
    80002f6c:	6b6080e7          	jalr	1718(ra) # 8000261e <getHelloWorld>
}
    80002f70:	2501                	sext.w	a0,a0
    80002f72:	60a2                	ld	ra,8(sp)
    80002f74:	6402                	ld	s0,0(sp)
    80002f76:	0141                	addi	sp,sp,16
    80002f78:	8082                	ret

0000000080002f7a <sys_getProcTick>:

int
sys_getProcTick(void)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    80002f82:	fec40593          	addi	a1,s0,-20
    80002f86:	4501                	li	a0,0
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	d14080e7          	jalr	-748(ra) # 80002c9c <argint>
  return getProcTick(pid);
    80002f90:	fec42503          	lw	a0,-20(s0)
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	6ac080e7          	jalr	1708(ra) # 80002640 <getProcTick>
 // return getProcTick();
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret

0000000080002fa4 <sys_getProcInfo>:

int
sys_getProcInfo(void)
{
    80002fa4:	1141                	addi	sp,sp,-16
    80002fa6:	e406                	sd	ra,8(sp)
    80002fa8:	e022                	sd	s0,0(sp)
    80002faa:	0800                	addi	s0,sp,16
  return getProcInfo();
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	720080e7          	jalr	1824(ra) # 800026cc <getProcInfo>
}
    80002fb4:	60a2                	ld	ra,8(sp)
    80002fb6:	6402                	ld	s0,0(sp)
    80002fb8:	0141                	addi	sp,sp,16
    80002fba:	8082                	ret

0000000080002fbc <sys_sysinfo>:
//   // return 0;
// } 

uint64
sys_sysinfo(void)
{
    80002fbc:	715d                	addi	sp,sp,-80
    80002fbe:	e486                	sd	ra,72(sp)
    80002fc0:	e0a2                	sd	s0,64(sp)
    80002fc2:	fc26                	sd	s1,56(sp)
    80002fc4:	0880                	addi	s0,sp,80
  // get current process running on cpu
  struct proc *p = myproc();
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	a42080e7          	jalr	-1470(ra) # 80001a08 <myproc>
    80002fce:	84aa                	mv	s1,a0
  struct sysinfo info;
  // user space pointer to struct sysinfo
  uint64 pinfo;

  // get user space pointer
  argaddr(0, &pinfo);
    80002fd0:	fb840593          	addi	a1,s0,-72
    80002fd4:	4501                	li	a0,0
    80002fd6:	00000097          	auipc	ra,0x0
    80002fda:	ce6080e7          	jalr	-794(ra) # 80002cbc <argaddr>
  // printf("Virt Addr: %p\n", pinfo);
  // if (argaddr(0, &pinfo) < 0)
  //   return -1;

  // get sysinfo
  info.freemem = nfreemem();
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	b68080e7          	jalr	-1176(ra) # 80000b46 <nfreemem>
    80002fe6:	fca43823          	sd	a0,-48(s0)
  info.nproc = nproc();
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	738080e7          	jalr	1848(ra) # 80002722 <nproc>
    80002ff2:	fca43c23          	sd	a0,-40(s0)
  info.uptime = getTicks();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	784080e7          	jalr	1924(ra) # 8000277a <getTicks>
    80002ffe:	c22517d3          	fcvt.l.d	a5,fa0,rtz
    80003002:	fcf43023          	sd	a5,-64(s0)
  info.totalram = getTotalRam();
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	b8c080e7          	jalr	-1140(ra) # 80000b92 <getTotalRam>
    8000300e:	fca43423          	sd	a0,-56(s0)

  
  
  // copy sysinfo from kernel to user
  if (copyout(p->pagetable, pinfo, (char *)&info, sizeof(struct sysinfo)) < 0)
    80003012:	02000693          	li	a3,32
    80003016:	fc040613          	addi	a2,s0,-64
    8000301a:	fb843583          	ld	a1,-72(s0)
    8000301e:	68a8                	ld	a0,80(s1)
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	6a4080e7          	jalr	1700(ra) # 800016c4 <copyout>
    return -1;

  return 0;
    80003028:	957d                	srai	a0,a0,0x3f
    8000302a:	60a6                	ld	ra,72(sp)
    8000302c:	6406                	ld	s0,64(sp)
    8000302e:	74e2                	ld	s1,56(sp)
    80003030:	6161                	addi	sp,sp,80
    80003032:	8082                	ret

0000000080003034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003034:	7179                	addi	sp,sp,-48
    80003036:	f406                	sd	ra,40(sp)
    80003038:	f022                	sd	s0,32(sp)
    8000303a:	ec26                	sd	s1,24(sp)
    8000303c:	e84a                	sd	s2,16(sp)
    8000303e:	e44e                	sd	s3,8(sp)
    80003040:	e052                	sd	s4,0(sp)
    80003042:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003044:	00005597          	auipc	a1,0x5
    80003048:	50c58593          	addi	a1,a1,1292 # 80008550 <syscalls+0xd0>
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	b7c50513          	addi	a0,a0,-1156 # 80016bc8 <bcache>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b4e080e7          	jalr	-1202(ra) # 80000ba2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000305c:	0001c797          	auipc	a5,0x1c
    80003060:	b6c78793          	addi	a5,a5,-1172 # 8001ebc8 <bcache+0x8000>
    80003064:	0001c717          	auipc	a4,0x1c
    80003068:	dcc70713          	addi	a4,a4,-564 # 8001ee30 <bcache+0x8268>
    8000306c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003070:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003074:	00014497          	auipc	s1,0x14
    80003078:	b6c48493          	addi	s1,s1,-1172 # 80016be0 <bcache+0x18>
    b->next = bcache.head.next;
    8000307c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000307e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003080:	00005a17          	auipc	s4,0x5
    80003084:	4d8a0a13          	addi	s4,s4,1240 # 80008558 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003088:	2b893783          	ld	a5,696(s2)
    8000308c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000308e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003092:	85d2                	mv	a1,s4
    80003094:	01048513          	addi	a0,s1,16
    80003098:	00001097          	auipc	ra,0x1
    8000309c:	4c4080e7          	jalr	1220(ra) # 8000455c <initsleeplock>
    bcache.head.next->prev = b;
    800030a0:	2b893783          	ld	a5,696(s2)
    800030a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030aa:	45848493          	addi	s1,s1,1112
    800030ae:	fd349de3          	bne	s1,s3,80003088 <binit+0x54>
  }
}
    800030b2:	70a2                	ld	ra,40(sp)
    800030b4:	7402                	ld	s0,32(sp)
    800030b6:	64e2                	ld	s1,24(sp)
    800030b8:	6942                	ld	s2,16(sp)
    800030ba:	69a2                	ld	s3,8(sp)
    800030bc:	6a02                	ld	s4,0(sp)
    800030be:	6145                	addi	sp,sp,48
    800030c0:	8082                	ret

00000000800030c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030c2:	7179                	addi	sp,sp,-48
    800030c4:	f406                	sd	ra,40(sp)
    800030c6:	f022                	sd	s0,32(sp)
    800030c8:	ec26                	sd	s1,24(sp)
    800030ca:	e84a                	sd	s2,16(sp)
    800030cc:	e44e                	sd	s3,8(sp)
    800030ce:	1800                	addi	s0,sp,48
    800030d0:	892a                	mv	s2,a0
    800030d2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	af450513          	addi	a0,a0,-1292 # 80016bc8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	b56080e7          	jalr	-1194(ra) # 80000c32 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030e4:	0001c497          	auipc	s1,0x1c
    800030e8:	d9c4b483          	ld	s1,-612(s1) # 8001ee80 <bcache+0x82b8>
    800030ec:	0001c797          	auipc	a5,0x1c
    800030f0:	d4478793          	addi	a5,a5,-700 # 8001ee30 <bcache+0x8268>
    800030f4:	02f48f63          	beq	s1,a5,80003132 <bread+0x70>
    800030f8:	873e                	mv	a4,a5
    800030fa:	a021                	j	80003102 <bread+0x40>
    800030fc:	68a4                	ld	s1,80(s1)
    800030fe:	02e48a63          	beq	s1,a4,80003132 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003102:	449c                	lw	a5,8(s1)
    80003104:	ff279ce3          	bne	a5,s2,800030fc <bread+0x3a>
    80003108:	44dc                	lw	a5,12(s1)
    8000310a:	ff3799e3          	bne	a5,s3,800030fc <bread+0x3a>
      b->refcnt++;
    8000310e:	40bc                	lw	a5,64(s1)
    80003110:	2785                	addiw	a5,a5,1
    80003112:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	ab450513          	addi	a0,a0,-1356 # 80016bc8 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	bca080e7          	jalr	-1078(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    80003124:	01048513          	addi	a0,s1,16
    80003128:	00001097          	auipc	ra,0x1
    8000312c:	46e080e7          	jalr	1134(ra) # 80004596 <acquiresleep>
      return b;
    80003130:	a8b9                	j	8000318e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003132:	0001c497          	auipc	s1,0x1c
    80003136:	d464b483          	ld	s1,-698(s1) # 8001ee78 <bcache+0x82b0>
    8000313a:	0001c797          	auipc	a5,0x1c
    8000313e:	cf678793          	addi	a5,a5,-778 # 8001ee30 <bcache+0x8268>
    80003142:	00f48863          	beq	s1,a5,80003152 <bread+0x90>
    80003146:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	cf81                	beqz	a5,80003162 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314c:	64a4                	ld	s1,72(s1)
    8000314e:	fee49de3          	bne	s1,a4,80003148 <bread+0x86>
  panic("bget: no buffers");
    80003152:	00005517          	auipc	a0,0x5
    80003156:	40e50513          	addi	a0,a0,1038 # 80008560 <syscalls+0xe0>
    8000315a:	ffffd097          	auipc	ra,0xffffd
    8000315e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
      b->dev = dev;
    80003162:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003166:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000316a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000316e:	4785                	li	a5,1
    80003170:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	a5650513          	addi	a0,a0,-1450 # 80016bc8 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b6c080e7          	jalr	-1172(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    80003182:	01048513          	addi	a0,s1,16
    80003186:	00001097          	auipc	ra,0x1
    8000318a:	410080e7          	jalr	1040(ra) # 80004596 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000318e:	409c                	lw	a5,0(s1)
    80003190:	cb89                	beqz	a5,800031a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003192:	8526                	mv	a0,s1
    80003194:	70a2                	ld	ra,40(sp)
    80003196:	7402                	ld	s0,32(sp)
    80003198:	64e2                	ld	s1,24(sp)
    8000319a:	6942                	ld	s2,16(sp)
    8000319c:	69a2                	ld	s3,8(sp)
    8000319e:	6145                	addi	sp,sp,48
    800031a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800031a2:	4581                	li	a1,0
    800031a4:	8526                	mv	a0,s1
    800031a6:	00003097          	auipc	ra,0x3
    800031aa:	fde080e7          	jalr	-34(ra) # 80006184 <virtio_disk_rw>
    b->valid = 1;
    800031ae:	4785                	li	a5,1
    800031b0:	c09c                	sw	a5,0(s1)
  return b;
    800031b2:	b7c5                	j	80003192 <bread+0xd0>

00000000800031b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031c0:	0541                	addi	a0,a0,16
    800031c2:	00001097          	auipc	ra,0x1
    800031c6:	46e080e7          	jalr	1134(ra) # 80004630 <holdingsleep>
    800031ca:	cd01                	beqz	a0,800031e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031cc:	4585                	li	a1,1
    800031ce:	8526                	mv	a0,s1
    800031d0:	00003097          	auipc	ra,0x3
    800031d4:	fb4080e7          	jalr	-76(ra) # 80006184 <virtio_disk_rw>
}
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	64a2                	ld	s1,8(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret
    panic("bwrite");
    800031e2:	00005517          	auipc	a0,0x5
    800031e6:	39650513          	addi	a0,a0,918 # 80008578 <syscalls+0xf8>
    800031ea:	ffffd097          	auipc	ra,0xffffd
    800031ee:	354080e7          	jalr	852(ra) # 8000053e <panic>

00000000800031f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	e426                	sd	s1,8(sp)
    800031fa:	e04a                	sd	s2,0(sp)
    800031fc:	1000                	addi	s0,sp,32
    800031fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003200:	01050913          	addi	s2,a0,16
    80003204:	854a                	mv	a0,s2
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	42a080e7          	jalr	1066(ra) # 80004630 <holdingsleep>
    8000320e:	c92d                	beqz	a0,80003280 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003210:	854a                	mv	a0,s2
    80003212:	00001097          	auipc	ra,0x1
    80003216:	3da080e7          	jalr	986(ra) # 800045ec <releasesleep>

  acquire(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	9ae50513          	addi	a0,a0,-1618 # 80016bc8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	a10080e7          	jalr	-1520(ra) # 80000c32 <acquire>
  b->refcnt--;
    8000322a:	40bc                	lw	a5,64(s1)
    8000322c:	37fd                	addiw	a5,a5,-1
    8000322e:	0007871b          	sext.w	a4,a5
    80003232:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003234:	eb05                	bnez	a4,80003264 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003236:	68bc                	ld	a5,80(s1)
    80003238:	64b8                	ld	a4,72(s1)
    8000323a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000323c:	64bc                	ld	a5,72(s1)
    8000323e:	68b8                	ld	a4,80(s1)
    80003240:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003242:	0001c797          	auipc	a5,0x1c
    80003246:	98678793          	addi	a5,a5,-1658 # 8001ebc8 <bcache+0x8000>
    8000324a:	2b87b703          	ld	a4,696(a5)
    8000324e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003250:	0001c717          	auipc	a4,0x1c
    80003254:	be070713          	addi	a4,a4,-1056 # 8001ee30 <bcache+0x8268>
    80003258:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000325a:	2b87b703          	ld	a4,696(a5)
    8000325e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003260:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003264:	00014517          	auipc	a0,0x14
    80003268:	96450513          	addi	a0,a0,-1692 # 80016bc8 <bcache>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	a7a080e7          	jalr	-1414(ra) # 80000ce6 <release>
}
    80003274:	60e2                	ld	ra,24(sp)
    80003276:	6442                	ld	s0,16(sp)
    80003278:	64a2                	ld	s1,8(sp)
    8000327a:	6902                	ld	s2,0(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret
    panic("brelse");
    80003280:	00005517          	auipc	a0,0x5
    80003284:	30050513          	addi	a0,a0,768 # 80008580 <syscalls+0x100>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2b6080e7          	jalr	694(ra) # 8000053e <panic>

0000000080003290 <bpin>:

void
bpin(struct buf *b) {
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	1000                	addi	s0,sp,32
    8000329a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329c:	00014517          	auipc	a0,0x14
    800032a0:	92c50513          	addi	a0,a0,-1748 # 80016bc8 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	98e080e7          	jalr	-1650(ra) # 80000c32 <acquire>
  b->refcnt++;
    800032ac:	40bc                	lw	a5,64(s1)
    800032ae:	2785                	addiw	a5,a5,1
    800032b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	91650513          	addi	a0,a0,-1770 # 80016bc8 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	a2c080e7          	jalr	-1492(ra) # 80000ce6 <release>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <bunpin>:

void
bunpin(struct buf *b) {
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	1000                	addi	s0,sp,32
    800032d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d8:	00014517          	auipc	a0,0x14
    800032dc:	8f050513          	addi	a0,a0,-1808 # 80016bc8 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	952080e7          	jalr	-1710(ra) # 80000c32 <acquire>
  b->refcnt--;
    800032e8:	40bc                	lw	a5,64(s1)
    800032ea:	37fd                	addiw	a5,a5,-1
    800032ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ee:	00014517          	auipc	a0,0x14
    800032f2:	8da50513          	addi	a0,a0,-1830 # 80016bc8 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	9f0080e7          	jalr	-1552(ra) # 80000ce6 <release>
}
    800032fe:	60e2                	ld	ra,24(sp)
    80003300:	6442                	ld	s0,16(sp)
    80003302:	64a2                	ld	s1,8(sp)
    80003304:	6105                	addi	sp,sp,32
    80003306:	8082                	ret

0000000080003308 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	e426                	sd	s1,8(sp)
    80003310:	e04a                	sd	s2,0(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003316:	00d5d59b          	srliw	a1,a1,0xd
    8000331a:	0001c797          	auipc	a5,0x1c
    8000331e:	f8a7a783          	lw	a5,-118(a5) # 8001f2a4 <sb+0x1c>
    80003322:	9dbd                	addw	a1,a1,a5
    80003324:	00000097          	auipc	ra,0x0
    80003328:	d9e080e7          	jalr	-610(ra) # 800030c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000332c:	0074f713          	andi	a4,s1,7
    80003330:	4785                	li	a5,1
    80003332:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003336:	14ce                	slli	s1,s1,0x33
    80003338:	90d9                	srli	s1,s1,0x36
    8000333a:	00950733          	add	a4,a0,s1
    8000333e:	05874703          	lbu	a4,88(a4)
    80003342:	00e7f6b3          	and	a3,a5,a4
    80003346:	c69d                	beqz	a3,80003374 <bfree+0x6c>
    80003348:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000334a:	94aa                	add	s1,s1,a0
    8000334c:	fff7c793          	not	a5,a5
    80003350:	8ff9                	and	a5,a5,a4
    80003352:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003356:	00001097          	auipc	ra,0x1
    8000335a:	120080e7          	jalr	288(ra) # 80004476 <log_write>
  brelse(bp);
    8000335e:	854a                	mv	a0,s2
    80003360:	00000097          	auipc	ra,0x0
    80003364:	e92080e7          	jalr	-366(ra) # 800031f2 <brelse>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6902                	ld	s2,0(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret
    panic("freeing free block");
    80003374:	00005517          	auipc	a0,0x5
    80003378:	21450513          	addi	a0,a0,532 # 80008588 <syscalls+0x108>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>

0000000080003384 <balloc>:
{
    80003384:	711d                	addi	sp,sp,-96
    80003386:	ec86                	sd	ra,88(sp)
    80003388:	e8a2                	sd	s0,80(sp)
    8000338a:	e4a6                	sd	s1,72(sp)
    8000338c:	e0ca                	sd	s2,64(sp)
    8000338e:	fc4e                	sd	s3,56(sp)
    80003390:	f852                	sd	s4,48(sp)
    80003392:	f456                	sd	s5,40(sp)
    80003394:	f05a                	sd	s6,32(sp)
    80003396:	ec5e                	sd	s7,24(sp)
    80003398:	e862                	sd	s8,16(sp)
    8000339a:	e466                	sd	s9,8(sp)
    8000339c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000339e:	0001c797          	auipc	a5,0x1c
    800033a2:	eee7a783          	lw	a5,-274(a5) # 8001f28c <sb+0x4>
    800033a6:	10078163          	beqz	a5,800034a8 <balloc+0x124>
    800033aa:	8baa                	mv	s7,a0
    800033ac:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033ae:	0001cb17          	auipc	s6,0x1c
    800033b2:	edab0b13          	addi	s6,s6,-294 # 8001f288 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033b8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ba:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033bc:	6c89                	lui	s9,0x2
    800033be:	a061                	j	80003446 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c0:	974a                	add	a4,a4,s2
    800033c2:	8fd5                	or	a5,a5,a3
    800033c4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033c8:	854a                	mv	a0,s2
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	0ac080e7          	jalr	172(ra) # 80004476 <log_write>
        brelse(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	e1e080e7          	jalr	-482(ra) # 800031f2 <brelse>
  bp = bread(dev, bno);
    800033dc:	85a6                	mv	a1,s1
    800033de:	855e                	mv	a0,s7
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	ce2080e7          	jalr	-798(ra) # 800030c2 <bread>
    800033e8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033ea:	40000613          	li	a2,1024
    800033ee:	4581                	li	a1,0
    800033f0:	05850513          	addi	a0,a0,88
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	93a080e7          	jalr	-1734(ra) # 80000d2e <memset>
  log_write(bp);
    800033fc:	854a                	mv	a0,s2
    800033fe:	00001097          	auipc	ra,0x1
    80003402:	078080e7          	jalr	120(ra) # 80004476 <log_write>
  brelse(bp);
    80003406:	854a                	mv	a0,s2
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	dea080e7          	jalr	-534(ra) # 800031f2 <brelse>
}
    80003410:	8526                	mv	a0,s1
    80003412:	60e6                	ld	ra,88(sp)
    80003414:	6446                	ld	s0,80(sp)
    80003416:	64a6                	ld	s1,72(sp)
    80003418:	6906                	ld	s2,64(sp)
    8000341a:	79e2                	ld	s3,56(sp)
    8000341c:	7a42                	ld	s4,48(sp)
    8000341e:	7aa2                	ld	s5,40(sp)
    80003420:	7b02                	ld	s6,32(sp)
    80003422:	6be2                	ld	s7,24(sp)
    80003424:	6c42                	ld	s8,16(sp)
    80003426:	6ca2                	ld	s9,8(sp)
    80003428:	6125                	addi	sp,sp,96
    8000342a:	8082                	ret
    brelse(bp);
    8000342c:	854a                	mv	a0,s2
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	dc4080e7          	jalr	-572(ra) # 800031f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003436:	015c87bb          	addw	a5,s9,s5
    8000343a:	00078a9b          	sext.w	s5,a5
    8000343e:	004b2703          	lw	a4,4(s6)
    80003442:	06eaf363          	bgeu	s5,a4,800034a8 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003446:	41fad79b          	sraiw	a5,s5,0x1f
    8000344a:	0137d79b          	srliw	a5,a5,0x13
    8000344e:	015787bb          	addw	a5,a5,s5
    80003452:	40d7d79b          	sraiw	a5,a5,0xd
    80003456:	01cb2583          	lw	a1,28(s6)
    8000345a:	9dbd                	addw	a1,a1,a5
    8000345c:	855e                	mv	a0,s7
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	c64080e7          	jalr	-924(ra) # 800030c2 <bread>
    80003466:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003468:	004b2503          	lw	a0,4(s6)
    8000346c:	000a849b          	sext.w	s1,s5
    80003470:	8662                	mv	a2,s8
    80003472:	faa4fde3          	bgeu	s1,a0,8000342c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003476:	41f6579b          	sraiw	a5,a2,0x1f
    8000347a:	01d7d69b          	srliw	a3,a5,0x1d
    8000347e:	00c6873b          	addw	a4,a3,a2
    80003482:	00777793          	andi	a5,a4,7
    80003486:	9f95                	subw	a5,a5,a3
    80003488:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000348c:	4037571b          	sraiw	a4,a4,0x3
    80003490:	00e906b3          	add	a3,s2,a4
    80003494:	0586c683          	lbu	a3,88(a3)
    80003498:	00d7f5b3          	and	a1,a5,a3
    8000349c:	d195                	beqz	a1,800033c0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349e:	2605                	addiw	a2,a2,1
    800034a0:	2485                	addiw	s1,s1,1
    800034a2:	fd4618e3          	bne	a2,s4,80003472 <balloc+0xee>
    800034a6:	b759                	j	8000342c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034a8:	00005517          	auipc	a0,0x5
    800034ac:	0f850513          	addi	a0,a0,248 # 800085a0 <syscalls+0x120>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	0d8080e7          	jalr	216(ra) # 80000588 <printf>
  return 0;
    800034b8:	4481                	li	s1,0
    800034ba:	bf99                	j	80003410 <balloc+0x8c>

00000000800034bc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034bc:	7179                	addi	sp,sp,-48
    800034be:	f406                	sd	ra,40(sp)
    800034c0:	f022                	sd	s0,32(sp)
    800034c2:	ec26                	sd	s1,24(sp)
    800034c4:	e84a                	sd	s2,16(sp)
    800034c6:	e44e                	sd	s3,8(sp)
    800034c8:	e052                	sd	s4,0(sp)
    800034ca:	1800                	addi	s0,sp,48
    800034cc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034ce:	47ad                	li	a5,11
    800034d0:	02b7e763          	bltu	a5,a1,800034fe <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034d4:	02059493          	slli	s1,a1,0x20
    800034d8:	9081                	srli	s1,s1,0x20
    800034da:	048a                	slli	s1,s1,0x2
    800034dc:	94aa                	add	s1,s1,a0
    800034de:	0504a903          	lw	s2,80(s1)
    800034e2:	06091e63          	bnez	s2,8000355e <bmap+0xa2>
      addr = balloc(ip->dev);
    800034e6:	4108                	lw	a0,0(a0)
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	e9c080e7          	jalr	-356(ra) # 80003384 <balloc>
    800034f0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034f4:	06090563          	beqz	s2,8000355e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034f8:	0524a823          	sw	s2,80(s1)
    800034fc:	a08d                	j	8000355e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034fe:	ff45849b          	addiw	s1,a1,-12
    80003502:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003506:	0ff00793          	li	a5,255
    8000350a:	08e7e563          	bltu	a5,a4,80003594 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000350e:	08052903          	lw	s2,128(a0)
    80003512:	00091d63          	bnez	s2,8000352c <bmap+0x70>
      addr = balloc(ip->dev);
    80003516:	4108                	lw	a0,0(a0)
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	e6c080e7          	jalr	-404(ra) # 80003384 <balloc>
    80003520:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003524:	02090d63          	beqz	s2,8000355e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003528:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000352c:	85ca                	mv	a1,s2
    8000352e:	0009a503          	lw	a0,0(s3)
    80003532:	00000097          	auipc	ra,0x0
    80003536:	b90080e7          	jalr	-1136(ra) # 800030c2 <bread>
    8000353a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000353c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003540:	02049593          	slli	a1,s1,0x20
    80003544:	9181                	srli	a1,a1,0x20
    80003546:	058a                	slli	a1,a1,0x2
    80003548:	00b784b3          	add	s1,a5,a1
    8000354c:	0004a903          	lw	s2,0(s1)
    80003550:	02090063          	beqz	s2,80003570 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003554:	8552                	mv	a0,s4
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	c9c080e7          	jalr	-868(ra) # 800031f2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000355e:	854a                	mv	a0,s2
    80003560:	70a2                	ld	ra,40(sp)
    80003562:	7402                	ld	s0,32(sp)
    80003564:	64e2                	ld	s1,24(sp)
    80003566:	6942                	ld	s2,16(sp)
    80003568:	69a2                	ld	s3,8(sp)
    8000356a:	6a02                	ld	s4,0(sp)
    8000356c:	6145                	addi	sp,sp,48
    8000356e:	8082                	ret
      addr = balloc(ip->dev);
    80003570:	0009a503          	lw	a0,0(s3)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	e10080e7          	jalr	-496(ra) # 80003384 <balloc>
    8000357c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003580:	fc090ae3          	beqz	s2,80003554 <bmap+0x98>
        a[bn] = addr;
    80003584:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003588:	8552                	mv	a0,s4
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	eec080e7          	jalr	-276(ra) # 80004476 <log_write>
    80003592:	b7c9                	j	80003554 <bmap+0x98>
  panic("bmap: out of range");
    80003594:	00005517          	auipc	a0,0x5
    80003598:	02450513          	addi	a0,a0,36 # 800085b8 <syscalls+0x138>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>

00000000800035a4 <iget>:
{
    800035a4:	7179                	addi	sp,sp,-48
    800035a6:	f406                	sd	ra,40(sp)
    800035a8:	f022                	sd	s0,32(sp)
    800035aa:	ec26                	sd	s1,24(sp)
    800035ac:	e84a                	sd	s2,16(sp)
    800035ae:	e44e                	sd	s3,8(sp)
    800035b0:	e052                	sd	s4,0(sp)
    800035b2:	1800                	addi	s0,sp,48
    800035b4:	89aa                	mv	s3,a0
    800035b6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035b8:	0001c517          	auipc	a0,0x1c
    800035bc:	cf050513          	addi	a0,a0,-784 # 8001f2a8 <itable>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	672080e7          	jalr	1650(ra) # 80000c32 <acquire>
  empty = 0;
    800035c8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ca:	0001c497          	auipc	s1,0x1c
    800035ce:	cf648493          	addi	s1,s1,-778 # 8001f2c0 <itable+0x18>
    800035d2:	0001d697          	auipc	a3,0x1d
    800035d6:	77e68693          	addi	a3,a3,1918 # 80020d50 <log>
    800035da:	a039                	j	800035e8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035dc:	02090b63          	beqz	s2,80003612 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e0:	08848493          	addi	s1,s1,136
    800035e4:	02d48a63          	beq	s1,a3,80003618 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035e8:	449c                	lw	a5,8(s1)
    800035ea:	fef059e3          	blez	a5,800035dc <iget+0x38>
    800035ee:	4098                	lw	a4,0(s1)
    800035f0:	ff3716e3          	bne	a4,s3,800035dc <iget+0x38>
    800035f4:	40d8                	lw	a4,4(s1)
    800035f6:	ff4713e3          	bne	a4,s4,800035dc <iget+0x38>
      ip->ref++;
    800035fa:	2785                	addiw	a5,a5,1
    800035fc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035fe:	0001c517          	auipc	a0,0x1c
    80003602:	caa50513          	addi	a0,a0,-854 # 8001f2a8 <itable>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	6e0080e7          	jalr	1760(ra) # 80000ce6 <release>
      return ip;
    8000360e:	8926                	mv	s2,s1
    80003610:	a03d                	j	8000363e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003612:	f7f9                	bnez	a5,800035e0 <iget+0x3c>
    80003614:	8926                	mv	s2,s1
    80003616:	b7e9                	j	800035e0 <iget+0x3c>
  if(empty == 0)
    80003618:	02090c63          	beqz	s2,80003650 <iget+0xac>
  ip->dev = dev;
    8000361c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003620:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003624:	4785                	li	a5,1
    80003626:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000362a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000362e:	0001c517          	auipc	a0,0x1c
    80003632:	c7a50513          	addi	a0,a0,-902 # 8001f2a8 <itable>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	6b0080e7          	jalr	1712(ra) # 80000ce6 <release>
}
    8000363e:	854a                	mv	a0,s2
    80003640:	70a2                	ld	ra,40(sp)
    80003642:	7402                	ld	s0,32(sp)
    80003644:	64e2                	ld	s1,24(sp)
    80003646:	6942                	ld	s2,16(sp)
    80003648:	69a2                	ld	s3,8(sp)
    8000364a:	6a02                	ld	s4,0(sp)
    8000364c:	6145                	addi	sp,sp,48
    8000364e:	8082                	ret
    panic("iget: no inodes");
    80003650:	00005517          	auipc	a0,0x5
    80003654:	f8050513          	addi	a0,a0,-128 # 800085d0 <syscalls+0x150>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	ee6080e7          	jalr	-282(ra) # 8000053e <panic>

0000000080003660 <fsinit>:
fsinit(int dev) {
    80003660:	7179                	addi	sp,sp,-48
    80003662:	f406                	sd	ra,40(sp)
    80003664:	f022                	sd	s0,32(sp)
    80003666:	ec26                	sd	s1,24(sp)
    80003668:	e84a                	sd	s2,16(sp)
    8000366a:	e44e                	sd	s3,8(sp)
    8000366c:	1800                	addi	s0,sp,48
    8000366e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003670:	4585                	li	a1,1
    80003672:	00000097          	auipc	ra,0x0
    80003676:	a50080e7          	jalr	-1456(ra) # 800030c2 <bread>
    8000367a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000367c:	0001c997          	auipc	s3,0x1c
    80003680:	c0c98993          	addi	s3,s3,-1012 # 8001f288 <sb>
    80003684:	02000613          	li	a2,32
    80003688:	05850593          	addi	a1,a0,88
    8000368c:	854e                	mv	a0,s3
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	6fc080e7          	jalr	1788(ra) # 80000d8a <memmove>
  brelse(bp);
    80003696:	8526                	mv	a0,s1
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	b5a080e7          	jalr	-1190(ra) # 800031f2 <brelse>
  if(sb.magic != FSMAGIC)
    800036a0:	0009a703          	lw	a4,0(s3)
    800036a4:	102037b7          	lui	a5,0x10203
    800036a8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036ac:	02f71263          	bne	a4,a5,800036d0 <fsinit+0x70>
  initlog(dev, &sb);
    800036b0:	0001c597          	auipc	a1,0x1c
    800036b4:	bd858593          	addi	a1,a1,-1064 # 8001f288 <sb>
    800036b8:	854a                	mv	a0,s2
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	b40080e7          	jalr	-1216(ra) # 800041fa <initlog>
}
    800036c2:	70a2                	ld	ra,40(sp)
    800036c4:	7402                	ld	s0,32(sp)
    800036c6:	64e2                	ld	s1,24(sp)
    800036c8:	6942                	ld	s2,16(sp)
    800036ca:	69a2                	ld	s3,8(sp)
    800036cc:	6145                	addi	sp,sp,48
    800036ce:	8082                	ret
    panic("invalid file system");
    800036d0:	00005517          	auipc	a0,0x5
    800036d4:	f1050513          	addi	a0,a0,-240 # 800085e0 <syscalls+0x160>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	e66080e7          	jalr	-410(ra) # 8000053e <panic>

00000000800036e0 <iinit>:
{
    800036e0:	7179                	addi	sp,sp,-48
    800036e2:	f406                	sd	ra,40(sp)
    800036e4:	f022                	sd	s0,32(sp)
    800036e6:	ec26                	sd	s1,24(sp)
    800036e8:	e84a                	sd	s2,16(sp)
    800036ea:	e44e                	sd	s3,8(sp)
    800036ec:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036ee:	00005597          	auipc	a1,0x5
    800036f2:	f0a58593          	addi	a1,a1,-246 # 800085f8 <syscalls+0x178>
    800036f6:	0001c517          	auipc	a0,0x1c
    800036fa:	bb250513          	addi	a0,a0,-1102 # 8001f2a8 <itable>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	4a4080e7          	jalr	1188(ra) # 80000ba2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003706:	0001c497          	auipc	s1,0x1c
    8000370a:	bca48493          	addi	s1,s1,-1078 # 8001f2d0 <itable+0x28>
    8000370e:	0001d997          	auipc	s3,0x1d
    80003712:	65298993          	addi	s3,s3,1618 # 80020d60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003716:	00005917          	auipc	s2,0x5
    8000371a:	eea90913          	addi	s2,s2,-278 # 80008600 <syscalls+0x180>
    8000371e:	85ca                	mv	a1,s2
    80003720:	8526                	mv	a0,s1
    80003722:	00001097          	auipc	ra,0x1
    80003726:	e3a080e7          	jalr	-454(ra) # 8000455c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000372a:	08848493          	addi	s1,s1,136
    8000372e:	ff3498e3          	bne	s1,s3,8000371e <iinit+0x3e>
}
    80003732:	70a2                	ld	ra,40(sp)
    80003734:	7402                	ld	s0,32(sp)
    80003736:	64e2                	ld	s1,24(sp)
    80003738:	6942                	ld	s2,16(sp)
    8000373a:	69a2                	ld	s3,8(sp)
    8000373c:	6145                	addi	sp,sp,48
    8000373e:	8082                	ret

0000000080003740 <ialloc>:
{
    80003740:	715d                	addi	sp,sp,-80
    80003742:	e486                	sd	ra,72(sp)
    80003744:	e0a2                	sd	s0,64(sp)
    80003746:	fc26                	sd	s1,56(sp)
    80003748:	f84a                	sd	s2,48(sp)
    8000374a:	f44e                	sd	s3,40(sp)
    8000374c:	f052                	sd	s4,32(sp)
    8000374e:	ec56                	sd	s5,24(sp)
    80003750:	e85a                	sd	s6,16(sp)
    80003752:	e45e                	sd	s7,8(sp)
    80003754:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003756:	0001c717          	auipc	a4,0x1c
    8000375a:	b3e72703          	lw	a4,-1218(a4) # 8001f294 <sb+0xc>
    8000375e:	4785                	li	a5,1
    80003760:	04e7fa63          	bgeu	a5,a4,800037b4 <ialloc+0x74>
    80003764:	8aaa                	mv	s5,a0
    80003766:	8bae                	mv	s7,a1
    80003768:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000376a:	0001ca17          	auipc	s4,0x1c
    8000376e:	b1ea0a13          	addi	s4,s4,-1250 # 8001f288 <sb>
    80003772:	00048b1b          	sext.w	s6,s1
    80003776:	0044d793          	srli	a5,s1,0x4
    8000377a:	018a2583          	lw	a1,24(s4)
    8000377e:	9dbd                	addw	a1,a1,a5
    80003780:	8556                	mv	a0,s5
    80003782:	00000097          	auipc	ra,0x0
    80003786:	940080e7          	jalr	-1728(ra) # 800030c2 <bread>
    8000378a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000378c:	05850993          	addi	s3,a0,88
    80003790:	00f4f793          	andi	a5,s1,15
    80003794:	079a                	slli	a5,a5,0x6
    80003796:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003798:	00099783          	lh	a5,0(s3)
    8000379c:	c3a1                	beqz	a5,800037dc <ialloc+0x9c>
    brelse(bp);
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	a54080e7          	jalr	-1452(ra) # 800031f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037a6:	0485                	addi	s1,s1,1
    800037a8:	00ca2703          	lw	a4,12(s4)
    800037ac:	0004879b          	sext.w	a5,s1
    800037b0:	fce7e1e3          	bltu	a5,a4,80003772 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	e5450513          	addi	a0,a0,-428 # 80008608 <syscalls+0x188>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	dcc080e7          	jalr	-564(ra) # 80000588 <printf>
  return 0;
    800037c4:	4501                	li	a0,0
}
    800037c6:	60a6                	ld	ra,72(sp)
    800037c8:	6406                	ld	s0,64(sp)
    800037ca:	74e2                	ld	s1,56(sp)
    800037cc:	7942                	ld	s2,48(sp)
    800037ce:	79a2                	ld	s3,40(sp)
    800037d0:	7a02                	ld	s4,32(sp)
    800037d2:	6ae2                	ld	s5,24(sp)
    800037d4:	6b42                	ld	s6,16(sp)
    800037d6:	6ba2                	ld	s7,8(sp)
    800037d8:	6161                	addi	sp,sp,80
    800037da:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037dc:	04000613          	li	a2,64
    800037e0:	4581                	li	a1,0
    800037e2:	854e                	mv	a0,s3
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	54a080e7          	jalr	1354(ra) # 80000d2e <memset>
      dip->type = type;
    800037ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037f0:	854a                	mv	a0,s2
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	c84080e7          	jalr	-892(ra) # 80004476 <log_write>
      brelse(bp);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	9f6080e7          	jalr	-1546(ra) # 800031f2 <brelse>
      return iget(dev, inum);
    80003804:	85da                	mv	a1,s6
    80003806:	8556                	mv	a0,s5
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	d9c080e7          	jalr	-612(ra) # 800035a4 <iget>
    80003810:	bf5d                	j	800037c6 <ialloc+0x86>

0000000080003812 <iupdate>:
{
    80003812:	1101                	addi	sp,sp,-32
    80003814:	ec06                	sd	ra,24(sp)
    80003816:	e822                	sd	s0,16(sp)
    80003818:	e426                	sd	s1,8(sp)
    8000381a:	e04a                	sd	s2,0(sp)
    8000381c:	1000                	addi	s0,sp,32
    8000381e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003820:	415c                	lw	a5,4(a0)
    80003822:	0047d79b          	srliw	a5,a5,0x4
    80003826:	0001c597          	auipc	a1,0x1c
    8000382a:	a7a5a583          	lw	a1,-1414(a1) # 8001f2a0 <sb+0x18>
    8000382e:	9dbd                	addw	a1,a1,a5
    80003830:	4108                	lw	a0,0(a0)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	890080e7          	jalr	-1904(ra) # 800030c2 <bread>
    8000383a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383c:	05850793          	addi	a5,a0,88
    80003840:	40c8                	lw	a0,4(s1)
    80003842:	893d                	andi	a0,a0,15
    80003844:	051a                	slli	a0,a0,0x6
    80003846:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003848:	04449703          	lh	a4,68(s1)
    8000384c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003850:	04649703          	lh	a4,70(s1)
    80003854:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003858:	04849703          	lh	a4,72(s1)
    8000385c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003860:	04a49703          	lh	a4,74(s1)
    80003864:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003868:	44f8                	lw	a4,76(s1)
    8000386a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000386c:	03400613          	li	a2,52
    80003870:	05048593          	addi	a1,s1,80
    80003874:	0531                	addi	a0,a0,12
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	514080e7          	jalr	1300(ra) # 80000d8a <memmove>
  log_write(bp);
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	bf6080e7          	jalr	-1034(ra) # 80004476 <log_write>
  brelse(bp);
    80003888:	854a                	mv	a0,s2
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	968080e7          	jalr	-1688(ra) # 800031f2 <brelse>
}
    80003892:	60e2                	ld	ra,24(sp)
    80003894:	6442                	ld	s0,16(sp)
    80003896:	64a2                	ld	s1,8(sp)
    80003898:	6902                	ld	s2,0(sp)
    8000389a:	6105                	addi	sp,sp,32
    8000389c:	8082                	ret

000000008000389e <idup>:
{
    8000389e:	1101                	addi	sp,sp,-32
    800038a0:	ec06                	sd	ra,24(sp)
    800038a2:	e822                	sd	s0,16(sp)
    800038a4:	e426                	sd	s1,8(sp)
    800038a6:	1000                	addi	s0,sp,32
    800038a8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038aa:	0001c517          	auipc	a0,0x1c
    800038ae:	9fe50513          	addi	a0,a0,-1538 # 8001f2a8 <itable>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	380080e7          	jalr	896(ra) # 80000c32 <acquire>
  ip->ref++;
    800038ba:	449c                	lw	a5,8(s1)
    800038bc:	2785                	addiw	a5,a5,1
    800038be:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038c0:	0001c517          	auipc	a0,0x1c
    800038c4:	9e850513          	addi	a0,a0,-1560 # 8001f2a8 <itable>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	41e080e7          	jalr	1054(ra) # 80000ce6 <release>
}
    800038d0:	8526                	mv	a0,s1
    800038d2:	60e2                	ld	ra,24(sp)
    800038d4:	6442                	ld	s0,16(sp)
    800038d6:	64a2                	ld	s1,8(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret

00000000800038dc <ilock>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	e04a                	sd	s2,0(sp)
    800038e6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038e8:	c115                	beqz	a0,8000390c <ilock+0x30>
    800038ea:	84aa                	mv	s1,a0
    800038ec:	451c                	lw	a5,8(a0)
    800038ee:	00f05f63          	blez	a5,8000390c <ilock+0x30>
  acquiresleep(&ip->lock);
    800038f2:	0541                	addi	a0,a0,16
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	ca2080e7          	jalr	-862(ra) # 80004596 <acquiresleep>
  if(ip->valid == 0){
    800038fc:	40bc                	lw	a5,64(s1)
    800038fe:	cf99                	beqz	a5,8000391c <ilock+0x40>
}
    80003900:	60e2                	ld	ra,24(sp)
    80003902:	6442                	ld	s0,16(sp)
    80003904:	64a2                	ld	s1,8(sp)
    80003906:	6902                	ld	s2,0(sp)
    80003908:	6105                	addi	sp,sp,32
    8000390a:	8082                	ret
    panic("ilock");
    8000390c:	00005517          	auipc	a0,0x5
    80003910:	d1450513          	addi	a0,a0,-748 # 80008620 <syscalls+0x1a0>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000391c:	40dc                	lw	a5,4(s1)
    8000391e:	0047d79b          	srliw	a5,a5,0x4
    80003922:	0001c597          	auipc	a1,0x1c
    80003926:	97e5a583          	lw	a1,-1666(a1) # 8001f2a0 <sb+0x18>
    8000392a:	9dbd                	addw	a1,a1,a5
    8000392c:	4088                	lw	a0,0(s1)
    8000392e:	fffff097          	auipc	ra,0xfffff
    80003932:	794080e7          	jalr	1940(ra) # 800030c2 <bread>
    80003936:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003938:	05850593          	addi	a1,a0,88
    8000393c:	40dc                	lw	a5,4(s1)
    8000393e:	8bbd                	andi	a5,a5,15
    80003940:	079a                	slli	a5,a5,0x6
    80003942:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003944:	00059783          	lh	a5,0(a1)
    80003948:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000394c:	00259783          	lh	a5,2(a1)
    80003950:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003954:	00459783          	lh	a5,4(a1)
    80003958:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000395c:	00659783          	lh	a5,6(a1)
    80003960:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003964:	459c                	lw	a5,8(a1)
    80003966:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003968:	03400613          	li	a2,52
    8000396c:	05b1                	addi	a1,a1,12
    8000396e:	05048513          	addi	a0,s1,80
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	418080e7          	jalr	1048(ra) # 80000d8a <memmove>
    brelse(bp);
    8000397a:	854a                	mv	a0,s2
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	876080e7          	jalr	-1930(ra) # 800031f2 <brelse>
    ip->valid = 1;
    80003984:	4785                	li	a5,1
    80003986:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003988:	04449783          	lh	a5,68(s1)
    8000398c:	fbb5                	bnez	a5,80003900 <ilock+0x24>
      panic("ilock: no type");
    8000398e:	00005517          	auipc	a0,0x5
    80003992:	c9a50513          	addi	a0,a0,-870 # 80008628 <syscalls+0x1a8>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>

000000008000399e <iunlock>:
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	e426                	sd	s1,8(sp)
    800039a6:	e04a                	sd	s2,0(sp)
    800039a8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039aa:	c905                	beqz	a0,800039da <iunlock+0x3c>
    800039ac:	84aa                	mv	s1,a0
    800039ae:	01050913          	addi	s2,a0,16
    800039b2:	854a                	mv	a0,s2
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	c7c080e7          	jalr	-900(ra) # 80004630 <holdingsleep>
    800039bc:	cd19                	beqz	a0,800039da <iunlock+0x3c>
    800039be:	449c                	lw	a5,8(s1)
    800039c0:	00f05d63          	blez	a5,800039da <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	c26080e7          	jalr	-986(ra) # 800045ec <releasesleep>
}
    800039ce:	60e2                	ld	ra,24(sp)
    800039d0:	6442                	ld	s0,16(sp)
    800039d2:	64a2                	ld	s1,8(sp)
    800039d4:	6902                	ld	s2,0(sp)
    800039d6:	6105                	addi	sp,sp,32
    800039d8:	8082                	ret
    panic("iunlock");
    800039da:	00005517          	auipc	a0,0x5
    800039de:	c5e50513          	addi	a0,a0,-930 # 80008638 <syscalls+0x1b8>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	b5c080e7          	jalr	-1188(ra) # 8000053e <panic>

00000000800039ea <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ea:	7179                	addi	sp,sp,-48
    800039ec:	f406                	sd	ra,40(sp)
    800039ee:	f022                	sd	s0,32(sp)
    800039f0:	ec26                	sd	s1,24(sp)
    800039f2:	e84a                	sd	s2,16(sp)
    800039f4:	e44e                	sd	s3,8(sp)
    800039f6:	e052                	sd	s4,0(sp)
    800039f8:	1800                	addi	s0,sp,48
    800039fa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039fc:	05050493          	addi	s1,a0,80
    80003a00:	08050913          	addi	s2,a0,128
    80003a04:	a021                	j	80003a0c <itrunc+0x22>
    80003a06:	0491                	addi	s1,s1,4
    80003a08:	01248d63          	beq	s1,s2,80003a22 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a0c:	408c                	lw	a1,0(s1)
    80003a0e:	dde5                	beqz	a1,80003a06 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a10:	0009a503          	lw	a0,0(s3)
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	8f4080e7          	jalr	-1804(ra) # 80003308 <bfree>
      ip->addrs[i] = 0;
    80003a1c:	0004a023          	sw	zero,0(s1)
    80003a20:	b7dd                	j	80003a06 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a22:	0809a583          	lw	a1,128(s3)
    80003a26:	e185                	bnez	a1,80003a46 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a28:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a2c:	854e                	mv	a0,s3
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	de4080e7          	jalr	-540(ra) # 80003812 <iupdate>
}
    80003a36:	70a2                	ld	ra,40(sp)
    80003a38:	7402                	ld	s0,32(sp)
    80003a3a:	64e2                	ld	s1,24(sp)
    80003a3c:	6942                	ld	s2,16(sp)
    80003a3e:	69a2                	ld	s3,8(sp)
    80003a40:	6a02                	ld	s4,0(sp)
    80003a42:	6145                	addi	sp,sp,48
    80003a44:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a46:	0009a503          	lw	a0,0(s3)
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	678080e7          	jalr	1656(ra) # 800030c2 <bread>
    80003a52:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a54:	05850493          	addi	s1,a0,88
    80003a58:	45850913          	addi	s2,a0,1112
    80003a5c:	a021                	j	80003a64 <itrunc+0x7a>
    80003a5e:	0491                	addi	s1,s1,4
    80003a60:	01248b63          	beq	s1,s2,80003a76 <itrunc+0x8c>
      if(a[j])
    80003a64:	408c                	lw	a1,0(s1)
    80003a66:	dde5                	beqz	a1,80003a5e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a68:	0009a503          	lw	a0,0(s3)
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	89c080e7          	jalr	-1892(ra) # 80003308 <bfree>
    80003a74:	b7ed                	j	80003a5e <itrunc+0x74>
    brelse(bp);
    80003a76:	8552                	mv	a0,s4
    80003a78:	fffff097          	auipc	ra,0xfffff
    80003a7c:	77a080e7          	jalr	1914(ra) # 800031f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a80:	0809a583          	lw	a1,128(s3)
    80003a84:	0009a503          	lw	a0,0(s3)
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	880080e7          	jalr	-1920(ra) # 80003308 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a90:	0809a023          	sw	zero,128(s3)
    80003a94:	bf51                	j	80003a28 <itrunc+0x3e>

0000000080003a96 <iput>:
{
    80003a96:	1101                	addi	sp,sp,-32
    80003a98:	ec06                	sd	ra,24(sp)
    80003a9a:	e822                	sd	s0,16(sp)
    80003a9c:	e426                	sd	s1,8(sp)
    80003a9e:	e04a                	sd	s2,0(sp)
    80003aa0:	1000                	addi	s0,sp,32
    80003aa2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	80450513          	addi	a0,a0,-2044 # 8001f2a8 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	186080e7          	jalr	390(ra) # 80000c32 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab4:	4498                	lw	a4,8(s1)
    80003ab6:	4785                	li	a5,1
    80003ab8:	02f70363          	beq	a4,a5,80003ade <iput+0x48>
  ip->ref--;
    80003abc:	449c                	lw	a5,8(s1)
    80003abe:	37fd                	addiw	a5,a5,-1
    80003ac0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ac2:	0001b517          	auipc	a0,0x1b
    80003ac6:	7e650513          	addi	a0,a0,2022 # 8001f2a8 <itable>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	21c080e7          	jalr	540(ra) # 80000ce6 <release>
}
    80003ad2:	60e2                	ld	ra,24(sp)
    80003ad4:	6442                	ld	s0,16(sp)
    80003ad6:	64a2                	ld	s1,8(sp)
    80003ad8:	6902                	ld	s2,0(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ade:	40bc                	lw	a5,64(s1)
    80003ae0:	dff1                	beqz	a5,80003abc <iput+0x26>
    80003ae2:	04a49783          	lh	a5,74(s1)
    80003ae6:	fbf9                	bnez	a5,80003abc <iput+0x26>
    acquiresleep(&ip->lock);
    80003ae8:	01048913          	addi	s2,s1,16
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	aa8080e7          	jalr	-1368(ra) # 80004596 <acquiresleep>
    release(&itable.lock);
    80003af6:	0001b517          	auipc	a0,0x1b
    80003afa:	7b250513          	addi	a0,a0,1970 # 8001f2a8 <itable>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	1e8080e7          	jalr	488(ra) # 80000ce6 <release>
    itrunc(ip);
    80003b06:	8526                	mv	a0,s1
    80003b08:	00000097          	auipc	ra,0x0
    80003b0c:	ee2080e7          	jalr	-286(ra) # 800039ea <itrunc>
    ip->type = 0;
    80003b10:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b14:	8526                	mv	a0,s1
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	cfc080e7          	jalr	-772(ra) # 80003812 <iupdate>
    ip->valid = 0;
    80003b1e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	ac8080e7          	jalr	-1336(ra) # 800045ec <releasesleep>
    acquire(&itable.lock);
    80003b2c:	0001b517          	auipc	a0,0x1b
    80003b30:	77c50513          	addi	a0,a0,1916 # 8001f2a8 <itable>
    80003b34:	ffffd097          	auipc	ra,0xffffd
    80003b38:	0fe080e7          	jalr	254(ra) # 80000c32 <acquire>
    80003b3c:	b741                	j	80003abc <iput+0x26>

0000000080003b3e <iunlockput>:
{
    80003b3e:	1101                	addi	sp,sp,-32
    80003b40:	ec06                	sd	ra,24(sp)
    80003b42:	e822                	sd	s0,16(sp)
    80003b44:	e426                	sd	s1,8(sp)
    80003b46:	1000                	addi	s0,sp,32
    80003b48:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	e54080e7          	jalr	-428(ra) # 8000399e <iunlock>
  iput(ip);
    80003b52:	8526                	mv	a0,s1
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	f42080e7          	jalr	-190(ra) # 80003a96 <iput>
}
    80003b5c:	60e2                	ld	ra,24(sp)
    80003b5e:	6442                	ld	s0,16(sp)
    80003b60:	64a2                	ld	s1,8(sp)
    80003b62:	6105                	addi	sp,sp,32
    80003b64:	8082                	ret

0000000080003b66 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b66:	1141                	addi	sp,sp,-16
    80003b68:	e422                	sd	s0,8(sp)
    80003b6a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b6c:	411c                	lw	a5,0(a0)
    80003b6e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b70:	415c                	lw	a5,4(a0)
    80003b72:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b74:	04451783          	lh	a5,68(a0)
    80003b78:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b7c:	04a51783          	lh	a5,74(a0)
    80003b80:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b84:	04c56783          	lwu	a5,76(a0)
    80003b88:	e99c                	sd	a5,16(a1)
}
    80003b8a:	6422                	ld	s0,8(sp)
    80003b8c:	0141                	addi	sp,sp,16
    80003b8e:	8082                	ret

0000000080003b90 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b90:	457c                	lw	a5,76(a0)
    80003b92:	0ed7e963          	bltu	a5,a3,80003c84 <readi+0xf4>
{
    80003b96:	7159                	addi	sp,sp,-112
    80003b98:	f486                	sd	ra,104(sp)
    80003b9a:	f0a2                	sd	s0,96(sp)
    80003b9c:	eca6                	sd	s1,88(sp)
    80003b9e:	e8ca                	sd	s2,80(sp)
    80003ba0:	e4ce                	sd	s3,72(sp)
    80003ba2:	e0d2                	sd	s4,64(sp)
    80003ba4:	fc56                	sd	s5,56(sp)
    80003ba6:	f85a                	sd	s6,48(sp)
    80003ba8:	f45e                	sd	s7,40(sp)
    80003baa:	f062                	sd	s8,32(sp)
    80003bac:	ec66                	sd	s9,24(sp)
    80003bae:	e86a                	sd	s10,16(sp)
    80003bb0:	e46e                	sd	s11,8(sp)
    80003bb2:	1880                	addi	s0,sp,112
    80003bb4:	8b2a                	mv	s6,a0
    80003bb6:	8bae                	mv	s7,a1
    80003bb8:	8a32                	mv	s4,a2
    80003bba:	84b6                	mv	s1,a3
    80003bbc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bbe:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bc2:	0ad76063          	bltu	a4,a3,80003c62 <readi+0xd2>
  if(off + n > ip->size)
    80003bc6:	00e7f463          	bgeu	a5,a4,80003bce <readi+0x3e>
    n = ip->size - off;
    80003bca:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bce:	0a0a8963          	beqz	s5,80003c80 <readi+0xf0>
    80003bd2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bd8:	5c7d                	li	s8,-1
    80003bda:	a82d                	j	80003c14 <readi+0x84>
    80003bdc:	020d1d93          	slli	s11,s10,0x20
    80003be0:	020ddd93          	srli	s11,s11,0x20
    80003be4:	05890793          	addi	a5,s2,88
    80003be8:	86ee                	mv	a3,s11
    80003bea:	963e                	add	a2,a2,a5
    80003bec:	85d2                	mv	a1,s4
    80003bee:	855e                	mv	a0,s7
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	8d4080e7          	jalr	-1836(ra) # 800024c4 <either_copyout>
    80003bf8:	05850d63          	beq	a0,s8,80003c52 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	5f4080e7          	jalr	1524(ra) # 800031f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c06:	013d09bb          	addw	s3,s10,s3
    80003c0a:	009d04bb          	addw	s1,s10,s1
    80003c0e:	9a6e                	add	s4,s4,s11
    80003c10:	0559f763          	bgeu	s3,s5,80003c5e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c14:	00a4d59b          	srliw	a1,s1,0xa
    80003c18:	855a                	mv	a0,s6
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	8a2080e7          	jalr	-1886(ra) # 800034bc <bmap>
    80003c22:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c26:	cd85                	beqz	a1,80003c5e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c28:	000b2503          	lw	a0,0(s6)
    80003c2c:	fffff097          	auipc	ra,0xfffff
    80003c30:	496080e7          	jalr	1174(ra) # 800030c2 <bread>
    80003c34:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c36:	3ff4f613          	andi	a2,s1,1023
    80003c3a:	40cc87bb          	subw	a5,s9,a2
    80003c3e:	413a873b          	subw	a4,s5,s3
    80003c42:	8d3e                	mv	s10,a5
    80003c44:	2781                	sext.w	a5,a5
    80003c46:	0007069b          	sext.w	a3,a4
    80003c4a:	f8f6f9e3          	bgeu	a3,a5,80003bdc <readi+0x4c>
    80003c4e:	8d3a                	mv	s10,a4
    80003c50:	b771                	j	80003bdc <readi+0x4c>
      brelse(bp);
    80003c52:	854a                	mv	a0,s2
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	59e080e7          	jalr	1438(ra) # 800031f2 <brelse>
      tot = -1;
    80003c5c:	59fd                	li	s3,-1
  }
  return tot;
    80003c5e:	0009851b          	sext.w	a0,s3
}
    80003c62:	70a6                	ld	ra,104(sp)
    80003c64:	7406                	ld	s0,96(sp)
    80003c66:	64e6                	ld	s1,88(sp)
    80003c68:	6946                	ld	s2,80(sp)
    80003c6a:	69a6                	ld	s3,72(sp)
    80003c6c:	6a06                	ld	s4,64(sp)
    80003c6e:	7ae2                	ld	s5,56(sp)
    80003c70:	7b42                	ld	s6,48(sp)
    80003c72:	7ba2                	ld	s7,40(sp)
    80003c74:	7c02                	ld	s8,32(sp)
    80003c76:	6ce2                	ld	s9,24(sp)
    80003c78:	6d42                	ld	s10,16(sp)
    80003c7a:	6da2                	ld	s11,8(sp)
    80003c7c:	6165                	addi	sp,sp,112
    80003c7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c80:	89d6                	mv	s3,s5
    80003c82:	bff1                	j	80003c5e <readi+0xce>
    return 0;
    80003c84:	4501                	li	a0,0
}
    80003c86:	8082                	ret

0000000080003c88 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c88:	457c                	lw	a5,76(a0)
    80003c8a:	10d7e863          	bltu	a5,a3,80003d9a <writei+0x112>
{
    80003c8e:	7159                	addi	sp,sp,-112
    80003c90:	f486                	sd	ra,104(sp)
    80003c92:	f0a2                	sd	s0,96(sp)
    80003c94:	eca6                	sd	s1,88(sp)
    80003c96:	e8ca                	sd	s2,80(sp)
    80003c98:	e4ce                	sd	s3,72(sp)
    80003c9a:	e0d2                	sd	s4,64(sp)
    80003c9c:	fc56                	sd	s5,56(sp)
    80003c9e:	f85a                	sd	s6,48(sp)
    80003ca0:	f45e                	sd	s7,40(sp)
    80003ca2:	f062                	sd	s8,32(sp)
    80003ca4:	ec66                	sd	s9,24(sp)
    80003ca6:	e86a                	sd	s10,16(sp)
    80003ca8:	e46e                	sd	s11,8(sp)
    80003caa:	1880                	addi	s0,sp,112
    80003cac:	8aaa                	mv	s5,a0
    80003cae:	8bae                	mv	s7,a1
    80003cb0:	8a32                	mv	s4,a2
    80003cb2:	8936                	mv	s2,a3
    80003cb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cb6:	00e687bb          	addw	a5,a3,a4
    80003cba:	0ed7e263          	bltu	a5,a3,80003d9e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cbe:	00043737          	lui	a4,0x43
    80003cc2:	0ef76063          	bltu	a4,a5,80003da2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc6:	0c0b0863          	beqz	s6,80003d96 <writei+0x10e>
    80003cca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ccc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd0:	5c7d                	li	s8,-1
    80003cd2:	a091                	j	80003d16 <writei+0x8e>
    80003cd4:	020d1d93          	slli	s11,s10,0x20
    80003cd8:	020ddd93          	srli	s11,s11,0x20
    80003cdc:	05848793          	addi	a5,s1,88
    80003ce0:	86ee                	mv	a3,s11
    80003ce2:	8652                	mv	a2,s4
    80003ce4:	85de                	mv	a1,s7
    80003ce6:	953e                	add	a0,a0,a5
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	832080e7          	jalr	-1998(ra) # 8000251a <either_copyin>
    80003cf0:	07850263          	beq	a0,s8,80003d54 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cf4:	8526                	mv	a0,s1
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	780080e7          	jalr	1920(ra) # 80004476 <log_write>
    brelse(bp);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	4f2080e7          	jalr	1266(ra) # 800031f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d08:	013d09bb          	addw	s3,s10,s3
    80003d0c:	012d093b          	addw	s2,s10,s2
    80003d10:	9a6e                	add	s4,s4,s11
    80003d12:	0569f663          	bgeu	s3,s6,80003d5e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d16:	00a9559b          	srliw	a1,s2,0xa
    80003d1a:	8556                	mv	a0,s5
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	7a0080e7          	jalr	1952(ra) # 800034bc <bmap>
    80003d24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d28:	c99d                	beqz	a1,80003d5e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d2a:	000aa503          	lw	a0,0(s5)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	394080e7          	jalr	916(ra) # 800030c2 <bread>
    80003d36:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d38:	3ff97513          	andi	a0,s2,1023
    80003d3c:	40ac87bb          	subw	a5,s9,a0
    80003d40:	413b073b          	subw	a4,s6,s3
    80003d44:	8d3e                	mv	s10,a5
    80003d46:	2781                	sext.w	a5,a5
    80003d48:	0007069b          	sext.w	a3,a4
    80003d4c:	f8f6f4e3          	bgeu	a3,a5,80003cd4 <writei+0x4c>
    80003d50:	8d3a                	mv	s10,a4
    80003d52:	b749                	j	80003cd4 <writei+0x4c>
      brelse(bp);
    80003d54:	8526                	mv	a0,s1
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	49c080e7          	jalr	1180(ra) # 800031f2 <brelse>
  }

  if(off > ip->size)
    80003d5e:	04caa783          	lw	a5,76(s5)
    80003d62:	0127f463          	bgeu	a5,s2,80003d6a <writei+0xe2>
    ip->size = off;
    80003d66:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d6a:	8556                	mv	a0,s5
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	aa6080e7          	jalr	-1370(ra) # 80003812 <iupdate>

  return tot;
    80003d74:	0009851b          	sext.w	a0,s3
}
    80003d78:	70a6                	ld	ra,104(sp)
    80003d7a:	7406                	ld	s0,96(sp)
    80003d7c:	64e6                	ld	s1,88(sp)
    80003d7e:	6946                	ld	s2,80(sp)
    80003d80:	69a6                	ld	s3,72(sp)
    80003d82:	6a06                	ld	s4,64(sp)
    80003d84:	7ae2                	ld	s5,56(sp)
    80003d86:	7b42                	ld	s6,48(sp)
    80003d88:	7ba2                	ld	s7,40(sp)
    80003d8a:	7c02                	ld	s8,32(sp)
    80003d8c:	6ce2                	ld	s9,24(sp)
    80003d8e:	6d42                	ld	s10,16(sp)
    80003d90:	6da2                	ld	s11,8(sp)
    80003d92:	6165                	addi	sp,sp,112
    80003d94:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d96:	89da                	mv	s3,s6
    80003d98:	bfc9                	j	80003d6a <writei+0xe2>
    return -1;
    80003d9a:	557d                	li	a0,-1
}
    80003d9c:	8082                	ret
    return -1;
    80003d9e:	557d                	li	a0,-1
    80003da0:	bfe1                	j	80003d78 <writei+0xf0>
    return -1;
    80003da2:	557d                	li	a0,-1
    80003da4:	bfd1                	j	80003d78 <writei+0xf0>

0000000080003da6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003da6:	1141                	addi	sp,sp,-16
    80003da8:	e406                	sd	ra,8(sp)
    80003daa:	e022                	sd	s0,0(sp)
    80003dac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dae:	4639                	li	a2,14
    80003db0:	ffffd097          	auipc	ra,0xffffd
    80003db4:	04e080e7          	jalr	78(ra) # 80000dfe <strncmp>
}
    80003db8:	60a2                	ld	ra,8(sp)
    80003dba:	6402                	ld	s0,0(sp)
    80003dbc:	0141                	addi	sp,sp,16
    80003dbe:	8082                	ret

0000000080003dc0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc0:	7139                	addi	sp,sp,-64
    80003dc2:	fc06                	sd	ra,56(sp)
    80003dc4:	f822                	sd	s0,48(sp)
    80003dc6:	f426                	sd	s1,40(sp)
    80003dc8:	f04a                	sd	s2,32(sp)
    80003dca:	ec4e                	sd	s3,24(sp)
    80003dcc:	e852                	sd	s4,16(sp)
    80003dce:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd0:	04451703          	lh	a4,68(a0)
    80003dd4:	4785                	li	a5,1
    80003dd6:	00f71a63          	bne	a4,a5,80003dea <dirlookup+0x2a>
    80003dda:	892a                	mv	s2,a0
    80003ddc:	89ae                	mv	s3,a1
    80003dde:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de0:	457c                	lw	a5,76(a0)
    80003de2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003de4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de6:	e79d                	bnez	a5,80003e14 <dirlookup+0x54>
    80003de8:	a8a5                	j	80003e60 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dea:	00005517          	auipc	a0,0x5
    80003dee:	85650513          	addi	a0,a0,-1962 # 80008640 <syscalls+0x1c0>
    80003df2:	ffffc097          	auipc	ra,0xffffc
    80003df6:	74c080e7          	jalr	1868(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dfa:	00005517          	auipc	a0,0x5
    80003dfe:	85e50513          	addi	a0,a0,-1954 # 80008658 <syscalls+0x1d8>
    80003e02:	ffffc097          	auipc	ra,0xffffc
    80003e06:	73c080e7          	jalr	1852(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0a:	24c1                	addiw	s1,s1,16
    80003e0c:	04c92783          	lw	a5,76(s2)
    80003e10:	04f4f763          	bgeu	s1,a5,80003e5e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e14:	4741                	li	a4,16
    80003e16:	86a6                	mv	a3,s1
    80003e18:	fc040613          	addi	a2,s0,-64
    80003e1c:	4581                	li	a1,0
    80003e1e:	854a                	mv	a0,s2
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	d70080e7          	jalr	-656(ra) # 80003b90 <readi>
    80003e28:	47c1                	li	a5,16
    80003e2a:	fcf518e3          	bne	a0,a5,80003dfa <dirlookup+0x3a>
    if(de.inum == 0)
    80003e2e:	fc045783          	lhu	a5,-64(s0)
    80003e32:	dfe1                	beqz	a5,80003e0a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e34:	fc240593          	addi	a1,s0,-62
    80003e38:	854e                	mv	a0,s3
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	f6c080e7          	jalr	-148(ra) # 80003da6 <namecmp>
    80003e42:	f561                	bnez	a0,80003e0a <dirlookup+0x4a>
      if(poff)
    80003e44:	000a0463          	beqz	s4,80003e4c <dirlookup+0x8c>
        *poff = off;
    80003e48:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e4c:	fc045583          	lhu	a1,-64(s0)
    80003e50:	00092503          	lw	a0,0(s2)
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	750080e7          	jalr	1872(ra) # 800035a4 <iget>
    80003e5c:	a011                	j	80003e60 <dirlookup+0xa0>
  return 0;
    80003e5e:	4501                	li	a0,0
}
    80003e60:	70e2                	ld	ra,56(sp)
    80003e62:	7442                	ld	s0,48(sp)
    80003e64:	74a2                	ld	s1,40(sp)
    80003e66:	7902                	ld	s2,32(sp)
    80003e68:	69e2                	ld	s3,24(sp)
    80003e6a:	6a42                	ld	s4,16(sp)
    80003e6c:	6121                	addi	sp,sp,64
    80003e6e:	8082                	ret

0000000080003e70 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e70:	711d                	addi	sp,sp,-96
    80003e72:	ec86                	sd	ra,88(sp)
    80003e74:	e8a2                	sd	s0,80(sp)
    80003e76:	e4a6                	sd	s1,72(sp)
    80003e78:	e0ca                	sd	s2,64(sp)
    80003e7a:	fc4e                	sd	s3,56(sp)
    80003e7c:	f852                	sd	s4,48(sp)
    80003e7e:	f456                	sd	s5,40(sp)
    80003e80:	f05a                	sd	s6,32(sp)
    80003e82:	ec5e                	sd	s7,24(sp)
    80003e84:	e862                	sd	s8,16(sp)
    80003e86:	e466                	sd	s9,8(sp)
    80003e88:	1080                	addi	s0,sp,96
    80003e8a:	84aa                	mv	s1,a0
    80003e8c:	8aae                	mv	s5,a1
    80003e8e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e90:	00054703          	lbu	a4,0(a0)
    80003e94:	02f00793          	li	a5,47
    80003e98:	02f70363          	beq	a4,a5,80003ebe <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e9c:	ffffe097          	auipc	ra,0xffffe
    80003ea0:	b6c080e7          	jalr	-1172(ra) # 80001a08 <myproc>
    80003ea4:	15053503          	ld	a0,336(a0)
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	9f6080e7          	jalr	-1546(ra) # 8000389e <idup>
    80003eb0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb2:	02f00913          	li	s2,47
  len = path - s;
    80003eb6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eb8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eba:	4b85                	li	s7,1
    80003ebc:	a865                	j	80003f74 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ebe:	4585                	li	a1,1
    80003ec0:	4505                	li	a0,1
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	6e2080e7          	jalr	1762(ra) # 800035a4 <iget>
    80003eca:	89aa                	mv	s3,a0
    80003ecc:	b7dd                	j	80003eb2 <namex+0x42>
      iunlockput(ip);
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	c6e080e7          	jalr	-914(ra) # 80003b3e <iunlockput>
      return 0;
    80003ed8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003eda:	854e                	mv	a0,s3
    80003edc:	60e6                	ld	ra,88(sp)
    80003ede:	6446                	ld	s0,80(sp)
    80003ee0:	64a6                	ld	s1,72(sp)
    80003ee2:	6906                	ld	s2,64(sp)
    80003ee4:	79e2                	ld	s3,56(sp)
    80003ee6:	7a42                	ld	s4,48(sp)
    80003ee8:	7aa2                	ld	s5,40(sp)
    80003eea:	7b02                	ld	s6,32(sp)
    80003eec:	6be2                	ld	s7,24(sp)
    80003eee:	6c42                	ld	s8,16(sp)
    80003ef0:	6ca2                	ld	s9,8(sp)
    80003ef2:	6125                	addi	sp,sp,96
    80003ef4:	8082                	ret
      iunlock(ip);
    80003ef6:	854e                	mv	a0,s3
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	aa6080e7          	jalr	-1370(ra) # 8000399e <iunlock>
      return ip;
    80003f00:	bfe9                	j	80003eda <namex+0x6a>
      iunlockput(ip);
    80003f02:	854e                	mv	a0,s3
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	c3a080e7          	jalr	-966(ra) # 80003b3e <iunlockput>
      return 0;
    80003f0c:	89e6                	mv	s3,s9
    80003f0e:	b7f1                	j	80003eda <namex+0x6a>
  len = path - s;
    80003f10:	40b48633          	sub	a2,s1,a1
    80003f14:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f18:	099c5463          	bge	s8,s9,80003fa0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f1c:	4639                	li	a2,14
    80003f1e:	8552                	mv	a0,s4
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	e6a080e7          	jalr	-406(ra) # 80000d8a <memmove>
  while(*path == '/')
    80003f28:	0004c783          	lbu	a5,0(s1)
    80003f2c:	01279763          	bne	a5,s2,80003f3a <namex+0xca>
    path++;
    80003f30:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f32:	0004c783          	lbu	a5,0(s1)
    80003f36:	ff278de3          	beq	a5,s2,80003f30 <namex+0xc0>
    ilock(ip);
    80003f3a:	854e                	mv	a0,s3
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	9a0080e7          	jalr	-1632(ra) # 800038dc <ilock>
    if(ip->type != T_DIR){
    80003f44:	04499783          	lh	a5,68(s3)
    80003f48:	f97793e3          	bne	a5,s7,80003ece <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f4c:	000a8563          	beqz	s5,80003f56 <namex+0xe6>
    80003f50:	0004c783          	lbu	a5,0(s1)
    80003f54:	d3cd                	beqz	a5,80003ef6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f56:	865a                	mv	a2,s6
    80003f58:	85d2                	mv	a1,s4
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	e64080e7          	jalr	-412(ra) # 80003dc0 <dirlookup>
    80003f64:	8caa                	mv	s9,a0
    80003f66:	dd51                	beqz	a0,80003f02 <namex+0x92>
    iunlockput(ip);
    80003f68:	854e                	mv	a0,s3
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	bd4080e7          	jalr	-1068(ra) # 80003b3e <iunlockput>
    ip = next;
    80003f72:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f74:	0004c783          	lbu	a5,0(s1)
    80003f78:	05279763          	bne	a5,s2,80003fc6 <namex+0x156>
    path++;
    80003f7c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f7e:	0004c783          	lbu	a5,0(s1)
    80003f82:	ff278de3          	beq	a5,s2,80003f7c <namex+0x10c>
  if(*path == 0)
    80003f86:	c79d                	beqz	a5,80003fb4 <namex+0x144>
    path++;
    80003f88:	85a6                	mv	a1,s1
  len = path - s;
    80003f8a:	8cda                	mv	s9,s6
    80003f8c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f8e:	01278963          	beq	a5,s2,80003fa0 <namex+0x130>
    80003f92:	dfbd                	beqz	a5,80003f10 <namex+0xa0>
    path++;
    80003f94:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f96:	0004c783          	lbu	a5,0(s1)
    80003f9a:	ff279ce3          	bne	a5,s2,80003f92 <namex+0x122>
    80003f9e:	bf8d                	j	80003f10 <namex+0xa0>
    memmove(name, s, len);
    80003fa0:	2601                	sext.w	a2,a2
    80003fa2:	8552                	mv	a0,s4
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	de6080e7          	jalr	-538(ra) # 80000d8a <memmove>
    name[len] = 0;
    80003fac:	9cd2                	add	s9,s9,s4
    80003fae:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fb2:	bf9d                	j	80003f28 <namex+0xb8>
  if(nameiparent){
    80003fb4:	f20a83e3          	beqz	s5,80003eda <namex+0x6a>
    iput(ip);
    80003fb8:	854e                	mv	a0,s3
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	adc080e7          	jalr	-1316(ra) # 80003a96 <iput>
    return 0;
    80003fc2:	4981                	li	s3,0
    80003fc4:	bf19                	j	80003eda <namex+0x6a>
  if(*path == 0)
    80003fc6:	d7fd                	beqz	a5,80003fb4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	85a6                	mv	a1,s1
    80003fce:	b7d1                	j	80003f92 <namex+0x122>

0000000080003fd0 <dirlink>:
{
    80003fd0:	7139                	addi	sp,sp,-64
    80003fd2:	fc06                	sd	ra,56(sp)
    80003fd4:	f822                	sd	s0,48(sp)
    80003fd6:	f426                	sd	s1,40(sp)
    80003fd8:	f04a                	sd	s2,32(sp)
    80003fda:	ec4e                	sd	s3,24(sp)
    80003fdc:	e852                	sd	s4,16(sp)
    80003fde:	0080                	addi	s0,sp,64
    80003fe0:	892a                	mv	s2,a0
    80003fe2:	8a2e                	mv	s4,a1
    80003fe4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fe6:	4601                	li	a2,0
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	dd8080e7          	jalr	-552(ra) # 80003dc0 <dirlookup>
    80003ff0:	e93d                	bnez	a0,80004066 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff2:	04c92483          	lw	s1,76(s2)
    80003ff6:	c49d                	beqz	s1,80004024 <dirlink+0x54>
    80003ff8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffa:	4741                	li	a4,16
    80003ffc:	86a6                	mv	a3,s1
    80003ffe:	fc040613          	addi	a2,s0,-64
    80004002:	4581                	li	a1,0
    80004004:	854a                	mv	a0,s2
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	b8a080e7          	jalr	-1142(ra) # 80003b90 <readi>
    8000400e:	47c1                	li	a5,16
    80004010:	06f51163          	bne	a0,a5,80004072 <dirlink+0xa2>
    if(de.inum == 0)
    80004014:	fc045783          	lhu	a5,-64(s0)
    80004018:	c791                	beqz	a5,80004024 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401a:	24c1                	addiw	s1,s1,16
    8000401c:	04c92783          	lw	a5,76(s2)
    80004020:	fcf4ede3          	bltu	s1,a5,80003ffa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004024:	4639                	li	a2,14
    80004026:	85d2                	mv	a1,s4
    80004028:	fc240513          	addi	a0,s0,-62
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	e0e080e7          	jalr	-498(ra) # 80000e3a <strncpy>
  de.inum = inum;
    80004034:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004038:	4741                	li	a4,16
    8000403a:	86a6                	mv	a3,s1
    8000403c:	fc040613          	addi	a2,s0,-64
    80004040:	4581                	li	a1,0
    80004042:	854a                	mv	a0,s2
    80004044:	00000097          	auipc	ra,0x0
    80004048:	c44080e7          	jalr	-956(ra) # 80003c88 <writei>
    8000404c:	1541                	addi	a0,a0,-16
    8000404e:	00a03533          	snez	a0,a0
    80004052:	40a00533          	neg	a0,a0
}
    80004056:	70e2                	ld	ra,56(sp)
    80004058:	7442                	ld	s0,48(sp)
    8000405a:	74a2                	ld	s1,40(sp)
    8000405c:	7902                	ld	s2,32(sp)
    8000405e:	69e2                	ld	s3,24(sp)
    80004060:	6a42                	ld	s4,16(sp)
    80004062:	6121                	addi	sp,sp,64
    80004064:	8082                	ret
    iput(ip);
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	a30080e7          	jalr	-1488(ra) # 80003a96 <iput>
    return -1;
    8000406e:	557d                	li	a0,-1
    80004070:	b7dd                	j	80004056 <dirlink+0x86>
      panic("dirlink read");
    80004072:	00004517          	auipc	a0,0x4
    80004076:	5f650513          	addi	a0,a0,1526 # 80008668 <syscalls+0x1e8>
    8000407a:	ffffc097          	auipc	ra,0xffffc
    8000407e:	4c4080e7          	jalr	1220(ra) # 8000053e <panic>

0000000080004082 <namei>:

struct inode*
namei(char *path)
{
    80004082:	1101                	addi	sp,sp,-32
    80004084:	ec06                	sd	ra,24(sp)
    80004086:	e822                	sd	s0,16(sp)
    80004088:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000408a:	fe040613          	addi	a2,s0,-32
    8000408e:	4581                	li	a1,0
    80004090:	00000097          	auipc	ra,0x0
    80004094:	de0080e7          	jalr	-544(ra) # 80003e70 <namex>
}
    80004098:	60e2                	ld	ra,24(sp)
    8000409a:	6442                	ld	s0,16(sp)
    8000409c:	6105                	addi	sp,sp,32
    8000409e:	8082                	ret

00000000800040a0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040a0:	1141                	addi	sp,sp,-16
    800040a2:	e406                	sd	ra,8(sp)
    800040a4:	e022                	sd	s0,0(sp)
    800040a6:	0800                	addi	s0,sp,16
    800040a8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040aa:	4585                	li	a1,1
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	dc4080e7          	jalr	-572(ra) # 80003e70 <namex>
}
    800040b4:	60a2                	ld	ra,8(sp)
    800040b6:	6402                	ld	s0,0(sp)
    800040b8:	0141                	addi	sp,sp,16
    800040ba:	8082                	ret

00000000800040bc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040bc:	1101                	addi	sp,sp,-32
    800040be:	ec06                	sd	ra,24(sp)
    800040c0:	e822                	sd	s0,16(sp)
    800040c2:	e426                	sd	s1,8(sp)
    800040c4:	e04a                	sd	s2,0(sp)
    800040c6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040c8:	0001d917          	auipc	s2,0x1d
    800040cc:	c8890913          	addi	s2,s2,-888 # 80020d50 <log>
    800040d0:	01892583          	lw	a1,24(s2)
    800040d4:	02892503          	lw	a0,40(s2)
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	fea080e7          	jalr	-22(ra) # 800030c2 <bread>
    800040e0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040e2:	02c92683          	lw	a3,44(s2)
    800040e6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040e8:	02d05763          	blez	a3,80004116 <write_head+0x5a>
    800040ec:	0001d797          	auipc	a5,0x1d
    800040f0:	c9478793          	addi	a5,a5,-876 # 80020d80 <log+0x30>
    800040f4:	05c50713          	addi	a4,a0,92
    800040f8:	36fd                	addiw	a3,a3,-1
    800040fa:	1682                	slli	a3,a3,0x20
    800040fc:	9281                	srli	a3,a3,0x20
    800040fe:	068a                	slli	a3,a3,0x2
    80004100:	0001d617          	auipc	a2,0x1d
    80004104:	c8460613          	addi	a2,a2,-892 # 80020d84 <log+0x34>
    80004108:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000410a:	4390                	lw	a2,0(a5)
    8000410c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000410e:	0791                	addi	a5,a5,4
    80004110:	0711                	addi	a4,a4,4
    80004112:	fed79ce3          	bne	a5,a3,8000410a <write_head+0x4e>
  }
  bwrite(buf);
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	09c080e7          	jalr	156(ra) # 800031b4 <bwrite>
  brelse(buf);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	0d0080e7          	jalr	208(ra) # 800031f2 <brelse>
}
    8000412a:	60e2                	ld	ra,24(sp)
    8000412c:	6442                	ld	s0,16(sp)
    8000412e:	64a2                	ld	s1,8(sp)
    80004130:	6902                	ld	s2,0(sp)
    80004132:	6105                	addi	sp,sp,32
    80004134:	8082                	ret

0000000080004136 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004136:	0001d797          	auipc	a5,0x1d
    8000413a:	c467a783          	lw	a5,-954(a5) # 80020d7c <log+0x2c>
    8000413e:	0af05d63          	blez	a5,800041f8 <install_trans+0xc2>
{
    80004142:	7139                	addi	sp,sp,-64
    80004144:	fc06                	sd	ra,56(sp)
    80004146:	f822                	sd	s0,48(sp)
    80004148:	f426                	sd	s1,40(sp)
    8000414a:	f04a                	sd	s2,32(sp)
    8000414c:	ec4e                	sd	s3,24(sp)
    8000414e:	e852                	sd	s4,16(sp)
    80004150:	e456                	sd	s5,8(sp)
    80004152:	e05a                	sd	s6,0(sp)
    80004154:	0080                	addi	s0,sp,64
    80004156:	8b2a                	mv	s6,a0
    80004158:	0001da97          	auipc	s5,0x1d
    8000415c:	c28a8a93          	addi	s5,s5,-984 # 80020d80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004160:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004162:	0001d997          	auipc	s3,0x1d
    80004166:	bee98993          	addi	s3,s3,-1042 # 80020d50 <log>
    8000416a:	a00d                	j	8000418c <install_trans+0x56>
    brelse(lbuf);
    8000416c:	854a                	mv	a0,s2
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	084080e7          	jalr	132(ra) # 800031f2 <brelse>
    brelse(dbuf);
    80004176:	8526                	mv	a0,s1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	07a080e7          	jalr	122(ra) # 800031f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004180:	2a05                	addiw	s4,s4,1
    80004182:	0a91                	addi	s5,s5,4
    80004184:	02c9a783          	lw	a5,44(s3)
    80004188:	04fa5e63          	bge	s4,a5,800041e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000418c:	0189a583          	lw	a1,24(s3)
    80004190:	014585bb          	addw	a1,a1,s4
    80004194:	2585                	addiw	a1,a1,1
    80004196:	0289a503          	lw	a0,40(s3)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	f28080e7          	jalr	-216(ra) # 800030c2 <bread>
    800041a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041a4:	000aa583          	lw	a1,0(s5)
    800041a8:	0289a503          	lw	a0,40(s3)
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	f16080e7          	jalr	-234(ra) # 800030c2 <bread>
    800041b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041b6:	40000613          	li	a2,1024
    800041ba:	05890593          	addi	a1,s2,88
    800041be:	05850513          	addi	a0,a0,88
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	bc8080e7          	jalr	-1080(ra) # 80000d8a <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	fe8080e7          	jalr	-24(ra) # 800031b4 <bwrite>
    if(recovering == 0)
    800041d4:	f80b1ce3          	bnez	s6,8000416c <install_trans+0x36>
      bunpin(dbuf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	0f2080e7          	jalr	242(ra) # 800032cc <bunpin>
    800041e2:	b769                	j	8000416c <install_trans+0x36>
}
    800041e4:	70e2                	ld	ra,56(sp)
    800041e6:	7442                	ld	s0,48(sp)
    800041e8:	74a2                	ld	s1,40(sp)
    800041ea:	7902                	ld	s2,32(sp)
    800041ec:	69e2                	ld	s3,24(sp)
    800041ee:	6a42                	ld	s4,16(sp)
    800041f0:	6aa2                	ld	s5,8(sp)
    800041f2:	6b02                	ld	s6,0(sp)
    800041f4:	6121                	addi	sp,sp,64
    800041f6:	8082                	ret
    800041f8:	8082                	ret

00000000800041fa <initlog>:
{
    800041fa:	7179                	addi	sp,sp,-48
    800041fc:	f406                	sd	ra,40(sp)
    800041fe:	f022                	sd	s0,32(sp)
    80004200:	ec26                	sd	s1,24(sp)
    80004202:	e84a                	sd	s2,16(sp)
    80004204:	e44e                	sd	s3,8(sp)
    80004206:	1800                	addi	s0,sp,48
    80004208:	892a                	mv	s2,a0
    8000420a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000420c:	0001d497          	auipc	s1,0x1d
    80004210:	b4448493          	addi	s1,s1,-1212 # 80020d50 <log>
    80004214:	00004597          	auipc	a1,0x4
    80004218:	46458593          	addi	a1,a1,1124 # 80008678 <syscalls+0x1f8>
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	984080e7          	jalr	-1660(ra) # 80000ba2 <initlock>
  log.start = sb->logstart;
    80004226:	0149a583          	lw	a1,20(s3)
    8000422a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000422c:	0109a783          	lw	a5,16(s3)
    80004230:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004232:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004236:	854a                	mv	a0,s2
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	e8a080e7          	jalr	-374(ra) # 800030c2 <bread>
  log.lh.n = lh->n;
    80004240:	4d34                	lw	a3,88(a0)
    80004242:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004244:	02d05563          	blez	a3,8000426e <initlog+0x74>
    80004248:	05c50793          	addi	a5,a0,92
    8000424c:	0001d717          	auipc	a4,0x1d
    80004250:	b3470713          	addi	a4,a4,-1228 # 80020d80 <log+0x30>
    80004254:	36fd                	addiw	a3,a3,-1
    80004256:	1682                	slli	a3,a3,0x20
    80004258:	9281                	srli	a3,a3,0x20
    8000425a:	068a                	slli	a3,a3,0x2
    8000425c:	06050613          	addi	a2,a0,96
    80004260:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004262:	4390                	lw	a2,0(a5)
    80004264:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004266:	0791                	addi	a5,a5,4
    80004268:	0711                	addi	a4,a4,4
    8000426a:	fed79ce3          	bne	a5,a3,80004262 <initlog+0x68>
  brelse(buf);
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	f84080e7          	jalr	-124(ra) # 800031f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004276:	4505                	li	a0,1
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	ebe080e7          	jalr	-322(ra) # 80004136 <install_trans>
  log.lh.n = 0;
    80004280:	0001d797          	auipc	a5,0x1d
    80004284:	ae07ae23          	sw	zero,-1284(a5) # 80020d7c <log+0x2c>
  write_head(); // clear the log
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	e34080e7          	jalr	-460(ra) # 800040bc <write_head>
}
    80004290:	70a2                	ld	ra,40(sp)
    80004292:	7402                	ld	s0,32(sp)
    80004294:	64e2                	ld	s1,24(sp)
    80004296:	6942                	ld	s2,16(sp)
    80004298:	69a2                	ld	s3,8(sp)
    8000429a:	6145                	addi	sp,sp,48
    8000429c:	8082                	ret

000000008000429e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000429e:	1101                	addi	sp,sp,-32
    800042a0:	ec06                	sd	ra,24(sp)
    800042a2:	e822                	sd	s0,16(sp)
    800042a4:	e426                	sd	s1,8(sp)
    800042a6:	e04a                	sd	s2,0(sp)
    800042a8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042aa:	0001d517          	auipc	a0,0x1d
    800042ae:	aa650513          	addi	a0,a0,-1370 # 80020d50 <log>
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	980080e7          	jalr	-1664(ra) # 80000c32 <acquire>
  while(1){
    if(log.committing){
    800042ba:	0001d497          	auipc	s1,0x1d
    800042be:	a9648493          	addi	s1,s1,-1386 # 80020d50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c2:	4979                	li	s2,30
    800042c4:	a039                	j	800042d2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042c6:	85a6                	mv	a1,s1
    800042c8:	8526                	mv	a0,s1
    800042ca:	ffffe097          	auipc	ra,0xffffe
    800042ce:	df2080e7          	jalr	-526(ra) # 800020bc <sleep>
    if(log.committing){
    800042d2:	50dc                	lw	a5,36(s1)
    800042d4:	fbed                	bnez	a5,800042c6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d6:	509c                	lw	a5,32(s1)
    800042d8:	0017871b          	addiw	a4,a5,1
    800042dc:	0007069b          	sext.w	a3,a4
    800042e0:	0027179b          	slliw	a5,a4,0x2
    800042e4:	9fb9                	addw	a5,a5,a4
    800042e6:	0017979b          	slliw	a5,a5,0x1
    800042ea:	54d8                	lw	a4,44(s1)
    800042ec:	9fb9                	addw	a5,a5,a4
    800042ee:	00f95963          	bge	s2,a5,80004300 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042f2:	85a6                	mv	a1,s1
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffe097          	auipc	ra,0xffffe
    800042fa:	dc6080e7          	jalr	-570(ra) # 800020bc <sleep>
    800042fe:	bfd1                	j	800042d2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004300:	0001d517          	auipc	a0,0x1d
    80004304:	a5050513          	addi	a0,a0,-1456 # 80020d50 <log>
    80004308:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	9dc080e7          	jalr	-1572(ra) # 80000ce6 <release>
      break;
    }
  }
}
    80004312:	60e2                	ld	ra,24(sp)
    80004314:	6442                	ld	s0,16(sp)
    80004316:	64a2                	ld	s1,8(sp)
    80004318:	6902                	ld	s2,0(sp)
    8000431a:	6105                	addi	sp,sp,32
    8000431c:	8082                	ret

000000008000431e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000431e:	7139                	addi	sp,sp,-64
    80004320:	fc06                	sd	ra,56(sp)
    80004322:	f822                	sd	s0,48(sp)
    80004324:	f426                	sd	s1,40(sp)
    80004326:	f04a                	sd	s2,32(sp)
    80004328:	ec4e                	sd	s3,24(sp)
    8000432a:	e852                	sd	s4,16(sp)
    8000432c:	e456                	sd	s5,8(sp)
    8000432e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004330:	0001d497          	auipc	s1,0x1d
    80004334:	a2048493          	addi	s1,s1,-1504 # 80020d50 <log>
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8f8080e7          	jalr	-1800(ra) # 80000c32 <acquire>
  log.outstanding -= 1;
    80004342:	509c                	lw	a5,32(s1)
    80004344:	37fd                	addiw	a5,a5,-1
    80004346:	0007891b          	sext.w	s2,a5
    8000434a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000434c:	50dc                	lw	a5,36(s1)
    8000434e:	e7b9                	bnez	a5,8000439c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004350:	04091e63          	bnez	s2,800043ac <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004354:	0001d497          	auipc	s1,0x1d
    80004358:	9fc48493          	addi	s1,s1,-1540 # 80020d50 <log>
    8000435c:	4785                	li	a5,1
    8000435e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004360:	8526                	mv	a0,s1
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	984080e7          	jalr	-1660(ra) # 80000ce6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000436a:	54dc                	lw	a5,44(s1)
    8000436c:	06f04763          	bgtz	a5,800043da <end_op+0xbc>
    acquire(&log.lock);
    80004370:	0001d497          	auipc	s1,0x1d
    80004374:	9e048493          	addi	s1,s1,-1568 # 80020d50 <log>
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	8b8080e7          	jalr	-1864(ra) # 80000c32 <acquire>
    log.committing = 0;
    80004382:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffe097          	auipc	ra,0xffffe
    8000438c:	d98080e7          	jalr	-616(ra) # 80002120 <wakeup>
    release(&log.lock);
    80004390:	8526                	mv	a0,s1
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	954080e7          	jalr	-1708(ra) # 80000ce6 <release>
}
    8000439a:	a03d                	j	800043c8 <end_op+0xaa>
    panic("log.committing");
    8000439c:	00004517          	auipc	a0,0x4
    800043a0:	2e450513          	addi	a0,a0,740 # 80008680 <syscalls+0x200>
    800043a4:	ffffc097          	auipc	ra,0xffffc
    800043a8:	19a080e7          	jalr	410(ra) # 8000053e <panic>
    wakeup(&log);
    800043ac:	0001d497          	auipc	s1,0x1d
    800043b0:	9a448493          	addi	s1,s1,-1628 # 80020d50 <log>
    800043b4:	8526                	mv	a0,s1
    800043b6:	ffffe097          	auipc	ra,0xffffe
    800043ba:	d6a080e7          	jalr	-662(ra) # 80002120 <wakeup>
  release(&log.lock);
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	926080e7          	jalr	-1754(ra) # 80000ce6 <release>
}
    800043c8:	70e2                	ld	ra,56(sp)
    800043ca:	7442                	ld	s0,48(sp)
    800043cc:	74a2                	ld	s1,40(sp)
    800043ce:	7902                	ld	s2,32(sp)
    800043d0:	69e2                	ld	s3,24(sp)
    800043d2:	6a42                	ld	s4,16(sp)
    800043d4:	6aa2                	ld	s5,8(sp)
    800043d6:	6121                	addi	sp,sp,64
    800043d8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043da:	0001da97          	auipc	s5,0x1d
    800043de:	9a6a8a93          	addi	s5,s5,-1626 # 80020d80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043e2:	0001da17          	auipc	s4,0x1d
    800043e6:	96ea0a13          	addi	s4,s4,-1682 # 80020d50 <log>
    800043ea:	018a2583          	lw	a1,24(s4)
    800043ee:	012585bb          	addw	a1,a1,s2
    800043f2:	2585                	addiw	a1,a1,1
    800043f4:	028a2503          	lw	a0,40(s4)
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	cca080e7          	jalr	-822(ra) # 800030c2 <bread>
    80004400:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004402:	000aa583          	lw	a1,0(s5)
    80004406:	028a2503          	lw	a0,40(s4)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	cb8080e7          	jalr	-840(ra) # 800030c2 <bread>
    80004412:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004414:	40000613          	li	a2,1024
    80004418:	05850593          	addi	a1,a0,88
    8000441c:	05848513          	addi	a0,s1,88
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	96a080e7          	jalr	-1686(ra) # 80000d8a <memmove>
    bwrite(to);  // write the log
    80004428:	8526                	mv	a0,s1
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	d8a080e7          	jalr	-630(ra) # 800031b4 <bwrite>
    brelse(from);
    80004432:	854e                	mv	a0,s3
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	dbe080e7          	jalr	-578(ra) # 800031f2 <brelse>
    brelse(to);
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	db4080e7          	jalr	-588(ra) # 800031f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	2905                	addiw	s2,s2,1
    80004448:	0a91                	addi	s5,s5,4
    8000444a:	02ca2783          	lw	a5,44(s4)
    8000444e:	f8f94ee3          	blt	s2,a5,800043ea <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004452:	00000097          	auipc	ra,0x0
    80004456:	c6a080e7          	jalr	-918(ra) # 800040bc <write_head>
    install_trans(0); // Now install writes to home locations
    8000445a:	4501                	li	a0,0
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	cda080e7          	jalr	-806(ra) # 80004136 <install_trans>
    log.lh.n = 0;
    80004464:	0001d797          	auipc	a5,0x1d
    80004468:	9007ac23          	sw	zero,-1768(a5) # 80020d7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	c50080e7          	jalr	-944(ra) # 800040bc <write_head>
    80004474:	bdf5                	j	80004370 <end_op+0x52>

0000000080004476 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004476:	1101                	addi	sp,sp,-32
    80004478:	ec06                	sd	ra,24(sp)
    8000447a:	e822                	sd	s0,16(sp)
    8000447c:	e426                	sd	s1,8(sp)
    8000447e:	e04a                	sd	s2,0(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004484:	0001d917          	auipc	s2,0x1d
    80004488:	8cc90913          	addi	s2,s2,-1844 # 80020d50 <log>
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	7a4080e7          	jalr	1956(ra) # 80000c32 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004496:	02c92603          	lw	a2,44(s2)
    8000449a:	47f5                	li	a5,29
    8000449c:	06c7c563          	blt	a5,a2,80004506 <log_write+0x90>
    800044a0:	0001d797          	auipc	a5,0x1d
    800044a4:	8cc7a783          	lw	a5,-1844(a5) # 80020d6c <log+0x1c>
    800044a8:	37fd                	addiw	a5,a5,-1
    800044aa:	04f65e63          	bge	a2,a5,80004506 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044ae:	0001d797          	auipc	a5,0x1d
    800044b2:	8c27a783          	lw	a5,-1854(a5) # 80020d70 <log+0x20>
    800044b6:	06f05063          	blez	a5,80004516 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044ba:	4781                	li	a5,0
    800044bc:	06c05563          	blez	a2,80004526 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c0:	44cc                	lw	a1,12(s1)
    800044c2:	0001d717          	auipc	a4,0x1d
    800044c6:	8be70713          	addi	a4,a4,-1858 # 80020d80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044cc:	4314                	lw	a3,0(a4)
    800044ce:	04b68c63          	beq	a3,a1,80004526 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044d2:	2785                	addiw	a5,a5,1
    800044d4:	0711                	addi	a4,a4,4
    800044d6:	fef61be3          	bne	a2,a5,800044cc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044da:	0621                	addi	a2,a2,8
    800044dc:	060a                	slli	a2,a2,0x2
    800044de:	0001d797          	auipc	a5,0x1d
    800044e2:	87278793          	addi	a5,a5,-1934 # 80020d50 <log>
    800044e6:	963e                	add	a2,a2,a5
    800044e8:	44dc                	lw	a5,12(s1)
    800044ea:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044ec:	8526                	mv	a0,s1
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	da2080e7          	jalr	-606(ra) # 80003290 <bpin>
    log.lh.n++;
    800044f6:	0001d717          	auipc	a4,0x1d
    800044fa:	85a70713          	addi	a4,a4,-1958 # 80020d50 <log>
    800044fe:	575c                	lw	a5,44(a4)
    80004500:	2785                	addiw	a5,a5,1
    80004502:	d75c                	sw	a5,44(a4)
    80004504:	a835                	j	80004540 <log_write+0xca>
    panic("too big a transaction");
    80004506:	00004517          	auipc	a0,0x4
    8000450a:	18a50513          	addi	a0,a0,394 # 80008690 <syscalls+0x210>
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	030080e7          	jalr	48(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004516:	00004517          	auipc	a0,0x4
    8000451a:	19250513          	addi	a0,a0,402 # 800086a8 <syscalls+0x228>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	020080e7          	jalr	32(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004526:	00878713          	addi	a4,a5,8
    8000452a:	00271693          	slli	a3,a4,0x2
    8000452e:	0001d717          	auipc	a4,0x1d
    80004532:	82270713          	addi	a4,a4,-2014 # 80020d50 <log>
    80004536:	9736                	add	a4,a4,a3
    80004538:	44d4                	lw	a3,12(s1)
    8000453a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000453c:	faf608e3          	beq	a2,a5,800044ec <log_write+0x76>
  }
  release(&log.lock);
    80004540:	0001d517          	auipc	a0,0x1d
    80004544:	81050513          	addi	a0,a0,-2032 # 80020d50 <log>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	79e080e7          	jalr	1950(ra) # 80000ce6 <release>
}
    80004550:	60e2                	ld	ra,24(sp)
    80004552:	6442                	ld	s0,16(sp)
    80004554:	64a2                	ld	s1,8(sp)
    80004556:	6902                	ld	s2,0(sp)
    80004558:	6105                	addi	sp,sp,32
    8000455a:	8082                	ret

000000008000455c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000455c:	1101                	addi	sp,sp,-32
    8000455e:	ec06                	sd	ra,24(sp)
    80004560:	e822                	sd	s0,16(sp)
    80004562:	e426                	sd	s1,8(sp)
    80004564:	e04a                	sd	s2,0(sp)
    80004566:	1000                	addi	s0,sp,32
    80004568:	84aa                	mv	s1,a0
    8000456a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000456c:	00004597          	auipc	a1,0x4
    80004570:	15c58593          	addi	a1,a1,348 # 800086c8 <syscalls+0x248>
    80004574:	0521                	addi	a0,a0,8
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	62c080e7          	jalr	1580(ra) # 80000ba2 <initlock>
  lk->name = name;
    8000457e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004582:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004586:	0204a423          	sw	zero,40(s1)
}
    8000458a:	60e2                	ld	ra,24(sp)
    8000458c:	6442                	ld	s0,16(sp)
    8000458e:	64a2                	ld	s1,8(sp)
    80004590:	6902                	ld	s2,0(sp)
    80004592:	6105                	addi	sp,sp,32
    80004594:	8082                	ret

0000000080004596 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004596:	1101                	addi	sp,sp,-32
    80004598:	ec06                	sd	ra,24(sp)
    8000459a:	e822                	sd	s0,16(sp)
    8000459c:	e426                	sd	s1,8(sp)
    8000459e:	e04a                	sd	s2,0(sp)
    800045a0:	1000                	addi	s0,sp,32
    800045a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a4:	00850913          	addi	s2,a0,8
    800045a8:	854a                	mv	a0,s2
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	688080e7          	jalr	1672(ra) # 80000c32 <acquire>
  while (lk->locked) {
    800045b2:	409c                	lw	a5,0(s1)
    800045b4:	cb89                	beqz	a5,800045c6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045b6:	85ca                	mv	a1,s2
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffe097          	auipc	ra,0xffffe
    800045be:	b02080e7          	jalr	-1278(ra) # 800020bc <sleep>
  while (lk->locked) {
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	fbed                	bnez	a5,800045b6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045c6:	4785                	li	a5,1
    800045c8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045ca:	ffffd097          	auipc	ra,0xffffd
    800045ce:	43e080e7          	jalr	1086(ra) # 80001a08 <myproc>
    800045d2:	591c                	lw	a5,48(a0)
    800045d4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045d6:	854a                	mv	a0,s2
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	70e080e7          	jalr	1806(ra) # 80000ce6 <release>
}
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6902                	ld	s2,0(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	e426                	sd	s1,8(sp)
    800045f4:	e04a                	sd	s2,0(sp)
    800045f6:	1000                	addi	s0,sp,32
    800045f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fa:	00850913          	addi	s2,a0,8
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	632080e7          	jalr	1586(ra) # 80000c32 <acquire>
  lk->locked = 0;
    80004608:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000460c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004610:	8526                	mv	a0,s1
    80004612:	ffffe097          	auipc	ra,0xffffe
    80004616:	b0e080e7          	jalr	-1266(ra) # 80002120 <wakeup>
  release(&lk->lk);
    8000461a:	854a                	mv	a0,s2
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	6ca080e7          	jalr	1738(ra) # 80000ce6 <release>
}
    80004624:	60e2                	ld	ra,24(sp)
    80004626:	6442                	ld	s0,16(sp)
    80004628:	64a2                	ld	s1,8(sp)
    8000462a:	6902                	ld	s2,0(sp)
    8000462c:	6105                	addi	sp,sp,32
    8000462e:	8082                	ret

0000000080004630 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004630:	7179                	addi	sp,sp,-48
    80004632:	f406                	sd	ra,40(sp)
    80004634:	f022                	sd	s0,32(sp)
    80004636:	ec26                	sd	s1,24(sp)
    80004638:	e84a                	sd	s2,16(sp)
    8000463a:	e44e                	sd	s3,8(sp)
    8000463c:	1800                	addi	s0,sp,48
    8000463e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004640:	00850913          	addi	s2,a0,8
    80004644:	854a                	mv	a0,s2
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	5ec080e7          	jalr	1516(ra) # 80000c32 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000464e:	409c                	lw	a5,0(s1)
    80004650:	ef99                	bnez	a5,8000466e <holdingsleep+0x3e>
    80004652:	4481                	li	s1,0
  release(&lk->lk);
    80004654:	854a                	mv	a0,s2
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	690080e7          	jalr	1680(ra) # 80000ce6 <release>
  return r;
}
    8000465e:	8526                	mv	a0,s1
    80004660:	70a2                	ld	ra,40(sp)
    80004662:	7402                	ld	s0,32(sp)
    80004664:	64e2                	ld	s1,24(sp)
    80004666:	6942                	ld	s2,16(sp)
    80004668:	69a2                	ld	s3,8(sp)
    8000466a:	6145                	addi	sp,sp,48
    8000466c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000466e:	0284a983          	lw	s3,40(s1)
    80004672:	ffffd097          	auipc	ra,0xffffd
    80004676:	396080e7          	jalr	918(ra) # 80001a08 <myproc>
    8000467a:	5904                	lw	s1,48(a0)
    8000467c:	413484b3          	sub	s1,s1,s3
    80004680:	0014b493          	seqz	s1,s1
    80004684:	bfc1                	j	80004654 <holdingsleep+0x24>

0000000080004686 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004686:	1141                	addi	sp,sp,-16
    80004688:	e406                	sd	ra,8(sp)
    8000468a:	e022                	sd	s0,0(sp)
    8000468c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000468e:	00004597          	auipc	a1,0x4
    80004692:	04a58593          	addi	a1,a1,74 # 800086d8 <syscalls+0x258>
    80004696:	0001d517          	auipc	a0,0x1d
    8000469a:	80250513          	addi	a0,a0,-2046 # 80020e98 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	504080e7          	jalr	1284(ra) # 80000ba2 <initlock>
}
    800046a6:	60a2                	ld	ra,8(sp)
    800046a8:	6402                	ld	s0,0(sp)
    800046aa:	0141                	addi	sp,sp,16
    800046ac:	8082                	ret

00000000800046ae <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046ae:	1101                	addi	sp,sp,-32
    800046b0:	ec06                	sd	ra,24(sp)
    800046b2:	e822                	sd	s0,16(sp)
    800046b4:	e426                	sd	s1,8(sp)
    800046b6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046b8:	0001c517          	auipc	a0,0x1c
    800046bc:	7e050513          	addi	a0,a0,2016 # 80020e98 <ftable>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	572080e7          	jalr	1394(ra) # 80000c32 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c8:	0001c497          	auipc	s1,0x1c
    800046cc:	7e848493          	addi	s1,s1,2024 # 80020eb0 <ftable+0x18>
    800046d0:	0001d717          	auipc	a4,0x1d
    800046d4:	78070713          	addi	a4,a4,1920 # 80021e50 <disk>
    if(f->ref == 0){
    800046d8:	40dc                	lw	a5,4(s1)
    800046da:	cf99                	beqz	a5,800046f8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046dc:	02848493          	addi	s1,s1,40
    800046e0:	fee49ce3          	bne	s1,a4,800046d8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046e4:	0001c517          	auipc	a0,0x1c
    800046e8:	7b450513          	addi	a0,a0,1972 # 80020e98 <ftable>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	5fa080e7          	jalr	1530(ra) # 80000ce6 <release>
  return 0;
    800046f4:	4481                	li	s1,0
    800046f6:	a819                	j	8000470c <filealloc+0x5e>
      f->ref = 1;
    800046f8:	4785                	li	a5,1
    800046fa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046fc:	0001c517          	auipc	a0,0x1c
    80004700:	79c50513          	addi	a0,a0,1948 # 80020e98 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	5e2080e7          	jalr	1506(ra) # 80000ce6 <release>
}
    8000470c:	8526                	mv	a0,s1
    8000470e:	60e2                	ld	ra,24(sp)
    80004710:	6442                	ld	s0,16(sp)
    80004712:	64a2                	ld	s1,8(sp)
    80004714:	6105                	addi	sp,sp,32
    80004716:	8082                	ret

0000000080004718 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004718:	1101                	addi	sp,sp,-32
    8000471a:	ec06                	sd	ra,24(sp)
    8000471c:	e822                	sd	s0,16(sp)
    8000471e:	e426                	sd	s1,8(sp)
    80004720:	1000                	addi	s0,sp,32
    80004722:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004724:	0001c517          	auipc	a0,0x1c
    80004728:	77450513          	addi	a0,a0,1908 # 80020e98 <ftable>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	506080e7          	jalr	1286(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    80004734:	40dc                	lw	a5,4(s1)
    80004736:	02f05263          	blez	a5,8000475a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000473a:	2785                	addiw	a5,a5,1
    8000473c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000473e:	0001c517          	auipc	a0,0x1c
    80004742:	75a50513          	addi	a0,a0,1882 # 80020e98 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	5a0080e7          	jalr	1440(ra) # 80000ce6 <release>
  return f;
}
    8000474e:	8526                	mv	a0,s1
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6105                	addi	sp,sp,32
    80004758:	8082                	ret
    panic("filedup");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	f8650513          	addi	a0,a0,-122 # 800086e0 <syscalls+0x260>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	ddc080e7          	jalr	-548(ra) # 8000053e <panic>

000000008000476a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000476a:	7139                	addi	sp,sp,-64
    8000476c:	fc06                	sd	ra,56(sp)
    8000476e:	f822                	sd	s0,48(sp)
    80004770:	f426                	sd	s1,40(sp)
    80004772:	f04a                	sd	s2,32(sp)
    80004774:	ec4e                	sd	s3,24(sp)
    80004776:	e852                	sd	s4,16(sp)
    80004778:	e456                	sd	s5,8(sp)
    8000477a:	0080                	addi	s0,sp,64
    8000477c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000477e:	0001c517          	auipc	a0,0x1c
    80004782:	71a50513          	addi	a0,a0,1818 # 80020e98 <ftable>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	4ac080e7          	jalr	1196(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    8000478e:	40dc                	lw	a5,4(s1)
    80004790:	06f05163          	blez	a5,800047f2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004794:	37fd                	addiw	a5,a5,-1
    80004796:	0007871b          	sext.w	a4,a5
    8000479a:	c0dc                	sw	a5,4(s1)
    8000479c:	06e04363          	bgtz	a4,80004802 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047a0:	0004a903          	lw	s2,0(s1)
    800047a4:	0094ca83          	lbu	s5,9(s1)
    800047a8:	0104ba03          	ld	s4,16(s1)
    800047ac:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047b0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047b4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047b8:	0001c517          	auipc	a0,0x1c
    800047bc:	6e050513          	addi	a0,a0,1760 # 80020e98 <ftable>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	526080e7          	jalr	1318(ra) # 80000ce6 <release>

  if(ff.type == FD_PIPE){
    800047c8:	4785                	li	a5,1
    800047ca:	04f90d63          	beq	s2,a5,80004824 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047ce:	3979                	addiw	s2,s2,-2
    800047d0:	4785                	li	a5,1
    800047d2:	0527e063          	bltu	a5,s2,80004812 <fileclose+0xa8>
    begin_op();
    800047d6:	00000097          	auipc	ra,0x0
    800047da:	ac8080e7          	jalr	-1336(ra) # 8000429e <begin_op>
    iput(ff.ip);
    800047de:	854e                	mv	a0,s3
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	2b6080e7          	jalr	694(ra) # 80003a96 <iput>
    end_op();
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	b36080e7          	jalr	-1226(ra) # 8000431e <end_op>
    800047f0:	a00d                	j	80004812 <fileclose+0xa8>
    panic("fileclose");
    800047f2:	00004517          	auipc	a0,0x4
    800047f6:	ef650513          	addi	a0,a0,-266 # 800086e8 <syscalls+0x268>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	d44080e7          	jalr	-700(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004802:	0001c517          	auipc	a0,0x1c
    80004806:	69650513          	addi	a0,a0,1686 # 80020e98 <ftable>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	4dc080e7          	jalr	1244(ra) # 80000ce6 <release>
  }
}
    80004812:	70e2                	ld	ra,56(sp)
    80004814:	7442                	ld	s0,48(sp)
    80004816:	74a2                	ld	s1,40(sp)
    80004818:	7902                	ld	s2,32(sp)
    8000481a:	69e2                	ld	s3,24(sp)
    8000481c:	6a42                	ld	s4,16(sp)
    8000481e:	6aa2                	ld	s5,8(sp)
    80004820:	6121                	addi	sp,sp,64
    80004822:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004824:	85d6                	mv	a1,s5
    80004826:	8552                	mv	a0,s4
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	34c080e7          	jalr	844(ra) # 80004b74 <pipeclose>
    80004830:	b7cd                	j	80004812 <fileclose+0xa8>

0000000080004832 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004832:	715d                	addi	sp,sp,-80
    80004834:	e486                	sd	ra,72(sp)
    80004836:	e0a2                	sd	s0,64(sp)
    80004838:	fc26                	sd	s1,56(sp)
    8000483a:	f84a                	sd	s2,48(sp)
    8000483c:	f44e                	sd	s3,40(sp)
    8000483e:	0880                	addi	s0,sp,80
    80004840:	84aa                	mv	s1,a0
    80004842:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004844:	ffffd097          	auipc	ra,0xffffd
    80004848:	1c4080e7          	jalr	452(ra) # 80001a08 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000484c:	409c                	lw	a5,0(s1)
    8000484e:	37f9                	addiw	a5,a5,-2
    80004850:	4705                	li	a4,1
    80004852:	04f76763          	bltu	a4,a5,800048a0 <filestat+0x6e>
    80004856:	892a                	mv	s2,a0
    ilock(f->ip);
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	082080e7          	jalr	130(ra) # 800038dc <ilock>
    stati(f->ip, &st);
    80004862:	fb840593          	addi	a1,s0,-72
    80004866:	6c88                	ld	a0,24(s1)
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	2fe080e7          	jalr	766(ra) # 80003b66 <stati>
    iunlock(f->ip);
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	12c080e7          	jalr	300(ra) # 8000399e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000487a:	46e1                	li	a3,24
    8000487c:	fb840613          	addi	a2,s0,-72
    80004880:	85ce                	mv	a1,s3
    80004882:	05093503          	ld	a0,80(s2)
    80004886:	ffffd097          	auipc	ra,0xffffd
    8000488a:	e3e080e7          	jalr	-450(ra) # 800016c4 <copyout>
    8000488e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004892:	60a6                	ld	ra,72(sp)
    80004894:	6406                	ld	s0,64(sp)
    80004896:	74e2                	ld	s1,56(sp)
    80004898:	7942                	ld	s2,48(sp)
    8000489a:	79a2                	ld	s3,40(sp)
    8000489c:	6161                	addi	sp,sp,80
    8000489e:	8082                	ret
  return -1;
    800048a0:	557d                	li	a0,-1
    800048a2:	bfc5                	j	80004892 <filestat+0x60>

00000000800048a4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048a4:	7179                	addi	sp,sp,-48
    800048a6:	f406                	sd	ra,40(sp)
    800048a8:	f022                	sd	s0,32(sp)
    800048aa:	ec26                	sd	s1,24(sp)
    800048ac:	e84a                	sd	s2,16(sp)
    800048ae:	e44e                	sd	s3,8(sp)
    800048b0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048b2:	00854783          	lbu	a5,8(a0)
    800048b6:	c3d5                	beqz	a5,8000495a <fileread+0xb6>
    800048b8:	84aa                	mv	s1,a0
    800048ba:	89ae                	mv	s3,a1
    800048bc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048be:	411c                	lw	a5,0(a0)
    800048c0:	4705                	li	a4,1
    800048c2:	04e78963          	beq	a5,a4,80004914 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048c6:	470d                	li	a4,3
    800048c8:	04e78d63          	beq	a5,a4,80004922 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048cc:	4709                	li	a4,2
    800048ce:	06e79e63          	bne	a5,a4,8000494a <fileread+0xa6>
    ilock(f->ip);
    800048d2:	6d08                	ld	a0,24(a0)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	008080e7          	jalr	8(ra) # 800038dc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048dc:	874a                	mv	a4,s2
    800048de:	5094                	lw	a3,32(s1)
    800048e0:	864e                	mv	a2,s3
    800048e2:	4585                	li	a1,1
    800048e4:	6c88                	ld	a0,24(s1)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	2aa080e7          	jalr	682(ra) # 80003b90 <readi>
    800048ee:	892a                	mv	s2,a0
    800048f0:	00a05563          	blez	a0,800048fa <fileread+0x56>
      f->off += r;
    800048f4:	509c                	lw	a5,32(s1)
    800048f6:	9fa9                	addw	a5,a5,a0
    800048f8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048fa:	6c88                	ld	a0,24(s1)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	0a2080e7          	jalr	162(ra) # 8000399e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004904:	854a                	mv	a0,s2
    80004906:	70a2                	ld	ra,40(sp)
    80004908:	7402                	ld	s0,32(sp)
    8000490a:	64e2                	ld	s1,24(sp)
    8000490c:	6942                	ld	s2,16(sp)
    8000490e:	69a2                	ld	s3,8(sp)
    80004910:	6145                	addi	sp,sp,48
    80004912:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004914:	6908                	ld	a0,16(a0)
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	3c6080e7          	jalr	966(ra) # 80004cdc <piperead>
    8000491e:	892a                	mv	s2,a0
    80004920:	b7d5                	j	80004904 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004922:	02451783          	lh	a5,36(a0)
    80004926:	03079693          	slli	a3,a5,0x30
    8000492a:	92c1                	srli	a3,a3,0x30
    8000492c:	4725                	li	a4,9
    8000492e:	02d76863          	bltu	a4,a3,8000495e <fileread+0xba>
    80004932:	0792                	slli	a5,a5,0x4
    80004934:	0001c717          	auipc	a4,0x1c
    80004938:	4c470713          	addi	a4,a4,1220 # 80020df8 <devsw>
    8000493c:	97ba                	add	a5,a5,a4
    8000493e:	639c                	ld	a5,0(a5)
    80004940:	c38d                	beqz	a5,80004962 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004942:	4505                	li	a0,1
    80004944:	9782                	jalr	a5
    80004946:	892a                	mv	s2,a0
    80004948:	bf75                	j	80004904 <fileread+0x60>
    panic("fileread");
    8000494a:	00004517          	auipc	a0,0x4
    8000494e:	dae50513          	addi	a0,a0,-594 # 800086f8 <syscalls+0x278>
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	bec080e7          	jalr	-1044(ra) # 8000053e <panic>
    return -1;
    8000495a:	597d                	li	s2,-1
    8000495c:	b765                	j	80004904 <fileread+0x60>
      return -1;
    8000495e:	597d                	li	s2,-1
    80004960:	b755                	j	80004904 <fileread+0x60>
    80004962:	597d                	li	s2,-1
    80004964:	b745                	j	80004904 <fileread+0x60>

0000000080004966 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004966:	715d                	addi	sp,sp,-80
    80004968:	e486                	sd	ra,72(sp)
    8000496a:	e0a2                	sd	s0,64(sp)
    8000496c:	fc26                	sd	s1,56(sp)
    8000496e:	f84a                	sd	s2,48(sp)
    80004970:	f44e                	sd	s3,40(sp)
    80004972:	f052                	sd	s4,32(sp)
    80004974:	ec56                	sd	s5,24(sp)
    80004976:	e85a                	sd	s6,16(sp)
    80004978:	e45e                	sd	s7,8(sp)
    8000497a:	e062                	sd	s8,0(sp)
    8000497c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000497e:	00954783          	lbu	a5,9(a0)
    80004982:	10078663          	beqz	a5,80004a8e <filewrite+0x128>
    80004986:	892a                	mv	s2,a0
    80004988:	8aae                	mv	s5,a1
    8000498a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000498c:	411c                	lw	a5,0(a0)
    8000498e:	4705                	li	a4,1
    80004990:	02e78263          	beq	a5,a4,800049b4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004994:	470d                	li	a4,3
    80004996:	02e78663          	beq	a5,a4,800049c2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000499a:	4709                	li	a4,2
    8000499c:	0ee79163          	bne	a5,a4,80004a7e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049a0:	0ac05d63          	blez	a2,80004a5a <filewrite+0xf4>
    int i = 0;
    800049a4:	4981                	li	s3,0
    800049a6:	6b05                	lui	s6,0x1
    800049a8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049ac:	6b85                	lui	s7,0x1
    800049ae:	c00b8b9b          	addiw	s7,s7,-1024
    800049b2:	a861                	j	80004a4a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049b4:	6908                	ld	a0,16(a0)
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	22e080e7          	jalr	558(ra) # 80004be4 <pipewrite>
    800049be:	8a2a                	mv	s4,a0
    800049c0:	a045                	j	80004a60 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049c2:	02451783          	lh	a5,36(a0)
    800049c6:	03079693          	slli	a3,a5,0x30
    800049ca:	92c1                	srli	a3,a3,0x30
    800049cc:	4725                	li	a4,9
    800049ce:	0cd76263          	bltu	a4,a3,80004a92 <filewrite+0x12c>
    800049d2:	0792                	slli	a5,a5,0x4
    800049d4:	0001c717          	auipc	a4,0x1c
    800049d8:	42470713          	addi	a4,a4,1060 # 80020df8 <devsw>
    800049dc:	97ba                	add	a5,a5,a4
    800049de:	679c                	ld	a5,8(a5)
    800049e0:	cbdd                	beqz	a5,80004a96 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049e2:	4505                	li	a0,1
    800049e4:	9782                	jalr	a5
    800049e6:	8a2a                	mv	s4,a0
    800049e8:	a8a5                	j	80004a60 <filewrite+0xfa>
    800049ea:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	8b0080e7          	jalr	-1872(ra) # 8000429e <begin_op>
      ilock(f->ip);
    800049f6:	01893503          	ld	a0,24(s2)
    800049fa:	fffff097          	auipc	ra,0xfffff
    800049fe:	ee2080e7          	jalr	-286(ra) # 800038dc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a02:	8762                	mv	a4,s8
    80004a04:	02092683          	lw	a3,32(s2)
    80004a08:	01598633          	add	a2,s3,s5
    80004a0c:	4585                	li	a1,1
    80004a0e:	01893503          	ld	a0,24(s2)
    80004a12:	fffff097          	auipc	ra,0xfffff
    80004a16:	276080e7          	jalr	630(ra) # 80003c88 <writei>
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	00a05763          	blez	a0,80004a2a <filewrite+0xc4>
        f->off += r;
    80004a20:	02092783          	lw	a5,32(s2)
    80004a24:	9fa9                	addw	a5,a5,a0
    80004a26:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a2a:	01893503          	ld	a0,24(s2)
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	f70080e7          	jalr	-144(ra) # 8000399e <iunlock>
      end_op();
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	8e8080e7          	jalr	-1816(ra) # 8000431e <end_op>

      if(r != n1){
    80004a3e:	009c1f63          	bne	s8,s1,80004a5c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a42:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a46:	0149db63          	bge	s3,s4,80004a5c <filewrite+0xf6>
      int n1 = n - i;
    80004a4a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a4e:	84be                	mv	s1,a5
    80004a50:	2781                	sext.w	a5,a5
    80004a52:	f8fb5ce3          	bge	s6,a5,800049ea <filewrite+0x84>
    80004a56:	84de                	mv	s1,s7
    80004a58:	bf49                	j	800049ea <filewrite+0x84>
    int i = 0;
    80004a5a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a5c:	013a1f63          	bne	s4,s3,80004a7a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a60:	8552                	mv	a0,s4
    80004a62:	60a6                	ld	ra,72(sp)
    80004a64:	6406                	ld	s0,64(sp)
    80004a66:	74e2                	ld	s1,56(sp)
    80004a68:	7942                	ld	s2,48(sp)
    80004a6a:	79a2                	ld	s3,40(sp)
    80004a6c:	7a02                	ld	s4,32(sp)
    80004a6e:	6ae2                	ld	s5,24(sp)
    80004a70:	6b42                	ld	s6,16(sp)
    80004a72:	6ba2                	ld	s7,8(sp)
    80004a74:	6c02                	ld	s8,0(sp)
    80004a76:	6161                	addi	sp,sp,80
    80004a78:	8082                	ret
    ret = (i == n ? n : -1);
    80004a7a:	5a7d                	li	s4,-1
    80004a7c:	b7d5                	j	80004a60 <filewrite+0xfa>
    panic("filewrite");
    80004a7e:	00004517          	auipc	a0,0x4
    80004a82:	c8a50513          	addi	a0,a0,-886 # 80008708 <syscalls+0x288>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
    return -1;
    80004a8e:	5a7d                	li	s4,-1
    80004a90:	bfc1                	j	80004a60 <filewrite+0xfa>
      return -1;
    80004a92:	5a7d                	li	s4,-1
    80004a94:	b7f1                	j	80004a60 <filewrite+0xfa>
    80004a96:	5a7d                	li	s4,-1
    80004a98:	b7e1                	j	80004a60 <filewrite+0xfa>

0000000080004a9a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a9a:	7179                	addi	sp,sp,-48
    80004a9c:	f406                	sd	ra,40(sp)
    80004a9e:	f022                	sd	s0,32(sp)
    80004aa0:	ec26                	sd	s1,24(sp)
    80004aa2:	e84a                	sd	s2,16(sp)
    80004aa4:	e44e                	sd	s3,8(sp)
    80004aa6:	e052                	sd	s4,0(sp)
    80004aa8:	1800                	addi	s0,sp,48
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aae:	0005b023          	sd	zero,0(a1)
    80004ab2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	bf8080e7          	jalr	-1032(ra) # 800046ae <filealloc>
    80004abe:	e088                	sd	a0,0(s1)
    80004ac0:	c551                	beqz	a0,80004b4c <pipealloc+0xb2>
    80004ac2:	00000097          	auipc	ra,0x0
    80004ac6:	bec080e7          	jalr	-1044(ra) # 800046ae <filealloc>
    80004aca:	00aa3023          	sd	a0,0(s4)
    80004ace:	c92d                	beqz	a0,80004b40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	016080e7          	jalr	22(ra) # 80000ae6 <kalloc>
    80004ad8:	892a                	mv	s2,a0
    80004ada:	c125                	beqz	a0,80004b3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004adc:	4985                	li	s3,1
    80004ade:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ae2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ae6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aee:	00004597          	auipc	a1,0x4
    80004af2:	c2a58593          	addi	a1,a1,-982 # 80008718 <syscalls+0x298>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	0ac080e7          	jalr	172(ra) # 80000ba2 <initlock>
  (*f0)->type = FD_PIPE;
    80004afe:	609c                	ld	a5,0(s1)
    80004b00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b04:	609c                	ld	a5,0(s1)
    80004b06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b0a:	609c                	ld	a5,0(s1)
    80004b0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b10:	609c                	ld	a5,0(s1)
    80004b12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b1e:	000a3783          	ld	a5,0(s4)
    80004b22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b26:	000a3783          	ld	a5,0(s4)
    80004b2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b2e:	000a3783          	ld	a5,0(s4)
    80004b32:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b36:	4501                	li	a0,0
    80004b38:	a025                	j	80004b60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b3a:	6088                	ld	a0,0(s1)
    80004b3c:	e501                	bnez	a0,80004b44 <pipealloc+0xaa>
    80004b3e:	a039                	j	80004b4c <pipealloc+0xb2>
    80004b40:	6088                	ld	a0,0(s1)
    80004b42:	c51d                	beqz	a0,80004b70 <pipealloc+0xd6>
    fileclose(*f0);
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	c26080e7          	jalr	-986(ra) # 8000476a <fileclose>
  if(*f1)
    80004b4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b50:	557d                	li	a0,-1
  if(*f1)
    80004b52:	c799                	beqz	a5,80004b60 <pipealloc+0xc6>
    fileclose(*f1);
    80004b54:	853e                	mv	a0,a5
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	c14080e7          	jalr	-1004(ra) # 8000476a <fileclose>
  return -1;
    80004b5e:	557d                	li	a0,-1
}
    80004b60:	70a2                	ld	ra,40(sp)
    80004b62:	7402                	ld	s0,32(sp)
    80004b64:	64e2                	ld	s1,24(sp)
    80004b66:	6942                	ld	s2,16(sp)
    80004b68:	69a2                	ld	s3,8(sp)
    80004b6a:	6a02                	ld	s4,0(sp)
    80004b6c:	6145                	addi	sp,sp,48
    80004b6e:	8082                	ret
  return -1;
    80004b70:	557d                	li	a0,-1
    80004b72:	b7fd                	j	80004b60 <pipealloc+0xc6>

0000000080004b74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b74:	1101                	addi	sp,sp,-32
    80004b76:	ec06                	sd	ra,24(sp)
    80004b78:	e822                	sd	s0,16(sp)
    80004b7a:	e426                	sd	s1,8(sp)
    80004b7c:	e04a                	sd	s2,0(sp)
    80004b7e:	1000                	addi	s0,sp,32
    80004b80:	84aa                	mv	s1,a0
    80004b82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	0ae080e7          	jalr	174(ra) # 80000c32 <acquire>
  if(writable){
    80004b8c:	02090d63          	beqz	s2,80004bc6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b94:	21848513          	addi	a0,s1,536
    80004b98:	ffffd097          	auipc	ra,0xffffd
    80004b9c:	588080e7          	jalr	1416(ra) # 80002120 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ba0:	2204b783          	ld	a5,544(s1)
    80004ba4:	eb95                	bnez	a5,80004bd8 <pipeclose+0x64>
    release(&pi->lock);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	13e080e7          	jalr	318(ra) # 80000ce6 <release>
    kfree((char*)pi);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	e38080e7          	jalr	-456(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004bba:	60e2                	ld	ra,24(sp)
    80004bbc:	6442                	ld	s0,16(sp)
    80004bbe:	64a2                	ld	s1,8(sp)
    80004bc0:	6902                	ld	s2,0(sp)
    80004bc2:	6105                	addi	sp,sp,32
    80004bc4:	8082                	ret
    pi->readopen = 0;
    80004bc6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bca:	21c48513          	addi	a0,s1,540
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	552080e7          	jalr	1362(ra) # 80002120 <wakeup>
    80004bd6:	b7e9                	j	80004ba0 <pipeclose+0x2c>
    release(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	10c080e7          	jalr	268(ra) # 80000ce6 <release>
}
    80004be2:	bfe1                	j	80004bba <pipeclose+0x46>

0000000080004be4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004be4:	711d                	addi	sp,sp,-96
    80004be6:	ec86                	sd	ra,88(sp)
    80004be8:	e8a2                	sd	s0,80(sp)
    80004bea:	e4a6                	sd	s1,72(sp)
    80004bec:	e0ca                	sd	s2,64(sp)
    80004bee:	fc4e                	sd	s3,56(sp)
    80004bf0:	f852                	sd	s4,48(sp)
    80004bf2:	f456                	sd	s5,40(sp)
    80004bf4:	f05a                	sd	s6,32(sp)
    80004bf6:	ec5e                	sd	s7,24(sp)
    80004bf8:	e862                	sd	s8,16(sp)
    80004bfa:	1080                	addi	s0,sp,96
    80004bfc:	84aa                	mv	s1,a0
    80004bfe:	8aae                	mv	s5,a1
    80004c00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	e06080e7          	jalr	-506(ra) # 80001a08 <myproc>
    80004c0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	024080e7          	jalr	36(ra) # 80000c32 <acquire>
  while(i < n){
    80004c16:	0b405663          	blez	s4,80004cc2 <pipewrite+0xde>
  int i = 0;
    80004c1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c1e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c22:	21c48b93          	addi	s7,s1,540
    80004c26:	a089                	j	80004c68 <pipewrite+0x84>
      release(&pi->lock);
    80004c28:	8526                	mv	a0,s1
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	0bc080e7          	jalr	188(ra) # 80000ce6 <release>
      return -1;
    80004c32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c34:	854a                	mv	a0,s2
    80004c36:	60e6                	ld	ra,88(sp)
    80004c38:	6446                	ld	s0,80(sp)
    80004c3a:	64a6                	ld	s1,72(sp)
    80004c3c:	6906                	ld	s2,64(sp)
    80004c3e:	79e2                	ld	s3,56(sp)
    80004c40:	7a42                	ld	s4,48(sp)
    80004c42:	7aa2                	ld	s5,40(sp)
    80004c44:	7b02                	ld	s6,32(sp)
    80004c46:	6be2                	ld	s7,24(sp)
    80004c48:	6c42                	ld	s8,16(sp)
    80004c4a:	6125                	addi	sp,sp,96
    80004c4c:	8082                	ret
      wakeup(&pi->nread);
    80004c4e:	8562                	mv	a0,s8
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	4d0080e7          	jalr	1232(ra) # 80002120 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c58:	85a6                	mv	a1,s1
    80004c5a:	855e                	mv	a0,s7
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	460080e7          	jalr	1120(ra) # 800020bc <sleep>
  while(i < n){
    80004c64:	07495063          	bge	s2,s4,80004cc4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c68:	2204a783          	lw	a5,544(s1)
    80004c6c:	dfd5                	beqz	a5,80004c28 <pipewrite+0x44>
    80004c6e:	854e                	mv	a0,s3
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	6f4080e7          	jalr	1780(ra) # 80002364 <killed>
    80004c78:	f945                	bnez	a0,80004c28 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c7a:	2184a783          	lw	a5,536(s1)
    80004c7e:	21c4a703          	lw	a4,540(s1)
    80004c82:	2007879b          	addiw	a5,a5,512
    80004c86:	fcf704e3          	beq	a4,a5,80004c4e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c8a:	4685                	li	a3,1
    80004c8c:	01590633          	add	a2,s2,s5
    80004c90:	faf40593          	addi	a1,s0,-81
    80004c94:	0509b503          	ld	a0,80(s3)
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	ab8080e7          	jalr	-1352(ra) # 80001750 <copyin>
    80004ca0:	03650263          	beq	a0,s6,80004cc4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ca4:	21c4a783          	lw	a5,540(s1)
    80004ca8:	0017871b          	addiw	a4,a5,1
    80004cac:	20e4ae23          	sw	a4,540(s1)
    80004cb0:	1ff7f793          	andi	a5,a5,511
    80004cb4:	97a6                	add	a5,a5,s1
    80004cb6:	faf44703          	lbu	a4,-81(s0)
    80004cba:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cbe:	2905                	addiw	s2,s2,1
    80004cc0:	b755                	j	80004c64 <pipewrite+0x80>
  int i = 0;
    80004cc2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cc4:	21848513          	addi	a0,s1,536
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	458080e7          	jalr	1112(ra) # 80002120 <wakeup>
  release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	014080e7          	jalr	20(ra) # 80000ce6 <release>
  return i;
    80004cda:	bfa9                	j	80004c34 <pipewrite+0x50>

0000000080004cdc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cdc:	715d                	addi	sp,sp,-80
    80004cde:	e486                	sd	ra,72(sp)
    80004ce0:	e0a2                	sd	s0,64(sp)
    80004ce2:	fc26                	sd	s1,56(sp)
    80004ce4:	f84a                	sd	s2,48(sp)
    80004ce6:	f44e                	sd	s3,40(sp)
    80004ce8:	f052                	sd	s4,32(sp)
    80004cea:	ec56                	sd	s5,24(sp)
    80004cec:	e85a                	sd	s6,16(sp)
    80004cee:	0880                	addi	s0,sp,80
    80004cf0:	84aa                	mv	s1,a0
    80004cf2:	892e                	mv	s2,a1
    80004cf4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	d12080e7          	jalr	-750(ra) # 80001a08 <myproc>
    80004cfe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d00:	8526                	mv	a0,s1
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	f30080e7          	jalr	-208(ra) # 80000c32 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d0a:	2184a703          	lw	a4,536(s1)
    80004d0e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d12:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d16:	02f71763          	bne	a4,a5,80004d44 <piperead+0x68>
    80004d1a:	2244a783          	lw	a5,548(s1)
    80004d1e:	c39d                	beqz	a5,80004d44 <piperead+0x68>
    if(killed(pr)){
    80004d20:	8552                	mv	a0,s4
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	642080e7          	jalr	1602(ra) # 80002364 <killed>
    80004d2a:	e941                	bnez	a0,80004dba <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d2c:	85a6                	mv	a1,s1
    80004d2e:	854e                	mv	a0,s3
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	38c080e7          	jalr	908(ra) # 800020bc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d38:	2184a703          	lw	a4,536(s1)
    80004d3c:	21c4a783          	lw	a5,540(s1)
    80004d40:	fcf70de3          	beq	a4,a5,80004d1a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d46:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d48:	05505363          	blez	s5,80004d8e <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d4c:	2184a783          	lw	a5,536(s1)
    80004d50:	21c4a703          	lw	a4,540(s1)
    80004d54:	02f70d63          	beq	a4,a5,80004d8e <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d58:	0017871b          	addiw	a4,a5,1
    80004d5c:	20e4ac23          	sw	a4,536(s1)
    80004d60:	1ff7f793          	andi	a5,a5,511
    80004d64:	97a6                	add	a5,a5,s1
    80004d66:	0187c783          	lbu	a5,24(a5)
    80004d6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d6e:	4685                	li	a3,1
    80004d70:	fbf40613          	addi	a2,s0,-65
    80004d74:	85ca                	mv	a1,s2
    80004d76:	050a3503          	ld	a0,80(s4)
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	94a080e7          	jalr	-1718(ra) # 800016c4 <copyout>
    80004d82:	01650663          	beq	a0,s6,80004d8e <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d86:	2985                	addiw	s3,s3,1
    80004d88:	0905                	addi	s2,s2,1
    80004d8a:	fd3a91e3          	bne	s5,s3,80004d4c <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d8e:	21c48513          	addi	a0,s1,540
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	38e080e7          	jalr	910(ra) # 80002120 <wakeup>
  release(&pi->lock);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	f4a080e7          	jalr	-182(ra) # 80000ce6 <release>
  return i;
}
    80004da4:	854e                	mv	a0,s3
    80004da6:	60a6                	ld	ra,72(sp)
    80004da8:	6406                	ld	s0,64(sp)
    80004daa:	74e2                	ld	s1,56(sp)
    80004dac:	7942                	ld	s2,48(sp)
    80004dae:	79a2                	ld	s3,40(sp)
    80004db0:	7a02                	ld	s4,32(sp)
    80004db2:	6ae2                	ld	s5,24(sp)
    80004db4:	6b42                	ld	s6,16(sp)
    80004db6:	6161                	addi	sp,sp,80
    80004db8:	8082                	ret
      release(&pi->lock);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	f2a080e7          	jalr	-214(ra) # 80000ce6 <release>
      return -1;
    80004dc4:	59fd                	li	s3,-1
    80004dc6:	bff9                	j	80004da4 <piperead+0xc8>

0000000080004dc8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dc8:	1141                	addi	sp,sp,-16
    80004dca:	e422                	sd	s0,8(sp)
    80004dcc:	0800                	addi	s0,sp,16
    80004dce:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dd0:	8905                	andi	a0,a0,1
    80004dd2:	c111                	beqz	a0,80004dd6 <flags2perm+0xe>
      perm = PTE_X;
    80004dd4:	4521                	li	a0,8
    if(flags & 0x2)
    80004dd6:	8b89                	andi	a5,a5,2
    80004dd8:	c399                	beqz	a5,80004dde <flags2perm+0x16>
      perm |= PTE_W;
    80004dda:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dde:	6422                	ld	s0,8(sp)
    80004de0:	0141                	addi	sp,sp,16
    80004de2:	8082                	ret

0000000080004de4 <exec>:

int
exec(char *path, char **argv)
{
    80004de4:	de010113          	addi	sp,sp,-544
    80004de8:	20113c23          	sd	ra,536(sp)
    80004dec:	20813823          	sd	s0,528(sp)
    80004df0:	20913423          	sd	s1,520(sp)
    80004df4:	21213023          	sd	s2,512(sp)
    80004df8:	ffce                	sd	s3,504(sp)
    80004dfa:	fbd2                	sd	s4,496(sp)
    80004dfc:	f7d6                	sd	s5,488(sp)
    80004dfe:	f3da                	sd	s6,480(sp)
    80004e00:	efde                	sd	s7,472(sp)
    80004e02:	ebe2                	sd	s8,464(sp)
    80004e04:	e7e6                	sd	s9,456(sp)
    80004e06:	e3ea                	sd	s10,448(sp)
    80004e08:	ff6e                	sd	s11,440(sp)
    80004e0a:	1400                	addi	s0,sp,544
    80004e0c:	892a                	mv	s2,a0
    80004e0e:	dea43423          	sd	a0,-536(s0)
    80004e12:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	bf2080e7          	jalr	-1038(ra) # 80001a08 <myproc>
    80004e1e:	84aa                	mv	s1,a0

  begin_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	47e080e7          	jalr	1150(ra) # 8000429e <begin_op>

  if((ip = namei(path)) == 0){
    80004e28:	854a                	mv	a0,s2
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	258080e7          	jalr	600(ra) # 80004082 <namei>
    80004e32:	c93d                	beqz	a0,80004ea8 <exec+0xc4>
    80004e34:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	aa6080e7          	jalr	-1370(ra) # 800038dc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e3e:	04000713          	li	a4,64
    80004e42:	4681                	li	a3,0
    80004e44:	e5040613          	addi	a2,s0,-432
    80004e48:	4581                	li	a1,0
    80004e4a:	8556                	mv	a0,s5
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	d44080e7          	jalr	-700(ra) # 80003b90 <readi>
    80004e54:	04000793          	li	a5,64
    80004e58:	00f51a63          	bne	a0,a5,80004e6c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e5c:	e5042703          	lw	a4,-432(s0)
    80004e60:	464c47b7          	lui	a5,0x464c4
    80004e64:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e68:	04f70663          	beq	a4,a5,80004eb4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e6c:	8556                	mv	a0,s5
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	cd0080e7          	jalr	-816(ra) # 80003b3e <iunlockput>
    end_op();
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	4a8080e7          	jalr	1192(ra) # 8000431e <end_op>
  }
  return -1;
    80004e7e:	557d                	li	a0,-1
}
    80004e80:	21813083          	ld	ra,536(sp)
    80004e84:	21013403          	ld	s0,528(sp)
    80004e88:	20813483          	ld	s1,520(sp)
    80004e8c:	20013903          	ld	s2,512(sp)
    80004e90:	79fe                	ld	s3,504(sp)
    80004e92:	7a5e                	ld	s4,496(sp)
    80004e94:	7abe                	ld	s5,488(sp)
    80004e96:	7b1e                	ld	s6,480(sp)
    80004e98:	6bfe                	ld	s7,472(sp)
    80004e9a:	6c5e                	ld	s8,464(sp)
    80004e9c:	6cbe                	ld	s9,456(sp)
    80004e9e:	6d1e                	ld	s10,448(sp)
    80004ea0:	7dfa                	ld	s11,440(sp)
    80004ea2:	22010113          	addi	sp,sp,544
    80004ea6:	8082                	ret
    end_op();
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	476080e7          	jalr	1142(ra) # 8000431e <end_op>
    return -1;
    80004eb0:	557d                	li	a0,-1
    80004eb2:	b7f9                	j	80004e80 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	c16080e7          	jalr	-1002(ra) # 80001acc <proc_pagetable>
    80004ebe:	8b2a                	mv	s6,a0
    80004ec0:	d555                	beqz	a0,80004e6c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec2:	e7042783          	lw	a5,-400(s0)
    80004ec6:	e8845703          	lhu	a4,-376(s0)
    80004eca:	c735                	beqz	a4,80004f36 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ecc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ece:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ed2:	6a05                	lui	s4,0x1
    80004ed4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ed8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004edc:	6d85                	lui	s11,0x1
    80004ede:	7d7d                	lui	s10,0xfffff
    80004ee0:	a481                	j	80005120 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ee2:	00004517          	auipc	a0,0x4
    80004ee6:	83e50513          	addi	a0,a0,-1986 # 80008720 <syscalls+0x2a0>
    80004eea:	ffffb097          	auipc	ra,0xffffb
    80004eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ef2:	874a                	mv	a4,s2
    80004ef4:	009c86bb          	addw	a3,s9,s1
    80004ef8:	4581                	li	a1,0
    80004efa:	8556                	mv	a0,s5
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	c94080e7          	jalr	-876(ra) # 80003b90 <readi>
    80004f04:	2501                	sext.w	a0,a0
    80004f06:	1aa91a63          	bne	s2,a0,800050ba <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f0a:	009d84bb          	addw	s1,s11,s1
    80004f0e:	013d09bb          	addw	s3,s10,s3
    80004f12:	1f74f763          	bgeu	s1,s7,80005100 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004f16:	02049593          	slli	a1,s1,0x20
    80004f1a:	9181                	srli	a1,a1,0x20
    80004f1c:	95e2                	add	a1,a1,s8
    80004f1e:	855a                	mv	a0,s6
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	198080e7          	jalr	408(ra) # 800010b8 <walkaddr>
    80004f28:	862a                	mv	a2,a0
    if(pa == 0)
    80004f2a:	dd45                	beqz	a0,80004ee2 <exec+0xfe>
      n = PGSIZE;
    80004f2c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f2e:	fd49f2e3          	bgeu	s3,s4,80004ef2 <exec+0x10e>
      n = sz - i;
    80004f32:	894e                	mv	s2,s3
    80004f34:	bf7d                	j	80004ef2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f36:	4901                	li	s2,0
  iunlockput(ip);
    80004f38:	8556                	mv	a0,s5
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	c04080e7          	jalr	-1020(ra) # 80003b3e <iunlockput>
  end_op();
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	3dc080e7          	jalr	988(ra) # 8000431e <end_op>
  p = myproc();
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	abe080e7          	jalr	-1346(ra) # 80001a08 <myproc>
    80004f52:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f54:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f58:	6785                	lui	a5,0x1
    80004f5a:	17fd                	addi	a5,a5,-1
    80004f5c:	993e                	add	s2,s2,a5
    80004f5e:	77fd                	lui	a5,0xfffff
    80004f60:	00f977b3          	and	a5,s2,a5
    80004f64:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f68:	4691                	li	a3,4
    80004f6a:	6609                	lui	a2,0x2
    80004f6c:	963e                	add	a2,a2,a5
    80004f6e:	85be                	mv	a1,a5
    80004f70:	855a                	mv	a0,s6
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	4fa080e7          	jalr	1274(ra) # 8000146c <uvmalloc>
    80004f7a:	8c2a                	mv	s8,a0
  ip = 0;
    80004f7c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f7e:	12050e63          	beqz	a0,800050ba <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f82:	75f9                	lui	a1,0xffffe
    80004f84:	95aa                	add	a1,a1,a0
    80004f86:	855a                	mv	a0,s6
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	70a080e7          	jalr	1802(ra) # 80001692 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f90:	7afd                	lui	s5,0xfffff
    80004f92:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f94:	df043783          	ld	a5,-528(s0)
    80004f98:	6388                	ld	a0,0(a5)
    80004f9a:	c925                	beqz	a0,8000500a <exec+0x226>
    80004f9c:	e9040993          	addi	s3,s0,-368
    80004fa0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fa4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fa6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	f02080e7          	jalr	-254(ra) # 80000eaa <strlen>
    80004fb0:	0015079b          	addiw	a5,a0,1
    80004fb4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fb8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fbc:	13596663          	bltu	s2,s5,800050e8 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fc0:	df043d83          	ld	s11,-528(s0)
    80004fc4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fc8:	8552                	mv	a0,s4
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	ee0080e7          	jalr	-288(ra) # 80000eaa <strlen>
    80004fd2:	0015069b          	addiw	a3,a0,1
    80004fd6:	8652                	mv	a2,s4
    80004fd8:	85ca                	mv	a1,s2
    80004fda:	855a                	mv	a0,s6
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	6e8080e7          	jalr	1768(ra) # 800016c4 <copyout>
    80004fe4:	10054663          	bltz	a0,800050f0 <exec+0x30c>
    ustack[argc] = sp;
    80004fe8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fec:	0485                	addi	s1,s1,1
    80004fee:	008d8793          	addi	a5,s11,8
    80004ff2:	def43823          	sd	a5,-528(s0)
    80004ff6:	008db503          	ld	a0,8(s11)
    80004ffa:	c911                	beqz	a0,8000500e <exec+0x22a>
    if(argc >= MAXARG)
    80004ffc:	09a1                	addi	s3,s3,8
    80004ffe:	fb3c95e3          	bne	s9,s3,80004fa8 <exec+0x1c4>
  sz = sz1;
    80005002:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005006:	4a81                	li	s5,0
    80005008:	a84d                	j	800050ba <exec+0x2d6>
  sp = sz;
    8000500a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000500c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000500e:	00349793          	slli	a5,s1,0x3
    80005012:	f9040713          	addi	a4,s0,-112
    80005016:	97ba                	add	a5,a5,a4
    80005018:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcf70>
  sp -= (argc+1) * sizeof(uint64);
    8000501c:	00148693          	addi	a3,s1,1
    80005020:	068e                	slli	a3,a3,0x3
    80005022:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005026:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000502a:	01597663          	bgeu	s2,s5,80005036 <exec+0x252>
  sz = sz1;
    8000502e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005032:	4a81                	li	s5,0
    80005034:	a059                	j	800050ba <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005036:	e9040613          	addi	a2,s0,-368
    8000503a:	85ca                	mv	a1,s2
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	686080e7          	jalr	1670(ra) # 800016c4 <copyout>
    80005046:	0a054963          	bltz	a0,800050f8 <exec+0x314>
  p->trapframe->a1 = sp;
    8000504a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000504e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005052:	de843783          	ld	a5,-536(s0)
    80005056:	0007c703          	lbu	a4,0(a5)
    8000505a:	cf11                	beqz	a4,80005076 <exec+0x292>
    8000505c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000505e:	02f00693          	li	a3,47
    80005062:	a039                	j	80005070 <exec+0x28c>
      last = s+1;
    80005064:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005068:	0785                	addi	a5,a5,1
    8000506a:	fff7c703          	lbu	a4,-1(a5)
    8000506e:	c701                	beqz	a4,80005076 <exec+0x292>
    if(*s == '/')
    80005070:	fed71ce3          	bne	a4,a3,80005068 <exec+0x284>
    80005074:	bfc5                	j	80005064 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005076:	4641                	li	a2,16
    80005078:	de843583          	ld	a1,-536(s0)
    8000507c:	158b8513          	addi	a0,s7,344
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	df8080e7          	jalr	-520(ra) # 80000e78 <safestrcpy>
  oldpagetable = p->pagetable;
    80005088:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000508c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005090:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005094:	058bb783          	ld	a5,88(s7)
    80005098:	e6843703          	ld	a4,-408(s0)
    8000509c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000509e:	058bb783          	ld	a5,88(s7)
    800050a2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050a6:	85ea                	mv	a1,s10
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	ac0080e7          	jalr	-1344(ra) # 80001b68 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050b0:	0004851b          	sext.w	a0,s1
    800050b4:	b3f1                	j	80004e80 <exec+0x9c>
    800050b6:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050ba:	df843583          	ld	a1,-520(s0)
    800050be:	855a                	mv	a0,s6
    800050c0:	ffffd097          	auipc	ra,0xffffd
    800050c4:	aa8080e7          	jalr	-1368(ra) # 80001b68 <proc_freepagetable>
  if(ip){
    800050c8:	da0a92e3          	bnez	s5,80004e6c <exec+0x88>
  return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	bb4d                	j	80004e80 <exec+0x9c>
    800050d0:	df243c23          	sd	s2,-520(s0)
    800050d4:	b7dd                	j	800050ba <exec+0x2d6>
    800050d6:	df243c23          	sd	s2,-520(s0)
    800050da:	b7c5                	j	800050ba <exec+0x2d6>
    800050dc:	df243c23          	sd	s2,-520(s0)
    800050e0:	bfe9                	j	800050ba <exec+0x2d6>
    800050e2:	df243c23          	sd	s2,-520(s0)
    800050e6:	bfd1                	j	800050ba <exec+0x2d6>
  sz = sz1;
    800050e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ec:	4a81                	li	s5,0
    800050ee:	b7f1                	j	800050ba <exec+0x2d6>
  sz = sz1;
    800050f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f4:	4a81                	li	s5,0
    800050f6:	b7d1                	j	800050ba <exec+0x2d6>
  sz = sz1;
    800050f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050fc:	4a81                	li	s5,0
    800050fe:	bf75                	j	800050ba <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005100:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005104:	e0843783          	ld	a5,-504(s0)
    80005108:	0017869b          	addiw	a3,a5,1
    8000510c:	e0d43423          	sd	a3,-504(s0)
    80005110:	e0043783          	ld	a5,-512(s0)
    80005114:	0387879b          	addiw	a5,a5,56
    80005118:	e8845703          	lhu	a4,-376(s0)
    8000511c:	e0e6dee3          	bge	a3,a4,80004f38 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005120:	2781                	sext.w	a5,a5
    80005122:	e0f43023          	sd	a5,-512(s0)
    80005126:	03800713          	li	a4,56
    8000512a:	86be                	mv	a3,a5
    8000512c:	e1840613          	addi	a2,s0,-488
    80005130:	4581                	li	a1,0
    80005132:	8556                	mv	a0,s5
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	a5c080e7          	jalr	-1444(ra) # 80003b90 <readi>
    8000513c:	03800793          	li	a5,56
    80005140:	f6f51be3          	bne	a0,a5,800050b6 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005144:	e1842783          	lw	a5,-488(s0)
    80005148:	4705                	li	a4,1
    8000514a:	fae79de3          	bne	a5,a4,80005104 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000514e:	e4043483          	ld	s1,-448(s0)
    80005152:	e3843783          	ld	a5,-456(s0)
    80005156:	f6f4ede3          	bltu	s1,a5,800050d0 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000515a:	e2843783          	ld	a5,-472(s0)
    8000515e:	94be                	add	s1,s1,a5
    80005160:	f6f4ebe3          	bltu	s1,a5,800050d6 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005164:	de043703          	ld	a4,-544(s0)
    80005168:	8ff9                	and	a5,a5,a4
    8000516a:	fbad                	bnez	a5,800050dc <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000516c:	e1c42503          	lw	a0,-484(s0)
    80005170:	00000097          	auipc	ra,0x0
    80005174:	c58080e7          	jalr	-936(ra) # 80004dc8 <flags2perm>
    80005178:	86aa                	mv	a3,a0
    8000517a:	8626                	mv	a2,s1
    8000517c:	85ca                	mv	a1,s2
    8000517e:	855a                	mv	a0,s6
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	2ec080e7          	jalr	748(ra) # 8000146c <uvmalloc>
    80005188:	dea43c23          	sd	a0,-520(s0)
    8000518c:	d939                	beqz	a0,800050e2 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000518e:	e2843c03          	ld	s8,-472(s0)
    80005192:	e2042c83          	lw	s9,-480(s0)
    80005196:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000519a:	f60b83e3          	beqz	s7,80005100 <exec+0x31c>
    8000519e:	89de                	mv	s3,s7
    800051a0:	4481                	li	s1,0
    800051a2:	bb95                	j	80004f16 <exec+0x132>

00000000800051a4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051a4:	7179                	addi	sp,sp,-48
    800051a6:	f406                	sd	ra,40(sp)
    800051a8:	f022                	sd	s0,32(sp)
    800051aa:	ec26                	sd	s1,24(sp)
    800051ac:	e84a                	sd	s2,16(sp)
    800051ae:	1800                	addi	s0,sp,48
    800051b0:	892e                	mv	s2,a1
    800051b2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051b4:	fdc40593          	addi	a1,s0,-36
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	ae4080e7          	jalr	-1308(ra) # 80002c9c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051c0:	fdc42703          	lw	a4,-36(s0)
    800051c4:	47bd                	li	a5,15
    800051c6:	02e7eb63          	bltu	a5,a4,800051fc <argfd+0x58>
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	83e080e7          	jalr	-1986(ra) # 80001a08 <myproc>
    800051d2:	fdc42703          	lw	a4,-36(s0)
    800051d6:	01a70793          	addi	a5,a4,26
    800051da:	078e                	slli	a5,a5,0x3
    800051dc:	953e                	add	a0,a0,a5
    800051de:	611c                	ld	a5,0(a0)
    800051e0:	c385                	beqz	a5,80005200 <argfd+0x5c>
    return -1;
  if(pfd)
    800051e2:	00090463          	beqz	s2,800051ea <argfd+0x46>
    *pfd = fd;
    800051e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051ea:	4501                	li	a0,0
  if(pf)
    800051ec:	c091                	beqz	s1,800051f0 <argfd+0x4c>
    *pf = f;
    800051ee:	e09c                	sd	a5,0(s1)
}
    800051f0:	70a2                	ld	ra,40(sp)
    800051f2:	7402                	ld	s0,32(sp)
    800051f4:	64e2                	ld	s1,24(sp)
    800051f6:	6942                	ld	s2,16(sp)
    800051f8:	6145                	addi	sp,sp,48
    800051fa:	8082                	ret
    return -1;
    800051fc:	557d                	li	a0,-1
    800051fe:	bfcd                	j	800051f0 <argfd+0x4c>
    80005200:	557d                	li	a0,-1
    80005202:	b7fd                	j	800051f0 <argfd+0x4c>

0000000080005204 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005204:	1101                	addi	sp,sp,-32
    80005206:	ec06                	sd	ra,24(sp)
    80005208:	e822                	sd	s0,16(sp)
    8000520a:	e426                	sd	s1,8(sp)
    8000520c:	1000                	addi	s0,sp,32
    8000520e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	7f8080e7          	jalr	2040(ra) # 80001a08 <myproc>
    80005218:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000521a:	0d050793          	addi	a5,a0,208
    8000521e:	4501                	li	a0,0
    80005220:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005222:	6398                	ld	a4,0(a5)
    80005224:	cb19                	beqz	a4,8000523a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005226:	2505                	addiw	a0,a0,1
    80005228:	07a1                	addi	a5,a5,8
    8000522a:	fed51ce3          	bne	a0,a3,80005222 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000522e:	557d                	li	a0,-1
}
    80005230:	60e2                	ld	ra,24(sp)
    80005232:	6442                	ld	s0,16(sp)
    80005234:	64a2                	ld	s1,8(sp)
    80005236:	6105                	addi	sp,sp,32
    80005238:	8082                	ret
      p->ofile[fd] = f;
    8000523a:	01a50793          	addi	a5,a0,26
    8000523e:	078e                	slli	a5,a5,0x3
    80005240:	963e                	add	a2,a2,a5
    80005242:	e204                	sd	s1,0(a2)
      return fd;
    80005244:	b7f5                	j	80005230 <fdalloc+0x2c>

0000000080005246 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005246:	715d                	addi	sp,sp,-80
    80005248:	e486                	sd	ra,72(sp)
    8000524a:	e0a2                	sd	s0,64(sp)
    8000524c:	fc26                	sd	s1,56(sp)
    8000524e:	f84a                	sd	s2,48(sp)
    80005250:	f44e                	sd	s3,40(sp)
    80005252:	f052                	sd	s4,32(sp)
    80005254:	ec56                	sd	s5,24(sp)
    80005256:	e85a                	sd	s6,16(sp)
    80005258:	0880                	addi	s0,sp,80
    8000525a:	8b2e                	mv	s6,a1
    8000525c:	89b2                	mv	s3,a2
    8000525e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005260:	fb040593          	addi	a1,s0,-80
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	e3c080e7          	jalr	-452(ra) # 800040a0 <nameiparent>
    8000526c:	84aa                	mv	s1,a0
    8000526e:	14050f63          	beqz	a0,800053cc <create+0x186>
    return 0;

  ilock(dp);
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	66a080e7          	jalr	1642(ra) # 800038dc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000527a:	4601                	li	a2,0
    8000527c:	fb040593          	addi	a1,s0,-80
    80005280:	8526                	mv	a0,s1
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	b3e080e7          	jalr	-1218(ra) # 80003dc0 <dirlookup>
    8000528a:	8aaa                	mv	s5,a0
    8000528c:	c931                	beqz	a0,800052e0 <create+0x9a>
    iunlockput(dp);
    8000528e:	8526                	mv	a0,s1
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	8ae080e7          	jalr	-1874(ra) # 80003b3e <iunlockput>
    ilock(ip);
    80005298:	8556                	mv	a0,s5
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	642080e7          	jalr	1602(ra) # 800038dc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052a2:	000b059b          	sext.w	a1,s6
    800052a6:	4789                	li	a5,2
    800052a8:	02f59563          	bne	a1,a5,800052d2 <create+0x8c>
    800052ac:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0b4>
    800052b0:	37f9                	addiw	a5,a5,-2
    800052b2:	17c2                	slli	a5,a5,0x30
    800052b4:	93c1                	srli	a5,a5,0x30
    800052b6:	4705                	li	a4,1
    800052b8:	00f76d63          	bltu	a4,a5,800052d2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052bc:	8556                	mv	a0,s5
    800052be:	60a6                	ld	ra,72(sp)
    800052c0:	6406                	ld	s0,64(sp)
    800052c2:	74e2                	ld	s1,56(sp)
    800052c4:	7942                	ld	s2,48(sp)
    800052c6:	79a2                	ld	s3,40(sp)
    800052c8:	7a02                	ld	s4,32(sp)
    800052ca:	6ae2                	ld	s5,24(sp)
    800052cc:	6b42                	ld	s6,16(sp)
    800052ce:	6161                	addi	sp,sp,80
    800052d0:	8082                	ret
    iunlockput(ip);
    800052d2:	8556                	mv	a0,s5
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	86a080e7          	jalr	-1942(ra) # 80003b3e <iunlockput>
    return 0;
    800052dc:	4a81                	li	s5,0
    800052de:	bff9                	j	800052bc <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052e0:	85da                	mv	a1,s6
    800052e2:	4088                	lw	a0,0(s1)
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	45c080e7          	jalr	1116(ra) # 80003740 <ialloc>
    800052ec:	8a2a                	mv	s4,a0
    800052ee:	c539                	beqz	a0,8000533c <create+0xf6>
  ilock(ip);
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	5ec080e7          	jalr	1516(ra) # 800038dc <ilock>
  ip->major = major;
    800052f8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052fc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005300:	4905                	li	s2,1
    80005302:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005306:	8552                	mv	a0,s4
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	50a080e7          	jalr	1290(ra) # 80003812 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005310:	000b059b          	sext.w	a1,s6
    80005314:	03258b63          	beq	a1,s2,8000534a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005318:	004a2603          	lw	a2,4(s4)
    8000531c:	fb040593          	addi	a1,s0,-80
    80005320:	8526                	mv	a0,s1
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	cae080e7          	jalr	-850(ra) # 80003fd0 <dirlink>
    8000532a:	06054f63          	bltz	a0,800053a8 <create+0x162>
  iunlockput(dp);
    8000532e:	8526                	mv	a0,s1
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	80e080e7          	jalr	-2034(ra) # 80003b3e <iunlockput>
  return ip;
    80005338:	8ad2                	mv	s5,s4
    8000533a:	b749                	j	800052bc <create+0x76>
    iunlockput(dp);
    8000533c:	8526                	mv	a0,s1
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	800080e7          	jalr	-2048(ra) # 80003b3e <iunlockput>
    return 0;
    80005346:	8ad2                	mv	s5,s4
    80005348:	bf95                	j	800052bc <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000534a:	004a2603          	lw	a2,4(s4)
    8000534e:	00003597          	auipc	a1,0x3
    80005352:	3f258593          	addi	a1,a1,1010 # 80008740 <syscalls+0x2c0>
    80005356:	8552                	mv	a0,s4
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	c78080e7          	jalr	-904(ra) # 80003fd0 <dirlink>
    80005360:	04054463          	bltz	a0,800053a8 <create+0x162>
    80005364:	40d0                	lw	a2,4(s1)
    80005366:	00003597          	auipc	a1,0x3
    8000536a:	3e258593          	addi	a1,a1,994 # 80008748 <syscalls+0x2c8>
    8000536e:	8552                	mv	a0,s4
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	c60080e7          	jalr	-928(ra) # 80003fd0 <dirlink>
    80005378:	02054863          	bltz	a0,800053a8 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000537c:	004a2603          	lw	a2,4(s4)
    80005380:	fb040593          	addi	a1,s0,-80
    80005384:	8526                	mv	a0,s1
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	c4a080e7          	jalr	-950(ra) # 80003fd0 <dirlink>
    8000538e:	00054d63          	bltz	a0,800053a8 <create+0x162>
    dp->nlink++;  // for ".."
    80005392:	04a4d783          	lhu	a5,74(s1)
    80005396:	2785                	addiw	a5,a5,1
    80005398:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000539c:	8526                	mv	a0,s1
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	474080e7          	jalr	1140(ra) # 80003812 <iupdate>
    800053a6:	b761                	j	8000532e <create+0xe8>
  ip->nlink = 0;
    800053a8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053ac:	8552                	mv	a0,s4
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	464080e7          	jalr	1124(ra) # 80003812 <iupdate>
  iunlockput(ip);
    800053b6:	8552                	mv	a0,s4
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	786080e7          	jalr	1926(ra) # 80003b3e <iunlockput>
  iunlockput(dp);
    800053c0:	8526                	mv	a0,s1
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	77c080e7          	jalr	1916(ra) # 80003b3e <iunlockput>
  return 0;
    800053ca:	bdcd                	j	800052bc <create+0x76>
    return 0;
    800053cc:	8aaa                	mv	s5,a0
    800053ce:	b5fd                	j	800052bc <create+0x76>

00000000800053d0 <sys_dup>:
{
    800053d0:	7179                	addi	sp,sp,-48
    800053d2:	f406                	sd	ra,40(sp)
    800053d4:	f022                	sd	s0,32(sp)
    800053d6:	ec26                	sd	s1,24(sp)
    800053d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053da:	fd840613          	addi	a2,s0,-40
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	dc2080e7          	jalr	-574(ra) # 800051a4 <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ec:	02054363          	bltz	a0,80005412 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053f0:	fd843503          	ld	a0,-40(s0)
    800053f4:	00000097          	auipc	ra,0x0
    800053f8:	e10080e7          	jalr	-496(ra) # 80005204 <fdalloc>
    800053fc:	84aa                	mv	s1,a0
    return -1;
    800053fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005400:	00054963          	bltz	a0,80005412 <sys_dup+0x42>
  filedup(f);
    80005404:	fd843503          	ld	a0,-40(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	310080e7          	jalr	784(ra) # 80004718 <filedup>
  return fd;
    80005410:	87a6                	mv	a5,s1
}
    80005412:	853e                	mv	a0,a5
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	64e2                	ld	s1,24(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_read>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005426:	fd840593          	addi	a1,s0,-40
    8000542a:	4505                	li	a0,1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	890080e7          	jalr	-1904(ra) # 80002cbc <argaddr>
  argint(2, &n);
    80005434:	fe440593          	addi	a1,s0,-28
    80005438:	4509                	li	a0,2
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	862080e7          	jalr	-1950(ra) # 80002c9c <argint>
  if(argfd(0, 0, &f) < 0)
    80005442:	fe840613          	addi	a2,s0,-24
    80005446:	4581                	li	a1,0
    80005448:	4501                	li	a0,0
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	d5a080e7          	jalr	-678(ra) # 800051a4 <argfd>
    80005452:	87aa                	mv	a5,a0
    return -1;
    80005454:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005456:	0007cc63          	bltz	a5,8000546e <sys_read+0x50>
  return fileread(f, p, n);
    8000545a:	fe442603          	lw	a2,-28(s0)
    8000545e:	fd843583          	ld	a1,-40(s0)
    80005462:	fe843503          	ld	a0,-24(s0)
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	43e080e7          	jalr	1086(ra) # 800048a4 <fileread>
}
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	6145                	addi	sp,sp,48
    80005474:	8082                	ret

0000000080005476 <sys_write>:
{
    80005476:	7179                	addi	sp,sp,-48
    80005478:	f406                	sd	ra,40(sp)
    8000547a:	f022                	sd	s0,32(sp)
    8000547c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000547e:	fd840593          	addi	a1,s0,-40
    80005482:	4505                	li	a0,1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	838080e7          	jalr	-1992(ra) # 80002cbc <argaddr>
  argint(2, &n);
    8000548c:	fe440593          	addi	a1,s0,-28
    80005490:	4509                	li	a0,2
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	80a080e7          	jalr	-2038(ra) # 80002c9c <argint>
  if(argfd(0, 0, &f) < 0)
    8000549a:	fe840613          	addi	a2,s0,-24
    8000549e:	4581                	li	a1,0
    800054a0:	4501                	li	a0,0
    800054a2:	00000097          	auipc	ra,0x0
    800054a6:	d02080e7          	jalr	-766(ra) # 800051a4 <argfd>
    800054aa:	87aa                	mv	a5,a0
    return -1;
    800054ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054ae:	0007cc63          	bltz	a5,800054c6 <sys_write+0x50>
  return filewrite(f, p, n);
    800054b2:	fe442603          	lw	a2,-28(s0)
    800054b6:	fd843583          	ld	a1,-40(s0)
    800054ba:	fe843503          	ld	a0,-24(s0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	4a8080e7          	jalr	1192(ra) # 80004966 <filewrite>
}
    800054c6:	70a2                	ld	ra,40(sp)
    800054c8:	7402                	ld	s0,32(sp)
    800054ca:	6145                	addi	sp,sp,48
    800054cc:	8082                	ret

00000000800054ce <sys_close>:
{
    800054ce:	1101                	addi	sp,sp,-32
    800054d0:	ec06                	sd	ra,24(sp)
    800054d2:	e822                	sd	s0,16(sp)
    800054d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054d6:	fe040613          	addi	a2,s0,-32
    800054da:	fec40593          	addi	a1,s0,-20
    800054de:	4501                	li	a0,0
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	cc4080e7          	jalr	-828(ra) # 800051a4 <argfd>
    return -1;
    800054e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054ea:	02054463          	bltz	a0,80005512 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	51a080e7          	jalr	1306(ra) # 80001a08 <myproc>
    800054f6:	fec42783          	lw	a5,-20(s0)
    800054fa:	07e9                	addi	a5,a5,26
    800054fc:	078e                	slli	a5,a5,0x3
    800054fe:	97aa                	add	a5,a5,a0
    80005500:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005504:	fe043503          	ld	a0,-32(s0)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	262080e7          	jalr	610(ra) # 8000476a <fileclose>
  return 0;
    80005510:	4781                	li	a5,0
}
    80005512:	853e                	mv	a0,a5
    80005514:	60e2                	ld	ra,24(sp)
    80005516:	6442                	ld	s0,16(sp)
    80005518:	6105                	addi	sp,sp,32
    8000551a:	8082                	ret

000000008000551c <sys_fstat>:
{
    8000551c:	1101                	addi	sp,sp,-32
    8000551e:	ec06                	sd	ra,24(sp)
    80005520:	e822                	sd	s0,16(sp)
    80005522:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005524:	fe040593          	addi	a1,s0,-32
    80005528:	4505                	li	a0,1
    8000552a:	ffffd097          	auipc	ra,0xffffd
    8000552e:	792080e7          	jalr	1938(ra) # 80002cbc <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005532:	fe840613          	addi	a2,s0,-24
    80005536:	4581                	li	a1,0
    80005538:	4501                	li	a0,0
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	c6a080e7          	jalr	-918(ra) # 800051a4 <argfd>
    80005542:	87aa                	mv	a5,a0
    return -1;
    80005544:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005546:	0007ca63          	bltz	a5,8000555a <sys_fstat+0x3e>
  return filestat(f, st);
    8000554a:	fe043583          	ld	a1,-32(s0)
    8000554e:	fe843503          	ld	a0,-24(s0)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	2e0080e7          	jalr	736(ra) # 80004832 <filestat>
}
    8000555a:	60e2                	ld	ra,24(sp)
    8000555c:	6442                	ld	s0,16(sp)
    8000555e:	6105                	addi	sp,sp,32
    80005560:	8082                	ret

0000000080005562 <sys_link>:
{
    80005562:	7169                	addi	sp,sp,-304
    80005564:	f606                	sd	ra,296(sp)
    80005566:	f222                	sd	s0,288(sp)
    80005568:	ee26                	sd	s1,280(sp)
    8000556a:	ea4a                	sd	s2,272(sp)
    8000556c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000556e:	08000613          	li	a2,128
    80005572:	ed040593          	addi	a1,s0,-304
    80005576:	4501                	li	a0,0
    80005578:	ffffd097          	auipc	ra,0xffffd
    8000557c:	764080e7          	jalr	1892(ra) # 80002cdc <argstr>
    return -1;
    80005580:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005582:	10054e63          	bltz	a0,8000569e <sys_link+0x13c>
    80005586:	08000613          	li	a2,128
    8000558a:	f5040593          	addi	a1,s0,-176
    8000558e:	4505                	li	a0,1
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	74c080e7          	jalr	1868(ra) # 80002cdc <argstr>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000559a:	10054263          	bltz	a0,8000569e <sys_link+0x13c>
  begin_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	d00080e7          	jalr	-768(ra) # 8000429e <begin_op>
  if((ip = namei(old)) == 0){
    800055a6:	ed040513          	addi	a0,s0,-304
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	ad8080e7          	jalr	-1320(ra) # 80004082 <namei>
    800055b2:	84aa                	mv	s1,a0
    800055b4:	c551                	beqz	a0,80005640 <sys_link+0xde>
  ilock(ip);
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	326080e7          	jalr	806(ra) # 800038dc <ilock>
  if(ip->type == T_DIR){
    800055be:	04449703          	lh	a4,68(s1)
    800055c2:	4785                	li	a5,1
    800055c4:	08f70463          	beq	a4,a5,8000564c <sys_link+0xea>
  ip->nlink++;
    800055c8:	04a4d783          	lhu	a5,74(s1)
    800055cc:	2785                	addiw	a5,a5,1
    800055ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	23e080e7          	jalr	574(ra) # 80003812 <iupdate>
  iunlock(ip);
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	3c0080e7          	jalr	960(ra) # 8000399e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055e6:	fd040593          	addi	a1,s0,-48
    800055ea:	f5040513          	addi	a0,s0,-176
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	ab2080e7          	jalr	-1358(ra) # 800040a0 <nameiparent>
    800055f6:	892a                	mv	s2,a0
    800055f8:	c935                	beqz	a0,8000566c <sys_link+0x10a>
  ilock(dp);
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	2e2080e7          	jalr	738(ra) # 800038dc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005602:	00092703          	lw	a4,0(s2)
    80005606:	409c                	lw	a5,0(s1)
    80005608:	04f71d63          	bne	a4,a5,80005662 <sys_link+0x100>
    8000560c:	40d0                	lw	a2,4(s1)
    8000560e:	fd040593          	addi	a1,s0,-48
    80005612:	854a                	mv	a0,s2
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	9bc080e7          	jalr	-1604(ra) # 80003fd0 <dirlink>
    8000561c:	04054363          	bltz	a0,80005662 <sys_link+0x100>
  iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	51c080e7          	jalr	1308(ra) # 80003b3e <iunlockput>
  iput(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	46a080e7          	jalr	1130(ra) # 80003a96 <iput>
  end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	cea080e7          	jalr	-790(ra) # 8000431e <end_op>
  return 0;
    8000563c:	4781                	li	a5,0
    8000563e:	a085                	j	8000569e <sys_link+0x13c>
    end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	cde080e7          	jalr	-802(ra) # 8000431e <end_op>
    return -1;
    80005648:	57fd                	li	a5,-1
    8000564a:	a891                	j	8000569e <sys_link+0x13c>
    iunlockput(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	4f0080e7          	jalr	1264(ra) # 80003b3e <iunlockput>
    end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	cc8080e7          	jalr	-824(ra) # 8000431e <end_op>
    return -1;
    8000565e:	57fd                	li	a5,-1
    80005660:	a83d                	j	8000569e <sys_link+0x13c>
    iunlockput(dp);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	4da080e7          	jalr	1242(ra) # 80003b3e <iunlockput>
  ilock(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	26e080e7          	jalr	622(ra) # 800038dc <ilock>
  ip->nlink--;
    80005676:	04a4d783          	lhu	a5,74(s1)
    8000567a:	37fd                	addiw	a5,a5,-1
    8000567c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	190080e7          	jalr	400(ra) # 80003812 <iupdate>
  iunlockput(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	4b2080e7          	jalr	1202(ra) # 80003b3e <iunlockput>
  end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	c8a080e7          	jalr	-886(ra) # 8000431e <end_op>
  return -1;
    8000569c:	57fd                	li	a5,-1
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	70b2                	ld	ra,296(sp)
    800056a2:	7412                	ld	s0,288(sp)
    800056a4:	64f2                	ld	s1,280(sp)
    800056a6:	6952                	ld	s2,272(sp)
    800056a8:	6155                	addi	sp,sp,304
    800056aa:	8082                	ret

00000000800056ac <sys_unlink>:
{
    800056ac:	7151                	addi	sp,sp,-240
    800056ae:	f586                	sd	ra,232(sp)
    800056b0:	f1a2                	sd	s0,224(sp)
    800056b2:	eda6                	sd	s1,216(sp)
    800056b4:	e9ca                	sd	s2,208(sp)
    800056b6:	e5ce                	sd	s3,200(sp)
    800056b8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056ba:	08000613          	li	a2,128
    800056be:	f3040593          	addi	a1,s0,-208
    800056c2:	4501                	li	a0,0
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	618080e7          	jalr	1560(ra) # 80002cdc <argstr>
    800056cc:	18054163          	bltz	a0,8000584e <sys_unlink+0x1a2>
  begin_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	bce080e7          	jalr	-1074(ra) # 8000429e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056d8:	fb040593          	addi	a1,s0,-80
    800056dc:	f3040513          	addi	a0,s0,-208
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	9c0080e7          	jalr	-1600(ra) # 800040a0 <nameiparent>
    800056e8:	84aa                	mv	s1,a0
    800056ea:	c979                	beqz	a0,800057c0 <sys_unlink+0x114>
  ilock(dp);
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	1f0080e7          	jalr	496(ra) # 800038dc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056f4:	00003597          	auipc	a1,0x3
    800056f8:	04c58593          	addi	a1,a1,76 # 80008740 <syscalls+0x2c0>
    800056fc:	fb040513          	addi	a0,s0,-80
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	6a6080e7          	jalr	1702(ra) # 80003da6 <namecmp>
    80005708:	14050a63          	beqz	a0,8000585c <sys_unlink+0x1b0>
    8000570c:	00003597          	auipc	a1,0x3
    80005710:	03c58593          	addi	a1,a1,60 # 80008748 <syscalls+0x2c8>
    80005714:	fb040513          	addi	a0,s0,-80
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	68e080e7          	jalr	1678(ra) # 80003da6 <namecmp>
    80005720:	12050e63          	beqz	a0,8000585c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005724:	f2c40613          	addi	a2,s0,-212
    80005728:	fb040593          	addi	a1,s0,-80
    8000572c:	8526                	mv	a0,s1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	692080e7          	jalr	1682(ra) # 80003dc0 <dirlookup>
    80005736:	892a                	mv	s2,a0
    80005738:	12050263          	beqz	a0,8000585c <sys_unlink+0x1b0>
  ilock(ip);
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	1a0080e7          	jalr	416(ra) # 800038dc <ilock>
  if(ip->nlink < 1)
    80005744:	04a91783          	lh	a5,74(s2)
    80005748:	08f05263          	blez	a5,800057cc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000574c:	04491703          	lh	a4,68(s2)
    80005750:	4785                	li	a5,1
    80005752:	08f70563          	beq	a4,a5,800057dc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005756:	4641                	li	a2,16
    80005758:	4581                	li	a1,0
    8000575a:	fc040513          	addi	a0,s0,-64
    8000575e:	ffffb097          	auipc	ra,0xffffb
    80005762:	5d0080e7          	jalr	1488(ra) # 80000d2e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005766:	4741                	li	a4,16
    80005768:	f2c42683          	lw	a3,-212(s0)
    8000576c:	fc040613          	addi	a2,s0,-64
    80005770:	4581                	li	a1,0
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	514080e7          	jalr	1300(ra) # 80003c88 <writei>
    8000577c:	47c1                	li	a5,16
    8000577e:	0af51563          	bne	a0,a5,80005828 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005782:	04491703          	lh	a4,68(s2)
    80005786:	4785                	li	a5,1
    80005788:	0af70863          	beq	a4,a5,80005838 <sys_unlink+0x18c>
  iunlockput(dp);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	3b0080e7          	jalr	944(ra) # 80003b3e <iunlockput>
  ip->nlink--;
    80005796:	04a95783          	lhu	a5,74(s2)
    8000579a:	37fd                	addiw	a5,a5,-1
    8000579c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	070080e7          	jalr	112(ra) # 80003812 <iupdate>
  iunlockput(ip);
    800057aa:	854a                	mv	a0,s2
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	392080e7          	jalr	914(ra) # 80003b3e <iunlockput>
  end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	b6a080e7          	jalr	-1174(ra) # 8000431e <end_op>
  return 0;
    800057bc:	4501                	li	a0,0
    800057be:	a84d                	j	80005870 <sys_unlink+0x1c4>
    end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	b5e080e7          	jalr	-1186(ra) # 8000431e <end_op>
    return -1;
    800057c8:	557d                	li	a0,-1
    800057ca:	a05d                	j	80005870 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057cc:	00003517          	auipc	a0,0x3
    800057d0:	f8450513          	addi	a0,a0,-124 # 80008750 <syscalls+0x2d0>
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	d6a080e7          	jalr	-662(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057dc:	04c92703          	lw	a4,76(s2)
    800057e0:	02000793          	li	a5,32
    800057e4:	f6e7f9e3          	bgeu	a5,a4,80005756 <sys_unlink+0xaa>
    800057e8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ec:	4741                	li	a4,16
    800057ee:	86ce                	mv	a3,s3
    800057f0:	f1840613          	addi	a2,s0,-232
    800057f4:	4581                	li	a1,0
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	398080e7          	jalr	920(ra) # 80003b90 <readi>
    80005800:	47c1                	li	a5,16
    80005802:	00f51b63          	bne	a0,a5,80005818 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005806:	f1845783          	lhu	a5,-232(s0)
    8000580a:	e7a1                	bnez	a5,80005852 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000580c:	29c1                	addiw	s3,s3,16
    8000580e:	04c92783          	lw	a5,76(s2)
    80005812:	fcf9ede3          	bltu	s3,a5,800057ec <sys_unlink+0x140>
    80005816:	b781                	j	80005756 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005818:	00003517          	auipc	a0,0x3
    8000581c:	f5050513          	addi	a0,a0,-176 # 80008768 <syscalls+0x2e8>
    80005820:	ffffb097          	auipc	ra,0xffffb
    80005824:	d1e080e7          	jalr	-738(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005828:	00003517          	auipc	a0,0x3
    8000582c:	f5850513          	addi	a0,a0,-168 # 80008780 <syscalls+0x300>
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	d0e080e7          	jalr	-754(ra) # 8000053e <panic>
    dp->nlink--;
    80005838:	04a4d783          	lhu	a5,74(s1)
    8000583c:	37fd                	addiw	a5,a5,-1
    8000583e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	fce080e7          	jalr	-50(ra) # 80003812 <iupdate>
    8000584c:	b781                	j	8000578c <sys_unlink+0xe0>
    return -1;
    8000584e:	557d                	li	a0,-1
    80005850:	a005                	j	80005870 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	2ea080e7          	jalr	746(ra) # 80003b3e <iunlockput>
  iunlockput(dp);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	2e0080e7          	jalr	736(ra) # 80003b3e <iunlockput>
  end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	ab8080e7          	jalr	-1352(ra) # 8000431e <end_op>
  return -1;
    8000586e:	557d                	li	a0,-1
}
    80005870:	70ae                	ld	ra,232(sp)
    80005872:	740e                	ld	s0,224(sp)
    80005874:	64ee                	ld	s1,216(sp)
    80005876:	694e                	ld	s2,208(sp)
    80005878:	69ae                	ld	s3,200(sp)
    8000587a:	616d                	addi	sp,sp,240
    8000587c:	8082                	ret

000000008000587e <sys_open>:

uint64
sys_open(void)
{
    8000587e:	7131                	addi	sp,sp,-192
    80005880:	fd06                	sd	ra,184(sp)
    80005882:	f922                	sd	s0,176(sp)
    80005884:	f526                	sd	s1,168(sp)
    80005886:	f14a                	sd	s2,160(sp)
    80005888:	ed4e                	sd	s3,152(sp)
    8000588a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000588c:	f4c40593          	addi	a1,s0,-180
    80005890:	4505                	li	a0,1
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	40a080e7          	jalr	1034(ra) # 80002c9c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000589a:	08000613          	li	a2,128
    8000589e:	f5040593          	addi	a1,s0,-176
    800058a2:	4501                	li	a0,0
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	438080e7          	jalr	1080(ra) # 80002cdc <argstr>
    800058ac:	87aa                	mv	a5,a0
    return -1;
    800058ae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058b0:	0a07c963          	bltz	a5,80005962 <sys_open+0xe4>

  begin_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	9ea080e7          	jalr	-1558(ra) # 8000429e <begin_op>

  if(omode & O_CREATE){
    800058bc:	f4c42783          	lw	a5,-180(s0)
    800058c0:	2007f793          	andi	a5,a5,512
    800058c4:	cfc5                	beqz	a5,8000597c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058c6:	4681                	li	a3,0
    800058c8:	4601                	li	a2,0
    800058ca:	4589                	li	a1,2
    800058cc:	f5040513          	addi	a0,s0,-176
    800058d0:	00000097          	auipc	ra,0x0
    800058d4:	976080e7          	jalr	-1674(ra) # 80005246 <create>
    800058d8:	84aa                	mv	s1,a0
    if(ip == 0){
    800058da:	c959                	beqz	a0,80005970 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058dc:	04449703          	lh	a4,68(s1)
    800058e0:	478d                	li	a5,3
    800058e2:	00f71763          	bne	a4,a5,800058f0 <sys_open+0x72>
    800058e6:	0464d703          	lhu	a4,70(s1)
    800058ea:	47a5                	li	a5,9
    800058ec:	0ce7ed63          	bltu	a5,a4,800059c6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	dbe080e7          	jalr	-578(ra) # 800046ae <filealloc>
    800058f8:	89aa                	mv	s3,a0
    800058fa:	10050363          	beqz	a0,80005a00 <sys_open+0x182>
    800058fe:	00000097          	auipc	ra,0x0
    80005902:	906080e7          	jalr	-1786(ra) # 80005204 <fdalloc>
    80005906:	892a                	mv	s2,a0
    80005908:	0e054763          	bltz	a0,800059f6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000590c:	04449703          	lh	a4,68(s1)
    80005910:	478d                	li	a5,3
    80005912:	0cf70563          	beq	a4,a5,800059dc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005916:	4789                	li	a5,2
    80005918:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000591c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005920:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005924:	f4c42783          	lw	a5,-180(s0)
    80005928:	0017c713          	xori	a4,a5,1
    8000592c:	8b05                	andi	a4,a4,1
    8000592e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005932:	0037f713          	andi	a4,a5,3
    80005936:	00e03733          	snez	a4,a4
    8000593a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000593e:	4007f793          	andi	a5,a5,1024
    80005942:	c791                	beqz	a5,8000594e <sys_open+0xd0>
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	4789                	li	a5,2
    8000594a:	0af70063          	beq	a4,a5,800059ea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	04e080e7          	jalr	78(ra) # 8000399e <iunlock>
  end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	9c6080e7          	jalr	-1594(ra) # 8000431e <end_op>

  return fd;
    80005960:	854a                	mv	a0,s2
}
    80005962:	70ea                	ld	ra,184(sp)
    80005964:	744a                	ld	s0,176(sp)
    80005966:	74aa                	ld	s1,168(sp)
    80005968:	790a                	ld	s2,160(sp)
    8000596a:	69ea                	ld	s3,152(sp)
    8000596c:	6129                	addi	sp,sp,192
    8000596e:	8082                	ret
      end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	9ae080e7          	jalr	-1618(ra) # 8000431e <end_op>
      return -1;
    80005978:	557d                	li	a0,-1
    8000597a:	b7e5                	j	80005962 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000597c:	f5040513          	addi	a0,s0,-176
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	702080e7          	jalr	1794(ra) # 80004082 <namei>
    80005988:	84aa                	mv	s1,a0
    8000598a:	c905                	beqz	a0,800059ba <sys_open+0x13c>
    ilock(ip);
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	f50080e7          	jalr	-176(ra) # 800038dc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005994:	04449703          	lh	a4,68(s1)
    80005998:	4785                	li	a5,1
    8000599a:	f4f711e3          	bne	a4,a5,800058dc <sys_open+0x5e>
    8000599e:	f4c42783          	lw	a5,-180(s0)
    800059a2:	d7b9                	beqz	a5,800058f0 <sys_open+0x72>
      iunlockput(ip);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	198080e7          	jalr	408(ra) # 80003b3e <iunlockput>
      end_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	970080e7          	jalr	-1680(ra) # 8000431e <end_op>
      return -1;
    800059b6:	557d                	li	a0,-1
    800059b8:	b76d                	j	80005962 <sys_open+0xe4>
      end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	964080e7          	jalr	-1692(ra) # 8000431e <end_op>
      return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	bf79                	j	80005962 <sys_open+0xe4>
    iunlockput(ip);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	176080e7          	jalr	374(ra) # 80003b3e <iunlockput>
    end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	94e080e7          	jalr	-1714(ra) # 8000431e <end_op>
    return -1;
    800059d8:	557d                	li	a0,-1
    800059da:	b761                	j	80005962 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059dc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059e0:	04649783          	lh	a5,70(s1)
    800059e4:	02f99223          	sh	a5,36(s3)
    800059e8:	bf25                	j	80005920 <sys_open+0xa2>
    itrunc(ip);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	ffe080e7          	jalr	-2(ra) # 800039ea <itrunc>
    800059f4:	bfa9                	j	8000594e <sys_open+0xd0>
      fileclose(f);
    800059f6:	854e                	mv	a0,s3
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	d72080e7          	jalr	-654(ra) # 8000476a <fileclose>
    iunlockput(ip);
    80005a00:	8526                	mv	a0,s1
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	13c080e7          	jalr	316(ra) # 80003b3e <iunlockput>
    end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	914080e7          	jalr	-1772(ra) # 8000431e <end_op>
    return -1;
    80005a12:	557d                	li	a0,-1
    80005a14:	b7b9                	j	80005962 <sys_open+0xe4>

0000000080005a16 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a16:	7175                	addi	sp,sp,-144
    80005a18:	e506                	sd	ra,136(sp)
    80005a1a:	e122                	sd	s0,128(sp)
    80005a1c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	880080e7          	jalr	-1920(ra) # 8000429e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a26:	08000613          	li	a2,128
    80005a2a:	f7040593          	addi	a1,s0,-144
    80005a2e:	4501                	li	a0,0
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	2ac080e7          	jalr	684(ra) # 80002cdc <argstr>
    80005a38:	02054963          	bltz	a0,80005a6a <sys_mkdir+0x54>
    80005a3c:	4681                	li	a3,0
    80005a3e:	4601                	li	a2,0
    80005a40:	4585                	li	a1,1
    80005a42:	f7040513          	addi	a0,s0,-144
    80005a46:	00000097          	auipc	ra,0x0
    80005a4a:	800080e7          	jalr	-2048(ra) # 80005246 <create>
    80005a4e:	cd11                	beqz	a0,80005a6a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	0ee080e7          	jalr	238(ra) # 80003b3e <iunlockput>
  end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	8c6080e7          	jalr	-1850(ra) # 8000431e <end_op>
  return 0;
    80005a60:	4501                	li	a0,0
}
    80005a62:	60aa                	ld	ra,136(sp)
    80005a64:	640a                	ld	s0,128(sp)
    80005a66:	6149                	addi	sp,sp,144
    80005a68:	8082                	ret
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	8b4080e7          	jalr	-1868(ra) # 8000431e <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	b7fd                	j	80005a62 <sys_mkdir+0x4c>

0000000080005a76 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a76:	7135                	addi	sp,sp,-160
    80005a78:	ed06                	sd	ra,152(sp)
    80005a7a:	e922                	sd	s0,144(sp)
    80005a7c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	820080e7          	jalr	-2016(ra) # 8000429e <begin_op>
  argint(1, &major);
    80005a86:	f6c40593          	addi	a1,s0,-148
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	210080e7          	jalr	528(ra) # 80002c9c <argint>
  argint(2, &minor);
    80005a94:	f6840593          	addi	a1,s0,-152
    80005a98:	4509                	li	a0,2
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	202080e7          	jalr	514(ra) # 80002c9c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f7040593          	addi	a1,s0,-144
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	230080e7          	jalr	560(ra) # 80002cdc <argstr>
    80005ab4:	02054b63          	bltz	a0,80005aea <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab8:	f6841683          	lh	a3,-152(s0)
    80005abc:	f6c41603          	lh	a2,-148(s0)
    80005ac0:	458d                	li	a1,3
    80005ac2:	f7040513          	addi	a0,s0,-144
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	780080e7          	jalr	1920(ra) # 80005246 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ace:	cd11                	beqz	a0,80005aea <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	06e080e7          	jalr	110(ra) # 80003b3e <iunlockput>
  end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	846080e7          	jalr	-1978(ra) # 8000431e <end_op>
  return 0;
    80005ae0:	4501                	li	a0,0
}
    80005ae2:	60ea                	ld	ra,152(sp)
    80005ae4:	644a                	ld	s0,144(sp)
    80005ae6:	610d                	addi	sp,sp,160
    80005ae8:	8082                	ret
    end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	834080e7          	jalr	-1996(ra) # 8000431e <end_op>
    return -1;
    80005af2:	557d                	li	a0,-1
    80005af4:	b7fd                	j	80005ae2 <sys_mknod+0x6c>

0000000080005af6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af6:	7135                	addi	sp,sp,-160
    80005af8:	ed06                	sd	ra,152(sp)
    80005afa:	e922                	sd	s0,144(sp)
    80005afc:	e526                	sd	s1,136(sp)
    80005afe:	e14a                	sd	s2,128(sp)
    80005b00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b02:	ffffc097          	auipc	ra,0xffffc
    80005b06:	f06080e7          	jalr	-250(ra) # 80001a08 <myproc>
    80005b0a:	892a                	mv	s2,a0
  
  begin_op();
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	792080e7          	jalr	1938(ra) # 8000429e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b14:	08000613          	li	a2,128
    80005b18:	f6040593          	addi	a1,s0,-160
    80005b1c:	4501                	li	a0,0
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	1be080e7          	jalr	446(ra) # 80002cdc <argstr>
    80005b26:	04054b63          	bltz	a0,80005b7c <sys_chdir+0x86>
    80005b2a:	f6040513          	addi	a0,s0,-160
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	554080e7          	jalr	1364(ra) # 80004082 <namei>
    80005b36:	84aa                	mv	s1,a0
    80005b38:	c131                	beqz	a0,80005b7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	da2080e7          	jalr	-606(ra) # 800038dc <ilock>
  if(ip->type != T_DIR){
    80005b42:	04449703          	lh	a4,68(s1)
    80005b46:	4785                	li	a5,1
    80005b48:	04f71063          	bne	a4,a5,80005b88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b4c:	8526                	mv	a0,s1
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	e50080e7          	jalr	-432(ra) # 8000399e <iunlock>
  iput(p->cwd);
    80005b56:	15093503          	ld	a0,336(s2)
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	f3c080e7          	jalr	-196(ra) # 80003a96 <iput>
  end_op();
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	7bc080e7          	jalr	1980(ra) # 8000431e <end_op>
  p->cwd = ip;
    80005b6a:	14993823          	sd	s1,336(s2)
  return 0;
    80005b6e:	4501                	li	a0,0
}
    80005b70:	60ea                	ld	ra,152(sp)
    80005b72:	644a                	ld	s0,144(sp)
    80005b74:	64aa                	ld	s1,136(sp)
    80005b76:	690a                	ld	s2,128(sp)
    80005b78:	610d                	addi	sp,sp,160
    80005b7a:	8082                	ret
    end_op();
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	7a2080e7          	jalr	1954(ra) # 8000431e <end_op>
    return -1;
    80005b84:	557d                	li	a0,-1
    80005b86:	b7ed                	j	80005b70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	fb4080e7          	jalr	-76(ra) # 80003b3e <iunlockput>
    end_op();
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	78c080e7          	jalr	1932(ra) # 8000431e <end_op>
    return -1;
    80005b9a:	557d                	li	a0,-1
    80005b9c:	bfd1                	j	80005b70 <sys_chdir+0x7a>

0000000080005b9e <sys_exec>:

uint64
sys_exec(void)
{
    80005b9e:	7145                	addi	sp,sp,-464
    80005ba0:	e786                	sd	ra,456(sp)
    80005ba2:	e3a2                	sd	s0,448(sp)
    80005ba4:	ff26                	sd	s1,440(sp)
    80005ba6:	fb4a                	sd	s2,432(sp)
    80005ba8:	f74e                	sd	s3,424(sp)
    80005baa:	f352                	sd	s4,416(sp)
    80005bac:	ef56                	sd	s5,408(sp)
    80005bae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bb0:	e3840593          	addi	a1,s0,-456
    80005bb4:	4505                	li	a0,1
    80005bb6:	ffffd097          	auipc	ra,0xffffd
    80005bba:	106080e7          	jalr	262(ra) # 80002cbc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bbe:	08000613          	li	a2,128
    80005bc2:	f4040593          	addi	a1,s0,-192
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	114080e7          	jalr	276(ra) # 80002cdc <argstr>
    80005bd0:	87aa                	mv	a5,a0
    return -1;
    80005bd2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005bd4:	0c07c263          	bltz	a5,80005c98 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bd8:	10000613          	li	a2,256
    80005bdc:	4581                	li	a1,0
    80005bde:	e4040513          	addi	a0,s0,-448
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	14c080e7          	jalr	332(ra) # 80000d2e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bee:	89a6                	mv	s3,s1
    80005bf0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bf2:	02000a13          	li	s4,32
    80005bf6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bfa:	00391793          	slli	a5,s2,0x3
    80005bfe:	e3040593          	addi	a1,s0,-464
    80005c02:	e3843503          	ld	a0,-456(s0)
    80005c06:	953e                	add	a0,a0,a5
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	ff6080e7          	jalr	-10(ra) # 80002bfe <fetchaddr>
    80005c10:	02054a63          	bltz	a0,80005c44 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c14:	e3043783          	ld	a5,-464(s0)
    80005c18:	c3b9                	beqz	a5,80005c5e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	ecc080e7          	jalr	-308(ra) # 80000ae6 <kalloc>
    80005c22:	85aa                	mv	a1,a0
    80005c24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c28:	cd11                	beqz	a0,80005c44 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c2a:	6605                	lui	a2,0x1
    80005c2c:	e3043503          	ld	a0,-464(s0)
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	020080e7          	jalr	32(ra) # 80002c50 <fetchstr>
    80005c38:	00054663          	bltz	a0,80005c44 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c3c:	0905                	addi	s2,s2,1
    80005c3e:	09a1                	addi	s3,s3,8
    80005c40:	fb491be3          	bne	s2,s4,80005bf6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048913          	addi	s2,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c531                	beqz	a0,80005c96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	d9e080e7          	jalr	-610(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff2499e3          	bne	s1,s2,80005c48 <sys_exec+0xaa>
  return -1;
    80005c5a:	557d                	li	a0,-1
    80005c5c:	a835                	j	80005c98 <sys_exec+0xfa>
      argv[i] = 0;
    80005c5e:	0a8e                	slli	s5,s5,0x3
    80005c60:	fc040793          	addi	a5,s0,-64
    80005c64:	9abe                	add	s5,s5,a5
    80005c66:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c6a:	e4040593          	addi	a1,s0,-448
    80005c6e:	f4040513          	addi	a0,s0,-192
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	172080e7          	jalr	370(ra) # 80004de4 <exec>
    80005c7a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	10048993          	addi	s3,s1,256
    80005c80:	6088                	ld	a0,0(s1)
    80005c82:	c901                	beqz	a0,80005c92 <sys_exec+0xf4>
    kfree(argv[i]);
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	d66080e7          	jalr	-666(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	04a1                	addi	s1,s1,8
    80005c8e:	ff3499e3          	bne	s1,s3,80005c80 <sys_exec+0xe2>
  return ret;
    80005c92:	854a                	mv	a0,s2
    80005c94:	a011                	j	80005c98 <sys_exec+0xfa>
  return -1;
    80005c96:	557d                	li	a0,-1
}
    80005c98:	60be                	ld	ra,456(sp)
    80005c9a:	641e                	ld	s0,448(sp)
    80005c9c:	74fa                	ld	s1,440(sp)
    80005c9e:	795a                	ld	s2,432(sp)
    80005ca0:	79ba                	ld	s3,424(sp)
    80005ca2:	7a1a                	ld	s4,416(sp)
    80005ca4:	6afa                	ld	s5,408(sp)
    80005ca6:	6179                	addi	sp,sp,464
    80005ca8:	8082                	ret

0000000080005caa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005caa:	7139                	addi	sp,sp,-64
    80005cac:	fc06                	sd	ra,56(sp)
    80005cae:	f822                	sd	s0,48(sp)
    80005cb0:	f426                	sd	s1,40(sp)
    80005cb2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cb4:	ffffc097          	auipc	ra,0xffffc
    80005cb8:	d54080e7          	jalr	-684(ra) # 80001a08 <myproc>
    80005cbc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cbe:	fd840593          	addi	a1,s0,-40
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	ff8080e7          	jalr	-8(ra) # 80002cbc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ccc:	fc840593          	addi	a1,s0,-56
    80005cd0:	fd040513          	addi	a0,s0,-48
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	dc6080e7          	jalr	-570(ra) # 80004a9a <pipealloc>
    return -1;
    80005cdc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cde:	0c054463          	bltz	a0,80005da6 <sys_pipe+0xfc>
  fd0 = -1;
    80005ce2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ce6:	fd043503          	ld	a0,-48(s0)
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	51a080e7          	jalr	1306(ra) # 80005204 <fdalloc>
    80005cf2:	fca42223          	sw	a0,-60(s0)
    80005cf6:	08054b63          	bltz	a0,80005d8c <sys_pipe+0xe2>
    80005cfa:	fc843503          	ld	a0,-56(s0)
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	506080e7          	jalr	1286(ra) # 80005204 <fdalloc>
    80005d06:	fca42023          	sw	a0,-64(s0)
    80005d0a:	06054863          	bltz	a0,80005d7a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0e:	4691                	li	a3,4
    80005d10:	fc440613          	addi	a2,s0,-60
    80005d14:	fd843583          	ld	a1,-40(s0)
    80005d18:	68a8                	ld	a0,80(s1)
    80005d1a:	ffffc097          	auipc	ra,0xffffc
    80005d1e:	9aa080e7          	jalr	-1622(ra) # 800016c4 <copyout>
    80005d22:	02054063          	bltz	a0,80005d42 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d26:	4691                	li	a3,4
    80005d28:	fc040613          	addi	a2,s0,-64
    80005d2c:	fd843583          	ld	a1,-40(s0)
    80005d30:	0591                	addi	a1,a1,4
    80005d32:	68a8                	ld	a0,80(s1)
    80005d34:	ffffc097          	auipc	ra,0xffffc
    80005d38:	990080e7          	jalr	-1648(ra) # 800016c4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d3c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d3e:	06055463          	bgez	a0,80005da6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d42:	fc442783          	lw	a5,-60(s0)
    80005d46:	07e9                	addi	a5,a5,26
    80005d48:	078e                	slli	a5,a5,0x3
    80005d4a:	97a6                	add	a5,a5,s1
    80005d4c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d50:	fc042503          	lw	a0,-64(s0)
    80005d54:	0569                	addi	a0,a0,26
    80005d56:	050e                	slli	a0,a0,0x3
    80005d58:	94aa                	add	s1,s1,a0
    80005d5a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d5e:	fd043503          	ld	a0,-48(s0)
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	a08080e7          	jalr	-1528(ra) # 8000476a <fileclose>
    fileclose(wf);
    80005d6a:	fc843503          	ld	a0,-56(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	9fc080e7          	jalr	-1540(ra) # 8000476a <fileclose>
    return -1;
    80005d76:	57fd                	li	a5,-1
    80005d78:	a03d                	j	80005da6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d7a:	fc442783          	lw	a5,-60(s0)
    80005d7e:	0007c763          	bltz	a5,80005d8c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d82:	07e9                	addi	a5,a5,26
    80005d84:	078e                	slli	a5,a5,0x3
    80005d86:	94be                	add	s1,s1,a5
    80005d88:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d8c:	fd043503          	ld	a0,-48(s0)
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	9da080e7          	jalr	-1574(ra) # 8000476a <fileclose>
    fileclose(wf);
    80005d98:	fc843503          	ld	a0,-56(s0)
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	9ce080e7          	jalr	-1586(ra) # 8000476a <fileclose>
    return -1;
    80005da4:	57fd                	li	a5,-1
}
    80005da6:	853e                	mv	a0,a5
    80005da8:	70e2                	ld	ra,56(sp)
    80005daa:	7442                	ld	s0,48(sp)
    80005dac:	74a2                	ld	s1,40(sp)
    80005dae:	6121                	addi	sp,sp,64
    80005db0:	8082                	ret
	...

0000000080005dc0 <kernelvec>:
    80005dc0:	7111                	addi	sp,sp,-256
    80005dc2:	e006                	sd	ra,0(sp)
    80005dc4:	e40a                	sd	sp,8(sp)
    80005dc6:	e80e                	sd	gp,16(sp)
    80005dc8:	ec12                	sd	tp,24(sp)
    80005dca:	f016                	sd	t0,32(sp)
    80005dcc:	f41a                	sd	t1,40(sp)
    80005dce:	f81e                	sd	t2,48(sp)
    80005dd0:	fc22                	sd	s0,56(sp)
    80005dd2:	e0a6                	sd	s1,64(sp)
    80005dd4:	e4aa                	sd	a0,72(sp)
    80005dd6:	e8ae                	sd	a1,80(sp)
    80005dd8:	ecb2                	sd	a2,88(sp)
    80005dda:	f0b6                	sd	a3,96(sp)
    80005ddc:	f4ba                	sd	a4,104(sp)
    80005dde:	f8be                	sd	a5,112(sp)
    80005de0:	fcc2                	sd	a6,120(sp)
    80005de2:	e146                	sd	a7,128(sp)
    80005de4:	e54a                	sd	s2,136(sp)
    80005de6:	e94e                	sd	s3,144(sp)
    80005de8:	ed52                	sd	s4,152(sp)
    80005dea:	f156                	sd	s5,160(sp)
    80005dec:	f55a                	sd	s6,168(sp)
    80005dee:	f95e                	sd	s7,176(sp)
    80005df0:	fd62                	sd	s8,184(sp)
    80005df2:	e1e6                	sd	s9,192(sp)
    80005df4:	e5ea                	sd	s10,200(sp)
    80005df6:	e9ee                	sd	s11,208(sp)
    80005df8:	edf2                	sd	t3,216(sp)
    80005dfa:	f1f6                	sd	t4,224(sp)
    80005dfc:	f5fa                	sd	t5,232(sp)
    80005dfe:	f9fe                	sd	t6,240(sp)
    80005e00:	ccbfc0ef          	jal	ra,80002aca <kerneltrap>
    80005e04:	6082                	ld	ra,0(sp)
    80005e06:	6122                	ld	sp,8(sp)
    80005e08:	61c2                	ld	gp,16(sp)
    80005e0a:	7282                	ld	t0,32(sp)
    80005e0c:	7322                	ld	t1,40(sp)
    80005e0e:	73c2                	ld	t2,48(sp)
    80005e10:	7462                	ld	s0,56(sp)
    80005e12:	6486                	ld	s1,64(sp)
    80005e14:	6526                	ld	a0,72(sp)
    80005e16:	65c6                	ld	a1,80(sp)
    80005e18:	6666                	ld	a2,88(sp)
    80005e1a:	7686                	ld	a3,96(sp)
    80005e1c:	7726                	ld	a4,104(sp)
    80005e1e:	77c6                	ld	a5,112(sp)
    80005e20:	7866                	ld	a6,120(sp)
    80005e22:	688a                	ld	a7,128(sp)
    80005e24:	692a                	ld	s2,136(sp)
    80005e26:	69ca                	ld	s3,144(sp)
    80005e28:	6a6a                	ld	s4,152(sp)
    80005e2a:	7a8a                	ld	s5,160(sp)
    80005e2c:	7b2a                	ld	s6,168(sp)
    80005e2e:	7bca                	ld	s7,176(sp)
    80005e30:	7c6a                	ld	s8,184(sp)
    80005e32:	6c8e                	ld	s9,192(sp)
    80005e34:	6d2e                	ld	s10,200(sp)
    80005e36:	6dce                	ld	s11,208(sp)
    80005e38:	6e6e                	ld	t3,216(sp)
    80005e3a:	7e8e                	ld	t4,224(sp)
    80005e3c:	7f2e                	ld	t5,232(sp)
    80005e3e:	7fce                	ld	t6,240(sp)
    80005e40:	6111                	addi	sp,sp,256
    80005e42:	10200073          	sret
    80005e46:	00000013          	nop
    80005e4a:	00000013          	nop
    80005e4e:	0001                	nop

0000000080005e50 <timervec>:
    80005e50:	34051573          	csrrw	a0,mscratch,a0
    80005e54:	e10c                	sd	a1,0(a0)
    80005e56:	e510                	sd	a2,8(a0)
    80005e58:	e914                	sd	a3,16(a0)
    80005e5a:	6d0c                	ld	a1,24(a0)
    80005e5c:	7110                	ld	a2,32(a0)
    80005e5e:	6194                	ld	a3,0(a1)
    80005e60:	96b2                	add	a3,a3,a2
    80005e62:	e194                	sd	a3,0(a1)
    80005e64:	4589                	li	a1,2
    80005e66:	14459073          	csrw	sip,a1
    80005e6a:	6914                	ld	a3,16(a0)
    80005e6c:	6510                	ld	a2,8(a0)
    80005e6e:	610c                	ld	a1,0(a0)
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	30200073          	mret
	...

0000000080005e7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e7a:	1141                	addi	sp,sp,-16
    80005e7c:	e422                	sd	s0,8(sp)
    80005e7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e80:	0c0007b7          	lui	a5,0xc000
    80005e84:	4705                	li	a4,1
    80005e86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e88:	c3d8                	sw	a4,4(a5)
}
    80005e8a:	6422                	ld	s0,8(sp)
    80005e8c:	0141                	addi	sp,sp,16
    80005e8e:	8082                	ret

0000000080005e90 <plicinithart>:

void
plicinithart(void)
{
    80005e90:	1141                	addi	sp,sp,-16
    80005e92:	e406                	sd	ra,8(sp)
    80005e94:	e022                	sd	s0,0(sp)
    80005e96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	b44080e7          	jalr	-1212(ra) # 800019dc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ea0:	0085171b          	slliw	a4,a0,0x8
    80005ea4:	0c0027b7          	lui	a5,0xc002
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	40200713          	li	a4,1026
    80005eae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eb2:	00d5151b          	slliw	a0,a0,0xd
    80005eb6:	0c2017b7          	lui	a5,0xc201
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	00052023          	sw	zero,0(a0)
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	addi	sp,sp,16
    80005ec6:	8082                	ret

0000000080005ec8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ec8:	1141                	addi	sp,sp,-16
    80005eca:	e406                	sd	ra,8(sp)
    80005ecc:	e022                	sd	s0,0(sp)
    80005ece:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed0:	ffffc097          	auipc	ra,0xffffc
    80005ed4:	b0c080e7          	jalr	-1268(ra) # 800019dc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ed8:	00d5179b          	slliw	a5,a0,0xd
    80005edc:	0c201537          	lui	a0,0xc201
    80005ee0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ee2:	4148                	lw	a0,4(a0)
    80005ee4:	60a2                	ld	ra,8(sp)
    80005ee6:	6402                	ld	s0,0(sp)
    80005ee8:	0141                	addi	sp,sp,16
    80005eea:	8082                	ret

0000000080005eec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eec:	1101                	addi	sp,sp,-32
    80005eee:	ec06                	sd	ra,24(sp)
    80005ef0:	e822                	sd	s0,16(sp)
    80005ef2:	e426                	sd	s1,8(sp)
    80005ef4:	1000                	addi	s0,sp,32
    80005ef6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	ae4080e7          	jalr	-1308(ra) # 800019dc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f00:	00d5151b          	slliw	a0,a0,0xd
    80005f04:	0c2017b7          	lui	a5,0xc201
    80005f08:	97aa                	add	a5,a5,a0
    80005f0a:	c3c4                	sw	s1,4(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret

0000000080005f16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f16:	1141                	addi	sp,sp,-16
    80005f18:	e406                	sd	ra,8(sp)
    80005f1a:	e022                	sd	s0,0(sp)
    80005f1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f1e:	479d                	li	a5,7
    80005f20:	04a7cc63          	blt	a5,a0,80005f78 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f24:	0001c797          	auipc	a5,0x1c
    80005f28:	f2c78793          	addi	a5,a5,-212 # 80021e50 <disk>
    80005f2c:	97aa                	add	a5,a5,a0
    80005f2e:	0187c783          	lbu	a5,24(a5)
    80005f32:	ebb9                	bnez	a5,80005f88 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f34:	00451613          	slli	a2,a0,0x4
    80005f38:	0001c797          	auipc	a5,0x1c
    80005f3c:	f1878793          	addi	a5,a5,-232 # 80021e50 <disk>
    80005f40:	6394                	ld	a3,0(a5)
    80005f42:	96b2                	add	a3,a3,a2
    80005f44:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f48:	6398                	ld	a4,0(a5)
    80005f4a:	9732                	add	a4,a4,a2
    80005f4c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f50:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f54:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f58:	953e                	add	a0,a0,a5
    80005f5a:	4785                	li	a5,1
    80005f5c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f60:	0001c517          	auipc	a0,0x1c
    80005f64:	f0850513          	addi	a0,a0,-248 # 80021e68 <disk+0x18>
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	1b8080e7          	jalr	440(ra) # 80002120 <wakeup>
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret
    panic("free_desc 1");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	81850513          	addi	a0,a0,-2024 # 80008790 <syscalls+0x310>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f88:	00003517          	auipc	a0,0x3
    80005f8c:	81850513          	addi	a0,a0,-2024 # 800087a0 <syscalls+0x320>
    80005f90:	ffffa097          	auipc	ra,0xffffa
    80005f94:	5ae080e7          	jalr	1454(ra) # 8000053e <panic>

0000000080005f98 <virtio_disk_init>:
{
    80005f98:	1101                	addi	sp,sp,-32
    80005f9a:	ec06                	sd	ra,24(sp)
    80005f9c:	e822                	sd	s0,16(sp)
    80005f9e:	e426                	sd	s1,8(sp)
    80005fa0:	e04a                	sd	s2,0(sp)
    80005fa2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fa4:	00003597          	auipc	a1,0x3
    80005fa8:	80c58593          	addi	a1,a1,-2036 # 800087b0 <syscalls+0x330>
    80005fac:	0001c517          	auipc	a0,0x1c
    80005fb0:	fcc50513          	addi	a0,a0,-52 # 80021f78 <disk+0x128>
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	bee080e7          	jalr	-1042(ra) # 80000ba2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fbc:	100017b7          	lui	a5,0x10001
    80005fc0:	4398                	lw	a4,0(a5)
    80005fc2:	2701                	sext.w	a4,a4
    80005fc4:	747277b7          	lui	a5,0x74727
    80005fc8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fcc:	14f71c63          	bne	a4,a5,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fd0:	100017b7          	lui	a5,0x10001
    80005fd4:	43dc                	lw	a5,4(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fd8:	4709                	li	a4,2
    80005fda:	14e79563          	bne	a5,a4,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fde:	100017b7          	lui	a5,0x10001
    80005fe2:	479c                	lw	a5,8(a5)
    80005fe4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fe6:	12e79f63          	bne	a5,a4,80006124 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fea:	100017b7          	lui	a5,0x10001
    80005fee:	47d8                	lw	a4,12(a5)
    80005ff0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff2:	554d47b7          	lui	a5,0x554d4
    80005ff6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ffa:	12f71563          	bne	a4,a5,80006124 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006006:	4705                	li	a4,1
    80006008:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600a:	470d                	li	a4,3
    8000600c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000600e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006010:	c7ffe737          	lui	a4,0xc7ffe
    80006014:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7cf>
    80006018:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000601a:	2701                	sext.w	a4,a4
    8000601c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000601e:	472d                	li	a4,11
    80006020:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006022:	5bbc                	lw	a5,112(a5)
    80006024:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006028:	8ba1                	andi	a5,a5,8
    8000602a:	10078563          	beqz	a5,80006134 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006036:	43fc                	lw	a5,68(a5)
    80006038:	2781                	sext.w	a5,a5
    8000603a:	10079563          	bnez	a5,80006144 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	5bdc                	lw	a5,52(a5)
    80006044:	2781                	sext.w	a5,a5
  if(max == 0)
    80006046:	10078763          	beqz	a5,80006154 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000604a:	471d                	li	a4,7
    8000604c:	10f77c63          	bgeu	a4,a5,80006164 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	a96080e7          	jalr	-1386(ra) # 80000ae6 <kalloc>
    80006058:	0001c497          	auipc	s1,0x1c
    8000605c:	df848493          	addi	s1,s1,-520 # 80021e50 <disk>
    80006060:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	a84080e7          	jalr	-1404(ra) # 80000ae6 <kalloc>
    8000606a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	a7a080e7          	jalr	-1414(ra) # 80000ae6 <kalloc>
    80006074:	87aa                	mv	a5,a0
    80006076:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006078:	6088                	ld	a0,0(s1)
    8000607a:	cd6d                	beqz	a0,80006174 <virtio_disk_init+0x1dc>
    8000607c:	0001c717          	auipc	a4,0x1c
    80006080:	ddc73703          	ld	a4,-548(a4) # 80021e58 <disk+0x8>
    80006084:	cb65                	beqz	a4,80006174 <virtio_disk_init+0x1dc>
    80006086:	c7fd                	beqz	a5,80006174 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006088:	6605                	lui	a2,0x1
    8000608a:	4581                	li	a1,0
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	ca2080e7          	jalr	-862(ra) # 80000d2e <memset>
  memset(disk.avail, 0, PGSIZE);
    80006094:	0001c497          	auipc	s1,0x1c
    80006098:	dbc48493          	addi	s1,s1,-580 # 80021e50 <disk>
    8000609c:	6605                	lui	a2,0x1
    8000609e:	4581                	li	a1,0
    800060a0:	6488                	ld	a0,8(s1)
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	c8c080e7          	jalr	-884(ra) # 80000d2e <memset>
  memset(disk.used, 0, PGSIZE);
    800060aa:	6605                	lui	a2,0x1
    800060ac:	4581                	li	a1,0
    800060ae:	6888                	ld	a0,16(s1)
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	c7e080e7          	jalr	-898(ra) # 80000d2e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060b8:	100017b7          	lui	a5,0x10001
    800060bc:	4721                	li	a4,8
    800060be:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060c0:	4098                	lw	a4,0(s1)
    800060c2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060c6:	40d8                	lw	a4,4(s1)
    800060c8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060cc:	6498                	ld	a4,8(s1)
    800060ce:	0007069b          	sext.w	a3,a4
    800060d2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060d6:	9701                	srai	a4,a4,0x20
    800060d8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060dc:	6898                	ld	a4,16(s1)
    800060de:	0007069b          	sext.w	a3,a4
    800060e2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060e6:	9701                	srai	a4,a4,0x20
    800060e8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060ec:	4705                	li	a4,1
    800060ee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060f0:	00e48c23          	sb	a4,24(s1)
    800060f4:	00e48ca3          	sb	a4,25(s1)
    800060f8:	00e48d23          	sb	a4,26(s1)
    800060fc:	00e48da3          	sb	a4,27(s1)
    80006100:	00e48e23          	sb	a4,28(s1)
    80006104:	00e48ea3          	sb	a4,29(s1)
    80006108:	00e48f23          	sb	a4,30(s1)
    8000610c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006110:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006114:	0727a823          	sw	s2,112(a5)
}
    80006118:	60e2                	ld	ra,24(sp)
    8000611a:	6442                	ld	s0,16(sp)
    8000611c:	64a2                	ld	s1,8(sp)
    8000611e:	6902                	ld	s2,0(sp)
    80006120:	6105                	addi	sp,sp,32
    80006122:	8082                	ret
    panic("could not find virtio disk");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	69c50513          	addi	a0,a0,1692 # 800087c0 <syscalls+0x340>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	6ac50513          	addi	a0,a0,1708 # 800087e0 <syscalls+0x360>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6bc50513          	addi	a0,a0,1724 # 80008800 <syscalls+0x380>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6cc50513          	addi	a0,a0,1740 # 80008820 <syscalls+0x3a0>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6dc50513          	addi	a0,a0,1756 # 80008840 <syscalls+0x3c0>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6ec50513          	addi	a0,a0,1772 # 80008860 <syscalls+0x3e0>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>

0000000080006184 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006184:	7119                	addi	sp,sp,-128
    80006186:	fc86                	sd	ra,120(sp)
    80006188:	f8a2                	sd	s0,112(sp)
    8000618a:	f4a6                	sd	s1,104(sp)
    8000618c:	f0ca                	sd	s2,96(sp)
    8000618e:	ecce                	sd	s3,88(sp)
    80006190:	e8d2                	sd	s4,80(sp)
    80006192:	e4d6                	sd	s5,72(sp)
    80006194:	e0da                	sd	s6,64(sp)
    80006196:	fc5e                	sd	s7,56(sp)
    80006198:	f862                	sd	s8,48(sp)
    8000619a:	f466                	sd	s9,40(sp)
    8000619c:	f06a                	sd	s10,32(sp)
    8000619e:	ec6e                	sd	s11,24(sp)
    800061a0:	0100                	addi	s0,sp,128
    800061a2:	8aaa                	mv	s5,a0
    800061a4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061a6:	00c52d03          	lw	s10,12(a0)
    800061aa:	001d1d1b          	slliw	s10,s10,0x1
    800061ae:	1d02                	slli	s10,s10,0x20
    800061b0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800061b4:	0001c517          	auipc	a0,0x1c
    800061b8:	dc450513          	addi	a0,a0,-572 # 80021f78 <disk+0x128>
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	a76080e7          	jalr	-1418(ra) # 80000c32 <acquire>
  for(int i = 0; i < 3; i++){
    800061c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061c6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061c8:	0001cb97          	auipc	s7,0x1c
    800061cc:	c88b8b93          	addi	s7,s7,-888 # 80021e50 <disk>
  for(int i = 0; i < 3; i++){
    800061d0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d2:	0001cc97          	auipc	s9,0x1c
    800061d6:	da6c8c93          	addi	s9,s9,-602 # 80021f78 <disk+0x128>
    800061da:	a08d                	j	8000623c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061dc:	00fb8733          	add	a4,s7,a5
    800061e0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061e6:	0207c563          	bltz	a5,80006210 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ea:	2905                	addiw	s2,s2,1
    800061ec:	0611                	addi	a2,a2,4
    800061ee:	05690c63          	beq	s2,s6,80006246 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061f2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061f4:	0001c717          	auipc	a4,0x1c
    800061f8:	c5c70713          	addi	a4,a4,-932 # 80021e50 <disk>
    800061fc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061fe:	01874683          	lbu	a3,24(a4)
    80006202:	fee9                	bnez	a3,800061dc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006204:	2785                	addiw	a5,a5,1
    80006206:	0705                	addi	a4,a4,1
    80006208:	fe979be3          	bne	a5,s1,800061fe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000620c:	57fd                	li	a5,-1
    8000620e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006210:	01205d63          	blez	s2,8000622a <virtio_disk_rw+0xa6>
    80006214:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006216:	000a2503          	lw	a0,0(s4)
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	cfc080e7          	jalr	-772(ra) # 80005f16 <free_desc>
      for(int j = 0; j < i; j++)
    80006222:	2d85                	addiw	s11,s11,1
    80006224:	0a11                	addi	s4,s4,4
    80006226:	ffb918e3          	bne	s2,s11,80006216 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622a:	85e6                	mv	a1,s9
    8000622c:	0001c517          	auipc	a0,0x1c
    80006230:	c3c50513          	addi	a0,a0,-964 # 80021e68 <disk+0x18>
    80006234:	ffffc097          	auipc	ra,0xffffc
    80006238:	e88080e7          	jalr	-376(ra) # 800020bc <sleep>
  for(int i = 0; i < 3; i++){
    8000623c:	f8040a13          	addi	s4,s0,-128
{
    80006240:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006242:	894e                	mv	s2,s3
    80006244:	b77d                	j	800061f2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006246:	f8042583          	lw	a1,-128(s0)
    8000624a:	00a58793          	addi	a5,a1,10
    8000624e:	0792                	slli	a5,a5,0x4

  if(write)
    80006250:	0001c617          	auipc	a2,0x1c
    80006254:	c0060613          	addi	a2,a2,-1024 # 80021e50 <disk>
    80006258:	00f60733          	add	a4,a2,a5
    8000625c:	018036b3          	snez	a3,s8
    80006260:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006262:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006266:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000626a:	f6078693          	addi	a3,a5,-160
    8000626e:	6218                	ld	a4,0(a2)
    80006270:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006272:	00878513          	addi	a0,a5,8
    80006276:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006278:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000627a:	6208                	ld	a0,0(a2)
    8000627c:	96aa                	add	a3,a3,a0
    8000627e:	4741                	li	a4,16
    80006280:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006282:	4705                	li	a4,1
    80006284:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006288:	f8442703          	lw	a4,-124(s0)
    8000628c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006290:	0712                	slli	a4,a4,0x4
    80006292:	953a                	add	a0,a0,a4
    80006294:	058a8693          	addi	a3,s5,88
    80006298:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000629a:	6208                	ld	a0,0(a2)
    8000629c:	972a                	add	a4,a4,a0
    8000629e:	40000693          	li	a3,1024
    800062a2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062a4:	001c3c13          	seqz	s8,s8
    800062a8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062aa:	001c6c13          	ori	s8,s8,1
    800062ae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800062b2:	f8842603          	lw	a2,-120(s0)
    800062b6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062ba:	0001c697          	auipc	a3,0x1c
    800062be:	b9668693          	addi	a3,a3,-1130 # 80021e50 <disk>
    800062c2:	00258713          	addi	a4,a1,2
    800062c6:	0712                	slli	a4,a4,0x4
    800062c8:	9736                	add	a4,a4,a3
    800062ca:	587d                	li	a6,-1
    800062cc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d0:	0612                	slli	a2,a2,0x4
    800062d2:	9532                	add	a0,a0,a2
    800062d4:	f9078793          	addi	a5,a5,-112
    800062d8:	97b6                	add	a5,a5,a3
    800062da:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800062dc:	629c                	ld	a5,0(a3)
    800062de:	97b2                	add	a5,a5,a2
    800062e0:	4605                	li	a2,1
    800062e2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062e4:	4509                	li	a0,2
    800062e6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800062ea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062ee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062f2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062f6:	6698                	ld	a4,8(a3)
    800062f8:	00275783          	lhu	a5,2(a4)
    800062fc:	8b9d                	andi	a5,a5,7
    800062fe:	0786                	slli	a5,a5,0x1
    80006300:	97ba                	add	a5,a5,a4
    80006302:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006306:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000630a:	6698                	ld	a4,8(a3)
    8000630c:	00275783          	lhu	a5,2(a4)
    80006310:	2785                	addiw	a5,a5,1
    80006312:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006316:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000631a:	100017b7          	lui	a5,0x10001
    8000631e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006322:	004aa783          	lw	a5,4(s5)
    80006326:	02c79163          	bne	a5,a2,80006348 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000632a:	0001c917          	auipc	s2,0x1c
    8000632e:	c4e90913          	addi	s2,s2,-946 # 80021f78 <disk+0x128>
  while(b->disk == 1) {
    80006332:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006334:	85ca                	mv	a1,s2
    80006336:	8556                	mv	a0,s5
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	d84080e7          	jalr	-636(ra) # 800020bc <sleep>
  while(b->disk == 1) {
    80006340:	004aa783          	lw	a5,4(s5)
    80006344:	fe9788e3          	beq	a5,s1,80006334 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006348:	f8042903          	lw	s2,-128(s0)
    8000634c:	00290793          	addi	a5,s2,2
    80006350:	00479713          	slli	a4,a5,0x4
    80006354:	0001c797          	auipc	a5,0x1c
    80006358:	afc78793          	addi	a5,a5,-1284 # 80021e50 <disk>
    8000635c:	97ba                	add	a5,a5,a4
    8000635e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006362:	0001c997          	auipc	s3,0x1c
    80006366:	aee98993          	addi	s3,s3,-1298 # 80021e50 <disk>
    8000636a:	00491713          	slli	a4,s2,0x4
    8000636e:	0009b783          	ld	a5,0(s3)
    80006372:	97ba                	add	a5,a5,a4
    80006374:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006378:	854a                	mv	a0,s2
    8000637a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000637e:	00000097          	auipc	ra,0x0
    80006382:	b98080e7          	jalr	-1128(ra) # 80005f16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006386:	8885                	andi	s1,s1,1
    80006388:	f0ed                	bnez	s1,8000636a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000638a:	0001c517          	auipc	a0,0x1c
    8000638e:	bee50513          	addi	a0,a0,-1042 # 80021f78 <disk+0x128>
    80006392:	ffffb097          	auipc	ra,0xffffb
    80006396:	954080e7          	jalr	-1708(ra) # 80000ce6 <release>
}
    8000639a:	70e6                	ld	ra,120(sp)
    8000639c:	7446                	ld	s0,112(sp)
    8000639e:	74a6                	ld	s1,104(sp)
    800063a0:	7906                	ld	s2,96(sp)
    800063a2:	69e6                	ld	s3,88(sp)
    800063a4:	6a46                	ld	s4,80(sp)
    800063a6:	6aa6                	ld	s5,72(sp)
    800063a8:	6b06                	ld	s6,64(sp)
    800063aa:	7be2                	ld	s7,56(sp)
    800063ac:	7c42                	ld	s8,48(sp)
    800063ae:	7ca2                	ld	s9,40(sp)
    800063b0:	7d02                	ld	s10,32(sp)
    800063b2:	6de2                	ld	s11,24(sp)
    800063b4:	6109                	addi	sp,sp,128
    800063b6:	8082                	ret

00000000800063b8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063b8:	1101                	addi	sp,sp,-32
    800063ba:	ec06                	sd	ra,24(sp)
    800063bc:	e822                	sd	s0,16(sp)
    800063be:	e426                	sd	s1,8(sp)
    800063c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063c2:	0001c497          	auipc	s1,0x1c
    800063c6:	a8e48493          	addi	s1,s1,-1394 # 80021e50 <disk>
    800063ca:	0001c517          	auipc	a0,0x1c
    800063ce:	bae50513          	addi	a0,a0,-1106 # 80021f78 <disk+0x128>
    800063d2:	ffffb097          	auipc	ra,0xffffb
    800063d6:	860080e7          	jalr	-1952(ra) # 80000c32 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063da:	10001737          	lui	a4,0x10001
    800063de:	533c                	lw	a5,96(a4)
    800063e0:	8b8d                	andi	a5,a5,3
    800063e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063e8:	689c                	ld	a5,16(s1)
    800063ea:	0204d703          	lhu	a4,32(s1)
    800063ee:	0027d783          	lhu	a5,2(a5)
    800063f2:	04f70863          	beq	a4,a5,80006442 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063f6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063fa:	6898                	ld	a4,16(s1)
    800063fc:	0204d783          	lhu	a5,32(s1)
    80006400:	8b9d                	andi	a5,a5,7
    80006402:	078e                	slli	a5,a5,0x3
    80006404:	97ba                	add	a5,a5,a4
    80006406:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006408:	00278713          	addi	a4,a5,2
    8000640c:	0712                	slli	a4,a4,0x4
    8000640e:	9726                	add	a4,a4,s1
    80006410:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006414:	e721                	bnez	a4,8000645c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006416:	0789                	addi	a5,a5,2
    80006418:	0792                	slli	a5,a5,0x4
    8000641a:	97a6                	add	a5,a5,s1
    8000641c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000641e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006422:	ffffc097          	auipc	ra,0xffffc
    80006426:	cfe080e7          	jalr	-770(ra) # 80002120 <wakeup>

    disk.used_idx += 1;
    8000642a:	0204d783          	lhu	a5,32(s1)
    8000642e:	2785                	addiw	a5,a5,1
    80006430:	17c2                	slli	a5,a5,0x30
    80006432:	93c1                	srli	a5,a5,0x30
    80006434:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006438:	6898                	ld	a4,16(s1)
    8000643a:	00275703          	lhu	a4,2(a4)
    8000643e:	faf71ce3          	bne	a4,a5,800063f6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006442:	0001c517          	auipc	a0,0x1c
    80006446:	b3650513          	addi	a0,a0,-1226 # 80021f78 <disk+0x128>
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	89c080e7          	jalr	-1892(ra) # 80000ce6 <release>
}
    80006452:	60e2                	ld	ra,24(sp)
    80006454:	6442                	ld	s0,16(sp)
    80006456:	64a2                	ld	s1,8(sp)
    80006458:	6105                	addi	sp,sp,32
    8000645a:	8082                	ret
      panic("virtio_disk_intr status");
    8000645c:	00002517          	auipc	a0,0x2
    80006460:	41c50513          	addi	a0,a0,1052 # 80008878 <syscalls+0x3f8>
    80006464:	ffffa097          	auipc	ra,0xffffa
    80006468:	0da080e7          	jalr	218(ra) # 8000053e <panic>
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
