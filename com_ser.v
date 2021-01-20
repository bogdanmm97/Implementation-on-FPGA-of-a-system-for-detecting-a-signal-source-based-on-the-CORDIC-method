module com_ser(
	input [55:0] data_in,
	input clk,
	input rst,
	input n_det,//pt no detect
	
	output end_trs,
	output tx_on,
	output Tx
    );
	 
	 reg [2:0] state = 3'b0;
	 reg [11:0] count = 12'b0;
	 reg reg_Tx = 1'b1;
	 reg [7:0] d_shift = 8'b0;
	 reg [3:0] nr_bit = 4'b0;
	 reg [271:0] afis = 272'h4d617375726120756e676869756c756920657374652064653a202E67726164650a0d;
	 reg [271:0] text = 272'b0;
	 reg [55:0] same_d =56'b0;
	 reg ok=0;
	 reg reg_end_trs =1'b0;
	 reg reg_tx_on = 1'b0;
	 
	
	 reg [5:0] nr_pachet = 6'b0;
	 reg [15:0] delay = 16'b0;
	
	 parameter stop_begin = 3'b0; 
	 parameter idle = 3'b01;
	 parameter start = 3'b010;
	 parameter trs_state = 3'b011;
	 parameter final = 3'b100;
	
	 assign Tx = reg_Tx;
	 assign end_trs = reg_end_trs;
	 assign tx_on = reg_tx_on;
	 
	 always @(posedge clk) begin
			case (state)
				stop_begin: begin
					reg_Tx<=1'b1;
					count <=12'b0;
					nr_pachet<=0;
					delay<=0;
					text <= afis;
					d_shift <=0;
					nr_bit <=0;
					same_d <= data_in;
					reg_end_trs <= 1'b0;
					reg_tx_on <=1'b0;
					if (rst)
						state <=stop_begin;
					else if ((~rst) && (n_det))
						state <= idle;		
				end
				idle: begin
					reg_tx_on <=1'b1;
					state <= start;
					if ((nr_pachet == 6'b11010) || (nr_pachet == 6'b11011) || (nr_pachet == 6'b11100) || (nr_pachet == 6'd30) || (nr_pachet == 6'd31)|| (nr_pachet == 6'd32) || (nr_pachet == 6'd33))  begin
						if (nr_pachet == 6'b11010) begin
							d_shift <= data_in[55:48];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'b11011) begin
							d_shift <= data_in[47:40];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'b11100) begin
							d_shift <= data_in[39:32];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'd30) begin
							d_shift <= data_in[31:24];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'd31) begin
							d_shift <= data_in[23:16];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'd32) begin
							d_shift <= data_in[15:8];
							nr_pachet <= nr_pachet+1'b1;
						end else if (nr_pachet == 6'd33) begin
							d_shift <= data_in[7:0];
							nr_pachet <= nr_pachet+1'b1;
						end
					end else begin
						text <= {text[263:0],8'b0};
						d_shift <= text[271:264];
						nr_pachet <= nr_pachet+1'b1;
					end
				end
				start: begin
					if (count == 12'h363) begin	
						state <= trs_state;
						count <= 12'b0;
						reg_Tx <= d_shift[0] ;
						d_shift <= {1'b0,d_shift[7:1]};
						nr_bit <= nr_bit + 1'b1;
					end else begin
						state <= start;
						count <= count + 1'b1;
						reg_Tx <= 1'b0;
					end
				end
				trs_state: begin
					if(count == 12'h363)
						if ( nr_bit > 4'd7) begin
							state <= final;
							count <= 12'b0;
							nr_bit <= 4'b0;
						end else begin
							count <= 12'b0;
							reg_Tx <= d_shift[0] ;
							d_shift <= {1'b0,d_shift[7:1]};
							nr_bit <= nr_bit + 1'b1;
							state <= trs_state;
						end
					else
						count <= count + 1'b1;
				end
				final : begin
					reg_Tx <= 1'b1;
					if(nr_pachet > 6'd40) begin
						if(delay==16'h1)
							reg_end_trs <= 1'b1;
						else
							reg_end_trs <= 1'b0;
						if ( delay == 16'hf) begin
							delay <= 16'b0;
							state <= stop_begin;
							text <= afis;
						end else
							delay <= delay+1'b1;					
					end else if ( nr_pachet <= 6'd40) begin
						if ( delay == 16'hffff)
							delay <= 16'b0;
						else
							delay <= delay+1'b1;
						state <= (delay == 16'hffff) ? idle : final;	
					end
				end
			endcase
	 end

endmodule

