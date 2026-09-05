# 💤 LazyVim Config

A personal Neovim setup built on [LazyVim](https://github.com/LazyVim/LazyVim), tuned for inline image/video/PDF preview, a fast floating-terminal workflow, and multi-language development (C/C++, Python, Dart, Docker, .NET, LaTeX).

## Features

- 🎨 Transparent [Tokyo Night](https://github.com/folke/tokyonight.nvim) theme
- 📂 [oil.nvim](https://github.com/stevearc/oil.nvim) as the default file explorer — edit your filesystem like a buffer
- 🖼️ Inline image preview and video playback, from the explorer or the file under your cursor
- 📖 Inline PDF viewer — pages rendered right in the buffer, from the terminal or oil
- 💻 Floating terminal workflow (float / horizontal / vertical) via toggleterm
- ⚡ [flash.nvim](https://github.com/folke/flash.nvim) for fast jump motions
- ⇥ [tabout.nvim](https://github.com/abecodes/tabout.nvim) — `<Tab>` jumps past a closing bracket/quote instead of indenting
- 🔍 Telescope tuned with split-open keymaps
- 📄 VimTeX wired up for Skim (macOS PDF viewer)
- 🧩 LazyVim extras for C/C++, Python, Dart, Docker, .NET, JSON, and LaTeX

## Notable Configuration

### Theme
Tokyo Night (`night` style) with transparency forced on — `Normal`, `NormalFloat`, `SignColumn`, `LineNr`, and `FoldColumn` all get their background stripped so the terminal background shows through.

### File Explorer & Media Preview
[oil.nvim](https://github.com/stevearc/oil.nvim) is the default explorer: hidden files shown, confirmation skipped for simple edits. Its own image preview is disabled — instead:

- **[focal.nvim](https://github.com/hmdfrds/focal.nvim)** shows a hover preview on `CursorHold` (backed by image.nvim). `updatetime` drops from Neovim's 4000ms default to 300ms so the hover actually feels responsive.
- **[image.nvim](https://github.com/3rd/image.nvim)** renders the images, using the `kitty` backend and `magick_cli` processor.
- `<leader>p` — Quick Look–style preview: images float in a window, videos play via `mpv`.
- `<leader>mv` — plays a file directly with `mpv`, resolving the path from the oil entry under your cursor, or `<cfile>` elsewhere.

### Inline PDF Viewer
`pdf.lua` renders PDFs directly in the buffer instead of dumping raw bytes as text. A `BufReadCmd` autocmd takes over `*.pdf` entirely, rasterises the current page to a PNG with `pdftoppm` (200 DPI), and draws it with image.nvim — the same code path whether the file is opened from the terminal (`nvim foo.pdf`) or picked in oil. Page count comes from `pdfinfo`.

Both calls run async via `vim.system` so nothing blocks input while a page renders, re-renders are debounced (250ms) so scrolling through oil doesn't spawn a process per cursor move, and a generation counter discards results for a page you've already scrolled past.

- `]p` / `[p` — next / previous page
- `r` — force a redraw of the current page

### Tab Navigation
[tabout.nvim](https://github.com/abecodes/tabout.nvim) makes `<Tab>` jump past a closing `'`, `"`, `` ` ``, `)`, `]`, or `}` instead of inserting a literal tab or indenting (`<S-Tab>` does the same backwards). Loaded eagerly, not lazy, with high priority so it attaches before completion's own `<Tab>` mapping.

### Terminal
[toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) runs in three flavors — floating, horizontal, vertical — each on its own keymap, with terminal-mode mappings for window navigation and closing without killing the job.

### Motions & Search
[flash.nvim](https://github.com/folke/flash.nvim) is wired into normal/visual/operator-pending modes for both regular and Treesitter-based jumps, toggleable from the command line.

### Telescope
Extra keymaps send the selected result straight to a horizontal or vertical split; Treesitter previews are disabled for snappier scrolling.

### LaTeX
VimTeX opens compiled PDFs in **Skim** (`vimtex_view_method = "skim"`) — macOS only, swap this out on other platforms.

## Requirements

- **Neovim** ≥ 0.9 (0.10+ recommended — `lazy.lua` falls back between `vim.uv`/`vim.loop`, so both are supported)
- **Git**
- A **Nerd Font**, set as your terminal font (icons in bufferline, oil, Telescope, statusline)
- **ripgrep** and **fd** — Telescope live grep / file finding
- A **C compiler** and **make** — Treesitter parsers and `telescope-fzf-native`
- **kitty**, or another terminal supporting the kitty graphics protocol (Ghostty, WezTerm, etc.) — required by image.nvim's `kitty` backend
- **ImageMagick** (`magick` CLI) — required by image.nvim's `magick_cli` processor
- **poppler** (`pdftoppm` + `pdfinfo`) — `brew install poppler` — powers the inline PDF viewer
- **mpv** — powers the video-preview keymaps
- **Skim.app** (macOS) — PDF viewer for VimTeX

Mason installs the language servers, formatters, and debug adapters for the enabled extras (clangd, Python tools, Dart, Docker, OmniSharp, texlab, etc.) automatically on first launch.

## Installation

```bash
# back up any existing config
mv ~/.config/nvim ~/.config/nvim.bak

git clone <your-repo-url> ~/.config/nvim
nvim
```

On first launch, `lazy.nvim` bootstraps itself and installs every plugin pinned in `lazy-lock.json`. Afterward, run `:Mason` to confirm language tooling installed correctly, and `:checkhealth` to check Treesitter, Telescope, and image.nvim specifically.

## Structure

```
.
├── lua/
│   ├── config/
│   │   ├── autocmds.lua     # custom autocommands (LazyVim defaults only)
│   │   ├── keymaps.lua      # hjkl-only nav, quick preview, mpv playback
│   │   ├── lazy.lua         # lazy.nvim bootstrap + setup
│   │   └── options.lua      # custom options (LazyVim defaults only)
│   └── plugins/
│       ├── bufferline.lua
│       ├── example.lua      # disabled — kept as LazyVim's reference spec
│       ├── extend-vimtex.lua
│       ├── flash.lua
│       ├── focal.lua
│       ├── image.lua
│       ├── oil.lua
│       ├── pdf.lua          # inline PDF viewer (pdftoppm/pdfinfo + image.nvim)
│       ├── tabout.lua
│       ├── telescope.lua
│       ├── terminal.lua
│       └── tokyonight.lua
├── init.lua                 # entry point — loads config.lazy
├── lazy-lock.json           # pinned plugin commits
├── lazyvim.json              # enabled LazyVim extras
├── stylua.toml               # Lua formatter settings
└── .neoconf.json              # lua_ls settings for editing this config
```

## Keymaps

Leader key is `<space>` (LazyVim default). Only custom mappings are listed below — see [LazyVim's own keymaps](https://www.lazyvim.org/keymaps) for everything else.

| Keymap | Mode | Action |
|---|---|---|
| `<Up>` `<Down>` `<Left>` `<Right>` | Normal | Disabled — forces `hjkl` |
| `o` | Normal | Open line below; skips auto-comment insertion on the last line |
| `<leader>p` | Normal | Quick preview: images float, videos play via mpv |
| `q` | Normal (preview window) | Close the image preview window |
| `<leader>mv` | Normal | Play a video with mpv in a floating terminal |
| `<leader>o` | Normal | Open oil.nvim with a vertical preview split |
| `<leader>O` | Normal | Open oil.nvim in a floating window |
| `]p` / `[p` | Normal (PDF buffer) | Next / previous PDF page |
| `r` | Normal (PDF buffer) | Redraw current PDF page |
| `<Tab>` / `<S-Tab>` | Insert (inside brackets/quotes) | Tab out via tabout.nvim |
| `s` | Normal/Visual/Op-pending | Flash jump |
| `S` | Normal/Visual/Op-pending | Flash Treesitter jump |
| `r` | Op-pending | Flash remote |
| `R` | Op-pending/Visual | Flash Treesitter search |
| `<C-s>` | Command-line | Toggle Flash search |
| `<C-s>` / `<C-v>` | Telescope (insert/normal) | Open selection in a horizontal / vertical split |
| `<leader>tt` | Normal | Toggle floating terminal |
| `<leader>th` | Normal | Toggle horizontal terminal |
| `<leader>tv` | Normal | Toggle vertical terminal |
| `<esc>` | Terminal | Back to Normal mode |
| `<C-h/j/k/l>` | Terminal | Move to the window left/below/above/right |
| `<C-q>` | Terminal | Close the terminal window |
| `q` | Normal (terminal buffer) | Close the terminal window |

## Plugins

### Custom Plugins
| Plugin | Purpose |
|---|---|
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | Colorscheme, configured transparent |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | Default file explorer |
| [focal.nvim](https://github.com/hmdfrds/focal.nvim) | Hover preview on cursor hold |
| [image.nvim](https://github.com/3rd/image.nvim) | Renders images in the terminal, and PDF pages via `pdf.lua` |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Floating/split terminals, mpv playback |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffer tabs with a smart close command |
| [flash.nvim](https://github.com/folke/flash.nvim) | Jump motions |
| [tabout.nvim](https://github.com/abecodes/tabout.nvim) | Tab out of brackets/quotes instead of indenting |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (+ [fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)) | Fuzzy finder |
| [vimtex](https://github.com/lervag/vimtex) | LaTeX support, Skim as PDF viewer |

`pdf.lua` itself isn't a plugin — it's a `BufReadCmd` autocmd built on image.nvim, listed above.

The rest of `lazy-lock.json` — completion, git signs, formatting/linting, which-key, and other quality-of-life plugins — comes bundled with LazyVim's own defaults and the extras below.

### LazyVim Extras Enabled
| Extra | Adds |
|---|---|
| `coding.yanky` | Yank/paste history |
| `dap.core`, `dap.nlua` | Debugging, including this config's own Lua |
| `editor.telescope` | Base Telescope integration |
| `lang.clangd` | C/C++ |
| `lang.cmake` | CMake |
| `lang.dart` | Dart |
| `lang.docker` | Dockerfile |
| `lang.dotnet` | .NET / C# (OmniSharp) |
| `lang.json` | JSON, with schema support |
| `lang.python` | Python |
| `lang.tex` | LaTeX tooling (texlab) |
| `util.rest` | REST client ([kulala.nvim](https://github.com/mistweaverco/kulala.nvim)) |
| `util.startuptime` | Startup time profiling |

## Formatting

Lua files are formatted with [StyLua](https://github.com/JohnnyMorganz/StyLua): 2-space indent, 120-column width (see `stylua.toml`).

## License

[Apache License 2.0](./LICENSE)
