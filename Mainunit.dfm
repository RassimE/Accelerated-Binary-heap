object MainForm: TMainForm
  Left = 269
  Top = 139
  Width = 872
  Height = 482
  Caption = 'Map tool for C-Evo v0.1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object MiniImg: TImage
    Left = 133
    Top = 41
    Width = 731
    Height = 376
    Cursor = crCross
    Align = alClient
    Stretch = True
  end
  object PaintBox1: TPaintBox
    Left = 133
    Top = 41
    Width = 731
    Height = 376
    Cursor = crCross
    Align = alClient
    PopupMenu = PopupMenu1
    OnClick = PaintBox1Click
    OnMouseMove = PaintBox1MouseMove
    OnMouseUp = PaintBox1MouseUp
    OnPaint = PaintBox1Paint
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 417
    Width = 864
    Height = 19
    Panels = <
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 150
      end
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
    SimplePanel = False
  end
  object Panel1: TPanel
    Left = 0
    Top = 41
    Width = 133
    Height = 376
    Align = alLeft
    Enabled = False
    TabOrder = 1
    object Label1: TLabel
      Left = 11
      Top = 231
      Width = 113
      Height = 33
      AutoSize = False
      Caption = '---'
      WordWrap = True
    end
    object Label2: TLabel
      Left = 11
      Top = 271
      Width = 113
      Height = 33
      AutoSize = False
      Caption = '---'
      WordWrap = True
    end
    object Label5: TLabel
      Left = 11
      Top = 314
      Width = 9
      Height = 13
      Caption = '---'
    end
    object Label6: TLabel
      Left = 16
      Top = 152
      Width = 97
      Height = 13
      Caption = 'User Defined Layer :'
    end
    object TerrainRBtn: TRadioButton
      Left = 10
      Top = 9
      Width = 68
      Height = 17
      Caption = 'Terrain'
      Checked = True
      PopupMenu = PopupMenu1
      TabOrder = 0
      TabStop = True
      OnClick = TerrainRBtnClick
      OnDblClick = Legend1Click
    end
    object FormationsRBtn: TRadioButton
      Tag = 1
      Left = 11
      Top = 33
      Width = 73
      Height = 17
      Caption = 'Formations'
      PopupMenu = PopupMenu1
      TabOrder = 1
      OnClick = TerrainRBtnClick
      OnDblClick = Legend1Click
    end
    object BreakBtn: TButton
      Left = 15
      Top = 199
      Width = 75
      Height = 25
      Caption = 'Break'
      TabOrder = 2
      Visible = False
      OnClick = BreakBtnClick
    end
    object UnitsChBox: TCheckBox
      Left = 28
      Top = 82
      Width = 81
      Height = 17
      Caption = 'Units'
      TabOrder = 3
      OnClick = TownsChBoxClick
    end
    object TownsChBox: TCheckBox
      Left = 28
      Top = 107
      Width = 81
      Height = 17
      Caption = 'Towns'
      TabOrder = 4
      OnClick = TownsChBoxClick
    end
    object TerritoryChBox: TCheckBox
      Left = 28
      Top = 58
      Width = 81
      Height = 17
      Caption = 'Territory'
      PopupMenu = PopupMenu1
      TabOrder = 5
      OnClick = TerritoryChBoxClick
    end
    object RoadsChBox: TCheckBox
      Left = 28
      Top = 132
      Width = 81
      Height = 17
      Caption = 'Roads'
      TabOrder = 6
      OnClick = TownsChBoxClick
    end
    object ComboBox1: TComboBox
      Left = 24
      Top = 168
      Width = 73
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 7
      Text = 'NONE'
      OnChange = TerritoryChBoxClick
      OnDblClick = Legend1Click
      Items.Strings = (
        'NONE')
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 864
    Height = 41
    Align = alTop
    Enabled = False
    TabOrder = 2
    object Label9: TLabel
      Left = 9
      Top = 13
      Width = 22
      Height = 13
      Caption = 'Pan:'
    end
    object MeasureBtn: TSpeedButton
      Left = 137
      Top = 8
      Width = 25
      Height = 25
      Hint = 'Measure tool'
      GroupIndex = 1
      Enabled = False
      Flat = True
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
        DDDDDDDDDDD0DDDDDDDDDDDDDDD0DDDDDDDDDDDDDD000DDDDDDDDDDD00D0D00D
        DDDDDDD0DDD0DDD0DDDDDDD0DDD0DDD0DDDDDD0DDD0D0DDD0DDD000000DDD000
        000DDD0DDD0D0DDD0DDDDDD0DDD0DDD0DDDDDDD0DDD0DDD0DDDDDDDD00D0D00D
        DDDDDDDDDD000DDDDDDDDDDDDDD0DDDDDDDDDDDDDDD0DDDDDDDD}
      ParentShowHint = False
      ShowHint = True
      OnClick = MeasureBtnClick
    end
    object SpeedButton1: TSpeedButton
      Left = 112
      Top = 8
      Width = 25
      Height = 25
      GroupIndex = 1
      Down = True
      Flat = True
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDD0F00D
        DDDDDDDDDDD0FF0DDDDDDD0DDD0FFF0DDDDDDD00DD0FF0DDDDDDDD0F00FFF0DD
        DDDDDD0FFFFF0DDDDDDDDD0FFFFFF000DDDDDD0FFFFFFF0DDDDDDD0FFFFFF0DD
        DDDDDD0FFFFF0DDDDDDDDD0FFFF0DDDDDDDDDD0FFF0DDDDDDDDDDD0FF0DDDDDD
        DDDDDD0F0DDDDDDDDDDDDD00DDDDDDDDDDDDDD0DDDDDDDDDDDDD}
      OnClick = SpeedButton1Click
    end
    object Label3: TLabel
      Left = 211
      Top = 12
      Width = 9
      Height = 13
      Caption = '---'
    end
    object Label4: TLabel
      Left = 295
      Top = 12
      Width = 9
      Height = 13
      Caption = '---'
    end
    object SpinEdit1: TSpinEdit
      Left = 37
      Top = 8
      Width = 49
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 0
      Value = 0
      OnChange = SpinEdit1Change
    end
  end
  object MainMenu1: TMainMenu
    Left = 488
    Top = 8
    object File1: TMenuItem
      Caption = '&File'
      object Open1: TMenuItem
        Caption = '&Open'
        OnClick = Open1Click
      end
      object Saveasbmp1: TMenuItem
        Caption = 'Save as &bmp...'
        Enabled = False
        OnClick = Saveasbmp1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'E&xit'
        OnClick = Exit1Click
      end
    end
    object Map1: TMenuItem
      Caption = '&Map'
      Enabled = False
      object Info1: TMenuItem
        Caption = '&Info'
        object Brief1: TMenuItem
          Caption = '&Brief...'
          OnClick = Brief1Click
        end
        object Detail1: TMenuItem
          Caption = '&Detail...'
          OnClick = Detail1Click
        end
      end
      object Legend1: TMenuItem
        Caption = '&Legend...'
        OnClick = Legend1Click
      end
    end
    object Benchmark1: TMenuItem
      Caption = '&Benchmark'
      Enabled = False
      object AverageTime1: TMenuItem
        Caption = 'Average Time'
        Checked = True
        RadioItem = True
        OnClick = BestTime1Click
      end
      object BestTime1: TMenuItem
        Caption = 'Best Time'
        RadioItem = True
        OnClick = BestTime1Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object FindFormations1: TMenuItem
        Caption = 'Find Formations Test 1'
        OnClick = FindFormations1Click
      end
      object FindFormations2: TMenuItem
        Caption = 'Find Formations Test 2'
        OnClick = FindFormations2Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object GetMoveAdvice1: TMenuItem
        Caption = 'GetMoveAdvice - Dijkstra'
        OnClick = GetMoveAdvice1Click
      end
      object GetMoveAdvice2: TMenuItem
        Caption = 'GetMoveAdvice - A*'
        OnClick = GetMoveAdvice2Click
      end
      object Imitator1: TMenuItem
        Caption = 'Imitator'
        OnClick = Imitator1Click
      end
      object N3: TMenuItem
        Caption = '-'
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object About1: TMenuItem
        Caption = 'About...'
        OnClick = About1Click
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 
      'C-Evo Map Files (*.cevo map)|*.cevo map|Map data Files (*.dat)|*' +
      '.dat|All Files (*.*)|*.*'
    Left = 545
    Top = 8
  end
  object SavePictureDialog1: TSavePictureDialog
    DefaultExt = 'bmp'
    Filter = 'Bitmaps (*.bmp)|*.bmp'
    Left = 516
    Top = 8
  end
  object PopupMenu1: TPopupMenu
    AutoPopup = False
    Left = 192
    Top = 144
    object Legend2: TMenuItem
      Caption = '&Legend...'
      OnClick = Legend1Click
    end
    object CreateUnit1: TMenuItem
      Caption = 'Create Unit'
      object Nation1: TMenuItem
        Caption = 'Nation 1'
        OnClick = Nation15Click
      end
      object Nation2: TMenuItem
        Tag = 1
        Caption = 'Nation 2'
        OnClick = Nation15Click
      end
      object Nation3: TMenuItem
        Tag = 2
        Caption = 'Nation 3'
        OnClick = Nation15Click
      end
      object Nation4: TMenuItem
        Tag = 3
        Caption = 'Nation 4'
        OnClick = Nation15Click
      end
      object Nation5: TMenuItem
        Tag = 4
        Caption = 'Nation 5'
        OnClick = Nation15Click
      end
      object Nation6: TMenuItem
        Tag = 5
        Caption = 'Nation 6'
        OnClick = Nation15Click
      end
      object Nation7: TMenuItem
        Tag = 6
        Caption = 'Nation 7'
        OnClick = Nation15Click
      end
      object Nation8: TMenuItem
        Tag = 7
        Caption = 'Nation 8'
        OnClick = Nation15Click
      end
      object Nation9: TMenuItem
        Tag = 8
        Caption = 'Nation 9'
        OnClick = Nation15Click
      end
      object Nation10: TMenuItem
        Tag = 9
        Caption = 'Nation 10'
        OnClick = Nation15Click
      end
      object Nation11: TMenuItem
        Tag = 10
        Caption = 'Nation 11'
        OnClick = Nation15Click
      end
      object Nation12: TMenuItem
        Tag = 11
        Caption = 'Nation 12'
        OnClick = Nation15Click
      end
      object Nation13: TMenuItem
        Tag = 12
        Caption = 'Nation 13'
        OnClick = Nation15Click
      end
      object Nation14: TMenuItem
        Tag = 13
        Caption = 'Nation 14'
        OnClick = Nation15Click
      end
      object Nation15: TMenuItem
        Tag = 14
        Caption = 'Nation 15'
        OnClick = Nation15Click
      end
    end
    object CreateCity1: TMenuItem
      Caption = 'Create City'
      object Nation16: TMenuItem
        Caption = 'Nation 1'
        OnClick = Nation30Click
      end
      object Nation17: TMenuItem
        Tag = 1
        Caption = 'Nation 2'
        OnClick = Nation30Click
      end
      object Nation18: TMenuItem
        Tag = 2
        Caption = 'Nation 3'
        OnClick = Nation30Click
      end
      object Nation19: TMenuItem
        Tag = 3
        Caption = 'Nation 4'
        OnClick = Nation30Click
      end
      object Nation20: TMenuItem
        Tag = 4
        Caption = 'Nation 5'
        OnClick = Nation30Click
      end
      object Nation21: TMenuItem
        Tag = 5
        Caption = 'Nation 6'
        OnClick = Nation30Click
      end
      object Nation22: TMenuItem
        Tag = 6
        Caption = 'Nation 7'
        OnClick = Nation30Click
      end
      object Nation23: TMenuItem
        Tag = 7
        Caption = 'Nation 8'
        OnClick = Nation30Click
      end
      object Nation24: TMenuItem
        Tag = 8
        Caption = 'Nation 9'
        OnClick = Nation30Click
      end
      object Nation25: TMenuItem
        Tag = 9
        Caption = 'Nation 10'
        OnClick = Nation30Click
      end
      object Nation26: TMenuItem
        Tag = 10
        Caption = 'Nation 11'
        OnClick = Nation30Click
      end
      object Nation27: TMenuItem
        Tag = 11
        Caption = 'Nation 12'
        OnClick = Nation30Click
      end
      object Nation28: TMenuItem
        Tag = 12
        Caption = 'Nation 13'
        OnClick = Nation30Click
      end
      object Nation29: TMenuItem
        Tag = 13
        Caption = 'Nation 14'
        OnClick = Nation30Click
      end
      object Nation30: TMenuItem
        Tag = 14
        Caption = 'Nation 15'
        OnClick = Nation30Click
      end
    end
  end
end
