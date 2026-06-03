%%%%%%%%%% Dependencies %%%%%%%%%%
library(X, Path) :- library_path(Base), atomic_list_concat([Base, '/', X], Path).
library(X, Y, Path) :- library_path(Base), atomic_list_concat([Base, '/../', X, '/', Y], Path).
:- prolog_load_context(directory, Source),
   directory_file_path(Source, '..', Parent),
   directory_file_path(Parent, 'lib', LibPath),
   asserta(library_path(LibPath)).
:- autoload(library(uuid)).
:- use_module(library(random)).
:- use_module(library(janus)).
:- use_module(library(error)).
:- use_module(library(listing)).
:- use_module(library(aggregate)).
:- use_module(library(thread)).
:- use_module(library(lists)).
:- use_module(library(yall), except([(/)/3])).
:- use_module(library(apply)).
:- use_module(library(apply_macros)).
:- use_module(library(process)).
:- use_module(library(filesex)).
:- use_module(library(prolog_profile)).
:- current_prolog_flag(argv, Argv),
   ( member(mork, Argv) -> ensure_loaded([parser, translator, specializer, filereader, '../mork_ffi/morkspaces', spaces])
                         ; ensure_loaded([parser, translator, specializer, filereader, spaces])).

%%%%%%%%%% Standard Library for MeTTa %%%%%%%%%%

%%% Representation and parsing conversions: %%%
id(X, X).
repr(Term, R) :- swrite(Term, R).
repra(Term, R) :- term_to_atom(Term, R).
parse(Str, R) :- sread(Str, R).

%%% Arithmetic & Comparison: %%%
'+'(A,B,R)  :- R is A + B.
'-'(A,B,R)  :- R is A - B.
'*'(A,B,R)  :- R is A * B.
'/'(A,B,R)  :- R is A / B.
'%'(A,B,R)  :- R is A mod B.
'<'(A,B,R)  :- (A<B -> R=true ; R=false).
'>'(A,B,R)  :- (A>B -> R=true ; R=false).
'=='(A,B,R) :- (A==B -> R=true ; R=false).
'!='(A,B,R) :- (A==B -> R=false ; R=true).
'='(A,B,R) :-  (A=B -> R=true ; R=false).
'=?'(A,B,R) :- (\+ \+ A=B -> R=true ; R=false).
'=alpha'(A,B,R) :- (A =@= B -> R=true ; R=false).
'=@='(A,B,R) :- (A =@= B -> R=true ; R=false).
'<='(A,B,R) :- (A =< B -> R=true ; R=false).
'>='(A,B,R) :- (A >= B -> R=true ; R=false).
min(A,B,R)  :- R is min(A,B).
max(A,B,R)  :- R is max(A,B).
exp(Arg,R) :- R is exp(Arg).
:- use_module(library(clpfd)).
'#+'(A, B, R) :- R #= A + B.
'#-'(A, B, R) :- R #= A - B.
'#*'(A, B, R) :- R #= A * B.
'#div'(A, B, R) :- R #= A div B.
'#//'(A, B, R) :- R #= A // B.
'#mod'(A, B, R) :- R #= A mod B.
'#min'(A, B, R) :- R #= min(A,B).
'#max'(A, B, R) :- R #= max(A,B).
'#<'(A, B, true)  :- A #< B, !.
'#<'(_, _, false).
'#>'(A, B, true)  :- A #> B, !.
'#>'(_, _, false).
'#='(A, B, true)  :- A #= B, !.
'#='(_, _, false).
'#\\='(A, B, true)  :- A #\= B, !.
'#\\='(_, _, false).
'pow-math'(A, B, Out) :- Out is A ** B.
'sqrt-math'(A, Out)   :- Out is sqrt(A).
'abs-math'(A, Out)    :- Out is abs(A).
'log-math'(Base, X, Out) :- Out is log(X) / log(Base).
'trunc-math'(A, Out)  :- Out is truncate(A).
'ceil-math'(A, Out)   :- Out is ceil(A).
'floor-math'(A, Out)  :- Out is floor(A).
'round-math'(A, Out)  :- Out is round(A).
'sin-math'(A, Out)  :- Out is sin(A).
'cos-math'(A, Out)  :- Out is cos(A).
'tan-math'(A, Out)  :- Out is tan(A).
'asin-math'(A, Out) :- Out is asin(A).
'acos-math'(A, Out) :- Out is acos(A).
'atan-math'(A, Out) :- Out is atan(A).
'isnan-math'(A, Out) :- ( A =:= A -> Out = false ; Out = true ).
'isinf-math'(A, Out) :- ( A =:= 1.0Inf ; A =:= -1.0Inf -> Out = true ; Out = false ).
'min-atom'(List, Out) :- min_list(List, Out).
'max-atom'(List, Out) :- max_list(List, Out).

%%% Random Generators: %%%
'random-int'(Min, Max, Result) :- random_between(Min, Max, Result).
'random-int'('&rng', Min, Max, Result) :- random_between(Min, Max, Result).
'random-float'(Min, Max, Result) :- random(R), Result is Min + R * (Max - Min).
'random-float'('&rng', Min, Max, Result) :- random(R), Result is Min + R * (Max - Min).

%%% Boolean Logic: %%%
bool(true).
bool(false).
and(A,B,C) :- bool(A), bool(B), ( A == true -> C = B ; A == false -> C = false ).
or(A,B,C) :- bool(A), bool(B), ( A == true -> C = true ; A == false -> C = B ).
not(A,B) :- bool(A), ( A == true -> B = false ; A == false -> B = true ).
xor(A,B,C) :- bool(A), bool(B), ( A == B -> C = false ; C = true ).
implies(A,B,C) :- bool(A), bool(B), ( A == true -> ( B == true  -> C = true ; B == false -> C = false )
                                                 ; A == false -> C = true ).

%%% Nondeterminism: %%%
superpose(L,X) :- member(X,L).
empty(_) :- fail.

%%% Lists / Tuples: %%%
'cons-atom'(H, T, [H|T]).
'decons-atom'([H|T], [H|[T]]).
'first-from-pair'([A, _], A).
first([A, _], A).
'second-from-pair'([_, A], A).
'unique-atom'(A, B) :- list_to_set(A, B).

%%% Alpha-equivalence unique atom %%%
'alpha-unique-atom'(A, B) :-
    must_be(list, A),
    alpha_list_to_set(A, B).

alpha_list_to_set(List, Set) :-
    empty_assoc(Seen0),
    alpha_list_to_set_assoc(List, Seen0, Set).

alpha_list_to_set_assoc([], _, []).
alpha_list_to_set_assoc([H|T], SeenIn, R) :-
    copy_term(H, HCopy),
    numbervars(HCopy, 0, _),
    term_hash(HCopy, Key),
    ( get_assoc(Key, SeenIn, _) ->
        alpha_list_to_set_assoc(T, SeenIn, R)
    ;
        put_assoc(Key, SeenIn, true, SeenOut),
        R = [H|RT],
        alpha_list_to_set_assoc(T, SeenOut, RT)
    ).

'sort-atom'(List, Sorted) :- msort(List, Sorted).
'size-atom'(List, Size) :- length(List, Size).
'car-atom'([H|_], H).
'cdr-atom'([_|T], T).
decons([H|T], [H|[T]]).
cons(H, T, [H|T]).
'index-atom'(List, Index, Elem) :- nth0(Index, List, Elem).
member(X, L, true) :- member(X, L).
'is-member'(X, List, true) :- member(X, List).
'is-member'(X, List, false) :- \+ member(X, List).

member_alpha(X, [H|_]) :- (var(X) -> var(H) ; true), X = H, !.
member_alpha(X, [_|T]) :- member_alpha(X, T).

'is-alpha-member'(X, List, true) :- member_alpha(X, List), !.
'is-alpha-member'(_, _, false).

'exclude-item'(A, L, R) :- exclude(==(A), L, R).

%Multisets:
'subtraction-atom'([], _, []).
'subtraction-atom'([H|T], B, Out) :- ( select(H, B, BRest) -> 'subtraction-atom'(T, BRest, Out)
                                                            ; Out = [H|Rest],
                                                              'subtraction-atom'(T, B, Rest) ).
'union-atom'(A, B, Out) :- append(A, B, Out).
'intersection-atom'(A, B, Out) :- intersection(A, B, Out).

%%% Type system: %%%
get_function_type([F|Args], T) :- nonvar(F), match('&self', [':',F,[->|Ts]], _, _),
                                  append(As,[T],Ts),
                                  maplist('get-type',Args,As).

:- dynamic 'get-type'/2.
'get-type'(X, T) :- (get_type_candidate(X, T) *-> true ; T = '%Undefined%' ).
get_type_candidate(X, 'Number')   :- number(X), !.
get_type_candidate(X, _) :- var(X), !.
get_type_candidate(X, 'String')   :- string(X), !.
get_type_candidate(true, 'Bool')  :- !.
get_type_candidate(false, 'Bool') :- !.
get_type_candidate(X, T) :- get_function_type(X,T).
get_type_candidate(X, T) :- \+ get_function_type(X, _),
                            is_list(X),
                            maplist('get-type', X, T).
get_type_candidate(X, T) :- match('&self', [':',X,T], T, _).
'get-metatype'(X, 'Variable') :- var(X), !.
'get-metatype'(X, 'Grounded') :- number(X), !.
'get-metatype'(X, 'Grounded') :- string(X), !.
'get-metatype'(true,  'Grounded') :- !.
'get-metatype'(false, 'Grounded') :- !.
'get-metatype'(X, 'Grounded') :- atom(X), fun(X), !.  % e.g., '+' is a registered fun/1
'get-metatype'(X, 'Expression') :- is_list(X), !.     % e.g., (+ 1 2), (a b)
'get-metatype'(X, 'Symbol') :- atom(X), !.            % e.g., a

'is-var'(A,R) :- var(A) -> R=true ; R=false.
'is-ground'(A,R) :- ground(A) -> R=true ; R=false.
'is-expr'(A,R) :- is_list(A) -> R=true ; R=false.
'is-space'(A,R) :- atom(A), atom_concat('&', _, A) -> R=true ; R=false.

%%% Diagnostics / Testing: %%%
'println!'(Arg, true) :- swrite(Arg, RArg),
                         format('~w~n', [RArg]).

'readln!'(Out) :- read_line_to_string(user_input, Str),
                  sread(Str, Out).

test(A,B,true) :- (A =@= B -> E = '✅' ; E = '❌'),
                  swrite(A, RA),
                  swrite(B, RB),
                  format("is ~w, should ~w. ~w ~n", [RA, RB, E]),
                  (A =@= B -> true ; halt(1)).

assert(Goal, true) :- ( call(Goal) -> true
                                    ; swrite(Goal, RG),
                                      format("Assertion failed: ~w~n", [RG]),
                                      halt(1) ).

%%% Time Retrieval: %%%
'current-time'(Time) :- get_time(Time).
'format-time'(Format, TimeString) :- get_time(Time), format_time(atom(TimeString), Format, Time).

%%% Python bindings: %%%
'py-call'(SpecList, Result) :- 'py-call'(SpecList, Result, []).
'py-call'([Spec|Args], Result, Opts) :- ( string(Spec) -> atom_string(A, Spec) ; A = Spec ),
                                        must_be(atom, A),
                                        ( sub_atom(A, 0, 1, _, '.')         % ".method"
                                          -> sub_atom(A, 1, _, 0, Fun),
                                             Args = [Obj|Rest],
                                             ( Rest == []
                                               -> compound_name_arguments(Meth, Fun, [])
                                                ; Meth =.. [Fun|Rest] ),
                                             py_call(Obj:Meth, Result, Opts)
                                           ; atomic_list_concat([M,F], '.', A) % "mod.fun"
                                             -> ( Args == []
                                                  -> compound_name_arguments(Call0, F, [])
                                                   ; Call0 =.. [F|Args] ),
                                                py_call(M:Call0, Result, Opts)
                                              ; ( Args == []                      % bare "fun"
                                                  -> compound_name_arguments(Call0, A, [])
                                                   ; Call0 =.. [A|Args] ),
                                                py_call(builtins:Call0, Result, Opts) ).

%%% States: %%%
'bind!'(A, ['new-state', B], C) :- 'change-state!'(A, B, C).
'change-state!'(Var, Value, true) :- nb_setval(Var, Value).
'get-state'(Var, Value) :- nb_getval(Var, Value).

%%% Eval: %%%
eval(C, Out) :- translate_expr(C, Goals, Out),
                call_goals(Goals).

call_goals([]).
call_goals([G|Gs]) :- call(G), 
                      call_goals(Gs).

until_runtime(Pred, Func, X, Out) :-
    reduce([Pred, X], Truth),
    ( Truth == true
      -> Out = X
      ; reduce([Func, X], Next),
        until_runtime(Pred, Func, Next, Out)
    ).

%%% Profiling: %%%
:- dynamic metta_profile_session/0.
:- multifile prolog:show_profile_hook/1.

profile_metta_file(File, Results) :-
    setup_call_cleanup(enable_metta_profile_session,
                       profile(load_metta_file(File, Results)),
                       disable_metta_profile_session).

enable_metta_profile_session :-
    retractall(metta_profile_session),
    assertz(metta_profile_session).

disable_metta_profile_session :-
    retractall(metta_profile_session).

prolog:show_profile_hook(Options) :-
    metta_profile_session,
    show_metta_profile(Options).

show_metta_profile(_) :-
    profile_data(Data),
    Summary = Data.summary,
    metta_profile_predicates(MettaPreds),
    metta_profile_nodes(Data.nodes, MettaPreds, Nodes),
    profiled_time(Summary, ProfiledTime),
    format("~`=t MeTTa profile ~`=t~112|~n"),
    format("Samples: ~D  Total nodes: ~D  Profiled time: ~3f s~n",
           [Summary.samples, Summary.nodes, ProfiledTime]),
    ( Nodes == []
      -> format("No MeTTa-defined functions were recorded by the profiler.~n"),
         format("~`=t~112|~n")
      ; length(Nodes, Count),
         format("MeTTa predicates recorded: ~D~n", [Count]),
        format("Predicate~tCalls~54|~tSelf~68|~tSelf %~80|~tTotal~94|~tTotal %~108|~n"),
        format("~`-t~112|~n"),
        forall(member(Node, Nodes), show_metta_profile_node(Node, Summary)),
        show_metta_call_tree(Nodes, MettaPreds, Summary),
        format("~`=t~112|~n")
    ).

metta_profile_nodes(AllNodes, MettaPreds, SortedNodes) :-
    include(is_metta_profile_node(MettaPreds), AllNodes, Nodes0),
    findall(Key-Node,
            ( member(Node, Nodes0),
              metta_profile_sort_key(Node, Key)
            ),
            KeyedNodes),
    keysort(KeyedNodes, SortedPairs),
    findall(Node, member(_-Node, SortedPairs), SortedNodes).

metta_profile_predicates(Preds) :-
    findall(Pred, metta_profile_predicate(Pred), Preds0),
    sort(Preds0, Preds).

metta_profile_predicate(F/Arity) :-
    current_predicate(F/Arity),
    atom(F),
    catch(nb_current(F, MetaList), _, fail),
    is_list(MetaList),
    member(fun_meta(Args, _), MetaList),
    length(Args, N),
    Arity is N + 1.
metta_profile_predicate(F/Arity) :-
    translated_from(Ref, [=, [F|_], _]),
    clause(Head, _, Ref),
    functor(Head, F, Arity).

is_metta_profile_node(MettaPreds, Node) :-
    normalize_profile_predicate(Node.predicate, Pred),
    memberchk(Pred, MettaPreds).

normalize_profile_predicate(_Module:Pred, Normalized) :- !,
    normalize_profile_predicate(Pred, Normalized).
normalize_profile_predicate(F/Arity, F/Arity).

metta_profile_sort_key(Node, Key) :-
    TotalTicks is Node.ticks_self + Node.ticks_siblings,
    normalize_profile_predicate(Node.predicate, Pred),
    Key = key(-TotalTicks, -Node.call, Pred).

show_metta_profile_node(Node, Summary) :-
    normalize_profile_predicate(Node.predicate, Pred),
    predicate_label(Pred, Label),
    ticks_to_seconds(Node.ticks_self, Summary, SelfSeconds),
    ticks_to_percentage(Node.ticks_self, Summary, SelfPercent),
    TotalTicks is Node.ticks_self + Node.ticks_siblings,
    ticks_to_seconds(TotalTicks, Summary, TotalSeconds),
    ticks_to_percentage(TotalTicks, Summary, TotalPercent),
    format("~w~t~D~54|~t~3f s~68|~t~1f %~80|~t~3f s~94|~t~1f %~108|~n",
           [Label, Node.call, SelfSeconds, SelfPercent, TotalSeconds, TotalPercent]).

show_metta_call_tree(Nodes, MettaPreds, Summary) :-
    metta_profile_roots(Nodes, MettaPreds, Summary, Roots),
    ( Roots == []
      -> true
      ; format("~`-t~112|~n"),
        format("Partitioned MeTTa call tree from hot entry functions~n"),
        format("Displayed totals are caller-attributed so each node equals its self time plus displayed children.~n"),
        format("Repeated caller->callee edges are aggregated by predicate name before partitioning.~n"),
        format("Function~tCalls~78|~tTime~92|~tTime %~106|~n"),
        format("~`-t~112|~n"),
        forall(member(Root, Roots),
               ( show_metta_call_tree_root(Root, Nodes, MettaPreds, Summary),
                  format("~`-t~112|~n")
               ))
    ).

metta_profile_roots(Nodes, MettaPreds, Summary, Roots) :-
    findall(Key-Node,
            metta_profile_root(Nodes, MettaPreds, Summary, Key, Node),
            KeyedRoots),
    ( KeyedRoots == []
      -> Roots = []
      ; keysort(KeyedRoots, SortedPairs),
        findall(Node, member(_-Node, SortedPairs), Roots)
    ).

metta_profile_root(Nodes, MettaPreds, Summary, Key, Node) :-
    member(Node, Nodes),
    TotalTicks is Node.ticks_self + Node.ticks_siblings,
    ticks_to_percentage(TotalTicks, Summary, Percent),
    Percent >= 1.0,
    \+ has_metta_caller(Node, MettaPreds),
    normalize_profile_predicate(Node.predicate, Pred),
    Key = key(-TotalTicks, -Node.call, Pred).

has_metta_caller(Node, MettaPreds) :-
    member(Relative, Node.callers),
    profile_relative_node(Relative, RelativeNode),
    is_metta_profile_node(MettaPreds, RelativeNode).

show_metta_call_tree_root(Node, Nodes, MettaPreds, Summary) :-
    node_total_ticks(Node, RootTicks),
    show_metta_profile_tree_node(Node, Node.call, RootTicks, Summary, 0, [], [], _, Nodes, MettaPreds).

show_metta_profile_tree_node(Node, Calls, AllocatedTicks, Summary, Depth, Seen, ExpandedIn, ExpandedOut, Nodes, MettaPreds) :-
    normalize_profile_predicate(Node.predicate, Pred),
    predicate_label(Pred, Label),
    ticks_to_seconds(AllocatedTicks, Summary, TotalSeconds),
    ticks_to_percentage(AllocatedTicks, Summary, TotalPercent),
    ( memberchk(Pred, Seen)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, cycle),
         ExpandedOut = ExpandedIn
      ; memberchk(Pred, ExpandedIn)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, shared),
         ExpandedOut = ExpandedIn
      ; format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, normal),
         partition_metta_node(Node, AllocatedTicks, MettaPreds, SelfTicks, Callees),
         Seen1 = [Pred|Seen],
         Expanded1 = [Pred|ExpandedIn],
         Depth1 is Depth + 1,
         show_metta_profile_tree_components(SelfTicks, Callees, Summary, Depth1, Seen1, Expanded1, ExpandedOut, Nodes, MettaPreds)
    ).

show_metta_profile_tree_components(SelfTicks, Callees, Summary, Depth, Seen, ExpandedIn, ExpandedOut, Nodes, MettaPreds) :-
    show_metta_profile_self(SelfTicks, Summary, Depth, ExpandedIn, ExpandedMid),
    show_metta_profile_tree_callees(Callees, Summary, Depth, Seen, ExpandedMid, ExpandedOut, Nodes, MettaPreds).

show_metta_profile_self(SelfTicks, Summary, Depth, ExpandedIn, ExpandedOut) :-
    ( SelfTicks =< 0
      -> ExpandedOut = ExpandedIn
      ; ticks_to_seconds(SelfTicks, Summary, SelfSeconds),
        ticks_to_percentage(SelfTicks, Summary, SelfPercent),
        format_metta_tree_line(Depth, '[self]', 0, SelfSeconds, SelfPercent, self),
        ExpandedOut = ExpandedIn
    ).

show_metta_profile_tree_callees([], _, _, _, Expanded, Expanded, _, _).
show_metta_profile_tree_callees([callee(Pred, Calls, Ticks)|Callees], Summary, Depth, Seen, ExpandedIn, ExpandedOut, Nodes, MettaPreds) :-
    show_metta_profile_tree_callee(Pred, Calls, Ticks, Summary, Depth, Seen, ExpandedIn, ExpandedMid, Nodes, MettaPreds),
    show_metta_profile_tree_callees(Callees, Summary, Depth, Seen, ExpandedMid, ExpandedOut, Nodes, MettaPreds).

show_metta_profile_tree_callee(Pred, Calls, Ticks, Summary, Depth, Seen, ExpandedIn, ExpandedOut, Nodes, MettaPreds) :-
    predicate_label(Pred, Label),
    ticks_to_seconds(Ticks, Summary, TotalSeconds),
    ticks_to_percentage(Ticks, Summary, TotalPercent),
    ( memberchk(Pred, Seen)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, cycle)
      ,  ExpandedOut = ExpandedIn
      ; memberchk(Pred, ExpandedIn)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, shared)
      ,  ExpandedOut = ExpandedIn
      ; format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, normal),
        Expanded1 = [Pred|ExpandedIn],
        ( metta_node_for_predicate(Nodes, Pred, Node)
          -> partition_metta_node(Node, Ticks, MettaPreds, SelfTicks, ChildCallees),
             ( SelfTicks =< 0,
               ChildCallees == []
               -> ExpandedOut = Expanded1
               ; Seen1 = [Pred|Seen],
                 Depth1 is Depth + 1,
                 show_metta_profile_tree_components(SelfTicks, ChildCallees, Summary, Depth1, Seen1, Expanded1, ExpandedOut, Nodes, MettaPreds)
             )
          ; ExpandedOut = Expanded1
        )
    ).

partition_metta_node(Node, AllocatedTicks, MettaPreds, SelfTicks, PartitionedCallees) :-
    metta_profile_callees(Node, MettaPreds, RawCallees),
    RawSelfTicks is max(0, Node.ticks_self),
    raw_callee_ticks(RawCallees, RawChildTicks),
    ComponentTicks is RawSelfTicks + RawChildTicks,
    ( ComponentTicks =< 0
      -> SelfTicks = AllocatedTicks,
         PartitionedCallees = []
      ; Scale is AllocatedTicks / ComponentTicks,
        SelfTicks is AllocatedTicks * RawSelfTicks / ComponentTicks,
        partition_metta_callees(RawCallees, Scale, PartitionedCallees)
    ).

partition_metta_callees([], _, []).
partition_metta_callees([callee(Pred, Calls, RawTicks)|Callees], Scale, [callee(Pred, Calls, Ticks)|Partitioned]) :-
    Ticks is RawTicks * Scale,
    partition_metta_callees(Callees, Scale, Partitioned).

raw_callee_ticks([], 0).
raw_callee_ticks([callee(_, _, Ticks)|Callees], Total) :-
    raw_callee_ticks(Callees, Rest),
    Total is Rest + Ticks.

format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, Status) :-
    Indent is Depth * 2,
    ( Status == cycle
      -> format(string(DisplayLabel), "~w (cycle)", [Label])
      ; Status == shared
      -> format(string(DisplayLabel), "~w (expanded above)", [Label])
      ; Status == self
      -> DisplayLabel = Label
      ; DisplayLabel = Label
    ),
    format("~*c~w~t~D~78|~t~3f s~92|~t~1f %~106|~n",
           [Indent, 0' , DisplayLabel, Calls, TotalSeconds, TotalPercent]).

node_total_ticks(Node, Ticks) :-
    Ticks is Node.ticks_self + Node.ticks_siblings.

metta_node_for_predicate([Node|_], Pred, Node) :-
    normalize_profile_predicate(Node.predicate, Pred),
    !.
metta_node_for_predicate([_|Nodes], Pred, Node) :-
    metta_node_for_predicate(Nodes, Pred, Node).

metta_profile_callees(Node, MettaPreds, SortedCallees) :-
    findall(edge(Pred, Calls, Ticks),
            ( member(Relative, Node.callees),
              profile_relative_node(Relative, RelativeNode),
              is_metta_profile_node(MettaPreds, RelativeNode),
              normalize_profile_predicate(RelativeNode.predicate, Pred),
              Calls = RelativeNode.call,
              Ticks is RelativeNode.ticks_self + RelativeNode.ticks_siblings
            ),
            Edges0),
    aggregate_profile_edges(Edges0, AggregatedEdges),
    findall(Key-callee(Pred, Calls, Ticks),
            ( member(edge(Pred, Calls, Ticks), AggregatedEdges),
              Key = key(-Ticks, -Calls, Pred)
            ),
            KeyedCallees),
    keysort(KeyedCallees, SortedPairs),
    findall(Callee, member(_-Callee, SortedPairs), SortedCallees).

aggregate_profile_edges([], []).
aggregate_profile_edges(Edges, Aggregated) :-
    findall(Pred-edge(Calls, Ticks), member(edge(Pred, Calls, Ticks), Edges), KeyedEdges),
    keysort(KeyedEdges, SortedEdges),
    aggregate_profile_edges_sorted(SortedEdges, Aggregated).

aggregate_profile_edges_sorted([], []).
aggregate_profile_edges_sorted([Pred-edge(Calls, Ticks)|Rest], [edge(Pred, CallsSum, TicksSum)|Aggregated]) :-
    aggregate_profile_edges_same(Rest, Pred, Calls, Ticks, CallsSum, TicksSum, Remaining),
    aggregate_profile_edges_sorted(Remaining, Aggregated).

aggregate_profile_edges_same([Pred-edge(Calls, Ticks)|Rest], Pred, Calls0, Ticks0, CallsSum, TicksSum, Remaining) :- !,
    Calls1 is Calls0 + Calls,
    Ticks1 is Ticks0 + Ticks,
    aggregate_profile_edges_same(Rest, Pred, Calls1, Ticks1, CallsSum, TicksSum, Remaining).
aggregate_profile_edges_same(Remaining, _, Calls, Ticks, Calls, Ticks, Remaining).

profile_relative_node(node(Predicate, _CycleId, TicksSelf, TicksSiblings, Calls, Redos, Exits),
                      node{predicate:Predicate,
                           ticks_self:TicksSelf,
                           ticks_siblings:TicksSiblings,
                           call:Calls,
                           redo:Redos,
                           exit:Exits,
                           callers:[],
                           callees:[]}).

profiled_time(Summary, 0.0) :-
    Summary.ticks =< 0,
    !.
profiled_time(Summary, Seconds) :-
    ProfiledTicks is max(0, Summary.ticks - Summary.accounting),
    Seconds is (Summary.time * ProfiledTicks) / Summary.ticks.

ticks_to_seconds(_, Summary, 0.0) :-
    Summary.ticks =< 0,
    !.
ticks_to_seconds(Ticks, Summary, Seconds) :-
    Seconds is (Summary.time * Ticks) / Summary.ticks.

ticks_to_percentage(_, Summary, 0.0) :-
    ProfiledTicks is Summary.ticks - Summary.accounting,
    ProfiledTicks =< 0,
    !.
ticks_to_percentage(Ticks, Summary, Percent) :-
    ProfiledTicks is Summary.ticks - Summary.accounting,
    Percent is 100 * Ticks / ProfiledTicks.

%%% Higher-Order Functions: %%%
'foldl-atom'([], Acc, _Func, Acc).
'foldl-atom'([H|T], Acc0, Func, Out) :- reduce([Func,Acc0,H], Acc1),
                                        'foldl-atom'(T, Acc1, Func, Out).

'map-atom'([], _Func, []).
'map-atom'([H|T], Func, [R|RT]) :- reduce([Func,H], R),
                                   'map-atom'(T, Func, RT).

'filter-atom'([], _Func, []).
'filter-atom'([H|T], Func, Out) :- ( reduce([Func,H], true) -> Out = [H|RT]
                                                             ; Out = RT ),
                                   'filter-atom'(T, Func, RT).

%%% Prolog interop: %%%
argv(K, Arg) :- current_prolog_flag(argv, Argv), nth0(K, Argv, A), ( atom_number(A, N) -> Arg = N ; Arg = A ).
import_prolog_function(N, true) :- register_fun(N).
'Predicate'([F|Args], Term) :- Term =.. [F|Args].
callPredicate(G, true) :- call(G).
assertzPredicate(G, true) :- assertz(G).
assertaPredicate(G, true) :- asserta(G).
retractPredicate(G, true) :- retract(G), !.
retractPredicate(_, false).

%%% Library / Import: %%%
ensure_metta_ext(Path, Path) :- file_name_extension(_, metta, Path), !.
ensure_metta_ext(Path, PathWithExt) :- file_name_extension(Path, metta, PathWithExt).

'import!'(Space, File, true) :- catch(importer_helper(Space, File), _, fail).
importer_helper(Space, File) :- atom_string(File, SFile),
                                working_dir(Base),
                                ( file_name_extension(ModPath, 'py', SFile)
                                  -> absolute_file_name(SFile, Path, [relative_to(Base)]),
                                     file_directory_name(Path, Dir),
                                     file_base_name(ModPath, ModuleName),
                                     py_call(sys:path:append(Dir), _),
                                     py_call(builtins:'__import__'(ModuleName), _)
                                   ; ( Path = SFile ; atomic_list_concat([Base, '/', SFile], Path) ),
                                     ensure_metta_ext(Path, PathWithExt),
                                     exists_file(PathWithExt), !,
                                     load_metta_file(PathWithExt, _, Space) ).

:- dynamic translator_rule/1.
'add-translator-rule!'(HV, true) :- ( translator_rule(HV)
                                      -> true ; assertz(translator_rule(HV)) ).

'remove-translator-rule!'(HV, true) :- retractall(translator_rule(HV)).

%%% Registration: %%%
:- dynamic fun/1.
register_fun(N) :- (fun(N) -> true ; assertz(fun(N))).
:- maplist(register_fun, [superpose, empty, let, 'let*', '+','-','*','/', '%', min, max, 'change-state!', 'get-state', 'bind!',
                          '<','>','==', '!=', '=', '=?', '<=', '>=', and, or, xor, implies, not, sqrt, exp, log, cos, sin,
                          'first-from-pair', 'second-from-pair', 'car-atom', 'cdr-atom', 'unique-atom', 'alpha-unique-atom',
                          repr, repra, parse, 'println!', 'readln!', test, assert, 'mm2-exec', atom_concat, atom_chars, copy_term, term_hash,
                          foldl, first, last, append, length, 'size-atom', sort, msort, member, 'is-member', 'is-alpha-member', 'exclude-item', list_to_set, maplist, eval, reduce, 'import!',
                          'add-atom', 'remove-atom', 'get-atoms', match, 'is-var', 'is-ground', 'is-expr', 'is-space', 'get-mettatype',
                          decons, 'decons-atom', 'py-call', 'get-type', 'get-metatype', '=alpha', concat, sread, cons, reverse,
                          '#+','#-','#*','#div','#//','#mod','#min','#max','#<','#>','#=','#\\=','set_hook',
                          'union-atom', 'cons-atom', 'intersection-atom', 'subtraction-atom', 'index-atom', id,
                          'pow-math', 'sqrt-math', 'sort-atom','abs-math', 'log-math', 'trunc-math', 'ceil-math',
                          'floor-math', 'round-math', 'sin-math', 'cos-math', 'tan-math', 'asin-math','random-int','random-float',
                          'acos-math', 'atan-math', 'isnan-math', 'isinf-math', 'min-atom', 'max-atom',
                          'foldl-atom', 'map-atom', 'filter-atom','current-time','format-time', library, exists_file,
                          import_prolog_function, 'Predicate', callPredicate, assertaPredicate, assertzPredicate, retractPredicate,
                          'add-translator-rule!', 'remove-translator-rule!', argv]).
