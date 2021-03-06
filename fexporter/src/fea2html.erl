-module(fea2html).
-compile([export_all]).
-import(utils, [create_folder/1, get_list_from_file/1, get_random_str/1]).
-import(fea2dot, [generate_dot/2]).
-include("../include/features.hrl").
-include("../include/fea2html.hrl").
-include("../include/fea2dot.hrl").
-define(random_name(V), lists:flatten(V++get_random_str(7))).
%% API zone
%% ========
export_html({feature, Name, Lookups}, ClassFolder, TargetFolder) ->
    ExportFolder = filename:join([TargetFolder, Name]),
    {ok, created} = create_folder(ExportFolder),
    export_html_lookup(Lookups, ClassFolder, ExportFolder).

export_class_html(ClassFile, ExportFolder) ->
    io:format("~p::~p", [ClassFile, ExportFolder]),
    ExportClassFolder = filename:join([ExportFolder, lists:flatten("classes")]),
    io:format("~p~n", [ExportClassFolder]),
    {ok, created} = create_folder(ExportClassFolder),
    {ok, Glyphs} = get_list_from_file(ClassFile),
    Basename = filename:basename(ClassFile),
    {ok, done} = write_list_glyphs_to_html(Glyphs, Basename, ExportClassFolder).

%% Local zone
%% ==========

write_list_glyphs_to_html(List, Basename, ExportFolder) ->
    %% first flat write
    FNameFlat = lists:flatten(filename:join(ExportFolder, Basename)),
    {ok, FD1} = file:open(FNameFlat, [write]),
    {ok, done} = write_flat(List, FD1),
    ok = file:close(FD1),
    Filename = lists:flatten(filename:join(ExportFolder, Basename++".th")),
    {ok, FD} = file:open(Filename, [write]),
    ok = io:format(FD, ?table_head, []),
    {ok, done} = write_table_rows(List, FD),
    ok = io:format(FD, ?table_footer, []),
    ok = file:close(FD),
    {ok, done}.

write_flat([], _FD) ->
    {ok, done};
write_flat([Glyph|T], FD) ->
    ok = io:format(FD, Glyph++"\n", []),
    write_flat(T, FD).
%% lookups
export_html_lookup([], _CF, _EF) ->
    {ok, done};
export_html_lookup([_C=#lookup{name=Name, lookups=Tables}|Rest], CF, EF) ->
    {ok, Dots} = generate_dot(Tables, EF),
    {ok, done} = write_html(Dots, filename:join([EF, Name++".th"])),
    export_html_lookup(Rest, CF, EF).

%% write to dot file
write_html(Dots, Filename) ->
    {ok, FileDescription} = file:open(Filename, [write]),
    {ok, done} = write_table_head(FileDescription),
    {ok, done} = write_table_entry(Dots, FileDescription),
    {ok, done} = write_table_footer(FileDescription),
    ok = file:close(FileDescription),
    {ok, done}.

write_table_entry([], _FD) ->
    {ok, done};
write_table_entry([{dot, Subs, Bys}|Rest], FD) ->
    ok = io:format(FD, ?table_row_start, []),
    {ok, done} = write_table_rows(Subs, FD),
    {ok, done} = write_table_rows(Bys, FD),
    ok = io:format(FD, ?table_row_end, []),
    write_table_entry(Rest, FD).

write_table_rows([], _FD) ->
    {ok, done};
write_table_rows([H|T], FD) ->
    {ok, done} = write_table_row(H, FD),
    write_table_rows(T, FD).

write_table_row(_H=#dotglyph{cluster_name=_ClusterName,
                             label=Label,
                             icon_name=_IconName,
                             color=Color}, FD) ->
    ImageName = Label++".png",
    ok = io:format(FD, ?table_data(ImageName, Label, Color), []),
    {ok, done};

write_table_row({multi, Name, Color, List}, FD) ->
    RName = ?random_name("multi"),
    ok = io:format(FD, ?table_list_data_hd(Color), []),
    ok = io:format(FD, ?div_head(RName, Name), []),
    ok = io:format(FD, ?div_tag(RName), []),
    ok = io:format(FD, ?table_inner_head(Name), []),
    {ok, done} = write_table_inner_row(List, FD),
    ok = io:format(FD, ?table_inner_foot, []),
    ok = io:format(FD, ?div_foot, []),
    ok = io:format(FD, ?table_list_data_ft, []),
    {ok, done};

write_table_row(Glyph, FD) ->
    ImageName = Glyph++".png",
    ok = io:format(FD, ?table_row_start, []),
    ok = io:format(FD, ?table_data(ImageName, Glyph, "black"), []),
    ok = io:format(FD, ?table_row_end, []),
    {ok, done}.

write_table_inner_row([], _FD) ->
    {ok, done};
write_table_inner_row([Glyph|T], FD) ->
    ImageName = Glyph++".png",
    ok = io:format(FD, ?table_row_start, []),
    ok = io:format(FD, ?table_inner_data(ImageName, Glyph), []),
    ok = io:format(FD, ?table_row_end, []),
    write_table_inner_row(T, FD).

take_name(_C = #dotglyph{icon_name=Iname}) ->
    Iname;
take_name(Iname) ->
    Iname.

%% insert head  and footer part
write_table_head(FD) ->
    ok = io:format(FD, ?table_head, []),
    {ok, done}.

write_table_footer(FD) ->
    ok = io:format(FD, ?table_footer, []),
    {ok, done}.
