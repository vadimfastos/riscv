`include "dev_defines.sv"


/* Модуль SoC. Содержит шину, процессор, память, контроллер прерываний. Необходимо подключить периферию. */
module soc #(
	parameter SOC_DEV_COUNT=1,		// количество переферийных устройств
	parameter RAM_INIT_FILE="",		// имя файла с прошивкой
	parameter RAM_SIZE = 64*1024	// размер памяти в байтах
) (

	/* Тактовые импульсы и сигнал синхронного сброса */
	input clk, rstn,
	
	/* Подключение переферийных устройств к шине */
	BusEntry.SlaveBus dev_bus_slaves[0:SOC_DEV_COUNT-1],
	
	/* Настройки адресного пространства для каждого периферийного устройства (начальный адрес и размер участка памяти для устройства) */
	BusConfig dev_bus_config[0:SOC_DEV_COUNT-1],
	
	/* Подключение периферийных устройств к контроллеру прерываний */
	input [31:0] dev_int_req,	// запросы прерываний от устройств
	output [31:0] dev_int_fin	// сигналы о завершении обработки прерываний устройствам
);
	
	// Системная шина
	BusEntry bus_core0();
	BusEntry bus_slaves[0:SOC_DEV_COUNT]();
	BusConfig bus_config[0:SOC_DEV_COUNT];
	soc_bus #(
		(SOC_DEV_COUNT + 1) // кол-во ведомых устройств = кол-во переферийных устройств + 1 (для памяти)
	) bus(.clk, .rstn, .master0(bus_core0), .slaves(bus_slaves), .bus_config);
	
	
	// Контроллер прерываний
    logic ic_int;              // запрос на обработку прерывания
	logic ic_int_rst;          // сигнал о завершении обработки прерывания
	logic [31:0] ic_mcause;    // номер прерывания
	logic [31:0] ic_mie;       // маска прерываний
	soc_ic ic0 (
	   
        // синхронизация и сброс
        .clk,
        .rstn,
        
        // подключается к ядру процессора
        .mie_i(ic_mie),
        .int_rst_i(ic_int_rst),
        .int_o(ic_int),
        .mcause_o(ic_mcause),
	     
	    // подключается к периферийным устройствам
        .int_req_i(dev_int_req),
        .int_fin_o(dev_int_fin)
	);
	
	
	// Ядро процессора
	logic [31:0] instr_rdata, instr_addr;
	riscv_core core0 (
	
	    .bus(bus_core0),
		
		// синхронный доступ к инструкциям (по фронту)
		.instr_rdata_i(instr_rdata),
		.instr_addr_o(instr_addr),
		
		// контроллер прерываний
        .ic_int_i(ic_int),
        .ic_mcause_i(ic_mcause),
        .ic_mie_o(ic_mie),
        .ic_int_rst_o(ic_int_rst)
	);
	

	// Подключаем память
	soc_memory #(
		RAM_INIT_FILE,
		RAM_SIZE
	) memory0 (
		
		// подключение к шине
		.bus(bus_slaves[0]),
		
		// синхронный доступ к инструкциям (по фронту)
		.instr_rdata_o(instr_rdata),
		.instr_addr_i (instr_addr)
	);
	assign bus_config[0].addr = 0;
	assign bus_config[0].size = RAM_SIZE;
	
	
	// Подключаем периферийные устройства
	generate
	   for (genvar i=0; i<SOC_DEV_COUNT; i++) begin
	   
			/* Тактовые импульсы и сигнал синхронного сброса */
            assign dev_bus_slaves[i].clk = bus_slaves[i+1].clk;
            assign dev_bus_slaves[i].rstn = bus_slaves[i+1].rstn;
			
			/* Шина адреса и шина данных */
			assign dev_bus_slaves[i].addr = bus_slaves[i+1].addr;
			assign dev_bus_slaves[i].wdata = bus_slaves[i+1].wdata;
			assign bus_slaves[i+1].rdata = dev_bus_slaves[i].rdata;
			
			/* Шина управления */
			assign dev_bus_slaves[i].req = bus_slaves[i+1].req;
			assign dev_bus_slaves[i].we = bus_slaves[i+1].we;
			assign dev_bus_slaves[i].be = bus_slaves[i+1].be;
			assign bus_slaves[i+1].ack = dev_bus_slaves[i].ack;
            assign bus_slaves[i+1].error = 1'b0;
			
	   end
	endgenerate
	assign bus_config[1:SOC_DEV_COUNT] = dev_bus_config;
	
	
endmodule
