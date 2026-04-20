:- ensure_loaded(metta).

prologfunc(X,Y) :- Y is X+1.

prolog_interop_example :- register_fun(prologfunc),
                          process_metta_string("(= (mettafunc $x) (prologfunc $x))", _),
                          listing(mettafunc),
                          mettafunc(30, R),
                          format("mettafunc(30) = ~w~n", [R]).

cli_flag('-p').
cli_flag('--profile').
cli_flag('-s').
cli_flag('--silent').
cli_flag(silent).
cli_flag(mork).

cli_file_argument(Arg) :- \+ cli_flag(Arg).

cli_file(Args, File) :-
    include(cli_file_argument, Args, [File|_]).

cli_profile_enabled(Args) :-
    memberchk('-p', Args).
cli_profile_enabled(Args) :-
    memberchk('--profile', Args).

run_metta_file(Args, File, Results) :-
    retractall(working_dir(_)),
    file_directory_name(File, Dir),
    assertz(working_dir(Dir)),
    ( cli_profile_enabled(Args)
      -> profile_metta_file(File, Results)
      ; load_metta_file(File, Results)
    ).

main :- current_prolog_flag(argv, Args),
        ( Args = [] -> prolog_interop_example
        ; Args = [mork] -> prolog_interop_example,
                           mork_test
        ; cli_file(Args, File) -> run_metta_file(Args, File, Results),
                                  maplist(swrite, Results, ResultsR),
                                  maplist(format("~w~n"), ResultsR)
        ; format(user_error, "Usage: run.sh [-p|--profile] [-s|--silent] <file.metta>~n", []),
          halt(1)
        ),
        halt.

:- initialization(main, main).
