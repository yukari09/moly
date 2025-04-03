defmodule MolyWeb.Affinew.Helper do
  def format_es_data(nil, _), do: nil

  def format_es_data(data_str, format \\ "{Mfull} {D}, {YYYY}") do
    Timex.parse!(data_str, "{ISO:Extended:Z}")
    |> Timex.format!(format)
  end
end
