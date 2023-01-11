`include "dev_defines.sv"


/* Тестовое устройство ввода-вывода (1024 байт ввод, 1024 байт вывод + возможность посыла сигнала прерывания) */
module dev_test(
	
	/* Подключение к шине */
	BusEntry.Slave bus,
	input int_fin_i,
	output logic int_req_o,
	
	/* Подключение к testbench */
	input logic dev_test_irq,				// сигнал прерывания от тестбенча, его нужно передать на обработку
	input logic [7:0] dev_test_in[0:1023],	// ввод данных с тестбенча
	output logic [7:0] dev_test_out[0:1023]	// вывод данных на тестбенч
);
	
	// Определяем, к какому участку памяти (для ввода или для вывода) идёт обращение
	logic [9:0] cell_addr;
	assign cell_addr = bus.addr[9:0];
	
	logic is_input, is_output;
	assign is_input = (bus.addr[11:0] < 1024);
	assign is_output = (bus.addr[11:0] >= 1024) && (bus.addr[11:0] < 2048);
	
	
	// Реализуем операцию чтения
	always_ff @(posedge bus.clk) begin
		if (is_output) begin
			bus.rdata <= {dev_test_out[cell_addr+3], dev_test_out[cell_addr+2], dev_test_out[cell_addr+1], dev_test_out[cell_addr+0]};
		end else if (is_input) begin
			bus.rdata <= {dev_test_in[cell_addr+3], dev_test_in[cell_addr+2], dev_test_in[cell_addr+1], dev_test_in[cell_addr+0]};
		end else begin
			bus.rdata <= 32'b0;
		end
	end
	
	
	// Реализуем операцию записи
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
	
	
	// После завершения операции нужно выставить сигнал завершения на шину
	always_ff @(posedge bus.clk)
		bus.ack <= bus.req;
	
	
	// Посыл сигнала прерывания
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			int_req_o <= 0;
		end else begin
			if (dev_test_irq && !int_req_o) int_req_o <= 1;
			else if (int_fin_i) int_req_o <= 0;
		end
	end
	
	
endmodule
