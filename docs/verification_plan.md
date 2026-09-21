# Verification Plan

## Strategy

The physical `tx_serial` output is looped into `rx_serial`, so every accepted transmit request must produce one decoded receive frame. The monitor records the accepted data/parity configuration and waits for `rx_valid`; the scoreboard compares payload and requires both error flags to remain clear.

| Goal | Stimulus | Check |
|---|---|---|
| No parity | Directed and weighted random frames | End-to-end payload comparison |
| Even parity | Directed `0x55` plus random data | No parity error; coverage mode bin |
| Odd parity | Directed `0xAA` plus random data | No parity error; coverage mode bin |
| Boundary patterns | `00`, `FF`, `55`, `AA` plus other bytes | Payload bins and payload × parity cross |
| TX control | Sequential requests around busy/done | Start-to-busy and single-cycle-done SVA |
| RX completion | Every loopback frame | One-cycle `rx_valid`, known serial lines |

## Constraints and coverage

When parity is disabled, `parity_odd` is constrained low so the random space has three meaningful modes: none, even, and odd. Data weighting emphasizes boundary/alternating bytes while preserving all other values. Coverage crosses payload class with parity mode.

## Honest limitation and closure

The current UVM topology proves correct error-free TX-to-RX operation; it does not corrupt the loopback wire to force parity and stop-bit errors. The RTL exposes and implements both error flags, but a pin-driving negative agent is a future extension and no negative-error coverage is claimed. Closure for the present scope requires zero UVM errors/fatals, passing SVA, all loopback bins, and the five-frame portable PASS token.
