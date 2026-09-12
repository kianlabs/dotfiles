# discord-admin-plus

Profile-local MCP server (stdio) for the `agent-admin` Hermes profile.
Gives Admin Sol the Discord guild-management operations missing from
Hermes' built-in `discord_admin` toolset.

- Live path: `~/.hermes/profiles/agent-admin/tools/discord-admin-plus/server.py`
- Backup path (this file's sibling): `hermes/mcp/discord-admin-plus/server.py`
- Runtime: Hermes venv python, stdlib only (no third-party deps).
- Auth: `DISCORD_BOT_TOKEN` from the active profile's secret scope
  (`env: {DISCORD_BOT_TOKEN: ${DISCORD_BOT_TOKEN}}`). Never hardcoded,
  never logged (errors are redacted).
- API: `https://discord.com/api/v10` with `Authorization: Bot <token>`.
  Handles 400/401/403/404/429 (rate-limit retry) with human-readable errors.

Discovery: **14/14 tools**.

## Tools

| Tool | Notes |
|---|---|
| `create_category` | guild_id, name, optional position |
| `create_text_channel` | guild_id, name, optional category_id/topic/position |
| `edit_channel` | rename/topic/position; only changed fields required |
| `move_channel` | channel_id + category_id, optional position |
| `delete_channel` | DESTRUCTIVE — explicit confirmation only |
| `create_role` | never defaults to Administrator |
| `edit_role` | honors role hierarchy |
| `delete_role` | DESTRUCTIVE — explicit confirmation only |
| `set_channel_permission` | role/member overwrite: allow/deny bitfields |
| `delete_channel_permission` | DESTRUCTIVE/security-sensitive |
| `reorder_channels` | bulk positions via official endpoint |
| `reorder_roles` | bulk positions; honors hierarchy |
| `send_message` | bot message; mentions always suppressed (`allowed_mentions: {parse: []}`) |
| `edit_member_nickname` | see below |

## edit_member_nickname

```text
edit_member_nickname(
  guild_id,
  user_id,
  nickname
)
```

Behavior:

- `PATCH /guilds/{guild_id}/members/{user_id}` with `{ "nick": ... }`
- `user_id="@me"` for Admin Sol's own nickname (Discord rejects the
  plain member endpoint for self-nicks with Missing Permissions)
- empty string or null nickname = reset
- max 32 chars (Discord limit, validated)
- honors Discord permissions + role hierarchy (403 surfaces a clear error)

## Hermes MCP loader patch (local)

File: `tools/mcp_tool.py` in the Hermes checkout (NOT backed up here —
docs/diff only, re-apply after fresh install/update if upstream unfixed).

`_ensure_mcp_sdk()`, both early-return guards, changed from:

```python
if _MCP_SDK_IMPORT_ATTEMPTED or ClientSession is not None:
    return _MCP_AVAILABLE
```

to:

```python
if _MCP_SDK_IMPORT_ATTEMPTED:
    return _MCP_AVAILABLE
```

Why: the old guard could return before `StdioServerParameters` /
`stdio_client` were bound, causing
`NameError: StdioServerParameters is not defined` and parking
`discord-admin-plus` after 3 retries.

Dependency: `pydantic==2.13.4` (repo-pinned). MCP SDK 2.0.0 needs
Pydantic v2; a downgraded pydantic 1.x breaks the SDK import entirely.

Reference backup of the patched file (pre-patch state) lives next to the
live source as `tools/mcp_tool.py.bak.guardfix` (not committed).

## Restore after fresh install / Hermes update

1. Copy this directory's `server.py` to
   `~/.hermes/profiles/agent-admin/tools/discord-admin-plus/server.py`
   (`chmod 700`).
2. Create the bot token manually — never commit it. Wire it as
   `DISCORD_BOT_TOKEN` in the profile `.env` and reference it from
   `mcp_servers.discord-admin-plus.env` (see `hermes/profiles/agent-admin/config.yaml`).
3. Ensure `pydantic==2.13.4` in the Hermes venv.
4. Re-apply the `_ensure_mcp_sdk()` guard patch above if upstream
   hasn't fixed it.
5. `hermes -p agent-admin mcp test discord-admin-plus` → expect **14/14 tools**.
6. Restart only `hermes-gateway-agent-admin.service` and confirm
   `Connected as Admin Sol` with no parked/error lines.
