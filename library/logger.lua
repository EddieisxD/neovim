--- Structured Logger for DAG Execution & System Diagnostics
local M = {}

M.levels = {
  TRACE = 1,
  DEBUG = 2,
  INFO = 3,
  WARN = 4,
  ERROR = 5,
}

local current_level = M.levels.INFO
local logs = {}
local log_file_path = vim.fn.stdpath("state") .. "/dag_nvim.log"

--- Set the global log level
---@param level string|number
function M.set_level(level)
  if type(level) == "string" then
    current_level = M.levels[level:upper()] or M.levels.INFO
  elseif type(level) == "number" then
    current_level = level
  end
end

--- Append a log message
---@param level_name string
---@param msg string
---@param meta? table
local function log(level_name, msg, meta)
  local lvl = M.levels[level_name] or M.levels.INFO
  if lvl < current_level then return end

  local time_str = os.date("%H:%M:%S")
  local entry = {
    time = time_str,
    level = level_name,
    message = msg,
    meta = meta or {},
  }
  table.insert(logs, entry)

  local formatted = string.format("[%s] [%s] %s", time_str, level_name, msg)
  if meta and next(meta) then
    formatted = formatted .. " | " .. vim.inspect(meta)
  end

  -- Write to file asynchronously or sync
  local f = io.open(log_file_path, "a")
  if f then
    f:write(formatted .. "\n")
    f:close()
  end

  -- Notify user on WARN / ERROR if neovim UI is available
  if lvl >= M.levels.WARN and vim.notify then
    local notify_lvl = lvl == M.levels.ERROR and vim.log.levels.ERROR or vim.log.levels.WARN
    vim.notify(formatted, notify_lvl, { title = "DAG Engine" })
  end
end

function M.trace(msg, meta) log("TRACE", msg, meta) end
function M.debug(msg, meta) log("DEBUG", msg, meta) end
function M.info(msg, meta)  log("INFO", msg, meta) end
function M.warn(msg, meta)  log("WARN", msg, meta) end
function M.error(msg, meta) log("ERROR", msg, meta) end

--- Get all recorded log entries
---@return table
function M.get_logs()
  return logs
end

--- Clear recorded logs
function M.clear()
  logs = {}
  local f = io.open(log_file_path, "w")
  if f then
    f:write("--- DAG Neovim Log Initialized " .. os.date() .. " ---\n")
    f:close()
  end
end

M.clear()

return M
