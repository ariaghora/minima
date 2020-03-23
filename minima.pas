unit minima;

{$mode objfpc}{$H+}

interface

uses
  Classes, RegExpr, SysUtils, fgl;

type

  TRequestHandlerFunc = function: string;
  TRouteVarMap = specialize TFPGMap<string, string>;

  { TMinimaApp }

  TMinimaApp = class
    fContentType: string;
    fRequestData: string;
    fErr404Handler: TRequestHandlerFunc;
    fErr500Handler: TRequestHandlerFunc;
    fErrorMessage: string;
  public
    constructor Create;
    function GetCurrentMethod: string;
    function GetCurrentRoute: string;
    function GetRouteVars(RouteVar: string): string;
    procedure Cleanup;
    procedure Run;
    procedure Route(ARoute: string; AMethods: array of string;
      ARequestHandlerFunc: TRequestHandlerFunc);
    property ContentType: string read fContentType;
    property Err404Handler: TRequestHandlerFunc read fErr404Handler write fErr404Handler;
    property Err500Handler: TRequestHandlerFunc read fErr500Handler write fErr500Handler;
    property ReqMethod: string read GetCurrentMethod;
    property RouteVars[RouteVar: string]: string read GetRouteVars;
  private
    NumMatchingRoutes: integer;
    RequestHandlerFuncCandidate: TRequestHandlerFunc;
    RouteVarMap: TRouteVarMap;
    function RouteToPattern(ARoute: string): string;
    function RoutePatternMatches(CurrentRoute: string; DefinedRoute: string): boolean;
  end;

  function Default404Handler: string;
  function Default500Handler: string;


implementation

operator in(str: string; strarr: array of string): boolean;
var
  s: string;
begin
  Result := False;
  for s in strarr do
  begin
    Result := s = str;
    if Result then Break;
  end;
end;

function Default404Handler: string;
begin
  Result := '404 error';
end;

function Default500Handler: string;
begin
  Result := '500 error';
end;

procedure TMinimaApp.Run;
begin
  if self.NumMatchingRoutes = 1 then
  begin
    WriteLn(Format('Content-Type: %s', [self.ContentType]), sLineBreak);
    WriteLn(self.RequestHandlerFuncCandidate);
  end
  else if self.NumMatchingRoutes > 1 then
  begin
    WriteLn(Format('Content-Type: %s', [self.ContentType]), sLineBreak);
    WriteLn('Error 500: There are duplicate or ambiguous routes.');
  end
  else
  begin
    WriteLn(Format('Content-Type: %s', [self.ContentType]), sLineBreak);
    WriteLn(self.Err404Handler);
  end;
end;

procedure TMinimaApp.Route(ARoute: string; AMethods: array of string;
  ARequestHandlerFunc: TRequestHandlerFunc);
var
  s, CurrentRoute, CurrentMethod, RoutePattern, key, val: string;
  c: char;
  ARouteSplit, CurrentRouteSplit: TStringArray;
  i: integer;
begin
  CurrentMethod := GetCurrentMethod();
  CurrentRoute  := GetCurrentRoute();
  RoutePattern  := RouteToPattern(ARoute);

  { Blank route equals to '/' route. }
  if CurrentRoute = '' then CurrentRoute := '/';

  if (RoutePatternMatches(CurrentRoute, RoutePattern)) and
    (CurrentMethod in AMethods) then
  begin
    if CurrentMethod = 'GET' then
      { if GET, the request data is the query string itself }
      fRequestData := GetEnvironmentVariable('QUERY_STRING')
    else
      { otherwise, the request data comes from STDIN }
      while not EOF(Input) do
      begin
        Read(c);
        fRequestData := fRequestData + c;
      end;

    { Parse route variables }
    i := 0;
    ARouteSplit := ARoute.Split('/');
    CurrentRouteSplit := CurrentRoute.Split('/');
    for s in ARouteSplit do
    begin
      if s.StartsWith('<') and s.EndsWith('>') then
      begin
        key := s.Replace('<', '').Replace('>', '').Trim;
        val := CurrentRouteSplit[i];
        self.RouteVarMap.Add(key, val);
      end;
      Inc(i);
    end;

    { then print the output }
    Inc(self.NumMatchingRoutes);
    self.RequestHandlerFuncCandidate := ARequestHandlerFunc;
  end;
end;

constructor TMinimaApp.Create;
begin
  fContentType := 'text/html';
  self.Err404Handler := @Default404Handler;
  self.Err500Handler := @Default500Handler;
  self.NumMatchingRoutes := 0;
  self.RouteVarMap := TRouteVarMap.Create;
end;

function TMinimaApp.GetRouteVars(RouteVar: string): string;
begin
  Result := '';
  RouteVarMap.TryGetData(RouteVar, Result);
end;

procedure TMinimaApp.Cleanup;
begin
  FreeAndNil(self.fErr404Handler);
  FreeAndNil(self.fErr500Handler);
  FreeAndNil(self.RouteVarMap);
end;

function TMinimaApp.RouteToPattern(ARoute: string): string;
begin
  Result := Format('^(%s)(\?[a-zA-Z0-9]+=[a-zA-Z0-9]+)?$', [ARoute]);
  Result := ReplaceRegExpr('<[a-zA-Z0-9_]+>', Result, '[a-zA-Z0-9_]+', True);
end;

function TMinimaApp.RoutePatternMatches(CurrentRoute: string;
  DefinedRoute: string): boolean;
var
  regexobj: TRegExpr;
  RoutePattern: string;
begin
  RoutePattern := RouteToPattern(DefinedRoute);
  regexobj := TRegExpr.Create(RoutePattern);
  Result := regexobj.Exec(CurrentRoute);
  regexobj.Free;
end;

function TMinimaApp.GetCurrentMethod: string;
begin
  Result := GetEnvironmentVariable('REQUEST_METHOD');
end;

function TMinimaApp.GetCurrentRoute: string;
var
  uri, ScriptName: string;
begin
  uri   := GetEnvironmentVariable('REQUEST_URI');
  ScriptName := GetEnvironmentVariable('SCRIPT_NAME');
  Result := Copy(uri, Length(ScriptName) + 1, Length(uri) - Length(ScriptName));
  if Pos('?', Result) > 0 then
     Result := Copy(Result, 0, Pos('?', Result) - 1);
  exit(Result);
end;

end.
