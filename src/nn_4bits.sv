`default_nettype none

// top module, has control logic
module tiny_nn
  (input logic clk, 
   input logic [3:0] in,
   input logic [3:0] btn, 
   output logic valid, inside_circle);

  // Q2.1 : 1 sign 2 int 1 frac

  ///////////////////////////////////////////////////////////
  //////////////////// HARDCODED WEIGHTS ////////////////////
  ///////////////////////////////////////////////////////////

  /*** W0 (6x2) 
  [[ 1.5, -2.0],
   [ 1.5,  1.5],
   [-4.0, -1.0],
   [ 1.5, -1.0],
   [ 0.0, -2.0],
   [ 1.0,  4.0 ]] -> saturate to 3.5
  ******************/

  logic [5:0][1:0][3:0] W0; 
  always_comb begin
    W0[5] = {4'b0111, 4'b0010};
    W0[4] = {4'b0111, 4'b0010};
    W0[3] = {4'b1110, 4'b1110};
    W0[2] = {4'b1110, 4'b1000};
    W0[1] = {4'b0011, 4'b0011};
    W0[0] = {4'b1100, 4'b0011};
  end

  /*** B0 (6x1) 
  [-1.5, -0.5, 1.0, -1.5, -1.0, -0.5]
  ***/
  // logic [5:0][3:0] B0 = '{
  //   4'b1111,  // B0[5]: -0.5
  //   4'b1110,  // B0[4]: -1.0
  //   4'b1101,  // B0[3]: -1.5
  //   4'b0010,  // B0[2]:  1.0
  //   4'b1111,  // B0[1]: -0.5
  //   4'b1101   // B0[0]: -1.5
  // };

  logic [5:0][3:0] B0;
  always_comb begin
    B0[5] = 4'b1111;
    B0[4] = 4'b1110;
    B0[3] = 4'b1101;
    B0[2] = 4'b0010;
    B0[1] = 4'b1111;
    B0[0] = 4'b1101;
  end
  /*** W1 (1x6) 
  [[-3.0, -2.0, -4.0, -2.5, -2.0, -3.5 ]] -> saturate to -4.0
  ******************/
  // logic [0:0][5:0][3:0] W1 = '{
  //   '{4'b1000,   // W1[0][5]: -4.0
  //     4'b1100,   // W1[0][4]: -2.0
  //     4'b1011,   // W1[0][3]: -2.5
  //     4'b1000,   // W1[0][2]: -4.0
  //     4'b1100,   // W1[0][1]: -2.0
  //     4'b1010}   // W1[0][0]: -3.0
  // };

  logic [5:0][3:0] W1; 
  always_comb begin
    W1[5] = 4'b1000;
    W1[4] = 4'b1100;
    W1[3] = 4'b1011;
    W1[2] = 4'b1000;
    W1[1] = 4'b1100;
    W1[0] = 4'b1010;
  end

  /*** B1 (1x1)
  4.0954 -> saturate to 3.5
  ***/
  logic [0:0][3:0] B1;
  assign B1[0] = 4'b0111;

  ///////////////////////////////////////////////////////////
  /////////////////////// LOAD INPUTS ///////////////////////
  ///////////////////////////////////////////////////////////

  logic sync_x0, sync_y0, sync_start, sync_rst_n; 
  logic load_x0, load_x1, load_y0, load_y1, start, rst_n; 
  logic [1:0][3:0] coor; 

  // sync buttons
  always_ff @(posedge clk) begin
    {sync_x0, sync_y0} <= {btn[1], btn[0]};
    sync_start <= btn[2]; 
    sync_rst_n <= btn[3];

    {load_x0, load_y0} <= {sync_x0, sync_y0}; 
    start <= sync_start; 
    rst_n <= sync_rst_n; 
  end

  // set coordinates
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      coor <= '0; 
    end
    else begin
      if (load_x0) coor[0][3:0] <= in; 
      else if (load_y0) coor[1][3:0] <= in; 
    end
  end

  ///////////////////////////////////////////////////////////
  ///////////////////// CONTROLLER FSM //////////////////////
  ///////////////////////////////////////////////////////////
  logic start_mac0, start_mac1, sel_layer, store_layer0, store_layer1;
  logic done_mac0, done_mac1; 
  enum logic [2:0] {IDLE, LAYER0, LOAD0, LAYER1, LOAD1, DONE} state, nextState; 
  
  always_ff @(posedge clk) begin
    if (~rst_n) state <= IDLE;
    else state <= nextState; 
  end

  always_comb begin
    start_mac0 = 1'd0;
    start_mac1 = 1'd0;
    sel_layer = 1'd0; 
    store_layer0 = 1'd0;
    store_layer1 = 1'd0;
    valid = 1'd0; 
    case (state)
      IDLE: begin
        if (start) begin
          nextState = LAYER0;
          start_mac0 = 1'd1; 
        end
        else nextState = IDLE;
      end
      LAYER0: begin
        if (done_mac0) begin
          nextState = LOAD0;
          sel_layer = 1'd1; 
          store_layer0 = 1'd1;
        end
        else nextState = LAYER0;
      end
      LOAD0: begin
        nextState = LAYER1; 
        start_mac1 = 1'd1; 
      end
      LAYER1: begin
        if (done_mac1) begin
          nextState = LOAD1;
          store_layer1 = 1'd1;
        end
        else begin
          nextState = LAYER1;
          sel_layer = 1'd1; 
        end
      end
      LOAD1:  nextState = DONE; 
      DONE: begin
        nextState = DONE;
        valid = 1'd1; 
      end
      default: begin
        nextState = IDLE;
      end
    endcase
  end

  ///////////////////////////////////////////////////////////
  //////////////////////// INFERENCE ////////////////////////
  ///////////////////////////////////////////////////////////

  // store layer outputs
  logic [5:0][3:0] layer0_nodes, mac_out0, relu_out;
  logic [0:0][3:0] layer1_node, mac_out1;

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      layer0_nodes <= 'd0;
      layer1_node  <= 'd0;
    end
    else begin
      if      (store_layer0) layer0_nodes <= relu_out; 
      else if (store_layer1) layer1_node  <= mac_out1; 
    end
  end

  // result
  assign inside_circle = ~layer1_node[0][3];

  // actual math stuff
  mul phase0 (.W(W0), .B(B0), .in(coor), .clk, .rst_n, .start_mac(start_mac0),
              .mac_out(mac_out0), .done_mac(done_mac0));

  relu activation (.in(mac_out0), .out(relu_out));

  mul #(.MAT_ROWS(1), .MAT_COLS(6)) phase1 (.W(W1), .B(B1), .in(layer0_nodes),
                                            .clk, .rst_n, .start_mac(start_mac1),
                                            .mac_out(mac_out1), .done_mac(done_mac1));

endmodule: tiny_nn

// MAC unit
module mul
  #(parameter MAT_ROWS = 6,
    parameter MAT_COLS = 2)
  (input logic   [MAT_ROWS-1:0][MAT_COLS-1:0][3:0] W,
   input logic   [MAT_ROWS-1:0][3:0] B,
   input logic   [MAT_COLS-1:0][3:0] in, 
   input logic   clk, rst_n, start_mac, 
   output logic  [MAT_ROWS-1:0][3:0] mac_out,
   output logic  done_mac);

  logic overflow; 
  logic [MAT_ROWS-1:0][3:0] prod, prod_to_add; 
  logic [7:0]  temp_prod;       
  logic [3:0]  fixed_val_prod, temp_sum, fin_sum, fin_acc; 

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      prod_to_add <= 'd0;
      done_mac    <= 'd0; 
    end
    else begin
      prod_to_add <= prod;
      done_mac    <= start_mac; 
    end
  end

  always_comb begin
    for (int i = 0; i < MAT_ROWS; i++) begin
      temp_sum = '0;
      for (int j = 0; j < MAT_COLS; j++) begin
        temp_prod = {{4{W[i][j][3]}}, W[i][j]} * {{4{in[j][3]}}, in[j]};
        // mul overflow
        overflow = (temp_prod[7:5] != {3{temp_prod[7]}});
        if (overflow) begin
          fixed_val_prod = temp_prod[7] ? 4'sb1000 : 4'sb0111; 
        end
        else begin
          fixed_val_prod = temp_prod[5:2];
        end

        fin_sum = temp_sum + fixed_val_prod;
        // add overflow
        if (fin_sum[3] & !temp_sum[3] & !fixed_val_prod[3]) begin
          temp_sum = 4'sb0111;       
        end
        else if (!fin_sum[3] & temp_sum[3] & fixed_val_prod[3]) begin
          temp_sum = 4'sb1000;  
        end  
        else begin
          temp_sum = fin_sum;
        end
      end
      prod[i] = temp_sum;
    end

    // add bias
    for (int i = 0; i < MAT_ROWS; i++) begin
      fin_acc = prod_to_add[i] + B[i];
      // overflow again
      if (fin_acc[3] & !prod_to_add[i][3] & !B[i][3]) begin
        mac_out[i] = 4'sb0111;
      end
      else if (!fin_acc[3] & prod_to_add[i][3] & B[i][3]) begin
        mac_out[i] = 4'sb1000;
      end
      else begin
        mac_out[i] = fin_acc;
      end
    end 
  end

endmodule: mul


// ReLU activation function
module relu
  #(parameter MAT_ROWS = 6)
  (input  logic [MAT_ROWS-1:0][3:0] in, 
   output logic [MAT_ROWS-1:0][3:0] out);

  always_comb begin
    for (int i = 0; i < MAT_ROWS; i++)
      out[i] = in[i][3] ? 4'b0000 : in[i]; 
  end

endmodule: relu
