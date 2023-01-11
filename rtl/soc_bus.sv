/* ��������� ����. ��� �������������� ����� ����� ���������� � ������� � ������������� ������������ �������� ����� ��. */



/* ����� ����������� � ��������� ����.
 * ��� ����������� � ���� ������ ��������������� ��� ������ ����� ����������.
 */
interface BusEntry;
	
	/* �������� �������� � ������ ����������� ������ */
	logic clk;
	logic rstn;
	
	/* ���� ������ � ���� ������ */
	logic [31:0] addr;     // ����� ����������
	logic [31:0] rdata;    // ��������� ������
	logic [31:0] wdata;    // ������ ��� ������
	
	/* ���� ���������� */
	logic req;         // ��������� � ���� (������������ ������� �����������)
	logic we;          // ������ ������ (0-������, 1-������)
	logic [3:0] be;    // � ����� ������ ��� ��������� ��� ������ (1 �� i ����� ����������, ��� ��� ��������� � i ����� � ������ ������)
	logic ack;         // ������ ���������� �������� (������������ ������� �����������)
	logic error;	   // ������ ������, ������������ �����, ���� ������������� ����� �� ����������� �� � ����� �����������; � ��������� �� ������������
	
	/* ������� � ������� ���������� ����� ������ ����������� � ���� */
	modport Master(input clk, rstn, rdata, ack, error, output addr, wdata, req, we, be);  // ��� �������� ���������� �� ������� ����������
	modport MasterBus(output clk, rstn, rdata, ack, error, input addr, wdata, req, we, be);  // ��� �������� ���������� �� ������� ����
	modport Slave(input clk, rstn, addr, wdata, req, we, be, output rdata, ack);   // ��� �������� ���������� �� ������� ����������
	modport SlaveBus(output clk, rstn, addr, wdata, req, we, be, input rdata, ack);   // ��� �������� ���������� �� ������� ����
    
endinterface


/* �������� ������ ����:
 * �� ���� ���� ���� ������� (master) ���������� � ��������� �������(slave).
 * ��� �������� �� ���� ���������� �� ���������� �������� ����������.
 * ��� ����� ������� ���������� ������ ��������� ������ ����� addr � ������ req.
 * ��� ������ ��� ������������� ����� ��������� ������ wdata � ������� we � be.
 * ����� ���������� ����� ������� ack ��� err.
 * � ����������� �� �������������� �������� ���������� �� �������� �� ��������� ����� ��� ����� ����.
 * ������ req ������ ��������� ���� ����.
 */


/* ���������� ��������� ���� ������ �����, ����� ����� ��������� � ������ ����������.
 * ��� ����� ���� ����� ���������������� (� ������� ������) ��� ������ ��������� ���������.
 * ��� ������� ������������� � ���� �������� ���������� ���������� ������ ��������� ����� � ������ ������� ��������� ������������.
 */
typedef struct packed {
	logic [31:0] addr;
	logic [31:0] size;
} BusConfig;



/* ��������� ����. � ��� ������������ ���������, ������ � ��� ������������ ����������. */
module soc_bus #(parameter SLAVES_COUNT=2) (
    
    // �������� �������� � ������ ����������� ������
    input clk,
    input rstn,
    
    // ����������� �������� � ������� ���������
    BusEntry.MasterBus master0,
    BusEntry.SlaveBus slaves [0:SLAVES_COUNT-1],
    
    // ��������� ���� (������������)
    input BusConfig bus_config[0:SLAVES_COUNT-1]
);
	
	// ���������� ���, ����������� ��� �������� ������ �������� ����������
	localparam SLAVES_COUNT_BITS = $clog2(SLAVES_COUNT);
	
	/* � ���� ����� ���� ���������� ������ ����� ���������,
	 * ������� ����������� ������������ ��������� ��������.
	 * ��� ��������� �������� ������������ ��������� ����������:
	 * is - index slave (��� �������� �� ������� �����������)
	 * isn - index slave number (��� �������� �� ����� ������ �������� ����������)
	 */
	genvar is, isn;
	
	
	// �������� �������� � ������ ����������� ������ ��� �������� ����������
	assign master0.clk = clk;
	assign master0.rstn = rstn;
	
	// �������� �������� � ������ ����������� ������ ��� ������� ���������
	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].clk = clk;
	       assign slaves[is].rstn = rstn;
	   end
	endgenerate
	
	
	// ��� ������� �������� ���������� �����, ����� �� �����, ������������ ������� �����������, � ��� �������� �������
	logic [SLAVES_COUNT-1:0] is_slave_addr;
	generate
        for (is=0; is<SLAVES_COUNT; is++)
            assign is_slave_addr[is] = (master0.addr >= bus_config[is].addr) && (master0.addr < bus_config[is].addr + bus_config[is].size);
    endgenerate
    
    
    // ���������, �� ��������� �� ������ (����� �� ��������� �� � ������ �������� ����������)
    logic is_addr_err;
    assign is_addr_err = !(|is_slave_addr);
	
	always_ff @(posedge clk) begin
		if (master0.req) begin
			master0.error <= is_addr_err;
		end else begin
			master0.error <= 0;
		end
	end
	
    
	/* ��� ����� ����������, � ������ ���������� ��������� �������� ������� ����������� �����.
	 * �� ��� ����������, ����������� �� ������� ����� ������� �� ���������.
	 * ������ ����� ���������� ����� ����������, �� ���� ��� � ����� ������� �� ���� is_slave_addr ����� 1.
	 * ��� ����� ����� ��������.
	 */
	logic [SLAVES_COUNT-1:0] slave_index_and_is_slave_addr[0:SLAVES_COUNT_BITS-1];
    generate
        for (isn=0; isn<SLAVES_COUNT_BITS; isn++)
            for (is=0; is<SLAVES_COUNT; is++)
                assign slave_index_and_is_slave_addr[isn][is] = is[isn] & is_slave_addr[is];
    endgenerate
    
    
    // ����������, � ������ �������� ���������� ��� ������
	logic [SLAVES_COUNT_BITS-1:0] cur_slave_number;
	generate
	   for (isn=0; isn<SLAVES_COUNT_BITS; isn++)
	       assign cur_slave_number[isn] = | slave_index_and_is_slave_addr[isn];
	endgenerate
	
	
    // ������ ������, ������ ��� ������ � ��������� ������� (�� ����������� req) ����� �������� ���� ������� ����������� ������������
   	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].addr = master0.addr;
	       assign slaves[is].wdata = master0.wdata;
	       assign slaves[is].we = master0.we;
	       assign slaves[is].be = master0.be;
	   end
	endgenerate
	
	
	// ������� �������� �������� ���������� ������ ������� req
	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].req = !is_addr_err && (is==cur_slave_number) && master0.req;
	   end
	endgenerate
	
	
	// ������� �������� ���������� �������� ������ � ������ ���������� ��������
	logic [31:0] slaves_rdata[0:SLAVES_COUNT-1];
	logic slaves_ack[0:SLAVES_COUNT-1];
	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves_rdata[is] = slaves[is].rdata;
	       assign slaves_ack[is] = slaves[is].ack;
	   end
	endgenerate
	assign master0.rdata = slaves_rdata[cur_slave_number];
	assign master0.ack = slaves_ack[cur_slave_number];
    
    
endmodule
