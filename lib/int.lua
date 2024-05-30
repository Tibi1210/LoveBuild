Integer = {}
local function val(o) return type(o) == 'number' and o or o[1] end
function Integer.__add(a,b) return Integer:create(val(a) + val(b)) end
function Integer.__sub(a,b) return Integer:create(val(a) - val(b)) end
function Integer.__div(a,b) return Integer:create(val(a) / val(b)) end
function Integer.__mul(a,b) return Integer:create(val(a) * val(b)) end
function Integer:__tostring() return tostring(self[1]) end
function Integer:create(value)
   return setmetatable({math.floor(value)}, Integer)
end

return Integer