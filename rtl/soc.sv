`include "dev_defines.sv"


/* ������ SoC. �������� ����, ���������, ������, ���������� ����������. ���������� ���������� ���������. */
module soc #(
	parameter SOC_DEV_COUNT=1,		// ���������� ������������ ���������
	parameter RAM_INIT_FILE="",		// ��� ����� � ���������
	parameter RAM_SIZE = 64*1024	// ������ ������ � ������
) (

	/* �������� �������� � ������ ����������� ������ */
	input clk, rstn,
	
	/* ����������� ������������ ��������� � ���� */
	BusEntry.SlaveBus dev_bus_slaves[0:SOC_DEV_COUNT-1],
	
	/* ��������� ��������� ������������ ��� ������� ������������� ���������� (��������� ����� � ������ ������� ������ ��� ����������) */
	BusConfig dev_bus_config[0:SOC_DEV_COUNT-1],
	
	/* ����������� ������������ ��������� � ����������� ���������� */
	input [31:0] dev_int_req,	// ������� ���������� �� ���������
	output [31:0] dev_int_fin	// ������� � ���������� ��������� ���������� �����������
);
	
	// ��������� ����
	BusEntry bus_core0();
	BusEntry bus_slaves[0:SOC_DEV_COUNT]();
	BusConfig bus_config[0:SOC_DEV_COUNT];
	soc_bus #(
		(SOC_DEV_COUNT + 1) // ���-�� ������� ��������� = ���-�� ������������ ��������� + 1 (��� ������)
	) bus(.clk, .rstn, .master0(bus_core0), .slaves(bus_slaves), .bus_config);
	
	
	// ���������� ����������
    logic ic_int;              // ������ �� ��������� ����������
	logic ic_int_rst;          // ������ � ���������� ��������� ����������
	logic [31:0] ic_mcause;    // ����� ����������
	logic [31:0] ic_mie;       // ����� ����������
	soc_ic ic0 (
	   
        // ������������� � �����
        .clk,
        .rstn,
        
        // ������������ � ���� ����������
        .mie_i(ic_mie),
        .int_rst_i(ic_int_rst),
        .int_o(ic_int),
        .mcause_o(ic_mcause),
	     
	    // ������������ � ������������ �����������
        .int_req_i(dev_int_req),
        .int_fin_o(dev_int_fin)
	);
	
	
	// ���� ����������
	logic [31:0] instr_rdata, instr_addr;
	riscv_core core0 (
	
	    .bus(bus_core0),
		
		// ���������� ������ � ����������� (�� ������)
		.instr_rdata_i(instr_rdata),
		.instr_addr_o(instr_addr),
		
		// ���������� ����������
        .ic_int_i(ic_int),
        .ic_mcause_i(ic_mcause),
        .ic_mie_o(ic_mie),
        .ic_int_rst_o(ic_int_rst)
	);
	

	// ���������� ������
	soc_memory #(
		RAM_INIT_FILE,
		RAM_SIZE
	) memory0 (
		
		// ����������� � ����
		.bus(bus_slaves[0]),
		
		// ���������� ������ � ����������� (�� ������)
		.instr_rdata_o(instr_rdata),
		.instr_addr_i (instr_addr)
	);
	assign bus_config[0].addr = 0;
	assign bus_config[0].size = RAM_SIZE;
	
	
	// ���������� ������������ ����������
	generate
	   for (genvar i=0; i<SOC_DEV_COUNT; i++) begin
	   
			/* �������� �������� � ������ ����������� ������ */
            assign dev_bus_slaves[i].clk = bus_slaves[i+1].clk;
            assign dev_bus_slaves[i].rstn = bus_slaves[i+1].rstn;
			
			/* ���� ������ � ���� ������ */
			assign dev_bus_slaves[i].addr = bus_slaves[i+1].addr;
			assign dev_bus_slaves[i].wdata = bus_slaves[i+1].wdata;
			assign bus_slaves[i+1].rdata = dev_bus_slaves[i].rdata;
			
			/* ���� ���������� */
			assign dev_bus_slaves[i].req = bus_slaves[i+1].req;
			assign dev_bus_slaves[i].we = bus_slaves[i+1].we;
			assign dev_bus_slaves[i].be = bus_slaves[i+1].be;
			assign bus_slaves[i+1].ack = dev_bus_slaves[i].ack;
            assign bus_slaves[i+1].error = 1'b0;
			
	   end
	endgenerate
	assign bus_config[1:SOC_DEV_COUNT] = dev_bus_config;
	
	
endmodule
