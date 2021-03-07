//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

{$INCLUDE switches}
unit PQUnit;

interface

type

TIntegerArray = array[0..$40000000 div sizeof(integer)] of integer;
PIntegerArray = ^TIntegerArray;

TheapItem = record
	Value:	integer;
	Item:	integer;
end;

PItem = ^TheapItem;

TItemArray = array[0..$40000000 div sizeof(TheapItem)] of TheapItem;
PItemArray = ^TItemArray;

TBasePQ = class
	procedure Empty;									virtual; abstract;
	function Put(Item, Value: integer): boolean;		virtual; abstract;
	function Get(var Item, Value: integer): boolean;	virtual; abstract;
protected
	n,						// current size of the heap.
	fmax:	integer;		// max. size of the heap.
	Hp:		PItemArray;		// (Value, Item) pairs of the heap.
	Ix:		PIntegerArray;	// positions of pairs in the heap.
{$IFDEF DISPLAY}
private
	function GetItem(Index: integer): integer;		virtual;
	function GetnItem: integer;						virtual;
public
	property nItem: Integer read GetnItem;
	property Item[Index: Integer]: integer read GetItem;
{$ENDIF}
end;

TBHPQ = class(TBasePQ)		//	Binary tree heap PQ
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;override;
	function Get(var Item, Value: integer): boolean;override;
end;

TQHPQ = class(TBasePQ)		//Quad tree heap PQ
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;override;
	function Get(var Item, Value: integer): boolean;override;
end;

TRAPQ = class(TBasePQ)		//	Raw array PQ
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;override;
	function Get(var Item, Value: integer): boolean;override;
end;

TSAPQ = class(TBasePQ)		//	Sorted array PQ
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;override;
	function Get(var Item, Value: integer): boolean;override;
end;

TFIFO = class(TBasePQ)	//	FIFO
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;		override;
	function Get(var Item, Value: integer): boolean;	override;
private
	bufh,						// head of buffer.
	bufe:	integer;			// end of buffer.
	fV:		PIntegerArray;		// array of Values
	fI:		PIntegerArray;		// array of Items

{$IFDEF DISPLAY}
	function GetItem(Index: integer): integer;	override;
	function GetnItem: integer;					override;
{$ENDIF}
end;

TSDEBPQ = class(TBasePQ)		//	Sorted double ended buffer PQ
	constructor Create(max: integer);
	destructor Destroy; override;
	procedure Empty;	override;
	function Put(Item, Value: integer): boolean;override;
	function Get(var Item, Value: integer): boolean;override;
private
	bufh,				// head of buffer.
	bufe:	integer;	// end of buffer.
{$IFDEF STATISTICS}
	n:		integer;
{$ENDIF}

{$IFDEF DISPLAY}
	function GetItem(Index: integer): integer;	override;
	function GetnItem: integer;					override;
{$ENDIF}
end;

{$IFDEF STATISTICS}
var
	MaxN, nAddNode,
	nDecreaseKey,
	nDeleteNode,
	xx, yy, zz:		integer;

	MaxD, MaxI,
	MaxT:	Double;
{$ENDIF}

implementation

uses
	MainUnit;

//=============== TBasePQ ======================
{$IFDEF DISPLAY}
function TBasePQ.GetnItem: integer;
begin
	result := n;
end;

function TBasePQ.GetItem(Index: integer): integer;
begin
	if(Index<0)or(Index>=n)then	result := -1
	else						result :=  Hp[Index].Item;
end;
{$ENDIF}

//=============== TBHPQ ========================

constructor TBHPQ.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TheapItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TBHPQ.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TBHPQ.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	n := 0;
end;

(*****************************************************************************)
(*             TBHPQ.Put                                                     *)
(*****************************************************************************)
//Parent(i) = (i-1)/2.
function TBHPQ.Put(Item, Value: integer): boolean; //O(lg(n))
{$IFNDEF ASSEMBLER}
var
	i, j:		integer;
	lbh:		PItemArray;
	lIx:		PIntegerArray;
begin
	lIx := Ix;
	lbh := Hp;
	i := lIx[Item];
	if i >= 0 then
	begin
		if lbh[i].Value <= Value then
		begin
			result := False;
			exit;
		end;
	end
	else
	begin
		i := n;
		Inc(n);
{$IFDEF STATISTICS}
		if n>MaxN then MaxN:=n
{$ENDIF}
	end;

	while i > 0 do
	begin
		j := (i-1) shr 1;	//Parent(i) = (i-1)/2
		if Value >= lbh[j].Value then	break;
		lbh[i].Value := lbh[j].Value;
		lbh[i].Item := lbh[j].Item;
		lIx[lbh[i].Item] := i;
		i := j;
	end;
	//	Insert the new Item at the insertion point found.
	lbh[i].Value := Value;
	lbh[i].Item := Item;
	lIx[lbh[i].Item] := i;
	result := True;
end;
{$ELSE}
register;
asm
	push	esi
	push	edi
	push	ebx
	mov		esi, self.Ix

	mov		edi, self.Hp
	mov		ebx, esi[Item*4]	//ebx := i

	test	ebx, ebx
	jl		@a
//case i>=0
		//if lbh[i].Value <= Value then
	cmp		Value, TheapItem(edi[ebx*8]).Value
	jl		@b

	xor		eax, eax
	pop		ebx
	pop		edi
	pop		esi
	ret

//case i<0
@a:
	mov		ebx, self.n
	inc		dword ptr self.n
@b:
	test	ebx, ebx
	jle		@found1

	lea		eax, [ebx-1]
	push	ebp
	push	Item
@loop:
	shr		eax, 1

	mov		ebp, TheapItem(edi[eax*8]).Value
	cmp		ebp, Value
	jle		@found0

//	cmp		TheapItem(edi[eax*8]).Value, Value
//	jle		@found0
//	mov		ebp, TheapItem(edi[eax*8]).Value

	mov		edx, TheapItem(edi[eax*8]).Item

	mov		TheapItem(edi[ebx*8]).Value, ebp	//lbh[i] := lbh[j]
	mov		TheapItem(edi[ebx*8]).Item, edx

	mov		esi[edx*4], ebx		//lIx[lbh[i].Item] := i
	mov		ebx, eax			//i := j
	dec		eax					//j := (i-1) shr 1

	test	ebx, ebx
	jnle	@loop
@found0:
	pop		Item
	pop		ebp
@found1:

	mov		TheapItem(edi[ebx*8]).Value, Value
	mov		TheapItem(edi[ebx*8]).Item, Item
	mov		esi[Item*4], ebx		//lIx[lbh[i].Item] := i

	mov		al, 1
	pop		ebx
	pop		edi
	pop		esi
end;
{$ENDIF}

//Left(i) = 2*i+1.
//Right(i) = 2*i+2 => Left(i)+1
function TBHPQ.Get(var Item, Value: integer): boolean; //O(lg(n))
{$IFNDEF ASSEMBLER}
var
	i, j, t, jVal:	integer;
	last:		TheapItem;
	lbh:		PItemArray;
begin
	if n = 0 then
	begin
		result := False;
		exit;
	end;

	lbh := Hp;
	Value := lbh[0].Value;
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
			if j < t then
				if lbh[j].Value > lbh[j + 1].Value then	inc(j);

			jVal :=	lbh[j].Value;

			if jVal >= last.Value then	break;
			lbh[i].Value := jVal;		//lbh[j].Value;
			lbh[i].Item := lbh[j].Item;
			Ix[lbh[i].Item] := i;
			i := j;
			j := j shl 1+1;	//Left(j) = 2*j+1
		end;

		// Insert the last in the correct place in the heap.
		lbh[i].Value := last.Value;
		lbh[i].Item := last.Item;
		Ix[last.Item] := i;
	end;
	result := True
end;
{$ELSE}
register;
asm
	cmp		self.n, 0
	jnz		@begin
	xor		eax, eax
	ret
@begin:
	push	ebx
	push	esi

	push	edi
	mov		esi, self.Hp

	add		esp, -8
	mov		edi, TheapItem([esi]).Value	//Value := lbh[0].Value

	mov		ebx, TheapItem([esi]).Item	//Item := lbh[0].Item
	mov		[ecx], edi

	mov		edi, self.Ix
	mov		ecx, self.n

	mov		[edx], ebx
	dec		ecx

	mov		edi[ebx*4], -1		//Ix[Item] := -1
	mov		self.n, ecx			//n := n-1
	jle		@done
//=================================================================
	mov		edx, TheapItem(esi[ecx*8]).Value
	mov		eax, TheapItem(esi[ecx*8]).Item		//last := lbh[n]

	mov		[esp+4], eax		// last.Item
	lea		eax, [ecx-1]		//	t := n-1;

	mov		ebx, 1				// j:=1;
	xor		ecx, ecx			// i:=0;

	cmp		ebx, eax
	jnle	@endLoop1

	mov		[esp], eax
	push	ebp
					// while j<=t
@loop:
	mov		ebp, TheapItem(esi[ebx*8]).Value

	jnl		@0b
	cmp		ebp, TheapItem(esi[ebx*8+8]).Value

	jle		@0b
	mov		ebp, TheapItem(esi[ebx*8+8]).Value

	inc		ebx						//Inc(j);
@0b:
	cmp		ebp, edx							//last.Value
	jnl		@endLoop0			//break

	mov		eax, TheapItem(esi[ebx*8]).Item
	mov		TheapItem(esi[ecx*8]).Value, ebp	//lbh[i] := lbh[j]

	mov		TheapItem(esi[ecx*8]).Item, eax
	mov		edi[eax*4], ecx	//Ix[lbh[i].Item] := i;

	mov		ecx, ebx		//i:=j
	lea		ebx, [2*ebx+1]	//j:= j shl 1+1

	cmp		ebx, [esp+4]
	jle		@loop
@endLoop0:
	pop		ebp
@endLoop1:
	mov		TheapItem(esi[ecx*8]).Value, edx	// last.Value

	mov		eax, [esp+4]						// last.Item
	mov		TheapItem(esi[ecx*8]).Item, eax

	mov		edi[eax*4], ecx	//Ix[last.Item] := i;
@done:
	add		esp, 8
	mov		al, 1
	pop		edi
	pop		esi
	pop		ebx
end;
{$ENDIF}

//=============== TQHPQ ========================
constructor TQHPQ.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TheapItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TQHPQ.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TQHPQ.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	n := 0;
end;

function TQHPQ.Put(Item, Value: integer): boolean;
{$IFNDEF ASSEMBLER}
var
	i, j:	integer;
	lqh:	PItemArray;
	lIx:	PIntegerArray;
begin
	lqh := Hp;
	lIx := Ix;

	i := lIx[Item];
	if i >= 0 then
	begin
		if lqh[i].Value <= Value then
		begin
			result := False;
			exit;
		end
	end
	else
	begin
		i := n;
		Inc(n);
{$IFDEF STATISTICS}
		if n>MaxN then MaxN:=n
{$ENDIF}
	end;

	while i > 0 do
	begin
		j := (i-1) shr 2;	//Parent(i) = (i-1)/4
		if Value >= lqh[j].Value then	break;
		lqh[i].Value := lqh[j].Value;
		lqh[i].Item := lqh[j].Item;
		lIx[lqh[j].Item] := i;
		i := j;
	end;
	//	Insert the new Item at the insertion point found.
	lqh[i].Value := Value;
	lqh[i].Item := Item;
	lIx[lqh[i].Item] := i;
	result := True;
end;
{$ELSE}
register;
asm
	push	esi
	push	edi
	push	ebx
	mov		esi, self.Ix

	mov		edi, self.Hp
	mov		ebx, esi[Item*4]	//ebx := i

	test	ebx, ebx
	jl		@a
//case i>=0
		//if lbh[i].Value <= Value then
	cmp		Value, TheapItem(edi[ebx*8]).Value
	jl		@b

	xor		eax, eax
	pop		ebx
	pop		edi
	pop		esi
	ret

//case i<0
@a:
	mov		ebx, self.n
	inc		dword ptr self.n
@b:
	test	ebx, ebx
	jle		@found1

	lea		eax, [ebx-1]
	push	ebp
	push	Item
@loop:
	shr		eax, 2

//	mov		ebp, TheapItem(edi[eax*8]).Value
//	cmp		ebp, Value
//	jle		@found0

	cmp		Value, TheapItem(edi[eax*8]).Value
	jg		@found0

	mov		ebp, TheapItem(edi[eax*8]).Value
	mov		edx, TheapItem(edi[eax*8]).Item

	mov		TheapItem(edi[ebx*8]).Value, ebp	//lbh[i] := lbh[j]
	mov		TheapItem(edi[ebx*8]).Item, edx

	mov		esi[edx*4], ebx	//lIx[lbh[i].Item] := i
	mov		ebx, eax		//i := j

	dec		eax			//j := (i-1) shr 1
	test	ebx, ebx
	jnle	@loop

@found0:
	pop		Item
	pop		ebp
@found1:

	mov		TheapItem(edi[ebx*8]).Value, Value
	mov		TheapItem(edi[ebx*8]).Item, Item
	mov		esi[Item*4], ebx		//lIx[lbh[i].Item] := i

	mov		al, 1
	pop		ebx
	pop		edi
	pop		esi
end;
{$ENDIF}

function TQHPQ.Get(var Item, Value: integer): boolean;
{$IFNDEF ASSEMBLER}
var
	i, j, t,
	next:		integer;
	last:		TheapItem;
	lqh:		PItemArray;
begin
	if n = 0 then
	begin
		result := False;
		exit
	end;

	lqh := Hp;
	Value := lqh[0].Value;
	Item := lqh[0].Item;
	Ix[lqh[0].Item] := -1;

	dec(n);

	if n > 0 then
	begin
		last := lqh[n];
		i := 0;		j := 1;				//Child1(i) = i*4+1
		t := n-1;

		while j <= t do
		begin
			// Searching the minimum key among the childrens
			next := j;					//next := Child1(i)
			if j < t then
			begin
				Inc(j);						//Child2(i) = i*4+2
				if (lqh[j].Value < lqh[next].Value)then	next := j;
				if j < t then
				begin
					Inc(j);					//Child3(i) = i*4+3
					if (lqh[j].Value < lqh[next].Value)then	next := j;
					if(j < t) then
					begin
						Inc(j);				//Child4(i) = i*4+4
						if(lqh[j].Value < lqh[next].Value)then	next := j;
					end
				end
			end;

			if last.Value <= lqh[next].Value then		break;
			lqh[i].Value := lqh[next].Value;
			lqh[i].Item := lqh[next].Item;
			Ix[lqh[next].Item] := i;

			i := next;
			j := next * 4 + 1;			//Child1(i) = i*4+1
		end;

		lqh[i].Value := last.Value;
		lqh[i].Item := last.Item;
		Ix[lqh[i].Item] := i;
	end;

{
//	..Unrolled version

	if n > 0 then
	begin
		last := lqh[n];
		i := 0;		j := 1;				//Child1(i) = i*4+1
		t := n and not 3;

		while j < t do
		begin
			// Searching the minimum key among the childrens
			next := j;													//Child1(i) = i*4+1
			if(lqh[j+1].Value < lqh[next].Value)then	next := j+1;	//Child2(i) = i*4+2
			if(lqh[j+2].Value < lqh[next].Value)then	next := j+2;	//Child3(i) = i*4+3
			if(lqh[j+3].Value < lqh[next].Value)then	next := j+3;	//Child4(i) = i*4+4

			if last.Value <= lqh[next].Value then
				break;

			lqh[i].Value := lqh[next].Value;
			lqh[i].Item := lqh[next].Item;
			Ix[lqh[next].Item] := i;

			i := next;
			j := next * 4 + 1;			//Child1(i) = i*4+1
		end;

		if (j>=t)and(j < n)then
		begin
			t := n-1;
			// Searching the minimum key among the childrens
			next := j;					//next := Child1(i)
			if j < t then
			begin
				Inc(j);						//Child2(i) = i*4+2
				if (lqh[j].Value < lqh[next].Value)then	next := j;
				if j < t then
				begin
					Inc(j);					//Child3(i) = i*4+3
					if (lqh[j].Value < lqh[next].Value)then	next := j;
					if(j < t) then
					begin
						Inc(j);				//Child4(i) = i*4+4
						if(lqh[j].Value < lqh[next].Value)then	next := j;
					end
				end
			end;

			if last.Value > lqh[next].Value then
			begin
				lqh[i].Value := lqh[next].Value;
				lqh[i].Item := lqh[next].Item;
				Ix[lqh[next].Item] := i;
				i := next;
			end
		end;

		lqh[i].Value := last.Value;
		lqh[i].Item := last.Item;
		Ix[lqh[i].Item] := i;
	end;
}
	result := True
end;
{$ELSE}
register;
asm
	cmp		self.n, 0
	jnz		@begin
	xor		eax, eax
	ret
@begin:
	push	ebx
	push	esi

	push	edi
	mov		esi, self.Hp

	add		esp, -8
	mov		edi, TheapItem([esi]).Value	//Value := lbh[0].Value

	mov		ebx, TheapItem([esi]).Item	//Item := lbh[0].Item
	mov		[ecx], edi

	mov		edi, self.Ix
	mov		ecx, self.n

	mov		[edx], ebx
	dec		ecx

	mov		edi[ebx*4], -1		//Ix[Item] := -1
	mov		self.n, ecx			//n := n-1
	je		@done
//=================================================================
	mov		eax, TheapItem(esi[ecx*8]).Item		//last := lbh[n]
	mov		edx, TheapItem(esi[ecx*8]).Value

	mov		[esp+4], eax		//	last.Item
	lea		eax, [ecx-1]		//	t := n-1;

	mov		ebx, 1				// j := 1;
	xor		ecx, ecx			// i := 0;

	cmp		ebx, eax
	jg		@endLoop1

	mov		[esp], eax			// while j<=t
//=================================================================
	push	ebp
@loop:
//=================================================================
	mov		ebp, TheapItem(esi[ebx*8]).Value
	mov		eax, ebx								//next := j
	jnl		@0c
//=================================================================
	inc		ebx
	cmp		ebp, TheapItem(esi[ebx*8]).Value
	jle		@0a
	mov		ebp, TheapItem(esi[ebx*8]).Value
	mov		eax, ebx								//next := j+1
@0a:
	cmp		ebx, [esp+4]
	jnl		@0c
//=================================================================
	inc		ebx
	cmp		ebp, TheapItem(esi[ebx*8]).Value
	jle		@0b
	mov		ebp, TheapItem(esi[ebx*8]).Value
	mov		eax, ebx								//next := j+2
@0b:
	cmp		ebx, [esp+4]
	jnl		@0c
//=================================================================
//	inc		ebx
//	cmp		ebp, TheapItem(esi[ebx*8]).Value
//	jle		@0c
//	mov		ebp, TheapItem(esi[ebx*8]).Value
//	mov		eax, ebx								//next := j+3

	cmp		ebp, TheapItem(esi[ebx*8+8]).Value
	jle		@0c
	mov		ebp, TheapItem(esi[ebx*8+8]).Value
	lea		eax, [ebx+1]					//next := j+3
//=================================================================
@0c:
	cmp		ebp, edx							//last.Value
	jnl		@endLoop0			//break
//=================================================================
	mov		ebx, TheapItem(esi[eax*8]).Item
	mov		TheapItem(esi[ecx*8]).Value, ebp	//lbh[i] := lbh[j]

	mov		TheapItem(esi[ecx*8]).Item, ebx
	mov		edi[ebx*4], ecx	//Ix[lbh[i].Item] := i;

	lea		ebx, [4*eax+1]	//j := next*4+1
	mov		ecx, eax		//i := next
//	shl		ebx, 2
//	inc		ebx

	cmp		ebx, [esp+4]
	jle		@loop
@endLoop0:
	pop		ebp
//=================================================================
@endLoop1:
	mov		TheapItem(esi[ecx*8]).Value, edx	// last.Value

	mov		eax, [esp+4]						// last.Item
	mov		TheapItem(esi[ecx*8]).Item, eax

	mov		edi[eax*4], ecx	//Ix[last.Item] := i;
@done:
	add		esp, 8
	mov		al, 1
	pop		edi
	pop		esi
	pop		ebx
end;
{$ENDIF}

//=================== TRAPQ =======================
//	Some times is more efficient for short distances

constructor TRAPQ.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TheapItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TRAPQ.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TRAPQ.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	n := 0;
end;

function TRAPQ.Put(Item, Value: integer): boolean; //O(1)
var
	i:		integer;
	lra:	PItemArray;
begin
	i := Ix[Item];
	lra := Hp;

	if i >= 0 then
	begin
		if lra[i].Value <= Value then
		begin
			result := False;
			exit;
		end;
	end
	else
	begin
		i := n;
		Ix[Item] := i;
		lra[i].Item := Item;
		Inc(n);
	end;

	lra[i].Value := Value;
	result := True;

{$IFDEF STATISTICS}
	if n>MaxN then MaxN:=n
{$ENDIF}
end;

function TRAPQ.Get(var Item, Value: integer): boolean;	//O(n)
var
	i, t, minV, iMin:	integer;
	pMin, pN:			^TheapItem;
	lsa:				PItemArray;
begin
	if n = 0 then
	begin
		result := False;
		exit;
	end;

	lsa := Hp;
	iMin := 0;
	minV := lsa[0].Value;
	dec(n);

	for i := 1 to n do
	begin
		if lsa[i].Value < minV then
		begin
			minV := lsa[i].Value;
			iMin := i;
		end
	end;

	pMin := @lsa[iMin];

	Item := pMin^.Item;
	Value := pMin^.Value;

	if iMin < n then
	begin
		pN := @lsa[n];
		pMin^.Value := pN^.Value;
		t := pN^.Item;
		pMin^.Item := t;
		Ix[t] := iMin;
	end;

	result := True;
end;

//=================== TSAPQ =======================
//	Some times is more efficient for short distances

constructor TSAPQ.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TheapItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TSAPQ.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TSAPQ.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	n := 0;
end;

function TSAPQ.Put(Item, Value: integer): boolean; //O(n)
var
	i, j, t:	integer;
	lsa:		PItemArray;
	lIx:		PIntegerArray;
begin
	lIx := Ix;
	lsa := Hp;
	i := lIx[Item];

	if i < 0 then
	begin
		i := n;
		while i > 0 do
		begin
			if lsa[i-1].Value >= Value then
				break;
			lsa[i].Value := lsa[i-1].Value;
			t := lsa[i-1].Item;
			lsa[i].Item := t;
			lIx[t] := i;
			dec(i);
		end;
		lsa[i].Value := Value;
		lsa[i].Item := Item;
		lIx[lsa[i].Item] := i;

		Inc(n);
{$IFDEF STATISTICS}
		if n>MaxN then MaxN:=n;
{$ENDIF}
		result := True;
		exit;
	end
	else if lsa[i].Value <= Value then
	begin
		result := False;
		exit;
	end;

	j := n-1;
	while i<j do
	begin
		if lsa[i+1].Value <= Value then
			break;
		lsa[i].Value := lsa[i+1].Value;
		lsa[i].Item := lsa[i+1].Item;
		lIx[lsa[i].Item] := i;
		Inc(i);
	end;
	lsa[i].Value := Value;
	lsa[i].Item := Item;
	lIx[lsa[i].Item] := i;
	result := True;
end;

function TSAPQ.Get(var Item, Value: integer): boolean; //O(1)
begin
	if n = 0 then
	begin
		result := False;
		exit;
	end;

	dec(n);
	Item := Hp[n].Item;
	Value := Hp[n].Value;
	result := True;
end;

//========== TFIFO =======================
// Finds any valid path
constructor TFIFO.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(fV, fmax*SizeOf(integer));
	GetMem(fI, fmax*SizeOf(integer));
	Empty
end;

destructor TFIFO.Destroy;
begin
	FreeMem(fV);
	FreeMem(fI);
	inherited Destroy;
end;

procedure TFIFO.Empty;
begin
	FillChar(fV^, fmax*sizeOf(integer), 255);
	bufh := 0;
	bufe := 0;
end;

{$IFDEF DISPLAY}
function TFIFO.GetnItem: integer;
begin
	Result := bufe - bufh;
	if Result<0 then Inc(Result, fMax)
end;

function TFIFO.GetItem(Index: integer): integer;
begin
	if Index<0 then
	begin
		result := -1;
		exit
	end;

	Index := Index + bufh;
	if(Index>=bufe)and((bufe>bufh)or
		((bufe<bufh)and(Index<bufh)))then	result := -1
	else	result :=  fI[Index];
end;
{$ENDIF}

function TFIFO.Put(Item, Value: integer): boolean;
begin
	if Longword(fV[Item]) <= Longword(Value) then
	begin
		result := False;
		exit;
	end;

	fV[Item] := Value;
	fI[bufe] := Item;
	inc(bufe);
	if bufe >= fmax then bufe := 0;
	result := True;
end;

function TFIFO.Get(var Item, Value: integer): boolean;
begin
	if bufh = bufe then
	begin
		result := False;
		exit;			
	end;
	Item := fI[bufh];
	Value := fV[Item];
	inc(bufh);
	if bufh >= fmax then bufh := 0;
	result := True;
end;

//=================== TSDEBPQ =======================
//	Priority Queue based on Sorted double ended buffer
constructor TSDEBPQ.Create(max: integer);
begin
	inherited Create;
	fmax := max;
	GetMem(Hp, fmax*SizeOf(TheapItem));
	GetMem(Ix, fmax*SizeOf(integer));
	Empty
end;

destructor TSDEBPQ.Destroy;
begin
	FreeMem(Hp);
	FreeMem(Ix);
	inherited Destroy;
end;

procedure TSDEBPQ.Empty;
begin
	FillChar(Ix^, fmax*sizeOf(integer), 255);
	bufh := 0;	bufe := 0;
{$IFDEF STATISTICS}
	n := 0;
{$ENDIF}
end;

{$IFDEF DISPLAY}
function TSDEBPQ.GetnItem: integer;
begin
	Result := bufe - bufh;
	if Result<0 then Inc(Result, fMax)
end;

function TSDEBPQ.GetItem(Index: integer): integer;
begin
	if Index<0 then
	begin
		result := -1;
		exit
	end;

	Index := Index + bufh;
	if Index>=fMax then	Dec(Index, fMax);
	if((bufe>bufh)and((Index>=bufe)or(Index<bufh)))or
		((bufe<bufh)and(Index<bufh)and(Index>=bufe)) then	result := -1
	else	result :=  Hp[Index].Item;
end;
{$ENDIF}

{ $DEFINE SKIPEQUALS}

function TSDEBPQ.Put(Item, Value: integer): boolean;
{$IFNDEF ASSEMBLER}
var
	i, j, lbufp,
	lfmax:		integer;
{$IFDEF SKIPEQUALS}
	k, temp:	integer;
{$ENDIF}
	lsa:		PItemArray;
	lIx:		PIntegerArray;
begin
	lsa := Hp;
	lIx := Ix;

	i := lIx[Item];

	if i >= 0 then
	begin
		if lsa[i].Value <= Value then
		begin
			result := False;
			exit;
		end;
	end
	else
	begin
		i := bufe;
		j := bufe;
		inc(j);
		if j >= fmax then j := 0;
		bufe := j;
{$IFDEF STATISTICS}
		Inc(n);
		if n > MaxN then MaxN:= n;
{$ENDIF}
	end;
	lbufp := bufh;
	lfmax := fmax;
{$IFDEF SKIPEQUALS}
	k := i;
	if k = 0 then	k := lfmax;
	Dec(k);

	while i<>lbufp do
	begin
		j := k;

		temp := lsa[j].Value;
		if temp <= Value then
			break;

		if k = 0 then	k := lfmax;
		Dec(k);

		while(temp=lsa[k].Value)and(j<>lbufp)do
		begin
			j := k;
			if k = 0 then	k := lfmax;
			Dec(k);
		end;

		lsa[i].Value := temp;
		lsa[i].Item := lsa[j].Item;
		lIx[lsa[i].Item] := i;
		i := j;
	end;
{$ELSE}

	j := i;
	while j<>lbufp do
	begin
		if j = 0 then	j := lfmax;
		Dec(j);
		if lsa[j].Value <= Value then
			break;
		lsa[i].Value := lsa[j].Value;
		lsa[i].Item := lsa[j].Item;
		lIx[lsa[i].Item] := i;
		i := j;
	end;
{$ENDIF}
	lsa[i].Value := Value;
	lsa[i].Item := Item;
	lIx[lsa[i].Item] := i;

	result := True;
end;
{$ELSE}
register;
asm
	push	ebx
	push	ebp
	push	esi
	push	edi

	mov		esi, self.Ix
	mov		edi, self.Hp	//lsa := Hp

	mov		ebx, [esi+Item*4]	//i := Ix[Item]
	test	ebx, ebx

	jl		@a
//case i>=0
		//if lsa[i].Value <= Value then
	cmp		Value, [edi+ebx*8]	//TheapItem(edi[ebx*8]).Value
	jl		@b

	xor		eax, eax
	pop		edi
	pop		esi
	pop		ebp
	pop		ebx
	ret

//case i<0
@a:
	mov		ebp, self.bufe
	mov		ebx, ebp			//i := bufe
	inc		ebp
	cmp		ebp, self.fmax
	jl		@c
	xor		ebp, ebp
@c:
	mov		self.bufe, ebp
//=============================================
@b:
	add		esp, -8

	cmp		ebx, self.bufh		//While i <> bufh
	jz		@found1

	mov		[esp], Item

	mov		edx, self.fmax
	mov		[esp+4], edx

	mov		eax, self.bufh
	mov		edx, ebx		//j := i
//=============================================
@loop:
	test	edx, edx			//j=0
	jnz		@d
	mov		edx, [esp+4]
@d:
	dec		edx					//dec(j)

//	sub		edx, 1
//	ja		@d
///	mov		edx, [esp+4]
//	dec		edx
//@d:

	mov		ebp, [edi+edx*8]	// if lra[j].Value<=Value then break;
	cmp		ebp, Value
	jle		@found0

//	cmp		Value, [edi+edx*8]
//	jg		@found0
//  mov		ebp, [edi+edx*8]	// if lra[j].Value<=Value then break;

	mov		[edi+ebx*8], ebp	// lsa[i].Value := lsa[j].Value

	mov		ebp, [edi+edx*8+4]
	mov		[edi+ebx*8+4], ebp	// lsa[i].Item := lsa[j].Item

	mov		[esi+ebp*4], ebx	// Ix[lsa[i].Item] := i
	mov		ebx, edx			// i:=j

	cmp		edx, eax
	jnz		@loop
//=============================================
@found0:
	mov		Item, [esp]

@found1:
	mov		[edi+ebx*8], Value
	mov		[edi+ebx*8+4], Item
	mov		[esi+Item*4], ebx
	add		esp, 8
	mov		al, 1
	pop		edi
	pop		esi
	pop		ebp
	pop		ebx
end;
{$ENDIF}

function TSDEBPQ.Get(var Item, Value: integer): boolean; //O(1)
var
	i:		integer;
	lra:	PItemArray;
begin
	i := bufh;
	if i = bufe then
	begin
		result := False;
		exit;
	end;

	lra := Hp;
	Item := lra[i].Item;
	Value := lra[i].Value;

	inc(i);
	if i >= fmax then i := 0;
	bufh := i;
{$IFDEF STATISTICS}
	dec(n);
{$ENDIF}
	result := True;
end;

{$IFDEF STATISTICS}
initialization
	MaxN := 0;
	nAddNode := 0;
	nDecreaseKey := 0;
	nDeleteNode := 0;

	MaxD := 0.0;
	MaxI := 0.0;
	MaxT := 0.0;
	xx := 0;
	yy := 0;
	zz := 0;
{$ENDIF}
end.

