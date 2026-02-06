// Database Webhook handler: when a new message is inserted, send FCM push to recipient.
// Requires: FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY (from Firebase service account)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID");
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL");
const FCM_PRIVATE_KEY = Deno.env.get("FCM_PRIVATE_KEY")?.replace(/\\n/g, "\n");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (!FCM_PROJECT_ID || !FCM_CLIENT_EMAIL || !FCM_PRIVATE_KEY) {
    console.error("FCM credentials not configured");
    return Response.json({ ok: false, error: "FCM not configured" }, {
      status: 500,
      headers: { ...corsHeaders(), "Content-Type": "application/json" },
    });
  }

  try {
    const payload = await req.json();
    const { type, table, record } = payload;

    if (type !== "INSERT" || table !== "messages" || !record) {
      return Response.json({ ok: true, skipped: "not a message insert" }, {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const msgType = (record.type || "text").toString().toLowerCase();
    if (msgType !== "text") {
      return Response.json({ ok: true, skipped: "not a text message" }, {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const conversationId = record.conversation_id;
    const senderId = record.sender_id;
    const content = record.content ?? record.message_text ?? "New message";

    const { data: conv, error: convErr } = await supabase
      .from("conversations")
      .select("trainer_id, trainee_id")
      .eq("id", conversationId)
      .single();

    if (convErr || !conv) {
      return Response.json({ ok: false, error: "Conversation not found" }, {
        status: 400,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const recipientId =
      conv.trainer_id === senderId ? conv.trainee_id : conv.trainer_id;
    if (!recipientId) {
      return Response.json({ ok: true, skipped: "no recipient" }, {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const { data: tokens } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", recipientId)
      .eq("notifications_enabled", true);

    if (!tokens || tokens.length === 0) {
      return Response.json({ ok: true, skipped: "no FCM tokens" }, {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const { data: senderProfile } = await supabase
      .from("profiles")
      .select("display_name, username")
      .eq("user_id", senderId)
      .single();

    const senderName =
      senderProfile?.display_name || senderProfile?.username || "Someone";
    const title = `New message from ${senderName}`;
    const body =
      content.length > 100 ? `${content.substring(0, 100)}...` : content;

    const jwt = new JWT({
      email: FCM_CLIENT_EMAIL,
      key: FCM_PRIVATE_KEY,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await jwt.getAccessToken();
    const token = accessToken?.token;
    if (!token) {
      return Response.json({ ok: false, error: "Failed to get FCM token" }, {
        status: 500,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;
    const results = [];

    for (const row of tokens) {
      const fcmToken = row.fcm_token;
      if (!fcmToken) continue;

      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: { title, body },
            data: {
              conversation_id: conversationId,
            },
            android: {
              priority: "high",
              notification: { channel_id: "messages" },
            },
            apns: {
              payload: { aps: { sound: "default" } },
              fcm_options: {},
            },
          },
        }),
      });
      results.push({ token: fcmToken.substring(0, 20) + "...", status: res.status });
    }

    return Response.json({ ok: true, sent: results.length, results }, {
      status: 200,
      headers: { ...corsHeaders(), "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-push-on-message error:", e);
    return Response.json({ ok: false, error: String(e) }, {
      status: 500,
      headers: { ...corsHeaders(), "Content-Type": "application/json" },
    });
  }
});

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}
