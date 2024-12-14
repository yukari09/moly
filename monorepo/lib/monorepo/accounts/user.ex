defmodule Monorepo.Accounts.User do
  use Ash.Resource,
    otp_app: :monorepo,
    domain: Monorepo.Accounts,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication],
    data_layer: AshPostgres.DataLayer

  authentication do
    tokens do
      enabled?(true)
      token_resource(Monorepo.Accounts.Token)
      signing_secret(Monorepo.Secrets)
    end

    strategies do
      password :password do
        identity_field(:email)

        resettable do
          sender(Monorepo.Accounts.User.Senders.SendPasswordResetEmail)
        end
      end
      google do
        client_id Monorepo.Secrets
        redirect_uri Monorepo.Secrets
        client_secret Monorepo.Secrets
      end
    end

    add_ons do
      confirmation :confirm_new_user do
        monitor_fields([:email])
        confirm_on_create?(true)
        confirm_on_update?(false)
        auto_confirm_actions([:sign_in_with_magic_link, :reset_password_with_password])
        sender(Monorepo.Accounts.User.Senders.SendNewUserConfirmationEmail)
      end
    end
  end

  postgres do
    table("users")
    repo(Monorepo.Repo)
  end

  actions do
    defaults([:read])

    read :get_by_subject do
      description("Get a user by the subject claim in a JWT")
      argument(:subject, :string, allow_nil?: false)
      get?(true)
      prepare(AshAuthentication.Preparations.FilterBySubject)
    end

    read :sign_in_with_password do
      description("Attempt to sign in using a email and password.")
      get?(true)

      argument :email, :ci_string do
        description("The email to use for retrieving the user.")
        allow_nil?(false)
      end

      argument :password, :string do
        description("The password to check for the matching user.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided email and password and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    read :sign_in_with_token do
      # In the generated sign in components, we validate the
      # email and password directly in the LiveView
      # and generate a short-lived token that can be used to sign in over
      # a standard controller action, exchanging it for a standard token.
      # This action performs that exchange. If you do not use the generated
      # liveviews, you may remove this action, and set
      # `sign_in_tokens_enabled? false` in the password strategy.

      description("Attempt to sign in using a short-lived sign in token.")
      get?(true)

      argument :token, :string do
        description("The short-lived sign in token.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided sign in token and generates a token
      prepare(AshAuthentication.Strategy.Password.SignInWithTokenPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    create :register_with_password do
      description("Register a new user with a email and password.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # Sets the email from the argument
      change(set_attribute(:email, arg(:email)))

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    create :register_with_google do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :unique_email

      change AshAuthentication.GenerateTokenChange

      # Required if you have the `identity_resource` configuration enabled.
      change AshAuthentication.Strategy.OAuth2.IdentityChange

      change fn changeset, _ ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)

        Ash.Changeset.change_attributes(changeset, Map.take(user_info, ["email"]))
      end

      # Required if you're using the password & confirmation strategies
      upsert_fields []
      change set_attribute(:confirmed_at, &DateTime.utc_now/0)
      change after_action(fn _changeset, user, _context ->
        case user.confirmed_at do
          nil -> {:error, "Unconfirmed user exists already"}
          _ -> {:ok, user}
        end
      end)
    end

    action :request_password_reset_with_password do
      description("Send password reset instructions to a user if they exist.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      # creates a reset token and invokes the relevant senders
      run({AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email})
    end

    read :get_by_email do
      description("Looks up a user by their email")
      get?(true)

      argument :email, :ci_string do
        allow_nil?(false)
      end

      filter(expr(email == ^arg(:email)))
    end

    update :password_reset_with_password do
      argument :reset_token, :string do
        allow_nil?(false)
        sensitive?(true)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      # validates the provided reset token
      validate(AshAuthentication.Strategy.Password.ResetTokenValidation)

      # validates that the password matches the confirmation
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      # Hashes the provided password
      change(AshAuthentication.Strategy.Password.HashPasswordChange)

      # Generates an authentication token for the user
      change(AshAuthentication.GenerateTokenChange)
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end

    policy always() do
      forbid_if(always())
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :ci_string do
      allow_nil?(false)
      public?(true)
    end

    attribute :hashed_password, :string do
      allow_nil?(true)
      sensitive?(true)
    end
  end

  identities do
    identity(:unique_email, [:email])
  end

end
