// Регистровый файл
module riscv_reg_file(clk, rstn, A1, A2, A3, WD3, WE3, RD1, RD2);
    input clk, rstn;
    input [4:0] A1, A2, A3;
    input [31:0] WD3;
    input WE3;
    output[31:0] RD1, RD2;

    logic [31:0] registers[0:31];
    
    assign RD1 = (A1 != 0) ? registers[A1] : 32'b0;
    assign RD2 = (A2 != 0) ? registers[A2] : 32'b0;
    
    always_ff @(posedge clk)
        if (!rstn) begin
            for (int i=0; i<32; i++)
                registers[i] <= 32'b0;
        end else begin
            if (WE3)
                registers[A3] <= WD3;
        end
	
endmodule
