---
name: account
description: "Stitch 계정 전환 — 여러 Google 계정의 API 키를 관리하고 전환"
---

# /prism account

Stitch 계정을 전환합니다. 여러 Google 계정의 API 키를 관리하여 크레딧 한도를 우회합니다.

## Usage

| Subcommand | Usage | Action |
|------------|-------|--------|
| (없음) | `/prism account` | 현재 연결된 계정 표시 |
| `list` | `/prism account list` | 등록된 모든 계정 목록 |
| `switch` | `/prism account switch <name>` | 다른 계정으로 전환 |
| `add` | `/prism account add <name> <email> <api-key>` | 새 계정 등록 |
| `remove` | `/prism account remove <name>` | 계정 삭제 |

## Execution

1. 계정 파일: `~/.claude/prism-accounts.json`
2. 전환 시: `~/.claude.json`의 `mcpServers.stitch.headers.x-goog-api-key` 값을 선택된 계정의 API 키로 교체
3. `prism-accounts.json`의 `active` 필드 업데이트
4. **전환 후 세션 재시작 필요** — 사용자에게 `/clear` 또는 새 세션 안내

## 전환 스크립트

```bash
# switch 실행 시:
ACCOUNT_NAME=$1
API_KEY=$(python3 -c "
import json
with open('$HOME/.claude/prism-accounts.json') as f:
    d = json.load(f)
account = next(a for a in d['accounts'] if a['name'] == '$ACCOUNT_NAME')
print(account['apiKey'])
")

# ~/.claude.json 업데이트
python3 -c "
import json
with open('$HOME/.claude.json') as f:
    d = json.load(f)
d['mcpServers']['stitch']['headers'] = {'x-goog-api-key': '$API_KEY'}
with open('$HOME/.claude.json', 'w') as f:
    json.dump(d, f, indent=2)
"

# active 업데이트
python3 -c "
import json
with open('$HOME/.claude/prism-accounts.json') as f:
    d = json.load(f)
d['active'] = '$ACCOUNT_NAME'
with open('$HOME/.claude/prism-accounts.json', 'w') as f:
    json.dump(d, f, indent=2)
"
```

## 현재 계정 확인

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
