# Fresh MacBook setup

Step-by-step, copy-pastable commands to set up these dotfiles on a brand-new Mac. Run each block in order, in the default macOS **Terminal** app until step 8.

## 1. Install the Xcode Command Line Tools (git, make, C compiler)

```bash
xcode-select --install
```

Wait for the GUI installer to finish before you continue.

## 2. Install Homebrew and add it to your PATH

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

> `.zshrc` doesn't put `/opt/homebrew/bin` on PATH, so this line in `~/.zprofile` is required.

## 3. Install the command-line tools

```bash
brew install stow git neovim ripgrep fd fzf bat eza zoxide lazygit \
  imagemagick poppler mpv tree-sitter-cli \
  llvm@22 python@3.13 pipx node maven cmake libpq csvlens
```

```bash
brew install jandedobbeleer/oh-my-posh/oh-my-posh
brew install d99kris/nchat/nchat
```

## 4. Install the apps, font and SDKs

```bash
brew install --cask ghostty font-jetbrains-mono-nerd-font temurin@21 skim basictex dotnet-sdk docker-desktop
```

- `temurin@21` is needed because `.zshrc` runs `/usr/libexec/java_home -v21`, and jdtls requires Java 21 or newer.
- `basictex` and `skim` are for VimTeX. `dotnet-sdk` is for Roslyn/C#. `docker-desktop` is optional.

## 5. Install latexmk for VimTeX

```bash
sudo /Library/TeX/texbin/tlmgr update --self
sudo /Library/TeX/texbin/tlmgr install latexmk
```

## 6. (Optional) Install Dart for the `lang.dart` extra

```bash
brew tap dart-lang/dart && brew install dart
```

## 7. Clone the repo and link everything with stow

```bash
git clone https://github.com/saipreetham99/mac-dotfiles.git ~/dots
```

> If the repo is private, run `brew install gh && gh auth login` first, or set up an SSH key and clone `git@github.com:saipreetham99/mac-dotfiles.git`.

Remove the default files that would block the links, and create the real directories:

```bash
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.pre-dots
rm -rf ~/.config/nvim
rm -f ~/.config/ghostty/config ~/.clang-format ~/themes.json
mkdir -p ~/.config/ghostty ~/.config/nchat
```

> Create `~/.config/ghostty` and `~/.config/nchat` as real directories before you stow. If you don't, stow links the whole directory into the repo. nchat would then write its `history/` and `profiles/` (your login session) into `~/dots`.

```bash
cd ~/dots && stow -v zsh nvim ghostty nchat clang-format
```

Check the links:

```bash
ls -la ~/.zshrc ~/themes.json ~/.clang-format ~/.config/nvim ~/.config/ghostty/config ~/.config/nchat/
```

## 8. Open Ghostty

Quit Terminal and open **Ghostty** from Applications. On the first shell start, `.zshrc` clones its 4 zsh plugins into `~/.config/zsh/plugins` by itself.

## 9. Bootstrap Neovim

Install every plugin at the commits pinned in `lazy-lock.json`:

```bash
nvim --headless "+Lazy! restore" +qa
```

Then open Neovim once and wait for Mason to finish installing language servers (you can watch it in `:Mason`):

```bash
nvim
```

Inside Neovim, install the Roslyn C# server (it comes from a community registry, so it doesn't install automatically) and run the health check:

```vim
:MasonInstall roslyn
:checkhealth
```

## 10. Link your WhatsApp account in nchat

```bash
nchat --setup
```

## 11. Pull plugin updates later

```bash
zplugin-update
```

## Notes

- `.zshrc` has `/Users/siva/...` hardcoded in a few places (the pipx path, the Antigravity path, Docker completions). They only work if your username on the new Mac is also `siva`.
