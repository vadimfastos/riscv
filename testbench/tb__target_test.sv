`timescale 1ns / 100ps


/* Тестирование SoC с тестовым переферийным устройством.
 * Программа для проверки: строковый калькулятор.
 * Подсчёт строкового выражения в целых числах с учётом приоритетов.
 * Допустимые входные символы: цифры, +, -, *
 * Реализована обработка ошибок, сообщения об ошибке выводятся в консоль.
*/
module tb__target_test;
	
	/* Тактовые импульсы и сигнал сброса*/
	logic clk, rstn;
	always begin
	   clk = 1'b0;
	   #1;
	   clk = 1'b1;
	   #1;
	end
	initial begin
		rstn = 1'b0;
		#20;
		rstn = 1'b1;
	end
	
	/* Тестовое периферийное устройство (1024 байт ввод, 1024 байт вывод + возможность посыла сигнала прерывания) */
	logic [7:0] dev_test_in[0:1023];
	logic [7:0] dev_test_out[0:1023];
	logic dev_test_irq;
    
	/* Подключаем тестируемое устройство */
    target_test DUT(.*);
	
	
	/* Прочитать строку от устройства */
	task gets(output string str);
		int	i;
		
		i = 0;
		str = "";
		#1;
		
		while (i<1024 && dev_test_out[i]!=0) begin
			str = {str, dev_test_out[i]};
			#1;
			i++;
			#1;
		end
	endtask
	
	
	/* Передать строку устройству */
	task puts(input string str);
		for (int i=0; i<str.len(); i++)
			dev_test_in[i] = str[i];
		dev_test_in[str.len()] = 0;
		
		dev_test_irq = 1'b0;
		@(posedge clk);
		dev_test_irq = 1'b1;
		@(posedge clk);
		dev_test_irq = 1'b0;
	endtask
	
	
	/* Шаг тестирования - передать строку устройству и получить ответ */
	task test_step(input string str);
		string ans;
		
		puts(str);
		#200000;
		
		gets(ans);
		$display(ans);
	endtask
	
	
	/* Тестируем устройство */
	initial begin
		#100000;
		
		test_step("2+2"); //  4
		test_step("21-23+12"); // 10
		test_step("561245+3154-114+971"); // 565256
		test_step("14*12*3-1218+1331"); // 617
		test_step("12-35*31+51*19-12*14*1+3"); // -269
		
		$finish;
	end
	
	
endmodule
