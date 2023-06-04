unit Frames;

{$MODE Delphi}

interface

uses
  SysDef, CalcCrc, LogList, SysUtils;

type
  TReceiveState = record
    State : Integer;
    Index : Integer;
    CRC : Integer;
    LRC : Byte;
  end;

function BuildTransmitFrame(UseCRC : Boolean;
                            var TransmitData : Array of Byte;
                            var TransmitFrame : Array of Byte;
                            Length, MaxLength : Integer) : Integer;
procedure AcceptReceiveFrame(var ReceiveState : TReceiveState);
function DecodeReceiveStream(UseCRC : Boolean;
                             ReceiveByte : Byte;
                             var ReceiveState : TReceiveState;
                             var ReceiveData : Array of Byte;
                             MaxLength : Integer) : Integer;

implementation

const
  // Defines for receive_state_machine
  RCV_IDLE = 0;
  RCV_ARM  = 1;
  RCV_DLE  = 2;
  RCV_STX  = 3;
  RCV_DAT  = 4;
  RCV_ETX  = 5;
  RCV_RDY  = 7;
  RCV_OVR  = 8;
  RCV_CRC1 = 9;
  RCV_CRC2 = 10;
  RCV_LRC = 11;

  ASCII_STX = $02;
  ASCII_ETX = $03;
  ASCII_DLE = $10;
  ASCII_SYN = $16;


procedure AddLog(sData: String);
begin
  LogPutLine(2, 'DEBUG> '+sData);
end;

// ******************************************************
function BuildTransmitFrame(UseCRC : Boolean;
                            var TransmitData : Array of Byte;
                            var TransmitFrame : Array of Byte;
                            Length, MaxLength : Integer) : Integer;
var
  i,j : Integer;
  crc : Word;
  lrc : Byte;
  b : Byte;
begin
  if Length + 8 > MaxLength then
  begin
    Result := ERR_OVERFLOW;
    Exit;
  end;
  crc := 0;
  lrc := 0;
  TransmitFrame[0] := ASCII_SYN;
  TransmitFrame[1] := ASCII_SYN;
  TransmitFrame[2] := ASCII_DLE;
  TransmitFrame[3] := ASCII_STX;
  j := 4;
  for i := 0 to Length-1 do
  begin
    b := Byte(TransmitData[i]);
    if b = ASCII_DLE then
    begin
      TransmitFrame[j] := ASCII_DLE;
      inc(j);
    end;
    TransmitFrame[j] := b;
    inc(j);
    if j+4 >= MaxLength then
    begin
      Result := ERR_OVERFLOW;
      Exit;
    end;
    if UseCRC then
      crc := crc16(crc, b)
    else
      lrc := lrc xor b;
  end;
  TransmitFrame[j] := ASCII_DLE;
  inc(j);
  TransmitFrame[j] := ASCII_ETX;
  inc(j);
  if UseCRC then
  begin
    crc := crc16(crc, ASCII_ETX);
    TransmitFrame[j] := crc and $ff;
    inc(j);
    TransmitFrame[j] := crc shr 8;
    inc(j);
  end
  else
  begin
    lrc := lrc xor ASCII_ETX;
    TransmitFrame[j] := lrc;
    inc(j);
  end;
  Result := j;
end;

// ******************************************************
procedure AcceptReceiveFrame(var ReceiveState : TReceiveState);
begin
  with ReceiveState do
  begin
    State := RCV_ARM;
    Index := 0;
    CRC := 0;
    LRC := 0;
  end;
end;

// ******************************************************
function DecodeReceiveStream(UseCRC : Boolean;
                             ReceiveByte : Byte;
                             var ReceiveState : TReceiveState;
                             var ReceiveData : Array of Byte;
                             MaxLength : Integer) : Integer;
begin
  Result := 0;
  case ReceiveState.State of
    RCV_ARM:
      begin
        if (ReceiveByte = ASCII_SYN) then
          ReceiveState.State := RCV_DLE
        else
          if not UseCRC and (ReceiveByte = ASCII_DLE) then
            ReceiveState.State := RCV_STX;
      end;
    RCV_DLE:
      if (ReceiveByte = ASCII_DLE) then
        ReceiveState.State := RCV_STX
      else
        if (ReceiveByte <> ASCII_SYN) then
          ReceiveState.State := RCV_ARM;
    RCV_STX:
      if (ReceiveByte = ASCII_STX) then
      begin
        ReceiveState.CRC := 0;
        ReceiveState.LRC := 0;
        ReceiveState.Index := 0;
        ReceiveState.State := RCV_DAT;
      end
      else
        ReceiveState.State := RCV_ARM;
    RCV_DAT:
      if (ReceiveByte = ASCII_DLE) then
        ReceiveState.State := RCV_ETX
      else
        if ReceiveState.Index >= MaxLength then
        begin
          ReceiveState.State := RCV_ARM;
        end
        else
        begin
          ReceiveData[ReceiveState.Index] := ReceiveByte;
          inc(ReceiveState.Index);
          if UseCRC then
            ReceiveState.CRC := crc16(ReceiveState.CRC, ReceiveByte)
          else
            ReceiveState.LRC := ReceiveState.LRC xor ReceiveByte;
          ReceiveState.State := RCV_DAT;
        end;
    RCV_ETX:
      if (ReceiveByte = ASCII_ETX) then
      begin
        if UseCRC then
        begin
          ReceiveState.CRC := crc16(ReceiveState.CRC, ReceiveByte);
          ReceiveState.State := RCV_CRC1;
        end
        else
        begin
          ReceiveState.LRC := ReceiveState.LRC xor ReceiveByte;
          ReceiveState.State := RCV_LRC;
        end;
      end
      else
        if (ReceiveByte = ASCII_STX) then
        begin
          ReceiveState.CRC := 0;
          ReceiveState.LRC := 0;
          ReceiveState.Index := 0;
          ReceiveState.State := RCV_DAT;
AddLog('RX Restart');
        end
        else
          if (ReceiveByte = ASCII_DLE) then
          begin
            ReceiveData[ReceiveState.Index] := ReceiveByte;
            inc(ReceiveState.Index);
            if UseCRC then
              ReceiveState.CRC := crc16(ReceiveState.CRC, ReceiveByte)
            else
              ReceiveState.LRC := ReceiveState.LRC xor ReceiveByte;
            ReceiveState.State := RCV_DAT
          end
          else
          begin
            ReceiveState.State := RCV_ARM;
AddLog('RX Abort');
          end;
    RCV_CRC1:
      begin
        ReceiveState.CRC := crc16(ReceiveState.CRC, ReceiveByte);
        ReceiveState.State := RCV_CRC2;
      end;
    RCV_CRC2:
      begin
        ReceiveState.CRC := crc16(ReceiveState.CRC, ReceiveByte);
        if (ReceiveState.CRC = 0) then
        begin
          ReceiveState.State := RCV_RDY;
          Result := ReceiveState.Index;
        end
        else
        begin
          ReceiveState.State := RCV_ARM;
AddLog('RX CRC '+IntToHex(ReceiveState.CRC,4)+'H '+IntToStr(ReceiveState.Index));
        end;
      end;
    RCV_LRC:
      begin
        if (ReceiveState.LRC = ReceiveByte) then
        begin
          ReceiveState.State := RCV_RDY;
          Result := ReceiveState.Index;
        end
        else
          ReceiveState.State := RCV_ARM;
      end;
    else
      ReceiveState.State := RCV_ARM;
  end;
end;

end.
