program minima_app;

{$mode objfpc}{$H+}

uses
  minima;

var
  app: TMinimaApp;

  function CtrlMain: string;
  begin
    Result := 'Hello. This is main page.';
  end;

  function CtrlUser: string;
  begin
    Result := 'Hello ' + app.RouteVars['name'] + ', ';
    Result := Result + 'Your book ID is ' + app.RouteVars['book_id'] + '. ';

    if app.ReqMethod = 'POST' then
      Result := Result + 'Pssst! This is a POST request.';
  end;

begin
  app := TMinimaApp.Create;
  app.Route('/', ['GET'], @CtrlMain);
  app.Route('/user/<name>/book_id/<book_id>', ['GET', 'POST'], @CtrlUser);
  app.Run;

  app.Cleanup;
end.
