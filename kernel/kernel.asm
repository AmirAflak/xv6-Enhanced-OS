
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
    80000068:	e1c78793          	addi	a5,a5,-484 # 80005e80 <timervec>
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
    80000130:	3fe080e7          	jalr	1022(ra) # 8000252a <either_copyin>
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
    80000196:	aa0080e7          	jalr	-1376(ra) # 80000c32 <acquire>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	848080e7          	jalr	-1976(ra) # 80001a08 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1a8080e7          	jalr	424(ra) # 80002370 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ef2080e7          	jalr	-270(ra) # 800020c8 <sleep>
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
    80000216:	2c2080e7          	jalr	706(ra) # 800024d4 <either_copyout>
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
    80000232:	ab8080e7          	jalr	-1352(ra) # 80000ce6 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	83450513          	addi	a0,a0,-1996 # 80010a70 <cons>
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
    800002f6:	28e080e7          	jalr	654(ra) # 80002580 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	77650513          	addi	a0,a0,1910 # 80010a70 <cons>
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
    8000044a:	ce6080e7          	jalr	-794(ra) # 8000212c <wakeup>
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
    8000046c:	73a080e7          	jalr	1850(ra) # 80000ba2 <initlock>

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
    8000075a:	3c250513          	addi	a0,a0,962 # 80010b18 <pr>
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
    80000776:	3a648493          	addi	s1,s1,934 # 80010b18 <pr>
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
    800007d6:	36650513          	addi	a0,a0,870 # 80010b38 <uart_tx_lock>
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
    80000896:	89a080e7          	jalr	-1894(ra) # 8000212c <wakeup>
    
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
    800008da:	35c080e7          	jalr	860(ra) # 80000c32 <acquire>
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
    80000920:	7ac080e7          	jalr	1964(ra) # 800020c8 <sleep>
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
    800009c0:	17c48493          	addi	s1,s1,380 # 80010b38 <uart_tx_lock>
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
    80000a1a:	318080e7          	jalr	792(ra) # 80000d2e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	15290913          	addi	s2,s2,338 # 80010b70 <kmem>
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
    80000abe:	0b650513          	addi	a0,a0,182 # 80010b70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0e0080e7          	jalr	224(ra) # 80000ba2 <initlock>
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
    80000afe:	138080e7          	jalr	312(ra) # 80000c32 <acquire>
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
    80000b38:	03c50513          	addi	a0,a0,60 # 80010b70 <kmem>
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
    80000b56:	01e50513          	addi	a0,a0,30 # 80010b70 <kmem>
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
    80000b74:	00050513          	mv	a0,a0
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
    80000baa:	00052023          	sw	zero,0(a0) # fffffffff8000000 <end+0xffffffff77fde060>
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
    80000ee8:	a2470713          	addi	a4,a4,-1500 # 80008908 <started>
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
    80000f1e:	928080e7          	jalr	-1752(ra) # 80002842 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f22:	00005097          	auipc	ra,0x5
    80000f26:	f9e080e7          	jalr	-98(ra) # 80005ec0 <plicinithart>
  }

  scheduler();        
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	fec080e7          	jalr	-20(ra) # 80001f16 <scheduler>
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
    80000f96:	888080e7          	jalr	-1912(ra) # 8000281a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	8a8080e7          	jalr	-1880(ra) # 80002842 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	f08080e7          	jalr	-248(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000faa:	00005097          	auipc	ra,0x5
    80000fae:	f16080e7          	jalr	-234(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	0b8080e7          	jalr	184(ra) # 8000306a <binit>
    iinit();         // inode table
    80000fba:	00002097          	auipc	ra,0x2
    80000fbe:	75c080e7          	jalr	1884(ra) # 80003716 <iinit>
    fileinit();      // file table
    80000fc2:	00003097          	auipc	ra,0x3
    80000fc6:	6fa080e7          	jalr	1786(ra) # 800046bc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fca:	00005097          	auipc	ra,0x5
    80000fce:	ffe080e7          	jalr	-2(ra) # 80005fc8 <virtio_disk_init>
    userinit();      // first user process
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	d1a080e7          	jalr	-742(ra) # 80001cec <userinit>
    __sync_synchronize();
    80000fda:	0ff0000f          	fence
    started = 1;
    80000fde:	4785                	li	a5,1
    80000fe0:	00008717          	auipc	a4,0x8
    80000fe4:	92f72423          	sw	a5,-1752(a4) # 80008908 <started>
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
    80000ff8:	91c7b783          	ld	a5,-1764(a5) # 80008910 <kernel_pagetable>
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
    800012b4:	66a7b023          	sd	a0,1632(a5) # 80008910 <kernel_pagetable>
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
    800018ac:	71848493          	addi	s1,s1,1816 # 80010fc0 <proc>
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
    800018c6:	2fea0a13          	addi	s4,s4,766 # 80016bc0 <tickslock>
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
    80001948:	24c50513          	addi	a0,a0,588 # 80010b90 <pid_lock>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	256080e7          	jalr	598(ra) # 80000ba2 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001954:	00007597          	auipc	a1,0x7
    80001958:	89458593          	addi	a1,a1,-1900 # 800081e8 <digits+0x1a8>
    8000195c:	0000f517          	auipc	a0,0xf
    80001960:	24c50513          	addi	a0,a0,588 # 80010ba8 <wait_lock>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	23e080e7          	jalr	574(ra) # 80000ba2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	0000f497          	auipc	s1,0xf
    80001970:	65448493          	addi	s1,s1,1620 # 80010fc0 <proc>
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
    80001992:	23298993          	addi	s3,s3,562 # 80016bc0 <tickslock>
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
    800019fc:	1c850513          	addi	a0,a0,456 # 80010bc0 <cpus>
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
    80001a24:	17070713          	addi	a4,a4,368 # 80010b90 <pid_lock>
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
    80001a5c:	e487a783          	lw	a5,-440(a5) # 800088a0 <first.1>
    80001a60:	eb89                	bnez	a5,80001a72 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a62:	00001097          	auipc	ra,0x1
    80001a66:	df8080e7          	jalr	-520(ra) # 8000285a <usertrapret>
}
    80001a6a:	60a2                	ld	ra,8(sp)
    80001a6c:	6402                	ld	s0,0(sp)
    80001a6e:	0141                	addi	sp,sp,16
    80001a70:	8082                	ret
    first = 0;
    80001a72:	00007797          	auipc	a5,0x7
    80001a76:	e207a723          	sw	zero,-466(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001a7a:	4505                	li	a0,1
    80001a7c:	00002097          	auipc	ra,0x2
    80001a80:	c1a080e7          	jalr	-998(ra) # 80003696 <fsinit>
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
    80001a96:	0fe90913          	addi	s2,s2,254 # 80010b90 <pid_lock>
    80001a9a:	854a                	mv	a0,s2
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	196080e7          	jalr	406(ra) # 80000c32 <acquire>
  pid = nextpid;
    80001aa4:	00007797          	auipc	a5,0x7
    80001aa8:	e0078793          	addi	a5,a5,-512 # 800088a4 <nextpid>
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
    80001c22:	3a248493          	addi	s1,s1,930 # 80010fc0 <proc>
    80001c26:	00015917          	auipc	s2,0x15
    80001c2a:	f9a90913          	addi	s2,s2,-102 # 80016bc0 <tickslock>
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
    80001c64:	cc07a783          	lw	a5,-832(a5) # 80008920 <ticks>
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
    80001d04:	c0a7bc23          	sd	a0,-1000(a5) # 80008918 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d08:	03400613          	li	a2,52
    80001d0c:	00007597          	auipc	a1,0x7
    80001d10:	ba458593          	addi	a1,a1,-1116 # 800088b0 <initcode>
    80001d14:	6928                	ld	a0,80(a0)
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	69c080e7          	jalr	1692(ra) # 800013b2 <uvmfirst>
  p->sz = PGSIZE;
    80001d1e:	6785                	lui	a5,0x1
    80001d20:	e4bc                	sd	a5,72(s1)
  p->ctime = ticks;
    80001d22:	00007717          	auipc	a4,0x7
    80001d26:	bfe72703          	lw	a4,-1026(a4) # 80008920 <ticks>
    80001d2a:	16e4a423          	sw	a4,360(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d2e:	6cb8                	ld	a4,88(s1)
    80001d30:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d34:	6cb8                	ld	a4,88(s1)
    80001d36:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d38:	4641                	li	a2,16
    80001d3a:	00006597          	auipc	a1,0x6
    80001d3e:	4c658593          	addi	a1,a1,1222 # 80008200 <digits+0x1c0>
    80001d42:	15848513          	addi	a0,s1,344
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	132080e7          	jalr	306(ra) # 80000e78 <safestrcpy>
  p->cwd = namei("/");
    80001d4e:	00006517          	auipc	a0,0x6
    80001d52:	4c250513          	addi	a0,a0,1218 # 80008210 <digits+0x1d0>
    80001d56:	00002097          	auipc	ra,0x2
    80001d5a:	362080e7          	jalr	866(ra) # 800040b8 <namei>
    80001d5e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d62:	478d                	li	a5,3
    80001d64:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d66:	8526                	mv	a0,s1
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	f7e080e7          	jalr	-130(ra) # 80000ce6 <release>
}
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret

0000000080001d7a <growproc>:
{
    80001d7a:	1101                	addi	sp,sp,-32
    80001d7c:	ec06                	sd	ra,24(sp)
    80001d7e:	e822                	sd	s0,16(sp)
    80001d80:	e426                	sd	s1,8(sp)
    80001d82:	e04a                	sd	s2,0(sp)
    80001d84:	1000                	addi	s0,sp,32
    80001d86:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c80080e7          	jalr	-896(ra) # 80001a08 <myproc>
    80001d90:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d92:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d94:	01204c63          	bgtz	s2,80001dac <growproc+0x32>
  } else if(n < 0){
    80001d98:	02094663          	bltz	s2,80001dc4 <growproc+0x4a>
  p->sz = sz;
    80001d9c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d9e:	4501                	li	a0,0
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6902                	ld	s2,0(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dac:	4691                	li	a3,4
    80001dae:	00b90633          	add	a2,s2,a1
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	6b8080e7          	jalr	1720(ra) # 8000146c <uvmalloc>
    80001dbc:	85aa                	mv	a1,a0
    80001dbe:	fd79                	bnez	a0,80001d9c <growproc+0x22>
      return -1;
    80001dc0:	557d                	li	a0,-1
    80001dc2:	bff9                	j	80001da0 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc4:	00b90633          	add	a2,s2,a1
    80001dc8:	6928                	ld	a0,80(a0)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	65a080e7          	jalr	1626(ra) # 80001424 <uvmdealloc>
    80001dd2:	85aa                	mv	a1,a0
    80001dd4:	b7e1                	j	80001d9c <growproc+0x22>

0000000080001dd6 <fork>:
{
    80001dd6:	7139                	addi	sp,sp,-64
    80001dd8:	fc06                	sd	ra,56(sp)
    80001dda:	f822                	sd	s0,48(sp)
    80001ddc:	f426                	sd	s1,40(sp)
    80001dde:	f04a                	sd	s2,32(sp)
    80001de0:	ec4e                	sd	s3,24(sp)
    80001de2:	e852                	sd	s4,16(sp)
    80001de4:	e456                	sd	s5,8(sp)
    80001de6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	c20080e7          	jalr	-992(ra) # 80001a08 <myproc>
    80001df0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	e20080e7          	jalr	-480(ra) # 80001c12 <allocproc>
    80001dfa:	10050c63          	beqz	a0,80001f12 <fork+0x13c>
    80001dfe:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e00:	048ab603          	ld	a2,72(s5)
    80001e04:	692c                	ld	a1,80(a0)
    80001e06:	050ab503          	ld	a0,80(s5)
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	7b6080e7          	jalr	1974(ra) # 800015c0 <uvmcopy>
    80001e12:	04054863          	bltz	a0,80001e62 <fork+0x8c>
  np->sz = p->sz;
    80001e16:	048ab783          	ld	a5,72(s5)
    80001e1a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e1e:	058ab683          	ld	a3,88(s5)
    80001e22:	87b6                	mv	a5,a3
    80001e24:	058a3703          	ld	a4,88(s4)
    80001e28:	12068693          	addi	a3,a3,288
    80001e2c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e30:	6788                	ld	a0,8(a5)
    80001e32:	6b8c                	ld	a1,16(a5)
    80001e34:	6f90                	ld	a2,24(a5)
    80001e36:	01073023          	sd	a6,0(a4)
    80001e3a:	e708                	sd	a0,8(a4)
    80001e3c:	eb0c                	sd	a1,16(a4)
    80001e3e:	ef10                	sd	a2,24(a4)
    80001e40:	02078793          	addi	a5,a5,32
    80001e44:	02070713          	addi	a4,a4,32
    80001e48:	fed792e3          	bne	a5,a3,80001e2c <fork+0x56>
  np->trapframe->a0 = 0;
    80001e4c:	058a3783          	ld	a5,88(s4)
    80001e50:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e54:	0d0a8493          	addi	s1,s5,208
    80001e58:	0d0a0913          	addi	s2,s4,208
    80001e5c:	150a8993          	addi	s3,s5,336
    80001e60:	a00d                	j	80001e82 <fork+0xac>
    freeproc(np);
    80001e62:	8552                	mv	a0,s4
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	d56080e7          	jalr	-682(ra) # 80001bba <freeproc>
    release(&np->lock);
    80001e6c:	8552                	mv	a0,s4
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e78080e7          	jalr	-392(ra) # 80000ce6 <release>
    return -1;
    80001e76:	597d                	li	s2,-1
    80001e78:	a059                	j	80001efe <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e7a:	04a1                	addi	s1,s1,8
    80001e7c:	0921                	addi	s2,s2,8
    80001e7e:	01348b63          	beq	s1,s3,80001e94 <fork+0xbe>
    if(p->ofile[i])
    80001e82:	6088                	ld	a0,0(s1)
    80001e84:	d97d                	beqz	a0,80001e7a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e86:	00003097          	auipc	ra,0x3
    80001e8a:	8c8080e7          	jalr	-1848(ra) # 8000474e <filedup>
    80001e8e:	00a93023          	sd	a0,0(s2)
    80001e92:	b7e5                	j	80001e7a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e94:	150ab503          	ld	a0,336(s5)
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	a3c080e7          	jalr	-1476(ra) # 800038d4 <idup>
    80001ea0:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea4:	4641                	li	a2,16
    80001ea6:	158a8593          	addi	a1,s5,344
    80001eaa:	158a0513          	addi	a0,s4,344
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	fca080e7          	jalr	-54(ra) # 80000e78 <safestrcpy>
  pid = np->pid;
    80001eb6:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eba:	8552                	mv	a0,s4
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	e2a080e7          	jalr	-470(ra) # 80000ce6 <release>
  acquire(&wait_lock);
    80001ec4:	0000f497          	auipc	s1,0xf
    80001ec8:	ce448493          	addi	s1,s1,-796 # 80010ba8 <wait_lock>
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	d64080e7          	jalr	-668(ra) # 80000c32 <acquire>
  np->parent = p;
    80001ed6:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	e0a080e7          	jalr	-502(ra) # 80000ce6 <release>
  acquire(&np->lock);
    80001ee4:	8552                	mv	a0,s4
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	d4c080e7          	jalr	-692(ra) # 80000c32 <acquire>
  np->state = RUNNABLE;
    80001eee:	478d                	li	a5,3
    80001ef0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ef4:	8552                	mv	a0,s4
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	df0080e7          	jalr	-528(ra) # 80000ce6 <release>
}
    80001efe:	854a                	mv	a0,s2
    80001f00:	70e2                	ld	ra,56(sp)
    80001f02:	7442                	ld	s0,48(sp)
    80001f04:	74a2                	ld	s1,40(sp)
    80001f06:	7902                	ld	s2,32(sp)
    80001f08:	69e2                	ld	s3,24(sp)
    80001f0a:	6a42                	ld	s4,16(sp)
    80001f0c:	6aa2                	ld	s5,8(sp)
    80001f0e:	6121                	addi	sp,sp,64
    80001f10:	8082                	ret
    return -1;
    80001f12:	597d                	li	s2,-1
    80001f14:	b7ed                	j	80001efe <fork+0x128>

0000000080001f16 <scheduler>:
{
    80001f16:	7139                	addi	sp,sp,-64
    80001f18:	fc06                	sd	ra,56(sp)
    80001f1a:	f822                	sd	s0,48(sp)
    80001f1c:	f426                	sd	s1,40(sp)
    80001f1e:	f04a                	sd	s2,32(sp)
    80001f20:	ec4e                	sd	s3,24(sp)
    80001f22:	e852                	sd	s4,16(sp)
    80001f24:	e456                	sd	s5,8(sp)
    80001f26:	e05a                	sd	s6,0(sp)
    80001f28:	0080                	addi	s0,sp,64
    80001f2a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f2e:	00779a93          	slli	s5,a5,0x7
    80001f32:	0000f717          	auipc	a4,0xf
    80001f36:	c5e70713          	addi	a4,a4,-930 # 80010b90 <pid_lock>
    80001f3a:	9756                	add	a4,a4,s5
    80001f3c:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f40:	0000f717          	auipc	a4,0xf
    80001f44:	c8870713          	addi	a4,a4,-888 # 80010bc8 <cpus+0x8>
    80001f48:	9aba                	add	s5,s5,a4
        if(p->state == RUNNABLE) {
    80001f4a:	498d                	li	s3,3
          p->state = RUNNING;
    80001f4c:	4b11                	li	s6,4
          c->proc = p;
    80001f4e:	079e                	slli	a5,a5,0x7
    80001f50:	0000fa17          	auipc	s4,0xf
    80001f54:	c40a0a13          	addi	s4,s4,-960 # 80010b90 <pid_lock>
    80001f58:	9a3e                	add	s4,s4,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f5a:	00015917          	auipc	s2,0x15
    80001f5e:	c6690913          	addi	s2,s2,-922 # 80016bc0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f66:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6a:	10079073          	csrw	sstatus,a5
    80001f6e:	0000f497          	auipc	s1,0xf
    80001f72:	05248493          	addi	s1,s1,82 # 80010fc0 <proc>
    80001f76:	a811                	j	80001f8a <scheduler+0x74>
        release(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d6c080e7          	jalr	-660(ra) # 80000ce6 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	17048493          	addi	s1,s1,368
    80001f86:	fd248ee3          	beq	s1,s2,80001f62 <scheduler+0x4c>
        acquire(&p->lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	ca6080e7          	jalr	-858(ra) # 80000c32 <acquire>
        if(p->state == RUNNABLE) {
    80001f94:	4c9c                	lw	a5,24(s1)
    80001f96:	ff3791e3          	bne	a5,s3,80001f78 <scheduler+0x62>
          p->state = RUNNING;
    80001f9a:	0164ac23          	sw	s6,24(s1)
          c->proc = p;
    80001f9e:	029a3823          	sd	s1,48(s4)
          swtch(&c->context, &p->context);
    80001fa2:	06048593          	addi	a1,s1,96
    80001fa6:	8556                	mv	a0,s5
    80001fa8:	00001097          	auipc	ra,0x1
    80001fac:	808080e7          	jalr	-2040(ra) # 800027b0 <swtch>
          c->proc = 0;
    80001fb0:	020a3823          	sd	zero,48(s4)
    80001fb4:	b7d1                	j	80001f78 <scheduler+0x62>

0000000080001fb6 <sched>:
{
    80001fb6:	7179                	addi	sp,sp,-48
    80001fb8:	f406                	sd	ra,40(sp)
    80001fba:	f022                	sd	s0,32(sp)
    80001fbc:	ec26                	sd	s1,24(sp)
    80001fbe:	e84a                	sd	s2,16(sp)
    80001fc0:	e44e                	sd	s3,8(sp)
    80001fc2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	a44080e7          	jalr	-1468(ra) # 80001a08 <myproc>
    80001fcc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	bea080e7          	jalr	-1046(ra) # 80000bb8 <holding>
    80001fd6:	c93d                	beqz	a0,8000204c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fda:	2781                	sext.w	a5,a5
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	0000f717          	auipc	a4,0xf
    80001fe2:	bb270713          	addi	a4,a4,-1102 # 80010b90 <pid_lock>
    80001fe6:	97ba                	add	a5,a5,a4
    80001fe8:	0a87a703          	lw	a4,168(a5)
    80001fec:	4785                	li	a5,1
    80001fee:	06f71763          	bne	a4,a5,8000205c <sched+0xa6>
  if(p->state == RUNNING)
    80001ff2:	4c98                	lw	a4,24(s1)
    80001ff4:	4791                	li	a5,4
    80001ff6:	06f70b63          	beq	a4,a5,8000206c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ffe:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002000:	efb5                	bnez	a5,8000207c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002002:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002004:	0000f917          	auipc	s2,0xf
    80002008:	b8c90913          	addi	s2,s2,-1140 # 80010b90 <pid_lock>
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	97ca                	add	a5,a5,s2
    80002012:	0ac7a983          	lw	s3,172(a5)
    80002016:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002018:	2781                	sext.w	a5,a5
    8000201a:	079e                	slli	a5,a5,0x7
    8000201c:	0000f597          	auipc	a1,0xf
    80002020:	bac58593          	addi	a1,a1,-1108 # 80010bc8 <cpus+0x8>
    80002024:	95be                	add	a1,a1,a5
    80002026:	06048513          	addi	a0,s1,96
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	786080e7          	jalr	1926(ra) # 800027b0 <swtch>
    80002032:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	97ca                	add	a5,a5,s2
    8000203a:	0b37a623          	sw	s3,172(a5)
}
    8000203e:	70a2                	ld	ra,40(sp)
    80002040:	7402                	ld	s0,32(sp)
    80002042:	64e2                	ld	s1,24(sp)
    80002044:	6942                	ld	s2,16(sp)
    80002046:	69a2                	ld	s3,8(sp)
    80002048:	6145                	addi	sp,sp,48
    8000204a:	8082                	ret
    panic("sched p->lock");
    8000204c:	00006517          	auipc	a0,0x6
    80002050:	1cc50513          	addi	a0,a0,460 # 80008218 <digits+0x1d8>
    80002054:	ffffe097          	auipc	ra,0xffffe
    80002058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>
    panic("sched locks");
    8000205c:	00006517          	auipc	a0,0x6
    80002060:	1cc50513          	addi	a0,a0,460 # 80008228 <digits+0x1e8>
    80002064:	ffffe097          	auipc	ra,0xffffe
    80002068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>
    panic("sched running");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1cc50513          	addi	a0,a0,460 # 80008238 <digits+0x1f8>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1cc50513          	addi	a0,a0,460 # 80008248 <digits+0x208>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>

000000008000208c <yield>:
{
    8000208c:	1101                	addi	sp,sp,-32
    8000208e:	ec06                	sd	ra,24(sp)
    80002090:	e822                	sd	s0,16(sp)
    80002092:	e426                	sd	s1,8(sp)
    80002094:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	972080e7          	jalr	-1678(ra) # 80001a08 <myproc>
    8000209e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	b92080e7          	jalr	-1134(ra) # 80000c32 <acquire>
  p->state = RUNNABLE;
    800020a8:	478d                	li	a5,3
    800020aa:	cc9c                	sw	a5,24(s1)
  sched();
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	f0a080e7          	jalr	-246(ra) # 80001fb6 <sched>
  release(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	c30080e7          	jalr	-976(ra) # 80000ce6 <release>
}
    800020be:	60e2                	ld	ra,24(sp)
    800020c0:	6442                	ld	s0,16(sp)
    800020c2:	64a2                	ld	s1,8(sp)
    800020c4:	6105                	addi	sp,sp,32
    800020c6:	8082                	ret

00000000800020c8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020c8:	7179                	addi	sp,sp,-48
    800020ca:	f406                	sd	ra,40(sp)
    800020cc:	f022                	sd	s0,32(sp)
    800020ce:	ec26                	sd	s1,24(sp)
    800020d0:	e84a                	sd	s2,16(sp)
    800020d2:	e44e                	sd	s3,8(sp)
    800020d4:	1800                	addi	s0,sp,48
    800020d6:	89aa                	mv	s3,a0
    800020d8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	92e080e7          	jalr	-1746(ra) # 80001a08 <myproc>
    800020e2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	b4e080e7          	jalr	-1202(ra) # 80000c32 <acquire>
  release(lk);
    800020ec:	854a                	mv	a0,s2
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	bf8080e7          	jalr	-1032(ra) # 80000ce6 <release>

  // Go to sleep.
  p->chan = chan;
    800020f6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fa:	4789                	li	a5,2
    800020fc:	cc9c                	sw	a5,24(s1)

  sched();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	eb8080e7          	jalr	-328(ra) # 80001fb6 <sched>

  // Tidy up.
  p->chan = 0;
    80002106:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	bda080e7          	jalr	-1062(ra) # 80000ce6 <release>
  acquire(lk);
    80002114:	854a                	mv	a0,s2
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b1c080e7          	jalr	-1252(ra) # 80000c32 <acquire>
}
    8000211e:	70a2                	ld	ra,40(sp)
    80002120:	7402                	ld	s0,32(sp)
    80002122:	64e2                	ld	s1,24(sp)
    80002124:	6942                	ld	s2,16(sp)
    80002126:	69a2                	ld	s3,8(sp)
    80002128:	6145                	addi	sp,sp,48
    8000212a:	8082                	ret

000000008000212c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000212c:	7139                	addi	sp,sp,-64
    8000212e:	fc06                	sd	ra,56(sp)
    80002130:	f822                	sd	s0,48(sp)
    80002132:	f426                	sd	s1,40(sp)
    80002134:	f04a                	sd	s2,32(sp)
    80002136:	ec4e                	sd	s3,24(sp)
    80002138:	e852                	sd	s4,16(sp)
    8000213a:	e456                	sd	s5,8(sp)
    8000213c:	0080                	addi	s0,sp,64
    8000213e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e8048493          	addi	s1,s1,-384 # 80010fc0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002148:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000214a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000214c:	00015917          	auipc	s2,0x15
    80002150:	a7490913          	addi	s2,s2,-1420 # 80016bc0 <tickslock>
    80002154:	a811                	j	80002168 <wakeup+0x3c>
      }
      release(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b8e080e7          	jalr	-1138(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002160:	17048493          	addi	s1,s1,368
    80002164:	03248663          	beq	s1,s2,80002190 <wakeup+0x64>
    if(p != myproc()){
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	8a0080e7          	jalr	-1888(ra) # 80001a08 <myproc>
    80002170:	fea488e3          	beq	s1,a0,80002160 <wakeup+0x34>
      acquire(&p->lock);
    80002174:	8526                	mv	a0,s1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	abc080e7          	jalr	-1348(ra) # 80000c32 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000217e:	4c9c                	lw	a5,24(s1)
    80002180:	fd379be3          	bne	a5,s3,80002156 <wakeup+0x2a>
    80002184:	709c                	ld	a5,32(s1)
    80002186:	fd4798e3          	bne	a5,s4,80002156 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000218a:	0154ac23          	sw	s5,24(s1)
    8000218e:	b7e1                	j	80002156 <wakeup+0x2a>
    }
  }
}
    80002190:	70e2                	ld	ra,56(sp)
    80002192:	7442                	ld	s0,48(sp)
    80002194:	74a2                	ld	s1,40(sp)
    80002196:	7902                	ld	s2,32(sp)
    80002198:	69e2                	ld	s3,24(sp)
    8000219a:	6a42                	ld	s4,16(sp)
    8000219c:	6aa2                	ld	s5,8(sp)
    8000219e:	6121                	addi	sp,sp,64
    800021a0:	8082                	ret

00000000800021a2 <reparent>:
{
    800021a2:	7179                	addi	sp,sp,-48
    800021a4:	f406                	sd	ra,40(sp)
    800021a6:	f022                	sd	s0,32(sp)
    800021a8:	ec26                	sd	s1,24(sp)
    800021aa:	e84a                	sd	s2,16(sp)
    800021ac:	e44e                	sd	s3,8(sp)
    800021ae:	e052                	sd	s4,0(sp)
    800021b0:	1800                	addi	s0,sp,48
    800021b2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b4:	0000f497          	auipc	s1,0xf
    800021b8:	e0c48493          	addi	s1,s1,-500 # 80010fc0 <proc>
      pp->parent = initproc;
    800021bc:	00006a17          	auipc	s4,0x6
    800021c0:	75ca0a13          	addi	s4,s4,1884 # 80008918 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021c4:	00015997          	auipc	s3,0x15
    800021c8:	9fc98993          	addi	s3,s3,-1540 # 80016bc0 <tickslock>
    800021cc:	a029                	j	800021d6 <reparent+0x34>
    800021ce:	17048493          	addi	s1,s1,368
    800021d2:	01348d63          	beq	s1,s3,800021ec <reparent+0x4a>
    if(pp->parent == p){
    800021d6:	7c9c                	ld	a5,56(s1)
    800021d8:	ff279be3          	bne	a5,s2,800021ce <reparent+0x2c>
      pp->parent = initproc;
    800021dc:	000a3503          	ld	a0,0(s4)
    800021e0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	f4a080e7          	jalr	-182(ra) # 8000212c <wakeup>
    800021ea:	b7d5                	j	800021ce <reparent+0x2c>
}
    800021ec:	70a2                	ld	ra,40(sp)
    800021ee:	7402                	ld	s0,32(sp)
    800021f0:	64e2                	ld	s1,24(sp)
    800021f2:	6942                	ld	s2,16(sp)
    800021f4:	69a2                	ld	s3,8(sp)
    800021f6:	6a02                	ld	s4,0(sp)
    800021f8:	6145                	addi	sp,sp,48
    800021fa:	8082                	ret

00000000800021fc <exit>:
{
    800021fc:	7179                	addi	sp,sp,-48
    800021fe:	f406                	sd	ra,40(sp)
    80002200:	f022                	sd	s0,32(sp)
    80002202:	ec26                	sd	s1,24(sp)
    80002204:	e84a                	sd	s2,16(sp)
    80002206:	e44e                	sd	s3,8(sp)
    80002208:	e052                	sd	s4,0(sp)
    8000220a:	1800                	addi	s0,sp,48
    8000220c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	7fa080e7          	jalr	2042(ra) # 80001a08 <myproc>
    80002216:	89aa                	mv	s3,a0
  if(p == initproc)
    80002218:	00006797          	auipc	a5,0x6
    8000221c:	7007b783          	ld	a5,1792(a5) # 80008918 <initproc>
    80002220:	0d050493          	addi	s1,a0,208
    80002224:	15050913          	addi	s2,a0,336
    80002228:	02a79363          	bne	a5,a0,8000224e <exit+0x52>
    panic("init exiting");
    8000222c:	00006517          	auipc	a0,0x6
    80002230:	03450513          	addi	a0,a0,52 # 80008260 <digits+0x220>
    80002234:	ffffe097          	auipc	ra,0xffffe
    80002238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
      fileclose(f);
    8000223c:	00002097          	auipc	ra,0x2
    80002240:	564080e7          	jalr	1380(ra) # 800047a0 <fileclose>
      p->ofile[fd] = 0;
    80002244:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002248:	04a1                	addi	s1,s1,8
    8000224a:	01248563          	beq	s1,s2,80002254 <exit+0x58>
    if(p->ofile[fd]){
    8000224e:	6088                	ld	a0,0(s1)
    80002250:	f575                	bnez	a0,8000223c <exit+0x40>
    80002252:	bfdd                	j	80002248 <exit+0x4c>
  begin_op();
    80002254:	00002097          	auipc	ra,0x2
    80002258:	080080e7          	jalr	128(ra) # 800042d4 <begin_op>
  iput(p->cwd);
    8000225c:	1509b503          	ld	a0,336(s3)
    80002260:	00002097          	auipc	ra,0x2
    80002264:	86c080e7          	jalr	-1940(ra) # 80003acc <iput>
  end_op();
    80002268:	00002097          	auipc	ra,0x2
    8000226c:	0ec080e7          	jalr	236(ra) # 80004354 <end_op>
  p->cwd = 0;
    80002270:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002274:	0000f497          	auipc	s1,0xf
    80002278:	93448493          	addi	s1,s1,-1740 # 80010ba8 <wait_lock>
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	9b4080e7          	jalr	-1612(ra) # 80000c32 <acquire>
  reparent(p);
    80002286:	854e                	mv	a0,s3
    80002288:	00000097          	auipc	ra,0x0
    8000228c:	f1a080e7          	jalr	-230(ra) # 800021a2 <reparent>
  wakeup(p->parent);
    80002290:	0389b503          	ld	a0,56(s3)
    80002294:	00000097          	auipc	ra,0x0
    80002298:	e98080e7          	jalr	-360(ra) # 8000212c <wakeup>
  acquire(&p->lock);
    8000229c:	854e                	mv	a0,s3
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	994080e7          	jalr	-1644(ra) # 80000c32 <acquire>
  p->xstate = status;
    800022a6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022aa:	4795                	li	a5,5
    800022ac:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	a34080e7          	jalr	-1484(ra) # 80000ce6 <release>
  sched();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	cfc080e7          	jalr	-772(ra) # 80001fb6 <sched>
  panic("zombie exit");
    800022c2:	00006517          	auipc	a0,0x6
    800022c6:	fae50513          	addi	a0,a0,-82 # 80008270 <digits+0x230>
    800022ca:	ffffe097          	auipc	ra,0xffffe
    800022ce:	274080e7          	jalr	628(ra) # 8000053e <panic>

00000000800022d2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022d2:	7179                	addi	sp,sp,-48
    800022d4:	f406                	sd	ra,40(sp)
    800022d6:	f022                	sd	s0,32(sp)
    800022d8:	ec26                	sd	s1,24(sp)
    800022da:	e84a                	sd	s2,16(sp)
    800022dc:	e44e                	sd	s3,8(sp)
    800022de:	1800                	addi	s0,sp,48
    800022e0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022e2:	0000f497          	auipc	s1,0xf
    800022e6:	cde48493          	addi	s1,s1,-802 # 80010fc0 <proc>
    800022ea:	00015997          	auipc	s3,0x15
    800022ee:	8d698993          	addi	s3,s3,-1834 # 80016bc0 <tickslock>
    acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	93e080e7          	jalr	-1730(ra) # 80000c32 <acquire>
    if(p->pid == pid){
    800022fc:	589c                	lw	a5,48(s1)
    800022fe:	01278d63          	beq	a5,s2,80002318 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	9e2080e7          	jalr	-1566(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000230c:	17048493          	addi	s1,s1,368
    80002310:	ff3491e3          	bne	s1,s3,800022f2 <kill+0x20>
  }
  return -1;
    80002314:	557d                	li	a0,-1
    80002316:	a829                	j	80002330 <kill+0x5e>
      p->killed = 1;
    80002318:	4785                	li	a5,1
    8000231a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000231c:	4c98                	lw	a4,24(s1)
    8000231e:	4789                	li	a5,2
    80002320:	00f70f63          	beq	a4,a5,8000233e <kill+0x6c>
      release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	9c0080e7          	jalr	-1600(ra) # 80000ce6 <release>
      return 0;
    8000232e:	4501                	li	a0,0
}
    80002330:	70a2                	ld	ra,40(sp)
    80002332:	7402                	ld	s0,32(sp)
    80002334:	64e2                	ld	s1,24(sp)
    80002336:	6942                	ld	s2,16(sp)
    80002338:	69a2                	ld	s3,8(sp)
    8000233a:	6145                	addi	sp,sp,48
    8000233c:	8082                	ret
        p->state = RUNNABLE;
    8000233e:	478d                	li	a5,3
    80002340:	cc9c                	sw	a5,24(s1)
    80002342:	b7cd                	j	80002324 <kill+0x52>

0000000080002344 <setkilled>:

void
setkilled(struct proc *p)
{
    80002344:	1101                	addi	sp,sp,-32
    80002346:	ec06                	sd	ra,24(sp)
    80002348:	e822                	sd	s0,16(sp)
    8000234a:	e426                	sd	s1,8(sp)
    8000234c:	1000                	addi	s0,sp,32
    8000234e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	8e2080e7          	jalr	-1822(ra) # 80000c32 <acquire>
  p->killed = 1;
    80002358:	4785                	li	a5,1
    8000235a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	988080e7          	jalr	-1656(ra) # 80000ce6 <release>
}
    80002366:	60e2                	ld	ra,24(sp)
    80002368:	6442                	ld	s0,16(sp)
    8000236a:	64a2                	ld	s1,8(sp)
    8000236c:	6105                	addi	sp,sp,32
    8000236e:	8082                	ret

0000000080002370 <killed>:

int
killed(struct proc *p)
{
    80002370:	1101                	addi	sp,sp,-32
    80002372:	ec06                	sd	ra,24(sp)
    80002374:	e822                	sd	s0,16(sp)
    80002376:	e426                	sd	s1,8(sp)
    80002378:	e04a                	sd	s2,0(sp)
    8000237a:	1000                	addi	s0,sp,32
    8000237c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	8b4080e7          	jalr	-1868(ra) # 80000c32 <acquire>
  k = p->killed;
    80002386:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	95a080e7          	jalr	-1702(ra) # 80000ce6 <release>
  return k;
}
    80002394:	854a                	mv	a0,s2
    80002396:	60e2                	ld	ra,24(sp)
    80002398:	6442                	ld	s0,16(sp)
    8000239a:	64a2                	ld	s1,8(sp)
    8000239c:	6902                	ld	s2,0(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <wait>:
{
    800023a2:	715d                	addi	sp,sp,-80
    800023a4:	e486                	sd	ra,72(sp)
    800023a6:	e0a2                	sd	s0,64(sp)
    800023a8:	fc26                	sd	s1,56(sp)
    800023aa:	f84a                	sd	s2,48(sp)
    800023ac:	f44e                	sd	s3,40(sp)
    800023ae:	f052                	sd	s4,32(sp)
    800023b0:	ec56                	sd	s5,24(sp)
    800023b2:	e85a                	sd	s6,16(sp)
    800023b4:	e45e                	sd	s7,8(sp)
    800023b6:	e062                	sd	s8,0(sp)
    800023b8:	0880                	addi	s0,sp,80
    800023ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	64c080e7          	jalr	1612(ra) # 80001a08 <myproc>
    800023c4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023c6:	0000e517          	auipc	a0,0xe
    800023ca:	7e250513          	addi	a0,a0,2018 # 80010ba8 <wait_lock>
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	864080e7          	jalr	-1948(ra) # 80000c32 <acquire>
    havekids = 0;
    800023d6:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023d8:	4a15                	li	s4,5
        havekids = 1;
    800023da:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023dc:	00014997          	auipc	s3,0x14
    800023e0:	7e498993          	addi	s3,s3,2020 # 80016bc0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e4:	0000ec17          	auipc	s8,0xe
    800023e8:	7c4c0c13          	addi	s8,s8,1988 # 80010ba8 <wait_lock>
    havekids = 0;
    800023ec:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	bd248493          	addi	s1,s1,-1070 # 80010fc0 <proc>
    800023f6:	a88d                	j	80002468 <wait+0xc6>
          pid = pp->pid;
    800023f8:	0304a983          	lw	s3,48(s1)
          pp->ctime = 0;
    800023fc:	1604a423          	sw	zero,360(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002400:	000b0e63          	beqz	s6,8000241c <wait+0x7a>
    80002404:	4691                	li	a3,4
    80002406:	02c48613          	addi	a2,s1,44
    8000240a:	85da                	mv	a1,s6
    8000240c:	05093503          	ld	a0,80(s2)
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	2b4080e7          	jalr	692(ra) # 800016c4 <copyout>
    80002418:	02054563          	bltz	a0,80002442 <wait+0xa0>
          freeproc(pp);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	79c080e7          	jalr	1948(ra) # 80001bba <freeproc>
          release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	8be080e7          	jalr	-1858(ra) # 80000ce6 <release>
          release(&wait_lock);
    80002430:	0000e517          	auipc	a0,0xe
    80002434:	77850513          	addi	a0,a0,1912 # 80010ba8 <wait_lock>
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	8ae080e7          	jalr	-1874(ra) # 80000ce6 <release>
          return pid;
    80002440:	a0b5                	j	800024ac <wait+0x10a>
            release(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	8a2080e7          	jalr	-1886(ra) # 80000ce6 <release>
            release(&wait_lock);
    8000244c:	0000e517          	auipc	a0,0xe
    80002450:	75c50513          	addi	a0,a0,1884 # 80010ba8 <wait_lock>
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	892080e7          	jalr	-1902(ra) # 80000ce6 <release>
            return -1;
    8000245c:	59fd                	li	s3,-1
    8000245e:	a0b9                	j	800024ac <wait+0x10a>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002460:	17048493          	addi	s1,s1,368
    80002464:	03348463          	beq	s1,s3,8000248c <wait+0xea>
      if(pp->parent == p){
    80002468:	7c9c                	ld	a5,56(s1)
    8000246a:	ff279be3          	bne	a5,s2,80002460 <wait+0xbe>
        acquire(&pp->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	7c2080e7          	jalr	1986(ra) # 80000c32 <acquire>
        if(pp->state == ZOMBIE){
    80002478:	4c9c                	lw	a5,24(s1)
    8000247a:	f7478fe3          	beq	a5,s4,800023f8 <wait+0x56>
        release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	866080e7          	jalr	-1946(ra) # 80000ce6 <release>
        havekids = 1;
    80002488:	8756                	mv	a4,s5
    8000248a:	bfd9                	j	80002460 <wait+0xbe>
    if(!havekids || killed(p)){
    8000248c:	c719                	beqz	a4,8000249a <wait+0xf8>
    8000248e:	854a                	mv	a0,s2
    80002490:	00000097          	auipc	ra,0x0
    80002494:	ee0080e7          	jalr	-288(ra) # 80002370 <killed>
    80002498:	c51d                	beqz	a0,800024c6 <wait+0x124>
      release(&wait_lock);
    8000249a:	0000e517          	auipc	a0,0xe
    8000249e:	70e50513          	addi	a0,a0,1806 # 80010ba8 <wait_lock>
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	844080e7          	jalr	-1980(ra) # 80000ce6 <release>
      return -1;
    800024aa:	59fd                	li	s3,-1
}
    800024ac:	854e                	mv	a0,s3
    800024ae:	60a6                	ld	ra,72(sp)
    800024b0:	6406                	ld	s0,64(sp)
    800024b2:	74e2                	ld	s1,56(sp)
    800024b4:	7942                	ld	s2,48(sp)
    800024b6:	79a2                	ld	s3,40(sp)
    800024b8:	7a02                	ld	s4,32(sp)
    800024ba:	6ae2                	ld	s5,24(sp)
    800024bc:	6b42                	ld	s6,16(sp)
    800024be:	6ba2                	ld	s7,8(sp)
    800024c0:	6c02                	ld	s8,0(sp)
    800024c2:	6161                	addi	sp,sp,80
    800024c4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c6:	85e2                	mv	a1,s8
    800024c8:	854a                	mv	a0,s2
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	bfe080e7          	jalr	-1026(ra) # 800020c8 <sleep>
    havekids = 0;
    800024d2:	bf29                	j	800023ec <wait+0x4a>

00000000800024d4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	e052                	sd	s4,0(sp)
    800024e2:	1800                	addi	s0,sp,48
    800024e4:	84aa                	mv	s1,a0
    800024e6:	892e                	mv	s2,a1
    800024e8:	89b2                	mv	s3,a2
    800024ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	51c080e7          	jalr	1308(ra) # 80001a08 <myproc>
  if(user_dst){
    800024f4:	c08d                	beqz	s1,80002516 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	1c6080e7          	jalr	454(ra) # 800016c4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6a02                	ld	s4,0(sp)
    80002512:	6145                	addi	sp,sp,48
    80002514:	8082                	ret
    memmove((char *)dst, src, len);
    80002516:	000a061b          	sext.w	a2,s4
    8000251a:	85ce                	mv	a1,s3
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	86c080e7          	jalr	-1940(ra) # 80000d8a <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyout+0x32>

000000008000252a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	e052                	sd	s4,0(sp)
    80002538:	1800                	addi	s0,sp,48
    8000253a:	892a                	mv	s2,a0
    8000253c:	84ae                	mv	s1,a1
    8000253e:	89b2                	mv	s3,a2
    80002540:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	4c6080e7          	jalr	1222(ra) # 80001a08 <myproc>
  if(user_src){
    8000254a:	c08d                	beqz	s1,8000256c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000254c:	86d2                	mv	a3,s4
    8000254e:	864e                	mv	a2,s3
    80002550:	85ca                	mv	a1,s2
    80002552:	6928                	ld	a0,80(a0)
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	1fc080e7          	jalr	508(ra) # 80001750 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000255c:	70a2                	ld	ra,40(sp)
    8000255e:	7402                	ld	s0,32(sp)
    80002560:	64e2                	ld	s1,24(sp)
    80002562:	6942                	ld	s2,16(sp)
    80002564:	69a2                	ld	s3,8(sp)
    80002566:	6a02                	ld	s4,0(sp)
    80002568:	6145                	addi	sp,sp,48
    8000256a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000256c:	000a061b          	sext.w	a2,s4
    80002570:	85ce                	mv	a1,s3
    80002572:	854a                	mv	a0,s2
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	816080e7          	jalr	-2026(ra) # 80000d8a <memmove>
    return 0;
    8000257c:	8526                	mv	a0,s1
    8000257e:	bff9                	j	8000255c <either_copyin+0x32>

0000000080002580 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002580:	715d                	addi	sp,sp,-80
    80002582:	e486                	sd	ra,72(sp)
    80002584:	e0a2                	sd	s0,64(sp)
    80002586:	fc26                	sd	s1,56(sp)
    80002588:	f84a                	sd	s2,48(sp)
    8000258a:	f44e                	sd	s3,40(sp)
    8000258c:	f052                	sd	s4,32(sp)
    8000258e:	ec56                	sd	s5,24(sp)
    80002590:	e85a                	sd	s6,16(sp)
    80002592:	e45e                	sd	s7,8(sp)
    80002594:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	b3250513          	addi	a0,a0,-1230 # 800080c8 <digits+0x88>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	fea080e7          	jalr	-22(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	b7248493          	addi	s1,s1,-1166 # 80011118 <proc+0x158>
    800025ae:	00014917          	auipc	s2,0x14
    800025b2:	76a90913          	addi	s2,s2,1898 # 80016d18 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b8:	00006997          	auipc	s3,0x6
    800025bc:	cc898993          	addi	s3,s3,-824 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025c0:	00006a97          	auipc	s5,0x6
    800025c4:	cc8a8a93          	addi	s5,s5,-824 # 80008288 <digits+0x248>
    printf("\n");
    800025c8:	00006a17          	auipc	s4,0x6
    800025cc:	b00a0a13          	addi	s4,s4,-1280 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d0:	00006b97          	auipc	s7,0x6
    800025d4:	d28b8b93          	addi	s7,s7,-728 # 800082f8 <states.0>
    800025d8:	a00d                	j	800025fa <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025da:	ed86a583          	lw	a1,-296(a3)
    800025de:	8556                	mv	a0,s5
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	fa8080e7          	jalr	-88(ra) # 80000588 <printf>
    printf("\n");
    800025e8:	8552                	mv	a0,s4
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	f9e080e7          	jalr	-98(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f2:	17048493          	addi	s1,s1,368
    800025f6:	03248163          	beq	s1,s2,80002618 <procdump+0x98>
    if(p->state == UNUSED)
    800025fa:	86a6                	mv	a3,s1
    800025fc:	ec04a783          	lw	a5,-320(s1)
    80002600:	dbed                	beqz	a5,800025f2 <procdump+0x72>
      state = "???";
    80002602:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002604:	fcfb6be3          	bltu	s6,a5,800025da <procdump+0x5a>
    80002608:	1782                	slli	a5,a5,0x20
    8000260a:	9381                	srli	a5,a5,0x20
    8000260c:	078e                	slli	a5,a5,0x3
    8000260e:	97de                	add	a5,a5,s7
    80002610:	6390                	ld	a2,0(a5)
    80002612:	f661                	bnez	a2,800025da <procdump+0x5a>
      state = "???";
    80002614:	864e                	mv	a2,s3
    80002616:	b7d1                	j	800025da <procdump+0x5a>
  }
}
    80002618:	60a6                	ld	ra,72(sp)
    8000261a:	6406                	ld	s0,64(sp)
    8000261c:	74e2                	ld	s1,56(sp)
    8000261e:	7942                	ld	s2,48(sp)
    80002620:	79a2                	ld	s3,40(sp)
    80002622:	7a02                	ld	s4,32(sp)
    80002624:	6ae2                	ld	s5,24(sp)
    80002626:	6b42                	ld	s6,16(sp)
    80002628:	6ba2                	ld	s7,8(sp)
    8000262a:	6161                	addi	sp,sp,80
    8000262c:	8082                	ret

000000008000262e <getHelloWorld>:

uint64 
getHelloWorld(void)
{
    8000262e:	1141                	addi	sp,sp,-16
    80002630:	e406                	sd	ra,8(sp)
    80002632:	e022                	sd	s0,0(sp)
    80002634:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    80002636:	00006517          	auipc	a0,0x6
    8000263a:	c6250513          	addi	a0,a0,-926 # 80008298 <digits+0x258>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	f4a080e7          	jalr	-182(ra) # 80000588 <printf>
  return 0;
}
    80002646:	4501                	li	a0,0
    80002648:	60a2                	ld	ra,8(sp)
    8000264a:	6402                	ld	s0,0(sp)
    8000264c:	0141                	addi	sp,sp,16
    8000264e:	8082                	ret

0000000080002650 <getProcTick>:

int 
getProcTick(int pid){
    80002650:	7139                	addi	sp,sp,-64
    80002652:	fc06                	sd	ra,56(sp)
    80002654:	f822                	sd	s0,48(sp)
    80002656:	f426                	sd	s1,40(sp)
    80002658:	f04a                	sd	s2,32(sp)
    8000265a:	ec4e                	sd	s3,24(sp)
    8000265c:	e852                	sd	s4,16(sp)
    8000265e:	e456                	sd	s5,8(sp)
    80002660:	0080                	addi	s0,sp,64
    80002662:	892a                	mv	s2,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002664:	0000f497          	auipc	s1,0xf
    80002668:	95c48493          	addi	s1,s1,-1700 # 80010fc0 <proc>
   acquire(&p->lock);
    // acquire(&tickslock);
    if(pid == p->pid){
      int diff = ticks - p->ctime;
    8000266c:	00006a97          	auipc	s5,0x6
    80002670:	2b4a8a93          	addi	s5,s5,692 # 80008920 <ticks>
      if (diff < 0){
        diff = diff * -1; 
      }
      printf("%d\n", diff);
    80002674:	00006a17          	auipc	s4,0x6
    80002678:	deca0a13          	addi	s4,s4,-532 # 80008460 <states.0+0x168>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267c:	00014997          	auipc	s3,0x14
    80002680:	54498993          	addi	s3,s3,1348 # 80016bc0 <tickslock>
    80002684:	a811                	j	80002698 <getProcTick+0x48>
    }
   release(&p->lock);
    80002686:	8526                	mv	a0,s1
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	65e080e7          	jalr	1630(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002690:	17048493          	addi	s1,s1,368
    80002694:	03348a63          	beq	s1,s3,800026c8 <getProcTick+0x78>
   acquire(&p->lock);
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	598080e7          	jalr	1432(ra) # 80000c32 <acquire>
    if(pid == p->pid){
    800026a2:	589c                	lw	a5,48(s1)
    800026a4:	ff2791e3          	bne	a5,s2,80002686 <getProcTick+0x36>
      int diff = ticks - p->ctime;
    800026a8:	000aa783          	lw	a5,0(s5)
    800026ac:	1684a583          	lw	a1,360(s1)
    800026b0:	9f8d                	subw	a5,a5,a1
      printf("%d\n", diff);
    800026b2:	41f7d59b          	sraiw	a1,a5,0x1f
    800026b6:	8fad                	xor	a5,a5,a1
    800026b8:	40b785bb          	subw	a1,a5,a1
    800026bc:	8552                	mv	a0,s4
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	eca080e7          	jalr	-310(ra) # 80000588 <printf>
    800026c6:	b7c1                	j	80002686 <getProcTick+0x36>
  //  release(&tickslock);
  }
  return 0;
}
    800026c8:	4501                	li	a0,0
    800026ca:	70e2                	ld	ra,56(sp)
    800026cc:	7442                	ld	s0,48(sp)
    800026ce:	74a2                	ld	s1,40(sp)
    800026d0:	7902                	ld	s2,32(sp)
    800026d2:	69e2                	ld	s3,24(sp)
    800026d4:	6a42                	ld	s4,16(sp)
    800026d6:	6aa2                	ld	s5,8(sp)
    800026d8:	6121                	addi	sp,sp,64
    800026da:	8082                	ret

00000000800026dc <getProcInfo>:

int 
getProcInfo(void){
    800026dc:	7179                	addi	sp,sp,-48
    800026de:	f406                	sd	ra,40(sp)
    800026e0:	f022                	sd	s0,32(sp)
    800026e2:	ec26                	sd	s1,24(sp)
    800026e4:	e84a                	sd	s2,16(sp)
    800026e6:	e44e                	sd	s3,8(sp)
    800026e8:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    800026ea:	0000f497          	auipc	s1,0xf
    800026ee:	8d648493          	addi	s1,s1,-1834 # 80010fc0 <proc>
  
  // for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
  if(p->state != UNUSED)
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    800026f2:	00006997          	auipc	s3,0x6
    800026f6:	bb698993          	addi	s3,s3,-1098 # 800082a8 <digits+0x268>
  for(p = proc; p < &proc[NPROC]; p++){
    800026fa:	00014917          	auipc	s2,0x14
    800026fe:	4c690913          	addi	s2,s2,1222 # 80016bc0 <tickslock>
    80002702:	a029                	j	8000270c <getProcInfo+0x30>
    80002704:	17048493          	addi	s1,s1,368
    80002708:	01248d63          	beq	s1,s2,80002722 <getProcInfo+0x46>
  if(p->state != UNUSED)
    8000270c:	4c9c                	lw	a5,24(s1)
    8000270e:	dbfd                	beqz	a5,80002704 <getProcInfo+0x28>
    printf("#pid = %d, create time = %d\n", p->pid, p->ctime);
    80002710:	1684a603          	lw	a2,360(s1)
    80002714:	588c                	lw	a1,48(s1)
    80002716:	854e                	mv	a0,s3
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	e70080e7          	jalr	-400(ra) # 80000588 <printf>
    80002720:	b7d5                	j	80002704 <getProcInfo+0x28>
    // if(p->state == SLEEPING){
    //   cprintf("-pid = %d, create time = %d\n", p->pid, p->ctime);
    // }
  }
  return 0;
}
    80002722:	4501                	li	a0,0
    80002724:	70a2                	ld	ra,40(sp)
    80002726:	7402                	ld	s0,32(sp)
    80002728:	64e2                	ld	s1,24(sp)
    8000272a:	6942                	ld	s2,16(sp)
    8000272c:	69a2                	ld	s3,8(sp)
    8000272e:	6145                	addi	sp,sp,48
    80002730:	8082                	ret

0000000080002732 <nproc>:
//   printf("sysinfo ?????\n");
//   return 0;
// }
uint64
nproc(struct sysinfo *addr)
{
    80002732:	7179                	addi	sp,sp,-48
    80002734:	f406                	sd	ra,40(sp)
    80002736:	f022                	sd	s0,32(sp)
    80002738:	ec26                	sd	s1,24(sp)
    8000273a:	e84a                	sd	s2,16(sp)
    8000273c:	e44e                	sd	s3,8(sp)
    8000273e:	e052                	sd	s4,0(sp)
    80002740:	1800                	addi	s0,sp,48
  uint64 cnt = 0;

  for (int i = 0; i < NPROC; i++) {
    80002742:	0000f497          	auipc	s1,0xf
    80002746:	87e48493          	addi	s1,s1,-1922 # 80010fc0 <proc>
    8000274a:	00014a17          	auipc	s4,0x14
    8000274e:	476a0a13          	addi	s4,s4,1142 # 80016bc0 <tickslock>
  uint64 cnt = 0;
    80002752:	4901                	li	s2,0
    acquire(&proc[i].lock); 
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	4dc080e7          	jalr	1244(ra) # 80000c32 <acquire>
    if (proc[i].state != UNUSED)
    8000275e:	4c9c                	lw	a5,24(s1)
      cnt++;
    80002760:	00f037b3          	snez	a5,a5
    80002764:	993e                	add	s2,s2,a5
    release(&proc[i].lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	57e080e7          	jalr	1406(ra) # 80000ce6 <release>
  for (int i = 0; i < NPROC; i++) {
    80002770:	17048493          	addi	s1,s1,368
    80002774:	ff4490e3          	bne	s1,s4,80002754 <nproc+0x22>
  }

  return cnt;
}
    80002778:	854a                	mv	a0,s2
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6a02                	ld	s4,0(sp)
    80002786:	6145                	addi	sp,sp,48
    80002788:	8082                	ret

000000008000278a <getTicks>:

double 
getTicks(void){
    8000278a:	1141                	addi	sp,sp,-16
    8000278c:	e422                	sd	s0,8(sp)
    8000278e:	0800                	addi	s0,sp,16
  return ticks;
}
    80002790:	00006797          	auipc	a5,0x6
    80002794:	1907a783          	lw	a5,400(a5) # 80008920 <ticks>
    80002798:	d2178553          	fcvt.d.wu	fa0,a5
    8000279c:	6422                	ld	s0,8(sp)
    8000279e:	0141                	addi	sp,sp,16
    800027a0:	8082                	ret

00000000800027a2 <changeSch>:
//     return -1;
//   return 0;
// }

int
changeSch(void){
    800027a2:	1141                	addi	sp,sp,-16
    800027a4:	e422                	sd	s0,8(sp)
    800027a6:	0800                	addi	s0,sp,16

  return 0;
}
    800027a8:	4501                	li	a0,0
    800027aa:	6422                	ld	s0,8(sp)
    800027ac:	0141                	addi	sp,sp,16
    800027ae:	8082                	ret

00000000800027b0 <swtch>:
    800027b0:	00153023          	sd	ra,0(a0)
    800027b4:	00253423          	sd	sp,8(a0)
    800027b8:	e900                	sd	s0,16(a0)
    800027ba:	ed04                	sd	s1,24(a0)
    800027bc:	03253023          	sd	s2,32(a0)
    800027c0:	03353423          	sd	s3,40(a0)
    800027c4:	03453823          	sd	s4,48(a0)
    800027c8:	03553c23          	sd	s5,56(a0)
    800027cc:	05653023          	sd	s6,64(a0)
    800027d0:	05753423          	sd	s7,72(a0)
    800027d4:	05853823          	sd	s8,80(a0)
    800027d8:	05953c23          	sd	s9,88(a0)
    800027dc:	07a53023          	sd	s10,96(a0)
    800027e0:	07b53423          	sd	s11,104(a0)
    800027e4:	0005b083          	ld	ra,0(a1)
    800027e8:	0085b103          	ld	sp,8(a1)
    800027ec:	6980                	ld	s0,16(a1)
    800027ee:	6d84                	ld	s1,24(a1)
    800027f0:	0205b903          	ld	s2,32(a1)
    800027f4:	0285b983          	ld	s3,40(a1)
    800027f8:	0305ba03          	ld	s4,48(a1)
    800027fc:	0385ba83          	ld	s5,56(a1)
    80002800:	0405bb03          	ld	s6,64(a1)
    80002804:	0485bb83          	ld	s7,72(a1)
    80002808:	0505bc03          	ld	s8,80(a1)
    8000280c:	0585bc83          	ld	s9,88(a1)
    80002810:	0605bd03          	ld	s10,96(a1)
    80002814:	0685bd83          	ld	s11,104(a1)
    80002818:	8082                	ret

000000008000281a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000281a:	1141                	addi	sp,sp,-16
    8000281c:	e406                	sd	ra,8(sp)
    8000281e:	e022                	sd	s0,0(sp)
    80002820:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002822:	00006597          	auipc	a1,0x6
    80002826:	b0658593          	addi	a1,a1,-1274 # 80008328 <states.0+0x30>
    8000282a:	00014517          	auipc	a0,0x14
    8000282e:	39650513          	addi	a0,a0,918 # 80016bc0 <tickslock>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	370080e7          	jalr	880(ra) # 80000ba2 <initlock>
}
    8000283a:	60a2                	ld	ra,8(sp)
    8000283c:	6402                	ld	s0,0(sp)
    8000283e:	0141                	addi	sp,sp,16
    80002840:	8082                	ret

0000000080002842 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e422                	sd	s0,8(sp)
    80002846:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00003797          	auipc	a5,0x3
    8000284c:	5a878793          	addi	a5,a5,1448 # 80005df0 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002854:	6422                	ld	s0,8(sp)
    80002856:	0141                	addi	sp,sp,16
    80002858:	8082                	ret

000000008000285a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000285a:	1141                	addi	sp,sp,-16
    8000285c:	e406                	sd	ra,8(sp)
    8000285e:	e022                	sd	s0,0(sp)
    80002860:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	1a6080e7          	jalr	422(ra) # 80001a08 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002874:	00004617          	auipc	a2,0x4
    80002878:	78c60613          	addi	a2,a2,1932 # 80007000 <_trampoline>
    8000287c:	00004697          	auipc	a3,0x4
    80002880:	78468693          	addi	a3,a3,1924 # 80007000 <_trampoline>
    80002884:	8e91                	sub	a3,a3,a2
    80002886:	040007b7          	lui	a5,0x4000
    8000288a:	17fd                	addi	a5,a5,-1
    8000288c:	07b2                	slli	a5,a5,0xc
    8000288e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002890:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002896:	180026f3          	csrr	a3,satp
    8000289a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289c:	6d38                	ld	a4,88(a0)
    8000289e:	6134                	ld	a3,64(a0)
    800028a0:	6585                	lui	a1,0x1
    800028a2:	96ae                	add	a3,a3,a1
    800028a4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a6:	6d38                	ld	a4,88(a0)
    800028a8:	00000697          	auipc	a3,0x0
    800028ac:	13068693          	addi	a3,a3,304 # 800029d8 <usertrap>
    800028b0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b4:	8692                	mv	a3,tp
    800028b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ca:	6f18                	ld	a4,24(a4)
    800028cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d0:	6928                	ld	a0,80(a0)
    800028d2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028d4:	00004717          	auipc	a4,0x4
    800028d8:	7c870713          	addi	a4,a4,1992 # 8000709c <userret>
    800028dc:	8f11                	sub	a4,a4,a2
    800028de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028e0:	577d                	li	a4,-1
    800028e2:	177e                	slli	a4,a4,0x3f
    800028e4:	8d59                	or	a0,a0,a4
    800028e6:	9782                	jalr	a5
}
    800028e8:	60a2                	ld	ra,8(sp)
    800028ea:	6402                	ld	s0,0(sp)
    800028ec:	0141                	addi	sp,sp,16
    800028ee:	8082                	ret

00000000800028f0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028f0:	1101                	addi	sp,sp,-32
    800028f2:	ec06                	sd	ra,24(sp)
    800028f4:	e822                	sd	s0,16(sp)
    800028f6:	e426                	sd	s1,8(sp)
    800028f8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fa:	00014497          	auipc	s1,0x14
    800028fe:	2c648493          	addi	s1,s1,710 # 80016bc0 <tickslock>
    80002902:	8526                	mv	a0,s1
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	32e080e7          	jalr	814(ra) # 80000c32 <acquire>
  ticks++;
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	01450513          	addi	a0,a0,20 # 80008920 <ticks>
    80002914:	411c                	lw	a5,0(a0)
    80002916:	2785                	addiw	a5,a5,1
    80002918:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	812080e7          	jalr	-2030(ra) # 8000212c <wakeup>
  release(&tickslock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	3c2080e7          	jalr	962(ra) # 80000ce6 <release>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret

0000000080002936 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002936:	1101                	addi	sp,sp,-32
    80002938:	ec06                	sd	ra,24(sp)
    8000293a:	e822                	sd	s0,16(sp)
    8000293c:	e426                	sd	s1,8(sp)
    8000293e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002940:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002944:	00074d63          	bltz	a4,8000295e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002948:	57fd                	li	a5,-1
    8000294a:	17fe                	slli	a5,a5,0x3f
    8000294c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000294e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002950:	06f70363          	beq	a4,a5,800029b6 <devintr+0x80>
  }
}
    80002954:	60e2                	ld	ra,24(sp)
    80002956:	6442                	ld	s0,16(sp)
    80002958:	64a2                	ld	s1,8(sp)
    8000295a:	6105                	addi	sp,sp,32
    8000295c:	8082                	ret
     (scause & 0xff) == 9){
    8000295e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002962:	46a5                	li	a3,9
    80002964:	fed792e3          	bne	a5,a3,80002948 <devintr+0x12>
    int irq = plic_claim();
    80002968:	00003097          	auipc	ra,0x3
    8000296c:	590080e7          	jalr	1424(ra) # 80005ef8 <plic_claim>
    80002970:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002972:	47a9                	li	a5,10
    80002974:	02f50763          	beq	a0,a5,800029a2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002978:	4785                	li	a5,1
    8000297a:	02f50963          	beq	a0,a5,800029ac <devintr+0x76>
    return 1;
    8000297e:	4505                	li	a0,1
    } else if(irq){
    80002980:	d8f1                	beqz	s1,80002954 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002982:	85a6                	mv	a1,s1
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9ac50513          	addi	a0,a0,-1620 # 80008330 <states.0+0x38>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bfc080e7          	jalr	-1028(ra) # 80000588 <printf>
      plic_complete(irq);
    80002994:	8526                	mv	a0,s1
    80002996:	00003097          	auipc	ra,0x3
    8000299a:	586080e7          	jalr	1414(ra) # 80005f1c <plic_complete>
    return 1;
    8000299e:	4505                	li	a0,1
    800029a0:	bf55                	j	80002954 <devintr+0x1e>
      uartintr();
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	ff8080e7          	jalr	-8(ra) # 8000099a <uartintr>
    800029aa:	b7ed                	j	80002994 <devintr+0x5e>
      virtio_disk_intr();
    800029ac:	00004097          	auipc	ra,0x4
    800029b0:	a3c080e7          	jalr	-1476(ra) # 800063e8 <virtio_disk_intr>
    800029b4:	b7c5                	j	80002994 <devintr+0x5e>
    if(cpuid() == 0){
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	026080e7          	jalr	38(ra) # 800019dc <cpuid>
    800029be:	c901                	beqz	a0,800029ce <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029c0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029c4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029c6:	14479073          	csrw	sip,a5
    return 2;
    800029ca:	4509                	li	a0,2
    800029cc:	b761                	j	80002954 <devintr+0x1e>
      clockintr();
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	f22080e7          	jalr	-222(ra) # 800028f0 <clockintr>
    800029d6:	b7ed                	j	800029c0 <devintr+0x8a>

00000000800029d8 <usertrap>:
{
    800029d8:	1101                	addi	sp,sp,-32
    800029da:	ec06                	sd	ra,24(sp)
    800029dc:	e822                	sd	s0,16(sp)
    800029de:	e426                	sd	s1,8(sp)
    800029e0:	e04a                	sd	s2,0(sp)
    800029e2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029e8:	1007f793          	andi	a5,a5,256
    800029ec:	e3b1                	bnez	a5,80002a30 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ee:	00003797          	auipc	a5,0x3
    800029f2:	40278793          	addi	a5,a5,1026 # 80005df0 <kernelvec>
    800029f6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	00e080e7          	jalr	14(ra) # 80001a08 <myproc>
    80002a02:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a04:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	14102773          	csrr	a4,sepc
    80002a0a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a10:	47a1                	li	a5,8
    80002a12:	02f70763          	beq	a4,a5,80002a40 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	f20080e7          	jalr	-224(ra) # 80002936 <devintr>
    80002a1e:	892a                	mv	s2,a0
    80002a20:	c151                	beqz	a0,80002aa4 <usertrap+0xcc>
  if(killed(p))
    80002a22:	8526                	mv	a0,s1
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	94c080e7          	jalr	-1716(ra) # 80002370 <killed>
    80002a2c:	c929                	beqz	a0,80002a7e <usertrap+0xa6>
    80002a2e:	a099                	j	80002a74 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	92050513          	addi	a0,a0,-1760 # 80008350 <states.0+0x58>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>
    if(killed(p))
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	930080e7          	jalr	-1744(ra) # 80002370 <killed>
    80002a48:	e921                	bnez	a0,80002a98 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a4a:	6cb8                	ld	a4,88(s1)
    80002a4c:	6f1c                	ld	a5,24(a4)
    80002a4e:	0791                	addi	a5,a5,4
    80002a50:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	2d4080e7          	jalr	724(ra) # 80002d32 <syscall>
  if(killed(p))
    80002a66:	8526                	mv	a0,s1
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	908080e7          	jalr	-1784(ra) # 80002370 <killed>
    80002a70:	c911                	beqz	a0,80002a84 <usertrap+0xac>
    80002a72:	4901                	li	s2,0
    exit(-1);
    80002a74:	557d                	li	a0,-1
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	786080e7          	jalr	1926(ra) # 800021fc <exit>
    if(which_dev == 2)
    80002a7e:	4789                	li	a5,2
    80002a80:	04f90f63          	beq	s2,a5,80002ade <usertrap+0x106>
  usertrapret();
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	dd6080e7          	jalr	-554(ra) # 8000285a <usertrapret>
}
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6902                	ld	s2,0(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
      exit(-1);
    80002a98:	557d                	li	a0,-1
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	762080e7          	jalr	1890(ra) # 800021fc <exit>
    80002aa2:	b765                	j	80002a4a <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aa8:	5890                	lw	a2,48(s1)
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	8c650513          	addi	a0,a0,-1850 # 80008370 <states.0+0x78>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ad6080e7          	jalr	-1322(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002abe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	8de50513          	addi	a0,a0,-1826 # 800083a0 <states.0+0xa8>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	abe080e7          	jalr	-1346(ra) # 80000588 <printf>
    setkilled(p);
    80002ad2:	8526                	mv	a0,s1
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	870080e7          	jalr	-1936(ra) # 80002344 <setkilled>
    80002adc:	b769                	j	80002a66 <usertrap+0x8e>
      yield();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	5ae080e7          	jalr	1454(ra) # 8000208c <yield>
    80002ae6:	bf79                	j	80002a84 <usertrap+0xac>

0000000080002ae8 <kerneltrap>:
{
    80002ae8:	7179                	addi	sp,sp,-48
    80002aea:	f406                	sd	ra,40(sp)
    80002aec:	f022                	sd	s0,32(sp)
    80002aee:	ec26                	sd	s1,24(sp)
    80002af0:	e84a                	sd	s2,16(sp)
    80002af2:	e44e                	sd	s3,8(sp)
    80002af4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b02:	1004f793          	andi	a5,s1,256
    80002b06:	cb85                	beqz	a5,80002b36 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b0e:	ef85                	bnez	a5,80002b46 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	e26080e7          	jalr	-474(ra) # 80002936 <devintr>
    80002b18:	cd1d                	beqz	a0,80002b56 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1a:	4789                	li	a5,2
    80002b1c:	06f50a63          	beq	a0,a5,80002b90 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b20:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b24:	10049073          	csrw	sstatus,s1
}
    80002b28:	70a2                	ld	ra,40(sp)
    80002b2a:	7402                	ld	s0,32(sp)
    80002b2c:	64e2                	ld	s1,24(sp)
    80002b2e:	6942                	ld	s2,16(sp)
    80002b30:	69a2                	ld	s3,8(sp)
    80002b32:	6145                	addi	sp,sp,48
    80002b34:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	88a50513          	addi	a0,a0,-1910 # 800083c0 <states.0+0xc8>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a00080e7          	jalr	-1536(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	8a250513          	addi	a0,a0,-1886 # 800083e8 <states.0+0xf0>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b56:	85ce                	mv	a1,s3
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	8b050513          	addi	a0,a0,-1872 # 80008408 <states.0+0x110>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a28080e7          	jalr	-1496(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	8a850513          	addi	a0,a0,-1880 # 80008418 <states.0+0x120>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a10080e7          	jalr	-1520(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	8b050513          	addi	a0,a0,-1872 # 80008430 <states.0+0x138>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	9b6080e7          	jalr	-1610(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	e78080e7          	jalr	-392(ra) # 80001a08 <myproc>
    80002b98:	d541                	beqz	a0,80002b20 <kerneltrap+0x38>
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	e6e080e7          	jalr	-402(ra) # 80001a08 <myproc>
    80002ba2:	4d18                	lw	a4,24(a0)
    80002ba4:	4791                	li	a5,4
    80002ba6:	f6f71de3          	bne	a4,a5,80002b20 <kerneltrap+0x38>
    yield();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	4e2080e7          	jalr	1250(ra) # 8000208c <yield>
    80002bb2:	b7bd                	j	80002b20 <kerneltrap+0x38>

0000000080002bb4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	e48080e7          	jalr	-440(ra) # 80001a08 <myproc>
  switch (n) {
    80002bc8:	4795                	li	a5,5
    80002bca:	0497e163          	bltu	a5,s1,80002c0c <argraw+0x58>
    80002bce:	048a                	slli	s1,s1,0x2
    80002bd0:	00006717          	auipc	a4,0x6
    80002bd4:	89870713          	addi	a4,a4,-1896 # 80008468 <states.0+0x170>
    80002bd8:	94ba                	add	s1,s1,a4
    80002bda:	409c                	lw	a5,0(s1)
    80002bdc:	97ba                	add	a5,a5,a4
    80002bde:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be0:	6d3c                	ld	a5,88(a0)
    80002be2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	64a2                	ld	s1,8(sp)
    80002bea:	6105                	addi	sp,sp,32
    80002bec:	8082                	ret
    return p->trapframe->a1;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	7fa8                	ld	a0,120(a5)
    80002bf2:	bfcd                	j	80002be4 <argraw+0x30>
    return p->trapframe->a2;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	63c8                	ld	a0,128(a5)
    80002bf8:	b7f5                	j	80002be4 <argraw+0x30>
    return p->trapframe->a3;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	67c8                	ld	a0,136(a5)
    80002bfe:	b7dd                	j	80002be4 <argraw+0x30>
    return p->trapframe->a4;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	6bc8                	ld	a0,144(a5)
    80002c04:	b7c5                	j	80002be4 <argraw+0x30>
    return p->trapframe->a5;
    80002c06:	6d3c                	ld	a5,88(a0)
    80002c08:	6fc8                	ld	a0,152(a5)
    80002c0a:	bfe9                	j	80002be4 <argraw+0x30>
  panic("argraw");
    80002c0c:	00006517          	auipc	a0,0x6
    80002c10:	83450513          	addi	a0,a0,-1996 # 80008440 <states.0+0x148>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	92a080e7          	jalr	-1750(ra) # 8000053e <panic>

0000000080002c1c <fetchaddr>:
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	e426                	sd	s1,8(sp)
    80002c24:	e04a                	sd	s2,0(sp)
    80002c26:	1000                	addi	s0,sp,32
    80002c28:	84aa                	mv	s1,a0
    80002c2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	ddc080e7          	jalr	-548(ra) # 80001a08 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c34:	653c                	ld	a5,72(a0)
    80002c36:	02f4f863          	bgeu	s1,a5,80002c66 <fetchaddr+0x4a>
    80002c3a:	00848713          	addi	a4,s1,8
    80002c3e:	02e7e663          	bltu	a5,a4,80002c6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c42:	46a1                	li	a3,8
    80002c44:	8626                	mv	a2,s1
    80002c46:	85ca                	mv	a1,s2
    80002c48:	6928                	ld	a0,80(a0)
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	b06080e7          	jalr	-1274(ra) # 80001750 <copyin>
    80002c52:	00a03533          	snez	a0,a0
    80002c56:	40a00533          	neg	a0,a0
}
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6902                	ld	s2,0(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret
    return -1;
    80002c66:	557d                	li	a0,-1
    80002c68:	bfcd                	j	80002c5a <fetchaddr+0x3e>
    80002c6a:	557d                	li	a0,-1
    80002c6c:	b7fd                	j	80002c5a <fetchaddr+0x3e>

0000000080002c6e <fetchstr>:
{
    80002c6e:	7179                	addi	sp,sp,-48
    80002c70:	f406                	sd	ra,40(sp)
    80002c72:	f022                	sd	s0,32(sp)
    80002c74:	ec26                	sd	s1,24(sp)
    80002c76:	e84a                	sd	s2,16(sp)
    80002c78:	e44e                	sd	s3,8(sp)
    80002c7a:	1800                	addi	s0,sp,48
    80002c7c:	892a                	mv	s2,a0
    80002c7e:	84ae                	mv	s1,a1
    80002c80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	d86080e7          	jalr	-634(ra) # 80001a08 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c8a:	86ce                	mv	a3,s3
    80002c8c:	864a                	mv	a2,s2
    80002c8e:	85a6                	mv	a1,s1
    80002c90:	6928                	ld	a0,80(a0)
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	b4c080e7          	jalr	-1204(ra) # 800017de <copyinstr>
    80002c9a:	00054e63          	bltz	a0,80002cb6 <fetchstr+0x48>
  return strlen(buf);
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	20a080e7          	jalr	522(ra) # 80000eaa <strlen>
}
    80002ca8:	70a2                	ld	ra,40(sp)
    80002caa:	7402                	ld	s0,32(sp)
    80002cac:	64e2                	ld	s1,24(sp)
    80002cae:	6942                	ld	s2,16(sp)
    80002cb0:	69a2                	ld	s3,8(sp)
    80002cb2:	6145                	addi	sp,sp,48
    80002cb4:	8082                	ret
    return -1;
    80002cb6:	557d                	li	a0,-1
    80002cb8:	bfc5                	j	80002ca8 <fetchstr+0x3a>

0000000080002cba <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	e426                	sd	s1,8(sp)
    80002cc2:	1000                	addi	s0,sp,32
    80002cc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	eee080e7          	jalr	-274(ra) # 80002bb4 <argraw>
    80002cce:	c088                	sw	a0,0(s1)
}
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	64a2                	ld	s1,8(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{ 
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	ece080e7          	jalr	-306(ra) # 80002bb4 <argraw>
    80002cee:	e088                	sd	a0,0(s1)
  // return 0;
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6105                	addi	sp,sp,32
    80002cf8:	8082                	ret

0000000080002cfa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cfa:	7179                	addi	sp,sp,-48
    80002cfc:	f406                	sd	ra,40(sp)
    80002cfe:	f022                	sd	s0,32(sp)
    80002d00:	ec26                	sd	s1,24(sp)
    80002d02:	e84a                	sd	s2,16(sp)
    80002d04:	1800                	addi	s0,sp,48
    80002d06:	84ae                	mv	s1,a1
    80002d08:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d0a:	fd840593          	addi	a1,s0,-40
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	fcc080e7          	jalr	-52(ra) # 80002cda <argaddr>
  return fetchstr(addr, buf, max);
    80002d16:	864a                	mv	a2,s2
    80002d18:	85a6                	mv	a1,s1
    80002d1a:	fd843503          	ld	a0,-40(s0)
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	f50080e7          	jalr	-176(ra) # 80002c6e <fetchstr>
}
    80002d26:	70a2                	ld	ra,40(sp)
    80002d28:	7402                	ld	s0,32(sp)
    80002d2a:	64e2                	ld	s1,24(sp)
    80002d2c:	6942                	ld	s2,16(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret

0000000080002d32 <syscall>:
[SYS_changeSch] sys_changeSch,
};

void
syscall(void)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	e04a                	sd	s2,0(sp)
    80002d3c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	cca080e7          	jalr	-822(ra) # 80001a08 <myproc>
    80002d46:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d48:	05853903          	ld	s2,88(a0)
    80002d4c:	0a893783          	ld	a5,168(s2)
    80002d50:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d54:	37fd                	addiw	a5,a5,-1
    80002d56:	4765                	li	a4,25
    80002d58:	00f76f63          	bltu	a4,a5,80002d76 <syscall+0x44>
    80002d5c:	00369713          	slli	a4,a3,0x3
    80002d60:	00005797          	auipc	a5,0x5
    80002d64:	72078793          	addi	a5,a5,1824 # 80008480 <syscalls>
    80002d68:	97ba                	add	a5,a5,a4
    80002d6a:	639c                	ld	a5,0(a5)
    80002d6c:	c789                	beqz	a5,80002d76 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d6e:	9782                	jalr	a5
    80002d70:	06a93823          	sd	a0,112(s2)
    80002d74:	a839                	j	80002d92 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d76:	15848613          	addi	a2,s1,344
    80002d7a:	588c                	lw	a1,48(s1)
    80002d7c:	00005517          	auipc	a0,0x5
    80002d80:	6cc50513          	addi	a0,a0,1740 # 80008448 <states.0+0x150>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	804080e7          	jalr	-2044(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d8c:	6cbc                	ld	a5,88(s1)
    80002d8e:	577d                	li	a4,-1
    80002d90:	fbb8                	sd	a4,112(a5)
  }
}
    80002d92:	60e2                	ld	ra,24(sp)
    80002d94:	6442                	ld	s0,16(sp)
    80002d96:	64a2                	ld	s1,8(sp)
    80002d98:	6902                	ld	s2,0(sp)
    80002d9a:	6105                	addi	sp,sp,32
    80002d9c:	8082                	ret

0000000080002d9e <sys_exit>:
#include "sysinfo.h"
// #include "kalloc.c"

uint64
sys_exit(void)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002da6:	fec40593          	addi	a1,s0,-20
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	f0e080e7          	jalr	-242(ra) # 80002cba <argint>
  exit(n);
    80002db4:	fec42503          	lw	a0,-20(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	444080e7          	jalr	1092(ra) # 800021fc <exit>
  return 0;  // not reached
}
    80002dc0:	4501                	li	a0,0
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dca:	1141                	addi	sp,sp,-16
    80002dcc:	e406                	sd	ra,8(sp)
    80002dce:	e022                	sd	s0,0(sp)
    80002dd0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	c36080e7          	jalr	-970(ra) # 80001a08 <myproc>
}
    80002dda:	5908                	lw	a0,48(a0)
    80002ddc:	60a2                	ld	ra,8(sp)
    80002dde:	6402                	ld	s0,0(sp)
    80002de0:	0141                	addi	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <sys_fork>:

uint64
sys_fork(void)
{
    80002de4:	1141                	addi	sp,sp,-16
    80002de6:	e406                	sd	ra,8(sp)
    80002de8:	e022                	sd	s0,0(sp)
    80002dea:	0800                	addi	s0,sp,16
  return fork();
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	fea080e7          	jalr	-22(ra) # 80001dd6 <fork>
}
    80002df4:	60a2                	ld	ra,8(sp)
    80002df6:	6402                	ld	s0,0(sp)
    80002df8:	0141                	addi	sp,sp,16
    80002dfa:	8082                	ret

0000000080002dfc <sys_wait>:

uint64
sys_wait(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e04:	fe840593          	addi	a1,s0,-24
    80002e08:	4501                	li	a0,0
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	ed0080e7          	jalr	-304(ra) # 80002cda <argaddr>
  return wait(p);
    80002e12:	fe843503          	ld	a0,-24(s0)
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	58c080e7          	jalr	1420(ra) # 800023a2 <wait>
}
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e26:	7179                	addi	sp,sp,-48
    80002e28:	f406                	sd	ra,40(sp)
    80002e2a:	f022                	sd	s0,32(sp)
    80002e2c:	ec26                	sd	s1,24(sp)
    80002e2e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e30:	fdc40593          	addi	a1,s0,-36
    80002e34:	4501                	li	a0,0
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	e84080e7          	jalr	-380(ra) # 80002cba <argint>
  addr = myproc()->sz;
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	bca080e7          	jalr	-1078(ra) # 80001a08 <myproc>
    80002e46:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e48:	fdc42503          	lw	a0,-36(s0)
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	f2e080e7          	jalr	-210(ra) # 80001d7a <growproc>
    80002e54:	00054863          	bltz	a0,80002e64 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e58:	8526                	mv	a0,s1
    80002e5a:	70a2                	ld	ra,40(sp)
    80002e5c:	7402                	ld	s0,32(sp)
    80002e5e:	64e2                	ld	s1,24(sp)
    80002e60:	6145                	addi	sp,sp,48
    80002e62:	8082                	ret
    return -1;
    80002e64:	54fd                	li	s1,-1
    80002e66:	bfcd                	j	80002e58 <sys_sbrk+0x32>

0000000080002e68 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e68:	7139                	addi	sp,sp,-64
    80002e6a:	fc06                	sd	ra,56(sp)
    80002e6c:	f822                	sd	s0,48(sp)
    80002e6e:	f426                	sd	s1,40(sp)
    80002e70:	f04a                	sd	s2,32(sp)
    80002e72:	ec4e                	sd	s3,24(sp)
    80002e74:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e76:	fcc40593          	addi	a1,s0,-52
    80002e7a:	4501                	li	a0,0
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	e3e080e7          	jalr	-450(ra) # 80002cba <argint>
  acquire(&tickslock);
    80002e84:	00014517          	auipc	a0,0x14
    80002e88:	d3c50513          	addi	a0,a0,-708 # 80016bc0 <tickslock>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	da6080e7          	jalr	-602(ra) # 80000c32 <acquire>
  ticks0 = ticks;
    80002e94:	00006917          	auipc	s2,0x6
    80002e98:	a8c92903          	lw	s2,-1396(s2) # 80008920 <ticks>
  while(ticks - ticks0 < n){
    80002e9c:	fcc42783          	lw	a5,-52(s0)
    80002ea0:	cf9d                	beqz	a5,80002ede <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea2:	00014997          	auipc	s3,0x14
    80002ea6:	d1e98993          	addi	s3,s3,-738 # 80016bc0 <tickslock>
    80002eaa:	00006497          	auipc	s1,0x6
    80002eae:	a7648493          	addi	s1,s1,-1418 # 80008920 <ticks>
    if(killed(myproc())){
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	b56080e7          	jalr	-1194(ra) # 80001a08 <myproc>
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	4b6080e7          	jalr	1206(ra) # 80002370 <killed>
    80002ec2:	ed15                	bnez	a0,80002efe <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec4:	85ce                	mv	a1,s3
    80002ec6:	8526                	mv	a0,s1
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	200080e7          	jalr	512(ra) # 800020c8 <sleep>
  while(ticks - ticks0 < n){
    80002ed0:	409c                	lw	a5,0(s1)
    80002ed2:	412787bb          	subw	a5,a5,s2
    80002ed6:	fcc42703          	lw	a4,-52(s0)
    80002eda:	fce7ece3          	bltu	a5,a4,80002eb2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ede:	00014517          	auipc	a0,0x14
    80002ee2:	ce250513          	addi	a0,a0,-798 # 80016bc0 <tickslock>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	e00080e7          	jalr	-512(ra) # 80000ce6 <release>
  return 0;
    80002eee:	4501                	li	a0,0
}
    80002ef0:	70e2                	ld	ra,56(sp)
    80002ef2:	7442                	ld	s0,48(sp)
    80002ef4:	74a2                	ld	s1,40(sp)
    80002ef6:	7902                	ld	s2,32(sp)
    80002ef8:	69e2                	ld	s3,24(sp)
    80002efa:	6121                	addi	sp,sp,64
    80002efc:	8082                	ret
      release(&tickslock);
    80002efe:	00014517          	auipc	a0,0x14
    80002f02:	cc250513          	addi	a0,a0,-830 # 80016bc0 <tickslock>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	de0080e7          	jalr	-544(ra) # 80000ce6 <release>
      return -1;
    80002f0e:	557d                	li	a0,-1
    80002f10:	b7c5                	j	80002ef0 <sys_sleep+0x88>

0000000080002f12 <sys_kill>:

uint64
sys_kill(void)
{ 
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f1a:	fec40593          	addi	a1,s0,-20
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	d9a080e7          	jalr	-614(ra) # 80002cba <argint>
  return kill(pid);
    80002f28:	fec42503          	lw	a0,-20(s0)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	3a6080e7          	jalr	934(ra) # 800022d2 <kill>
}
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	c7a50513          	addi	a0,a0,-902 # 80016bc0 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	ce4080e7          	jalr	-796(ra) # 80000c32 <acquire>
  xticks = ticks;
    80002f56:	00006497          	auipc	s1,0x6
    80002f5a:	9ca4a483          	lw	s1,-1590(s1) # 80008920 <ticks>
  release(&tickslock);
    80002f5e:	00014517          	auipc	a0,0x14
    80002f62:	c6250513          	addi	a0,a0,-926 # 80016bc0 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	d80080e7          	jalr	-640(ra) # 80000ce6 <release>
  return xticks;
}
    80002f6e:	02049513          	slli	a0,s1,0x20
    80002f72:	9101                	srli	a0,a0,0x20
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	64a2                	ld	s1,8(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret

0000000080002f7e <sys_getHelloWorld>:

int 
sys_getHelloWorld(void)
{
    80002f7e:	1141                	addi	sp,sp,-16
    80002f80:	e406                	sd	ra,8(sp)
    80002f82:	e022                	sd	s0,0(sp)
    80002f84:	0800                	addi	s0,sp,16
  return getHelloWorld();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	6a8080e7          	jalr	1704(ra) # 8000262e <getHelloWorld>
}
    80002f8e:	2501                	sext.w	a0,a0
    80002f90:	60a2                	ld	ra,8(sp)
    80002f92:	6402                	ld	s0,0(sp)
    80002f94:	0141                	addi	sp,sp,16
    80002f96:	8082                	ret

0000000080002f98 <sys_getProcTick>:

int
sys_getProcTick(void)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    80002fa0:	fec40593          	addi	a1,s0,-20
    80002fa4:	4501                	li	a0,0
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	d14080e7          	jalr	-748(ra) # 80002cba <argint>
  return getProcTick(pid);
    80002fae:	fec42503          	lw	a0,-20(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	69e080e7          	jalr	1694(ra) # 80002650 <getProcTick>
}
    80002fba:	60e2                	ld	ra,24(sp)
    80002fbc:	6442                	ld	s0,16(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <sys_getProcInfo>:

int
sys_getProcInfo(void)
{
    80002fc2:	1141                	addi	sp,sp,-16
    80002fc4:	e406                	sd	ra,8(sp)
    80002fc6:	e022                	sd	s0,0(sp)
    80002fc8:	0800                	addi	s0,sp,16
  return getProcInfo();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	712080e7          	jalr	1810(ra) # 800026dc <getProcInfo>
}
    80002fd2:	60a2                	ld	ra,8(sp)
    80002fd4:	6402                	ld	s0,0(sp)
    80002fd6:	0141                	addi	sp,sp,16
    80002fd8:	8082                	ret

0000000080002fda <sys_sysinfo>:


uint64
sys_sysinfo(void)
{
    80002fda:	715d                	addi	sp,sp,-80
    80002fdc:	e486                	sd	ra,72(sp)
    80002fde:	e0a2                	sd	s0,64(sp)
    80002fe0:	fc26                	sd	s1,56(sp)
    80002fe2:	0880                	addi	s0,sp,80
  // get current process running on cpu
  struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	a24080e7          	jalr	-1500(ra) # 80001a08 <myproc>
    80002fec:	84aa                	mv	s1,a0
  struct sysinfo info;
  // user space pointer to struct sysinfo
  uint64 pinfo;

  // get user space pointer
  argaddr(0, &pinfo);
    80002fee:	fb840593          	addi	a1,s0,-72
    80002ff2:	4501                	li	a0,0
    80002ff4:	00000097          	auipc	ra,0x0
    80002ff8:	ce6080e7          	jalr	-794(ra) # 80002cda <argaddr>

  // get sysinfo
  info.freemem = nfreemem();
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	b4a080e7          	jalr	-1206(ra) # 80000b46 <nfreemem>
    80003004:	fca43823          	sd	a0,-48(s0)
  info.nproc = nproc();
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	72a080e7          	jalr	1834(ra) # 80002732 <nproc>
    80003010:	fca43c23          	sd	a0,-40(s0)
  info.uptime = getTicks();
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	776080e7          	jalr	1910(ra) # 8000278a <getTicks>
    8000301c:	c22517d3          	fcvt.l.d	a5,fa0,rtz
    80003020:	fcf43023          	sd	a5,-64(s0)
  info.totalram = getTotalRam();
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	b6e080e7          	jalr	-1170(ra) # 80000b92 <getTotalRam>
    8000302c:	fca43423          	sd	a0,-56(s0)

  
  
  // copy sysinfo from kernel to user
  if (copyout(p->pagetable, pinfo, (char *)&info, sizeof(struct sysinfo)) < 0)
    80003030:	02000693          	li	a3,32
    80003034:	fc040613          	addi	a2,s0,-64
    80003038:	fb843583          	ld	a1,-72(s0)
    8000303c:	68a8                	ld	a0,80(s1)
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	686080e7          	jalr	1670(ra) # 800016c4 <copyout>
    return -1;

  return 0;
}
    80003046:	957d                	srai	a0,a0,0x3f
    80003048:	60a6                	ld	ra,72(sp)
    8000304a:	6406                	ld	s0,64(sp)
    8000304c:	74e2                	ld	s1,56(sp)
    8000304e:	6161                	addi	sp,sp,80
    80003050:	8082                	ret

0000000080003052 <sys_changeSch>:

int
sys_changeSch(void)
{
    80003052:	1141                	addi	sp,sp,-16
    80003054:	e406                	sd	ra,8(sp)
    80003056:	e022                	sd	s0,0(sp)
    80003058:	0800                	addi	s0,sp,16
  return changeSch();
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	748080e7          	jalr	1864(ra) # 800027a2 <changeSch>
}
    80003062:	60a2                	ld	ra,8(sp)
    80003064:	6402                	ld	s0,0(sp)
    80003066:	0141                	addi	sp,sp,16
    80003068:	8082                	ret

000000008000306a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000306a:	7179                	addi	sp,sp,-48
    8000306c:	f406                	sd	ra,40(sp)
    8000306e:	f022                	sd	s0,32(sp)
    80003070:	ec26                	sd	s1,24(sp)
    80003072:	e84a                	sd	s2,16(sp)
    80003074:	e44e                	sd	s3,8(sp)
    80003076:	e052                	sd	s4,0(sp)
    80003078:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000307a:	00005597          	auipc	a1,0x5
    8000307e:	4de58593          	addi	a1,a1,1246 # 80008558 <syscalls+0xd8>
    80003082:	00014517          	auipc	a0,0x14
    80003086:	b5650513          	addi	a0,a0,-1194 # 80016bd8 <bcache>
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	b18080e7          	jalr	-1256(ra) # 80000ba2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003092:	0001c797          	auipc	a5,0x1c
    80003096:	b4678793          	addi	a5,a5,-1210 # 8001ebd8 <bcache+0x8000>
    8000309a:	0001c717          	auipc	a4,0x1c
    8000309e:	da670713          	addi	a4,a4,-602 # 8001ee40 <bcache+0x8268>
    800030a2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030a6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030aa:	00014497          	auipc	s1,0x14
    800030ae:	b4648493          	addi	s1,s1,-1210 # 80016bf0 <bcache+0x18>
    b->next = bcache.head.next;
    800030b2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030b4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030b6:	00005a17          	auipc	s4,0x5
    800030ba:	4aaa0a13          	addi	s4,s4,1194 # 80008560 <syscalls+0xe0>
    b->next = bcache.head.next;
    800030be:	2b893783          	ld	a5,696(s2)
    800030c2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030c4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030c8:	85d2                	mv	a1,s4
    800030ca:	01048513          	addi	a0,s1,16
    800030ce:	00001097          	auipc	ra,0x1
    800030d2:	4c4080e7          	jalr	1220(ra) # 80004592 <initsleeplock>
    bcache.head.next->prev = b;
    800030d6:	2b893783          	ld	a5,696(s2)
    800030da:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030dc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e0:	45848493          	addi	s1,s1,1112
    800030e4:	fd349de3          	bne	s1,s3,800030be <binit+0x54>
  }
}
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	69a2                	ld	s3,8(sp)
    800030f2:	6a02                	ld	s4,0(sp)
    800030f4:	6145                	addi	sp,sp,48
    800030f6:	8082                	ret

00000000800030f8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	e84a                	sd	s2,16(sp)
    80003102:	e44e                	sd	s3,8(sp)
    80003104:	1800                	addi	s0,sp,48
    80003106:	892a                	mv	s2,a0
    80003108:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	ace50513          	addi	a0,a0,-1330 # 80016bd8 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	b20080e7          	jalr	-1248(ra) # 80000c32 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000311a:	0001c497          	auipc	s1,0x1c
    8000311e:	d764b483          	ld	s1,-650(s1) # 8001ee90 <bcache+0x82b8>
    80003122:	0001c797          	auipc	a5,0x1c
    80003126:	d1e78793          	addi	a5,a5,-738 # 8001ee40 <bcache+0x8268>
    8000312a:	02f48f63          	beq	s1,a5,80003168 <bread+0x70>
    8000312e:	873e                	mv	a4,a5
    80003130:	a021                	j	80003138 <bread+0x40>
    80003132:	68a4                	ld	s1,80(s1)
    80003134:	02e48a63          	beq	s1,a4,80003168 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003138:	449c                	lw	a5,8(s1)
    8000313a:	ff279ce3          	bne	a5,s2,80003132 <bread+0x3a>
    8000313e:	44dc                	lw	a5,12(s1)
    80003140:	ff3799e3          	bne	a5,s3,80003132 <bread+0x3a>
      b->refcnt++;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	2785                	addiw	a5,a5,1
    80003148:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314a:	00014517          	auipc	a0,0x14
    8000314e:	a8e50513          	addi	a0,a0,-1394 # 80016bd8 <bcache>
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	b94080e7          	jalr	-1132(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    8000315a:	01048513          	addi	a0,s1,16
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	46e080e7          	jalr	1134(ra) # 800045cc <acquiresleep>
      return b;
    80003166:	a8b9                	j	800031c4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003168:	0001c497          	auipc	s1,0x1c
    8000316c:	d204b483          	ld	s1,-736(s1) # 8001ee88 <bcache+0x82b0>
    80003170:	0001c797          	auipc	a5,0x1c
    80003174:	cd078793          	addi	a5,a5,-816 # 8001ee40 <bcache+0x8268>
    80003178:	00f48863          	beq	s1,a5,80003188 <bread+0x90>
    8000317c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	cf81                	beqz	a5,80003198 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003182:	64a4                	ld	s1,72(s1)
    80003184:	fee49de3          	bne	s1,a4,8000317e <bread+0x86>
  panic("bget: no buffers");
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	3e050513          	addi	a0,a0,992 # 80008568 <syscalls+0xe8>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3ae080e7          	jalr	942(ra) # 8000053e <panic>
      b->dev = dev;
    80003198:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000319c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031a0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031a4:	4785                	li	a5,1
    800031a6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a8:	00014517          	auipc	a0,0x14
    800031ac:	a3050513          	addi	a0,a0,-1488 # 80016bd8 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	b36080e7          	jalr	-1226(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    800031b8:	01048513          	addi	a0,s1,16
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	410080e7          	jalr	1040(ra) # 800045cc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031c4:	409c                	lw	a5,0(s1)
    800031c6:	cb89                	beqz	a5,800031d8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031c8:	8526                	mv	a0,s1
    800031ca:	70a2                	ld	ra,40(sp)
    800031cc:	7402                	ld	s0,32(sp)
    800031ce:	64e2                	ld	s1,24(sp)
    800031d0:	6942                	ld	s2,16(sp)
    800031d2:	69a2                	ld	s3,8(sp)
    800031d4:	6145                	addi	sp,sp,48
    800031d6:	8082                	ret
    virtio_disk_rw(b, 0);
    800031d8:	4581                	li	a1,0
    800031da:	8526                	mv	a0,s1
    800031dc:	00003097          	auipc	ra,0x3
    800031e0:	fd8080e7          	jalr	-40(ra) # 800061b4 <virtio_disk_rw>
    b->valid = 1;
    800031e4:	4785                	li	a5,1
    800031e6:	c09c                	sw	a5,0(s1)
  return b;
    800031e8:	b7c5                	j	800031c8 <bread+0xd0>

00000000800031ea <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f6:	0541                	addi	a0,a0,16
    800031f8:	00001097          	auipc	ra,0x1
    800031fc:	46e080e7          	jalr	1134(ra) # 80004666 <holdingsleep>
    80003200:	cd01                	beqz	a0,80003218 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003202:	4585                	li	a1,1
    80003204:	8526                	mv	a0,s1
    80003206:	00003097          	auipc	ra,0x3
    8000320a:	fae080e7          	jalr	-82(ra) # 800061b4 <virtio_disk_rw>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6105                	addi	sp,sp,32
    80003216:	8082                	ret
    panic("bwrite");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	36850513          	addi	a0,a0,872 # 80008580 <syscalls+0x100>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	31e080e7          	jalr	798(ra) # 8000053e <panic>

0000000080003228 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	e426                	sd	s1,8(sp)
    80003230:	e04a                	sd	s2,0(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003236:	01050913          	addi	s2,a0,16
    8000323a:	854a                	mv	a0,s2
    8000323c:	00001097          	auipc	ra,0x1
    80003240:	42a080e7          	jalr	1066(ra) # 80004666 <holdingsleep>
    80003244:	c92d                	beqz	a0,800032b6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003246:	854a                	mv	a0,s2
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	3da080e7          	jalr	986(ra) # 80004622 <releasesleep>

  acquire(&bcache.lock);
    80003250:	00014517          	auipc	a0,0x14
    80003254:	98850513          	addi	a0,a0,-1656 # 80016bd8 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	9da080e7          	jalr	-1574(ra) # 80000c32 <acquire>
  b->refcnt--;
    80003260:	40bc                	lw	a5,64(s1)
    80003262:	37fd                	addiw	a5,a5,-1
    80003264:	0007871b          	sext.w	a4,a5
    80003268:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000326a:	eb05                	bnez	a4,8000329a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000326c:	68bc                	ld	a5,80(s1)
    8000326e:	64b8                	ld	a4,72(s1)
    80003270:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003272:	64bc                	ld	a5,72(s1)
    80003274:	68b8                	ld	a4,80(s1)
    80003276:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003278:	0001c797          	auipc	a5,0x1c
    8000327c:	96078793          	addi	a5,a5,-1696 # 8001ebd8 <bcache+0x8000>
    80003280:	2b87b703          	ld	a4,696(a5)
    80003284:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003286:	0001c717          	auipc	a4,0x1c
    8000328a:	bba70713          	addi	a4,a4,-1094 # 8001ee40 <bcache+0x8268>
    8000328e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003290:	2b87b703          	ld	a4,696(a5)
    80003294:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003296:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000329a:	00014517          	auipc	a0,0x14
    8000329e:	93e50513          	addi	a0,a0,-1730 # 80016bd8 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	a44080e7          	jalr	-1468(ra) # 80000ce6 <release>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6902                	ld	s2,0(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret
    panic("brelse");
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	2d250513          	addi	a0,a0,722 # 80008588 <syscalls+0x108>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	280080e7          	jalr	640(ra) # 8000053e <panic>

00000000800032c6 <bpin>:

void
bpin(struct buf *b) {
    800032c6:	1101                	addi	sp,sp,-32
    800032c8:	ec06                	sd	ra,24(sp)
    800032ca:	e822                	sd	s0,16(sp)
    800032cc:	e426                	sd	s1,8(sp)
    800032ce:	1000                	addi	s0,sp,32
    800032d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d2:	00014517          	auipc	a0,0x14
    800032d6:	90650513          	addi	a0,a0,-1786 # 80016bd8 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	958080e7          	jalr	-1704(ra) # 80000c32 <acquire>
  b->refcnt++;
    800032e2:	40bc                	lw	a5,64(s1)
    800032e4:	2785                	addiw	a5,a5,1
    800032e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e8:	00014517          	auipc	a0,0x14
    800032ec:	8f050513          	addi	a0,a0,-1808 # 80016bd8 <bcache>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	9f6080e7          	jalr	-1546(ra) # 80000ce6 <release>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	64a2                	ld	s1,8(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <bunpin>:

void
bunpin(struct buf *b) {
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	1000                	addi	s0,sp,32
    8000330c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000330e:	00014517          	auipc	a0,0x14
    80003312:	8ca50513          	addi	a0,a0,-1846 # 80016bd8 <bcache>
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	91c080e7          	jalr	-1764(ra) # 80000c32 <acquire>
  b->refcnt--;
    8000331e:	40bc                	lw	a5,64(s1)
    80003320:	37fd                	addiw	a5,a5,-1
    80003322:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003324:	00014517          	auipc	a0,0x14
    80003328:	8b450513          	addi	a0,a0,-1868 # 80016bd8 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	9ba080e7          	jalr	-1606(ra) # 80000ce6 <release>
}
    80003334:	60e2                	ld	ra,24(sp)
    80003336:	6442                	ld	s0,16(sp)
    80003338:	64a2                	ld	s1,8(sp)
    8000333a:	6105                	addi	sp,sp,32
    8000333c:	8082                	ret

000000008000333e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	e426                	sd	s1,8(sp)
    80003346:	e04a                	sd	s2,0(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000334c:	00d5d59b          	srliw	a1,a1,0xd
    80003350:	0001c797          	auipc	a5,0x1c
    80003354:	f647a783          	lw	a5,-156(a5) # 8001f2b4 <sb+0x1c>
    80003358:	9dbd                	addw	a1,a1,a5
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	d9e080e7          	jalr	-610(ra) # 800030f8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003362:	0074f713          	andi	a4,s1,7
    80003366:	4785                	li	a5,1
    80003368:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000336c:	14ce                	slli	s1,s1,0x33
    8000336e:	90d9                	srli	s1,s1,0x36
    80003370:	00950733          	add	a4,a0,s1
    80003374:	05874703          	lbu	a4,88(a4)
    80003378:	00e7f6b3          	and	a3,a5,a4
    8000337c:	c69d                	beqz	a3,800033aa <bfree+0x6c>
    8000337e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003380:	94aa                	add	s1,s1,a0
    80003382:	fff7c793          	not	a5,a5
    80003386:	8ff9                	and	a5,a5,a4
    80003388:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	120080e7          	jalr	288(ra) # 800044ac <log_write>
  brelse(bp);
    80003394:	854a                	mv	a0,s2
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	e92080e7          	jalr	-366(ra) # 80003228 <brelse>
}
    8000339e:	60e2                	ld	ra,24(sp)
    800033a0:	6442                	ld	s0,16(sp)
    800033a2:	64a2                	ld	s1,8(sp)
    800033a4:	6902                	ld	s2,0(sp)
    800033a6:	6105                	addi	sp,sp,32
    800033a8:	8082                	ret
    panic("freeing free block");
    800033aa:	00005517          	auipc	a0,0x5
    800033ae:	1e650513          	addi	a0,a0,486 # 80008590 <syscalls+0x110>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	18c080e7          	jalr	396(ra) # 8000053e <panic>

00000000800033ba <balloc>:
{
    800033ba:	711d                	addi	sp,sp,-96
    800033bc:	ec86                	sd	ra,88(sp)
    800033be:	e8a2                	sd	s0,80(sp)
    800033c0:	e4a6                	sd	s1,72(sp)
    800033c2:	e0ca                	sd	s2,64(sp)
    800033c4:	fc4e                	sd	s3,56(sp)
    800033c6:	f852                	sd	s4,48(sp)
    800033c8:	f456                	sd	s5,40(sp)
    800033ca:	f05a                	sd	s6,32(sp)
    800033cc:	ec5e                	sd	s7,24(sp)
    800033ce:	e862                	sd	s8,16(sp)
    800033d0:	e466                	sd	s9,8(sp)
    800033d2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	0001c797          	auipc	a5,0x1c
    800033d8:	ec87a783          	lw	a5,-312(a5) # 8001f29c <sb+0x4>
    800033dc:	10078163          	beqz	a5,800034de <balloc+0x124>
    800033e0:	8baa                	mv	s7,a0
    800033e2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033e4:	0001cb17          	auipc	s6,0x1c
    800033e8:	eb4b0b13          	addi	s6,s6,-332 # 8001f298 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ec:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ee:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033f2:	6c89                	lui	s9,0x2
    800033f4:	a061                	j	8000347c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033f6:	974a                	add	a4,a4,s2
    800033f8:	8fd5                	or	a5,a5,a3
    800033fa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033fe:	854a                	mv	a0,s2
    80003400:	00001097          	auipc	ra,0x1
    80003404:	0ac080e7          	jalr	172(ra) # 800044ac <log_write>
        brelse(bp);
    80003408:	854a                	mv	a0,s2
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	e1e080e7          	jalr	-482(ra) # 80003228 <brelse>
  bp = bread(dev, bno);
    80003412:	85a6                	mv	a1,s1
    80003414:	855e                	mv	a0,s7
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	ce2080e7          	jalr	-798(ra) # 800030f8 <bread>
    8000341e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003420:	40000613          	li	a2,1024
    80003424:	4581                	li	a1,0
    80003426:	05850513          	addi	a0,a0,88
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	904080e7          	jalr	-1788(ra) # 80000d2e <memset>
  log_write(bp);
    80003432:	854a                	mv	a0,s2
    80003434:	00001097          	auipc	ra,0x1
    80003438:	078080e7          	jalr	120(ra) # 800044ac <log_write>
  brelse(bp);
    8000343c:	854a                	mv	a0,s2
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	dea080e7          	jalr	-534(ra) # 80003228 <brelse>
}
    80003446:	8526                	mv	a0,s1
    80003448:	60e6                	ld	ra,88(sp)
    8000344a:	6446                	ld	s0,80(sp)
    8000344c:	64a6                	ld	s1,72(sp)
    8000344e:	6906                	ld	s2,64(sp)
    80003450:	79e2                	ld	s3,56(sp)
    80003452:	7a42                	ld	s4,48(sp)
    80003454:	7aa2                	ld	s5,40(sp)
    80003456:	7b02                	ld	s6,32(sp)
    80003458:	6be2                	ld	s7,24(sp)
    8000345a:	6c42                	ld	s8,16(sp)
    8000345c:	6ca2                	ld	s9,8(sp)
    8000345e:	6125                	addi	sp,sp,96
    80003460:	8082                	ret
    brelse(bp);
    80003462:	854a                	mv	a0,s2
    80003464:	00000097          	auipc	ra,0x0
    80003468:	dc4080e7          	jalr	-572(ra) # 80003228 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000346c:	015c87bb          	addw	a5,s9,s5
    80003470:	00078a9b          	sext.w	s5,a5
    80003474:	004b2703          	lw	a4,4(s6)
    80003478:	06eaf363          	bgeu	s5,a4,800034de <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000347c:	41fad79b          	sraiw	a5,s5,0x1f
    80003480:	0137d79b          	srliw	a5,a5,0x13
    80003484:	015787bb          	addw	a5,a5,s5
    80003488:	40d7d79b          	sraiw	a5,a5,0xd
    8000348c:	01cb2583          	lw	a1,28(s6)
    80003490:	9dbd                	addw	a1,a1,a5
    80003492:	855e                	mv	a0,s7
    80003494:	00000097          	auipc	ra,0x0
    80003498:	c64080e7          	jalr	-924(ra) # 800030f8 <bread>
    8000349c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349e:	004b2503          	lw	a0,4(s6)
    800034a2:	000a849b          	sext.w	s1,s5
    800034a6:	8662                	mv	a2,s8
    800034a8:	faa4fde3          	bgeu	s1,a0,80003462 <balloc+0xa8>
      m = 1 << (bi % 8);
    800034ac:	41f6579b          	sraiw	a5,a2,0x1f
    800034b0:	01d7d69b          	srliw	a3,a5,0x1d
    800034b4:	00c6873b          	addw	a4,a3,a2
    800034b8:	00777793          	andi	a5,a4,7
    800034bc:	9f95                	subw	a5,a5,a3
    800034be:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c2:	4037571b          	sraiw	a4,a4,0x3
    800034c6:	00e906b3          	add	a3,s2,a4
    800034ca:	0586c683          	lbu	a3,88(a3)
    800034ce:	00d7f5b3          	and	a1,a5,a3
    800034d2:	d195                	beqz	a1,800033f6 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d4:	2605                	addiw	a2,a2,1
    800034d6:	2485                	addiw	s1,s1,1
    800034d8:	fd4618e3          	bne	a2,s4,800034a8 <balloc+0xee>
    800034dc:	b759                	j	80003462 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	0ca50513          	addi	a0,a0,202 # 800085a8 <syscalls+0x128>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	0a2080e7          	jalr	162(ra) # 80000588 <printf>
  return 0;
    800034ee:	4481                	li	s1,0
    800034f0:	bf99                	j	80003446 <balloc+0x8c>

00000000800034f2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034f2:	7179                	addi	sp,sp,-48
    800034f4:	f406                	sd	ra,40(sp)
    800034f6:	f022                	sd	s0,32(sp)
    800034f8:	ec26                	sd	s1,24(sp)
    800034fa:	e84a                	sd	s2,16(sp)
    800034fc:	e44e                	sd	s3,8(sp)
    800034fe:	e052                	sd	s4,0(sp)
    80003500:	1800                	addi	s0,sp,48
    80003502:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003504:	47ad                	li	a5,11
    80003506:	02b7e763          	bltu	a5,a1,80003534 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000350a:	02059493          	slli	s1,a1,0x20
    8000350e:	9081                	srli	s1,s1,0x20
    80003510:	048a                	slli	s1,s1,0x2
    80003512:	94aa                	add	s1,s1,a0
    80003514:	0504a903          	lw	s2,80(s1)
    80003518:	06091e63          	bnez	s2,80003594 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000351c:	4108                	lw	a0,0(a0)
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	e9c080e7          	jalr	-356(ra) # 800033ba <balloc>
    80003526:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000352a:	06090563          	beqz	s2,80003594 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000352e:	0524a823          	sw	s2,80(s1)
    80003532:	a08d                	j	80003594 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003534:	ff45849b          	addiw	s1,a1,-12
    80003538:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000353c:	0ff00793          	li	a5,255
    80003540:	08e7e563          	bltu	a5,a4,800035ca <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003544:	08052903          	lw	s2,128(a0)
    80003548:	00091d63          	bnez	s2,80003562 <bmap+0x70>
      addr = balloc(ip->dev);
    8000354c:	4108                	lw	a0,0(a0)
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	e6c080e7          	jalr	-404(ra) # 800033ba <balloc>
    80003556:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000355a:	02090d63          	beqz	s2,80003594 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000355e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003562:	85ca                	mv	a1,s2
    80003564:	0009a503          	lw	a0,0(s3)
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	b90080e7          	jalr	-1136(ra) # 800030f8 <bread>
    80003570:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003572:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003576:	02049593          	slli	a1,s1,0x20
    8000357a:	9181                	srli	a1,a1,0x20
    8000357c:	058a                	slli	a1,a1,0x2
    8000357e:	00b784b3          	add	s1,a5,a1
    80003582:	0004a903          	lw	s2,0(s1)
    80003586:	02090063          	beqz	s2,800035a6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000358a:	8552                	mv	a0,s4
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	c9c080e7          	jalr	-868(ra) # 80003228 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003594:	854a                	mv	a0,s2
    80003596:	70a2                	ld	ra,40(sp)
    80003598:	7402                	ld	s0,32(sp)
    8000359a:	64e2                	ld	s1,24(sp)
    8000359c:	6942                	ld	s2,16(sp)
    8000359e:	69a2                	ld	s3,8(sp)
    800035a0:	6a02                	ld	s4,0(sp)
    800035a2:	6145                	addi	sp,sp,48
    800035a4:	8082                	ret
      addr = balloc(ip->dev);
    800035a6:	0009a503          	lw	a0,0(s3)
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	e10080e7          	jalr	-496(ra) # 800033ba <balloc>
    800035b2:	0005091b          	sext.w	s2,a0
      if(addr){
    800035b6:	fc090ae3          	beqz	s2,8000358a <bmap+0x98>
        a[bn] = addr;
    800035ba:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035be:	8552                	mv	a0,s4
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	eec080e7          	jalr	-276(ra) # 800044ac <log_write>
    800035c8:	b7c9                	j	8000358a <bmap+0x98>
  panic("bmap: out of range");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	ff650513          	addi	a0,a0,-10 # 800085c0 <syscalls+0x140>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>

00000000800035da <iget>:
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	e052                	sd	s4,0(sp)
    800035e8:	1800                	addi	s0,sp,48
    800035ea:	89aa                	mv	s3,a0
    800035ec:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035ee:	0001c517          	auipc	a0,0x1c
    800035f2:	cca50513          	addi	a0,a0,-822 # 8001f2b8 <itable>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	63c080e7          	jalr	1596(ra) # 80000c32 <acquire>
  empty = 0;
    800035fe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003600:	0001c497          	auipc	s1,0x1c
    80003604:	cd048493          	addi	s1,s1,-816 # 8001f2d0 <itable+0x18>
    80003608:	0001d697          	auipc	a3,0x1d
    8000360c:	75868693          	addi	a3,a3,1880 # 80020d60 <log>
    80003610:	a039                	j	8000361e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003612:	02090b63          	beqz	s2,80003648 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003616:	08848493          	addi	s1,s1,136
    8000361a:	02d48a63          	beq	s1,a3,8000364e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000361e:	449c                	lw	a5,8(s1)
    80003620:	fef059e3          	blez	a5,80003612 <iget+0x38>
    80003624:	4098                	lw	a4,0(s1)
    80003626:	ff3716e3          	bne	a4,s3,80003612 <iget+0x38>
    8000362a:	40d8                	lw	a4,4(s1)
    8000362c:	ff4713e3          	bne	a4,s4,80003612 <iget+0x38>
      ip->ref++;
    80003630:	2785                	addiw	a5,a5,1
    80003632:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003634:	0001c517          	auipc	a0,0x1c
    80003638:	c8450513          	addi	a0,a0,-892 # 8001f2b8 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	6aa080e7          	jalr	1706(ra) # 80000ce6 <release>
      return ip;
    80003644:	8926                	mv	s2,s1
    80003646:	a03d                	j	80003674 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003648:	f7f9                	bnez	a5,80003616 <iget+0x3c>
    8000364a:	8926                	mv	s2,s1
    8000364c:	b7e9                	j	80003616 <iget+0x3c>
  if(empty == 0)
    8000364e:	02090c63          	beqz	s2,80003686 <iget+0xac>
  ip->dev = dev;
    80003652:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003656:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000365a:	4785                	li	a5,1
    8000365c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003660:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003664:	0001c517          	auipc	a0,0x1c
    80003668:	c5450513          	addi	a0,a0,-940 # 8001f2b8 <itable>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	67a080e7          	jalr	1658(ra) # 80000ce6 <release>
}
    80003674:	854a                	mv	a0,s2
    80003676:	70a2                	ld	ra,40(sp)
    80003678:	7402                	ld	s0,32(sp)
    8000367a:	64e2                	ld	s1,24(sp)
    8000367c:	6942                	ld	s2,16(sp)
    8000367e:	69a2                	ld	s3,8(sp)
    80003680:	6a02                	ld	s4,0(sp)
    80003682:	6145                	addi	sp,sp,48
    80003684:	8082                	ret
    panic("iget: no inodes");
    80003686:	00005517          	auipc	a0,0x5
    8000368a:	f5250513          	addi	a0,a0,-174 # 800085d8 <syscalls+0x158>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>

0000000080003696 <fsinit>:
fsinit(int dev) {
    80003696:	7179                	addi	sp,sp,-48
    80003698:	f406                	sd	ra,40(sp)
    8000369a:	f022                	sd	s0,32(sp)
    8000369c:	ec26                	sd	s1,24(sp)
    8000369e:	e84a                	sd	s2,16(sp)
    800036a0:	e44e                	sd	s3,8(sp)
    800036a2:	1800                	addi	s0,sp,48
    800036a4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036a6:	4585                	li	a1,1
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	a50080e7          	jalr	-1456(ra) # 800030f8 <bread>
    800036b0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036b2:	0001c997          	auipc	s3,0x1c
    800036b6:	be698993          	addi	s3,s3,-1050 # 8001f298 <sb>
    800036ba:	02000613          	li	a2,32
    800036be:	05850593          	addi	a1,a0,88
    800036c2:	854e                	mv	a0,s3
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	6c6080e7          	jalr	1734(ra) # 80000d8a <memmove>
  brelse(bp);
    800036cc:	8526                	mv	a0,s1
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	b5a080e7          	jalr	-1190(ra) # 80003228 <brelse>
  if(sb.magic != FSMAGIC)
    800036d6:	0009a703          	lw	a4,0(s3)
    800036da:	102037b7          	lui	a5,0x10203
    800036de:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036e2:	02f71263          	bne	a4,a5,80003706 <fsinit+0x70>
  initlog(dev, &sb);
    800036e6:	0001c597          	auipc	a1,0x1c
    800036ea:	bb258593          	addi	a1,a1,-1102 # 8001f298 <sb>
    800036ee:	854a                	mv	a0,s2
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	b40080e7          	jalr	-1216(ra) # 80004230 <initlog>
}
    800036f8:	70a2                	ld	ra,40(sp)
    800036fa:	7402                	ld	s0,32(sp)
    800036fc:	64e2                	ld	s1,24(sp)
    800036fe:	6942                	ld	s2,16(sp)
    80003700:	69a2                	ld	s3,8(sp)
    80003702:	6145                	addi	sp,sp,48
    80003704:	8082                	ret
    panic("invalid file system");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	ee250513          	addi	a0,a0,-286 # 800085e8 <syscalls+0x168>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>

0000000080003716 <iinit>:
{
    80003716:	7179                	addi	sp,sp,-48
    80003718:	f406                	sd	ra,40(sp)
    8000371a:	f022                	sd	s0,32(sp)
    8000371c:	ec26                	sd	s1,24(sp)
    8000371e:	e84a                	sd	s2,16(sp)
    80003720:	e44e                	sd	s3,8(sp)
    80003722:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003724:	00005597          	auipc	a1,0x5
    80003728:	edc58593          	addi	a1,a1,-292 # 80008600 <syscalls+0x180>
    8000372c:	0001c517          	auipc	a0,0x1c
    80003730:	b8c50513          	addi	a0,a0,-1140 # 8001f2b8 <itable>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	46e080e7          	jalr	1134(ra) # 80000ba2 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000373c:	0001c497          	auipc	s1,0x1c
    80003740:	ba448493          	addi	s1,s1,-1116 # 8001f2e0 <itable+0x28>
    80003744:	0001d997          	auipc	s3,0x1d
    80003748:	62c98993          	addi	s3,s3,1580 # 80020d70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000374c:	00005917          	auipc	s2,0x5
    80003750:	ebc90913          	addi	s2,s2,-324 # 80008608 <syscalls+0x188>
    80003754:	85ca                	mv	a1,s2
    80003756:	8526                	mv	a0,s1
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	e3a080e7          	jalr	-454(ra) # 80004592 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003760:	08848493          	addi	s1,s1,136
    80003764:	ff3498e3          	bne	s1,s3,80003754 <iinit+0x3e>
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6942                	ld	s2,16(sp)
    80003770:	69a2                	ld	s3,8(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret

0000000080003776 <ialloc>:
{
    80003776:	715d                	addi	sp,sp,-80
    80003778:	e486                	sd	ra,72(sp)
    8000377a:	e0a2                	sd	s0,64(sp)
    8000377c:	fc26                	sd	s1,56(sp)
    8000377e:	f84a                	sd	s2,48(sp)
    80003780:	f44e                	sd	s3,40(sp)
    80003782:	f052                	sd	s4,32(sp)
    80003784:	ec56                	sd	s5,24(sp)
    80003786:	e85a                	sd	s6,16(sp)
    80003788:	e45e                	sd	s7,8(sp)
    8000378a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000378c:	0001c717          	auipc	a4,0x1c
    80003790:	b1872703          	lw	a4,-1256(a4) # 8001f2a4 <sb+0xc>
    80003794:	4785                	li	a5,1
    80003796:	04e7fa63          	bgeu	a5,a4,800037ea <ialloc+0x74>
    8000379a:	8aaa                	mv	s5,a0
    8000379c:	8bae                	mv	s7,a1
    8000379e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037a0:	0001ca17          	auipc	s4,0x1c
    800037a4:	af8a0a13          	addi	s4,s4,-1288 # 8001f298 <sb>
    800037a8:	00048b1b          	sext.w	s6,s1
    800037ac:	0044d793          	srli	a5,s1,0x4
    800037b0:	018a2583          	lw	a1,24(s4)
    800037b4:	9dbd                	addw	a1,a1,a5
    800037b6:	8556                	mv	a0,s5
    800037b8:	00000097          	auipc	ra,0x0
    800037bc:	940080e7          	jalr	-1728(ra) # 800030f8 <bread>
    800037c0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037c2:	05850993          	addi	s3,a0,88
    800037c6:	00f4f793          	andi	a5,s1,15
    800037ca:	079a                	slli	a5,a5,0x6
    800037cc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ce:	00099783          	lh	a5,0(s3)
    800037d2:	c3a1                	beqz	a5,80003812 <ialloc+0x9c>
    brelse(bp);
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	a54080e7          	jalr	-1452(ra) # 80003228 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037dc:	0485                	addi	s1,s1,1
    800037de:	00ca2703          	lw	a4,12(s4)
    800037e2:	0004879b          	sext.w	a5,s1
    800037e6:	fce7e1e3          	bltu	a5,a4,800037a8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	e2650513          	addi	a0,a0,-474 # 80008610 <syscalls+0x190>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d96080e7          	jalr	-618(ra) # 80000588 <printf>
  return 0;
    800037fa:	4501                	li	a0,0
}
    800037fc:	60a6                	ld	ra,72(sp)
    800037fe:	6406                	ld	s0,64(sp)
    80003800:	74e2                	ld	s1,56(sp)
    80003802:	7942                	ld	s2,48(sp)
    80003804:	79a2                	ld	s3,40(sp)
    80003806:	7a02                	ld	s4,32(sp)
    80003808:	6ae2                	ld	s5,24(sp)
    8000380a:	6b42                	ld	s6,16(sp)
    8000380c:	6ba2                	ld	s7,8(sp)
    8000380e:	6161                	addi	sp,sp,80
    80003810:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003812:	04000613          	li	a2,64
    80003816:	4581                	li	a1,0
    80003818:	854e                	mv	a0,s3
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	514080e7          	jalr	1300(ra) # 80000d2e <memset>
      dip->type = type;
    80003822:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	c84080e7          	jalr	-892(ra) # 800044ac <log_write>
      brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	9f6080e7          	jalr	-1546(ra) # 80003228 <brelse>
      return iget(dev, inum);
    8000383a:	85da                	mv	a1,s6
    8000383c:	8556                	mv	a0,s5
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	d9c080e7          	jalr	-612(ra) # 800035da <iget>
    80003846:	bf5d                	j	800037fc <ialloc+0x86>

0000000080003848 <iupdate>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	e04a                	sd	s2,0(sp)
    80003852:	1000                	addi	s0,sp,32
    80003854:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003856:	415c                	lw	a5,4(a0)
    80003858:	0047d79b          	srliw	a5,a5,0x4
    8000385c:	0001c597          	auipc	a1,0x1c
    80003860:	a545a583          	lw	a1,-1452(a1) # 8001f2b0 <sb+0x18>
    80003864:	9dbd                	addw	a1,a1,a5
    80003866:	4108                	lw	a0,0(a0)
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	890080e7          	jalr	-1904(ra) # 800030f8 <bread>
    80003870:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003872:	05850793          	addi	a5,a0,88
    80003876:	40c8                	lw	a0,4(s1)
    80003878:	893d                	andi	a0,a0,15
    8000387a:	051a                	slli	a0,a0,0x6
    8000387c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000387e:	04449703          	lh	a4,68(s1)
    80003882:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003886:	04649703          	lh	a4,70(s1)
    8000388a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000388e:	04849703          	lh	a4,72(s1)
    80003892:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003896:	04a49703          	lh	a4,74(s1)
    8000389a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000389e:	44f8                	lw	a4,76(s1)
    800038a0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038a2:	03400613          	li	a2,52
    800038a6:	05048593          	addi	a1,s1,80
    800038aa:	0531                	addi	a0,a0,12
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	4de080e7          	jalr	1246(ra) # 80000d8a <memmove>
  log_write(bp);
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	bf6080e7          	jalr	-1034(ra) # 800044ac <log_write>
  brelse(bp);
    800038be:	854a                	mv	a0,s2
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	968080e7          	jalr	-1688(ra) # 80003228 <brelse>
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6902                	ld	s2,0(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <idup>:
{
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	e426                	sd	s1,8(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038e0:	0001c517          	auipc	a0,0x1c
    800038e4:	9d850513          	addi	a0,a0,-1576 # 8001f2b8 <itable>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	34a080e7          	jalr	842(ra) # 80000c32 <acquire>
  ip->ref++;
    800038f0:	449c                	lw	a5,8(s1)
    800038f2:	2785                	addiw	a5,a5,1
    800038f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	9c250513          	addi	a0,a0,-1598 # 8001f2b8 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	3e8080e7          	jalr	1000(ra) # 80000ce6 <release>
}
    80003906:	8526                	mv	a0,s1
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret

0000000080003912 <ilock>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000391e:	c115                	beqz	a0,80003942 <ilock+0x30>
    80003920:	84aa                	mv	s1,a0
    80003922:	451c                	lw	a5,8(a0)
    80003924:	00f05f63          	blez	a5,80003942 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003928:	0541                	addi	a0,a0,16
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	ca2080e7          	jalr	-862(ra) # 800045cc <acquiresleep>
  if(ip->valid == 0){
    80003932:	40bc                	lw	a5,64(s1)
    80003934:	cf99                	beqz	a5,80003952 <ilock+0x40>
}
    80003936:	60e2                	ld	ra,24(sp)
    80003938:	6442                	ld	s0,16(sp)
    8000393a:	64a2                	ld	s1,8(sp)
    8000393c:	6902                	ld	s2,0(sp)
    8000393e:	6105                	addi	sp,sp,32
    80003940:	8082                	ret
    panic("ilock");
    80003942:	00005517          	auipc	a0,0x5
    80003946:	ce650513          	addi	a0,a0,-794 # 80008628 <syscalls+0x1a8>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	bf4080e7          	jalr	-1036(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003952:	40dc                	lw	a5,4(s1)
    80003954:	0047d79b          	srliw	a5,a5,0x4
    80003958:	0001c597          	auipc	a1,0x1c
    8000395c:	9585a583          	lw	a1,-1704(a1) # 8001f2b0 <sb+0x18>
    80003960:	9dbd                	addw	a1,a1,a5
    80003962:	4088                	lw	a0,0(s1)
    80003964:	fffff097          	auipc	ra,0xfffff
    80003968:	794080e7          	jalr	1940(ra) # 800030f8 <bread>
    8000396c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000396e:	05850593          	addi	a1,a0,88
    80003972:	40dc                	lw	a5,4(s1)
    80003974:	8bbd                	andi	a5,a5,15
    80003976:	079a                	slli	a5,a5,0x6
    80003978:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000397a:	00059783          	lh	a5,0(a1)
    8000397e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003982:	00259783          	lh	a5,2(a1)
    80003986:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000398a:	00459783          	lh	a5,4(a1)
    8000398e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003992:	00659783          	lh	a5,6(a1)
    80003996:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000399a:	459c                	lw	a5,8(a1)
    8000399c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000399e:	03400613          	li	a2,52
    800039a2:	05b1                	addi	a1,a1,12
    800039a4:	05048513          	addi	a0,s1,80
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	3e2080e7          	jalr	994(ra) # 80000d8a <memmove>
    brelse(bp);
    800039b0:	854a                	mv	a0,s2
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	876080e7          	jalr	-1930(ra) # 80003228 <brelse>
    ip->valid = 1;
    800039ba:	4785                	li	a5,1
    800039bc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039be:	04449783          	lh	a5,68(s1)
    800039c2:	fbb5                	bnez	a5,80003936 <ilock+0x24>
      panic("ilock: no type");
    800039c4:	00005517          	auipc	a0,0x5
    800039c8:	c6c50513          	addi	a0,a0,-916 # 80008630 <syscalls+0x1b0>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	b72080e7          	jalr	-1166(ra) # 8000053e <panic>

00000000800039d4 <iunlock>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	e04a                	sd	s2,0(sp)
    800039de:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039e0:	c905                	beqz	a0,80003a10 <iunlock+0x3c>
    800039e2:	84aa                	mv	s1,a0
    800039e4:	01050913          	addi	s2,a0,16
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	c7c080e7          	jalr	-900(ra) # 80004666 <holdingsleep>
    800039f2:	cd19                	beqz	a0,80003a10 <iunlock+0x3c>
    800039f4:	449c                	lw	a5,8(s1)
    800039f6:	00f05d63          	blez	a5,80003a10 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	c26080e7          	jalr	-986(ra) # 80004622 <releasesleep>
}
    80003a04:	60e2                	ld	ra,24(sp)
    80003a06:	6442                	ld	s0,16(sp)
    80003a08:	64a2                	ld	s1,8(sp)
    80003a0a:	6902                	ld	s2,0(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret
    panic("iunlock");
    80003a10:	00005517          	auipc	a0,0x5
    80003a14:	c3050513          	addi	a0,a0,-976 # 80008640 <syscalls+0x1c0>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080003a20 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a20:	7179                	addi	sp,sp,-48
    80003a22:	f406                	sd	ra,40(sp)
    80003a24:	f022                	sd	s0,32(sp)
    80003a26:	ec26                	sd	s1,24(sp)
    80003a28:	e84a                	sd	s2,16(sp)
    80003a2a:	e44e                	sd	s3,8(sp)
    80003a2c:	e052                	sd	s4,0(sp)
    80003a2e:	1800                	addi	s0,sp,48
    80003a30:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a32:	05050493          	addi	s1,a0,80
    80003a36:	08050913          	addi	s2,a0,128
    80003a3a:	a021                	j	80003a42 <itrunc+0x22>
    80003a3c:	0491                	addi	s1,s1,4
    80003a3e:	01248d63          	beq	s1,s2,80003a58 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a42:	408c                	lw	a1,0(s1)
    80003a44:	dde5                	beqz	a1,80003a3c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a46:	0009a503          	lw	a0,0(s3)
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	8f4080e7          	jalr	-1804(ra) # 8000333e <bfree>
      ip->addrs[i] = 0;
    80003a52:	0004a023          	sw	zero,0(s1)
    80003a56:	b7dd                	j	80003a3c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a58:	0809a583          	lw	a1,128(s3)
    80003a5c:	e185                	bnez	a1,80003a7c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a5e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a62:	854e                	mv	a0,s3
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	de4080e7          	jalr	-540(ra) # 80003848 <iupdate>
}
    80003a6c:	70a2                	ld	ra,40(sp)
    80003a6e:	7402                	ld	s0,32(sp)
    80003a70:	64e2                	ld	s1,24(sp)
    80003a72:	6942                	ld	s2,16(sp)
    80003a74:	69a2                	ld	s3,8(sp)
    80003a76:	6a02                	ld	s4,0(sp)
    80003a78:	6145                	addi	sp,sp,48
    80003a7a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a7c:	0009a503          	lw	a0,0(s3)
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	678080e7          	jalr	1656(ra) # 800030f8 <bread>
    80003a88:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a8a:	05850493          	addi	s1,a0,88
    80003a8e:	45850913          	addi	s2,a0,1112
    80003a92:	a021                	j	80003a9a <itrunc+0x7a>
    80003a94:	0491                	addi	s1,s1,4
    80003a96:	01248b63          	beq	s1,s2,80003aac <itrunc+0x8c>
      if(a[j])
    80003a9a:	408c                	lw	a1,0(s1)
    80003a9c:	dde5                	beqz	a1,80003a94 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a9e:	0009a503          	lw	a0,0(s3)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	89c080e7          	jalr	-1892(ra) # 8000333e <bfree>
    80003aaa:	b7ed                	j	80003a94 <itrunc+0x74>
    brelse(bp);
    80003aac:	8552                	mv	a0,s4
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	77a080e7          	jalr	1914(ra) # 80003228 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ab6:	0809a583          	lw	a1,128(s3)
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	880080e7          	jalr	-1920(ra) # 8000333e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ac6:	0809a023          	sw	zero,128(s3)
    80003aca:	bf51                	j	80003a5e <itrunc+0x3e>

0000000080003acc <iput>:
{
    80003acc:	1101                	addi	sp,sp,-32
    80003ace:	ec06                	sd	ra,24(sp)
    80003ad0:	e822                	sd	s0,16(sp)
    80003ad2:	e426                	sd	s1,8(sp)
    80003ad4:	e04a                	sd	s2,0(sp)
    80003ad6:	1000                	addi	s0,sp,32
    80003ad8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ada:	0001b517          	auipc	a0,0x1b
    80003ade:	7de50513          	addi	a0,a0,2014 # 8001f2b8 <itable>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	150080e7          	jalr	336(ra) # 80000c32 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aea:	4498                	lw	a4,8(s1)
    80003aec:	4785                	li	a5,1
    80003aee:	02f70363          	beq	a4,a5,80003b14 <iput+0x48>
  ip->ref--;
    80003af2:	449c                	lw	a5,8(s1)
    80003af4:	37fd                	addiw	a5,a5,-1
    80003af6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003af8:	0001b517          	auipc	a0,0x1b
    80003afc:	7c050513          	addi	a0,a0,1984 # 8001f2b8 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	1e6080e7          	jalr	486(ra) # 80000ce6 <release>
}
    80003b08:	60e2                	ld	ra,24(sp)
    80003b0a:	6442                	ld	s0,16(sp)
    80003b0c:	64a2                	ld	s1,8(sp)
    80003b0e:	6902                	ld	s2,0(sp)
    80003b10:	6105                	addi	sp,sp,32
    80003b12:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b14:	40bc                	lw	a5,64(s1)
    80003b16:	dff1                	beqz	a5,80003af2 <iput+0x26>
    80003b18:	04a49783          	lh	a5,74(s1)
    80003b1c:	fbf9                	bnez	a5,80003af2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b1e:	01048913          	addi	s2,s1,16
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	aa8080e7          	jalr	-1368(ra) # 800045cc <acquiresleep>
    release(&itable.lock);
    80003b2c:	0001b517          	auipc	a0,0x1b
    80003b30:	78c50513          	addi	a0,a0,1932 # 8001f2b8 <itable>
    80003b34:	ffffd097          	auipc	ra,0xffffd
    80003b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <release>
    itrunc(ip);
    80003b3c:	8526                	mv	a0,s1
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	ee2080e7          	jalr	-286(ra) # 80003a20 <itrunc>
    ip->type = 0;
    80003b46:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b4a:	8526                	mv	a0,s1
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	cfc080e7          	jalr	-772(ra) # 80003848 <iupdate>
    ip->valid = 0;
    80003b54:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00001097          	auipc	ra,0x1
    80003b5e:	ac8080e7          	jalr	-1336(ra) # 80004622 <releasesleep>
    acquire(&itable.lock);
    80003b62:	0001b517          	auipc	a0,0x1b
    80003b66:	75650513          	addi	a0,a0,1878 # 8001f2b8 <itable>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	0c8080e7          	jalr	200(ra) # 80000c32 <acquire>
    80003b72:	b741                	j	80003af2 <iput+0x26>

0000000080003b74 <iunlockput>:
{
    80003b74:	1101                	addi	sp,sp,-32
    80003b76:	ec06                	sd	ra,24(sp)
    80003b78:	e822                	sd	s0,16(sp)
    80003b7a:	e426                	sd	s1,8(sp)
    80003b7c:	1000                	addi	s0,sp,32
    80003b7e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	e54080e7          	jalr	-428(ra) # 800039d4 <iunlock>
  iput(ip);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	f42080e7          	jalr	-190(ra) # 80003acc <iput>
}
    80003b92:	60e2                	ld	ra,24(sp)
    80003b94:	6442                	ld	s0,16(sp)
    80003b96:	64a2                	ld	s1,8(sp)
    80003b98:	6105                	addi	sp,sp,32
    80003b9a:	8082                	ret

0000000080003b9c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b9c:	1141                	addi	sp,sp,-16
    80003b9e:	e422                	sd	s0,8(sp)
    80003ba0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ba2:	411c                	lw	a5,0(a0)
    80003ba4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ba6:	415c                	lw	a5,4(a0)
    80003ba8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003baa:	04451783          	lh	a5,68(a0)
    80003bae:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bb2:	04a51783          	lh	a5,74(a0)
    80003bb6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bba:	04c56783          	lwu	a5,76(a0)
    80003bbe:	e99c                	sd	a5,16(a1)
}
    80003bc0:	6422                	ld	s0,8(sp)
    80003bc2:	0141                	addi	sp,sp,16
    80003bc4:	8082                	ret

0000000080003bc6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bc6:	457c                	lw	a5,76(a0)
    80003bc8:	0ed7e963          	bltu	a5,a3,80003cba <readi+0xf4>
{
    80003bcc:	7159                	addi	sp,sp,-112
    80003bce:	f486                	sd	ra,104(sp)
    80003bd0:	f0a2                	sd	s0,96(sp)
    80003bd2:	eca6                	sd	s1,88(sp)
    80003bd4:	e8ca                	sd	s2,80(sp)
    80003bd6:	e4ce                	sd	s3,72(sp)
    80003bd8:	e0d2                	sd	s4,64(sp)
    80003bda:	fc56                	sd	s5,56(sp)
    80003bdc:	f85a                	sd	s6,48(sp)
    80003bde:	f45e                	sd	s7,40(sp)
    80003be0:	f062                	sd	s8,32(sp)
    80003be2:	ec66                	sd	s9,24(sp)
    80003be4:	e86a                	sd	s10,16(sp)
    80003be6:	e46e                	sd	s11,8(sp)
    80003be8:	1880                	addi	s0,sp,112
    80003bea:	8b2a                	mv	s6,a0
    80003bec:	8bae                	mv	s7,a1
    80003bee:	8a32                	mv	s4,a2
    80003bf0:	84b6                	mv	s1,a3
    80003bf2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bf4:	9f35                	addw	a4,a4,a3
    return 0;
    80003bf6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bf8:	0ad76063          	bltu	a4,a3,80003c98 <readi+0xd2>
  if(off + n > ip->size)
    80003bfc:	00e7f463          	bgeu	a5,a4,80003c04 <readi+0x3e>
    n = ip->size - off;
    80003c00:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c04:	0a0a8963          	beqz	s5,80003cb6 <readi+0xf0>
    80003c08:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c0e:	5c7d                	li	s8,-1
    80003c10:	a82d                	j	80003c4a <readi+0x84>
    80003c12:	020d1d93          	slli	s11,s10,0x20
    80003c16:	020ddd93          	srli	s11,s11,0x20
    80003c1a:	05890793          	addi	a5,s2,88
    80003c1e:	86ee                	mv	a3,s11
    80003c20:	963e                	add	a2,a2,a5
    80003c22:	85d2                	mv	a1,s4
    80003c24:	855e                	mv	a0,s7
    80003c26:	fffff097          	auipc	ra,0xfffff
    80003c2a:	8ae080e7          	jalr	-1874(ra) # 800024d4 <either_copyout>
    80003c2e:	05850d63          	beq	a0,s8,80003c88 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c32:	854a                	mv	a0,s2
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	5f4080e7          	jalr	1524(ra) # 80003228 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c3c:	013d09bb          	addw	s3,s10,s3
    80003c40:	009d04bb          	addw	s1,s10,s1
    80003c44:	9a6e                	add	s4,s4,s11
    80003c46:	0559f763          	bgeu	s3,s5,80003c94 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c4a:	00a4d59b          	srliw	a1,s1,0xa
    80003c4e:	855a                	mv	a0,s6
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	8a2080e7          	jalr	-1886(ra) # 800034f2 <bmap>
    80003c58:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c5c:	cd85                	beqz	a1,80003c94 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c5e:	000b2503          	lw	a0,0(s6)
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	496080e7          	jalr	1174(ra) # 800030f8 <bread>
    80003c6a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6c:	3ff4f613          	andi	a2,s1,1023
    80003c70:	40cc87bb          	subw	a5,s9,a2
    80003c74:	413a873b          	subw	a4,s5,s3
    80003c78:	8d3e                	mv	s10,a5
    80003c7a:	2781                	sext.w	a5,a5
    80003c7c:	0007069b          	sext.w	a3,a4
    80003c80:	f8f6f9e3          	bgeu	a3,a5,80003c12 <readi+0x4c>
    80003c84:	8d3a                	mv	s10,a4
    80003c86:	b771                	j	80003c12 <readi+0x4c>
      brelse(bp);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	59e080e7          	jalr	1438(ra) # 80003228 <brelse>
      tot = -1;
    80003c92:	59fd                	li	s3,-1
  }
  return tot;
    80003c94:	0009851b          	sext.w	a0,s3
}
    80003c98:	70a6                	ld	ra,104(sp)
    80003c9a:	7406                	ld	s0,96(sp)
    80003c9c:	64e6                	ld	s1,88(sp)
    80003c9e:	6946                	ld	s2,80(sp)
    80003ca0:	69a6                	ld	s3,72(sp)
    80003ca2:	6a06                	ld	s4,64(sp)
    80003ca4:	7ae2                	ld	s5,56(sp)
    80003ca6:	7b42                	ld	s6,48(sp)
    80003ca8:	7ba2                	ld	s7,40(sp)
    80003caa:	7c02                	ld	s8,32(sp)
    80003cac:	6ce2                	ld	s9,24(sp)
    80003cae:	6d42                	ld	s10,16(sp)
    80003cb0:	6da2                	ld	s11,8(sp)
    80003cb2:	6165                	addi	sp,sp,112
    80003cb4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb6:	89d6                	mv	s3,s5
    80003cb8:	bff1                	j	80003c94 <readi+0xce>
    return 0;
    80003cba:	4501                	li	a0,0
}
    80003cbc:	8082                	ret

0000000080003cbe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cbe:	457c                	lw	a5,76(a0)
    80003cc0:	10d7e863          	bltu	a5,a3,80003dd0 <writei+0x112>
{
    80003cc4:	7159                	addi	sp,sp,-112
    80003cc6:	f486                	sd	ra,104(sp)
    80003cc8:	f0a2                	sd	s0,96(sp)
    80003cca:	eca6                	sd	s1,88(sp)
    80003ccc:	e8ca                	sd	s2,80(sp)
    80003cce:	e4ce                	sd	s3,72(sp)
    80003cd0:	e0d2                	sd	s4,64(sp)
    80003cd2:	fc56                	sd	s5,56(sp)
    80003cd4:	f85a                	sd	s6,48(sp)
    80003cd6:	f45e                	sd	s7,40(sp)
    80003cd8:	f062                	sd	s8,32(sp)
    80003cda:	ec66                	sd	s9,24(sp)
    80003cdc:	e86a                	sd	s10,16(sp)
    80003cde:	e46e                	sd	s11,8(sp)
    80003ce0:	1880                	addi	s0,sp,112
    80003ce2:	8aaa                	mv	s5,a0
    80003ce4:	8bae                	mv	s7,a1
    80003ce6:	8a32                	mv	s4,a2
    80003ce8:	8936                	mv	s2,a3
    80003cea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cec:	00e687bb          	addw	a5,a3,a4
    80003cf0:	0ed7e263          	bltu	a5,a3,80003dd4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cf4:	00043737          	lui	a4,0x43
    80003cf8:	0ef76063          	bltu	a4,a5,80003dd8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfc:	0c0b0863          	beqz	s6,80003dcc <writei+0x10e>
    80003d00:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d02:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d06:	5c7d                	li	s8,-1
    80003d08:	a091                	j	80003d4c <writei+0x8e>
    80003d0a:	020d1d93          	slli	s11,s10,0x20
    80003d0e:	020ddd93          	srli	s11,s11,0x20
    80003d12:	05848793          	addi	a5,s1,88
    80003d16:	86ee                	mv	a3,s11
    80003d18:	8652                	mv	a2,s4
    80003d1a:	85de                	mv	a1,s7
    80003d1c:	953e                	add	a0,a0,a5
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	80c080e7          	jalr	-2036(ra) # 8000252a <either_copyin>
    80003d26:	07850263          	beq	a0,s8,80003d8a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d2a:	8526                	mv	a0,s1
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	780080e7          	jalr	1920(ra) # 800044ac <log_write>
    brelse(bp);
    80003d34:	8526                	mv	a0,s1
    80003d36:	fffff097          	auipc	ra,0xfffff
    80003d3a:	4f2080e7          	jalr	1266(ra) # 80003228 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3e:	013d09bb          	addw	s3,s10,s3
    80003d42:	012d093b          	addw	s2,s10,s2
    80003d46:	9a6e                	add	s4,s4,s11
    80003d48:	0569f663          	bgeu	s3,s6,80003d94 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d4c:	00a9559b          	srliw	a1,s2,0xa
    80003d50:	8556                	mv	a0,s5
    80003d52:	fffff097          	auipc	ra,0xfffff
    80003d56:	7a0080e7          	jalr	1952(ra) # 800034f2 <bmap>
    80003d5a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d5e:	c99d                	beqz	a1,80003d94 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d60:	000aa503          	lw	a0,0(s5)
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	394080e7          	jalr	916(ra) # 800030f8 <bread>
    80003d6c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6e:	3ff97513          	andi	a0,s2,1023
    80003d72:	40ac87bb          	subw	a5,s9,a0
    80003d76:	413b073b          	subw	a4,s6,s3
    80003d7a:	8d3e                	mv	s10,a5
    80003d7c:	2781                	sext.w	a5,a5
    80003d7e:	0007069b          	sext.w	a3,a4
    80003d82:	f8f6f4e3          	bgeu	a3,a5,80003d0a <writei+0x4c>
    80003d86:	8d3a                	mv	s10,a4
    80003d88:	b749                	j	80003d0a <writei+0x4c>
      brelse(bp);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	49c080e7          	jalr	1180(ra) # 80003228 <brelse>
  }

  if(off > ip->size)
    80003d94:	04caa783          	lw	a5,76(s5)
    80003d98:	0127f463          	bgeu	a5,s2,80003da0 <writei+0xe2>
    ip->size = off;
    80003d9c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003da0:	8556                	mv	a0,s5
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	aa6080e7          	jalr	-1370(ra) # 80003848 <iupdate>

  return tot;
    80003daa:	0009851b          	sext.w	a0,s3
}
    80003dae:	70a6                	ld	ra,104(sp)
    80003db0:	7406                	ld	s0,96(sp)
    80003db2:	64e6                	ld	s1,88(sp)
    80003db4:	6946                	ld	s2,80(sp)
    80003db6:	69a6                	ld	s3,72(sp)
    80003db8:	6a06                	ld	s4,64(sp)
    80003dba:	7ae2                	ld	s5,56(sp)
    80003dbc:	7b42                	ld	s6,48(sp)
    80003dbe:	7ba2                	ld	s7,40(sp)
    80003dc0:	7c02                	ld	s8,32(sp)
    80003dc2:	6ce2                	ld	s9,24(sp)
    80003dc4:	6d42                	ld	s10,16(sp)
    80003dc6:	6da2                	ld	s11,8(sp)
    80003dc8:	6165                	addi	sp,sp,112
    80003dca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dcc:	89da                	mv	s3,s6
    80003dce:	bfc9                	j	80003da0 <writei+0xe2>
    return -1;
    80003dd0:	557d                	li	a0,-1
}
    80003dd2:	8082                	ret
    return -1;
    80003dd4:	557d                	li	a0,-1
    80003dd6:	bfe1                	j	80003dae <writei+0xf0>
    return -1;
    80003dd8:	557d                	li	a0,-1
    80003dda:	bfd1                	j	80003dae <writei+0xf0>

0000000080003ddc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ddc:	1141                	addi	sp,sp,-16
    80003dde:	e406                	sd	ra,8(sp)
    80003de0:	e022                	sd	s0,0(sp)
    80003de2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003de4:	4639                	li	a2,14
    80003de6:	ffffd097          	auipc	ra,0xffffd
    80003dea:	018080e7          	jalr	24(ra) # 80000dfe <strncmp>
}
    80003dee:	60a2                	ld	ra,8(sp)
    80003df0:	6402                	ld	s0,0(sp)
    80003df2:	0141                	addi	sp,sp,16
    80003df4:	8082                	ret

0000000080003df6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003df6:	7139                	addi	sp,sp,-64
    80003df8:	fc06                	sd	ra,56(sp)
    80003dfa:	f822                	sd	s0,48(sp)
    80003dfc:	f426                	sd	s1,40(sp)
    80003dfe:	f04a                	sd	s2,32(sp)
    80003e00:	ec4e                	sd	s3,24(sp)
    80003e02:	e852                	sd	s4,16(sp)
    80003e04:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e06:	04451703          	lh	a4,68(a0)
    80003e0a:	4785                	li	a5,1
    80003e0c:	00f71a63          	bne	a4,a5,80003e20 <dirlookup+0x2a>
    80003e10:	892a                	mv	s2,a0
    80003e12:	89ae                	mv	s3,a1
    80003e14:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e16:	457c                	lw	a5,76(a0)
    80003e18:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e1a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e1c:	e79d                	bnez	a5,80003e4a <dirlookup+0x54>
    80003e1e:	a8a5                	j	80003e96 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e20:	00005517          	auipc	a0,0x5
    80003e24:	82850513          	addi	a0,a0,-2008 # 80008648 <syscalls+0x1c8>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	716080e7          	jalr	1814(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e30:	00005517          	auipc	a0,0x5
    80003e34:	83050513          	addi	a0,a0,-2000 # 80008660 <syscalls+0x1e0>
    80003e38:	ffffc097          	auipc	ra,0xffffc
    80003e3c:	706080e7          	jalr	1798(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e40:	24c1                	addiw	s1,s1,16
    80003e42:	04c92783          	lw	a5,76(s2)
    80003e46:	04f4f763          	bgeu	s1,a5,80003e94 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e4a:	4741                	li	a4,16
    80003e4c:	86a6                	mv	a3,s1
    80003e4e:	fc040613          	addi	a2,s0,-64
    80003e52:	4581                	li	a1,0
    80003e54:	854a                	mv	a0,s2
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	d70080e7          	jalr	-656(ra) # 80003bc6 <readi>
    80003e5e:	47c1                	li	a5,16
    80003e60:	fcf518e3          	bne	a0,a5,80003e30 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e64:	fc045783          	lhu	a5,-64(s0)
    80003e68:	dfe1                	beqz	a5,80003e40 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e6a:	fc240593          	addi	a1,s0,-62
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	f6c080e7          	jalr	-148(ra) # 80003ddc <namecmp>
    80003e78:	f561                	bnez	a0,80003e40 <dirlookup+0x4a>
      if(poff)
    80003e7a:	000a0463          	beqz	s4,80003e82 <dirlookup+0x8c>
        *poff = off;
    80003e7e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e82:	fc045583          	lhu	a1,-64(s0)
    80003e86:	00092503          	lw	a0,0(s2)
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	750080e7          	jalr	1872(ra) # 800035da <iget>
    80003e92:	a011                	j	80003e96 <dirlookup+0xa0>
  return 0;
    80003e94:	4501                	li	a0,0
}
    80003e96:	70e2                	ld	ra,56(sp)
    80003e98:	7442                	ld	s0,48(sp)
    80003e9a:	74a2                	ld	s1,40(sp)
    80003e9c:	7902                	ld	s2,32(sp)
    80003e9e:	69e2                	ld	s3,24(sp)
    80003ea0:	6a42                	ld	s4,16(sp)
    80003ea2:	6121                	addi	sp,sp,64
    80003ea4:	8082                	ret

0000000080003ea6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ea6:	711d                	addi	sp,sp,-96
    80003ea8:	ec86                	sd	ra,88(sp)
    80003eaa:	e8a2                	sd	s0,80(sp)
    80003eac:	e4a6                	sd	s1,72(sp)
    80003eae:	e0ca                	sd	s2,64(sp)
    80003eb0:	fc4e                	sd	s3,56(sp)
    80003eb2:	f852                	sd	s4,48(sp)
    80003eb4:	f456                	sd	s5,40(sp)
    80003eb6:	f05a                	sd	s6,32(sp)
    80003eb8:	ec5e                	sd	s7,24(sp)
    80003eba:	e862                	sd	s8,16(sp)
    80003ebc:	e466                	sd	s9,8(sp)
    80003ebe:	1080                	addi	s0,sp,96
    80003ec0:	84aa                	mv	s1,a0
    80003ec2:	8aae                	mv	s5,a1
    80003ec4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ec6:	00054703          	lbu	a4,0(a0)
    80003eca:	02f00793          	li	a5,47
    80003ece:	02f70363          	beq	a4,a5,80003ef4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ed2:	ffffe097          	auipc	ra,0xffffe
    80003ed6:	b36080e7          	jalr	-1226(ra) # 80001a08 <myproc>
    80003eda:	15053503          	ld	a0,336(a0)
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	9f6080e7          	jalr	-1546(ra) # 800038d4 <idup>
    80003ee6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ee8:	02f00913          	li	s2,47
  len = path - s;
    80003eec:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eee:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ef0:	4b85                	li	s7,1
    80003ef2:	a865                	j	80003faa <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ef4:	4585                	li	a1,1
    80003ef6:	4505                	li	a0,1
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	6e2080e7          	jalr	1762(ra) # 800035da <iget>
    80003f00:	89aa                	mv	s3,a0
    80003f02:	b7dd                	j	80003ee8 <namex+0x42>
      iunlockput(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c6e080e7          	jalr	-914(ra) # 80003b74 <iunlockput>
      return 0;
    80003f0e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f10:	854e                	mv	a0,s3
    80003f12:	60e6                	ld	ra,88(sp)
    80003f14:	6446                	ld	s0,80(sp)
    80003f16:	64a6                	ld	s1,72(sp)
    80003f18:	6906                	ld	s2,64(sp)
    80003f1a:	79e2                	ld	s3,56(sp)
    80003f1c:	7a42                	ld	s4,48(sp)
    80003f1e:	7aa2                	ld	s5,40(sp)
    80003f20:	7b02                	ld	s6,32(sp)
    80003f22:	6be2                	ld	s7,24(sp)
    80003f24:	6c42                	ld	s8,16(sp)
    80003f26:	6ca2                	ld	s9,8(sp)
    80003f28:	6125                	addi	sp,sp,96
    80003f2a:	8082                	ret
      iunlock(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	aa6080e7          	jalr	-1370(ra) # 800039d4 <iunlock>
      return ip;
    80003f36:	bfe9                	j	80003f10 <namex+0x6a>
      iunlockput(ip);
    80003f38:	854e                	mv	a0,s3
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	c3a080e7          	jalr	-966(ra) # 80003b74 <iunlockput>
      return 0;
    80003f42:	89e6                	mv	s3,s9
    80003f44:	b7f1                	j	80003f10 <namex+0x6a>
  len = path - s;
    80003f46:	40b48633          	sub	a2,s1,a1
    80003f4a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f4e:	099c5463          	bge	s8,s9,80003fd6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f52:	4639                	li	a2,14
    80003f54:	8552                	mv	a0,s4
    80003f56:	ffffd097          	auipc	ra,0xffffd
    80003f5a:	e34080e7          	jalr	-460(ra) # 80000d8a <memmove>
  while(*path == '/')
    80003f5e:	0004c783          	lbu	a5,0(s1)
    80003f62:	01279763          	bne	a5,s2,80003f70 <namex+0xca>
    path++;
    80003f66:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f68:	0004c783          	lbu	a5,0(s1)
    80003f6c:	ff278de3          	beq	a5,s2,80003f66 <namex+0xc0>
    ilock(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	9a0080e7          	jalr	-1632(ra) # 80003912 <ilock>
    if(ip->type != T_DIR){
    80003f7a:	04499783          	lh	a5,68(s3)
    80003f7e:	f97793e3          	bne	a5,s7,80003f04 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f82:	000a8563          	beqz	s5,80003f8c <namex+0xe6>
    80003f86:	0004c783          	lbu	a5,0(s1)
    80003f8a:	d3cd                	beqz	a5,80003f2c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f8c:	865a                	mv	a2,s6
    80003f8e:	85d2                	mv	a1,s4
    80003f90:	854e                	mv	a0,s3
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	e64080e7          	jalr	-412(ra) # 80003df6 <dirlookup>
    80003f9a:	8caa                	mv	s9,a0
    80003f9c:	dd51                	beqz	a0,80003f38 <namex+0x92>
    iunlockput(ip);
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	bd4080e7          	jalr	-1068(ra) # 80003b74 <iunlockput>
    ip = next;
    80003fa8:	89e6                	mv	s3,s9
  while(*path == '/')
    80003faa:	0004c783          	lbu	a5,0(s1)
    80003fae:	05279763          	bne	a5,s2,80003ffc <namex+0x156>
    path++;
    80003fb2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb4:	0004c783          	lbu	a5,0(s1)
    80003fb8:	ff278de3          	beq	a5,s2,80003fb2 <namex+0x10c>
  if(*path == 0)
    80003fbc:	c79d                	beqz	a5,80003fea <namex+0x144>
    path++;
    80003fbe:	85a6                	mv	a1,s1
  len = path - s;
    80003fc0:	8cda                	mv	s9,s6
    80003fc2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fc4:	01278963          	beq	a5,s2,80003fd6 <namex+0x130>
    80003fc8:	dfbd                	beqz	a5,80003f46 <namex+0xa0>
    path++;
    80003fca:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fcc:	0004c783          	lbu	a5,0(s1)
    80003fd0:	ff279ce3          	bne	a5,s2,80003fc8 <namex+0x122>
    80003fd4:	bf8d                	j	80003f46 <namex+0xa0>
    memmove(name, s, len);
    80003fd6:	2601                	sext.w	a2,a2
    80003fd8:	8552                	mv	a0,s4
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	db0080e7          	jalr	-592(ra) # 80000d8a <memmove>
    name[len] = 0;
    80003fe2:	9cd2                	add	s9,s9,s4
    80003fe4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fe8:	bf9d                	j	80003f5e <namex+0xb8>
  if(nameiparent){
    80003fea:	f20a83e3          	beqz	s5,80003f10 <namex+0x6a>
    iput(ip);
    80003fee:	854e                	mv	a0,s3
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	adc080e7          	jalr	-1316(ra) # 80003acc <iput>
    return 0;
    80003ff8:	4981                	li	s3,0
    80003ffa:	bf19                	j	80003f10 <namex+0x6a>
  if(*path == 0)
    80003ffc:	d7fd                	beqz	a5,80003fea <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ffe:	0004c783          	lbu	a5,0(s1)
    80004002:	85a6                	mv	a1,s1
    80004004:	b7d1                	j	80003fc8 <namex+0x122>

0000000080004006 <dirlink>:
{
    80004006:	7139                	addi	sp,sp,-64
    80004008:	fc06                	sd	ra,56(sp)
    8000400a:	f822                	sd	s0,48(sp)
    8000400c:	f426                	sd	s1,40(sp)
    8000400e:	f04a                	sd	s2,32(sp)
    80004010:	ec4e                	sd	s3,24(sp)
    80004012:	e852                	sd	s4,16(sp)
    80004014:	0080                	addi	s0,sp,64
    80004016:	892a                	mv	s2,a0
    80004018:	8a2e                	mv	s4,a1
    8000401a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000401c:	4601                	li	a2,0
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	dd8080e7          	jalr	-552(ra) # 80003df6 <dirlookup>
    80004026:	e93d                	bnez	a0,8000409c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004028:	04c92483          	lw	s1,76(s2)
    8000402c:	c49d                	beqz	s1,8000405a <dirlink+0x54>
    8000402e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004030:	4741                	li	a4,16
    80004032:	86a6                	mv	a3,s1
    80004034:	fc040613          	addi	a2,s0,-64
    80004038:	4581                	li	a1,0
    8000403a:	854a                	mv	a0,s2
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	b8a080e7          	jalr	-1142(ra) # 80003bc6 <readi>
    80004044:	47c1                	li	a5,16
    80004046:	06f51163          	bne	a0,a5,800040a8 <dirlink+0xa2>
    if(de.inum == 0)
    8000404a:	fc045783          	lhu	a5,-64(s0)
    8000404e:	c791                	beqz	a5,8000405a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004050:	24c1                	addiw	s1,s1,16
    80004052:	04c92783          	lw	a5,76(s2)
    80004056:	fcf4ede3          	bltu	s1,a5,80004030 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000405a:	4639                	li	a2,14
    8000405c:	85d2                	mv	a1,s4
    8000405e:	fc240513          	addi	a0,s0,-62
    80004062:	ffffd097          	auipc	ra,0xffffd
    80004066:	dd8080e7          	jalr	-552(ra) # 80000e3a <strncpy>
  de.inum = inum;
    8000406a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406e:	4741                	li	a4,16
    80004070:	86a6                	mv	a3,s1
    80004072:	fc040613          	addi	a2,s0,-64
    80004076:	4581                	li	a1,0
    80004078:	854a                	mv	a0,s2
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	c44080e7          	jalr	-956(ra) # 80003cbe <writei>
    80004082:	1541                	addi	a0,a0,-16
    80004084:	00a03533          	snez	a0,a0
    80004088:	40a00533          	neg	a0,a0
}
    8000408c:	70e2                	ld	ra,56(sp)
    8000408e:	7442                	ld	s0,48(sp)
    80004090:	74a2                	ld	s1,40(sp)
    80004092:	7902                	ld	s2,32(sp)
    80004094:	69e2                	ld	s3,24(sp)
    80004096:	6a42                	ld	s4,16(sp)
    80004098:	6121                	addi	sp,sp,64
    8000409a:	8082                	ret
    iput(ip);
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	a30080e7          	jalr	-1488(ra) # 80003acc <iput>
    return -1;
    800040a4:	557d                	li	a0,-1
    800040a6:	b7dd                	j	8000408c <dirlink+0x86>
      panic("dirlink read");
    800040a8:	00004517          	auipc	a0,0x4
    800040ac:	5c850513          	addi	a0,a0,1480 # 80008670 <syscalls+0x1f0>
    800040b0:	ffffc097          	auipc	ra,0xffffc
    800040b4:	48e080e7          	jalr	1166(ra) # 8000053e <panic>

00000000800040b8 <namei>:

struct inode*
namei(char *path)
{
    800040b8:	1101                	addi	sp,sp,-32
    800040ba:	ec06                	sd	ra,24(sp)
    800040bc:	e822                	sd	s0,16(sp)
    800040be:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040c0:	fe040613          	addi	a2,s0,-32
    800040c4:	4581                	li	a1,0
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	de0080e7          	jalr	-544(ra) # 80003ea6 <namex>
}
    800040ce:	60e2                	ld	ra,24(sp)
    800040d0:	6442                	ld	s0,16(sp)
    800040d2:	6105                	addi	sp,sp,32
    800040d4:	8082                	ret

00000000800040d6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040d6:	1141                	addi	sp,sp,-16
    800040d8:	e406                	sd	ra,8(sp)
    800040da:	e022                	sd	s0,0(sp)
    800040dc:	0800                	addi	s0,sp,16
    800040de:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040e0:	4585                	li	a1,1
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	dc4080e7          	jalr	-572(ra) # 80003ea6 <namex>
}
    800040ea:	60a2                	ld	ra,8(sp)
    800040ec:	6402                	ld	s0,0(sp)
    800040ee:	0141                	addi	sp,sp,16
    800040f0:	8082                	ret

00000000800040f2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040f2:	1101                	addi	sp,sp,-32
    800040f4:	ec06                	sd	ra,24(sp)
    800040f6:	e822                	sd	s0,16(sp)
    800040f8:	e426                	sd	s1,8(sp)
    800040fa:	e04a                	sd	s2,0(sp)
    800040fc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040fe:	0001d917          	auipc	s2,0x1d
    80004102:	c6290913          	addi	s2,s2,-926 # 80020d60 <log>
    80004106:	01892583          	lw	a1,24(s2)
    8000410a:	02892503          	lw	a0,40(s2)
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	fea080e7          	jalr	-22(ra) # 800030f8 <bread>
    80004116:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004118:	02c92683          	lw	a3,44(s2)
    8000411c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000411e:	02d05763          	blez	a3,8000414c <write_head+0x5a>
    80004122:	0001d797          	auipc	a5,0x1d
    80004126:	c6e78793          	addi	a5,a5,-914 # 80020d90 <log+0x30>
    8000412a:	05c50713          	addi	a4,a0,92
    8000412e:	36fd                	addiw	a3,a3,-1
    80004130:	1682                	slli	a3,a3,0x20
    80004132:	9281                	srli	a3,a3,0x20
    80004134:	068a                	slli	a3,a3,0x2
    80004136:	0001d617          	auipc	a2,0x1d
    8000413a:	c5e60613          	addi	a2,a2,-930 # 80020d94 <log+0x34>
    8000413e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004140:	4390                	lw	a2,0(a5)
    80004142:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004144:	0791                	addi	a5,a5,4
    80004146:	0711                	addi	a4,a4,4
    80004148:	fed79ce3          	bne	a5,a3,80004140 <write_head+0x4e>
  }
  bwrite(buf);
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	09c080e7          	jalr	156(ra) # 800031ea <bwrite>
  brelse(buf);
    80004156:	8526                	mv	a0,s1
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	0d0080e7          	jalr	208(ra) # 80003228 <brelse>
}
    80004160:	60e2                	ld	ra,24(sp)
    80004162:	6442                	ld	s0,16(sp)
    80004164:	64a2                	ld	s1,8(sp)
    80004166:	6902                	ld	s2,0(sp)
    80004168:	6105                	addi	sp,sp,32
    8000416a:	8082                	ret

000000008000416c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416c:	0001d797          	auipc	a5,0x1d
    80004170:	c207a783          	lw	a5,-992(a5) # 80020d8c <log+0x2c>
    80004174:	0af05d63          	blez	a5,8000422e <install_trans+0xc2>
{
    80004178:	7139                	addi	sp,sp,-64
    8000417a:	fc06                	sd	ra,56(sp)
    8000417c:	f822                	sd	s0,48(sp)
    8000417e:	f426                	sd	s1,40(sp)
    80004180:	f04a                	sd	s2,32(sp)
    80004182:	ec4e                	sd	s3,24(sp)
    80004184:	e852                	sd	s4,16(sp)
    80004186:	e456                	sd	s5,8(sp)
    80004188:	e05a                	sd	s6,0(sp)
    8000418a:	0080                	addi	s0,sp,64
    8000418c:	8b2a                	mv	s6,a0
    8000418e:	0001da97          	auipc	s5,0x1d
    80004192:	c02a8a93          	addi	s5,s5,-1022 # 80020d90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004196:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004198:	0001d997          	auipc	s3,0x1d
    8000419c:	bc898993          	addi	s3,s3,-1080 # 80020d60 <log>
    800041a0:	a00d                	j	800041c2 <install_trans+0x56>
    brelse(lbuf);
    800041a2:	854a                	mv	a0,s2
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	084080e7          	jalr	132(ra) # 80003228 <brelse>
    brelse(dbuf);
    800041ac:	8526                	mv	a0,s1
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	07a080e7          	jalr	122(ra) # 80003228 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b6:	2a05                	addiw	s4,s4,1
    800041b8:	0a91                	addi	s5,s5,4
    800041ba:	02c9a783          	lw	a5,44(s3)
    800041be:	04fa5e63          	bge	s4,a5,8000421a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041c2:	0189a583          	lw	a1,24(s3)
    800041c6:	014585bb          	addw	a1,a1,s4
    800041ca:	2585                	addiw	a1,a1,1
    800041cc:	0289a503          	lw	a0,40(s3)
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	f28080e7          	jalr	-216(ra) # 800030f8 <bread>
    800041d8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041da:	000aa583          	lw	a1,0(s5)
    800041de:	0289a503          	lw	a0,40(s3)
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	f16080e7          	jalr	-234(ra) # 800030f8 <bread>
    800041ea:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ec:	40000613          	li	a2,1024
    800041f0:	05890593          	addi	a1,s2,88
    800041f4:	05850513          	addi	a0,a0,88
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	b92080e7          	jalr	-1134(ra) # 80000d8a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004200:	8526                	mv	a0,s1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	fe8080e7          	jalr	-24(ra) # 800031ea <bwrite>
    if(recovering == 0)
    8000420a:	f80b1ce3          	bnez	s6,800041a2 <install_trans+0x36>
      bunpin(dbuf);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	0f2080e7          	jalr	242(ra) # 80003302 <bunpin>
    80004218:	b769                	j	800041a2 <install_trans+0x36>
}
    8000421a:	70e2                	ld	ra,56(sp)
    8000421c:	7442                	ld	s0,48(sp)
    8000421e:	74a2                	ld	s1,40(sp)
    80004220:	7902                	ld	s2,32(sp)
    80004222:	69e2                	ld	s3,24(sp)
    80004224:	6a42                	ld	s4,16(sp)
    80004226:	6aa2                	ld	s5,8(sp)
    80004228:	6b02                	ld	s6,0(sp)
    8000422a:	6121                	addi	sp,sp,64
    8000422c:	8082                	ret
    8000422e:	8082                	ret

0000000080004230 <initlog>:
{
    80004230:	7179                	addi	sp,sp,-48
    80004232:	f406                	sd	ra,40(sp)
    80004234:	f022                	sd	s0,32(sp)
    80004236:	ec26                	sd	s1,24(sp)
    80004238:	e84a                	sd	s2,16(sp)
    8000423a:	e44e                	sd	s3,8(sp)
    8000423c:	1800                	addi	s0,sp,48
    8000423e:	892a                	mv	s2,a0
    80004240:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004242:	0001d497          	auipc	s1,0x1d
    80004246:	b1e48493          	addi	s1,s1,-1250 # 80020d60 <log>
    8000424a:	00004597          	auipc	a1,0x4
    8000424e:	43658593          	addi	a1,a1,1078 # 80008680 <syscalls+0x200>
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	94e080e7          	jalr	-1714(ra) # 80000ba2 <initlock>
  log.start = sb->logstart;
    8000425c:	0149a583          	lw	a1,20(s3)
    80004260:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004262:	0109a783          	lw	a5,16(s3)
    80004266:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004268:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000426c:	854a                	mv	a0,s2
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	e8a080e7          	jalr	-374(ra) # 800030f8 <bread>
  log.lh.n = lh->n;
    80004276:	4d34                	lw	a3,88(a0)
    80004278:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000427a:	02d05563          	blez	a3,800042a4 <initlog+0x74>
    8000427e:	05c50793          	addi	a5,a0,92
    80004282:	0001d717          	auipc	a4,0x1d
    80004286:	b0e70713          	addi	a4,a4,-1266 # 80020d90 <log+0x30>
    8000428a:	36fd                	addiw	a3,a3,-1
    8000428c:	1682                	slli	a3,a3,0x20
    8000428e:	9281                	srli	a3,a3,0x20
    80004290:	068a                	slli	a3,a3,0x2
    80004292:	06050613          	addi	a2,a0,96
    80004296:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004298:	4390                	lw	a2,0(a5)
    8000429a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000429c:	0791                	addi	a5,a5,4
    8000429e:	0711                	addi	a4,a4,4
    800042a0:	fed79ce3          	bne	a5,a3,80004298 <initlog+0x68>
  brelse(buf);
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	f84080e7          	jalr	-124(ra) # 80003228 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042ac:	4505                	li	a0,1
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	ebe080e7          	jalr	-322(ra) # 8000416c <install_trans>
  log.lh.n = 0;
    800042b6:	0001d797          	auipc	a5,0x1d
    800042ba:	ac07ab23          	sw	zero,-1322(a5) # 80020d8c <log+0x2c>
  write_head(); // clear the log
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	e34080e7          	jalr	-460(ra) # 800040f2 <write_head>
}
    800042c6:	70a2                	ld	ra,40(sp)
    800042c8:	7402                	ld	s0,32(sp)
    800042ca:	64e2                	ld	s1,24(sp)
    800042cc:	6942                	ld	s2,16(sp)
    800042ce:	69a2                	ld	s3,8(sp)
    800042d0:	6145                	addi	sp,sp,48
    800042d2:	8082                	ret

00000000800042d4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042d4:	1101                	addi	sp,sp,-32
    800042d6:	ec06                	sd	ra,24(sp)
    800042d8:	e822                	sd	s0,16(sp)
    800042da:	e426                	sd	s1,8(sp)
    800042dc:	e04a                	sd	s2,0(sp)
    800042de:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042e0:	0001d517          	auipc	a0,0x1d
    800042e4:	a8050513          	addi	a0,a0,-1408 # 80020d60 <log>
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	94a080e7          	jalr	-1718(ra) # 80000c32 <acquire>
  while(1){
    if(log.committing){
    800042f0:	0001d497          	auipc	s1,0x1d
    800042f4:	a7048493          	addi	s1,s1,-1424 # 80020d60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f8:	4979                	li	s2,30
    800042fa:	a039                	j	80004308 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042fc:	85a6                	mv	a1,s1
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffe097          	auipc	ra,0xffffe
    80004304:	dc8080e7          	jalr	-568(ra) # 800020c8 <sleep>
    if(log.committing){
    80004308:	50dc                	lw	a5,36(s1)
    8000430a:	fbed                	bnez	a5,800042fc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000430c:	509c                	lw	a5,32(s1)
    8000430e:	0017871b          	addiw	a4,a5,1
    80004312:	0007069b          	sext.w	a3,a4
    80004316:	0027179b          	slliw	a5,a4,0x2
    8000431a:	9fb9                	addw	a5,a5,a4
    8000431c:	0017979b          	slliw	a5,a5,0x1
    80004320:	54d8                	lw	a4,44(s1)
    80004322:	9fb9                	addw	a5,a5,a4
    80004324:	00f95963          	bge	s2,a5,80004336 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004328:	85a6                	mv	a1,s1
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffe097          	auipc	ra,0xffffe
    80004330:	d9c080e7          	jalr	-612(ra) # 800020c8 <sleep>
    80004334:	bfd1                	j	80004308 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004336:	0001d517          	auipc	a0,0x1d
    8000433a:	a2a50513          	addi	a0,a0,-1494 # 80020d60 <log>
    8000433e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	9a6080e7          	jalr	-1626(ra) # 80000ce6 <release>
      break;
    }
  }
}
    80004348:	60e2                	ld	ra,24(sp)
    8000434a:	6442                	ld	s0,16(sp)
    8000434c:	64a2                	ld	s1,8(sp)
    8000434e:	6902                	ld	s2,0(sp)
    80004350:	6105                	addi	sp,sp,32
    80004352:	8082                	ret

0000000080004354 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004354:	7139                	addi	sp,sp,-64
    80004356:	fc06                	sd	ra,56(sp)
    80004358:	f822                	sd	s0,48(sp)
    8000435a:	f426                	sd	s1,40(sp)
    8000435c:	f04a                	sd	s2,32(sp)
    8000435e:	ec4e                	sd	s3,24(sp)
    80004360:	e852                	sd	s4,16(sp)
    80004362:	e456                	sd	s5,8(sp)
    80004364:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004366:	0001d497          	auipc	s1,0x1d
    8000436a:	9fa48493          	addi	s1,s1,-1542 # 80020d60 <log>
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	8c2080e7          	jalr	-1854(ra) # 80000c32 <acquire>
  log.outstanding -= 1;
    80004378:	509c                	lw	a5,32(s1)
    8000437a:	37fd                	addiw	a5,a5,-1
    8000437c:	0007891b          	sext.w	s2,a5
    80004380:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004382:	50dc                	lw	a5,36(s1)
    80004384:	e7b9                	bnez	a5,800043d2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004386:	04091e63          	bnez	s2,800043e2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000438a:	0001d497          	auipc	s1,0x1d
    8000438e:	9d648493          	addi	s1,s1,-1578 # 80020d60 <log>
    80004392:	4785                	li	a5,1
    80004394:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004396:	8526                	mv	a0,s1
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	94e080e7          	jalr	-1714(ra) # 80000ce6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043a0:	54dc                	lw	a5,44(s1)
    800043a2:	06f04763          	bgtz	a5,80004410 <end_op+0xbc>
    acquire(&log.lock);
    800043a6:	0001d497          	auipc	s1,0x1d
    800043aa:	9ba48493          	addi	s1,s1,-1606 # 80020d60 <log>
    800043ae:	8526                	mv	a0,s1
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	882080e7          	jalr	-1918(ra) # 80000c32 <acquire>
    log.committing = 0;
    800043b8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043bc:	8526                	mv	a0,s1
    800043be:	ffffe097          	auipc	ra,0xffffe
    800043c2:	d6e080e7          	jalr	-658(ra) # 8000212c <wakeup>
    release(&log.lock);
    800043c6:	8526                	mv	a0,s1
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	91e080e7          	jalr	-1762(ra) # 80000ce6 <release>
}
    800043d0:	a03d                	j	800043fe <end_op+0xaa>
    panic("log.committing");
    800043d2:	00004517          	auipc	a0,0x4
    800043d6:	2b650513          	addi	a0,a0,694 # 80008688 <syscalls+0x208>
    800043da:	ffffc097          	auipc	ra,0xffffc
    800043de:	164080e7          	jalr	356(ra) # 8000053e <panic>
    wakeup(&log);
    800043e2:	0001d497          	auipc	s1,0x1d
    800043e6:	97e48493          	addi	s1,s1,-1666 # 80020d60 <log>
    800043ea:	8526                	mv	a0,s1
    800043ec:	ffffe097          	auipc	ra,0xffffe
    800043f0:	d40080e7          	jalr	-704(ra) # 8000212c <wakeup>
  release(&log.lock);
    800043f4:	8526                	mv	a0,s1
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	8f0080e7          	jalr	-1808(ra) # 80000ce6 <release>
}
    800043fe:	70e2                	ld	ra,56(sp)
    80004400:	7442                	ld	s0,48(sp)
    80004402:	74a2                	ld	s1,40(sp)
    80004404:	7902                	ld	s2,32(sp)
    80004406:	69e2                	ld	s3,24(sp)
    80004408:	6a42                	ld	s4,16(sp)
    8000440a:	6aa2                	ld	s5,8(sp)
    8000440c:	6121                	addi	sp,sp,64
    8000440e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004410:	0001da97          	auipc	s5,0x1d
    80004414:	980a8a93          	addi	s5,s5,-1664 # 80020d90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004418:	0001da17          	auipc	s4,0x1d
    8000441c:	948a0a13          	addi	s4,s4,-1720 # 80020d60 <log>
    80004420:	018a2583          	lw	a1,24(s4)
    80004424:	012585bb          	addw	a1,a1,s2
    80004428:	2585                	addiw	a1,a1,1
    8000442a:	028a2503          	lw	a0,40(s4)
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	cca080e7          	jalr	-822(ra) # 800030f8 <bread>
    80004436:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004438:	000aa583          	lw	a1,0(s5)
    8000443c:	028a2503          	lw	a0,40(s4)
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	cb8080e7          	jalr	-840(ra) # 800030f8 <bread>
    80004448:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000444a:	40000613          	li	a2,1024
    8000444e:	05850593          	addi	a1,a0,88
    80004452:	05848513          	addi	a0,s1,88
    80004456:	ffffd097          	auipc	ra,0xffffd
    8000445a:	934080e7          	jalr	-1740(ra) # 80000d8a <memmove>
    bwrite(to);  // write the log
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	d8a080e7          	jalr	-630(ra) # 800031ea <bwrite>
    brelse(from);
    80004468:	854e                	mv	a0,s3
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	dbe080e7          	jalr	-578(ra) # 80003228 <brelse>
    brelse(to);
    80004472:	8526                	mv	a0,s1
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	db4080e7          	jalr	-588(ra) # 80003228 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447c:	2905                	addiw	s2,s2,1
    8000447e:	0a91                	addi	s5,s5,4
    80004480:	02ca2783          	lw	a5,44(s4)
    80004484:	f8f94ee3          	blt	s2,a5,80004420 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	c6a080e7          	jalr	-918(ra) # 800040f2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004490:	4501                	li	a0,0
    80004492:	00000097          	auipc	ra,0x0
    80004496:	cda080e7          	jalr	-806(ra) # 8000416c <install_trans>
    log.lh.n = 0;
    8000449a:	0001d797          	auipc	a5,0x1d
    8000449e:	8e07a923          	sw	zero,-1806(a5) # 80020d8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	c50080e7          	jalr	-944(ra) # 800040f2 <write_head>
    800044aa:	bdf5                	j	800043a6 <end_op+0x52>

00000000800044ac <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044ac:	1101                	addi	sp,sp,-32
    800044ae:	ec06                	sd	ra,24(sp)
    800044b0:	e822                	sd	s0,16(sp)
    800044b2:	e426                	sd	s1,8(sp)
    800044b4:	e04a                	sd	s2,0(sp)
    800044b6:	1000                	addi	s0,sp,32
    800044b8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044ba:	0001d917          	auipc	s2,0x1d
    800044be:	8a690913          	addi	s2,s2,-1882 # 80020d60 <log>
    800044c2:	854a                	mv	a0,s2
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	76e080e7          	jalr	1902(ra) # 80000c32 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044cc:	02c92603          	lw	a2,44(s2)
    800044d0:	47f5                	li	a5,29
    800044d2:	06c7c563          	blt	a5,a2,8000453c <log_write+0x90>
    800044d6:	0001d797          	auipc	a5,0x1d
    800044da:	8a67a783          	lw	a5,-1882(a5) # 80020d7c <log+0x1c>
    800044de:	37fd                	addiw	a5,a5,-1
    800044e0:	04f65e63          	bge	a2,a5,8000453c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044e4:	0001d797          	auipc	a5,0x1d
    800044e8:	89c7a783          	lw	a5,-1892(a5) # 80020d80 <log+0x20>
    800044ec:	06f05063          	blez	a5,8000454c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044f0:	4781                	li	a5,0
    800044f2:	06c05563          	blez	a2,8000455c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044f6:	44cc                	lw	a1,12(s1)
    800044f8:	0001d717          	auipc	a4,0x1d
    800044fc:	89870713          	addi	a4,a4,-1896 # 80020d90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004500:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004502:	4314                	lw	a3,0(a4)
    80004504:	04b68c63          	beq	a3,a1,8000455c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004508:	2785                	addiw	a5,a5,1
    8000450a:	0711                	addi	a4,a4,4
    8000450c:	fef61be3          	bne	a2,a5,80004502 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004510:	0621                	addi	a2,a2,8
    80004512:	060a                	slli	a2,a2,0x2
    80004514:	0001d797          	auipc	a5,0x1d
    80004518:	84c78793          	addi	a5,a5,-1972 # 80020d60 <log>
    8000451c:	963e                	add	a2,a2,a5
    8000451e:	44dc                	lw	a5,12(s1)
    80004520:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	da2080e7          	jalr	-606(ra) # 800032c6 <bpin>
    log.lh.n++;
    8000452c:	0001d717          	auipc	a4,0x1d
    80004530:	83470713          	addi	a4,a4,-1996 # 80020d60 <log>
    80004534:	575c                	lw	a5,44(a4)
    80004536:	2785                	addiw	a5,a5,1
    80004538:	d75c                	sw	a5,44(a4)
    8000453a:	a835                	j	80004576 <log_write+0xca>
    panic("too big a transaction");
    8000453c:	00004517          	auipc	a0,0x4
    80004540:	15c50513          	addi	a0,a0,348 # 80008698 <syscalls+0x218>
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	ffa080e7          	jalr	-6(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000454c:	00004517          	auipc	a0,0x4
    80004550:	16450513          	addi	a0,a0,356 # 800086b0 <syscalls+0x230>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000455c:	00878713          	addi	a4,a5,8
    80004560:	00271693          	slli	a3,a4,0x2
    80004564:	0001c717          	auipc	a4,0x1c
    80004568:	7fc70713          	addi	a4,a4,2044 # 80020d60 <log>
    8000456c:	9736                	add	a4,a4,a3
    8000456e:	44d4                	lw	a3,12(s1)
    80004570:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004572:	faf608e3          	beq	a2,a5,80004522 <log_write+0x76>
  }
  release(&log.lock);
    80004576:	0001c517          	auipc	a0,0x1c
    8000457a:	7ea50513          	addi	a0,a0,2026 # 80020d60 <log>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	768080e7          	jalr	1896(ra) # 80000ce6 <release>
}
    80004586:	60e2                	ld	ra,24(sp)
    80004588:	6442                	ld	s0,16(sp)
    8000458a:	64a2                	ld	s1,8(sp)
    8000458c:	6902                	ld	s2,0(sp)
    8000458e:	6105                	addi	sp,sp,32
    80004590:	8082                	ret

0000000080004592 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004592:	1101                	addi	sp,sp,-32
    80004594:	ec06                	sd	ra,24(sp)
    80004596:	e822                	sd	s0,16(sp)
    80004598:	e426                	sd	s1,8(sp)
    8000459a:	e04a                	sd	s2,0(sp)
    8000459c:	1000                	addi	s0,sp,32
    8000459e:	84aa                	mv	s1,a0
    800045a0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045a2:	00004597          	auipc	a1,0x4
    800045a6:	12e58593          	addi	a1,a1,302 # 800086d0 <syscalls+0x250>
    800045aa:	0521                	addi	a0,a0,8
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	5f6080e7          	jalr	1526(ra) # 80000ba2 <initlock>
  lk->name = name;
    800045b4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045bc:	0204a423          	sw	zero,40(s1)
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045da:	00850913          	addi	s2,a0,8
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	652080e7          	jalr	1618(ra) # 80000c32 <acquire>
  while (lk->locked) {
    800045e8:	409c                	lw	a5,0(s1)
    800045ea:	cb89                	beqz	a5,800045fc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ec:	85ca                	mv	a1,s2
    800045ee:	8526                	mv	a0,s1
    800045f0:	ffffe097          	auipc	ra,0xffffe
    800045f4:	ad8080e7          	jalr	-1320(ra) # 800020c8 <sleep>
  while (lk->locked) {
    800045f8:	409c                	lw	a5,0(s1)
    800045fa:	fbed                	bnez	a5,800045ec <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045fc:	4785                	li	a5,1
    800045fe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004600:	ffffd097          	auipc	ra,0xffffd
    80004604:	408080e7          	jalr	1032(ra) # 80001a08 <myproc>
    80004608:	591c                	lw	a5,48(a0)
    8000460a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	6d8080e7          	jalr	1752(ra) # 80000ce6 <release>
}
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	64a2                	ld	s1,8(sp)
    8000461c:	6902                	ld	s2,0(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004622:	1101                	addi	sp,sp,-32
    80004624:	ec06                	sd	ra,24(sp)
    80004626:	e822                	sd	s0,16(sp)
    80004628:	e426                	sd	s1,8(sp)
    8000462a:	e04a                	sd	s2,0(sp)
    8000462c:	1000                	addi	s0,sp,32
    8000462e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004630:	00850913          	addi	s2,a0,8
    80004634:	854a                	mv	a0,s2
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	5fc080e7          	jalr	1532(ra) # 80000c32 <acquire>
  lk->locked = 0;
    8000463e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004642:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004646:	8526                	mv	a0,s1
    80004648:	ffffe097          	auipc	ra,0xffffe
    8000464c:	ae4080e7          	jalr	-1308(ra) # 8000212c <wakeup>
  release(&lk->lk);
    80004650:	854a                	mv	a0,s2
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	694080e7          	jalr	1684(ra) # 80000ce6 <release>
}
    8000465a:	60e2                	ld	ra,24(sp)
    8000465c:	6442                	ld	s0,16(sp)
    8000465e:	64a2                	ld	s1,8(sp)
    80004660:	6902                	ld	s2,0(sp)
    80004662:	6105                	addi	sp,sp,32
    80004664:	8082                	ret

0000000080004666 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004666:	7179                	addi	sp,sp,-48
    80004668:	f406                	sd	ra,40(sp)
    8000466a:	f022                	sd	s0,32(sp)
    8000466c:	ec26                	sd	s1,24(sp)
    8000466e:	e84a                	sd	s2,16(sp)
    80004670:	e44e                	sd	s3,8(sp)
    80004672:	1800                	addi	s0,sp,48
    80004674:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004676:	00850913          	addi	s2,a0,8
    8000467a:	854a                	mv	a0,s2
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	5b6080e7          	jalr	1462(ra) # 80000c32 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004684:	409c                	lw	a5,0(s1)
    80004686:	ef99                	bnez	a5,800046a4 <holdingsleep+0x3e>
    80004688:	4481                	li	s1,0
  release(&lk->lk);
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	65a080e7          	jalr	1626(ra) # 80000ce6 <release>
  return r;
}
    80004694:	8526                	mv	a0,s1
    80004696:	70a2                	ld	ra,40(sp)
    80004698:	7402                	ld	s0,32(sp)
    8000469a:	64e2                	ld	s1,24(sp)
    8000469c:	6942                	ld	s2,16(sp)
    8000469e:	69a2                	ld	s3,8(sp)
    800046a0:	6145                	addi	sp,sp,48
    800046a2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a4:	0284a983          	lw	s3,40(s1)
    800046a8:	ffffd097          	auipc	ra,0xffffd
    800046ac:	360080e7          	jalr	864(ra) # 80001a08 <myproc>
    800046b0:	5904                	lw	s1,48(a0)
    800046b2:	413484b3          	sub	s1,s1,s3
    800046b6:	0014b493          	seqz	s1,s1
    800046ba:	bfc1                	j	8000468a <holdingsleep+0x24>

00000000800046bc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046bc:	1141                	addi	sp,sp,-16
    800046be:	e406                	sd	ra,8(sp)
    800046c0:	e022                	sd	s0,0(sp)
    800046c2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046c4:	00004597          	auipc	a1,0x4
    800046c8:	01c58593          	addi	a1,a1,28 # 800086e0 <syscalls+0x260>
    800046cc:	0001c517          	auipc	a0,0x1c
    800046d0:	7dc50513          	addi	a0,a0,2012 # 80020ea8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	4ce080e7          	jalr	1230(ra) # 80000ba2 <initlock>
}
    800046dc:	60a2                	ld	ra,8(sp)
    800046de:	6402                	ld	s0,0(sp)
    800046e0:	0141                	addi	sp,sp,16
    800046e2:	8082                	ret

00000000800046e4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046e4:	1101                	addi	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ee:	0001c517          	auipc	a0,0x1c
    800046f2:	7ba50513          	addi	a0,a0,1978 # 80020ea8 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	53c080e7          	jalr	1340(ra) # 80000c32 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046fe:	0001c497          	auipc	s1,0x1c
    80004702:	7c248493          	addi	s1,s1,1986 # 80020ec0 <ftable+0x18>
    80004706:	0001d717          	auipc	a4,0x1d
    8000470a:	75a70713          	addi	a4,a4,1882 # 80021e60 <disk>
    if(f->ref == 0){
    8000470e:	40dc                	lw	a5,4(s1)
    80004710:	cf99                	beqz	a5,8000472e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004712:	02848493          	addi	s1,s1,40
    80004716:	fee49ce3          	bne	s1,a4,8000470e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000471a:	0001c517          	auipc	a0,0x1c
    8000471e:	78e50513          	addi	a0,a0,1934 # 80020ea8 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	5c4080e7          	jalr	1476(ra) # 80000ce6 <release>
  return 0;
    8000472a:	4481                	li	s1,0
    8000472c:	a819                	j	80004742 <filealloc+0x5e>
      f->ref = 1;
    8000472e:	4785                	li	a5,1
    80004730:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004732:	0001c517          	auipc	a0,0x1c
    80004736:	77650513          	addi	a0,a0,1910 # 80020ea8 <ftable>
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	5ac080e7          	jalr	1452(ra) # 80000ce6 <release>
}
    80004742:	8526                	mv	a0,s1
    80004744:	60e2                	ld	ra,24(sp)
    80004746:	6442                	ld	s0,16(sp)
    80004748:	64a2                	ld	s1,8(sp)
    8000474a:	6105                	addi	sp,sp,32
    8000474c:	8082                	ret

000000008000474e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000474e:	1101                	addi	sp,sp,-32
    80004750:	ec06                	sd	ra,24(sp)
    80004752:	e822                	sd	s0,16(sp)
    80004754:	e426                	sd	s1,8(sp)
    80004756:	1000                	addi	s0,sp,32
    80004758:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000475a:	0001c517          	auipc	a0,0x1c
    8000475e:	74e50513          	addi	a0,a0,1870 # 80020ea8 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	4d0080e7          	jalr	1232(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    8000476a:	40dc                	lw	a5,4(s1)
    8000476c:	02f05263          	blez	a5,80004790 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004770:	2785                	addiw	a5,a5,1
    80004772:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004774:	0001c517          	auipc	a0,0x1c
    80004778:	73450513          	addi	a0,a0,1844 # 80020ea8 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	56a080e7          	jalr	1386(ra) # 80000ce6 <release>
  return f;
}
    80004784:	8526                	mv	a0,s1
    80004786:	60e2                	ld	ra,24(sp)
    80004788:	6442                	ld	s0,16(sp)
    8000478a:	64a2                	ld	s1,8(sp)
    8000478c:	6105                	addi	sp,sp,32
    8000478e:	8082                	ret
    panic("filedup");
    80004790:	00004517          	auipc	a0,0x4
    80004794:	f5850513          	addi	a0,a0,-168 # 800086e8 <syscalls+0x268>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>

00000000800047a0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047a0:	7139                	addi	sp,sp,-64
    800047a2:	fc06                	sd	ra,56(sp)
    800047a4:	f822                	sd	s0,48(sp)
    800047a6:	f426                	sd	s1,40(sp)
    800047a8:	f04a                	sd	s2,32(sp)
    800047aa:	ec4e                	sd	s3,24(sp)
    800047ac:	e852                	sd	s4,16(sp)
    800047ae:	e456                	sd	s5,8(sp)
    800047b0:	0080                	addi	s0,sp,64
    800047b2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047b4:	0001c517          	auipc	a0,0x1c
    800047b8:	6f450513          	addi	a0,a0,1780 # 80020ea8 <ftable>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	476080e7          	jalr	1142(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    800047c4:	40dc                	lw	a5,4(s1)
    800047c6:	06f05163          	blez	a5,80004828 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ca:	37fd                	addiw	a5,a5,-1
    800047cc:	0007871b          	sext.w	a4,a5
    800047d0:	c0dc                	sw	a5,4(s1)
    800047d2:	06e04363          	bgtz	a4,80004838 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047d6:	0004a903          	lw	s2,0(s1)
    800047da:	0094ca83          	lbu	s5,9(s1)
    800047de:	0104ba03          	ld	s4,16(s1)
    800047e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ee:	0001c517          	auipc	a0,0x1c
    800047f2:	6ba50513          	addi	a0,a0,1722 # 80020ea8 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4f0080e7          	jalr	1264(ra) # 80000ce6 <release>

  if(ff.type == FD_PIPE){
    800047fe:	4785                	li	a5,1
    80004800:	04f90d63          	beq	s2,a5,8000485a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004804:	3979                	addiw	s2,s2,-2
    80004806:	4785                	li	a5,1
    80004808:	0527e063          	bltu	a5,s2,80004848 <fileclose+0xa8>
    begin_op();
    8000480c:	00000097          	auipc	ra,0x0
    80004810:	ac8080e7          	jalr	-1336(ra) # 800042d4 <begin_op>
    iput(ff.ip);
    80004814:	854e                	mv	a0,s3
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	2b6080e7          	jalr	694(ra) # 80003acc <iput>
    end_op();
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	b36080e7          	jalr	-1226(ra) # 80004354 <end_op>
    80004826:	a00d                	j	80004848 <fileclose+0xa8>
    panic("fileclose");
    80004828:	00004517          	auipc	a0,0x4
    8000482c:	ec850513          	addi	a0,a0,-312 # 800086f0 <syscalls+0x270>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	d0e080e7          	jalr	-754(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004838:	0001c517          	auipc	a0,0x1c
    8000483c:	67050513          	addi	a0,a0,1648 # 80020ea8 <ftable>
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	4a6080e7          	jalr	1190(ra) # 80000ce6 <release>
  }
}
    80004848:	70e2                	ld	ra,56(sp)
    8000484a:	7442                	ld	s0,48(sp)
    8000484c:	74a2                	ld	s1,40(sp)
    8000484e:	7902                	ld	s2,32(sp)
    80004850:	69e2                	ld	s3,24(sp)
    80004852:	6a42                	ld	s4,16(sp)
    80004854:	6aa2                	ld	s5,8(sp)
    80004856:	6121                	addi	sp,sp,64
    80004858:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000485a:	85d6                	mv	a1,s5
    8000485c:	8552                	mv	a0,s4
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	34c080e7          	jalr	844(ra) # 80004baa <pipeclose>
    80004866:	b7cd                	j	80004848 <fileclose+0xa8>

0000000080004868 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004868:	715d                	addi	sp,sp,-80
    8000486a:	e486                	sd	ra,72(sp)
    8000486c:	e0a2                	sd	s0,64(sp)
    8000486e:	fc26                	sd	s1,56(sp)
    80004870:	f84a                	sd	s2,48(sp)
    80004872:	f44e                	sd	s3,40(sp)
    80004874:	0880                	addi	s0,sp,80
    80004876:	84aa                	mv	s1,a0
    80004878:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000487a:	ffffd097          	auipc	ra,0xffffd
    8000487e:	18e080e7          	jalr	398(ra) # 80001a08 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004882:	409c                	lw	a5,0(s1)
    80004884:	37f9                	addiw	a5,a5,-2
    80004886:	4705                	li	a4,1
    80004888:	04f76763          	bltu	a4,a5,800048d6 <filestat+0x6e>
    8000488c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000488e:	6c88                	ld	a0,24(s1)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	082080e7          	jalr	130(ra) # 80003912 <ilock>
    stati(f->ip, &st);
    80004898:	fb840593          	addi	a1,s0,-72
    8000489c:	6c88                	ld	a0,24(s1)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	2fe080e7          	jalr	766(ra) # 80003b9c <stati>
    iunlock(f->ip);
    800048a6:	6c88                	ld	a0,24(s1)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	12c080e7          	jalr	300(ra) # 800039d4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048b0:	46e1                	li	a3,24
    800048b2:	fb840613          	addi	a2,s0,-72
    800048b6:	85ce                	mv	a1,s3
    800048b8:	05093503          	ld	a0,80(s2)
    800048bc:	ffffd097          	auipc	ra,0xffffd
    800048c0:	e08080e7          	jalr	-504(ra) # 800016c4 <copyout>
    800048c4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048c8:	60a6                	ld	ra,72(sp)
    800048ca:	6406                	ld	s0,64(sp)
    800048cc:	74e2                	ld	s1,56(sp)
    800048ce:	7942                	ld	s2,48(sp)
    800048d0:	79a2                	ld	s3,40(sp)
    800048d2:	6161                	addi	sp,sp,80
    800048d4:	8082                	ret
  return -1;
    800048d6:	557d                	li	a0,-1
    800048d8:	bfc5                	j	800048c8 <filestat+0x60>

00000000800048da <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048da:	7179                	addi	sp,sp,-48
    800048dc:	f406                	sd	ra,40(sp)
    800048de:	f022                	sd	s0,32(sp)
    800048e0:	ec26                	sd	s1,24(sp)
    800048e2:	e84a                	sd	s2,16(sp)
    800048e4:	e44e                	sd	s3,8(sp)
    800048e6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048e8:	00854783          	lbu	a5,8(a0)
    800048ec:	c3d5                	beqz	a5,80004990 <fileread+0xb6>
    800048ee:	84aa                	mv	s1,a0
    800048f0:	89ae                	mv	s3,a1
    800048f2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f4:	411c                	lw	a5,0(a0)
    800048f6:	4705                	li	a4,1
    800048f8:	04e78963          	beq	a5,a4,8000494a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048fc:	470d                	li	a4,3
    800048fe:	04e78d63          	beq	a5,a4,80004958 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004902:	4709                	li	a4,2
    80004904:	06e79e63          	bne	a5,a4,80004980 <fileread+0xa6>
    ilock(f->ip);
    80004908:	6d08                	ld	a0,24(a0)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	008080e7          	jalr	8(ra) # 80003912 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004912:	874a                	mv	a4,s2
    80004914:	5094                	lw	a3,32(s1)
    80004916:	864e                	mv	a2,s3
    80004918:	4585                	li	a1,1
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	2aa080e7          	jalr	682(ra) # 80003bc6 <readi>
    80004924:	892a                	mv	s2,a0
    80004926:	00a05563          	blez	a0,80004930 <fileread+0x56>
      f->off += r;
    8000492a:	509c                	lw	a5,32(s1)
    8000492c:	9fa9                	addw	a5,a5,a0
    8000492e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004930:	6c88                	ld	a0,24(s1)
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	0a2080e7          	jalr	162(ra) # 800039d4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000493a:	854a                	mv	a0,s2
    8000493c:	70a2                	ld	ra,40(sp)
    8000493e:	7402                	ld	s0,32(sp)
    80004940:	64e2                	ld	s1,24(sp)
    80004942:	6942                	ld	s2,16(sp)
    80004944:	69a2                	ld	s3,8(sp)
    80004946:	6145                	addi	sp,sp,48
    80004948:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000494a:	6908                	ld	a0,16(a0)
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	3c6080e7          	jalr	966(ra) # 80004d12 <piperead>
    80004954:	892a                	mv	s2,a0
    80004956:	b7d5                	j	8000493a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004958:	02451783          	lh	a5,36(a0)
    8000495c:	03079693          	slli	a3,a5,0x30
    80004960:	92c1                	srli	a3,a3,0x30
    80004962:	4725                	li	a4,9
    80004964:	02d76863          	bltu	a4,a3,80004994 <fileread+0xba>
    80004968:	0792                	slli	a5,a5,0x4
    8000496a:	0001c717          	auipc	a4,0x1c
    8000496e:	49e70713          	addi	a4,a4,1182 # 80020e08 <devsw>
    80004972:	97ba                	add	a5,a5,a4
    80004974:	639c                	ld	a5,0(a5)
    80004976:	c38d                	beqz	a5,80004998 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004978:	4505                	li	a0,1
    8000497a:	9782                	jalr	a5
    8000497c:	892a                	mv	s2,a0
    8000497e:	bf75                	j	8000493a <fileread+0x60>
    panic("fileread");
    80004980:	00004517          	auipc	a0,0x4
    80004984:	d8050513          	addi	a0,a0,-640 # 80008700 <syscalls+0x280>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>
    return -1;
    80004990:	597d                	li	s2,-1
    80004992:	b765                	j	8000493a <fileread+0x60>
      return -1;
    80004994:	597d                	li	s2,-1
    80004996:	b755                	j	8000493a <fileread+0x60>
    80004998:	597d                	li	s2,-1
    8000499a:	b745                	j	8000493a <fileread+0x60>

000000008000499c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000499c:	715d                	addi	sp,sp,-80
    8000499e:	e486                	sd	ra,72(sp)
    800049a0:	e0a2                	sd	s0,64(sp)
    800049a2:	fc26                	sd	s1,56(sp)
    800049a4:	f84a                	sd	s2,48(sp)
    800049a6:	f44e                	sd	s3,40(sp)
    800049a8:	f052                	sd	s4,32(sp)
    800049aa:	ec56                	sd	s5,24(sp)
    800049ac:	e85a                	sd	s6,16(sp)
    800049ae:	e45e                	sd	s7,8(sp)
    800049b0:	e062                	sd	s8,0(sp)
    800049b2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049b4:	00954783          	lbu	a5,9(a0)
    800049b8:	10078663          	beqz	a5,80004ac4 <filewrite+0x128>
    800049bc:	892a                	mv	s2,a0
    800049be:	8aae                	mv	s5,a1
    800049c0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049c2:	411c                	lw	a5,0(a0)
    800049c4:	4705                	li	a4,1
    800049c6:	02e78263          	beq	a5,a4,800049ea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ca:	470d                	li	a4,3
    800049cc:	02e78663          	beq	a5,a4,800049f8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049d0:	4709                	li	a4,2
    800049d2:	0ee79163          	bne	a5,a4,80004ab4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049d6:	0ac05d63          	blez	a2,80004a90 <filewrite+0xf4>
    int i = 0;
    800049da:	4981                	li	s3,0
    800049dc:	6b05                	lui	s6,0x1
    800049de:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049e2:	6b85                	lui	s7,0x1
    800049e4:	c00b8b9b          	addiw	s7,s7,-1024
    800049e8:	a861                	j	80004a80 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049ea:	6908                	ld	a0,16(a0)
    800049ec:	00000097          	auipc	ra,0x0
    800049f0:	22e080e7          	jalr	558(ra) # 80004c1a <pipewrite>
    800049f4:	8a2a                	mv	s4,a0
    800049f6:	a045                	j	80004a96 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049f8:	02451783          	lh	a5,36(a0)
    800049fc:	03079693          	slli	a3,a5,0x30
    80004a00:	92c1                	srli	a3,a3,0x30
    80004a02:	4725                	li	a4,9
    80004a04:	0cd76263          	bltu	a4,a3,80004ac8 <filewrite+0x12c>
    80004a08:	0792                	slli	a5,a5,0x4
    80004a0a:	0001c717          	auipc	a4,0x1c
    80004a0e:	3fe70713          	addi	a4,a4,1022 # 80020e08 <devsw>
    80004a12:	97ba                	add	a5,a5,a4
    80004a14:	679c                	ld	a5,8(a5)
    80004a16:	cbdd                	beqz	a5,80004acc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a18:	4505                	li	a0,1
    80004a1a:	9782                	jalr	a5
    80004a1c:	8a2a                	mv	s4,a0
    80004a1e:	a8a5                	j	80004a96 <filewrite+0xfa>
    80004a20:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	8b0080e7          	jalr	-1872(ra) # 800042d4 <begin_op>
      ilock(f->ip);
    80004a2c:	01893503          	ld	a0,24(s2)
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	ee2080e7          	jalr	-286(ra) # 80003912 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a38:	8762                	mv	a4,s8
    80004a3a:	02092683          	lw	a3,32(s2)
    80004a3e:	01598633          	add	a2,s3,s5
    80004a42:	4585                	li	a1,1
    80004a44:	01893503          	ld	a0,24(s2)
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	276080e7          	jalr	630(ra) # 80003cbe <writei>
    80004a50:	84aa                	mv	s1,a0
    80004a52:	00a05763          	blez	a0,80004a60 <filewrite+0xc4>
        f->off += r;
    80004a56:	02092783          	lw	a5,32(s2)
    80004a5a:	9fa9                	addw	a5,a5,a0
    80004a5c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a60:	01893503          	ld	a0,24(s2)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	f70080e7          	jalr	-144(ra) # 800039d4 <iunlock>
      end_op();
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	8e8080e7          	jalr	-1816(ra) # 80004354 <end_op>

      if(r != n1){
    80004a74:	009c1f63          	bne	s8,s1,80004a92 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a78:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a7c:	0149db63          	bge	s3,s4,80004a92 <filewrite+0xf6>
      int n1 = n - i;
    80004a80:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a84:	84be                	mv	s1,a5
    80004a86:	2781                	sext.w	a5,a5
    80004a88:	f8fb5ce3          	bge	s6,a5,80004a20 <filewrite+0x84>
    80004a8c:	84de                	mv	s1,s7
    80004a8e:	bf49                	j	80004a20 <filewrite+0x84>
    int i = 0;
    80004a90:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a92:	013a1f63          	bne	s4,s3,80004ab0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a96:	8552                	mv	a0,s4
    80004a98:	60a6                	ld	ra,72(sp)
    80004a9a:	6406                	ld	s0,64(sp)
    80004a9c:	74e2                	ld	s1,56(sp)
    80004a9e:	7942                	ld	s2,48(sp)
    80004aa0:	79a2                	ld	s3,40(sp)
    80004aa2:	7a02                	ld	s4,32(sp)
    80004aa4:	6ae2                	ld	s5,24(sp)
    80004aa6:	6b42                	ld	s6,16(sp)
    80004aa8:	6ba2                	ld	s7,8(sp)
    80004aaa:	6c02                	ld	s8,0(sp)
    80004aac:	6161                	addi	sp,sp,80
    80004aae:	8082                	ret
    ret = (i == n ? n : -1);
    80004ab0:	5a7d                	li	s4,-1
    80004ab2:	b7d5                	j	80004a96 <filewrite+0xfa>
    panic("filewrite");
    80004ab4:	00004517          	auipc	a0,0x4
    80004ab8:	c5c50513          	addi	a0,a0,-932 # 80008710 <syscalls+0x290>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	a82080e7          	jalr	-1406(ra) # 8000053e <panic>
    return -1;
    80004ac4:	5a7d                	li	s4,-1
    80004ac6:	bfc1                	j	80004a96 <filewrite+0xfa>
      return -1;
    80004ac8:	5a7d                	li	s4,-1
    80004aca:	b7f1                	j	80004a96 <filewrite+0xfa>
    80004acc:	5a7d                	li	s4,-1
    80004ace:	b7e1                	j	80004a96 <filewrite+0xfa>

0000000080004ad0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ad0:	7179                	addi	sp,sp,-48
    80004ad2:	f406                	sd	ra,40(sp)
    80004ad4:	f022                	sd	s0,32(sp)
    80004ad6:	ec26                	sd	s1,24(sp)
    80004ad8:	e84a                	sd	s2,16(sp)
    80004ada:	e44e                	sd	s3,8(sp)
    80004adc:	e052                	sd	s4,0(sp)
    80004ade:	1800                	addi	s0,sp,48
    80004ae0:	84aa                	mv	s1,a0
    80004ae2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ae4:	0005b023          	sd	zero,0(a1)
    80004ae8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	bf8080e7          	jalr	-1032(ra) # 800046e4 <filealloc>
    80004af4:	e088                	sd	a0,0(s1)
    80004af6:	c551                	beqz	a0,80004b82 <pipealloc+0xb2>
    80004af8:	00000097          	auipc	ra,0x0
    80004afc:	bec080e7          	jalr	-1044(ra) # 800046e4 <filealloc>
    80004b00:	00aa3023          	sd	a0,0(s4)
    80004b04:	c92d                	beqz	a0,80004b76 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	fe0080e7          	jalr	-32(ra) # 80000ae6 <kalloc>
    80004b0e:	892a                	mv	s2,a0
    80004b10:	c125                	beqz	a0,80004b70 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b12:	4985                	li	s3,1
    80004b14:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b18:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b1c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b20:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b24:	00004597          	auipc	a1,0x4
    80004b28:	bfc58593          	addi	a1,a1,-1028 # 80008720 <syscalls+0x2a0>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	076080e7          	jalr	118(ra) # 80000ba2 <initlock>
  (*f0)->type = FD_PIPE;
    80004b34:	609c                	ld	a5,0(s1)
    80004b36:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b3a:	609c                	ld	a5,0(s1)
    80004b3c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b40:	609c                	ld	a5,0(s1)
    80004b42:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b46:	609c                	ld	a5,0(s1)
    80004b48:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b4c:	000a3783          	ld	a5,0(s4)
    80004b50:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b54:	000a3783          	ld	a5,0(s4)
    80004b58:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b5c:	000a3783          	ld	a5,0(s4)
    80004b60:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b64:	000a3783          	ld	a5,0(s4)
    80004b68:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b6c:	4501                	li	a0,0
    80004b6e:	a025                	j	80004b96 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b70:	6088                	ld	a0,0(s1)
    80004b72:	e501                	bnez	a0,80004b7a <pipealloc+0xaa>
    80004b74:	a039                	j	80004b82 <pipealloc+0xb2>
    80004b76:	6088                	ld	a0,0(s1)
    80004b78:	c51d                	beqz	a0,80004ba6 <pipealloc+0xd6>
    fileclose(*f0);
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	c26080e7          	jalr	-986(ra) # 800047a0 <fileclose>
  if(*f1)
    80004b82:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b86:	557d                	li	a0,-1
  if(*f1)
    80004b88:	c799                	beqz	a5,80004b96 <pipealloc+0xc6>
    fileclose(*f1);
    80004b8a:	853e                	mv	a0,a5
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	c14080e7          	jalr	-1004(ra) # 800047a0 <fileclose>
  return -1;
    80004b94:	557d                	li	a0,-1
}
    80004b96:	70a2                	ld	ra,40(sp)
    80004b98:	7402                	ld	s0,32(sp)
    80004b9a:	64e2                	ld	s1,24(sp)
    80004b9c:	6942                	ld	s2,16(sp)
    80004b9e:	69a2                	ld	s3,8(sp)
    80004ba0:	6a02                	ld	s4,0(sp)
    80004ba2:	6145                	addi	sp,sp,48
    80004ba4:	8082                	ret
  return -1;
    80004ba6:	557d                	li	a0,-1
    80004ba8:	b7fd                	j	80004b96 <pipealloc+0xc6>

0000000080004baa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004baa:	1101                	addi	sp,sp,-32
    80004bac:	ec06                	sd	ra,24(sp)
    80004bae:	e822                	sd	s0,16(sp)
    80004bb0:	e426                	sd	s1,8(sp)
    80004bb2:	e04a                	sd	s2,0(sp)
    80004bb4:	1000                	addi	s0,sp,32
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	078080e7          	jalr	120(ra) # 80000c32 <acquire>
  if(writable){
    80004bc2:	02090d63          	beqz	s2,80004bfc <pipeclose+0x52>
    pi->writeopen = 0;
    80004bc6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bca:	21848513          	addi	a0,s1,536
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	55e080e7          	jalr	1374(ra) # 8000212c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bd6:	2204b783          	ld	a5,544(s1)
    80004bda:	eb95                	bnez	a5,80004c0e <pipeclose+0x64>
    release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	108080e7          	jalr	264(ra) # 80000ce6 <release>
    kfree((char*)pi);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	e02080e7          	jalr	-510(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004bf0:	60e2                	ld	ra,24(sp)
    80004bf2:	6442                	ld	s0,16(sp)
    80004bf4:	64a2                	ld	s1,8(sp)
    80004bf6:	6902                	ld	s2,0(sp)
    80004bf8:	6105                	addi	sp,sp,32
    80004bfa:	8082                	ret
    pi->readopen = 0;
    80004bfc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c00:	21c48513          	addi	a0,s1,540
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	528080e7          	jalr	1320(ra) # 8000212c <wakeup>
    80004c0c:	b7e9                	j	80004bd6 <pipeclose+0x2c>
    release(&pi->lock);
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	0d6080e7          	jalr	214(ra) # 80000ce6 <release>
}
    80004c18:	bfe1                	j	80004bf0 <pipeclose+0x46>

0000000080004c1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c1a:	711d                	addi	sp,sp,-96
    80004c1c:	ec86                	sd	ra,88(sp)
    80004c1e:	e8a2                	sd	s0,80(sp)
    80004c20:	e4a6                	sd	s1,72(sp)
    80004c22:	e0ca                	sd	s2,64(sp)
    80004c24:	fc4e                	sd	s3,56(sp)
    80004c26:	f852                	sd	s4,48(sp)
    80004c28:	f456                	sd	s5,40(sp)
    80004c2a:	f05a                	sd	s6,32(sp)
    80004c2c:	ec5e                	sd	s7,24(sp)
    80004c2e:	e862                	sd	s8,16(sp)
    80004c30:	1080                	addi	s0,sp,96
    80004c32:	84aa                	mv	s1,a0
    80004c34:	8aae                	mv	s5,a1
    80004c36:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <myproc>
    80004c40:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	fee080e7          	jalr	-18(ra) # 80000c32 <acquire>
  while(i < n){
    80004c4c:	0b405663          	blez	s4,80004cf8 <pipewrite+0xde>
  int i = 0;
    80004c50:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c52:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c54:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c58:	21c48b93          	addi	s7,s1,540
    80004c5c:	a089                	j	80004c9e <pipewrite+0x84>
      release(&pi->lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	086080e7          	jalr	134(ra) # 80000ce6 <release>
      return -1;
    80004c68:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c6a:	854a                	mv	a0,s2
    80004c6c:	60e6                	ld	ra,88(sp)
    80004c6e:	6446                	ld	s0,80(sp)
    80004c70:	64a6                	ld	s1,72(sp)
    80004c72:	6906                	ld	s2,64(sp)
    80004c74:	79e2                	ld	s3,56(sp)
    80004c76:	7a42                	ld	s4,48(sp)
    80004c78:	7aa2                	ld	s5,40(sp)
    80004c7a:	7b02                	ld	s6,32(sp)
    80004c7c:	6be2                	ld	s7,24(sp)
    80004c7e:	6c42                	ld	s8,16(sp)
    80004c80:	6125                	addi	sp,sp,96
    80004c82:	8082                	ret
      wakeup(&pi->nread);
    80004c84:	8562                	mv	a0,s8
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	4a6080e7          	jalr	1190(ra) # 8000212c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c8e:	85a6                	mv	a1,s1
    80004c90:	855e                	mv	a0,s7
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	436080e7          	jalr	1078(ra) # 800020c8 <sleep>
  while(i < n){
    80004c9a:	07495063          	bge	s2,s4,80004cfa <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c9e:	2204a783          	lw	a5,544(s1)
    80004ca2:	dfd5                	beqz	a5,80004c5e <pipewrite+0x44>
    80004ca4:	854e                	mv	a0,s3
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	6ca080e7          	jalr	1738(ra) # 80002370 <killed>
    80004cae:	f945                	bnez	a0,80004c5e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cb0:	2184a783          	lw	a5,536(s1)
    80004cb4:	21c4a703          	lw	a4,540(s1)
    80004cb8:	2007879b          	addiw	a5,a5,512
    80004cbc:	fcf704e3          	beq	a4,a5,80004c84 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc0:	4685                	li	a3,1
    80004cc2:	01590633          	add	a2,s2,s5
    80004cc6:	faf40593          	addi	a1,s0,-81
    80004cca:	0509b503          	ld	a0,80(s3)
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	a82080e7          	jalr	-1406(ra) # 80001750 <copyin>
    80004cd6:	03650263          	beq	a0,s6,80004cfa <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cda:	21c4a783          	lw	a5,540(s1)
    80004cde:	0017871b          	addiw	a4,a5,1
    80004ce2:	20e4ae23          	sw	a4,540(s1)
    80004ce6:	1ff7f793          	andi	a5,a5,511
    80004cea:	97a6                	add	a5,a5,s1
    80004cec:	faf44703          	lbu	a4,-81(s0)
    80004cf0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cf4:	2905                	addiw	s2,s2,1
    80004cf6:	b755                	j	80004c9a <pipewrite+0x80>
  int i = 0;
    80004cf8:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cfa:	21848513          	addi	a0,s1,536
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	42e080e7          	jalr	1070(ra) # 8000212c <wakeup>
  release(&pi->lock);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	fde080e7          	jalr	-34(ra) # 80000ce6 <release>
  return i;
    80004d10:	bfa9                	j	80004c6a <pipewrite+0x50>

0000000080004d12 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d12:	715d                	addi	sp,sp,-80
    80004d14:	e486                	sd	ra,72(sp)
    80004d16:	e0a2                	sd	s0,64(sp)
    80004d18:	fc26                	sd	s1,56(sp)
    80004d1a:	f84a                	sd	s2,48(sp)
    80004d1c:	f44e                	sd	s3,40(sp)
    80004d1e:	f052                	sd	s4,32(sp)
    80004d20:	ec56                	sd	s5,24(sp)
    80004d22:	e85a                	sd	s6,16(sp)
    80004d24:	0880                	addi	s0,sp,80
    80004d26:	84aa                	mv	s1,a0
    80004d28:	892e                	mv	s2,a1
    80004d2a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	cdc080e7          	jalr	-804(ra) # 80001a08 <myproc>
    80004d34:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	efa080e7          	jalr	-262(ra) # 80000c32 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d40:	2184a703          	lw	a4,536(s1)
    80004d44:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d48:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4c:	02f71763          	bne	a4,a5,80004d7a <piperead+0x68>
    80004d50:	2244a783          	lw	a5,548(s1)
    80004d54:	c39d                	beqz	a5,80004d7a <piperead+0x68>
    if(killed(pr)){
    80004d56:	8552                	mv	a0,s4
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	618080e7          	jalr	1560(ra) # 80002370 <killed>
    80004d60:	e941                	bnez	a0,80004df0 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d62:	85a6                	mv	a1,s1
    80004d64:	854e                	mv	a0,s3
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	362080e7          	jalr	866(ra) # 800020c8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d6e:	2184a703          	lw	a4,536(s1)
    80004d72:	21c4a783          	lw	a5,540(s1)
    80004d76:	fcf70de3          	beq	a4,a5,80004d50 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7e:	05505363          	blez	s5,80004dc4 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d82:	2184a783          	lw	a5,536(s1)
    80004d86:	21c4a703          	lw	a4,540(s1)
    80004d8a:	02f70d63          	beq	a4,a5,80004dc4 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d8e:	0017871b          	addiw	a4,a5,1
    80004d92:	20e4ac23          	sw	a4,536(s1)
    80004d96:	1ff7f793          	andi	a5,a5,511
    80004d9a:	97a6                	add	a5,a5,s1
    80004d9c:	0187c783          	lbu	a5,24(a5)
    80004da0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da4:	4685                	li	a3,1
    80004da6:	fbf40613          	addi	a2,s0,-65
    80004daa:	85ca                	mv	a1,s2
    80004dac:	050a3503          	ld	a0,80(s4)
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	914080e7          	jalr	-1772(ra) # 800016c4 <copyout>
    80004db8:	01650663          	beq	a0,s6,80004dc4 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dbc:	2985                	addiw	s3,s3,1
    80004dbe:	0905                	addi	s2,s2,1
    80004dc0:	fd3a91e3          	bne	s5,s3,80004d82 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dc4:	21c48513          	addi	a0,s1,540
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	364080e7          	jalr	868(ra) # 8000212c <wakeup>
  release(&pi->lock);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	f14080e7          	jalr	-236(ra) # 80000ce6 <release>
  return i;
}
    80004dda:	854e                	mv	a0,s3
    80004ddc:	60a6                	ld	ra,72(sp)
    80004dde:	6406                	ld	s0,64(sp)
    80004de0:	74e2                	ld	s1,56(sp)
    80004de2:	7942                	ld	s2,48(sp)
    80004de4:	79a2                	ld	s3,40(sp)
    80004de6:	7a02                	ld	s4,32(sp)
    80004de8:	6ae2                	ld	s5,24(sp)
    80004dea:	6b42                	ld	s6,16(sp)
    80004dec:	6161                	addi	sp,sp,80
    80004dee:	8082                	ret
      release(&pi->lock);
    80004df0:	8526                	mv	a0,s1
    80004df2:	ffffc097          	auipc	ra,0xffffc
    80004df6:	ef4080e7          	jalr	-268(ra) # 80000ce6 <release>
      return -1;
    80004dfa:	59fd                	li	s3,-1
    80004dfc:	bff9                	j	80004dda <piperead+0xc8>

0000000080004dfe <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dfe:	1141                	addi	sp,sp,-16
    80004e00:	e422                	sd	s0,8(sp)
    80004e02:	0800                	addi	s0,sp,16
    80004e04:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e06:	8905                	andi	a0,a0,1
    80004e08:	c111                	beqz	a0,80004e0c <flags2perm+0xe>
      perm = PTE_X;
    80004e0a:	4521                	li	a0,8
    if(flags & 0x2)
    80004e0c:	8b89                	andi	a5,a5,2
    80004e0e:	c399                	beqz	a5,80004e14 <flags2perm+0x16>
      perm |= PTE_W;
    80004e10:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e14:	6422                	ld	s0,8(sp)
    80004e16:	0141                	addi	sp,sp,16
    80004e18:	8082                	ret

0000000080004e1a <exec>:

int
exec(char *path, char **argv)
{
    80004e1a:	de010113          	addi	sp,sp,-544
    80004e1e:	20113c23          	sd	ra,536(sp)
    80004e22:	20813823          	sd	s0,528(sp)
    80004e26:	20913423          	sd	s1,520(sp)
    80004e2a:	21213023          	sd	s2,512(sp)
    80004e2e:	ffce                	sd	s3,504(sp)
    80004e30:	fbd2                	sd	s4,496(sp)
    80004e32:	f7d6                	sd	s5,488(sp)
    80004e34:	f3da                	sd	s6,480(sp)
    80004e36:	efde                	sd	s7,472(sp)
    80004e38:	ebe2                	sd	s8,464(sp)
    80004e3a:	e7e6                	sd	s9,456(sp)
    80004e3c:	e3ea                	sd	s10,448(sp)
    80004e3e:	ff6e                	sd	s11,440(sp)
    80004e40:	1400                	addi	s0,sp,544
    80004e42:	892a                	mv	s2,a0
    80004e44:	dea43423          	sd	a0,-536(s0)
    80004e48:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	bbc080e7          	jalr	-1092(ra) # 80001a08 <myproc>
    80004e54:	84aa                	mv	s1,a0

  begin_op();
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	47e080e7          	jalr	1150(ra) # 800042d4 <begin_op>

  if((ip = namei(path)) == 0){
    80004e5e:	854a                	mv	a0,s2
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	258080e7          	jalr	600(ra) # 800040b8 <namei>
    80004e68:	c93d                	beqz	a0,80004ede <exec+0xc4>
    80004e6a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	aa6080e7          	jalr	-1370(ra) # 80003912 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e74:	04000713          	li	a4,64
    80004e78:	4681                	li	a3,0
    80004e7a:	e5040613          	addi	a2,s0,-432
    80004e7e:	4581                	li	a1,0
    80004e80:	8556                	mv	a0,s5
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	d44080e7          	jalr	-700(ra) # 80003bc6 <readi>
    80004e8a:	04000793          	li	a5,64
    80004e8e:	00f51a63          	bne	a0,a5,80004ea2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e92:	e5042703          	lw	a4,-432(s0)
    80004e96:	464c47b7          	lui	a5,0x464c4
    80004e9a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e9e:	04f70663          	beq	a4,a5,80004eea <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ea2:	8556                	mv	a0,s5
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	cd0080e7          	jalr	-816(ra) # 80003b74 <iunlockput>
    end_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	4a8080e7          	jalr	1192(ra) # 80004354 <end_op>
  }
  return -1;
    80004eb4:	557d                	li	a0,-1
}
    80004eb6:	21813083          	ld	ra,536(sp)
    80004eba:	21013403          	ld	s0,528(sp)
    80004ebe:	20813483          	ld	s1,520(sp)
    80004ec2:	20013903          	ld	s2,512(sp)
    80004ec6:	79fe                	ld	s3,504(sp)
    80004ec8:	7a5e                	ld	s4,496(sp)
    80004eca:	7abe                	ld	s5,488(sp)
    80004ecc:	7b1e                	ld	s6,480(sp)
    80004ece:	6bfe                	ld	s7,472(sp)
    80004ed0:	6c5e                	ld	s8,464(sp)
    80004ed2:	6cbe                	ld	s9,456(sp)
    80004ed4:	6d1e                	ld	s10,448(sp)
    80004ed6:	7dfa                	ld	s11,440(sp)
    80004ed8:	22010113          	addi	sp,sp,544
    80004edc:	8082                	ret
    end_op();
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	476080e7          	jalr	1142(ra) # 80004354 <end_op>
    return -1;
    80004ee6:	557d                	li	a0,-1
    80004ee8:	b7f9                	j	80004eb6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eea:	8526                	mv	a0,s1
    80004eec:	ffffd097          	auipc	ra,0xffffd
    80004ef0:	be0080e7          	jalr	-1056(ra) # 80001acc <proc_pagetable>
    80004ef4:	8b2a                	mv	s6,a0
    80004ef6:	d555                	beqz	a0,80004ea2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef8:	e7042783          	lw	a5,-400(s0)
    80004efc:	e8845703          	lhu	a4,-376(s0)
    80004f00:	c735                	beqz	a4,80004f6c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f02:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f04:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f08:	6a05                	lui	s4,0x1
    80004f0a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f0e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f12:	6d85                	lui	s11,0x1
    80004f14:	7d7d                	lui	s10,0xfffff
    80004f16:	a481                	j	80005156 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f18:	00004517          	auipc	a0,0x4
    80004f1c:	81050513          	addi	a0,a0,-2032 # 80008728 <syscalls+0x2a8>
    80004f20:	ffffb097          	auipc	ra,0xffffb
    80004f24:	61e080e7          	jalr	1566(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f28:	874a                	mv	a4,s2
    80004f2a:	009c86bb          	addw	a3,s9,s1
    80004f2e:	4581                	li	a1,0
    80004f30:	8556                	mv	a0,s5
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	c94080e7          	jalr	-876(ra) # 80003bc6 <readi>
    80004f3a:	2501                	sext.w	a0,a0
    80004f3c:	1aa91a63          	bne	s2,a0,800050f0 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f40:	009d84bb          	addw	s1,s11,s1
    80004f44:	013d09bb          	addw	s3,s10,s3
    80004f48:	1f74f763          	bgeu	s1,s7,80005136 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004f4c:	02049593          	slli	a1,s1,0x20
    80004f50:	9181                	srli	a1,a1,0x20
    80004f52:	95e2                	add	a1,a1,s8
    80004f54:	855a                	mv	a0,s6
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	162080e7          	jalr	354(ra) # 800010b8 <walkaddr>
    80004f5e:	862a                	mv	a2,a0
    if(pa == 0)
    80004f60:	dd45                	beqz	a0,80004f18 <exec+0xfe>
      n = PGSIZE;
    80004f62:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f64:	fd49f2e3          	bgeu	s3,s4,80004f28 <exec+0x10e>
      n = sz - i;
    80004f68:	894e                	mv	s2,s3
    80004f6a:	bf7d                	j	80004f28 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f6c:	4901                	li	s2,0
  iunlockput(ip);
    80004f6e:	8556                	mv	a0,s5
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	c04080e7          	jalr	-1020(ra) # 80003b74 <iunlockput>
  end_op();
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	3dc080e7          	jalr	988(ra) # 80004354 <end_op>
  p = myproc();
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	a88080e7          	jalr	-1400(ra) # 80001a08 <myproc>
    80004f88:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f8a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f8e:	6785                	lui	a5,0x1
    80004f90:	17fd                	addi	a5,a5,-1
    80004f92:	993e                	add	s2,s2,a5
    80004f94:	77fd                	lui	a5,0xfffff
    80004f96:	00f977b3          	and	a5,s2,a5
    80004f9a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f9e:	4691                	li	a3,4
    80004fa0:	6609                	lui	a2,0x2
    80004fa2:	963e                	add	a2,a2,a5
    80004fa4:	85be                	mv	a1,a5
    80004fa6:	855a                	mv	a0,s6
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	4c4080e7          	jalr	1220(ra) # 8000146c <uvmalloc>
    80004fb0:	8c2a                	mv	s8,a0
  ip = 0;
    80004fb2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fb4:	12050e63          	beqz	a0,800050f0 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fb8:	75f9                	lui	a1,0xffffe
    80004fba:	95aa                	add	a1,a1,a0
    80004fbc:	855a                	mv	a0,s6
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	6d4080e7          	jalr	1748(ra) # 80001692 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fc6:	7afd                	lui	s5,0xfffff
    80004fc8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	df043783          	ld	a5,-528(s0)
    80004fce:	6388                	ld	a0,0(a5)
    80004fd0:	c925                	beqz	a0,80005040 <exec+0x226>
    80004fd2:	e9040993          	addi	s3,s0,-368
    80004fd6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fda:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fdc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	ecc080e7          	jalr	-308(ra) # 80000eaa <strlen>
    80004fe6:	0015079b          	addiw	a5,a0,1
    80004fea:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fee:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ff2:	13596663          	bltu	s2,s5,8000511e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ff6:	df043d83          	ld	s11,-528(s0)
    80004ffa:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ffe:	8552                	mv	a0,s4
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	eaa080e7          	jalr	-342(ra) # 80000eaa <strlen>
    80005008:	0015069b          	addiw	a3,a0,1
    8000500c:	8652                	mv	a2,s4
    8000500e:	85ca                	mv	a1,s2
    80005010:	855a                	mv	a0,s6
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	6b2080e7          	jalr	1714(ra) # 800016c4 <copyout>
    8000501a:	10054663          	bltz	a0,80005126 <exec+0x30c>
    ustack[argc] = sp;
    8000501e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005022:	0485                	addi	s1,s1,1
    80005024:	008d8793          	addi	a5,s11,8
    80005028:	def43823          	sd	a5,-528(s0)
    8000502c:	008db503          	ld	a0,8(s11)
    80005030:	c911                	beqz	a0,80005044 <exec+0x22a>
    if(argc >= MAXARG)
    80005032:	09a1                	addi	s3,s3,8
    80005034:	fb3c95e3          	bne	s9,s3,80004fde <exec+0x1c4>
  sz = sz1;
    80005038:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000503c:	4a81                	li	s5,0
    8000503e:	a84d                	j	800050f0 <exec+0x2d6>
  sp = sz;
    80005040:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005042:	4481                	li	s1,0
  ustack[argc] = 0;
    80005044:	00349793          	slli	a5,s1,0x3
    80005048:	f9040713          	addi	a4,s0,-112
    8000504c:	97ba                	add	a5,a5,a4
    8000504e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcf60>
  sp -= (argc+1) * sizeof(uint64);
    80005052:	00148693          	addi	a3,s1,1
    80005056:	068e                	slli	a3,a3,0x3
    80005058:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000505c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005060:	01597663          	bgeu	s2,s5,8000506c <exec+0x252>
  sz = sz1;
    80005064:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005068:	4a81                	li	s5,0
    8000506a:	a059                	j	800050f0 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000506c:	e9040613          	addi	a2,s0,-368
    80005070:	85ca                	mv	a1,s2
    80005072:	855a                	mv	a0,s6
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	650080e7          	jalr	1616(ra) # 800016c4 <copyout>
    8000507c:	0a054963          	bltz	a0,8000512e <exec+0x314>
  p->trapframe->a1 = sp;
    80005080:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005084:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005088:	de843783          	ld	a5,-536(s0)
    8000508c:	0007c703          	lbu	a4,0(a5)
    80005090:	cf11                	beqz	a4,800050ac <exec+0x292>
    80005092:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005094:	02f00693          	li	a3,47
    80005098:	a039                	j	800050a6 <exec+0x28c>
      last = s+1;
    8000509a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000509e:	0785                	addi	a5,a5,1
    800050a0:	fff7c703          	lbu	a4,-1(a5)
    800050a4:	c701                	beqz	a4,800050ac <exec+0x292>
    if(*s == '/')
    800050a6:	fed71ce3          	bne	a4,a3,8000509e <exec+0x284>
    800050aa:	bfc5                	j	8000509a <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800050ac:	4641                	li	a2,16
    800050ae:	de843583          	ld	a1,-536(s0)
    800050b2:	158b8513          	addi	a0,s7,344
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	dc2080e7          	jalr	-574(ra) # 80000e78 <safestrcpy>
  oldpagetable = p->pagetable;
    800050be:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050c2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050c6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050ca:	058bb783          	ld	a5,88(s7)
    800050ce:	e6843703          	ld	a4,-408(s0)
    800050d2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050d4:	058bb783          	ld	a5,88(s7)
    800050d8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050dc:	85ea                	mv	a1,s10
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	a8a080e7          	jalr	-1398(ra) # 80001b68 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050e6:	0004851b          	sext.w	a0,s1
    800050ea:	b3f1                	j	80004eb6 <exec+0x9c>
    800050ec:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050f0:	df843583          	ld	a1,-520(s0)
    800050f4:	855a                	mv	a0,s6
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	a72080e7          	jalr	-1422(ra) # 80001b68 <proc_freepagetable>
  if(ip){
    800050fe:	da0a92e3          	bnez	s5,80004ea2 <exec+0x88>
  return -1;
    80005102:	557d                	li	a0,-1
    80005104:	bb4d                	j	80004eb6 <exec+0x9c>
    80005106:	df243c23          	sd	s2,-520(s0)
    8000510a:	b7dd                	j	800050f0 <exec+0x2d6>
    8000510c:	df243c23          	sd	s2,-520(s0)
    80005110:	b7c5                	j	800050f0 <exec+0x2d6>
    80005112:	df243c23          	sd	s2,-520(s0)
    80005116:	bfe9                	j	800050f0 <exec+0x2d6>
    80005118:	df243c23          	sd	s2,-520(s0)
    8000511c:	bfd1                	j	800050f0 <exec+0x2d6>
  sz = sz1;
    8000511e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005122:	4a81                	li	s5,0
    80005124:	b7f1                	j	800050f0 <exec+0x2d6>
  sz = sz1;
    80005126:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000512a:	4a81                	li	s5,0
    8000512c:	b7d1                	j	800050f0 <exec+0x2d6>
  sz = sz1;
    8000512e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005132:	4a81                	li	s5,0
    80005134:	bf75                	j	800050f0 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005136:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000513a:	e0843783          	ld	a5,-504(s0)
    8000513e:	0017869b          	addiw	a3,a5,1
    80005142:	e0d43423          	sd	a3,-504(s0)
    80005146:	e0043783          	ld	a5,-512(s0)
    8000514a:	0387879b          	addiw	a5,a5,56
    8000514e:	e8845703          	lhu	a4,-376(s0)
    80005152:	e0e6dee3          	bge	a3,a4,80004f6e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005156:	2781                	sext.w	a5,a5
    80005158:	e0f43023          	sd	a5,-512(s0)
    8000515c:	03800713          	li	a4,56
    80005160:	86be                	mv	a3,a5
    80005162:	e1840613          	addi	a2,s0,-488
    80005166:	4581                	li	a1,0
    80005168:	8556                	mv	a0,s5
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	a5c080e7          	jalr	-1444(ra) # 80003bc6 <readi>
    80005172:	03800793          	li	a5,56
    80005176:	f6f51be3          	bne	a0,a5,800050ec <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000517a:	e1842783          	lw	a5,-488(s0)
    8000517e:	4705                	li	a4,1
    80005180:	fae79de3          	bne	a5,a4,8000513a <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005184:	e4043483          	ld	s1,-448(s0)
    80005188:	e3843783          	ld	a5,-456(s0)
    8000518c:	f6f4ede3          	bltu	s1,a5,80005106 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005190:	e2843783          	ld	a5,-472(s0)
    80005194:	94be                	add	s1,s1,a5
    80005196:	f6f4ebe3          	bltu	s1,a5,8000510c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000519a:	de043703          	ld	a4,-544(s0)
    8000519e:	8ff9                	and	a5,a5,a4
    800051a0:	fbad                	bnez	a5,80005112 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051a2:	e1c42503          	lw	a0,-484(s0)
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	c58080e7          	jalr	-936(ra) # 80004dfe <flags2perm>
    800051ae:	86aa                	mv	a3,a0
    800051b0:	8626                	mv	a2,s1
    800051b2:	85ca                	mv	a1,s2
    800051b4:	855a                	mv	a0,s6
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	2b6080e7          	jalr	694(ra) # 8000146c <uvmalloc>
    800051be:	dea43c23          	sd	a0,-520(s0)
    800051c2:	d939                	beqz	a0,80005118 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051c4:	e2843c03          	ld	s8,-472(s0)
    800051c8:	e2042c83          	lw	s9,-480(s0)
    800051cc:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051d0:	f60b83e3          	beqz	s7,80005136 <exec+0x31c>
    800051d4:	89de                	mv	s3,s7
    800051d6:	4481                	li	s1,0
    800051d8:	bb95                	j	80004f4c <exec+0x132>

00000000800051da <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051da:	7179                	addi	sp,sp,-48
    800051dc:	f406                	sd	ra,40(sp)
    800051de:	f022                	sd	s0,32(sp)
    800051e0:	ec26                	sd	s1,24(sp)
    800051e2:	e84a                	sd	s2,16(sp)
    800051e4:	1800                	addi	s0,sp,48
    800051e6:	892e                	mv	s2,a1
    800051e8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051ea:	fdc40593          	addi	a1,s0,-36
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	acc080e7          	jalr	-1332(ra) # 80002cba <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051f6:	fdc42703          	lw	a4,-36(s0)
    800051fa:	47bd                	li	a5,15
    800051fc:	02e7eb63          	bltu	a5,a4,80005232 <argfd+0x58>
    80005200:	ffffd097          	auipc	ra,0xffffd
    80005204:	808080e7          	jalr	-2040(ra) # 80001a08 <myproc>
    80005208:	fdc42703          	lw	a4,-36(s0)
    8000520c:	01a70793          	addi	a5,a4,26
    80005210:	078e                	slli	a5,a5,0x3
    80005212:	953e                	add	a0,a0,a5
    80005214:	611c                	ld	a5,0(a0)
    80005216:	c385                	beqz	a5,80005236 <argfd+0x5c>
    return -1;
  if(pfd)
    80005218:	00090463          	beqz	s2,80005220 <argfd+0x46>
    *pfd = fd;
    8000521c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005220:	4501                	li	a0,0
  if(pf)
    80005222:	c091                	beqz	s1,80005226 <argfd+0x4c>
    *pf = f;
    80005224:	e09c                	sd	a5,0(s1)
}
    80005226:	70a2                	ld	ra,40(sp)
    80005228:	7402                	ld	s0,32(sp)
    8000522a:	64e2                	ld	s1,24(sp)
    8000522c:	6942                	ld	s2,16(sp)
    8000522e:	6145                	addi	sp,sp,48
    80005230:	8082                	ret
    return -1;
    80005232:	557d                	li	a0,-1
    80005234:	bfcd                	j	80005226 <argfd+0x4c>
    80005236:	557d                	li	a0,-1
    80005238:	b7fd                	j	80005226 <argfd+0x4c>

000000008000523a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000523a:	1101                	addi	sp,sp,-32
    8000523c:	ec06                	sd	ra,24(sp)
    8000523e:	e822                	sd	s0,16(sp)
    80005240:	e426                	sd	s1,8(sp)
    80005242:	1000                	addi	s0,sp,32
    80005244:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	7c2080e7          	jalr	1986(ra) # 80001a08 <myproc>
    8000524e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005250:	0d050793          	addi	a5,a0,208
    80005254:	4501                	li	a0,0
    80005256:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005258:	6398                	ld	a4,0(a5)
    8000525a:	cb19                	beqz	a4,80005270 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000525c:	2505                	addiw	a0,a0,1
    8000525e:	07a1                	addi	a5,a5,8
    80005260:	fed51ce3          	bne	a0,a3,80005258 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005264:	557d                	li	a0,-1
}
    80005266:	60e2                	ld	ra,24(sp)
    80005268:	6442                	ld	s0,16(sp)
    8000526a:	64a2                	ld	s1,8(sp)
    8000526c:	6105                	addi	sp,sp,32
    8000526e:	8082                	ret
      p->ofile[fd] = f;
    80005270:	01a50793          	addi	a5,a0,26
    80005274:	078e                	slli	a5,a5,0x3
    80005276:	963e                	add	a2,a2,a5
    80005278:	e204                	sd	s1,0(a2)
      return fd;
    8000527a:	b7f5                	j	80005266 <fdalloc+0x2c>

000000008000527c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000527c:	715d                	addi	sp,sp,-80
    8000527e:	e486                	sd	ra,72(sp)
    80005280:	e0a2                	sd	s0,64(sp)
    80005282:	fc26                	sd	s1,56(sp)
    80005284:	f84a                	sd	s2,48(sp)
    80005286:	f44e                	sd	s3,40(sp)
    80005288:	f052                	sd	s4,32(sp)
    8000528a:	ec56                	sd	s5,24(sp)
    8000528c:	e85a                	sd	s6,16(sp)
    8000528e:	0880                	addi	s0,sp,80
    80005290:	8b2e                	mv	s6,a1
    80005292:	89b2                	mv	s3,a2
    80005294:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005296:	fb040593          	addi	a1,s0,-80
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	e3c080e7          	jalr	-452(ra) # 800040d6 <nameiparent>
    800052a2:	84aa                	mv	s1,a0
    800052a4:	14050f63          	beqz	a0,80005402 <create+0x186>
    return 0;

  ilock(dp);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	66a080e7          	jalr	1642(ra) # 80003912 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052b0:	4601                	li	a2,0
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	b3e080e7          	jalr	-1218(ra) # 80003df6 <dirlookup>
    800052c0:	8aaa                	mv	s5,a0
    800052c2:	c931                	beqz	a0,80005316 <create+0x9a>
    iunlockput(dp);
    800052c4:	8526                	mv	a0,s1
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	8ae080e7          	jalr	-1874(ra) # 80003b74 <iunlockput>
    ilock(ip);
    800052ce:	8556                	mv	a0,s5
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	642080e7          	jalr	1602(ra) # 80003912 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052d8:	000b059b          	sext.w	a1,s6
    800052dc:	4789                	li	a5,2
    800052de:	02f59563          	bne	a1,a5,80005308 <create+0x8c>
    800052e2:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0a4>
    800052e6:	37f9                	addiw	a5,a5,-2
    800052e8:	17c2                	slli	a5,a5,0x30
    800052ea:	93c1                	srli	a5,a5,0x30
    800052ec:	4705                	li	a4,1
    800052ee:	00f76d63          	bltu	a4,a5,80005308 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052f2:	8556                	mv	a0,s5
    800052f4:	60a6                	ld	ra,72(sp)
    800052f6:	6406                	ld	s0,64(sp)
    800052f8:	74e2                	ld	s1,56(sp)
    800052fa:	7942                	ld	s2,48(sp)
    800052fc:	79a2                	ld	s3,40(sp)
    800052fe:	7a02                	ld	s4,32(sp)
    80005300:	6ae2                	ld	s5,24(sp)
    80005302:	6b42                	ld	s6,16(sp)
    80005304:	6161                	addi	sp,sp,80
    80005306:	8082                	ret
    iunlockput(ip);
    80005308:	8556                	mv	a0,s5
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	86a080e7          	jalr	-1942(ra) # 80003b74 <iunlockput>
    return 0;
    80005312:	4a81                	li	s5,0
    80005314:	bff9                	j	800052f2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005316:	85da                	mv	a1,s6
    80005318:	4088                	lw	a0,0(s1)
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	45c080e7          	jalr	1116(ra) # 80003776 <ialloc>
    80005322:	8a2a                	mv	s4,a0
    80005324:	c539                	beqz	a0,80005372 <create+0xf6>
  ilock(ip);
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	5ec080e7          	jalr	1516(ra) # 80003912 <ilock>
  ip->major = major;
    8000532e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005332:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005336:	4905                	li	s2,1
    80005338:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000533c:	8552                	mv	a0,s4
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	50a080e7          	jalr	1290(ra) # 80003848 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005346:	000b059b          	sext.w	a1,s6
    8000534a:	03258b63          	beq	a1,s2,80005380 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000534e:	004a2603          	lw	a2,4(s4)
    80005352:	fb040593          	addi	a1,s0,-80
    80005356:	8526                	mv	a0,s1
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	cae080e7          	jalr	-850(ra) # 80004006 <dirlink>
    80005360:	06054f63          	bltz	a0,800053de <create+0x162>
  iunlockput(dp);
    80005364:	8526                	mv	a0,s1
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	80e080e7          	jalr	-2034(ra) # 80003b74 <iunlockput>
  return ip;
    8000536e:	8ad2                	mv	s5,s4
    80005370:	b749                	j	800052f2 <create+0x76>
    iunlockput(dp);
    80005372:	8526                	mv	a0,s1
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	800080e7          	jalr	-2048(ra) # 80003b74 <iunlockput>
    return 0;
    8000537c:	8ad2                	mv	s5,s4
    8000537e:	bf95                	j	800052f2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005380:	004a2603          	lw	a2,4(s4)
    80005384:	00003597          	auipc	a1,0x3
    80005388:	3c458593          	addi	a1,a1,964 # 80008748 <syscalls+0x2c8>
    8000538c:	8552                	mv	a0,s4
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	c78080e7          	jalr	-904(ra) # 80004006 <dirlink>
    80005396:	04054463          	bltz	a0,800053de <create+0x162>
    8000539a:	40d0                	lw	a2,4(s1)
    8000539c:	00003597          	auipc	a1,0x3
    800053a0:	3b458593          	addi	a1,a1,948 # 80008750 <syscalls+0x2d0>
    800053a4:	8552                	mv	a0,s4
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	c60080e7          	jalr	-928(ra) # 80004006 <dirlink>
    800053ae:	02054863          	bltz	a0,800053de <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053b2:	004a2603          	lw	a2,4(s4)
    800053b6:	fb040593          	addi	a1,s0,-80
    800053ba:	8526                	mv	a0,s1
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	c4a080e7          	jalr	-950(ra) # 80004006 <dirlink>
    800053c4:	00054d63          	bltz	a0,800053de <create+0x162>
    dp->nlink++;  // for ".."
    800053c8:	04a4d783          	lhu	a5,74(s1)
    800053cc:	2785                	addiw	a5,a5,1
    800053ce:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	474080e7          	jalr	1140(ra) # 80003848 <iupdate>
    800053dc:	b761                	j	80005364 <create+0xe8>
  ip->nlink = 0;
    800053de:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053e2:	8552                	mv	a0,s4
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	464080e7          	jalr	1124(ra) # 80003848 <iupdate>
  iunlockput(ip);
    800053ec:	8552                	mv	a0,s4
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	786080e7          	jalr	1926(ra) # 80003b74 <iunlockput>
  iunlockput(dp);
    800053f6:	8526                	mv	a0,s1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	77c080e7          	jalr	1916(ra) # 80003b74 <iunlockput>
  return 0;
    80005400:	bdcd                	j	800052f2 <create+0x76>
    return 0;
    80005402:	8aaa                	mv	s5,a0
    80005404:	b5fd                	j	800052f2 <create+0x76>

0000000080005406 <sys_dup>:
{
    80005406:	7179                	addi	sp,sp,-48
    80005408:	f406                	sd	ra,40(sp)
    8000540a:	f022                	sd	s0,32(sp)
    8000540c:	ec26                	sd	s1,24(sp)
    8000540e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005410:	fd840613          	addi	a2,s0,-40
    80005414:	4581                	li	a1,0
    80005416:	4501                	li	a0,0
    80005418:	00000097          	auipc	ra,0x0
    8000541c:	dc2080e7          	jalr	-574(ra) # 800051da <argfd>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005422:	02054363          	bltz	a0,80005448 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005426:	fd843503          	ld	a0,-40(s0)
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	e10080e7          	jalr	-496(ra) # 8000523a <fdalloc>
    80005432:	84aa                	mv	s1,a0
    return -1;
    80005434:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005436:	00054963          	bltz	a0,80005448 <sys_dup+0x42>
  filedup(f);
    8000543a:	fd843503          	ld	a0,-40(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	310080e7          	jalr	784(ra) # 8000474e <filedup>
  return fd;
    80005446:	87a6                	mv	a5,s1
}
    80005448:	853e                	mv	a0,a5
    8000544a:	70a2                	ld	ra,40(sp)
    8000544c:	7402                	ld	s0,32(sp)
    8000544e:	64e2                	ld	s1,24(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret

0000000080005454 <sys_read>:
{
    80005454:	7179                	addi	sp,sp,-48
    80005456:	f406                	sd	ra,40(sp)
    80005458:	f022                	sd	s0,32(sp)
    8000545a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000545c:	fd840593          	addi	a1,s0,-40
    80005460:	4505                	li	a0,1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	878080e7          	jalr	-1928(ra) # 80002cda <argaddr>
  argint(2, &n);
    8000546a:	fe440593          	addi	a1,s0,-28
    8000546e:	4509                	li	a0,2
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	84a080e7          	jalr	-1974(ra) # 80002cba <argint>
  if(argfd(0, 0, &f) < 0)
    80005478:	fe840613          	addi	a2,s0,-24
    8000547c:	4581                	li	a1,0
    8000547e:	4501                	li	a0,0
    80005480:	00000097          	auipc	ra,0x0
    80005484:	d5a080e7          	jalr	-678(ra) # 800051da <argfd>
    80005488:	87aa                	mv	a5,a0
    return -1;
    8000548a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000548c:	0007cc63          	bltz	a5,800054a4 <sys_read+0x50>
  return fileread(f, p, n);
    80005490:	fe442603          	lw	a2,-28(s0)
    80005494:	fd843583          	ld	a1,-40(s0)
    80005498:	fe843503          	ld	a0,-24(s0)
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	43e080e7          	jalr	1086(ra) # 800048da <fileread>
}
    800054a4:	70a2                	ld	ra,40(sp)
    800054a6:	7402                	ld	s0,32(sp)
    800054a8:	6145                	addi	sp,sp,48
    800054aa:	8082                	ret

00000000800054ac <sys_write>:
{
    800054ac:	7179                	addi	sp,sp,-48
    800054ae:	f406                	sd	ra,40(sp)
    800054b0:	f022                	sd	s0,32(sp)
    800054b2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054b4:	fd840593          	addi	a1,s0,-40
    800054b8:	4505                	li	a0,1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	820080e7          	jalr	-2016(ra) # 80002cda <argaddr>
  argint(2, &n);
    800054c2:	fe440593          	addi	a1,s0,-28
    800054c6:	4509                	li	a0,2
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	7f2080e7          	jalr	2034(ra) # 80002cba <argint>
  if(argfd(0, 0, &f) < 0)
    800054d0:	fe840613          	addi	a2,s0,-24
    800054d4:	4581                	li	a1,0
    800054d6:	4501                	li	a0,0
    800054d8:	00000097          	auipc	ra,0x0
    800054dc:	d02080e7          	jalr	-766(ra) # 800051da <argfd>
    800054e0:	87aa                	mv	a5,a0
    return -1;
    800054e2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054e4:	0007cc63          	bltz	a5,800054fc <sys_write+0x50>
  return filewrite(f, p, n);
    800054e8:	fe442603          	lw	a2,-28(s0)
    800054ec:	fd843583          	ld	a1,-40(s0)
    800054f0:	fe843503          	ld	a0,-24(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	4a8080e7          	jalr	1192(ra) # 8000499c <filewrite>
}
    800054fc:	70a2                	ld	ra,40(sp)
    800054fe:	7402                	ld	s0,32(sp)
    80005500:	6145                	addi	sp,sp,48
    80005502:	8082                	ret

0000000080005504 <sys_close>:
{
    80005504:	1101                	addi	sp,sp,-32
    80005506:	ec06                	sd	ra,24(sp)
    80005508:	e822                	sd	s0,16(sp)
    8000550a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000550c:	fe040613          	addi	a2,s0,-32
    80005510:	fec40593          	addi	a1,s0,-20
    80005514:	4501                	li	a0,0
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	cc4080e7          	jalr	-828(ra) # 800051da <argfd>
    return -1;
    8000551e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005520:	02054463          	bltz	a0,80005548 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	4e4080e7          	jalr	1252(ra) # 80001a08 <myproc>
    8000552c:	fec42783          	lw	a5,-20(s0)
    80005530:	07e9                	addi	a5,a5,26
    80005532:	078e                	slli	a5,a5,0x3
    80005534:	97aa                	add	a5,a5,a0
    80005536:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000553a:	fe043503          	ld	a0,-32(s0)
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	262080e7          	jalr	610(ra) # 800047a0 <fileclose>
  return 0;
    80005546:	4781                	li	a5,0
}
    80005548:	853e                	mv	a0,a5
    8000554a:	60e2                	ld	ra,24(sp)
    8000554c:	6442                	ld	s0,16(sp)
    8000554e:	6105                	addi	sp,sp,32
    80005550:	8082                	ret

0000000080005552 <sys_fstat>:
{
    80005552:	1101                	addi	sp,sp,-32
    80005554:	ec06                	sd	ra,24(sp)
    80005556:	e822                	sd	s0,16(sp)
    80005558:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000555a:	fe040593          	addi	a1,s0,-32
    8000555e:	4505                	li	a0,1
    80005560:	ffffd097          	auipc	ra,0xffffd
    80005564:	77a080e7          	jalr	1914(ra) # 80002cda <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005568:	fe840613          	addi	a2,s0,-24
    8000556c:	4581                	li	a1,0
    8000556e:	4501                	li	a0,0
    80005570:	00000097          	auipc	ra,0x0
    80005574:	c6a080e7          	jalr	-918(ra) # 800051da <argfd>
    80005578:	87aa                	mv	a5,a0
    return -1;
    8000557a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000557c:	0007ca63          	bltz	a5,80005590 <sys_fstat+0x3e>
  return filestat(f, st);
    80005580:	fe043583          	ld	a1,-32(s0)
    80005584:	fe843503          	ld	a0,-24(s0)
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	2e0080e7          	jalr	736(ra) # 80004868 <filestat>
}
    80005590:	60e2                	ld	ra,24(sp)
    80005592:	6442                	ld	s0,16(sp)
    80005594:	6105                	addi	sp,sp,32
    80005596:	8082                	ret

0000000080005598 <sys_link>:
{
    80005598:	7169                	addi	sp,sp,-304
    8000559a:	f606                	sd	ra,296(sp)
    8000559c:	f222                	sd	s0,288(sp)
    8000559e:	ee26                	sd	s1,280(sp)
    800055a0:	ea4a                	sd	s2,272(sp)
    800055a2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a4:	08000613          	li	a2,128
    800055a8:	ed040593          	addi	a1,s0,-304
    800055ac:	4501                	li	a0,0
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	74c080e7          	jalr	1868(ra) # 80002cfa <argstr>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b8:	10054e63          	bltz	a0,800056d4 <sys_link+0x13c>
    800055bc:	08000613          	li	a2,128
    800055c0:	f5040593          	addi	a1,s0,-176
    800055c4:	4505                	li	a0,1
    800055c6:	ffffd097          	auipc	ra,0xffffd
    800055ca:	734080e7          	jalr	1844(ra) # 80002cfa <argstr>
    return -1;
    800055ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d0:	10054263          	bltz	a0,800056d4 <sys_link+0x13c>
  begin_op();
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	d00080e7          	jalr	-768(ra) # 800042d4 <begin_op>
  if((ip = namei(old)) == 0){
    800055dc:	ed040513          	addi	a0,s0,-304
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	ad8080e7          	jalr	-1320(ra) # 800040b8 <namei>
    800055e8:	84aa                	mv	s1,a0
    800055ea:	c551                	beqz	a0,80005676 <sys_link+0xde>
  ilock(ip);
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	326080e7          	jalr	806(ra) # 80003912 <ilock>
  if(ip->type == T_DIR){
    800055f4:	04449703          	lh	a4,68(s1)
    800055f8:	4785                	li	a5,1
    800055fa:	08f70463          	beq	a4,a5,80005682 <sys_link+0xea>
  ip->nlink++;
    800055fe:	04a4d783          	lhu	a5,74(s1)
    80005602:	2785                	addiw	a5,a5,1
    80005604:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	23e080e7          	jalr	574(ra) # 80003848 <iupdate>
  iunlock(ip);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	3c0080e7          	jalr	960(ra) # 800039d4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000561c:	fd040593          	addi	a1,s0,-48
    80005620:	f5040513          	addi	a0,s0,-176
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	ab2080e7          	jalr	-1358(ra) # 800040d6 <nameiparent>
    8000562c:	892a                	mv	s2,a0
    8000562e:	c935                	beqz	a0,800056a2 <sys_link+0x10a>
  ilock(dp);
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	2e2080e7          	jalr	738(ra) # 80003912 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005638:	00092703          	lw	a4,0(s2)
    8000563c:	409c                	lw	a5,0(s1)
    8000563e:	04f71d63          	bne	a4,a5,80005698 <sys_link+0x100>
    80005642:	40d0                	lw	a2,4(s1)
    80005644:	fd040593          	addi	a1,s0,-48
    80005648:	854a                	mv	a0,s2
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	9bc080e7          	jalr	-1604(ra) # 80004006 <dirlink>
    80005652:	04054363          	bltz	a0,80005698 <sys_link+0x100>
  iunlockput(dp);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	51c080e7          	jalr	1308(ra) # 80003b74 <iunlockput>
  iput(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	46a080e7          	jalr	1130(ra) # 80003acc <iput>
  end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	cea080e7          	jalr	-790(ra) # 80004354 <end_op>
  return 0;
    80005672:	4781                	li	a5,0
    80005674:	a085                	j	800056d4 <sys_link+0x13c>
    end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	cde080e7          	jalr	-802(ra) # 80004354 <end_op>
    return -1;
    8000567e:	57fd                	li	a5,-1
    80005680:	a891                	j	800056d4 <sys_link+0x13c>
    iunlockput(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	4f0080e7          	jalr	1264(ra) # 80003b74 <iunlockput>
    end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	cc8080e7          	jalr	-824(ra) # 80004354 <end_op>
    return -1;
    80005694:	57fd                	li	a5,-1
    80005696:	a83d                	j	800056d4 <sys_link+0x13c>
    iunlockput(dp);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	4da080e7          	jalr	1242(ra) # 80003b74 <iunlockput>
  ilock(ip);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	26e080e7          	jalr	622(ra) # 80003912 <ilock>
  ip->nlink--;
    800056ac:	04a4d783          	lhu	a5,74(s1)
    800056b0:	37fd                	addiw	a5,a5,-1
    800056b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	190080e7          	jalr	400(ra) # 80003848 <iupdate>
  iunlockput(ip);
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	4b2080e7          	jalr	1202(ra) # 80003b74 <iunlockput>
  end_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	c8a080e7          	jalr	-886(ra) # 80004354 <end_op>
  return -1;
    800056d2:	57fd                	li	a5,-1
}
    800056d4:	853e                	mv	a0,a5
    800056d6:	70b2                	ld	ra,296(sp)
    800056d8:	7412                	ld	s0,288(sp)
    800056da:	64f2                	ld	s1,280(sp)
    800056dc:	6952                	ld	s2,272(sp)
    800056de:	6155                	addi	sp,sp,304
    800056e0:	8082                	ret

00000000800056e2 <sys_unlink>:
{
    800056e2:	7151                	addi	sp,sp,-240
    800056e4:	f586                	sd	ra,232(sp)
    800056e6:	f1a2                	sd	s0,224(sp)
    800056e8:	eda6                	sd	s1,216(sp)
    800056ea:	e9ca                	sd	s2,208(sp)
    800056ec:	e5ce                	sd	s3,200(sp)
    800056ee:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056f0:	08000613          	li	a2,128
    800056f4:	f3040593          	addi	a1,s0,-208
    800056f8:	4501                	li	a0,0
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	600080e7          	jalr	1536(ra) # 80002cfa <argstr>
    80005702:	18054163          	bltz	a0,80005884 <sys_unlink+0x1a2>
  begin_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	bce080e7          	jalr	-1074(ra) # 800042d4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000570e:	fb040593          	addi	a1,s0,-80
    80005712:	f3040513          	addi	a0,s0,-208
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	9c0080e7          	jalr	-1600(ra) # 800040d6 <nameiparent>
    8000571e:	84aa                	mv	s1,a0
    80005720:	c979                	beqz	a0,800057f6 <sys_unlink+0x114>
  ilock(dp);
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	1f0080e7          	jalr	496(ra) # 80003912 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000572a:	00003597          	auipc	a1,0x3
    8000572e:	01e58593          	addi	a1,a1,30 # 80008748 <syscalls+0x2c8>
    80005732:	fb040513          	addi	a0,s0,-80
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	6a6080e7          	jalr	1702(ra) # 80003ddc <namecmp>
    8000573e:	14050a63          	beqz	a0,80005892 <sys_unlink+0x1b0>
    80005742:	00003597          	auipc	a1,0x3
    80005746:	00e58593          	addi	a1,a1,14 # 80008750 <syscalls+0x2d0>
    8000574a:	fb040513          	addi	a0,s0,-80
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	68e080e7          	jalr	1678(ra) # 80003ddc <namecmp>
    80005756:	12050e63          	beqz	a0,80005892 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000575a:	f2c40613          	addi	a2,s0,-212
    8000575e:	fb040593          	addi	a1,s0,-80
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	692080e7          	jalr	1682(ra) # 80003df6 <dirlookup>
    8000576c:	892a                	mv	s2,a0
    8000576e:	12050263          	beqz	a0,80005892 <sys_unlink+0x1b0>
  ilock(ip);
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	1a0080e7          	jalr	416(ra) # 80003912 <ilock>
  if(ip->nlink < 1)
    8000577a:	04a91783          	lh	a5,74(s2)
    8000577e:	08f05263          	blez	a5,80005802 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005782:	04491703          	lh	a4,68(s2)
    80005786:	4785                	li	a5,1
    80005788:	08f70563          	beq	a4,a5,80005812 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000578c:	4641                	li	a2,16
    8000578e:	4581                	li	a1,0
    80005790:	fc040513          	addi	a0,s0,-64
    80005794:	ffffb097          	auipc	ra,0xffffb
    80005798:	59a080e7          	jalr	1434(ra) # 80000d2e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000579c:	4741                	li	a4,16
    8000579e:	f2c42683          	lw	a3,-212(s0)
    800057a2:	fc040613          	addi	a2,s0,-64
    800057a6:	4581                	li	a1,0
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	514080e7          	jalr	1300(ra) # 80003cbe <writei>
    800057b2:	47c1                	li	a5,16
    800057b4:	0af51563          	bne	a0,a5,8000585e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057b8:	04491703          	lh	a4,68(s2)
    800057bc:	4785                	li	a5,1
    800057be:	0af70863          	beq	a4,a5,8000586e <sys_unlink+0x18c>
  iunlockput(dp);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	3b0080e7          	jalr	944(ra) # 80003b74 <iunlockput>
  ip->nlink--;
    800057cc:	04a95783          	lhu	a5,74(s2)
    800057d0:	37fd                	addiw	a5,a5,-1
    800057d2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	070080e7          	jalr	112(ra) # 80003848 <iupdate>
  iunlockput(ip);
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	392080e7          	jalr	914(ra) # 80003b74 <iunlockput>
  end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	b6a080e7          	jalr	-1174(ra) # 80004354 <end_op>
  return 0;
    800057f2:	4501                	li	a0,0
    800057f4:	a84d                	j	800058a6 <sys_unlink+0x1c4>
    end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	b5e080e7          	jalr	-1186(ra) # 80004354 <end_op>
    return -1;
    800057fe:	557d                	li	a0,-1
    80005800:	a05d                	j	800058a6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005802:	00003517          	auipc	a0,0x3
    80005806:	f5650513          	addi	a0,a0,-170 # 80008758 <syscalls+0x2d8>
    8000580a:	ffffb097          	auipc	ra,0xffffb
    8000580e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005812:	04c92703          	lw	a4,76(s2)
    80005816:	02000793          	li	a5,32
    8000581a:	f6e7f9e3          	bgeu	a5,a4,8000578c <sys_unlink+0xaa>
    8000581e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005822:	4741                	li	a4,16
    80005824:	86ce                	mv	a3,s3
    80005826:	f1840613          	addi	a2,s0,-232
    8000582a:	4581                	li	a1,0
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	398080e7          	jalr	920(ra) # 80003bc6 <readi>
    80005836:	47c1                	li	a5,16
    80005838:	00f51b63          	bne	a0,a5,8000584e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000583c:	f1845783          	lhu	a5,-232(s0)
    80005840:	e7a1                	bnez	a5,80005888 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005842:	29c1                	addiw	s3,s3,16
    80005844:	04c92783          	lw	a5,76(s2)
    80005848:	fcf9ede3          	bltu	s3,a5,80005822 <sys_unlink+0x140>
    8000584c:	b781                	j	8000578c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000584e:	00003517          	auipc	a0,0x3
    80005852:	f2250513          	addi	a0,a0,-222 # 80008770 <syscalls+0x2f0>
    80005856:	ffffb097          	auipc	ra,0xffffb
    8000585a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000585e:	00003517          	auipc	a0,0x3
    80005862:	f2a50513          	addi	a0,a0,-214 # 80008788 <syscalls+0x308>
    80005866:	ffffb097          	auipc	ra,0xffffb
    8000586a:	cd8080e7          	jalr	-808(ra) # 8000053e <panic>
    dp->nlink--;
    8000586e:	04a4d783          	lhu	a5,74(s1)
    80005872:	37fd                	addiw	a5,a5,-1
    80005874:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005878:	8526                	mv	a0,s1
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	fce080e7          	jalr	-50(ra) # 80003848 <iupdate>
    80005882:	b781                	j	800057c2 <sys_unlink+0xe0>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	a005                	j	800058a6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005888:	854a                	mv	a0,s2
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	2ea080e7          	jalr	746(ra) # 80003b74 <iunlockput>
  iunlockput(dp);
    80005892:	8526                	mv	a0,s1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	2e0080e7          	jalr	736(ra) # 80003b74 <iunlockput>
  end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	ab8080e7          	jalr	-1352(ra) # 80004354 <end_op>
  return -1;
    800058a4:	557d                	li	a0,-1
}
    800058a6:	70ae                	ld	ra,232(sp)
    800058a8:	740e                	ld	s0,224(sp)
    800058aa:	64ee                	ld	s1,216(sp)
    800058ac:	694e                	ld	s2,208(sp)
    800058ae:	69ae                	ld	s3,200(sp)
    800058b0:	616d                	addi	sp,sp,240
    800058b2:	8082                	ret

00000000800058b4 <sys_open>:

uint64
sys_open(void)
{
    800058b4:	7131                	addi	sp,sp,-192
    800058b6:	fd06                	sd	ra,184(sp)
    800058b8:	f922                	sd	s0,176(sp)
    800058ba:	f526                	sd	s1,168(sp)
    800058bc:	f14a                	sd	s2,160(sp)
    800058be:	ed4e                	sd	s3,152(sp)
    800058c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058c2:	f4c40593          	addi	a1,s0,-180
    800058c6:	4505                	li	a0,1
    800058c8:	ffffd097          	auipc	ra,0xffffd
    800058cc:	3f2080e7          	jalr	1010(ra) # 80002cba <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058d0:	08000613          	li	a2,128
    800058d4:	f5040593          	addi	a1,s0,-176
    800058d8:	4501                	li	a0,0
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	420080e7          	jalr	1056(ra) # 80002cfa <argstr>
    800058e2:	87aa                	mv	a5,a0
    return -1;
    800058e4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058e6:	0a07c963          	bltz	a5,80005998 <sys_open+0xe4>

  begin_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	9ea080e7          	jalr	-1558(ra) # 800042d4 <begin_op>

  if(omode & O_CREATE){
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	2007f793          	andi	a5,a5,512
    800058fa:	cfc5                	beqz	a5,800059b2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058fc:	4681                	li	a3,0
    800058fe:	4601                	li	a2,0
    80005900:	4589                	li	a1,2
    80005902:	f5040513          	addi	a0,s0,-176
    80005906:	00000097          	auipc	ra,0x0
    8000590a:	976080e7          	jalr	-1674(ra) # 8000527c <create>
    8000590e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005910:	c959                	beqz	a0,800059a6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005912:	04449703          	lh	a4,68(s1)
    80005916:	478d                	li	a5,3
    80005918:	00f71763          	bne	a4,a5,80005926 <sys_open+0x72>
    8000591c:	0464d703          	lhu	a4,70(s1)
    80005920:	47a5                	li	a5,9
    80005922:	0ce7ed63          	bltu	a5,a4,800059fc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	dbe080e7          	jalr	-578(ra) # 800046e4 <filealloc>
    8000592e:	89aa                	mv	s3,a0
    80005930:	10050363          	beqz	a0,80005a36 <sys_open+0x182>
    80005934:	00000097          	auipc	ra,0x0
    80005938:	906080e7          	jalr	-1786(ra) # 8000523a <fdalloc>
    8000593c:	892a                	mv	s2,a0
    8000593e:	0e054763          	bltz	a0,80005a2c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005942:	04449703          	lh	a4,68(s1)
    80005946:	478d                	li	a5,3
    80005948:	0cf70563          	beq	a4,a5,80005a12 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000594c:	4789                	li	a5,2
    8000594e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005952:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005956:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000595a:	f4c42783          	lw	a5,-180(s0)
    8000595e:	0017c713          	xori	a4,a5,1
    80005962:	8b05                	andi	a4,a4,1
    80005964:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005968:	0037f713          	andi	a4,a5,3
    8000596c:	00e03733          	snez	a4,a4
    80005970:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005974:	4007f793          	andi	a5,a5,1024
    80005978:	c791                	beqz	a5,80005984 <sys_open+0xd0>
    8000597a:	04449703          	lh	a4,68(s1)
    8000597e:	4789                	li	a5,2
    80005980:	0af70063          	beq	a4,a5,80005a20 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005984:	8526                	mv	a0,s1
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	04e080e7          	jalr	78(ra) # 800039d4 <iunlock>
  end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	9c6080e7          	jalr	-1594(ra) # 80004354 <end_op>

  return fd;
    80005996:	854a                	mv	a0,s2
}
    80005998:	70ea                	ld	ra,184(sp)
    8000599a:	744a                	ld	s0,176(sp)
    8000599c:	74aa                	ld	s1,168(sp)
    8000599e:	790a                	ld	s2,160(sp)
    800059a0:	69ea                	ld	s3,152(sp)
    800059a2:	6129                	addi	sp,sp,192
    800059a4:	8082                	ret
      end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	9ae080e7          	jalr	-1618(ra) # 80004354 <end_op>
      return -1;
    800059ae:	557d                	li	a0,-1
    800059b0:	b7e5                	j	80005998 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059b2:	f5040513          	addi	a0,s0,-176
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	702080e7          	jalr	1794(ra) # 800040b8 <namei>
    800059be:	84aa                	mv	s1,a0
    800059c0:	c905                	beqz	a0,800059f0 <sys_open+0x13c>
    ilock(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	f50080e7          	jalr	-176(ra) # 80003912 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ca:	04449703          	lh	a4,68(s1)
    800059ce:	4785                	li	a5,1
    800059d0:	f4f711e3          	bne	a4,a5,80005912 <sys_open+0x5e>
    800059d4:	f4c42783          	lw	a5,-180(s0)
    800059d8:	d7b9                	beqz	a5,80005926 <sys_open+0x72>
      iunlockput(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	198080e7          	jalr	408(ra) # 80003b74 <iunlockput>
      end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	970080e7          	jalr	-1680(ra) # 80004354 <end_op>
      return -1;
    800059ec:	557d                	li	a0,-1
    800059ee:	b76d                	j	80005998 <sys_open+0xe4>
      end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	964080e7          	jalr	-1692(ra) # 80004354 <end_op>
      return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	bf79                	j	80005998 <sys_open+0xe4>
    iunlockput(ip);
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	176080e7          	jalr	374(ra) # 80003b74 <iunlockput>
    end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	94e080e7          	jalr	-1714(ra) # 80004354 <end_op>
    return -1;
    80005a0e:	557d                	li	a0,-1
    80005a10:	b761                	j	80005998 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a12:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a16:	04649783          	lh	a5,70(s1)
    80005a1a:	02f99223          	sh	a5,36(s3)
    80005a1e:	bf25                	j	80005956 <sys_open+0xa2>
    itrunc(ip);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	ffe080e7          	jalr	-2(ra) # 80003a20 <itrunc>
    80005a2a:	bfa9                	j	80005984 <sys_open+0xd0>
      fileclose(f);
    80005a2c:	854e                	mv	a0,s3
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	d72080e7          	jalr	-654(ra) # 800047a0 <fileclose>
    iunlockput(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	13c080e7          	jalr	316(ra) # 80003b74 <iunlockput>
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	914080e7          	jalr	-1772(ra) # 80004354 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	b7b9                	j	80005998 <sys_open+0xe4>

0000000080005a4c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a4c:	7175                	addi	sp,sp,-144
    80005a4e:	e506                	sd	ra,136(sp)
    80005a50:	e122                	sd	s0,128(sp)
    80005a52:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	880080e7          	jalr	-1920(ra) # 800042d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a5c:	08000613          	li	a2,128
    80005a60:	f7040593          	addi	a1,s0,-144
    80005a64:	4501                	li	a0,0
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	294080e7          	jalr	660(ra) # 80002cfa <argstr>
    80005a6e:	02054963          	bltz	a0,80005aa0 <sys_mkdir+0x54>
    80005a72:	4681                	li	a3,0
    80005a74:	4601                	li	a2,0
    80005a76:	4585                	li	a1,1
    80005a78:	f7040513          	addi	a0,s0,-144
    80005a7c:	00000097          	auipc	ra,0x0
    80005a80:	800080e7          	jalr	-2048(ra) # 8000527c <create>
    80005a84:	cd11                	beqz	a0,80005aa0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	0ee080e7          	jalr	238(ra) # 80003b74 <iunlockput>
  end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	8c6080e7          	jalr	-1850(ra) # 80004354 <end_op>
  return 0;
    80005a96:	4501                	li	a0,0
}
    80005a98:	60aa                	ld	ra,136(sp)
    80005a9a:	640a                	ld	s0,128(sp)
    80005a9c:	6149                	addi	sp,sp,144
    80005a9e:	8082                	ret
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	8b4080e7          	jalr	-1868(ra) # 80004354 <end_op>
    return -1;
    80005aa8:	557d                	li	a0,-1
    80005aaa:	b7fd                	j	80005a98 <sys_mkdir+0x4c>

0000000080005aac <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aac:	7135                	addi	sp,sp,-160
    80005aae:	ed06                	sd	ra,152(sp)
    80005ab0:	e922                	sd	s0,144(sp)
    80005ab2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	820080e7          	jalr	-2016(ra) # 800042d4 <begin_op>
  argint(1, &major);
    80005abc:	f6c40593          	addi	a1,s0,-148
    80005ac0:	4505                	li	a0,1
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	1f8080e7          	jalr	504(ra) # 80002cba <argint>
  argint(2, &minor);
    80005aca:	f6840593          	addi	a1,s0,-152
    80005ace:	4509                	li	a0,2
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	1ea080e7          	jalr	490(ra) # 80002cba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad8:	08000613          	li	a2,128
    80005adc:	f7040593          	addi	a1,s0,-144
    80005ae0:	4501                	li	a0,0
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	218080e7          	jalr	536(ra) # 80002cfa <argstr>
    80005aea:	02054b63          	bltz	a0,80005b20 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aee:	f6841683          	lh	a3,-152(s0)
    80005af2:	f6c41603          	lh	a2,-148(s0)
    80005af6:	458d                	li	a1,3
    80005af8:	f7040513          	addi	a0,s0,-144
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	780080e7          	jalr	1920(ra) # 8000527c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b04:	cd11                	beqz	a0,80005b20 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	06e080e7          	jalr	110(ra) # 80003b74 <iunlockput>
  end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	846080e7          	jalr	-1978(ra) # 80004354 <end_op>
  return 0;
    80005b16:	4501                	li	a0,0
}
    80005b18:	60ea                	ld	ra,152(sp)
    80005b1a:	644a                	ld	s0,144(sp)
    80005b1c:	610d                	addi	sp,sp,160
    80005b1e:	8082                	ret
    end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	834080e7          	jalr	-1996(ra) # 80004354 <end_op>
    return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	b7fd                	j	80005b18 <sys_mknod+0x6c>

0000000080005b2c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b2c:	7135                	addi	sp,sp,-160
    80005b2e:	ed06                	sd	ra,152(sp)
    80005b30:	e922                	sd	s0,144(sp)
    80005b32:	e526                	sd	s1,136(sp)
    80005b34:	e14a                	sd	s2,128(sp)
    80005b36:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b38:	ffffc097          	auipc	ra,0xffffc
    80005b3c:	ed0080e7          	jalr	-304(ra) # 80001a08 <myproc>
    80005b40:	892a                	mv	s2,a0
  
  begin_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	792080e7          	jalr	1938(ra) # 800042d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b4a:	08000613          	li	a2,128
    80005b4e:	f6040593          	addi	a1,s0,-160
    80005b52:	4501                	li	a0,0
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	1a6080e7          	jalr	422(ra) # 80002cfa <argstr>
    80005b5c:	04054b63          	bltz	a0,80005bb2 <sys_chdir+0x86>
    80005b60:	f6040513          	addi	a0,s0,-160
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	554080e7          	jalr	1364(ra) # 800040b8 <namei>
    80005b6c:	84aa                	mv	s1,a0
    80005b6e:	c131                	beqz	a0,80005bb2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	da2080e7          	jalr	-606(ra) # 80003912 <ilock>
  if(ip->type != T_DIR){
    80005b78:	04449703          	lh	a4,68(s1)
    80005b7c:	4785                	li	a5,1
    80005b7e:	04f71063          	bne	a4,a5,80005bbe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b82:	8526                	mv	a0,s1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	e50080e7          	jalr	-432(ra) # 800039d4 <iunlock>
  iput(p->cwd);
    80005b8c:	15093503          	ld	a0,336(s2)
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	f3c080e7          	jalr	-196(ra) # 80003acc <iput>
  end_op();
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	7bc080e7          	jalr	1980(ra) # 80004354 <end_op>
  p->cwd = ip;
    80005ba0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ba4:	4501                	li	a0,0
}
    80005ba6:	60ea                	ld	ra,152(sp)
    80005ba8:	644a                	ld	s0,144(sp)
    80005baa:	64aa                	ld	s1,136(sp)
    80005bac:	690a                	ld	s2,128(sp)
    80005bae:	610d                	addi	sp,sp,160
    80005bb0:	8082                	ret
    end_op();
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	7a2080e7          	jalr	1954(ra) # 80004354 <end_op>
    return -1;
    80005bba:	557d                	li	a0,-1
    80005bbc:	b7ed                	j	80005ba6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bbe:	8526                	mv	a0,s1
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	fb4080e7          	jalr	-76(ra) # 80003b74 <iunlockput>
    end_op();
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	78c080e7          	jalr	1932(ra) # 80004354 <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	bfd1                	j	80005ba6 <sys_chdir+0x7a>

0000000080005bd4 <sys_exec>:

uint64
sys_exec(void)
{
    80005bd4:	7145                	addi	sp,sp,-464
    80005bd6:	e786                	sd	ra,456(sp)
    80005bd8:	e3a2                	sd	s0,448(sp)
    80005bda:	ff26                	sd	s1,440(sp)
    80005bdc:	fb4a                	sd	s2,432(sp)
    80005bde:	f74e                	sd	s3,424(sp)
    80005be0:	f352                	sd	s4,416(sp)
    80005be2:	ef56                	sd	s5,408(sp)
    80005be4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005be6:	e3840593          	addi	a1,s0,-456
    80005bea:	4505                	li	a0,1
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	0ee080e7          	jalr	238(ra) # 80002cda <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bf4:	08000613          	li	a2,128
    80005bf8:	f4040593          	addi	a1,s0,-192
    80005bfc:	4501                	li	a0,0
    80005bfe:	ffffd097          	auipc	ra,0xffffd
    80005c02:	0fc080e7          	jalr	252(ra) # 80002cfa <argstr>
    80005c06:	87aa                	mv	a5,a0
    return -1;
    80005c08:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c0a:	0c07c263          	bltz	a5,80005cce <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c0e:	10000613          	li	a2,256
    80005c12:	4581                	li	a1,0
    80005c14:	e4040513          	addi	a0,s0,-448
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	116080e7          	jalr	278(ra) # 80000d2e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c20:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c24:	89a6                	mv	s3,s1
    80005c26:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c28:	02000a13          	li	s4,32
    80005c2c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c30:	00391793          	slli	a5,s2,0x3
    80005c34:	e3040593          	addi	a1,s0,-464
    80005c38:	e3843503          	ld	a0,-456(s0)
    80005c3c:	953e                	add	a0,a0,a5
    80005c3e:	ffffd097          	auipc	ra,0xffffd
    80005c42:	fde080e7          	jalr	-34(ra) # 80002c1c <fetchaddr>
    80005c46:	02054a63          	bltz	a0,80005c7a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c4a:	e3043783          	ld	a5,-464(s0)
    80005c4e:	c3b9                	beqz	a5,80005c94 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c50:	ffffb097          	auipc	ra,0xffffb
    80005c54:	e96080e7          	jalr	-362(ra) # 80000ae6 <kalloc>
    80005c58:	85aa                	mv	a1,a0
    80005c5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c5e:	cd11                	beqz	a0,80005c7a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c60:	6605                	lui	a2,0x1
    80005c62:	e3043503          	ld	a0,-464(s0)
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	008080e7          	jalr	8(ra) # 80002c6e <fetchstr>
    80005c6e:	00054663          	bltz	a0,80005c7a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c72:	0905                	addi	s2,s2,1
    80005c74:	09a1                	addi	s3,s3,8
    80005c76:	fb491be3          	bne	s2,s4,80005c2c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7a:	10048913          	addi	s2,s1,256
    80005c7e:	6088                	ld	a0,0(s1)
    80005c80:	c531                	beqz	a0,80005ccc <sys_exec+0xf8>
    kfree(argv[i]);
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	d68080e7          	jalr	-664(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8a:	04a1                	addi	s1,s1,8
    80005c8c:	ff2499e3          	bne	s1,s2,80005c7e <sys_exec+0xaa>
  return -1;
    80005c90:	557d                	li	a0,-1
    80005c92:	a835                	j	80005cce <sys_exec+0xfa>
      argv[i] = 0;
    80005c94:	0a8e                	slli	s5,s5,0x3
    80005c96:	fc040793          	addi	a5,s0,-64
    80005c9a:	9abe                	add	s5,s5,a5
    80005c9c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ca0:	e4040593          	addi	a1,s0,-448
    80005ca4:	f4040513          	addi	a0,s0,-192
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	172080e7          	jalr	370(ra) # 80004e1a <exec>
    80005cb0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb2:	10048993          	addi	s3,s1,256
    80005cb6:	6088                	ld	a0,0(s1)
    80005cb8:	c901                	beqz	a0,80005cc8 <sys_exec+0xf4>
    kfree(argv[i]);
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	d30080e7          	jalr	-720(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc2:	04a1                	addi	s1,s1,8
    80005cc4:	ff3499e3          	bne	s1,s3,80005cb6 <sys_exec+0xe2>
  return ret;
    80005cc8:	854a                	mv	a0,s2
    80005cca:	a011                	j	80005cce <sys_exec+0xfa>
  return -1;
    80005ccc:	557d                	li	a0,-1
}
    80005cce:	60be                	ld	ra,456(sp)
    80005cd0:	641e                	ld	s0,448(sp)
    80005cd2:	74fa                	ld	s1,440(sp)
    80005cd4:	795a                	ld	s2,432(sp)
    80005cd6:	79ba                	ld	s3,424(sp)
    80005cd8:	7a1a                	ld	s4,416(sp)
    80005cda:	6afa                	ld	s5,408(sp)
    80005cdc:	6179                	addi	sp,sp,464
    80005cde:	8082                	ret

0000000080005ce0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ce0:	7139                	addi	sp,sp,-64
    80005ce2:	fc06                	sd	ra,56(sp)
    80005ce4:	f822                	sd	s0,48(sp)
    80005ce6:	f426                	sd	s1,40(sp)
    80005ce8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cea:	ffffc097          	auipc	ra,0xffffc
    80005cee:	d1e080e7          	jalr	-738(ra) # 80001a08 <myproc>
    80005cf2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cf4:	fd840593          	addi	a1,s0,-40
    80005cf8:	4501                	li	a0,0
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	fe0080e7          	jalr	-32(ra) # 80002cda <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d02:	fc840593          	addi	a1,s0,-56
    80005d06:	fd040513          	addi	a0,s0,-48
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	dc6080e7          	jalr	-570(ra) # 80004ad0 <pipealloc>
    return -1;
    80005d12:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d14:	0c054463          	bltz	a0,80005ddc <sys_pipe+0xfc>
  fd0 = -1;
    80005d18:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d1c:	fd043503          	ld	a0,-48(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	51a080e7          	jalr	1306(ra) # 8000523a <fdalloc>
    80005d28:	fca42223          	sw	a0,-60(s0)
    80005d2c:	08054b63          	bltz	a0,80005dc2 <sys_pipe+0xe2>
    80005d30:	fc843503          	ld	a0,-56(s0)
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	506080e7          	jalr	1286(ra) # 8000523a <fdalloc>
    80005d3c:	fca42023          	sw	a0,-64(s0)
    80005d40:	06054863          	bltz	a0,80005db0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d44:	4691                	li	a3,4
    80005d46:	fc440613          	addi	a2,s0,-60
    80005d4a:	fd843583          	ld	a1,-40(s0)
    80005d4e:	68a8                	ld	a0,80(s1)
    80005d50:	ffffc097          	auipc	ra,0xffffc
    80005d54:	974080e7          	jalr	-1676(ra) # 800016c4 <copyout>
    80005d58:	02054063          	bltz	a0,80005d78 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d5c:	4691                	li	a3,4
    80005d5e:	fc040613          	addi	a2,s0,-64
    80005d62:	fd843583          	ld	a1,-40(s0)
    80005d66:	0591                	addi	a1,a1,4
    80005d68:	68a8                	ld	a0,80(s1)
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	95a080e7          	jalr	-1702(ra) # 800016c4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d72:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d74:	06055463          	bgez	a0,80005ddc <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d78:	fc442783          	lw	a5,-60(s0)
    80005d7c:	07e9                	addi	a5,a5,26
    80005d7e:	078e                	slli	a5,a5,0x3
    80005d80:	97a6                	add	a5,a5,s1
    80005d82:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d86:	fc042503          	lw	a0,-64(s0)
    80005d8a:	0569                	addi	a0,a0,26
    80005d8c:	050e                	slli	a0,a0,0x3
    80005d8e:	94aa                	add	s1,s1,a0
    80005d90:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d94:	fd043503          	ld	a0,-48(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	a08080e7          	jalr	-1528(ra) # 800047a0 <fileclose>
    fileclose(wf);
    80005da0:	fc843503          	ld	a0,-56(s0)
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	9fc080e7          	jalr	-1540(ra) # 800047a0 <fileclose>
    return -1;
    80005dac:	57fd                	li	a5,-1
    80005dae:	a03d                	j	80005ddc <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005db0:	fc442783          	lw	a5,-60(s0)
    80005db4:	0007c763          	bltz	a5,80005dc2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005db8:	07e9                	addi	a5,a5,26
    80005dba:	078e                	slli	a5,a5,0x3
    80005dbc:	94be                	add	s1,s1,a5
    80005dbe:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dc2:	fd043503          	ld	a0,-48(s0)
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	9da080e7          	jalr	-1574(ra) # 800047a0 <fileclose>
    fileclose(wf);
    80005dce:	fc843503          	ld	a0,-56(s0)
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	9ce080e7          	jalr	-1586(ra) # 800047a0 <fileclose>
    return -1;
    80005dda:	57fd                	li	a5,-1
}
    80005ddc:	853e                	mv	a0,a5
    80005dde:	70e2                	ld	ra,56(sp)
    80005de0:	7442                	ld	s0,48(sp)
    80005de2:	74a2                	ld	s1,40(sp)
    80005de4:	6121                	addi	sp,sp,64
    80005de6:	8082                	ret
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	cb9fc0ef          	jal	ra,80002ae8 <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	6d0c                	ld	a1,24(a0)
    80005e8c:	7110                	ld	a2,32(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	b14080e7          	jalr	-1260(ra) # 800019dc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	953e                	add	a0,a0,a5
    80005eec:	00052023          	sw	zero,0(a0)
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	adc080e7          	jalr	-1316(ra) # 800019dc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5179b          	slliw	a5,a0,0xd
    80005f0c:	0c201537          	lui	a0,0xc201
    80005f10:	953e                	add	a0,a0,a5
  return irq;
}
    80005f12:	4148                	lw	a0,4(a0)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	ab4080e7          	jalr	-1356(ra) # 800019dc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cc63          	blt	a5,a0,80005fa8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f54:	0001c797          	auipc	a5,0x1c
    80005f58:	f0c78793          	addi	a5,a5,-244 # 80021e60 <disk>
    80005f5c:	97aa                	add	a5,a5,a0
    80005f5e:	0187c783          	lbu	a5,24(a5)
    80005f62:	ebb9                	bnez	a5,80005fb8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f64:	00451613          	slli	a2,a0,0x4
    80005f68:	0001c797          	auipc	a5,0x1c
    80005f6c:	ef878793          	addi	a5,a5,-264 # 80021e60 <disk>
    80005f70:	6394                	ld	a3,0(a5)
    80005f72:	96b2                	add	a3,a3,a2
    80005f74:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f78:	6398                	ld	a4,0(a5)
    80005f7a:	9732                	add	a4,a4,a2
    80005f7c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f80:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f84:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	4785                	li	a5,1
    80005f8c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f90:	0001c517          	auipc	a0,0x1c
    80005f94:	ee850513          	addi	a0,a0,-280 # 80021e78 <disk+0x18>
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	194080e7          	jalr	404(ra) # 8000212c <wakeup>
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
    panic("free_desc 1");
    80005fa8:	00002517          	auipc	a0,0x2
    80005fac:	7f050513          	addi	a0,a0,2032 # 80008798 <syscalls+0x318>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	58e080e7          	jalr	1422(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005fb8:	00002517          	auipc	a0,0x2
    80005fbc:	7f050513          	addi	a0,a0,2032 # 800087a8 <syscalls+0x328>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	57e080e7          	jalr	1406(ra) # 8000053e <panic>

0000000080005fc8 <virtio_disk_init>:
{
    80005fc8:	1101                	addi	sp,sp,-32
    80005fca:	ec06                	sd	ra,24(sp)
    80005fcc:	e822                	sd	s0,16(sp)
    80005fce:	e426                	sd	s1,8(sp)
    80005fd0:	e04a                	sd	s2,0(sp)
    80005fd2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd4:	00002597          	auipc	a1,0x2
    80005fd8:	7e458593          	addi	a1,a1,2020 # 800087b8 <syscalls+0x338>
    80005fdc:	0001c517          	auipc	a0,0x1c
    80005fe0:	fac50513          	addi	a0,a0,-84 # 80021f88 <disk+0x128>
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	bbe080e7          	jalr	-1090(ra) # 80000ba2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fec:	100017b7          	lui	a5,0x10001
    80005ff0:	4398                	lw	a4,0(a5)
    80005ff2:	2701                	sext.w	a4,a4
    80005ff4:	747277b7          	lui	a5,0x74727
    80005ff8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ffc:	14f71c63          	bne	a4,a5,80006154 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006000:	100017b7          	lui	a5,0x10001
    80006004:	43dc                	lw	a5,4(a5)
    80006006:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006008:	4709                	li	a4,2
    8000600a:	14e79563          	bne	a5,a4,80006154 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	479c                	lw	a5,8(a5)
    80006014:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006016:	12e79f63          	bne	a5,a4,80006154 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	47d8                	lw	a4,12(a5)
    80006020:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006022:	554d47b7          	lui	a5,0x554d4
    80006026:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000602a:	12f71563          	bne	a4,a5,80006154 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	4705                	li	a4,1
    80006038:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603a:	470d                	li	a4,3
    8000603c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000603e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006040:	c7ffe737          	lui	a4,0xc7ffe
    80006044:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7bf>
    80006048:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000604a:	2701                	sext.w	a4,a4
    8000604c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604e:	472d                	li	a4,11
    80006050:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006052:	5bbc                	lw	a5,112(a5)
    80006054:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006058:	8ba1                	andi	a5,a5,8
    8000605a:	10078563          	beqz	a5,80006164 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006066:	43fc                	lw	a5,68(a5)
    80006068:	2781                	sext.w	a5,a5
    8000606a:	10079563          	bnez	a5,80006174 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000606e:	100017b7          	lui	a5,0x10001
    80006072:	5bdc                	lw	a5,52(a5)
    80006074:	2781                	sext.w	a5,a5
  if(max == 0)
    80006076:	10078763          	beqz	a5,80006184 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000607a:	471d                	li	a4,7
    8000607c:	10f77c63          	bgeu	a4,a5,80006194 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	a66080e7          	jalr	-1434(ra) # 80000ae6 <kalloc>
    80006088:	0001c497          	auipc	s1,0x1c
    8000608c:	dd848493          	addi	s1,s1,-552 # 80021e60 <disk>
    80006090:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	a54080e7          	jalr	-1452(ra) # 80000ae6 <kalloc>
    8000609a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	a4a080e7          	jalr	-1462(ra) # 80000ae6 <kalloc>
    800060a4:	87aa                	mv	a5,a0
    800060a6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060a8:	6088                	ld	a0,0(s1)
    800060aa:	cd6d                	beqz	a0,800061a4 <virtio_disk_init+0x1dc>
    800060ac:	0001c717          	auipc	a4,0x1c
    800060b0:	dbc73703          	ld	a4,-580(a4) # 80021e68 <disk+0x8>
    800060b4:	cb65                	beqz	a4,800061a4 <virtio_disk_init+0x1dc>
    800060b6:	c7fd                	beqz	a5,800061a4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800060b8:	6605                	lui	a2,0x1
    800060ba:	4581                	li	a1,0
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	c72080e7          	jalr	-910(ra) # 80000d2e <memset>
  memset(disk.avail, 0, PGSIZE);
    800060c4:	0001c497          	auipc	s1,0x1c
    800060c8:	d9c48493          	addi	s1,s1,-612 # 80021e60 <disk>
    800060cc:	6605                	lui	a2,0x1
    800060ce:	4581                	li	a1,0
    800060d0:	6488                	ld	a0,8(s1)
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	c5c080e7          	jalr	-932(ra) # 80000d2e <memset>
  memset(disk.used, 0, PGSIZE);
    800060da:	6605                	lui	a2,0x1
    800060dc:	4581                	li	a1,0
    800060de:	6888                	ld	a0,16(s1)
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	c4e080e7          	jalr	-946(ra) # 80000d2e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	4721                	li	a4,8
    800060ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060f0:	4098                	lw	a4,0(s1)
    800060f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060f6:	40d8                	lw	a4,4(s1)
    800060f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060fc:	6498                	ld	a4,8(s1)
    800060fe:	0007069b          	sext.w	a3,a4
    80006102:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006106:	9701                	srai	a4,a4,0x20
    80006108:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000610c:	6898                	ld	a4,16(s1)
    8000610e:	0007069b          	sext.w	a3,a4
    80006112:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006116:	9701                	srai	a4,a4,0x20
    80006118:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000611c:	4705                	li	a4,1
    8000611e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006120:	00e48c23          	sb	a4,24(s1)
    80006124:	00e48ca3          	sb	a4,25(s1)
    80006128:	00e48d23          	sb	a4,26(s1)
    8000612c:	00e48da3          	sb	a4,27(s1)
    80006130:	00e48e23          	sb	a4,28(s1)
    80006134:	00e48ea3          	sb	a4,29(s1)
    80006138:	00e48f23          	sb	a4,30(s1)
    8000613c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006140:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006144:	0727a823          	sw	s2,112(a5)
}
    80006148:	60e2                	ld	ra,24(sp)
    8000614a:	6442                	ld	s0,16(sp)
    8000614c:	64a2                	ld	s1,8(sp)
    8000614e:	6902                	ld	s2,0(sp)
    80006150:	6105                	addi	sp,sp,32
    80006152:	8082                	ret
    panic("could not find virtio disk");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	67450513          	addi	a0,a0,1652 # 800087c8 <syscalls+0x348>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	68450513          	addi	a0,a0,1668 # 800087e8 <syscalls+0x368>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	69450513          	addi	a0,a0,1684 # 80008808 <syscalls+0x388>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	6a450513          	addi	a0,a0,1700 # 80008828 <syscalls+0x3a8>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006194:	00002517          	auipc	a0,0x2
    80006198:	6b450513          	addi	a0,a0,1716 # 80008848 <syscalls+0x3c8>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800061a4:	00002517          	auipc	a0,0x2
    800061a8:	6c450513          	addi	a0,a0,1732 # 80008868 <syscalls+0x3e8>
    800061ac:	ffffa097          	auipc	ra,0xffffa
    800061b0:	392080e7          	jalr	914(ra) # 8000053e <panic>

00000000800061b4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b4:	7119                	addi	sp,sp,-128
    800061b6:	fc86                	sd	ra,120(sp)
    800061b8:	f8a2                	sd	s0,112(sp)
    800061ba:	f4a6                	sd	s1,104(sp)
    800061bc:	f0ca                	sd	s2,96(sp)
    800061be:	ecce                	sd	s3,88(sp)
    800061c0:	e8d2                	sd	s4,80(sp)
    800061c2:	e4d6                	sd	s5,72(sp)
    800061c4:	e0da                	sd	s6,64(sp)
    800061c6:	fc5e                	sd	s7,56(sp)
    800061c8:	f862                	sd	s8,48(sp)
    800061ca:	f466                	sd	s9,40(sp)
    800061cc:	f06a                	sd	s10,32(sp)
    800061ce:	ec6e                	sd	s11,24(sp)
    800061d0:	0100                	addi	s0,sp,128
    800061d2:	8aaa                	mv	s5,a0
    800061d4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d6:	00c52d03          	lw	s10,12(a0)
    800061da:	001d1d1b          	slliw	s10,s10,0x1
    800061de:	1d02                	slli	s10,s10,0x20
    800061e0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800061e4:	0001c517          	auipc	a0,0x1c
    800061e8:	da450513          	addi	a0,a0,-604 # 80021f88 <disk+0x128>
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	a46080e7          	jalr	-1466(ra) # 80000c32 <acquire>
  for(int i = 0; i < 3; i++){
    800061f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061f8:	0001cb97          	auipc	s7,0x1c
    800061fc:	c68b8b93          	addi	s7,s7,-920 # 80021e60 <disk>
  for(int i = 0; i < 3; i++){
    80006200:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006202:	0001cc97          	auipc	s9,0x1c
    80006206:	d86c8c93          	addi	s9,s9,-634 # 80021f88 <disk+0x128>
    8000620a:	a08d                	j	8000626c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000620c:	00fb8733          	add	a4,s7,a5
    80006210:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006214:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006216:	0207c563          	bltz	a5,80006240 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000621a:	2905                	addiw	s2,s2,1
    8000621c:	0611                	addi	a2,a2,4
    8000621e:	05690c63          	beq	s2,s6,80006276 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006222:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006224:	0001c717          	auipc	a4,0x1c
    80006228:	c3c70713          	addi	a4,a4,-964 # 80021e60 <disk>
    8000622c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000622e:	01874683          	lbu	a3,24(a4)
    80006232:	fee9                	bnez	a3,8000620c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006234:	2785                	addiw	a5,a5,1
    80006236:	0705                	addi	a4,a4,1
    80006238:	fe979be3          	bne	a5,s1,8000622e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000623c:	57fd                	li	a5,-1
    8000623e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006240:	01205d63          	blez	s2,8000625a <virtio_disk_rw+0xa6>
    80006244:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006246:	000a2503          	lw	a0,0(s4)
    8000624a:	00000097          	auipc	ra,0x0
    8000624e:	cfc080e7          	jalr	-772(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    80006252:	2d85                	addiw	s11,s11,1
    80006254:	0a11                	addi	s4,s4,4
    80006256:	ffb918e3          	bne	s2,s11,80006246 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000625a:	85e6                	mv	a1,s9
    8000625c:	0001c517          	auipc	a0,0x1c
    80006260:	c1c50513          	addi	a0,a0,-996 # 80021e78 <disk+0x18>
    80006264:	ffffc097          	auipc	ra,0xffffc
    80006268:	e64080e7          	jalr	-412(ra) # 800020c8 <sleep>
  for(int i = 0; i < 3; i++){
    8000626c:	f8040a13          	addi	s4,s0,-128
{
    80006270:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006272:	894e                	mv	s2,s3
    80006274:	b77d                	j	80006222 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006276:	f8042583          	lw	a1,-128(s0)
    8000627a:	00a58793          	addi	a5,a1,10
    8000627e:	0792                	slli	a5,a5,0x4

  if(write)
    80006280:	0001c617          	auipc	a2,0x1c
    80006284:	be060613          	addi	a2,a2,-1056 # 80021e60 <disk>
    80006288:	00f60733          	add	a4,a2,a5
    8000628c:	018036b3          	snez	a3,s8
    80006290:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006292:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006296:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000629a:	f6078693          	addi	a3,a5,-160
    8000629e:	6218                	ld	a4,0(a2)
    800062a0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062a2:	00878513          	addi	a0,a5,8
    800062a6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062a8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062aa:	6208                	ld	a0,0(a2)
    800062ac:	96aa                	add	a3,a3,a0
    800062ae:	4741                	li	a4,16
    800062b0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062b2:	4705                	li	a4,1
    800062b4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800062b8:	f8442703          	lw	a4,-124(s0)
    800062bc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062c0:	0712                	slli	a4,a4,0x4
    800062c2:	953a                	add	a0,a0,a4
    800062c4:	058a8693          	addi	a3,s5,88
    800062c8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800062ca:	6208                	ld	a0,0(a2)
    800062cc:	972a                	add	a4,a4,a0
    800062ce:	40000693          	li	a3,1024
    800062d2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062d4:	001c3c13          	seqz	s8,s8
    800062d8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062da:	001c6c13          	ori	s8,s8,1
    800062de:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800062e2:	f8842603          	lw	a2,-120(s0)
    800062e6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062ea:	0001c697          	auipc	a3,0x1c
    800062ee:	b7668693          	addi	a3,a3,-1162 # 80021e60 <disk>
    800062f2:	00258713          	addi	a4,a1,2
    800062f6:	0712                	slli	a4,a4,0x4
    800062f8:	9736                	add	a4,a4,a3
    800062fa:	587d                	li	a6,-1
    800062fc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006300:	0612                	slli	a2,a2,0x4
    80006302:	9532                	add	a0,a0,a2
    80006304:	f9078793          	addi	a5,a5,-112
    80006308:	97b6                	add	a5,a5,a3
    8000630a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000630c:	629c                	ld	a5,0(a3)
    8000630e:	97b2                	add	a5,a5,a2
    80006310:	4605                	li	a2,1
    80006312:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006314:	4509                	li	a0,2
    80006316:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000631a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000631e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006322:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006326:	6698                	ld	a4,8(a3)
    80006328:	00275783          	lhu	a5,2(a4)
    8000632c:	8b9d                	andi	a5,a5,7
    8000632e:	0786                	slli	a5,a5,0x1
    80006330:	97ba                	add	a5,a5,a4
    80006332:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006336:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000633a:	6698                	ld	a4,8(a3)
    8000633c:	00275783          	lhu	a5,2(a4)
    80006340:	2785                	addiw	a5,a5,1
    80006342:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006346:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000634a:	100017b7          	lui	a5,0x10001
    8000634e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006352:	004aa783          	lw	a5,4(s5)
    80006356:	02c79163          	bne	a5,a2,80006378 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000635a:	0001c917          	auipc	s2,0x1c
    8000635e:	c2e90913          	addi	s2,s2,-978 # 80021f88 <disk+0x128>
  while(b->disk == 1) {
    80006362:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006364:	85ca                	mv	a1,s2
    80006366:	8556                	mv	a0,s5
    80006368:	ffffc097          	auipc	ra,0xffffc
    8000636c:	d60080e7          	jalr	-672(ra) # 800020c8 <sleep>
  while(b->disk == 1) {
    80006370:	004aa783          	lw	a5,4(s5)
    80006374:	fe9788e3          	beq	a5,s1,80006364 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006378:	f8042903          	lw	s2,-128(s0)
    8000637c:	00290793          	addi	a5,s2,2
    80006380:	00479713          	slli	a4,a5,0x4
    80006384:	0001c797          	auipc	a5,0x1c
    80006388:	adc78793          	addi	a5,a5,-1316 # 80021e60 <disk>
    8000638c:	97ba                	add	a5,a5,a4
    8000638e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006392:	0001c997          	auipc	s3,0x1c
    80006396:	ace98993          	addi	s3,s3,-1330 # 80021e60 <disk>
    8000639a:	00491713          	slli	a4,s2,0x4
    8000639e:	0009b783          	ld	a5,0(s3)
    800063a2:	97ba                	add	a5,a5,a4
    800063a4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063a8:	854a                	mv	a0,s2
    800063aa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063ae:	00000097          	auipc	ra,0x0
    800063b2:	b98080e7          	jalr	-1128(ra) # 80005f46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063b6:	8885                	andi	s1,s1,1
    800063b8:	f0ed                	bnez	s1,8000639a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ba:	0001c517          	auipc	a0,0x1c
    800063be:	bce50513          	addi	a0,a0,-1074 # 80021f88 <disk+0x128>
    800063c2:	ffffb097          	auipc	ra,0xffffb
    800063c6:	924080e7          	jalr	-1756(ra) # 80000ce6 <release>
}
    800063ca:	70e6                	ld	ra,120(sp)
    800063cc:	7446                	ld	s0,112(sp)
    800063ce:	74a6                	ld	s1,104(sp)
    800063d0:	7906                	ld	s2,96(sp)
    800063d2:	69e6                	ld	s3,88(sp)
    800063d4:	6a46                	ld	s4,80(sp)
    800063d6:	6aa6                	ld	s5,72(sp)
    800063d8:	6b06                	ld	s6,64(sp)
    800063da:	7be2                	ld	s7,56(sp)
    800063dc:	7c42                	ld	s8,48(sp)
    800063de:	7ca2                	ld	s9,40(sp)
    800063e0:	7d02                	ld	s10,32(sp)
    800063e2:	6de2                	ld	s11,24(sp)
    800063e4:	6109                	addi	sp,sp,128
    800063e6:	8082                	ret

00000000800063e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063e8:	1101                	addi	sp,sp,-32
    800063ea:	ec06                	sd	ra,24(sp)
    800063ec:	e822                	sd	s0,16(sp)
    800063ee:	e426                	sd	s1,8(sp)
    800063f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063f2:	0001c497          	auipc	s1,0x1c
    800063f6:	a6e48493          	addi	s1,s1,-1426 # 80021e60 <disk>
    800063fa:	0001c517          	auipc	a0,0x1c
    800063fe:	b8e50513          	addi	a0,a0,-1138 # 80021f88 <disk+0x128>
    80006402:	ffffb097          	auipc	ra,0xffffb
    80006406:	830080e7          	jalr	-2000(ra) # 80000c32 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000640a:	10001737          	lui	a4,0x10001
    8000640e:	533c                	lw	a5,96(a4)
    80006410:	8b8d                	andi	a5,a5,3
    80006412:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006414:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006418:	689c                	ld	a5,16(s1)
    8000641a:	0204d703          	lhu	a4,32(s1)
    8000641e:	0027d783          	lhu	a5,2(a5)
    80006422:	04f70863          	beq	a4,a5,80006472 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006426:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000642a:	6898                	ld	a4,16(s1)
    8000642c:	0204d783          	lhu	a5,32(s1)
    80006430:	8b9d                	andi	a5,a5,7
    80006432:	078e                	slli	a5,a5,0x3
    80006434:	97ba                	add	a5,a5,a4
    80006436:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006438:	00278713          	addi	a4,a5,2
    8000643c:	0712                	slli	a4,a4,0x4
    8000643e:	9726                	add	a4,a4,s1
    80006440:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006444:	e721                	bnez	a4,8000648c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006446:	0789                	addi	a5,a5,2
    80006448:	0792                	slli	a5,a5,0x4
    8000644a:	97a6                	add	a5,a5,s1
    8000644c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000644e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	cda080e7          	jalr	-806(ra) # 8000212c <wakeup>

    disk.used_idx += 1;
    8000645a:	0204d783          	lhu	a5,32(s1)
    8000645e:	2785                	addiw	a5,a5,1
    80006460:	17c2                	slli	a5,a5,0x30
    80006462:	93c1                	srli	a5,a5,0x30
    80006464:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006468:	6898                	ld	a4,16(s1)
    8000646a:	00275703          	lhu	a4,2(a4)
    8000646e:	faf71ce3          	bne	a4,a5,80006426 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006472:	0001c517          	auipc	a0,0x1c
    80006476:	b1650513          	addi	a0,a0,-1258 # 80021f88 <disk+0x128>
    8000647a:	ffffb097          	auipc	ra,0xffffb
    8000647e:	86c080e7          	jalr	-1940(ra) # 80000ce6 <release>
}
    80006482:	60e2                	ld	ra,24(sp)
    80006484:	6442                	ld	s0,16(sp)
    80006486:	64a2                	ld	s1,8(sp)
    80006488:	6105                	addi	sp,sp,32
    8000648a:	8082                	ret
      panic("virtio_disk_intr status");
    8000648c:	00002517          	auipc	a0,0x2
    80006490:	3f450513          	addi	a0,a0,1012 # 80008880 <syscalls+0x400>
    80006494:	ffffa097          	auipc	ra,0xffffa
    80006498:	0aa080e7          	jalr	170(ra) # 8000053e <panic>
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
