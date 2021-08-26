math.randomseed(os.time())

W,H = Good.GetWindowSize()
local CX_CARD, CY_CARD = 73, 99
local SELOFFSET = 20

local OFFSET_CLEAR = {0, -H/2 + 25, -W/2 + 50, 0, 0, H/2 - 25, W/2 - 50, 0}
local OFFSET_PASS = {0, -110, -230, 0, 0, 60, 205, 0}
local OFFSET_INDICATOR = {0, -90, -210, 0, 0, 60, 205, 0}
local OFFSET_SCORE = {0, -90, -210, 0, 0, 60, 195, 0}
local OFFSET_RANKING = {0, -150, -250, 0, 0, 150, 240, 0}

local DebugMode = false                 -- Show NPC's cards.

local Round                             -- Start from who has club 3.
local AIDelay
local CurrPlayer
LastSet = nil

local PassCount
local SetPanel
local ClearCount
local RoundMsg

local PossibleMoves                     -- Possible moves of current player.
local SelSet                            -- Current selected type of card set.
local SelIndex                          -- Current selected index of card set.

FirstRound = false

local btnGo, btnPass
local msgReverse = nil

local Players = {}                      -- Cards for 4 players.
local PossibleCards = {}                -- Possible cards of NPC that not play.

local MsgBox = nil

function InitDealCards()
  -- Deal cards to 4 players.
  local Cards = GetInitCards()
  for i = 0, 3 do
    local pc = {}
    pc.n = 0
    Players[i] = pc
  end
  for i = 0, 53 do
    local pc = Players[math.mod(i, 4)]
    pc.n = pc.n + 1
    local c = Cards[i]
    pc[pc.n] = c
    local n = 1 + GetCompareNumber(c)
    PossibleCards[n] = PossibleCards[n] + 1
  end
end

function GenInitCardsObj()
  Round = nil
  for p = 0, 3 do                       -- Gen cards obj.
    local pc = Players[p]
    pc.p = p
    for i = 1, pc.n do
      local c = pc[i]
      if (CLUB3 == c) then
        Round = p
      end
      local o = Good.GenObj(-1, 0)
      local param = Good.GetParam(o)
      param.c = c
      param.i = i
      param.o = o
      param.test = false
      pc[i] = param
      Good.SetDim(o, CX_CARD * GetNumber(c), CY_CARD * GetFace(c), CX_CARD, CY_CARD)
    end
    SortCardsByNumber(pc)
    ArrangeCards(pc)
  end
end

function InitPlayerSelAi()
  if (0 ~= TotalRound) then
    -- Round mode.
    for i = 0, 3 do
      if (2 ~= i) then
        Players[i].AISel = math.random(2)
      end
    end
  elseif (RandAI) then
    -- Practice with 3 NPC.
    local AI = {}
    for i = 0, 2 do
      AI[i] = i
    end
    RandShuffle(AI, 2)
    Players[0].AISel = AI[0]
    Players[1].AISel = AI[1]
    Players[3].AISel = AI[2]
  else
    -- Practice with one NPC.
    for i = 0, 3 do
      Players[i].AISel = AISel
    end
  end
end

function InitCards()
  PossibleCards = {}                    -- Init possible cards of NPC.
  for i = 0,16 do
    PossibleCards[i] = 0
  end
  InitDealCards()
  InitPlayerSelAi()
  GenInitCardsObj()
end

function GetCardPos(p, i)
  local x, y
  if (0 == p) then                      -- Top player.
    local OFFSET_X = 15
    local CW = (W - (8 * OFFSET_X + CX_CARD))/2 + 40
    x = CW + OFFSET_X * (8 - i - 1)
    y = 5
  elseif (1 == p) then                  -- Left player.
    local OFFSET_Y = 15
    local CH = (H - (8 * OFFSET_Y + CX_CARD))/2 - 25
    x = 14
    y = CH/3 + OFFSET_Y * (i - 1)
  elseif (2 == p) then                  -- Bottom player.
    local OFFSET_X = 25
    local CW = (W - (12 * OFFSET_X + CX_CARD))/2
    x = CW + OFFSET_X * (i - 1)
    y = H - CY_CARD - 5
  elseif (3 == p) then                  -- Right player.
    local OFFSET_Y = 15
    local CH = (H - (8 * OFFSET_Y + CX_CARD))/2
    x = W - 70
    y = CH + OFFSET_Y * (8 - i - 1)
  end
  return x, y
end

function ArrangeCards(pc)
  local p = pc.p
  for i = 1, pc.n do
    pc[i].i = i
    local c = pc[i].c
    local ox = CX_CARD * GetNumber(c)
    local oy = CY_CARD * GetFace(c)
    local o = pc[i].o
    Good.AddChild(-1, o)                -- Re-zorder.
    local x, y = GetCardPos(p, i)
    Good.SetPos(o, x, y)
    if (1 == p) then                    -- Left player.
      Good.SetAnchor(o, 0.5, 0.5)
      Good.SetRot(o, 90)
    elseif (3 == p) then                -- Right player.
      Good.SetAnchor(o, 0.5, 0.5)
      Good.SetRot(o, 270)
    end
    if (2 ~= p) then                    -- Bottom player.
      if (DebugMode) then
        Good.SetTexId(o, 0)
        Good.SetDim(o, CX_CARD * GetNumber(c), CY_CARD * GetFace(c), CX_CARD, CY_CARD)
      else
        Good.SetTexId(o, 32)
        Good.SetDim(o, 0, 0, 0, 0)
      end
    end
  end
end

function GetCardsScore(Total, p, pc)
  local Score = 0
  local Cards = 0
  for i = 1,#p do
    local pi = p[i]
    if (not pi.test) then
      local n = 1 + GetCompareNumber(pi.c)
      local N = 0
      if (Reverse) then
        for j = 0,n - 1 do
          N = N + pc[j]
        end
      else
        for j = n + 1,#pc do
          N = N + pc[j]
        end
      end
      local s = N / Total
      if (pi.flag[2]) then            -- Pair.
        s = s / 2
      end
      if (pi.flag[3]) then            -- Three of a kind.
        s = s / 3
      end
      if (pi.flag[4]) then            -- Four of a kind.
        s = s / 4
      end
      if (pi.flag[5]) then            -- Flush.
        s = s / 3.5
      end
      if (0.06 < s) then
        Cards = Cards + 1
      end
      Score = Score + s
    end
  end
  return Score, Cards
end

function GetScore(p)
  local pc = {}
  for i = 0,#PossibleCards do           -- Copy possible cards.
    pc[i] = PossibleCards[i]
  end
  for i = 1,p.n do                      -- Exclude self cards.
    if (not p[i].test) then
      local n = 1 + GetCompareNumber(p[i].c)
      pc[n] = pc[n] - 1
    end
  end
  local Total = 0                       -- Count total possible cards.
  for i = 0,#pc do
    Total = Total + pc[i]
  end
  return GetCardsScore(Total, p, pc)
end

function TmpReverseGetScore(p, TmpRev)
  if (TmpRev) then
    Reverse = not Reverse
  end
  local s,c = GetScore(p)
  if (TmpRev) then
    Reverse = not Reverse
  end
  return s,c
end

function ResetCardsPos(p)
  for i = 1, p.n do
    local param = p[i]
    local o = p[i].o
    if (nil ~= param.sel) then
      local x, y = Good.GetPos(o)
      Good.SetPos(o, x, y + SELOFFSET)
      param.sel = nil
    end
  end
end

function ToggleSelCard(p)
  local o = p.o
  local x,y = Good.GetPos(o)
  if (nil == p.sel) then
    p.sel = 1
    Good.SetPos(o, x, y - SELOFFSET)
  else
    p.sel = nil
    Good.SetPos(o, x, y + SELOFFSET)
  end
end

function SetCurrPlayerIndicator()
  if (nil ~= CurrPlayer) then
    Good.KillObj(CurrPlayer)
  end
  local r = math.mod(Round, 4)
  if (0 >= Players[r].n) then
    return
  end
  CurrPlayer = GenTexObj(-1, 8, 35, 29, 0, 0)
  local a = {90, 0, 270, 180}
  Good.SetAnchor(CurrPlayer, 0.5, 0.5)
  Good.SetRot(CurrPlayer, a[r + 1])
  Good.SetPos(CurrPlayer, (W - 35)/2 + OFFSET_INDICATOR[2 * r + 1], (H - 29)/2 + OFFSET_INDICATOR[2 * r + 2])
end

function NextRound()
  Round = Round + 1
  SetCurrPlayerIndicator()
  local r = math.mod(Round, 4)
  local pc = Players[r]
  if (2 == r) then
    MyRound()
  elseif (0 < pc.n) then
    AIDelay = 30
  end
end

function MyRound()
  local pc = Players[2]
  if (FirstRound or 3 <= Good.GetChildCount(PassCount)) then
    PossibleMoves = GenPossibleMoves(pc)
  else
    PossibleMoves = GenPossibleMoves(pc, SelSet)
  end
  local w = 82
  local x = (W - 5 * w) / 2
  local y = H - 50
  SetPanel = Good.GenDummy(-1)
  for i = 0, 4 do
    local pm = PossibleMoves[1 + i]
    if (nil ~= pm and 0 < #pm) then
      local o = GenTexObj(SetPanel, 12 + i, 60, 34, 0, 0)
      Good.SetPos(o, x + i * w + (w - 60)/2, y)
    end
  end
  SelIndex = 0
end

function GrayOutLastPlayCards()
  if (nil ~= LastSet) then
    for i = 1, LastSet.n do
      Good.SetScript(LastSet[i].o, 'GrayOut')
    end
  end
end

function GenScoreStrObj(parent, idxPlayer, s, color)
  return GenStrObj(parent, (W - 35)/2 + OFFSET_SCORE[2 * idxPlayer + 1], (H - 29)/2 + OFFSET_SCORE[2 * idxPlayer + 2], s, nil, nil, nil, color)
end

function UpdateLosePlayerScore(i)
  local pc = Players[i]
  local score = pc.n
  for j = 1, pc.n do
    local c = pc[j].c
    local n = GetNumber(c)
    if (JOKER1 == c or JOKER2 == c or 1 == n) then
      score = score * 2
    end
  end
  local s = string.format('-%d', score)
  local o = GenScoreStrObj(-1, i, s, 0xffff0000)
  PlayerScore[i] = PlayerScore[i] - score
  return o, score
end

function UpdatePlayerScores(win)
  local update = {}
  local Gain = 0
  for i = 0, 3 do
    if (win ~= i) then
      local o, score = UpdateLosePlayerScore(i)
      update[i] = o
      Gain = Gain + score
    end
  end
  PlayerScore[win] = PlayerScore[win] + Gain
  local s = string.format('+%d', Gain)
  local o = GenScoreStrObj(-1, win, s, 0xff00ff00)
  update[win] = o
  SetRoundScores(CurrRound - 1)
  for i = 0, 3 do
    Good.AddChild(-1, update[i])
  end
end

function PlayCardsToTable(pc, m, r)
  local nx = (W - CX_CARD)/2 + OFFSET_INDICATOR[2 * r + 1]/2 + math.random(-10, 10)
  local ny = (H - CY_CARD)/2 + OFFSET_INDICATOR[2 * r + 2]/2 + math.random(-10, 10)
  LastSet = {}
  LastSet.n = #m
  for i = 1, #m do
    local p = pc[m[i]]
    local o = p.o
    Good.SetPos(o, nx + 18 * (i - 1), ny)
    Good.SetRot(o, 0)
    local c = p.c
    Good.SetTexId(o, 0)
    Good.SetDim(o, CX_CARD * GetNumber(c), CY_CARD * GetFace(c), CX_CARD, CY_CARD)
    Good.AddChild(-1, o)                -- Move zorder to topmost.
    LastSet[i] = p
    local n = 1 + GetCompareNumber(c)
    PossibleCards[n] = PossibleCards[n] - 1
  end
  SortMoves(pc, m)
  for i = #m, 1, -1 do
    table.remove(pc, m[i])
  end
  pc.n = pc.n - #m
end

function PlayCards(pc, m)
  Good.KillAllChild(PassCount)
  if (nil ~= SetPanel) then
    Good.KillObj(SetPanel)
  end
  Good.SetVisible(btnPass, Good.INVISIBLE)
  Good.SetVisible(btnGo, Good.INVISIBLE)
  local r = math.mod(Round, 4)
  GrayOutLastPlayCards()
  PlayCardsToTable(pc, m, r)
  if (0 >= pc.n) then                   -- Cards clear.
    local o = GenTexObj(-1, 7, 100, 50, 0, 0)
    Good.SetPos(o, (W - 100)/2 + OFFSET_CLEAR[2 * r + 1], (H - 50)/2 + OFFSET_CLEAR[2 * r + 2])
    table.insert(ClearCount, 1 + r)
    if (3 == #ClearCount or 0 ~= TotalRound) then -- 3 players clear, game is over. Or any player clear then game is over in score mode.
      Good.KillObj(CurrPlayer)
      for i = 0, 3 do
        if (0 < Players[i].n) then
          local d = DebugMode
          DebugMode = true
          ArrangeCards(Players[i])      -- Show cards of last player.
          DebugMode = d
        end
      end
      if (0 ~= TotalRound) then
        CurrRound = CurrRound + 1
        UpdatePlayerScores(r)
      end
      return
    end
  end
  FirstRound = false
  NextRound()
  if (4 == SelSet) then                 -- Four of a kind, reverse order!
    AddReverseMsg()
    AIDelay = 130
  else
    ArrangeCards(pc)
  end
end

function PassOne()
  if (FirstRound) then
    return
  end
  if (nil ~= SetPanel) then
    Good.KillObj(SetPanel)
  end
  Good.SetVisible(btnPass, Good.INVISIBLE)
  Good.SetVisible(btnGo, Good.INVISIBLE)
  local r = math.mod(Round, 4)
  local o = GenTexObj(PassCount, 6, 28, 25)
  Good.SetPos(o, W/2 + OFFSET_PASS[2 * r + 1], H/2 + OFFSET_PASS[2 * r + 2])
  if (0 >= Players[r].n) then
    Good.SetVisible(o, Good.INVISIBLE)
  end
  NextRound()
end

function MarkTestCards(pc, m)
  for i = 1, #m do
    pc[m[i]].test = true                -- Mark cards to pretent played.
  end
end

function UnmarkTestCards(pc)
  for i = 1, pc.n do
    pc[i].test = false                  -- Undo mark.
  end
end

function ChooseLowestScorePossibleMove(pc)
  AITesting = true
  local BestScore = 1000
  local BestCardsLeft = 1000
  local BestMove = nil
  for i = 1, 5 do                       -- Loop for all possible moves to find a best move(lowest score)
    local pm = PossibleMoves[i]
    if (nil ~= pm and 0 < #pm) then
      for j = 1, #pm do
        local m = pm[j]
        if (nil == LastSet or #m == #LastSet) then
          MarkTestCards(pc, m)
          local TempMove = {}           -- Save the move.
          for k = 1,#m do
            TempMove[k] = pc[m[k]].c
          end
          SortCardsByNumber(pc)
          ArrangeCards(pc)
          pc.n = pc.n - #m
          local TempPossibleMoves = GenPossibleMoves(pc) -- Regen possible moves to get new card flags.
          local s,c = TmpReverseGetScore(pc, 4 == j)
          if ((1 == pc.AISel and BestScore > s) or (2 == pc.AISel and (BestScore > s or BestCardsLeft > c))) then
            BestScore = s
            BestCardsLeft = c
            BestMove = TempMove
            SelSet = i
          end
          pc.n = pc.n + #m
          UnmarkTestCards(pc)
          SortCardsByNumber(pc)
          ArrangeCards(pc)
        end
      end
    end
  end
  AITesting = false
  SortCardsByNumber(pc)
  ArrangeCards(pc)
  return BestMove
end

function ChooseBestMove2(pc)
  local BestMove = ChooseLowestScorePossibleMove(pc)
  if (nil ~= BestMove) then
    local m = {}
    for i = 1, #BestMove do
      for j = 1, pc.n do
        if (pc[j].c == BestMove[i]) then
          m[i] = j
          break
        end
      end
    end
    PlayCards(pc, m)
    return true
  else
    return false
  end
end

function ChooseBestMove1(pc)
  local pm
  if (nil == LastSet) then
    SelSet = 1
    pm = PossibleMoves[1]
  else
    pm = PossibleMoves[SelSet]
  end
  if (0 < #pm) then
    PlayCards(pc, pm[1])
    return true
  else
    return false
  end
end

function ChooseBestMove(pc, SelSet)
  PossibleMoves = GenPossibleMoves(pc, SelSet)
  if (0 == pc.AISel) then
    return ChooseBestMove1(pc)
  elseif (1 == pc.AISel or 2 == pc.AISel) then
    return ChooseBestMove2(pc)
  else
    return false
  end
end

function AIMove(r)
  local pc = Players[r]
  -- First round.
  if (FirstRound) then
    ChooseBestMove(pc)
    return
  end
  -- All clear?
  if (0 >= pc.n) then
    PassOne()
    return
  end
  -- 3 players pass, new round.
  if (3 <= Good.GetChildCount(PassCount)) then
    Good.KillAllChild(PassCount)
    GrayOutLastPlayCards()
    LastSet = nil
    if (not ChooseBestMove(pc)) then
      SelSet = 1
      PlayCards(pc, {1})
    end
    return
  end
  -- Follow LastSet.
  if (nil ~= LastSet) then
    if (ChooseBestMove(pc, SelSet)) then
      return
    end
  end
  -- Can't follow, pass.
  PassOne()
end

function SetRoundScores(r)
  if (0 == TotalRound) then             -- This is not round mode.
    return
  end
  Good.KillAllChild(RoundMsg)
  local s = string.format("Round %d/%d", r, TotalRound)
  local o = GenStrObj(RoundMsg, 0, 0, s, nil, nil, nil, 0x80ffffff)
  AdjustStrObj(o)
  for i = 0, 3 do
    local s = string.format("%d", PlayerScore[i])
    local o = GenScoreStrObj(RoundMsg, i, s, 0x80ffffff)
    AdjustStrObj(o)
  end
end

Level = {}

Level.OnCreate = function(param)
  Reverse = false
  FirstRound = true
  InitCards()
  RoundMsg = Good.GenDummy(-1)
  Good.AddChild(-1, RoundMsg)
  SetRoundScores(CurrRound)
  CurrPlayer = nil
  SetCurrPlayerIndicator()
  AIDelay = 30
  PassCount = Good.GenDummy(-1)
  ClearCount = {}
  SelSet = nil
  SetIndex = nil
  LastSet = nil
  SetPanel = nil
  btnGo = GenTexObj(-1, 10, 100, 100, 0, 0)
  Good.SetPos(btnGo, W - 100, H - 100)
  Good.SetVisible(btnGo, Good.INVISIBLE)
  btnPass = GenTexObj(-1, 9, 100, 100, 0, 0)
  Good.SetPos(btnPass, 0, H - 100)
  Good.SetVisible(btnPass, Good.INVISIBLE)
  if (2 == Round) then
    MyRound()
  end
  Level.OnStep = OnStepGame
end

function ShowMsgBox(msg)
  local w1,h1 = Resource.GetTexSize(47)
  MsgBox = Good.GenObj(-1, 47)
  Good.SetPos(MsgBox, (W - w1)/2, (H - h1)/2)
  local o = Good.GenObj(MsgBox, msg)
  local w2,h2 = Resource.GetTexSize(msg)
  Good.SetPos(o, (w1-w2)/2, 70)
end

function SortPlayerScore(Rank)
  for i = 0, 2 do
    for j = i, 3 do
      if (PlayerScore[i] < PlayerScore[j]) then
        local tmp = PlayerScore[i]
        PlayerScore[i] = PlayerScore[j]
        PlayerScore[j] = tmp
        tmp = Rank[i + 1]
        Rank[i + 1] = Rank[j + 1]
        Rank[j + 1] = tmp
      end
    end
  end
end

function SetRanking()
  if (0 == TotalRound) then
    return
  end
  local PlayerRank = {0, 1, 2, 3}
  SortPlayerScore(PlayerRank)
  for i = 0, 3 do
    local x = (W - 100)/2 + OFFSET_RANKING[2 * PlayerRank[i + 1] + 1]
    local y = (H - 100)/2 + OFFSET_RANKING[2 * PlayerRank[i + 1] + 2]
    local o = Good.GenObj(-1, 66)
    Good.SetPos(o, x, y)
    local s = GenStrObj(o, (100 - 16)/2, 12, string.format('%d', (1 + i)), nil, nil, nil, 0xffff0000)
  end
end

function AddReverseMsg()
  msgReverse = Good.GenObj(-1, 11, 'Blink')
  Good.SetBgColor(msgReverse, 0xffff0000)
  local x,y,w,h = Good.GetDim(msgReverse)
  Good.SetPos(msgReverse, (W - w)/2, (H - h)/2)
end

function KillReverseMsg()
  if (nil ~= msgReverse) then           -- Kill reverse msg.
    Good.KillObj(msgReverse)
    msgReverse = nil
    Reverse = not Reverse
    for i = 0, 3 do
      local pc = Players[i]
      SortCardsByNumber(pc)
      ArrangeCards(pc)
    end
    if (2 == math.mod(Round, 4)) then
      PossibleMoves = GenPossibleMoves(Players[2])
    end
    if (Reverse) then
      PossibleCards[0] = PossibleCards[16]
      PossibleCards[16] = 0
    else
      PossibleCards[16] = PossibleCards[0]
      PossibleCards[0] = 0
    end
  end
end

function ToggleDebugMode(IsToggle)
  if (EnableDebug) then
    if (IsToggle) then
      DebugMode = not DebugMode
      for i = 0, 3 do
        local pc = Players[i]
        ResetCardsPos(pc)
        ArrangeCards(pc)
      end
    end
  else
    DebugMode = false
  end
end

function SelCardSet(pc, Index)
  if (1 + Index ~= SelSet) then
    SelSet = 1 + Index
    SelIndex = 1
  else
    SelIndex = SelIndex + 1
    if (#PossibleMoves[SelSet] < SelIndex) then
      SelIndex = 1
    end
  end
  ResetCardsPos(pc)
  local m = PossibleMoves[SelSet][SelIndex]
  for i = 1, #m do
    ToggleSelCard(pc[m[i]])
  end
end

function SelCardSetChanged(mx, my, pc)
  local w = 82
  local x = (W - 5 * w) / 2
  local y = H - 50
  for i = 0, 4 do
    local pm = PossibleMoves[1 + i]
    local xb = x + i * w + (w - 60)/2
    if (nil ~= pm and 0 < #pm and PtInRect(mx, my, xb - 10, y - 10, xb + 60 + 10, y + 34 + 20)) then
      SelCardSet(pc, i)
      return true
    end
  end
  return false
end

function isQuitGame()
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    Level.OnStep = OnStepQuit
    ShowMsgBox(48)
    return true
  else
    return false
  end
end

function isGameOver()
  if (3 == #ClearCount) then
    GrayOutLastPlayCards()
    AIDelay = 80
    Level.OnStep = OnStepOver
    return true
  end
  if (0 ~= TotalRound and 0 ~= #ClearCount) then -- One is clear in score mode.
    GrayOutLastPlayCards()
    AIDelay = 180
    if (CurrRound > TotalRound) then
      Level.OnStep = OnStepOver
    else
      Level.OnStep = OnStepNextRound
    end
    return true
  end
  return false
end

function PlayMyRound()
  local pc = Players[2]
  if (0 >= pc.n) then                   -- Clear?
    PassOne()
    return
  end

  if (not FirstRound and 3 > Good.GetChildCount(PassCount) and nil ~= SelSet and 0 == #PossibleMoves[SelSet]) then -- No move?
    PassOne()
    return
  end

  if (not FirstRound and 3 > Good.GetChildCount(PassCount)) then -- Enable pass and go btn.
    Good.SetVisible(btnPass, Good.VISIBLE)
  end
  Good.SetVisible(btnGo, Good.VISIBLE)

  if (not Input.IsKeyPushed(Input.LBUTTON)) then -- No touch?
    return
  end

  local mx, my = Input.GetMousePos()

  if (EnableDebug and PtInRect(mx, my, (W - 40)/2, (H - 40)/2, (W + 20)/2, (H + 20)/2)) then -- New game.
    Good.GenObj(-1, 2)
    return
  end

  ToggleDebugMode(PtInRect(mx, my, W - 40, 0, W, 40))

  if (SelCardSetChanged(mx, my, pc)) then -- Sel set.
    return
  end

  if (PtInRect(mx, my, W - 100, H - 100, W, H)) then -- Play card.
    if (Good.INVISIBLE == Good.GetVisible(btnGo)) then
      return
    end
    if (0 < SelIndex) then
      local m = PossibleMoves[SelSet][SelIndex]
      PlayCards(pc, m)
    end
  elseif (not FirstRound and PtInRect(mx, my, 0, H - 100, 100, H)) then -- Pass.
    if (Good.INVISIBLE == Good.GetVisible(btnPass)) then
      return
    end
    ResetCardsPos(pc)
    PassOne()
  end
end

function OnStepGame(param)
  if (isQuitGame()) then
    return
  end

  if (isGameOver()) then
    return
  end

  -- AI round.
  if (0 < AIDelay) then
    AIDelay = AIDelay - 1
    return
  end

  KillReverseMsg()

  local r = math.mod(Round, 4)
  if (2 ~= r) then
    AIMove(r)
    return
  end

  PlayMyRound()
end

function OnStepQuit(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    Good.KillObj(MsgBox)
    Level.OnStep = OnStepGame           -- Resume game.
  elseif (Input.IsKeyPushed(Input.LBUTTON)) then
    local w,h = Resource.GetTexSize(47)
    local mbx,mby = (W-w)/2, (H-h)/2
    local x,y = Input.GetMousePos()
    if (PtInRect(x, y, mbx, mby + h/2, mbx + w/2, mby + h)) then
      Good.KillObj(MsgBox)
      Level.OnStep = OnStepGame         -- Resume game.
    elseif (PtInRect(x, y, mbx + w/2, mby + h/2, mbx + w, mby + h)) then
      Good.GenObj(-1, 18)               -- Title.
    end
  end
end

function OnStepOver(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    -- Eat.
  end
  if (0 < AIDelay) then
    AIDelay = AIDelay - 1
    return
  end
  Level.OnStep = OnStepAgain
  ShowMsgBox(49)
  SetRanking()
end

function OnStepNextRound(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    -- Eat.
  end
  if (0 >= AIDelay) then
    Good.GenObj(-1, 2)                  -- New game.
  else
    AIDelay = AIDelay - 1
  end
end

function OnStepAgain(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    -- Eat.
  elseif (Input.IsKeyPushed(Input.LBUTTON)) then
    local w,h = Resource.GetTexSize(47)
    local mbx,mby = (W-w)/2, (H-h)/2
    local x,y = Input.GetMousePos()
    if (PtInRect(x, y, mbx, mby + h/2, mbx + w/2, mby + h)) then
      Good.GenObj(-1, 18)               -- Title.
    elseif (PtInRect(x, y, mbx + w/2, mby + h/2, mbx + w, mby + h)) then
      if (0 ~= TotalRound) then
        InitPlayerScore()
      end
      Good.GenObj(-1, 2)                -- New game.
    end
  end
end

Level.OnStep = OnStepGame
