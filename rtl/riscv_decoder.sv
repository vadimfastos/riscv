`include "riscv_defines.sv"

// Главный декодер команд
module riscv_decoder (
    input [31:0] fetched_instr_i,	// Инструкция для декодирования, считанная из памяти инструкций
    input pipeline_stall_req_i,		// Сигнал приостановки конвеера, равен 1, если текущая выбранная инструкция неверная
	
    output logic [1:0] alu_src_a_sel_o,	// Управляющий сигнал мультиплексора для выбора первого операнда АЛУ
    output logic [2:0] alu_src_b_sel_o,	// Управляющий сигнал мультиплексора для выбора второго операнда АЛУ
    output logic [4:0] alu_op_o,		// Операция АЛУ
    
	input mem_stall_req_i,			// Сигнал о необходимости приостанова процессора (от LSU)
    output logic mem_req_o,			// Запрос на доступ к памяти (часть интерфейса памяти)
    output logic mem_we_o,			// Сигнал разрешения записи в память, «write enable» (при равенстве нулю происходит чтение)
    output logic [2:0] mem_size_o,	// Управляющий сигнал для выбора размера слова при чтении-записи в память (часть интерфейса памяти)
    
    output logic reg_file_we_o,		// Сигнал разрешения записи в регистровый файл
    output logic reg_file_wd_sel_o,	// Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл (АЛУ или память)
	output logic reg_file_wd_csr_o,	// Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл (модуль CSR)
    
    output logic pc_enable_o,		// Сигнал о разрешении работы счётчика команд
    output logic pc_branch_o,		// Сигнал об инструкции условного перехода
    output logic pc_jal_o,			// Сигнал об инструкции безусловного перехода jal
    output logic [1:0] pc_src_sel_o,// Управляющий сигнал для выбора источника записи в счётчик команд
    
	input ic_int_i,						// Запрос на обработку прерывания от контроллера прерываний
    output logic ic_int_rst_o,			// Сигнал о завершении обработки прерывания контроллеру
    output logic trap_illegal_instr_o,	// Сигнал о некорректной инструкции
	
    output logic [1:0] csr_op_o	// Операция CSR
);
    
    
    // Получаем поля, необходимые для декодирования инструкции
    logic [6:0] func7;
    logic [2:0] func3;
    assign func7 = fetched_instr_i[31:25];
    assign func3 = fetched_instr_i[14:12];
    
	
    // Реализована поддержка только 32-х битных инструкций. Два младших бита опкода всегда равны 11 (RV-32).
	logic instr_32bit;
	logic [4:0] opcode;
	assign instr_32bit = (fetched_instr_i[1:0]==2'b11) && (fetched_instr_i[4:2]!=3'b111);
	assign opcode = fetched_instr_i[6:2];
	

    // Сигнал о неверной инструкции всегда вырабатывается, если инструкция не 32-х битная
	logic illegal_instr;
    assign trap_illegal_instr_o = !instr_32bit || illegal_instr;
    
	
	/* Приостанов процессора возникает, когда данные не поступили с памяти или случился приостанов конвеера.
		Но если возникает прерывание, то приостанова процессора нет. */
    assign pc_enable_o = !mem_stall_req_i && !pipeline_stall_req_i || ic_int_i;
    
    
    /* Запись в регистровый файл разрешается только тогда, когда:
		1) инструкция корректна
		2) нет приостанова процессора из-за доступа к шине
		3) нет приостанова процессора из-за работы конвеера
		4) нет сигнала прерывания
	*/
    logic reg_file_we;
    assign reg_file_we_o = reg_file_we && !trap_illegal_instr_o && !mem_stall_req_i && !pipeline_stall_req_i && !ic_int_i;
    
    
	// Этот флаг выставляется, если идёт обращение к системе (выполняется инструкция SYSTEM или происходит прерывание)
	logic system;
	assign system = instr_32bit && (opcode == `SYSTEM_OPCODE) || ic_int_i;
    assign ic_int_rst_o = fetched_instr_i == `INSTR_MRET;
	
	
	// Обработка системных инструкций
	logic csr_instruction;
	assign csr_instruction = instr_32bit && (opcode==`SYSTEM_OPCODE) && (func3==3'b001 || func3==3'b010 || func3==3'b011);
	assign csr_op_o = (csr_instruction) ? func3[1:0] : 2'b0;
	assign reg_file_wd_csr_o = csr_instruction;
	
    
    /* Сигнал об инструкции перехода может быть выдан только при соответствующей операции.
        При этом не должно быть сигнала о некорректной инструкции. */
    assign pc_branch_o = (opcode == `BRANCH_OPCODE) && (!trap_illegal_instr_o);
    assign pc_jal_o = (opcode == `JAL_OPCODE) && (!trap_illegal_instr_o);
    logic jalr;
    assign jalr = (opcode == `JALR_OPCODE) && (!trap_illegal_instr_o);
	
	
    /* Источник записи в счётчик команд */
	always_comb begin
		if (fetched_instr_i == `INSTR_MRET) begin
			pc_src_sel_o <= 2'd2;
		end else if (ic_int_i) begin
			pc_src_sel_o <= 2'd3;
		end else begin
			pc_src_sel_o <= {1'b0, jalr};
		end
	end
	
	
    /* Сигнал для доступа к памяти и сигналы для управления ею выдаются только для соотвествующих инструкций:
        load (opcode == `LOAD_OPCODE), store (opcode == `STORE_OPCODE). При этом не должно быть сигнала о некорректной инструкции. 
		Запись в регистровый файл из памяти осуществляется только для инструкции загрузки из памяти. */
	logic mem_can_req;
	assign mem_can_req = (!trap_illegal_instr_o) && (!ic_int_i) && (!pipeline_stall_req_i);
    assign mem_req_o = (opcode==`LOAD_OPCODE || opcode==`STORE_OPCODE) && mem_can_req;
    assign mem_we_o = (opcode==`STORE_OPCODE) && mem_can_req;
    assign mem_size_o = (mem_req_o) ? (func3) : (`LDST_W);
	assign reg_file_wd_sel_o = (opcode==`LOAD_OPCODE) ? `WB_LSU_DATA : `WB_EX_RESULT;
	
	
    // Осуществляем декодирование
    always_comb begin
    
        case (opcode)
            
            // Computing instruction, reg<=reg,reg (R type)
            `OP_OPCODE: begin
                
                // Оба исходных операнда АЛУ - регистры
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                
                // Результат записывается в регистр из АЛУ
                reg_file_we <= 1;
                
                // Получим команду для АЛУ
                alu_op_o[2:0] <= func3;
                alu_op_o[4:3] <= (!illegal_instr) ? (func7[6:5]) : (2'b00);
                
                // Проверим func3 и func7 на корректность
                if (func7 == 7'h20) begin
                    illegal_instr <= (func3!=7'h0) && (func3!=7'h5);
                end else begin
                    illegal_instr <= (func7 != 7'h00);
                end
                
            end   
            
            
            // Computing instruction, reg<=reg,imm (I type)
            `OP_IMM_OPCODE: begin
                
                // Первый исходный операнд - регистр, второй - константа
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_I;
                
                // Результат записывается в регистр из АЛУ
                reg_file_we <= 1;
                
                // Получим команду для АЛУ и проверяем func3 и func7 на корректность
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
                
                /* Первый исходный операнд АЛУ - регистр, второй - константа.
                    В сумме они дадут адрес ячеки памяти. */
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_I;
                alu_op_o <= `ALU_ADD;
                
                // Данные из памяти записывается в регистр из памяти
                reg_file_we <= 1;
                
                // Проверяем func3 на корректность
                illegal_instr <= (func3==3'h3) || (func3==3'h6) || (func3==3'h7);
            end
            
            
            // Store to memory (S type)
            `STORE_OPCODE: begin
                
                /* Первый исходный операнд АЛУ - регистр, второй - константа.
                    В сумме они дадут адрес ячеки памяти. */
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_IMM_S;
                alu_op_o <= `ALU_ADD;
                
                // При сохранении в память запись в регистр не осуществляется
                reg_file_we <= 0;
                
                // Проверяем func3 на корректность
                illegal_instr <= (func3!=3'h0) && (func3!=3'h1) && (func3!=3'h2);
            end
            
            
            // Branch if (B type)
            `BRANCH_OPCODE: begin
            
                // Оба исходных операнда для сравнения - регистры
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                
                // Результат не записывается в регистр
                reg_file_we <= 0;
                
                // Получим команду для АЛУ
                alu_op_o <= (!trap_illegal_instr_o) ? ({2'b11, func3}) : `ALU_EQ;
                
                // Проверяем func3 на корректность
                illegal_instr <= (func3==3'h2) || (func3==3'h3);
            end
            
            
            // jal (J type)
            `JAL_OPCODE: begin
                
                // RD = PC + 4
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_INCR;
                alu_op_o <= `ALU_ADD;
                
                // Результат записывается в регистр
                reg_file_we <= 1;
                
                // Эта инструкция корректна
                illegal_instr <= 0;
            end
            
            
            // jalr (I type)
            `JALR_OPCODE: begin
                
                // RD = PC + 4
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_INCR;
                alu_op_o <= `ALU_ADD;
                
                // Результат записывается в регистр
                reg_file_we <= 1;
                
                // Эта инструкция корректна, если func3==0
                illegal_instr <= (func3 != 3'b0);
            end
            
            
            // lui (U type)
            `LUI_OPCODE: begin
                
                // RD = 0 + imm_U
                alu_src_a_sel_o <= `OP_A_ZERO;
                alu_src_b_sel_o <= `OP_B_IMM_U;
                alu_op_o <= `ALU_ADD;
                
                // Результат записывается в регистр
                reg_file_we <= 1;
                
                // Эта всегда инструкция корректна
                illegal_instr <= 0;
            end
            
            
            // auipc (U type)
            `AUIPC_OPCODE: begin
                
                // RD = PC + imm_U
                alu_src_a_sel_o <= `OP_A_CURR_PC;
                alu_src_b_sel_o <= `OP_B_IMM_U;
                alu_op_o <= `ALU_ADD;
                
                // Результат записывается в регистр
                reg_file_we <= 1;
                
                // Эта всегда инструкция корректна
                illegal_instr <= 0;
            end
            
            
            // CSR instructions (CSRRW, CSRRS, CSRRC). MRET inSystem instructions (ecall, ebrake), execute nop instruction instead.
            `SYSTEM_OPCODE: begin
                
                // Не выполняем никаких действий на АЛУ
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                alu_op_o <= `ALU_ADD;
				
                // Результат записывается в регистр, если выполняется инструкция CSR
                reg_file_we <= csr_instruction;
                
                // Корректными являются инструкции доступа к CSR и инструкции ecall, ebrake, mret
                illegal_instr <= (!csr_instruction) && (fetched_instr_i!=`INSTR_ECALL) &&
					(fetched_instr_i!=`INSTR_EBRAKE) && (fetched_instr_i!=`INSTR_MRET);
				
				// Завершим симуляцию, если текущая инструкция EBRAKE
				/*if (fetched_instr_i == `INSTR_EBRAKE)
					$finish;*/
			end
            
            
            /* MISC-MEM instructions (fence). Execute nop instruction instead.
               Invalid instructions. */
            default: begin
                
                // Не выполняем никаких действий
                alu_src_a_sel_o <= `OP_A_RS1;
                alu_src_b_sel_o <= `OP_B_RS2;
                alu_op_o <= `ALU_ADD;
                
                // Записи в регистр нет
                reg_file_we <= 0;
              
                // Инструкция MISC_MEM корректна, остальные нет
                illegal_instr <= (opcode != `MISC_MEM_OPCODE);
            end
        
        endcase
    
    end

endmodule
