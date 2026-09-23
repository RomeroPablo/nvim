-- A character drawing view over an ordinary text buffer. The view is a movable
-- window into sparse coordinates; the backing buffer remains a normal file.
local M = {}

local views = {}
local active_count = 0
local previous_mouse
local tools = { "brush", "line", "arrow", "box", "ellipse", "erase", "text" }
local selection_ns = vim.api.nvim_create_namespace("asciiflow.selection")
local bit = require("bit")
local up, right, down, left = 1, 2, 4, 8
local glyph_for = {
	[1] = "│", [2] = "─", [3] = "└", [4] = "│", [5] = "│", [6] = "┌", [7] = "├",
	[8] = "─", [9] = "┘", [10] = "─", [11] = "┴", [12] = "┐", [13] = "┤", [14] = "┬", [15] = "┼",
}
local mask_for = {
	["│"] = 5, ["─"] = 10, ["└"] = 3, ["┌"] = 6, ["├"] = 7, ["┘"] = 9,
	["┴"] = 11, ["┐"] = 12, ["┤"] = 13, ["┬"] = 14, ["┼"] = 15,
	["|"] = 5, ["-"] = 10, ["+"] = 15,
}
local arrow_connection = { ["►"] = left, ["◄"] = right, ["▲"] = down, ["▼"] = up }
local saved_options = { "number", "relativenumber", "signcolumn", "wrap", "list", "spell", "foldcolumn", "colorcolumn", "cursorline", "winbar", "virtualedit" }

local function key(x, y)
	return x .. "," .. y
end

local function characters(s)
	local chars = vim.fn.split(s, "\\zs")
	for _, char in ipairs(chars) do
		if vim.fn.strchars(char) ~= 1 or vim.fn.strdisplaywidth(char) ~= 1 or char:byte(1) < 32 then
			return nil
		end
	end
	return chars
end

local function load_source(state)
	local cells = {}
	for y, line in ipairs(vim.api.nvim_buf_get_lines(state.source, 0, -1, false)) do
		local chars = characters(line)
		if not chars then
			return false
		end
		for x, char in ipairs(chars) do
			if char ~= " " then
				cells[key(x - 1 + (state.origin_x or 0), y - 1 + (state.origin_y or 0))] = char
			end
		end
	end
	state.cells = cells
	state.tick = vim.api.nvim_buf_get_changedtick(state.source)
	return true
end

local function bounds(cells)
	local min_x, min_y, max_x, max_y
	for position in pairs(cells) do
		local x, y = position:match("^(-?%d+),(-?%d+)$")
		x, y = tonumber(x), tonumber(y)
		min_x = min_x and math.min(min_x, x) or x
		min_y = min_y and math.min(min_y, y) or y
		max_x = max_x and math.max(max_x, x) or x
		max_y = max_y and math.max(max_y, y) or y
	end
	return min_x, min_y, max_x, max_y
end

local function serialize(cells)
	local min_x, min_y, max_x, max_y = bounds(cells)
	if not min_x then
		return { "" }, 0, 0
	end
	min_x, min_y = math.min(0, min_x), math.min(0, min_y)
	local lines = {}
	for y = min_y, max_y do
		local row = {}
		for x = min_x, max_x do
			row[#row + 1] = cells[key(x, y)] or " "
		end
		lines[#lines + 1] = table.concat(row):gsub(" +$", "")
	end
	return lines, min_x, min_y
end

local function undo_sequence(state)
	return vim.api.nvim_buf_call(state.source, function()
		return vim.fn.undotree().seq_cur
	end)
end

local function plot(cells, x, y, char, merge)
	local position = key(x, y)
	if char == " " then
		cells[position] = nil
		return
	end
	local old = cells[position]
	if merge and old and old ~= char and mask_for[old] and mask_for[char] then
		cells[position] = glyph_for[bit.bor(mask_for[old], mask_for[char])]
	elseif merge and old and old ~= char
		and (old == "╱" or old == "╲" or old == "/" or old == "\\")
		and (char == "╱" or char == "╲") then
		cells[position] = "╳"
	else
		cells[position] = char
	end
end

local function existing_connections(cells, x, y)
	local mask = mask_for[cells[key(x, y)]] or 0
	if mask == 0 then
		return 0
	end
	local connected = 0
	for _, neighbor in ipairs({
		{ 0, -1, up, down }, { 1, 0, right, left },
		{ 0, 1, down, up }, { -1, 0, left, right },
	}) do
		local direction, opposite = neighbor[3], neighbor[4]
		if bit.band(mask, direction) ~= 0 then
			local adjacent = cells[key(x + neighbor[1], y + neighbor[2])]
			local adjacent_mask = mask_for[adjacent] or arrow_connection[adjacent] or 0
			if bit.band(adjacent_mask, opposite) ~= 0 then
				connected = bit.bor(connected, direction)
			end
		end
	end
	return connected ~= 0 and connected or mask
end

local function connect(cells, connections, x, y, direction)
	local position = key(x, y)
	local mask = bit.bor(connections[position] or existing_connections(cells, x, y), direction)
	connections[position] = mask
	cells[position] = glyph_for[mask]
end

local function line(cells, x0, y0, x1, y1, char, connections)
	connections = connections or {}
	local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
	local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
	local error_value = dx - dy
	if x0 == x1 and y0 == y1 then
		plot(cells, x0, y0, char or "•")
		return
	end
	while true do
		if x0 == x1 and y0 == y1 then
			break
		end
		local next_x, next_y = x0, y0
		local doubled = 2 * error_value
		if doubled > -dy then
			error_value = error_value - dy
			next_x = x0 + sx
		end
		if doubled < dx then
			error_value = error_value + dx
			next_y = y0 + sy
		end
		if char then
			plot(cells, x0, y0, char)
			plot(cells, next_x, next_y, char)
		elseif next_y == y0 then
			connect(cells, connections, x0, y0, sx > 0 and right or left)
			connect(cells, connections, next_x, next_y, sx > 0 and left or right)
		elseif next_x == x0 then
			connect(cells, connections, x0, y0, sy > 0 and down or up)
			connect(cells, connections, next_x, next_y, sy > 0 and up or down)
		else
			local glyph = sx == sy and "╲" or "╱"
			plot(cells, x0, y0, glyph, true)
			plot(cells, next_x, next_y, glyph, true)
		end
		x0, y0 = next_x, next_y
	end
end

local function shape(cells, tool, x0, y0, x1, y1, brush, connections)
	connections = connections or {}
	if tool == "brush" or tool == "erase" then
		line(cells, x0, y0, x1, y1, tool == "erase" and " " or brush)
	elseif tool == "line" or tool == "arrow" then
		line(cells, x0, y0, x1, y1, nil, connections)
		if tool == "arrow" and (x0 ~= x1 or y0 ~= y1) then
			local dx, dy = x1 - x0, y1 - y0
			local head = math.abs(dx) >= math.abs(dy) and (dx > 0 and "►" or "◄") or (dy > 0 and "▼" or "▲")
			plot(cells, x1, y1, head)
		end
	elseif tool == "box" then
		local left, right = math.min(x0, x1), math.max(x0, x1)
		local top, bottom = math.min(y0, y1), math.max(y0, y1)
		line(cells, left, top, right, top, nil, connections)
		line(cells, left, bottom, right, bottom, nil, connections)
		line(cells, left, top, left, bottom, nil, connections)
		line(cells, right, top, right, bottom, nil, connections)
	elseif tool == "ellipse" then
		local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		local rx, ry = math.abs(x1 - x0) / 2, math.abs(y1 - y0) / 2
		if rx == 0 or ry == 0 then
			line(cells, x0, y0, x1, y1)
			return
		end
		local steps = math.ceil(4 * math.pi * math.max(rx, ry))
		for i = 0, steps do
			local angle = 2 * math.pi * i / steps
			local x, y = math.floor(cx + rx * math.cos(angle) + 0.5), math.floor(cy + ry * math.sin(angle) + 0.5)
			local tx, ty = -rx * math.sin(angle), ry * math.cos(angle)
			local glyph = math.abs(ty) * 3 < math.abs(tx) and "─"
				or math.abs(tx) * 3 < math.abs(ty) and "│"
				or tx * ty > 0 and "╲" or "╱"
			plot(cells, x, y, glyph)
		end
	end
end

local function size(state)
	return vim.api.nvim_win_get_width(state.win), vim.api.nvim_win_get_height(state.win)
end

local function canvas_window(state)
	local current = vim.api.nvim_get_current_win()
	if vim.api.nvim_win_get_buf(current) == state.canvas then
		state.win = current
		return true
	end
	if vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_buf(state.win) == state.canvas then
		return true
	end
	local windows = vim.fn.win_findbuf(state.canvas)
	if #windows > 0 then
		state.win = windows[1]
		return true
	end
	return false
end

local function sync_source(state)
	if not vim.api.nvim_buf_is_valid(state.source) then
		return false
	end
	if vim.api.nvim_buf_get_changedtick(state.source) == state.tick then
		return true
	end
	if not load_source(state) then
		vim.notify("ASCII Flow: source contains a character wider than one cell; close the canvas to edit it", vim.log.levels.WARN)
		return false
	end
	state.pending = nil
	state.selection = nil
	state.moving = nil
	vim.notify("ASCII Flow: canvas refreshed after the source changed", vim.log.levels.INFO)
	return true
end

local function selection_bounds(state)
	if not state.selection then
		return nil
	end
	local anchor = state.selection
	return math.min(anchor.x, state.x), math.min(anchor.y, state.y),
		math.max(anchor.x, state.x), math.max(anchor.y, state.y)
end

local function within(x, y, left_x, top_y, right_x, bottom_y)
	return x >= left_x and x <= right_x and y >= top_y and y <= bottom_y
end

local function visible_cursor(state)
	local width, height = size(state)
	state.view_x = math.min(state.view_x, state.x)
	state.view_y = math.min(state.view_y, state.y)
	state.view_x = math.max(state.view_x, state.x - width + 1)
	state.view_y = math.max(state.view_y, state.y - height + 1)
end

local function refresh(state)
	if not vim.api.nvim_buf_is_valid(state.canvas) or not canvas_window(state) then
		return
	end
	if not sync_source(state) then
		return
	end
	visible_cursor(state)
	local width, height = size(state)
	local preview = {}
	local preview_connections = {}
	if state.pending and state.tool ~= "brush" and state.tool ~= "erase" then
		shape(preview, state.tool, state.pending.x, state.pending.y, state.x, state.y,
			state.brush, preview_connections)
	end
	local selected_left, selected_top, selected_right, selected_bottom = selection_bounds(state)
	if state.moving then
		local dx, dy = state.x - state.moving.start_x, state.y - state.moving.start_y
		for _, cell in ipairs(state.moving.cells) do
			preview[key(cell.x + dx, cell.y + dy)] = cell.char
		end
		selected_left, selected_top = state.moving.left + dx, state.moving.top + dy
		selected_right, selected_bottom = state.moving.right + dx, state.moving.bottom + dy
	end
	local lines = {}
	for row = 0, height - 1 do
		local chars = {}
		for col = 0, width - 1 do
			local x, y = state.view_x + col, state.view_y + row
			local position = key(x, y)
			local base, overlay = state.cells[position], preview[position]
			if state.moving and within(x, y, state.moving.left, state.moving.top,
				state.moving.right, state.moving.bottom) then
				base = nil
			end
			if overlay and base and state.pending then
				local mask_a, mask_b = existing_connections(state.cells, x, y), preview_connections[position]
				overlay = mask_for[overlay] and mask_a ~= 0 and mask_b
					and glyph_for[bit.bor(mask_a, mask_b)] or overlay
			end
			chars[#chars + 1] = overlay or base or " "
		end
		lines[#lines + 1] = table.concat(chars)
	end
	vim.bo[state.canvas].modifiable = true
	vim.api.nvim_buf_set_lines(state.canvas, 0, -1, false, lines)
	vim.bo[state.canvas].modified = false
	vim.bo[state.canvas].modifiable = false
	vim.api.nvim_buf_clear_namespace(state.canvas, selection_ns, 0, -1)
	if selected_left then
		for y = math.max(selected_top, state.view_y), math.min(selected_bottom, state.view_y + height - 1) do
			local first = math.max(selected_left - state.view_x, 0)
			local last = math.min(selected_right - state.view_x + 1, width)
			if first < last then
				local row = y - state.view_y
				vim.api.nvim_buf_set_extmark(state.canvas, selection_ns, row, vim.fn.byteidx(lines[row + 1], first), {
					end_row = row, end_col = vim.fn.byteidx(lines[row + 1], last),
					hl_group = "Visual", priority = 200,
				})
			end
		end
	end
	local cursor_row, cursor_col = state.y - state.view_y + 1, state.x - state.view_x
	vim.api.nvim_win_set_cursor(state.win, { cursor_row, vim.fn.byteidx(lines[cursor_row], cursor_col) })
	local pending = state.pending and " (set endpoint)" or ""
	if state.selection then
		pending = state.moving and " (move: Space commits)" or " (selection: m move, d delete)"
	end
	vim.wo[state.win].winbar = " ASCII Flow  [" .. state.tool .. pending .. "]  " .. state.x .. "," .. state.y
		.. "  1-7 tools  v select  Space draw  HJKL pan  q edit  ? help "
end

local function commit(state)
	if not sync_source(state) then
		return
	end
	local lines, origin_x, origin_y = serialize(state.cells)
	if not vim.deep_equal(lines, vim.api.nvim_buf_get_lines(state.source, 0, -1, false)) then
		vim.api.nvim_buf_call(state.source, function()
			vim.go.undolevels = vim.go.undolevels
		end)
		vim.api.nvim_buf_set_lines(state.source, 0, -1, false, lines)
		state.tick = vim.api.nvim_buf_get_changedtick(state.source)
	end
	state.origin_x, state.origin_y = origin_x, origin_y
	state.origins[undo_sequence(state)] = { x = origin_x, y = origin_y }
	refresh(state)
end

local function close(state)
	if not state or not views[state.canvas] then
		return
	end
	views[state.canvas] = nil
	active_count = active_count - 1
	if active_count == 0 and previous_mouse then
		vim.o.mouse = previous_mouse
		previous_mouse = nil
	end
	if vim.api.nvim_buf_is_valid(state.source) then
		vim.bo[state.source].bufhidden = state.source_bufhidden
	end
	for _, win in ipairs(vim.fn.win_findbuf(state.canvas)) do
		if vim.api.nvim_buf_is_valid(state.source) then
			vim.api.nvim_win_set_buf(win, state.source)
			local min_x, min_y = bounds(state.cells)
			min_x, min_y = math.min(0, min_x or 0), math.min(0, min_y or 0)
			local row = math.min(state.y - min_y + 1, vim.api.nvim_buf_line_count(state.source))
			if row > 0 then
				local text = vim.api.nvim_buf_get_lines(state.source, row - 1, row, false)[1]
				local column = math.min(math.max(state.x - min_x, 0), vim.fn.strchars(text))
				vim.api.nvim_win_set_cursor(win, { row, vim.fn.byteidx(text, column) })
			end
		end
		for option, value in pairs(state.window_options) do
			vim.api.nvim_set_option_value(option, value, { win = win })
		end
	end
	if vim.api.nvim_buf_is_valid(state.canvas) then
		vim.api.nvim_buf_delete(state.canvas, { force = true })
	end
end

local function move(state, dx, dy)
	if not sync_source(state) then
		return
	end
	local old_x, old_y = state.x, state.y
	state.x, state.y = state.x + dx, state.y + dy
	if state.pending and not state.selection and (state.tool == "brush" or state.tool == "erase") then
		shape(state.cells, state.tool, old_x, old_y, state.x, state.y, state.brush)
		commit(state)
	else
		refresh(state)
	end
end

local function begin_move(state)
	if not sync_source(state) then
		return
	end
	if not state.selection or state.moving then
		return
	end
	local left_x, top_y, right_x, bottom_y = selection_bounds(state)
	local cells = {}
	for position, char in pairs(state.cells) do
		local x, y = position:match("^(-?%d+),(-?%d+)$")
		x, y = tonumber(x), tonumber(y)
		if within(x, y, left_x, top_y, right_x, bottom_y) then
			cells[#cells + 1] = { x = x, y = y, char = char }
		end
	end
	state.moving = {
		left = left_x, top = top_y, right = right_x, bottom = bottom_y,
		start_x = state.x, start_y = state.y, cells = cells,
	}
	refresh(state)
end

local function finish_move(state)
	local moving = state.moving
	if not moving then
		return
	end
	local dx, dy = state.x - moving.start_x, state.y - moving.start_y
	for position in pairs(state.cells) do
		local x, y = position:match("^(-?%d+),(-?%d+)$")
		x, y = tonumber(x), tonumber(y)
		if within(x, y, moving.left, moving.top, moving.right, moving.bottom) then
			state.cells[position] = nil
		end
	end
	for _, cell in ipairs(moving.cells) do
		state.cells[key(cell.x + dx, cell.y + dy)] = cell.char
	end
	state.moving = nil
	state.selection = nil
	commit(state)
end

local function delete_selection(state)
	if not sync_source(state) then
		return
	end
	if not state.selection then
		return
	end
	local left_x, top_y, right_x, bottom_y = selection_bounds(state)
	for position in pairs(state.cells) do
		local x, y = position:match("^(-?%d+),(-?%d+)$")
		x, y = tonumber(x), tonumber(y)
		if within(x, y, left_x, top_y, right_x, bottom_y) then
			state.cells[position] = nil
		end
	end
	state.moving = nil
	state.selection = nil
	commit(state)
end

local function action(state)
	if not sync_source(state) then
		return
	end
	if state.moving then
		finish_move(state)
		return
	elseif state.selection then
		vim.notify("ASCII Flow: press m to move or d to delete the selected rectangle", vim.log.levels.INFO)
		return
	end
	if state.tool == "text" then
		vim.ui.input({ prompt = "ASCII text: " }, function(value)
			if not value or not views[state.canvas] then
				return
			end
			if not sync_source(state) then
				return
			end
			local chars = characters(value)
			if not chars then
				vim.notify("ASCII Flow: text must use one-cell printable characters", vim.log.levels.WARN)
				return
			end
			for i, char in ipairs(chars) do
				plot(state.cells, state.x + i - 1, state.y, char)
			end
			commit(state)
		end)
		return
	end
	if not state.pending then
		state.pending = { x = state.x, y = state.y }
		if state.tool == "brush" or state.tool == "erase" then
			plot(state.cells, state.x, state.y, state.tool == "erase" and " " or state.brush)
			commit(state)
		else
			refresh(state)
		end
	else
		if state.tool ~= "brush" and state.tool ~= "erase" then
			shape(state.cells, state.tool, state.pending.x, state.pending.y, state.x, state.y, state.brush)
			state.pending = nil
			commit(state)
		else
			state.pending = nil
			refresh(state)
		end
	end
end

local function select_tool(state, tool)
	state.tool = tool
	state.pending = nil
	state.selection = nil
	state.moving = nil
	refresh(state)
end

local function source_history(state, command)
	local ok, err = pcall(vim.api.nvim_buf_call, state.source, function()
		vim.cmd(command)
	end)
	if not ok then
		vim.notify("ASCII Flow: " .. tostring(err), vim.log.levels.WARN)
	end
	local origin = state.origins[undo_sequence(state)]
	if origin then
		state.origin_x, state.origin_y = origin.x, origin.y
	end
	load_source(state)
	state.pending = nil
	state.selection = nil
	state.moving = nil
	refresh(state)
end

local function map(state, lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = state.canvas, silent = true, nowait = true, desc = "ASCII Flow: " .. desc })
end

local function install_maps(state)
	for _, direction in ipairs({ { "h", -1, 0 }, { "j", 0, 1 }, { "k", 0, -1 }, { "l", 1, 0 },
		{ "<Left>", -1, 0 }, { "<Down>", 0, 1 }, { "<Up>", 0, -1 }, { "<Right>", 1, 0 } }) do
		map(state, direction[1], function() move(state, direction[2], direction[3]) end, "Move cursor")
	end
	for _, direction in ipairs({ { "H", -8, 0 }, { "J", 0, 8 }, { "K", 0, -8 }, { "L", 8, 0 } }) do
		map(state, direction[1], function()
			state.view_x = state.view_x + direction[2]
			state.view_y = state.view_y + direction[3]
			move(state, direction[2], direction[3])
		end, "Pan canvas")
	end
	for index, tool in ipairs(tools) do
		map(state, tostring(index), function() select_tool(state, tool) end, "Select " .. tool .. " tool")
	end
	map(state, "<Space>", function() action(state) end, "Start or finish drawing")
	for _, lhs in ipairs({ "v", "V", "<C-v>" }) do
		map(state, lhs, function()
			if state.selection then
				state.selection = nil
				state.moving = nil
			else
				state.pending = nil
				state.selection = { x = state.x, y = state.y }
			end
			refresh(state)
		end, "Toggle rectangular selection")
	end
	map(state, "m", function() begin_move(state) end, "Move selected rectangle")
	map(state, "d", function()
		if not state.moving then
			delete_selection(state)
		end
	end, "Delete selected rectangle")
	map(state, "x", function()
		if state.moving then
			return
		end
		if state.selection then
			delete_selection(state)
		else
			plot(state.cells, state.x, state.y, " ")
			commit(state)
		end
	end, "Delete selected rectangle or current cell")
	map(state, "<Esc>", function()
		if state.moving then
			state.x, state.y = state.moving.start_x, state.moving.start_y
			state.moving = nil
			refresh(state)
		elseif state.selection then
			state.selection = nil
			refresh(state)
		elseif state.pending then
			state.pending = nil
			refresh(state)
		else
			close(state)
		end
	end, "Cancel shape or return to text")
	map(state, "q", function() close(state) end, "Return to text buffer")
	map(state, "u", function() source_history(state, "silent undo") end, "Undo drawing")
	map(state, "<C-r>", function() source_history(state, "silent redo") end, "Redo drawing")
	map(state, "c", function()
		vim.ui.input({ prompt = "Brush character: ", default = state.brush }, function(value)
			local chars = value and characters(value)
			if chars and #chars == 1 then
				state.brush = value
			elseif value then
				vim.notify("ASCII Flow: choose one printable one-cell character", vim.log.levels.WARN)
			end
		end)
	end, "Choose brush character")
	map(state, "?", M.help, "Show drawing keys")
	local function mouse_point(draw)
		local mouse = vim.fn.getmousepos()
		if mouse.winid > 0 and vim.api.nvim_win_get_buf(mouse.winid) == state.canvas
			and mouse.winrow > 0 and mouse.wincol > 0 then
			state.win = mouse.winid
			state.x = state.view_x + mouse.wincol - 1
			state.y = state.view_y + mouse.winrow - 1
			if state.selection then
				refresh(state)
			elseif draw then
				action(state)
			end
		end
	end
	map(state, "<LeftMouse>", function() mouse_point(true) end, "Place a point or select a corner")
	map(state, "<LeftDrag>", function() mouse_point(false) end, "Extend rectangular selection")
end

function M.help()
	vim.notify(table.concat({
		"ASCII Flow: 1 brush, 2 line, 3 arrow, 4 box, 5 ellipse, 6 erase, 7 text",
		"h/j/k/l or arrows move; H/J/K/L pan 8 cells; Space starts/finishes a shape",
		"v or Ctrl-v starts a rectangle; move or click/drag its opposite corner",
		"m moves the rectangle, then move and press Space; d or x deletes selected cells",
		"c changes brush character; Esc cancels or exits; q returns to text editing",
		"u / Ctrl-r undo/redo; :w or :w file saves",
	}, "\n"), vim.log.levels.INFO)
end

function M.open()
	local win = vim.api.nvim_get_current_win()
	local source = vim.api.nvim_get_current_buf()
	if views[source] then
		close(views[source])
		return
	end
	if vim.bo[source].buftype ~= "" or not vim.bo[source].modifiable then
		vim.notify("ASCII Flow: open a modifiable text buffer first", vim.log.levels.WARN)
		return
	end
	local state = {
		win = win, source = source, canvas = vim.api.nvim_create_buf(false, true),
		tool = "line", brush = "•", x = 0, y = 0, view_x = 0, view_y = 0,
		origin_x = 0, origin_y = 0, origins = {},
		source_bufhidden = vim.bo[source].bufhidden, window_options = {},
	}
	if not load_source(state) then
		vim.api.nvim_buf_delete(state.canvas, { force = true })
		vim.notify("ASCII Flow supports printable, one-cell characters (no tabs or wide glyphs)", vim.log.levels.WARN)
		return
	end
	state.origins[undo_sequence(state)] = { x = 0, y = 0 }
	local row, col = unpack(vim.api.nvim_win_get_cursor(win))
	local source_line = vim.api.nvim_buf_get_lines(source, row - 1, row, false)[1]
	state.x, state.y = vim.fn.charidx(source_line, col), row - 1
	state.view_x, state.view_y = math.max(0, state.x - 5), math.max(0, row - 5)
	for _, option in ipairs(saved_options) do
		state.window_options[option] = vim.api.nvim_get_option_value(option, { win = win })
	end
	vim.bo[source].bufhidden = "hide"
	vim.bo[state.canvas].buftype = "acwrite"
	vim.bo[state.canvas].bufhidden = "wipe"
	vim.api.nvim_buf_set_name(state.canvas, "ascii-flow://" .. source .. "/" .. state.canvas)
	vim.api.nvim_win_set_buf(win, state.canvas)
	for option, value in pairs({ number = false, relativenumber = false, signcolumn = "no", wrap = false,
		list = false, spell = false, foldcolumn = "0", colorcolumn = "", cursorline = true, virtualedit = "all" }) do
		vim.api.nvim_set_option_value(option, value, { win = win })
	end
	views[state.canvas] = state
	active_count = active_count + 1
	if active_count == 1 then
		previous_mouse = vim.o.mouse
		vim.o.mouse = "a"
	end
	install_maps(state)
	vim.api.nvim_create_autocmd("BufWriteCmd", { buffer = state.canvas, callback = function(args)
		if vim.api.nvim_buf_is_valid(source) then
			local target = args.file
			local canvas_name = vim.api.nvim_buf_get_name(state.canvas)
			local source_name = vim.api.nvim_buf_get_name(source)
			vim.api.nvim_buf_call(source, function()
				if target == canvas_name or target == source_name then
					vim.cmd("write")
				else
					vim.cmd("write " .. vim.fn.fnameescape(target))
				end
			end)
			vim.bo[state.canvas].modified = false
		end
	end })
	vim.api.nvim_create_autocmd("BufWipeout", { buffer = state.canvas, callback = function()
		if views[state.canvas] then
			vim.schedule(function() close(state) end)
		end
	end })
	refresh(state)
end

function M.setup()
	vim.api.nvim_create_user_command("AsciiFlow", M.open, { desc = "Toggle the ASCII drawing canvas" })
	vim.api.nvim_create_user_command("AsciiFlowHelp", M.help, { desc = "Show ASCII Flow drawing keys" })
	vim.api.nvim_create_user_command("AsciiFlowTool", function(args)
		local state = views[vim.api.nvim_get_current_buf()]
		if not state then
			vim.notify("ASCII Flow: open the canvas first", vim.log.levels.WARN)
			return
		end
		if not vim.tbl_contains(tools, args.args) then
			vim.notify("ASCII Flow: unknown tool " .. args.args, vim.log.levels.WARN)
			return
		end
		select_tool(state, args.args)
	end, { nargs = 1, complete = function() return tools end, desc = "Select an ASCII drawing tool" })
	vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { callback = function()
		for _, state in pairs(views) do
			refresh(state)
		end
	end })
end

return M
