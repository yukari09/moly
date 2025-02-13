defmodule MonorepoWeb.Affiliate.UserPageLive2 do
  use MonorepoWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1, auto_upload: true, progress: &handle_progress/3)
      |> allow_upload(:banner, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1, auto_upload: true, progress: &handle_progress/3)
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
      if !is_nil(meta_value) && old_meta_value != meta_value do
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

  def handle_event("partial_update", _, socket) do
    {:noreply, socket}
  end

  defp handle_progress(uploader, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} = _meta ->
          old_file =
            Monorepo.Accounts.Helper.load_meta_value_by_meta_key(socket.assigns.current_user, uploader)
          if old_file do
            filename = old_file["filename"]
            Monorepo.Helper.remove_object(filename)
          end
          uploaded_file = case uploader do
            :avatar -> Monorepo.Accounts.Helper.generate_avatar_from_entry(entry, path)
            :banner -> Monorepo.Accounts.Helper.generate_banner_from_entry(entry, path)
          end
          {:ok, uploaded_file}
        end)

      new_user_meta_party = [%{meta_key: uploader, meta_value: uploaded_file}]
      changeset = Ash.Changeset.new(socket.assigns.current_user)

      result = Ash.update(changeset, %{user_meta: new_user_meta_party},
        action: :update_user_meta,
        context: %{private: %{ash_authentication?: true}}
      )

      socket =
        case result do
          {:ok, new_current_user} ->
            put_flash(socket, :info, "Your information has been updated.")
            |> assign(:current_user, new_current_user)

          {:error, _} ->
            put_flash(socket, :error, "Your information update failed, please try again later")
        end
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end



  def render(assigns) do
    ~H"""
    <div>
      <.form phx-change="partial_update">
        <div class="relative lg:h-[250px] bg-primary">
          <label for={@uploads.banner.ref} class="rounded bg-gray-50 px-2 py-1 text-xs font-semibold text-gray-600 shadow-sm hover:bg-gray-100 absolute top-2 right-2 cursor-pointer"><.icon name="hero-pencil-solid" class="size-4 text-gray-500" /></label>
          <div class="w-full h-full overflow-hidden">
            <img  class="w-full h-full object-cover overflow-hidden" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :banner)["xxl"]} />
          </div>
          <.live_file_input class="size-0" upload={@uploads.banner} />
          <label for={@uploads.avatar.ref} class="-bottom-10 absolute size-24 cursor-pointer">
            <img :if={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar) && Enum.count(@uploads.avatar.entries) == 0} class="inline-block size-24 rounded-full" src={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar)["128"]} alt="">
            <span :if={!Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :avatar) && Enum.count(@uploads.avatar.entries) == 0} class="inline-flex size-24 items-center justify-center rounded-full bg-primary border-2 border-white">
              <span class="font-medium text-white uppercase text-4xl">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) |> String.slice(0, 1)}</span>
            </span>
            <div class="w-full h-full rounded-full absolute inset-0 opacity-0 hover:opacity-10 bg-black"></div>
          </label>
          <.live_file_input class="size-0" upload={@uploads.avatar} />
        </div>

      <div class="flex items-start gap-8 mt-12">
        <div class="w-80 py-4 px-2">
          <div class="text-2xl px-4 text-gray-900">
            <p><%= Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :name) %></p>
            <p class="text-xs/8">@{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :username)}</p>
          </div>
          <div class="space-y-1 mb-12">
            <div>
              <textarea type="textarea" id="user_meta_0_meta_value" class="px-4 w-full !border-0  text-sm  !text-gray-500 !outline-none break-words resize-none overflow-hidden" rows="2" name="user_meta[0][meta_value]" placeholder="Add a description"   rows="1" phx-debounce="blur">{Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :description)}</textarea>
              <input type="hidden" name="user_meta[0][meta_key]" value={:description}/>
            </div>

            <div>
              <div class="grid grid-cols-1">
                <input type="text" name="user_meta[1][meta_value]" placeholder="Add a location" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :location)} phx-debounce="blur" class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6"/>
                <.icon name="hero-map-pin" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
              </div>
              <input type="hidden" name="user_meta[1][meta_key]" value={:location}/>
            </div>

            <div>
              <div class="grid grid-cols-1">
                <input type="text" name="user_meta[2][meta_value]" placeholder="Add a website URL" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :website)} phx-debounce="blur" class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6"/>
                <.icon name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
              </div>
              <input type="hidden" name="user_meta[2][meta_key]" value={:website}/>
            </div>

            <div>
              <div class="grid grid-cols-1">
                <input type="text" name="user_meta[3][meta_value]" placeholder="Add a X(twiiter)" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :twitter)} phx-debounce="blur" class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6"/>
                <Lucideicons.twitter name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
              </div>
              <input type="hidden" name="user_meta[3][meta_key]" value={:twitter}/>
            </div>

            <div>
              <div class="grid grid-cols-1">
                <input type="text" name="user_meta[4][meta_value]" placeholder="Add a Facebook" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :facebook)} phx-debounce="blur" class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6"/>
                <Lucideicons.facebook name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
              </div>
              <input type="hidden" name="user_meta[4][meta_key]" value={:facebook}/>
            </div>

            <div>
              <div class="grid grid-cols-1">
                <input type="text" name="user_meta[5][meta_value]" placeholder="Add a Instagram" value={Monorepo.Accounts.Helper.load_meta_value_by_meta_key(@current_user, :instagram)} phx-debounce="blur" class="col-start-1 row-start-1 block w-full rounded-md bg-white py-1.5 pl-10 pr-3 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-none placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600 sm:pl-9 sm:text-sm/6"/>
                <Lucideicons.instagram name="hero-globe-alt" class="pointer-events-none col-start-1 row-start-1 ml-3 size-5 self-center text-gray-400 sm:size-4" />
              </div>
              <input type="hidden" name="user_meta[5][meta_key]" value={:instagram}/>
            </div>
          </div>
        </div>
        <!--start tab-->
        <div class="grow px-2">
        <div class="relative border-b border-gray-200 pb-5 sm:pb-0">
          <%!-- <div class="md:flex md:items-center md:justify-between">
            <div class="mt-3 flex md:absolute md:top-3 md:right-0 md:mt-0">
              <button type="button" class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 shadow-xs ring-gray-300 ring-inset hover:bg-gray-50">Share</button>
              <button type="button" class="ml-3 inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-gray-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-600">Create</button>
            </div>
          </div> --%>
          <div class="mt-4">
            <div class="grid grid-cols-1 sm:hidden">
              <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
              <select aria-label="Select a tab" class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-2 pr-8 pl-3 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-gray-600">
                <option>Applied</option>
                <option>Phone Screening</option>
                <option selected>Interview</option>
                <option>Offer</option>
                <option>Hired</option>
              </select>
              <svg class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true" data-slot="icon">
                <path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
              </svg>
            </div>
            <!-- Tabs at small breakpoint and up -->
            <div class="hidden sm:block">
              <nav class="-mb-px flex space-x-8">
                <!-- Current: "border-gray-500 text-gray-600", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
                <a href="#" class="border-b-2 border-green-500 px-1 pb-4 text-sm font-medium whitespace-nowrap text-green-600" aria-current="page">Published</a>
                <a href="#" class="border-b-2 border-transparent px-1 pb-4 text-sm font-medium whitespace-nowrap text-gray-500 hover:border-gray-300 hover:text-gray-700">Saved</a>
              </nav>
            </div>
          </div>
        </div>
        </div>
        <!--end-->
      </div>
    </.form>
    </div>
    """
  end
end
