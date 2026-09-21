# UART Transmitter/Receiver Specification

## Frame format

The UART sends one start bit, `DATA_BITS` payload bits LSB first, optional parity, and one stop bit:

`idle(1) → start(0) → data[0] ... data[N-1] → optional parity → stop(1)`

`DATA_BITS` may be 5 through 9 and `CLKS_PER_BIT` must be at least four. The reference verification configuration uses eight data bits.

## Transmitter

A `tx_start` request is accepted only while `tx_busy=0`. The transmitter snapshots data and parity configuration, holds each serialized bit for `CLKS_PER_BIT` clocks, returns the line high for the stop bit, and pulses `tx_done` for one clock. Requests while busy are ignored.

## Receiver

The receiver detects a falling edge from idle, checks the start bit near its midpoint, and then samples each subsequent field once per bit period. On a complete frame it updates `rx_data` and pulses `rx_valid`. A parity mismatch sets `rx_parity_error`; a low sampled stop bit sets `rx_frame_error`.

For even parity, the parity bit makes the XOR of data plus parity zero. For odd parity, it makes that XOR one. `parity_odd` is meaningful only when parity is enabled; constrained-random traffic removes the redundant disabled/odd combination.

## Reset and boundaries

Active-low asynchronous reset returns TX to mark/idle and clears receiver status. The design intentionally omits fractional baud generation, synchronizer/metastability modeling, oversampling majority vote, multiple stop bits, hardware flow control, break detection, and buffering.
