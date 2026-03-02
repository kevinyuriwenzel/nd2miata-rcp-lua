# nd2miata-rcp-lua
LUA scripts for Autosport Labs' racecapture series that work with the ND2 Miata (2016-2025)

This is a variant of the script linked to in this forum post:

https://forum.autosportlabs.com/viewtopic.php?p=30789#p30789

This revision replaces the original single-line Lua brake pressure decoder with a cleaner, non-blocking implementation and a standard 16-bit unwrap algorithm.

Goals of the update:

- Fix CAN2 instability/remove blocking behavior (OG script caused issues with TireX sensors running on CAN2)
- Simplify overflow handling
- Avoid unintended CAN reinitialization
- Improve readability and maintainability

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

### 3️⃣ Replaced Custom Overflow Logic With Standard 16-bit Unwrap

Before:

- Two overflow flags
- Threshold of ±30000
- Manual addition of 65535 / 131070
- Non-standard wrap math

After:

- Standard delta-based unwrap:
  - Compute delta = raw - previous
  - If delta > 32768 → subtract 65536
  - If delta < -32768 → add 65536
  - Accumulate continuous value

---

### 4️⃣ Cleaner Big-Endian Extraction

Before:

- Generic map_chan() system
- Indirect function dispatch
- Offset math embedded in mapper

After:

    local function u16_be(data, start0)
      local i = start0 + 1
      return data[i] * 256 + data[i + 1]
    end

Why:

- Explicit 16-bit big-endian extraction
- Easier to audit (IMHO)

