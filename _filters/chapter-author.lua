-- Inserts chapter author and date in small gray text after the first H1
-- heading in PDF output. Runs per-chapter during book PDF compilation.
-- HTML output is unaffected (handled by the title block CSS instead).

local author_str = ""
local date_str   = ""
local inserted   = false

return {
  {
    Meta = function(meta)
      if meta.author then
        author_str = pandoc.utils.stringify(meta.author)
      end
      if meta.date then
        date_str = pandoc.utils.stringify(meta.date)
      end
      return meta
    end
  },
  {
    Header = function(el)
      if el.level ~= 1 or inserted or not FORMAT:match("latex") then
        return nil
      end
      local parts = {}
      if author_str ~= "" then parts[#parts + 1] = author_str end
      if date_str   ~= "" then parts[#parts + 1] = date_str   end
      if #parts == 0 then return nil end
      inserted = true
      local line = table.concat(parts, " \\enspace·\\enspace ")
      local raw = pandoc.RawBlock("latex",
        "\\noindent{\\small\\color{gray}" .. line .. "}\\par\\vspace{0.5em}"
      )
      return { el, raw }
    end
  }
}
