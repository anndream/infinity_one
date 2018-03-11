defmodule OneLogger do

  require Logger

  defmacro __using__(opts \\ []) do
    quote location: :keep do
      require Logger
      import unquote(__MODULE__)
      if Keyword.get(unquote(opts), :debug, :true) do
        def __debug__, do: true
      else
        def __debug__, do: false
      end
      @__level__ Keyword.get(unquote(opts), :level)
    end
  end

  defmacro trace(event, params, msg \\ "") do
    modules =
      case Application.get_env :infinity_one, :one_tracer_modules, [] do
        :all -> [:all]
        other -> other
      end

    match =
      quote do
        Enum.find(modules, fn
          {__MODULE__, _} -> true
          __MODULE__      -> true
          :all            -> true
          _               -> false
        end)
        |> case do
          {_, mod_level} -> mod_level
          __MODULE__     -> :check
          :all         -> :check
          _              -> false
        end
      end

    quote bind_quoted: [modules: modules, match: match, msg: msg, event: event, params: params], location: :keep do
      if match != false do
        the_level =
          case match do
            :check ->
              @__level__ || Application.get_env(:infinity_one, :one_tracer_level, :debug)
            false -> false
            other -> other
          end

        msg1 =
          case msg do
            "" -> ""
            mg -> mg <> ", "
          end

        Logger.log the_level, fn -> "TRACE: #{event}: #{msg1}params: " <>
          inspect(params) end
      else
        _ = {event, params, msg}
      end
    end
  end

  defmacro debug(event, params, msg \\ "") do
    name = __CALLER__.function |> elem(0) |> to_string
    quote location: :keep do
      msg1 =
        case unquote(msg) do
          "" -> ""
          mg -> mg <> ", "
        end

      if __debug__() do
        if InfinityOne.env() == :prod do
          Logger.debug "%% " <> inspect(__MODULE__) <>
            ".#{unquote(name)} #{unquote(event)}: #{msg1}params: " <>
            "#{inspect unquote(params)}"
        else
          Logger.info "%% " <> inspect(__MODULE__) <>
            ".#{unquote(name)} #{unquote(event)}: #{msg1}params: " <>
            "#{inspect unquote(params)}"
        end
      else
        _ = {unquote(event), unquote(params), msg1}
      end
    end
  end

  defmacro warn(event, params, msg \\ "") do
    name = __CALLER__.function |> elem(0) |> to_string
    quote location: :keep do
      msg1 = case unquote(msg) do
        "" -> ""
        mg -> mg <> ", "
      end

      if __debug__() do
        Logger.warn "%% " <> inspect(__MODULE__) <> ".#{unquote(name)} " <>
          "#{unquote(event)}: #{msg1}params: #{inspect unquote(params)}"
      end
    end
  end

  def log_inspect(term, level, opts) do
    {label, opts} = Keyword.pop(opts, :label)
    label =
      if label do
        label <> ": "
      else
        ""
      end
    Logger.log level, label <> inspect(term, opts)
    term
  end
end
