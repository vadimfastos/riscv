/* Системная шина. Все взаимодействия между ядром процессора с памятью и переферийными устройствами проходят через неё. */



/* Точка подключения к системной шине.
 * Все подключения к шине должны реализовываться при помощи этого интерфейса.
 */
interface BusEntry;
	
	/* Тактовые импульсы и сигнал синхронного сброса */
	logic clk;
	logic rstn;
	
	/* Шина адреса и шина данных */
	logic [31:0] addr;     // адрес устройства
	logic [31:0] rdata;    // считанные данные
	logic [31:0] wdata;    // данные для записи
	
	/* Шина управления */
	logic req;         // обращение к шине (выставляется ведущим устройством)
	logic we;          // сигнал записи (0-чтение, 1-запись)
	logic [3:0] be;    // к каким байтам идёт обращение при записи (1 на i месте показывает, что идёт обращение к i байту в йчейке памяти)
	logic ack;         // сигнал завершения операции (выставляется ведомым устройством)
	logic error;	   // сигнал ошибки, выставляется шиной, если запрашиваемый адрес не соотносится ни с каким устройством; к периферии не подключается
	
	/* Ведущие и ведомые устройства имеют разное подключение к шине */
	modport Master(input clk, rstn, rdata, ack, error, output addr, wdata, req, we, be);  // для ведущего устройства со стороны устройства
	modport MasterBus(output clk, rstn, rdata, ack, error, input addr, wdata, req, we, be);  // для ведущего устройства со стороны шины
	modport Slave(input clk, rstn, addr, wdata, req, we, be, output rdata, ack);   // для ведомого устройства со стороны устройства
	modport SlaveBus(output clk, rstn, addr, wdata, req, we, be, input rdata, ack);   // для ведомого устройства со стороны шины
    
endinterface


/* Описание работы шины:
 * На шине есть одно ведущее (master) устройство и несколько ведомых(slave).
 * Все операции на шине начинаются по инициативе ведущего устройства.
 * Для этого ведущее устройство должно выставить нужный адрес addr и сигнал req.
 * Для записи ещё дополнительно нужно выставить данные wdata и сигналы we и be.
 * Затем необходимо ждать сигнала ack или err.
 * В зависимости от быстродействия ведомого устройства он появится на следующем такте или через такт.
 * Сигнал req должен держаться один такт.
 */


/* Контроллер системной шины должен знать, какой адрес относится к какому устройству.
 * Для этого шину нужно сконфигурировать (в главном модуле) при помощи следующей структуры.
 * Для каждого подключенного к шине ведомого устройства необходимо задать начальный адрес и размер участка адресного пространства.
 */
typedef struct packed {
	logic [31:0] addr;
	logic [31:0] size;
} BusConfig;



/* Системная шина. К ней подключаются процессор, память и все переферийные устройства. */
module soc_bus #(parameter SLAVES_COUNT=2) (
    
    // тактовые импульсы и сигнал синхронного сброса
    input clk,
    input rstn,
    
    // подключение ведущего и ведомых устройств
    BusEntry.MasterBus master0,
    BusEntry.SlaveBus slaves [0:SLAVES_COUNT-1],
    
    // настройки шины (конфигурация)
    input BusConfig bus_config[0:SLAVES_COUNT-1]
);
	
	// Количество бит, необходимое для хранения номера ведомого устройства
	localparam SLAVES_COUNT_BITS = $clog2(SLAVES_COUNT);
	
	/* К шине может быть подключено разное число устройств,
	 * поэтому применяется динамическая генерация описания.
	 * Для избежания путаницы используются следующие переменные:
	 * is - index slave (для итерации по ведомым устройствам)
	 * isn - index slave number (для итерации по битам номера ведомого устройства)
	 */
	genvar is, isn;
	
	
	// Тактовые импульсы и сигнал синхронного сброса для ведущего устройства
	assign master0.clk = clk;
	assign master0.rstn = rstn;
	
	// Тактовые импульсы и сигнал синхронного сброса для ведомых устройств
	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].clk = clk;
	       assign slaves[is].rstn = rstn;
	   end
	endgenerate
	
	
	// Для каждого ведомого устройства узнаём, попал ли адрес, выставленный ведущим устройством, в его диапазон адресов
	logic [SLAVES_COUNT-1:0] is_slave_addr;
	generate
        for (is=0; is<SLAVES_COUNT; is++)
            assign is_slave_addr[is] = (master0.addr >= bus_config[is].addr) && (master0.addr < bus_config[is].addr + bus_config[is].size);
    endgenerate
    
    
    // Проверяем, не произошла ли ошибка (адрес не относится ни к одному ведомому устройству)
    logic is_addr_err;
    assign is_addr_err = !(|is_slave_addr);
	
	always_ff @(posedge clk) begin
		if (master0.req) begin
			master0.error <= is_addr_err;
		end else begin
			master0.error <= 0;
		end
	end
	
    
	/* Нам нужно определить, к какому устройству относится выданный ведущим устройством адрес.
	 * Мы уже определили, пренадлежит ли текущий адрес каждому из устройств.
	 * Теперь нужно определить номер устройства, то есть бит с каким номером на шине is_slave_addr равен 1.
	 * Для этого нужен шифратор.
	 */
	logic [SLAVES_COUNT-1:0] slave_index_and_is_slave_addr[0:SLAVES_COUNT_BITS-1];
    generate
        for (isn=0; isn<SLAVES_COUNT_BITS; isn++)
            for (is=0; is<SLAVES_COUNT; is++)
                assign slave_index_and_is_slave_addr[isn][is] = is[isn] & is_slave_addr[is];
    endgenerate
    
    
    // Определяем, к какому ведомому устройству идёт доступ
	logic [SLAVES_COUNT_BITS-1:0] cur_slave_number;
	generate
	   for (isn=0; isn<SLAVES_COUNT_BITS; isn++)
	       assign cur_slave_number[isn] = | slave_index_and_is_slave_addr[isn];
	endgenerate
	
	
    // Сигнал адреса, данных для записи и системные сигналы (за исключением req) можем выдавать всем ведомым устройствам одновременно
   	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].addr = master0.addr;
	       assign slaves[is].wdata = master0.wdata;
	       assign slaves[is].we = master0.we;
	       assign slaves[is].be = master0.be;
	   end
	endgenerate
	
	
	// Выдадим текущему ведомому устройству сигнал запроса req
	generate
	   for (is=0; is<SLAVES_COUNT; is++) begin
	       assign slaves[is].req = !is_addr_err && (is==cur_slave_number) && master0.req;
	   end
	endgenerate
	
	
	// Выдадим ведущему устройству считаные данные и сигнал завершения операции
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
