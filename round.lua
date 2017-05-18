local INIT_SCORE = 1000

TotalRound = 0
CurrRound = 0
PlayerScore = {}

SelRound = {}

function InitPlayerScore()
  CurrRound = 1
  for i = 0, 3 do
    PlayerScore[i] = INIT_SCORE
  end
end

function DrakAllRound()
  for i = 61, 65 do
    Good.SetBgColor(i, 0xff000000)
    Good.SetBgColor(Good.GetChild(i, 0), 0x40ffffff)
  end
end

function SelRound.OnCreate(param)
  for i = 61, 65 do
    local l,t,w,h = Good.GetDim(i)
    local o = GenStrObj(i, (w - 32)/2, (h - 32)/2, tostring(10 * (i - 60)))
  end
  DrakAllRound()
  Good.SetBgColor(61, 0xffffffff)
  Good.SetBgColor(Good.GetChild(61, 0), 0xffffffff)
  TotalRound = 0
  InitPlayerScore()
end

function SelRound.OnStep(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    Good.GenObj(-1, 18)                 -- Back to title.
  elseif (Input.IsKeyPushed(Input.LBUTTON)) then
    local mx,my = Input.GetMousePos()
    for i = 61, 65 do
      local l,t,w,h = Good.GetDim(i)
      local x,y = Good.GetPos(i)
      if (PtInRect(mx, my, x, y, x + w, y + h)) then
        if (TotalRound ~= i - 61) then
          DrakAllRound()
          Good.SetBgColor(i, 0xffffffff)
          Good.SetBgColor(Good.GetChild(i, 0), 0xffffffff)
          TotalRound = i - 61
        else
          TotalRound = 10 * (1 + TotalRound)
          Good.GenObj(-1, 2)                  -- Start game.
        end
        break
      end
    end
  end
end
