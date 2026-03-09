-- ===== Config =====
tickRate = 25
CAN_chan = 0
be_mode  = 1

OldBrake = 0.0
BrakeOverflow = 0
BrakeOverflow2 = 0

brakeId = addChannel("Brake", 25, 0, 0, 100, "%")

CAN_map = {
  [120] = function(a)
    map_chan(brakeId, a, 4, 2, 60, 65536.0, -36.272278)
  end
}

function onTick()
  processCAN(CAN_chan)
end

function processCAN(ch)
  while true do
    local id, ext, data = rxCAN(ch, 0)   -- non-blocking
    if id == nil then break end

    local f = CAN_map[id]
    if f ~= nil then
      f(data)
    end
  end
end

function map_chan_le(f, a, g, h, i, j, k)
  g = g + 1
  local l = 0
  local m = 1

  while h > 0 do
    l = l + a[g] * m
    m = m * 256
    g = g + 1
    h = h - 1
  end

  setChannel(f, l * i / j + k)
end

function map_chan_be(f, a, g, h, i, j, k)
  g = g + 1
  local l = 0
  local n = nil
  local o = 0.0

  while h > 0 do
    l = l * 256 + a[g]
    g = g + 1
    h = h - 1
  end

  if f == brakeId then
    o = l

    if o <= OldBrake - 30000 and BrakeOverflow == 1 then
      BrakeOverflow2 = 1
    elseif o <= OldBrake - 30000 then
      BrakeOverflow = 1
    elseif o >= OldBrake + 30000 and BrakeOverflow2 == 1 then
      BrakeOverflow2 = 0
    elseif o >= OldBrake + 30000 and BrakeOverflow == 1 then
      BrakeOverflow = 0
    end

    OldBrake = o

    if BrakeOverflow2 == 1 then
      l = o + 131070
    elseif BrakeOverflow == 1 then
      l = o + 65535
    else
      l = o
    end
  end

  n = l * i / j + k
  if n < 0 then n = 0 end
  setChannel(f, n)
end

map_chan = (be_mode == 1) and map_chan_be or map_chan_le

setTickRate(tickRate)
