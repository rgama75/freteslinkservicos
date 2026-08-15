-- Expose only the status of every submitted quote (no pricing data, no
-- submitter identity) to all authenticated users, bypassing the row-level
-- security that otherwise limits a user to their own submissions or the
-- approver to everything. This lets any user see, in "Cotações Salvas",
-- when the approver has decided on a quote someone else submitted.
CREATE OR REPLACE FUNCTION public.listar_status_cotacoes()
RETURNS TABLE (
  cliente text,
  origem text,
  destino text,
  status text,
  decided_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT cliente, origem, destino, status, decided_at
  FROM public.cotacoes_aprovacao
  ORDER BY created_at DESC;
$$;

REVOKE ALL ON FUNCTION public.listar_status_cotacoes() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.listar_status_cotacoes() TO authenticated;
