-module (neoring).
-export ([start/3, first_proc/3, first_loop/4, proc_start/3, proc_loop/2]).

start(MsgCount, ProcCount, Msg) ->
	spawn(ring, first_proc, [MsgCount, ProcCount, Msg]).

first_proc(MsgCount, ProcCount, Msg) ->
	io:format("First process ~w created, setting up the rest of the ring ...~n", [self()]),
	NextPid = spawn(ring, proc_start, [self(), self(), ProcCount-1]),
	LastPid = receive
				{Pid, ready} -> Pid
			  end,
	io:format("Received ready message from last process ~w, about to send messages around the ring ...~n", [LastPid]),
	first_loop(NextPid, LastPid, MsgCount, Msg).

first_loop(NextPid, LastPid, MsgCount, Msg) ->
	case MsgCount of
		MsgCount when MsgCount > 0 ->
			NextPid ! {self(), Msg},
			receive
				{LastPid, Msg} ->
					first_loop(NextPid, LastPid, MsgCount-1, Msg)
			end;
		0 ->
			NextPid ! {self(), stop},
			receive
				{LastPid, stop} -> ok
			end
	end.

proc_start(FirstPid, PrevPid, ProcCount) when ProcCount > 0 ->
	NextPid = spawn(ring, proc_start, [FirstPid, self(), ProcCount-1]),
	io:format("Created process ~w, ~w processes to go.~n", [NextPid, ProcCount]),
	proc_loop(PrevPid, NextPid);

proc_start(FirstPid, PrevPid, 0) ->
	io:format("Last process ~w reached, linking back to first process ~w.~n", [self(), FirstPid]),
	FirstPid ! {self(), ready},
	proc_loop(PrevPid, FirstPid).

proc_loop(PrevPid, NextPid) ->
	receive
		{PrevPid, Msg} ->
			NextPid ! {self(), Msg},
			io:format("Forwarded msg ~w to process ~w.~n", [Msg, NextPid]),
			proc_loop(PrevPid, NextPid);
		{PrevPid, stop} ->
			NextPid ! {self(), stop},
			ok
	end.