module soc_ic(

	// тактовый сигнал и сигнал сброса
	input clk,
	input rstn,
	
	// подключается к ядру процессора
	input [31:0] mie_i,		// маска прерываний
	input int_rst_i,		// сигнал о завершении обработки прерывания
	output int_o,			// сигнал о наличии прерывания
	output [31:0] mcause_o,	// номер прерывания
	
	// подключается к переферийным устройствам
	input [31:0] int_req_i,    // запросы прерывания от устройств
	output [31:0] int_fin_o    // сигналы о завершении обработки прерывания
	
);

	// показывает, обрабатывается ли сейчас какое-либо прерывание или нет
	logic is_interrupt;
	
	
	// номер текущего опрашиваемого устройства
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
	
	
	// допущенные прерывания к обработке; если один из битов равен 1, то соответствующее прерывание будет обрабатываться
	logic [31:0] int_ack;
	assign int_ack = (32'b1 << cur_int_num) & int_req_i & mie_i;
	assign is_interrupt = |int_ack;
	
	
	// сигналы о завершении обработки прерывания
	assign int_fin_o = int_ack & {32{int_rst_i}};
	
	
	// выдадим запрос на обработку прерывания процессору
	logic is_interrupt_trig;
	always_ff @(posedge clk) begin
		if (!rstn || int_rst_i) is_interrupt_trig <= 1'b0;
		else is_interrupt_trig <= is_interrupt;
	end
	assign int_o = is_interrupt ^ is_interrupt_trig;
	
	
endmodule
