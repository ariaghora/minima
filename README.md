# Minima

A bare minimum CGI web framework for pascal that supports (somewhat `¯\_(ツ)_/¯`) dynamic routing.
It is really minimum and straightforward. No bloat, no unnecessary abstraction.
Define the routes, show what you want to show.
That's it, that's all.

```delphi
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
```
