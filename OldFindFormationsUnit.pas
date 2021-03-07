//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

{$INCLUDE switches}
unit OldFindFormationsUnit;

interface

procedure FindFormations_Old;

implementation

uses
	Protocol, CommonUnit;

procedure FindFormations_Old;
//===============================================================
// replace Formation name a by b
	procedure ReplaceCont(a, b, Stop: integer);
	var
		i:	integer;
	begin
		if a < b then
		begin
			i := a;	a := b;	b := i
		end;

		if a > b then
			for i := a to Stop do
				if iFormation[i] = a then
					iFormation[i] := b
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

var
	x, y, y0,
	Loc, Wrong:		integer;
	Cnt, IDOfIndex,
	IndexOfID:		array[0..lxmax*lymax-1] of integer;
begin
	FillChar(iFormation, MapSize*SizeOf(integer), 255);

	for y := 1 to ly - 2 do
		for x := 0 to lx - 1 do
		begin
			Loc := x + lx*y;
//			iContinent[Loc] := -1;
			if (MyMap[Loc]+1) and fTerrain >= fGrass+1 then
			begin // connect continents
				if (y-2 >= 1) and ((MyMap[Loc-2*lx]+1) and fTerrain>=fGrass+1) then
					iFormation[Loc] := iFormation[Loc-2*lx];
				if (x-1+y and 1 >= 0) and (y-1 >= 1) and ((MyMap[Loc-1+y and 1-lx]+1) and fTerrain >= fGrass+1) then
					iFormation[Loc] := iFormation[Loc-1+y and 1-lx];
				if (x+y and 1 < lx) and (y-1 >= 1) and ((MyMap[Loc+y and 1-lx]+1) and fTerrain >= fGrass+1) then
					iFormation[Loc] := iFormation[Loc+y and 1-lx];
				if (x-1 >= 0) and ((MyMap[Loc-1]+1) and fTerrain >= fGrass+1) then
					if iFormation[Loc] = -1 then	iFormation[Loc] := iFormation[Loc-1]
					else							ReplaceCont(iFormation[Loc], iFormation[Loc-1], Loc);
				if iFormation[Loc]=-1 then			iFormation[Loc] := Loc
			end
			else if MyMap[Loc] and fTerrain<fGrass then
			begin // connect oceans
				if (y-2 >= 1) and (MyMap[Loc-2*lx] and fTerrain<fGrass) then
					iFormation[Loc] := iFormation[Loc-2*lx];
				if (x-1+y and 1 >= 0) and (y-1 >= 1) and (MyMap[Loc-1+y and 1-lx] and fTerrain < fGrass) then
					iFormation[Loc] := iFormation[Loc-1+y and 1-lx];
				if (x+y and 1 < lx) and (y-1 >= 1) and (MyMap[Loc+y and 1-lx] and fTerrain < fGrass) then
					iFormation[Loc] := iFormation[Loc+y and 1-lx];
				if (x-1>=0) and (MyMap[Loc-1] and fTerrain < fGrass) then
					if iFormation[Loc] = -1 then	iFormation[Loc] := iFormation[Loc-1]
					else							ReplaceCont(iFormation[Loc-1], iFormation[Loc], Loc);
				if iFormation[Loc] = -1 then		iFormation[Loc] := Loc
			end
		end;

{connect Continents due to round earth}
	for y := 1 to ly - 2 do
	begin
		Wrong := -1;
		if (MyMap[lx*y]+1) and fTerrain >= fGrass+1 then
		begin
			if (MyMap[lx - 1 + lx*y] + 1) and fTerrain >= fGrass+1 then
				Wrong := iFormation[lx - 1 + lx*y];
			if (y and 1 = 0) and (y-1 >= 1) and ((MyMap[lx - 1 + lx*(y-1)]+1) and fTerrain >= fGrass+1) then
				Wrong := iFormation[lx-1+lx*(y-1)];
			if (y and 1 = 0) and (y+1 < ly-1) and ((MyMap[lx-1+lx*(y+1)]+1) and fTerrain >= fGrass+1) then
				Wrong := iFormation[lx-1+lx*(y+1)];
		end
		else if MyMap[lx*y] and fTerrain<fGrass then
		begin
			if MyMap[lx-1+lx*y] and fTerrain<fGrass then
				Wrong := iFormation[lx - 1 + lx*y];
			if (y and 1 = 0) and (y-1 >= 1) and (MyMap[lx -1 + lx*(y-1)] and fTerrain < fGrass) then
				Wrong := iFormation[lx-1+lx*(y-1)];
			if (y and 1 = 0) and (y+1 < ly-1) and (MyMap[lx - 1 + lx*(y+1)] and fTerrain < fGrass) then
				Wrong := iFormation[lx-1+lx*(y+1)];
		end;
		if Wrong >= 0 then
			ReplaceCont(Wrong, iFormation[lx*y], MapSize-1)
	end;

// poles
	for x := 0 to lx - 1 do
	begin
		if MyMap[x] and fTerrain <> fUNKNOWN then				iFormation[x] := 0
		else													iFormation[x] := -1;

		if MyMap[x+lx*(ly-1)] and fTerrain <> fUNKNOWN then		iFormation[x+lx*(ly-1)] := lx*(ly-1)
		else													iFormation[x+lx*(ly-1)] := -1;
	end;

// sort continents by size
	FillChar(Cnt, SizeOf(Cnt), 0);
	for Loc := 0 to MapSize-1 do
	begin
		if iFormation[Loc] >= 0 then
			inc(Cnt[iFormation[Loc]]);
		IDOfIndex[Loc] := Loc
	end;

	nFormation := 0;
	repeat
		y := nFormation+1;
		for x := nFormation+2 to MapSize-1 do
			if Cnt[x] > Cnt[y] then y := x;
		if Cnt[y] = 0 then	Break;
		
		x := Cnt[nFormation];
		Cnt[nFormation] := Cnt[y];
		Cnt[y] := x;

		x := IDOfIndex[nFormation];
		IDOfIndex[nFormation] := IDOfIndex[y];
		IDOfIndex[y] := x;

		inc(nFormation);
	until False;

// generate Formation numbers
	for Loc := 0 to nFormation-1 do
		IndexOfID[IDOfIndex[Loc]] := Loc;
	for Loc := 0 to MapSize-1 do
		if iFormation[Loc] >= 0 then
			iFormation[Loc] := IndexOfID[iFormation[Loc]];

// generate Formation info
	with FormationInfo[-1] do
	begin // not discovered
		Kind := Hidden;
		Size := 0;
		for x := 0 to nPl-1 do
			Presence[x] := -1;
		Adjacent := 0;
		FullyDiscovered := False;
	end;

	for Loc := 0 to nFormation-1 do with FormationInfo[Loc] do
	begin
		if(IDOfIndex[Loc]=0) or (IDOfIndex[Loc]=lx*(ly-1)) then			Kind := Pole
		else if MyMap[IDOfIndex[Loc]] and fTerrain < fGrass then		Kind := Water
		else															Kind := Land;
		IDLoc := -1;
		Size := Cnt[Loc];
		for x := 0 to nPl-1 do
			Presence[x] := -1;
		Adjacent := 0;
		FullyDiscovered := True;
	end;

	for Loc := 0 to MapSize-1 do
	begin
		y0 := Loc div lx;
		CheckAdjacent(Loc,Loc-2*lx);
		CheckAdjacent(Loc,(Loc+(-1+y0 and 1+lx*2) div 2) mod lx +lx*(y0-1));
		CheckAdjacent(Loc,(Loc+(1+y0 and 1) div 2) mod lx +lx*(y0-1));
		CheckAdjacent(Loc,(Loc-1+lx) mod lx +lx*y0);

		if Territory[Loc] >= 0 then // enemy territory spotted
			FormationInfo[iFormation[Loc]].Presence[Territory[Loc]] := 0;
	end;
end;

end.
