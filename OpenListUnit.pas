//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

{$INCLUDE switches}
unit OpenListUnit;

interface

type

TIntegerArray = array[0..$40000000 div sizeof(integer)] of integer;
PIntegerArray = ^TIntegerArray;

TAStarItem = record
	f:		integer;	// sum of cumulative cost of predecessors and self and heuristic
	Value:	integer;	// cost of this node + it's predecessors
	h:		integer;	// heuristic estimate of distance to goal
	Item:	integer;
end;

PAStarItem = ^TAStarItem;

TAStarItemArray = array[0..$40000000 div sizeof(TAStarItem)] of TAStarItem;
PAStarItemArray = ^TAStarItemArray;

TOpenList = class
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;
	function Put(Item, Value, h: integer): boolean;
	function Get(var Item, Value, h: integer): boolean;
	procedure Remove(Item: integer);
private
	n,							// current size of the heap.
	fmax:	integer;			// max. size of the heap.
	Hp:		PAStarItemArray;	// (Value, Item) pairs of the heap.
	Ix:		PIntegerArray;		// positions of pairs in the heap Hp.
private
	function GetValue(Item: integer): integer;
{$IFDEF DISPLAY}
	function GetItem(Index: integer): integer;
	function GetnItem: integer;
{$ENDIF}
public
{$IFDEF DISPLAY}
	property nItem: Integer read GetnItem;
	property Item[Index: Integer]: integer read GetItem;
{$ENDIF}
	property Value[Index: Integer]: integer read GetValue;
end;

implementation

//=============== TOpenList ========================
constructor TOpenList.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TAStarItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TOpenList.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TOpenList.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	n := 0;
end;

{$IFDEF DISPLAY}
function TOpenList.GetnItem: integer;
begin
	result := n;
end;

function TOpenList.GetItem(Index: integer): integer;
begin
	if(Index<0)or(Index>=n)then	result := -1
	else						result :=  Hp[Index].Item;
end;
{$ENDIF}

function TOpenList.GetValue(Item: integer): integer;
var
	i:		integer;
begin
	i := Ix[Item];
	if i<0 then		result := -1
	else			result := Hp[i].Value
end;

procedure TOpenList.Remove(Item: integer);
var
	i, j, t:	integer;
	last:		TAStarItem;
	lbh:		PAStarItemArray;
begin
	if n = 0 then
		exit;
	lbh := Hp;
	i := Ix[Item];
	Ix[Item] := -1;

	dec(n);
	if n > i then
	begin
		last := lbh[n];
		j := i shl 1+1;		t := n-1;
		while j <= t do
		begin
									//	Right(i) = Left(i)+1
			if(j < t) then
				if(lbh[j].f > lbh[j + 1].f)then	inc(j);

			if lbh[j].f >= last.f then	break;
//			lbh[i] := lbh[j];
			lbh[i].f := lbh[j].f;
			lbh[i].Value := lbh[j].Value;
			lbh[i].h := lbh[j].h;
			lbh[i].Item := lbh[j].Item;
			Ix[lbh[i].Item] := i;
			i := j;
			j := j shl 1+1;	//Left(j) = 2*j+1
		end;

		// Insert the last in the correct place in the heap.
//		lbh[i] := last;
		lbh[i].f := last.f;
		lbh[i].Value := last.Value;
		lbh[i].h := last.h;
		lbh[i].Item := last.Item;
		Ix[last.Item] := i;
	end;
end;

(*****************************************************************************)
(* 			TOpenList.Put                                                    *)
(*****************************************************************************)
//Parent(i) = (i-1)/2.
function TOpenList.Put(Item, Value, h: integer): boolean; //O(lg(n))
var
	i, j, f:	integer;
	lbh:		PAStarItemArray;
	lIx:		PIntegerArray;
begin
	lIx := Ix;
	lbh := Hp;
	i := lIx[Item];
	f := (Value shr 8) + h;
	if i >= 0 then
	begin
		if lbh[i].f <= f then
		begin
			result := False;
			exit;
		end;
	end
	else
	begin
		i := n;
		Inc(n);
	end;

	while i > 0 do
	begin
		j := (i-1) shr 1;	//Parent(i) = (i-1)/2
		if f >= lbh[j].f then	break;
//		lbh[i] := lbh[j];
		lbh[i].f := lbh[j].f;
		lbh[i].Value := lbh[j].Value;
		lbh[i].h := lbh[j].h;
		lbh[i].Item := lbh[j].Item;
		lIx[lbh[i].Item] := i;
		i := j;
	end;
	//	Insert the new Item at the insertion point found.
	lbh[i].f := f;
	lbh[i].Value := Value;
	lbh[i].h := h;
	lbh[i].Item := Item;
	lIx[lbh[i].Item] := i;
	result := True;
end;

//Left(i) = 2*i+1.
//Right(i) = 2*i+2 => Left(i)+1
function TOpenList.Get(var Item, Value, h:	integer): boolean; //O(lg(n))
var
	i, j, t:	integer;
	last:		TAStarItem;
	lbh:		PAStarItemArray;
begin
	if n = 0 then
	begin
		result := False;
		exit;
	end;

	lbh := Hp;
	Value := lbh[0].Value;
	h := lbh[0].h;

	Item := lbh[0].Item;
	Ix[Item] := -1;

	dec(n);
	if n > 0 then
	begin
		last := lbh[n];

		i := 0;		j := 1;		t := n-1;
		while j <= t do
		begin
									//	Right(i) = Left(i)+1
			if(j < t) then
				if(lbh[j].f > lbh[j + 1].f)then	inc(j);

			if lbh[j].f >= last.f then	break;
			lbh[i].f := lbh[j].f;
			lbh[i].Value := lbh[j].Value;
			lbh[i].h := lbh[j].h;
			lbh[i].Item := lbh[j].Item;
			Ix[lbh[i].Item] := i;
			i := j;
			j := j shl 1+1;	//Left(j) = 2*j+1
		end;

		// Insert the last in the correct place in the heap.
		lbh[i].f := last.f;
		lbh[i].Value := last.Value;
		lbh[i].h := last.h;
		lbh[i].Item := last.Item;
		Ix[last.Item] := i;
	end;
	result := True
end;

end.
