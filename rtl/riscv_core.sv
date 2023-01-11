`include "riscv_defines.sv"

/* ���������� ���� ���������� � ������������ RISC-V
 * ��������� ����������, ������� ����� 2 ������: ������� ������� � ���������� �������.
 */
module riscv_core(
	
	// ����������� � ��������� ����
    BusEntry.Master bus,
	
	// ������, ��������� ������ � ����������� (�� ������)
	output logic [31:0] instr_addr_o,  // ����� ������ ������, ���������� ���������� (��� ��� ���)
	input [31:0] instr_rdata_i,        // ��������� ���������� (��� ������ ������� ������������ 0)
	
	// ���������� ����������
	input ic_int_i,                // ������ �� ��������� ���������� �� ����������� ����������
	input [31:0] ic_mcause_i,      // ����� ����������
	output logic [31:0] ic_mie_o,  // ����� ����������
	output logic ic_int_rst_o      // ������ � ���������� ��������� ���������� �����������
);
	
	// ������ ������ �������� - ������� �������
	logic pipeline_stall_req; // ������ ����������� ��������
	logic [31:0] fetched_instr_addr_last; // ����� ������� ����������, ������� ����� � instr
	logic [31:0] program_counter, instr; // ������� ������ � ������� ����������
    logic mem_stall_req; // ������ ������������ ���������� �� LSU, ���������������� � ���������� PC
	
	assign pipeline_stall_req = program_counter != fetched_instr_addr_last;
	always @(posedge bus.clk)
		fetched_instr_addr_last <= instr_addr_o;
	
	
	// ���������� ������ ����������
	always_comb begin
		if (!bus.rstn) begin
			instr_addr_o <= 0;
		end else begin
			if (pipeline_stall_req) begin
				instr_addr_o <= program_counter;
			end else begin
				instr_addr_o <= (mem_stall_req) ? fetched_instr_addr_last : (fetched_instr_addr_last + 4);
			end
		end
	end
	assign instr = instr_rdata_i;
	
	
    // ������ �������: ������ ��������������� ��������
	logic [31:0] imm_I, imm_S, imm_B, imm_J;
    assign imm_I = { {20{instr[31]}}, instr[31:20] };
    assign imm_S = { {20{instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_B = { {20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
	assign imm_J = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
    
    
    // ���������� ����������� ����
    logic WE3;
    logic [4:0] A1, A2, A3;
    logic [31:0] RD1, RD2, WD3;
    riscv_reg_file reg_file0(.clk(bus.clk), .rstn(bus.rstn), .*);
    
    // ������ �������: �����, � ����� ��������� ��� ���������
    assign A1 = instr[19:15];
    assign A2 = instr[24:20];
	assign A3 = instr[11:7];
	
	
    // ���������� ���
    logic alu_flag;
    logic [4:0] alu_op;
    logic [31:0] alu_op1, alu_op2, alu_result;
    riscv_alu alu0(.A(alu_op1), .B(alu_op2), .ALUOp(alu_op), .Flag(alu_flag), .Result(alu_result));
    
    // ��������� ����� ��������� ��� ���
    logic [1:0] alu_src_a_sel;
    logic [2:0] alu_src_b_sel;
    always_comb begin
        case (alu_src_a_sel)
            `OP_A_RS1: alu_op1 <= RD1;
            `OP_A_CURR_PC: alu_op1 <= program_counter;
            `OP_A_ZERO: alu_op1 <= 32'b0;
            default: alu_op1 <= 32'b0;
        endcase
        case (alu_src_b_sel)
            `OP_B_RS2: alu_op2 <= RD2;
            `OP_B_IMM_I: alu_op2 <= imm_I;
            `OP_B_IMM_U: alu_op2 <= { instr[31:12], 12'b0 };
            `OP_B_IMM_S: alu_op2 <= imm_S;
            `OP_B_INCR: alu_op2 <= 32'd4;
            default: alu_op2 <= 32'd4;
        endcase
    end
    
	
	// ���������� ����������: ������ �������� ���������� � ������ �������������� ������� � ������
    logic illegal_instr, mem_unalign_access;
	logic [31:0] csr_mtvec, csr_mepc, csr_rd;
	
    // ���������� ���������� �������� / ����������
    logic mem_req, mem_we;
    logic [2:0] mem_size;
    logic [31:0] mem_out;
	
	riscv_lsu lsu0(
	       
		// ����������� � ��������� ����
		.bus,
        
		// ��� ����� ������������ � ���� ����������
		.lsu_req_i(mem_req),						// 1 - ���������� � ������
		.lsu_we_i(mem_we),							// 1 � ���� ����� �������� � ������
		.lsu_addr_i(alu_result),					// �����, �� �������� ����� ����������
		.lsu_size_i(mem_size),						// ������ �������������� ������
		.lsu_data_i(RD2),							// ������ ��� ������ � ������
		.lsu_data_o(mem_out),						// ������ ��������� �� ������
		.lsu_stall_req_o(mem_stall_req),			// ���������� ����������
		.lsu_unalign_access_o(mem_unalign_access)	// ������ ����������: ������������� ������ � ������
	);
	
    
    // ��������� ������ � ����������� ����: � ������ ���, �� ������ ��� �� CSR
    logic reg_file_wd_sel, reg_file_wd_csr;
    assign WD3 = (!reg_file_wd_csr) ? ((reg_file_wd_sel) ? mem_out : alu_result) : csr_rd;
	
	
    // ��������� ������� ������
    logic en_program_counter, branch, jal;
    logic [1:0] pc_src_sel;
    always_ff @(posedge bus.clk) begin
        if (!bus.rstn) begin
        
            // ����� ����������
            program_counter <= `RESET_ADDR;
            
        end else if (en_program_counter) begin
            
            case (pc_src_sel)
                2'd3: program_counter <= csr_mtvec;
                2'd2: program_counter <= csr_mepc;
                2'd1: program_counter <= RD1 + imm_I;
                default: begin
                    if (jal) program_counter <= program_counter + imm_J;
                    else if (branch && alu_flag) program_counter <= program_counter + imm_B;
                    else program_counter <= program_counter + 4;
                end
            endcase
            
        end
    end
    
    
    // ���������� ������� �������
    logic [1:0] csr_op;
    riscv_decoder decoder0(
        .fetched_instr_i(instr),	// ���������� ��� �������������, ��������� �� ������ ����������
		.pipeline_stall_req_i(pipeline_stall_req), // ������ ������������ ��������, ����� 1, ���� ������� ��������� ���������� ��������
		
        .alu_src_a_sel_o(alu_src_a_sel),	// ����������� ������ �������������� ��� ������ ������� �������� ���
        .alu_src_b_sel_o(alu_src_b_sel), 	// ����������� ������ �������������� ��� ������ ������� �������� ���
        .alu_op_o(alu_op),					// �������� ���
		
		.mem_stall_req_i(mem_stall_req),	// ������ � ������������� ����������� ���������� (�� LSU)
        .mem_req_o(mem_req),                // ������ �� ������ � ������ (����� ���������� ������)
        .mem_we_o(mem_we),                  // ������ ���������� ������ � ������, �write enable� (��� ��������� ���� ���������� ������)
        .mem_size_o(mem_size),              // ����������� ������ ��� ������ ������� ����� ��� ������-������ � ������ (����� ���������� ������)
        
		.reg_file_we_o(WE3),                	// ������ ���������� ������ � ����������� ����
		.reg_file_wd_sel_o(reg_file_wd_sel),	// ����������� ������ �������������� ��� ������ ������, ������������ � ����������� ���� (��� ��� ������)
		.reg_file_wd_csr_o(reg_file_wd_csr),	// ����������� ������ �������������� ��� ������ ������, ������������ � ����������� ���� (������ CSR)
		
		.pc_enable_o(en_program_counter),	// ������ � ���������� ������ �������� ������
		.pc_branch_o(branch),				// ������ �� ���������� ��������� ��������
		.pc_jal_o(jal),						// ������ �� ���������� ������������ �������� jal
		.pc_src_sel_o(pc_src_sel),			// ����������� ������ ��� ������ ��������� ������ � ������� ������
	
		.ic_int_i(ic_int_i),				// ������ �� ��������� ���������� �� ����������� ����������
		.ic_int_rst_o(ic_int_rst_o),	    // ������ � ���������� ��������� ���������� �����������
		.trap_illegal_instr_o(illegal_instr),	// ������ � ������������ ����������

		.csr_op_o(csr_op)	// �������� CSR
	
    );
    
    
    // ���������� ������ CSR
    riscv_csr csr0(
	
        // �������� ������ � ������ ������
        .clk(bus.clk),
        .rstn(bus.rstn),
	
        .IC_INT(ic_int_i),      // ������ � ���������� (�������������� ������ ���������� �� ������� ���������, � �� ����������)
        .CSR_OP(csr_op),        // ������� ��� ����� CSR (������� 2 ���� func3 ������� SYSTEM)
        .A(instr[31:20]),       // ����� ��������
        .PC(program_counter),   // ������� ������
        .WD(RD1),               // ������ ��� ������ � �������� CSR
        .RD(csr_rd),            // ��������� �� ��������� CSR ������
	
	    // ������ � ���� ��������� ��������� ��������� ��� ������ ����������
        .mcause_i(ic_mcause_i),  // ����� ����������
        .mie_o(ic_mie_o),        // ����� ����������
        .mtvec_o(csr_mtvec),    // ����� ������ ����������� ����������
        .mepc_o(csr_mepc)       // ����� �������� �������� �������� ������ �� ������ ����������� ����������
    );

endmodule
