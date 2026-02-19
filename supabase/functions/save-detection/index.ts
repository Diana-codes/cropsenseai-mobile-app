import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface DetectionRequest {
  disease_id: string;
  image_url: string;
  confidence_score: number;
  top_predictions: Array<{
    disease: string;
    confidence: number;
  }>;
  location?: string;
  crop_type?: string;
  notes?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: {
            Authorization: req.headers.get("Authorization")!,
          },
        },
      }
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const detectionData: DetectionRequest = await req.json();

    const { data, error } = await supabase
      .from("disease_detections")
      .insert({
        user_id: user.id,
        disease_id: detectionData.disease_id,
        image_url: detectionData.image_url,
        confidence_score: detectionData.confidence_score,
        top_predictions: detectionData.top_predictions,
        location: detectionData.location,
        crop_type: detectionData.crop_type,
        notes: detectionData.notes,
        status: "pending",
      })
      .select(
        `
        *,
        disease:crop_diseases(
          id,
          name,
          description,
          symptoms,
          severity_level
        )
      `
      )
      .single();

    if (error) {
      throw error;
    }

    const { data: recommendations } = await supabase
      .from("recommendations")
      .select("*")
      .eq("disease_id", detectionData.disease_id)
      .order("priority", { ascending: true });

    return new Response(
      JSON.stringify({
        success: true,
        detection: data,
        recommendations: recommendations || [],
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
