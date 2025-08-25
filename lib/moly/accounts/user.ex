defmodule Moly.Accounts.User do
  use Ash.Resource,
    otp_app: :moly,
    domain: Moly.Accounts,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshGraphql.Resource],
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  authentication do
    tokens do
      enabled?(true)
      token_resource(Moly.Accounts.Token)
      signing_secret(Moly.Secrets)
    end

    strategies do
      password :password do
        identity_field(:email)
        sign_in_token_lifetime(3600*24*30)
        require_confirmed_with :confirmed_at
        session_identifier :jti
        resettable do
          sender(Moly.Accounts.User.Senders.SendPasswordResetEmail)
        end
      end

      google do
        client_id(Moly.Secrets)
        redirect_uri(Moly.Secrets)
        client_secret(Moly.Secrets)
        icon(:google)
      end
    end

    add_ons do
      #Disabled
      confirmation :confirm_new_user do
        monitor_fields([:email])
        confirm_on_create?(true)
        confirm_on_update?(false)
        require_interaction?(true)
        sender(Moly.Accounts.User.Senders.SendNewUserConfirmationEmail)
      end
    end
  end

  postgres do
    table "users"
    repo(Moly.Repo)
  end

  # multitenancy do
  #   strategy :attribute
  # end

  actions do
    read :read do
      primary? true
      prepare build(sort: [inserted_at: :desc])

      pagination do
        required? false
        offset? true
        keyset? true
        countable true
      end
    end

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject

      prepare fn query, _context ->
        query
        |> Ash.Query.load([:user_meta])
      end
    end

    read :sign_in_with_password do
      description "Attempt to sign in using a email and password."
      get? true

      argument :email, :ci_string do
        description "The email to use for retrieving the user."
        allow_nil? false
      end

      argument :password, :string do
        description "The password to check for the matching user."
        allow_nil? false
        sensitive? true
      end

      argument :agreement, :string do
        description "The agreement to the terms of service."
        allow_nil? false
      end

      # validates the provided email and password and generates a token
      prepare AshAuthentication.Strategy.Password.SignInPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
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

      description "Attempt to sign in using a short-lived sign in token."
      get? true

      argument :token, :string do
        description "The short-lived sign in token."
        allow_nil? false
        sensitive? true
      end

      # validates the provided sign in token and generates a token
      prepare AshAuthentication.Strategy.Password.SignInWithTokenPreparation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    create :register_with_password do
      description "Register a new user with a email and password."

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      argument :agreement, :string do
        description "The agreement to the terms of service."
        allow_nil? false
      end

      change before_action(fn %{arguments: %{email: email}} = changeset, _context ->
               user_meta = register_relation_user_meta(email)
               Ash.Changeset.manage_relationship(changeset, :user_meta, user_meta, type: :create)
             end)

      # Sets the email from the argument
      change set_attribute(:email, arg(:email))

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
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

      change after_action(fn changeset, user, context ->
               case user.confirmed_at do
                 nil ->
                   {:error, "Unconfirmed user exists already"}

                 _ ->
                   if DateTime.diff(DateTime.utc_now(), user.inserted_at) < 2 do
                     user_info = Ash.Changeset.get_argument(changeset, :user_info)
                     user_meta = register_relation_user_meta(user_info)

                     Ash.update(user, %{user_meta: user_meta},
                       action: :update_user_meta,
                       return_errors?: true,
                       context: %{private: %{ash_authentication?: true}}
                     )
                   end

                   {:ok, user}
               end
             end)
    end

    create :create_manually do
      description "Create a new user using the admin interface"

      argument :email, :string do
        allow_nil? false

        constraints trim?: true,
                    allow_empty?: false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :roles, {:array, :atom} do
        allow_nil? false
        default [:user]
      end

      argument :confirmed_at, :datetime do
        allow_nil? true
      end

      argument :status, :atom do
        default :inactive
        constraints one_of: [:active, :inactive, :deleted]
      end

      validate match(:email, ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/) do
        message "must be a valid email address"
      end

      change set_context(%{strategy_name: :password})
      change AshAuthentication.Strategy.Password.HashPasswordChange
      change set_attribute(:status, arg(:status))
      change set_attribute(:roles, arg(:roles))
      change set_attribute(:email, arg(:email))
      change set_attribute(:confirmed_at, arg(:confirmed_at))

      change before_action(fn %{arguments: %{email: email}} = changeset, _context ->
               user_meta = register_relation_user_meta(email)
               Ash.Changeset.manage_relationship(changeset, :user_meta, user_meta, type: :create)
             end)
    end

    action :request_password_reset_with_password do
      description "Send password reset instructions to a user if they exist."

      argument :email, :ci_string do
        allow_nil? false
      end

      argument :agreement, :string do
        description "The agreement to the terms of service."
        allow_nil? false
      end

      # creates a reset token and invokes the relevant senders
      run {AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email}
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get? true

      argument :email, :ci_string do
        allow_nil? false
      end

      filter expr(email == ^arg(:email))
    end

    update :password_reset_with_password do
      argument :reset_token, :string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      # validates the provided reset token
      validate AshAuthentication.Strategy.Password.ResetTokenValidation

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange
    end


    update :update_user_status do
      description "Update the status of a user to active"

      accept [:confirmed_at]

      argument :status, :atom do
        allow_nil? false
        constraints one_of: [:active, :inactive, :deleted]
      end

      change set_attribute(:status, arg(:status))
    end

    update :update_user_meta do
      require_atomic? false

      argument :user_meta, {:array, :map} do
        allow_nil? false
      end

      change manage_relationship(:user_meta, :user_meta,
               on_lookup: :relate,
               on_no_match: :create,
               on_match: :update,
               use_identities: [:meta_key_with_user_id]
             )
    end

    update :update, primary?: true
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy always() do
      forbid_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? true
      sensitive? true
    end

    attribute :roles, {:array, :atom} do
      allow_nil? false
      default [:user]
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :inactive
      constraints one_of: [:active, :inactive, :deleted]
      public? true
    end

    timestamps(public?: true)
  end

  calculations do
    # calculate :avatar, :string, expr(
    #   first(:user_meta, field: :meta_value, query: [filter: expr(meta_key == "avatar")])
    # ), public?: true
    # calculate :name, :string, expr(
    #   first(:user_meta, field: :meta_value, query: [filter: expr(meta_key == "name")])
    # ), public?: true
    # calculate :username, :string, expr(
    #   first(:user_meta, field: :meta_value, query: [filter: expr(meta_key == "username")])
    # ), public?: true
  end

  relationships do
    has_many :posts, Moly.Contents.Post, destination_attribute: :author_id
    has_many :user_meta, Moly.Accounts.UserMeta, public?: true
    has_many :comments, Moly.Comments.Comment, destination_attribute: :comment_author_id
    has_many :post_actions, Moly.Accounts.UserPostAction
  end

  identities do
    identity :unique_email, [:email]
  end

  graphql do
    type :user
  end

  defp register_relation_user_meta(email_or_user_info) do
    [name, username, avatar] =
      case email_or_user_info do
        %Ash.CiString{} ->
          email = Ash.CiString.value(email_or_user_info)
          name = extract_name_from_email(email)
          username = "#{name}#{Moly.Helper.generate_random_id(2)}"
          [name, username, nil]

        email_or_user_info when is_map(email_or_user_info) ->
          name = email_or_user_info["name"]
          username = email_or_user_info["name"] |> String.replace(" ", "")
          username = username <> Moly.Helper.generate_random_id(2)

          avatar =
            Moly.Utilities.Account.generate_avatar_from_url(email_or_user_info["picture"])

          [name, username, avatar]

        email_or_user_info when is_binary(email_or_user_info) ->
          name = extract_name_from_email(email_or_user_info)
          [name, name, nil]
      end

    [
      %{meta_key: :name, meta_value: name},
      %{meta_key: :username, meta_value: username},
      %{meta_key: :avatar, meta_value: avatar}
    ]
  end

  defp extract_name_from_email(email),
    do: email |> to_string() |> String.split("@") |> List.first()
end
