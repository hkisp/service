import { usageSummary } from "@/lib/usage";

export async function GET() {
  // Real counts from the local in-memory log only; zero when nothing ran.
  // No costs are invented.
  return Response.json(usageSummary());
}
