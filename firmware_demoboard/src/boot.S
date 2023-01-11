// Загрузчик для RISC-V

// Точка входа в программу - настраиваем стек и глобальные данные
.section .boot
.globl __start
__start:
	la sp, __program_stack_top
	la gp, __global_pointer


// Инициализация (зануление) сегмента bss
	la t0, __bss_start
	la t1, __bss_end
	j __bss_init_compare
__bss_init_loop:
	sw zero, 0(t0)
	addi  t0, t0, 4
__bss_init_compare:
	blt t0, t1, __bss_init_loop


// Настраиваем прерывания (запрещаем все, основная программа сама разрешит нужные)
__init_interrupts:

	// устанавливаем обработчик прерывания
	la t0, __interrupt_handler
	csrw mtvec, t0

	// настраиваем стек прерываний
	la t0, __interrupt_stack_top
	csrw mscratch, t0

	// маска прерываний (запретим все прерывания, высокоуровненная программа сама разрешит нужные)
	li t0, 0
	csrw mie, t0 


/* Вызов функции main
Передача аргументов argc и argv в main. Формально, argc должен
быть больше нуля, а argv должен указывать на массив строк,
нулевой элемент которого является именем исполняемого файла,
Но для простоты реалзации оба аргумента всего лишь обнулены.
Это сделано для детерменированного поведения программы в случае,
если она будет пытаться использовать эти аргументы. */
__main_call:
	li a0, 0
	li a1, 0
	jal main


// Зацикливание после выхода из функции mai
__endless_loop:
	j __endless_loop


// Обработчик прерывания - сохраняем регистры и вызываем нужные функции
__interrupt_handler:
	csrrw sp, mscratch, sp
	addi sp, sp, -64
	
	// Сохраняем регистры a0 - a7 на стек
	sw a0, 0(sp)
	sw a1, 4(sp)
	sw a2, 8(sp)
	sw a3, 12(sp)
	sw a4, 16(sp)
	sw a5, 20(sp)
	sw a6, 24(sp)
	sw a7, 28(sp)
	
	// Сохраняем регистры t0 - t6 на стек
	sw t0, 32(sp)
	sw t1, 36(sp)
	sw t2, 40(sp)
	sw t3, 44(sp)
	sw t4, 48(sp)
	sw t5, 52(sp)
	sw t6, 56(sp)
	
	// Сохраняем адрес возврата на стек (мы будем вызывать другую функцию)
	sw ra, 60(sp)

// Обрабатываем прерывание - узнаём его номер и вызываем высокоуровненный обработчик
__interrupt_handler__switch:
	
	// Узнаём номер прерывания
	csrr a0, mcause
	jal interrupt_handler

// Возвращаем регистры на места и выходим
__interrupt_handler__done:

	// Восстанавливаем регистры a0 - a7 из стека
	lw a0, 0(sp)
	lw a1, 4(sp)
	lw a2, 8(sp)
	lw a3, 12(sp)
	lw a4, 16(sp)
	lw a5, 20(sp)
	lw a6, 24(sp)
	lw a7, 28(sp)
	
	// Восстанавливаем регистры t0 - t6 из стека
	lw t0, 32(sp)
	lw t1, 36(sp)
	lw t2, 40(sp)
	lw t3, 44(sp)
	lw t4, 48(sp)
	lw t5, 52(sp)
	lw t6, 56(sp)
	
	// Восстанавливаем адрес возврата из стека
	lw ra, 60(sp)
	
	addi sp, sp, 64
	csrrw sp, mscratch, sp 
	mret
