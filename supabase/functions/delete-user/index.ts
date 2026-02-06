// Delete the authenticated user's account. Requires Authorization: Bearer <access_token>.
// Tries getUser(token) first (legacy); if that fails, verifies JWT via JWKS and uses sub.
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

  // 1) Try legacy getUser(token) first (works with legacy JWT)
  const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: { user }, error: getUserError } = await anonClient.auth.getUser(token);
  if (!getUserError && user?.id) {
    userId = user.id;
  }

  // 2) If that failed, verify JWT with JWKS (no issuer check to avoid mismatch)
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
