defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def test() do
    actor =
      Ash.get!(Moly.Accounts.User, "aeaa6a0b-1d33-4146-a7e2-11553705ceba",
        context: %{private: %{ash_authentication?: true}}
      )

    params = %{
      "categories" => %{"0" => "448c9b12-5d2a-4459-8b26-7080fb704069"},
      "post_content" => "<p>Brevo Affiliate Program</p>",
      "post_meta" => %{
        "10" => %{
          "meta_key" => "affiliate_program_link",
          "meta_value" => "https://www.brevo.com/affiliates/"
        },
        "11" => %{"meta_key" => "region", "meta_value" => "Global"},
        "12" => %{
          "meta_key" => "affiliate_signup_requirements",
          "meta_value" => "<p>Brevo Affiliate Program</p>"
        },
        "13" => %{
          "0" => %{"meta_key" => "commission_type", "meta_value" => "bounty"},
          "1" => %{"meta_key" => "commission_amount", "meta_value" => "5"},
          "2" => %{"meta_key" => "commission_unit", "meta_value" => "USD"},
          "3" => %{"meta_key" => "commission_notes", "meta_value" => "免費註冊"}
        },
        "14" => %{
          "0" => %{"meta_key" => "commission_type", "meta_value" => "bounty"},
          "1" => %{"meta_key" => "commission_amount", "meta_value" => "10"},
          "2" => %{"meta_key" => "commission_unit", "meta_value" => "USD"},
          "3" => %{"meta_key" => "commission_notes", "meta_value" => "付費訂閱"}
        },
        "15" => %{
          "0" => %{"meta_key" => "commission_type", "meta_value" => "revenue_share"},
          "1" => %{"meta_key" => "commission_amount", "meta_value" => "20"},
          "2" => %{"meta_key" => "commission_unit", "meta_value" => "%"},
          "3" => %{"meta_key" => "commission_notes", "meta_value" => ""}
        },
        "4" => %{"meta_key" => "cookie_duration", "meta_value" => "90"},
        "5" => %{"meta_key" => "duration_months", "meta_value" => "12"},
        "6" => %{"meta_key" => "payment_method", "meta_value" => "Paypal,Bank Transfer"},
        "7" => %{"meta_key" => "min_payout_threshold", "meta_value" => "100"},
        "8" => %{"meta_key" => "payment_cycle", "meta_value" => "monthly"},
        "9" => %{"meta_key" => "currency", "meta_value" => "EUR"}
      },
      "post_tags" => "Brevo Affiliate Program",
      "post_title" => "Brevo Affiliate Program"
    }

    post_meta = Map.get(params, "post_meta")

    new_post_meta =
      Enum.reduce(post_meta, [], fn
        {k, %{"0" => v0, "1" => v1, "2" => v2} = commission}, a1 ->
          reduce_map = [v0, v1, v2]

          reduce_map =
            if Map.has_key?(commission, "3") do
              v3 = Map.get(commission, "3")
              [v3 | reduce_map]
            else
              reduce_map
            end

          Enum.reduce(reduce_map, a1, fn %{
                                           "meta_key" => meta_key,
                                           "meta_value" => meta_value
                                         },
                                         a2 ->
            [%{"meta_key" => String.to_atom("#{meta_key}_#{k}"), "meta_value" => meta_value} | a2]
          end)

        {_, v}, a1 ->
          [v | a1]
      end)

    new_post_meta =
      Enum.with_index(new_post_meta)
      |> Enum.reduce(%{}, &Map.put(&2, "#{elem(&1, 1)}", elem(&1, 0)))

    params = Map.put(params, "post_meta", new_post_meta)
    params = Map.put(params, "post_status", "pending")
    params = Map.put(params, "post_name", Moly.Helper.generate_random_str())

    post_excerpt =
      Floki.parse_document!(params["post_content"]) |> Floki.text() |> String.slice(0..255)

    params = Map.put(params, "post_excerpt", post_excerpt)
    params = Map.put(params, "post_date", DateTime.utc_now())

    post_tags =
      Map.get(params, "post_tags")
      |> String.split(",")
      |> Enum.map(fn name ->
        name = String.trim(name)
        slug = Moly.Helper.string2slug(name)

        %{
          "name" => name,
          "slug" => slug,
          "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
        }
      end)

    params = Map.put(params, "tags", post_tags)
    params = Map.delete(params, "post_tags")

    actor = Map.put(actor, :roles, [:owner])


    Ash.create(Moly.Contents.Post, params, action: :create_post, actor: actor)
  end
end
