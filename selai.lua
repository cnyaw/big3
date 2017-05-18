local MenuRect

SelAiLevel = {}

function DrakAllFace()
  local o = {40,41,42,53,54,55};
  AISel = 0
  for i =1, #o do
    Good.SetBgColor(o[i], 0xff000000)
  end
end

SelAiLevel.OnCreate = function(param)
  DrakAllFace()
  Good.SetBgColor(40, 0xffffffff)
  MenuRect = {}
  local o = {43,57,58,59}
  for i = 1, #o do
    local l,t,w,h = Good.GetDim(o[i])
    local x,y = Good.GetPos(o[i])
    local rc = {x, y, x + w, y + h}
    MenuRect[i] = rc
  end
  TotalRound = 0
  RandAI = false
end

SelAiLevel.OnStep = function(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    Good.GenObj(-1, 18)                 -- Back to title.
  elseif (Input.IsKeyPushed(Input.LBUTTON)) then
    local mx,my = Input.GetMousePos()
    for sel = 1, #MenuRect do
      local rc = MenuRect[sel]
      if (PtInRect(mx, my, rc[1], rc[2], rc[3], rc[4])) then
         sel = sel - 1
         if (AISel ~= sel) then
          DrakAllFace()
          AISel = sel
          if (3 == sel) then
            for i=53,55 do
              Good.SetBgColor(i, 0xffffffff)
            end
          else
            Good.SetBgColor(40 + sel, 0xffffffff)
          end
        else
          if (3 == sel) then
            RandAI = true
          end
          Good.GenObj(-1, 2)                  -- Start game.
        end
      end
    end
  end
end
