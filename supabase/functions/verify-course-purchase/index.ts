import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// يفتح دورة مدفوعة للأم بعد التحقق من الشراء مع Google Play.
// Secrets:
//   GOOGLE_SERVICE_ACCOUNT_JSON  — حساب خدمة له صلاحية على التطبيق في Play Console (مطلوب للتحقق الحقيقي)
//   ANDROID_PACKAGE_NAME         — اختياري، الافتراضي com.bayanour.bayanour
//   ALLOW_UNVERIFIED_PURCHASES=1 — للتجربة فقط: يفتح الدورة بدون تحقق من Google

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "missing auth" }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userErr } = await userClient.auth.getUser();
    if (userErr || !user) return json({ error: "unauthorized" }, 401);

    const body = await req.json();
    const courseId = String(body.course_id ?? "");
    const productId = String(body.product_id ?? "");
    const purchaseToken = body.purchase_token ? String(body.purchase_token) : "";
    const platform = String(body.platform ?? "android");
    if (!courseId || !productId) {
      return json({ error: "course_id and product_id required" }, 400);
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: course } = await admin
      .from("courses")
      .select("id, access_type, publish_status, store_product_id_android, store_product_id_ios")
      .eq("id", courseId)
      .maybeSingle();

    if (!course || course.publish_status !== "published") {
      return json({ error: "course not found" }, 404);
    }
    const expectedProduct = platform === "ios"
      ? course.store_product_id_ios
      : course.store_product_id_android;
    if (!expectedProduct || expectedProduct !== productId) {
      return json({ error: "product does not match course" }, 400);
    }

    const allowUnverified = Deno.env.get("ALLOW_UNVERIFIED_PURCHASES") === "1";
    const serviceAccount = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");

    if (platform === "android" && serviceAccount) {
      if (!purchaseToken) return json({ error: "purchase_token required" }, 400);
      const packageName = Deno.env.get("ANDROID_PACKAGE_NAME") ?? "com.bayanour.bayanour";
      const purchase = await getGooglePurchase(
        JSON.parse(serviceAccount),
        packageName,
        productId,
        purchaseToken,
      );
      // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
      if (purchase.purchaseState !== 0) {
        return json({ error: "purchase not completed", state: purchase.purchaseState }, 402);
      }
    } else if (!allowUnverified) {
      return json({ error: "store verification not configured" }, 503);
    }

    const receipt = purchaseToken || `unverified:${platform}:${user.id}:${courseId}`;

    const { data: reused } = await admin
      .from("course_enrollments")
      .select("user_id")
      .eq("store_receipt", receipt)
      .neq("user_id", user.id)
      .maybeSingle();
    if (reused) return json({ error: "receipt already used" }, 409);

    const { error: upsertErr } = await admin.from("course_enrollments").upsert(
      {
        user_id: user.id,
        course_id: courseId,
        source: "store",
        store_receipt: receipt.slice(0, 2000),
      },
      { onConflict: "user_id,course_id" },
    );
    if (upsertErr) return json({ error: upsertErr.message }, 500);

    return json({ ok: true, course_id: courseId });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

type ServiceAccount = { client_email: string; private_key: string };

async function getGooglePurchase(
  account: ServiceAccount,
  packageName: string,
  productId: string,
  token: string,
): Promise<{ purchaseState?: number }> {
  const accessToken = await googleAccessToken(account);
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
      encodeURIComponent(packageName)
    }/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!res.ok) {
    throw new Error(`google verify failed ${res.status}: ${await res.text()}`);
  }
  return await res.json();
}

async function googleAccessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;

  const pem = account.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`google token failed ${res.status}: ${await res.text()}`);
  const data = await res.json();
  return data.access_token as string;
}

function b64url(input: string | Uint8Array): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
