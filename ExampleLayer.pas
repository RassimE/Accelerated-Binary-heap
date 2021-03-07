//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//	Example of utilization of the 'User defined layer'

unit ExampleLayer;

interface

implementation

uses
	UserLayerUnit, CommonUnit;

type

TDangerLand = Class(TUserLayer)
	procedure InitLayerData;	override;
end;

procedure TDangerLand.InitLayerData;
var
	i, Loc, Dist,
	dx, dy, Value:	integer;
begin
	FNO_DATA_VALUE := 0;
	FLayerUpdate := [luCity];

	inherited;

	for i := 0 to RO.nEnemyCity-1 do
	begin
		for dy := -6 to 6 do
		begin
			for dx := -6 to 6 do
			if((dx+dy) and 1=0)then
			begin
				Loc := Relative(RO.EnemyCity[i].Loc, dx, dy);
				if Loc>=0 then
				begin
					Dist := Distance(Loc, RO.EnemyCity[i].Loc);
					if Dist<=10 then
					begin
						Value := 11-Dist;
						Inc(FDataArray^[Loc], Value);
						if FMaxValue < FDataArray^[Loc] then
							FMaxValue := FDataArray^[Loc];
						if FMinValue > FDataArray^[Loc] then
							FMinValue := FDataArray^[Loc];
					end;
				end;
			end;
		end
	end;
end;

initialization
	UserLayers.Add(TDangerLand.Create('Example','Danger rate', 'D'));
end.
