# UART RTL and UVM Verification

A synthesizable UART transmitter/receiver supporting optional even or odd parity, verified end-to-end with a UVM loopback environment, SVA, coverage, and an executable Verilator smoke test.

## Frame

```text
idle(1) → start(0) → data[0] ... data[N-1] → optional parity → stop(1)
```

The transmitter serializes LSB first. The receiver validates the start bit at its midpoint and samples subsequent fields once per `CLKS_PER_BIT`. See [the specification](docs/specification.md).

## Verification architecture

The UVM driver launches sequenced TX requests. The physical `tx_serial` output loops back into `rx_serial`; the monitor pairs each accepted request with `rx_valid`, and the scoreboard checks payload plus parity/framing status. Coverage crosses data patterns with parity mode.

## Run

```bash
make uvm       # Cadence Xcelium + UVM
make regress   # five randomized seeds
make lint      # Verilator lint
make smoke     # executable serial loopback
```

Passing portable execution includes live SVA and prints:

```text
UART_SMOKE_PASS checks=5
```

The Xcelium report should finish with `UVM_ERROR : 0`, `UVM_FATAL : 0`, and a `UART_SUMMARY` line. The detailed goals and current negative-test limitation are recorded in [the verification plan](docs/verification_plan.md).

See [verified results and tool scope](docs/verification_results.md) for the reproducible validation record.

## License

MIT — see [LICENSE](LICENSE).
