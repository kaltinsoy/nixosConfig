{ pkgs, lib, config, ... }:

# ── Local AI on ryzenserver (llama.cpp + SearXNG over LAN) ────────────────
# Server: Fedora @ 192.168.0.133, llama.cpp router on :8090 (OpenAI + Anthropic
# API, started on demand), SearXNG on :8888. Reachable from 192.168.0.0/24 only.
#
# The API key is NOT stored in this repo / the Nix store. Put it in:
#   ~/.config/ryzen-ai/api-key   (chmod 600)
# Fetch it with:  ssh koray@192.168.0.133 cat /etc/llama/api-key
#
# Commands:
#   opencode       → OpenCode agent using the server (default: 64k Qwen3.8)
#   claude-local   → Claude Code pointed at the server (normal `claude` unchanged)
#   pdftotext      → convert PDFs to text before feeding them to agents
#
# OpenCode memory: knowledge graph in ~/.local/share/opencode-memory.jsonl
# (MCP server-memory), rules in memory-instructions.md. Delete the file to reset.

let
  server   = "192.168.0.133";
  keyFile  = "$HOME/.config/ryzen-ai/api-key";
  coder    = "Qwen3.8-27B-Heretic-Ara-IQ4_XS-64k";

  # Long-term memory (knowledge graph) shared by all OpenCode sessions
  memoryFile = "${config.xdg.dataHome}/opencode-memory.jsonl";

  searxngMcp = pkgs.writeText "searxng-mcp.json" (builtins.toJSON {
    mcpServers.searxng = {
      command = "${pkgs.nodejs}/bin/npx";
      args    = [ "-y" "mcp-searxng" ];
      env.SEARXNG_URL = "http://${server}:8888";
    };
  });

  claude-local = pkgs.writeShellScriptBin "claude-local" ''
    if [ ! -r "${keyFile}" ]; then
      echo "Missing ${keyFile} — run: ssh koray@${server} cat /etc/llama/api-key > ${keyFile}" >&2
      exit 1
    fi
    export ANTHROPIC_BASE_URL="http://${server}:8090"
    export ANTHROPIC_AUTH_TOKEN="$(cat "${keyFile}")"
    export ANTHROPIC_MODEL="${coder}"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${coder}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${coder}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${coder}"
    export CLAUDE_CODE_SUBAGENT_MODEL="${coder}"
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    exec ${pkgs.claude-code}/bin/claude --mcp-config ${searxngMcp} "$@"
  '';
in
{
  home.packages = [
    pkgs.opencode
    pkgs.nodejs          # npx for MCP servers (mcp-searxng)
    pkgs.poppler-utils   # pdftotext / pdfinfo
    claude-local
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "ryzen/${coder}";
    small_model = "ryzen/${coder}";
    share = "disabled";   # /share would upload chats to opencode.ai — keep history local
    provider.ryzen = {
      npm  = "@ai-sdk/openai-compatible";
      name = "ryzenserver (llama.cpp)";
      options = {
        baseURL = "http://${server}:8090/v1";
        apiKey  = "{file:~/.config/ryzen-ai/api-key}";
      };
      models = {
        "${coder}" = {
          name  = "Qwen3.8 27B Heretic-Ara · 64k (coding)";
          limit = { context = 65536; output = 16384; };
        };
        "Qwen3.8-27B-Heretic-Ara-IQ4_XS" = {
          name  = "Qwen3.8 27B Heretic-Ara · 32k";
          limit = { context = 32768; output = 16384; };
        };
        "Qwen3.8-27B-HauhauCS-Aggressive-IQ4_XS" = {
          name  = "Qwen3.8 27B HauhauCS Aggressive · 16k";
          limit = { context = 16384; output = 8192; };
        };
      };
    };
    instructions = [ "${config.xdg.configHome}/opencode/memory-instructions.md" ];
    mcp.searxng = {
      type        = "local";
      command     = [ "${pkgs.nodejs}/bin/npx" "-y" "mcp-searxng" ];
      environment = { SEARXNG_URL = "http://${server}:8888"; };
    };
    mcp.memory = {
      type        = "local";
      command     = [ "${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-memory" ];
      environment = { MEMORY_FILE_PATH = memoryFile; };
    };
  };

  # Kept separate from AGENTS.md so ~/.config/opencode/AGENTS.md stays user-editable
  xdg.configFile."opencode/memory-instructions.md".text = ''
    # Long-term memory

    You have a persistent memory (the `memory` MCP tools: a knowledge graph of
    entities, relations and observations) shared across all sessions.

    - At the start of a task, use `search_nodes` with a few keywords from the
      request (person, project, topic) and use what you find.
    - Save only durable, useful facts: the user's preferences, their projects and
      what they are about, decisions made, conventions, recurring problems and fixes.
      Use `create_entities` for new things and `add_observations` for new facts.
    - Do not save secrets (passwords, keys, tokens), temporary state, or large text.
      Keep each observation to one short sentence.
    - When the user says "remember ..." save it; when they say "forget ..." delete it.
    - If a stored fact turns out to be wrong, delete or correct it.
  '';
}
