--- Directed Acyclic Graph (DAG) Execution Engine
--- Solves module execution order, detects circular dependencies, and handles side-effectful execution.

local logger = require("library.logger")

local M = {}

M.Phases = {
  SETUP    = 10,
  OPTIONS  = 20,
  KEYMAPS  = 30,
  AUTOCMDS = 40,
  LOADER   = 50,
  PLUGINS  = 60,
  POST     = 70,
}

local PhaseNames = {
  [10] = "SETUP",
  [20] = "OPTIONS",
  [30] = "KEYMAPS",
  [40] = "AUTOCMDS",
  [50] = "LOADER",
  [60] = "PLUGINS",
  [70] = "POST",
}

--- Creates a new DAG instance
---@return table
function M.new()
  local self = setmetatable({}, { __index = M })
  self.nodes = {}
  return self
end

--- Add a node to the DAG
---@param node { id: string, phase?: number, deps?: string[], exec: function, meta?: table }
function M:add_node(node)
  assert(node.id, "[DAG] Node must have an 'id'")
  assert(type(node.exec) == "function", string.format("[DAG] Node '%s' must have an 'exec' function", node.id))

  if self.nodes[node.id] then
    logger.warn(string.format("[DAG] Overwriting node '%s'", node.id))
  end

  self.nodes[node.id] = {
    id = node.id,
    phase = node.phase or M.Phases.PLUGINS,
    deps = node.deps or {},
    exec = node.exec,
    meta = node.meta or {},
  }
end

--- Detect cycles in the DAG using Depth-First Search (DFS)
---@return string[]|nil cycle_path Returns cycle path array if detected, nil if acyclic
function M:detect_cycles()
  local visited = {}
  local in_stack = {}
  local cycle_path = {}

  local function dfs(node_id, path)
    visited[node_id] = true
    in_stack[node_id] = true
    table.insert(path, node_id)

    local node = self.nodes[node_id]
    if node then
      for _, dep_id in ipairs(node.deps) do
        if self.nodes[dep_id] then
          if not visited[dep_id] then
            local result = dfs(dep_id, path)
            if result then return result end
          elseif in_stack[dep_id] then
            -- Found cycle!
            table.insert(path, dep_id)
            return path
          end
        end
      end
    end

    in_stack[node_id] = false
    table.remove(path)
    return nil
  end

  for id in pairs(self.nodes) do
    if not visited[id] then
      local path = dfs(id, {})
      if path then return path end
    end
  end

  return nil
end

--- Topologically sort DAG nodes respecting phase priorities and declared dependencies
---@return table[] sorted_nodes
function M:topological_sort()
  local cycle = self:detect_cycles()
  if cycle then
    local cycle_str = table.concat(cycle, " -> ")
    local err_msg = string.format("[DAG Error] Circular dependency detected in graph: %s", cycle_str)
    logger.error(err_msg)
    error(err_msg)
  end

  -- Compute in-degrees for nodes
  local in_degree = {}
  local adj = {}

  for id in pairs(self.nodes) do
    in_degree[id] = 0
    adj[id] = {}
  end

  for id, node in pairs(self.nodes) do
    for _, dep in ipairs(node.deps) do
      if self.nodes[dep] then
        table.insert(adj[dep], id)
        in_degree[id] = in_degree[id] + 1
      else
        logger.warn(string.format("[DAG] Node '%s' depends on unknown node '%s'", id, dep))
      end
    end
  end

  -- Queue nodes with 0 in-degree
  local queue = {}
  for id, deg in pairs(in_degree) do
    if deg == 0 then
      table.insert(queue, self.nodes[id])
    end
  end

  local sorted = {}

  while #queue > 0 do
    -- Sort queue by phase priority so earlier phases execute first among independent nodes
    table.sort(queue, function(a, b)
      if a.phase ~= b.phase then
        return a.phase < b.phase
      end
      return a.id < b.id
    end)

    local curr = table.remove(queue, 1)
    table.insert(sorted, curr)

    for _, neighbor_id in ipairs(adj[curr.id]) do
      in_degree[neighbor_id] = in_degree[neighbor_id] - 1
      if in_degree[neighbor_id] == 0 then
        table.insert(queue, self.nodes[neighbor_id])
      end
    end
  end

  if #sorted < vim.tbl_count(self.nodes) then
    error("[DAG Error] Topological sort failed to resolve all nodes.")
  end

  return sorted
end

--- Execute all nodes in topological order with logging and error isolation
---@return { executed: number, failed: number, total_time_ms: number }
function M:execute()
  local sorted = self:topological_sort()
  local stats = { executed = 0, failed = 0, total_time_ms = 0 }
  local start_all = vim.loop.hrtime()

  logger.info(string.format("[DAG Execution] Starting execution of %d nodes", #sorted))

  for _, node in ipairs(sorted) do
    local phase_name = PhaseNames[node.phase] or ("PHASE_" .. tostring(node.phase))
    logger.debug(string.format("[DAG Run] Executing '%s' [%s]", node.id, phase_name))

    local node_start = vim.loop.hrtime()
    local ok, err = xpcall(node.exec, debug.traceback)
    local elapsed_ms = (vim.loop.hrtime() - node_start) / 1e6

    if ok then
      stats.executed = stats.executed + 1
      logger.info(string.format("[DAG Success] '%s' completed in %.2fms", node.id, elapsed_ms))
    else
      stats.failed = stats.failed + 1
      logger.error(string.format("[DAG Failure] '%s' failed in %.2fms:\n%s", node.id, elapsed_ms, tostring(err)))
    end
  end

  stats.total_time_ms = (vim.loop.hrtime() - start_all) / 1e6
  logger.info(string.format("[DAG Execution Summary] %d executed, %d failed in %.2fms",
    stats.executed, stats.failed, stats.total_time_ms))

  return stats
end

return M
