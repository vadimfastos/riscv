#include <stdbool.h>
#include <stdint.h>
#include "dev_basic_io.h"



/* Программа:
	1) С переключателей считываются два 8-битных числа (первое - с SW[0]-SW[7], второе - с SW[8]-SW[15]).
		Их произведение выводится на светодиоды (16 бит) и на младшие 4 семисегментника,
		их целочисленное частное - на 2 средних семисегментника, а остаток - на 2 старших.
	2) Кнопки управляют состоянием RGB светодиодов. Кнопка C гасит все светодиоды. Кнопками R и L можно выбрать светодиод и его канал.
		Кнопка D гасит светодиод, U - зажигает.
*/


int main(int argc, char **argv) {
	
	// Для того, чтобы понять какое событие произошло, будем хранить прошлое состояние
	uint16_t sw_old = 0;
	uint8_t btn_old = 0;	
	
	uint8_t cur_rgb = 0; // текущий канал текущего светодиода (0-5)
	dev_basic_io__rgb_set(0);
	
	// Опрашиваем кнопки и переключатели в цикле
	bool is_init = false;
	while (true) {
		uint16_t sw = dev_basic_io__switches_get();
		uint8_t btn = dev_basic_io__buttons_get();
		
		// Обработка состояния переключателей
		if (sw!=sw_old || !is_init) {
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
		
		// Запоминаем новые значения
		sw_old = sw;
		btn_old = btn;
		is_init = true;
	}
	
	return 0;
}


void interrupt_handler(uint32_t int_num) {}
