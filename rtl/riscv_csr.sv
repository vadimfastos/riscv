/* Коды системных команд к модулю CSR (младшие 2 бита func3 команды SYSTEM) */
`define CSR_OP_NONE  2'b00	// нет команды (ничего не делать)
`define CSR_OP_CSRRW 2'b01	// чтение + запись регистров CSR
`define CSR_OP_CSRRS 2'b10	// чтение + установка бит регистров CSR
`define CSR_OP_CSRRC 2'b11	// чтение + очистка бит регистров CSR

/* Номера регистров CSR */
`define CSR_REG_MIE 12'h304
`define CSR_REG_MTVEC 12'h305
`define CSR_REG_MSCRATCH 12'h340
`define CSR_REG_MEPC 12'h341
`define CSR_REG_MCAUSE 12'h342


// Реализация модуля CSR
module riscv_csr(
	
	// тактовый сигнал и сигнал сброса
	input clk,
	input rstn,
	
	input IC_INT, 		// сигнал о прерывании
	input [1:0] CSR_OP,	// команда для блока CSR
	input [11:0] A,		// номер регистра
	input [31:0] PC,	// счётчик команд
	input [31:0] WD,	// данные для записи в регистры CSR
	output logic [31:0] RD,	// считанные из регистров CSR данные
	
	// доступ к этим системным регистрам необходим для работы прерываний
	input [31:0] mcause_i,	// номер прерывания
	output [31:0] mie_o,	// маска прерываний
	output [31:0] mtvec_o,	// адрес начала обработчика прерываний
	output [31:0] mepc_o	// здесь хранится значение счётчика команд до вызова обработчика прерываний
	
);
	
	// Здесь будем хранить системные регистры, необходимые для работы системы прерываний
	logic [31:0] mie, mtvec, mscratch, mepc, mcause;
	assign mie_o = mie;
	assign mtvec_o = mtvec;
	assign mepc_o = mepc;
	
	
	// Реализуем чтение системных регистров
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
	
	
	// Обработаем операцию над регистрами CSR (здесь мы не учитываем сигнал о прерывании, его учтём позже, при записи)
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
	
	
	// Реализуем запись в регистры mie, mtvec и mscratch
	always_ff @(posedge clk) begin
		if (!rstn) begin
			
			// Обнуляем регистры при поступлении сигнала сброса
			mie <= 32'b0;
			mtvec <= 32'b0;
			mscratch <= 32'b0;
			
		end else begin
			
			// Записываем данные, если поступила такая команда
			if (csr_write_req)
				case (A)
					`CSR_REG_MIE: mie <= csr_new_data;
					`CSR_REG_MTVEC: mtvec <= csr_new_data;
					`CSR_REG_MSCRATCH: mscratch <= csr_new_data;
				endcase
			
		end
	end
	
	
	// Реализуем запись в регистры mepc и mcause
	always_ff @(posedge clk) begin
		if (!rstn) begin
			
			// Обнуляем регистры при поступлении сигнала сброса
			mepc <= 32'b0;
			mcause <= 32'b0;
			
		end else begin
			
			// Записываем данные, если поступила такая команда или пришёл сигнал прерывания
			if (IC_INT || A==`CSR_REG_MEPC && csr_write_req)
				mepc <= (IC_INT) ? PC : csr_new_data;
			if (IC_INT || A==`CSR_REG_MCAUSE && csr_write_req)
				mcause <= (IC_INT) ? mcause_i : csr_new_data;
		end
	end
	
	
endmodule
