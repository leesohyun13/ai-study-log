# Ponytail 플러그인 분석 노트

대상 저장소: <https://github.com/DietrichGebert/ponytail>

이 문서는 주니어 개발자가 Ponytail 플러그인에서 얻을 수 있는 인사이트, 실제 개발 중 사용법, 그리고 비슷한 플러그인을 만들 때 참고하면 좋은 파일들을 정리한다.

## 한 줄 요약

Ponytail은 새로운 도구를 많이 붙이는 플러그인이 아니라, 에이전트가 코드를 만들기 전에 "정말 필요한가?", "이미 있는 코드나 표준 기능으로 끝낼 수 없는가?", "가장 작은 올바른 diff는 무엇인가?"를 계속 확인하게 만드는 행동 제어 플러그인이다.

## 동작 방식

Ponytail이 직접 subagent를 실행하거나 여러 agent를 조율하는 것은 아니다. 핵심은 instruction injection과 mode state 관리다.

1. 세션이 시작되면 `SessionStart` hook이 실행된다.
2. 기본 모드(`full` 등)를 읽고 현재 모드를 상태 파일에 저장한다.
3. `skills/ponytail/SKILL.md`의 규칙을 hidden context로 주입한다.
4. 사용자가 `/ponytail lite|full|ultra|off`를 입력하면 `UserPromptSubmit` hook이 모드를 바꾼다.
5. host가 subagent를 만들면 `SubagentStart` hook이 같은 Ponytail 규칙을 subagent에도 주입한다.

즉, Ponytail은 "subagent를 돌리는 플러그인"이 아니라, parent agent와 subagent가 같은 개발 철학을 잃지 않도록 매번 같은 규칙을 다시 주입하는 플러그인이다.

## 주니어 개발자가 얻을 수 있는 인사이트

### 1. 적게 짜는 것은 대충 짜는 것이 아니다

Ponytail의 핵심 표현은 "lazy senior developer"지만, 여기서 lazy는 무책임하다는 뜻이 아니다. 문제를 충분히 이해한 뒤에 가장 작은 해결책을 고르는 태도다.

주니어가 특히 배울 점은 "작은 코드"보다 "작아도 맞는 위치에 있는 코드"가 중요하다는 점이다. 버그 리포트가 특정 화면이나 API를 가리키더라도, 실제 원인이 공통 함수라면 호출부마다 방어 코드를 넣는 대신 공통 지점에서 한 번 고치는 것이 더 작고 더 정확한 수정이다.

### 2. 구현 전에 사다리를 탄다

Ponytail은 코드를 쓰기 전에 아래 순서로 멈춰 보게 만든다.

1. 이 기능이 정말 필요한가?
2. 이미 코드베이스에 같은 기능이 있는가?
3. 표준 라이브러리로 가능한가?
4. 플랫폼 기본 기능으로 가능한가?
5. 이미 설치된 dependency로 가능한가?
6. 한 줄로 가능한가?
7. 그래도 필요하면 최소 구현을 작성한다.

이 순서가 중요한 이유는, 많은 주니어 실수가 "새 파일, 새 클래스, 새 abstraction"에서 시작되기 때문이다. 실제 현업에서는 새 구조를 만드는 것보다 기존 흐름을 이해하고 거기에 작게 얹는 능력이 더 자주 필요하다.

### 3. 플러그인은 기능보다 행동을 제품화할 수 있다

Ponytail의 새로움은 "도구를 하나 더 제공한다"가 아니라 "에이전트의 판단 기준을 바꾼다"에 있다.

일반적인 플러그인은 커맨드, MCP, formatter, generator를 추가한다. Ponytail은 agent가 문제를 대하는 기본 습관을 바꾼다. 우리가 플러그인을 만든다면 "어떤 작업을 자동화할까?"뿐 아니라 "에이전트가 어떤 기준으로 판단하게 만들까?"를 먼저 정의할 수 있다.

예를 들면 우리 팀용 플러그인은 다음처럼 만들 수 있다.

- DB 조회는 기본적으로 `readonly_query`를 먼저 고려하게 한다.
- 서로 다른 `__bind_key__` 모델 사이에서는 subquery 대신 리스트 조회 후 `in_()`을 쓰게 한다.
- Celery task에서는 `get_task_logger`와 `KafkaContext` 사용 여부를 확인하게 한다.
- API 변경 전에는 기존 Marshmallow schema, container, service 패턴을 먼저 찾게 한다.

이런 룰은 단순 lint로 잡기 어려운 팀의 개발 판단 기준이다. Ponytail은 이런 판단 기준을 플러그인으로 제품화할 수 있음을 보여준다.

### 4. Hook은 "기억 유지 장치"로 쓸 수 있다

에이전트는 긴 세션, compact, resume, subagent 실행을 거치면서 초반 instruction을 잊거나 약하게 적용할 수 있다. Ponytail은 hook을 사용해서 세션 시작, prompt 제출, subagent 시작 시점마다 같은 규칙을 다시 주입한다.

비슷한 플러그인을 만들 때도 hook을 단순 실행 스크립트로만 보지 말고, agent가 잊으면 안 되는 원칙을 계속 되살리는 장치로 볼 수 있다.

### 5. 좋은 플러그인은 예외를 명확히 적는다

Ponytail은 "작게 만들어라"만 말하지 않는다. 보안, trust boundary validation, 데이터 손실을 막는 에러 처리, 접근성, 사용자가 명시적으로 요구한 내용은 줄이지 말라고 못박는다.

이 부분이 중요하다. 좋은 규칙은 방향만 강하게 말하지 않고, 적용하면 안 되는 경계도 같이 정의한다. 우리도 플러그인을 만들 때 "항상 해라"보다 "언제 하지 말아야 하는가"를 반드시 써야 한다.

### 6. 플러그인도 테스트와 벤치마크가 필요하다

Ponytail은 hook, command, adapter, behavior drift를 테스트한다. 또 benchmark 문서로 token, LOC, cost, time 감소를 주장한다.

주니어 입장에서는 "프롬프트니까 대충 써도 된다"가 아니라, 플러그인도 제품이고 회귀가 생길 수 있다는 점을 배울 수 있다.

## 개발할 때 사용 방법

### 기본값: `/ponytail full`

일반 기능 개발, 버그픽스, 작은 리팩토링에는 `full`이 가장 적당하다.

```text
/ponytail full
```

이 모드는 기존 코드 재사용, 표준 기능 우선, 최소 diff를 강하게 요구한다. 다만 문제 이해, 보안, 데이터 정합성, 필요한 테스트까지 줄이라고 하지는 않는다.

### 요구사항이 애매할 때: `/ponytail lite`

주니어 개발자에게는 `lite`가 좋은 학습 모드다.

```text
/ponytail lite
```

이 모드는 요청받은 구현을 하되, 더 작은 대안이 있으면 한 줄로 알려준다. "일단 구현하면서도 더 단순한 길을 배우는" 방식이라 협업에 적합하다.

### 과한 설계를 걷어낼 때: `/ponytail ultra`

```text
/ponytail ultra
```

`ultra`는 YAGNI를 매우 강하게 적용한다. 죽은 코드 제거, 불필요한 factory/interface/config 제거, spec에 없는 확장성 제거에는 유용하다.

단, 결제, 정산, 인증, 권한, migration, 데이터 삭제, 장애 복구 같은 영역에서는 신중하게 써야 한다. 이런 영역은 "작은 코드"보다 "명확한 안전장치"가 우선이다.

### PR 전 점검: `/ponytail-review`

```text
/ponytail-review
```

정확성 리뷰가 아니라, 과한 구현만 보는 리뷰다. 예를 들면 다음을 찾는다.

- 지워도 되는 dead code
- 표준 라이브러리로 대체 가능한 custom code
- 플랫폼 기본 기능으로 충분한 dependency
- 구현체 하나뿐인 interface/factory
- 같은 로직을 더 짧게 쓸 수 있는 부분

### 끄기

```text
/ponytail off
```

또는:

```text
stop ponytail
normal mode
```

한 번 설정한 모드는 세션 안에서 계속 유지된다. 새 세션에서도 기본 모드를 바꾸려면 `PONYTAIL_DEFAULT_MODE` 환경변수나 Ponytail config의 `defaultMode`를 설정해야 한다.

## 우리 팀이 비슷한 플러그인을 만든다면

### 1. 핵심 철학을 먼저 한 문장으로 정한다

Ponytail의 중심 문장은 "가장 작은 올바른 구현"이다. 우리도 플러그인을 만들기 전에 이런 문장을 먼저 정해야 한다.

예시:

- "backend convention을 벗어나기 전에 기존 service/repository/schema 패턴을 먼저 찾는다."
- "DB 부하와 cross-bind query 위험을 코드 작성 전에 확인한다."
- "Celery task에서는 observability와 producer lifecycle을 기본 안전장치로 둔다."

### 2. core instruction과 host adapter를 분리한다

Ponytail은 핵심 규칙을 `skills/ponytail/SKILL.md`에 두고, Claude/Codex/Copilot/OpenCode 같은 host별 처리는 얇은 adapter로 둔다.

우리도 다음 구조를 참고할 수 있다.

```text
skills/team-backend/SKILL.md      # 팀 개발 원칙의 본체
hooks/team-activate.js            # 세션 시작 시 규칙 주입
hooks/team-mode-tracker.js        # 모드 변경 추적
hooks/team-subagent.js            # subagent에도 규칙 전파
commands/team.toml                # /team strict|lite|off
commands/team-review.toml         # PR 전 팀 convention 리뷰
tests/*.test.js                   # hook과 command drift 테스트
```

### 3. mode를 둔다

하나의 강도만 있으면 너무 빡빡하거나 너무 약할 수 있다. Ponytail처럼 `lite`, `full`, `ultra`를 두면 상황별로 다르게 쓸 수 있다.

우리 팀용 예시:

- `lite`: 팀 convention 위반 가능성만 알려준다.
- `full`: convention에 맞게 직접 수정한다.
- `strict`: 위험한 DB/Celery/API 패턴은 작업 전에 강하게 차단한다.

### 4. subagent까지 규칙을 전파한다

main agent가 규칙을 알아도 subagent가 모르면 코드 리뷰, 검색, 리팩토링 helper가 다른 기준으로 판단할 수 있다. Ponytail의 `SubagentStart` hook은 이 문제를 해결한다.

팀 플러그인을 만든다면 subagent에도 반드시 다음을 전달해야 한다.

- 팀 architecture rule
- 금지 패턴
- 예외 조건
- 리뷰 출력 형식

### 5. "하지 말아야 할 것"을 명확히 적는다

Ponytail이 좋은 이유는 작게 만들라는 말 옆에 예외를 둔다는 점이다. 우리도 아래 같은 경계를 명확히 적어야 한다.

- 보안 validation은 줄이지 않는다.
- 데이터 손실 방지 로직은 줄이지 않는다.
- 결제/정산/권한 코드는 테스트 없이 단순화하지 않는다.
- 사용자가 명시적으로 요구한 호환성은 제거하지 않는다.
- 문제 이해를 생략하고 작은 diff만 만들지 않는다.

## 중요 파일

| 파일 | 역할 | 참고할 점 |
| --- | --- | --- |
| [`skills/ponytail/SKILL.md`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/skills/ponytail/SKILL.md) | 플러그인의 핵심 행동 규칙 | 플러그인의 "제품 철학"을 한 파일에 모으는 방식 |
| [`AGENTS.md`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/AGENTS.md) | 플러그인 없는 agent도 읽을 수 있는 fallback 지침 | repo-level instruction으로도 핵심 규칙을 전달하는 방식 |
| [`.codex-plugin/plugin.json`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/.codex-plugin/plugin.json) | Codex용 plugin manifest | skills, hooks, UI metadata를 연결하는 방식 |
| [`.claude-plugin/plugin.json`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/.claude-plugin/plugin.json) | Claude용 plugin manifest | host별 manifest를 분리하는 방식 |
| [`hooks/claude-codex-hooks.json`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/claude-codex-hooks.json) | hook event wiring | `SessionStart`, `UserPromptSubmit`, `SubagentStart` 조합 |
| [`hooks/ponytail-activate.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-activate.js) | 세션 시작 시 규칙 주입 | 기본 모드 읽기, 상태 저장, hidden context 출력 |
| [`hooks/ponytail-mode-tracker.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-mode-tracker.js) | `/ponytail` 명령 감지 | 사용자 프롬프트를 보고 mode state를 바꾸는 방식 |
| [`hooks/ponytail-subagent.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-subagent.js) | subagent 시작 시 규칙 재주입 | parent context가 subagent에 자동 전달되지 않는 문제 해결 |
| [`hooks/ponytail-runtime.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-runtime.js) | 상태 파일과 host별 hook output 처리 | Codex, Claude, Copilot별 출력 포맷 분기 |
| [`hooks/ponytail-config.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-config.js) | 기본 모드와 config 해석 | env, config file, default fallback 순서 |
| [`hooks/ponytail-instructions.js`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/hooks/ponytail-instructions.js) | SKILL 본문을 모드별로 필터링 | core instruction을 여러 adapter에서 재사용하는 방식 |
| [`commands/ponytail.toml`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/commands/ponytail.toml) | `/ponytail` 명령 정의 | 사용자 진입점을 짧고 명확하게 만드는 방식 |
| [`commands/ponytail-review.toml`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/commands/ponytail-review.toml) | over-engineering 리뷰 명령 | 일반 리뷰와 목적이 다른 특화 리뷰 명령 |
| [`docs/agent-portability.md`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/docs/agent-portability.md) | 여러 agent host로 이식하는 전략 | core는 공유하고 adapter만 얇게 두는 설계 |
| [`docs/platform-native.md`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/docs/platform-native.md) | native/platform 우선 판단 예시 | 추상적인 원칙을 실제 대체 목록으로 바꾸는 방식 |
| [`benchmarks/results/2026-06-18-agentic.md`](https://raw.githubusercontent.com/DietrichGebert/ponytail/main/benchmarks/results/2026-06-18-agentic.md) | 효과 측정 결과 | LOC, token, cost, time 감소를 근거로 제시하는 방식 |
| [`tests/`](https://github.com/DietrichGebert/ponytail/tree/main/tests) | hook, command, adapter 테스트 | 플러그인도 회귀 테스트 대상이라는 점 |

## 주니어 개발자를 위한 실전 체크리스트

작업 전에:

- 새 코드를 쓰기 전에 기존 코드에서 같은 역할을 하는 함수, service, schema, util을 검색한다.
- helper를 새로 만들기 전에 표준 라이브러리나 이미 설치된 dependency로 가능한지 본다.
- abstraction을 만들기 전에 구현체가 둘 이상 필요한지 확인한다.
- 버그 수정이면 증상이 아니라 공통 원인을 찾는다.

작업 중:

- 파일 수를 늘리기 전에 기존 파일에 자연스럽게 들어갈 수 있는지 본다.
- local workaround가 아니라 shared function에서 고칠 수 있는지 본다.
- "나중에 필요할 수도 있어서" 만든 옵션, interface, config는 대부분 제거한다.
- 단순화를 의도했다면 이유와 한계를 짧게 남긴다.

작업 후:

- non-trivial logic에는 최소 하나의 실행 가능한 확인 수단을 남긴다.
- PR 전에 `/ponytail-review`로 지울 수 있는 코드를 찾는다.
- 단순화하면서 보안, 데이터 정합성, 에러 처리, 접근성을 줄이지 않았는지 확인한다.

## 결론

Ponytail의 진짜 가치는 "짧은 답변"이 아니라 "작은 구현을 선택하는 판단 체계"에 있다. 주니어 개발자는 이 플러그인을 통해 구현 속도보다 중요한 것이 문제 이해, 기존 코드 재사용, 불필요한 추상화 회피, 안전장치의 경계 설정이라는 점을 배울 수 있다.

우리가 비슷한 플러그인을 만든다면 Ponytail의 구조를 그대로 복사하기보다, 우리 팀의 반복 실수와 architecture convention을 "hook으로 계속 주입되는 판단 기준"으로 만드는 쪽이 더 가치 있다.
