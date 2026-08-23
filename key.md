  ### General

   Mode    Key         Action
  ━━━━━━  ━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   N       Space w     Write the current buffer
  ──────  ──────────  ──────────────────────────────────────────────────
   N       Space q     Quit the current window
  ──────  ──────────  ──────────────────────────────────────────────────
   V       Ctrl-c      Copy selection to the system clipboard
  ──────  ──────────  ──────────────────────────────────────────────────
   I       Ctrl-v      Paste from the system clipboard
  ──────  ──────────  ──────────────────────────────────────────────────
   N       Ctrl-v      Paste from the system clipboard after the cursor
  ──────  ──────────  ──────────────────────────────────────────────────
   V       Ctrl-v      Replace the selection from the system clipboard
  ──────  ──────────  ──────────────────────────────────────────────────
   N       Space t     Toggle a bottom terminal split
  ──────  ──────────  ──────────────────────────────────────────────────
   T       Esc         Leave terminal mode
  ──────  ──────────  ──────────────────────────────────────────────────
   N       Ctrl-s      Switch between source and header using clangd
  ──────  ──────────  ──────────────────────────────────────────────────
   N       Space aa    Toggle the assembly view

  Defined in lua/config/controls.lua:10.

  ### LSP

  These are buffer-local and become active when an LSP client attaches.

   Key         Action
  ━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   gd          Go to definition
  ──────────  ──────────────────────────────────────────
   gD          Go to declaration
  ──────────  ──────────────────────────────────────────
   gr          Show references
  ──────────  ──────────────────────────────────────────
   gi          Go to implementation
  ──────────  ──────────────────────────────────────────
   K           Show hover documentation
  ──────────  ──────────────────────────────────────────
   ]e          Jump to next error
  ──────────  ──────────────────────────────────────────
   [e          Jump to previous error
  ──────────  ──────────────────────────────────────────
   Space rn    Rename symbol
  ──────────  ──────────────────────────────────────────
   Space ca    Show code actions
  ──────────  ──────────────────────────────────────────
   Space e     Show diagnostics for the current line
  ──────────  ──────────────────────────────────────────
   Space f     Format the current buffer asynchronously

  Defined in lua/plugins/lsp.lua:175.

  ### Telescope

   Key         Action
  ━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Space ff    Find files
  ──────────  ────────────────────────────────────────────────────
   Space fg    Search text with live grep, including hidden files
  ──────────  ────────────────────────────────────────────────────
   Space fb    Find open buffers
  ──────────  ────────────────────────────────────────────────────
   Space fh    Search help tags

  Defined in lua/plugins/telescope.lua:7.

  ### Git and Gitsigns

  The Neogit mappings are global. Gitsigns mappings are buffer-local to files where Gitsigns attaches.

   Mode    Key         Action
  ━━━━━━  ━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   N       Space gg    Open Neogit
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gc    Open Neogit’s commit view
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gl    Open the Git log
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       ]c          Next Git hunk; retains normal diff navigation in diff mode
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       [c          Previous Git hunk; retains normal diff navigation in diff mode
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gs    Stage current hunk
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   V       Space gs    Stage selected lines
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gr    Reset current hunk
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   V       Space gr    Reset selected lines
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gS    Stage the entire buffer
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gR    Reset the entire buffer
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gp    Preview the current hunk
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gi    Preview the hunk inline
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gb    Show full blame information for the current line
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gd    Diff the buffer against the index
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gD    Diff the buffer against the previous revision
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gq    Send hunks to the quickfix list
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gB    Toggle current-line blame
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   N       Space gw    Toggle word-level diff highlighting
  ──────  ──────────  ────────────────────────────────────────────────────────────────
   V/O     ih          Select the current Git hunk

  Defined in lua/plugins/git.lua:10.

  ### Debugging

   Key                     Action
  ━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   F5 / Space dc           Start or continue debugging
  ──────────────────────  ──────────────────────────────────────────────────────────
   Shift-F5 / Space dt     Stop/terminate debugging
  ──────────────────────  ──────────────────────────────────────────────────────────
   F9 / Space db           Toggle breakpoint
  ──────────────────────  ──────────────────────────────────────────────────────────
   F10 / Space do          Step over
  ──────────────────────  ──────────────────────────────────────────────────────────
   F11 / Space di          Step into
  ──────────────────────  ──────────────────────────────────────────────────────────
   Shift-F11 / Space dO    Step out
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dB                Add a conditional breakpoint
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dl                Add a log point
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dp                Pause execution
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dr                Restart debugging
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dL                Run the previous debug configuration
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space df                Run to cursor
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dk                Move one stack frame up
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dj                Move one stack frame down
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space du                Toggle the debugger UI
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space dR                Toggle the debugger REPL
  ──────────────────────  ──────────────────────────────────────────────────────────
   Space de                Evaluate an expression; works in normal and visual modes

  Defined in lua/plugins/dap.lua:77.

  ### Performance annotations

   Mode    Key          Action
  ━━━━━━  ━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   N       Space plf    Load flat perf data
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space plg    Load a perf call graph
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space plo    Open a flamegraph inside Neovim
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space plO    Open an external interactive flamegraph
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pe     Select a perf event
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pF     Cycle annotation display format
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pa     Annotate perf data
  ──────  ───────────  ──────────────────────────────────────────────
   V       Space pa     Annotate the selected region
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pf     Annotate the current function
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pt     Toggle perf annotations
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space ph     Show hottest lines
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space ps     Show hottest symbols
  ──────  ───────────  ──────────────────────────────────────────────
   N       Space pc     Show hottest callers of the current function
  ──────  ───────────  ──────────────────────────────────────────────
   V       Space pc     Show hottest callers for the selection

  Inside Perfanno’s Telescope pickers:

   Mode    Key       Action
  ━━━━━━  ━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   I       Ctrl-h    Navigate to hottest callers
  ──────  ────────  ─────────────────────────────
   I       Ctrl-l    Navigate to hottest callees
  ──────  ────────  ─────────────────────────────
   N       gu        Navigate to hottest callers
  ──────  ────────  ─────────────────────────────
   N       gd        Navigate to hottest callees

  Defined in lua/plugins/perfanno.lua:30.

  ### Completion

  Blink completion uses its super-tab preset in insert mode:

   Key              Action
  ━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Tab              Select and accept completion, or move forward through snippet fields
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Shift-Tab        Move backward through snippet fields
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Ctrl-Space       Show completion/documentation
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Ctrl-e           Cancel completion
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Up / Ctrl-p      Select previous completion
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Down / Ctrl-n    Select next completion
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Ctrl-b           Scroll documentation up
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Ctrl-f           Scroll documentation down
  ───────────────  ──────────────────────────────────────────────────────────────────────
   Ctrl-k           Show or hide signature help

  Configured in lua/plugins/completion.lua:9.
