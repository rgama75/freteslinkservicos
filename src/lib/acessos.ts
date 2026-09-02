import { supabase } from "@/integrations/supabase/client";

export type AcessoStatus = "pendente" | "aprovado" | "reprovado";

export type UsuarioAcesso = {
  id: string;
  email: string | null;
  full_name: string | null;
  company: string | null;
  access_status: string;
  created_at: string;
  access_decided_at: string | null;
};

/** Status de acesso do usuário logado. */
export async function meuAcesso(userId: string): Promise<AcessoStatus> {
  const { data, error } = await supabase
    .from("profiles")
    .select("access_status")
    .eq("id", userId)
    .maybeSingle();
  if (error || !data) return "pendente";
  return (data.access_status as AcessoStatus) ?? "pendente";
}

/** Lista todos os cadastros (apenas o aprovador tem permissão). */
export async function listarUsuarios(): Promise<UsuarioAcesso[]> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email, full_name, company, access_status, created_at, access_decided_at")
    .order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []) as UsuarioAcesso[];
}

/** Aprova ou reprova o acesso de um cadastro. */
export async function decidirAcesso(id: string, status: AcessoStatus) {
  const { data: userData } = await supabase.auth.getUser();
  const { error } = await supabase
    .from("profiles")
    .update({
      access_status: status,
      access_decided_at: new Date().toISOString(),
      access_decided_by: userData.user?.id ?? null,
    })
    .eq("id", id);
  if (error) throw error;
}

/** Se o usuário logado tem o papel de administrador (aprovador). */
export async function souAdministrador(): Promise<boolean> {
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) return false;
  const { data, error } = await supabase
    .from("user_roles")
    .select("role")
    .eq("user_id", userData.user.id)
    .eq("role", "approver")
    .maybeSingle();
  if (error) return false;
  return data != null;
}

/** IDs de todos os usuários que já são administradores (só visível para administradores). */
export async function listarAdministradores(): Promise<string[]> {
  const { data, error } = await supabase.from("user_roles").select("user_id").eq("role", "approver");
  if (error) throw error;
  return (data ?? []).map((r) => r.user_id as string);
}

/** Concede o papel de administrador a um usuário (só um administrador pode conceder). */
export async function tornarAdministrador(userId: string) {
  const { error } = await supabase.from("user_roles").insert({ user_id: userId, role: "approver" });
  if (error) throw error;
}
