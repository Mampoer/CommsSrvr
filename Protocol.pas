unit Protocol;

{$MODE Delphi}

interface

  uses
    StdCtrls, Classes, LCLIntf, LCLType, LMessages, SyncObjs, SysUtils, StrUtils,
    SysDef, Unit1;

  var
    // variables associated with Terminal Sessions, 1..8 for COM Ports, 9..MAX_CHANNELS for TCP sessions
    CallTimer : Array[0..MAX_CHANNELS+1] of Integer;
    TerminateCall : Array[0..MAX_CHANNELS+1] of Integer;
    KeepAlive : Array[0..MAX_CHANNELS+1] of Integer;
    HeaderType : Array[0..MAX_CHANNELS+1] of Byte;
    TransmitLength : Array[0..MAX_CHANNELS+1] of Integer;
    TransmitBuffer : Array[0..MAX_CHANNELS+1, 0..8200] of Byte;
    TransmitReady : Array[0..MAX_CHANNELS+1] of Integer;
    PlacedAnOrder : Array[0..MAX_CHANNELS+1] of Boolean;
    SessionSequence : Array[0..MAX_CHANNELS+1] of Integer;
    MaxChannels : Integer;

  procedure Startup;
  procedure TerminalConnected(PortNum : Integer);
  function HandleMessage(PortNum, Count : Integer; Buffer : Array of Byte) : Boolean;
  procedure BuildMessage(PortNum : Integer);

implementation

uses
  INIFile, LogList, Upstream, md5, FIFOList, FIFOList2;

const
  MAX_XMT_LENGTH = 900;


var
  // variables associated with Terminal Sessions, 1..8 for COM Ports, 9..MAX_CHANNELS for TCP sessions
  AuthenticateDownstream : Array[1..MAX_CHANNELS+1] of Boolean;
  ReceiveSequence : Array[1..MAX_CHANNELS+1] of Integer;
  TransmitSequence : Array[1..MAX_CHANNELS+1] of Integer;
  TransmitCount : Array[1..MAX_CHANNELS+1] of Integer;
  SerialNumber : Array[1..MAX_CHANNELS+1, 0..14] of Byte;

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
procedure GetStateOfHealth(PortNum,Count : Integer; Buffer : Array of Byte);
var
  pHdr : PUpstreamHeaderC;
  pTag : PMessageTag;
  pReqTag : PTagSOHRequest;
  pRspTag : PTagSOHResponse;
  pCmdTag : PTagSOHCommand;
  pCnfTag : PTagSOHConfirmation;
  pQryTag : PTagSOHQuery;
  RetVal,Size,Offset,Link : Integer;
  sTagType : String;
  status,events : String;
  str : String;
  ndx : Integer;
begin
  if (PortNum < 1) or (PortNum > MaxChannels) then
  begin
    AddLog(3, 1, 0, 'ERR: Invalid channel number '+IntToStr(PortNum)+' in GetStateOfHealth() call');
    Exit;
  end;

{
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
}
  pHdr := PUpstreamHeaderC(@Buffer[0]);
  BCDToInt(pHdr.MessageLength, Size, 2);
  if Size <> Count then
    Exit;
  if pHdr.HeaderLength >= Size - 4 then
    Exit;
  if pHdr.HeaderLength < 14 then
    Exit;

  Offset := pHdr.HeaderLength;
  while (Offset < Count) do
  begin
    pTag := PMessageTag(@Buffer[Offset]);
    BCDToInt(pTag.TagLength, Size, 2);
    if Offset + Size > Count then
    begin
      AddLog(2, PortNum, 0, 'MONITOR: Tag overflow in received message');
      break;
    end;
    SetString(sTagType, PChar(@pTag.TagType), 2);
    if sTagType = TAG_TYPE_SOH_REQUEST then
    begin
      pReqTag := PTagSOHRequest(@Buffer[Offset]);

      if pReqTag.UpstreamOption = 0 then
      begin
        // our status requested
        str := '';
        for ndx:=9 to MaxChannels do
        begin
          if ChannelInUse[ndx] then
            str := str + 'O'
          else
            str := str + '.'
        end;

        status := InstanceName + 'Communication Server V' + VERSION_NUMBER + #13+#10 + #13+#10;
        status := status + '      Realtime Clock: ' + FormatDateTime('yyyy-mm-dd hh:mm:ss', Now) + #13+#10;
        status := status + '       Alive Counter: ' + IntToStr(AliveCounter) + #13+#10;
        status := status + '   Connected Clients: ' + IntToStr(ConnectedClients) + #13+#10;
        status := status + '   ' + str + #13+#10;
        status := status + '     Connect Counter: ' + IntToStr(ConnectCounter) + #13+#10;
        status := status + '     Upstream Link 1: ' + Form1.staUpstream1.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 2: ' + Form1.staUpstream2.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 3: ' + Form1.staUpstream3.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 4: ' + Form1.staUpstream4.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 5: ' + Form1.staUpstream5.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 6: ' + Form1.staUpstream6.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 7: ' + Form1.staUpstream7.Caption.Caption + #13+#10;
        status := status + '     Upstream Link 8: ' + Form1.staUpstream8.Caption.Caption + #13+#10;

        if (pReqTag.ReportingLevel < 1) or (pReqTag.ReportingLevel > 3) then
          events := 'Invalid Reporting Level requested ('+IntToStr(pReqTag.ReportingLevel)+')'
        else
          events := LogGetLine(pReqTag.ReportingLevel);

        // echo the header
        MoveMemory(@TransmitBuffer[PortNum][0], @Buffer[0], pHdr.HeaderLength);
        pHdr := PUpstreamHeaderC(@TransmitBuffer[PortNum][0]);
        // build response tag
        pRspTag := PTagSOHResponse(@TransmitBuffer[PortNum][pHdr.HeaderLength]);
        StrArr(TAG_TYPE_SOH_RESPONSE, pRspTag.TagType, 2);
        pRspTag.TagFormat := ord('A');
        if pReqTag.TagFormat = ord('A') then
          pRspTag.SequenceNumber :=  pReqTag.SequenceNumber
        else
          pRspTag.SequenceNumber := 0;

        Size := pHdr.HeaderLength + Sizeof(TTagSOHResponse);
        if Size + Length(status) + 10 >= Sizeof(TransmitBuffer[PortNum]) then
          RetVal := Sizeof(TransmitBuffer[PortNum]) - Size - 10
        else
          RetVal := Length(status)+1;
        IntToBCD(RetVal, pRspTag.StatusLength, 4);
        StrArr(RightStr(status, RetVal), TransmitBuffer[PortNum][Size], RetVal);
        Size := Size + RetVal;

        if Size + Length(events) + 10 >= Sizeof(TransmitBuffer[PortNum]) then
          RetVal := Sizeof(TransmitBuffer[PortNum]) - Size - 10
        else
          RetVal := Length(events)+1;
        IntToBCD(RetVal, pRspTag.EventsLength, 4);
        StrArr(RightStr(events, RetVal), TransmitBuffer[PortNum][Size], RetVal);
        Size := Size + RetVal;

        IntToBCD(Size, pHdr.MessageLength, 4);
        IntToBCD(Size-pHdr.HeaderLength, pRspTag.TagLength, 4);

        TransmitLength[PortNum] := Size;
        Form1.TransmitMessage(PortNum);
        TransmitReady[PortNum] := 0;
        Exit;
      end
      else
      begin
        // ship upstream
        Link := (pReqTag.UpstreamOption and $0F);
        if Link = 0 then Link := 1;
        if (Link >= 1) and (Link <= 8) then
        begin
          pHdr.ChannelNumber := PortNum;
          pReqTag.UpstreamOption := 0;
          Form1.QueueUpstream(Link, PortNum, Buffer, Count);
          if (KeepAlive[PortNum] > 0) and (KeepAlive[PortNum] < 4) then
            KeepAlive[PortNum] := 4;
          Inc(TransmitReady[PortNum], ResponseTime[Link]);
          Inc(ResponseDue[PortNum]);
        end;
        Exit;
      end;
    end;

    if sTagType = TAG_TYPE_SOH_COMMAND then
    begin
      pCmdTag := PTagSOHCommand(@Buffer[pHdr.HeaderLength]);

      if pCmdTag.UpstreamOption = 0 then
      begin
        // echo the header
        MoveMemory(@TransmitBuffer[PortNum][0], @Buffer[0], pHdr.HeaderLength);
        pHdr := PUpstreamHeaderC(@TransmitBuffer[PortNum][0]);
        // build response tag
        pCnfTag := PTagSOHConfirmation(@TransmitBuffer[PortNum][pHdr.HeaderLength]);
        StrArr(TAG_TYPE_SOH_CONFIRMATION, pCnfTag.TagType, 2);
        pCnfTag.TagFormat := ord('A');
        if pCnfTag.TagFormat = ord('A') then
          pCnfTag.SequenceNumber :=  pCmdTag.SequenceNumber
        else
          pCnfTag.SequenceNumber := 0;
        pCnfTag.CommandCode := pCmdTag.CommandCode;

        Size := pHdr.HeaderLength + Sizeof(TTagSOHConfirmation);

        case pCmdTag.CommandCode of
        ord('B'):
          begin // bounce
            if (ParamCount = 0) or (ParamStr(1) <> 'Bounce') then
            begin
              pCnfTag.ResultCode[0] := $FF;
              pCnfTag.ResultCode[1] := $F7;
            end
            else
            begin
              if (ParamCount > 1) and (StrToIntDef(ParamStr(2), -1) > 0) then
              begin
                Link := StrToIntDef(ParamStr(2), -1);
                case Link of
                1:
                  begin
                    if UseUpstream[1] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 1 command received');
                      Form1.IdTCPUpstream1.Disconnect;
                      Form1.ShowStatus(1001, STA_HANGUP);
                      LinkConState[1] := CON_DISCONNECTED;
                      LinkTimer[1] := TICKSPERSECOND;
                    end;
                  end;
                2:
                  begin
                    if UseUpstream[2] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 2 command received');
                      Form1.IdTCPUpstream2.Disconnect;
                      Form1.ShowStatus(1002, STA_HANGUP);
                      LinkConState[2] := CON_DISCONNECTED;
                      LinkTimer[2] := TICKSPERSECOND;
                    end;
                  end;
                3:
                  begin
                    if UseUpstream[3] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 3 command received');
                      Form1.IdTCPUpstream3.Disconnect;
                      Form1.ShowStatus(1003, STA_HANGUP);
                      LinkConState[3] := CON_DISCONNECTED;
                      LinkTimer[3] := TICKSPERSECOND;
                    end;
                  end;
                4:
                  begin
                    if UseUpstream[4] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 4 command received');
                      Form1.IdTCPUpstream4.Disconnect;
                      Form1.ShowStatus(1004, STA_HANGUP);
                      LinkConState[4] := CON_DISCONNECTED;
                      LinkTimer[4] := TICKSPERSECOND;
                    end;
                  end;
                5:
                  begin
                    if UseUpstream[4] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 5 command received');
                      Form1.IdTCPUpstream5.Disconnect;
                      Form1.ShowStatus(1005, STA_HANGUP);
                      LinkConState[5] := CON_DISCONNECTED;
                      LinkTimer[5] := TICKSPERSECOND;
                    end;
                  end;
                6:
                  begin
                    if UseUpstream[6] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 6 command received');
                      Form1.IdTCPUpstream6.Disconnect;
                      Form1.ShowStatus(1006, STA_HANGUP);
                      LinkConState[6] := CON_DISCONNECTED;
                      LinkTimer[6] := TICKSPERSECOND;
                    end;
                  end;
                7:
                  begin
                    if UseUpstream[7] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 7 command received');
                      Form1.IdTCPUpstream7.Disconnect;
                      Form1.ShowStatus(1007, STA_HANGUP);
                      LinkConState[7] := CON_DISCONNECTED;
                      LinkTimer[7] := TICKSPERSECOND;
                    end;
                  end;
                8:
                  begin
                    if UseUpstream[8] then
                    begin
                      AddLog(3, PortNum, 0, 'MONITOR: Bounce Link 8 command received');
                      Form1.IdTCPUpstream8.Disconnect;
                      Form1.ShowStatus(1008, STA_HANGUP);
                      LinkConState[8] := CON_DISCONNECTED;
                      LinkTimer[8] := TICKSPERSECOND;
                    end;
                  end;
                end;
              end;
              pCnfTag.ResultCode[0] := 0;
              pCnfTag.ResultCode[1] := 0;
            end;
          end;
        else
          pCnfTag.ResultCode[0] := $FF;
          pCnfTag.ResultCode[1] := $FF;
        end;

        IntToBCD(Size, pHdr.MessageLength, 4);
        IntToBCD(Size-pHdr.HeaderLength, pCnfTag.TagLength, 4);

        TransmitLength[PortNum] := Size;
        Form1.TransmitMessage(PortNum);
        TransmitReady[PortNum] := 0;
        Exit;
      end
      else
      begin
        // ship upstream
        Link := (pCmdTag.UpstreamOption and $0F);
        if Link = 0 then Link := 1;
        if (Link >= 1) and (Link <= 8) then
        begin
          pHdr.ChannelNumber := PortNum;
          pCmdTag.UpstreamOption := 0;
          Form1.QueueUpstream(Link, PortNum, Buffer, Count);
//          if KeepAlive[PortNum] < 4 then
          if (KeepAlive[PortNum] > 0) and (KeepAlive[PortNum] < 4) then
            KeepAlive[PortNum] := 4;
          Inc(TransmitReady[PortNum], ResponseTime[Link]);
          Inc(ResponseDue[PortNum]);
        end;
        Exit;
      end;
    end
    else
    begin
      pQryTag := PTagSOHQuery(@Buffer[pHdr.HeaderLength]);
      if pQryTag.UpstreamOption > 0 then
      begin
        // ship upstream
        Link := (pQryTag.UpstreamOption and $0F);
        if Link = 0 then Link := 1;
        if (Link >= 1) and (Link <= 8) then
        begin
          pHdr.ChannelNumber := PortNum;
          pQryTag.UpstreamOption := 0;
          Form1.QueueUpstream(Link, PortNum, Buffer, Count);
//          if KeepAlive[PortNum] < 4 then
          if (KeepAlive[PortNum] > 0) and (KeepAlive[PortNum] < 4) then
            KeepAlive[PortNum] := 4;
          Inc(TransmitReady[PortNum], ResponseTime[Link]);
          Inc(ResponseDue[PortNum]);
        end;
        Exit;
      end;
    end;

    BCDToInt(pTag.TagLength, Size, 2);
    Offset := Offset + Size;
  end;
end;

// ****************************************************************************
procedure BuildMessage(PortNum : Integer);
// time to ship something to terminal
var
  Item : TItem2;
  pHdrC : PUpstreamHeaderC;
  pHdrE : PMessageHeaderE;
  pHdr1 : PMessageHeader1;
  pHdr2 : PMessageHeader2;
  pHdrJ : PMessageHeaderJ;
  sDspTxt : String;
  i,j,size : Integer;
  BitFlags : Byte;
begin
  if (PortNum < 1) or (PortNum > MaxChannels) then
  begin
    AddLog(3, 1, 0, 'ERR: Invalid channel number '+IntToStr(PortNum)+' in BuildMessage() call');
    Exit;
  end;

  // limit on number of messages per session
  TransmitCount[PortNum] := TransmitCount[PortNum] + 1;
  if TransmitCount[PortNum] > 800 then
    Exit;

  pHdrC := PUpstreamHeaderC(@TransmitBuffer[PortNum]);
  pHdrE := PMessageHeaderE(@TransmitBuffer[PortNum]);
  pHdr1 := PMessageHeader1(@TransmitBuffer[PortNum]);
  pHdr2 := PMessageHeader2(@TransmitBuffer[PortNum]);
  pHdrJ := PMessageHeaderJ(@TransmitBuffer[PortNum]);

  // check if previous message was acknowledged
  if TransmitLength[PortNum] > 0 then
  begin
    // not yet
    if (HeaderType[PortNum] = ord('C')) or (HeaderType[PortNum] = ord('A')) then
    begin
      TransmitLength[PortNum] := 0; // do not retransmit to RemoteMonitor
    end
    else
    begin
      // retransmit previous message
      if HeaderType[PortNum] = ord('J') then
      begin
        BCDToInt(pHdrJ.MessageNumber, i, 2);
        BCDToInt(pHdrJ.MessageLength, j, 2);
      end
      else
      begin
        BCDToInt(pHdrE.MessageNumber, i, 2);
        BCDToInt(pHdrE.MessageLength, j, 2);
      end;
      AddLog(2, PortNum, 0, 'XMT: Retransmitting... ['+IntToStr(i)+','+IntToStr(TransmitLength[PortNum])+','+IntToStr(j)+']');
      Form1.TransmitMessage(PortNum);
      Exit;
    end;
  end;

  // each outgoing message will get us closer to the end of the session
  if KeepAlive[PortNum] > 0 then
    KeepAlive[PortNum] := KeepAlive[PortNum] - 1;

  // populate outgoing message header
  if HeaderType[PortNum] = ord('B') then
  begin
    pHdr1.MessageFormat := Ord('B');
    pHdr1.MessageType := Ord(MSG_TYPE_DATA);
    IntToBCD(SessionSequence[PortNum], pHdr1.SessionNumber, 4);
    IntToBCD(TransmitSequence[PortNum], pHdr1.MessageNumber, 4);
    IntToBCD(ReceiveSequence[PortNum], pHdr1.NxtMsgExp, 4);
    pHdr1.StartEnd := $00;
    StrToBCD(ConnectedTerminal[PortNum], pHdr1.TerminalID, 8);
    pHdr1.SignType := 0;
    ZeroMemory(@pHdr1.Signature, 16);
    if AuthenticateDownstream[PortNum] then
      size := Sizeof(TMessageHeader1)
    else
      size := Sizeof(TMessageHeader2);
    pHdr1.HeaderLength := size;
    IntToBCD(size, pHdr1.MessageLength, 4);
  end
  else if HeaderType[PortNum] = ord('A') then
  begin
    // header already present
    size := 0;
  end
  else if HeaderType[PortNum] = ord('C') then
  begin
    // Remote Monitor session
    size := Sizeof(TUpstreamHeaderC);
    ZeroMemory(@TransmitBuffer[PortNum], size);
    pHdrC.MessageFormat := Ord('C');
    pHdrC.MessageType := ord(MSG_TYPE_SUPERVISORY);
    pHdrC.HeaderLength := size;
    IntToBCD(size, pHdrC.MessageLength, 4);
  end
  else if HeaderType[PortNum] = ord('J') then
  begin
    pHdrJ.MessageFormat := Ord('J');
    pHdrJ.MessageType := Ord(MSG_TYPE_DATA);
    IntToBCD(0, pHdrJ.ChannelNumber, 4);
    IntToBCD(PortNum, pHdrJ.ChannelNumber, 4);
    StrArr(ConnectedSerial[PortNum], pHdrJ.SerialNumber, 15);
    StrArr(ConnectedTerminal[PortNum], pHdrJ.TerminalID, 8);
    IntToBCD(SessionSequence[PortNum], pHdrJ.SessionNumber, 8);
    IntToBCD(TransmitSequence[PortNum], pHdrJ.MessageNumber, 4);
    IntToBCD(ReceiveSequence[PortNum], pHdrJ.NxtMsgExp, 4);
    if KeepAlive[PortNum] = -1 then
      pHdrJ.BitFlags := $02
    else
      pHdrJ.BitFlags := $00;
    pHdrJ.FieldCount := 0;
    pHdrJ.SignType := 0;
    ZeroMemory(@pHdrJ.Signature, 16);
    size := Sizeof(TMessageHeaderJ);
    pHdrJ.HeaderLength := size;
    IntToBCD(size, pHdrJ.MessageLength, 4);
  end
  else
  begin
    pHdrE.MessageFormat := Ord('E');
    pHdrE.MessageType := Ord(MSG_TYPE_DATA);
    IntToBCD(SessionSequence[PortNum], pHdrE.SessionNumber, 4);
    IntToBCD(TransmitSequence[PortNum], pHdrE.MessageNumber, 4);
    IntToBCD(ReceiveSequence[PortNum], pHdrE.NxtMsgExp, 4);
    if KeepAlive[PortNum] = -1 then
      pHdrE.StartEnd := $02
    else
      pHdrE.StartEnd := $00;
    StrToBCD(ConnectedTerminal[PortNum], pHdrE.TerminalID, 16);
    pHdrE.SignType := 0;
    ZeroMemory(@pHdrE.Signature, 16);
    size := Sizeof(TMessageHeaderE);
    pHdrE.HeaderLength := size;
    IntToBCD(size, pHdrE.MessageLength, 4);
  end;

  if HeaderType[PortNum] <> ord('A') then
    sDspTxt := 'S=' + IntToStr(SessionSequence[PortNum]) + ', M=' + IntToStr(TransmitSequence[PortNum]);

  // find payload
  if channelFIFO[PortNum].RemoveItem(Item) then
  begin
    if (Item.Size <= 8192) and (size+Item.Size < SizeOf(TransmitBuffer[PortNum])) then
    begin
      MoveMemory(@TransmitBuffer[PortNum][size], @Item.Buffer, Item.Size);
      TransmitLength[PortNum] := size + Item.Size;
      AddLog(1, PortNum, 0, 'XMT: '+sDspTxt+' ('+IntToStr(TransmitLength[PortNum])+')');
    end
    else
    begin
      TransmitLength[PortNum] := size;
      AddLog(2, PortNum, 0, 'XMT: EmptyMessage PAYLOAD DISCARDED, '+sDspTxt+' ('+IntToStr(Item.Size)+')');
    end;
    // update message length
    IntToBCD(TransmitLength[PortNum], pHdr1.MessageLength, 4);
    // ship it
    Form1.TransmitMessage(PortNum);
    if (HeaderType[PortNum] = ord('C')) or (HeaderType[PortNum] = ord('A')) then
      TransmitLength[PortNum] := 0;
    Exit;
  end;

  // flag end of session if nothing more to say
  if KeepAlive[PortNum] <= 0 then
  begin
    i := pHdr1.StartEnd;
    if HeaderType[PortNum] = ord('B') then
    begin
      pHdr1.StartEnd := $02;
      i := pHdr1.StartEnd;
    end
    else if HeaderType[PortNum] = ord('E') then
    begin
      pHdrE.StartEnd := $02;
      i := pHdrE.StartEnd;
    end
    else if HeaderType[PortNum] = ord('J') then
    begin
      pHdrJ.BitFlags := $02;
      i := pHdrJ.BitFlags;
    end;
    if (TerminateCall[PortNum] = 1) or (PortNum <= 8) then
    begin
      if DebugMode > 3 then
        AddLog(0, PortNum, 0, '...terminating connection... '+IntToStr(TerminateCall[PortNum]));
      CallTimer[PortNum] := 0;
      if TerminateCall[PortNum] < 2 then
        TerminateCall[PortNum] := 2;
    end;
    i := pHdrE.StartEnd;
    AddLog(1, PortNum, 0, 'XMT: Close '+sDspTxt+' 0x'+IntToHex(i, 2)+' '+IntToStr(TerminateCall[PortNum]));
  end
  else
  begin
    Inc(EmptyCounter1[PortNum]);
    if EmptyCounter1[PortNum] > 10 then
    begin
      AddLog(1, PortNUm, 0, 'XMT: No downstream activity, dropping connection '+IntToStr(TerminateCall[PortNum]));
      CallTimer[PortNum] := 0;
      KeepAlive[PortNum] := -1;
      if TerminateCall[PortNum] < 2 then
        TerminateCall[PortNum] := 2;
      Exit;
    end
    else
      AddLog(1, PortNum, 0, 'XMT: Empty '+sDspTxt+' '+IntToStr(TerminateCall[PortNum])+' '+IntToStr(EmptyCounter1[PortNum]));
  end;

  // ship empty message
  TransmitLength[PortNum] := size;
  IntToBCD(TransmitLength[PortNum], pHdrE.MessageLength, 4);
  Form1.TransmitMessage(PortNum);
end;

// ****************************************************************************
function HandleMessage(PortNum, Count : Integer; Buffer : Array of Byte) : Boolean;
var
  pHdrA : PMessageHeaderA;
  pHdrB : PMessageHeaderB;
  pHdrE : PMessageHeaderE;
  pHdrJ : PMessageHeaderJ;
  HdrLen,Size,Offset : Integer;
  sDspTxt : String;
  Host,SesNo,MsgNo,NxtMsg : Integer;
  BitFlags : Byte;
  RetVal,ndx,len : Integer;
  Digest1,Digest2 : MD5Digest;
  pTag : PMessageTag;
  sTagType : String;
  StartBitSet : Boolean;
  EndBitSet : Boolean;
  NewSession : Boolean;
  LinkNumber : Integer;
begin
  Result := True;
  NewSession := False;
  sDspTxt := '';

  if (PortNum < 1) or (PortNum > MaxChannels) then
  begin
    AddLog(3, 1, 0, 'ERR: Invalid channel number '+IntToStr(PortNum)+' in HandleMessage() call');
    Result := False;
    Exit;
  end;

  pHdrA := PMessageHeaderA(@Buffer[0]);
  pHdrB := PMessageHeaderB(@Buffer[0]);
  pHdrE := PMessageHeaderE(@Buffer[0]);
  pHdrJ := PMessageHeaderJ(@Buffer[0]);

  if (pHdrE.MessageFormat = Ord('C')) and (pHdrE.MessageType = ord(MSG_TYPE_SUPERVISORY)) then
  begin
    HeaderType[PortNum] := pHdrE.MessageFormat;
    // RemoteMonitor request
    GetStateOfHealth(PortNum, Count, Buffer);
    Result := True;
    Exit;
  end;

  if (pHdrA.MessageFormat = Ord('A')) and (pHdrA.MessageType = ord(MSG_TYPE_SUPERVISORY)) then
  begin
    HeaderType[PortNum] := pHdrA.MessageFormat;
    // RCMS Request
    BCDToInt(pHdrA.HostID, Host, 2);
    if Host = 0 then
      LinkNumber := 1
    else
      LinkNumber := Host;
    if (LinkNumber >= 1) and (LinkNumber <= 8) then
    begin
      IntToBCD(PortNum, pHdrA.ChannelNumber, 4);
      Form1.QueueUpstream(LinkNumber, PortNum, Buffer, Count);
      Inc(TransmitReady[PortNum], ResponseTime[LinkNumber]);
      Inc(ResponseDue[PortNum]);
    end;
    Result := True;
    Exit;
  end;

  if (pHdrE.MessageFormat <> Ord('E')) and (pHdrJ.MessageFormat <> Ord('J')) and (pHdrB.MessageFormat <> Ord('B')) then
  begin
    sDspTxt := 'RCV ERR: Unknown Message Format ' + IntToHex(pHdrE.MessageFormat, 2) + 'H';
    AddLog(2, PortNum, 0, sDspTxt);
    if PortNum > 8 then
      Result := False
    else
      if TerminateCall[PortNum] < 2 then
        TerminateCall[PortNum] := 2;
    Exit;
  end;
  HeaderType[PortNum] := pHdrE.MessageFormat;

  BCDToInt(pHdrE.MessageLength, Size, 2);
  if Size <> Count then
  begin
    sDspTxt := 'RCV ERR: Message length mismatch (' + IntToStr(Size) + ' vs. ' + IntToStr(Count) + ') ['+IntToHex(pHdrE.MessageType, 2)+']';
    AddLog(2, PortNum, 0, sDspTxt);
    Result := False;
    Exit;
  end;

  HdrLen := pHdrE.HeaderLength;
  StartBitSet := False;
  EndBitSet := False;

  if pHdrB.MessageFormat = Ord('B') then
  begin
    BCDToInt(pHdrB.TerminalID, RetVal, 4);
    ConnectedSerial[PortNum] := '';
    ConnectedTerminal[PortNum] := Format('%8.8d', [RetVal]);
    BCDToInt(pHdrB.HostID, Host, 2);
    BCDToInt(pHdrB.SessionNumber, SesNo, 2);
    BCDToInt(pHdrB.MessageNumber, MsgNo, 2);
    BCDToInt(pHdrB.NxtMsgExp, NxtMsg, 2);
    if HdrLen = Sizeof(TMessageHeader2) then
    begin
      len := Sizeof(TMessageHeader2);
      AuthenticateDownstream[PortNum] := False;
    end
    else
    begin
      len := Sizeof(TMessageHeader1);
      AuthenticateDownstream[PortNum] := True;
    end;
    if (pHdrB.StartEnd and $01) = $01 then
      StartBitSet := True;
    if (pHdrB.StartEnd and $02) = $02 then
      EndBitSet := True;
  end
  else
  begin
    if pHdrE.MessageFormat = Ord('J') then
    begin
      ConnectedSerial[PortNum] := ArrStr(pHdrJ.SerialNumber, 15);
      ConnectedTerminal[PortNum] := ArrStr(pHdrJ.TerminalID, 8);
      BCDToInt(pHdrJ.HostID, Host, 2);
      BCDToInt(pHdrJ.SessionNumber, SesNo, 4);
      BCDToInt(pHdrJ.MessageNumber, MsgNo, 2);
      BCDToInt(pHdrJ.NxtMsgExp, NxtMsg, 2);
      if (pHdrJ.BitFlags and $01) = $01 then
        StartBitSet := True;
      if (pHdrJ.BitFlags and $02) = $02 then
        EndBitSet := True;
      len := Sizeof(TMessageHeaderJ);
    end
    else
    begin
      ConnectedSerial[PortNum] := '';
//      BCDToInt64(pHdrE.TerminalID, TerminalID, 8);
      ConnectedTerminal[PortNum] := BCDStr(pHdrE.TerminalID, 8);
      BCDToInt(pHdrE.HostID, Host, 2);
      BCDToInt(pHdrE.SessionNumber, SesNo, 2);
      BCDToInt(pHdrE.MessageNumber, MsgNo, 2);
      BCDToInt(pHdrE.NxtMsgExp, NxtMsg, 2);
      if (pHdrE.StartEnd and $01) = $01 then
        StartBitSet := True;
      if (pHdrE.StartEnd and $02) = $02 then
        EndBitSet := True;
      len := Sizeof(TMessageHeaderE);
    end;
    AuthenticateDownstream[PortNum] := True;
  end;

  if HdrLen < len then
  begin
    sDspTxt := 'RCV: Header too short (' + IntToStr(HdrLen) + ',' + IntToStr(Count) + ') ['+IntToHex(pHdrE.MessageType, 2)+']';
    AddLog(2, PortNum, 0, sDspTxt);
    Result := False;
    Exit;
  end;

//  if ((pHdrE.StartEnd and $01) = $01) or (SesNo <> SessionSequence[PortNum]) then
  if (SesNo <> SessionSequence[PortNum]) or StartBitSet then
  begin
    Form1.FlushTransmitter(PortNum);
    TransmitLength[PortNum] := 0;
    TransmitCount[PortNum] := 0;
    TransmitSequence[PortNum] := 0;
    ReceiveSequence[PortNum] := 0;
    TerminateCall[PortNum] := 0;
    TransmitReady[PortNum] := 0;
    RequestLength[PortNum] := 0;
    ResponseDue[PortNum] := 0;
    KeepAlive[PortNum] := KeepAliveCount;
    ChannelLink[PortNum] := 0;
    CloseRequested[PortNum] := False;
    channelFIFO[PortNum].Flush;
  end;

  if AuthenticateDownstream[PortNum] then
  begin
    if pHdrB.MessageFormat = Ord('B') then
    begin
      if pHdrB.SignType <> 1 then
      begin
        AddLog(2, PortNum, 0, 'RCV: Authentication required, message discarded');
        Result := False;
        Exit;
      end;
      MoveMemory(@Digest1, @pHdrB.Signature, 16);
      ZeroMemory(@pHdrB.Signature, 16);
      MoveMemory(@pHdrB.Signature[0], @pHdrB.TerminalID[0], 4);
      MoveMemory(@pHdrB.Signature[7], @pHdrB.SessionNumber[0], 2);
      MoveMemory(@pHdrB.Signature[13], @pHdrB.MessageNumber[0], 2);
      Digest2 := MD5Memory(@Buffer, Count);
      if not MD5Match(Digest1, Digest2) then
      begin
        AddLog(2, PortNum, 0, 'RCV: Authentication failed, message discarded');
        Result := False;
        Exit;
      end;
    end
    else if pHdrJ.MessageFormat = Ord('J') then
    begin
      if pHdrJ.SignType <> 4 then
      begin
        AddLog(2, PortNum, 0, 'RCV ERR: Authentication required, message discarded');
        Result := False;
        Exit;
      end;
      MoveMemory(@Digest1, @pHdrJ.Signature, 16);
      ZeroMemory(@pHdrJ.Signature, 16);
      MoveMemory(@pHdrJ.Signature[0], @pHdrJ.TerminalID[0], 8);
      MoveMemory(@pHdrJ.Signature[9], @pHdrJ.SessionNumber[0], 4);
      MoveMemory(@pHdrJ.Signature[13], @pHdrJ.MessageNumber[0], 2);
      Digest2 := MD5Memory(@Buffer, Count);
      if not MD5Match(Digest1, Digest2) then
      begin
        AddLog(2, PortNum, 0, 'RCV: Authentication failed, message discarded');
        Result := False;
        Exit;
      end;
    end
    else
    begin
      if (pHdrE.SignType <> 1) and (pHdrE.SignType <> 2)  and (pHdrE.SignType <> 3) then
      begin
        AddLog(2, PortNum, 0, 'RCV: Authentication required, message discarded');
        Result := False;
        Exit;
      end;
      MoveMemory(@Digest1, @pHdrE.Signature, 16);
      ZeroMemory(@pHdrE.Signature, 16);
      if pHdrE.SignType = 1 then
      begin
        MoveMemory(@pHdrE.Signature[0], @pHdrE.TerminalID[4], 12);
        MoveMemory(@pHdrE.Signature[12], @pHdrE.SessionNumber[0], 2);
        MoveMemory(@pHdrE.Signature[14], @pHdrE.MessageNumber[0], 2);
      end
      else if pHdrE.SignType = 3 then
      begin
        MoveMemory(@pHdrE.Signature[0], @pHdrE.TerminalID[0], 8);
        MoveMemory(@pHdrE.Signature[8], @pHdrE.HostID[0], 2);
        MoveMemory(@pHdrE.Signature[10], @pHdrE.NxtMsgExp[0], 2);
        MoveMemory(@pHdrE.Signature[12], @pHdrE.SessionNumber[0], 2);
        MoveMemory(@pHdrE.Signature[14], @pHdrE.MessageNumber[0], 2);
      end;
      Digest2 := MD5Memory(@Buffer, Count);
      if not MD5Match(Digest1, Digest2) then
      begin
        AddLog(2, PortNum, 0, 'RCV: Authentication failed, message discarded');
        Result := False;
        Exit;
      end;
    end;
  end;

  sDspTxt := 'RCV: S=' + IntToStr(SesNo) + ', M=' + IntToStr(MsgNo) + ', N=' + IntToStr(NxtMsg);
  if Host > 0 then
    sDspTxt := sDspTxt + ', H=' + IntToStr(Host);
    
  sDspTxt := sDspTxt + ' (' + IntToStr(Count) + ')';

  if EndBitSet then
  begin
//AddLog(0, PortNUm, 0, '...close request... '+IntToStr(TerminateCall[PortNum]));
    if TerminateCall[PortNum] = 0 then
    begin
      TerminateCall[PortNum] := 1;
    end;
    sDspTxt := sDspTxt + ' (end)';
  end;

  AddLog(1, PortNum, 0, sDspTxt);

  SessionSequence[PortNum] := SesNo;

  if NxtMsg = ((TransmitSequence[PortNum] + 1) mod 10000) then
  begin
    TransmitSequence[PortNum] := (TransmitSequence[PortNum] + 1) mod 10000;
    TransmitLength[PortNum] := 0;
  end;

  if MsgNo <> ReceiveSequence[PortNum] then
  begin
    sDspTxt := '  SEQ ERR: Unexpected sequence number (' + IntToStr(MsgNo) + ' vs. ' + IntToStr(ReceiveSequence[PortNum]) + ')';
    AddLog(2, PortNum, 0, sDspTxt);
    TransmitReady[PortNum] := 1;  // allow retransmit
//    Result := False;
    Exit;
  end;

  ReceiveSequence[PortNum] := (ReceiveSequence[PortNum] + 1) mod 10000;

  // forward messages to Upstream Server
  if UseUpstream[1] or UseUpstream[2] or UseUpstream[3] or UseUpstream[4] or
     UseUpstream[5] or UseUpstream[6] or UseUpstream[7] or UseUpstream[8] then
  begin
    UpstreamRequest(PortNum, SesNo, Host, MsgNo, NxtMsg, pHdrB.MessageFormat, BitFlags, @Buffer[HdrLen], Size - HdrLen);
  end;
end;

// ****************************************************************************
procedure TerminalConnected(PortNum : Integer);
begin
  if (PortNum < 1) or (PortNum > MaxChannels) then
  begin
    AddLog(3, 1, 0, 'ERR: Invalid channel number '+IntToStr(PortNum)+' in TerminalConnected() call');
    Exit;
  end;
//AddLog(0, PortNum, 0, '...terminal connected... '+IntToStr(TerminateCall[PortNum]));

  TerminateCall[PortNum] := 0;
  TransmitLength[PortNum] := 0;
  TransmitCount[PortNum] := 0;
  TransmitSequence[PortNum] := 0;
  ReceiveSequence[PortNum] := 0;
  TransmitReady[PortNum] := 0;
  RequestLength[PortNum] := 0;
  AuthenticateDownstream[PortNum] := True;
  PlacedAnOrder[PortNum] := False;
  ChannelLink[PortNum] := 0;
  ZeroMemory(@SerialNumber[PortNum], 15);
  channelFIFO[PortNum].Flush;
end;

// ****************************************************************************
procedure Startup;
var
  i : Integer;
begin
  for i := 1 to MAX_CHANNELS do
  begin
    CallTimer[i] := 0;
    TerminateCall[i] := 0;
    TransmitLength[i] := 0;
    TransmitSequence[i] := 0;
    ReceiveSequence[i] := 0;
    SessionSequence[i] := 0;
    TransmitReady[i] := 0;
    HeaderType[i] := 0;
    ChannelLink[i] := 0;
    ChannelInUse[i] := False;
  end;
end;

end.
