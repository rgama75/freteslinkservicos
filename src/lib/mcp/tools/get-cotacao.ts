import { defineTool, ToolError } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { supabaseForUser } from "../supabase";

export default defineTool({
  name: "get_cotacao",
  title: "Detalhar cotação",
  description:
    "Retorna todos os dados de uma cotação submetida à aprovação, incluindo as entradas gerais e os cálculos por configuração de eixos.",
  inputSchema: {
    id: z.string().uuid().describe("Identificador da cotação."),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ id }, ctx) => {
    if (!ctx.isAuthenticated()) throw new ToolError("Não autenticado.");
    const supabase = supabaseForUser(ctx);
    const { data, error } = await supabase
      .from("cotacoes_aprovacao")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (error) throw new ToolError(error.message);
    if (!data) throw new ToolError("Cotação não encontrada.");
    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
      structuredContent: { cotacao: data },
    };
  },
});
