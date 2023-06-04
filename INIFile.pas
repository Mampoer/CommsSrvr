unit INIFile;

{$MODE Delphi}

interface
  uses Forms, LCLIntf, LCLType, LMessages, IniFiles, SysUtils, Classes;

  procedure IniInitialize;
  // Start up INI file access.

  procedure IniShutdown;
  // Shutdown INI file access.

  function IniRead(Section, Ident, Default : String) : String;
  // Read an INI value.

  procedure IniWrite(Section, Ident, Value : String);
  // Write an INI value.

  procedure IniSection(Section : String; var Strings : TStringList);
  // Return all keys and values for given section

  function AnyIniRead(FileName, Section, Ident, Default : String) : String;
  // read from INI specified by file name

  function AnyIniWrite(FileName, Section, Ident, Value : String) : Integer;
  // Write an INI value to specified file

implementation

  var
    iFile : TIniFile;
    csIniFile   : TRTLCriticalSection;  // Critical section for this unit.

  procedure IniInitialize;
  // Start up INI file access.  Set up the IniFile object.
  var
    fName : String;
  begin
    InitializeCriticalSection(csIniFile);
    EnterCriticalSection(csIniFile);
    fName := ExpandFileName(Application.ExeName);
    fName := Copy(fName, 1, Length(fName)-4) + '.INI' ;
    iFile := TIniFile.Create(fName);
    LeaveCriticalSection(csIniFile);
  end;

  procedure IniShutdown;
  // Shutdown INI file access.
  begin
    EnterCriticalSection(csIniFile);
    iFile.Free;
    LeaveCriticalSection(csIniFile);
    DeleteCriticalSection(csIniFile)
  end;

  function IniRead(Section, Ident, Default : String) : String;
  begin
    EnterCriticalSection(csIniFile);
    Result := iFile.ReadString(Section, Ident, Default);
    LeaveCriticalSection(csIniFile);
  end;

  procedure IniWrite(Section, Ident, Value : String);
  begin
    EnterCriticalSection(csIniFile);
    iFile.WriteString(Section, Ident, Value);
    LeaveCriticalSection(csIniFile);
  end;

  procedure IniSection(Section : String; var Strings : TStringList);
  begin
    EnterCriticalSection(csIniFile);
    if Strings <> nil then
      iFile.ReadSectionValues(Section, Strings);
    LeaveCriticalSection(csIniFile);
  end;

  function AnyIniRead(FileName, Section, Ident, Default : String) : String;
  var
    f : TIniFile;
  begin
    Result := '?';
    try
      f := TIniFile.Create(FileName);
      try
        Result := f.ReadString(Section, Ident, Default);
      finally
        f.Free;
      end;
    except
      Result := '?';
    end;
  end;

  function AnyIniWrite(FileName, Section, Ident, Value : String) : Integer;
  var
    f : TIniFile;
  begin
    Result := 0;
    try
      f := TIniFile.Create(FileName);
      try
        f.WriteString(Section, Ident, Value);
      finally
        f.Free;
      end;
    except
      Result := -1;
    end;
  end;

end.
