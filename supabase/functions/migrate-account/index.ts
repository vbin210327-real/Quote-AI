import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function parseJsonBody<T>(req: Request): Promise<T | null> {
  return req.json().catch(() => null);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const missingEnv: string[] = [];
  if (!supabaseUrl) missingEnv.push("SUPABASE_URL");
  if (!supabaseServiceKey) missingEnv.push("SUPABASE_SERVICE_ROLE_KEY");

  if (missingEnv.length > 0) {
    console.error("Missing env vars:", missingEnv);
    return jsonResponse(
      { error: "server_misconfigured", missing: missingEnv },
      500,
    );
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length)
    : "";
  if (!token) {
    return jsonResponse({ error: "auth_required" }, 401);
  }

  const userClient = createClient(supabaseUrl, supabaseServiceKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const adminClient = createClient(supabaseUrl, supabaseServiceKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData?.user) {
    return jsonResponse({ error: "auth_required" }, 401);
  }

  const body = await parseJsonBody<{ oldUserId?: string }>(req);
  const oldUserId = body?.oldUserId;
  if (!oldUserId) {
    return jsonResponse({ error: "invalid_request" }, 400);
  }

  const newUserId = userData.user.id;
  const oldUserIdLower = oldUserId.toLowerCase();
  const newUserIdLower = newUserId.toLowerCase();

  if (oldUserIdLower === newUserIdLower) {
    return jsonResponse({ skipped: true, reason: "same_user" });
  }

  const { data: oldUserData, error: oldUserError } =
    await adminClient.auth.admin.getUserById(oldUserId);
  if (oldUserError || !oldUserData?.user) {
    return jsonResponse({ error: "old_user_not_found" }, 400);
  }

  const oldUser = oldUserData.user as {
    is_anonymous?: boolean;
    isAnonymous?: boolean;
  };
  const isOldAnonymous = oldUser.is_anonymous ?? oldUser.isAnonymous ?? false;
  if (!isOldAnonymous) {
    return jsonResponse({ error: "old_user_not_anonymous" }, 400);
  }

  const { count: profileCount, error: profileCountError } = await adminClient
    .from("user_profiles")
    .select("id", { count: "exact", head: true })
    .eq("user_id", newUserIdLower);
  if (profileCountError) {
    return jsonResponse({ error: "check_profile_failed" }, 500);
  }

  const { count: conversationCount, error: conversationCountError } =
    await adminClient
      .from("conversations")
      .select("id", { count: "exact", head: true })
      .eq("user_id", newUserIdLower);
  if (conversationCountError) {
    return jsonResponse({ error: "check_conversations_failed" }, 500);
  }

  const { count: quoteCount, error: quoteCountError } = await adminClient
    .from("saved_quotes")
    .select("id", { count: "exact", head: true })
    .eq("user_id", newUserIdLower);
  if (quoteCountError) {
    return jsonResponse({ error: "check_quotes_failed" }, 500);
  }

  if ((profileCount ?? 0) > 0 || (conversationCount ?? 0) > 0 ||
    (quoteCount ?? 0) > 0) {
    return jsonResponse({ skipped: true, reason: "target_not_empty" });
  }

  const candidateOldIds = Array.from(
    new Set([oldUserId, oldUserIdLower, oldUserId.toUpperCase()]),
  );

  const { error: profileUpdateError } = await adminClient
    .from("user_profiles")
    .update({ user_id: newUserIdLower, updated_at: new Date().toISOString() })
    .in("user_id", candidateOldIds);
  if (profileUpdateError) {
    return jsonResponse({ error: "migrate_profile_failed" }, 500);
  }

  const { error: conversationUpdateError } = await adminClient
    .from("conversations")
    .update({ user_id: newUserIdLower })
    .in("user_id", candidateOldIds);
  if (conversationUpdateError) {
    return jsonResponse({ error: "migrate_conversations_failed" }, 500);
  }

  const { error: quoteUpdateError } = await adminClient
    .from("saved_quotes")
    .update({ user_id: newUserIdLower })
    .in("user_id", candidateOldIds);
  if (quoteUpdateError) {
    return jsonResponse({ error: "migrate_quotes_failed" }, 500);
  }

  const bucketName = "profile-images";
  const { data: files, error: listError } = await adminClient.storage
    .from(bucketName)
    .list(oldUserIdLower, { limit: 100 });
  if (!listError && files && files.length > 0) {
    for (const file of files) {
      const fromPath = `${oldUserIdLower}/${file.name}`;
      const toPath = `${newUserIdLower}/${file.name}`;
      const { error: moveError } = await adminClient.storage
        .from(bucketName)
        .move(fromPath, toPath);
      if (moveError) {
        console.error("Move storage error:", moveError);
      }
    }

    const { data: publicUrlData } = adminClient.storage
      .from(bucketName)
      .getPublicUrl(`${newUserIdLower}/profile.jpg`);
    if (publicUrlData?.publicUrl) {
      const updatedUrl = `${publicUrlData.publicUrl}?t=${Date.now()}`;
      await adminClient
        .from("user_profiles")
        .update({ profile_image_url: updatedUrl })
        .eq("user_id", newUserIdLower);
    }
  }

  return jsonResponse({ migrated: true });
});
