require 'cairo'

netuphist = {}
netdownhist = {}
ramhist = {}
swaphist = {}
cpuhist = {}
cur = 1

-- SETTINGS
nbCPU = 4
FSs = {"/", "/var", "/home"}
ladapter = "eth0"
wadapter = "wlan0"
ntop = 10
-- SETTINGS

function conky_init()
  local cr, cs = nil

  if conky_window == nil then return end
  if cs == nil or cairo_xlib_surface_get_width(cs) ~= conky_window.width or cairo_xlib_surface_get_height(cs) ~= conky_window.height then
    if cs then cairo_surface_destroy(cs) end
    cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  end
  if cr then cairo_destroy(cr) end
  cr = cairo_create(cs)


  local items = 30 + nbCPU + #FSs + ntop
  defaultSize = conky_window.height / items
  height = defaultSize + 1
  small = defaultSize * .8
  blue = {.4,.6,.8,.5}
  cur = cur % 100 + 1

  local ypos = 60
  local xpos = 25
  local margin = 50

  ypos = general(cr, xpos, ypos)       + margin
  ypos = fs     (cr, xpos, ypos)       + margin
  ypos = ram    (cr, xpos, ypos)       + margin
  ypos = cpu    (cr, xpos, ypos)       + margin
  ypos = top    (cr, xpos, ypos, ntop) + margin
  ypos = network(cr, xpos, ypos)       + margin

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

function general(cr, x, y)
  cadre(cr, x, y, 450, 3 * height, 10)

  emboss(cr    , x      , y, "Kernel")
  y = emboss(cr, x + 450, y, conky_parse("$kernel") , 1)
  emboss(cr    , x      , y, "Uptime")
  y = emboss(cr, x + 450, y, conky_parse("$uptime") , 1)
  emboss(cr    , x      , y, "Load")
  y = emboss(cr, x + 450, y, conky_parse("$loadavg"), 1)

  return y
end

function ram(cr, x, y)
  cadre(cr, x, y, 450, 10 + 4 * height, 10)

  if #swaphist == 0 then
    local i
    for i = 1,100 do
      swaphist[i] =.001
    end
  end

  if #ramhist == 0 then
    local i
    for i = 1,100 do
      ramhist[i] =.001
    end
  end

  ramhist[cur] = tonumber(conky_parse("$memperc"))
  swaphist[cur] = tonumber(conky_parse("$swapperc"))

  emboss(cr, x      , y, "Ram")
  emboss(cr, x + 180, y, conky_parse("$mem/")  , 1)
  y = emboss(cr, x + 260, y, conky_parse("$memmax"), 1)
  bar(cr, x + 5, y, 255, conky_parse("$memperc"), blue)
  graph(cr, x + 280, y, 170, ramhist, blue, 100)
  y = y + height + 10

  emboss(cr, x      , y, "Swap")
  emboss(cr, x + 180, y, conky_parse("$swap/")  , 1)
  y = emboss(cr, x + 260, y, conky_parse("$swapmax"), 1)
  bar(cr, x + 5, y, 255, conky_parse("$swapperc"), blue)
  graph(cr, x + 280, y, 170, swaphist, blue, 100)
  y = y + height

  return y
end

function cpu(cr, x, y)
  cadre(cr, x, y, 450, 10 + (1 + nbCPU) * height, 10)

  if #cpuhist == 0 then
    local i, j
    for i = 1,nbCPU do
      cpuhist[i] = {}
      for j = 1,100 do
        cpuhist[i][j] = .001
      end
    end
  end

  emboss(cr    , x      , y, "Cpu")
  emboss(cr    , x + 260, y, conky_parse("$freq_g GHz")             , 1)
  y = emboss(cr, x + 450, y, conky_parse("Temp ${hwmon 0 temp 1}°C"), 1) + 10

  local cpu

  for cpu=1,nbCPU do
    bar(cr, x + 5, y, 255, conky_parse("${cpu cpu" .. cpu .. "}"), blue)
    cpuhist[cpu][cur] = tonumber(conky_parse("${cpu cpu" .. cpu .. "}"))
    graph(cr, x + 280, y, 170, cpuhist[cpu], blue, 100)
    y = y + height
  end

  return y
end

function network(cr, x, y)
  cadre(cr, x, y, 450, 4 * height + 10, 10)

  local upspd = conky_parse("${upspeedf " .. wadapter .. "}") + conky_parse("${upspeedf " .. ladapter .. "}")
  local downspd = conky_parse("${downspeedf " .. wadapter .. "}") + conky_parse("${downspeedf " .. ladapter .. "}")

  local upspdunit = "KiB/s"
  local downspdunit = "KiB/s"
  if upspd > 1024 then
    upspd = upspd / 1024
    upspdunit = "MiB/s"
  end
  if downspd > 1024 then
    downspd = downspd / 1024
    downspdunit = "MiB/s"
  end

  local ethup = string.match(conky_parse("${totalup " .. ladapter .. "}"),"[%d.]+")
  local ethupunit = string.match(conky_parse("${totalup " .. ladapter .. "}"),"%a")
  if ethupunit == "K" then
    ethup = ethup * 1024
  elseif ethupunit == "M" then
    ethup = ethup * 1024 * 1024
  elseif ethupunit == "G" then
    ethup = ethup * 1024 * 1024 * 1024
  end

  local ethdown = string.match(conky_parse("${totaldown " .. ladapter .. "}"),"[%d.]+")
  local ethdownunit = string.match(conky_parse("${totaldown " .. ladapter .. "}"),"%a")
  if ethdownunit == "K" then
    ethdown = ethdown * 1024
  elseif ethdownunit == "M" then
    ethdown = ethdown * 1024 * 1024
  elseif ethdownunit == "G" then
    ethdown = ethdown * 1024 * 1024 * 1024
  end

  local wlanup = string.match(conky_parse("${totalup " .. wadapter .. "}"),"[%d.]+")
  local wlanupunit = string.match(conky_parse("${totalup " .. wadapter .. "}"),"%a")
  if wlanupunit == "K" then
    wlanup = wlanup * 1024
  elseif wlanupunit == "M" then
    wlanup = wlanup * 1024 * 1024
  elseif wlanupunit == "G" then
    wlanup = wlanup * 1024 * 1024 * 1024
  end

  local wlandown = string.match(conky_parse("${totaldown " .. wadapter .. "}"),"[%d.]+")
  local wlandownunit = string.match(conky_parse("${totaldown " .. wadapter .. "}"),"%a")
  if wlandownunit == "K" then
    wlandown = wlandown * 1024
  elseif wlandownunit == "M" then
    wlandown = wlandown * 1024 * 1024
  elseif wlandownunit == "G" then
    wlandown = wlandown * 1024 * 1024 * 1024
  end

  local totalup = ethup + wlanup
  local upunit = "B"
  if totalup > (1024 * 1024 * 1024) then
    totalup = totalup / (1024 * 1024 * 1024)
    upunit = "GiB"
  elseif totalup > (1024 * 1024) then
    totalup = totalup / (1024 * 1024)
    upunit = "MiB"
  elseif totalup > 1024 then
    totalup = totalup / 1024
    upunit = "KiB"
  end

  local totaldown = ethdown + wlandown
  local downunit = "B"
  if totaldown > (1024 * 1024 * 1024) then
    totaldown = totaldown / (1024 * 1024 * 1024)
    downunit = "GiB"
  elseif totaldown > (1024 * 1024) then
    totaldown = totaldown / (1024 * 1024)
    downunit = "MiB"
  elseif totaldown > 1024 then
    totaldown = totaldown / 1024
    downunit = "KiB"
  end

  if #netuphist == 0 then
    local i
    for i = 1,100 do
      netuphist[i] = .001
    end
  end

  if #netdownhist == 0 then
    local i
    for i = 1,100 do
      netdownhist[i] = .001
    end
  end

  netuphist[cur] = tonumber(conky_parse("${upspeedf " .. wadapter .. "}") + conky_parse("${upspeedf " .. ladapter .. "}"))
  netdownhist[cur] = tonumber(conky_parse("${downspeedf " .. wadapter .. "}") + conky_parse("${downspeedf " .. ladapter .. "}"))

  maxspeed = max({max(netuphist), max(netdownhist)})

  emboss(cr, x      , y, "Up")
  emboss(cr, x + 260, y, string.format("%.1f",upspd) .. upspdunit    , 1)
  graph(cr,  x + 280, y, 170, netuphist, blue, maxspeed)
  y = y + height
  emboss(cr, x      , y, "Down")
  emboss(cr, x + 260, y, string.format("%.1f",downspd) .. downspdunit, 1)
  graph(cr,  x + 280, y, 170, netdownhist, blue, maxspeed, 1)
  y = y + height + 10
  emboss(cr    , x    , y, "Total up")
  y = emboss(cr, x+260, y, string.format("%.2f",totalup) .. upunit     , 1)
  emboss(cr    , x    , y, "Total down")
  y = emboss(cr, x+260, y, string.format("%.2f",totaldown) .. downunit , 1)

  return y
end

function fs(cr, x, y)
  cadre(cr, x, y, 450, height * #FSs, 10)

  for row=1,#FSs do
    emboss(cr, x      , y     , FSs[row])
    emboss(cr, x + 180, y     , conky_parse("${fs_used " .. FSs[row] .. "}/"), 1)
    emboss(cr, x + 260, y     , conky_parse("${fs_size " .. FSs[row] .. "}") , 1)
    bar(cr, x + 280, y, 170, conky_parse("${fs_used_perc " .. FSs[row] .. "}"), blue)
    y = y + height
  end

  return y
end

function top(cr, x, y, nrows)
  cadre(cr, x, y, 450, height + 10 + nrows * small, 10)

  emboss(cr    , x      , y, "Name")
  emboss(cr    , x + 220, y, "Cpu", 1)
  emboss(cr    , x + 230, y, "Name")
  y = emboss(cr, x + 450, y, "Ram", 1) + 10

  local row

  for row=1,nrows do
    emboss(cr    , x      , y, conky_parse("${top name " .. row .. "}")    , 0, small)
    emboss(cr    , x + 220, y, conky_parse("${top cpu " .. row .. "}")     , 1, small)
    emboss(cr    , x + 230, y, conky_parse("${top_mem name " .. row .. "}"), 0, small)
    y = emboss(cr, x + 450, y, conky_parse("${top_mem mem " .. row .. "}") , 1, small)
  end

  return y
end

function cadre(cr, x, y, w, h, r, pop, col)
  if pop == nil then pop = 1 end

  local pi = 3.141592

  if pop < 0 then y = y + pop end
  cairo_set_operator(cr, CAIRO_OPERATOR_XOR)
    cairo_move_to(cr, x, y - r)
    cairo_arc(cr, x + w, y    , r, 1.5 * pi, 0   * pi)
    cairo_arc(cr, x + w, y + h, r, 0   * pi, .5  * pi)
    cairo_arc(cr, x    , y + h, r, .5  * pi, 1   * pi)
    cairo_arc(cr, x    , y    , r, 1   * pi, 1.5 * pi)

    cairo_set_source_rgb(cr, 1, 1, 1)
    cairo_fill(cr)

    y = y - pop

    cairo_move_to(cr, x, y - r)
    cairo_arc(cr, x + w, y    , r,1.5 * pi, 0   * pi)
    cairo_arc(cr, x + w, y + h, r,0   * pi, .5  * pi)
    cairo_arc(cr, x    , y + h, r,.5  * pi, 1   * pi)
    cairo_arc(cr, x    , y    , r,1   * pi, 1.5 * pi)

    cairo_set_source_rgb(cr, 0, 0, 0)
    cairo_fill(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)

  cairo_move_to(cr, x, y - r)
  cairo_arc(cr, x + w, y    , r, 1.5 * pi, 0   * pi)
  cairo_arc(cr, x + w, y + h, r, 0   * pi, .5  * pi)
  cairo_arc(cr, x    , y + h, r, .5  * pi, 1   * pi)
  cairo_arc(cr, x    , y    , r, 1   * pi, 1.5 * pi)

  if pop > 0 then cairo_set_source_rgba(cr, 0, 0, 0, .1) else cairo_set_source_rgba(cr, 1, 1, 1, .1) end
  cairo_fill_preserve(cr)
  if col ~= nil then cairo_set_source_rgba(cr, col[1], col[2], col[3], col[4]) else cairo_set_source_rgba(cr, 0, 0, 0, 0)end
  cairo_fill(cr)
end

function bar(cr, x, y, width, percent, color)
  local barh = height / 3
  emboss(cr, x + width, y + 3, percent .. "%", 1, small)
  width = width - 45
  cadre(cr, x, y + barh + 4, width                , barh - 4, 4)
  cadre(cr, x, y + barh + 4, width * percent / 100, barh - 4, 2, -1, color)
end

function emboss(cr, x, y, text, right, size, pop, col)
  if pop == nil then pop = 1 end
  if size == nil then size = defaultSize end
  if right == nil then right = 0 end

  y = y + size

  cairo_select_font_face (cr, "Impact", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
  cairo_set_font_size (cr, size);

  if right == 1 then
    extent = cairo_text_extents_t:create()
    tolua.takeownership(extent)
    cairo_text_extents(cr, text, extent)
    x = x - extent.x_advance
  -- cairo_text_extents_t:destroy(extent)
  end

  if pop < 0 then y = y + pop end
  cairo_set_operator(cr, CAIRO_OPERATOR_XOR)
    cairo_move_to(cr, x, y)
    cairo_text_path(cr, text)
    cairo_set_source_rgb(cr, 1, 1, 1)
    cairo_fill(cr)

    cairo_move_to(cr,x,y - pop)
    cairo_text_path(cr, text)
    cairo_set_source_rgb(cr, 0, 0, 0)
    cairo_fill(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)

  cairo_move_to(cr, x, y)
  cairo_text_path(cr, text)
  if pop > 0 then cairo_set_source_rgba(cr, 0, 0, 0, .1) else cairo_set_source_rgba(cr, 1, 1, 1, .1) end
  cairo_fill_preserve(cr)
  if col ~= nil then cairo_set_source_rgba(cr, col[1], col[2], col[3], col[4]) else cairo_set_source_rgba(cr, 0, 0, 0, 0) end
  cairo_fill(cr)

  return y
end

function graph(cr, x, y, width, hist, color, maximum, reverse)

  if maximum == nil then maximum = max(hist) end
  if reverse == nil then reverse = 0 end

  x = x - 2
  width = width + 2

  local scalev = (height - 2) / maximum
  if reverse == 1 then
    scalev = -scalev
    y = y + 1
  else
    y = y + height - 1
  end
  local scaleh = width / 100

  cairo_move_to(cr, x + scaleh, y)

  local i
  for i = cur+1,100 do
    cairo_line_to(cr, x + (i - cur) * scaleh, y - hist[i] * scalev)
  end
  for i = 1,cur do
    cairo_line_to(cr, x + ((100 - cur) + i) * scaleh, y - hist[i] * scalev)
  end

  cairo_line_to(cr, x + 100 * scaleh, y)
  cairo_close_path(cr)
  cairo_set_source_rgb(cr, 1, 1, 1)
  cairo_fill(cr)

  y = y - 2

  cairo_move_to(cr, x + scaleh, y)

  for i = cur+1,100 do
    cairo_line_to(cr, x + (i - cur) * scaleh, y - hist[i] * scalev)
  end
  for i = 1,cur do
    cairo_line_to(cr, x + ((100 - cur) + i) * scaleh, y - hist[i] * scalev)
  end

  cairo_line_to(cr, x + 100 * scaleh, y)
  cairo_close_path(cr)
  cairo_set_source_rgb(cr, 0, 0, 0)
  cairo_fill(cr)

  y = y + 1

  cairo_move_to(cr, x + scaleh, y)

  for i = cur+1,100 do
    cairo_line_to(cr, x + (i - cur) * scaleh, y - hist[i] * scalev)
  end
  for i = 1,cur do
    cairo_line_to(cr, x + ((100 - cur) + i) * scaleh, y - hist[i] * scalev)
  end

  cairo_line_to(cr, x + 100 * scaleh, y)
  cairo_close_path(cr)
  cairo_set_source_rgba(cr, color[1], color[2], color[3], 1)
  cairo_fill(cr)
end

function max(hist)
  local i
  local max = 0

  for i=1,#hist do
    if hist[i] > max then max = hist[i] end
  end

  return max
end
