defmodule MolyWeb.YoutubeChannelHub.PageController do
  use MolyWeb, :controller

  alias MolyWeb.Youtubechannelhub.PageHtml.Prompts

  def index(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "Youtube Thumbnail Viewer And Downloader"
    page_description = "Find youtube thumbnail high-quality thumbnails from any YouTube video in seconds. Professional tools for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "
    render conn, :index, [page_title: page_title, page_description: page_description]
  end
  def calculator(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "Youtube Income Estimator PRO"
    page_description = "Youtube Income Estimator PRO, Professional Youtube Money Calculator for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "
    render conn, :calculator, [page_title: page_title, page_description: page_description]
  end

  def tag_generator_result(conn, %{"text" => text, "cfToken" => cfToken}) do

    conn = put_layout(conn, false)
    page_title = "#{text} Youtube Tag Generator Results"
    page_description = "Free AI Powered Youtube Tag Generator Is a free tool that allows you to easily generate SEO optimized YouTube tags / keywords from the title of your video, for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "

    args = [page_title: page_title, page_description: page_description, style: register_style(), text: text]

    args =
      case Moly.Helper.validate_cf(cfToken) do
        :ok ->
          {:ok, content} = Prompts.youtube_generate_tag(text)
          Keyword.put(args, :result, JSON.decode!(content))
        :error ->
          args
    end
    render conn, :tag_generator_result, args
  end

  def tag_generator(conn, _params) do
    conn = put_layout(conn, false)
    page_title = "TubeTagPilot - Free AI Powered Youtube Tag Generator And Optimizer"
    page_description = "TubeTagPilot Free AI Powered Youtube Tag Generator And Optimizer Is a free tool that allows you to easily generate SEO optimized YouTube tags / keywords from the title of your video, for content creators, bloggers, and digital marketers #{DateTime.utc_now() |> Map.get(:year)}. "
    render conn, :tag_generator, [page_title: page_title, page_description: page_description, style: register_style()]
  end

  defp register_style() do
    """
    <style>
    :root {
        --primary-color: #b2cae5;
        --secondary-text-color: #5c718a;
      }
    </style>
    """
  end


end
