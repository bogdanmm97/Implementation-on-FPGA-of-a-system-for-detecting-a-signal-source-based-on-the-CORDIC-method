module maxim(
	input clk,
	input rst,
	input en_maxim,
	input [23:0] es_adc,
	
	output [1:0] en_arctg,
	output [23:0] max_date_adc
    );
	 
	 
	 reg [23999:0] xy_axis = 24000'b0;
	 reg [1:0] state = 2'b0;
	 reg [11:0] count_nr_es = 12'b0;
	 reg [23:0] reg_out_es_max =24'b0;
	 reg [23:0] reg_out_xy_es_max =24'b0;
	 reg [1:0] reg_en_arctg = 2'b0;
	 
	 //alg max
	 reg [11:0] aux_x =12'b0;
	 reg [11:0] aux_y =12'b0;
	 reg [23:0] aux_xy = 24'b0;
	 
	 assign max_date_adc = reg_out_xy_es_max;
	 assign en_arctg = reg_en_arctg;
	 
	 always @(posedge clk) begin
		if(~rst)
			case (state)
				2'b0: begin
					aux_xy <=0; reg_en_arctg <= 2'b0;
					if (en_maxim) begin	
						xy_axis <= {xy_axis[23975:0],es_adc[23:12],es_adc[11:0]};
						if (count_nr_es == 12'd999) begin
							state <= 2'b1;
							count_nr_es <= 0;
						end else begin
							count_nr_es <= count_nr_es + 1'b1;
							state <= 2'b0;
						end
					end
				end
				2'b1: begin
					if (count_nr_es <= 12'd999) begin
						count_nr_es <= count_nr_es + 1'b1;
						xy_axis<={24'b0,xy_axis[23999:24]};
						if((xy_axis[23:12]>=aux_xy[23:12]) && (xy_axis[11:0]>=aux_xy[11:0])) aux_xy <= xy_axis[23:0]; else aux_xy <= aux_xy;
						state <= 2'b1;
					end else begin
						state <= 2'b10;
						count_nr_es <=0;
					end		
				end
				2'b10: begin
					if ((aux_xy[23:12] > 12'b00000011111) && (aux_xy[11:0] > 12'b00000011111)) begin//mai mare de 0.05V
						reg_out_xy_es_max <=aux_xy;
						reg_en_arctg <= 2'b11;
						state <= 2'b0;
					end else if ((aux_xy[23:12] > 12'b00011111111) && (aux_xy[11:0] < 12'b00000011111)) begin//0grade
						reg_out_xy_es_max <=aux_xy;
						reg_en_arctg <= 2'b11;
						state <= 2'b0;
					end else if ((aux_xy[23:12] < 12'b00000011111) && (aux_xy[11:0] > 12'b00011111111)) begin//mai mare de 0.025V,90grade
						reg_out_xy_es_max <=aux_xy;
						reg_en_arctg <= 2'b11;
						state <= 2'b0;
					end else begin//nedeterminare
						reg_out_xy_es_max <=24'b0;
						reg_en_arctg <= 2'b01;
						state <= 2'b0;
					end
				end
			endcase
		else begin
			count_nr_es <= 0; aux_x<=0; aux_y <=0; reg_out_es_max <=24'b0;  state <= 2'b0; reg_en_arctg <= 2'b0;
		end
	 end
endmodule
