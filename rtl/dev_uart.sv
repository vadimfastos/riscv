`include "dev_defines.sv"


/* ������������ ����������: UART ���������. ��������� ������������ ������� � �����������. */
module dev_uart # (
	parameter CLOCK_FREQUENCY = 100*1000*1000 // �������� ������� ����������
) (
	
	/* ����������� � ���� */
	BusEntry.Slave bus,
	input int_fin_i,
	output int_req_o,
	
	/* ����������� � �����. USB-RS232 Interface */
	input UART_TXD_IN,
	output UART_RXD_OUT
);
	
	
	// ���������� ���������� UART ����������
	logic uart_rx_ready, uart_tx_req, uart_tx_busy;
	logic [7:0] uart_rx_data, uart_tx_data;
	uart # (CLOCK_FREQUENCY) uart0 (
		
		// �������� �������� � ������ ������
		.clk(bus.clk),
		.rstn(bus.rstn),
	
		// ���� ������
		.rx_data(uart_rx_data), 	// �������� ������, ������� ��� rx_ready=1
		.rx_ready(uart_rx_ready),	// ������������ � 1 �� 1 ����, ����� �������� ������ ������� (����� ���������� ����� �����)
	
		// �������� ������
		.tx_data(uart_tx_data),	// ������, ������� ����� ��������
		.tx_req(uart_tx_req),	// ����� ��������� � 1 �� 1 ����, ����� ������ �������� ������, ����� tx_busy=0
		.tx_busy(uart_tx_busy),	// ���� ��������� �����������
	
		// ��������� UART
		.rxd(UART_TXD_IN),
		.txd(UART_RXD_OUT)
	);

	
	// ���������� FIFO ��� ������ ��������
	localparam RX_FIFO_SIZE = 1024;
	logic rx_fifo_data_ready, rx_fifo_clear_req;
	logic [7:0] rx_fifo[0:RX_FIFO_SIZE-1];
	logic [$clog2(RX_FIFO_SIZE)-1:0] rx_fifo_read_pos, rx_fifo_write_pos;
	
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn || rx_fifo_clear_req) begin
			rx_fifo_write_pos <= 0;
		end else if (uart_rx_ready) begin
			
			// ���� ��������� ����� ����������, ���������� ������
			if (rx_fifo_write_pos+1 != rx_fifo_read_pos) begin
				rx_fifo[rx_fifo_write_pos] <= uart_rx_data;
				rx_fifo_write_pos <= rx_fifo_write_pos + 1;
			end
			
		end
	end
	
	assign rx_fifo_data_ready = rx_fifo_read_pos != rx_fifo_write_pos;
	
	
	// ����������, � ������ �������� ��� ���������
	logic [9:0] reg_index;
	assign reg_index = bus.addr[11:2];
	
	
	// �������� ������
	always_ff @(posedge bus.clk) begin
		if (!bus.rstn) begin
			rx_fifo_read_pos <= 0;
		end else if (bus.req && !bus.we) begin
			case (reg_index)
		
				// ������ �� �������� ������� � ����������
				(`DEV_UART__REG_CONTROL_STATUS>>2):
					bus.rdata <= (rx_fifo_data_ready<<`DEV_UART__CSR_RX_DATA_READY) | (uart_tx_busy<<`DEV_UART__CSR_TX_BUSY);
				
				// ������ �� �������� �������� ������. ���� � ������ �������� ���� ������, �� ���������� ������� �� � ������� �� �� ������.
				(`DEV_UART__REG_RXD>>2): begin
					if (rx_fifo_data_ready) begin
						bus.rdata <= {24'b0, rx_fifo[rx_fifo_read_pos]};
						rx_fifo_read_pos <= rx_fifo_read_pos + 1;
					end else begin
						bus.rdata <= 32'b0;
					end
				end
				
				(`DEV_UART__REG_TXD>>2):
					bus.rdata <= {24'b0, uart_tx_data};
				default: bus.rdata <= 32'b0;
				
			endcase
		end else begin
			if (rx_fifo_clear_req)
				rx_fifo_read_pos <= 0;
		end
	end
	
	
	// �������� ������ � ������� ������ ��� ��������
	always_ff @(posedge bus.clk)
		if (!bus.rstn) begin
			uart_tx_data <= 8'b0;
		end else if (bus.req && bus.we && reg_index==(`DEV_UART__REG_TXD>>2)) begin
			uart_tx_data <= bus.wdata[7:0];
		end
	
	
	// �������� ������ � ������� ����������
	always_ff @(posedge bus.clk)
		if (bus.rstn && bus.req && bus.we && reg_index==(`DEV_UART__REG_CONTROL_STATUS>>2)) begin
			uart_tx_req <= !uart_tx_busy && bus.wdata[`DEV_UART__CSR_TX_REQ];
			rx_fifo_clear_req <= bus.wdata[`DEV_UART__CSR_RX_CLEAR];
		end else begin
			uart_tx_req <= 0;
			rx_fifo_clear_req <= 0;
		end
	
	
	// ����� ���������� �������� ����� ��������� ������ ���������� �� ����
	always_ff @(posedge bus.clk)
		bus.ack <= bus.req;
	
	
	// ����� ������� ���������� (0, ��� ��� ���������� �� ������������)
	assign int_req_o = 1'b0;
	
	
endmodule



/* ���������� UART ����������. ���� ������� ��������� ������, �� ��� ������������. */
module uart # (
	parameter CLOCK_FREQUENCY = 100*1000*1000, // �������� ������� ����������
	parameter BAUDRATE = 9600 // �������� �������� ������ (���)
) (
	
	// �������� �������� � ������ ������
	input clk,
	input rstn,
	
	// ���� ������
	output logic [7:0] rx_data,	// �������� ������, ������� ��� rx_ready=1
	output logic rx_ready,		// ������������ � 1 �� 1 ����, ����� �������� ������ ������� (����� ���������� ����� �����)
	
	// �������� ������
	input [7:0] tx_data,	// ������, ������� ����� ��������
	input tx_req,			// ����� ��������� � 1 �� 1 ����, ����� ������ �������� ������, ����� tx_busy=0
	output tx_busy,			// ���� ��������� �����������
	
	// ��������� UART
	input rxd,
	output logic txd
);
	
	// ������������ ��������� ������� ��� ������������ UART
	localparam CLOCK_DIVIDER = CLOCK_FREQUENCY / (BAUDRATE);
	localparam CLOCK_DIVIDER_HALF = CLOCK_FREQUENCY / (BAUDRATE*2);
	
	
	/* �������� ������ ��� ����� ������ (rx_clk), ������������ �� 1 ����, ����� ����� ������� ��������� ���.
		rx_clk_start ��c��������� � 1, ����� ����� ������ ������������. ������� ���� ����� �������� �������� �����. */
	logic rx_clk_start, rx_clk;
	logic [$clog2(CLOCK_DIVIDER)-1:0] rx_clk_counter;
	assign rx_clk = rx_clk_counter == 0;
	
	always_ff @(posedge clk) begin
		if (!rstn) begin
			rx_clk_counter <= CLOCK_DIVIDER_HALF - 1;
		end else begin
			if (rx_clk_start) begin
				rx_clk_counter <= CLOCK_DIVIDER_HALF - 1;
			end else begin
				rx_clk_counter <= (rx_clk_counter!=0) ? (rx_clk_counter-1) : (CLOCK_DIVIDER-1);
			end
		end
	end
	
	
	/* �������� ������ ��� �������� ������ (tx_clk), ������������ �� 1 ����, ����� ����� �������� ��������� ���. */
	logic tx_clk;
	logic [$clog2(CLOCK_DIVIDER)-1:0] tx_clk_counter;
	assign tx_clk = tx_clk_counter == 0;
	
	always_ff @(posedge clk) begin
		if (!rstn) begin
			tx_clk_counter <= CLOCK_DIVIDER - 1;
		end else begin
			tx_clk_counter <= (tx_clk_counter!=0) ? (tx_clk_counter-1) : (CLOCK_DIVIDER-1);
		end
	end
	
	
	// ������������ ���� ������
	enum {RX_STATE_IDLE, RX_STATE_START, RX_STATE_DATA, RX_STATE_STOP} rx_state;
	logic [2:0] rx_bit_counter;
	
	// ���������� ������ ������������ ��������, ����� ��������� ������� �� 1 � 0 � ��������� ��������
	assign rx_clk_start = (rx_state==RX_STATE_IDLE) && !rxd;
	
	always_ff @(posedge clk) begin
		if (!rstn) begin
			rx_state <= RX_STATE_IDLE;
			rx_ready <= 0;
		end else begin
			case (rx_state)
				
				// ���� �� ��������� � ��������� �������� � �� ���� �������� ������ 0, �� ��� �������� � ������ ��������� ���.
				RX_STATE_IDLE: begin
					if (!rxd)
						rx_state <= RX_STATE_START;
					rx_ready <= 0;
					rx_bit_counter <= 0;
				end
				
				// ��������� ��������� ��� � ��������� ��� �� ��������� 0
				RX_STATE_START:
					if (rx_clk)
						rx_state <= (!rxd) ? RX_STATE_DATA : RX_STATE_IDLE;
				
				// ��������� ��������� ��� ������
				RX_STATE_DATA:
					if (rx_clk) begin
						rx_data <= {rxd, rx_data[7:1]};
						if (rx_bit_counter == 3'd7)
							rx_state <= RX_STATE_STOP;
						rx_bit_counter <= rx_bit_counter + 1;
					end
				
				// ��������� �������� ��� � ��������� ��� �� ��������� 1
				RX_STATE_STOP:
					if (rx_clk) begin
						rx_ready <= rxd; // �������� ������ ������� ������ ���� �������� ��� ����� 1
						rx_state <= RX_STATE_IDLE;
					end
				
				default: rx_state <= RX_STATE_IDLE;
			endcase
		end
	end
	
	
	// ������������ �������� ������
	enum {TX_STATE_IDLE, TX_STATE_START, TX_STATE_DATA, TX_STATE_STOP} tx_state;
	logic [7:0] tx_buffer;
	logic [2:0] tx_bit_counter;
	
	// ���������� ���� ��������� �����������
	assign tx_busy = tx_state != TX_STATE_IDLE;
	
	always_ff @(posedge clk) begin
		if (!rstn) begin
			tx_state <= TX_STATE_IDLE;
			txd <= 1;
		end else begin
			case (tx_state)
				
				// ���� � ��������� �������� ������ ������ �� ��������, �� ��������� ���
				TX_STATE_IDLE:
					if (tx_req) begin
						tx_state <= TX_STATE_START;
						tx_buffer <= tx_data;
						tx_bit_counter <= 3'd0;
					end
				
				// �������� ��������� ���
				TX_STATE_START:
					if (tx_clk) begin
						tx_state <= TX_STATE_DATA;
						txd <= 0;
					end
					
				// �������� ��������� ��� ������
				TX_STATE_DATA:
					if (tx_clk) begin
						txd <= tx_buffer[0];
						tx_buffer <= {1'b0, tx_buffer[7:1]};
						if (tx_bit_counter == 3'd7)
							tx_state <= TX_STATE_STOP;
						tx_bit_counter <= tx_bit_counter + 1;
					end
				
				// �������� �������� ���
				TX_STATE_STOP:
					if (tx_clk) begin
						tx_state <= TX_STATE_IDLE;
						txd <= 1;
					end
				
				default: tx_state <= TX_STATE_IDLE;
			endcase
		end
	end
	
	
endmodule
