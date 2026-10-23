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
#   Strata (:8097) → Qwen3.8-Flash-Next 125B, provider "strata" in OpenCode
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
    pkgs.ocrmypdf        # OCR for scanned PDFs (prebuilt tesseract includes tur + eng)
    claude-local
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "ryzen/${coder}";
    # no fixed small_model: titles + compaction use the session's own model, so they never
    # switch models (Strata and llama.cpp can't both be loaded on the one GPU)
    compaction = { auto = true; prune = true; };   # prune: drop old tool outputs first
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
        "Gemma-4-12B-262k" = {
          name  = "Gemma 4 12B · 262k (studying, long docs, images)";
          limit = { context = 262144; output = 16384; };
        };
        "gpt-oss-20b-128k" = {
          name  = "gpt-oss 20B · 128k (fast research)";
          limit = { context = 131072; output = 16384; };
        };
      };
    };
    # Strata (Qwen3.8-Flash-Next 125B MoE, IQ3_S) — loads on first request (~45 s),
    # unloads after 15 min idle; unloads llama.cpp's model first (one GPU)
    provider.strata = {
      npm  = "@ai-sdk/openai-compatible";
      name = "ryzenserver (Strata)";
      options = {
        baseURL = "http://${server}:8097/v1";
        apiKey  = "{file:~/.config/ryzen-ai/api-key}";
        timeout = 600000;   # first request waits for the model to load
      };
      models."qwen3.8-flash-next-iq3_s" = {
        name  = "Qwen3.8-Flash-Next 125B · 128k (Strata, smartest)";
        limit = { context = 131072; output = 32768; };
      };
    };
    instructions = [
      "${config.xdg.configHome}/opencode/memory-instructions.md"
      "${config.xdg.configHome}/opencode/web-instructions.md"
    ];
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

  xdg.configFile."opencode/web-instructions.md".text = ''
    # Web research

    - Search with the `searxng` tool, then fetch the most relevant pages.
    - Stack Overflow / Stack Exchange pages return 403 to WebFetch (bot protection).
      Do not retry them; use the official Stack Exchange API instead (JSON, no key needed):
      - question: https://api.stackexchange.com/2.3/questions/{id}?site=stackoverflow&filter=withbody
      - answers:  https://api.stackexchange.com/2.3/questions/{id}/answers?site=stackoverflow&filter=withbody&sort=votes
      (for other sites change `site=`, e.g. superuser, askubuntu, unix)
    - Reddit blocks WebFetch (403, also for .json and old.reddit.com) and rate-limits
      thread RSS (429). Do not retry Reddit URLs: use what the search results already
      show (title + snippet), look for the same information on other sites, and give
      the user the Reddit link if a thread looks important so they can read it.
    - GitHub files: prefer raw.githubusercontent.com URLs.

    # PDFs

    - The models here cannot take PDF files directly: do not use the Read tool on a .pdf.
      Convert it with bash instead: `pdftotext -layout file.pdf -` (keeps tables/columns),
      or `pdftotext -layout -f 3 -l 5 file.pdf -` for pages 3-5 of a long PDF.
      `pdfinfo file.pdf` shows the page count first.
    - If pdftotext returns (almost) no text, the PDF is scanned: OCR it first with
      `ocrmypdf -l tur+eng --skip-text file.pdf /tmp/ocr.pdf` (Turkish + English), then run
      pdftotext on /tmp/ocr.pdf.
    - If a page stays blocked, say so and move on to another source; do not try to
      bypass bot protection or CAPTCHAs.
  '';
}
