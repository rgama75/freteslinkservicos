ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS access_status text NOT NULL DEFAULT 'pendente',
  ADD COLUMN IF NOT EXISTS access_decided_at timestamptz,
  ADD COLUMN IF NOT EXISTS access_decided_by uuid;

UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE u.id = p.id AND p.email IS NULL;

UPDATE public.profiles SET access_status = 'aprovado' WHERE access_status = 'pendente';

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, company, email, access_status)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'company',
    NEW.email,
    CASE WHEN lower(NEW.email) = 'rodrigo.gama@linkbr.com' THEN 'aprovado' ELSE 'pendente' END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

CREATE POLICY "Approver can view all profiles"
ON public.profiles FOR SELECT TO authenticated
USING (private.has_role(auth.uid(), 'approver'::app_role));

CREATE POLICY "Approver can decide access"
ON public.profiles FOR UPDATE TO authenticated
USING (private.has_role(auth.uid(), 'approver'::app_role))
WITH CHECK (private.has_role(auth.uid(), 'approver'::app_role));