`timescale 1ns / 100ps


/* Тестирование SoC с платой */
module tb__target_board;
	
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
		.RAM_INIT_FILE("firmware_board.mem")
	) DUT(.*);
	
	
	// Подключаем реализацию UART интерфейса
	logic uart_rx_ready, uart_tx_req, uart_tx_busy;
	logic [7:0] uart_rx_data, uart_tx_data;
	logic uart_clk;
	always begin
		uart_clk = 0;
		#25;
		uart_clk = 1;
		#25;
	end
	uart # (
		.CLOCK_FREQUENCY(20*1000*1000)
	) tb_uart0 (
		
		// тактовые импульсы и сигнал сброса
		.clk(uart_clk),
		.rstn(CPU_RESETN),
	
		// приём данных
		.rx_data(uart_rx_data), 	// принятые данные, валидны при rx_ready=1
		.rx_ready(uart_rx_ready),	// выставляется в 1 на 1 такт, когда принятые данные валидны (после очередного приёма байта)
	
		// передача данных
		.tx_data(uart_tx_data),	// данные, которые нужно передать
		.tx_req(uart_tx_req),	// нужно выставить в 1 на 1 такт, чтобы начать передачу данных, когда tx_busy=0
		.tx_busy(uart_tx_busy),	// флаг занятости передатчика
	
		// интерфейс UART
		.rxd(UART_RXD_OUT),
		.txd(UART_TXD_IN)
	);
	
	
	// Посылка байта по UART
	task uart_send_byte(input byte data);
	
		// ждём, пока передатчик UART не будет свободен
		while (uart_tx_busy)
			#1;
		
		// посылаем запрос на передачу данных
		uart_tx_data <= data;
		@(posedge uart_clk);
		uart_tx_req <= 1;
		@(posedge uart_clk);
		uart_tx_req <= 0;
		@(posedge uart_clk);
		
		// ожидаем окончания пересылки
		while (uart_tx_busy)
			#1;
	endtask
	
	
	// Приём байта по UART
	task uart_receive_byte(output byte data);
		// ждём поступления данных
		while (!uart_rx_ready)
			#1;
		
		// выдаём результат
		data <= uart_rx_data;
		@(posedge uart_clk);
	endtask
	
	
	// Посылка строки по UART
	task uart_send_string(input string data);
		for (int i=0; i<data.len(); i++)
			uart_send_byte(data[i]);
	endtask
	
	
	// Приём строки по UART
	task uart_receive_string(output string data);
		byte ch;
		data = "";
		while (1) begin
			uart_receive_byte(ch);
			#1;
			if (ch < 8'h20)
				break;
			data = {data, ch};
		end
	endtask
	
	
	// Тестирование калькулятора (ввод выражения и вывод результата в консоль)
	task calc_test(input string exp);
		string ans;
		uart_send_string(exp);
		uart_receive_string(ans);
		$display("'%s': %s", exp, ans);
	endtask
	
	
	/* Тестируем устройство */
	string hello_world;
	initial begin
		SW = 16'b0;
		BTNC = 1'b0;
		BTNU = 1'b0;
		BTNL = 1'b0;
		BTNR = 1'b0;
		BTND = 1'b0;
		uart_tx_req = 1'b0;
		#100;
		
		
		// Принимаем строку "Hello, world!\n"
		uart_receive_string(hello_world);
		$display(hello_world);
		
		
		/* 1) С переключателей считываются два 8-битных числа (первое - с SW[0]-SW[7], второе - с SW[8]-SW[15]).
		Их произведение выводится на светодиоды (16 бит) и на младшие 4 семисегментника,
		их целочисленное частное - на 2 средних семисегментника, а остаток - на 2 старших. */
		SW = 16'hF712;
		#40000;
		$display("0xF7 * 0x12 = ", 16'hF7 * 16'h12, "; program_out = ", LED);
		
		
		/* 2) Кнопки управляют состоянием RGB светодиодов. Кнопка C гасит все светодиоды.
		Кнопками R и L можно выбрать светодиод и его канал.
		Кнопка D гасит светодиод, U - зажигает. */
		BTNL = 1'b1;
		#40000;
		BTNL = 1'b0;
		#40000;
		
		BTNU = 1'b1;
		#40000;
		BTNU = 1'b0;
		#40000;
		
		
		/* 3) Взаимодействие с компьютером через UART. Программа считает переденное ей выражение и возвращает результат по UART. */
		calc_test("2+2="); //  4
		calc_test("21-23+12="); // 10
		calc_test("561245+3154-114+971="); // 565256
		calc_test("14*12*3-1218+1331="); // 617
		calc_test("12-35*31+51*19-12*14*1+3="); // -269
		
		$finish;
	end
	
endmodule
