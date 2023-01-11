`include "riscv_defines.sv"

/* Реализация ядра процессора с архитектурой RISC-V
 * Процессор конвеерный, конвеер имеет 2 стадии: выборка команды и исполнение команды.
 */
module riscv_core(
	
	// подключение к системной шине
    BusEntry.Master bus,
	
	// память, сихронный доступ к инструкциям (по фронту)
	output logic [31:0] instr_addr_o,  // адрес ячейки памяти, содержащей инструкцию (ПЗУ или ОЗУ)
	input [31:0] instr_rdata_i,        // считанная инструкция (при ошибке доступа возвращается 0)
	
	// контроллер прерываний
	input ic_int_i,                // запрос на обработку прерывания от контроллера прерываний
	input [31:0] ic_mcause_i,      // номер прерывания
	output logic [31:0] ic_mie_o,  // маска прерываний
	output logic ic_int_rst_o      // сигнал о завершении обработки прерывания контроллеру
);
	
	// Первая стадия конвеера - выборка команды
	logic pipeline_stall_req; // сигнал приостанова конвеера
	logic [31:0] fetched_instr_addr_last; // адрес текущей инструкции, которая лежит в instr
	logic [31:0] program_counter, instr; // счётчик команд и текущая инструкция
    logic mem_stall_req; // сигнал приостановки процессора от LSU, приостанавливаем и обновление PC
	
	assign pipeline_stall_req = program_counter != fetched_instr_addr_last;
	always @(posedge bus.clk)
		fetched_instr_addr_last <= instr_addr_o;
	
	
	// Подключаем память инструкций
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
	
	
    // Разбор команды: делаем знакорасширение констант
	logic [31:0] imm_I, imm_S, imm_B, imm_J;
    assign imm_I = { {20{instr[31]}}, instr[31:20] };
    assign imm_S = { {20{instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_B = { {20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
	assign imm_J = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
    
    
    // Подключаем регистровый файл
    logic WE3;
    logic [4:0] A1, A2, A3;
    logic [31:0] RD1, RD2, WD3;
    riscv_reg_file reg_file0(.clk(bus.clk), .rstn(bus.rstn), .*);
    
    // Разбор команды: узнаём, к каким регистрам идёт обращение
    assign A1 = instr[19:15];
    assign A2 = instr[24:20];
	assign A3 = instr[11:7];
	
	
    // Подключаем АЛУ
    logic alu_flag;
    logic [4:0] alu_op;
    logic [31:0] alu_op1, alu_op2, alu_result;
    riscv_alu alu0(.A(alu_op1), .B(alu_op2), .ALUOp(alu_op), .Flag(alu_flag), .Result(alu_result));
    
    // Реализуем выбор операндов для АЛУ
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
    
	
	// Подсистема прерываний: сигнал неверной инструкции и сигнал невыровненного доступа к памяти
    logic illegal_instr, mem_unalign_access;
	logic [31:0] csr_mtvec, csr_mepc, csr_rd;
	
    // Подключаем устройство загрузки / сохранения
    logic mem_req, mem_we;
    logic [2:0] mem_size;
    logic [31:0] mem_out;
	
	riscv_lsu lsu0(
	       
		// подключение к системной шине
		.bus,
        
		// эта часть подключается к ядру процессора
		.lsu_req_i(mem_req),						// 1 - обратиться к памяти
		.lsu_we_i(mem_we),							// 1 – если нужно записать в память
		.lsu_addr_i(alu_result),					// адрес, по которому хотим обратиться
		.lsu_size_i(mem_size),						// размер обрабатываемых данных
		.lsu_data_i(RD2),							// данные для записи в память
		.lsu_data_o(mem_out),						// данные считанные из памяти
		.lsu_stall_req_o(mem_stall_req),			// приостанов процессора
		.lsu_unalign_access_o(mem_unalign_access)	// сигнал исключения: невыровненный доступ к памяти
	);
	
    
    // Реализуем запись в регистровый файл: с выхода АЛУ, из памяти или из CSR
    logic reg_file_wd_sel, reg_file_wd_csr;
    assign WD3 = (!reg_file_wd_csr) ? ((reg_file_wd_sel) ? mem_out : alu_result) : csr_rd;
	
	
    // Реализуем счётчик команд
    logic en_program_counter, branch, jal;
    logic [1:0] pc_src_sel;
    always_ff @(posedge bus.clk) begin
        if (!bus.rstn) begin
        
            // Сброс процессора
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
    
    
    // Подключаем главный декодер
    logic [1:0] csr_op;
    riscv_decoder decoder0(
        .fetched_instr_i(instr),	// Инструкция для декодирования, считанная из памяти инструкций
		.pipeline_stall_req_i(pipeline_stall_req), // Сигнал приостановки конвеера, равен 1, если текущая выбранная инструкция неверная
		
        .alu_src_a_sel_o(alu_src_a_sel),	// Управляющий сигнал мультиплексора для выбора первого операнда АЛУ
        .alu_src_b_sel_o(alu_src_b_sel), 	// Управляющий сигнал мультиплексора для выбора второго операнда АЛУ
        .alu_op_o(alu_op),					// Операция АЛУ
		
		.mem_stall_req_i(mem_stall_req),	// Сигнал о необходимости приостанова процессора (от LSU)
        .mem_req_o(mem_req),                // Запрос на доступ к памяти (часть интерфейса памяти)
        .mem_we_o(mem_we),                  // Сигнал разрешения записи в память, «write enable» (при равенстве нулю происходит чтение)
        .mem_size_o(mem_size),              // Управляющий сигнал для выбора размера слова при чтении-записи в память (часть интерфейса памяти)
        
		.reg_file_we_o(WE3),                	// Сигнал разрешения записи в регистровый файл
		.reg_file_wd_sel_o(reg_file_wd_sel),	// Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл (АЛУ или память)
		.reg_file_wd_csr_o(reg_file_wd_csr),	// Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл (модуль CSR)
		
		.pc_enable_o(en_program_counter),	// Сигнал о разрешении работы счётчика команд
		.pc_branch_o(branch),				// Сигнал об инструкции условного перехода
		.pc_jal_o(jal),						// Сигнал об инструкции безусловного перехода jal
		.pc_src_sel_o(pc_src_sel),			// Управляющий сигнал для выбора источника записи в счётчик команд
	
		.ic_int_i(ic_int_i),				// Запрос на обработку прерывания от контроллера прерываний
		.ic_int_rst_o(ic_int_rst_o),	    // Сигнал о завершении обработки прерывания контроллеру
		.trap_illegal_instr_o(illegal_instr),	// Сигнал о некорректной инструкции

		.csr_op_o(csr_op)	// Операция CSR
	
    );
    
    
    // Подключаем модуль CSR
    riscv_csr csr0(
	
        // тактовый сигнал и сигнал сброса
        .clk(bus.clk),
        .rstn(bus.rstn),
	
        .IC_INT(ic_int_i),      // сигнал о прерывании (обрабатываются только прерывания от внешних устройств, а не исключения)
        .CSR_OP(csr_op),        // команда для блока CSR (младшие 2 бита func3 команды SYSTEM)
        .A(instr[31:20]),       // номер регистра
        .PC(program_counter),   // счётчик команд
        .WD(RD1),               // данные для записи в регистры CSR
        .RD(csr_rd),            // считанные из регистров CSR данные
	
	    // доступ к этим системным регистрам необходим для работы прерываний
        .mcause_i(ic_mcause_i),  // номер прерывания
        .mie_o(ic_mie_o),        // маска прерываний
        .mtvec_o(csr_mtvec),    // адрес начала обработчика прерываний
        .mepc_o(csr_mepc)       // здесь хранится значение счётчика команд до вызова обработчика прерываний
    );

endmodule
