-- Today only rodrigo.gama@linkbr.com is ever granted the 'approver' role
-- (via the on-signup trigger), and it can never be granted to anyone else.
-- Users who forward their quotes for approval expect any administrator to
-- see and decide them, so let existing approvers view every role grant and
-- promote other users to approver.

CREATE POLICY "Approver can view all roles"
ON public.user_roles FOR SELECT TO authenticated
USING (private.has_role(auth.uid(), 'approver'::public.app_role));

CREATE POLICY "Approver can grant approver role"
ON public.user_roles FOR INSERT TO authenticated
WITH CHECK (
  role = 'approver'::public.app_role
  AND private.has_role(auth.uid(), 'approver'::public.app_role)
);
