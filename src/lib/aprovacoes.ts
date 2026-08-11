import { supabase } from "@/integrations/supabase/client";
import type { DadosCard, DadosGerais } from "@/lib/pricing";

export const APPROVER_EMAIL = "rodrigo.gama@linkbr.com";

export type SubmissaoStatus = "pendente" | "aprovada" | "reprovada";

export type Submissao = {
  id: string;
  cliente: string;
  origem: string;
  uf_origem: string;
  destino: string;
  uf_destino: string;
  status: string;
  observacao: string | null;
  submitted_by_email: string | null;
  created_at: string;
  decided_at: string | null;
  dados: unknown;
};

export async function submeterAprovacao(
  gerais: DadosGerais,
  cards: Record<number, DadosCard>,
) {
  const { data: userData, error: userError } = await supabase.auth.getUser();
  const user = userData.user;
  if (userError || !user) throw new Error("Sessão expirada. Entre novamente.");

  const { error } = await supabase.from("cotacoes_aprovacao").insert({
    user_id: user.id,
    submitted_by_email: user.email ?? null,
    cliente: gerais.cliente ?? "",
    origem: gerais.origem ?? "",
    uf_origem: gerais.ufOrigem ?? "",
    destino: gerais.destino ?? "",
    uf_destino: gerais.ufDestino ?? "",
    dados: { gerais, cards } as never,
    status: "pendente",
  });
  if (error) throw error;
}

export async function listarSubmissoes(): Promise<Submissao[]> {
  const { data, error } = await supabase
    .from("cotacoes_aprovacao")
    .select(
      "id, cliente, origem, uf_origem, destino, uf_destino, status, observacao, submitted_by_email, created_at, decided_at, dados",
    )
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as Submissao[];
}

export async function decidirSubmissao(id: string, status: SubmissaoStatus) {
  const { data: userData } = await supabase.auth.getUser();
  const { error } = await supabase
    .from("cotacoes_aprovacao")
    .update({
      status,
      decided_at: new Date().toISOString(),
      decided_by: userData.user?.id ?? null,
    })
    .eq("id", id);
  if (error) throw error;
}
