#!/usr/bin/env python3
"""discord-admin-plus — profile-local MCP server for agent-admin.

Exposes structured Discord guild administration (categories, channels,
roles, permission overwrites) over MCP stdio. Stdlib only — no third-party
dependencies, no shell, no filesystem access, no generic HTTP.

Auth: reads DISCORD_BOT_TOKEN from the process environment (injected by
Hermes from the active profile's secret scope). The token is never printed,
never logged, and never echoed back in tool results or errors.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

API_BASE = "https://discord.com/api/v10"
SNOWFLAKE_RE = re.compile(r"^[1-9][0-9]{5,25}$")
TOKEN = os.environ.get("DISCORD_BOT_TOKEN", "")

if not TOKEN:
    sys.stderr.write("discord-admin-plus: DISCORD_BOT_TOKEN is not set\n")
    sys.stderr.flush()
    sys.exit(1)


def _redact(text):
    """Scrub anything that looks like a credential from outward text."""
    if not isinstance(text, str):
        return text
    out = re.sub(r"[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{5,}\.[A-Za-z0-9_\-]{20,}",
                 "[REDACTED]", text)
    return out


class DiscordError(Exception):
    pass


def _api(method, path, payload=None, _retries=3):
    body = json.dumps(payload).encode() if payload is not None else None
    for attempt in range(_retries + 1):
        req = urllib.request.Request(
            API_BASE + path, method=method,
            headers={"Authorization": "Bot " + TOKEN,
                     "Content-Type": "application/json",
                     "User-Agent": "discord-admin-plus-mcp/1.0"},
            data=body)
        try:
            with urllib.request.urlopen(req, timeout=25) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as exc:
            try:
                detail = json.loads(exc.read() or b"{}")
            except Exception:
                detail = {}
            msg = str(detail.get("message", "")) or f"HTTP {exc.code}"
            if exc.code == 429 and attempt < _retries:
                wait = min(float(detail.get("retry_after", 1.0)), 10.0)
                time.sleep(wait)
                continue
            raise DiscordError(_friendly(exc.code, msg, detail))
        except (urllib.error.URLError, TimeoutError) as exc:
            if attempt < _retries:
                time.sleep(1.0)
                continue
            raise DiscordError(f"Network error reaching Discord API: {exc.__class__.__name__}")
    raise DiscordError("Rate limited by Discord; please retry shortly.")


def _friendly(code, msg, detail):
    code = int(code)
    if code == 400:
        return f"Bad request: {_redact(msg)} { _redact(json.dumps(detail.get('errors', {}))) }".strip()
    if code == 401:
        return "Unauthorized: bot token invalid or revoked. Regenerate it in the Developer Portal."
    if code == 403:
        return ("Forbidden: bot lacks permission or role hierarchy blocks this "
                f"action. ({_redact(msg)})")
    if code == 404:
        return f"Not found: unknown guild/channel/role. ({_redact(msg)})"
    if code == 429:
        return "Rate limited by Discord; please retry shortly."
    if 500 <= code < 600:
        return f"Discord server error (HTTP {code}); retry later."
    return f"Discord API error HTTP {code}: {_redact(msg)}"


def _snowflake(name, value):
    if not isinstance(value, str) or not SNOWFLAKE_RE.match(value):
        raise DiscordError(f"Invalid {name}: must be a Discord snowflake id string.")
    return value


def _opt(payload, args, key, validator=None):
    if key in args and args[key] is not None:
        v = args[key]
        payload[key] = validator(v) if validator else v


def _nonempty_str(v):
    if not isinstance(v, str) or not v.strip():
        raise DiscordError("Name must be a non-empty string.")
    return v.strip()[:100]


def _perms(v):
    if isinstance(v, bool):
        return "0" if not v else v
    if isinstance(v, int):
        if v < 0:
            raise DiscordError("permissions must be >= 0.")
        return str(v)
    if isinstance(v, str) and re.fullmatch(r"[0-9]{1,20}", v):
        return v
    raise DiscordError("permissions must be an integer bitfield or digit string.")


def t_create_category(a):
    payload = {"name": _nonempty_str(a["name"]), "type": 4}
    _opt(payload, a, "position", int)
    return _api("POST", f"/guilds/{_snowflake('guild_id', a['guild_id'])}/channels", payload)


def t_create_text_channel(a):
    payload = {"name": _nonempty_str(a["name"]), "type": 0}
    _opt(payload, a, "category_id", lambda v: _snowflake("category_id", v))
    if "category_id" in payload:
        payload["parent_id"] = payload.pop("category_id")
    _opt(payload, a, "topic", lambda v: v if isinstance(v, str) else (_ for _ in ()).throw(
        DiscordError("topic must be a string.")))
    if "topic" in payload:
        payload["topic"] = payload["topic"][:1024]
    _opt(payload, a, "position", int)
    return _api("POST", f"/guilds/{_snowflake('guild_id', a['guild_id'])}/channels", payload)


def t_edit_channel(a):
    payload = {}
    _opt(payload, a, "name", _nonempty_str)
    _opt(payload, a, "topic", lambda v: v[:1024] if isinstance(v, str) else (_ for _ in ()).throw(
        DiscordError("topic must be a string.")))
    _opt(payload, a, "position", int)
    if not payload:
        raise DiscordError("Nothing to change: provide at least one of name/topic/position.")
    return _api("PATCH", f"/channels/{_snowflake('channel_id', a['channel_id'])}", payload)


def t_move_channel(a):
    cid = _snowflake("channel_id", a["channel_id"])
    payload = {"parent_id": _snowflake("category_id", a["category_id"])}
    _opt(payload, a, "position", int)
    return _api("PATCH", f"/channels/{cid}", payload)


def t_delete_channel(a):
    _api("DELETE", f"/channels/{_snowflake('channel_id', a['channel_id'])}")
    return {"ok": True, "deleted_channel_id": a["channel_id"]}


def t_create_role(a):
    payload = {"name": _nonempty_str(a["name"])}
    _opt(payload, a, "permissions", _perms)
    _opt(payload, a, "color", int)
    _opt(payload, a, "hoist", bool)
    _opt(payload, a, "mentionable", bool)
    return _api("POST", f"/guilds/{_snowflake('guild_id', a['guild_id'])}/roles", payload)


def t_edit_role(a):
    payload = {}
    _opt(payload, a, "name", _nonempty_str)
    _opt(payload, a, "permissions", _perms)
    _opt(payload, a, "color", int)
    _opt(payload, a, "hoist", bool)
    _opt(payload, a, "mentionable", bool)
    if not payload:
        raise DiscordError("Nothing to change: provide at least one editable field.")
    return _api("PATCH",
                f"/guilds/{_snowflake('guild_id', a['guild_id'])}/roles/{_snowflake('role_id', a['role_id'])}",
                payload)


def t_delete_role(a):
    _api("DELETE",
         f"/guilds/{_snowflake('guild_id', a['guild_id'])}/roles/{_snowflake('role_id', a['role_id'])}")
    return {"ok": True, "deleted_role_id": a["role_id"]}


def t_set_channel_permission(a):
    cid = _snowflake("channel_id", a["channel_id"])
    target = _snowflake("target_id", a["target_id"])
    ttype = a.get("target_type", "role")
    if ttype == "role":
        kind = 0
    elif ttype == "member":
        kind = 1
    else:
        raise DiscordError("target_type must be 'role' or 'member'.")
    payload = {"id": target, "type": kind,
               "allow": _perms(a.get("allow", 0)), "deny": _perms(a.get("deny", 0))}
    _api("PUT", f"/channels/{cid}/permissions/{target}", payload)
    return {"ok": True, "channel_id": cid, "target_id": target}


def t_delete_channel_permission(a):
    cid = _snowflake("channel_id", a["channel_id"])
    target = _snowflake("target_id", a["target_id"])
    _api("DELETE", f"/channels/{cid}/permissions/{target}")
    return {"ok": True, "channel_id": cid, "target_id": target}


def t_reorder_channels(a):
    gid = _snowflake("guild_id", a["guild_id"])
    items = a.get("items")
    if not isinstance(items, list) or not items:
        raise DiscordError("items must be a non-empty list of {id, position}.")
    payload = []
    for it in items:
        if not isinstance(it, dict):
            raise DiscordError("Each item must be {id, position}.")
        entry = {"id": _snowflake("item id", it["id"]), "position": int(it["position"])}
        if it.get("parent_id") is not None:
            entry["parent_id"] = _snowflake("parent_id", it["parent_id"])
        payload.append(entry)
    _api("PATCH", f"/guilds/{gid}/channels", payload)
    return {"ok": True, "reordered": len(payload)}


def t_reorder_roles(a):
    gid = _snowflake("guild_id", a["guild_id"])
    items = a.get("items")
    if not isinstance(items, list) or not items:
        raise DiscordError("items must be a non-empty list of {id, position}.")
    payload = [{"id": _snowflake("item id", it["id"]), "position": int(it["position"])}
               for it in items if isinstance(it, dict) and "id" in it and "position" in it]
    if not payload:
        raise DiscordError("items must be a non-empty list of {id, position}.")
    return _api("PATCH", f"/guilds/{gid}/roles", payload)


def t_send_message(a):
    cid = _snowflake("channel_id", a["channel_id"])
    content = a.get("content")
    if not isinstance(content, str) or not content.strip():
        raise DiscordError("content must be a non-empty string.")
    if len(content) > 2000:
        raise DiscordError("content exceeds Discord's 2000-character limit.")
    payload = {"content": content,
               "allowed_mentions": {"parse": []},
               "suppress_embeds": bool(a.get("suppress_embeds", False))}
    msg = _api("POST", f"/channels/{cid}/messages", payload)
    return {"ok": True, "message_id": msg.get("id"), "channel_id": cid}


def t_edit_member_nickname(a):
    gid = _snowflake("guild_id", a["guild_id"])
    uid = a.get("user_id")
    # Bots must change their own nickname via the @me endpoint.
    me = (uid == "@me")
    if not me:
        uid = _snowflake("user_id", uid)
    nick = a.get("nickname")
    if nick is None:
        payload = {"nick": None}
    elif isinstance(nick, str) and not nick.strip():
        payload = {"nick": None}
    elif isinstance(nick, str) and len(nick) <= 32:
        payload = {"nick": nick}
    else:
        raise DiscordError("nickname must be a string up to 32 characters (empty/null resets it).")
    m = _api("PATCH", f"/guilds/{gid}/members/{uid}", payload)
    return {"ok": True, "user_id": uid, "nick": m.get("nick")}


DESTRUCTIVE = " DESTRUCTIVE — only call after explicit user confirmation."

TOOLS = [
    ("create_category", "Create a new channel category in a guild.",
     {"type": "object", "required": ["guild_id", "name"],
      "properties": {"guild_id": {"type": "string"}, "name": {"type": "string"},
                     "position": {"type": "integer"}}}, t_create_category),
    ("create_text_channel", "Create a new text channel, optionally inside a category.",
     {"type": "object", "required": ["guild_id", "name"],
      "properties": {"guild_id": {"type": "string"}, "name": {"type": "string"},
                     "category_id": {"type": "string"}, "topic": {"type": "string"},
                     "position": {"type": "integer"}}}, t_create_text_channel),
    ("edit_channel", "Rename a channel and/or change its topic/position. Only provide fields that should change.",
     {"type": "object", "required": ["channel_id"],
      "properties": {"channel_id": {"type": "string"}, "name": {"type": "string"},
                     "topic": {"type": "string"}, "position": {"type": "integer"}}}, t_edit_channel),
    ("move_channel", "Move a channel into a different category, optionally at a position.",
     {"type": "object", "required": ["channel_id", "category_id"],
      "properties": {"channel_id": {"type": "string"}, "category_id": {"type": "string"},
                     "position": {"type": "integer"}}}, t_move_channel),
    ("delete_channel", "Permanently delete a channel." + DESTRUCTIVE,
     {"type": "object", "required": ["channel_id"],
      "properties": {"channel_id": {"type": "string"}}}, t_delete_channel),
    ("create_role", "Create a guild role. Never defaults to Administrator; pass permissions explicitly if needed.",
     {"type": "object", "required": ["guild_id", "name"],
      "properties": {"guild_id": {"type": "string"}, "name": {"type": "string"},
                     "permissions": {"type": ["integer", "string"]},
                     "color": {"type": "integer"}, "hoist": {"type": "boolean"},
                     "mentionable": {"type": "boolean"}}}, t_create_role),
    ("edit_role", "Edit a role. Only provide fields that should change. Honors role hierarchy.",
     {"type": "object", "required": ["guild_id", "role_id"],
      "properties": {"guild_id": {"type": "string"}, "role_id": {"type": "string"},
                     "name": {"type": "string"},
                     "permissions": {"type": ["integer", "string"]},
                     "color": {"type": "integer"}, "hoist": {"type": "boolean"},
                     "mentionable": {"type": "boolean"}}}, t_edit_role),
    ("delete_role", "Permanently delete a role." + DESTRUCTIVE,
     {"type": "object", "required": ["guild_id", "role_id"],
      "properties": {"guild_id": {"type": "string"},
                     "role_id": {"type": "string"}}}, t_delete_role),
    ("set_channel_permission", "Create/edit a permission overwrite for a role or member on a channel. allow/deny are permission bitfields.",
     {"type": "object", "required": ["channel_id", "target_id"],
      "properties": {"channel_id": {"type": "string"}, "target_id": {"type": "string"},
                     "target_type": {"type": "string", "enum": ["role", "member"]},
                     "allow": {"type": ["integer", "string"]},
                     "deny": {"type": ["integer", "string"]}}}, t_set_channel_permission),
    ("delete_channel_permission", "Remove a permission overwrite from a channel. Security-sensitive." + DESTRUCTIVE,
     {"type": "object", "required": ["channel_id", "target_id"],
      "properties": {"channel_id": {"type": "string"},
                     "target_id": {"type": "string"}}}, t_delete_channel_permission),
    ("reorder_channels", "Bulk-set channel/category positions via the official endpoint.",
     {"type": "object", "required": ["guild_id", "items"],
      "properties": {"guild_id": {"type": "string"},
                     "items": {"type": "array", "items": {"type": "object"}}}},
     t_reorder_channels),
    ("reorder_roles", "Bulk-set role positions via the official endpoint. Honors role hierarchy.",
     {"type": "object", "required": ["guild_id", "items"],
      "properties": {"guild_id": {"type": "string"},
                     "items": {"type": "array", "items": {"type": "object"}}}},
     t_reorder_roles),
    ("send_message", "Send a plain-text message to a text channel as the bot (default use: admin activity log). Mentions are always suppressed.",
     {"type": "object", "required": ["channel_id", "content"],
      "properties": {"channel_id": {"type": "string"}, "content": {"type": "string"},
                     "suppress_embeds": {"type": "boolean"}}},
     t_send_message),
    ("edit_member_nickname", "Change a member/bot server nickname (PATCH guild member nick). Use user_id @me for the bot itself. Empty or null nickname resets it. Honors role hierarchy and permissions.",
     {"type": "object", "required": ["guild_id", "user_id"],
      "properties": {"guild_id": {"type": "string"}, "user_id": {"type": "string"},
                     "nickname": {"type": "string"}}},
     t_edit_member_nickname),
]
HANDLERS = {name: fn for name, _, _, fn in TOOLS}


def _send(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def _ok(uid, result):
    _send({"jsonrpc": "2.0", "id": uid,
           "result": {"content": [{"type": "text",
                                   "text": _redact(json.dumps(result, ensure_ascii=False)[:4000])}]}})


def _err(uid, code, message):
    _send({"jsonrpc": "2.0", "id": uid,
           "error": {"code": code, "message": _redact(str(message))[:1000]}})


def main():
    proto = "2024-11-05"
    inp = sys.stdin
    for line in inp:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except Exception:
            continue
        if not isinstance(msg, dict) or msg.get("jsonrpc") != "2.0":
            continue
        method = msg.get("method")
        uid = msg.get("id")
        params = msg.get("params", {}) or {}
        if method == "initialize":
            proto = params.get("protocolVersion", proto)
            _send({"jsonrpc": "2.0", "id": uid,
                   "result": {"protocolVersion": proto,
                              "capabilities": {"tools": {}},
                              "serverInfo": {"name": "discord-admin-plus",
                                             "version": "1.0.0"}}})
        elif method in ("notifications/initialized", "notifications/cancelled"):
            continue
        elif method == "ping":
            _send({"jsonrpc": "2.0", "id": uid, "result": {}})
        elif method == "tools/list":
            _send({"jsonrpc": "2.0", "id": uid,
                   "result": {"tools": [{"name": n, "description": d,
                                         "inputSchema": s} for n, d, s, _ in TOOLS]}})
        elif method == "tools/call":
            name = params.get("name")
            args = params.get("arguments", {}) or {}
            fn = HANDLERS.get(name)
            if fn is None:
                _err(uid, -32602, f"Unknown tool: {name}")
                continue
            try:
                _ok(uid, fn(args))
            except DiscordError as exc:
                _send({"jsonrpc": "2.0", "id": uid,
                       "result": {"content": [{"type": "text",
                                               "text": "Error: " + _redact(str(exc))[:1000]}],
                                  "isError": True}})
            except Exception as exc:
                _send({"jsonrpc": "2.0", "id": uid,
                       "result": {"content": [{"type": "text",
                                               "text": "Error: internal error ("
                                               + exc.__class__.__name__ + ")"}],
                                  "isError": True}})
        else:
            if uid is not None:
                _err(uid, -32601, f"Method not found: {method}")


if __name__ == "__main__":
    main()
