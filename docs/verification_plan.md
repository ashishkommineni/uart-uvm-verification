# Verification Plan

The UVM loopback test covers no parity, even parity, odd parity, random payloads, boundary patterns (`00`, `FF`, `55`, `AA`), transmitter busy/done behavior, receiver output, and error-free framing. A self-checking scoreboard matches every accepted TX frame with one RX frame. Coverage crosses payload class with parity mode. SVA checks start-to-busy response, one-cycle completion pulses, and known serial output.

The portable smoke test executes five frames through the real serial datapath. Error-injection hooks are intentionally left for a future negative-test extension; this limitation is stated rather than claiming unexecuted coverage.
