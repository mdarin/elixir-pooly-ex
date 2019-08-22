defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec
 
  @doc """
  Struct that maintains the state of the server
  """
  #@spec ...
  defmodule State do
    defstruct pool_sup: nil,
      worker_sup: nil,
      workers: nil,
      size: nil,
      woker: nil, 
      mfa: nil,
      monitors: nil,
      name: nil
  end


  ## API

  @doc """
  назначение фукнции
  """
  #@spec спецификация 
  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup,pool_config], name: name(pool_config[:name]))
  end

  @doc """
  назначение фукнции
  """
  #@spec спецификация 
  def checkout(pool_name) do
    GenServer.call(name(pool_name), :checkout)
  end

  @doc """
  назначение фукнции
  """
  #@spec спецификация 
  def checkin(pool_name, worker_pid) do
    GenServer.call(name(pool_name), {:checkin,worker_pid})
  end

  @doc """
  назначение фукнции
  """
  #@spec спецификация 
  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end



  ## Callbacks
  
  @doc """
  """
  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{pool_sup: pool_sup, monitors: monitors})
  end
  def init([{:mfa, mfa}|rest], state) do
    init(rest,  %{state | mfa: mfa})
  end
  def init([{:size, size}|rest], state) do
    init(rest, %{state | size: size})
  end
  def init([_|rest], state) do
    init(rest, state)
  end
  def init([], state) do
    send(self, :start_worker_supervisor)
    {:ok, state}
  end

  @doc """
  назначение фукнции
  """
  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker|rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {workers, ref})
        {:reply, worker, %{state | workers: rest}}
      [] ->
        {:reply, :noproc, state}
    end    
  end
 
  def handle_call({:checkin, worker}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
	{:noreply, %{state | workers: [pid|workers]}}
      [] ->
        {:noreply, state}
    end
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end


  @doc """
  назначение функции
  """
  def handle_info(:start_worker_supervisor, state = %{sup: sup, mfa: mfa, size: size}) do
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end
 
  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end 

  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers, worker_sup: worker_sup}) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [new_worker(worker_sup)|workers]}
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:start_pool, pool_config}, state) do
    {:ok, _pool_sup} = Supervisor.start_child(Pooly.PoolSupervisor, supervisor_spec(pool_config))
    {:noreply, state}
  end

  def handle_info(:start_worker_supervisor, state = %{pool_sup: pool_sup, name: name, mfa: mfa, size: size}) do
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, supervisor_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers, pool_sup: pool_sup}) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [new_worker(pool_sup)|workers]}
        {:noreply, new_state}
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, worker_sup, reason}, state = %{worker_sup: worker_sup}) do
    {:stop, reason, state}
  end


  @doc """
  """
  def terminate(_reason, _state) do
    :ok
  end



  ## internals
  @doc """
  """
  defp name(pool_name) do
    :"#{pool_name}Server" 
  end

  @doc """
  """
  defp supervisor_spec(name, mfa) do
    opts = [id: name <> "WorkerSupervisor", restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [self(),mfa], opts)
  end

  @doc """
  """
  defp prepopulate(size, sup) do
    prepopulate(size, sup, [])
  end
  defp prepopulate(size, _sup, workers) when size < 1 do
    workers
  end
  defp prepopulate(size, sup, workers) do
    prepopulate(size-1, sup, [new_worker(sup) | workers])
  end

  
  @doc """
  """
  defp new_worker(sup) do
    {:ok, worker} = Supervisor.start_child(sup, [[]])
    worker
  end


  defp supervisor_spec(pool_config) do
    opts = [id: :"#{pool_config[:name]}Supervisor"]
    supervisor(Pooly.PoolSupervisor, [pool_config], opts)
  end

end # eof module
