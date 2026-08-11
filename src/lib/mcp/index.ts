import { auth, defineMcp } from "@lovable.dev/mcp-js";
import type { AnyToolDefinition } from "@lovable.dev/mcp-js";
import listCotacoesTool from "./tools/list-cotacoes";
import getCotacaoTool from "./tools/get-cotacao";
import decidirCotacaoTool from "./tools/decidir-cotacao";

const projectRef =
  import.meta.env['VITE_SUPABASE_PROJECT_ID'] ?? "project-ref-unset";

export default defineMcp({
  name: "sistema-de-precificacao-de-fretes",
  title: "Ship Rate Calculator",
  version: "0.1.0",
  instructions:
    "Ferramentas do sistema de precificação de fretes rodoviários. Use `list_cotacoes` para listar cotações submetidas à aprovação, `get_cotacao` para ver os dados completos de uma cotação e `decidir_cotacao` para aprovar ou reprovar (apenas aprovadores).",
  auth: auth.oauth.issuer({
    issuer: `https://${projectRef}.supabase.co/auth/v1`,
    acceptedAudiences: "authenticated",
  }),
  tools: [listCotacoesTool, getCotacaoTool, decidirCotacaoTool] as AnyToolDefinition[],
});
