# starter-kit — 복붙용 빈 스켈레톤

[[01-learn-compounding-kb]]의 "지식 복리 루프"를 자기 레포에 그대로 깔 수 있게 만든 시작 키트.
**전부 깔 필요 없다.** 차용 사다리(→ [[00-overview]]) 순서대로 1번부터 늘려라.

## 어디에 두는가 (= 배선표)

| 이 키트 파일 | 복사 위치 | 로딩 방식 |
|---|---|---|
| `gotchas.md` | `docs/wiki/gotchas.md` | 온디맨드 (검색될 때만) |
| `decisions.md` | `docs/wiki/decisions.md` | 온디맨드 |
| `routing-table.md` | `docs/wiki/README.md` 에 통합 | 온디맨드 |
| `learn-command.md` | `.claude/commands/learn.md` | `/learn` 호출 시 |

> ⚠️ 위치가 동작을 결정한다. `.claude/commands/`에 둬야 `/learn`으로 불린다. 자세한 배선표는 [[00-overview]] 2번.

## 최소 시작 (1칸)

1. `docs/wiki/gotchas.md` 한 장만 복사해서 만든다.
2. 작업하다 "또 틀린 것"이 나오면 표에 `틀림 → 맞음` 1줄 추가.
3. 끝. 이것만 해도 복리가 돌기 시작한다.

## 그다음 (2~3칸)

4. `decisions.md` 추가 — "왜 이 동작을 택했나"를 한 줄씩.
5. `learn-command.md`를 `.claude/commands/learn.md`로 복사 → 세션 끝에 `/learn` 호출 → 적을 것만 자동 적립.
6. 작업 시작 전엔 Claude에게 "작업 전 `docs/wiki/`에서 관련 교훈 먼저 찾아줘"라고 한 줄 시키면 회수 루프 완성.

## 핵심 규칙 3개 (잊지 말 것)

- **안 적는 게 기본값.** "다음에 또 만날 함정·결정"만. 작업로그 금지.
- **코드 사본 금지.** 실제 코드 경로만 링크. (코드가 진실의 출처)
- **상시 로드는 비싸다.** 진짜 매번 강제할 것만 `.claude/rules/`로 올린다.
