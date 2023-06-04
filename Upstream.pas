unit Upstream;

{$MODE Delphi}

interface

  uses
    StdCtrls, Classes, SysUtils, LCLIntf, LCLType, LMessages,
    SysDef, Unit1;

  var
    // Terminal to Transaction Server messages
    RequestBuffer : Array[0..MAX_CHANNELS+1, 0..1023] of Byte;
    RequestLength : Array[0..MAX_CHANNELS+1] of Integer;
    ResponseDue : Array[0..MAX_CHANNELS+1] of Integer;
    CloseRequested : Array[0..MAX_CHANNELS+1] of Boolean;

  procedure ProcessResponse(LinkNumber : Integer; Count : Integer; Buffer : Array of Byte);
  procedure UpstreamRequest(Channel : Integer; Session, Host, MsgNum, NxtExp : Integer; HdrType, BitFlags : Byte; Buffer : Pointer; Length : Integer);
  procedure TestSession(LinkNumber : Integer);
  procedure SendPing(LinkNumber : Integer);

implementation

uses
  INIFile, LogList, Protocol, md5;


// ****************************************************************************
procedure AddLog(Level,Channel,Link : Integer; sData: String);
begin
  if Channel = 0 then
  begin
    if Link = 0 then
      LogPutLine(Level, '> '+sData)
    else
      LogPutLine(Level, 'UPSTREAM '+IntToStr(Link)+'> '+sData);
  end
  else if Link = 0 then
    LogPutLine(Level, IntToStr(Channel)+'-'+ConnectedTerminal[Channel]+'> '+sData)
  else
    LogPutLine(Level, IntToStr(Channel)+'-'+ConnectedTerminal[Channel]+'-'+IntToStr(Link)+'>   '+sData);
end;

// ****************************************************************************
procedure LogResponse(LinkNumber : Integer; Count : Integer; Buffer : Array of Byte);
var
  str : String;
  i,Size : Integer;
begin
  str := 'RX Link ['+IntToStr(Count)+'] ';
  if DebugMode > 2 then
  begin
    Size := Count;
    if (DebugMode > 3) then
    begin
      if (Size > 100) then
        Size := 100;
      for i := 0 to Size-1 do
        str := str + IntToHex(Buffer[i],2);
      if Size < Count then
        str := str + '...';
    end;
  end;
  AddLog(0, 0, LinkNumber, str);
end;

// ****************************************************************************
procedure ProcessResponse(LinkNumber : Integer; Count : Integer; Buffer : Array of Byte);
var
  pHdrA : PUpstreamHeaderA;
  pHdrC : PUpstreamHeaderC;
  pHdrF : PUpstreamHeaderF;
  pHdrJ : PUpstreamHeaderJ;
  Size,Offset,SesNo,Channel,HeaderSize : Integer;
  sTagType,sTermID : String;
  str : String;
  i : Integer;
begin
  if DebugMode > 1 then
  begin
    LogResponse(LinkNumber, Count, Buffer);
  end;

  pHdrJ := PUpstreamHeaderJ(@Buffer[0]);
  pHdrF := PUpstreamHeaderF(@Buffer[0]);
  pHdrC := PUpstreamHeaderC(@Buffer[0]);
  pHdrA := PUpstreamHeaderA(@Buffer[0]);

  if pHdrJ.MessageFormat = ord('J') then
    BCDToInt(pHdrJ.ChannelNumber, Channel, 2)
  else if pHdrJ.MessageFormat = ord('A') then
    BCDToInt(pHdrA.ChannelNumber, Channel, 2)
  else if pHdrF.MessageFormat = ord('F') then
    Channel := pHdrF.ChannelNumber
  else if pHdrC.MessageFormat = ord('C') then
    Channel := pHdrC.ChannelNumber
  else
  begin
    AddLog(2, 0, LinkNumber, 'RSP ERR: Unknown Message Format ' + IntToHex(pHdrF.MessageFormat, 2) + 'H');
    Exit;
  end;

  if (Channel < 1) or (Channel > MaxChannels) then
  begin
    if Channel = 0 then
    begin
      if pHdrA.MessageType = ord(MSG_TYPE_PING_RSP) then
        AddLog(1, 0, LinkNumber, 'RSP: Ping')
      else
        AddLog(1, 0, LinkNumber, '      RSP: Empty')
    end
    else
      AddLog(2, 0, LinkNumber, '      ERR: Invalid Channel Number '+IntToStr(Channel)+' in Upstream Response');
    Exit;
  end;

  if pHdrA.MessageType = ord(MSG_TYPE_SUPERVISORY) then
  begin
    // upstream response received - send it to terminal promptly
    if TransmitReady[Channel] > 1 then
      TransmitReady[Channel] := 1;
    if pHdrA.MessageFormat = Ord('A') then
    begin
      // include header
      Form1.QueueDownstream(Channel, Count, @Buffer[0]);
    end
    else
    begin
      Size := pHdrC.HeaderLength;
      if (Count > Size) and (Size < 256) then
        Form1.QueueDownstream(Channel, Count-Size, @Buffer[Size]);
    end;
    Exit;
  end;

  BCDToInt(pHdrF.MessageLength, Size, 2);
  if Size <> Count then
  begin
    AddLog(1, 0, LinkNumber, 'RSP: Empty Message');
    Exit;
  end;

  if pHdrF.MessageType = ord(MSG_TYPE_EMPTY_RSP) then
  begin
    AddLog(0, 0, LinkNumber, 'RSP: Ping');
    Exit;
  end;
  if pHdrF.MessageType = ord(MSG_TYPE_PING_RSP) then
  begin
    AddLog(0, 0, LinkNumber, '      RSP: Ping');
    Exit;
  end;
  if pHdrF.MessageType <> ord(MSG_TYPE_RESPONSE) then
  begin
    AddLog(2, 0, LinkNumber, '      RSP: Unknown Response Message ('+IntToHex(pHdrF.MessageType, 2)+', '+IntToStr(Count)+')');
    Exit;
  end;

  if ResponseDue[Channel] > 0 then
    Dec(ResponseDue[Channel]);

  if pHdrJ.MessageFormat = ord('J') then
  begin
    HeaderSize := pHdrJ.HeaderLength;
    sTermID := ArrStr(pHdrJ.TerminalID, 8);
    BCDToInt(pHdrJ.SessionNumber, SesNo, 4);
  end
  else if pHdrC.MessageFormat = ord('C') then
  begin
    HeaderSize := pHdrC.HeaderLength;
    sTermID := BCDStr(pHdrC.TerminalID, 4);
    BCDToInt(pHdrC.SessionNumber, SesNo, 2);
  end
  else
  begin
    HeaderSize := pHdrF.HeaderLength;
    sTermID := BCDStr(pHdrF.TerminalID, 8);
    BCDToInt(pHdrF.SessionNumber, SesNo, 2);
  end;

  if sTermID <> ConnectedTerminal[Channel] then
  begin
    AddLog(2, Channel, LinkNumber, 'RSP: Terminal ID mismatch for Channel '+IntToStr(Channel) + ', '+sTermID+' vs. '+ConnectedTerminal[Channel]);
    Exit;
  end;

//SesNo := 0;
  if SesNo <> SessionSequence[Channel] then
  begin
    if SesNo = 0 then
    begin
      AddLog(2, Channel, LinkNumber, 'RSP: Terminate condition ('+IntToStr(SessionSequence[Channel])+') '+IntToStr(TerminateCall[Channel]));
//      if KeepAlive[Channel] > 0 then
//        KeepAlive[Channel] := -1;
      if TerminateCall[Channel] < 2 then
        TerminateCall[Channel] := 2;
    end
    else
      AddLog(2, Channel, LinkNumber, 'RSP: Unexpected Session Number ('+IntToStr(SessionSequence[Channel])+', '+IntToStr(SesNo)+')');
    Exit;
  end;

  if Count = pHdrF.HeaderLength then
  begin
    // upstream response received - send it to terminal promptly
    if TransmitReady[Channel] > 1 then
      TransmitReady[Channel] := 1;

    // empty message
    Inc(EmptyCounter2[Channel]);
    if EmptyCounter2[Channel] > 5 then
    begin
      // too many empty responses from upstream link
      if KeepAlive[Channel] > 0 then
        KeepAlive[Channel] := -1;
      AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+' Abandon');
      Exit;
    end;
    if ( (pHdrJ.MessageFormat = ord('J')) and ((pHdrJ.BitFlags and $02) = $02) )
       or ( (pHdrF.MessageFormat = ord('F')) and ((pHdrF.StartEnd and $02) = $02) )
       or ( (pHdrC.MessageFormat = ord('C')) and not PlacedAnOrder[Channel] )
       or CloseRequested[Channel] then
    begin
      // nothing more to say, terminate session
      if KeepAlive[Channel] > 0 then
        KeepAlive[Channel] := 0;
      AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+' Close');
    end
    else
      AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+' Empty ('+IntToStr(EmptyCounter2[Channel])+')');
    Exit;
  end;

  if ((pHdrJ.MessageFormat = ord('J')) and ((pHdrJ.BitFlags and $02) = $02))
      or ((pHdrF.MessageFormat = ord('F')) and ((pHdrF.StartEnd and $02) = $02)) then
  begin
    CloseRequested[Channel] := True;
    if ((pHdrF.MessageFormat = ord('F')) and ((pHdrF.StartEnd and $04) = $04)) or
       ((pHdrF.MessageFormat = ord('J')) and ((pHdrJ.BitFlags and $04) = $04)) then
    begin
      KeepAlive[Channel] := -1;
      AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+'  Terminate ('+IntToStr(Size)+')');
    end
    else
      AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+' Close ('+IntToStr(Size)+')');
  end
  else
    AddLog(1, Channel, LinkNumber, 'RSP: S='+IntToStr(SesNo)+' ('+IntToStr(Size)+')');

  Size := pHdrF.HeaderLength;
  if Count >= Size then
    Form1.QueueDownstream(Channel, Count-Size, @Buffer[Size]); // exclude header

  // upstream response received - send it to terminal promptly
  if TransmitReady[Channel] > 1 then
    TransmitReady[Channel] := 1;

  if (KeepAlive[Channel] > 0) and (KeepAlive[Channel] < 2) then
    KeepAlive[Channel] := 2;
end;

// ****************************************************************************
procedure UpstreamRequest(Channel : Integer; Session, Host, MsgNum, NxtExp : Integer; HdrType, BitFlags : Byte; Buffer : Pointer; Length : Integer);
var
  pHdrF : PUpstreamHeaderF;
  pHdrC : PUpstreamHeaderC;
  pHdrJ : PUpstreamHeaderJ;
  RetVal, Size : Integer;
  Digest : MD5Digest;
  OutputBuffer : Array[0..1023] of Byte;
  LinkNumber : Integer;
  i,n : Integer;
begin
  if (Channel < 1) or (Channel > MaxChannels) then
  begin
    AddLog(3, 1, 0, 'ERR: Invalid channel number '+IntToStr(Channel)+' in UpstreamRequest() call');
    Exit;
  end;

  if (Host < 0) or (Host > 999) then
  begin
    AddLog(2, Channel, 1, '  ERR: Invalid host number '+IntToStr(Host)+' in request, using Link 1');
    LinkNumber := 1;
//    Exit;
  end
  else
  begin
    if ChannelLink[Channel] = 0 then
    begin
{      LinkNumber := 0;
      n := 0;
      for i := 1 to 8 do
      begin
        // round robin
        Inc(RoutingIndex[Host]);
        if RoutingIndex[Host] > 8 then
          RoutingIndex[Host] := 1;
        if RoutingTable[Host, RoutingIndex[Host]] then
        begin
          Inc(n);
          if LinkConState[RoutingIndex[Host]] = CON_READY then
          begin
            LinkNumber := RoutingIndex[Host];
            break;
          end;
        end;
      end;}
      LinkNumber := Form1.DetermineRoute(Host);
      ChannelLink[Channel] := LinkNumber;
    end
    else
      LinkNumber := ChannelLink[Channel];
  end;

  if LinkNumber = 0 then
  begin
    if n = 1 then
    begin
      AddLog(2, 0, 1, 'ERR: Upstream Server link down');
      Exit;
    end
    else if n > 1 then
    begin
      AddLog(2, 0, 1, 'ERR: Upstream Server links down');
      Exit;
    end;
    LinkNumber := 1; // default
  end;

  if LinkConState[LinkNumber] <> CON_READY then
  begin
    AddLog(2, 0, LinkNumber, 'ERR: Upstream Server link down');
    KeepAlive[Channel] := 0; // terminate session
    Exit;
  end;

  if HdrType = ord('J') then
  begin
    Size := Sizeof(TUpstreamHeaderJ);
    pHdrJ := PUpstreamHeaderJ(@OutputBuffer[0]);
    pHdrJ.MessageFormat := Ord('J');
    if Length = 0 then
      pHdrJ.MessageType := Ord(MSG_TYPE_EMPTY_REQ)
    else
      pHdrJ.MessageType := Ord(MSG_TYPE_REQUEST);
    pHdrJ.HeaderLength := Size;
    MoveMemory(@OutputBuffer[Size], Buffer, Length);
    Size := Size + Length;
    IntToBCD(Size, pHdrJ.MessageLength, 4);
    IntToBCD(Host, pHdrJ.HostID, 4);
    IntToBCD(Channel, pHdrJ.ChannelNumber, 4);
    StrArr(ConnectedTerminal[Channel], pHdrJ.TerminalID, 8);
    StrArr(ConnectedSerial[Channel], pHdrJ.SerialNumber, 15);
    IntToBCD(Session, pHdrJ.SessionNumber, 8);
    IntToBCD(MsgNum, pHdrJ.MessageNumber, 4);
    IntToBCD(NxtExp, pHdrJ.NxtMsgExp, 4);
    pHdrJ.BitFlags := BitFlags;
    pHdrJ.FieldCount := 0;
    pHdrJ.SignType := 4;
    ZeroMemory(@pHdrJ.Signature, 16);
    MoveMemory(@pHdrJ.Signature[0], @pHdrJ.TerminalID[0], 8);
    MoveMemory(@pHdrJ.Signature[9], @pHdrJ.SessionNumber[0], 4);
    MoveMemory(@pHdrJ.Signature[13], @pHdrJ.MessageNumber[0], 2);
    Digest := MD5Memory(@OutputBuffer[0], Size);
    MoveMemory(@pHdrJ.Signature, @Digest, 16);
    pHdrJ.SignType := 4;
    AddLog(1, Channel, LinkNumber, 'REQ: S='+IntToStr(Session)+' ('+IntToStr(Size)+')');
    if (Channel <= 8) and (MsgNum = 0) then
      EmptyCounter2[Channel] := 0;
  end
  else if (HdrType = ord('C')) or (HdrType = ord('B')) then
  begin
    Size := Sizeof(TUpstreamHeaderC);
    pHdrC := PUpstreamHeaderC(@OutputBuffer[0]);
    pHdrC.MessageFormat := Ord('C');
    pHdrC.MessageType := Ord(MSG_TYPE_REQUEST);
    pHdrC.HeaderLength := Size;
    MoveMemory(@OutputBuffer[Size], Buffer, Length);
    Size := Size + Length;
    IntToBCD(Size, pHdrC.MessageLength, 4);
    IntToBCD(Host, pHdrC.HostID, 4);
//    Int64ToBCD(TerminalID, pHdr2.TerminalID, 8);
    StrToBCD(ConnectedTerminal[Channel], pHdrC.TerminalID, 8);
    IntToBCD(Session, pHdrC.SessionNumber, 4);
    pHdrC.ChannelNumber := Channel;
    pHdrC.SignType := 0;
    ZeroMemory(@pHdrC.Signature, 16);
    AddLog(1, Channel, LinkNumber, 'REQ: S='+IntToStr(Session)+' ('+IntToStr(Size)+')');
  end
  else
  begin
    Size := Sizeof(TUpstreamHeaderF);
    pHdrF := PUpstreamHeaderF(@OutputBuffer[0]);
    pHdrF.MessageFormat := Ord('F');
    pHdrF.MessageType := Ord(MSG_TYPE_REQUEST);
    pHdrF.HeaderLength := Size;
    MoveMemory(@OutputBuffer[Size], Buffer, Length);
    Size := Size + Length;
    IntToBCD(Size, pHdrF.MessageLength, 4);
    IntToBCD(Host, pHdrF.HostID, 4);
//    Int64ToBCD(TerminalID, pHdr.TerminalID, 16);
    StrToBCD(ConnectedTerminal[Channel], pHdrF.TerminalID, 8);
    IntToBCD(Session, pHdrF.SessionNumber, 4);
    pHdrF.ChannelNumber := Channel;
    pHdrF.StartEnd := 0;
    pHdrF.SignType := 0;
    ZeroMemory(@pHdrF.Signature, 16);
    AddLog(1, Channel, LinkNumber, 'REQ: S='+IntToStr(Session)+' ('+IntToStr(Size)+')');
  end;

  if Size > Sizeof(OutputBuffer) then
  begin
    AddLog(2, Channel, LinkNumber, 'ERR: Request Tag too big (' + IntToStr(Size) + ')');
    Exit;
  end;

  RetVal := Form1.QueueUpstream(LinkNumber, Channel, OutputBuffer, Size);
  if RetVal = 0 then
  begin
//    if (Length > 0) and (KeepAlive[Channel] < 4) then
//      KeepAlive[Channel] := 4;
    if Length > 0 then
      KeepAlive[Channel] := KeepAliveCount;
    // give upstream server time before sending (empty) response to terminal
    // upon arrival of response from upstream TransmitReady will be reduced to 1
    Inc(TransmitReady[Channel], ResponseTime[LinkNumber]);
    Inc(ResponseDue[Channel]);
  end
  else
    AddLog(3, 0, LinkNumber, 'ERR: Upstream Server queue failure (' + IntToStr(RetVal) + ')');
end;

// ****************************************************************************
procedure TestSession(LinkNumber : Integer);
var
  pHdrF : PUpstreamHeaderF;
  pHdrC : PUpstreamHeaderC;
  RetVal : Integer;
  OutputBuffer : Array[0..255] of Byte;
begin
{  pHdrF := PUpstreamHeaderF(@OutputBuffer[0]);
  pHdrF.MessageFormat := Ord('F');
  pHdrF.MessageType := Ord(MSG_TYPE_EMPTY_REQ);
  pHdrF.HeaderLength := Sizeof(TUpstreamHeaderF);
  IntToBCD(0, pHdrF.HostID, 8);
  Int64ToBCD(0, pHdrF.TerminalID, 16);
  IntToBCD(0, pHdrF.SessionNumber, 4);
  IntToBCD(Sizeof(TUpstreamHeaderF), pHdrF.MessageLength, 4);
  pHdrF.ChannelNumber := 1;
  pHdrF.SignType := 0;
  ZeroMemory(@pHdrF.Signature, 16);|}

  pHdrC := PUpstreamHeaderC(@OutputBuffer[0]);
  pHdrC.MessageFormat := Ord('C');
  pHdrC.MessageType := Ord(MSG_TYPE_EMPTY_REQ);
  pHdrC.HeaderLength := Sizeof(TUpstreamHeaderC);
  IntToBCD(0, pHdrC.HostID, 8);
  IntToBCD(0, pHdrC.TerminalID, 8);
  IntToBCD(0, pHdrC.SessionNumber, 4);
  IntToBCD(Sizeof(TUpstreamHeaderC), pHdrC.MessageLength, 4);
  pHdrC.ChannelNumber := 0;
  pHdrC.SignType := 0;
  ZeroMemory(@pHdrC.Signature, 16);

//  RetVal := Form1.QueueUpstream(LinkNumber, 0, OutputBuffer, Sizeof(TUpstreamHeaderF));
  RetVal := Form1.QueueUpstream(LinkNumber, 0, OutputBuffer, Sizeof(TUpstreamHeaderC));
  if RetVal = 0 then
    AddLog(1, 0, LinkNumber, 'REQ: Empty Message (Echo Test)')
  else
    AddLog(2, 0, LinkNumber, 'REQ: Test Message send failure (' + IntToStr(RetVal) + ')');
end;

// ****************************************************************************
procedure SendPing(LinkNumber : Integer);
var
  pHdrA : PUpstreamHeaderA;
  pHdrF : PUpstreamHeaderF;
  RetVal,Size : Integer;
  OutputBuffer : Array[0..255] of Byte;
begin
  if PingType[LinkNumber] = 'A' then
  begin
    pHdrA := PUpstreamHeaderA(@OutputBuffer[0]);
    pHdrA.MessageFormat := Ord('A');
    pHdrA.MessageType := Ord(MSG_TYPE_PING_REQ);
    pHdrA.HeaderLength := Sizeof(TUpstreamHeaderA);
    IntToBCD(0, pHdrA.HostID, 4);
    IntToBCD(0, pHdrA.ChannelNumber, 4);
    IntToBCD(Sizeof(TUpstreamHeaderA), pHdrA.MessageLength, 4);
    pHdrA.SignType := 0;
    ZeroMemory(@pHdrA.Signature, 16);
    Size := Sizeof(TUpstreamHeaderA);
  end
  else
  begin
    pHdrF := PUpstreamHeaderF(@OutputBuffer[0]);
    pHdrF.MessageFormat := Ord('F');
    pHdrF.MessageType := Ord(MSG_TYPE_PING_REQ);
    pHdrF.HeaderLength := Sizeof(TUpstreamHeaderF);
    IntToBCD(0, pHdrF.HostID, 4);
    Int64ToBCD(0, pHdrF.TerminalID, 16);
    IntToBCD(0, pHdrF.SessionNumber, 4);
    IntToBCD(Sizeof(TUpstreamHeaderF), pHdrF.MessageLength, 4);
    pHdrF.ChannelNumber := 0;
    pHdrF.SignType := 0;
    ZeroMemory(@pHdrF.Signature, 16);
    Size := Sizeof(TUpstreamHeaderF);
  end;

  RetVal := Form1.QueueUpstream(LinkNumber, 0, OutputBuffer, Size);
  if RetVal = 0 then
    AddLog(0, 0, LinkNumber, 'REQ: Ping Message')
  else
    AddLog(2, 0, LinkNumber, 'REQ: Ping send failure (' + IntToStr(RetVal) + ')');
end;

end.
