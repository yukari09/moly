defmodule MonorepoWeb.Affiliates.AffiliateController do
  use MonorepoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  # alias Monorepo.Affiliates
  # alias Monorepo.Affiliates.Affiliate

  # def index(conn, _params) do
  #   affiliates = Affiliates.list_affiliates()
  #   render(conn, :index, affiliates: affiliates)
  # end

  # def new(conn, _params) do
  #   changeset = Affiliates.change_affiliate(%Affiliate{})
  #   render(conn, :new, changeset: changeset)
  # end

  # def create(conn, %{"affiliate" => affiliate_params}) do
  #   case Affiliates.create_affiliate(affiliate_params) do
  #     {:ok, affiliate} ->
  #       conn
  #       |> put_flash(:info, "Affiliate created successfully.")
  #       |> redirect(to: ~p"/affiliates/affiliates/#{affiliate}")

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, :new, changeset: changeset)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   affiliate = Affiliates.get_affiliate!(id)
  #   render(conn, :show, affiliate: affiliate)
  # end

  # def edit(conn, %{"id" => id}) do
  #   affiliate = Affiliates.get_affiliate!(id)
  #   changeset = Affiliates.change_affiliate(affiliate)
  #   render(conn, :edit, affiliate: affiliate, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "affiliate" => affiliate_params}) do
  #   affiliate = Affiliates.get_affiliate!(id)

  #   case Affiliates.update_affiliate(affiliate, affiliate_params) do
  #     {:ok, affiliate} ->
  #       conn
  #       |> put_flash(:info, "Affiliate updated successfully.")
  #       |> redirect(to: ~p"/affiliates/affiliates/#{affiliate}")

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, :edit, affiliate: affiliate, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   affiliate = Affiliates.get_affiliate!(id)
  #   {:ok, _affiliate} = Affiliates.delete_affiliate(affiliate)

  #   conn
  #   |> put_flash(:info, "Affiliate deleted successfully.")
  #   |> redirect(to: ~p"/affiliates/affiliates")
  # end
end
