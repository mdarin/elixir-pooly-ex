defmodule Pooly.Supervisor do
  use Supervisor

  ## API

  @doc """
  назначение функции
  """
  #@spec спецификация для экспортируемых функций и для ответственных местечек
  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: __MODULE__)
  end

  ## callbacks

  @doc """
  назначение функции
  """
  def init(pool_config) do
   children = [
     supervisor(Pooly.PoolsSupervisor, []),
     worker(Pooly.PoolServer, [self(), pool_config])
   ]

   opts = [strategy: :one_for_all]

   supervise(children, opts)
 end

end # eof module
