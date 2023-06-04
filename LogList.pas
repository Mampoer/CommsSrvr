unit LogList;

{$MODE Delphi}

interface

  uses StdCtrls, Classes, SysUtils, LCLIntf, LCLType, LMessages, SyncObjs;

  procedure LogInitialize;
  procedure LogShutdown;

  function LogGetStatusLine : String;
  procedure LogSetStatusLine(StatusText : String);

  function LogGetLine(Level : Integer) : String;
  procedure LogPutLine(Level : Integer; LogText : String);

implementation

var
  csLogStrings : TCriticalSection;     // Critical section for this unit.
  LogBuffer0   : TStringList;          // All log entries
  LogBuffer1   : TStringList;          // Level 3,2 and 1 entries
  LogBuffer2   : TStringList;          // Level 3 and 2 entries
  LogBuffer3   : TStringList;          // Level 3 entries
  StatusBuffer : String;               // Holds the last StatusLine update.

// ***********************************************
procedure LogInitialize;
begin
  LogBuffer0 := TStringList.Create;
  LogBuffer1 := TStringList.Create;
  LogBuffer2 := TStringList.Create;
  LogBuffer3 := TStringList.Create;
  StatusBuffer := '';
  if csLogStrings = nil then
    csLogStrings := TCriticalSection.Create;
end;

// ***********************************************
procedure LogShutdown;
begin
  LogBuffer3.Free;
  LogBuffer2.Free;
  LogBuffer1.Free;
  LogBuffer0.Free;
  if csLogStrings <> nil then
  begin
    csLogStrings.Free;
    csLogStrings := nil;
  end;
end;

// ***********************************************
function LogGetStatusLine : String;
// Returns the last status line set.
begin
  if csLogStrings = nil then
    Exit;
  csLogStrings.Enter;
  Result := StatusBuffer;
  StatusBuffer := '';
  csLogStrings.Leave;
end;

// ***********************************************
procedure LogSetStatusLine(StatusText : String);
// Put the StatusText in as the Status Line.
begin
  if csLogStrings = nil then
    Exit;
  csLogStrings.Enter;
  StatusBuffer := StatusText;
  csLogStrings.Leave;
end;

// ***********************************************
function LogGetLine(Level : Integer) : String;
// Returns the next log line in the series.  Returns '' if non there.
begin
  Result := '';
  if csLogStrings = nil then
    Exit;
  if (Level = 0) and (LogBuffer0.Count = 0) then
    Exit;
  csLogStrings.Enter;
  case Level of
  0: begin
      // Return the first string and delete it.
      Result := LogBuffer0.Strings[0];
      LogBuffer0.Delete(0);
    end;
  1: begin
      Result := LogBuffer1.Text;
    end;
  2: begin
      Result := LogBuffer2.Text;
    end;
  3: begin
      Result := LogBuffer3.Text;
    end;
  end;
  csLogStrings.Leave;
end;

// ***********************************************
procedure LogPutLine(Level : Integer; LogText : String);
// Put the LogText in as the next log line.
begin
  if csLogStrings = nil then
    Exit;
  if LogText[Length(LogText)] = #10 then
    // If line ends in LF - then assume it ends in CR/LF and
    //  chop those off.
    LogText := Copy(LogText, 1, Length(LogText)- 2);
  // Add on the date and time.
  LogText := FormatDateTime('mm/dd hh:mm:ss.zzz ', Now) + LogText;

  csLogStrings.Enter;

  // Make sure we only have 5000 in the list.  Delete the oldest.
  if LogBuffer0.Count >= 5000 then
  begin
    LogBuffer0.Delete(0);
    LogBuffer0.Add('###' + LogText); // notification that dropped
  end
  else
    LogBuffer0.Add(LogText);

  if Level > 0 then
  begin
    // Make sure we only have 90 in the list.  Delete the oldest.
    if LogBuffer1.Count >= 90 then
      LogBuffer1.Delete(0);
    LogBuffer1.Add(LogText);
  end;
  if Level > 1 then
  begin
    // Make sure we only have 50 in the list.  Delete the oldest.
    if LogBuffer2.Count >= 50 then
      LogBuffer2.Delete(0);
    LogBuffer2.Add(LogText);
  end;
  if Level > 2 then
  begin
    // Make sure we only have 20 in the list.  Delete the oldest.
    if LogBuffer3.Count >= 20 then
      LogBuffer3.Delete(0);
    LogBuffer3.Add(LogText);
  end;
  csLogStrings.Leave;
end;

begin
  csLogStrings := nil;
end.
