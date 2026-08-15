-- Replace the SECURITY DEFINER status RPC with a dedicated, non-sensitive status table.

CREATE TABLE IF NOT EXISTS public.cotacoes_status (
  cotacao_id uuid PRIMARY KEY REFERENCES public.cotacoes_aprovacao(id) ON DELETE CASCADE,
  cliente text NOT NULL DEFAULT '',
  origem text NOT NULL DEFAULT '',
  destino text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'pendente',
  decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.cotacoes_status TO authenticated;
GRANT ALL ON public.cotacoes_status TO service_role;

ALTER TABLE public.cotacoes_status ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Signed-in users can view quote statuses" ON public.cotacoes_status;
CREATE POLICY "Signed-in users can view quote statuses"
ON public.cotacoes_status
FOR SELECT
TO authenticated
USING (true);

CREATE OR REPLACE FUNCTION public.sync_cotacao_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.cotacoes_status (cotacao_id, cliente, origem, destino, status, decided_at, created_at)
  VALUES (NEW.id, NEW.cliente, NEW.origem, NEW.destino, NEW.status, NEW.decided_at, NEW.created_at)
  ON CONFLICT (cotacao_id) DO UPDATE
    SET cliente = EXCLUDED.cliente,
        origem = EXCLUDED.origem,
        destino = EXCLUDED.destino,
        status = EXCLUDED.status,
        decided_at = EXCLUDED.decided_at;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_cotacao_status() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_cotacao_status() FROM anon;
REVOKE ALL ON FUNCTION public.sync_cotacao_status() FROM authenticated;

DROP TRIGGER IF EXISTS cotacoes_aprovacao_sync_status ON public.cotacoes_aprovacao;
CREATE TRIGGER cotacoes_aprovacao_sync_status
AFTER INSERT OR UPDATE ON public.cotacoes_aprovacao
FOR EACH ROW EXECUTE FUNCTION public.sync_cotacao_status();

INSERT INTO public.cotacoes_status (cotacao_id, cliente, origem, destino, status, decided_at, created_at)
SELECT id, cliente, origem, destino, status, decided_at, created_at
FROM public.cotacoes_aprovacao
ON CONFLICT (cotacao_id) DO UPDATE
  SET cliente = EXCLUDED.cliente,
      origem = EXCLUDED.origem,
      destino = EXCLUDED.destino,
      status = EXCLUDED.status,
      decided_at = EXCLUDED.decided_at;

DROP FUNCTION IF EXISTS public.listar_status_cotacoes();