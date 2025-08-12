defmodule Moly.GraphqlSchema do
  use Absinthe.Schema

  require Ash.Query

  import_types Absinthe.Plug.Types

  # Add your domains here
  use AshGraphql,
    domains: [Moly.Contents, Moly.Accounts, Moly.Terms]


  @privite_context [context: %{private: %{ash_authentication?: true}}]

  input_object :user_meta_input do
    field :meta_key, :string
    field :meta_value, :string
  end

  query do

    field :is_not_username_available, :boolean do
      description "Check the username available in user meta."
      arg :username, non_null(:string)

      resolve fn args, %{context: %{actor: _actor}} = _context ->
        username = args.username

        Ash.Query.new(Moly.Accounts.UserMeta)
        |> Ash.Query.filter(meta_value == ^username)
        |> Ash.exists()
      end
    end

    field :get_user_by_username, :user do
      description "Get user through user meta's meta key equal username."
      arg :username, non_null(:string)
      arg :secrect_key, non_null(:string)

      resolve fn args, _context ->
        if check_app_secrect(args) do
          Ash.Query.new(Moly.Accounts.User)
          |> Ash.Query.filter(user_meta.meta_key == "username" and user_meta.meta_value == ^args.username)
          |> Ash.Query.load([:user_meta])
          |> Ash.read_first(@privite_context)
        end
      end
    end
  end

  mutation do


    field :upload_media, :post do
      arg :file, non_null(:upload)

      resolve fn args, context ->
        %{context: %{actor: actor}} = context
        Moly.Helper.plug_upload_to_phoenix_liveview_upload_entry(args.file)
        |> Moly.Helper.create_media_post_by_entry(args.file.path, actor)
        |> case do
          :error -> {:error, "Failed to create media post"}
          {:ok, _, post} ->
            {:ok, post}
        end
      end
    end

    field :generate_confirm_token, :string do
      description "Generate token for user by purpose."
      arg :purpose, non_null(:string)

      resolve fn args, context ->
        purpose = String.to_atom(args.purpose) #:confirm_new_user
        %{context: %{actor: user}} = context

        subject = AshAuthentication.user_to_subject(user)
        strategy = AshAuthentication.Info.strategy!(Moly.Accounts.User, purpose)

        token_record =
          Ash.Query.new(Moly.Accounts.Token)
          |> Ash.Query.filter(subject == ^subject and purpose == ^purpose and expires_at > ^DateTime.utc_now())
          |> Ash.read_first(@privite_context)
          |> case do
            {:ok, maybe_exists} -> maybe_exists
            {:error, _} -> nil
          end

        token_lifetime =
          if token_record do
            Ash.destroy!(token_record, Keyword.merge(@privite_context, [action: :destory_token]))
            {DateTime.diff(token_record.expires_at, DateTime.utc_now()), :seconds}
          else
            strategy.token_lifetime
          end

        claims = %{"act" => strategy.confirm_action_name}

        {:ok, token, _claims} =
          AshAuthentication.Jwt.token_for_user(
            user,
            claims,
            Keyword.merge([], token_lifetime: token_lifetime)
          )

        Ash.create(Moly.Accounts.Token, %{
          extra_data: %{email: to_string(user.email)},
          purpose: purpose,
          token: token,
        }, Keyword.merge([action: :store_token], @privite_context))

        {:ok, token}
      end


    end


    field :generate_reset_token, :string do
      description "Generate reset password token."
      arg :email, non_null(:string)

      resolve fn args, _context ->
        email = args.email
        strategy = AshAuthentication.Info.strategy_for_action!(Moly.Accounts.User, :request_password_reset_with_password)

        user = Ash.Query.for_read(Moly.Accounts.User, :get_by_email, %{email: email}, @privite_context) |> Ash.read_one!()
        AshAuthentication.Strategy.Password.reset_token_for(strategy, user)
      end
    end

    field :verify_confirm_token, :user do
      description "Verify token."
      arg :token, non_null(:string)
      arg :purpose, non_null(:string)

      resolve fn args, _context ->
        token = args.token
        purpose = String.to_atom(args.purpose) #:confirm_new_user

        strategy = AshAuthentication.Info.strategy!(Moly.Accounts.User, purpose)

        case AshAuthentication.AddOn.Confirmation.Actions.confirm(strategy, %{"confirm" => token}, @privite_context) do
          {:ok, user} ->
            Ash.update!(user, %{status: :active, confirmed_at: DateTime.utc_now()}, Keyword.merge(@privite_context, [action: :update_user_status]))
            {:ok, user}
          {:error, _} ->
            {:error, nil}
        end
      end
    end

    field :reset_password_with_token, :user do
      description "Reset password by reset token."
      arg :reset_token, non_null(:string)
      arg :password, non_null(:string)
      arg :password_confirmation, non_null(:string)

      resolve fn args, _context ->
        strategy = AshAuthentication.Info.strategy_for_action!(Moly.Accounts.User, :password_reset_with_password)

        with {:ok, %{"sub" => subject}, _} <- AshAuthentication.Jwt.verify(args.reset_token, strategy.resource, []),
                {:ok, user} <- AshAuthentication.subject_to_user(subject, strategy.resource, []) do

          Ash.Changeset.for_update(user, :password_reset_with_password, %{
            reset_token: args.reset_token, password: args.password, password_confirmation: args.password_confirmation
          })
          |> Ash.update(@privite_context)
          |> case do
            {:error, _} -> {:error, nil}
            {:ok, user} -> {:ok,  user}
          end
        end
      end
    end

    field :update_user_meta, :user do
      description "Update current user meta"
      arg :user_meta, list_of(:user_meta_input)

      resolve fn args, context ->
        %{context: %{actor: actor}} = context
        user_meta = args.user_meta
        Ash.update(actor, %{user_meta: user_meta}, Keyword.merge(@privite_context, [action: :update_user_meta]))
      end
    end
  end


  defp check_app_secrect(args) do
    Map.get(args, :secrect_key) == Application.get_env(:moly, :app_secrect_key)
  end
end
