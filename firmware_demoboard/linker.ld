OUTPUT_FORMAT("elf32-littleriscv")
ENTRY(__start)


/* Настройка памяти */
__MEMORY_START = 0x0;
__MEMORY_SIZE = 0x10000;
__INTERRUPT_STACK_SIZE = 8192;


MEMORY {
   ram (rwx) : ORIGIN = __MEMORY_START, LENGTH = __MEMORY_SIZE
}


SECTIONS {
	
	/* Секция загрузчика и кода программ */
	. = __MEMORY_START;
	PROVIDE(__start = __MEMORY_START);
	.text : {
		*(.boot);
		*(.text*);
		. = ALIGN(4);
	}
	
	/* Инициализированные данные */
	. = ALIGN(4);
	__global_pointer = . + 0x800;
	.data : {
		*(.data*);
		. = ALIGN(4);
		*(.rodata*);
		. = ALIGN(4);
	}
	
	/* Неициализированные данные (их загрузчик должен заполнить нулями) */
	. = ALIGN(4);
	__bss_start = .;
	.bss : {
		*(.bss*)
		. = ALIGN(4);
		*(.sbss*)
		. = ALIGN(4);
	}
	. = ALIGN(4);
	__bss_end = .;
	
	/* Стек программ и стек прерываний */
	PROVIDE(__program_stack_top = __MEMORY_START + __MEMORY_SIZE - __INTERRUPT_STACK_SIZE);
	PROVIDE(__interrupt_stack_top = __MEMORY_START + __MEMORY_SIZE);
	
}
