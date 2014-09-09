{
  gitprompt: Git prompt utility
  Author: Jerry Jian (emisjerry@gmail.com)

  v0.01 2014/09/02: Initial version
  v0.02 2014/09/03: Add different color for branch status
  v0.03 2014/09/04: Get root folder to read HEAD file properly
  v0.04 2014/09/09: Add version entry to ini for recreating it
  v0.05 2014/09/09: Fix not git folder error
}
program gitprompt;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp, Windows, IniFiles, Dos, Process
  { you can add units after this };

type

  { TMyApplication }
  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

  const
    _DEBUG: Boolean = true;
    _VERSION:String = '0.05 2014/09/09';

{ TMyApplication }

function help(): Boolean;
begin
  writeln('gitprompt - Git info utility v' + _VERSION + ' [written by Jerry Jian (emisjerry@gmail.com)]');
  writeln('');
  writeln('Output the new prompt command based on git-prompt.ini.');
  writeln('');
  writeln('Color schemes for branch name in prompt:');
  writeln('  Cyan: local up-to-date with the remote');
  writeln('  Red:  local behind with the remote');
  writeln('  yellow: local non-sync with the remote');
  writeln('  Green: local changes');
  Result := true;
end;

function getHEADFile(): String;
var
  _sResult, s: String;
begin
  _sResult := '.git/HEAD';
  // git rev-parse --show-toplevel will get the root folder
  if (RunCommand('git', ['rev-parse', '--show-toplevel'], s)) then begin
    s := Copy(s, 1, Length(s)-1);  // remove the last #10
    _sResult := s + '/' + _sResult;
  end;
  Result := _sResult;
end;

{ URL: http://ascii-table.com/ansi-escape-sequences.php
Esc[Value;...;Valuem

Text attributes
0	All attributes off
1	Bold on
4	Underscore (on monochrome display adapter only)
5	Blink on
7	Reverse video on
8	Concealed on

Foreground colors
30	Black
31	Red
32	Green
33	Yellow
34	Blue
35	Magenta
36	Cyan
37	White

Background colors
40	Black
41	Red
42	Green
43	Yellow
44	Blue
45	Magenta
46	Cyan
47	White
}
function getEscapeColor(sColor: String; sType: String): String;
var _iPos: Integer;
  _sColor: String;
  _sBold, _sType: String;
begin
  sColor := LowerCase(sColor);
  _iPos := Pos(' ', sColor);
  _sBold := '0';
  if (_iPos > 0) then begin
    _sBold := Copy(sColor, 1, _iPos-1);
    if (_sBold = 'light') then _sBold := '1'
    else _sBold := '0';
  end;
  _sColor := Copy(sColor, _iPos+1, 20);
  if (sType = 'FG') then _sType := '3' else _sType := '4';
  //writeln('color=' + _sColor + ',bold=' + _sBold);

  if (_sColor = 'black') then begin
    _sColor := '0';
  end else if (_sColor = 'red') then begin
    _sColor := '1';
  end else if (_sColor = 'green') then begin
    _sColor := '2';
  end else if (_sColor = 'green') then begin
    _sColor := '2';
  end else if (_sColor = 'yellow') then begin
    _sColor := '3';
  end else if (_sColor = 'blue') then begin
    _sColor := '4';
  end else if (_sColor = 'magenta') then begin
    _sColor := '5';
  end else if (_sColor = 'cyan') then begin
    _sColor := '6';
  end else begin // white
    _sColor := '7';
  end;
  if (sType = 'FG') then Result := _sBold + ';' + _sType + _sColor
  else Result := ';' + _sType + _sColor;
end;

procedure TMyApplication.DoRun;
var _iPos: Integer;
  _sBranchName, _sCurrentDir, _sText, _sExeFileDir: String;
  _sDefaultFGColor, _shighlightFGColor, _sIniVersion: String;
  _sDefaultBGColor, _shighlightBGColor, _sBranchStatus, _sBranchStatusCode, _sParam: String;
  _sPrompt, s, _sBatchFile, _sTempDir, _sHEADFile: AnsiString;
  _oFileHEAD : TextFile;
  _oFileBatch: TextFile;
  _oIni: TIniFile;
  _needCreateIni: Boolean;
begin
  { add your program here }
  _sParam := '';
  if (ParamCount = 1) then _sParam := ParamStr(1);
  if (_sParam = '-?') or (_sParam = '-help') or (_sParam = '-h') then begin
    help();
    Terminate;
    Exit;
  end;

  _sExeFileDir := ExtractFilePath(ExeName);
  _sCurrentDir := GetCurrentDir();
  _sHEADFile := getHEADFile();
  //writeln('echo ' + _sHEADFile);

  if not FileExists(_sHEADFile) then begin
    WriteLn('echo This folder is not a Git working directory.');
    Terminate;
    Exit;
  end;

  _needCreateIni := false;
  _oIni := TIniFile.Create(_sExeFileDir + 'git-prompt.ini');
  if FileExists(_sExeFileDir + 'git-prompt.ini') then begin
    _sIniVersion := _oIni.ReadString('Prompt', 'version', '');
    if (_sIniVersion <> _VERSION) then _needCreateIni := true;
  end else begin
    _needCreateIni := true;
  end;

  if (_needCreateIni) then begin
    _oIni.WriteString('Prompt', 'DefaultFG', 'light green');
    _oIni.WriteString('Prompt', 'DefaultBG', 'black');
    _oIni.WriteString('Prompt', 'HighlightFG', 'light yellow');
    _oIni.WriteString('Prompt', 'HighlightBG', 'black');
    _oIni.WriteString('Prompt', 'PromptBatch', 'd:\util\git-prompt.bat');
  end;
  _oIni.WriteString('Prompt', 'version', _VERSION);

  _sHighlightFGColor := _oIni.ReadString('Prompt', 'HighlightFG.behind', '');
  if (_sHighlightFGColor = '') then begin
    _oIni.WriteString('Prompt', 'HighlightFG.up-to-date', 'light cyan');
    _oIni.WriteString('Prompt', 'HighlightBG.up-to-date', 'black');
    _oIni.WriteString('Prompt', 'HighlightFG.behind', 'light red');
    _oIni.WriteString('Prompt', 'HighlightBG.behind', 'black');
    _oIni.WriteString('Prompt', 'HighlightFG.nonsync', 'light yellow');
    _oIni.WriteString('Prompt', 'HighlightBG.nonsync', 'black');
    _oIni.WriteString('Prompt', 'HighlightFG.ahead', 'light green');
    _oIni.WriteString('Prompt', 'HighlightBG.ahead', 'black');
  end;

  AssignFile(_oFileHEAD, _sHEADFile);
  FileMode := fmOpenRead;
  Reset(_oFileHEAD);

  ReadLn(_oFileHEAD, _sText);
  CloseFile(_oFileHEAD);

  _iPos := Pos('heads/', _sText);
  if (_iPos > 0) then begin
    _sBranchName := Copy(_sText, _iPos+6, 99);

    _sDefaultFGColor := _oIni.ReadString('Prompt', 'DefaultFG', 'white');
    _sDefaultFGColor := getEscapeColor(_sDefaultFGColor, 'FG');
    _sDefaultBGColor := _oIni.ReadString('Prompt', 'DefaultBG', 'black');
    _sDefaultBGColor := getEscapeColor(_sDefaultBGColor, 'BG');

    _sBranchStatus := ''; _sBranchStatusCode := '';
    if (RunCommand('git', ['status'], s)) then begin
      _iPos := Pos('Your branch is ', s);
      if (_iPos > 0) then begin
        _sBranchStatus := Copy(s, _iPos+15, 255);
        _iPos := Pos(' ', _sBranchStatus);
        _sBranchStatusCode := '.' + Copy(_sBranchStatus, 1, _iPos-1);  // "behind" or "up-to-date"
        _iPos := Pos(#10, _sBranchStatus);
        if (_iPos > 0) then begin
          _sBranchStatus := Copy(_sBranchStatus, 1, _iPos-1);  // The status message.
        end else begin
          _iPos := Pos('.', _sBranchStatus);
          _sBranchStatus := Copy(_sBranchStatus, 1, _iPos);
        end;
      end;
    end;
    _sHighlightFGColor := _oIni.ReadString('Prompt', 'HighlightFG' + _sBranchStatusCode, 'white');
    _sHighlightFGColor := getEscapeColor(_sHighlightFGColor, 'FG');
    _sHighlightBGColor := _oIni.ReadString('Prompt', 'HighlightBG' + _sBranchStatusCode, 'black');
    _sHighlightBGColor := getEscapeColor(_sHighlightBGColor, 'BG');


    _sPrompt := '$p ($E[' + _sHighlightFGColor + _sHighlightBGColor + 'm' +
         _sBranchName + '$E[' + _sDefaultFGColor + _sDefaultBGColor + 'm)$g';

    _sTempDir := GetEnv('TEMP');
    Writeln('prompt ' + _sPrompt);
    Writeln('@echo Branch: ' + _sBranchName);
    if (_sBranchStatusCode <> '') then Writeln('@echo Branch is ' + _sBranchStatus);
    Writeln('@rem Use git-prompt.bat to change your prompt.');
    Writeln('@rem git-prompt.bat will generate git-prompt-temp.bat in ' + _sTempDir + ', then execute it to change prompt');

    _sBatchFile := _oIni.ReadString('Prompt', 'PromptBatch', _sTempDir + '\git-prompt.bat');
    if not FileExists(_sBatchFile) then begin
      AssignFile(_oFileBatch, _sBatchFile);
      ReWrite(_oFileBatch);
      s := '@echo off' + #13#10+
        'if "%1"=="-?" goto HELP' + #13#10 +
        'if "%1"=="-help" goto HELP' + #13#10 +
        'goto GIT' + #13#10 +
        ':HELP' + #13#10 +
        '  git prompt -?' + #13#10 +
        '  goto END' + #13#10 +
        ':GIT' + #13#10 +
        '  git prompt > %TEMP%\git-prompt-temp.bat' + #13#10+
        '  call %TEMP%\git-prompt-temp.bat' + #13#10 +
        '  echo:' + #13#10 +
        '  goto END' + #13#10 +
        ':END' + #13#10;

      Writeln(_oFileBatch, s);
      CloseFile(_oFileBatch);
    end;
  end;
  _oIni.Free;

  Terminate;
  Exit;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='My Application';
  Application.Run;
  Application.Free;
end.

