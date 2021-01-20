module val_prag_adc(
	input clk_fpga,
	input in_d0,//mosi_1
	input in_d1,//mosi_1_in2
//	input in_d0_x,//mosi2
//	input in_d1_x,//mosi_2_in2
	input en_trs,
	input rst,
	input end_trs_on,
	input end_trs_off,
	
	output en_maxim,
	output [23:0] d_rcv,
	output s_clk,
	output cs
	//output s_clk_2,
	//output cs_2,
	//output [2:0] directie,
	//output no_det
    );
	 
	reg [2:0] state=0;
	reg reg_cs =1'b1;
	//pt a obtine 20mhz
	reg [2:0] count_s_clk = 3'b0;
	reg clk_pos=0;
	reg clk_ox=0;
	reg clk_zz=0;
	//...
	reg [11:0] data_reg = 12'b0;
	reg [11:0] data_reg2 = 12'b0;
	//reg [11:0] data_reg_x = 12'b0;
	//reg [11:0] data_reg2_x = 12'b0;
	reg [4:0] nr_bit = 5'b0;
	reg [4:0] count_again = 5'b0;
	reg reg_en_maxim =1'b0;
	//reg [5:0] nr_es = 6'b0;
	reg [11:0] nr_es = 12'b0;
	
	
	reg [2:0] regiune = 3'b111;
	reg [23:0] x_and_y = 24'b0;//x este de la 23 la 12, y este de la 11 la 0
	
	parameter [2:0] idle = 3'b0;
	parameter [2:0] start = 3'b1;
	parameter [2:0] receive = 3'b010;
	parameter [2:0] next_or_stop = 3'b011;
	parameter [2:0] final_st = 3'b100;
	//reg reg_no_det = 1'b0;
	//reg [23:0] finish_trs=24'b0;
	
	//assign no_det = reg_no_det;
	//assign directie = regiune;
	assign d_rcv = x_and_y;
	assign cs = reg_cs;
	//assign cs_2 = reg_cs;
	assign s_clk = (count_s_clk == 3'b010) ? clk_zz : (clk_pos ^ clk_ox);//pt a obtine 20mhz
	//assign s_clk_2 = (count_s_clk == 3'b010) ? clk_zz : (clk_pos ^ clk_ox);//pt a obtine 20mhz
	assign en_maxim = reg_en_maxim;

	
	always @(negedge clk_fpga) begin	
		 if(((en_trs==1'b1) || (state == start) || (state == receive) || (state == next_or_stop)) && (state != final_st))
			clk_zz <= clk_ox;
	end
	
	always @(posedge  clk_fpga) begin
		if(rst) begin
			count_s_clk <=3'b0;
			clk_pos <= 1'b0;
			clk_ox <=1'b0;
		end else if (((en_trs==1'b1) || (state == start) || (state == receive) || (state == next_or_stop)) && (state != final_st)) begin
				if (count_s_clk == 3'b100) begin
					count_s_clk <=3'b0;
					clk_pos <= 1'b1;
				end else begin
					count_s_clk <= count_s_clk + 1'b1;
					clk_pos <= 1'b0;
				end
					clk_ox <= clk_pos;
				end
		if (count_s_clk == 3'b010) begin
				clk_pos <= 1'b0;
				clk_ox <=1'b0;
		end	
		case (state)
			idle: begin
				reg_en_maxim=1'b0;
				reg_cs <= 1'b1;
				data_reg <= 12'b0;
				data_reg2 <= 12'b0;
				//data_reg_x <= 12'b0;
				//data_reg2_x <= 12'b0;
				//regiune <= 3'b111;
				x_and_y <= 24'b0;
				nr_bit <= 5'b0;
				//reg_no_det <= 1'b0;
				if (rst)
					state <= idle;
				else
					state <= (en_trs) ? start : idle;
			end
			start: begin
					if (clk_pos==1'b1) begin
						reg_cs <= 1'b0;
						state <= receive;
					end else
						state <= start;
			end
			receive : begin
					if(nr_bit == 5'b10000) 
						if (count_s_clk==3'b011) begin
							state <= next_or_stop;
							nr_bit <= 5'b0;
						end else
							state <= receive;
					else begin
						if (count_s_clk == 3'b010) begin
								data_reg <= {data_reg[10:0],in_d0};//primul adc
								data_reg2 <= {data_reg2[10:0],in_d1};//pt cealalta intrare primul adc
								//data_reg_x <= {data_reg_x[10:0],in_d0_x};//al doilea adc
								//data_reg2_x <= {data_reg2_x[10:0],in_d1_x};//al doilea adc a 2 in
								nr_bit <= nr_bit+1'b1;
								state <= receive ;
						end
					end
			end
			next_or_stop: begin	
					reg_cs <= 1'b1;
					if (count_again == 5'b10100) begin
						count_again <= 5'b0;
						state <= final_st;
					end else begin
						state <= next_or_stop;
						count_again <= count_again + 1'b1;
					end	
			end
			final_st : begin
				clk_pos <= 1'b0;
				//if (nr_es <= 6'b110001) begin
				if (nr_es <= 12'd999) begin
					state<=idle;
					x_and_y <= {data_reg2,data_reg};
					reg_en_maxim=1'b1;
					nr_es <= nr_es +1'b1;
				end else begin
					reg_en_maxim=1'b0;
					x_and_y <=0;
					if ((end_trs_on) || (end_trs_off)) begin 
						state <=idle;
						nr_es <= 0;
					end else 
						state <=final_st;
				end
				
			end
		endcase
	end
endmodule

