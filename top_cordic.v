module top_cordic(
	input clk,
	input rst,
	input en_trs,
	//adc
	input in_data_adc1_d0,
	input in_data_adc1_d1,
	//input in_data_adc2_d0,
	//input in_data_adc2_d1,

	
	//adc
	//output s_clk_2,
	//output cs_2
	output s_clk_1,
	output cs_1,
	
	//emisie
	output Tx
    );
	 wire en_maxim;
	 wire [23:0] data_out_adc;
	 wire [23:0] data_out_max;
	 wire [1:0] en_out_maxim;
	 wire en_extensie_biti = (en_out_maxim == 2'b11) ? 1'b1 : 1'b0 ;
	 wire en_no_sig = (en_out_maxim == 2'b01) ? 1'b1 : 1'b0;
	 wire [16:0] rez_f_atang;
	 wire en_conv;
	 wire [47:0] d_out_conv;
	 wire [31:0] x_in_atang;
	 wire [31:0] y_in_atang;
	 wire [55:0] data_out_crc;
	 wire en_atang = start_atang;
	 wire en_crc;
	 wire en_ser_on;
	 wire end_trs_on;
	 wire end_trs_off;
	 wire Tx_on, Tx_off;
	 wire tx_on;
	 
	 reg start_atang = 1'b0;
	 reg [31:0] x_intrare =32'b0;
	 reg [31:0] y_intrare =32'b0;
	 
	 assign x_in_atang = x_intrare;
	 assign y_in_atang = y_intrare;
	 assign Tx = (tx_on) ? Tx_on : Tx_off;
	 
	 val_prag_adc ADC(.clk_fpga(clk),.rst(rst),.end_trs_on(end_trs_on),.end_trs_off(end_trs_off),.in_d0(in_data_adc1_d0),.in_d1(in_data_adc1_d1),.en_trs(en_trs),.en_maxim(en_maxim),.d_rcv(data_out_adc),.s_clk(s_clk_1),.cs(cs_1));
	 maxim MAXIM(.clk(clk),.rst(rst),.en_maxim(en_maxim),.es_adc(data_out_adc),.max_date_adc(data_out_max),.en_arctg(en_out_maxim));
	 atang Arctg_alg(.clk(clk),.en(en_atang),.rst(rst),.x_in(x_in_atang),.y_in(y_in_atang),.z_out(rez_f_atang),.en_conv(en_conv));
	 conv_dec_ascii Conversie(.clk(clk),.en_conv(en_conv),.again(end_trs_on),.d_in(rez_f_atang),.d_out(d_out_conv),.en_crc(en_crc));
	 CRC crc(.clk(clk),.rst(rst),.en(en_crc),.data_in(d_out_conv),.data_out(data_out_crc),.en_seriala(en_ser_on));
	 com_ser EMISIE(.clk(clk),.rst(rst),.data_in(data_out_crc),.n_det(en_ser_on),.Tx(Tx_on),.end_trs(end_trs_on),.tx_on(tx_on));
	 no_signal No_signal(.clk(clk),.rst(rst),.n_det(en_no_sig),.Tx(Tx_off),.end_trs(end_trs_off));
	 
	 always @(posedge clk) begin
		if(en_extensie_biti) begin
			x_intrare[31:0] <= {1'b0,data_out_max[23:12],19'b0};
			y_intrare[31:0] <= {1'b0,data_out_max[11:0],19'b0};
			start_atang <= 1'b1;
		end else if (en_out_maxim == 2'b01) begin
			x_intrare[31:0] <= 32'b0;
			y_intrare[31:0] <= 32'b0;
			start_atang <= 1'b0;
		end else
			start_atang <= 1'b0;
	end
			

endmodule
