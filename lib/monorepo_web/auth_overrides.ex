defmodule MonorepoWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides

  # configure your UI overrides here

  # First argument to `override` is the component name you are overriding.
  # The body contains any number of configurations you wish to override
  # Below are some examples

  # For a complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html

  override AshAuthentication.Phoenix.Components.Banner do
    set :image_url, "/images/logo.svg"
    set :text_class, "text-accent text-4xl"
    set :text, "affinew"
    set :image_class, "size-12"
    set :root_class, "flex items-center justify-center"
  end

  override AshAuthentication.Phoenix.Components.SignIn do
    set :show_banner, true
  end

  override AshAuthentication.Phoenix.Components.Password do
    set :toggler_class, "flex-none text-gray-500 hover:text-gray-600 px-2 first:pl-0"
  end

  override AshAuthentication.Phoenix.Components.Password.Input do
    set :submit_class, "w-full flex justify-center py-2 px-4 border border-transparent rounded-md
    shadow-sm text-sm font-medium text-white bg-green-500 hover:bg-green-600
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500
    mt-4 mb-4"
  end
end
