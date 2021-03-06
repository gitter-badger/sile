SILE.units = {
  pt = { relative = false, value = 1 }
}

SILE.registerUnit = function (u, t)
  local def = SU.required(t, "definition", "registering unit "..u)
  local relative = t.relative or false
  if type(def) == "string" then
    local num,unit = string.match(def, "(-?[%d%.]+)%s*([%%%a]+)")
    if not SILE.units[unit] then SU.error("Unit "..u.." defined in terms of unknown unit "..unit) end
    if SILE.units[unit].relative then
      SILE.units[u] = { relative = true, convertor = function (v) return num * SILE.toPoints(v,unit) end}
    else
      SILE.units[u] = { relative = false, value = SILE.toPoints(num,unit) }
    end
  else
    SILE.units[u] = { relative = relative, convertor = def }
  end
end

SILE.toPoints = function(num, unit)
  if (not unit) then
    if (type(num) == "string") then -- split into num and unit parts
      num,unit = string.match(num, "(-?[%d%.]+)%s*([%%%a]+)")
      num = tonumber(num)
    else return tonumber(num) end
  end
  if (not SILE.units[unit]) then SU.error( "Unknown unit "..unit ) end
  num =  tonumber(string.match(num, "(-?[%d%.]+)"))
  if SILE.units[unit].convertor then
    return SILE.units[unit].convertor(num)
  else
    return num * SILE.units[unit].value
  end
end

SILE.registerUnit("mm", {definition = "2.8346457pt"})
SILE.registerUnit("cm", {definition = "10mm"})
SILE.registerUnit("in", {definition = "72pt"})

SILE.registerUnit("%", { relative = true, definition = function (v)
  SU.warn("Obsolete ambiguous % unit detected, please use %pw or %ph instead")
  return v / 100 * SILE.documentState.paperSize[1]
end})
SILE.registerUnit("%pw", { relative = true, definition = function (v)
  return v / 100 * SILE.documentState.orgPaperSize[1]
end})
SILE.registerUnit("%ph", { relative = true, definition = function (v)
  return v / 100 * SILE.documentState.orgPaperSize[2]
end})
SILE.registerUnit("%pmin", { relative = true, definition = function (v)
  return v / 100 * math.min(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
end})
SILE.registerUnit("%pmax", { relative = true, definition = function (v)
  return v / 100 * math.max(SILE.documentState.orgPaperSize[1], SILE.documentState.orgPaperSize[2])
end})
SILE.registerUnit("%fw", { relative = true, definition = function (v)
  return v / 100 * SILE.typesetter.frame:width()
end})
SILE.registerUnit("%fh", { relative = true, definition = function (v)
  return v / 100 * SILE.typesetter.frame:height()
end})
SILE.registerUnit("%fmin", { relative = true, definition = function (v)
  return v / 100 * math.min(SILE.typesetter.frame:width(), SILE.typesetter.frame:height())
end})
SILE.registerUnit("%fmax", { relative = true, definition = function (v)
  return v / 100 * math.max(SILE.typesetter.frame:width(), SILE.typesetter.frame:height())
end})
SILE.registerUnit("%lw", { relative = true, definition = function (v)
  local lskip = SILE.settings.get("document.lskip") or SILE.length.parse("0")
  local rskip = SILE.settings.get("document.rskip") or SILE.length.parse("0")
  local left = lskip.width and lskip.width:absolute() or lskip:absolute()
  local right = rskip.width and rskip.width:absolute() or rskip:absolute()
  local lw = SILE.typesetter.frame:lineWidth() - left - right
  return v / 100 * lw.length
end})
SILE.registerUnit("em", { relative = true, definition = function (v)
  return v * SILE.settings.get("font.size")
end})
SILE.registerUnit("ex", { relative = true, definition = function (v)
  return v * SILE.shaper:measureDim("x")
end})
SILE.registerUnit("spc", { relative = true, definition = function (v)
  return v * SILE.shaper:measureDim(" ")
end})

SILE.registerUnit("en", { definition = "0.5em" })

_relativeMeasurement = std.object {
  _type = "RelativeMeasurement",
  absolute = function(self)
    return SILE.toPoints(self.number, self.unit)
  end,
  __add = function (self, other)
    SU.error("We tried to do arithmetic on a relative measurement without explicitly absolutizing it. (That's a bug)", 1)
  end,
  __sub = function (self, other)
    SU.error("We tried to do arithmetic on a relative measurement without explicitly absolutizing it. (That's a bug)", 1)
  end
}

SILE.toMeasurement = function (number, unit)
  if not SILE.units[unit].relative then return SILE.toPoints(number,unit) end
  return _relativeMeasurement { number = number, unit = unit }
end

SILE.toAbsoluteMeasurement = function(n)
  if type(n) == "table" and n.prototype and (n:prototype() == "RelativeMeasurement"
    or n:prototype() == "Length") then
    return n:absolute()
  else
    return n
  end
end
