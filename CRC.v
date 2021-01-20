module CRC #(	parameter length_in=48,  
					parameter length_gen=9,
					parameter length_rest=length_gen-1)
				( 	input clk,
					input rst,
					input [length_in-1:0] data_in,
					input en,
					//input [length_gen-1:0] pol_gen,
					
					output en_seriala,
					output [length_in+length_rest-1:0] data_out
				);
				
	reg [1:0] state = 2'b0;
	reg reg_en_seriala = 1'b0;
	wire [length_in+length_rest-1:0] m_zero = {data_in,8'b0}; 
	reg [length_gen-1:0 ] deimpartit = 9'b0;
	reg [7:0] count = 8'b1; 
	reg [length_rest-1:0] rest = 8'b0; 
	//reg [8:0] a =9'b0;
	reg [length_gen-1:0] pol_gen = 9'b100110001;
	
	
	parameter idle = 2'b0;
	parameter start = 2'b01;
	parameter crc = 2'b10;
	parameter end_state = 2'b11;
	
	assign data_out = {data_in,rest};
	assign en_seriala = reg_en_seriala;
	
	always @(posedge clk) begin
		case (state)
			idle:  begin
				deimpartit <= 0;
				reg_en_seriala <=1'b0;
				count <= 8'b1;
				if (rst)
					state <= idle;
				else if(~rst && en)
					state <= start;
			end
			start: begin
				deimpartit <= {(m_zero[length_in+length_rest-1:length_in+length_rest-length_gen] ^ pol_gen) , m_zero[length_in+length_rest-length_gen-count]};
				//a <=m_zero[length_in+length_rest-length_gen-count];
				count <= count + 1'b1;
				state <= crc;
			end
			crc: begin
				if ( count == length_in+length_rest-length_gen+1 ) begin 
					state <= end_state;
					count <= 0;
					if ( deimpartit[length_gen-1] == 1'b0 )
						rest <= (deimpartit[length_gen-2:0] ^ 8'b0);//aici trebuie modificat cand schimb polinom generator
					else 
						rest <= (deimpartit[length_gen-2:0]  ^ pol_gen[length_gen-2:0]);
				end else if ( count < length_in+length_rest-length_gen+1 ) begin
					state <= crc;
					count <= count + 1'b1;
					if ( deimpartit[length_gen-1] == 1'b0 )
						deimpartit <=  {(deimpartit ^ 9'b0),m_zero[length_in+length_rest-length_gen-count]};//si aici ar trebui mod daca modific pol generator
					else
						deimpartit <=  {(deimpartit ^ pol_gen),m_zero[length_in+length_rest-length_gen-count]};
				end
			end
			end_state: begin
				rest <= rest;
				state <= idle;
				reg_en_seriala <=1'b1;
			end
		endcase
	end
endmodule
