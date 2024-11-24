#!/bin/bash

# Define the directory structure with better name
INSTALL_DIR="$HOME/.ai_tools"
BIN_DIR="$INSTALL_DIR/bin"
CONFIG_DIR="$HOME/.config/shell_gpt"  # Keep this path for compatibility

# Create the directory structure
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# Install directly without --user flag or pipx
echo "Installing requirements..."
python3 -m pip install shell-gpt[litellm] aider-chat

# Ensure we can use pipx right away
export PATH="$HOME/.local/bin:$PATH"

# Create the aiderDS script
cat > "$BIN_DIR/aiderDS" << 'EOL'
#!/bin/bash
aider --model openrouter/deepseek/deepseek-chat --map-tokens 1024 "$@"
EOL
chmod +x "$BIN_DIR/aiderDS"

# Create the .sgptrc configuration file
cat > "$CONFIG_DIR/.sgptrc" << 'EOL'
OPENAI_API_KEY="$OPENROUTER_API_KEY"
API_BASE_URL=https://openrouter.ai/api/v1
CHAT_CACHE_LENGTH=100
CHAT_CACHE_PATH=/tmp/shell_gpt/chat_cache
CACHE_LENGTH=100
CACHE_PATH=/tmp/shell_gpt/cache
REQUEST_TIMEOUT=60
DEFAULT_MODEL=openrouter/deepseek/deepseek-chat
DEFAULT_COLOR=magenta
DEFAULT_EXECUTE_SHELL_CMD=false
DISABLE_STREAMING=false
CODE_THEME=default
OPENAI_FUNCTIONS_PATH=/home/runner/.config/shell_gpt/functions
SHOW_FUNCTIONS_OUTPUT=false
OPENAI_USE_FUNCTIONS=true
USE_LITELLM=true
ROLE_STORAGE_PATH=/home/runner/.config/shell_gpt/roles
PRETTIFY_MARKDOWN=true
SHELL_INTERACTION=true
OS_NAME=auto
SHELL_NAME=auto
EOL

# Create the set_alias.sh script
cat > "$INSTALL_DIR/set_alias.sh" << 'EOL'
#!/bin/bash

# Set the aiderDS alias
alias aiderDS="$HOME/.shell_gpt/bin/aiderDS"

# Print the PATH environment variable to verify it is updated correctly
echo "Updated PATH: $PATH"

# Check if the alias is set correctly
if alias aiderDS >/dev/null 2>&1; then
    echo "aiderDS alias is set correctly."
else
    echo "aiderDS alias is not set correctly."
fi
EOL

# Create the set_api_key.sh script
cat > "$INSTALL_DIR/set_api_key.sh" << 'EOL'
#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <provider>"
    exit 1
fi

PROVIDER="$1"

# Define the path to the configuration file
CONFIG_FILE="$HOME/.config/shell_gpt/.sgptrc"

# Check if the provider is valid
if [[ "$PROVIDER" != "openai" && "$PROVIDER" != "anthropic" && "$PROVIDER" != "openrouter" ]]; then
    echo "Invalid provider. Use 'openai', 'anthropic', or 'openrouter'."
    exit 1
fi

# Set the API key reference, API base URL, and use_litellm based on the provider
case "$PROVIDER" in
    "openai")
        API_KEY_REF="\$OPENAI_API_KEY"
        API_BASE_URL="https://api.openai.com/v1"
        ;;
    "anthropic")
        API_KEY_REF="\$ANTHROPIC_API_KEY"
        API_BASE_URL="https://api.anthropic.com/v1"
        ;;
    "openrouter")
        API_KEY_REF="\$OPENROUTER_API_KEY"
        API_BASE_URL="https://openrouter.ai/api/v1"
        ;;
esac

# Always set USE_LITELLM to true
USE_LITELLM="true"

# Update the configuration file
sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=\"$API_KEY_REF\"|" "$CONFIG_FILE"
sed -i "s|^API_BASE_URL=.*|API_BASE_URL=$API_BASE_URL|" "$CONFIG_FILE"
sed -i "s|^USE_LITELLM=.*|USE_LITELLM=$USE_LITELLM|" "$CONFIG_FILE"

echo "OPENAI_API_KEY updated to reference $API_KEY_REF for $PROVIDER."
echo "API_BASE_URL updated to $API_BASE_URL for $PROVIDER."
echo "USE_LITELLM updated to $USE_LITELLM for $PROVIDER."
EOL

# Create the set_default_model.sh script
cat > "$INSTALL_DIR/set_default_model.sh" << 'EOL'
#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <model>"
    exit 1
fi

MODEL="$1"

# Define the path to the configuration file
CONFIG_FILE="$HOME/.config/shell_gpt/.sgptrc"

# Read the API_BASE_URL from the configuration file
API_BASE_URL=$(grep -oP 'API_BASE_URL=\K[^ ]+' "$CONFIG_FILE")

# Determine the provider based on the API_BASE_URL
case "$API_BASE_URL" in
    "https://api.openai.com/v1")
        PROVIDER="openai"
        ;;
    "https://api.anthropic.com/v1")
        PROVIDER="anthropic"
        ;;
    "https://openrouter.ai/api/v1")
        PROVIDER="openrouter"
        ;;
    *)
        echo "Unknown API_BASE_URL. Cannot determine provider."
        exit 1
        ;;
esac

# Prefix the model path with the provider
MODEL_PATH="$PROVIDER/$MODEL"

# Escape special characters in the model path
ESCAPED_MODEL_PATH=$(echo "$MODEL_PATH" | sed 's/[\/&]/\\&/g')

# Update the configuration file using a different delimiter
sed -i "s|^DEFAULT_MODEL=.*|DEFAULT_MODEL=$ESCAPED_MODEL_PATH|" "$CONFIG_FILE"

echo "DEFAULT_MODEL updated to $MODEL_PATH for $PROVIDER."
EOL

# Create the startup.sh script
cat > "$INSTALL_DIR/startup.sh" << 'EOL'
#!/bin/bash
# Create config directory if it doesn't exist
mkdir -p ~/.config/shell_gpt

# If ~/.config has the file, copy FROM ~/.config TO workspace
if [ -f ~/.config/shell_gpt/.sgptrc ]; then
    cp ~/.config/shell_gpt/.sgptrc .sgptrc
else
    # No ~/.config file - copy FROM workspace TO ~/.config
    if [ -f .sgptrc ]; then
        cp .sgptrc ~/.config/shell_gpt/.sgptrc
        chmod 600 ~/.config/shell_gpt/.sgptrc
    fi
fi

# Create bin directory in workspace
mkdir -p bin

# Create the aiderDS script
cat > bin/aiderDS << 'INNEREOF'
#!/bin/bash
aider --model openrouter/deepseek/deepseek-chat --map-tokens 1024 "$@"
INNEREOF
chmod +x bin/aiderDS
export PATH="$PWD/bin:$PATH"

# Source the alias script
source $PWD/set_alias.sh

# Ensure the script is sourced in the current shell session
if [ -z "$STARTUP_SOURCED" ]; then
    export STARTUP_SOURCED=1
    source $PWD/startup.sh
else
    echo "Startup configuration complete!"
fi
EOL

# Set execute permissions
chmod +x "$INSTALL_DIR/set_alias.sh"
chmod +x "$INSTALL_DIR/set_api_key.sh"
chmod +x "$INSTALL_DIR/set_default_model.sh"
chmod +x "$INSTALL_DIR/startup.sh"

# Set the PATH environment variable
export PATH="$BIN_DIR:$PATH"

# Source the alias script
source "$INSTALL_DIR/set_alias.sh"

echo "Installation complete!"
