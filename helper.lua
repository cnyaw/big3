Reverse = false                         -- Every time a four of a kind is played, toggle reverse flag.
ReverseFlag = nil
JOKER1, JOKER2 = 52, 53

Blink = {}

Blink.OnStep = function(param)
  if (nil == param.step) then
    param.step = 0
    param.flag = true
    Good.SetAnchor(param._id, 0.5, 0.5)
  end
  param.step = param.step + 1
  if (80 <= param.step) then
    if (80 == param.step) then
      if (not Reverse) then
        ReverseFlag = Good.GenObj(-1, 11)
        Good.SetBgColor(ReverseFlag, 0x30ffffff)
        local x,y,w,h = Good.GetDim(ReverseFlag)
        Good.SetPos(ReverseFlag, (W - w)/2, (H - h)/2)
      elseif (nil ~= ReverseFlag) then
        Good.KillObj(ReverseFlag)
      end
    end
    Good.SetBgColor(param._id, 0xffff0000)
    local s = 1.0 + (param.step - 80) / 1.4
    Good.SetScale(param._id, s, s)
    local alpha = (255 - (param.step - 80) * 8)
    if (0 > alpha) then
      alpha = 0
    end
    Good.SetBgColor(param._id, 0xff0000 + alpha * 0x1000000)
  else
    if (0 == math.mod(param.step, 5)) then
      param.flag = not param.flag
      if (param.flag) then
        Good.SetBgColor(param._id, 0xff000000)
      else
        Good.SetBgColor(param._id, 0xffff0000)
      end
    end
  end
end

GrayOut = {}

GrayOut.OnStep = function(param)
  if (nil == param.step) then
    param.step = 255 + 180
  end
  param.step = param.step - 10
  if (0 >= param.step) then
    Good.KillObj(param._id)
  elseif (255 >= param.step) then
    Good.SetBgColor(param._id, 0xffffff + param.step * 0x1000000)
  end
end

function RandShuffle(a, len)
  for i = 1, len do
    local r = math.random(i + 1) - 1
    local n = a[r]
    a[r] = a[i]
    a[i] = n
  end
end

function SwapCards(p, j)
  local tmp = p[j]
  p[j] = p[j + 1]
  p[j + 1] = tmp
end

function SearchCard(p, c)
  for i = 1, #p do
    if (p[i].c == c) then
      return p[i]
    end
  end
  return nil
end

function CompareNumber(n1, n2)
  if (Reverse) then
    return n2 > n1
  else
    return n1 > n2
  end
end

function SortCardsByNumber(p)           -- Sort by number then face.
  for i = 1, p.n do
    for j = 1, p.n - i do
      local c1, c2 = p[j].c, p[j + 1].c
      local f1, f2 = GetFace(c1), GetFace(c2)
      local n1, n2 = GetCompareNumber(c1), GetCompareNumber(c2)
      if ((p[j].test and not p[j + 1].test) or (n1 == n2 and f1 < f2) or CompareNumber(n1, n2)) then
        SwapCards(p, j)
      end
    end
  end
end

function SortCardsByFace(p)             -- Sort by face then number.
  for i = 1, p.n do
    for j = 1, p.n - i do
      local c1, c2 = p[j].c, p[j + 1].c
      local f1, f2 = GetFace(c1), GetFace(c2)
      local n1, n2 = GetCompareNumber(c1), GetCompareNumber(c2)
      if ((p[j].test and not p[j + 1].test) or (f1 == f2 and CompareNumber(n1, n2)) or (f1 > f2)) then
        SwapCards(p, j)
      end
    end
  end
end

function SortPossibleMoves(p, pm)
  for i = 1, #pm do
    for j = 1, #pm - i do
      local n1, n2 = GetCompareNumber(p[pm[j][1]].c), GetCompareNumber(p[pm[j + 1][1]].c)
      if (CompareNumber(n1, n2)) then
        SwapCards(pm, j)
      end
    end
  end
end

function SortMoves(p, pm)
  for i = 1, #pm do
    for j = 1, #pm - i do
      local n1, n2 = GetCompareNumber(p[pm[j]].c), GetCompareNumber(p[pm[j + 1]].c)
      if (CompareNumber(n1, n2)) then
        SwapCards(pm, j)
      end
    end
  end
end

function GetNumber(c)
  if (JOKER1 == c or JOKER2 == c) then
    if (Reverse) then
      return -1
    else
      return 13
    end
  else
    return c % 13
  end
end

function GetCompareNumber(c)
  local n = GetNumber(c)
  if (0 == n) then                      -- A.
    return 13
  elseif (1 == n) then                  -- 2.
    return 14
  elseif (JOKER1 == c or JOKER2 == c) then -- Joker.
    if (Reverse) then
      return -1
    else
      return 15
    end
  else
    return n
  end
end

function GetFace(c)
  if (JOKER1 == c) then
    return 0
  elseif (JOKER2 == c) then
    return 1
  else
    return math.floor(c / 13)
  end
end

function AdjustStrObj(o)
  for i = 1, Good.GetChildCount(o) - 1 do
    local c = Good.GetChild(o, i)
    local x,y = Good.GetPos(c)
    Good.SetPos(c, i * 12, y)
  end
  Good.SetScale(o, 0.8, 0.8)
end
