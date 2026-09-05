# dots

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) — zsh, Neovim (LazyVim), Ghostty, and nchat.

## What's included

| Package  | Symlinks to                                                    | Notes                                                   |
| -------- | --------------------------------------------------------------- | -------------------------------------------------------- |
| `zsh`    | `~/.zshrc`, `~/themes.json`                                    | zsh config + oh-my-posh theme                           |
| `nvim`   | `~/.config/nvim`                                               | LazyVim-based Neovim config                             |
| `ghostty`| `~/.config/ghostty/config`                                     | Config only — `config.bak` stays local, not tracked     |
| `nchat`  | `~/.config/nchat/{app,color,key,ui}.conf`, `nchat-pick.sh`      | Settings only — see [Nchat](#nchat) below               |

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/) — `brew install stow`
- [oh-my-posh](https://ohmyposh.dev/) — `brew install oh-my-posh` (prompt theme)
- [zoxide](https://github.com/ajeetdsouza/zoxide) — `brew install zoxide` (powers `cd`, see `.zshrc`)
- [fzf](https://github.com/junegunn/fzf) — `brew install fzf` (Ctrl+T file picker, Ctrl+F picker, Ctrl+R history)
- [eza](https://github.com/eza-community/eza) — `brew install eza` (`ls`/`ll`/`la`/`tree` aliases)
- [bat](https://github.com/sharkdp/bat) — `brew install bat` (`MANPAGER`, fzf preview window)
- [Ghostty](https://ghostty.org/) — JetBrainsMono Nerd Font installed, for `font-family` in `config`
- Neovim — see `nvim/.config/nvim`'s own requirements: a Nerd Font, ripgrep, fd, a C compiler, a terminal supporting the kitty graphics protocol, ImageMagick, poppler, mpv, and Skim
- nchat — `brew tap d99kris/nchat && brew install nchat`

## Install on a new machine

```bash
git clone <your-repo-url> ~/dots
cd ~/dots

# remove anything that would conflict with stow's symlinks
rm -f ~/.zshrc
rm -rf ~/.config/nvim ~/.config/ghostty ~/.config/nchat

stow zsh nvim ghostty nchat
```

Stow won't link over a real file or folder, so anything already sitting at those paths on a fresh machine needs to be cleared first — that's what the block above does.

## Zsh

The four zsh plugins referenced in `.zshrc` (`zsh-autosuggestions`, `zsh-history-substring-search`, `zsh-vi-mode`, `fast-syntax-highlighting`) aren't vendored in this repo and don't need a plugin manager — a small `_zplugin_load` helper clones each one straight from GitHub into `~/.config/zsh/plugins` the first time a new shell starts, then sources it. Nothing to install up front beyond the tools listed above.

Run `zplugin-update` any time to `git pull --ff-only` every cloned plugin.

## Nchat

Deliberately **not** included: `history`, `profiles`, `debug.info`, `log.txt`, `log.txt.1`, `temp`, `version`. `history` is the actual message cache and `profiles` holds the live login session — both are private data, not config, so they're excluded on purpose and never touch this repo.

After stowing on a new machine, link the account fresh:

```bash
nchat --setup
```

## Not tracked

- `~/.config/ghostty/config.bak`
- `~/oh-my-posh-themes/` — never added to a package
- `~/.config/zsh/plugins/` — auto-cloned by `.zshrc`, see [Zsh](#zsh) above

## Making changes

Edit files at their normal paths (`~/.zshrc`, `~/.config/nvim/...`, etc.) exactly as usual — they're symlinks into this repo, not copies, so there's nothing to sync. From `~/dots`:

```bash
git add .
git commit -m "update config"
git push
```
