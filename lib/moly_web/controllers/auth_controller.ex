defmodule MolyWeb.AuthController do
  use MolyWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/programs"

    message =
      case activity do
        {:confirm_new_user, :confirm} ->
          if user.status != :active do
            Ash.update!(
              user,
              %{status: :active},
              action: :update_user_status,
              context: %{private: %{ash_authentication?: true}}
            )
          end

          "Your email address has now been confirmed"

        {:password, :reset} ->
          "Your password has successfully been reset"

        _ ->
          "You are now signed in"
      end

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    # If your resource has a different name, update the assign name here (i.e :current_admin)
    |> assign(:current_user, user)
    |> put_flash(:info, message)
    |> redirect(to: return_to)
  end

  def failure(conn, activity, reason) do
    message =
      case {activity, reason} do
        {{:magic_link, _},
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          "You have already signed in another way, but have not confirmed your account. Please confirm your account."

        _ ->
          "Incorrect email or password"
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    return_to = get_session(conn, :return_to) || ~p"/"

    conn
    |> clear_session()
    |> put_flash(:info, "You are now signed out")
    |> redirect(to: return_to)
  end
end
