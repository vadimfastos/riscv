#ifndef DEV_BASIC_IO_H
#define DEV_BASIC_IO_H


#include <stdint.h>


// Ресурсы устройства
#define DEV_BASIO_IO__START_ADDR 0xC0001000
#define DEV_BASIO_IO__SIZE 0x1000
#define DEV_BASIO_IO__INT_NUM 17

// Относительные адреса регистров устройства
#define DEV_BASIO_IO__REG_INPUT_SW 0
#define DEV_BASIO_IO__REG_INPUT_BTN 4
#define DEV_BASIO_IO__REG_OUTPUT_LEDS 8
#define DEV_BASIO_IO__REG_OUTPUT_RGB 12
#define DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE 16
#define DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER 20

// Кнопки
#define DEV_BASIO_IO__BTND 0x01
#define DEV_BASIO_IO__BTNR 0x02
#define DEV_BASIO_IO__BTNL 0x04
#define DEV_BASIO_IO__BTNU 0x08
#define DEV_BASIO_IO__BTNC 0x10

// RGB светодиоды
#define DEV_BASIO_IO__RGB_R1 0x01
#define DEV_BASIO_IO__RGB_G1 0x02
#define DEV_BASIO_IO__RGB_B1 0x04
#define DEV_BASIO_IO__RGB_R2 0x08
#define DEV_BASIO_IO__RGB_G2 0x10
#define DEV_BASIO_IO__RGB_B2 0x20



/* -------------------------------------------------- Чтение состояния кнопок и переключателей -------------------------------------------------- */

static inline uint16_t dev_basic_io__switches_get() {
	volatile uint32_t *reg_input_sw = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_INPUT_SW);
	return *reg_input_sw;
}

static inline uint8_t dev_basic_io__buttons_get() {
	volatile uint32_t *reg_input_btn = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_INPUT_BTN);
	return *reg_input_btn;
}



/* -------------------------------------------------- Управление одноцветными светодиодами -------------------------------------------------- */

static inline uint16_t dev_basic_io__leds_get() {
	volatile uint32_t *reg_output_leds = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_LEDS);
	return *reg_output_leds;
}

static inline void dev_basic_io__leds_set(uint16_t state) {
	volatile uint32_t *reg_output_leds = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_LEDS);
	*reg_output_leds = state;
}



/* -------------------------------------------------- Управление RGB светодиодами -------------------------------------------------- */

static inline uint8_t dev_basic_io__rgb_get() {
	volatile uint32_t *reg_output_rgb = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_RGB);
	return *reg_output_rgb;
}

static inline void dev_basic_io__rgb_set(uint8_t state) {
	volatile uint32_t *reg_output_rgb = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_RGB);
	*reg_output_rgb = state;	
}



/* -------------------------------------------------- Управление семисегментными индикаторами -------------------------------------------------- */

static inline void dev_basic_io__7sd_enable(uint8_t state) {
	volatile uint32_t *reg_7sd_enable = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE);
	*reg_7sd_enable = state;	
}

static inline void dev_basic_io__7sd_output(uint32_t number) {
	volatile uint32_t *reg_7sd_number = (uint32_t*)(DEV_BASIO_IO__START_ADDR + DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER);
	*reg_7sd_number = number;
}



#endif
