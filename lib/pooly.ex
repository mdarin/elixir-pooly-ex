defmodule Pooly do
  use Application 

  @moduledoc """
  Documentation for Pooly.
  """

  ## API

  @doc """
  назначение функции указать минимально
  """
  #spec ... указать спецификацию функции
  def start(_type, _args)  do
    IO.puts "Application #{inspect __MODULE__} starting on node #{inspect :erlang.node()}"
    pools_config = [
     [name: "Pool1", mfa: {SampleWorker, :start_link, []}, size: 2],
     [name: "Pool2", mfa: {SampleWorker, :start_link, []}, size: 3],
     [name: "Pool3", mfa: {SampleWorker, :start_link, []}, size: 4]
    ]
   
    start_pools(pools_config)
  end


  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def start_pools(pools_config) do
    Pooly.Supervisor.start_link(pools_config)
  end

  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def checkout() do
    Pooly.Server.checkout 
  end

  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def checkin(worker_pid) do
    Pooly.Server.checkin(worker_pid)
  end

  @doc """
  назначение функции указать минимально
  """
  #@spec указать спецификацию функции
  def status() do
    Pooly.Server.status
  end


  ## Callbacks



  ## Internals


end # eof module
