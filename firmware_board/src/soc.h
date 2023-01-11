#ifndef SOC_H
#define SOC_H


// Разрешить прерывание с номером num
static inline void soc_interrupt_enable(uint8_t num) {
	uint32_t mask = 1 << num;
	__asm__ __volatile__(
		"csrs mie, %0\n"
		: // список выходных операндов
		: "r"(mask) // список входных операндов
		: // список разрушаемых регистров
	);
}


// Запретить прерывание с номером num
static inline void soc_interrupt_disable(uint8_t num) {
	uint32_t mask = 1 << num;
	__asm__ __volatile__(
		"csrc mie, %0\n"
		: // список выходных операндов
		: "r"(mask) // список входных операндов
		: // список разрушаемых регистров
	);
}


#endif
