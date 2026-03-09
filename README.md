# nd2miata-rcp-lua
LUA scripts for Autosport Labs' racecapture series that work with the ND2 Miata (2016-2025)

This is a variant of the LUA script contained in the RCP config linked to in this forum post:

https://forum.autosportlabs.com/viewtopic.php?p=30789#p30789

This revision replaces the original single-line Lua brake pressure decoder with a cleaner, non-blocking implementation and a standard 16-bit unwrap algorithm.

Goals of the update:

- Fix CAN2 instability/remove blocking behavior (OG script caused issues with TireX sensors running on CAN2)
- Avoid unintended CAN reinitialization

---

### 1️⃣ Non-Blocking CAN Reads

Before:
    rxCAN(b)

After:
    rxCAN(b, 0)

Why:

- Default rxCAN() can block up to ~100ms waiting for frames, this broke CAN2 when used with TireX sensors

The script now drains the CAN queue without ever waiting.

---

### 2️⃣ Removed initCAN() From Lua

Before:
    initCAN(CAN_chan, CAN_baud)

After:
    Removed entirely.

Why:

- CAN baud is configured in RaceCapture settings.

---


