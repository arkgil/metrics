defmodule Metrics.FastTables do
  @moduledoc false

  ## get/0 and get_all/0 could be parametrized, e.g. get(:views), get(:counters), etc. - -this way
  ## we could try out and benchmark different implementations, e.g. separete tables for counters
  ## and views, one global table etc.

  use GenServer

  @type t :: :ets.tab()

  @spec get_all() :: [t(), ...]
  def get_all() do
    1..schedulers_online()
    |> Enum.map(&table/1)
  end

  @spec get() :: t()
  def get() do
    table(current_scheduler_id())
  end

  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, [], []]}
    }
  end

  @impl true
  def init(_) do
    create_tables()
    {:ok, []}
  end

  defp create_tables() do
    heir = Process.whereis(Metrics.Supervisor)

    for i <- 1..schedulers_online() do
      table = table(i)
      :ets.new(table, [:public, :bag, :named_table, {:heir, heir, []}, keypos: 1])
    end
  end

  defp table(1), do: :metrics_table_1
  defp table(2), do: :metrics_table_2
  defp table(3), do: :metrics_table_3
  defp table(4), do: :metrics_table_4
  defp table(5), do: :metrics_table_5
  defp table(6), do: :metrics_table_6
  defp table(7), do: :metrics_table_7
  defp table(8), do: :metrics_table_8
  defp table(9), do: :metrics_table_9
  defp table(10), do: :metrics_table_10
  defp table(11), do: :metrics_table_11
  defp table(12), do: :metrics_table_12
  defp table(13), do: :metrics_table_13
  defp table(14), do: :metrics_table_14
  defp table(15), do: :metrics_table_15
  defp table(16), do: :metrics_table_16
  defp table(17), do: :metrics_table_17
  defp table(18), do: :metrics_table_18
  defp table(19), do: :metrics_table_19
  defp table(20), do: :metrics_table_20
  defp table(21), do: :metrics_table_21
  defp table(22), do: :metrics_table_22
  defp table(23), do: :metrics_table_23
  defp table(24), do: :metrics_table_24
  defp table(25), do: :metrics_table_25
  defp table(26), do: :metrics_table_26
  defp table(27), do: :metrics_table_27
  defp table(28), do: :metrics_table_28
  defp table(29), do: :metrics_table_29
  defp table(30), do: :metrics_table_30
  defp table(31), do: :metrics_table_31
  defp table(32), do: :metrics_table_32
  defp table(33), do: :metrics_table_33
  defp table(34), do: :metrics_table_34
  defp table(35), do: :metrics_table_35
  defp table(36), do: :metrics_table_36
  defp table(37), do: :metrics_table_37
  defp table(38), do: :metrics_table_38
  defp table(39), do: :metrics_table_39
  defp table(40), do: :metrics_table_40
  defp table(41), do: :metrics_table_41
  defp table(42), do: :metrics_table_42
  defp table(43), do: :metrics_table_43
  defp table(44), do: :metrics_table_44
  defp table(45), do: :metrics_table_45
  defp table(46), do: :metrics_table_46
  defp table(47), do: :metrics_table_47
  defp table(48), do: :metrics_table_48
  defp table(49), do: :metrics_table_49
  defp table(50), do: :metrics_table_50
  defp table(51), do: :metrics_table_51
  defp table(52), do: :metrics_table_52
  defp table(53), do: :metrics_table_53
  defp table(54), do: :metrics_table_54
  defp table(55), do: :metrics_table_55
  defp table(56), do: :metrics_table_56
  defp table(57), do: :metrics_table_57
  defp table(58), do: :metrics_table_58
  defp table(59), do: :metrics_table_59
  defp table(60), do: :metrics_table_60
  defp table(61), do: :metrics_table_61
  defp table(62), do: :metrics_table_62
  defp table(63), do: :metrics_table_63
  defp table(64), do: :metrics_table_64
  defp table(n) when is_integer(n) and n > 0, do: :"metrics_table_#{n}"

  defp schedulers_online(), do: :erlang.system_info(:schedulers_online)

  defp current_scheduler_id(), do: :erlang.system_info(:scheduler_id)
end
