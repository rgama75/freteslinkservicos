-- Status da cotação decidido pelo aprovador (rodrigo.gama@linkbr.com) visível
-- para qualquer usuário autenticado.
--
-- A RLS de cotacoes_aprovacao só permite que um usuário comum leia as próprias
-- submissões, então ele nunca enxerga a decisão que o aprovador registrou em
-- uma cotação submetida por outra pessoa. A função abaixo (SECURITY DEFINER)
-- devolve apenas o par chave/status das cotações já decididas pelo aprovador,
-- e somente para as chaves que o chamador já possui localmente.

CREATE OR REPLACE FUNCTION private.chave_cotacao(
  _cliente text,
  _origem text,
  _destino text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
  SELECT lower(btrim(coalesce(_cliente, ''))) || '|' ||
         lower(btrim(coalesce(_origem, ''))) || '|' ||
         lower(btrim(coalesce(_destino, '')))
$$;

REVOKE ALL ON FUNCTION private.chave_cotacao(text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.chave_cotacao(text, text, text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.status_cotacoes_aprovador(_chaves text[])
RETURNS TABLE (chave text, status text, decided_at timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT ON (d.chave) d.chave, d.status, d.decided_at
  FROM (
    SELECT private.chave_cotacao(ca.cliente, ca.origem, ca.destino) AS chave,
           ca.status AS status,
           ca.decided_at AS decided_at,
           ca.created_at AS created_at
    FROM public.cotacoes_aprovacao AS ca
    WHERE ca.decided_at IS NOT NULL
      AND ca.status <> 'pendente'
      AND private.has_role(ca.decided_by, 'approver'::public.app_role)
  ) AS d
  WHERE auth.uid() IS NOT NULL
    AND coalesce(array_length(_chaves, 1), 0) BETWEEN 1 AND 1000
    AND d.chave = ANY (_chaves)
  ORDER BY d.chave, d.decided_at DESC, d.created_at DESC
$$;

REVOKE ALL ON FUNCTION public.status_cotacoes_aprovador(text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.status_cotacoes_aprovador(text[]) TO authenticated, service_role;
