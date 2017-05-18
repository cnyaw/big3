CLUB3 = 41
AITesting = false

function GenKindMoves(p, s, Set, n0, Moves) -- Gen moves of a kind.
  local m4 = {}
  for i = 1, p.n do
    local c = p[i].c
    if (not p[i].test and JOKER1 ~= c and JOKER2 ~= c and CompareNumber(GetCompareNumber(c), n0) and #p >= i + Set - 1) then
      local m = {}
      m[1] = i
      local jdx = 2
      for j = 2, Set do
        local idx = i + j - 1
        if (not p[idx].test and GetNumber(c) == GetNumber(p[idx].c)) then
          m[jdx] = idx
          jdx = jdx + 1
        end
      end
      if (#m == Set) then
        if (not AITesting) then
          table.insert(m4, 1 + #m4, m)
        end
        for j = 1,#m do
          p[m[j]].flag[Set] = true
        end
      end
    end
  end
  if (not AITesting) then
    SortPossibleMoves(p, m4)
    table.insert(Moves, Set, m4)
  end
end

function GenFlushMoves(p, s, n0, Moves)
  local m5 = {}
  SortCardsByFace(p)
  for i = 1, p.n - 2 do
    local c = p[i].c
    if (not p[i].test and JOKER1 ~= c and JOKER2 ~= c and CompareNumber(GetCompareNumber(c), n0)) then
      for j = i + 1, p.n do
        if (GetFace(c) ~= GetFace(p[j].c)) then
          break
        end
        if (1 ~= math.abs(c - p[j].c)) then
          break
        end
        if (3 <= j - i + 1) then
          local m = {}
          for k = i, j do
            m[k - i + 1] = p[k].i
            p[k].flag[5] = true
          end
          if (nil == s or (nil ~= LastSet and #m == #LastSet) and not AITesting) then -- Should have same length.
            table.insert(m5, 1 + #m5, m)
          end
        end
        if (Reverse) then
          c = c - 1
        else
          c = c + 1
        end
      end
    end
  end
  SortCardsByNumber(p)
  if (not AITesting) then
    SortPossibleMoves(p, m5)
    table.insert(Moves, 5, m5)
  end
end

function FilterFirstRoundMoves(p, Moves) -- Filter moves not contain club3.
  for i = 1, 5 do
    local pm = Moves[i]
    if (nil ~= pm) then
      local n = #pm
      for j = n, 1, -1 do
        local m = pm[j]
        local FoundClub3 = false
        for k = 1, #m do
          if (CLUB3 == p[m[k]].c) then
            FoundClub3 = true
            break
          end
        end
        if (not FoundClub3) then
          table.remove(pm, j)
        end
      end
    end
  end
end

function AddJokerMoves(p, s, n0, Moves, j1)
  -- Add moves of a kind.
  for i = 3,1,-1 do
    local pm = Moves[i]
    if (nil ~= pm) then
      local pm2 = Moves[i + 1]
      if (nil == pm2) then
        pm2 = {}
      end
      for j = 1, #pm do
        local m = pm[j]
        local nm = {}
        for k = 1, #m do
          nm[k] = m[k]
          p[m[k]].flag[i + 1] = true
        end
        if (not AITesting) then
          table.insert(nm, j1.i)
          table.insert(pm2, nm)
        end
      end
      SortPossibleMoves(p, pm2)
      Moves[i + 1] = pm2
    end
  end
  -- Add flush moves.
  local pm5 = Moves[5]
  if (nil ~= pm5) then
    for i = 1, #pm5 do
      local m = pm5[i]
      local nm = {}
      for j = 1, #m do
        nm[j] = m[j]
        p[m[j]].flag[5] = true
      end
      table.insert(nm, j1.i)
      if (nil == s or (nil ~= LastSet and #nm == #LastSet) and not AITesting) then -- Should have same length.
        table.insert(pm5, nm)
      end
    end
  else
    pm5 = {}
  end
  SortCardsByFace(p)
  for i = 1, p.n - 1 do
    local c = p[i].c
    local fc = GetFace(c)
    if (not p[i].test and JOKER1 ~= c and JOKER2 ~= c and CompareNumber(GetCompareNumber(c), n0) and fc == GetFace(p[i+1].c) and (1 == math.abs(c - p[i+1].c) or 2 == math.abs(c - p[i+1].c))) then
      local m
      if (1 == math.abs(c - p[i + 1].c)) then -- {n,n-1} type.
        m = {p[i].i, p[i + 1].i, j1.i}
      elseif (2 == math.abs(c - p[i + 1].c)) then -- {n,n-2} type.
        m = {p[i].i, j1.i, p[i + 1].i}
      end
      p[i].flag[5] = true
      p[i + 1].flag[5] = true
      if (nil == s or (nil ~= LastSet and #m == #LastSet) and not AITesting) then -- Should have same length.
        table.insert(pm5, m)
      end
      for j = i + 2, p.n do
        if (fc ~= GetFace(p[j].c) or (j - i + 1) ~= math.abs(c - p[j].c)) then
          break
        end
        local nm = {m[1], m[2], m[3]}
        for k = i + 2, j do
          nm[k - i + 2] = p[k].i
          p[k].flag[5] = true
        end
        if (nil == s or (nil ~= LastSet and #nm == #LastSet) and not AITesting) then -- Should have same length.
          table.insert(pm5, nm)
        end
      end
    end
  end
  SortCardsByNumber(p)
  if (not AITesting) then
    SortPossibleMoves(p, pm5)
    Moves[5] = pm5
  end
  -- Add new joker single moves.
  if (CompareNumber(GetCompareNumber(j1.c), n0)) then
    local pm = Moves[1]
    if (nil == pm) then
      pm = {}
    end
    if (not AITesting) then
      local nm = {j1.i}
      table.insert(pm, nm)
      SortPossibleMoves(p, pm)
      Moves[1] = pm
    end
  end
end

function GenJokerMoves(p, s, n0, Moves) -- Gen joker moves.
  local j2 = SearchCard(p, JOKER2)
  if (nil ~= j2) then
    AddJokerMoves(p, s, n0, Moves, j2)
  end
  local j1 = SearchCard(p, JOKER1)
  if (nil ~= j1) then
    AddJokerMoves(p, s, n0, Moves, j1)
  end
end

function GenPossibleMoves(p, s)         -- Gen possible moves.
  local n0 = 0
  if (Reverse) then
    n0 = 15
  end
  if (nil ~= s and nil ~= LastSet) then
    n0 = GetCompareNumber(LastSet[1].c)
  end
  for i = 1, p.n do                     -- Reset possible flag of each cards.
    p[i].flag = {}
    for j = 1, 5 do
      p[i].flag[j] = false
    end
  end
  local Moves = {}
  for i = 1, 4 do
    GenKindMoves(p, s, i, n0, Moves)    -- Single, one pair, three of a kind, four of a kind.
  end
  GenFlushMoves(p, s, n0, Moves)        -- Straight flush.
  if (FirstRound) then
    FilterFirstRoundMoves(p, Moves)     -- Filter moves that not contain club3 in first round.
  end
  GenJokerMoves(p, s, n0, Moves)        -- Gen wildcard joker moves.
  if (FirstRound) then
    FilterFirstRoundMoves(p, Moves)     -- Filter again.
  end
  if (nil ~= s) then                    -- Filter invalid sets.
    for i = 1, 5 do
      if (i ~= s) then
        Moves[i] = nil
      end
    end
  end
  return Moves
end
