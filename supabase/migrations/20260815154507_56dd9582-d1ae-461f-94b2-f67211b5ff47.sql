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

REVOKE ALL ON FUNCTION public.listar_status_cotacoes() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.listar_status_cotacoes() FROM anon;
GRANT EXECUTE ON FUNCTION public.listar_status_cotacoes() TO authenticated;