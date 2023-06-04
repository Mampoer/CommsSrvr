unit FileDrvr;

interface

  uses Windows, SysUtils, StdCtrls, Classes, SysDef;

  const
    MAX_OPEN_FILES = 10;

    // File Types
    FT_UNDEFINED = 0;
    FT_FLAT = 1;             // Header followed by data blob
    FT_FIXED_RECORDS = 2;    // Header followed by fixed length data records
    FT_VARIABLE_RECORDS = 3; // Header followed by variable size data records
    FT_VARIABLE_FIELDS = 4;  // Header followed by variable size data records
                             //   where records are structured as fields
    // Record Types
    RT_0 = 0; // 0 used for FT_FLAT file types
    RT_1 = 1; // 1..4 used for FT_FIXED_RECORDS, all records same size
    RT_2 = 2;
    RT_3 = 3;
    RT_4 = 4;
    RT_5 = 5; // 5..8 used for FT_VARIABLE_RECORDS, each record own size
    RT_6 = 6;
    RT_7 = 7;
    RT_8 = 8;
    RT_9 = 9; // 9..10 used for FT_VARIABLE_FIELDS, Structured Field Records
    RT_10 = 10;
    // Field Types
    FT_0 = 0;
    FT_1 = 1;
    FT_2 = 2;
    FT_3 = 3;
    FT_4 = 4;

  type
    PFileHeader = ^TFileHeader;
    TFileHeader = packed record
      FileType : Word;         // contains one of the FT_xxx constants
      FileIdentifier : Word;   // unique ID assigned by file owner
      FileNumber : DWord;      // sequence number assigned by owner
      RecordSize : Word;       // 0 means variable
      MirrorFlag : Word;       // non-zero if file is to be mirrored
      HeaderSize : Word;       // Size of this record in 8-bit bytes
      HeaderCRC : Word         // CRC-16 on all other fields in this record
    end;

    TIndexEntry = packed record
      RecordOffset : Word;     // Offset from beginning of file
      RecordNumber : Word;     // as per sort order for this index
      RecordSize : Word;       // size of the the record stored at 'Offset'
      RecordIdentifier : Word; // same as Identifier stored at 'Offset'
    end;

    TIndex = packed record
      IndexNumber : Word;      // Starting from 1
      IndexField : Word;       // Field number used to sort
      IndexSize : Word;        // Size of Index Table containing Index Entries
      IndexCRC : Word;         // CRC-16 on Index excluding this record field
      IndexTable : Array[1..255] of TIndexEntry;
    end;

    TRecord0 = packed record
      Data : PChar;
    end;

    TRecord1 = packed record
      RecordType : Word;
      Data : PChar;
    end;

    TRecord2 = packed record
      RecordType : Word;
      RecordCRC : Word;
      Data : PChar;
    end;

    TRecord3 = packed record
      RecordType : Word;
      RecordIdentifier : Word;
      Data : PChar;
    end;

    TRecord4 = packed record
      RecordType : Word;
      RecordIdentifier : Word;
      RecordCRC : Word;
      Data : PChar;
    end;

    TRecord5 = packed record
      RecordType : Word;
      RecordSize : Word;
      Data : PChar;
    end;

    TRecord6 = packed record
      RecordType : Word;
      RecordSize : Word;
      RecordCRC : Word;
      Data : PChar;
    end;

    TRecord7 = packed record
      RecordType : Word;
      RecordSize : Word;
      RecordIdentifier : Word;
      Data : PChar;
    end;

    TRecord8 = packed record
      RecordType : Word;
      RecordSize : Word;
      RecordIdentifier : Word;
      RecordCRC : Word;
      Data : PChar;
    end;

    TRecord9 = packed record
      RecordType : Word;
      RecordSize : Word;
      RecordIdentifier : Word;
      FieldList : PChar;
    end;

    TRecord10 = packed record
      RecordType : Word;
      RecordSize : Word;
      RecordIdentifier : Word;
      RecordCRC : Word;
      FieldList : PChar;
    end;

    TField0 = packed record
      Data : PChar;
    end;

    TField1 = packed record
      FieldType : Word;
      Data : PChar;
    end;

    TField2 = packed record
      FieldType : Word;
      FieldIdentifier : Word;
      Data : PChar;
    end;

    TField3 = packed record
      FieldType : Word;
      FieldSize : Word;
      Data : PChar;
    end;

    TField4 = packed record
      FieldType : Word;
      FieldIdentifier : Word;
      FieldSize : Word;
      Data : PChar;
    end;

    TFileTable = record
      FileHandle1 : Integer;
      FileHandle2 : Integer;
      FileHeader : TFileHeader;
    end;

  procedure SetFilePaths(const sPath1, sPath2 : String);
  function CreateFile(const sFileName : String; wFileType, wFileIdentifier : Word; dwFileNumber : LongInt; wRecordSize : Word; bMirrorFlag : Boolean) : Boolean;
  function RemoveFile(const sFileName : String; MirrorFlag : Boolean) : Boolean;
  function RecoverFile(const sFileName : String) : Boolean;
  function ChangeFileName(const sOldFileName, sNewFileName : String; MirrorFlag : Boolean) : Boolean;
  function MergeFile(const sSrcName, sDstName : String; MirrorFlag : Boolean) : Boolean;
  function FindFile(var sFileName : String; MirrorFlag : Boolean): Boolean;
  function CountFile(var sFileName : String; MirrorFlag : Boolean; var dCount : Cardinal): Boolean;
//  function CheckFile(const sFileName : String; var FileHeader : TFileHeader; var dRecordCount : Integer) : Boolean;
//  function IndexFile(const sFileName : String; dFieldNumber : Integer) : Boolean;
//  function RemoveIndex(const sFileName : String; dFieldNumber : Integer) : Boolean;
//  function PurgeFile(const sFileName : String) : Boolean;
  function AppendFile(const sFileName : String; cData : PChar; Count : Integer; MirrorFlag : Boolean) : Boolean;

  function OpenFile(const sFileName : String; var dHandle : Integer; var FileHeader : TFileHeader) : Boolean;
  function CloseFile(dHandle : Integer) : Boolean;
  function AppendRecord(dHandle : Integer; wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
  function InsertRecord(dHandle : Integer; wIndexNo, wRecNo, wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
  function RetrieveRecord(dHandle : Integer; wIndexNo, wRecNo : Word; var wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
  function ReadRecords(dHandle : Integer; var wRecCount : Word; wIndexNo, wRecNo : Word; var wRecSize : Word; pRecords : Pointer) : Boolean;
  function FindRecord(dHandle : Integer; wCmpOffset, wCmpSize, wIndexNo: Word; var wRecNo, wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
  function RemoveRecord(dHandle : Integer; pRecord : Pointer) : Boolean;
  function GetLastFileError : Integer;

implementation

var
  ErrorCode : Integer;
  sMasterPath : String;
  sBackupPath : String;
  FileTable : Array[1..MAX_OPEN_FILES] of TFileTable;

// ****************************************************************************
// Read 'dCount' number of bytes at current file location from both master and
// backup files, and return error if data from both files do not compare
// Data returned in buffer pointed to by 'PBuffer'
//
function ReadBuffer(FileHandle1, FileHandle2 : Integer; PBuffer : Pointer; dCount : Integer; MirrorFlag : Boolean) : Integer;
var
  dRetVal1, dRetVal2 : Integer;
  PBuffer2 : Pointer;
begin
  dRetVal1 := FileRead(FileHandle1, PBuffer^, dCount);
  if MirrorFlag then
  begin
    try
      GetMem(PBuffer2, dCount);
    except
      Result := ERR_NOMEMORY;
      Exit;
    end;
    try
      dRetVal2 := FileRead(FileHandle2, PBuffer2^, dCount);
      if (dRetVal2 <> dRetVal1) or not CompareMem(PBuffer, PBuffer2, dRetVal1) then
          dRetVal1 := ERR_FILECOMPARE;
    finally
      FreeMem(PBuffer2);
    end;
  end;
  Result := dRetVal1;
end;

// ****************************************************************************
function ReadFileHeader(const sFileName : String; Index : Integer) : Integer;
var
  FileHandle1, FileHandle2 : Integer;
  dRetVal : Integer;
  dCount : Integer;
  PBuffer2 : Pointer;
begin
  if (FileGetAttr(sMasterPath+sFileName) and faReadOnly) <> 0 then
    FileHandle1 := FileOpen(sMasterPath+sFileName, fmOpenRead or fmShareDenyNone)
  else
    FileHandle1 := FileOpen(sMasterPath+sFileName, fmOpenReadWrite or fmShareDenyWrite);
  if FileHandle1 = -1 then
  begin
    Result := GetLastError;
    Exit;
  end;
  dCount := Sizeof(TFileHeader);
  dRetVal := FileRead(FileHandle1, FileTable[Index].FileHeader, dCount);
  if dRetVal <> Sizeof(TFileHeader) then
  begin
    if dRetVal < 0 then
      dRetVal := GetLastError
    else
      dRetVal := 0;
    if dRetVal = 0 then
      dRetVal := ERR_FILEREAD;
  end
  else
    dRetVal := 0;
  if dRetVal <> 0 then
  begin
    FileClose(FileHandle1);
    Result := dRetVal;
    Exit;
  end;

  if FileTable[Index].FileHeader.MirrorFlag <> 0 then
  begin
    FileHandle2 := FileOpen(sBackupPath+sFileName, fmOpenReadWrite or fmShareDenyWrite);
    if FileHandle2 = -1 then
    begin
      FileClose(FileHandle1);
      Result := GetLastError;
      Exit;
    end;
    try
      GetMem(PBuffer2, Sizeof(TFileHeader)+1);
    except
      Result := ERR_NOMEMORY;
      FileClose(FileHandle1);
      FileClose(FileHandle2);
      Exit;
    end;
    try
      dRetVal := FileRead(FileHandle2, PBuffer2^, Sizeof(TFileHeader));
      if dRetVal <> dCount then
      begin
        if dRetVal < 0 then
          dRetVal := GetLastError
        else
          dRetVal := 0;
        if dRetVal = 0 then
          dRetVal := ERR_FILEREAD;
      end
      else
        dRetVal := 0;
      if dRetVal = 0 then
        if not CompareMem(@FileTable[Index].FileHeader, PBuffer2, Sizeof(TFileHeader)) then
          dRetVal := ERR_FILECOMPARE;
    finally
      FreeMem(PBuffer2);
    end;
    if dRetVal <> 0 then
    begin
      FileClose(FileHandle1);
      FileClose(FileHandle2);
      Result := dRetVal;
      Exit;
    end;
  end
  else
    FileHandle2 := 0;
  FileTable[Index].FileHandle1 := FileHandle1;
  FileTable[Index].FileHandle2 := FileHandle2;
  Result := 0;
end;

// ****************************************************************************
// Compare 'dCount' number of bytes at current file location from both master and
// backup files, and return error if data from both files do no match
//
function VerifyWrite(FileHandle1, FileHandle2 : Integer; dCount : Integer; MirrorFlag : Boolean) : Integer;
var
  dRetVal : Integer;
  PBuffer1, PBuffer2 : Pointer;
begin

  try
    GetMem(PBuffer1, dCount);
  except
    Result := ERR_NOMEMORY;
    Exit;
  end;

  dRetVal := FileRead(FileHandle1, PBuffer1^, dCount);
  if dRetVal <> dCount then
  begin
    if dRetVal < 0 then
      dRetVal := GetLastError
    else
      dRetVal := 0;
    if dRetVal = 0 then
      dRetVal := ERR_FILEREAD;
  end
  else
    dRetVal := 0;

  if MirrorFlag then
  begin
    try
      GetMem(PBuffer2, dCount);
    except
      FreeMem(PBuffer1);
      Result := ERR_NOMEMORY;
      Exit;
    end;
    if dRetVal = 0 then
    begin
      dRetVal := FileRead(FileHandle2, PBuffer2^, dCount);
      if dRetVal <> dCount then
      begin
        if dRetVal < 0 then
          dRetVal := GetLastError
        else
          dRetVal := 0;
        if dRetVal = 0 then
          dRetVal := ERR_FILEREAD;
      end
      else
        dRetVal := 0;
    end;
    if dRetVal = 0 then
    begin
      if not CompareMem(PBuffer1, PBuffer2, dCount) then
        dRetVal := ERR_FILECOMPARE;
    end;
    FreeMem(PBuffer2);
  end;

  FreeMem(PBuffer1);
  Result := dRetVal;
end;

// ****************************************************************************
procedure SetFilePaths(const sPath1, sPath2 : String);
begin
  sMasterPath := sPath1;
  sBackupPath := sPath2;
end;

// ****************************************************************************
function CreateFile(const sFileName : String; wFileType, wFileIdentifier : Word;
  dwFileNumber : LongInt; wRecordSize : Word; bMirrorFlag : Boolean) : Boolean;
var
  FileHandle1, FileHandle2 : Integer;
  NewHeader : TFileHeader;
begin
  Result := False;

  case wFileType of
  FT_FLAT,
  FT_VARIABLE_RECORDS,
  FT_VARIABLE_FIELDS:
    begin
      if wRecordSize <> 0 then
      begin
        ErrorCode := ERR_INVALPARM;
        Exit;
      end;
    end;
  FT_FIXED_RECORDS:
    begin
      if wRecordSize = 0 then
      begin
        ErrorCode := ERR_INVALPARM;
        Exit;
      end;
    end;
  FT_UNDEFINED:
    begin
    end;
  else
    begin
      Exit;
    end;
  end;

  with NewHeader do
  begin
    FileType := wFileType;
    FileIdentifier := wFileIdentifier;
    FileNumber := dwFileNumber;
    RecordSize := wRecordSize;
    if bMirrorFlag then
      MirrorFlag := 1
    else
      MirrorFlag := 0;
    HeaderSize := Sizeof(TFileHeader);
    HeaderCRC := 0;
  end;

  if FileExists(sMasterPath+sFileName) and not
       DeleteFile(sMasterPath+sFileName) then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  FileHandle1 := FileCreate(sMasterPath+sFileName);
  if FileHandle1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;

  if bMirrorFlag then
  begin
    if FileExists(sBackupPath+sFileName) and not
         DeleteFile(sBackupPath+sFileName) then
    begin
      FileClose(FileHandle1);
      ErrorCode := GetLastError;
      Exit;
    end;
    FileHandle2 := FileCreate(sBackupPath+sFileName);
    if FileHandle2 = -1 then
    begin
      FileClose(FileHandle1);
      ErrorCode := GetLastError;
      Exit;
    end;
  end;

  if wFileType = FT_UNDEFINED then
  begin
    FileClose(FileHandle1);
    if bMirrorFlag then FileClose(FileHandle2);
    Result := True;
    Exit;
  end;

  if (FileWrite(FileHandle1, NewHeader, Sizeof(TFileHeader)) < 0) or
       not FlushFileBuffers(FileHandle1) or (FileSeek(FileHandle1, 0, 0) = -1) then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle1);
    if bMirrorFlag then FileClose(FileHandle2);
    Exit;
  end;

  if bMirrorFlag then
  begin
    if (FileWrite(FileHandle2, NewHeader, Sizeof(TFileHeader)) < 0) or
         not FlushFileBuffers(FileHandle2) or (FileSeek(FileHandle2, 0, 0) = -1) then
    begin
      ErrorCode := GetLastError;
      FileClose(FileHandle1);
      FileClose(FileHandle2);
      Exit;
    end;
  end;

  ErrorCode := VerifyWrite(FileHandle1, FileHandle2, Sizeof(TFileHeader), bMirrorFlag);
  if ErrorCode <> 0 then
    Result := False
  else
    Result := True;

  FileClose(FileHandle1);
  if bMirrorFlag then FileClose(FileHandle2);
end;

// ****************************************************************************
function RemoveFile(const sFileName : String; MirrorFlag : Boolean) : Boolean;
begin
  Result := False;
  ErrorCode := 0;
  if not DeleteFile(sMasterPath+sFileName) then
    ErrorCode := GetLastError;
  if MirrorFlag and not DeleteFile(sBackupPath+sFileName) then
    ErrorCode := GetLastError;
  if ErrorCode = 0 then
    Result := True;
end;

// ****************************************************************************
function RecoverFile(const sFileName : String) : Boolean;
begin
  Result := False;
  ErrorCode := 0;
  if not CopyFile(PChar(sMasterPath+sFileName), PChar(sBackupPath+sFileName), False) then
    ErrorCode := GetLastError;
  if ErrorCode = 0 then
    Result := True;
end;

// ****************************************************************************
function ChangeFileName(const sOldFileName, sNewFileName : String; MirrorFlag : Boolean) : Boolean;
begin
  Result := False;
  ErrorCode := 0;
  if not RenameFile(sMasterPath+sOldFileName, sMasterPath+sNewFileName) then
    ErrorCode := GetLastError;
  if MirrorFlag and not RenameFile(sBackupPath+sOldFileName, sBackupPath+sNewFileName) then
    ErrorCode := GetLastError;
  if ErrorCode = 0 then
    Result := True;
end;

// ****************************************************************************
function MergeFile(const sSrcName, sDstName : String; MirrorFlag : Boolean) : Boolean;
var
  MStream : TMemoryStream;
  FStream : TFileStream;
begin
  Result := False;
  if not FileExists(sMasterPath+sSrcName) or
           (MirrorFlag and not FileExists(sBackupPath+sSrcName)) then
    Exit;
  MStream := TMemoryStream.Create;
  try
    if FileExists(sMasterPath+sDstName) then
      FStream := TFileStream.Create(sMasterPath+sDstName, fmOpenReadWrite or fmShareDenyWrite)
    else
      FStream := TFileStream.Create(sMasterPath+sDstName, fmCreate or fmShareDenyWrite);
    try
      // Append file 'sSrcName' to file 'sDstName'
      MStream.LoadFromFile(sMasterPath+sSrcName);
      FStream.Seek(0, soFromEnd);
      FStream.CopyFrom(MStream, 0);
      Result := True;
    finally
      FStream.Free;
    end;
  finally
    MStream.Free;
  end;
  if Result = False then
    Exit;
  if not MirrorFlag then
    Exit;
  Result := False;
  MStream := TMemoryStream.Create;
  try
    if FileExists(sBackupPath+sDstName) then
      FStream := TFileStream.Create(sBackupPath+sDstName, fmOpenReadWrite or fmShareDenyWrite)
    else
      FStream := TFileStream.Create(sBackupPath+sDstName, fmCreate or fmShareDenyWrite);
    try
      // Append file 'sSrcName' to file 'sDstName'
      MStream.LoadFromFile(sBackupPath+sSrcName);
      FStream.Seek(0, soFromEnd);
      FStream.CopyFrom(MStream, 0);
      Result := True;
    finally
      FStream.Free;
    end;
  finally
    MStream.Free;
  end;
end;

// ****************************************************************************
function FindFile(var sFileName : String; MirrorFlag : Boolean): Boolean;
var
  SearchRec: TSearchRec;
  Retval : Integer;
begin
  Retval := FindFirst(sMasterPath+sFileName, faAnyFile, SearchRec);
  if Retval <> 0 then
  begin
    ErrorCode := Retval;
    Result := False;
    Exit;
  end;
  sFileName := SearchRec.Name;
  FindClose(SearchRec);
  // now make sure same file also exists in backup directory
  if MirrorFlag and not FileExists(sBackupPath+sFileName) then
  begin
    ErrorCode := ERR_FILEMISSING;
    Result := False;
    Exit;
  end;
  Result := True;
end;

// ****************************************************************************
function CountFile(var sFileName : String; MirrorFlag : Boolean; var dCount : Cardinal): Boolean;
var
  SearchRec: TSearchRec;
  Retval : Integer;
begin
  Result := False;
  dCount := 0;
  Retval := FindFirst(sMasterPath+sFileName, faAnyFile, SearchRec);
  if Retval <> 0 then
  begin
    ErrorCode := Retval;
    Exit;
  end;
  while RetVal = 0 do
  begin
    // now make sure same file also exists in backup directory
    if MirrorFlag and not FileExists(sBackupPath+SearchRec.Name) then
    begin
      sFileName := SearchRec.Name;
      ErrorCode := ERR_FILEMISSING;
      Exit;
    end;
    Inc(dCount);
    RetVal := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
  Result := True;
end;

// ****************************************************************************
function AppendFile(const sFileName : String; cData : PChar; Count : Integer;
                      MirrorFlag : Boolean) : Boolean;
var
  FileHandle1, FileHandle2 : Integer;
begin
  Result := False;
  FileHandle1 := FileOpen(sMasterPath+sFileName, fmOpenWrite or fmShareDenyWrite);
  if FileHandle1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  if FileSeek(FileHandle1, 0, 2) = -1 then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle1);
    Exit;
  end;
  if FileWrite(FileHandle1, cData^, Count) < 0 then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle1);
    Exit;
  end;
  if not FlushFileBuffers(FileHandle1) then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle1);
    Exit;
  end;
  FileClose(FileHandle1);

  if not MirrorFlag then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
  FileHandle2 := FileOpen(sBackupPath+sFileName, fmOpenWrite or fmShareDenyWrite);
  if FileHandle2 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  if FileSeek(FileHandle2, 0, 2) = -1 then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle2);
    Exit;
  end;
  if FileWrite(FileHandle2, cData^, Count) < 0 then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle2);
    Exit;
  end;
  if not FlushFileBuffers(FileHandle2) then
  begin
    ErrorCode := GetLastError;
    FileClose(FileHandle2);
    Exit;
  end;
  FileClose(FileHandle2);
  Result := True;
end;

// ****************************************************************************
function OpenFile(const sFileName : String; var dHandle : Integer; var FileHeader : TFileHeader) : Boolean;
var
  Index : Integer;
begin
  Result := False;
  for Index := Low(FileTable) to High(FileTable) do
  begin
    if (FileTable[Index].FileHandle1 = -1) and
         (FileTable[Index].FileHandle2 = -1) then
      Break;
    if Index = High(FileTable) then
    begin
      ErrorCode := ERR_FILE2MANYOPEN;
      Exit;
    end;
  end;
  ErrorCode := ReadFileHeader(sFileName, Index);
  if ErrorCode <> 0 then
    Exit;
  dHandle := Index;
  FileHeader := FileTable[Index].FileHeader;
  Result := True;
end;

// ****************************************************************************
function CloseFile(dHandle : Integer) : Boolean;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or (dHandle > High(FileTable)) then
    Exit;
  if FileTable[dHandle].FileHandle1 <> -1 then
  begin
    try
      FileClose(FileTable[dHandle].FileHandle1);
    finally
      FileTable[dHandle].FileHandle1 := -1;
    end;
  end;
  if FileTable[dHandle].FileHandle2 > 0 then
  begin
    try
      FileClose(FileTable[dHandle].FileHandle2);
    finally
      FileTable[dHandle].FileHandle2 := -1;
    end;
  end
  else
    FileTable[dHandle].FileHandle2 := -1;
  ErrorCode := 0;
  Result := True;
end;

// ****************************************************************************
function AppendRecord(dHandle : Integer; wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
var
  Offset1, Offset2 : Integer;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) or
             (wRecSize < 1) or (pRecord = nil) then
    Exit;

  case FileTable[dHandle].FileHeader.FileType of
  FT_FLAT:
    begin
      if wRecType <> RT_0 then
        Exit;
    end;
  FT_FIXED_RECORDS:
    begin
      if (wRecType < RT_1) or (wRecType > RT_4) then
        Exit;
      if wRecSize <> FileTable[dHandle].FileHeader.RecordSize then
        Exit;
    end;
  FT_VARIABLE_RECORDS:
    begin
      if (wRecType < RT_5) or (wRecType > RT_8) then
        Exit;
    end;
  FT_VARIABLE_FIELDS:
    begin
      if (wRecType < RT_9) or (wRecType > RT_10) then
        Exit;
    end;
  else
    begin
      Exit;
    end;
  end;

  Offset1 := FileSeek(FileTable[dHandle].FileHandle1, 0, 2);
  if Offset1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;

  if (FileWrite(FileTable[dHandle].FileHandle1, pRecord^, wRecSize) < 0) or
       not FlushFileBuffers(FileTable[dHandle].FileHandle1) then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  Offset1 := FileSeek(FileTable[dHandle].FileHandle1, Offset1, 0);
  if Offset1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;

  if FileTable[dHandle].FileHeader.MirrorFlag <> 0 then
  begin
    Offset2 := FileSeek(FileTable[dHandle].FileHandle2, 0, 2);
    if Offset2 = -1 then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    if (FileWrite(FileTable[dHandle].FileHandle2, pRecord^, wRecSize) < 0) or
         not FlushFileBuffers(FileTable[dHandle].FileHandle2) then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    Offset2 := FileSeek(FileTable[dHandle].FileHandle2, Offset2, 0);
    if Offset2 = -1 then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    ErrorCode := VerifyWrite(FileTable[dHandle].FileHandle1,
                   FileTable[dHandle].FileHandle2, wRecSize, True);
  end
  else
    ErrorCode := VerifyWrite(FileTable[dHandle].FileHandle1,
                   FileTable[dHandle].FileHandle2, wRecSize, False);

  if ErrorCode <> 0 then
    Result := False
  else
    Result := True;
end;

// ****************************************************************************
function InsertRecord(dHandle : Integer; wIndexNo, wRecNo, wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
var
  Offset1, Offset2 : Integer;
  RecOffset, RecOrigin : Integer;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) or
             (wRecSize < 1) or (pRecord = nil) then
    Exit;

  case FileTable[dHandle].FileHeader.FileType of
  FT_FLAT:
    begin
      Exit;
    end;
  FT_FIXED_RECORDS:
    begin
      if (wRecType < RT_1) or (wRecType > RT_4) then
        Exit;
      if wRecSize <> FileTable[dHandle].FileHeader.RecordSize then
        Exit;
      if wIndexNo = 0 then
      begin
        if wRecNo = 0 then
        begin
          RecOrigin := 2;
          RecOffset := 0;
        end
        else
        begin
          RecOrigin := 0;
          RecOffset := Sizeof(TFileHeader) + (wRecNo - 1) * wRecSize;
        end;
      end
      else
        Exit;
    end;
  FT_VARIABLE_RECORDS:
    begin
//      if (wRecType < RT_5) or (wRecType > RT_8) then
        Exit;
    end;
  FT_VARIABLE_FIELDS:
    begin
//      if (wRecType < RT_9) or (wRecType > RT_10) then
        Exit;
    end;
  else
    begin
      Exit;
    end;
  end;

  Offset1 := FileSeek(FileTable[dHandle].FileHandle1, RecOffset, RecOrigin);
  if Offset1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  if (FileWrite(FileTable[dHandle].FileHandle1, pRecord^, wRecSize) < 0) or
       not FlushFileBuffers(FileTable[dHandle].FileHandle1) then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;
  Offset1 := FileSeek(FileTable[dHandle].FileHandle1, RecOffset, RecOrigin);
  if Offset1 = -1 then
  begin
    ErrorCode := GetLastError;
    Exit;
  end;

  if FileTable[dHandle].FileHeader.MirrorFlag <> 0 then
  begin
    Offset2 := FileSeek(FileTable[dHandle].FileHandle2, RecOffset, RecOrigin);
    if Offset2 = -1 then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    if (FileWrite(FileTable[dHandle].FileHandle2, pRecord^, wRecSize) < 0) or
         not FlushFileBuffers(FileTable[dHandle].FileHandle2) then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    Offset2 := FileSeek(FileTable[dHandle].FileHandle2, RecOffset, RecOrigin);
    if Offset2 = -1 then
    begin
      ErrorCode := GetLastError;
      Exit;
    end;
    ErrorCode := VerifyWrite(FileTable[dHandle].FileHandle1,
                   FileTable[dHandle].FileHandle2, wRecSize, True);
  end
  else
    ErrorCode := VerifyWrite(FileTable[dHandle].FileHandle1,
                   FileTable[dHandle].FileHandle2, wRecSize, False);

  if ErrorCode <> 0 then
    Result := False
  else
    Result := True;
end;

// ****************************************************************************
function RetrieveRecord(dHandle : Integer; wIndexNo, wRecNo : Word; var wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
var
  Offset1, Offset2 : Integer;
  RetVal : Integer;
  MFlag : Boolean;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) or
             (pRecord = nil) then
    Exit;

  if FileTable[dHandle].FileHeader.MirrorFlag <> 0 then
    MFlag := True
  else
    MFlag := False;

  case FileTable[dHandle].FileHeader.FileType of
  FT_FLAT:
    begin
      wRecType := 0;
      RetVal := ReadBuffer(FileTable[dHandle].FileHandle1,
                     FileTable[dHandle].FileHandle2, pRecord, wRecSize, MFlag);
      if RetVal < 0 then
        ErrorCode := RetVal
      else
      begin
        wRecSize := RetVal;
        ErrorCode := 0;
        Result := True;
      end;
    end;
  FT_FIXED_RECORDS:
    begin
      if wIndexNo = 0 then
      begin
        if wRecNo = 0 then
        begin // 0 means last record
          wRecSize := FileTable[dHandle].FileHeader.RecordSize;
          Offset1 := FileSeek(FileTable[dHandle].FileHandle1, -(Integer(wRecSize)), 2);
          if MFlag then
            Offset2 := FileSeek(FileTable[dHandle].FileHandle2, -(Integer(wRecSize)), 2)
          else
            Offset2 := 0;
          if (Offset1 = -1) or (Offset2 = -1) then
          begin
            ErrorCode := GetLastError;
            Exit;
          end;
        end
        else
        begin
          wRecSize := FileTable[dHandle].FileHeader.RecordSize;
          Offset1 := Sizeof(TFileHeader) + (wRecNo - 1) * wRecSize;
          Offset2 := Offset1;
          Offset1 := FileSeek(FileTable[dHandle].FileHandle1, Offset1, 0);
          if MFlag then
            Offset2 := FileSeek(FileTable[dHandle].FileHandle2, Offset2, 0)
          else
            Offset2 := 0;
          if (Offset1 = -1) or (Offset2 = -1) then
          begin
            ErrorCode := GetLastError;
            Exit;
          end;
        end;
        RetVal := ReadBuffer(FileTable[dHandle].FileHandle1,
                       FileTable[dHandle].FileHandle2, pRecord, wRecSize, MFlag);
        if RetVal <> wRecSize then
        begin
          if RetVal < 0 then
            ErrorCode := RetVal
          else
            if RetVal = 0 then
              ErrorCode := ERR_FILENORECORD
            else
              ErrorCode := ERR_FILESIZE;
        end
        else
           ErrorCode := 0;
        wRecType := PWordArray(pRecord)^[0];
      end
      else
        Exit;
    end;
  FT_VARIABLE_RECORDS,
  FT_VARIABLE_FIELDS:
    begin
      if wIndexNo = 0 then
      begin
        RetVal := ReadBuffer(FileTable[dHandle].FileHandle1,
                       FileTable[dHandle].FileHandle2, pRecord, 4, MFlag);
        if RetVal <> 4 then
        begin
          if RetVal < 0 then
            ErrorCode := RetVal
          else
            if RetVal = 0 then
              ErrorCode := ERR_FILENORECORD
            else
              ErrorCode := ERR_FILESIZE;
          Exit;
        end;
        wRecType := PWordArray(pRecord)^[0];
        wRecSize := PWordArray(pRecord)^[1];
        RetVal := ReadBuffer(FileTable[dHandle].FileHandle1,
                       FileTable[dHandle].FileHandle2, @PWordArray(pRecord)^[2], wRecSize-4, MFlag);
        if RetVal <> wRecSize-4 then
        begin
          if RetVal < 0 then
            ErrorCode := RetVal
          else
            if RetVal = 0 then
              ErrorCode := ERR_FILENORECORD
            else
              ErrorCode := ERR_FILESIZE;
        end
        else
           ErrorCode := 0;
      end
      else
        Exit;
    end;
  else
    Exit;
  end;

  if ErrorCode <> 0 then
    Result := False
  else
    Result := True;
end;

// ****************************************************************************
function ReadRecords(dHandle : Integer; var wRecCount : Word; wIndexNo, wRecNo : Word; var wRecSize : Word; pRecords : Pointer) : Boolean;
var
  Offset1, Offset2 : Integer;
  RetVal : Integer;
  MFlag : Boolean;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) or
             (pRecords = nil) then
    Exit;

  if FileTable[dHandle].FileHeader.MirrorFlag <> 0 then
    MFlag := True
  else
    MFlag := False;

  case FileTable[dHandle].FileHeader.FileType of
  FT_FLAT:
    Exit;
  FT_FIXED_RECORDS:
    begin
      if wIndexNo = 0 then
      begin
        if wRecNo = 0 then
        begin // 0 means last record
          wRecSize := FileTable[dHandle].FileHeader.RecordSize;
          Offset1 := FileSeek(FileTable[dHandle].FileHandle1, -(wRecCount*Integer(wRecSize)), 2);
          if MFlag then
            Offset2 := FileSeek(FileTable[dHandle].FileHandle2, -(wRecCount*Integer(wRecSize)), 2)
          else
            Offset2 := 0;
          if (Offset1 = -1) or (Offset2 = -1) then
          begin
            ErrorCode := GetLastError;
            Exit;
          end;
        end
        else
        begin
          wRecSize := FileTable[dHandle].FileHeader.RecordSize;
          Offset1 := Sizeof(TFileHeader) + (wRecNo - 1) * wRecSize;
          Offset2 := Offset1;
          Offset1 := FileSeek(FileTable[dHandle].FileHandle1, Offset1, 0);
          if MFlag then
            Offset2 := FileSeek(FileTable[dHandle].FileHandle2, Offset2, 0)
          else
            Offset2 := 0;
          if (Offset1 = -1) or (Offset2 = -1) then
          begin
            ErrorCode := GetLastError;
            Exit;
          end;
        end;
        RetVal := ReadBuffer(FileTable[dHandle].FileHandle1,
                       FileTable[dHandle].FileHandle2, pRecords, wRecSize * wRecCount, MFlag);
        if RetVal <> wRecSize * wRecCount then
        begin
          if RetVal < 0 then
            ErrorCode := RetVal
          else
            if RetVal mod wRecSize <> 0 then
              ErrorCode := ERR_FILETOOSHORT
            else
            begin
              wRecCount := RetVal div wRecSize;
              ErrorCode := 0;
            end;
        end
        else
           ErrorCode := 0;
      end
      else
        Exit;
    end;
  FT_VARIABLE_RECORDS,
  FT_VARIABLE_FIELDS:
    begin
      Exit;
    end;
  else
    Exit;
  end;

  if ErrorCode <> 0 then
    Result := False
  else
    Result := True;
end;

// ****************************************************************************
function FindRecord(dHandle : Integer; wCmpOffset, wCmpSize, wIndexNo: Word; var wRecNo, wRecType, wRecSize : Word; pRecord : Pointer) : Boolean;
var
  Offset1, Offset2 : Integer;
  i, RetVal : Integer;
  MFlag : Boolean;
  pBuffer : Pointer;
begin
  Result := False;
  ErrorCode := ERR_INVALPARM;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) or
             (pRecord = nil) then
    Exit;

  if FileTable[dHandle].FileHeader.MirrorFlag <> 0 then
    MFlag := True
  else
    MFlag := False;

  case FileTable[dHandle].FileHeader.FileType of
  FT_FLAT:
    Exit;
  FT_FIXED_RECORDS:
    begin
      wRecSize := FileTable[dHandle].FileHeader.RecordSize;
      try
        GetMem(pBuffer, wRecSize * 100);
      except
        ErrorCode := ERR_NOMEMORY;
        Exit;
      end;
      try
        if wIndexNo = 0 then
        begin
          if wRecNo = 0 then wRecNo := 1;
          Offset1 := Sizeof(TFileHeader) + (wRecNo - 1) * wRecSize;
          Offset2 := Offset1;
          Offset1 := FileSeek(FileTable[dHandle].FileHandle1, Offset1, 0);
          if MFlag then
            Offset2 := FileSeek(FileTable[dHandle].FileHandle2, Offset2, 0)
          else
            Offset2 := 0;
          if (Offset1 = -1) or (Offset2 = -1) then
          begin
            ErrorCode := GetLastError;
            Exit;
          end;
          wRecNo := 0;
          repeat
            RetVal := ReadBuffer(FileTable[dHandle].FileHandle1, FileTable[dHandle].FileHandle2,
                           pBuffer, wRecSize * 100, MFlag);
            if RetVal < 0 then
            begin
              ErrorCode := RetVal;
              Exit;
            end;
            if RetVal mod wRecSize <> 0 then
            begin
              ErrorCode := ERR_FILETOOSHORT;
              Exit;
            end;
            Offset1 := 0;
            for i := 1 to RetVal div wRecSize do
            begin
              Inc(wRecNo);
              if CompareMem(@PByteArray(pRecord)^[wCmpOffset],
                            @PByteArray(pBuffer)^[Offset1+wCmpOffset], wCmpSize) then
              begin
                CopyMemory(pRecord, @PByteArray(pBuffer)^[Offset1], wRecSize);
                wRecType := PWordArray(pRecord)^[0];
                Result := True;
                Exit;
              end;
              Offset1 := Offset1 + wRecSize;
            end;
          until RetVal <> wRecSize * 100;
          wRecNo := 0;
          wRecType := 0;
          Result := True;
          Exit;
        end
        else
          Exit;
      finally
        FreeMem(PBuffer);
      end;
    end;
  FT_VARIABLE_RECORDS,
  FT_VARIABLE_FIELDS:
    begin
//      if wIndexNo = 0 then
//      begin
//        ErrorCode := ReadBuffer(FileTable[dHandle].FileHandle1,
//                       FileTable[dHandle].FileHandle2, pRecord, 4, MFlag);
//        if ErrorCode <> 0 then
//          Exit;
//        wRecType := PWordArray(pRecord)^[0];
//        wRecSize := PWordArray(pRecord)^[1];
//        ErrorCode := ReadBuffer(FileTable[dHandle].FileHandle1,
//                       FileTable[dHandle].FileHandle2, @PWordArray(pRecord)^[2], wRecSize-4, MFlag);
//      end
//      else
        Exit;
    end;
  else
    Exit;
  end;
end;

// ****************************************************************************
function RemoveRecord(dHandle : Integer; pRecord : Pointer) : Boolean;
begin
  Result := False;
  if (dHandle < Low(FileTable)) or
       (dHandle > High(FileTable)) or
         (FileTable[dHandle].FileHandle1 = -1) or
           (FileTable[dHandle].FileHandle2 = -1) then
  begin
    ErrorCode := ERR_INVALPARM;
    Exit;
  end;
  Result := True;
end;

// ****************************************************************************
function GetLastFileError : Integer;
begin
  Result := ErrorCode;
end;

// ****************************************************************************
procedure Init;
var
  i : Integer;
begin
  ErrorCode := 0;
  sMasterPath := 'x';
  sBackupPath := 'x';
  ZeroMemory(@FileTable, Sizeof(FileTable));
  for i := Low(FileTable) to High(FileTable) do
  begin
    FileTable[i].FileHandle1 := -1;
    FileTable[i].FileHandle2 := -1;
  end;
end;

// ****************************************************************************
begin
  Init;
end.
