M = {}

function M.get_files()
  local result = vim.system({ 'git', 'status', '--porcelain', '-uall' },
    { text = true }
  ):wait()

  local output = {}

  if result.code ~= 0 then return output end

  for _, v in pairs(vim.split(result.stdout, '\n')) do
    if v ~= '' then
      local status = v:sub(1, 2)
      local file = v:sub(4)
      table.insert(output, { status = status, file = file })
    end
  end

  return output
end

function M.get_file_diff(status, file)
  print(file)

  local git_cmd = {}
  if status == '??' then
    -- new file
    git_cmd = { 'git', 'diff', '--no-index', '/dev/null', file }
  elseif status:sub(1, 1) ~= ' ' then
    -- staged files
    git_cmd = { 'git', 'diff', '--cached', '--', file }
  else
    -- work tree files
    git_cmd = { 'git', 'diff', '--', file }
  end

  local result = vim.system(git_cmd, { text = true }):wait()

  -- exit codes:
  -- 0 = no diff
  -- 1 = diff exists
  -- >1 = error
  if result.code > 1 then return nil end
  return result.stdout
end

return M
