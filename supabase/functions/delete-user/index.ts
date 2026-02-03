// Delete the authenticated user's account. Requires Authorization: Bearer <access_token>.
// Uses service role to delete the user from Supabase Auth (works for email and OAuth e.g. Google).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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

  const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: { user }, error: getUserError } = await anonClient.auth.getUser(token);
  if (getUserError || !user?.id) {
    return Response.json(
      { error: getUserError?.message ?? "Invalid or expired token" },
      { status: 401, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
    );
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);
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
