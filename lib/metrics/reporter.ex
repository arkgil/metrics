defmodule Metrics.Reporter do
  @moduledoc """
  Behaviour for processes forwarding values emitted by views to external systems.
  """

  use GenServer

  alias Metrics.{ReporterSupervisor, ReporterStore}

  @type state :: term()

  @doc """
  Called when the reporter process is initialized.

  It is used to set up initial reporter's state. `start_link/3` returns only after `init/1` returns.
  See `c:GenServer.init/1` for the description of return values.
  """
  @callback init(arg :: term()) ::
              {:ok, state()}
              | {:ok, state(), timeout() | :hibernate}
              | {:stop, reason :: any()}
              | :ignore

  @doc """
  Called when any of the views emit the values.

  `ts` argument is a UTC timestamp. For the description of return values see `handle_info/2`.
  """
  @callback handle_emit(
              Metrics.metric(),
              Metrics.view(),
              [Metrics.value()],
              Metrics.timestamp(),
              state()
            ) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate}
              | {:stop, reason :: any(), new_state}
            when new_state: state()

  @doc """
  Called to handle all other messages received by the reporter process.

  See `c:GenServer.terminate/2` for detailed description.
  """
  @callback handle_info(msg :: :timeout | term(), state()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate}
              | {:stop, reason :: any(), new_state}
            when new_state: state()

  @doc """
  Called when the reporter process is about to terminate.

  See `c:GenServer.terminate/2` for detailed description.
  """
  @callback terminate(reason, state()) :: term()
            when reason: :normal | :shutdown | {:shutdown, term()}

  @doc """
  Called in some cases o retrieve a formatted version of the reporter process status.

  See `c:GenServer.format_status/2` for detailed description.
  """
  @callback format_status(reason, pdict_and_state :: list()) :: term()
            when reason: :normal | :terminate

  @doc """
  Called to change the state of the reporter process when a different version of a module is loaded
  (hot code swapping) and the state's structure should be changed.

  See `c:GenServer.code_change/3` for detailed description.
  """
  @callback code_change(old_vsn, state(), extra :: term()) ::
              {:ok, new_state :: state()} | {:error, reason :: term()} | {:down, term()}
            when old_vsn: term()

  @optional_callbacks [
    handle_info: 2,
    format_status: 2,
    code_change: 3
  ]

  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour Metrics.Reporter

      @doc """
      Returns a child specification to start this module under a supervisor

      See documentation of `Supervisor` module for more information.
      """
      def child_spec(arg) do
        default = %{
          id: __MODULE__,
          start: {Metrics.Reporter, :start_link, [__MODULE__, arg, []]}
        }

        Supervisor.child_spec(default, unquote(Macro.escape(opts)))
      end

      @impl true
      def terminate(_reason, _state) do
        :ok
      end

      defoverridable child_spec: 1, terminate: 2
    end
  end

  @doc """
  Starts a reporter process and links to the caller

  `module` is a reporter module. `arg` is arbitrary term passed to `init/1` callback during
  initialization. `opts` is a list of options as passed to `GenServer.start_link/3`.

  This function can be used to start a reporter process as a part of supervision tree.
  """
  @spec start_link(module, arg :: term(), opts :: GenServer.options()) :: GenServer.on_start()
  def start_link(mod, arg, opts \\ []) do
    GenServer.start_link(__MODULE__, [mod, arg], opts)
  end

  @doc """
  Starts a reporter process as a part of `Metrics` application supervision tree.

  See `start_link/3` for description of arguments.
  """
  @spec start(module, arg :: term(), opts :: GenServer.options()) :: Supervisor.on_start_child()
  def start(mod, arg, opts \\ []) do
    ReporterSupervisor.start_child([mod, arg, opts])
  end

  @doc false
  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end

  @doc false
  @spec notify(pid, Metrics.metric(), Metrics.view(), [Metrics.value()], Metrics.timestamp()) ::
          :ok
  def notify(pid, metric, view, values, ts) do
    GenServer.cast(pid, {:"$metrics_emitted", metric, view, values, ts})
  end

  @impl true
  def init([mod, arg]) do
    Process.put(:"$initial_call", {mod, :init, 1})

    case mod.init(arg) do
      {:ok, int} ->
        ReporterStore.register()
        {:ok, make_initial_state(mod, int)}

      {:ok, int, timeout_or_hibernate} ->
        ReporterStore.register()
        {:ok, make_initial_state(mod, int), timeout_or_hibernate}

      {:stop, _reason} = stop ->
        stop

      :ignore ->
        :ignore

      other ->
        {:stop, {:bad_return_value, other}}
    end
  end

  @impl true
  def handle_cast({:"$metrics_emitted", metric, view, values, ts}, %{mod: mod, int: int} = state) do
    result = mod.handle_emit(metric, view, values, ts, int)
    handle_result(result, state)
  end

  @impl true
  def handle_info(msg, %{mod: mod, int: int} = state) do
    try do
      result = mod.handle_info(msg, int)
      handle_result(result, state)
    catch
      :error, :undef ->
        if function_exported?(mod, :handle_info, 2) do
          :erlang.raise(:error, :undef, System.stacktrace())
        else
          {:registered_name, name} = Process.info(self(), :registered_name)
          proc = if name == [], do: self(), else: name
          pattern = 'Undefined handle_info/2 in ~p, process ~p received unexpected message ~p~n'
          :error_logger.warning_msg(pattern, [mod, proc, msg])
          {:noreply, state}
        end
    end
  end

  @impl true
  def terminate(reason, %{mod: mod, int: int}) do
    mod.terminate(reason, int)
  end

  @impl true
  def format_status(reason, [pdict, %{mod: mod, int: int}]) do
    try do
      mod.format_status(reason, [pdict, int])
    catch
      :error, :undef ->
        if function_exported?(mod, :format_status, 2) do
          :erlang.raise(:error, :undef, System.stacktrace())
        else
          if reason == :normal do
            [{:data, [{'State', int}]}]
          else
            int
          end
        end
    end
  end

  @impl true
  def code_change(old_vsn, new_vsn, %{mod: mod, int: int} = state) do
    try do
      mod.code_change(old_vsn, new_vsn, int)
    catch
      :error, :undef ->
        if function_exported?(mod, :code_change, 3) do
          :erlang.raise(:error, :undef, System.stacktrace())
        else
          {:ok, state}
        end
    else
      {:ok, int} ->
        {:ok, %{state | int: int}}

      {:error, _reason} = ret ->
        ret

      {:down, _reason} = ret ->
        ret
    end
  end

  defp make_initial_state(mod, int) do
    %{mod: mod, int: int}
  end

  defp handle_result({:noreply, int}, state), do: {:noreply, %{state | int: int}}

  defp handle_result({:noreply, int, timeout_or_hibernate}, state),
    do: {:noreply, %{state | int: int}, timeout_or_hibernate}

  defp handle_result({:stop, reason, int}, state), do: {:stop, reason, %{state | int: int}}
  defp handle_result(other, state), do: {:stop, {:bad_return_value, other}, state}
end
