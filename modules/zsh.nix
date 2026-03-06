{ config, lib, pkgs, ... }:

{
  users.defaultUserShell    = pkgs.zsh;
  users.users.root.shell    = pkgs.zsh; # defaultUserShell does not apply to root

  programs.zsh = {
    enable = true;

    # autosuggestions is safe to enable via the NixOS wrapper.
    # syntaxHighlighting is intentionally disabled here — it is sourced manually
    # in interactiveShellInit to enforce the required load order:
    #   autosuggestions → syntax-highlighting → history-substring-search
    autosuggestions.enable = true;
    syntaxHighlighting.enable = false;

    histSize = 10000;

    setOptions = [
      "HIST_IGNORE_ALL_DUPS"   # no duplicate entries in history
      "HIST_SAVE_NO_DUPS"      # don't write duplicates to histfile
      "SHARE_HISTORY"          # share history across sessions
      "AUTO_CD"                # type a dir name to cd into it
      "INTERACTIVE_COMMENTS"   # allow # comments in interactive shell
      "COMPLETE_IN_WORD"       # complete from both ends of a word
      "ALWAYS_TO_END"          # move cursor to end after completion
    ];

    # plugins = [
    #   {
    #     # Up/down arrows search history by current prefix
    #     name = "zsh-history-substring-search";
    #     src  = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
    #   }
    # ];

    shellAliases = {
      # Navigation
      ls    = "eza";
      ll    = "eza -lh --git";
      la    = "eza -lah --git";
      lt    = "eza --tree";
      ".."  = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      mkdir  = "mkdir -p";
      cp     = "cp -i";
      mv     = "mv -i";

      # Git
      g    = "git";
      gs   = "git status";
      ga   = "git add";
      gaa  = "git add --all";
      gc   = "git commit";
      gcm  = "git commit -m";
      gca  = "git commit --amend --no-edit";
      gp   = "git push";
      gpl  = "git pull";
      gl   = "git log --oneline --graph --decorate";
      gd   = "git diff";
      gds  = "git diff --staged";
      gco  = "git checkout";
      gb   = "git branch";
      gst  = "git stash";
      gsp  = "git stash pop";

      # Nix / NixOS
      nrs  = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      nrb  = "sudo nixos-rebuild boot   --flake /etc/nixos#nixos";
      nrt  = "sudo nixos-rebuild test   --flake /etc/nixos#nixos";
      nfu  = "sudo nix flake update /etc/nixos";
      ngc  = "sudo nix-collect-garbage -d";
      nso  = "sudo nix store optimise";
      nsh  = "nix shell nixpkgs#";
      ndev = "nix develop";
    };

    interactiveShellInit = ''
      # Load order: syntax-highlighting must precede history-substring-search,
      # otherwise history-substring-search's ZLE widget wrapping breaks.
      # autosuggestions is already sourced earlier by its NixOS wrapper.
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # History substring search — bind to arrow keys
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Word navigation — Ctrl+Left / Ctrl+Right
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      # Home / End / Delete
      bindkey '^[[H'  beginning-of-line
      bindkey '^[[F'  end-of-line
      bindkey '^[[3~' delete-char

      # fzf — fuzzy completion (**<TAB>) and key bindings:
      #   Ctrl+T  fuzzy-find file and paste to command line
      #   Ctrl+R  fuzzy search command history
      #   Alt+C   fuzzy cd into subdirectory
      export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=none'
      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      # sudo widget — ESC ESC prepends/removes sudo on the current line
      sudo-command-line() {
        [[ -z $BUFFER ]] && zle up-history
        if [[ $BUFFER == sudo\ * ]]; then
          LBUFFER="''${LBUFFER#sudo }"
        else
          LBUFFER="sudo $LBUFFER"
        fi
      }
      zle -N sudo-command-line
      bindkey '^[^[' sudo-command-line
    '';
  };

  # Starship — cross-shell prompt.
  programs.starship = {
    enable   = true;
    settings = {
      add_newline = false;

      # Segment order — keep it lean
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      username = {
        show_always = false;
        format      = "[$user]($style)@";
        style_user  = "bold cyan";
      };

      hostname = {
        ssh_only = true;
        format   = "[$hostname]($style) ";
        style    = "bold green";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo  = true;
        style             = "bold blue";
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        style  = "bold purple";
        symbol = " ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style  = "bold red";
      };

      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "nix ";
        style  = "bold cyan";
      };

      cmd_duration = {
        min_time = 2000;
        format   = "[$duration]($style) ";
        style    = "yellow";
      };

      character = {
        success_symbol = "[$](bold green)";
        error_symbol   = "[$](bold red)";
      };
    };
  };

  # Nerd Fonts for terminal icon/glyph support.
  fonts = {
    packages = with pkgs.nerd-fonts; [
      caskaydia-cove   # Cascadia Code with Nerd Font glyphs
      jetbrains-mono   # JetBrains Mono with Nerd Font glyphs
    ];
    fontconfig.defaultFonts.monospace = [
      "CaskaydiaCove Nerd Font Mono"
      "JetBrainsMono Nerd Font Mono"
    ];
  };

  environment.systemPackages = with pkgs; [ eza fzf ];
}
