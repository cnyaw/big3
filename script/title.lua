EnableDebug = false

Title = {}

Title.OnCreate = function(param)
  local w,h = Resource.GetTexSize(0)    -- Hack: pre-load card tex so all tex can pack to one.
  param.EnableDebug5 = 0
end

Title.OnStep = function(param)
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    Good.Exit()
  elseif (Input.IsKeyPushed(Input.LBUTTON)) then
    local mx,my = Input.GetMousePos()
    local o = Good.PickObj(mx, my, Good.TEXBG)
    if (27 == o) then                   -- Click on the diamond.
      param.EnableDebug5 = param.EnableDebug5 + 1
      EnableDebug = 5 == param.EnableDebug5
    elseif (30 == o) then               -- Select round.
      Good.GenObj(-1, 45)
    elseif (50 == o) then               -- Select AI to play game.
      Good.GenObj(-1, 37)
    end
  end
end
