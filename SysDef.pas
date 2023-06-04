unit SysDef;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, SysUtils, Classes;

const
  ERR_BASE = -5000;

  ERR_FAILED = (ERR_BASE);
  ERR_INVALPARM = (ERR_BASE - 1);

  ERR_NOMEMORY = (ERR_BASE - 10);
  ERR_OVERFLOW = (ERR_BASE - 11);
  ERR_UNDERFLOW = (ERR_BASE - 12);
  ERR_NOTINITIALISED = (ERR_BASE - 13);
  ERR_LISTFULL = (ERR_BASE - 14);

  ERR_NOTNUMERIC = (ERR_BASE - 20);
  ERR_INVALDATE = (ERR_BASE - 21);
  ERR_NOTFOUND = (ERR_BASE - 22);

  ERR_CHANNELNUM = (ERR_BASE - 40);
  ERR_LINKNUMBER = (ERR_BASE - 41);
  ERR_INVALIDHEADER = (ERR_BASE - 42);
  ERR_AUTHENTICATION = (ERR_BASE - 43);

  ERR_NOTCONNECTED = (ERR_BASE - 50);

  TERMINAL_TYPE_UNICAPT16 = 'A';
  TERMINAL_TYPE_UNICAPT32 = 'B';
  TERMINAL_TYPE_TELIUM = 'C';

  MSG_TYPE_EMPTY_REQ = 'E';
  MSG_TYPE_EMPTY_RSP = 'e';
  MSG_TYPE_PING_REQ = 'P';
  MSG_TYPE_PING_RSP = 'p';

  // Terminal Server - Transaction Server
  MSG_TYPE_REQUEST = 'R';
  MSG_TYPE_RESPONSE = 'r';

  // Terminal Server - Terminals
  MSG_TYPE_CONNECT = 'C';
  MSG_TYPE_DATA = 'D';
  MSG_TYPE_SUPERVISORY = 'S';

  TAG_TYPE_SOH_REQUEST = '@R';
  TAG_TYPE_SOH_RESPONSE = '@r';
  TAG_TYPE_SOH_COMMAND = '@C';
  TAG_TYPE_SOH_CONFIRMATION = '@c';

type
  PUpstreamHeaderF = ^TUpstreamHeaderF;
  TUpstreamHeaderF = packed record
    MessageFormat : Byte;                 // 'F'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    TerminalID : Array[0..7] of Byte;	    // BCD-16
    SessionNumber : Array[0..1] of Byte;  // BCD-4
    ChannelNumber : Byte;                 // Binary
    StartEnd : Byte;
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PUpstreamHeaderA = ^TUpstreamHeaderA;
  TUpstreamHeaderA = packed record
    MessageFormat : Byte;                 // 'A'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    ChannelNumber : Array[0..1] of Byte;  // BCD-4
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PUpstreamHeaderC = ^TUpstreamHeaderC;
  TUpstreamHeaderC = packed record
    MessageFormat : Byte;                 // 'C'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    TerminalID : Array[0..3] of Byte;	    // BCD-8
    SessionNumber : Array[0..1] of Byte;  // BCD-4
    ChannelNumber : Byte;                 // Binary
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PUpstreamHeaderJ = ^TUpstreamHeaderJ;
  TUpstreamHeaderJ = packed record
    MessageFormat : Byte;                 // 'J'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    ChannelNumber : Array[0..1] of Byte;  // BCD-4
    SerialNumber : Array[0..14] of Byte;  // Ascii
    TerminalID : Array[0..7] of Byte;	    // Ascii
    SessionNumber : Array[0..3] of Byte;  // BCD-8
    MessageNumber : Array[0..1] of Byte;  // BCD-4
    NxtMsgExp : Array[0..1] of Byte;      // BCD-4
    BitFlags : Byte;                      // 8 Bits
    FieldCount : Byte;                    // Binary
    // optional fields (THeaderField)
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;


  PTPDUHeader = ^TTPDUHeader;
  TTPDUHeader = packed record
    MessageID : Byte;                     // $60/$68
    DestinAddress : Array[0..1] of Byte;  // NII
    OriginAddress : Array[0..1] of Byte;
  end;

  PMessageHeaderA = ^TUpstreamHeaderA;
  TMessageHeaderA = packed record
    MessageFormat : Byte;                 // 'A'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    ChannelNumber : Array[0..1] of Byte;  // BCD-4
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PMessageHeaderJ = ^TMessageHeaderJ;
  TMessageHeaderJ = packed record
    MessageFormat : Byte;                 // 'J'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;                   // MSG_TYPE_...
    HeaderLength : Byte;                  // Binary
    HostID : Array[0..1] of Byte;   	    // BCD-4
    ChannelNumber : Array[0..1] of Byte;  // BCD-4
    SerialNumber : Array[0..14] of Byte;  // Ascii
    TerminalID : Array[0..7] of Byte;	    // Ascii
    SessionNumber : Array[0..3] of Byte;  // BCD-8
    MessageNumber : Array[0..1] of Byte;  // BCD-4
    NxtMsgExp : Array[0..1] of Byte;      // BCD-4
    BitFlags : Byte;                      // 8 Bits
    FieldCount : Byte;                    // Binary
    // optional fields (THeaderField)
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  // from V2 terminal
  PMessageHeaderE = ^TMessageHeaderE;
  TMessageHeaderE = packed record
    MessageFormat : Byte;                 // 'E'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;
    HeaderLength : Byte;
    SessionNumber : Array[0..1] of Byte;
    MessageNumber : Array[0..1] of Byte;
    NxtMsgExp : Array[0..1] of Byte;
    StartEnd : Byte;
    HostID : Array[0..1] of Byte;         // BCD-4
    TerminalID : Array[0..7] of Byte;  	  // BCD-16
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  // from V1 terminal
  PMessageHeader1 = ^TMessageHeader1;
  TMessageHeader1 = packed record
    MessageFormat : Byte;                 // 'B'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;
    HeaderLength : Byte;
    SessionNumber : Array[0..1] of Byte;
    MessageNumber : Array[0..1] of Byte;
    NxtMsgExp : Array[0..1] of Byte;
    StartEnd : Byte;
    HostID : Array[0..1] of Byte;         // BCD-4
    TerminalID : Array[0..3] of Byte;  	  // BCD-8
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PMessageHeader2 = ^TMessageHeader2;
  TMessageHeader2 = packed record
    MessageFormat : Byte;                 // 'B'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;
    HeaderLength : Byte;
    SessionNumber : Array[0..1] of Byte;
    MessageNumber : Array[0..1] of Byte;
    NxtMsgExp : Array[0..1] of Byte;
    StartEnd : Byte;
    HostID : Array[0..1] of Byte;         // BCD-4
    TerminalID : Array[0..3] of Byte;  	  // BCD-8
  end;

  PMessageHeaderB = ^TMessageHeaderB;
  TMessageHeaderB = packed record
    MessageFormat : Byte;                 // 'B'
    MessageLength : Array[0..1] of Byte;  // BCD-4
    MessageType : Byte;
    HeaderLength : Byte;
    SessionNumber : Array[0..1] of Byte;
    MessageNumber : Array[0..1] of Byte;
    NxtMsgExp : Array[0..1] of Byte;
    StartEnd : Byte;
    HostID : Array[0..1] of Byte;         // BCD-4
    TerminalID : Array[0..3] of Byte;  	  // BCD-8
    SignType : Byte;
    Signature : Array[0..15] of Byte;
  end;

  PMessageTag = ^TMessageTag;
  TMessageTag = packed record
    TagType : Array[0..1] of Byte;			  // Ascii
    TagLength : Array[0..1] of Byte;		  // BCD-2 (2+2+sizeof(Data))
    Data : Array of Byte;
  end;

  //
  // RemoteMonitor tags
  //
  PTagSOHRequest = ^TTagSOHRequest;
  TTagSOHRequest = packed record
    TagType : Array[0..1] of Byte;      // TAG_TYPE_SOH_REQUEST
    TagLength : Array[0..1] of Byte;
    TagFormat : Byte;                   // 'A'
    SequenceNumber : Byte;
    ReportingLevel : Byte;
    UpstreamOption : Byte;
  end;

  PTagSOHResponse = ^TTagSOHResponse;
  TTagSOHResponse = packed record
    TagType : Array[0..1] of Byte;      // TAG_TYPE_SOH_RESPONSE
    TagLength : Array[0..1] of Byte;
    TagFormat : Byte;                   // 'A'
    SequenceNumber : Byte;
    StatusLength : Array[0..1] of Byte;
    EventsLength : Array[0..1] of Byte;
//  StatusLines : Array of Byte;        // Variable length - see StatusLength
//  EventLines : Array of Byte;         // Variable length - see StatusLength
  end;

  PTagSOHCommand = ^TTagSOHCommand;
  TTagSOHCommand = packed record
    TagType : Array[0..1] of Byte;      // TAG_TYPE_SOH_COMMAND
    TagLength : Array[0..1] of Byte;
    TagFormat : Byte;                   // 'A'
    SequenceNumber : Byte;
    UpstreamOption : Byte;
    CommandCode : Byte;
    //Parameters : Array of Byte;      // Variable length
  end;

  PTagSOHConfirmation = ^TTagSOHConfirmation;
  TTagSOHConfirmation = packed record
    TagType : Array[0..1] of Byte;      // TAG_TYPE_SOH_CONFIRMATION
    TagLength : Array[0..1] of Byte;
    TagFormat : Byte;                   // 'A'
    SequenceNumber : Byte;
    CommandCode : Byte;
    ResultCode : Array[0..1] of Byte;
   //ResultData : Array of Byte;        // Variable length
  end;

  PTagSOHQuery = ^TTagSOHQuery;
  TTagSOHQuery = packed record
    TagType : Array[0..1] of Byte;      // TAG_TYPE_SOH_...
    TagLength : Array[0..1] of Byte;
    TagFormat : Byte;                   // 'A'
    UpstreamOption : Byte;
    //...
  end;



function BCDToInt(var Bcd : Array of Byte; var Int : Integer; Count : Integer) : Boolean;
function BCDToInt64(var Bcd : Array of Byte; var Int : Int64; Count : Integer) : Boolean;
function IntToBCD(Int : Integer; var Bcd : Array of Byte; Count : Integer) : Boolean;
function Int64ToBCD(Int : Int64; var Bcd : Array of Byte; Count : Integer) : Boolean;
function BCDStr(var Bcd : Array of Byte; Count : Integer) : String;
function StrToBCD(Str : String; var Bcd : Array of Byte; Count : Integer) : Boolean;
function StrArr(const Str : String; var Alp : Array of Byte; Count : Integer) : Integer;
function StrInt(const Str : String) : Integer;
function ArrStr(var Arr : Array of Byte; Count : Integer) : String;
function ArrStr2(var Arr : Array of Byte; Count : Integer) : String;
function ArrHex(const Arr : Array of Byte; Count : Integer) : String;
function HexDump(const Arr : Array of Byte; Count : Integer; Delim : Char) : String;
function CentsToStr(dCents : Int64) : String;

function replaceControlCodes(str : String) : String;
function GetFirstField(var Str : String) : String;
function GetFirstNumber(var Str : String; Width : Integer) : String;
function GetFirstToken(var Str : String) : String;

{function FindFile(const sFilePath, sFileName : String; var FileNames : TStringList) : Boolean;
function RetrieveFile(const sFilePath, sFileName : String; var Contents : TStringList) : Integer;
function StoreFile(const sFilePath, sFileName : String; var Contents : TStringList) : Integer;
function WriteFile(const sName,sData : String) : Integer;
function ReadBinFile(sName : String; Offset, Count : Integer; var Buffer) : Integer;}

implementation

// ****************************************************************************
function BCDToInt(var Bcd : Array of Byte; var Int : Integer; Count : Integer) : Boolean;
var
  i,j : Integer;
  b : Byte;
begin
  Result := False;
  Int := 0;
  if Count < 1 then
    Exit;
  j := 1;
  for i := Count-1 downto 0 do
  begin
    b := Bcd[i] shr 4;
    if (b > 9) or ((Bcd[i] and $0f) > 9) then Exit;
    b := 10 * b + (Bcd[i] and $0f);
    Int := Int + j * b;
    j := j * 100;
  end;
  Result := True;
end;

// ****************************************************************************
function BCDToInt64(var Bcd : Array of Byte; var Int : Int64; Count : Integer) : Boolean;
var
  i : Integer;
  j : Int64;
  b : Byte;
begin
  Result := False;
  Int := 0;
  if Count < 1 then
    Exit;
  j := 1;
  for i := Count-1 downto 0 do
  begin
    b := Bcd[i] shr 4;
    if (b > 9) or ((Bcd[i] and $0f) > 9) then Exit;
    b := 10 * b + (Bcd[i] and $0f);
    Int := Int + j * b;
    j := j * 100;
  end;
  Result := True;
end;

// ****************************************************************************
function IntToBCD(Int : Integer; var Bcd : Array of Byte; Count : Integer) : Boolean;
var
  i : Integer;
begin
  Result := False;
  if (Count < 1) or (Count > 8) then
    Exit;
  Count := (Count + 1) shr 1;
// Count=5 or 6, Int=12345 then Bcd=01|23|45
  for i := Count-1 downto 0 do
  begin
    Bcd[i] := Int mod 10;
    Int := Int div 10;
    Bcd[i] := Bcd[i] + ((Int mod 10) shl 4);
    Int := Int div 10;
  end;
  Result := True;
end;

// ****************************************************************************
function Int64ToBCD(Int : Int64; var Bcd : Array of Byte; Count : Integer) : Boolean;
var
  i : Integer;
begin
  Result := False;
  if (Count < 1) or (Count > 16) then
    Exit;
  Count := (Count + 1) shr 1;
  for i := Count-1 downto 0 do
  begin
    Bcd[i] := Int mod 10;
    Int := Int div 10;
    Bcd[i] := Bcd[i] + ((Int mod 10) shl 4);
    Int := Int div 10;
  end;
  Result := True;
end;

// ****************************************************************************
function StrToBCD(Str : String; var Bcd : Array of Byte; Count : Integer) : Boolean;
var
  i,n : Integer;
  s : String;
  b : Byte;
begin
  Result := False;
  if (Count < 1) or (Count > 16) then
    Exit;
  s := Str;
  if Length(s) < Count then
    s := StringOfChar('0', Count-Length(s)) + s;
  if (Count and $01) = $01 then
    s := '0' + s;
  n := 0;

  for i := 1 to Length(s) do
  begin
    b := Ord(s[i]) and $0f;
    if (i and $01) = $01 then
      Bcd[n] := b shl 4
    else
    begin
      Bcd[n] := Bcd[n] or b;
      n := n + 1;
    end;
  end;
  Result := True;
end;

// ****************************************************************************
function BCDStr(var Bcd : Array of Byte; Count : Integer) : String;
var
  i : Integer;
  b : Byte;
begin
  Result := '';
  if Count < 1 then
    Exit;
  for i := 0 to Count-1 do
  begin
    b := Bcd[i] shr 4;
    if (b > 9) or ((Bcd[i] and $0f) > 9) then Exit;
    Result := Result + Chr(48+b);
    b := Bcd[i] and $0f;
    Result := Result + Chr(48+b);
  end;
end;

// ****************************************************************************
function StrArr(const Str : String; var Alp : Array of Byte; Count : Integer) : Integer;
var
  Buffer : PChar;
begin
  GetMem(Buffer, Count+2);
  try
    ZeroMemory(Buffer, Count);
    StrLFmt(Buffer, Count, '%-s', [Str]);
    MoveMemory(@Alp, Buffer, Count);
  finally
    FreeMem(Buffer);
  end;
  if Length(Str) < Count then
    Result := Length(Str)
  else
    Result := Count;
end;

// ****************************************************************************
function StrInt(const Str : String) : Integer;
begin
  try
    Result := StrToIntDef(Str, 0);
  except
    Result := 0;
  end;
end;

// ****************************************************************************
function ArrStr(var Arr : Array of Byte; Count : Integer) : String;
var
  n : Integer;
  b : Byte;
begin
  Result := '';
  for n := 0 to Count-1 do
  begin
    b := Arr[n];
    if b = 0 then
      Exit;
    if (b < 32) or (b > 126) then
      b := ord('.');
    Result := Result + chr(b);
  end;
end;

// ****************************************************************************
function ArrStr2(var Arr : Array of Byte; Count : Integer) : String;
var
  n : Integer;
  b : Byte;
begin
  Result := '';
  for n := 0 to Count-1 do
  begin
    b := Arr[n];
    Result := Result + chr(b);
  end;
end;

// ****************************************************************************
function ArrHex(const Arr : Array of Byte; Count : Integer) : String;
var
  n : Integer;
  b : Byte;
begin
  Result := '';
  for n := 0 to Count-1 do
  begin
    b := Arr[n];
    Result := Result + IntToHex(b, 2);
  end;
end;

// ****************************************************************************
function HexDump(const Arr : Array of Byte; Count : Integer; Delim : Char) : String;
var
  n : Integer;
  b : Byte;
begin
  Result := '';
  for n := 0 to Count-1 do
  begin
    b := Arr[n];
    Result := Result + IntToHex(b, 2);
    if n < Count-1 then
      Result := Result + Delim;
  end;
end;

// ****************************************************************************
function CentsToStr(dCents : Int64) : String;
var
  s1, s2 : String;
  c : Integer;
begin
  s1 := IntToStr(dCents div 100);
  c := dCents mod 100;
  if c < 0 then c := c * -1;
  s2 := IntToStr(c);
  if Length(s2) = 1 then
    s2 := '0' + s2;
  Result := s1 + '.' + s2;
end;

// ****************************************************************************
function replaceControlCodes(str : String) : String;
var
  i : Integer;
begin
  i := Pos('\r', str);
  while i > 0 do
  begin
    str := Copy(str, 1, i-1) + #13 + Copy(str, i+2, Length(str)-i-1);
    i := Pos('\r', str);
  end;
  i := Pos('\n', str);
  while i > 0 do
  begin
    str := Copy(str, 1, i-1) + #10 + Copy(str, i+2, Length(str)-i-1);
    i := Pos('\n', str);
  end;
  i := Pos('\h', str);
  while i > 0 do
  begin
    str := Copy(str, 1, i-1) + #26 + Copy(str, i+2, Length(str)-i-1);
    i := Pos('\h', str);
  end;
  i := Pos('\b', str);
  while i > 0 do
  begin
    str := Copy(str, 1, i-1) + #27 + Copy(str, i+1, Length(str)-i);
    i := Pos('\b', str);
  end;
  i := Pos('\s', str);
  while i > 0 do
  begin
    str := Copy(str, 1, i-1) + #27 + Copy(str, i+1, Length(str)-i);
    i := Pos('\s', str);
  end;
  Result := str;
end;

// ****************************************************************************
function GetFirstField(var Str : String) : String;
var
  n : Integer;
begin
  n := Pos(',', Str);
  if n > 0 then
  begin
    Result := Copy(Str, 1, n-1);
    Str := Copy(Str, n+1, Length(Str)-n);
  end
  else
  begin
    Result := Str;
    Str := '';
  end;
end;

// ****************************************************************************
function GetFirstNumber(var Str : String; Width : Integer) : String;
var
  n : Integer;
begin
  n := Pos(',', Str);
  if n > 0 then
  begin
    Result := Copy(Str, 1, n-1);
    Str := Copy(Str, n+1, Length(Str)-n);
  end
  else
  begin
    Result := Str;
    Str := '';
  end;
  if Length(Result) < Width then
    Result := StringOfChar('0', Width-Length(Result)) + Result;
  if Length(Result) > Width then
    SetLength(Result, Width);
end;

// ****************************************************************************
function GetFirstToken(var Str : String) : String;
var
  n : Integer;
begin
  n := Pos('|', Str);
  if n > 0 then
  begin
    Result := Copy(Str, 1, n-1);
    Str := Copy(Str, n+1, Length(Str)-n);
  end
  else
  begin
    Result := Str;
    Str := '';
  end;
end;

// ****************************************************************************
function FindFile(const sFilePath, sFileName : String; var FileNames : TStringList) : Boolean;
var
  SearchRec: TSearchRec;
  Retval : Integer;
begin
  Result := False;
  FileNames.Clear;
  Retval := FindFirst(sFilePath+sFileName, faReadOnly, SearchRec);
  if Retval <> 0 then
    Exit;
  while RetVal = 0 do
  begin
    if (SearchRec.Attr and faReadOnly) <> 0 then
    begin
      FileNames.Add(SearchRec.Name);
      Result := True;
    end;
    RetVal := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
end;

{
// ****************************************************************************
function RetrieveFile(const sFilePath, sFileName : String; var Contents : TStringList) : Integer;
begin
  try
    Contents.LoadFromFile(sFilePath + sFileName);
  except
    Result := ERR_FILEMISSING;
    Exit;
  end;
  Result := 0;
end;

// ****************************************************************************
function StoreFile(const sFilePath, sFileName : String; var Contents : TStringList) : Integer;
begin
  if FileExists(sFilePath+sFileName)then
  begin
    Result := ERR_FILEXISTS;
    Exit;
  end;
  try
    Contents.SaveToFile(sFilePath+sFileName);
    Result := FileSetAttr(sFilePath+sFileName, faReadOnly);
  except
    Result := ERR_MSGFILE;
  end;
end;

// ****************************************************************************
function WriteFile(const sName,sData : String) : Integer;
var
  FileHandle : Integer;
  Count,Actual : Cardinal;
  Buf : Array[0..5000] of Char;
begin
  Result := 0;
  if not FileExists(sName) then
    FileHandle := FileCreate(sName)
  else
    FileHandle := FileOpen(sName, fmOpenWrite or fmShareDenyNone);
  if FileHandle > 0 then
  begin
    Count := Length(sData);
    if Count > Sizeof(Buf)-1 then
      Count := Sizeof(Buf)-1;
    FileSeek(FileHandle, 0, 2);
    StrPLCopy(Buf, sData, Count);
    Actual := FileWrite(FileHandle, Buf, Count);
    FlushFileBuffers(FileHandle);
    FileClose(FileHandle);
    if Actual <> Count then
    begin
      DeleteFile(sName);
      Result := ERR_FILEWRITE;
    end;
    if FileSetAttr(sName, faReadOnly) <> 0 then
    begin
      RenameFile(sName, sName+FormatDateTime('yymmddhhnnsszzz', Now)+'.exception');
      Result := ERR_FILEATTR;
    end;
  end;
end;

// ****************************************************************************
function ReadBinFile(sName : String; Offset, Count : Integer; var Buffer) : Integer;
var
  FileHandle : Integer;
begin
  Result := -1;
  if not FileExists(sName) then
    Exit;
  FileHandle := FileOpen(sName, fmOpenRead or fmShareDenyNone);
  if FileHandle > 0 then
  begin
    FileSeek(FileHandle, Offset, 0);
    Result := FileRead(FileHandle, Buffer, Count);
    FileClose(FileHandle);
  end;
end;}

end.

