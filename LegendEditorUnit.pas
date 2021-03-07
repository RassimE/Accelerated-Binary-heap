//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

{$INCLUDE switches}
unit LegendEditorUnit;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls,
	StdCtrls, Buttons, ExtCtrls, Dialogs, Spin, Grids,
	Protocol, CommonUnit, UserLayerUnit;

type
  TLegendEditorDlg = class(TForm)
	OKBtn: TButton;
	CancelBtn: TButton;
	ColorDialog1: TColorDialog;
	DrawGrid1: TDrawGrid;
	SpinEdit1: TSpinEdit;
	Label1: TLabel;
	CheckBox1: TCheckBox;
    Label2: TLabel;
    ComboBox1: TComboBox;
    ApplyBtn: TButton;
	procedure CheckBox1Click(Sender: TObject);
	procedure DrawGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
	  Rect: TRect; State: TGridDrawState);
	procedure FormShow(Sender: TObject);
	procedure FormClose(Sender: TObject; var Action: TCloseAction);
	procedure SpinEdit1Change(Sender: TObject);
	procedure DrawGrid1MouseDown(Sender: TObject; Button: TMouseButton;
	  Shift: TShiftState; X, Y: Integer);
    procedure DrawGrid1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DrawGrid1DblClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
	procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
  private
	{ Private declarations }
	FUserLayer:				TUserLayer;
	FMinValue,
	FMaxValue:				Double;
	FMaskColor:				TColor;
	FColorArray:			array [0..1000] of TRGB;
	FTerrainColors:			array [0..15] of TRGB;
	FFormationColors:		array [0..3] of TRGB;
	FTribeColors:			array [0..nPl-1] of TRGB;

	FUnits:					string;
	Result, FLevelsNum,
	FColumn, FRow:			LongInt;
	FMasked,
	FMouseDown:				Boolean;

	procedure SetUserLayer(Layer: TUserLayer);

	procedure SetLayerName(Val: string);
	function ReadLayerName: string;
	procedure SetMasked(Val: Boolean);
	procedure SetMaskColor(Val: TColor);
	procedure SetLevelsNum(Val: integer);
	function GetLevelColor(I: integer): TColor;
	procedure SetLevelColor(I:integer; Val: TColor);
  public
	{ Public declarations }
//	Wrappers for user defined layers
	property UserLayer: TUserLayer read FUserLayer write SetUserLayer;
	property LayerName: string read ReadLayerName write SetLayerName;
	property Units: string read FUnits write FUnits;
	property Masked: Boolean read FMasked write SetMasked;
	property MaskColor: TColor read FMaskColor write SetMaskColor;
	property MinValue: Double read FMinValue write FMinValue;
	property MaxValue: Double read FMaxValue write FMaxValue;
	property LevelsNum: integer read FLevelsNum write SetLevelsNum;
	property LevelColor[I: integer]: TColor read GetLevelColor write SetLevelColor;
  end;

var
	LegendEditorDlg: TLegendEditorDlg;

implementation

{$R *.DFM}

uses
	MainUnit;

procedure TLegendEditorDlg.SetUserLayer(Layer: TUserLayer);
var
	i:		integer;
begin
	FUserLayer := Layer;
	LayerName := Layer.LayerName;
	Units := Layer.UnitsName;
	Masked := Layer.Masked_NO_DATA;
	LevelsNum := Layer.LevelsNum;
	if Layer.Masked_NO_DATA then
			MaskColor := Layer.LevelColor[Layer.LevelsNum];
	MinValue := Layer.MinValue;
	MaxValue := Layer.MaxValue;

	for i := 0 to Layer.LevelsNum do
			LevelColor[i] := Layer.LevelColor[i];
end;

procedure TLegendEditorDlg.SetLayerName(Val: string);
var
	i:	integer;
begin
	i := ComboBox1.ItemIndex;

	if(Val='')or(Val='NONE') then
	begin
		if ComboBox1.Items.Count > 3 then
			ComboBox1.Items.Delete(3);
		if i >= ComboBox1.Items.Count then
			i := ComboBox1.Items.Count-1
	end
	else
	begin
		if ComboBox1.Items.Count > 3 then
			ComboBox1.Items.Strings[3] := Val
		else
			ComboBox1.Items.Add(Val);
	end;

	ComboBox1.ItemIndex := i;
end;

function TLegendEditorDlg.ReadLayerName: string;
begin
	if ComboBox1.Items.Count > 3 then
		result := ComboBox1.Items.Strings[3]
	else
		result := ''
end;

procedure TLegendEditorDlg.SetMasked(Val: Boolean);
begin
	CheckBox1.Checked := Val;
	FMasked := Val;
end;

procedure TLegendEditorDlg.SetMaskColor(Val: TColor);
begin
	FMaskColor := Val;
end;

procedure TLegendEditorDlg.SetLevelsNum(Val: integer);
begin
	FLevelsNum := Val;
	SpinEdit1.Value := Val;
	DrawGrid1.RowCount := Val+1-Ord(FMasked);
	DrawGrid1.Repaint;
end;

function TLegendEditorDlg.GetLevelColor(I: integer): TColor;
begin
	Result := 0;
	if (I>=0)and(I<=SpinEdit1.Value)then
		Result := RGBToColor(FColorArray[I]);
end;

procedure TLegendEditorDlg.SetLevelColor(I:integer; Val: TColor);
var
	RGB:	TRGB;
begin
	if (I>=0)and(I<=SpinEdit1.Value)then
	begin
		RGB := ColorToRGB(Val);
		if (FColorArray[I].R <> RGB.R)or
			(FColorArray[I].G <> RGB.G)or
			(FColorArray[I].B <> RGB.B) then
		begin
			FColorArray[I] := RGB;
			DrawGrid1.Repaint;
		end;
	end;
end;

procedure TLegendEditorDlg.FormCreate(Sender: TObject);
var
	i:		integer;
	RGB:	TRGB;
begin
	for i := 0 to 999 do
	begin
		RGB.R := Random(256);
		RGB.G := Random(256);
		RGB.B := Random(256);
		FColorArray[i] := RGB;
	end;

	ComboBox1Change(ComboBox1);
end;

procedure TLegendEditorDlg.FormShow(Sender: TObject);
var
	i:		integer;
begin
	FMouseDown := False;
	Result := mrCancel;

	for i := 0 to fMountains do
		FTerrainColors[i] := ColorToRGB(TerrainColors[i]);
	FTerrainColors[fMountains+1] := ColorToRGB(TerrainColors[-1]);

	for i := 0 to 3 do
		FFormationColors[i] := ColorToRGB(FormationColors[TFormationKind(i)]);

	for i := 0 to nPl-1 do
		FTribeColors[i] := ColorToRGB(TribeColors[i]);
end;

procedure TLegendEditorDlg.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
	i:		integer;
begin
	if FMasked then
	begin

	end;

	if 	Result = mrOk then
	begin
		for i := 0 to fMountains do
			TerrainColors[i] := RGBToColor(FTerrainColors[i]);
		TerrainColors[-1] := RGBToColor(FTerrainColors[fMountains+1]);

		for i := 0 to 3 do
			FormationColors[TFormationKind(i)] := RGBToColor(FFormationColors[i]);
		GenerateFormationsColors;
		for i := 0 to nPl-1 do
			TribeColors[i] := RGBToColor(FTribeColors[i]);

		if(LayerName <> '')and(LayerName <> 'NONE')then
		begin
			FUserLayer.Masked_NO_DATA := FMasked;
			FUserLayer.LevelsNum := FLevelsNum;
			for i := 0 to FUserLayer.LevelsNum do
				FUserLayer.LevelColor[i] := LevelColor[i];
		end;
	end;
end;

procedure TLegendEditorDlg.CheckBox1Click(Sender: TObject);
begin
	if not CheckBox1.Enabled then exit;

	FMasked := CheckBox1.Checked;
	DrawGrid1.RowCount := SpinEdit1.Value+1-Ord(FMasked);
	DrawGrid1.Repaint;
end;

procedure TLegendEditorDlg.DrawGrid1DrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
	OldColor:		TColor;
	PColorArray:	PRGBArray;
begin
	OldColor := DrawGrid1.Canvas.Brush.Color;

	case ACol of
	0:	begin
			DrawGrid1.Canvas.FillRect(Rect);
			case ComboBox1.ItemIndex of
			0:	if ARow<SpinEdit1.Value then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, Name_TerrainType[ARow])
				else
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, Name_TerrainType[-1]);

			1:	if ARow = 0 then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'Hidden')
				else if ARow = 1 then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'Land')
				else if ARow = 2 then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'Water')
				else //if ARow = 3 then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'Pole');
			2:	DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'Tribe '+IntToStr(ARow));

			else
				if ARow<SpinEdit1.Value then
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'From '+
						FormatFloat('0.0######" "', FMinValue+(FMaxValue-FMinValue)/SpinEdit1.Value*ARow)+
							FUnits)
				else
					DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'No_DATA');
			end
		end;
	1:	if ComboBox1.ItemIndex>2 then
		begin
			DrawGrid1.Canvas.FillRect(Rect);
			if ARow<SpinEdit1.Value then
				DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, 'to '+
					FormatFloat('0.0######" "', FMinValue+(FMaxValue-FMinValue)/SpinEdit1.Value*(ARow+1))+
					FUnits);
		end;
	2:	begin
			case ComboBox1.ItemIndex of
			0:	PColorArray := @FTerrainColors;
			1:	PColorArray := @FFormationColors;
			2:	PColorArray := @FTribeColors;
			else
				PColorArray := @FColorArray;
			end;
			DrawGrid1.Canvas.Brush.Color :=
				PColorArray[ARow].R+
				(PColorArray[ARow].G shl 8)+
				(PColorArray[ARow].B shl 16);
			DrawGrid1.Canvas.FillRect(Rect);
		end;
	3:	begin
			DrawGrid1.Canvas.FillRect(Rect);
			if ARow<SpinEdit1.Value then
				DrawGrid1.Canvas.TextRect(Rect, Rect.Left, Rect.Top, '  '+IntToStr(ARow));
		end;
	end;

	DrawGrid1.Canvas.Brush.Color := OldColor;
	if gdFocused in State then
		DrawGrid1.Canvas.DrawFocusRect(Rect);
end;

procedure TLegendEditorDlg.SpinEdit1Change(Sender: TObject);
begin
	if not SpinEdit1.Enabled then exit;
	FLevelsNum := SpinEdit1.Value;
	DrawGrid1.RowCount := SpinEdit1.Value+1-Ord(FMasked);
	DrawGrid1.Repaint;
end;

procedure TLegendEditorDlg.DrawGrid1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	DrawGrid1.MouseToCell(X, Y, FColumn, FRow);
	if (not (ssDouble in Shift))and(Button = mbLeft) then
		FMouseDown := True;
end;

procedure TLegendEditorDlg.DrawGrid1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	sColor, eColor:	TRGB;
	ARow, ACol:		LongInt;
	Rs, Re, i:		Integer;
	PColorArray:	PRGBArray;
begin
	DrawGrid1.MouseToCell(X, Y, ACol, ARow);
	if FRow = ARow then
		Exit;
	Rs := DrawGrid1.Selection.Top;
	Re := DrawGrid1.Selection.Bottom;

	case ComboBox1.ItemIndex of
	0:		PColorArray := @FTerrainColors;
	1:		PColorArray := @FFormationColors;
	2:		PColorArray := @FTribeColors;
	else	PColorArray := @FColorArray;
	end;

	ColorDialog1.Color := rgbToColor(PColorArray[Rs]);
	if ColorDialog1.Execute then
	begin
		sColor := ColorToRGB(ColorDialog1.Color);
		ColorDialog1.Color := rgbToColor(PColorArray[Re]);
		if ColorDialog1.Execute then
		begin
			eColor := ColorToRGB(ColorDialog1.Color);
			for i := Rs to Re do
			begin
				PColorArray[i].R := Round(sColor.R+(eColor.R-sColor.R)/(Re-Rs)*(i-Rs));
				PColorArray[i].G := Round(sColor.G+(eColor.G-sColor.G)/(Re-Rs)*(i-Rs));
				PColorArray[i].B := Round(sColor.B+(eColor.B-sColor.B)/(Re-Rs)*(i-Rs));
			end;
			DrawGrid1.Repaint;
		end;
	end;
	FMouseDown := False;
end;

procedure TLegendEditorDlg.DrawGrid1DblClick(Sender: TObject);
var
	PColorArray:	PRGBArray;
begin
	case ComboBox1.ItemIndex of
	0:		PColorArray := @FTerrainColors;
	1:		PColorArray := @FFormationColors;
	2:		PColorArray := @FTribeColors;
	else	PColorArray := @FColorArray;
	end;

	ColorDialog1.Color := rgbToColor(PColorArray[FRow]);
	if ColorDialog1.Execute then
	begin
		PColorArray[FRow] := ColorToRGB(ColorDialog1.Color);
		DrawGrid1.Repaint;
	end;
end;

procedure TLegendEditorDlg.OKBtnClick(Sender: TObject);
begin
	Result := mrOk;
end;

procedure TLegendEditorDlg.CancelBtnClick(Sender: TObject);
begin
	Result := mrCancel;
end;

procedure TLegendEditorDlg.ComboBox1Change(Sender: TObject);
begin
	Label1.Enabled := ComboBox1.ItemIndex>2;
	SpinEdit1.Enabled := ComboBox1.ItemIndex>2;
	CheckBox1.Enabled := ComboBox1.ItemIndex>2;

	if ComboBox1.ItemIndex<=2 then	DrawGrid1.ColWidths[1]:=0
	else							DrawGrid1.ColWidths[1]:=95;

	Case ComboBox1.ItemIndex of
	0:	begin								//Terrain
			CheckBox1.Checked := False;
			SpinEdit1.Value := fMountains+1;
			DrawGrid1.RowCount := fMountains+2;
			DrawGrid1.Repaint;
		end;
	1:	begin								//Formations
			CheckBox1.Checked := True;
			SpinEdit1.Value := 4;
			DrawGrid1.RowCount := 4;
			DrawGrid1.Repaint;
		end;
	2:	begin								//Nations
			CheckBox1.Checked := True;
			SpinEdit1.Value := nPl-1;
			DrawGrid1.RowCount := nPl-1;
			DrawGrid1.Repaint;
		end;
	3:	SpinEdit1.Value := FLevelsNum;		//User defined layer
	end;
end;

procedure TLegendEditorDlg.ApplyBtnClick(Sender: TObject);
var
	i:		integer;
begin
	for i := 0 to fMountains do
		TerrainColors[i] := RGBToColor(FTerrainColors[i]);
	TerrainColors[-1] := RGBToColor(FTerrainColors[fMountains+1]);

	for i := 0 to 3 do
		FormationColors[TFormationKind(i)] := RGBToColor(FFormationColors[i]);
	GenerateFormationsColors;
	for i := 0 to nPl-1 do
		TribeColors[i] := RGBToColor(FTribeColors[i]);

	if(LayerName <> '')and(LayerName <> 'NONE')then
	begin
		FUserLayer.Masked_NO_DATA := Masked;
		FUserLayer.LevelsNum := FLevelsNum;
		for i := 0 to FUserLayer.LevelsNum do
			FUserLayer.LevelColor[i] := LevelColor[i];
	end;

	MainForm.RepaintMap;
end;

end.
