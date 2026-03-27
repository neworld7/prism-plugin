---
name: account
description: "Stitch 계정 전환 — /prism account로 목록, /prism account <name>으로 전환"
---

# /prism account

Stitch 계정을 전환합니다.

## Usage

| Usage | Action |
|-------|--------|
| `/prism account` | 등록된 계정 목록 + 현재 활성 계정 표시 |
| `/prism account <name>` | 해당 계정으로 전환 |

## Execution

### 초기 설정 (최초 1회)

`~/.claude/prism-accounts.json`이 없으면 아래 형식으로 생성:

```json
{
  "active": "myaccount",
  "accounts": [
    {
      "name": "myaccount",
      "email": "user@gmail.com",
      "apiKey": "AIza..."
    }
  ]
}
```

API 키: [Google AI Studio](https://aistudio.google.com/apikey)에서 발급.
계정 추가: `accounts` 배열에 객체 추가 후 `/prism account <name>`으로 전환.

### 인자 없음 — 계정 목록

```bash
python3 -c "
import json
with open('$HOME/.claude/prism-accounts.json') as f:
    d = json.load(f)
active = d['active']
for a in d['accounts']:
    marker = '→' if a['name'] == active else ' '
    print(f'{marker} {a[\"name\"]} ({a[\"email\"]})')
"
```

### 인자 있음 — 계정 전환

```bash
ACCOUNT_NAME=$1

python3 -c "
import json, sys

name = '$ACCOUNT_NAME'

with open('$HOME/.claude/prism-accounts.json') as f:
    accounts = json.load(f)

match = next((a for a in accounts['accounts'] if a['name'] == name), None)
if not match:
    print(f'계정 \"{name}\"을 찾을 수 없습니다.')
    sys.exit(1)

# ~/.claude.json 업데이트
with open('$HOME/.claude.json') as f:
    claude = json.load(f)
claude.setdefault('mcpServers', {}).setdefault('stitch', {})['headers'] = {'x-goog-api-key': match['apiKey']}
claude['mcpServers']['stitch']['type'] = 'http'
claude['mcpServers']['stitch']['url'] = 'https://stitch.googleapis.com/mcp'
with open('$HOME/.claude.json', 'w') as f:
    json.dump(claude, f, indent=2)

# active 업데이트
accounts['active'] = name
with open('$HOME/.claude/prism-accounts.json', 'w') as f:
    json.dump(accounts, f, indent=2)

print(f'→ {match[\"name\"]} ({match[\"email\"]}) 로 전환 완료')
print('세션을 재시작해주세요 (/clear 또는 새 세션)')
"
```
