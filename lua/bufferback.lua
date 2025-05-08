-- bufferback.nvim
local M = {}

-- Stack to store recently closed buffers
M.buffer_stack = {}
-- Maximum number of buffers to remember
M.max_stack_size = 20
-- Default keymaps configuration
M.default_keymaps = {
  delete_buffer = "<S-w>", -- Shift+W to delete buffer
  restore_buffer = "<S-M-w>", -- Shift+Opt+W to restore buffer
  list_stack = "<leader>bl", -- List the buffer stack
  enable = true, -- Whether to use default keymaps
}

-- Push a buffer to the stack when it's deleted
local function push_to_stack(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Skip empty buffers or special buffers
  if filepath == "" or filepath:match("^%w+://") then
    return
  end

  -- Store cursor position too for better restoration
  local cursor_pos = vim.api.nvim_buf_get_mark(bufnr, '"')

  -- Add to the stack
  table.insert(M.buffer_stack, 1, {
    filepath = filepath,
    cursor_pos = cursor_pos,
  })

  -- Trim the stack if it exceeds max size
  if #M.buffer_stack > M.max_stack_size then
    table.remove(M.buffer_stack)
  end
end

-- Delete the current buffer
function M.delete_buffer()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(current_bufnr)

  -- Don't try to push to stack here - the BufDelete autocmd will handle that

  -- Delete the buffer
  vim.cmd("bdelete")

  -- Optional: Notify user
  if filepath ~= "" then
    vim.notify("Deleted buffer: " .. vim.fn.fnamemodify(filepath, ":t"), vim.log.levels.INFO)
  end
end

-- Restore the most recently closed buffer
function M.restore_buffer()
  if #M.buffer_stack == 0 then
    vim.notify("No buffers to restore", vim.log.levels.INFO)
    return
  end

  local buf_info = table.remove(M.buffer_stack, 1)

  -- Check if file exists before restoring
  if vim.fn.filereadable(buf_info.filepath) == 0 then
    vim.notify("File no longer exists: " .. buf_info.filepath, vim.log.levels.WARN)
    -- Try the next file in stack
    return M.restore_buffer()
  end

  -- Open the file
  vim.cmd("edit " .. vim.fn.fnameescape(buf_info.filepath))

  -- Restore cursor position
  if buf_info.cursor_pos then
    vim.api.nvim_win_set_cursor(0, buf_info.cursor_pos)
  end

  vim.notify("Restored: " .. vim.fn.fnamemodify(buf_info.filepath, ":t"), vim.log.levels.INFO)
end

-- List all buffers in the stack
function M.list_buffer_stack()
  if #M.buffer_stack == 0 then
    vim.notify("Buffer stack is empty", vim.log.levels.INFO)
    return
  end

  local lines = { "BufferBack Stack:" }
  for i, buf in ipairs(M.buffer_stack) do
    -- Get filename only for cleaner display
    local filename = vim.fn.fnamemodify(buf.filepath, ":t")
    table.insert(lines, string.format("%d: %s", i, filename))
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Setup keymaps
local function setup_keymaps(keymap_opts)
  -- Merge with defaults
  local keymaps = vim.tbl_deep_extend("force", M.default_keymaps, keymap_opts or {})

  -- Only set up keymaps if enabled
  if keymaps.enable then
    -- Delete buffer
    if keymaps.delete_buffer then
      vim.keymap.set("n", keymaps.delete_buffer, M.delete_buffer, {
        noremap = true,
        desc = "Delete current buffer and add to stack",
      })
    end

    -- Restore buffer
    if keymaps.restore_buffer then
      vim.keymap.set("n", keymaps.restore_buffer, M.restore_buffer, {
        noremap = true,
        desc = "Restore most recently closed buffer",
      })
    end

    -- List stack
    if keymaps.list_stack then
      vim.keymap.set("n", keymaps.list_stack, M.list_buffer_stack, {
        noremap = true,
        desc = "List all buffers in stack",
      })
    end
  end
end

-- Setup the plugin
function M.setup(opts)
  opts = opts or {}

  -- Apply user options
  M.max_stack_size = opts.max_stack_size or M.max_stack_size

  -- Create autocmd to track buffer deletions
  vim.api.nvim_create_autocmd("BufDelete", {
    pattern = "*",
    callback = function(args)
      push_to_stack(args.buf)
    end,
  })

  -- Create user commands
  vim.api.nvim_create_user_command("BufferBack", M.restore_buffer, {})
  vim.api.nvim_create_user_command("BufferBackList", M.list_buffer_stack, {})
  vim.api.nvim_create_user_command("BufferBackDelete", M.delete_buffer, {})

  -- Setup keymaps with user overrides
  setup_keymaps(opts.keymaps)
end

return M
