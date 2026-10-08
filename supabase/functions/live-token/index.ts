import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { RtcRole, RtcTokenBuilder } from "npm:agora-token@2.0.6";

// Issues an Agora pass for a live session.
// App ID comes from app_settings.agora_app_id (dashboard).
// Secret AGORA_APP_CERTIFICATE: when unset, token is null (Agora project in "Testing mode").

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const TOKEN_TTL_SECONDS = 4 * 60 * 60;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "unauthorized" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);

    const { session_id: sessionId } = await req.json().catch(() => ({}));
    if (!sessionId) return json({ error: "bad_request" }, 400);

    const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const [{ data: session }, { data: profile }, { data: appIdRow }] = await Promise.all([
      admin.from("live_sessions").select("id, status").eq("id", sessionId).maybeSingle(),
      admin.from("profiles").select("role").eq("id", user.id).maybeSingle(),
      admin.from("app_settings").select("value").eq("key", "agora_app_id").maybeSingle(),
    ]);
    if (!session) return json({ error: "not_found" }, 404);

    const appId = (appIdRow?.value ?? "").trim();
    if (!appId) return json({ error: "agora_not_configured" }, 503);

    const isStaff = ["admin", "editor", "reviewer"].includes(profile?.role ?? "");
    if (!isStaff && session.status !== "live") return json({ error: "not_live" }, 409);

    let role: "host" | "speaker" | "audience";
    if (isStaff) {
      role = "host";
    } else {
      const { data: request } = await admin
        .from("live_stage_requests")
        .select("status")
        .eq("session_id", sessionId)
        .eq("user_id", user.id)
        .maybeSingle();
      if (request?.status === "approved") {
        role = "speaker";
      } else {
        const { data: allowed } = await userClient.rpc("has_live_access", { p_session_id: sessionId });
        if (!allowed) return json({ error: "no_access" }, 403);
        role = "audience";
      }
    }

    const channel = `live_${session.id}`;
    const account = role === "host" ? `host_${user.id}` : user.id;
    const certificate = Deno.env.get("AGORA_APP_CERTIFICATE")?.trim();
    const token = certificate
      ? RtcTokenBuilder.buildTokenWithUserAccount(
        appId,
        certificate,
        channel,
        account,
        role === "audience" ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER,
        TOKEN_TTL_SECONDS,
        TOKEN_TTL_SECONDS,
      )
      : null;

    return json({ app_id: appId, channel, account, token, role });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
