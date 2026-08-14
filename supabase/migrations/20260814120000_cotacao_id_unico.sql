-- Identificador único da cotação, gerado no momento em que ela é salva.
-- É a chave que liga a cotação salva à sua submissão de aprovação, para que
-- cotações com dados idênticos (cliente/origem/destino) nunca compartilhem status.
ALTER TABLE public.cotacoes_aprovacao
  ADD COLUMN IF NOT EXISTS cotacao_id text;

CREATE INDEX IF NOT EXISTS cotacoes_aprovacao_cotacao_id_idx
  ON public.cotacoes_aprovacao (cotacao_id);
