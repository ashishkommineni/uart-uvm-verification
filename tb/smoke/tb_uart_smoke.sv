`timescale 1ns / 1ps
module tb_uart_smoke;
  localparam int DATA_BITS = 8, CLKS_PER_BIT = 8;
  logic
      clk,
      rst_n,
      parity_en,
      parity_odd,
      tx_start,
      tx_serial,
      tx_busy,
      tx_done,
      rx_serial,
      rx_valid,
      rx_parity_error,
      rx_frame_error;
  logic [DATA_BITS-1:0] tx_data, rx_data;
  int checks = 0;
  initial clk = 0;
  always #5 clk = ~clk;
  assign rx_serial = tx_serial;
  uart #(
      .DATA_BITS(DATA_BITS),
      .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (
      .*
  );
  uart_sva sva (
      .clk,
      .rst_n,
      .tx_start,
      .tx_busy,
      .tx_done,
      .tx_serial,
      .rx_valid,
      .rx_serial
  );
  task automatic send_check(input logic [7:0] data, input logic pen, input logic podd);
    while (tx_busy) @(posedge clk);
    @(negedge clk);
    tx_data = data;
    parity_en = pen;
    parity_odd = podd;
    tx_start = 1;
    @(negedge clk);
    tx_start = 0;
    @(posedge rx_valid);
    #1;
    if (rx_data !== data || rx_parity_error || rx_frame_error)
      $fatal(
          1,
          "UART mismatch tx=%02h rx=%02h pe=%0b fe=%0b",
          data,
          rx_data,
          rx_parity_error,
          rx_frame_error
      );
    checks++;
  endtask
  initial begin
    rst_n = 0;
    parity_en = 0;
    parity_odd = 0;
    tx_start = 0;
    tx_data = '0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    send_check(8'h00, 0, 0);
    send_check(8'h55, 1, 0);
    send_check(8'haa, 1, 1);
    send_check(8'hff, 0, 0);
    send_check(8'ha5, 1, 0);
    while (tx_busy) @(posedge clk);
    if ($isunknown(tx_done)) $fatal(1, "tx_done is unknown");
    $display("UART_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
