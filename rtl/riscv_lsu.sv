`include "riscv_defines.sv"

// ������ ��������/����������
module riscv_lsu(
    
	// ����������� � ��������� ����
    BusEntry.Master bus,

	// ��� ����� ������������ � ���� ����������
	input lsu_req_i,					// 1 - ���������� � ������
	input lsu_we_i,						// 1 � ���� ����� �������� � ������
	input [31:0] lsu_addr_i,			// �����, �� �������� ����� ����������
	input [2:0] lsu_size_i,				// ������ �������������� ������
	input [31:0] lsu_data_i,			// ������ ��� ������ � ������
	output logic [31:0] lsu_data_o,		// ������ ��������� �� ������
	output logic lsu_stall_req_o,		// ���������� ����������
	output logic lsu_unalign_access_o	// ������ ����������: ������������� ������ � ������
	
);
	
	// ��������� ����� �� ���������� ����� ������ (30 ������� ���) � �������� (2 ����)
	logic [1:0] byte_offset;
	assign byte_offset = lsu_addr_i[1:0];
	assign bus.addr = {lsu_addr_i[31:2], 2'b0};
	
	
	// ��������, ��� �� � ��� �������������� ������� � ������
	logic unalign_access_b, unalign_access_h;
	assign unalign_access_b = byte_offset[0] && (lsu_size_i!=`LDST_B) && (lsu_size_i!=`LDST_BU);
	assign unalign_access_h = byte_offset[1] && (lsu_size_i!=`LDST_H) && (lsu_size_i!=`LDST_HU) && (lsu_size_i!=`LDST_B) && (lsu_size_i!=`LDST_BU);
	assign lsu_unalign_access_o = lsu_req_i && (unalign_access_b || unalign_access_h);
	
	
	// ���������� � ������ �� ���������� ���� ���������� �� ����� ������� � ������
	assign bus.we = bus.req && lsu_we_i;
	
	// ������ � ������
	always_comb begin
        if (lsu_size_i==`LDST_B || lsu_size_i==`LDST_BU) begin
            bus.wdata <= { 4{lsu_data_i[7:0]} };
            bus.be <= 4'b0001 << byte_offset;
        end else if (lsu_size_i==`LDST_H || lsu_size_i==`LDST_HU) begin
            bus.wdata <= { 2{lsu_data_i[15:0]} };
            bus.be <= (byte_offset[1]) ? 4'b1100 : 4'b0011;
        end else begin
            bus.wdata <= lsu_data_i;
            bus.be <= 4'b1111;
        end
    end
	
	
	// �������� ���� �� ������� �������� (����� ��������������, ���� ������������ ����)
	logic [7:0] lb_data;
	always_comb begin
		case (byte_offset)
			2'b00: lb_data <= bus.rdata[7:0];
			2'b01: lb_data <= bus.rdata[15:8];
			2'b10: lb_data <= bus.rdata[23:16];
			2'b11: lb_data <= bus.rdata[31:24];
		endcase
	end
	
	// �������� ��������� �� ������� �������� (����� ��������������, ���� ������������� �����)
	logic [15:0] lh_data;
	assign lh_data = (byte_offset == 2'b10) ? bus.rdata[31:16] : bus.rdata[15:0];
	
	
	// ������ �� ������
	always_comb begin
		case (lsu_size_i)
            `LDST_B: lsu_data_o <= {{24{lb_data[7]}}, lb_data};
            `LDST_H: lsu_data_o <= {{16{lh_data[15]}}, lh_data};
            `LDST_BU: lsu_data_o <= {24'b0, lb_data};
            `LDST_HU: lsu_data_o <= {16'b0, lh_data};
            default: lsu_data_o <= bus.rdata;
		endcase
	end
	
	
	// ���������� � ������ �� ���������� ���� ���������� (�������, ����� �� ���� �������������� �������)
	logic bus_need_req, bus_have_ack;
	assign bus_need_req = !lsu_unalign_access_o && lsu_req_i;
	assign bus_have_ack = bus.ack || bus.error;
	
	
	/* ��� ���������� �� ���� ����� 2 ����: ���� ������ (1 ����) � ���� ������ (1 � ����� ������).
	 * ��� ������� � ���� ��������� �������� �������.
	 */
	enum { IDLE, REQUEST, WAIT } state;
	
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			state <= IDLE;
		end else begin
			
			case (state)
				
				// ���������, �� ������ �� ������ �� ��������� � ������
				IDLE: begin
					if (bus_need_req)
						state <= REQUEST;
				end
				
				// ���������, ������ �� �����
				REQUEST: begin
					if (bus_have_ack) begin
						state <= IDLE;
					end else begin
						state <= WAIT;
					end
				end
				
				// �� ��������� �������� ��������� � ��������� �������, ���� ������ �����
				WAIT: begin
					if (bus_have_ack)
						state <= IDLE;
				end
				
			endcase
			
		end
	end
	
	// ����� ������ �� ����, ���� ��������� ������ � ������
	assign bus.req = (state==IDLE) && bus_need_req;
	
	// ���������������� ���������, ���� ��� �������������� � �����
	assign lsu_stall_req_o = bus_need_req && !bus_have_ack;
	
	
endmodule
