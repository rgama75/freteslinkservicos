import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

const schema = z.object({
  nome: z.string().trim().max(120).optional(),
  email: z.string().trim().email().max(160),
  empresa: z.string().trim().max(120).optional(),
});

/**
 * Avisa o aprovador que existe um novo cadastro aguardando liberação.
 * O destinatário é fixo no servidor — nunca vem do navegador.
 */
export const notificarNovoCadastro = createServerFn({ method: "POST" })
  .inputValidator((data: unknown) => schema.parse(data))
  .handler(async ({ data }) => {
    const { sendTemplateEmail } = await import("@/lib/email-templates/send-email");
    const APPROVER_EMAIL = "rodrigo.gama@linkbr.com";
    try {
      const result = await sendTemplateEmail("novo-cadastro", APPROVER_EMAIL, {
        templateData: { nome: data.nome, email: data.email, empresa: data.empresa },
        idempotencyKey: `novo-cadastro-${data.email.toLowerCase()}`,
      });
      return { ok: result.sent };
    } catch (error) {
      console.error("[notificarNovoCadastro] falha ao enviar e-mail", error);
      return { ok: false };
    }
  });
