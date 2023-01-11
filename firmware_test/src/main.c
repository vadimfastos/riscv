#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "soc.h"
#include "calc.h"


// Тестовое периферийное устройство (1024 байт ввод, 1024 байт вывод + возможность посыла сигнала прерывания)
#define DEV_TEST__INPUT_ADDR 0xC0000000
#define DEV_TEST__INPUT_SIZE 1024
#define DEV_TEST__OUTPUT_ADDR 0xC0000400
#define DEV_TEST__OUTPUT_SIZE 1024
#define DEV_TEST__INT_NUM 16

// Флаг получения данных от устройства ввода. Выставляется прерыванием, сбрасывается при обработке строки
volatile bool dev_test__input_received = false;

int dev_test__output_pos = 0;



int main(int argc, char **argv) {
	
	soc_interrupt_enable(DEV_TEST__INT_NUM);
	
	// Очищаем память для вывода
	uint32_t *mmo = (uint32_t *)DEV_TEST__OUTPUT_ADDR;
	for (int i=0; i<DEV_TEST__OUTPUT_SIZE/4; i++)
		mmo[i] = 0;
	dev_test__output_pos = 0;
	
	printf("Hello, world!\nThis is test program for my own design SoC.\n");
	printf("This is a simple calculator, it can calc expressions with +,- and * in integer numbers.\n");
	
	// Ждём ввода выражения, подсчитываем его и выводим результат
	while (1) {
		
		char buffer[DEV_TEST__INPUT_SIZE];
		while (!dev_test__input_received) ;
		strncpy(buffer, (char*)(DEV_TEST__INPUT_ADDR), DEV_TEST__INPUT_SIZE);
		dev_test__input_received = false;
		
		int result;
		if (calc(buffer, &result))
			printf("%s = %d\n", buffer, result);
		dev_test__output_pos = 0;
		
	}
	return 0;
}


// Обработчик прерываний от тестового устройства
void interrupt_handler(uint32_t int_num) {
	if (int_num != DEV_TEST__INT_NUM)
		return;
	dev_test__input_received = true;
}


// Вывод символа на устройство
int putchar(int c) {
	char *mmo = (char *)DEV_TEST__OUTPUT_ADDR;
	mmo[dev_test__output_pos] = (char)c;
	dev_test__output_pos++;
	mmo[dev_test__output_pos] = 0;
		/* Для повышения производительности отключим проверку на выход из границ памяти
		if (dev_test__output_pos >= DEV_TEST__OUTPUT_SIZE)
			dev_test__output_pos = 0;*/
	return c;
}


// Вывод строки на устройство
int puts(const char *s) {
	char *mmo = (char *)DEV_TEST__OUTPUT_ADDR;
	while (*s) {
		mmo[dev_test__output_pos] = *s;
		dev_test__output_pos++;
		mmo[dev_test__output_pos] = 0;
		s++;
		/* Для повышения производительности отключим проверку на выход из границ памяти
		if (dev_test__output_pos >= DEV_TEST__OUTPUT_SIZE)
			dev_test__output_pos = 0;*/
	}
	return 0;
}
