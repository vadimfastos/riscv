#ifndef DEV_UART_H
#define DEV_UART_H


#include <stdint.h>


// Ресурсы устройства
#define DEV_UART__START_ADDR 0xC0002000
#define DEV_UART__SIZE 0x1000
#define DEV_UART__INT_NUM 18

#define DEV_UART__REG_CONTROL_STATUS 0
#define DEV_UART__REG_RXD 4
#define DEV_UART__REG_TXD 8


// Регистр REG_CONTROL_STATUS (управление устройством)
#define DEV_UART__CSR_RX_DATA_READY 0x01
#define DEV_UART__CSR_RX_CLEAR 0x02
#define DEV_UART__CSR_TX_BUSY 0x10000
#define DEV_UART__CSR_TX_REQ 0x20000


// Вывод символа через UART
static inline void dev_uart__send_byte(uint8_t byte) {
	volatile uint32_t *reg_csr = (uint32_t *)(DEV_UART__START_ADDR + DEV_UART__REG_CONTROL_STATUS);
	
	// Ждём, пока передатчик не освободится
	while ( ((*reg_csr)&DEV_UART__CSR_TX_BUSY) != 0 )
		;
	
	// Посылаем данные
	volatile uint32_t *reg_txd = (uint32_t *)(DEV_UART__START_ADDR + DEV_UART__REG_TXD);
	*reg_txd = byte;
	*reg_csr = DEV_UART__CSR_TX_REQ;
	
	// Ждём окончания передачи
	while ( ((*reg_csr)&DEV_UART__CSR_TX_BUSY) != 0)
		;
}


// Получение символа через UART
static inline uint8_t dev_uart__receive_byte() {
	
	// Ждём данных
	volatile uint32_t *reg_csr = (uint32_t *)(DEV_UART__START_ADDR + DEV_UART__REG_CONTROL_STATUS);
	while ( ((*reg_csr)&DEV_UART__CSR_RX_DATA_READY) == 0)
		;
	
	// Принимаем данные
	volatile uint32_t *reg_rxd = (uint32_t *)(DEV_UART__START_ADDR + DEV_UART__REG_RXD);
	return *reg_rxd;
}


// Очистить буффер приёма UART
static inline void dev_uart__rx_clear() {
	volatile uint32_t *reg_csr = (uint32_t *)(DEV_UART__START_ADDR + DEV_UART__REG_CONTROL_STATUS);
	*reg_csr = DEV_UART__CSR_RX_CLEAR;
}


// Обработчик прерывания от UART
static inline void dev_uart_interrupt() { }



#endif
