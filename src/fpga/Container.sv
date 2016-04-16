`include "Const.vh"

module Container(input logic clk, reset,
                 input logic [`PRED_WIDTH:0] src,
                 output logic done);

  enum logic [2:0] {RUN_BELLMAN, RUN_CYCLE_DETECT, DONE} state;
  logic bellman_done, cycle_done, bellman_reset, cycle_reset; //Reset and done registers
  
  //Memory
  /*Vertmat/Adjmat Read Outputs*/
  logic [`VERT_WIDTH:0] vertmat_q;
  logic [`WEIGHT_WIDTH:0] adjmat_q;
  /*VertMat Memory*/
  logic [`VERT_WIDTH:0] vertmat_data;
  logic [`PRED_WIDTH:0] vertmat_addr; //Both write
  logic vertmat_we;
  /*AdjMat Memory*/
  logic [`WEIGHT_WIDTH:0] adjmat_data;
  logic [`PRED_WIDTH:0] adjmat_row_addr; //Both write
  logic [`PRED_WIDTH:0] adjmat_col_addr; //Both write
  logic adjmat_we;
  /*Memory specific module vars*/
  logic [`PRED_WIDTH:0] bellman_vertmat_addr;
  logic [`PRED_WIDTH:0] bellman_adjmat_row_addr;
  logic [`PRED_WIDTH:0] bellman_adjmat_col_addr; 
  logic [`PRED_WIDTH:0] cycle_vertmat_addr;
  logic [`PRED_WIDTH:0] cycle_adjmat_row_addr;
  logic [`PRED_WIDTH:0] cycle_adjmat_col_addr; 
  
  assign vertmat_addr = bellman_done ? bellman_vertmat_addr : cycle_vertmat_addr;
  assign adjmat_row_addr = bellman_done ? bellman_adjmat_row_addr : cycle_adjmat_row_addr;
  assign admat_col_addr = bellman_done ? bellman_adjmat_col_addr : cycle_adjmat_col_addr;
  
  Bellman bellman(.vertmat_addr(bellman_vertmat_addr), .adjmat_row_addr(bellman_adjmat_row_addr), 
						.adjmat_col_addr(bellman_adjmat_col_addr), .*);
  CycleDetect cycle_detect(.vertmat_addr(cycle_vertmat_addr), .adjmat_row_addr(cycle_adjmat_row_addr), 
						.adjmat_col_addr(cycle_adjmat_col_addr), .*);
  VertMat vertmat(.data(vertmat_data), .addr(vertmat_addr), .we(vertmat_we), .q(vertmat_q), .*);
  AdjMat adjmat(.data(adjmat_data), .row_addr(adjmat_row_addr), .col_addr(adjmat_col_addr), 
						.we(adjmat_we), .q(adjmat_q), .*);

  always_ff @(posedge clk) begin
    if (reset) begin
      done <= 0;
      state <= RUN_BELLMAN;
      bellman_reset <= 1;
    end else case (state)
      RUN_BELLMAN: begin
        bellman_reset <= 0;
        if (bellman_done) begin
          cycle_reset <= 1;
          state <= RUN_CYCLE_DETECT;
        end
      end
      RUN_CYCLE_DETECT: begin
        cycle_reset <= 0;
        if (cycle_done) state <= DONE;
      end
      DONE: done <= 1;
      default: state <= DONE;
    endcase
  end

endmodule