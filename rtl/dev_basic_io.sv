`include "dev_defines.sv"


/* ������� ����/�����. ������������� � ������. ����������, �������������� ����������. */
module dev_basic_io # (
	parameter CLOCK_FREQUENCY = 100*1000*1000 // �������� ������� ����������
) (
	
	/* ����������� � ���� */
	BusEntry.Slave bus,
	input int_fin_i,
	output logic int_req_o,
	
	/* ����������� � ����� */
    input [15:0] SW, // �������������
    input BTNC, BTNU, BTNL, BTNR, BTND, // ������
    output [15:0] LED, // ����������� ����������
    output LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B, // RGB ����������
    output CA, CB, CC, CD, CE, CF, CG, // �������������� ���������� (������)
    output [7:0] AN // �������������� ���������� (����� ����������)
);
	
	/* �������� ����������, � ������� ��������� ����� ������ */
	logic [31:0] reg_input_sw;			// ��������� ��������������, ������ ��� ������
	logic [31:0] reg_input_btn;			// ��������� ������, ������ ��� ������
	logic [31:0] reg_output_leds;		// ���������� ������������ ������������
	logic [31:0] reg_output_rgb;		// ���������� RGB ������������
	logic [31:0] reg_output_7sd_enable;	// ���������� ��������� ��������������� ����������
	logic [31:0] reg_output_7sd_data;	// �����, ������������ �� �������������� �����������
	
	/* ���������� ������������� � ������ � ��������� ���������� */
    assign reg_input_sw[15:0] = SW;
	assign reg_input_sw[31:16] = 16'b0;
	assign reg_input_sw[31:16] = 16'b0;
	assign reg_input_btn[4:0] = {BTNC, BTNU, BTNL, BTNR, BTND};
	assign reg_input_btn[31:5] = 27'b0;
	
	/* ���������� ���������� � ��������� ���������� */
	assign LED = reg_output_leds[15:0];
	assign LED16_R = reg_output_rgb[0];
	assign LED16_G = reg_output_rgb[1];
	assign LED16_B = reg_output_rgb[2];
	assign LED17_R = reg_output_rgb[3];
	assign LED17_G = reg_output_rgb[4];
	assign LED17_B = reg_output_rgb[5];
	
	/* ���������� �������������� ��������� � ��������� ���������� */
	display7 # (
		.CLOCK_FREQUENCY(CLOCK_FREQUENCY)
	) display7_0(.clk(bus.clk), .rstn(bus.rstn), .enable(reg_output_7sd_enable[7:0]), .digits(reg_output_7sd_data), .*);
	
	
	// ����������, � ������ �������� ��� ���������
	logic [9:0] reg_index;
	assign reg_index = bus.addr[11:2];
	
	
	// �������� ������
	always_ff @(posedge bus.clk) begin
		case (reg_index)
			(`DEV_BASIO_IO__REG_INPUT_SW>>2): bus.rdata <= reg_input_sw;
			(`DEV_BASIO_IO__REG_INPUT_BTN>>2): bus.rdata <= reg_input_btn;
			(`DEV_BASIO_IO__REG_OUTPUT_LEDS>>2): bus.rdata <= reg_output_leds;
			(`DEV_BASIO_IO__REG_OUTPUT_RGB>>2): bus.rdata <= reg_output_rgb;
			(`DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE>>2): bus.rdata <= reg_output_7sd_enable;
			(`DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER>>2): bus.rdata <= reg_output_7sd_data;
			default: bus.rdata <= 0;
		endcase
	end
	
	
	// �������� ������
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			reg_output_leds <= 32'b0;
			reg_output_rgb <= 32'b0;
			reg_output_7sd_enable <= 32'b0;
			reg_output_7sd_data <= 32'b0;
		end else if (bus.req && bus.we) begin
			case (reg_index)
				(`DEV_BASIO_IO__REG_OUTPUT_LEDS>>2):		reg_output_leds <= bus.wdata;			
				(`DEV_BASIO_IO__REG_OUTPUT_RGB>>2):			reg_output_rgb <= bus.wdata;			
				(`DEV_BASIO_IO__REG_OUTPUT_7SD_ENABLE>>2):	reg_output_7sd_enable <= bus.wdata;
				(`DEV_BASIO_IO__REG_OUTPUT_7SD_NUMBER>>2):	reg_output_7sd_data <= bus.wdata;
			endcase
		end
	end
	
	
	// ����� ���������� �������� ����� ��������� ������ ���������� �� ����
	always_ff @(posedge bus.clk)
		bus.ack <= bus.req;
	
	
	// ����� ������� ����������
	logic [31:0] reg_input_sw_old, reg_input_btn_old;
	logic irq;
	always_ff @(posedge bus.clk) begin
		reg_input_sw_old <= reg_input_sw;
		reg_input_btn_old <= reg_input_btn;
	end
	assign irq = | ((reg_input_sw^reg_input_sw_old) | (reg_input_btn^reg_input_btn_old));
	
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			int_req_o <= 0;
		end else begin
			if (irq && !int_req_o) int_req_o <= 1;
			else if (int_fin_i) int_req_o <= 0;
		end
	end
	
	
endmodule



// ������ � �������������� �����������
module display7 # (
	parameter CLOCK_FREQUENCY = 100*1000*1000 // �������� ������� ����������
) (
	
	// �������� �������� � ������ ������
	input clk,
	input rstn,
	
	// ����� ������
    input [7:0] enable,
    input [31:0] digits,
	
	// �������������� ����������
    output logic CA, CB, CC, CD, CE, CF, CG,
    output logic [7:0] AN
);
    
	// �� ������� �� ������� � �������� �������
    localparam COUNT_MAX = CLOCK_FREQUENCY / 100000;
	
    /* � ������ ����� ����������� ������������ ���������, ������� ��� ����� ��������� ��������
    ������ �� ������ �� �����������. ��� ����� ���������� 3-� ������ ������� (0-7).
    ����� ������� ������� ������� ������� ��� ������ ������, ������� ��� ����� �������� �������. */
    logic [2:0] cur_digit_index;
    logic [$clog2(COUNT_MAX)-1:0] counter;
    always_ff @(posedge clk) begin
        if (!rstn) begin
            counter <= COUNT_MAX-1;
            cur_digit_index <= 0;
        end else begin
            if (counter > 0) begin
                counter <= counter - 1;
            end else begin
                cur_digit_index <= cur_digit_index + 1;
                counter <= COUNT_MAX - 1;
            end
        end
    end
    
    // ���������� ��� ������ ������� ��������������� ����������
    logic cur_enable;
    logic [3:0] cur_digit;
    logic [6:0] cur_output;
    always_comb begin
        if (cur_enable)
        begin
            case (cur_digit)
                4'h0: cur_output <= 7'b1000000;
                4'h1: cur_output <= 7'b1111001;
                4'h2: cur_output <= 7'b0100100;
                4'h3: cur_output <= 7'b0110000;
                4'h4: cur_output <= 7'b0011001;
                4'h5: cur_output <= 7'b0010010;
                4'h6: cur_output <= 7'b0000010;
                4'h7: cur_output <= 7'b1111000;
                4'h8: cur_output <= 7'b0000000;
                4'h9: cur_output <= 7'b0010000;
                4'hA: cur_output <= 7'b0001000;
                4'hb: cur_output <= 7'b0000011;
                4'hC: cur_output <= 7'b1000110;
                4'hd: cur_output <= 7'b0100001;
                4'hE: cur_output <= 7'b0000110;
                4'hF: cur_output <= 7'b0001110;
            endcase
        end else begin
            cur_output <= 7'b1111111;
        end
    end
    
    // ������� �� ������� ������� �����
    always_comb begin
        
        // ����������� ����� � ��� ��� ���������� (�������� ������ �� ����������)
        case (cur_digit_index)
            3'd0: begin cur_enable <= enable[0]; cur_digit <= digits[3:0]; end
            3'd1: begin cur_enable <= enable[1]; cur_digit <= digits[7:4]; end
            3'd2: begin cur_enable <= enable[2]; cur_digit <= digits[11:8]; end
            3'd3: begin cur_enable <= enable[3]; cur_digit <= digits[15:12]; end
            3'd4: begin cur_enable <= enable[4]; cur_digit <= digits[19:16]; end
            3'd5: begin cur_enable <= enable[5]; cur_digit <= digits[23:20]; end
            3'd6: begin cur_enable <= enable[6]; cur_digit <= digits[27:24]; end
            3'd7: begin cur_enable <= enable[7]; cur_digit <= digits[31:28]; end
        endcase
        
        // �������� ������ �� ���������
        CA <= cur_output[0];
        CB <= cur_output[1];
        CC <= cur_output[2];
        CD <= cur_output[3];
        CE <= cur_output[4];
        CF <= cur_output[5];
        CG <= cur_output[6];
        AN <= ~(8'b1 << cur_digit_index);
        
    end

endmodule
