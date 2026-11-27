local src = game:HttpGet("https://raw.githubusercontent.com/AllForOneScripts/Quirks/main/Wire_Source.lua?t=" .. tick())
local bytes = {}
for i = 1, #src do
    bytes[i] = bit32.bxor(src:byte(i), 171)
end
local out = table.concat(bytes, ",")
if setclipboard then setclipboard(out) end
print("=== BYTES COPIADOS ===")
print(out)
