`include "dev_defines.sv"


/* Этот модуль предназначается для заливки на плату */
module target_board #(
	parameter RAM_INIT_FILE = "firmware_board.mem",
	//parameter RAM_INIT_FILE = "firmware_demoboard.mem",
	parameter RAM_SIZE = 64*1024
) (

    /* Тактовые импульсы и сигнал сброса */
    input CLK100MHZ,
    input CPU_RESETN,
	
	/* Базовый ввод/вывод. Переключатели и кнопки. Светодиоды, семисегментные индикаторы. */
	input [15:0] SW, // переключатели
    input BTNC, BTNU, BTNL, BTNR, BTND, // кнопки
    output [15:0] LED, // одноцветные светодиоды
    output LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B, // RGB светодиоды
    output CA, CB, CC, CD, CE, CF, CG, // семисегментные индикаторы (данные)
    output [7:0] AN, // семисегментные индикаторы (выбор индикатора)
	
	/* USB-RS232 Interface (UART) */
	input UART_TXD_IN,
	output UART_RXD_OUT

);
	
	// Параметры периферийных устройств
	localparam DEV_COUNT = 2;
	localparam DEV_BASIO_IO__BUS_NUM = 0; 
	localparam DEV_UART__BUS_NUM = 1; 
	
	
	/* Тактовые импульсы и сигнал синхронного сброса. Сигнал clk генерируем с помощью PLL. */
	logic clk, rstn;
	localparam CLK_PLL_MUL = 8;
	localparam CLK_PLL_DIV = 32;
	localparam CLOCK_FREQUENCY = (100*1000*1000*CLK_PLL_MUL)/CLK_PLL_DIV;
	
	
	/* Создаём основную часть - SoC */
	BusEntry dev_bus_slaves[0:DEV_COUNT-1]();
	BusConfig dev_bus_config[0:DEV_COUNT-1];
	logic [31:0] dev_int_req, dev_int_fin;
	soc #(
		.SOC_DEV_COUNT(DEV_COUNT),			// количество переферийных устройств
		.RAM_INIT_FILE(RAM_INIT_FILE),		// имя файла с прошивкой
		.RAM_SIZE(RAM_SIZE)					// размер памяти в байтах
	) soc0 (.*);
	
	
	// Подключаем устройство для базового ввода-вывода. Переключатели и кнопки. Светодиоды, семисегментные индикаторы.
	logic [15:0] ld;
	dev_basic_io # (
		.CLOCK_FREQUENCY(CLOCK_FREQUENCY)
	) dev_basic_io0(.bus(dev_bus_slaves[DEV_BASIO_IO__BUS_NUM]), .int_fin_i(dev_int_fin[`DEV_BASIO_IO__INT_NUM]), .int_req_o(dev_int_req[`DEV_BASIO_IO__INT_NUM]), .*);
	assign dev_bus_config[DEV_BASIO_IO__BUS_NUM].addr = `DEV_BASIO_IO__START_ADDR;
	assign dev_bus_config[DEV_BASIO_IO__BUS_NUM].size = `DEV_BASIO_IO__SIZE;

	
	// Подключаем UART интерфейс. Позволяет обмениваться данными с компьютером. 
	dev_uart # (
		.CLOCK_FREQUENCY(CLOCK_FREQUENCY)
	) dev_uart0 (.bus(dev_bus_slaves[DEV_UART__BUS_NUM]), .int_fin_i(dev_int_fin[`DEV_UART__INT_NUM]), .int_req_o(dev_int_req[`DEV_UART__INT_NUM]), .*);
	assign dev_bus_config[DEV_UART__BUS_NUM].addr = `DEV_UART__START_ADDR;
	assign dev_bus_config[DEV_UART__BUS_NUM].size = `DEV_UART__SIZE;
	
	
	/* На входы контроллера прерываний, к которым не подключены устройства, должны подаваться нули */
	generate
		for (genvar i=0; i<32; i++)
			if (i!=`DEV_BASIO_IO__INT_NUM && i!=`DEV_UART__INT_NUM)
				assign dev_int_req[i] = 0;
	endgenerate
	
	
	/* Генерируем тактовый сигнал. Base Phase Locked Loop (PLL) */
	logic CLKOUT0, CLKOUT1, CLKOUT2, CLKOUT3, CLKOUT4, CLKOUT5;
	logic PLL_LOCKED, CLKFB;
	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),		// OPTIMIZED, HIGH, LOW
		.CLKFBOUT_MULT(CLK_PLL_MUL),	// Multiply value for all CLKOUT, (2-64)
		.CLKFBOUT_PHASE(0.0),			// Phase offset in degrees of CLKFB, (-360.000-360.000).
		.CLKIN1_PERIOD(10),				// Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
		
		// CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
		.CLKOUT0_DIVIDE(CLK_PLL_DIV),
		.CLKOUT1_DIVIDE(1),
		.CLKOUT2_DIVIDE(1),
		.CLKOUT3_DIVIDE(1),
		.CLKOUT4_DIVIDE(1),
		.CLKOUT5_DIVIDE(1),
		
		// CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT2_DUTY_CYCLE(0.5),
		.CLKOUT3_DUTY_CYCLE(0.5),
		.CLKOUT4_DUTY_CYCLE(0.5),
		.CLKOUT5_DUTY_CYCLE(0.5),
		
		// CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.DIVCLK_DIVIDE(1),        // Master division value, (1-56)
		.REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
		.STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
		
	) PLLE2_BASE_inst (

		// Clock Outputs: 1-bit (each) output: User configurable clock outputs
		.CLKOUT0(CLKOUT0),	// 1-bit output: CLKOUT0
		.CLKOUT1(CLKOUT1),	// 1-bit output: CLKOUT1
		.CLKOUT2(CLKOUT2),	// 1-bit output: CLKOUT2
		.CLKOUT3(CLKOUT3),	// 1-bit output: CLKOUT3
		.CLKOUT4(CLKOUT4),	// 1-bit output: CLKOUT4
		.CLKOUT5(CLKOUT5),	// 1-bit output: CLKOUT5
		
		// Feedback Clocks: 1-bit (each) output: Clock feedback ports
		.CLKFBOUT(CLKFB),		// 1-bit output: Feedback clock
		.LOCKED(PLL_LOCKED),	// 1-bit output: LOCK
		.CLKIN1(CLK100MHZ),		// 1-bit input: Input clock
		
		// Control Ports: 1-bit (each) input: PLL control ports
		.PWRDWN(1'b0),	// 1-bit input: Power-down
		.RST(1'b0),		// 1-bit input: Reset
		
		// Feedback Clocks: 1-bit (each) input: Clock feedback ports
		.CLKFBIN(CLKFB)	// 1-bit input: Feedback clock
	);
	assign clk = CLKOUT0;
	
	
	// Генерируем сигнал сброса
	(* ASYNC_REG="TRUE" *) logic [2:0] rstn_sreg = 0;
	always_ff @(posedge clk) begin
		rstn_sreg <= {rstn_sreg[1:0], CPU_RESETN && PLL_LOCKED};
		rstn <= rstn_sreg[2];
	end
	
	
endmodule
