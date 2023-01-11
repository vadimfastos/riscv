/* ���� ��������� ������ � ������ CSR (������� 2 ���� func3 ������� SYSTEM) */
`define CSR_OP_NONE  2'b00	// ��� ������� (������ �� ������)
`define CSR_OP_CSRRW 2'b01	// ������ + ������ ��������� CSR
`define CSR_OP_CSRRS 2'b10	// ������ + ��������� ��� ��������� CSR
`define CSR_OP_CSRRC 2'b11	// ������ + ������� ��� ��������� CSR

/* ������ ��������� CSR */
`define CSR_REG_MIE 12'h304
`define CSR_REG_MTVEC 12'h305
`define CSR_REG_MSCRATCH 12'h340
`define CSR_REG_MEPC 12'h341
`define CSR_REG_MCAUSE 12'h342


// ���������� ������ CSR
module riscv_csr(
	
	// �������� ������ � ������ ������
	input clk,
	input rstn,
	
	input IC_INT, 		// ������ � ����������
	input [1:0] CSR_OP,	// ������� ��� ����� CSR
	input [11:0] A,		// ����� ��������
	input [31:0] PC,	// ������� ������
	input [31:0] WD,	// ������ ��� ������ � �������� CSR
	output logic [31:0] RD,	// ��������� �� ��������� CSR ������
	
	// ������ � ���� ��������� ��������� ��������� ��� ������ ����������
	input [31:0] mcause_i,	// ����� ����������
	output [31:0] mie_o,	// ����� ����������
	output [31:0] mtvec_o,	// ����� ������ ����������� ����������
	output [31:0] mepc_o	// ����� �������� �������� �������� ������ �� ������ ����������� ����������
	
);
	
	// ����� ����� ������� ��������� ��������, ����������� ��� ������ ������� ����������
	logic [31:0] mie, mtvec, mscratch, mepc, mcause;
	assign mie_o = mie;
	assign mtvec_o = mtvec;
	assign mepc_o = mepc;
	
	
	// ��������� ������ ��������� ���������
	always_comb begin
		case (A)
			`CSR_REG_MIE: RD <= mie;
			`CSR_REG_MTVEC: RD <= mtvec;
			`CSR_REG_MSCRATCH: RD <= mscratch;
			`CSR_REG_MEPC: RD <= mepc;
			`CSR_REG_MCAUSE: RD <= mcause;
			default: RD <= 32'b0;
		endcase
	end
	
	
	// ���������� �������� ��� ���������� CSR (����� �� �� ��������� ������ � ����������, ��� ���� �����, ��� ������)
	logic csr_write_req;
	assign csr_write_req = (CSR_OP==`CSR_OP_CSRRW) || (CSR_OP==`CSR_OP_CSRRS) || (CSR_OP==`CSR_OP_CSRRC);
	
	logic [31:0] csr_new_data;
	always_comb begin
		case (CSR_OP)
			`CSR_OP_CSRRW: csr_new_data <= WD;
			`CSR_OP_CSRRS: csr_new_data <= RD | WD;
			`CSR_OP_CSRRC: csr_new_data <= RD & (~WD);
			default: csr_new_data <= 32'b0;
		endcase
	end
	
	
	// ��������� ������ � �������� mie, mtvec � mscratch
	always_ff @(posedge clk) begin
		if (!rstn) begin
			
			// �������� �������� ��� ����������� ������� ������
			mie <= 32'b0;
			mtvec <= 32'b0;
			mscratch <= 32'b0;
			
		end else begin
			
			// ���������� ������, ���� ��������� ����� �������
			if (csr_write_req)
				case (A)
					`CSR_REG_MIE: mie <= csr_new_data;
					`CSR_REG_MTVEC: mtvec <= csr_new_data;
					`CSR_REG_MSCRATCH: mscratch <= csr_new_data;
				endcase
			
		end
	end
	
	
	// ��������� ������ � �������� mepc � mcause
	always_ff @(posedge clk) begin
		if (!rstn) begin
			
			// �������� �������� ��� ����������� ������� ������
			mepc <= 32'b0;
			mcause <= 32'b0;
			
		end else begin
			
			// ���������� ������, ���� ��������� ����� ������� ��� ������ ������ ����������
			if (IC_INT || A==`CSR_REG_MEPC && csr_write_req)
				mepc <= (IC_INT) ? PC : csr_new_data;
			if (IC_INT || A==`CSR_REG_MCAUSE && csr_write_req)
				mcause <= (IC_INT) ? mcause_i : csr_new_data;
		end
	end
	
	
endmodule
