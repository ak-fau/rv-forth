local sub = string.sub
local fmt = string.format
local gsub = string.gsub
local bit = require "bit32"

local function normalize_name(s)
   local subst = {
      ['-'] = "minus",
      ['+'] = "plus",
      ['/'] = "div",
      ['*'] = "mul",
   }
   if #s == 1 then
      return subst[s] or s
   else
      return gsub(s, "-+/*", "_")
   end
end

local function create_dict(list)
   local p_name = "n_null"
   local s_offset = 0

   print("    .section .rodata")
   print("    .align 2")
   print(p_name .. ": .word 0, 0")

   for _,w in ipairs(list) do
      local name = "n_" .. normalize_name(w)

      if #w > 3 then
         local s_name = "s_" .. normalize_name(w)
         print("    .section .strings")
         print("    .align 2")
         print(s_name .. ": .ascii \"" .. w .. "\"")
         print("    .section .rodata")
         print(name .. ":")
         local nf = bit.lshift(#w, 24)
         nf = bit.bor(nf, s_offset)
         s_offset = s_offset + #w
         s_offset = 4 * math.ceil(s_offset / 4)
         print("    .word", fmt("0x%08x", nf))
      else
         local bytes = ""
         for i=1,#w do
            if bytes ~= "" then bytes = bytes .. ", " end
            bytes = bytes .. "'" .. sub(w, i, i) .. "'"
         end
         for i=1,3-#w do
            bytes = bytes .. ", 0"
         end
         print(name..": .byte", bytes)
         print("    .byte", #w)
      end

      print("    .word", p_name)
      p_name = name
   end
   print("")
   print(".global _dict")
   print(".equ _dict, " .. p_name)
end

return create_dict
