--- Modular DAG System Unit Test Suite
--- Run via: nvim --headless -u init.lua -c "luafile tests/run_tests.lua" +q

local dag_lib = require("library.dag")
local metatable_util = require("library.metatable")
local loader_adapter = require("library.loader_adapter")

local passed = 0
local failed = 0

local function assert_test(condition, name, err_msg)
  if condition then
    passed = passed + 1
    print("  ✓ PASSED: " .. name)
  else
    failed = failed + 1
    print("  ✗ FAILED: " .. name .. " - " .. tostring(err_msg))
  end
end

print("\n==========================================")
print("  Running System Unit Test Suite")
print("==========================================\n")

-- Test 1: DAG Acyclic Topological Sort
do
  local g = dag_lib.new()
  local order = {}
  g:add_node({ id = "nodeB", phase = 2, deps = { "nodeA" }, exec = function() table.insert(order, "nodeB") end })
  g:add_node({ id = "nodeA", phase = 1, deps = {}, exec = function() table.insert(order, "nodeA") end })

  local stats = g:execute()
  assert_test(stats.executed == 2 and order[1] == "nodeA" and order[2] == "nodeB",
    "DAG Acyclic Topological Sort Execution Order")
end

-- Test 2: DAG Cycle Detection
do
  local g = dag_lib.new()
  g:add_node({ id = "nodeA", phase = 1, deps = { "nodeB" }, exec = function() end })
  g:add_node({ id = "nodeB", phase = 1, deps = { "nodeA" }, exec = function() end })

  local ok, err = pcall(function() g:topological_sort() end)
  assert_test(not ok and tostring(err):find("Circular dependency detected"),
    "DAG Cycle Detection Guard")
end

-- Test 3: Metatable Sealing & Unsealing
do
  local tbl = { a = 1, b = { c = 2 } }
  local sealed = metatable_util.seal(tbl, "TestTable")
  local write_ok = pcall(function() sealed.new_key = 99 end)
  local unsealed = metatable_util.unseal(sealed)
  unsealed.new_key = 100

  assert_test(not write_ok and unsealed.new_key == 100,
    "Metatable Sealing Guard & Unsealing Mutation Bridge")
end

-- Test 4: Loader Adapter Universal Spec Transformation
do
  local raw_spec = loader_adapter.spec({ name = "catppuccin/nvim", opts = { flavour = "mocha" } })
  local adapted = loader_adapter.to_lazy_specs({ raw_spec }, { plugin_source = "auto" })

  assert_test(#adapted == 1 and type(adapted[1].config) == "function",
    "Loader Adapter Lazy Spec Transformation")
end

-- Test 5: Persistent State Engine Load & Save
do
  local Bundle = _G.Bundle
  if Bundle then
    Bundle.state.colorscheme = "oxocarbon"
    Bundle:save_state()

    Bundle.state.colorscheme = nil
    Bundle:load_state()

    assert_test(Bundle.state.colorscheme == "oxocarbon",
      "Persistent State Engine Cross-Session JSON Serialization")
  end
end

print("\n==========================================")
print(string.format("  Test Summary: %d Passed, %d Failed", passed, failed))
print("==========================================\n")

if failed > 0 then
  vim.cmd("cquit 1")
end
