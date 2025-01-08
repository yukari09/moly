defmodule Monorepo do
  @moduledoc """
  Monorepo keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  def test() do
    current_user = Ash.get!(Monorepo.Accounts.User, "d0faba77-88b2-4edc-b358-dbf6419a7351", context: %{private: %{ash_authentication?: true}})
  #   # post = Ash.get!(Monorepo.Contents.Post, "03331276-0138-4ec3-add7-0cfb71b68623", actor: current_user)

  #   # # Monorepo.Contents.create_meta(%{meta_key: :test, meta_value: "test", post: post})
  #   # # |> Ash.Changeset.manage_relationship(:post, post)

  #   # Monorepo.Contents.PostMeta
  #   # |> Ash.Changeset.for_create(:create, %{meta_key: :test, meta_value: "test"})
  #   # |> Ash.Changeset.manage_relationship(:post, post, type: :append_and_remove)
  #   # |> Ash.create!(actor:  current_user)

  #   # IO.puts("Hello, World!")

    # form =
    #   AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
    #     forms: [
    #       post_meta: [
    #         type: :list,
    #         resource: Monorepo.Contents.PostMeta,
    #         update_action: :update,
    #         create_action: :create_post_meta
    #       ],
    #       # term_taxonomy: [
    #       #   type: :list,
    #       #   data: [],
    #       #   resource: Monorepo.Terms.TermTaxonomy,
    #       #   update_action: :update,
    #       #   create_action: :create
    #       # ],
    #       term_taxonomy_tags: [
    #         type: :list,
    #         data: [],
    #         resource: Monorepo.Terms.Term,
    #         update_action: :update,
    #         create_action: :create
    #       ]
    #     ]
    #   ])
    #   # |> AshPhoenix.Form.add_form([:term_taxonomy_tags])
    #   |> AshPhoenix.Form.add_form([:term_taxonomy])
    #   |> Phoenix.Component.to_form()


    # params =  %{"categories_term_relationships" => %{"0" => %{"term_order" => "0"}, "1" => %{"term_order" => "1"}, "2" => %{"term_order" => "2", "term_taxonomy_id" => "f613753d-23c6-4a3e-aa59-0a8ed849621a"}, "3" => %{"term_order" => "3", "term_taxonomy_id" => "b8ac451f-b122-4c0d-b709-6c1f3278d49b"}, "4" => %{"term_order" => "4"}}, "guid" => "http://192.168.6.8:4000/p/jlHIMQaV", "post_content" => "{\"time\":1736307000776,\"blocks\":[{\"id\":\"lzVYy5dv-s\",\"type\":\"header\",\"data\":{\"text\":\"Start Writing Your New Article\",\"level\":2}},{\"id\":\"OZknf7w4jz\",\"type\":\"paragraph\",\"data\":{\"text\":\"This is the starting point of your article. You can begin writing or use the toolbar to add more content blocks.\"}},{\"id\":\"lmwVTBMrPb\",\"type\":\"header\",\"data\":{\"text\":\"Article Outline\",\"level\":3}},{\"id\":\"J5R5gEjM65\",\"type\":\"list\",\"data\":{\"style\":\"unordered\",\"meta\":{},\"items\":[{\"content\":\"First point\",\"meta\":{},\"items\":[]},{\"content\":\"Second point\",\"meta\":{},\"items\":[]},{\"content\":\"Third point\",\"meta\":{},\"items\":[]}]}},{\"id\":\"Xi1WtMxCSP\",\"type\":\"quote\",\"data\":{\"text\":\"Writing is an exploration. You start from nothing and learn as you go.\",\"caption\":\"E.L. Doctorow\",\"alignment\":\"left\"}},{\"id\":\"Nz1-R9ohif\",\"type\":\"header\",\"data\":{\"text\":\"efsfsdfsdf\",\"level\":1}}],\"version\":\"2.30.7\"}", "post_date" => "2025-01-08T03:45:51Z", "post_excerpt" => "", "post_meta" => %{"1" => %{"meta_key" => "comments_open", "meta_value" => "1"}}, "post_name" => "/#{Monorepo.Helper.generate_random_str(8)}", "post_status" => "draft", "post_title" => "Start Writing Your New Article"}

    # AshPhoenix.Form.submit(form, params: params, action_opts: [actor: current_user])

    params = %{
      "guid" => "http://192.168.6.8:4000/p/pxTAziow",
      "post_content" => "{\"time\":1736320825343,\"blocks\":[{\"id\":\"lzVYy5dv-s\",\"type\":\"header\",\"data\":{\"text\":\"Start Writing Your New Article\",\"level\":2}},{\"id\":\"OZknf7w4jz\",\"type\":\"paragraph\",\"data\":{\"text\":\"This is the starting point of your article. You can begin writing or use the toolbar to add more content blocks.\"}},{\"id\":\"lmwVTBMrPb\",\"type\":\"header\",\"data\":{\"text\":\"Article Outline\",\"level\":3}},{\"id\":\"J5R5gEjM65\",\"type\":\"list\",\"data\":{\"style\":\"unordered\",\"meta\":{},\"items\":[{\"content\":\"First point\",\"meta\":{},\"items\":[]},{\"content\":\"Second point\",\"meta\":{},\"items\":[]},{\"content\":\"Third point\",\"meta\":{},\"items\":[]}]}},{\"id\":\"Xi1WtMxCSP\",\"type\":\"quote\",\"data\":{\"text\":\"Writing is an exploration. You start from nothing and learn as you go.sdf\",\"caption\":\"E.L. Doctsorow\",\"alignment\":\"left\"}},{\"id\":\"Nz1-R9ohif\",\"type\":\"header\",\"data\":{\"text\":\"efsfsdf\",\"level\":1}}],\"version\":\"2.30.7\"}",
      "post_date" => "2025-01-08T07:25:40Z",
      "post_excerpt" => "",
      "post_meta" => %{"1" => %{"meta_key" => "comments_open", "meta_value" => "1"}},
      "post_name" => "/#{Monorepo.Helper.generate_random_str(8)}",
      "post_status" => "draft",
      "post_title" => "Start Writing Your New Article",
      "term_taxonomy" => ["b8ac451f-b122-4c0d-b709-6c1f3278d49b"]
    }

    form =
      AshPhoenix.Form.for_create(Monorepo.Contents.Post, :create_post, [
        forms: [
          post_meta: [
            type: :list,
            resource: Monorepo.Contents.PostMeta,
            data: [],
            update_action: :update,
            create_action: :create_post_meta
          ]
        ],
        actor: current_user
      ])

    AshPhoenix.Form.submit(form, params: params, action_opts: [actor: current_user])
  end


end
