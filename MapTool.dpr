program MapTool;

uses
  Forms,
  MainUnit in 'Mainunit.pas' {MainForm},
  MoveAdviceParams in 'MoveAdviceParams.pas' {GetMoveAdviceDlg},
  LegendEditorUnit in 'LegendEditorUnit.pas' {LegendEditorDlg},
  AboutDlgUnit in 'AboutDlgUnit.pas' {AboutBox},
  GetMoveAdviceUnit in 'GetMoveAdviceUnit.pas',
  NewFindFormationsUnit in 'NewFindFormationsUnit.pas',
  OldFindFormationsUnit in 'OldFindFormationsUnit.pas',
  PQUnit in 'PQUnit.pas',
  OpenListUnit in 'OpenListUnit.pas',
  CommonUnit in 'CommonUnit.pas',
  UserLayerUnit in 'UserLayerUnit.pas',
  ExampleLayer in 'ExampleLayer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Map tool for C-Evo';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TGetMoveAdviceDlg, GetMoveAdviceDlg);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TLegendEditorDlg, LegendEditorDlg);
  Application.Run;
end.
