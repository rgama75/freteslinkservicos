CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

REVOKE ALL ON FUNCTION private.has_role(uuid, public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.has_role(uuid, public.app_role) TO authenticated, service_role;

DROP POLICY IF EXISTS "Approver can view all submissions" ON public.cotacoes_aprovacao;
CREATE POLICY "Approver can view all submissions"
ON public.cotacoes_aprovacao FOR SELECT TO authenticated
USING (private.has_role(auth.uid(), 'approver'::public.app_role));

DROP POLICY IF EXISTS "Approver can decide submissions" ON public.cotacoes_aprovacao;
CREATE POLICY "Approver can decide submissions"
ON public.cotacoes_aprovacao FOR UPDATE TO authenticated
USING (private.has_role(auth.uid(), 'approver'::public.app_role))
WITH CHECK (private.has_role(auth.uid(), 'approver'::public.app_role));

REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;