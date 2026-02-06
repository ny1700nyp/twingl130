# Delete User Edge Function – 배포 방법

설정의 "Delete my account"가 동작하려면 Supabase Edge Function `delete-user`를 배포해야 합니다.

---

## 방법 A: Supabase 웹 대시보드로 배포

1. **Supabase 대시보드** 접속  
   https://supabase.com/dashboard → 프로젝트 선택

2. **Edge Functions** 메뉴  
   왼쪽 사이드바에서 **Edge Functions** 클릭

3. **새 함수 배포**  
   **Deploy a new function** (또는 "Create a new function") 클릭 후 **Via Editor** 선택

4. **함수 이름**  
   이름을 **`delete-user`** 로 지정 (앱이 이 이름으로 호출함)

5. **코드 붙여넣기**  
   에디터에 아래 코드 전체를 붙여넣고 저장 (먼저 getUser, 실패 시 JWKS로 검증):

```ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as jose from "jsr:@panva/jose@6";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const JWKS_URL = `${SUPABASE_URL.replace(/\/$/, "")}/auth/v1/.well-known/jwks.json`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return Response.json({ error: "Missing or invalid Authorization header" }, {
      status: 401,
      headers: { ...corsHeaders(), "Content-Type": "application/json" },
    });
  }
  const token = authHeader.replace("Bearer ", "").trim();

  let userId: string | null = null;
  const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: { user }, error: getUserError } = await anonClient.auth.getUser(token);
  if (!getUserError && user?.id) userId = user.id;

  let lastError = getUserError?.message ?? null;
  if (!userId) {
    try {
      const JWKS = jose.createRemoteJWKSet(new URL(JWKS_URL));
      const { payload } = await jose.jwtVerify(token, JWKS);
      const sub = payload.sub;
      if (sub && typeof sub === "string") userId = sub;
    } catch (e) {
      lastError = e instanceof Error ? e.message : String(e);
    }
  }

  if (!userId) {
    return Response.json(
      { error: lastError ?? "Invalid or expired token" },
      { status: 401, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
    );
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteError) {
    return Response.json(
      { error: deleteError.message },
      { status: 400, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
    );
  }

  return Response.json({ success: true }, {
    status: 200,
    headers: { ...corsHeaders(), "Content-Type": "application/json" },
  });
});

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}
```

6. **배포**  
   **Deploy function** 버튼 클릭. 배포가 끝나면 앱에서 "Delete me from Twingl"이 동작합니다.

> 대시보드에서 배포한 함수는 URL, Anon Key, Service Role Key가 자동으로 설정됩니다. 별도 환경 변수 입력은 필요 없습니다.

> **401이 계속 나는 경우:** 대시보드 배포는 게이트웨이 JWT 검사(verify_jwt)를 끌 수 없을 수 있습니다. 그럴 때는 **방법 B(CLI)** 로 `--no-verify-jwt` 옵션을 붙여 배포해 보세요.

---

## 방법 B: Supabase CLI로 배포

## 1. Supabase CLI 설치

- https://supabase.com/docs/guides/cli

## 2. 로그인 및 프로젝트 연결

```bash
supabase login
supabase link --project-ref oibboowecbxvjmookwtd
```

(프로젝트 ref는 Supabase 대시보드 URL에서 확인 가능)

## 3. Edge Function 배포

**중요:** 게이트웨이에서 JWT 검사를 건너뛰어야 401이 나지 않습니다. `supabase/config.toml`에 `[functions.delete-user] verify_jwt = false`가 있으면 자동 적용됩니다. 없으면 아래처럼 옵션을 붙이세요.

```bash
supabase functions deploy delete-user --no-verify-jwt
```

배포 시 `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`는 자동으로 주입됩니다.

## 4. 동작 방식

- 앱에서 "Delete my account" → Yes 선택 시, 현재 세션의 JWT로 `delete-user` 함수를 호출합니다.
- 함수는 JWT로 사용자를 검증한 뒤, **service role**로 Supabase Auth에서 해당 사용자를 삭제합니다.
- 이메일·Google 등 모든 로그인 방식에 동일하게 적용됩니다.
