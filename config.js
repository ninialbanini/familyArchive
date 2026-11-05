/* Family Voice Archive settings.
   The Supabase project URL and publishable (public) key turn on family
   sign-in and saving. Both are safe to publish: the archive is protected
   by the row-level security rules in supabase/setup.sql.
   Leave them empty to run the site as a demo that doesn't save. */
window.FVA_CONFIG = {
  supabaseUrl: "https://acuqfqptncxdtwxvpika.supabase.co",
  supabaseAnonKey: "sb_publishable_xJnv4e96pWNmNzQCnH30xw_HuoCm1nt",
  /* The shared "family password" login. This is the email of a Supabase user
     you create for the whole family (see README). Only the password is secret. */
  familyLoginEmail: "family.archive@example.com"
};
