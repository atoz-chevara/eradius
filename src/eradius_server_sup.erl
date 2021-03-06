%% @private
%% @doc Supervisor for RADIUS server processes.
-module(eradius_server_sup).
-export([start_link/0, start_instance/1, stop_instance/2, all/0]).

-behaviour(supervisor).
-export([init/1]).

-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------------------------------
%% -- API
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_instance(ServerAddr = {ServerName, {IP, Port}}) ->
    lager:info("Starting RADIUS Listener at ~s", [eradius_server:printable_peer(IP, Port)]),
    MetricsAddress = eradius_metrics:make_addr_info(ServerAddr),
    eradius_metrics:create_server(MetricsAddress),
    supervisor:start_child(?SERVER, [ServerName, IP, Port]).

stop_instance(ServerAddr = {_ServerName, {IP, Port}}, Pid) ->
    lager:info("Stopping RADIUS Listener at ~s", [eradius_server:printable_peer(IP, Port)]),
    MetricsAddress = eradius_metrics:make_addr_info(ServerAddr),
    eradius_metrics:delete_server(MetricsAddress),
    supervisor:terminate_child(?SERVER, Pid).

all() ->
    lists:map(fun({_, Child, _, _}) -> Child end, supervisor:which_children(?SERVER)).

%% ------------------------------------------------------------------------------------------
%% -- supervisor callbacks
init([]) ->
    RestartStrategy = simple_one_for_one,
    Restarts = 10,
    RestartInterval = 2,

    SupFlags = {RestartStrategy, Restarts, RestartInterval},
    Child = {'_', {eradius_server, start_link, []}, transient, 1000, worker, [eradius_server]},

    {ok, {SupFlags, [Child]}}.
