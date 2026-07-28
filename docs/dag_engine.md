# Directed Acyclic Graph (DAG) Execution Engine

The DAG engine ([`library/dag.lua`](file:///home/addy/.config/nvim.wip/library/dag.lua)) manages module execution ordering, dependency resolution, cycle detection, and isolated side-effect execution.

---

## 1. Execution Phases

Nodes in the DAG are assigned an integer phase priority (`Phases`):

| Phase Constant | Value | Purpose |
| :--- | :--- | :--- |
| `SETUP` | 10 | Early runtime setup and basic system options |
| `OPTIONS` | 20 | Setting `vim.opt`, global variables, and options |
| `KEYMAPS` | 30 | Core keybindings registration |
| `AUTOCMDS` | 40 | Autocommands and augroups setup |
| `LOADER` | 50 | Plugin manager setup (Lazy.nvim / Lze) |
| `PLUGINS` | 60 | Plugin-specific logic and configs |
| `POST` | 70 | Late startup hooks, statusline, and UI post-processing |

---

## 2. Dependency Resolution & Topological Sorting

The DAG engine uses **Kahn's Algorithm** combined with phase priority ordering:

1. Computes the **in-degree** (number of unresolved dependencies) for every node.
2. Nodes with `in_degree == 0` are placed into an execution queue.
3. Queue elements are sorted primary by `phase` priority (e.g. `OPTIONS` runs before `KEYMAPS`) and secondary by `id`.
4. Nodes are popped and executed sequentially.

---

## 3. Cycle Detection

Before sorting, the DAG engine performs a **Depth-First Search (DFS)** cycle check:
- If a dependency loop is detected (e.g., `Module A -> Module B -> Module A`), sorting halts immediately.
- A visual trace is logged and thrown:
  ```
  [DAG Error] Circular dependency detected in graph: module_b -> module_a -> module_b
  ```

---

## 4. Isolated Execution & Error Handling

Each DAG node is executed inside an `xpcall` block:
- Node start and finish times are measured with nanosecond precision (`vim.loop.hrtime()`).
- If a node throws an exception, the failure is caught, logged with a full stack traceback, and recorded in execution stats without crashing Neovim or blocking unrelated nodes.
