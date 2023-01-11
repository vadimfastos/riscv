`timescale 1ns / 100ps


/* ������������ SoC � ������ */
module tb__target_demoboard;
	
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
		.RAM_INIT_FILE("firmware_demoboard.mem")
	) DUT(.*);
	
	
	/* ��������� ���������� */
	initial begin
		SW = 16'b0;
		BTNC = 1'b0;
		BTNU = 1'b0;
		BTNL = 1'b0;
		BTNR = 1'b0;
		BTND = 1'b0;
		UART_TXD_IN = 1'b1;
		#100000;
		
		/* 1) � �������������� ����������� ��� 8-������ ����� (������ - � SW[0]-SW[7], ������ - � SW[8]-SW[15]).
		�� ������������ ��������� �� ���������� (16 ���) � �� ������� 4 ���������������,
		�� ������������� ������� - �� 2 ������� ���������������, � ������� - �� 2 �������. */
		SW = 16'hF712;
		#100000;
		$display("0xF7 * 0x12 = ", 16'hF7 * 16'h12, "; program_out = ", LED);
		
		/* 2) ������ ��������� ���������� RGB �����������. ������ C ����� ��� ����������.
		�������� R � L ����� ������� ��������� � ��� �����.
		������ D ����� ���������, U - ��������. */
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
