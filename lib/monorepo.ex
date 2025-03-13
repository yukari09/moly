defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def t() do
    actor =
      Ash.get!(Monorepo.Accounts.User, "d5f63c95-61d4-459b-9a47-de568f236160",
        context: %{private: %{ash_authentication?: true}}
      )

    params = %{
      "categories" => %{
        "0" => "8d21c7e7-74e9-435f-82eb-54cbebcd546e",
        "1" => "0474a5b1-fef5-43c3-a658-b7a809369a36"
      },
      "post_content" =>
        "<p>Join the affiliate program and start earning passive income with ease! Promote products through your affiliate link and earn a <strong>15% recurring commission</strong> on every purchase made through your referral. No investment is required, and there is no cap on how much you can earn. Share your affiliate link, and when it leads to a purchase, you get rewarded. Plus, you can withdraw your commission to your bank account or account balance anytime. Get started today and turn your referrals into a steady income stream. The affiliate commission is effective after the order cycle ends in U.S. time.</p>",
      "post_date" => "2025-02-22T23:58:23.526785Z",
      "post_meta" => %{
        "1" => %{"meta_key" => "commission_min", "meta_value" => "10"},
        "10" => %{
          "meta_key" => "attachment_affiliate_media",
          "meta_value" => "5fc958c9-b70c-4558-9a4c-c6dacb598e44"
        },
        "11" => %{
          "meta_key" => "attachment_affiliate_media_feature",
          "meta_value" => "5fc958c9-b70c-4558-9a4c-c6dacb598e44"
        },
        "2" => %{"meta_key" => "commission_max", "meta_value" => "30"},
        "3" => %{"meta_key" => "commission_unit", "meta_value" => "%"},
        "4" => %{"meta_key" => "commission_model", "meta_value" => "CPC"},
        "5" => %{
          "meta_key" => "affiliate_link",
          "meta_value" => "https://www.raksmart.com/reseller/affiliates.html"
        },
        "6" => %{"meta_key" => "cookie_duration", "meta_value" => "30"}
      },
      "post_name" => "cXpEmwTvrWiS",
      "post_status" => "pending",
      "post_title" =>
        "Become an Affiliate: Earn 30% Recurring Commission on Purchases – No Investment, No Cap!",
      "post_type" => "affiliate",
      "tags" => %{
        "0" => %{
          "name" => "affiliate program",
          "slug" => "affiliate-program",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "1" => %{
          "name" => "earn money",
          "slug" => "earn-money",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "2" => %{
          "name" => "recurring commission",
          "slug" => "recurring-commission",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "3" => %{
          "name" => "no investment required",
          "slug" => "no-investment-required",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "4" => %{
          "name" => "free to join",
          "slug" => "free-to-join",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "5" => %{
          "name" => "passive income",
          "slug" => "passive-income",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "6" => %{
          "name" => "affiliate marketing",
          "slug" => "affiliate-marketing",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "7" => %{
          "name" => "earn online",
          "slug" => "earn-online",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "8" => %{
          "name" => "affiliate link",
          "slug" => "affiliate-link",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        },
        "9" => %{
          "name" => "referral program",
          "slug" => "referral-program",
          "term_taxonomy" => [%{"taxonomy" => "post_tag"}]
        }
      }
    }

    actor = Map.put(actor, :roles, [:user, :admin])

    Ash.create(Monorepo.Contents.Post, params, actor: actor, action: :create_post)
  end
end
