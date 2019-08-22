defmodule SampleWorker do
  use GenServer


  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

 
  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def stop(pid) do
    GenServer.call(pid, :stop)
  end


  ## callbacks
  
  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

end # eof module
