`include "dev_defines.sv"


/* �������� ���������� �����-������ (1024 ���� ����, 1024 ���� ����� + ����������� ������ ������� ����������) */
module dev_test(
	
	/* ����������� � ���� */
	BusEntry.Slave bus,
	input int_fin_i,
	output logic int_req_o,
	
	/* ����������� � testbench */
	input logic dev_test_irq,				// ������ ���������� �� ���������, ��� ����� �������� �� ���������
	input logic [7:0] dev_test_in[0:1023],	// ���� ������ � ���������
	output logic [7:0] dev_test_out[0:1023]	// ����� ������ �� ��������
);
	
	// ����������, � ������ ������� ������ (��� ����� ��� ��� ������) ��� ���������
	logic [9:0] cell_addr;
	assign cell_addr = bus.addr[9:0];
	
	logic is_input, is_output;
	assign is_input = (bus.addr[11:0] < 1024);
	assign is_output = (bus.addr[11:0] >= 1024) && (bus.addr[11:0] < 2048);
	
	
	// ��������� �������� ������
	always_ff @(posedge bus.clk) begin
		if (is_output) begin
			bus.rdata <= {dev_test_out[cell_addr+3], dev_test_out[cell_addr+2], dev_test_out[cell_addr+1], dev_test_out[cell_addr+0]};
		end else if (is_input) begin
			bus.rdata <= {dev_test_in[cell_addr+3], dev_test_in[cell_addr+2], dev_test_in[cell_addr+1], dev_test_in[cell_addr+0]};
		end else begin
			bus.rdata <= 32'b0;
		end
	end
	
	
	// ��������� �������� ������
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			for (int i=0; i<1024; i++)
				dev_test_out[i] <= 0;
		end else if (bus.req && bus.we && is_output) begin
			if (bus.be[0])
				dev_test_out[cell_addr+0] <= bus.wdata[7:0];
			if (bus.be[1])
				dev_test_out[cell_addr+1] <= bus.wdata[15:8];
			if (bus.be[2])
				dev_test_out[cell_addr+2] <= bus.wdata[23:16];
			if (bus.be[3])
				dev_test_out[cell_addr+3] <= bus.wdata[31:24];
		end
	end
	
	
	// ����� ���������� �������� ����� ��������� ������ ���������� �� ����
	always_ff @(posedge bus.clk)
		bus.ack <= bus.req;
	
	
	// ����� ������� ����������
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			int_req_o <= 0;
		end else begin
			if (dev_test_irq && !int_req_o) int_req_o <= 1;
			else if (int_fin_i) int_req_o <= 0;
		end
	end
	
	
endmodule
