//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//	Dijksta's and A* pathfinding algoritms analisis.
// Based on GetMoveAdvice function at Core.Pas C-evo 0.14.1 (http://C-Evo.org/)

{$INCLUDE switches}
unit GetMoveAdviceUnit;

interface

uses Protocol, PQUnit;

const
	eMountains=$6000FFFF;	// additional return code for server internal use

function RandomData(Radius: integer; PQ: TBasePQ): integer;
function Imitator(uix: integer; var a: TMoveAdviceData; PQ: TBasePQ): integer;

function GetMoveAdvice(uix: integer; var a: TMoveAdviceData; PQ: TBasePQ): integer;
function GetMoveAdviceA(uix: integer; var a: TMoveAdviceData): integer;

implementation

uses
	Windows, Graphics, SysUtils, Math, Forms, CommonUnit, MainUnit, OpenListUnit;

//===============================================================================
function RandomData(Radius: integer; PQ: TBasePQ): integer;
var
	i, j, N, M, T:		integer;
begin
//	N := Radius div 10;
	PQ.Empty;
	PQ.Put(0, 0);

	for i := 1 to Radius-1 do
	begin
		PQ.Get(M, T);
		for j := 0 to 8 do
			PQ.Put(i, 10+Random(5))
	end;
	result := eOK
end;

function Imitator(uix: integer; var a: TMoveAdviceData; PQ: TBasePQ): integer;
var
{$IFDEF DISPLAY}
	k:								Double;
	Rect:							TRect;
	Bitmap, OffScreen:				TBitmap;
	j, l, x, y, r, Color:			integer;
{$ENDIF}

	FromLoc, Radius:				integer;
	N, V8, MoveCost,
	Loc, Loc1, T:					integer;
	Adjacent:						TVicinity8Loc;
	Time:							array[0..lxmax*lymax-1] of integer;
begin
{$IFDEF DISPLAY}
	Bitmap := TBitmap.Create;
	Bitmap.Height := MainForm.MiniImg.Picture.Bitmap.Height;
	Bitmap.Width := MainForm.MiniImg.Picture.Bitmap.Width;
	Bitmap.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;

	OffScreen := TBitmap.Create;
	OffScreen.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;
	r := Round(Min(MainForm.MiniImg.Height/MainForm.MiniImg.Picture.Graphic.Height,
						MainForm.MiniImg.Width/MainForm.MiniImg.Picture.Graphic.Width));
	if r < 2 then r := 2;
{$ENDIF}

	FromLoc := RO.Un[uix].Loc;
//	Radius := Distance(FromLoc, a.ToLoc);
	result := eOK;

	FillChar(Time, SizeOf(Time), 255); {-1}
	PQ.Empty;
	PQ.Put(FromLoc, 0);

//	for i := 0 to Radius-1 do
//	begin
		while PQ.Get(Loc, T) do
		begin
{$IFDEF DISPLAY}
			if MainForm.bBreak then exit;
			PaintMiniMap(Bitmap, False);
			OffScreen.Height := MainForm.PaintBox1.Height;
			OffScreen.Width := MainForm.PaintBox1.Width;

			Rect := MainForm.PaintBox1.BoundsRect;
			OffsetRect(Rect, -MainForm.PaintBox1.Left, -MainForm.PaintBox1.Top);

			OffScreen.Canvas.StretchDraw(OffScreen.Canvas.ClipRect, Bitmap);
			PaintFeatures(OffScreen.Canvas, r, MainForm.MiniImg.Width,
					MainForm.RoadsChBox.Checked, MainForm.TownsChBox.Checked,
					MainForm.UnitsChBox.Checked);

			OffScreen.Canvas.Pen.Width := 1;
			OffScreen.Canvas.CopyMode := cmSrcCopy;

			n := PQ.nItem;
			if n>0 then		k := 255 / n
			else			k := 0;

			MainForm.Label1.Caption := 'N = '+IntToStr(n);

			if n>0 then
			begin
				for j := 0 to n-1 do
				begin
					Color := Round(k*(j+1));
					OffScreen.Canvas.Brush.Color := RGB(Color, 255-Color, 255-Color);
					OffScreen.Canvas.Pen.Color := 0;//RGB(Color, 255-Color, 255-Color);
					l := PQ.Item[j];
					MainForm.LocToClient(l, x, y);
					OffScreen.Canvas.Ellipse(x-2, y-2,x+2, y+2);
				end;
			end;

			MainForm.PaintBox1.Canvas.CopyRect(Rect, OffScreen.Canvas, OffScreen.Canvas.ClipRect);
			Application.ProcessMessages;
{$ENDIF}
//==================================================================
			Time[Loc] := T;
			if Loc = a.ToLoc then break;

			V8_to_Loc(Loc, Adjacent);

			for V8 := 0 to 7 do
			begin
				Loc1 := Adjacent[V8];

				MoveCost := 50;
				if V8 and 1<>0 then		inc(MoveCost, MoveCost shl 1)
				else					inc(MoveCost, MoveCost);

				if(Loc1 >= 0)and(Loc1 < MapSize-1)and(Time[Loc1] < 0)then
					PQ.Put(Loc1, T+MoveCost)
			end;
		end;
//	end;

{$IFDEF DISPLAY}
	Bitmap.Free;
	OffScreen.Free;
{$ENDIF}
end;

//Code From C-Evo 0.14.1

function GetMoveAdvice(uix: integer; var a: TMoveAdviceData; PQ: TBasePQ): integer;
const
	//domains
	gmaAir=0; gmaSea=1; gmaGround_NoZoC=2; gmaGround_ZoC=3;
	//flags
	gmaNav=4; gmaOver=4; gmaAlpine=8;
var
{$IFDEF DISPLAY}
	k:								Double;
	Rect:							TRect;
	Bitmap, OffScreen:				TBitmap;
	n, j, l, x, y,
	x1, y1, r, Color:				integer;
{$ENDIF}

	i, FromLoc, EndLoc, T, T1, maxmov,
	initmov, Loc, Loc1, FromTile,
	ToTile, V8, MoveInfo, HeavyCost,
	RailCost, MoveCost, AddDamage, MaxDamage:	integer;
	Map:										^TTileList;
	Adjacent:									TVicinity8Loc;
	From:										array[0..lxmax*lymax-1] of integer;
	Time:										array[0..lxmax*lymax-1] of integer;
	Damage:										array[0..lxmax*lymax-1] of integer;
	MountainDelay, Resistant:					boolean;
//  tt,tt0: int64;
begin
//  QueryPerformanceCounter(tt0);
{$IFDEF DISPLAY}
	Bitmap := TBitmap.Create;
	Bitmap.Height := MainForm.MiniImg.Picture.Bitmap.Height;
	Bitmap.Width := MainForm.MiniImg.Picture.Bitmap.Width;
	Bitmap.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;

	OffScreen := TBitmap.Create;
	OffScreen.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;
	r := Round(Min(MainForm.MiniImg.Height/MainForm.MiniImg.Picture.Graphic.Height,
						MainForm.MiniImg.Width/MainForm.MiniImg.Picture.Graphic.Width));
	if r < 2 then r := 2;
{$ENDIF}

	MaxDamage := RO.Un[uix].Health-1;
	if MaxDamage > a.MaxHostile_MovementLeft then
		if a.MaxHostile_MovementLeft>=0 then
			MaxDamage := a.MaxHostile_MovementLeft
		else
			MaxDamage := 0;

	Map:=@RO.Map^;
	if (a.ToLoc<>maNextCity) and ((a.ToLoc<0) or (a.ToLoc>=MapSize)) then
	begin result:=eInvalid; exit end;

	if (a.ToLoc<>maNextCity) and (Map[a.ToLoc] and fTerrain=fUNKNOWN) then
	begin result:=eNoWay; exit end;

	with RO.Model[RO.Un[uix].mix] do
	case Domain of
	dGround:
		if (a.ToLoc<>maNextCity) and (Map[a.ToLoc] and fTerrain=fOcean) then
		begin result:=eDomainMismatch; exit end
		else
		begin
			if Flags and mdZOC<>0 then MoveInfo:=gmaGround_ZoC
			else MoveInfo:=gmaGround_NoZoC;
			if Cap[mcOver]>0 then inc(MoveInfo,gmaOver);
			if Cap[mcAlpine]>0 then inc(MoveInfo,gmaAlpine);
			HeavyCost:=50+(Speed-150)*13 shr 7;
			if RO.Wonder[woShinkansen].EffectiveOwner=AIMe then RailCost:=0
			else RailCost := Speed*(4*1311) shr 17;
			maxmov := Speed;
			initmov := 0;
			Resistant := RO.Wonder[woGardens].EffectiveOwner=AIMe;
		end;
	dSea:
		if (a.ToLoc<>maNextCity) and (Map[a.ToLoc] and fTerrain>=fGrass)
		and (Map[a.ToLoc] and (fCity or fUnit or fCanal)=0) then
		begin result:=eDomainMismatch; exit end
		else
		begin
			MoveInfo:=gmaSea;
			if Cap[mcNav]>0 then inc(MoveInfo,gmaNav);
//			maxmov:=UnitSpeed(Player,RW[Player].Un[uix].mix,100);
//			initmov:=maxmov-UnitSpeed(Player,RW[Player].Un[uix].mix, RW[Player].Un[uix].Health);
			maxmov := Speed;
			if RO.Wonder[woMagellan].EffectiveOwner = AIme then
				inc(maxmov, 200);
			initmov := maxmov - UnitSpeed(uix);
		end;
	dAir:
		begin
			MoveInfo:=gmaAir;
			maxmov:=Speed;
			initmov:=0;
		end
	end;

	FromLoc:=RO.Un[uix].Loc;
	FillChar(Time, SizeOf(Time),255); {-1}
//	FillChar(From, SizeOf(From),255); {-1}
	Damage[FromLoc]:=0;
//	Q:=TIPQ.Create(MapSize);
	PQ.Empty;
	PQ.Put(FromLoc,(maxmov-RO.Un[uix].Movement) shl 8);
	while PQ.Get(Loc,T) do
	begin
{$IFDEF DISPLAY}
		if MainForm.bBreak then exit;
		PaintMiniMap(Bitmap, False);
		OffScreen.Height := MainForm.PaintBox1.Height;
		OffScreen.Width := MainForm.PaintBox1.Width;

		Rect := MainForm.PaintBox1.BoundsRect;
		OffsetRect(Rect, -MainForm.PaintBox1.Left, -MainForm.PaintBox1.Top);

		OffScreen.Canvas.StretchDraw(OffScreen.Canvas.ClipRect, Bitmap);

		OffScreen.Canvas.Pen.Width := 1;
		OffScreen.Canvas.CopyMode := cmSrcCopy;

		PaintFeatures(OffScreen.Canvas, r, MainForm.MiniImg.Width,
				MainForm.RoadsChBox.Checked, MainForm.TownsChBox.Checked,
				MainForm.UnitsChBox.Checked);

		n := PQ.nItem;
		if n>0 then		k := 255 / n
		else			k := 0;


		MainForm.Label1.Caption := 'N = '+IntToStr(n);
		if n>0 then
		begin
			for j := 0 to n-1 do
			begin
				Color := Round(k*(j+1));
				OffScreen.Canvas.Brush.Color := RGB(Color, 255-Color, 255-Color);
				OffScreen.Canvas.Pen.Color := 0;//RGB(Color, 255-Color, 255-Color);
				l := PQ.Item[j];
				MainForm.LocToClient(l, x, y);
				OffScreen.Canvas.Ellipse(x-2, y-2,x+2, y+2);
			end;
		end;

		MainForm.PaintBox1.Canvas.CopyRect(Rect, OffScreen.Canvas, OffScreen.Canvas.ClipRect);
		Application.ProcessMessages;
{$ENDIF}
//==================================================================
		Time[Loc]:=T;
		if T >= (a.MoreTurns+1) shl 20 then
		begin Loc:=-1; Break end;

		FromTile := Map[Loc];
		if(Loc = a.ToLoc)or(a.ToLoc = maNextCity)and(FromTile and fCity<>0)then
			Break;

		if T and $FFF00 = $FFF00 then inc(T, $100000); // indicates mountain delay

		V8_to_Loc(Loc, Adjacent);
		for V8 := 0 to 7 do
		begin
			Loc1 := Adjacent[V8];
			if(Loc1>=0) and (Loc1<MapSize) and (Time[Loc1]<0)then
			begin
				ToTile := Map[Loc1];

				if(Loc1 = a.ToLoc)and(ToTile and (fUnit or fOwned)=fUnit) then
				begin // attack position found
					if PQ.Put(Loc1,T+1) then		From[Loc1]:=Loc;
				end
				else if (ToTile and fTerrain<>fUNKNOWN)and
					((Loc1=a.ToLoc) or (ToTile and (fCity or fOwned)<>fCity))and	// don't move through enemy cities
					((Loc1=a.ToLoc) or (ToTile and (fUnit or fOwned)<>fUnit))and 	// way is blocked
					(ToTile and not FromTile and fPeace=0)and
					((MoveInfo and 3<gmaGround_ZoC)or
					(ToTile and FromTile and fInEnemyZoc=0)or
					(ToTile and fOwnZoCUnit<>0))then
				begin
				// calculate move cost, must be identic to GetMoveCost function
					AddDamage := 0;
					MountainDelay := false;
					case MoveInfo of
					gmaAir:		MoveCost:=50; {always valid move}
					gmaSea:
						if	(ToTile and (fCity or fCanal)<>0)or
							(ToTile and fTerrain=fShore)then {domain ok}
								MoveCost:=50 {valid move}
						else	MoveCost:=-1;
					gmaSea+gmaNav:
						if	(ToTile and (fCity or fCanal)<>0)or
							(ToTile and fTerrain<fGrass) then {domain ok}
								MoveCost:=50 {valid move}
						else	MoveCost:=-1;
					else // ground unit
					if (ToTile and fTerrain>=fGrass) then {domain ok}
						begin {valid move}
							if (FromTile and (fRR or fCity)<>0)
							and (ToTile and (fRR or fCity)<>0) then
								MoveCost:=RailCost //move along railroad
							else if (FromTile and (fRoad or fRR or fCity)<>0)
							and (ToTile and (fRoad or fRR or fCity)<>0)
							or (FromTile and ToTile and (fRiver or fCanal)<>0)
							or (MoveInfo and gmaAlpine<>0) then
							//move along road, river or canal
								if MoveInfo and gmaOver<>0 then	MoveCost:=40
								else	MoveCost:=20
							else if MoveInfo and gmaOver<>0 then MoveCost:=-1
							else case Terrain[ToTile and fTerrain].MoveCost of
							1:		MoveCost:=50; // plain terrain
							2:		MoveCost:=HeavyCost; // heavy terrain
							3:
								begin
									MoveCost:=maxmov;
									MountainDelay:=true;
								end;
							end;

					// calculate HostileDamage
							if not resistant and (ToTile and fTerImp<>tiBase) then
								if ToTile and (fTerrain or fCity or fRiver or fCanal or fSpecial1{Oasis})=fDesert then
								begin
									if V8 and 1<>0 then
											AddDamage:=((DesertThurst*3)*MoveCost-1) div maxmov +1
									else	AddDamage:=((DesertThurst*2)*MoveCost-1) div maxmov +1
								end
								else if ToTile and (fTerrain or fCity or fRiver or fCanal)=fArctic then
								begin
									if V8 and 1<>0 then
											AddDamage:=((ArcticThurst*3)*MoveCost-1) div maxmov +1
									else	AddDamage:=((ArcticThurst*2)*MoveCost-1) div maxmov +1
								end;
						end
						else MoveCost:=-1;
					end;	//case MoveInfo of

					if (MoveCost>0) and not MountainDelay then
					if V8 and 1<>0 then	inc(MoveCost, MoveCost*2)
					else				inc(MoveCost, MoveCost);

{//!!! BUG:		Causes ground units walk on the water
					if (MoveInfo and 2<>0)	//	ground unit, check transport load/unload
						and((MoveCost<0)and(ToTile and (fUnit or fOwned)=fUnit or fOwned)  // assume ship/airplane is transport -- load!
						or(FromTile and fTerrain<fGrass)) then
						MoveCost := maxmov; //	transport load or unload
}
					if	(MoveInfo and 2<>0)  // ground unit, check transport load/unload
						and((MoveCost<0)and(ToTile and (fUnit or fOwned)=fUnit or fOwned)  // assume ship/airplane is transport -- load!
						or((FromTile and fTerrain<fGrass)and((ToTile and fTerrain>=fGrass)
						or(ToTile and (fUnit or fOwned)=fUnit or fOwned)))) then
							MoveCost := maxmov; // transport load or unload

					if MoveCost>=0 then		//	valid move
					begin
						if MoveCost+T shr 8 and $FFF > maxmov then
						begin // must wait for next turn
						// calculate HostileDamage
							if (MoveInfo and 2<>0)and 		//ground unit
							not resistant and (FromTile and fTerImp<>tiBase) then
								if FromTile and (fTerrain or fCity or fRiver or fCanal or fSpecial1{Oasis})=fDesert then
									inc(AddDamage, (DesertThurst*(maxmov-T shr 8 and $FFF)-1) div maxmov +1)
								else if FromTile and (fTerrain or fCity or fRiver or fCanal)=fArctic then
									inc(AddDamage, (ArcticThurst*(maxmov-T shr 8 and $FFF)-1) div maxmov +1);

							T1 := T and $7FF00000 +$100000+(initmov+MoveCost) shl 8;
						end
						else T1 := T + MoveCost shl 8+1;

						if MountainDelay then T1 := T1 or $FFF00;

						if Damage[Loc] + AddDamage <= MaxDamage then
							if PQ.Put(Loc1,T1) then
							begin
								From[Loc1] := Loc;
								Damage[Loc1] := Damage[Loc] + AddDamage;
							end
					end
				end
			end
		end		//for V8:=0 to 7 do
	end;	//while PQ.Get(Loc,T) do

{$IFDEF DISPLAY}
	MainForm.PaintBox1.Canvas.Pen.Mode := pmCopy;
	MainForm.PaintBox1.Canvas.Brush.Color := 255;
	MainForm.PaintBox1.Canvas.Pen.Color := 255;
{$ENDIF}

	if (Loc=a.ToLoc) or (a.ToLoc=maNextCity) and (Loc>=0)
	and (Map[Loc] and fCity<>0) then
	begin
		a.MoreTurns := T shr 20;
		EndLoc := Loc;
		a.nStep:=0;
		while Loc<>FromLoc do
		begin
{$IFDEF DISPLAY}
			MainForm.LocToClient(Loc, x, y);
			MainForm.PaintBox1.Canvas.MoveTo(x, y);
//			if Time[Loc]<$100000 then
				MainForm.PaintBox1.Canvas.Ellipse(x-2, y-2,x+2, y+2);

			MainForm.LocToClient(From[Loc], x1, y1);

			if abs(x1-x)>MainForm.MiniImg.Width shr 1 then
				MainForm.PaintBox1.Canvas.LineTo(x, y1)
			else
				MainForm.PaintBox1.Canvas.LineTo(x1, y1);

{$ENDIF}
			if Time[Loc]<$100000 then inc(a.nStep);
			Loc:=From[Loc];
		end;
		Loc := EndLoc;
		i := a.nStep;
		while Loc<>FromLoc do
		begin
			if Time[Loc]<$100000 then
			begin
				dec(i);
				if i<25 then
				begin
					a.dx[i]:=((Loc mod lx *2 +Loc div lx and 1)
						-(From[Loc] mod lx *2 +From[Loc] div lx and 1)+3*lx) mod (2*lx) -lx;
					a.dy[i]:=Loc div lx-From[Loc] div lx;
				end
			end;
			Loc:=From[Loc];
		end;
		a.MaxHostile_MovementLeft:=maxmov-Time[EndLoc] shr 8 and $FFF;
		if a.nStep>25 then a.nStep:=25;
		result := eOK
	end
	else result:=eNoWay;

//  QueryPerformanceCounter(tt);{time in s is: (tt-tt0)/PerfFreq}

{$IFDEF DISPLAY}
	Bitmap.Free;
	OffScreen.Free;
{$ENDIF}
end; // GetMoveAdvice

{ $UNDEF DISPLAY}
{ $DEFINE DISPLAY}

function GetMoveAdviceA(uix: integer; var a: TMoveAdviceData): integer;
const
	//domains
	gmaAir=0; gmaSea=1; gmaGround_NoZoC=2; gmaGround_ZoC=3;
	//flags
	gmaNav=4; gmaOver=4; gmaAlpine=8;
var
{$IFDEF DISPLAY}
	k:								Double;
	Rect:							TRect;
	Bitmap, OffScreen:				TBitmap;
	n, j, l, x, y, r, Color:		integer;
{$ENDIF}
	xDest, yDest,
	h, h1, OldT1, lx2,
	x1, y1, dx, dy,
	i, FromLoc, EndLoc, T, T1, maxmov,
	initmov, Loc, Loc1, FromTile,
	ToTile, V8, MoveInfo, HeavyCost,
	RailCost, MoveCost, AddDamage, MaxDamage:	integer;
	Map:										^TTileList;
	Adjacent:									TVicinity8Loc;
	From:										array[0..lxmax*lymax-1] of integer;
	Time:										array[0..lxmax*lymax-1] of integer;
	Damage:										array[0..lxmax*lymax-1] of integer;
	MountainDelay, Resistant:					boolean;
//==================================================================
	function heuristic(Loc: Integer):integer;
	var
		x, y, dx, dy, a, b:		integer;
	begin
		x := XYab[Loc].X;	y := XYab[Loc].Y;
		dx := xDest - x + lx;
		while dx < 0 do		inc(dx, lx2);
		while dx > lx2 do	dec(dx, lx2);

		dx := dx-lx;		dy := yDest - y;
		a := abs(dx+dy);	b := abs(dy-dx);
		dx := abs(dx);		dy := abs(dy);

//		result := (dx + dy) shl 10;
		result := (2*(dx + dy) + abs(dx-dy) ) shl 6;

//		result := (a + b) shl 9;
//		if a>b then			result := (a + b shr 1)shl 10
//		else				result := (b + a shr 1)shl 10;
	end;
//==================================================================
begin
//  QueryPerformanceCounter(tt0);
{$IFDEF DISPLAY}
	Bitmap := TBitmap.Create;
	Bitmap.Height := MainForm.MiniImg.Picture.Bitmap.Height;
	Bitmap.Width := MainForm.MiniImg.Picture.Bitmap.Width;
	Bitmap.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;

	OffScreen := TBitmap.Create;
	OffScreen.PixelFormat := MainForm.MiniImg.Picture.Bitmap.PixelFormat;
	r := Round(Min(MainForm.MiniImg.Height/MainForm.MiniImg.Picture.Graphic.Height,
						MainForm.MiniImg.Width/MainForm.MiniImg.Picture.Graphic.Width));
	if r < 2 then r := 2;
{$ENDIF}

	MaxDamage := RO.Un[uix].Health-1;
	if MaxDamage > a.MaxHostile_MovementLeft then
		if a.MaxHostile_MovementLeft>=0 then
			MaxDamage := a.MaxHostile_MovementLeft
		else
			MaxDamage := 0;

	Map:=@RO.Map^;
	if (a.ToLoc<0) or (a.ToLoc>=MapSize) then
	begin result:=eInvalid; exit end;

	if (Map[a.ToLoc] and fTerrain=fUNKNOWN) then
	begin result:=eNoWay; exit end;

	with RO.Model[RO.Un[uix].mix] do
	case Domain of
	dGround:
		if (Map[a.ToLoc] and fTerrain=fOcean) then
		begin result:=eDomainMismatch; exit end
		else
		begin
			if Flags and mdZOC<>0 then MoveInfo:=gmaGround_ZoC
			else MoveInfo:=gmaGround_NoZoC;
			if Cap[mcOver]>0 then inc(MoveInfo,gmaOver);
			if Cap[mcAlpine]>0 then inc(MoveInfo,gmaAlpine);
			HeavyCost := 50 + (Speed-150)*13 shr 7;
			if RO.Wonder[woShinkansen].EffectiveOwner=AIMe then RailCost:=0
			else RailCost := Speed*(4*1311) shr 17;
			maxmov := Speed;
			initmov := 0;
			Resistant := RO.Wonder[woGardens].EffectiveOwner=AIMe;
		end;
	dSea:
		if (Map[a.ToLoc] and fTerrain>=fGrass)
		and (Map[a.ToLoc] and (fCity or fUnit or fCanal)=0) then
		begin result:=eDomainMismatch; exit end
		else
		begin
			MoveInfo:=gmaSea;
			if Cap[mcNav]>0 then inc(MoveInfo,gmaNav);
//			maxmov:=UnitSpeed(Player,RW[Player].Un[uix].mix,100);
//			initmov:=maxmov-UnitSpeed(Player,RW[Player].Un[uix].mix, RW[Player].Un[uix].Health);
			maxmov := Speed;
			if RO.Wonder[woMagellan].EffectiveOwner = AIme then
				inc(maxmov, 200);
			initmov := maxmov - UnitSpeed(uix);
		end;
	dAir:
		begin
			MoveInfo:=gmaAir;
			maxmov:=Speed;
			initmov:=0;
		end
	end;

	FromLoc:=RO.Un[uix].Loc;
	FillChar(Time, SizeOf(Time),255); {-1}
	Damage[FromLoc]:=0;

	lx2 := 2*lx;
	xDest := XYab[a.ToLoc].X;	yDest := XYab[a.ToLoc].Y;

	x1 := XYab[FromLoc].X;		y1 := XYab[FromLoc].Y;
	dx := xDest - x1 + lx;
	while dx < 0 do		inc(dx, lx2);
	while dx > lx2 do	dec(dx, lx2);
	dx := abs(dx-lx);		dy := abs(yDest - y1);

//	h1 := (dx + dy) shl 10;
	h1 := (2*(dx + dy) + abs(dx-dy)) shl 9;
//	h1 := heuristic(FromLoc);

	OpenList.Empty;
	OpenList.Put(FromLoc, (maxmov-RO.Un[uix].Movement) shl 8, h1);

	while OpenList.Get(Loc, T, h) do
	begin
{$IFDEF DISPLAY}
		if MainForm.bBreak then exit;
		PaintMiniMap(Bitmap, False);
		OffScreen.Height := MainForm.PaintBox1.Height;
		OffScreen.Width := MainForm.PaintBox1.Width;

		Rect := MainForm.PaintBox1.BoundsRect;
		OffsetRect(Rect, -MainForm.PaintBox1.Left, -MainForm.PaintBox1.Top);

		OffScreen.Canvas.StretchDraw(OffScreen.Canvas.ClipRect, Bitmap);
		PaintFeatures(OffScreen.Canvas, r, MainForm.MiniImg.Width,
				MainForm.RoadsChBox.Checked, MainForm.TownsChBox.Checked,
				MainForm.UnitsChBox.Checked);

		OffScreen.Canvas.Pen.Width := 1;
		OffScreen.Canvas.CopyMode := cmSrcCopy;

		n := OpenList.nItem;
		if n>0 then		k := 255 / n
		else			k := 0;

		MainForm.Label1.Caption := 'N = '+IntToStr(n);
		if n>0 then
		begin
			for j := 0 to n-1 do
			begin
				Color := Round(k*(j+1));
				OffScreen.Canvas.Brush.Color := RGB(Color, 255-Color, 255-Color);
				OffScreen.Canvas.Pen.Color := 0;//RGB(Color, 255-Color, 255-Color);
				l := OpenList.Item[j];
				MainForm.LocToClient(l, x, y);
				OffScreen.Canvas.Ellipse(x-2, y-2,x+2, y+2);
			end;
		end;

		MainForm.PaintBox1.Canvas.CopyRect(Rect, OffScreen.Canvas, OffScreen.Canvas.ClipRect);
		Application.ProcessMessages;
{$ENDIF}
//==================================================================
		Time[Loc] := T;

		if T >= (a.MoreTurns+1) shl 20 then
		begin Loc:=-1; Break end;

		FromTile := Map[Loc];
		if(Loc = a.ToLoc)then
			Break;

		if T and $FFF00 = $FFF00 then inc(T, $100000); // indicates mountain delay

		V8_to_Loc(Loc, Adjacent);
		for V8 := 0 to 7 do
		begin
			Loc1 := Adjacent[V8];

			if(Loc1>=0) and (Loc1<MapSize) then
			begin
				ToTile := Map[Loc1];

				if(Loc1 = a.ToLoc)and(ToTile and (fUnit or fOwned)=fUnit) then
				begin // attack position found
					OldT1 := OpenList.Value[Loc1];
					if(OldT1 >= 0)and(OldT1 <= T+1)then
						continue;

					if(Time[Loc1]>=0)and(Time[Loc1]<=T+1)then
						continue;
					Time[Loc1] := -1;

					OpenList.Put(Loc1, T+1, h+1);
					From[Loc1] := Loc;
				end
				else if (ToTile and fTerrain<>fUNKNOWN)and
					((Loc1=a.ToLoc) or (ToTile and (fCity or fOwned)<>fCity))and	// don't move through enemy cities
					((Loc1=a.ToLoc) or (ToTile and (fUnit or fOwned)<>fUnit))and 	// way is blocked
					(ToTile and not FromTile and fPeace=0)and
					((MoveInfo and 3<gmaGround_ZoC)or
					(ToTile and FromTile and fInEnemyZoc=0)or
					(ToTile and fOwnZoCUnit<>0))then
				begin
				// calculate move cost, must be identic to GetMoveCost function
					AddDamage := 0;
					MountainDelay := false;
					case MoveInfo of
					gmaAir:		MoveCost:=50; {always valid move}
					gmaSea:
						if	(ToTile and (fCity or fCanal)<>0)or
							(ToTile and fTerrain=fShore)then {domain ok}
								MoveCost:=50 {valid move}
						else	MoveCost:=-1;
					gmaSea+gmaNav:
						if	(ToTile and (fCity or fCanal)<>0)or
							(ToTile and fTerrain<fGrass) then {domain ok}
								MoveCost:=50 {valid move}
						else	MoveCost:=-1;
					else // ground unit
					if (ToTile and fTerrain>=fGrass) then {domain ok}
						begin {valid move}
							if (FromTile and (fRR or fCity)<>0)
							and (ToTile and (fRR or fCity)<>0) then
								MoveCost:=RailCost //move along railroad
							else if (FromTile and (fRoad or fRR or fCity)<>0)
							and (ToTile and (fRoad or fRR or fCity)<>0)
							or (FromTile and ToTile and (fRiver or fCanal)<>0)
							or (MoveInfo and gmaAlpine<>0) then
							//move along road, river or canal
								if MoveInfo and gmaOver<>0 then	MoveCost:=40
								else	MoveCost:=20
							else if MoveInfo and gmaOver<>0 then MoveCost:=-1
							else case Terrain[ToTile and fTerrain].MoveCost of
							1:		MoveCost:=50; // plain terrain
							2:		MoveCost:=HeavyCost; // heavy terrain
							3:
								begin
									MoveCost:=maxmov;
									MountainDelay:=true;
								end;
							end;

					// calculate HostileDamage
							if not resistant and (ToTile and fTerImp<>tiBase) then
								if ToTile and (fTerrain or fCity or fRiver or fCanal or fSpecial1{Oasis})=fDesert then
								begin
									if V8 and 1<>0 then
											AddDamage:=((DesertThurst*3)*MoveCost-1) div maxmov +1
									else	AddDamage:=((DesertThurst*2)*MoveCost-1) div maxmov +1
								end
								else if ToTile and (fTerrain or fCity or fRiver or fCanal)=fArctic then
								begin
									if V8 and 1<>0 then
											AddDamage:=((ArcticThurst*3)*MoveCost-1) div maxmov +1
									else	AddDamage:=((ArcticThurst*2)*MoveCost-1) div maxmov +1
								end;
						end
						else MoveCost:=-1;
					end;	//case MoveInfo of

					if (MoveCost>0) and not MountainDelay then
					if V8 and 1<>0 then	inc(MoveCost, MoveCost*2)
					else				inc(MoveCost, MoveCost);

{!!! BUG:		Causes ground units walk on the water
					if (MoveInfo and 2<>0)	//	ground unit, check transport load/unload
						and((MoveCost<0)and(ToTile and (fUnit or fOwned)=fUnit or fOwned)  // assume ship/airplane is transport -- load!
						or(FromTile and fTerrain<fGrass)) then
						MoveCost := maxmov; //	transport load or unload
}
					if	(MoveInfo and 2<>0)  // ground unit, check transport load/unload
						and((MoveCost<0)and(ToTile and (fUnit or fOwned)=fUnit or fOwned)  // assume ship/airplane is transport -- load!
						or((FromTile and fTerrain<fGrass)and((ToTile and fTerrain>=fGrass)
						or(ToTile and (fUnit or fOwned)=fUnit or fOwned)))) then
							MoveCost := maxmov; // transport load or unload

					if MoveCost>=0 then		//	valid move
					begin
						if MoveCost+T shr 8 and $FFF > maxmov then
						begin // must wait for next turn
						// calculate HostileDamage
							if (MoveInfo and 2<>0)and 		//ground unit
							not resistant and (FromTile and fTerImp<>tiBase) then
								if FromTile and (fTerrain or fCity or fRiver or fCanal or fSpecial1{Oasis})=fDesert then
									inc(AddDamage, (DesertThurst*(maxmov-T shr 8 and $FFF)-1) div maxmov +1)
								else if FromTile and (fTerrain or fCity or fRiver or fCanal)=fArctic then
									inc(AddDamage, (ArcticThurst*(maxmov-T shr 8 and $FFF)-1) div maxmov +1);

							T1 := T and $7FF00000 +$100000+(initmov+MoveCost) shl 8;
						end
						else T1 := T + MoveCost shl 8+1;

						if MountainDelay then T1 := T1 or $FFF00;

						if Damage[Loc] + AddDamage <= MaxDamage then
						begin
							OldT1 := OpenList.Value[Loc1];
							if(OldT1 >= 0)and(OldT1 <= T1)then
								continue;

							if(Time[Loc1]>=0)and(Time[Loc1]<=T1)then
								continue;
							Time[Loc1] := -1;

							x1 := XYab[Loc1].X;		y1 := XYab[Loc1].Y;
							dx := xDest - x1 + lx;
							while dx < 0 do		inc(dx, lx2);
							while dx > lx2 do	dec(dx, lx2);
							dx := abs(dx-lx);	dy := abs(yDest - y1);

//							h1 := (dx + dy) shl 10;
							h1 := (2*(dx + dy) + abs(dx-dy)) shl 9;
//							h1 := heuristic(Loc1);

							if OpenList.Put(Loc1, T1, h1) then
							begin
								From[Loc1] := Loc;
								Damage[Loc1] := Damage[Loc] + AddDamage;
							end
						end;
					end
				end
			end
		end;	//for V8:=0 to 7 do
	end;	//while OpenList.Get(Loc,T) do

{$IFDEF DISPLAY}
	MainForm.PaintBox1.Canvas.Pen.Mode := pmCopy;
	MainForm.PaintBox1.Canvas.Brush.Color := 255;
	MainForm.PaintBox1.Canvas.Pen.Color := 255;
{$ENDIF}

	if (Loc=a.ToLoc) then
	begin
		a.MoreTurns := T shr 20;
		EndLoc:=Loc;
		a.nStep:=0;
		while Loc<>FromLoc do
		begin
{$IFDEF DISPLAY}
			MainForm.LocToClient(Loc, x, y);
			MainForm.PaintBox1.Canvas.MoveTo(x, y);
//			if Time[Loc]<$100000 then
				MainForm.PaintBox1.Canvas.Ellipse(x-2, y-2,x+2, y+2);

			MainForm.LocToClient(From[Loc], x1, y1);
			if abs(x1-x)>MainForm.MiniImg.Width shr 1 then
				MainForm.PaintBox1.Canvas.LineTo(x, y1)
			else
				MainForm.PaintBox1.Canvas.LineTo(x1, y1);
{$ENDIF}
			if Time[Loc]<$100000 then inc(a.nStep);
			Loc:=From[Loc];
		end;
		Loc := EndLoc;
		i := a.nStep;
		while Loc<>FromLoc do
		begin
			if Time[Loc]<$100000 then
			begin
				dec(i);
				if i<25 then
				begin
					a.dx[i]:=((Loc mod lx *2 +Loc div lx and 1)
						-(From[Loc] mod lx *2 +From[Loc] div lx and 1)+3*lx) mod (2*lx) -lx;
					a.dy[i]:=Loc div lx-From[Loc] div lx;
				end
			end;
			Loc:=From[Loc];
		end;
		a.MaxHostile_MovementLeft:=maxmov-Time[EndLoc] shr 8 and $FFF;
		if a.nStep>25 then a.nStep:=25;
		result:=eOK
	end
	else result:=eNoWay;

//  QueryPerformanceCounter(tt);{time in s is: (tt-tt0)/PerfFreq}

{$IFDEF DISPLAY}
	Bitmap.Free;
	OffScreen.Free;
{$ENDIF}
end; // GetMoveAdviceA

end.
