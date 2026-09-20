`timescale 1ns / 1ps

module uart #(
    parameter int unsigned DATA_BITS    = 8,
    parameter int unsigned CLKS_PER_BIT = 16,
    localparam int unsigned CLK_CNT_W   = $clog2(CLKS_PER_BIT),
    localparam int unsigned BIT_CNT_W   = $clog2(DATA_BITS)
) (
    input logic clk,
    input logic rst_n,
    input logic parity_en,
    input logic parity_odd,

    input  logic                 tx_start,
    input  logic [DATA_BITS-1:0] tx_data,
    output logic                 tx_serial,
    output logic                 tx_busy,
    output logic                 tx_done,

    input  logic                 rx_serial,
    output logic [DATA_BITS-1:0] rx_data,
    output logic                 rx_valid,
    output logic                 rx_parity_error,
    output logic                 rx_frame_error
);

  initial begin
    if (DATA_BITS < 5 || DATA_BITS > 9) $fatal(1, "DATA_BITS must be 5..9");
    if (CLKS_PER_BIT < 4) $fatal(1, "CLKS_PER_BIT must be at least 4");
  end

  localparam logic [CLK_CNT_W-1:0] LAST_CLK = CLK_CNT_W'(CLKS_PER_BIT - 1);
  localparam logic [CLK_CNT_W-1:0] HALF_CLK = CLK_CNT_W'((CLKS_PER_BIT / 2) - 1);
  localparam logic [BIT_CNT_W-1:0] LAST_BIT = BIT_CNT_W'(DATA_BITS - 1);

  typedef enum logic [2:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_PARITY,
    TX_STOP
  } tx_state_t;
  typedef enum logic [2:0] {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_PARITY,
    RX_STOP
  } rx_state_t;

  tx_state_t tx_state_q;
  rx_state_t rx_state_q;
  logic [CLK_CNT_W-1:0] tx_clk_count_q, rx_clk_count_q;
  logic [BIT_CNT_W-1:0] tx_bit_index_q, rx_bit_index_q;
  logic [DATA_BITS-1:0] tx_shift_q, rx_shift_q;
  logic tx_parity_q, tx_parity_en_q;
  logic rx_parity_en_q, rx_parity_odd_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state_q     <= TX_IDLE;
      tx_clk_count_q <= '0;
      tx_bit_index_q <= '0;
      tx_shift_q     <= '0;
      tx_parity_q    <= 1'b0;
      tx_parity_en_q <= 1'b0;
      tx_serial      <= 1'b1;
      tx_busy        <= 1'b0;
      tx_done        <= 1'b0;
    end else begin
      tx_done <= 1'b0;
      case (tx_state_q)
        TX_IDLE: begin
          tx_serial <= 1'b1;
          tx_busy <= 1'b0;
          tx_clk_count_q <= '0;
          if (tx_start) begin
            tx_shift_q     <= tx_data;
            tx_parity_q    <= (^tx_data) ^ parity_odd;
            tx_parity_en_q <= parity_en;
            tx_bit_index_q <= '0;
            tx_serial      <= 1'b0;
            tx_busy        <= 1'b1;
            tx_state_q     <= TX_START;
          end
        end

        TX_START: begin
          if (tx_clk_count_q == LAST_CLK) begin
            tx_clk_count_q <= '0;
            tx_serial      <= tx_shift_q[0];
            tx_state_q     <= TX_DATA;
          end else tx_clk_count_q <= tx_clk_count_q + 1'b1;
        end

        TX_DATA: begin
          if (tx_clk_count_q == LAST_CLK) begin
            tx_clk_count_q <= '0;
            if (tx_bit_index_q == LAST_BIT) begin
              tx_serial  <= tx_parity_en_q ? tx_parity_q : 1'b1;
              tx_state_q <= tx_parity_en_q ? TX_PARITY : TX_STOP;
            end else begin
              tx_bit_index_q <= tx_bit_index_q + 1'b1;
              tx_shift_q     <= tx_shift_q >> 1;
              tx_serial      <= tx_shift_q[1];
            end
          end else tx_clk_count_q <= tx_clk_count_q + 1'b1;
        end

        TX_PARITY: begin
          if (tx_clk_count_q == LAST_CLK) begin
            tx_clk_count_q <= '0;
            tx_serial      <= 1'b1;
            tx_state_q     <= TX_STOP;
          end else tx_clk_count_q <= tx_clk_count_q + 1'b1;
        end

        TX_STOP: begin
          if (tx_clk_count_q == LAST_CLK) begin
            tx_clk_count_q <= '0;
            tx_serial      <= 1'b1;
            tx_busy        <= 1'b0;
            tx_done        <= 1'b1;
            tx_state_q     <= TX_IDLE;
          end else tx_clk_count_q <= tx_clk_count_q + 1'b1;
        end

        default: tx_state_q <= TX_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state_q      <= RX_IDLE;
      rx_clk_count_q  <= '0;
      rx_bit_index_q  <= '0;
      rx_shift_q      <= '0;
      rx_parity_en_q  <= 1'b0;
      rx_parity_odd_q <= 1'b0;
      rx_data         <= '0;
      rx_valid        <= 1'b0;
      rx_parity_error <= 1'b0;
      rx_frame_error  <= 1'b0;
    end else begin
      rx_valid <= 1'b0;
      case (rx_state_q)
        RX_IDLE: begin
          rx_clk_count_q <= '0;
          rx_bit_index_q <= '0;
          if (!rx_serial) begin
            rx_parity_en_q  <= parity_en;
            rx_parity_odd_q <= parity_odd;
            rx_parity_error <= 1'b0;
            rx_frame_error  <= 1'b0;
            rx_state_q      <= RX_START;
          end
        end

        RX_START: begin
          if (rx_clk_count_q == HALF_CLK) begin
            rx_clk_count_q <= '0;
            if (!rx_serial) rx_state_q <= RX_DATA;
            else rx_state_q <= RX_IDLE;
          end else rx_clk_count_q <= rx_clk_count_q + 1'b1;
        end

        RX_DATA: begin
          if (rx_clk_count_q == LAST_CLK) begin
            rx_clk_count_q <= '0;
            rx_shift_q[rx_bit_index_q] <= rx_serial;
            if (rx_bit_index_q == LAST_BIT) begin
              rx_state_q <= rx_parity_en_q ? RX_PARITY : RX_STOP;
            end else rx_bit_index_q <= rx_bit_index_q + 1'b1;
          end else rx_clk_count_q <= rx_clk_count_q + 1'b1;
        end

        RX_PARITY: begin
          if (rx_clk_count_q == LAST_CLK) begin
            rx_clk_count_q  <= '0;
            rx_parity_error <= (rx_serial != ((^rx_shift_q) ^ rx_parity_odd_q));
            rx_state_q      <= RX_STOP;
          end else rx_clk_count_q <= rx_clk_count_q + 1'b1;
        end

        RX_STOP: begin
          if (rx_clk_count_q == LAST_CLK) begin
            rx_clk_count_q <= '0;
            rx_data        <= rx_shift_q;
            rx_frame_error <= !rx_serial;
            rx_valid       <= 1'b1;
            rx_state_q     <= RX_IDLE;
          end else rx_clk_count_q <= rx_clk_count_q + 1'b1;
        end

        default: rx_state_q <= RX_IDLE;
      endcase
    end
  end
endmodule
