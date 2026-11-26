# Lunula AI Agent Hooks (Claude Code & Codex)

Drive the Lunula notch island directly from **Claude Code**, **OpenAI Codex**, or any shell script using the built-in `lunula://` URL scheme — zero background servers, zero private APIs, zero focus stealing (`open -g`).

Make the hook scripts executable once:

```bash
chmod +x examples/hooks/claude-code-lunula.sh examples/hooks/codex-lunula.sh
```

## Claude Code (`~/.claude/settings.json`)

Replace `/PATH/TO/Lunula` with your local clone path (or copy the snippet directly from **Lunula Settings → Activities → Custom Activities**):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "/PATH/TO/Lunula/examples/hooks/claude-code-lunula.sh" }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "/PATH/TO/Lunula/examples/hooks/claude-code-lunula.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "/PATH/TO/Lunula/examples/hooks/claude-code-lunula.sh" }
        ]
      }
    ]
  }
}
```

## OpenAI Codex (`~/.codex/config.toml`)

```toml
notify = ["/PATH/TO/Lunula/examples/hooks/codex-lunula.sh"]
```

## Raw `lunula://` Examples

```bash
# Show a live activity for 60 seconds
open -g "lunula://activity/show?id=build&title=Xcode%20Build&subtitle=Compiling%20Lunula&symbol=hammer.fill&accent=32D74B&duration=60"

# End a live activity
open -g "lunula://activity/end?id=build"

# Report AI token/window usage to the System & AI popover
open -g "lunula://ai/usage?provider=Claude&tokens=48200&cost=0.42&limit=35"

# Raise a critical approval alert with Allow / Deny buttons
open -g "lunula://agent/approval?id=req-1&agent=Claude%20Code&command=git%20push%20origin%20main"
```
