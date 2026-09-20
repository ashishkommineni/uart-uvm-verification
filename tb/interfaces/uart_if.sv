`timescale 1ns / 1ps
interface uart_if #(
    parameter int DATA_BITS = 8
) (
    input logic clk
);
  logic rst_n, parity_en, parity_odd;
  logic tx_start;
  logic [DATA_BITS-1:0] tx_data;
  logic tx_serial, tx_busy, tx_done;
  logic rx_serial;
  logic [DATA_BITS-1:0] rx_data;
  logic rx_valid, rx_parity_error, rx_frame_error;
  clocking drv_cb @(negedge clk);
    output parity_en, parity_odd, tx_start, tx_data;
    input tx_busy, tx_done, rx_data, rx_valid, rx_parity_error, rx_frame_error;
  endclocking
endinterface
