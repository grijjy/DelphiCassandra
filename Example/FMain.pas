unit FMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Grijjy.DateUtils,
  Grijjy.Cassandra;

type
  TFormMain = class(TForm)
    ButtonConnect: TButton;
    ButtonCreateKeySpace: TButton;
    ButtonCreateTable: TButton;
    ButtonInsert: TButton;
    ButtonQueryOneRow: TButton;
    EditContactPoints: TEdit;
    LabelContactPoints: TLabel;
    MemoLog: TMemo;
    ButtonQueryAllRows: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonConnectClick(Sender: TObject);
    procedure ButtonCreateKeySpaceClick(Sender: TObject);
    procedure ButtonCreateTableClick(Sender: TObject);
    procedure ButtonInsertClick(Sender: TObject);
    procedure ButtonQueryOneRowClick(Sender: TObject);
    procedure ButtonQueryAllRowsClick(Sender: TObject);
  private
    { Private declarations }
    FCassandra: TgoCassandra;
    FCassUuidGen: TgoCassUuidGen;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.DateUtils;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FCassandra := TgoCassandra.Create;
  FCassUuidGen := TgoCassUuidGen.Create;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FCassUuidGen.Free;
  FCassandra.Free;
end;

procedure TFormMain.ButtonConnectClick(Sender: TObject);
begin
  FCassandra.ContactPoints := EditContactPoints.Text;
  if FCassandra.Connect then
  begin
    MemoLog.Lines.Add('Connected!');
  end
  else
    MemoLog.Lines.Add('Connect Failure = ' + FCassandra.LastErrorDesc);
end;

procedure TFormMain.ButtonCreateKeyspaceClick(Sender: TObject);
var
  Statement: TgoCassStatement;
begin
  Statement := TgoCassStatement.Create(
    'CREATE KEYSPACE keyspace_test WITH REPLICATION = { ''class'' : ''SimpleStrategy'', ''replication_factor'' : 1 };');
  try
    if FCassandra.Execute(Statement) then
    begin
      MemoLog.Lines.Add('Keyspace Created!');
    end
    else
      MemoLog.Lines.Add('Error = ' + FCassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;

procedure TFormMain.ButtonCreateTableClick(Sender: TObject);
var
  Statement: TgoCassStatement;
begin
  Statement := TgoCassStatement.Create(
    'CREATE TABLE keyspace_test.table_test (' +
        'user_id uuid,' +
        'from_user text,' +
        'time timestamp,' +
        'PRIMARY KEY (from_user, time)' +
    ')' +
    ' WITH CLUSTERING ORDER BY (time ASC);');
  try
    if FCassandra.Execute(Statement) then
    begin
      MemoLog.Lines.Add('Table Created!');
    end
    else
      MemoLog.Lines.Add('Error = ' + FCassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;

procedure TFormMain.ButtonInsertClick(Sender: TObject);
var
  Statement: TgoCassStatement;
begin
  Statement := TgoCassStatement.Create('INSERT INTO keyspace_test.table_test (user_id, from_user, time) VALUES (?, ?, ?);', 3);
  try
    Statement.Bind(0, FCassUuidGen.New);
    Statement.Bind(1, 'user4');
    Statement.Bind(2, goDateTimeToMillisecondsSinceEpoch(TTimeZone.Local.ToUniversalTime(Now), True));
    if FCassandra.Execute(Statement) then
    begin
      MemoLog.Lines.Add('Insert Success!');

    end
    else
      MemoLog.Lines.Add('Insert Failure = ' + FCassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;

procedure TFormMain.ButtonQueryOneRowClick(Sender: TObject);
var
  Statement: TgoCassStatement;
  QueryFuture: TgoCassFuture;
  CassResult: TgoCassResult;
  Row: TgoCassRow;
begin
  Statement := TgoCassStatement.Create('SELECT * FROM keyspace_test.table_test WHERE from_user = ''user4'';');
  try
    if FCassandra.Execute(Statement, QueryFuture) then
    begin
      MemoLog.Lines.Add('Query Success!');
      CassResult := TgoCassResult.Create(QueryFuture);
      try
        if CassResult.Success then
        begin
          Row := CassResult.FirstRow;
          if Row <> nil then
          begin
            MemoLog.Lines.Add('user_id = ' + FCassUuidGen.AsString(Row.GetUuid('user_id')));
            MemoLog.Lines.Add('from_user = ' + Row.GetString('from_user'));
            MemoLog.Lines.Add('time = ' + Row.GetInt64('time').ToString);
          end;
        end;
      finally
        CassResult.Free;
      end;
    end
    else
      MemoLog.Lines.Add('Query Failure = ' + FCassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;

procedure TFormMain.ButtonQueryAllRowsClick(Sender: TObject);
var
  Statement: TgoCassStatement;
  QueryFuture: TgoCassFuture;
  CassResult: TgoCassResult;
  Row: TgoCassRow;
  Iterator: TgoCassIterator;
begin
  Statement := TgoCassStatement.Create('SELECT * FROM keyspace_test.table_test;');
  try
    if FCassandra.Execute(Statement, QueryFuture) then
    begin
      MemoLog.Lines.Add('Query Success!');
      CassResult := TgoCassResult.Create(QueryFuture);
      try
        if CassResult.Success then
        begin
          Iterator := CassResult.Iterator;
          while Iterator.Next do
          begin
            Row := Iterator.GetRow;
            MemoLog.Lines.Add('user_id = ' + FCassUuidGen.AsString(Row.GetUuid('user_id')));
            MemoLog.Lines.Add('from_user = ' + Row.GetString('from_user'));
            MemoLog.Lines.Add('time = ' + Row.GetInt64('time').ToString);
          end;
        end;
      finally
        CassResult.Free;
      end;
    end
    else
      MemoLog.Lines.Add('Query Failure = ' + FCassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;

end.
