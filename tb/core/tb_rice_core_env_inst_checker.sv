module tb_rice_core_env_inst_checker
  import  rice_core_pkg::*;
(
  input var                     i_clk,
  input var                     i_rst_n,
  rice_core_pipeline_if.monitor pipeline_if
);
  import  uvm_pkg::*;
  `include  "uvm_macros.svh"

  logic [31:0]  inst;
  always @(posedge i_clk) begin
    inst  <= pipeline_if.if_result.inst;
  end

  ast_valid_instruction:
  assert
    property (
      @(posedge i_clk) disable iff (!i_rst_n)
      pipeline_if.id_result.valid |->
        (pipeline_if.id_result.alu_operation.command != RICE_CORE_ALU_NONE) ||
        (pipeline_if.id_result.memory_access.access_type != RICE_CORE_MEMORY_ACCESS_NONE)
    )
  else
    `uvm_fatal("INVALID_INST", $sformatf("invalid instruction is given: %h", inst))
endmodule
