`default_nettype none
module tiny_nn (
	clk,
	in,
	btn,
	valid,
	inside_circle
);
	reg _sv2v_0;
	input wire clk;
	input wire [3:0] in;
	input wire [3:0] btn;
	output reg valid;
	output wire inside_circle;
	reg [47:0] W0;
	always @(*) begin
		if (_sv2v_0)
			;
		W0[40+:8] = 8'b01110010;
		W0[32+:8] = 8'b01110010;
		W0[24+:8] = 8'b11101110;
		W0[16+:8] = 8'b11101000;
		W0[8+:8] = 8'b00110011;
		W0[0+:8] = 8'b11000011;
	end
	reg [23:0] B0;
	always @(*) begin
		if (_sv2v_0)
			;
		B0[20+:4] = 4'b1111;
		B0[16+:4] = 4'b1110;
		B0[12+:4] = 4'b1101;
		B0[8+:4] = 4'b0010;
		B0[4+:4] = 4'b1111;
		B0[0+:4] = 4'b1101;
	end
	reg [23:0] W1;
	always @(*) begin
		if (_sv2v_0)
			;
		W1[20+:4] = 4'b1000;
		W1[16+:4] = 4'b1100;
		W1[12+:4] = 4'b1011;
		W1[8+:4] = 4'b1000;
		W1[4+:4] = 4'b1100;
		W1[0+:4] = 4'b1010;
	end
	wire [3:0] B1;
	assign B1[0+:4] = 4'b0111;
	reg sync_x0;
	reg sync_y0;
	reg sync_start;
	reg sync_rst_n;
	reg load_x0;
	wire load_x1;
	reg load_y0;
	wire load_y1;
	reg start;
	reg rst_n;
	reg [7:0] coor;
	always @(posedge clk) begin
		{sync_x0, sync_y0} <= {btn[1], btn[0]};
		sync_start <= btn[2];
		sync_rst_n <= btn[3];
		{load_x0, load_y0} <= {sync_x0, sync_y0};
		start <= sync_start;
		rst_n <= sync_rst_n;
	end
	always @(posedge clk)
		if (!rst_n)
			coor <= 1'sb0;
		else if (load_x0)
			coor[3-:4] <= in;
		else if (load_y0)
			coor[7-:4] <= in;
	reg start_mac0;
	reg start_mac1;
	reg sel_layer;
	reg store_layer0;
	reg store_layer1;
	wire done_mac0;
	wire done_mac1;
	reg [2:0] state;
	reg [2:0] nextState;
	always @(posedge clk)
		if (~rst_n)
			state <= 3'd0;
		else
			state <= nextState;
	always @(*) begin
		if (_sv2v_0)
			;
		start_mac0 = 1'd0;
		start_mac1 = 1'd0;
		sel_layer = 1'd0;
		store_layer0 = 1'd0;
		store_layer1 = 1'd0;
		valid = 1'd0;
		case (state)
			3'd0:
				if (start) begin
					nextState = 3'd1;
					start_mac0 = 1'd1;
				end
				else
					nextState = 3'd0;
			3'd1:
				if (done_mac0) begin
					nextState = 3'd2;
					sel_layer = 1'd1;
					store_layer0 = 1'd1;
				end
				else
					nextState = 3'd1;
			3'd2: begin
				nextState = 3'd3;
				start_mac1 = 1'd1;
			end
			3'd3:
				if (done_mac1) begin
					nextState = 3'd4;
					store_layer1 = 1'd1;
				end
				else begin
					nextState = 3'd3;
					sel_layer = 1'd1;
				end
			3'd4: nextState = 3'd5;
			3'd5: begin
				nextState = 3'd5;
				valid = 1'd1;
			end
			default: nextState = 3'd0;
		endcase
	end
	reg [23:0] layer0_nodes;
	wire [23:0] mac_out0;
	wire [23:0] relu_out;
	reg [3:0] layer1_node;
	wire [3:0] mac_out1;
	always @(posedge clk)
		if (~rst_n) begin
			layer0_nodes <= 'd0;
			layer1_node <= 'd0;
		end
		else if (store_layer0)
			layer0_nodes <= relu_out;
		else if (store_layer1)
			layer1_node <= mac_out1;
	assign inside_circle = ~layer1_node[3];
	mul phase0(
		.W(W0),
		.B(B0),
		.in(coor),
		.clk(clk),
		.rst_n(rst_n),
		.start_mac(start_mac0),
		.mac_out(mac_out0),
		.done_mac(done_mac0)
	);
	relu activation(
		.in(mac_out0),
		.out(relu_out)
	);
	mul #(
		.MAT_ROWS(1),
		.MAT_COLS(6)
	) phase1(
		.W(W1),
		.B(B1),
		.in(layer0_nodes),
		.clk(clk),
		.rst_n(rst_n),
		.start_mac(start_mac1),
		.mac_out(mac_out1),
		.done_mac(done_mac1)
	);
	initial _sv2v_0 = 0;
endmodule
module mul (
	W,
	B,
	in,
	clk,
	rst_n,
	start_mac,
	mac_out,
	done_mac
);
	reg _sv2v_0;
	parameter MAT_ROWS = 6;
	parameter MAT_COLS = 2;
	input wire [((MAT_ROWS * MAT_COLS) * 4) - 1:0] W;
	input wire [(MAT_ROWS * 4) - 1:0] B;
	input wire [(MAT_COLS * 4) - 1:0] in;
	input wire clk;
	input wire rst_n;
	input wire start_mac;
	output reg [(MAT_ROWS * 4) - 1:0] mac_out;
	output reg done_mac;
	reg overflow;
	reg [(MAT_ROWS * 4) - 1:0] prod;
	reg [(MAT_ROWS * 4) - 1:0] prod_to_add;
	reg [7:0] temp_prod;
	reg [3:0] fixed_val_prod;
	reg [3:0] temp_sum;
	reg [3:0] fin_sum;
	reg [3:0] fin_acc;
	always @(posedge clk)
		if (~rst_n) begin
			prod_to_add <= 'd0;
			done_mac <= 'd0;
		end
		else begin
			prod_to_add <= prod;
			done_mac <= start_mac;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < MAT_ROWS; i = i + 1)
				begin
					temp_sum = 1'sb0;
					begin : sv2v_autoblock_2
						reg signed [31:0] j;
						for (j = 0; j < MAT_COLS; j = j + 1)
							begin
								temp_prod = {{4 {W[(((i * MAT_COLS) + j) * 4) + 3]}}, W[((i * MAT_COLS) + j) * 4+:4]} * {{4 {in[(j * 4) + 3]}}, in[j * 4+:4]};
								overflow = temp_prod[7:5] != {3 {temp_prod[7]}};
								if (overflow)
									fixed_val_prod = (temp_prod[7] ? 4'sb1000 : 4'sb0111);
								else
									fixed_val_prod = temp_prod[5:2];
								fin_sum = temp_sum + fixed_val_prod;
								if ((fin_sum[3] & !temp_sum[3]) & !fixed_val_prod[3])
									temp_sum = 4'sb0111;
								else if ((!fin_sum[3] & temp_sum[3]) & fixed_val_prod[3])
									temp_sum = 4'sb1000;
								else
									temp_sum = fin_sum;
							end
					end
					prod[i * 4+:4] = temp_sum;
				end
		end
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < MAT_ROWS; i = i + 1)
				begin
					fin_acc = prod_to_add[i * 4+:4] + B[i * 4+:4];
					if ((fin_acc[3] & !prod_to_add[(i * 4) + 3]) & !B[(i * 4) + 3])
						mac_out[i * 4+:4] = 4'sb0111;
					else if ((!fin_acc[3] & prod_to_add[(i * 4) + 3]) & B[(i * 4) + 3])
						mac_out[i * 4+:4] = 4'sb1000;
					else
						mac_out[i * 4+:4] = fin_acc;
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module relu (
	in,
	out
);
	reg _sv2v_0;
	parameter MAT_ROWS = 6;
	input wire [(MAT_ROWS * 4) - 1:0] in;
	output reg [(MAT_ROWS * 4) - 1:0] out;
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < MAT_ROWS; i = i + 1)
				out[i * 4+:4] = (in[(i * 4) + 3] ? 4'b0000 : in[i * 4+:4]);
		end
	end
	initial _sv2v_0 = 0;
endmodule