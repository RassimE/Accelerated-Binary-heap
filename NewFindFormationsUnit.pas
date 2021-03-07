//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//	Sorting bug fixed.

{$INCLUDE switches}
unit NewFindFormationsUnit;

interface

procedure FindFormations_New;

var
	nContinent, nOcean, nDistrict:		integer;
implementation

uses
	Protocol, CommonUnit;

procedure FindFormations_New;
const
	tConvert: Array [0..31] of integer =
	(0,0,1,1,1,1,1,1,-1,1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1);
var
	x, y, x0, y0,
	ll, lx2,
	c, IDx,
	Loc, Wrong:			integer;
	pI:					^integer;
	Adjacent:			TVicinity8Loc;
	IndexOfID:			array[-1..(lxmax*lymax) shr 2] of	integer;
	IDOfIndex, Cnt:		array[0..(lxmax*lymax) shr 2] of	integer;
//===============================================================
// replace Continent name a by b
	procedure ReplaceCont(a, b: integer);
	var
		i:	integer;
	begin
		if a < b then
		begin
			i := a;	a := b;	b := i
		end;

		if a > b then
		begin
			for i := a to IDx-1 do
				if IndexOfID[i] = a then
					IndexOfID[i] := b
		end
	end;
//===============================================================
	procedure ReplaceCont1(a, b: integer);
	var
		i:	integer;
	begin
		if a < b then
		begin
			i := a;	a := b;	b := i
		end;

		if a > b then
			for i := 1 to b do
				if IndexOfID[i] = b then
					IndexOfID[i] := a;
	end;
//===============================================================

	procedure CheckAdjacent(Loc1, Loc2: integer);
	var
		f1, f2:	integer;
	begin
		if (Loc1 >= 0) and (Loc1 < MapSize) and (Loc2 >= 0) and (Loc2 < MapSize) then
		begin
			f1 := iFormation[Loc1];
			f2 := iFormation[Loc2];
			if f1 <> f2 then
			begin
				if f2 < 0 then	FormationInfo[f1].FullyDiscovered := False
				else if f2 < 32 then
								FormationInfo[f1].Adjacent := FormationInfo[f1].Adjacent or (1 shl f2);

				if f1 < 0 then	FormationInfo[f2].FullyDiscovered := False
				else if f1 < 32 then
								FormationInfo[f2].Adjacent := FormationInfo[f2].Adjacent or (1 shl f1);
			end
		end
	end;
//===============================================================

begin
	FillChar(iFormation, MapSize*SizeOf(integer), 255);
	for x := -1 to 1 do
		IndexOfID[x] := x;
	ll := 0;	lx2 := lx+lx;
	IDx := 1;

	for y := 1 to ly - 2 do
	begin
		inc(ll, lx);
		y0 := y and 1;
		for x := 0 to lx-1 do
		begin
			Loc := ll + x;
			c :=  tConvert[MyMap[Loc] and fTerrain];
			if c >= 0 then
			begin
				if y >= 2 then
				begin
					if (y >= 3) and (tConvert[MyMap[Loc-lx2] and fTerrain] = c) then
						iFormation[Loc] := iFormation[Loc-lx2];				//	^

					if (x + y0 - 1 >= 0)and(tConvert[MyMap[Loc-lx + y0 - 1] and fTerrain] = c) then
						iFormation[Loc] := iFormation[Loc-lx + y0 - 1];		//	^-

					if (x + y0 < lx)and(tConvert[MyMap[Loc-lx + y0] and fTerrain] = c) then
						iFormation[Loc] := iFormation[Loc-lx + y0];			//	-^
				end;

				if (x >= 1) and (tConvert[MyMap[Loc-1] and fTerrain] = c) then
				begin
					if iFormation[Loc] = -1 then
						iFormation[Loc] := iFormation[Loc-1]				//	<-
					else if IndexOfID[iFormation[Loc]] <> IndexOfID[iFormation[Loc-1]] then
						ReplaceCont(IndexOfID[iFormation[Loc]], IndexOfID[iFormation[Loc-1]]);
				end;

				if iFormation[Loc]=-1 then
				begin
					iFormation[Loc] := IDx;
					Inc(IDx);
					IndexOfID[IDx] := IDx;
					IDOfIndex[IDx] := IDx;
				end;
			end;
		end;
	end;

//connect Formations due to round earth

	ll := 0;
	for y := 1 to ly - 2 do
	begin
		Inc(ll, lx);
		Wrong := -1;
		c :=  tConvert[MyMap[ll] and fTerrain];

		if c >= 0 then
		begin
			if tConvert[MyMap[ll+lx - 1] and fTerrain] = c then
				Wrong := ll+lx - 1;

			if y and 1 = 0 then
			begin
				if (y >= 2) and (tConvert[MyMap[ll - 1] and fTerrain] = c) then
					Wrong := ll - 1;
				if (y < ly-2) and (tConvert[MyMap[ll+lx2 - 1] and fTerrain] = c) then
					Wrong := ll+lx2 - 1;
			end
		end;

		if (Wrong >= 0)and(IndexOfID[iFormation[ll]]<>IndexOfID[iFormation[Wrong]]) then
			ReplaceCont(IndexOfID[iFormation[ll]], IndexOfID[iFormation[Wrong]]);
	end;

// poles
	ll := lx*(ly-1);
	for x := 0 to lx - 1 do
	begin
		if MyMap[x] and fTerrain <> fUNKNOWN then				iFormation[x] := 0
		else													iFormation[x] := -1;

		if MyMap[ll + x] and fTerrain <> fUNKNOWN then			iFormation[ll + x] := IDx
		else													iFormation[ll + x] := -1;
	end;

// sort formations by size
//===============================================================
	x := IDx shl 1;		y := MapSize shr 2;
	if x<y then		FillChar(Cnt, x*SizeOf(integer), 0)
	else			FillChar(Cnt, y*SizeOf(integer), 0);

	for Loc := 0 to MapSize-1 do
	begin
		if IndexOfID[iFormation[Loc]] >= 0 then
		begin
			inc(Cnt[IndexOfID[iFormation[Loc]]]);
			iFormation[Loc] := IndexOfID[iFormation[Loc]];
		end;
	end;

	nFormation := 0;
	IDOfIndex[0] := 0;
	IDOfIndex[1] := 1;

	repeat
		y := nFormation;
		pI := @Cnt[y];
		c := pI^;
		for x := nFormation+1 to IDx do
		begin
			Inc(pI);
			if pI^ > c then
			begin
				c := pI^;
				y := x;
			end;
		end;

		if c = 0 then
			break;

		Cnt[y] := Cnt[nFormation];
		Cnt[nFormation] := c;

		x := IDOfIndex[nFormation];
		IDOfIndex[nFormation] := IDOfIndex[y];
		IDOfIndex[y] := x;

		Inc(nFormation);
	until False;
//===============================================================

// generate Formation numbers

	for x := 0 to nFormation-1 do
		IndexOfID[IDOfIndex[x]] := x;

	for Loc := 0 to MapSize-1 do
		if iFormation[Loc] >= 0 then
		begin
			x := IndexOfID[iFormation[Loc]];
			FormationInfo[x].IDLoc := Loc;
			iFormation[Loc] := x;
		end;

// generate Formation info
	with FormationInfo[-1] do
	begin // not discovered
		Kind := Hidden;
		IDLoc := -1;
		Size := -1;
		for x := 0 to nPl-1 do	Presence[x] := -1;
		Adjacent := 0;
		FullyDiscovered := False;
	end;


	for y := 0 to nFormation-1 do with FormationInfo[y] do
	begin
		if MyMap[IDLoc] and fTerrain = fArctic then			Kind := Pole
		else if MyMap[IDLoc] and fTerrain < fGrass then		Kind := Water
		else												Kind := Land;

		IDLoc := -1;
		Size := Cnt[y];
		for x := 0 to nPl-1 do	Presence[x] := -1;
		Adjacent := 0;
		FullyDiscovered := True;
	end;

	ll := 0;
	for y := 0 to ly - 1 do
	begin
//		y0 := y and 1;	//		y0 := (1+y and 1)shr 1;
		y0 := y shr 1;
		for x := 0 to lx-1 do
		begin
			Loc := ll + x;
			CheckAdjacent(Loc, Loc-lx2);		//	^

			x0 := x + y0 - 1;	if x0 < 0 then		x0 := lx-1;
			CheckAdjacent(Loc, ll-lx + x0);		//	\

			x0 := x + y0;		if x0 >= lx then	x0 := 0;
			CheckAdjacent(Loc, ll-lx + x0);		//	/

			x0 := x-1;			if x0 < 0 then		x0 := lx-1;
			CheckAdjacent(Loc, ll + x0);		//	<

			if Territory[Loc] >= 0 then				// enemy territory spotted
				FormationInfo[iFormation[Loc]].Presence[Territory[Loc]] := 0;
		end;
		inc(ll, lx);
	end;
end;

end.
