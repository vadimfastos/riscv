`timescale 1ns / 100ps


/* Тестирование SoC с платой */
module tb__target_demoboard;
	
	/* Тактовые импульсы и сигнал сброса */
    logic CLK100MHZ;
    logic CPU_RESETN;
	always begin
		CLK100MHZ = 1'b0;
		#5;
		CLK100MHZ = 1'b1;
		#5;
	end
	initial begin
		CPU_RESETN = 1'b0;
		#1000;
		CPU_RESETN = 1'b1;
	end
	
	
	/* Базовый ввод/вывод. Переключатели и кнопки. Светодиоды, семисегментные индикаторы. */
	logic [15:0] SW; // переключатели
    logic BTNC, BTNU, BTNL, BTNR, BTND; // кнопки
    logic [15:0] LED; // одноцветные светодиоды
    logic LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B; // RGB светодиоды
    logic CA, CB, CC, CD, CE, CF, CG; // семисегментные индикаторы (данные)
    logic [7:0] AN; // семисегментные индикаторы (выбор индикатора)
	
	/* USB-RS232 Interface (UART) */
	logic UART_TXD_IN;
	logic UART_RXD_OUT;
	
	/* Подключаем тестируемое устройство */
    target_board # (
		.RAM_INIT_FILE("firmware_demoboard.mem")
	) DUT(.*);
	
	
	/* Тестируем устройство */
	initial begin
		SW = 16'b0;
		BTNC = 1'b0;
		BTNU = 1'b0;
		BTNL = 1'b0;
		BTNR = 1'b0;
		BTND = 1'b0;
		UART_TXD_IN = 1'b1;
		#100000;
		
		/* 1) С переключателей считываются два 8-битных числа (первое - с SW[0]-SW[7], второе - с SW[8]-SW[15]).
		Их произведение выводится на светодиоды (16 бит) и на младшие 4 семисегментника,
		их целочисленное частное - на 2 средних семисегментника, а остаток - на 2 старших. */
		SW = 16'hF712;
		#100000;
		$display("0xF7 * 0x12 = ", 16'hF7 * 16'h12, "; program_out = ", LED);
		
		/* 2) Кнопки управляют состоянием RGB светодиодов. Кнопка C гасит все светодиоды.
		Кнопками R и L можно выбрать светодиод и его канал.
		Кнопка D гасит светодиод, U - зажигает. */
		BTNL = 1'b1;
		#100000;
		BTNL = 1'b0;
		#100000;
		
		BTNU = 1'b1;
		#100000;
		BTNU = 1'b0;
		#100000;
		
		$finish;
	end
	
endmodule
