import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { meuAcesso } from "@/lib/acessos";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const { data, error } = await supabase.auth.getUser();
    if (error || !data.user) throw redirect({ to: "/" });
    const status = await meuAcesso(data.user.id);
    if (status !== "aprovado") throw redirect({ to: "/aguardando-aprovacao" });
    return { user: data.user };
  },
  component: () => <Outlet />,
});
