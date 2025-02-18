defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def t1() do
    require Ash.Query
    opts = [
      actor: %{roles: [:user]},
      context: %{private: %{ash_authentication?: true}}
    ]

    post =
      Ash.get!(Monorepo.Contents.Post, "b10e5e6c-5ff5-4b26-9eae-6f45e141bc57", opts)
      |> Ash.load!([:post_categories, :post_tags, author: :user_meta, post_meta: :children], opts)


    Monorepo.Utilities.MetaValue.post_images(post, :attachment_affiliate_media, ["xlarge", "large", "medium"])
  end

  # def test() do
    # require Ash.Query
    # alias AshAuthentication.{Info, Jwt}

    # user =
    #   Ash.get!(Monorepo.Accounts.User, "8bb78136-7cfe-4611-a346-a043b4102f4e",
    #     context: %{private: %{ash_authentication?: true}}
    #   )

    # new_user_meta_party = [%{"meta_key" => "description", "meta_value" => "test for update or insert"}]
    # params = %{
    #   "categories" => ["a1590d06-d245-4e55-9e96-c1723c0f228d","e715145a-a215-42ab-9c09-5ad589c0b835"],
    #   "post_content" => "探索這些天然健康補充品，享受最佳健康效果！購買啟動！立即體驗！",
    #   "post_date" => "2025-02-02T08:22:16.577088Z",
    #   "post_meta" => %{
    #     "0" => %{"meta_key" => :commission_min, "meta_value" => "10"},
    #     "1" => %{"meta_key" => :commission_max, "meta_value" => "20"},
    #     "2" => %{"meta_key" => :commission_unit, "meta_value" => "%"},
    #     "3" => %{"meta_key" => :commission_model, "meta_value" => "CPC"},
    #     "4" => %{
    #       "meta_key" => :affiliate_link,
    #       "meta_value" => "https://www.youtube.com/watch?v=es9MaJPb_U8"
    #     },
    #     "5" => %{
    #       "meta_key" => :attachment_affiliate_media,
    #       "meta_value" => "2269f7a4-c2ed-42f7-bc15-fbea2e001be2"
    #     },
    #     "6" => %{
    #       "meta_key" => :attachment_affiliate_media_feature,
    #       "meta_value" => "2269f7a4-c2ed-42f7-bc15-fbea2e001be2"
    #     }
    #   },
    #   "post_title" => "超值健康補充品 - 10% 佣金",
    #   "post_type" => "affiliate"
    # }
    # current_user = %{
    #   current_user |
    #   roles: [:owner | current_user.roles]
    # }
    # # current_user = %{roles: current_user.rows}
    # form = AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
    #   forms: [
    #     auto?: true
    #   ],
    #   actor: current_user
    # ])
    # |> Phoenix.Component.to_form()
    # AshPhoenix.Form.submit(form, params: params)

    # claims = %{"act" => "confirm_new_user"}
    # {:ok, strategy} = AshAuthentication.Info.strategy(Monorepo.Accounts.User, :confirm_new_user)
    # {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(current_user, claims, token_lifetime: strategy.token_lifetime)

    # {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(current_user, %{"purpose" => "confirm_user_email"})
    # Monorepo.Accounts.User.Senders.SendNewUserConfirmationEmail.send(current_user, token, nil)

    # Ash.update(current_user, %{updated_at:  DateTime.utc_now()}, action: :resend_confirmation, context: %{private: %{ash_authentication?: true}})
    # IO.puts(:ok)

    # token =
    #   Monorepo.Accounts.Token
    #   |> Ash.Query.filter(subject == ^"user?id=#{user.id}" and purpose == "confirm_new_user" and expires_at > now())
    #   |> Ash.Query.limit(1)
    #   |> Ash.read_one(context: %{private: %{ash_authentication?: true}})
    #   |> case do
    #     {:ok, nil} ->
    #       claims = %{"act" => "confirm_new_user"}
    #       {:ok, strategy} = AshAuthentication.Info.strategy(Monorepo.Accounts.User, :confirm_new_user)
    #       {:ok, token, _} = AshAuthentication.Jwt.token_for_user(user, claims, token_lifetime: strategy.token_lifetime)
    #       Ash.create(Monorepo.Accounts.Token, %{extra_data: %{email: user.email}, purpose: "confirm_new_user", token: token}, action: :store_token, context: %{private: %{ash_authentication?: true}})
    #       token
    #     {:ok, user_token} ->
    #       claims = %{"act" => user_token.purpose, "jti" => user_token.jti, "sub" => user_token.subject}
    #       {:ok, strategy} = AshAuthentication.Info.strategy(Monorepo.Accounts.User, :confirm_new_user)
    #       {:ok, token, _} = AshAuthentication.Jwt.token_for_user(user, claims, token_lifetime: strategy.token_lifetime)
    #       token
    #   end

    # token

    # |> case do
    #   {:ok, nil} ->
    #     {:ok, strategy} = AshAuthentication.Info.strategy(Monorepo.Accounts.User, :confirm_new_user)
    #     {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(current_user, claims, token_lifetime: strategy.token_lifetime)
    #   {:ok, token} ->
    #     AshAuthentication.Jwt.token_for_resource(current_user, claims)
    # end
    # Monorepo.Accounts.User
    # |> Ash.read(action: :resend_confirmation)

    # Ash.update(user, %{updated_at: DateTime.utc_now()},
    #   action: :resend_confirmation,
    #   context: %{private: %{ash_authentication?: true}}
    # )

    # {:ok, user} =
    # Monorepo.Accounts.User
    # |> Ash.ActionInput.for_action(:resend_confirmation, %{email: user.email}, context: %{private: %{ash_authentication?: true}})
    # |> Ash.run_action()
  # end
end
