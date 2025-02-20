defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """



  def t() do

    actor = Ash.get!(Monorepo.Accounts.User, "c111ac40-5b95-424d-92ff-16286f209acb", context: %{private: %{ash_authentication?: true}})

    post =
      Ash.get!(Monorepo.Contents.Post, "a668e623-c7c4-4826-9c6e-077e6c27de77", actor: %{roles: [:admin]})
      |> Ash.load!([:post_meta, :post_categories, :post_tags],
        actor: %{roles: [:admin]}
      )

    params =  %{"categories" => ["fbc0244e-6d61-43d9-8902-12c717475a44", "dcf63611-0920-4b63-b842-323772cc8413", "346f9639-5ea7-4153-9e32-33434b40948a"], "guid" => "http://localhost:4000/p/Ivo-BhUbJsHP", "post_content" => "{\"time\":1739671394204,\"blocks\":[{\"id\":\"kZ8TBNjOWZ\",\"type\":\"paragraph\",\"data\":{\"text\":\"Step into the picturesque paradise of Kamakura, Japan, where pristine beaches meet immaculate residential streets. \"}},{\"id\":\"i_LVngN4Qs\",\"type\":\"paragraph\",\"data\":{\"text\":\"Join us on a captivating walking tour as we explore the stunning scenery and charming neighbourhoods that define this coastal town of Kanagawa. \"}},{\"id\":\"MDKx-mj-iw\",\"type\":\"paragraph\",\"data\":{\"text\":\"From the crystal-clear waters of the beach to the perfectly manicured houses lined with cherry blossoms, Kamakura is a visual delight at every turn. \"}},{\"id\":\"UeoL7Bxmgq\",\"type\":\"paragraph\",\"data\":{\"text\":\"Discover the beauty of Japan's coastal gem and immerse yourself in its serene landscapes as the Enoden Train rushes through the alleyways and cuts through the village streets. \"}}],\"version\":\"2.30.7\"}", "post_date" => "2025-02-18T02:02:00Z", "post_excerpt" => "Step into the picturesque paradise of Kamakura, Japan, where pristine beaches meet immaculate residential streets.", "post_meta" => %{"0" => %{"meta_key" => "thumbnail_id", "meta_value" => "df747756-a356-4e58-b52c-5428b6b9b56a"}, "1" => %{"meta_key" => "comments_open", "meta_value" => "1"}}, "post_name" => "Ivo-BhUbJsHP", "post_status" => "publish", "post_title" => "4K Japan Seaside Village Walk - Kamakura Enoden Train Line Kanagawa Suburbs Walking Tour | HDR 60fps", "tags" => %{"0" => %{"name" => "方舟子", "term_taxonomy" => [%{"taxonomy" => "eeebf9db-a4ba-42fe-928b-c444151f4b89"}]}}}

    Ash.update(post, params, action: :update_post, actor: actor)
  end
end
