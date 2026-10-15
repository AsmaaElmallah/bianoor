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
// Used when the saved model is retired by Google (404), so mothers aren't locked out.
const DEFAULT_GEMINI_MODEL = "gemini-3.8-flash";
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
  webSearch: boolean;
};
type Source = { title: string; url: string | null };
type StreamPart = { text?: string; sources?: Source[] };
type Reference = { id: string; title: string; content: string; source_name: string; source_url: string | null };
type Baby = { childId: string | null; band: string; bandIndex: number; name: string; profileText: string };

class AiError extends Error {
  constructor(public code: "busy" | "not_configured" | "failed", detail?: string) {
    super(detail ?? code);
  }
}

/** Status + a short reason (no secrets) so the app/dashboard can show what went wrong. */
function failure(e: unknown) {
  const code = e instanceof AiError ? e.code : "failed";
  const status = code === "busy" ? "busy" : code === "not_configured" ? "not_configured" : "error";
  const detail = (e instanceof Error ? e.message : String(e)).slice(0, 300);
  return { status, detail };
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
      case "health":
        return await handleHealth(admin, user.id, settings);
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
    return json(failure(e));
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
  const safeQuestion = hideName(question, baby.name);
  // Emergency words no longer block the answer: the app shows the red steps first, then the answer streams.
  const emergency = detectEmergency(question, baby.bandIndex);

  const [conversationId, quota] = await Promise.all([
    ensureConversation(admin, userId, body.conversation_id, baby.childId, question),
    consume(admin, userId, "message", settings),
  ]);
  if (quota !== "ok") return json({ status: quota, conversation_id: conversationId });

  const [history, refs] = await Promise.all([
    loadHistory(admin, conversationId),
    findReferences(admin, meal ? `أكل طفل ${AGE_LABELS[baby.bandIndex]}: ${meal.ingredients}` : safeQuestion, baby.band),
  ]);
  const system = meal ? mealSystemPrompt(baby, refs, meal) : chatSystemPrompt(baby, refs, emergency);
  const messages: ChatMsg[] = [...history, { role: "user", content: safeQuestion }];
  const notes = meal ? mealSafetyNotes(baby.bandIndex, meal) : [];

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (event: Record<string, unknown>) =>
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(event)}\n\n`));

      send({ t: "meta", conversation_id: conversationId, emergency: emergency ? EMERGENCY : null });
      let text = "";
      let emitted = 0;
      let webSources: Source[] = [];
      // Hold back a few characters so the trailing «@@followups» block never flashes on screen.
      const flush = (final: boolean) => {
        const cut = text.indexOf(TAIL_MARK);
        const end = cut >= 0 ? cut : final ? text.length : Math.max(emitted, text.length - TAIL_MARK.length);
        if (end > emitted) {
          send({ t: "delta", text: text.slice(emitted, end) });
          emitted = end;
        }
      };

      try {
        for await (const part of streamAnswer(settings, system, messages, !meal)) {
          if (part.sources) webSources = part.sources;
          if (part.text) {
            text += part.text;
            flush(false);
          }
        }
        flush(true);
        const answer = splitAnswer(text, refs, webSources);
        if (!answer.body) throw new AiError("failed", "empty answer");

        const payload = {
          format: "md",
          followups: answer.followups,
          sources: answer.sources,
          ...(emergency ? { emergency: EMERGENCY } : {}),
          ...(notes.length ? { notes } : {}),
        };
        await insertMessage(admin, conversationId, userId, "user", "normal", question, null);
        const message = await insertMessage(admin, conversationId, userId, "assistant", "normal", answer.body, payload);
        await touchConversation(admin, conversationId);
        send({ t: "done", status: "ok", conversation_id: conversationId, message });
      } catch (e) {
        console.error("ai ask failed", e);
        await refund(admin, userId, "message");
        send({ t: "error", ...failure(e), conversation_id: conversationId });
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: { ...cors, "Content-Type": "text/event-stream; charset=utf-8", "Cache-Control": "no-cache" },
  });
}

const TAIL_MARK = "@@followups";

/** Splits the streamed markdown into the visible answer, follow-up chips and sources. */
function splitAnswer(raw: string, refs: Reference[], webSources: Source[]) {
  const cut = raw.indexOf(TAIL_MARK);
  const body = (cut >= 0 ? raw.slice(0, cut) : raw).trim();
  const tail = cut >= 0 ? raw.slice(cut + TAIL_MARK.length) : "";

  const followups: string[] = [];
  let refNumbers: number[] = [];
  for (const line of tail.split("\n")) {
    const l = line.trim();
    if (l.startsWith("@@refs")) {
      refNumbers = (l.slice(6).match(/\d+/g) ?? []).map(Number);
    } else if (/^[-*•]\s*/.test(l)) {
      const q = l.replace(/^[-*•]\s*/, "").trim();
      if (q.length > 2) followups.push(q.slice(0, 120));
    }
  }

  const library = [...new Set(refNumbers)]
    .filter((n) => Number.isInteger(n) && n >= 1 && n <= refs.length)
    .map((n) => ({ title: refs[n - 1].source_name, url: refs[n - 1].source_url }));
  const seen = new Set<string>();
  const sources = [...library, ...webSources].filter((s) => {
    const key = s.url ?? s.title;
    if (!s.title || seen.has(key)) return false;
    seen.add(key);
    return true;
  }).slice(0, 6);

  return { body, followups: followups.slice(0, 3), sources };
}

function referencesBlock(refs: Reference[]) {
  return refs.length
    ? refs.map((r, i) => `[${i + 1}] ${r.title} — المصدر: ${r.source_name}\n${r.content}`).join("\n\n")
    : "(مفيش مرجع مطابق في المكتبة للسؤال ده — اعتمدي على معرفتك الموثوقة ونتايج البحث)";
}

const ANSWER_TAIL = `في آخر الرد بالظبط، بعد سطر فاضي، اكتبي الجزء ده (التطبيق بيخفيه ويحوّله لأزرار):
${TAIL_MARK}
- سؤال متابعة قصير ممكن الأم تسأله بعد كده (بلهجتها)
- سؤال متابعة تاني
- سؤال متابعة تالت
@@refs أرقام مراجع مكتبة بيانور اللي استخدمتيها مفصولة بفاصلة، أو سيبيها فاضية`;

function chatSystemPrompt(baby: Baby, refs: Reference[], emergency: boolean) {
  return `أنتِ «بيانور»: رفيقة ذكية ودافية جوه تطبيق بيانور، بتساعد الأمهات في كل حاجة — زي ChatGPT بالظبط في الذكاء والتفصيل، بس قلبك مع الأم وخبرتك الأساسية في الأطفال من الولادة لحد سنتين.

عن طفل الأم:
${baby.profileText}

مكتبة بيانور (مراجع من WHO وAAP وCDC وNHS — استخدميها لما تفيد):
${referencesBlock(refs)}

إزاي تردي:
- اتكلمي بنفس لهجة الأم بالظبط: لو كتبت مصري ردي مصري، يمني ردي يمني، خليجي/شامي/مغربي نفس الشيء، فصحى ردي فصحى، إنجليزي ردي إنجليزي.
- جاوبي على السؤال نفسه من أول سطر، وبعدين التفاصيل اللي تفرق معاها. طول الرد على قد السؤال: سؤال بسيط = سطرين تلاتة، سؤال كبير = رد مفصّل ومنظم.
- نظّمي الرد بـ Markdown بسيط: **تقيل** للمعلومة المهمة، نقط بـ "- "، خطوات مرقمة "1. "، وعنوان صغير "### " بس لو الرد طويل. ممنوع الجداول والروابط.
- خليكي إنسانة: لو الأم قلقانة أو تعبانة طمّنيها بجملة صادقة من غير مبالغة ومن غير لوم. إيموجي واحد أو اتنين بالكتير لو مناسب.
- خصّصي الرد على عمر الطفل وبياناته. ولو ناقصك معلومة مهمة جاوبي باللي تقدري عليه وفي الآخر اسأليها سؤال توضيحي واحد.
- جاوبي على أي سؤال تسأله: الطفل، الحمل والولادة، الرضاعة، صحة الأم ونفسيتها، العلاقة مع الزوج والأهل، البيت والأكل، وحتى الأسئلة العامة. ما ترفضيش سؤال إلا لو مؤذي.
- المعلومة الطبية لازم تكون من مصادر موثوقة (مكتبة بيانور، WHO، AAP، CDC، NHS، Mayo Clinic، UNICEF). ممنوع تأليف أرقام أو دراسات أو أسماء مصادر.

الأمان (مهم جداً):
- ممنوع تحديد جرعة أي دواء أو وصف دواء بالاسم كعلاج للطفل؛ قولي إن الجرعة بيحددها الدكتور أو الصيدلي حسب الوزن.
- ممنوع التشخيص الأكيد؛ اشرحي الأسباب الشائعة المحتملة، وقولي بوضوح وبالتقيل علامات الخطر اللي تستدعي الدكتور أو الطوارئ.
- لما تتكلمي عن الطفل استخدمي {{baby}} مكان اسمه.
${emergency ? "\nتنبيه: كلام الأم فيه علامة طوارئ محتملة، والتطبيق بيعرض لها خطوات الطوارئ فوق ردك. لو بتوصف حالة بتحصل دلوقتي: أول سطر في ردك يكون توجيه واضح إنها تروح الطوارئ أو تكلم الإسعاف حالاً، وبعدين اللي تعمله لحد ما توصل. لو سؤالها وقائي أو عام جاوبي عادي.\n" : ""}
${ANSWER_TAIL}`;
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
  const refsText = referencesBlock(refs);
  const underOne = baby.bandIndex <= 2;

  return `أنتِ «بيانور»، رفيقة الأم الدافية. الأم عايزة وجبة النهارده لطفلها.

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

شكل الرد (Markdown بسيط، ممنوع الجداول):
- أول سطر: اسم الوجبة بالتقيل + جملة دافية ليه هي مناسبة لعمره.
- ### المكونات (نقط، بالكميات بمقاييس البيت)
- ### طريقة التحضير (خطوات مرقمة، وآخر خطوة إزاي تحفظيها ولحد إمتى)
- ### الكمية المناسبة لعمره
- سطر أخير عن علامات الحساسية اللي تستدعي الدكتور لو الأكلة جديدة.

${ANSWER_TAIL}`;
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
    await refund(admin, userId, "plan");
    return json(failure(e));
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
  let lastError: ReturnType<typeof failure> | null = null;
  for (const row of rows ?? []) {
    try {
      const values = await embed(`${row.title}\n${row.content}`, "RETRIEVAL_DOCUMENT");
      if (!values) continue;
      await admin.from("ai_knowledge").update({ embedding: toVector(values) }).eq("id", row.id);
      done++;
    } catch (e) {
      console.error("embed failed", e);
      lastError = failure(e);
      break;
    }
  }

  const { count } = await admin
    .from("ai_knowledge")
    .select("id", { count: "exact", head: true })
    .is("embedding", null);
  if (done === 0 && lastError) return json({ ...lastError, done, remaining: count ?? 0 });
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
  if (res.status === 429) throw new AiError("busy", "gemini embed 429: quota/rate limit");
  if (!res.ok) throw new AiError("failed", `gemini embed ${res.status}: ${await googleErrorMessage(res)}`);
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

async function callGemini(model: string, system: string, messages: ChatMsg[]): Promise<string> {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new AiError("not_configured");

  // Arabic JSON is token-heavy, and thinking tokens share the same budget.
  const generationConfig: Record<string, unknown> = {
    temperature: 0.5,
    maxOutputTokens: 8192,
    responseMimeType: "application/json",
  };
  // Gemini 2.x takes a token budget; 3.x+ takes a level and rejects budget 0.
  if (/^gemini-2\.5-flash/.test(model)) generationConfig.thinkingConfig = { thinkingBudget: 0 };
  else if (/^gemini-[3-9]/.test(model)) generationConfig.thinkingConfig = { thinkingLevel: "low" };

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
  if (res.status === 429) throw new AiError("busy", "gemini 429: quota/rate limit");
  if (res.status === 404 && model !== DEFAULT_GEMINI_MODEL) {
    await res.body?.cancel();
    console.warn(`gemini model ${model} not found, falling back to ${DEFAULT_GEMINI_MODEL}`);
    return await callGemini(DEFAULT_GEMINI_MODEL, system, messages);
  }
  if (!res.ok) throw new AiError("failed", `gemini ${res.status} (${model}): ${await googleErrorMessage(res)}`);
  const data = await res.json();
  const candidate = data?.candidates?.[0];
  const text = (candidate?.content?.parts ?? [])
    .map((p: { text?: string }) => p.text ?? "")
    .join("");
  if (!text) {
    const reason = data?.promptFeedback?.blockReason ?? candidate?.finishReason ?? "unknown";
    throw new AiError("failed", `gemini empty response (${reason})`);
  }
  if (candidate?.finishReason === "MAX_TOKENS") throw new AiError("failed", "gemini answer cut (MAX_TOKENS)");
  return text;
}

async function googleErrorMessage(res: Response) {
  const raw = await res.text();
  try {
    const err = JSON.parse(raw)?.error;
    return `${err?.status ?? ""} ${err?.message ?? raw}`.trim().slice(0, 250);
  } catch {
    return raw.slice(0, 250);
  }
}

/** Chat answers: markdown streamed as it is written, so the first words show in about a second. */
async function* streamAnswer(
  settings: Settings,
  system: string,
  messages: ChatMsg[],
  allowSearch: boolean,
): AsyncGenerator<StreamPart> {
  if (settings.provider === "claude") {
    yield { text: await callClaude(settings.model, system, messages, false) };
    return;
  }
  yield* streamGemini(settings.model, system, messages, allowSearch && settings.webSearch);
}

async function* streamGemini(
  model: string,
  system: string,
  messages: ChatMsg[],
  search: boolean,
): AsyncGenerator<StreamPart> {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new AiError("not_configured");

  const generationConfig: Record<string, unknown> = { temperature: 0.7, maxOutputTokens: 4096 };
  if (/^gemini-2\.5-flash/.test(model)) generationConfig.thinkingConfig = { thinkingBudget: 0 };
  else if (/^gemini-[3-9]/.test(model)) generationConfig.thinkingConfig = { thinkingLevel: "low" };

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:streamGenerateContent?alt=sse`,
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
        ...(search ? { tools: [{ google_search: {} }] } : {}),
      }),
    },
  );

  if (res.status === 404 && model !== DEFAULT_GEMINI_MODEL) {
    await res.body?.cancel();
    yield* streamGemini(DEFAULT_GEMINI_MODEL, system, messages, search);
    return;
  }
  // Google Search has its own (small) free quota; answering without it beats failing.
  if (!res.ok && search) {
    console.warn(`gemini search unavailable (${res.status}): ${await googleErrorMessage(res)}`);
    yield* streamGemini(model, system, messages, false);
    return;
  }
  if (res.status === 429) throw new AiError("busy", "gemini 429: quota/rate limit");
  if (!res.ok || !res.body) throw new AiError("failed", `gemini ${res.status} (${model}): ${await googleErrorMessage(res)}`);

  const reader = res.body.pipeThrough(new TextDecoderStream()).getReader();
  let buffer = "";
  let finish = "";
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += value;
    let newline: number;
    while ((newline = buffer.indexOf("\n")) >= 0) {
      const line = buffer.slice(0, newline).trim();
      buffer = buffer.slice(newline + 1);
      if (!line.startsWith("data:")) continue;
      let chunk: Record<string, any>;
      try {
        chunk = JSON.parse(line.slice(5));
      } catch {
        continue;
      }
      const candidate = chunk?.candidates?.[0];
      const text = (candidate?.content?.parts ?? [])
        .filter((p: { thought?: boolean }) => !p.thought)
        .map((p: { text?: string }) => p.text ?? "")
        .join("");
      if (text) yield { text };
      const chunks = candidate?.groundingMetadata?.groundingChunks;
      if (Array.isArray(chunks) && chunks.length) {
        yield {
          sources: chunks
            .map((c: { web?: { uri?: string; title?: string } }) => ({ title: c.web?.title ?? "", url: c.web?.uri ?? null }))
            .filter((s: Source) => s.title),
        };
      }
      if (candidate?.finishReason) finish = candidate.finishReason;
      if (chunk?.promptFeedback?.blockReason) throw new AiError("failed", `blocked (${chunk.promptFeedback.blockReason})`);
    }
  }
  if (finish && !["STOP", "MAX_TOKENS"].includes(finish)) console.warn(`gemini finished with ${finish}`);
}

async function callClaude(model: string, system: string, messages: ChatMsg[], jsonOnly = true) {
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
      max_tokens: jsonOnly ? 1500 : 4096,
      temperature: jsonOnly ? 0.5 : 0.7,
      system: jsonOnly ? `${system}\n\nأرجعي JSON صالح فقط بدون أي نص قبله أو بعده.` : system,
      messages,
    }),
  });
  if (res.status === 429 || res.status === 529) throw new AiError("busy", `claude ${res.status}`);
  if (!res.ok) throw new AiError("failed", `claude ${res.status}: ${(await res.text()).slice(0, 250)}`);
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
    .in("key", ["ai_enabled", "ai_provider", "ai_model", "ai_daily_limit", "ai_global_daily_limit", "ai_web_search"]);
  const map = Object.fromEntries((data ?? []).map((r: { key: string; value: string }) => [r.key, r.value]));
  const provider = map.ai_provider === "claude" ? "claude" : "gemini";
  return {
    enabled: (map.ai_enabled ?? "true") !== "false",
    provider,
    model: (map.ai_model ?? "").trim() || (provider === "claude" ? "claude-haiku-4-5" : DEFAULT_GEMINI_MODEL),
    dailyLimit: Math.max(1, Number(map.ai_daily_limit) || 20),
    globalLimit: Math.max(1, Number(map.ai_global_daily_limit) || 200),
    webSearch: (map.ai_web_search ?? "true") !== "false",
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

/** A failed AI call must not eat the mother's daily quota. */
async function refund(admin: SupabaseClient, userId: string, kind: "message" | "plan") {
  const { error } = await admin.rpc("ai_refund", { p_user: userId, p_kind: kind });
  if (error) console.error("ai_refund", error);
}

// ---------------------------------------------------------------------------
// Health check (staff) — dashboard button «اختبار المساعدة»
// ---------------------------------------------------------------------------

async function handleHealth(admin: SupabaseClient, userId: string, settings: Settings) {
  const { data: profile } = await admin.from("profiles").select("role").eq("id", userId).maybeSingle();
  if (!["admin", "editor"].includes(profile?.role ?? "")) return json({ error: "forbidden" }, 403);

  type Check = { name: string; ok: boolean; detail: string };
  const checks: Check[] = [];
  const run = async (name: string, fn: () => Promise<string>) => {
    try {
      checks.push({ name, ok: true, detail: await fn() });
    } catch (e) {
      checks.push({ name, ok: false, detail: failure(e).detail });
    }
  };

  await run("settings", async () => {
    if (!settings.enabled) throw new Error("ai_enabled = false (المساعدة متوقفة من الإعدادات)");
    return `${settings.provider} / ${settings.model}`;
  });
  await run("api_key", async () => {
    const name = settings.provider === "claude" ? "ANTHROPIC_API_KEY" : "GEMINI_API_KEY";
    if (!Deno.env.get(name)) throw new Error(`${name} مش موجود في Supabase Secrets`);
    if (!Deno.env.get("GEMINI_API_KEY")) throw new Error("GEMINI_API_KEY مطلوب للبحث في المراجع");
    return `${name} موجود`;
  });
  await run("generate", async () => {
    const raw = await generate(settings, 'أرجعي JSON فقط: {"ok": true}', [{ role: "user", content: "اختبار" }]);
    parseJson(raw);
    return "الموديل رد بـ JSON سليم";
  });
  await run("stream", async () => {
    const started = Date.now();
    let firstMs = 0;
    let text = "";
    for await (const part of streamAnswer(settings, "ردي بكلمتين بالمصري.", [{ role: "user", content: "إزيك؟" }], true)) {
      if (part.text && !firstMs) firstMs = Date.now() - started;
      text += part.text ?? "";
    }
    if (!text.trim()) throw new Error("الرد المباشر رجع فاضي");
    return `أول كلمة بعد ${(firstMs / 1000).toFixed(1)} ثانية — البحث في Google ${settings.webSearch ? "شغال" : "مقفول"}`;
  });
  await run("embedding", async () => {
    const v = await embed("اختبار", "RETRIEVAL_QUERY");
    if (!v) throw new Error("embedding فاضي");
    return `${v.length} أبعاد`;
  });
  await run("database", async () => {
    const { error } = await admin.rpc("ai_refund", { p_user: userId, p_kind: "message" });
    if (error) throw new Error(`ai_refund: ${error.message} — شغّلي migration 039`);
    const { count: total } = await admin.from("ai_knowledge").select("id", { count: "exact", head: true })
      .eq("publish_status", "published");
    const { count: pending } = await admin.from("ai_knowledge").select("id", { count: "exact", head: true })
      .eq("publish_status", "published").is("embedding", null);
    if (!total) throw new Error("مفيش مراجع منشورة — شغّلي ملفات 035 و036");
    if (pending) throw new Error(`${pending} من ${total} مرجع مش متجهزين — دوسي «تجهيز المراجع للبحث»`);
    return `${total} مرجع جاهز للبحث`;
  });

  return json({ status: checks.every((c) => c.ok) ? "ok" : "error", checks });
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
  // Old card-style answers only carry a short summary; replaying their JSON would pull the model back to JSON.
  const history: ChatMsg[] = rows.map((m: { role: Role; content: string }) => ({
    role: m.role,
    content: m.content,
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
