# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings |
| Executable serial + SVA smoke | PASS | `UART_SMOKE_PASS checks=5` |
| Parameter elaboration | PASS | Both 5-data-bit/4-clock and 9-data-bit/16-clock variants passed strict lint |
| UVM source compile/elaboration | PASS | RTL, interface, SVA, UVM package, and top compiled with Accellera UVM `78c0654` |

```text
UART_SMOKE_PASS checks=5
```

Five complete serialized frames pass through TX and RX with parity disabled, even parity, and odd parity. Payload checks include `00`, `55`, `AA`, `FF`, and `A5`; every frame requires exact data, no parity error, and no framing error. Runtime SVA checks busy/done/valid pulse behavior, idle-high TX, and known TX/RX lines.

## Second-pass findings corrected

- Meaningful parity-mode and weighted payload constraints were added.
- A redundant disabled-parity state was removed from the random space.
- Scoreboard no-traffic and shell `pipefail` guards were retained and validated.
- README wording was corrected from “parallel” to sequenced requests.

The present test scope does not inject a bad parity or stop bit; that limitation is documented in the verification plan and no negative-error coverage is claimed.

## Xcelium boundary

No Xcelium runtime or functional-coverage percentage is claimed here. Full UVM source elaboration passed. A licensed regression must produce zero UVM errors/fatals, passing SVA, and planned error-free loopback coverage.
