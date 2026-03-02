-- ===== Config =====
tickRate  = 25
CAN_chan  = 0          -- listen on CAN1 / channel 0
be_mode   = 1          -- kept for compatibility; we decode BE explicitly below

-- Virtual channel
brakeId = addChannel("Brake", 25, 0, 0, 100, "%")

-- ===== Helpers =====

-- Read unsigned 16-bit big-endian from RaceCapture data array
-- start0 is a 0-based byte offset (so start0=4 means bytes 5 and 6 in Lua's 1-based array)
local function u16_be(data, start0)
  local i = start0 + 1
  return data[i] * 256 + data[i + 1]
end

-- Standard unwrap for a wrapping 16-bit counter/value.
-- Keeps a continuous (unbounded) integer by adding the "smallest" delta each sample.
local brake_prev_raw = nil
local brake_unwrapped = 0

local function unwrap_u16(raw)
  if brake_prev_raw == nil then
    brake_prev_raw = raw
    brake_unwrapped = raw
    return brake_unwrapped
  end

  local delta = raw - brake_prev_raw

  -- Choose the shortest path across the 16-bit wrap boundary.
  if delta > 32768 then
    delta = delta - 65536
  elseif delta < -32768 then
    delta = delta + 65536
  end

  brake_unwrapped = brake_unwrapped + delta
  brake_prev_raw = raw
  return brake_unwrapped
end

-- Apply scale/offset and clamp
local function set_brake_from_raw(raw_unwrapped)
  -- same scaling as your original:
  -- n = l * 60 / 65536 + (-36.272278)
  local n = (raw_unwrapped * 60.0 / 65536.0) - 36.272278
  if n < 0 then n = 0 end
  setChannel(brakeId, n)
end

-- ===== CAN map =====
CAN_map = {
  [120] = function(data)
    local raw16 = u16_be(data, 4)         -- same field as original map_chan(..., 4, 2, ...)
    local raw_unwrapped = unwrap_u16(raw16)
    set_brake_from_raw(raw_unwrapped)
  end
}

-- ===== Main loop =====
function processCAN(ch)
  while true do
    local id, ext, data = rxCAN(ch, 0)    -- non-blocking
    if id == nil then break end
    local f = CAN_map[id]
    if f ~= nil then f(data) end
  end
end

function onTick()
  processCAN(CAN_chan)
end

setTickRate(tickRate)