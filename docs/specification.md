# UART Specification

This project implements a full-duplex RTL UART with independent transmitter and receiver, 5–9 configurable data bits at elaboration, one start bit, optional even/odd parity, and one stop bit. `CLKS_PER_BIT` derives baud timing from `clk`.

Frames are sent LSB first. `tx_start` is accepted only while `tx_busy=0`. `tx_done` and `rx_valid` are one-cycle pulses. The receiver samples the start bit near its midpoint and then samples each data/parity/stop bit once per programmed bit period. It reports parity and framing errors with the corresponding `rx_valid` pulse.
