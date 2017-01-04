object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'FormMain'
  ClientHeight = 295
  ClientWidth = 490
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object LabelContactPoints: TLabel
    Left = 32
    Top = 16
    Width = 74
    Height = 13
    Caption = 'Contact Points:'
  end
  object ButtonConnect: TButton
    Left = 192
    Top = 33
    Width = 137
    Height = 25
    Caption = 'ButtonConnect'
    TabOrder = 0
    OnClick = ButtonConnectClick
  end
  object ButtonCreateKeySpace: TButton
    Left = 32
    Top = 80
    Width = 137
    Height = 25
    Caption = 'ButtonCreateKeySpace'
    TabOrder = 1
    OnClick = ButtonCreateKeySpaceClick
  end
  object ButtonCreateTable: TButton
    Left = 32
    Top = 120
    Width = 137
    Height = 25
    Caption = 'ButtonCreateTable'
    TabOrder = 2
    OnClick = ButtonCreateTableClick
  end
  object ButtonInsert: TButton
    Left = 32
    Top = 159
    Width = 137
    Height = 25
    Caption = 'ButtonInsert'
    TabOrder = 3
    OnClick = ButtonInsertClick
  end
  object ButtonQueryOneRow: TButton
    Left = 32
    Top = 200
    Width = 137
    Height = 25
    Caption = 'ButtonQueryOneRow'
    TabOrder = 4
    OnClick = ButtonQueryOneRowClick
  end
  object EditContactPoints: TEdit
    Left = 32
    Top = 35
    Width = 137
    Height = 21
    TabOrder = 5
    Text = '192.168.1.83'
  end
  object MemoLog: TMemo
    Left = 192
    Top = 82
    Width = 265
    Height = 183
    TabOrder = 6
  end
  object ButtonQueryAllRows: TButton
    Left = 32
    Top = 240
    Width = 137
    Height = 25
    Caption = 'ButtonQueryAllRows'
    TabOrder = 7
    OnClick = ButtonQueryAllRowsClick
  end
end
