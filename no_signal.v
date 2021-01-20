module no_signal(
	input clk,
	input rst,
	input n_det,//pt no detect
	
	output end_trs,
	output Tx
    );
	 
	 reg [2:0] state = 3'b0;
	 reg [11:0] count = 12'b0;
	 reg reg_Tx = 1'b1;
	 reg [7:0] d_shift = 8'b0;
	 reg [3:0] nr_bit = 4'b0;
	 reg [151:0] nedetectat = 152'h53656d6e616c206e6564657465637461740a0d;
	 reg [151:0] ned_text = 152'b0;
	 //reg [23:0] same_d =24'b0;
	 reg ok=0;
	 reg reg_end_trs = 1'b0;
	 
	
	 reg [5:0] nr_pachet = 6'b0;
	 reg [15:0] delay = 16'b0;
	
	 parameter stop_begin = 3'b0; 
	 parameter idle = 3'b01;
	 parameter start = 3'b010;
	 parameter trs_state = 3'b011;
	 parameter final = 3'b100;
	
	 assign Tx = reg_Tx;
	 assign end_trs = reg_end_trs;
	 
	 always @(posedge clk) begin
			case (state)
				stop_begin: begin
					reg_Tx<=1'b1;
					count <=12'b0;
					nr_pachet<=0;
					delay<=0;
					ned_text <= nedetectat;
					d_shift <=0;
					nr_bit <=0;
					reg_end_trs <= 1'b0;
					//same_d <= data_in;
					if(rst)
						state<=stop_begin;
					else if((~rst) && (n_det))
						state <= idle;		
				end
				idle: begin
					state <= start;
					ned_text <= {ned_text[143:0],8'b0};
					d_shift <= ned_text[151:144];
					nr_pachet <= nr_pachet+1'b1;	
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
					if (nr_pachet > 6'd19) begin
						reg_end_trs <= 1'b1;
						state <=stop_begin;
					end
					if (nr_pachet <= 6'd19) begin
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

