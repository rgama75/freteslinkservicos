ALTER TABLE public.cotacoes_aprovacao ADD COLUMN IF NOT EXISTS ref_local text;
ALTER TABLE public.cotacoes_status ADD COLUMN IF NOT EXISTS ref_local text;

CREATE OR REPLACE FUNCTION public.sync_cotacao_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.cotacoes_status (cotacao_id, ref_local, cliente, origem, destino, status, decided_at, created_at)
  VALUES (NEW.id, NEW.ref_local, NEW.cliente, NEW.origem, NEW.destino, NEW.status, NEW.decided_at, NEW.created_at)
  ON CONFLICT (cotacao_id) DO UPDATE
    SET ref_local = EXCLUDED.ref_local,
        cliente = EXCLUDED.cliente,
        origem = EXCLUDED.origem,
        destino = EXCLUDED.destino,
        status = EXCLUDED.status,
        decided_at = EXCLUDED.decided_at;
  RETURN NEW;
END;
$function$;