/* Конфигурация шина и прерываний для переферийных устройств. Для каждого устройства нужно задать:
 * 1) его номер на шине (задаётся в главном модуле, при генерации модуля SoC)
 * 2) начальный адрес и размер участка памяти
 * 3) номер прерывания (если есть)
 */



/* Тестовое переферийное устройство (1 КБайт ввод, 1 КБайт вывод + возможность посыла сигнала прерывания) */
`define DEV_TEST__START_ADDR 32'hC0000000
`define DEV_TEST__SIZE 32'h1000
`define DEV_TEST__INT_NUM 16



/*  Базовый ввод/вывод. Переключатели и кнопки. Светодиоды, семисегментные индикаторы. */
`define DEV_BASIO_IO__START_ADDR 32'hC0001000
`define DEV_BASIO_IO__SIZE 32'h1000
`define DEV_BASIO_IO__INT_NUM 17

`define DEV_BASIO_IO__REG_INPUT_SW 0
`define DEV_BASIO_IO__REG_INPUT_BTN 4
`define DEV_BASIO_IO__REG_OUTPUT_LEDS 8
`define DEV_BASIO_IO__REG_OUTPUT_RGB 12
`define DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE 16
`define DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER 20



/* Переферийное устройство: UART интерфейс. Позволяет обмениваться данными с компьютером. */
`define DEV_UART__START_ADDR 32'hC0002000
`define DEV_UART__SIZE 32'h1000
`define DEV_UART__INT_NUM 18

`define DEV_UART__REG_CONTROL_STATUS 0
`define DEV_UART__REG_RXD 4
`define DEV_UART__REG_TXD 8

`define DEV_UART__CSR_RX_DATA_READY 0
`define DEV_UART__CSR_RX_CLEAR 1
`define DEV_UART__CSR_TX_BUSY 16
`define DEV_UART__CSR_TX_REQ 17
