// Code your design here
module RangeFinder
  #(parameter WIDTH=16)
  (input  logic [WIDTH-1:0]  data_in,
    input  logic             clock, reset_n,
    input  logic             go, finish,
    output logic [WIDTH-1:0] range,
    output logic             error);

  logic enable, clear, prev_go, pedge_go; 
  logic [WIDTH-1:0] curr_min, curr_max, imm_min, imm_max, curr_range; 
  enum logic [1:0] {IDLE, VALID, ERR} state, nextState;

  // store prev go for edge detection, delay range by 1 clk
  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) begin 
      prev_go <= 'd0; 
      range <= 'd0; 
    end
    else begin 
      prev_go <= go; 
      range <= curr_range;
    end
  end

  assign pedge_go = ~prev_go & go; 

  // next state update logic
  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) state <= IDLE;
    else       state <= nextState; 
  end

  // next state logic
  always_comb begin
    case (state) 
      IDLE: begin
        if (finish)        nextState = ERR; 
        else if (pedge_go) nextState = VALID; 
        else               nextState = IDLE; 
      end
      VALID: begin
        if (finish)        nextState = IDLE; 
        else if (pedge_go) nextState = ERR; 
        else               nextState = VALID; 
      end
      ERR: nextState = (pedge_go & ~finish) ? VALID : ERR; 
      default: nextState = IDLE;
    endcase
  end

  // output logic
  always_comb begin
    case (state) 
      IDLE: begin
        if (finish)        {enable, error, clear} = 3'b011; 
        else if (pedge_go) {enable, error, clear} = 3'b100; 
        else               {enable, error, clear} = 3'b000; 
      end
      VALID: begin
        if (finish)        {enable, error, clear} = 3'b001; 
        else if (pedge_go) {enable, error, clear} = 3'b011; 
        else               {enable, error, clear} = 3'b100;
      end
      ERR: begin
        if (pedge_go & ~finish) {enable, error, clear} = 3'b110; 
        else                    {enable, error, clear} = 3'b010; 
      end
      default: {enable, error, clear} = 3'd0;
    endcase
  end

  // running min and max
  always_ff @(posedge clock, negedge reset_n) begin
    if (~reset_n) begin
      curr_min <= {WIDTH{1'b1}};
      curr_max <= 'd0; 
    end
    else if (clear) begin
      curr_min <= {WIDTH{1'b1}};
      curr_max <= 'd0; 
    end
    else if (enable) begin
      curr_min <= imm_min; 
      curr_max <= imm_max; 
    end
    else begin
      curr_min <= {WIDTH{1'b1}};
      curr_max <= 'd0; 
    end
  end

  // calc final result
  always_comb begin
    imm_min = (data_in < curr_min) ?  data_in : curr_min; 
    imm_max = (data_in > curr_max) ?  data_in : curr_max; 
    curr_range = imm_max - imm_min; 
  end
   

endmodule: RangeFinder