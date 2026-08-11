import { defineTool, ToolError } from "@lovable.dev/mcp-js";
import { z } from "zod";
import { supabaseForUser } from "../supabase";

const COLUNAS =
  "id, cliente, origem, uf_origem, destino, uf_destino, status, observacao, submitted_by_email, created_at, decided_at";

export default defineTool({
  name: "list_cotacoes",
  title: "Listar cotações submetidas",
  description:
    "Lista as cotações de frete submetidas à aprovação visíveis para o usuário autenticado. Permite filtrar por status.",
  inputSchema: {
    status: z
      .enum(["pendente", "aprovada", "reprovada"])
      .optional()
      .describe("Filtra pelo status da submissão."),
    limit: z
      .number()
      .int()
      .min(1)
      .max(100)
      .optional()
      .describe("Número máximo de cotações retornadas (padrão 20)."),
  },
  annotations: { readOnlyHint: true, idempotentHint: true, openWorldHint: false },
  handler: async ({ status, limit }, ctx) => {
    if (!ctx.isAuthenticated()) throw new ToolError("Não autenticado.");
    const supabase = supabaseForUser(ctx);
    let query = supabase
      .from("cotacoes_aprovacao")
      .select(COLUNAS)
      .order("created_at", { ascending: false })
      .limit(limit ?? 20);
    if (status) query = query.eq("status", status);
    const { data, error } = await query;
    if (error) throw new ToolError(error.message);
    return {
      content: [{ type: "text", text: JSON.stringify(data ?? [], null, 2) }],
      structuredContent: { cotacoes: data ?? [] },
    };
  },
});
