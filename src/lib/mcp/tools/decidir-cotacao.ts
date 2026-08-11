import { defineTool, ToolError } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { supabaseForUser } from "../supabase";

export default defineTool({
  name: "decidir_cotacao",
  title: "Aprovar ou reprovar cotação",
  description:
    "Aprova ou reprova uma cotação pendente. Só funciona para usuários com permissão de aprovador.",
  inputSchema: {
    id: z.string().uuid().describe("Identificador da cotação."),
    status: z
      .enum(["aprovada", "reprovada"])
      .describe("Decisão a registrar na cotação."),
    observacao: z
      .string()
      .trim()
      .max(1000)
      .optional()
      .describe("Comentário opcional sobre a decisão."),
  },
  annotations: { readOnlyHint: false, destructiveHint: true, openWorldHint: false },
  handler: async ({ id, status, observacao }, ctx) => {
    if (!ctx.isAuthenticated()) throw new ToolError("Não autenticado.");
    const supabase = supabaseForUser(ctx);
    const { data, error } = await supabase
      .from("cotacoes_aprovacao")
      .update({
        status,
        decided_at: new Date().toISOString(),
        decided_by: ctx.getUserId(),
        ...(observacao ? { observacao } : {}),
      })
      .eq("id", id)
      .select("id, status, decided_at, observacao");
    if (error) throw new ToolError(error.message);
    if (!data || data.length === 0)
      throw new ToolError(
        "Nenhuma cotação atualizada — verifique o id e se você tem permissão de aprovador.",
      );
    return {
      content: [{ type: "text", text: `Cotação ${id} marcada como ${status}.` }],
      structuredContent: { cotacao: data[0] },
    };
  },
});
