#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "soc.h"
#include "dev_basic_io.h"
#include "dev_uart.h"
#include "calc.h"



/* Программа:
	1) С переключателей считываются два 8-битных числа (первое - с SW[0]-SW[7], второе - с SW[8]-SW[15]).
		Их произведение выводится на светодиоды (16 бит) и на младшие 4 семисегментника,
		их целочисленное частное - на 2 средних семисегментника, а остаток - на 2 старших.
	2) Кнопки управляют состоянием RGB светодиодов. Кнопка C гасит все светодиоды. Кнопками R и L можно выбрать светодиод и его канал.
		Кнопка D гасит светодиод, U - зажигает.
	3) Взаимодействие с компьютером через UART. Программа считает переденное ей выражение и возвращает результат по UART.
	
	Части 1 и 2 работают в прерывании. Часть 3 - в основном цикле.
*/

void dev_basic_io_interrupt(bool is_init);


int main(int argc, char **argv) {
	dev_basic_io_interrupt(true);
	soc_interrupt_enable(DEV_BASIO_IO__INT_NUM);
	soc_interrupt_enable(DEV_UART__INT_NUM);
	
	printf("Hello, world!\n");
	// Взаимодействие с компьютером через UART. Программа считает переденное ей выражение и возвращает результат по UART.
	while (1) {
		
		// Читаем строку по UART, до знака '='
		const int buffer_size = 1024;
		char buffer[buffer_size];
		int buffer_pos = 0;
		
		while (buffer_pos < buffer_size-1) {
			buffer[buffer_pos] = getchar();
			if (buffer[buffer_pos] == '=')
				break;
			buffer_pos++;
		}
		buffer[buffer_pos] = 0;
		dev_uart__rx_clear();
		
		
		// Подсчитываем выражение и выводим результат
		int result;
		if (calc(buffer, &result))
			printf("%s = %d\n", buffer, result);
	}
	return 0;
}



// Обработчик прерываний от переключателей и кнопок. Выполняет 1 и 2 части программы
void dev_basic_io_interrupt(bool is_init) {
	
	uint16_t sw = dev_basic_io__switches_get();
	uint8_t btn = dev_basic_io__buttons_get();
	
	// Для того, чтобы понять какое событие произошло, будем хранить прошлое состояние
	static uint16_t sw_old = 0;
	static uint8_t btn_old = 0;	
	
	
	// Обработка состояния переключателей
	if (sw!=sw_old || is_init) {
		uint32_t a = sw & 0xFF;
		uint32_t b = sw >> 8;
		uint32_t mul = a * b;
		uint32_t div = a / b;
		uint32_t rem = a % b;
	
		dev_basic_io__leds_set(mul);
		dev_basic_io__7sd_enable(0xFF);
		dev_basic_io__7sd_output(mul | div<<16 | rem<<24);	
	}
	
	
	// Обработка состояния кнопок
	if (btn != btn_old) {
		uint8_t pressed = btn & (~btn_old);
		
		static uint8_t cur_rgb = 0; // текущий канал текущего светодиода (0-5)
		switch (pressed) {
			case DEV_BASIO_IO__BTNC:
				dev_basic_io__rgb_set(0);
				break;
			case DEV_BASIO_IO__BTNL:
				if (cur_rgb < 5)
					cur_rgb++;
				break;
			case DEV_BASIO_IO__BTNR:
				if (cur_rgb > 0)
					cur_rgb--;
				break;
			case DEV_BASIO_IO__BTND: {
				uint8_t rgb_old = dev_basic_io__rgb_get();
				dev_basic_io__rgb_set( rgb_old & (~(0x01<<cur_rgb)) );
				break;
			}
			case DEV_BASIO_IO__BTNU: {
				uint8_t rgb_old = dev_basic_io__rgb_get();
				dev_basic_io__rgb_set( rgb_old | (0x01<<cur_rgb) );
				break;
			}
		}
	}
	if (is_init)
		dev_basic_io__rgb_set(0);
	
	
	// Запоминаем новые значения
	sw_old = sw;
	btn_old = btn;
}


// Обзорный обработчик прерываний
void interrupt_handler(uint32_t int_num) {
	switch (int_num) {
		case DEV_BASIO_IO__INT_NUM: dev_basic_io_interrupt(false); break;
		case DEV_UART__INT_NUM: dev_uart_interrupt(); break;
		default: break;
	}
}



int getchar(void) {
	uint8_t ch = dev_uart__receive_byte();
	return ch;
}

int putchar(int c) {
	dev_uart__send_byte(c);
	return c;
}

int puts(const char *s) {
	while (*s != 0) {
		dev_uart__send_byte(*s);
		s++;
	}
	return 0;
}
