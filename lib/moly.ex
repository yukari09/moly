defmodule Moly do
  @moduledoc """
  Moly keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  # def test() do
  #   require Ash.Query
  #   actor =
  #     Ash.get!(Moly.Accounts.User, "609e44e6-8080-4c42-ae52-36ecb190f2cf",
  #       context: %{private: %{ash_authentication?: true}}
  #     )

  #     data = %{
  #       post_content: "<p>The <strong>SiteGround Affiliate Program</strong> offers affiliates the chance to earn <strong>up to $100 per sale</strong> for referring new customers to SiteGround’s hosting services. SiteGround is well-known for its high-quality customer service and reliable hosting solutions. If you’re running a blog or website that focuses on web development or business, this program is an excellent opportunity for you. SiteGround offers affiliates marketing resources and analytics to help them track and optimize their performance.</p>",
  #       tags: [
  #         %{
  #           "name" => "affiliate marketing tips",
  #           "slug" => "affiliate-marketing-tips",
  #           "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
  #         },
  #         %{
  #           "name" => "content marketing",
  #           "slug" => "content-marketing",
  #           "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
  #         },
  #         %{
  #           "name" => "conversion rate",
  #           "slug" => "conversion-rate",
  #           "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
  #         },
  #         %{
  #           "name" => "saas affiliate",
  #           "slug" => "saas-affiliate",
  #           "term_taxonomy" => [%{"taxonomy" => "affiliate_tag"}]
  #         }
  #       ],
  #       post_date: ~U[2025-04-06 01:46:19.091794Z],
  #       post_excerpt: "<p>The <strong>SiteGround Affiliate Program</strong> offers affiliates the chance to earn <strong>up to $100 per sale</strong> for referring new customers to SiteGround’s hosting services. SiteGround is well-known for its high-quality customer service and reliable hosting solutions. If you’re running a blog or website that focuses on web development or business, this program is an excellent opportunity for you. SiteGround offers affiliates marketing resources and analytics to help them track and optimize their performance.</p>",
  #       post_meta: [
  #         %{
  #           meta_value: "Per sale of premium subscription",
  #           meta_key: :commission_notes_0
  #         },
  #         %{meta_value: "revenue_share", meta_key: :commission_type_0},
  #         %{meta_value: "%", meta_key: :commission_unit_0},
  #         %{meta_value: "25", meta_key: :commission_amount_0},
  #         %{
  #           meta_value: "Per new website builder subscription",
  #           meta_key: :commission_notes_1
  #         },
  #         %{meta_value: "bounty", meta_key: :commission_type_1},
  #         %{meta_value: "$", meta_key: :commission_unit_1},
  #         %{meta_value: "80", meta_key: :commission_amount_1},
  #         %{
  #           meta_value: "Per first purchase of service",
  #           meta_key: :commission_notes_2
  #         },
  #         %{meta_value: "bounty", meta_key: :commission_type_2},
  #         %{meta_value: "$", meta_key: :commission_unit_2},
  #         %{meta_value: "25", meta_key: :commission_amount_2},
  #         %{meta_value: "Global", meta_key: :region},
  #         %{meta_value: "https://www.x.com/1", meta_key: :affiliate_program_link},
  #         %{
  #           meta_value: "<h3>Eligibility:</h3><ul><li>Must have a niche website or blog.</li><li>Affiliates must have a professional presence online (e.g., LinkedIn or a personal brand).</li><li>Must provide a professional email address for payment and communication.</li></ul><h3>Prohibited Content:</h3><ul><li>No adult, gambling, or illegal content.</li><li>Cannot promote scams or misleading offers.</li></ul>",
  #           meta_key: :affiliate_signup_requirements
  #         },
  #         %{meta_value: "30", meta_key: :cookie_duration},
  #         %{meta_value: "24", meta_key: :duration_months},
  #         %{meta_value: "Skrill,Payoneer,Paypal", meta_key: :payment_method},
  #         %{meta_value: "100", meta_key: :min_payout_threshold},
  #         %{meta_value: "monthly", meta_key: :payment_cycle},
  #         %{meta_value: "USD", meta_key: :currency},
  #         %{
  #           meta_value: "e4c78455-0463-4752-9d42-8216f43766b7",
  #           meta_key: :attachment_affiliate_media_feature
  #         },
  #         %{
  #           meta_value: "e4c78455-0463-4752-9d42-8216f43766b7",
  #           meta_key: :attachment_affiliate_media
  #         }
  #       ],
  #       post_name: "QChVNuJVFDvC",
  #       post_status: :publish,
  #       post_title: "Zoho Affiliate Program - Earn 20% Recurring Commissions",
  #       post_type: :affiliate,
  #       categories: ["dd3934da-a166-4e29-829c-cca8859eed0b"]
  #     }

  #   # Ash.create(Moly.Contents.Post, data, actor: actor, action: :create_post)

  #   post = Ash.get!(Moly.Contents.Post, "320b80b8-e54a-409e-b845-9ef51f91a044", actor: actor)
  #   Ash.update(post, %{post_date: DateTime.utc_now}, actor: actor, action: :update_post)
  # end
end
