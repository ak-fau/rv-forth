local sub = string.sub

local function create_dict(list)
   local p_name = "n_null"

   print("    .section .rodata")
   print("    .align 2")
   print(p_name .. ": .word 0, 0")

   for _,w in ipairs(list) do
      if #w > 3 then
         error "Name length >3 is not supported [yet]"
      else
         local name = "n_" .. w
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
         print("    .word", p_name)
         p_name = name
      end
   end
   print(".global _dict")
   print(".equ _dict, " .. p_name)
end

return create_dict
