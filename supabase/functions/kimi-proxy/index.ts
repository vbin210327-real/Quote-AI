import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const kimiApiKey = Deno.env.get("KIMI_API_KEY");
const revenueCatSecret = Deno.env.get("REVENUECAT_SECRET_KEY");
const kimiEndpoint =
  Deno.env.get("KIMI_API_ENDPOINT") ??
  "https://api.moonshot.cn/v1/chat/completions";

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function parseDate(value: unknown): number | null {
  if (typeof value === "string") {
    const ms = Date.parse(value);
    return Number.isNaN(ms) ? null : ms;
  }
  if (typeof value === "number") {
    return value;
  }
  return null;
}

function isEntitlementActive(entitlement: Record<string, unknown> | null) {
  if (!entitlement) {
    return false;
  }

  if (entitlement.is_active === true) {
    return true;
  }

  const now = Date.now();
  const grace = parseDate(entitlement.grace_period_expires_date);
  if (grace && grace > now) {
    return true;
  }

  const expires =
    parseDate(entitlement.expires_date) ??
    parseDate(entitlement.expires_date_ms);
  if (!expires) {
    return true;
  }

  return expires > now;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  if (!supabaseUrl || !supabaseServiceKey || !kimiApiKey || !revenueCatSecret) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length)
    : "";
  if (!token) {
    return jsonResponse({ error: "auth_required" }, 401);
  }

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data, error } = await supabase.auth.getUser();
  if (error || !data?.user) {
    return jsonResponse({ error: "auth_required" }, 401);
  }

  const userId = data.user.id;
  const candidateIds = Array.from(
    new Set([userId, userId.toLowerCase(), userId.toUpperCase()]),
  );

  let hasActiveEntitlement = false;

  for (const candidateId of candidateIds) {
    const rcResponse = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(
        candidateId,
      )}`,
      {
        headers: {
          Authorization: `Bearer ${revenueCatSecret}`,
          "Content-Type": "application/json",
        },
      },
    );

    if (!rcResponse.ok) {
      if (rcResponse.status === 404) {
        continue;
      }
      return jsonResponse({ error: "subscription_required" }, 402);
    }

    const rcData = await rcResponse.json();
    const entitlement = rcData?.subscriber?.entitlements?.pro ?? null;
    if (isEntitlementActive(entitlement)) {
      hasActiveEntitlement = true;
      break;
    }
  }

  if (!hasActiveEntitlement) {
    return jsonResponse({ error: "subscription_required" }, 402);
  }

  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_request" }, 400);
  }

  const kimiResponse = await fetch(kimiEndpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${kimiApiKey}`,
    },
    body: JSON.stringify(payload),
  });

  const bodyText = await kimiResponse.text();
  return new Response(bodyText, {
    status: kimiResponse.status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
});
