CREATE TYPE public.app_role AS ENUM ('approver');

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own roles"
ON public.user_roles FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
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

CREATE OR REPLACE FUNCTION public.grant_approver_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email_confirmed_at IS NOT NULL
     AND lower(NEW.email) = 'rodrigo.gama@linkbr.com' THEN
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'approver')
    ON CONFLICT (user_id, role) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created_grant_approver
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.grant_approver_role();

CREATE TRIGGER on_auth_user_confirmed_grant_approver
AFTER UPDATE OF email_confirmed_at ON auth.users
FOR EACH ROW
WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
EXECUTE FUNCTION public.grant_approver_role();

CREATE TABLE public.cotacoes_aprovacao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  submitted_by_email text,
  cliente text NOT NULL DEFAULT '',
  origem text NOT NULL DEFAULT '',
  uf_origem text NOT NULL DEFAULT '',
  destino text NOT NULL DEFAULT '',
  uf_destino text NOT NULL DEFAULT '',
  dados jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pendente',
  observacao text,
  decided_at timestamptz,
  decided_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE ON public.cotacoes_aprovacao TO authenticated;
GRANT ALL ON public.cotacoes_aprovacao TO service_role;

ALTER TABLE public.cotacoes_aprovacao ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own submissions"
ON public.cotacoes_aprovacao FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Approver can view all submissions"
ON public.cotacoes_aprovacao FOR SELECT TO authenticated
USING (public.has_role(auth.uid(), 'approver'));

CREATE POLICY "Users can submit their own quotes"
ON public.cotacoes_aprovacao FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Approver can decide submissions"
ON public.cotacoes_aprovacao FOR UPDATE TO authenticated
USING (public.has_role(auth.uid(), 'approver'))
WITH CHECK (public.has_role(auth.uid(), 'approver'));

CREATE TRIGGER cotacoes_aprovacao_set_updated_at
BEFORE UPDATE ON public.cotacoes_aprovacao
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();