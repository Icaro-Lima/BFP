cubeMatrix(
    [[000, 000, 000, 101, 101, 101, 000, 000, 000],
     [000, 000, 000, 101, 101, 101, 000, 000, 000],
     [000, 000, 000, 101, 101, 101, 000, 000, 000],
     [102, 102, 102, 103, 103, 103, 044, 044, 044],
     [102, 102, 102, 103, 103, 103, 044, 044, 044],
     [102, 102, 102, 103, 103, 103, 044, 044, 044],
     [000, 000, 000, 045, 045, 045, 000, 000, 000],
     [000, 000, 000, 045, 045, 045, 000, 000, 000],
     [000, 000, 000, 045, 045, 045, 000, 000, 000],
     [000, 000, 000, 100, 100, 100, 000, 000, 000],
     [000, 000, 000, 100, 100, 100, 000, 000, 000],
     [000, 000, 000, 100, 100, 100, 000, 000, 000]]
).

animations(Animations) :- loadAnimations(Animations).
     
assetsPath("../Assets").

lineLimit(500).

cols(Cols) :- tty_size(_, Cols).
rows(Rows) :- tty_size(Rows, _).

cubeOriginRow(0).
cuboMidCol(X) :- cols(Y), X is Y // 2 - 75 // 2.

esc("\e").

writeOnLineAux([], List, _, List).
	
writeOnLineAux([HeadIn|TailIn], [Head|Tail], I, [HeadOut|TailOut]) :-
	(
	I > 0 -> II is I - 1, HeadOut = Head, writeOnLineAux([HeadIn|TailIn], Tail, II, TailOut);
	HeadOut = HeadIn, writeOnLineAux(TailIn, Tail, 0, TailOut)
	).

writeOnLine(StrIn, Str, I, StrOut) :-
	string_to_list(StrIn, ListIn), string_to_list(Str, List),
	writeOnLineAux(ListIn, List, I, ListOut),
	string_to_list(StrOut, ListOut).

matrixToText([], "").

matrixToText([Head|Tail], Text) :-
	matrixToText(Tail, TextAux), string_concat(Head, TextAux, Text).

filledLine(Str, J) :-
	cols(Cols), lineLimit(LineLimit), JJ is J + 1,
	(
	J < Cols -> filledLine(StrAux, JJ), string_concat(" ", StrAux, Str);
	J >= Cols, J < LineLimit -> filledLine(StrAux, JJ), string_concat("\0", StrAux, Str);
	Str = ""
	).

filledMatrixAux([], Rows) :- rows(Rows).

filledMatrixAux([Head|Tail], I) :-
	II is I + 1,
	filledLine(Head, 0), filledMatrixAux(Tail, II).

readLinesFromSTream(Stream, []) :-
    at_end_of_stream(Stream).
    
readLinesFromSTream(Stream, [Head|Tail]) :-
    read_line_to_string(Stream, Head),
    readLinesFromSTream(Stream, Tail).

readFileLines(FileName, List) :- 
    open(FileName, read, Stream),
    readLinesFromSTream(Stream, List),!,
	close(Stream).

ruleForCubeFrameNames(Name, Frame) :-
	member(NameWithoutSep, ['0Left', '1Left', '2Left', '0Right', '1Right',
	'2Right', 'AUp', 'BUp', 'CUp', 'ADown', 'BDown', 'CDown', 'aClockwise',
	'bClockwise', 'cClockwise', 'aCounterclockwise', 'bCounterclockwise',
	'cCounterclockwise']),

	atom_concat(NameWithoutSep, '_', NameWithUnderline),

	between(0, 4, Number),

	atom_number(NumberAtom, Number),
	
	atom_concat(NameWithUnderline, NumberAtom, Name),

	assetsPath(AssetsPath),
	string_concat(AssetsPath, "/Cubo", CubePath),

	string_concat(CubePath, "/", CubePathBar),

	string_concat(CubePathBar, NameWithoutSep, CubePathBarName),

	string_concat(CubePathBarName, "/", CubePathBarNameBar),

	atom_string(NumberAtom, NumberString),

	string_concat(CubePathBarNameBar, NumberString, CubePathBarNameBarAnim),

	string_concat(CubePathBarNameBarAnim, ".txt", CubePathBarNameBarAnimTxt),

	readFileLines(CubePathBarNameBarAnimTxt, Frame).

ruleForLogoFrameNames(Name, Frame) :-
	between(0, 43, Number),
	atom_number(NumberAtom, Number),
	atom_concat('Logo_', NumberAtom, Name),

	assetsPath(AssetsPath),

	string_concat(AssetsPath, "/Logo/", PathWithLogo),

	atom_string(NumberAtom, NumberString),

	string_concat(PathWithLogo, NumberString, PathWithLogoNumber),

	string_concat(PathWithLogoNumber, ".txt", FullPath),

	readFileLines(FullPath, Frame).

inserListOfTuplesInDict(Dict, [(Key, Value)|[]], DictOut) :-
	DictOut = Dict.put(Key, Value).

inserListOfTuplesInDict(Dict, [(Key, Value)|Tail], DictOut) :-
	inserListOfTuplesInDict(Dict, Tail, DictOutAux), DictOut = DictOutAux.put(Key, Value).

loadAnimations(Animations) :-
	assetsPath(AssetsPath),
	string_concat(AssetsPath, "/Cubo", CubePath),

	string_concat(CubePath, "/Default.txt", PathOfDefault),
	readFileLines(PathOfDefault, AnimationOfDefault),

	AnimationsWithOnlyDefault = _{'Default': AnimationOfDefault},

	findall((X, Y), ruleForCubeFrameNames(X, Y), ListCube),

	inserListOfTuplesInDict(AnimationsWithOnlyDefault, ListCube, AnimationsWithDefaultAndCube),

	findall((X, Y), ruleForLogoFrameNames(X, Y), ListLogo),

	inserListOfTuplesInDict(AnimationsWithDefaultAndCube, ListLogo, Animations).

elementOfList([Element|_], 0, Element).

elementOfList([_|Tail], I, Element) :-
	Iaux is I - 1,
	elementOfList(Tail, Iaux, Element).

elementOfMatrix(Matrix, I, J, Element) :-
	elementOfList(Matrix, I, Line),
	elementOfList(Line, J, Element).


colorizeStringAux([], _, IsPainting, _, Output) :-
	(
	IsPainting -> Output = "\e[0m";
	Output = ""
	).

colorizeStringAux([Head|Tail], ColourMatrix, IsPainting, PasteHead, Output) :-
	(\+IsPainting -> CondToOpenCode = true; Head \= PasteHead -> CondToOpenCode = true; CondToOpenCode = false),

	(
	Head >= 65, Head =< 76, CondToOpenCode -> Line is Head - 65, elementOfMatrix(ColourMatrix, Line, 3, Cod), atom_number(CodAtom, Cod), atom_string(CodAtom, CodString), colorizeStringAux(Tail, ColourMatrix, true, Head, OutputAux), string_concat("\e[", CodString, CodedBegin), string_concat(CodedBegin, "m ", CodedEnd), string_concat(CodedEnd, OutputAux, Output);
	Head >= 65, Head =< 76, CondToOpenCode = false -> colorizeStringAux(Tail, ColourMatrix, true, Head, OutputAux), string_concat(" ", OutputAux, Output);

	string_codes(HeadString, [Head]), colorizeStringAux(Tail, ColourMatrix, false, Head, OutputAux), (IsPainting -> string_concat("\e[0m", HeadString, HeadStringCode); string_concat(HeadString, "", HeadStringCode)), string_concat(HeadStringCode, OutputAux, Output)
	).

colorizeString(StringInput, ColourMatrix, StringOutput) :-
	string_to_list(StringInput, List), colorizeStringAux(List, ColourMatrix, false, 0, StringOutput).
