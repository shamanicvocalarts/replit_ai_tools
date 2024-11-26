#!/bin/bash

# Create directory structure
INSTALL_DIR="$HOME/.ai_tools"
BIN_DIR="$INSTALL_DIR/bin"
# CONFIG_DIR="$HOME/.config/shell_gpt"

mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Install base packages through interactive shell
echo "Installing AI tools..."

# pip install --no-cache-dir shell-gpt[litellm]
pip install --no-cache-dir aider-chat

echo "Downloading Replit-optimized Aider config..."
curl -o "/home/runner/workspace/.aider.conf.yml" https://raw.githubusercontent.com/shamanicvocalarts/replit_ai_tools/main/.aider.conf.yml

# Create the .sgptrc configuration file
# cat > "$CONFIG_DIR/.sgptrc" << 'EOL'
# OPENAI_API_KEY="$OPENROUTER_API_KEY"
# API_BASE_URL=https://openrouter.ai/api/v1
# CHAT_CACHE_LENGTH=100
# CHAT_CACHE_PATH=/tmp/shell_gpt/chat_cache
# CACHE_LENGTH=100
# CACHE_PATH=/tmp/shell_gpt/cache
# REQUEST_TIMEOUT=60
# DEFAULT_MODEL=openrouter/deepseek/deepseek-chat
# DEFAULT_COLOR=magenta
# DEFAULT_EXECUTE_SHELL_CMD=false
# DISABLE_STREAMING=false
# CODE_THEME=default
# OPENAI_FUNCTIONS_PATH=/home/runner/.config/shell_gpt/functions
# SHOW_FUNCTIONS_OUTPUT=false
# OPENAI_USE_FUNCTIONS=true
# USE_LITELLM=true
# ROLE_STORAGE_PATH=/home/runner/.config/shell_gpt/roles
# PRETTIFY_MARKDOWN=true
# SHELL_INTERACTION=true
# OS_NAME=auto
# SHELL_NAME=auto
# EOL

# Create the set_alias.sh script
cat > "$INSTALL_DIR/set_alias.sh" << 'EOL'
#!/bin/bash
alias aiderDS="$HOME/.ai_tools/bin/aiderDS"
echo "Updated PATH: $PATH"
if alias aiderDS >/dev/null 2>&1; then
    echo "aiderDS alias is set correctly."
else
    echo "aiderDS alias is not set correctly."
fi
EOL

# # Create the set_api_key.sh script
# cat > "$INSTALL_DIR/set_api_key.sh" << 'EOL'
# #!/bin/bash
# if [ "$#" -ne 1 ]; then
#     echo "Usage: $0 <provider>"
#     exit 1
# fi

# PROVIDER="$1"
# CONFIG_FILE="$HOME/.config/shell_gpt/.sgptrc"

# if [[ "$PROVIDER" != "openai" && "$PROVIDER" != "anthropic" && "$PROVIDER" != "openrouter" ]]; then
#     echo "Invalid provider. Use 'openai', 'anthropic', or 'openrouter'."
#     exit 1
# fi

# case "$PROVIDER" in
#     "openai")
#         API_KEY_REF="\$OPENAI_API_KEY"
#         API_BASE_URL="https://api.openai.com/v1"
#         ;;
#     "anthropic")
#         API_KEY_REF="\$ANTHROPIC_API_KEY"
#         API_BASE_URL="https://api.anthropic.com/v1"
#         ;;
#     "openrouter")
#         API_KEY_REF="\$OPENROUTER_API_KEY"
#         API_BASE_URL="https://openrouter.ai/api/v1"
#         ;;
# esac

# USE_LITELLM="true"

# sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=\"$API_KEY_REF\"|" "$CONFIG_FILE"
# sed -i "s|^API_BASE_URL=.*|API_BASE_URL=$API_BASE_URL|" "$CONFIG_FILE"
# sed -i "s|^USE_LITELLM=.*|USE_LITELLM=$USE_LITELLM|" "$CONFIG_FILE"

# echo "OPENAI_API_KEY updated to reference $API_KEY_REF for $PROVIDER."
# echo "API_BASE_URL updated to $API_BASE_URL for $PROVIDER."
# echo "USE_LITELLM updated to $USE_LITELLM for $PROVIDER."
# EOL

# # Create the set_default_model.sh script
# cat > "$INSTALL_DIR/set_default_model.sh" << 'EOL'
# #!/bin/bash
# if [ "$#" -eq 0 ]; then
#     echo "Usage: $0 <model>"
#     exit 1
# fi

# MODEL="$1"
# CONFIG_FILE="$HOME/.config/shell_gpt/.sgptrc"
# API_BASE_URL=$(grep -oP 'API_BASE_URL=\K[^ ]+' "$CONFIG_FILE")

# case "$API_BASE_URL" in
#     "https://api.openai.com/v1")
#         PROVIDER="openai"
#         ;;
#     "https://api.anthropic.com/v1")
#         PROVIDER="anthropic"
#         ;;
#     "https://openrouter.ai/api/v1")
#         PROVIDER="openrouter"
#         ;;
#     *)
#         echo "Unknown API_BASE_URL. Cannot determine provider."
#         exit 1
#         ;;
# esac

# MODEL_PATH="$PROVIDER/$MODEL"
# ESCAPED_MODEL_PATH=$(echo "$MODEL_PATH" | sed 's/[\/&]/\\&/g')
# sed -i "s|^DEFAULT_MODEL=.*|DEFAULT_MODEL=$ESCAPED_MODEL_PATH|" "$CONFIG_FILE"

# echo "DEFAULT_MODEL updated to $MODEL_PATH for $PROVIDER."
# EOL

# Create the startup.sh script
cat > "$INSTALL_DIR/startup.sh" << EOL
#!/bin/bash
# Create config directory if it doesn't exist
mkdir -p $CONFIG_DIR

# If ~/.config has the file, copy FROM ~/.config TO workspace
# if [ -f $CONFIG_DIR/.sgptrc ]; then
#     cp $CONFIG_DIR/.sgptrc $INSTALL_DIR/.sgptrc
# else
#     # No ~/.config file - copy FROM workspace TO ~/.config
#     if [ -f $INSTALL_DIR/.sgptrc ]; then
#         cp $INSTALL_DIR/.sgptrc $CONFIG_DIR/.sgptrc
#         chmod 600 $CONFIG_DIR/.sgptrc
#     fi
# fi

# Create bin directory
mkdir -p "$BIN_DIR"

# Create the aiderDS script
cat > "$BIN_DIR/aiderDS" << 'INNEREOF'
#!/bin/bash
aider --model openrouter/deepseek/deepseek-chat --map-tokens 1024 "\$@"
INNEREOF
chmod +x "$BIN_DIR/aiderDS"
export PATH="$BIN_DIR:\$PATH"

# Source the alias script
source "$INSTALL_DIR/set_alias.sh"
EOL

# Set execute permissions
chmod +x "$INSTALL_DIR/set_alias.sh"
# chmod +x "$INSTALL_DIR/set_api_key.sh"
# chmod +x "$INSTALL_DIR/set_default_model.sh"
chmod +x "$INSTALL_DIR/startup.sh"

# Create the aiderDS script
cat > "$BIN_DIR/aiderDS" << 'EOL'
#!/bin/bash
aider --model openrouter/deepseek/deepseek-chat --map-tokens 1024 "$@"
EOL
chmod +x "$BIN_DIR/aiderDS"

# Set the PATH
export PATH="$BIN_DIR:$PATH"

# Source the alias script
source "$INSTALL_DIR/set_alias.sh"

cat > aitoolsreadme.md << 'EOL'
# AI Development Tools for Replit

This script installs and configures AI-powered development tools to assist with coding and development in any Replit environment.

## Installed Tools
This installation sets up:
- **Aider** ([https://github.com/Aider-AI/aider](https://github.com/Aider-AI/aider)) - AI pair programming in your terminal

## Initial Setup

After installation, first initialize the environment:
```bash
source ~/.ai_tools/startup.sh
```
This ensures all tools and scripts function correctly in Replit's environment.


## Aider

Aider is an AI pair programming tool that helps you edit code directly in your terminal through natural language conversations.

To start an Aider session:
```bash
aider
```
For Replit-optimized settings, run this on first run:
```bash 
aider --config /home/runner/workspace/.aider.conf.yml
```
the interface will now use a colour scheme more suited for replits shell

The installation includes a preconfigured aiderDS command that uses the Deepseek model via OpenRouter with repository mapping enabled:
```bash
aiderDS
```

This is equivalent to:
```bash
aider --model openrouter/deepseek/deepseek-chat --map-tokens 1024
```

For Replit-optimized settings, use:
```bash 
aider --config .aider.conf.yml
```

See the [Aider documentation](https://aider.chat/) for more details on how to have effective coding conversations.

Please note, it is currently not reccomended to use playwright for aiders web scraping features. 

## API Keys

The tools require API keys to function. These should be configured in the Replit Secrets tab with the following names:

- `OPENAI_API_KEY` - For OpenAI API access
- `ANTHROPIC_API_KEY` - For Anthropic/Claude API access
- `OPENROUTER_API_KEY` - For OpenRouter API access

Only configure the API key(s) for the provider(s) you plan to use.

## Addendum

If tools stop working (common after Replit restarts or environment changes):
```bash
source ~/.ai_tools/startup.sh
```

Remember to always use `source` with the configuration scripts to ensure they properly modify your current shell environment.



EOL


echo "Installation complete!"
