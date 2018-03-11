defmodule OneChat.File do
  use Arc.Definition

  # Include ecto support (requires package arc_ecto installed):
  use Arc.Ecto.Definition
  require Logger

  def __storage, do: Arc.Storage.Local

  @versions [:original, :poster]

  # TODO: This needs to be changed so only subscribers to the channel can
  #       read the attachments
  @acl :public_read

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Whitelist file extensions:
  def validate({file, _}) do
    # TODO: This needs to changed to pull from Settings.
    ~w(.jpg .jpeg .gif .png .txt .text .doc .pdf .wav .mp3 .mp4 .mov .m4a .xls)
    |> Enum.member?(Path.extname(file.file_name) |> String.downcase)
  end

  def transform(:poster, {_, %{type: "video" <> _}}) do
    {:ffmpeg, fn(input, output) ->
      "-i #{input} -f image2 -ss 00:00:01.00 -vframes 1 -vf scale=-1:200 #{output}" end, :jpg}
  end

  def transform(:poster, {_, %{type: "image" <> _}} = _params) do
    {:convert, "-strip -resize @80000 -format png", :png}
  end

  def transform(:poster, _params) do
    :noaction
  end

  def filename(:poster, _params) do
    :poster
  end

  def filename(_version, {_, %{file_name: file_name}}) do
    String.replace(file_name, ~r(\.[^/.]+$), "")
  end

  def filename(_version, %{file_name: file_name}) do
    file_name
  end

  # Override the persisted filenames:
  # def filename(version, params) do
  #   Logger.warn "filename version: #{inspect version}, params: #{inspect params}"
  #   version
  # end

  def storage_dir(_version, {_file, scope}) do
    storage_dir(scope)
  end

  def storage_dir(scope) do
    path = "priv/static/uploads/#{scope.message_id}"
    if InfinityOne.env == :prod do
      Path.join(Application.app_dir(:infinity_one), path)
    else
      path
    end
  end

  # Provide a default URL if there hasn't been a file uploaded
  # def default_url(version, scope) do
  #   "/images/avatars/default_#{version}.png"
  # end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: Plug.MIME.path(file.file_name)]
  # end
end
