% Declarando o módulo
- module (ring).
% Exportando o método start
- export ([start/2]).

% Função que inicia a execução do programa e exibe o tempo total de execução
start (N, M) ->
     statistics(wall_clock),
     MainProcess = self(),
     io:format("Criando um anel de ~p processos~n~n", [N]),
     spawn(fun() -> ring(1, N, M, self(), MainProcess) end),
     receive
          ended -> void
     end,
     {_, Time} = statistics(wall_clock),
     io:format("Tempo total de execucao: ~p millisegundos~n", [Time]).

% Função executada ao se passar o valor 0 para o número de processos
ring (_, N, _, _, _) when (N =< 0) ->
     io:format("O anel esta vazio~n~n"),
     erlang:error(emptyRing);

% Função executada ao se passar o valor 0 para o número de mensagens
ring (_, _, M, _, _) when (M =< 0) ->
     io:format("Sem mensagens para enviar~n~n"),
     erlang:error(noMessages);

% Função que cria o último processo e chama o início do envio de mensagens
ring (N, N, M, FirstProcess, MainProcess) ->
     io:format("Criando o processo ~p (~p)~n~n", [N, self()]),
     io:format("Enviando ~p mensagens ao anel~n~n", [M]),
     FirstProcess ! {send, main_process, MainProcess},
     loop(M, N, N, FirstProcess, MainProcess);

% Função que cria um processo e chama a próxima posição
ring (I, N, M, FirstProcess, MainProcess) ->
     io:format("Criando o processo ~p (~p)~n", [I, self()]),
     NextProcess = spawn(fun() -> ring(I + 1, N, M, FirstProcess, MainProcess) end),
     loop(M, I, N, NextProcess, MainProcess).

% Função chamada ao se finalizar o processo principal
loop (0, N, N, _, MainProcess) ->
     io:format("~nProcesso ~p (~p) finalizado~n~n", [N, self()]),
     MainProcess ! ended;

% Função chamada ao se finalizar um processo
loop (0, I, _, _, _) -> 
     io:format("~nProcesso ~p (~p) finalizado~n~n", [I, self()]);

% Função que realiza o envio de mensagens entre os processos
loop (M, I, N, NextProcess, MainProcess) ->
     receive
          {send, From, FromProcess} ->
               io:format("Processo ~p (~p) recebeu a mensagem ~p do processo ~p (~p) ~n", [I, self(), M, From, FromProcess]),
               NextProcess ! {send, I, self()},
               loop(M - 1, I, N, NextProcess, MainProcess)
     end.