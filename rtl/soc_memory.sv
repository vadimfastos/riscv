// Память (ОЗУ и ПЗУ)
module soc_memory #(
	parameter RAM_INIT_FILE = "",	// имя файла с прошивкой
	parameter RAM_SIZE = 64*1024	// размер памяти в байтах
) (
	
	// подключение к шине
	BusEntry.Slave bus,
	
	// синхронный доступ к инструкциям (по фронту)
	input [31:0] instr_addr_i, 			// адрес ячейки памяти, содержащей инструкцию (ПЗУ или ОЗУ)
	output logic [31:0] instr_rdata_o 	// считанная инструкция (при ошибке доступа возвращается 0)
	
);
	
	
	//Создаём и инициализируем память
	logic [31:0] memory[0:RAM_SIZE/4-1];
	
	/*
	logic [7:0] tmp_memory[0:RAM_SIZE-1];
	initial begin
	    for (int i=0; i<RAM_SIZE; i++)
	       tmp_memory[i] = 0;
		if (RAM_INIT_FILE != "")
			$readmemh(RAM_INIT_FILE, tmp_memory);
	    for (int i=0; i<RAM_SIZE/4; i++)
            memory[i] <= {tmp_memory[i*4 + 3], tmp_memory[i*4 + 2], tmp_memory[i*4 + 1], tmp_memory[i*4 + 0]};
	end
	*/
	
	initial begin
	   if (RAM_INIT_FILE != "")
			$readmemh(RAM_INIT_FILE, memory);
    end
	
	
	// Чтение инструкции
	logic instr_addr_invalid;
	logic [$clog2(RAM_SIZE)-3:0] instr_cell_index;
    assign instr_cell_index = instr_addr_i[$clog2(RAM_SIZE)-1:2];
	always_ff @(posedge bus.clk)
		instr_rdata_o <= memory[instr_cell_index];
	
	
	/* Получаем номер ячейки. Так как память подключена к шине,
		у нас нет необходимости проверять выход за границы памяти. */
    logic [$clog2(RAM_SIZE)-2:0] ram_cell_index;
    assign ram_cell_index = bus.addr[$clog2(RAM_SIZE)-1:2];
	
	
	// Реализуем чтение из памяти
	always_ff @(posedge bus.clk)
		if (bus.req)
			bus.rdata <= memory[ram_cell_index];
	
	
	// Реализуем запись в память
	always_ff @(posedge bus.clk) begin
		if (bus.req && bus.we) begin
			
			if(bus.be[0])
				memory[ram_cell_index][7:0] <= bus.wdata[7:0];
			
			if(bus.be[1])
				memory[ram_cell_index][15:8] <= bus.wdata[15:8];
			
			if(bus.be[2])
				memory[ram_cell_index][23:16] <= bus.wdata[23:16];
			
			if(bus.be[3])
				memory[ram_cell_index][31:24] <= bus.wdata[31:24];
			
        end
	end
	
	
	// После завершения операции нужно выставить сигнал завершения на шину
	always_ff @(posedge bus.clk)
		bus.ack <= bus.req;
	
	
endmodule
