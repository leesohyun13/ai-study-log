### 🍳 퇴근해도 Claude Code가 계속 일하게 — macOS sleep 방지 (stay-awake 플러그인)

- **작성자 / 직무:** 현호 / 개발
- **날짜:** 2026-06-30
- **상태:** ✅ 성공

---

**1. 문제 (Problem)**
> Claude Code에 긴 작업(빌드, 리팩토링, 리서치 루프 등)을 시켜놓고 퇴근하거나 자리를 비우면, 노트북이 절전모드(idle sleep)에 들어가면서 **작업이 그 자리에서 멈춘다.** 끝나는 걸 기다리거나, 중간에 끊긴 걸 다음 날 다시 돌려야 했다.

**2. 원래 걸리던 시간**
> 작업 자체 시간 + "끝날 때까지 자리 지키는" 대기 시간. 30분~몇 시간짜리 작업이면 그 시간 동안 컴퓨터 앞에 묶여 있어야 했다.

**3. 쓴 도구 · 프롬프트 (Recipe)**

> macOS의 `caffeinate`를 Claude Code 훅으로 자동 제어하는 **stay-awake 플러그인**. 이 저장소(`ai-study-log`)가 곧 플러그인 마켓플레이스라 **명령어 2줄이면 끝.** (orangesquare-org 같은 사내 접근 권한 필요 없음 — 이 저장소가 public이라 누구나 가능)

**설치 (최초 1회)** — Claude Code 안에서:

```text
/plugin marketplace add leesohyun13/ai-study-log
/plugin install stay-awake@ai-study-log
```

설치 후 Claude Code를 한 번 재시작하면 훅이 적용된다. **끝.** 이제부터 Claude가 작업하는 동안 자동으로 sleep이 막히고, 응답이 끝나거나 입력을 기다리는 동안엔 자동으로 풀린다.

**잘 동작하는지 확인** — 터미널에서:

```bash
# Claude가 작업 중일 때 실행하면 caffeinate 1개가 뜬다. 응답이 끝나면 사라진다.
pgrep -fl 'caffeinate -i -w'
```

**동작 원리 (한 줄):** Claude가 일하기 시작하면(`UserPromptSubmit`/`PostToolUse` 훅) `caffeinate -i -w <claude_pid>`를 띄워 idle sleep을 막고, 제어권이 사용자에게 넘어가면(`Stop`/권한 다이얼로그/유휴 대기) 죽인다. `-w <claude_pid>` 덕분에 Claude 프로세스가 죽으면 caffeinate도 같이 죽어서 **고아 프로세스가 남지 않는다.**

<details>
<summary><b>플러그인 없이 수동으로 쓰고 싶다면 (가장 단순한 대안)</b></summary>

플러그인 설치 없이, 자리 비우기 직전에 터미널에서 직접 한 줄 실행해도 된다:

```bash
# 이 터미널이 켜져 있는 동안 idle sleep 방지. 작업 끝나면 Ctrl+C로 종료.
caffeinate -i

# 또는 특정 Claude Code 프로세스가 살아있는 동안만 (그 프로세스가 죽으면 자동 종료)
caffeinate -i -w $(pgrep -f 'claude' | head -1)
```

플러그인은 이걸 "작업 중에만 자동으로 켜고 끄게" 만든 것뿐이다. 수동 방식은 작업이 끝나도 계속 깨어 있으니 잊지 말고 꺼야 한다.

</details>

**4. 줄어든 시간 / 효과**
> "끝날 때까지 자리 지키기" 대기 시간 → **0.** 작업 걸어놓고 퇴근하면 밤새 알아서 끝난다(아래 함정 1만 지키면).

**5. 함정 (안 되던 것 / 주의점)** ← **이 칸이 제일 중요하다**

> **① ⚠️ 노트북 뚜껑을 닫으면 무조건 잠긴다.**
> `caffeinate -i`는 *idle* sleep(가만히 둬서 자는 것)만 막는다. **뚜껑을 닫으면(clamshell)** macOS가 하드웨어 차원에서 잠가버리고, 이건 `caffeinate`로 못 막는다. → **자리를 비우려면 뚜껑을 열어둬라.** 디스플레이가 꺼지거나 화면보호기가 떠도 작업은 안 멈추니 괜찮다. (정 뚜껑을 닫아야 하면: 전원 어댑터 + 외장 모니터/키보드 연결해 clamshell 모드로 쓰거나, 고급 사용자는 `sudo pmset -c disablesleep 1` — AC 전원 한정, 끝나면 `0`으로 되돌릴 것.)
>
> **② macOS 전용.** Windows/Linux에서는 훅이 그냥 아무 일도 안 한다(no-op). Windows는 `powercfg`, `presentationsettings.exe` 등 다른 기법이 필요.
>
> **③ 전원 연결 권장.** 배터리만으로 두면 배터리 방전으로 꺼질 수 있다. 어댑터 꽂아두기.
>
> **④ 권한 대기 중엔 일부러 멈춘다.** Claude가 권한 다이얼로그나 `AskUserQuestion`으로 사용자 입력을 기다리는 동안엔 caffeinate가 꺼진다(어차피 작업이 그 지점에서 멈춰 있으니 손해 없음 — 돌아와서 답하면 다시 깨어남). **자리를 비운 사이 권한 프롬프트가 뜨면 거기서 멈춘다.** 무인 장시간 작업이면 위험한 명령이 없는 선에서 권한을 미리 넓혀두는 걸 고려.

**6. 재사용 가능성**
> **높음.** macOS를 쓰는 스터디 멤버 누구나 명령어 2줄로 동일하게 세팅 가능. 같은 `caffeinate` 기법은 긴 빌드·테스트·다운로드·렌더링 등 "자리 비우는 동안 멈추면 안 되는" 모든 작업에 그대로 응용된다. 플러그인 소스는 [`plugins/stay-awake/`](../plugins/stay-awake/)에 있으니 훅 자동화의 예제로도 그대로 읽어볼 수 있다.
