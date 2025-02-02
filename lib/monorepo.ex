defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def test() do
    require Ash.Query
    current_user = Ash.get!(Monorepo.Accounts.User, "8867319c-7951-4a59-b581-e5d4c6b751fe", context: %{private: %{ash_authentication?: true}})
    # new_user_meta_party = [%{"meta_key" => "description", "meta_value" => "test for update or insert"}]
    params = %{
      "categories" => ["a1590d06-d245-4e55-9e96-c1723c0f228d","e715145a-a215-42ab-9c09-5ad589c0b835"],
      "post_content" => "探索這些天然健康補充品，享受最佳健康效果！購買啟動！立即體驗！",
      "post_date" => "2025-02-02T08:22:16.577088Z",
      "post_meta" => %{
        "0" => %{"meta_key" => :commission_min, "meta_value" => "10"},
        "1" => %{"meta_key" => :commission_max, "meta_value" => "20"},
        "2" => %{"meta_key" => :commission_unit, "meta_value" => "%"},
        "3" => %{"meta_key" => :commission_model, "meta_value" => "CPC"},
        "4" => %{
          "meta_key" => :affiliate_link,
          "meta_value" => "https://www.youtube.com/watch?v=es9MaJPb_U8"
        },
        "5" => %{
          "meta_key" => :attachment_affiliate_media,
          "meta_value" => "2269f7a4-c2ed-42f7-bc15-fbea2e001be2"
        },
        "6" => %{
          "meta_key" => :attachment_affiliate_media_feature,
          "meta_value" => "2269f7a4-c2ed-42f7-bc15-fbea2e001be2"
        }
      },
      "post_title" => "超值健康補充品 - 10% 佣金",
      "post_type" => "affiliate"
    }
    current_user = %{
      current_user |
      roles: [:owner | current_user.roles]
    }
    # current_user = %{roles: current_user.rows}
    form = AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
      forms: [
        auto?: true
      ],
      actor: current_user
    ])
    |> Phoenix.Component.to_form()
    AshPhoenix.Form.submit(form, params: params)
  end



end
