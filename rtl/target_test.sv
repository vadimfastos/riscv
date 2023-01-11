`include "dev_defines.sv"


/* Тестирование SoC с тестовым переферийным устройством */
module target_test #(
	parameter RAM_INIT_FILE = "firmware_test.mem",
	parameter RAM_SIZE = 64*1024
) (

	/* Тактовые импульсы и сигнал синхронного сброса */
	input clk, rstn,
	
	/* Тестовое устройство ввода-вывода (1024 байт ввод, 1024 байт вывод + возможность посыла сигнала прерывания) */
	input logic dev_test_irq,				// сигнал прерывания от тестбенча, его нужно передать на обработку
	input logic [7:0] dev_test_in[0:1023],	// ввод данных с тестбенча
	output logic [7:0] dev_test_out[0:1023]	// вывод данных на тестбенч
);

	// Параметры периферийных устройств
	localparam DEV_COUNT = 1;
	localparam DEV_TEST__BUS_NUM = 0; 
	
	
	/* Создаём основную часть - SoC */
	BusEntry dev_bus_slaves[0:DEV_COUNT-1]();
	BusConfig dev_bus_config[0:DEV_COUNT-1];
	logic [31:0] dev_int_req, dev_int_fin;
	soc #(
		.SOC_DEV_COUNT(DEV_COUNT),			// количество переферийных устройств
		.RAM_INIT_FILE(RAM_INIT_FILE),		// имя файла с прошивкой
		.RAM_SIZE(RAM_SIZE)					// размер памяти в байтах
	) soc0 (.*);
	
	
	/* Тестовое устройство ввода-вывода (1024 байт ввод, 1024 байт вывод + возможность посыла сигнала прерывания) */
	logic dev_test__irq;
	dev_test dev_test0(.bus(dev_bus_slaves[DEV_TEST__BUS_NUM]), .int_fin_i(dev_int_fin[`DEV_TEST__INT_NUM]), .int_req_o(dev_int_req[`DEV_TEST__INT_NUM]), .*);
	assign dev_bus_config[DEV_TEST__BUS_NUM].addr = `DEV_TEST__START_ADDR;
	assign dev_bus_config[DEV_TEST__BUS_NUM].size = `DEV_TEST__SIZE;
	
	
	/* На входы контроллера прерываний, к которым не подключены устройства, должны подаваться нули */
	generate
		for (genvar i=0; i<32; i++)
			if (i!=`DEV_TEST__INT_NUM)
				assign dev_int_req[i] = 0;
	endgenerate
	
	
endmodule
