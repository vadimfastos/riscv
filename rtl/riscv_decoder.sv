`include "riscv_defines.sv"

// ������� ������� ������
module riscv_decoder (
    input [31:0] fetched_instr_i,	// ���������� ��� �������������, ��������� �� ������ ����������
    input pipeline_stall_req_i,		// ������ ������������ ��������, ����� 1, ���� ������� ��������� ���������� ��������
	
    output logic [1:0] alu_src_a_sel_o,	// ����������� ������ �������������� ��� ������ ������� �������� ���
    output logic [2:0] alu_src_b_sel_o,	// ����������� ������ �������������� ��� ������ ������� �������� ���
    output logic [4:0] alu_op_o,		// �������� ���
    
	input mem_stall_req_i,			// ������ � ������������� ����������� ���������� (�� LSU)
    output logic mem_req_o,			// ������ �� ������ � ������ (����� ���������� ������)
    output logic mem_we_o,			// ������ ���������� ������ � ������, �write enable� (��� ��������� ���� ���������� ������)
    output logic [2:0] mem_size_o,	// ����������� ������ ��� ������ ������� ����� ��� ������-������ � ������ (����� ���������� ������)
    
    output logic reg_file_we_o,		// ������ ���������� ������ � ����������� ����
    output logic reg_file_wd_sel_o,	// ����������� ������ �������������� ��� ������ ������, ������������ � ����������� ���� (��� ��� ������)
	output logic reg_file_wd_csr_o,	// ����������� ������ �������������� ��� ������ ������, ������������ � ����������� ���� (������ CSR)
    
    output logic pc_enable_o,		// ������ � ���������� ������ �������� ������
    output logic pc_branch_o,		// ������ �� ���������� ��������� ��������
    output logic pc_jal_o,			// ������ �� ���������� ������������ �������� jal
    output logic [1:0] pc_src_sel_o,// ����������� ������ ��� ������ ��������� ������ � ������� ������
    
	input ic_int_i,						// ������ �� ��������� ���������� �� ����������� ����������
    output logic ic_int_rst_o,			// ������ � ���������� ��������� ���������� �����������
    output logic trap_illegal_instr_o,	// ������ � ������������ ����������
	
    output logic [1:0] csr_op_o	// �������� CSR
);
    
    
    // �������� ����, ����������� ��� ������������� ����������
    logic [6:0] func7;
    logic [2:0] func3;
    assign func7 = fetched_instr_i[31:25];
    assign func3 = fetched_instr_i[14:12];
    
	
    // ����������� ��������� ������ 32-� ������ ����������. ��� ������� ���� ������ ������ ����� 11 (RV-32).
	logic instr_32bit;
	logic [4:0] opcode;
	assign instr_32bit = (fetched_instr_i[1:0]==2'b11) && (fetched_instr_i[4:2]!=3'b111);
	assign opcode = fetched_instr_i[6:2];
	

    // ������ � �������� ���������� ������ ��������������, ���� ���������� �� 32-� ������
	logic illegal_instr;
    assign trap_illegal_instr_o = !instr_32bit || illegal_instr;
    
	
	/* ���������� ���������� ���������, ����� ������ �� ��������� � ������ ��� �������� ���������� ��������.
		�� ���� ��������� ����������, �� ����������� ���������� ���. */
    assign pc_enable_o = !mem_stall_req_i && !pipeline_stall_req_i || ic_int_i;
    
    
    /* ������ � ����������� ���� ����������� ������ �����, �����:
		1) ���������� ���������
		2) ��� ����������� ���������� ��-�� ������� � ����
		3) ��� ����������� ���������� ��-�� ������ ��������
		4) ��� ������� ����������
	*/
    logic reg_file_we;
    assign reg_file_we_o = reg_file_we && !trap_illegal_instr_o && !mem_stall_req_i && !pipeline_stall_req_i && !ic_int_i;
    
    
	// ���� ���� ������������, ���� ��� ��������� � ������� (����������� ���������� SYSTEM ��� ���������� ����������)
	logic system;
	assign system = instr_32bit && (opcode == `SYSTEM_OPCODE) || ic_int_i;
    assign ic_int_rst_o = fetched_instr_i == `INSTR_MRET;
	
	
	// ��������� ��������� ����������
	logic csr_instruction;
	assign csr_instruction = instr_32bit && (opcode==`SYSTEM_OPCODE) && (func3==3'b001 || func3==3'b010 || func3==3'b011);
	assign csr_op_o = (csr_instruction) ? func3[1:0] : 2'b0;
	assign reg_file_wd_csr_o = csr_instruction;
	
    
    /* ������ �� ���������� �������� ����� ���� ����� ������ ��� ��������������� ��������.
        ��� ���� �� ������ ���� ������� � ������������ ����������. */
    assign pc_branch_o = (opcode == `BRANCH_OPCODE) && (!trap_illegal_instr_o);
    assign pc_jal_o = (opcode == `JAL_OPCODE) && (!trap_illegal_instr_o);
    logic jalr;
    assign jalr = (opcode == `JALR_OPCODE) && (!trap_illegal_instr_o);
	
	
    /* �������� ������ � ������� ������ */
	always_comb begin
		if (fetched_instr_i == `INSTR_MRET) begin
			pc_src_sel_o <= 2'd2;
		end else if (ic_int_i) begin
			pc_src_sel_o <= 2'd3;
		end else begin
			pc_src_sel_o <= {1'b0, jalr};
		end
	end
	
	
    /* ������ ��� ������� � ������ � ������� ��� ���������� �� �������� ������ ��� �������������� ����������:
        load (opcode == `LOAD_OPCODE), store (opcode == `STORE_OPCODE). ��� ���� �� ������ ���� ������� � ������������ ����������. 
		������ � ����������� ���� �� ������ �������������� ������ ��� ���������� �������� �� ������. */
	logic mem_can_req;
	assign mem_can_req = (!trap_illegal_instr_o) && (!ic_int_i) && (!pipeline_stall_req_i);
    assign mem_req_o = (opcode==`LOAD_OPCODE || opcode==`STORE_OPCODE) && mem_can_req;
    assign mem_we_o = (opcode==`STORE_OPCODE) && mem_can_req;
    assign mem_size_o = (mem_req_o) ? (func3) : (`LDST_W);
	assign reg_file_wd_sel_o = (opcode==`LOAD_OPCODE) ? `WB_LSU_DATA : `WB_EX_RESULT;
	
	
    // ������������ �������������
    always_comb begin
    
        case (opcode)
            
            // Computing instruction, reg<=reg,reg (R type)
            `OP_OPCODE: begin
                
                // ��� �������� �������� ��� - ��������
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                
                // ��������� ������������ � ������� �� ���
                reg_file_we <= 1;
                
                // ������� ������� ��� ���
                alu_op_o[2:0] <= func3;
                alu_op_o[4:3] <= (!illegal_instr) ? (func7[6:5]) : (2'b00);
                
                // �������� func3 � func7 �� ������������
                if (func7 == 7'h20) begin
                    illegal_instr <= (func3!=7'h0) && (func3!=7'h5);
                end else begin
                    illegal_instr <= (func7 != 7'h00);
                end
                
            end   
            
            
            // Computing instruction, reg<=reg,imm (I type)
            `OP_IMM_OPCODE: begin
                
                // ������ �������� ������� - �������, ������ - ���������
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_I;
                
                // ��������� ������������ � ������� �� ���
                reg_file_we <= 1;
                
                // ������� ������� ��� ��� � ��������� func3 � func7 �� ������������
                alu_op_o[2:0] <= func3;
                
                if (func3 == 3'h1) begin
                    alu_op_o[4:3] <= 0;
                    illegal_instr <= (func7 != 7'h00);
                end else if (func3 == 3'h5) begin
                    alu_op_o[4:3] <= (!illegal_instr) ? (func7[6:5]) : 2'b00;
                    illegal_instr <= (func7 != 7'h00) && (func7 != 7'h20);
                end else begin
                    alu_op_o[4:3] <= 0;
                    illegal_instr <= 0;
                end
                
            end
            
            
            // Load from memory (I type)
            `LOAD_OPCODE: begin
                
                /* ������ �������� ������� ��� - �������, ������ - ���������.
                    � ����� ��� ����� ����� ����� ������. */
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_I;
                alu_op_o <= `ALU_ADD;
                
                // ������ �� ������ ������������ � ������� �� ������
                reg_file_we <= 1;
                
                // ��������� func3 �� ������������
                illegal_instr <= (func3==3'h3) || (func3==3'h6) || (func3==3'h7);
            end
            
            
            // Store to memory (S type)
            `STORE_OPCODE: begin
                
                /* ������ �������� ������� ��� - �������, ������ - ���������.
                    � ����� ��� ����� ����� ����� ������. */
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_S;
                alu_op_o <= `ALU_ADD;
                
                // ��� ���������� � ������ ������ � ������� �� ��������������
                reg_file_we <= 0;
                
                // ��������� func3 �� ������������
                illegal_instr <= (func3!=3'h0) && (func3!=3'h1) && (func3!=3'h2);
            end
            
            
            // Branch if (B type)
            `BRANCH_OPCODE: begin
            
                // ��� �������� �������� ��� ��������� - ��������
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                
                // ��������� �� ������������ � �������
                reg_file_we <= 0;
                
                // ������� ������� ��� ���
                alu_op_o <= (!trap_illegal_instr_o) ? ({2'b11, func3}) : `ALU_EQ;
                
                // ��������� func3 �� ������������
                illegal_instr <= (func3==3'h2) || (func3==3'h3);
            end
            
            
            // jal (J type)
            `JAL_OPCODE: begin
                
                // RD = PC + 4
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_INCR;
                alu_op_o <= `ALU_ADD;
                
                // ��������� ������������ � �������
                reg_file_we <= 1;
                
                // ��� ���������� ���������
                illegal_instr <= 0;
            end
            
            
            // jalr (I type)
            `JALR_OPCODE: begin
                
                // RD = PC + 4
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_INCR;
                alu_op_o <= `ALU_ADD;
                
                // ��������� ������������ � �������
                reg_file_we <= 1;
                
                // ��� ���������� ���������, ���� func3==0
                illegal_instr <= (func3 != 3'b0);
            end
            
            
            // lui (U type)
            `LUI_OPCODE: begin
                
                // RD = 0 + imm_U
                alu_src_a_sel_o <= `OP_A_ZERO;
                alu_src_b_sel_o <= `OP_B_IMM_U;
                alu_op_o <= `ALU_ADD;
                
                // ��������� ������������ � �������
                reg_file_we <= 1;
                
                // ��� ������ ���������� ���������
                illegal_instr <= 0;
            end
            
            
            // auipc (U type)
            `AUIPC_OPCODE: begin
                
                // RD = PC + imm_U
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_IMM_U;
                alu_op_o <= `ALU_ADD;
                
                // ��������� ������������ � �������
                reg_file_we <= 1;
                
                // ��� ������ ���������� ���������
                illegal_instr <= 0;
            end
            
            
            // CSR instructions (CSRRW, CSRRS, CSRRC). MRET inSystem instructions (ecall, ebrake), execute nop instruction instead.
            `SYSTEM_OPCODE: begin
                
                // �� ��������� ������� �������� �� ���
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                alu_op_o <= `ALU_ADD;
				
                // ��������� ������������ � �������, ���� ����������� ���������� CSR
                reg_file_we <= csr_instruction;
                
                // ����������� �������� ���������� ������� � CSR � ���������� ecall, ebrake, mret
                illegal_instr <= (!csr_instruction) && (fetched_instr_i!=`INSTR_ECALL) &&
					(fetched_instr_i!=`INSTR_EBRAKE) && (fetched_instr_i!=`INSTR_MRET);
				
				// �������� ���������, ���� ������� ���������� EBRAKE
				/*if (fetched_instr_i == `INSTR_EBRAKE)
					$finish;*/
			end
            
            
            /* MISC-MEM instructions (fence). Execute nop instruction instead.
               Invalid instructions. */
            default: begin
                
                // �� ��������� ������� ��������
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                alu_op_o <= `ALU_ADD;
                
                // ������ � ������� ���
                reg_file_we <= 0;
              
                // ���������� MISC_MEM ���������, ��������� ���
                illegal_instr <= (opcode != `MISC_MEM_OPCODE);
            end
        
        endcase
    
    end

endmodule
