  -- * ReaScript Name: LBX Chaos Engine

-- @version 0.92
-- @author LBX - with original code from mpl
-- built upon mpl_Randomize_Track_FX_Parameters script
-- Also includes freely available code: Pickle/Unpickle (Steve Dekorte/Snooks), RoundRect (mwe/Lokasenna)

----------------------------------------------
----------------------------------------------

--ORIGINAL MPL HEADER:

-- @version 1.20
-- @author mpl
-- @changelog
--   + Add 'Get all parameters' button
--   + Add 'Get all parameters except protected' button
--   + Add 'render', "upsampl" to protected table

--[[
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  
--[[ changelog
    - 1.20
      + Add 'Get all parameters' button
      + Add 'Get all parameters except protected' button
      + Add 'render', "upsampl" to protected table
    - 1.11
       # ReaPack verioning fix
       + Store only picked parameters
       - Ignore protected table
    - 1.0
      + init release
    - 0.1
      + alpha without GUI
]]
  
  --------------------------------------------
  --------------------------------------------
  
  protected_table = {
    "upsmpl",
    "upsampl",
    "render",
    "gain", 
    "vol", 
    "on" ,
    "off",
    "wet",
    "dry",
    "oversamp",
    "alias",
    "input",
    "power",
    "solo",
    "mute",
    "feed",
    
    "attack",
    "decay",
    "sustain",
    "release",
    
    "bypass",
    "dest",
    "mix",
    "out",
    "make",
    "auto",
    "level",
    "peak",
    "limit",
    "velocity",
    "active",
    "master"
    }
  
  automode_table = {"Trim/Read","Read","Touch","Write","Latch", "Latch Preview"}
  
  sync_table = {"1/64t","1/64","1/64d","1/32t","1/32","1/32d","1/16t","1/16","1/16d","1/8t","1/8","1/8d","1/4t","1/4","1/4d","1/2t","1/2","1/2d","1","2","4","8","16","32"}
  sync_mult_table = {1/64*2/3,1/64,1/64*1.5,1/32*2/3,1/32,1/32*1.5,1/16*2/3,1/16,1/16*1.5,1/8*2/3,1/8,1/8*1.5,1/4*2/3,1/4,1/4*1.5,1/2*2/3,1/2,1/2*1.5,1,2,4,8,16,32}
  
  shape_table = {"TRI","SIN","SQR","FST","FST2","SLW","SLW2","SMO"}
  
  seq_step_table = {"R","A","B","C","D","E","F","G","H","-"}
  seq_speedmulttxt = {"1/8x", "1/4x", "1/2x", "1x", "2x", "4x", "8x"}
  seq_speedmult = {8, 4, 2, 1, 0.5, 0.25, 0.125}
  seq_triggerhold = {'OFF', 'BAR', 'BEAT'}
  dockpos_table = {'Window undocked','Window docked'}
  
  typeseq = 0
  typemorph = 1
  PI = 3.1415926535
  HALF_PI = 0.5 * 3.1415926535
  
  --local pow = math.pow
  
  function CalcSyncTime(syncidx)

    local ts_b,ts_d,bpm = reaper.TimeMap_GetTimeSigAtTime(0,reaper.GetPlayPosition())
    local tm
    if syncidx < 19 then  --less than a bar
      tm = ((60 * ts_d)/bpm) * sync_mult_table[syncidx]
    else
      tm = ((60 * ts_d)/bpm) * sync_mult_table[syncidx] * (ts_b/ts_d)
    end
    return tm
  
  end

  function CalcBarTime()

    local ts_b,ts_d,bpm = reaper.TimeMap_GetTimeSigAtTime(0,reaper.GetPlayPosition())
    local tm = ((60 * ts_d)/bpm) * (ts_b/ts_d) 
    
    return tm
  
  end
  
  function CalcBeatTime()
  
    local ts_b,ts_d,bpm = reaper.TimeMap_GetTimeSigAtTime(0,reaper.GetPlayPosition())
    local tm = ((60 * ts_d)/bpm) * (1/4) 
    
    return tm
  
  end
  
  --val between 0-1
  function CalcShapeVal(last_M, val, t, d)
  
    local oval = val
    if preset[last_M].morph_shape == 1 then
    elseif preset[last_M].morph_shape == 2 then
      --SINE
      --oval = (math.cos(math.rad(180 + val*180))+1)/2
      oval = (math.cos(PI + val*PI)+1) / 2
    elseif preset[last_M].morph_shape == 3 then
      --SQUARE
      oval = 1
    elseif preset[last_M].morph_shape == 4 then
      --FAST START
      --oval = math.sin(val*HALF_PI)
      oval = outCubic(t,0,1,d)
    elseif preset[last_M].morph_shape == 5 then
      --FAST START2
      oval = outExpo(t,0,1,d)
    elseif preset[last_M].morph_shape == 6 then
      --SLOW START
      --oval = math.cos(PI + val*HALF_PI)+1
      oval = inCubic(t,0,1,d)
    elseif preset[last_M].morph_shape == 7 then
      --SLOW START2
      oval = inExpo(t,0,1,d)
    elseif preset[last_M].morph_shape == 8 then
      --Smooth cubic
      oval = inOutCubic(t,0,1,d)
    end
    return oval
  end
  
  function inCubic(t, b, c, d)
    t = t / d
    return c * t^3 + b
  end

  function outCubic(t, b, c, d)
    t = t / d - 1
    return c * (t^3 + 1) + b
  end
  
  function inOutCubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then
      return c / 2 * t * t * t + b
    else
      t = t - 2
      return c / 2 * (t * t * t + 2) + b
    end
  end
  
  function inExpo(t, b, c, d)
    if t == 0 then
      return b
    else
      return c * 2^(10 * (t / d - 1)) + b - c * 0.001
    end
  end
  
  function outExpo(t, b, c, d)
    if t == d then
      return b + c
    else
      return c * 1.001 * -2^(-10 * t / d) + 1 + b
    end
  end
  
---------------------------------------------
-- Pickle.lua
-- A table serialization utility for lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
-- (updated for Lua 5.3 by me)
-- Freeware
----------------------------------------------

function pickle(t)
return Pickle:clone():pickle_(t)
end

Pickle = {
clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end
}

function Pickle:pickle_(root)
if type(root) ~= "table" then
error("can only pickle tables, not ".. type(root).."s")
end
self._tableToRef = {}
self._refToTable = {}
local savecount = 0
self:ref_(root)
local s = ""

while #self._refToTable > savecount do
savecount = savecount + 1
local t = self._refToTable[savecount]
s = s.."{\n"

for i, v in pairs(t) do
s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
end
s = s.."},\n"
end

return string.format("{%s}", s)
end

function Pickle:value_(v)
local vtype = type(v)
if vtype == "string" then return string.format("%q", v)
elseif vtype == "number" then return v
elseif vtype == "boolean" then return tostring(v)
elseif vtype == "table" then return "{"..self:ref_(v).."}"
else error("pickle a "..type(v).." is not supported")
end
end

function Pickle:ref_(t)
local ref = self._tableToRef[t]
if not ref then
if t == self then error("can't pickle the pickle class") end
table.insert(self._refToTable, t)
ref = #self._refToTable
self._tableToRef[t] = ref
end
return ref
end

----------------------------------------------
-- unpickle
----------------------------------------------

function unpickle(s)
if type(s) ~= "string" then
error("can't unpickle a "..type(s)..", only strings")
end
local gentables = load("return "..s)
local tables = gentables()

for tnum = 1, #tables do
local t = tables[tnum]
local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
for i, v in pairs(tcopy) do
local ni, nv
if type(i) == "table" then ni = tables[i[1]] else ni = i end
if type(v) == "table" then nv = tables[v[1]] else nv = v end
t[i] = nil
t[ni] = nv
end
end
return tables[1]
end

  ------------------------------------------------------------

--handy function to save writing reaper.ShowConsoleMsg("x".."\n")
function DBG(str)
if str==nil then str="nil" end
reaper.ShowConsoleMsg(str.."\n")
end

  ------------------------------------------------------------

local function SaveDefaultFXSetup()

  if preset[last_M][fxidx] ~= nil then
  
    local save_path=reaper.GetResourcePath().."/Scripts/LBX/"
    local fxname = preset[last_M][fxidx].fx_name:gsub('%W','')
    local fn=save_path..fxname..".txt"
  
    local DELETE=true
    local file
    
    if reaper.file_exists(fn) then
    
    end
    
    if DELETE then
      file=io.open(fn,"w")
      local pickled_table=pickle(preset[last_M][fxidx].params)
      file:write(pickled_table)
      file:close()
    end
    
  end

end

  ------------------------------------------------------------

local function LoadDefaultFXSetup(fxidx)

  if preset[last_M][fxidx] ~= nil then
  
    local load_path=reaper.GetResourcePath().."/Scripts/LBX/"
    local fxname = preset[last_M][fxidx].fx_name:gsub('%W','')
    local fn=load_path..fxname..".txt"
    if reaper.file_exists(fn) then

      local file
      file=io.open(fn,"r")
      local content=file:read("*a")
      file:close()
      
      local dp = unpickle(content)

      local dp_act_cnt = 1
      preset[last_M][fxidx].param_actidx = {}
      for i = 1,#dp do
      
        preset[last_M][fxidx].params[i] = {param_name = dp[i].param_name,
                                              is_protected = dp[i].is_protected,
                                              is_act = dp[i].is_act,
                                              val = preset[last_M][fxidx].params[i].val}
        if preset[last_M][fxidx].params[i].is_act then
          preset[last_M][fxidx].param_actidx[dp_act_cnt] = i
          dp_act_cnt = dp_act_cnt + 1
        end        
      end
            
    end

  end
  
end

  ------------------------------------------------------------

-- Improved roundrect() function with fill, adapted from mwe's EEL example.
local function roundrect(x, y, w, h, r, antialias, fill)
  
  local aa = antialias or 1
  fill = fill or 0
  
  if fill == 0 or false then
    gfx.roundrect(x, y, w, h, r, aa)
  elseif h >= 2 * r then
    gfx.a = 1
    -- Corners
    gfx.circle(x + r, y + r, r, 1, aa)      -- top-left
    gfx.circle(x + w - r-1, y + r, r, 1, aa)    -- top-right
    gfx.circle(x + w - r-1, y + h - r -1, r , 1, aa)  -- bottom-right
    gfx.circle(x + r, y + h - r -1, r, 1, aa)    -- bottom-left
    
    -- Ends
    gfx.rect(x, y + r, r, h - r * 2)
    gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
      
    -- Body + sides
    gfx.rect(x + r, y, w - r * 2 + 1, h + 1.5)
    
  else
  
    r = h / 2 - 1
  
    -- Ends
    gfx.circle(x + r, y + r, r, 1, aa)
    gfx.circle(x + w - r, y + r, r, 1, aa)
    
    -- Body
    gfx.rect(x + r, y, w - r * 2, h)
    
  end  
  
end

  ------------------------------------------------------------

  function GetObjects_Settings()
    local obj = {}
      
    main_w = gfx1.main_w        
    
    local sizew = 600
    local sizeh = 400
    local butth = 25
      
    obj.sections = {}
    obj.sections[1] = {x = ((main_w/2) - (sizew/2)),
                       y = ((gfx1.main_h/2) - (sizeh/2)),
                       w = sizew,
                       h = sizeh}
    obj.sections[2] = {x = obj.sections[1].x + obj.sections[1].w - 32,
                       y = obj.sections[1].y - 38,
                       w = 30,
                       h = 36}

    obj.sections[10] = {x = obj.sections[1].x + 12,
                       y = obj.sections[1].y + 12,
                       w = (sizew-24)/2,
                       h = butth}
    obj.sections[11] = {x = obj.sections[1].x + 12,
                       y = obj.sections[10].y + obj.sections[10].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[12] = {x = obj.sections[1].x + 12,
                       y = obj.sections[11].y + obj.sections[11].h + 2,
                       w = (sizew-24)/2,
                       h = butth}
    obj.sections[13] = {x = obj.sections[1].x + 12,
                       y = obj.sections[12].y + obj.sections[12].h + 2,
                       w = (sizew-24)/2,
                       h = butth}
    obj.sections[14] = {x = obj.sections[1].x + 12,
                       y = obj.sections[13].y + obj.sections[13].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[15] = {x = obj.sections[1].x + 12,
                       y = obj.sections[14].y + obj.sections[14].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[16] = {x = obj.sections[1].x + 12,
                       y = obj.sections[15].y + obj.sections[15].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[17] = {x = obj.sections[1].x + 12,
                       y = obj.sections[16].y + obj.sections[16].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[18] = {x = obj.sections[1].x + 12,
                       y = obj.sections[17].y + obj.sections[17].h + 2,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[59] = {x = obj.sections[1].x + 12,
                       y = obj.sections[1].y + obj.sections[1].h - 2*butth,
                       w = (sizew-24)/2,
                       h = butth}

    obj.sections[60] = {x = ((main_w/2) - (sizew/2)),
                       y = ((gfx1.main_h/2) - (sizeh/2))-40,
                       w = sizew,
                       h = 40}
    
    return obj
    
  end
  ------------------------------------------------------------

  function GetObjects()
    local obj = {}
      
      if pick_state then
          main_w = gfx1.main_w - plist_w
      else
          main_w = gfx1.main_w        
      end
      
      local screenoff = 3
      obj.sections = {}
      local num = 8
      local offset = (gfx1.main_h) / (num * 2)
      local dy = 0
      for i =1, num do
        if i == 1 then
          obj.sections[i] = {x = 0 ,
                             y = 0,
                             w = main_w,
                             h = (gfx1.main_h) / (num * 4) + 10}
        else
          obj.sections[i] = {x = 0 ,
                             y = obj.sections[i-1].y+obj.sections[i-1].h,
                             w = main_w,
                             h = (gfx1.main_h-obj.sections[1].h) / (num-1)}        
        end
      end

      local slotw = main_w / (slotcnt + 1)
      
      local spacer = 12
      obj.sections[65] = {x = 0,
                          y = obj.sections[2].y + spacer,
                          w = main_w,
                          h = obj.sections[2].h - spacer*2}
      
      obj.sections[2].w = 180
      obj.sections[2].y = 0
      obj.sections[2].h = obj.sections[1].h
      obj.sections[1].x = 176
      obj.sections[1].y = 0
      obj.sections[1].w = 180
      
      obj.sections[4].y = obj.sections[4].y + obj.sections[4].h / 4      
      obj.sections[5].y = obj.sections[5].y + obj.sections[5].h / 2
      
      obj.sections[102] = {x = 100,
                           y = obj.sections[4].y + obj.sections[4].h / 4,
                           w = main_w - 108,
                           h = obj.sections[4].h + obj.sections[5].h - (obj.sections[4].h / 2) + 24}
      obj.sections[103] = {x = obj.sections[102].x,
                           y = obj.sections[102].y-18,
                           w = obj.sections[102].w,
                           h = 18}
      
      obj.sections[10] = {x = obj.sections[1].x + obj.sections[1].w - 4,
                          y = obj.sections[1].y,
                          w = obj.sections[1].w,
                          h = obj.sections[1].h}
      obj.sections[11] = {x = obj.sections[10].x + obj.sections[10].w+2,
                          y = obj.sections[1].y,
                          w = main_w - (obj.sections[1].x + obj.sections[1].w) - 178 ,
                          h = obj.sections[1].h}
                           
    for i = 0, slotcnt / 2 - 1 do
      obj.sections[13 + i] = {x = main_w - (5 * slotw) + slotw + (slotw * i) ,
                            y = obj.sections[3].y,
                            w = slotw - 2,
                            h = obj.sections[3].h/2}                           
    end
    for i = 0, slotcnt / 2 - 1 do
      obj.sections[17 + i] = {x = main_w - (5 * slotw) + slotw + (slotw * i) ,
                            y = obj.sections[3].y + obj.sections[3].h/2,
                            w = slotw - 2,
                            h = obj.sections[3].h/2}                           
    end
    obj.sections[3].w = obj.sections[13].w + 5 - 6
    obj.sections[3].x = main_w - (5 * slotw)
    for i = 0, 15 do
      obj.sections[44 + i] = {x = (main_w / 16) * i ,
                            y = obj.sections[65].y,
                            w = (main_w) / 16 - 2,
                            h = obj.sections[65].h}                           
    end
    
    
    obj.sections[80] = {x = 62,
                        w = obj.sections[3].x-64,
                        y = obj.sections[3].y - screenoff,
                        h = 20}
    
    slotw = (main_w - 300) / (slotcnt + 2)
    
    obj.sections[6].x = slotw * 5 + 12
    obj.sections[6].y = obj.sections[7].y
    obj.sections[6].w = main_w - (slotw * 10) - 24
    obj.sections[6].h = obj.sections[7].h + obj.sections[8].h
    
    obj.sections[7].w = slotw-2
    for i = 0, (slotcnt / 2)-1 do
      obj.sections[24+i] = {x = (i+1) * slotw,
                            y = obj.sections[7].y,
                            w = slotw-2,
                            h = obj.sections[7].h}                           
    end
    for i = 0, (slotcnt / 2)-1 do
      obj.sections[32+i] = {x = main_w - (5*slotw) + (i) * slotw,
                            y = obj.sections[7].y,
                            w = slotw-2,
                            h = obj.sections[7].h}                           
    end
    --obj.sections[7].h = obj.sections[7].h + obj.sections[8].h
    for i = 0, (slotcnt / 2)-1 do
      obj.sections[28+i] = {x = (i+1) * slotw,
                            y = obj.sections[8].y,
                            w = slotw-2,
                            h = obj.sections[8].h}                           
    end
    for i = 0, (slotcnt / 2)-1 do
      obj.sections[36+i] = {x = main_w - (5*slotw) + (i) * slotw,
                            y = obj.sections[8].y,
                            w = slotw-2,
                            h = obj.sections[8].h}                           
    end
    obj.sections[66] = {x = obj.sections[24].x,
                        y = obj.sections[24].y,
                        w = obj.sections[31].x + obj.sections[31].w - obj.sections[24].x,
                        h = obj.sections[31].y + obj.sections[31].h - obj.sections[24].y}
    obj.sections[67] = {x = obj.sections[32].x,
                        y = obj.sections[32].y,
                        w = obj.sections[39].x + obj.sections[39].w - obj.sections[32].x,
                        h = obj.sections[39].y + obj.sections[39].h - obj.sections[32].y}

    obj.sections[41] = {x = main_w - (slotw-1),
                          y = obj.sections[7].y,
                          w = slotw-2,
                          h = obj.sections[7].h}                           
    obj.sections[101] = {x = main_w - (slotw-1),
                          y = obj.sections[8].y,
                          w = slotw-2,
                          h = obj.sections[41].h}                           

    obj.sections[60] = {x = main_w - 360 ,
                          y = obj.sections[1].y,
                          w = 178,
                          h = obj.sections[1].h}

    obj.sections[111] = {x = main_w - 540 ,
                          y = obj.sections[1].y,
                          w = 178,
                          h = obj.sections[1].h}
    obj.sections[110] = {x =  obj.sections[2].x + obj.sections[2].w + 2,
                          y = obj.sections[1].y,
                          w = main_w - 542 - obj.sections[2].w - 2,
                          h = obj.sections[1].h}
                                                     
    obj.sections[40] = {x = main_w - 180 ,
                          y = obj.sections[1].y,
                          w = 178,
                          h = obj.sections[1].h}                           


    obj.sections[42] = {x = 0 ,
                          y = obj.sections[3].y + 20 - screenoff,
                          w = obj.sections[3].x,
                          h = obj.sections[3].h/2}
    obj.sections[68] = {x = 0 ,
                          y = obj.sections[3].y + obj.sections[3].h/2 + 8 - screenoff,
                          w = obj.sections[3].x,
                          h = obj.sections[3].h/2}

    obj.sections[43] = {x = main_w + 5,
                        y = 0,
                        w = plist_w - 5,
                        h = gfx1.main_h}                           
    obj.sections[69] = {x = 8 ,
                          y = obj.sections[80].y,
                          w = 60,
                          h = obj.sections[80].h}
    obj.sections[70] = {x = obj.sections[43].x + obj.sections[43].w - 2 * butt_h - 4,
                  y = 2+fx_h,
                  w = butt_h,
                  h = butt_h - 4}
    obj.sections[71] = {x = obj.sections[43].x + obj.sections[43].w - butt_h - 2,
                  y = 2+fx_h,
                  w = butt_h,
                  h = butt_h - 4}
    obj.sections[75] = {x = obj.sections[6].x ,
                        y = obj.sections[6].y, 
                        w = obj.sections[6].w,
                        h = math.max(obj.sections[6].h/8-2,20)}
    obj.sections[77] = {x = obj.sections[75].x ,
                        y = obj.sections[75].y + (obj.sections[75].h +1), 
                        w = (obj.sections[75].w)/4 - 2,
                        h = math.max(obj.sections[75].h-8,20)}
    obj.sections[78] = {x = obj.sections[77].x + obj.sections[77].w + 2,
                        y = obj.sections[77].y, 
                        w = obj.sections[77].w,
                        h = obj.sections[77].h}
    obj.sections[79] = {x = obj.sections[77].x + (obj.sections[77].w + 2) *3,
                        y = obj.sections[78].y, -- + obj.sections[78].h + 2, 
                        w = obj.sections[78].w,
                        h = obj.sections[78].h}
    obj.sections[113] = {x = obj.sections[6].x ,
                        y = obj.sections[78].y + obj.sections[78].h+2,
                        w = obj.sections[6].w,
                        h = obj.sections[78].h}
    obj.sections[114] = {x = obj.sections[6].x ,
                        y = obj.sections[113].y + obj.sections[113].h+1,
                        w = obj.sections[6].w,
                        h = obj.sections[113].h}
    obj.sections[76] = {x = obj.sections[6].x ,
                        y = obj.sections[114].y + obj.sections[114].h + (gfx1.main_h - (obj.sections[114].y + obj.sections[114].h))/4, --obj.sections[6].y + (obj.sections[6].h / 2) - 20, 
                        w = obj.sections[6].w,
                        h = (gfx1.main_h - (obj.sections[113].y + obj.sections[113].h))/2} --obj.sections[6].h-4 - (obj.sections[6].h / 2)-20}
    obj.sections[81] = {x = obj.sections[6].x ,
                        y = obj.sections[6].y - 22, 
                        w = obj.sections[6].w/2 - 2,
                        h = 20}
    obj.sections[82] = {x = obj.sections[6].x + obj.sections[6].w/2,
                        y = obj.sections[6].y - 22, 
                        w = obj.sections[6].w/4 - 2,
                        h = 20}

    obj.sections[112] = {x = obj.sections[6].x + obj.sections[6].w/4 * 3,
                        y = obj.sections[6].y - 22, 
                        w = obj.sections[6].w/4 - 2,
                        h = 20}

    obj.sections[83] = {x = obj.sections[77].x + (obj.sections[77].w + 2)*2,
                        y = obj.sections[77].y, --+ obj.sections[77].h + 2, 
                        w = obj.sections[77].w,
                        h = obj.sections[77].h}
    obj.sections[90] = {x = 8, y = obj.sections[42].y +6, 
                        w = obj.sections[3].x - 16, 
                        h = obj.sections[68].y + obj.sections[68].h - obj.sections[42].y - 8}
    
    obj.sections[100] = {x = 0,
                         y = obj.sections[5].y + obj.sections[5].h + 6,
                         w = obj.sections[24].w,
                         h = math.max(obj.sections[6].y - (obj.sections[5].y + obj.sections[5].h + 6) - 10, 20)}
    --SeqSelect
    obj.sections[104] = {x = obj.sections[100].w + 2,
                         y = obj.sections[100].y,
                         w = obj.sections[100].w,
                         h = obj.sections[100].h}
    --Loop
    obj.sections[105] = {x = obj.sections[104].x + obj.sections[104].w + 2,
                         y = obj.sections[100].y,
                         w = obj.sections[100].w,
                         h = obj.sections[100].h}
    obj.sections[106] = {x = obj.sections[105].x + obj.sections[105].w + 2,
                         y = obj.sections[100].y,
                         w = obj.sections[100].w,
                         h = obj.sections[100].h}
                         
    obj.sections[107] = {x = obj.sections[33].x,
                         y = obj.sections[100].y,
                         w = obj.sections[41].x + obj.sections[41].w - obj.sections[33].x,
                         h = obj.sections[100].h}
    obj.sections[108] = {x = obj.sections[32].x,
                         y = obj.sections[100].y,
                         w = obj.sections[32].w,
                         h = obj.sections[100].h}
                         
    obj.sections[109] = {x = obj.sections[106].x + obj.sections[106].w + 2,
                         y = obj.sections[100].y,
                         w = obj.sections[100].w,
                         h = obj.sections[100].h}

    obj.sections[120] = {x = obj.sections[4].x,
                         y = obj.sections[4].y + obj.sections[4].h + 4,
                         w = obj.sections[4].w,
                         h = obj.sections[5].y - (obj.sections[4].y + obj.sections[4].h + 4)}
                         
    --Print Sequence
    obj.sections[121] = {x = obj.sections[4].x + 4,
                         y = obj.sections[4].y,
                         w = 90,
                         h = 16}
    local pw,ph, butt_h = 500, 130, 20 --(obj.sections[5].y + obj.sections[5].h) - obj.sections[4].y
    obj.sections[122] = {x = (obj.sections[4].x + obj.sections[4].w/2) - pw/2,
                         y = (obj.sections[4].y + (((obj.sections[5].y + obj.sections[5].h) - obj.sections[4].y)/2)) - ph/2  ,
                         w = pw,
                         h = ph}

    
    obj.sections[123] = {x = obj.sections[122].x + 120,
                             y = obj.sections[122].y + 20,
                             w = 150,
                             h = butt_h}    
    obj.sections[124] = {x = obj.sections[122].x + 120,
                             y = obj.sections[122].y + 55,
                             w = 75,
                             h = butt_h}    
    obj.sections[125] = {x = obj.sections[122].x + 120,
                             y = obj.sections[122].y + 90,
                             w = 75,
                             h = butt_h}    

    obj.sections[126] = {x = obj.sections[122].x + 300,
                             y = obj.sections[122].y + 55,
                             w = 170,
                             h = butt_h*2}    

    return obj
  end
  
  -----------------------------------------------------------------------     
  
  function GetGUI_vars()
    gfx.mode = 0
    
    local gui = {}
      gui.aa = 1
      gui.fontname = 'Calibri' --Calibri
      gui.fontsize_tab = 20    
      gui.fontsz_knob = 18
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize_tab = gui.fontsize_tab - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_knob = gui.fontsz_knob - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_get = gui.fontsz_get - 5 end
      
      gui.color = {['back'] = '71 71 71 ',
                      ['back2'] = '51 63 56',
                      ['black'] = '0 0 0',
                      ['green'] = '102 255 102',
                      ['green1'] = '0 120 169', --'0 156 36',
                      ['green_dark1'] = '0 76 0',
                      ['blue'] = '127 204 255',
                      ['white'] = '205 205 205',
                      ['red'] = '255 70 50',
                      ['green_dark'] = '102 153 102',
                      ['yellow'] = '200 200 0',
                      ['yellow1'] = '160 160 0',
                      ['bryellow'] = '220 220 0',
                      ['pink'] = '200 150 200',
                      ['grey'] = '0 13 25', --'64 64 64',
                      ['grey1'] = '0 25 50', --'32 32 32',
                      ['dgrey1'] = '0 25 50', --'16 16 16',
                      ['dgrey2'] = '16 16 16',
                      ['red1'] = '165 8 46',
                      ['red2'] = '93 4 28',
                      ['red3'] = '200 13 66',
                      ['blue1'] = '0 120 169',
                      ['dblue1'] = '0 25 50',
                      ['backg'] = '5 0 10'
                    }
    return gui
  end  
  
  ------------------------------------------------------------
      
  function f_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  
  ------------------------------------------------------------
  
  function GUI_textC_FIT(gui, xywh, text, color, defsz)
     
    local font_sz = defsz
    local pad = 2
  
    gfx.setfont(1, gui.fontname, font_sz)
  
    --gfx.rect(x,y,w,h,0)
  
    local str_w, str_h = gfx.measurestr(text)
  
    -- We don't want to run the text right to the edge of the button
    local max_length = xywh.w - (2 * pad)
  
    -- See if my_str at the current size will fit in the rectangle
    -- If it does, break the loop and carry on
    -- If it doesn't, reduce the font size by 1 and check again
    local i
    for i = font_sz, 0, -1 do
      
      if str_w <= max_length then break end
  
      gfx.setfont(1, font, i)
      str_w, str_h = gfx.measurestr(text)
    end
    
    f_Get_SSV(color) 
    gfx.x = xywh.x + (xywh.w - str_w) / 2
    gfx.y = xywh.y + (xywh.h - str_h) / 2
    gfx.drawstr(text)
  end

  function GUI_textC_FIT_RJ(gui, xywh, text, color, defsz, pad)
     
    local font_sz = defsz
    --local pad = 8
  
    gfx.setfont(1, gui.fontname, font_sz)
  
    --gfx.rect(x,y,w,h,0)
  
    local str_w, str_h = gfx.measurestr(text)
  
    -- We don't want to run the text right to the edge of the button
    local max_length = xywh.w - (2 * pad)
  
    -- See if my_str at the current size will fit in the rectangle
    -- If it does, break the loop and carry on
    -- If it doesn't, reduce the font size by 1 and check again
    local i
    for i = font_sz, 0, -1 do
      
      if str_w <= max_length then break end
  
      gfx.setfont(1, font, i)
      str_w, str_h = gfx.measurestr(text)
    end
    
    f_Get_SSV(color) 
    gfx.x = xywh.x + (xywh.w - str_w) - pad
    gfx.y = xywh.y + (xywh.h - str_h) / 2
    gfx.drawstr(text)
  end
  
  function GUI_textC(gui, xywh, text, color, offs)
        f_Get_SSV(color)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
    
  function GUI_text(gui, xywh, text)
        f_Get_SSV(gui.color.white)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end

  function GUI_textsm(gui, xywh, text)
        f_Get_SSV(gui.color.white)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob-1.5)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
  
  function GUI_textsm_LJ(gui, xywh, text, c)
        f_Get_SSV(c)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob-1.5)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+4,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end

  function GUI_textsm2_LJ(gui, xywh, text, c, offs)
        f_Get_SSV(c)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+2,xywh.y+(xywh.h-gfx.texth)/2 -1
        gfx.drawstr(text)
  end
  function GUI_textsm2_RJ(gui, xywh, text, c, offs)
        f_Get_SSV(c)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+xywh.w-(text_len+2),xywh.y+(xywh.h-gfx.texth)/2 -1
        gfx.drawstr(text)
  end
  
  function GUI_text_size(gui, xywh, text, offs)
        f_Get_SSV(gui.color.white)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob-offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
  
  ------------------------------------------------------------
  
  function GUI_DrawPList(obj, gui)
  
    if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].params ~= nil then

      butt_cnt = math.floor((gfx1.main_h - fx_h) / butt_h)
      for i = 0, butt_cnt-1 do
      
        local xywh = {x = obj.sections[43].x,
                      y = fx_h + i * butt_h,
                      w = obj.sections[43].w,
                      h = butt_h}
        if preset[last_M][fxidx].params[i + plist_offset] ~= nil then
          local c = gui.color.white
          if preset[last_M][fxidx].params[i + plist_offset].is_act then
            f_Get_SSV(gui.color.blue1)
            gfx.a = 1  
            gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )
            c = gui.color.black
          end
          GUI_textsm_LJ(gui, xywh, preset[last_M][fxidx].params[i + plist_offset].param_name, c)
        end
      end
      local xywh = {x = obj.sections[43].x,
                    y = fx_h,
                    w = obj.sections[43].w,
                    h = butt_h}
      f_Get_SSV('128 128 128')
      gfx.a = 0.5  
      gfx.rect(xywh.x,
       xywh.y, 
       xywh.w,
       xywh.h, 1 )
      gfx.a = 0.5
      f_Get_SSV(gui.color.black)
      gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
       
      local xywh = {x = obj.sections[43].x,
                    y = obj.sections[43].h - butt_h,
                    w = obj.sections[43].w,
                    h = butt_h}
      f_Get_SSV('128 128 128')
      gfx.a = 0.5  
      gfx.rect(xywh.x,
       xywh.y, 
       xywh.w,
       xywh.h, 1 )
      gfx.a = 0.5
      f_Get_SSV(gui.color.black)
      gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

      --L & S buttons
      f_Get_SSV(gui.color.black)
      gfx.a = 0.8  
      gfx.rect(obj.sections[70].x,
       obj.sections[70].y, 
       obj.sections[70].w,
       obj.sections[70].h, 0 )
      GUI_textsm(gui, obj.sections[70], "L")

      f_Get_SSV(gui.color.black)
      gfx.a = 0.8  
      gfx.rect(obj.sections[71].x,
       obj.sections[71].y, 
       obj.sections[71].w,
       obj.sections[71].h, 0 )
      GUI_textsm(gui, obj.sections[71], "S")

    --FX
    local xywh = {x = obj.sections[43].x,
                  y = 0,
                  w = obj.sections[43].w,
                  h = butt_h}
    f_Get_SSV('128 128 128')
    gfx.a = 0.5  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
    
    local xywh = {x = obj.sections[43].x,
                  y = fx_h - butt_h - 10,
                  w = obj.sections[43].w,
                  h = butt_h}
    f_Get_SSV('128 128 128')
    gfx.a = 0.5  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)
    
    butt_cntfx = math.floor((fx_h) / butt_h)
    for i = 0, butt_cntfx-1 do
    
      local c = gui.color.white
      local xywh = {x = obj.sections[43].x,
                    y = i * butt_h,
                    w = obj.sections[43].w,
                    h = butt_h}
      if preset[last_M][i] ~= nil then
        --if preset[last_M][i].active then
        if i == fxidx then
          f_Get_SSV(gui.color.blue1)
          gfx.a = 1  
          gfx.rect(xywh.x,
           xywh.y, 
           xywh.w,
           xywh.h, 1 )
          c = gui.color.black
        end
        GUI_textsm_LJ(gui, xywh, CropFXName(preset[last_M][i].fx_name), c)
      end
    end
    
    end  
  end
  
  ------------------------------------------------------------
  function GUI_Fade(gui)
    gfx.dest = 1

    gfx.a = 0.6
    f_Get_SSV(gui.color.black)
    gfx.rect(0,0, gfx1.main_w,gfx1.main_h,1)

    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)

  end
      
  function GUI_draw(obj, gui)
    gfx.mode =4
    
    if not settings_state then
      
      local actcnt 
      if update_gfx then   
        gfx.dest = 1
        gfx.setimgdim(1, -1, -1)  
        gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)  
        -- gradient
          --gfx.gradrect(0,0, gfx1.main_w,gfx1.main_h, 1,1,1.6,0.5, 0,0,0.0008,0.00005, 0,0,0,-0.0005)
        -- rects
        f_Get_SSV(gui.color.backg)
        gfx.rect(0,0, gfx1.main_w,gfx1.main_h,1)
          gfx.a = 1
  
        if pick_state then
          f_Get_SSV(gui.color.grey)  
          gfx.rect(obj.sections[1].x,
           obj.sections[1].y + 2, 
           obj.sections[1].w - 6,
           obj.sections[1].h -2, 1 )
          --f_Get_SSV(gui.color.white)
          gfx.a = 1 
          GUI_textC_FIT(gui, obj.sections[1], 'GET FOCUSED FX', gui.color.white, 16)
        end
        
        -- generate pattern
          gfx.a = 0.6  
          f_Get_SSV(gui.color.red1)  
          roundrect(obj.sections[3].x,
           obj.sections[3].y + 2, 
           obj.sections[3].w,
           obj.sections[3].h -2, 8, 1, 1)
          GUI_textC_FIT(gui, obj.sections[3], 'RANDOMIZE',gui.color.black,18)
          
          gfx.a = 1  
          f_Get_SSV(gui.color.blue1)  
          gfx.rect(obj.sections[80].x + 8,
           obj.sections[80].y + 2, 
           obj.sections[80].w - 14,
           obj.sections[80].h -2, 1, 1, 1)
          if settings_restrictfx == 0 then
            GUI_textC_FIT(gui, obj.sections[80], 'ALL FX',gui.color.black,16)
          else
            if preset[last_M][settings_restrictfx] then
              GUI_textC_FIT(gui, obj.sections[80], 'FX: ' .. CropFXName(preset[last_M][settings_restrictfx].fx_name),gui.color.black,16)
            end
          end
          
          for i = 0, slotcnt - 1 do
            gfx.a = 1
            f_Get_SSV(gui.color.blue1)  
            roundrect(obj.sections[13+i].x,
             obj.sections[13+i].y + 2, 
             obj.sections[13+i].w,
             obj.sections[13+i].h -2, 8, 1, 0 )
            GUI_textC_FIT(gui, obj.sections[13+i], 'CAPTURE ' .. string.char(65 + i),gui.color.blue1,14)
          end
   
          local c,c2,f,m
          for i = 0, 15 do
            gfx.a = 1
            f=1
            m = 0
            if last_M == i+1 then
              --gfx.a = 1
              m = GetMSlotMuted(i+1)
              if m == 2 then
                c2 = gui.color.red1
              elseif m == 1 then
                c2 = gui.color.red2
              end
              f_Get_SSV(gui.color.blue1)
              c = gui.color.black
            elseif preset[i+1][1] then
              m = GetMSlotMuted(i+1)
              if m == 2 then
                c2 = gui.color.red1
              elseif m == 1 then
                c2 = gui.color.red2
              end
              f_Get_SSV(gui.color.yellow1)
              c = gui.color.black
            else
              f_Get_SSV(gui.color.red1)
              c = gui.color.red1
              f = 0
              gfx.a = (1-(0.8*(((16-(i))/16))+0.2)) * 0.45 + 0.05
            end
            
            gfx.rect(obj.sections[44+i].x,
                     obj.sections[44+i].y + 2, 
                     obj.sections[44+i].w,
                     obj.sections[44+i].h -2, f, 1, 1)
            if m > 0 then
              f_Get_SSV(c2)
              gfx.rect(obj.sections[44+i].x+2,
                       obj.sections[44+i].y + 4, 
                       6,6,
                       1, 1, 1)
            end                    
            GUI_textC(gui, obj.sections[44+i], 'P' .. i+1, c, -2)
            if m > 0 then
            
            end 
          end
          
          if not pick_state then
            gfx.a = 1
            if write_state then
              f_Get_SSV(gui.color.red1)  
              gfx.rect(obj.sections[40].x,
               obj.sections[40].y + 2, 
               obj.sections[40].w,
               obj.sections[40].h -2, 1 )
              gfx.a = 1
              GUI_textC_FIT(gui, obj.sections[40], 'STOP REC', gui.color.white, 16)
            else
              f_Get_SSV(gui.color.grey)  
              gfx.rect(obj.sections[40].x,
               obj.sections[40].y + 2, 
               obj.sections[40].w,
               obj.sections[40].h -2, 1 )
              gfx.a = 1
              GUI_textC_FIT(gui, obj.sections[40], 'REC AUTOMATION', gui.color.white, 16)
            end
          end

          gfx.a = 0.8
          
          if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].params ~= nil then
            if settings_restrictfx == 0 then
              local bypassed, active = 0, 0
              for i = 1, #preset[last_M] do
                if preset[last_M][i].tracknumberOut ~= nil then
                  local track = reaper.GetTrack(0,preset[last_M][i].tracknumberOut-1)              
                  if track and reaper.TrackFX_GetEnabled(track, preset[last_M][i].fxnumberOut) then
                    active = active + 1
                  else
                    bypassed = bypassed + 1
                  end
                end
              end
              if bypassed == 0 then
                --all active
                f_Get_SSV(gui.color.grey1)
                c = gui.color.white  
              elseif active == 0 then
                --all bypassed
                f_Get_SSV(gui.color.red1)  
                c = gui.color.black
              else
                --partial
                f_Get_SSV(gui.color.yellow1)  
                c = gui.color.black
              end
              gfx.rect(obj.sections[69].x,
                 obj.sections[69].y+2, 
                 obj.sections[69].w,
                 obj.sections[69].h-2, true )
            
            else
              local track = reaper.GetTrack(0,preset[last_M][settings_restrictfx].tracknumberOut-1)              
              if track and reaper.TrackFX_GetEnabled(track, preset[last_M][settings_restrictfx].fxnumberOut) then
                f_Get_SSV(gui.color.grey1)  
                gfx.a = 1
                gfx.rect(obj.sections[69].x,
                 obj.sections[69].y + 2, 
                 obj.sections[69].w,
                 obj.sections[69].h -2, true )
                c = gui.color.white
              else
                f_Get_SSV(gui.color.red1)  
                gfx.a = 1
                gfx.rect(obj.sections[69].x,
                 obj.sections[69].y + 2, 
                 obj.sections[69].w,
                 obj.sections[69].h -2, true )
                c = gui.color.black
              end
            end
            
            GUI_textC(gui, obj.sections[69], 'M', c, -2)
          end
          
          if not pick_state then
            gfx.a = 1
            f_Get_SSV(gui.color.grey)  
            gfx.rect(obj.sections[110].x - 6,
             obj.sections[110].y + 2, 
             obj.sections[110].w + 6,
             obj.sections[110].h -2, 1 )

            gfx.a = 1
            f_Get_SSV(gui.color.grey)  
            gfx.rect(obj.sections[60].x,
             obj.sections[60].y + 2, 
             obj.sections[60].w,
             obj.sections[60].h -2, 1 )
            gfx.a = 1
            GUI_textC_FIT(gui, obj.sections[60], 'SETTINGS', gui.color.white, 16)

            gfx.a = 1
            f_Get_SSV(gui.color.grey)  
            gfx.rect(obj.sections[111].x,
             obj.sections[111].y + 2, 
             obj.sections[111].w,
             obj.sections[111].h -2, 1 )
            gfx.a = 1
            GUI_textC_FIT(gui, obj.sections[111], 'SAVE', gui.color.white, 16)
          end
          
          if pick_state then
            gfx.a = 1
            f_Get_SSV(gui.color.grey)  
            gfx.rect(obj.sections[10].x,
             obj.sections[10].y + 2, 
             obj.sections[10].w,
             obj.sections[10].h -2, 1 )
            gfx.a = 1
            GUI_textC_FIT(gui, obj.sections[10], 'SELECT ALL PARAMS', gui.color.white, 16)
            gfx.a = 1
            f_Get_SSV(gui.color.grey)  
            gfx.rect(obj.sections[11].x,
             obj.sections[11].y + 2, 
             obj.sections[11].w,
             obj.sections[11].h -2, 1 )
            gfx.a = 1
            GUI_textC_FIT(gui, obj.sections[11], 'SELECT ALL EXCEPT PROTECTED', gui.color.white, 16)
          end
          
        -- pick
          
          gfx.a = 1
          f_Get_SSV(gui.color.grey)  
          gfx.rect(obj.sections[2].x,
           obj.sections[2].y + 2, 
           obj.sections[2].w - 6,
           obj.sections[2].h -2, 1 )
          gfx.a = 1
          if not pick_state then 
            GUI_textC_FIT(gui, obj.sections[2], 'SETUP P'..last_M, gui.color.white, 16)
          else 
            if not pick_state_cnt then pick_state_cnt = 0 end
            GUI_textC_FIT(gui, obj.sections[2], 'SELECT P'..last_M..' FX & PARAMS', gui.color.white, 16)
          end
          
        f_Get_SSV(gui.color.black)
        gfx.rect(obj.sections[75].x ,
                        obj.sections[75].y, 
                        obj.sections[75].w,
                        obj.sections[75].h, true)
        if preset[last_M].settings_morphsync then
          GUI_textC(gui, obj.sections[75], "MORPH TIME     " .. tostring(sync_table[preset[last_M].morph_sync]), gui.color.white, -2)
        else
          GUI_textC(gui, obj.sections[75], "MORPH TIME     " .. tostring(math.floor(preset[last_M].morph_fader * 10) * 0.1) .. "s", gui.color.white, -2)
        end

        local c
        if preset[last_M].settings_morphsync then
          f_Get_SSV(gui.color.green1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)      
          c = gui.color.white
        end
        roundrect(obj.sections[82].x ,
                        obj.sections[82].y, 
                        obj.sections[82].w,
                        obj.sections[82].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[82], "SYNC", c, -4)

        if triggerhold > 0 then
          f_Get_SSV(gui.color.yellow1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)      
          c = gui.color.white
        end
        roundrect(obj.sections[112].x ,
                        obj.sections[112].y, 
                        obj.sections[112].w,
                        obj.sections[112].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[112], seq_triggerhold[triggerhold+1], c, -4)
        
        --if preset[last_M].settings_morphshape then
          f_Get_SSV(gui.color.green1)              
          c = gui.color.black
        --else
        --  f_Get_SSV(gui.color.dgrey1)      
        --  c = gui.color.white
        --end
        roundrect(obj.sections[83].x ,
                        obj.sections[83].y, 
                        obj.sections[83].w,
                        obj.sections[83].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[83], shape_table[preset[last_M].morph_shape], c, -4)

        
        if preset[last_M].settings_morphrebound then
          f_Get_SSV(gui.color.green1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)
          c = gui.color.white
        end
        roundrect(obj.sections[77].x ,
                        obj.sections[77].y, 
                        obj.sections[77].w,
                        obj.sections[77].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[77], "REBOUND", c, -4)

        if preset[last_M].settings_morphretrigger then
          f_Get_SSV(gui.color.green1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)
          c = gui.color.white
        end
        roundrect(obj.sections[78].x ,
                        obj.sections[78].y, 
                        obj.sections[78].w,
                        obj.sections[78].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[78], "RETRIGGER", c, -4)

        if preset[last_M].settings_morphloop then
          f_Get_SSV(gui.color.green1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)
          c = gui.color.white
        end
        roundrect(obj.sections[79].x ,
                        obj.sections[79].y, 
                        obj.sections[79].w,
                        obj.sections[79].h, 1, 1, 1)
        GUI_textC(gui, obj.sections[79], "LOOP", c, -4)

        if morph_time[last_M] > 0 then
          f_Get_SSV(gui.color.red1)
          roundrect(obj.sections[81].x ,
                          obj.sections[81].y, 
                          obj.sections[81].w,
                          obj.sections[81].h, 1, 1, 1)
          GUI_textC(gui, obj.sections[81], "STOP", gui.color.black, -4)
        else
          f_Get_SSV(gui.color.dgrey1)
          roundrect(obj.sections[81].x ,
                          obj.sections[81].y, 
                          obj.sections[81].w,
                          obj.sections[81].h, 1, 1, 1)
        end      
        
        c = gui.color.white
        if seq_state >= 1 then
          f_Get_SSV(gui.color.green1)
          c = gui.color.black
        else
          f_Get_SSV(gui.color.dgrey1)      
        end
        roundrect(obj.sections[100].x ,
                        obj.sections[100].y, 
                        obj.sections[100].w,
                        obj.sections[100].h, 1, 1, 1)
        GUI_textC_FIT(gui, obj.sections[100], "SEQUENCER", c, 14)

        --PLAY GRP PLAY BTN
        local size = 10
        local xo = obj.sections[107].w / 8
        local xywh = {x = 0,
                      y = obj.sections[107].y, 
                      w = xo - 2,
                      h = obj.sections[107].h}
        for i = 1, 8 do
          xywh.x = obj.sections[107].x + (xo * (i-1))
          f_Get_SSV(gui.color.yellow1)
          gfx.a = 1 
          --[[if grp_state[i] == 1 then
            gfx.a = time
            f_Get_SSV('0 255 0')
          elseif grp_state[i] == 2 then
            f_Get_SSV('0 255 0')
          end    ]]          
          roundrect(xywh.x,
                    xywh.y, 
                    xywh.w,
                    xywh.h, 1, 1, 0)
          --f_Get_SSV(gui.color.white)
          gfx.triangle(obj.sections[107].x + (xo * (i-1)) + ((xo - 2)/2) - size/2 -4,
                       obj.sections[107].y + obj.sections[107].h/2 - size/2,
                       obj.sections[107].x + (xo * (i-1)) + ((xo - 2)/2) - size/2 -4,
                       obj.sections[107].y + obj.sections[107].h/2 + size/2,
                       obj.sections[107].x + (xo * (i-1)) + ((xo - 2)/2) + size/2 -4,
                       obj.sections[107].y + obj.sections[107].h/2)
          GUI_textC_FIT_RJ(gui, xywh, i, gui.color.yellow1, 14, xywh.w/8)
        end
        
        f_Get_SSV(gui.color.red1)              
        roundrect(obj.sections[108].x ,
                        obj.sections[108].y, 
                        obj.sections[108].w,
                        obj.sections[108].h, 1, 1, 0)
        --f_Get_SSV(gui.color.white)
        gfx.rect(obj.sections[108].x + obj.sections[108].w/2 - size/2,
                 obj.sections[108].y + obj.sections[108].h/2 - size/2,
                 size, size)
        
        if seq_state >= 1 then

          local c = gui.color.white
          if seq[last_M][seq[last_M].selected].loop then
            f_Get_SSV(gui.color.green1)              
            c = gui.color.black
          else
            f_Get_SSV(gui.color.dgrey1)      
          end
          roundrect(obj.sections[105].x ,
                          obj.sections[105].y, 
                          obj.sections[105].w,
                          obj.sections[105].h, 1, 1, 1)
          GUI_textC_FIT(gui, obj.sections[105], "SEQ LOOP", c, 14)

          if seq[last_M][seq[last_M].selected].speedmult > 4 then
            f_Get_SSV(gui.color.green1)              
            c = gui.color.black
          elseif seq[last_M][seq[last_M].selected].speedmult < 4 then
            f_Get_SSV(gui.color.red1)              
            c = gui.color.black
          else
            f_Get_SSV(gui.color.dgrey1)      
            c = gui.color.white
          end
          roundrect(obj.sections[106].x ,
                          obj.sections[106].y, 
                          obj.sections[106].w,
                          obj.sections[106].h, 1, 1, 1)
          GUI_textC_FIT(gui, obj.sections[106], "SPD: " .. seq_speedmulttxt[seq[last_M][seq[last_M].selected].speedmult], c, 14)

          local ap
          if seq[last_M][seq[last_M].selected].autoplay > 0 then
            f_Get_SSV(gui.color.yellow1)
            ap = tostring(seq[last_M][seq[last_M].selected].autoplay)
            c = gui.color.black
          else
            f_Get_SSV(gui.color.dgrey1)
            c = gui.color.white
            ap = "OFF"
          end
          roundrect(obj.sections[109].x ,
                          obj.sections[109].y, 
                          obj.sections[109].w,
                          obj.sections[109].h, 1, 1, 1)
          GUI_textC_FIT(gui, obj.sections[109], "PLAY GRP: " .. ap, c, 14)
          
        elseif seq_state == 0 then
        
          f_Get_SSV(gui.color.black)
          gfx.rect(obj.sections[120].x,
                  obj.sections[120].y, 
                  obj.sections[120].w,
                  obj.sections[120].h-4, true)

          actcnt = 0
          for Fxi = 1, #preset[last_M] do
            if preset[last_M][Fxi].param_actidx then
              actcnt = actcnt + #preset[last_M][Fxi].param_actidx
            end
          end        

          local pcnt = 0
          for Fxi = 1, #preset[last_M] do
            if preset[last_M][Fxi].param_actidx then
              
              local xywh = {x = pcnt * (obj.sections[120].w / actcnt),
                            y = obj.sections[120].y,
                            w = 100,
                            h = obj.sections[120].h-4}
              GUI_textsm2_LJ(gui, xywh, string.upper(CropFXName(preset[last_M][Fxi].fx_name)), gui.color.yellow1, -4)
              pcnt = pcnt + #preset[last_M][Fxi].param_actidx
            end
          end
        
        end
      end
        --   
      
      if update_gfx or update_morph or update_slots or update_seq or update_seqgrid or update_seqplay or update_disp or update_misc or update_print then
  
        if not update_gfx then       
          gfx.dest = 1
        end

        if update_gfx or update_misc then
          gfx.a = 1
          f_Get_SSV(gui.color.blue1)
          gfx.rect(obj.sections[113].x,
                    obj.sections[113].y, 
                    obj.sections[113].w * chaos,
                    obj.sections[113].h, true)
          f_Get_SSV(gui.color.dblue1)
          gfx.rect(obj.sections[113].x + (obj.sections[113].w * chaos),
                    obj.sections[113].y, 
                    obj.sections[113].w - (obj.sections[113].w * chaos),
                    obj.sections[113].h, true)
          local c = gui.color.white
          if chaos > 0.6 then
            c = gui.color.black
          end
          GUI_textC(gui, obj.sections[113], 'STUTTER        <  >        SMOOTH', c, -4)

          --[[gfx.a = 1
          f_Get_SSV(gui.color.blue1)
          gfx.rect(obj.sections[114].x,
                    obj.sections[114].y, 
                    obj.sections[114].w * morphratepos,
                    obj.sections[114].h, true)
          f_Get_SSV(gui.color.dblue1)
          gfx.rect(obj.sections[114].x + (obj.sections[114].w * morphratepos),
                   obj.sections[114].y, 
                    obj.sections[114].w - (obj.sections[114].w * morphratepos),
                    obj.sections[114].h, true)
          local c = gui.color.white
          if morphratepos > 0.6 then
            c = gui.color.black
          end
          GUI_textC(gui, obj.sections[114], morphrate, c, -4)]]

        end
                
        if update_gfx or update_disp then
  
          --screen        
          gfx.a = 1 
          f_Get_SSV(gui.color.black)  
          roundrect(obj.sections[90].x,
           obj.sections[90].y , 
           obj.sections[90].w ,
           obj.sections[90].h , 10, 1, 1)

          f_Get_SSV(gui.color.yellow1)
          gfx.roundrect(obj.sections[90].x,
           obj.sections[90].y , 
           obj.sections[90].w ,
           obj.sections[90].h , 10, 1)
        
          if disp_notify ~= nil then
          
            GUI_textC_FIT(gui, obj.sections[90], disp_notify, gui.color.bryellow, 20)          
            disp_notify = nil
          
          elseif disp_notify2 ~= nil then
          
            GUI_textC_FIT(gui, obj.sections[90], disp_notify2, gui.color.bryellow, 20)          
            disp_notify2 = nil
            
          elseif fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].params ~= nil then
            local fx_name, param_name, c = Disp_FXName, Disp_ParamName, gui.color.bryellow
            if MR_over == "" then
              --fx_name = CropFXName(preset[last_M][fxidx].fx_name) 
              if not preset[last_M].active then
                --c = gui.color.red
              end
            else
              fx_name = MR_over
              param_name = ""
              local i
              for i = 1, #preset[MR_lastover] do
                param_name = param_name .. "   " .. CropFXName(preset[MR_lastover][i].fx_name)
              end
              c = gui.color.blue
            end
            if fx_name == nil then
              fx_name = "<EMPTY>"
            end
            
            GUI_textC(gui, obj.sections[42], fx_name, c, 2)
            GUI_textC_FIT(gui, obj.sections[68], param_name .. "     " .. Disp_ParamV, c, 16)
            disp_lastover = 0
          end
        end
      
        if update_gfx or update_slots then
          local c
          if #preset[last_M] > 0 then
            if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].S_params and preset[last_M][fxidx].S_params[0] ~= nil then
              if preset[last_M].use_params == 0 then
                f_Get_SSV(gui.color.blue1)
                c = gui.color.black 
              else
                f_Get_SSV(gui.color.backg)
                c = gui.color.blue1
              end
              gfx.a = 0.5
              roundrect(obj.sections[7].x,
                        obj.sections[7].y + 2,
                        obj.sections[7].w ,
                        obj.sections[7].h - 2, 8, 1, 1, 1)          
              GUI_textC_FIT(gui, obj.sections[7], 'RANDOM', c, 16)
  
              if preset[last_M].use_params2 == 0 and seq[last_M].running == 0 then
                f_Get_SSV(gui.color.red1) 
                c = gui.color.black 
              elseif morph_time[last_M] > 0 and morphtime[last_M] and morphtime[last_M].sslot == 0 then
                f_Get_SSV(gui.color.red2)               
                c = gui.color.black 
              elseif morph_time[last_M] > 0 and morphtime[last_M] and morphtime[last_M].eslot == 0 then
                f_Get_SSV(gui.color.red1)               
                c = gui.color.yellow 
              else
                f_Get_SSV(gui.color.backg) 
                c = gui.color.red1
              end
              gfx.a = 0.5
              roundrect(obj.sections[41].x,
                        obj.sections[41].y + 2,
                        obj.sections[41].w ,
                        obj.sections[41].h - 2, 8, 1, 1, 1)          
            end
          --if morphtime[last_M] and (morphtime[last_M].sslot == 0 or morphtime[last_M].eslot == 0) then
          --  c = f_Get_SSV(gui.color.yellow)
          --end
            GUI_textC_FIT(gui, obj.sections[41], 'RANDOM', c, 16)
          end  
  
          for i = 0, slotcnt - 1 do
            if #preset[last_M] > 0 then
              if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].S_params and preset[last_M][fxidx].S_params[i+1] ~= nil then
                
                if preset[last_M].use_params == i+1 then
                  f_Get_SSV(gui.color.blue1)
                  c = gui.color.black 
                else
                  f_Get_SSV(gui.color.backg) 
                  c = gui.color.blue1
                end
                gfx.a = 0.5
                roundrect(obj.sections[24+i].x,
                          obj.sections[24+i].y + 2,
                          obj.sections[24+i].w ,
                          obj.sections[24+i].h - 2, 8, 1, 1, 1)          
                GUI_textC_FIT(gui, obj.sections[24+i], string.char(65 + i), c, 40)
    
                if preset[last_M].use_params2 == i+1 and seq[last_M].running == 0 then
                  f_Get_SSV(gui.color.red1)
                  c = gui.color.black
                elseif morph_time[last_M] > 0 and morphtime[last_M] and i+1 == morphtime[last_M].sslot then
                  f_Get_SSV(gui.color.red2)
                  c = gui.color.black               
                elseif morph_time[last_M] > 0 and morphtime[last_M] and i+1 == morphtime[last_M].eslot then
                  f_Get_SSV(gui.color.red1)
                  c = gui.color.yellow              
                else
                  f_Get_SSV(gui.color.backg)
                  c = gui.color.red1 
                end
                gfx.a = 0.5
                roundrect(obj.sections[32+i].x,
                          obj.sections[32+i].y + 2,
                          obj.sections[32+i].w ,
                          obj.sections[32+i].h - 2, 8, 1, 1, 1)          
    
              end
              --if morphtime[last_M] and (morphtime[last_M].sslot == i+1 or morphtime[last_M].eslot == i+1) then
              --  c = gui.color.yellow
              --end
              GUI_textC_FIT(gui, obj.sections[32+i], string.char(65 + i), c, 40)
            end
          end
          
          if #preset[last_M] > 0 then
            c = gui.color.red1
            if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].S_params and preset[last_M][fxidx].S_params[0] ~= nil then
              --if preset[last_M].use_params2 == -1 then
              if seq[last_M].running > 0 then
                f_Get_SSV(gui.color.yellow1) 
                c = gui.color.black
              else
                f_Get_SSV(gui.color.backg) 
              end
              gfx.a = 0.5
              roundrect(obj.sections[101].x,
                        obj.sections[101].y + 2,
                        obj.sections[101].w ,
                        obj.sections[101].h - 2, 8, 1, 1, 1)          
            end
            GUI_textC_FIT(gui, obj.sections[101], 'SEQUENCE', c, 16)
          end                  
        end
        
        gfx.a = 1
        f_Get_SSV(gui.color.black)
        gfx.rect(obj.sections[76].x ,
                        obj.sections[76].y, 
                        obj.sections[76].w,
                        obj.sections[76].h, true)

        -- gfx rand
        --local actcnt = 0
        if seq_state == 0 then
          gfx.a = 1
          f_Get_SSV(gui.color.black)
          gfx.rect(obj.sections[4].x ,
                    obj.sections[4].y-4, 
                    obj.sections[4].w,
                    obj.sections[4].h+8, true)
          gfx.rect(obj.sections[5].x ,
                    obj.sections[5].y-4, 
                    obj.sections[5].w,
                    obj.sections[5].h+8, true)
          f_Get_SSV(gui.color.red1)
          gfx.rect(obj.sections[4].x ,
                          obj.sections[4].y-6, 
                          obj.sections[4].w,
                          1, true)
          gfx.rect(obj.sections[4].x ,
                          obj.sections[5].y + obj.sections[5].h + 4, 
                          obj.sections[4].w,
                          1, true)
  
          if not update_gfx then
            actcnt = 0
            for Fxi = 1, #preset[last_M] do
              if preset[last_M][Fxi].param_actidx then
                actcnt = actcnt + #preset[last_M][Fxi].param_actidx
              end
            end        
          end
          local rcnt = 1
          local pcnt = 1
          for Fxi = 1, #preset[last_M] do
              if preset[last_M][Fxi] and preset[last_M][Fxi].params ~= nil then
                if preset[last_M][Fxi].S_params[preset[last_M].use_params2] ~= nil then
                  local dh 
                  for i = 1, #preset[last_M][Fxi].param_actidx do
                    local idx = preset[last_M][Fxi].param_actidx[i]
                    if preset[last_M][Fxi].params[idx].is_act then
                      gfx.a = (0.6 * preset[last_M].morph_val+0.4) * (0.7 * (rcnt / actcnt) + 0.3)
                      f_Get_SSV(gui.color.red3)
                      dh = math.floor(obj.sections[5].h * preset[last_M][Fxi].S_params[preset[last_M].use_params2][idx].val)  
                      gfx.rect((rcnt-1)*obj.sections[5].w / actcnt,
                                       obj.sections[5].y + obj.sections[5].h -dh, 
                                       obj.sections[5].w / actcnt - 1,
                                       dh, true)
                      if preset[last_M].morph_val ~= nil then 
                        if preset[last_M][Fxi].S_params[preset[last_M].use_params] ~= nil then
                          local dy = preset[last_M][Fxi].S_params[preset[last_M].use_params][idx].val 
                                    + ((preset[last_M][Fxi].S_params[preset[last_M].use_params2][idx].val 
                                    - preset[last_M][Fxi].S_params[preset[last_M].use_params][idx].val) * preset[last_M].morph_val)
                          local y = obj.sections[5].y + obj.sections[5].h * (1 - dy)
                          local x = (rcnt-1)*obj.sections[5].w / actcnt  
                          gfx.a = 0.6
                          f_Get_SSV(gui.color.blue1)  
                          gfx.line(x, 
                                    y,
                                    x + (obj.sections[5].w / actcnt)-2, 
                                    y, 4)
                        end
                      end
                      rcnt = rcnt + 1
                    end
                  end
                end          
          
                -- gfx defaults
                if preset[last_M][Fxi].S_params[preset[last_M].use_params] ~= nil then
                  local dh
                  for i = 1, #preset[last_M][Fxi].param_actidx do
                    local idx = preset[last_M][Fxi].param_actidx[i]             
                     if preset[last_M][Fxi].params[idx].is_act then
                      f_Get_SSV(gui.color.blue1)
                      gfx.a = (1.4-((0.6 * (preset[last_M].morph_val)+0.4))) * (0.7 * ((actcnt - pcnt) / actcnt) + 0.3)
                      dh = math.floor(obj.sections[4].h * preset[last_M][Fxi].S_params[preset[last_M].use_params][idx].val)  
                      gfx.rect((pcnt-1)*obj.sections[4].w / actcnt,
                        obj.sections[4].y + obj.sections[4].h -dh, 
                        obj.sections[4].w / actcnt - 1,
                        dh, true)
        
                      if preset[last_M].morph_val ~= nil and preset[last_M][Fxi].S_params[preset[last_M].use_params2] ~= nil then 
                        local dy = preset[last_M][Fxi].S_params[preset[last_M].use_params][idx].val + ((preset[last_M][Fxi].S_params[preset[last_M].use_params2][idx].val - preset[last_M][Fxi].S_params[preset[last_M].use_params][idx].val) * preset[last_M].morph_val)
                        local y = obj.sections[4].y + obj.sections[4].h * (1 - dy)
                        local x = (pcnt-1)*obj.sections[4].w / actcnt  
                        gfx.a = 0.6
                        f_Get_SSV(gui.color.red)  
                        gfx.line(x, 
                                  y,
                                  x + (obj.sections[4].w / actcnt)-2, 
                                  y, 4)
                      end
                      pcnt = pcnt + 1
                    end
                  end
                end
              end    
            --end
          end
        elseif seq_state == 1 or seq_state == 2 then --seq

          if update_gfx or update_seqplay then
            local i, c
            local xywh = {x = obj.sections[104].x, y = obj.sections[104].y, w = obj.sections[104].w, h = obj.sections[104].h}
            xywh.w = (obj.sections[104].w/4) - 2
            for i = 1, 4 do
              c = gui.color.white
              if seq[last_M].selected == i then
                f_Get_SSV(gui.color.green1)
                c = gui.color.black
              elseif seq[last_M].running == i then
                f_Get_SSV(gui.color.yellow1)
                c = gui.color.black
              else 
                f_Get_SSV(gui.color.dgrey1)
              end
              xywh.x = obj.sections[104].x + ((i-1) * (xywh.w +2))
              roundrect(xywh.x,
                        xywh.y, 
                        xywh.w,
                        xywh.h, 1, 1, 1)
              GUI_textC(gui, xywh, i, c, -2)
            end
          end
          
          if update_gfx or update_seqgrid then
            f_Get_SSV(gui.color.black)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[4].y-4, 
                            obj.sections[4].w,
                            obj.sections[5].y + obj.sections[5].h - obj.sections[4].y +8, true)
            f_Get_SSV(gui.color.green_dark1)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[4].y-6, 
                            obj.sections[4].w,
                            1, true)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[5].y + obj.sections[5].h + 4, 
                            obj.sections[4].w,
                            1, true)
          end
  
          local i, steps, butt_h = _, 32, math.floor(obj.sections[102].h/6)        
          if update_gfx or update_seq or update_seqgrid then
            for i = 1, steps do
            
              local x = obj.sections[102].x + (math.floor(obj.sections[102].w/32)*(i-1))
              local xywh = {x = x, y = obj.sections[102].y - 18, w = obj.sections[102].w/steps - 1, h = 18}
              local c
              if i <= seq[last_M][seq[last_M].selected].steps then
                if seq[last_M].running == seq[last_M].selected then
                  if seq[last_M].currentstep == i then
                    f_Get_SSV(gui.color.yellow1)
                    gfx.rect(xywh.x,xywh.y,xywh.w,xywh.h, true)
                    GUI_textC(gui, xywh, i, gui.color.dblue1, -5)
                  else
                    f_Get_SSV(gui.color.black)
                    gfx.rect(xywh.x,xywh.y,xywh.w,xywh.h, true)                  
                    GUI_textC(gui, xywh, i, gui.color.blue, -5)
                  end
                else
                  f_Get_SSV(gui.color.black)
                  gfx.rect(xywh.x,xywh.y,xywh.w,xywh.h, true)                                  
                  GUI_textC(gui, xywh, i, gui.color.blue, -5)                
                end
                --c = gui.color.dblue1
              else
                GUI_textC(gui, xywh, i, gui.color.grey, -5)
                --c = gui.color.dgrey2
              end
            end
            
          end

          if update_gfx or update_seqgrid then

            --local i, steps, butt_h = _, 32, math.floor(obj.sections[102].h/6)
            local xywh = {x = 2, y = obj.sections[102].y, w = obj.sections[102].x-10, h = butt_h}
            GUI_textC_FIT_RJ(gui, xywh, "TARGET SLOT", gui.color.blue, 16, 8) 
            xywh.y = obj.sections[102].y + (butt_h + 1)
            GUI_textC_FIT_RJ(gui, xywh, "MORPH TIME", gui.color.blue, 16, 8) 
            xywh.y = obj.sections[102].y + (butt_h + 1) * 2
            GUI_textC_FIT_RJ(gui, xywh, "STEP SHAPE", gui.color.blue, 16, 8) 
            xywh.y = obj.sections[102].y + (butt_h + 1) * 3
            GUI_textC_FIT_RJ(gui, xywh, "STEP REBOUND", gui.color.blue, 16, 8) 
            xywh.y = obj.sections[102].y + (butt_h + 1) * 4
            GUI_textC_FIT_RJ(gui, xywh, "STEP LENGTH", gui.color.blue, 16, 8) 
            xywh.y = obj.sections[102].y + (butt_h + 1) * 5
            GUI_textC_FIT_RJ(gui, xywh, "START SLOT", gui.color.blue, 16, 8) 
            
            for i = 1, steps do
            
              local x = obj.sections[102].x + (math.floor(obj.sections[102].w/32)*(i-1))
              --local xywh = {x = x, y = obj.sections[102].y - 18, w = obj.sections[102].w/steps - 1, h = 18}
              local c
              if i <= seq[last_M][seq[last_M].selected].steps then
                c = gui.color.blue1
              else
                c = gui.color.dblue1 --dgrey2
              end
  
              local xywh = {}
              xywh[1] = {x = x, y = obj.sections[102].y, w = obj.sections[102].w/steps - 1, h = butt_h}
              xywh[2] = {x = x, y = obj.sections[102].y + (butt_h + 1), w = obj.sections[102].w/steps - 1, h = butt_h}
              xywh[3] = {x = x, y = obj.sections[102].y + (butt_h + 1) * 2, w = obj.sections[102].w/steps - 1, h = butt_h}
              xywh[4] = {x = x, y = obj.sections[102].y + (butt_h + 1) * 3, w = obj.sections[102].w/steps - 1, h = butt_h}
              xywh[5] = {x = x, y = obj.sections[102].y + (butt_h + 1) * 4, w = obj.sections[102].w/steps - 1, h = butt_h}
              xywh[6] = {x = x, y = obj.sections[102].y + (butt_h + 1) * 5, w = obj.sections[102].w/steps - 1, h = butt_h}
              
              f_Get_SSV(c)
              gfx.a = 0.7-(0.8*(((seq[last_M][seq[last_M].selected].steps-((i-1)%seq[last_M][seq[last_M].selected].steps))/seq[last_M][seq[last_M].selected].steps))+0.2)*0.7
              gfx.rect(xywh[1].x,xywh[1].y,xywh[1].w,xywh[1].h, true)
              gfx.rect(xywh[2].x,xywh[2].y,xywh[2].w,xywh[2].h, true)
              gfx.rect(xywh[3].x,xywh[3].y,xywh[3].w,xywh[3].h, true)
              gfx.rect(xywh[4].x,xywh[4].y,xywh[4].w,xywh[4].h, true)
              gfx.rect(xywh[5].x,xywh[5].y,xywh[5].w,xywh[5].h, true)
              gfx.rect(xywh[6].x,xywh[6].y,xywh[6].w,xywh[6].h, true)
              
              if i <= seq[last_M][seq[last_M].selected].steps then
                GUI_textC(gui, xywh[1], seq_step_table[seq[last_M][seq[last_M].selected][i].targetslot+1], gui.color.green, -2)
                GUI_textC_FIT(gui, xywh[2], sync_table[seq[last_M][seq[last_M].selected][i].stepmorphtime], gui.color.green, 14)
                GUI_textC_FIT(gui, xywh[3], shape_table[seq[last_M][seq[last_M].selected][i].stepshape], gui.color.green, 12)
                local t = ""
                if seq[last_M][seq[last_M].selected][i].steprebound then
                  t = "*"
                end
                GUI_textC(gui, xywh[4], t, gui.color.green, -6)              
                GUI_textC_FIT(gui, xywh[5], sync_table[seq[last_M][seq[last_M].selected][i].steplength], gui.color.yellow, 14)
                GUI_textC(gui, xywh[6], seq_step_table[seq[last_M][seq[last_M].selected][i].stepstartslot+1], gui.color.yellow, -2)
              end
            
            end
          end          
        
          if seq_state == 2 then
          
            if update_gfx or update_seqgrid then
              gfx.a = 0.7
              f_Get_SSV(gui.color.black)
              gfx.rect(obj.sections[4].x ,
                      obj.sections[4].y-4, 
                      obj.sections[4].w,
                      obj.sections[5].y + obj.sections[5].h - obj.sections[4].y +8, true)          
            end
            if update_seq then
              gfx.a = 0.7
              f_Get_SSV(gui.color.black)
              local xywh = {x = x, y = obj.sections[102].y - 18, w = obj.sections[102].w, h = 18}
              gfx.rect(xywh.x ,
                      xywh.y, 
                      xywh.w,
                      xywh.h, true)
            end
            
            if update_gfx or update_seqgrid or update_seq or update_print then
            
              gfx.a = 1
              f_Get_SSV(gui.color.black)
              roundrect(obj.sections[122].x ,
                        obj.sections[122].y, 
                        obj.sections[122].w,
                        obj.sections[122].h, 4, 1, 1)
              f_Get_SSV(gui.color.blue1)
              roundrect(obj.sections[122].x,
                        obj.sections[122].y, 
                        obj.sections[122].w,
                        obj.sections[122].h, 4, 1, 0)
            
              xywh = {x = obj.sections[123].x - 120, y = obj.sections[123].y, w = 120, h = obj.sections[123].h}
              GUI_textC_FIT_RJ(gui, xywh, 'QUALITY', gui.color.blue, 14, 10)
              xywh.y = obj.sections[124].y
              GUI_textC_FIT_RJ(gui, xywh, 'LENGTH DIVISOR', gui.color.blue, 14, 10)
              xywh.y = obj.sections[125].y
              GUI_textC_FIT_RJ(gui, xywh, 'LENGTH MULTIPLIER', gui.color.blue, 14, 10)
              
              local ww = obj.sections[123].w * print_quality
              f_Get_SSV(gui.color.dblue1)
              gfx.rect(obj.sections[123].x,obj.sections[123].y,obj.sections[123].w,obj.sections[123].h,1)
              f_Get_SSV(gui.color.blue1)
              gfx.rect(obj.sections[123].x,obj.sections[123].y,ww,obj.sections[123].h,1)
              local c = gui.color.white
              if print_quality >= 0.6 then
                c = gui.color.black
              end
              GUI_textC(gui, obj.sections[123], math.floor(print_quality*100) .. "%", c, -4)
              
              f_Get_SSV(gui.color.blue1)
              gfx.rect(obj.sections[124].x,obj.sections[124].y,obj.sections[124].w,obj.sections[124].h,1)
              GUI_textC(gui, obj.sections[124], sync_table[print_lendiv], gui.color.black, -4)

              f_Get_SSV(gui.color.blue1)
              gfx.rect(obj.sections[125].x,obj.sections[125].y,obj.sections[125].w,obj.sections[125].h,1)
              GUI_textC(gui, obj.sections[125], print_lenmult, gui.color.black, -4)

              f_Get_SSV(gui.color.blue)
              gfx.rect(obj.sections[126].x,obj.sections[126].y,obj.sections[126].w,obj.sections[126].h,1)
              GUI_textC(gui, obj.sections[126], 'PRINT SEQUENCE', gui.color.black, -4)
            
            end
            
          end

          --if update_gfx then
          gfx.a = 1
          local c = gui.color.blue
          f_Get_SSV(gui.color.blue1)
          if seq_state == 1 then
            roundrect(obj.sections[121].x,
                     obj.sections[121].y,
                     obj.sections[121].w,
                     obj.sections[121].h, 1, 1, 0)
          else
            roundrect(obj.sections[121].x,
                     obj.sections[121].y,
                     obj.sections[121].w,
                     obj.sections[121].h, 1, 1, 1)
            c = gui.color.black
          end
          GUI_textC_FIT(gui, obj.sections[121], 'PRINT SEQUENCE', c, 14)
          --end
          
        
--[[        elseif seq_state == 2 then

          if update_gfx then

            f_Get_SSV(gui.color.black)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[4].y-4, 
                            obj.sections[4].w,
                            obj.sections[5].y + obj.sections[5].h - obj.sections[4].y +8, true)
            f_Get_SSV(gui.color.green_dark1)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[4].y-6, 
                            obj.sections[4].w,
                            1, true)
            gfx.rect(obj.sections[4].x ,
                            obj.sections[5].y + obj.sections[5].h + 4, 
                            obj.sections[4].w,
                            1, true)

            f_Get_SSV(gui.color.blue1)
            gfx.rect(obj.sections[121].x,
                     obj.sections[121].y,
                     obj.sections[121].w,
                     obj.sections[121].h, false)
          end]]
          
        end
                
        -- val      
         if preset[last_M].morph_val ~= nil then 
          f_Get_SSV(gui.color.yellow1) 
          gfx.a = math.abs(preset[last_M].morph_val - 0.5)*1.5
          local width = (preset[last_M].morph_val - 0.5) * (obj.sections[76].w)
          if width >= 0 then
            gfx.rect(obj.sections[76].x + (obj.sections[76].w / 2),
                      obj.sections[76].y+4,
                      width,
                      obj.sections[76].h-8, 1)
          else
            gfx.rect(obj.sections[76].x + (obj.sections[76].w / 2) + width,
                      obj.sections[76].y+4,
                      -width,
                      obj.sections[76].h-8, 1)        
          end
          f_Get_SSV(gui.color.blue1)
          gfx.a = 1
          local Spos = (preset[last_M].morph_val) * (obj.sections[76].w - 4)
          gfx.rect(obj.sections[76].x + Spos,
                    obj.sections[76].y,
                    4,
                    obj.sections[76].h,4,1,1,1)
         end
         
      end 
      
      if pick_state then 
        gfx.a = time * 0.8
        f_Get_SSV(gui.color.red1) 
        gfx.rect(obj.sections[2].x,
                  obj.sections[2].y+2,
                  obj.sections[2].w-6,
                  obj.sections[2].h-2, 1)
        GUI_DrawPList(obj, gui)
      end

      if update_morph_time then
        gfx.dest = 1
        local mp
        local c, tc = _, gui.color.white
        if morphtime[last_M] ~= nil then
          if morph_time[last_M] > 0 then
            mp = (reaper.time_precise() - morphtime[last_M].st) / (morphtime[last_M].et - morphtime[last_M].st)
            if mp >= 1 then
              if preset[last_M].settings_morphrebound then
                mp = 0
                preset[last_M].use_params2 = morphtime[last_M].sslot 
              else 
                mp = 1 
                preset[last_M].use_params2 = morphtime[last_M].eslot 
              end
              c = gui.color.black
            else
              c = gui.color.yellow
            end
            tc = gui.color.black
          else
            mp = 0
            c = gui.color.black 
          end
        else
          mp = 1 
          c = gui.color.black 
        end
        local ww
        f_Get_SSV(c)
        if mp == 0 then
          gfx.a = 1
          ww = obj.sections[75].w
        else
          gfx.a = mp
          ww = obj.sections[75].w * mp
          f_Get_SSV(gui.color.black)        
          gfx.rect(obj.sections[75].x + ww,
                            obj.sections[75].y,
                            obj.sections[75].w - ww,
                            obj.sections[75].h, 1)

          f_Get_SSV(c)
        end
        gfx.rect(obj.sections[75].x,
                          obj.sections[75].y,
                          ww,
                          obj.sections[75].h, 1)

        
        if preset[last_M].settings_morphsync then
          GUI_textC(gui, obj.sections[75], "MORPH TIME     " .. tostring(sync_table[preset[last_M].morph_sync]), tc, -2)
        else
          GUI_textC(gui, obj.sections[75], "MORPH TIME     " .. tostring(math.floor(preset[last_M].morph_fader * 10) * 0.1) .. "s", tc, -2)
        end
        
        local lm
        
        if morph_time[last_M] > 0 then
          f_Get_SSV(gui.color.red1)
          roundrect(obj.sections[81].x ,
                          obj.sections[81].y, 
                          obj.sections[81].w,
                          obj.sections[81].h, 1, 1, 1)
          GUI_textC(gui, obj.sections[81], "STOP", gui.color.black, -4)
        else
          f_Get_SSV(gui.color.dgrey1)
          roundrect(obj.sections[81].x ,
                          obj.sections[81].y, 
                          obj.sections[81].w,
                          obj.sections[81].h, 1, 1, 1)
        end        
      end

      c = gui.color.yellow
      for lm = 1, #preset do
        if morphtime[lm] ~= nil then
          if morphtime[lm].st ~= nil then
            local mp = math.min((reaper.time_precise() - morphtime[lm].st) / (morphtime[lm].et - morphtime[lm].st),1)
            if morph_time[lm] > 0 then
            
              gfx.a = 0.2 + (mp*0.8)
              f_Get_SSV(c)
              gfx.rect(obj.sections[44+lm-1].x+8,
                       obj.sections[44+lm-1].y + obj.sections[44+lm-1].h +2, 
                       (obj.sections[44+lm-1].w-16) * mp,
                       4, true)  
              f_Get_SSV(gui.color.black)
              gfx.rect(obj.sections[44+lm-1].x+8 + ((obj.sections[44+lm-1].w-16) * mp),
                       obj.sections[44+lm-1].y + obj.sections[44+lm-1].h +2, 
                       obj.sections[44+lm-1].w-16 - ((obj.sections[44+lm-1].w-16) * mp),
                       4, true)
            end
          end
        end        
      end
      
    else
      
      --Settings
      
      if update_gfx then

        gfx.dest = 1
        --gfx.setimgdim(1, -1, -1)  
        --gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)  
        -- gradient
        --gfx.gradrect(0,0, gfx1.main_w,gfx1.main_h, 1,1,1.6,0.5, 0,0,0.0008,0.00005, 0,0,0,-0.0005)
 
        gfx.a = 1
        f_Get_SSV(gui.color.black)
        roundrect(obj.sections[1].x ,
                        obj.sections[1].y-31, 
                        obj.sections[1].w,
                        obj.sections[1].h+31, 40, 1, 1)
        f_Get_SSV(gui.color.blue1)  
        roundrect(obj.sections[1].x ,
                        obj.sections[1].y-31, 
                        obj.sections[1].w,
                        obj.sections[1].h+31, 40, 1, 0)


        gfx.a = 1
        f_Get_SSV(gui.color.blue1)  
        gfx.rect(obj.sections[60].x,
         obj.sections[60].y + 2, 
         obj.sections[60].w,
         obj.sections[60].h -2, 1 )
        GUI_textC_FIT(gui, obj.sections[60], 'SETTINGS', gui.color.white, 16)

        f_Get_SSV(gui.color.blue)
        --[[gfx.rect(obj.sections[2].x ,
                        obj.sections[2].y, 
                        obj.sections[2].w,
                        obj.sections[2].h, 0)]]
        gfx.a = 0.8
        f_Get_SSV(gui.color.white)
        GUI_text_size(gui, obj.sections[2], 'X', -12)
        
        local c
        local f
        
        if settings_autoopenfx then
          f = 1
          c = gui.color.black
        else
          f = 0
          c = gui.color.blue
        end
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[10].x ,
                        obj.sections[10].y, 
                        obj.sections[10].w,
                        obj.sections[10].h, f)
        gfx.a = 1
        GUI_textC(gui, obj.sections[10], 'Auto open active fx GUI', c, -2)

        if settings_delautomationpointsonunarm then
          f = 1
          c = gui.color.black
        else
          f = 0
          c = gui.color.blue
        end
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[11].x ,
                        obj.sections[11].y, 
                        obj.sections[11].w,
                        obj.sections[11].h, f)
        gfx.a = 1
        GUI_textC(gui, obj.sections[11], 'Delete env points at play position on disarm', c, -2)

        if settings_autoloadfxsettings then
          f = 1
          c = gui.color.black
        else
          f = 0
          c = gui.color.blue
        end
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[14].x ,
                        obj.sections[14].y, 
                        obj.sections[14].w,
                        obj.sections[14].h, f)
        gfx.a = 1
        GUI_textC(gui, obj.sections[14], 'Auto load default FX parameter settings', c, -2)

        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[12].x ,
                        obj.sections[12].y, 
                        obj.sections[12].w,
                        obj.sections[12].h, 0)
        gfx.a = 1
        c = gui.color.blue
        GUI_textC(gui, obj.sections[12], 'Record Automation Off Mode: ' .. automode_table[settings_automodeoff+1], c, -2)
        
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[13].x ,
                        obj.sections[13].y, 
                        obj.sections[13].w,
                        obj.sections[13].h, 0)
        gfx.a = 1
        c = gui.color.blue
        GUI_textC(gui, obj.sections[13], 'Record Automation On Mode: ' .. automode_table[settings_automodeon+1], c, -2)

        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[15].x ,
                        obj.sections[15].y, 
                        obj.sections[15].w,
                        obj.sections[15].h, 0)
        gfx.a = 1
        c = gui.color.blue
        GUI_textC(gui, obj.sections[15], 'Latency Adjust: ' .. latencyadjust*1000 .. 'ms', c, -2)

        f_Get_SSV(gui.color.red1)
        gfx.rect(obj.sections[59].x ,
                        obj.sections[59].y, 
                        obj.sections[59].w,
                        obj.sections[59].h, 0)
        gfx.a = 1
        c = gui.color.red
        GUI_textC(gui, obj.sections[59], 'RESET EVERYTHING', c, -2)

        if settings_showtips then
          f = 1
          c = gui.color.black
        else
          f = 0
          c = gui.color.blue
        end
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[16].x ,
                        obj.sections[16].y, 
                        obj.sections[16].w,
                        obj.sections[16].h, f)
        gfx.a = 1
        GUI_textC(gui, obj.sections[16], 'Show tooltips', c, -2)

        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[17].x ,
                        obj.sections[17].y, 
                        obj.sections[17].w,
                        obj.sections[17].h, 0)
        gfx.a = 1
        c = gui.color.blue
        GUI_textC(gui, obj.sections[17], dockpos_table[settings_docked+1], c, -2)

        if settings_playstop then
          f = 1
          c = gui.color.black
        else
          f = 0
          c = gui.color.blue
        end
        f_Get_SSV(gui.color.blue1)
        gfx.rect(obj.sections[18].x ,
                        obj.sections[18].y, 
                        obj.sections[18].w,
                        obj.sections[18].h, f)
        gfx.a = 1
        GUI_textC(gui, obj.sections[18], 'Play/Stop project on sequence start/stop', c, -2)

      end      
    end
      
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
      
    update_gfx = false
    update_morph = false
    update_slots = false
    update_morph_time = false
    update_seq = false
    update_seqgrid = false
    update_seqplay = false    
    update_disp = false
    update_misc = false
    update_print = false
    
  end
  
  ------------------------------------------------------------

  function GetMSlotMuted(idx)
  
    local i, mcnt, ret = _, 0, 0
    for i = 1, #preset[idx] do
      local pfx = "Preset_" .. idx .. "_FX_" .. i .. "_"
      local _, tracknumberOut = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_tracknumberOut")
      local _, fxnumberOut = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fxnumberOut")
      tracknumberOut = tonumber(tracknumberOut)
      fxnumberOut = tonumber(fxnumberOut)
      if tracknumberOut ~= nil then
        local track = reaper.GetTrack(0,tracknumberOut-1)
        local muted = not reaper.TrackFX_GetEnabled(track, fxnumberOut)
        if muted then
          mcnt = mcnt + 1
        end
      end
    end
    if mcnt == #preset[idx] then
      ret = 2
    elseif mcnt > 0 then
      ret = 1    
    else
      ret = 0
    end
    return ret
  end
  
  ------------------------------------------------------------
  
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("LBX Chaos Engine", w, h, 0, x, y)  
  end

 -------------------------------------------------------------     
      
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end   
  
  ------------------------------------------------------------
  
  function MOUSE_slider(b)
    if mouse.mx > b.x - 200 and mouse.mx < b.x+b.w + 200
      --and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB then
      --local ofs
      
     return math.floor(100*(mouse.mx - b.x) / (b.w))/100
    end 
  end

  ------------------------------------------------------------
  
  function MOUSE_sliderV(b)
    if mouse.my > b.y - 200 and mouse.my < b.y+b.h + 200
      --and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB then
      --local ofs
      
     return math.floor(100*(mouse.my - b.y) / (b.h))/100
    end 
  end
    
  ------------------------------------------------------------

  function MOUSE_sliderVMF(b)
    if mouse.LB or mouse.RB then
     return math.floor(100*(mouse.my+((b.h*32)/2) - b.y) / (b.h*32))/100
    end 
  end
    
  ------------------------------------------------------------

  function MOUSE_click(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB 
      and not mouse.last_LB then
     return true 
    end 
  end

  function MOUSE_click_RB(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.RB 
      and not mouse.last_RB then
     return true 
    end 
  end

  ------------------------------------------------------------
  
  function MOUSE_over(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h then
     return true 
    end 
  end

  ------------------------------------------------------------
    
  function GetProtectedState(track, fx, param)
    local _, buf = reaper.TrackFX_GetParamName( track, fx, param, '' )
    local t = {}
    for word in buf:gmatch('[%a]+') do t [#t+1] = word end
    if #t == 0 then return false end
    for i = 1, #t do
      local par_name = t[i]
      protect = false
      for j = 1, #protected_table do
        if par_name:lower():find(protected_table[j])~=nil then return true end
      end
    end 
    return false
  end
  
  ------------------------------------------------------------
  
  function ENGINE_ResetALL()
  
--[[    for i = 1, #preset do
      preset[i].active = false
      if preset[i][fxidx] then
        preset[i][fxidx].param_actidx = {}
        preset[i][fxidx].params = {}
        preset[i][fxidx].S_params = {}
        preset[i].fx = {}
      end
    end
    
    plist_offset = 0
    preset[last_M].use_params = 1
    preset[last_M].use_params2 = 1
    preset[last_M].morph_val = 0
    last_M = 1
    ]]
    --delete all proj settings
    reaper.SetProjExtState(0, SCRIPT_NAME, "", "")
    
    INITALL()
    
  end
  
  ------------------------------------------------------------

  function ENGINE_OpenPresetFX()

    for i = 1, preset[last_M].fxcnt do
      if preset[last_M][i] then
        local track = reaper.GetTrack(0,preset[last_M][i].tracknumberOut-1)    
        if not reaper.TrackFX_GetOpen(track, preset[last_M][i].fxnumberOut) then
          reaper.TrackFX_Show(track, preset[last_M][i].fxnumberOut, 3)
        end
      end
    end
  
  end

  ------------------------------------------------------------

  function ENGINE_ClosePresetFX()

    for i = 1, preset[last_M].fxcnt do
      if preset[last_M][i] then
        local track = reaper.GetTrack(0,preset[last_M][i].tracknumberOut-1)    
        if reaper.TrackFX_GetOpen(track, preset[last_M][i].fxnumberOut) then
          reaper.TrackFX_Show(track, preset[last_M][i].fxnumberOut, 2)
        end
      end
    end
  
  end

  ------------------------------------------------------------
  
  function ENGINE_Reset()
  
    if fxidx > 0 then
      if preset[last_M][fxidx] and preset[last_M][fxidx].params ~= nil then
        --Hide fx
        if preset[last_M][fxidx].tracknumberOut ~= nil then
          local track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
          if settings_autoopenfx then
            ENGINE_ClosePresetFX()
          end          
          if write_state then
            reaper.SetTrackAutomationMode(track, settings_automodeoff)
            DeleteLastEnvPoint(track, reaper.GetPlayPosition())
          end
        end
      end
    
      plist_offset = 0
      
      if preset[last_M][fxidx] ~= nil then
        preset[last_M][fxidx].param_actidx = {}
        preset[last_M][fxidx].S_params = {}
      end
      --preset[last_M][fxidx].S_params = {}
      --preset[last_M][fxidx] = nil
    end
    preset[last_M].use_params = 1
    preset[last_M].use_params2 = 1
    preset[last_M].morph_val = 0
  
  end

  ------------------------------------------------------------

  function DeleteLastEnvPoint(track, pos)
  
    if settings_delautomationpointsonunarm then 
      if preset[last_M][fxidx].param_actidx and #preset[last_M][fxidx].param_actidx > 0 then
        if track == nil then track = reaper.GetTrack(0, preset[last_M][fxidx].tracknumberOut-1) end
        if track == nil then return end 
        for i = 1, #preset[last_M][fxidx].param_actidx do
          local env = reaper.GetFXEnvelope(track, preset[last_M][fxidx].fxnumberOut, preset[last_M][fxidx].param_actidx[i]-1, false)
          if env then
            -- check play state (only do if recording automation (ie play/record)
            local pstate = reaper.GetPlayState()
            
            if pstate == 1 or pstate == 4 then
              reaper.DeleteEnvelopePointRange(env, pos, pos+0.6)
            end 
          end
        end
      
      end
    end
    
  end

  ------------------------------------------------------------
  
  function ENGINE_LoadedFX()

    local found = false
    local retval, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.GetTrack(0, tracknumberOut-1)
    if track == nil then return true end
    local guid =  reaper.TrackFX_GetFXGUID( track, fxnumberOut )
    for i = 1, preset[last_M].fxcnt do
    
      if tracknumberOut == preset[last_M][i].tracknumberOut and
         guid == preset[last_M][i].guid then
         found = true
         break
      end
    
    end
    
    return found
  
  end  
    
  ------------------------------------------------------------

  function ENGINE_GetParams()
    local params = {}
     
    local retval, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.GetTrack(0, tracknumberOut-1)
    if track == nil then return end
    params.active = true
    params.param_actidx = {}
    params.S_params = {}
    params.params = {}
    params.fxnumberOut = fxnumberOut
    params.guid =  reaper.TrackFX_GetFXGUID( track, params.fxnumberOut )
    params.tguid = reaper.GetTrackGUID( track)
    params.tracknumberOut = tracknumberOut
    _, params.fx_name =  reaper.TrackFX_GetFXName( track, params.fxnumberOut, '' )
    if retval ~= 1 or tracknumberOut <= 0 or params.fxnumberOut == nil then return end    
    local num_params = reaper.TrackFX_GetNumParams( track, params.fxnumberOut )
    if not num_params or num_params == 0 then return end    
    for i = 1, num_params do 
      local  is_prot = GetProtectedState(track, params.fxnumberOut, i-1 )
      local _, pname = reaper.TrackFX_GetParamName(track, params.fxnumberOut, i-1, '')
      params.params[i] =  {val = reaper.TrackFX_GetParamNormalized( track, params.fxnumberOut, i-1 ) ,
                    is_act = false,
                    is_protected = is_prot,
                    param_name = pname}
    end
    return params
  end
  
  ------------------------------------------------------------

  function ENGINE_GetParamsX(fxi)
    local params = {}
    --if def_params == nil then return end
    if fxi > 0 and preset[last_M][fxi].params == nil then return end
     
    local retval, tracknumberOut, fxnumberOut = 1, preset[last_M][fxi].tracknumberOut, preset[last_M][fxi].fxnumberOut
    if tracknumberOut ~= nil then
      local track = reaper.GetTrack(0, tracknumberOut-1)
      if track == nil then return end
--      params.fxnumberOut = fxnumberOut
--      params.guid =   reaper.TrackFX_GetFXGUID( track, params.fxnumberOut )
--      params.tguid = reaper.GetTrackGUID( track)
--      params.tracknumberOut = tracknumberOut
--      _, params.fx_name =  reaper.TrackFX_GetFXName( track, params.fxnumberOut, '' )
      if retval ~= 1 or tracknumberOut <= 0 or preset[last_M][fxi].fxnumberOut == nil then return end    
      local num_params = reaper.TrackFX_GetNumParams( track, preset[last_M][fxi].fxnumberOut )
      if not num_params or num_params == 0 then return end    
      for i = 1, num_params do 
        params[i] = {val = reaper.TrackFX_GetParamNormalized( track, preset[last_M][fxi].fxnumberOut, i-1 ) }
      end
    end
    return params
  end
  
  ------------------------------------------------------------
  
  function ENGINE_SetParams(last_M, rt, print)
  
    local fxidx
    local mp, mpv 
    local resetmt = false

    if morphtime[last_M] ~= nil then
      --local rt = reaper.time_precise()
      mp = F_limit((rt - morphtime[last_M].st) / ((morphtime[last_M].et - morphtime[last_M].st)),0,1)
      mpv = CalcShapeVal(last_M, mp, rt - morphtime[last_M].st, (morphtime[last_M].et - morphtime[last_M].st))
      --if mpv == preset[last_M].mp then return end 
      preset[last_M].mp = mpv
      --if mp<0 then
      --end
    end
    
    for fxidx = 1,preset[last_M].fxcnt do
  
      if preset[last_M] == nil then return end
      if preset[last_M][fxidx].params == nil then return end
      if preset[last_M][fxidx].S_params[preset[last_M].use_params] == nil then return end
      if preset[last_M][fxidx].S_params[preset[last_M].use_params2] == nil then return end
      if preset[last_M].morph_val == nil then return end
      
      local found = false
      track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
      _, fx_name = reaper.TrackFX_GetFXName( track, preset[last_M][fxidx].fxnumberOut, '' )
      guid =  reaper.TrackFX_GetFXGUID( track, preset[last_M][fxidx].fxnumberOut )
      tguid = reaper.GetTrackGUID(track)
      
      local track_num, fx_num
      
      if (preset[last_M][fxidx].tguid == tguid
         and preset[last_M][fxidx].guid == guid
         and preset[last_M][fxidx].fx_name == fx_name) then
      
        fx_num = preset[last_M][fxidx].fxnumberOut
        found = true
      
      else 
        --Search for plugin
        found, track_num, fx_num = FindFX(preset[last_M][fxidx].tguid, preset[last_M][fxidx].guid, false)
        if found then
          track = reaper.GetTrack(0,track_num)
          preset[last_M][fxidx].tracknumberOut = track_num+1
          preset[last_M][fxidx].fxnumberOut = fx_num
        end      
      end
      if found then
          if preset[last_M][fxidx].param_actidx ~= nil then
            if morph_time[last_M] == 0 then
              for i = 1, math.min(#preset[last_M][fxidx].param_actidx, max_params_count) do
                 reaper.TrackFX_SetParamNormalized( track, fx_num, preset[last_M][fxidx].param_actidx[i] - 1, 
                              preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val 
                              + (preset[last_M][fxidx].S_params[preset[last_M].use_params2][preset[last_M][fxidx].param_actidx[i]].val 
                              - preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val) * preset[last_M].morph_val
                          )
              end
            else--if mp >= 0 then 
              for i = 1, math.min(#preset[last_M][fxidx].param_actidx, max_params_count) do
  
                if morphtime[last_M] ~= nil then
                  
                  if mp >= 1 then
                    if preset[last_M].settings_morphrebound then
                      mp = 0
                    else
                      mp =1
                    end
                    resetmt = true
                  end
                  if preset[last_M][fxidx].S_params[morphtime[last_M].sslot] ~= nil 
                      and preset[last_M][fxidx].S_params[morphtime[last_M].eslot] ~= nil   then
                      
                    local val = preset[last_M][fxidx].S_params[morphtime[last_M].sslot][preset[last_M][fxidx].param_actidx[i]].val + 
                                              (preset[last_M][fxidx].S_params[morphtime[last_M].eslot][preset[last_M][fxidx].param_actidx[i]].val 
                                              - preset[last_M][fxidx].S_params[morphtime[last_M].sslot][preset[last_M][fxidx].param_actidx[i]].val) * mpv
                    reaper.TrackFX_SetParamNormalized( track, fx_num, preset[last_M][fxidx].param_actidx[i] - 1, 
                              preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val + 
                                (val - preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val) * preset[last_M].morph_val
                              )
                  end
                end
                          
              end          
            end
          end          
      else
        --not found
        --memslot[last_M] = false
      end
    end
    if resetmt then
      if not preset[last_M].settings_morphloop then
        morph_time[last_M] = 0
        morph_time_reset = true
        if preset[last_M].settings_morphrebound then        
          preset[last_M].use_params2 = morphtime[last_M].sslot
        else
          preset[last_M].use_params2 = morphtime[last_M].eslot        
        end
        ENGINE_SetParams(last_M, reaper.time_precise(), false) --ensure final morph settings are sent to plugin
      else
        --if not seq[last_M].running then
          if preset[last_M].settings_morphrebound then
            if seq[last_M].running > 0 then
              morph_time[last_M] = CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepmorphtime) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult]
            else
              morph_time[last_M] = preset[last_M].morph_fader
            end
            morphtime[last_M].st = morphtime[last_M].et
            morphtime[last_M].et = morphtime[last_M].et + morph_time[last_M]
            --morphtime[last_M].oet = morphtime[last_M].et
          else
            if seq[last_M].running > 0 then
              morph_time[last_M] = CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepmorphtime) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult]
            else
              morph_time[last_M] = preset[last_M].morph_fader
            end
            morphtime[last_M].st = morphtime[last_M].et
            morphtime[last_M].et = morphtime[last_M].et + morph_time[last_M]
            --morphtime[last_M].oet = morphtime[last_M].et
            local sslot = morphtime[last_M].sslot
            if mp > 0.5 then
              preset[last_M].use_params2 = morphtime[last_M].eslot
            else
              preset[last_M].use_params2 = morphtime[last_M].sslot
            end
            morphtime[last_M].sslot = morphtime[last_M].eslot
            morphtime[last_M].eslot = sslot
          end
        --end
      end
      gfx_forceupdate = true
    end
    
  end 
  
  ------------------------------------------------------------

  function FindFX(ptguid, pfxguid, forcechk)
  
    local tnum, fnum, found = -1,-1,false
    
    local tcnt = reaper.CountTracks(0)
    for t = 0, tcnt do
      local track = reaper.GetTrack(0,t)
      if track ~= nil then
        local tguid = reaper.GetTrackGUID(track, t)
        if tguid == ptguid or forcechk then
      
          local fcnt = reaper.TrackFX_GetCount(track)
          for f = 0, fcnt do
            local fguid = reaper.TrackFX_GetFXGUID(track, f)
            if fguid == pfxguid then
              tnum = t
              fnum = f
              found = true
              break
            end
          end
          if found then
            break
          end
        end
      end
    end
  
    return found, tnum, fnum
  end
  
  ------------------------------------------------------------
  
  function ENGINE_GenerateRandPatt(fxidx)
    if preset[last_M][fxidx].params ~= nil then 
      local rand = {}
      for i = 1, #preset[last_M][fxidx].params do
        if preset[last_M][fxidx].params[i].is_act then
            rand[i] = {val = math.random()}
        else
          rand[i] = {val = preset[last_M][fxidx].params[i].val}
        end
      end
      return rand
    end
  end
  
  ------------------------------------------------------------
  
  function ENGINE_OpenEnvs()
    if #preset[last_M] == 0 then return end
    if preset[last_M][fxidx].params == nil then return end
        
    track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
--    _, fx_name =  reaper.TrackFX_GetFXName( track, def_params.fxnumberOut, '' )
--    guid = reaper.TrackFX_GetFXGUID( track, fxnumberOut )
    if track ~= nil then
       
       max_params_count = 200
        for i = 1, math.min(#preset[last_M][fxidx].params, max_params_count) do
          if preset[last_M][fxidx].params[i].is_act then
             reaper.GetFXEnvelope(track, preset[last_M][fxidx].fxnumberOut, i-1, true)
          end
          
        end
        reaper.TrackList_AdjustWindows(0)
    reaper.UpdateArrange()
    end
  end 
  
  ------------------------------------------------------------
  
  function RunSequences(rt)
  
    if rt == nil then
      rt = reaper.time_precise()      
    end
    
  --SEQUENCE
  local i
  for i = 1, #seq do
    if seq[i].running > 0 then
    
      if rt < seq[i].stepet then
      --if reaper.time_precise() < seq[i].stepet then       
      else
        seq[i].currentstep = seq[i].currentstep + 1
        
        if seq[i].currentstep > seq[i][seq[i].running].steps then
          --loop or stop
          if seq[i][seq[i].running].loop then
            seq[i].currentstep = 1
            seq[i].stepst = seq[i].stepet
            seq[i].stepet = seq[i].stepet + (CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].steplength) * seq_speedmult[seq[i][seq[i].running].speedmult])
            
            preset[i].settings_morphrebound = seq[i][seq[i].running][seq[i].currentstep].steprebound
            preset[i].morph_shape = seq[i][seq[i].running][seq[i].currentstep].stepshape
  
            morph_time[i] = CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].stepmorphtime) * seq_speedmult[seq[i][seq[i].running].speedmult]
  
            local newsslot
            if seq[i][seq[i].running][seq[i].currentstep].stepstartslot < 9 then
              newsslot = seq[i][seq[i].running][seq[i].currentstep].stepstartslot
            else
              newsslot = seq[i][seq[i].running][seq[i][seq[i].running].steps].targetslot
            end
            
            local neweslot
            if seq[i][seq[i].running][seq[i].currentstep].targetslot < 9 then
              neweslot = seq[i][seq[i].running][seq[i].currentstep].targetslot
            else
              neweslot = newsslot
            end
              morphtime[i] = {st = seq[i].stepst,
                              et = seq[i].stepst + morph_time[i],
                              sslot = newsslot,
                              eslot = neweslot}
          else
            morph_time[i] = 0              
            seq[i].running = 0
            update_gfx = true
          end
          
        else
          seq[i].stepst = seq[i].stepet
          seq[i].stepet = seq[i].stepet + (CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].steplength) * seq_speedmult[seq[i][seq[i].running].speedmult])
          
          preset[i].settings_morphrebound = seq[i][seq[i].running][seq[i].currentstep].steprebound
          preset[i].morph_shape = seq[i][seq[i].running][seq[i].currentstep].stepshape
  
          morph_time[i] = CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].stepmorphtime) * seq_speedmult[seq[i][seq[i].running].speedmult]
  
          local newsslot 
          if seq[i][seq[i].running][seq[i].currentstep].stepstartslot < 9 then
            newsslot = seq[i][seq[i].running][seq[i].currentstep].stepstartslot
          else
            newsslot = seq[i][seq[i].running][seq[i].currentstep-1].targetslot
            local p = 2
            while newsslot == 9 and seq[i].currentstep-p >= 1 do
              newsslot = seq[i][seq[i].running][seq[i].currentstep-p].targetslot
              p=p+1
            end
          end
  
          local neweslot
          if seq[i][seq[i].running][seq[i].currentstep].targetslot < 9 then
            neweslot = seq[i][seq[i].running][seq[i].currentstep].targetslot
          else
            neweslot = newsslot
          end
  
          morphtime[i] = {st = seq[i].stepst,
                           et = seq[i].stepst + morph_time[i],
                           sslot = newsslot,
                           eslot = neweslot}
        end
        update_slots = true            
        update_seq = true
      end
      
    end
  end
  
end

  ------------------------------------------------------------    
  
  function run()  
    time = math.abs(math.sin( -1 + (os.clock() % 2)))
  
    if gfx.w ~= last_gfx_w or gfx.h ~= last_gfx_h then
      if gfx.w < 800 then gfx.w = 800 end
      if gfx.h < 450 then gfx.h = 450 end
      gfx1.main_w = gfx.w
      gfx1.main_h = gfx.h
      win_w = gfx.w
      win_h = gfx.h
      
      settings_state = false
      obj = GetObjects()
      update_gfx = true
      --reaper.ShowConsoleMsg("TTTTTTTTTTTT")
    end
  
    if not settings_state then
      if pick_state then
        --triggers redraw
        gfx.w = gfx1.main_w + 100
      end
      
      if gfx_forceupdate then
        gfx_forceupdate = false
        update_seq = true
        update_slots = true
        update_morph = true  
      end
      
      --local obj = GetObjects()
      local gui = GetGUI_vars()    
      GUI_draw(obj, gui)
      
      mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y  
      mouse.LB = gfx.mouse_cap&1==1 
      mouse.RB = gfx.mouse_cap&2==2 

      if MOUSE_click(obj.sections[107]) or MOUSE_click(obj.sections[101]) then
        if settings_playstop and reaper.GetPlayState() == 0 then
          reaper.OnPlayButton()
        end
      end
        
      local rt3, rt2 = reaper.time_precise(), _
      local rt = reaper.time_precise() + latencyadjust
      local trighold = false
      if triggerhold > 0 and ((reaper.GetPlayState() == 1 or reaper.GetPlayState() == 4)) then
        local pp = reaper.GetPlayPosition()
        local bt
        if triggerhold == 2 then
          bt = CalcBeatTime()
        else
          bt = CalcBarTime()
        end
        rt2 = reaper.time_precise() + (((math.floor(pp / bt) + 1) * bt)-pp)
        trighold = true
      end

      if MOUSE_click(obj.sections[107]) then
        local pidx = math.floor((mouse.mx - obj.sections[107].x) / (obj.sections[107].w / 8))+1
        --AUTOSTART
        local i, s
        if not trighold then
          --grp_state[pidx] = 2
          for i = 1, 16 do
            for s = 1, 4 do
              if #preset[i] > 0 and seq[i][s].autoplay == pidx then
                seq[i].running = s
                seq[i].currentstep = 1
                seq[i].stepst = rt
                seq[i].stepet = rt + (CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].steplength) * seq_speedmult[seq[i][seq[i].running].speedmult]) 
                --seq[i].ostepet = seq[i].stepet
                
                preset[i].settings_morphrebound = seq[i][seq[i].running][seq[i].currentstep].steprebound
                preset[i].morph_shape = seq[i][seq[i].running][seq[i].currentstep].stepshape
              
                morph_time[i] = CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].stepmorphtime) * seq_speedmult[seq[i][seq[i].running].speedmult]
        
                local newsslot
                if seq[i][seq[i].running][seq[i].currentstep].stepstartslot < 9 then
                  newsslot = seq[i][seq[i].running][seq[i].currentstep].stepstartslot
                else
                  newsslot = seq[i][seq[i].running][seq[i][seq[i].running].steps].targetslot
                end
                
                local neweslot
                if seq[i][seq[i].running][seq[i].currentstep].targetslot < 9 then
                  neweslot = seq[i][seq[i].running][seq[i].currentstep].targetslot
                else
                  neweslot = newsslot
                end
        
                morphtime[i] = {st = rt,
                                     et = rt + morph_time[i],
                                     --oet = rt + morph_time[i],
                                     sslot = newsslot,
                                     eslot = neweslot}
                update_slots = true
                update_seq = true
                update_seqplay = true
              end
            end
          end
        else
          for i = 1, 16 do
            for s = 1, 4 do
              if #preset[i] > 0 and seq[i][s].autoplay == pidx then
                local newsslot
                if seq[i][s][1].stepstartslot < 9 then
                  newsslot = seq[i][s][1].stepstartslot
                else
                  newsslot = seq[i][s][seq[i][s].steps].targetslot
                end
                
                local neweslot
                if seq[i][s][1].targetslot < 9 then
                  neweslot = seq[i][s][1].targetslot
                else
                  neweslot = newsslot
                end

                th_seq[#th_seq+1] = {type = type_seq,
                             i = i,
                             running = s,
                             currentstep = 1, 
                             stepst = rt2, 
                             stepet = rt2 + (CalcSyncTime(seq[i][s][1].steplength) * seq_speedmult[seq[i][s].speedmult]),
                             morphrebound = seq[i][s][1].steprebound,
                             morph_shape = seq[i][s][1].stepshape,
                             sslot = newsslot,
                             eslot = neweslot}
              end
            end
          end
        end
      end

      if MOUSE_click(obj.sections[108]) then
        if settings_playstop and reaper.GetPlayState() ~= 0 then
          reaper.OnStopButton()
        end
        local i
        for i = 1, 16 do
          morph_time[i] = 0
          seq[i].running = 0
          chaos_start = nil
          
          --ENGINE_SetParams()
          if morphtime[i] then
            local mp = (reaper.time_precise() - morphtime[i].st) / (morphtime[i].et - morphtime[i].st)
            if mp > 0.5 then
              preset[i].use_params2 = morphtime[i].eslot
            else
              preset[i].use_params2 = morphtime[i].sslot
            end
          end
        end
        update_gfx = true
      end
      
      if MOUSE_click(obj.sections[101]) then        
        if not trighold then
          if #preset[last_M] > 0 then
            seq[last_M].running = seq[last_M].selected
            seq[last_M].currentstep = 1
            seq[last_M].stepst = rt
            seq[last_M].stepet = rt + (CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].steplength) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult])
            --seq[last_M].ostepet = seq[last_M].stepet
            
            preset[last_M].settings_morphrebound = seq[last_M][seq[last_M].running][seq[last_M].currentstep].steprebound
            preset[last_M].morph_shape = seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepshape
          
            morph_time[last_M] = CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepmorphtime) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult]
    
            local newsslot
            if seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepstartslot < 9 then
              newsslot = seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepstartslot
            else
              newsslot = seq[last_M][seq[last_M].running][seq[last_M][seq[last_M].running].steps].targetslot
            end
            
            local neweslot
            if seq[last_M][seq[last_M].running][seq[last_M].currentstep].targetslot < 9 then
              neweslot = seq[last_M][seq[last_M].running][seq[last_M].currentstep].targetslot
            else
              neweslot = newsslot
            end
    
            morphtime[last_M] = {st = rt,
                                 et = rt + morph_time[last_M],
                                 --oet = rt + morph_time[last_M],
                                 sslot = newsslot,
                                 eslot = neweslot}
            update_slots = true
            update_seq = true
            update_seqplay = true
          end
        else
          i = last_M
          s = seq[i].selected
          if #preset[i] > 0 then
            local newsslot
            if seq[i][s][1].stepstartslot < 9 then
              newsslot = seq[i][s][1].stepstartslot
            else
              newsslot = seq[i][s][seq[i][s].steps].targetslot
            end
            
            local neweslot
            if seq[i][s][1].targetslot < 9 then
              neweslot = seq[i][s][1].targetslot
            else
              neweslot = newsslot
            end
            th_seq[#th_seq+1] = {type = type_seq,
                         i = i,
                         running = s,
                         currentstep = 1, 
                         stepst = rt2, 
                         stepet = rt2 + (CalcSyncTime(seq[i][s][1].steplength) * seq_speedmult[seq[i][s].speedmult]),
                         morphrebound = seq[i][s][1].steprebound,
                         morph_shape = seq[i][s][1].stepshape,
                         sslot = newsslot,
                         eslot = neweslot}
          end
        
        end
      end
    
      if MOUSE_click_RB(obj.sections[65]) then        
        local i = math.floor(mouse.mx / (obj.sections[44].w + 2)) +1                    
        if morph_time[i] then
          if morph_time[i] > 0 then 
            --STOP MORPH
            morph_time[i] = 0
            seq[i].running = 0
            
            --ENGINE_SetParams()
            local mp = (reaper.time_precise() - morphtime[i].st) / (morphtime[i].et - morphtime[i].st)
            if mp > 0.5 then
              preset[i].use_params2 = morphtime[i].eslot
            else
              preset[i].use_params2 = morphtime[i].sslot
            end
            update_gfx = true
          else
            if not trighold then
              --START MORPH
              if #preset[i] > 0 then
                seq[i].running = seq[i].selected
                seq[i].currentstep = 1
                seq[i].stepst = rt
                seq[i].stepet = rt + (CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].steplength) * seq_speedmult[seq[i][seq[i].running].speedmult])
                --seq[i].ostepet = seq[i].stepet

                preset[i].settings_morphrebound = seq[i][seq[i].running][seq[i].currentstep].steprebound
                preset[i].morph_shape = seq[i][seq[i].running][seq[i].currentstep].stepshape
                
                morph_time[i] = CalcSyncTime(seq[i][seq[i].running][seq[i].currentstep].stepmorphtime) * seq_speedmult[seq[i][seq[i].running].speedmult]
                
                local newsslot
                if seq[i][seq[i].running][seq[i].currentstep].stepstartslot < 9 then
                  newsslot = seq[i][seq[i].running][seq[i].currentstep].stepstartslot
                else
                  newsslot = seq[i][seq[i].running][seq[i][seq[i].running].steps].targetslot
                end
                
                local neweslot
                if seq[i][seq[i].running][seq[i].currentstep].targetslot < 9 then
                  neweslot = seq[i][seq[i].running][seq[i].currentstep].targetslot
                else
                  neweslot = newsslot
                end
                
                morphtime[last_M] = {st = rt,
                                     et = rt + morph_time[i],
                                     --oet = rt + morph_time[i],
                                     sslot = newsslot,
                                     eslot = neweslot}
                update_slots = true
                update_seq = true
                update_seqplay = true
              end
            else
              s = seq[i].selected
              if #preset[i] > 0 then
                local newsslot
                if seq[i][s][1].stepstartslot < 9 then
                  newsslot = seq[i][s][1].stepstartslot
                else
                  newsslot = seq[i][s][seq[i][s].steps].targetslot
                end
                
                local neweslot
                if seq[i][s][1].targetslot < 9 then
                  neweslot = seq[i][s][1].targetslot
                else
                  neweslot = newsslot
                end
    
                th_seq[#th_seq+1] = {type = type_seq,
                             i = i,
                             running = s,
                             currentstep = 1, 
                             stepst = rt2, 
                             stepet = rt2 + (CalcSyncTime(seq[i][s][1].steplength) * seq_speedmult[seq[i][s].speedmult]),
                             morphrebound = seq[i][s][1].steprebound,
                             morph_shape = seq[i][s][1].stepshape,
                             sslot = newsslot,
                             eslot = neweslot}
              end
            end
          end
        end        
      end

      if #th_seq > 0 then
        for i = 1, #th_seq do
          if th_seq[i] and th_seq[i].stepst <= reaper.time_precise() then
            local ii = th_seq[i].i
            if th_seq[i].type == type_seq then
              seq[ii].running = th_seq[i].running
              seq[ii].currentstep = th_seq[i].currentstep
              seq[ii].stepst = th_seq[i].stepst
              seq[ii].stepet = th_seq[i].stepet 
              --seq[ii].ostepet = th_seq[i].stepet 
              
              preset[ii].settings_morphrebound = th_seq[i].morphrebound
              preset[ii].morph_shape = th_seq[i].morph_shape
            
              morph_time[ii] = CalcSyncTime(seq[ii][seq[ii].running][seq[ii].currentstep].stepmorphtime) * seq_speedmult[seq[ii][seq[ii].running].speedmult]
      
              morphtime[ii] = {st = th_seq[i].stepst,
                             et = th_seq[i].stepst + morph_time[ii],
                             --oet = th_seq[i].stepst + morph_time[ii],
                             sslot = th_seq[i].sslot,
                             eslot = th_seq[i].eslot}
              update_slots = true
              update_seq = true
              update_seqplay = true          
              th_seq[i] = nil
            end
            
          end
        end
        
      end
      
      RunSequences()    
      
     -- Slot
     if MOUSE_click(obj.sections[66]) then
      local i = math.floor((mouse.mx - obj.sections[24].x) / (obj.sections[24].w+2)) 
                + (math.floor((mouse.my - obj.sections[24].y) / (obj.sections[24].h+2)) * 4) + 1
      if preset[last_M][1] and preset[last_M][1].S_params and preset[last_M][1].S_params[i] ~= nil then 
        preset[last_M].use_params = i
        update_slots = true
        ENGINE_SetParams(last_M, reaper.time_precise(), false)
      end
     end
     local lb = MOUSE_click(obj.sections[67])
     local rb = MOUSE_click_RB(obj.sections[67])
     if lb or rb then 
      local i = math.floor((mouse.mx - obj.sections[32].x) / (obj.sections[32].w+2)) 
                + (math.floor((mouse.my - obj.sections[32].y) / (obj.sections[32].h+2)) * 4) + 1
      if preset[last_M][1] and preset[last_M][1].S_params and preset[last_M][1].S_params[i] ~= nil then
        morph_time[last_M] = preset[last_M].morph_fader
        if morph_time[last_M] == 0 or lb then 
          morph_time[last_M] = 0
          preset[last_M].use_params2 = i
          update_slots = true
          --update_gfx = true
          ENGINE_SetParams(last_M, reaper.time_precise(), false)
        else
          --local rt = reaper.time_precise()
          morphtime[last_M] = {st = rt,
                       et = rt + morph_time[last_M],
                       --oet = rt + morph_time[last_M],
                       sslot = preset[last_M].use_params2,
                       eslot = i}
          if not preset[last_M].settings_morphretrigger then
            preset[last_M].use_params2 = i
          end
          update_slots = true
        end
      end
     end
     
    -- Select Random
      if MOUSE_click(obj.sections[7]) then
         if preset[last_M][1] and preset[last_M][1].S_params and preset[last_M][1].S_params[0] ~= nil then 
           preset[last_M].use_params = 0
           update_slots = true 
           ENGINE_SetParams(last_M, reaper.time_precise(), false)
         end
      end
      local lb = MOUSE_click(obj.sections[41])
      local rb = MOUSE_click_RB(obj.sections[41])
      if lb or rb then
         if preset[last_M][1] and preset[last_M][1].S_params and preset[last_M][1].S_params[0] ~= nil then 
           morph_time[last_M] = preset[last_M].morph_fader
           if morph_time[last_M] == 0 or lb then 
             morph_time[last_M] = 0 
             preset[last_M].use_params2 = 0
             update_slots = true
             ENGINE_SetParams(last_M, reaper.time_precise(), false)
           else
             --local rt = reaper.time_precise()
             morphtime[last_M] = {st = rt,
                          et = rt + morph_time[last_M],
                          --oet = rt + morph_time[last_M],
                          sslot = preset[last_M].use_params2,
                          eslot = 0}
             if not preset[last_M].settings_morphretrigger then
               preset[last_M].use_params2 = 0
             end
             update_slots = true
           end
         end
      end  
    
        -- 2 pick
        if MOUSE_click(obj.sections[2]) then 
          fxidx = 1
          pick_state = not pick_state
          update_gfx = true
          ltfx = true 
        end 
                  
      if pick_state == true then

        -- get params
        if MOUSE_click(obj.sections[1]) then
          if preset then
            if not ENGINE_LoadedFX() then
              fxidx = preset[last_M].fxcnt + 1
              preset[last_M][fxidx] = ENGINE_GetParams()
              if preset[last_M][fxidx] ~= nil then
                if settings_autoloadfxsettings then
                  LoadDefaultFXSetup(fxidx)
                end
                preset[last_M][fxidx].S_params = {}
                for i = 0, slotcnt do
                  preset[last_M][fxidx].S_params[i] = ENGINE_GetParamsX(fxidx)
                end
                preset[last_M].active = true
                preset[last_M].fxcnt = preset[last_M].fxcnt + 1
              end
            end
            update_gfx = true
          end
        end    
        
        if ltfx then      
          _, _, _, paramnumber =reaper.GetLastTouchedFX()
          if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].params 
            and paramnumber +1 <= #preset[last_M][fxidx].params  
            and preset[last_M][fxidx].params[paramnumber+1] 
            and preset[last_M][fxidx].params[paramnumber+1].is_act == false then  
            
            preset[last_M][fxidx].params[paramnumber+1].is_act = true
            preset[last_M][fxidx].param_actidx[#preset[last_M][fxidx].param_actidx+1] = paramnumber+1
            update_gfx = true
          end
        end
        
        if MOUSE_click(obj.sections[70]) then
          --load
          LoadDefaultFXSetup(fxidx)
          update_gfx = true
          
        elseif MOUSE_click(obj.sections[71]) then
          --save
          SaveDefaultFXSetup()
                 
        elseif MOUSE_click(obj.sections[43]) then
          if mouse.my < fx_h then
            --FX
            if mouse.my > butt_h and mouse.my < fx_h - butt_h - 10 then
              local idx = math.floor((mouse.my - butt_h) / butt_h) + 1 + plist_offset
              fxidx = idx
              if preset[last_M][idx] == nil then
                fxidx = 1
              else
                fxidx = idx
              end
            
              update_gfx = true
            end
          elseif mouse.my > fx_h + butt_h and mouse.my < gfx1.main_h - butt_h then
              ltfx = false
              local idx = math.floor((mouse.my - (fx_h + butt_h)) / butt_h) + 1 + plist_offset
              if preset[last_M][fxidx] and preset[last_M][fxidx].params[idx] then
                preset[last_M][fxidx].params[idx].is_act = not preset[last_M][fxidx].params[idx].is_act
                if preset[last_M][fxidx].params[idx].is_act then
                  preset[last_M][fxidx].param_actidx[#preset[last_M][fxidx].param_actidx+1] = idx
                else
                  ENGINE_RemoveElement(idx)
                end
                update_gfx = true
              end
          elseif butt_cnt ~= nil and butt_cnt-2 < #preset[last_M][fxidx].params then
            if mouse.my >= gfx1.main_h - butt_h then
              plist_offset = plist_offset + (butt_cnt-2)
              if plist_offset + (butt_cnt - 2) > #preset[last_M][fxidx].params then
                plist_offset = #preset[last_M][fxidx].params - (butt_cnt - 2)
              end
              update_gfx = true
            elseif mouse.my <= fx_h + butt_h then
              plist_offset = plist_offset - (butt_cnt-2)
              if plist_offset < 0 then
                plist_offset = 0 
              end
              update_gfx = true
            end
          end
        elseif MOUSE_click_RB(obj.sections[43]) then
          if mouse.my < fx_h then
            --FX
            if mouse.my > butt_h and mouse.my < fx_h - butt_h - 10 then
              --Remove FX
              local idx = math.floor((mouse.my - butt_h) / butt_h) + 1 + plist_offset
              if idx < preset[last_M].fxcnt then
                if preset[last_M][idx] ~= nil then
                  for i = idx, preset[last_M].fxcnt do
                    preset[last_M][i] = preset[last_M][i+1]
                  end 
                end
              end
              preset[last_M][preset[last_M].fxcnt] = {} 
              preset[last_M].fxcnt = preset[last_M].fxcnt - 1
              fxidx = 1
              settings_restrictfx = 0
              update_gfx = true
            end
          end        
        end
        
        pick_state_cnt = 0
        if fxidx > 0 and preset[last_M][fxidx] and preset[last_M][fxidx].params then 
          for i = 1, #preset[last_M][fxidx].params do
            if preset[last_M][fxidx].params[i].is_act then pick_state_cnt = pick_state_cnt + 1 end
          end
        end
     
      -- 2a get all
        if MOUSE_click(obj.sections[10]) then
           
          if preset[last_M][fxidx] and preset[last_M][fxidx].params  then  
            preset[last_M][fxidx].param_actidx = {}
            for i = 1, #preset[last_M][fxidx].params do 
              preset[last_M][fxidx].params[i].is_act = true 
              preset[last_M][fxidx].param_actidx[#preset[last_M][fxidx].param_actidx+1] = i
            end
          end
          update_gfx = true 
        end 
        
      -- 2a get all except protected
        if MOUSE_click(obj.sections[11]) then 
          if preset[last_M][fxidx] and preset[last_M][fxidx].params  then  
            for i = 1, #preset[last_M][fxidx].params do preset[last_M][fxidx].params[i].is_act = false end
            preset[last_M][fxidx].param_actidx = {}
            for i = 1, #preset[last_M][fxidx].params do 
              if not preset[last_M][fxidx].params[i].is_protected then 
                preset[last_M][fxidx].params[i].is_act = true
                preset[last_M][fxidx].param_actidx[#preset[last_M][fxidx].param_actidx+1] = i
              end 
            end
          end
          update_gfx = true 
        end 
      end
                                  
      -- gen pattern
        if MOUSE_click(obj.sections[3]) then
          local fxi 
          if settings_restrictfx == 0 then          
            for fxi = 1, preset[last_M].fxcnt do
              if preset[last_M][fxi].S_params then
                preset[last_M][fxi].S_params[0] = ENGINE_GenerateRandPatt(fxi)
                if morph_time[last_M] == 0 then 
                  preset[last_M].use_params2 = 0
                end
                update_gfx = true 
              end
            end
          else
            fxi = settings_restrictfx
            if preset[last_M][fxi].S_params then
              preset[last_M][fxi].S_params[0] = ENGINE_GenerateRandPatt(fxi) 
              if morph_time[last_M] == 0 then 
                preset[last_M].use_params2 = 0
              end
              update_gfx = true 
            end          
          end
          ENGINE_SetParams(last_M, reaper.time_precise(), false)
          disp_notify = 'Preset ' .. last_M .. ' parameters randomized'
        end
  
     -- capture X
       if MOUSE_click({x = obj.sections[13].x,
                     y = obj.sections[13].y,
                     w = obj.sections[20].x + obj.sections[20].w - obj.sections[13].x,
                     h = obj.sections[20].y + obj.sections[20].h - obj.sections[13].y}) then
          local i = math.floor((mouse.mx - obj.sections[13].x) / obj.sections[13].w) 
                            + (math.floor((mouse.my - obj.sections[13].y) / obj.sections[13].h) * 4) + 1
          local fxi
          if settings_restrictfx == 0 then
            for fxi = 1,preset[last_M].fxcnt do
              if preset[last_M][fxi].params ~= nil and preset[last_M][fxi].param_actidx ~= nil then
                if #preset[last_M][fxi].param_actidx > 0 then
                  preset[last_M][fxi].S_params[i] = ENGINE_GetParamsX(fxi)
                  preset[last_M].use_params2 = i
                  preset[last_M].morph_val = 1
                  update_gfx = true 
                end
              end
            end
          else
            fxi = settings_restrictfx
            if preset[last_M][fxi].params ~= nil and preset[last_M][fxi].param_actidx ~= nil then
              if #preset[last_M][fxi].param_actidx > 0 then
                preset[last_M][fxi].S_params[i] = ENGINE_GetParamsX(fxi)
                preset[last_M].use_params2 = i
                preset[last_M].morph_val = 1
                update_gfx = true 
              end
            end          
          end
          ENGINE_SetParams(last_M, reaper.time_precise(), false)
          disp_notify = 'Preset ' .. last_M .. ' parameters captured from plugin(s)'
          
       end            
  
      --MR
      local MR_overfound = false
      --if not pick_state then
        if MOUSE_over(obj.sections[65]) then
          local i = math.floor(mouse.mx / (obj.sections[44].w + 2))
          if i+1 ~= MR_lastover then
            --_, MR_over = reaper.GetProjExtState(0, SCRIPT_NAME, "MEM" .. (i+1) .. "defparams_fx_name")
            MR_over = "PRESET " .. tostring(i+1)
            update_gfx = true
            MR_lastover = i+1
          end
          MR_flag = true
          MR_overfound = true
        end
        if MOUSE_click(obj.sections[65]) then --and morph_time[last_M] == 0 then
          local i = math.floor(mouse.mx / (obj.sections[44].w + 2))                     
          if last_M ~= nil then
            fxidx = 1
            settings_restrictfx = 0
            morph_takeover = true
            if preset[last_M][fxidx] ~= nil then
              if preset[last_M][fxidx].fx_name ~= nil and FindFX(preset[last_M][fxidx].tguid,preset[last_M][fxidx].guid,true) then
                preset[last_M].active = true
              else
                preset[last_M].active = false
              end 
            end
          end

          if settings_autoopenfx then
            ENGINE_ClosePresetFX()
          end

          last_M = i+1 

          Disp_FXName = "PRESET " .. last_M
          Disp_ParamName = ""
          if preset[last_M] then

            if preset[last_M][fxidx] then
              pick_state = false
            else
              pick_state = true
            end
            
            local i
            for i = 1, #preset[last_M] do
              Disp_ParamName  = Disp_ParamName  .. "   " .. CropFXName(preset[last_M][i].fx_name)
            end
  
            if settings_autoopenfx then
              ENGINE_OpenPresetFX()
            end
            update_gfx = true
          end
        end
        
      --end
     
     if not MR_overfound and MR_flag then
       MR_over = ""
       MR_lastover = -1
       MR_flag = false
       update_gfx = true
     end
     
    --ParamName + Adjust Param
    local PN_overfound = false
    if not pick_state and seq_state == 0 then

      if fxidx > 0 and preset[last_M][fxidx] then
        local fxi
        local actcnt = 0
        for fxi = 1,preset[last_M].fxcnt do
          actcnt = actcnt + #preset[last_M][fxi].param_actidx
        end
        
        if MOUSE_click(obj.sections[4]) then 
          mouse.context = 'sliderV' 
          fxi = 1
          local i = math.floor((mouse.mx / obj.sections[4].w) * actcnt) + 1
          local sub = 0
          local paramcnt = #preset[last_M][fxi].param_actidx
          while i > paramcnt do
            sub = sub + #preset[last_M][fxi].param_actidx
            fxi = fxi + 1
            paramcnt = paramcnt + #preset[last_M][fxi].param_actidx
          end
          PN_DragIdx = i - sub
          PN_Fxi = fxi
        end     
        if mouse.context and mouse.context == 'sliderV' then
           local val = F_limit(MOUSE_sliderV(obj.sections[4]),0,1)
           if val ~= nil then
            val = 1-val
            if preset[last_M][PN_Fxi].S_params ~= nil and preset[last_M].use_params and preset[last_M][PN_Fxi].S_params[preset[last_M].use_params] then
              if preset[last_M][PN_Fxi].S_params[preset[last_M].use_params][preset[last_M][PN_Fxi].param_actidx[PN_DragIdx]].val ~= val then
                preset[last_M][PN_Fxi].S_params[preset[last_M].use_params][preset[last_M][PN_Fxi].param_actidx[PN_DragIdx]].val = val
                update_morph = true
                ENGINE_SetParams(last_M, reaper.time_precise(), false)
              end          
            else
              --check loaded data - as plugin is missing
            end
           end
        end
  
        if MOUSE_click(obj.sections[5]) then 
          mouse.context = 'sliderV2' 
          fxi = 1
          local i = math.floor((mouse.mx / obj.sections[5].w) * actcnt) + 1
          local sub = 0
          local paramcnt = #preset[last_M][fxi].param_actidx
          while i > paramcnt do
            sub = sub + #preset[last_M][fxi].param_actidx
            fxi = fxi + 1
            paramcnt = paramcnt + #preset[last_M][fxi].param_actidx
          end
          PN_DragIdx = i - sub
          PN_Fxi = fxi
        end     
        if mouse.context and mouse.context == 'sliderV2' then
           local val = F_limit(MOUSE_sliderV(obj.sections[5]),0,1)
           if val ~= nil then
            if preset[last_M][PN_Fxi].S_params ~= nil and preset[last_M].use_params2 and preset[last_M][PN_Fxi].S_params[preset[last_M].use_params2] then
              val = 1-val
              if preset[last_M][PN_Fxi].S_params[preset[last_M].use_params2][preset[last_M][PN_Fxi].param_actidx[PN_DragIdx]].val ~= val then
                preset[last_M][PN_Fxi].S_params[preset[last_M].use_params2][preset[last_M][PN_Fxi].param_actidx[PN_DragIdx]].val = val
                update_morph = true
                ENGINE_SetParams(last_M, reaper.time_precise(), false)
              end          
            else
              --check loaded data - as plugin is missing
            end
          end
        end
  
        if mouse.context ~= "sliderV" and mouse.context ~= "sliderV2" then
          if MOUSE_over(obj.sections[4]) or MOUSE_over(obj.sections[5]) then
            local i = math.floor((mouse.mx / obj.sections[4].w) * actcnt) +1    
            if i ~= PN_lastover then
              fxi = 1
              local sub = 0
              local paramcnt = #preset[last_M][fxi].param_actidx
              while i > paramcnt do
                sub = sub + #preset[last_M][fxi].param_actidx
                fxi = fxi + 1
                paramcnt = paramcnt + #preset[last_M][fxi].param_actidx
              end
              if preset[last_M] and preset[last_M][fxi].param_actidx[i - sub] ~= nil then
                local track = reaper.GetTrack(0,preset[last_M][fxi].tracknumberOut-1)
                Disp_FXName = CropFXName(preset[last_M][fxi].fx_name)
                Disp_ParamName = preset[last_M][fxi].params[preset[last_M][fxi].param_actidx[i - sub]].param_name
                _, Disp_ParamV = reaper.TrackFX_GetFormattedParamValue(track, preset[last_M][fxi].fxnumberOut, preset[last_M][fxi].param_actidx[i - sub] -1, "")
                update_disp = true
                PN_lastover = i
              end
            end
            PN_overfound = true
            PN_flag = true
          end
        else
          local track = reaper.GetTrack(0,preset[last_M][PN_Fxi].tracknumberOut-1)
          _, Disp_ParamV = reaper.TrackFX_GetFormattedParamValue(track, preset[last_M][PN_Fxi].fxnumberOut, preset[last_M][PN_Fxi].param_actidx[PN_DragIdx] -1, "")      
          update_disp = true
        end
      end
    end

    if not PN_overfound and PN_flag and mouse.context ~= 'sliderV' and mouse.context ~= 'sliderV2' then
      Disp_FXName = "PRESET " .. last_M
      Disp_ParamName = ""
      local i
      for i = 1, #preset[last_M] do
        Disp_ParamName  = Disp_ParamName  .. "   " .. CropFXName(preset[last_M][i].fx_name)
      end
        
      Disp_ParamV = ""
      PN_flag = false
      PN_lastover = -1
      update_disp = true
    end
           
     -- Write
     if not pick_state then
       --[[if MOUSE_click(obj.sections[40]) then 
         
        if write_state then
          if preset[last_M][fxidx] ~= nil then
            DeleteLastEnvPoint(nil, reaper.GetPlayPosition())
          end
          reaper.Main_OnCommand(1008, 0)
        end
         
         write_state = not write_state
         
         if write_state then
          ENGINE_OpenEnvs()
          if reaper.GetPlayState() == 1 or reaper.GetPlayState() == 4 then
            reaper.SetEditCurPos(reaper.GetPlayPosition(), true, false)
          end
          reaper.Main_OnCommand(1007, 0)
          if preset[last_M][fxidx] ~= nil then
           local track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
           reaper.SetTrackAutomationMode(track, settings_automodeon)
          end
         else
          if preset[last_M][fxidx] ~= nil then
           local track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
           reaper.SetTrackAutomationMode(track, settings_automodeoff)
          end
                 
         end
         update_gfx = true
       end]]
     
     -- Save + open settings
       if MOUSE_click(obj.sections[60]) then 
         settings_state = true
         GUI_Fade(gui)
         update_gfx = true
       end

       if MOUSE_click(obj.sections[111]) then 
         savestate()
       end
     end

     -- Restrict FX
       if MOUSE_click(obj.sections[80]) then
        settings_restrictfx = settings_restrictfx + 1
        if settings_restrictfx > #preset[last_M] then
          settings_restrictfx =0
        end
        update_gfx = true
        
     -- FX Bypass
       elseif MOUSE_click(obj.sections[69]) then 
         if preset[last_M] ~= nil then
           if settings_restrictfx == 0 then
             --bypass all
             for i = 1, #preset[last_M] do
               if preset[last_M][i] then
                 local track = reaper.GetTrack(0,preset[last_M][i].tracknumberOut-1)
                 reaper.TrackFX_SetEnabled(track, preset[last_M][i].fxnumberOut, not reaper.TrackFX_GetEnabled(track, preset[last_M][i].fxnumberOut))
               end           
             end
           else
             --bypass selected
             if preset[last_M][settings_restrictfx] then
               local track = reaper.GetTrack(0,preset[last_M][settings_restrictfx].tracknumberOut-1)
               reaper.TrackFX_SetEnabled(track, preset[last_M][settings_restrictfx].fxnumberOut, not reaper.TrackFX_GetEnabled(track, preset[last_M][settings_restrictfx].fxnumberOut))
             end
           end
           update_gfx = true
         end       

     -- FX Name (show fx)
       elseif MOUSE_click(obj.sections[42]) then
         if preset[last_M] ~= nil then
           if settings_restrictfx == 0 then
             --show all
             for i = 1, #preset[last_M] do
               if preset[last_M][i] then
                 local track = reaper.GetTrack(0,preset[last_M][i].tracknumberOut-1)
                 if not reaper.TrackFX_GetOpen(track, preset[last_M][i].fxnumberOut) then
                   reaper.TrackFX_Show(track, preset[last_M][i].fxnumberOut, 3)
                 end        
               end           
             end
           else
             --show selected
             if preset[last_M][settings_restrictfx] then
               local track = reaper.GetTrack(0,preset[last_M][settings_restrictfx].tracknumberOut-1)
               if not reaper.TrackFX_GetOpen(track, preset[last_M][settings_restrictfx].fxnumberOut) then
                 reaper.TrackFX_Show(track, preset[last_M][settings_restrictfx].fxnumberOut, 3)
               end        
             end
           end
         end
       end
     
     --chaos
      if MOUSE_click(obj.sections[113]) then mouse.context = 'chaosslider' end
      if mouse.context and mouse.context == 'chaosslider' then
         local val = F_limit(MOUSE_slider(obj.sections[113]),0,1)
         if val ~= nil then
           chaos = val       
           update_misc = true
         end
      end      

     --rate
      --[[if MOUSE_click_RB(obj.sections[114]) then 
        morphrate = 1 
        morphratepos = 0.5
        update_misc = true
      elseif MOUSE_click(obj.sections[114]) then mouse.context = 'rateslider' end
      if mouse.context and mouse.context == 'rateslider' then
         local val = F_limit(MOUSE_slider(obj.sections[113]),0,1)
         if val ~= nil then
           morphratepos = val
           if val >= 0.5 then
             morphrate = 1 + (((val-0.5)*2) * (morphrate_limit-1))
           else
             morphrate = (1/morphrate_limit) + (val*2 * (morphrate_limit-1)/morphrate_limit)
           end
           update_misc = true
         end
      end      
     
      if morphrate ~= last_morphrate then
        for i = 1, #seq do
          if seq[i].running > 0 then
            seq[i].stepet = seq[i].stepst + ((seq[i].ostepet - seq[i].stepst) * (1/morphrate))
            morphtime[i].et = morphtime[i].st + ((morphtime[i].oet - morphtime[i].st) * (1/morphrate))
          end
        end      
      end
      last_morphrate = morphrate]]
      
      -- morph
        
      local morphset = false
      --Morph External
        if reaper.HasExtState('LBX_Morph', 'MorphValue') then
          local mv = reaper.GetExtState('LBX_Morph', 'MorphValue' )
          local val = tonumber(mv)
          if not val or val < 0 then val = 0 end
          if morph_takeover then
            if val >= preset[last_M].morph_val - 0.1 and val <= preset[last_M].morph_val + 0.1 then
              morph_takeover = false
            end
          elseif val ~= last_morph_val then
            preset[last_M].morph_val = val
            ENGINE_SetParams(last_M, reaper.time_precise(), false)
            update_morph = true 
            morphset = true
          end
        end    
        --Morph Time
        if MOUSE_click(obj.sections[75]) then 
          mouse.context = 'MorphTimesliderV'
          if preset[last_M].settings_morphsync then
            morph_faderpos = preset[last_M].morph_sync
          else
            morph_faderpos = preset[last_M].morph_fader
          end
        elseif MOUSE_click_RB(obj.sections[75]) then 
          if preset[last_M].settings_morphsync then 
            preset[last_M].morph_sync = preset[last_M].morph_sync + 1
            if preset[last_M].morph_sync > #sync_table then
              preset[last_M].morph_sync = #sync_table 
            end
            preset[last_M].morph_fader = CalcSyncTime(preset[last_M].morph_sync)
            update_morph_time = true
          else
            mouse.context = 'MorphTimesliderV_fine'
            morph_faderpos = preset[last_M].morph_fader
          end
        end     
        if mouse.context and mouse.context == 'MorphTimesliderV' then
           local val = F_limit(MOUSE_sliderVMF(obj.sections[75]),0,1)
           if val ~= nil then
             if preset[last_M].settings_morphsync then
               preset[last_M].morph_sync = morph_faderpos + math.floor((0.5-val) * #sync_table)
               if preset[last_M].morph_sync < 1 then preset[last_M].morph_sync = 1 end
               if preset[last_M].morph_sync > #sync_table then preset[last_M].morph_sync = #sync_table end
               preset[last_M].morph_fader = CalcSyncTime(preset[last_M].morph_sync)
               update_morph_time = true
             else
               preset[last_M].morph_fader = morph_faderpos + math.floor((0.5-val)*100)
               if preset[last_M].morph_fader < 0 then preset[last_M].morph_fader = 0 end
               if preset[last_M].morph_fader > 120 then preset[last_M].morph_fader = 120 end
               update_morph_time = true
             end
           end
        elseif mouse.context and mouse.context == 'MorphTimesliderV_fine' then
           local val = F_limit(MOUSE_sliderVMF(obj.sections[75]),0,1)
           if val ~= nil then
             preset[last_M].morph_fader = morph_faderpos + (0.5-val)*10
             if preset[last_M].morph_fader < 0 then preset[last_M].morph_fader = 0 end
             if preset[last_M].morph_fader > 120 then preset[last_M].morph_fader = 120 end
             update_morph_time = true
           end
        end
        if not morphset and MOUSE_click(obj.sections[76]) then mouse.context = 'slider' end
        if mouse.context and mouse.context == 'slider' then
           preset[last_M].morph_val = F_limit(MOUSE_slider(obj.sections[76]),0,1)
           if preset[last_M].morph_val ~= last_morph_val then
            ENGINE_SetParams(last_M, reaper.time_precise(), false)
            update_morph = true
            morphset = true
            reaper.DeleteExtState("LBX_Morph", "MorphValue", false)
            morph_takeover = true
           end
        end      
        
        if MOUSE_click(obj.sections[77]) then 
          preset[last_M].settings_morphrebound = not preset[last_M].settings_morphrebound
          update_gfx = true
        end 
        if MOUSE_click(obj.sections[78]) then 
          preset[last_M].settings_morphretrigger = not preset[last_M].settings_morphretrigger
          update_gfx = true
        end 
        if MOUSE_click(obj.sections[79]) then 
          preset[last_M].settings_morphloop = not preset[last_M].settings_morphloop
          update_gfx = true
        end 
        if MOUSE_click(obj.sections[81]) then
          if morph_time[last_M] > 0 then 
            morph_time[last_M] = 0
            seq[last_M].running = 0
            
            --ENGINE_SetParams()
            local mp = (reaper.time_precise() - morphtime[last_M].st) / (morphtime[last_M].et - morphtime[last_M].st)
            if mp > 0.5 then
              preset[last_M].use_params2 = morphtime[last_M].eslot
            else
              preset[last_M].use_params2 = morphtime[last_M].sslot
            end
            update_gfx = true
          end
        end 
        if MOUSE_click(obj.sections[82]) then 
          preset[last_M].settings_morphsync = not preset[last_M].settings_morphsync
          if preset[last_M].settings_morphsync then
            preset[last_M].morph_fader = CalcSyncTime(preset[last_M].morph_sync)
          end
          update_gfx = true
        end 
        if MOUSE_click(obj.sections[83]) then 
          preset[last_M].morph_shape = preset[last_M].morph_shape + 1
          if preset[last_M].morph_shape > #shape_table then preset[last_M].morph_shape = 1 end
          update_gfx = true
        end 

        if MOUSE_click(obj.sections[112]) then 
          triggerhold = triggerhold + 1
          if triggerhold > #seq_triggerhold-1 then triggerhold = 0 end
          update_gfx = true
        end 
        
      last_gfx_w = gfx.w
      last_gfx_h = gfx.h

      if MOUSE_click(obj.sections[100]) then 
        seq_state = seq_state + 1
        if seq_state > 1 then
          seq_state = 0
        end
        update_gfx = true
      end

      --SEQUENCE
      if seq_state == 1 or seq_state == 2 then
        if seq_state == 1 then
          local steps, butt_h = 32, math.floor(obj.sections[102].h/6)
          local lb = MOUSE_click(obj.sections[102])
          local rb = MOUSE_click_RB(obj.sections[102])
          if MOUSE_click(obj.sections[103]) then
            local w = ((math.floor(obj.sections[103].w/steps)*steps))
            local x = math.floor(((mouse.mx - obj.sections[103].x) / w) * steps) +1
            seq[last_M][seq[last_M].selected].steps = x
            update_seqgrid = true
            update_seq = true
            
          elseif lb or rb then 
            local w = ((math.floor(obj.sections[102].w/steps)*steps))
            local x = math.floor(((mouse.mx - obj.sections[102].x) / w) * steps) +1
            local y = math.floor((mouse.my - obj.sections[102].y) / (butt_h + 1)) +1
            if x <= seq[last_M][seq[last_M].selected].steps and y <= 6 then
              if y == 1 then
                if rb then
                  seq[last_M][seq[last_M].selected][x].targetslot = seq[last_M][seq[last_M].selected][x].targetslot - 1
                  if seq[last_M][seq[last_M].selected][x].targetslot < 0 then
                    seq[last_M][seq[last_M].selected][x].targetslot = #seq_step_table-1
                  end
                else
                  seq[last_M][seq[last_M].selected][x].targetslot = seq[last_M][seq[last_M].selected][x].targetslot + 1
                  if seq[last_M][seq[last_M].selected][x].targetslot > #seq_step_table-1 then
                    seq[last_M][seq[last_M].selected][x].targetslot = 0
                  end                 
                end
                update_seqgrid = true
              elseif y == 2 then
                if rb then
                  seq[last_M][seq[last_M].selected][x].stepmorphtime = seq[last_M][seq[last_M].selected][x].stepmorphtime - 1
                  if seq[last_M][seq[last_M].selected][x].stepmorphtime < 5 then
                    seq[last_M][seq[last_M].selected][x].stepmorphtime = #sync_table
                  end
                else
                  seq[last_M][seq[last_M].selected][x].stepmorphtime = seq[last_M][seq[last_M].selected][x].stepmorphtime + 1
                  if seq[last_M][seq[last_M].selected][x].stepmorphtime > #sync_table then
                    seq[last_M][seq[last_M].selected][x].stepmorphtime = 5
                  end                 
                end
                update_seqgrid = true            
              elseif y == 3 then
                if rb then
                  seq[last_M][seq[last_M].selected][x].stepshape = seq[last_M][seq[last_M].selected][x].stepshape - 1
                  if seq[last_M][seq[last_M].selected][x].stepshape < 1 then
                    seq[last_M][seq[last_M].selected][x].stepshape = #shape_table
                  end
                else
                  seq[last_M][seq[last_M].selected][x].stepshape = seq[last_M][seq[last_M].selected][x].stepshape + 1
                  if seq[last_M][seq[last_M].selected][x].stepshape > #shape_table then
                    seq[last_M][seq[last_M].selected][x].stepshape = 1
                  end                 
                end
                update_seqgrid = true            
              elseif y == 4 then
                seq[last_M][seq[last_M].selected][x].steprebound = not seq[last_M][seq[last_M].selected][x].steprebound
                update_seqgrid = true            
              elseif y == 5 then
                if rb then
                  seq[last_M][seq[last_M].selected][x].steplength = seq[last_M][seq[last_M].selected][x].steplength - 1
                  if seq[last_M][seq[last_M].selected][x].steplength < 5 then
                    seq[last_M][seq[last_M].selected][x].steplength = #sync_table
                  end
                else
                  seq[last_M][seq[last_M].selected][x].steplength = seq[last_M][seq[last_M].selected][x].steplength + 1
                  if seq[last_M][seq[last_M].selected][x].steplength > #sync_table then
                    seq[last_M][seq[last_M].selected][x].steplength = 5
                  end                 
                end
                update_seqgrid = true            
              elseif y == 6 then
                if rb then
                  seq[last_M][seq[last_M].selected][x].stepstartslot = seq[last_M][seq[last_M].selected][x].stepstartslot - 1
                  if seq[last_M][seq[last_M].selected][x].stepstartslot < 0 then
                    seq[last_M][seq[last_M].selected][x].stepstartslot = #seq_step_table-1
                  end
                else
                  seq[last_M][seq[last_M].selected][x].stepstartslot = seq[last_M][seq[last_M].selected][x].stepstartslot + 1
                  if seq[last_M][seq[last_M].selected][x].stepstartslot > #seq_step_table-1 then
                    seq[last_M][seq[last_M].selected][x].stepstartslot = 0
                  end                 
                end
                update_seqgrid = true            
              end          
            end
          end
        end
        
        --Seq select
        if MOUSE_click(obj.sections[104]) then
          local s = math.floor((mouse.mx - obj.sections[104].x) / (obj.sections[104].w/4)) + 1
          seq[last_M].selected = s
          if seq[last_M].selected > 4 then
            seq[last_M].selected = 4
          elseif seq[last_M].selected < 1 then
            seq[last_M].selected = 1
          end
          update_gfx = true                  
        end
      
        --Seq Loop
        if MOUSE_click(obj.sections[105]) then
          seq[last_M][seq[last_M].selected].loop = not seq[last_M][seq[last_M].selected].loop
          update_gfx = true                  
        end

        --autoplay
        if MOUSE_click(obj.sections[109]) then
          seq[last_M][seq[last_M].selected].autoplay = seq[last_M][seq[last_M].selected].autoplay + 1
          if seq[last_M][seq[last_M].selected].autoplay > 8 then
            seq[last_M][seq[last_M].selected].autoplay = 8
          end
          update_gfx = true                  
        elseif MOUSE_click_RB(obj.sections[109]) then
          seq[last_M][seq[last_M].selected].autoplay = seq[last_M][seq[last_M].selected].autoplay - 1
          if seq[last_M][seq[last_M].selected].autoplay < 0 then
            seq[last_M][seq[last_M].selected].autoplay = 0
          end
          update_gfx = true                  
        end

        if MOUSE_click(obj.sections[106]) then
          seq[last_M][seq[last_M].selected].speedmult = seq[last_M][seq[last_M].selected].speedmult + 1
          if seq[last_M][seq[last_M].selected].speedmult > #seq_speedmulttxt then
            seq[last_M][seq[last_M].selected].speedmult = #seq_speedmulttxt
          end
          update_gfx = true                  
        elseif MOUSE_click_RB(obj.sections[106]) then
          seq[last_M][seq[last_M].selected].speedmult = seq[last_M][seq[last_M].selected].speedmult - 1
          if seq[last_M][seq[last_M].selected].speedmult < 1 then
            seq[last_M][seq[last_M].selected].speedmult = 1
          end
          update_gfx = true                  
        end
      --end

      --if seq_state == 1 or seq_state == 2 then

        if MOUSE_click(obj.sections[121]) then
          if seq_state == 1 then
            seq_state = 2
          else
            seq_state = 1
          end
          update_gfx = true
        end
        
        if seq_state == 2 then
        
          if MOUSE_click(obj.sections[123]) then mouse.context = 'printqualityslider' end
          if mouse.context and mouse.context == 'printqualityslider' then
             val = F_limit(MOUSE_slider(obj.sections[123]),0,1)
             if val ~= nil then
               print_quality = val
               if print_quality < 0.1 then print_quality = 0.1 end
             end
             update_print = true
          end      

          if MOUSE_click(obj.sections[124]) then
            print_lendiv = print_lendiv + 1
            if print_lendiv > #sync_table then print_lendiv = #sync_table end
            update_print = true
          elseif MOUSE_click_RB(obj.sections[124]) then
            print_lendiv = print_lendiv - 1
            if print_lendiv < 1 then print_lendiv = 1 end
            update_print = true
          end

          if MOUSE_click(obj.sections[125]) then
            print_lenmult = print_lenmult + 1
            if print_lenmult > 256 then print_lenmult = 256 end
            update_print = true
          elseif MOUSE_click_RB(obj.sections[125]) then
            print_lenmult = print_lenmult - 1
            if print_lenmult < 1 then print_lenmult = 1 end
            update_print = true
          end
        
          if MOUSE_click(obj.sections[126]) then
            --PRINT SEQUENCE
            local t = CalcSyncTime(print_lendiv) * print_lenmult
            local s = CalcBarTime()/(128 * print_quality)
            PrintEnvelopes(last_M, t, s)
          end
          
        end
        
      end
    
      if preset[last_M].morph_val ~= nil then
        last_morph_val = preset[last_M].morph_val
       else
        preset[last_M].morph_val = last_morph_val
      end

      if not pick_state and settings_showtips then
        ToolTips()    
      end
            
    else
      --Settings
      local rt = reaper.time_precise()
      RunSequences()    
      
      local obj = GetObjects_Settings()
      local gui = GetGUI_vars()    
      GUI_draw(obj, gui)
      
      mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y  
      mouse.LB = gfx.mouse_cap&1==1 
      mouse.RB = gfx.mouse_cap&2==2 
      
      -- Exit Settings
      if MOUSE_click(obj.sections[2]) then
        settings_state = false
        update_gfx = true
      end

      if MOUSE_click(obj.sections[10]) then 
        settings_autoopenfx = not settings_autoopenfx
        update_gfx = true
      end
      if MOUSE_click(obj.sections[11]) then 
        settings_delautomationpointsonunarm = not settings_delautomationpointsonunarm
        update_gfx = true
      end

      if MOUSE_click(obj.sections[12]) then 
        if settings_automodeoff ~= nil then 
          settings_automodeoff = settings_automodeoff + 1
          if settings_automodeoff >= #automode_table then
            settings_automodeoff = 0
          end
          update_gfx = true
        end
      end
      if MOUSE_click(obj.sections[13]) then
        if settings_automodeon ~= nil then 
          settings_automodeon = settings_automodeon + 1
          if settings_automodeon >= #automode_table then
            settings_automodeon = 0
          end
          update_gfx = true
        end
      end
      if MOUSE_click(obj.sections[14]) then
        settings_autoloadfxsettings = not settings_autoloadfxsettings
        update_gfx = true
      end

      if MOUSE_click(obj.sections[16]) then
        settings_showtips = not settings_showtips
        update_gfx = true
      end

      if MOUSE_click(obj.sections[17]) then
        settings_docked = settings_docked + 1
        if settings_docked > 1 then
          settings_docked = 0
        end
        gfx.dock(settings_docked)
        if settings_docked == 0 then
          gfx1 = {main_w = win_w, main_h = win_h}
          gfx.w = gfx1.main_w
          gfx.h = gfx1.main_h
        end
        update_gfx = true
      end

      if MOUSE_click(obj.sections[18]) then
        settings_playstop = not settings_playstop
        update_gfx = true
      end

      if MOUSE_click(obj.sections[59]) then
        ENGINE_ResetALL()
        settings_state = false
        update_gfx = true
        run()
      end

      if MOUSE_click(obj.sections[15]) then 
        mouse.context = 'latencysliderV'
        latency_faderpos = latencyadjust
      elseif MOUSE_click_RB(obj.sections[15]) then 
        mouse.context = 'latencysliderV_fine'
        latency_faderpos = latencyadjust
      end     
      if mouse.context and mouse.context == 'latencysliderV' then
        local val = F_limit(MOUSE_sliderVMF(obj.sections[15]),0,1)
        if val ~= nil then
          latencyadjust = latency_faderpos + (0.5-val)
          if latencyadjust < -0.5 then latencyadjust = -0.5 end
          if latencyadjust > 0.5 then latencyadjust = 0.5 end
          update_gfx = true
        end
      elseif mouse.context and mouse.context == 'latencysliderV_fine' then
         local val = F_limit(MOUSE_sliderVMF(obj.sections[15]),0,1)
         if val ~= nil then
           latencyadjust = latency_faderpos + (0.5-val)*0.1
           if latencyadjust < -0.5 then latencyadjust = -0.5 end
           if latencyadjust > 0.5 then latencyadjust = 0.5 end
           update_gfx = true
         end
      end
      
    end  
    
    if chaos < 1 and chaos_start == nil then
      chaos_bt = CalcBarTime()/2
      chaos_start = reaper.time_precise()
    end
    
    if chaos < 1 and reaper.time_precise() < chaos_start then
    else
      for i = 1, #morph_time do
        if morph_time[i] > 0 then
          ENGINE_SetParams(i, reaper.time_precise(), false)
        elseif morph_time_reset then
          morph_time_reset = false
          update_slots = true    
        end
        update_morph_time = true
      end  
      if chaos == 1 then chaos_start = nil
      elseif chaos_start ~= nil then
        chaos_start = chaos_start + ((1-chaos) * chaos_bt)
      end
    end      
        
    if not mouse.LB and not mouse.RB then mouse.context = nil end
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(run) else gfx.quit() end
    gfx.update()
    mouse.last_LB = mouse.LB
    mouse.last_RB = mouse.RB
    
  end
  
  ------------------------------------------------------------
  
  function ToolTips()
  
    disp_notify2 = nil
    local mo = false
    if MOUSE_over({x = obj.sections[13].x,
                 y = obj.sections[13].y,
                 w = obj.sections[20].x + obj.sections[20].w - obj.sections[13].x,
                 h = obj.sections[20].y + obj.sections[20].h - obj.sections[13].y}) then
      mo = true
      if disp_lastover ~= 1 then
        disp_lastover = 1
        disp_notify2 = 'Capture current parameter values from plugin'
        update_disp = true
      end
    elseif MOUSE_over(obj.sections[3]) then    
      mo = true
      if disp_lastover ~= 2 then
        disp_lastover = 2
        disp_notify2 = 'Randomize parameter values for current preset'
        update_disp = true
      end
    elseif MOUSE_over(obj.sections[80]) then
      mo = true
      if disp_lastover ~= 3 then
        disp_lastover = 3
        disp_notify2 = 'Restrict randomize and capture to selected plugin only'
        update_disp = true        
      end
    elseif MOUSE_over(obj.sections[69]) then
      mo = true
      if disp_lastover ~= 4 then
        disp_lastover = 4
        disp_notify2 = 'Bypass all or selected plugins (within preset)'
        update_disp = true   
      end
    elseif MOUSE_over(obj.sections[107]) then
      mo = true
      if disp_lastover ~= 5 then
        disp_lastover = 5
        disp_notify2 = 'Start selected sequence group'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[108]) then
      mo = true
      if disp_lastover ~= 6 then
        disp_lastover = 6
        disp_notify2 = 'Stop all sequences'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[82]) then
      mo = true
      if disp_lastover ~= 7 then
        disp_lastover = 7
        disp_notify2 = 'Sync auto morph time to tempo'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[83]) then
      mo = true
      if disp_lastover ~= 8 then
        disp_lastover = 8
        disp_notify2 = 'Select auto morph shape'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[112]) then
      mo = true
      if disp_lastover ~= 9 then
        disp_lastover = 9
        disp_notify2 = 'Trigger sequences and auto morph on next bar/beat or instantly'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[81]) then
      mo = true
      if disp_lastover ~= 10 then
        disp_lastover = 10
        disp_notify2 = 'Stop sequence or auto morph for current preset'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[76]) then
      mo = true
      if disp_lastover ~= 11 then
        disp_lastover = 11
        disp_notify2 = 'Slide to morph parameters between selected blue and red slots'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[79]) then
      mo = true
      if disp_lastover ~= 12 then
        disp_lastover = 12
        disp_notify2 = 'Loop sequence steps or auto morph'
        update_disp = true
      end
    elseif MOUSE_over(obj.sections[78]) then
      mo = true
      if disp_lastover ~= 13 then
        disp_lastover = 13
        disp_notify2 = 'Restart auto morph when auto morph is running'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[77]) then
      mo = true
      if disp_lastover ~= 14 then
        disp_lastover = 14
        disp_notify2 = 'Auto morph only in one direction (like sawtooth)'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[75]) then
      mo = true
      if disp_lastover ~= 15 then
        disp_lastover = 15
        disp_notify2 = 'Set auto morph time - and displays current auto morph position'
        update_disp = true           
      end
    elseif (MOUSE_over(obj.sections[7]) or MOUSE_over(obj.sections[41])) then
      mo = true
      if disp_lastover ~= 16 then
        disp_lastover = 16
        disp_notify2 = 'Select random parameter settings slot'
        update_disp = true           
      end
    elseif (MOUSE_over(obj.sections[66]) or MOUSE_over(obj.sections[67])) then
      mo = true
      if disp_lastover ~= 17 then
        disp_lastover = 17
        disp_notify2 = 'Select morph parameter settings slot'
        update_disp = true           
      end
    elseif (MOUSE_over(obj.sections[70]) or MOUSE_over(obj.sections[71])) then
      mo = true
      if disp_lastover ~= 18 then
        disp_lastover = 18
        disp_notify2 = 'Load/save default plugin parameters and settings'
        update_disp = true           
      end
    elseif MOUSE_over(obj.sections[100]) then
      mo = true
      if disp_lastover ~= 19 then
        disp_lastover = 19
        disp_notify2 = 'Open/close sequencer'
        update_disp = true           
      end
    elseif seq_state == 1 and MOUSE_over(obj.sections[104]) then
      mo = true
      if disp_lastover ~= 20 then
        disp_lastover = 20
        disp_notify2 = 'Select preset sequence'
        update_disp = true           
      end
    elseif seq_state == 1 and MOUSE_over(obj.sections[105]) then
      mo = true
      if disp_lastover ~= 21 then
        disp_lastover = 21
        disp_notify2 = 'Loop at end of selected sequence'
        update_disp = true           
      end
    elseif seq_state == 1 and MOUSE_over(obj.sections[106]) then
      mo = true
      if disp_lastover ~= 22 then
        disp_lastover = 22
        disp_notify2 = 'Speed multiplier for selected sequence'
        update_disp = true           
      end
    elseif seq_state == 1 and MOUSE_over(obj.sections[109]) then
      mo = true
      if disp_lastover ~= 23 then
        disp_lastover = 23
        disp_notify2 = 'Select sequence autoplay group'
        update_disp = true           
      end
    elseif seq_state == 1 and MOUSE_over(obj.sections[103]) then
      mo = true
      if disp_lastover ~= 50 then
        disp_lastover = 50
        disp_notify2 = 'Click to select number of steps in sequence'
        update_disp = true           
      end
    end
    if not mo then
      if disp_lastover and disp_lastover > 0 then
        disp_lastover = -1
        disp_notify2 = nil
        update_disp = true           
      end
    end
  
  end
  
  ------------------------------------------------------------
     
  function ENGINE_Timer_Morph(val)
  
    local rt = reaper.time_precise()
    
  
  end
  
  ------------------------------------------------------------
  
  function ENGINE_RemoveElement(val)
  
    --if tab then
      for i = 1, #preset[last_M][fxidx].param_actidx do
        if preset[last_M][fxidx].param_actidx[i] == val then
        
          table.remove(preset[last_M][fxidx].param_actidx, i)
          break
        end
      end
    --end
  
  end
  
  ------------------------------------------------------------
  
  function onload()
  
    local pfx = "Preset_"
    local fxcnt
    
    morph_takeover = true
    
--    preset = {fx = {params = {}, S_params = {}, param_actidx = {}}}
    --preset[last_M].fx = {}
    --preset[last_M][fxidx].S_params = {}
    
    reaper.DeleteExtState("LBX_Morph", "MorphValue", true)
    ret, ss = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "savedsettings")
    if ss == "1" then
      local _, V = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "VERSION")
      V = tonumber(V)
      if V >= 0.92 then
        _, chaos = reaper.GetProjExtState(0, SCRIPT_NAME, "CHAOS")
        chaos = tonumber(chaos)
      end

      _, slotcnt = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "slotcnt")
      _, latencyadjust = reaper.GetProjExtState(0, SCRIPT_NAME, "latencyadjust")
      latencyadjust = tonumber(latencyadjust)
      
      local Mi
      for Mi = 1,16 do
        pfx = "PRESET_" .. Mi .. "_"
        _, preset[Mi].fxcnt = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "FXCOUNT")
        _, preset[Mi].active = tobool(reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "preset_active"))
        _, preset[Mi].use_params = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "use_params")      
        _, preset[Mi].use_params2 = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "use_params2")
          preset[Mi].use_params = tonumber(preset[Mi].use_params)
          preset[Mi].use_params2 = tonumber(preset[Mi].use_params2)
          if preset[Mi].use_params == nil then preset[Mi].use_params = 1 end
          if preset[Mi].use_params2 == nil then preset[Mi].use_params2 = 1 end
        preset[Mi].fxcnt = tonumber(preset[Mi].fxcnt)

        _, preset[Mi].morph_fader = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morph_time")
        _, preset[Mi].settings_morphrebound = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphrebound")
        _, preset[Mi].settings_morphretrigger = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphretrigger")
        _, preset[Mi].settings_morphsync = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphsync")
        _, preset[Mi].settings_morphloop = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphloop")
        _, preset[Mi].morph_val = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morph_val")
        _, preset[Mi].morph_sync = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morph_sync")
        _, preset[Mi].morph_shape = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morph_shape")
        if preset[Mi].morph_fader == "" then preset[Mi].morph_fader = 0 else preset[Mi].morph_fader = tonumber(preset[Mi].morph_fader) end
        preset[Mi].settings_morphrebound = tobool(preset[Mi].settings_morphrebound)
        preset[Mi].settings_morphretrigger = tobool(preset[Mi].settings_morphretrigger)
        preset[Mi].settings_morphsync = tobool(preset[Mi].settings_morphsync)
        preset[Mi].settings_morphloop = tobool(preset[Mi].settings_morphloop)
        preset[Mi].morph_val = tonumber(preset[Mi].morph_val)
        preset[Mi].morph_sync = tonumber(preset[Mi].morph_sync)
        preset[Mi].morph_shape = tonumber(preset[Mi].morph_shape)

        local _, mt = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime")
        if tobool(mt) then
          
          local _, st = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_st")
          local _, et = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_et")
          local _, sslot = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_sslot")
          local _, eslot = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_eslot")
          morphtime[Mi] = {st = tonumber(st),
                           et = tonumber(et),
                           sslot = tonumber(sslot),
                           eslot = tonumber(eslot)}
        end
              
        if preset[Mi].fxcnt ~= nil then
          if preset[Mi].fxcnt > 0 then fxidx = 1 end  
          for Fxi = 1, preset[Mi].fxcnt do  
      
            pfx = "Preset_" .. Mi .. "_FX_" .. Fxi .. "_"
            preset[Mi][Fxi] = INIT_FX()
      
            local retval, dp_cnt = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_COUNT")
            if retval and dp_cnt ~= nil and dp_cnt ~= "" then
              dp_cnt = tonumber(dp_cnt)
              if dp_cnt > 0 then
                preset[Mi][Fxi].params = {}
                preset[Mi][Fxi].S_params = {}
                
                _, preset[Mi][Fxi].active = tobool(reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fx_active"))
                _, preset[Mi][Fxi].fx_name = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fx_name")
                _, preset[Mi][Fxi].fxnumberOut = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fxnumberOut")
                _, preset[Mi][Fxi].guid = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_guid")
                _, preset[Mi][Fxi].tguid = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_trackguid")
                _, preset[Mi][Fxi].tracknumberOut = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_tracknumberOut")
                preset[Mi][Fxi].tracknumberOut = tonumber(preset[Mi][Fxi].tracknumberOut)
                preset[Mi][Fxi].fxnumberOut = tonumber(preset[Mi][Fxi].fxnumberOut)
                
                --Show fx
                local track = reaper.GetTrack(0,preset[Mi][Fxi].tracknumberOut-1)
                local _, fx_name = reaper.TrackFX_GetFXName( track, preset[Mi][Fxi].fxnumberOut, '' )
                local guid =  reaper.TrackFX_GetFXGUID( track, preset[Mi][Fxi].fxnumberOut )
                local tguid = reaper.GetTrackGUID(track)
                
                local track_num, fx_num
                local found = false
                
                if (preset[Mi][Fxi].tguid == tguid
                   and preset[Mi][Fxi].guid == guid
                   and preset[Mi][Fxi].fx_name == fx_name) then
                
                  fx_num = preset[Mi][Fxi].fxnumberOut
                  found = true
                
                else 
                  --Search for plugin
                  found, track_num, fx_num = FindFX(preset[Mi][Fxi].tguid,preset[Mi][Fxi].guid, false)
                  if found then
                    track = reaper.GetTrack(0,track_num)
                    preset[Mi][Fxi].tracknumberOut = track_num+1
                    preset[Mi][Fxi].fxnumberOut = fx_num
                  end      
                end
                if found then
                  --[[if settings_autoopenfx then
                    ENGINE_OpenPresetFX()              
                  end]]
                  if write_state then
                    reaper.SetTrackAutomationMode(track, settings_automodeon)
                  end
                end        
                
                local dp_act_cnt = 1
                preset[Mi][Fxi].param_actidx = {}
                for i = 1,dp_cnt do
                
                  local ret, pn = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_param_name")
                  local ret, ip = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_is_protected")       
                  local ret, ia = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_is_act")
                  local ret, val = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_val")
        
                  preset[Mi][Fxi].params[i] = {param_name = pn,
                                   is_protected = tobool(ip),
                                   is_act = tobool(ia),
                                   val = val}
                  if preset[Mi][Fxi].params[i].is_act then
                    preset[Mi][Fxi].param_actidx[dp_act_cnt] = i
                    dp_act_cnt = dp_act_cnt + 1
                  end        
                end
              
                for i = 0, slotcnt do
                  local _, sp_cnt = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "S_params_" .. i .. "_COUNT")
                  if tonumber(sp_cnt) > 0 then
                    preset[Mi][Fxi].S_params[i] = {}
                    for j = 1,sp_cnt do
                      
                      local ret, val = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "S_params_" .. i .."_" .. j .. "_val")
                      preset[Mi][Fxi].S_params[i][j] = {val = tonumber(val)}
                    end
                  end
                end
              end
            end
          end
        end

       pfx = "SEQ_" .. Mi .. "_"
       _, seq[Mi].selected = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "SELECTED")
       --_, seq[Mi].autostart = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "AUTOPLAY")
       seq[Mi].selected = tonumber(seq[Mi].selected)
       --seq[Mi].autostart = tobool(seq[Mi].autostart)
       local s
       for s = 1, #seq[Mi] do
          pfx = "SEQ_" .. Mi .. "_" .. s .. "_"
          _, seq[Mi][s].steps = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "STEPS")
          _, seq[Mi][s].loop = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "LOOP")
          _, seq[Mi][s].speedmult = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "SPEEDMULT")
          _, seq[Mi][s].autoplay = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "AUTOPLAY")
          seq[Mi][s].steps = tonumber(seq[Mi][s].steps)
          seq[Mi][s].loop = tobool(seq[Mi][s].loop)
          seq[Mi][s].speedmult = tonumber(seq[Mi][s].speedmult)
          seq[Mi][s].autoplay = tonumber(seq[Mi][s].autoplay)
          for step = 1, #seq[Mi][s] do
            pfx = "SEQ_" .. Mi .. "_" .. s .. "_" .. step .. "_"
            _, seq[Mi][s][step].targetslot = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "TARGET")
            _, seq[Mi][s][step].stepshape = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "SHAPE")
            _, seq[Mi][s][step].stepmorphtime = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "MORPHTIME")
            _, seq[Mi][s][step].steplength = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "LENGTH")
            _, seq[Mi][s][step].steprebound = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "REBOUND")
            _, seq[Mi][s][step].stepstartslot = reaper.GetProjExtState(0, SCRIPT_NAME, pfx .. "START")
            seq[Mi][s][step].targetslot = tonumber(seq[Mi][s][step].targetslot)
            seq[Mi][s][step].stepshape = tonumber(seq[Mi][s][step].stepshape)
            seq[Mi][s][step].stepmorphtime = tonumber(seq[Mi][s][step].stepmorphtime)
            seq[Mi][s][step].steplength = tonumber(seq[Mi][s][step].steplength)
            seq[Mi][s][step].steprebound = tobool(seq[Mi][s][step].steprebound)
            seq[Mi][s][step].stepstartslot = tonumber(seq[Mi][s][step].stepstartslot)
          end
        end

      end      
      --[[for i = 1,16 do
        _, preset[i].active = reaper.GetProjExtState(0, SCRIPT_NAME, "MEMSLOT_" .. i)
        preset[i].active = tobool(preset[i].active)
      end]]
      
    else
      savestate("")
    end
    update_gfx = true
  end
  
  ------------------------------------------------------------
  
  function savestate()
    --local SCRIPT_NAME = 'LBXChaosEngine'
    reaper.SetProjExtState(0, SCRIPT_NAME, "", "")
    
    local pfx = "Preset_"
    
    reaper.DeleteExtState("LBX_Morph", "MorphValue", false)
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "savedsettings", "1")
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "VERSION", VERSION)
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "slotcnt", slotcnt)
    reaper.SetProjExtState(0, SCRIPT_NAME, "ActiveMemorySlot", last_M)    
    reaper.SetProjExtState(0, SCRIPT_NAME, "LatencyAdjust", latencyadjust)
    reaper.SetProjExtState(0, SCRIPT_NAME, "CHAOS", chaos)

    for Mi = 1,16 do
      pfx = "PRESET_" .. Mi .. "_"
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "preset_active",  tostring(preset[Mi].active))
      if preset[Mi].fxcnt == nil then preset[Mi].fxcnt = 0 end
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "FXCOUNT", preset[Mi].fxcnt)
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "use_params", preset[Mi].use_params)
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "use_params2", preset[Mi].use_params2)
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_time", preset[Mi].morph_fader) 
      --reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_rebound", tostring(preset[Mi].settings_morphrebound)) 
      --reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_retrigger", tostring(preset[Mi].settings_morphretrigger)) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_val", preset[Mi].morph_val) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphloop", tostring(preset[Mi].settings_morphloop))
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphretrigger", tostring(preset[Mi].settings_morphretrigger)) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphrebound", tostring(preset[Mi].settings_morphrebound)) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "settings_morphsync", tostring(preset[Mi].settings_morphsync)) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_sync", preset[Mi].morph_sync) 
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_shape", preset[Mi].morph_shape) 

      if morphtime[Mi] then
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime", tostring(true)) 
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_st", morphtime[Mi].st) 
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_et", morphtime[Mi].et)
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_sslot", morphtime[Mi].sslot)
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime_eslot", morphtime[Mi].eslot)      
      else
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morphtime", tostring(false)) 
      end

      if preset[Mi].fxcnt > 0 then
        for Fxi = 1, preset[Mi].fxcnt do
  
          pfx = "Preset_" .. Mi .. "_FX_" .. Fxi .. "_"
          
          if preset[Mi] and preset[Mi][Fxi] ~= nil then      
        
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_COUNT", #preset[Mi][Fxi].params)
            if preset[Mi][Fxi].fx_name ~= nil then
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fx_active", tostring(preset[Mi][Fxi].active))
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fx_name", preset[Mi][Fxi].fx_name)
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_fxnumberOut", preset[Mi][Fxi].fxnumberOut)
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_guid", preset[Mi][Fxi].guid)
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_trackguid", preset[Mi][Fxi].tguid)
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_tracknumberOut", preset[Mi][Fxi].tracknumberOut)
              for i = 1,#preset[Mi][Fxi].params do
                reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_param_name", preset[Mi][Fxi].params[i].param_name)
                reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_is_protected", tostring(preset[Mi][Fxi].params[i].is_protected))
                reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_is_act", tostring(preset[Mi][Fxi].params[i].is_act))
                reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_" .. i .."_val", preset[Mi][Fxi].params[i].val)
              end
            end
          else
            reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "defparams_COUNT", 0)    
          end 
      
          for i = 0,slotcnt do
            if preset[Mi][Fxi] and preset[Mi][Fxi].S_params and preset[Mi][Fxi].S_params[i] ~= nil then
              reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "S_params_" .. i .. "_COUNT", #preset[Mi][Fxi].S_params[i])        
              for j = 1,#preset[Mi][Fxi].S_params[i] do
                reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "S_params_" .. i .."_" .. j .. "_val", preset[Mi][Fxi].S_params[i][j].val)
              end
            else
              reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "S_params_" .. i .. "_COUNT", 0)
            end
          end
      
          --for i = 1,16 do
            if preset[Mi] then
              reaper.SetProjExtState(0, SCRIPT_NAME, "MEMSLOT_" .. Mi, tostring(preset[Mi].active))
            end
          --end
        
        end
      end
      
      pfx = "SEQ_" .. Mi .. "_"
      reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "SELECTED", tostring(seq[Mi].selected))
      --reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "AUTOPLAY", tostring(seq[Mi].autostart))
      for s = 1, #seq[Mi] do
        pfx = "SEQ_" .. Mi .. "_" .. s .. "_"
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "STEPS", tostring(seq[Mi][s].steps))
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "LOOP", tostring(seq[Mi][s].loop))
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "SPEEDMULT", tostring(seq[Mi][s].speedmult))
        reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "AUTOPLAY", tostring(seq[Mi][s].autoplay))
        for step = 1, #seq[Mi][s] do
          pfx = "SEQ_" .. Mi .. "_" .. s .. "_" .. step .. "_"
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "TARGET", tostring(seq[Mi][s][step].targetslot))
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "SHAPE", tostring(seq[Mi][s][step].stepshape))
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "MORPHTIME", tostring(seq[Mi][s][step].stepmorphtime))
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "LENGTH", tostring(seq[Mi][s][step].steplength))
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "REBOUND", tostring(seq[Mi][s][step].steprebound))
          reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "START", tostring(seq[Mi][s][step].stepstartslot))
        end
      end
      
                  
    end
  end
  
  ------------------------------------------------------------
  
  function saveperfstate(pfx)
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "morph_val", preset[last_M].morph_val) 
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "use_params", use_params)
    reaper.SetProjExtState(0, SCRIPT_NAME, pfx .. "use_params2", use_params2)  
  end
  
  ------------------------------------------------------------
  
  function tobool(b)
  
    local ret
    if tostring(b) == "true" then
      ret = true
    else
      ret = false
    end
    return ret
    
  end
  
  ------------------------------------------------------------
  
  function at_exit()
    savestate()
    
    --save settings
    reaper.SetExtState(SCRIPT_NAME, "AutoOpenFX", tostring(settings_autoopenfx), true)
    reaper.SetExtState(SCRIPT_NAME, "AutoDelPoints", tostring(settings_delautomationpointsonunarm), true)
    reaper.SetExtState(SCRIPT_NAME, "RecordAutoModeOff", tostring(settings_automodeoff), true)
    reaper.SetExtState(SCRIPT_NAME, "RecordAutoModeOn", tostring(settings_automodeon), true)
    reaper.SetExtState(SCRIPT_NAME, "AutoLoadFXSettings", tostring(settings_autoloadfxsettings), true)
    reaper.SetExtState(SCRIPT_NAME, "ShowTips", tostring(settings_showtips), true)    
    reaper.SetExtState(SCRIPT_NAME, "WindowDocked", tostring(settings_docked), true)    
    reaper.SetExtState(SCRIPT_NAME, "PlayStop", tostring(settings_playstop), true)    
    
    reaper.SetExtState(SCRIPT_NAME, "WindowWidth", gfx1.main_w, true)
    reaper.SetExtState(SCRIPT_NAME, "WindowHeight", gfx1.main_h, true)
    
    gfx.quit()
  end
  
  ------------------------------------------------------------

  function loadsettings()
  
    if reaper.HasExtState(SCRIPT_NAME, "AutoOpenFX") then
      settings_autoopenfx = tobool(reaper.GetExtState(SCRIPT_NAME, "AutoOpenFX"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "ShowTips") then
      settings_showtips = tobool(reaper.GetExtState(SCRIPT_NAME, "ShowTips"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "WindowDocked") then
      settings_docked = tonumber(reaper.GetExtState(SCRIPT_NAME, "WindowDocked"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "PlayStop") then
      settings_playstop = tobool(reaper.GetExtState(SCRIPT_NAME, "PlayStop"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "AutoDelPoints") then
      settings_delautomationpointsonunarm = tobool(reaper.GetExtState(SCRIPT_NAME, "AutoDelPoints"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "RecordAutoModeOff") then
      settings_automodeoff = tonumber(reaper.GetExtState(SCRIPT_NAME, "RecordAutoModeOff"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "RecordAutoModeOn") then
      settings_automodeon = tonumber(reaper.GetExtState(SCRIPT_NAME, "RecordAutoModeOn"))
    end
    if reaper.HasExtState(SCRIPT_NAME, "AutoLoadFXSettings") then
      settings_autoloadfxsettings = tobool(reaper.GetExtState(SCRIPT_NAME, "AutoLoadFXSettings"))
    end
    local retVal, lM = reaper.GetProjExtState(0, SCRIPT_NAME, "ActiveMemorySlot")
    if retVal > 0 then
      --reaper.ShowConsoleMsg("lM" .. lM)
      last_M = tonumber(lM)
    else
      --reaper.ShowConsoleMsg("123")      
      last_M = 1
    end
    
    if reaper.HasExtState(SCRIPT_NAME, "WindowWidth") and reaper.HasExtState(SCRIPT_NAME, "WindowHeight") then
      gfx1 = {main_w = reaper.GetExtState(SCRIPT_NAME, "WindowWidth"),
              main_h = reaper.GetExtState(SCRIPT_NAME, "WindowHeight")}
    else
      gfx1 = {main_w = 800, main_h = 450}
    end
  
  end
  
  ------------------------------------------------------------

  function CropFXName(n)

    if n == nil then
      return ""
    else
      return string.match(n, ':(.+)%(')
    end
    
  end
  
  function INIT()
  
    local i
    local preset = {{}}
    preset.last_M = 1
    for i = 1, 16 do
      preset[i] = {}
      preset[i].fxcnt = 0
      preset[i].use_params = 1
      preset[i].use_params2 = 1
      preset[i].morph_sync = 19 
      preset[i].morph_fader = CalcSyncTime(preset[i].morph_sync)
      preset[i].morph_shape = 1
      preset[i].morph_val = 0
      preset[i].mp = 0
      preset[i].settings_morphretrigger = true
      preset[i].settings_morphrebound = false
      preset[i].settings_morphloop = false
      preset[i].settings_morphsync = true
    end
    
    return preset
  
  end

  function INIT_FX()
  local preset = {}
  
    preset = {active = false,
                 fx_name = "",
                 tracknumberOut = -1,
                 fxnumberOut = -1,
                 guid = "",
                 tguid = "",
                 params = {},
                 S_params = {},
                 param_actidx = {}
                 }
    return preset
  
  end

  function INIT_SEQ()
    local seq = {}
    local i, j, s    
    
    for i = 1, 16 do
      seq[i] = {}
      seq[i].selected = 1
      seq[i].running = 0
      seq[i].currentstep = 0
      seq[i].stepst = 0
      seq[i].stepet = 0
      --seq[i].ostepet = 0
      seq[i].autostart = true
      for s = 1, 4 do
        seq[i][s] = {}
        seq[i][s].steps = 8
        seq[i][s].loop = true
        seq[i][s].speedmult = 4
        seq[i][s].autoplay = 0
        for j = 1, 32 do
          seq[i][s][j] = INIT_SEQSTEP()
        end
      end
    end
     
    return seq
  end  
  
  function INIT_SEQSTEP()
    local seq = {}
        
    seq = {targetslot = 1,
           stepshape = 1,
           stepmorphtime = 19,
           steplength = 19,
           steprebound = false,
           stepstartslot = 9}
     
    return seq
  end
    
  ------------------------------------------------------------
  
  function PrintEnvelopes(lM, print_len, print_step)
  
    curpos = reaper.GetCursorPosition()
  
    if #preset[lM] > 0 then

      local i
      
      --stop all sequences
      for i = 1, 16 do
        morph_time[i] = 0
        seq[i].running = 0
      end
      chaos_start = nil
      
      for fxi = 1, #preset[lM] do
        for p = 1, #preset[lM][fxi].param_actidx do
        
          local track = reaper.GetTrack(0,preset[lM][fxi].tracknumberOut-1)
          local fx_num = preset[last_M][fxidx].fxnumberOut
          local env = reaper.GetFXEnvelope(track, fx_num, preset[lM][fxi].param_actidx[p]-1, true)
          preset[lM][fxi].params[preset[lM][fxi].param_actidx[p]].Env = env
          _ = reaper.DeleteEnvelopePointRange(env, curpos, curpos + print_len)
        
        end
      end
      
      --start/init sequence
      seq[lM].running = seq[lM].selected
      seq[lM].currentstep = 1
      seq[lM].stepst = curpos
      seq[lM].stepet = curpos + (CalcSyncTime(seq[lM][seq[lM].running][seq[lM].currentstep].steplength) * seq_speedmult[seq[lM][seq[lM].running].speedmult])
      
      preset[lM].settings_morphrebound = seq[lM][seq[lM].running][seq[lM].currentstep].steprebound
      preset[lM].morph_shape = seq[lM][seq[lM].running][seq[lM].currentstep].stepshape
    
      morph_time[lM] = CalcSyncTime(seq[lM][seq[lM].running][seq[lM].currentstep].stepmorphtime) * seq_speedmult[seq[lM][seq[lM].running].speedmult]

      local newsslot
      if seq[lM][seq[lM].running][seq[lM].currentstep].stepstartslot < 9 then
        newsslot = seq[lM][seq[lM].running][seq[lM].currentstep].stepstartslot
      else
        newsslot = seq[lM][seq[lM].running][seq[lM][seq[lM].running].steps].targetslot
      end
      
      local neweslot
      if seq[lM][seq[lM].running][seq[lM].currentstep].targetslot < 9 then
        neweslot = seq[lM][seq[lM].running][seq[lM].currentstep].targetslot
      else
        neweslot = newsslot
      end

      morphtime[lM] = {st = curpos,
                       et = curpos + morph_time[lM],
                       sslot = newsslot,
                       eslot = neweslot}

      --loop through morph
      local shape
      if chaos < 1 or preset[lM].morph_shape == 3 then
        shape = 1      
      else
        shape = 0            
      end
      
      for rt = curpos, curpos + print_len, print_step do
      
        RunSequences(rt)
      
        if chaos < 1 and chaos_start == nil then
          chaos_bt = CalcBarTime()/2
          chaos_start = rt
        end
        
        if chaos < 1 and rt < chaos_start then
        else
          for i = 1, #morph_time do
            if morph_time[i] > 0 then
              ENGINE_PrintParams(i, rt, shape)
            elseif morph_time_reset then
              morph_time_reset = false
              --update_slots = true    
            end
            --update_morph_time = true
          end  
          if chaos == 1 then chaos_start = nil
          elseif chaos_start ~= nil then
            chaos_start = chaos_start + ((1-chaos) * chaos_bt)
          end
        end            
      
      end
      
      --disable sequence
      seq[lM].running = 0
      morph_time[lM] = 0
      chaos_start = nil
      
      --sort points
      for fxi = 1, #preset[lM] do
        for p = 1, #preset[lM][fxi].param_actidx do
        
          local env = preset[lM][fxi].params[preset[lM][fxi].param_actidx[p]].Env 
          reaper.Envelope_SortPoints(env)
          preset[lM][fxi].params[preset[lM][fxi].param_actidx[p]].Env = nil
        
        end
      end
      
      --refresh track display
      reaper.TrackList_AdjustWindows(0)
      reaper.UpdateArrange()
      
    end  
  end
  
  ------------------------------------------------------------
    
    function ENGINE_PrintParams(last_M, rt, shape)
    
      local fxidx
      local mp, mpv 
      local resetmt = false
  
      if morphtime[last_M] ~= nil then
        mp = F_limit((rt - morphtime[last_M].st) / ((morphtime[last_M].et - morphtime[last_M].st)),0,1)
        mpv = CalcShapeVal(last_M, mp, rt - morphtime[last_M].st, (morphtime[last_M].et - morphtime[last_M].st))
        preset[last_M].mp = mpv
      end
      
      for fxidx = 1,preset[last_M].fxcnt do
    
        if preset[last_M] == nil then return end
        if preset[last_M][fxidx].params == nil then return end
        if preset[last_M][fxidx].S_params[preset[last_M].use_params] == nil then return end
        if preset[last_M][fxidx].S_params[preset[last_M].use_params2] == nil then return end
        if preset[last_M].morph_val == nil then return end
        
        local found = false
        track = reaper.GetTrack(0,preset[last_M][fxidx].tracknumberOut-1)
        _, fx_name = reaper.TrackFX_GetFXName( track, preset[last_M][fxidx].fxnumberOut, '' )
        guid =  reaper.TrackFX_GetFXGUID( track, preset[last_M][fxidx].fxnumberOut )
        tguid = reaper.GetTrackGUID(track)
        
        local track_num, fx_num
        
        if (preset[last_M][fxidx].tguid == tguid
           and preset[last_M][fxidx].guid == guid
           and preset[last_M][fxidx].fx_name == fx_name) then
        
          fx_num = preset[last_M][fxidx].fxnumberOut
          found = true
        
        else 
          --Search for plugin
          found, track_num, fx_num = FindFX(preset[last_M][fxidx].tguid, preset[last_M][fxidx].guid, false)
          if found then
            track = reaper.GetTrack(0,track_num)
            preset[last_M][fxidx].tracknumberOut = track_num+1
            preset[last_M][fxidx].fxnumberOut = fx_num
          end      
        end
        if found then
            if preset[last_M][fxidx].param_actidx ~= nil then
              if morph_time[last_M] == 0 then
                for i = 1, math.min(#preset[last_M][fxidx].param_actidx, max_params_count) do
                  --Add point to parameter envelope 
                  --local env = reaper.GetFXEnvelope(track, fx_num, preset[last_M][fxidx].param_actidx[i]-1, true)
                  local env = preset[last_M][fxidx].params[preset[last_M][fxidx].param_actidx[i]].Env
                  _ = reaper.InsertEnvelopePoint(env,rt,
                                          preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val 
                                          + (preset[last_M][fxidx].S_params[preset[last_M].use_params2][preset[last_M][fxidx].param_actidx[i]].val 
                                          - preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val) * preset[last_M].morph_val,
                                          shape,0,false,true)
                
                end
              else
                for i = 1, math.min(#preset[last_M][fxidx].param_actidx, max_params_count) do
    
                  if morphtime[last_M] ~= nil then
                    
                    if mp >= 1 then
                      if preset[last_M].settings_morphrebound then
                        mp = 0
                      else
                        mp = 1
                      end
                      resetmt = true
                    end
                    if preset[last_M][fxidx].S_params[morphtime[last_M].sslot] ~= nil 
                        and preset[last_M][fxidx].S_params[morphtime[last_M].eslot] ~= nil   then
                        
                      local val = preset[last_M][fxidx].S_params[morphtime[last_M].sslot][preset[last_M][fxidx].param_actidx[i]].val + 
                                                (preset[last_M][fxidx].S_params[morphtime[last_M].eslot][preset[last_M][fxidx].param_actidx[i]].val 
                                                - preset[last_M][fxidx].S_params[morphtime[last_M].sslot][preset[last_M][fxidx].param_actidx[i]].val) * mpv                      
                      --Add point to parameter envelope 
                      local env = reaper.GetFXEnvelope(track, fx_num, preset[last_M][fxidx].param_actidx[i]-1, true)
                      _ = reaper.InsertEnvelopePoint(env,rt,
                                              preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val + 
                                              (val - preset[last_M][fxidx].S_params[preset[last_M].use_params][preset[last_M][fxidx].param_actidx[i]].val) * preset[last_M].morph_val,
                                              shape,0,false,true)
                                            
                    end
                  end
                            
                end          
              end
            end          
        end
      end
      if resetmt then
        if not preset[last_M].settings_morphloop then
          morph_time[last_M] = 0
          morph_time_reset = true
          if preset[last_M].settings_morphrebound then        
            preset[last_M].use_params2 = morphtime[last_M].sslot
          else
            preset[last_M].use_params2 = morphtime[last_M].eslot        
          end
          --ENGINE_SetParams(last_M, reaper.time_precise(), false) --ensure final morph settings are sent to plugin
        else
          --if not seq[last_M].running then
            if preset[last_M].settings_morphrebound then
              if seq[last_M].running > 0 then
                morph_time[last_M] = CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepmorphtime) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult]
              else
                morph_time[last_M] = preset[last_M].morph_fader
              end
              morphtime[last_M].st = morphtime[last_M].et
              morphtime[last_M].et = morphtime[last_M].et + morph_time[last_M]
            else
              if seq[last_M].running > 0 then
                morph_time[last_M] = CalcSyncTime(seq[last_M][seq[last_M].running][seq[last_M].currentstep].stepmorphtime) * seq_speedmult[seq[last_M][seq[last_M].running].speedmult]
              else
                morph_time[last_M] = preset[last_M].morph_fader
              end
              morphtime[last_M].st = morphtime[last_M].et
              morphtime[last_M].et = morphtime[last_M].et + morph_time[last_M]
              local sslot = morphtime[last_M].sslot
              if mp > 0.5 then
                preset[last_M].use_params2 = morphtime[last_M].eslot
              else
                preset[last_M].use_params2 = morphtime[last_M].sslot
              end
              morphtime[last_M].sslot = morphtime[last_M].eslot
              morphtime[last_M].eslot = sslot
            end
          --end
        end
        gfx_forceupdate = true
      end
      
    end
  
  ---------------------------------------------------
  
  function INITALL()  
  
    win_w = 800
    win_h = 450
    max_params_count = 200
  
    morphtime = {}
    morph_time = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    morph_time_reset = false
    morph_faderpos = 0
    latency_faderpos = 0
    gfx_forceupdate = false
    
    preset = INIT()
    seq = INIT_SEQ()
    
    fx_h = 160
    
    PN_DragIdx = -1
    MR_flag = false
    PN_flag = false
    PN_lastover = -1
    PN_Fxi = 0
    Disp_FXName = ""
    Disp_ParamName = ""
    Disp_ParamV = ""
    MR_over = ""
    MR_lastover = -1
    last_M = 1
    fxidx = 0
    plist_w = 150
    plist_offset = 0
    butt_h = 20
    use_params = 1
    use_params2 = 1
    slotcnt = 8 --max 8
    update_gfx = true
    update_morph = false
    update_slots = false
    update_morph_time = false
    update_seq = false
    update_seqgrid = false
    update_seqplay = false
    update_disp = false
    update_misc = false
    update_print = false
    pick_state = false
    
    seq_state = 0
    
    write_state = false
    settings_state = false
    settings_autoopenfx = true
    settings_delautomationpointsonunarm = true
    settings_automodeoff = 5
    settings_automodeon = 4
    settings_autoloadfxsettings = false
    settings_restrictfx = 0
    settings_showtips = true
    settings_playstop = true
    chaos_limit = 30
    chaos = 1
    chaosval = 1
    chaos_start = nil
    triggerhold = 1
    th_morphtime = {}
    th_seq = {}
    latencyadjust = -0.2
    --morphrate_limit = 8
    --morphrate = 1
    --morphratepos = 0.5
    --last_morphrate = morphrate
    settings_docked = 0
  
    print_quality = 1
    print_lendiv = 19
    print_lenmult = 4
  
    loadsettings()
    Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h) 
    mouse = {}
  
    --savestate()
    onload()
    --if settings_docked > 0 then
    gfx.dock(settings_docked)
    --end  
    
    Disp_FXName = "PRESET " .. last_M
    Disp_ParamName = ""
    local i
    for i = 1, #preset[last_M] do
      Disp_ParamName  = Disp_ParamName  .. "   " .. CropFXName(preset[last_M][i].fx_name)
    end
    if preset[last_M].settings_morphsync then
      preset[last_M].morph_fader = CalcSyncTime(preset[last_M].morph_sync)
    end
    disp_notify = 'LBX CHAOS ENGINE'
    obj = GetObjects()
  
  end
    
  ------------------------------------------------------------

  SCRIPT_NAME = "LBXChaosEngine"
  VERSION = 0.92
  
  INITALL()
  
  run()
  reaper.atexit(at_exit)
  
  ------------------------------------------------------------
