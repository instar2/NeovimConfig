local M = {}
local expression = "v:lua.require'config.indent'.get(v:lnum)"
local supported = { python = true, rust = true, typescriptreact = true }

local function ancestor(node, kinds)
  while node do
    if kinds[node:type()] then
      return node
    end
    node = node:parent()
  end
end

local function root()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if ok and parser then
    local parsed, trees = pcall(parser.parse, parser)
    if parsed and trees and trees[1] then
      return trees[1]:root()
    end
  end
end

local function at(tree, line, col)
  if tree and line > 0 then
    return tree:descendant_for_range(line - 1, col, line - 1, col)
  end
end

-- Stop at interpolation boundaries: their contents are code, not string payload.
local function literal(node)
  while node do
    local kind = node:type()
    if kind == "interpolation" or kind == "template_substitution" then
      return nil
    end
    if
      kind == "string"
      or kind == "string_literal"
      or kind == "raw_string_literal"
      or kind == "template_string"
    then
      return node
    end
    node = node:parent()
  end
end

local function native()
  local expr = vim.b.user_native_indentexpr
  if not expr or expr == "" or expr == expression then
    return -1
  end
  local ok, value = pcall(vim.fn.eval, expr)
  return ok and value or -1
end

local function syntax_literal(line)
  local in_string = false
  for _, id in ipairs(vim.fn.synstack(line, 1)) do
    local name = vim.fn.synIDattr(id, "name")
    if name:find("Field") or name:find("Substitution") then
      return false
    end
    in_string = in_string
      or name:find("String") ~= nil
      or name:find("Bytes") ~= nil
      or name == "typescriptTemplate"
  end
  return in_string
end

local function interpolation_indent(node, line, text)
  local interpolation = ancestor(node, { interpolation = true, template_substitution = true })
  if not interpolation then
    return
  end
  local container = ancestor(node, {
    arguments = true,
    parenthesized_expression = true,
    list = true,
    dictionary = true,
    set = true,
    tuple = true,
    statement_block = true,
    object = true,
    array = true,
    interpolation = true,
    template_substitution = true,
  })
  local row, col = container:start()
  if row < line - 1 then
    if text:match("^%s*[])}]") then
      return vim.fn.indent(row + 1)
    end
    -- Python aligns to an inline first argument; hanging brackets use one level.
    if vim.bo.filetype == "python" and vim.fn.getline(row + 1):sub(col + 2):match("%S") then
      return vim.fn.virtcol({ row + 1, col + 1 })
    end
    return vim.fn.indent(row + 1) + vim.fn.shiftwidth()
  end
end

local function rust_indent(tree, line, text, prev)
  local first = text:find("%S")
  local node = first and at(tree, line, first - 1)
  -- A delimiter belongs to its immediate container, even inside a closure call.
  if text:match("^%s*[])}]") and node and node:parent() then
    local start = node:parent():start() + 1
    if start < line then
      return vim.fn.indent(start)
    end
  end
  local previous = vim.fn.getline(prev)
  if not first or text:match("^%s*%.[%a_]") then
    local tail = previous:match("^(.-)%s*$")
    local last = at(tree, prev, math.max(0, #tail - 1))
    local call = ancestor(last, { call_expression = true })
    if call and tail:match("%)%??$") then
      local fn = call:field("function")[1]
      if fn and fn:type() == "field_expression" then
        return vim.fn.indent(fn:start() + 1) + vim.fn.shiftwidth()
      end
    end
  end
end

local function jsx_indent(tree, line, text, prev)
  local first = text:find("%S")
  local node = first and at(tree, line, first - 1)
  local tag = ancestor(
    node,
    { jsx_opening_element = true, jsx_self_closing_element = true, jsx_closing_element = true }
  )
  if tag then
    local start = tag:start() + 1
    if tag:type() == "jsx_closing_element" then
      return vim.fn.indent(tag:parent():start() + 1)
    end
    local inside_code = ancestor(node, { jsx_expression = true })
    if start < line and (not inside_code or inside_code:start() < tag:start()) then
      return vim.fn.indent(start) + (text:match("^%s*/?>") and 0 or vim.fn.shiftwidth())
    end
    local element = tag:type() == "jsx_opening_element" and tag:parent() or tag
    local parent = element:parent()
    if start == line and parent then
      if parent:type() == "jsx_element" then
        return vim.fn.indent(parent:start() + 1) + vim.fn.shiftwidth()
      elseif parent:type() == "parenthesized_expression" and parent:start() < line - 1 then
        return vim.fn.indent(parent:start() + 1) + vim.fn.shiftwidth()
      end
    end
  end
  -- Both parenthesized arms of a ternary should use the same hanging indent.
  local parens = ancestor(node, { parenthesized_expression = true })
  if
    parens
    and parens:parent()
    and parens:parent():type() == "ternary_expression"
    and text:match("^%s*%)")
  then
    local start = parens:start() + 1
    if start < line then
      return vim.fn.indent(start)
    end
  end
  if not first then
    local previous = vim.fn.getline(prev):gsub("%s+$", "")
    local last = at(tree, prev, math.max(0, #previous - 1))
    local opening = ancestor(last, { jsx_opening_element = true })
    if opening then
      return vim.fn.indent(opening:start() + 1) + vim.fn.shiftwidth()
    end
  end
end

function M.get(line)
  local tree = root()
  local text = vim.fn.getline(line)
  -- Column zero is intentional: whitespace before a closing quote is payload too.
  local str = literal(at(tree, line, 0))
  if str and str:start() < line - 1 then
    return -1
  end
  if (not tree or tree:has_error()) and syntax_literal(line) then
    return -1
  end
  local first = text:find("%S") or 1
  local node = at(tree, line, first - 1)
  local interpolation = interpolation_indent(node, line, text)
  if interpolation ~= nil then
    return interpolation
  end
  local ft = vim.bo.filetype
  if ft == "python" then
    if text:match("^%s*case%s+.-:%s*$") or text:match("^%s*case%s+.-:%s*#") then
      local node = at(tree, line, (text:find("%S") or 1) - 1)
      local match = ancestor(node, { match_statement = true })
      if match then
        return vim.fn.indent(match:start() + 1) + vim.fn.shiftwidth()
      end
    end
    local value = native()
    -- The bundled Python indent script does not skip pythonBytes syntax groups.
    -- A completed expression statement cannot open a continuation on the next line.
    local prev = vim.fn.prevnonblank(line - 1)
    local previous = vim.fn.getline(prev):gsub("%s+$", "")
    local last = at(tree, prev, math.max(0, #previous - 1))
    if ancestor(last, { comment = true }) then
      last = at(tree, prev, (previous:find("%S") or 1) - 1)
    end
    local statement = ancestor(last, { expression_statement = true })
    if statement and not statement:has_error() and statement:end_() == prev - 1 then
      local base = vim.fn.indent(statement:start() + 1)
      if value > base then
        return base
      end
    end
    return value
  end
  if not tree then
    return native()
  end
  local prev = vim.fn.prevnonblank(line - 1)
  local corrected
  if ft == "rust" then
    corrected = rust_indent(tree, line, text, prev)
  elseif ft == "typescriptreact" then
    corrected = jsx_indent(tree, line, text, prev)
  end
  if corrected ~= nil then
    return corrected
  end
  -- An unfinished construct may parse only as ERROR, or leave the new EOF line
  -- outside the syntax tree. Native indentation has better recovery there.
  if
    tree:has_error() and (not node or node:id() == tree:id() or ancestor(node, { ERROR = true }))
  then
    return native()
  end
  local ok, value = pcall(require("nvim-treesitter").indentexpr)
  return ok and value or native()
end

function M.enter()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line, col = pos[1], pos[2]
  local text = vim.fn.getline(line)
  -- Require an actual JSX opening/closing pair, not tag-like text in a string.
  if text:sub(col, col) == ">" and text:sub(col + 1, col + 2) == "</" then
    local tree = root()
    local opening = ancestor(at(tree, line, col - 1), { jsx_opening_element = true })
    local closing = ancestor(at(tree, line, col + 1), { jsx_closing_element = true })
    if opening and closing and opening:parent():id() == closing:parent():id() then
      local open_name, close_name = opening:field("name")[1], closing:field("name")[1]
      if
        (not open_name and not close_name)
        or (
          open_name
          and close_name
          and vim.treesitter.get_node_text(open_name, 0)
            == vim.treesitter.get_node_text(close_name, 0)
        )
      then
        return vim.api.nvim_replace_termcodes("<CR><C-o>O", true, false, true)
      end
    end
  end
  return require("mini.pairs").cr()
end

function M.attach(buf)
  local ft = vim.bo[buf].filetype
  if not supported[ft] then
    return
  end
  if vim.bo[buf].indentexpr ~= expression then
    vim.b[buf].user_native_indentexpr = vim.bo[buf].indentexpr
  end
  -- Native indentation uses synID to skip strings/comments, including on fallback.
  -- Tree-sitter.start() clears this option, so restore it after starting the parser.
  vim.bo[buf].syntax = ft
  vim.bo[buf].indentexpr = expression
  if ft == "python" then
    vim.opt_local.indentkeys:append("0=case")
  elseif ft == "typescriptreact" then
    vim.keymap.set(
      "i",
      "<CR>",
      M.enter,
      { buffer = buf, expr = true, replace_keycodes = false, desc = "Newline inside JSX or pairs" }
    )
    vim.b[buf].undo_ftplugin = (vim.b[buf].undo_ftplugin or "") .. " | silent! iunmap <buffer> <CR>"
  end
end

function M.setup()
  vim.g.python_indent = vim.tbl_extend("force", vim.g.python_indent or {}, {
    open_paren = "shiftwidth()",
    closed_paren_align_last_line = false,
  })
end

return M
