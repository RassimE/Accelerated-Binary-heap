//	Map Tool for C-Evo
//	Version:		0.01		2005.
//	Author:			Rassim Eminli.

{$INCLUDE switches}
unit MoveAdviceParams;

interface

uses Windows, SysUtils, Messages, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, Spin;

type
  TGetMoveAdviceDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
	Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
	Label4: TLabel;
    woGardens: TCheckBox;
    woMagellan: TCheckBox;
    woShinkansen: TCheckBox;
    AirUnit: TCheckBox;
    FromLoc: TSpinEdit;
    ToLoc: TSpinEdit;
    MP: TSpinEdit;
    Health: TSpinEdit;
    mcNavOver: TCheckBox;
    Label5: TLabel;
    UsedPQ: TComboBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
	SpeedButton3: TSpeedButton;
	procedure FormCreate(Sender: TObject);
	procedure FormShow(Sender: TObject);
	procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
	procedure FormClose(Sender: TObject; var Action: TCloseAction);
	procedure AirUnitClick(Sender: TObject);
	procedure SpeedButton1Click(Sender: TObject);
	procedure SpeedButton2Click(Sender: TObject);
	procedure FromLocChange(Sender: TObject);
	procedure ToLocChange(Sender: TObject);
	procedure OKBtnClick(Sender: TObject);
	procedure CancelBtnClick(Sender: TObject);
  private
	{ Private declarations }
	RetVal:			integer;
	procedure SetFromLoc(Loc: Integer);
  public
	{ Public declarations }
	function ShowDialog: integer;
  end;

var
	GetMoveAdviceDlg: TGetMoveAdviceDlg;

implementation

{$R *.dfm}

uses
	Protocol, CommonUnit, MainUnit;

procedure TGetMoveAdviceDlg.SetFromLoc(Loc: Integer);
var
	Domain:		integer;
begin
	AirUnit.Enabled := Valid(Loc)and(RO.Map[Loc] and fTerrain<>fUNKNOWN);

	if AirUnit.Enabled then
	begin
		if AirUnit.Checked then
			Domain := dAir
		else if RO.Map[Loc] and fTerrain <= fShore then
			Domain := dSea
		else// if RO.Map[Loc] and fTerrain > fShore then
			Domain := dGround
	end
	else	Domain := -1;

	if Domain = dAir then
	begin
		Label4.Enabled := False;
		Health.Enabled := False;

		woGardens.Enabled := False;
		woMagellan.Enabled := False;
		mcNavOver.Enabled := False;
		woShinkansen.Enabled := False;
	end
	else
	begin
		Label4.Enabled := True;
		Health.Enabled := True;
		mcNavOver.Enabled := True;

		if Domain = dSea then
		begin
			woGardens.Enabled := False;
			woShinkansen.Enabled := False;

			woMagellan.Enabled := True;
			mcNavOver.Caption := 'mcNav';
			if MP.Value < 350 then MP.Value := 350
		end
		else //if Domain=dGround then
		begin
			woMagellan.Enabled := False;

			woGardens.Enabled := True;
			woShinkansen.Enabled := True;
			mcNavOver.Caption := 'mcOver';
			if MP.Value>550 then MP.Value := 550
		end;
	end;
end;

function TGetMoveAdviceDlg.ShowDialog: integer;
begin
	RetVal := mrNone;
	Visible := True;
	while RetVal = mrNone do
		Application.ProcessMessages;
	Hide;
	result := RetVal;
end;

//==============================================================
//						Form events
//==============================================================
procedure TGetMoveAdviceDlg.FormCreate(Sender: TObject);
var
	i:		integer;
begin
	MP.MaxValue := 750;
	UsedPQ.Items.Clear;
	for i := 0 to nPQ-1 do
		if Assigned(PQArray[i]) then		UsedPQ.Items.Add(PQArray[i].ClassName)
		else								UsedPQ.Items.Add('nil');

	i := UsedPQ.Items.Count-1;
	while(i>=0)and(UsedPQ.Items.Strings[i]='nil') do
	begin
		UsedPQ.Items.Delete(i);
		dec(i);
	end;

	if UsedPQ.Items.Count>0 then
		UsedPQ.ItemIndex := 0;
end;

procedure TGetMoveAdviceDlg.FormShow(Sender: TObject);
begin
	FromLoc.MinValue := 0;
	FromLoc.MaxValue := MapSize-1;
	if FromLoc.Value > FromLoc.MaxValue then
		FromLoc.Value := FromLoc.MaxValue;

	ToLoc.MinValue := maNextCity;
	ToLoc.MaxValue := MapSize-1;
	if ToLoc.Value > ToLoc.MaxValue then
		ToLoc.Value := ToLoc.MaxValue;
	SetFromLoc(FromLoc.Value);
end;

procedure TGetMoveAdviceDlg.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
	RetVal := mrCancel;
end;

procedure TGetMoveAdviceDlg.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
	Action := caNone;
end;

//==============================================================
//			Other events
//==============================================================
procedure TGetMoveAdviceDlg.AirUnitClick(Sender: TObject);
begin
	if AirUnit.Checked then
	begin
		MP.MaxValue := 1250;
		if MP.Value < 650 then MP.Value := 650;
	end
	else
		MP.MaxValue := 750;
	SetFromLoc(FromLoc.Value);
end;

procedure TGetMoveAdviceDlg.FromLocChange(Sender: TObject);
begin
	SetFromLoc(FromLoc.Value);
	if ToLoc.Value>=0 then
		MainForm.StatusBar1.Panels[6].Text := 'Distance = '+IntTostr(Distance(FromLoc.Value,ToLoc.Value))
	else
		MainForm.StatusBar1.Panels[6].Text := ''
end;

procedure TGetMoveAdviceDlg.ToLocChange(Sender: TObject);
begin
	if ToLoc.Value>=0 then
		MainForm.StatusBar1.Panels[6].Text := 'Distance = '+IntTostr(Distance(FromLoc.Value,ToLoc.Value))
	else
		MainForm.StatusBar1.Panels[6].Text := ''
end;

procedure TGetMoveAdviceDlg.SpeedButton1Click(Sender: TObject);
var
	newLoc:		integer;
begin
	SpeedButton1.Down := True;
	MainForm.SelectLoc(newLoc);
	if newLoc>=0 then
		FromLoc.Value := newLoc;
	SpeedButton3.Down := True;
end;

procedure TGetMoveAdviceDlg.SpeedButton2Click(Sender: TObject);
var
	newLoc:		integer;
begin
	SpeedButton2.Down := True;
	MainForm.SelectLoc(newLoc);
	if newLoc>=0 then
		ToLoc.Value := newLoc;
	SpeedButton3.Down := True;
end;

procedure TGetMoveAdviceDlg.OKBtnClick(Sender: TObject);
begin
	RetVal := mrOk;
end;

procedure TGetMoveAdviceDlg.CancelBtnClick(Sender: TObject);
begin
	RetVal := mrCancel;
end;

end.
