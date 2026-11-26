import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-push-secret",
  "Content-Type": "application/json",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("Supabase service credentials are not available", { status: 500, headers: corsHeaders });
  }

  try {
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: runtimeSecrets, error: secretError } = await admin.rpc("service_chat_push_runtime_secrets");
    if (secretError) throw secretError;
    const expectedSecret = String(runtimeSecrets?.service_chat_push_secret || "");
    const vapidPublicKey = String(runtimeSecrets?.service_chat_vapid_public || "");
    const vapidPrivateKey = String(runtimeSecrets?.service_chat_vapid_private || "");
    if (!expectedSecret || req.headers.get("x-push-secret") !== expectedSecret) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }
    if (!vapidPublicKey || !vapidPrivateKey) {
      return new Response("VAPID keys are not configured", { status: 500, headers: corsHeaders });
    }

    const payload = await req.json();
    const ticket = String(payload.ticket || "");
    if (!ticket) return new Response("Missing ticket", { status: 400, headers: corsHeaders });

    const { data: rows, error } = await admin
      .from("service_chat_push_subscriptions")
      .select("id, subscription");
    if (error) throw error;
    if (!rows?.length) return new Response(JSON.stringify({ sent: 0 }), { headers: corsHeaders });

    webpush.setVapidDetails("mailto:admin@copycomputer.app", vapidPublicKey, vapidPrivateKey);
    const title = "COPY COMPUTER · Pesan pelanggan baru";
    const body = String(payload.customer_name || "Pelanggan") + " · " + ticket + ": " +
      String(payload.message || "Ada pesan baru").slice(0, 110);
    const notification = JSON.stringify({
      title, body, ticket,
      url: "https://copycompcctv.github.io/CCTV_Report/servisan/app.html#jobs",
    });

    let sent = 0;
    const expired: number[] = [];
    const results = await Promise.allSettled(rows.map(async (row: { id: number; subscription: any }) => {
      try {
        await webpush.sendNotification(row.subscription, notification, { TTL: 86400 });
        sent++;
      } catch (err) {
        const status = Number((err as any)?.statusCode || 0);
        if (status === 404 || status === 410) expired.push(row.id);
        else console.error("Push delivery failed:", status);
      }
    }));
    if (expired.length) await admin.from("service_chat_push_subscriptions").delete().in("id", expired);
    return new Response(JSON.stringify({ sent, expired: expired.length, attempts: results.length }), { headers: corsHeaders });
  } catch (err) {
    console.error("service-chat-push:", err);
    return new Response("Push delivery failed", { status: 500, headers: corsHeaders });
  }
});
