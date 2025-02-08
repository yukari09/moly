defmodule MonorepoWeb.Affiliate.UserPage do
  use MonorepoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event(
        "partial_update",
        %{"_target" => ["user_meta", i, _], "user_meta" => user_meta},
        socket
      ) do
    updated_user_meta = user_meta[i]
    meta_key = String.to_atom(updated_user_meta["meta_key"])
    meta_value = updated_user_meta["meta_value"]

    old_meta_value =
      Monorepo.Accounts.Helper.load_meta_value_by_meta_key(socket.assigns.current_user, meta_key)

    socket =
      if old_meta_value != meta_value do
        new_user_meta_party = [%{meta_key: meta_key, meta_value: meta_value}]
        changeset = Ash.Changeset.new(socket.assigns.current_user)

        result =
          Ash.update(changeset, %{user_meta: new_user_meta_party},
            action: :update_user_meta,
            context: %{private: %{ash_authentication?: true}}
          )

        case result do
          {:ok, new_current_user} ->
            put_flash(socket, :info, "Your information has been updated.")
            |> assign(:current_user, new_current_user)

          {:error, _} ->
            put_flash(socket, :error, "Your information update failed, please try again later")
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="relative min-h-[200px] bg-primary">
        <a class="btn btn-sm rounded-md absolute top-2 right-2 px-2"><.icon name="hero-pencil-solid" class="size-4 text-gray-500" /></a>
      </div>
      <div class="px-4 -mt-12">
          <div class="avatar" role="button">
            <div class="size-24 rounded-full" :if={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)}>
              <img src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)["128"]} />
            </div>
          </div>
          <div class="avatar placeholder" :if={!Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)}>
            <div class="bg-primary text-base-100 size-24 rounded-full border-base-200 border-4">
                <span class="capitalize text-5xl">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) |> String.slice(0, 1)}</span>
            </div>
          </div>
      </div>
      <form phx-change="partial_update">
      <div class="flex items-start gap-8">
        <div class="w-80 py-4 px-2">
          <div class="text-2xl px-4 text-gray-900">
            <p><%= Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) %></p>
            <p class="text-xs/8">@{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :username)}</p>
          </div>
          <div class="space-y-3 mb-12">
            <div>
              <textarea id="user_meta_0_meta_value" class="textarea resize-none w-full" name="user_meta[0][meta_value]" placeholder="Add a description"  phx-hook="Resize" rows="1" phx-debounce="blur">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :description)}</textarea>
              <input type="hidden" name="user_meta[0][meta_key]" value={:description}/>
            </div>

            <label class="input input-sm flex items-center gap-1">
              <.icon name="hero-map-pin" class="size-4" />
              <input type="text" name="user_meta[1][meta_value]" placeholder="Add a location" class="grow" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :location)} phx-debounce="blur"/>
              <input type="hidden" name="user_meta[1][meta_key]" value={:location}/>
            </label>

            <label class="input input-sm flex items-center gap-1">
              <.icon name="hero-globe-alt" class="size-4" />
              <input type="text" name="user_meta[2][meta_value]" placeholder="Add a website URL" class="grow" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :website)} phx-debounce="blur"/>
              <input type="hidden" name="user_meta[2][meta_key]" value={:website}/>
            </label>


            <label class="input input-sm flex items-center gap-1">
              <Lucideicons.twitter class="size-4" />
              <input type="text" name="user_meta[3][meta_value]" placeholder="Add a X(twiiter)" class="grow" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :twitter)} phx-debounce="blur"/>
              <input type="hidden" name="user_meta[3][meta_key]" value={:twitter}/>
            </label>

            <label class="input input-sm flex items-center gap-1">
              <Lucideicons.facebook class="size-4" />
              <input type="text" name="user_meta[4][meta_value]" placeholder="Add a Facebook" class="grow" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :facebook)} phx-debounce="blur"/>
              <input type="hidden" name="user_meta[4][meta_key]" value={:facebook}/>
            </label>

            <label class="input input-sm flex items-center gap-1">
              <Lucideicons.instagram class="size-4" />
              <input type="text" name="user_meta[5][meta_value]" placeholder="Add a Instagram" class="grow" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :instagram)} phx-debounce="blur"/>
              <input type="hidden" name="user_meta[5][meta_key]" value={:instagram}/>
            </label>
          </div>
        </div>
        <div class="border-b flex item-center justify-between w-full pr-2">
          <div role="tablist" class="tabs tabs-bordered w-auto max-w-sm">
            <a role="tab" class="tab">Published</a>
            <a role="tab" class="tab tab-active">Saved</a>
          </div>
          <label class="input input-sm flex items-center gap-1 max-w-xs input-bordered my-1" autocomplete="off">
              <Lucideicons.search class="size-4" />
              <input type="text" name="search" placeholder="Search..." class="grow" phx-debounce="blur"/>
          </label>
        </div>
      </div>
    </form>
    """
  end
end
