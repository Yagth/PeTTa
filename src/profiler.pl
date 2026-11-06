%%% MeTTa profiler: `run.sh -p|--profile file.metta` (fork addition). %%%
%%% It lives outside metta.pl because the builtin registry check covers every %%%
%%% predicate that metta.pl defines. %%%

:- use_module(library(prolog_profile)).

%%% Profiling: %%%
:- dynamic metta_profile_session/0.
:- multifile prolog:show_profile_hook/1.

profile_metta_file(File, Results) :-
    profile_metta_files([File], [Results]).

%All named files are loaded under one profile session, so one report covers them:
profile_metta_files(Files, ResultsList) :-
    setup_call_cleanup(enable_metta_profile_session,
                       profile(maplist(load_metta_file, Files, ResultsList)),
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
    member(Meta, MetaList),
    ( Meta = fun_meta(Args, _) ; Meta = fun_meta(Args, _, _) ),
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
        format("Recursive MeTTa call tree from hot entry functions (all reachable MeTTa callees)~n"),
        format("Repeated caller->callee edges are aggregated by predicate name.~n"),
        format("Function~tCalls~78|~tTotal~92|~tTotal %~106|~n"),
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
    show_metta_profile_tree_node(Node, Node.call, Summary, 0, [], [], _, Nodes, MettaPreds).

show_metta_profile_tree_node(Node, Calls, Summary, Depth, Seen, ExpandedIn, ExpandedOut, Nodes, MettaPreds) :-
    normalize_profile_predicate(Node.predicate, Pred),
    predicate_label(Pred, Label),
    TotalTicks is Node.ticks_self + Node.ticks_siblings,
    ticks_to_seconds(TotalTicks, Summary, TotalSeconds),
    ticks_to_percentage(TotalTicks, Summary, TotalPercent),
    ( memberchk(Pred, Seen)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, cycle),
         ExpandedOut = ExpandedIn
      ; memberchk(Pred, ExpandedIn)
      -> format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, shared),
         ExpandedOut = ExpandedIn
      ; format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, normal),
         metta_profile_callees(Node, MettaPreds, Callees),
         Seen1 = [Pred|Seen],
         Expanded1 = [Pred|ExpandedIn],
         Depth1 is Depth + 1,
         show_metta_profile_tree_callees(Callees, Summary, Depth1, Seen1, Expanded1, ExpandedOut, Nodes, MettaPreds)
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
          -> metta_profile_callees(Node, MettaPreds, ChildCallees),
             ( ChildCallees == []
               -> ExpandedOut = Expanded1
               ; Seen1 = [Pred|Seen],
                 Depth1 is Depth + 1,
                 show_metta_profile_tree_callees(ChildCallees, Summary, Depth1, Seen1, Expanded1, ExpandedOut, Nodes, MettaPreds)
             )
          ; ExpandedOut = Expanded1
        )
    ).

format_metta_tree_line(Depth, Label, Calls, TotalSeconds, TotalPercent, Status) :-
    Indent is Depth * 2,
    ( Status == cycle
      -> format(string(DisplayLabel), "~w (cycle)", [Label])
      ; Status == shared
      -> format(string(DisplayLabel), "~w (expanded above)", [Label])
      ; DisplayLabel = Label
    ),
    format("~*c~w~t~D~78|~t~3f s~92|~t~1f %~106|~n",
           [Indent, 0' , DisplayLabel, Calls, TotalSeconds, TotalPercent]).

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
