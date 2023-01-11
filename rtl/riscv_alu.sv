
// ��������� ���� ������
package ALUOps;
    enum logic[4:0] {
    
        // ��������, ���������
        ALU_ADD = 5'b00000,
        ALU_SUB = 5'b01000,
        
        // ��������� ���������� ��������
        ALU_XOR = 5'b00100,
        ALU_OR = 5'b00110,
        ALU_AND = 5'b00111,
        
        // ������
        ALU_SLL = 5'b00001,
        ALU_SRL = 5'b00101,
        ALU_SRA = 5'b01101,
        
        // ��������� �������� � �����������, ��������� � Result
        ALU_SLT = 5'b00010,
        ALU_SLTU = 5'b00011,
        
        // ��������� ����� / �� �����, ��������� � Flag
        ALU_BEQ = 5'b11000,
        ALU_BNE = 5'b11001,
        
        // �������� ���������, ��������� � Flag
        ALU_BLT = 5'b11100,
        ALU_BGE = 5'b11101,
        
        // ���������� ���������, ��������� � Flag
        ALU_BLTU = 5'b11110,
        ALU_BGEU = 5'b11111
        
    } ALU_OPCODES;
endpackage



// ���
module riscv_alu (
    input [31:0] A,
    input [31:0] B,
    input [4:0] ALUOp,
    output logic Flag,
    output logic [31:0] Result
);

    import ALUOps::*;
    
    always_comb begin
    
        if (!ALUOp[4]) begin // ��������� �������� ������� � Result
            
            Flag <= 0;
            case (ALUOp)
                
                // ��������, ���������
                ALU_ADD: Result <= A + B;
                ALU_SUB: Result <= A - B;
                
                // ��������� ���������� ��������
                ALU_XOR: Result <= A ^ B;
                ALU_OR: Result <= A | B;
                ALU_AND: Result <= A & B;
                
                // ������ (SLL, SRL, SRA)
                ALU_SLL: Result <= A << (B[4:0]);
                ALU_SRL: Result <= A >> (B[4:0]);
                ALU_SRA: Result <= $signed(A) >>> (B[4:0]);
                
                // ��������� �������� � �����������, ��������� � Result
				ALU_SLT: Result <= $signed(A) < $signed(B);
                ALU_SLTU : Result <= A < B;
            
                default: Result <= 0;
            endcase
            
        end else begin  // ��������� �������� ������� � Flags
            
            Result <= 0;
            case (ALUOp)
            
                // ��������� ����� / �� �����, ��������� � Flag
                ALU_BEQ: Flag <= A == B;
                ALU_BNE: Flag <= A != B;
                
                // �������� ���������, ��������� � Flag
                ALU_BLT: Flag <= $signed(A) < $signed(B);
                ALU_BGE: Flag <= $signed(A) >= $signed(B);
                
                // ���������� ���������, ��������� � Flag
                ALU_BLTU: Flag <= A < B;
                ALU_BGEU: Flag <= A >= B;
            
                default: Flag <= 0;
            endcase
            
        end
    end
        
endmodule
