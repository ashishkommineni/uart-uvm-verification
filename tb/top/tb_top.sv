`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import uart_uvm_pkg::*;
  logic clk = 0;
  always #5ns clk = ~clk;
  uart_if #(DATA_BITS) vif (clk);
  assign vif.rx_serial = vif.tx_serial;
  uart #(
      .DATA_BITS(DATA_BITS),
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (
      .clk,
      .rst_n(vif.rst_n),
      .parity_en(vif.parity_en),
      .parity_odd(vif.parity_odd),
      .tx_start(vif.tx_start),
      .tx_data(vif.tx_data),
      .tx_serial(vif.tx_serial),
      .tx_busy(vif.tx_busy),
      .tx_done(vif.tx_done),
      .rx_serial(vif.rx_serial),
      .rx_data(vif.rx_data),
      .rx_valid(vif.rx_valid),
      .rx_parity_error(vif.rx_parity_error),
      .rx_frame_error(vif.rx_frame_error)
  );
  uart_sva sva (
      .clk,
      .rst_n(vif.rst_n),
      .tx_start(vif.tx_start),
      .tx_busy(vif.tx_busy),
      .tx_done(vif.tx_done),
      .tx_serial(vif.tx_serial),
      .rx_valid(vif.rx_valid),
      .rx_serial(vif.rx_serial)
  );
  initial begin
    vif.rst_n = 0;
    vif.tx_start = 0;
    vif.tx_data = '0;
    vif.parity_en = 0;
    vif.parity_odd = 0;
    repeat (5) @(posedge clk);
    vif.rst_n = 1;
  end
  initial begin
    uvm_config_db#(virtual uart_if #(DATA_BITS))::set(null, "uvm_test_top.env.agent.*", "vif", vif);
    run_test("uart_test");
  end
endmodule
