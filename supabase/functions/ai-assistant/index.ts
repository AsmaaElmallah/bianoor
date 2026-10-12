import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

// «مساعدة بيانور» — chat + daily plan + embedding the references library.
// Secrets: GEMINI_API_KEY (free, Google AI Studio). Optional: ANTHROPIC_API_KEY when ai_provider = claude.
// Single self-contained file so it can be deployed from the Supabase dashboard editor.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const AGE_BANDS = ["m0_3", "m3_6", "m6_12", "m12_18", "m18_24"];
const AGE_LABELS = [
  "من الولادة لـ 3 شهور",
  "من 3 لـ 6 شهور",
  "من 6 لـ 12 شهر",
  "من سنة لسنة ونص",
  "من سنة ونص لسنتين",
];
const EMBED_MODEL = "gemini-embedding-001";
const EMBED_DIMS = 768;
const HISTORY_LIMIT = 10;

type Role = "user" | "assistant";
type ChatMsg = { role: Role; content: string };
type Settings = {
  enabled: boolean;
  provider: "gemini" | "claude";
  model: string;
  dailyLimit: number;
  globalLimit: number;
};
type Reference = { id: string; title: string; content: string; source_name: string; source_url: string | null };
type Baby = { childId: string | null; band: string; bandIndex: number; name: string; profileText: string };

class AiError extends Error {
  constructor(public code: "busy" | "not_configured" | "failed", detail?: string) {
    super(detail ?? code);
  }
}

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

    const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const body = await req.json().catch(() => ({}));
    const settings = await loadSettings(admin);

    switch (body.action) {
      case "embed_knowledge":
        return await handleEmbedKnowledge(admin, user.id);
      case "daily_plan":
        if (!settings.enabled) return json({ status: "disabled" });
        return await handleDailyPlan(admin, user.id, body, settings);
      case "ask":
        if (!settings.enabled) return json({ status: "disabled" });
        return await handleAsk(admin, user.id, body, settings);
      default:
        return json({ error: "bad_request" }, 400);
    }
  } catch (e) {
    console.error(e);
    return json({ error: "server_error" }, 500);
  }
});

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

async function handleAsk(
  admin: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  settings: Settings,
) {
  const question = String(body.question ?? "").trim().slice(0, 1000);
  if (question.length < 2) return json({ error: "bad_request" }, 400);
  const meal = body.mode === "meal" ? readMeal(body.meal) : null;

  const baby = await loadBaby(admin, userId, body.age_range_index);
  const conversationId = await ensureConversation(admin, userId, body.conversation_id, baby.childId, question);
  const history = await loadHistory(admin, conversationId);

  if (detectEmergency(question, baby.bandIndex)) {
    await insertMessage(admin, conversationId, userId, "user", "normal", question, null);
    const message = await insertMessage(
      admin, conversationId, userId, "assistant", "emergency", EMERGENCY.message, EMERGENCY,
    );
    await touchConversation(admin, conversationId);
    return json({ status: "emergency", conversation_id: conversationId, message });
  }

  const quota = await consume(admin, userId, "message", settings);
  if (quota !== "ok") return json({ status: quota, conversation_id: conversationId });

  const safeQuestion = hideName(question, baby.name);
  const refs = await findReferences(
    admin,
    meal ? `أكل طفل ${AGE_LABELS[baby.bandIndex]}: ${meal.ingredients}` : safeQuestion,
    baby.band,
  );
  const system = meal ? mealSystemPrompt(baby, refs, meal) : chatSystemPrompt(baby, refs);

  let parsed: Record<string, unknown>;
  try {
    const raw = await generate(settings, system, [
      ...history,
      { role: "user", content: safeQuestion },
    ]);
    parsed = parseJson(raw);
  } catch (e) {
    console.error("ai ask failed", e);
    const code = e instanceof AiError ? e.code : "failed";
    return json({ status: code === "busy" ? "busy" : "error", conversation_id: conversationId });
  }

  const payload = normalizeAnswer(parsed, refs, meal ? mealSafetyNotes(baby.bandIndex, meal) : []);
  await insertMessage(admin, conversationId, userId, "user", "normal", question, null);
  const message = await insertMessage(
    admin, conversationId, userId, "assistant", "normal", payload.summary, payload,
  );
  await touchConversation(admin, conversationId);
  return json({ status: "ok", conversation_id: conversationId, message });
}

function chatSystemPrompt(baby: Baby, refs: Reference[]) {
  const refsText = refs.length
    ? refs.map((r, i) => `[${i + 1}] ${r.title} — المصدر: ${r.source_name}\n${r.content}`).join("\n\n")
    : "لا توجد مراجع مطابقة لهذا السؤال في مكتبة بيانور.";

  return `أنتِ «مساعدة بيانور»، مساعدة تربوية لأمهات الأطفال من الولادة حتى عمر سنتين داخل تطبيق بيانور.

بيانات الطفل:
${baby.profileText}

مراجع بيانور العلمية (مأخوذة من WHO وAAP وCDC وNHS ومصادر معتمدة):
${refsText}

قواعد إلزامية:
1. ردي بنفس لغة الأم ولهجتها (يمنية، مصرية، خليجية، شامية، فصحى، إنجليزية...). لو اللهجة غير واضحة استخدمي عربية فصحى بسيطة.
2. اعتمدي على مراجع بيانور المرفقة فقط. أي معلومة مهمة لازم تكون من مرجع، واكتبي أرقام المراجع اللي استخدمتيها في "refs".
3. لو المراجع لا تغطي السؤال: وضّحي ذلك بلطف، وقدمي توجيهاً عاماً آمناً ومتفقاً عليه فقط، بدون أرقام أو تفاصيل غير مؤكدة، واجعلي "grounded": false، وانصحي باستشارة أخصائية بيانور أو طبيب الأطفال.
4. ممنوع التشخيص. ممنوع ذكر أي دواء أو جرعة أو مكمل غذائي. ممنوع تأليف دراسات أو أرقام أو روابط أو مصادر.
5. لو في السؤال أي علامة خطر، اكتبي بوضوح أن الطفل يحتاج طبيباً فوراً.
6. النبرة: هادئة، مطمئنة، مختصرة، بدون لوم للأم.
7. عند الإشارة للطفل استخدمي {{baby}} بدلاً من اسمه.
8. لو السؤال خارج رعاية الطفل والأمومة والتربية، اعتذري بلطف ووجّهيها لما تقدري تساعدي فيه.

أرجعي JSON فقط بهذا الشكل:
{
  "summary": "خلاصة مطمئنة في جملتين أو ثلاث",
  "activity": { "title": "نشاط عملي مناسب لعمر الطفل اليوم", "steps": ["خطوة", "خطوة", "خطوة"] } أو null لو غير مناسب,
  "see_doctor_when": "متى تستشير الطبيب بخصوص هذا الموضوع (جملة أو جملتين)",
  "followups": ["سؤال متابعة قصير", "سؤال متابعة قصير"],
  "refs": [1, 2],
  "grounded": true
}`;
}

type Meal = { ingredients: string; allergies: string[] };

function readMeal(raw: unknown): Meal {
  const m = (raw ?? {}) as Record<string, unknown>;
  return {
    ingredients: String(m.ingredients ?? "").trim().slice(0, 300),
    allergies: (Array.isArray(m.allergies) ? m.allergies : [])
      .map((a) => String(a).trim().slice(0, 40))
      .filter(Boolean)
      .slice(0, 10),
  };
}

function mealSystemPrompt(baby: Baby, refs: Reference[], meal: Meal) {
  const refsText = refs.length
    ? refs.map((r, i) => `[${i + 1}] ${r.title} — المصدر: ${r.source_name}\n${r.content}`).join("\n\n")
    : "لا توجد مراجع مطابقة.";
  const underOne = baby.bandIndex <= 2;

  return `أنتِ «مساعدة بيانور». الأم عايزة وجبة النهارده لطفلها.

بيانات الطفل:
${baby.profileText}

الموجود عند الأم: ${meal.ingredients || "لم تحدد — اقترحي من مكونات بسيطة متوفرة في أي بيت"}
حساسية أو أكلات ممنوعة عند الطفل: ${meal.allergies.length ? meal.allergies.join("، ") : "لا يوجد"}

مراجع بيانور العلمية:
${refsText}

قواعد إلزامية:
1. ردي بنفس لغة الأم ولهجتها.
2. وجبة واحدة آمنة ومناسبة لعمر الطفل بالظبط، من الموجود عند الأم قدر الإمكان، والقوام مناسب للعمر.
3. ممنوع نهائياً أي مكون من قائمة الحساسية أو مشتقاته.
${baby.bandIndex === 0 ? "4. الطفل أقل من 3 شهور: لا تقترحي أي أكل. وضحي أن الرضاعة الطبيعية أو الصناعية كافية حتى حوالي 6 شهور، واجعلي activity = null." : ""}${baby.bandIndex === 1 ? "4. الطفل بين 3 و6 شهور: وضحي أن الأكل الصلب يبدأ عند حوالي 6 شهور مع علامات الاستعداد، ولو لسه أقل من 6 شهور فالرضاعة كافية. لو قدمتي وجبة تكون أول تذوق ناعم جداً بكمية صغيرة." : ""}
${underOne ? "5. أقل من سنة: ممنوع العسل، ممنوع إضافة ملح أو سكر، لبن البقر ليس مشروباً أساسياً." : "5. قللي الملح والسكر."}
6. ممنوع المكسرات الكاملة والعنب الكامل والأكل الصغير الصلب؛ أي حاجة ممكن تسبب اختناق لازم تتطحن أو تتقطع مناسب.
7. الكمية بمقاييس البيت (معالق صغيرة/كبيرة) ومناسبة للعمر حسب المراجع، وقولي إن الطفل هو اللي يحدد الشبع.
8. ممنوع أي دواء أو مكمل أو تشخيص. عند الإشارة للطفل استخدمي {{baby}}.

أرجعي JSON فقط:
{
  "summary": "اسم الوجبة + الكمية المناسبة لعمره في جملتين",
  "activity": { "title": "اسم الوجبة", "steps": ["خطوات التحضير", "...", "آخر خطوة: إزاي تحفظيها ولحد إمتى"] } أو null,
  "see_doctor_when": "علامات الحساسية اللي تستدعي الطبيب لو الأكلة جديدة",
  "followups": ["سؤال متابعة قصير", "سؤال متابعة قصير"],
  "refs": [1],
  "grounded": true
}`;
}

/** Fixed safety lines shown with every meal — never left to the model. */
function mealSafetyNotes(bandIndex: number, meal: Meal) {
  const notes: string[] = [];
  if (bandIndex <= 1) notes.push("الأكل الصلب بيبدأ عند حوالي 6 شهور مع علامات الاستعداد (يقعد بسند ويثبت راسه).");
  if (bandIndex <= 2) notes.push("قبل سنة: ممنوع العسل، ومن غير ملح أو سكر.");
  notes.push("أي أكلة جديدة قدميها لوحدها وبكمية صغيرة، وراقبي أي طفح أو ترجيع أو تورم.");
  notes.push("الأكل يتقطع صغير أو يتهرس، والطفل ياكل وهو قاعد وتحت عينك.");
  if (meal.allergies.length) notes.push(`اتأكدي إن الوجبة مافيهاش: ${meal.allergies.join("، ")}.`);
  return notes;
}

function normalizeAnswer(parsed: Record<string, unknown>, refs: Reference[], notes: string[] = []) {
  const activityRaw = parsed.activity as Record<string, unknown> | null | undefined;
  const steps = Array.isArray(activityRaw?.steps)
    ? (activityRaw!.steps as unknown[]).map(String).filter(Boolean).slice(0, 6)
    : [];
  const refNumbers = Array.isArray(parsed.refs) ? (parsed.refs as unknown[]).map(Number) : [];
  const used = [...new Set(refNumbers)]
    .filter((n) => Number.isInteger(n) && n >= 1 && n <= refs.length)
    .map((n) => refs[n - 1]);

  return {
    summary: String(parsed.summary ?? "").trim() || "معلش، ما قدرتش أجهز رد واضح. جربي تسألي بطريقة تانية.",
    activity: activityRaw && activityRaw.title && steps.length
      ? { title: String(activityRaw.title), steps }
      : null,
    see_doctor_when: String(parsed.see_doctor_when ?? "").trim(),
    followups: Array.isArray(parsed.followups)
      ? (parsed.followups as unknown[]).map(String).filter(Boolean).slice(0, 3)
      : [],
    sources: used.map((r) => ({ title: r.source_name, url: r.source_url })),
    grounded: used.length > 0 && parsed.grounded !== false,
    ...(notes.length ? { notes } : {}),
  };
}

// ---------------------------------------------------------------------------
// Daily plan
// ---------------------------------------------------------------------------

async function handleDailyPlan(
  admin: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  settings: Settings,
) {
  const date = String(body.date ?? "");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return json({ error: "bad_request" }, 400);
  const diffDays = Math.abs(Date.parse(`${date}T00:00:00Z`) - Date.now()) / 86_400_000;
  if (!Number.isFinite(diffDays) || diffDays > 2) return json({ error: "bad_request" }, 400);

  const { data: existing } = await admin
    .from("ai_daily_plans")
    .select("plan_date, content")
    .eq("user_id", userId)
    .eq("plan_date", date)
    .maybeSingle();
  if (existing) return json({ status: "ok", plan: existing.content, date });

  const quota = await consume(admin, userId, "plan", settings);
  if (quota !== "ok") return json({ status: quota });

  const baby = await loadBaby(admin, userId, body.age_range_index);
  const { data: refRows } = await admin
    .from("ai_knowledge")
    .select("id, title, content, source_name, source_url")
    .eq("publish_status", "published")
    .overlaps("age_bands", [baby.band, "all"])
    .in("category", ["motor", "language", "social", "play", "sleep", "feeding"])
    .limit(8);
  const refs = (refRows ?? []) as Reference[];

  const { data: lastPlan } = await admin
    .from("ai_daily_plans")
    .select("content")
    .eq("user_id", userId)
    .order("plan_date", { ascending: false })
    .limit(1)
    .maybeSingle();
  const lastTitles = ((lastPlan?.content?.activities ?? []) as { title?: string }[])
    .map((a) => a.title)
    .filter(Boolean)
    .join("، ");

  const english = String(body.lang ?? "ar").startsWith("en");
  const system = `أنتِ «مساعدة بيانور». جهّزي خطة يوم قصيرة لأم طفل عمره ${AGE_LABELS[baby.bandIndex]}.

بيانات الطفل:
${baby.profileText}

مراجع بيانور العلمية:
${refs.map((r, i) => `[${i + 1}] ${r.title} — ${r.source_name}\n${r.content}`).join("\n\n") || "لا توجد مراجع."}

القواعد:
- اكتبي ${english ? "بالإنجليزية البسيطة" : "بعربية فصحى بسيطة قريبة من الأمهات"}.
- 3 أنشطة مختلفة ومناسبة للعمر بالظبط، مبنية على المراجع، آمنة، بأدوات موجودة في أي بيت، ومن غير شاشات.
${lastTitles ? `- لا تكرري أنشطة أمس: ${lastTitles}.` : ""}
- نصيحة اليوم مأخوذة من المراجع.
- "quran_moment": اقتراح لطيف قصير لسماع القرآن أو ذكر مع الطفل (مثلاً سماع سورة قصيرة بصوت هادئ)، بدون فتاوى.
- ممنوع أي دواء أو تشخيص. عند الإشارة للطفل استخدمي {{baby}}.

أرجعي JSON فقط:
{
  "tip": "نصيحة اليوم في جملتين",
  "activities": [ { "title": "اسم النشاط", "minutes": 5, "why": "فايدته في جملة", "steps": ["خطوة", "خطوة"] } ],
  "quran_moment": "جملة واحدة",
  "refs": [1, 2]
}`;

  let parsed: Record<string, unknown>;
  try {
    parsed = parseJson(await generate(settings, system, [{ role: "user", content: `خطة يوم ${date}` }]));
  } catch (e) {
    console.error("ai plan failed", e);
    const code = e instanceof AiError ? e.code : "failed";
    return json({ status: code === "busy" ? "busy" : "error" });
  }

  const refNumbers = Array.isArray(parsed.refs) ? (parsed.refs as unknown[]).map(Number) : [];
  const sources = [...new Set(refNumbers)]
    .filter((n) => Number.isInteger(n) && n >= 1 && n <= refs.length)
    .map((n) => ({ title: refs[n - 1].source_name, url: refs[n - 1].source_url }));
  const plan = {
    tip: String(parsed.tip ?? "").trim(),
    activities: (Array.isArray(parsed.activities) ? parsed.activities : [])
      .slice(0, 4)
      .map((a: Record<string, unknown>) => ({
        title: String(a.title ?? ""),
        minutes: Math.max(1, Math.min(60, Number(a.minutes) || 5)),
        why: String(a.why ?? ""),
        steps: Array.isArray(a.steps) ? (a.steps as unknown[]).map(String).slice(0, 6) : [],
      }))
      .filter((a: { title: string }) => a.title),
    quran_moment: String(parsed.quran_moment ?? "").trim(),
    sources: sources.filter((s, i, all) => all.findIndex((x) => x.title === s.title) === i),
  };

  await admin.from("ai_daily_plans").upsert(
    { user_id: userId, child_id: baby.childId, plan_date: date, content: plan },
    { onConflict: "user_id,plan_date" },
  );
  return json({ status: "ok", plan, date });
}

// ---------------------------------------------------------------------------
// References library (staff)
// ---------------------------------------------------------------------------

async function handleEmbedKnowledge(admin: SupabaseClient, userId: string) {
  const { data: profile } = await admin.from("profiles").select("role").eq("id", userId).maybeSingle();
  if (!["admin", "editor"].includes(profile?.role ?? "")) return json({ error: "forbidden" }, 403);
  if (!Deno.env.get("GEMINI_API_KEY")) return json({ status: "not_configured" });

  const { data: rows } = await admin
    .from("ai_knowledge")
    .select("id, title, content")
    .is("embedding", null)
    .limit(40);

  let done = 0;
  for (const row of rows ?? []) {
    try {
      const values = await embed(`${row.title}\n${row.content}`, "RETRIEVAL_DOCUMENT");
      if (!values) continue;
      await admin.from("ai_knowledge").update({ embedding: toVector(values) }).eq("id", row.id);
      done++;
    } catch (e) {
      console.error("embed failed", e);
      break;
    }
  }

  const { count } = await admin
    .from("ai_knowledge")
    .select("id", { count: "exact", head: true })
    .is("embedding", null);
  return json({ status: "ok", done, remaining: count ?? 0 });
}

async function findReferences(admin: SupabaseClient, question: string, band: string): Promise<Reference[]> {
  try {
    const values = await embed(question, "RETRIEVAL_QUERY");
    if (!values) return [];
    const { data, error } = await admin.rpc("match_ai_knowledge", {
      p_embedding: toVector(values),
      p_band: band,
      p_count: 4,
    });
    if (error) {
      console.error("match_ai_knowledge", error);
      return [];
    }
    return (data ?? []) as Reference[];
  } catch (e) {
    console.error("findReferences", e);
    return [];
  }
}

async function embed(text: string, taskType: "RETRIEVAL_DOCUMENT" | "RETRIEVAL_QUERY") {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return null;
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${EMBED_MODEL}:embedContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        content: { parts: [{ text }] },
        taskType,
        outputDimensionality: EMBED_DIMS,
      }),
    },
  );
  if (res.status === 429) throw new AiError("busy");
  if (!res.ok) {
    console.error("embed http", res.status, await res.text());
    return null;
  }
  const data = await res.json();
  const values = data?.embedding?.values as number[] | undefined;
  return values?.length === EMBED_DIMS ? values : null;
}

function toVector(values: number[]) {
  return `[${values.join(",")}]`;
}

// ---------------------------------------------------------------------------
// AI providers
// ---------------------------------------------------------------------------

async function generate(settings: Settings, system: string, messages: ChatMsg[]) {
  return settings.provider === "claude"
    ? await callClaude(settings.model, system, messages)
    : await callGemini(settings.model, system, messages);
}

async function callGemini(model: string, system: string, messages: ChatMsg[]) {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new AiError("not_configured");

  const generationConfig: Record<string, unknown> = {
    temperature: 0.5,
    maxOutputTokens: 1500,
    responseMimeType: "application/json",
  };
  if (model.includes("flash")) generationConfig.thinkingConfig = { thinkingBudget: 0 };

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: messages.map((m) => ({
          role: m.role === "assistant" ? "model" : "user",
          parts: [{ text: m.content }],
        })),
        generationConfig,
      }),
    },
  );
  if (res.status === 429) throw new AiError("busy");
  if (!res.ok) throw new AiError("failed", `gemini ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = (data?.candidates?.[0]?.content?.parts ?? [])
    .map((p: { text?: string }) => p.text ?? "")
    .join("");
  if (!text) throw new AiError("failed", "gemini empty response");
  return text;
}

async function callClaude(model: string, system: string, messages: ChatMsg[]) {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) throw new AiError("not_configured");
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": key,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model,
      max_tokens: 1500,
      temperature: 0.5,
      system: `${system}\n\nأرجعي JSON صالح فقط بدون أي نص قبله أو بعده.`,
      messages,
    }),
  });
  if (res.status === 429 || res.status === 529) throw new AiError("busy");
  if (!res.ok) throw new AiError("failed", `claude ${res.status}: ${await res.text()}`);
  const data = await res.json();
  return (data?.content ?? []).map((p: { text?: string }) => p.text ?? "").join("");
}

function parseJson(raw: string): Record<string, unknown> {
  const cleaned = raw.replace(/```(?:json)?/gi, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start < 0 || end <= start) throw new AiError("failed", "no json in response");
  return JSON.parse(cleaned.slice(start, end + 1));
}

// ---------------------------------------------------------------------------
// Emergency filter (runs before any AI call)
// ---------------------------------------------------------------------------

const EMERGENCY = {
  title: "ده موقف طارئ",
  message: "اللي بتوصفيه ممكن يكون خطير على الطفل ويحتاج طبيب فوراً. من فضلك لا تنتظري رد التطبيق.",
  steps: [
    "اتصلي بالإسعاف أو اذهبي لأقرب طوارئ الآن.",
    "خليكي جنب الطفل وراقبي تنفسه ولونه.",
    "لا تعطي الطفل أي دواء أو أكل أو شرب إلا بتوجيه الطبيب.",
  ],
};

const EMERGENCY_TERMS = [
  "تشنج", "صرع", "اختناق", "يختنق", "بيختنق", "مخنوق", "اتخنق", "انخنق", "شرقان",
  "مش بيتنفس", "ما يتنفس", "مايتنفس", "لا يتنفس", "مش قادر يتنفس", "ما يقدر يتنفس",
  "صعوبه في التنفس", "صعوبه تنفس", "ضيق تنفس", "ضيق في التنفس", "توقف التنفس", "وقف نفسه",
  "لونه ازرق", "شفايفه زرقا", "شفايفه ازرق", "شفتاه زرقاء", "زرقان", "ازرقاق",
  "بلع حاجه", "بلع جسم", "بلع حجر", "بلع بطاريه", "بلع حجاره", "بلع عمله", "بلع فلوس", "بلع زرار",
  "بلع مغناطيس", "بلع دوا كتير", "شرب دوا كتير", "بلع حبوب", "ابتلع", "بلعت حاجه", "انبلع",
  "نزيف", "ينزف", "بينزف", "نزف",
  "تسمم", "مسموم", "شرب كلور", "شرب منظف", "شرب ديتول", "شرب كاز", "شرب جاز", "شرب بنزين", "شرب علبه دوا",
  "فقد الوعي", "فاقد الوعي", "اغمي", "اغماء", "مغمي", "مش بيصحي", "ما يصحي", "مايصحي", "لا يستجيب", "مش بيستجيب",
  "وقع علي راسه", "وقع من السرير", "وقع من الكنبه", "وقع من فوق", "وقع من علي", "وقع من السلم", "سقط من",
  "سقط علي راسه", "خبط راسه", "انخبط في راسه",
  "اتحرق", "انحرق", "محروق", "اتكهرب", "صعق", "كهربا مسكته", "غرق في", "غرقان", "كان هيغرق",
  "حراره عاليه جدا", "سخونيه عاليه جدا", "حمي شديده", "رقبته متيبسه", "طفح ما بيختفيش",
  "choking", "seizure", "not breathing", "unconscious", "poison", "swallowed",
];

function normalizeAr(text: string) {
  return text
    .toLowerCase()
    .replace(/[\u064B-\u0652\u0640]/g, "")
    .replace(/[إأآ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/[٠-٩]/g, (d) => String("٠١٢٣٤٥٦٧٨٩".indexOf(d)))
    .replace(/\s+/g, " ");
}

function detectEmergency(question: string, bandIndex: number) {
  const text = normalizeAr(question);
  if (EMERGENCY_TERMS.some((t) => text.includes(normalizeAr(t)))) return true;

  const fever = text.match(/(حراره|حرارته|سخونيه|سخونه|سخن|حمي|درجه)[^\d]{0,20}(\d{2}(?:[.,]\d)?)/);
  if (fever) {
    const temp = Number(fever[2].replace(",", "."));
    if (temp >= 39 && temp <= 43) return true;
    if (bandIndex === 0 && temp >= 38 && temp <= 43) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

async function loadSettings(admin: SupabaseClient): Promise<Settings> {
  const { data } = await admin
    .from("app_settings")
    .select("key, value")
    .in("key", ["ai_enabled", "ai_provider", "ai_model", "ai_daily_limit", "ai_global_daily_limit"]);
  const map = Object.fromEntries((data ?? []).map((r: { key: string; value: string }) => [r.key, r.value]));
  const provider = map.ai_provider === "claude" ? "claude" : "gemini";
  return {
    enabled: (map.ai_enabled ?? "true") !== "false",
    provider,
    model: (map.ai_model ?? "").trim() || (provider === "claude" ? "claude-haiku-4-5" : "gemini-2.5-flash"),
    dailyLimit: Math.max(1, Number(map.ai_daily_limit) || 20),
    globalLimit: Math.max(1, Number(map.ai_global_daily_limit) || 200),
  };
}

async function consume(admin: SupabaseClient, userId: string, kind: "message" | "plan", s: Settings) {
  const { data, error } = await admin.rpc("ai_consume", {
    p_user: userId,
    p_kind: kind,
    p_limit: s.dailyLimit,
    p_global_limit: s.globalLimit,
  });
  if (error) {
    console.error("ai_consume", error);
    return "error";
  }
  return data as "ok" | "limit" | "busy";
}

const NUTRITION: Record<string, string> = {
  breastfeeding: "رضاعة طبيعية",
  formula: "لبن صناعي",
  balanced: "أكل متوازن",
  irregular: "أكل غير منتظم",
};
const SLEEP_ISSUES: Record<string, string> = {
  intermittent: "نوم متقطع",
  continuousCrying: "عياط مستمر",
};

async function loadBaby(admin: SupabaseClient, userId: string, fallbackIndex: unknown): Promise<Baby> {
  const { data: child } = await admin
    .from("children")
    .select("id, name, gender, age_range_index")
    .eq("user_id", userId)
    .eq("is_active", true)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  let answersQuery = admin.from("onboarding_answers").select("answers").eq("user_id", userId);
  if (child?.id) answersQuery = answersQuery.eq("child_id", child.id);
  const { data: onboarding } = await answersQuery
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  const a = (onboarding?.answers ?? {}) as Record<string, unknown>;

  const rawIndex = child?.age_range_index ?? a.age_range_index ?? fallbackIndex;
  const bandIndex = Math.min(4, Math.max(0, Number(rawIndex) || 0));
  const name = String(child?.name ?? a.name ?? "").trim();
  const gender = child?.gender ?? a.gender;

  const list = (v: unknown) => (Array.isArray(v) ? v.map(String).filter(Boolean).join("، ") : "");
  const lines = [
    `- العمر: ${AGE_LABELS[bandIndex]}`,
    gender ? `- النوع: ${gender === "male" ? "ولد" : "بنت"}` : "",
    a.nutrition ? `- التغذية: ${NUTRITION[String(a.nutrition)] ?? a.nutrition}` : "",
    a.sleep_pattern ? `- النوم: ${a.sleep_pattern === "regular" ? "منتظم" : "غير منتظم"}` : "",
    list(a.sleep_issues) ? `- مشاكل النوم: ${(a.sleep_issues as string[]).map((s) => SLEEP_ISSUES[s] ?? s).join("، ")}` : "",
    list(a.strengths) ? `- نقاط القوة: ${list(a.strengths)}` : "",
    list(a.challenges) ? `- التحديات: ${list(a.challenges)}` : "",
    a.has_special_needs === true ? `- احتياجات خاصة: ${String(a.special_needs_details ?? "نعم").slice(0, 200)}` : "",
    a.has_physical_activity === false ? "- النشاط الحركي: قليل" : "",
    a.behavior_notes ? `- ملاحظات الأم: ${String(a.behavior_notes).slice(0, 300)}` : "",
  ].filter(Boolean);

  return {
    childId: child?.id ?? null,
    band: AGE_BANDS[bandIndex],
    bandIndex,
    name,
    profileText: hideName(lines.join("\n"), name),
  };
}

/** The baby's real name never reaches the AI provider. */
function hideName(text: string, name: string) {
  if (!name || name.length < 2) return text;
  return text.split(name).join("{{baby}}");
}

async function ensureConversation(
  admin: SupabaseClient,
  userId: string,
  conversationId: unknown,
  childId: string | null,
  question: string,
) {
  if (typeof conversationId === "string" && conversationId) {
    const { data } = await admin
      .from("ai_conversations")
      .select("id")
      .eq("id", conversationId)
      .eq("user_id", userId)
      .maybeSingle();
    if (data) return data.id as string;
  }
  const { data, error } = await admin
    .from("ai_conversations")
    .insert({ user_id: userId, child_id: childId, title: question.slice(0, 60) })
    .select("id")
    .single();
  if (error) throw error;
  return data.id as string;
}

async function loadHistory(admin: SupabaseClient, conversationId: string): Promise<ChatMsg[]> {
  const { data } = await admin
    .from("ai_messages")
    .select("role, kind, content, payload")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(HISTORY_LIMIT);
  const rows = (data ?? []).reverse().filter((m: { kind: string }) => m.kind === "normal");
  const history: ChatMsg[] = rows.map((m: { role: Role; content: string; payload: Record<string, unknown> | null }) => ({
    role: m.role,
    content: m.role === "assistant" && m.payload ? JSON.stringify(m.payload) : m.content,
  }));
  while (history.length && history[0].role !== "user") history.shift();
  return history;
}

async function insertMessage(
  admin: SupabaseClient,
  conversationId: string,
  userId: string,
  role: Role,
  kind: "normal" | "emergency",
  content: string,
  payload: unknown,
) {
  const { data, error } = await admin
    .from("ai_messages")
    .insert({ conversation_id: conversationId, user_id: userId, role, kind, content, payload })
    .select("id, role, kind, content, payload, created_at")
    .single();
  if (error) throw error;
  return data;
}

async function touchConversation(admin: SupabaseClient, conversationId: string) {
  await admin.from("ai_conversations").update({ updated_at: new Date().toISOString() }).eq("id", conversationId);
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
