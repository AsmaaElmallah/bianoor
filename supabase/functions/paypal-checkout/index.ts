import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

// Secrets: PAYPAL_CLIENT_ID, PAYPAL_SECRET, PAYPAL_ENV ("sandbox" | "live", default sandbox),
// PAYPAL_WEBHOOK_ID (webhook URL: .../functions/v1/paypal-checkout?hook=paypal).
// "Verify JWT" must be OFF for this function: PayPal redirects the buyer back here without a token,
// and its webhooks carry no Supabase token either.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Kind = "subscription" | "course" | "book";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    if (req.method === "GET") return await handleReturn(req, admin);
    if (new URL(req.url).searchParams.get("hook") === "paypal") return await handleWebhook(req, admin);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "unauthorized" }, 401);
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const action = String(body.action ?? "");

    if (action === "create") {
      const kind = String(body.kind ?? "") as Kind;
      const itemId = String(body.item_id ?? "");
      if ((kind !== "subscription" && kind !== "course" && kind !== "book") || !itemId) {
        return json({ error: "bad_request" }, 400);
      }
      return await createOrder(admin, user.id, kind, itemId);
    }

    if (action === "capture") {
      const orderId = String(body.order_id ?? "");
      const { data: order } = await admin
        .from("paypal_orders").select("user_id").eq("id", orderId).maybeSingle();
      if (!order || order.user_id !== user.id) return json({ error: "not_found" }, 404);
      const result = await captureOrder(admin, orderId);
      return json(result, result.ok ? 200 : 402);
    }

    if (action === "inspect") {
      const { data: isStaff } = await userClient.rpc("is_staff");
      if (isStaff !== true) return json({ error: "forbidden" }, 403);
      return await inspectOrder(admin, String(body.order_id ?? ""));
    }

    return json({ error: "bad_request" }, 400);
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

async function createOrder(admin: SupabaseClient, userId: string, kind: Kind, itemId: string) {
  const { data: setting } = await admin
    .from("app_settings").select("value").eq("key", "payment_paypal_enabled").maybeSingle();
  if (setting?.value !== "true") return json({ error: "paypal_disabled" }, 403);

  let price: number | null = null;
  let title = "";
  if (kind === "subscription") {
    const { data: plan } = await admin
      .from("subscription_plans").select("name, price_usd, active").eq("id", itemId).maybeSingle();
    if (plan?.active) {
      price = plan.price_usd;
      title = plan.name;
    }
  } else if (kind === "course") {
    const { data: course } = await admin
      .from("courses").select("title, price_usd, access_type, publish_status").eq("id", itemId).maybeSingle();
    if (course?.publish_status === "published" && course.access_type === "paid") {
      price = course.price_usd;
      title = course.title;
    }
  } else {
    const { data: book } = await admin
      .from("library_paid_books").select("title, price_usd, publish_status").eq("id", itemId).maybeSingle();
    if (book?.publish_status === "published") {
      price = book.price_usd;
      title = book.title;
    }
  }
  if (!price || price <= 0) return json({ error: "no_price" }, 400);

  const value = Number(price).toFixed(2);
  const returnBase = `${Deno.env.get("SUPABASE_URL")}/functions/v1/paypal-checkout`;
  const res = await paypal("/v2/checkout/orders", {
    intent: "CAPTURE",
    purchase_units: [{
      reference_id: itemId,
      custom_id: `${kind}:${itemId}:${userId}`,
      description: title.slice(0, 120),
      amount: { currency_code: "USD", value },
    }],
    payment_source: {
      paypal: {
        experience_context: {
          brand_name: "Bayanour",
          user_action: "PAY_NOW",
          shipping_preference: "NO_SHIPPING",
          return_url: `${returnBase}?result=return`,
          cancel_url: `${returnBase}?result=cancel`,
        },
      },
    },
  });
  if (!res.ok) {
    console.error("paypal create failed", res.status, res.data);
    return json({ error: "paypal_error" }, 502);
  }

  const orderId = res.data.id as string;
  const approveUrl = (res.data.links as { rel: string; href: string }[] | undefined)
    ?.find((l) => l.rel === "payer-action" || l.rel === "approve")?.href;
  if (!orderId || !approveUrl) return json({ error: "paypal_error" }, 502);

  const { error } = await admin.from("paypal_orders").insert({
    id: orderId,
    user_id: userId,
    kind,
    item_id: itemId,
    amount: value,
  });
  if (error) return json({ error: error.message }, 500);

  return json({ order_id: orderId, approve_url: approveUrl });
}

async function captureOrder(admin: SupabaseClient, orderId: string) {
  const { data: order } = await admin
    .from("paypal_orders").select("*").eq("id", orderId).maybeSingle();
  if (!order) return { ok: false, status: "not_found" };
  if (order.status === "completed") return { ok: true, status: "completed", kind: order.kind };

  let res = await paypal(`/v2/checkout/orders/${orderId}/capture`, {});
  const captureError = res.ok ? null : res.data;
  if (!res.ok) {
    // Already captured (e.g. return page and app both confirmed) or not yet approved.
    res = await paypal(`/v2/checkout/orders/${orderId}`, null);
    if (!res.ok) {
      const detail = { lookupStatus: res.status, lookupError: res.data?.name ?? null, captureError: paypalIssue(captureError) };
      console.error("paypal order lookup failed", orderId, JSON.stringify(detail));
      return { ok: false, status: "paypal_error", detail };
    }
  }

  const capture = res.data.purchase_units?.[0]?.payments?.captures?.[0];
  const paid = res.data.status === "COMPLETED" &&
    capture?.status === "COMPLETED" &&
    capture.amount?.currency_code === order.currency &&
    Number(capture.amount?.value) >= Number(order.amount);
  if (!paid) {
    const detail = {
      orderStatus: res.data.status ?? null,
      captureStatus: capture?.status ?? null,
      captureReason: capture?.status_details?.reason ?? null,
      amount: capture?.amount ?? null,
      expected: { value: order.amount, currency: order.currency },
      captureError: paypalIssue(captureError),
    };
    console.warn("paypal not paid", orderId, JSON.stringify(detail));
    return { ok: false, status: capture?.status ?? res.data.status ?? "pending", detail };
  }

  await grant(admin, order.user_id, order.kind, order.item_id, orderId);
  await admin.from("paypal_orders")
    .update({ status: "completed", completed_at: new Date().toISOString() })
    .eq("id", orderId);
  return { ok: true, status: "completed", kind: order.kind };
}

// deno-lint-ignore no-explicit-any
function paypalIssue(err: any) {
  if (!err) return null;
  return {
    name: err.name ?? null,
    issue: err.details?.[0]?.issue ?? null,
    description: err.details?.[0]?.description ?? err.message ?? null,
  };
}

/** Staff support tool: what PayPal says about an order, and finish it if the buyer did approve. */
async function inspectOrder(admin: SupabaseClient, orderId: string) {
  const { data: order } = await admin
    .from("paypal_orders").select("*").eq("id", orderId).maybeSingle();
  if (!order) return json({ error: "not_found" }, 404);

  const env = Deno.env.get("PAYPAL_ENV") === "live" ? "live" : "sandbox";
  const before = await paypal(`/v2/checkout/orders/${orderId}`, null);
  if (!before.ok) {
    return json({
      env,
      localStatus: order.status,
      found: false,
      lookupStatus: before.status,
      lookupError: before.data?.name ?? null,
    });
  }

  const d = before.data;
  const unit = d.purchase_units?.[0];
  const snapshot = {
    env,
    localStatus: order.status,
    found: true,
    paypalStatus: d.status ?? null,
    payerCountry: d.payer?.address?.country_code ?? d.payment_source?.paypal?.address?.country_code ?? null,
    payerEmail: d.payer?.email_address ?? d.payment_source?.paypal?.email_address ?? null,
    payeeEmail: unit?.payee?.email_address ?? null,
    payeeMerchantId: unit?.payee?.merchant_id ?? null,
    captureStatus: unit?.payments?.captures?.[0]?.status ?? null,
    captureReason: unit?.payments?.captures?.[0]?.status_details?.reason ?? null,
  };

  if (order.status === "completed" || (d.status !== "APPROVED" && d.status !== "COMPLETED")) {
    return json(snapshot);
  }
  const attempt = await captureOrder(admin, orderId);
  return json({ ...snapshot, attempt });
}

async function grant(admin: SupabaseClient, userId: string, kind: Kind, itemId: string, orderId: string) {
  const receipt = `paypal:${orderId}`;
  if (kind === "book") {
    const { error } = await admin.from("library_book_purchases").upsert(
      { user_id: userId, book_id: itemId, source: "paypal", store_receipt: receipt },
      { onConflict: "user_id,book_id" },
    );
    if (error) throw error;
    return;
  }
  if (kind === "course") {
    const { error } = await admin.from("course_enrollments").upsert(
      { user_id: userId, course_id: itemId, source: "paypal", store_receipt: receipt },
      { onConflict: "user_id,course_id" },
    );
    if (error) throw error;
    return;
  }

  // Extends the plan and adds its lesson days in one transaction, at most once per order.
  const { error } = await admin.rpc("grant_paid_subscription", {
    p_order_id: orderId,
    p_user_id: userId,
    p_plan_id: itemId,
  });
  if (error) throw error;
}

async function handleReturn(req: Request, admin: SupabaseClient) {
  const url = new URL(req.url);
  if (url.searchParams.get("result") === "cancel") {
    return text("تم إلغاء الدفع.\nتقدري تقفلي الصفحة دي وترجعي لتطبيق بيانور.");
  }
  const orderId = url.searchParams.get("token") ?? "";
  if (!orderId) return text("رابط غير صحيح.", 400);
  const result = await captureOrder(admin, orderId);
  const done = result.kind === "book"
    ? "تم الدفع بنجاح ✅\nاقفلي الصفحة دي وارجعي لتطبيق بيانور، وهنتواصل معاكِ لتسليم الكتاب."
    : result.kind === "course"
    ? "تم الدفع بنجاح ✅\nاقفلي الصفحة دي وارجعي لتطبيق بيانور، هتلاقي الدورة اتفتحت."
    : "تم الدفع بنجاح ✅\nاقفلي الصفحة دي وارجعي لتطبيق بيانور، هتلاقي الاشتراك اتفعّل.";
  if (result.ok) return text(done);
  if (result.status === "PENDING") {
    return text("PayPal بيراجع الدفعة دي ⏳\nأول ما تتأكد هتتفعّل لوحدها. ارجعي لتطبيق بيانور ودوسي «تحققي من الدفع» بعد شوية.", 202);
  }
  return text("الدفع لسه ما اكتملش.\nارجعي للتطبيق ودوسي «تحققي من الدفع»، أو تواصلي معانا.", 402);
}

// Covers buyers who approve the payment but never come back to the return page.
async function handleWebhook(req: Request, admin: SupabaseClient) {
  const webhookId = Deno.env.get("PAYPAL_WEBHOOK_ID");
  if (!webhookId) {
    console.error("PAYPAL_WEBHOOK_ID not set");
    return json({ error: "webhook_not_configured" }, 500);
  }

  const raw = await req.text();
  // deno-lint-ignore no-explicit-any
  let event: any;
  try {
    event = JSON.parse(raw);
  } catch {
    return json({ error: "bad_request" }, 400);
  }

  const h = req.headers;
  const verify = await paypal("/v1/notifications/verify-webhook-signature", {
    auth_algo: h.get("paypal-auth-algo"),
    cert_url: h.get("paypal-cert-url"),
    transmission_id: h.get("paypal-transmission-id"),
    transmission_sig: h.get("paypal-transmission-sig"),
    transmission_time: h.get("paypal-transmission-time"),
    webhook_id: webhookId,
    webhook_event: event,
  });
  if (!verify.ok || verify.data?.verification_status !== "SUCCESS") {
    console.error("paypal webhook verification failed", verify.status, verify.data);
    return json({ error: "invalid_signature" }, 400);
  }

  let orderId = "";
  if (event.event_type === "CHECKOUT.ORDER.APPROVED") {
    orderId = String(event.resource?.id ?? "");
  } else if (event.event_type === "PAYMENT.CAPTURE.COMPLETED") {
    orderId = String(event.resource?.supplementary_data?.related_ids?.order_id ?? "");
  }
  if (!orderId) return json({ ok: true, ignored: event.event_type ?? null });

  const result = await captureOrder(admin, orderId);
  return json({ ok: true, order: orderId, status: result.status });
}

let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) return cachedToken.value;
  const id = Deno.env.get("PAYPAL_CLIENT_ID");
  const secret = Deno.env.get("PAYPAL_SECRET");
  if (!id || !secret) throw new Error("PAYPAL_CLIENT_ID / PAYPAL_SECRET not set");
  const res = await fetch(`${paypalBase()}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${id}:${secret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`paypal auth failed: ${JSON.stringify(data)}`);
  cachedToken = { value: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
  return cachedToken.value;
}

function paypalBase() {
  return Deno.env.get("PAYPAL_ENV") === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}

// deno-lint-ignore no-explicit-any
async function paypal(path: string, body: unknown | null): Promise<{ ok: boolean; status: number; data: any }> {
  const res = await fetch(`${paypalBase()}${path}`, {
    method: body === null ? "GET" : "POST",
    headers: {
      Authorization: `Bearer ${await accessToken()}`,
      "Content-Type": "application/json",
    },
    body: body === null ? undefined : JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, data };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function text(message: string, status = 200) {
  return new Response(message, {
    status,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
