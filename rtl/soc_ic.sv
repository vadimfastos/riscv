module soc_ic(

	// �������� ������ � ������ ������
	input clk,
	input rstn,
	
	// ������������ � ���� ����������
	input [31:0] mie_i,		// ����� ����������
	input int_rst_i,		// ������ � ���������� ��������� ����������
	output int_o,			// ������ � ������� ����������
	output [31:0] mcause_o,	// ����� ����������
	
	// ������������ � ������������ �����������
	input [31:0] int_req_i,    // ������� ���������� �� ���������
	output [31:0] int_fin_o    // ������� � ���������� ��������� ����������
	
);

	// ����������, �������������� �� ������ �����-���� ���������� ��� ���
	logic is_interrupt;
	
	
	// ����� �������� ������������� ����������
	logic [4:0] cur_int_num;
	always_ff @(posedge clk) begin
		if (!rstn || int_rst_i) begin
			cur_int_num <= 5'b0;
		end else begin
			if (!is_interrupt)
				cur_int_num <= cur_int_num + 1;
		end
	end
	assign mcause_o = {27'b0, cur_int_num};
	
	
	// ���������� ���������� � ���������; ���� ���� �� ����� ����� 1, �� ��������������� ���������� ����� ��������������
	logic [31:0] int_ack;
	assign int_ack = (32'b1 << cur_int_num) & int_req_i & mie_i;
	assign is_interrupt = |int_ack;
	
	
	// ������� � ���������� ��������� ����������
	assign int_fin_o = int_ack & {32{int_rst_i}};
	
	
	// ������� ������ �� ��������� ���������� ����������
	logic is_interrupt_trig;
	always_ff @(posedge clk) begin
		if (!rstn || int_rst_i) is_interrupt_trig <= 1'b0;
		else is_interrupt_trig <= is_interrupt;
	end
	assign int_o = is_interrupt ^ is_interrupt_trig;
	
	
endmodule
