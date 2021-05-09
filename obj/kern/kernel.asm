
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <start_of_kernel-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start_of_kernel
start_of_kernel:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4                   	.byte 0xe4

f010000c <start_of_kernel>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 10 12 00 	lgdtl  0x121018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Leave a few words on the stack for the user trap frame
	movl	$(ptr_stack_top-SIZEOF_STRUCT_TRAPFRAME),%esp
f0100033:	bc bc 0f 12 f0       	mov    $0xf0120fbc,%esp

	# now to C code
	call	FOS_initialize
f0100038:	e8 02 00 00 00       	call   f010003f <FOS_initialize>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <FOS_initialize>:



//First ever function called in FOS kernel
void FOS_initialize()
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_uninitialized_data_section[], end_of_kernel[];

	// Before doing anything else,
	// clear the uninitialized global data (BSS) section of our program, from start_of_uninitialized_data_section to end_of_kernel 
	// This ensures that all static/global variables start with zero value.
	memset(start_of_uninitialized_data_section, 0, end_of_kernel - start_of_uninitialized_data_section);
f0100045:	ba d4 49 15 f0       	mov    $0xf01549d4,%edx
f010004a:	b8 12 3d 15 f0       	mov    $0xf0153d12,%eax
f010004f:	29 c2                	sub    %eax,%edx
f0100051:	89 d0                	mov    %edx,%eax
f0100053:	83 ec 04             	sub    $0x4,%esp
f0100056:	50                   	push   %eax
f0100057:	6a 00                	push   $0x0
f0100059:	68 12 3d 15 f0       	push   $0xf0153d12
f010005e:	e8 34 6d 00 00       	call   f0106d97 <memset>
f0100063:	83 c4 10             	add    $0x10,%esp

	// Initialize the console.
	// Can't call cprintf until after we do this!
	console_initialize();
f0100066:	e8 7b 08 00 00       	call   f01008e6 <console_initialize>

	//print welcome message
	print_welcome_message();
f010006b:	e8 45 00 00 00       	call   f01000b5 <print_welcome_message>

	// Lab 2 memory management initialization functions
	detect_memory();
f0100070:	e8 c6 17 00 00       	call   f010183b <detect_memory>
	initialize_kernel_VM();
f0100075:	e8 37 43 00 00       	call   f01043b1 <initialize_kernel_VM>
	initialize_paging();
f010007a:	e8 f6 46 00 00       	call   f0104775 <initialize_paging>
	page_check();
f010007f:	e8 83 1b 00 00       	call   f0101c07 <page_check>

	
	// Lab 3 user environment initialization functions
	env_init();
f0100084:	e8 e3 4e 00 00       	call   f0104f6c <env_init>
	idt_init();
f0100089:	e8 77 56 00 00       	call   f0105705 <idt_init>

	
	// start the kernel command prompt.
	while (1==1)
	{
		cprintf("\nWelcome to the FOS kernel command prompt!\n");
f010008e:	83 ec 0c             	sub    $0xc,%esp
f0100091:	68 a0 73 10 f0       	push   $0xf01073a0
f0100096:	e8 19 56 00 00       	call   f01056b4 <cprintf>
f010009b:	83 c4 10             	add    $0x10,%esp
		cprintf("Type 'help' for a list of commands.\n");	
f010009e:	83 ec 0c             	sub    $0xc,%esp
f01000a1:	68 cc 73 10 f0       	push   $0xf01073cc
f01000a6:	e8 09 56 00 00       	call   f01056b4 <cprintf>
f01000ab:	83 c4 10             	add    $0x10,%esp
		run_command_prompt();
f01000ae:	e8 9e 08 00 00       	call   f0100951 <run_command_prompt>
	}
f01000b3:	eb d9                	jmp    f010008e <FOS_initialize+0x4f>

f01000b5 <print_welcome_message>:
}


void print_welcome_message()
{
f01000b5:	55                   	push   %ebp
f01000b6:	89 e5                	mov    %esp,%ebp
f01000b8:	83 ec 08             	sub    $0x8,%esp
	cprintf("\n\n\n");
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	68 f1 73 10 f0       	push   $0xf01073f1
f01000c3:	e8 ec 55 00 00       	call   f01056b4 <cprintf>
f01000c8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f01000cb:	83 ec 0c             	sub    $0xc,%esp
f01000ce:	68 f8 73 10 f0       	push   $0xf01073f8
f01000d3:	e8 dc 55 00 00       	call   f01056b4 <cprintf>
f01000d8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000db:	83 ec 0c             	sub    $0xc,%esp
f01000de:	68 40 74 10 f0       	push   $0xf0107440
f01000e3:	e8 cc 55 00 00       	call   f01056b4 <cprintf>
f01000e8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                   !! FCIS says HELLO !!                     !!\n");
f01000eb:	83 ec 0c             	sub    $0xc,%esp
f01000ee:	68 88 74 10 f0       	push   $0xf0107488
f01000f3:	e8 bc 55 00 00       	call   f01056b4 <cprintf>
f01000f8:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!                                                             !!\n");
f01000fb:	83 ec 0c             	sub    $0xc,%esp
f01000fe:	68 40 74 10 f0       	push   $0xf0107440
f0100103:	e8 ac 55 00 00       	call   f01056b4 <cprintf>
f0100108:	83 c4 10             	add    $0x10,%esp
	cprintf("\t\t!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	68 f8 73 10 f0       	push   $0xf01073f8
f0100113:	e8 9c 55 00 00       	call   f01056b4 <cprintf>
f0100118:	83 c4 10             	add    $0x10,%esp
	cprintf("\n\n\n\n");	
f010011b:	83 ec 0c             	sub    $0xc,%esp
f010011e:	68 cd 74 10 f0       	push   $0xf01074cd
f0100123:	e8 8c 55 00 00       	call   f01056b4 <cprintf>
f0100128:	83 c4 10             	add    $0x10,%esp
}
f010012b:	90                   	nop
f010012c:	c9                   	leave  
f010012d:	c3                   	ret    

f010012e <_panic>:
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel command prompt.
 */
void _panic(const char *file, int line, const char *fmt,...)
{
f010012e:	55                   	push   %ebp
f010012f:	89 e5                	mov    %esp,%ebp
f0100131:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f0100134:	a1 20 3d 15 f0       	mov    0xf0153d20,%eax
f0100139:	85 c0                	test   %eax,%eax
f010013b:	74 02                	je     f010013f <_panic+0x11>
		goto dead;
f010013d:	eb 49                	jmp    f0100188 <_panic+0x5a>
	panicstr = fmt;
f010013f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100142:	a3 20 3d 15 f0       	mov    %eax,0xf0153d20

	va_start(ap, fmt);
f0100147:	8d 45 10             	lea    0x10(%ebp),%eax
f010014a:	83 c0 04             	add    $0x4,%eax
f010014d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100150:	83 ec 04             	sub    $0x4,%esp
f0100153:	ff 75 0c             	pushl  0xc(%ebp)
f0100156:	ff 75 08             	pushl  0x8(%ebp)
f0100159:	68 d2 74 10 f0       	push   $0xf01074d2
f010015e:	e8 51 55 00 00       	call   f01056b4 <cprintf>
f0100163:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f0100166:	8b 45 10             	mov    0x10(%ebp),%eax
f0100169:	83 ec 08             	sub    $0x8,%esp
f010016c:	ff 75 f4             	pushl  -0xc(%ebp)
f010016f:	50                   	push   %eax
f0100170:	e8 16 55 00 00       	call   f010568b <vcprintf>
f0100175:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f0100178:	83 ec 0c             	sub    $0xc,%esp
f010017b:	68 ea 74 10 f0       	push   $0xf01074ea
f0100180:	e8 2f 55 00 00       	call   f01056b4 <cprintf>
f0100185:	83 c4 10             	add    $0x10,%esp
	va_end(ap);

dead:
	/* break into the kernel command prompt */
	while (1==1)
		run_command_prompt();
f0100188:	e8 c4 07 00 00       	call   f0100951 <run_command_prompt>
f010018d:	eb f9                	jmp    f0100188 <_panic+0x5a>

f010018f <_warn>:
}

/* like panic, but don't enters the kernel command prompt*/
void _warn(const char *file, int line, const char *fmt,...)
{
f010018f:	55                   	push   %ebp
f0100190:	89 e5                	mov    %esp,%ebp
f0100192:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100195:	8d 45 10             	lea    0x10(%ebp),%eax
f0100198:	83 c0 04             	add    $0x4,%eax
f010019b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	ff 75 0c             	pushl  0xc(%ebp)
f01001a4:	ff 75 08             	pushl  0x8(%ebp)
f01001a7:	68 ec 74 10 f0       	push   $0xf01074ec
f01001ac:	e8 03 55 00 00       	call   f01056b4 <cprintf>
f01001b1:	83 c4 10             	add    $0x10,%esp
	vcprintf(fmt, ap);
f01001b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01001b7:	83 ec 08             	sub    $0x8,%esp
f01001ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01001bd:	50                   	push   %eax
f01001be:	e8 c8 54 00 00       	call   f010568b <vcprintf>
f01001c3:	83 c4 10             	add    $0x10,%esp
	cprintf("\n");
f01001c6:	83 ec 0c             	sub    $0xc,%esp
f01001c9:	68 ea 74 10 f0       	push   $0xf01074ea
f01001ce:	e8 e1 54 00 00       	call   f01056b4 <cprintf>
f01001d3:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f01001d6:	90                   	nop
f01001d7:	c9                   	leave  
f01001d8:	c3                   	ret    

f01001d9 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001d9:	55                   	push   %ebp
f01001da:	89 e5                	mov    %esp,%ebp
f01001dc:	83 ec 10             	sub    $0x10,%esp
f01001df:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e6:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01001e9:	89 c2                	mov    %eax,%edx
f01001eb:	ec                   	in     (%dx),%al
f01001ec:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01001ef:	8a 45 f7             	mov    -0x9(%ebp),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001f2:	0f b6 c0             	movzbl %al,%eax
f01001f5:	83 e0 01             	and    $0x1,%eax
f01001f8:	85 c0                	test   %eax,%eax
f01001fa:	75 07                	jne    f0100203 <serial_proc_data+0x2a>
		return -1;
f01001fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100201:	eb 16                	jmp    f0100219 <serial_proc_data+0x40>
f0100203:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010020a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010020d:	89 c2                	mov    %eax,%edx
f010020f:	ec                   	in     (%dx),%al
f0100210:	88 45 f6             	mov    %al,-0xa(%ebp)
	return data;
f0100213:	8a 45 f6             	mov    -0xa(%ebp),%al
	return inb(COM1+COM_RX);
f0100216:	0f b6 c0             	movzbl %al,%eax
}
f0100219:	c9                   	leave  
f010021a:	c3                   	ret    

f010021b <serial_intr>:

void
serial_intr(void)
{
f010021b:	55                   	push   %ebp
f010021c:	89 e5                	mov    %esp,%ebp
f010021e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100221:	a1 40 3d 15 f0       	mov    0xf0153d40,%eax
f0100226:	85 c0                	test   %eax,%eax
f0100228:	74 10                	je     f010023a <serial_intr+0x1f>
		cons_intr(serial_proc_data);
f010022a:	83 ec 0c             	sub    $0xc,%esp
f010022d:	68 d9 01 10 f0       	push   $0xf01001d9
f0100232:	e8 e4 05 00 00       	call   f010081b <cons_intr>
f0100237:	83 c4 10             	add    $0x10,%esp
}
f010023a:	90                   	nop
f010023b:	c9                   	leave  
f010023c:	c3                   	ret    

f010023d <serial_init>:

void
serial_init(void)
{
f010023d:	55                   	push   %ebp
f010023e:	89 e5                	mov    %esp,%ebp
f0100240:	83 ec 40             	sub    $0x40,%esp
f0100243:	c7 45 fc fa 03 00 00 	movl   $0x3fa,-0x4(%ebp)
f010024a:	c6 45 ce 00          	movb   $0x0,-0x32(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010024e:	8a 45 ce             	mov    -0x32(%ebp),%al
f0100251:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100254:	ee                   	out    %al,(%dx)
f0100255:	c7 45 f8 fb 03 00 00 	movl   $0x3fb,-0x8(%ebp)
f010025c:	c6 45 cf 80          	movb   $0x80,-0x31(%ebp)
f0100260:	8a 45 cf             	mov    -0x31(%ebp),%al
f0100263:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100266:	ee                   	out    %al,(%dx)
f0100267:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)
f010026e:	c6 45 d0 0c          	movb   $0xc,-0x30(%ebp)
f0100272:	8a 45 d0             	mov    -0x30(%ebp),%al
f0100275:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100278:	ee                   	out    %al,(%dx)
f0100279:	c7 45 f0 f9 03 00 00 	movl   $0x3f9,-0x10(%ebp)
f0100280:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
f0100284:	8a 45 d1             	mov    -0x2f(%ebp),%al
f0100287:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010028a:	ee                   	out    %al,(%dx)
f010028b:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
f0100292:	c6 45 d2 03          	movb   $0x3,-0x2e(%ebp)
f0100296:	8a 45 d2             	mov    -0x2e(%ebp),%al
f0100299:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010029c:	ee                   	out    %al,(%dx)
f010029d:	c7 45 e8 fc 03 00 00 	movl   $0x3fc,-0x18(%ebp)
f01002a4:	c6 45 d3 00          	movb   $0x0,-0x2d(%ebp)
f01002a8:	8a 45 d3             	mov    -0x2d(%ebp),%al
f01002ab:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01002ae:	ee                   	out    %al,(%dx)
f01002af:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f01002b6:	c6 45 d4 01          	movb   $0x1,-0x2c(%ebp)
f01002ba:	8a 45 d4             	mov    -0x2c(%ebp),%al
f01002bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01002c0:	ee                   	out    %al,(%dx)
f01002c1:	c7 45 e0 fd 03 00 00 	movl   $0x3fd,-0x20(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01002cb:	89 c2                	mov    %eax,%edx
f01002cd:	ec                   	in     (%dx),%al
f01002ce:	88 45 d5             	mov    %al,-0x2b(%ebp)
	return data;
f01002d1:	8a 45 d5             	mov    -0x2b(%ebp),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01002d4:	3c ff                	cmp    $0xff,%al
f01002d6:	0f 95 c0             	setne  %al
f01002d9:	0f b6 c0             	movzbl %al,%eax
f01002dc:	a3 40 3d 15 f0       	mov    %eax,0xf0153d40
f01002e1:	c7 45 dc fa 03 00 00 	movl   $0x3fa,-0x24(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01002eb:	89 c2                	mov    %eax,%edx
f01002ed:	ec                   	in     (%dx),%al
f01002ee:	88 45 d6             	mov    %al,-0x2a(%ebp)
f01002f1:	c7 45 d8 f8 03 00 00 	movl   $0x3f8,-0x28(%ebp)
f01002f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01002fb:	89 c2                	mov    %eax,%edx
f01002fd:	ec                   	in     (%dx),%al
f01002fe:	88 45 d7             	mov    %al,-0x29(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100301:	90                   	nop
f0100302:	c9                   	leave  
f0100303:	c3                   	ret    

f0100304 <delay>:
// page.

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100304:	55                   	push   %ebp
f0100305:	89 e5                	mov    %esp,%ebp
f0100307:	83 ec 20             	sub    $0x20,%esp
f010030a:	c7 45 fc 84 00 00 00 	movl   $0x84,-0x4(%ebp)
f0100311:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100314:	89 c2                	mov    %eax,%edx
f0100316:	ec                   	in     (%dx),%al
f0100317:	88 45 ec             	mov    %al,-0x14(%ebp)
f010031a:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)
f0100321:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100324:	89 c2                	mov    %eax,%edx
f0100326:	ec                   	in     (%dx),%al
f0100327:	88 45 ed             	mov    %al,-0x13(%ebp)
f010032a:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)
f0100331:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100334:	89 c2                	mov    %eax,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	88 45 ee             	mov    %al,-0x12(%ebp)
f010033a:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
f0100341:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100344:	89 c2                	mov    %eax,%edx
f0100346:	ec                   	in     (%dx),%al
f0100347:	88 45 ef             	mov    %al,-0x11(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010034a:	90                   	nop
f010034b:	c9                   	leave  
f010034c:	c3                   	ret    

f010034d <lpt_putc>:

static void
lpt_putc(int c)
{
f010034d:	55                   	push   %ebp
f010034e:	89 e5                	mov    %esp,%ebp
f0100350:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010035a:	eb 08                	jmp    f0100364 <lpt_putc+0x17>
		delay();
f010035c:	e8 a3 ff ff ff       	call   f0100304 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 2800; i++) //12800
f0100361:	ff 45 fc             	incl   -0x4(%ebp)
f0100364:	c7 45 ec 79 03 00 00 	movl   $0x379,-0x14(%ebp)
f010036b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010036e:	89 c2                	mov    %eax,%edx
f0100370:	ec                   	in     (%dx),%al
f0100371:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
f0100374:	8a 45 eb             	mov    -0x15(%ebp),%al
f0100377:	84 c0                	test   %al,%al
f0100379:	78 09                	js     f0100384 <lpt_putc+0x37>
f010037b:	81 7d fc ef 0a 00 00 	cmpl   $0xaef,-0x4(%ebp)
f0100382:	7e d8                	jle    f010035c <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f0100384:	8b 45 08             	mov    0x8(%ebp),%eax
f0100387:	0f b6 c0             	movzbl %al,%eax
f010038a:	c7 45 f4 78 03 00 00 	movl   $0x378,-0xc(%ebp)
f0100391:	88 45 e8             	mov    %al,-0x18(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100394:	8a 45 e8             	mov    -0x18(%ebp),%al
f0100397:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010039a:	ee                   	out    %al,(%dx)
f010039b:	c7 45 f0 7a 03 00 00 	movl   $0x37a,-0x10(%ebp)
f01003a2:	c6 45 e9 0d          	movb   $0xd,-0x17(%ebp)
f01003a6:	8a 45 e9             	mov    -0x17(%ebp),%al
f01003a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01003ac:	ee                   	out    %al,(%dx)
f01003ad:	c7 45 f8 7a 03 00 00 	movl   $0x37a,-0x8(%ebp)
f01003b4:	c6 45 ea 08          	movb   $0x8,-0x16(%ebp)
f01003b8:	8a 45 ea             	mov    -0x16(%ebp),%al
f01003bb:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01003be:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003bf:	90                   	nop
f01003c0:	c9                   	leave  
f01003c1:	c3                   	ret    

f01003c2 <cga_init>:
static uint16 *crt_buf;
static uint16 crt_pos;

void
cga_init(void)
{
f01003c2:	55                   	push   %ebp
f01003c3:	89 e5                	mov    %esp,%ebp
f01003c5:	83 ec 20             	sub    $0x20,%esp
	volatile uint16 *cp;
	uint16 was;
	unsigned pos;

	cp = (uint16*) (KERNEL_BASE + CGA_BUF);
f01003c8:	c7 45 fc 00 80 0b f0 	movl   $0xf00b8000,-0x4(%ebp)
	was = *cp;
f01003cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003d2:	66 8b 00             	mov    (%eax),%ax
f01003d5:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16) 0xA55A;
f01003d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003dc:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01003e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01003e4:	66 8b 00             	mov    (%eax),%ax
f01003e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01003eb:	74 13                	je     f0100400 <cga_init+0x3e>
		cp = (uint16*) (KERNEL_BASE + MONO_BUF);
f01003ed:	c7 45 fc 00 00 0b f0 	movl   $0xf00b0000,-0x4(%ebp)
		addr_6845 = MONO_BASE;
f01003f4:	c7 05 44 3d 15 f0 b4 	movl   $0x3b4,0xf0153d44
f01003fb:	03 00 00 
f01003fe:	eb 14                	jmp    f0100414 <cga_init+0x52>
	} else {
		*cp = was;
f0100400:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100403:	66 8b 45 fa          	mov    -0x6(%ebp),%ax
f0100407:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
f010040a:	c7 05 44 3d 15 f0 d4 	movl   $0x3d4,0xf0153d44
f0100411:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100414:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f0100419:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010041c:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
f0100420:	8a 45 e0             	mov    -0x20(%ebp),%al
f0100423:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100426:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100427:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f010042c:	40                   	inc    %eax
f010042d:	89 45 ec             	mov    %eax,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100430:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100433:	89 c2                	mov    %eax,%edx
f0100435:	ec                   	in     (%dx),%al
f0100436:	88 45 e1             	mov    %al,-0x1f(%ebp)
	return data;
f0100439:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010043c:	0f b6 c0             	movzbl %al,%eax
f010043f:	c1 e0 08             	shl    $0x8,%eax
f0100442:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f0100445:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f010044a:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010044d:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100451:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100454:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100457:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f0100458:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f010045d:	40                   	inc    %eax
f010045e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100461:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100464:	89 c2                	mov    %eax,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010046a:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010046d:	0f b6 c0             	movzbl %al,%eax
f0100470:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16*) cp;
f0100473:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100476:	a3 48 3d 15 f0       	mov    %eax,0xf0153d48
	crt_pos = pos;
f010047b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010047e:	66 a3 4c 3d 15 f0    	mov    %ax,0xf0153d4c
}
f0100484:	90                   	nop
f0100485:	c9                   	leave  
f0100486:	c3                   	ret    

f0100487 <cga_putc>:



void
cga_putc(int c)
{
f0100487:	55                   	push   %ebp
f0100488:	89 e5                	mov    %esp,%ebp
f010048a:	53                   	push   %ebx
f010048b:	83 ec 24             	sub    $0x24,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010048e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100491:	b0 00                	mov    $0x0,%al
f0100493:	85 c0                	test   %eax,%eax
f0100495:	75 07                	jne    f010049e <cga_putc+0x17>
		c |= 0x0700;
f0100497:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f010049e:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a1:	0f b6 c0             	movzbl %al,%eax
f01004a4:	83 f8 09             	cmp    $0x9,%eax
f01004a7:	0f 84 94 00 00 00    	je     f0100541 <cga_putc+0xba>
f01004ad:	83 f8 09             	cmp    $0x9,%eax
f01004b0:	7f 0a                	jg     f01004bc <cga_putc+0x35>
f01004b2:	83 f8 08             	cmp    $0x8,%eax
f01004b5:	74 14                	je     f01004cb <cga_putc+0x44>
f01004b7:	e9 c8 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
f01004bc:	83 f8 0a             	cmp    $0xa,%eax
f01004bf:	74 49                	je     f010050a <cga_putc+0x83>
f01004c1:	83 f8 0d             	cmp    $0xd,%eax
f01004c4:	74 53                	je     f0100519 <cga_putc+0x92>
f01004c6:	e9 b9 00 00 00       	jmp    f0100584 <cga_putc+0xfd>
	case '\b':
		if (crt_pos > 0) {
f01004cb:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f01004d1:	66 85 c0             	test   %ax,%ax
f01004d4:	0f 84 d0 00 00 00    	je     f01005aa <cga_putc+0x123>
			crt_pos--;
f01004da:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f01004e0:	48                   	dec    %eax
f01004e1:	66 a3 4c 3d 15 f0    	mov    %ax,0xf0153d4c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e7:	8b 15 48 3d 15 f0    	mov    0xf0153d48,%edx
f01004ed:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f01004f3:	0f b7 c0             	movzwl %ax,%eax
f01004f6:	01 c0                	add    %eax,%eax
f01004f8:	01 c2                	add    %eax,%edx
f01004fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01004fd:	b0 00                	mov    $0x0,%al
f01004ff:	83 c8 20             	or     $0x20,%eax
f0100502:	66 89 02             	mov    %ax,(%edx)
		}
		break;
f0100505:	e9 a0 00 00 00       	jmp    f01005aa <cga_putc+0x123>
	case '\n':
		crt_pos += CRT_COLS;
f010050a:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f0100510:	83 c0 50             	add    $0x50,%eax
f0100513:	66 a3 4c 3d 15 f0    	mov    %ax,0xf0153d4c
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100519:	66 8b 0d 4c 3d 15 f0 	mov    0xf0153d4c,%cx
f0100520:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f0100526:	bb 50 00 00 00       	mov    $0x50,%ebx
f010052b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100530:	66 f7 f3             	div    %bx
f0100533:	89 d0                	mov    %edx,%eax
f0100535:	29 c1                	sub    %eax,%ecx
f0100537:	89 c8                	mov    %ecx,%eax
f0100539:	66 a3 4c 3d 15 f0    	mov    %ax,0xf0153d4c
		break;
f010053f:	eb 6a                	jmp    f01005ab <cga_putc+0x124>
	case '\t':
		cons_putc(' ');
f0100541:	83 ec 0c             	sub    $0xc,%esp
f0100544:	6a 20                	push   $0x20
f0100546:	e8 79 03 00 00       	call   f01008c4 <cons_putc>
f010054b:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010054e:	83 ec 0c             	sub    $0xc,%esp
f0100551:	6a 20                	push   $0x20
f0100553:	e8 6c 03 00 00       	call   f01008c4 <cons_putc>
f0100558:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f010055b:	83 ec 0c             	sub    $0xc,%esp
f010055e:	6a 20                	push   $0x20
f0100560:	e8 5f 03 00 00       	call   f01008c4 <cons_putc>
f0100565:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100568:	83 ec 0c             	sub    $0xc,%esp
f010056b:	6a 20                	push   $0x20
f010056d:	e8 52 03 00 00       	call   f01008c4 <cons_putc>
f0100572:	83 c4 10             	add    $0x10,%esp
		cons_putc(' ');
f0100575:	83 ec 0c             	sub    $0xc,%esp
f0100578:	6a 20                	push   $0x20
f010057a:	e8 45 03 00 00       	call   f01008c4 <cons_putc>
f010057f:	83 c4 10             	add    $0x10,%esp
		break;
f0100582:	eb 27                	jmp    f01005ab <cga_putc+0x124>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100584:	8b 0d 48 3d 15 f0    	mov    0xf0153d48,%ecx
f010058a:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f0100590:	8d 50 01             	lea    0x1(%eax),%edx
f0100593:	66 89 15 4c 3d 15 f0 	mov    %dx,0xf0153d4c
f010059a:	0f b7 c0             	movzwl %ax,%eax
f010059d:	01 c0                	add    %eax,%eax
f010059f:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f01005a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01005a5:	66 89 02             	mov    %ax,(%edx)
		break;
f01005a8:	eb 01                	jmp    f01005ab <cga_putc+0x124>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
f01005aa:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ab:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f01005b1:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005b5:	76 58                	jbe    f010060f <cga_putc+0x188>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
f01005b7:	a1 48 3d 15 f0       	mov    0xf0153d48,%eax
f01005bc:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c2:	a1 48 3d 15 f0       	mov    0xf0153d48,%eax
f01005c7:	83 ec 04             	sub    $0x4,%esp
f01005ca:	68 00 0f 00 00       	push   $0xf00
f01005cf:	52                   	push   %edx
f01005d0:	50                   	push   %eax
f01005d1:	e8 f1 67 00 00       	call   f0106dc7 <memcpy>
f01005d6:	83 c4 10             	add    $0x10,%esp
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005d9:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f01005e0:	eb 15                	jmp    f01005f7 <cga_putc+0x170>
			crt_buf[i] = 0x0700 | ' ';
f01005e2:	8b 15 48 3d 15 f0    	mov    0xf0153d48,%edx
f01005e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01005eb:	01 c0                	add    %eax,%eax
f01005ed:	01 d0                	add    %edx,%eax
f01005ef:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f4:	ff 45 f4             	incl   -0xc(%ebp)
f01005f7:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f01005fe:	7e e2                	jle    f01005e2 <cga_putc+0x15b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100600:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f0100606:	83 e8 50             	sub    $0x50,%eax
f0100609:	66 a3 4c 3d 15 f0    	mov    %ax,0xf0153d4c
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010060f:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f0100614:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100617:	c6 45 e0 0e          	movb   $0xe,-0x20(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061b:	8a 45 e0             	mov    -0x20(%ebp),%al
f010061e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100621:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100622:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f0100628:	66 c1 e8 08          	shr    $0x8,%ax
f010062c:	0f b6 c0             	movzbl %al,%eax
f010062f:	8b 15 44 3d 15 f0    	mov    0xf0153d44,%edx
f0100635:	42                   	inc    %edx
f0100636:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0100639:	88 45 e1             	mov    %al,-0x1f(%ebp)
f010063c:	8a 45 e1             	mov    -0x1f(%ebp),%al
f010063f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100642:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f0100643:	a1 44 3d 15 f0       	mov    0xf0153d44,%eax
f0100648:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010064b:	c6 45 e2 0f          	movb   $0xf,-0x1e(%ebp)
f010064f:	8a 45 e2             	mov    -0x1e(%ebp),%al
f0100652:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100655:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100656:	66 a1 4c 3d 15 f0    	mov    0xf0153d4c,%ax
f010065c:	0f b6 c0             	movzbl %al,%eax
f010065f:	8b 15 44 3d 15 f0    	mov    0xf0153d44,%edx
f0100665:	42                   	inc    %edx
f0100666:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100669:	88 45 e3             	mov    %al,-0x1d(%ebp)
f010066c:	8a 45 e3             	mov    -0x1d(%ebp),%al
f010066f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100672:	ee                   	out    %al,(%dx)
}
f0100673:	90                   	nop
f0100674:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100677:	c9                   	leave  
f0100678:	c3                   	ret    

f0100679 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100679:	55                   	push   %ebp
f010067a:	89 e5                	mov    %esp,%ebp
f010067c:	83 ec 28             	sub    $0x28,%esp
f010067f:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	ec                   	in     (%dx),%al
f010068c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	return data;
f010068f:	8a 45 e3             	mov    -0x1d(%ebp),%al
	int c;
	uint8 data;
	static uint32 shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100692:	0f b6 c0             	movzbl %al,%eax
f0100695:	83 e0 01             	and    $0x1,%eax
f0100698:	85 c0                	test   %eax,%eax
f010069a:	75 0a                	jne    f01006a6 <kbd_proc_data+0x2d>
		return -1;
f010069c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01006a1:	e9 54 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
f01006a6:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01006b0:	89 c2                	mov    %eax,%edx
f01006b2:	ec                   	in     (%dx),%al
f01006b3:	88 45 e2             	mov    %al,-0x1e(%ebp)
	return data;
f01006b6:	8a 45 e2             	mov    -0x1e(%ebp),%al

	data = inb(KBDATAP);
f01006b9:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
f01006bc:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
f01006c0:	75 17                	jne    f01006d9 <kbd_proc_data+0x60>
		// E0 escape character
		shift |= E0ESC;
f01006c2:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f01006c7:	83 c8 40             	or     $0x40,%eax
f01006ca:	a3 68 3f 15 f0       	mov    %eax,0xf0153f68
		return 0;
f01006cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d4:	e9 21 01 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (data & 0x80) {
f01006d9:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006dc:	84 c0                	test   %al,%al
f01006de:	79 44                	jns    f0100724 <kbd_proc_data+0xab>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01006e0:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f01006e5:	83 e0 40             	and    $0x40,%eax
f01006e8:	85 c0                	test   %eax,%eax
f01006ea:	75 08                	jne    f01006f4 <kbd_proc_data+0x7b>
f01006ec:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006ef:	83 e0 7f             	and    $0x7f,%eax
f01006f2:	eb 03                	jmp    f01006f7 <kbd_proc_data+0x7e>
f01006f4:	8a 45 f3             	mov    -0xd(%ebp),%al
f01006f7:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f01006fa:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f01006fe:	8a 80 20 10 12 f0    	mov    -0xfedefe0(%eax),%al
f0100704:	83 c8 40             	or     $0x40,%eax
f0100707:	0f b6 c0             	movzbl %al,%eax
f010070a:	f7 d0                	not    %eax
f010070c:	89 c2                	mov    %eax,%edx
f010070e:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100713:	21 d0                	and    %edx,%eax
f0100715:	a3 68 3f 15 f0       	mov    %eax,0xf0153f68
		return 0;
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
f010071f:	e9 d6 00 00 00       	jmp    f01007fa <kbd_proc_data+0x181>
	} else if (shift & E0ESC) {
f0100724:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100729:	83 e0 40             	and    $0x40,%eax
f010072c:	85 c0                	test   %eax,%eax
f010072e:	74 11                	je     f0100741 <kbd_proc_data+0xc8>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100730:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
f0100734:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100739:	83 e0 bf             	and    $0xffffffbf,%eax
f010073c:	a3 68 3f 15 f0       	mov    %eax,0xf0153f68
	}

	shift |= shiftcode[data];
f0100741:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100745:	8a 80 20 10 12 f0    	mov    -0xfedefe0(%eax),%al
f010074b:	0f b6 d0             	movzbl %al,%edx
f010074e:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100753:	09 d0                	or     %edx,%eax
f0100755:	a3 68 3f 15 f0       	mov    %eax,0xf0153f68
	shift ^= togglecode[data];
f010075a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f010075e:	8a 80 20 11 12 f0    	mov    -0xfedeee0(%eax),%al
f0100764:	0f b6 d0             	movzbl %al,%edx
f0100767:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f010076c:	31 d0                	xor    %edx,%eax
f010076e:	a3 68 3f 15 f0       	mov    %eax,0xf0153f68

	c = charcode[shift & (CTL | SHIFT)][data];
f0100773:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100778:	83 e0 03             	and    $0x3,%eax
f010077b:	8b 14 85 20 15 12 f0 	mov    -0xfedeae0(,%eax,4),%edx
f0100782:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
f0100786:	01 d0                	add    %edx,%eax
f0100788:	8a 00                	mov    (%eax),%al
f010078a:	0f b6 c0             	movzbl %al,%eax
f010078d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
f0100790:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f0100795:	83 e0 08             	and    $0x8,%eax
f0100798:	85 c0                	test   %eax,%eax
f010079a:	74 22                	je     f01007be <kbd_proc_data+0x145>
		if ('a' <= c && c <= 'z')
f010079c:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
f01007a0:	7e 0c                	jle    f01007ae <kbd_proc_data+0x135>
f01007a2:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
f01007a6:	7f 06                	jg     f01007ae <kbd_proc_data+0x135>
			c += 'A' - 'a';
f01007a8:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
f01007ac:	eb 10                	jmp    f01007be <kbd_proc_data+0x145>
		else if ('A' <= c && c <= 'Z')
f01007ae:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
f01007b2:	7e 0a                	jle    f01007be <kbd_proc_data+0x145>
f01007b4:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
f01007b8:	7f 04                	jg     f01007be <kbd_proc_data+0x145>
			c += 'a' - 'A';
f01007ba:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01007be:	a1 68 3f 15 f0       	mov    0xf0153f68,%eax
f01007c3:	f7 d0                	not    %eax
f01007c5:	83 e0 06             	and    $0x6,%eax
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	75 2b                	jne    f01007f7 <kbd_proc_data+0x17e>
f01007cc:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
f01007d3:	75 22                	jne    f01007f7 <kbd_proc_data+0x17e>
		cprintf("Rebooting!\n");
f01007d5:	83 ec 0c             	sub    $0xc,%esp
f01007d8:	68 06 75 10 f0       	push   $0xf0107506
f01007dd:	e8 d2 4e 00 00       	call   f01056b4 <cprintf>
f01007e2:	83 c4 10             	add    $0x10,%esp
f01007e5:	c7 45 e8 92 00 00 00 	movl   $0x92,-0x18(%ebp)
f01007ec:	c6 45 e1 03          	movb   $0x3,-0x1f(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01007f0:	8a 45 e1             	mov    -0x1f(%ebp),%al
f01007f3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01007f6:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01007f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01007fa:	c9                   	leave  
f01007fb:	c3                   	ret    

f01007fc <kbd_intr>:

void
kbd_intr(void)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100802:	83 ec 0c             	sub    $0xc,%esp
f0100805:	68 79 06 10 f0       	push   $0xf0100679
f010080a:	e8 0c 00 00 00       	call   f010081b <cons_intr>
f010080f:	83 c4 10             	add    $0x10,%esp
}
f0100812:	90                   	nop
f0100813:	c9                   	leave  
f0100814:	c3                   	ret    

f0100815 <kbd_init>:

void
kbd_init(void)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
}
f0100818:	90                   	nop
f0100819:	5d                   	pop    %ebp
f010081a:	c3                   	ret    

f010081b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
f0100821:	eb 35                	jmp    f0100858 <cons_intr+0x3d>
		if (c == 0)
f0100823:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100827:	75 02                	jne    f010082b <cons_intr+0x10>
			continue;
f0100829:	eb 2d                	jmp    f0100858 <cons_intr+0x3d>
		cons.buf[cons.wpos++] = c;
f010082b:	a1 64 3f 15 f0       	mov    0xf0153f64,%eax
f0100830:	8d 50 01             	lea    0x1(%eax),%edx
f0100833:	89 15 64 3f 15 f0    	mov    %edx,0xf0153f64
f0100839:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010083c:	88 90 60 3d 15 f0    	mov    %dl,-0xfeac2a0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f0100842:	a1 64 3f 15 f0       	mov    0xf0153f64,%eax
f0100847:	3d 00 02 00 00       	cmp    $0x200,%eax
f010084c:	75 0a                	jne    f0100858 <cons_intr+0x3d>
			cons.wpos = 0;
f010084e:	c7 05 64 3f 15 f0 00 	movl   $0x0,0xf0153f64
f0100855:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100858:	8b 45 08             	mov    0x8(%ebp),%eax
f010085b:	ff d0                	call   *%eax
f010085d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100860:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f0100864:	75 bd                	jne    f0100823 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100866:	90                   	nop
f0100867:	c9                   	leave  
f0100868:	c3                   	ret    

f0100869 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100869:	55                   	push   %ebp
f010086a:	89 e5                	mov    %esp,%ebp
f010086c:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010086f:	e8 a7 f9 ff ff       	call   f010021b <serial_intr>
	kbd_intr();
f0100874:	e8 83 ff ff ff       	call   f01007fc <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100879:	8b 15 60 3f 15 f0    	mov    0xf0153f60,%edx
f010087f:	a1 64 3f 15 f0       	mov    0xf0153f64,%eax
f0100884:	39 c2                	cmp    %eax,%edx
f0100886:	74 35                	je     f01008bd <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
f0100888:	a1 60 3f 15 f0       	mov    0xf0153f60,%eax
f010088d:	8d 50 01             	lea    0x1(%eax),%edx
f0100890:	89 15 60 3f 15 f0    	mov    %edx,0xf0153f60
f0100896:	8a 80 60 3d 15 f0    	mov    -0xfeac2a0(%eax),%al
f010089c:	0f b6 c0             	movzbl %al,%eax
f010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if (cons.rpos == CONSBUFSIZE)
f01008a2:	a1 60 3f 15 f0       	mov    0xf0153f60,%eax
f01008a7:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008ac:	75 0a                	jne    f01008b8 <cons_getc+0x4f>
			cons.rpos = 0;
f01008ae:	c7 05 60 3f 15 f0 00 	movl   $0x0,0xf0153f60
f01008b5:	00 00 00 
		return c;
f01008b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008bb:	eb 05                	jmp    f01008c2 <cons_getc+0x59>
	}
	return 0;
f01008bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01008c2:	c9                   	leave  
f01008c3:	c3                   	ret    

f01008c4 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f01008c4:	55                   	push   %ebp
f01008c5:	89 e5                	mov    %esp,%ebp
f01008c7:	83 ec 08             	sub    $0x8,%esp
	lpt_putc(c);
f01008ca:	ff 75 08             	pushl  0x8(%ebp)
f01008cd:	e8 7b fa ff ff       	call   f010034d <lpt_putc>
f01008d2:	83 c4 04             	add    $0x4,%esp
	cga_putc(c);
f01008d5:	83 ec 0c             	sub    $0xc,%esp
f01008d8:	ff 75 08             	pushl  0x8(%ebp)
f01008db:	e8 a7 fb ff ff       	call   f0100487 <cga_putc>
f01008e0:	83 c4 10             	add    $0x10,%esp
}
f01008e3:	90                   	nop
f01008e4:	c9                   	leave  
f01008e5:	c3                   	ret    

f01008e6 <console_initialize>:

// initialize the console devices
void
console_initialize(void)
{
f01008e6:	55                   	push   %ebp
f01008e7:	89 e5                	mov    %esp,%ebp
f01008e9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01008ec:	e8 d1 fa ff ff       	call   f01003c2 <cga_init>
	kbd_init();
f01008f1:	e8 1f ff ff ff       	call   f0100815 <kbd_init>
	serial_init();
f01008f6:	e8 42 f9 ff ff       	call   f010023d <serial_init>

	if (!serial_exists)
f01008fb:	a1 40 3d 15 f0       	mov    0xf0153d40,%eax
f0100900:	85 c0                	test   %eax,%eax
f0100902:	75 10                	jne    f0100914 <console_initialize+0x2e>
		cprintf("Serial port does not exist!\n");
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	68 12 75 10 f0       	push   $0xf0107512
f010090c:	e8 a3 4d 00 00       	call   f01056b4 <cprintf>
f0100911:	83 c4 10             	add    $0x10,%esp
}
f0100914:	90                   	nop
f0100915:	c9                   	leave  
f0100916:	c3                   	ret    

f0100917 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010091d:	83 ec 0c             	sub    $0xc,%esp
f0100920:	ff 75 08             	pushl  0x8(%ebp)
f0100923:	e8 9c ff ff ff       	call   f01008c4 <cons_putc>
f0100928:	83 c4 10             	add    $0x10,%esp
}
f010092b:	90                   	nop
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <getchar>:

int
getchar(void)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100934:	e8 30 ff ff ff       	call   f0100869 <cons_getc>
f0100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
f010093c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100940:	74 f2                	je     f0100934 <getchar+0x6>
		/* do nothing */;
	return c;
f0100942:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0100945:	c9                   	leave  
f0100946:	c3                   	ret    

f0100947 <iscons>:

int
iscons(int fdnum)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f010094a:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010094f:	5d                   	pop    %ebp
f0100950:	c3                   	ret    

f0100951 <run_command_prompt>:

int firstTime = 1;

//invoke the command prompt
void run_command_prompt()
{
f0100951:	55                   	push   %ebp
f0100952:	89 e5                	mov    %esp,%ebp
f0100954:	81 ec 08 04 00 00    	sub    $0x408,%esp
	cprintf("========================\n");
f010095a:	83 ec 0c             	sub    $0xc,%esp
f010095d:	68 f4 79 10 f0       	push   $0xf01079f4
f0100962:	e8 4d 4d 00 00       	call   f01056b4 <cprintf>
f0100967:	83 c4 10             	add    $0x10,%esp
	//CAUTION: DON'T CHANGE OR COMMENT THESE LINE======
	if (firstTime)
f010096a:	a1 68 16 12 f0       	mov    0xf0121668,%eax
f010096f:	85 c0                	test   %eax,%eax
f0100971:	74 11                	je     f0100984 <run_command_prompt+0x33>
	{
		firstTime = 0;
f0100973:	c7 05 68 16 12 f0 00 	movl   $0x0,0xf0121668
f010097a:	00 00 00 
		TestAssignment2();
f010097d:	e8 b3 1c 00 00       	call   f0102635 <TestAssignment2>
f0100982:	eb 10                	jmp    f0100994 <run_command_prompt+0x43>

	}
	else
	{
		cprintf("Test failed.\n");
f0100984:	83 ec 0c             	sub    $0xc,%esp
f0100987:	68 0e 7a 10 f0       	push   $0xf0107a0e
f010098c:	e8 23 4d 00 00       	call   f01056b4 <cprintf>
f0100991:	83 c4 10             	add    $0x10,%esp
	char command_line[1024];

	while (1==1)
	{
		//get command line
		readline("FOS> ", command_line);
f0100994:	83 ec 08             	sub    $0x8,%esp
f0100997:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f010099d:	50                   	push   %eax
f010099e:	68 1c 7a 10 f0       	push   $0xf0107a1c
f01009a3:	e8 03 61 00 00       	call   f0106aab <readline>
f01009a8:	83 c4 10             	add    $0x10,%esp

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
f01009ab:	83 ec 0c             	sub    $0xc,%esp
f01009ae:	8d 85 f8 fb ff ff    	lea    -0x408(%ebp),%eax
f01009b4:	50                   	push   %eax
f01009b5:	e8 0d 00 00 00       	call   f01009c7 <execute_command>
f01009ba:	83 c4 10             	add    $0x10,%esp
f01009bd:	85 c0                	test   %eax,%eax
f01009bf:	78 02                	js     f01009c3 <run_command_prompt+0x72>
				break;
	}
f01009c1:	eb d1                	jmp    f0100994 <run_command_prompt+0x43>
		readline("FOS> ", command_line);

		//parse and execute the command
		if (command_line != NULL)
			if (execute_command(command_line) < 0)
				break;
f01009c3:	90                   	nop
	}
}
f01009c4:	90                   	nop
f01009c5:	c9                   	leave  
f01009c6:	c3                   	ret    

f01009c7 <execute_command>:
#define WHITESPACE "\t\r\n "

//Function to parse any command and execute it
//(simply by calling its corresponding function)
int execute_command(char *command_string)
{
f01009c7:	55                   	push   %ebp
f01009c8:	89 e5                	mov    %esp,%ebp
f01009ca:	83 ec 58             	sub    $0x58,%esp
	int number_of_arguments;
	//allocate array of char * of size MAX_ARGUMENTS = 16 found in string.h
	char *arguments[MAX_ARGUMENTS];


	strsplit(command_string, WHITESPACE, arguments, &number_of_arguments) ;
f01009cd:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01009d0:	50                   	push   %eax
f01009d1:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01009d4:	50                   	push   %eax
f01009d5:	68 22 7a 10 f0       	push   $0xf0107a22
f01009da:	ff 75 08             	pushl  0x8(%ebp)
f01009dd:	e8 6d 66 00 00       	call   f010704f <strsplit>
f01009e2:	83 c4 10             	add    $0x10,%esp
	if (number_of_arguments == 0)
f01009e5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009e8:	85 c0                	test   %eax,%eax
f01009ea:	75 0a                	jne    f01009f6 <execute_command+0x2f>
		return 0;
f01009ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01009f1:	e9 95 00 00 00       	jmp    f0100a8b <execute_command+0xc4>

	// Lookup in the commands array and execute the command
	int command_found = 0;
f01009f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f01009fd:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100a04:	eb 33                	jmp    f0100a39 <execute_command+0x72>
	{
		if (strcmp(arguments[0], commands[i].name) == 0)
f0100a06:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a09:	89 d0                	mov    %edx,%eax
f0100a0b:	01 c0                	add    %eax,%eax
f0100a0d:	01 d0                	add    %edx,%eax
f0100a0f:	c1 e0 02             	shl    $0x2,%eax
f0100a12:	05 60 15 12 f0       	add    $0xf0121560,%eax
f0100a17:	8b 10                	mov    (%eax),%edx
f0100a19:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a1c:	83 ec 08             	sub    $0x8,%esp
f0100a1f:	52                   	push   %edx
f0100a20:	50                   	push   %eax
f0100a21:	e8 8f 62 00 00       	call   f0106cb5 <strcmp>
f0100a26:	83 c4 10             	add    $0x10,%esp
f0100a29:	85 c0                	test   %eax,%eax
f0100a2b:	75 09                	jne    f0100a36 <execute_command+0x6f>
		{
			command_found = 1;
f0100a2d:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
			break;
f0100a34:	eb 0b                	jmp    f0100a41 <execute_command+0x7a>
		return 0;

	// Lookup in the commands array and execute the command
	int command_found = 0;
	int i ;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a36:	ff 45 f0             	incl   -0x10(%ebp)
f0100a39:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a3c:	83 f8 15             	cmp    $0x15,%eax
f0100a3f:	76 c5                	jbe    f0100a06 <execute_command+0x3f>
			command_found = 1;
			break;
		}
	}

	if(command_found)
f0100a41:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100a45:	74 2b                	je     f0100a72 <execute_command+0xab>
	{
		int return_value;
		return_value = commands[i].function_to_execute(number_of_arguments, arguments);
f0100a47:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a4a:	89 d0                	mov    %edx,%eax
f0100a4c:	01 c0                	add    %eax,%eax
f0100a4e:	01 d0                	add    %edx,%eax
f0100a50:	c1 e0 02             	shl    $0x2,%eax
f0100a53:	05 68 15 12 f0       	add    $0xf0121568,%eax
f0100a58:	8b 00                	mov    (%eax),%eax
f0100a5a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a5d:	83 ec 08             	sub    $0x8,%esp
f0100a60:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a63:	51                   	push   %ecx
f0100a64:	52                   	push   %edx
f0100a65:	ff d0                	call   *%eax
f0100a67:	83 c4 10             	add    $0x10,%esp
f0100a6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
		return return_value;
f0100a6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a70:	eb 19                	jmp    f0100a8b <execute_command+0xc4>
	}
	else
	{
		//if not found, then it's unknown command
		cprintf("Unknown command '%s'\n", arguments[0]);
f0100a72:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a75:	83 ec 08             	sub    $0x8,%esp
f0100a78:	50                   	push   %eax
f0100a79:	68 27 7a 10 f0       	push   $0xf0107a27
f0100a7e:	e8 31 4c 00 00       	call   f01056b4 <cprintf>
f0100a83:	83 c4 10             	add    $0x10,%esp
		return 0;
f0100a86:	b8 00 00 00 00       	mov    $0x0,%eax
	}
}
f0100a8b:	c9                   	leave  
f0100a8c:	c3                   	ret    

f0100a8d <command_help>:
/***************************************/
/*DON'T change the following functions*/
/***************************************/
//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
f0100a8d:	55                   	push   %ebp
f0100a8e:	89 e5                	mov    %esp,%ebp
f0100a90:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100a93:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0100a9a:	eb 3b                	jmp    f0100ad7 <command_help+0x4a>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);
f0100a9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100a9f:	89 d0                	mov    %edx,%eax
f0100aa1:	01 c0                	add    %eax,%eax
f0100aa3:	01 d0                	add    %edx,%eax
f0100aa5:	c1 e0 02             	shl    $0x2,%eax
f0100aa8:	05 64 15 12 f0       	add    $0xf0121564,%eax
f0100aad:	8b 10                	mov    (%eax),%edx
f0100aaf:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0100ab2:	89 c8                	mov    %ecx,%eax
f0100ab4:	01 c0                	add    %eax,%eax
f0100ab6:	01 c8                	add    %ecx,%eax
f0100ab8:	c1 e0 02             	shl    $0x2,%eax
f0100abb:	05 60 15 12 f0       	add    $0xf0121560,%eax
f0100ac0:	8b 00                	mov    (%eax),%eax
f0100ac2:	83 ec 04             	sub    $0x4,%esp
f0100ac5:	52                   	push   %edx
f0100ac6:	50                   	push   %eax
f0100ac7:	68 3d 7a 10 f0       	push   $0xf0107a3d
f0100acc:	e8 e3 4b 00 00       	call   f01056b4 <cprintf>
f0100ad1:	83 c4 10             	add    $0x10,%esp
/***************************************/
//print name and description of each command
int command_help(int number_of_arguments, char **arguments)
{
	int i;
	for (i = 0; i < NUM_OF_COMMANDS; i++)
f0100ad4:	ff 45 f4             	incl   -0xc(%ebp)
f0100ad7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ada:	83 f8 15             	cmp    $0x15,%eax
f0100add:	76 bd                	jbe    f0100a9c <command_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].description);

	cprintf("-------------------\n");
f0100adf:	83 ec 0c             	sub    $0xc,%esp
f0100ae2:	68 46 7a 10 f0       	push   $0xf0107a46
f0100ae7:	e8 c8 4b 00 00       	call   f01056b4 <cprintf>
f0100aec:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100aef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100af4:	c9                   	leave  
f0100af5:	c3                   	ret    

f0100af6 <command_kernel_info>:

/*DON'T change this function*/
//print information about kernel addresses and kernel size
int command_kernel_info(int number_of_arguments, char **arguments )
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
f0100af9:	83 ec 08             	sub    $0x8,%esp
	extern char start_of_kernel[], end_of_kernel_code_section[], start_of_uninitialized_data_section[], end_of_kernel[];

	cprintf("Special kernel symbols:\n");
f0100afc:	83 ec 0c             	sub    $0xc,%esp
f0100aff:	68 5b 7a 10 f0       	push   $0xf0107a5b
f0100b04:	e8 ab 4b 00 00       	call   f01056b4 <cprintf>
f0100b09:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
f0100b0c:	b8 0c 00 10 00       	mov    $0x10000c,%eax
f0100b11:	83 ec 04             	sub    $0x4,%esp
f0100b14:	50                   	push   %eax
f0100b15:	68 0c 00 10 f0       	push   $0xf010000c
f0100b1a:	68 74 7a 10 f0       	push   $0xf0107a74
f0100b1f:	e8 90 4b 00 00       	call   f01056b4 <cprintf>
f0100b24:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
f0100b27:	b8 85 73 10 00       	mov    $0x107385,%eax
f0100b2c:	83 ec 04             	sub    $0x4,%esp
f0100b2f:	50                   	push   %eax
f0100b30:	68 85 73 10 f0       	push   $0xf0107385
f0100b35:	68 b0 7a 10 f0       	push   $0xf0107ab0
f0100b3a:	e8 75 4b 00 00       	call   f01056b4 <cprintf>
f0100b3f:	83 c4 10             	add    $0x10,%esp
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
f0100b42:	b8 12 3d 15 00       	mov    $0x153d12,%eax
f0100b47:	83 ec 04             	sub    $0x4,%esp
f0100b4a:	50                   	push   %eax
f0100b4b:	68 12 3d 15 f0       	push   $0xf0153d12
f0100b50:	68 ec 7a 10 f0       	push   $0xf0107aec
f0100b55:	e8 5a 4b 00 00       	call   f01056b4 <cprintf>
f0100b5a:	83 c4 10             	add    $0x10,%esp
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
f0100b5d:	b8 d4 49 15 00       	mov    $0x1549d4,%eax
f0100b62:	83 ec 04             	sub    $0x4,%esp
f0100b65:	50                   	push   %eax
f0100b66:	68 d4 49 15 f0       	push   $0xf01549d4
f0100b6b:	68 34 7b 10 f0       	push   $0xf0107b34
f0100b70:	e8 3f 4b 00 00       	call   f01056b4 <cprintf>
f0100b75:	83 c4 10             	add    $0x10,%esp
	cprintf("Kernel executable memory footprint: %d KB\n",
			(end_of_kernel-start_of_kernel+1023)/1024);
f0100b78:	b8 d4 49 15 f0       	mov    $0xf01549d4,%eax
f0100b7d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100b83:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100b88:	29 c2                	sub    %eax,%edx
f0100b8a:	89 d0                	mov    %edx,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  Start Address of the kernel 			%08x (virt)  %08x (phys)\n", start_of_kernel, start_of_kernel - KERNEL_BASE);
	cprintf("  End address of kernel code  			%08x (virt)  %08x (phys)\n", end_of_kernel_code_section, end_of_kernel_code_section - KERNEL_BASE);
	cprintf("  Start addr. of uninitialized data section 	%08x (virt)  %08x (phys)\n", start_of_uninitialized_data_section, start_of_uninitialized_data_section - KERNEL_BASE);
	cprintf("  End address of the kernel   			%08x (virt)  %08x (phys)\n", end_of_kernel, end_of_kernel - KERNEL_BASE);
	cprintf("Kernel executable memory footprint: %d KB\n",
f0100b8c:	85 c0                	test   %eax,%eax
f0100b8e:	79 05                	jns    f0100b95 <command_kernel_info+0x9f>
f0100b90:	05 ff 03 00 00       	add    $0x3ff,%eax
f0100b95:	c1 f8 0a             	sar    $0xa,%eax
f0100b98:	83 ec 08             	sub    $0x8,%esp
f0100b9b:	50                   	push   %eax
f0100b9c:	68 70 7b 10 f0       	push   $0xf0107b70
f0100ba1:	e8 0e 4b 00 00       	call   f01056b4 <cprintf>
f0100ba6:	83 c4 10             	add    $0x10,%esp
			(end_of_kernel-start_of_kernel+1023)/1024);
	return 0;
f0100ba9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bae:	c9                   	leave  
f0100baf:	c3                   	ret    

f0100bb0 <command_readmem>:


/*DON'T change this function*/
int command_readmem(int number_of_arguments, char **arguments)
{
f0100bb0:	55                   	push   %ebp
f0100bb1:	89 e5                	mov    %esp,%ebp
f0100bb3:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100bb6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bb9:	83 c0 04             	add    $0x4,%eax
f0100bbc:	8b 00                	mov    (%eax),%eax
f0100bbe:	83 ec 04             	sub    $0x4,%esp
f0100bc1:	6a 10                	push   $0x10
f0100bc3:	6a 00                	push   $0x0
f0100bc5:	50                   	push   %eax
f0100bc6:	e8 3e 63 00 00       	call   f0106f09 <strtol>
f0100bcb:	83 c4 10             	add    $0x10,%esp
f0100bce:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address ) ;
f0100bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100bd4:	89 45 f0             	mov    %eax,-0x10(%ebp)

	cprintf("value at address %x = %c\n", ptr, *ptr);
f0100bd7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bda:	8a 00                	mov    (%eax),%al
f0100bdc:	0f b6 c0             	movzbl %al,%eax
f0100bdf:	83 ec 04             	sub    $0x4,%esp
f0100be2:	50                   	push   %eax
f0100be3:	ff 75 f0             	pushl  -0x10(%ebp)
f0100be6:	68 9b 7b 10 f0       	push   $0xf0107b9b
f0100beb:	e8 c4 4a 00 00       	call   f01056b4 <cprintf>
f0100bf0:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100bf3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bf8:	c9                   	leave  
f0100bf9:	c3                   	ret    

f0100bfa <command_writemem>:

/*DON'T change this function*/
int command_writemem(int number_of_arguments, char **arguments)
{
f0100bfa:	55                   	push   %ebp
f0100bfb:	89 e5                	mov    %esp,%ebp
f0100bfd:	83 ec 18             	sub    $0x18,%esp
	unsigned int address = strtol(arguments[1], NULL, 16);
f0100c00:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c03:	83 c0 04             	add    $0x4,%eax
f0100c06:	8b 00                	mov    (%eax),%eax
f0100c08:	83 ec 04             	sub    $0x4,%esp
f0100c0b:	6a 10                	push   $0x10
f0100c0d:	6a 00                	push   $0x0
f0100c0f:	50                   	push   %eax
f0100c10:	e8 f4 62 00 00       	call   f0106f09 <strtol>
f0100c15:	83 c4 10             	add    $0x10,%esp
f0100c18:	89 45 f4             	mov    %eax,-0xc(%ebp)
	unsigned char *ptr = (unsigned char *)(address) ;
f0100c1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c1e:	89 45 f0             	mov    %eax,-0x10(%ebp)

	*ptr = arguments[2][0];
f0100c21:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c24:	83 c0 08             	add    $0x8,%eax
f0100c27:	8b 00                	mov    (%eax),%eax
f0100c29:	8a 00                	mov    (%eax),%al
f0100c2b:	88 c2                	mov    %al,%dl
f0100c2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c30:	88 10                	mov    %dl,(%eax)

	return 0;
f0100c32:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c37:	c9                   	leave  
f0100c38:	c3                   	ret    

f0100c39 <command_meminfo>:

/*DON'T change this function*/
int command_meminfo(int number_of_arguments, char **arguments)
{
f0100c39:	55                   	push   %ebp
f0100c3a:	89 e5                	mov    %esp,%ebp
f0100c3c:	83 ec 08             	sub    $0x8,%esp
	cprintf("Free frames = %d\n", calculate_free_frames());
f0100c3f:	e8 80 41 00 00       	call   f0104dc4 <calculate_free_frames>
f0100c44:	83 ec 08             	sub    $0x8,%esp
f0100c47:	50                   	push   %eax
f0100c48:	68 b5 7b 10 f0       	push   $0xf0107bb5
f0100c4d:	e8 62 4a 00 00       	call   f01056b4 <cprintf>
f0100c52:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c5a:	c9                   	leave  
f0100c5b:	c3                   	ret    

f0100c5c <command_ver>:
//===========================================================================
//Lab1 Examples
//=============
/*DON'T change this function*/
int command_ver(int number_of_arguments, char **arguments)
{
f0100c5c:	55                   	push   %ebp
f0100c5d:	89 e5                	mov    %esp,%ebp
f0100c5f:	83 ec 08             	sub    $0x8,%esp
	cprintf("FOS version 0.1\n") ;
f0100c62:	83 ec 0c             	sub    $0xc,%esp
f0100c65:	68 c7 7b 10 f0       	push   $0xf0107bc7
f0100c6a:	e8 45 4a 00 00       	call   f01056b4 <cprintf>
f0100c6f:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100c72:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c77:	c9                   	leave  
f0100c78:	c3                   	ret    

f0100c79 <command_add>:

/*DON'T change this function*/
int command_add(int number_of_arguments, char **arguments)
{
f0100c79:	55                   	push   %ebp
f0100c7a:	89 e5                	mov    %esp,%ebp
f0100c7c:	83 ec 18             	sub    $0x18,%esp
	int n1 = strtol(arguments[1], NULL, 10);
f0100c7f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c82:	83 c0 04             	add    $0x4,%eax
f0100c85:	8b 00                	mov    (%eax),%eax
f0100c87:	83 ec 04             	sub    $0x4,%esp
f0100c8a:	6a 0a                	push   $0xa
f0100c8c:	6a 00                	push   $0x0
f0100c8e:	50                   	push   %eax
f0100c8f:	e8 75 62 00 00       	call   f0106f09 <strtol>
f0100c94:	83 c4 10             	add    $0x10,%esp
f0100c97:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int n2 = strtol(arguments[2], NULL, 10);
f0100c9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c9d:	83 c0 08             	add    $0x8,%eax
f0100ca0:	8b 00                	mov    (%eax),%eax
f0100ca2:	83 ec 04             	sub    $0x4,%esp
f0100ca5:	6a 0a                	push   $0xa
f0100ca7:	6a 00                	push   $0x0
f0100ca9:	50                   	push   %eax
f0100caa:	e8 5a 62 00 00       	call   f0106f09 <strtol>
f0100caf:	83 c4 10             	add    $0x10,%esp
f0100cb2:	89 45 f0             	mov    %eax,-0x10(%ebp)

	int res = n1 + n2 ;
f0100cb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100cb8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cbb:	01 d0                	add    %edx,%eax
f0100cbd:	89 45 ec             	mov    %eax,-0x14(%ebp)
	cprintf("res=%d\n", res);
f0100cc0:	83 ec 08             	sub    $0x8,%esp
f0100cc3:	ff 75 ec             	pushl  -0x14(%ebp)
f0100cc6:	68 d8 7b 10 f0       	push   $0xf0107bd8
f0100ccb:	e8 e4 49 00 00       	call   f01056b4 <cprintf>
f0100cd0:	83 c4 10             	add    $0x10,%esp

	return 0;
f0100cd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cd8:	c9                   	leave  
f0100cd9:	c3                   	ret    

f0100cda <command_show_mapping>:

//===========================================================================
//Lab4.Hands.On
//=============
int command_show_mapping(int number_of_arguments, char **arguments)
{
f0100cda:	55                   	push   %ebp
f0100cdb:	89 e5                	mov    %esp,%ebp
f0100cdd:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sm"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100ce0:	83 ec 04             	sub    $0x4,%esp
f0100ce3:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100ce8:	68 3f 01 00 00       	push   $0x13f
f0100ced:	68 01 7c 10 f0       	push   $0xf0107c01
f0100cf2:	e8 37 f4 ff ff       	call   f010012e <_panic>

f0100cf7 <command_set_permission>:

	return 0 ;
}

int command_set_permission(int number_of_arguments, char **arguments)
{
f0100cf7:	55                   	push   %ebp
f0100cf8:	89 e5                	mov    %esp,%ebp
f0100cfa:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100cfd:	83 ec 04             	sub    $0x4,%esp
f0100d00:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d05:	68 48 01 00 00       	push   $0x148
f0100d0a:	68 01 7c 10 f0       	push   $0xf0107c01
f0100d0f:	e8 1a f4 ff ff       	call   f010012e <_panic>

f0100d14 <command_share_range>:

	return 0 ;
}

int command_share_range(int number_of_arguments, char **arguments)
{
f0100d14:	55                   	push   %ebp
f0100d15:	89 e5                	mov    %esp,%ebp
f0100d17:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB4 Hands-on: fill this function. corresponding command name is "sr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d1a:	83 ec 04             	sub    $0x4,%esp
f0100d1d:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d22:	68 51 01 00 00       	push   $0x151
f0100d27:	68 01 7c 10 f0       	push   $0xf0107c01
f0100d2c:	e8 fd f3 ff ff       	call   f010012e <_panic>

f0100d31 <command_nr>:
//===========================================================================
//Lab5.Examples
//==============
//[1] Number of references on the given physical address
int command_nr(int number_of_arguments, char **arguments)
{
f0100d31:	55                   	push   %ebp
f0100d32:	89 e5                	mov    %esp,%ebp
f0100d34:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "nr"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d37:	83 ec 04             	sub    $0x4,%esp
f0100d3a:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d3f:	68 5e 01 00 00       	push   $0x15e
f0100d44:	68 01 7c 10 f0       	push   $0xf0107c01
f0100d49:	e8 e0 f3 ff ff       	call   f010012e <_panic>

f0100d4e <command_ap>:
	return 0;
}

//[2] Allocate Page: If the given user virtual address is mapped, do nothing. Else, allocate a single frame and map it to a given virtual address in the user space
int command_ap(int number_of_arguments, char **arguments)
{
f0100d4e:	55                   	push   %ebp
f0100d4f:	89 e5                	mov    %esp,%ebp
f0100d51:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "ap"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d54:	83 ec 04             	sub    $0x4,%esp
f0100d57:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d5c:	68 68 01 00 00       	push   $0x168
f0100d61:	68 01 7c 10 f0       	push   $0xf0107c01
f0100d66:	e8 c3 f3 ff ff       	call   f010012e <_panic>

f0100d6b <command_fp>:
	return 0 ;
}

//[3] Free Page: Un-map a single page at the given virtual address in the user space
int command_fp(int number_of_arguments, char **arguments)
{
f0100d6b:	55                   	push   %ebp
f0100d6c:	89 e5                	mov    %esp,%ebp
f0100d6e:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Example: fill this function. corresponding command name is "fp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d71:	83 ec 04             	sub    $0x4,%esp
f0100d74:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d79:	68 72 01 00 00       	push   $0x172
f0100d7e:	68 01 7c 10 f0       	push   $0xf0107c01
f0100d83:	e8 a6 f3 ff ff       	call   f010012e <_panic>

f0100d88 <command_asp>:
//===========================================================================
//Lab5.Hands-on
//==============
//[1] Allocate Shared Pages
int command_asp(int number_of_arguments, char **arguments)
{
f0100d88:	55                   	push   %ebp
f0100d89:	89 e5                	mov    %esp,%ebp
f0100d8b:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "asp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100d8e:	83 ec 04             	sub    $0x4,%esp
f0100d91:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100d96:	68 7f 01 00 00       	push   $0x17f
f0100d9b:	68 01 7c 10 f0       	push   $0xf0107c01
f0100da0:	e8 89 f3 ff ff       	call   f010012e <_panic>

f0100da5 <command_cfp>:
}


//[2] Count Free Pages in Range
int command_cfp(int number_of_arguments, char **arguments)
{
f0100da5:	55                   	push   %ebp
f0100da6:	89 e5                	mov    %esp,%ebp
f0100da8:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB5 Hands-on: fill this function. corresponding command name is "cfp"
	//Comment the following line
	panic("Function is not implemented yet!");
f0100dab:	83 ec 04             	sub    $0x4,%esp
f0100dae:	68 e0 7b 10 f0       	push   $0xf0107be0
f0100db3:	68 8a 01 00 00       	push   $0x18a
f0100db8:	68 01 7c 10 f0       	push   $0xf0107c01
f0100dbd:	e8 6c f3 ff ff       	call   f010012e <_panic>

f0100dc2 <command_run>:
//===========================================================================
//Lab6.Examples
//=============
/*DON'T change this function*/
int command_run(int number_of_arguments, char **arguments)
{
f0100dc2:	55                   	push   %ebp
f0100dc3:	89 e5                	mov    %esp,%ebp
f0100dc5:	83 ec 18             	sub    $0x18,%esp
	//[1] Create and initialize a new environment for the program to be run
	struct UserProgramInfo* ptr_program_info = env_create(arguments[1]);
f0100dc8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100dcb:	83 c0 04             	add    $0x4,%eax
f0100dce:	8b 00                	mov    (%eax),%eax
f0100dd0:	83 ec 0c             	sub    $0xc,%esp
f0100dd3:	50                   	push   %eax
f0100dd4:	e8 c4 40 00 00       	call   f0104e9d <env_create>
f0100dd9:	83 c4 10             	add    $0x10,%esp
f0100ddc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0100ddf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100de3:	75 07                	jne    f0100dec <command_run+0x2a>
f0100de5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dea:	eb 0f                	jmp    f0100dfb <command_run+0x39>

	//[2] Run the created environment using "env_run" function
	env_run(ptr_program_info->environment);
f0100dec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100def:	8b 40 0c             	mov    0xc(%eax),%eax
f0100df2:	83 ec 0c             	sub    $0xc,%esp
f0100df5:	50                   	push   %eax
f0100df6:	e8 11 41 00 00       	call   f0104f0c <env_run>
	return 0;
}
f0100dfb:	c9                   	leave  
f0100dfc:	c3                   	ret    

f0100dfd <command_kill>:

/*DON'T change this function*/
int command_kill(int number_of_arguments, char **arguments)
{
f0100dfd:	55                   	push   %ebp
f0100dfe:	89 e5                	mov    %esp,%ebp
f0100e00:	83 ec 18             	sub    $0x18,%esp
	//[1] Get the user program info of the program (by searching in the "userPrograms" array
	struct UserProgramInfo* ptr_program_info = get_user_program_info(arguments[1]) ;
f0100e03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e06:	83 c0 04             	add    $0x4,%eax
f0100e09:	8b 00                	mov    (%eax),%eax
f0100e0b:	83 ec 0c             	sub    $0xc,%esp
f0100e0e:	50                   	push   %eax
f0100e0f:	e8 c9 45 00 00       	call   f01053dd <get_user_program_info>
f0100e14:	83 c4 10             	add    $0x10,%esp
f0100e17:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(ptr_program_info == 0) return 0;
f0100e1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0100e1e:	75 07                	jne    f0100e27 <command_kill+0x2a>
f0100e20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e25:	eb 21                	jmp    f0100e48 <command_kill+0x4b>

	//[2] Kill its environment using "env_free" function
	env_free(ptr_program_info->environment);
f0100e27:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e2a:	8b 40 0c             	mov    0xc(%eax),%eax
f0100e2d:	83 ec 0c             	sub    $0xc,%esp
f0100e30:	50                   	push   %eax
f0100e31:	e8 19 41 00 00       	call   f0104f4f <env_free>
f0100e36:	83 c4 10             	add    $0x10,%esp
	ptr_program_info->environment = NULL;
f0100e39:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e3c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	return 0;
f0100e43:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e48:	c9                   	leave  
f0100e49:	c3                   	ret    

f0100e4a <command_ft>:

int command_ft(int number_of_arguments, char **arguments)
{
f0100e4a:	55                   	push   %ebp
f0100e4b:	89 e5                	mov    %esp,%ebp
	//TODO: LAB6 Example: fill this function. corresponding command name is "ft"
	//Comment the following line

	return 0;
f0100e4d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e52:	5d                   	pop    %ebp
f0100e53:	c3                   	ret    

f0100e54 <command_cnia>:
//========================================================
//Q1:Create Named Int Array
//=========================
/*DON'T change this function*/
int command_cnia(int number_of_arguments, char **arguments )
{
f0100e54:	55                   	push   %ebp
f0100e55:	89 e5                	mov    %esp,%ebp
f0100e57:	83 ec 08             	sub    $0x8,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CreateIntArray() FUNCTION
	CreateIntArray(number_of_arguments, arguments);
f0100e5a:	83 ec 08             	sub    $0x8,%esp
f0100e5d:	ff 75 0c             	pushl  0xc(%ebp)
f0100e60:	ff 75 08             	pushl  0x8(%ebp)
f0100e63:	e8 0a 00 00 00       	call   f0100e72 <CreateIntArray>
f0100e68:	83 c4 10             	add    $0x10,%esp
	return 0;
f0100e6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e70:	c9                   	leave  
f0100e71:	c3                   	ret    

f0100e72 <CreateIntArray>:
 * arguments	[1]	[2]	[3]	...
 * Create integer array named "x", with 5 elements: 10, 20, 30, 0, 0
 * It should return the start address of the FIRST ELEMENT in the created array
 */
int* CreateIntArray(int numOfArgs, char** arguments)
{
f0100e72:	55                   	push   %ebp
f0100e73:	89 e5                	mov    %esp,%ebp
f0100e75:	53                   	push   %ebx
f0100e76:	83 ec 24             	sub    $0x24,%esp
	  int offset = 0;
f0100e79:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	 strcpy(arrays[count].name,arguments[1]) ;
f0100e80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e83:	83 c0 04             	add    $0x4,%eax
f0100e86:	8b 08                	mov    (%eax),%ecx
f0100e88:	8b 15 6c 3f 15 f0    	mov    0xf0153f6c,%edx
f0100e8e:	89 d0                	mov    %edx,%eax
f0100e90:	01 c0                	add    %eax,%eax
f0100e92:	01 d0                	add    %edx,%eax
f0100e94:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f0100e9b:	01 d8                	add    %ebx,%eax
f0100e9d:	01 d0                	add    %edx,%eax
f0100e9f:	05 00 48 15 f0       	add    $0xf0154800,%eax
f0100ea4:	83 ec 08             	sub    $0x8,%esp
f0100ea7:	51                   	push   %ecx
f0100ea8:	50                   	push   %eax
f0100ea9:	e8 4a 5d 00 00       	call   f0106bf8 <strcpy>
f0100eae:	83 c4 10             	add    $0x10,%esp
     arrays[count].size=strtol(arguments[2], NULL, 10);
f0100eb1:	8b 1d 6c 3f 15 f0    	mov    0xf0153f6c,%ebx
f0100eb7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eba:	83 c0 08             	add    $0x8,%eax
f0100ebd:	8b 00                	mov    (%eax),%eax
f0100ebf:	83 ec 04             	sub    $0x4,%esp
f0100ec2:	6a 0a                	push   $0xa
f0100ec4:	6a 00                	push   $0x0
f0100ec6:	50                   	push   %eax
f0100ec7:	e8 3d 60 00 00       	call   f0106f09 <strtol>
f0100ecc:	83 c4 10             	add    $0x10,%esp
f0100ecf:	89 c2                	mov    %eax,%edx
f0100ed1:	89 d8                	mov    %ebx,%eax
f0100ed3:	01 c0                	add    %eax,%eax
f0100ed5:	01 d8                	add    %ebx,%eax
f0100ed7:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100ede:	01 c8                	add    %ecx,%eax
f0100ee0:	01 d8                	add    %ebx,%eax
f0100ee2:	05 14 48 15 f0       	add    $0xf0154814,%eax
f0100ee7:	89 10                	mov    %edx,(%eax)
     int* ptrToInt= (int*)intArrAddress;
f0100ee9:	a1 40 15 12 f0       	mov    0xf0121540,%eax
f0100eee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
     int counterLoc=0;
f0100ef1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
     int newCounter=0;
f0100ef8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
     while (*(arguments + offset) != '\0')
f0100eff:	eb 06                	jmp    f0100f07 <CreateIntArray+0x95>
      {
          ++counterLoc;
f0100f01:	ff 45 f0             	incl   -0x10(%ebp)
          ++offset;
f0100f04:	ff 45 f4             	incl   -0xc(%ebp)
	 strcpy(arrays[count].name,arguments[1]) ;
     arrays[count].size=strtol(arguments[2], NULL, 10);
     int* ptrToInt= (int*)intArrAddress;
     int counterLoc=0;
     int newCounter=0;
     while (*(arguments + offset) != '\0')
f0100f07:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0100f11:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f14:	01 d0                	add    %edx,%eax
f0100f16:	8b 00                	mov    (%eax),%eax
f0100f18:	85 c0                	test   %eax,%eax
f0100f1a:	75 e5                	jne    f0100f01 <CreateIntArray+0x8f>
      {
          ++counterLoc;
          ++offset;
      }
     newCounter  = counterLoc-3;
f0100f1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f1f:	83 e8 03             	sub    $0x3,%eax
f0100f22:	89 45 e0             	mov    %eax,-0x20(%ebp)
     int x=strtol(arguments[2],NULL,10);
f0100f25:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f28:	83 c0 08             	add    $0x8,%eax
f0100f2b:	8b 00                	mov    (%eax),%eax
f0100f2d:	83 ec 04             	sub    $0x4,%esp
f0100f30:	6a 0a                	push   $0xa
f0100f32:	6a 00                	push   $0x0
f0100f34:	50                   	push   %eax
f0100f35:	e8 cf 5f 00 00       	call   f0106f09 <strtol>
f0100f3a:	83 c4 10             	add    $0x10,%esp
f0100f3d:	89 45 dc             	mov    %eax,-0x24(%ebp)
     char *ptrr;
     int tottal_index =x-newCounter;
f0100f40:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f43:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100f46:	89 45 d8             	mov    %eax,-0x28(%ebp)

     for(int i=3;i<newCounter+3;i++){
f0100f49:	c7 45 ec 03 00 00 00 	movl   $0x3,-0x14(%ebp)
f0100f50:	eb 39                	jmp    f0100f8b <CreateIntArray+0x119>

    	*intArrAddress =strtol(arguments[i],NULL,10);
f0100f52:	8b 1d 40 15 12 f0    	mov    0xf0121540,%ebx
f0100f58:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f5b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0100f62:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f65:	01 d0                	add    %edx,%eax
f0100f67:	8b 00                	mov    (%eax),%eax
f0100f69:	83 ec 04             	sub    $0x4,%esp
f0100f6c:	6a 0a                	push   $0xa
f0100f6e:	6a 00                	push   $0x0
f0100f70:	50                   	push   %eax
f0100f71:	e8 93 5f 00 00       	call   f0106f09 <strtol>
f0100f76:	83 c4 10             	add    $0x10,%esp
f0100f79:	89 03                	mov    %eax,(%ebx)
    	 intArrAddress++;
f0100f7b:	a1 40 15 12 f0       	mov    0xf0121540,%eax
f0100f80:	83 c0 04             	add    $0x4,%eax
f0100f83:	a3 40 15 12 f0       	mov    %eax,0xf0121540
     newCounter  = counterLoc-3;
     int x=strtol(arguments[2],NULL,10);
     char *ptrr;
     int tottal_index =x-newCounter;

     for(int i=3;i<newCounter+3;i++){
f0100f88:	ff 45 ec             	incl   -0x14(%ebp)
f0100f8b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f8e:	83 c0 03             	add    $0x3,%eax
f0100f91:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f0100f94:	7f bc                	jg     f0100f52 <CreateIntArray+0xe0>

    	*intArrAddress =strtol(arguments[i],NULL,10);
    	 intArrAddress++;
     }
     int k=0;
f0100f96:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
    while(k<tottal_index){
f0100f9d:	eb 21                	jmp    f0100fc0 <CreateIntArray+0x14e>
         if(tottal_index>0){
f0100f9f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fa3:	7e 18                	jle    f0100fbd <CreateIntArray+0x14b>
         		*intArrAddress=0;
f0100fa5:	a1 40 15 12 f0       	mov    0xf0121540,%eax
f0100faa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
         		intArrAddress++;
f0100fb0:	a1 40 15 12 f0       	mov    0xf0121540,%eax
f0100fb5:	83 c0 04             	add    $0x4,%eax
f0100fb8:	a3 40 15 12 f0       	mov    %eax,0xf0121540
         	}
         k++;
f0100fbd:	ff 45 e8             	incl   -0x18(%ebp)

    	*intArrAddress =strtol(arguments[i],NULL,10);
    	 intArrAddress++;
     }
     int k=0;
    while(k<tottal_index){
f0100fc0:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100fc3:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100fc6:	7c d7                	jl     f0100f9f <CreateIntArray+0x12d>
         		*intArrAddress=0;
         		intArrAddress++;
         	}
         k++;
     }
     arrays[count].ptr=ptrToInt;
f0100fc8:	8b 15 6c 3f 15 f0    	mov    0xf0153f6c,%edx
f0100fce:	89 d0                	mov    %edx,%eax
f0100fd0:	01 c0                	add    %eax,%eax
f0100fd2:	01 d0                	add    %edx,%eax
f0100fd4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100fdb:	01 c8                	add    %ecx,%eax
f0100fdd:	01 d0                	add    %edx,%eax
f0100fdf:	8d 90 18 48 15 f0    	lea    -0xfeab7e8(%eax),%edx
f0100fe5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fe8:	89 02                	mov    %eax,(%edx)
    count++;
f0100fea:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0100fef:	40                   	inc    %eax
f0100ff0:	a3 6c 3f 15 f0       	mov    %eax,0xf0153f6c
    return ptrToInt;
f0100ff5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
f0100ff8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ffb:	c9                   	leave  
f0100ffc:	c3                   	ret    

f0100ffd <command_ces>:

//Q2:Copy Elements from One Array to Another
//==========================================
/*DON'T change this function*/
int command_ces(int number_of_arguments, char **arguments )
{
f0100ffd:	55                   	push   %ebp
f0100ffe:	89 e5                	mov    %esp,%ebp
f0101000:	83 ec 08             	sub    $0x8,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CopyElements() FUNCTION
	CopyElements(arguments) ;
f0101003:	83 ec 0c             	sub    $0xc,%esp
f0101006:	ff 75 0c             	pushl  0xc(%ebp)
f0101009:	e8 0a 00 00 00       	call   f0101018 <CopyElements>
f010100e:	83 c4 10             	add    $0x10,%esp
	return 0;
f0101011:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101016:	c9                   	leave  
f0101017:	c3                   	ret    

f0101018 <CopyElements>:
 * arguments[3]: start index in the source array
 * arguments[4]: start index in the destination array
 * arguments[5]: number of elements to be copied
 */
void CopyElements(char** arguments)
{
f0101018:	55                   	push   %ebp
f0101019:	89 e5                	mov    %esp,%ebp
f010101b:	53                   	push   %ebx
f010101c:	83 ec 74             	sub    $0x74,%esp
	//...

	int coppied_array[MAX_ARGUMENTS];
	int requested_position;
	int requested_destination;
	for(int i=0;i<count;i++){
f010101f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
f0101026:	eb 3b                	jmp    f0101063 <CopyElements+0x4b>

		if(strcmp(arrays[i].name, arguments[1])==0){
f0101028:	8b 45 08             	mov    0x8(%ebp),%eax
f010102b:	83 c0 04             	add    $0x4,%eax
f010102e:	8b 08                	mov    (%eax),%ecx
f0101030:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101033:	89 d0                	mov    %edx,%eax
f0101035:	01 c0                	add    %eax,%eax
f0101037:	01 d0                	add    %edx,%eax
f0101039:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f0101040:	01 d8                	add    %ebx,%eax
f0101042:	01 d0                	add    %edx,%eax
f0101044:	05 00 48 15 f0       	add    $0xf0154800,%eax
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	51                   	push   %ecx
f010104d:	50                   	push   %eax
f010104e:	e8 62 5c 00 00       	call   f0106cb5 <strcmp>
f0101053:	83 c4 10             	add    $0x10,%esp
f0101056:	85 c0                	test   %eax,%eax
f0101058:	75 06                	jne    f0101060 <CopyElements+0x48>
			requested_position=i;
f010105a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010105d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//...

	int coppied_array[MAX_ARGUMENTS];
	int requested_position;
	int requested_destination;
	for(int i=0;i<count;i++){
f0101060:	ff 45 ec             	incl   -0x14(%ebp)
f0101063:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0101068:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f010106b:	7c bb                	jl     f0101028 <CopyElements+0x10>
			requested_position=i;
		}
	}


	for(int i=0;i<count;i++){
f010106d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f0101074:	eb 3e                	jmp    f01010b4 <CopyElements+0x9c>
		if(strcmp(arguments[2],arrays[i].name)==0){
f0101076:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101079:	89 d0                	mov    %edx,%eax
f010107b:	01 c0                	add    %eax,%eax
f010107d:	01 d0                	add    %edx,%eax
f010107f:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101086:	01 c8                	add    %ecx,%eax
f0101088:	01 d0                	add    %edx,%eax
f010108a:	8d 90 00 48 15 f0    	lea    -0xfeab800(%eax),%edx
f0101090:	8b 45 08             	mov    0x8(%ebp),%eax
f0101093:	83 c0 08             	add    $0x8,%eax
f0101096:	8b 00                	mov    (%eax),%eax
f0101098:	83 ec 08             	sub    $0x8,%esp
f010109b:	52                   	push   %edx
f010109c:	50                   	push   %eax
f010109d:	e8 13 5c 00 00       	call   f0106cb5 <strcmp>
f01010a2:	83 c4 10             	add    $0x10,%esp
f01010a5:	85 c0                	test   %eax,%eax
f01010a7:	75 08                	jne    f01010b1 <CopyElements+0x99>
			requested_destination=i;
f01010a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01010ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
			break;
f01010af:	eb 0d                	jmp    f01010be <CopyElements+0xa6>
			requested_position=i;
		}
	}


	for(int i=0;i<count;i++){
f01010b1:	ff 45 e8             	incl   -0x18(%ebp)
f01010b4:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f01010b9:	39 45 e8             	cmp    %eax,-0x18(%ebp)
f01010bc:	7c b8                	jl     f0101076 <CopyElements+0x5e>
		}else{

			continue;
		}
	}
	  int *destPtr =arrays[requested_destination].ptr;
f01010be:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01010c1:	89 d0                	mov    %edx,%eax
f01010c3:	01 c0                	add    %eax,%eax
f01010c5:	01 d0                	add    %edx,%eax
f01010c7:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01010ce:	01 c8                	add    %ecx,%eax
f01010d0:	01 d0                	add    %edx,%eax
f01010d2:	05 18 48 15 f0       	add    $0xf0154818,%eax
f01010d7:	8b 00                	mov    (%eax),%eax
f01010d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)



	  int *pttr = arrays[requested_position].ptr;
f01010dc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01010df:	89 d0                	mov    %edx,%eax
f01010e1:	01 c0                	add    %eax,%eax
f01010e3:	01 d0                	add    %edx,%eax
f01010e5:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01010ec:	01 c8                	add    %ecx,%eax
f01010ee:	01 d0                	add    %edx,%eax
f01010f0:	05 18 48 15 f0       	add    $0xf0154818,%eax
f01010f5:	8b 00                	mov    (%eax),%eax
f01010f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	  for(int j=0;j<arrays[requested_position].size;j++){
f01010fa:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101101:	eb 1b                	jmp    f010111e <CopyElements+0x106>
		  coppied_array[j]=pttr[j];
f0101103:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101106:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010110d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101110:	01 d0                	add    %edx,%eax
f0101112:	8b 10                	mov    (%eax),%edx
f0101114:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101117:	89 54 85 94          	mov    %edx,-0x6c(%ebp,%eax,4)
	  int *destPtr =arrays[requested_destination].ptr;



	  int *pttr = arrays[requested_position].ptr;
	  for(int j=0;j<arrays[requested_position].size;j++){
f010111b:	ff 45 e0             	incl   -0x20(%ebp)
f010111e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101121:	89 d0                	mov    %edx,%eax
f0101123:	01 c0                	add    %eax,%eax
f0101125:	01 d0                	add    %edx,%eax
f0101127:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f010112e:	01 c8                	add    %ecx,%eax
f0101130:	01 d0                	add    %edx,%eax
f0101132:	05 14 48 15 f0       	add    $0xf0154814,%eax
f0101137:	8b 00                	mov    (%eax),%eax
f0101139:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f010113c:	7f c5                	jg     f0101103 <CopyElements+0xeb>
		  coppied_array[j]=pttr[j];
	  }
	  destPtr+=strtol(arguments[4], NULL, 10);
f010113e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101141:	83 c0 10             	add    $0x10,%eax
f0101144:	8b 00                	mov    (%eax),%eax
f0101146:	83 ec 04             	sub    $0x4,%esp
f0101149:	6a 0a                	push   $0xa
f010114b:	6a 00                	push   $0x0
f010114d:	50                   	push   %eax
f010114e:	e8 b6 5d 00 00       	call   f0106f09 <strtol>
f0101153:	83 c4 10             	add    $0x10,%esp
f0101156:	c1 e0 02             	shl    $0x2,%eax
f0101159:	01 45 e4             	add    %eax,-0x1c(%ebp)
	  int requestedSize = strtol(arguments[5], NULL, 10);
f010115c:	8b 45 08             	mov    0x8(%ebp),%eax
f010115f:	83 c0 14             	add    $0x14,%eax
f0101162:	8b 00                	mov    (%eax),%eax
f0101164:	83 ec 04             	sub    $0x4,%esp
f0101167:	6a 0a                	push   $0xa
f0101169:	6a 00                	push   $0x0
f010116b:	50                   	push   %eax
f010116c:	e8 98 5d 00 00       	call   f0106f09 <strtol>
f0101171:	83 c4 10             	add    $0x10,%esp
f0101174:	89 45 dc             	mov    %eax,-0x24(%ebp)
	  int i=strtol(arguments[3], NULL, 10);
f0101177:	8b 45 08             	mov    0x8(%ebp),%eax
f010117a:	83 c0 0c             	add    $0xc,%eax
f010117d:	8b 00                	mov    (%eax),%eax
f010117f:	83 ec 04             	sub    $0x4,%esp
f0101182:	6a 0a                	push   $0xa
f0101184:	6a 00                	push   $0x0
f0101186:	50                   	push   %eax
f0101187:	e8 7d 5d 00 00       	call   f0106f09 <strtol>
f010118c:	83 c4 10             	add    $0x10,%esp
f010118f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	while(requestedSize--){
f0101192:	eb 13                	jmp    f01011a7 <CopyElements+0x18f>
		*destPtr=coppied_array[i];
f0101194:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101197:	8b 54 85 94          	mov    -0x6c(%ebp,%eax,4),%edx
f010119b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010119e:	89 10                	mov    %edx,(%eax)
		i++;
f01011a0:	ff 45 d8             	incl   -0x28(%ebp)
		destPtr++;
f01011a3:	83 45 e4 04          	addl   $0x4,-0x1c(%ebp)
		  coppied_array[j]=pttr[j];
	  }
	  destPtr+=strtol(arguments[4], NULL, 10);
	  int requestedSize = strtol(arguments[5], NULL, 10);
	  int i=strtol(arguments[3], NULL, 10);
	while(requestedSize--){
f01011a7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011aa:	8d 50 ff             	lea    -0x1(%eax),%edx
f01011ad:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	75 e0                	jne    f0101194 <CopyElements+0x17c>
		*destPtr=coppied_array[i];
		i++;
		destPtr++;
	}
}
f01011b4:	90                   	nop
f01011b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011b8:	c9                   	leave  
f01011b9:	c3                   	ret    

f01011ba <command_fia>:

//Q3:Find Element in the Array
//============================
/*DON'T change this function*/
int command_fia(int number_of_arguments, char **arguments )
{
f01011ba:	55                   	push   %ebp
f01011bb:	89 e5                	mov    %esp,%ebp
f01011bd:	83 ec 18             	sub    $0x18,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE FindInArray() FUNCTION
	int itemLoc = FindElementInArray(arguments) ;
f01011c0:	83 ec 0c             	sub    $0xc,%esp
f01011c3:	ff 75 0c             	pushl  0xc(%ebp)
f01011c6:	e8 38 00 00 00       	call   f0101203 <FindElementInArray>
f01011cb:	83 c4 10             	add    $0x10,%esp
f01011ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (itemLoc != -1)
f01011d1:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
f01011d5:	74 15                	je     f01011ec <command_fia+0x32>
	{
		cprintf("Item is found @ %d\n", itemLoc) ;
f01011d7:	83 ec 08             	sub    $0x8,%esp
f01011da:	ff 75 f4             	pushl  -0xc(%ebp)
f01011dd:	68 17 7c 10 f0       	push   $0xf0107c17
f01011e2:	e8 cd 44 00 00       	call   f01056b4 <cprintf>
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	eb 10                	jmp    f01011fc <command_fia+0x42>
	}
	else
	{
		cprintf("Item not found\n");
f01011ec:	83 ec 0c             	sub    $0xc,%esp
f01011ef:	68 2b 7c 10 f0       	push   $0xf0107c2b
f01011f4:	e8 bb 44 00 00       	call   f01056b4 <cprintf>
f01011f9:	83 c4 10             	add    $0x10,%esp
	}
	return 0;
f01011fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101201:	c9                   	leave  
f0101202:	c3                   	ret    

f0101203 <FindElementInArray>:
 * 		If array doesn't exist, return -1
 * 		Else If Item is Found: return item index
 * 		Else: return -1
 */
int FindElementInArray(char** arguments)
{
f0101203:	55                   	push   %ebp
f0101204:	89 e5                	mov    %esp,%ebp
f0101206:	53                   	push   %ebx
f0101207:	83 ec 24             	sub    $0x24,%esp
	//Assignment2.Q3
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
f010120a:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
	int status=1;
f0101211:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	for(int i=0;i<count;i++){
f0101218:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f010121f:	eb 42                	jmp    f0101263 <FindElementInArray+0x60>

		if(strcmp(arrays[i].name, arguments[1])==0){
f0101221:	8b 45 08             	mov    0x8(%ebp),%eax
f0101224:	83 c0 04             	add    $0x4,%eax
f0101227:	8b 08                	mov    (%eax),%ecx
f0101229:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010122c:	89 d0                	mov    %edx,%eax
f010122e:	01 c0                	add    %eax,%eax
f0101230:	01 d0                	add    %edx,%eax
f0101232:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f0101239:	01 d8                	add    %ebx,%eax
f010123b:	01 d0                	add    %edx,%eax
f010123d:	05 00 48 15 f0       	add    $0xf0154800,%eax
f0101242:	83 ec 08             	sub    $0x8,%esp
f0101245:	51                   	push   %ecx
f0101246:	50                   	push   %eax
f0101247:	e8 69 5a 00 00       	call   f0106cb5 <strcmp>
f010124c:	83 c4 10             	add    $0x10,%esp
f010124f:	85 c0                	test   %eax,%eax
f0101251:	75 0d                	jne    f0101260 <FindElementInArray+0x5d>
			requested_position=i;
f0101253:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101256:	89 45 f4             	mov    %eax,-0xc(%ebp)
			status=0;
f0101259:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
	int status=1;
	for(int i=0;i<count;i++){
f0101260:	ff 45 e8             	incl   -0x18(%ebp)
f0101263:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0101268:	39 45 e8             	cmp    %eax,-0x18(%ebp)
f010126b:	7c b4                	jl     f0101221 <FindElementInArray+0x1e>
		if(strcmp(arrays[i].name, arguments[1])==0){
			requested_position=i;
			status=0;
		}
	}
	if(status==0){
f010126d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0101271:	75 7f                	jne    f01012f2 <FindElementInArray+0xef>
	int *address=arrays[requested_position].ptr;
f0101273:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101276:	89 d0                	mov    %edx,%eax
f0101278:	01 c0                	add    %eax,%eax
f010127a:	01 d0                	add    %edx,%eax
f010127c:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101283:	01 c8                	add    %ecx,%eax
f0101285:	01 d0                	add    %edx,%eax
f0101287:	05 18 48 15 f0       	add    $0xf0154818,%eax
f010128c:	8b 00                	mov    (%eax),%eax
f010128e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for(int i=0;i<arrays[requested_position].size;i++){
f0101291:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101298:	eb 38                	jmp    f01012d2 <FindElementInArray+0xcf>
		if(address[i]==strtol(arguments[2],NULL,10)){
f010129a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010129d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01012a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012a7:	01 d0                	add    %edx,%eax
f01012a9:	8b 18                	mov    (%eax),%ebx
f01012ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ae:	83 c0 08             	add    $0x8,%eax
f01012b1:	8b 00                	mov    (%eax),%eax
f01012b3:	83 ec 04             	sub    $0x4,%esp
f01012b6:	6a 0a                	push   $0xa
f01012b8:	6a 00                	push   $0x0
f01012ba:	50                   	push   %eax
f01012bb:	e8 49 5c 00 00       	call   f0106f09 <strtol>
f01012c0:	83 c4 10             	add    $0x10,%esp
f01012c3:	39 c3                	cmp    %eax,%ebx
f01012c5:	75 08                	jne    f01012cf <FindElementInArray+0xcc>
			requested_destination=i;
f01012c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
			break;
f01012cd:	eb 23                	jmp    f01012f2 <FindElementInArray+0xef>
			status=0;
		}
	}
	if(status==0){
	int *address=arrays[requested_position].ptr;
	for(int i=0;i<arrays[requested_position].size;i++){
f01012cf:	ff 45 e4             	incl   -0x1c(%ebp)
f01012d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012d5:	89 d0                	mov    %edx,%eax
f01012d7:	01 c0                	add    %eax,%eax
f01012d9:	01 d0                	add    %edx,%eax
f01012db:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01012e2:	01 c8                	add    %ecx,%eax
f01012e4:	01 d0                	add    %edx,%eax
f01012e6:	05 14 48 15 f0       	add    $0xf0154814,%eax
f01012eb:	8b 00                	mov    (%eax),%eax
f01012ed:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f01012f0:	7f a8                	jg     f010129a <FindElementInArray+0x97>
			break;
		}
	}
	}

	return requested_destination;
f01012f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f01012f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012f8:	c9                   	leave  
f01012f9:	c3                   	ret    

f01012fa <command_cav>:

//Q4:Calculate Array Variance
//===========================
/*DON'T change this function*/
int command_cav(int number_of_arguments, char **arguments )
{
f01012fa:	55                   	push   %ebp
f01012fb:	89 e5                	mov    %esp,%ebp
f01012fd:	83 ec 18             	sub    $0x18,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE CalcArrVar() FUNCTION
	int var = CalcArrVar(arguments);
f0101300:	83 ec 0c             	sub    $0xc,%esp
f0101303:	ff 75 0c             	pushl  0xc(%ebp)
f0101306:	e8 29 00 00 00       	call   f0101334 <CalcArrVar>
f010130b:	83 c4 10             	add    $0x10,%esp
f010130e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("variance of %s = %d\n", arguments[1], var);
f0101311:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101314:	83 c0 04             	add    $0x4,%eax
f0101317:	8b 00                	mov    (%eax),%eax
f0101319:	83 ec 04             	sub    $0x4,%esp
f010131c:	ff 75 f4             	pushl  -0xc(%ebp)
f010131f:	50                   	push   %eax
f0101320:	68 3b 7c 10 f0       	push   $0xf0107c3b
f0101325:	e8 8a 43 00 00       	call   f01056b4 <cprintf>
f010132a:	83 c4 10             	add    $0x10,%esp
	return 0;
f010132d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101332:	c9                   	leave  
f0101333:	c3                   	ret    

f0101334 <CalcArrVar>:

/*FILL this function
 * arguments[1]: array name
 */
int CalcArrVar(char** arguments)
{
f0101334:	55                   	push   %ebp
f0101335:	89 e5                	mov    %esp,%ebp
f0101337:	53                   	push   %ebx
f0101338:	83 ec 34             	sub    $0x34,%esp
	//TODO: Assignment2.Q4
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
f010133b:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
	int status=1;
f0101342:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
	for(int i=0;i<count;i++){
f0101349:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0101350:	eb 42                	jmp    f0101394 <CalcArrVar+0x60>
		//cprintf("arrays name %p \n",arrays[5].ptr);
		if(strcmp(arrays[i].name, arguments[1])==0){
f0101352:	8b 45 08             	mov    0x8(%ebp),%eax
f0101355:	83 c0 04             	add    $0x4,%eax
f0101358:	8b 08                	mov    (%eax),%ecx
f010135a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010135d:	89 d0                	mov    %edx,%eax
f010135f:	01 c0                	add    %eax,%eax
f0101361:	01 d0                	add    %edx,%eax
f0101363:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f010136a:	01 d8                	add    %ebx,%eax
f010136c:	01 d0                	add    %edx,%eax
f010136e:	05 00 48 15 f0       	add    $0xf0154800,%eax
f0101373:	83 ec 08             	sub    $0x8,%esp
f0101376:	51                   	push   %ecx
f0101377:	50                   	push   %eax
f0101378:	e8 38 59 00 00       	call   f0106cb5 <strcmp>
f010137d:	83 c4 10             	add    $0x10,%esp
f0101380:	85 c0                	test   %eax,%eax
f0101382:	75 0d                	jne    f0101391 <CalcArrVar+0x5d>
			requested_position=i;
f0101384:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101387:	89 45 f4             	mov    %eax,-0xc(%ebp)
			status=0;
f010138a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	//put your logic here
	//...
	int requested_position;
	int requested_destination=-1;
	int status=1;
	for(int i=0;i<count;i++){
f0101391:	ff 45 f0             	incl   -0x10(%ebp)
f0101394:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0101399:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f010139c:	7c b4                	jl     f0101352 <CalcArrVar+0x1e>
			requested_position=i;
			status=0;

		}
	}
	int summisionOfArray=0;
f010139e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	int *address=arrays[requested_position].ptr;
f01013a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01013a8:	89 d0                	mov    %edx,%eax
f01013aa:	01 c0                	add    %eax,%eax
f01013ac:	01 d0                	add    %edx,%eax
f01013ae:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01013b5:	01 c8                	add    %ecx,%eax
f01013b7:	01 d0                	add    %edx,%eax
f01013b9:	05 18 48 15 f0       	add    $0xf0154818,%eax
f01013be:	8b 00                	mov    (%eax),%eax
f01013c0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for(int i=0;i<arrays[requested_position].size;i++){
f01013c3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f01013ca:	eb 17                	jmp    f01013e3 <CalcArrVar+0xaf>
		summisionOfArray+=address[i];
f01013cc:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01013cf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01013d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013d9:	01 d0                	add    %edx,%eax
f01013db:	8b 00                	mov    (%eax),%eax
f01013dd:	01 45 ec             	add    %eax,-0x14(%ebp)

		}
	}
	int summisionOfArray=0;
	int *address=arrays[requested_position].ptr;
	for(int i=0;i<arrays[requested_position].size;i++){
f01013e0:	ff 45 e8             	incl   -0x18(%ebp)
f01013e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01013e6:	89 d0                	mov    %edx,%eax
f01013e8:	01 c0                	add    %eax,%eax
f01013ea:	01 d0                	add    %edx,%eax
f01013ec:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01013f3:	01 c8                	add    %ecx,%eax
f01013f5:	01 d0                	add    %edx,%eax
f01013f7:	05 14 48 15 f0       	add    $0xf0154814,%eax
f01013fc:	8b 00                	mov    (%eax),%eax
f01013fe:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f0101401:	7f c9                	jg     f01013cc <CalcArrVar+0x98>
		summisionOfArray+=address[i];
	}
	int mainCalc = summisionOfArray/arrays[requested_position].size;
f0101403:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101406:	89 d0                	mov    %edx,%eax
f0101408:	01 c0                	add    %eax,%eax
f010140a:	01 d0                	add    %edx,%eax
f010140c:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101413:	01 c8                	add    %ecx,%eax
f0101415:	01 d0                	add    %edx,%eax
f0101417:	05 14 48 15 f0       	add    $0xf0154814,%eax
f010141c:	8b 18                	mov    (%eax),%ebx
f010141e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101421:	99                   	cltd   
f0101422:	f7 fb                	idiv   %ebx
f0101424:	89 45 d0             	mov    %eax,-0x30(%ebp)
	int bVariance=0;
f0101427:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	for(int i=0;i<arrays[requested_position].size;i++){
f010142e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101435:	eb 33                	jmp    f010146a <CalcArrVar+0x136>
		bVariance+=(address[i]-mainCalc)*(address[i]-mainCalc);
f0101437:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010143a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101441:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101444:	01 d0                	add    %edx,%eax
f0101446:	8b 00                	mov    (%eax),%eax
f0101448:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010144b:	89 c2                	mov    %eax,%edx
f010144d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101450:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0101457:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010145a:	01 c8                	add    %ecx,%eax
f010145c:	8b 00                	mov    (%eax),%eax
f010145e:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101461:	0f af c2             	imul   %edx,%eax
f0101464:	01 45 e4             	add    %eax,-0x1c(%ebp)
	for(int i=0;i<arrays[requested_position].size;i++){
		summisionOfArray+=address[i];
	}
	int mainCalc = summisionOfArray/arrays[requested_position].size;
	int bVariance=0;
	for(int i=0;i<arrays[requested_position].size;i++){
f0101467:	ff 45 e0             	incl   -0x20(%ebp)
f010146a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010146d:	89 d0                	mov    %edx,%eax
f010146f:	01 c0                	add    %eax,%eax
f0101471:	01 d0                	add    %edx,%eax
f0101473:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f010147a:	01 c8                	add    %ecx,%eax
f010147c:	01 d0                	add    %edx,%eax
f010147e:	05 14 48 15 f0       	add    $0xf0154814,%eax
f0101483:	8b 00                	mov    (%eax),%eax
f0101485:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101488:	7f ad                	jg     f0101437 <CalcArrVar+0x103>
		bVariance+=(address[i]-mainCalc)*(address[i]-mainCalc);
	}
	int variance = bVariance/arrays[requested_position].size;
f010148a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010148d:	89 d0                	mov    %edx,%eax
f010148f:	01 c0                	add    %eax,%eax
f0101491:	01 d0                	add    %edx,%eax
f0101493:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f010149a:	01 c8                	add    %ecx,%eax
f010149c:	01 d0                	add    %edx,%eax
f010149e:	05 14 48 15 f0       	add    $0xf0154814,%eax
f01014a3:	8b 18                	mov    (%eax),%ebx
f01014a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014a8:	99                   	cltd   
f01014a9:	f7 fb                	idiv   %ebx
f01014ab:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return variance;
f01014ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
}
f01014b1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014b4:	c9                   	leave  
f01014b5:	c3                   	ret    

f01014b6 <command_mta>:
//========================================================
//BONUS: Merge Two Arrays
//=======================
/*DON'T change this function*/
int command_mta(int number_of_arguments, char **arguments )
{
f01014b6:	55                   	push   %ebp
f01014b7:	89 e5                	mov    %esp,%ebp
f01014b9:	83 ec 08             	sub    $0x8,%esp
	//DON'T WRITE YOUR LOGIC HERE, WRITE INSIDE THE MergeTwoArrays() FUNCTION
	MergeTwoArrays(arguments);
f01014bc:	83 ec 0c             	sub    $0xc,%esp
f01014bf:	ff 75 0c             	pushl  0xc(%ebp)
f01014c2:	e8 0a 00 00 00       	call   f01014d1 <MergeTwoArrays>
f01014c7:	83 c4 10             	add    $0x10,%esp
	return 0;
f01014ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014cf:	c9                   	leave  
f01014d0:	c3                   	ret    

f01014d1 <MergeTwoArrays>:
 * arguments[2]: name of the second array to be merged
 * arguments[3]: name of the NEW array
 * After merging the two arrays, they become not accessible anymore [i.e. removed].
 */
void MergeTwoArrays(char** arguments)
{
f01014d1:	55                   	push   %ebp
f01014d2:	89 e5                	mov    %esp,%ebp
f01014d4:	56                   	push   %esi
f01014d5:	53                   	push   %ebx
f01014d6:	83 ec 30             	sub    $0x30,%esp
	//TODO: Assignment2.BONUS
	//put your logic here
	//...
	int*farrPointer;
	int*sarrPointer;
	int*lastArrPointer=arrays[count-1].ptr;
f01014d9:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f01014de:	8d 50 ff             	lea    -0x1(%eax),%edx
f01014e1:	89 d0                	mov    %edx,%eax
f01014e3:	01 c0                	add    %eax,%eax
f01014e5:	01 d0                	add    %edx,%eax
f01014e7:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01014ee:	01 c8                	add    %ecx,%eax
f01014f0:	01 d0                	add    %edx,%eax
f01014f2:	05 18 48 15 f0       	add    $0xf0154818,%eax
f01014f7:	8b 00                	mov    (%eax),%eax
f01014f9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	lastArrPointer+=(arrays[count-1].size*2);
f01014fc:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0101501:	8d 50 ff             	lea    -0x1(%eax),%edx
f0101504:	89 d0                	mov    %edx,%eax
f0101506:	01 c0                	add    %eax,%eax
f0101508:	01 d0                	add    %edx,%eax
f010150a:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101511:	01 c8                	add    %ecx,%eax
f0101513:	01 d0                	add    %edx,%eax
f0101515:	05 14 48 15 f0       	add    $0xf0154814,%eax
f010151a:	8b 00                	mov    (%eax),%eax
f010151c:	c1 e0 03             	shl    $0x3,%eax
f010151f:	01 45 cc             	add    %eax,-0x34(%ebp)
	int *mergedArrayPointer=(int *)lastArrPointer;
f0101522:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101525:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int *scPointer = (int *)lastArrPointer;
f0101528:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010152b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	int firstArraySize=0;
f010152e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
	int secondArraySize=0;
f0101535:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int frstCounter=0;
f010153c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	int scCounter=0;
f0101543:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	for(int i=0;i<count;i++){
f010154a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101551:	e9 ed 00 00 00       	jmp    f0101643 <MergeTwoArrays+0x172>
		if(strcmp(arguments[1],arrays[i].name)==0){
f0101556:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101559:	89 d0                	mov    %edx,%eax
f010155b:	01 c0                	add    %eax,%eax
f010155d:	01 d0                	add    %edx,%eax
f010155f:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101566:	01 c8                	add    %ecx,%eax
f0101568:	01 d0                	add    %edx,%eax
f010156a:	8d 90 00 48 15 f0    	lea    -0xfeab800(%eax),%edx
f0101570:	8b 45 08             	mov    0x8(%ebp),%eax
f0101573:	83 c0 04             	add    $0x4,%eax
f0101576:	8b 00                	mov    (%eax),%eax
f0101578:	83 ec 08             	sub    $0x8,%esp
f010157b:	52                   	push   %edx
f010157c:	50                   	push   %eax
f010157d:	e8 33 57 00 00       	call   f0106cb5 <strcmp>
f0101582:	83 c4 10             	add    $0x10,%esp
f0101585:	85 c0                	test   %eax,%eax
f0101587:	75 42                	jne    f01015cb <MergeTwoArrays+0xfa>
		farrPointer=arrays[i].ptr;
f0101589:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010158c:	89 d0                	mov    %edx,%eax
f010158e:	01 c0                	add    %eax,%eax
f0101590:	01 d0                	add    %edx,%eax
f0101592:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101599:	01 c8                	add    %ecx,%eax
f010159b:	01 d0                	add    %edx,%eax
f010159d:	05 18 48 15 f0       	add    $0xf0154818,%eax
f01015a2:	8b 00                	mov    (%eax),%eax
f01015a4:	89 45 f4             	mov    %eax,-0xc(%ebp)
		firstArraySize=arrays[i].size;
f01015a7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01015aa:	89 d0                	mov    %edx,%eax
f01015ac:	01 c0                	add    %eax,%eax
f01015ae:	01 d0                	add    %edx,%eax
f01015b0:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01015b7:	01 c8                	add    %ecx,%eax
f01015b9:	01 d0                	add    %edx,%eax
f01015bb:	05 14 48 15 f0       	add    $0xf0154814,%eax
f01015c0:	8b 00                	mov    (%eax),%eax
f01015c2:	89 45 e8             	mov    %eax,-0x18(%ebp)
		frstCounter=i;
f01015c5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01015c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
		}
		if(strcmp(arguments[2],arrays[i].name)==0){
f01015cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01015ce:	89 d0                	mov    %edx,%eax
f01015d0:	01 c0                	add    %eax,%eax
f01015d2:	01 d0                	add    %edx,%eax
f01015d4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01015db:	01 c8                	add    %ecx,%eax
f01015dd:	01 d0                	add    %edx,%eax
f01015df:	8d 90 00 48 15 f0    	lea    -0xfeab800(%eax),%edx
f01015e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e8:	83 c0 08             	add    $0x8,%eax
f01015eb:	8b 00                	mov    (%eax),%eax
f01015ed:	83 ec 08             	sub    $0x8,%esp
f01015f0:	52                   	push   %edx
f01015f1:	50                   	push   %eax
f01015f2:	e8 be 56 00 00       	call   f0106cb5 <strcmp>
f01015f7:	83 c4 10             	add    $0x10,%esp
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	75 42                	jne    f0101640 <MergeTwoArrays+0x16f>
		sarrPointer=arrays[i].ptr;
f01015fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101601:	89 d0                	mov    %edx,%eax
f0101603:	01 c0                	add    %eax,%eax
f0101605:	01 d0                	add    %edx,%eax
f0101607:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f010160e:	01 c8                	add    %ecx,%eax
f0101610:	01 d0                	add    %edx,%eax
f0101612:	05 18 48 15 f0       	add    $0xf0154818,%eax
f0101617:	8b 00                	mov    (%eax),%eax
f0101619:	89 45 f0             	mov    %eax,-0x10(%ebp)
		secondArraySize=arrays[i].size;
f010161c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010161f:	89 d0                	mov    %edx,%eax
f0101621:	01 c0                	add    %eax,%eax
f0101623:	01 d0                	add    %edx,%eax
f0101625:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f010162c:	01 c8                	add    %ecx,%eax
f010162e:	01 d0                	add    %edx,%eax
f0101630:	05 14 48 15 f0       	add    $0xf0154814,%eax
f0101635:	8b 00                	mov    (%eax),%eax
f0101637:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		scCounter=i;
f010163a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010163d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	int *scPointer = (int *)lastArrPointer;
	int firstArraySize=0;
	int secondArraySize=0;
	int frstCounter=0;
	int scCounter=0;
	for(int i=0;i<count;i++){
f0101640:	ff 45 d8             	incl   -0x28(%ebp)
f0101643:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f0101648:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f010164b:	0f 8c 05 ff ff ff    	jl     f0101556 <MergeTwoArrays+0x85>
	}


	//merge first array

	for(int i=0;i<firstArraySize;i++){
f0101651:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0101658:	eb 1d                	jmp    f0101677 <MergeTwoArrays+0x1a6>

		*mergedArrayPointer=farrPointer[i];
f010165a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010165d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101664:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101667:	01 d0                	add    %edx,%eax
f0101669:	8b 10                	mov    (%eax),%edx
f010166b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010166e:	89 10                	mov    %edx,(%eax)

		mergedArrayPointer++;
f0101670:	83 45 ec 04          	addl   $0x4,-0x14(%ebp)
	}


	//merge first array

	for(int i=0;i<firstArraySize;i++){
f0101674:	ff 45 d4             	incl   -0x2c(%ebp)
f0101677:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010167a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010167d:	7c db                	jl     f010165a <MergeTwoArrays+0x189>

		mergedArrayPointer++;

	}

	for(int i=0;i<secondArraySize;i++){
f010167f:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0101686:	eb 1d                	jmp    f01016a5 <MergeTwoArrays+0x1d4>

		*mergedArrayPointer=sarrPointer[i];
f0101688:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010168b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101692:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101695:	01 d0                	add    %edx,%eax
f0101697:	8b 10                	mov    (%eax),%edx
f0101699:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010169c:	89 10                	mov    %edx,(%eax)

		mergedArrayPointer++;
f010169e:	83 45 ec 04          	addl   $0x4,-0x14(%ebp)

		mergedArrayPointer++;

	}

	for(int i=0;i<secondArraySize;i++){
f01016a2:	ff 45 d0             	incl   -0x30(%ebp)
f01016a5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016a8:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f01016ab:	7c db                	jl     f0101688 <MergeTwoArrays+0x1b7>
		*mergedArrayPointer=sarrPointer[i];

		mergedArrayPointer++;
	}

	 strcpy(arrays[frstCounter].name,"//") ;
f01016ad:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01016b0:	89 d0                	mov    %edx,%eax
f01016b2:	01 c0                	add    %eax,%eax
f01016b4:	01 d0                	add    %edx,%eax
f01016b6:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01016bd:	01 c8                	add    %ecx,%eax
f01016bf:	01 d0                	add    %edx,%eax
f01016c1:	05 00 48 15 f0       	add    $0xf0154800,%eax
f01016c6:	83 ec 08             	sub    $0x8,%esp
f01016c9:	68 50 7c 10 f0       	push   $0xf0107c50
f01016ce:	50                   	push   %eax
f01016cf:	e8 24 55 00 00       	call   f0106bf8 <strcpy>
f01016d4:	83 c4 10             	add    $0x10,%esp
	 strcpy(arrays[scCounter].name,"//") ;
f01016d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01016da:	89 d0                	mov    %edx,%eax
f01016dc:	01 c0                	add    %eax,%eax
f01016de:	01 d0                	add    %edx,%eax
f01016e0:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f01016e7:	01 c8                	add    %ecx,%eax
f01016e9:	01 d0                	add    %edx,%eax
f01016eb:	05 00 48 15 f0       	add    $0xf0154800,%eax
f01016f0:	83 ec 08             	sub    $0x8,%esp
f01016f3:	68 50 7c 10 f0       	push   $0xf0107c50
f01016f8:	50                   	push   %eax
f01016f9:	e8 fa 54 00 00       	call   f0106bf8 <strcpy>
f01016fe:	83 c4 10             	add    $0x10,%esp

	 strcpy(arrays[count].name,arguments[3]) ;
f0101701:	8b 45 08             	mov    0x8(%ebp),%eax
f0101704:	83 c0 0c             	add    $0xc,%eax
f0101707:	8b 08                	mov    (%eax),%ecx
f0101709:	8b 15 6c 3f 15 f0    	mov    0xf0153f6c,%edx
f010170f:	89 d0                	mov    %edx,%eax
f0101711:	01 c0                	add    %eax,%eax
f0101713:	01 d0                	add    %edx,%eax
f0101715:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f010171c:	01 d8                	add    %ebx,%eax
f010171e:	01 d0                	add    %edx,%eax
f0101720:	05 00 48 15 f0       	add    $0xf0154800,%eax
f0101725:	83 ec 08             	sub    $0x8,%esp
f0101728:	51                   	push   %ecx
f0101729:	50                   	push   %eax
f010172a:	e8 c9 54 00 00       	call   f0106bf8 <strcpy>
f010172f:	83 c4 10             	add    $0x10,%esp
	 arrays[count].ptr=scPointer;
f0101732:	8b 15 6c 3f 15 f0    	mov    0xf0153f6c,%edx
f0101738:	89 d0                	mov    %edx,%eax
f010173a:	01 c0                	add    %eax,%eax
f010173c:	01 d0                	add    %edx,%eax
f010173e:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0101745:	01 c8                	add    %ecx,%eax
f0101747:	01 d0                	add    %edx,%eax
f0101749:	8d 90 18 48 15 f0    	lea    -0xfeab7e8(%eax),%edx
f010174f:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0101752:	89 02                	mov    %eax,(%edx)
	 arrays[count].size=arrays[frstCounter].size+arrays[scCounter].size;
f0101754:	8b 15 6c 3f 15 f0    	mov    0xf0153f6c,%edx
f010175a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010175d:	89 c8                	mov    %ecx,%eax
f010175f:	01 c0                	add    %eax,%eax
f0101761:	01 c8                	add    %ecx,%eax
f0101763:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f010176a:	01 d8                	add    %ebx,%eax
f010176c:	01 c8                	add    %ecx,%eax
f010176e:	05 14 48 15 f0       	add    $0xf0154814,%eax
f0101773:	8b 18                	mov    (%eax),%ebx
f0101775:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101778:	89 c8                	mov    %ecx,%eax
f010177a:	01 c0                	add    %eax,%eax
f010177c:	01 c8                	add    %ecx,%eax
f010177e:	8d 34 c5 00 00 00 00 	lea    0x0(,%eax,8),%esi
f0101785:	01 f0                	add    %esi,%eax
f0101787:	01 c8                	add    %ecx,%eax
f0101789:	05 14 48 15 f0       	add    $0xf0154814,%eax
f010178e:	8b 00                	mov    (%eax),%eax
f0101790:	8d 0c 03             	lea    (%ebx,%eax,1),%ecx
f0101793:	89 d0                	mov    %edx,%eax
f0101795:	01 c0                	add    %eax,%eax
f0101797:	01 d0                	add    %edx,%eax
f0101799:	8d 1c c5 00 00 00 00 	lea    0x0(,%eax,8),%ebx
f01017a0:	01 d8                	add    %ebx,%eax
f01017a2:	01 d0                	add    %edx,%eax
f01017a4:	05 14 48 15 f0       	add    $0xf0154814,%eax
f01017a9:	89 08                	mov    %ecx,(%eax)
	 count++;
f01017ab:	a1 6c 3f 15 f0       	mov    0xf0153f6c,%eax
f01017b0:	40                   	inc    %eax
f01017b1:	a3 6c 3f 15 f0       	mov    %eax,0xf0153f6c


}
f01017b6:	90                   	nop
f01017b7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01017ba:	5b                   	pop    %ebx
f01017bb:	5e                   	pop    %esi
f01017bc:	5d                   	pop    %ebp
f01017bd:	c3                   	ret    

f01017be <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f01017be:	55                   	push   %ebp
f01017bf:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f01017c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c4:	8b 15 c4 49 15 f0    	mov    0xf01549c4,%edx
f01017ca:	29 d0                	sub    %edx,%eax
f01017cc:	c1 f8 02             	sar    $0x2,%eax
f01017cf:	89 c2                	mov    %eax,%edx
f01017d1:	89 d0                	mov    %edx,%eax
f01017d3:	c1 e0 02             	shl    $0x2,%eax
f01017d6:	01 d0                	add    %edx,%eax
f01017d8:	c1 e0 02             	shl    $0x2,%eax
f01017db:	01 d0                	add    %edx,%eax
f01017dd:	c1 e0 02             	shl    $0x2,%eax
f01017e0:	01 d0                	add    %edx,%eax
f01017e2:	89 c1                	mov    %eax,%ecx
f01017e4:	c1 e1 08             	shl    $0x8,%ecx
f01017e7:	01 c8                	add    %ecx,%eax
f01017e9:	89 c1                	mov    %eax,%ecx
f01017eb:	c1 e1 10             	shl    $0x10,%ecx
f01017ee:	01 c8                	add    %ecx,%eax
f01017f0:	01 c0                	add    %eax,%eax
f01017f2:	01 d0                	add    %edx,%eax
}
f01017f4:	5d                   	pop    %ebp
f01017f5:	c3                   	ret    

f01017f6 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f01017f6:	55                   	push   %ebp
f01017f7:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f01017f9:	ff 75 08             	pushl  0x8(%ebp)
f01017fc:	e8 bd ff ff ff       	call   f01017be <to_frame_number>
f0101801:	83 c4 04             	add    $0x4,%esp
f0101804:	c1 e0 0c             	shl    $0xc,%eax
}
f0101807:	c9                   	leave  
f0101808:	c3                   	ret    

f0101809 <nvram_read>:
{
	sizeof(gdt) - 1, (unsigned long) gdt
};

int nvram_read(int r)
{	
f0101809:	55                   	push   %ebp
f010180a:	89 e5                	mov    %esp,%ebp
f010180c:	53                   	push   %ebx
f010180d:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101810:	8b 45 08             	mov    0x8(%ebp),%eax
f0101813:	83 ec 0c             	sub    $0xc,%esp
f0101816:	50                   	push   %eax
f0101817:	e8 e3 3d 00 00       	call   f01055ff <mc146818_read>
f010181c:	83 c4 10             	add    $0x10,%esp
f010181f:	89 c3                	mov    %eax,%ebx
f0101821:	8b 45 08             	mov    0x8(%ebp),%eax
f0101824:	40                   	inc    %eax
f0101825:	83 ec 0c             	sub    $0xc,%esp
f0101828:	50                   	push   %eax
f0101829:	e8 d1 3d 00 00       	call   f01055ff <mc146818_read>
f010182e:	83 c4 10             	add    $0x10,%esp
f0101831:	c1 e0 08             	shl    $0x8,%eax
f0101834:	09 d8                	or     %ebx,%eax
}
f0101836:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101839:	c9                   	leave  
f010183a:	c3                   	ret    

f010183b <detect_memory>:
	
void detect_memory()
{
f010183b:	55                   	push   %ebp
f010183c:	89 e5                	mov    %esp,%ebp
f010183e:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	size_of_base_mem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PAGE_SIZE);
f0101841:	83 ec 0c             	sub    $0xc,%esp
f0101844:	6a 15                	push   $0x15
f0101846:	e8 be ff ff ff       	call   f0101809 <nvram_read>
f010184b:	83 c4 10             	add    $0x10,%esp
f010184e:	c1 e0 0a             	shl    $0xa,%eax
f0101851:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101854:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101857:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010185c:	a3 f4 47 15 f0       	mov    %eax,0xf01547f4
	size_of_extended_mem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PAGE_SIZE);
f0101861:	83 ec 0c             	sub    $0xc,%esp
f0101864:	6a 17                	push   $0x17
f0101866:	e8 9e ff ff ff       	call   f0101809 <nvram_read>
f010186b:	83 c4 10             	add    $0x10,%esp
f010186e:	c1 e0 0a             	shl    $0xa,%eax
f0101871:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101874:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101877:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010187c:	a3 ec 47 15 f0       	mov    %eax,0xf01547ec

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (size_of_extended_mem)
f0101881:	a1 ec 47 15 f0       	mov    0xf01547ec,%eax
f0101886:	85 c0                	test   %eax,%eax
f0101888:	74 11                	je     f010189b <detect_memory+0x60>
		maxpa = PHYS_EXTENDED_MEM + size_of_extended_mem;
f010188a:	a1 ec 47 15 f0       	mov    0xf01547ec,%eax
f010188f:	05 00 00 10 00       	add    $0x100000,%eax
f0101894:	a3 f0 47 15 f0       	mov    %eax,0xf01547f0
f0101899:	eb 0a                	jmp    f01018a5 <detect_memory+0x6a>
	else
		maxpa = size_of_extended_mem;
f010189b:	a1 ec 47 15 f0       	mov    0xf01547ec,%eax
f01018a0:	a3 f0 47 15 f0       	mov    %eax,0xf01547f0

	number_of_frames = maxpa / PAGE_SIZE;
f01018a5:	a1 f0 47 15 f0       	mov    0xf01547f0,%eax
f01018aa:	c1 e8 0c             	shr    $0xc,%eax
f01018ad:	a3 e8 47 15 f0       	mov    %eax,0xf01547e8

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f01018b2:	a1 f0 47 15 f0       	mov    0xf01547f0,%eax
f01018b7:	c1 e8 0a             	shr    $0xa,%eax
f01018ba:	83 ec 08             	sub    $0x8,%esp
f01018bd:	50                   	push   %eax
f01018be:	68 54 7c 10 f0       	push   $0xf0107c54
f01018c3:	e8 ec 3d 00 00       	call   f01056b4 <cprintf>
f01018c8:	83 c4 10             	add    $0x10,%esp
	cprintf("base = %dK, extended = %dK\n", (int)(size_of_base_mem/1024), (int)(size_of_extended_mem/1024));
f01018cb:	a1 ec 47 15 f0       	mov    0xf01547ec,%eax
f01018d0:	c1 e8 0a             	shr    $0xa,%eax
f01018d3:	89 c2                	mov    %eax,%edx
f01018d5:	a1 f4 47 15 f0       	mov    0xf01547f4,%eax
f01018da:	c1 e8 0a             	shr    $0xa,%eax
f01018dd:	83 ec 04             	sub    $0x4,%esp
f01018e0:	52                   	push   %edx
f01018e1:	50                   	push   %eax
f01018e2:	68 75 7c 10 f0       	push   $0xf0107c75
f01018e7:	e8 c8 3d 00 00       	call   f01056b4 <cprintf>
f01018ec:	83 c4 10             	add    $0x10,%esp
}
f01018ef:	90                   	nop
f01018f0:	c9                   	leave  
f01018f1:	c3                   	ret    

f01018f2 <check_boot_pgdir>:
// but it is a pretty good check.
//
uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va);

void check_boot_pgdir()
{
f01018f2:	55                   	push   %ebp
f01018f3:	89 e5                	mov    %esp,%ebp
f01018f5:	83 ec 28             	sub    $0x28,%esp
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
f01018f8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f01018ff:	8b 15 e8 47 15 f0    	mov    0xf01547e8,%edx
f0101905:	89 d0                	mov    %edx,%eax
f0101907:	01 c0                	add    %eax,%eax
f0101909:	01 d0                	add    %edx,%eax
f010190b:	c1 e0 02             	shl    $0x2,%eax
f010190e:	89 c2                	mov    %eax,%edx
f0101910:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101913:	01 d0                	add    %edx,%eax
f0101915:	48                   	dec    %eax
f0101916:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101919:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010191c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101921:	f7 75 f0             	divl   -0x10(%ebp)
f0101924:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101927:	29 d0                	sub    %edx,%eax
f0101929:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (i = 0; i < n; i += PAGE_SIZE)
f010192c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101933:	eb 71                	jmp    f01019a6 <check_boot_pgdir+0xb4>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);
f0101935:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101938:	8d 90 00 00 00 ef    	lea    -0x11000000(%eax),%edx
f010193e:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101943:	83 ec 08             	sub    $0x8,%esp
f0101946:	52                   	push   %edx
f0101947:	50                   	push   %eax
f0101948:	e8 f4 01 00 00       	call   f0101b41 <check_va2pa>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	89 c2                	mov    %eax,%edx
f0101952:	a1 c4 49 15 f0       	mov    0xf01549c4,%eax
f0101957:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010195a:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0101961:	77 14                	ja     f0101977 <check_boot_pgdir+0x85>
f0101963:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101966:	68 94 7c 10 f0       	push   $0xf0107c94
f010196b:	6a 5e                	push   $0x5e
f010196d:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101972:	e8 b7 e7 ff ff       	call   f010012e <_panic>
f0101977:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010197a:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0101980:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101983:	01 c8                	add    %ecx,%eax
f0101985:	39 c2                	cmp    %eax,%edx
f0101987:	74 16                	je     f010199f <check_boot_pgdir+0xad>
f0101989:	68 d4 7c 10 f0       	push   $0xf0107cd4
f010198e:	68 36 7d 10 f0       	push   $0xf0107d36
f0101993:	6a 5e                	push   $0x5e
f0101995:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010199a:	e8 8f e7 ff ff       	call   f010012e <_panic>
{
	uint32 i, n;

	// check frames_info array
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
f010199f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01019a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01019a9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f01019ac:	72 87                	jb     f0101935 <check_boot_pgdir+0x43>
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f01019ae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01019b5:	eb 3d                	jmp    f01019f4 <check_boot_pgdir+0x102>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);
f01019b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01019ba:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f01019c0:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01019c5:	83 ec 08             	sub    $0x8,%esp
f01019c8:	52                   	push   %edx
f01019c9:	50                   	push   %eax
f01019ca:	e8 72 01 00 00       	call   f0101b41 <check_va2pa>
f01019cf:	83 c4 10             	add    $0x10,%esp
f01019d2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f01019d5:	74 16                	je     f01019ed <check_boot_pgdir+0xfb>
f01019d7:	68 4c 7d 10 f0       	push   $0xf0107d4c
f01019dc:	68 36 7d 10 f0       	push   $0xf0107d36
f01019e1:	6a 62                	push   $0x62
f01019e3:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01019e8:	e8 41 e7 ff ff       	call   f010012e <_panic>
	n = ROUNDUP(number_of_frames*sizeof(struct Frame_Info), PAGE_SIZE);
	for (i = 0; i < n; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, READ_ONLY_FRAMES_INFO + i) == K_PHYSICAL_ADDRESS(frames_info) + i);

	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
f01019ed:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f01019f4:	81 7d f4 00 00 00 10 	cmpl   $0x10000000,-0xc(%ebp)
f01019fb:	75 ba                	jne    f01019b7 <check_boot_pgdir+0xc5>
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f01019fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101a04:	eb 6e                	jmp    f0101a74 <check_boot_pgdir+0x182>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);
f0101a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a09:	8d 90 00 80 bf ef    	lea    -0x10408000(%eax),%edx
f0101a0f:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101a14:	83 ec 08             	sub    $0x8,%esp
f0101a17:	52                   	push   %edx
f0101a18:	50                   	push   %eax
f0101a19:	e8 23 01 00 00       	call   f0101b41 <check_va2pa>
f0101a1e:	83 c4 10             	add    $0x10,%esp
f0101a21:	c7 45 e0 00 90 11 f0 	movl   $0xf0119000,-0x20(%ebp)
f0101a28:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0101a2f:	77 14                	ja     f0101a45 <check_boot_pgdir+0x153>
f0101a31:	ff 75 e0             	pushl  -0x20(%ebp)
f0101a34:	68 94 7c 10 f0       	push   $0xf0107c94
f0101a39:	6a 66                	push   $0x66
f0101a3b:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101a40:	e8 e9 e6 ff ff       	call   f010012e <_panic>
f0101a45:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101a48:	8d 8a 00 00 00 10    	lea    0x10000000(%edx),%ecx
f0101a4e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a51:	01 ca                	add    %ecx,%edx
f0101a53:	39 d0                	cmp    %edx,%eax
f0101a55:	74 16                	je     f0101a6d <check_boot_pgdir+0x17b>
f0101a57:	68 84 7d 10 f0       	push   $0xf0107d84
f0101a5c:	68 36 7d 10 f0       	push   $0xf0107d36
f0101a61:	6a 66                	push   $0x66
f0101a63:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101a68:	e8 c1 e6 ff ff       	call   f010012e <_panic>
	// check phys mem
	for (i = 0; KERNEL_BASE + i != 0; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_BASE + i) == i);

	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
f0101a6d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0101a74:	81 7d f4 ff 7f 00 00 	cmpl   $0x7fff,-0xc(%ebp)
f0101a7b:	76 89                	jbe    f0101a06 <check_boot_pgdir+0x114>
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101a7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f0101a84:	e9 98 00 00 00       	jmp    f0101b21 <check_boot_pgdir+0x22f>
		switch (i) {
f0101a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a8c:	2d bb 03 00 00       	sub    $0x3bb,%eax
f0101a91:	83 f8 04             	cmp    $0x4,%eax
f0101a94:	77 29                	ja     f0101abf <check_boot_pgdir+0x1cd>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
f0101a96:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101a9b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101a9e:	c1 e2 02             	shl    $0x2,%edx
f0101aa1:	01 d0                	add    %edx,%eax
f0101aa3:	8b 00                	mov    (%eax),%eax
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	75 71                	jne    f0101b1a <check_boot_pgdir+0x228>
f0101aa9:	68 fa 7d 10 f0       	push   $0xf0107dfa
f0101aae:	68 36 7d 10 f0       	push   $0xf0107d36
f0101ab3:	6a 70                	push   $0x70
f0101ab5:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101aba:	e8 6f e6 ff ff       	call   f010012e <_panic>
			break;
		default:
			if (i >= PDX(KERNEL_BASE))
f0101abf:	81 7d f4 bf 03 00 00 	cmpl   $0x3bf,-0xc(%ebp)
f0101ac6:	76 29                	jbe    f0101af1 <check_boot_pgdir+0x1ff>
				assert(ptr_page_directory[i]);
f0101ac8:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101acd:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101ad0:	c1 e2 02             	shl    $0x2,%edx
f0101ad3:	01 d0                	add    %edx,%eax
f0101ad5:	8b 00                	mov    (%eax),%eax
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	75 42                	jne    f0101b1d <check_boot_pgdir+0x22b>
f0101adb:	68 fa 7d 10 f0       	push   $0xf0107dfa
f0101ae0:	68 36 7d 10 f0       	push   $0xf0107d36
f0101ae5:	6a 74                	push   $0x74
f0101ae7:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101aec:	e8 3d e6 ff ff       	call   f010012e <_panic>
			else				
				assert(ptr_page_directory[i] == 0);
f0101af1:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101af6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101af9:	c1 e2 02             	shl    $0x2,%edx
f0101afc:	01 d0                	add    %edx,%eax
f0101afe:	8b 00                	mov    (%eax),%eax
f0101b00:	85 c0                	test   %eax,%eax
f0101b02:	74 19                	je     f0101b1d <check_boot_pgdir+0x22b>
f0101b04:	68 10 7e 10 f0       	push   $0xf0107e10
f0101b09:	68 36 7d 10 f0       	push   $0xf0107d36
f0101b0e:	6a 76                	push   $0x76
f0101b10:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101b15:	e8 14 e6 ff ff       	call   f010012e <_panic>
		case PDX(UVPT):
		case PDX(KERNEL_STACK_TOP-1):
		case PDX(UENVS):
		case PDX(READ_ONLY_FRAMES_INFO):			
			assert(ptr_page_directory[i]);
			break;
f0101b1a:	90                   	nop
f0101b1b:	eb 01                	jmp    f0101b1e <check_boot_pgdir+0x22c>
		default:
			if (i >= PDX(KERNEL_BASE))
				assert(ptr_page_directory[i]);
			else				
				assert(ptr_page_directory[i] == 0);
			break;
f0101b1d:	90                   	nop
	// check kernel stack
	for (i = 0; i < KERNEL_STACK_SIZE; i += PAGE_SIZE)
		assert(check_va2pa(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE + i) == K_PHYSICAL_ADDRESS(ptr_stack_bottom) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101b1e:	ff 45 f4             	incl   -0xc(%ebp)
f0101b21:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
f0101b28:	0f 86 5b ff ff ff    	jbe    f0101a89 <check_boot_pgdir+0x197>
			else				
				assert(ptr_page_directory[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f0101b2e:	83 ec 0c             	sub    $0xc,%esp
f0101b31:	68 2c 7e 10 f0       	push   $0xf0107e2c
f0101b36:	e8 79 3b 00 00       	call   f01056b4 <cprintf>
f0101b3b:	83 c4 10             	add    $0x10,%esp
}
f0101b3e:	90                   	nop
f0101b3f:	c9                   	leave  
f0101b40:	c3                   	ret    

f0101b41 <check_va2pa>:
// defined by the page directory 'ptr_page_directory'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

uint32 check_va2pa(uint32 *ptr_page_directory, uint32 va)
{
f0101b41:	55                   	push   %ebp
f0101b42:	89 e5                	mov    %esp,%ebp
f0101b44:	83 ec 18             	sub    $0x18,%esp
	uint32 *p;

	ptr_page_directory = &ptr_page_directory[PDX(va)];
f0101b47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b4a:	c1 e8 16             	shr    $0x16,%eax
f0101b4d:	c1 e0 02             	shl    $0x2,%eax
f0101b50:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*ptr_page_directory & PERM_PRESENT))
f0101b53:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b56:	8b 00                	mov    (%eax),%eax
f0101b58:	83 e0 01             	and    $0x1,%eax
f0101b5b:	85 c0                	test   %eax,%eax
f0101b5d:	75 0a                	jne    f0101b69 <check_va2pa+0x28>
		return ~0;
f0101b5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101b64:	e9 87 00 00 00       	jmp    f0101bf0 <check_va2pa+0xaf>
	p = (uint32*) K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(*ptr_page_directory));
f0101b69:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b6c:	8b 00                	mov    (%eax),%eax
f0101b6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101b73:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101b76:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b79:	c1 e8 0c             	shr    $0xc,%eax
f0101b7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101b7f:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f0101b84:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0101b87:	72 17                	jb     f0101ba0 <check_va2pa+0x5f>
f0101b89:	ff 75 f4             	pushl  -0xc(%ebp)
f0101b8c:	68 4c 7e 10 f0       	push   $0xf0107e4c
f0101b91:	68 89 00 00 00       	push   $0x89
f0101b96:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101b9b:	e8 8e e5 ff ff       	call   f010012e <_panic>
f0101ba0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101ba3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ba8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!(p[PTX(va)] & PERM_PRESENT))
f0101bab:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bae:	c1 e8 0c             	shr    $0xc,%eax
f0101bb1:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101bb6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101bbd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bc0:	01 d0                	add    %edx,%eax
f0101bc2:	8b 00                	mov    (%eax),%eax
f0101bc4:	83 e0 01             	and    $0x1,%eax
f0101bc7:	85 c0                	test   %eax,%eax
f0101bc9:	75 07                	jne    f0101bd2 <check_va2pa+0x91>
		return ~0;
f0101bcb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bd0:	eb 1e                	jmp    f0101bf0 <check_va2pa+0xaf>
	return EXTRACT_ADDRESS(p[PTX(va)]);
f0101bd2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bd5:	c1 e8 0c             	shr    $0xc,%eax
f0101bd8:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101bdd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0101be4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101be7:	01 d0                	add    %edx,%eax
f0101be9:	8b 00                	mov    (%eax),%eax
f0101beb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f0101bf0:	c9                   	leave  
f0101bf1:	c3                   	ret    

f0101bf2 <tlb_invalidate>:
		
void tlb_invalidate(uint32 *ptr_page_directory, void *virtual_address)
{
f0101bf2:	55                   	push   %ebp
f0101bf3:	89 e5                	mov    %esp,%ebp
f0101bf5:	83 ec 10             	sub    $0x10,%esp
f0101bf8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101bfb:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101bfe:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101c01:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(virtual_address);
}
f0101c04:	90                   	nop
f0101c05:	c9                   	leave  
f0101c06:	c3                   	ret    

f0101c07 <page_check>:

void page_check()
{
f0101c07:	55                   	push   %ebp
f0101c08:	89 e5                	mov    %esp,%ebp
f0101c0a:	53                   	push   %ebx
f0101c0b:	83 ec 24             	sub    $0x24,%esp
	struct Frame_Info *pp, *pp0, *pp1, *pp2;
	struct Linked_List fl;

	// should be able to allocate three frames_info
	pp0 = pp1 = pp2 = 0;
f0101c0e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f0101c15:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101c18:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101c1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(allocate_frame(&pp0) == 0);
f0101c21:	83 ec 0c             	sub    $0xc,%esp
f0101c24:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0101c27:	50                   	push   %eax
f0101c28:	e8 d2 2d 00 00       	call   f01049ff <allocate_frame>
f0101c2d:	83 c4 10             	add    $0x10,%esp
f0101c30:	85 c0                	test   %eax,%eax
f0101c32:	74 19                	je     f0101c4d <page_check+0x46>
f0101c34:	68 7b 7e 10 f0       	push   $0xf0107e7b
f0101c39:	68 36 7d 10 f0       	push   $0xf0107d36
f0101c3e:	68 9d 00 00 00       	push   $0x9d
f0101c43:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101c48:	e8 e1 e4 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp1) == 0);
f0101c4d:	83 ec 0c             	sub    $0xc,%esp
f0101c50:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101c53:	50                   	push   %eax
f0101c54:	e8 a6 2d 00 00       	call   f01049ff <allocate_frame>
f0101c59:	83 c4 10             	add    $0x10,%esp
f0101c5c:	85 c0                	test   %eax,%eax
f0101c5e:	74 19                	je     f0101c79 <page_check+0x72>
f0101c60:	68 95 7e 10 f0       	push   $0xf0107e95
f0101c65:	68 36 7d 10 f0       	push   $0xf0107d36
f0101c6a:	68 9e 00 00 00       	push   $0x9e
f0101c6f:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101c74:	e8 b5 e4 ff ff       	call   f010012e <_panic>
	assert(allocate_frame(&pp2) == 0);
f0101c79:	83 ec 0c             	sub    $0xc,%esp
f0101c7c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0101c7f:	50                   	push   %eax
f0101c80:	e8 7a 2d 00 00       	call   f01049ff <allocate_frame>
f0101c85:	83 c4 10             	add    $0x10,%esp
f0101c88:	85 c0                	test   %eax,%eax
f0101c8a:	74 19                	je     f0101ca5 <page_check+0x9e>
f0101c8c:	68 af 7e 10 f0       	push   $0xf0107eaf
f0101c91:	68 36 7d 10 f0       	push   $0xf0107d36
f0101c96:	68 9f 00 00 00       	push   $0x9f
f0101c9b:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101ca0:	e8 89 e4 ff ff       	call   f010012e <_panic>

	assert(pp0);
f0101ca5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ca8:	85 c0                	test   %eax,%eax
f0101caa:	75 19                	jne    f0101cc5 <page_check+0xbe>
f0101cac:	68 c9 7e 10 f0       	push   $0xf0107ec9
f0101cb1:	68 36 7d 10 f0       	push   $0xf0107d36
f0101cb6:	68 a1 00 00 00       	push   $0xa1
f0101cbb:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101cc0:	e8 69 e4 ff ff       	call   f010012e <_panic>
	assert(pp1 && pp1 != pp0);
f0101cc5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101cc8:	85 c0                	test   %eax,%eax
f0101cca:	74 0a                	je     f0101cd6 <page_check+0xcf>
f0101ccc:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101ccf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101cd2:	39 c2                	cmp    %eax,%edx
f0101cd4:	75 19                	jne    f0101cef <page_check+0xe8>
f0101cd6:	68 cd 7e 10 f0       	push   $0xf0107ecd
f0101cdb:	68 36 7d 10 f0       	push   $0xf0107d36
f0101ce0:	68 a2 00 00 00       	push   $0xa2
f0101ce5:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101cea:	e8 3f e4 ff ff       	call   f010012e <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101cef:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101cf2:	85 c0                	test   %eax,%eax
f0101cf4:	74 14                	je     f0101d0a <page_check+0x103>
f0101cf6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101cf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101cfc:	39 c2                	cmp    %eax,%edx
f0101cfe:	74 0a                	je     f0101d0a <page_check+0x103>
f0101d00:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101d03:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d06:	39 c2                	cmp    %eax,%edx
f0101d08:	75 19                	jne    f0101d23 <page_check+0x11c>
f0101d0a:	68 e0 7e 10 f0       	push   $0xf0107ee0
f0101d0f:	68 36 7d 10 f0       	push   $0xf0107d36
f0101d14:	68 a3 00 00 00       	push   $0xa3
f0101d19:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101d1e:	e8 0b e4 ff ff       	call   f010012e <_panic>

	// temporarily steal the rest of the free frames_info
	fl = free_frame_list;
f0101d23:	a1 c0 49 15 f0       	mov    0xf01549c0,%eax
f0101d28:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	LIST_INIT(&free_frame_list);
f0101d2b:	c7 05 c0 49 15 f0 00 	movl   $0x0,0xf01549c0
f0101d32:	00 00 00 

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101d35:	83 ec 0c             	sub    $0xc,%esp
f0101d38:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101d3b:	50                   	push   %eax
f0101d3c:	e8 be 2c 00 00       	call   f01049ff <allocate_frame>
f0101d41:	83 c4 10             	add    $0x10,%esp
f0101d44:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101d47:	74 19                	je     f0101d62 <page_check+0x15b>
f0101d49:	68 00 7f 10 f0       	push   $0xf0107f00
f0101d4e:	68 36 7d 10 f0       	push   $0xf0107d36
f0101d53:	68 aa 00 00 00       	push   $0xaa
f0101d58:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101d5d:	e8 cc e3 ff ff       	call   f010012e <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) < 0);
f0101d62:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101d65:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101d6a:	6a 00                	push   $0x0
f0101d6c:	6a 00                	push   $0x0
f0101d6e:	52                   	push   %edx
f0101d6f:	50                   	push   %eax
f0101d70:	e8 97 2e 00 00       	call   f0104c0c <map_frame>
f0101d75:	83 c4 10             	add    $0x10,%esp
f0101d78:	85 c0                	test   %eax,%eax
f0101d7a:	78 19                	js     f0101d95 <page_check+0x18e>
f0101d7c:	68 20 7f 10 f0       	push   $0xf0107f20
f0101d81:	68 36 7d 10 f0       	push   $0xf0107d36
f0101d86:	68 ad 00 00 00       	push   $0xad
f0101d8b:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101d90:	e8 99 e3 ff ff       	call   f010012e <_panic>

	// free pp0 and try again: pp0 should be used for page table
	free_frame(pp0);
f0101d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d98:	83 ec 0c             	sub    $0xc,%esp
f0101d9b:	50                   	push   %eax
f0101d9c:	e8 c5 2c 00 00       	call   f0104a66 <free_frame>
f0101da1:	83 c4 10             	add    $0x10,%esp
	assert(map_frame(ptr_page_directory, pp1, 0x0, 0) == 0);
f0101da4:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101da7:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101dac:	6a 00                	push   $0x0
f0101dae:	6a 00                	push   $0x0
f0101db0:	52                   	push   %edx
f0101db1:	50                   	push   %eax
f0101db2:	e8 55 2e 00 00       	call   f0104c0c <map_frame>
f0101db7:	83 c4 10             	add    $0x10,%esp
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	74 19                	je     f0101dd7 <page_check+0x1d0>
f0101dbe:	68 50 7f 10 f0       	push   $0xf0107f50
f0101dc3:	68 36 7d 10 f0       	push   $0xf0107d36
f0101dc8:	68 b1 00 00 00       	push   $0xb1
f0101dcd:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101dd2:	e8 57 e3 ff ff       	call   f010012e <_panic>
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f0101dd7:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101ddc:	8b 00                	mov    (%eax),%eax
f0101dde:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101de3:	89 c3                	mov    %eax,%ebx
f0101de5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101de8:	83 ec 0c             	sub    $0xc,%esp
f0101deb:	50                   	push   %eax
f0101dec:	e8 05 fa ff ff       	call   f01017f6 <to_physical_address>
f0101df1:	83 c4 10             	add    $0x10,%esp
f0101df4:	39 c3                	cmp    %eax,%ebx
f0101df6:	74 19                	je     f0101e11 <page_check+0x20a>
f0101df8:	68 80 7f 10 f0       	push   $0xf0107f80
f0101dfd:	68 36 7d 10 f0       	push   $0xf0107d36
f0101e02:	68 b2 00 00 00       	push   $0xb2
f0101e07:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101e0c:	e8 1d e3 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, 0x0) == to_physical_address(pp1));
f0101e11:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101e16:	83 ec 08             	sub    $0x8,%esp
f0101e19:	6a 00                	push   $0x0
f0101e1b:	50                   	push   %eax
f0101e1c:	e8 20 fd ff ff       	call   f0101b41 <check_va2pa>
f0101e21:	83 c4 10             	add    $0x10,%esp
f0101e24:	89 c3                	mov    %eax,%ebx
f0101e26:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e29:	83 ec 0c             	sub    $0xc,%esp
f0101e2c:	50                   	push   %eax
f0101e2d:	e8 c4 f9 ff ff       	call   f01017f6 <to_physical_address>
f0101e32:	83 c4 10             	add    $0x10,%esp
f0101e35:	39 c3                	cmp    %eax,%ebx
f0101e37:	74 19                	je     f0101e52 <page_check+0x24b>
f0101e39:	68 c4 7f 10 f0       	push   $0xf0107fc4
f0101e3e:	68 36 7d 10 f0       	push   $0xf0107d36
f0101e43:	68 b3 00 00 00       	push   $0xb3
f0101e48:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101e4d:	e8 dc e2 ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f0101e52:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e55:	8b 40 08             	mov    0x8(%eax),%eax
f0101e58:	66 83 f8 01          	cmp    $0x1,%ax
f0101e5c:	74 19                	je     f0101e77 <page_check+0x270>
f0101e5e:	68 05 80 10 f0       	push   $0xf0108005
f0101e63:	68 36 7d 10 f0       	push   $0xf0107d36
f0101e68:	68 b4 00 00 00       	push   $0xb4
f0101e6d:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101e72:	e8 b7 e2 ff ff       	call   f010012e <_panic>
	assert(pp0->references == 1);
f0101e77:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101e7a:	8b 40 08             	mov    0x8(%eax),%eax
f0101e7d:	66 83 f8 01          	cmp    $0x1,%ax
f0101e81:	74 19                	je     f0101e9c <page_check+0x295>
f0101e83:	68 1a 80 10 f0       	push   $0xf010801a
f0101e88:	68 36 7d 10 f0       	push   $0xf0107d36
f0101e8d:	68 b5 00 00 00       	push   $0xb5
f0101e92:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101e97:	e8 92 e2 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because pp0 is already allocated for page table
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101e9c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101e9f:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101ea4:	6a 00                	push   $0x0
f0101ea6:	68 00 10 00 00       	push   $0x1000
f0101eab:	52                   	push   %edx
f0101eac:	50                   	push   %eax
f0101ead:	e8 5a 2d 00 00       	call   f0104c0c <map_frame>
f0101eb2:	83 c4 10             	add    $0x10,%esp
f0101eb5:	85 c0                	test   %eax,%eax
f0101eb7:	74 19                	je     f0101ed2 <page_check+0x2cb>
f0101eb9:	68 30 80 10 f0       	push   $0xf0108030
f0101ebe:	68 36 7d 10 f0       	push   $0xf0107d36
f0101ec3:	68 b8 00 00 00       	push   $0xb8
f0101ec8:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101ecd:	e8 5c e2 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101ed2:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101ed7:	83 ec 08             	sub    $0x8,%esp
f0101eda:	68 00 10 00 00       	push   $0x1000
f0101edf:	50                   	push   %eax
f0101ee0:	e8 5c fc ff ff       	call   f0101b41 <check_va2pa>
f0101ee5:	83 c4 10             	add    $0x10,%esp
f0101ee8:	89 c3                	mov    %eax,%ebx
f0101eea:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101eed:	83 ec 0c             	sub    $0xc,%esp
f0101ef0:	50                   	push   %eax
f0101ef1:	e8 00 f9 ff ff       	call   f01017f6 <to_physical_address>
f0101ef6:	83 c4 10             	add    $0x10,%esp
f0101ef9:	39 c3                	cmp    %eax,%ebx
f0101efb:	74 19                	je     f0101f16 <page_check+0x30f>
f0101efd:	68 70 80 10 f0       	push   $0xf0108070
f0101f02:	68 36 7d 10 f0       	push   $0xf0107d36
f0101f07:	68 b9 00 00 00       	push   $0xb9
f0101f0c:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101f11:	e8 18 e2 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101f16:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101f19:	8b 40 08             	mov    0x8(%eax),%eax
f0101f1c:	66 83 f8 01          	cmp    $0x1,%ax
f0101f20:	74 19                	je     f0101f3b <page_check+0x334>
f0101f22:	68 b7 80 10 f0       	push   $0xf01080b7
f0101f27:	68 36 7d 10 f0       	push   $0xf0107d36
f0101f2c:	68 ba 00 00 00       	push   $0xba
f0101f31:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101f36:	e8 f3 e1 ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f0101f3b:	83 ec 0c             	sub    $0xc,%esp
f0101f3e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101f41:	50                   	push   %eax
f0101f42:	e8 b8 2a 00 00       	call   f01049ff <allocate_frame>
f0101f47:	83 c4 10             	add    $0x10,%esp
f0101f4a:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101f4d:	74 19                	je     f0101f68 <page_check+0x361>
f0101f4f:	68 00 7f 10 f0       	push   $0xf0107f00
f0101f54:	68 36 7d 10 f0       	push   $0xf0107d36
f0101f59:	68 bd 00 00 00       	push   $0xbd
f0101f5e:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101f63:	e8 c6 e1 ff ff       	call   f010012e <_panic>

	// should be able to map pp2 at PAGE_SIZE because it's already there
	assert(map_frame(ptr_page_directory, pp2, (void*) PAGE_SIZE, 0) == 0);
f0101f68:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101f6b:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101f70:	6a 00                	push   $0x0
f0101f72:	68 00 10 00 00       	push   $0x1000
f0101f77:	52                   	push   %edx
f0101f78:	50                   	push   %eax
f0101f79:	e8 8e 2c 00 00       	call   f0104c0c <map_frame>
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	85 c0                	test   %eax,%eax
f0101f83:	74 19                	je     f0101f9e <page_check+0x397>
f0101f85:	68 30 80 10 f0       	push   $0xf0108030
f0101f8a:	68 36 7d 10 f0       	push   $0xf0107d36
f0101f8f:	68 c0 00 00 00       	push   $0xc0
f0101f94:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101f99:	e8 90 e1 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp2));
f0101f9e:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0101fa3:	83 ec 08             	sub    $0x8,%esp
f0101fa6:	68 00 10 00 00       	push   $0x1000
f0101fab:	50                   	push   %eax
f0101fac:	e8 90 fb ff ff       	call   f0101b41 <check_va2pa>
f0101fb1:	83 c4 10             	add    $0x10,%esp
f0101fb4:	89 c3                	mov    %eax,%ebx
f0101fb6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101fb9:	83 ec 0c             	sub    $0xc,%esp
f0101fbc:	50                   	push   %eax
f0101fbd:	e8 34 f8 ff ff       	call   f01017f6 <to_physical_address>
f0101fc2:	83 c4 10             	add    $0x10,%esp
f0101fc5:	39 c3                	cmp    %eax,%ebx
f0101fc7:	74 19                	je     f0101fe2 <page_check+0x3db>
f0101fc9:	68 70 80 10 f0       	push   $0xf0108070
f0101fce:	68 36 7d 10 f0       	push   $0xf0107d36
f0101fd3:	68 c1 00 00 00       	push   $0xc1
f0101fd8:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0101fdd:	e8 4c e1 ff ff       	call   f010012e <_panic>
	assert(pp2->references == 1);
f0101fe2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101fe5:	8b 40 08             	mov    0x8(%eax),%eax
f0101fe8:	66 83 f8 01          	cmp    $0x1,%ax
f0101fec:	74 19                	je     f0102007 <page_check+0x400>
f0101fee:	68 b7 80 10 f0       	push   $0xf01080b7
f0101ff3:	68 36 7d 10 f0       	push   $0xf0107d36
f0101ff8:	68 c2 00 00 00       	push   $0xc2
f0101ffd:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102002:	e8 27 e1 ff ff       	call   f010012e <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in map_frame
	assert(allocate_frame(&pp) == E_NO_MEM);
f0102007:	83 ec 0c             	sub    $0xc,%esp
f010200a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010200d:	50                   	push   %eax
f010200e:	e8 ec 29 00 00       	call   f01049ff <allocate_frame>
f0102013:	83 c4 10             	add    $0x10,%esp
f0102016:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102019:	74 19                	je     f0102034 <page_check+0x42d>
f010201b:	68 00 7f 10 f0       	push   $0xf0107f00
f0102020:	68 36 7d 10 f0       	push   $0xf0107d36
f0102025:	68 c6 00 00 00       	push   $0xc6
f010202a:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010202f:	e8 fa e0 ff ff       	call   f010012e <_panic>

	// should not be able to map at PTSIZE because need free frame for page table
	assert(map_frame(ptr_page_directory, pp0, (void*) PTSIZE, 0) < 0);
f0102034:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0102037:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f010203c:	6a 00                	push   $0x0
f010203e:	68 00 00 40 00       	push   $0x400000
f0102043:	52                   	push   %edx
f0102044:	50                   	push   %eax
f0102045:	e8 c2 2b 00 00       	call   f0104c0c <map_frame>
f010204a:	83 c4 10             	add    $0x10,%esp
f010204d:	85 c0                	test   %eax,%eax
f010204f:	78 19                	js     f010206a <page_check+0x463>
f0102051:	68 cc 80 10 f0       	push   $0xf01080cc
f0102056:	68 36 7d 10 f0       	push   $0xf0107d36
f010205b:	68 c9 00 00 00       	push   $0xc9
f0102060:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102065:	e8 c4 e0 ff ff       	call   f010012e <_panic>

	// insert pp1 at PAGE_SIZE (replacing pp2)
	assert(map_frame(ptr_page_directory, pp1, (void*) PAGE_SIZE, 0) == 0);
f010206a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010206d:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102072:	6a 00                	push   $0x0
f0102074:	68 00 10 00 00       	push   $0x1000
f0102079:	52                   	push   %edx
f010207a:	50                   	push   %eax
f010207b:	e8 8c 2b 00 00       	call   f0104c0c <map_frame>
f0102080:	83 c4 10             	add    $0x10,%esp
f0102083:	85 c0                	test   %eax,%eax
f0102085:	74 19                	je     f01020a0 <page_check+0x499>
f0102087:	68 08 81 10 f0       	push   $0xf0108108
f010208c:	68 36 7d 10 f0       	push   $0xf0107d36
f0102091:	68 cc 00 00 00       	push   $0xcc
f0102096:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010209b:	e8 8e e0 ff ff       	call   f010012e <_panic>

	// should have pp1 at both 0 and PAGE_SIZE, pp2 nowhere, ...
	assert(check_va2pa(ptr_page_directory, 0) == to_physical_address(pp1));
f01020a0:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01020a5:	83 ec 08             	sub    $0x8,%esp
f01020a8:	6a 00                	push   $0x0
f01020aa:	50                   	push   %eax
f01020ab:	e8 91 fa ff ff       	call   f0101b41 <check_va2pa>
f01020b0:	83 c4 10             	add    $0x10,%esp
f01020b3:	89 c3                	mov    %eax,%ebx
f01020b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020b8:	83 ec 0c             	sub    $0xc,%esp
f01020bb:	50                   	push   %eax
f01020bc:	e8 35 f7 ff ff       	call   f01017f6 <to_physical_address>
f01020c1:	83 c4 10             	add    $0x10,%esp
f01020c4:	39 c3                	cmp    %eax,%ebx
f01020c6:	74 19                	je     f01020e1 <page_check+0x4da>
f01020c8:	68 48 81 10 f0       	push   $0xf0108148
f01020cd:	68 36 7d 10 f0       	push   $0xf0107d36
f01020d2:	68 cf 00 00 00       	push   $0xcf
f01020d7:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01020dc:	e8 4d e0 ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f01020e1:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01020e6:	83 ec 08             	sub    $0x8,%esp
f01020e9:	68 00 10 00 00       	push   $0x1000
f01020ee:	50                   	push   %eax
f01020ef:	e8 4d fa ff ff       	call   f0101b41 <check_va2pa>
f01020f4:	83 c4 10             	add    $0x10,%esp
f01020f7:	89 c3                	mov    %eax,%ebx
f01020f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020fc:	83 ec 0c             	sub    $0xc,%esp
f01020ff:	50                   	push   %eax
f0102100:	e8 f1 f6 ff ff       	call   f01017f6 <to_physical_address>
f0102105:	83 c4 10             	add    $0x10,%esp
f0102108:	39 c3                	cmp    %eax,%ebx
f010210a:	74 19                	je     f0102125 <page_check+0x51e>
f010210c:	68 88 81 10 f0       	push   $0xf0108188
f0102111:	68 36 7d 10 f0       	push   $0xf0107d36
f0102116:	68 d0 00 00 00       	push   $0xd0
f010211b:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102120:	e8 09 e0 ff ff       	call   f010012e <_panic>
	// ... and ref counts should reflect this
	assert(pp1->references == 2);
f0102125:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102128:	8b 40 08             	mov    0x8(%eax),%eax
f010212b:	66 83 f8 02          	cmp    $0x2,%ax
f010212f:	74 19                	je     f010214a <page_check+0x543>
f0102131:	68 cf 81 10 f0       	push   $0xf01081cf
f0102136:	68 36 7d 10 f0       	push   $0xf0107d36
f010213b:	68 d2 00 00 00       	push   $0xd2
f0102140:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102145:	e8 e4 df ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f010214a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010214d:	8b 40 08             	mov    0x8(%eax),%eax
f0102150:	66 85 c0             	test   %ax,%ax
f0102153:	74 19                	je     f010216e <page_check+0x567>
f0102155:	68 e4 81 10 f0       	push   $0xf01081e4
f010215a:	68 36 7d 10 f0       	push   $0xf0107d36
f010215f:	68 d3 00 00 00       	push   $0xd3
f0102164:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102169:	e8 c0 df ff ff       	call   f010012e <_panic>

	// pp2 should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp2);
f010216e:	83 ec 0c             	sub    $0xc,%esp
f0102171:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102174:	50                   	push   %eax
f0102175:	e8 85 28 00 00       	call   f01049ff <allocate_frame>
f010217a:	83 c4 10             	add    $0x10,%esp
f010217d:	85 c0                	test   %eax,%eax
f010217f:	75 0a                	jne    f010218b <page_check+0x584>
f0102181:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102184:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102187:	39 c2                	cmp    %eax,%edx
f0102189:	74 19                	je     f01021a4 <page_check+0x59d>
f010218b:	68 fc 81 10 f0       	push   $0xf01081fc
f0102190:	68 36 7d 10 f0       	push   $0xf0107d36
f0102195:	68 d6 00 00 00       	push   $0xd6
f010219a:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010219f:	e8 8a df ff ff       	call   f010012e <_panic>

	// unmapping pp1 at 0 should keep pp1 at PAGE_SIZE
	unmap_frame(ptr_page_directory, 0x0);
f01021a4:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01021a9:	83 ec 08             	sub    $0x8,%esp
f01021ac:	6a 00                	push   $0x0
f01021ae:	50                   	push   %eax
f01021af:	e8 76 2b 00 00       	call   f0104d2a <unmap_frame>
f01021b4:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f01021b7:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01021bc:	83 ec 08             	sub    $0x8,%esp
f01021bf:	6a 00                	push   $0x0
f01021c1:	50                   	push   %eax
f01021c2:	e8 7a f9 ff ff       	call   f0101b41 <check_va2pa>
f01021c7:	83 c4 10             	add    $0x10,%esp
f01021ca:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021cd:	74 19                	je     f01021e8 <page_check+0x5e1>
f01021cf:	68 24 82 10 f0       	push   $0xf0108224
f01021d4:	68 36 7d 10 f0       	push   $0xf0107d36
f01021d9:	68 da 00 00 00       	push   $0xda
f01021de:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01021e3:	e8 46 df ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == to_physical_address(pp1));
f01021e8:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01021ed:	83 ec 08             	sub    $0x8,%esp
f01021f0:	68 00 10 00 00       	push   $0x1000
f01021f5:	50                   	push   %eax
f01021f6:	e8 46 f9 ff ff       	call   f0101b41 <check_va2pa>
f01021fb:	83 c4 10             	add    $0x10,%esp
f01021fe:	89 c3                	mov    %eax,%ebx
f0102200:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102203:	83 ec 0c             	sub    $0xc,%esp
f0102206:	50                   	push   %eax
f0102207:	e8 ea f5 ff ff       	call   f01017f6 <to_physical_address>
f010220c:	83 c4 10             	add    $0x10,%esp
f010220f:	39 c3                	cmp    %eax,%ebx
f0102211:	74 19                	je     f010222c <page_check+0x625>
f0102213:	68 88 81 10 f0       	push   $0xf0108188
f0102218:	68 36 7d 10 f0       	push   $0xf0107d36
f010221d:	68 db 00 00 00       	push   $0xdb
f0102222:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102227:	e8 02 df ff ff       	call   f010012e <_panic>
	assert(pp1->references == 1);
f010222c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010222f:	8b 40 08             	mov    0x8(%eax),%eax
f0102232:	66 83 f8 01          	cmp    $0x1,%ax
f0102236:	74 19                	je     f0102251 <page_check+0x64a>
f0102238:	68 05 80 10 f0       	push   $0xf0108005
f010223d:	68 36 7d 10 f0       	push   $0xf0107d36
f0102242:	68 dc 00 00 00       	push   $0xdc
f0102247:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010224c:	e8 dd de ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0102251:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102254:	8b 40 08             	mov    0x8(%eax),%eax
f0102257:	66 85 c0             	test   %ax,%ax
f010225a:	74 19                	je     f0102275 <page_check+0x66e>
f010225c:	68 e4 81 10 f0       	push   $0xf01081e4
f0102261:	68 36 7d 10 f0       	push   $0xf0107d36
f0102266:	68 dd 00 00 00       	push   $0xdd
f010226b:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102270:	e8 b9 de ff ff       	call   f010012e <_panic>

	// unmapping pp1 at PAGE_SIZE should free it
	unmap_frame(ptr_page_directory, (void*) PAGE_SIZE);
f0102275:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f010227a:	83 ec 08             	sub    $0x8,%esp
f010227d:	68 00 10 00 00       	push   $0x1000
f0102282:	50                   	push   %eax
f0102283:	e8 a2 2a 00 00       	call   f0104d2a <unmap_frame>
f0102288:	83 c4 10             	add    $0x10,%esp
	assert(check_va2pa(ptr_page_directory, 0x0) == ~0);
f010228b:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102290:	83 ec 08             	sub    $0x8,%esp
f0102293:	6a 00                	push   $0x0
f0102295:	50                   	push   %eax
f0102296:	e8 a6 f8 ff ff       	call   f0101b41 <check_va2pa>
f010229b:	83 c4 10             	add    $0x10,%esp
f010229e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022a1:	74 19                	je     f01022bc <page_check+0x6b5>
f01022a3:	68 24 82 10 f0       	push   $0xf0108224
f01022a8:	68 36 7d 10 f0       	push   $0xf0107d36
f01022ad:	68 e1 00 00 00       	push   $0xe1
f01022b2:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01022b7:	e8 72 de ff ff       	call   f010012e <_panic>
	assert(check_va2pa(ptr_page_directory, PAGE_SIZE) == ~0);
f01022bc:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01022c1:	83 ec 08             	sub    $0x8,%esp
f01022c4:	68 00 10 00 00       	push   $0x1000
f01022c9:	50                   	push   %eax
f01022ca:	e8 72 f8 ff ff       	call   f0101b41 <check_va2pa>
f01022cf:	83 c4 10             	add    $0x10,%esp
f01022d2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022d5:	74 19                	je     f01022f0 <page_check+0x6e9>
f01022d7:	68 50 82 10 f0       	push   $0xf0108250
f01022dc:	68 36 7d 10 f0       	push   $0xf0107d36
f01022e1:	68 e2 00 00 00       	push   $0xe2
f01022e6:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01022eb:	e8 3e de ff ff       	call   f010012e <_panic>
	assert(pp1->references == 0);
f01022f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01022f3:	8b 40 08             	mov    0x8(%eax),%eax
f01022f6:	66 85 c0             	test   %ax,%ax
f01022f9:	74 19                	je     f0102314 <page_check+0x70d>
f01022fb:	68 81 82 10 f0       	push   $0xf0108281
f0102300:	68 36 7d 10 f0       	push   $0xf0107d36
f0102305:	68 e3 00 00 00       	push   $0xe3
f010230a:	68 c5 7c 10 f0       	push   $0xf0107cc5
f010230f:	e8 1a de ff ff       	call   f010012e <_panic>
	assert(pp2->references == 0);
f0102314:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102317:	8b 40 08             	mov    0x8(%eax),%eax
f010231a:	66 85 c0             	test   %ax,%ax
f010231d:	74 19                	je     f0102338 <page_check+0x731>
f010231f:	68 e4 81 10 f0       	push   $0xf01081e4
f0102324:	68 36 7d 10 f0       	push   $0xf0107d36
f0102329:	68 e4 00 00 00       	push   $0xe4
f010232e:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102333:	e8 f6 dd ff ff       	call   f010012e <_panic>

	// so it should be returned by allocate_frame
	assert(allocate_frame(&pp) == 0 && pp == pp1);
f0102338:	83 ec 0c             	sub    $0xc,%esp
f010233b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010233e:	50                   	push   %eax
f010233f:	e8 bb 26 00 00       	call   f01049ff <allocate_frame>
f0102344:	83 c4 10             	add    $0x10,%esp
f0102347:	85 c0                	test   %eax,%eax
f0102349:	75 0a                	jne    f0102355 <page_check+0x74e>
f010234b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010234e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102351:	39 c2                	cmp    %eax,%edx
f0102353:	74 19                	je     f010236e <page_check+0x767>
f0102355:	68 98 82 10 f0       	push   $0xf0108298
f010235a:	68 36 7d 10 f0       	push   $0xf0107d36
f010235f:	68 e7 00 00 00       	push   $0xe7
f0102364:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102369:	e8 c0 dd ff ff       	call   f010012e <_panic>

	// should be no free memory
	assert(allocate_frame(&pp) == E_NO_MEM);
f010236e:	83 ec 0c             	sub    $0xc,%esp
f0102371:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102374:	50                   	push   %eax
f0102375:	e8 85 26 00 00       	call   f01049ff <allocate_frame>
f010237a:	83 c4 10             	add    $0x10,%esp
f010237d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102380:	74 19                	je     f010239b <page_check+0x794>
f0102382:	68 00 7f 10 f0       	push   $0xf0107f00
f0102387:	68 36 7d 10 f0       	push   $0xf0107d36
f010238c:	68 ea 00 00 00       	push   $0xea
f0102391:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102396:	e8 93 dd ff ff       	call   f010012e <_panic>

	// forcibly take pp0 back
	assert(EXTRACT_ADDRESS(ptr_page_directory[0]) == to_physical_address(pp0));
f010239b:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01023a0:	8b 00                	mov    (%eax),%eax
f01023a2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01023a7:	89 c3                	mov    %eax,%ebx
f01023a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01023ac:	83 ec 0c             	sub    $0xc,%esp
f01023af:	50                   	push   %eax
f01023b0:	e8 41 f4 ff ff       	call   f01017f6 <to_physical_address>
f01023b5:	83 c4 10             	add    $0x10,%esp
f01023b8:	39 c3                	cmp    %eax,%ebx
f01023ba:	74 19                	je     f01023d5 <page_check+0x7ce>
f01023bc:	68 80 7f 10 f0       	push   $0xf0107f80
f01023c1:	68 36 7d 10 f0       	push   $0xf0107d36
f01023c6:	68 ed 00 00 00       	push   $0xed
f01023cb:	68 c5 7c 10 f0       	push   $0xf0107cc5
f01023d0:	e8 59 dd ff ff       	call   f010012e <_panic>
	ptr_page_directory[0] = 0;
f01023d5:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01023da:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->references == 1);
f01023e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01023e3:	8b 40 08             	mov    0x8(%eax),%eax
f01023e6:	66 83 f8 01          	cmp    $0x1,%ax
f01023ea:	74 19                	je     f0102405 <page_check+0x7fe>
f01023ec:	68 1a 80 10 f0       	push   $0xf010801a
f01023f1:	68 36 7d 10 f0       	push   $0xf0107d36
f01023f6:	68 ef 00 00 00       	push   $0xef
f01023fb:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102400:	e8 29 dd ff ff       	call   f010012e <_panic>
	pp0->references = 0;
f0102405:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102408:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	free_frame_list = fl;
f010240e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102411:	a3 c0 49 15 f0       	mov    %eax,0xf01549c0

	// free the frames_info we took
	free_frame(pp0);
f0102416:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102419:	83 ec 0c             	sub    $0xc,%esp
f010241c:	50                   	push   %eax
f010241d:	e8 44 26 00 00       	call   f0104a66 <free_frame>
f0102422:	83 c4 10             	add    $0x10,%esp
	free_frame(pp1);
f0102425:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102428:	83 ec 0c             	sub    $0xc,%esp
f010242b:	50                   	push   %eax
f010242c:	e8 35 26 00 00       	call   f0104a66 <free_frame>
f0102431:	83 c4 10             	add    $0x10,%esp
	free_frame(pp2);
f0102434:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102437:	83 ec 0c             	sub    $0xc,%esp
f010243a:	50                   	push   %eax
f010243b:	e8 26 26 00 00       	call   f0104a66 <free_frame>
f0102440:	83 c4 10             	add    $0x10,%esp

	cprintf("page_check() succeeded!\n");
f0102443:	83 ec 0c             	sub    $0xc,%esp
f0102446:	68 be 82 10 f0       	push   $0xf01082be
f010244b:	e8 64 32 00 00       	call   f01056b4 <cprintf>
f0102450:	83 c4 10             	add    $0x10,%esp
}
f0102453:	90                   	nop
f0102454:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102457:	c9                   	leave  
f0102458:	c3                   	ret    

f0102459 <turn_on_paging>:

void turn_on_paging()
{
f0102459:	55                   	push   %ebp
f010245a:	89 e5                	mov    %esp,%ebp
f010245c:	83 ec 20             	sub    $0x20,%esp
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA (KERNEL_BASE), i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	ptr_page_directory[0] = ptr_page_directory[PDX(KERNEL_BASE)];
f010245f:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102464:	8b 15 cc 49 15 f0    	mov    0xf01549cc,%edx
f010246a:	8b 92 00 0f 00 00    	mov    0xf00(%edx),%edx
f0102470:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(phys_page_directory);
f0102472:	a1 d0 49 15 f0       	mov    0xf01549d0,%eax
f0102477:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010247a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010247d:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32
rcr0(void)
{
	uint32 val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102480:	0f 20 c0             	mov    %cr0,%eax
f0102483:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return val;
f0102486:	8b 45 f4             	mov    -0xc(%ebp),%eax

	// Turn on paging.
	uint32 cr0;
	cr0 = rcr0();
f0102489:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f010248c:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f0102493:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f0102497:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010249a:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static __inline void
lcr0(uint32 val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010249d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01024a0:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNEL_BASE+x => x => x.
	// (x < 4MB so uses paging ptr_page_directory[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f01024a3:	0f 01 15 b0 16 12 f0 	lgdtl  0xf01216b0
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01024aa:	b8 23 00 00 00       	mov    $0x23,%eax
f01024af:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01024b1:	b8 23 00 00 00       	mov    $0x23,%eax
f01024b6:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01024b8:	b8 10 00 00 00       	mov    $0x10,%eax
f01024bd:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01024bf:	b8 10 00 00 00       	mov    $0x10,%eax
f01024c4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01024c6:	b8 10 00 00 00       	mov    $0x10,%eax
f01024cb:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01024cd:	ea d4 24 10 f0 08 00 	ljmp   $0x8,$0xf01024d4
	asm volatile("lldt %%ax" :: "a" (0));
f01024d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01024d9:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNEL_BASE + x => KERNEL_BASE + x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	ptr_page_directory[0] = 0;
f01024dc:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01024e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the ptr_page_directory[0] mapping.
	lcr3(phys_page_directory);
f01024e7:	a1 d0 49 15 f0       	mov    0xf01549d0,%eax
f01024ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static __inline void
lcr3(uint32 val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01024ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01024f2:	0f 22 d8             	mov    %eax,%cr3
}
f01024f5:	90                   	nop
f01024f6:	c9                   	leave  
f01024f7:	c3                   	ret    

f01024f8 <setup_listing_to_all_page_tables_entries>:

void setup_listing_to_all_page_tables_entries()
{
f01024f8:	55                   	push   %ebp
f01024f9:	89 e5                	mov    %esp,%ebp
f01024fb:	83 ec 18             	sub    $0x18,%esp
	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address VPT.

	// Permissions: kernel RW, user NONE
	uint32 phys_frame_address = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01024fe:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102503:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102506:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f010250d:	77 17                	ja     f0102526 <setup_listing_to_all_page_tables_entries+0x2e>
f010250f:	ff 75 f4             	pushl  -0xc(%ebp)
f0102512:	68 94 7c 10 f0       	push   $0xf0107c94
f0102517:	68 39 01 00 00       	push   $0x139
f010251c:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102521:	e8 08 dc ff ff       	call   f010012e <_panic>
f0102526:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102529:	05 00 00 00 10       	add    $0x10000000,%eax
f010252e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	ptr_page_directory[PDX(VPT)] = CONSTRUCT_ENTRY(phys_frame_address , PERM_PRESENT | PERM_WRITEABLE);
f0102531:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102536:	05 fc 0e 00 00       	add    $0xefc,%eax
f010253b:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010253e:	83 ca 03             	or     $0x3,%edx
f0102541:	89 10                	mov    %edx,(%eax)

	// same for UVPT
	//Permissions: kernel R, user R
	ptr_page_directory[PDX(UVPT)] = K_PHYSICAL_ADDRESS(ptr_page_directory)|PERM_USER|PERM_PRESENT;
f0102543:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102548:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f010254e:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0102553:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102556:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f010255d:	77 17                	ja     f0102576 <setup_listing_to_all_page_tables_entries+0x7e>
f010255f:	ff 75 ec             	pushl  -0x14(%ebp)
f0102562:	68 94 7c 10 f0       	push   $0xf0107c94
f0102567:	68 3e 01 00 00       	push   $0x13e
f010256c:	68 c5 7c 10 f0       	push   $0xf0107cc5
f0102571:	e8 b8 db ff ff       	call   f010012e <_panic>
f0102576:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102579:	05 00 00 00 10       	add    $0x10000000,%eax
f010257e:	83 c8 05             	or     $0x5,%eax
f0102581:	89 02                	mov    %eax,(%edx)

}
f0102583:	90                   	nop
f0102584:	c9                   	leave  
f0102585:	c3                   	ret    

f0102586 <envid2env>:
//   0 on success, -E_BAD_ENV on error.
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int envid2env(int32  envid, struct Env **env_store, bool checkperm)
{
f0102586:	55                   	push   %ebp
f0102587:	89 e5                	mov    %esp,%ebp
f0102589:	83 ec 10             	sub    $0x10,%esp
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010258c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102590:	75 15                	jne    f01025a7 <envid2env+0x21>
		*env_store = curenv;
f0102592:	8b 15 74 3f 15 f0    	mov    0xf0153f74,%edx
f0102598:	8b 45 0c             	mov    0xc(%ebp),%eax
f010259b:	89 10                	mov    %edx,(%eax)
		return 0;
f010259d:	b8 00 00 00 00       	mov    $0x0,%eax
f01025a2:	e9 8c 00 00 00       	jmp    f0102633 <envid2env+0xad>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01025a7:	8b 15 70 3f 15 f0    	mov    0xf0153f70,%edx
f01025ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01025b0:	25 ff 03 00 00       	and    $0x3ff,%eax
f01025b5:	89 c1                	mov    %eax,%ecx
f01025b7:	89 c8                	mov    %ecx,%eax
f01025b9:	c1 e0 02             	shl    $0x2,%eax
f01025bc:	01 c8                	add    %ecx,%eax
f01025be:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01025c5:	01 c8                	add    %ecx,%eax
f01025c7:	c1 e0 02             	shl    $0x2,%eax
f01025ca:	01 d0                	add    %edx,%eax
f01025cc:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01025cf:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01025d2:	8b 40 54             	mov    0x54(%eax),%eax
f01025d5:	85 c0                	test   %eax,%eax
f01025d7:	74 0b                	je     f01025e4 <envid2env+0x5e>
f01025d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01025dc:	8b 40 4c             	mov    0x4c(%eax),%eax
f01025df:	3b 45 08             	cmp    0x8(%ebp),%eax
f01025e2:	74 10                	je     f01025f4 <envid2env+0x6e>
		*env_store = 0;
f01025e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025e7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01025ed:	b8 02 00 00 00       	mov    $0x2,%eax
f01025f2:	eb 3f                	jmp    f0102633 <envid2env+0xad>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01025f4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01025f8:	74 2c                	je     f0102626 <envid2env+0xa0>
f01025fa:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f01025ff:	39 45 fc             	cmp    %eax,-0x4(%ebp)
f0102602:	74 22                	je     f0102626 <envid2env+0xa0>
f0102604:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102607:	8b 50 50             	mov    0x50(%eax),%edx
f010260a:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f010260f:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102612:	39 c2                	cmp    %eax,%edx
f0102614:	74 10                	je     f0102626 <envid2env+0xa0>
		*env_store = 0;
f0102616:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102619:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010261f:	b8 02 00 00 00       	mov    $0x2,%eax
f0102624:	eb 0d                	jmp    f0102633 <envid2env+0xad>
	}

	*env_store = e;
f0102626:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102629:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010262c:	89 10                	mov    %edx,(%eax)
	return 0;
f010262e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102633:	c9                   	leave  
f0102634:	c3                   	ret    

f0102635 <TestAssignment2>:

//define the white-space symbols
#define WHITESPACE "\t\r\n "

void TestAssignment2()
{
f0102635:	55                   	push   %ebp
f0102636:	89 e5                	mov    %esp,%ebp
f0102638:	83 ec 08             	sub    $0x8,%esp
	cprintf("\n========================\n");
f010263b:	83 ec 0c             	sub    $0xc,%esp
f010263e:	68 e0 82 10 f0       	push   $0xf01082e0
f0102643:	e8 6c 30 00 00       	call   f01056b4 <cprintf>
f0102648:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q1:\n");
f010264b:	83 ec 0c             	sub    $0xc,%esp
f010264e:	68 fb 82 10 f0       	push   $0xf01082fb
f0102653:	e8 5c 30 00 00       	call   f01056b4 <cprintf>
f0102658:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f010265b:	83 ec 0c             	sub    $0xc,%esp
f010265e:	68 15 83 10 f0       	push   $0xf0108315
f0102663:	e8 4c 30 00 00       	call   f01056b4 <cprintf>
f0102668:	83 c4 10             	add    $0x10,%esp
	TestAss2Q1();
f010266b:	e8 d7 00 00 00       	call   f0102747 <TestAss2Q1>
	cprintf("\n========================\n");
f0102670:	83 ec 0c             	sub    $0xc,%esp
f0102673:	68 e0 82 10 f0       	push   $0xf01082e0
f0102678:	e8 37 30 00 00       	call   f01056b4 <cprintf>
f010267d:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q2:\n");
f0102680:	83 ec 0c             	sub    $0xc,%esp
f0102683:	68 2f 83 10 f0       	push   $0xf010832f
f0102688:	e8 27 30 00 00       	call   f01056b4 <cprintf>
f010268d:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f0102690:	83 ec 0c             	sub    $0xc,%esp
f0102693:	68 15 83 10 f0       	push   $0xf0108315
f0102698:	e8 17 30 00 00       	call   f01056b4 <cprintf>
f010269d:	83 c4 10             	add    $0x10,%esp
	TestAss2Q2();
f01026a0:	e8 ec 03 00 00       	call   f0102a91 <TestAss2Q2>
	cprintf("\n========================\n");
f01026a5:	83 ec 0c             	sub    $0xc,%esp
f01026a8:	68 e0 82 10 f0       	push   $0xf01082e0
f01026ad:	e8 02 30 00 00       	call   f01056b4 <cprintf>
f01026b2:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q3:\n");
f01026b5:	83 ec 0c             	sub    $0xc,%esp
f01026b8:	68 49 83 10 f0       	push   $0xf0108349
f01026bd:	e8 f2 2f 00 00       	call   f01056b4 <cprintf>
f01026c2:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f01026c5:	83 ec 0c             	sub    $0xc,%esp
f01026c8:	68 15 83 10 f0       	push   $0xf0108315
f01026cd:	e8 e2 2f 00 00       	call   f01056b4 <cprintf>
f01026d2:	83 c4 10             	add    $0x10,%esp
	TestAss2Q3();
f01026d5:	e8 40 08 00 00       	call   f0102f1a <TestAss2Q3>
	cprintf("\n========================\n");
f01026da:	83 ec 0c             	sub    $0xc,%esp
f01026dd:	68 e0 82 10 f0       	push   $0xf01082e0
f01026e2:	e8 cd 2f 00 00       	call   f01056b4 <cprintf>
f01026e7:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of Q4:\n");
f01026ea:	83 ec 0c             	sub    $0xc,%esp
f01026ed:	68 63 83 10 f0       	push   $0xf0108363
f01026f2:	e8 bd 2f 00 00       	call   f01056b4 <cprintf>
f01026f7:	83 c4 10             	add    $0x10,%esp
	cprintf("========================\n");
f01026fa:	83 ec 0c             	sub    $0xc,%esp
f01026fd:	68 15 83 10 f0       	push   $0xf0108315
f0102702:	e8 ad 2f 00 00       	call   f01056b4 <cprintf>
f0102707:	83 c4 10             	add    $0x10,%esp
	TestAss2Q4();
f010270a:	e8 05 0e 00 00       	call   f0103514 <TestAss2Q4>
	cprintf("\n===========================\n");
f010270f:	83 ec 0c             	sub    $0xc,%esp
f0102712:	68 7d 83 10 f0       	push   $0xf010837d
f0102717:	e8 98 2f 00 00       	call   f01056b4 <cprintf>
f010271c:	83 c4 10             	add    $0x10,%esp
	cprintf("Automatic Testing of BONUS:\n");
f010271f:	83 ec 0c             	sub    $0xc,%esp
f0102722:	68 9b 83 10 f0       	push   $0xf010839b
f0102727:	e8 88 2f 00 00       	call   f01056b4 <cprintf>
f010272c:	83 c4 10             	add    $0x10,%esp
	cprintf("===========================\n");
f010272f:	83 ec 0c             	sub    $0xc,%esp
f0102732:	68 b8 83 10 f0       	push   $0xf01083b8
f0102737:	e8 78 2f 00 00       	call   f01056b4 <cprintf>
f010273c:	83 c4 10             	add    $0x10,%esp
	TestAss2BONUS();
f010273f:	e8 32 10 00 00       	call   f0103776 <TestAss2BONUS>
}
f0102744:	90                   	nop
f0102745:	c9                   	leave  
f0102746:	c3                   	ret    

f0102747 <TestAss2Q1>:

int TestAss2Q1()
{
f0102747:	55                   	push   %ebp
f0102748:	89 e5                	mov    %esp,%ebp
f010274a:	57                   	push   %edi
f010274b:	56                   	push   %esi
f010274c:	53                   	push   %ebx
f010274d:	81 ec ac 01 00 00    	sub    $0x1ac,%esp
	int retValue = 1;
f0102753:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
	int i = 0;
f010275a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	//Create first array
	char cr1[100] = "cnia x 3 1 2 3";
f0102761:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0102767:	bb 42 85 10 f0       	mov    $0xf0108542,%ebx
f010276c:	ba 0f 00 00 00       	mov    $0xf,%edx
f0102771:	89 c7                	mov    %eax,%edi
f0102773:	89 de                	mov    %ebx,%esi
f0102775:	89 d1                	mov    %edx,%ecx
f0102777:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102779:	8d 95 7f ff ff ff    	lea    -0x81(%ebp),%edx
f010277f:	b9 55 00 00 00       	mov    $0x55,%ecx
f0102784:	b0 00                	mov    $0x0,%al
f0102786:	89 d7                	mov    %edx,%edi
f0102788:	f3 aa                	rep stos %al,%es:(%edi)
	int numOfArgs = 0;
f010278a:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102791:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f0102794:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f010279a:	50                   	push   %eax
f010279b:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f01027a1:	50                   	push   %eax
f01027a2:	68 d5 83 10 f0       	push   $0xf01083d5
f01027a7:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f01027ad:	50                   	push   %eax
f01027ae:	e8 9c 48 00 00       	call   f010704f <strsplit>
f01027b3:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs, args) ;
f01027b6:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f01027bc:	83 ec 08             	sub    $0x8,%esp
f01027bf:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f01027c5:	52                   	push   %edx
f01027c6:	50                   	push   %eax
f01027c7:	e8 a6 e6 ff ff       	call   f0100e72 <CreateIntArray>
f01027cc:	83 c4 10             	add    $0x10,%esp
f01027cf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f01027d2:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f01027d9:	77 16                	ja     f01027f1 <TestAss2Q1+0xaa>
f01027db:	68 da 83 10 f0       	push   $0xf01083da
f01027e0:	68 f3 83 10 f0       	push   $0xf01083f3
f01027e5:	6a 29                	push   $0x29
f01027e7:	68 08 84 10 f0       	push   $0xf0108408
f01027ec:	e8 3d d9 ff ff       	call   f010012e <_panic>

	//Check elements of 1st array
	int expectedArr1[] = {1, 2, 3};
f01027f1:	8d 85 20 ff ff ff    	lea    -0xe0(%ebp),%eax
f01027f7:	bb a8 85 10 f0       	mov    $0xf01085a8,%ebx
f01027fc:	ba 03 00 00 00       	mov    $0x3,%edx
f0102801:	89 c7                	mov    %eax,%edi
f0102803:	89 de                	mov    %ebx,%esi
f0102805:	89 d1                	mov    %edx,%ecx
f0102807:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr1, ptr1, 3))
f0102809:	83 ec 04             	sub    $0x4,%esp
f010280c:	6a 03                	push   $0x3
f010280e:	ff 75 dc             	pushl  -0x24(%ebp)
f0102811:	8d 85 20 ff ff ff    	lea    -0xe0(%ebp),%eax
f0102817:	50                   	push   %eax
f0102818:	e8 b0 1a 00 00       	call   f01042cd <CheckArrays>
f010281d:	83 c4 10             	add    $0x10,%esp
f0102820:	85 c0                	test   %eax,%eax
f0102822:	75 18                	jne    f010283c <TestAss2Q1+0xf5>
	{
		cprintf("[EVAL] #1 CreateIntArray: Failed\n");
f0102824:	83 ec 0c             	sub    $0xc,%esp
f0102827:	68 18 84 10 f0       	push   $0xf0108418
f010282c:	e8 83 2e 00 00       	call   f01056b4 <cprintf>
f0102831:	83 c4 10             	add    $0x10,%esp
		return retValue;
f0102834:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102837:	e9 4d 02 00 00       	jmp    f0102a89 <TestAss2Q1+0x342>
	}

	//Create second array
	char cr2[100] = "cnia myArr 4 7 8";
f010283c:	8d 85 bc fe ff ff    	lea    -0x144(%ebp),%eax
f0102842:	bb b4 85 10 f0       	mov    $0xf01085b4,%ebx
f0102847:	ba 11 00 00 00       	mov    $0x11,%edx
f010284c:	89 c7                	mov    %eax,%edi
f010284e:	89 de                	mov    %ebx,%esi
f0102850:	89 d1                	mov    %edx,%ecx
f0102852:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102854:	8d 95 cd fe ff ff    	lea    -0x133(%ebp),%edx
f010285a:	b9 53 00 00 00       	mov    $0x53,%ecx
f010285f:	b0 00                	mov    $0x0,%al
f0102861:	89 d7                	mov    %edx,%edi
f0102863:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102865:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f010286c:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f010286f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102875:	50                   	push   %eax
f0102876:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010287c:	50                   	push   %eax
f010287d:	68 d5 83 10 f0       	push   $0xf01083d5
f0102882:	8d 85 bc fe ff ff    	lea    -0x144(%ebp),%eax
f0102888:	50                   	push   %eax
f0102889:	e8 c1 47 00 00       	call   f010704f <strsplit>
f010288e:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
f0102891:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0102897:	83 ec 08             	sub    $0x8,%esp
f010289a:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f01028a0:	52                   	push   %edx
f01028a1:	50                   	push   %eax
f01028a2:	e8 cb e5 ff ff       	call   f0100e72 <CreateIntArray>
f01028a7:	83 c4 10             	add    $0x10,%esp
f01028aa:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF100000C);
f01028ad:	81 7d d8 0b 00 00 f1 	cmpl   $0xf100000b,-0x28(%ebp)
f01028b4:	77 16                	ja     f01028cc <TestAss2Q1+0x185>
f01028b6:	68 3a 84 10 f0       	push   $0xf010843a
f01028bb:	68 f3 83 10 f0       	push   $0xf01083f3
f01028c0:	6a 39                	push   $0x39
f01028c2:	68 08 84 10 f0       	push   $0xf0108408
f01028c7:	e8 62 d8 ff ff       	call   f010012e <_panic>

	//Check elements of 2nd array
	int expectedArr2[] = {7, 8, 0, 0};
f01028cc:	8d 85 ac fe ff ff    	lea    -0x154(%ebp),%eax
f01028d2:	bb 18 86 10 f0       	mov    $0xf0108618,%ebx
f01028d7:	ba 04 00 00 00       	mov    $0x4,%edx
f01028dc:	89 c7                	mov    %eax,%edi
f01028de:	89 de                	mov    %ebx,%esi
f01028e0:	89 d1                	mov    %edx,%ecx
f01028e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr2, ptr2, 4))
f01028e4:	83 ec 04             	sub    $0x4,%esp
f01028e7:	6a 04                	push   $0x4
f01028e9:	ff 75 d8             	pushl  -0x28(%ebp)
f01028ec:	8d 85 ac fe ff ff    	lea    -0x154(%ebp),%eax
f01028f2:	50                   	push   %eax
f01028f3:	e8 d5 19 00 00       	call   f01042cd <CheckArrays>
f01028f8:	83 c4 10             	add    $0x10,%esp
f01028fb:	85 c0                	test   %eax,%eax
f01028fd:	75 18                	jne    f0102917 <TestAss2Q1+0x1d0>
	{
		cprintf("[EVAL] #2 CreateIntArray: Failed\n");
f01028ff:	83 ec 0c             	sub    $0xc,%esp
f0102902:	68 54 84 10 f0       	push   $0xf0108454
f0102907:	e8 a8 2d 00 00       	call   f01056b4 <cprintf>
f010290c:	83 c4 10             	add    $0x10,%esp
		return retValue;
f010290f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102912:	e9 72 01 00 00       	jmp    f0102a89 <TestAss2Q1+0x342>
	}

	//Check elements of 1st array
	if (!CheckArrays(expectedArr1, ptr1, 3))
f0102917:	83 ec 04             	sub    $0x4,%esp
f010291a:	6a 03                	push   $0x3
f010291c:	ff 75 dc             	pushl  -0x24(%ebp)
f010291f:	8d 85 20 ff ff ff    	lea    -0xe0(%ebp),%eax
f0102925:	50                   	push   %eax
f0102926:	e8 a2 19 00 00       	call   f01042cd <CheckArrays>
f010292b:	83 c4 10             	add    $0x10,%esp
f010292e:	85 c0                	test   %eax,%eax
f0102930:	75 18                	jne    f010294a <TestAss2Q1+0x203>
	{
		cprintf("[EVAL] #3 CreateIntArray: Failed\n");
f0102932:	83 ec 0c             	sub    $0xc,%esp
f0102935:	68 78 84 10 f0       	push   $0xf0108478
f010293a:	e8 75 2d 00 00       	call   f01056b4 <cprintf>
f010293f:	83 c4 10             	add    $0x10,%esp
		return retValue;
f0102942:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102945:	e9 3f 01 00 00       	jmp    f0102a89 <TestAss2Q1+0x342>
	}

	//Create third array
	char cr3[100] = "cnia zeros 10";
f010294a:	8d 85 48 fe ff ff    	lea    -0x1b8(%ebp),%eax
f0102950:	bb 28 86 10 f0       	mov    $0xf0108628,%ebx
f0102955:	ba 0e 00 00 00       	mov    $0xe,%edx
f010295a:	89 c7                	mov    %eax,%edi
f010295c:	89 de                	mov    %ebx,%esi
f010295e:	89 d1                	mov    %edx,%ecx
f0102960:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102962:	8d 95 56 fe ff ff    	lea    -0x1aa(%ebp),%edx
f0102968:	b9 56 00 00 00       	mov    $0x56,%ecx
f010296d:	b0 00                	mov    $0x0,%al
f010296f:	89 d7                	mov    %edx,%edi
f0102971:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102973:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f010297a:	00 00 00 
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f010297d:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102983:	50                   	push   %eax
f0102984:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010298a:	50                   	push   %eax
f010298b:	68 d5 83 10 f0       	push   $0xf01083d5
f0102990:	8d 85 48 fe ff ff    	lea    -0x1b8(%ebp),%eax
f0102996:	50                   	push   %eax
f0102997:	e8 b3 46 00 00       	call   f010704f <strsplit>
f010299c:	83 c4 10             	add    $0x10,%esp

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
f010299f:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f01029a5:	83 ec 08             	sub    $0x8,%esp
f01029a8:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f01029ae:	52                   	push   %edx
f01029af:	50                   	push   %eax
f01029b0:	e8 bd e4 ff ff       	call   f0100e72 <CreateIntArray>
f01029b5:	83 c4 10             	add    $0x10,%esp
f01029b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(ptr3 >= (int*)0xF100001C);
f01029bb:	81 7d d4 1b 00 00 f1 	cmpl   $0xf100001b,-0x2c(%ebp)
f01029c2:	77 16                	ja     f01029da <TestAss2Q1+0x293>
f01029c4:	68 9a 84 10 f0       	push   $0xf010849a
f01029c9:	68 f3 83 10 f0       	push   $0xf01083f3
f01029ce:	6a 50                	push   $0x50
f01029d0:	68 08 84 10 f0       	push   $0xf0108408
f01029d5:	e8 54 d7 ff ff       	call   f010012e <_panic>

	//Check elements of 3rd array
	for (i=0 ; i<10; i++)
f01029da:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01029e1:	eb 2d                	jmp    f0102a10 <TestAss2Q1+0x2c9>
	{
		if (ptr3[i] != 0)
f01029e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029e6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01029ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029f0:	01 d0                	add    %edx,%eax
f01029f2:	8b 00                	mov    (%eax),%eax
f01029f4:	85 c0                	test   %eax,%eax
f01029f6:	74 15                	je     f0102a0d <TestAss2Q1+0x2c6>
		{
			cprintf("[EVAL] #4 CreateIntArray: Failed\n");
f01029f8:	83 ec 0c             	sub    $0xc,%esp
f01029fb:	68 b4 84 10 f0       	push   $0xf01084b4
f0102a00:	e8 af 2c 00 00       	call   f01056b4 <cprintf>
f0102a05:	83 c4 10             	add    $0x10,%esp
			return retValue;
f0102a08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a0b:	eb 7c                	jmp    f0102a89 <TestAss2Q1+0x342>

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
	assert(ptr3 >= (int*)0xF100001C);

	//Check elements of 3rd array
	for (i=0 ; i<10; i++)
f0102a0d:	ff 45 e4             	incl   -0x1c(%ebp)
f0102a10:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f0102a14:	7e cd                	jle    f01029e3 <TestAss2Q1+0x29c>
			cprintf("[EVAL] #4 CreateIntArray: Failed\n");
			return retValue;
		}
	}
	//Check elements of 2nd array
	if (!CheckArrays(expectedArr2, ptr2, 4))
f0102a16:	83 ec 04             	sub    $0x4,%esp
f0102a19:	6a 04                	push   $0x4
f0102a1b:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a1e:	8d 85 ac fe ff ff    	lea    -0x154(%ebp),%eax
f0102a24:	50                   	push   %eax
f0102a25:	e8 a3 18 00 00       	call   f01042cd <CheckArrays>
f0102a2a:	83 c4 10             	add    $0x10,%esp
f0102a2d:	85 c0                	test   %eax,%eax
f0102a2f:	75 15                	jne    f0102a46 <TestAss2Q1+0x2ff>
	{
		cprintf("[EVAL] #5 CreateIntArray: Failed\n");
f0102a31:	83 ec 0c             	sub    $0xc,%esp
f0102a34:	68 d8 84 10 f0       	push   $0xf01084d8
f0102a39:	e8 76 2c 00 00       	call   f01056b4 <cprintf>
f0102a3e:	83 c4 10             	add    $0x10,%esp
		return retValue;
f0102a41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a44:	eb 43                	jmp    f0102a89 <TestAss2Q1+0x342>
	}

	//Check elements of 1st array
	if (!CheckArrays(expectedArr1, ptr1, 3))
f0102a46:	83 ec 04             	sub    $0x4,%esp
f0102a49:	6a 03                	push   $0x3
f0102a4b:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a4e:	8d 85 20 ff ff ff    	lea    -0xe0(%ebp),%eax
f0102a54:	50                   	push   %eax
f0102a55:	e8 73 18 00 00       	call   f01042cd <CheckArrays>
f0102a5a:	83 c4 10             	add    $0x10,%esp
f0102a5d:	85 c0                	test   %eax,%eax
f0102a5f:	75 15                	jne    f0102a76 <TestAss2Q1+0x32f>
	{
		cprintf("[EVAL] #6 CreateIntArray: Failed\n");
f0102a61:	83 ec 0c             	sub    $0xc,%esp
f0102a64:	68 fc 84 10 f0       	push   $0xf01084fc
f0102a69:	e8 46 2c 00 00       	call   f01056b4 <cprintf>
f0102a6e:	83 c4 10             	add    $0x10,%esp
		return retValue;
f0102a71:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a74:	eb 13                	jmp    f0102a89 <TestAss2Q1+0x342>
	}

	cprintf("[EVAL] CreateIntArray: Succeeded\n");
f0102a76:	83 ec 0c             	sub    $0xc,%esp
f0102a79:	68 20 85 10 f0       	push   $0xf0108520
f0102a7e:	e8 31 2c 00 00       	call   f01056b4 <cprintf>
f0102a83:	83 c4 10             	add    $0x10,%esp

	return retValue;
f0102a86:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
f0102a89:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a8c:	5b                   	pop    %ebx
f0102a8d:	5e                   	pop    %esi
f0102a8e:	5f                   	pop    %edi
f0102a8f:	5d                   	pop    %ebp
f0102a90:	c3                   	ret    

f0102a91 <TestAss2Q2>:

int TestAss2Q2()
{
f0102a91:	55                   	push   %ebp
f0102a92:	89 e5                	mov    %esp,%ebp
f0102a94:	57                   	push   %edi
f0102a95:	56                   	push   %esi
f0102a96:	53                   	push   %ebx
f0102a97:	81 ec 2c 03 00 00    	sub    $0x32c,%esp
	int retValue = 1;
f0102a9d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int i = 0;
f0102aa4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	//Create first array
	char cr1[100] = "cnia final 10";
f0102aab:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0102ab1:	bb 80 87 10 f0       	mov    $0xf0108780,%ebx
f0102ab6:	ba 0e 00 00 00       	mov    $0xe,%edx
f0102abb:	89 c7                	mov    %eax,%edi
f0102abd:	89 de                	mov    %ebx,%esi
f0102abf:	89 d1                	mov    %edx,%ecx
f0102ac1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102ac3:	8d 95 7e ff ff ff    	lea    -0x82(%ebp),%edx
f0102ac9:	b9 56 00 00 00       	mov    $0x56,%ecx
f0102ace:	b0 00                	mov    $0x0,%al
f0102ad0:	89 d7                	mov    %edx,%edi
f0102ad2:	f3 aa                	rep stos %al,%es:(%edi)
	int numOfArgs = 0;
f0102ad4:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102adb:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f0102ade:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102ae4:	50                   	push   %eax
f0102ae5:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102aeb:	50                   	push   %eax
f0102aec:	68 d5 83 10 f0       	push   $0xf01083d5
f0102af1:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0102af7:	50                   	push   %eax
f0102af8:	e8 52 45 00 00       	call   f010704f <strsplit>
f0102afd:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
f0102b00:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0102b06:	83 ec 08             	sub    $0x8,%esp
f0102b09:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0102b0f:	52                   	push   %edx
f0102b10:	50                   	push   %eax
f0102b11:	e8 5c e3 ff ff       	call   f0100e72 <CreateIntArray>
f0102b16:	83 c4 10             	add    $0x10,%esp
f0102b19:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f0102b1c:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f0102b23:	77 16                	ja     f0102b3b <TestAss2Q2+0xaa>
f0102b25:	68 da 83 10 f0       	push   $0xf01083da
f0102b2a:	68 f3 83 10 f0       	push   $0xf01083f3
f0102b2f:	6a 79                	push   $0x79
f0102b31:	68 08 84 10 f0       	push   $0xf0108408
f0102b36:	e8 f3 d5 ff ff       	call   f010012e <_panic>

	//Create second array
	char cr2[100] = "cnia srcArr 3 1 2 3";
f0102b3b:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f0102b41:	bb e4 87 10 f0       	mov    $0xf01087e4,%ebx
f0102b46:	ba 05 00 00 00       	mov    $0x5,%edx
f0102b4b:	89 c7                	mov    %eax,%edi
f0102b4d:	89 de                	mov    %ebx,%esi
f0102b4f:	89 d1                	mov    %edx,%ecx
f0102b51:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102b53:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
f0102b59:	b9 14 00 00 00       	mov    $0x14,%ecx
f0102b5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b63:	89 d7                	mov    %edx,%edi
f0102b65:	f3 ab                	rep stos %eax,%es:(%edi)
	numOfArgs = 0;
f0102b67:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102b6e:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f0102b71:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102b77:	50                   	push   %eax
f0102b78:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102b7e:	50                   	push   %eax
f0102b7f:	68 d5 83 10 f0       	push   $0xf01083d5
f0102b84:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f0102b8a:	50                   	push   %eax
f0102b8b:	e8 bf 44 00 00       	call   f010704f <strsplit>
f0102b90:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
f0102b93:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0102b99:	83 ec 08             	sub    $0x8,%esp
f0102b9c:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0102ba2:	52                   	push   %edx
f0102ba3:	50                   	push   %eax
f0102ba4:	e8 c9 e2 ff ff       	call   f0100e72 <CreateIntArray>
f0102ba9:	83 c4 10             	add    $0x10,%esp
f0102bac:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF1000000);
f0102baf:	81 7d d8 ff ff ff f0 	cmpl   $0xf0ffffff,-0x28(%ebp)
f0102bb6:	77 19                	ja     f0102bd1 <TestAss2Q2+0x140>
f0102bb8:	68 8c 86 10 f0       	push   $0xf010868c
f0102bbd:	68 f3 83 10 f0       	push   $0xf01083f3
f0102bc2:	68 81 00 00 00       	push   $0x81
f0102bc7:	68 08 84 10 f0       	push   $0xf0108408
f0102bcc:	e8 5d d5 ff ff       	call   f010012e <_panic>

	//Create third array
	char cr3[100] = "cnia dstArr 5 7 8";
f0102bd1:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
f0102bd7:	bb 48 88 10 f0       	mov    $0xf0108848,%ebx
f0102bdc:	ba 12 00 00 00       	mov    $0x12,%edx
f0102be1:	89 c7                	mov    %eax,%edi
f0102be3:	89 de                	mov    %ebx,%esi
f0102be5:	89 d1                	mov    %edx,%ecx
f0102be7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102be9:	8d 95 76 fe ff ff    	lea    -0x18a(%ebp),%edx
f0102bef:	b9 52 00 00 00       	mov    $0x52,%ecx
f0102bf4:	b0 00                	mov    $0x0,%al
f0102bf6:	89 d7                	mov    %edx,%edi
f0102bf8:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102bfa:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102c01:	00 00 00 
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f0102c04:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102c0a:	50                   	push   %eax
f0102c0b:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102c11:	50                   	push   %eax
f0102c12:	68 d5 83 10 f0       	push   $0xf01083d5
f0102c17:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
f0102c1d:	50                   	push   %eax
f0102c1e:	e8 2c 44 00 00       	call   f010704f <strsplit>
f0102c23:	83 c4 10             	add    $0x10,%esp

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
f0102c26:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0102c2c:	83 ec 08             	sub    $0x8,%esp
f0102c2f:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0102c35:	52                   	push   %edx
f0102c36:	50                   	push   %eax
f0102c37:	e8 36 e2 ff ff       	call   f0100e72 <CreateIntArray>
f0102c3c:	83 c4 10             	add    $0x10,%esp
f0102c3f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(ptr3 >= (int*)0xF1000000);
f0102c42:	81 7d d4 ff ff ff f0 	cmpl   $0xf0ffffff,-0x2c(%ebp)
f0102c49:	77 19                	ja     f0102c64 <TestAss2Q2+0x1d3>
f0102c4b:	68 a5 86 10 f0       	push   $0xf01086a5
f0102c50:	68 f3 83 10 f0       	push   $0xf01083f3
f0102c55:	68 89 00 00 00       	push   $0x89
f0102c5a:	68 08 84 10 f0       	push   $0xf0108408
f0102c5f:	e8 ca d4 ff ff       	call   f010012e <_panic>

	//Copy: Test1
	char cr4[100] = "ces srcArr dstArr 0 2 3";
f0102c64:	8d 85 00 fe ff ff    	lea    -0x200(%ebp),%eax
f0102c6a:	bb ac 88 10 f0       	mov    $0xf01088ac,%ebx
f0102c6f:	ba 06 00 00 00       	mov    $0x6,%edx
f0102c74:	89 c7                	mov    %eax,%edi
f0102c76:	89 de                	mov    %ebx,%esi
f0102c78:	89 d1                	mov    %edx,%ecx
f0102c7a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102c7c:	8d 95 18 fe ff ff    	lea    -0x1e8(%ebp),%edx
f0102c82:	b9 13 00 00 00       	mov    $0x13,%ecx
f0102c87:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c8c:	89 d7                	mov    %edx,%edi
f0102c8e:	f3 ab                	rep stos %eax,%es:(%edi)
	numOfArgs = 0;
f0102c90:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102c97:	00 00 00 
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;
f0102c9a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102ca0:	50                   	push   %eax
f0102ca1:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102ca7:	50                   	push   %eax
f0102ca8:	68 d5 83 10 f0       	push   $0xf01083d5
f0102cad:	8d 85 00 fe ff ff    	lea    -0x200(%ebp),%eax
f0102cb3:	50                   	push   %eax
f0102cb4:	e8 96 43 00 00       	call   f010704f <strsplit>
f0102cb9:	83 c4 10             	add    $0x10,%esp

	CopyElements(args) ;
f0102cbc:	83 ec 0c             	sub    $0xc,%esp
f0102cbf:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102cc5:	50                   	push   %eax
f0102cc6:	e8 4d e3 ff ff       	call   f0101018 <CopyElements>
f0102ccb:	83 c4 10             	add    $0x10,%esp

	int expectedArr1[] = {7, 8, 1, 2, 3};
f0102cce:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
f0102cd4:	bb 10 89 10 f0       	mov    $0xf0108910,%ebx
f0102cd9:	ba 05 00 00 00       	mov    $0x5,%edx
f0102cde:	89 c7                	mov    %eax,%edi
f0102ce0:	89 de                	mov    %ebx,%esi
f0102ce2:	89 d1                	mov    %edx,%ecx
f0102ce4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr1, ptr3, 5))
f0102ce6:	83 ec 04             	sub    $0x4,%esp
f0102ce9:	6a 05                	push   $0x5
f0102ceb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102cee:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
f0102cf4:	50                   	push   %eax
f0102cf5:	e8 d3 15 00 00       	call   f01042cd <CheckArrays>
f0102cfa:	83 c4 10             	add    $0x10,%esp
f0102cfd:	85 c0                	test   %eax,%eax
f0102cff:	75 1a                	jne    f0102d1b <TestAss2Q2+0x28a>
	{
		cprintf("[EVAL] #1 CopyElements: Failed\n");
f0102d01:	83 ec 0c             	sub    $0xc,%esp
f0102d04:	68 c0 86 10 f0       	push   $0xf01086c0
f0102d09:	e8 a6 29 00 00       	call   f01056b4 <cprintf>
f0102d0e:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102d11:	b8 01 00 00 00       	mov    $0x1,%eax
f0102d16:	e9 f7 01 00 00       	jmp    f0102f12 <TestAss2Q2+0x481>
	}

	//Copy: Test2
	char cr5[100] = "ces dstArr final 0 0 5";
f0102d1b:	8d 85 88 fd ff ff    	lea    -0x278(%ebp),%eax
f0102d21:	bb 24 89 10 f0       	mov    $0xf0108924,%ebx
f0102d26:	ba 17 00 00 00       	mov    $0x17,%edx
f0102d2b:	89 c7                	mov    %eax,%edi
f0102d2d:	89 de                	mov    %ebx,%esi
f0102d2f:	89 d1                	mov    %edx,%ecx
f0102d31:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102d33:	8d 95 9f fd ff ff    	lea    -0x261(%ebp),%edx
f0102d39:	b9 4d 00 00 00       	mov    $0x4d,%ecx
f0102d3e:	b0 00                	mov    $0x0,%al
f0102d40:	89 d7                	mov    %edx,%edi
f0102d42:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102d44:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102d4b:	00 00 00 
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;
f0102d4e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102d54:	50                   	push   %eax
f0102d55:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102d5b:	50                   	push   %eax
f0102d5c:	68 d5 83 10 f0       	push   $0xf01083d5
f0102d61:	8d 85 88 fd ff ff    	lea    -0x278(%ebp),%eax
f0102d67:	50                   	push   %eax
f0102d68:	e8 e2 42 00 00       	call   f010704f <strsplit>
f0102d6d:	83 c4 10             	add    $0x10,%esp

	CopyElements(args) ;
f0102d70:	83 ec 0c             	sub    $0xc,%esp
f0102d73:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102d79:	50                   	push   %eax
f0102d7a:	e8 99 e2 ff ff       	call   f0101018 <CopyElements>
f0102d7f:	83 c4 10             	add    $0x10,%esp

	int expectedArr2[] = {7, 8, 1, 2, 3, 0, 0, 0, 0, 0};
f0102d82:	8d 85 60 fd ff ff    	lea    -0x2a0(%ebp),%eax
f0102d88:	bb a0 89 10 f0       	mov    $0xf01089a0,%ebx
f0102d8d:	ba 0a 00 00 00       	mov    $0xa,%edx
f0102d92:	89 c7                	mov    %eax,%edi
f0102d94:	89 de                	mov    %ebx,%esi
f0102d96:	89 d1                	mov    %edx,%ecx
f0102d98:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr2, ptr1, 10))
f0102d9a:	83 ec 04             	sub    $0x4,%esp
f0102d9d:	6a 0a                	push   $0xa
f0102d9f:	ff 75 dc             	pushl  -0x24(%ebp)
f0102da2:	8d 85 60 fd ff ff    	lea    -0x2a0(%ebp),%eax
f0102da8:	50                   	push   %eax
f0102da9:	e8 1f 15 00 00       	call   f01042cd <CheckArrays>
f0102dae:	83 c4 10             	add    $0x10,%esp
f0102db1:	85 c0                	test   %eax,%eax
f0102db3:	75 1a                	jne    f0102dcf <TestAss2Q2+0x33e>
	{
		cprintf("[EVAL] #2 CopyElements: Failed\n");
f0102db5:	83 ec 0c             	sub    $0xc,%esp
f0102db8:	68 e0 86 10 f0       	push   $0xf01086e0
f0102dbd:	e8 f2 28 00 00       	call   f01056b4 <cprintf>
f0102dc2:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102dc5:	b8 01 00 00 00       	mov    $0x1,%eax
f0102dca:	e9 43 01 00 00       	jmp    f0102f12 <TestAss2Q2+0x481>
	}

	//Copy: Test3
	char cr6[100] = "ces final final 0 5 5";
f0102dcf:	8d 85 fc fc ff ff    	lea    -0x304(%ebp),%eax
f0102dd5:	bb c8 89 10 f0       	mov    $0xf01089c8,%ebx
f0102dda:	ba 16 00 00 00       	mov    $0x16,%edx
f0102ddf:	89 c7                	mov    %eax,%edi
f0102de1:	89 de                	mov    %ebx,%esi
f0102de3:	89 d1                	mov    %edx,%ecx
f0102de5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102de7:	8d 95 12 fd ff ff    	lea    -0x2ee(%ebp),%edx
f0102ded:	b9 4e 00 00 00       	mov    $0x4e,%ecx
f0102df2:	b0 00                	mov    $0x0,%al
f0102df4:	89 d7                	mov    %edx,%edi
f0102df6:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102df8:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f0102dff:	00 00 00 
	strsplit(cr6, WHITESPACE, args, &numOfArgs) ;
f0102e02:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102e08:	50                   	push   %eax
f0102e09:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102e0f:	50                   	push   %eax
f0102e10:	68 d5 83 10 f0       	push   $0xf01083d5
f0102e15:	8d 85 fc fc ff ff    	lea    -0x304(%ebp),%eax
f0102e1b:	50                   	push   %eax
f0102e1c:	e8 2e 42 00 00       	call   f010704f <strsplit>
f0102e21:	83 c4 10             	add    $0x10,%esp

	CopyElements(args) ;
f0102e24:	83 ec 0c             	sub    $0xc,%esp
f0102e27:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0102e2d:	50                   	push   %eax
f0102e2e:	e8 e5 e1 ff ff       	call   f0101018 <CopyElements>
f0102e33:	83 c4 10             	add    $0x10,%esp

	int expectedArr3[] = {7, 8, 1, 2, 3, 7, 8, 1, 2, 3};
f0102e36:	8d 85 d4 fc ff ff    	lea    -0x32c(%ebp),%eax
f0102e3c:	bb 40 8a 10 f0       	mov    $0xf0108a40,%ebx
f0102e41:	ba 0a 00 00 00       	mov    $0xa,%edx
f0102e46:	89 c7                	mov    %eax,%edi
f0102e48:	89 de                	mov    %ebx,%esi
f0102e4a:	89 d1                	mov    %edx,%ecx
f0102e4c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr3, ptr1, 10))
f0102e4e:	83 ec 04             	sub    $0x4,%esp
f0102e51:	6a 0a                	push   $0xa
f0102e53:	ff 75 dc             	pushl  -0x24(%ebp)
f0102e56:	8d 85 d4 fc ff ff    	lea    -0x32c(%ebp),%eax
f0102e5c:	50                   	push   %eax
f0102e5d:	e8 6b 14 00 00       	call   f01042cd <CheckArrays>
f0102e62:	83 c4 10             	add    $0x10,%esp
f0102e65:	85 c0                	test   %eax,%eax
f0102e67:	75 1a                	jne    f0102e83 <TestAss2Q2+0x3f2>
	{
		cprintf("[EVAL] #3 CopyElements: Failed\n");
f0102e69:	83 ec 0c             	sub    $0xc,%esp
f0102e6c:	68 00 87 10 f0       	push   $0xf0108700
f0102e71:	e8 3e 28 00 00       	call   f01056b4 <cprintf>
f0102e76:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102e79:	b8 01 00 00 00       	mov    $0x1,%eax
f0102e7e:	e9 8f 00 00 00       	jmp    f0102f12 <TestAss2Q2+0x481>
	}

	//Check other arrays
	int expectedArr4[] = {1, 2, 3};
f0102e83:	8d 85 c8 fc ff ff    	lea    -0x338(%ebp),%eax
f0102e89:	bb a8 85 10 f0       	mov    $0xf01085a8,%ebx
f0102e8e:	ba 03 00 00 00       	mov    $0x3,%edx
f0102e93:	89 c7                	mov    %eax,%edi
f0102e95:	89 de                	mov    %ebx,%esi
f0102e97:	89 d1                	mov    %edx,%ecx
f0102e99:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if (!CheckArrays(expectedArr4, ptr2, 3))
f0102e9b:	83 ec 04             	sub    $0x4,%esp
f0102e9e:	6a 03                	push   $0x3
f0102ea0:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ea3:	8d 85 c8 fc ff ff    	lea    -0x338(%ebp),%eax
f0102ea9:	50                   	push   %eax
f0102eaa:	e8 1e 14 00 00       	call   f01042cd <CheckArrays>
f0102eaf:	83 c4 10             	add    $0x10,%esp
f0102eb2:	85 c0                	test   %eax,%eax
f0102eb4:	75 17                	jne    f0102ecd <TestAss2Q2+0x43c>
	{
		cprintf("[EVAL] #4 CopyElements: Failed\n");
f0102eb6:	83 ec 0c             	sub    $0xc,%esp
f0102eb9:	68 20 87 10 f0       	push   $0xf0108720
f0102ebe:	e8 f1 27 00 00       	call   f01056b4 <cprintf>
f0102ec3:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102ec6:	b8 01 00 00 00       	mov    $0x1,%eax
f0102ecb:	eb 45                	jmp    f0102f12 <TestAss2Q2+0x481>
	}
	if (!CheckArrays(expectedArr1, ptr3, 5))
f0102ecd:	83 ec 04             	sub    $0x4,%esp
f0102ed0:	6a 05                	push   $0x5
f0102ed2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102ed5:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
f0102edb:	50                   	push   %eax
f0102edc:	e8 ec 13 00 00       	call   f01042cd <CheckArrays>
f0102ee1:	83 c4 10             	add    $0x10,%esp
f0102ee4:	85 c0                	test   %eax,%eax
f0102ee6:	75 17                	jne    f0102eff <TestAss2Q2+0x46e>
	{
		cprintf("[EVAL] #5 CopyElements: Failed\n");
f0102ee8:	83 ec 0c             	sub    $0xc,%esp
f0102eeb:	68 40 87 10 f0       	push   $0xf0108740
f0102ef0:	e8 bf 27 00 00       	call   f01056b4 <cprintf>
f0102ef5:	83 c4 10             	add    $0x10,%esp
		return 1;
f0102ef8:	b8 01 00 00 00       	mov    $0x1,%eax
f0102efd:	eb 13                	jmp    f0102f12 <TestAss2Q2+0x481>
	}


	cprintf("[EVAL] CopyElements: Succeeded\n");
f0102eff:	83 ec 0c             	sub    $0xc,%esp
f0102f02:	68 60 87 10 f0       	push   $0xf0108760
f0102f07:	e8 a8 27 00 00       	call   f01056b4 <cprintf>
f0102f0c:	83 c4 10             	add    $0x10,%esp

	return retValue;
f0102f0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
f0102f12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f15:	5b                   	pop    %ebx
f0102f16:	5e                   	pop    %esi
f0102f17:	5f                   	pop    %edi
f0102f18:	5d                   	pop    %ebp
f0102f19:	c3                   	ret    

f0102f1a <TestAss2Q3>:

int TestAss2Q3()
{
f0102f1a:	55                   	push   %ebp
f0102f1b:	89 e5                	mov    %esp,%ebp
f0102f1d:	57                   	push   %edi
f0102f1e:	56                   	push   %esi
f0102f1f:	53                   	push   %ebx
f0102f20:	81 ec bc 04 00 00    	sub    $0x4bc,%esp
	int ret = 1;
f0102f26:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int i = 0;
f0102f2d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	//Create first array
	char cr1[100] = "cnia y 5 10 20 30 40 30";
f0102f34:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102f3a:	bb be 8b 10 f0       	mov    $0xf0108bbe,%ebx
f0102f3f:	ba 06 00 00 00       	mov    $0x6,%edx
f0102f44:	89 c7                	mov    %eax,%edi
f0102f46:	89 de                	mov    %ebx,%esi
f0102f48:	89 d1                	mov    %edx,%ecx
f0102f4a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102f4c:	8d 55 84             	lea    -0x7c(%ebp),%edx
f0102f4f:	b9 13 00 00 00       	mov    $0x13,%ecx
f0102f54:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f59:	89 d7                	mov    %edx,%edi
f0102f5b:	f3 ab                	rep stos %eax,%es:(%edi)
	int numOfArgs = 0;
f0102f5d:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
f0102f64:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f0102f67:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0102f6d:	50                   	push   %eax
f0102f6e:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0102f74:	50                   	push   %eax
f0102f75:	68 d5 83 10 f0       	push   $0xf01083d5
f0102f7a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0102f80:	50                   	push   %eax
f0102f81:	e8 c9 40 00 00       	call   f010704f <strsplit>
f0102f86:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
f0102f89:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
f0102f8f:	83 ec 08             	sub    $0x8,%esp
f0102f92:	8d 95 28 ff ff ff    	lea    -0xd8(%ebp),%edx
f0102f98:	52                   	push   %edx
f0102f99:	50                   	push   %eax
f0102f9a:	e8 d3 de ff ff       	call   f0100e72 <CreateIntArray>
f0102f9f:	83 c4 10             	add    $0x10,%esp
f0102fa2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f0102fa5:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f0102fac:	77 19                	ja     f0102fc7 <TestAss2Q3+0xad>
f0102fae:	68 da 83 10 f0       	push   $0xf01083da
f0102fb3:	68 f3 83 10 f0       	push   $0xf01083f3
f0102fb8:	68 d3 00 00 00       	push   $0xd3
f0102fbd:	68 08 84 10 f0       	push   $0xf0108408
f0102fc2:	e8 67 d1 ff ff       	call   f010012e <_panic>

	//Create second array
	char cr2[100] = "cnia z 8 1 2 3 4";
f0102fc7:	8d 85 c4 fe ff ff    	lea    -0x13c(%ebp),%eax
f0102fcd:	bb 22 8c 10 f0       	mov    $0xf0108c22,%ebx
f0102fd2:	ba 11 00 00 00       	mov    $0x11,%edx
f0102fd7:	89 c7                	mov    %eax,%edi
f0102fd9:	89 de                	mov    %ebx,%esi
f0102fdb:	89 d1                	mov    %edx,%ecx
f0102fdd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0102fdf:	8d 95 d5 fe ff ff    	lea    -0x12b(%ebp),%edx
f0102fe5:	b9 53 00 00 00       	mov    $0x53,%ecx
f0102fea:	b0 00                	mov    $0x0,%al
f0102fec:	89 d7                	mov    %edx,%edi
f0102fee:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0102ff0:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
f0102ff7:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f0102ffa:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0103000:	50                   	push   %eax
f0103001:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103007:	50                   	push   %eax
f0103008:	68 d5 83 10 f0       	push   $0xf01083d5
f010300d:	8d 85 c4 fe ff ff    	lea    -0x13c(%ebp),%eax
f0103013:	50                   	push   %eax
f0103014:	e8 36 40 00 00       	call   f010704f <strsplit>
f0103019:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
f010301c:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
f0103022:	83 ec 08             	sub    $0x8,%esp
f0103025:	8d 95 28 ff ff ff    	lea    -0xd8(%ebp),%edx
f010302b:	52                   	push   %edx
f010302c:	50                   	push   %eax
f010302d:	e8 40 de ff ff       	call   f0100e72 <CreateIntArray>
f0103032:	83 c4 10             	add    $0x10,%esp
f0103035:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF1000000);
f0103038:	81 7d d8 ff ff ff f0 	cmpl   $0xf0ffffff,-0x28(%ebp)
f010303f:	77 19                	ja     f010305a <TestAss2Q3+0x140>
f0103041:	68 8c 86 10 f0       	push   $0xf010868c
f0103046:	68 f3 83 10 f0       	push   $0xf01083f3
f010304b:	68 db 00 00 00       	push   $0xdb
f0103050:	68 08 84 10 f0       	push   $0xf0108408
f0103055:	e8 d4 d0 ff ff       	call   f010012e <_panic>

	//Create third array
	char cr3[100] = "cnia w 3 5 4 3";
f010305a:	8d 85 60 fe ff ff    	lea    -0x1a0(%ebp),%eax
f0103060:	bb 86 8c 10 f0       	mov    $0xf0108c86,%ebx
f0103065:	ba 0f 00 00 00       	mov    $0xf,%edx
f010306a:	89 c7                	mov    %eax,%edi
f010306c:	89 de                	mov    %ebx,%esi
f010306e:	89 d1                	mov    %edx,%ecx
f0103070:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103072:	8d 95 6f fe ff ff    	lea    -0x191(%ebp),%edx
f0103078:	b9 55 00 00 00       	mov    $0x55,%ecx
f010307d:	b0 00                	mov    $0x0,%al
f010307f:	89 d7                	mov    %edx,%edi
f0103081:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0103083:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
f010308a:	00 00 00 
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f010308d:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0103093:	50                   	push   %eax
f0103094:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f010309a:	50                   	push   %eax
f010309b:	68 d5 83 10 f0       	push   $0xf01083d5
f01030a0:	8d 85 60 fe ff ff    	lea    -0x1a0(%ebp),%eax
f01030a6:	50                   	push   %eax
f01030a7:	e8 a3 3f 00 00       	call   f010704f <strsplit>
f01030ac:	83 c4 10             	add    $0x10,%esp

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
f01030af:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
f01030b5:	83 ec 08             	sub    $0x8,%esp
f01030b8:	8d 95 28 ff ff ff    	lea    -0xd8(%ebp),%edx
f01030be:	52                   	push   %edx
f01030bf:	50                   	push   %eax
f01030c0:	e8 ad dd ff ff       	call   f0100e72 <CreateIntArray>
f01030c5:	83 c4 10             	add    $0x10,%esp
f01030c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(ptr3 >= (int*)0xF1000000);
f01030cb:	81 7d d4 ff ff ff f0 	cmpl   $0xf0ffffff,-0x2c(%ebp)
f01030d2:	77 19                	ja     f01030ed <TestAss2Q3+0x1d3>
f01030d4:	68 a5 86 10 f0       	push   $0xf01086a5
f01030d9:	68 f3 83 10 f0       	push   $0xf01083f3
f01030de:	68 e3 00 00 00       	push   $0xe3
f01030e3:	68 08 84 10 f0       	push   $0xf0108408
f01030e8:	e8 41 d0 ff ff       	call   f010012e <_panic>

	//Find (Arr not Exist)
	char f2[100] = "fia m 3";
f01030ed:	c7 85 fc fd ff ff 66 	movl   $0x20616966,-0x204(%ebp)
f01030f4:	69 61 20 
f01030f7:	c7 85 00 fe ff ff 6d 	movl   $0x33206d,-0x200(%ebp)
f01030fe:	20 33 00 
f0103101:	8d 95 04 fe ff ff    	lea    -0x1fc(%ebp),%edx
f0103107:	b9 17 00 00 00       	mov    $0x17,%ecx
f010310c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103111:	89 d7                	mov    %edx,%edi
f0103113:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f2, WHITESPACE, args, &numOfArgs) ;
f0103115:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010311b:	50                   	push   %eax
f010311c:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103122:	50                   	push   %eax
f0103123:	68 d5 83 10 f0       	push   $0xf01083d5
f0103128:	8d 85 fc fd ff ff    	lea    -0x204(%ebp),%eax
f010312e:	50                   	push   %eax
f010312f:	e8 1b 3f 00 00       	call   f010704f <strsplit>
f0103134:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103137:	83 ec 0c             	sub    $0xc,%esp
f010313a:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103140:	50                   	push   %eax
f0103141:	e8 bd e0 ff ff       	call   f0101203 <FindElementInArray>
f0103146:	83 c4 10             	add    $0x10,%esp
f0103149:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f010314c:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0103150:	74 1a                	je     f010316c <TestAss2Q3+0x252>
	{
		cprintf("[EVAL] #1 FindElementInArray: Failed\n");
f0103152:	83 ec 0c             	sub    $0xc,%esp
f0103155:	68 68 8a 10 f0       	push   $0xf0108a68
f010315a:	e8 55 25 00 00       	call   f01056b4 <cprintf>
f010315f:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103162:	b8 01 00 00 00       	mov    $0x1,%eax
f0103167:	e9 a0 03 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}
	//Find (Exist)
	char f3[100] = "fia y 30";
f010316c:	8d 85 98 fd ff ff    	lea    -0x268(%ebp),%eax
f0103172:	bb ea 8c 10 f0       	mov    $0xf0108cea,%ebx
f0103177:	ba 09 00 00 00       	mov    $0x9,%edx
f010317c:	89 c7                	mov    %eax,%edi
f010317e:	89 de                	mov    %ebx,%esi
f0103180:	89 d1                	mov    %edx,%ecx
f0103182:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103184:	8d 95 a1 fd ff ff    	lea    -0x25f(%ebp),%edx
f010318a:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f010318f:	b0 00                	mov    $0x0,%al
f0103191:	89 d7                	mov    %edx,%edi
f0103193:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f3, WHITESPACE, args, &numOfArgs) ;
f0103195:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010319b:	50                   	push   %eax
f010319c:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01031a2:	50                   	push   %eax
f01031a3:	68 d5 83 10 f0       	push   $0xf01083d5
f01031a8:	8d 85 98 fd ff ff    	lea    -0x268(%ebp),%eax
f01031ae:	50                   	push   %eax
f01031af:	e8 9b 3e 00 00       	call   f010704f <strsplit>
f01031b4:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f01031b7:	83 ec 0c             	sub    $0xc,%esp
f01031ba:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01031c0:	50                   	push   %eax
f01031c1:	e8 3d e0 ff ff       	call   f0101203 <FindElementInArray>
f01031c6:	83 c4 10             	add    $0x10,%esp
f01031c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 2)
f01031cc:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
f01031d0:	74 1a                	je     f01031ec <TestAss2Q3+0x2d2>
	{
		cprintf("[EVAL] #2 FindElementInArray: Failed\n");
f01031d2:	83 ec 0c             	sub    $0xc,%esp
f01031d5:	68 90 8a 10 f0       	push   $0xf0108a90
f01031da:	e8 d5 24 00 00       	call   f01056b4 <cprintf>
f01031df:	83 c4 10             	add    $0x10,%esp
		return 1;
f01031e2:	b8 01 00 00 00       	mov    $0x1,%eax
f01031e7:	e9 20 03 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	//Find (Not Exist)
	char f4[100] = "fia y 1";
f01031ec:	c7 85 34 fd ff ff 66 	movl   $0x20616966,-0x2cc(%ebp)
f01031f3:	69 61 20 
f01031f6:	c7 85 38 fd ff ff 79 	movl   $0x312079,-0x2c8(%ebp)
f01031fd:	20 31 00 
f0103200:	8d 95 3c fd ff ff    	lea    -0x2c4(%ebp),%edx
f0103206:	b9 17 00 00 00       	mov    $0x17,%ecx
f010320b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103210:	89 d7                	mov    %edx,%edi
f0103212:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f4, WHITESPACE, args, &numOfArgs) ;
f0103214:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010321a:	50                   	push   %eax
f010321b:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103221:	50                   	push   %eax
f0103222:	68 d5 83 10 f0       	push   $0xf01083d5
f0103227:	8d 85 34 fd ff ff    	lea    -0x2cc(%ebp),%eax
f010322d:	50                   	push   %eax
f010322e:	e8 1c 3e 00 00       	call   f010704f <strsplit>
f0103233:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103236:	83 ec 0c             	sub    $0xc,%esp
f0103239:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f010323f:	50                   	push   %eax
f0103240:	e8 be df ff ff       	call   f0101203 <FindElementInArray>
f0103245:	83 c4 10             	add    $0x10,%esp
f0103248:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f010324b:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f010324f:	74 1a                	je     f010326b <TestAss2Q3+0x351>
	{
		cprintf("[EVAL] #3 FindElementInArray: Failed\n");
f0103251:	83 ec 0c             	sub    $0xc,%esp
f0103254:	68 b8 8a 10 f0       	push   $0xf0108ab8
f0103259:	e8 56 24 00 00       	call   f01056b4 <cprintf>
f010325e:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103261:	b8 01 00 00 00       	mov    $0x1,%eax
f0103266:	e9 a1 02 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	//Create fourth array
	char cr4[100] = "cnia m 3 1 3 5";
f010326b:	8d 85 d0 fc ff ff    	lea    -0x330(%ebp),%eax
f0103271:	bb 4e 8d 10 f0       	mov    $0xf0108d4e,%ebx
f0103276:	ba 0f 00 00 00       	mov    $0xf,%edx
f010327b:	89 c7                	mov    %eax,%edi
f010327d:	89 de                	mov    %ebx,%esi
f010327f:	89 d1                	mov    %edx,%ecx
f0103281:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103283:	8d 95 df fc ff ff    	lea    -0x321(%ebp),%edx
f0103289:	b9 55 00 00 00       	mov    $0x55,%ecx
f010328e:	b0 00                	mov    $0x0,%al
f0103290:	89 d7                	mov    %edx,%edi
f0103292:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0103294:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
f010329b:	00 00 00 
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;
f010329e:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f01032a4:	50                   	push   %eax
f01032a5:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01032ab:	50                   	push   %eax
f01032ac:	68 d5 83 10 f0       	push   $0xf01083d5
f01032b1:	8d 85 d0 fc ff ff    	lea    -0x330(%ebp),%eax
f01032b7:	50                   	push   %eax
f01032b8:	e8 92 3d 00 00       	call   f010704f <strsplit>
f01032bd:	83 c4 10             	add    $0x10,%esp

	int* ptr4 = CreateIntArray(numOfArgs,args) ;
f01032c0:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
f01032c6:	83 ec 08             	sub    $0x8,%esp
f01032c9:	8d 95 28 ff ff ff    	lea    -0xd8(%ebp),%edx
f01032cf:	52                   	push   %edx
f01032d0:	50                   	push   %eax
f01032d1:	e8 9c db ff ff       	call   f0100e72 <CreateIntArray>
f01032d6:	83 c4 10             	add    $0x10,%esp
f01032d9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	assert(ptr4 >= (int*)0xF1000000);
f01032dc:	81 7d d0 ff ff ff f0 	cmpl   $0xf0ffffff,-0x30(%ebp)
f01032e3:	77 19                	ja     f01032fe <TestAss2Q3+0x3e4>
f01032e5:	68 de 8a 10 f0       	push   $0xf0108ade
f01032ea:	68 f3 83 10 f0       	push   $0xf01083f3
f01032ef:	68 08 01 00 00       	push   $0x108
f01032f4:	68 08 84 10 f0       	push   $0xf0108408
f01032f9:	e8 30 ce ff ff       	call   f010012e <_panic>

	//Find (Not Exist)
	char f5[100] = "fia z 1";
f01032fe:	c7 85 6c fc ff ff 66 	movl   $0x20616966,-0x394(%ebp)
f0103305:	69 61 20 
f0103308:	c7 85 70 fc ff ff 7a 	movl   $0x31207a,-0x390(%ebp)
f010330f:	20 31 00 
f0103312:	8d 95 74 fc ff ff    	lea    -0x38c(%ebp),%edx
f0103318:	b9 17 00 00 00       	mov    $0x17,%ecx
f010331d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103322:	89 d7                	mov    %edx,%edi
f0103324:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f5, WHITESPACE, args, &numOfArgs) ;
f0103326:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010332c:	50                   	push   %eax
f010332d:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103333:	50                   	push   %eax
f0103334:	68 d5 83 10 f0       	push   $0xf01083d5
f0103339:	8d 85 6c fc ff ff    	lea    -0x394(%ebp),%eax
f010333f:	50                   	push   %eax
f0103340:	e8 0a 3d 00 00       	call   f010704f <strsplit>
f0103345:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103348:	83 ec 0c             	sub    $0xc,%esp
f010334b:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103351:	50                   	push   %eax
f0103352:	e8 ac de ff ff       	call   f0101203 <FindElementInArray>
f0103357:	83 c4 10             	add    $0x10,%esp
f010335a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 0)
f010335d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103361:	74 1a                	je     f010337d <TestAss2Q3+0x463>
	{
		cprintf("[EVAL] #4 FindElementInArray: Failed\n");
f0103363:	83 ec 0c             	sub    $0xc,%esp
f0103366:	68 f8 8a 10 f0       	push   $0xf0108af8
f010336b:	e8 44 23 00 00       	call   f01056b4 <cprintf>
f0103370:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103373:	b8 01 00 00 00       	mov    $0x1,%eax
f0103378:	e9 8f 01 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	//Find
	char f6[100] = "fia z 0";
f010337d:	c7 85 08 fc ff ff 66 	movl   $0x20616966,-0x3f8(%ebp)
f0103384:	69 61 20 
f0103387:	c7 85 0c fc ff ff 7a 	movl   $0x30207a,-0x3f4(%ebp)
f010338e:	20 30 00 
f0103391:	8d 95 10 fc ff ff    	lea    -0x3f0(%ebp),%edx
f0103397:	b9 17 00 00 00       	mov    $0x17,%ecx
f010339c:	b8 00 00 00 00       	mov    $0x0,%eax
f01033a1:	89 d7                	mov    %edx,%edi
f01033a3:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f6, WHITESPACE, args, &numOfArgs) ;
f01033a5:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f01033ab:	50                   	push   %eax
f01033ac:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01033b2:	50                   	push   %eax
f01033b3:	68 d5 83 10 f0       	push   $0xf01083d5
f01033b8:	8d 85 08 fc ff ff    	lea    -0x3f8(%ebp),%eax
f01033be:	50                   	push   %eax
f01033bf:	e8 8b 3c 00 00       	call   f010704f <strsplit>
f01033c4:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f01033c7:	83 ec 0c             	sub    $0xc,%esp
f01033ca:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01033d0:	50                   	push   %eax
f01033d1:	e8 2d de ff ff       	call   f0101203 <FindElementInArray>
f01033d6:	83 c4 10             	add    $0x10,%esp
f01033d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 4)
f01033dc:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
f01033e0:	74 1a                	je     f01033fc <TestAss2Q3+0x4e2>
	{
		cprintf("[EVAL] #5 FindElementInArray: Failed\n");
f01033e2:	83 ec 0c             	sub    $0xc,%esp
f01033e5:	68 20 8b 10 f0       	push   $0xf0108b20
f01033ea:	e8 c5 22 00 00       	call   f01056b4 <cprintf>
f01033ef:	83 c4 10             	add    $0x10,%esp
		return 1;
f01033f2:	b8 01 00 00 00       	mov    $0x1,%eax
f01033f7:	e9 10 01 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	char f7[100] = "fia w 3";
f01033fc:	c7 85 a4 fb ff ff 66 	movl   $0x20616966,-0x45c(%ebp)
f0103403:	69 61 20 
f0103406:	c7 85 a8 fb ff ff 77 	movl   $0x332077,-0x458(%ebp)
f010340d:	20 33 00 
f0103410:	8d 95 ac fb ff ff    	lea    -0x454(%ebp),%edx
f0103416:	b9 17 00 00 00       	mov    $0x17,%ecx
f010341b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103420:	89 d7                	mov    %edx,%edi
f0103422:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f7, WHITESPACE, args, &numOfArgs) ;
f0103424:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f010342a:	50                   	push   %eax
f010342b:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f0103431:	50                   	push   %eax
f0103432:	68 d5 83 10 f0       	push   $0xf01083d5
f0103437:	8d 85 a4 fb ff ff    	lea    -0x45c(%ebp),%eax
f010343d:	50                   	push   %eax
f010343e:	e8 0c 3c 00 00       	call   f010704f <strsplit>
f0103443:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103446:	83 ec 0c             	sub    $0xc,%esp
f0103449:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f010344f:	50                   	push   %eax
f0103450:	e8 ae dd ff ff       	call   f0101203 <FindElementInArray>
f0103455:	83 c4 10             	add    $0x10,%esp
f0103458:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 2)
f010345b:	83 7d e4 02          	cmpl   $0x2,-0x1c(%ebp)
f010345f:	74 1a                	je     f010347b <TestAss2Q3+0x561>
	{
		cprintf("[EVAL] #6 FindElementInArray: Failed\n");
f0103461:	83 ec 0c             	sub    $0xc,%esp
f0103464:	68 48 8b 10 f0       	push   $0xf0108b48
f0103469:	e8 46 22 00 00       	call   f01056b4 <cprintf>
f010346e:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103471:	b8 01 00 00 00       	mov    $0x1,%eax
f0103476:	e9 91 00 00 00       	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	char f8[100] = "fia m 3";
f010347b:	c7 85 40 fb ff ff 66 	movl   $0x20616966,-0x4c0(%ebp)
f0103482:	69 61 20 
f0103485:	c7 85 44 fb ff ff 6d 	movl   $0x33206d,-0x4bc(%ebp)
f010348c:	20 33 00 
f010348f:	8d 95 48 fb ff ff    	lea    -0x4b8(%ebp),%edx
f0103495:	b9 17 00 00 00       	mov    $0x17,%ecx
f010349a:	b8 00 00 00 00       	mov    $0x0,%eax
f010349f:	89 d7                	mov    %edx,%edi
f01034a1:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(f8, WHITESPACE, args, &numOfArgs) ;
f01034a3:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f01034a9:	50                   	push   %eax
f01034aa:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01034b0:	50                   	push   %eax
f01034b1:	68 d5 83 10 f0       	push   $0xf01083d5
f01034b6:	8d 85 40 fb ff ff    	lea    -0x4c0(%ebp),%eax
f01034bc:	50                   	push   %eax
f01034bd:	e8 8d 3b 00 00       	call   f010704f <strsplit>
f01034c2:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f01034c5:	83 ec 0c             	sub    $0xc,%esp
f01034c8:	8d 85 28 ff ff ff    	lea    -0xd8(%ebp),%eax
f01034ce:	50                   	push   %eax
f01034cf:	e8 2f dd ff ff       	call   f0101203 <FindElementInArray>
f01034d4:	83 c4 10             	add    $0x10,%esp
f01034d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 1)
f01034da:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
f01034de:	74 17                	je     f01034f7 <TestAss2Q3+0x5dd>
	{
		cprintf("[EVAL] #7 FindElementInArray: Failed\n");
f01034e0:	83 ec 0c             	sub    $0xc,%esp
f01034e3:	68 70 8b 10 f0       	push   $0xf0108b70
f01034e8:	e8 c7 21 00 00       	call   f01056b4 <cprintf>
f01034ed:	83 c4 10             	add    $0x10,%esp
		return 1;
f01034f0:	b8 01 00 00 00       	mov    $0x1,%eax
f01034f5:	eb 15                	jmp    f010350c <TestAss2Q3+0x5f2>
	}

	cprintf("[EVAL] FindElementInArray: Succeeded\n");
f01034f7:	83 ec 0c             	sub    $0xc,%esp
f01034fa:	68 98 8b 10 f0       	push   $0xf0108b98
f01034ff:	e8 b0 21 00 00       	call   f01056b4 <cprintf>
f0103504:	83 c4 10             	add    $0x10,%esp

	return 1;
f0103507:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010350c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010350f:	5b                   	pop    %ebx
f0103510:	5e                   	pop    %esi
f0103511:	5f                   	pop    %edi
f0103512:	5d                   	pop    %ebp
f0103513:	c3                   	ret    

f0103514 <TestAss2Q4>:

int TestAss2Q4()
{
f0103514:	55                   	push   %ebp
f0103515:	89 e5                	mov    %esp,%ebp
f0103517:	57                   	push   %edi
f0103518:	56                   	push   %esi
f0103519:	53                   	push   %ebx
f010351a:	81 ec fc 01 00 00    	sub    $0x1fc,%esp
	int retValue = 1;
f0103520:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int i = 0;
f0103527:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	//Create first array
	char cr1[100] = "cnia _x4 3 10 20 30";
f010352e:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0103534:	bb 0c 8e 10 f0       	mov    $0xf0108e0c,%ebx
f0103539:	ba 05 00 00 00       	mov    $0x5,%edx
f010353e:	89 c7                	mov    %eax,%edi
f0103540:	89 de                	mov    %ebx,%esi
f0103542:	89 d1                	mov    %edx,%ecx
f0103544:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103546:	8d 55 84             	lea    -0x7c(%ebp),%edx
f0103549:	b9 14 00 00 00       	mov    $0x14,%ecx
f010354e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103553:	89 d7                	mov    %edx,%edi
f0103555:	f3 ab                	rep stos %eax,%es:(%edi)
	int numOfArgs = 0;
f0103557:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f010355e:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f0103561:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0103567:	50                   	push   %eax
f0103568:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010356e:	50                   	push   %eax
f010356f:	68 d5 83 10 f0       	push   $0xf01083d5
f0103574:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f010357a:	50                   	push   %eax
f010357b:	e8 cf 3a 00 00       	call   f010704f <strsplit>
f0103580:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
f0103583:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f0103589:	83 ec 08             	sub    $0x8,%esp
f010358c:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0103592:	52                   	push   %edx
f0103593:	50                   	push   %eax
f0103594:	e8 d9 d8 ff ff       	call   f0100e72 <CreateIntArray>
f0103599:	83 c4 10             	add    $0x10,%esp
f010359c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f010359f:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f01035a6:	77 19                	ja     f01035c1 <TestAss2Q4+0xad>
f01035a8:	68 da 83 10 f0       	push   $0xf01083da
f01035ad:	68 f3 83 10 f0       	push   $0xf01083f3
f01035b2:	68 40 01 00 00       	push   $0x140
f01035b7:	68 08 84 10 f0       	push   $0xf0108408
f01035bc:	e8 6d cb ff ff       	call   f010012e <_panic>


	//Create second array
	char cr2[100] = "cnia _y4 4 400 400";
f01035c1:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f01035c7:	bb 70 8e 10 f0       	mov    $0xf0108e70,%ebx
f01035cc:	ba 13 00 00 00       	mov    $0x13,%edx
f01035d1:	89 c7                	mov    %eax,%edi
f01035d3:	89 de                	mov    %ebx,%esi
f01035d5:	89 d1                	mov    %edx,%ecx
f01035d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01035d9:	8d 95 db fe ff ff    	lea    -0x125(%ebp),%edx
f01035df:	b9 51 00 00 00       	mov    $0x51,%ecx
f01035e4:	b0 00                	mov    $0x0,%al
f01035e6:	89 d7                	mov    %edx,%edi
f01035e8:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f01035ea:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
f01035f1:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f01035f4:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01035fa:	50                   	push   %eax
f01035fb:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0103601:	50                   	push   %eax
f0103602:	68 d5 83 10 f0       	push   $0xf01083d5
f0103607:	8d 85 c8 fe ff ff    	lea    -0x138(%ebp),%eax
f010360d:	50                   	push   %eax
f010360e:	e8 3c 3a 00 00       	call   f010704f <strsplit>
f0103613:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args);
f0103616:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f010361c:	83 ec 08             	sub    $0x8,%esp
f010361f:	8d 95 2c ff ff ff    	lea    -0xd4(%ebp),%edx
f0103625:	52                   	push   %edx
f0103626:	50                   	push   %eax
f0103627:	e8 46 d8 ff ff       	call   f0100e72 <CreateIntArray>
f010362c:	83 c4 10             	add    $0x10,%esp
f010362f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF1000000);
f0103632:	81 7d d8 ff ff ff f0 	cmpl   $0xf0ffffff,-0x28(%ebp)
f0103639:	77 19                	ja     f0103654 <TestAss2Q4+0x140>
f010363b:	68 8c 86 10 f0       	push   $0xf010868c
f0103640:	68 f3 83 10 f0       	push   $0xf01083f3
f0103645:	68 49 01 00 00       	push   $0x149
f010364a:	68 08 84 10 f0       	push   $0xf0108408
f010364f:	e8 da ca ff ff       	call   f010012e <_panic>

	int ret =0 ;
f0103654:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

	//Calculate var of 1st array
	char v1[100] = "cav _x4";
f010365b:	c7 85 64 fe ff ff 63 	movl   $0x20766163,-0x19c(%ebp)
f0103662:	61 76 20 
f0103665:	c7 85 68 fe ff ff 5f 	movl   $0x34785f,-0x198(%ebp)
f010366c:	78 34 00 
f010366f:	8d 95 6c fe ff ff    	lea    -0x194(%ebp),%edx
f0103675:	b9 17 00 00 00       	mov    $0x17,%ecx
f010367a:	b8 00 00 00 00       	mov    $0x0,%eax
f010367f:	89 d7                	mov    %edx,%edi
f0103681:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(v1, WHITESPACE, args, &numOfArgs) ;
f0103683:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0103689:	50                   	push   %eax
f010368a:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f0103690:	50                   	push   %eax
f0103691:	68 d5 83 10 f0       	push   $0xf01083d5
f0103696:	8d 85 64 fe ff ff    	lea    -0x19c(%ebp),%eax
f010369c:	50                   	push   %eax
f010369d:	e8 ad 39 00 00       	call   f010704f <strsplit>
f01036a2:	83 c4 10             	add    $0x10,%esp
	ret = CalcArrVar(args) ;
f01036a5:	83 ec 0c             	sub    $0xc,%esp
f01036a8:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f01036ae:	50                   	push   %eax
f01036af:	e8 80 dc ff ff       	call   f0101334 <CalcArrVar>
f01036b4:	83 c4 10             	add    $0x10,%esp
f01036b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	if (ret != 66)
f01036ba:	83 7d d4 42          	cmpl   $0x42,-0x2c(%ebp)
f01036be:	74 1a                	je     f01036da <TestAss2Q4+0x1c6>
	{
		cprintf("[EVAL] #1 CalcArrVar: Failed\n");
f01036c0:	83 ec 0c             	sub    $0xc,%esp
f01036c3:	68 b2 8d 10 f0       	push   $0xf0108db2
f01036c8:	e8 e7 1f 00 00       	call   f01056b4 <cprintf>
f01036cd:	83 c4 10             	add    $0x10,%esp
		return 1;
f01036d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01036d5:	e9 94 00 00 00       	jmp    f010376e <TestAss2Q4+0x25a>
	}

	//Calculate var of 2nd array
	char v2[100] = "cav _y4";
f01036da:	c7 85 00 fe ff ff 63 	movl   $0x20766163,-0x200(%ebp)
f01036e1:	61 76 20 
f01036e4:	c7 85 04 fe ff ff 5f 	movl   $0x34795f,-0x1fc(%ebp)
f01036eb:	79 34 00 
f01036ee:	8d 95 08 fe ff ff    	lea    -0x1f8(%ebp),%edx
f01036f4:	b9 17 00 00 00       	mov    $0x17,%ecx
f01036f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01036fe:	89 d7                	mov    %edx,%edi
f0103700:	f3 ab                	rep stos %eax,%es:(%edi)
	strsplit(v2, WHITESPACE, args, &numOfArgs) ;
f0103702:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f0103708:	50                   	push   %eax
f0103709:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010370f:	50                   	push   %eax
f0103710:	68 d5 83 10 f0       	push   $0xf01083d5
f0103715:	8d 85 00 fe ff ff    	lea    -0x200(%ebp),%eax
f010371b:	50                   	push   %eax
f010371c:	e8 2e 39 00 00       	call   f010704f <strsplit>
f0103721:	83 c4 10             	add    $0x10,%esp
	ret = CalcArrVar(args) ;
f0103724:	83 ec 0c             	sub    $0xc,%esp
f0103727:	8d 85 2c ff ff ff    	lea    -0xd4(%ebp),%eax
f010372d:	50                   	push   %eax
f010372e:	e8 01 dc ff ff       	call   f0101334 <CalcArrVar>
f0103733:	83 c4 10             	add    $0x10,%esp
f0103736:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	if (ret != 40000)
f0103739:	81 7d d4 40 9c 00 00 	cmpl   $0x9c40,-0x2c(%ebp)
f0103740:	74 17                	je     f0103759 <TestAss2Q4+0x245>
	{
		cprintf("[EVAL] #2 CalcArrVar: Failed\n");
f0103742:	83 ec 0c             	sub    $0xc,%esp
f0103745:	68 d0 8d 10 f0       	push   $0xf0108dd0
f010374a:	e8 65 1f 00 00       	call   f01056b4 <cprintf>
f010374f:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103752:	b8 01 00 00 00       	mov    $0x1,%eax
f0103757:	eb 15                	jmp    f010376e <TestAss2Q4+0x25a>
	}

	cprintf("[EVAL] CalcArrVar: Succeeded\n");
f0103759:	83 ec 0c             	sub    $0xc,%esp
f010375c:	68 ee 8d 10 f0       	push   $0xf0108dee
f0103761:	e8 4e 1f 00 00       	call   f01056b4 <cprintf>
f0103766:	83 c4 10             	add    $0x10,%esp

	return 1;
f0103769:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010376e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103771:	5b                   	pop    %ebx
f0103772:	5e                   	pop    %esi
f0103773:	5f                   	pop    %edi
f0103774:	5d                   	pop    %ebp
f0103775:	c3                   	ret    

f0103776 <TestAss2BONUS>:

int TestAss2BONUS()
{
f0103776:	55                   	push   %ebp
f0103777:	89 e5                	mov    %esp,%ebp
f0103779:	57                   	push   %edi
f010377a:	56                   	push   %esi
f010377b:	53                   	push   %ebx
f010377c:	81 ec 0c 09 00 00    	sub    $0x90c,%esp
	int ret = 1;
f0103782:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int i = 0;
f0103789:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	//Create first array
	char cr1[100] = "cnia x1 20 1 2 3";
f0103790:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f0103796:	bb e3 90 10 f0       	mov    $0xf01090e3,%ebx
f010379b:	ba 11 00 00 00       	mov    $0x11,%edx
f01037a0:	89 c7                	mov    %eax,%edi
f01037a2:	89 de                	mov    %ebx,%esi
f01037a4:	89 d1                	mov    %edx,%ecx
f01037a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01037a8:	8d 95 79 ff ff ff    	lea    -0x87(%ebp),%edx
f01037ae:	b9 53 00 00 00       	mov    $0x53,%ecx
f01037b3:	b0 00                	mov    $0x0,%al
f01037b5:	89 d7                	mov    %edx,%edi
f01037b7:	f3 aa                	rep stos %al,%es:(%edi)
	int numOfArgs = 0;
f01037b9:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f01037c0:	00 00 00 
	char *args[MAX_ARGUMENTS] ;
	strsplit(cr1, WHITESPACE, args, &numOfArgs) ;
f01037c3:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f01037c9:	50                   	push   %eax
f01037ca:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f01037d0:	50                   	push   %eax
f01037d1:	68 d5 83 10 f0       	push   $0xf01083d5
f01037d6:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
f01037dc:	50                   	push   %eax
f01037dd:	e8 6d 38 00 00       	call   f010704f <strsplit>
f01037e2:	83 c4 10             	add    $0x10,%esp

	int* ptr1 = CreateIntArray(numOfArgs,args) ;
f01037e5:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f01037eb:	83 ec 08             	sub    $0x8,%esp
f01037ee:	8d 95 24 ff ff ff    	lea    -0xdc(%ebp),%edx
f01037f4:	52                   	push   %edx
f01037f5:	50                   	push   %eax
f01037f6:	e8 77 d6 ff ff       	call   f0100e72 <CreateIntArray>
f01037fb:	83 c4 10             	add    $0x10,%esp
f01037fe:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(ptr1 >= (int*)0xF1000000);
f0103801:	81 7d dc ff ff ff f0 	cmpl   $0xf0ffffff,-0x24(%ebp)
f0103808:	77 19                	ja     f0103823 <TestAss2BONUS+0xad>
f010380a:	68 da 83 10 f0       	push   $0xf01083da
f010380f:	68 f3 83 10 f0       	push   $0xf01083f3
f0103814:	68 73 01 00 00       	push   $0x173
f0103819:	68 08 84 10 f0       	push   $0xf0108408
f010381e:	e8 0b c9 ff ff       	call   f010012e <_panic>

	//Create second array
	char cr2[100] = "cnia y1 30 10 20 30";
f0103823:	8d 85 c0 fe ff ff    	lea    -0x140(%ebp),%eax
f0103829:	bb 47 91 10 f0       	mov    $0xf0109147,%ebx
f010382e:	ba 05 00 00 00       	mov    $0x5,%edx
f0103833:	89 c7                	mov    %eax,%edi
f0103835:	89 de                	mov    %ebx,%esi
f0103837:	89 d1                	mov    %edx,%ecx
f0103839:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010383b:	8d 95 d4 fe ff ff    	lea    -0x12c(%ebp),%edx
f0103841:	b9 14 00 00 00       	mov    $0x14,%ecx
f0103846:	b8 00 00 00 00       	mov    $0x0,%eax
f010384b:	89 d7                	mov    %edx,%edi
f010384d:	f3 ab                	rep stos %eax,%es:(%edi)
	numOfArgs = 0;
f010384f:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f0103856:	00 00 00 
	strsplit(cr2, WHITESPACE, args, &numOfArgs) ;
f0103859:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f010385f:	50                   	push   %eax
f0103860:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103866:	50                   	push   %eax
f0103867:	68 d5 83 10 f0       	push   $0xf01083d5
f010386c:	8d 85 c0 fe ff ff    	lea    -0x140(%ebp),%eax
f0103872:	50                   	push   %eax
f0103873:	e8 d7 37 00 00       	call   f010704f <strsplit>
f0103878:	83 c4 10             	add    $0x10,%esp

	int* ptr2 = CreateIntArray(numOfArgs,args) ;
f010387b:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f0103881:	83 ec 08             	sub    $0x8,%esp
f0103884:	8d 95 24 ff ff ff    	lea    -0xdc(%ebp),%edx
f010388a:	52                   	push   %edx
f010388b:	50                   	push   %eax
f010388c:	e8 e1 d5 ff ff       	call   f0100e72 <CreateIntArray>
f0103891:	83 c4 10             	add    $0x10,%esp
f0103894:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(ptr2 >= (int*)0xF1000000);
f0103897:	81 7d d8 ff ff ff f0 	cmpl   $0xf0ffffff,-0x28(%ebp)
f010389e:	77 19                	ja     f01038b9 <TestAss2BONUS+0x143>
f01038a0:	68 8c 86 10 f0       	push   $0xf010868c
f01038a5:	68 f3 83 10 f0       	push   $0xf01083f3
f01038aa:	68 7b 01 00 00       	push   $0x17b
f01038af:	68 08 84 10 f0       	push   $0xf0108408
f01038b4:	e8 75 c8 ff ff       	call   f010012e <_panic>

	//Create third array
	char cr3[100] = "cnia z1 10 100 200 300";
f01038b9:	8d 85 5c fe ff ff    	lea    -0x1a4(%ebp),%eax
f01038bf:	bb ab 91 10 f0       	mov    $0xf01091ab,%ebx
f01038c4:	ba 17 00 00 00       	mov    $0x17,%edx
f01038c9:	89 c7                	mov    %eax,%edi
f01038cb:	89 de                	mov    %ebx,%esi
f01038cd:	89 d1                	mov    %edx,%ecx
f01038cf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01038d1:	8d 95 73 fe ff ff    	lea    -0x18d(%ebp),%edx
f01038d7:	b9 4d 00 00 00       	mov    $0x4d,%ecx
f01038dc:	b0 00                	mov    $0x0,%al
f01038de:	89 d7                	mov    %edx,%edi
f01038e0:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f01038e2:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f01038e9:	00 00 00 
	strsplit(cr3, WHITESPACE, args, &numOfArgs) ;
f01038ec:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f01038f2:	50                   	push   %eax
f01038f3:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f01038f9:	50                   	push   %eax
f01038fa:	68 d5 83 10 f0       	push   $0xf01083d5
f01038ff:	8d 85 5c fe ff ff    	lea    -0x1a4(%ebp),%eax
f0103905:	50                   	push   %eax
f0103906:	e8 44 37 00 00       	call   f010704f <strsplit>
f010390b:	83 c4 10             	add    $0x10,%esp

	int* ptr3 = CreateIntArray(numOfArgs,args) ;
f010390e:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f0103914:	83 ec 08             	sub    $0x8,%esp
f0103917:	8d 95 24 ff ff ff    	lea    -0xdc(%ebp),%edx
f010391d:	52                   	push   %edx
f010391e:	50                   	push   %eax
f010391f:	e8 4e d5 ff ff       	call   f0100e72 <CreateIntArray>
f0103924:	83 c4 10             	add    $0x10,%esp
f0103927:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(ptr3 >= (int*)0xF1000000);
f010392a:	81 7d d4 ff ff ff f0 	cmpl   $0xf0ffffff,-0x2c(%ebp)
f0103931:	77 19                	ja     f010394c <TestAss2BONUS+0x1d6>
f0103933:	68 a5 86 10 f0       	push   $0xf01086a5
f0103938:	68 f3 83 10 f0       	push   $0xf01083f3
f010393d:	68 83 01 00 00       	push   $0x183
f0103942:	68 08 84 10 f0       	push   $0xf0108408
f0103947:	e8 e2 c7 ff ff       	call   f010012e <_panic>

	//Create fourth array
	char cr4[100] = "cnia w1 40 -1 -2 -3";
f010394c:	8d 85 f8 fd ff ff    	lea    -0x208(%ebp),%eax
f0103952:	bb 0f 92 10 f0       	mov    $0xf010920f,%ebx
f0103957:	ba 05 00 00 00       	mov    $0x5,%edx
f010395c:	89 c7                	mov    %eax,%edi
f010395e:	89 de                	mov    %ebx,%esi
f0103960:	89 d1                	mov    %edx,%ecx
f0103962:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103964:	8d 95 0c fe ff ff    	lea    -0x1f4(%ebp),%edx
f010396a:	b9 14 00 00 00       	mov    $0x14,%ecx
f010396f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103974:	89 d7                	mov    %edx,%edi
f0103976:	f3 ab                	rep stos %eax,%es:(%edi)
	numOfArgs = 0;
f0103978:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f010397f:	00 00 00 
	strsplit(cr4, WHITESPACE, args, &numOfArgs) ;
f0103982:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103988:	50                   	push   %eax
f0103989:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f010398f:	50                   	push   %eax
f0103990:	68 d5 83 10 f0       	push   $0xf01083d5
f0103995:	8d 85 f8 fd ff ff    	lea    -0x208(%ebp),%eax
f010399b:	50                   	push   %eax
f010399c:	e8 ae 36 00 00       	call   f010704f <strsplit>
f01039a1:	83 c4 10             	add    $0x10,%esp

	int* ptr4 = CreateIntArray(numOfArgs,args) ;
f01039a4:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f01039aa:	83 ec 08             	sub    $0x8,%esp
f01039ad:	8d 95 24 ff ff ff    	lea    -0xdc(%ebp),%edx
f01039b3:	52                   	push   %edx
f01039b4:	50                   	push   %eax
f01039b5:	e8 b8 d4 ff ff       	call   f0100e72 <CreateIntArray>
f01039ba:	83 c4 10             	add    $0x10,%esp
f01039bd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	assert(ptr4 >= (int*)0xF1000000);
f01039c0:	81 7d d0 ff ff ff f0 	cmpl   $0xf0ffffff,-0x30(%ebp)
f01039c7:	77 19                	ja     f01039e2 <TestAss2BONUS+0x26c>
f01039c9:	68 de 8a 10 f0       	push   $0xf0108ade
f01039ce:	68 f3 83 10 f0       	push   $0xf01083f3
f01039d3:	68 8b 01 00 00       	push   $0x18b
f01039d8:	68 08 84 10 f0       	push   $0xf0108408
f01039dd:	e8 4c c7 ff ff       	call   f010012e <_panic>

	//Merge1
	char mr1[100] = "mta x1 y1 x2";
f01039e2:	8d 85 94 fd ff ff    	lea    -0x26c(%ebp),%eax
f01039e8:	bb 73 92 10 f0       	mov    $0xf0109273,%ebx
f01039ed:	ba 0d 00 00 00       	mov    $0xd,%edx
f01039f2:	89 c7                	mov    %eax,%edi
f01039f4:	89 de                	mov    %ebx,%esi
f01039f6:	89 d1                	mov    %edx,%ecx
f01039f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01039fa:	8d 95 a1 fd ff ff    	lea    -0x25f(%ebp),%edx
f0103a00:	b9 57 00 00 00       	mov    $0x57,%ecx
f0103a05:	b0 00                	mov    $0x0,%al
f0103a07:	89 d7                	mov    %edx,%edi
f0103a09:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0103a0b:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f0103a12:	00 00 00 
	strsplit(mr1, WHITESPACE, args, &numOfArgs) ;
f0103a15:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103a1b:	50                   	push   %eax
f0103a1c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103a22:	50                   	push   %eax
f0103a23:	68 d5 83 10 f0       	push   $0xf01083d5
f0103a28:	8d 85 94 fd ff ff    	lea    -0x26c(%ebp),%eax
f0103a2e:	50                   	push   %eax
f0103a2f:	e8 1b 36 00 00       	call   f010704f <strsplit>
f0103a34:	83 c4 10             	add    $0x10,%esp

	MergeTwoArrays(args) ;
f0103a37:	83 ec 0c             	sub    $0xc,%esp
f0103a3a:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103a40:	50                   	push   %eax
f0103a41:	e8 8b da ff ff       	call   f01014d1 <MergeTwoArrays>
f0103a46:	83 c4 10             	add    $0x10,%esp

	//Find
	char f1[100] = "fia x1 1";
f0103a49:	8d 85 30 fd ff ff    	lea    -0x2d0(%ebp),%eax
f0103a4f:	bb d7 92 10 f0       	mov    $0xf01092d7,%ebx
f0103a54:	ba 09 00 00 00       	mov    $0x9,%edx
f0103a59:	89 c7                	mov    %eax,%edi
f0103a5b:	89 de                	mov    %ebx,%esi
f0103a5d:	89 d1                	mov    %edx,%ecx
f0103a5f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103a61:	8d 95 39 fd ff ff    	lea    -0x2c7(%ebp),%edx
f0103a67:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f0103a6c:	b0 00                	mov    $0x0,%al
f0103a6e:	89 d7                	mov    %edx,%edi
f0103a70:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f1, WHITESPACE, args, &numOfArgs) ;
f0103a72:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103a78:	50                   	push   %eax
f0103a79:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103a7f:	50                   	push   %eax
f0103a80:	68 d5 83 10 f0       	push   $0xf01083d5
f0103a85:	8d 85 30 fd ff ff    	lea    -0x2d0(%ebp),%eax
f0103a8b:	50                   	push   %eax
f0103a8c:	e8 be 35 00 00       	call   f010704f <strsplit>
f0103a91:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103a94:	83 ec 0c             	sub    $0xc,%esp
f0103a97:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103a9d:	50                   	push   %eax
f0103a9e:	e8 60 d7 ff ff       	call   f0101203 <FindElementInArray>
f0103aa3:	83 c4 10             	add    $0x10,%esp
f0103aa6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f0103aa9:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0103aad:	74 1a                	je     f0103ac9 <TestAss2BONUS+0x353>
	{
		cprintf("[EVAL] #1 MergeTwoArrays: Failed\n");
f0103aaf:	83 ec 0c             	sub    $0xc,%esp
f0103ab2:	68 d4 8e 10 f0       	push   $0xf0108ed4
f0103ab7:	e8 f8 1b 00 00       	call   f01056b4 <cprintf>
f0103abc:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103abf:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ac4:	e9 fc 07 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}
	char f2[100] = "fia y1 30";
f0103ac9:	8d 85 cc fc ff ff    	lea    -0x334(%ebp),%eax
f0103acf:	bb 3b 93 10 f0       	mov    $0xf010933b,%ebx
f0103ad4:	ba 0a 00 00 00       	mov    $0xa,%edx
f0103ad9:	89 c7                	mov    %eax,%edi
f0103adb:	89 de                	mov    %ebx,%esi
f0103add:	89 d1                	mov    %edx,%ecx
f0103adf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103ae1:	8d 95 d6 fc ff ff    	lea    -0x32a(%ebp),%edx
f0103ae7:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0103aec:	b0 00                	mov    $0x0,%al
f0103aee:	89 d7                	mov    %edx,%edi
f0103af0:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f2, WHITESPACE, args, &numOfArgs) ;
f0103af2:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103af8:	50                   	push   %eax
f0103af9:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103aff:	50                   	push   %eax
f0103b00:	68 d5 83 10 f0       	push   $0xf01083d5
f0103b05:	8d 85 cc fc ff ff    	lea    -0x334(%ebp),%eax
f0103b0b:	50                   	push   %eax
f0103b0c:	e8 3e 35 00 00       	call   f010704f <strsplit>
f0103b11:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103b14:	83 ec 0c             	sub    $0xc,%esp
f0103b17:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103b1d:	50                   	push   %eax
f0103b1e:	e8 e0 d6 ff ff       	call   f0101203 <FindElementInArray>
f0103b23:	83 c4 10             	add    $0x10,%esp
f0103b26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f0103b29:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0103b2d:	74 1a                	je     f0103b49 <TestAss2BONUS+0x3d3>
	{
		cprintf("[EVAL] #2 MergeTwoArrays: Failed\n");
f0103b2f:	83 ec 0c             	sub    $0xc,%esp
f0103b32:	68 f8 8e 10 f0       	push   $0xf0108ef8
f0103b37:	e8 78 1b 00 00       	call   f01056b4 <cprintf>
f0103b3c:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103b3f:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b44:	e9 7c 07 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f3[100] = "fia x2 1";
f0103b49:	8d 85 68 fc ff ff    	lea    -0x398(%ebp),%eax
f0103b4f:	bb 9f 93 10 f0       	mov    $0xf010939f,%ebx
f0103b54:	ba 09 00 00 00       	mov    $0x9,%edx
f0103b59:	89 c7                	mov    %eax,%edi
f0103b5b:	89 de                	mov    %ebx,%esi
f0103b5d:	89 d1                	mov    %edx,%ecx
f0103b5f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103b61:	8d 95 71 fc ff ff    	lea    -0x38f(%ebp),%edx
f0103b67:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f0103b6c:	b0 00                	mov    $0x0,%al
f0103b6e:	89 d7                	mov    %edx,%edi
f0103b70:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f3, WHITESPACE, args, &numOfArgs) ;
f0103b72:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103b78:	50                   	push   %eax
f0103b79:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103b7f:	50                   	push   %eax
f0103b80:	68 d5 83 10 f0       	push   $0xf01083d5
f0103b85:	8d 85 68 fc ff ff    	lea    -0x398(%ebp),%eax
f0103b8b:	50                   	push   %eax
f0103b8c:	e8 be 34 00 00       	call   f010704f <strsplit>
f0103b91:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103b94:	83 ec 0c             	sub    $0xc,%esp
f0103b97:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103b9d:	50                   	push   %eax
f0103b9e:	e8 60 d6 ff ff       	call   f0101203 <FindElementInArray>
f0103ba3:	83 c4 10             	add    $0x10,%esp
f0103ba6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 0)
f0103ba9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103bad:	74 1a                	je     f0103bc9 <TestAss2BONUS+0x453>
	{
		cprintf("[EVAL] #3 MergeTwoArrays: Failed\n");
f0103baf:	83 ec 0c             	sub    $0xc,%esp
f0103bb2:	68 1c 8f 10 f0       	push   $0xf0108f1c
f0103bb7:	e8 f8 1a 00 00       	call   f01056b4 <cprintf>
f0103bbc:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103bbf:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bc4:	e9 fc 06 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	//Create fifth array
	char cr5[100] = "cnia m1 5 -1 1 -1";
f0103bc9:	8d 85 04 fc ff ff    	lea    -0x3fc(%ebp),%eax
f0103bcf:	bb 03 94 10 f0       	mov    $0xf0109403,%ebx
f0103bd4:	ba 12 00 00 00       	mov    $0x12,%edx
f0103bd9:	89 c7                	mov    %eax,%edi
f0103bdb:	89 de                	mov    %ebx,%esi
f0103bdd:	89 d1                	mov    %edx,%ecx
f0103bdf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103be1:	8d 95 16 fc ff ff    	lea    -0x3ea(%ebp),%edx
f0103be7:	b9 52 00 00 00       	mov    $0x52,%ecx
f0103bec:	b0 00                	mov    $0x0,%al
f0103bee:	89 d7                	mov    %edx,%edi
f0103bf0:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0103bf2:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f0103bf9:	00 00 00 
	strsplit(cr5, WHITESPACE, args, &numOfArgs) ;
f0103bfc:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103c02:	50                   	push   %eax
f0103c03:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103c09:	50                   	push   %eax
f0103c0a:	68 d5 83 10 f0       	push   $0xf01083d5
f0103c0f:	8d 85 04 fc ff ff    	lea    -0x3fc(%ebp),%eax
f0103c15:	50                   	push   %eax
f0103c16:	e8 34 34 00 00       	call   f010704f <strsplit>
f0103c1b:	83 c4 10             	add    $0x10,%esp

	int* ptr5 = CreateIntArray(numOfArgs,args) ;
f0103c1e:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
f0103c24:	83 ec 08             	sub    $0x8,%esp
f0103c27:	8d 95 24 ff ff ff    	lea    -0xdc(%ebp),%edx
f0103c2d:	52                   	push   %edx
f0103c2e:	50                   	push   %eax
f0103c2f:	e8 3e d2 ff ff       	call   f0100e72 <CreateIntArray>
f0103c34:	83 c4 10             	add    $0x10,%esp
f0103c37:	89 45 cc             	mov    %eax,-0x34(%ebp)
	assert(ptr5 >= (int*)0xF1000000);
f0103c3a:	81 7d cc ff ff ff f0 	cmpl   $0xf0ffffff,-0x34(%ebp)
f0103c41:	77 19                	ja     f0103c5c <TestAss2BONUS+0x4e6>
f0103c43:	68 3e 8f 10 f0       	push   $0xf0108f3e
f0103c48:	68 f3 83 10 f0       	push   $0xf01083f3
f0103c4d:	68 b5 01 00 00       	push   $0x1b5
f0103c52:	68 08 84 10 f0       	push   $0xf0108408
f0103c57:	e8 d2 c4 ff ff       	call   f010012e <_panic>


	char f4[100] = "fia x2 0";
f0103c5c:	8d 85 a0 fb ff ff    	lea    -0x460(%ebp),%eax
f0103c62:	bb 67 94 10 f0       	mov    $0xf0109467,%ebx
f0103c67:	ba 09 00 00 00       	mov    $0x9,%edx
f0103c6c:	89 c7                	mov    %eax,%edi
f0103c6e:	89 de                	mov    %ebx,%esi
f0103c70:	89 d1                	mov    %edx,%ecx
f0103c72:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103c74:	8d 95 a9 fb ff ff    	lea    -0x457(%ebp),%edx
f0103c7a:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f0103c7f:	b0 00                	mov    $0x0,%al
f0103c81:	89 d7                	mov    %edx,%edi
f0103c83:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f4, WHITESPACE, args, &numOfArgs) ;
f0103c85:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103c8b:	50                   	push   %eax
f0103c8c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103c92:	50                   	push   %eax
f0103c93:	68 d5 83 10 f0       	push   $0xf01083d5
f0103c98:	8d 85 a0 fb ff ff    	lea    -0x460(%ebp),%eax
f0103c9e:	50                   	push   %eax
f0103c9f:	e8 ab 33 00 00       	call   f010704f <strsplit>
f0103ca4:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103ca7:	83 ec 0c             	sub    $0xc,%esp
f0103caa:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103cb0:	50                   	push   %eax
f0103cb1:	e8 4d d5 ff ff       	call   f0101203 <FindElementInArray>
f0103cb6:	83 c4 10             	add    $0x10,%esp
f0103cb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 3)
f0103cbc:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
f0103cc0:	74 1a                	je     f0103cdc <TestAss2BONUS+0x566>
	{
		cprintf("[EVAL] #4 MergeTwoArrays: Failed\n");
f0103cc2:	83 ec 0c             	sub    $0xc,%esp
f0103cc5:	68 58 8f 10 f0       	push   $0xf0108f58
f0103cca:	e8 e5 19 00 00       	call   f01056b4 <cprintf>
f0103ccf:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103cd2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cd7:	e9 e9 05 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f5[100] = "fia x2 30";
f0103cdc:	8d 85 3c fb ff ff    	lea    -0x4c4(%ebp),%eax
f0103ce2:	bb cb 94 10 f0       	mov    $0xf01094cb,%ebx
f0103ce7:	ba 0a 00 00 00       	mov    $0xa,%edx
f0103cec:	89 c7                	mov    %eax,%edi
f0103cee:	89 de                	mov    %ebx,%esi
f0103cf0:	89 d1                	mov    %edx,%ecx
f0103cf2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103cf4:	8d 95 46 fb ff ff    	lea    -0x4ba(%ebp),%edx
f0103cfa:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0103cff:	b0 00                	mov    $0x0,%al
f0103d01:	89 d7                	mov    %edx,%edi
f0103d03:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f5, WHITESPACE, args, &numOfArgs) ;
f0103d05:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103d0b:	50                   	push   %eax
f0103d0c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103d12:	50                   	push   %eax
f0103d13:	68 d5 83 10 f0       	push   $0xf01083d5
f0103d18:	8d 85 3c fb ff ff    	lea    -0x4c4(%ebp),%eax
f0103d1e:	50                   	push   %eax
f0103d1f:	e8 2b 33 00 00       	call   f010704f <strsplit>
f0103d24:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103d27:	83 ec 0c             	sub    $0xc,%esp
f0103d2a:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103d30:	50                   	push   %eax
f0103d31:	e8 cd d4 ff ff       	call   f0101203 <FindElementInArray>
f0103d36:	83 c4 10             	add    $0x10,%esp
f0103d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 22)
f0103d3c:	83 7d e4 16          	cmpl   $0x16,-0x1c(%ebp)
f0103d40:	74 1a                	je     f0103d5c <TestAss2BONUS+0x5e6>
	{
		cprintf("[EVAL] #5 MergeTwoArrays: Failed\n");
f0103d42:	83 ec 0c             	sub    $0xc,%esp
f0103d45:	68 7c 8f 10 f0       	push   $0xf0108f7c
f0103d4a:	e8 65 19 00 00       	call   f01056b4 <cprintf>
f0103d4f:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103d52:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d57:	e9 69 05 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f6[100] = "fia x2 -1";
f0103d5c:	8d 85 d8 fa ff ff    	lea    -0x528(%ebp),%eax
f0103d62:	bb 2f 95 10 f0       	mov    $0xf010952f,%ebx
f0103d67:	ba 0a 00 00 00       	mov    $0xa,%edx
f0103d6c:	89 c7                	mov    %eax,%edi
f0103d6e:	89 de                	mov    %ebx,%esi
f0103d70:	89 d1                	mov    %edx,%ecx
f0103d72:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103d74:	8d 95 e2 fa ff ff    	lea    -0x51e(%ebp),%edx
f0103d7a:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0103d7f:	b0 00                	mov    $0x0,%al
f0103d81:	89 d7                	mov    %edx,%edi
f0103d83:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f6, WHITESPACE, args, &numOfArgs) ;
f0103d85:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103d8b:	50                   	push   %eax
f0103d8c:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103d92:	50                   	push   %eax
f0103d93:	68 d5 83 10 f0       	push   $0xf01083d5
f0103d98:	8d 85 d8 fa ff ff    	lea    -0x528(%ebp),%eax
f0103d9e:	50                   	push   %eax
f0103d9f:	e8 ab 32 00 00       	call   f010704f <strsplit>
f0103da4:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103da7:	83 ec 0c             	sub    $0xc,%esp
f0103daa:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103db0:	50                   	push   %eax
f0103db1:	e8 4d d4 ff ff       	call   f0101203 <FindElementInArray>
f0103db6:	83 c4 10             	add    $0x10,%esp
f0103db9:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if (ret != -1)
f0103dbc:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0103dc0:	74 1a                	je     f0103ddc <TestAss2BONUS+0x666>
	{
		cprintf("[EVAL] #6 MergeTwoArrays: Failed\n");
f0103dc2:	83 ec 0c             	sub    $0xc,%esp
f0103dc5:	68 a0 8f 10 f0       	push   $0xf0108fa0
f0103dca:	e8 e5 18 00 00       	call   f01056b4 <cprintf>
f0103dcf:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103dd2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103dd7:	e9 e9 04 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	//Merge2
	char mr2[100] = "mta z1 x2 z1";
f0103ddc:	8d 85 74 fa ff ff    	lea    -0x58c(%ebp),%eax
f0103de2:	bb 93 95 10 f0       	mov    $0xf0109593,%ebx
f0103de7:	ba 0d 00 00 00       	mov    $0xd,%edx
f0103dec:	89 c7                	mov    %eax,%edi
f0103dee:	89 de                	mov    %ebx,%esi
f0103df0:	89 d1                	mov    %edx,%ecx
f0103df2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103df4:	8d 95 81 fa ff ff    	lea    -0x57f(%ebp),%edx
f0103dfa:	b9 57 00 00 00       	mov    $0x57,%ecx
f0103dff:	b0 00                	mov    $0x0,%al
f0103e01:	89 d7                	mov    %edx,%edi
f0103e03:	f3 aa                	rep stos %al,%es:(%edi)
	numOfArgs = 0;
f0103e05:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
f0103e0c:	00 00 00 
	strsplit(mr2, WHITESPACE, args, &numOfArgs) ;
f0103e0f:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103e15:	50                   	push   %eax
f0103e16:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103e1c:	50                   	push   %eax
f0103e1d:	68 d5 83 10 f0       	push   $0xf01083d5
f0103e22:	8d 85 74 fa ff ff    	lea    -0x58c(%ebp),%eax
f0103e28:	50                   	push   %eax
f0103e29:	e8 21 32 00 00       	call   f010704f <strsplit>
f0103e2e:	83 c4 10             	add    $0x10,%esp

	MergeTwoArrays(args) ;
f0103e31:	83 ec 0c             	sub    $0xc,%esp
f0103e34:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103e3a:	50                   	push   %eax
f0103e3b:	e8 91 d6 ff ff       	call   f01014d1 <MergeTwoArrays>
f0103e40:	83 c4 10             	add    $0x10,%esp

	char f7[100] = "fia z1 100";
f0103e43:	8d 85 10 fa ff ff    	lea    -0x5f0(%ebp),%eax
f0103e49:	bb f7 95 10 f0       	mov    $0xf01095f7,%ebx
f0103e4e:	ba 0b 00 00 00       	mov    $0xb,%edx
f0103e53:	89 c7                	mov    %eax,%edi
f0103e55:	89 de                	mov    %ebx,%esi
f0103e57:	89 d1                	mov    %edx,%ecx
f0103e59:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103e5b:	8d 95 1b fa ff ff    	lea    -0x5e5(%ebp),%edx
f0103e61:	b9 59 00 00 00       	mov    $0x59,%ecx
f0103e66:	b0 00                	mov    $0x0,%al
f0103e68:	89 d7                	mov    %edx,%edi
f0103e6a:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f7, WHITESPACE, args, &numOfArgs) ;
f0103e6c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103e72:	50                   	push   %eax
f0103e73:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103e79:	50                   	push   %eax
f0103e7a:	68 d5 83 10 f0       	push   $0xf01083d5
f0103e7f:	8d 85 10 fa ff ff    	lea    -0x5f0(%ebp),%eax
f0103e85:	50                   	push   %eax
f0103e86:	e8 c4 31 00 00       	call   f010704f <strsplit>
f0103e8b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103e8e:	83 ec 0c             	sub    $0xc,%esp
f0103e91:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103e97:	50                   	push   %eax
f0103e98:	e8 66 d3 ff ff       	call   f0101203 <FindElementInArray>
f0103e9d:	83 c4 10             	add    $0x10,%esp
f0103ea0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 0)
f0103ea3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103ea7:	74 1a                	je     f0103ec3 <TestAss2BONUS+0x74d>
	{
		cprintf("[EVAL] #7 MergeTwoArrays: Failed\n");
f0103ea9:	83 ec 0c             	sub    $0xc,%esp
f0103eac:	68 c4 8f 10 f0       	push   $0xf0108fc4
f0103eb1:	e8 fe 17 00 00       	call   f01056b4 <cprintf>
f0103eb6:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103eb9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ebe:	e9 02 04 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f8[100] = "fia x2 1";
f0103ec3:	8d 85 ac f9 ff ff    	lea    -0x654(%ebp),%eax
f0103ec9:	bb 9f 93 10 f0       	mov    $0xf010939f,%ebx
f0103ece:	ba 09 00 00 00       	mov    $0x9,%edx
f0103ed3:	89 c7                	mov    %eax,%edi
f0103ed5:	89 de                	mov    %ebx,%esi
f0103ed7:	89 d1                	mov    %edx,%ecx
f0103ed9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103edb:	8d 95 b5 f9 ff ff    	lea    -0x64b(%ebp),%edx
f0103ee1:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f0103ee6:	b0 00                	mov    $0x0,%al
f0103ee8:	89 d7                	mov    %edx,%edi
f0103eea:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f8, WHITESPACE, args, &numOfArgs) ;
f0103eec:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103ef2:	50                   	push   %eax
f0103ef3:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103ef9:	50                   	push   %eax
f0103efa:	68 d5 83 10 f0       	push   $0xf01083d5
f0103eff:	8d 85 ac f9 ff ff    	lea    -0x654(%ebp),%eax
f0103f05:	50                   	push   %eax
f0103f06:	e8 44 31 00 00       	call   f010704f <strsplit>
f0103f0b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103f0e:	83 ec 0c             	sub    $0xc,%esp
f0103f11:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103f17:	50                   	push   %eax
f0103f18:	e8 e6 d2 ff ff       	call   f0101203 <FindElementInArray>
f0103f1d:	83 c4 10             	add    $0x10,%esp
f0103f20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f0103f23:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0103f27:	74 1a                	je     f0103f43 <TestAss2BONUS+0x7cd>
	{
		cprintf("[EVAL] #8 MergeTwoArrays: Failed\n");
f0103f29:	83 ec 0c             	sub    $0xc,%esp
f0103f2c:	68 e8 8f 10 f0       	push   $0xf0108fe8
f0103f31:	e8 7e 17 00 00       	call   f01056b4 <cprintf>
f0103f36:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103f39:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f3e:	e9 82 03 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f9[100] = "fia z1 1";
f0103f43:	8d 85 48 f9 ff ff    	lea    -0x6b8(%ebp),%eax
f0103f49:	bb 5b 96 10 f0       	mov    $0xf010965b,%ebx
f0103f4e:	ba 09 00 00 00       	mov    $0x9,%edx
f0103f53:	89 c7                	mov    %eax,%edi
f0103f55:	89 de                	mov    %ebx,%esi
f0103f57:	89 d1                	mov    %edx,%ecx
f0103f59:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103f5b:	8d 95 51 f9 ff ff    	lea    -0x6af(%ebp),%edx
f0103f61:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f0103f66:	b0 00                	mov    $0x0,%al
f0103f68:	89 d7                	mov    %edx,%edi
f0103f6a:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f9, WHITESPACE, args, &numOfArgs) ;
f0103f6c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103f72:	50                   	push   %eax
f0103f73:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103f79:	50                   	push   %eax
f0103f7a:	68 d5 83 10 f0       	push   $0xf01083d5
f0103f7f:	8d 85 48 f9 ff ff    	lea    -0x6b8(%ebp),%eax
f0103f85:	50                   	push   %eax
f0103f86:	e8 c4 30 00 00       	call   f010704f <strsplit>
f0103f8b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f0103f8e:	83 ec 0c             	sub    $0xc,%esp
f0103f91:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103f97:	50                   	push   %eax
f0103f98:	e8 66 d2 ff ff       	call   f0101203 <FindElementInArray>
f0103f9d:	83 c4 10             	add    $0x10,%esp
f0103fa0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 10)
f0103fa3:	83 7d e4 0a          	cmpl   $0xa,-0x1c(%ebp)
f0103fa7:	74 1a                	je     f0103fc3 <TestAss2BONUS+0x84d>
	{
		cprintf("[EVAL] #9 MergeTwoArrays: Failed\n");
f0103fa9:	83 ec 0c             	sub    $0xc,%esp
f0103fac:	68 0c 90 10 f0       	push   $0xf010900c
f0103fb1:	e8 fe 16 00 00       	call   f01056b4 <cprintf>
f0103fb6:	83 c4 10             	add    $0x10,%esp
		return 1;
f0103fb9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fbe:	e9 02 03 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f10[100] = "fia z1 30";
f0103fc3:	8d 85 e4 f8 ff ff    	lea    -0x71c(%ebp),%eax
f0103fc9:	bb bf 96 10 f0       	mov    $0xf01096bf,%ebx
f0103fce:	ba 0a 00 00 00       	mov    $0xa,%edx
f0103fd3:	89 c7                	mov    %eax,%edi
f0103fd5:	89 de                	mov    %ebx,%esi
f0103fd7:	89 d1                	mov    %edx,%ecx
f0103fd9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f0103fdb:	8d 95 ee f8 ff ff    	lea    -0x712(%ebp),%edx
f0103fe1:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0103fe6:	b0 00                	mov    $0x0,%al
f0103fe8:	89 d7                	mov    %edx,%edi
f0103fea:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f10, WHITESPACE, args, &numOfArgs) ;
f0103fec:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0103ff2:	50                   	push   %eax
f0103ff3:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0103ff9:	50                   	push   %eax
f0103ffa:	68 d5 83 10 f0       	push   $0xf01083d5
f0103fff:	8d 85 e4 f8 ff ff    	lea    -0x71c(%ebp),%eax
f0104005:	50                   	push   %eax
f0104006:	e8 44 30 00 00       	call   f010704f <strsplit>
f010400b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010400e:	83 ec 0c             	sub    $0xc,%esp
f0104011:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104017:	50                   	push   %eax
f0104018:	e8 e6 d1 ff ff       	call   f0101203 <FindElementInArray>
f010401d:	83 c4 10             	add    $0x10,%esp
f0104020:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 32)
f0104023:	83 7d e4 20          	cmpl   $0x20,-0x1c(%ebp)
f0104027:	74 1a                	je     f0104043 <TestAss2BONUS+0x8cd>
	{
		cprintf("[EVAL] #10 MergeTwoArrays: Failed\n");
f0104029:	83 ec 0c             	sub    $0xc,%esp
f010402c:	68 30 90 10 f0       	push   $0xf0109030
f0104031:	e8 7e 16 00 00       	call   f01056b4 <cprintf>
f0104036:	83 c4 10             	add    $0x10,%esp
		return 1;
f0104039:	b8 01 00 00 00       	mov    $0x1,%eax
f010403e:	e9 82 02 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char f11[100] = "fia z1 -1";
f0104043:	8d 85 80 f8 ff ff    	lea    -0x780(%ebp),%eax
f0104049:	bb 23 97 10 f0       	mov    $0xf0109723,%ebx
f010404e:	ba 0a 00 00 00       	mov    $0xa,%edx
f0104053:	89 c7                	mov    %eax,%edi
f0104055:	89 de                	mov    %ebx,%esi
f0104057:	89 d1                	mov    %edx,%ecx
f0104059:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f010405b:	8d 95 8a f8 ff ff    	lea    -0x776(%ebp),%edx
f0104061:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0104066:	b0 00                	mov    $0x0,%al
f0104068:	89 d7                	mov    %edx,%edi
f010406a:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(f11, WHITESPACE, args, &numOfArgs) ;
f010406c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0104072:	50                   	push   %eax
f0104073:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104079:	50                   	push   %eax
f010407a:	68 d5 83 10 f0       	push   $0xf01083d5
f010407f:	8d 85 80 f8 ff ff    	lea    -0x780(%ebp),%eax
f0104085:	50                   	push   %eax
f0104086:	e8 c4 2f 00 00       	call   f010704f <strsplit>
f010408b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010408e:	83 ec 0c             	sub    $0xc,%esp
f0104091:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104097:	50                   	push   %eax
f0104098:	e8 66 d1 ff ff       	call   f0101203 <FindElementInArray>
f010409d:	83 c4 10             	add    $0x10,%esp
f01040a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f01040a3:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f01040a7:	74 1a                	je     f01040c3 <TestAss2BONUS+0x94d>
	{
		cprintf("[EVAL] #11 MergeTwoArrays: Failed\n");
f01040a9:	83 ec 0c             	sub    $0xc,%esp
f01040ac:	68 54 90 10 f0       	push   $0xf0109054
f01040b1:	e8 fe 15 00 00       	call   f01056b4 <cprintf>
f01040b6:	83 c4 10             	add    $0x10,%esp
		return 1;
f01040b9:	b8 01 00 00 00       	mov    $0x1,%eax
f01040be:	e9 02 02 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	//Check ALL other arrays
	char ff1[100] = "fia x1 1";
f01040c3:	8d 85 1c f8 ff ff    	lea    -0x7e4(%ebp),%eax
f01040c9:	bb d7 92 10 f0       	mov    $0xf01092d7,%ebx
f01040ce:	ba 09 00 00 00       	mov    $0x9,%edx
f01040d3:	89 c7                	mov    %eax,%edi
f01040d5:	89 de                	mov    %ebx,%esi
f01040d7:	89 d1                	mov    %edx,%ecx
f01040d9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01040db:	8d 95 25 f8 ff ff    	lea    -0x7db(%ebp),%edx
f01040e1:	b9 5b 00 00 00       	mov    $0x5b,%ecx
f01040e6:	b0 00                	mov    $0x0,%al
f01040e8:	89 d7                	mov    %edx,%edi
f01040ea:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(ff1, WHITESPACE, args, &numOfArgs) ;
f01040ec:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f01040f2:	50                   	push   %eax
f01040f3:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f01040f9:	50                   	push   %eax
f01040fa:	68 d5 83 10 f0       	push   $0xf01083d5
f01040ff:	8d 85 1c f8 ff ff    	lea    -0x7e4(%ebp),%eax
f0104105:	50                   	push   %eax
f0104106:	e8 44 2f 00 00       	call   f010704f <strsplit>
f010410b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010410e:	83 ec 0c             	sub    $0xc,%esp
f0104111:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104117:	50                   	push   %eax
f0104118:	e8 e6 d0 ff ff       	call   f0101203 <FindElementInArray>
f010411d:	83 c4 10             	add    $0x10,%esp
f0104120:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f0104123:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0104127:	74 1a                	je     f0104143 <TestAss2BONUS+0x9cd>
	{
		cprintf("[EVAL] #12 MergeTwoArrays: Failed\n");
f0104129:	83 ec 0c             	sub    $0xc,%esp
f010412c:	68 78 90 10 f0       	push   $0xf0109078
f0104131:	e8 7e 15 00 00       	call   f01056b4 <cprintf>
f0104136:	83 c4 10             	add    $0x10,%esp
		return 1;
f0104139:	b8 01 00 00 00       	mov    $0x1,%eax
f010413e:	e9 82 01 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char ff2[100] = "fia y1 30";
f0104143:	8d 85 b8 f7 ff ff    	lea    -0x848(%ebp),%eax
f0104149:	bb 3b 93 10 f0       	mov    $0xf010933b,%ebx
f010414e:	ba 0a 00 00 00       	mov    $0xa,%edx
f0104153:	89 c7                	mov    %eax,%edi
f0104155:	89 de                	mov    %ebx,%esi
f0104157:	89 d1                	mov    %edx,%ecx
f0104159:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f010415b:	8d 95 c2 f7 ff ff    	lea    -0x83e(%ebp),%edx
f0104161:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0104166:	b0 00                	mov    $0x0,%al
f0104168:	89 d7                	mov    %edx,%edi
f010416a:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(ff2, WHITESPACE, args, &numOfArgs) ;
f010416c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0104172:	50                   	push   %eax
f0104173:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104179:	50                   	push   %eax
f010417a:	68 d5 83 10 f0       	push   $0xf01083d5
f010417f:	8d 85 b8 f7 ff ff    	lea    -0x848(%ebp),%eax
f0104185:	50                   	push   %eax
f0104186:	e8 c4 2e 00 00       	call   f010704f <strsplit>
f010418b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010418e:	83 ec 0c             	sub    $0xc,%esp
f0104191:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104197:	50                   	push   %eax
f0104198:	e8 66 d0 ff ff       	call   f0101203 <FindElementInArray>
f010419d:	83 c4 10             	add    $0x10,%esp
f01041a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != -1)
f01041a3:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f01041a7:	74 1a                	je     f01041c3 <TestAss2BONUS+0xa4d>
	{
		cprintf("[EVAL] #12 MergeTwoArrays: Failed\n");
f01041a9:	83 ec 0c             	sub    $0xc,%esp
f01041ac:	68 78 90 10 f0       	push   $0xf0109078
f01041b1:	e8 fe 14 00 00       	call   f01056b4 <cprintf>
f01041b6:	83 c4 10             	add    $0x10,%esp
		return 1;
f01041b9:	b8 01 00 00 00       	mov    $0x1,%eax
f01041be:	e9 02 01 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char ff3[100] = "fia w1 -1";
f01041c3:	8d 85 54 f7 ff ff    	lea    -0x8ac(%ebp),%eax
f01041c9:	bb 87 97 10 f0       	mov    $0xf0109787,%ebx
f01041ce:	ba 0a 00 00 00       	mov    $0xa,%edx
f01041d3:	89 c7                	mov    %eax,%edi
f01041d5:	89 de                	mov    %ebx,%esi
f01041d7:	89 d1                	mov    %edx,%ecx
f01041d9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f01041db:	8d 95 5e f7 ff ff    	lea    -0x8a2(%ebp),%edx
f01041e1:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f01041e6:	b0 00                	mov    $0x0,%al
f01041e8:	89 d7                	mov    %edx,%edi
f01041ea:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(ff3, WHITESPACE, args, &numOfArgs) ;
f01041ec:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f01041f2:	50                   	push   %eax
f01041f3:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f01041f9:	50                   	push   %eax
f01041fa:	68 d5 83 10 f0       	push   $0xf01083d5
f01041ff:	8d 85 54 f7 ff ff    	lea    -0x8ac(%ebp),%eax
f0104205:	50                   	push   %eax
f0104206:	e8 44 2e 00 00       	call   f010704f <strsplit>
f010420b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010420e:	83 ec 0c             	sub    $0xc,%esp
f0104211:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104217:	50                   	push   %eax
f0104218:	e8 e6 cf ff ff       	call   f0101203 <FindElementInArray>
f010421d:	83 c4 10             	add    $0x10,%esp
f0104220:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 0)
f0104223:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104227:	74 1a                	je     f0104243 <TestAss2BONUS+0xacd>
	{
		cprintf("[EVAL] #13 MergeTwoArrays: Failed\n");
f0104229:	83 ec 0c             	sub    $0xc,%esp
f010422c:	68 9c 90 10 f0       	push   $0xf010909c
f0104231:	e8 7e 14 00 00       	call   f01056b4 <cprintf>
f0104236:	83 c4 10             	add    $0x10,%esp
		return 1;
f0104239:	b8 01 00 00 00       	mov    $0x1,%eax
f010423e:	e9 82 00 00 00       	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	char ff4[100] = "fia m1 -1";
f0104243:	8d 85 f0 f6 ff ff    	lea    -0x910(%ebp),%eax
f0104249:	bb eb 97 10 f0       	mov    $0xf01097eb,%ebx
f010424e:	ba 0a 00 00 00       	mov    $0xa,%edx
f0104253:	89 c7                	mov    %eax,%edi
f0104255:	89 de                	mov    %ebx,%esi
f0104257:	89 d1                	mov    %edx,%ecx
f0104259:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
f010425b:	8d 95 fa f6 ff ff    	lea    -0x906(%ebp),%edx
f0104261:	b9 5a 00 00 00       	mov    $0x5a,%ecx
f0104266:	b0 00                	mov    $0x0,%al
f0104268:	89 d7                	mov    %edx,%edi
f010426a:	f3 aa                	rep stos %al,%es:(%edi)
	strsplit(ff4, WHITESPACE, args, &numOfArgs) ;
f010426c:	8d 85 64 ff ff ff    	lea    -0x9c(%ebp),%eax
f0104272:	50                   	push   %eax
f0104273:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104279:	50                   	push   %eax
f010427a:	68 d5 83 10 f0       	push   $0xf01083d5
f010427f:	8d 85 f0 f6 ff ff    	lea    -0x910(%ebp),%eax
f0104285:	50                   	push   %eax
f0104286:	e8 c4 2d 00 00       	call   f010704f <strsplit>
f010428b:	83 c4 10             	add    $0x10,%esp
	ret = FindElementInArray(args) ;
f010428e:	83 ec 0c             	sub    $0xc,%esp
f0104291:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
f0104297:	50                   	push   %eax
f0104298:	e8 66 cf ff ff       	call   f0101203 <FindElementInArray>
f010429d:	83 c4 10             	add    $0x10,%esp
f01042a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (ret != 0)
f01042a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01042a7:	74 17                	je     f01042c0 <TestAss2BONUS+0xb4a>
	{
		cprintf("[EVAL] #14 MergeTwoArrays: Failed\n");
f01042a9:	83 ec 0c             	sub    $0xc,%esp
f01042ac:	68 c0 90 10 f0       	push   $0xf01090c0
f01042b1:	e8 fe 13 00 00       	call   f01056b4 <cprintf>
f01042b6:	83 c4 10             	add    $0x10,%esp
		return 1;
f01042b9:	b8 01 00 00 00       	mov    $0x1,%eax
f01042be:	eb 05                	jmp    f01042c5 <TestAss2BONUS+0xb4f>
	}

	return 1;
f01042c0:	b8 01 00 00 00       	mov    $0x1,%eax
}
f01042c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01042c8:	5b                   	pop    %ebx
f01042c9:	5e                   	pop    %esi
f01042ca:	5f                   	pop    %edi
f01042cb:	5d                   	pop    %ebp
f01042cc:	c3                   	ret    

f01042cd <CheckArrays>:

//========================================================
int CheckArrays(int *expectedArr, int *actualArr, int N)
{
f01042cd:	55                   	push   %ebp
f01042ce:	89 e5                	mov    %esp,%ebp
f01042d0:	83 ec 10             	sub    $0x10,%esp

	int equal = 1 ;
f01042d3:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
	for(int i = 0; i < N; i++)
f01042da:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01042e1:	eb 30                	jmp    f0104313 <CheckArrays+0x46>
	{
		if(expectedArr[i] != actualArr[i])
f01042e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01042e6:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01042ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01042f0:	01 d0                	add    %edx,%eax
f01042f2:	8b 10                	mov    (%eax),%edx
f01042f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01042f7:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f01042fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104301:	01 c8                	add    %ecx,%eax
f0104303:	8b 00                	mov    (%eax),%eax
f0104305:	39 c2                	cmp    %eax,%edx
f0104307:	74 07                	je     f0104310 <CheckArrays+0x43>
			return 0;
f0104309:	b8 00 00 00 00       	mov    $0x0,%eax
f010430e:	eb 0e                	jmp    f010431e <CheckArrays+0x51>
//========================================================
int CheckArrays(int *expectedArr, int *actualArr, int N)
{

	int equal = 1 ;
	for(int i = 0; i < N; i++)
f0104310:	ff 45 fc             	incl   -0x4(%ebp)
f0104313:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104316:	3b 45 10             	cmp    0x10(%ebp),%eax
f0104319:	7c c8                	jl     f01042e3 <CheckArrays+0x16>
	{
		if(expectedArr[i] != actualArr[i])
			return 0;

	}
	return equal;
f010431b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f010431e:	c9                   	leave  
f010431f:	c3                   	ret    

f0104320 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0104320:	55                   	push   %ebp
f0104321:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0104323:	8b 45 08             	mov    0x8(%ebp),%eax
f0104326:	8b 15 c4 49 15 f0    	mov    0xf01549c4,%edx
f010432c:	29 d0                	sub    %edx,%eax
f010432e:	c1 f8 02             	sar    $0x2,%eax
f0104331:	89 c2                	mov    %eax,%edx
f0104333:	89 d0                	mov    %edx,%eax
f0104335:	c1 e0 02             	shl    $0x2,%eax
f0104338:	01 d0                	add    %edx,%eax
f010433a:	c1 e0 02             	shl    $0x2,%eax
f010433d:	01 d0                	add    %edx,%eax
f010433f:	c1 e0 02             	shl    $0x2,%eax
f0104342:	01 d0                	add    %edx,%eax
f0104344:	89 c1                	mov    %eax,%ecx
f0104346:	c1 e1 08             	shl    $0x8,%ecx
f0104349:	01 c8                	add    %ecx,%eax
f010434b:	89 c1                	mov    %eax,%ecx
f010434d:	c1 e1 10             	shl    $0x10,%ecx
f0104350:	01 c8                	add    %ecx,%eax
f0104352:	01 c0                	add    %eax,%eax
f0104354:	01 d0                	add    %edx,%eax
}
f0104356:	5d                   	pop    %ebp
f0104357:	c3                   	ret    

f0104358 <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0104358:	55                   	push   %ebp
f0104359:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f010435b:	ff 75 08             	pushl  0x8(%ebp)
f010435e:	e8 bd ff ff ff       	call   f0104320 <to_frame_number>
f0104363:	83 c4 04             	add    $0x4,%esp
f0104366:	c1 e0 0c             	shl    $0xc,%eax
}
f0104369:	c9                   	leave  
f010436a:	c3                   	ret    

f010436b <to_frame_info>:

static inline struct Frame_Info* to_frame_info(uint32 physical_address)
{
f010436b:	55                   	push   %ebp
f010436c:	89 e5                	mov    %esp,%ebp
f010436e:	83 ec 08             	sub    $0x8,%esp
	if (PPN(physical_address) >= number_of_frames)
f0104371:	8b 45 08             	mov    0x8(%ebp),%eax
f0104374:	c1 e8 0c             	shr    $0xc,%eax
f0104377:	89 c2                	mov    %eax,%edx
f0104379:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f010437e:	39 c2                	cmp    %eax,%edx
f0104380:	72 14                	jb     f0104396 <to_frame_info+0x2b>
		panic("to_frame_info called with invalid pa");
f0104382:	83 ec 04             	sub    $0x4,%esp
f0104385:	68 50 98 10 f0       	push   $0xf0109850
f010438a:	6a 39                	push   $0x39
f010438c:	68 75 98 10 f0       	push   $0xf0109875
f0104391:	e8 98 bd ff ff       	call   f010012e <_panic>
	return &frames_info[PPN(physical_address)];
f0104396:	8b 15 c4 49 15 f0    	mov    0xf01549c4,%edx
f010439c:	8b 45 08             	mov    0x8(%ebp),%eax
f010439f:	c1 e8 0c             	shr    $0xc,%eax
f01043a2:	89 c1                	mov    %eax,%ecx
f01043a4:	89 c8                	mov    %ecx,%eax
f01043a6:	01 c0                	add    %eax,%eax
f01043a8:	01 c8                	add    %ecx,%eax
f01043aa:	c1 e0 02             	shl    $0x2,%eax
f01043ad:	01 d0                	add    %edx,%eax
}
f01043af:	c9                   	leave  
f01043b0:	c3                   	ret    

f01043b1 <initialize_kernel_VM>:
//
// From USER_TOP to USER_LIMIT, the user is allowed to read but not write.
// Above USER_LIMIT the user cannot read (or write).

void initialize_kernel_VM()
{
f01043b1:	55                   	push   %ebp
f01043b2:	89 e5                	mov    %esp,%ebp
f01043b4:	83 ec 28             	sub    $0x28,%esp
	//panic("initialize_kernel_VM: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	ptr_page_directory = boot_allocate_space(PAGE_SIZE, PAGE_SIZE);
f01043b7:	83 ec 08             	sub    $0x8,%esp
f01043ba:	68 00 10 00 00       	push   $0x1000
f01043bf:	68 00 10 00 00       	push   $0x1000
f01043c4:	e8 ca 01 00 00       	call   f0104593 <boot_allocate_space>
f01043c9:	83 c4 10             	add    $0x10,%esp
f01043cc:	a3 cc 49 15 f0       	mov    %eax,0xf01549cc
	memset(ptr_page_directory, 0, PAGE_SIZE);
f01043d1:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01043d6:	83 ec 04             	sub    $0x4,%esp
f01043d9:	68 00 10 00 00       	push   $0x1000
f01043de:	6a 00                	push   $0x0
f01043e0:	50                   	push   %eax
f01043e1:	e8 b1 29 00 00       	call   f0106d97 <memset>
f01043e6:	83 c4 10             	add    $0x10,%esp
	phys_page_directory = K_PHYSICAL_ADDRESS(ptr_page_directory);
f01043e9:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01043ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01043f1:	81 7d f4 ff ff ff ef 	cmpl   $0xefffffff,-0xc(%ebp)
f01043f8:	77 14                	ja     f010440e <initialize_kernel_VM+0x5d>
f01043fa:	ff 75 f4             	pushl  -0xc(%ebp)
f01043fd:	68 90 98 10 f0       	push   $0xf0109890
f0104402:	6a 3c                	push   $0x3c
f0104404:	68 c1 98 10 f0       	push   $0xf01098c1
f0104409:	e8 20 bd ff ff       	call   f010012e <_panic>
f010440e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104411:	05 00 00 00 10       	add    $0x10000000,%eax
f0104416:	a3 d0 49 15 f0       	mov    %eax,0xf01549d0
	// Map the kernel stack with VA range :
	//  [KERNEL_STACK_TOP-KERNEL_STACK_SIZE, KERNEL_STACK_TOP), 
	// to physical address : "phys_stack_bottom".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_range(ptr_page_directory, KERNEL_STACK_TOP - KERNEL_STACK_SIZE, KERNEL_STACK_SIZE, K_PHYSICAL_ADDRESS(ptr_stack_bottom), PERM_WRITEABLE) ;
f010441b:	c7 45 f0 00 90 11 f0 	movl   $0xf0119000,-0x10(%ebp)
f0104422:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0104429:	77 14                	ja     f010443f <initialize_kernel_VM+0x8e>
f010442b:	ff 75 f0             	pushl  -0x10(%ebp)
f010442e:	68 90 98 10 f0       	push   $0xf0109890
f0104433:	6a 44                	push   $0x44
f0104435:	68 c1 98 10 f0       	push   $0xf01098c1
f010443a:	e8 ef bc ff ff       	call   f010012e <_panic>
f010443f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104442:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0104448:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f010444d:	83 ec 0c             	sub    $0xc,%esp
f0104450:	6a 02                	push   $0x2
f0104452:	52                   	push   %edx
f0104453:	68 00 80 00 00       	push   $0x8000
f0104458:	68 00 80 bf ef       	push   $0xefbf8000
f010445d:	50                   	push   %eax
f010445e:	e8 92 01 00 00       	call   f01045f5 <boot_map_range>
f0104463:	83 c4 20             	add    $0x20,%esp
	//      the PA range [0, 2^32 - KERNEL_BASE)
	// We might not have 2^32 - KERNEL_BASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_range(ptr_page_directory, KERNEL_BASE, 0xFFFFFFFF - KERNEL_BASE, 0, PERM_WRITEABLE) ;
f0104466:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f010446b:	83 ec 0c             	sub    $0xc,%esp
f010446e:	6a 02                	push   $0x2
f0104470:	6a 00                	push   $0x0
f0104472:	68 ff ff ff 0f       	push   $0xfffffff
f0104477:	68 00 00 00 f0       	push   $0xf0000000
f010447c:	50                   	push   %eax
f010447d:	e8 73 01 00 00       	call   f01045f5 <boot_map_range>
f0104482:	83 c4 20             	add    $0x20,%esp
	// Permissions:
	//    - frames_info -- kernel RW, user NONE
	//    - the image mapped at READ_ONLY_FRAMES_INFO  -- kernel R, user R
	// Your code goes here:
	uint32 array_size;
	array_size = number_of_frames * sizeof(struct Frame_Info) ;
f0104485:	8b 15 e8 47 15 f0    	mov    0xf01547e8,%edx
f010448b:	89 d0                	mov    %edx,%eax
f010448d:	01 c0                	add    %eax,%eax
f010448f:	01 d0                	add    %edx,%eax
f0104491:	c1 e0 02             	shl    $0x2,%eax
f0104494:	89 45 ec             	mov    %eax,-0x14(%ebp)
	frames_info = boot_allocate_space(array_size, PAGE_SIZE);
f0104497:	83 ec 08             	sub    $0x8,%esp
f010449a:	68 00 10 00 00       	push   $0x1000
f010449f:	ff 75 ec             	pushl  -0x14(%ebp)
f01044a2:	e8 ec 00 00 00       	call   f0104593 <boot_allocate_space>
f01044a7:	83 c4 10             	add    $0x10,%esp
f01044aa:	a3 c4 49 15 f0       	mov    %eax,0xf01549c4
	boot_map_range(ptr_page_directory, READ_ONLY_FRAMES_INFO, array_size, K_PHYSICAL_ADDRESS(frames_info), PERM_USER) ;
f01044af:	a1 c4 49 15 f0       	mov    0xf01549c4,%eax
f01044b4:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01044b7:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f01044be:	77 14                	ja     f01044d4 <initialize_kernel_VM+0x123>
f01044c0:	ff 75 e8             	pushl  -0x18(%ebp)
f01044c3:	68 90 98 10 f0       	push   $0xf0109890
f01044c8:	6a 5f                	push   $0x5f
f01044ca:	68 c1 98 10 f0       	push   $0xf01098c1
f01044cf:	e8 5a bc ff ff       	call   f010012e <_panic>
f01044d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01044d7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01044dd:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f01044e2:	83 ec 0c             	sub    $0xc,%esp
f01044e5:	6a 04                	push   $0x4
f01044e7:	52                   	push   %edx
f01044e8:	ff 75 ec             	pushl  -0x14(%ebp)
f01044eb:	68 00 00 00 ef       	push   $0xef000000
f01044f0:	50                   	push   %eax
f01044f1:	e8 ff 00 00 00       	call   f01045f5 <boot_map_range>
f01044f6:	83 c4 20             	add    $0x20,%esp


	// This allows the kernel & user to access any page table entry using a
	// specified VA for each: VPT for kernel and UVPT for User.
	setup_listing_to_all_page_tables_entries();
f01044f9:	e8 fa df ff ff       	call   f01024f8 <setup_listing_to_all_page_tables_entries>
	// Permissions:
	//    - envs itself -- kernel RW, user NONE
	//    - the image of envs mapped at UENVS  -- kernel R, user R

	// LAB 3: Your code here.
	int envs_size = NENV * sizeof(struct Env) ;
f01044fe:	c7 45 e4 00 90 01 00 	movl   $0x19000,-0x1c(%ebp)

	//allocate space for "envs" array aligned on 4KB boundary
	envs = boot_allocate_space(envs_size, PAGE_SIZE);
f0104505:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104508:	83 ec 08             	sub    $0x8,%esp
f010450b:	68 00 10 00 00       	push   $0x1000
f0104510:	50                   	push   %eax
f0104511:	e8 7d 00 00 00       	call   f0104593 <boot_allocate_space>
f0104516:	83 c4 10             	add    $0x10,%esp
f0104519:	a3 70 3f 15 f0       	mov    %eax,0xf0153f70

	//make the user to access this array by mapping it to UPAGES linear address (UPAGES is in User/Kernel space)
	boot_map_range(ptr_page_directory, UENVS, envs_size, K_PHYSICAL_ADDRESS(envs), PERM_USER) ;
f010451e:	a1 70 3f 15 f0       	mov    0xf0153f70,%eax
f0104523:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104526:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f010452d:	77 14                	ja     f0104543 <initialize_kernel_VM+0x192>
f010452f:	ff 75 e0             	pushl  -0x20(%ebp)
f0104532:	68 90 98 10 f0       	push   $0xf0109890
f0104537:	6a 75                	push   $0x75
f0104539:	68 c1 98 10 f0       	push   $0xf01098c1
f010453e:	e8 eb bb ff ff       	call   f010012e <_panic>
f0104543:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104546:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f010454c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010454f:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0104554:	83 ec 0c             	sub    $0xc,%esp
f0104557:	6a 04                	push   $0x4
f0104559:	51                   	push   %ecx
f010455a:	52                   	push   %edx
f010455b:	68 00 00 c0 ee       	push   $0xeec00000
f0104560:	50                   	push   %eax
f0104561:	e8 8f 00 00 00       	call   f01045f5 <boot_map_range>
f0104566:	83 c4 20             	add    $0x20,%esp

	//update permissions of the corresponding entry in page directory to make it USER with PERMISSION read only
	ptr_page_directory[PDX(UENVS)] = ptr_page_directory[PDX(UENVS)]|(PERM_USER|(PERM_PRESENT & (~PERM_WRITEABLE)));
f0104569:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f010456e:	05 ec 0e 00 00       	add    $0xeec,%eax
f0104573:	8b 15 cc 49 15 f0    	mov    0xf01549cc,%edx
f0104579:	81 c2 ec 0e 00 00    	add    $0xeec,%edx
f010457f:	8b 12                	mov    (%edx),%edx
f0104581:	83 ca 05             	or     $0x5,%edx
f0104584:	89 10                	mov    %edx,(%eax)


	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f0104586:	e8 67 d3 ff ff       	call   f01018f2 <check_boot_pgdir>

	// NOW: Turn off the segmentation by setting the segments' base to 0, and
	// turn on the paging by setting the corresponding flags in control register 0 (cr0)
	turn_on_paging() ;
f010458b:	e8 c9 de ff ff       	call   f0102459 <turn_on_paging>
}
f0104590:	90                   	nop
f0104591:	c9                   	leave  
f0104592:	c3                   	ret    

f0104593 <boot_allocate_space>:
// It's too early to run out of memory.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
// 
void* boot_allocate_space(uint32 size, uint32 align)
		{
f0104593:	55                   	push   %ebp
f0104594:	89 e5                	mov    %esp,%ebp
f0104596:	83 ec 10             	sub    $0x10,%esp
	// Initialize ptr_free_mem if this is the first time.
	// 'end_of_kernel' is a symbol automatically generated by the linker,
	// which points to the end of the kernel-
	// i.e., the first virtual address that the linker
	// did not assign to any kernel code or global variables.
	if (ptr_free_mem == 0)
f0104599:	a1 c8 49 15 f0       	mov    0xf01549c8,%eax
f010459e:	85 c0                	test   %eax,%eax
f01045a0:	75 0a                	jne    f01045ac <boot_allocate_space+0x19>
		ptr_free_mem = end_of_kernel;
f01045a2:	c7 05 c8 49 15 f0 d4 	movl   $0xf01549d4,0xf01549c8
f01045a9:	49 15 f0 

	// Your code here:
	//	Step 1: round ptr_free_mem up to be aligned properly
	ptr_free_mem = ROUNDUP(ptr_free_mem, PAGE_SIZE) ;
f01045ac:	c7 45 fc 00 10 00 00 	movl   $0x1000,-0x4(%ebp)
f01045b3:	a1 c8 49 15 f0       	mov    0xf01549c8,%eax
f01045b8:	89 c2                	mov    %eax,%edx
f01045ba:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01045bd:	01 d0                	add    %edx,%eax
f01045bf:	48                   	dec    %eax
f01045c0:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01045c3:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01045c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01045cb:	f7 75 fc             	divl   -0x4(%ebp)
f01045ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01045d1:	29 d0                	sub    %edx,%eax
f01045d3:	a3 c8 49 15 f0       	mov    %eax,0xf01549c8

	//	Step 2: save current value of ptr_free_mem as allocated space
	void *ptr_allocated_mem;
	ptr_allocated_mem = ptr_free_mem ;
f01045d8:	a1 c8 49 15 f0       	mov    0xf01549c8,%eax
f01045dd:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//	Step 3: increase ptr_free_mem to record allocation
	ptr_free_mem += size ;
f01045e0:	8b 15 c8 49 15 f0    	mov    0xf01549c8,%edx
f01045e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01045e9:	01 d0                	add    %edx,%eax
f01045eb:	a3 c8 49 15 f0       	mov    %eax,0xf01549c8

	//	Step 4: return allocated space
	return ptr_allocated_mem ;
f01045f0:	8b 45 f4             	mov    -0xc(%ebp),%eax

		}
f01045f3:	c9                   	leave  
f01045f4:	c3                   	ret    

f01045f5 <boot_map_range>:
//
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
f01045f5:	55                   	push   %ebp
f01045f6:	89 e5                	mov    %esp,%ebp
f01045f8:	83 ec 28             	sub    $0x28,%esp
	int i = 0 ;
f01045fb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
f0104602:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0104609:	8b 55 14             	mov    0x14(%ebp),%edx
f010460c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010460f:	01 d0                	add    %edx,%eax
f0104611:	48                   	dec    %eax
f0104612:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104615:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104618:	ba 00 00 00 00       	mov    $0x0,%edx
f010461d:	f7 75 f0             	divl   -0x10(%ebp)
f0104620:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104623:	29 d0                	sub    %edx,%eax
f0104625:	89 45 14             	mov    %eax,0x14(%ebp)
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f0104628:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010462f:	eb 53                	jmp    f0104684 <boot_map_range+0x8f>
	{
		uint32 *ptr_page_table = boot_get_page_table(ptr_page_directory, virtual_address, 1) ;
f0104631:	83 ec 04             	sub    $0x4,%esp
f0104634:	6a 01                	push   $0x1
f0104636:	ff 75 0c             	pushl  0xc(%ebp)
f0104639:	ff 75 08             	pushl  0x8(%ebp)
f010463c:	e8 4e 00 00 00       	call   f010468f <boot_get_page_table>
f0104641:	83 c4 10             	add    $0x10,%esp
f0104644:	89 45 e8             	mov    %eax,-0x18(%ebp)
		uint32 index_page_table = PTX(virtual_address);
f0104647:	8b 45 0c             	mov    0xc(%ebp),%eax
f010464a:	c1 e8 0c             	shr    $0xc,%eax
f010464d:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104652:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
f0104655:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104658:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010465f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104662:	01 c2                	add    %eax,%edx
f0104664:	8b 45 18             	mov    0x18(%ebp),%eax
f0104667:	0b 45 14             	or     0x14(%ebp),%eax
f010466a:	83 c8 01             	or     $0x1,%eax
f010466d:	89 02                	mov    %eax,(%edx)
		physical_address += PAGE_SIZE ;
f010466f:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
		virtual_address += PAGE_SIZE ;
f0104676:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
//
void boot_map_range(uint32 *ptr_page_directory, uint32 virtual_address, uint32 size, uint32 physical_address, int perm)
{
	int i = 0 ;
	physical_address = ROUNDUP(physical_address, PAGE_SIZE) ;
	for (i = 0 ; i < size ; i += PAGE_SIZE)
f010467d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
f0104684:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104687:	3b 45 10             	cmp    0x10(%ebp),%eax
f010468a:	72 a5                	jb     f0104631 <boot_map_range+0x3c>
		uint32 index_page_table = PTX(virtual_address);
		ptr_page_table[index_page_table] = CONSTRUCT_ENTRY(physical_address, perm | PERM_PRESENT) ;
		physical_address += PAGE_SIZE ;
		virtual_address += PAGE_SIZE ;
	}
}
f010468c:	90                   	nop
f010468d:	c9                   	leave  
f010468e:	c3                   	ret    

f010468f <boot_get_page_table>:
// boot_get_page_table cannot fail.  It's too early to fail.
// This function may ONLY be used during boot time,
// before the free_frame_list has been set up.
//
uint32* boot_get_page_table(uint32 *ptr_page_directory, uint32 virtual_address, int create)
		{
f010468f:	55                   	push   %ebp
f0104690:	89 e5                	mov    %esp,%ebp
f0104692:	83 ec 28             	sub    $0x28,%esp
	uint32 index_page_directory = PDX(virtual_address);
f0104695:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104698:	c1 e8 16             	shr    $0x16,%eax
f010469b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 page_directory_entry = ptr_page_directory[index_page_directory];
f010469e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01046a1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01046a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01046ab:	01 d0                	add    %edx,%eax
f01046ad:	8b 00                	mov    (%eax),%eax
f01046af:	89 45 f0             	mov    %eax,-0x10(%ebp)

	uint32 phys_page_table = EXTRACT_ADDRESS(page_directory_entry);
f01046b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01046b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01046ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32 *ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table);
f01046bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01046c0:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01046c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01046c6:	c1 e8 0c             	shr    $0xc,%eax
f01046c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046cc:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f01046d1:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01046d4:	72 17                	jb     f01046ed <boot_get_page_table+0x5e>
f01046d6:	ff 75 e8             	pushl  -0x18(%ebp)
f01046d9:	68 d8 98 10 f0       	push   $0xf01098d8
f01046de:	68 db 00 00 00       	push   $0xdb
f01046e3:	68 c1 98 10 f0       	push   $0xf01098c1
f01046e8:	e8 41 ba ff ff       	call   f010012e <_panic>
f01046ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01046f0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01046f5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if (phys_page_table == 0)
f01046f8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01046fc:	75 72                	jne    f0104770 <boot_get_page_table+0xe1>
	{
		if (create)
f01046fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104702:	74 65                	je     f0104769 <boot_get_page_table+0xda>
		{
			ptr_page_table = boot_allocate_space(PAGE_SIZE, PAGE_SIZE) ;
f0104704:	83 ec 08             	sub    $0x8,%esp
f0104707:	68 00 10 00 00       	push   $0x1000
f010470c:	68 00 10 00 00       	push   $0x1000
f0104711:	e8 7d fe ff ff       	call   f0104593 <boot_allocate_space>
f0104716:	83 c4 10             	add    $0x10,%esp
f0104719:	89 45 e0             	mov    %eax,-0x20(%ebp)
			phys_page_table = K_PHYSICAL_ADDRESS(ptr_page_table);
f010471c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010471f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104722:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
f0104729:	77 17                	ja     f0104742 <boot_get_page_table+0xb3>
f010472b:	ff 75 dc             	pushl  -0x24(%ebp)
f010472e:	68 90 98 10 f0       	push   $0xf0109890
f0104733:	68 e1 00 00 00       	push   $0xe1
f0104738:	68 c1 98 10 f0       	push   $0xf01098c1
f010473d:	e8 ec b9 ff ff       	call   f010012e <_panic>
f0104742:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104745:	05 00 00 00 10       	add    $0x10000000,%eax
f010474a:	89 45 ec             	mov    %eax,-0x14(%ebp)
			ptr_page_directory[index_page_directory] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_WRITEABLE);
f010474d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104750:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104757:	8b 45 08             	mov    0x8(%ebp),%eax
f010475a:	01 d0                	add    %edx,%eax
f010475c:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010475f:	83 ca 03             	or     $0x3,%edx
f0104762:	89 10                	mov    %edx,(%eax)
			return ptr_page_table ;
f0104764:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104767:	eb 0a                	jmp    f0104773 <boot_get_page_table+0xe4>
		}
		else
			return 0 ;
f0104769:	b8 00 00 00 00       	mov    $0x0,%eax
f010476e:	eb 03                	jmp    f0104773 <boot_get_page_table+0xe4>
	}
	return ptr_page_table ;
f0104770:	8b 45 e0             	mov    -0x20(%ebp),%eax
		}
f0104773:	c9                   	leave  
f0104774:	c3                   	ret    

f0104775 <initialize_paging>:
// After this point, ONLY use the functions below
// to allocate and deallocate physical memory via the free_frame_list,
// and NEVER use boot_allocate_space() or the related boot-time functions above.
//
void initialize_paging()
{
f0104775:	55                   	push   %ebp
f0104776:	89 e5                	mov    %esp,%ebp
f0104778:	53                   	push   %ebx
f0104779:	83 ec 24             	sub    $0x24,%esp
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which frames are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&free_frame_list);
f010477c:	c7 05 c0 49 15 f0 00 	movl   $0x0,0xf01549c0
f0104783:	00 00 00 

	frames_info[0].references = 1;
f0104786:	a1 c4 49 15 f0       	mov    0xf01549c4,%eax
f010478b:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);
f0104791:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f0104798:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010479b:	05 ff ff 09 00       	add    $0x9ffff,%eax
f01047a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01047a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01047a6:	ba 00 00 00 00       	mov    $0x0,%edx
f01047ab:	f7 75 f0             	divl   -0x10(%ebp)
f01047ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01047b1:	29 d0                	sub    %edx,%eax
f01047b3:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f01047b6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
f01047bd:	e9 90 00 00 00       	jmp    f0104852 <initialize_paging+0xdd>
	{
		frames_info[i].references = 0;
f01047c2:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f01047c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01047cb:	89 d0                	mov    %edx,%eax
f01047cd:	01 c0                	add    %eax,%eax
f01047cf:	01 d0                	add    %edx,%eax
f01047d1:	c1 e0 02             	shl    $0x2,%eax
f01047d4:	01 c8                	add    %ecx,%eax
f01047d6:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f01047dc:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f01047e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01047e5:	89 d0                	mov    %edx,%eax
f01047e7:	01 c0                	add    %eax,%eax
f01047e9:	01 d0                	add    %edx,%eax
f01047eb:	c1 e0 02             	shl    $0x2,%eax
f01047ee:	01 c8                	add    %ecx,%eax
f01047f0:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f01047f6:	89 10                	mov    %edx,(%eax)
f01047f8:	8b 00                	mov    (%eax),%eax
f01047fa:	85 c0                	test   %eax,%eax
f01047fc:	74 1d                	je     f010481b <initialize_paging+0xa6>
f01047fe:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f0104804:	8b 1d c4 49 15 f0    	mov    0xf01549c4,%ebx
f010480a:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f010480d:	89 c8                	mov    %ecx,%eax
f010480f:	01 c0                	add    %eax,%eax
f0104811:	01 c8                	add    %ecx,%eax
f0104813:	c1 e0 02             	shl    $0x2,%eax
f0104816:	01 d8                	add    %ebx,%eax
f0104818:	89 42 04             	mov    %eax,0x4(%edx)
f010481b:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f0104821:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104824:	89 d0                	mov    %edx,%eax
f0104826:	01 c0                	add    %eax,%eax
f0104828:	01 d0                	add    %edx,%eax
f010482a:	c1 e0 02             	shl    $0x2,%eax
f010482d:	01 c8                	add    %ecx,%eax
f010482f:	a3 c0 49 15 f0       	mov    %eax,0xf01549c0
f0104834:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f010483a:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010483d:	89 d0                	mov    %edx,%eax
f010483f:	01 c0                	add    %eax,%eax
f0104841:	01 d0                	add    %edx,%eax
f0104843:	c1 e0 02             	shl    $0x2,%eax
f0104846:	01 c8                	add    %ecx,%eax
f0104848:	c7 40 04 c0 49 15 f0 	movl   $0xf01549c0,0x4(%eax)

	frames_info[0].references = 1;

	int range_end = ROUNDUP(PHYS_IO_MEM,PAGE_SIZE);

	for (i = 1; i < range_end/PAGE_SIZE; i++)
f010484f:	ff 45 f4             	incl   -0xc(%ebp)
f0104852:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104855:	85 c0                	test   %eax,%eax
f0104857:	79 05                	jns    f010485e <initialize_paging+0xe9>
f0104859:	05 ff 0f 00 00       	add    $0xfff,%eax
f010485e:	c1 f8 0c             	sar    $0xc,%eax
f0104861:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0104864:	0f 8f 58 ff ff ff    	jg     f01047c2 <initialize_paging+0x4d>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f010486a:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
f0104871:	eb 1d                	jmp    f0104890 <initialize_paging+0x11b>
	{
		frames_info[i].references = 1;
f0104873:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f0104879:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010487c:	89 d0                	mov    %edx,%eax
f010487e:	01 c0                	add    %eax,%eax
f0104880:	01 d0                	add    %edx,%eax
f0104882:	c1 e0 02             	shl    $0x2,%eax
f0104885:	01 c8                	add    %ecx,%eax
f0104887:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}

	for (i = PHYS_IO_MEM/PAGE_SIZE ; i < PHYS_EXTENDED_MEM/PAGE_SIZE; i++)
f010488d:	ff 45 f4             	incl   -0xc(%ebp)
f0104890:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
f0104897:	7e da                	jle    f0104873 <initialize_paging+0xfe>
	{
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);
f0104899:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
f01048a0:	a1 c8 49 15 f0       	mov    0xf01549c8,%eax
f01048a5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01048a8:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f01048af:	77 17                	ja     f01048c8 <initialize_paging+0x153>
f01048b1:	ff 75 e0             	pushl  -0x20(%ebp)
f01048b4:	68 90 98 10 f0       	push   $0xf0109890
f01048b9:	68 1e 01 00 00       	push   $0x11e
f01048be:	68 c1 98 10 f0       	push   $0xf01098c1
f01048c3:	e8 66 b8 ff ff       	call   f010012e <_panic>
f01048c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048cb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01048d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048d4:	01 d0                	add    %edx,%eax
f01048d6:	48                   	dec    %eax
f01048d7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01048da:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01048dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01048e2:	f7 75 e4             	divl   -0x1c(%ebp)
f01048e5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01048e8:	29 d0                	sub    %edx,%eax
f01048ea:	89 45 e8             	mov    %eax,-0x18(%ebp)

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f01048ed:	c7 45 f4 00 01 00 00 	movl   $0x100,-0xc(%ebp)
f01048f4:	eb 1d                	jmp    f0104913 <initialize_paging+0x19e>
	{
		frames_info[i].references = 1;
f01048f6:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f01048fc:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01048ff:	89 d0                	mov    %edx,%eax
f0104901:	01 c0                	add    %eax,%eax
f0104903:	01 d0                	add    %edx,%eax
f0104905:	c1 e0 02             	shl    $0x2,%eax
f0104908:	01 c8                	add    %ecx,%eax
f010490a:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
		frames_info[i].references = 1;
	}

	range_end = ROUNDUP(K_PHYSICAL_ADDRESS(ptr_free_mem), PAGE_SIZE);

	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
f0104910:	ff 45 f4             	incl   -0xc(%ebp)
f0104913:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104916:	85 c0                	test   %eax,%eax
f0104918:	79 05                	jns    f010491f <initialize_paging+0x1aa>
f010491a:	05 ff 0f 00 00       	add    $0xfff,%eax
f010491f:	c1 f8 0c             	sar    $0xc,%eax
f0104922:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0104925:	7f cf                	jg     f01048f6 <initialize_paging+0x181>
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f0104927:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010492a:	85 c0                	test   %eax,%eax
f010492c:	79 05                	jns    f0104933 <initialize_paging+0x1be>
f010492e:	05 ff 0f 00 00       	add    $0xfff,%eax
f0104933:	c1 f8 0c             	sar    $0xc,%eax
f0104936:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104939:	e9 90 00 00 00       	jmp    f01049ce <initialize_paging+0x259>
	{
		frames_info[i].references = 0;
f010493e:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f0104944:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104947:	89 d0                	mov    %edx,%eax
f0104949:	01 c0                	add    %eax,%eax
f010494b:	01 d0                	add    %edx,%eax
f010494d:	c1 e0 02             	shl    $0x2,%eax
f0104950:	01 c8                	add    %ecx,%eax
f0104952:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
f0104958:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f010495e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104961:	89 d0                	mov    %edx,%eax
f0104963:	01 c0                	add    %eax,%eax
f0104965:	01 d0                	add    %edx,%eax
f0104967:	c1 e0 02             	shl    $0x2,%eax
f010496a:	01 c8                	add    %ecx,%eax
f010496c:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f0104972:	89 10                	mov    %edx,(%eax)
f0104974:	8b 00                	mov    (%eax),%eax
f0104976:	85 c0                	test   %eax,%eax
f0104978:	74 1d                	je     f0104997 <initialize_paging+0x222>
f010497a:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f0104980:	8b 1d c4 49 15 f0    	mov    0xf01549c4,%ebx
f0104986:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0104989:	89 c8                	mov    %ecx,%eax
f010498b:	01 c0                	add    %eax,%eax
f010498d:	01 c8                	add    %ecx,%eax
f010498f:	c1 e0 02             	shl    $0x2,%eax
f0104992:	01 d8                	add    %ebx,%eax
f0104994:	89 42 04             	mov    %eax,0x4(%edx)
f0104997:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f010499d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01049a0:	89 d0                	mov    %edx,%eax
f01049a2:	01 c0                	add    %eax,%eax
f01049a4:	01 d0                	add    %edx,%eax
f01049a6:	c1 e0 02             	shl    $0x2,%eax
f01049a9:	01 c8                	add    %ecx,%eax
f01049ab:	a3 c0 49 15 f0       	mov    %eax,0xf01549c0
f01049b0:	8b 0d c4 49 15 f0    	mov    0xf01549c4,%ecx
f01049b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01049b9:	89 d0                	mov    %edx,%eax
f01049bb:	01 c0                	add    %eax,%eax
f01049bd:	01 d0                	add    %edx,%eax
f01049bf:	c1 e0 02             	shl    $0x2,%eax
f01049c2:	01 c8                	add    %ecx,%eax
f01049c4:	c7 40 04 c0 49 15 f0 	movl   $0xf01549c0,0x4(%eax)
	for (i = PHYS_EXTENDED_MEM/PAGE_SIZE ; i < range_end/PAGE_SIZE; i++)
	{
		frames_info[i].references = 1;
	}

	for (i = range_end/PAGE_SIZE ; i < number_of_frames; i++)
f01049cb:	ff 45 f4             	incl   -0xc(%ebp)
f01049ce:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01049d1:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f01049d6:	39 c2                	cmp    %eax,%edx
f01049d8:	0f 82 60 ff ff ff    	jb     f010493e <initialize_paging+0x1c9>
	{
		frames_info[i].references = 0;
		LIST_INSERT_HEAD(&free_frame_list, &frames_info[i]);
	}
}
f01049de:	90                   	nop
f01049df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01049e2:	c9                   	leave  
f01049e3:	c3                   	ret    

f01049e4 <initialize_frame_info>:
// Initialize a Frame_Info structure.
// The result has null links and 0 references.
// Note that the corresponding physical frame is NOT initialized!
//
void initialize_frame_info(struct Frame_Info *ptr_frame_info)
{
f01049e4:	55                   	push   %ebp
f01049e5:	89 e5                	mov    %esp,%ebp
f01049e7:	83 ec 08             	sub    $0x8,%esp
	memset(ptr_frame_info, 0, sizeof(*ptr_frame_info));
f01049ea:	83 ec 04             	sub    $0x4,%esp
f01049ed:	6a 0c                	push   $0xc
f01049ef:	6a 00                	push   $0x0
f01049f1:	ff 75 08             	pushl  0x8(%ebp)
f01049f4:	e8 9e 23 00 00       	call   f0106d97 <memset>
f01049f9:	83 c4 10             	add    $0x10,%esp
}
f01049fc:	90                   	nop
f01049fd:	c9                   	leave  
f01049fe:	c3                   	ret    

f01049ff <allocate_frame>:
//   E_NO_MEM -- otherwise
//
// Hint: use LIST_FIRST, LIST_REMOVE, and initialize_frame_info
// Hint: references should not be incremented
int allocate_frame(struct Frame_Info **ptr_frame_info)
{
f01049ff:	55                   	push   %ebp
f0104a00:	89 e5                	mov    %esp,%ebp
f0104a02:	83 ec 08             	sub    $0x8,%esp
	// Fill this function in	
	*ptr_frame_info = LIST_FIRST(&free_frame_list);
f0104a05:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f0104a0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a0e:	89 10                	mov    %edx,(%eax)
	if(*ptr_frame_info == NULL)
f0104a10:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a13:	8b 00                	mov    (%eax),%eax
f0104a15:	85 c0                	test   %eax,%eax
f0104a17:	75 07                	jne    f0104a20 <allocate_frame+0x21>
		return E_NO_MEM;
f0104a19:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104a1e:	eb 44                	jmp    f0104a64 <allocate_frame+0x65>

	LIST_REMOVE(*ptr_frame_info);
f0104a20:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a23:	8b 00                	mov    (%eax),%eax
f0104a25:	8b 00                	mov    (%eax),%eax
f0104a27:	85 c0                	test   %eax,%eax
f0104a29:	74 12                	je     f0104a3d <allocate_frame+0x3e>
f0104a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2e:	8b 00                	mov    (%eax),%eax
f0104a30:	8b 00                	mov    (%eax),%eax
f0104a32:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a35:	8b 12                	mov    (%edx),%edx
f0104a37:	8b 52 04             	mov    0x4(%edx),%edx
f0104a3a:	89 50 04             	mov    %edx,0x4(%eax)
f0104a3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a40:	8b 00                	mov    (%eax),%eax
f0104a42:	8b 40 04             	mov    0x4(%eax),%eax
f0104a45:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a48:	8b 12                	mov    (%edx),%edx
f0104a4a:	8b 12                	mov    (%edx),%edx
f0104a4c:	89 10                	mov    %edx,(%eax)
	initialize_frame_info(*ptr_frame_info);
f0104a4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a51:	8b 00                	mov    (%eax),%eax
f0104a53:	83 ec 0c             	sub    $0xc,%esp
f0104a56:	50                   	push   %eax
f0104a57:	e8 88 ff ff ff       	call   f01049e4 <initialize_frame_info>
f0104a5c:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104a5f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a64:	c9                   	leave  
f0104a65:	c3                   	ret    

f0104a66 <free_frame>:
//
// Return a frame to the free_frame_list.
// (This function should only be called when ptr_frame_info->references reaches 0.)
//
void free_frame(struct Frame_Info *ptr_frame_info)
{
f0104a66:	55                   	push   %ebp
f0104a67:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	LIST_INSERT_HEAD(&free_frame_list, ptr_frame_info);
f0104a69:	8b 15 c0 49 15 f0    	mov    0xf01549c0,%edx
f0104a6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a72:	89 10                	mov    %edx,(%eax)
f0104a74:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a77:	8b 00                	mov    (%eax),%eax
f0104a79:	85 c0                	test   %eax,%eax
f0104a7b:	74 0b                	je     f0104a88 <free_frame+0x22>
f0104a7d:	a1 c0 49 15 f0       	mov    0xf01549c0,%eax
f0104a82:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a85:	89 50 04             	mov    %edx,0x4(%eax)
f0104a88:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a8b:	a3 c0 49 15 f0       	mov    %eax,0xf01549c0
f0104a90:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a93:	c7 40 04 c0 49 15 f0 	movl   $0xf01549c0,0x4(%eax)
}
f0104a9a:	90                   	nop
f0104a9b:	5d                   	pop    %ebp
f0104a9c:	c3                   	ret    

f0104a9d <decrement_references>:
//
// Decrement the reference count on a frame
// freeing it if there are no more references.
//
void decrement_references(struct Frame_Info* ptr_frame_info)
{
f0104a9d:	55                   	push   %ebp
f0104a9e:	89 e5                	mov    %esp,%ebp
	if (--(ptr_frame_info->references) == 0)
f0104aa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104aa3:	8b 40 08             	mov    0x8(%eax),%eax
f0104aa6:	48                   	dec    %eax
f0104aa7:	8b 55 08             	mov    0x8(%ebp),%edx
f0104aaa:	66 89 42 08          	mov    %ax,0x8(%edx)
f0104aae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab1:	8b 40 08             	mov    0x8(%eax),%eax
f0104ab4:	66 85 c0             	test   %ax,%ax
f0104ab7:	75 0b                	jne    f0104ac4 <decrement_references+0x27>
		free_frame(ptr_frame_info);
f0104ab9:	ff 75 08             	pushl  0x8(%ebp)
f0104abc:	e8 a5 ff ff ff       	call   f0104a66 <free_frame>
f0104ac1:	83 c4 04             	add    $0x4,%esp
}
f0104ac4:	90                   	nop
f0104ac5:	c9                   	leave  
f0104ac6:	c3                   	ret    

f0104ac7 <get_page_table>:
//
// Hint: you can use "to_physical_address()" to turn a Frame_Info*
// into the physical address of the frame it refers to. 

int get_page_table(uint32 *ptr_page_directory, const void *virtual_address, int create, uint32 **ptr_page_table)
{
f0104ac7:	55                   	push   %ebp
f0104ac8:	89 e5                	mov    %esp,%ebp
f0104aca:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	uint32 page_directory_entry = ptr_page_directory[PDX(virtual_address)];
f0104acd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ad0:	c1 e8 16             	shr    $0x16,%eax
f0104ad3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104ada:	8b 45 08             	mov    0x8(%ebp),%eax
f0104add:	01 d0                	add    %edx,%eax
f0104adf:	8b 00                	mov    (%eax),%eax
f0104ae1:	89 45 f4             	mov    %eax,-0xc(%ebp)

	*ptr_page_table = K_VIRTUAL_ADDRESS(EXTRACT_ADDRESS(page_directory_entry)) ;
f0104ae4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104ae7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104aec:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104aef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104af2:	c1 e8 0c             	shr    $0xc,%eax
f0104af5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104af8:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f0104afd:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f0104b00:	72 17                	jb     f0104b19 <get_page_table+0x52>
f0104b02:	ff 75 f0             	pushl  -0x10(%ebp)
f0104b05:	68 d8 98 10 f0       	push   $0xf01098d8
f0104b0a:	68 79 01 00 00       	push   $0x179
f0104b0f:	68 c1 98 10 f0       	push   $0xf01098c1
f0104b14:	e8 15 b6 ff ff       	call   f010012e <_panic>
f0104b19:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104b1c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0104b21:	89 c2                	mov    %eax,%edx
f0104b23:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b26:	89 10                	mov    %edx,(%eax)

	if (page_directory_entry == 0)
f0104b28:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104b2c:	0f 85 d3 00 00 00    	jne    f0104c05 <get_page_table+0x13e>
	{
		if (create)
f0104b32:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0104b36:	0f 84 b9 00 00 00    	je     f0104bf5 <get_page_table+0x12e>
		{
			struct Frame_Info* ptr_frame_info;
			int err = allocate_frame(&ptr_frame_info) ;
f0104b3c:	83 ec 0c             	sub    $0xc,%esp
f0104b3f:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0104b42:	50                   	push   %eax
f0104b43:	e8 b7 fe ff ff       	call   f01049ff <allocate_frame>
f0104b48:	83 c4 10             	add    $0x10,%esp
f0104b4b:	89 45 e8             	mov    %eax,-0x18(%ebp)
			if(err == E_NO_MEM)
f0104b4e:	83 7d e8 fc          	cmpl   $0xfffffffc,-0x18(%ebp)
f0104b52:	75 13                	jne    f0104b67 <get_page_table+0xa0>
			{
				*ptr_page_table = 0;
f0104b54:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				return E_NO_MEM;
f0104b5d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104b62:	e9 a3 00 00 00       	jmp    f0104c0a <get_page_table+0x143>
			}

			uint32 phys_page_table = to_physical_address(ptr_frame_info);
f0104b67:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104b6a:	83 ec 0c             	sub    $0xc,%esp
f0104b6d:	50                   	push   %eax
f0104b6e:	e8 e5 f7 ff ff       	call   f0104358 <to_physical_address>
f0104b73:	83 c4 10             	add    $0x10,%esp
f0104b76:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			*ptr_page_table = K_VIRTUAL_ADDRESS(phys_page_table) ;
f0104b79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b7c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b82:	c1 e8 0c             	shr    $0xc,%eax
f0104b85:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104b88:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f0104b8d:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f0104b90:	72 17                	jb     f0104ba9 <get_page_table+0xe2>
f0104b92:	ff 75 e0             	pushl  -0x20(%ebp)
f0104b95:	68 d8 98 10 f0       	push   $0xf01098d8
f0104b9a:	68 88 01 00 00       	push   $0x188
f0104b9f:	68 c1 98 10 f0       	push   $0xf01098c1
f0104ba4:	e8 85 b5 ff ff       	call   f010012e <_panic>
f0104ba9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104bac:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0104bb1:	89 c2                	mov    %eax,%edx
f0104bb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bb6:	89 10                	mov    %edx,(%eax)

			//initialize new page table by 0's
			memset(*ptr_page_table , 0, PAGE_SIZE);
f0104bb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bbb:	8b 00                	mov    (%eax),%eax
f0104bbd:	83 ec 04             	sub    $0x4,%esp
f0104bc0:	68 00 10 00 00       	push   $0x1000
f0104bc5:	6a 00                	push   $0x0
f0104bc7:	50                   	push   %eax
f0104bc8:	e8 ca 21 00 00       	call   f0106d97 <memset>
f0104bcd:	83 c4 10             	add    $0x10,%esp

			ptr_frame_info->references = 1;
f0104bd0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104bd3:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
			ptr_page_directory[PDX(virtual_address)] = CONSTRUCT_ENTRY(phys_page_table, PERM_PRESENT | PERM_USER | PERM_WRITEABLE);
f0104bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bdc:	c1 e8 16             	shr    $0x16,%eax
f0104bdf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104be6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104be9:	01 d0                	add    %edx,%eax
f0104beb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104bee:	83 ca 07             	or     $0x7,%edx
f0104bf1:	89 10                	mov    %edx,(%eax)
f0104bf3:	eb 10                	jmp    f0104c05 <get_page_table+0x13e>
		}
		else
		{
			*ptr_page_table = 0;
f0104bf5:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bf8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return 0;
f0104bfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c03:	eb 05                	jmp    f0104c0a <get_page_table+0x143>
		}
	}	
	return 0;
f0104c05:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c0a:	c9                   	leave  
f0104c0b:	c3                   	ret    

f0104c0c <map_frame>:
//   E_NO_MEM, if page table couldn't be allocated
//
// Hint: implement using get_page_table() and unmap_frame().
//
int map_frame(uint32 *ptr_page_directory, struct Frame_Info *ptr_frame_info, void *virtual_address, int perm)
{
f0104c0c:	55                   	push   %ebp
f0104c0d:	89 e5                	mov    %esp,%ebp
f0104c0f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 physical_address = to_physical_address(ptr_frame_info);
f0104c12:	ff 75 0c             	pushl  0xc(%ebp)
f0104c15:	e8 3e f7 ff ff       	call   f0104358 <to_physical_address>
f0104c1a:	83 c4 04             	add    $0x4,%esp
f0104c1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32 *ptr_page_table;
	if( get_page_table(ptr_page_directory, virtual_address, 1, &ptr_page_table) == 0)
f0104c20:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104c23:	50                   	push   %eax
f0104c24:	6a 01                	push   $0x1
f0104c26:	ff 75 10             	pushl  0x10(%ebp)
f0104c29:	ff 75 08             	pushl  0x8(%ebp)
f0104c2c:	e8 96 fe ff ff       	call   f0104ac7 <get_page_table>
f0104c31:	83 c4 10             	add    $0x10,%esp
f0104c34:	85 c0                	test   %eax,%eax
f0104c36:	75 7c                	jne    f0104cb4 <map_frame+0xa8>
	{
		uint32 page_table_entry = ptr_page_table[PTX(virtual_address)];
f0104c38:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104c3b:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c3e:	c1 ea 0c             	shr    $0xc,%edx
f0104c41:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104c47:	c1 e2 02             	shl    $0x2,%edx
f0104c4a:	01 d0                	add    %edx,%eax
f0104c4c:	8b 00                	mov    (%eax),%eax
f0104c4e:	89 45 f0             	mov    %eax,-0x10(%ebp)

		//If already mapped
		if ((page_table_entry & PERM_PRESENT) == PERM_PRESENT)
f0104c51:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104c54:	83 e0 01             	and    $0x1,%eax
f0104c57:	85 c0                	test   %eax,%eax
f0104c59:	74 25                	je     f0104c80 <map_frame+0x74>
		{
			//on this pa, then do nothing
			if (EXTRACT_ADDRESS(page_table_entry) == physical_address)
f0104c5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104c5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104c63:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0104c66:	75 07                	jne    f0104c6f <map_frame+0x63>
				return 0;
f0104c68:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c6d:	eb 4a                	jmp    f0104cb9 <map_frame+0xad>
			//on another pa, then unmap it
			else
				unmap_frame(ptr_page_directory , virtual_address);
f0104c6f:	83 ec 08             	sub    $0x8,%esp
f0104c72:	ff 75 10             	pushl  0x10(%ebp)
f0104c75:	ff 75 08             	pushl  0x8(%ebp)
f0104c78:	e8 ad 00 00 00       	call   f0104d2a <unmap_frame>
f0104c7d:	83 c4 10             	add    $0x10,%esp
		}
		ptr_frame_info->references++;
f0104c80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c83:	8b 40 08             	mov    0x8(%eax),%eax
f0104c86:	40                   	inc    %eax
f0104c87:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c8a:	66 89 42 08          	mov    %ax,0x8(%edx)
		ptr_page_table[PTX(virtual_address)] = CONSTRUCT_ENTRY(physical_address , perm | PERM_PRESENT);
f0104c8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104c91:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c94:	c1 ea 0c             	shr    $0xc,%edx
f0104c97:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104c9d:	c1 e2 02             	shl    $0x2,%edx
f0104ca0:	01 c2                	add    %eax,%edx
f0104ca2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ca5:	0b 45 f4             	or     -0xc(%ebp),%eax
f0104ca8:	83 c8 01             	or     $0x1,%eax
f0104cab:	89 02                	mov    %eax,(%edx)

		return 0;
f0104cad:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cb2:	eb 05                	jmp    f0104cb9 <map_frame+0xad>
	}	
	return E_NO_MEM;
f0104cb4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0104cb9:	c9                   	leave  
f0104cba:	c3                   	ret    

f0104cbb <get_frame_info>:
// Return 0 if there is no frame mapped at virtual_address.
//
// Hint: implement using get_page_table() and get_frame_info().
//
struct Frame_Info * get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table)
		{
f0104cbb:	55                   	push   %ebp
f0104cbc:	89 e5                	mov    %esp,%ebp
f0104cbe:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in	
	uint32 ret =  get_page_table(ptr_page_directory, virtual_address, 0, ptr_page_table) ;
f0104cc1:	ff 75 10             	pushl  0x10(%ebp)
f0104cc4:	6a 00                	push   $0x0
f0104cc6:	ff 75 0c             	pushl  0xc(%ebp)
f0104cc9:	ff 75 08             	pushl  0x8(%ebp)
f0104ccc:	e8 f6 fd ff ff       	call   f0104ac7 <get_page_table>
f0104cd1:	83 c4 10             	add    $0x10,%esp
f0104cd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*ptr_page_table) != 0)
f0104cd7:	8b 45 10             	mov    0x10(%ebp),%eax
f0104cda:	8b 00                	mov    (%eax),%eax
f0104cdc:	85 c0                	test   %eax,%eax
f0104cde:	74 43                	je     f0104d23 <get_frame_info+0x68>
	{	
		uint32 index_page_table = PTX(virtual_address);
f0104ce0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ce3:	c1 e8 0c             	shr    $0xc,%eax
f0104ce6:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)
		uint32 page_table_entry = (*ptr_page_table)[index_page_table];
f0104cee:	8b 45 10             	mov    0x10(%ebp),%eax
f0104cf1:	8b 00                	mov    (%eax),%eax
f0104cf3:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0104cf6:	c1 e2 02             	shl    $0x2,%edx
f0104cf9:	01 d0                	add    %edx,%eax
f0104cfb:	8b 00                	mov    (%eax),%eax
f0104cfd:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if( page_table_entry != 0)	
f0104d00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0104d04:	74 16                	je     f0104d1c <get_frame_info+0x61>
			return to_frame_info( EXTRACT_ADDRESS ( page_table_entry ) );
f0104d06:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104d09:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104d0e:	83 ec 0c             	sub    $0xc,%esp
f0104d11:	50                   	push   %eax
f0104d12:	e8 54 f6 ff ff       	call   f010436b <to_frame_info>
f0104d17:	83 c4 10             	add    $0x10,%esp
f0104d1a:	eb 0c                	jmp    f0104d28 <get_frame_info+0x6d>
		return 0;
f0104d1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d21:	eb 05                	jmp    f0104d28 <get_frame_info+0x6d>
	}
	return 0;
f0104d23:	b8 00 00 00 00       	mov    $0x0,%eax
		}
f0104d28:	c9                   	leave  
f0104d29:	c3                   	ret    

f0104d2a <unmap_frame>:
//
// Hint: implement using get_frame_info(),
// 	tlb_invalidate(), and decrement_references().
//
void unmap_frame(uint32 *ptr_page_directory, void *virtual_address)
{
f0104d2a:	55                   	push   %ebp
f0104d2b:	89 e5                	mov    %esp,%ebp
f0104d2d:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	uint32 *ptr_page_table;
	struct Frame_Info* ptr_frame_info = get_frame_info(ptr_page_directory, virtual_address, &ptr_page_table);
f0104d30:	83 ec 04             	sub    $0x4,%esp
f0104d33:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0104d36:	50                   	push   %eax
f0104d37:	ff 75 0c             	pushl  0xc(%ebp)
f0104d3a:	ff 75 08             	pushl  0x8(%ebp)
f0104d3d:	e8 79 ff ff ff       	call   f0104cbb <get_frame_info>
f0104d42:	83 c4 10             	add    $0x10,%esp
f0104d45:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if( ptr_frame_info != 0 )
f0104d48:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0104d4c:	74 39                	je     f0104d87 <unmap_frame+0x5d>
	{
		decrement_references(ptr_frame_info);
f0104d4e:	83 ec 0c             	sub    $0xc,%esp
f0104d51:	ff 75 f4             	pushl  -0xc(%ebp)
f0104d54:	e8 44 fd ff ff       	call   f0104a9d <decrement_references>
f0104d59:	83 c4 10             	add    $0x10,%esp
		ptr_page_table[PTX(virtual_address)] = 0;
f0104d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104d5f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d62:	c1 ea 0c             	shr    $0xc,%edx
f0104d65:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104d6b:	c1 e2 02             	shl    $0x2,%edx
f0104d6e:	01 d0                	add    %edx,%eax
f0104d70:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(ptr_page_directory, virtual_address);
f0104d76:	83 ec 08             	sub    $0x8,%esp
f0104d79:	ff 75 0c             	pushl  0xc(%ebp)
f0104d7c:	ff 75 08             	pushl  0x8(%ebp)
f0104d7f:	e8 6e ce ff ff       	call   f0101bf2 <tlb_invalidate>
f0104d84:	83 c4 10             	add    $0x10,%esp
	}	
}
f0104d87:	90                   	nop
f0104d88:	c9                   	leave  
f0104d89:	c3                   	ret    

f0104d8a <get_page>:
//		or to allocate any necessary page tables.
// 	HINT: 	remember to free the allocated frame if there is no space 
//		for the necessary page tables

int get_page(uint32* ptr_page_directory, void *virtual_address, int perm)
{
f0104d8a:	55                   	push   %ebp
f0104d8b:	89 e5                	mov    %esp,%ebp
f0104d8d:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("get_page function is not completed yet") ;
f0104d90:	83 ec 04             	sub    $0x4,%esp
f0104d93:	68 08 99 10 f0       	push   $0xf0109908
f0104d98:	68 14 02 00 00       	push   $0x214
f0104d9d:	68 c1 98 10 f0       	push   $0xf01098c1
f0104da2:	e8 87 b3 ff ff       	call   f010012e <_panic>

f0104da7 <calculate_required_frames>:
	return 0 ;
}

//[2] calculate_required_frames: 
uint32 calculate_required_frames(uint32* ptr_page_directory, uint32 start_virtual_address, uint32 size)
{
f0104da7:	55                   	push   %ebp
f0104da8:	89 e5                	mov    %esp,%ebp
f0104daa:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("calculate_required_frames function is not completed yet") ;
f0104dad:	83 ec 04             	sub    $0x4,%esp
f0104db0:	68 30 99 10 f0       	push   $0xf0109930
f0104db5:	68 2b 02 00 00       	push   $0x22b
f0104dba:	68 c1 98 10 f0       	push   $0xf01098c1
f0104dbf:	e8 6a b3 ff ff       	call   f010012e <_panic>

f0104dc4 <calculate_free_frames>:


//[3] calculate_free_frames:

uint32 calculate_free_frames()
{
f0104dc4:	55                   	push   %ebp
f0104dc5:	89 e5                	mov    %esp,%ebp
f0104dc7:	83 ec 10             	sub    $0x10,%esp
	// PROJECT 2008: Your code here.
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
f0104dca:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	LIST_FOREACH(ptr, &free_frame_list)
f0104dd1:	a1 c0 49 15 f0       	mov    0xf01549c0,%eax
f0104dd6:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0104dd9:	eb 0b                	jmp    f0104de6 <calculate_free_frames+0x22>
	{
		cnt++ ;
f0104ddb:	ff 45 f8             	incl   -0x8(%ebp)
	//panic("calculate_free_frames function is not completed yet") ;

	//calculate the free frames from the free frame list
	struct Frame_Info *ptr;
	uint32 cnt = 0 ; 
	LIST_FOREACH(ptr, &free_frame_list)
f0104dde:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0104de1:	8b 00                	mov    (%eax),%eax
f0104de3:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0104de6:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0104dea:	75 ef                	jne    f0104ddb <calculate_free_frames+0x17>
	{
		cnt++ ;
	}
	return cnt;
f0104dec:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0104def:	c9                   	leave  
f0104df0:	c3                   	ret    

f0104df1 <freeMem>:
//	Steps:
//		1) Unmap all mapped pages in the range [virtual_address, virtual_address + size ]
//		2) Free all mapped page tables in this range

void freeMem(uint32* ptr_page_directory, void *virtual_address, uint32 size)
{
f0104df1:	55                   	push   %ebp
f0104df2:	89 e5                	mov    %esp,%ebp
f0104df4:	83 ec 08             	sub    $0x8,%esp
	// PROJECT 2008: Your code here.
	panic("freeMem function is not completed yet") ;
f0104df7:	83 ec 04             	sub    $0x4,%esp
f0104dfa:	68 68 99 10 f0       	push   $0xf0109968
f0104dff:	68 52 02 00 00       	push   $0x252
f0104e04:	68 c1 98 10 f0       	push   $0xf01098c1
f0104e09:	e8 20 b3 ff ff       	call   f010012e <_panic>

f0104e0e <allocate_environment>:
//
// Returns 0 on success, < 0 on failure.  Errors include:
//	E_NO_FREE_ENV if all NENVS environments are allocated
//
int allocate_environment(struct Env** e)
{	
f0104e0e:	55                   	push   %ebp
f0104e0f:	89 e5                	mov    %esp,%ebp
	if (!(*e = LIST_FIRST(&env_free_list)))
f0104e11:	8b 15 78 3f 15 f0    	mov    0xf0153f78,%edx
f0104e17:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e1a:	89 10                	mov    %edx,(%eax)
f0104e1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e1f:	8b 00                	mov    (%eax),%eax
f0104e21:	85 c0                	test   %eax,%eax
f0104e23:	75 07                	jne    f0104e2c <allocate_environment+0x1e>
		return E_NO_FREE_ENV;
f0104e25:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0104e2a:	eb 05                	jmp    f0104e31 <allocate_environment+0x23>
	return 0;
f0104e2c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e31:	5d                   	pop    %ebp
f0104e32:	c3                   	ret    

f0104e33 <free_environment>:

// Free the given environment "e", simply by adding it to the free environment list.
void free_environment(struct Env* e)
{
f0104e33:	55                   	push   %ebp
f0104e34:	89 e5                	mov    %esp,%ebp
	curenv = NULL;	
f0104e36:	c7 05 74 3f 15 f0 00 	movl   $0x0,0xf0153f74
f0104e3d:	00 00 00 
	// return the environment to the free list
	e->env_status = ENV_FREE;
f0104e40:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e43:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	LIST_INSERT_HEAD(&env_free_list, e);
f0104e4a:	8b 15 78 3f 15 f0    	mov    0xf0153f78,%edx
f0104e50:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e53:	89 50 44             	mov    %edx,0x44(%eax)
f0104e56:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e59:	8b 40 44             	mov    0x44(%eax),%eax
f0104e5c:	85 c0                	test   %eax,%eax
f0104e5e:	74 0e                	je     f0104e6e <free_environment+0x3b>
f0104e60:	a1 78 3f 15 f0       	mov    0xf0153f78,%eax
f0104e65:	8b 55 08             	mov    0x8(%ebp),%edx
f0104e68:	83 c2 44             	add    $0x44,%edx
f0104e6b:	89 50 48             	mov    %edx,0x48(%eax)
f0104e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e71:	a3 78 3f 15 f0       	mov    %eax,0xf0153f78
f0104e76:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e79:	c7 40 48 78 3f 15 f0 	movl   $0xf0153f78,0x48(%eax)
}
f0104e80:	90                   	nop
f0104e81:	5d                   	pop    %ebp
f0104e82:	c3                   	ret    

f0104e83 <program_segment_alloc_map>:
//
// if the allocation failed, return E_NO_MEM 
// otherwise return 0
//
static int program_segment_alloc_map(struct Env *e, void *va, uint32 length)
{
f0104e83:	55                   	push   %ebp
f0104e84:	89 e5                	mov    %esp,%ebp
f0104e86:	83 ec 08             	sub    $0x8,%esp
	//TODO: LAB6 Hands-on: fill this function. 
	//Comment the following line
	panic("Function is not implemented yet!");
f0104e89:	83 ec 04             	sub    $0x4,%esp
f0104e8c:	68 ec 99 10 f0       	push   $0xf01099ec
f0104e91:	6a 7b                	push   $0x7b
f0104e93:	68 0d 9a 10 f0       	push   $0xf0109a0d
f0104e98:	e8 91 b2 ff ff       	call   f010012e <_panic>

f0104e9d <env_create>:
}

//
// Allocates a new env and loads the named user program into it.
struct UserProgramInfo* env_create(char* user_program_name)
{
f0104e9d:	55                   	push   %ebp
f0104e9e:	89 e5                	mov    %esp,%ebp
f0104ea0:	83 ec 38             	sub    $0x38,%esp
	//[1] get pointer to the start of the "user_program_name" program in memory
	// Hint: use "get_user_program_info" function, 
	// you should set the following "ptr_program_start" by the start address of the user program 
	uint8* ptr_program_start = 0; 
f0104ea3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	struct UserProgramInfo* ptr_user_program_info =get_user_program_info(user_program_name);
f0104eaa:	83 ec 0c             	sub    $0xc,%esp
f0104ead:	ff 75 08             	pushl  0x8(%ebp)
f0104eb0:	e8 28 05 00 00       	call   f01053dd <get_user_program_info>
f0104eb5:	83 c4 10             	add    $0x10,%esp
f0104eb8:	89 45 f0             	mov    %eax,-0x10(%ebp)

	if (ptr_user_program_info == 0)
f0104ebb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0104ebf:	75 07                	jne    f0104ec8 <env_create+0x2b>
		return NULL ;
f0104ec1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ec6:	eb 42                	jmp    f0104f0a <env_create+0x6d>

	ptr_program_start = ptr_user_program_info->ptr_start ;
f0104ec8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104ecb:	8b 40 08             	mov    0x8(%eax),%eax
f0104ece:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//[2] allocate new environment, (from the free environment list)
	//if there's no one, return NULL
	// Hint: use "allocate_environment" function
	struct Env* e = NULL;
f0104ed1:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	if(allocate_environment(&e) == E_NO_FREE_ENV)
f0104ed8:	83 ec 0c             	sub    $0xc,%esp
f0104edb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104ede:	50                   	push   %eax
f0104edf:	e8 2a ff ff ff       	call   f0104e0e <allocate_environment>
f0104ee4:	83 c4 10             	add    $0x10,%esp
f0104ee7:	83 f8 fb             	cmp    $0xfffffffb,%eax
f0104eea:	75 07                	jne    f0104ef3 <env_create+0x56>
	{
		return 0;
f0104eec:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ef1:	eb 17                	jmp    f0104f0a <env_create+0x6d>
	}

	//=========================================================
	//TODO: LAB6 Hands-on: fill this part. 
	//Comment the following line
	panic("env_create: directory creation is not implemented yet!");
f0104ef3:	83 ec 04             	sub    $0x4,%esp
f0104ef6:	68 28 9a 10 f0       	push   $0xf0109a28
f0104efb:	68 9f 00 00 00       	push   $0x9f
f0104f00:	68 0d 9a 10 f0       	push   $0xf0109a0d
f0104f05:	e8 24 b2 ff ff       	call   f010012e <_panic>

	//[11] switch back to the page directory exists before segment loading
	lcr3(kern_phys_pgdir) ;

	return ptr_user_program_info;
}
f0104f0a:	c9                   	leave  
f0104f0b:	c3                   	ret    

f0104f0c <env_run>:
// Used to run the given environment "e", simply by 
// context switch from curenv to env e.
//  (This function does not return.)
//
void env_run(struct Env *e)
{
f0104f0c:	55                   	push   %ebp
f0104f0d:	89 e5                	mov    %esp,%ebp
f0104f0f:	83 ec 18             	sub    $0x18,%esp
	if(curenv != e)
f0104f12:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0104f17:	3b 45 08             	cmp    0x8(%ebp),%eax
f0104f1a:	74 25                	je     f0104f41 <env_run+0x35>
	{		
		curenv = e ;
f0104f1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f1f:	a3 74 3f 15 f0       	mov    %eax,0xf0153f74
		curenv->env_runs++ ;
f0104f24:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0104f29:	8b 50 58             	mov    0x58(%eax),%edx
f0104f2c:	42                   	inc    %edx
f0104f2d:	89 50 58             	mov    %edx,0x58(%eax)
		lcr3(curenv->env_cr3) ;	
f0104f30:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0104f35:	8b 40 60             	mov    0x60(%eax),%eax
f0104f38:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0104f3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f3e:	0f 22 d8             	mov    %eax,%cr3
	}	
	env_pop_tf(&(curenv->env_tf));
f0104f41:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0104f46:	83 ec 0c             	sub    $0xc,%esp
f0104f49:	50                   	push   %eax
f0104f4a:	e8 89 06 00 00       	call   f01055d8 <env_pop_tf>

f0104f4f <env_free>:

//
// Frees environment "e" and all memory it uses.
// 
void env_free(struct Env *e)
{
f0104f4f:	55                   	push   %ebp
f0104f50:	89 e5                	mov    %esp,%ebp
f0104f52:	83 ec 08             	sub    $0x8,%esp
	panic("env_free function is not completed yet") ;
f0104f55:	83 ec 04             	sub    $0x4,%esp
f0104f58:	68 60 9a 10 f0       	push   $0xf0109a60
f0104f5d:	68 2f 01 00 00       	push   $0x12f
f0104f62:	68 0d 9a 10 f0       	push   $0xf0109a0d
f0104f67:	e8 c2 b1 ff ff       	call   f010012e <_panic>

f0104f6c <env_init>:
// Insert in reverse order, so that the first call to allocate_environment()
// returns envs[0].
//
void
env_init(void)
{	
f0104f6c:	55                   	push   %ebp
f0104f6d:	89 e5                	mov    %esp,%ebp
f0104f6f:	53                   	push   %ebx
f0104f70:	83 ec 10             	sub    $0x10,%esp
	int iEnv = NENV-1;
f0104f73:	c7 45 f8 ff 03 00 00 	movl   $0x3ff,-0x8(%ebp)
	for(; iEnv >= 0; iEnv--)
f0104f7a:	e9 ed 00 00 00       	jmp    f010506c <env_init+0x100>
	{
		envs[iEnv].env_status = ENV_FREE;
f0104f7f:	8b 0d 70 3f 15 f0    	mov    0xf0153f70,%ecx
f0104f85:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0104f88:	89 d0                	mov    %edx,%eax
f0104f8a:	c1 e0 02             	shl    $0x2,%eax
f0104f8d:	01 d0                	add    %edx,%eax
f0104f8f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104f96:	01 d0                	add    %edx,%eax
f0104f98:	c1 e0 02             	shl    $0x2,%eax
f0104f9b:	01 c8                	add    %ecx,%eax
f0104f9d:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[iEnv].env_id = 0;
f0104fa4:	8b 0d 70 3f 15 f0    	mov    0xf0153f70,%ecx
f0104faa:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0104fad:	89 d0                	mov    %edx,%eax
f0104faf:	c1 e0 02             	shl    $0x2,%eax
f0104fb2:	01 d0                	add    %edx,%eax
f0104fb4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104fbb:	01 d0                	add    %edx,%eax
f0104fbd:	c1 e0 02             	shl    $0x2,%eax
f0104fc0:	01 c8                	add    %ecx,%eax
f0104fc2:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
f0104fc9:	8b 0d 70 3f 15 f0    	mov    0xf0153f70,%ecx
f0104fcf:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0104fd2:	89 d0                	mov    %edx,%eax
f0104fd4:	c1 e0 02             	shl    $0x2,%eax
f0104fd7:	01 d0                	add    %edx,%eax
f0104fd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0104fe0:	01 d0                	add    %edx,%eax
f0104fe2:	c1 e0 02             	shl    $0x2,%eax
f0104fe5:	01 c8                	add    %ecx,%eax
f0104fe7:	8b 15 78 3f 15 f0    	mov    0xf0153f78,%edx
f0104fed:	89 50 44             	mov    %edx,0x44(%eax)
f0104ff0:	8b 40 44             	mov    0x44(%eax),%eax
f0104ff3:	85 c0                	test   %eax,%eax
f0104ff5:	74 2a                	je     f0105021 <env_init+0xb5>
f0104ff7:	8b 15 78 3f 15 f0    	mov    0xf0153f78,%edx
f0104ffd:	8b 1d 70 3f 15 f0    	mov    0xf0153f70,%ebx
f0105003:	8b 4d f8             	mov    -0x8(%ebp),%ecx
f0105006:	89 c8                	mov    %ecx,%eax
f0105008:	c1 e0 02             	shl    $0x2,%eax
f010500b:	01 c8                	add    %ecx,%eax
f010500d:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0105014:	01 c8                	add    %ecx,%eax
f0105016:	c1 e0 02             	shl    $0x2,%eax
f0105019:	01 d8                	add    %ebx,%eax
f010501b:	83 c0 44             	add    $0x44,%eax
f010501e:	89 42 48             	mov    %eax,0x48(%edx)
f0105021:	8b 0d 70 3f 15 f0    	mov    0xf0153f70,%ecx
f0105027:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010502a:	89 d0                	mov    %edx,%eax
f010502c:	c1 e0 02             	shl    $0x2,%eax
f010502f:	01 d0                	add    %edx,%eax
f0105031:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0105038:	01 d0                	add    %edx,%eax
f010503a:	c1 e0 02             	shl    $0x2,%eax
f010503d:	01 c8                	add    %ecx,%eax
f010503f:	a3 78 3f 15 f0       	mov    %eax,0xf0153f78
f0105044:	8b 0d 70 3f 15 f0    	mov    0xf0153f70,%ecx
f010504a:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010504d:	89 d0                	mov    %edx,%eax
f010504f:	c1 e0 02             	shl    $0x2,%eax
f0105052:	01 d0                	add    %edx,%eax
f0105054:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f010505b:	01 d0                	add    %edx,%eax
f010505d:	c1 e0 02             	shl    $0x2,%eax
f0105060:	01 c8                	add    %ecx,%eax
f0105062:	c7 40 48 78 3f 15 f0 	movl   $0xf0153f78,0x48(%eax)
//
void
env_init(void)
{	
	int iEnv = NENV-1;
	for(; iEnv >= 0; iEnv--)
f0105069:	ff 4d f8             	decl   -0x8(%ebp)
f010506c:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0105070:	0f 89 09 ff ff ff    	jns    f0104f7f <env_init+0x13>
	{
		envs[iEnv].env_status = ENV_FREE;
		envs[iEnv].env_id = 0;
		LIST_INSERT_HEAD(&env_free_list, &envs[iEnv]);	
	}
}
f0105076:	90                   	nop
f0105077:	83 c4 10             	add    $0x10,%esp
f010507a:	5b                   	pop    %ebx
f010507b:	5d                   	pop    %ebp
f010507c:	c3                   	ret    

f010507d <complete_environment_initialization>:

void complete_environment_initialization(struct Env* e)
{	
f010507d:	55                   	push   %ebp
f010507e:	89 e5                	mov    %esp,%ebp
f0105080:	83 ec 18             	sub    $0x18,%esp
	//VPT and UVPT map the env's own page table, with
	//different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PERM_PRESENT | PERM_WRITEABLE;
f0105083:	8b 45 08             	mov    0x8(%ebp),%eax
f0105086:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105089:	8d 90 fc 0e 00 00    	lea    0xefc(%eax),%edx
f010508f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105092:	8b 40 60             	mov    0x60(%eax),%eax
f0105095:	83 c8 03             	or     $0x3,%eax
f0105098:	89 02                	mov    %eax,(%edx)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PERM_PRESENT | PERM_USER;
f010509a:	8b 45 08             	mov    0x8(%ebp),%eax
f010509d:	8b 40 5c             	mov    0x5c(%eax),%eax
f01050a0:	8d 90 f4 0e 00 00    	lea    0xef4(%eax),%edx
f01050a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01050a9:	8b 40 60             	mov    0x60(%eax),%eax
f01050ac:	83 c8 05             	or     $0x5,%eax
f01050af:	89 02                	mov    %eax,(%edx)

	int32 generation;	
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01050b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01050b4:	8b 40 4c             	mov    0x4c(%eax),%eax
f01050b7:	05 00 10 00 00       	add    $0x1000,%eax
f01050bc:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01050c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (generation <= 0)	// Don't create a negative env_id.
f01050c4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01050c8:	7f 07                	jg     f01050d1 <complete_environment_initialization+0x54>
		generation = 1 << ENVGENSHIFT;
f01050ca:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%ebp)
	e->env_id = generation | (e - envs);
f01050d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01050d4:	8b 15 70 3f 15 f0    	mov    0xf0153f70,%edx
f01050da:	29 d0                	sub    %edx,%eax
f01050dc:	c1 f8 02             	sar    $0x2,%eax
f01050df:	89 c1                	mov    %eax,%ecx
f01050e1:	89 c8                	mov    %ecx,%eax
f01050e3:	c1 e0 02             	shl    $0x2,%eax
f01050e6:	01 c8                	add    %ecx,%eax
f01050e8:	c1 e0 07             	shl    $0x7,%eax
f01050eb:	29 c8                	sub    %ecx,%eax
f01050ed:	c1 e0 03             	shl    $0x3,%eax
f01050f0:	01 c8                	add    %ecx,%eax
f01050f2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01050f9:	01 d0                	add    %edx,%eax
f01050fb:	c1 e0 02             	shl    $0x2,%eax
f01050fe:	01 c8                	add    %ecx,%eax
f0105100:	c1 e0 03             	shl    $0x3,%eax
f0105103:	01 c8                	add    %ecx,%eax
f0105105:	89 c2                	mov    %eax,%edx
f0105107:	c1 e2 06             	shl    $0x6,%edx
f010510a:	29 c2                	sub    %eax,%edx
f010510c:	8d 04 12             	lea    (%edx,%edx,1),%eax
f010510f:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0105112:	8d 04 95 00 00 00 00 	lea    0x0(,%edx,4),%eax
f0105119:	01 c2                	add    %eax,%edx
f010511b:	8d 04 12             	lea    (%edx,%edx,1),%eax
f010511e:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f0105121:	89 d0                	mov    %edx,%eax
f0105123:	f7 d8                	neg    %eax
f0105125:	0b 45 f4             	or     -0xc(%ebp),%eax
f0105128:	89 c2                	mov    %eax,%edx
f010512a:	8b 45 08             	mov    0x8(%ebp),%eax
f010512d:	89 50 4c             	mov    %edx,0x4c(%eax)

	// Set the basic status variables.
	e->env_parent_id = 0;//parent_id;
f0105130:	8b 45 08             	mov    0x8(%ebp),%eax
f0105133:	c7 40 50 00 00 00 00 	movl   $0x0,0x50(%eax)
	e->env_status = ENV_RUNNABLE;
f010513a:	8b 45 08             	mov    0x8(%ebp),%eax
f010513d:	c7 40 54 01 00 00 00 	movl   $0x1,0x54(%eax)
	e->env_runs = 0;
f0105144:	8b 45 08             	mov    0x8(%ebp),%eax
f0105147:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010514e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105151:	83 ec 04             	sub    $0x4,%esp
f0105154:	6a 44                	push   $0x44
f0105156:	6a 00                	push   $0x0
f0105158:	50                   	push   %eax
f0105159:	e8 39 1c 00 00       	call   f0106d97 <memset>
f010515e:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	e->env_tf.tf_ds = GD_UD | 3;
f0105161:	8b 45 08             	mov    0x8(%ebp),%eax
f0105164:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	e->env_tf.tf_es = GD_UD | 3;
f010516a:	8b 45 08             	mov    0x8(%ebp),%eax
f010516d:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	e->env_tf.tf_ss = GD_UD | 3;
f0105173:	8b 45 08             	mov    0x8(%ebp),%eax
f0105176:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	e->env_tf.tf_esp = (uint32*)USTACKTOP;
f010517c:	8b 45 08             	mov    0x8(%ebp),%eax
f010517f:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	e->env_tf.tf_cs = GD_UT | 3;
f0105186:	8b 45 08             	mov    0x8(%ebp),%eax
f0105189:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e);	
f010518f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105192:	8b 40 44             	mov    0x44(%eax),%eax
f0105195:	85 c0                	test   %eax,%eax
f0105197:	74 0f                	je     f01051a8 <complete_environment_initialization+0x12b>
f0105199:	8b 45 08             	mov    0x8(%ebp),%eax
f010519c:	8b 40 44             	mov    0x44(%eax),%eax
f010519f:	8b 55 08             	mov    0x8(%ebp),%edx
f01051a2:	8b 52 48             	mov    0x48(%edx),%edx
f01051a5:	89 50 48             	mov    %edx,0x48(%eax)
f01051a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01051ab:	8b 40 48             	mov    0x48(%eax),%eax
f01051ae:	8b 55 08             	mov    0x8(%ebp),%edx
f01051b1:	8b 52 44             	mov    0x44(%edx),%edx
f01051b4:	89 10                	mov    %edx,(%eax)
	return ;
f01051b6:	90                   	nop
}
f01051b7:	c9                   	leave  
f01051b8:	c3                   	ret    

f01051b9 <PROGRAM_SEGMENT_NEXT>:

struct ProgramSegment* PROGRAM_SEGMENT_NEXT(struct ProgramSegment* seg, uint8* ptr_program_start)
				{
f01051b9:	55                   	push   %ebp
f01051ba:	89 e5                	mov    %esp,%ebp
f01051bc:	83 ec 18             	sub    $0x18,%esp
	int index = (*seg).segment_id++;
f01051bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01051c2:	8b 40 10             	mov    0x10(%eax),%eax
f01051c5:	8d 48 01             	lea    0x1(%eax),%ecx
f01051c8:	8b 55 08             	mov    0x8(%ebp),%edx
f01051cb:	89 4a 10             	mov    %ecx,0x10(%edx)
f01051ce:	89 45 f4             	mov    %eax,-0xc(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01051d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01051d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01051da:	8b 00                	mov    (%eax),%eax
f01051dc:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01051e1:	74 17                	je     f01051fa <PROGRAM_SEGMENT_NEXT+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01051e3:	83 ec 04             	sub    $0x4,%esp
f01051e6:	68 87 9a 10 f0       	push   $0xf0109a87
f01051eb:	68 88 01 00 00       	push   $0x188
f01051f0:	68 0d 9a 10 f0       	push   $0xf0109a0d
f01051f5:	e8 34 af ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01051fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01051fd:	8b 50 1c             	mov    0x1c(%eax),%edx
f0105200:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105203:	01 d0                	add    %edx,%eax
f0105205:	89 45 ec             	mov    %eax,-0x14(%ebp)

	while (ph[(*seg).segment_id].p_type != ELF_PROG_LOAD && ((*seg).segment_id < pELFHDR->e_phnum)) (*seg).segment_id++;	
f0105208:	eb 0f                	jmp    f0105219 <PROGRAM_SEGMENT_NEXT+0x60>
f010520a:	8b 45 08             	mov    0x8(%ebp),%eax
f010520d:	8b 40 10             	mov    0x10(%eax),%eax
f0105210:	8d 50 01             	lea    0x1(%eax),%edx
f0105213:	8b 45 08             	mov    0x8(%ebp),%eax
f0105216:	89 50 10             	mov    %edx,0x10(%eax)
f0105219:	8b 45 08             	mov    0x8(%ebp),%eax
f010521c:	8b 40 10             	mov    0x10(%eax),%eax
f010521f:	c1 e0 05             	shl    $0x5,%eax
f0105222:	89 c2                	mov    %eax,%edx
f0105224:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105227:	01 d0                	add    %edx,%eax
f0105229:	8b 00                	mov    (%eax),%eax
f010522b:	83 f8 01             	cmp    $0x1,%eax
f010522e:	74 13                	je     f0105243 <PROGRAM_SEGMENT_NEXT+0x8a>
f0105230:	8b 45 08             	mov    0x8(%ebp),%eax
f0105233:	8b 50 10             	mov    0x10(%eax),%edx
f0105236:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105239:	8b 40 2c             	mov    0x2c(%eax),%eax
f010523c:	0f b7 c0             	movzwl %ax,%eax
f010523f:	39 c2                	cmp    %eax,%edx
f0105241:	72 c7                	jb     f010520a <PROGRAM_SEGMENT_NEXT+0x51>
	index = (*seg).segment_id;
f0105243:	8b 45 08             	mov    0x8(%ebp),%eax
f0105246:	8b 40 10             	mov    0x10(%eax),%eax
f0105249:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(index < pELFHDR->e_phnum)
f010524c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010524f:	8b 40 2c             	mov    0x2c(%eax),%eax
f0105252:	0f b7 c0             	movzwl %ax,%eax
f0105255:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0105258:	7e 63                	jle    f01052bd <PROGRAM_SEGMENT_NEXT+0x104>
	{
		(*seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f010525a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010525d:	c1 e0 05             	shl    $0x5,%eax
f0105260:	89 c2                	mov    %eax,%edx
f0105262:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105265:	01 d0                	add    %edx,%eax
f0105267:	8b 50 04             	mov    0x4(%eax),%edx
f010526a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010526d:	01 c2                	add    %eax,%edx
f010526f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105272:	89 10                	mov    %edx,(%eax)
		(*seg).size_in_memory =  ph[index].p_memsz;
f0105274:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105277:	c1 e0 05             	shl    $0x5,%eax
f010527a:	89 c2                	mov    %eax,%edx
f010527c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010527f:	01 d0                	add    %edx,%eax
f0105281:	8b 50 14             	mov    0x14(%eax),%edx
f0105284:	8b 45 08             	mov    0x8(%ebp),%eax
f0105287:	89 50 08             	mov    %edx,0x8(%eax)
		(*seg).size_in_file = ph[index].p_filesz;
f010528a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010528d:	c1 e0 05             	shl    $0x5,%eax
f0105290:	89 c2                	mov    %eax,%edx
f0105292:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105295:	01 d0                	add    %edx,%eax
f0105297:	8b 50 10             	mov    0x10(%eax),%edx
f010529a:	8b 45 08             	mov    0x8(%ebp),%eax
f010529d:	89 50 04             	mov    %edx,0x4(%eax)
		(*seg).virtual_address = (uint8*)ph[index].p_va;
f01052a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01052a3:	c1 e0 05             	shl    $0x5,%eax
f01052a6:	89 c2                	mov    %eax,%edx
f01052a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01052ab:	01 d0                	add    %edx,%eax
f01052ad:	8b 40 08             	mov    0x8(%eax),%eax
f01052b0:	89 c2                	mov    %eax,%edx
f01052b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01052b5:	89 50 0c             	mov    %edx,0xc(%eax)
		return seg;
f01052b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01052bb:	eb 05                	jmp    f01052c2 <PROGRAM_SEGMENT_NEXT+0x109>
	}
	return 0;
f01052bd:	b8 00 00 00 00       	mov    $0x0,%eax
				}
f01052c2:	c9                   	leave  
f01052c3:	c3                   	ret    

f01052c4 <PROGRAM_SEGMENT_FIRST>:

struct ProgramSegment PROGRAM_SEGMENT_FIRST( uint8* ptr_program_start)
{
f01052c4:	55                   	push   %ebp
f01052c5:	89 e5                	mov    %esp,%ebp
f01052c7:	57                   	push   %edi
f01052c8:	56                   	push   %esi
f01052c9:	53                   	push   %ebx
f01052ca:	83 ec 2c             	sub    $0x2c,%esp
	struct ProgramSegment seg;
	seg.segment_id = 0;
f01052cd:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

	struct Proghdr *ph, *eph; 
	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01052d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052d7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01052da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052dd:	8b 00                	mov    (%eax),%eax
f01052df:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01052e4:	74 17                	je     f01052fd <PROGRAM_SEGMENT_FIRST+0x39>
		panic("Matafa2nash 3ala Keda"); 
f01052e6:	83 ec 04             	sub    $0x4,%esp
f01052e9:	68 87 9a 10 f0       	push   $0xf0109a87
f01052ee:	68 a1 01 00 00       	push   $0x1a1
f01052f3:	68 0d 9a 10 f0       	push   $0xf0109a0d
f01052f8:	e8 31 ae ff ff       	call   f010012e <_panic>
	ph = (struct Proghdr *) ( ((uint8 *) ptr_program_start) + pELFHDR->e_phoff);
f01052fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105300:	8b 50 1c             	mov    0x1c(%eax),%edx
f0105303:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105306:	01 d0                	add    %edx,%eax
f0105308:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while (ph[(seg).segment_id].p_type != ELF_PROG_LOAD && ((seg).segment_id < pELFHDR->e_phnum)) (seg).segment_id++;
f010530b:	eb 07                	jmp    f0105314 <PROGRAM_SEGMENT_FIRST+0x50>
f010530d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105310:	40                   	inc    %eax
f0105311:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105314:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105317:	c1 e0 05             	shl    $0x5,%eax
f010531a:	89 c2                	mov    %eax,%edx
f010531c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010531f:	01 d0                	add    %edx,%eax
f0105321:	8b 00                	mov    (%eax),%eax
f0105323:	83 f8 01             	cmp    $0x1,%eax
f0105326:	74 10                	je     f0105338 <PROGRAM_SEGMENT_FIRST+0x74>
f0105328:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010532b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010532e:	8b 40 2c             	mov    0x2c(%eax),%eax
f0105331:	0f b7 c0             	movzwl %ax,%eax
f0105334:	39 c2                	cmp    %eax,%edx
f0105336:	72 d5                	jb     f010530d <PROGRAM_SEGMENT_FIRST+0x49>
	int index = (seg).segment_id;
f0105338:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010533b:	89 45 dc             	mov    %eax,-0x24(%ebp)

	if(index < pELFHDR->e_phnum)
f010533e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105341:	8b 40 2c             	mov    0x2c(%eax),%eax
f0105344:	0f b7 c0             	movzwl %ax,%eax
f0105347:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010534a:	7e 68                	jle    f01053b4 <PROGRAM_SEGMENT_FIRST+0xf0>
	{	
		(seg).ptr_start = (uint8 *) ptr_program_start + ph[index].p_offset;
f010534c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010534f:	c1 e0 05             	shl    $0x5,%eax
f0105352:	89 c2                	mov    %eax,%edx
f0105354:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105357:	01 d0                	add    %edx,%eax
f0105359:	8b 50 04             	mov    0x4(%eax),%edx
f010535c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010535f:	01 d0                	add    %edx,%eax
f0105361:	89 45 c8             	mov    %eax,-0x38(%ebp)
		(seg).size_in_memory =  ph[index].p_memsz;
f0105364:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105367:	c1 e0 05             	shl    $0x5,%eax
f010536a:	89 c2                	mov    %eax,%edx
f010536c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010536f:	01 d0                	add    %edx,%eax
f0105371:	8b 40 14             	mov    0x14(%eax),%eax
f0105374:	89 45 d0             	mov    %eax,-0x30(%ebp)
		(seg).size_in_file = ph[index].p_filesz;
f0105377:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010537a:	c1 e0 05             	shl    $0x5,%eax
f010537d:	89 c2                	mov    %eax,%edx
f010537f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105382:	01 d0                	add    %edx,%eax
f0105384:	8b 40 10             	mov    0x10(%eax),%eax
f0105387:	89 45 cc             	mov    %eax,-0x34(%ebp)
		(seg).virtual_address = (uint8*)ph[index].p_va;
f010538a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010538d:	c1 e0 05             	shl    $0x5,%eax
f0105390:	89 c2                	mov    %eax,%edx
f0105392:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105395:	01 d0                	add    %edx,%eax
f0105397:	8b 40 08             	mov    0x8(%eax),%eax
f010539a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		return seg;
f010539d:	8b 45 08             	mov    0x8(%ebp),%eax
f01053a0:	89 c3                	mov    %eax,%ebx
f01053a2:	8d 45 c8             	lea    -0x38(%ebp),%eax
f01053a5:	ba 05 00 00 00       	mov    $0x5,%edx
f01053aa:	89 df                	mov    %ebx,%edi
f01053ac:	89 c6                	mov    %eax,%esi
f01053ae:	89 d1                	mov    %edx,%ecx
f01053b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01053b2:	eb 1c                	jmp    f01053d0 <PROGRAM_SEGMENT_FIRST+0x10c>
	}
	seg.segment_id = -1;
f01053b4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
	return seg;
f01053bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01053be:	89 c3                	mov    %eax,%ebx
f01053c0:	8d 45 c8             	lea    -0x38(%ebp),%eax
f01053c3:	ba 05 00 00 00       	mov    $0x5,%edx
f01053c8:	89 df                	mov    %ebx,%edi
f01053ca:	89 c6                	mov    %eax,%esi
f01053cc:	89 d1                	mov    %edx,%ecx
f01053ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
}
f01053d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01053d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01053d6:	5b                   	pop    %ebx
f01053d7:	5e                   	pop    %esi
f01053d8:	5f                   	pop    %edi
f01053d9:	5d                   	pop    %ebp
f01053da:	c2 04 00             	ret    $0x4

f01053dd <get_user_program_info>:

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
f01053dd:	55                   	push   %ebp
f01053de:	89 e5                	mov    %esp,%ebp
f01053e0:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f01053e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f01053ea:	eb 23                	jmp    f010540f <get_user_program_info+0x32>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
f01053ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053ef:	c1 e0 04             	shl    $0x4,%eax
f01053f2:	05 c0 16 12 f0       	add    $0xf01216c0,%eax
f01053f7:	8b 00                	mov    (%eax),%eax
f01053f9:	83 ec 08             	sub    $0x8,%esp
f01053fc:	50                   	push   %eax
f01053fd:	ff 75 08             	pushl  0x8(%ebp)
f0105400:	e8 b0 18 00 00       	call   f0106cb5 <strcmp>
f0105405:	83 c4 10             	add    $0x10,%esp
f0105408:	85 c0                	test   %eax,%eax
f010540a:	74 0f                	je     f010541b <get_user_program_info+0x3e>
}

struct UserProgramInfo* get_user_program_info(char* user_program_name)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f010540c:	ff 45 f4             	incl   -0xc(%ebp)
f010540f:	a1 14 17 12 f0       	mov    0xf0121714,%eax
f0105414:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0105417:	7c d3                	jl     f01053ec <get_user_program_info+0xf>
f0105419:	eb 01                	jmp    f010541c <get_user_program_info+0x3f>
		if (strcmp(user_program_name, userPrograms[i].name) == 0)
			break;
f010541b:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f010541c:	a1 14 17 12 f0       	mov    0xf0121714,%eax
f0105421:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0105424:	75 1a                	jne    f0105440 <get_user_program_info+0x63>
	{
		cprintf("Unknown user program '%s'\n", user_program_name);
f0105426:	83 ec 08             	sub    $0x8,%esp
f0105429:	ff 75 08             	pushl  0x8(%ebp)
f010542c:	68 9d 9a 10 f0       	push   $0xf0109a9d
f0105431:	e8 7e 02 00 00       	call   f01056b4 <cprintf>
f0105436:	83 c4 10             	add    $0x10,%esp
		return 0;
f0105439:	b8 00 00 00 00       	mov    $0x0,%eax
f010543e:	eb 0b                	jmp    f010544b <get_user_program_info+0x6e>
	}

	return &userPrograms[i];
f0105440:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105443:	c1 e0 04             	shl    $0x4,%eax
f0105446:	05 c0 16 12 f0       	add    $0xf01216c0,%eax
				}
f010544b:	c9                   	leave  
f010544c:	c3                   	ret    

f010544d <get_user_program_info_by_env>:

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
f010544d:	55                   	push   %ebp
f010544e:	89 e5                	mov    %esp,%ebp
f0105450:	83 ec 18             	sub    $0x18,%esp
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f0105453:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
f010545a:	eb 15                	jmp    f0105471 <get_user_program_info_by_env+0x24>
		if (e== userPrograms[i].environment)
f010545c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010545f:	c1 e0 04             	shl    $0x4,%eax
f0105462:	05 cc 16 12 f0       	add    $0xf01216cc,%eax
f0105467:	8b 00                	mov    (%eax),%eax
f0105469:	3b 45 08             	cmp    0x8(%ebp),%eax
f010546c:	74 0f                	je     f010547d <get_user_program_info_by_env+0x30>
				}

struct UserProgramInfo* get_user_program_info_by_env(struct Env* e)
				{
	int i;
	for (i = 0; i < NUM_USER_PROGS; i++) {
f010546e:	ff 45 f4             	incl   -0xc(%ebp)
f0105471:	a1 14 17 12 f0       	mov    0xf0121714,%eax
f0105476:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0105479:	7c e1                	jl     f010545c <get_user_program_info_by_env+0xf>
f010547b:	eb 01                	jmp    f010547e <get_user_program_info_by_env+0x31>
		if (e== userPrograms[i].environment)
			break;
f010547d:	90                   	nop
	}
	if(i==NUM_USER_PROGS) 
f010547e:	a1 14 17 12 f0       	mov    0xf0121714,%eax
f0105483:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0105486:	75 17                	jne    f010549f <get_user_program_info_by_env+0x52>
	{
		cprintf("Unknown user program \n");
f0105488:	83 ec 0c             	sub    $0xc,%esp
f010548b:	68 b8 9a 10 f0       	push   $0xf0109ab8
f0105490:	e8 1f 02 00 00       	call   f01056b4 <cprintf>
f0105495:	83 c4 10             	add    $0x10,%esp
		return 0;
f0105498:	b8 00 00 00 00       	mov    $0x0,%eax
f010549d:	eb 0b                	jmp    f01054aa <get_user_program_info_by_env+0x5d>
	}

	return &userPrograms[i];
f010549f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01054a2:	c1 e0 04             	shl    $0x4,%eax
f01054a5:	05 c0 16 12 f0       	add    $0xf01216c0,%eax
				}
f01054aa:	c9                   	leave  
f01054ab:	c3                   	ret    

f01054ac <set_environment_entry_point>:

void set_environment_entry_point(struct UserProgramInfo* ptr_user_program)
{
f01054ac:	55                   	push   %ebp
f01054ad:	89 e5                	mov    %esp,%ebp
f01054af:	83 ec 18             	sub    $0x18,%esp
	uint8* ptr_program_start=ptr_user_program->ptr_start;
f01054b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01054b5:	8b 40 08             	mov    0x8(%eax),%eax
f01054b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	struct Env* e = ptr_user_program->environment;
f01054bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01054be:	8b 40 0c             	mov    0xc(%eax),%eax
f01054c1:	89 45 f0             	mov    %eax,-0x10(%ebp)

	struct Elf * pELFHDR = (struct Elf *)ptr_program_start ; 
f01054c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01054c7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pELFHDR->e_magic != ELF_MAGIC) 
f01054ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01054cd:	8b 00                	mov    (%eax),%eax
f01054cf:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
f01054d4:	74 17                	je     f01054ed <set_environment_entry_point+0x41>
		panic("Matafa2nash 3ala Keda"); 
f01054d6:	83 ec 04             	sub    $0x4,%esp
f01054d9:	68 87 9a 10 f0       	push   $0xf0109a87
f01054de:	68 d9 01 00 00       	push   $0x1d9
f01054e3:	68 0d 9a 10 f0       	push   $0xf0109a0d
f01054e8:	e8 41 ac ff ff       	call   f010012e <_panic>
	e->env_tf.tf_eip = (uint32*)pELFHDR->e_entry ;
f01054ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01054f0:	8b 40 18             	mov    0x18(%eax),%eax
f01054f3:	89 c2                	mov    %eax,%edx
f01054f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01054f8:	89 50 30             	mov    %edx,0x30(%eax)
}
f01054fb:	90                   	nop
f01054fc:	c9                   	leave  
f01054fd:	c3                   	ret    

f01054fe <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f01054fe:	55                   	push   %ebp
f01054ff:	89 e5                	mov    %esp,%ebp
f0105501:	83 ec 08             	sub    $0x8,%esp
	env_free(e);
f0105504:	83 ec 0c             	sub    $0xc,%esp
f0105507:	ff 75 08             	pushl  0x8(%ebp)
f010550a:	e8 40 fa ff ff       	call   f0104f4f <env_free>
f010550f:	83 c4 10             	add    $0x10,%esp

	//cprintf("Destroyed the only environment - nothing more to do!\n");
	while (1)
		run_command_prompt();
f0105512:	e8 3a b4 ff ff       	call   f0100951 <run_command_prompt>
f0105517:	eb f9                	jmp    f0105512 <env_destroy+0x14>

f0105519 <env_run_cmd_prmpt>:
}

void env_run_cmd_prmpt()
{
f0105519:	55                   	push   %ebp
f010551a:	89 e5                	mov    %esp,%ebp
f010551c:	83 ec 18             	sub    $0x18,%esp
	struct UserProgramInfo* upi= get_user_program_info_by_env(curenv);	
f010551f:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105524:	83 ec 0c             	sub    $0xc,%esp
f0105527:	50                   	push   %eax
f0105528:	e8 20 ff ff ff       	call   f010544d <get_user_program_info_by_env>
f010552d:	83 c4 10             	add    $0x10,%esp
f0105530:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&curenv->env_tf, 0, sizeof(curenv->env_tf));
f0105533:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105538:	83 ec 04             	sub    $0x4,%esp
f010553b:	6a 44                	push   $0x44
f010553d:	6a 00                	push   $0x0
f010553f:	50                   	push   %eax
f0105540:	e8 52 18 00 00       	call   f0106d97 <memset>
f0105545:	83 c4 10             	add    $0x10,%esp
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.

	curenv->env_tf.tf_ds = GD_UD | 3;
f0105548:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f010554d:	66 c7 40 24 23 00    	movw   $0x23,0x24(%eax)
	curenv->env_tf.tf_es = GD_UD | 3;
f0105553:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105558:	66 c7 40 20 23 00    	movw   $0x23,0x20(%eax)
	curenv->env_tf.tf_ss = GD_UD | 3;
f010555e:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105563:	66 c7 40 40 23 00    	movw   $0x23,0x40(%eax)
	curenv->env_tf.tf_esp = (uint32*)USTACKTOP;
f0105569:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f010556e:	c7 40 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%eax)
	curenv->env_tf.tf_cs = GD_UT | 3;
f0105575:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f010557a:	66 c7 40 34 1b 00    	movw   $0x1b,0x34(%eax)
	set_environment_entry_point(upi);
f0105580:	83 ec 0c             	sub    $0xc,%esp
f0105583:	ff 75 f4             	pushl  -0xc(%ebp)
f0105586:	e8 21 ff ff ff       	call   f01054ac <set_environment_entry_point>
f010558b:	83 c4 10             	add    $0x10,%esp

	lcr3(K_PHYSICAL_ADDRESS(ptr_page_directory));
f010558e:	a1 cc 49 15 f0       	mov    0xf01549cc,%eax
f0105593:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105596:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f010559d:	77 17                	ja     f01055b6 <env_run_cmd_prmpt+0x9d>
f010559f:	ff 75 f0             	pushl  -0x10(%ebp)
f01055a2:	68 d0 9a 10 f0       	push   $0xf0109ad0
f01055a7:	68 04 02 00 00       	push   $0x204
f01055ac:	68 0d 9a 10 f0       	push   $0xf0109a0d
f01055b1:	e8 78 ab ff ff       	call   f010012e <_panic>
f01055b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01055b9:	05 00 00 00 10       	add    $0x10000000,%eax
f01055be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01055c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01055c4:	0f 22 d8             	mov    %eax,%cr3

	curenv = NULL;
f01055c7:	c7 05 74 3f 15 f0 00 	movl   $0x0,0xf0153f74
f01055ce:	00 00 00 

	while (1)
		run_command_prompt();
f01055d1:	e8 7b b3 ff ff       	call   f0100951 <run_command_prompt>
f01055d6:	eb f9                	jmp    f01055d1 <env_run_cmd_prmpt+0xb8>

f01055d8 <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01055d8:	55                   	push   %ebp
f01055d9:	89 e5                	mov    %esp,%ebp
f01055db:	83 ec 08             	sub    $0x8,%esp
	__asm __volatile("movl %0,%%esp\n"
f01055de:	8b 65 08             	mov    0x8(%ebp),%esp
f01055e1:	61                   	popa   
f01055e2:	07                   	pop    %es
f01055e3:	1f                   	pop    %ds
f01055e4:	83 c4 08             	add    $0x8,%esp
f01055e7:	cf                   	iret   
			"\tpopl %%es\n"
			"\tpopl %%ds\n"
			"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
			"\tiret"
			: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01055e8:	83 ec 04             	sub    $0x4,%esp
f01055eb:	68 01 9b 10 f0       	push   $0xf0109b01
f01055f0:	68 1b 02 00 00       	push   $0x21b
f01055f5:	68 0d 9a 10 f0       	push   $0xf0109a0d
f01055fa:	e8 2f ab ff ff       	call   f010012e <_panic>

f01055ff <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01055ff:	55                   	push   %ebp
f0105600:	89 e5                	mov    %esp,%ebp
f0105602:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0105605:	8b 45 08             	mov    0x8(%ebp),%eax
f0105608:	0f b6 c0             	movzbl %al,%eax
f010560b:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0105612:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105615:	8a 45 f6             	mov    -0xa(%ebp),%al
f0105618:	8b 55 fc             	mov    -0x4(%ebp),%edx
f010561b:	ee                   	out    %al,(%dx)
f010561c:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static __inline uint8
inb(int port)
{
	uint8 data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105623:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0105626:	89 c2                	mov    %eax,%edx
f0105628:	ec                   	in     (%dx),%al
f0105629:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f010562c:	8a 45 f7             	mov    -0x9(%ebp),%al
	return inb(IO_RTC+1);
f010562f:	0f b6 c0             	movzbl %al,%eax
}
f0105632:	c9                   	leave  
f0105633:	c3                   	ret    

f0105634 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0105634:	55                   	push   %ebp
f0105635:	89 e5                	mov    %esp,%ebp
f0105637:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f010563a:	8b 45 08             	mov    0x8(%ebp),%eax
f010563d:	0f b6 c0             	movzbl %al,%eax
f0105640:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
f0105647:	88 45 f6             	mov    %al,-0xa(%ebp)
}

static __inline void
outb(int port, uint8 data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010564a:	8a 45 f6             	mov    -0xa(%ebp),%al
f010564d:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0105650:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f0105651:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105654:	0f b6 c0             	movzbl %al,%eax
f0105657:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)
f010565e:	88 45 f7             	mov    %al,-0x9(%ebp)
f0105661:	8a 45 f7             	mov    -0x9(%ebp),%al
f0105664:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0105667:	ee                   	out    %al,(%dx)
}
f0105668:	90                   	nop
f0105669:	c9                   	leave  
f010566a:	c3                   	ret    

f010566b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010566b:	55                   	push   %ebp
f010566c:	89 e5                	mov    %esp,%ebp
f010566e:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f0105671:	83 ec 0c             	sub    $0xc,%esp
f0105674:	ff 75 08             	pushl  0x8(%ebp)
f0105677:	e8 9b b2 ff ff       	call   f0100917 <cputchar>
f010567c:	83 c4 10             	add    $0x10,%esp
	*cnt++;
f010567f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105682:	83 c0 04             	add    $0x4,%eax
f0105685:	89 45 0c             	mov    %eax,0xc(%ebp)
}
f0105688:	90                   	nop
f0105689:	c9                   	leave  
f010568a:	c3                   	ret    

f010568b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010568b:	55                   	push   %ebp
f010568c:	89 e5                	mov    %esp,%ebp
f010568e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0105691:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0105698:	ff 75 0c             	pushl  0xc(%ebp)
f010569b:	ff 75 08             	pushl  0x8(%ebp)
f010569e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01056a1:	50                   	push   %eax
f01056a2:	68 6b 56 10 f0       	push   $0xf010566b
f01056a7:	e8 57 0f 00 00       	call   f0106603 <vprintfmt>
f01056ac:	83 c4 10             	add    $0x10,%esp
	return cnt;
f01056af:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f01056b2:	c9                   	leave  
f01056b3:	c3                   	ret    

f01056b4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01056b4:	55                   	push   %ebp
f01056b5:	89 e5                	mov    %esp,%ebp
f01056b7:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01056ba:	8d 45 0c             	lea    0xc(%ebp),%eax
f01056bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
f01056c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01056c3:	83 ec 08             	sub    $0x8,%esp
f01056c6:	ff 75 f4             	pushl  -0xc(%ebp)
f01056c9:	50                   	push   %eax
f01056ca:	e8 bc ff ff ff       	call   f010568b <vcprintf>
f01056cf:	83 c4 10             	add    $0x10,%esp
f01056d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
f01056d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f01056d8:	c9                   	leave  
f01056d9:	c3                   	ret    

f01056da <trapname>:
};
extern  void (*PAGE_FAULT)();
extern  void (*SYSCALL_HANDLER)();

static const char *trapname(int trapno)
{
f01056da:	55                   	push   %ebp
f01056db:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01056dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01056e0:	83 f8 13             	cmp    $0x13,%eax
f01056e3:	77 0c                	ja     f01056f1 <trapname+0x17>
		return excnames[trapno];
f01056e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01056e8:	8b 04 85 40 9e 10 f0 	mov    -0xfef61c0(,%eax,4),%eax
f01056ef:	eb 12                	jmp    f0105703 <trapname+0x29>
	if (trapno == T_SYSCALL)
f01056f1:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
f01056f5:	75 07                	jne    f01056fe <trapname+0x24>
		return "System call";
f01056f7:	b8 20 9b 10 f0       	mov    $0xf0109b20,%eax
f01056fc:	eb 05                	jmp    f0105703 <trapname+0x29>
	return "(unknown trap)";
f01056fe:	b8 2c 9b 10 f0       	mov    $0xf0109b2c,%eax
}
f0105703:	5d                   	pop    %ebp
f0105704:	c3                   	ret    

f0105705 <idt_init>:


void
idt_init(void)
{
f0105705:	55                   	push   %ebp
f0105706:	89 e5                	mov    %esp,%ebp
f0105708:	83 ec 10             	sub    $0x10,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	//initialize idt
	SETGATE(idt[T_PGFLT], 0, GD_KT , &PAGE_FAULT, 0) ;
f010570b:	b8 64 5c 10 f0       	mov    $0xf0105c64,%eax
f0105710:	66 a3 f0 3f 15 f0    	mov    %ax,0xf0153ff0
f0105716:	66 c7 05 f2 3f 15 f0 	movw   $0x8,0xf0153ff2
f010571d:	08 00 
f010571f:	a0 f4 3f 15 f0       	mov    0xf0153ff4,%al
f0105724:	83 e0 e0             	and    $0xffffffe0,%eax
f0105727:	a2 f4 3f 15 f0       	mov    %al,0xf0153ff4
f010572c:	a0 f4 3f 15 f0       	mov    0xf0153ff4,%al
f0105731:	83 e0 1f             	and    $0x1f,%eax
f0105734:	a2 f4 3f 15 f0       	mov    %al,0xf0153ff4
f0105739:	a0 f5 3f 15 f0       	mov    0xf0153ff5,%al
f010573e:	83 e0 f0             	and    $0xfffffff0,%eax
f0105741:	83 c8 0e             	or     $0xe,%eax
f0105744:	a2 f5 3f 15 f0       	mov    %al,0xf0153ff5
f0105749:	a0 f5 3f 15 f0       	mov    0xf0153ff5,%al
f010574e:	83 e0 ef             	and    $0xffffffef,%eax
f0105751:	a2 f5 3f 15 f0       	mov    %al,0xf0153ff5
f0105756:	a0 f5 3f 15 f0       	mov    0xf0153ff5,%al
f010575b:	83 e0 9f             	and    $0xffffff9f,%eax
f010575e:	a2 f5 3f 15 f0       	mov    %al,0xf0153ff5
f0105763:	a0 f5 3f 15 f0       	mov    0xf0153ff5,%al
f0105768:	83 c8 80             	or     $0xffffff80,%eax
f010576b:	a2 f5 3f 15 f0       	mov    %al,0xf0153ff5
f0105770:	b8 64 5c 10 f0       	mov    $0xf0105c64,%eax
f0105775:	c1 e8 10             	shr    $0x10,%eax
f0105778:	66 a3 f6 3f 15 f0    	mov    %ax,0xf0153ff6
	SETGATE(idt[T_SYSCALL], 0, GD_KT , &SYSCALL_HANDLER, 3) ;
f010577e:	b8 68 5c 10 f0       	mov    $0xf0105c68,%eax
f0105783:	66 a3 00 41 15 f0    	mov    %ax,0xf0154100
f0105789:	66 c7 05 02 41 15 f0 	movw   $0x8,0xf0154102
f0105790:	08 00 
f0105792:	a0 04 41 15 f0       	mov    0xf0154104,%al
f0105797:	83 e0 e0             	and    $0xffffffe0,%eax
f010579a:	a2 04 41 15 f0       	mov    %al,0xf0154104
f010579f:	a0 04 41 15 f0       	mov    0xf0154104,%al
f01057a4:	83 e0 1f             	and    $0x1f,%eax
f01057a7:	a2 04 41 15 f0       	mov    %al,0xf0154104
f01057ac:	a0 05 41 15 f0       	mov    0xf0154105,%al
f01057b1:	83 e0 f0             	and    $0xfffffff0,%eax
f01057b4:	83 c8 0e             	or     $0xe,%eax
f01057b7:	a2 05 41 15 f0       	mov    %al,0xf0154105
f01057bc:	a0 05 41 15 f0       	mov    0xf0154105,%al
f01057c1:	83 e0 ef             	and    $0xffffffef,%eax
f01057c4:	a2 05 41 15 f0       	mov    %al,0xf0154105
f01057c9:	a0 05 41 15 f0       	mov    0xf0154105,%al
f01057ce:	83 c8 60             	or     $0x60,%eax
f01057d1:	a2 05 41 15 f0       	mov    %al,0xf0154105
f01057d6:	a0 05 41 15 f0       	mov    0xf0154105,%al
f01057db:	83 c8 80             	or     $0xffffff80,%eax
f01057de:	a2 05 41 15 f0       	mov    %al,0xf0154105
f01057e3:	b8 68 5c 10 f0       	mov    $0xf0105c68,%eax
f01057e8:	c1 e8 10             	shr    $0x10,%eax
f01057eb:	66 a3 06 41 15 f0    	mov    %ax,0xf0154106

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KERNEL_STACK_TOP;
f01057f1:	c7 05 84 47 15 f0 00 	movl   $0xefc00000,0xf0154784
f01057f8:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f01057fb:	66 c7 05 88 47 15 f0 	movw   $0x10,0xf0154788
f0105802:	10 00 

	// Initialize the TSS field of the gdt.
	gdt[GD_TSS >> 3] = SEG16(STS_T32A, (uint32) (&ts),
f0105804:	66 c7 05 a8 16 12 f0 	movw   $0x68,0xf01216a8
f010580b:	68 00 
f010580d:	b8 80 47 15 f0       	mov    $0xf0154780,%eax
f0105812:	66 a3 aa 16 12 f0    	mov    %ax,0xf01216aa
f0105818:	b8 80 47 15 f0       	mov    $0xf0154780,%eax
f010581d:	c1 e8 10             	shr    $0x10,%eax
f0105820:	a2 ac 16 12 f0       	mov    %al,0xf01216ac
f0105825:	a0 ad 16 12 f0       	mov    0xf01216ad,%al
f010582a:	83 e0 f0             	and    $0xfffffff0,%eax
f010582d:	83 c8 09             	or     $0x9,%eax
f0105830:	a2 ad 16 12 f0       	mov    %al,0xf01216ad
f0105835:	a0 ad 16 12 f0       	mov    0xf01216ad,%al
f010583a:	83 c8 10             	or     $0x10,%eax
f010583d:	a2 ad 16 12 f0       	mov    %al,0xf01216ad
f0105842:	a0 ad 16 12 f0       	mov    0xf01216ad,%al
f0105847:	83 e0 9f             	and    $0xffffff9f,%eax
f010584a:	a2 ad 16 12 f0       	mov    %al,0xf01216ad
f010584f:	a0 ad 16 12 f0       	mov    0xf01216ad,%al
f0105854:	83 c8 80             	or     $0xffffff80,%eax
f0105857:	a2 ad 16 12 f0       	mov    %al,0xf01216ad
f010585c:	a0 ae 16 12 f0       	mov    0xf01216ae,%al
f0105861:	83 e0 f0             	and    $0xfffffff0,%eax
f0105864:	a2 ae 16 12 f0       	mov    %al,0xf01216ae
f0105869:	a0 ae 16 12 f0       	mov    0xf01216ae,%al
f010586e:	83 e0 ef             	and    $0xffffffef,%eax
f0105871:	a2 ae 16 12 f0       	mov    %al,0xf01216ae
f0105876:	a0 ae 16 12 f0       	mov    0xf01216ae,%al
f010587b:	83 e0 df             	and    $0xffffffdf,%eax
f010587e:	a2 ae 16 12 f0       	mov    %al,0xf01216ae
f0105883:	a0 ae 16 12 f0       	mov    0xf01216ae,%al
f0105888:	83 c8 40             	or     $0x40,%eax
f010588b:	a2 ae 16 12 f0       	mov    %al,0xf01216ae
f0105890:	a0 ae 16 12 f0       	mov    0xf01216ae,%al
f0105895:	83 e0 7f             	and    $0x7f,%eax
f0105898:	a2 ae 16 12 f0       	mov    %al,0xf01216ae
f010589d:	b8 80 47 15 f0       	mov    $0xf0154780,%eax
f01058a2:	c1 e8 18             	shr    $0x18,%eax
f01058a5:	a2 af 16 12 f0       	mov    %al,0xf01216af
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS >> 3].sd_s = 0;
f01058aa:	a0 ad 16 12 f0       	mov    0xf01216ad,%al
f01058af:	83 e0 ef             	and    $0xffffffef,%eax
f01058b2:	a2 ad 16 12 f0       	mov    %al,0xf01216ad
f01058b7:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
}

static __inline void
ltr(uint16 sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01058bd:	66 8b 45 fe          	mov    -0x2(%ebp),%ax
f01058c1:	0f 00 d8             	ltr    %ax

	// Load the TSS
	ltr(GD_TSS);

	// Load the IDT
	asm volatile("lidt idt_pd");
f01058c4:	0f 01 1d 18 17 12 f0 	lidtl  0xf0121718
}
f01058cb:	90                   	nop
f01058cc:	c9                   	leave  
f01058cd:	c3                   	ret    

f01058ce <print_trapframe>:

void
print_trapframe(struct Trapframe *tf)
{
f01058ce:	55                   	push   %ebp
f01058cf:	89 e5                	mov    %esp,%ebp
f01058d1:	83 ec 08             	sub    $0x8,%esp
	cprintf("TRAP frame at %p\n", tf);
f01058d4:	83 ec 08             	sub    $0x8,%esp
f01058d7:	ff 75 08             	pushl  0x8(%ebp)
f01058da:	68 3b 9b 10 f0       	push   $0xf0109b3b
f01058df:	e8 d0 fd ff ff       	call   f01056b4 <cprintf>
f01058e4:	83 c4 10             	add    $0x10,%esp
	print_regs(&tf->tf_regs);
f01058e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01058ea:	83 ec 0c             	sub    $0xc,%esp
f01058ed:	50                   	push   %eax
f01058ee:	e8 f6 00 00 00       	call   f01059e9 <print_regs>
f01058f3:	83 c4 10             	add    $0x10,%esp
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01058f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01058f9:	8b 40 20             	mov    0x20(%eax),%eax
f01058fc:	0f b7 c0             	movzwl %ax,%eax
f01058ff:	83 ec 08             	sub    $0x8,%esp
f0105902:	50                   	push   %eax
f0105903:	68 4d 9b 10 f0       	push   $0xf0109b4d
f0105908:	e8 a7 fd ff ff       	call   f01056b4 <cprintf>
f010590d:	83 c4 10             	add    $0x10,%esp
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0105910:	8b 45 08             	mov    0x8(%ebp),%eax
f0105913:	8b 40 24             	mov    0x24(%eax),%eax
f0105916:	0f b7 c0             	movzwl %ax,%eax
f0105919:	83 ec 08             	sub    $0x8,%esp
f010591c:	50                   	push   %eax
f010591d:	68 60 9b 10 f0       	push   $0xf0109b60
f0105922:	e8 8d fd ff ff       	call   f01056b4 <cprintf>
f0105927:	83 c4 10             	add    $0x10,%esp
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010592a:	8b 45 08             	mov    0x8(%ebp),%eax
f010592d:	8b 40 28             	mov    0x28(%eax),%eax
f0105930:	83 ec 0c             	sub    $0xc,%esp
f0105933:	50                   	push   %eax
f0105934:	e8 a1 fd ff ff       	call   f01056da <trapname>
f0105939:	83 c4 10             	add    $0x10,%esp
f010593c:	89 c2                	mov    %eax,%edx
f010593e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105941:	8b 40 28             	mov    0x28(%eax),%eax
f0105944:	83 ec 04             	sub    $0x4,%esp
f0105947:	52                   	push   %edx
f0105948:	50                   	push   %eax
f0105949:	68 73 9b 10 f0       	push   $0xf0109b73
f010594e:	e8 61 fd ff ff       	call   f01056b4 <cprintf>
f0105953:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x\n", tf->tf_err);
f0105956:	8b 45 08             	mov    0x8(%ebp),%eax
f0105959:	8b 40 2c             	mov    0x2c(%eax),%eax
f010595c:	83 ec 08             	sub    $0x8,%esp
f010595f:	50                   	push   %eax
f0105960:	68 85 9b 10 f0       	push   $0xf0109b85
f0105965:	e8 4a fd ff ff       	call   f01056b4 <cprintf>
f010596a:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010596d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105970:	8b 40 30             	mov    0x30(%eax),%eax
f0105973:	83 ec 08             	sub    $0x8,%esp
f0105976:	50                   	push   %eax
f0105977:	68 94 9b 10 f0       	push   $0xf0109b94
f010597c:	e8 33 fd ff ff       	call   f01056b4 <cprintf>
f0105981:	83 c4 10             	add    $0x10,%esp
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0105984:	8b 45 08             	mov    0x8(%ebp),%eax
f0105987:	8b 40 34             	mov    0x34(%eax),%eax
f010598a:	0f b7 c0             	movzwl %ax,%eax
f010598d:	83 ec 08             	sub    $0x8,%esp
f0105990:	50                   	push   %eax
f0105991:	68 a3 9b 10 f0       	push   $0xf0109ba3
f0105996:	e8 19 fd ff ff       	call   f01056b4 <cprintf>
f010599b:	83 c4 10             	add    $0x10,%esp
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010599e:	8b 45 08             	mov    0x8(%ebp),%eax
f01059a1:	8b 40 38             	mov    0x38(%eax),%eax
f01059a4:	83 ec 08             	sub    $0x8,%esp
f01059a7:	50                   	push   %eax
f01059a8:	68 b6 9b 10 f0       	push   $0xf0109bb6
f01059ad:	e8 02 fd ff ff       	call   f01056b4 <cprintf>
f01059b2:	83 c4 10             	add    $0x10,%esp
	cprintf("  esp  0x%08x\n", tf->tf_esp);
f01059b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01059b8:	8b 40 3c             	mov    0x3c(%eax),%eax
f01059bb:	83 ec 08             	sub    $0x8,%esp
f01059be:	50                   	push   %eax
f01059bf:	68 c5 9b 10 f0       	push   $0xf0109bc5
f01059c4:	e8 eb fc ff ff       	call   f01056b4 <cprintf>
f01059c9:	83 c4 10             	add    $0x10,%esp
	cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01059cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01059cf:	8b 40 40             	mov    0x40(%eax),%eax
f01059d2:	0f b7 c0             	movzwl %ax,%eax
f01059d5:	83 ec 08             	sub    $0x8,%esp
f01059d8:	50                   	push   %eax
f01059d9:	68 d4 9b 10 f0       	push   $0xf0109bd4
f01059de:	e8 d1 fc ff ff       	call   f01056b4 <cprintf>
f01059e3:	83 c4 10             	add    $0x10,%esp
}
f01059e6:	90                   	nop
f01059e7:	c9                   	leave  
f01059e8:	c3                   	ret    

f01059e9 <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f01059e9:	55                   	push   %ebp
f01059ea:	89 e5                	mov    %esp,%ebp
f01059ec:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01059ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01059f2:	8b 00                	mov    (%eax),%eax
f01059f4:	83 ec 08             	sub    $0x8,%esp
f01059f7:	50                   	push   %eax
f01059f8:	68 e7 9b 10 f0       	push   $0xf0109be7
f01059fd:	e8 b2 fc ff ff       	call   f01056b4 <cprintf>
f0105a02:	83 c4 10             	add    $0x10,%esp
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0105a05:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a08:	8b 40 04             	mov    0x4(%eax),%eax
f0105a0b:	83 ec 08             	sub    $0x8,%esp
f0105a0e:	50                   	push   %eax
f0105a0f:	68 f6 9b 10 f0       	push   $0xf0109bf6
f0105a14:	e8 9b fc ff ff       	call   f01056b4 <cprintf>
f0105a19:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0105a1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a1f:	8b 40 08             	mov    0x8(%eax),%eax
f0105a22:	83 ec 08             	sub    $0x8,%esp
f0105a25:	50                   	push   %eax
f0105a26:	68 05 9c 10 f0       	push   $0xf0109c05
f0105a2b:	e8 84 fc ff ff       	call   f01056b4 <cprintf>
f0105a30:	83 c4 10             	add    $0x10,%esp
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0105a33:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a36:	8b 40 0c             	mov    0xc(%eax),%eax
f0105a39:	83 ec 08             	sub    $0x8,%esp
f0105a3c:	50                   	push   %eax
f0105a3d:	68 14 9c 10 f0       	push   $0xf0109c14
f0105a42:	e8 6d fc ff ff       	call   f01056b4 <cprintf>
f0105a47:	83 c4 10             	add    $0x10,%esp
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0105a4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a4d:	8b 40 10             	mov    0x10(%eax),%eax
f0105a50:	83 ec 08             	sub    $0x8,%esp
f0105a53:	50                   	push   %eax
f0105a54:	68 23 9c 10 f0       	push   $0xf0109c23
f0105a59:	e8 56 fc ff ff       	call   f01056b4 <cprintf>
f0105a5e:	83 c4 10             	add    $0x10,%esp
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0105a61:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a64:	8b 40 14             	mov    0x14(%eax),%eax
f0105a67:	83 ec 08             	sub    $0x8,%esp
f0105a6a:	50                   	push   %eax
f0105a6b:	68 32 9c 10 f0       	push   $0xf0109c32
f0105a70:	e8 3f fc ff ff       	call   f01056b4 <cprintf>
f0105a75:	83 c4 10             	add    $0x10,%esp
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0105a78:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a7b:	8b 40 18             	mov    0x18(%eax),%eax
f0105a7e:	83 ec 08             	sub    $0x8,%esp
f0105a81:	50                   	push   %eax
f0105a82:	68 41 9c 10 f0       	push   $0xf0109c41
f0105a87:	e8 28 fc ff ff       	call   f01056b4 <cprintf>
f0105a8c:	83 c4 10             	add    $0x10,%esp
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0105a8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a92:	8b 40 1c             	mov    0x1c(%eax),%eax
f0105a95:	83 ec 08             	sub    $0x8,%esp
f0105a98:	50                   	push   %eax
f0105a99:	68 50 9c 10 f0       	push   $0xf0109c50
f0105a9e:	e8 11 fc ff ff       	call   f01056b4 <cprintf>
f0105aa3:	83 c4 10             	add    $0x10,%esp
}
f0105aa6:	90                   	nop
f0105aa7:	c9                   	leave  
f0105aa8:	c3                   	ret    

f0105aa9 <trap_dispatch>:

static void
trap_dispatch(struct Trapframe *tf)
{
f0105aa9:	55                   	push   %ebp
f0105aaa:	89 e5                	mov    %esp,%ebp
f0105aac:	57                   	push   %edi
f0105aad:	56                   	push   %esi
f0105aae:	53                   	push   %ebx
f0105aaf:	83 ec 1c             	sub    $0x1c,%esp
	// Handle processor exceptions.
	// LAB 3: Your code here.

	if(tf->tf_trapno == T_PGFLT)
f0105ab2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ab5:	8b 40 28             	mov    0x28(%eax),%eax
f0105ab8:	83 f8 0e             	cmp    $0xe,%eax
f0105abb:	75 13                	jne    f0105ad0 <trap_dispatch+0x27>
	{
		page_fault_handler(tf);
f0105abd:	83 ec 0c             	sub    $0xc,%esp
f0105ac0:	ff 75 08             	pushl  0x8(%ebp)
f0105ac3:	e8 47 01 00 00       	call   f0105c0f <page_fault_handler>
f0105ac8:	83 c4 10             	add    $0x10,%esp
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0105acb:	e9 90 00 00 00       	jmp    f0105b60 <trap_dispatch+0xb7>

	if(tf->tf_trapno == T_PGFLT)
	{
		page_fault_handler(tf);
	}
	else if (tf->tf_trapno == T_SYSCALL)
f0105ad0:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ad3:	8b 40 28             	mov    0x28(%eax),%eax
f0105ad6:	83 f8 30             	cmp    $0x30,%eax
f0105ad9:	75 42                	jne    f0105b1d <trap_dispatch+0x74>
	{
		uint32 ret = syscall(tf->tf_regs.reg_eax
f0105adb:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ade:	8b 78 04             	mov    0x4(%eax),%edi
f0105ae1:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ae4:	8b 30                	mov    (%eax),%esi
f0105ae6:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ae9:	8b 58 10             	mov    0x10(%eax),%ebx
f0105aec:	8b 45 08             	mov    0x8(%ebp),%eax
f0105aef:	8b 48 18             	mov    0x18(%eax),%ecx
f0105af2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105af5:	8b 50 14             	mov    0x14(%eax),%edx
f0105af8:	8b 45 08             	mov    0x8(%ebp),%eax
f0105afb:	8b 40 1c             	mov    0x1c(%eax),%eax
f0105afe:	83 ec 08             	sub    $0x8,%esp
f0105b01:	57                   	push   %edi
f0105b02:	56                   	push   %esi
f0105b03:	53                   	push   %ebx
f0105b04:	51                   	push   %ecx
f0105b05:	52                   	push   %edx
f0105b06:	50                   	push   %eax
f0105b07:	e8 48 04 00 00       	call   f0105f54 <syscall>
f0105b0c:	83 c4 20             	add    $0x20,%esp
f0105b0f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			,tf->tf_regs.reg_edx
			,tf->tf_regs.reg_ecx
			,tf->tf_regs.reg_ebx
			,tf->tf_regs.reg_edi
					,tf->tf_regs.reg_esi);
		tf->tf_regs.reg_eax = ret;
f0105b12:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b15:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105b18:	89 50 1c             	mov    %edx,0x1c(%eax)
		else {
			env_destroy(curenv);
			return;
		}
	}
	return;
f0105b1b:	eb 43                	jmp    f0105b60 <trap_dispatch+0xb7>
		tf->tf_regs.reg_eax = ret;
	}
	else
	{
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0105b1d:	83 ec 0c             	sub    $0xc,%esp
f0105b20:	ff 75 08             	pushl  0x8(%ebp)
f0105b23:	e8 a6 fd ff ff       	call   f01058ce <print_trapframe>
f0105b28:	83 c4 10             	add    $0x10,%esp
		if (tf->tf_cs == GD_KT)
f0105b2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b2e:	8b 40 34             	mov    0x34(%eax),%eax
f0105b31:	66 83 f8 08          	cmp    $0x8,%ax
f0105b35:	75 17                	jne    f0105b4e <trap_dispatch+0xa5>
			panic("unhandled trap in kernel");
f0105b37:	83 ec 04             	sub    $0x4,%esp
f0105b3a:	68 5f 9c 10 f0       	push   $0xf0109c5f
f0105b3f:	68 8a 00 00 00       	push   $0x8a
f0105b44:	68 78 9c 10 f0       	push   $0xf0109c78
f0105b49:	e8 e0 a5 ff ff       	call   f010012e <_panic>
		else {
			env_destroy(curenv);
f0105b4e:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105b53:	83 ec 0c             	sub    $0xc,%esp
f0105b56:	50                   	push   %eax
f0105b57:	e8 a2 f9 ff ff       	call   f01054fe <env_destroy>
f0105b5c:	83 c4 10             	add    $0x10,%esp
			return;
f0105b5f:	90                   	nop
		}
	}
	return;
}
f0105b60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105b63:	5b                   	pop    %ebx
f0105b64:	5e                   	pop    %esi
f0105b65:	5f                   	pop    %edi
f0105b66:	5d                   	pop    %ebp
f0105b67:	c3                   	ret    

f0105b68 <trap>:

void
trap(struct Trapframe *tf)
{
f0105b68:	55                   	push   %ebp
f0105b69:	89 e5                	mov    %esp,%ebp
f0105b6b:	57                   	push   %edi
f0105b6c:	56                   	push   %esi
f0105b6d:	53                   	push   %ebx
f0105b6e:	83 ec 0c             	sub    $0xc,%esp
	//cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
f0105b71:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b74:	8b 40 34             	mov    0x34(%eax),%eax
f0105b77:	0f b7 c0             	movzwl %ax,%eax
f0105b7a:	83 e0 03             	and    $0x3,%eax
f0105b7d:	83 f8 03             	cmp    $0x3,%eax
f0105b80:	75 42                	jne    f0105bc4 <trap+0x5c>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0105b82:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105b87:	85 c0                	test   %eax,%eax
f0105b89:	75 19                	jne    f0105ba4 <trap+0x3c>
f0105b8b:	68 84 9c 10 f0       	push   $0xf0109c84
f0105b90:	68 8b 9c 10 f0       	push   $0xf0109c8b
f0105b95:	68 9d 00 00 00       	push   $0x9d
f0105b9a:	68 78 9c 10 f0       	push   $0xf0109c78
f0105b9f:	e8 8a a5 ff ff       	call   f010012e <_panic>
		curenv->env_tf = *tf;
f0105ba4:	8b 15 74 3f 15 f0    	mov    0xf0153f74,%edx
f0105baa:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bad:	89 c3                	mov    %eax,%ebx
f0105baf:	b8 11 00 00 00       	mov    $0x11,%eax
f0105bb4:	89 d7                	mov    %edx,%edi
f0105bb6:	89 de                	mov    %ebx,%esi
f0105bb8:	89 c1                	mov    %eax,%ecx
f0105bba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0105bbc:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105bc1:	89 45 08             	mov    %eax,0x8(%ebp)
	}

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0105bc4:	83 ec 0c             	sub    $0xc,%esp
f0105bc7:	ff 75 08             	pushl  0x8(%ebp)
f0105bca:	e8 da fe ff ff       	call   f0105aa9 <trap_dispatch>
f0105bcf:	83 c4 10             	add    $0x10,%esp

        // Return to the current environment, which should be runnable.
        assert(curenv && curenv->env_status == ENV_RUNNABLE);
f0105bd2:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105bd7:	85 c0                	test   %eax,%eax
f0105bd9:	74 0d                	je     f0105be8 <trap+0x80>
f0105bdb:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105be0:	8b 40 54             	mov    0x54(%eax),%eax
f0105be3:	83 f8 01             	cmp    $0x1,%eax
f0105be6:	74 19                	je     f0105c01 <trap+0x99>
f0105be8:	68 a0 9c 10 f0       	push   $0xf0109ca0
f0105bed:	68 8b 9c 10 f0       	push   $0xf0109c8b
f0105bf2:	68 a7 00 00 00       	push   $0xa7
f0105bf7:	68 78 9c 10 f0       	push   $0xf0109c78
f0105bfc:	e8 2d a5 ff ff       	call   f010012e <_panic>
        env_run(curenv);
f0105c01:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105c06:	83 ec 0c             	sub    $0xc,%esp
f0105c09:	50                   	push   %eax
f0105c0a:	e8 fd f2 ff ff       	call   f0104f0c <env_run>

f0105c0f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0105c0f:	55                   	push   %ebp
f0105c10:	89 e5                	mov    %esp,%ebp
f0105c12:	83 ec 18             	sub    $0x18,%esp

static __inline uint32
rcr2(void)
{
	uint32 val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0105c15:	0f 20 d0             	mov    %cr2,%eax
f0105c18:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
f0105c1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
	uint32 fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0105c1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0105c21:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c24:	8b 50 30             	mov    0x30(%eax),%edx
	curenv->env_id, fault_va, tf->tf_eip);
f0105c27:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0105c2c:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105c2f:	52                   	push   %edx
f0105c30:	ff 75 f4             	pushl  -0xc(%ebp)
f0105c33:	50                   	push   %eax
f0105c34:	68 d0 9c 10 f0       	push   $0xf0109cd0
f0105c39:	e8 76 fa ff ff       	call   f01056b4 <cprintf>
f0105c3e:	83 c4 10             	add    $0x10,%esp
	curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0105c41:	83 ec 0c             	sub    $0xc,%esp
f0105c44:	ff 75 08             	pushl  0x8(%ebp)
f0105c47:	e8 82 fc ff ff       	call   f01058ce <print_trapframe>
f0105c4c:	83 c4 10             	add    $0x10,%esp
	env_destroy(curenv);
f0105c4f:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105c54:	83 ec 0c             	sub    $0xc,%esp
f0105c57:	50                   	push   %eax
f0105c58:	e8 a1 f8 ff ff       	call   f01054fe <env_destroy>
f0105c5d:	83 c4 10             	add    $0x10,%esp

}
f0105c60:	90                   	nop
f0105c61:	c9                   	leave  
f0105c62:	c3                   	ret    
f0105c63:	90                   	nop

f0105c64 <PAGE_FAULT>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(PAGE_FAULT, T_PGFLT)		
f0105c64:	6a 0e                	push   $0xe
f0105c66:	eb 06                	jmp    f0105c6e <_alltraps>

f0105c68 <SYSCALL_HANDLER>:

TRAPHANDLER_NOEC(SYSCALL_HANDLER, T_SYSCALL)
f0105c68:	6a 00                	push   $0x0
f0105c6a:	6a 30                	push   $0x30
f0105c6c:	eb 00                	jmp    f0105c6e <_alltraps>

f0105c6e <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:

push %ds 
f0105c6e:	1e                   	push   %ds
push %es 
f0105c6f:	06                   	push   %es
pushal 	
f0105c70:	60                   	pusha  

mov $(GD_KD), %ax 
f0105c71:	66 b8 10 00          	mov    $0x10,%ax
mov %ax,%ds
f0105c75:	8e d8                	mov    %eax,%ds
mov %ax,%es
f0105c77:	8e c0                	mov    %eax,%es

push %esp
f0105c79:	54                   	push   %esp

call trap
f0105c7a:	e8 e9 fe ff ff       	call   f0105b68 <trap>

pop %ecx /* poping the pointer to the tf from the stack so that the stack top is at the values of the registers posuhed by pusha*/
f0105c7f:	59                   	pop    %ecx
popal 	
f0105c80:	61                   	popa   
pop %es 
f0105c81:	07                   	pop    %es
pop %ds    
f0105c82:	1f                   	pop    %ds

/*skipping the trap_no and the error code so that the stack top is at the old eip value*/
add $(8),%esp
f0105c83:	83 c4 08             	add    $0x8,%esp

iret
f0105c86:	cf                   	iret   

f0105c87 <to_frame_number>:
void	unmap_frame(uint32 *pgdir, void *va);
struct Frame_Info *get_frame_info(uint32 *ptr_page_directory, void *virtual_address, uint32 **ptr_page_table);
void decrement_references(struct Frame_Info* ptr_frame_info);

static inline uint32 to_frame_number(struct Frame_Info *ptr_frame_info)
{
f0105c87:	55                   	push   %ebp
f0105c88:	89 e5                	mov    %esp,%ebp
	return ptr_frame_info - frames_info;
f0105c8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c8d:	8b 15 c4 49 15 f0    	mov    0xf01549c4,%edx
f0105c93:	29 d0                	sub    %edx,%eax
f0105c95:	c1 f8 02             	sar    $0x2,%eax
f0105c98:	89 c2                	mov    %eax,%edx
f0105c9a:	89 d0                	mov    %edx,%eax
f0105c9c:	c1 e0 02             	shl    $0x2,%eax
f0105c9f:	01 d0                	add    %edx,%eax
f0105ca1:	c1 e0 02             	shl    $0x2,%eax
f0105ca4:	01 d0                	add    %edx,%eax
f0105ca6:	c1 e0 02             	shl    $0x2,%eax
f0105ca9:	01 d0                	add    %edx,%eax
f0105cab:	89 c1                	mov    %eax,%ecx
f0105cad:	c1 e1 08             	shl    $0x8,%ecx
f0105cb0:	01 c8                	add    %ecx,%eax
f0105cb2:	89 c1                	mov    %eax,%ecx
f0105cb4:	c1 e1 10             	shl    $0x10,%ecx
f0105cb7:	01 c8                	add    %ecx,%eax
f0105cb9:	01 c0                	add    %eax,%eax
f0105cbb:	01 d0                	add    %edx,%eax
}
f0105cbd:	5d                   	pop    %ebp
f0105cbe:	c3                   	ret    

f0105cbf <to_physical_address>:

static inline uint32 to_physical_address(struct Frame_Info *ptr_frame_info)
{
f0105cbf:	55                   	push   %ebp
f0105cc0:	89 e5                	mov    %esp,%ebp
	return to_frame_number(ptr_frame_info) << PGSHIFT;
f0105cc2:	ff 75 08             	pushl  0x8(%ebp)
f0105cc5:	e8 bd ff ff ff       	call   f0105c87 <to_frame_number>
f0105cca:	83 c4 04             	add    $0x4,%esp
f0105ccd:	c1 e0 0c             	shl    $0xc,%eax
}
f0105cd0:	c9                   	leave  
f0105cd1:	c3                   	ret    

f0105cd2 <sys_cputs>:

// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void sys_cputs(const char *s, uint32 len)
{
f0105cd2:	55                   	push   %ebp
f0105cd3:	89 e5                	mov    %esp,%ebp
f0105cd5:	83 ec 08             	sub    $0x8,%esp
	// Destroy the environment if not.
	
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0105cd8:	83 ec 04             	sub    $0x4,%esp
f0105cdb:	ff 75 08             	pushl  0x8(%ebp)
f0105cde:	ff 75 0c             	pushl  0xc(%ebp)
f0105ce1:	68 90 9e 10 f0       	push   $0xf0109e90
f0105ce6:	e8 c9 f9 ff ff       	call   f01056b4 <cprintf>
f0105ceb:	83 c4 10             	add    $0x10,%esp
}
f0105cee:	90                   	nop
f0105cef:	c9                   	leave  
f0105cf0:	c3                   	ret    

f0105cf1 <sys_cgetc>:

// Read a character from the system console.
// Returns the character.
static int
sys_cgetc(void)
{
f0105cf1:	55                   	push   %ebp
f0105cf2:	89 e5                	mov    %esp,%ebp
f0105cf4:	83 ec 18             	sub    $0x18,%esp
	int c;

	// The cons_getc() primitive doesn't wait for a character,
	// but the sys_cgetc() system call does.
	while ((c = cons_getc()) == 0)
f0105cf7:	e8 6d ab ff ff       	call   f0100869 <cons_getc>
f0105cfc:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0105cff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0105d03:	74 f2                	je     f0105cf7 <sys_cgetc+0x6>
		/* do nothing */;

	return c;
f0105d05:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0105d08:	c9                   	leave  
f0105d09:	c3                   	ret    

f0105d0a <sys_getenvid>:

// Returns the current environment's envid.
static int32 sys_getenvid(void)
{
f0105d0a:	55                   	push   %ebp
f0105d0b:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f0105d0d:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105d12:	8b 40 4c             	mov    0x4c(%eax),%eax
}
f0105d15:	5d                   	pop    %ebp
f0105d16:	c3                   	ret    

f0105d17 <sys_env_destroy>:
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int sys_env_destroy(int32  envid)
{
f0105d17:	55                   	push   %ebp
f0105d18:	89 e5                	mov    %esp,%ebp
f0105d1a:	83 ec 18             	sub    $0x18,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0105d1d:	83 ec 04             	sub    $0x4,%esp
f0105d20:	6a 01                	push   $0x1
f0105d22:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0105d25:	50                   	push   %eax
f0105d26:	ff 75 08             	pushl  0x8(%ebp)
f0105d29:	e8 58 c8 ff ff       	call   f0102586 <envid2env>
f0105d2e:	83 c4 10             	add    $0x10,%esp
f0105d31:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0105d34:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0105d38:	79 05                	jns    f0105d3f <sys_env_destroy+0x28>
		return r;
f0105d3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105d3d:	eb 5b                	jmp    f0105d9a <sys_env_destroy+0x83>
	if (e == curenv)
f0105d3f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105d42:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105d47:	39 c2                	cmp    %eax,%edx
f0105d49:	75 1b                	jne    f0105d66 <sys_env_destroy+0x4f>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0105d4b:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105d50:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105d53:	83 ec 08             	sub    $0x8,%esp
f0105d56:	50                   	push   %eax
f0105d57:	68 95 9e 10 f0       	push   $0xf0109e95
f0105d5c:	e8 53 f9 ff ff       	call   f01056b4 <cprintf>
f0105d61:	83 c4 10             	add    $0x10,%esp
f0105d64:	eb 20                	jmp    f0105d86 <sys_env_destroy+0x6f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0105d66:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105d69:	8b 50 4c             	mov    0x4c(%eax),%edx
f0105d6c:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105d71:	8b 40 4c             	mov    0x4c(%eax),%eax
f0105d74:	83 ec 04             	sub    $0x4,%esp
f0105d77:	52                   	push   %edx
f0105d78:	50                   	push   %eax
f0105d79:	68 b0 9e 10 f0       	push   $0xf0109eb0
f0105d7e:	e8 31 f9 ff ff       	call   f01056b4 <cprintf>
f0105d83:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0105d86:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105d89:	83 ec 0c             	sub    $0xc,%esp
f0105d8c:	50                   	push   %eax
f0105d8d:	e8 6c f7 ff ff       	call   f01054fe <env_destroy>
f0105d92:	83 c4 10             	add    $0x10,%esp
	return 0;
f0105d95:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105d9a:	c9                   	leave  
f0105d9b:	c3                   	ret    

f0105d9c <sys_env_sleep>:

static void sys_env_sleep()
{
f0105d9c:	55                   	push   %ebp
f0105d9d:	89 e5                	mov    %esp,%ebp
f0105d9f:	83 ec 08             	sub    $0x8,%esp
	env_run_cmd_prmpt();
f0105da2:	e8 72 f7 ff ff       	call   f0105519 <env_run_cmd_prmpt>
}
f0105da7:	90                   	nop
f0105da8:	c9                   	leave  
f0105da9:	c3                   	ret    

f0105daa <sys_allocate_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_allocate_page(void *va, int perm)
{
f0105daa:	55                   	push   %ebp
f0105dab:	89 e5                	mov    %esp,%ebp
f0105dad:	83 ec 28             	sub    $0x28,%esp
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!
	
	int r;
	struct Env *e = curenv;
f0105db0:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105db5:	89 45 f4             	mov    %eax,-0xc(%ebp)

	//if ((r = envid2env(envid, &e, 1)) < 0)
		//return r;
	
	struct Frame_Info *ptr_frame_info ;
	r = allocate_frame(&ptr_frame_info) ;
f0105db8:	83 ec 0c             	sub    $0xc,%esp
f0105dbb:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0105dbe:	50                   	push   %eax
f0105dbf:	e8 3b ec ff ff       	call   f01049ff <allocate_frame>
f0105dc4:	83 c4 10             	add    $0x10,%esp
f0105dc7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0105dca:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0105dce:	75 08                	jne    f0105dd8 <sys_allocate_page+0x2e>
		return r ;
f0105dd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105dd3:	e9 cc 00 00 00       	jmp    f0105ea4 <sys_allocate_page+0xfa>
	
	//check virtual address to be paged_aligned and < USER_TOP
	if ((uint32)va >= USER_TOP || (uint32)va % PAGE_SIZE != 0)
f0105dd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ddb:	3d ff ff bf ee       	cmp    $0xeebfffff,%eax
f0105de0:	77 0c                	ja     f0105dee <sys_allocate_page+0x44>
f0105de2:	8b 45 08             	mov    0x8(%ebp),%eax
f0105de5:	25 ff 0f 00 00       	and    $0xfff,%eax
f0105dea:	85 c0                	test   %eax,%eax
f0105dec:	74 0a                	je     f0105df8 <sys_allocate_page+0x4e>
		return E_INVAL;
f0105dee:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105df3:	e9 ac 00 00 00       	jmp    f0105ea4 <sys_allocate_page+0xfa>
	
	//check permissions to be appropriatess
	if ((perm & (~PERM_AVAILABLE & ~PERM_WRITEABLE)) != (PERM_USER))
f0105df8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105dfb:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0105e00:	83 f8 04             	cmp    $0x4,%eax
f0105e03:	74 0a                	je     f0105e0f <sys_allocate_page+0x65>
		return E_INVAL;
f0105e05:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105e0a:	e9 95 00 00 00       	jmp    f0105ea4 <sys_allocate_page+0xfa>
	
			
	uint32 physical_address = to_physical_address(ptr_frame_info) ;
f0105e0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105e12:	83 ec 0c             	sub    $0xc,%esp
f0105e15:	50                   	push   %eax
f0105e16:	e8 a4 fe ff ff       	call   f0105cbf <to_physical_address>
f0105e1b:	83 c4 10             	add    $0x10,%esp
f0105e1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	memset(K_VIRTUAL_ADDRESS(physical_address), 0, PAGE_SIZE);
f0105e21:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105e24:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0105e27:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105e2a:	c1 e8 0c             	shr    $0xc,%eax
f0105e2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105e30:	a1 e8 47 15 f0       	mov    0xf01547e8,%eax
f0105e35:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0105e38:	72 14                	jb     f0105e4e <sys_allocate_page+0xa4>
f0105e3a:	ff 75 e8             	pushl  -0x18(%ebp)
f0105e3d:	68 c8 9e 10 f0       	push   $0xf0109ec8
f0105e42:	6a 7a                	push   $0x7a
f0105e44:	68 f7 9e 10 f0       	push   $0xf0109ef7
f0105e49:	e8 e0 a2 ff ff       	call   f010012e <_panic>
f0105e4e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105e51:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0105e56:	83 ec 04             	sub    $0x4,%esp
f0105e59:	68 00 10 00 00       	push   $0x1000
f0105e5e:	6a 00                	push   $0x0
f0105e60:	50                   	push   %eax
f0105e61:	e8 31 0f 00 00       	call   f0106d97 <memset>
f0105e66:	83 c4 10             	add    $0x10,%esp
		
	r = map_frame(e->env_pgdir, ptr_frame_info, va, perm) ;
f0105e69:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0105e6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105e6f:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105e72:	ff 75 0c             	pushl  0xc(%ebp)
f0105e75:	ff 75 08             	pushl  0x8(%ebp)
f0105e78:	52                   	push   %edx
f0105e79:	50                   	push   %eax
f0105e7a:	e8 8d ed ff ff       	call   f0104c0c <map_frame>
f0105e7f:	83 c4 10             	add    $0x10,%esp
f0105e82:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (r == E_NO_MEM)
f0105e85:	83 7d f0 fc          	cmpl   $0xfffffffc,-0x10(%ebp)
f0105e89:	75 14                	jne    f0105e9f <sys_allocate_page+0xf5>
	{
		decrement_references(ptr_frame_info);
f0105e8b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105e8e:	83 ec 0c             	sub    $0xc,%esp
f0105e91:	50                   	push   %eax
f0105e92:	e8 06 ec ff ff       	call   f0104a9d <decrement_references>
f0105e97:	83 c4 10             	add    $0x10,%esp
		return r;
f0105e9a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105e9d:	eb 05                	jmp    f0105ea4 <sys_allocate_page+0xfa>
	}
	return 0 ;
f0105e9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105ea4:	c9                   	leave  
f0105ea5:	c3                   	ret    

f0105ea6 <sys_get_page>:
//	E_INVAL if va >= UTOP, or va is not page-aligned.
//	E_INVAL if perm is inappropriate (see above).
//	E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_get_page(void *va, int perm)
{
f0105ea6:	55                   	push   %ebp
f0105ea7:	89 e5                	mov    %esp,%ebp
f0105ea9:	83 ec 08             	sub    $0x8,%esp
	return get_page(curenv->env_pgdir, va, perm) ;
f0105eac:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105eb1:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105eb4:	83 ec 04             	sub    $0x4,%esp
f0105eb7:	ff 75 0c             	pushl  0xc(%ebp)
f0105eba:	ff 75 08             	pushl  0x8(%ebp)
f0105ebd:	50                   	push   %eax
f0105ebe:	e8 c7 ee ff ff       	call   f0104d8a <get_page>
f0105ec3:	83 c4 10             	add    $0x10,%esp
}
f0105ec6:	c9                   	leave  
f0105ec7:	c3                   	ret    

f0105ec8 <sys_map_frame>:
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int sys_map_frame(int32 srcenvid, void *srcva, int32 dstenvid, void *dstva, int perm)
{
f0105ec8:	55                   	push   %ebp
f0105ec9:	89 e5                	mov    %esp,%ebp
f0105ecb:	83 ec 08             	sub    $0x8,%esp
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	panic("sys_map_frame not implemented");
f0105ece:	83 ec 04             	sub    $0x4,%esp
f0105ed1:	68 06 9f 10 f0       	push   $0xf0109f06
f0105ed6:	68 b1 00 00 00       	push   $0xb1
f0105edb:	68 f7 9e 10 f0       	push   $0xf0109ef7
f0105ee0:	e8 49 a2 ff ff       	call   f010012e <_panic>

f0105ee5 <sys_unmap_frame>:
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int sys_unmap_frame(int32 envid, void *va)
{
f0105ee5:	55                   	push   %ebp
f0105ee6:	89 e5                	mov    %esp,%ebp
f0105ee8:	83 ec 08             	sub    $0x8,%esp
	// Hint: This function is a wrapper around page_remove().
	
	// LAB 4: Your code here.
	panic("sys_page_unmap not implemented");
f0105eeb:	83 ec 04             	sub    $0x4,%esp
f0105eee:	68 24 9f 10 f0       	push   $0xf0109f24
f0105ef3:	68 c0 00 00 00       	push   $0xc0
f0105ef8:	68 f7 9e 10 f0       	push   $0xf0109ef7
f0105efd:	e8 2c a2 ff ff       	call   f010012e <_panic>

f0105f02 <sys_calculate_required_frames>:
}

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
f0105f02:	55                   	push   %ebp
f0105f03:	89 e5                	mov    %esp,%ebp
f0105f05:	83 ec 08             	sub    $0x8,%esp
	return calculate_required_frames(curenv->env_pgdir, start_virtual_address, size); 
f0105f08:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105f0d:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105f10:	83 ec 04             	sub    $0x4,%esp
f0105f13:	ff 75 0c             	pushl  0xc(%ebp)
f0105f16:	ff 75 08             	pushl  0x8(%ebp)
f0105f19:	50                   	push   %eax
f0105f1a:	e8 88 ee ff ff       	call   f0104da7 <calculate_required_frames>
f0105f1f:	83 c4 10             	add    $0x10,%esp
}
f0105f22:	c9                   	leave  
f0105f23:	c3                   	ret    

f0105f24 <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
f0105f24:	55                   	push   %ebp
f0105f25:	89 e5                	mov    %esp,%ebp
f0105f27:	83 ec 08             	sub    $0x8,%esp
	return calculate_free_frames();
f0105f2a:	e8 95 ee ff ff       	call   f0104dc4 <calculate_free_frames>
}
f0105f2f:	c9                   	leave  
f0105f30:	c3                   	ret    

f0105f31 <sys_freeMem>:
void sys_freeMem(void* start_virtual_address, uint32 size)
{
f0105f31:	55                   	push   %ebp
f0105f32:	89 e5                	mov    %esp,%ebp
f0105f34:	83 ec 08             	sub    $0x8,%esp
	freeMem((uint32*)curenv->env_pgdir, (void*)start_virtual_address, size);
f0105f37:	a1 74 3f 15 f0       	mov    0xf0153f74,%eax
f0105f3c:	8b 40 5c             	mov    0x5c(%eax),%eax
f0105f3f:	83 ec 04             	sub    $0x4,%esp
f0105f42:	ff 75 0c             	pushl  0xc(%ebp)
f0105f45:	ff 75 08             	pushl  0x8(%ebp)
f0105f48:	50                   	push   %eax
f0105f49:	e8 a3 ee ff ff       	call   f0104df1 <freeMem>
f0105f4e:	83 c4 10             	add    $0x10,%esp
	return;
f0105f51:	90                   	nop
}
f0105f52:	c9                   	leave  
f0105f53:	c3                   	ret    

f0105f54 <syscall>:
// Dispatches to the correct kernel function, passing the arguments.
uint32
syscall(uint32 syscallno, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
f0105f54:	55                   	push   %ebp
f0105f55:	89 e5                	mov    %esp,%ebp
f0105f57:	56                   	push   %esi
f0105f58:	53                   	push   %ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	switch(syscallno)
f0105f59:	83 7d 08 0c          	cmpl   $0xc,0x8(%ebp)
f0105f5d:	0f 87 19 01 00 00    	ja     f010607c <syscall+0x128>
f0105f63:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f66:	c1 e0 02             	shl    $0x2,%eax
f0105f69:	05 44 9f 10 f0       	add    $0xf0109f44,%eax
f0105f6e:	8b 00                	mov    (%eax),%eax
f0105f70:	ff e0                	jmp    *%eax
	{
		case SYS_cputs:
			sys_cputs((const char*)a1,a2);
f0105f72:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105f75:	83 ec 08             	sub    $0x8,%esp
f0105f78:	ff 75 10             	pushl  0x10(%ebp)
f0105f7b:	50                   	push   %eax
f0105f7c:	e8 51 fd ff ff       	call   f0105cd2 <sys_cputs>
f0105f81:	83 c4 10             	add    $0x10,%esp
			return 0;
f0105f84:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f89:	e9 f3 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f0105f8e:	e8 5e fd ff ff       	call   f0105cf1 <sys_cgetc>
f0105f93:	e9 e9 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0105f98:	e8 6d fd ff ff       	call   f0105d0a <sys_getenvid>
f0105f9d:	e9 df 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_env_destroy:
			return sys_env_destroy(a1);
f0105fa2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105fa5:	83 ec 0c             	sub    $0xc,%esp
f0105fa8:	50                   	push   %eax
f0105fa9:	e8 69 fd ff ff       	call   f0105d17 <sys_env_destroy>
f0105fae:	83 c4 10             	add    $0x10,%esp
f0105fb1:	e9 cb 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_env_sleep:
			sys_env_sleep();
f0105fb6:	e8 e1 fd ff ff       	call   f0105d9c <sys_env_sleep>
			return 0;
f0105fbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0105fc0:	e9 bc 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_calc_req_frames:
			return sys_calculate_required_frames(a1, a2);			
f0105fc5:	83 ec 08             	sub    $0x8,%esp
f0105fc8:	ff 75 10             	pushl  0x10(%ebp)
f0105fcb:	ff 75 0c             	pushl  0xc(%ebp)
f0105fce:	e8 2f ff ff ff       	call   f0105f02 <sys_calculate_required_frames>
f0105fd3:	83 c4 10             	add    $0x10,%esp
f0105fd6:	e9 a6 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_calc_free_frames:
			return sys_calculate_free_frames();			
f0105fdb:	e8 44 ff ff ff       	call   f0105f24 <sys_calculate_free_frames>
f0105fe0:	e9 9c 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_freeMem:
			sys_freeMem((void*)a1, a2);
f0105fe5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105fe8:	83 ec 08             	sub    $0x8,%esp
f0105feb:	ff 75 10             	pushl  0x10(%ebp)
f0105fee:	50                   	push   %eax
f0105fef:	e8 3d ff ff ff       	call   f0105f31 <sys_freeMem>
f0105ff4:	83 c4 10             	add    $0x10,%esp
			return 0;			
f0105ff7:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ffc:	e9 80 00 00 00       	jmp    f0106081 <syscall+0x12d>
			break;
		//======================
		
		case SYS_allocate_page:
			sys_allocate_page((void*)a1, a2);
f0106001:	8b 55 10             	mov    0x10(%ebp),%edx
f0106004:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106007:	83 ec 08             	sub    $0x8,%esp
f010600a:	52                   	push   %edx
f010600b:	50                   	push   %eax
f010600c:	e8 99 fd ff ff       	call   f0105daa <sys_allocate_page>
f0106011:	83 c4 10             	add    $0x10,%esp
			return 0;
f0106014:	b8 00 00 00 00       	mov    $0x0,%eax
f0106019:	eb 66                	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_get_page:
			sys_get_page((void*)a1, a2);
f010601b:	8b 55 10             	mov    0x10(%ebp),%edx
f010601e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106021:	83 ec 08             	sub    $0x8,%esp
f0106024:	52                   	push   %edx
f0106025:	50                   	push   %eax
f0106026:	e8 7b fe ff ff       	call   f0105ea6 <sys_get_page>
f010602b:	83 c4 10             	add    $0x10,%esp
			return 0;
f010602e:	b8 00 00 00 00       	mov    $0x0,%eax
f0106033:	eb 4c                	jmp    f0106081 <syscall+0x12d>
		break;case SYS_map_frame:
			sys_map_frame(a1, (void*)a2, a3, (void*)a4, a5);
f0106035:	8b 75 1c             	mov    0x1c(%ebp),%esi
f0106038:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010603b:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010603e:	8b 55 10             	mov    0x10(%ebp),%edx
f0106041:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106044:	83 ec 0c             	sub    $0xc,%esp
f0106047:	56                   	push   %esi
f0106048:	53                   	push   %ebx
f0106049:	51                   	push   %ecx
f010604a:	52                   	push   %edx
f010604b:	50                   	push   %eax
f010604c:	e8 77 fe ff ff       	call   f0105ec8 <sys_map_frame>
f0106051:	83 c4 20             	add    $0x20,%esp
			return 0;
f0106054:	b8 00 00 00 00       	mov    $0x0,%eax
f0106059:	eb 26                	jmp    f0106081 <syscall+0x12d>
			break;
		case SYS_unmap_frame:
			sys_unmap_frame(a1, (void*)a2);
f010605b:	8b 55 10             	mov    0x10(%ebp),%edx
f010605e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106061:	83 ec 08             	sub    $0x8,%esp
f0106064:	52                   	push   %edx
f0106065:	50                   	push   %eax
f0106066:	e8 7a fe ff ff       	call   f0105ee5 <sys_unmap_frame>
f010606b:	83 c4 10             	add    $0x10,%esp
			return 0;
f010606e:	b8 00 00 00 00       	mov    $0x0,%eax
f0106073:	eb 0c                	jmp    f0106081 <syscall+0x12d>
			break;
		case NSYSCALLS:	
			return 	-E_INVAL;
f0106075:	b8 03 00 00 00       	mov    $0x3,%eax
f010607a:	eb 05                	jmp    f0106081 <syscall+0x12d>
			break;
	}
	//panic("syscall not implemented");
	return -E_INVAL;
f010607c:	b8 03 00 00 00       	mov    $0x3,%eax
}
f0106081:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0106084:	5b                   	pop    %ebx
f0106085:	5e                   	pop    %esi
f0106086:	5d                   	pop    %ebp
f0106087:	c3                   	ret    

f0106088 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
f0106088:	55                   	push   %ebp
f0106089:	89 e5                	mov    %esp,%ebp
f010608b:	83 ec 20             	sub    $0x20,%esp
	int l = *region_left, r = *region_right, any_matches = 0;
f010608e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106091:	8b 00                	mov    (%eax),%eax
f0106093:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0106096:	8b 45 10             	mov    0x10(%ebp),%eax
f0106099:	8b 00                	mov    (%eax),%eax
f010609b:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010609e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	
	while (l <= r) {
f01060a5:	e9 ca 00 00 00       	jmp    f0106174 <stab_binsearch+0xec>
		int true_m = (l + r) / 2, m = true_m;
f01060aa:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01060ad:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01060b0:	01 d0                	add    %edx,%eax
f01060b2:	89 c2                	mov    %eax,%edx
f01060b4:	c1 ea 1f             	shr    $0x1f,%edx
f01060b7:	01 d0                	add    %edx,%eax
f01060b9:	d1 f8                	sar    %eax
f01060bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01060be:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01060c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01060c4:	eb 03                	jmp    f01060c9 <stab_binsearch+0x41>
			m--;
f01060c6:	ff 4d f0             	decl   -0x10(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01060c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01060cc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01060cf:	7c 1e                	jl     f01060ef <stab_binsearch+0x67>
f01060d1:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01060d4:	89 d0                	mov    %edx,%eax
f01060d6:	01 c0                	add    %eax,%eax
f01060d8:	01 d0                	add    %edx,%eax
f01060da:	c1 e0 02             	shl    $0x2,%eax
f01060dd:	89 c2                	mov    %eax,%edx
f01060df:	8b 45 08             	mov    0x8(%ebp),%eax
f01060e2:	01 d0                	add    %edx,%eax
f01060e4:	8a 40 04             	mov    0x4(%eax),%al
f01060e7:	0f b6 c0             	movzbl %al,%eax
f01060ea:	3b 45 14             	cmp    0x14(%ebp),%eax
f01060ed:	75 d7                	jne    f01060c6 <stab_binsearch+0x3e>
			m--;
		if (m < l) {	// no match in [l, m]
f01060ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01060f2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01060f5:	7d 09                	jge    f0106100 <stab_binsearch+0x78>
			l = true_m + 1;
f01060f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01060fa:	40                   	inc    %eax
f01060fb:	89 45 fc             	mov    %eax,-0x4(%ebp)
			continue;
f01060fe:	eb 74                	jmp    f0106174 <stab_binsearch+0xec>
		}

		// actual binary search
		any_matches = 1;
f0106100:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
		if (stabs[m].n_value < addr) {
f0106107:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010610a:	89 d0                	mov    %edx,%eax
f010610c:	01 c0                	add    %eax,%eax
f010610e:	01 d0                	add    %edx,%eax
f0106110:	c1 e0 02             	shl    $0x2,%eax
f0106113:	89 c2                	mov    %eax,%edx
f0106115:	8b 45 08             	mov    0x8(%ebp),%eax
f0106118:	01 d0                	add    %edx,%eax
f010611a:	8b 40 08             	mov    0x8(%eax),%eax
f010611d:	3b 45 18             	cmp    0x18(%ebp),%eax
f0106120:	73 11                	jae    f0106133 <stab_binsearch+0xab>
			*region_left = m;
f0106122:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106125:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0106128:	89 10                	mov    %edx,(%eax)
			l = true_m + 1;
f010612a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010612d:	40                   	inc    %eax
f010612e:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0106131:	eb 41                	jmp    f0106174 <stab_binsearch+0xec>
		} else if (stabs[m].n_value > addr) {
f0106133:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0106136:	89 d0                	mov    %edx,%eax
f0106138:	01 c0                	add    %eax,%eax
f010613a:	01 d0                	add    %edx,%eax
f010613c:	c1 e0 02             	shl    $0x2,%eax
f010613f:	89 c2                	mov    %eax,%edx
f0106141:	8b 45 08             	mov    0x8(%ebp),%eax
f0106144:	01 d0                	add    %edx,%eax
f0106146:	8b 40 08             	mov    0x8(%eax),%eax
f0106149:	3b 45 18             	cmp    0x18(%ebp),%eax
f010614c:	76 14                	jbe    f0106162 <stab_binsearch+0xda>
			*region_right = m - 1;
f010614e:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0106151:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106154:	8b 45 10             	mov    0x10(%ebp),%eax
f0106157:	89 10                	mov    %edx,(%eax)
			r = m - 1;
f0106159:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010615c:	48                   	dec    %eax
f010615d:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0106160:	eb 12                	jmp    f0106174 <stab_binsearch+0xec>
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0106162:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106165:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0106168:	89 10                	mov    %edx,(%eax)
			l = m;
f010616a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010616d:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f0106170:	83 45 18 04          	addl   $0x4,0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uint32*  addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0106174:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106177:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f010617a:	0f 8e 2a ff ff ff    	jle    f01060aa <stab_binsearch+0x22>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0106180:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0106184:	75 0f                	jne    f0106195 <stab_binsearch+0x10d>
		*region_right = *region_left - 1;
f0106186:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106189:	8b 00                	mov    (%eax),%eax
f010618b:	8d 50 ff             	lea    -0x1(%eax),%edx
f010618e:	8b 45 10             	mov    0x10(%ebp),%eax
f0106191:	89 10                	mov    %edx,(%eax)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0106193:	eb 3d                	jmp    f01061d2 <stab_binsearch+0x14a>

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0106195:	8b 45 10             	mov    0x10(%ebp),%eax
f0106198:	8b 00                	mov    (%eax),%eax
f010619a:	89 45 fc             	mov    %eax,-0x4(%ebp)
f010619d:	eb 03                	jmp    f01061a2 <stab_binsearch+0x11a>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010619f:	ff 4d fc             	decl   -0x4(%ebp)
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01061a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061a5:	8b 00                	mov    (%eax),%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01061a7:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01061aa:	7d 1e                	jge    f01061ca <stab_binsearch+0x142>
		     l > *region_left && stabs[l].n_type != type;
f01061ac:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01061af:	89 d0                	mov    %edx,%eax
f01061b1:	01 c0                	add    %eax,%eax
f01061b3:	01 d0                	add    %edx,%eax
f01061b5:	c1 e0 02             	shl    $0x2,%eax
f01061b8:	89 c2                	mov    %eax,%edx
f01061ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01061bd:	01 d0                	add    %edx,%eax
f01061bf:	8a 40 04             	mov    0x4(%eax),%al
f01061c2:	0f b6 c0             	movzbl %al,%eax
f01061c5:	3b 45 14             	cmp    0x14(%ebp),%eax
f01061c8:	75 d5                	jne    f010619f <stab_binsearch+0x117>
		     l--)
			/* do nothing */;
		*region_left = l;
f01061ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061cd:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01061d0:	89 10                	mov    %edx,(%eax)
	}
}
f01061d2:	90                   	nop
f01061d3:	c9                   	leave  
f01061d4:	c3                   	ret    

f01061d5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uint32*  addr, struct Eipdebuginfo *info)
{
f01061d5:	55                   	push   %ebp
f01061d6:	89 e5                	mov    %esp,%ebp
f01061d8:	83 ec 38             	sub    $0x38,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01061db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061de:	c7 00 78 9f 10 f0    	movl   $0xf0109f78,(%eax)
	info->eip_line = 0;
f01061e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061e7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	info->eip_fn_name = "<unknown>";
f01061ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061f1:	c7 40 08 78 9f 10 f0 	movl   $0xf0109f78,0x8(%eax)
	info->eip_fn_namelen = 9;
f01061f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01061fb:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
	info->eip_fn_addr = addr;
f0106202:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106205:	8b 55 08             	mov    0x8(%ebp),%edx
f0106208:	89 50 10             	mov    %edx,0x10(%eax)
	info->eip_fn_narg = 0;
f010620b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010620e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

	// Find the relevant set of stabs
	if ((uint32)addr >= USER_LIMIT) {
f0106215:	8b 45 08             	mov    0x8(%ebp),%eax
f0106218:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f010621d:	76 1e                	jbe    f010623d <debuginfo_eip+0x68>
		stabs = __STAB_BEGIN__;
f010621f:	c7 45 f4 d0 a1 10 f0 	movl   $0xf010a1d0,-0xc(%ebp)
		stab_end = __STAB_END__;
f0106226:	c7 45 f0 28 4f 11 f0 	movl   $0xf0114f28,-0x10(%ebp)
		stabstr = __STABSTR_BEGIN__;
f010622d:	c7 45 ec 29 4f 11 f0 	movl   $0xf0114f29,-0x14(%ebp)
		stabstr_end = __STABSTR_END__;
f0106234:	c7 45 e8 3b 8f 11 f0 	movl   $0xf0118f3b,-0x18(%ebp)
f010623b:	eb 2a                	jmp    f0106267 <debuginfo_eip+0x92>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f010623d:	c7 45 e0 00 00 20 00 	movl   $0x200000,-0x20(%ebp)

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		
		stabs = usd->stabs;
f0106244:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0106247:	8b 00                	mov    (%eax),%eax
f0106249:	89 45 f4             	mov    %eax,-0xc(%ebp)
		stab_end = usd->stab_end;
f010624c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010624f:	8b 40 04             	mov    0x4(%eax),%eax
f0106252:	89 45 f0             	mov    %eax,-0x10(%ebp)
		stabstr = usd->stabstr;
f0106255:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0106258:	8b 40 08             	mov    0x8(%eax),%eax
f010625b:	89 45 ec             	mov    %eax,-0x14(%ebp)
		stabstr_end = usd->stabstr_end;
f010625e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0106261:	8b 40 0c             	mov    0xc(%eax),%eax
f0106264:	89 45 e8             	mov    %eax,-0x18(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0106267:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010626a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
f010626d:	76 0a                	jbe    f0106279 <debuginfo_eip+0xa4>
f010626f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0106272:	48                   	dec    %eax
f0106273:	8a 00                	mov    (%eax),%al
f0106275:	84 c0                	test   %al,%al
f0106277:	74 0a                	je     f0106283 <debuginfo_eip+0xae>
		return -1;
f0106279:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010627e:	e9 01 02 00 00       	jmp    f0106484 <debuginfo_eip+0x2af>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0106283:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	rfile = (stab_end - stabs) - 1;
f010628a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010628d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106290:	29 c2                	sub    %eax,%edx
f0106292:	89 d0                	mov    %edx,%eax
f0106294:	c1 f8 02             	sar    $0x2,%eax
f0106297:	89 c2                	mov    %eax,%edx
f0106299:	89 d0                	mov    %edx,%eax
f010629b:	c1 e0 02             	shl    $0x2,%eax
f010629e:	01 d0                	add    %edx,%eax
f01062a0:	c1 e0 02             	shl    $0x2,%eax
f01062a3:	01 d0                	add    %edx,%eax
f01062a5:	c1 e0 02             	shl    $0x2,%eax
f01062a8:	01 d0                	add    %edx,%eax
f01062aa:	89 c1                	mov    %eax,%ecx
f01062ac:	c1 e1 08             	shl    $0x8,%ecx
f01062af:	01 c8                	add    %ecx,%eax
f01062b1:	89 c1                	mov    %eax,%ecx
f01062b3:	c1 e1 10             	shl    $0x10,%ecx
f01062b6:	01 c8                	add    %ecx,%eax
f01062b8:	01 c0                	add    %eax,%eax
f01062ba:	01 d0                	add    %edx,%eax
f01062bc:	48                   	dec    %eax
f01062bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01062c0:	ff 75 08             	pushl  0x8(%ebp)
f01062c3:	6a 64                	push   $0x64
f01062c5:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01062c8:	50                   	push   %eax
f01062c9:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01062cc:	50                   	push   %eax
f01062cd:	ff 75 f4             	pushl  -0xc(%ebp)
f01062d0:	e8 b3 fd ff ff       	call   f0106088 <stab_binsearch>
f01062d5:	83 c4 14             	add    $0x14,%esp
	if (lfile == 0)
f01062d8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01062db:	85 c0                	test   %eax,%eax
f01062dd:	75 0a                	jne    f01062e9 <debuginfo_eip+0x114>
		return -1;
f01062df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01062e4:	e9 9b 01 00 00       	jmp    f0106484 <debuginfo_eip+0x2af>

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01062e9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01062ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
	rfun = rfile;
f01062ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01062f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01062f5:	ff 75 08             	pushl  0x8(%ebp)
f01062f8:	6a 24                	push   $0x24
f01062fa:	8d 45 cc             	lea    -0x34(%ebp),%eax
f01062fd:	50                   	push   %eax
f01062fe:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0106301:	50                   	push   %eax
f0106302:	ff 75 f4             	pushl  -0xc(%ebp)
f0106305:	e8 7e fd ff ff       	call   f0106088 <stab_binsearch>
f010630a:	83 c4 14             	add    $0x14,%esp

	if (lfun <= rfun) {
f010630d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0106310:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0106313:	39 c2                	cmp    %eax,%edx
f0106315:	0f 8f 86 00 00 00    	jg     f01063a1 <debuginfo_eip+0x1cc>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010631b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010631e:	89 c2                	mov    %eax,%edx
f0106320:	89 d0                	mov    %edx,%eax
f0106322:	01 c0                	add    %eax,%eax
f0106324:	01 d0                	add    %edx,%eax
f0106326:	c1 e0 02             	shl    $0x2,%eax
f0106329:	89 c2                	mov    %eax,%edx
f010632b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010632e:	01 d0                	add    %edx,%eax
f0106330:	8b 00                	mov    (%eax),%eax
f0106332:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0106335:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0106338:	29 d1                	sub    %edx,%ecx
f010633a:	89 ca                	mov    %ecx,%edx
f010633c:	39 d0                	cmp    %edx,%eax
f010633e:	73 22                	jae    f0106362 <debuginfo_eip+0x18d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0106340:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0106343:	89 c2                	mov    %eax,%edx
f0106345:	89 d0                	mov    %edx,%eax
f0106347:	01 c0                	add    %eax,%eax
f0106349:	01 d0                	add    %edx,%eax
f010634b:	c1 e0 02             	shl    $0x2,%eax
f010634e:	89 c2                	mov    %eax,%edx
f0106350:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106353:	01 d0                	add    %edx,%eax
f0106355:	8b 10                	mov    (%eax),%edx
f0106357:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010635a:	01 c2                	add    %eax,%edx
f010635c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010635f:	89 50 08             	mov    %edx,0x8(%eax)
		info->eip_fn_addr = (uint32*) stabs[lfun].n_value;
f0106362:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0106365:	89 c2                	mov    %eax,%edx
f0106367:	89 d0                	mov    %edx,%eax
f0106369:	01 c0                	add    %eax,%eax
f010636b:	01 d0                	add    %edx,%eax
f010636d:	c1 e0 02             	shl    $0x2,%eax
f0106370:	89 c2                	mov    %eax,%edx
f0106372:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106375:	01 d0                	add    %edx,%eax
f0106377:	8b 50 08             	mov    0x8(%eax),%edx
f010637a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010637d:	89 50 10             	mov    %edx,0x10(%eax)
		addr = (uint32*)(addr - (info->eip_fn_addr));
f0106380:	8b 55 08             	mov    0x8(%ebp),%edx
f0106383:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106386:	8b 40 10             	mov    0x10(%eax),%eax
f0106389:	29 c2                	sub    %eax,%edx
f010638b:	89 d0                	mov    %edx,%eax
f010638d:	c1 f8 02             	sar    $0x2,%eax
f0106390:	89 45 08             	mov    %eax,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0106393:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0106396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfun;
f0106399:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010639c:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010639f:	eb 15                	jmp    f01063b6 <debuginfo_eip+0x1e1>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01063a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01063a4:	8b 55 08             	mov    0x8(%ebp),%edx
f01063a7:	89 50 10             	mov    %edx,0x10(%eax)
		lline = lfile;
f01063aa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01063ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		rline = rfile;
f01063b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01063b3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01063b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01063b9:	8b 40 08             	mov    0x8(%eax),%eax
f01063bc:	83 ec 08             	sub    $0x8,%esp
f01063bf:	6a 3a                	push   $0x3a
f01063c1:	50                   	push   %eax
f01063c2:	e8 a4 09 00 00       	call   f0106d6b <strfind>
f01063c7:	83 c4 10             	add    $0x10,%esp
f01063ca:	89 c2                	mov    %eax,%edx
f01063cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01063cf:	8b 40 08             	mov    0x8(%eax),%eax
f01063d2:	29 c2                	sub    %eax,%edx
f01063d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01063d7:	89 50 0c             	mov    %edx,0xc(%eax)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01063da:	eb 03                	jmp    f01063df <debuginfo_eip+0x20a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01063dc:	ff 4d e4             	decl   -0x1c(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01063df:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01063e2:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01063e5:	7c 4e                	jl     f0106435 <debuginfo_eip+0x260>
	       && stabs[lline].n_type != N_SOL
f01063e7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01063ea:	89 d0                	mov    %edx,%eax
f01063ec:	01 c0                	add    %eax,%eax
f01063ee:	01 d0                	add    %edx,%eax
f01063f0:	c1 e0 02             	shl    $0x2,%eax
f01063f3:	89 c2                	mov    %eax,%edx
f01063f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01063f8:	01 d0                	add    %edx,%eax
f01063fa:	8a 40 04             	mov    0x4(%eax),%al
f01063fd:	3c 84                	cmp    $0x84,%al
f01063ff:	74 34                	je     f0106435 <debuginfo_eip+0x260>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0106401:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0106404:	89 d0                	mov    %edx,%eax
f0106406:	01 c0                	add    %eax,%eax
f0106408:	01 d0                	add    %edx,%eax
f010640a:	c1 e0 02             	shl    $0x2,%eax
f010640d:	89 c2                	mov    %eax,%edx
f010640f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106412:	01 d0                	add    %edx,%eax
f0106414:	8a 40 04             	mov    0x4(%eax),%al
f0106417:	3c 64                	cmp    $0x64,%al
f0106419:	75 c1                	jne    f01063dc <debuginfo_eip+0x207>
f010641b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010641e:	89 d0                	mov    %edx,%eax
f0106420:	01 c0                	add    %eax,%eax
f0106422:	01 d0                	add    %edx,%eax
f0106424:	c1 e0 02             	shl    $0x2,%eax
f0106427:	89 c2                	mov    %eax,%edx
f0106429:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010642c:	01 d0                	add    %edx,%eax
f010642e:	8b 40 08             	mov    0x8(%eax),%eax
f0106431:	85 c0                	test   %eax,%eax
f0106433:	74 a7                	je     f01063dc <debuginfo_eip+0x207>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0106435:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0106438:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010643b:	7c 42                	jl     f010647f <debuginfo_eip+0x2aa>
f010643d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0106440:	89 d0                	mov    %edx,%eax
f0106442:	01 c0                	add    %eax,%eax
f0106444:	01 d0                	add    %edx,%eax
f0106446:	c1 e0 02             	shl    $0x2,%eax
f0106449:	89 c2                	mov    %eax,%edx
f010644b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010644e:	01 d0                	add    %edx,%eax
f0106450:	8b 00                	mov    (%eax),%eax
f0106452:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0106455:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0106458:	29 d1                	sub    %edx,%ecx
f010645a:	89 ca                	mov    %ecx,%edx
f010645c:	39 d0                	cmp    %edx,%eax
f010645e:	73 1f                	jae    f010647f <debuginfo_eip+0x2aa>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0106460:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0106463:	89 d0                	mov    %edx,%eax
f0106465:	01 c0                	add    %eax,%eax
f0106467:	01 d0                	add    %edx,%eax
f0106469:	c1 e0 02             	shl    $0x2,%eax
f010646c:	89 c2                	mov    %eax,%edx
f010646e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106471:	01 d0                	add    %edx,%eax
f0106473:	8b 10                	mov    (%eax),%edx
f0106475:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0106478:	01 c2                	add    %eax,%edx
f010647a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010647d:	89 10                	mov    %edx,(%eax)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f010647f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106484:	c9                   	leave  
f0106485:	c3                   	ret    

f0106486 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0106486:	55                   	push   %ebp
f0106487:	89 e5                	mov    %esp,%ebp
f0106489:	53                   	push   %ebx
f010648a:	83 ec 14             	sub    $0x14,%esp
f010648d:	8b 45 10             	mov    0x10(%ebp),%eax
f0106490:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0106493:	8b 45 14             	mov    0x14(%ebp),%eax
f0106496:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0106499:	8b 45 18             	mov    0x18(%ebp),%eax
f010649c:	ba 00 00 00 00       	mov    $0x0,%edx
f01064a1:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f01064a4:	77 55                	ja     f01064fb <printnum+0x75>
f01064a6:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f01064a9:	72 05                	jb     f01064b0 <printnum+0x2a>
f01064ab:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f01064ae:	77 4b                	ja     f01064fb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01064b0:	8b 45 1c             	mov    0x1c(%ebp),%eax
f01064b3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01064b6:	8b 45 18             	mov    0x18(%ebp),%eax
f01064b9:	ba 00 00 00 00       	mov    $0x0,%edx
f01064be:	52                   	push   %edx
f01064bf:	50                   	push   %eax
f01064c0:	ff 75 f4             	pushl  -0xc(%ebp)
f01064c3:	ff 75 f0             	pushl  -0x10(%ebp)
f01064c6:	e8 59 0c 00 00       	call   f0107124 <__udivdi3>
f01064cb:	83 c4 10             	add    $0x10,%esp
f01064ce:	83 ec 04             	sub    $0x4,%esp
f01064d1:	ff 75 20             	pushl  0x20(%ebp)
f01064d4:	53                   	push   %ebx
f01064d5:	ff 75 18             	pushl  0x18(%ebp)
f01064d8:	52                   	push   %edx
f01064d9:	50                   	push   %eax
f01064da:	ff 75 0c             	pushl  0xc(%ebp)
f01064dd:	ff 75 08             	pushl  0x8(%ebp)
f01064e0:	e8 a1 ff ff ff       	call   f0106486 <printnum>
f01064e5:	83 c4 20             	add    $0x20,%esp
f01064e8:	eb 1a                	jmp    f0106504 <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01064ea:	83 ec 08             	sub    $0x8,%esp
f01064ed:	ff 75 0c             	pushl  0xc(%ebp)
f01064f0:	ff 75 20             	pushl  0x20(%ebp)
f01064f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01064f6:	ff d0                	call   *%eax
f01064f8:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01064fb:	ff 4d 1c             	decl   0x1c(%ebp)
f01064fe:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0106502:	7f e6                	jg     f01064ea <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0106504:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0106507:	bb 00 00 00 00       	mov    $0x0,%ebx
f010650c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010650f:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0106512:	53                   	push   %ebx
f0106513:	51                   	push   %ecx
f0106514:	52                   	push   %edx
f0106515:	50                   	push   %eax
f0106516:	e8 19 0d 00 00       	call   f0107234 <__umoddi3>
f010651b:	83 c4 10             	add    $0x10,%esp
f010651e:	05 40 a0 10 f0       	add    $0xf010a040,%eax
f0106523:	8a 00                	mov    (%eax),%al
f0106525:	0f be c0             	movsbl %al,%eax
f0106528:	83 ec 08             	sub    $0x8,%esp
f010652b:	ff 75 0c             	pushl  0xc(%ebp)
f010652e:	50                   	push   %eax
f010652f:	8b 45 08             	mov    0x8(%ebp),%eax
f0106532:	ff d0                	call   *%eax
f0106534:	83 c4 10             	add    $0x10,%esp
}
f0106537:	90                   	nop
f0106538:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010653b:	c9                   	leave  
f010653c:	c3                   	ret    

f010653d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010653d:	55                   	push   %ebp
f010653e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0106540:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f0106544:	7e 1c                	jle    f0106562 <getuint+0x25>
		return va_arg(*ap, unsigned long long);
f0106546:	8b 45 08             	mov    0x8(%ebp),%eax
f0106549:	8b 00                	mov    (%eax),%eax
f010654b:	8d 50 08             	lea    0x8(%eax),%edx
f010654e:	8b 45 08             	mov    0x8(%ebp),%eax
f0106551:	89 10                	mov    %edx,(%eax)
f0106553:	8b 45 08             	mov    0x8(%ebp),%eax
f0106556:	8b 00                	mov    (%eax),%eax
f0106558:	83 e8 08             	sub    $0x8,%eax
f010655b:	8b 50 04             	mov    0x4(%eax),%edx
f010655e:	8b 00                	mov    (%eax),%eax
f0106560:	eb 40                	jmp    f01065a2 <getuint+0x65>
	else if (lflag)
f0106562:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106566:	74 1e                	je     f0106586 <getuint+0x49>
		return va_arg(*ap, unsigned long);
f0106568:	8b 45 08             	mov    0x8(%ebp),%eax
f010656b:	8b 00                	mov    (%eax),%eax
f010656d:	8d 50 04             	lea    0x4(%eax),%edx
f0106570:	8b 45 08             	mov    0x8(%ebp),%eax
f0106573:	89 10                	mov    %edx,(%eax)
f0106575:	8b 45 08             	mov    0x8(%ebp),%eax
f0106578:	8b 00                	mov    (%eax),%eax
f010657a:	83 e8 04             	sub    $0x4,%eax
f010657d:	8b 00                	mov    (%eax),%eax
f010657f:	ba 00 00 00 00       	mov    $0x0,%edx
f0106584:	eb 1c                	jmp    f01065a2 <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
f0106586:	8b 45 08             	mov    0x8(%ebp),%eax
f0106589:	8b 00                	mov    (%eax),%eax
f010658b:	8d 50 04             	lea    0x4(%eax),%edx
f010658e:	8b 45 08             	mov    0x8(%ebp),%eax
f0106591:	89 10                	mov    %edx,(%eax)
f0106593:	8b 45 08             	mov    0x8(%ebp),%eax
f0106596:	8b 00                	mov    (%eax),%eax
f0106598:	83 e8 04             	sub    $0x4,%eax
f010659b:	8b 00                	mov    (%eax),%eax
f010659d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01065a2:	5d                   	pop    %ebp
f01065a3:	c3                   	ret    

f01065a4 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01065a4:	55                   	push   %ebp
f01065a5:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01065a7:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f01065ab:	7e 1c                	jle    f01065c9 <getint+0x25>
		return va_arg(*ap, long long);
f01065ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01065b0:	8b 00                	mov    (%eax),%eax
f01065b2:	8d 50 08             	lea    0x8(%eax),%edx
f01065b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01065b8:	89 10                	mov    %edx,(%eax)
f01065ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01065bd:	8b 00                	mov    (%eax),%eax
f01065bf:	83 e8 08             	sub    $0x8,%eax
f01065c2:	8b 50 04             	mov    0x4(%eax),%edx
f01065c5:	8b 00                	mov    (%eax),%eax
f01065c7:	eb 38                	jmp    f0106601 <getint+0x5d>
	else if (lflag)
f01065c9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01065cd:	74 1a                	je     f01065e9 <getint+0x45>
		return va_arg(*ap, long);
f01065cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01065d2:	8b 00                	mov    (%eax),%eax
f01065d4:	8d 50 04             	lea    0x4(%eax),%edx
f01065d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01065da:	89 10                	mov    %edx,(%eax)
f01065dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01065df:	8b 00                	mov    (%eax),%eax
f01065e1:	83 e8 04             	sub    $0x4,%eax
f01065e4:	8b 00                	mov    (%eax),%eax
f01065e6:	99                   	cltd   
f01065e7:	eb 18                	jmp    f0106601 <getint+0x5d>
	else
		return va_arg(*ap, int);
f01065e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01065ec:	8b 00                	mov    (%eax),%eax
f01065ee:	8d 50 04             	lea    0x4(%eax),%edx
f01065f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01065f4:	89 10                	mov    %edx,(%eax)
f01065f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01065f9:	8b 00                	mov    (%eax),%eax
f01065fb:	83 e8 04             	sub    $0x4,%eax
f01065fe:	8b 00                	mov    (%eax),%eax
f0106600:	99                   	cltd   
}
f0106601:	5d                   	pop    %ebp
f0106602:	c3                   	ret    

f0106603 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0106603:	55                   	push   %ebp
f0106604:	89 e5                	mov    %esp,%ebp
f0106606:	56                   	push   %esi
f0106607:	53                   	push   %ebx
f0106608:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010660b:	eb 17                	jmp    f0106624 <vprintfmt+0x21>
			if (ch == '\0')
f010660d:	85 db                	test   %ebx,%ebx
f010660f:	0f 84 af 03 00 00    	je     f01069c4 <vprintfmt+0x3c1>
				return;
			putch(ch, putdat);
f0106615:	83 ec 08             	sub    $0x8,%esp
f0106618:	ff 75 0c             	pushl  0xc(%ebp)
f010661b:	53                   	push   %ebx
f010661c:	8b 45 08             	mov    0x8(%ebp),%eax
f010661f:	ff d0                	call   *%eax
f0106621:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0106624:	8b 45 10             	mov    0x10(%ebp),%eax
f0106627:	8d 50 01             	lea    0x1(%eax),%edx
f010662a:	89 55 10             	mov    %edx,0x10(%ebp)
f010662d:	8a 00                	mov    (%eax),%al
f010662f:	0f b6 d8             	movzbl %al,%ebx
f0106632:	83 fb 25             	cmp    $0x25,%ebx
f0106635:	75 d6                	jne    f010660d <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0106637:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
f010663b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
f0106642:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0106649:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
f0106650:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0106657:	8b 45 10             	mov    0x10(%ebp),%eax
f010665a:	8d 50 01             	lea    0x1(%eax),%edx
f010665d:	89 55 10             	mov    %edx,0x10(%ebp)
f0106660:	8a 00                	mov    (%eax),%al
f0106662:	0f b6 d8             	movzbl %al,%ebx
f0106665:	8d 43 dd             	lea    -0x23(%ebx),%eax
f0106668:	83 f8 55             	cmp    $0x55,%eax
f010666b:	0f 87 2b 03 00 00    	ja     f010699c <vprintfmt+0x399>
f0106671:	8b 04 85 64 a0 10 f0 	mov    -0xfef5f9c(,%eax,4),%eax
f0106678:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f010667a:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
f010667e:	eb d7                	jmp    f0106657 <vprintfmt+0x54>
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0106680:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
f0106684:	eb d1                	jmp    f0106657 <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0106686:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
f010668d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0106690:	89 d0                	mov    %edx,%eax
f0106692:	c1 e0 02             	shl    $0x2,%eax
f0106695:	01 d0                	add    %edx,%eax
f0106697:	01 c0                	add    %eax,%eax
f0106699:	01 d8                	add    %ebx,%eax
f010669b:	83 e8 30             	sub    $0x30,%eax
f010669e:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
f01066a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01066a4:	8a 00                	mov    (%eax),%al
f01066a6:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
f01066a9:	83 fb 2f             	cmp    $0x2f,%ebx
f01066ac:	7e 3e                	jle    f01066ec <vprintfmt+0xe9>
f01066ae:	83 fb 39             	cmp    $0x39,%ebx
f01066b1:	7f 39                	jg     f01066ec <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01066b3:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01066b6:	eb d5                	jmp    f010668d <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01066b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01066bb:	83 c0 04             	add    $0x4,%eax
f01066be:	89 45 14             	mov    %eax,0x14(%ebp)
f01066c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01066c4:	83 e8 04             	sub    $0x4,%eax
f01066c7:	8b 00                	mov    (%eax),%eax
f01066c9:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
f01066cc:	eb 1f                	jmp    f01066ed <vprintfmt+0xea>

		case '.':
			if (width < 0)
f01066ce:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01066d2:	79 83                	jns    f0106657 <vprintfmt+0x54>
				width = 0;
f01066d4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
f01066db:	e9 77 ff ff ff       	jmp    f0106657 <vprintfmt+0x54>

		case '#':
			altflag = 1;
f01066e0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01066e7:	e9 6b ff ff ff       	jmp    f0106657 <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
f01066ec:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01066ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01066f1:	0f 89 60 ff ff ff    	jns    f0106657 <vprintfmt+0x54>
				width = precision, precision = -1;
f01066f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01066fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01066fd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
f0106704:	e9 4e ff ff ff       	jmp    f0106657 <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0106709:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
f010670c:	e9 46 ff ff ff       	jmp    f0106657 <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0106711:	8b 45 14             	mov    0x14(%ebp),%eax
f0106714:	83 c0 04             	add    $0x4,%eax
f0106717:	89 45 14             	mov    %eax,0x14(%ebp)
f010671a:	8b 45 14             	mov    0x14(%ebp),%eax
f010671d:	83 e8 04             	sub    $0x4,%eax
f0106720:	8b 00                	mov    (%eax),%eax
f0106722:	83 ec 08             	sub    $0x8,%esp
f0106725:	ff 75 0c             	pushl  0xc(%ebp)
f0106728:	50                   	push   %eax
f0106729:	8b 45 08             	mov    0x8(%ebp),%eax
f010672c:	ff d0                	call   *%eax
f010672e:	83 c4 10             	add    $0x10,%esp
			break;
f0106731:	e9 89 02 00 00       	jmp    f01069bf <vprintfmt+0x3bc>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0106736:	8b 45 14             	mov    0x14(%ebp),%eax
f0106739:	83 c0 04             	add    $0x4,%eax
f010673c:	89 45 14             	mov    %eax,0x14(%ebp)
f010673f:	8b 45 14             	mov    0x14(%ebp),%eax
f0106742:	83 e8 04             	sub    $0x4,%eax
f0106745:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
f0106747:	85 db                	test   %ebx,%ebx
f0106749:	79 02                	jns    f010674d <vprintfmt+0x14a>
				err = -err;
f010674b:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f010674d:	83 fb 07             	cmp    $0x7,%ebx
f0106750:	7f 0b                	jg     f010675d <vprintfmt+0x15a>
f0106752:	8b 34 9d 20 a0 10 f0 	mov    -0xfef5fe0(,%ebx,4),%esi
f0106759:	85 f6                	test   %esi,%esi
f010675b:	75 19                	jne    f0106776 <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
f010675d:	53                   	push   %ebx
f010675e:	68 51 a0 10 f0       	push   $0xf010a051
f0106763:	ff 75 0c             	pushl  0xc(%ebp)
f0106766:	ff 75 08             	pushl  0x8(%ebp)
f0106769:	e8 5e 02 00 00       	call   f01069cc <printfmt>
f010676e:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
f0106771:	e9 49 02 00 00       	jmp    f01069bf <vprintfmt+0x3bc>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0106776:	56                   	push   %esi
f0106777:	68 5a a0 10 f0       	push   $0xf010a05a
f010677c:	ff 75 0c             	pushl  0xc(%ebp)
f010677f:	ff 75 08             	pushl  0x8(%ebp)
f0106782:	e8 45 02 00 00       	call   f01069cc <printfmt>
f0106787:	83 c4 10             	add    $0x10,%esp
			break;
f010678a:	e9 30 02 00 00       	jmp    f01069bf <vprintfmt+0x3bc>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010678f:	8b 45 14             	mov    0x14(%ebp),%eax
f0106792:	83 c0 04             	add    $0x4,%eax
f0106795:	89 45 14             	mov    %eax,0x14(%ebp)
f0106798:	8b 45 14             	mov    0x14(%ebp),%eax
f010679b:	83 e8 04             	sub    $0x4,%eax
f010679e:	8b 30                	mov    (%eax),%esi
f01067a0:	85 f6                	test   %esi,%esi
f01067a2:	75 05                	jne    f01067a9 <vprintfmt+0x1a6>
				p = "(null)";
f01067a4:	be 5d a0 10 f0       	mov    $0xf010a05d,%esi
			if (width > 0 && padc != '-')
f01067a9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01067ad:	7e 6d                	jle    f010681c <vprintfmt+0x219>
f01067af:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
f01067b3:	74 67                	je     f010681c <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
f01067b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01067b8:	83 ec 08             	sub    $0x8,%esp
f01067bb:	50                   	push   %eax
f01067bc:	56                   	push   %esi
f01067bd:	e8 0a 04 00 00       	call   f0106bcc <strnlen>
f01067c2:	83 c4 10             	add    $0x10,%esp
f01067c5:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f01067c8:	eb 16                	jmp    f01067e0 <vprintfmt+0x1dd>
					putch(padc, putdat);
f01067ca:	0f be 45 db          	movsbl -0x25(%ebp),%eax
f01067ce:	83 ec 08             	sub    $0x8,%esp
f01067d1:	ff 75 0c             	pushl  0xc(%ebp)
f01067d4:	50                   	push   %eax
f01067d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01067d8:	ff d0                	call   *%eax
f01067da:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01067dd:	ff 4d e4             	decl   -0x1c(%ebp)
f01067e0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01067e4:	7f e4                	jg     f01067ca <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01067e6:	eb 34                	jmp    f010681c <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
f01067e8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01067ec:	74 1c                	je     f010680a <vprintfmt+0x207>
f01067ee:	83 fb 1f             	cmp    $0x1f,%ebx
f01067f1:	7e 05                	jle    f01067f8 <vprintfmt+0x1f5>
f01067f3:	83 fb 7e             	cmp    $0x7e,%ebx
f01067f6:	7e 12                	jle    f010680a <vprintfmt+0x207>
					putch('?', putdat);
f01067f8:	83 ec 08             	sub    $0x8,%esp
f01067fb:	ff 75 0c             	pushl  0xc(%ebp)
f01067fe:	6a 3f                	push   $0x3f
f0106800:	8b 45 08             	mov    0x8(%ebp),%eax
f0106803:	ff d0                	call   *%eax
f0106805:	83 c4 10             	add    $0x10,%esp
f0106808:	eb 0f                	jmp    f0106819 <vprintfmt+0x216>
				else
					putch(ch, putdat);
f010680a:	83 ec 08             	sub    $0x8,%esp
f010680d:	ff 75 0c             	pushl  0xc(%ebp)
f0106810:	53                   	push   %ebx
f0106811:	8b 45 08             	mov    0x8(%ebp),%eax
f0106814:	ff d0                	call   *%eax
f0106816:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0106819:	ff 4d e4             	decl   -0x1c(%ebp)
f010681c:	89 f0                	mov    %esi,%eax
f010681e:	8d 70 01             	lea    0x1(%eax),%esi
f0106821:	8a 00                	mov    (%eax),%al
f0106823:	0f be d8             	movsbl %al,%ebx
f0106826:	85 db                	test   %ebx,%ebx
f0106828:	74 24                	je     f010684e <vprintfmt+0x24b>
f010682a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010682e:	78 b8                	js     f01067e8 <vprintfmt+0x1e5>
f0106830:	ff 4d e0             	decl   -0x20(%ebp)
f0106833:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0106837:	79 af                	jns    f01067e8 <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0106839:	eb 13                	jmp    f010684e <vprintfmt+0x24b>
				putch(' ', putdat);
f010683b:	83 ec 08             	sub    $0x8,%esp
f010683e:	ff 75 0c             	pushl  0xc(%ebp)
f0106841:	6a 20                	push   $0x20
f0106843:	8b 45 08             	mov    0x8(%ebp),%eax
f0106846:	ff d0                	call   *%eax
f0106848:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010684b:	ff 4d e4             	decl   -0x1c(%ebp)
f010684e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0106852:	7f e7                	jg     f010683b <vprintfmt+0x238>
				putch(' ', putdat);
			break;
f0106854:	e9 66 01 00 00       	jmp    f01069bf <vprintfmt+0x3bc>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0106859:	83 ec 08             	sub    $0x8,%esp
f010685c:	ff 75 e8             	pushl  -0x18(%ebp)
f010685f:	8d 45 14             	lea    0x14(%ebp),%eax
f0106862:	50                   	push   %eax
f0106863:	e8 3c fd ff ff       	call   f01065a4 <getint>
f0106868:	83 c4 10             	add    $0x10,%esp
f010686b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010686e:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
f0106871:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0106874:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0106877:	85 d2                	test   %edx,%edx
f0106879:	79 23                	jns    f010689e <vprintfmt+0x29b>
				putch('-', putdat);
f010687b:	83 ec 08             	sub    $0x8,%esp
f010687e:	ff 75 0c             	pushl  0xc(%ebp)
f0106881:	6a 2d                	push   $0x2d
f0106883:	8b 45 08             	mov    0x8(%ebp),%eax
f0106886:	ff d0                	call   *%eax
f0106888:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
f010688b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010688e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0106891:	f7 d8                	neg    %eax
f0106893:	83 d2 00             	adc    $0x0,%edx
f0106896:	f7 da                	neg    %edx
f0106898:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010689b:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
f010689e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01068a5:	e9 bc 00 00 00       	jmp    f0106966 <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01068aa:	83 ec 08             	sub    $0x8,%esp
f01068ad:	ff 75 e8             	pushl  -0x18(%ebp)
f01068b0:	8d 45 14             	lea    0x14(%ebp),%eax
f01068b3:	50                   	push   %eax
f01068b4:	e8 84 fc ff ff       	call   f010653d <getuint>
f01068b9:	83 c4 10             	add    $0x10,%esp
f01068bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01068bf:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
f01068c2:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
f01068c9:	e9 98 00 00 00       	jmp    f0106966 <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01068ce:	83 ec 08             	sub    $0x8,%esp
f01068d1:	ff 75 0c             	pushl  0xc(%ebp)
f01068d4:	6a 58                	push   $0x58
f01068d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01068d9:	ff d0                	call   *%eax
f01068db:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f01068de:	83 ec 08             	sub    $0x8,%esp
f01068e1:	ff 75 0c             	pushl  0xc(%ebp)
f01068e4:	6a 58                	push   $0x58
f01068e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01068e9:	ff d0                	call   *%eax
f01068eb:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
f01068ee:	83 ec 08             	sub    $0x8,%esp
f01068f1:	ff 75 0c             	pushl  0xc(%ebp)
f01068f4:	6a 58                	push   $0x58
f01068f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01068f9:	ff d0                	call   *%eax
f01068fb:	83 c4 10             	add    $0x10,%esp
			break;
f01068fe:	e9 bc 00 00 00       	jmp    f01069bf <vprintfmt+0x3bc>

		// pointer
		case 'p':
			putch('0', putdat);
f0106903:	83 ec 08             	sub    $0x8,%esp
f0106906:	ff 75 0c             	pushl  0xc(%ebp)
f0106909:	6a 30                	push   $0x30
f010690b:	8b 45 08             	mov    0x8(%ebp),%eax
f010690e:	ff d0                	call   *%eax
f0106910:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
f0106913:	83 ec 08             	sub    $0x8,%esp
f0106916:	ff 75 0c             	pushl  0xc(%ebp)
f0106919:	6a 78                	push   $0x78
f010691b:	8b 45 08             	mov    0x8(%ebp),%eax
f010691e:	ff d0                	call   *%eax
f0106920:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
f0106923:	8b 45 14             	mov    0x14(%ebp),%eax
f0106926:	83 c0 04             	add    $0x4,%eax
f0106929:	89 45 14             	mov    %eax,0x14(%ebp)
f010692c:	8b 45 14             	mov    0x14(%ebp),%eax
f010692f:	83 e8 04             	sub    $0x4,%eax
f0106932:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0106934:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0106937:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
f010693e:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
f0106945:	eb 1f                	jmp    f0106966 <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0106947:	83 ec 08             	sub    $0x8,%esp
f010694a:	ff 75 e8             	pushl  -0x18(%ebp)
f010694d:	8d 45 14             	lea    0x14(%ebp),%eax
f0106950:	50                   	push   %eax
f0106951:	e8 e7 fb ff ff       	call   f010653d <getuint>
f0106956:	83 c4 10             	add    $0x10,%esp
f0106959:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010695c:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
f010695f:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f0106966:	0f be 55 db          	movsbl -0x25(%ebp),%edx
f010696a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010696d:	83 ec 04             	sub    $0x4,%esp
f0106970:	52                   	push   %edx
f0106971:	ff 75 e4             	pushl  -0x1c(%ebp)
f0106974:	50                   	push   %eax
f0106975:	ff 75 f4             	pushl  -0xc(%ebp)
f0106978:	ff 75 f0             	pushl  -0x10(%ebp)
f010697b:	ff 75 0c             	pushl  0xc(%ebp)
f010697e:	ff 75 08             	pushl  0x8(%ebp)
f0106981:	e8 00 fb ff ff       	call   f0106486 <printnum>
f0106986:	83 c4 20             	add    $0x20,%esp
			break;
f0106989:	eb 34                	jmp    f01069bf <vprintfmt+0x3bc>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010698b:	83 ec 08             	sub    $0x8,%esp
f010698e:	ff 75 0c             	pushl  0xc(%ebp)
f0106991:	53                   	push   %ebx
f0106992:	8b 45 08             	mov    0x8(%ebp),%eax
f0106995:	ff d0                	call   *%eax
f0106997:	83 c4 10             	add    $0x10,%esp
			break;
f010699a:	eb 23                	jmp    f01069bf <vprintfmt+0x3bc>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010699c:	83 ec 08             	sub    $0x8,%esp
f010699f:	ff 75 0c             	pushl  0xc(%ebp)
f01069a2:	6a 25                	push   $0x25
f01069a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01069a7:	ff d0                	call   *%eax
f01069a9:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
f01069ac:	ff 4d 10             	decl   0x10(%ebp)
f01069af:	eb 03                	jmp    f01069b4 <vprintfmt+0x3b1>
f01069b1:	ff 4d 10             	decl   0x10(%ebp)
f01069b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01069b7:	48                   	dec    %eax
f01069b8:	8a 00                	mov    (%eax),%al
f01069ba:	3c 25                	cmp    $0x25,%al
f01069bc:	75 f3                	jne    f01069b1 <vprintfmt+0x3ae>
				/* do nothing */;
			break;
f01069be:	90                   	nop
		}
	}
f01069bf:	e9 47 fc ff ff       	jmp    f010660b <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
f01069c4:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f01069c5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01069c8:	5b                   	pop    %ebx
f01069c9:	5e                   	pop    %esi
f01069ca:	5d                   	pop    %ebp
f01069cb:	c3                   	ret    

f01069cc <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01069cc:	55                   	push   %ebp
f01069cd:	89 e5                	mov    %esp,%ebp
f01069cf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01069d2:	8d 45 10             	lea    0x10(%ebp),%eax
f01069d5:	83 c0 04             	add    $0x4,%eax
f01069d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f01069db:	8b 45 10             	mov    0x10(%ebp),%eax
f01069de:	ff 75 f4             	pushl  -0xc(%ebp)
f01069e1:	50                   	push   %eax
f01069e2:	ff 75 0c             	pushl  0xc(%ebp)
f01069e5:	ff 75 08             	pushl  0x8(%ebp)
f01069e8:	e8 16 fc ff ff       	call   f0106603 <vprintfmt>
f01069ed:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
f01069f0:	90                   	nop
f01069f1:	c9                   	leave  
f01069f2:	c3                   	ret    

f01069f3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01069f3:	55                   	push   %ebp
f01069f4:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f01069f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01069f9:	8b 40 08             	mov    0x8(%eax),%eax
f01069fc:	8d 50 01             	lea    0x1(%eax),%edx
f01069ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106a02:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f0106a05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106a08:	8b 10                	mov    (%eax),%edx
f0106a0a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106a0d:	8b 40 04             	mov    0x4(%eax),%eax
f0106a10:	39 c2                	cmp    %eax,%edx
f0106a12:	73 12                	jae    f0106a26 <sprintputch+0x33>
		*b->buf++ = ch;
f0106a14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106a17:	8b 00                	mov    (%eax),%eax
f0106a19:	8d 48 01             	lea    0x1(%eax),%ecx
f0106a1c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106a1f:	89 0a                	mov    %ecx,(%edx)
f0106a21:	8b 55 08             	mov    0x8(%ebp),%edx
f0106a24:	88 10                	mov    %dl,(%eax)
}
f0106a26:	90                   	nop
f0106a27:	5d                   	pop    %ebp
f0106a28:	c3                   	ret    

f0106a29 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0106a29:	55                   	push   %ebp
f0106a2a:	89 e5                	mov    %esp,%ebp
f0106a2c:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0106a2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0106a32:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0106a35:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106a38:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106a3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0106a3e:	01 d0                	add    %edx,%eax
f0106a40:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0106a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0106a4a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0106a4e:	74 06                	je     f0106a56 <vsnprintf+0x2d>
f0106a50:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106a54:	7f 07                	jg     f0106a5d <vsnprintf+0x34>
		return -E_INVAL;
f0106a56:	b8 03 00 00 00       	mov    $0x3,%eax
f0106a5b:	eb 20                	jmp    f0106a7d <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0106a5d:	ff 75 14             	pushl  0x14(%ebp)
f0106a60:	ff 75 10             	pushl  0x10(%ebp)
f0106a63:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0106a66:	50                   	push   %eax
f0106a67:	68 f3 69 10 f0       	push   $0xf01069f3
f0106a6c:	e8 92 fb ff ff       	call   f0106603 <vprintfmt>
f0106a71:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
f0106a74:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0106a77:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0106a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f0106a7d:	c9                   	leave  
f0106a7e:	c3                   	ret    

f0106a7f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0106a7f:	55                   	push   %ebp
f0106a80:	89 e5                	mov    %esp,%ebp
f0106a82:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0106a85:	8d 45 10             	lea    0x10(%ebp),%eax
f0106a88:	83 c0 04             	add    $0x4,%eax
f0106a8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0106a8e:	8b 45 10             	mov    0x10(%ebp),%eax
f0106a91:	ff 75 f4             	pushl  -0xc(%ebp)
f0106a94:	50                   	push   %eax
f0106a95:	ff 75 0c             	pushl  0xc(%ebp)
f0106a98:	ff 75 08             	pushl  0x8(%ebp)
f0106a9b:	e8 89 ff ff ff       	call   f0106a29 <vsnprintf>
f0106aa0:	83 c4 10             	add    $0x10,%esp
f0106aa3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
f0106aa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
f0106aa9:	c9                   	leave  
f0106aaa:	c3                   	ret    

f0106aab <readline>:

#define BUFLEN 1024
//static char buf[BUFLEN];

void readline(const char *prompt, char* buf)
{
f0106aab:	55                   	push   %ebp
f0106aac:	89 e5                	mov    %esp,%ebp
f0106aae:	83 ec 18             	sub    $0x18,%esp
	int i, c, echoing;
	
	if (prompt != NULL)
f0106ab1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0106ab5:	74 13                	je     f0106aca <readline+0x1f>
		cprintf("%s", prompt);
f0106ab7:	83 ec 08             	sub    $0x8,%esp
f0106aba:	ff 75 08             	pushl  0x8(%ebp)
f0106abd:	68 bc a1 10 f0       	push   $0xf010a1bc
f0106ac2:	e8 ed eb ff ff       	call   f01056b4 <cprintf>
f0106ac7:	83 c4 10             	add    $0x10,%esp

	
	i = 0;
f0106aca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = iscons(0);	
f0106ad1:	83 ec 0c             	sub    $0xc,%esp
f0106ad4:	6a 00                	push   $0x0
f0106ad6:	e8 6c 9e ff ff       	call   f0100947 <iscons>
f0106adb:	83 c4 10             	add    $0x10,%esp
f0106ade:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (1) {
		c = getchar();
f0106ae1:	e8 48 9e ff ff       	call   f010092e <getchar>
f0106ae6:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
f0106ae9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0106aed:	79 22                	jns    f0106b11 <readline+0x66>
			if (c != -E_EOF)
f0106aef:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
f0106af3:	0f 84 ad 00 00 00    	je     f0106ba6 <readline+0xfb>
				cprintf("read error: %e\n", c);			
f0106af9:	83 ec 08             	sub    $0x8,%esp
f0106afc:	ff 75 ec             	pushl  -0x14(%ebp)
f0106aff:	68 bf a1 10 f0       	push   $0xf010a1bf
f0106b04:	e8 ab eb ff ff       	call   f01056b4 <cprintf>
f0106b09:	83 c4 10             	add    $0x10,%esp
			return;
f0106b0c:	e9 95 00 00 00       	jmp    f0106ba6 <readline+0xfb>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0106b11:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
f0106b15:	7e 34                	jle    f0106b4b <readline+0xa0>
f0106b17:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
f0106b1e:	7f 2b                	jg     f0106b4b <readline+0xa0>
			if (echoing)
f0106b20:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0106b24:	74 0e                	je     f0106b34 <readline+0x89>
				cputchar(c);
f0106b26:	83 ec 0c             	sub    $0xc,%esp
f0106b29:	ff 75 ec             	pushl  -0x14(%ebp)
f0106b2c:	e8 e6 9d ff ff       	call   f0100917 <cputchar>
f0106b31:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0106b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0106b37:	8d 50 01             	lea    0x1(%eax),%edx
f0106b3a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0106b3d:	89 c2                	mov    %eax,%edx
f0106b3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106b42:	01 d0                	add    %edx,%eax
f0106b44:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0106b47:	88 10                	mov    %dl,(%eax)
f0106b49:	eb 56                	jmp    f0106ba1 <readline+0xf6>
		} else if (c == '\b' && i > 0) {
f0106b4b:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
f0106b4f:	75 1f                	jne    f0106b70 <readline+0xc5>
f0106b51:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0106b55:	7e 19                	jle    f0106b70 <readline+0xc5>
			if (echoing)
f0106b57:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0106b5b:	74 0e                	je     f0106b6b <readline+0xc0>
				cputchar(c);
f0106b5d:	83 ec 0c             	sub    $0xc,%esp
f0106b60:	ff 75 ec             	pushl  -0x14(%ebp)
f0106b63:	e8 af 9d ff ff       	call   f0100917 <cputchar>
f0106b68:	83 c4 10             	add    $0x10,%esp
			i--;
f0106b6b:	ff 4d f4             	decl   -0xc(%ebp)
f0106b6e:	eb 31                	jmp    f0106ba1 <readline+0xf6>
		} else if (c == '\n' || c == '\r') {
f0106b70:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
f0106b74:	74 0a                	je     f0106b80 <readline+0xd5>
f0106b76:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
f0106b7a:	0f 85 61 ff ff ff    	jne    f0106ae1 <readline+0x36>
			if (echoing)
f0106b80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0106b84:	74 0e                	je     f0106b94 <readline+0xe9>
				cputchar(c);
f0106b86:	83 ec 0c             	sub    $0xc,%esp
f0106b89:	ff 75 ec             	pushl  -0x14(%ebp)
f0106b8c:	e8 86 9d ff ff       	call   f0100917 <cputchar>
f0106b91:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;	
f0106b94:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0106b97:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106b9a:	01 d0                	add    %edx,%eax
f0106b9c:	c6 00 00             	movb   $0x0,(%eax)
			return;		
f0106b9f:	eb 06                	jmp    f0106ba7 <readline+0xfc>
		}
	}
f0106ba1:	e9 3b ff ff ff       	jmp    f0106ae1 <readline+0x36>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);			
			return;
f0106ba6:	90                   	nop
				cputchar(c);
			buf[i] = 0;	
			return;		
		}
	}
}
f0106ba7:	c9                   	leave  
f0106ba8:	c3                   	ret    

f0106ba9 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0106ba9:	55                   	push   %ebp
f0106baa:	89 e5                	mov    %esp,%ebp
f0106bac:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0106baf:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0106bb6:	eb 06                	jmp    f0106bbe <strlen+0x15>
		n++;
f0106bb8:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0106bbb:	ff 45 08             	incl   0x8(%ebp)
f0106bbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0106bc1:	8a 00                	mov    (%eax),%al
f0106bc3:	84 c0                	test   %al,%al
f0106bc5:	75 f1                	jne    f0106bb8 <strlen+0xf>
		n++;
	return n;
f0106bc7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0106bca:	c9                   	leave  
f0106bcb:	c3                   	ret    

f0106bcc <strnlen>:

int
strnlen(const char *s, uint32 size)
{
f0106bcc:	55                   	push   %ebp
f0106bcd:	89 e5                	mov    %esp,%ebp
f0106bcf:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0106bd2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0106bd9:	eb 09                	jmp    f0106be4 <strnlen+0x18>
		n++;
f0106bdb:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0106bde:	ff 45 08             	incl   0x8(%ebp)
f0106be1:	ff 4d 0c             	decl   0xc(%ebp)
f0106be4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106be8:	74 09                	je     f0106bf3 <strnlen+0x27>
f0106bea:	8b 45 08             	mov    0x8(%ebp),%eax
f0106bed:	8a 00                	mov    (%eax),%al
f0106bef:	84 c0                	test   %al,%al
f0106bf1:	75 e8                	jne    f0106bdb <strnlen+0xf>
		n++;
	return n;
f0106bf3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0106bf6:	c9                   	leave  
f0106bf7:	c3                   	ret    

f0106bf8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0106bf8:	55                   	push   %ebp
f0106bf9:	89 e5                	mov    %esp,%ebp
f0106bfb:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0106bfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c01:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0106c04:	90                   	nop
f0106c05:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c08:	8d 50 01             	lea    0x1(%eax),%edx
f0106c0b:	89 55 08             	mov    %edx,0x8(%ebp)
f0106c0e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106c11:	8d 4a 01             	lea    0x1(%edx),%ecx
f0106c14:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0106c17:	8a 12                	mov    (%edx),%dl
f0106c19:	88 10                	mov    %dl,(%eax)
f0106c1b:	8a 00                	mov    (%eax),%al
f0106c1d:	84 c0                	test   %al,%al
f0106c1f:	75 e4                	jne    f0106c05 <strcpy+0xd>
		/* do nothing */;
	return ret;
f0106c21:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0106c24:	c9                   	leave  
f0106c25:	c3                   	ret    

f0106c26 <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
f0106c26:	55                   	push   %ebp
f0106c27:	89 e5                	mov    %esp,%ebp
f0106c29:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
f0106c2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c2f:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0106c32:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0106c39:	eb 1f                	jmp    f0106c5a <strncpy+0x34>
		*dst++ = *src;
f0106c3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c3e:	8d 50 01             	lea    0x1(%eax),%edx
f0106c41:	89 55 08             	mov    %edx,0x8(%ebp)
f0106c44:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106c47:	8a 12                	mov    (%edx),%dl
f0106c49:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0106c4b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106c4e:	8a 00                	mov    (%eax),%al
f0106c50:	84 c0                	test   %al,%al
f0106c52:	74 03                	je     f0106c57 <strncpy+0x31>
			src++;
f0106c54:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0106c57:	ff 45 fc             	incl   -0x4(%ebp)
f0106c5a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106c5d:	3b 45 10             	cmp    0x10(%ebp),%eax
f0106c60:	72 d9                	jb     f0106c3b <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0106c62:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0106c65:	c9                   	leave  
f0106c66:	c3                   	ret    

f0106c67 <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
f0106c67:	55                   	push   %ebp
f0106c68:	89 e5                	mov    %esp,%ebp
f0106c6a:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f0106c6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c70:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0106c73:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106c77:	74 30                	je     f0106ca9 <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
f0106c79:	eb 16                	jmp    f0106c91 <strlcpy+0x2a>
			*dst++ = *src++;
f0106c7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0106c7e:	8d 50 01             	lea    0x1(%eax),%edx
f0106c81:	89 55 08             	mov    %edx,0x8(%ebp)
f0106c84:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106c87:	8d 4a 01             	lea    0x1(%edx),%ecx
f0106c8a:	89 4d 0c             	mov    %ecx,0xc(%ebp)
f0106c8d:	8a 12                	mov    (%edx),%dl
f0106c8f:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0106c91:	ff 4d 10             	decl   0x10(%ebp)
f0106c94:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106c98:	74 09                	je     f0106ca3 <strlcpy+0x3c>
f0106c9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106c9d:	8a 00                	mov    (%eax),%al
f0106c9f:	84 c0                	test   %al,%al
f0106ca1:	75 d8                	jne    f0106c7b <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0106ca3:	8b 45 08             	mov    0x8(%ebp),%eax
f0106ca6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0106ca9:	8b 55 08             	mov    0x8(%ebp),%edx
f0106cac:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106caf:	29 c2                	sub    %eax,%edx
f0106cb1:	89 d0                	mov    %edx,%eax
}
f0106cb3:	c9                   	leave  
f0106cb4:	c3                   	ret    

f0106cb5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0106cb5:	55                   	push   %ebp
f0106cb6:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
f0106cb8:	eb 06                	jmp    f0106cc0 <strcmp+0xb>
		p++, q++;
f0106cba:	ff 45 08             	incl   0x8(%ebp)
f0106cbd:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0106cc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0106cc3:	8a 00                	mov    (%eax),%al
f0106cc5:	84 c0                	test   %al,%al
f0106cc7:	74 0e                	je     f0106cd7 <strcmp+0x22>
f0106cc9:	8b 45 08             	mov    0x8(%ebp),%eax
f0106ccc:	8a 10                	mov    (%eax),%dl
f0106cce:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106cd1:	8a 00                	mov    (%eax),%al
f0106cd3:	38 c2                	cmp    %al,%dl
f0106cd5:	74 e3                	je     f0106cba <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0106cd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0106cda:	8a 00                	mov    (%eax),%al
f0106cdc:	0f b6 d0             	movzbl %al,%edx
f0106cdf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106ce2:	8a 00                	mov    (%eax),%al
f0106ce4:	0f b6 c0             	movzbl %al,%eax
f0106ce7:	29 c2                	sub    %eax,%edx
f0106ce9:	89 d0                	mov    %edx,%eax
}
f0106ceb:	5d                   	pop    %ebp
f0106cec:	c3                   	ret    

f0106ced <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
f0106ced:	55                   	push   %ebp
f0106cee:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
f0106cf0:	eb 09                	jmp    f0106cfb <strncmp+0xe>
		n--, p++, q++;
f0106cf2:	ff 4d 10             	decl   0x10(%ebp)
f0106cf5:	ff 45 08             	incl   0x8(%ebp)
f0106cf8:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
f0106cfb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106cff:	74 17                	je     f0106d18 <strncmp+0x2b>
f0106d01:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d04:	8a 00                	mov    (%eax),%al
f0106d06:	84 c0                	test   %al,%al
f0106d08:	74 0e                	je     f0106d18 <strncmp+0x2b>
f0106d0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d0d:	8a 10                	mov    (%eax),%dl
f0106d0f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106d12:	8a 00                	mov    (%eax),%al
f0106d14:	38 c2                	cmp    %al,%dl
f0106d16:	74 da                	je     f0106cf2 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
f0106d18:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106d1c:	75 07                	jne    f0106d25 <strncmp+0x38>
		return 0;
f0106d1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0106d23:	eb 14                	jmp    f0106d39 <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0106d25:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d28:	8a 00                	mov    (%eax),%al
f0106d2a:	0f b6 d0             	movzbl %al,%edx
f0106d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106d30:	8a 00                	mov    (%eax),%al
f0106d32:	0f b6 c0             	movzbl %al,%eax
f0106d35:	29 c2                	sub    %eax,%edx
f0106d37:	89 d0                	mov    %edx,%eax
}
f0106d39:	5d                   	pop    %ebp
f0106d3a:	c3                   	ret    

f0106d3b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0106d3b:	55                   	push   %ebp
f0106d3c:	89 e5                	mov    %esp,%ebp
f0106d3e:	83 ec 04             	sub    $0x4,%esp
f0106d41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106d44:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0106d47:	eb 12                	jmp    f0106d5b <strchr+0x20>
		if (*s == c)
f0106d49:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d4c:	8a 00                	mov    (%eax),%al
f0106d4e:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0106d51:	75 05                	jne    f0106d58 <strchr+0x1d>
			return (char *) s;
f0106d53:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d56:	eb 11                	jmp    f0106d69 <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0106d58:	ff 45 08             	incl   0x8(%ebp)
f0106d5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d5e:	8a 00                	mov    (%eax),%al
f0106d60:	84 c0                	test   %al,%al
f0106d62:	75 e5                	jne    f0106d49 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0106d64:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106d69:	c9                   	leave  
f0106d6a:	c3                   	ret    

f0106d6b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0106d6b:	55                   	push   %ebp
f0106d6c:	89 e5                	mov    %esp,%ebp
f0106d6e:	83 ec 04             	sub    $0x4,%esp
f0106d71:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106d74:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
f0106d77:	eb 0d                	jmp    f0106d86 <strfind+0x1b>
		if (*s == c)
f0106d79:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d7c:	8a 00                	mov    (%eax),%al
f0106d7e:	3a 45 fc             	cmp    -0x4(%ebp),%al
f0106d81:	74 0e                	je     f0106d91 <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0106d83:	ff 45 08             	incl   0x8(%ebp)
f0106d86:	8b 45 08             	mov    0x8(%ebp),%eax
f0106d89:	8a 00                	mov    (%eax),%al
f0106d8b:	84 c0                	test   %al,%al
f0106d8d:	75 ea                	jne    f0106d79 <strfind+0xe>
f0106d8f:	eb 01                	jmp    f0106d92 <strfind+0x27>
		if (*s == c)
			break;
f0106d91:	90                   	nop
	return (char *) s;
f0106d92:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106d95:	c9                   	leave  
f0106d96:	c3                   	ret    

f0106d97 <memset>:


void *
memset(void *v, int c, uint32 n)
{
f0106d97:	55                   	push   %ebp
f0106d98:	89 e5                	mov    %esp,%ebp
f0106d9a:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f0106d9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0106da0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f0106da3:	8b 45 10             	mov    0x10(%ebp),%eax
f0106da6:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (--m >= 0)
f0106da9:	eb 0e                	jmp    f0106db9 <memset+0x22>
		*p++ = c;
f0106dab:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106dae:	8d 50 01             	lea    0x1(%eax),%edx
f0106db1:	89 55 fc             	mov    %edx,-0x4(%ebp)
f0106db4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106db7:	88 10                	mov    %dl,(%eax)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0106db9:	ff 4d f8             	decl   -0x8(%ebp)
f0106dbc:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0106dc0:	79 e9                	jns    f0106dab <memset+0x14>
		*p++ = c;

	return v;
f0106dc2:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106dc5:	c9                   	leave  
f0106dc6:	c3                   	ret    

f0106dc7 <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
f0106dc7:	55                   	push   %ebp
f0106dc8:	89 e5                	mov    %esp,%ebp
f0106dca:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0106dcd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106dd0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0106dd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0106dd6:	89 45 f8             	mov    %eax,-0x8(%ebp)
	while (n-- > 0)
f0106dd9:	eb 16                	jmp    f0106df1 <memcpy+0x2a>
		*d++ = *s++;
f0106ddb:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106dde:	8d 50 01             	lea    0x1(%eax),%edx
f0106de1:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0106de4:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0106de7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0106dea:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0106ded:	8a 12                	mov    (%edx),%dl
f0106def:	88 10                	mov    %dl,(%eax)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0106df1:	8b 45 10             	mov    0x10(%ebp),%eax
f0106df4:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106df7:	89 55 10             	mov    %edx,0x10(%ebp)
f0106dfa:	85 c0                	test   %eax,%eax
f0106dfc:	75 dd                	jne    f0106ddb <memcpy+0x14>
		*d++ = *s++;

	return dst;
f0106dfe:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106e01:	c9                   	leave  
f0106e02:	c3                   	ret    

f0106e03 <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
f0106e03:	55                   	push   %ebp
f0106e04:	89 e5                	mov    %esp,%ebp
f0106e06:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f0106e09:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106e0c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f0106e0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0106e12:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f0106e15:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106e18:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0106e1b:	73 50                	jae    f0106e6d <memmove+0x6a>
f0106e1d:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0106e20:	8b 45 10             	mov    0x10(%ebp),%eax
f0106e23:	01 d0                	add    %edx,%eax
f0106e25:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0106e28:	76 43                	jbe    f0106e6d <memmove+0x6a>
		s += n;
f0106e2a:	8b 45 10             	mov    0x10(%ebp),%eax
f0106e2d:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f0106e30:	8b 45 10             	mov    0x10(%ebp),%eax
f0106e33:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
f0106e36:	eb 10                	jmp    f0106e48 <memmove+0x45>
			*--d = *--s;
f0106e38:	ff 4d f8             	decl   -0x8(%ebp)
f0106e3b:	ff 4d fc             	decl   -0x4(%ebp)
f0106e3e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106e41:	8a 10                	mov    (%eax),%dl
f0106e43:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106e46:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0106e48:	8b 45 10             	mov    0x10(%ebp),%eax
f0106e4b:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106e4e:	89 55 10             	mov    %edx,0x10(%ebp)
f0106e51:	85 c0                	test   %eax,%eax
f0106e53:	75 e3                	jne    f0106e38 <memmove+0x35>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0106e55:	eb 23                	jmp    f0106e7a <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0106e57:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106e5a:	8d 50 01             	lea    0x1(%eax),%edx
f0106e5d:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0106e60:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0106e63:	8d 4a 01             	lea    0x1(%edx),%ecx
f0106e66:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0106e69:	8a 12                	mov    (%edx),%dl
f0106e6b:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0106e6d:	8b 45 10             	mov    0x10(%ebp),%eax
f0106e70:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106e73:	89 55 10             	mov    %edx,0x10(%ebp)
f0106e76:	85 c0                	test   %eax,%eax
f0106e78:	75 dd                	jne    f0106e57 <memmove+0x54>
			*d++ = *s++;

	return dst;
f0106e7a:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106e7d:	c9                   	leave  
f0106e7e:	c3                   	ret    

f0106e7f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
f0106e7f:	55                   	push   %ebp
f0106e80:	89 e5                	mov    %esp,%ebp
f0106e82:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
f0106e85:	8b 45 08             	mov    0x8(%ebp),%eax
f0106e88:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
f0106e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106e8e:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
f0106e91:	eb 2a                	jmp    f0106ebd <memcmp+0x3e>
		if (*s1 != *s2)
f0106e93:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106e96:	8a 10                	mov    (%eax),%dl
f0106e98:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106e9b:	8a 00                	mov    (%eax),%al
f0106e9d:	38 c2                	cmp    %al,%dl
f0106e9f:	74 16                	je     f0106eb7 <memcmp+0x38>
			return (int) *s1 - (int) *s2;
f0106ea1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0106ea4:	8a 00                	mov    (%eax),%al
f0106ea6:	0f b6 d0             	movzbl %al,%edx
f0106ea9:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0106eac:	8a 00                	mov    (%eax),%al
f0106eae:	0f b6 c0             	movzbl %al,%eax
f0106eb1:	29 c2                	sub    %eax,%edx
f0106eb3:	89 d0                	mov    %edx,%eax
f0106eb5:	eb 18                	jmp    f0106ecf <memcmp+0x50>
		s1++, s2++;
f0106eb7:	ff 45 fc             	incl   -0x4(%ebp)
f0106eba:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
f0106ebd:	8b 45 10             	mov    0x10(%ebp),%eax
f0106ec0:	8d 50 ff             	lea    -0x1(%eax),%edx
f0106ec3:	89 55 10             	mov    %edx,0x10(%ebp)
f0106ec6:	85 c0                	test   %eax,%eax
f0106ec8:	75 c9                	jne    f0106e93 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0106eca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106ecf:	c9                   	leave  
f0106ed0:	c3                   	ret    

f0106ed1 <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
f0106ed1:	55                   	push   %ebp
f0106ed2:	89 e5                	mov    %esp,%ebp
f0106ed4:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0106ed7:	8b 55 08             	mov    0x8(%ebp),%edx
f0106eda:	8b 45 10             	mov    0x10(%ebp),%eax
f0106edd:	01 d0                	add    %edx,%eax
f0106edf:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
f0106ee2:	eb 15                	jmp    f0106ef9 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0106ee4:	8b 45 08             	mov    0x8(%ebp),%eax
f0106ee7:	8a 00                	mov    (%eax),%al
f0106ee9:	0f b6 d0             	movzbl %al,%edx
f0106eec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0106eef:	0f b6 c0             	movzbl %al,%eax
f0106ef2:	39 c2                	cmp    %eax,%edx
f0106ef4:	74 0d                	je     f0106f03 <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0106ef6:	ff 45 08             	incl   0x8(%ebp)
f0106ef9:	8b 45 08             	mov    0x8(%ebp),%eax
f0106efc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0106eff:	72 e3                	jb     f0106ee4 <memfind+0x13>
f0106f01:	eb 01                	jmp    f0106f04 <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
f0106f03:	90                   	nop
	return (void *) s;
f0106f04:	8b 45 08             	mov    0x8(%ebp),%eax
}
f0106f07:	c9                   	leave  
f0106f08:	c3                   	ret    

f0106f09 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0106f09:	55                   	push   %ebp
f0106f0a:	89 e5                	mov    %esp,%ebp
f0106f0c:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
f0106f0f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f0106f16:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0106f1d:	eb 03                	jmp    f0106f22 <strtol+0x19>
		s++;
f0106f1f:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0106f22:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f25:	8a 00                	mov    (%eax),%al
f0106f27:	3c 20                	cmp    $0x20,%al
f0106f29:	74 f4                	je     f0106f1f <strtol+0x16>
f0106f2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f2e:	8a 00                	mov    (%eax),%al
f0106f30:	3c 09                	cmp    $0x9,%al
f0106f32:	74 eb                	je     f0106f1f <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f0106f34:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f37:	8a 00                	mov    (%eax),%al
f0106f39:	3c 2b                	cmp    $0x2b,%al
f0106f3b:	75 05                	jne    f0106f42 <strtol+0x39>
		s++;
f0106f3d:	ff 45 08             	incl   0x8(%ebp)
f0106f40:	eb 13                	jmp    f0106f55 <strtol+0x4c>
	else if (*s == '-')
f0106f42:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f45:	8a 00                	mov    (%eax),%al
f0106f47:	3c 2d                	cmp    $0x2d,%al
f0106f49:	75 0a                	jne    f0106f55 <strtol+0x4c>
		s++, neg = 1;
f0106f4b:	ff 45 08             	incl   0x8(%ebp)
f0106f4e:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0106f55:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106f59:	74 06                	je     f0106f61 <strtol+0x58>
f0106f5b:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f0106f5f:	75 20                	jne    f0106f81 <strtol+0x78>
f0106f61:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f64:	8a 00                	mov    (%eax),%al
f0106f66:	3c 30                	cmp    $0x30,%al
f0106f68:	75 17                	jne    f0106f81 <strtol+0x78>
f0106f6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f6d:	40                   	inc    %eax
f0106f6e:	8a 00                	mov    (%eax),%al
f0106f70:	3c 78                	cmp    $0x78,%al
f0106f72:	75 0d                	jne    f0106f81 <strtol+0x78>
		s += 2, base = 16;
f0106f74:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f0106f78:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0106f7f:	eb 28                	jmp    f0106fa9 <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
f0106f81:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106f85:	75 15                	jne    f0106f9c <strtol+0x93>
f0106f87:	8b 45 08             	mov    0x8(%ebp),%eax
f0106f8a:	8a 00                	mov    (%eax),%al
f0106f8c:	3c 30                	cmp    $0x30,%al
f0106f8e:	75 0c                	jne    f0106f9c <strtol+0x93>
		s++, base = 8;
f0106f90:	ff 45 08             	incl   0x8(%ebp)
f0106f93:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f0106f9a:	eb 0d                	jmp    f0106fa9 <strtol+0xa0>
	else if (base == 0)
f0106f9c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0106fa0:	75 07                	jne    f0106fa9 <strtol+0xa0>
		base = 10;
f0106fa2:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0106fa9:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fac:	8a 00                	mov    (%eax),%al
f0106fae:	3c 2f                	cmp    $0x2f,%al
f0106fb0:	7e 19                	jle    f0106fcb <strtol+0xc2>
f0106fb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fb5:	8a 00                	mov    (%eax),%al
f0106fb7:	3c 39                	cmp    $0x39,%al
f0106fb9:	7f 10                	jg     f0106fcb <strtol+0xc2>
			dig = *s - '0';
f0106fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fbe:	8a 00                	mov    (%eax),%al
f0106fc0:	0f be c0             	movsbl %al,%eax
f0106fc3:	83 e8 30             	sub    $0x30,%eax
f0106fc6:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0106fc9:	eb 42                	jmp    f010700d <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
f0106fcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fce:	8a 00                	mov    (%eax),%al
f0106fd0:	3c 60                	cmp    $0x60,%al
f0106fd2:	7e 19                	jle    f0106fed <strtol+0xe4>
f0106fd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fd7:	8a 00                	mov    (%eax),%al
f0106fd9:	3c 7a                	cmp    $0x7a,%al
f0106fdb:	7f 10                	jg     f0106fed <strtol+0xe4>
			dig = *s - 'a' + 10;
f0106fdd:	8b 45 08             	mov    0x8(%ebp),%eax
f0106fe0:	8a 00                	mov    (%eax),%al
f0106fe2:	0f be c0             	movsbl %al,%eax
f0106fe5:	83 e8 57             	sub    $0x57,%eax
f0106fe8:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0106feb:	eb 20                	jmp    f010700d <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
f0106fed:	8b 45 08             	mov    0x8(%ebp),%eax
f0106ff0:	8a 00                	mov    (%eax),%al
f0106ff2:	3c 40                	cmp    $0x40,%al
f0106ff4:	7e 39                	jle    f010702f <strtol+0x126>
f0106ff6:	8b 45 08             	mov    0x8(%ebp),%eax
f0106ff9:	8a 00                	mov    (%eax),%al
f0106ffb:	3c 5a                	cmp    $0x5a,%al
f0106ffd:	7f 30                	jg     f010702f <strtol+0x126>
			dig = *s - 'A' + 10;
f0106fff:	8b 45 08             	mov    0x8(%ebp),%eax
f0107002:	8a 00                	mov    (%eax),%al
f0107004:	0f be c0             	movsbl %al,%eax
f0107007:	83 e8 37             	sub    $0x37,%eax
f010700a:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f010700d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0107010:	3b 45 10             	cmp    0x10(%ebp),%eax
f0107013:	7d 19                	jge    f010702e <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
f0107015:	ff 45 08             	incl   0x8(%ebp)
f0107018:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010701b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010701f:	89 c2                	mov    %eax,%edx
f0107021:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0107024:	01 d0                	add    %edx,%eax
f0107026:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
f0107029:	e9 7b ff ff ff       	jmp    f0106fa9 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
f010702e:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f010702f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0107033:	74 08                	je     f010703d <strtol+0x134>
		*endptr = (char *) s;
f0107035:	8b 45 0c             	mov    0xc(%ebp),%eax
f0107038:	8b 55 08             	mov    0x8(%ebp),%edx
f010703b:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f010703d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0107041:	74 07                	je     f010704a <strtol+0x141>
f0107043:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0107046:	f7 d8                	neg    %eax
f0107048:	eb 03                	jmp    f010704d <strtol+0x144>
f010704a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f010704d:	c9                   	leave  
f010704e:	c3                   	ret    

f010704f <strsplit>:

int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
f010704f:	55                   	push   %ebp
f0107050:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
f0107052:	8b 45 14             	mov    0x14(%ebp),%eax
f0107055:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
f010705b:	8b 45 14             	mov    0x14(%ebp),%eax
f010705e:	8b 00                	mov    (%eax),%eax
f0107060:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0107067:	8b 45 10             	mov    0x10(%ebp),%eax
f010706a:	01 d0                	add    %edx,%eax
f010706c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0107072:	eb 0c                	jmp    f0107080 <strsplit+0x31>
			*string++ = 0;
f0107074:	8b 45 08             	mov    0x8(%ebp),%eax
f0107077:	8d 50 01             	lea    0x1(%eax),%edx
f010707a:	89 55 08             	mov    %edx,0x8(%ebp)
f010707d:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1) 
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
f0107080:	8b 45 08             	mov    0x8(%ebp),%eax
f0107083:	8a 00                	mov    (%eax),%al
f0107085:	84 c0                	test   %al,%al
f0107087:	74 18                	je     f01070a1 <strsplit+0x52>
f0107089:	8b 45 08             	mov    0x8(%ebp),%eax
f010708c:	8a 00                	mov    (%eax),%al
f010708e:	0f be c0             	movsbl %al,%eax
f0107091:	50                   	push   %eax
f0107092:	ff 75 0c             	pushl  0xc(%ebp)
f0107095:	e8 a1 fc ff ff       	call   f0106d3b <strchr>
f010709a:	83 c4 08             	add    $0x8,%esp
f010709d:	85 c0                	test   %eax,%eax
f010709f:	75 d3                	jne    f0107074 <strsplit+0x25>
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
f01070a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01070a4:	8a 00                	mov    (%eax),%al
f01070a6:	84 c0                	test   %al,%al
f01070a8:	74 5a                	je     f0107104 <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1) 
f01070aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01070ad:	8b 00                	mov    (%eax),%eax
f01070af:	83 f8 0f             	cmp    $0xf,%eax
f01070b2:	75 07                	jne    f01070bb <strsplit+0x6c>
		{
			return 0;
f01070b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01070b9:	eb 66                	jmp    f0107121 <strsplit+0xd2>
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
f01070bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01070be:	8b 00                	mov    (%eax),%eax
f01070c0:	8d 48 01             	lea    0x1(%eax),%ecx
f01070c3:	8b 55 14             	mov    0x14(%ebp),%edx
f01070c6:	89 0a                	mov    %ecx,(%edx)
f01070c8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f01070cf:	8b 45 10             	mov    0x10(%ebp),%eax
f01070d2:	01 c2                	add    %eax,%edx
f01070d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01070d7:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
f01070d9:	eb 03                	jmp    f01070de <strsplit+0x8f>
			string++;
f01070db:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}
		
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
f01070de:	8b 45 08             	mov    0x8(%ebp),%eax
f01070e1:	8a 00                	mov    (%eax),%al
f01070e3:	84 c0                	test   %al,%al
f01070e5:	74 8b                	je     f0107072 <strsplit+0x23>
f01070e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01070ea:	8a 00                	mov    (%eax),%al
f01070ec:	0f be c0             	movsbl %al,%eax
f01070ef:	50                   	push   %eax
f01070f0:	ff 75 0c             	pushl  0xc(%ebp)
f01070f3:	e8 43 fc ff ff       	call   f0106d3b <strchr>
f01070f8:	83 c4 08             	add    $0x8,%esp
f01070fb:	85 c0                	test   %eax,%eax
f01070fd:	74 dc                	je     f01070db <strsplit+0x8c>
			string++;
	}
f01070ff:	e9 6e ff ff ff       	jmp    f0107072 <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;
		
		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
f0107104:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
f0107105:	8b 45 14             	mov    0x14(%ebp),%eax
f0107108:	8b 00                	mov    (%eax),%eax
f010710a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
f0107111:	8b 45 10             	mov    0x10(%ebp),%eax
f0107114:	01 d0                	add    %edx,%eax
f0107116:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
f010711c:	b8 01 00 00 00       	mov    $0x1,%eax
}
f0107121:	c9                   	leave  
f0107122:	c3                   	ret    
f0107123:	90                   	nop

f0107124 <__udivdi3>:
f0107124:	55                   	push   %ebp
f0107125:	57                   	push   %edi
f0107126:	56                   	push   %esi
f0107127:	53                   	push   %ebx
f0107128:	83 ec 1c             	sub    $0x1c,%esp
f010712b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010712f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0107133:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0107137:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010713b:	89 ca                	mov    %ecx,%edx
f010713d:	89 f8                	mov    %edi,%eax
f010713f:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0107143:	85 f6                	test   %esi,%esi
f0107145:	75 2d                	jne    f0107174 <__udivdi3+0x50>
f0107147:	39 cf                	cmp    %ecx,%edi
f0107149:	77 65                	ja     f01071b0 <__udivdi3+0x8c>
f010714b:	89 fd                	mov    %edi,%ebp
f010714d:	85 ff                	test   %edi,%edi
f010714f:	75 0b                	jne    f010715c <__udivdi3+0x38>
f0107151:	b8 01 00 00 00       	mov    $0x1,%eax
f0107156:	31 d2                	xor    %edx,%edx
f0107158:	f7 f7                	div    %edi
f010715a:	89 c5                	mov    %eax,%ebp
f010715c:	31 d2                	xor    %edx,%edx
f010715e:	89 c8                	mov    %ecx,%eax
f0107160:	f7 f5                	div    %ebp
f0107162:	89 c1                	mov    %eax,%ecx
f0107164:	89 d8                	mov    %ebx,%eax
f0107166:	f7 f5                	div    %ebp
f0107168:	89 cf                	mov    %ecx,%edi
f010716a:	89 fa                	mov    %edi,%edx
f010716c:	83 c4 1c             	add    $0x1c,%esp
f010716f:	5b                   	pop    %ebx
f0107170:	5e                   	pop    %esi
f0107171:	5f                   	pop    %edi
f0107172:	5d                   	pop    %ebp
f0107173:	c3                   	ret    
f0107174:	39 ce                	cmp    %ecx,%esi
f0107176:	77 28                	ja     f01071a0 <__udivdi3+0x7c>
f0107178:	0f bd fe             	bsr    %esi,%edi
f010717b:	83 f7 1f             	xor    $0x1f,%edi
f010717e:	75 40                	jne    f01071c0 <__udivdi3+0x9c>
f0107180:	39 ce                	cmp    %ecx,%esi
f0107182:	72 0a                	jb     f010718e <__udivdi3+0x6a>
f0107184:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0107188:	0f 87 9e 00 00 00    	ja     f010722c <__udivdi3+0x108>
f010718e:	b8 01 00 00 00       	mov    $0x1,%eax
f0107193:	89 fa                	mov    %edi,%edx
f0107195:	83 c4 1c             	add    $0x1c,%esp
f0107198:	5b                   	pop    %ebx
f0107199:	5e                   	pop    %esi
f010719a:	5f                   	pop    %edi
f010719b:	5d                   	pop    %ebp
f010719c:	c3                   	ret    
f010719d:	8d 76 00             	lea    0x0(%esi),%esi
f01071a0:	31 ff                	xor    %edi,%edi
f01071a2:	31 c0                	xor    %eax,%eax
f01071a4:	89 fa                	mov    %edi,%edx
f01071a6:	83 c4 1c             	add    $0x1c,%esp
f01071a9:	5b                   	pop    %ebx
f01071aa:	5e                   	pop    %esi
f01071ab:	5f                   	pop    %edi
f01071ac:	5d                   	pop    %ebp
f01071ad:	c3                   	ret    
f01071ae:	66 90                	xchg   %ax,%ax
f01071b0:	89 d8                	mov    %ebx,%eax
f01071b2:	f7 f7                	div    %edi
f01071b4:	31 ff                	xor    %edi,%edi
f01071b6:	89 fa                	mov    %edi,%edx
f01071b8:	83 c4 1c             	add    $0x1c,%esp
f01071bb:	5b                   	pop    %ebx
f01071bc:	5e                   	pop    %esi
f01071bd:	5f                   	pop    %edi
f01071be:	5d                   	pop    %ebp
f01071bf:	c3                   	ret    
f01071c0:	bd 20 00 00 00       	mov    $0x20,%ebp
f01071c5:	89 eb                	mov    %ebp,%ebx
f01071c7:	29 fb                	sub    %edi,%ebx
f01071c9:	89 f9                	mov    %edi,%ecx
f01071cb:	d3 e6                	shl    %cl,%esi
f01071cd:	89 c5                	mov    %eax,%ebp
f01071cf:	88 d9                	mov    %bl,%cl
f01071d1:	d3 ed                	shr    %cl,%ebp
f01071d3:	89 e9                	mov    %ebp,%ecx
f01071d5:	09 f1                	or     %esi,%ecx
f01071d7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01071db:	89 f9                	mov    %edi,%ecx
f01071dd:	d3 e0                	shl    %cl,%eax
f01071df:	89 c5                	mov    %eax,%ebp
f01071e1:	89 d6                	mov    %edx,%esi
f01071e3:	88 d9                	mov    %bl,%cl
f01071e5:	d3 ee                	shr    %cl,%esi
f01071e7:	89 f9                	mov    %edi,%ecx
f01071e9:	d3 e2                	shl    %cl,%edx
f01071eb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01071ef:	88 d9                	mov    %bl,%cl
f01071f1:	d3 e8                	shr    %cl,%eax
f01071f3:	09 c2                	or     %eax,%edx
f01071f5:	89 d0                	mov    %edx,%eax
f01071f7:	89 f2                	mov    %esi,%edx
f01071f9:	f7 74 24 0c          	divl   0xc(%esp)
f01071fd:	89 d6                	mov    %edx,%esi
f01071ff:	89 c3                	mov    %eax,%ebx
f0107201:	f7 e5                	mul    %ebp
f0107203:	39 d6                	cmp    %edx,%esi
f0107205:	72 19                	jb     f0107220 <__udivdi3+0xfc>
f0107207:	74 0b                	je     f0107214 <__udivdi3+0xf0>
f0107209:	89 d8                	mov    %ebx,%eax
f010720b:	31 ff                	xor    %edi,%edi
f010720d:	e9 58 ff ff ff       	jmp    f010716a <__udivdi3+0x46>
f0107212:	66 90                	xchg   %ax,%ax
f0107214:	8b 54 24 08          	mov    0x8(%esp),%edx
f0107218:	89 f9                	mov    %edi,%ecx
f010721a:	d3 e2                	shl    %cl,%edx
f010721c:	39 c2                	cmp    %eax,%edx
f010721e:	73 e9                	jae    f0107209 <__udivdi3+0xe5>
f0107220:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0107223:	31 ff                	xor    %edi,%edi
f0107225:	e9 40 ff ff ff       	jmp    f010716a <__udivdi3+0x46>
f010722a:	66 90                	xchg   %ax,%ax
f010722c:	31 c0                	xor    %eax,%eax
f010722e:	e9 37 ff ff ff       	jmp    f010716a <__udivdi3+0x46>
f0107233:	90                   	nop

f0107234 <__umoddi3>:
f0107234:	55                   	push   %ebp
f0107235:	57                   	push   %edi
f0107236:	56                   	push   %esi
f0107237:	53                   	push   %ebx
f0107238:	83 ec 1c             	sub    $0x1c,%esp
f010723b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010723f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0107243:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0107247:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010724b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010724f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0107253:	89 f3                	mov    %esi,%ebx
f0107255:	89 fa                	mov    %edi,%edx
f0107257:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010725b:	89 34 24             	mov    %esi,(%esp)
f010725e:	85 c0                	test   %eax,%eax
f0107260:	75 1a                	jne    f010727c <__umoddi3+0x48>
f0107262:	39 f7                	cmp    %esi,%edi
f0107264:	0f 86 a2 00 00 00    	jbe    f010730c <__umoddi3+0xd8>
f010726a:	89 c8                	mov    %ecx,%eax
f010726c:	89 f2                	mov    %esi,%edx
f010726e:	f7 f7                	div    %edi
f0107270:	89 d0                	mov    %edx,%eax
f0107272:	31 d2                	xor    %edx,%edx
f0107274:	83 c4 1c             	add    $0x1c,%esp
f0107277:	5b                   	pop    %ebx
f0107278:	5e                   	pop    %esi
f0107279:	5f                   	pop    %edi
f010727a:	5d                   	pop    %ebp
f010727b:	c3                   	ret    
f010727c:	39 f0                	cmp    %esi,%eax
f010727e:	0f 87 ac 00 00 00    	ja     f0107330 <__umoddi3+0xfc>
f0107284:	0f bd e8             	bsr    %eax,%ebp
f0107287:	83 f5 1f             	xor    $0x1f,%ebp
f010728a:	0f 84 ac 00 00 00    	je     f010733c <__umoddi3+0x108>
f0107290:	bf 20 00 00 00       	mov    $0x20,%edi
f0107295:	29 ef                	sub    %ebp,%edi
f0107297:	89 fe                	mov    %edi,%esi
f0107299:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010729d:	89 e9                	mov    %ebp,%ecx
f010729f:	d3 e0                	shl    %cl,%eax
f01072a1:	89 d7                	mov    %edx,%edi
f01072a3:	89 f1                	mov    %esi,%ecx
f01072a5:	d3 ef                	shr    %cl,%edi
f01072a7:	09 c7                	or     %eax,%edi
f01072a9:	89 e9                	mov    %ebp,%ecx
f01072ab:	d3 e2                	shl    %cl,%edx
f01072ad:	89 14 24             	mov    %edx,(%esp)
f01072b0:	89 d8                	mov    %ebx,%eax
f01072b2:	d3 e0                	shl    %cl,%eax
f01072b4:	89 c2                	mov    %eax,%edx
f01072b6:	8b 44 24 08          	mov    0x8(%esp),%eax
f01072ba:	d3 e0                	shl    %cl,%eax
f01072bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01072c0:	8b 44 24 08          	mov    0x8(%esp),%eax
f01072c4:	89 f1                	mov    %esi,%ecx
f01072c6:	d3 e8                	shr    %cl,%eax
f01072c8:	09 d0                	or     %edx,%eax
f01072ca:	d3 eb                	shr    %cl,%ebx
f01072cc:	89 da                	mov    %ebx,%edx
f01072ce:	f7 f7                	div    %edi
f01072d0:	89 d3                	mov    %edx,%ebx
f01072d2:	f7 24 24             	mull   (%esp)
f01072d5:	89 c6                	mov    %eax,%esi
f01072d7:	89 d1                	mov    %edx,%ecx
f01072d9:	39 d3                	cmp    %edx,%ebx
f01072db:	0f 82 87 00 00 00    	jb     f0107368 <__umoddi3+0x134>
f01072e1:	0f 84 91 00 00 00    	je     f0107378 <__umoddi3+0x144>
f01072e7:	8b 54 24 04          	mov    0x4(%esp),%edx
f01072eb:	29 f2                	sub    %esi,%edx
f01072ed:	19 cb                	sbb    %ecx,%ebx
f01072ef:	89 d8                	mov    %ebx,%eax
f01072f1:	8a 4c 24 0c          	mov    0xc(%esp),%cl
f01072f5:	d3 e0                	shl    %cl,%eax
f01072f7:	89 e9                	mov    %ebp,%ecx
f01072f9:	d3 ea                	shr    %cl,%edx
f01072fb:	09 d0                	or     %edx,%eax
f01072fd:	89 e9                	mov    %ebp,%ecx
f01072ff:	d3 eb                	shr    %cl,%ebx
f0107301:	89 da                	mov    %ebx,%edx
f0107303:	83 c4 1c             	add    $0x1c,%esp
f0107306:	5b                   	pop    %ebx
f0107307:	5e                   	pop    %esi
f0107308:	5f                   	pop    %edi
f0107309:	5d                   	pop    %ebp
f010730a:	c3                   	ret    
f010730b:	90                   	nop
f010730c:	89 fd                	mov    %edi,%ebp
f010730e:	85 ff                	test   %edi,%edi
f0107310:	75 0b                	jne    f010731d <__umoddi3+0xe9>
f0107312:	b8 01 00 00 00       	mov    $0x1,%eax
f0107317:	31 d2                	xor    %edx,%edx
f0107319:	f7 f7                	div    %edi
f010731b:	89 c5                	mov    %eax,%ebp
f010731d:	89 f0                	mov    %esi,%eax
f010731f:	31 d2                	xor    %edx,%edx
f0107321:	f7 f5                	div    %ebp
f0107323:	89 c8                	mov    %ecx,%eax
f0107325:	f7 f5                	div    %ebp
f0107327:	89 d0                	mov    %edx,%eax
f0107329:	e9 44 ff ff ff       	jmp    f0107272 <__umoddi3+0x3e>
f010732e:	66 90                	xchg   %ax,%ax
f0107330:	89 c8                	mov    %ecx,%eax
f0107332:	89 f2                	mov    %esi,%edx
f0107334:	83 c4 1c             	add    $0x1c,%esp
f0107337:	5b                   	pop    %ebx
f0107338:	5e                   	pop    %esi
f0107339:	5f                   	pop    %edi
f010733a:	5d                   	pop    %ebp
f010733b:	c3                   	ret    
f010733c:	3b 04 24             	cmp    (%esp),%eax
f010733f:	72 06                	jb     f0107347 <__umoddi3+0x113>
f0107341:	3b 7c 24 04          	cmp    0x4(%esp),%edi
f0107345:	77 0f                	ja     f0107356 <__umoddi3+0x122>
f0107347:	89 f2                	mov    %esi,%edx
f0107349:	29 f9                	sub    %edi,%ecx
f010734b:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010734f:	89 14 24             	mov    %edx,(%esp)
f0107352:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0107356:	8b 44 24 04          	mov    0x4(%esp),%eax
f010735a:	8b 14 24             	mov    (%esp),%edx
f010735d:	83 c4 1c             	add    $0x1c,%esp
f0107360:	5b                   	pop    %ebx
f0107361:	5e                   	pop    %esi
f0107362:	5f                   	pop    %edi
f0107363:	5d                   	pop    %ebp
f0107364:	c3                   	ret    
f0107365:	8d 76 00             	lea    0x0(%esi),%esi
f0107368:	2b 04 24             	sub    (%esp),%eax
f010736b:	19 fa                	sbb    %edi,%edx
f010736d:	89 d1                	mov    %edx,%ecx
f010736f:	89 c6                	mov    %eax,%esi
f0107371:	e9 71 ff ff ff       	jmp    f01072e7 <__umoddi3+0xb3>
f0107376:	66 90                	xchg   %ax,%ax
f0107378:	39 44 24 04          	cmp    %eax,0x4(%esp)
f010737c:	72 ea                	jb     f0107368 <__umoddi3+0x134>
f010737e:	89 d9                	mov    %ebx,%ecx
f0107380:	e9 62 ff ff ff       	jmp    f01072e7 <__umoddi3+0xb3>
