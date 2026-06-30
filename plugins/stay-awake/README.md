# stay-awake

Claude Code가 **실제로 작업하는 동안에만** macOS의 sleep을 막고, 제어권이 사용자에게 넘어가면(권한 다이얼로그, 플랜 검토, 60초+ 입력 대기 등) 자동으로 일시정지하는 플러그인.

> 퇴근하거나 자리를 비운 사이에도 Claude가 돌리던 작업이 멈추지 않게 하는 게 목적.
> 설치·사용법은 [`recipes/stay-awake.md`](../../recipes/stay-awake.md) 참고.

## 동작 방식

`caffeinate -i -w <claude_pid>` 프로세스 하나를 띄웠다 죽였다 하는 게 전부다.

| 훅 | 매처 | 동작 |
|---|---|---|
| `SessionStart` | `*` | gc — 죽은 세션이 남긴 pid 파일 정리 |
| `UserPromptSubmit` | `*` | **start** — caffeinate 시작 |
| `PostToolUse` | `*` | **start** (멱등 — 이미 떠 있으면 무시) |
| `PreToolUse` | `AskUserQuestion\|ExitPlanMode` | **stop** — 사용자 입력 대기 |
| `Notification` | `permission_prompt\|idle_prompt` | **stop** — 권한/유휴 대기 |
| `Stop` | `*` | **stop** — 턴 종료 |
| `SessionEnd` | `*` | **stop** — 세션 종료(안전망) |

## 안전장치

- **`-w <claude_pid>`**: 지정한 Claude 프로세스가 죽는 즉시 caffeinate도 함께 종료된다. Ctrl+C·강제 종료·크래시·`/clear` 어디서 끊겨도 **고아 caffeinate가 남지 않는다.**
- **start는 멱등**: 이미 caffeinate가 살아 있으면 즉시 종료. 잦은 `PostToolUse` 호출에도 무해.
- **stop은 멱등**: 없거나 이미 죽은 caffeinate는 그냥 no-op.
- **Claude 프로세스(PPID)별 독립**: 여러 Claude Code 창을 동시에 띄워도 각자 자기 caffeinate만 관리한다. pid 파일은 `~/.cache/stay-awake/sessions/<claude_pid>.pid`.

## 강도: `caffeinate -i`

**idle(유휴) 시스템 sleep만 막는다.** 가장 보수적인 선택.

- 디스플레이가 꺼지거나 화면보호기가 떠도 → 시스템은 안 자고 Claude는 계속 작업한다. **문제 없음.**
- **노트북 뚜껑을 닫으면 → 잠긴다.** `caffeinate`로는 막을 수 없는 하드웨어 동작이다. 자리를 비우려면 **뚜껑을 열어둬야 한다.** ([`recipes/stay-awake.md`](../../recipes/stay-awake.md)의 "함정" 참고)

## 플랫폼

macOS 전용. 다른 OS에서는 모든 훅이 `uname -s` 체크로 no-op 처리된다.

## 수동 확인

```bash
# 작업 중이면 caffeinate 1개가 보이고, 응답이 끝나면 사라진다
pgrep -fl 'caffeinate -i -w'
ls ~/.cache/stay-awake/sessions/
```

## 참고

macOS에서 흔히 쓰는 `caffeinate` 자동화 기법을, 스터디 공용 공개 저장소에서 바로 설치할 수 있게 최소 구성으로 재작성한 버전이다. 락·상태 교차검증·고아 스윕 같은 고급 동시성 처리는 의도적으로 뺐다 — `-w <pid>` 백스톱만으로 고아가 안 남고, 동시 훅 경합은 스터디 사용 규모에선 실질 문제가 없기 때문. 더 강한 보장이 필요하면 훅 스크립트에 mkdir 기반 락을 추가하면 된다.
