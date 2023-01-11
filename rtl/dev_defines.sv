/* ������������ ���� � ���������� ��� ������������ ���������. ��� ������� ���������� ����� ������:
 * 1) ��� ����� �� ���� (������� � ������� ������, ��� ��������� ������ SoC)
 * 2) ��������� ����� � ������ ������� ������
 * 3) ����� ���������� (���� ����)
 */



/* �������� ������������ ���������� (1 ����� ����, 1 ����� ����� + ����������� ������ ������� ����������) */
`define DEV_TEST__START_ADDR 32'hC0000000
`define DEV_TEST__SIZE 32'h1000
`define DEV_TEST__INT_NUM 16



/*  ������� ����/�����. ������������� � ������. ����������, �������������� ����������. */
`define DEV_BASIO_IO__START_ADDR 32'hC0001000
`define DEV_BASIO_IO__SIZE 32'h1000
`define DEV_BASIO_IO__INT_NUM 17

`define DEV_BASIO_IO__REG_INPUT_SW 0
`define DEV_BASIO_IO__REG_INPUT_BTN 4
`define DEV_BASIO_IO__REG_OUTPUT_LEDS 8
`define DEV_BASIO_IO__REG_OUTPUT_RGB 12
`define DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE 16
`define DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER 20



/* ������������ ����������: UART ���������. ��������� ������������ ������� � �����������. */
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
