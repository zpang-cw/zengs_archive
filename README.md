# How These Dot Files are Implemented

## ZSH

### Requirement

- ensure the following block appened to end of `$HOME/.zshrc`

```
# CUSTOM ALIASES
for file in $HOME/.zsh_customs/*; do
    if [ -f "$file" ]; then
        source "$file"
    fi
done
```

### Purpose of each .zsh file

- `aliases.zsh` - custom aliases
- `for_fun.zsh` - shell prompt appearances
- `functions.zsh` - custom shell functions
