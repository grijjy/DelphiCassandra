unit Grijjy.Cassandra;

{ Delphi classes for Cassandra }

interface

uses
  Grijjy.Cassandra.API;

type
  { forward declarations }
  TgoCassResult = class;

  TgoCassUuidGen = class(TObject)
  private
    FCassUuidGen: CassUuidGen;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function New: CassUuid;
    function AsString(const AUuid: CassUuid): String;
    function FromString(const AUuid: String): CassUuid;
  end;

  TgoCassStatement = class(TObject)
  private
    FCassStatement: CassStatement;
  public
    constructor Create(const AQuery: String; const AParameterCount: Integer = 0);
    destructor Destroy; override;
  public
    function Bind(const AIndex: Integer; const AValue: String): CassError; overload;
    function Bind(const AIndex: Integer; const AValue: Int64): CassError; overload;
    function Bind(const AIndex: Integer; const AValue: CassUuid): CassError; overload;
  public
    property Statement: CassStatement read FCassStatement;
  end;

  TgoCassFuture = class(TObject)
  private
    FCassFuture: CassFuture;
  public
    constructor Create(const ACassFuture: CassFuture);
    destructor Destroy; override;
  public
    property Future: CassFuture read FCassFuture;
  end;

  TgoCassRow = class(TObject)
  private
    FCassRow: CassRow;
  public
    constructor Create(const ACassRow: CassRow);
    destructor Destroy; override;
  public
    function GetUuid(const AColumnByName: String): CassUuid;
    function GetString(const AColumnByName: String): String;
    function GetInt64(const AColumnByName: String): Int64;
  end;

  TgoCassIterator = class(TObject)
  private
    FCassIterator: CassIterator;
  public
    constructor Create(const ACassIterator: CassIterator);
    destructor Destroy; override;
  public
    function Next: Boolean;
    function GetRow: TgoCassRow;
  end;

  TgoCassResult = class(TObject)
  private
    FCassResult: CassResult;
    FQueryFuture: CassFuture;
  public
    constructor Create(const AQueryFuture: TgoCassFuture);
    destructor Destroy; override;
    function Success: Boolean;
  public
    function FirstRow: TgoCassRow;
    function Iterator: TgoCassIterator;
  end;

type
  TgoCassandra = class(TObject)
  protected
    FContactPoints: String;
    FLastErrorCode: Integer;
    FLastErrorDesc: String;
    procedure SetContactPoints(const AValue: String);
  private
    FCassCluster: CassCluster;
    FCassSession: CassSession;
    FConnectFuture: CassFuture;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function Connect: Boolean;
    function Execute(const AStatement: TgoCassStatement): Boolean; overload;
    function Execute(const AStatement: TgoCassStatement; out AQueryFuture: TgoCassFuture): Boolean; overload;
  public
    property ContactPoints: String read FContactPoints write SetContactPoints;
    property LastErrorCode: Integer read FLastErrorCode;
    property LastErrorDesc: String read FLastErrorDesc;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

{ TgoCassUuidGen }

constructor TgoCassUuidGen.Create;
begin
  FCassUuidGen := cass_uuid_gen_new;
end;

destructor TgoCassUuidGen.Destroy;
begin
  cass_uuid_gen_free(FCassUuidGen);
  inherited;
end;

function TgoCassUuidGen.New: CassUuid;
begin
  cass_uuid_gen_random(FCassUuidGen, @Result);
end;

function TgoCassUuidGen.AsString(const AUuid: CassUuid): String;
var
  P: array[0..CASS_UUID_STRING_LENGTH - 1] of AnsiChar;
begin
  cass_uuid_string(AUuid, P);
  Result := String(P);
end;

function TgoCassUuidGen.FromString(const AUuid: String): CassUuid;
begin
  cass_uuid_from_string(MarshaledAString(TMarshal.AsAnsi(AUuid)), @Result);
end;

{ TgoCassStatement }

constructor TgoCassStatement.Create(const AQuery: String; const AParameterCount: Integer);
begin
  FCassStatement := cass_statement_new(MarshaledAString(TMarshal.AsAnsi(AQuery)), AParameterCount);
end;

destructor TgoCassStatement.Destroy;
begin
  cass_statement_free(FCassStatement);
  inherited;
end;

function TgoCassStatement.Bind(const AIndex: Integer; const AValue: String): CassError;
begin
  Result := cass_statement_bind_string(FCassStatement, AIndex, MarshaledAString(TMarshal.AsAnsi(AValue)));
end;

function TgoCassStatement.Bind(const AIndex: Integer; const AValue: Int64): CassError;
begin
  Result := cass_statement_bind_int64(FCassStatement, AIndex, AValue);
end;

function TgoCassStatement.Bind(const AIndex: Integer; const AValue: CassUuid): CassError;
begin
  Result := cass_statement_bind_uuid(FCassStatement, AIndex, AValue);
end;

{ TgoCassFuture }

constructor TgoCassFuture.Create(const ACassFuture: CassFuture);
begin
  FCassFuture := ACassFuture;
end;

destructor TgoCassFuture.Destroy;
begin
  cass_future_free(FCassFuture);
  inherited;
end;

{ TgoCassRow }

constructor TgoCassRow.Create(const ACassRow: CassRow);
begin
  FCassRow := ACassRow;
end;

destructor TgoCassRow.Destroy;
begin
  inherited;
end;

function TgoCassRow.GetUuid(const AColumnByName: String): CassUuid;
var
  Column: CassValue;
begin
  Column := cass_row_get_column_by_name(FCassRow, MarshaledAString(TMarshal.AsAnsi(AColumnByName)));
  if Column <> nil then
    cass_value_get_uuid(Column, @Result);
end;

function TgoCassRow.GetString(const AColumnByName: String): String;
var
  Column: CassValue;
  P: PAnsiChar;
  Len: size_t;
begin
  Column := cass_row_get_column_by_name(FCassRow, MarshaledAString(TMarshal.AsAnsi(AColumnByName)));
  if Column <> nil then
  begin
    cass_value_get_string(Column, @P, @Len);
    Result := String(P);
  end
  else
    Result := '';
end;

function TgoCassRow.GetInt64(const AColumnByName: String): Int64;
var
  Column: CassValue;
begin
  Column := cass_row_get_column_by_name(FCassRow, MarshaledAString(TMarshal.AsAnsi(AColumnByName)));
  if Column <> nil then
    cass_value_get_int64(Column, @Result)
  else
    Result := 0;
end;

{ TgoCassIterator }

constructor TgoCassIterator.Create(const ACassIterator: CassIterator);
begin
  FCassIterator := ACassIterator;
end;

destructor TgoCassIterator.Destroy;
begin
  cass_iterator_free(FCassIterator);
  inherited;
end;

function TgoCassIterator.Next: Boolean;
begin
  Result := cass_iterator_next(FCassIterator);
end;

function TgoCassIterator.GetRow: TgoCassRow;
var
  ACassRow: CassRow;
begin
  ACassRow := cass_iterator_get_row(FCassIterator);
  Result := TgoCassRow.Create(ACassRow);
end;

{ TgoCassResult }

constructor TgoCassResult.Create(const AQueryFuture: TgoCassFuture);
begin
  FQueryFuture := AQueryFuture;
  FCassResult := cass_future_get_result(AQueryFuture.Future);
end;

destructor TgoCassResult.Destroy;
begin
  cass_result_free(FCassResult);
  inherited;
end;

function TgoCassResult.Success: Boolean;
begin
  Result := FCassResult <> nil;
end;

function TgoCassResult.FirstRow: TgoCassRow;
var
  ACassRow: CassRow;
begin
  ACassRow := cass_result_first_row(FCassResult);
  Result := TgoCassRow.Create(ACassRow);
end;

function TgoCassResult.Iterator: TgoCassIterator;
var
  ACassIterator: CassIterator;
begin
  ACassIterator := cass_iterator_from_result(FCassResult);
  Result := TgoCassIterator.Create(ACassIterator);
end;

{ TgoCassandra }

constructor TgoCassandra.Create;
begin
  FCassCluster := cass_cluster_new;
  FCassSession := cass_session_new;
end;

destructor TgoCassandra.Destroy;
begin
  if FConnectFuture <> nil then
    cass_future_free(FConnectFuture);
  cass_session_free(FCassSession);
  cass_cluster_free(FCassCluster);
  inherited;
end;

procedure TgoCassandra.SetContactPoints(const AValue: String);
begin
  cass_cluster_set_contact_points(FCassCluster, MarshaledAString(TMarshal.AsAnsi(AValue)));
end;

function TgoCassandra.Connect: Boolean;
begin
  { Provide the cluster object as configuration to connect the session }
  FConnectFuture := cass_session_connect(FCassSession, FCassCluster);

  { This operation will block until the result is ready }
  FLastErrorCode := cass_future_error_code(FConnectFuture);
  FLastErrorDesc := String(cass_error_desc(FLastErrorCode));
  Result := FLastErrorCode = CASS_OK;
end;

function TgoCassandra.Execute(const AStatement: TgoCassStatement): Boolean;
var
  QueryFuture: CassFuture;
begin
  QueryFuture := cass_session_execute(FCassSession, AStatement.Statement);
  try
    { This will block until the query has finished }
    FLastErrorCode :=  cass_future_error_code(QueryFuture);
    FLastErrorDesc := String(cass_error_desc(FLastErrorCode));
  finally
    cass_future_free(QueryFuture);
  end;
  Result := FLastErrorCode = CASS_OK;
end;

function TgoCassandra.Execute(const AStatement: TgoCassStatement; out AQueryFuture: TgoCassFuture): Boolean;
var
  QueryFuture: CassFuture;
begin
  QueryFuture := cass_session_execute(FCassSession, AStatement.Statement);

  { This will block until the query has finished }
  FLastErrorCode :=  cass_future_error_code(QueryFuture);
  FLastErrorDesc := String(cass_error_desc(FLastErrorCode));
  if FLastErrorCode = CASS_OK then
  begin
    AQueryFuture := TgoCassFuture.Create(QueryFuture);
    Result := True;
  end
  else
  begin
    cass_future_free(QueryFuture);
    Result := False;
  end;
end;

end.