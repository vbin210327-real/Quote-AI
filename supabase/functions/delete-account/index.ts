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

  const { data, error } = await userClient.auth.getUser();
  if (error || !data?.user) {
    return jsonResponse({ error: "auth_required" }, 401);
  }

  const userId = data.user.id;
  const candidateIds = Array.from(
    new Set([userId, userId.toLowerCase(), userId.toUpperCase()]),
  );
  const normalizedUserId = userId.toLowerCase();

  const { error: profileError } = await adminClient
    .from("user_profiles")
    .delete()
    .in("user_id", candidateIds);
  if (profileError) {
    console.error("Delete user_profiles error:", profileError);
    return jsonResponse({ error: "delete_profile_failed" }, 500);
  }

  const { error: quoteError } = await adminClient
    .from("saved_quotes")
    .delete()
    .in("user_id", candidateIds);
  if (quoteError) {
    console.error("Delete saved_quotes error:", quoteError);
    return jsonResponse({ error: "delete_quotes_failed" }, 500);
  }

  const { error: conversationError } = await adminClient
    .from("conversations")
    .delete()
    .in("user_id", candidateIds);
  if (conversationError) {
    console.error("Delete conversations error:", conversationError);
    return jsonResponse({ error: "delete_conversations_failed" }, 500);
  }

  const bucketName = "profile-images";
  const { data: files, error: listError } = await adminClient.storage
    .from(bucketName)
    .list(normalizedUserId, { limit: 100 });
  if (!listError && files && files.length > 0) {
    const paths = files.map((file) => `${normalizedUserId}/${file.name}`);
    const { error: removeError } = await adminClient.storage
      .from(bucketName)
      .remove(paths);
    if (removeError) {
      console.error("Delete storage error:", removeError);
      return jsonResponse({ error: "delete_storage_failed" }, 500);
    }
  }

  const { error: deleteUserError } = await adminClient.auth.admin.deleteUser(
    userId,
  );
  if (deleteUserError) {
    console.error("Delete auth user error:", deleteUserError);
    return jsonResponse({ error: "delete_user_failed" }, 500);
  }

  return jsonResponse({ success: true });
});
