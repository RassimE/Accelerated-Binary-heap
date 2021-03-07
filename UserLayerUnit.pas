//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//	Implementation of 'User defined layer'

{$INCLUDE switches}
unit UserLayerUnit;

interface

uses
	Graphics, CommonUnit;

type
	TLayerUpdate = set of (luTerrain, luRoad, luUnit, luCity);

	TUserLayer = Class
	protected
		FXSize, FYSize:		integer;
		FMinValue,
		FMaxValue:			integer;
		FNO_DATA_Value:		integer;
		FLayerUpdate:		TLayerUpdate;
		FLevelsNum:			integer;
		FMasked_NO_DATA:	Boolean;
		FLayerName,
		FFieldName,
		FUnitsName:			string;
		FRGBArray:			PRGBArray;
		FDataArray:			PIntegerArray;

		function GetValue(Loc: integer): integer;
		procedure SetValue(Loc, Val: integer);

		procedure SetLevelsNum(Val: integer);
		function GetLevelColor(I: integer): TColor;
		procedure SetLevelColor(I:integer; Val: TColor);
	public
		constructor Create(Layer, Field, Units: string);
		destructor Destroy; override;

		procedure InitLayerData;			virtual;
		procedure Paint(Bitmap: TBitmap);	virtual;
		property Update: TLayerUpdate read FLayerUpdate;
		property Value[Loc: Integer]: integer read GetValue write SetValue;
		property MinValue: integer read FMinValue;
		property MaxValue: integer read FMaxValue;
		property NodataValue: integer read FNO_DATA_Value;
		property Masked_NO_DATA: Boolean read FMasked_NO_DATA write FMasked_NO_DATA;
		property LayerName: string read FLayerName write FLayerName;
		property FieldName: string read FFieldName write FFieldName;
		property UnitsName: string read FUnitsName write FUnitsName;
		property LevelsNum: integer read FLevelsNum write SetLevelsNum;
		property LevelColor[I: integer]: TColor read GetLevelColor write SetLevelColor;
	end;

implementation

uses
	Dialogs;

constructor TUserLayer.Create(Layer, Field, Units: string);
begin
	inherited Create;
	FLevelsNum := 0;
	FXSize := 0;
	FYSize := 0;
	FMinValue := 0;
	FMaxValue := 0;
	FNO_DATA_Value := -1;
	FMasked_NO_DATA := True;
	FLayerUpdate := [];

	FRGBArray := nil;
	FDataArray := nil;
	FLayerName := Layer;
	FFieldName := Field;
	FUnitsName := Units;
end;

destructor TUserLayer.Destroy;
begin
	FreeMem(FRGBArray);
	FreeMem(FDataArray);
	inherited Destroy;
end;

function TUserLayer.GetValue(Loc: integer): integer;
begin
	if(FDataArray <> nil)and(Loc >= 0)and(Loc < MapSize)then
		result := FDataArray^[Loc]
	else
		result := FNO_DATA_Value
end;

procedure TUserLayer.SetValue(Loc, Val: integer);
begin
	if(FDataArray <> nil)and(Loc >= 0)and(Loc < MapSize)then
		FDataArray^[Loc] := Val
	else
		MessageDlg('Index out of bounds', mtError, [mbOk], 0);
end;

procedure TUserLayer.SetLevelsNum(Val: integer);
var
	i, OldVal:		integer;
begin
	OldVal := FLevelsNum;
	if Val <> OldVal then
	begin
		FLevelsNum := Val;
		ReAllocMem(FRGBArray, (FLevelsNum+1)*SizeOf(TRGB));

		for i := OldVal to FLevelsNum do
		begin
			FRGBArray^[i].R := Random(255);
			FRGBArray^[i].G := Random(255);
			FRGBArray^[i].B := Random(255);
		end;
	end;
end;

function TUserLayer.GetLevelColor(I: integer): TColor;
begin
	if(I<0)or(I>FLevelsNum)then
		if FLevelsNum > 0 then	result := RGBToColor(FRGBArray^[FLevelsNum])
		else					result := 0
	else						result := RGBToColor(FRGBArray^[I])
end;

procedure TUserLayer.SetLevelColor(I: integer; Val: TColor);
begin
	if(I>=0)and(I<=FLevelsNum)then
		FRGBArray^[I] := ColorToRGB(Val);
end;

procedure TUserLayer.InitLayerData;
var
	i, Loc, Dist,
	dx, dy, Value:	integer;
begin
	FXSize := lx;
	FYSize := ly;
	ReAllocMem(FDataArray, lx*ly*SizeOf(integer));
	FMinValue := 100000000;
	FMaxValue := -100000000;

	if FLevelsNum=0 then
	begin
		FLevelsNum := 10;
		ReAllocMem(FRGBArray, (FLevelsNum+1)*SizeOf(TRGB));
		for i := 0 to 9 do
		begin
			FRGBArray^[i].R := Random(255);
			FRGBArray^[i].G := Random(255);
			FRGBArray^[i].B := Random(255);
		end;
	end;

	for i := 0 to lx*ly-1 do
		FDataArray^[i] := FNO_DATA_Value;
end;

procedure TUserLayer.Paint(Bitmap: TBitmap);
var
	x, y, i, Loc:	integer;
	xm, ix:			integer;
	LevelStep:		Single;
	cm:				TRGB;
	CurrLine:		PRGBArray;
begin
	LevelStep := (FLevelsNum-1)/(FMaxValue-FMinValue);
	for y := 0 to ly-1 do
	begin
		CurrLine := Bitmap.ScanLine[y];

		for x := 0 to lx-1 do
			if not FMasked_NO_DATA or (FDataArray^[x+lx*y]<>FNO_DATA_Value) then
			begin
				Loc := x + lx*y;
				if FDataArray^[Loc] = FNO_DATA_Value then
					ix := FLevelsNum
				else
					ix := Round((FDataArray^[Loc]-FMinValue)*LevelStep);
				cm := FRGBArray^[ix];

				for i := 0 to 1 do
				begin
					xm := (x-xwMini)*2 + i + (y and 1);
					while xm < 0 do		inc(xm, 2*lx);
					while xm >= 2*lx do	dec(xm, 2*lx);

					CurrLine^[xm] := cm;
				end;
			end;
	end;
end;

end.
