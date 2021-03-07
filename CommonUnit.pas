//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//Some useful utils and definitions

{$INCLUDE switches}
unit CommonUnit;

interface

uses
	Windows, Classes, Graphics, Protocol, PQUnit, OpenListUnit;

const
	ApplicationTitle = 'Map tool for C-Evo';
	lMaxMapSize = lxmax*lymax;
	maNextCity	= -1;
	cntWaterTiles = fUNKNOWN+1;
	cntLandTiles = fUNKNOWN+2;
	nPQ = 10;

type
	TIntegerArray = array[0..$40000000 div sizeof(integer)] of integer;
	PIntegerArray = ^TIntegerArray;

	TLocPoint = packed record
		X, Y, a, b:	Smallint;
	end;


	TRGB = packed record
		B, G, R: Byte;
	end;
	PRGB = ^TRGB;

	TRGBArray = packed array [0..$40000000 div sizeof(TRGB)] of TRGB;
	PRGBArray = ^TRGBArray;

	TFormationKind = (Hidden, Land, Water, Pole);

	TFormationInfo = record
		Kind:		TFormationKind;//(Hidden, Land, Water, Pole);
		Size:		integer;
		Presence:	array[0..nPl-1] of integer;
			//only for continents:
			//	Presence[Player] = -1 if no cities,
			//						0 if territory,
			//						>0 number of known cities
		Adjacent:	Cardinal;
			// bitset telling to which of the 32 biggest formations this one is adjacent
		FullyDiscovered:	boolean;
		IDLoc:				integer;
	end;
	PFormationInfo = ^TFormationInfo;

	TVicinity8Loc = array[0..7] of integer;
	TVicinity21Loc = array[0..27] of integer;

const
	FormationColors: Array [Hidden..Pole] of TColor =
		(0,			10 shl 16 + 240 shl 8+10,
		240 shl 16 + 180 shl 8,	240 shl 16 + 230 shl 8+230);

	Name_FormationKind: Array[Hidden..Pole] of string =
		('Hidden', 'Land', 'Water', 'Pole');

	TerrainColors: Array [-1..fMountains] of TColor =(
	 0,							//fUNKNOWN
	 255 shl 16,				//fOcean=$00
	 255 shl 16+255 shl 8,	 	//fShore=$01
	 255 shl 8,				 	//fGrass=$02
	 255 shl 8+255,			 	//fDesert=$03
	 155 shl 8+200,			 	//fPrairie=$04
	 255 shl 16+200 shl 8+220,	//fTundra=$05
	 250 shl 16+250 shl 8+220,	//fArctic=$06
	 200 shl 16+128 shl 8,		//fSwamp=$07
	 0,
	 200 shl 8,				 	//fForest=$09
	 155 shl 8+120,			 	//fHills=$0A
	 255 shl 16+255 shl 8+255);	//fMountains=$0B

	Name_TerrainType: Array[-1..fMountains] of string =(
		'UNKNOWN', 'Ocean', 'Coast', 'Grassland', 'Desert', 'Prairie',
		'Tundra',  'Arctic','Swamp', '',		  'Forest', 'Hills',
		'Mountains');

function RGBToColor(Val: TRGB): TColor;
function ColorToRGB(Val: TColor): TRGB;
procedure GenerateFormationsColors;
procedure PaintMiniMap(Bitmap: TBitmap; ShowTerritory: Boolean);
procedure PaintFormations(Bitmap: TBitmap; ShowTerritory: Boolean);
procedure PaintFeatures(Canvas: TCanvas; r, Width: Integer; ShowRoads, ShowTowns, ShowUnits: Boolean);

function UnitSpeed(uix: integer): integer;
function Valid(Loc: integer): Boolean;
procedure dxdy(Loc0, Loc1: integer; var dx, dy: integer);
function Relative(Loc, dx, dy: integer): integer;
function Distance(Loc0, Loc1: integer): integer;

procedure ab_to_Loc(Loc0, a, b: integer; var Loc: integer);
procedure Loc_to_ab(Loc0,Loc: integer; var a,b: integer);

procedure ab_to_V8(a, b: integer; var V8: integer);
procedure V8_to_ab(V8: integer; var a,b: integer);
procedure ab_to_V21(a,b: integer; var V21: integer);
procedure V21_to_ab(V21: integer; var a, b: integer);

procedure V21_to_Loc(Loc0: integer; var VicinityLoc: TVicinity21Loc);
procedure V8_to_Loc(Loc0: integer; var VicinityLoc: TVicinity8Loc);

var
	lx, ly,
	MapSize,
	MapWidth,
	MapHeight,
	Turn, xwMini,
	nFormation,
	Mode:			integer;
	decompose24:	cardinal;

	ShowPolitical:	Boolean;

	AIme:			Integer;
	MyUn:			Array [0..999] of TUn;
	MyModel:		Array [0..99] of TModel;
	MyCity:			Array [0..999] of TCity;
	MyEnemyUn:		Array [0..999] of TUnitInfo;
	MyEnemyModel:	Array [0..99] of TModelInfo;
	MyEnemyCity:	Array [0..999] of TCityInfo;

	XYab:			Array [0..lMaxMapSize-1] of TLocPoint;
	MyMap:			Array[0..lMaxMapSize-1] of Cardinal;
	ObservedLast:	Array[0..lMaxMapSize-1] of SmallInt;
	Territory:		Array[0..lMaxMapSize-1] of ShortInt;

	Occupant:		Array[0..lMaxMapSize-1] of shortint;

	FormationInfo:	array[-1..lMaxMapSize div 4] of	TFormationInfo;
	iFormation:		array[0..lMaxMapSize-1] of integer;
	mColors:		array [-1..lMaxMapSize div 4] of TColor;
	TribeColors:	array[0..nPl-1] of TColor;

	tCount:			array[0..cntLandTiles] of integer;

	PQArray:		Array [0..nPQ-1] of TBasePQ;
	OpenList:		TOpenList;
	UserLayers:		TList;

const
		RO: TPlayerContext=(
			Map:@MyMap;	MapObservedLast:@ObservedLast;	Territory:@Territory;Un:@MyUn;
			City:@MyCity;	Model:@MyModel;	EnemyUn:@MyEnemyUn;
			EnemyCity:@MyEnemyCity; EnemyModel:@MyEnemyModel);

implementation

uses
	MainUnit, UserLayerUnit;
	
const
	ab_v8:	array[-4..4] of integer = (5, 6, 7, 4,-1, 0, 3, 2, 1);
	v8_a:	array[ 0..7] of integer = (1, 1, 0,-1,-1,-1, 0, 1);
	v8_b:	array[ 0..7] of integer = (0, 1, 1, 1, 0,-1,-1,-1);

//=========== Graphic  functions ==============================================
function RGBToColor(Val: TRGB): TColor;
begin
	Result := Val.R+(Val.G shl 8)+(Val.B shl 16)
end;

function ColorToRGB(Val: TColor): TRGB;
begin
	Result.R := Val and 255;
	Result.G := (Val shr 8)and 255;
	Result.B := (Val shr 16)and 255;
end;

procedure GenerateFormationsColors;
var
	i, j, k, Ws,
	Ls, L, W:		integer;
	RGB:			TRGB;
begin
	Ls:=-1; 		Ws:= -1;
	L := 0;			W := 0;
	for i := 0 to nFormation-1 do
	begin
		if FormationInfo[i].Kind = Land then
		begin
			if FormationInfo[i].Size <> Ls then
				inc(L);
			Ls := FormationInfo[i].Size
		end
		else if FormationInfo[i].Kind = Water then
		begin
			if FormationInfo[i].Size <> Ws then
				inc(W);
			Ws := FormationInfo[i].Size
		end;
	end;

	Ws := -1;		Ls := -1;
	j := 0;			k := 0;

	for i := 0 to nFormation-1 do
	begin
		case FormationInfo[i].Kind of
		Hidden,	Pole:
			mColors[i] := FormationColors[FormationInfo[i].Kind];
		Land:
			begin
				RGB := ColorToRGB(FormationColors[Land]);

				RGB.B := RGB.B *(L-j) div L;
				RGB.G := RGB.G *(L-j) div L;
				RGB.R := RGB.R *(L-j) div L;
				mColors[i] := RGBToColor(RGB);
				if FormationInfo[i].Size <> Ls then
					inc(j);
				Ls := FormationInfo[i].Size;
			end;
		Water:
			begin
				RGB := ColorToRGB(FormationColors[Water]);

				RGB.B := RGB.B *(W-k) div W;
				RGB.G := RGB.G *(W-k) div W;
				RGB.R := RGB.R *(W-k) div W;
				mColors[i] := RGBToColor(RGB);

				if FormationInfo[i].Size <> Ws then
					inc(k);
				Ws := FormationInfo[i].Size;
			end;
		end;
	end;
end;

procedure PaintMiniMap(Bitmap: TBitmap; ShowTerritory: Boolean);
type
	TLine = array[0..99999999, 0..2] of Byte;
var
	x, y, i,
	Loc, cm,
	cp, xm:		integer;
	CurrLine:	^TLine;
begin
	with Bitmap.Canvas do
	begin
		Brush.Color := TerrainColors[-1];
		FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
	end;

	for y := 0 to ly-1 do
	begin
		CurrLine := Bitmap.ScanLine[y];

		for x := 0 to lx-1 do
			if RO.Map[x + lx*y] and fTerrain<>fUNKNOWN then
			begin
				Loc := x + lx*y;
				cm := TerrainColors[RO.Map[Loc] and fTerrain];
				if ShowTerritory and(RO.Territory[Loc]>=0)then
				begin
					if RO.Territory[Loc]=AIme then
						cp := RGB(255, 0, 0)
					else
						cp := TribeColors[RO.Territory[Loc] and 15];
					cm := ((cm and $FFFEFEFF)+(cp and $FFFEFEFF))shr 1;
				end;

				for i := 0 to 1 do
				begin
					xm := (x-xwMini)*2 + i + (y and 1);
					while xm < 0 do		inc(xm, 2*lx);
					while xm >= 2*lx do	dec(xm, 2*lx);

					CurrLine[xm, 0]:=cm shr 16;
					CurrLine[xm, 1]:=cm shr 8 and $FF;
					CurrLine[xm, 2]:=cm and $FF;
				end;
			end;
	end;
end;

procedure PaintFormations(Bitmap: TBitmap; ShowTerritory: Boolean);
var
	x, y, i, Loc,
	xm:				integer;
	cm, cp:			TColor;
	CurrLine:		PRGBArray;
begin
	with Bitmap.Canvas do
	begin
		Brush.Color := FormationColors[Hidden];
		FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
	end;

	for y := 0 to ly-1 do
	begin
		CurrLine := Bitmap.ScanLine[y];
		for x := 0 to lx-1 do
			if FormationInfo[iFormation[x+lx*y]].Kind<>Hidden then
			begin
				Loc := x + lx*y;
				cm := mColors[iFormation[x+lx*y]];
				if ShowTerritory and(RO.Territory[Loc]>=0)then
				begin
					if RO.Territory[Loc]=AIme then
						cp := RGB(255, 0, 0)
					else
						cp := TribeColors[RO.Territory[Loc] and 15];
					cm := ((cm and $FFFEFEFF)+(cp and $FFFEFEFF))shr 1;
				end;

				for i := 0 to 1 do
				begin
					xm := (x-xwMini)*2 + i + (y and 1);
					while xm < 0 do		inc(xm, 2*lx);
					while xm >= 2*lx do	dec(xm, 2*lx);
					CurrLine^[xm] := ColorToRGB(cm);
				end;
			end
	end;
end;

procedure PaintFeatures(Canvas: TCanvas; r, Width: Integer; ShowRoads, ShowTowns, ShowUnits: Boolean);
var
	x0, y0, x, y,
	xm, ym, ll, i,
	Loc, Loc1,
	ym0, lx2:		integer;
	RR:				Boolean;
begin
	with Canvas do
	begin
		if ShowRoads then
		begin
			Pen.Mode := pmCopy;
			ll := 0;	lx2 := 2*lx;
			for ym := 0 to ly - 1 do
			begin
				ym0 := ym and 1;
				for xm := 0 to lx-1 do
				begin
					Loc := ll + xm;
					if MyMap[Loc] and (fRoad+fRR+fCity)<>0 then
					begin
						RR := MyMap[Loc] and (fRR+fCity)<>0;
						MainForm.LocToClient(Loc, x0, y0);

						if ym >= 1 then
						begin
							Loc1 := Loc-lx2;
							if (Loc1 >= 0) and (MyMap[Loc1] and (fRoad+fRR+fCity)<>0) then
							begin
								MoveTo(x0, y0);
								MainForm.LocToClient(Loc1, x, y);
								if RR and(MyMap[Loc1] and(fRR+fCity)<>0)then
									Pen.Color := 0
								else	Pen.Color := RGB(128, 128, 0);

								if abs(x0-x) > Width shr 1 then
								begin	x := 0;	end;

								LineTo(x, y);	//	^
							end;

							if xm + ym0 - 1 >= 0 then	Loc1 := Loc-lx + ym0 - 1
							else						Loc1 := Loc + ym0 - 1;
							if (Loc1 >= 0)and(MyMap[Loc1] and (fRoad+fRR+fCity)<>0) then
							begin
								MoveTo(x0, y0);
								MainForm.LocToClient(Loc1, x, y);
								if RR and(MyMap[Loc1] and(fRR+fCity)<>0)then
									Pen.Color := 0
								else	Pen.Color := RGB(128, 128, 0);

								if abs(x0-x) > Width shr 1 then
								begin
									x := 0;	dec(y, r shr 1);
								end;
								LineTo(x, y);	//	^-
							end;

							if xm + ym0 < lx then	Loc1 := Loc-lx + ym0
							else					Loc1 := Loc-lx2 + ym0;

							if (Loc1 >= 0)and(MyMap[Loc1] and (fRoad+fRR+fCity)<>0) then
							begin
								MoveTo(x0, y0);
								MainForm.LocToClient(Loc1, x, y);
								if RR and(MyMap[Loc1] and(fRR+fCity)<>0)then
									Pen.Color := 0
								else	Pen.Color := RGB(128, 128, 0);

								if abs(x0-x) > Width shr 1 then
								begin	x := Width;	dec(y, r shr 1);	end;
								LineTo(x, y);	//	-^
							end;
						end;

						if xm >= 1 then	Loc1 := Loc-1
						else			Loc1 := Loc+lx-1;

						if(Loc1>=0)and(Loc1<MapSize)and(MyMap[Loc1]and(fRoad+fRR+fCity)<>0)then
						begin
							MoveTo(x0, y0);
							MainForm.LocToClient(Loc1, x, y);
							if RR and(MyMap[Loc1] and(fRR+fCity)<>0)then
								Pen.Color := 0
							else	Pen.Color := RGB(128, 128, 0);

							if abs(x0-x)>MainForm.MiniImg.Width shr 1 then
							begin	x := 0;	end;
							LineTo(x, y);	//	<-
						end;

{						if (xm < MapSize-lx2-1) and (MyMap[Loc+lx2] and (fRoad+fRR+fCity)<>0) then
						begin
							PaintBox1.Canvas.MoveTo(x0, y0);
							LocToClient(Loc+lx2, x, y);
							if RR and(MyMap[Loc+lx2] and(fRR+fCity)<>0)then
								Pen.Color := 0
							else	Pen.Color := RGB(128, 128, 0);

							if abs(x0-x)>MiniImg.Width shr 1 then
							begin	x := 0;	end;
							PaintBox1.Canvas.LineTo(x, y);	//	<-
						end;	}
					end;
				end;
				inc(ll, lx);
			end;
		end;

		if ShowTowns then
		begin
			Pen.Color := 0;
			Brush.Color := RGB(255, 0, 0);
			Pen.Mode := pmCopy;
			for i := 0 to RO.nCity-1 do if RO.City[i].Loc>0 then
			begin
				MainForm.LocToClient(RO.City[i].Loc, x, y);
				Ellipse(x-r, y-r, x+r, y+r);
			end;

			for i := 0 to RO.nEnemyCity-1 do if RO.EnemyCity[i].Loc>0 then
			begin

				Brush.Color := TribeColors[RO.EnemyCity[i].Owner];
				MainForm.LocToClient(RO.EnemyCity[i].Loc, x, y);
				Ellipse(x-r, y-r,x+r, y+r);
			end;
		end;

		if ShowUnits then
		begin
			r := r shr 1;

			Pen.Color := 0;
			Brush.Color := RGB(255, 0, 0);
			Pen.Mode := pmCopy;

			for i := 0 to RO.nUn-1 do if RO.Un[i].Loc>0 then
			begin
				MainForm.LocToClient(RO.Un[i].Loc, x, y);
				Ellipse(x-r, y-r, x+r, y+r);
			end;

			for i := 0 to RO.nEnemyUn-1 do if RO.EnemyUn[i].Loc>0 then
			begin
				Brush.Color := TribeColors[RO.EnemyUn[i].Owner];
				MainForm.LocToClient(RO.EnemyUn[i].Loc, x, y);
				Ellipse(x-r, y-r,x+r, y+r);
			end;
		end;
	end
end;

//=============== Other functions ==============================================
function UnitSpeed(uix: integer): integer;
var
	Model:	^TModel;
begin
	Model := @RO.Model[RO.Un[uix].mix];
	result := Model^.Speed;
	if Model^.Domain = dSea then
	begin
		if RO.Wonder[woMagellan].EffectiveOwner=AIme then
			inc(result, 200);
		if RO.Un[uix].Health<100 then
			result:=((result-250)*RO.Un[uix].Health div 5000)*50+250;
	end
end;

function Valid(Loc: integer): Boolean;
begin
	Valid := (Loc>=0)and(Loc<MapSize)
end;

function Distance(Loc0, Loc1: integer): integer;
var
	y0, y1,
	x0, x1,
	dx, dy: integer;
begin
	y0 := XYab[Loc0].Y;		x0 := XYab[Loc0].X;
	y1 := XYab[Loc1].Y;		x1 := XYab[Loc1].X;

	dx := abs((x1 - x0 + 3*lx)mod(2*lx)-lx);
	dy := abs(y1 - y0);

	result := dx + dy + abs(dx-dy) shr 1;
end;

{relative location, dx in hor and dy in ver direction from Loc}
function Relative(Loc, dx, dy: integer): integer;
var
	x, y0: integer;
begin
	assert((Loc>=0) and (Loc<MapSize) and (dx+lx>=0));

	y0 := XYab[Loc].Y;
	x := ((Loc - y0*lx) shl 1 + dx + y0 and 1+ lx + lx) shr 1;

	while x < lx do Inc(x, lx);
	while x >= lx do Dec(x, lx);

	result := x + lx*(y0 + dy);

	if (result < 0) or (result>=MapSize) then result:=-1;
end;

{relative location from Loc0}
procedure ab_to_Loc(Loc0, a, b: integer; var Loc: integer);
var
	y0:	integer;
begin
	assert((Loc0>=0) and (Loc0<MapSize) and (a-b+lx>=0));
	y0 := cardinal(Loc0)*decompose24 shr 24;
	Loc := (Loc0 + (a - b + y0 and 1+lx+lx) shr 1) mod lx + lx*(y0+a+b);
	if Loc>=MapSize then Loc:=-$1000
end;

procedure dxdy(Loc0, Loc1: integer; var dx, dy: integer);
var
	y0, y1,
	x0, x1: integer;
begin
	y0 := XYab[Loc0].Y;		x0 := XYab[Loc0].X;
	y1 := XYab[Loc1].Y;		x1 := XYab[Loc1].X;

	dx := (x1 - x0 + 3*lx)mod(2*lx)-lx;
	dy := y1 - y0;
end;

procedure Loc_to_ab(Loc0, Loc: integer; var a, b: integer);
{$IFDEF FPC} // freepascal
var
	dx, dy: integer;
begin
	dx :=	((Loc mod lx *2 +Loc div lx and 1)
			-(Loc0 mod lx *2 +Loc0 div lx and 1)+3*lx) mod (2*lx) -lx;
	dy :=	Loc div lx-Loc0 div lx;

	a := (dx+dy) div 2;
	b := (dy-dx) div 2;
end;
{$ELSE} // delphi
register;
asm
push ebx

// calculate
push ecx
div byte ptr [lx]
xor ebx,ebx
mov bl,ah  // ebx:=Loc0 mod G.lx
mov ecx,eax
and ecx,$000000FF // ecx:=Loc0 div G.lx
mov eax,edx
div byte ptr [lx]
xor edx,edx
mov dl,ah // edx:=Loc mod G.lx
and eax,$000000FF // eax:=Loc div G.lx
sub edx,ebx // edx:=Loc mod G.lx-Loc0 mod G.lx
mov ebx,eax
sub ebx,ecx // ebx:=dy
and eax,1
and ecx,1
add edx,edx
add eax,edx
sub eax,ecx // eax:=dx, not normalized
pop ecx

// normalize
mov edx,dword ptr [lx]
cmp eax,edx
jl @a
  sub eax,edx
  sub eax,edx
  jmp @ok
@a:
neg edx
cmp eax,edx
jnl @ok
  sub eax,edx
  sub eax,edx

// return results
@ok:
mov edx,ebx
sub edx,eax
add eax,ebx
sar edx,1 // edx:=b
mov ebx,[b]
mov [ebx],edx
sar eax,1 // eax:=a
mov [a],eax

pop ebx
end;
{$ENDIF}

procedure ab_to_V8(a, b: integer; var V8: integer);
begin
	assert((abs(a)<=1) and (abs(b)<=1) and ((a<>0) or (b<>0)));
	V8 := ab_v8[2*b+b+a];
end;

procedure V8_to_ab(V8: integer; var a, b: integer);
begin
	a := v8_a[V8];	b:=V8_b[V8];
end;

procedure ab_to_V21(a,b: integer; var V21: integer);
begin
	V21 := (a+b+3) shl 2+(a-b+3) shr 1;
end;

procedure V21_to_ab(V21: integer; var a, b: integer);
var
	dx, dy: integer;
begin
	dy := V21 shr 2-3;
	dx := V21 and 3 shl 1 -3 + (dy+3) and 1;
	a := (dx+dy) div 2;
	b := (dy-dx) div 2;
end;

procedure V8_to_Loc(Loc0: integer; var VicinityLoc: TVicinity8Loc);
var
	x0, y0, lx0: integer;
begin
	lx0 := lx;				// put in register!
	y0:=cardinal(Loc0)*decompose24 shr 24;		//y0 := Loc0 div lx0;
	x0 := Loc0-y0*lx0;		// Loc0 mod lx;
	y0 := y0 and 1;
	VicinityLoc[1] := Loc0 + lx0*2;
	VicinityLoc[3] := Loc0 - 1;
	VicinityLoc[5] := Loc0 - lx0*2;
	VicinityLoc[7] := Loc0 + 1;

	inc(Loc0, y0 and 1);	//inc(Loc0, y0);
	VicinityLoc[0] := Loc0 + lx0;
	VicinityLoc[2] := Loc0 + lx0-1;
	VicinityLoc[4] := Loc0 - lx0-1;
	VicinityLoc[6] := Loc0 - lx0;

// world is round!
	if x0<lx0-1 then
	begin
		if x0=0 then
		begin
			inc(VicinityLoc[3], lx0);
			if y0 and 1=0 then
			begin
				inc(VicinityLoc[2],lx0);
				inc(VicinityLoc[4],lx0);
			end
		end
	end
	else
	begin
		dec(VicinityLoc[7], lx0);
		if y0 and 1 =1 then
		begin
			dec(VicinityLoc[0],lx0);
			dec(VicinityLoc[6],lx0);
		end
	end;

// check south pole
	case ly-y0 of
	1:
	begin
		VicinityLoc[0]:=-$1000;
		VicinityLoc[1]:=-$1000;
		VicinityLoc[2]:=-$1000;
	end;
	2:	VicinityLoc[1]:=-$1000;
	end;
end;

procedure V21_to_Loc(Loc0: integer; var VicinityLoc: TVicinity21Loc);
var
	dx, dy, bit, y0,
	xComp, yComp, xComp0,
	xCompSwitch:		integer;
	dst:				^integer;
begin
	y0 := cardinal(Loc0)*decompose24 shr 24; //y0 := Loc0 div lx;
	xComp0 := Loc0 - y0*lx-1;				// Loc0 mod lx -1
	xCompSwitch := xComp0-1+y0 and 1;
	if xComp0<0 then inc(xComp0, lx);
	if xCompSwitch<0 then inc(xCompSwitch, lx);
	xCompSwitch := xCompSwitch xor xComp0;
	yComp := lx*(y0-3);
	dst := @VicinityLoc;
	bit := 1;
	for dy := 0 to 6 do
		if yComp < MapSize then
		begin
			xComp0:=xComp0 xor xCompSwitch;
			xComp:=xComp0;
			for dx := 0 to 3 do
			begin
				if bit and $67F7F76<>0 then dst^ := xComp+yComp
				else dst^ := -1;
				inc(xComp);
				if xComp>=lx then dec(xComp, lx);
				inc(dst);
				bit:=bit shl 1;
			end;
			inc(yComp,lx);
		end
		else
			for dx := 0 to 3 do
				begin dst^:=-$1000; inc(dst); end;
end;

var
	i:	integer;
initialization
	FillChar(PQArray, SizeOf(PQArray), 0);
	PQArray[0] := TBHPQ.Create(lMaxMapSize);
	PQArray[1] := TQHPQ.Create(lMaxMapSize);
	PQArray[2] := TRAPQ.Create(lMaxMapSize);
	PQArray[3] := TSAPQ.Create(lMaxMapSize);
	PQArray[4] := TFIFO.Create(lMaxMapSize);
	PQArray[5] := TSDEBPQ.Create(lMaxMapSize);
	OpenList := TOpenList.Create(lMaxMapSize);

	Randomize;

	AIme := nPl-1;
	RO.Alive := $7FFFF;
	RO.nUn := 0;
	MyModel[0] := SpecialModel[0];
	MyModel[0].Flags := mdZOC or mdCivil;
	MyModel[1] := SpecialModel[2];
	MyModel[1].Flags := mdZOC;
	MyModel[2] := SpecialModel[8];
	MyModel[2].Flags := mdZOC;
	MyModel[3] := SpecialModel[6];
	RO.nModel := 4;

	MakeModelInfo(0, 0, SpecialModel[8], MyEnemyModel[0]);
	MakeModelInfo(0, 0, SpecialModel[6], MyEnemyModel[1]);
	RO.nEnemyModel := 2;

	for i := 0 to nPl-1 do
	begin
		RO.Treaty[i] := -1;
		TribeColors[i] := RGB(Random(255), Random(255), Random(255));
	end;

	UserLayers := TList.Create;

finalization
	for i := 0 to nPQ-1 do
		if Assigned(PQArray[i]) then PQArray[i].Free;
	OpenList.Free;

	for i:= 0 to UserLayers.Count-1 do
		TUserLayer(UserLayers.Items[i]).Free;
	UserLayers.Free;

end.


