program DelphiCassandraExample;

uses
  Vcl.Forms,
  FMain in 'FMain.pas' {FormMain},
  Grijjy.Cassandra in '..\Grijjy.Cassandra.pas',
  Grijjy.Cassandra.API in '..\Grijjy.Cassandra.API.pas',
  Grijjy.DateUtils in '..\..\GrijjyFoundation\Grijjy.DateUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
