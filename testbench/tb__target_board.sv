`timescale 1ns / 100ps


/* ������������ SoC � ������ */
module tb__target_board;
	
	/* �������� �������� � ������ ������ */
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
	
	
	/* ������� ����/�����. ������������� � ������. ����������, �������������� ����������. */
	logic [15:0] SW; // �������������
    logic BTNC, BTNU, BTNL, BTNR, BTND; // ������
    logic [15:0] LED; // ����������� ����������
    logic LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B; // RGB ����������
    logic CA, CB, CC, CD, CE, CF, CG; // �������������� ���������� (������)
    logic [7:0] AN; // �������������� ���������� (����� ����������)
	
	/* USB-RS232 Interface (UART) */
	logic UART_TXD_IN;
	logic UART_RXD_OUT;
	
	/* ���������� ����������� ���������� */
    target_board # (
		.RAM_INIT_FILE("firmware_board.mem")
	) DUT(.*);
	
	
	// ���������� ���������� UART ����������
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
		
		// �������� �������� � ������ ������
		.clk(uart_clk),
		.rstn(CPU_RESETN),
	
		// ���� ������
		.rx_data(uart_rx_data), 	// �������� ������, ������� ��� rx_ready=1
		.rx_ready(uart_rx_ready),	// ������������ � 1 �� 1 ����, ����� �������� ������ ������� (����� ���������� ����� �����)
	
		// �������� ������
		.tx_data(uart_tx_data),	// ������, ������� ����� ��������
		.tx_req(uart_tx_req),	// ����� ��������� � 1 �� 1 ����, ����� ������ �������� ������, ����� tx_busy=0
		.tx_busy(uart_tx_busy),	// ���� ��������� �����������
	
		// ��������� UART
		.rxd(UART_RXD_OUT),
		.txd(UART_TXD_IN)
	);
	
	
	// ������� ����� �� UART
	task uart_send_byte(input byte data);
	
		// ���, ���� ���������� UART �� ����� ��������
		while (uart_tx_busy)
			#1;
		
		// �������� ������ �� �������� ������
		uart_tx_data <= data;
		@(posedge uart_clk);
		uart_tx_req <= 1;
		@(posedge uart_clk);
		uart_tx_req <= 0;
		@(posedge uart_clk);
		
		// ������� ��������� ���������
		while (uart_tx_busy)
			#1;
	endtask
	
	
	// ���� ����� �� UART
	task uart_receive_byte(output byte data);
		// ��� ����������� ������
		while (!uart_rx_ready)
			#1;
		
		// ����� ���������
		data <= uart_rx_data;
		@(posedge uart_clk);
	endtask
	
	
	// ������� ������ �� UART
	task uart_send_string(input string data);
		for (int i=0; i<data.len(); i++)
			uart_send_byte(data[i]);
	endtask
	
	
	// ���� ������ �� UART
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
	
	
	// ������������ ������������ (���� ��������� � ����� ���������� � �������)
	task calc_test(input string exp);
		string ans;
		uart_send_string(exp);
		uart_receive_string(ans);
		$display("'%s': %s", exp, ans);
	endtask
	
	
	/* ��������� ���������� */
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
		
		
		// ��������� ������ "Hello, world!\n"
		uart_receive_string(hello_world);
		$display(hello_world);
		
		
		/* 1) � �������������� ����������� ��� 8-������ ����� (������ - � SW[0]-SW[7], ������ - � SW[8]-SW[15]).
		�� ������������ ��������� �� ���������� (16 ���) � �� ������� 4 ���������������,
		�� ������������� ������� - �� 2 ������� ���������������, � ������� - �� 2 �������. */
		SW = 16'hF712;
		#40000;
		$display("0xF7 * 0x12 = ", 16'hF7 * 16'h12, "; program_out = ", LED);
		
		
		/* 2) ������ ��������� ���������� RGB �����������. ������ C ����� ��� ����������.
		�������� R � L ����� ������� ��������� � ��� �����.
		������ D ����� ���������, U - ��������. */
		BTNL = 1'b1;
		#40000;
		BTNL = 1'b0;
		#40000;
		
		BTNU = 1'b1;
		#40000;
		BTNU = 1'b0;
		#40000;
		
		
		/* 3) �������������� � ����������� ����� UART. ��������� ������� ���������� �� ��������� � ���������� ��������� �� UART. */
		calc_test("2+2="); //  4
		calc_test("21-23+12="); // 10
		calc_test("561245+3154-114+971="); // 565256
		calc_test("14*12*3-1218+1331="); // 617
		calc_test("12-35*31+51*19-12*14*1+3="); // -269
		
		$finish;
	end
	
endmodule
