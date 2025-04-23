defmodule MolyWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides

  # configure your UI overrides here

  # First argument to `override` is the component name you are overriding.
  # The body contains any number of configurations you wish to override
  # Below are some examples

  # For a complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html
  override AshAuthentication.Phoenix.SignInLive do
    set(:root_class, "flex min-h-[100vh] flex-col justify-center py-12 sm:px-6 lg:px-8")
  end

  override AshAuthentication.Phoenix.Components.Banner do
    set(:image_url, "/images/logo.svgz")
    set(:image_class, "size-10 mx-auto h-10 w-auto")
    set(:root_class, "mx-auto")
    set(:text_class, "mt-2 text-center text-2xl/9 font-semibold tracking-tight")
    set(:text, "Affinew")
  end

  override AshAuthentication.Phoenix.Components.SignIn do
    set(:root_class, """
    flex-1 flex flex-col justify-center px-4 sm:px-6 lg:flex-none
    lg:px-20 xl:px-24 shadown-lg
    """)

    set(:strategy_class, "sm:mx-auto sm:w-full sm:max-w-[480px]")
  end

  override AshAuthentication.Phoenix.Components.Password do
    set(:root_class, "my-0")
    set(:toggler_class, "flex-none text-base-content px-2 first:pl-0 last:pr-0 last:text-primary")
  end

  override AshAuthentication.Phoenix.Components.Password.SignInForm do
    set(:root_class, "mt-4 bg-white px-12 pt-12 sm:rounded-t-lg sm:pt-12")
    set(:form_class, "space-y-6")
  end

  override AshAuthentication.Phoenix.Components.Password.RegisterForm do
    set(:root_class, "mt-4 bg-white px-12 pt-12 sm:rounded-t-lg sm:pt-12")
    set(:form_class, "space-y-6")
  end

  override AshAuthentication.Phoenix.ResetLive do
  end

  override AshAuthentication.Phoenix.Components.Reset do
  end

  override AshAuthentication.Phoenix.Components.Reset.Form do
    set(:root_class, "mt-4 bg-white px-12 py-12 sm:rounded-t-lg sm:pt-12")
    set(:form_class, "space-y-6")
    set(:spacer_class, "py-0")
  end

  override AshAuthentication.Phoenix.Components.Password.ResetForm do
    set(:root_class, "mt-4 bg-white px-12 pt-12 sm:rounded-t-lg sm:pt-12")
    set(:form_class, "space-y-6")
  end

  override AshAuthentication.Phoenix.Components.Password.Input do
    set(:input_class, "input !w-full")
    set(:submit_class, "btn text-white bg-primary w-full")
    set(:field_class, "")
    set(:identity_input_placeholder, "Email")
  end

  override AshAuthentication.Phoenix.Components.OAuth2 do
    set(:root_class, "w-full px-12 bg-white pt-4 pb-12 rounded-b-lg")
    set(:link_class, "btn bg-white text-black border-[#e5e5e5] w-full")
    set(:icon_class, "size-6")
  end

  override AshAuthentication.Phoenix.Components.HorizontalRule do
    set(:text, "Or continue with")
    set(:root_class, "relative pt-12")

    set(
      :hr_outer_class,
      "absolute inset-0 flex items-center sm:w-full sm:max-w-[480px] mx-auto bg-white"
    )

    set(:hr_inner_class, "w-4/5 border-t mt-12 border-base-content/5 mx-auto")
    set(:text_inner_class, "text-base-content bg-white px-4 font-meidum")
  end
end
