//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

//==============================================================
//	Original version created for C-Evo 13.0
//	Modified for C-Evo 14.0 & 14.1
//	http://C-Evo.org/

{$INCLUDE switches}
unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, ComCtrls, ExtDlgs, StdCtrls, Spin,
  PQUnit, Protocol, Buttons;
  
type
  TMainForm = class(TForm)
	MainMenu1: TMainMenu;
	File1: TMenuItem;
	Open1: TMenuItem;
	N1: TMenuItem;
	Exit1: TMenuItem;
	Saveasbmp1: TMenuItem;
	Benchmark1: TMenuItem;
	AverageTime1: TMenuItem;
	BestTime1: TMenuItem;
	N4: TMenuItem;
	FindFormations1: TMenuItem;
	FindFormations2: TMenuItem;
	N2: TMenuItem;
	GetMoveAdvice1: TMenuItem;
	GetMoveAdvice2: TMenuItem;
	Imitator1: TMenuItem;
	Map1: TMenuItem;
	Info1: TMenuItem;
	Brief1: TMenuItem;
	Detail1: TMenuItem;
	Legend1: TMenuItem;
	Help1: TMenuItem;
	About1: TMenuItem;
	PopupMenu1: TPopupMenu;
	Legend2: TMenuItem;
	CreateUnit1: TMenuItem;
	CreateCity1: TMenuItem;
	Nation1: TMenuItem;
	Nation2: TMenuItem;
	Nation3: TMenuItem;
	Nation4: TMenuItem;
	Nation5: TMenuItem;
	Nation6: TMenuItem;
	Nation7: TMenuItem;
	Nation8: TMenuItem;
	Nation9: TMenuItem;
	Nation10: TMenuItem;
	Nation11: TMenuItem;
	Nation12: TMenuItem;
	Nation13: TMenuItem;
	Nation14: TMenuItem;
	Nation15: TMenuItem;
	Nation16: TMenuItem;
	Nation17: TMenuItem;
	Nation18: TMenuItem;
	Nation19: TMenuItem;
	Nation20: TMenuItem;
	Nation21: TMenuItem;
	Nation22: TMenuItem;
	Nation23: TMenuItem;
	Nation24: TMenuItem;
    Nation25: TMenuItem;
    Nation26: TMenuItem;
    Nation27: TMenuItem;
    Nation28: TMenuItem;
    Nation29: TMenuItem;
    Nation30: TMenuItem;
	Panel1: TPanel;
	Panel2: TPanel;
	StatusBar1: TStatusBar;
	MiniImg: TImage;
	PaintBox1: TPaintBox;
	SpinEdit1: TSpinEdit;
	BreakBtn: TButton;
	TerrainRBtn: TRadioButton;
	FormationsRBtn: TRadioButton;
	TerritoryChBox: TCheckBox;
	UnitsChBox: TCheckBox;
	TownsChBox: TCheckBox;
	RoadsChBox: TCheckBox;
	ComboBox1: TComboBox;
	SpeedButton1: TSpeedButton;
	MeasureBtn: TSpeedButton;
	SavePictureDialog1: TSavePictureDialog;
	OpenDialog1: TOpenDialog;
	Label1: TLabel;
	Label2: TLabel;
	Label3: TLabel;
	Label4: TLabel;
	Label9: TLabel;
	Label5: TLabel;
	Label6: TLabel;
	procedure FormCreate(Sender: TObject);
	procedure FormResize(Sender: TObject);
	procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
	procedure Open1Click(Sender: TObject);
	procedure Saveasbmp1Click(Sender: TObject);
	procedure Exit1Click(Sender: TObject);
	procedure FindFormations1Click(Sender: TObject);
	procedure FindFormations2Click(Sender: TObject);
	procedure GetMoveAdvice1Click(Sender: TObject);
	procedure GetMoveAdvice2Click(Sender: TObject);
	procedure Imitator1Click(Sender: TObject);
	procedure Brief1Click(Sender: TObject);
	procedure Detail1Click(Sender: TObject);
	procedure Legend1Click(Sender: TObject);
	procedure About1Click(Sender: TObject);

	procedure SpinEdit1Change(Sender: TObject);
	procedure TerrainRBtnClick(Sender: TObject);
	procedure TerritoryChBoxClick(Sender: TObject);
	procedure TownsChBoxClick(Sender: TObject);
	procedure PaintBox1Paint(Sender: TObject);
	procedure PaintBox1Click(Sender: TObject);
	procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
	  Y: Integer);
	procedure SpeedButton1Click(Sender: TObject);
	procedure MeasureBtnClick(Sender: TObject);
	procedure BreakBtnClick(Sender: TObject);
	procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BestTime1Click(Sender: TObject);
    procedure Nation15Click(Sender: TObject);
    procedure Nation30Click(Sender: TObject);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
	{ Private declarations }
	Loaded:				Boolean;
	msX, msY,
	msXs, msYs,
	msXe, msYe,
	CommandMode,
	SelectedLoc,
	StartLoc, EndLoc,
	Stage, CurrLoc,
	PopupLoc, MapIndex:	Integer;
	Mini:				TBitmap;
	UnitNat, CityNat:	Array[0..nPl-1] of TMenuItem;
  public
	{ Public declarations }
	bBreak:		Boolean;

	function ClientToLoc(x, y: Integer): Integer;
	procedure LocToClient(Loc: Integer; var x, y: Integer);
	procedure PaintXYFromLoc(Loc: Integer; var x, y: integer);

	function TestFindFormations(V: integer): Double;
	function TestMoveAdvice(V: integer): Double;

	function SelectLoc(var Loc: Integer): Integer;
	function Measure(var Loc0, Loc1, Dist: Integer): Integer;

	procedure RepaintMap;
  end;

var
	MainForm: TMainForm;

implementation

{$R *.dfm}
{$R MainForm.res}
uses
	Math, CommonUnit, MoveAdviceParams, GetMoveAdviceUnit, UserLayerUnit,
	OldFindFormationsUnit, NewFindFormationsUnit, LegendEditorUnit, AboutDlgUnit;

const
	crTarget = 1;
	cmSelectLoc = 1;
	cmMeasure = 2;

//==============================================================
//					Helper functions
//==============================================================
function TMainForm.ClientToLoc(X, Y: Integer): Integer;
var
	kx, ky:			Double;
begin
	kx := Mini.Width / MiniImg.Width;
	ky := Mini.Height / MiniImg.Height;

	X := Trunc(X * kx);
	Y := Trunc(Y * ky);

	X := (X + 2-(Y and 1))shr 1 + xwMini-1;

	while X < 0 do		inc(X, lx);
	while X >=lx do		dec(X, lx);

	ClientToLoc := X + lx*Y;
end;

procedure TMainForm.LocToClient(Loc: Integer; var x, y: Integer);
var
	kx, ky:			Double;
begin
	kx := MiniImg.Width/Mini.Width;
	ky := MiniImg.Height/Mini.Height;

	y := Loc div lx;
	x := (Loc - y*lx-xwMini)*2+ (y and 1);
	if x >= 2*lx then dec(x, 2*lx);
	if x < 0 then inc(x, 2*lx);

	X := Trunc((X + 1.0) * kx);
	Y := Trunc((Y + 0.5) * ky);
end;

procedure TMainForm.PaintXYFromLoc(Loc: Integer; var x, y: integer);
begin
	y := Loc div lx;
	x := (Loc - y*lx-xwMini)*2+ (y and 1);
	if x >= 2*lx then dec(x, 2*lx);
	if x < 0 then inc(x, 2*lx);
end;

function TMainForm.SelectLoc(var Loc: Integer): Integer;
begin
	CommandMode := cmSelectLoc;
	PaintBox1.Cursor := crTarget;
	SelectedLoc := -1;

	while SelectedLoc<0 do
		Application.ProcessMessages;

	Loc := SelectedLoc;
	if Loc > MapSize then
		Loc := -1;
	result := Loc;
	CommandMode := -1;
	PaintBox1.Cursor := crCross;
end;

function TMainForm.Measure(var Loc0, Loc1, Dist: Integer): Integer;
begin
	CommandMode := cmMeasure;
	PaintBox1.Cursor := crTarget;
	Stage := 0;

	while Stage<2 do
		Application.ProcessMessages;

	CommandMode := -1;
	PaintBox1.Cursor := crCross;

	Loc0 := StartLoc;
	Loc1 := EndLoc;
	Dist := Distance(Loc0, Loc1);
	result := Dist
end;

function TMainForm.TestFindFormations(V: integer): Double;
var
	StartCount,
	EndCount,
	Current, Best,
	Frequency:		TLargeInteger;
	i:				integer;
begin
	if AverageTime1.Checked then
	begin
		QueryPerformanceCounter(StartCount);
		case V of
		0:	for i := 0 to 1000 do FindFormations_Old;
		1:	for i := 0 to 1000 do FindFormations_New;
		end;
		QueryPerformanceCounter(EndCount);
		QueryPerformanceFrequency(Frequency);
		result := 0.001*(EndCount-StartCount)/Frequency;
	end
	else
	begin
		Best := High(TLargeInteger);
		for i := 0 to 50 do
		begin
			case V of
			0:	begin
					QueryPerformanceCounter(StartCount);
					FindFormations_Old;
					QueryPerformanceCounter(EndCount);
				end;
			1:	begin
					QueryPerformanceCounter(StartCount);
					FindFormations_New;
					QueryPerformanceCounter(EndCount);
				end;

			end;
			Current := EndCount-StartCount;
			if Current< Best then Best := Current
		end;
		QueryPerformanceFrequency(Frequency);
		result := Best/Frequency;
	end;

	GenerateFormationsColors;

	if FormationsRBtn.Checked then	TerrainRBtnClick(FormationsRBtn)
	else							FormationsRBtn.Checked := True;
end;

function TMainForm.TestMoveAdvice(V: Integer): Double;
var
	MoveAdviceData:		TMoveAdviceData;
	PathColor:			TColor;
	i, x, y, x0, y0,
	xl, StartLoc,
	MoveAdviceResult:	Integer;
	StartCount,
	Current, Best,
	EndCount,
	Frequency:			TLargeInteger;
	PQ:					TBasePQ;
begin
	result := -1.0;

	GetMoveAdviceDlg.Label5.Visible := V<> 1;
	GetMoveAdviceDlg.UsedPQ.Visible := V<> 1;
	bBreak := False;
	File1.Enabled := False;
	Benchmark1.Enabled := False;
	MeasureBtn.Enabled := False;

	with GetMoveAdviceDlg do if ShowDialog = mrOK then
	begin
{$IFNDEF DISPLAY}
		File1.Enabled := True;
		Benchmark1.Enabled := True;
		MeasureBtn.Enabled := True;
{$ENDIF}
		if(V <> 1)then
		begin
			if not Assigned(PQArray[UsedPQ.ItemIndex]) then
			begin
				MessageDlg('Chosen PQ is not valid.', mtError, [mbOk], 0);
{$IFDEF DISPLAY}
				File1.Enabled := True;
				Benchmark1.Enabled := True;
				MeasureBtn.Enabled := True;
{$ENDIF}
				exit;
			end;
			PQ := PQArray[UsedPQ.ItemIndex];
		end;
		StartLoc := FromLoc.Value;

		RO.Un[RO.nUn].Loc := StartLoc;
		RO.Un[RO.nUn].Movement := MP.Value;
		RO.Un[RO.nUn].mix := 4;
		RO.Un[RO.nUn].Health := Health.Value;

		if AirUnit.Checked then
			RO.Model[4].Domain := dAir
		else if RO.Map[StartLoc] and fTerrain<=fShore then
		begin
			RO.Model[4].Domain := dSea;
			RO.Model[4].Cap[mcNav] := Byte(mcNavOver.Checked);
			if woMagellan.Checked then
				RO.Wonder[Protocol.woMagellan].EffectiveOwner := AIme
			else
				RO.Wonder[Protocol.woMagellan].EffectiveOwner := -1
		end
		else
		begin
			RO.Model[4].Domain := dGround;
			RO.Model[4].Cap[mcAlpine] := 0;
			if woShinkansen.Checked then
				RO.Wonder[Protocol.woShinkansen].EffectiveOwner := AIme
			else
				RO.Wonder[Protocol.woShinkansen].EffectiveOwner := -1;
			RO.Model[4].Cap[mcOver] := Byte(mcNavOver.Checked);

			if woGardens.Checked then
				RO.Wonder[Protocol.woGardens].EffectiveOwner := AIme
			else
				RO.Wonder[Protocol.woGardens].EffectiveOwner := -1
		end;

		RO.Model[4].Speed := RO.Un[RO.nUn].Movement;

		MoveAdviceData.ToLoc := ToLoc.Value;
		MoveAdviceData.MaxHostile_MovementLeft := 100;
		MoveAdviceData.MoreTurns := 999;

		Inc(RO.nUn);
{$IFDEF DISPLAY}
		BreakBtn.Visible := True;
{$ELSE}
	if AverageTime1.Checked then
	begin
		QueryPerformanceCounter(StartCount);
{$ENDIF}
		if V = 0 then
		begin
{$IFDEF DISPLAY}
			for i := 0 to 4 do
{$ELSE}
			PathColor := 195;
			for i := 0 to 10000 do
{$ENDIF}
			begin
				MoveAdviceData.MaxHostile_MovementLeft := 100;
				MoveAdviceData.MoreTurns := 999;
{$IFDEF DISPLAY}
				if bBreak then	break;
{$ENDIF}
				MoveAdviceResult := GetMoveAdvice(RO.nUn-1, MoveAdviceData, PQ);
			end
		end
		else if V = 1 then
		begin
{$IFDEF DISPLAY}
			for i := 0 to 4 do
{$ELSE}
			PathColor := 255;
			for i := 0 to 10000 do
{$ENDIF}
			begin
				MoveAdviceData.MaxHostile_MovementLeft := 100;
				MoveAdviceData.MoreTurns := 999;
{$IFDEF DISPLAY}
				if bBreak then	break;
{$ENDIF}
				MoveAdviceResult := GetMoveAdviceA(RO.nUn-1, MoveAdviceData);
			end
		end
		else if V = 2 then
		begin
{$IFDEF DISPLAY}
			for i := 0 to 4 do
{$ELSE}
			for i := 0 to 10000 do
{$ENDIF}
			begin
				MoveAdviceData.MaxHostile_MovementLeft := 100;
				MoveAdviceData.MoreTurns := 999;
{$IFDEF DISPLAY}
				if bBreak then	break;
{$ENDIF}
				Imitator(RO.nUn-1, MoveAdviceData, PQ);
			end;
		end;

{$IFDEF DISPLAY}
		File1.Enabled := True;
		Benchmark1.Enabled := True;
		MeasureBtn.Enabled := True;
		BreakBtn.Visible := False;
{$ELSE}
		QueryPerformanceCounter(EndCount);
		QueryPerformanceFrequency(Frequency);
		result := 0.0001*(EndCount-StartCount)/Frequency;
	end
	else
	begin
		Best := High(TLargeInteger);
		for i := 0 to 250 do
		begin
			case V of
			0:	begin
					PathColor := 195;
					MoveAdviceData.MaxHostile_MovementLeft := 100;
					MoveAdviceData.MoreTurns := 999;
					QueryPerformanceCounter(StartCount);
					MoveAdviceResult := GetMoveAdvice(RO.nUn-1, MoveAdviceData, PQ);
					QueryPerformanceCounter(EndCount);
				end;
			1:	begin
					PathColor := 255;
					MoveAdviceData.MaxHostile_MovementLeft := 100;
					MoveAdviceData.MoreTurns := 999;
					QueryPerformanceCounter(StartCount);
					MoveAdviceResult := GetMoveAdviceA(RO.nUn-1, MoveAdviceData);
					QueryPerformanceCounter(EndCount);
				end;
			2:	begin
					MoveAdviceData.MaxHostile_MovementLeft := 100;
					MoveAdviceData.MoreTurns := 999;
					QueryPerformanceCounter(StartCount);
					Imitator(RO.nUn-1, MoveAdviceData, PQ);
					QueryPerformanceCounter(EndCount);
				end;
			end;
			Current := EndCount-StartCount;
			if Current< Best then Best := Current
		end;
		QueryPerformanceFrequency(Frequency);
		result := Best/Frequency;
	end;

		if V <=1 then
		begin
			while(MoveAdviceResult = eOk)and(StartLoc<>MoveAdviceData.ToLoc)and(MoveAdviceData.nStep>0) do
			begin
				MoveAdviceData.MaxHostile_MovementLeft := 100;
				MoveAdviceData.MoreTurns := 999;

				if V = 0 then
					MoveAdviceResult := GetMoveAdvice(RO.nUn-1, MoveAdviceData, PQ)
				else
					MoveAdviceResult := GetMoveAdviceA(RO.nUn-1, MoveAdviceData);

				MiniImg.Canvas.Pen.Color := PathColor;
				PaintXYFromLoc(StartLoc, x0, y0);
//				MiniImg.Canvas.Pixels[x0, y0] := RGB(195, 0, 195);
				MiniImg.Canvas.Pixels[x0+1, y0] := RGB(195, 0, 195);
				MiniImg.Canvas.MoveTo(x0, y0);

				xl := x0;
				for i := 0 to MoveAdviceData.nStep -1 do
				begin
					StartLoc := Relative(StartLoc, MoveAdviceData.dx[i], MoveAdviceData.dy[i]);
					PaintXYFromLoc(StartLoc, x, y);

					if abs(xl-x)>lx then
					begin
						MiniImg.Canvas.Pixels[x0, y0] := PathColor;
						MiniImg.Canvas.MoveTo(x, y);
					end
					else
						MiniImg.Canvas.LineTo(x, y);
					xl := x;
//				MiniImg.Canvas.Pixels[x, y] := PathColor;
///				MiniImg.Canvas.Pixels[x+1, y] := PathColor;
				end;
				MiniImg.Canvas.Pixels[x0, y0] := RGB(195, 0, 195);
//			MiniImg.Canvas.Pixels[x0+1, y0] := RGB(195, 0, 195);
				RO.Un[RO.nUn-1].Loc := StartLoc;
			end;
			MiniImg.Canvas.Pixels[x, y] := RGB(195, 128, 195);
			MiniImg.Canvas.Pixels[x+1, y] := RGB(195, 128, 195);
		end;
	{$IFDEF STATISTICS}
		self.Label5.Caption := 'MaxN = '+IntToStr(MaxN);
//		Label6.Caption := 'nAddNode = '+IntToStr(nAddNode);
//		Label7.Caption := 'nDecreaseKey = '+IntToStr(nDecreaseKey);
//		Label8.Caption := 'nDeleteNode = '+IntToStr(nDeleteNode);
//		Label6.Caption := 'MaxD = '+ FormatFloat('00.00', 100.0*MaxD);
//		Label7.Caption := 'MaxI = '+ FormatFloat('00.00', 100.0*MaxI);
	{$ENDIF}
{$ENDIF}
		Dec(RO.nUn);
	end
	else
	begin
		File1.Enabled := True;
		Benchmark1.Enabled := True;
		MeasureBtn.Enabled := True;
	end;
end;

procedure TMainForm.RepaintMap;
begin
	if MapIndex = 0 then	PaintMiniMap(Mini, TerritoryChBox.Checked)
	else					PaintFormations(Mini, TerritoryChBox.Checked);

	if ComboBox1.ItemIndex>0 then
		TUserLayer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]).Paint(Mini);
end;

//==============================================================
//						MainForm events
//==============================================================
procedure TMainForm.FormCreate(Sender: TObject);
var
	i, ii, l:		integer;
	j:				TFormationKind;
	iniFile:		String;
	StringList:		TStringList;
	RandomRGB:		TRGB;
begin
	CommandMode := -1;
	Screen.Cursors[crTarget] := LoadCursor(HInstance, 'SELECTLOC');

	Mini := MiniImg.Picture.Bitmap;
	Mini.Width := 1;
	Mini.Height := 1;
	Mini.PixelFormat := pf24bit;

	Loaded := False;
	ShowPolitical := False;
	MapIndex := 0;

	UnitNat[0] := Nation1;		CityNat[0] := Nation16;
	UnitNat[1] := Nation2;		CityNat[1] := Nation17;
	UnitNat[2] := Nation3;		CityNat[2] := Nation18;
	UnitNat[3] := Nation4;		CityNat[3] := Nation19;
	UnitNat[4] := Nation5;		CityNat[4] := Nation20;
	UnitNat[5] := Nation6;		CityNat[5] := Nation21;
	UnitNat[6] := Nation7;		CityNat[6] := Nation22;
	UnitNat[7] := Nation8;		CityNat[7] := Nation23;
	UnitNat[8] := Nation9;		CityNat[8] := Nation24;
	UnitNat[9] := Nation10;		CityNat[9] := Nation25;
	UnitNat[10] := Nation11;	CityNat[10] := Nation26;
	UnitNat[11] := Nation12;	CityNat[11] := Nation27;
	UnitNat[12] := Nation13;	CityNat[12] := Nation28;
	UnitNat[13] := Nation14;	CityNat[13] := Nation29;
	UnitNat[14] := Nation15;	CityNat[14] := Nation30;

	iniFile := ChangeFileExt(Application.ExeName, '.ini');
	if FileExists(iniFile) then
	begin
		StringList := TStringList.Create;
		StringList.LoadFromFile(iniFile);
		for i := -1 to fMountains do 
			TerrainColors[i] :=
				StrToIntDef(StringList.Values[Name_TerrainType[i]], TerrainColors[i]);

		for j := Hidden to Pole do
			FormationColors[j] :=
				StrToIntDef(StringList.Values[Name_FormationKind[j]], FormationColors[j]);

		for i := 0 to nPl-1 do
			TribeColors[i] :=
				StrToIntDef(StringList.Values['Tribe'+IntToStr(i)], TribeColors[i]);

//	User defined leyers
		for i := 0 to UserLayers.Count-1 do with TUserLayer(UserLayers.Items[i]) do
		begin
			l := StrToIntDef(StringList.Values[LayerName], -1);
			if l>=0 then
			begin
//				FieldName := StringList.Values['Layer'+IntToStr(l)+'Field'];
				Masked_NO_DATA :=
					StrToIntDef(StringList.Values['Layer'+IntToStr(l)+'Masked_NO_DATA'], 0)<>0;
				LevelsNum :=
					StrToIntDef(StringList.Values['Layer'+IntToStr(l)+'LevelsNum'], 10);

				for ii := 0 to LevelsNum do
				begin
					RandomRGB.R := Random(255);
					RandomRGB.G := Random(255);
					RandomRGB.B := Random(255);
					LevelColor[ii] :=
							StrToIntDef(StringList.Values['Layer'+IntToStr(l)+'Level'+IntToStr(ii)],
							RGBToColor(RandomRGB));
				end;
			end;
		end;

		StringList.Free;
	end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
	MapWidth := ClientWidth;
	MapHeight := ClientHeight;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
	bBreak := True;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
	i, ii:			integer;
	j:				TFormationKind;
	iniFile:		String;
	StringList:		TStringList;
begin
	iniFile := ChangeFileExt(Application.ExeName, '.ini');

	StringList := TStringList.Create;
	for i := -1 to fMountains do if Name_TerrainType[i]<>'' then
		StringList.Add(Name_TerrainType[i]+'='+IntTostr(TerrainColors[i]));

	for j := Hidden to Pole do
		StringList.Add(Name_FormationKind[j]+'='+IntTostr(FormationColors[j]));

	for i := 0 to nPl-1 do
		StringList.Add('Tribe'+IntToStr(i)+'='+IntTostr(TribeColors[i]));

//	User defined leyers
	for i := 0 to UserLayers.Count-1 do with TUserLayer(UserLayers.Items[i]) do
	begin
		StringList.Add(LayerName+'='+IntToStr(i));
		StringList.Add('Layer'+IntToStr(i)+'Field='+FieldName);
		StringList.Add('Layer'+IntToStr(i)+'Units='+UnitsName);
		StringList.Add('Layer'+IntToStr(i)+'Masked_NO_DATA='+IntToStr(Ord(Masked_NO_DATA)));
		StringList.Add('Layer'+IntToStr(i)+'LevelsNum='+IntToStr(LevelsNum));
		for ii := 0 to LevelsNum do
			StringList.Add('Layer'+IntToStr(i)+'Level'+IntToStr(ii)+'='+IntToStr(LevelColor[ii]));
	end;

	StringList.SaveToFile(iniFile);
	StringList.Free;
end;
//==============================================================
//						PaintBox events
//==============================================================
procedure TMainForm.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
	if Loaded then
	begin
		CurrLoc := ClientToLoc(X, Y);

		if RO.Map[CurrLoc] and fTerrain<=fShore then
			if FormationInfo[iFormation[CurrLoc]].Size>50 then
				StatusBar1.Panels[0].Text := 'Ocean ' + IntToStr(iFormation[CurrLoc])
			else
				StatusBar1.Panels[0].Text := 'Lake ' + IntToStr(iFormation[CurrLoc])
		else if RO.Map[CurrLoc] and fTerrain<>fUNKNOWN then
			if FormationInfo[iFormation[CurrLoc]].Size>50 then
				StatusBar1.Panels[0].Text := 'Continent ' + IntToStr(iFormation[CurrLoc])
			else
				StatusBar1.Panels[0].Text := 'Island ' + IntToStr(iFormation[CurrLoc])
		else
			StatusBar1.Panels[0].Text := 'UNKNOWN';


		if RO.Map[CurrLoc] and fTerrain<>fUNKNOWN then
			StatusBar1.Panels[1].Text := 'Size: '+IntToStr(FormationInfo[iFormation[CurrLoc]].Size)
		else
			StatusBar1.Panels[1].Text := 'Size: UNKNOWN';


		StatusBar1.Panels[2].Text := 'Adjacent: '+ IntToHex(FormationInfo[iFormation[CurrLoc]].Adjacent, 8);

		StatusBar1.Panels[3].Text := 'Loc: '+IntToStr(CurrLoc);

		if RO.Map[CurrLoc] and fTerrain<>fUNKNOWN then
			StatusBar1.Panels[4].Text := 'Type: '+ Name_TerrainType[RO.Map[CurrLoc] and fTerrain]
		else
			StatusBar1.Panels[4].Text := 'Type: UNKNOWN';


		case FormationInfo[iFormation[CurrLoc]].Kind of
		Hidden:
			StatusBar1.Panels[5].Text := 'Kind: Hidden';
		Land:
			StatusBar1.Panels[5].Text := 'Kind: Land';
		Water:
			StatusBar1.Panels[5].Text := 'Kind: Water';
		Pole:
			StatusBar1.Panels[5].Text := 'Kind: Pole';
		end;

		if Stage = 1 then
		begin
			PaintBox1.Canvas.Pen.Color := RGB(255,255,255);
			PaintBox1.Canvas.Pen.Mode := pmXor;
			PaintBox1.Canvas.MoveTo(msXs, msYs);
			PaintBox1.Canvas.LineTo(msX, msY);

			PaintBox1.Canvas.MoveTo(msXs, msYs);
			PaintBox1.Canvas.LineTo(X, Y);
			StatusBar1.Panels[6].Text := 'Loc0: '+ IntTostr(StartLoc)+
										 ', Loc1: '+ IntTostr(CurrLoc)+
							'; Distance = '+IntTostr(Distance(StartLoc, CurrLoc))
		end
		else if Stage = 2 then
		begin
			PaintBox1.Canvas.Pen.Color := RGB(255,255,255);
			PaintBox1.Canvas.Pen.Mode := pmXor;
			PaintBox1.Canvas.MoveTo(msXs, msYs);
			PaintBox1.Canvas.LineTo(X, Y);
			StatusBar1.Panels[6].Text := 'Loc0: '+ IntTostr(StartLoc)+
									 ', Loc1: '+ IntTostr(EndLoc)+
										'; Distance = '+IntTostr(Distance(StartLoc, CurrLoc));

			MessageDlg(
			'Loc0 = '+ IntTostr(StartLoc)+'			Loc1 = '+ IntTostr(EndLoc)+
			chr(10)+chr(13)+

			'a0 = '+IntToStr(XYab[StartLoc].a)+', b0 = '+IntToStr(XYab[StartLoc].b)+
			'		a1 = '+IntToStr(XYab[EndLoc].a)+', b1 = '+IntToStr(XYab[EndLoc].b)+
			chr(10)+chr(13)+

			'X0 = '+IntToStr(XYab[StartLoc].X)+', Y0 = '+IntToStr(XYab[StartLoc].Y)+
			'		X1 = '+IntToStr(XYab[EndLoc].X)+', Y1 = '+IntToStr(XYab[EndLoc].Y)+
			chr(10)+chr(13)+

			chr(9)+chr(9)+'Distance = '+IntTostr(Distance(StartLoc, CurrLoc)),
			mtInformation, [mbOk], 0);

			Stage := 3;
		end
		else if ComboBox1.ItemIndex > 0 then
			with TUserLayer(ComboBox1.Items.Objects[ComboBox1.ItemIndex])do
			begin
				if Value[CurrLoc]<>NodataValue then
					StatusBar1.Panels[6].Text := FieldName + '='+
							IntToStr(Value[CurrLoc])+' '+ UnitsName
				else
					StatusBar1.Panels[6].Text := FieldName + '= NONE';
			end;
	end;
	msX := X;
	msY := Y;
end;

procedure TMainForm.PaintBox1Click(Sender: TObject);
begin
	if CommandMode = cmSelectLoc then
		SelectedLoc := CurrLoc
	else if CommandMode = cmMeasure then
	begin
		if Stage >= 3 then	Stage := 0;

		if Stage = 0 then
		begin
			StatusBar1.Panels[6].Text := '';
			msXs := msX;	msYs := msY;
			StartLoc := CurrLoc;	EndLoc := CurrLoc;
		end
		else if Stage = 1 then
		begin
			msXe := msX;	msYe := msY;
			EndLoc := CurrLoc;
		end;
		inc(Stage)
	end;
end;

procedure TMainForm.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
	Point:			TPoint;
	i, Loc,	Tile:	Integer;
begin
	if Loaded and (Button = mbRight) then
	begin
		Loc := ClientToLoc(X, Y);
		PopupLoc := Loc;
		Tile := RO.Map[Loc];
		CreateUnit1.Enabled := (Tile and fTerrain<>fUNKNOWN);
		CreateCity1.Enabled := (Tile and fTerrain<>fUNKNOWN)and
			(Terrain[Tile and fTerrain].IrrEff<>0)and(Tile and fCity=0);
		for i := 0 to nPl-1 do
		begin
			UnitNat[i].Enabled := (Occupant[Loc] = -1)or(Occupant[Loc] = i);
			CityNat[i].Enabled := (Occupant[Loc] = -1)or(Occupant[Loc] = i);
		end;

		Point.X := X;
		Point.Y := Y;
		Point := PaintBox1.ClientToScreen(Point);
		PopupMenu1.Popup(Point.X, Point.Y)
	end;
end;

procedure TMainForm.PaintBox1Paint(Sender: TObject);
var
	r:	integer;
begin
	if not Loaded then exit;

	r := Round(Min(MiniImg.Height/Mini.Height, MiniImg.Width/Mini.Width));
	if r < 2 then r := 2;
	PaintFeatures(PaintBox1.Canvas, r, MiniImg.Width,
		RoadsChBox.Checked, TownsChBox.Checked, UnitsChBox.Checked);
end;

//==============================================================
//			Menu events
//==============================================================
//========================= File ===============================
procedure TMainForm.Open1Click(Sender: TObject);
//--------------------------------------------------------------
function readDATFile(FileName: TFileName): Boolean;
var
	F:			File;
	MapSign:	packed array[0..11] of char;
begin
	result := False;
	AssignFile(F, FileName);
	FileMode := 0;  //Set file access to read only
	Reset(F, 1);

	try
		BlockRead(F, MapSign, 12);
		if string(MapSign)<> 'Map Data 01' then
		begin
			CloseFile(F);
			exit;
		end;

		BlockRead(F, lx, SizeOf(integer));
		BlockRead(F, ly, SizeOf(integer));

		MapSize := lx*ly;
		decompose24 := (1 shl 24-1) div lx +1;

		BlockRead(F, RO.Map^, MapSize*SizeOf(Cardinal));
		BlockRead(F, RO.MapObservedLast^, MapSize*SizeOf(SmallInt));
		BlockRead(F, RO.Territory^, MapSize*SizeOf(ShortInt));
		CloseFile(F);
		result := True;
	except
		CloseFile(F);
	end;
end;
//--------------------------------------------------------------
function readMAPFile(FileName: TFileName): Boolean;
var
	F:				File;
	FormatID:		packed array[0..8] of char;
	MaxTurn, Formatversion,
	Loc:			integer;
begin
	result := False;
	AssignFile(F, FileName);
	FileMode := 0;  //Set file access to read only
	Reset(F, 1);
	try
		FormatID[8] := chr(0);
		BlockRead(F, FormatID, 8);
		if string(FormatID)<> 'cEvoMap' then
		begin
			CloseFile(F);
			exit;
		end;

		BlockRead(F, Formatversion, 4);
		if Formatversion <> 0 then
		begin
			CloseFile(F);
			exit;
		end;
		BlockRead(F, MaxTurn, 4);

		BlockRead(F, lx, 4);
		BlockRead(F, ly, 4);

		MapSize := lx*ly;
		BlockRead(F, RO.Map^, MapSize*SizeOf(Cardinal));
		for Loc := 0 to MapSize-1 do
		begin
			RO.MapObservedLast[Loc] := 0;
			RO.Territory[Loc] := -1;
		end;
		CloseFile(F);
		result := True;
	except
		CloseFile(F);
	end;
end;
//--------------------------------------------------------------
var
	ReadResult:		Boolean;
	i, k, Loc,
	nn, dx, dy:		integer;
begin
	if OpenDialog1.Execute then
	begin
		if OpenDialog1.FilterIndex = 1 then		ReadResult := readMAPFile(OpenDialog1.FileName)
		else									ReadResult := readDATFile(OpenDialog1.FileName);

		if not ReadResult then
		begin
			MessageDlg('Error on file '+ ExtractFileName(OpenDialog1.FileName),
				mtError, [mbOk], 0);
			exit
		end;
		decompose24 := (1 shl 24-1) div lx +1;

		Mini.Width := 2*lx;
		Mini.Height := ly;
		FillChar(Occupant, SizeOf(Occupant), 255);
		FillChar(tCount, SizeOf(tCount), 0);

		AIme := nPl-1;			Turn := 0;
		RO.nEnemyCity := 0;		RO.nCity := 0;
		for Loc := 0 to MapSize-1 do
		begin
			inc(tCount[RO.Map[Loc] and fTerrain]);
			if RO.Map[Loc] and fTerrain<=fShore then
				inc(tCount[cntWaterTiles])
			else if RO.Map[Loc] and fTerrain<>fUNKNOWN then
				inc(tCount[cntLandTiles]);

			if ObservedLast[Loc] > Turn then Turn := ObservedLast[Loc];

			XYab[Loc].Y := Loc div lx;
			XYab[Loc].X :=(Loc - XYab[Loc].Y*lx)shl 1 +  XYab[Loc].Y and 1;
			dy	:=	XYab[Loc].Y;
			dx	:=	((2*(Loc - XYab[Loc].Y*lx) + XYab[Loc].Y and 1)+3*lx) mod (2*lx) - lx;

			XYab[Loc].a :=(dx+dy) div 2;
			XYab[Loc].b :=(dy-dx) div 2;

			if RO.Map[Loc] and fCity<>0 then
			begin
				Occupant[Loc] := RO.Territory[Loc];
				if RO.Map[Loc] and fOwned<>0 then
				begin
					AIme := Occupant[Loc];
					RO.City[RO.nCity].Loc := Loc;
					RO.City[RO.nCity].ID := RO.nCity;
					Inc(RO.nCity);
				end
				else
				begin
					RO.EnemyCity[RO.nEnemyCity].Loc := Loc;
					RO.EnemyCity[RO.nEnemyCity].ID := RO.nEnemyCity;
					RO.EnemyCity[RO.nEnemyCity].Owner := Occupant[Loc];
					Inc(RO.nEnemyCity);
				end;
			end;
		end;

		RO.nEnemyUn := 0;	RO.nUn := 0;

		for Loc := 0 to MapSize-1 do
		begin
			if RO.Map[Loc] and fUnit<>0 then
			begin
				if RO.Map[Loc] and fOwned<>0 then
				begin
					RO.Un[RO.nUn].Loc := Loc;
					RO.Un[RO.nUn].ID := RO.nUn;
					Occupant[Loc] := AIme;
					if RO.Map[Loc] and fTerrain<=fShore then
						RO.Un[RO.nUn].mix := 3
					else
						RO.Un[RO.nUn].mix := 2;
					RO.Un[RO.nUn].Home := 0;
					Inc(RO.nUn)
				end
				else
				begin
					RO.EnemyUn[RO.nEnemyUn].Loc := Loc;
					if(RO.Territory[Loc]>-1)and(RO.Territory[Loc]<>AIme) then
						RO.EnemyUn[RO.nEnemyUn].Owner := RO.Territory[Loc]
					else
						repeat
							RO.EnemyUn[RO.nEnemyUn].Owner := Random(nPl)
						until RO.EnemyUn[RO.nEnemyUn].Owner<>AIme;

					Occupant[Loc] := RO.EnemyUn[RO.nEnemyUn].Owner;
					if RO.Map[Loc] and fTerrain<=fShore then
						RO.EnemyUn[RO.nEnemyUn].emix := 1
					else
						RO.EnemyUn[RO.nEnemyUn].emix := 0;
					Inc(RO.nEnemyUn)
				end;
			end;
		end;

		Label3.Caption := 'Player = '+ IntToStr(AIme);
		Label4.Caption := 'Turn = '+ IntToStr(Turn);

		FindFormations_Old;
		GenerateFormationsColors;

		k := ComboBox1.ItemIndex;
		for i := ComboBox1.Items.Count-1  downto 1 do
			ComboBox1.Items.Delete(i);

		for i := 0 to UserLayers.Count-1 do	with TUserLayer(UserLayers.Items[i]) do
		begin
			InitLayerData;
			ComboBox1.AddItem(LayerName, UserLayers.Items[i]);
		end;
		ComboBox1.ItemIndex := k;

		SpinEdit1.MaxValue := lx;
		SpinEdit1.Value := 0;

		RepaintMap;

		MiniImg.Refresh;
		Loaded := True;
		Saveasbmp1.Enabled := True;
		Benchmark1.Enabled := True;
		Panel1.Enabled := True;
		Panel2.Enabled := True;

		MeasureBtn.Enabled := True;
		Map1.Enabled := True;
		Application.Title := ApplicationTitle+' ['+ ExtractFileName(OpenDialog1.FileName)+']';
		Caption := Application.Title;
	end;
end;

procedure TMainForm.Saveasbmp1Click(Sender: TObject);
begin
	if SavePictureDialog1.Execute then
		MiniImg.Picture.SaveToFile(SavePictureDialog1.FileName)
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
	Close
end;

//========================= Map ===============================
procedure TMainForm.Brief1Click(Sender: TObject);
var
	iKnownTiles:	integer;
	MessageStr:		String;
begin
	iKnownTiles := MapSize-tCount[fUNKNOWN];
	MessageStr :=	'lx = '+ IntTostr(lx)+'			ly = '+ IntTostr(ly)+
					chr(10)+chr(13)+
					'Map Size = '+chr(9)+IntToStr(MapSize)+chr(10)+chr(13)+
					'Known tiles ='+chr(9)+IntTostr(iKnownTiles)+'/'+
						chr(9)+IntTostr(Round(100.0*iKnownTiles/MapSize))+'%'+
					chr(10)+chr(13);
	if iKnownTiles>0 then
		MessageStr := MessageStr +
					'Water tiles ='+chr(9)+ IntTostr(tCount[cntWaterTiles])+'/'+
						chr(9)+IntTostr(Round(100.0*tCount[cntWaterTiles]/iKnownTiles))+'%'+
					chr(10)+chr(13)+
					'Land tiles ='+chr(9)+ IntTostr(tCount[cntLandTiles])+'/'+
						chr(9)+IntTostr(Round(100.0*tCount[cntLandTiles]/iKnownTiles))+'%';

	MessageDlg(MessageStr, mtInformation, [mbOk], 0);
end;

procedure TMainForm.Detail1Click(Sender: TObject);
var
	i, iKnownTiles:	integer;
	MessageStr:		String;
begin
	iKnownTiles := MapSize-tCount[fUNKNOWN];
	MessageStr :=	'lx = '+ IntTostr(lx)+'			ly = '+ IntTostr(ly)+
					chr(10)+chr(13)+
					'Map Size = '+chr(9)+IntToStr(MapSize)+chr(10)+chr(13)+
					'Known tiles ='+chr(9)+ IntTostr(iKnownTiles)+'/'+
						chr(9)+IntTostr(Round(100.0*iKnownTiles/MapSize))+'%'+
					chr(10)+chr(13);
	if iKnownTiles>0 then
		MessageStr := MessageStr +
					'Water tiles ='+chr(9)+ IntTostr(tCount[cntWaterTiles])+'/'+
						chr(9)+IntTostr(Round(100.0*tCount[cntWaterTiles]/iKnownTiles))+'%'+
					chr(10)+chr(13)+
					'Land tiles ='+chr(9)+IntTostr(tCount[cntLandTiles])+'/'+
						chr(9)+IntTostr(Round(100.0*tCount[cntLandTiles]/iKnownTiles))+'%'+
					chr(10)+chr(13);

	for i := fOcean to fMountains do if Name_TerrainType[i]<>'' then
		MessageStr := MessageStr + chr(10)+chr(13)+ Name_TerrainType[i]+' =  	'+ IntTostr(tCount[i])+
				'/'+chr(9)+IntTostr(Round(100.0*tCount[i]/iKnownTiles))+'%';

	MessageDlg(MessageStr, mtInformation, [mbOk], 0);
end;

procedure TMainForm.Legend1Click(Sender: TObject);
begin
	if ComboBox1.ItemIndex > 0 then
		LegendEditorDlg.UserLayer := TUserLayer(ComboBox1.Items.Objects[ComboBox1.ItemIndex])
	else
		LegendEditorDlg.LayerName := '';

	if LegendEditorDlg.ShowModal =  mrOK then
		RepaintMap
end;

//======================== Tools =============================
procedure TMainForm.BestTime1Click(Sender: TObject);
begin
	TMenuItem(Sender).Checked := True
end;

procedure TMainForm.FindFormations1Click(Sender: TObject);
var
	fTime:			Double;
begin
	fTime := TestFindFormations(0);
	Label1.Caption := 'FindFormations Test1 Time: ' + FormatFloat('0.0000000', fTime);
end;

procedure TMainForm.FindFormations2Click(Sender: TObject);
var
	fTime:			Double;
begin
	fTime := TestFindFormations(1);
	Label2.Caption := 'FindFormations Test2 Time: ' + FormatFloat('0.0000000', fTime);
end;

procedure TMainForm.GetMoveAdvice1Click(Sender: TObject);
var
	fTime:	Double;
begin
	SpeedButton1.Click;
	SpeedButton1.Down := True;
	fTime := TestMoveAdvice(0);
	if fTime >= 0 then
		Label1.Caption := 'GetMoveAdvice Test1 Time: ' + FormatFloat('0.0000000', fTime);
end;

procedure TMainForm.GetMoveAdvice2Click(Sender: TObject);
var
	fTime:			Double;
begin
	SpeedButton1.Click;
	SpeedButton1.Down := True;
	fTime := TestMoveAdvice(1);
	if fTime >= 0 then
		Label2.Caption := 'GetMoveAdvice Test2 Time: ' + FormatFloat('0.0000000', fTime);
end;

procedure TMainForm.Imitator1Click(Sender: TObject);
var
	fTime:			Double;
begin
	SpeedButton1Click(nil);
	fTime := TestMoveAdvice(2);
	if fTime >= 0 then
		Label2.Caption := 'GetMoveAdvice Test2 Time: ' + FormatFloat('0.0000000', fTime);
end;

//========================= Help ==============================
procedure TMainForm.About1Click(Sender: TObject);
begin
	AboutBox.ShowModal
end;

//========================= Popup ==============================
procedure TMainForm.Nation15Click(Sender: TObject);
var
	i, Nation:		integer;
begin
	Nation := TMenuItem(Sender).Tag;
	Occupant[PopupLoc] := Nation;
	RO.Map[PopupLoc] := RO.Map[PopupLoc] or fUnit;

	if Nation = AIme then
	begin
		RO.Map[PopupLoc] := RO.Map[PopupLoc] or fOwned or fObserved;
		RO.Un[RO.nUn].Loc := PopupLoc;
		RO.Un[RO.nUn].ID := RO.nUn;
		if RO.Map[PopupLoc] and fTerrain<=fShore then
			RO.Un[RO.nUn].mix := 3
		else
		begin
			RO.Un[RO.nUn].mix := 2;
			RO.Map[PopupLoc] := RO.Map[PopupLoc] or fOwnZoCUnit;
		end;
		RO.Un[RO.nUn].Home := 0;
		Inc(RO.nUn)
	end
	else
	begin
		RO.EnemyUn[RO.nEnemyUn].Loc := PopupLoc;
		RO.EnemyUn[RO.nEnemyUn].Owner := Nation;
		if RO.Map[PopupLoc] and fTerrain<=fShore then
			RO.EnemyUn[RO.nEnemyUn].emix := 1
		else
		begin
			RO.EnemyUn[RO.nEnemyUn].emix := 0;
			RO.Map[PopupLoc] := RO.Map[PopupLoc] or fInEnemyZoC;
		end;
		Inc(RO.nEnemyUn)
	end;

	for i := 0 to UserLayers.Count-1 do with TUserLayer(UserLayers.Items[i]) do
		if luUnit in Update then	InitLayerData;

	RepaintMap;
end;

procedure TMainForm.Nation30Click(Sender: TObject);
var
	i, Nation:		integer;
begin
	Nation := TMenuItem(Sender).Tag;
	Occupant[PopupLoc] := Nation;
	RO.Territory[PopupLoc] := Nation;
	RO.Map[PopupLoc] := RO.Map[PopupLoc] or fCity;

	if Nation=AIme then
	begin
		RO.Map[PopupLoc] := RO.Map[PopupLoc] or fOwned or fObserved;
		RO.City[RO.nCity].Loc := PopupLoc;
		RO.City[RO.nCity].ID := RO.nCity;
		Inc(RO.nCity);
	end
	else
	begin
		RO.EnemyCity[RO.nEnemyCity].Loc := PopupLoc;
		RO.EnemyCity[RO.nEnemyCity].ID := RO.nEnemyCity;
		RO.EnemyCity[RO.nEnemyCity].Owner := Nation;
		Inc(RO.nEnemyCity);
	end;

	for i := 0 to UserLayers.Count-1 do with TUserLayer(UserLayers.Items[i]) do
		if luCity in Update then	InitLayerData;

	RepaintMap;
end;

//==============================================================
//			Other events
//==============================================================
procedure TMainForm.SpinEdit1Change(Sender: TObject);
begin
	xwMini := SpinEdit1.Value;
	RepaintMap;
end;

procedure TMainForm.TerrainRBtnClick(Sender: TObject);
begin
	MapIndex := TRadioButton(Sender).Tag;
	RepaintMap;
end;

procedure TMainForm.TerritoryChBoxClick(Sender: TObject);
begin
	if ComboBox1.ItemIndex <= 0 then
		StatusBar1.Panels[6].Text := '';
	RepaintMap;
end;

procedure TMainForm.TownsChBoxClick(Sender: TObject);
begin
	PaintBox1.Invalidate
end;

procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
	if CommandMode = cmMeasure then
	begin
		CommandMode := -1;
		PaintBox1.Cursor := crCross;
	end
end;

procedure TMainForm.MeasureBtnClick(Sender: TObject);
begin
	CommandMode := cmMeasure;
	PaintBox1.Cursor := crTarget;
	Stage := 0;
end;

procedure TMainForm.BreakBtnClick(Sender: TObject);
begin
	bBreak := True;
end;

end.

