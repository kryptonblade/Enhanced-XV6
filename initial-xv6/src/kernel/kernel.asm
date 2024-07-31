
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
    80000068:	ebc78793          	addi	a5,a5,-324 # 80005f20 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbe9f>
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
    800001cc:	1ac080e7          	jalr	428(ra) # 80002374 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	eea080e7          	jalr	-278(ra) # 800020c0 <sleep>
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
    800002f6:	28e080e7          	jalr	654(ra) # 80002580 <procdump>
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
    8000044a:	cde080e7          	jalr	-802(ra) # 80002124 <wakeup>
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
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	35078793          	addi	a5,a5,848 # 800217c8 <devsw>
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
    80000896:	892080e7          	jalr	-1902(ra) # 80002124 <wakeup>
    
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
    80000920:	7a4080e7          	jalr	1956(ra) # 800020c0 <sleep>
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
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	f6278793          	addi	a5,a5,-158 # 80022960 <end>
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
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	e9250513          	addi	a0,a0,-366 # 80022960 <end>
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
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	9ac080e7          	jalr	-1620(ra) # 8000286a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	09a080e7          	jalr	154(ra) # 80005f60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe8080e7          	jalr	-24(ra) # 80001eb6 <scheduler>
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
    80000f3a:	90c080e7          	jalr	-1780(ra) # 80002842 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	92c080e7          	jalr	-1748(ra) # 8000286a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	004080e7          	jalr	4(ra) # 80005f4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	012080e7          	jalr	18(ra) # 80005f60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	110080e7          	jalr	272(ra) # 80003066 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	7b4080e7          	jalr	1972(ra) # 80003712 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	752080e7          	jalr	1874(ra) # 800046b8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	0fa080e7          	jalr	250(ra) # 80006068 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d22080e7          	jalr	-734(ra) # 80001c98 <userinit>
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
void proc_mapstacks(pagetable_t kpgtbl)
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

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	d1aa0a13          	addi	s4,s4,-742 # 80017580 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
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
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19848493          	addi	s1,s1,408
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
void procinit(void)
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
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	67048493          	addi	s1,s1,1648 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	c4e98993          	addi	s3,s3,-946 # 80017580 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	19848493          	addi	s1,s1,408
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
int cpuid()
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
struct cpu *
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
struct proc *
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
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
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

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e7c080e7          	jalr	-388(ra) # 80002882 <usertrapret>
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
    80001a24:	c72080e7          	jalr	-910(ra) # 80003692 <fsinit>
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
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
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
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
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
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
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
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3be48493          	addi	s1,s1,958 # 80010f80 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	9b690913          	addi	s2,s2,-1610 # 80017580 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	19848493          	addi	s1,s1,408
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a09d                	j	80001c5a <allocproc+0xa4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd21                	beqz	a0,80001c68 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c125                	beqz	a0,80001c80 <allocproc+0xca>
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
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	c927a783          	lw	a5,-878(a5) # 800088e0 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef4080e7          	jalr	-268(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	016080e7          	jalr	22(ra) # 80000c8a <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa4>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa4>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f14080e7          	jalr	-236(ra) # 80001bb6 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c2a7b623          	sd	a0,-980(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	bb858593          	addi	a1,a1,-1096 # 80008870 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	694080e7          	jalr	1684(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	136080e7          	jalr	310(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	3be080e7          	jalr	958(ra) # 800040b4 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f82080e7          	jalr	-126(ra) # 80000c8a <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80001d30:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d34:	01204c63          	bgtz	s2,80001d4c <growproc+0x32>
  else if (n < 0)
    80001d38:	02094663          	bltz	s2,80001d64 <growproc+0x4a>
  p->sz = sz;
    80001d3c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d4c:	4691                	li	a3,4
    80001d4e:	00b90633          	add	a2,s2,a1
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6bc080e7          	jalr	1724(ra) # 80001410 <uvmalloc>
    80001d5c:	85aa                	mv	a1,a0
    80001d5e:	fd79                	bnez	a0,80001d3c <growproc+0x22>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bff9                	j	80001d40 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	00b90633          	add	a2,s2,a1
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	65e080e7          	jalr	1630(ra) # 800013c8 <uvmdealloc>
    80001d72:	85aa                	mv	a1,a0
    80001d74:	b7e1                	j	80001d3c <growproc+0x22>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e24080e7          	jalr	-476(ra) # 80001bb6 <allocproc>
    80001d9a:	10050c63          	beqz	a0,80001eb2 <fork+0x13c>
    80001d9e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001da0:	048ab603          	ld	a2,72(s5)
    80001da4:	692c                	ld	a1,80(a0)
    80001da6:	050ab503          	ld	a0,80(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7ba080e7          	jalr	1978(ra) # 80001564 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	048ab783          	ld	a5,72(s5)
    80001dba:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	058ab683          	ld	a3,88(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	058a3703          	ld	a4,88(s4)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	058a3783          	ld	a5,88(s4)
    80001df0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001df4:	0d0a8493          	addi	s1,s5,208
    80001df8:	0d0a0913          	addi	s2,s4,208
    80001dfc:	150a8993          	addi	s3,s5,336
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	8552                	mv	a0,s4
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d5a080e7          	jalr	-678(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e0c:	8552                	mv	a0,s4
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a059                	j	80001e9e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01348b63          	beq	s1,s3,80001e34 <fork+0xbe>
    if (p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	924080e7          	jalr	-1756(ra) # 8000474a <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	150ab503          	ld	a0,336(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	a98080e7          	jalr	-1384(ra) # 800038d0 <idup>
    80001e40:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	158a8593          	addi	a1,s5,344
    80001e4a:	158a0513          	addi	a0,s4,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	d0448493          	addi	s1,s1,-764 # 80010b68 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	b7ed                	j	80001e9e <fork+0x128>

0000000080001eb6 <scheduler>:
{
    80001eb6:	715d                	addi	sp,sp,-80
    80001eb8:	e486                	sd	ra,72(sp)
    80001eba:	e0a2                	sd	s0,64(sp)
    80001ebc:	fc26                	sd	s1,56(sp)
    80001ebe:	f84a                	sd	s2,48(sp)
    80001ec0:	f44e                	sd	s3,40(sp)
    80001ec2:	f052                	sd	s4,32(sp)
    80001ec4:	ec56                	sd	s5,24(sp)
    80001ec6:	e85a                	sd	s6,16(sp)
    80001ec8:	e45e                	sd	s7,8(sp)
    80001eca:	e062                	sd	s8,0(sp)
    80001ecc:	0880                	addi	s0,sp,80
    80001ece:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed2:	00779693          	slli	a3,a5,0x7
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	c7a70713          	addi	a4,a4,-902 # 80010b50 <pid_lock>
    80001ede:	9736                	add	a4,a4,a3
    80001ee0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee4:	0000f717          	auipc	a4,0xf
    80001ee8:	ca470713          	addi	a4,a4,-860 # 80010b88 <cpus+0x8>
    80001eec:	00e68c33          	add	s8,a3,a4
    struct proc *selected = 0;
    80001ef0:	4a81                	li	s5,0
      if (p->state != RUNNABLE)
    80001ef2:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001ef4:	00015a17          	auipc	s4,0x15
    80001ef8:	68ca0a13          	addi	s4,s4,1676 # 80017580 <tickslock>
        p->state = RUNNING;
    80001efc:	4b91                	li	s7,4
        c->proc = p;
    80001efe:	0000fb17          	auipc	s6,0xf
    80001f02:	c52b0b13          	addi	s6,s6,-942 # 80010b50 <pid_lock>
    80001f06:	9b36                	add	s6,s6,a3
    80001f08:	a0a9                	j	80001f52 <scheduler+0x9c>
        release(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d7e080e7          	jalr	-642(ra) # 80000c8a <release>
        continue;
    80001f14:	a039                	j	80001f22 <scheduler+0x6c>
    80001f16:	8926                	mv	s2,s1
      release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f22:	19848493          	addi	s1,s1,408
    80001f26:	03448463          	beq	s1,s4,80001f4e <scheduler+0x98>
      acquire(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
      if (p->state != RUNNABLE)
    80001f34:	4c9c                	lw	a5,24(s1)
    80001f36:	fd379ae3          	bne	a5,s3,80001f0a <scheduler+0x54>
      if (selected == 0 || p->ctime < selected->ctime)
    80001f3a:	fc090ee3          	beqz	s2,80001f16 <scheduler+0x60>
    80001f3e:	16c4a703          	lw	a4,364(s1)
    80001f42:	16c92783          	lw	a5,364(s2)
    80001f46:	fcf779e3          	bgeu	a4,a5,80001f18 <scheduler+0x62>
    80001f4a:	8926                	mv	s2,s1
    80001f4c:	b7f1                	j	80001f18 <scheduler+0x62>
    if (p != 0)
    80001f4e:	02091363          	bnez	s2,80001f74 <scheduler+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5a:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001f62:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f64:	10079073          	csrw	sstatus,a5
    struct proc *selected = 0;
    80001f68:	8956                	mv	s2,s5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f6a:	0000f497          	auipc	s1,0xf
    80001f6e:	01648493          	addi	s1,s1,22 # 80010f80 <proc>
    80001f72:	bf65                	j	80001f2a <scheduler+0x74>
      acquire(&p->lock);
    80001f74:	84ca                	mv	s1,s2
    80001f76:	854a                	mv	a0,s2
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	c5e080e7          	jalr	-930(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f80:	01892783          	lw	a5,24(s2)
    80001f84:	01379f63          	bne	a5,s3,80001fa2 <scheduler+0xec>
        p->state = RUNNING;
    80001f88:	01792c23          	sw	s7,24(s2)
        c->proc = p;
    80001f8c:	032b3823          	sd	s2,48(s6)
        swtch(&c->context, &p->context);
    80001f90:	06090593          	addi	a1,s2,96
    80001f94:	8562                	mv	a0,s8
    80001f96:	00001097          	auipc	ra,0x1
    80001f9a:	842080e7          	jalr	-1982(ra) # 800027d8 <swtch>
        c->proc = 0;
    80001f9e:	020b3823          	sd	zero,48(s6)
      release(&p->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	ce6080e7          	jalr	-794(ra) # 80000c8a <release>
    80001fac:	b75d                	j	80001f52 <scheduler+0x9c>

0000000080001fae <sched>:
{
    80001fae:	7179                	addi	sp,sp,-48
    80001fb0:	f406                	sd	ra,40(sp)
    80001fb2:	f022                	sd	s0,32(sp)
    80001fb4:	ec26                	sd	s1,24(sp)
    80001fb6:	e84a                	sd	s2,16(sp)
    80001fb8:	e44e                	sd	s3,8(sp)
    80001fba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	9f0080e7          	jalr	-1552(ra) # 800019ac <myproc>
    80001fc4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	b96080e7          	jalr	-1130(ra) # 80000b5c <holding>
    80001fce:	c93d                	beqz	a0,80002044 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	0000f717          	auipc	a4,0xf
    80001fda:	b7a70713          	addi	a4,a4,-1158 # 80010b50 <pid_lock>
    80001fde:	97ba                	add	a5,a5,a4
    80001fe0:	0a87a703          	lw	a4,168(a5)
    80001fe4:	4785                	li	a5,1
    80001fe6:	06f71763          	bne	a4,a5,80002054 <sched+0xa6>
  if (p->state == RUNNING)
    80001fea:	4c98                	lw	a4,24(s1)
    80001fec:	4791                	li	a5,4
    80001fee:	06f70b63          	beq	a4,a5,80002064 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff6:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001ff8:	efb5                	bnez	a5,80002074 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ffc:	0000f917          	auipc	s2,0xf
    80002000:	b5490913          	addi	s2,s2,-1196 # 80010b50 <pid_lock>
    80002004:	2781                	sext.w	a5,a5
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	97ca                	add	a5,a5,s2
    8000200a:	0ac7a983          	lw	s3,172(a5)
    8000200e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	0000f597          	auipc	a1,0xf
    80002018:	b7458593          	addi	a1,a1,-1164 # 80010b88 <cpus+0x8>
    8000201c:	95be                	add	a1,a1,a5
    8000201e:	06048513          	addi	a0,s1,96
    80002022:	00000097          	auipc	ra,0x0
    80002026:	7b6080e7          	jalr	1974(ra) # 800027d8 <swtch>
    8000202a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	97ca                	add	a5,a5,s2
    80002032:	0b37a623          	sw	s3,172(a5)
}
    80002036:	70a2                	ld	ra,40(sp)
    80002038:	7402                	ld	s0,32(sp)
    8000203a:	64e2                	ld	s1,24(sp)
    8000203c:	6942                	ld	s2,16(sp)
    8000203e:	69a2                	ld	s3,8(sp)
    80002040:	6145                	addi	sp,sp,48
    80002042:	8082                	ret
    panic("sched p->lock");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	1d450513          	addi	a0,a0,468 # 80008218 <digits+0x1d8>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    panic("sched locks");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1d450513          	addi	a0,a0,468 # 80008228 <digits+0x1e8>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
    panic("sched running");
    80002064:	00006517          	auipc	a0,0x6
    80002068:	1d450513          	addi	a0,a0,468 # 80008238 <digits+0x1f8>
    8000206c:	ffffe097          	auipc	ra,0xffffe
    80002070:	4d2080e7          	jalr	1234(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002074:	00006517          	auipc	a0,0x6
    80002078:	1d450513          	addi	a0,a0,468 # 80008248 <digits+0x208>
    8000207c:	ffffe097          	auipc	ra,0xffffe
    80002080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>

0000000080002084 <yield>:
{
    80002084:	1101                	addi	sp,sp,-32
    80002086:	ec06                	sd	ra,24(sp)
    80002088:	e822                	sd	s0,16(sp)
    8000208a:	e426                	sd	s1,8(sp)
    8000208c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	91e080e7          	jalr	-1762(ra) # 800019ac <myproc>
    80002096:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	b3e080e7          	jalr	-1218(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020a0:	478d                	li	a5,3
    800020a2:	cc9c                	sw	a5,24(s1)
  sched();
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	f0a080e7          	jalr	-246(ra) # 80001fae <sched>
  release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bdc080e7          	jalr	-1060(ra) # 80000c8a <release>
}
    800020b6:	60e2                	ld	ra,24(sp)
    800020b8:	6442                	ld	s0,16(sp)
    800020ba:	64a2                	ld	s1,8(sp)
    800020bc:	6105                	addi	sp,sp,32
    800020be:	8082                	ret

00000000800020c0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020c0:	7179                	addi	sp,sp,-48
    800020c2:	f406                	sd	ra,40(sp)
    800020c4:	f022                	sd	s0,32(sp)
    800020c6:	ec26                	sd	s1,24(sp)
    800020c8:	e84a                	sd	s2,16(sp)
    800020ca:	e44e                	sd	s3,8(sp)
    800020cc:	1800                	addi	s0,sp,48
    800020ce:	89aa                	mv	s3,a0
    800020d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	8da080e7          	jalr	-1830(ra) # 800019ac <myproc>
    800020da:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	afa080e7          	jalr	-1286(ra) # 80000bd6 <acquire>
  release(lk);
    800020e4:	854a                	mv	a0,s2
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	ba4080e7          	jalr	-1116(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020ee:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020f2:	4789                	li	a5,2
    800020f4:	cc9c                	sw	a5,24(s1)

  sched();
    800020f6:	00000097          	auipc	ra,0x0
    800020fa:	eb8080e7          	jalr	-328(ra) # 80001fae <sched>

  // Tidy up.
  p->chan = 0;
    800020fe:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b86080e7          	jalr	-1146(ra) # 80000c8a <release>
  acquire(lk);
    8000210c:	854a                	mv	a0,s2
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
}
    80002116:	70a2                	ld	ra,40(sp)
    80002118:	7402                	ld	s0,32(sp)
    8000211a:	64e2                	ld	s1,24(sp)
    8000211c:	6942                	ld	s2,16(sp)
    8000211e:	69a2                	ld	s3,8(sp)
    80002120:	6145                	addi	sp,sp,48
    80002122:	8082                	ret

0000000080002124 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002124:	7139                	addi	sp,sp,-64
    80002126:	fc06                	sd	ra,56(sp)
    80002128:	f822                	sd	s0,48(sp)
    8000212a:	f426                	sd	s1,40(sp)
    8000212c:	f04a                	sd	s2,32(sp)
    8000212e:	ec4e                	sd	s3,24(sp)
    80002130:	e852                	sd	s4,16(sp)
    80002132:	e456                	sd	s5,8(sp)
    80002134:	0080                	addi	s0,sp,64
    80002136:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002138:	0000f497          	auipc	s1,0xf
    8000213c:	e4848493          	addi	s1,s1,-440 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002140:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002142:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002144:	00015917          	auipc	s2,0x15
    80002148:	43c90913          	addi	s2,s2,1084 # 80017580 <tickslock>
    8000214c:	a811                	j	80002160 <wakeup+0x3c>
      }
      release(&p->lock);
    8000214e:	8526                	mv	a0,s1
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b3a080e7          	jalr	-1222(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002158:	19848493          	addi	s1,s1,408
    8000215c:	03248663          	beq	s1,s2,80002188 <wakeup+0x64>
    if (p != myproc())
    80002160:	00000097          	auipc	ra,0x0
    80002164:	84c080e7          	jalr	-1972(ra) # 800019ac <myproc>
    80002168:	fea488e3          	beq	s1,a0,80002158 <wakeup+0x34>
      acquire(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	a68080e7          	jalr	-1432(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002176:	4c9c                	lw	a5,24(s1)
    80002178:	fd379be3          	bne	a5,s3,8000214e <wakeup+0x2a>
    8000217c:	709c                	ld	a5,32(s1)
    8000217e:	fd4798e3          	bne	a5,s4,8000214e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002182:	0154ac23          	sw	s5,24(s1)
    80002186:	b7e1                	j	8000214e <wakeup+0x2a>
    }
  }
}
    80002188:	70e2                	ld	ra,56(sp)
    8000218a:	7442                	ld	s0,48(sp)
    8000218c:	74a2                	ld	s1,40(sp)
    8000218e:	7902                	ld	s2,32(sp)
    80002190:	69e2                	ld	s3,24(sp)
    80002192:	6a42                	ld	s4,16(sp)
    80002194:	6aa2                	ld	s5,8(sp)
    80002196:	6121                	addi	sp,sp,64
    80002198:	8082                	ret

000000008000219a <reparent>:
{
    8000219a:	7179                	addi	sp,sp,-48
    8000219c:	f406                	sd	ra,40(sp)
    8000219e:	f022                	sd	s0,32(sp)
    800021a0:	ec26                	sd	s1,24(sp)
    800021a2:	e84a                	sd	s2,16(sp)
    800021a4:	e44e                	sd	s3,8(sp)
    800021a6:	e052                	sd	s4,0(sp)
    800021a8:	1800                	addi	s0,sp,48
    800021aa:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021ac:	0000f497          	auipc	s1,0xf
    800021b0:	dd448493          	addi	s1,s1,-556 # 80010f80 <proc>
      pp->parent = initproc;
    800021b4:	00006a17          	auipc	s4,0x6
    800021b8:	724a0a13          	addi	s4,s4,1828 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021bc:	00015997          	auipc	s3,0x15
    800021c0:	3c498993          	addi	s3,s3,964 # 80017580 <tickslock>
    800021c4:	a029                	j	800021ce <reparent+0x34>
    800021c6:	19848493          	addi	s1,s1,408
    800021ca:	01348d63          	beq	s1,s3,800021e4 <reparent+0x4a>
    if (pp->parent == p)
    800021ce:	7c9c                	ld	a5,56(s1)
    800021d0:	ff279be3          	bne	a5,s2,800021c6 <reparent+0x2c>
      pp->parent = initproc;
    800021d4:	000a3503          	ld	a0,0(s4)
    800021d8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021da:	00000097          	auipc	ra,0x0
    800021de:	f4a080e7          	jalr	-182(ra) # 80002124 <wakeup>
    800021e2:	b7d5                	j	800021c6 <reparent+0x2c>
}
    800021e4:	70a2                	ld	ra,40(sp)
    800021e6:	7402                	ld	s0,32(sp)
    800021e8:	64e2                	ld	s1,24(sp)
    800021ea:	6942                	ld	s2,16(sp)
    800021ec:	69a2                	ld	s3,8(sp)
    800021ee:	6a02                	ld	s4,0(sp)
    800021f0:	6145                	addi	sp,sp,48
    800021f2:	8082                	ret

00000000800021f4 <exit>:
{
    800021f4:	7179                	addi	sp,sp,-48
    800021f6:	f406                	sd	ra,40(sp)
    800021f8:	f022                	sd	s0,32(sp)
    800021fa:	ec26                	sd	s1,24(sp)
    800021fc:	e84a                	sd	s2,16(sp)
    800021fe:	e44e                	sd	s3,8(sp)
    80002200:	e052                	sd	s4,0(sp)
    80002202:	1800                	addi	s0,sp,48
    80002204:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	7a6080e7          	jalr	1958(ra) # 800019ac <myproc>
    8000220e:	89aa                	mv	s3,a0
  if (p == initproc)
    80002210:	00006797          	auipc	a5,0x6
    80002214:	6c87b783          	ld	a5,1736(a5) # 800088d8 <initproc>
    80002218:	0d050493          	addi	s1,a0,208
    8000221c:	15050913          	addi	s2,a0,336
    80002220:	02a79363          	bne	a5,a0,80002246 <exit+0x52>
    panic("init exiting");
    80002224:	00006517          	auipc	a0,0x6
    80002228:	03c50513          	addi	a0,a0,60 # 80008260 <digits+0x220>
    8000222c:	ffffe097          	auipc	ra,0xffffe
    80002230:	312080e7          	jalr	786(ra) # 8000053e <panic>
      fileclose(f);
    80002234:	00002097          	auipc	ra,0x2
    80002238:	568080e7          	jalr	1384(ra) # 8000479c <fileclose>
      p->ofile[fd] = 0;
    8000223c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002240:	04a1                	addi	s1,s1,8
    80002242:	01248563          	beq	s1,s2,8000224c <exit+0x58>
    if (p->ofile[fd])
    80002246:	6088                	ld	a0,0(s1)
    80002248:	f575                	bnez	a0,80002234 <exit+0x40>
    8000224a:	bfdd                	j	80002240 <exit+0x4c>
  begin_op();
    8000224c:	00002097          	auipc	ra,0x2
    80002250:	084080e7          	jalr	132(ra) # 800042d0 <begin_op>
  iput(p->cwd);
    80002254:	1509b503          	ld	a0,336(s3)
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	870080e7          	jalr	-1936(ra) # 80003ac8 <iput>
  end_op();
    80002260:	00002097          	auipc	ra,0x2
    80002264:	0f0080e7          	jalr	240(ra) # 80004350 <end_op>
  p->cwd = 0;
    80002268:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000226c:	0000f497          	auipc	s1,0xf
    80002270:	8fc48493          	addi	s1,s1,-1796 # 80010b68 <wait_lock>
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
  reparent(p);
    8000227e:	854e                	mv	a0,s3
    80002280:	00000097          	auipc	ra,0x0
    80002284:	f1a080e7          	jalr	-230(ra) # 8000219a <reparent>
  wakeup(p->parent);
    80002288:	0389b503          	ld	a0,56(s3)
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	e98080e7          	jalr	-360(ra) # 80002124 <wakeup>
  acquire(&p->lock);
    80002294:	854e                	mv	a0,s3
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	940080e7          	jalr	-1728(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000229e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022a2:	4795                	li	a5,5
    800022a4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022a8:	00006797          	auipc	a5,0x6
    800022ac:	6387a783          	lw	a5,1592(a5) # 800088e0 <ticks>
    800022b0:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	9d4080e7          	jalr	-1580(ra) # 80000c8a <release>
  sched();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	cf0080e7          	jalr	-784(ra) # 80001fae <sched>
  panic("zombie exit");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	faa50513          	addi	a0,a0,-86 # 80008270 <digits+0x230>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	270080e7          	jalr	624(ra) # 8000053e <panic>

00000000800022d6 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022d6:	7179                	addi	sp,sp,-48
    800022d8:	f406                	sd	ra,40(sp)
    800022da:	f022                	sd	s0,32(sp)
    800022dc:	ec26                	sd	s1,24(sp)
    800022de:	e84a                	sd	s2,16(sp)
    800022e0:	e44e                	sd	s3,8(sp)
    800022e2:	1800                	addi	s0,sp,48
    800022e4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022e6:	0000f497          	auipc	s1,0xf
    800022ea:	c9a48493          	addi	s1,s1,-870 # 80010f80 <proc>
    800022ee:	00015997          	auipc	s3,0x15
    800022f2:	29298993          	addi	s3,s3,658 # 80017580 <tickslock>
  {
    acquire(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	8de080e7          	jalr	-1826(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002300:	589c                	lw	a5,48(s1)
    80002302:	01278d63          	beq	a5,s2,8000231c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	982080e7          	jalr	-1662(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002310:	19848493          	addi	s1,s1,408
    80002314:	ff3491e3          	bne	s1,s3,800022f6 <kill+0x20>
  }
  return -1;
    80002318:	557d                	li	a0,-1
    8000231a:	a829                	j	80002334 <kill+0x5e>
      p->killed = 1;
    8000231c:	4785                	li	a5,1
    8000231e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002320:	4c98                	lw	a4,24(s1)
    80002322:	4789                	li	a5,2
    80002324:	00f70f63          	beq	a4,a5,80002342 <kill+0x6c>
      release(&p->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
      return 0;
    80002332:	4501                	li	a0,0
}
    80002334:	70a2                	ld	ra,40(sp)
    80002336:	7402                	ld	s0,32(sp)
    80002338:	64e2                	ld	s1,24(sp)
    8000233a:	6942                	ld	s2,16(sp)
    8000233c:	69a2                	ld	s3,8(sp)
    8000233e:	6145                	addi	sp,sp,48
    80002340:	8082                	ret
        p->state = RUNNABLE;
    80002342:	478d                	li	a5,3
    80002344:	cc9c                	sw	a5,24(s1)
    80002346:	b7cd                	j	80002328 <kill+0x52>

0000000080002348 <setkilled>:

void setkilled(struct proc *p)
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	1000                	addi	s0,sp,32
    80002352:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	882080e7          	jalr	-1918(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000235c:	4785                	li	a5,1
    8000235e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
}
    8000236a:	60e2                	ld	ra,24(sp)
    8000236c:	6442                	ld	s0,16(sp)
    8000236e:	64a2                	ld	s1,8(sp)
    80002370:	6105                	addi	sp,sp,32
    80002372:	8082                	ret

0000000080002374 <killed>:

int killed(struct proc *p)
{
    80002374:	1101                	addi	sp,sp,-32
    80002376:	ec06                	sd	ra,24(sp)
    80002378:	e822                	sd	s0,16(sp)
    8000237a:	e426                	sd	s1,8(sp)
    8000237c:	e04a                	sd	s2,0(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	854080e7          	jalr	-1964(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000238a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8fa080e7          	jalr	-1798(ra) # 80000c8a <release>
  return k;
}
    80002398:	854a                	mv	a0,s2
    8000239a:	60e2                	ld	ra,24(sp)
    8000239c:	6442                	ld	s0,16(sp)
    8000239e:	64a2                	ld	s1,8(sp)
    800023a0:	6902                	ld	s2,0(sp)
    800023a2:	6105                	addi	sp,sp,32
    800023a4:	8082                	ret

00000000800023a6 <wait>:
{
    800023a6:	715d                	addi	sp,sp,-80
    800023a8:	e486                	sd	ra,72(sp)
    800023aa:	e0a2                	sd	s0,64(sp)
    800023ac:	fc26                	sd	s1,56(sp)
    800023ae:	f84a                	sd	s2,48(sp)
    800023b0:	f44e                	sd	s3,40(sp)
    800023b2:	f052                	sd	s4,32(sp)
    800023b4:	ec56                	sd	s5,24(sp)
    800023b6:	e85a                	sd	s6,16(sp)
    800023b8:	e45e                	sd	s7,8(sp)
    800023ba:	e062                	sd	s8,0(sp)
    800023bc:	0880                	addi	s0,sp,80
    800023be:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	5ec080e7          	jalr	1516(ra) # 800019ac <myproc>
    800023c8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ca:	0000e517          	auipc	a0,0xe
    800023ce:	79e50513          	addi	a0,a0,1950 # 80010b68 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	804080e7          	jalr	-2044(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023da:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023dc:	4a15                	li	s4,5
        havekids = 1;
    800023de:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023e0:	00015997          	auipc	s3,0x15
    800023e4:	1a098993          	addi	s3,s3,416 # 80017580 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023e8:	0000ec17          	auipc	s8,0xe
    800023ec:	780c0c13          	addi	s8,s8,1920 # 80010b68 <wait_lock>
    havekids = 0;
    800023f0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023f2:	0000f497          	auipc	s1,0xf
    800023f6:	b8e48493          	addi	s1,s1,-1138 # 80010f80 <proc>
    800023fa:	a0bd                	j	80002468 <wait+0xc2>
          pid = pp->pid;
    800023fc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002400:	000b0e63          	beqz	s6,8000241c <wait+0x76>
    80002404:	4691                	li	a3,4
    80002406:	02c48613          	addi	a2,s1,44
    8000240a:	85da                	mv	a1,s6
    8000240c:	05093503          	ld	a0,80(s2)
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	258080e7          	jalr	600(ra) # 80001668 <copyout>
    80002418:	02054563          	bltz	a0,80002442 <wait+0x9c>
          freeproc(pp);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	740080e7          	jalr	1856(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
          release(&wait_lock);
    80002430:	0000e517          	auipc	a0,0xe
    80002434:	73850513          	addi	a0,a0,1848 # 80010b68 <wait_lock>
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	852080e7          	jalr	-1966(ra) # 80000c8a <release>
          return pid;
    80002440:	a0b5                	j	800024ac <wait+0x106>
            release(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
            release(&wait_lock);
    8000244c:	0000e517          	auipc	a0,0xe
    80002450:	71c50513          	addi	a0,a0,1820 # 80010b68 <wait_lock>
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	836080e7          	jalr	-1994(ra) # 80000c8a <release>
            return -1;
    8000245c:	59fd                	li	s3,-1
    8000245e:	a0b9                	j	800024ac <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002460:	19848493          	addi	s1,s1,408
    80002464:	03348463          	beq	s1,s3,8000248c <wait+0xe6>
      if (pp->parent == p)
    80002468:	7c9c                	ld	a5,56(s1)
    8000246a:	ff279be3          	bne	a5,s2,80002460 <wait+0xba>
        acquire(&pp->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	766080e7          	jalr	1894(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002478:	4c9c                	lw	a5,24(s1)
    8000247a:	f94781e3          	beq	a5,s4,800023fc <wait+0x56>
        release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	80a080e7          	jalr	-2038(ra) # 80000c8a <release>
        havekids = 1;
    80002488:	8756                	mv	a4,s5
    8000248a:	bfd9                	j	80002460 <wait+0xba>
    if (!havekids || killed(p))
    8000248c:	c719                	beqz	a4,8000249a <wait+0xf4>
    8000248e:	854a                	mv	a0,s2
    80002490:	00000097          	auipc	ra,0x0
    80002494:	ee4080e7          	jalr	-284(ra) # 80002374 <killed>
    80002498:	c51d                	beqz	a0,800024c6 <wait+0x120>
      release(&wait_lock);
    8000249a:	0000e517          	auipc	a0,0xe
    8000249e:	6ce50513          	addi	a0,a0,1742 # 80010b68 <wait_lock>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7e8080e7          	jalr	2024(ra) # 80000c8a <release>
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
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024c6:	85e2                	mv	a1,s8
    800024c8:	854a                	mv	a0,s2
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	bf6080e7          	jalr	-1034(ra) # 800020c0 <sleep>
    havekids = 0;
    800024d2:	bf39                	j	800023f0 <wait+0x4a>

00000000800024d4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
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
    800024f0:	4c0080e7          	jalr	1216(ra) # 800019ac <myproc>
  if (user_dst)
    800024f4:	c08d                	beqz	s1,80002516 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024f6:	86d2                	mv	a3,s4
    800024f8:	864e                	mv	a2,s3
    800024fa:	85ca                	mv	a1,s2
    800024fc:	6928                	ld	a0,80(a0)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	16a080e7          	jalr	362(ra) # 80001668 <copyout>
  else
  {
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
    80002522:	810080e7          	jalr	-2032(ra) # 80000d2e <memmove>
    return 0;
    80002526:	8526                	mv	a0,s1
    80002528:	bff9                	j	80002506 <either_copyout+0x32>

000000008000252a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
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
    80002546:	46a080e7          	jalr	1130(ra) # 800019ac <myproc>
  if (user_src)
    8000254a:	c08d                	beqz	s1,8000256c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000254c:	86d2                	mv	a3,s4
    8000254e:	864e                	mv	a2,s3
    80002550:	85ca                	mv	a1,s2
    80002552:	6928                	ld	a0,80(a0)
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	1a0080e7          	jalr	416(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
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
    memmove(dst, (char *)src, len);
    8000256c:	000a061b          	sext.w	a2,s4
    80002570:	85ce                	mv	a1,s3
    80002572:	854a                	mv	a0,s2
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	7ba080e7          	jalr	1978(ra) # 80000d2e <memmove>
    return 0;
    8000257c:	8526                	mv	a0,s1
    8000257e:	bff9                	j	8000255c <either_copyin+0x32>

0000000080002580 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
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
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002596:	00006517          	auipc	a0,0x6
    8000259a:	b3250513          	addi	a0,a0,-1230 # 800080c8 <digits+0x88>
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	fea080e7          	jalr	-22(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	b3248493          	addi	s1,s1,-1230 # 800110d8 <proc+0x158>
    800025ae:	00015917          	auipc	s2,0x15
    800025b2:	12a90913          	addi	s2,s2,298 # 800176d8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
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
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d0:	00006b97          	auipc	s7,0x6
    800025d4:	cf8b8b93          	addi	s7,s7,-776 # 800082c8 <states.0>
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
  for (p = proc; p < &proc[NPROC]; p++)
    800025f2:	19848493          	addi	s1,s1,408
    800025f6:	03248163          	beq	s1,s2,80002618 <procdump+0x98>
    if (p->state == UNUSED)
    800025fa:	86a6                	mv	a3,s1
    800025fc:	ec04a783          	lw	a5,-320(s1)
    80002600:	dbed                	beqz	a5,800025f2 <procdump+0x72>
      state = "???";
    80002602:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
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

000000008000262e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000262e:	711d                	addi	sp,sp,-96
    80002630:	ec86                	sd	ra,88(sp)
    80002632:	e8a2                	sd	s0,80(sp)
    80002634:	e4a6                	sd	s1,72(sp)
    80002636:	e0ca                	sd	s2,64(sp)
    80002638:	fc4e                	sd	s3,56(sp)
    8000263a:	f852                	sd	s4,48(sp)
    8000263c:	f456                	sd	s5,40(sp)
    8000263e:	f05a                	sd	s6,32(sp)
    80002640:	ec5e                	sd	s7,24(sp)
    80002642:	e862                	sd	s8,16(sp)
    80002644:	e466                	sd	s9,8(sp)
    80002646:	e06a                	sd	s10,0(sp)
    80002648:	1080                	addi	s0,sp,96
    8000264a:	8b2a                	mv	s6,a0
    8000264c:	8bae                	mv	s7,a1
    8000264e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	35c080e7          	jalr	860(ra) # 800019ac <myproc>
    80002658:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000265a:	0000e517          	auipc	a0,0xe
    8000265e:	50e50513          	addi	a0,a0,1294 # 80010b68 <wait_lock>
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	574080e7          	jalr	1396(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000266a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000266c:	4a15                	li	s4,5
        havekids = 1;
    8000266e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002670:	00015997          	auipc	s3,0x15
    80002674:	f1098993          	addi	s3,s3,-240 # 80017580 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002678:	0000ed17          	auipc	s10,0xe
    8000267c:	4f0d0d13          	addi	s10,s10,1264 # 80010b68 <wait_lock>
    havekids = 0;
    80002680:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002682:	0000f497          	auipc	s1,0xf
    80002686:	8fe48493          	addi	s1,s1,-1794 # 80010f80 <proc>
    8000268a:	a059                	j	80002710 <waitx+0xe2>
          pid = np->pid;
    8000268c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002690:	1684a703          	lw	a4,360(s1)
    80002694:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002698:	16c4a783          	lw	a5,364(s1)
    8000269c:	9f3d                	addw	a4,a4,a5
    8000269e:	1704a783          	lw	a5,368(s1)
    800026a2:	9f99                	subw	a5,a5,a4
    800026a4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026a8:	000b0e63          	beqz	s6,800026c4 <waitx+0x96>
    800026ac:	4691                	li	a3,4
    800026ae:	02c48613          	addi	a2,s1,44
    800026b2:	85da                	mv	a1,s6
    800026b4:	05093503          	ld	a0,80(s2)
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	fb0080e7          	jalr	-80(ra) # 80001668 <copyout>
    800026c0:	02054563          	bltz	a0,800026ea <waitx+0xbc>
          freeproc(np);
    800026c4:	8526                	mv	a0,s1
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	498080e7          	jalr	1176(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
          release(&wait_lock);
    800026d8:	0000e517          	auipc	a0,0xe
    800026dc:	49050513          	addi	a0,a0,1168 # 80010b68 <wait_lock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	5aa080e7          	jalr	1450(ra) # 80000c8a <release>
          return pid;
    800026e8:	a09d                	j	8000274e <waitx+0x120>
            release(&np->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	59e080e7          	jalr	1438(ra) # 80000c8a <release>
            release(&wait_lock);
    800026f4:	0000e517          	auipc	a0,0xe
    800026f8:	47450513          	addi	a0,a0,1140 # 80010b68 <wait_lock>
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	58e080e7          	jalr	1422(ra) # 80000c8a <release>
            return -1;
    80002704:	59fd                	li	s3,-1
    80002706:	a0a1                	j	8000274e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002708:	19848493          	addi	s1,s1,408
    8000270c:	03348463          	beq	s1,s3,80002734 <waitx+0x106>
      if (np->parent == p)
    80002710:	7c9c                	ld	a5,56(s1)
    80002712:	ff279be3          	bne	a5,s2,80002708 <waitx+0xda>
        acquire(&np->lock);
    80002716:	8526                	mv	a0,s1
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	4be080e7          	jalr	1214(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002720:	4c9c                	lw	a5,24(s1)
    80002722:	f74785e3          	beq	a5,s4,8000268c <waitx+0x5e>
        release(&np->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	562080e7          	jalr	1378(ra) # 80000c8a <release>
        havekids = 1;
    80002730:	8756                	mv	a4,s5
    80002732:	bfd9                	j	80002708 <waitx+0xda>
    if (!havekids || p->killed)
    80002734:	c701                	beqz	a4,8000273c <waitx+0x10e>
    80002736:	02892783          	lw	a5,40(s2)
    8000273a:	cb8d                	beqz	a5,8000276c <waitx+0x13e>
      release(&wait_lock);
    8000273c:	0000e517          	auipc	a0,0xe
    80002740:	42c50513          	addi	a0,a0,1068 # 80010b68 <wait_lock>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	546080e7          	jalr	1350(ra) # 80000c8a <release>
      return -1;
    8000274c:	59fd                	li	s3,-1
  }
}
    8000274e:	854e                	mv	a0,s3
    80002750:	60e6                	ld	ra,88(sp)
    80002752:	6446                	ld	s0,80(sp)
    80002754:	64a6                	ld	s1,72(sp)
    80002756:	6906                	ld	s2,64(sp)
    80002758:	79e2                	ld	s3,56(sp)
    8000275a:	7a42                	ld	s4,48(sp)
    8000275c:	7aa2                	ld	s5,40(sp)
    8000275e:	7b02                	ld	s6,32(sp)
    80002760:	6be2                	ld	s7,24(sp)
    80002762:	6c42                	ld	s8,16(sp)
    80002764:	6ca2                	ld	s9,8(sp)
    80002766:	6d02                	ld	s10,0(sp)
    80002768:	6125                	addi	sp,sp,96
    8000276a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000276c:	85ea                	mv	a1,s10
    8000276e:	854a                	mv	a0,s2
    80002770:	00000097          	auipc	ra,0x0
    80002774:	950080e7          	jalr	-1712(ra) # 800020c0 <sleep>
    havekids = 0;
    80002778:	b721                	j	80002680 <waitx+0x52>

000000008000277a <update_time>:

void update_time()
{
    8000277a:	7179                	addi	sp,sp,-48
    8000277c:	f406                	sd	ra,40(sp)
    8000277e:	f022                	sd	s0,32(sp)
    80002780:	ec26                	sd	s1,24(sp)
    80002782:	e84a                	sd	s2,16(sp)
    80002784:	e44e                	sd	s3,8(sp)
    80002786:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002788:	0000e497          	auipc	s1,0xe
    8000278c:	7f848493          	addi	s1,s1,2040 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002790:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002792:	00015917          	auipc	s2,0x15
    80002796:	dee90913          	addi	s2,s2,-530 # 80017580 <tickslock>
    8000279a:	a811                	j	800027ae <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	4ec080e7          	jalr	1260(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027a6:	19848493          	addi	s1,s1,408
    800027aa:	03248063          	beq	s1,s2,800027ca <update_time+0x50>
    acquire(&p->lock);
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	426080e7          	jalr	1062(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800027b8:	4c9c                	lw	a5,24(s1)
    800027ba:	ff3791e3          	bne	a5,s3,8000279c <update_time+0x22>
      p->rtime++;
    800027be:	1684a783          	lw	a5,360(s1)
    800027c2:	2785                	addiw	a5,a5,1
    800027c4:	16f4a423          	sw	a5,360(s1)
    800027c8:	bfd1                	j	8000279c <update_time+0x22>
  }
    800027ca:	70a2                	ld	ra,40(sp)
    800027cc:	7402                	ld	s0,32(sp)
    800027ce:	64e2                	ld	s1,24(sp)
    800027d0:	6942                	ld	s2,16(sp)
    800027d2:	69a2                	ld	s3,8(sp)
    800027d4:	6145                	addi	sp,sp,48
    800027d6:	8082                	ret

00000000800027d8 <swtch>:
    800027d8:	00153023          	sd	ra,0(a0)
    800027dc:	00253423          	sd	sp,8(a0)
    800027e0:	e900                	sd	s0,16(a0)
    800027e2:	ed04                	sd	s1,24(a0)
    800027e4:	03253023          	sd	s2,32(a0)
    800027e8:	03353423          	sd	s3,40(a0)
    800027ec:	03453823          	sd	s4,48(a0)
    800027f0:	03553c23          	sd	s5,56(a0)
    800027f4:	05653023          	sd	s6,64(a0)
    800027f8:	05753423          	sd	s7,72(a0)
    800027fc:	05853823          	sd	s8,80(a0)
    80002800:	05953c23          	sd	s9,88(a0)
    80002804:	07a53023          	sd	s10,96(a0)
    80002808:	07b53423          	sd	s11,104(a0)
    8000280c:	0005b083          	ld	ra,0(a1)
    80002810:	0085b103          	ld	sp,8(a1)
    80002814:	6980                	ld	s0,16(a1)
    80002816:	6d84                	ld	s1,24(a1)
    80002818:	0205b903          	ld	s2,32(a1)
    8000281c:	0285b983          	ld	s3,40(a1)
    80002820:	0305ba03          	ld	s4,48(a1)
    80002824:	0385ba83          	ld	s5,56(a1)
    80002828:	0405bb03          	ld	s6,64(a1)
    8000282c:	0485bb83          	ld	s7,72(a1)
    80002830:	0505bc03          	ld	s8,80(a1)
    80002834:	0585bc83          	ld	s9,88(a1)
    80002838:	0605bd03          	ld	s10,96(a1)
    8000283c:	0685bd83          	ld	s11,104(a1)
    80002840:	8082                	ret

0000000080002842 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e406                	sd	ra,8(sp)
    80002846:	e022                	sd	s0,0(sp)
    80002848:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000284a:	00006597          	auipc	a1,0x6
    8000284e:	aae58593          	addi	a1,a1,-1362 # 800082f8 <states.0+0x30>
    80002852:	00015517          	auipc	a0,0x15
    80002856:	d2e50513          	addi	a0,a0,-722 # 80017580 <tickslock>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	2ec080e7          	jalr	748(ra) # 80000b46 <initlock>
}
    80002862:	60a2                	ld	ra,8(sp)
    80002864:	6402                	ld	s0,0(sp)
    80002866:	0141                	addi	sp,sp,16
    80002868:	8082                	ret

000000008000286a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000286a:	1141                	addi	sp,sp,-16
    8000286c:	e422                	sd	s0,8(sp)
    8000286e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002870:	00003797          	auipc	a5,0x3
    80002874:	62078793          	addi	a5,a5,1568 # 80005e90 <kernelvec>
    80002878:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000287c:	6422                	ld	s0,8(sp)
    8000287e:	0141                	addi	sp,sp,16
    80002880:	8082                	ret

0000000080002882 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002882:	1141                	addi	sp,sp,-16
    80002884:	e406                	sd	ra,8(sp)
    80002886:	e022                	sd	s0,0(sp)
    80002888:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	122080e7          	jalr	290(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002896:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002898:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000289c:	00004617          	auipc	a2,0x4
    800028a0:	76460613          	addi	a2,a2,1892 # 80007000 <_trampoline>
    800028a4:	00004697          	auipc	a3,0x4
    800028a8:	75c68693          	addi	a3,a3,1884 # 80007000 <_trampoline>
    800028ac:	8e91                	sub	a3,a3,a2
    800028ae:	040007b7          	lui	a5,0x4000
    800028b2:	17fd                	addi	a5,a5,-1
    800028b4:	07b2                	slli	a5,a5,0xc
    800028b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028be:	180026f3          	csrr	a3,satp
    800028c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c4:	6d38                	ld	a4,88(a0)
    800028c6:	6134                	ld	a3,64(a0)
    800028c8:	6585                	lui	a1,0x1
    800028ca:	96ae                	add	a3,a3,a1
    800028cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028ce:	6d38                	ld	a4,88(a0)
    800028d0:	00000697          	auipc	a3,0x0
    800028d4:	13e68693          	addi	a3,a3,318 # 80002a0e <usertrap>
    800028d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028dc:	8692                	mv	a3,tp
    800028de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f2:	6f18                	ld	a4,24(a4)
    800028f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f8:	6928                	ld	a0,80(a0)
    800028fa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028fc:	00004717          	auipc	a4,0x4
    80002900:	7a070713          	addi	a4,a4,1952 # 8000709c <userret>
    80002904:	8f11                	sub	a4,a4,a2
    80002906:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002908:	577d                	li	a4,-1
    8000290a:	177e                	slli	a4,a4,0x3f
    8000290c:	8d59                	or	a0,a0,a4
    8000290e:	9782                	jalr	a5
}
    80002910:	60a2                	ld	ra,8(sp)
    80002912:	6402                	ld	s0,0(sp)
    80002914:	0141                	addi	sp,sp,16
    80002916:	8082                	ret

0000000080002918 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002918:	1101                	addi	sp,sp,-32
    8000291a:	ec06                	sd	ra,24(sp)
    8000291c:	e822                	sd	s0,16(sp)
    8000291e:	e426                	sd	s1,8(sp)
    80002920:	e04a                	sd	s2,0(sp)
    80002922:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002924:	00015917          	auipc	s2,0x15
    80002928:	c5c90913          	addi	s2,s2,-932 # 80017580 <tickslock>
    8000292c:	854a                	mv	a0,s2
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	2a8080e7          	jalr	680(ra) # 80000bd6 <acquire>
  ticks++;
    80002936:	00006497          	auipc	s1,0x6
    8000293a:	faa48493          	addi	s1,s1,-86 # 800088e0 <ticks>
    8000293e:	409c                	lw	a5,0(s1)
    80002940:	2785                	addiw	a5,a5,1
    80002942:	c09c                	sw	a5,0(s1)
  update_time();
    80002944:	00000097          	auipc	ra,0x0
    80002948:	e36080e7          	jalr	-458(ra) # 8000277a <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    8000294c:	8526                	mv	a0,s1
    8000294e:	fffff097          	auipc	ra,0xfffff
    80002952:	7d6080e7          	jalr	2006(ra) # 80002124 <wakeup>
  release(&tickslock);
    80002956:	854a                	mv	a0,s2
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80002960:	60e2                	ld	ra,24(sp)
    80002962:	6442                	ld	s0,16(sp)
    80002964:	64a2                	ld	s1,8(sp)
    80002966:	6902                	ld	s2,0(sp)
    80002968:	6105                	addi	sp,sp,32
    8000296a:	8082                	ret

000000008000296c <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    8000296c:	1101                	addi	sp,sp,-32
    8000296e:	ec06                	sd	ra,24(sp)
    80002970:	e822                	sd	s0,16(sp)
    80002972:	e426                	sd	s1,8(sp)
    80002974:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002976:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    8000297a:	00074d63          	bltz	a4,80002994 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    8000297e:	57fd                	li	a5,-1
    80002980:	17fe                	slli	a5,a5,0x3f
    80002982:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002984:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002986:	06f70363          	beq	a4,a5,800029ec <devintr+0x80>
  }
}
    8000298a:	60e2                	ld	ra,24(sp)
    8000298c:	6442                	ld	s0,16(sp)
    8000298e:	64a2                	ld	s1,8(sp)
    80002990:	6105                	addi	sp,sp,32
    80002992:	8082                	ret
      (scause & 0xff) == 9)
    80002994:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002998:	46a5                	li	a3,9
    8000299a:	fed792e3          	bne	a5,a3,8000297e <devintr+0x12>
    int irq = plic_claim();
    8000299e:	00003097          	auipc	ra,0x3
    800029a2:	5fa080e7          	jalr	1530(ra) # 80005f98 <plic_claim>
    800029a6:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800029a8:	47a9                	li	a5,10
    800029aa:	02f50763          	beq	a0,a5,800029d8 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800029ae:	4785                	li	a5,1
    800029b0:	02f50963          	beq	a0,a5,800029e2 <devintr+0x76>
    return 1;
    800029b4:	4505                	li	a0,1
    else if (irq)
    800029b6:	d8f1                	beqz	s1,8000298a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029b8:	85a6                	mv	a1,s1
    800029ba:	00006517          	auipc	a0,0x6
    800029be:	94650513          	addi	a0,a0,-1722 # 80008300 <states.0+0x38>
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	bc6080e7          	jalr	-1082(ra) # 80000588 <printf>
      plic_complete(irq);
    800029ca:	8526                	mv	a0,s1
    800029cc:	00003097          	auipc	ra,0x3
    800029d0:	5f0080e7          	jalr	1520(ra) # 80005fbc <plic_complete>
    return 1;
    800029d4:	4505                	li	a0,1
    800029d6:	bf55                	j	8000298a <devintr+0x1e>
      uartintr();
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartintr>
    800029e0:	b7ed                	j	800029ca <devintr+0x5e>
      virtio_disk_intr();
    800029e2:	00004097          	auipc	ra,0x4
    800029e6:	aa6080e7          	jalr	-1370(ra) # 80006488 <virtio_disk_intr>
    800029ea:	b7c5                	j	800029ca <devintr+0x5e>
    if (cpuid() == 0)
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	f94080e7          	jalr	-108(ra) # 80001980 <cpuid>
    800029f4:	c901                	beqz	a0,80002a04 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029f6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029fa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029fc:	14479073          	csrw	sip,a5
    return 2;
    80002a00:	4509                	li	a0,2
    80002a02:	b761                	j	8000298a <devintr+0x1e>
      clockintr();
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	f14080e7          	jalr	-236(ra) # 80002918 <clockintr>
    80002a0c:	b7ed                	j	800029f6 <devintr+0x8a>

0000000080002a0e <usertrap>:
{
    80002a0e:	1101                	addi	sp,sp,-32
    80002a10:	ec06                	sd	ra,24(sp)
    80002a12:	e822                	sd	s0,16(sp)
    80002a14:	e426                	sd	s1,8(sp)
    80002a16:	e04a                	sd	s2,0(sp)
    80002a18:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002a1e:	1007f793          	andi	a5,a5,256
    80002a22:	e3c1                	bnez	a5,80002aa2 <usertrap+0x94>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a24:	00003797          	auipc	a5,0x3
    80002a28:	46c78793          	addi	a5,a5,1132 # 80005e90 <kernelvec>
    80002a2c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	f7c080e7          	jalr	-132(ra) # 800019ac <myproc>
    80002a38:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a3a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3c:	14102773          	csrr	a4,sepc
    80002a40:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a42:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a46:	47a1                	li	a5,8
    80002a48:	06f70563          	beq	a4,a5,80002ab2 <usertrap+0xa4>
  else if ((which_dev = devintr()) != 0)
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	f20080e7          	jalr	-224(ra) # 8000296c <devintr>
    80002a54:	c945                	beqz	a0,80002b04 <usertrap+0xf6>
    if (which_dev == 2 && p->alarm_on==0  ) {
    80002a56:	4789                	li	a5,2
    80002a58:	08f51063          	bne	a0,a5,80002ad8 <usertrap+0xca>
    80002a5c:	1904a783          	lw	a5,400(s1)
    80002a60:	efa5                	bnez	a5,80002ad8 <usertrap+0xca>
      struct trapframe *tf = kalloc();
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	084080e7          	jalr	132(ra) # 80000ae6 <kalloc>
    80002a6a:	892a                	mv	s2,a0
      memmove(tf, p->trapframe, PGSIZE);
    80002a6c:	6605                	lui	a2,0x1
    80002a6e:	6cac                	ld	a1,88(s1)
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	2be080e7          	jalr	702(ra) # 80000d2e <memmove>
      p->alarm_tf = tf;
    80002a78:	1924b423          	sd	s2,392(s1)
      p->cur_ticks++;
    80002a7c:	1844a783          	lw	a5,388(s1)
    80002a80:	2785                	addiw	a5,a5,1
    80002a82:	0007871b          	sext.w	a4,a5
    80002a86:	18f4a223          	sw	a5,388(s1)
        if (p->cur_ticks == p->ticks )
    80002a8a:	1804a783          	lw	a5,384(s1)
    80002a8e:	04e79563          	bne	a5,a4,80002ad8 <usertrap+0xca>
      {p->alarm_on = 1;
    80002a92:	4785                	li	a5,1
    80002a94:	18f4a823          	sw	a5,400(s1)
        p->trapframe->epc = p->handler;}
    80002a98:	6cbc                	ld	a5,88(s1)
    80002a9a:	1784b703          	ld	a4,376(s1)
    80002a9e:	ef98                	sd	a4,24(a5)
    80002aa0:	a825                	j	80002ad8 <usertrap+0xca>
    panic("usertrap: not from user mode");
    80002aa2:	00006517          	auipc	a0,0x6
    80002aa6:	87e50513          	addi	a0,a0,-1922 # 80008320 <states.0+0x58>
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>
    if (killed(p))
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	8c2080e7          	jalr	-1854(ra) # 80002374 <killed>
    80002aba:	ed1d                	bnez	a0,80002af8 <usertrap+0xea>
    p->trapframe->epc += 4;
    80002abc:	6cb8                	ld	a4,88(s1)
    80002abe:	6f1c                	ld	a5,24(a4)
    80002ac0:	0791                	addi	a5,a5,4
    80002ac2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ac8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10079073          	csrw	sstatus,a5
    syscall();
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	29a080e7          	jalr	666(ra) # 80002d6a <syscall>
  if (killed(p))
    80002ad8:	8526                	mv	a0,s1
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	89a080e7          	jalr	-1894(ra) # 80002374 <killed>
    80002ae2:	ed31                	bnez	a0,80002b3e <usertrap+0x130>
  usertrapret();
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	d9e080e7          	jalr	-610(ra) # 80002882 <usertrapret>
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6902                	ld	s2,0(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret
      exit(-1);
    80002af8:	557d                	li	a0,-1
    80002afa:	fffff097          	auipc	ra,0xfffff
    80002afe:	6fa080e7          	jalr	1786(ra) # 800021f4 <exit>
    80002b02:	bf6d                	j	80002abc <usertrap+0xae>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b04:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b08:	5890                	lw	a2,48(s1)
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	83650513          	addi	a0,a0,-1994 # 80008340 <states.0+0x78>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b1e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b22:	00006517          	auipc	a0,0x6
    80002b26:	84e50513          	addi	a0,a0,-1970 # 80008370 <states.0+0xa8>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a5e080e7          	jalr	-1442(ra) # 80000588 <printf>
    setkilled(p);
    80002b32:	8526                	mv	a0,s1
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	814080e7          	jalr	-2028(ra) # 80002348 <setkilled>
    80002b3c:	bf71                	j	80002ad8 <usertrap+0xca>
    exit(-1);
    80002b3e:	557d                	li	a0,-1
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	6b4080e7          	jalr	1716(ra) # 800021f4 <exit>
    80002b48:	bf71                	j	80002ae4 <usertrap+0xd6>

0000000080002b4a <kerneltrap>:
{
    80002b4a:	7179                	addi	sp,sp,-48
    80002b4c:	f406                	sd	ra,40(sp)
    80002b4e:	f022                	sd	s0,32(sp)
    80002b50:	ec26                	sd	s1,24(sp)
    80002b52:	e84a                	sd	s2,16(sp)
    80002b54:	e44e                	sd	s3,8(sp)
    80002b56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b60:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b64:	1004f793          	andi	a5,s1,256
    80002b68:	c78d                	beqz	a5,80002b92 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b6e:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b70:	eb8d                	bnez	a5,80002ba2 <kerneltrap+0x58>
  if ((which_dev = devintr()) == 0)
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	dfa080e7          	jalr	-518(ra) # 8000296c <devintr>
    80002b7a:	cd05                	beqz	a0,80002bb2 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b7c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b80:	10049073          	csrw	sstatus,s1
}
    80002b84:	70a2                	ld	ra,40(sp)
    80002b86:	7402                	ld	s0,32(sp)
    80002b88:	64e2                	ld	s1,24(sp)
    80002b8a:	6942                	ld	s2,16(sp)
    80002b8c:	69a2                	ld	s3,8(sp)
    80002b8e:	6145                	addi	sp,sp,48
    80002b90:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b92:	00005517          	auipc	a0,0x5
    80002b96:	7fe50513          	addi	a0,a0,2046 # 80008390 <states.0+0xc8>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	81650513          	addi	a0,a0,-2026 # 800083b8 <states.0+0xf0>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bb2:	85ce                	mv	a1,s3
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	82450513          	addi	a0,a0,-2012 # 800083d8 <states.0+0x110>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	9cc080e7          	jalr	-1588(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bcc:	00006517          	auipc	a0,0x6
    80002bd0:	81c50513          	addi	a0,a0,-2020 # 800083e8 <states.0+0x120>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	9b4080e7          	jalr	-1612(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bdc:	00006517          	auipc	a0,0x6
    80002be0:	82450513          	addi	a0,a0,-2012 # 80008400 <states.0+0x138>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	95a080e7          	jalr	-1702(ra) # 8000053e <panic>

0000000080002bec <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	db4080e7          	jalr	-588(ra) # 800019ac <myproc>
  switch (n) {
    80002c00:	4795                	li	a5,5
    80002c02:	0497e163          	bltu	a5,s1,80002c44 <argraw+0x58>
    80002c06:	048a                	slli	s1,s1,0x2
    80002c08:	00006717          	auipc	a4,0x6
    80002c0c:	83070713          	addi	a4,a4,-2000 # 80008438 <states.0+0x170>
    80002c10:	94ba                	add	s1,s1,a4
    80002c12:	409c                	lw	a5,0(s1)
    80002c14:	97ba                	add	a5,a5,a4
    80002c16:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c18:	6d3c                	ld	a5,88(a0)
    80002c1a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c1c:	60e2                	ld	ra,24(sp)
    80002c1e:	6442                	ld	s0,16(sp)
    80002c20:	64a2                	ld	s1,8(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    return p->trapframe->a1;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	7fa8                	ld	a0,120(a5)
    80002c2a:	bfcd                	j	80002c1c <argraw+0x30>
    return p->trapframe->a2;
    80002c2c:	6d3c                	ld	a5,88(a0)
    80002c2e:	63c8                	ld	a0,128(a5)
    80002c30:	b7f5                	j	80002c1c <argraw+0x30>
    return p->trapframe->a3;
    80002c32:	6d3c                	ld	a5,88(a0)
    80002c34:	67c8                	ld	a0,136(a5)
    80002c36:	b7dd                	j	80002c1c <argraw+0x30>
    return p->trapframe->a4;
    80002c38:	6d3c                	ld	a5,88(a0)
    80002c3a:	6bc8                	ld	a0,144(a5)
    80002c3c:	b7c5                	j	80002c1c <argraw+0x30>
    return p->trapframe->a5;
    80002c3e:	6d3c                	ld	a5,88(a0)
    80002c40:	6fc8                	ld	a0,152(a5)
    80002c42:	bfe9                	j	80002c1c <argraw+0x30>
  panic("argraw");
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7cc50513          	addi	a0,a0,1996 # 80008410 <states.0+0x148>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>

0000000080002c54 <fetchaddr>:
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	e426                	sd	s1,8(sp)
    80002c5c:	e04a                	sd	s2,0(sp)
    80002c5e:	1000                	addi	s0,sp,32
    80002c60:	84aa                	mv	s1,a0
    80002c62:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	d48080e7          	jalr	-696(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c6c:	653c                	ld	a5,72(a0)
    80002c6e:	02f4f863          	bgeu	s1,a5,80002c9e <fetchaddr+0x4a>
    80002c72:	00848713          	addi	a4,s1,8
    80002c76:	02e7e663          	bltu	a5,a4,80002ca2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c7a:	46a1                	li	a3,8
    80002c7c:	8626                	mv	a2,s1
    80002c7e:	85ca                	mv	a1,s2
    80002c80:	6928                	ld	a0,80(a0)
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	a72080e7          	jalr	-1422(ra) # 800016f4 <copyin>
    80002c8a:	00a03533          	snez	a0,a0
    80002c8e:	40a00533          	neg	a0,a0
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6902                	ld	s2,0(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret
    return -1;
    80002c9e:	557d                	li	a0,-1
    80002ca0:	bfcd                	j	80002c92 <fetchaddr+0x3e>
    80002ca2:	557d                	li	a0,-1
    80002ca4:	b7fd                	j	80002c92 <fetchaddr+0x3e>

0000000080002ca6 <fetchstr>:
{
    80002ca6:	7179                	addi	sp,sp,-48
    80002ca8:	f406                	sd	ra,40(sp)
    80002caa:	f022                	sd	s0,32(sp)
    80002cac:	ec26                	sd	s1,24(sp)
    80002cae:	e84a                	sd	s2,16(sp)
    80002cb0:	e44e                	sd	s3,8(sp)
    80002cb2:	1800                	addi	s0,sp,48
    80002cb4:	892a                	mv	s2,a0
    80002cb6:	84ae                	mv	s1,a1
    80002cb8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	cf2080e7          	jalr	-782(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cc2:	86ce                	mv	a3,s3
    80002cc4:	864a                	mv	a2,s2
    80002cc6:	85a6                	mv	a1,s1
    80002cc8:	6928                	ld	a0,80(a0)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	ab8080e7          	jalr	-1352(ra) # 80001782 <copyinstr>
    80002cd2:	00054e63          	bltz	a0,80002cee <fetchstr+0x48>
  return strlen(buf);
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	176080e7          	jalr	374(ra) # 80000e4e <strlen>
}
    80002ce0:	70a2                	ld	ra,40(sp)
    80002ce2:	7402                	ld	s0,32(sp)
    80002ce4:	64e2                	ld	s1,24(sp)
    80002ce6:	6942                	ld	s2,16(sp)
    80002ce8:	69a2                	ld	s3,8(sp)
    80002cea:	6145                	addi	sp,sp,48
    80002cec:	8082                	ret
    return -1;
    80002cee:	557d                	li	a0,-1
    80002cf0:	bfc5                	j	80002ce0 <fetchstr+0x3a>

0000000080002cf2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	e426                	sd	s1,8(sp)
    80002cfa:	1000                	addi	s0,sp,32
    80002cfc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	eee080e7          	jalr	-274(ra) # 80002bec <argraw>
    80002d06:	c088                	sw	a0,0(s1)
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	64a2                	ld	s1,8(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret

0000000080002d12 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
    80002d1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	ece080e7          	jalr	-306(ra) # 80002bec <argraw>
    80002d26:	e088                	sd	a0,0(s1)
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d32:	7179                	addi	sp,sp,-48
    80002d34:	f406                	sd	ra,40(sp)
    80002d36:	f022                	sd	s0,32(sp)
    80002d38:	ec26                	sd	s1,24(sp)
    80002d3a:	e84a                	sd	s2,16(sp)
    80002d3c:	1800                	addi	s0,sp,48
    80002d3e:	84ae                	mv	s1,a1
    80002d40:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d42:	fd840593          	addi	a1,s0,-40
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	fcc080e7          	jalr	-52(ra) # 80002d12 <argaddr>
  return fetchstr(addr, buf, max);
    80002d4e:	864a                	mv	a2,s2
    80002d50:	85a6                	mv	a1,s1
    80002d52:	fd843503          	ld	a0,-40(s0)
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	f50080e7          	jalr	-176(ra) # 80002ca6 <fetchstr>
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6942                	ld	s2,16(sp)
    80002d66:	6145                	addi	sp,sp,48
    80002d68:	8082                	ret

0000000080002d6a <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	e04a                	sd	s2,0(sp)
    80002d74:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c36080e7          	jalr	-970(ra) # 800019ac <myproc>
    80002d7e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d80:	05853903          	ld	s2,88(a0)
    80002d84:	0a893783          	ld	a5,168(s2)
    80002d88:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d8c:	37fd                	addiw	a5,a5,-1
    80002d8e:	4761                	li	a4,24
    80002d90:	00f76f63          	bltu	a4,a5,80002dae <syscall+0x44>
    80002d94:	00369713          	slli	a4,a3,0x3
    80002d98:	00005797          	auipc	a5,0x5
    80002d9c:	6b878793          	addi	a5,a5,1720 # 80008450 <syscalls>
    80002da0:	97ba                	add	a5,a5,a4
    80002da2:	639c                	ld	a5,0(a5)
    80002da4:	c789                	beqz	a5,80002dae <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002da6:	9782                	jalr	a5
    80002da8:	06a93823          	sd	a0,112(s2)
    80002dac:	a839                	j	80002dca <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dae:	15848613          	addi	a2,s1,344
    80002db2:	588c                	lw	a1,48(s1)
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	66450513          	addi	a0,a0,1636 # 80008418 <states.0+0x150>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	7cc080e7          	jalr	1996(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dc4:	6cbc                	ld	a5,88(s1)
    80002dc6:	577d                	li	a4,-1
    80002dc8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6902                	ld	s2,0(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <sys_exit>:
#include "proc.h"

extern int readcount;
uint64
sys_exit(void)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dde:	fec40593          	addi	a1,s0,-20
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	f0e080e7          	jalr	-242(ra) # 80002cf2 <argint>
  exit(n);
    80002dec:	fec42503          	lw	a0,-20(s0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	404080e7          	jalr	1028(ra) # 800021f4 <exit>
  return 0; // not reached
}
    80002df8:	4501                	li	a0,0
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    80002e02:	1141                	addi	sp,sp,-16
    80002e04:	e422                	sd	s0,8(sp)
    80002e06:	0800                	addi	s0,sp,16
  return readcount;
}
    80002e08:	00006517          	auipc	a0,0x6
    80002e0c:	adc52503          	lw	a0,-1316(a0) # 800088e4 <readcount>
    80002e10:	6422                	ld	s0,8(sp)
    80002e12:	0141                	addi	sp,sp,16
    80002e14:	8082                	ret

0000000080002e16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e16:	1141                	addi	sp,sp,-16
    80002e18:	e406                	sd	ra,8(sp)
    80002e1a:	e022                	sd	s0,0(sp)
    80002e1c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	b8e080e7          	jalr	-1138(ra) # 800019ac <myproc>
}
    80002e26:	5908                	lw	a0,48(a0)
    80002e28:	60a2                	ld	ra,8(sp)
    80002e2a:	6402                	ld	s0,0(sp)
    80002e2c:	0141                	addi	sp,sp,16
    80002e2e:	8082                	ret

0000000080002e30 <sys_fork>:

uint64
sys_fork(void)
{
    80002e30:	1141                	addi	sp,sp,-16
    80002e32:	e406                	sd	ra,8(sp)
    80002e34:	e022                	sd	s0,0(sp)
    80002e36:	0800                	addi	s0,sp,16
  return fork();
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	f3e080e7          	jalr	-194(ra) # 80001d76 <fork>
}
    80002e40:	60a2                	ld	ra,8(sp)
    80002e42:	6402                	ld	s0,0(sp)
    80002e44:	0141                	addi	sp,sp,16
    80002e46:	8082                	ret

0000000080002e48 <sys_wait>:

uint64
sys_wait(void)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e50:	fe840593          	addi	a1,s0,-24
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	ebc080e7          	jalr	-324(ra) # 80002d12 <argaddr>
  return wait(p);
    80002e5e:	fe843503          	ld	a0,-24(s0)
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	544080e7          	jalr	1348(ra) # 800023a6 <wait>
}
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	6105                	addi	sp,sp,32
    80002e70:	8082                	ret

0000000080002e72 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e72:	7179                	addi	sp,sp,-48
    80002e74:	f406                	sd	ra,40(sp)
    80002e76:	f022                	sd	s0,32(sp)
    80002e78:	ec26                	sd	s1,24(sp)
    80002e7a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e7c:	fdc40593          	addi	a1,s0,-36
    80002e80:	4501                	li	a0,0
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	e70080e7          	jalr	-400(ra) # 80002cf2 <argint>
  addr = myproc()->sz;
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	b22080e7          	jalr	-1246(ra) # 800019ac <myproc>
    80002e92:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e94:	fdc42503          	lw	a0,-36(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	e82080e7          	jalr	-382(ra) # 80001d1a <growproc>
    80002ea0:	00054863          	bltz	a0,80002eb0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ea4:	8526                	mv	a0,s1
    80002ea6:	70a2                	ld	ra,40(sp)
    80002ea8:	7402                	ld	s0,32(sp)
    80002eaa:	64e2                	ld	s1,24(sp)
    80002eac:	6145                	addi	sp,sp,48
    80002eae:	8082                	ret
    return -1;
    80002eb0:	54fd                	li	s1,-1
    80002eb2:	bfcd                	j	80002ea4 <sys_sbrk+0x32>

0000000080002eb4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eb4:	7139                	addi	sp,sp,-64
    80002eb6:	fc06                	sd	ra,56(sp)
    80002eb8:	f822                	sd	s0,48(sp)
    80002eba:	f426                	sd	s1,40(sp)
    80002ebc:	f04a                	sd	s2,32(sp)
    80002ebe:	ec4e                	sd	s3,24(sp)
    80002ec0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ec2:	fcc40593          	addi	a1,s0,-52
    80002ec6:	4501                	li	a0,0
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	e2a080e7          	jalr	-470(ra) # 80002cf2 <argint>
  acquire(&tickslock);
    80002ed0:	00014517          	auipc	a0,0x14
    80002ed4:	6b050513          	addi	a0,a0,1712 # 80017580 <tickslock>
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	cfe080e7          	jalr	-770(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ee0:	00006917          	auipc	s2,0x6
    80002ee4:	a0092903          	lw	s2,-1536(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80002ee8:	fcc42783          	lw	a5,-52(s0)
    80002eec:	cf9d                	beqz	a5,80002f2a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eee:	00014997          	auipc	s3,0x14
    80002ef2:	69298993          	addi	s3,s3,1682 # 80017580 <tickslock>
    80002ef6:	00006497          	auipc	s1,0x6
    80002efa:	9ea48493          	addi	s1,s1,-1558 # 800088e0 <ticks>
    if (killed(myproc()))
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	aae080e7          	jalr	-1362(ra) # 800019ac <myproc>
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	46e080e7          	jalr	1134(ra) # 80002374 <killed>
    80002f0e:	ed15                	bnez	a0,80002f4a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f10:	85ce                	mv	a1,s3
    80002f12:	8526                	mv	a0,s1
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	1ac080e7          	jalr	428(ra) # 800020c0 <sleep>
  while (ticks - ticks0 < n)
    80002f1c:	409c                	lw	a5,0(s1)
    80002f1e:	412787bb          	subw	a5,a5,s2
    80002f22:	fcc42703          	lw	a4,-52(s0)
    80002f26:	fce7ece3          	bltu	a5,a4,80002efe <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f2a:	00014517          	auipc	a0,0x14
    80002f2e:	65650513          	addi	a0,a0,1622 # 80017580 <tickslock>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	d58080e7          	jalr	-680(ra) # 80000c8a <release>
  return 0;
    80002f3a:	4501                	li	a0,0
}
    80002f3c:	70e2                	ld	ra,56(sp)
    80002f3e:	7442                	ld	s0,48(sp)
    80002f40:	74a2                	ld	s1,40(sp)
    80002f42:	7902                	ld	s2,32(sp)
    80002f44:	69e2                	ld	s3,24(sp)
    80002f46:	6121                	addi	sp,sp,64
    80002f48:	8082                	ret
      release(&tickslock);
    80002f4a:	00014517          	auipc	a0,0x14
    80002f4e:	63650513          	addi	a0,a0,1590 # 80017580 <tickslock>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	d38080e7          	jalr	-712(ra) # 80000c8a <release>
      return -1;
    80002f5a:	557d                	li	a0,-1
    80002f5c:	b7c5                	j	80002f3c <sys_sleep+0x88>

0000000080002f5e <sys_kill>:

uint64
sys_kill(void)
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f66:	fec40593          	addi	a1,s0,-20
    80002f6a:	4501                	li	a0,0
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	d86080e7          	jalr	-634(ra) # 80002cf2 <argint>
  return kill(pid);
    80002f74:	fec42503          	lw	a0,-20(s0)
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	35e080e7          	jalr	862(ra) # 800022d6 <kill>
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	6105                	addi	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f92:	00014517          	auipc	a0,0x14
    80002f96:	5ee50513          	addi	a0,a0,1518 # 80017580 <tickslock>
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	c3c080e7          	jalr	-964(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fa2:	00006497          	auipc	s1,0x6
    80002fa6:	93e4a483          	lw	s1,-1730(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	5d650513          	addi	a0,a0,1494 # 80017580 <tickslock>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	cd8080e7          	jalr	-808(ra) # 80000c8a <release>
  return xticks;
}
    80002fba:	02049513          	slli	a0,s1,0x20
    80002fbe:	9101                	srli	a0,a0,0x20
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret

0000000080002fca <sys_waitx>:

uint64
sys_waitx(void)
{
    80002fca:	7139                	addi	sp,sp,-64
    80002fcc:	fc06                	sd	ra,56(sp)
    80002fce:	f822                	sd	s0,48(sp)
    80002fd0:	f426                	sd	s1,40(sp)
    80002fd2:	f04a                	sd	s2,32(sp)
    80002fd4:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002fd6:	fd840593          	addi	a1,s0,-40
    80002fda:	4501                	li	a0,0
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	d36080e7          	jalr	-714(ra) # 80002d12 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002fe4:	fd040593          	addi	a1,s0,-48
    80002fe8:	4505                	li	a0,1
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	d28080e7          	jalr	-728(ra) # 80002d12 <argaddr>
  argaddr(2, &addr2);
    80002ff2:	fc840593          	addi	a1,s0,-56
    80002ff6:	4509                	li	a0,2
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	d1a080e7          	jalr	-742(ra) # 80002d12 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003000:	fc040613          	addi	a2,s0,-64
    80003004:	fc440593          	addi	a1,s0,-60
    80003008:	fd843503          	ld	a0,-40(s0)
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	622080e7          	jalr	1570(ra) # 8000262e <waitx>
    80003014:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	996080e7          	jalr	-1642(ra) # 800019ac <myproc>
    8000301e:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003020:	4691                	li	a3,4
    80003022:	fc440613          	addi	a2,s0,-60
    80003026:	fd043583          	ld	a1,-48(s0)
    8000302a:	6928                	ld	a0,80(a0)
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	63c080e7          	jalr	1596(ra) # 80001668 <copyout>
    return -1;
    80003034:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003036:	00054f63          	bltz	a0,80003054 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000303a:	4691                	li	a3,4
    8000303c:	fc040613          	addi	a2,s0,-64
    80003040:	fc843583          	ld	a1,-56(s0)
    80003044:	68a8                	ld	a0,80(s1)
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	622080e7          	jalr	1570(ra) # 80001668 <copyout>
    8000304e:	00054a63          	bltz	a0,80003062 <sys_waitx+0x98>
    return -1;
  return ret;
    80003052:	87ca                	mv	a5,s2
}
    80003054:	853e                	mv	a0,a5
    80003056:	70e2                	ld	ra,56(sp)
    80003058:	7442                	ld	s0,48(sp)
    8000305a:	74a2                	ld	s1,40(sp)
    8000305c:	7902                	ld	s2,32(sp)
    8000305e:	6121                	addi	sp,sp,64
    80003060:	8082                	ret
    return -1;
    80003062:	57fd                	li	a5,-1
    80003064:	bfc5                	j	80003054 <sys_waitx+0x8a>

0000000080003066 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	e84a                	sd	s2,16(sp)
    80003070:	e44e                	sd	s3,8(sp)
    80003072:	e052                	sd	s4,0(sp)
    80003074:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003076:	00005597          	auipc	a1,0x5
    8000307a:	4aa58593          	addi	a1,a1,1194 # 80008520 <syscalls+0xd0>
    8000307e:	00014517          	auipc	a0,0x14
    80003082:	51a50513          	addi	a0,a0,1306 # 80017598 <bcache>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	ac0080e7          	jalr	-1344(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000308e:	0001c797          	auipc	a5,0x1c
    80003092:	50a78793          	addi	a5,a5,1290 # 8001f598 <bcache+0x8000>
    80003096:	0001c717          	auipc	a4,0x1c
    8000309a:	76a70713          	addi	a4,a4,1898 # 8001f800 <bcache+0x8268>
    8000309e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030a2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a6:	00014497          	auipc	s1,0x14
    800030aa:	50a48493          	addi	s1,s1,1290 # 800175b0 <bcache+0x18>
    b->next = bcache.head.next;
    800030ae:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030b0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030b2:	00005a17          	auipc	s4,0x5
    800030b6:	476a0a13          	addi	s4,s4,1142 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    800030ba:	2b893783          	ld	a5,696(s2)
    800030be:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030c0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030c4:	85d2                	mv	a1,s4
    800030c6:	01048513          	addi	a0,s1,16
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	4c4080e7          	jalr	1220(ra) # 8000458e <initsleeplock>
    bcache.head.next->prev = b;
    800030d2:	2b893783          	ld	a5,696(s2)
    800030d6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030d8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030dc:	45848493          	addi	s1,s1,1112
    800030e0:	fd349de3          	bne	s1,s3,800030ba <binit+0x54>
  }
}
    800030e4:	70a2                	ld	ra,40(sp)
    800030e6:	7402                	ld	s0,32(sp)
    800030e8:	64e2                	ld	s1,24(sp)
    800030ea:	6942                	ld	s2,16(sp)
    800030ec:	69a2                	ld	s3,8(sp)
    800030ee:	6a02                	ld	s4,0(sp)
    800030f0:	6145                	addi	sp,sp,48
    800030f2:	8082                	ret

00000000800030f4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030f4:	7179                	addi	sp,sp,-48
    800030f6:	f406                	sd	ra,40(sp)
    800030f8:	f022                	sd	s0,32(sp)
    800030fa:	ec26                	sd	s1,24(sp)
    800030fc:	e84a                	sd	s2,16(sp)
    800030fe:	e44e                	sd	s3,8(sp)
    80003100:	1800                	addi	s0,sp,48
    80003102:	892a                	mv	s2,a0
    80003104:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003106:	00014517          	auipc	a0,0x14
    8000310a:	49250513          	addi	a0,a0,1170 # 80017598 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003116:	0001c497          	auipc	s1,0x1c
    8000311a:	73a4b483          	ld	s1,1850(s1) # 8001f850 <bcache+0x82b8>
    8000311e:	0001c797          	auipc	a5,0x1c
    80003122:	6e278793          	addi	a5,a5,1762 # 8001f800 <bcache+0x8268>
    80003126:	02f48f63          	beq	s1,a5,80003164 <bread+0x70>
    8000312a:	873e                	mv	a4,a5
    8000312c:	a021                	j	80003134 <bread+0x40>
    8000312e:	68a4                	ld	s1,80(s1)
    80003130:	02e48a63          	beq	s1,a4,80003164 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003134:	449c                	lw	a5,8(s1)
    80003136:	ff279ce3          	bne	a5,s2,8000312e <bread+0x3a>
    8000313a:	44dc                	lw	a5,12(s1)
    8000313c:	ff3799e3          	bne	a5,s3,8000312e <bread+0x3a>
      b->refcnt++;
    80003140:	40bc                	lw	a5,64(s1)
    80003142:	2785                	addiw	a5,a5,1
    80003144:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003146:	00014517          	auipc	a0,0x14
    8000314a:	45250513          	addi	a0,a0,1106 # 80017598 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	b3c080e7          	jalr	-1220(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003156:	01048513          	addi	a0,s1,16
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	46e080e7          	jalr	1134(ra) # 800045c8 <acquiresleep>
      return b;
    80003162:	a8b9                	j	800031c0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003164:	0001c497          	auipc	s1,0x1c
    80003168:	6e44b483          	ld	s1,1764(s1) # 8001f848 <bcache+0x82b0>
    8000316c:	0001c797          	auipc	a5,0x1c
    80003170:	69478793          	addi	a5,a5,1684 # 8001f800 <bcache+0x8268>
    80003174:	00f48863          	beq	s1,a5,80003184 <bread+0x90>
    80003178:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000317a:	40bc                	lw	a5,64(s1)
    8000317c:	cf81                	beqz	a5,80003194 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000317e:	64a4                	ld	s1,72(s1)
    80003180:	fee49de3          	bne	s1,a4,8000317a <bread+0x86>
  panic("bget: no buffers");
    80003184:	00005517          	auipc	a0,0x5
    80003188:	3ac50513          	addi	a0,a0,940 # 80008530 <syscalls+0xe0>
    8000318c:	ffffd097          	auipc	ra,0xffffd
    80003190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
      b->dev = dev;
    80003194:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003198:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000319c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031a0:	4785                	li	a5,1
    800031a2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	3f450513          	addi	a0,a0,1012 # 80017598 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	ade080e7          	jalr	-1314(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800031b4:	01048513          	addi	a0,s1,16
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	410080e7          	jalr	1040(ra) # 800045c8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031c0:	409c                	lw	a5,0(s1)
    800031c2:	cb89                	beqz	a5,800031d4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031c4:	8526                	mv	a0,s1
    800031c6:	70a2                	ld	ra,40(sp)
    800031c8:	7402                	ld	s0,32(sp)
    800031ca:	64e2                	ld	s1,24(sp)
    800031cc:	6942                	ld	s2,16(sp)
    800031ce:	69a2                	ld	s3,8(sp)
    800031d0:	6145                	addi	sp,sp,48
    800031d2:	8082                	ret
    virtio_disk_rw(b, 0);
    800031d4:	4581                	li	a1,0
    800031d6:	8526                	mv	a0,s1
    800031d8:	00003097          	auipc	ra,0x3
    800031dc:	07c080e7          	jalr	124(ra) # 80006254 <virtio_disk_rw>
    b->valid = 1;
    800031e0:	4785                	li	a5,1
    800031e2:	c09c                	sw	a5,0(s1)
  return b;
    800031e4:	b7c5                	j	800031c4 <bread+0xd0>

00000000800031e6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	1000                	addi	s0,sp,32
    800031f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f2:	0541                	addi	a0,a0,16
    800031f4:	00001097          	auipc	ra,0x1
    800031f8:	46e080e7          	jalr	1134(ra) # 80004662 <holdingsleep>
    800031fc:	cd01                	beqz	a0,80003214 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031fe:	4585                	li	a1,1
    80003200:	8526                	mv	a0,s1
    80003202:	00003097          	auipc	ra,0x3
    80003206:	052080e7          	jalr	82(ra) # 80006254 <virtio_disk_rw>
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6105                	addi	sp,sp,32
    80003212:	8082                	ret
    panic("bwrite");
    80003214:	00005517          	auipc	a0,0x5
    80003218:	33450513          	addi	a0,a0,820 # 80008548 <syscalls+0xf8>
    8000321c:	ffffd097          	auipc	ra,0xffffd
    80003220:	322080e7          	jalr	802(ra) # 8000053e <panic>

0000000080003224 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	e426                	sd	s1,8(sp)
    8000322c:	e04a                	sd	s2,0(sp)
    8000322e:	1000                	addi	s0,sp,32
    80003230:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003232:	01050913          	addi	s2,a0,16
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	42a080e7          	jalr	1066(ra) # 80004662 <holdingsleep>
    80003240:	c92d                	beqz	a0,800032b2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003242:	854a                	mv	a0,s2
    80003244:	00001097          	auipc	ra,0x1
    80003248:	3da080e7          	jalr	986(ra) # 8000461e <releasesleep>

  acquire(&bcache.lock);
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	34c50513          	addi	a0,a0,844 # 80017598 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	982080e7          	jalr	-1662(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000325c:	40bc                	lw	a5,64(s1)
    8000325e:	37fd                	addiw	a5,a5,-1
    80003260:	0007871b          	sext.w	a4,a5
    80003264:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003266:	eb05                	bnez	a4,80003296 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003268:	68bc                	ld	a5,80(s1)
    8000326a:	64b8                	ld	a4,72(s1)
    8000326c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000326e:	64bc                	ld	a5,72(s1)
    80003270:	68b8                	ld	a4,80(s1)
    80003272:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003274:	0001c797          	auipc	a5,0x1c
    80003278:	32478793          	addi	a5,a5,804 # 8001f598 <bcache+0x8000>
    8000327c:	2b87b703          	ld	a4,696(a5)
    80003280:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003282:	0001c717          	auipc	a4,0x1c
    80003286:	57e70713          	addi	a4,a4,1406 # 8001f800 <bcache+0x8268>
    8000328a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000328c:	2b87b703          	ld	a4,696(a5)
    80003290:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003292:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003296:	00014517          	auipc	a0,0x14
    8000329a:	30250513          	addi	a0,a0,770 # 80017598 <bcache>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	9ec080e7          	jalr	-1556(ra) # 80000c8a <release>
}
    800032a6:	60e2                	ld	ra,24(sp)
    800032a8:	6442                	ld	s0,16(sp)
    800032aa:	64a2                	ld	s1,8(sp)
    800032ac:	6902                	ld	s2,0(sp)
    800032ae:	6105                	addi	sp,sp,32
    800032b0:	8082                	ret
    panic("brelse");
    800032b2:	00005517          	auipc	a0,0x5
    800032b6:	29e50513          	addi	a0,a0,670 # 80008550 <syscalls+0x100>
    800032ba:	ffffd097          	auipc	ra,0xffffd
    800032be:	284080e7          	jalr	644(ra) # 8000053e <panic>

00000000800032c2 <bpin>:

void
bpin(struct buf *b) {
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	1000                	addi	s0,sp,32
    800032cc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ce:	00014517          	auipc	a0,0x14
    800032d2:	2ca50513          	addi	a0,a0,714 # 80017598 <bcache>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	900080e7          	jalr	-1792(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800032de:	40bc                	lw	a5,64(s1)
    800032e0:	2785                	addiw	a5,a5,1
    800032e2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	2b450513          	addi	a0,a0,692 # 80017598 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	99e080e7          	jalr	-1634(ra) # 80000c8a <release>
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	64a2                	ld	s1,8(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret

00000000800032fe <bunpin>:

void
bunpin(struct buf *b) {
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	1000                	addi	s0,sp,32
    80003308:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000330a:	00014517          	auipc	a0,0x14
    8000330e:	28e50513          	addi	a0,a0,654 # 80017598 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	8c4080e7          	jalr	-1852(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000331a:	40bc                	lw	a5,64(s1)
    8000331c:	37fd                	addiw	a5,a5,-1
    8000331e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003320:	00014517          	auipc	a0,0x14
    80003324:	27850513          	addi	a0,a0,632 # 80017598 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	962080e7          	jalr	-1694(ra) # 80000c8a <release>
}
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	64a2                	ld	s1,8(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	e426                	sd	s1,8(sp)
    80003342:	e04a                	sd	s2,0(sp)
    80003344:	1000                	addi	s0,sp,32
    80003346:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003348:	00d5d59b          	srliw	a1,a1,0xd
    8000334c:	0001d797          	auipc	a5,0x1d
    80003350:	9287a783          	lw	a5,-1752(a5) # 8001fc74 <sb+0x1c>
    80003354:	9dbd                	addw	a1,a1,a5
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	d9e080e7          	jalr	-610(ra) # 800030f4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000335e:	0074f713          	andi	a4,s1,7
    80003362:	4785                	li	a5,1
    80003364:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003368:	14ce                	slli	s1,s1,0x33
    8000336a:	90d9                	srli	s1,s1,0x36
    8000336c:	00950733          	add	a4,a0,s1
    80003370:	05874703          	lbu	a4,88(a4)
    80003374:	00e7f6b3          	and	a3,a5,a4
    80003378:	c69d                	beqz	a3,800033a6 <bfree+0x6c>
    8000337a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000337c:	94aa                	add	s1,s1,a0
    8000337e:	fff7c793          	not	a5,a5
    80003382:	8ff9                	and	a5,a5,a4
    80003384:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003388:	00001097          	auipc	ra,0x1
    8000338c:	120080e7          	jalr	288(ra) # 800044a8 <log_write>
  brelse(bp);
    80003390:	854a                	mv	a0,s2
    80003392:	00000097          	auipc	ra,0x0
    80003396:	e92080e7          	jalr	-366(ra) # 80003224 <brelse>
}
    8000339a:	60e2                	ld	ra,24(sp)
    8000339c:	6442                	ld	s0,16(sp)
    8000339e:	64a2                	ld	s1,8(sp)
    800033a0:	6902                	ld	s2,0(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret
    panic("freeing free block");
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	1b250513          	addi	a0,a0,434 # 80008558 <syscalls+0x108>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	190080e7          	jalr	400(ra) # 8000053e <panic>

00000000800033b6 <balloc>:
{
    800033b6:	711d                	addi	sp,sp,-96
    800033b8:	ec86                	sd	ra,88(sp)
    800033ba:	e8a2                	sd	s0,80(sp)
    800033bc:	e4a6                	sd	s1,72(sp)
    800033be:	e0ca                	sd	s2,64(sp)
    800033c0:	fc4e                	sd	s3,56(sp)
    800033c2:	f852                	sd	s4,48(sp)
    800033c4:	f456                	sd	s5,40(sp)
    800033c6:	f05a                	sd	s6,32(sp)
    800033c8:	ec5e                	sd	s7,24(sp)
    800033ca:	e862                	sd	s8,16(sp)
    800033cc:	e466                	sd	s9,8(sp)
    800033ce:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033d0:	0001d797          	auipc	a5,0x1d
    800033d4:	88c7a783          	lw	a5,-1908(a5) # 8001fc5c <sb+0x4>
    800033d8:	10078163          	beqz	a5,800034da <balloc+0x124>
    800033dc:	8baa                	mv	s7,a0
    800033de:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033e0:	0001db17          	auipc	s6,0x1d
    800033e4:	878b0b13          	addi	s6,s6,-1928 # 8001fc58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ea:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ec:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033ee:	6c89                	lui	s9,0x2
    800033f0:	a061                	j	80003478 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033f2:	974a                	add	a4,a4,s2
    800033f4:	8fd5                	or	a5,a5,a3
    800033f6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033fa:	854a                	mv	a0,s2
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	0ac080e7          	jalr	172(ra) # 800044a8 <log_write>
        brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e1e080e7          	jalr	-482(ra) # 80003224 <brelse>
  bp = bread(dev, bno);
    8000340e:	85a6                	mv	a1,s1
    80003410:	855e                	mv	a0,s7
    80003412:	00000097          	auipc	ra,0x0
    80003416:	ce2080e7          	jalr	-798(ra) # 800030f4 <bread>
    8000341a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000341c:	40000613          	li	a2,1024
    80003420:	4581                	li	a1,0
    80003422:	05850513          	addi	a0,a0,88
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	8ac080e7          	jalr	-1876(ra) # 80000cd2 <memset>
  log_write(bp);
    8000342e:	854a                	mv	a0,s2
    80003430:	00001097          	auipc	ra,0x1
    80003434:	078080e7          	jalr	120(ra) # 800044a8 <log_write>
  brelse(bp);
    80003438:	854a                	mv	a0,s2
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	dea080e7          	jalr	-534(ra) # 80003224 <brelse>
}
    80003442:	8526                	mv	a0,s1
    80003444:	60e6                	ld	ra,88(sp)
    80003446:	6446                	ld	s0,80(sp)
    80003448:	64a6                	ld	s1,72(sp)
    8000344a:	6906                	ld	s2,64(sp)
    8000344c:	79e2                	ld	s3,56(sp)
    8000344e:	7a42                	ld	s4,48(sp)
    80003450:	7aa2                	ld	s5,40(sp)
    80003452:	7b02                	ld	s6,32(sp)
    80003454:	6be2                	ld	s7,24(sp)
    80003456:	6c42                	ld	s8,16(sp)
    80003458:	6ca2                	ld	s9,8(sp)
    8000345a:	6125                	addi	sp,sp,96
    8000345c:	8082                	ret
    brelse(bp);
    8000345e:	854a                	mv	a0,s2
    80003460:	00000097          	auipc	ra,0x0
    80003464:	dc4080e7          	jalr	-572(ra) # 80003224 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003468:	015c87bb          	addw	a5,s9,s5
    8000346c:	00078a9b          	sext.w	s5,a5
    80003470:	004b2703          	lw	a4,4(s6)
    80003474:	06eaf363          	bgeu	s5,a4,800034da <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003478:	41fad79b          	sraiw	a5,s5,0x1f
    8000347c:	0137d79b          	srliw	a5,a5,0x13
    80003480:	015787bb          	addw	a5,a5,s5
    80003484:	40d7d79b          	sraiw	a5,a5,0xd
    80003488:	01cb2583          	lw	a1,28(s6)
    8000348c:	9dbd                	addw	a1,a1,a5
    8000348e:	855e                	mv	a0,s7
    80003490:	00000097          	auipc	ra,0x0
    80003494:	c64080e7          	jalr	-924(ra) # 800030f4 <bread>
    80003498:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349a:	004b2503          	lw	a0,4(s6)
    8000349e:	000a849b          	sext.w	s1,s5
    800034a2:	8662                	mv	a2,s8
    800034a4:	faa4fde3          	bgeu	s1,a0,8000345e <balloc+0xa8>
      m = 1 << (bi % 8);
    800034a8:	41f6579b          	sraiw	a5,a2,0x1f
    800034ac:	01d7d69b          	srliw	a3,a5,0x1d
    800034b0:	00c6873b          	addw	a4,a3,a2
    800034b4:	00777793          	andi	a5,a4,7
    800034b8:	9f95                	subw	a5,a5,a3
    800034ba:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034be:	4037571b          	sraiw	a4,a4,0x3
    800034c2:	00e906b3          	add	a3,s2,a4
    800034c6:	0586c683          	lbu	a3,88(a3)
    800034ca:	00d7f5b3          	and	a1,a5,a3
    800034ce:	d195                	beqz	a1,800033f2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d0:	2605                	addiw	a2,a2,1
    800034d2:	2485                	addiw	s1,s1,1
    800034d4:	fd4618e3          	bne	a2,s4,800034a4 <balloc+0xee>
    800034d8:	b759                	j	8000345e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	09650513          	addi	a0,a0,150 # 80008570 <syscalls+0x120>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	0a6080e7          	jalr	166(ra) # 80000588 <printf>
  return 0;
    800034ea:	4481                	li	s1,0
    800034ec:	bf99                	j	80003442 <balloc+0x8c>

00000000800034ee <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ee:	7179                	addi	sp,sp,-48
    800034f0:	f406                	sd	ra,40(sp)
    800034f2:	f022                	sd	s0,32(sp)
    800034f4:	ec26                	sd	s1,24(sp)
    800034f6:	e84a                	sd	s2,16(sp)
    800034f8:	e44e                	sd	s3,8(sp)
    800034fa:	e052                	sd	s4,0(sp)
    800034fc:	1800                	addi	s0,sp,48
    800034fe:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003500:	47ad                	li	a5,11
    80003502:	02b7e763          	bltu	a5,a1,80003530 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003506:	02059493          	slli	s1,a1,0x20
    8000350a:	9081                	srli	s1,s1,0x20
    8000350c:	048a                	slli	s1,s1,0x2
    8000350e:	94aa                	add	s1,s1,a0
    80003510:	0504a903          	lw	s2,80(s1)
    80003514:	06091e63          	bnez	s2,80003590 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003518:	4108                	lw	a0,0(a0)
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	e9c080e7          	jalr	-356(ra) # 800033b6 <balloc>
    80003522:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003526:	06090563          	beqz	s2,80003590 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000352a:	0524a823          	sw	s2,80(s1)
    8000352e:	a08d                	j	80003590 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003530:	ff45849b          	addiw	s1,a1,-12
    80003534:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003538:	0ff00793          	li	a5,255
    8000353c:	08e7e563          	bltu	a5,a4,800035c6 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003540:	08052903          	lw	s2,128(a0)
    80003544:	00091d63          	bnez	s2,8000355e <bmap+0x70>
      addr = balloc(ip->dev);
    80003548:	4108                	lw	a0,0(a0)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e6c080e7          	jalr	-404(ra) # 800033b6 <balloc>
    80003552:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003556:	02090d63          	beqz	s2,80003590 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000355a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000355e:	85ca                	mv	a1,s2
    80003560:	0009a503          	lw	a0,0(s3)
    80003564:	00000097          	auipc	ra,0x0
    80003568:	b90080e7          	jalr	-1136(ra) # 800030f4 <bread>
    8000356c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000356e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003572:	02049593          	slli	a1,s1,0x20
    80003576:	9181                	srli	a1,a1,0x20
    80003578:	058a                	slli	a1,a1,0x2
    8000357a:	00b784b3          	add	s1,a5,a1
    8000357e:	0004a903          	lw	s2,0(s1)
    80003582:	02090063          	beqz	s2,800035a2 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003586:	8552                	mv	a0,s4
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	c9c080e7          	jalr	-868(ra) # 80003224 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003590:	854a                	mv	a0,s2
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6a02                	ld	s4,0(sp)
    8000359e:	6145                	addi	sp,sp,48
    800035a0:	8082                	ret
      addr = balloc(ip->dev);
    800035a2:	0009a503          	lw	a0,0(s3)
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e10080e7          	jalr	-496(ra) # 800033b6 <balloc>
    800035ae:	0005091b          	sext.w	s2,a0
      if(addr){
    800035b2:	fc090ae3          	beqz	s2,80003586 <bmap+0x98>
        a[bn] = addr;
    800035b6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035ba:	8552                	mv	a0,s4
    800035bc:	00001097          	auipc	ra,0x1
    800035c0:	eec080e7          	jalr	-276(ra) # 800044a8 <log_write>
    800035c4:	b7c9                	j	80003586 <bmap+0x98>
  panic("bmap: out of range");
    800035c6:	00005517          	auipc	a0,0x5
    800035ca:	fc250513          	addi	a0,a0,-62 # 80008588 <syscalls+0x138>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800035d6 <iget>:
{
    800035d6:	7179                	addi	sp,sp,-48
    800035d8:	f406                	sd	ra,40(sp)
    800035da:	f022                	sd	s0,32(sp)
    800035dc:	ec26                	sd	s1,24(sp)
    800035de:	e84a                	sd	s2,16(sp)
    800035e0:	e44e                	sd	s3,8(sp)
    800035e2:	e052                	sd	s4,0(sp)
    800035e4:	1800                	addi	s0,sp,48
    800035e6:	89aa                	mv	s3,a0
    800035e8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	68e50513          	addi	a0,a0,1678 # 8001fc78 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
  empty = 0;
    800035fa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035fc:	0001c497          	auipc	s1,0x1c
    80003600:	69448493          	addi	s1,s1,1684 # 8001fc90 <itable+0x18>
    80003604:	0001e697          	auipc	a3,0x1e
    80003608:	11c68693          	addi	a3,a3,284 # 80021720 <log>
    8000360c:	a039                	j	8000361a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000360e:	02090b63          	beqz	s2,80003644 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003612:	08848493          	addi	s1,s1,136
    80003616:	02d48a63          	beq	s1,a3,8000364a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000361a:	449c                	lw	a5,8(s1)
    8000361c:	fef059e3          	blez	a5,8000360e <iget+0x38>
    80003620:	4098                	lw	a4,0(s1)
    80003622:	ff3716e3          	bne	a4,s3,8000360e <iget+0x38>
    80003626:	40d8                	lw	a4,4(s1)
    80003628:	ff4713e3          	bne	a4,s4,8000360e <iget+0x38>
      ip->ref++;
    8000362c:	2785                	addiw	a5,a5,1
    8000362e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	64850513          	addi	a0,a0,1608 # 8001fc78 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
      return ip;
    80003640:	8926                	mv	s2,s1
    80003642:	a03d                	j	80003670 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003644:	f7f9                	bnez	a5,80003612 <iget+0x3c>
    80003646:	8926                	mv	s2,s1
    80003648:	b7e9                	j	80003612 <iget+0x3c>
  if(empty == 0)
    8000364a:	02090c63          	beqz	s2,80003682 <iget+0xac>
  ip->dev = dev;
    8000364e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003652:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003656:	4785                	li	a5,1
    80003658:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000365c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003660:	0001c517          	auipc	a0,0x1c
    80003664:	61850513          	addi	a0,a0,1560 # 8001fc78 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	622080e7          	jalr	1570(ra) # 80000c8a <release>
}
    80003670:	854a                	mv	a0,s2
    80003672:	70a2                	ld	ra,40(sp)
    80003674:	7402                	ld	s0,32(sp)
    80003676:	64e2                	ld	s1,24(sp)
    80003678:	6942                	ld	s2,16(sp)
    8000367a:	69a2                	ld	s3,8(sp)
    8000367c:	6a02                	ld	s4,0(sp)
    8000367e:	6145                	addi	sp,sp,48
    80003680:	8082                	ret
    panic("iget: no inodes");
    80003682:	00005517          	auipc	a0,0x5
    80003686:	f1e50513          	addi	a0,a0,-226 # 800085a0 <syscalls+0x150>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	eb4080e7          	jalr	-332(ra) # 8000053e <panic>

0000000080003692 <fsinit>:
fsinit(int dev) {
    80003692:	7179                	addi	sp,sp,-48
    80003694:	f406                	sd	ra,40(sp)
    80003696:	f022                	sd	s0,32(sp)
    80003698:	ec26                	sd	s1,24(sp)
    8000369a:	e84a                	sd	s2,16(sp)
    8000369c:	e44e                	sd	s3,8(sp)
    8000369e:	1800                	addi	s0,sp,48
    800036a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036a2:	4585                	li	a1,1
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	a50080e7          	jalr	-1456(ra) # 800030f4 <bread>
    800036ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036ae:	0001c997          	auipc	s3,0x1c
    800036b2:	5aa98993          	addi	s3,s3,1450 # 8001fc58 <sb>
    800036b6:	02000613          	li	a2,32
    800036ba:	05850593          	addi	a1,a0,88
    800036be:	854e                	mv	a0,s3
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	66e080e7          	jalr	1646(ra) # 80000d2e <memmove>
  brelse(bp);
    800036c8:	8526                	mv	a0,s1
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	b5a080e7          	jalr	-1190(ra) # 80003224 <brelse>
  if(sb.magic != FSMAGIC)
    800036d2:	0009a703          	lw	a4,0(s3)
    800036d6:	102037b7          	lui	a5,0x10203
    800036da:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036de:	02f71263          	bne	a4,a5,80003702 <fsinit+0x70>
  initlog(dev, &sb);
    800036e2:	0001c597          	auipc	a1,0x1c
    800036e6:	57658593          	addi	a1,a1,1398 # 8001fc58 <sb>
    800036ea:	854a                	mv	a0,s2
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	b40080e7          	jalr	-1216(ra) # 8000422c <initlog>
}
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6145                	addi	sp,sp,48
    80003700:	8082                	ret
    panic("invalid file system");
    80003702:	00005517          	auipc	a0,0x5
    80003706:	eae50513          	addi	a0,a0,-338 # 800085b0 <syscalls+0x160>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	e34080e7          	jalr	-460(ra) # 8000053e <panic>

0000000080003712 <iinit>:
{
    80003712:	7179                	addi	sp,sp,-48
    80003714:	f406                	sd	ra,40(sp)
    80003716:	f022                	sd	s0,32(sp)
    80003718:	ec26                	sd	s1,24(sp)
    8000371a:	e84a                	sd	s2,16(sp)
    8000371c:	e44e                	sd	s3,8(sp)
    8000371e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003720:	00005597          	auipc	a1,0x5
    80003724:	ea858593          	addi	a1,a1,-344 # 800085c8 <syscalls+0x178>
    80003728:	0001c517          	auipc	a0,0x1c
    8000372c:	55050513          	addi	a0,a0,1360 # 8001fc78 <itable>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	416080e7          	jalr	1046(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003738:	0001c497          	auipc	s1,0x1c
    8000373c:	56848493          	addi	s1,s1,1384 # 8001fca0 <itable+0x28>
    80003740:	0001e997          	auipc	s3,0x1e
    80003744:	ff098993          	addi	s3,s3,-16 # 80021730 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003748:	00005917          	auipc	s2,0x5
    8000374c:	e8890913          	addi	s2,s2,-376 # 800085d0 <syscalls+0x180>
    80003750:	85ca                	mv	a1,s2
    80003752:	8526                	mv	a0,s1
    80003754:	00001097          	auipc	ra,0x1
    80003758:	e3a080e7          	jalr	-454(ra) # 8000458e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000375c:	08848493          	addi	s1,s1,136
    80003760:	ff3498e3          	bne	s1,s3,80003750 <iinit+0x3e>
}
    80003764:	70a2                	ld	ra,40(sp)
    80003766:	7402                	ld	s0,32(sp)
    80003768:	64e2                	ld	s1,24(sp)
    8000376a:	6942                	ld	s2,16(sp)
    8000376c:	69a2                	ld	s3,8(sp)
    8000376e:	6145                	addi	sp,sp,48
    80003770:	8082                	ret

0000000080003772 <ialloc>:
{
    80003772:	715d                	addi	sp,sp,-80
    80003774:	e486                	sd	ra,72(sp)
    80003776:	e0a2                	sd	s0,64(sp)
    80003778:	fc26                	sd	s1,56(sp)
    8000377a:	f84a                	sd	s2,48(sp)
    8000377c:	f44e                	sd	s3,40(sp)
    8000377e:	f052                	sd	s4,32(sp)
    80003780:	ec56                	sd	s5,24(sp)
    80003782:	e85a                	sd	s6,16(sp)
    80003784:	e45e                	sd	s7,8(sp)
    80003786:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003788:	0001c717          	auipc	a4,0x1c
    8000378c:	4dc72703          	lw	a4,1244(a4) # 8001fc64 <sb+0xc>
    80003790:	4785                	li	a5,1
    80003792:	04e7fa63          	bgeu	a5,a4,800037e6 <ialloc+0x74>
    80003796:	8aaa                	mv	s5,a0
    80003798:	8bae                	mv	s7,a1
    8000379a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000379c:	0001ca17          	auipc	s4,0x1c
    800037a0:	4bca0a13          	addi	s4,s4,1212 # 8001fc58 <sb>
    800037a4:	00048b1b          	sext.w	s6,s1
    800037a8:	0044d793          	srli	a5,s1,0x4
    800037ac:	018a2583          	lw	a1,24(s4)
    800037b0:	9dbd                	addw	a1,a1,a5
    800037b2:	8556                	mv	a0,s5
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	940080e7          	jalr	-1728(ra) # 800030f4 <bread>
    800037bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037be:	05850993          	addi	s3,a0,88
    800037c2:	00f4f793          	andi	a5,s1,15
    800037c6:	079a                	slli	a5,a5,0x6
    800037c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ca:	00099783          	lh	a5,0(s3)
    800037ce:	c3a1                	beqz	a5,8000380e <ialloc+0x9c>
    brelse(bp);
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	a54080e7          	jalr	-1452(ra) # 80003224 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037d8:	0485                	addi	s1,s1,1
    800037da:	00ca2703          	lw	a4,12(s4)
    800037de:	0004879b          	sext.w	a5,s1
    800037e2:	fce7e1e3          	bltu	a5,a4,800037a4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	df250513          	addi	a0,a0,-526 # 800085d8 <syscalls+0x188>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d9a080e7          	jalr	-614(ra) # 80000588 <printf>
  return 0;
    800037f6:	4501                	li	a0,0
}
    800037f8:	60a6                	ld	ra,72(sp)
    800037fa:	6406                	ld	s0,64(sp)
    800037fc:	74e2                	ld	s1,56(sp)
    800037fe:	7942                	ld	s2,48(sp)
    80003800:	79a2                	ld	s3,40(sp)
    80003802:	7a02                	ld	s4,32(sp)
    80003804:	6ae2                	ld	s5,24(sp)
    80003806:	6b42                	ld	s6,16(sp)
    80003808:	6ba2                	ld	s7,8(sp)
    8000380a:	6161                	addi	sp,sp,80
    8000380c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000380e:	04000613          	li	a2,64
    80003812:	4581                	li	a1,0
    80003814:	854e                	mv	a0,s3
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	4bc080e7          	jalr	1212(ra) # 80000cd2 <memset>
      dip->type = type;
    8000381e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	c84080e7          	jalr	-892(ra) # 800044a8 <log_write>
      brelse(bp);
    8000382c:	854a                	mv	a0,s2
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	9f6080e7          	jalr	-1546(ra) # 80003224 <brelse>
      return iget(dev, inum);
    80003836:	85da                	mv	a1,s6
    80003838:	8556                	mv	a0,s5
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	d9c080e7          	jalr	-612(ra) # 800035d6 <iget>
    80003842:	bf5d                	j	800037f8 <ialloc+0x86>

0000000080003844 <iupdate>:
{
    80003844:	1101                	addi	sp,sp,-32
    80003846:	ec06                	sd	ra,24(sp)
    80003848:	e822                	sd	s0,16(sp)
    8000384a:	e426                	sd	s1,8(sp)
    8000384c:	e04a                	sd	s2,0(sp)
    8000384e:	1000                	addi	s0,sp,32
    80003850:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003852:	415c                	lw	a5,4(a0)
    80003854:	0047d79b          	srliw	a5,a5,0x4
    80003858:	0001c597          	auipc	a1,0x1c
    8000385c:	4185a583          	lw	a1,1048(a1) # 8001fc70 <sb+0x18>
    80003860:	9dbd                	addw	a1,a1,a5
    80003862:	4108                	lw	a0,0(a0)
    80003864:	00000097          	auipc	ra,0x0
    80003868:	890080e7          	jalr	-1904(ra) # 800030f4 <bread>
    8000386c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000386e:	05850793          	addi	a5,a0,88
    80003872:	40c8                	lw	a0,4(s1)
    80003874:	893d                	andi	a0,a0,15
    80003876:	051a                	slli	a0,a0,0x6
    80003878:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000387a:	04449703          	lh	a4,68(s1)
    8000387e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003882:	04649703          	lh	a4,70(s1)
    80003886:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000388a:	04849703          	lh	a4,72(s1)
    8000388e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003892:	04a49703          	lh	a4,74(s1)
    80003896:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000389a:	44f8                	lw	a4,76(s1)
    8000389c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000389e:	03400613          	li	a2,52
    800038a2:	05048593          	addi	a1,s1,80
    800038a6:	0531                	addi	a0,a0,12
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	486080e7          	jalr	1158(ra) # 80000d2e <memmove>
  log_write(bp);
    800038b0:	854a                	mv	a0,s2
    800038b2:	00001097          	auipc	ra,0x1
    800038b6:	bf6080e7          	jalr	-1034(ra) # 800044a8 <log_write>
  brelse(bp);
    800038ba:	854a                	mv	a0,s2
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	968080e7          	jalr	-1688(ra) # 80003224 <brelse>
}
    800038c4:	60e2                	ld	ra,24(sp)
    800038c6:	6442                	ld	s0,16(sp)
    800038c8:	64a2                	ld	s1,8(sp)
    800038ca:	6902                	ld	s2,0(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret

00000000800038d0 <idup>:
{
    800038d0:	1101                	addi	sp,sp,-32
    800038d2:	ec06                	sd	ra,24(sp)
    800038d4:	e822                	sd	s0,16(sp)
    800038d6:	e426                	sd	s1,8(sp)
    800038d8:	1000                	addi	s0,sp,32
    800038da:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038dc:	0001c517          	auipc	a0,0x1c
    800038e0:	39c50513          	addi	a0,a0,924 # 8001fc78 <itable>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	2f2080e7          	jalr	754(ra) # 80000bd6 <acquire>
  ip->ref++;
    800038ec:	449c                	lw	a5,8(s1)
    800038ee:	2785                	addiw	a5,a5,1
    800038f0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f2:	0001c517          	auipc	a0,0x1c
    800038f6:	38650513          	addi	a0,a0,902 # 8001fc78 <itable>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	390080e7          	jalr	912(ra) # 80000c8a <release>
}
    80003902:	8526                	mv	a0,s1
    80003904:	60e2                	ld	ra,24(sp)
    80003906:	6442                	ld	s0,16(sp)
    80003908:	64a2                	ld	s1,8(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret

000000008000390e <ilock>:
{
    8000390e:	1101                	addi	sp,sp,-32
    80003910:	ec06                	sd	ra,24(sp)
    80003912:	e822                	sd	s0,16(sp)
    80003914:	e426                	sd	s1,8(sp)
    80003916:	e04a                	sd	s2,0(sp)
    80003918:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000391a:	c115                	beqz	a0,8000393e <ilock+0x30>
    8000391c:	84aa                	mv	s1,a0
    8000391e:	451c                	lw	a5,8(a0)
    80003920:	00f05f63          	blez	a5,8000393e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003924:	0541                	addi	a0,a0,16
    80003926:	00001097          	auipc	ra,0x1
    8000392a:	ca2080e7          	jalr	-862(ra) # 800045c8 <acquiresleep>
  if(ip->valid == 0){
    8000392e:	40bc                	lw	a5,64(s1)
    80003930:	cf99                	beqz	a5,8000394e <ilock+0x40>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
    panic("ilock");
    8000393e:	00005517          	auipc	a0,0x5
    80003942:	cb250513          	addi	a0,a0,-846 # 800085f0 <syscalls+0x1a0>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000394e:	40dc                	lw	a5,4(s1)
    80003950:	0047d79b          	srliw	a5,a5,0x4
    80003954:	0001c597          	auipc	a1,0x1c
    80003958:	31c5a583          	lw	a1,796(a1) # 8001fc70 <sb+0x18>
    8000395c:	9dbd                	addw	a1,a1,a5
    8000395e:	4088                	lw	a0,0(s1)
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	794080e7          	jalr	1940(ra) # 800030f4 <bread>
    80003968:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000396a:	05850593          	addi	a1,a0,88
    8000396e:	40dc                	lw	a5,4(s1)
    80003970:	8bbd                	andi	a5,a5,15
    80003972:	079a                	slli	a5,a5,0x6
    80003974:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003976:	00059783          	lh	a5,0(a1)
    8000397a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000397e:	00259783          	lh	a5,2(a1)
    80003982:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003986:	00459783          	lh	a5,4(a1)
    8000398a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000398e:	00659783          	lh	a5,6(a1)
    80003992:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003996:	459c                	lw	a5,8(a1)
    80003998:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000399a:	03400613          	li	a2,52
    8000399e:	05b1                	addi	a1,a1,12
    800039a0:	05048513          	addi	a0,s1,80
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	38a080e7          	jalr	906(ra) # 80000d2e <memmove>
    brelse(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	876080e7          	jalr	-1930(ra) # 80003224 <brelse>
    ip->valid = 1;
    800039b6:	4785                	li	a5,1
    800039b8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ba:	04449783          	lh	a5,68(s1)
    800039be:	fbb5                	bnez	a5,80003932 <ilock+0x24>
      panic("ilock: no type");
    800039c0:	00005517          	auipc	a0,0x5
    800039c4:	c3850513          	addi	a0,a0,-968 # 800085f8 <syscalls+0x1a8>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	b76080e7          	jalr	-1162(ra) # 8000053e <panic>

00000000800039d0 <iunlock>:
{
    800039d0:	1101                	addi	sp,sp,-32
    800039d2:	ec06                	sd	ra,24(sp)
    800039d4:	e822                	sd	s0,16(sp)
    800039d6:	e426                	sd	s1,8(sp)
    800039d8:	e04a                	sd	s2,0(sp)
    800039da:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039dc:	c905                	beqz	a0,80003a0c <iunlock+0x3c>
    800039de:	84aa                	mv	s1,a0
    800039e0:	01050913          	addi	s2,a0,16
    800039e4:	854a                	mv	a0,s2
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	c7c080e7          	jalr	-900(ra) # 80004662 <holdingsleep>
    800039ee:	cd19                	beqz	a0,80003a0c <iunlock+0x3c>
    800039f0:	449c                	lw	a5,8(s1)
    800039f2:	00f05d63          	blez	a5,80003a0c <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	c26080e7          	jalr	-986(ra) # 8000461e <releasesleep>
}
    80003a00:	60e2                	ld	ra,24(sp)
    80003a02:	6442                	ld	s0,16(sp)
    80003a04:	64a2                	ld	s1,8(sp)
    80003a06:	6902                	ld	s2,0(sp)
    80003a08:	6105                	addi	sp,sp,32
    80003a0a:	8082                	ret
    panic("iunlock");
    80003a0c:	00005517          	auipc	a0,0x5
    80003a10:	bfc50513          	addi	a0,a0,-1028 # 80008608 <syscalls+0x1b8>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>

0000000080003a1c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a1c:	7179                	addi	sp,sp,-48
    80003a1e:	f406                	sd	ra,40(sp)
    80003a20:	f022                	sd	s0,32(sp)
    80003a22:	ec26                	sd	s1,24(sp)
    80003a24:	e84a                	sd	s2,16(sp)
    80003a26:	e44e                	sd	s3,8(sp)
    80003a28:	e052                	sd	s4,0(sp)
    80003a2a:	1800                	addi	s0,sp,48
    80003a2c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a2e:	05050493          	addi	s1,a0,80
    80003a32:	08050913          	addi	s2,a0,128
    80003a36:	a021                	j	80003a3e <itrunc+0x22>
    80003a38:	0491                	addi	s1,s1,4
    80003a3a:	01248d63          	beq	s1,s2,80003a54 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a3e:	408c                	lw	a1,0(s1)
    80003a40:	dde5                	beqz	a1,80003a38 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a42:	0009a503          	lw	a0,0(s3)
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	8f4080e7          	jalr	-1804(ra) # 8000333a <bfree>
      ip->addrs[i] = 0;
    80003a4e:	0004a023          	sw	zero,0(s1)
    80003a52:	b7dd                	j	80003a38 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a54:	0809a583          	lw	a1,128(s3)
    80003a58:	e185                	bnez	a1,80003a78 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a5a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a5e:	854e                	mv	a0,s3
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	de4080e7          	jalr	-540(ra) # 80003844 <iupdate>
}
    80003a68:	70a2                	ld	ra,40(sp)
    80003a6a:	7402                	ld	s0,32(sp)
    80003a6c:	64e2                	ld	s1,24(sp)
    80003a6e:	6942                	ld	s2,16(sp)
    80003a70:	69a2                	ld	s3,8(sp)
    80003a72:	6a02                	ld	s4,0(sp)
    80003a74:	6145                	addi	sp,sp,48
    80003a76:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a78:	0009a503          	lw	a0,0(s3)
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	678080e7          	jalr	1656(ra) # 800030f4 <bread>
    80003a84:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a86:	05850493          	addi	s1,a0,88
    80003a8a:	45850913          	addi	s2,a0,1112
    80003a8e:	a021                	j	80003a96 <itrunc+0x7a>
    80003a90:	0491                	addi	s1,s1,4
    80003a92:	01248b63          	beq	s1,s2,80003aa8 <itrunc+0x8c>
      if(a[j])
    80003a96:	408c                	lw	a1,0(s1)
    80003a98:	dde5                	beqz	a1,80003a90 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a9a:	0009a503          	lw	a0,0(s3)
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	89c080e7          	jalr	-1892(ra) # 8000333a <bfree>
    80003aa6:	b7ed                	j	80003a90 <itrunc+0x74>
    brelse(bp);
    80003aa8:	8552                	mv	a0,s4
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	77a080e7          	jalr	1914(ra) # 80003224 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ab2:	0809a583          	lw	a1,128(s3)
    80003ab6:	0009a503          	lw	a0,0(s3)
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	880080e7          	jalr	-1920(ra) # 8000333a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ac2:	0809a023          	sw	zero,128(s3)
    80003ac6:	bf51                	j	80003a5a <itrunc+0x3e>

0000000080003ac8 <iput>:
{
    80003ac8:	1101                	addi	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	e426                	sd	s1,8(sp)
    80003ad0:	e04a                	sd	s2,0(sp)
    80003ad2:	1000                	addi	s0,sp,32
    80003ad4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ad6:	0001c517          	auipc	a0,0x1c
    80003ada:	1a250513          	addi	a0,a0,418 # 8001fc78 <itable>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	0f8080e7          	jalr	248(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae6:	4498                	lw	a4,8(s1)
    80003ae8:	4785                	li	a5,1
    80003aea:	02f70363          	beq	a4,a5,80003b10 <iput+0x48>
  ip->ref--;
    80003aee:	449c                	lw	a5,8(s1)
    80003af0:	37fd                	addiw	a5,a5,-1
    80003af2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003af4:	0001c517          	auipc	a0,0x1c
    80003af8:	18450513          	addi	a0,a0,388 # 8001fc78 <itable>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	18e080e7          	jalr	398(ra) # 80000c8a <release>
}
    80003b04:	60e2                	ld	ra,24(sp)
    80003b06:	6442                	ld	s0,16(sp)
    80003b08:	64a2                	ld	s1,8(sp)
    80003b0a:	6902                	ld	s2,0(sp)
    80003b0c:	6105                	addi	sp,sp,32
    80003b0e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b10:	40bc                	lw	a5,64(s1)
    80003b12:	dff1                	beqz	a5,80003aee <iput+0x26>
    80003b14:	04a49783          	lh	a5,74(s1)
    80003b18:	fbf9                	bnez	a5,80003aee <iput+0x26>
    acquiresleep(&ip->lock);
    80003b1a:	01048913          	addi	s2,s1,16
    80003b1e:	854a                	mv	a0,s2
    80003b20:	00001097          	auipc	ra,0x1
    80003b24:	aa8080e7          	jalr	-1368(ra) # 800045c8 <acquiresleep>
    release(&itable.lock);
    80003b28:	0001c517          	auipc	a0,0x1c
    80003b2c:	15050513          	addi	a0,a0,336 # 8001fc78 <itable>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	15a080e7          	jalr	346(ra) # 80000c8a <release>
    itrunc(ip);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	ee2080e7          	jalr	-286(ra) # 80003a1c <itrunc>
    ip->type = 0;
    80003b42:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	cfc080e7          	jalr	-772(ra) # 80003844 <iupdate>
    ip->valid = 0;
    80003b50:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b54:	854a                	mv	a0,s2
    80003b56:	00001097          	auipc	ra,0x1
    80003b5a:	ac8080e7          	jalr	-1336(ra) # 8000461e <releasesleep>
    acquire(&itable.lock);
    80003b5e:	0001c517          	auipc	a0,0x1c
    80003b62:	11a50513          	addi	a0,a0,282 # 8001fc78 <itable>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	070080e7          	jalr	112(ra) # 80000bd6 <acquire>
    80003b6e:	b741                	j	80003aee <iput+0x26>

0000000080003b70 <iunlockput>:
{
    80003b70:	1101                	addi	sp,sp,-32
    80003b72:	ec06                	sd	ra,24(sp)
    80003b74:	e822                	sd	s0,16(sp)
    80003b76:	e426                	sd	s1,8(sp)
    80003b78:	1000                	addi	s0,sp,32
    80003b7a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	e54080e7          	jalr	-428(ra) # 800039d0 <iunlock>
  iput(ip);
    80003b84:	8526                	mv	a0,s1
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	f42080e7          	jalr	-190(ra) # 80003ac8 <iput>
}
    80003b8e:	60e2                	ld	ra,24(sp)
    80003b90:	6442                	ld	s0,16(sp)
    80003b92:	64a2                	ld	s1,8(sp)
    80003b94:	6105                	addi	sp,sp,32
    80003b96:	8082                	ret

0000000080003b98 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b98:	1141                	addi	sp,sp,-16
    80003b9a:	e422                	sd	s0,8(sp)
    80003b9c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b9e:	411c                	lw	a5,0(a0)
    80003ba0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ba2:	415c                	lw	a5,4(a0)
    80003ba4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ba6:	04451783          	lh	a5,68(a0)
    80003baa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bae:	04a51783          	lh	a5,74(a0)
    80003bb2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bb6:	04c56783          	lwu	a5,76(a0)
    80003bba:	e99c                	sd	a5,16(a1)
}
    80003bbc:	6422                	ld	s0,8(sp)
    80003bbe:	0141                	addi	sp,sp,16
    80003bc0:	8082                	ret

0000000080003bc2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bc2:	457c                	lw	a5,76(a0)
    80003bc4:	0ed7e963          	bltu	a5,a3,80003cb6 <readi+0xf4>
{
    80003bc8:	7159                	addi	sp,sp,-112
    80003bca:	f486                	sd	ra,104(sp)
    80003bcc:	f0a2                	sd	s0,96(sp)
    80003bce:	eca6                	sd	s1,88(sp)
    80003bd0:	e8ca                	sd	s2,80(sp)
    80003bd2:	e4ce                	sd	s3,72(sp)
    80003bd4:	e0d2                	sd	s4,64(sp)
    80003bd6:	fc56                	sd	s5,56(sp)
    80003bd8:	f85a                	sd	s6,48(sp)
    80003bda:	f45e                	sd	s7,40(sp)
    80003bdc:	f062                	sd	s8,32(sp)
    80003bde:	ec66                	sd	s9,24(sp)
    80003be0:	e86a                	sd	s10,16(sp)
    80003be2:	e46e                	sd	s11,8(sp)
    80003be4:	1880                	addi	s0,sp,112
    80003be6:	8b2a                	mv	s6,a0
    80003be8:	8bae                	mv	s7,a1
    80003bea:	8a32                	mv	s4,a2
    80003bec:	84b6                	mv	s1,a3
    80003bee:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bf0:	9f35                	addw	a4,a4,a3
    return 0;
    80003bf2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bf4:	0ad76063          	bltu	a4,a3,80003c94 <readi+0xd2>
  if(off + n > ip->size)
    80003bf8:	00e7f463          	bgeu	a5,a4,80003c00 <readi+0x3e>
    n = ip->size - off;
    80003bfc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c00:	0a0a8963          	beqz	s5,80003cb2 <readi+0xf0>
    80003c04:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c06:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c0a:	5c7d                	li	s8,-1
    80003c0c:	a82d                	j	80003c46 <readi+0x84>
    80003c0e:	020d1d93          	slli	s11,s10,0x20
    80003c12:	020ddd93          	srli	s11,s11,0x20
    80003c16:	05890793          	addi	a5,s2,88
    80003c1a:	86ee                	mv	a3,s11
    80003c1c:	963e                	add	a2,a2,a5
    80003c1e:	85d2                	mv	a1,s4
    80003c20:	855e                	mv	a0,s7
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	8b2080e7          	jalr	-1870(ra) # 800024d4 <either_copyout>
    80003c2a:	05850d63          	beq	a0,s8,80003c84 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c2e:	854a                	mv	a0,s2
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	5f4080e7          	jalr	1524(ra) # 80003224 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c38:	013d09bb          	addw	s3,s10,s3
    80003c3c:	009d04bb          	addw	s1,s10,s1
    80003c40:	9a6e                	add	s4,s4,s11
    80003c42:	0559f763          	bgeu	s3,s5,80003c90 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c46:	00a4d59b          	srliw	a1,s1,0xa
    80003c4a:	855a                	mv	a0,s6
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	8a2080e7          	jalr	-1886(ra) # 800034ee <bmap>
    80003c54:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c58:	cd85                	beqz	a1,80003c90 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c5a:	000b2503          	lw	a0,0(s6)
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	496080e7          	jalr	1174(ra) # 800030f4 <bread>
    80003c66:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c68:	3ff4f613          	andi	a2,s1,1023
    80003c6c:	40cc87bb          	subw	a5,s9,a2
    80003c70:	413a873b          	subw	a4,s5,s3
    80003c74:	8d3e                	mv	s10,a5
    80003c76:	2781                	sext.w	a5,a5
    80003c78:	0007069b          	sext.w	a3,a4
    80003c7c:	f8f6f9e3          	bgeu	a3,a5,80003c0e <readi+0x4c>
    80003c80:	8d3a                	mv	s10,a4
    80003c82:	b771                	j	80003c0e <readi+0x4c>
      brelse(bp);
    80003c84:	854a                	mv	a0,s2
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	59e080e7          	jalr	1438(ra) # 80003224 <brelse>
      tot = -1;
    80003c8e:	59fd                	li	s3,-1
  }
  return tot;
    80003c90:	0009851b          	sext.w	a0,s3
}
    80003c94:	70a6                	ld	ra,104(sp)
    80003c96:	7406                	ld	s0,96(sp)
    80003c98:	64e6                	ld	s1,88(sp)
    80003c9a:	6946                	ld	s2,80(sp)
    80003c9c:	69a6                	ld	s3,72(sp)
    80003c9e:	6a06                	ld	s4,64(sp)
    80003ca0:	7ae2                	ld	s5,56(sp)
    80003ca2:	7b42                	ld	s6,48(sp)
    80003ca4:	7ba2                	ld	s7,40(sp)
    80003ca6:	7c02                	ld	s8,32(sp)
    80003ca8:	6ce2                	ld	s9,24(sp)
    80003caa:	6d42                	ld	s10,16(sp)
    80003cac:	6da2                	ld	s11,8(sp)
    80003cae:	6165                	addi	sp,sp,112
    80003cb0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb2:	89d6                	mv	s3,s5
    80003cb4:	bff1                	j	80003c90 <readi+0xce>
    return 0;
    80003cb6:	4501                	li	a0,0
}
    80003cb8:	8082                	ret

0000000080003cba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	10d7e863          	bltu	a5,a3,80003dcc <writei+0x112>
{
    80003cc0:	7159                	addi	sp,sp,-112
    80003cc2:	f486                	sd	ra,104(sp)
    80003cc4:	f0a2                	sd	s0,96(sp)
    80003cc6:	eca6                	sd	s1,88(sp)
    80003cc8:	e8ca                	sd	s2,80(sp)
    80003cca:	e4ce                	sd	s3,72(sp)
    80003ccc:	e0d2                	sd	s4,64(sp)
    80003cce:	fc56                	sd	s5,56(sp)
    80003cd0:	f85a                	sd	s6,48(sp)
    80003cd2:	f45e                	sd	s7,40(sp)
    80003cd4:	f062                	sd	s8,32(sp)
    80003cd6:	ec66                	sd	s9,24(sp)
    80003cd8:	e86a                	sd	s10,16(sp)
    80003cda:	e46e                	sd	s11,8(sp)
    80003cdc:	1880                	addi	s0,sp,112
    80003cde:	8aaa                	mv	s5,a0
    80003ce0:	8bae                	mv	s7,a1
    80003ce2:	8a32                	mv	s4,a2
    80003ce4:	8936                	mv	s2,a3
    80003ce6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ce8:	00e687bb          	addw	a5,a3,a4
    80003cec:	0ed7e263          	bltu	a5,a3,80003dd0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cf0:	00043737          	lui	a4,0x43
    80003cf4:	0ef76063          	bltu	a4,a5,80003dd4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf8:	0c0b0863          	beqz	s6,80003dc8 <writei+0x10e>
    80003cfc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cfe:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d02:	5c7d                	li	s8,-1
    80003d04:	a091                	j	80003d48 <writei+0x8e>
    80003d06:	020d1d93          	slli	s11,s10,0x20
    80003d0a:	020ddd93          	srli	s11,s11,0x20
    80003d0e:	05848793          	addi	a5,s1,88
    80003d12:	86ee                	mv	a3,s11
    80003d14:	8652                	mv	a2,s4
    80003d16:	85de                	mv	a1,s7
    80003d18:	953e                	add	a0,a0,a5
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	810080e7          	jalr	-2032(ra) # 8000252a <either_copyin>
    80003d22:	07850263          	beq	a0,s8,80003d86 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d26:	8526                	mv	a0,s1
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	780080e7          	jalr	1920(ra) # 800044a8 <log_write>
    brelse(bp);
    80003d30:	8526                	mv	a0,s1
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	4f2080e7          	jalr	1266(ra) # 80003224 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3a:	013d09bb          	addw	s3,s10,s3
    80003d3e:	012d093b          	addw	s2,s10,s2
    80003d42:	9a6e                	add	s4,s4,s11
    80003d44:	0569f663          	bgeu	s3,s6,80003d90 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d48:	00a9559b          	srliw	a1,s2,0xa
    80003d4c:	8556                	mv	a0,s5
    80003d4e:	fffff097          	auipc	ra,0xfffff
    80003d52:	7a0080e7          	jalr	1952(ra) # 800034ee <bmap>
    80003d56:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d5a:	c99d                	beqz	a1,80003d90 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d5c:	000aa503          	lw	a0,0(s5)
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	394080e7          	jalr	916(ra) # 800030f4 <bread>
    80003d68:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6a:	3ff97513          	andi	a0,s2,1023
    80003d6e:	40ac87bb          	subw	a5,s9,a0
    80003d72:	413b073b          	subw	a4,s6,s3
    80003d76:	8d3e                	mv	s10,a5
    80003d78:	2781                	sext.w	a5,a5
    80003d7a:	0007069b          	sext.w	a3,a4
    80003d7e:	f8f6f4e3          	bgeu	a3,a5,80003d06 <writei+0x4c>
    80003d82:	8d3a                	mv	s10,a4
    80003d84:	b749                	j	80003d06 <writei+0x4c>
      brelse(bp);
    80003d86:	8526                	mv	a0,s1
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	49c080e7          	jalr	1180(ra) # 80003224 <brelse>
  }

  if(off > ip->size)
    80003d90:	04caa783          	lw	a5,76(s5)
    80003d94:	0127f463          	bgeu	a5,s2,80003d9c <writei+0xe2>
    ip->size = off;
    80003d98:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d9c:	8556                	mv	a0,s5
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	aa6080e7          	jalr	-1370(ra) # 80003844 <iupdate>

  return tot;
    80003da6:	0009851b          	sext.w	a0,s3
}
    80003daa:	70a6                	ld	ra,104(sp)
    80003dac:	7406                	ld	s0,96(sp)
    80003dae:	64e6                	ld	s1,88(sp)
    80003db0:	6946                	ld	s2,80(sp)
    80003db2:	69a6                	ld	s3,72(sp)
    80003db4:	6a06                	ld	s4,64(sp)
    80003db6:	7ae2                	ld	s5,56(sp)
    80003db8:	7b42                	ld	s6,48(sp)
    80003dba:	7ba2                	ld	s7,40(sp)
    80003dbc:	7c02                	ld	s8,32(sp)
    80003dbe:	6ce2                	ld	s9,24(sp)
    80003dc0:	6d42                	ld	s10,16(sp)
    80003dc2:	6da2                	ld	s11,8(sp)
    80003dc4:	6165                	addi	sp,sp,112
    80003dc6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dc8:	89da                	mv	s3,s6
    80003dca:	bfc9                	j	80003d9c <writei+0xe2>
    return -1;
    80003dcc:	557d                	li	a0,-1
}
    80003dce:	8082                	ret
    return -1;
    80003dd0:	557d                	li	a0,-1
    80003dd2:	bfe1                	j	80003daa <writei+0xf0>
    return -1;
    80003dd4:	557d                	li	a0,-1
    80003dd6:	bfd1                	j	80003daa <writei+0xf0>

0000000080003dd8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dd8:	1141                	addi	sp,sp,-16
    80003dda:	e406                	sd	ra,8(sp)
    80003ddc:	e022                	sd	s0,0(sp)
    80003dde:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003de0:	4639                	li	a2,14
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	fc0080e7          	jalr	-64(ra) # 80000da2 <strncmp>
}
    80003dea:	60a2                	ld	ra,8(sp)
    80003dec:	6402                	ld	s0,0(sp)
    80003dee:	0141                	addi	sp,sp,16
    80003df0:	8082                	ret

0000000080003df2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003df2:	7139                	addi	sp,sp,-64
    80003df4:	fc06                	sd	ra,56(sp)
    80003df6:	f822                	sd	s0,48(sp)
    80003df8:	f426                	sd	s1,40(sp)
    80003dfa:	f04a                	sd	s2,32(sp)
    80003dfc:	ec4e                	sd	s3,24(sp)
    80003dfe:	e852                	sd	s4,16(sp)
    80003e00:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e02:	04451703          	lh	a4,68(a0)
    80003e06:	4785                	li	a5,1
    80003e08:	00f71a63          	bne	a4,a5,80003e1c <dirlookup+0x2a>
    80003e0c:	892a                	mv	s2,a0
    80003e0e:	89ae                	mv	s3,a1
    80003e10:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e12:	457c                	lw	a5,76(a0)
    80003e14:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e16:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e18:	e79d                	bnez	a5,80003e46 <dirlookup+0x54>
    80003e1a:	a8a5                	j	80003e92 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e1c:	00004517          	auipc	a0,0x4
    80003e20:	7f450513          	addi	a0,a0,2036 # 80008610 <syscalls+0x1c0>
    80003e24:	ffffc097          	auipc	ra,0xffffc
    80003e28:	71a080e7          	jalr	1818(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e2c:	00004517          	auipc	a0,0x4
    80003e30:	7fc50513          	addi	a0,a0,2044 # 80008628 <syscalls+0x1d8>
    80003e34:	ffffc097          	auipc	ra,0xffffc
    80003e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3c:	24c1                	addiw	s1,s1,16
    80003e3e:	04c92783          	lw	a5,76(s2)
    80003e42:	04f4f763          	bgeu	s1,a5,80003e90 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e46:	4741                	li	a4,16
    80003e48:	86a6                	mv	a3,s1
    80003e4a:	fc040613          	addi	a2,s0,-64
    80003e4e:	4581                	li	a1,0
    80003e50:	854a                	mv	a0,s2
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	d70080e7          	jalr	-656(ra) # 80003bc2 <readi>
    80003e5a:	47c1                	li	a5,16
    80003e5c:	fcf518e3          	bne	a0,a5,80003e2c <dirlookup+0x3a>
    if(de.inum == 0)
    80003e60:	fc045783          	lhu	a5,-64(s0)
    80003e64:	dfe1                	beqz	a5,80003e3c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e66:	fc240593          	addi	a1,s0,-62
    80003e6a:	854e                	mv	a0,s3
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	f6c080e7          	jalr	-148(ra) # 80003dd8 <namecmp>
    80003e74:	f561                	bnez	a0,80003e3c <dirlookup+0x4a>
      if(poff)
    80003e76:	000a0463          	beqz	s4,80003e7e <dirlookup+0x8c>
        *poff = off;
    80003e7a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e7e:	fc045583          	lhu	a1,-64(s0)
    80003e82:	00092503          	lw	a0,0(s2)
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	750080e7          	jalr	1872(ra) # 800035d6 <iget>
    80003e8e:	a011                	j	80003e92 <dirlookup+0xa0>
  return 0;
    80003e90:	4501                	li	a0,0
}
    80003e92:	70e2                	ld	ra,56(sp)
    80003e94:	7442                	ld	s0,48(sp)
    80003e96:	74a2                	ld	s1,40(sp)
    80003e98:	7902                	ld	s2,32(sp)
    80003e9a:	69e2                	ld	s3,24(sp)
    80003e9c:	6a42                	ld	s4,16(sp)
    80003e9e:	6121                	addi	sp,sp,64
    80003ea0:	8082                	ret

0000000080003ea2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ea2:	711d                	addi	sp,sp,-96
    80003ea4:	ec86                	sd	ra,88(sp)
    80003ea6:	e8a2                	sd	s0,80(sp)
    80003ea8:	e4a6                	sd	s1,72(sp)
    80003eaa:	e0ca                	sd	s2,64(sp)
    80003eac:	fc4e                	sd	s3,56(sp)
    80003eae:	f852                	sd	s4,48(sp)
    80003eb0:	f456                	sd	s5,40(sp)
    80003eb2:	f05a                	sd	s6,32(sp)
    80003eb4:	ec5e                	sd	s7,24(sp)
    80003eb6:	e862                	sd	s8,16(sp)
    80003eb8:	e466                	sd	s9,8(sp)
    80003eba:	1080                	addi	s0,sp,96
    80003ebc:	84aa                	mv	s1,a0
    80003ebe:	8aae                	mv	s5,a1
    80003ec0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ec2:	00054703          	lbu	a4,0(a0)
    80003ec6:	02f00793          	li	a5,47
    80003eca:	02f70363          	beq	a4,a5,80003ef0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ece:	ffffe097          	auipc	ra,0xffffe
    80003ed2:	ade080e7          	jalr	-1314(ra) # 800019ac <myproc>
    80003ed6:	15053503          	ld	a0,336(a0)
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	9f6080e7          	jalr	-1546(ra) # 800038d0 <idup>
    80003ee2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ee4:	02f00913          	li	s2,47
  len = path - s;
    80003ee8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eea:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eec:	4b85                	li	s7,1
    80003eee:	a865                	j	80003fa6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ef0:	4585                	li	a1,1
    80003ef2:	4505                	li	a0,1
    80003ef4:	fffff097          	auipc	ra,0xfffff
    80003ef8:	6e2080e7          	jalr	1762(ra) # 800035d6 <iget>
    80003efc:	89aa                	mv	s3,a0
    80003efe:	b7dd                	j	80003ee4 <namex+0x42>
      iunlockput(ip);
    80003f00:	854e                	mv	a0,s3
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	c6e080e7          	jalr	-914(ra) # 80003b70 <iunlockput>
      return 0;
    80003f0a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f0c:	854e                	mv	a0,s3
    80003f0e:	60e6                	ld	ra,88(sp)
    80003f10:	6446                	ld	s0,80(sp)
    80003f12:	64a6                	ld	s1,72(sp)
    80003f14:	6906                	ld	s2,64(sp)
    80003f16:	79e2                	ld	s3,56(sp)
    80003f18:	7a42                	ld	s4,48(sp)
    80003f1a:	7aa2                	ld	s5,40(sp)
    80003f1c:	7b02                	ld	s6,32(sp)
    80003f1e:	6be2                	ld	s7,24(sp)
    80003f20:	6c42                	ld	s8,16(sp)
    80003f22:	6ca2                	ld	s9,8(sp)
    80003f24:	6125                	addi	sp,sp,96
    80003f26:	8082                	ret
      iunlock(ip);
    80003f28:	854e                	mv	a0,s3
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	aa6080e7          	jalr	-1370(ra) # 800039d0 <iunlock>
      return ip;
    80003f32:	bfe9                	j	80003f0c <namex+0x6a>
      iunlockput(ip);
    80003f34:	854e                	mv	a0,s3
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	c3a080e7          	jalr	-966(ra) # 80003b70 <iunlockput>
      return 0;
    80003f3e:	89e6                	mv	s3,s9
    80003f40:	b7f1                	j	80003f0c <namex+0x6a>
  len = path - s;
    80003f42:	40b48633          	sub	a2,s1,a1
    80003f46:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f4a:	099c5463          	bge	s8,s9,80003fd2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f4e:	4639                	li	a2,14
    80003f50:	8552                	mv	a0,s4
    80003f52:	ffffd097          	auipc	ra,0xffffd
    80003f56:	ddc080e7          	jalr	-548(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	01279763          	bne	a5,s2,80003f6c <namex+0xca>
    path++;
    80003f62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f64:	0004c783          	lbu	a5,0(s1)
    80003f68:	ff278de3          	beq	a5,s2,80003f62 <namex+0xc0>
    ilock(ip);
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	9a0080e7          	jalr	-1632(ra) # 8000390e <ilock>
    if(ip->type != T_DIR){
    80003f76:	04499783          	lh	a5,68(s3)
    80003f7a:	f97793e3          	bne	a5,s7,80003f00 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f7e:	000a8563          	beqz	s5,80003f88 <namex+0xe6>
    80003f82:	0004c783          	lbu	a5,0(s1)
    80003f86:	d3cd                	beqz	a5,80003f28 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f88:	865a                	mv	a2,s6
    80003f8a:	85d2                	mv	a1,s4
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	e64080e7          	jalr	-412(ra) # 80003df2 <dirlookup>
    80003f96:	8caa                	mv	s9,a0
    80003f98:	dd51                	beqz	a0,80003f34 <namex+0x92>
    iunlockput(ip);
    80003f9a:	854e                	mv	a0,s3
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	bd4080e7          	jalr	-1068(ra) # 80003b70 <iunlockput>
    ip = next;
    80003fa4:	89e6                	mv	s3,s9
  while(*path == '/')
    80003fa6:	0004c783          	lbu	a5,0(s1)
    80003faa:	05279763          	bne	a5,s2,80003ff8 <namex+0x156>
    path++;
    80003fae:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fb0:	0004c783          	lbu	a5,0(s1)
    80003fb4:	ff278de3          	beq	a5,s2,80003fae <namex+0x10c>
  if(*path == 0)
    80003fb8:	c79d                	beqz	a5,80003fe6 <namex+0x144>
    path++;
    80003fba:	85a6                	mv	a1,s1
  len = path - s;
    80003fbc:	8cda                	mv	s9,s6
    80003fbe:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fc0:	01278963          	beq	a5,s2,80003fd2 <namex+0x130>
    80003fc4:	dfbd                	beqz	a5,80003f42 <namex+0xa0>
    path++;
    80003fc6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	ff279ce3          	bne	a5,s2,80003fc4 <namex+0x122>
    80003fd0:	bf8d                	j	80003f42 <namex+0xa0>
    memmove(name, s, len);
    80003fd2:	2601                	sext.w	a2,a2
    80003fd4:	8552                	mv	a0,s4
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	d58080e7          	jalr	-680(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003fde:	9cd2                	add	s9,s9,s4
    80003fe0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fe4:	bf9d                	j	80003f5a <namex+0xb8>
  if(nameiparent){
    80003fe6:	f20a83e3          	beqz	s5,80003f0c <namex+0x6a>
    iput(ip);
    80003fea:	854e                	mv	a0,s3
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	adc080e7          	jalr	-1316(ra) # 80003ac8 <iput>
    return 0;
    80003ff4:	4981                	li	s3,0
    80003ff6:	bf19                	j	80003f0c <namex+0x6a>
  if(*path == 0)
    80003ff8:	d7fd                	beqz	a5,80003fe6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ffa:	0004c783          	lbu	a5,0(s1)
    80003ffe:	85a6                	mv	a1,s1
    80004000:	b7d1                	j	80003fc4 <namex+0x122>

0000000080004002 <dirlink>:
{
    80004002:	7139                	addi	sp,sp,-64
    80004004:	fc06                	sd	ra,56(sp)
    80004006:	f822                	sd	s0,48(sp)
    80004008:	f426                	sd	s1,40(sp)
    8000400a:	f04a                	sd	s2,32(sp)
    8000400c:	ec4e                	sd	s3,24(sp)
    8000400e:	e852                	sd	s4,16(sp)
    80004010:	0080                	addi	s0,sp,64
    80004012:	892a                	mv	s2,a0
    80004014:	8a2e                	mv	s4,a1
    80004016:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004018:	4601                	li	a2,0
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	dd8080e7          	jalr	-552(ra) # 80003df2 <dirlookup>
    80004022:	e93d                	bnez	a0,80004098 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004024:	04c92483          	lw	s1,76(s2)
    80004028:	c49d                	beqz	s1,80004056 <dirlink+0x54>
    8000402a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402c:	4741                	li	a4,16
    8000402e:	86a6                	mv	a3,s1
    80004030:	fc040613          	addi	a2,s0,-64
    80004034:	4581                	li	a1,0
    80004036:	854a                	mv	a0,s2
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	b8a080e7          	jalr	-1142(ra) # 80003bc2 <readi>
    80004040:	47c1                	li	a5,16
    80004042:	06f51163          	bne	a0,a5,800040a4 <dirlink+0xa2>
    if(de.inum == 0)
    80004046:	fc045783          	lhu	a5,-64(s0)
    8000404a:	c791                	beqz	a5,80004056 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404c:	24c1                	addiw	s1,s1,16
    8000404e:	04c92783          	lw	a5,76(s2)
    80004052:	fcf4ede3          	bltu	s1,a5,8000402c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004056:	4639                	li	a2,14
    80004058:	85d2                	mv	a1,s4
    8000405a:	fc240513          	addi	a0,s0,-62
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	d80080e7          	jalr	-640(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004066:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406a:	4741                	li	a4,16
    8000406c:	86a6                	mv	a3,s1
    8000406e:	fc040613          	addi	a2,s0,-64
    80004072:	4581                	li	a1,0
    80004074:	854a                	mv	a0,s2
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	c44080e7          	jalr	-956(ra) # 80003cba <writei>
    8000407e:	1541                	addi	a0,a0,-16
    80004080:	00a03533          	snez	a0,a0
    80004084:	40a00533          	neg	a0,a0
}
    80004088:	70e2                	ld	ra,56(sp)
    8000408a:	7442                	ld	s0,48(sp)
    8000408c:	74a2                	ld	s1,40(sp)
    8000408e:	7902                	ld	s2,32(sp)
    80004090:	69e2                	ld	s3,24(sp)
    80004092:	6a42                	ld	s4,16(sp)
    80004094:	6121                	addi	sp,sp,64
    80004096:	8082                	ret
    iput(ip);
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	a30080e7          	jalr	-1488(ra) # 80003ac8 <iput>
    return -1;
    800040a0:	557d                	li	a0,-1
    800040a2:	b7dd                	j	80004088 <dirlink+0x86>
      panic("dirlink read");
    800040a4:	00004517          	auipc	a0,0x4
    800040a8:	59450513          	addi	a0,a0,1428 # 80008638 <syscalls+0x1e8>
    800040ac:	ffffc097          	auipc	ra,0xffffc
    800040b0:	492080e7          	jalr	1170(ra) # 8000053e <panic>

00000000800040b4 <namei>:

struct inode*
namei(char *path)
{
    800040b4:	1101                	addi	sp,sp,-32
    800040b6:	ec06                	sd	ra,24(sp)
    800040b8:	e822                	sd	s0,16(sp)
    800040ba:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040bc:	fe040613          	addi	a2,s0,-32
    800040c0:	4581                	li	a1,0
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	de0080e7          	jalr	-544(ra) # 80003ea2 <namex>
}
    800040ca:	60e2                	ld	ra,24(sp)
    800040cc:	6442                	ld	s0,16(sp)
    800040ce:	6105                	addi	sp,sp,32
    800040d0:	8082                	ret

00000000800040d2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040d2:	1141                	addi	sp,sp,-16
    800040d4:	e406                	sd	ra,8(sp)
    800040d6:	e022                	sd	s0,0(sp)
    800040d8:	0800                	addi	s0,sp,16
    800040da:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040dc:	4585                	li	a1,1
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	dc4080e7          	jalr	-572(ra) # 80003ea2 <namex>
}
    800040e6:	60a2                	ld	ra,8(sp)
    800040e8:	6402                	ld	s0,0(sp)
    800040ea:	0141                	addi	sp,sp,16
    800040ec:	8082                	ret

00000000800040ee <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ee:	1101                	addi	sp,sp,-32
    800040f0:	ec06                	sd	ra,24(sp)
    800040f2:	e822                	sd	s0,16(sp)
    800040f4:	e426                	sd	s1,8(sp)
    800040f6:	e04a                	sd	s2,0(sp)
    800040f8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040fa:	0001d917          	auipc	s2,0x1d
    800040fe:	62690913          	addi	s2,s2,1574 # 80021720 <log>
    80004102:	01892583          	lw	a1,24(s2)
    80004106:	02892503          	lw	a0,40(s2)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	fea080e7          	jalr	-22(ra) # 800030f4 <bread>
    80004112:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004114:	02c92683          	lw	a3,44(s2)
    80004118:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000411a:	02d05763          	blez	a3,80004148 <write_head+0x5a>
    8000411e:	0001d797          	auipc	a5,0x1d
    80004122:	63278793          	addi	a5,a5,1586 # 80021750 <log+0x30>
    80004126:	05c50713          	addi	a4,a0,92
    8000412a:	36fd                	addiw	a3,a3,-1
    8000412c:	1682                	slli	a3,a3,0x20
    8000412e:	9281                	srli	a3,a3,0x20
    80004130:	068a                	slli	a3,a3,0x2
    80004132:	0001d617          	auipc	a2,0x1d
    80004136:	62260613          	addi	a2,a2,1570 # 80021754 <log+0x34>
    8000413a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000413c:	4390                	lw	a2,0(a5)
    8000413e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004140:	0791                	addi	a5,a5,4
    80004142:	0711                	addi	a4,a4,4
    80004144:	fed79ce3          	bne	a5,a3,8000413c <write_head+0x4e>
  }
  bwrite(buf);
    80004148:	8526                	mv	a0,s1
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	09c080e7          	jalr	156(ra) # 800031e6 <bwrite>
  brelse(buf);
    80004152:	8526                	mv	a0,s1
    80004154:	fffff097          	auipc	ra,0xfffff
    80004158:	0d0080e7          	jalr	208(ra) # 80003224 <brelse>
}
    8000415c:	60e2                	ld	ra,24(sp)
    8000415e:	6442                	ld	s0,16(sp)
    80004160:	64a2                	ld	s1,8(sp)
    80004162:	6902                	ld	s2,0(sp)
    80004164:	6105                	addi	sp,sp,32
    80004166:	8082                	ret

0000000080004168 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004168:	0001d797          	auipc	a5,0x1d
    8000416c:	5e47a783          	lw	a5,1508(a5) # 8002174c <log+0x2c>
    80004170:	0af05d63          	blez	a5,8000422a <install_trans+0xc2>
{
    80004174:	7139                	addi	sp,sp,-64
    80004176:	fc06                	sd	ra,56(sp)
    80004178:	f822                	sd	s0,48(sp)
    8000417a:	f426                	sd	s1,40(sp)
    8000417c:	f04a                	sd	s2,32(sp)
    8000417e:	ec4e                	sd	s3,24(sp)
    80004180:	e852                	sd	s4,16(sp)
    80004182:	e456                	sd	s5,8(sp)
    80004184:	e05a                	sd	s6,0(sp)
    80004186:	0080                	addi	s0,sp,64
    80004188:	8b2a                	mv	s6,a0
    8000418a:	0001da97          	auipc	s5,0x1d
    8000418e:	5c6a8a93          	addi	s5,s5,1478 # 80021750 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004192:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004194:	0001d997          	auipc	s3,0x1d
    80004198:	58c98993          	addi	s3,s3,1420 # 80021720 <log>
    8000419c:	a00d                	j	800041be <install_trans+0x56>
    brelse(lbuf);
    8000419e:	854a                	mv	a0,s2
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	084080e7          	jalr	132(ra) # 80003224 <brelse>
    brelse(dbuf);
    800041a8:	8526                	mv	a0,s1
    800041aa:	fffff097          	auipc	ra,0xfffff
    800041ae:	07a080e7          	jalr	122(ra) # 80003224 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041b2:	2a05                	addiw	s4,s4,1
    800041b4:	0a91                	addi	s5,s5,4
    800041b6:	02c9a783          	lw	a5,44(s3)
    800041ba:	04fa5e63          	bge	s4,a5,80004216 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041be:	0189a583          	lw	a1,24(s3)
    800041c2:	014585bb          	addw	a1,a1,s4
    800041c6:	2585                	addiw	a1,a1,1
    800041c8:	0289a503          	lw	a0,40(s3)
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	f28080e7          	jalr	-216(ra) # 800030f4 <bread>
    800041d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041d6:	000aa583          	lw	a1,0(s5)
    800041da:	0289a503          	lw	a0,40(s3)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	f16080e7          	jalr	-234(ra) # 800030f4 <bread>
    800041e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041e8:	40000613          	li	a2,1024
    800041ec:	05890593          	addi	a1,s2,88
    800041f0:	05850513          	addi	a0,a0,88
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	b3a080e7          	jalr	-1222(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800041fc:	8526                	mv	a0,s1
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	fe8080e7          	jalr	-24(ra) # 800031e6 <bwrite>
    if(recovering == 0)
    80004206:	f80b1ce3          	bnez	s6,8000419e <install_trans+0x36>
      bunpin(dbuf);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	0f2080e7          	jalr	242(ra) # 800032fe <bunpin>
    80004214:	b769                	j	8000419e <install_trans+0x36>
}
    80004216:	70e2                	ld	ra,56(sp)
    80004218:	7442                	ld	s0,48(sp)
    8000421a:	74a2                	ld	s1,40(sp)
    8000421c:	7902                	ld	s2,32(sp)
    8000421e:	69e2                	ld	s3,24(sp)
    80004220:	6a42                	ld	s4,16(sp)
    80004222:	6aa2                	ld	s5,8(sp)
    80004224:	6b02                	ld	s6,0(sp)
    80004226:	6121                	addi	sp,sp,64
    80004228:	8082                	ret
    8000422a:	8082                	ret

000000008000422c <initlog>:
{
    8000422c:	7179                	addi	sp,sp,-48
    8000422e:	f406                	sd	ra,40(sp)
    80004230:	f022                	sd	s0,32(sp)
    80004232:	ec26                	sd	s1,24(sp)
    80004234:	e84a                	sd	s2,16(sp)
    80004236:	e44e                	sd	s3,8(sp)
    80004238:	1800                	addi	s0,sp,48
    8000423a:	892a                	mv	s2,a0
    8000423c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000423e:	0001d497          	auipc	s1,0x1d
    80004242:	4e248493          	addi	s1,s1,1250 # 80021720 <log>
    80004246:	00004597          	auipc	a1,0x4
    8000424a:	40258593          	addi	a1,a1,1026 # 80008648 <syscalls+0x1f8>
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	8f6080e7          	jalr	-1802(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004258:	0149a583          	lw	a1,20(s3)
    8000425c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000425e:	0109a783          	lw	a5,16(s3)
    80004262:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004264:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004268:	854a                	mv	a0,s2
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	e8a080e7          	jalr	-374(ra) # 800030f4 <bread>
  log.lh.n = lh->n;
    80004272:	4d34                	lw	a3,88(a0)
    80004274:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004276:	02d05563          	blez	a3,800042a0 <initlog+0x74>
    8000427a:	05c50793          	addi	a5,a0,92
    8000427e:	0001d717          	auipc	a4,0x1d
    80004282:	4d270713          	addi	a4,a4,1234 # 80021750 <log+0x30>
    80004286:	36fd                	addiw	a3,a3,-1
    80004288:	1682                	slli	a3,a3,0x20
    8000428a:	9281                	srli	a3,a3,0x20
    8000428c:	068a                	slli	a3,a3,0x2
    8000428e:	06050613          	addi	a2,a0,96
    80004292:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004294:	4390                	lw	a2,0(a5)
    80004296:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004298:	0791                	addi	a5,a5,4
    8000429a:	0711                	addi	a4,a4,4
    8000429c:	fed79ce3          	bne	a5,a3,80004294 <initlog+0x68>
  brelse(buf);
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	f84080e7          	jalr	-124(ra) # 80003224 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042a8:	4505                	li	a0,1
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	ebe080e7          	jalr	-322(ra) # 80004168 <install_trans>
  log.lh.n = 0;
    800042b2:	0001d797          	auipc	a5,0x1d
    800042b6:	4807ad23          	sw	zero,1178(a5) # 8002174c <log+0x2c>
  write_head(); // clear the log
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	e34080e7          	jalr	-460(ra) # 800040ee <write_head>
}
    800042c2:	70a2                	ld	ra,40(sp)
    800042c4:	7402                	ld	s0,32(sp)
    800042c6:	64e2                	ld	s1,24(sp)
    800042c8:	6942                	ld	s2,16(sp)
    800042ca:	69a2                	ld	s3,8(sp)
    800042cc:	6145                	addi	sp,sp,48
    800042ce:	8082                	ret

00000000800042d0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042d0:	1101                	addi	sp,sp,-32
    800042d2:	ec06                	sd	ra,24(sp)
    800042d4:	e822                	sd	s0,16(sp)
    800042d6:	e426                	sd	s1,8(sp)
    800042d8:	e04a                	sd	s2,0(sp)
    800042da:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042dc:	0001d517          	auipc	a0,0x1d
    800042e0:	44450513          	addi	a0,a0,1092 # 80021720 <log>
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800042ec:	0001d497          	auipc	s1,0x1d
    800042f0:	43448493          	addi	s1,s1,1076 # 80021720 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f4:	4979                	li	s2,30
    800042f6:	a039                	j	80004304 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042f8:	85a6                	mv	a1,s1
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffe097          	auipc	ra,0xffffe
    80004300:	dc4080e7          	jalr	-572(ra) # 800020c0 <sleep>
    if(log.committing){
    80004304:	50dc                	lw	a5,36(s1)
    80004306:	fbed                	bnez	a5,800042f8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004308:	509c                	lw	a5,32(s1)
    8000430a:	0017871b          	addiw	a4,a5,1
    8000430e:	0007069b          	sext.w	a3,a4
    80004312:	0027179b          	slliw	a5,a4,0x2
    80004316:	9fb9                	addw	a5,a5,a4
    80004318:	0017979b          	slliw	a5,a5,0x1
    8000431c:	54d8                	lw	a4,44(s1)
    8000431e:	9fb9                	addw	a5,a5,a4
    80004320:	00f95963          	bge	s2,a5,80004332 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004324:	85a6                	mv	a1,s1
    80004326:	8526                	mv	a0,s1
    80004328:	ffffe097          	auipc	ra,0xffffe
    8000432c:	d98080e7          	jalr	-616(ra) # 800020c0 <sleep>
    80004330:	bfd1                	j	80004304 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004332:	0001d517          	auipc	a0,0x1d
    80004336:	3ee50513          	addi	a0,a0,1006 # 80021720 <log>
    8000433a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	94e080e7          	jalr	-1714(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004344:	60e2                	ld	ra,24(sp)
    80004346:	6442                	ld	s0,16(sp)
    80004348:	64a2                	ld	s1,8(sp)
    8000434a:	6902                	ld	s2,0(sp)
    8000434c:	6105                	addi	sp,sp,32
    8000434e:	8082                	ret

0000000080004350 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004350:	7139                	addi	sp,sp,-64
    80004352:	fc06                	sd	ra,56(sp)
    80004354:	f822                	sd	s0,48(sp)
    80004356:	f426                	sd	s1,40(sp)
    80004358:	f04a                	sd	s2,32(sp)
    8000435a:	ec4e                	sd	s3,24(sp)
    8000435c:	e852                	sd	s4,16(sp)
    8000435e:	e456                	sd	s5,8(sp)
    80004360:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004362:	0001d497          	auipc	s1,0x1d
    80004366:	3be48493          	addi	s1,s1,958 # 80021720 <log>
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	86a080e7          	jalr	-1942(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004374:	509c                	lw	a5,32(s1)
    80004376:	37fd                	addiw	a5,a5,-1
    80004378:	0007891b          	sext.w	s2,a5
    8000437c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000437e:	50dc                	lw	a5,36(s1)
    80004380:	e7b9                	bnez	a5,800043ce <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004382:	04091e63          	bnez	s2,800043de <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004386:	0001d497          	auipc	s1,0x1d
    8000438a:	39a48493          	addi	s1,s1,922 # 80021720 <log>
    8000438e:	4785                	li	a5,1
    80004390:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004392:	8526                	mv	a0,s1
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	8f6080e7          	jalr	-1802(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000439c:	54dc                	lw	a5,44(s1)
    8000439e:	06f04763          	bgtz	a5,8000440c <end_op+0xbc>
    acquire(&log.lock);
    800043a2:	0001d497          	auipc	s1,0x1d
    800043a6:	37e48493          	addi	s1,s1,894 # 80021720 <log>
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	82a080e7          	jalr	-2006(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800043b4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043b8:	8526                	mv	a0,s1
    800043ba:	ffffe097          	auipc	ra,0xffffe
    800043be:	d6a080e7          	jalr	-662(ra) # 80002124 <wakeup>
    release(&log.lock);
    800043c2:	8526                	mv	a0,s1
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	8c6080e7          	jalr	-1850(ra) # 80000c8a <release>
}
    800043cc:	a03d                	j	800043fa <end_op+0xaa>
    panic("log.committing");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	28250513          	addi	a0,a0,642 # 80008650 <syscalls+0x200>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	168080e7          	jalr	360(ra) # 8000053e <panic>
    wakeup(&log);
    800043de:	0001d497          	auipc	s1,0x1d
    800043e2:	34248493          	addi	s1,s1,834 # 80021720 <log>
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	d3c080e7          	jalr	-708(ra) # 80002124 <wakeup>
  release(&log.lock);
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	898080e7          	jalr	-1896(ra) # 80000c8a <release>
}
    800043fa:	70e2                	ld	ra,56(sp)
    800043fc:	7442                	ld	s0,48(sp)
    800043fe:	74a2                	ld	s1,40(sp)
    80004400:	7902                	ld	s2,32(sp)
    80004402:	69e2                	ld	s3,24(sp)
    80004404:	6a42                	ld	s4,16(sp)
    80004406:	6aa2                	ld	s5,8(sp)
    80004408:	6121                	addi	sp,sp,64
    8000440a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440c:	0001da97          	auipc	s5,0x1d
    80004410:	344a8a93          	addi	s5,s5,836 # 80021750 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004414:	0001da17          	auipc	s4,0x1d
    80004418:	30ca0a13          	addi	s4,s4,780 # 80021720 <log>
    8000441c:	018a2583          	lw	a1,24(s4)
    80004420:	012585bb          	addw	a1,a1,s2
    80004424:	2585                	addiw	a1,a1,1
    80004426:	028a2503          	lw	a0,40(s4)
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	cca080e7          	jalr	-822(ra) # 800030f4 <bread>
    80004432:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004434:	000aa583          	lw	a1,0(s5)
    80004438:	028a2503          	lw	a0,40(s4)
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	cb8080e7          	jalr	-840(ra) # 800030f4 <bread>
    80004444:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004446:	40000613          	li	a2,1024
    8000444a:	05850593          	addi	a1,a0,88
    8000444e:	05848513          	addi	a0,s1,88
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	8dc080e7          	jalr	-1828(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000445a:	8526                	mv	a0,s1
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	d8a080e7          	jalr	-630(ra) # 800031e6 <bwrite>
    brelse(from);
    80004464:	854e                	mv	a0,s3
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	dbe080e7          	jalr	-578(ra) # 80003224 <brelse>
    brelse(to);
    8000446e:	8526                	mv	a0,s1
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	db4080e7          	jalr	-588(ra) # 80003224 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004478:	2905                	addiw	s2,s2,1
    8000447a:	0a91                	addi	s5,s5,4
    8000447c:	02ca2783          	lw	a5,44(s4)
    80004480:	f8f94ee3          	blt	s2,a5,8000441c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004484:	00000097          	auipc	ra,0x0
    80004488:	c6a080e7          	jalr	-918(ra) # 800040ee <write_head>
    install_trans(0); // Now install writes to home locations
    8000448c:	4501                	li	a0,0
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	cda080e7          	jalr	-806(ra) # 80004168 <install_trans>
    log.lh.n = 0;
    80004496:	0001d797          	auipc	a5,0x1d
    8000449a:	2a07ab23          	sw	zero,694(a5) # 8002174c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	c50080e7          	jalr	-944(ra) # 800040ee <write_head>
    800044a6:	bdf5                	j	800043a2 <end_op+0x52>

00000000800044a8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	e426                	sd	s1,8(sp)
    800044b0:	e04a                	sd	s2,0(sp)
    800044b2:	1000                	addi	s0,sp,32
    800044b4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044b6:	0001d917          	auipc	s2,0x1d
    800044ba:	26a90913          	addi	s2,s2,618 # 80021720 <log>
    800044be:	854a                	mv	a0,s2
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	716080e7          	jalr	1814(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044c8:	02c92603          	lw	a2,44(s2)
    800044cc:	47f5                	li	a5,29
    800044ce:	06c7c563          	blt	a5,a2,80004538 <log_write+0x90>
    800044d2:	0001d797          	auipc	a5,0x1d
    800044d6:	26a7a783          	lw	a5,618(a5) # 8002173c <log+0x1c>
    800044da:	37fd                	addiw	a5,a5,-1
    800044dc:	04f65e63          	bge	a2,a5,80004538 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044e0:	0001d797          	auipc	a5,0x1d
    800044e4:	2607a783          	lw	a5,608(a5) # 80021740 <log+0x20>
    800044e8:	06f05063          	blez	a5,80004548 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044ec:	4781                	li	a5,0
    800044ee:	06c05563          	blez	a2,80004558 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044f2:	44cc                	lw	a1,12(s1)
    800044f4:	0001d717          	auipc	a4,0x1d
    800044f8:	25c70713          	addi	a4,a4,604 # 80021750 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044fc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044fe:	4314                	lw	a3,0(a4)
    80004500:	04b68c63          	beq	a3,a1,80004558 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004504:	2785                	addiw	a5,a5,1
    80004506:	0711                	addi	a4,a4,4
    80004508:	fef61be3          	bne	a2,a5,800044fe <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000450c:	0621                	addi	a2,a2,8
    8000450e:	060a                	slli	a2,a2,0x2
    80004510:	0001d797          	auipc	a5,0x1d
    80004514:	21078793          	addi	a5,a5,528 # 80021720 <log>
    80004518:	963e                	add	a2,a2,a5
    8000451a:	44dc                	lw	a5,12(s1)
    8000451c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	da2080e7          	jalr	-606(ra) # 800032c2 <bpin>
    log.lh.n++;
    80004528:	0001d717          	auipc	a4,0x1d
    8000452c:	1f870713          	addi	a4,a4,504 # 80021720 <log>
    80004530:	575c                	lw	a5,44(a4)
    80004532:	2785                	addiw	a5,a5,1
    80004534:	d75c                	sw	a5,44(a4)
    80004536:	a835                	j	80004572 <log_write+0xca>
    panic("too big a transaction");
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	12850513          	addi	a0,a0,296 # 80008660 <syscalls+0x210>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004548:	00004517          	auipc	a0,0x4
    8000454c:	13050513          	addi	a0,a0,304 # 80008678 <syscalls+0x228>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	fee080e7          	jalr	-18(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004558:	00878713          	addi	a4,a5,8
    8000455c:	00271693          	slli	a3,a4,0x2
    80004560:	0001d717          	auipc	a4,0x1d
    80004564:	1c070713          	addi	a4,a4,448 # 80021720 <log>
    80004568:	9736                	add	a4,a4,a3
    8000456a:	44d4                	lw	a3,12(s1)
    8000456c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000456e:	faf608e3          	beq	a2,a5,8000451e <log_write+0x76>
  }
  release(&log.lock);
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	1ae50513          	addi	a0,a0,430 # 80021720 <log>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	710080e7          	jalr	1808(ra) # 80000c8a <release>
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	e04a                	sd	s2,0(sp)
    80004598:	1000                	addi	s0,sp,32
    8000459a:	84aa                	mv	s1,a0
    8000459c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000459e:	00004597          	auipc	a1,0x4
    800045a2:	0fa58593          	addi	a1,a1,250 # 80008698 <syscalls+0x248>
    800045a6:	0521                	addi	a0,a0,8
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	59e080e7          	jalr	1438(ra) # 80000b46 <initlock>
  lk->name = name;
    800045b0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045b4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b8:	0204a423          	sw	zero,40(s1)
}
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6902                	ld	s2,0(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	e04a                	sd	s2,0(sp)
    800045d2:	1000                	addi	s0,sp,32
    800045d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d6:	00850913          	addi	s2,a0,8
    800045da:	854a                	mv	a0,s2
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	5fa080e7          	jalr	1530(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800045e4:	409c                	lw	a5,0(s1)
    800045e6:	cb89                	beqz	a5,800045f8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045e8:	85ca                	mv	a1,s2
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffe097          	auipc	ra,0xffffe
    800045f0:	ad4080e7          	jalr	-1324(ra) # 800020c0 <sleep>
  while (lk->locked) {
    800045f4:	409c                	lw	a5,0(s1)
    800045f6:	fbed                	bnez	a5,800045e8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045f8:	4785                	li	a5,1
    800045fa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045fc:	ffffd097          	auipc	ra,0xffffd
    80004600:	3b0080e7          	jalr	944(ra) # 800019ac <myproc>
    80004604:	591c                	lw	a5,48(a0)
    80004606:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004608:	854a                	mv	a0,s2
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	680080e7          	jalr	1664(ra) # 80000c8a <release>
}
    80004612:	60e2                	ld	ra,24(sp)
    80004614:	6442                	ld	s0,16(sp)
    80004616:	64a2                	ld	s1,8(sp)
    80004618:	6902                	ld	s2,0(sp)
    8000461a:	6105                	addi	sp,sp,32
    8000461c:	8082                	ret

000000008000461e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000461e:	1101                	addi	sp,sp,-32
    80004620:	ec06                	sd	ra,24(sp)
    80004622:	e822                	sd	s0,16(sp)
    80004624:	e426                	sd	s1,8(sp)
    80004626:	e04a                	sd	s2,0(sp)
    80004628:	1000                	addi	s0,sp,32
    8000462a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000462c:	00850913          	addi	s2,a0,8
    80004630:	854a                	mv	a0,s2
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	5a4080e7          	jalr	1444(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000463a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004642:	8526                	mv	a0,s1
    80004644:	ffffe097          	auipc	ra,0xffffe
    80004648:	ae0080e7          	jalr	-1312(ra) # 80002124 <wakeup>
  release(&lk->lk);
    8000464c:	854a                	mv	a0,s2
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	63c080e7          	jalr	1596(ra) # 80000c8a <release>
}
    80004656:	60e2                	ld	ra,24(sp)
    80004658:	6442                	ld	s0,16(sp)
    8000465a:	64a2                	ld	s1,8(sp)
    8000465c:	6902                	ld	s2,0(sp)
    8000465e:	6105                	addi	sp,sp,32
    80004660:	8082                	ret

0000000080004662 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004662:	7179                	addi	sp,sp,-48
    80004664:	f406                	sd	ra,40(sp)
    80004666:	f022                	sd	s0,32(sp)
    80004668:	ec26                	sd	s1,24(sp)
    8000466a:	e84a                	sd	s2,16(sp)
    8000466c:	e44e                	sd	s3,8(sp)
    8000466e:	1800                	addi	s0,sp,48
    80004670:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004672:	00850913          	addi	s2,a0,8
    80004676:	854a                	mv	a0,s2
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	55e080e7          	jalr	1374(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004680:	409c                	lw	a5,0(s1)
    80004682:	ef99                	bnez	a5,800046a0 <holdingsleep+0x3e>
    80004684:	4481                	li	s1,0
  release(&lk->lk);
    80004686:	854a                	mv	a0,s2
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	602080e7          	jalr	1538(ra) # 80000c8a <release>
  return r;
}
    80004690:	8526                	mv	a0,s1
    80004692:	70a2                	ld	ra,40(sp)
    80004694:	7402                	ld	s0,32(sp)
    80004696:	64e2                	ld	s1,24(sp)
    80004698:	6942                	ld	s2,16(sp)
    8000469a:	69a2                	ld	s3,8(sp)
    8000469c:	6145                	addi	sp,sp,48
    8000469e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a0:	0284a983          	lw	s3,40(s1)
    800046a4:	ffffd097          	auipc	ra,0xffffd
    800046a8:	308080e7          	jalr	776(ra) # 800019ac <myproc>
    800046ac:	5904                	lw	s1,48(a0)
    800046ae:	413484b3          	sub	s1,s1,s3
    800046b2:	0014b493          	seqz	s1,s1
    800046b6:	bfc1                	j	80004686 <holdingsleep+0x24>

00000000800046b8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046b8:	1141                	addi	sp,sp,-16
    800046ba:	e406                	sd	ra,8(sp)
    800046bc:	e022                	sd	s0,0(sp)
    800046be:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046c0:	00004597          	auipc	a1,0x4
    800046c4:	fe858593          	addi	a1,a1,-24 # 800086a8 <syscalls+0x258>
    800046c8:	0001d517          	auipc	a0,0x1d
    800046cc:	1a050513          	addi	a0,a0,416 # 80021868 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	476080e7          	jalr	1142(ra) # 80000b46 <initlock>
}
    800046d8:	60a2                	ld	ra,8(sp)
    800046da:	6402                	ld	s0,0(sp)
    800046dc:	0141                	addi	sp,sp,16
    800046de:	8082                	ret

00000000800046e0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046e0:	1101                	addi	sp,sp,-32
    800046e2:	ec06                	sd	ra,24(sp)
    800046e4:	e822                	sd	s0,16(sp)
    800046e6:	e426                	sd	s1,8(sp)
    800046e8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ea:	0001d517          	auipc	a0,0x1d
    800046ee:	17e50513          	addi	a0,a0,382 # 80021868 <ftable>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	4e4080e7          	jalr	1252(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046fa:	0001d497          	auipc	s1,0x1d
    800046fe:	18648493          	addi	s1,s1,390 # 80021880 <ftable+0x18>
    80004702:	0001e717          	auipc	a4,0x1e
    80004706:	11e70713          	addi	a4,a4,286 # 80022820 <disk>
    if(f->ref == 0){
    8000470a:	40dc                	lw	a5,4(s1)
    8000470c:	cf99                	beqz	a5,8000472a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000470e:	02848493          	addi	s1,s1,40
    80004712:	fee49ce3          	bne	s1,a4,8000470a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004716:	0001d517          	auipc	a0,0x1d
    8000471a:	15250513          	addi	a0,a0,338 # 80021868 <ftable>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	56c080e7          	jalr	1388(ra) # 80000c8a <release>
  return 0;
    80004726:	4481                	li	s1,0
    80004728:	a819                	j	8000473e <filealloc+0x5e>
      f->ref = 1;
    8000472a:	4785                	li	a5,1
    8000472c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000472e:	0001d517          	auipc	a0,0x1d
    80004732:	13a50513          	addi	a0,a0,314 # 80021868 <ftable>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	554080e7          	jalr	1364(ra) # 80000c8a <release>
}
    8000473e:	8526                	mv	a0,s1
    80004740:	60e2                	ld	ra,24(sp)
    80004742:	6442                	ld	s0,16(sp)
    80004744:	64a2                	ld	s1,8(sp)
    80004746:	6105                	addi	sp,sp,32
    80004748:	8082                	ret

000000008000474a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000474a:	1101                	addi	sp,sp,-32
    8000474c:	ec06                	sd	ra,24(sp)
    8000474e:	e822                	sd	s0,16(sp)
    80004750:	e426                	sd	s1,8(sp)
    80004752:	1000                	addi	s0,sp,32
    80004754:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	11250513          	addi	a0,a0,274 # 80021868 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	478080e7          	jalr	1144(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004766:	40dc                	lw	a5,4(s1)
    80004768:	02f05263          	blez	a5,8000478c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000476c:	2785                	addiw	a5,a5,1
    8000476e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004770:	0001d517          	auipc	a0,0x1d
    80004774:	0f850513          	addi	a0,a0,248 # 80021868 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	512080e7          	jalr	1298(ra) # 80000c8a <release>
  return f;
}
    80004780:	8526                	mv	a0,s1
    80004782:	60e2                	ld	ra,24(sp)
    80004784:	6442                	ld	s0,16(sp)
    80004786:	64a2                	ld	s1,8(sp)
    80004788:	6105                	addi	sp,sp,32
    8000478a:	8082                	ret
    panic("filedup");
    8000478c:	00004517          	auipc	a0,0x4
    80004790:	f2450513          	addi	a0,a0,-220 # 800086b0 <syscalls+0x260>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	daa080e7          	jalr	-598(ra) # 8000053e <panic>

000000008000479c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000479c:	7139                	addi	sp,sp,-64
    8000479e:	fc06                	sd	ra,56(sp)
    800047a0:	f822                	sd	s0,48(sp)
    800047a2:	f426                	sd	s1,40(sp)
    800047a4:	f04a                	sd	s2,32(sp)
    800047a6:	ec4e                	sd	s3,24(sp)
    800047a8:	e852                	sd	s4,16(sp)
    800047aa:	e456                	sd	s5,8(sp)
    800047ac:	0080                	addi	s0,sp,64
    800047ae:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	0b850513          	addi	a0,a0,184 # 80021868 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	41e080e7          	jalr	1054(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800047c0:	40dc                	lw	a5,4(s1)
    800047c2:	06f05163          	blez	a5,80004824 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047c6:	37fd                	addiw	a5,a5,-1
    800047c8:	0007871b          	sext.w	a4,a5
    800047cc:	c0dc                	sw	a5,4(s1)
    800047ce:	06e04363          	bgtz	a4,80004834 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047d2:	0004a903          	lw	s2,0(s1)
    800047d6:	0094ca83          	lbu	s5,9(s1)
    800047da:	0104ba03          	ld	s4,16(s1)
    800047de:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047e2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047e6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ea:	0001d517          	auipc	a0,0x1d
    800047ee:	07e50513          	addi	a0,a0,126 # 80021868 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	498080e7          	jalr	1176(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800047fa:	4785                	li	a5,1
    800047fc:	04f90d63          	beq	s2,a5,80004856 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004800:	3979                	addiw	s2,s2,-2
    80004802:	4785                	li	a5,1
    80004804:	0527e063          	bltu	a5,s2,80004844 <fileclose+0xa8>
    begin_op();
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	ac8080e7          	jalr	-1336(ra) # 800042d0 <begin_op>
    iput(ff.ip);
    80004810:	854e                	mv	a0,s3
    80004812:	fffff097          	auipc	ra,0xfffff
    80004816:	2b6080e7          	jalr	694(ra) # 80003ac8 <iput>
    end_op();
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	b36080e7          	jalr	-1226(ra) # 80004350 <end_op>
    80004822:	a00d                	j	80004844 <fileclose+0xa8>
    panic("fileclose");
    80004824:	00004517          	auipc	a0,0x4
    80004828:	e9450513          	addi	a0,a0,-364 # 800086b8 <syscalls+0x268>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004834:	0001d517          	auipc	a0,0x1d
    80004838:	03450513          	addi	a0,a0,52 # 80021868 <ftable>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	44e080e7          	jalr	1102(ra) # 80000c8a <release>
  }
}
    80004844:	70e2                	ld	ra,56(sp)
    80004846:	7442                	ld	s0,48(sp)
    80004848:	74a2                	ld	s1,40(sp)
    8000484a:	7902                	ld	s2,32(sp)
    8000484c:	69e2                	ld	s3,24(sp)
    8000484e:	6a42                	ld	s4,16(sp)
    80004850:	6aa2                	ld	s5,8(sp)
    80004852:	6121                	addi	sp,sp,64
    80004854:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004856:	85d6                	mv	a1,s5
    80004858:	8552                	mv	a0,s4
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	34c080e7          	jalr	844(ra) # 80004ba6 <pipeclose>
    80004862:	b7cd                	j	80004844 <fileclose+0xa8>

0000000080004864 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004864:	715d                	addi	sp,sp,-80
    80004866:	e486                	sd	ra,72(sp)
    80004868:	e0a2                	sd	s0,64(sp)
    8000486a:	fc26                	sd	s1,56(sp)
    8000486c:	f84a                	sd	s2,48(sp)
    8000486e:	f44e                	sd	s3,40(sp)
    80004870:	0880                	addi	s0,sp,80
    80004872:	84aa                	mv	s1,a0
    80004874:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004876:	ffffd097          	auipc	ra,0xffffd
    8000487a:	136080e7          	jalr	310(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000487e:	409c                	lw	a5,0(s1)
    80004880:	37f9                	addiw	a5,a5,-2
    80004882:	4705                	li	a4,1
    80004884:	04f76763          	bltu	a4,a5,800048d2 <filestat+0x6e>
    80004888:	892a                	mv	s2,a0
    ilock(f->ip);
    8000488a:	6c88                	ld	a0,24(s1)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	082080e7          	jalr	130(ra) # 8000390e <ilock>
    stati(f->ip, &st);
    80004894:	fb840593          	addi	a1,s0,-72
    80004898:	6c88                	ld	a0,24(s1)
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	2fe080e7          	jalr	766(ra) # 80003b98 <stati>
    iunlock(f->ip);
    800048a2:	6c88                	ld	a0,24(s1)
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	12c080e7          	jalr	300(ra) # 800039d0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048ac:	46e1                	li	a3,24
    800048ae:	fb840613          	addi	a2,s0,-72
    800048b2:	85ce                	mv	a1,s3
    800048b4:	05093503          	ld	a0,80(s2)
    800048b8:	ffffd097          	auipc	ra,0xffffd
    800048bc:	db0080e7          	jalr	-592(ra) # 80001668 <copyout>
    800048c0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048c4:	60a6                	ld	ra,72(sp)
    800048c6:	6406                	ld	s0,64(sp)
    800048c8:	74e2                	ld	s1,56(sp)
    800048ca:	7942                	ld	s2,48(sp)
    800048cc:	79a2                	ld	s3,40(sp)
    800048ce:	6161                	addi	sp,sp,80
    800048d0:	8082                	ret
  return -1;
    800048d2:	557d                	li	a0,-1
    800048d4:	bfc5                	j	800048c4 <filestat+0x60>

00000000800048d6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048d6:	7179                	addi	sp,sp,-48
    800048d8:	f406                	sd	ra,40(sp)
    800048da:	f022                	sd	s0,32(sp)
    800048dc:	ec26                	sd	s1,24(sp)
    800048de:	e84a                	sd	s2,16(sp)
    800048e0:	e44e                	sd	s3,8(sp)
    800048e2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048e4:	00854783          	lbu	a5,8(a0)
    800048e8:	c3d5                	beqz	a5,8000498c <fileread+0xb6>
    800048ea:	84aa                	mv	s1,a0
    800048ec:	89ae                	mv	s3,a1
    800048ee:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f0:	411c                	lw	a5,0(a0)
    800048f2:	4705                	li	a4,1
    800048f4:	04e78963          	beq	a5,a4,80004946 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048f8:	470d                	li	a4,3
    800048fa:	04e78d63          	beq	a5,a4,80004954 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048fe:	4709                	li	a4,2
    80004900:	06e79e63          	bne	a5,a4,8000497c <fileread+0xa6>
    ilock(f->ip);
    80004904:	6d08                	ld	a0,24(a0)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	008080e7          	jalr	8(ra) # 8000390e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000490e:	874a                	mv	a4,s2
    80004910:	5094                	lw	a3,32(s1)
    80004912:	864e                	mv	a2,s3
    80004914:	4585                	li	a1,1
    80004916:	6c88                	ld	a0,24(s1)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	2aa080e7          	jalr	682(ra) # 80003bc2 <readi>
    80004920:	892a                	mv	s2,a0
    80004922:	00a05563          	blez	a0,8000492c <fileread+0x56>
      f->off += r;
    80004926:	509c                	lw	a5,32(s1)
    80004928:	9fa9                	addw	a5,a5,a0
    8000492a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000492c:	6c88                	ld	a0,24(s1)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	0a2080e7          	jalr	162(ra) # 800039d0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004936:	854a                	mv	a0,s2
    80004938:	70a2                	ld	ra,40(sp)
    8000493a:	7402                	ld	s0,32(sp)
    8000493c:	64e2                	ld	s1,24(sp)
    8000493e:	6942                	ld	s2,16(sp)
    80004940:	69a2                	ld	s3,8(sp)
    80004942:	6145                	addi	sp,sp,48
    80004944:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004946:	6908                	ld	a0,16(a0)
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	3c6080e7          	jalr	966(ra) # 80004d0e <piperead>
    80004950:	892a                	mv	s2,a0
    80004952:	b7d5                	j	80004936 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004954:	02451783          	lh	a5,36(a0)
    80004958:	03079693          	slli	a3,a5,0x30
    8000495c:	92c1                	srli	a3,a3,0x30
    8000495e:	4725                	li	a4,9
    80004960:	02d76863          	bltu	a4,a3,80004990 <fileread+0xba>
    80004964:	0792                	slli	a5,a5,0x4
    80004966:	0001d717          	auipc	a4,0x1d
    8000496a:	e6270713          	addi	a4,a4,-414 # 800217c8 <devsw>
    8000496e:	97ba                	add	a5,a5,a4
    80004970:	639c                	ld	a5,0(a5)
    80004972:	c38d                	beqz	a5,80004994 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004974:	4505                	li	a0,1
    80004976:	9782                	jalr	a5
    80004978:	892a                	mv	s2,a0
    8000497a:	bf75                	j	80004936 <fileread+0x60>
    panic("fileread");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	d4c50513          	addi	a0,a0,-692 # 800086c8 <syscalls+0x278>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	bba080e7          	jalr	-1094(ra) # 8000053e <panic>
    return -1;
    8000498c:	597d                	li	s2,-1
    8000498e:	b765                	j	80004936 <fileread+0x60>
      return -1;
    80004990:	597d                	li	s2,-1
    80004992:	b755                	j	80004936 <fileread+0x60>
    80004994:	597d                	li	s2,-1
    80004996:	b745                	j	80004936 <fileread+0x60>

0000000080004998 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004998:	715d                	addi	sp,sp,-80
    8000499a:	e486                	sd	ra,72(sp)
    8000499c:	e0a2                	sd	s0,64(sp)
    8000499e:	fc26                	sd	s1,56(sp)
    800049a0:	f84a                	sd	s2,48(sp)
    800049a2:	f44e                	sd	s3,40(sp)
    800049a4:	f052                	sd	s4,32(sp)
    800049a6:	ec56                	sd	s5,24(sp)
    800049a8:	e85a                	sd	s6,16(sp)
    800049aa:	e45e                	sd	s7,8(sp)
    800049ac:	e062                	sd	s8,0(sp)
    800049ae:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049b0:	00954783          	lbu	a5,9(a0)
    800049b4:	10078663          	beqz	a5,80004ac0 <filewrite+0x128>
    800049b8:	892a                	mv	s2,a0
    800049ba:	8aae                	mv	s5,a1
    800049bc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049be:	411c                	lw	a5,0(a0)
    800049c0:	4705                	li	a4,1
    800049c2:	02e78263          	beq	a5,a4,800049e6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049c6:	470d                	li	a4,3
    800049c8:	02e78663          	beq	a5,a4,800049f4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049cc:	4709                	li	a4,2
    800049ce:	0ee79163          	bne	a5,a4,80004ab0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049d2:	0ac05d63          	blez	a2,80004a8c <filewrite+0xf4>
    int i = 0;
    800049d6:	4981                	li	s3,0
    800049d8:	6b05                	lui	s6,0x1
    800049da:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049de:	6b85                	lui	s7,0x1
    800049e0:	c00b8b9b          	addiw	s7,s7,-1024
    800049e4:	a861                	j	80004a7c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049e6:	6908                	ld	a0,16(a0)
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	22e080e7          	jalr	558(ra) # 80004c16 <pipewrite>
    800049f0:	8a2a                	mv	s4,a0
    800049f2:	a045                	j	80004a92 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049f4:	02451783          	lh	a5,36(a0)
    800049f8:	03079693          	slli	a3,a5,0x30
    800049fc:	92c1                	srli	a3,a3,0x30
    800049fe:	4725                	li	a4,9
    80004a00:	0cd76263          	bltu	a4,a3,80004ac4 <filewrite+0x12c>
    80004a04:	0792                	slli	a5,a5,0x4
    80004a06:	0001d717          	auipc	a4,0x1d
    80004a0a:	dc270713          	addi	a4,a4,-574 # 800217c8 <devsw>
    80004a0e:	97ba                	add	a5,a5,a4
    80004a10:	679c                	ld	a5,8(a5)
    80004a12:	cbdd                	beqz	a5,80004ac8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a14:	4505                	li	a0,1
    80004a16:	9782                	jalr	a5
    80004a18:	8a2a                	mv	s4,a0
    80004a1a:	a8a5                	j	80004a92 <filewrite+0xfa>
    80004a1c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	8b0080e7          	jalr	-1872(ra) # 800042d0 <begin_op>
      ilock(f->ip);
    80004a28:	01893503          	ld	a0,24(s2)
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	ee2080e7          	jalr	-286(ra) # 8000390e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a34:	8762                	mv	a4,s8
    80004a36:	02092683          	lw	a3,32(s2)
    80004a3a:	01598633          	add	a2,s3,s5
    80004a3e:	4585                	li	a1,1
    80004a40:	01893503          	ld	a0,24(s2)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	276080e7          	jalr	630(ra) # 80003cba <writei>
    80004a4c:	84aa                	mv	s1,a0
    80004a4e:	00a05763          	blez	a0,80004a5c <filewrite+0xc4>
        f->off += r;
    80004a52:	02092783          	lw	a5,32(s2)
    80004a56:	9fa9                	addw	a5,a5,a0
    80004a58:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a5c:	01893503          	ld	a0,24(s2)
    80004a60:	fffff097          	auipc	ra,0xfffff
    80004a64:	f70080e7          	jalr	-144(ra) # 800039d0 <iunlock>
      end_op();
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	8e8080e7          	jalr	-1816(ra) # 80004350 <end_op>

      if(r != n1){
    80004a70:	009c1f63          	bne	s8,s1,80004a8e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a74:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a78:	0149db63          	bge	s3,s4,80004a8e <filewrite+0xf6>
      int n1 = n - i;
    80004a7c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a80:	84be                	mv	s1,a5
    80004a82:	2781                	sext.w	a5,a5
    80004a84:	f8fb5ce3          	bge	s6,a5,80004a1c <filewrite+0x84>
    80004a88:	84de                	mv	s1,s7
    80004a8a:	bf49                	j	80004a1c <filewrite+0x84>
    int i = 0;
    80004a8c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a8e:	013a1f63          	bne	s4,s3,80004aac <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a92:	8552                	mv	a0,s4
    80004a94:	60a6                	ld	ra,72(sp)
    80004a96:	6406                	ld	s0,64(sp)
    80004a98:	74e2                	ld	s1,56(sp)
    80004a9a:	7942                	ld	s2,48(sp)
    80004a9c:	79a2                	ld	s3,40(sp)
    80004a9e:	7a02                	ld	s4,32(sp)
    80004aa0:	6ae2                	ld	s5,24(sp)
    80004aa2:	6b42                	ld	s6,16(sp)
    80004aa4:	6ba2                	ld	s7,8(sp)
    80004aa6:	6c02                	ld	s8,0(sp)
    80004aa8:	6161                	addi	sp,sp,80
    80004aaa:	8082                	ret
    ret = (i == n ? n : -1);
    80004aac:	5a7d                	li	s4,-1
    80004aae:	b7d5                	j	80004a92 <filewrite+0xfa>
    panic("filewrite");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	c2850513          	addi	a0,a0,-984 # 800086d8 <syscalls+0x288>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a86080e7          	jalr	-1402(ra) # 8000053e <panic>
    return -1;
    80004ac0:	5a7d                	li	s4,-1
    80004ac2:	bfc1                	j	80004a92 <filewrite+0xfa>
      return -1;
    80004ac4:	5a7d                	li	s4,-1
    80004ac6:	b7f1                	j	80004a92 <filewrite+0xfa>
    80004ac8:	5a7d                	li	s4,-1
    80004aca:	b7e1                	j	80004a92 <filewrite+0xfa>

0000000080004acc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004acc:	7179                	addi	sp,sp,-48
    80004ace:	f406                	sd	ra,40(sp)
    80004ad0:	f022                	sd	s0,32(sp)
    80004ad2:	ec26                	sd	s1,24(sp)
    80004ad4:	e84a                	sd	s2,16(sp)
    80004ad6:	e44e                	sd	s3,8(sp)
    80004ad8:	e052                	sd	s4,0(sp)
    80004ada:	1800                	addi	s0,sp,48
    80004adc:	84aa                	mv	s1,a0
    80004ade:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ae0:	0005b023          	sd	zero,0(a1)
    80004ae4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	bf8080e7          	jalr	-1032(ra) # 800046e0 <filealloc>
    80004af0:	e088                	sd	a0,0(s1)
    80004af2:	c551                	beqz	a0,80004b7e <pipealloc+0xb2>
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	bec080e7          	jalr	-1044(ra) # 800046e0 <filealloc>
    80004afc:	00aa3023          	sd	a0,0(s4)
    80004b00:	c92d                	beqz	a0,80004b72 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	fe4080e7          	jalr	-28(ra) # 80000ae6 <kalloc>
    80004b0a:	892a                	mv	s2,a0
    80004b0c:	c125                	beqz	a0,80004b6c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b0e:	4985                	li	s3,1
    80004b10:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b14:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b18:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b1c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b20:	00004597          	auipc	a1,0x4
    80004b24:	bc858593          	addi	a1,a1,-1080 # 800086e8 <syscalls+0x298>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	01e080e7          	jalr	30(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004b30:	609c                	ld	a5,0(s1)
    80004b32:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b36:	609c                	ld	a5,0(s1)
    80004b38:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b3c:	609c                	ld	a5,0(s1)
    80004b3e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b42:	609c                	ld	a5,0(s1)
    80004b44:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b48:	000a3783          	ld	a5,0(s4)
    80004b4c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b50:	000a3783          	ld	a5,0(s4)
    80004b54:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b58:	000a3783          	ld	a5,0(s4)
    80004b5c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b60:	000a3783          	ld	a5,0(s4)
    80004b64:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b68:	4501                	li	a0,0
    80004b6a:	a025                	j	80004b92 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b6c:	6088                	ld	a0,0(s1)
    80004b6e:	e501                	bnez	a0,80004b76 <pipealloc+0xaa>
    80004b70:	a039                	j	80004b7e <pipealloc+0xb2>
    80004b72:	6088                	ld	a0,0(s1)
    80004b74:	c51d                	beqz	a0,80004ba2 <pipealloc+0xd6>
    fileclose(*f0);
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	c26080e7          	jalr	-986(ra) # 8000479c <fileclose>
  if(*f1)
    80004b7e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b82:	557d                	li	a0,-1
  if(*f1)
    80004b84:	c799                	beqz	a5,80004b92 <pipealloc+0xc6>
    fileclose(*f1);
    80004b86:	853e                	mv	a0,a5
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	c14080e7          	jalr	-1004(ra) # 8000479c <fileclose>
  return -1;
    80004b90:	557d                	li	a0,-1
}
    80004b92:	70a2                	ld	ra,40(sp)
    80004b94:	7402                	ld	s0,32(sp)
    80004b96:	64e2                	ld	s1,24(sp)
    80004b98:	6942                	ld	s2,16(sp)
    80004b9a:	69a2                	ld	s3,8(sp)
    80004b9c:	6a02                	ld	s4,0(sp)
    80004b9e:	6145                	addi	sp,sp,48
    80004ba0:	8082                	ret
  return -1;
    80004ba2:	557d                	li	a0,-1
    80004ba4:	b7fd                	j	80004b92 <pipealloc+0xc6>

0000000080004ba6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ba6:	1101                	addi	sp,sp,-32
    80004ba8:	ec06                	sd	ra,24(sp)
    80004baa:	e822                	sd	s0,16(sp)
    80004bac:	e426                	sd	s1,8(sp)
    80004bae:	e04a                	sd	s2,0(sp)
    80004bb0:	1000                	addi	s0,sp,32
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	020080e7          	jalr	32(ra) # 80000bd6 <acquire>
  if(writable){
    80004bbe:	02090d63          	beqz	s2,80004bf8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bc2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bc6:	21848513          	addi	a0,s1,536
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	55a080e7          	jalr	1370(ra) # 80002124 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bd2:	2204b783          	ld	a5,544(s1)
    80004bd6:	eb95                	bnez	a5,80004c0a <pipeclose+0x64>
    release(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	0b0080e7          	jalr	176(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	e06080e7          	jalr	-506(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004bec:	60e2                	ld	ra,24(sp)
    80004bee:	6442                	ld	s0,16(sp)
    80004bf0:	64a2                	ld	s1,8(sp)
    80004bf2:	6902                	ld	s2,0(sp)
    80004bf4:	6105                	addi	sp,sp,32
    80004bf6:	8082                	ret
    pi->readopen = 0;
    80004bf8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bfc:	21c48513          	addi	a0,s1,540
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	524080e7          	jalr	1316(ra) # 80002124 <wakeup>
    80004c08:	b7e9                	j	80004bd2 <pipeclose+0x2c>
    release(&pi->lock);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	07e080e7          	jalr	126(ra) # 80000c8a <release>
}
    80004c14:	bfe1                	j	80004bec <pipeclose+0x46>

0000000080004c16 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c16:	711d                	addi	sp,sp,-96
    80004c18:	ec86                	sd	ra,88(sp)
    80004c1a:	e8a2                	sd	s0,80(sp)
    80004c1c:	e4a6                	sd	s1,72(sp)
    80004c1e:	e0ca                	sd	s2,64(sp)
    80004c20:	fc4e                	sd	s3,56(sp)
    80004c22:	f852                	sd	s4,48(sp)
    80004c24:	f456                	sd	s5,40(sp)
    80004c26:	f05a                	sd	s6,32(sp)
    80004c28:	ec5e                	sd	s7,24(sp)
    80004c2a:	e862                	sd	s8,16(sp)
    80004c2c:	1080                	addi	s0,sp,96
    80004c2e:	84aa                	mv	s1,a0
    80004c30:	8aae                	mv	s5,a1
    80004c32:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	d78080e7          	jalr	-648(ra) # 800019ac <myproc>
    80004c3c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	f96080e7          	jalr	-106(ra) # 80000bd6 <acquire>
  while(i < n){
    80004c48:	0b405663          	blez	s4,80004cf4 <pipewrite+0xde>
  int i = 0;
    80004c4c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c4e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c50:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c54:	21c48b93          	addi	s7,s1,540
    80004c58:	a089                	j	80004c9a <pipewrite+0x84>
      release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	02e080e7          	jalr	46(ra) # 80000c8a <release>
      return -1;
    80004c64:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c66:	854a                	mv	a0,s2
    80004c68:	60e6                	ld	ra,88(sp)
    80004c6a:	6446                	ld	s0,80(sp)
    80004c6c:	64a6                	ld	s1,72(sp)
    80004c6e:	6906                	ld	s2,64(sp)
    80004c70:	79e2                	ld	s3,56(sp)
    80004c72:	7a42                	ld	s4,48(sp)
    80004c74:	7aa2                	ld	s5,40(sp)
    80004c76:	7b02                	ld	s6,32(sp)
    80004c78:	6be2                	ld	s7,24(sp)
    80004c7a:	6c42                	ld	s8,16(sp)
    80004c7c:	6125                	addi	sp,sp,96
    80004c7e:	8082                	ret
      wakeup(&pi->nread);
    80004c80:	8562                	mv	a0,s8
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	4a2080e7          	jalr	1186(ra) # 80002124 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c8a:	85a6                	mv	a1,s1
    80004c8c:	855e                	mv	a0,s7
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	432080e7          	jalr	1074(ra) # 800020c0 <sleep>
  while(i < n){
    80004c96:	07495063          	bge	s2,s4,80004cf6 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c9a:	2204a783          	lw	a5,544(s1)
    80004c9e:	dfd5                	beqz	a5,80004c5a <pipewrite+0x44>
    80004ca0:	854e                	mv	a0,s3
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	6d2080e7          	jalr	1746(ra) # 80002374 <killed>
    80004caa:	f945                	bnez	a0,80004c5a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cac:	2184a783          	lw	a5,536(s1)
    80004cb0:	21c4a703          	lw	a4,540(s1)
    80004cb4:	2007879b          	addiw	a5,a5,512
    80004cb8:	fcf704e3          	beq	a4,a5,80004c80 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbc:	4685                	li	a3,1
    80004cbe:	01590633          	add	a2,s2,s5
    80004cc2:	faf40593          	addi	a1,s0,-81
    80004cc6:	0509b503          	ld	a0,80(s3)
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	a2a080e7          	jalr	-1494(ra) # 800016f4 <copyin>
    80004cd2:	03650263          	beq	a0,s6,80004cf6 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cd6:	21c4a783          	lw	a5,540(s1)
    80004cda:	0017871b          	addiw	a4,a5,1
    80004cde:	20e4ae23          	sw	a4,540(s1)
    80004ce2:	1ff7f793          	andi	a5,a5,511
    80004ce6:	97a6                	add	a5,a5,s1
    80004ce8:	faf44703          	lbu	a4,-81(s0)
    80004cec:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cf0:	2905                	addiw	s2,s2,1
    80004cf2:	b755                	j	80004c96 <pipewrite+0x80>
  int i = 0;
    80004cf4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cf6:	21848513          	addi	a0,s1,536
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	42a080e7          	jalr	1066(ra) # 80002124 <wakeup>
  release(&pi->lock);
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	f86080e7          	jalr	-122(ra) # 80000c8a <release>
  return i;
    80004d0c:	bfa9                	j	80004c66 <pipewrite+0x50>

0000000080004d0e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d0e:	715d                	addi	sp,sp,-80
    80004d10:	e486                	sd	ra,72(sp)
    80004d12:	e0a2                	sd	s0,64(sp)
    80004d14:	fc26                	sd	s1,56(sp)
    80004d16:	f84a                	sd	s2,48(sp)
    80004d18:	f44e                	sd	s3,40(sp)
    80004d1a:	f052                	sd	s4,32(sp)
    80004d1c:	ec56                	sd	s5,24(sp)
    80004d1e:	e85a                	sd	s6,16(sp)
    80004d20:	0880                	addi	s0,sp,80
    80004d22:	84aa                	mv	s1,a0
    80004d24:	892e                	mv	s2,a1
    80004d26:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80004d30:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d3c:	2184a703          	lw	a4,536(s1)
    80004d40:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d44:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d48:	02f71763          	bne	a4,a5,80004d76 <piperead+0x68>
    80004d4c:	2244a783          	lw	a5,548(s1)
    80004d50:	c39d                	beqz	a5,80004d76 <piperead+0x68>
    if(killed(pr)){
    80004d52:	8552                	mv	a0,s4
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	620080e7          	jalr	1568(ra) # 80002374 <killed>
    80004d5c:	e941                	bnez	a0,80004dec <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d5e:	85a6                	mv	a1,s1
    80004d60:	854e                	mv	a0,s3
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	35e080e7          	jalr	862(ra) # 800020c0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d6a:	2184a703          	lw	a4,536(s1)
    80004d6e:	21c4a783          	lw	a5,540(s1)
    80004d72:	fcf70de3          	beq	a4,a5,80004d4c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d76:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d78:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7a:	05505363          	blez	s5,80004dc0 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d7e:	2184a783          	lw	a5,536(s1)
    80004d82:	21c4a703          	lw	a4,540(s1)
    80004d86:	02f70d63          	beq	a4,a5,80004dc0 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d8a:	0017871b          	addiw	a4,a5,1
    80004d8e:	20e4ac23          	sw	a4,536(s1)
    80004d92:	1ff7f793          	andi	a5,a5,511
    80004d96:	97a6                	add	a5,a5,s1
    80004d98:	0187c783          	lbu	a5,24(a5)
    80004d9c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da0:	4685                	li	a3,1
    80004da2:	fbf40613          	addi	a2,s0,-65
    80004da6:	85ca                	mv	a1,s2
    80004da8:	050a3503          	ld	a0,80(s4)
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	8bc080e7          	jalr	-1860(ra) # 80001668 <copyout>
    80004db4:	01650663          	beq	a0,s6,80004dc0 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db8:	2985                	addiw	s3,s3,1
    80004dba:	0905                	addi	s2,s2,1
    80004dbc:	fd3a91e3          	bne	s5,s3,80004d7e <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dc0:	21c48513          	addi	a0,s1,540
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	360080e7          	jalr	864(ra) # 80002124 <wakeup>
  release(&pi->lock);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	ebc080e7          	jalr	-324(ra) # 80000c8a <release>
  return i;
}
    80004dd6:	854e                	mv	a0,s3
    80004dd8:	60a6                	ld	ra,72(sp)
    80004dda:	6406                	ld	s0,64(sp)
    80004ddc:	74e2                	ld	s1,56(sp)
    80004dde:	7942                	ld	s2,48(sp)
    80004de0:	79a2                	ld	s3,40(sp)
    80004de2:	7a02                	ld	s4,32(sp)
    80004de4:	6ae2                	ld	s5,24(sp)
    80004de6:	6b42                	ld	s6,16(sp)
    80004de8:	6161                	addi	sp,sp,80
    80004dea:	8082                	ret
      release(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	e9c080e7          	jalr	-356(ra) # 80000c8a <release>
      return -1;
    80004df6:	59fd                	li	s3,-1
    80004df8:	bff9                	j	80004dd6 <piperead+0xc8>

0000000080004dfa <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dfa:	1141                	addi	sp,sp,-16
    80004dfc:	e422                	sd	s0,8(sp)
    80004dfe:	0800                	addi	s0,sp,16
    80004e00:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e02:	8905                	andi	a0,a0,1
    80004e04:	c111                	beqz	a0,80004e08 <flags2perm+0xe>
      perm = PTE_X;
    80004e06:	4521                	li	a0,8
    if(flags & 0x2)
    80004e08:	8b89                	andi	a5,a5,2
    80004e0a:	c399                	beqz	a5,80004e10 <flags2perm+0x16>
      perm |= PTE_W;
    80004e0c:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e10:	6422                	ld	s0,8(sp)
    80004e12:	0141                	addi	sp,sp,16
    80004e14:	8082                	ret

0000000080004e16 <exec>:

int
exec(char *path, char **argv)
{
    80004e16:	de010113          	addi	sp,sp,-544
    80004e1a:	20113c23          	sd	ra,536(sp)
    80004e1e:	20813823          	sd	s0,528(sp)
    80004e22:	20913423          	sd	s1,520(sp)
    80004e26:	21213023          	sd	s2,512(sp)
    80004e2a:	ffce                	sd	s3,504(sp)
    80004e2c:	fbd2                	sd	s4,496(sp)
    80004e2e:	f7d6                	sd	s5,488(sp)
    80004e30:	f3da                	sd	s6,480(sp)
    80004e32:	efde                	sd	s7,472(sp)
    80004e34:	ebe2                	sd	s8,464(sp)
    80004e36:	e7e6                	sd	s9,456(sp)
    80004e38:	e3ea                	sd	s10,448(sp)
    80004e3a:	ff6e                	sd	s11,440(sp)
    80004e3c:	1400                	addi	s0,sp,544
    80004e3e:	892a                	mv	s2,a0
    80004e40:	dea43423          	sd	a0,-536(s0)
    80004e44:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	b64080e7          	jalr	-1180(ra) # 800019ac <myproc>
    80004e50:	84aa                	mv	s1,a0

  begin_op();
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	47e080e7          	jalr	1150(ra) # 800042d0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e5a:	854a                	mv	a0,s2
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	258080e7          	jalr	600(ra) # 800040b4 <namei>
    80004e64:	c93d                	beqz	a0,80004eda <exec+0xc4>
    80004e66:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	aa6080e7          	jalr	-1370(ra) # 8000390e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e70:	04000713          	li	a4,64
    80004e74:	4681                	li	a3,0
    80004e76:	e5040613          	addi	a2,s0,-432
    80004e7a:	4581                	li	a1,0
    80004e7c:	8556                	mv	a0,s5
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	d44080e7          	jalr	-700(ra) # 80003bc2 <readi>
    80004e86:	04000793          	li	a5,64
    80004e8a:	00f51a63          	bne	a0,a5,80004e9e <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e8e:	e5042703          	lw	a4,-432(s0)
    80004e92:	464c47b7          	lui	a5,0x464c4
    80004e96:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e9a:	04f70663          	beq	a4,a5,80004ee6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e9e:	8556                	mv	a0,s5
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	cd0080e7          	jalr	-816(ra) # 80003b70 <iunlockput>
    end_op();
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	4a8080e7          	jalr	1192(ra) # 80004350 <end_op>
  }
  return -1;
    80004eb0:	557d                	li	a0,-1
}
    80004eb2:	21813083          	ld	ra,536(sp)
    80004eb6:	21013403          	ld	s0,528(sp)
    80004eba:	20813483          	ld	s1,520(sp)
    80004ebe:	20013903          	ld	s2,512(sp)
    80004ec2:	79fe                	ld	s3,504(sp)
    80004ec4:	7a5e                	ld	s4,496(sp)
    80004ec6:	7abe                	ld	s5,488(sp)
    80004ec8:	7b1e                	ld	s6,480(sp)
    80004eca:	6bfe                	ld	s7,472(sp)
    80004ecc:	6c5e                	ld	s8,464(sp)
    80004ece:	6cbe                	ld	s9,456(sp)
    80004ed0:	6d1e                	ld	s10,448(sp)
    80004ed2:	7dfa                	ld	s11,440(sp)
    80004ed4:	22010113          	addi	sp,sp,544
    80004ed8:	8082                	ret
    end_op();
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	476080e7          	jalr	1142(ra) # 80004350 <end_op>
    return -1;
    80004ee2:	557d                	li	a0,-1
    80004ee4:	b7f9                	j	80004eb2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	ffffd097          	auipc	ra,0xffffd
    80004eec:	b88080e7          	jalr	-1144(ra) # 80001a70 <proc_pagetable>
    80004ef0:	8b2a                	mv	s6,a0
    80004ef2:	d555                	beqz	a0,80004e9e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef4:	e7042783          	lw	a5,-400(s0)
    80004ef8:	e8845703          	lhu	a4,-376(s0)
    80004efc:	c735                	beqz	a4,80004f68 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004efe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f00:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f04:	6a05                	lui	s4,0x1
    80004f06:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f0a:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004f0e:	6d85                	lui	s11,0x1
    80004f10:	7d7d                	lui	s10,0xfffff
    80004f12:	a481                	j	80005152 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f14:	00003517          	auipc	a0,0x3
    80004f18:	7dc50513          	addi	a0,a0,2012 # 800086f0 <syscalls+0x2a0>
    80004f1c:	ffffb097          	auipc	ra,0xffffb
    80004f20:	622080e7          	jalr	1570(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f24:	874a                	mv	a4,s2
    80004f26:	009c86bb          	addw	a3,s9,s1
    80004f2a:	4581                	li	a1,0
    80004f2c:	8556                	mv	a0,s5
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	c94080e7          	jalr	-876(ra) # 80003bc2 <readi>
    80004f36:	2501                	sext.w	a0,a0
    80004f38:	1aa91a63          	bne	s2,a0,800050ec <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f3c:	009d84bb          	addw	s1,s11,s1
    80004f40:	013d09bb          	addw	s3,s10,s3
    80004f44:	1f74f763          	bgeu	s1,s7,80005132 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004f48:	02049593          	slli	a1,s1,0x20
    80004f4c:	9181                	srli	a1,a1,0x20
    80004f4e:	95e2                	add	a1,a1,s8
    80004f50:	855a                	mv	a0,s6
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	10a080e7          	jalr	266(ra) # 8000105c <walkaddr>
    80004f5a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f5c:	dd45                	beqz	a0,80004f14 <exec+0xfe>
      n = PGSIZE;
    80004f5e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f60:	fd49f2e3          	bgeu	s3,s4,80004f24 <exec+0x10e>
      n = sz - i;
    80004f64:	894e                	mv	s2,s3
    80004f66:	bf7d                	j	80004f24 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f68:	4901                	li	s2,0
  iunlockput(ip);
    80004f6a:	8556                	mv	a0,s5
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	c04080e7          	jalr	-1020(ra) # 80003b70 <iunlockput>
  end_op();
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	3dc080e7          	jalr	988(ra) # 80004350 <end_op>
  p = myproc();
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	a30080e7          	jalr	-1488(ra) # 800019ac <myproc>
    80004f84:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f86:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f8a:	6785                	lui	a5,0x1
    80004f8c:	17fd                	addi	a5,a5,-1
    80004f8e:	993e                	add	s2,s2,a5
    80004f90:	77fd                	lui	a5,0xfffff
    80004f92:	00f977b3          	and	a5,s2,a5
    80004f96:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f9a:	4691                	li	a3,4
    80004f9c:	6609                	lui	a2,0x2
    80004f9e:	963e                	add	a2,a2,a5
    80004fa0:	85be                	mv	a1,a5
    80004fa2:	855a                	mv	a0,s6
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	46c080e7          	jalr	1132(ra) # 80001410 <uvmalloc>
    80004fac:	8c2a                	mv	s8,a0
  ip = 0;
    80004fae:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fb0:	12050e63          	beqz	a0,800050ec <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fb4:	75f9                	lui	a1,0xffffe
    80004fb6:	95aa                	add	a1,a1,a0
    80004fb8:	855a                	mv	a0,s6
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	67c080e7          	jalr	1660(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fc2:	7afd                	lui	s5,0xfffff
    80004fc4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fc6:	df043783          	ld	a5,-528(s0)
    80004fca:	6388                	ld	a0,0(a5)
    80004fcc:	c925                	beqz	a0,8000503c <exec+0x226>
    80004fce:	e9040993          	addi	s3,s0,-368
    80004fd2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fd6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	e74080e7          	jalr	-396(ra) # 80000e4e <strlen>
    80004fe2:	0015079b          	addiw	a5,a0,1
    80004fe6:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fea:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fee:	13596663          	bltu	s2,s5,8000511a <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ff2:	df043d83          	ld	s11,-528(s0)
    80004ff6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ffa:	8552                	mv	a0,s4
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	e52080e7          	jalr	-430(ra) # 80000e4e <strlen>
    80005004:	0015069b          	addiw	a3,a0,1
    80005008:	8652                	mv	a2,s4
    8000500a:	85ca                	mv	a1,s2
    8000500c:	855a                	mv	a0,s6
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	65a080e7          	jalr	1626(ra) # 80001668 <copyout>
    80005016:	10054663          	bltz	a0,80005122 <exec+0x30c>
    ustack[argc] = sp;
    8000501a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000501e:	0485                	addi	s1,s1,1
    80005020:	008d8793          	addi	a5,s11,8
    80005024:	def43823          	sd	a5,-528(s0)
    80005028:	008db503          	ld	a0,8(s11)
    8000502c:	c911                	beqz	a0,80005040 <exec+0x22a>
    if(argc >= MAXARG)
    8000502e:	09a1                	addi	s3,s3,8
    80005030:	fb3c95e3          	bne	s9,s3,80004fda <exec+0x1c4>
  sz = sz1;
    80005034:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005038:	4a81                	li	s5,0
    8000503a:	a84d                	j	800050ec <exec+0x2d6>
  sp = sz;
    8000503c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000503e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005040:	00349793          	slli	a5,s1,0x3
    80005044:	f9040713          	addi	a4,s0,-112
    80005048:	97ba                	add	a5,a5,a4
    8000504a:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc5a0>
  sp -= (argc+1) * sizeof(uint64);
    8000504e:	00148693          	addi	a3,s1,1
    80005052:	068e                	slli	a3,a3,0x3
    80005054:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005058:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000505c:	01597663          	bgeu	s2,s5,80005068 <exec+0x252>
  sz = sz1;
    80005060:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005064:	4a81                	li	s5,0
    80005066:	a059                	j	800050ec <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005068:	e9040613          	addi	a2,s0,-368
    8000506c:	85ca                	mv	a1,s2
    8000506e:	855a                	mv	a0,s6
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	5f8080e7          	jalr	1528(ra) # 80001668 <copyout>
    80005078:	0a054963          	bltz	a0,8000512a <exec+0x314>
  p->trapframe->a1 = sp;
    8000507c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005080:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005084:	de843783          	ld	a5,-536(s0)
    80005088:	0007c703          	lbu	a4,0(a5)
    8000508c:	cf11                	beqz	a4,800050a8 <exec+0x292>
    8000508e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005090:	02f00693          	li	a3,47
    80005094:	a039                	j	800050a2 <exec+0x28c>
      last = s+1;
    80005096:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000509a:	0785                	addi	a5,a5,1
    8000509c:	fff7c703          	lbu	a4,-1(a5)
    800050a0:	c701                	beqz	a4,800050a8 <exec+0x292>
    if(*s == '/')
    800050a2:	fed71ce3          	bne	a4,a3,8000509a <exec+0x284>
    800050a6:	bfc5                	j	80005096 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a8:	4641                	li	a2,16
    800050aa:	de843583          	ld	a1,-536(s0)
    800050ae:	158b8513          	addi	a0,s7,344
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	d6a080e7          	jalr	-662(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800050ba:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050be:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050c2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050c6:	058bb783          	ld	a5,88(s7)
    800050ca:	e6843703          	ld	a4,-408(s0)
    800050ce:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050d0:	058bb783          	ld	a5,88(s7)
    800050d4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d8:	85ea                	mv	a1,s10
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	a32080e7          	jalr	-1486(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050e2:	0004851b          	sext.w	a0,s1
    800050e6:	b3f1                	j	80004eb2 <exec+0x9c>
    800050e8:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050ec:	df843583          	ld	a1,-520(s0)
    800050f0:	855a                	mv	a0,s6
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	a1a080e7          	jalr	-1510(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800050fa:	da0a92e3          	bnez	s5,80004e9e <exec+0x88>
  return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	bb4d                	j	80004eb2 <exec+0x9c>
    80005102:	df243c23          	sd	s2,-520(s0)
    80005106:	b7dd                	j	800050ec <exec+0x2d6>
    80005108:	df243c23          	sd	s2,-520(s0)
    8000510c:	b7c5                	j	800050ec <exec+0x2d6>
    8000510e:	df243c23          	sd	s2,-520(s0)
    80005112:	bfe9                	j	800050ec <exec+0x2d6>
    80005114:	df243c23          	sd	s2,-520(s0)
    80005118:	bfd1                	j	800050ec <exec+0x2d6>
  sz = sz1;
    8000511a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511e:	4a81                	li	s5,0
    80005120:	b7f1                	j	800050ec <exec+0x2d6>
  sz = sz1;
    80005122:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005126:	4a81                	li	s5,0
    80005128:	b7d1                	j	800050ec <exec+0x2d6>
  sz = sz1;
    8000512a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000512e:	4a81                	li	s5,0
    80005130:	bf75                	j	800050ec <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005132:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005136:	e0843783          	ld	a5,-504(s0)
    8000513a:	0017869b          	addiw	a3,a5,1
    8000513e:	e0d43423          	sd	a3,-504(s0)
    80005142:	e0043783          	ld	a5,-512(s0)
    80005146:	0387879b          	addiw	a5,a5,56
    8000514a:	e8845703          	lhu	a4,-376(s0)
    8000514e:	e0e6dee3          	bge	a3,a4,80004f6a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005152:	2781                	sext.w	a5,a5
    80005154:	e0f43023          	sd	a5,-512(s0)
    80005158:	03800713          	li	a4,56
    8000515c:	86be                	mv	a3,a5
    8000515e:	e1840613          	addi	a2,s0,-488
    80005162:	4581                	li	a1,0
    80005164:	8556                	mv	a0,s5
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	a5c080e7          	jalr	-1444(ra) # 80003bc2 <readi>
    8000516e:	03800793          	li	a5,56
    80005172:	f6f51be3          	bne	a0,a5,800050e8 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005176:	e1842783          	lw	a5,-488(s0)
    8000517a:	4705                	li	a4,1
    8000517c:	fae79de3          	bne	a5,a4,80005136 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005180:	e4043483          	ld	s1,-448(s0)
    80005184:	e3843783          	ld	a5,-456(s0)
    80005188:	f6f4ede3          	bltu	s1,a5,80005102 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000518c:	e2843783          	ld	a5,-472(s0)
    80005190:	94be                	add	s1,s1,a5
    80005192:	f6f4ebe3          	bltu	s1,a5,80005108 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005196:	de043703          	ld	a4,-544(s0)
    8000519a:	8ff9                	and	a5,a5,a4
    8000519c:	fbad                	bnez	a5,8000510e <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000519e:	e1c42503          	lw	a0,-484(s0)
    800051a2:	00000097          	auipc	ra,0x0
    800051a6:	c58080e7          	jalr	-936(ra) # 80004dfa <flags2perm>
    800051aa:	86aa                	mv	a3,a0
    800051ac:	8626                	mv	a2,s1
    800051ae:	85ca                	mv	a1,s2
    800051b0:	855a                	mv	a0,s6
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	25e080e7          	jalr	606(ra) # 80001410 <uvmalloc>
    800051ba:	dea43c23          	sd	a0,-520(s0)
    800051be:	d939                	beqz	a0,80005114 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051c0:	e2843c03          	ld	s8,-472(s0)
    800051c4:	e2042c83          	lw	s9,-480(s0)
    800051c8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051cc:	f60b83e3          	beqz	s7,80005132 <exec+0x31c>
    800051d0:	89de                	mv	s3,s7
    800051d2:	4481                	li	s1,0
    800051d4:	bb95                	j	80004f48 <exec+0x132>

00000000800051d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051d6:	7179                	addi	sp,sp,-48
    800051d8:	f406                	sd	ra,40(sp)
    800051da:	f022                	sd	s0,32(sp)
    800051dc:	ec26                	sd	s1,24(sp)
    800051de:	e84a                	sd	s2,16(sp)
    800051e0:	1800                	addi	s0,sp,48
    800051e2:	892e                	mv	s2,a1
    800051e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051e6:	fdc40593          	addi	a1,s0,-36
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	b08080e7          	jalr	-1272(ra) # 80002cf2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051f2:	fdc42703          	lw	a4,-36(s0)
    800051f6:	47bd                	li	a5,15
    800051f8:	02e7eb63          	bltu	a5,a4,8000522e <argfd+0x58>
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	7b0080e7          	jalr	1968(ra) # 800019ac <myproc>
    80005204:	fdc42703          	lw	a4,-36(s0)
    80005208:	01a70793          	addi	a5,a4,26
    8000520c:	078e                	slli	a5,a5,0x3
    8000520e:	953e                	add	a0,a0,a5
    80005210:	611c                	ld	a5,0(a0)
    80005212:	c385                	beqz	a5,80005232 <argfd+0x5c>
    return -1;
  if(pfd)
    80005214:	00090463          	beqz	s2,8000521c <argfd+0x46>
    *pfd = fd;
    80005218:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000521c:	4501                	li	a0,0
  if(pf)
    8000521e:	c091                	beqz	s1,80005222 <argfd+0x4c>
    *pf = f;
    80005220:	e09c                	sd	a5,0(s1)
}
    80005222:	70a2                	ld	ra,40(sp)
    80005224:	7402                	ld	s0,32(sp)
    80005226:	64e2                	ld	s1,24(sp)
    80005228:	6942                	ld	s2,16(sp)
    8000522a:	6145                	addi	sp,sp,48
    8000522c:	8082                	ret
    return -1;
    8000522e:	557d                	li	a0,-1
    80005230:	bfcd                	j	80005222 <argfd+0x4c>
    80005232:	557d                	li	a0,-1
    80005234:	b7fd                	j	80005222 <argfd+0x4c>

0000000080005236 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005236:	1101                	addi	sp,sp,-32
    80005238:	ec06                	sd	ra,24(sp)
    8000523a:	e822                	sd	s0,16(sp)
    8000523c:	e426                	sd	s1,8(sp)
    8000523e:	1000                	addi	s0,sp,32
    80005240:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	76a080e7          	jalr	1898(ra) # 800019ac <myproc>
    8000524a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000524c:	0d050793          	addi	a5,a0,208
    80005250:	4501                	li	a0,0
    80005252:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005254:	6398                	ld	a4,0(a5)
    80005256:	cb19                	beqz	a4,8000526c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005258:	2505                	addiw	a0,a0,1
    8000525a:	07a1                	addi	a5,a5,8
    8000525c:	fed51ce3          	bne	a0,a3,80005254 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005260:	557d                	li	a0,-1
}
    80005262:	60e2                	ld	ra,24(sp)
    80005264:	6442                	ld	s0,16(sp)
    80005266:	64a2                	ld	s1,8(sp)
    80005268:	6105                	addi	sp,sp,32
    8000526a:	8082                	ret
      p->ofile[fd] = f;
    8000526c:	01a50793          	addi	a5,a0,26
    80005270:	078e                	slli	a5,a5,0x3
    80005272:	963e                	add	a2,a2,a5
    80005274:	e204                	sd	s1,0(a2)
      return fd;
    80005276:	b7f5                	j	80005262 <fdalloc+0x2c>

0000000080005278 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005278:	715d                	addi	sp,sp,-80
    8000527a:	e486                	sd	ra,72(sp)
    8000527c:	e0a2                	sd	s0,64(sp)
    8000527e:	fc26                	sd	s1,56(sp)
    80005280:	f84a                	sd	s2,48(sp)
    80005282:	f44e                	sd	s3,40(sp)
    80005284:	f052                	sd	s4,32(sp)
    80005286:	ec56                	sd	s5,24(sp)
    80005288:	e85a                	sd	s6,16(sp)
    8000528a:	0880                	addi	s0,sp,80
    8000528c:	8b2e                	mv	s6,a1
    8000528e:	89b2                	mv	s3,a2
    80005290:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005292:	fb040593          	addi	a1,s0,-80
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	e3c080e7          	jalr	-452(ra) # 800040d2 <nameiparent>
    8000529e:	84aa                	mv	s1,a0
    800052a0:	14050f63          	beqz	a0,800053fe <create+0x186>
    return 0;

  ilock(dp);
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	66a080e7          	jalr	1642(ra) # 8000390e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ac:	4601                	li	a2,0
    800052ae:	fb040593          	addi	a1,s0,-80
    800052b2:	8526                	mv	a0,s1
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	b3e080e7          	jalr	-1218(ra) # 80003df2 <dirlookup>
    800052bc:	8aaa                	mv	s5,a0
    800052be:	c931                	beqz	a0,80005312 <create+0x9a>
    iunlockput(dp);
    800052c0:	8526                	mv	a0,s1
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	8ae080e7          	jalr	-1874(ra) # 80003b70 <iunlockput>
    ilock(ip);
    800052ca:	8556                	mv	a0,s5
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	642080e7          	jalr	1602(ra) # 8000390e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052d4:	000b059b          	sext.w	a1,s6
    800052d8:	4789                	li	a5,2
    800052da:	02f59563          	bne	a1,a5,80005304 <create+0x8c>
    800052de:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc6e4>
    800052e2:	37f9                	addiw	a5,a5,-2
    800052e4:	17c2                	slli	a5,a5,0x30
    800052e6:	93c1                	srli	a5,a5,0x30
    800052e8:	4705                	li	a4,1
    800052ea:	00f76d63          	bltu	a4,a5,80005304 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052ee:	8556                	mv	a0,s5
    800052f0:	60a6                	ld	ra,72(sp)
    800052f2:	6406                	ld	s0,64(sp)
    800052f4:	74e2                	ld	s1,56(sp)
    800052f6:	7942                	ld	s2,48(sp)
    800052f8:	79a2                	ld	s3,40(sp)
    800052fa:	7a02                	ld	s4,32(sp)
    800052fc:	6ae2                	ld	s5,24(sp)
    800052fe:	6b42                	ld	s6,16(sp)
    80005300:	6161                	addi	sp,sp,80
    80005302:	8082                	ret
    iunlockput(ip);
    80005304:	8556                	mv	a0,s5
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	86a080e7          	jalr	-1942(ra) # 80003b70 <iunlockput>
    return 0;
    8000530e:	4a81                	li	s5,0
    80005310:	bff9                	j	800052ee <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005312:	85da                	mv	a1,s6
    80005314:	4088                	lw	a0,0(s1)
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	45c080e7          	jalr	1116(ra) # 80003772 <ialloc>
    8000531e:	8a2a                	mv	s4,a0
    80005320:	c539                	beqz	a0,8000536e <create+0xf6>
  ilock(ip);
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	5ec080e7          	jalr	1516(ra) # 8000390e <ilock>
  ip->major = major;
    8000532a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000532e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005332:	4905                	li	s2,1
    80005334:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005338:	8552                	mv	a0,s4
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	50a080e7          	jalr	1290(ra) # 80003844 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005342:	000b059b          	sext.w	a1,s6
    80005346:	03258b63          	beq	a1,s2,8000537c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000534a:	004a2603          	lw	a2,4(s4)
    8000534e:	fb040593          	addi	a1,s0,-80
    80005352:	8526                	mv	a0,s1
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	cae080e7          	jalr	-850(ra) # 80004002 <dirlink>
    8000535c:	06054f63          	bltz	a0,800053da <create+0x162>
  iunlockput(dp);
    80005360:	8526                	mv	a0,s1
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	80e080e7          	jalr	-2034(ra) # 80003b70 <iunlockput>
  return ip;
    8000536a:	8ad2                	mv	s5,s4
    8000536c:	b749                	j	800052ee <create+0x76>
    iunlockput(dp);
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	800080e7          	jalr	-2048(ra) # 80003b70 <iunlockput>
    return 0;
    80005378:	8ad2                	mv	s5,s4
    8000537a:	bf95                	j	800052ee <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000537c:	004a2603          	lw	a2,4(s4)
    80005380:	00003597          	auipc	a1,0x3
    80005384:	39058593          	addi	a1,a1,912 # 80008710 <syscalls+0x2c0>
    80005388:	8552                	mv	a0,s4
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	c78080e7          	jalr	-904(ra) # 80004002 <dirlink>
    80005392:	04054463          	bltz	a0,800053da <create+0x162>
    80005396:	40d0                	lw	a2,4(s1)
    80005398:	00003597          	auipc	a1,0x3
    8000539c:	38058593          	addi	a1,a1,896 # 80008718 <syscalls+0x2c8>
    800053a0:	8552                	mv	a0,s4
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	c60080e7          	jalr	-928(ra) # 80004002 <dirlink>
    800053aa:	02054863          	bltz	a0,800053da <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ae:	004a2603          	lw	a2,4(s4)
    800053b2:	fb040593          	addi	a1,s0,-80
    800053b6:	8526                	mv	a0,s1
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	c4a080e7          	jalr	-950(ra) # 80004002 <dirlink>
    800053c0:	00054d63          	bltz	a0,800053da <create+0x162>
    dp->nlink++;  // for ".."
    800053c4:	04a4d783          	lhu	a5,74(s1)
    800053c8:	2785                	addiw	a5,a5,1
    800053ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053ce:	8526                	mv	a0,s1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	474080e7          	jalr	1140(ra) # 80003844 <iupdate>
    800053d8:	b761                	j	80005360 <create+0xe8>
  ip->nlink = 0;
    800053da:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053de:	8552                	mv	a0,s4
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	464080e7          	jalr	1124(ra) # 80003844 <iupdate>
  iunlockput(ip);
    800053e8:	8552                	mv	a0,s4
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	786080e7          	jalr	1926(ra) # 80003b70 <iunlockput>
  iunlockput(dp);
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	77c080e7          	jalr	1916(ra) # 80003b70 <iunlockput>
  return 0;
    800053fc:	bdcd                	j	800052ee <create+0x76>
    return 0;
    800053fe:	8aaa                	mv	s5,a0
    80005400:	b5fd                	j	800052ee <create+0x76>

0000000080005402 <sys_dup>:
{
    80005402:	7179                	addi	sp,sp,-48
    80005404:	f406                	sd	ra,40(sp)
    80005406:	f022                	sd	s0,32(sp)
    80005408:	ec26                	sd	s1,24(sp)
    8000540a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000540c:	fd840613          	addi	a2,s0,-40
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	dc2080e7          	jalr	-574(ra) # 800051d6 <argfd>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000541e:	02054363          	bltz	a0,80005444 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005422:	fd843503          	ld	a0,-40(s0)
    80005426:	00000097          	auipc	ra,0x0
    8000542a:	e10080e7          	jalr	-496(ra) # 80005236 <fdalloc>
    8000542e:	84aa                	mv	s1,a0
    return -1;
    80005430:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005432:	00054963          	bltz	a0,80005444 <sys_dup+0x42>
  filedup(f);
    80005436:	fd843503          	ld	a0,-40(s0)
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	310080e7          	jalr	784(ra) # 8000474a <filedup>
  return fd;
    80005442:	87a6                	mv	a5,s1
}
    80005444:	853e                	mv	a0,a5
    80005446:	70a2                	ld	ra,40(sp)
    80005448:	7402                	ld	s0,32(sp)
    8000544a:	64e2                	ld	s1,24(sp)
    8000544c:	6145                	addi	sp,sp,48
    8000544e:	8082                	ret

0000000080005450 <sys_read>:
{
    80005450:	7179                	addi	sp,sp,-48
    80005452:	f406                	sd	ra,40(sp)
    80005454:	f022                	sd	s0,32(sp)
    80005456:	1800                	addi	s0,sp,48
  readcount++;
    80005458:	00003717          	auipc	a4,0x3
    8000545c:	48c70713          	addi	a4,a4,1164 # 800088e4 <readcount>
    80005460:	431c                	lw	a5,0(a4)
    80005462:	2785                	addiw	a5,a5,1
    80005464:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005466:	fd840593          	addi	a1,s0,-40
    8000546a:	4505                	li	a0,1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	8a6080e7          	jalr	-1882(ra) # 80002d12 <argaddr>
  argint(2, &n);
    80005474:	fe440593          	addi	a1,s0,-28
    80005478:	4509                	li	a0,2
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	878080e7          	jalr	-1928(ra) # 80002cf2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005482:	fe840613          	addi	a2,s0,-24
    80005486:	4581                	li	a1,0
    80005488:	4501                	li	a0,0
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	d4c080e7          	jalr	-692(ra) # 800051d6 <argfd>
    80005492:	87aa                	mv	a5,a0
    return -1;
    80005494:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005496:	0007cc63          	bltz	a5,800054ae <sys_read+0x5e>
  return fileread(f, p, n);
    8000549a:	fe442603          	lw	a2,-28(s0)
    8000549e:	fd843583          	ld	a1,-40(s0)
    800054a2:	fe843503          	ld	a0,-24(s0)
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	430080e7          	jalr	1072(ra) # 800048d6 <fileread>
}
    800054ae:	70a2                	ld	ra,40(sp)
    800054b0:	7402                	ld	s0,32(sp)
    800054b2:	6145                	addi	sp,sp,48
    800054b4:	8082                	ret

00000000800054b6 <sys_write>:
{
    800054b6:	7179                	addi	sp,sp,-48
    800054b8:	f406                	sd	ra,40(sp)
    800054ba:	f022                	sd	s0,32(sp)
    800054bc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054be:	fd840593          	addi	a1,s0,-40
    800054c2:	4505                	li	a0,1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	84e080e7          	jalr	-1970(ra) # 80002d12 <argaddr>
  argint(2, &n);
    800054cc:	fe440593          	addi	a1,s0,-28
    800054d0:	4509                	li	a0,2
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	820080e7          	jalr	-2016(ra) # 80002cf2 <argint>
  if(argfd(0, 0, &f) < 0)
    800054da:	fe840613          	addi	a2,s0,-24
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	cf4080e7          	jalr	-780(ra) # 800051d6 <argfd>
    800054ea:	87aa                	mv	a5,a0
    return -1;
    800054ec:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054ee:	0007cc63          	bltz	a5,80005506 <sys_write+0x50>
  return filewrite(f, p, n);
    800054f2:	fe442603          	lw	a2,-28(s0)
    800054f6:	fd843583          	ld	a1,-40(s0)
    800054fa:	fe843503          	ld	a0,-24(s0)
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	49a080e7          	jalr	1178(ra) # 80004998 <filewrite>
}
    80005506:	70a2                	ld	ra,40(sp)
    80005508:	7402                	ld	s0,32(sp)
    8000550a:	6145                	addi	sp,sp,48
    8000550c:	8082                	ret

000000008000550e <sys_close>:
{
    8000550e:	1101                	addi	sp,sp,-32
    80005510:	ec06                	sd	ra,24(sp)
    80005512:	e822                	sd	s0,16(sp)
    80005514:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005516:	fe040613          	addi	a2,s0,-32
    8000551a:	fec40593          	addi	a1,s0,-20
    8000551e:	4501                	li	a0,0
    80005520:	00000097          	auipc	ra,0x0
    80005524:	cb6080e7          	jalr	-842(ra) # 800051d6 <argfd>
    return -1;
    80005528:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000552a:	02054463          	bltz	a0,80005552 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	47e080e7          	jalr	1150(ra) # 800019ac <myproc>
    80005536:	fec42783          	lw	a5,-20(s0)
    8000553a:	07e9                	addi	a5,a5,26
    8000553c:	078e                	slli	a5,a5,0x3
    8000553e:	97aa                	add	a5,a5,a0
    80005540:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005544:	fe043503          	ld	a0,-32(s0)
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	254080e7          	jalr	596(ra) # 8000479c <fileclose>
  return 0;
    80005550:	4781                	li	a5,0
}
    80005552:	853e                	mv	a0,a5
    80005554:	60e2                	ld	ra,24(sp)
    80005556:	6442                	ld	s0,16(sp)
    80005558:	6105                	addi	sp,sp,32
    8000555a:	8082                	ret

000000008000555c <sys_fstat>:
{
    8000555c:	1101                	addi	sp,sp,-32
    8000555e:	ec06                	sd	ra,24(sp)
    80005560:	e822                	sd	s0,16(sp)
    80005562:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005564:	fe040593          	addi	a1,s0,-32
    80005568:	4505                	li	a0,1
    8000556a:	ffffd097          	auipc	ra,0xffffd
    8000556e:	7a8080e7          	jalr	1960(ra) # 80002d12 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005572:	fe840613          	addi	a2,s0,-24
    80005576:	4581                	li	a1,0
    80005578:	4501                	li	a0,0
    8000557a:	00000097          	auipc	ra,0x0
    8000557e:	c5c080e7          	jalr	-932(ra) # 800051d6 <argfd>
    80005582:	87aa                	mv	a5,a0
    return -1;
    80005584:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005586:	0007ca63          	bltz	a5,8000559a <sys_fstat+0x3e>
  return filestat(f, st);
    8000558a:	fe043583          	ld	a1,-32(s0)
    8000558e:	fe843503          	ld	a0,-24(s0)
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	2d2080e7          	jalr	722(ra) # 80004864 <filestat>
}
    8000559a:	60e2                	ld	ra,24(sp)
    8000559c:	6442                	ld	s0,16(sp)
    8000559e:	6105                	addi	sp,sp,32
    800055a0:	8082                	ret

00000000800055a2 <sys_link>:
{
    800055a2:	7169                	addi	sp,sp,-304
    800055a4:	f606                	sd	ra,296(sp)
    800055a6:	f222                	sd	s0,288(sp)
    800055a8:	ee26                	sd	s1,280(sp)
    800055aa:	ea4a                	sd	s2,272(sp)
    800055ac:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ae:	08000613          	li	a2,128
    800055b2:	ed040593          	addi	a1,s0,-304
    800055b6:	4501                	li	a0,0
    800055b8:	ffffd097          	auipc	ra,0xffffd
    800055bc:	77a080e7          	jalr	1914(ra) # 80002d32 <argstr>
    return -1;
    800055c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c2:	10054e63          	bltz	a0,800056de <sys_link+0x13c>
    800055c6:	08000613          	li	a2,128
    800055ca:	f5040593          	addi	a1,s0,-176
    800055ce:	4505                	li	a0,1
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	762080e7          	jalr	1890(ra) # 80002d32 <argstr>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055da:	10054263          	bltz	a0,800056de <sys_link+0x13c>
  begin_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	cf2080e7          	jalr	-782(ra) # 800042d0 <begin_op>
  if((ip = namei(old)) == 0){
    800055e6:	ed040513          	addi	a0,s0,-304
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	aca080e7          	jalr	-1334(ra) # 800040b4 <namei>
    800055f2:	84aa                	mv	s1,a0
    800055f4:	c551                	beqz	a0,80005680 <sys_link+0xde>
  ilock(ip);
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	318080e7          	jalr	792(ra) # 8000390e <ilock>
  if(ip->type == T_DIR){
    800055fe:	04449703          	lh	a4,68(s1)
    80005602:	4785                	li	a5,1
    80005604:	08f70463          	beq	a4,a5,8000568c <sys_link+0xea>
  ip->nlink++;
    80005608:	04a4d783          	lhu	a5,74(s1)
    8000560c:	2785                	addiw	a5,a5,1
    8000560e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	230080e7          	jalr	560(ra) # 80003844 <iupdate>
  iunlock(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	3b2080e7          	jalr	946(ra) # 800039d0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005626:	fd040593          	addi	a1,s0,-48
    8000562a:	f5040513          	addi	a0,s0,-176
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	aa4080e7          	jalr	-1372(ra) # 800040d2 <nameiparent>
    80005636:	892a                	mv	s2,a0
    80005638:	c935                	beqz	a0,800056ac <sys_link+0x10a>
  ilock(dp);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	2d4080e7          	jalr	724(ra) # 8000390e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005642:	00092703          	lw	a4,0(s2)
    80005646:	409c                	lw	a5,0(s1)
    80005648:	04f71d63          	bne	a4,a5,800056a2 <sys_link+0x100>
    8000564c:	40d0                	lw	a2,4(s1)
    8000564e:	fd040593          	addi	a1,s0,-48
    80005652:	854a                	mv	a0,s2
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	9ae080e7          	jalr	-1618(ra) # 80004002 <dirlink>
    8000565c:	04054363          	bltz	a0,800056a2 <sys_link+0x100>
  iunlockput(dp);
    80005660:	854a                	mv	a0,s2
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	50e080e7          	jalr	1294(ra) # 80003b70 <iunlockput>
  iput(ip);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	45c080e7          	jalr	1116(ra) # 80003ac8 <iput>
  end_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	cdc080e7          	jalr	-804(ra) # 80004350 <end_op>
  return 0;
    8000567c:	4781                	li	a5,0
    8000567e:	a085                	j	800056de <sys_link+0x13c>
    end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	cd0080e7          	jalr	-816(ra) # 80004350 <end_op>
    return -1;
    80005688:	57fd                	li	a5,-1
    8000568a:	a891                	j	800056de <sys_link+0x13c>
    iunlockput(ip);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	4e2080e7          	jalr	1250(ra) # 80003b70 <iunlockput>
    end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	cba080e7          	jalr	-838(ra) # 80004350 <end_op>
    return -1;
    8000569e:	57fd                	li	a5,-1
    800056a0:	a83d                	j	800056de <sys_link+0x13c>
    iunlockput(dp);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	4cc080e7          	jalr	1228(ra) # 80003b70 <iunlockput>
  ilock(ip);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	260080e7          	jalr	608(ra) # 8000390e <ilock>
  ip->nlink--;
    800056b6:	04a4d783          	lhu	a5,74(s1)
    800056ba:	37fd                	addiw	a5,a5,-1
    800056bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	182080e7          	jalr	386(ra) # 80003844 <iupdate>
  iunlockput(ip);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	4a4080e7          	jalr	1188(ra) # 80003b70 <iunlockput>
  end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	c7c080e7          	jalr	-900(ra) # 80004350 <end_op>
  return -1;
    800056dc:	57fd                	li	a5,-1
}
    800056de:	853e                	mv	a0,a5
    800056e0:	70b2                	ld	ra,296(sp)
    800056e2:	7412                	ld	s0,288(sp)
    800056e4:	64f2                	ld	s1,280(sp)
    800056e6:	6952                	ld	s2,272(sp)
    800056e8:	6155                	addi	sp,sp,304
    800056ea:	8082                	ret

00000000800056ec <sys_unlink>:
{
    800056ec:	7151                	addi	sp,sp,-240
    800056ee:	f586                	sd	ra,232(sp)
    800056f0:	f1a2                	sd	s0,224(sp)
    800056f2:	eda6                	sd	s1,216(sp)
    800056f4:	e9ca                	sd	s2,208(sp)
    800056f6:	e5ce                	sd	s3,200(sp)
    800056f8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056fa:	08000613          	li	a2,128
    800056fe:	f3040593          	addi	a1,s0,-208
    80005702:	4501                	li	a0,0
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	62e080e7          	jalr	1582(ra) # 80002d32 <argstr>
    8000570c:	18054163          	bltz	a0,8000588e <sys_unlink+0x1a2>
  begin_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	bc0080e7          	jalr	-1088(ra) # 800042d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005718:	fb040593          	addi	a1,s0,-80
    8000571c:	f3040513          	addi	a0,s0,-208
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	9b2080e7          	jalr	-1614(ra) # 800040d2 <nameiparent>
    80005728:	84aa                	mv	s1,a0
    8000572a:	c979                	beqz	a0,80005800 <sys_unlink+0x114>
  ilock(dp);
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	1e2080e7          	jalr	482(ra) # 8000390e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005734:	00003597          	auipc	a1,0x3
    80005738:	fdc58593          	addi	a1,a1,-36 # 80008710 <syscalls+0x2c0>
    8000573c:	fb040513          	addi	a0,s0,-80
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	698080e7          	jalr	1688(ra) # 80003dd8 <namecmp>
    80005748:	14050a63          	beqz	a0,8000589c <sys_unlink+0x1b0>
    8000574c:	00003597          	auipc	a1,0x3
    80005750:	fcc58593          	addi	a1,a1,-52 # 80008718 <syscalls+0x2c8>
    80005754:	fb040513          	addi	a0,s0,-80
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	680080e7          	jalr	1664(ra) # 80003dd8 <namecmp>
    80005760:	12050e63          	beqz	a0,8000589c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005764:	f2c40613          	addi	a2,s0,-212
    80005768:	fb040593          	addi	a1,s0,-80
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	684080e7          	jalr	1668(ra) # 80003df2 <dirlookup>
    80005776:	892a                	mv	s2,a0
    80005778:	12050263          	beqz	a0,8000589c <sys_unlink+0x1b0>
  ilock(ip);
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	192080e7          	jalr	402(ra) # 8000390e <ilock>
  if(ip->nlink < 1)
    80005784:	04a91783          	lh	a5,74(s2)
    80005788:	08f05263          	blez	a5,8000580c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000578c:	04491703          	lh	a4,68(s2)
    80005790:	4785                	li	a5,1
    80005792:	08f70563          	beq	a4,a5,8000581c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005796:	4641                	li	a2,16
    80005798:	4581                	li	a1,0
    8000579a:	fc040513          	addi	a0,s0,-64
    8000579e:	ffffb097          	auipc	ra,0xffffb
    800057a2:	534080e7          	jalr	1332(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057a6:	4741                	li	a4,16
    800057a8:	f2c42683          	lw	a3,-212(s0)
    800057ac:	fc040613          	addi	a2,s0,-64
    800057b0:	4581                	li	a1,0
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	506080e7          	jalr	1286(ra) # 80003cba <writei>
    800057bc:	47c1                	li	a5,16
    800057be:	0af51563          	bne	a0,a5,80005868 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057c2:	04491703          	lh	a4,68(s2)
    800057c6:	4785                	li	a5,1
    800057c8:	0af70863          	beq	a4,a5,80005878 <sys_unlink+0x18c>
  iunlockput(dp);
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	3a2080e7          	jalr	930(ra) # 80003b70 <iunlockput>
  ip->nlink--;
    800057d6:	04a95783          	lhu	a5,74(s2)
    800057da:	37fd                	addiw	a5,a5,-1
    800057dc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	062080e7          	jalr	98(ra) # 80003844 <iupdate>
  iunlockput(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	384080e7          	jalr	900(ra) # 80003b70 <iunlockput>
  end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	b5c080e7          	jalr	-1188(ra) # 80004350 <end_op>
  return 0;
    800057fc:	4501                	li	a0,0
    800057fe:	a84d                	j	800058b0 <sys_unlink+0x1c4>
    end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	b50080e7          	jalr	-1200(ra) # 80004350 <end_op>
    return -1;
    80005808:	557d                	li	a0,-1
    8000580a:	a05d                	j	800058b0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000580c:	00003517          	auipc	a0,0x3
    80005810:	f1450513          	addi	a0,a0,-236 # 80008720 <syscalls+0x2d0>
    80005814:	ffffb097          	auipc	ra,0xffffb
    80005818:	d2a080e7          	jalr	-726(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000581c:	04c92703          	lw	a4,76(s2)
    80005820:	02000793          	li	a5,32
    80005824:	f6e7f9e3          	bgeu	a5,a4,80005796 <sys_unlink+0xaa>
    80005828:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000582c:	4741                	li	a4,16
    8000582e:	86ce                	mv	a3,s3
    80005830:	f1840613          	addi	a2,s0,-232
    80005834:	4581                	li	a1,0
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	38a080e7          	jalr	906(ra) # 80003bc2 <readi>
    80005840:	47c1                	li	a5,16
    80005842:	00f51b63          	bne	a0,a5,80005858 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005846:	f1845783          	lhu	a5,-232(s0)
    8000584a:	e7a1                	bnez	a5,80005892 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000584c:	29c1                	addiw	s3,s3,16
    8000584e:	04c92783          	lw	a5,76(s2)
    80005852:	fcf9ede3          	bltu	s3,a5,8000582c <sys_unlink+0x140>
    80005856:	b781                	j	80005796 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005858:	00003517          	auipc	a0,0x3
    8000585c:	ee050513          	addi	a0,a0,-288 # 80008738 <syscalls+0x2e8>
    80005860:	ffffb097          	auipc	ra,0xffffb
    80005864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005868:	00003517          	auipc	a0,0x3
    8000586c:	ee850513          	addi	a0,a0,-280 # 80008750 <syscalls+0x300>
    80005870:	ffffb097          	auipc	ra,0xffffb
    80005874:	cce080e7          	jalr	-818(ra) # 8000053e <panic>
    dp->nlink--;
    80005878:	04a4d783          	lhu	a5,74(s1)
    8000587c:	37fd                	addiw	a5,a5,-1
    8000587e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	fc0080e7          	jalr	-64(ra) # 80003844 <iupdate>
    8000588c:	b781                	j	800057cc <sys_unlink+0xe0>
    return -1;
    8000588e:	557d                	li	a0,-1
    80005890:	a005                	j	800058b0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	2dc080e7          	jalr	732(ra) # 80003b70 <iunlockput>
  iunlockput(dp);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	2d2080e7          	jalr	722(ra) # 80003b70 <iunlockput>
  end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	aaa080e7          	jalr	-1366(ra) # 80004350 <end_op>
  return -1;
    800058ae:	557d                	li	a0,-1
}
    800058b0:	70ae                	ld	ra,232(sp)
    800058b2:	740e                	ld	s0,224(sp)
    800058b4:	64ee                	ld	s1,216(sp)
    800058b6:	694e                	ld	s2,208(sp)
    800058b8:	69ae                	ld	s3,200(sp)
    800058ba:	616d                	addi	sp,sp,240
    800058bc:	8082                	ret

00000000800058be <sys_open>:

uint64
sys_open(void)
{
    800058be:	7131                	addi	sp,sp,-192
    800058c0:	fd06                	sd	ra,184(sp)
    800058c2:	f922                	sd	s0,176(sp)
    800058c4:	f526                	sd	s1,168(sp)
    800058c6:	f14a                	sd	s2,160(sp)
    800058c8:	ed4e                	sd	s3,152(sp)
    800058ca:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058cc:	f4c40593          	addi	a1,s0,-180
    800058d0:	4505                	li	a0,1
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	420080e7          	jalr	1056(ra) # 80002cf2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058da:	08000613          	li	a2,128
    800058de:	f5040593          	addi	a1,s0,-176
    800058e2:	4501                	li	a0,0
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	44e080e7          	jalr	1102(ra) # 80002d32 <argstr>
    800058ec:	87aa                	mv	a5,a0
    return -1;
    800058ee:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058f0:	0a07c963          	bltz	a5,800059a2 <sys_open+0xe4>

  begin_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9dc080e7          	jalr	-1572(ra) # 800042d0 <begin_op>

  if(omode & O_CREATE){
    800058fc:	f4c42783          	lw	a5,-180(s0)
    80005900:	2007f793          	andi	a5,a5,512
    80005904:	cfc5                	beqz	a5,800059bc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005906:	4681                	li	a3,0
    80005908:	4601                	li	a2,0
    8000590a:	4589                	li	a1,2
    8000590c:	f5040513          	addi	a0,s0,-176
    80005910:	00000097          	auipc	ra,0x0
    80005914:	968080e7          	jalr	-1688(ra) # 80005278 <create>
    80005918:	84aa                	mv	s1,a0
    if(ip == 0){
    8000591a:	c959                	beqz	a0,800059b0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000591c:	04449703          	lh	a4,68(s1)
    80005920:	478d                	li	a5,3
    80005922:	00f71763          	bne	a4,a5,80005930 <sys_open+0x72>
    80005926:	0464d703          	lhu	a4,70(s1)
    8000592a:	47a5                	li	a5,9
    8000592c:	0ce7ed63          	bltu	a5,a4,80005a06 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	db0080e7          	jalr	-592(ra) # 800046e0 <filealloc>
    80005938:	89aa                	mv	s3,a0
    8000593a:	10050363          	beqz	a0,80005a40 <sys_open+0x182>
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	8f8080e7          	jalr	-1800(ra) # 80005236 <fdalloc>
    80005946:	892a                	mv	s2,a0
    80005948:	0e054763          	bltz	a0,80005a36 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000594c:	04449703          	lh	a4,68(s1)
    80005950:	478d                	li	a5,3
    80005952:	0cf70563          	beq	a4,a5,80005a1c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005956:	4789                	li	a5,2
    80005958:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000595c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005960:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005964:	f4c42783          	lw	a5,-180(s0)
    80005968:	0017c713          	xori	a4,a5,1
    8000596c:	8b05                	andi	a4,a4,1
    8000596e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005972:	0037f713          	andi	a4,a5,3
    80005976:	00e03733          	snez	a4,a4
    8000597a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000597e:	4007f793          	andi	a5,a5,1024
    80005982:	c791                	beqz	a5,8000598e <sys_open+0xd0>
    80005984:	04449703          	lh	a4,68(s1)
    80005988:	4789                	li	a5,2
    8000598a:	0af70063          	beq	a4,a5,80005a2a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	040080e7          	jalr	64(ra) # 800039d0 <iunlock>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	9b8080e7          	jalr	-1608(ra) # 80004350 <end_op>

  return fd;
    800059a0:	854a                	mv	a0,s2
}
    800059a2:	70ea                	ld	ra,184(sp)
    800059a4:	744a                	ld	s0,176(sp)
    800059a6:	74aa                	ld	s1,168(sp)
    800059a8:	790a                	ld	s2,160(sp)
    800059aa:	69ea                	ld	s3,152(sp)
    800059ac:	6129                	addi	sp,sp,192
    800059ae:	8082                	ret
      end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	9a0080e7          	jalr	-1632(ra) # 80004350 <end_op>
      return -1;
    800059b8:	557d                	li	a0,-1
    800059ba:	b7e5                	j	800059a2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059bc:	f5040513          	addi	a0,s0,-176
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	6f4080e7          	jalr	1780(ra) # 800040b4 <namei>
    800059c8:	84aa                	mv	s1,a0
    800059ca:	c905                	beqz	a0,800059fa <sys_open+0x13c>
    ilock(ip);
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	f42080e7          	jalr	-190(ra) # 8000390e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059d4:	04449703          	lh	a4,68(s1)
    800059d8:	4785                	li	a5,1
    800059da:	f4f711e3          	bne	a4,a5,8000591c <sys_open+0x5e>
    800059de:	f4c42783          	lw	a5,-180(s0)
    800059e2:	d7b9                	beqz	a5,80005930 <sys_open+0x72>
      iunlockput(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	18a080e7          	jalr	394(ra) # 80003b70 <iunlockput>
      end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	962080e7          	jalr	-1694(ra) # 80004350 <end_op>
      return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b76d                	j	800059a2 <sys_open+0xe4>
      end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	956080e7          	jalr	-1706(ra) # 80004350 <end_op>
      return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	bf79                	j	800059a2 <sys_open+0xe4>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	168080e7          	jalr	360(ra) # 80003b70 <iunlockput>
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	940080e7          	jalr	-1728(ra) # 80004350 <end_op>
    return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	b761                	j	800059a2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a1c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a20:	04649783          	lh	a5,70(s1)
    80005a24:	02f99223          	sh	a5,36(s3)
    80005a28:	bf25                	j	80005960 <sys_open+0xa2>
    itrunc(ip);
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	ff0080e7          	jalr	-16(ra) # 80003a1c <itrunc>
    80005a34:	bfa9                	j	8000598e <sys_open+0xd0>
      fileclose(f);
    80005a36:	854e                	mv	a0,s3
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	d64080e7          	jalr	-668(ra) # 8000479c <fileclose>
    iunlockput(ip);
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	12e080e7          	jalr	302(ra) # 80003b70 <iunlockput>
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	906080e7          	jalr	-1786(ra) # 80004350 <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
    80005a54:	b7b9                	j	800059a2 <sys_open+0xe4>

0000000080005a56 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a56:	7175                	addi	sp,sp,-144
    80005a58:	e506                	sd	ra,136(sp)
    80005a5a:	e122                	sd	s0,128(sp)
    80005a5c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	872080e7          	jalr	-1934(ra) # 800042d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a66:	08000613          	li	a2,128
    80005a6a:	f7040593          	addi	a1,s0,-144
    80005a6e:	4501                	li	a0,0
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	2c2080e7          	jalr	706(ra) # 80002d32 <argstr>
    80005a78:	02054963          	bltz	a0,80005aaa <sys_mkdir+0x54>
    80005a7c:	4681                	li	a3,0
    80005a7e:	4601                	li	a2,0
    80005a80:	4585                	li	a1,1
    80005a82:	f7040513          	addi	a0,s0,-144
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	7f2080e7          	jalr	2034(ra) # 80005278 <create>
    80005a8e:	cd11                	beqz	a0,80005aaa <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	0e0080e7          	jalr	224(ra) # 80003b70 <iunlockput>
  end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	8b8080e7          	jalr	-1864(ra) # 80004350 <end_op>
  return 0;
    80005aa0:	4501                	li	a0,0
}
    80005aa2:	60aa                	ld	ra,136(sp)
    80005aa4:	640a                	ld	s0,128(sp)
    80005aa6:	6149                	addi	sp,sp,144
    80005aa8:	8082                	ret
    end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	8a6080e7          	jalr	-1882(ra) # 80004350 <end_op>
    return -1;
    80005ab2:	557d                	li	a0,-1
    80005ab4:	b7fd                	j	80005aa2 <sys_mkdir+0x4c>

0000000080005ab6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ab6:	7135                	addi	sp,sp,-160
    80005ab8:	ed06                	sd	ra,152(sp)
    80005aba:	e922                	sd	s0,144(sp)
    80005abc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	812080e7          	jalr	-2030(ra) # 800042d0 <begin_op>
  argint(1, &major);
    80005ac6:	f6c40593          	addi	a1,s0,-148
    80005aca:	4505                	li	a0,1
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	226080e7          	jalr	550(ra) # 80002cf2 <argint>
  argint(2, &minor);
    80005ad4:	f6840593          	addi	a1,s0,-152
    80005ad8:	4509                	li	a0,2
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	218080e7          	jalr	536(ra) # 80002cf2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ae2:	08000613          	li	a2,128
    80005ae6:	f7040593          	addi	a1,s0,-144
    80005aea:	4501                	li	a0,0
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	246080e7          	jalr	582(ra) # 80002d32 <argstr>
    80005af4:	02054b63          	bltz	a0,80005b2a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005af8:	f6841683          	lh	a3,-152(s0)
    80005afc:	f6c41603          	lh	a2,-148(s0)
    80005b00:	458d                	li	a1,3
    80005b02:	f7040513          	addi	a0,s0,-144
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	772080e7          	jalr	1906(ra) # 80005278 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b0e:	cd11                	beqz	a0,80005b2a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	060080e7          	jalr	96(ra) # 80003b70 <iunlockput>
  end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	838080e7          	jalr	-1992(ra) # 80004350 <end_op>
  return 0;
    80005b20:	4501                	li	a0,0
}
    80005b22:	60ea                	ld	ra,152(sp)
    80005b24:	644a                	ld	s0,144(sp)
    80005b26:	610d                	addi	sp,sp,160
    80005b28:	8082                	ret
    end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	826080e7          	jalr	-2010(ra) # 80004350 <end_op>
    return -1;
    80005b32:	557d                	li	a0,-1
    80005b34:	b7fd                	j	80005b22 <sys_mknod+0x6c>

0000000080005b36 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b36:	7135                	addi	sp,sp,-160
    80005b38:	ed06                	sd	ra,152(sp)
    80005b3a:	e922                	sd	s0,144(sp)
    80005b3c:	e526                	sd	s1,136(sp)
    80005b3e:	e14a                	sd	s2,128(sp)
    80005b40:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b42:	ffffc097          	auipc	ra,0xffffc
    80005b46:	e6a080e7          	jalr	-406(ra) # 800019ac <myproc>
    80005b4a:	892a                	mv	s2,a0
  
  begin_op();
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	784080e7          	jalr	1924(ra) # 800042d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b54:	08000613          	li	a2,128
    80005b58:	f6040593          	addi	a1,s0,-160
    80005b5c:	4501                	li	a0,0
    80005b5e:	ffffd097          	auipc	ra,0xffffd
    80005b62:	1d4080e7          	jalr	468(ra) # 80002d32 <argstr>
    80005b66:	04054b63          	bltz	a0,80005bbc <sys_chdir+0x86>
    80005b6a:	f6040513          	addi	a0,s0,-160
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	546080e7          	jalr	1350(ra) # 800040b4 <namei>
    80005b76:	84aa                	mv	s1,a0
    80005b78:	c131                	beqz	a0,80005bbc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	d94080e7          	jalr	-620(ra) # 8000390e <ilock>
  if(ip->type != T_DIR){
    80005b82:	04449703          	lh	a4,68(s1)
    80005b86:	4785                	li	a5,1
    80005b88:	04f71063          	bne	a4,a5,80005bc8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	e42080e7          	jalr	-446(ra) # 800039d0 <iunlock>
  iput(p->cwd);
    80005b96:	15093503          	ld	a0,336(s2)
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	f2e080e7          	jalr	-210(ra) # 80003ac8 <iput>
  end_op();
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	7ae080e7          	jalr	1966(ra) # 80004350 <end_op>
  p->cwd = ip;
    80005baa:	14993823          	sd	s1,336(s2)
  return 0;
    80005bae:	4501                	li	a0,0
}
    80005bb0:	60ea                	ld	ra,152(sp)
    80005bb2:	644a                	ld	s0,144(sp)
    80005bb4:	64aa                	ld	s1,136(sp)
    80005bb6:	690a                	ld	s2,128(sp)
    80005bb8:	610d                	addi	sp,sp,160
    80005bba:	8082                	ret
    end_op();
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	794080e7          	jalr	1940(ra) # 80004350 <end_op>
    return -1;
    80005bc4:	557d                	li	a0,-1
    80005bc6:	b7ed                	j	80005bb0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	fa6080e7          	jalr	-90(ra) # 80003b70 <iunlockput>
    end_op();
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	77e080e7          	jalr	1918(ra) # 80004350 <end_op>
    return -1;
    80005bda:	557d                	li	a0,-1
    80005bdc:	bfd1                	j	80005bb0 <sys_chdir+0x7a>

0000000080005bde <sys_exec>:

uint64
sys_exec(void)
{
    80005bde:	7145                	addi	sp,sp,-464
    80005be0:	e786                	sd	ra,456(sp)
    80005be2:	e3a2                	sd	s0,448(sp)
    80005be4:	ff26                	sd	s1,440(sp)
    80005be6:	fb4a                	sd	s2,432(sp)
    80005be8:	f74e                	sd	s3,424(sp)
    80005bea:	f352                	sd	s4,416(sp)
    80005bec:	ef56                	sd	s5,408(sp)
    80005bee:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bf0:	e3840593          	addi	a1,s0,-456
    80005bf4:	4505                	li	a0,1
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	11c080e7          	jalr	284(ra) # 80002d12 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bfe:	08000613          	li	a2,128
    80005c02:	f4040593          	addi	a1,s0,-192
    80005c06:	4501                	li	a0,0
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	12a080e7          	jalr	298(ra) # 80002d32 <argstr>
    80005c10:	87aa                	mv	a5,a0
    return -1;
    80005c12:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c14:	0c07c263          	bltz	a5,80005cd8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c18:	10000613          	li	a2,256
    80005c1c:	4581                	li	a1,0
    80005c1e:	e4040513          	addi	a0,s0,-448
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	0b0080e7          	jalr	176(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c2a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c2e:	89a6                	mv	s3,s1
    80005c30:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c32:	02000a13          	li	s4,32
    80005c36:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c3a:	00391793          	slli	a5,s2,0x3
    80005c3e:	e3040593          	addi	a1,s0,-464
    80005c42:	e3843503          	ld	a0,-456(s0)
    80005c46:	953e                	add	a0,a0,a5
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	00c080e7          	jalr	12(ra) # 80002c54 <fetchaddr>
    80005c50:	02054a63          	bltz	a0,80005c84 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c54:	e3043783          	ld	a5,-464(s0)
    80005c58:	c3b9                	beqz	a5,80005c9e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	e8c080e7          	jalr	-372(ra) # 80000ae6 <kalloc>
    80005c62:	85aa                	mv	a1,a0
    80005c64:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c68:	cd11                	beqz	a0,80005c84 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c6a:	6605                	lui	a2,0x1
    80005c6c:	e3043503          	ld	a0,-464(s0)
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	036080e7          	jalr	54(ra) # 80002ca6 <fetchstr>
    80005c78:	00054663          	bltz	a0,80005c84 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c7c:	0905                	addi	s2,s2,1
    80005c7e:	09a1                	addi	s3,s3,8
    80005c80:	fb491be3          	bne	s2,s4,80005c36 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c84:	10048913          	addi	s2,s1,256
    80005c88:	6088                	ld	a0,0(s1)
    80005c8a:	c531                	beqz	a0,80005cd6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	d5e080e7          	jalr	-674(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c94:	04a1                	addi	s1,s1,8
    80005c96:	ff2499e3          	bne	s1,s2,80005c88 <sys_exec+0xaa>
  return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	a835                	j	80005cd8 <sys_exec+0xfa>
      argv[i] = 0;
    80005c9e:	0a8e                	slli	s5,s5,0x3
    80005ca0:	fc040793          	addi	a5,s0,-64
    80005ca4:	9abe                	add	s5,s5,a5
    80005ca6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005caa:	e4040593          	addi	a1,s0,-448
    80005cae:	f4040513          	addi	a0,s0,-192
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	164080e7          	jalr	356(ra) # 80004e16 <exec>
    80005cba:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbc:	10048993          	addi	s3,s1,256
    80005cc0:	6088                	ld	a0,0(s1)
    80005cc2:	c901                	beqz	a0,80005cd2 <sys_exec+0xf4>
    kfree(argv[i]);
    80005cc4:	ffffb097          	auipc	ra,0xffffb
    80005cc8:	d26080e7          	jalr	-730(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ccc:	04a1                	addi	s1,s1,8
    80005cce:	ff3499e3          	bne	s1,s3,80005cc0 <sys_exec+0xe2>
  return ret;
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	a011                	j	80005cd8 <sys_exec+0xfa>
  return -1;
    80005cd6:	557d                	li	a0,-1
}
    80005cd8:	60be                	ld	ra,456(sp)
    80005cda:	641e                	ld	s0,448(sp)
    80005cdc:	74fa                	ld	s1,440(sp)
    80005cde:	795a                	ld	s2,432(sp)
    80005ce0:	79ba                	ld	s3,424(sp)
    80005ce2:	7a1a                	ld	s4,416(sp)
    80005ce4:	6afa                	ld	s5,408(sp)
    80005ce6:	6179                	addi	sp,sp,464
    80005ce8:	8082                	ret

0000000080005cea <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cea:	7139                	addi	sp,sp,-64
    80005cec:	fc06                	sd	ra,56(sp)
    80005cee:	f822                	sd	s0,48(sp)
    80005cf0:	f426                	sd	s1,40(sp)
    80005cf2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cf4:	ffffc097          	auipc	ra,0xffffc
    80005cf8:	cb8080e7          	jalr	-840(ra) # 800019ac <myproc>
    80005cfc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cfe:	fd840593          	addi	a1,s0,-40
    80005d02:	4501                	li	a0,0
    80005d04:	ffffd097          	auipc	ra,0xffffd
    80005d08:	00e080e7          	jalr	14(ra) # 80002d12 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d0c:	fc840593          	addi	a1,s0,-56
    80005d10:	fd040513          	addi	a0,s0,-48
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	db8080e7          	jalr	-584(ra) # 80004acc <pipealloc>
    return -1;
    80005d1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d1e:	0c054463          	bltz	a0,80005de6 <sys_pipe+0xfc>
  fd0 = -1;
    80005d22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d26:	fd043503          	ld	a0,-48(s0)
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	50c080e7          	jalr	1292(ra) # 80005236 <fdalloc>
    80005d32:	fca42223          	sw	a0,-60(s0)
    80005d36:	08054b63          	bltz	a0,80005dcc <sys_pipe+0xe2>
    80005d3a:	fc843503          	ld	a0,-56(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	4f8080e7          	jalr	1272(ra) # 80005236 <fdalloc>
    80005d46:	fca42023          	sw	a0,-64(s0)
    80005d4a:	06054863          	bltz	a0,80005dba <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d4e:	4691                	li	a3,4
    80005d50:	fc440613          	addi	a2,s0,-60
    80005d54:	fd843583          	ld	a1,-40(s0)
    80005d58:	68a8                	ld	a0,80(s1)
    80005d5a:	ffffc097          	auipc	ra,0xffffc
    80005d5e:	90e080e7          	jalr	-1778(ra) # 80001668 <copyout>
    80005d62:	02054063          	bltz	a0,80005d82 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d66:	4691                	li	a3,4
    80005d68:	fc040613          	addi	a2,s0,-64
    80005d6c:	fd843583          	ld	a1,-40(s0)
    80005d70:	0591                	addi	a1,a1,4
    80005d72:	68a8                	ld	a0,80(s1)
    80005d74:	ffffc097          	auipc	ra,0xffffc
    80005d78:	8f4080e7          	jalr	-1804(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d7e:	06055463          	bgez	a0,80005de6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d82:	fc442783          	lw	a5,-60(s0)
    80005d86:	07e9                	addi	a5,a5,26
    80005d88:	078e                	slli	a5,a5,0x3
    80005d8a:	97a6                	add	a5,a5,s1
    80005d8c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d90:	fc042503          	lw	a0,-64(s0)
    80005d94:	0569                	addi	a0,a0,26
    80005d96:	050e                	slli	a0,a0,0x3
    80005d98:	94aa                	add	s1,s1,a0
    80005d9a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d9e:	fd043503          	ld	a0,-48(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	9fa080e7          	jalr	-1542(ra) # 8000479c <fileclose>
    fileclose(wf);
    80005daa:	fc843503          	ld	a0,-56(s0)
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	9ee080e7          	jalr	-1554(ra) # 8000479c <fileclose>
    return -1;
    80005db6:	57fd                	li	a5,-1
    80005db8:	a03d                	j	80005de6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005dba:	fc442783          	lw	a5,-60(s0)
    80005dbe:	0007c763          	bltz	a5,80005dcc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dc2:	07e9                	addi	a5,a5,26
    80005dc4:	078e                	slli	a5,a5,0x3
    80005dc6:	94be                	add	s1,s1,a5
    80005dc8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dcc:	fd043503          	ld	a0,-48(s0)
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	9cc080e7          	jalr	-1588(ra) # 8000479c <fileclose>
    fileclose(wf);
    80005dd8:	fc843503          	ld	a0,-56(s0)
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	9c0080e7          	jalr	-1600(ra) # 8000479c <fileclose>
    return -1;
    80005de4:	57fd                	li	a5,-1
}
    80005de6:	853e                	mv	a0,a5
    80005de8:	70e2                	ld	ra,56(sp)
    80005dea:	7442                	ld	s0,48(sp)
    80005dec:	74a2                	ld	s1,40(sp)
    80005dee:	6121                	addi	sp,sp,64
    80005df0:	8082                	ret

0000000080005df2 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80005df2:	1101                	addi	sp,sp,-32
    80005df4:	ec06                	sd	ra,24(sp)
    80005df6:	e822                	sd	s0,16(sp)
    80005df8:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    80005dfa:	fe440593          	addi	a1,s0,-28
    80005dfe:	4501                	li	a0,0
    80005e00:	ffffd097          	auipc	ra,0xffffd
    80005e04:	ef2080e7          	jalr	-270(ra) # 80002cf2 <argint>
  argaddr(1, &addr);
    80005e08:	fe840593          	addi	a1,s0,-24
    80005e0c:	4505                	li	a0,1
    80005e0e:	ffffd097          	auipc	ra,0xffffd
    80005e12:	f04080e7          	jalr	-252(ra) # 80002d12 <argaddr>

  myproc()->ticks = ticks;
    80005e16:	ffffc097          	auipc	ra,0xffffc
    80005e1a:	b96080e7          	jalr	-1130(ra) # 800019ac <myproc>
    80005e1e:	fe442783          	lw	a5,-28(s0)
    80005e22:	18f52023          	sw	a5,384(a0)
  myproc()->handler = addr;
    80005e26:	ffffc097          	auipc	ra,0xffffc
    80005e2a:	b86080e7          	jalr	-1146(ra) # 800019ac <myproc>
    80005e2e:	fe843783          	ld	a5,-24(s0)
    80005e32:	16f53c23          	sd	a5,376(a0)

  return 0;
}
    80005e36:	4501                	li	a0,0
    80005e38:	60e2                	ld	ra,24(sp)
    80005e3a:	6442                	ld	s0,16(sp)
    80005e3c:	6105                	addi	sp,sp,32
    80005e3e:	8082                	ret

0000000080005e40 <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80005e40:	1101                	addi	sp,sp,-32
    80005e42:	ec06                	sd	ra,24(sp)
    80005e44:	e822                	sd	s0,16(sp)
    80005e46:	e426                	sd	s1,8(sp)
    80005e48:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80005e4a:	ffffc097          	auipc	ra,0xffffc
    80005e4e:	b62080e7          	jalr	-1182(ra) # 800019ac <myproc>
    80005e52:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    80005e54:	6605                	lui	a2,0x1
    80005e56:	18853583          	ld	a1,392(a0)
    80005e5a:	6d28                	ld	a0,88(a0)
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	ed2080e7          	jalr	-302(ra) # 80000d2e <memmove>

  kfree(p->alarm_tf);
    80005e64:	1884b503          	ld	a0,392(s1)
    80005e68:	ffffb097          	auipc	ra,0xffffb
    80005e6c:	b82080e7          	jalr	-1150(ra) # 800009ea <kfree>
  p->alarm_tf = 0;
    80005e70:	1804b423          	sd	zero,392(s1)
  p->alarm_on = 0;
    80005e74:	1804a823          	sw	zero,400(s1)
  p->cur_ticks = 0;
    80005e78:	1804a223          	sw	zero,388(s1)
  return p->trapframe->a0;
    80005e7c:	6cbc                	ld	a5,88(s1)
}
    80005e7e:	7ba8                	ld	a0,112(a5)
    80005e80:	60e2                	ld	ra,24(sp)
    80005e82:	6442                	ld	s0,16(sp)
    80005e84:	64a2                	ld	s1,8(sp)
    80005e86:	6105                	addi	sp,sp,32
    80005e88:	8082                	ret
    80005e8a:	0000                	unimp
    80005e8c:	0000                	unimp
	...

0000000080005e90 <kernelvec>:
    80005e90:	7111                	addi	sp,sp,-256
    80005e92:	e006                	sd	ra,0(sp)
    80005e94:	e40a                	sd	sp,8(sp)
    80005e96:	e80e                	sd	gp,16(sp)
    80005e98:	ec12                	sd	tp,24(sp)
    80005e9a:	f016                	sd	t0,32(sp)
    80005e9c:	f41a                	sd	t1,40(sp)
    80005e9e:	f81e                	sd	t2,48(sp)
    80005ea0:	fc22                	sd	s0,56(sp)
    80005ea2:	e0a6                	sd	s1,64(sp)
    80005ea4:	e4aa                	sd	a0,72(sp)
    80005ea6:	e8ae                	sd	a1,80(sp)
    80005ea8:	ecb2                	sd	a2,88(sp)
    80005eaa:	f0b6                	sd	a3,96(sp)
    80005eac:	f4ba                	sd	a4,104(sp)
    80005eae:	f8be                	sd	a5,112(sp)
    80005eb0:	fcc2                	sd	a6,120(sp)
    80005eb2:	e146                	sd	a7,128(sp)
    80005eb4:	e54a                	sd	s2,136(sp)
    80005eb6:	e94e                	sd	s3,144(sp)
    80005eb8:	ed52                	sd	s4,152(sp)
    80005eba:	f156                	sd	s5,160(sp)
    80005ebc:	f55a                	sd	s6,168(sp)
    80005ebe:	f95e                	sd	s7,176(sp)
    80005ec0:	fd62                	sd	s8,184(sp)
    80005ec2:	e1e6                	sd	s9,192(sp)
    80005ec4:	e5ea                	sd	s10,200(sp)
    80005ec6:	e9ee                	sd	s11,208(sp)
    80005ec8:	edf2                	sd	t3,216(sp)
    80005eca:	f1f6                	sd	t4,224(sp)
    80005ecc:	f5fa                	sd	t5,232(sp)
    80005ece:	f9fe                	sd	t6,240(sp)
    80005ed0:	c7bfc0ef          	jal	ra,80002b4a <kerneltrap>
    80005ed4:	6082                	ld	ra,0(sp)
    80005ed6:	6122                	ld	sp,8(sp)
    80005ed8:	61c2                	ld	gp,16(sp)
    80005eda:	7282                	ld	t0,32(sp)
    80005edc:	7322                	ld	t1,40(sp)
    80005ede:	73c2                	ld	t2,48(sp)
    80005ee0:	7462                	ld	s0,56(sp)
    80005ee2:	6486                	ld	s1,64(sp)
    80005ee4:	6526                	ld	a0,72(sp)
    80005ee6:	65c6                	ld	a1,80(sp)
    80005ee8:	6666                	ld	a2,88(sp)
    80005eea:	7686                	ld	a3,96(sp)
    80005eec:	7726                	ld	a4,104(sp)
    80005eee:	77c6                	ld	a5,112(sp)
    80005ef0:	7866                	ld	a6,120(sp)
    80005ef2:	688a                	ld	a7,128(sp)
    80005ef4:	692a                	ld	s2,136(sp)
    80005ef6:	69ca                	ld	s3,144(sp)
    80005ef8:	6a6a                	ld	s4,152(sp)
    80005efa:	7a8a                	ld	s5,160(sp)
    80005efc:	7b2a                	ld	s6,168(sp)
    80005efe:	7bca                	ld	s7,176(sp)
    80005f00:	7c6a                	ld	s8,184(sp)
    80005f02:	6c8e                	ld	s9,192(sp)
    80005f04:	6d2e                	ld	s10,200(sp)
    80005f06:	6dce                	ld	s11,208(sp)
    80005f08:	6e6e                	ld	t3,216(sp)
    80005f0a:	7e8e                	ld	t4,224(sp)
    80005f0c:	7f2e                	ld	t5,232(sp)
    80005f0e:	7fce                	ld	t6,240(sp)
    80005f10:	6111                	addi	sp,sp,256
    80005f12:	10200073          	sret
    80005f16:	00000013          	nop
    80005f1a:	00000013          	nop
    80005f1e:	0001                	nop

0000000080005f20 <timervec>:
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	e10c                	sd	a1,0(a0)
    80005f26:	e510                	sd	a2,8(a0)
    80005f28:	e914                	sd	a3,16(a0)
    80005f2a:	6d0c                	ld	a1,24(a0)
    80005f2c:	7110                	ld	a2,32(a0)
    80005f2e:	6194                	ld	a3,0(a1)
    80005f30:	96b2                	add	a3,a3,a2
    80005f32:	e194                	sd	a3,0(a1)
    80005f34:	4589                	li	a1,2
    80005f36:	14459073          	csrw	sip,a1
    80005f3a:	6914                	ld	a3,16(a0)
    80005f3c:	6510                	ld	a2,8(a0)
    80005f3e:	610c                	ld	a1,0(a0)
    80005f40:	34051573          	csrrw	a0,mscratch,a0
    80005f44:	30200073          	mret
	...

0000000080005f4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f4a:	1141                	addi	sp,sp,-16
    80005f4c:	e422                	sd	s0,8(sp)
    80005f4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f50:	0c0007b7          	lui	a5,0xc000
    80005f54:	4705                	li	a4,1
    80005f56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f58:	c3d8                	sw	a4,4(a5)
}
    80005f5a:	6422                	ld	s0,8(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plicinithart>:

void
plicinithart(void)
{
    80005f60:	1141                	addi	sp,sp,-16
    80005f62:	e406                	sd	ra,8(sp)
    80005f64:	e022                	sd	s0,0(sp)
    80005f66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	a18080e7          	jalr	-1512(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f70:	0085171b          	slliw	a4,a0,0x8
    80005f74:	0c0027b7          	lui	a5,0xc002
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	40200713          	li	a4,1026
    80005f7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f82:	00d5151b          	slliw	a0,a0,0xd
    80005f86:	0c2017b7          	lui	a5,0xc201
    80005f8a:	953e                	add	a0,a0,a5
    80005f8c:	00052023          	sw	zero,0(a0)
}
    80005f90:	60a2                	ld	ra,8(sp)
    80005f92:	6402                	ld	s0,0(sp)
    80005f94:	0141                	addi	sp,sp,16
    80005f96:	8082                	ret

0000000080005f98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f98:	1141                	addi	sp,sp,-16
    80005f9a:	e406                	sd	ra,8(sp)
    80005f9c:	e022                	sd	s0,0(sp)
    80005f9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	9e0080e7          	jalr	-1568(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fa8:	00d5179b          	slliw	a5,a0,0xd
    80005fac:	0c201537          	lui	a0,0xc201
    80005fb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fb2:	4148                	lw	a0,4(a0)
    80005fb4:	60a2                	ld	ra,8(sp)
    80005fb6:	6402                	ld	s0,0(sp)
    80005fb8:	0141                	addi	sp,sp,16
    80005fba:	8082                	ret

0000000080005fbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbc:	1101                	addi	sp,sp,-32
    80005fbe:	ec06                	sd	ra,24(sp)
    80005fc0:	e822                	sd	s0,16(sp)
    80005fc2:	e426                	sd	s1,8(sp)
    80005fc4:	1000                	addi	s0,sp,32
    80005fc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	9b8080e7          	jalr	-1608(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd0:	00d5151b          	slliw	a0,a0,0xd
    80005fd4:	0c2017b7          	lui	a5,0xc201
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	c3c4                	sw	s1,4(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret

0000000080005fe6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fe6:	1141                	addi	sp,sp,-16
    80005fe8:	e406                	sd	ra,8(sp)
    80005fea:	e022                	sd	s0,0(sp)
    80005fec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fee:	479d                	li	a5,7
    80005ff0:	04a7cc63          	blt	a5,a0,80006048 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ff4:	0001d797          	auipc	a5,0x1d
    80005ff8:	82c78793          	addi	a5,a5,-2004 # 80022820 <disk>
    80005ffc:	97aa                	add	a5,a5,a0
    80005ffe:	0187c783          	lbu	a5,24(a5)
    80006002:	ebb9                	bnez	a5,80006058 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006004:	00451613          	slli	a2,a0,0x4
    80006008:	0001d797          	auipc	a5,0x1d
    8000600c:	81878793          	addi	a5,a5,-2024 # 80022820 <disk>
    80006010:	6394                	ld	a3,0(a5)
    80006012:	96b2                	add	a3,a3,a2
    80006014:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006018:	6398                	ld	a4,0(a5)
    8000601a:	9732                	add	a4,a4,a2
    8000601c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006020:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006024:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006028:	953e                	add	a0,a0,a5
    8000602a:	4785                	li	a5,1
    8000602c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006030:	0001d517          	auipc	a0,0x1d
    80006034:	80850513          	addi	a0,a0,-2040 # 80022838 <disk+0x18>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	0ec080e7          	jalr	236(ra) # 80002124 <wakeup>
}
    80006040:	60a2                	ld	ra,8(sp)
    80006042:	6402                	ld	s0,0(sp)
    80006044:	0141                	addi	sp,sp,16
    80006046:	8082                	ret
    panic("free_desc 1");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	71850513          	addi	a0,a0,1816 # 80008760 <syscalls+0x310>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	71850513          	addi	a0,a0,1816 # 80008770 <syscalls+0x320>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>

0000000080006068 <virtio_disk_init>:
{
    80006068:	1101                	addi	sp,sp,-32
    8000606a:	ec06                	sd	ra,24(sp)
    8000606c:	e822                	sd	s0,16(sp)
    8000606e:	e426                	sd	s1,8(sp)
    80006070:	e04a                	sd	s2,0(sp)
    80006072:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006074:	00002597          	auipc	a1,0x2
    80006078:	70c58593          	addi	a1,a1,1804 # 80008780 <syscalls+0x330>
    8000607c:	0001d517          	auipc	a0,0x1d
    80006080:	8cc50513          	addi	a0,a0,-1844 # 80022948 <disk+0x128>
    80006084:	ffffb097          	auipc	ra,0xffffb
    80006088:	ac2080e7          	jalr	-1342(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	4398                	lw	a4,0(a5)
    80006092:	2701                	sext.w	a4,a4
    80006094:	747277b7          	lui	a5,0x74727
    80006098:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000609c:	14f71c63          	bne	a4,a5,800061f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060a0:	100017b7          	lui	a5,0x10001
    800060a4:	43dc                	lw	a5,4(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a8:	4709                	li	a4,2
    800060aa:	14e79563          	bne	a5,a4,800061f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	479c                	lw	a5,8(a5)
    800060b4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060b6:	12e79f63          	bne	a5,a4,800061f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ba:	100017b7          	lui	a5,0x10001
    800060be:	47d8                	lw	a4,12(a5)
    800060c0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060c2:	554d47b7          	lui	a5,0x554d4
    800060c6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060ca:	12f71563          	bne	a4,a5,800061f4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	100017b7          	lui	a5,0x10001
    800060d2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d6:	4705                	li	a4,1
    800060d8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060da:	470d                	li	a4,3
    800060dc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060de:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060e0:	c7ffe737          	lui	a4,0xc7ffe
    800060e4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbdff>
    800060e8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060ea:	2701                	sext.w	a4,a4
    800060ec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ee:	472d                	li	a4,11
    800060f0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060f2:	5bbc                	lw	a5,112(a5)
    800060f4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060f8:	8ba1                	andi	a5,a5,8
    800060fa:	10078563          	beqz	a5,80006204 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006106:	43fc                	lw	a5,68(a5)
    80006108:	2781                	sext.w	a5,a5
    8000610a:	10079563          	bnez	a5,80006214 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	5bdc                	lw	a5,52(a5)
    80006114:	2781                	sext.w	a5,a5
  if(max == 0)
    80006116:	10078763          	beqz	a5,80006224 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000611a:	471d                	li	a4,7
    8000611c:	10f77c63          	bgeu	a4,a5,80006234 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	9c6080e7          	jalr	-1594(ra) # 80000ae6 <kalloc>
    80006128:	0001c497          	auipc	s1,0x1c
    8000612c:	6f848493          	addi	s1,s1,1784 # 80022820 <disk>
    80006130:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	9b4080e7          	jalr	-1612(ra) # 80000ae6 <kalloc>
    8000613a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000613c:	ffffb097          	auipc	ra,0xffffb
    80006140:	9aa080e7          	jalr	-1622(ra) # 80000ae6 <kalloc>
    80006144:	87aa                	mv	a5,a0
    80006146:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006148:	6088                	ld	a0,0(s1)
    8000614a:	cd6d                	beqz	a0,80006244 <virtio_disk_init+0x1dc>
    8000614c:	0001c717          	auipc	a4,0x1c
    80006150:	6dc73703          	ld	a4,1756(a4) # 80022828 <disk+0x8>
    80006154:	cb65                	beqz	a4,80006244 <virtio_disk_init+0x1dc>
    80006156:	c7fd                	beqz	a5,80006244 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006158:	6605                	lui	a2,0x1
    8000615a:	4581                	li	a1,0
    8000615c:	ffffb097          	auipc	ra,0xffffb
    80006160:	b76080e7          	jalr	-1162(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006164:	0001c497          	auipc	s1,0x1c
    80006168:	6bc48493          	addi	s1,s1,1724 # 80022820 <disk>
    8000616c:	6605                	lui	a2,0x1
    8000616e:	4581                	li	a1,0
    80006170:	6488                	ld	a0,8(s1)
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	b60080e7          	jalr	-1184(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000617a:	6605                	lui	a2,0x1
    8000617c:	4581                	li	a1,0
    8000617e:	6888                	ld	a0,16(s1)
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	b52080e7          	jalr	-1198(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006188:	100017b7          	lui	a5,0x10001
    8000618c:	4721                	li	a4,8
    8000618e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006190:	4098                	lw	a4,0(s1)
    80006192:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006196:	40d8                	lw	a4,4(s1)
    80006198:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000619c:	6498                	ld	a4,8(s1)
    8000619e:	0007069b          	sext.w	a3,a4
    800061a2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061a6:	9701                	srai	a4,a4,0x20
    800061a8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061ac:	6898                	ld	a4,16(s1)
    800061ae:	0007069b          	sext.w	a3,a4
    800061b2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061b6:	9701                	srai	a4,a4,0x20
    800061b8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061bc:	4705                	li	a4,1
    800061be:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061c0:	00e48c23          	sb	a4,24(s1)
    800061c4:	00e48ca3          	sb	a4,25(s1)
    800061c8:	00e48d23          	sb	a4,26(s1)
    800061cc:	00e48da3          	sb	a4,27(s1)
    800061d0:	00e48e23          	sb	a4,28(s1)
    800061d4:	00e48ea3          	sb	a4,29(s1)
    800061d8:	00e48f23          	sb	a4,30(s1)
    800061dc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061e0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e4:	0727a823          	sw	s2,112(a5)
}
    800061e8:	60e2                	ld	ra,24(sp)
    800061ea:	6442                	ld	s0,16(sp)
    800061ec:	64a2                	ld	s1,8(sp)
    800061ee:	6902                	ld	s2,0(sp)
    800061f0:	6105                	addi	sp,sp,32
    800061f2:	8082                	ret
    panic("could not find virtio disk");
    800061f4:	00002517          	auipc	a0,0x2
    800061f8:	59c50513          	addi	a0,a0,1436 # 80008790 <syscalls+0x340>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	342080e7          	jalr	834(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006204:	00002517          	auipc	a0,0x2
    80006208:	5ac50513          	addi	a0,a0,1452 # 800087b0 <syscalls+0x360>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	332080e7          	jalr	818(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006214:	00002517          	auipc	a0,0x2
    80006218:	5bc50513          	addi	a0,a0,1468 # 800087d0 <syscalls+0x380>
    8000621c:	ffffa097          	auipc	ra,0xffffa
    80006220:	322080e7          	jalr	802(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006224:	00002517          	auipc	a0,0x2
    80006228:	5cc50513          	addi	a0,a0,1484 # 800087f0 <syscalls+0x3a0>
    8000622c:	ffffa097          	auipc	ra,0xffffa
    80006230:	312080e7          	jalr	786(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006234:	00002517          	auipc	a0,0x2
    80006238:	5dc50513          	addi	a0,a0,1500 # 80008810 <syscalls+0x3c0>
    8000623c:	ffffa097          	auipc	ra,0xffffa
    80006240:	302080e7          	jalr	770(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006244:	00002517          	auipc	a0,0x2
    80006248:	5ec50513          	addi	a0,a0,1516 # 80008830 <syscalls+0x3e0>
    8000624c:	ffffa097          	auipc	ra,0xffffa
    80006250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>

0000000080006254 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006254:	7119                	addi	sp,sp,-128
    80006256:	fc86                	sd	ra,120(sp)
    80006258:	f8a2                	sd	s0,112(sp)
    8000625a:	f4a6                	sd	s1,104(sp)
    8000625c:	f0ca                	sd	s2,96(sp)
    8000625e:	ecce                	sd	s3,88(sp)
    80006260:	e8d2                	sd	s4,80(sp)
    80006262:	e4d6                	sd	s5,72(sp)
    80006264:	e0da                	sd	s6,64(sp)
    80006266:	fc5e                	sd	s7,56(sp)
    80006268:	f862                	sd	s8,48(sp)
    8000626a:	f466                	sd	s9,40(sp)
    8000626c:	f06a                	sd	s10,32(sp)
    8000626e:	ec6e                	sd	s11,24(sp)
    80006270:	0100                	addi	s0,sp,128
    80006272:	8aaa                	mv	s5,a0
    80006274:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006276:	00c52d03          	lw	s10,12(a0)
    8000627a:	001d1d1b          	slliw	s10,s10,0x1
    8000627e:	1d02                	slli	s10,s10,0x20
    80006280:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006284:	0001c517          	auipc	a0,0x1c
    80006288:	6c450513          	addi	a0,a0,1732 # 80022948 <disk+0x128>
    8000628c:	ffffb097          	auipc	ra,0xffffb
    80006290:	94a080e7          	jalr	-1718(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006294:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006296:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006298:	0001cb97          	auipc	s7,0x1c
    8000629c:	588b8b93          	addi	s7,s7,1416 # 80022820 <disk>
  for(int i = 0; i < 3; i++){
    800062a0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a2:	0001cc97          	auipc	s9,0x1c
    800062a6:	6a6c8c93          	addi	s9,s9,1702 # 80022948 <disk+0x128>
    800062aa:	a08d                	j	8000630c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062ac:	00fb8733          	add	a4,s7,a5
    800062b0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062b4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062b6:	0207c563          	bltz	a5,800062e0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062ba:	2905                	addiw	s2,s2,1
    800062bc:	0611                	addi	a2,a2,4
    800062be:	05690c63          	beq	s2,s6,80006316 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800062c2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062c4:	0001c717          	auipc	a4,0x1c
    800062c8:	55c70713          	addi	a4,a4,1372 # 80022820 <disk>
    800062cc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062ce:	01874683          	lbu	a3,24(a4)
    800062d2:	fee9                	bnez	a3,800062ac <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062d4:	2785                	addiw	a5,a5,1
    800062d6:	0705                	addi	a4,a4,1
    800062d8:	fe979be3          	bne	a5,s1,800062ce <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062dc:	57fd                	li	a5,-1
    800062de:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062e0:	01205d63          	blez	s2,800062fa <virtio_disk_rw+0xa6>
    800062e4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062e6:	000a2503          	lw	a0,0(s4)
    800062ea:	00000097          	auipc	ra,0x0
    800062ee:	cfc080e7          	jalr	-772(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    800062f2:	2d85                	addiw	s11,s11,1
    800062f4:	0a11                	addi	s4,s4,4
    800062f6:	ffb918e3          	bne	s2,s11,800062e6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062fa:	85e6                	mv	a1,s9
    800062fc:	0001c517          	auipc	a0,0x1c
    80006300:	53c50513          	addi	a0,a0,1340 # 80022838 <disk+0x18>
    80006304:	ffffc097          	auipc	ra,0xffffc
    80006308:	dbc080e7          	jalr	-580(ra) # 800020c0 <sleep>
  for(int i = 0; i < 3; i++){
    8000630c:	f8040a13          	addi	s4,s0,-128
{
    80006310:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006312:	894e                	mv	s2,s3
    80006314:	b77d                	j	800062c2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006316:	f8042583          	lw	a1,-128(s0)
    8000631a:	00a58793          	addi	a5,a1,10
    8000631e:	0792                	slli	a5,a5,0x4

  if(write)
    80006320:	0001c617          	auipc	a2,0x1c
    80006324:	50060613          	addi	a2,a2,1280 # 80022820 <disk>
    80006328:	00f60733          	add	a4,a2,a5
    8000632c:	018036b3          	snez	a3,s8
    80006330:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006332:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006336:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000633a:	f6078693          	addi	a3,a5,-160
    8000633e:	6218                	ld	a4,0(a2)
    80006340:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006342:	00878513          	addi	a0,a5,8
    80006346:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006348:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000634a:	6208                	ld	a0,0(a2)
    8000634c:	96aa                	add	a3,a3,a0
    8000634e:	4741                	li	a4,16
    80006350:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006352:	4705                	li	a4,1
    80006354:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006358:	f8442703          	lw	a4,-124(s0)
    8000635c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006360:	0712                	slli	a4,a4,0x4
    80006362:	953a                	add	a0,a0,a4
    80006364:	058a8693          	addi	a3,s5,88
    80006368:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000636a:	6208                	ld	a0,0(a2)
    8000636c:	972a                	add	a4,a4,a0
    8000636e:	40000693          	li	a3,1024
    80006372:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006374:	001c3c13          	seqz	s8,s8
    80006378:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000637a:	001c6c13          	ori	s8,s8,1
    8000637e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006382:	f8842603          	lw	a2,-120(s0)
    80006386:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000638a:	0001c697          	auipc	a3,0x1c
    8000638e:	49668693          	addi	a3,a3,1174 # 80022820 <disk>
    80006392:	00258713          	addi	a4,a1,2
    80006396:	0712                	slli	a4,a4,0x4
    80006398:	9736                	add	a4,a4,a3
    8000639a:	587d                	li	a6,-1
    8000639c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063a0:	0612                	slli	a2,a2,0x4
    800063a2:	9532                	add	a0,a0,a2
    800063a4:	f9078793          	addi	a5,a5,-112
    800063a8:	97b6                	add	a5,a5,a3
    800063aa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800063ac:	629c                	ld	a5,0(a3)
    800063ae:	97b2                	add	a5,a5,a2
    800063b0:	4605                	li	a2,1
    800063b2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063b4:	4509                	li	a0,2
    800063b6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800063ba:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063be:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800063c2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063c6:	6698                	ld	a4,8(a3)
    800063c8:	00275783          	lhu	a5,2(a4)
    800063cc:	8b9d                	andi	a5,a5,7
    800063ce:	0786                	slli	a5,a5,0x1
    800063d0:	97ba                	add	a5,a5,a4
    800063d2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800063d6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063da:	6698                	ld	a4,8(a3)
    800063dc:	00275783          	lhu	a5,2(a4)
    800063e0:	2785                	addiw	a5,a5,1
    800063e2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063e6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063ea:	100017b7          	lui	a5,0x10001
    800063ee:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063f2:	004aa783          	lw	a5,4(s5)
    800063f6:	02c79163          	bne	a5,a2,80006418 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800063fa:	0001c917          	auipc	s2,0x1c
    800063fe:	54e90913          	addi	s2,s2,1358 # 80022948 <disk+0x128>
  while(b->disk == 1) {
    80006402:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006404:	85ca                	mv	a1,s2
    80006406:	8556                	mv	a0,s5
    80006408:	ffffc097          	auipc	ra,0xffffc
    8000640c:	cb8080e7          	jalr	-840(ra) # 800020c0 <sleep>
  while(b->disk == 1) {
    80006410:	004aa783          	lw	a5,4(s5)
    80006414:	fe9788e3          	beq	a5,s1,80006404 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006418:	f8042903          	lw	s2,-128(s0)
    8000641c:	00290793          	addi	a5,s2,2
    80006420:	00479713          	slli	a4,a5,0x4
    80006424:	0001c797          	auipc	a5,0x1c
    80006428:	3fc78793          	addi	a5,a5,1020 # 80022820 <disk>
    8000642c:	97ba                	add	a5,a5,a4
    8000642e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006432:	0001c997          	auipc	s3,0x1c
    80006436:	3ee98993          	addi	s3,s3,1006 # 80022820 <disk>
    8000643a:	00491713          	slli	a4,s2,0x4
    8000643e:	0009b783          	ld	a5,0(s3)
    80006442:	97ba                	add	a5,a5,a4
    80006444:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006448:	854a                	mv	a0,s2
    8000644a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000644e:	00000097          	auipc	ra,0x0
    80006452:	b98080e7          	jalr	-1128(ra) # 80005fe6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006456:	8885                	andi	s1,s1,1
    80006458:	f0ed                	bnez	s1,8000643a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000645a:	0001c517          	auipc	a0,0x1c
    8000645e:	4ee50513          	addi	a0,a0,1262 # 80022948 <disk+0x128>
    80006462:	ffffb097          	auipc	ra,0xffffb
    80006466:	828080e7          	jalr	-2008(ra) # 80000c8a <release>
}
    8000646a:	70e6                	ld	ra,120(sp)
    8000646c:	7446                	ld	s0,112(sp)
    8000646e:	74a6                	ld	s1,104(sp)
    80006470:	7906                	ld	s2,96(sp)
    80006472:	69e6                	ld	s3,88(sp)
    80006474:	6a46                	ld	s4,80(sp)
    80006476:	6aa6                	ld	s5,72(sp)
    80006478:	6b06                	ld	s6,64(sp)
    8000647a:	7be2                	ld	s7,56(sp)
    8000647c:	7c42                	ld	s8,48(sp)
    8000647e:	7ca2                	ld	s9,40(sp)
    80006480:	7d02                	ld	s10,32(sp)
    80006482:	6de2                	ld	s11,24(sp)
    80006484:	6109                	addi	sp,sp,128
    80006486:	8082                	ret

0000000080006488 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006488:	1101                	addi	sp,sp,-32
    8000648a:	ec06                	sd	ra,24(sp)
    8000648c:	e822                	sd	s0,16(sp)
    8000648e:	e426                	sd	s1,8(sp)
    80006490:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006492:	0001c497          	auipc	s1,0x1c
    80006496:	38e48493          	addi	s1,s1,910 # 80022820 <disk>
    8000649a:	0001c517          	auipc	a0,0x1c
    8000649e:	4ae50513          	addi	a0,a0,1198 # 80022948 <disk+0x128>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	734080e7          	jalr	1844(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064aa:	10001737          	lui	a4,0x10001
    800064ae:	533c                	lw	a5,96(a4)
    800064b0:	8b8d                	andi	a5,a5,3
    800064b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b8:	689c                	ld	a5,16(s1)
    800064ba:	0204d703          	lhu	a4,32(s1)
    800064be:	0027d783          	lhu	a5,2(a5)
    800064c2:	04f70863          	beq	a4,a5,80006512 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064c6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064ca:	6898                	ld	a4,16(s1)
    800064cc:	0204d783          	lhu	a5,32(s1)
    800064d0:	8b9d                	andi	a5,a5,7
    800064d2:	078e                	slli	a5,a5,0x3
    800064d4:	97ba                	add	a5,a5,a4
    800064d6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064d8:	00278713          	addi	a4,a5,2
    800064dc:	0712                	slli	a4,a4,0x4
    800064de:	9726                	add	a4,a4,s1
    800064e0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064e4:	e721                	bnez	a4,8000652c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064e6:	0789                	addi	a5,a5,2
    800064e8:	0792                	slli	a5,a5,0x4
    800064ea:	97a6                	add	a5,a5,s1
    800064ec:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064ee:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064f2:	ffffc097          	auipc	ra,0xffffc
    800064f6:	c32080e7          	jalr	-974(ra) # 80002124 <wakeup>

    disk.used_idx += 1;
    800064fa:	0204d783          	lhu	a5,32(s1)
    800064fe:	2785                	addiw	a5,a5,1
    80006500:	17c2                	slli	a5,a5,0x30
    80006502:	93c1                	srli	a5,a5,0x30
    80006504:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006508:	6898                	ld	a4,16(s1)
    8000650a:	00275703          	lhu	a4,2(a4)
    8000650e:	faf71ce3          	bne	a4,a5,800064c6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006512:	0001c517          	auipc	a0,0x1c
    80006516:	43650513          	addi	a0,a0,1078 # 80022948 <disk+0x128>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	770080e7          	jalr	1904(ra) # 80000c8a <release>
}
    80006522:	60e2                	ld	ra,24(sp)
    80006524:	6442                	ld	s0,16(sp)
    80006526:	64a2                	ld	s1,8(sp)
    80006528:	6105                	addi	sp,sp,32
    8000652a:	8082                	ret
      panic("virtio_disk_intr status");
    8000652c:	00002517          	auipc	a0,0x2
    80006530:	31c50513          	addi	a0,a0,796 # 80008848 <syscalls+0x3f8>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	00a080e7          	jalr	10(ra) # 8000053e <panic>
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
