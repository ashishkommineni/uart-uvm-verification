`timescale 1ns / 1ps
module uart_sva (
    input logic clk,
    rst_n,
    tx_start,
    tx_busy,
    tx_done,
    tx_serial,
    rx_valid,
    rx_serial
);
  default clocking cb @(posedge clk);
  endclocking
  default disable iff (!rst_n); ap_start_sets_busy :
  assert property ((tx_start && !tx_busy) |=> tx_busy);
  ap_done_single_cycle :
  assert property (tx_done |=> !tx_done);
  ap_tx_known :
  assert property (!$isunknown(tx_serial));
  ap_rx_valid_single_cycle :
  assert property (rx_valid |=> !rx_valid);
  cp_back_to_back :
  cover property (tx_done ##1 tx_start);
endmodule
