UNIT Unit1;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, SyncObjs, FileCtrl, StrUtils, IniFiles,
  {CPort, CPortCtl, ScktComp, LMDControl, LMDBaseControl,
  LMDBaseGraphicControl, LMDBaseShape, LMDShapeControl, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, LMDGraphicControl,
  LMDLEDCustomLabel, LMDLEDLabel, LMDBaseMeter, LMDCustomProgressFill,
  LMDProgressFill, IdThreadMgr, IdThreadMgrDefault, IdTCPServer,}
  FIFOList, FIFOList2;

const
  VERSION_NUMBER = '2.45';
  TICKSPERSECOND = 100;
  MAX_CHANNELS = 160;


// CommSrvr Change History
//
// Version 2.45
// 2016/10/01 - Message Header A support
//            - PingType
//
// Version 2.44
// 2016/06/03 - Sign upstream messages that uses 'J' header
// 2016/06/21 - SuspendRoute logic on UpstreamLink 2
//
// Version 2.43
// 2015/10/29 - Message Header J support
//            - Routing Table increased from 256 to 1000 entries
//
// Version 2.42
// 2015/07/22 - ResponseThread implemented to handle message movement from
//            -   downFIFO to channelFIFO using call to ProcessResponse()
//            - Shortened text in log file messages
//
// Version 2.41
// 2014/07/28 - Terminate connection if more than 5 empty messages from upstream
//            - Terminate connection if more than 10 downstream empty messages sent
//            - Treat Header Session Number value of 0 in upstream response as
//            -   instruction to terminate session
//
// Version 2.40
// 2013/08/05 - Increased MAX_CAHNNELS to 160 (default 48)
//
// Version 2.39
// 2014/01/29 - debug
//
// Version 2.38
// 2013/11/20 - Support for GSM Modems (GSM Data connections)
//
// Version 2.37
// 2013/10/25 - Call ProcessResponse as long as responses are available (max 100 times)
//            - Increased MAX_CAHNNELS to 128 (default 48)
//
// Version 2.36
// 2013/08/05 - Changed FIFOlist2 list entries from 16 down to 8
//            - Increased MAX_CAHNNELS to 96 (default 48)
//
// Version 2.35
// 2013/01/30 - Fixed Remote Monitor/Commander to upstream link not working issue
//
// Version 2.34
// 2013/01/03 - Removed expiry date logic
//
// Version 2.33
// 2012/11/23 - Send last part of buffer rather than first part of buffer to RemoteMonitor
//            -   when size of status and events strings are larger them Item.Buffer
//
// Version 2.32
// 2012/08/16 - Increased Serve1.MaxConnections from 40 to 100
//            - Use (UpstreamOption and $0F) to route supervisory messages to
//            -   allow upstream routing info in high nibble
//            - Increased MAX_CAHNNELS to 64 (MaxChannels entry in .ini file, default 48)
//
// Version 2.31
// 2012/07/04 - Changed expiry date to 2013/01
//
// Version 2.30
// 2012/05/02 - New MAC seed for Telium terminals
//
// Version 2.29
// 2012/03/11 - Send SOHQuery tags upstream
//
// Version 2.28
// 2012/03/01 - Detect 0x10 + 'CLR' from terminal trying to connect RadioPAD and
//            -  respond with 'READY' to enable terminal to detect that it is
//            -  already connected
//
// Version 2.27
// 2012/02/01 - Changed expiry date to 2012/07
//
// Version 2.26
// 2011/10/20 - Changed DecodeReceiveStream() log level from 0 to 1
//
// Version 2.25
// 2011/06/30 - Changed expiry date to 2012/01
//
// Version 2.24
// 2011/02/22 - Changed Socket.Readable(100) to Socket.Readable(10) in ReceiveThread
//
// Version 2.23
// 2011/01/07 - Changed expiry date to 2011/07
//
// Version 2.22
// 2010/11/25 - Replaced [TerminalServer] with [SocketListener] in .ini file
//
// Version 2.21
// 2010/10/22 - Allow invalid HostID values through to upstream Link 1 with warning
//
// Version 2.20
// 2010/08/30 - Added thread to receive upstream responses
//            - Increased upstream links from 4 to 8
//            - Load sharing on upstream links
//            - Changed expiry date to 2011/01
//
// skipped 2.15 to 2.19
//
// Version 2.14
// 2010/05/06 - Changed expiry date to 2010/09
//
// Version 2.13
// 2010/03/15 - Set PlacedAnOrder to false upon new connection
//
// Version 2.12
// 2010/02/23 - Skip over channels in use when new socket connection
//
// Version 2.11
// 2010/01/06 - Changed expiry date to 2010/05
//            - Changed channelFIFO array to type FIFOlist2 (only 16 entries each)
//
// Version 2.10
// 2009/12/30 - SignType=2 support during message authentication
//            - Increased FIFOlist from 32 to 99 entries
//
// Version 2.09
// 2009/06/14 - Changed expiry date to 2010/01
// 2009/05/21 - Retransmit debug
//
// Version 2.08
// 2009/02/25 - Ping timer now also reset upon sending data to upstream link
//            - new icon
// 2009/03/09 - Increased RemoteMonitor upstream response messages max size from 8000 to 8192
//
// Version 2.07
// 2009/02/13 - (StartEnd and $04) in link response header - terminate session
//            - IdleTimeout in .ini file, seconds before dropping GPRS connection
//              after close/terminate indication in StartEnd of link response
//
// Version 2.06
// 2009/01/12 - Changed expiry date to 2009/08
//
// Version 2.05
// 2008/11/14 - Implemented channelFIFO[] to queue multiple downstream messages
//
// Version 2.04
// 2008/10/01 - Keep session open for longer if GlocellStock terminal connection
//
// Version 2.03
// 2008/08/29 - Added debug info for upstream link responses
// 2008/09/15 - Detect 'RING' response from dial-up modem
//
// Version 2.02
// 2008/05/29 - PlaceAnOrder introduced to extend connection for AirTime1 but not for Call Again
// 2008/07/30 - Added 'CloseRequested' to speed up top-up sessions
// 2008/08/03 - Changed expiry date to 2009/01
//
// Version 2.01
// 2008/05/13 - Implemented MSG_TYPE_PING
//
// Version 2.00
// 2007/12/02 - Initial release, based on 1.31
//
//

type
	MsgBuffer = array[0..184] of byte;

  TTranConStates = (CON_DISABLED, CON_STARTUP, CON_CONNECT, CON_CONNECTING, CON_READY, CON_DISCONNECTED);
  TModemType = (MT_NONE, MT_ANALOG);
  TPortStatus = (STA_DISABLED, STA_ERROR, STA_NOT_READY, STA_CONNECTING, STA_CONNECTED, STA_DROPPED, STA_HANGUP, STA_WAITING);

  TUpstreamThread = class(TThread)
  private
    Item : TItem;
  protected
    procedure Execute; override;
  end;

  TResponseThread = class(TThread)
  private
    Item : TItem;
  protected
    procedure Execute; override;
  end;

  TReceiveThread = class(TThread)
  private
    Item : TItem;
  protected
    procedure Execute; override;
  end;

  TForm1 = class(TForm)
    Timer1: TTimer;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    ComPort1: TComPort;
    ComPort2: TComPort;
    ComPort3: TComPort;
    ComPort4: TComPort;
    ComPort5: TComPort;
    ComPort6: TComPort;
    ComPort7: TComPort;
    ComPort8: TComPort;
    GroupBox3: TGroupBox;
    staPort1: TLMDShapeControl;
    staPort2: TLMDShapeControl;
    staPort3: TLMDShapeControl;
    staPort4: TLMDShapeControl;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Timer2: TTimer;
    lblPort1: TLabel;
    lblPort2: TLabel;
    lblPort3: TLabel;
    lblPort4: TLabel;
    Timer3: TTimer;
    GroupBox4: TGroupBox;
    ledSessions: TLMDLEDLabel;
    Label5: TLabel;
    Server1: TIdTCPServer;
    pbAlive: TLMDProgressFill;
    GroupBox5: TGroupBox;
    lblPort5: TLabel;
    staPort5: TLMDShapeControl;
    Label9: TLabel;
    lblPort6: TLabel;
    staPort6: TLMDShapeControl;
    Label11: TLabel;
    lblPort7: TLabel;
    staPort7: TLMDShapeControl;
    Label13: TLabel;
    lblPort8: TLabel;
    staPort8: TLMDShapeControl;
    Label7: TLabel;
    staUpstream1: TLMDShapeControl;
    staUpstream2: TLMDShapeControl;
    staUpstream3: TLMDShapeControl;
    staUpstream4: TLMDShapeControl;
    Label6: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    IdTCPUpstream1: TIdTCPClient;
    IdTCPUpstream2: TIdTCPClient;
    IdTCPUpstream3: TIdTCPClient;
    IdTCPUpstream4: TIdTCPClient;
    IdTCPUpstream5: TIdTCPClient;
    IdTCPUpstream6: TIdTCPClient;
    IdTCPUpstream7: TIdTCPClient;
    IdTCPUpstream8: TIdTCPClient;
    Label14: TLabel;
    staUpstream5: TLMDShapeControl;
    Label15: TLabel;
    staUpstream6: TLMDShapeControl;
    Label16: TLabel;
    staUpstream7: TLMDShapeControl;
    Label17: TLabel;
    staUpstream8: TLMDShapeControl;
    procedure LogToFile(TimeStamp : Boolean; sData: String);
    procedure FatalError(s1 : String);
    function QueueUpstream(LinkNumber,Channel : Integer; Data : Array of Byte; Count : Integer) : Integer;
    procedure QueueDownstream(Channel : Integer; Count : Integer; Data : Pointer);
    procedure BouncePort(PortNum : Integer);
    procedure FlushTransmitter(PortNum : Integer);
    function ReceiveMessage(PortNum, Timer, Count : Integer; Buffer : Array of Byte) : Boolean;
    function TransmitMessage(PortNum : Integer) : Integer;
    procedure ShowStatus(PortNum : Integer; Status : TPortStatus);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComPort1AfterOpen(Sender: TObject);
    procedure ComPort1Ring(Sender: TObject);
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure ComPort2AfterOpen(Sender: TObject);
    procedure ComPort2Ring(Sender: TObject);
    procedure ComPort2RxChar(Sender: TObject; Count: Integer);
    procedure ComPort1RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort2RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort3AfterOpen(Sender: TObject);
    procedure ComPort3Ring(Sender: TObject);
    procedure ComPort3RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort3RxChar(Sender: TObject; Count: Integer);
    procedure ComPort4AfterOpen(Sender: TObject);
    procedure ComPort4Ring(Sender: TObject);
    procedure ComPort4RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort4RxChar(Sender: TObject; Count: Integer);
    procedure Timer2Timer(Sender: TObject);
    procedure ComPort4DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort3DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort2DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort1DSRChange(Sender: TObject; OnOff: Boolean);
    procedure Timer3Timer(Sender: TObject);
    procedure Server1Connect(AThread: TIdPeerThread);
    procedure Server1Disconnect(AThread: TIdPeerThread);
    procedure Server1Exception(AThread: TIdPeerThread;
      AException: Exception);
    procedure Server1Execute(AThread: TIdPeerThread);
    procedure Server1ListenException(AThread: TIdListenerThread;
      AException: Exception);
    procedure staPort1DblClick(Sender: TObject);
    procedure staPort2DblClick(Sender: TObject);
    procedure staPort3DblClick(Sender: TObject);
    procedure staPort4DblClick(Sender: TObject);
    procedure staPort5DblClick(Sender: TObject);
    procedure staPort6DblClick(Sender: TObject);
    procedure staPort7DblClick(Sender: TObject);
    procedure staPort8DblClick(Sender: TObject);
    procedure ComPort5AfterOpen(Sender: TObject);
    procedure ComPort5DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort5Ring(Sender: TObject);
    procedure ComPort5RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort5RxChar(Sender: TObject; Count: Integer);
    procedure ComPort6AfterOpen(Sender: TObject);
    procedure ComPort6DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort6Ring(Sender: TObject);
    procedure ComPort6RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort6RxChar(Sender: TObject; Count: Integer);
    procedure ComPort7AfterOpen(Sender: TObject);
    procedure ComPort7DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort7Ring(Sender: TObject);
    procedure ComPort7RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort7RxChar(Sender: TObject; Count: Integer);
    procedure ComPort8AfterOpen(Sender: TObject);
    procedure ComPort8DSRChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort8Ring(Sender: TObject);
    procedure ComPort8RLSDChange(Sender: TObject; OnOff: Boolean);
    procedure ComPort8RxChar(Sender: TObject; Count: Integer);
    procedure IdTCPUpstream1Connected(Sender: TObject);
    procedure IdTCPUpstream1Disconnected(Sender: TObject);
    procedure IdTCPUpstream2Connected(Sender: TObject);
    procedure IdTCPUpstream2Disconnected(Sender: TObject);
    procedure IdTCPUpstream3Connected(Sender: TObject);
    procedure IdTCPUpstream3Disconnected(Sender: TObject);
    procedure IdTCPUpstream4Connected(Sender: TObject);
    procedure IdTCPUpstream4Disconnected(Sender: TObject);
    procedure IdTCPUpstream5Connected(Sender: TObject);
    procedure IdTCPUpstream5Disconnected(Sender: TObject);
    procedure IdTCPUpstream6Connected(Sender: TObject);
    procedure IdTCPUpstream6Disconnected(Sender: TObject);
    procedure IdTCPUpstream7Connected(Sender: TObject);
    procedure IdTCPUpstream7Disconnected(Sender: TObject);
    procedure IdTCPUpstream8Connected(Sender: TObject);
    procedure IdTCPUpstream8Disconnected(Sender: TObject);
    procedure staUpstream1DblClick(Sender: TObject);
    procedure staUpstream2DblClick(Sender: TObject);
    procedure staUpstream1Click(Sender: TObject);
    procedure staUpstream2Click(Sender: TObject);
    procedure staUpstream3Click(Sender: TObject);
    procedure staUpstream3DblClick(Sender: TObject);
    procedure staUpstream4Click(Sender: TObject);
    procedure staUpstream4DblClick(Sender: TObject);
    procedure staUpstream8DblClick(Sender: TObject);
    procedure staUpstream5DblClick(Sender: TObject);
    procedure staUpstream5Click(Sender: TObject);
    procedure staUpstream6DblClick(Sender: TObject);
    procedure staUpstream6Click(Sender: TObject);
    procedure staUpstream7DblClick(Sender: TObject);
    procedure staUpstream7Click(Sender: TObject);
    procedure staUpstream8Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function DetermineRoute(Host : Integer) : Integer;
  end;

var
  Form1: TForm1;
  UpstreamThread: TUpstreamThread;
  ResponseThread: TResponseThread;
  ReceiveThread: TReceiveThread;
  DebugMode : Integer;
  DisconnectTimeout : Integer;
  InstanceName : String;
  AliveCounter : Integer;
  KeepAliveCount : Integer;
  IdleTimeout : Integer;
  UseListener : Boolean; // enable TCP listener for terminal connections over TCP/IP
  RoutingTable : Array[0..999,1..8] of Boolean;
  RoutingIndex : Array[0..999] of Integer;
  RoutingLines : TStringList;
  UseUpstream : Array[1..8] of Boolean; // enable connection to upstream server
  PingTime : Array[1..8] of Integer;
  PingType : Array[1..8] of String;
  ResponseTime : Array[1..8] of Integer;
  ReconnectTimeout : Array[1..8] of Integer;
  LinkConState : Array[1..8] of TTranConStates;
  LinkTimer : Array[1..8] of Integer;
  LinkIdle : Array[1..8] of Integer;
  SuspendRoute : Array[1..8] of Boolean;
  TickCounter : Integer;
  SrvrTimer : Integer;
  ConnectCounter, ConnectedClients : Integer;
  // variables associated with 8 COM Ports
  CallConnected : Array[1..8] of Boolean;
  AnswerCall : Array[1..8] of Integer;
  ModemResponse : Array[1..8] of String;
  ModemReady : Array[1..8] of Boolean;
  ModemType : Array[1..8] of TModemType;
  // variables associated with channels
  ChannelInUse : Array[0..MAX_CHANNELS+1] of Boolean;
  ConnectedTerminal : Array[0..MAX_CHANNELS+1] of String[16];
  ConnectedSerial : Array[0..MAX_CHANNELS+1] of String[16];
  ReceiveCounter : Array[0..MAX_CHANNELS+1] of Integer;
  TransmitCounter : Array[0..MAX_CHANNELS+1] of Integer;
  ReceiveBuffer : Array[0..MAX_CHANNELS+1, 0..1023] of Byte;
  EmptyCounter1 : Array[0..MAX_CHANNELS+1] of Integer;
  EmptyCounter2 : Array[0..MAX_CHANNELS+1] of Integer;
  ChannelLink : Array[0..MAX_CHANNELS+1] of Byte;
  channelFIFO : Array[0..MAX_CHANNELS+1] of TFIFOList2;

implementation

uses
  SysDef, INIFile, LogList, Frames, Protocol, Upstream, Math, md5;

{$R *.lfm}

const
  ReceiveBufferSize = 8192;

type
  PServerClient   = ^TServerClient;
  TServerClient = record  // Object holding data of client
    Thread : Pointer;
    ConnectTimer : Integer;
    ConnectNumber : Integer;
  end;

var
  SectionName : String;
  AnswerDelay : Integer;
  MaxCallDuration : Integer;
  Clients : TThreadList;     // Holds the data of all TCP clients
  upFIFO : Array[1..8] of TFIFOList;
  downFIFO : Array[1..8] of TFIFOList;
  // variables assocaited with upstream connections
  LinkReceiveState : Array[1..8] of TReceiveState;
  LinkReceiveBuffer : Array[1..8, 0..8191] of Byte;
  // Terminal to Upstream Server messages
  RequestBuffer : Array[0..MAX_CHANNELS+1, 0..1023] of Byte;
  RequestLength : Array[0..MAX_CHANNELS+1] of Integer;
  // variables associated with Terminal Sessions, 1..8 for COM Ports, 9..32 for TCP sessions
  ReceiveState : Array[0..MAX_CHANNELS+1] of TReceiveState;
  FrameLength : Array[0..MAX_CHANNELS+1] of Integer;
  FrameBuffer : Array[0..MAX_CHANNELS+1, 0..9999] of Byte;

// #############################   #############  ############################
//	Msg1 : MsgBuffer = ($16,$16,$10,$02,$42,$01,$76,$43,$23,$00,$80,$00,$00,$00,$00,$32,$00,$03,$31,$02,$85,$10,$10,$01,$D0,$E4,$A1,$6C,$AE,$B2,$F3,$37,$CE,$C5,$DD,$09,$D8,$28,$1F,$15,$4D,$52,$00,$28,$43,$44,$42,$30,$30,$30,$33,$05,$28,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$01,$15,$A2,$4D,$45,$00,$70,$41,$54,$49,$35,$31,$30,$30,$4D,$50,$55,$30,$33,$33,$41,$00,$00,$00,$00,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$00,$00,$00,$00,$43,$46,$53,$3A,$32,$34,$35,$37,$36,$30,$20,$44,$46,$53,$3A,$34,$33,$35,$37,$31,$32,$20,$52,$41,$4D,$3A,$37,$30,$31,$39,$35,$32,$4D,$45,$00,$43,$41,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$49,$4D,$3A,$20,$10,$03,$D5,$E5);
//	Msg2 : MsgBuffer = ($16,$16,$10,$02,$42,$01,$76,$43,$23,$00,$81,$00,$00,$00,$00,$32,$00,$03,$31,$02,$85,$10,$10,$01,$3B,$F9,$DE,$66,$CC,$21,$89,$28,$87,$7C,$87,$AD,$80,$0F,$75,$46,$4D,$52,$00,$28,$43,$44,$42,$30,$30,$30,$33,$05,$28,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$02,$15,$A2,$4D,$45,$00,$70,$41,$54,$49,$35,$31,$30,$30,$4D,$50,$55,$30,$33,$33,$41,$00,$00,$00,$00,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$00,$00,$00,$00,$43,$46,$53,$3A,$32,$34,$35,$37,$36,$30,$20,$44,$46,$53,$3A,$34,$33,$35,$37,$31,$32,$20,$52,$41,$4D,$3A,$37,$30,$31,$39,$35,$32,$4D,$45,$00,$43,$41,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$49,$4D,$3A,$20,$10,$03,$E3,$12);
//	Msg3 : MsgBuffer = ($16,$16,$10,$02,$42,$01,$76,$43,$23,$00,$03,$00,$00,$00,$00,$32,$00,$03,$31,$02,$05,$10,$10,$01,$0C,$03,$7C,$63,$40,$14,$3B,$44,$68,$11,$6A,$2A,$13,$78,$6B,$30,$4D,$52,$00,$28,$43,$44,$42,$30,$30,$30,$33,$05,$28,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$03,$15,$22,$4D,$45,$00,$70,$41,$54,$49,$35,$31,$30,$30,$4D,$50,$55,$30,$33,$33,$41,$00,$00,$00,$00,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$00,$00,$00,$00,$43,$46,$53,$3A,$32,$34,$35,$37,$36,$30,$20,$44,$46,$53,$3A,$34,$33,$35,$37,$31,$32,$20,$52,$41,$4D,$3A,$37,$30,$31,$39,$35,$32,$4D,$45,$00,$43,$41,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$49,$4D,$3A,$20,$10,$03,$25,$6E);
//	Msg4 : MsgBuffer = ($16,$16,$10,$02,$42,$01,$76,$43,$23,$00,$04,$00,$00,$00,$00,$32,$00,$03,$31,$02,$05,$10,$10,$01,$30,$72,$4C,$0D,$48,$7E,$52,$5D,$27,$26,$39,$7F,$37,$62,$38,$34,$4D,$52,$00,$28,$43,$44,$42,$30,$30,$30,$33,$05,$28,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$01,$15,$22,$4D,$45,$00,$70,$41,$54,$49,$35,$31,$30,$30,$4D,$50,$55,$30,$33,$33,$41,$00,$00,$00,$00,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$00,$00,$00,$00,$43,$46,$53,$3A,$32,$34,$35,$37,$36,$30,$20,$44,$46,$53,$3A,$34,$33,$35,$37,$31,$32,$20,$52,$41,$4D,$3A,$37,$30,$31,$39,$35,$32,$4D,$45,$00,$43,$41,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$49,$4D,$3A,$20,$10,$03,$28,$50);
//	Msg5 : MsgBuffer = ($16,$16,$10,$02,$42,$01,$76,$43,$23,$00,$05,$00,$00,$00,$00,$32,$00,$03,$31,$02,$05,$10,$10,$01,$77,$6C,$39,$69,$0F,$07,$6E,$36,$06,$46,$25,$76,$6D,$46,$78,$55,$4D,$52,$00,$28,$43,$44,$42,$30,$30,$30,$33,$05,$28,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$03,$15,$22,$4D,$45,$00,$70,$41,$54,$49,$35,$31,$30,$30,$4D,$50,$55,$30,$33,$33,$41,$00,$00,$00,$00,$30,$30,$32,$31,$33,$31,$30,$32,$38,$35,$31,$30,$00,$00,$00,$00,$43,$46,$53,$3A,$32,$34,$35,$37,$36,$30,$20,$44,$46,$53,$3A,$34,$33,$35,$37,$31,$32,$20,$52,$41,$4D,$3A,$37,$30,$31,$39,$35,$32,$4D,$45,$00,$43,$41,$4D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$49,$4D,$3A,$20,$10,$03,$5A,$2B);

{function DecodeMessage(Count : Integer; Buffer : Array of Byte) : Boolean;
var
  pHdr1 : PMessageHeader1;
  Digest1,Digest2 : MD5Digest;
  i : Integer;
  RetVal : Integer;
begin
  AcceptReceiveFrame(ReceiveState[1]);
  for i := 0 to Count-1 do
  begin
    RetVal := DecodeReceiveStream(True, Buffer[i], ReceiveState[1], ReceiveBuffer[1], ReceiveBufferSize);
    if Retval > 0 then
    begin
      Result := True;
    end;
  end;

  RetVal := ReceiveState[1].Index;
  AcceptReceiveFrame(ReceiveState[1]);

  pHdr1 := PMessageHeader1(@ReceiveBuffer);
  if pHdr1.MessageFormat = ord('B') then
  begin
    BCDToInt(pHdr1.HostID, i, 2);
    BCDToInt(pHdr1.TerminalID, i, 4);
    if pHdr1.SignType = 1 then
    begin
      MoveMemory(@Digest1, @pHdr1.Signature, 16);
      ZeroMemory(@pHdr1.Signature, 16);
      MoveMemory(@pHdr1.Signature[0], @pHdr1.TerminalID[0], 4);
      MoveMemory(@pHdr1.Signature[7], @pHdr1.SessionNumber[0], 2);
      MoveMemory(@pHdr1.Signature[13], @pHdr1.MessageNumber[0], 2);
      Digest2 := MD5Memory(pHdr1, RetVal);
      if not MD5Match(Digest1, Digest2) then
      begin
        Result := False;
      end;
    end;
  end;
  if (i > 0) then
    Result := False;
end;}
// #############################   #############  ############################

// ****************************************************************************
procedure TForm1.LogToFile(TimeStamp : Boolean; sData: String);
var
  sName : String;
  FileHandle : Integer;
  Count : Cardinal;
  Buf : Array[0..9999] of Char;
begin
  sName := 'CS' + FormatDateTime('yyyymmdd', Now) + '.LOG';
  if not FileExists(sName) then
    FileHandle := FileCreate(sName)
  else
    FileHandle := FileOpen(sName, fmOpenWrite or fmShareDenyNone);
  if FileHandle > 0 then
  begin
    sData := sData + #13+#10;
    if TimeStamp then
      sData := FormatDateTime('mm/dd hh:nn:ss ', Now) + sData;
    Count := Length(sData);
    if Count > Sizeof(Buf)-1 then
      Count := Sizeof(Buf)-1;
    FileSeek(FileHandle, 0, 2);
    StrPLCopy(Buf, sData, Count);
    FileWrite(FileHandle, Buf, Count);
    FlushFileBuffers(FileHandle);
    FileClose(FileHandle);
  end;
end;

// ****************************************************************************
procedure TForm1.FatalError(s1 : String);
begin
  MessageDlg('Directory '+s1+' does not exist.'+#13+'Application Terminating', mtError, [mbOk], 0);
  Application.Terminate;
end;

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
procedure BuildRoutingTable;
var
  ndx1,ndx2 : Integer;
  Host,Link : Integer;
  fld,str : String;
begin
  for ndx1 := 0 to 999 do
  begin
    RoutingIndex[ndx1] := 0;
    for ndx2 := 1 to 8 do
      RoutingTable[ndx1,ndx2] := False;
  end;

  for ndx1 := 0 to RoutingLines.Count-1 do
  begin
    ndx2 := Pos('=', RoutingLines[ndx1]);
    if ndx2 > 0 then
    begin
      Host := StrToIntDef(Copy(RoutingLines[ndx1], 1, ndx2-1), 0);
      if (Host >= 0) and (Host <= 999) then
      begin
        str := Copy(RoutingLines[ndx1], ndx2+1, 100);
        while Length(str) > 0 do
        begin
          fld := GetFirstField(str);
          Link := StrToIntDef(fld, 0);
          if (Link >= 1) and (Link <= 8) then
            RoutingTable[Host, Link] := True
          else
            LogPutLine(3, 'INI> Invalid link number in UpstreamRouting section');
        end;
      end
      else
        LogPutLine(3, 'INI> Invalid host number in UpstreamRouting section');
    end;
  end;
end;

// ****************************************************************************
function UpstreamConnected(Link : Integer) : Boolean;
begin
  Result := False;
  case Link of
  1:
    if not Form1.IdTCPUpstream1.Connected or not Form1.IdTCPUpstream1.Socket.Connected then
      Exit;
  2:
    if not Form1.IdTCPUpstream2.Connected or not Form1.IdTCPUpstream2.Socket.Connected then
      Exit;
  3:
    if not Form1.IdTCPUpstream3.Connected or not Form1.IdTCPUpstream3.Socket.Connected then
      Exit;
  4:
    if not Form1.IdTCPUpstream4.Connected or not Form1.IdTCPUpstream4.Socket.Connected then
      Exit;
  5:
    if not Form1.IdTCPUpstream5.Connected or not Form1.IdTCPUpstream5.Socket.Connected then
      Exit;
  6:
    if not Form1.IdTCPUpstream6.Connected or not Form1.IdTCPUpstream6.Socket.Connected then
      Exit;
  7:
    if not Form1.IdTCPUpstream7.Connected or not Form1.IdTCPUpstream7.Socket.Connected then
      Exit;
  8:
    if not Form1.IdTCPUpstream8.Connected or not Form1.IdTCPUpstream8.Socket.Connected then
      Exit;
  end;
  Result := True;
end;

// ****************************************************************************
procedure UpstreamConnect(Link : Integer);
begin
  try
    LinkTimer[Link] := 30*TICKSPERSECOND;
    case Link of
    1: Form1.IdTCPUpstream1.Connect;
    2: Form1.IdTCPUpstream2.Connect;
    3: Form1.IdTCPUpstream3.Connect;
    4: Form1.IdTCPUpstream4.Connect;
    5: Form1.IdTCPUpstream5.Connect;
    6: Form1.IdTCPUpstream6.Connect;
    7: Form1.IdTCPUpstream7.Connect;
    8: Form1.IdTCPUpstream8.Connect;
    end;
  except
    case Link of
    1: AddLog(2, 0, 1, 'Upstream Server (' + Form1.IdTCPUpstream1.Host + ') not available');
    2: AddLog(2, 0, 2, 'Upstream Server (' + Form1.IdTCPUpstream2.Host + ') not available');
    3: AddLog(2, 0, 3, 'Upstream Server (' + Form1.IdTCPUpstream3.Host + ') not available');
    4: AddLog(2, 0, 4, 'Upstream Server (' + Form1.IdTCPUpstream4.Host + ') not available');
    5: AddLog(2, 0, 5, 'Upstream Server (' + Form1.IdTCPUpstream5.Host + ') not available');
    6: AddLog(2, 0, 6, 'Upstream Server (' + Form1.IdTCPUpstream6.Host + ') not available');
    7: AddLog(2, 0, 7, 'Upstream Server (' + Form1.IdTCPUpstream7.Host + ') not available');
    8: AddLog(2, 0, 8, 'Upstream Server (' + Form1.IdTCPUpstream8.Host + ') not available');
    end;
    Form1.ShowStatus(1000+Link, STA_ERROR);
    if (Link = 2) and SuspendRoute[2] then
    begin
      // deactivate socket listener when upstream connection not available
      Form1.Server1.Active := False;
      SrvrTimer := 0;
      Form1.GroupBox4.Color := clHighlightText;
    end;
    LinkConState[Link] := CON_DISCONNECTED;
    LinkTimer[Link] := 30*TICKSPERSECOND;
  end;
end;

// ****************************************************************************
procedure UpstreamDisconnect(Link : Integer);
begin
  case Link of
  1:
    begin
      Form1.IdTCPUpstream1.Disconnect;
      Form1.ShowStatus(1001, STA_HANGUP);
      LinkConState[1] := CON_DISCONNECTED;
      LinkTimer[1] := TICKSPERSECOND;
    end;
  2:
    begin
      Form1.IdTCPUpstream2.Disconnect;
      Form1.ShowStatus(1002, STA_HANGUP);
      LinkConState[2] := CON_DISCONNECTED;
      LinkTimer[2] := TICKSPERSECOND;
    end;
  3:
    begin
      Form1.IdTCPUpstream3.Disconnect;
      Form1.ShowStatus(1003, STA_HANGUP);
      LinkConState[3] := CON_DISCONNECTED;
      LinkTimer[3] := TICKSPERSECOND;
    end;
  4:
    begin
      Form1.IdTCPUpstream4.Disconnect;
      Form1.ShowStatus(1004, STA_HANGUP);
      LinkConState[4] := CON_DISCONNECTED;
      LinkTimer[4] := TICKSPERSECOND;
    end;
  5:
    begin
      Form1.IdTCPUpstream5.Disconnect;
      Form1.ShowStatus(1005, STA_HANGUP);
      LinkConState[5] := CON_DISCONNECTED;
      LinkTimer[5] := TICKSPERSECOND;
    end;
  6:
    begin
      Form1.IdTCPUpstream6.Disconnect;
      Form1.ShowStatus(1006, STA_HANGUP);
      LinkConState[6] := CON_DISCONNECTED;
      LinkTimer[6] := TICKSPERSECOND;
    end;
  7:
    begin
      Form1.IdTCPUpstream7.Disconnect;
      Form1.ShowStatus(1007, STA_HANGUP);
      LinkConState[7] := CON_DISCONNECTED;
      LinkTimer[7] := TICKSPERSECOND;
    end;
  8:
    begin
      Form1.IdTCPUpstream8.Disconnect;
      Form1.ShowStatus(1008, STA_HANGUP);
      LinkConState[8] := CON_DISCONNECTED;
      LinkTimer[8] := TICKSPERSECOND;
    end;
  end;
end;

// ****************************************************************************
function LinkRcvStream(Link,Count : Integer; Buffer : Array of Byte) : Integer;
var
  Item : TItem;
  i : Integer;
  RetVal : Integer;
begin
  Result := 0;
  if (Link < 1) or (Link > 8) then
    Exit;
  for i := 0 to Count-1 do
  begin
    RetVal := DecodeReceiveStream(True, Buffer[i], LinkReceiveState[Link], LinkReceiveBuffer[Link], ReceiveBufferSize-1);
    if Retval > 0 then
    begin
      if downFIFO[Link] <> nil then
      begin
        if RetVal < ITEM_BUFFER_SIZE then
        begin
          Item.OwnerID := Link;
          Item.Size := RetVal;
          MoveMemory(@Item.Buffer, @LinkReceiveBuffer[Link], RetVal);
          // intact responses from Upstream Server into input FIFO
          downFIFO[Link].AddItem(Item);
        end;
      end;
      // ready for next frame, arm receive state machine
      AcceptReceiveFrame(LinkReceiveState[Link]);
    end;
  end;
end;

// ****************************************************************************
procedure TResponseThread.Execute;
var
  Link : Integer;
  cnt : Integer;
  DoneWork : Boolean;
begin
  // handle incoming messages
  while not Terminated do
  begin
    DoneWork := False;
    try
      for Link := 1 to 8 do
      begin
        if downFIFO[Link] <> nil then
        begin
          if downFIFO[Link].RemoveItem(Item) then
          begin
            DoneWork := True;
            ProcessResponse(Link, Item.Size, Item.Buffer);
            if LinkConState[Link] = CON_READY then
              LinkTimer[Link] := 0;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
//        LogPutLine(3, 'Response Thread, '+E.Message);
//        Suspend;
      end;
    end;
    if not DoneWork then
      Sleep(10)
    else
      Sleep(1);
  end;
end;

// ****************************************************************************
procedure TReceiveThread.Execute;
var
  DoneWork : Boolean;
  Link : Integer;
  cnt,i : Integer;
  buf : Array[0..1500] of Byte;
begin
  // handle incoming messages
  while not Terminated do
  begin
    DoneWork := False;
    try
      for Link := 1 to 8 do
      begin
        if UpstreamConnected(Link) then
        begin
          case Link of
          1:
            if Form1.IdTCPUpstream1.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream1.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(1, cnt, buf);
            end;
          2:
            if Form1.IdTCPUpstream2.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream2.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(2, cnt, buf);
            end;
          3:
            if Form1.IdTCPUpstream3.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream3.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(3, cnt, buf);
            end;
          4:
            if Form1.IdTCPUpstream4.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream4.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(4, cnt, buf);
            end;
          5:
            if Form1.IdTCPUpstream5.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream5.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(5, cnt, buf);
            end;
          6:
            if Form1.IdTCPUpstream6.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream6.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(6, cnt, buf);
            end;
          7:
            if Form1.IdTCPUpstream7.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream7.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(7, cnt, buf);
            end;
          8:
            if Form1.IdTCPUpstream8.Socket.Readable(10) then
            begin
              DoneWork := True;
              cnt := Form1.IdTCPUpstream8.Socket.Recv(buf, Sizeof(buf));
              if cnt > 0 then
                LinkRcvStream(8, cnt, buf);
            end;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
//        LogPutLine(3, 'Response Thread, '+E.Message);
//        Suspend;
      end;
    end;
    if not DoneWork then
      Sleep(10)
    else
      Sleep(1);
  end;
end;

// ****************************************************************************
procedure TUpstreamThread.Execute;
var
  DoneWork : Boolean;
  Link : Integer;
  cnt,i : Integer;
  str : String;
begin
  while not Terminated do
  begin
    DoneWork := False;
    try
      for Link := 1 to 8 do
      begin
        // ship upstream transmit frame
        if upFIFO[Link] <> nil then
        begin
          if upFIFO[Link].RemoveItem(Item) then
          begin
            DoneWork := True;
            case Link of
            1: cnt := Form1.IdTCPUpstream1.Socket.Send(Item.Buffer, Item.Size);
            2: cnt := Form1.IdTCPUpstream2.Socket.Send(Item.Buffer, Item.Size);
            3: cnt := Form1.IdTCPUpstream3.Socket.Send(Item.Buffer, Item.Size);
            4: cnt := Form1.IdTCPUpstream4.Socket.Send(Item.Buffer, Item.Size);
            5: cnt := Form1.IdTCPUpstream5.Socket.Send(Item.Buffer, Item.Size);
            6: cnt := Form1.IdTCPUpstream6.Socket.Send(Item.Buffer, Item.Size);
            7: cnt := Form1.IdTCPUpstream7.Socket.Send(Item.Buffer, Item.Size);
            8: cnt := Form1.IdTCPUpstream8.Socket.Send(Item.Buffer, Item.Size);
            end;
            if cnt = Item.Size then
            begin
              // shipped, set response timer
              LinkTimer[Link] := ReconnectTimeout[Link]; // default 30sec
              LinkIdle[Link] := 0;
            end
            else
            begin
              LinkTimer[Link] := 1; // force reconnect
              AddLog(3, 0, Link, 'Send failure ('+IntToStr(cnt)+' vs. '+IntToStr(Item.Size)+')');
            end;
          end;
        end;
      end;
      if not DoneWork then
        Suspend; // incoming messages will resume thread
    except
      on E: Exception do
      begin
        LogPutLine(3, 'Upstream Thread, '+E.Message);
        Suspend;
      end;
    end;
  end;
end;

// ****************************************************************************
procedure ServiceUpstreamLink(Link : Integer);
var
  Item : TItem;
  str : String;
  cnt : Integer;
begin

  if downFIFO[Link] = nil then
    Exit;

  if UpstreamConnected(Link) then
  begin
    Inc(LinkIdle[Link]);

// moved to ResponseThread
//    if downFIFO[Link] <> nil then
//    begin
//      for cnt:= 1 to 100 do
//      begin
//        if downFIFO[Link].RemoveItem(Item) then
//        begin
//          LinkTimer[Link] := 0;
//          LinkIdle[Link] := 0;
//          ProcessResponse(Link, Item.Size, Item.Buffer);
//        end
//        else
//          break;
//      end;
//    end;

    if (PingTime[Link] > 0) and (LinkIdle[Link] > PingTime[Link]) then
    begin
      // time to ping upstream server
      AddLog(0, 0, Link, 'Ping');
      SendPing(Link);
      LinkIdle[Link] := 0;
    end;

  end
  else
  begin
    if LinkConState[Link] = CON_READY then
    begin
      AddLog(2, 0, Link, 'Upstream not connected');
      UpstreamDisconnect(Link);
    end;
  end;
end;


// ****************************************************************************
procedure ControlDTR(PortNum : Integer; Level : Boolean);
begin
  try
    case PortNum of
    1: Form1.ComPort1.SetDTR(Level);
    2: Form1.ComPort2.SetDTR(Level);
    3: Form1.ComPort3.SetDTR(Level);
    4: Form1.ComPort4.SetDTR(Level);
    5: Form1.ComPort5.SetDTR(Level);
    6: Form1.ComPort6.SetDTR(Level);
    7: Form1.ComPort7.SetDTR(Level);
    8: Form1.ComPort8.SetDTR(Level);
    end;
  except
    Form1.ShowStatus(PortNum, STA_ERROR);
  end;
end;

// ****************************************************************************
procedure ControlRTS(PortNum : Integer; Level : Boolean);
begin
  case PortNum of
  1: Form1.ComPort1.SetRTS(Level);
  2: Form1.ComPort2.SetRTS(Level);
  3: Form1.ComPort3.SetRTS(Level);
  4: Form1.ComPort4.SetRTS(Level);
  5: Form1.ComPort5.SetRTS(Level);
  6: Form1.ComPort6.SetRTS(Level);
  7: Form1.ComPort7.SetRTS(Level);
  8: Form1.ComPort8.SetRTS(Level);
  end;
end;

// ****************************************************************************
procedure ComPortSendString(PortNum : Integer; Data : String);
begin
  if DebugMode > 1 then
    LogPutLine(0, IntToStr(PortNum) + '> TX Modem: '+Data);
  case PortNum of
  1: Form1.ComPort1.WriteStr(Data);
  2: Form1.ComPort2.WriteStr(Data);
  3: Form1.ComPort3.WriteStr(Data);
  4: Form1.ComPort4.WriteStr(Data);
  5: Form1.ComPort5.WriteStr(Data);
  6: Form1.ComPort6.WriteStr(Data);
  7: Form1.ComPort7.WriteStr(Data);
  8: Form1.ComPort8.WriteStr(Data);
  end;
end;

// ****************************************************************************
procedure ReceiveResponse(PortNum, Count : Integer; Buffer : Array of Byte);
var
  i : Integer;
  str : String;
begin
  str := '';
  for i := 0 to Count-1 do
  begin
    ModemResponse[PortNum] := ModemResponse[PortNum] + Chr(Buffer[i]);
    if DebugMode > 1 then
    begin
      if (Buffer[i] < 20) or (Buffer[i] > 126) then
        str := str + '<'+IntToHex(Buffer[i], 2)+'>'
      else
        str := str + Chr(Buffer[i]);
    end;
  end;

  if DebugMode > 0 then
    LogPutLine(0, IntToStr(PortNum)+'> '+IntToStr(AnswerCall[PortNum])+' RX Modem: '+str);

  if (Pos('OK', ModemResponse[PortNum]) > 0) then
  begin
    ModemResponse[PortNum] := '';
    ModemReady[PortNum] := True;
    LogPutLine(0, IntToStr(PortNum)+'> Modem ready');
    Form1.ShowStatus(PortNum, STA_WAITING);
    Exit;
  end;

  if AnswerCall[PortNum] > 0 then
  begin
    // we are busy answering a call, look for "CONNECT..." response to "ATA" command
    if Pos('CONNECT ', ModemResponse[PortNum]) > 0 then
    begin
      AnswerCall[PortNum] := 0;
      CallTimer[PortNum] := MaxCallDuration; // max allowed timer for modem calls
      CallConnected[PortNum] := True;
      AcceptReceiveFrame(ReceiveState[PortNum]);
      LogPutLine(0, IntToStr(PortNum) + '> '+Copy(ModemResponse[PortNum], Pos('CONNECT ', ModemResponse[PortNum]), 20));
      ModemResponse[PortNum] := '';
      Form1.ShowStatus(PortNum, STA_CONNECTED);
      Exit;
    end;
  end
  else if AnswerCall[PortNum] = 0 then
  begin
    if Pos('RING', ModemResponse[PortNum]) > 0 then
    begin
      LogPutLine(0, IntToStr(PortNum)+'> Ringing..');
      AnswerCall[PortNum] := 1;
      CallTimer[PortNum] := 0;
      TerminateCall[PortNum] := 0;
      ModemResponse[PortNum] := '';
      ReceiveCounter[PortNum] := 0;
      TransmitCounter[PortNum] := 0;
    end;
  end;
end;

// ****************************************************************************
procedure ComPortInit(PortNum : Integer);
begin
  ControlDTR(PortNum, True);
  ControlRTS(PortNum, True);
  ModemResponse[PortNum] := '';
  ReceiveCounter[PortNum] := 0;
  TransmitCounter[PortNum] := 0;
  EmptyCounter1[PortNum] := 0;
  EmptyCounter2[PortNum] := 0;
  AcceptReceiveFrame(ReceiveState[PortNum]);
  case ModemType[PortNum] of
  MT_NONE:
    Form1.ShowStatus(PortNum, STA_WAITING);
  MT_ANALOG:
    begin
      ComPortSendString(PortNum, 'ATZ'+#13+#10);
      Form1.ShowStatus(PortNum, STA_NOT_READY);
    end;
  end;
end;

// ****************************************************************************
procedure ComPortRing(PortNum : Integer);
begin
  if ModemType[PortNum] <> MT_NONE then
  begin
    Form1.ShowStatus(PortNum, STA_CONNECTING);
    ControlDTR(PortNum, True);
    ControlRTS(PortNum, True);
    if AnswerCall[PortNum] = 0 then
    begin
      AnswerCall[PortNum] := 1;
      CallTimer[PortNum] := 0;
      TerminateCall[PortNum] := 0;
      LogPutLine(0, IntToStr(PortNum)+'> Call answer..');
      ModemResponse[PortNum] := '';
    end;
    if AnswerCall[PortNum] > AnswerDelay+TICKSPERSECOND then
    begin
      ComPortSendString(PortNum, 'ATA'+#13+#10);
    end;
    ReceiveCounter[PortNum] := 0;
    TransmitCounter[PortNum] := 0;
  end
  else
    CallTimer[PortNum] := MaxCallDuration; // max time allowed for calls
end;

// ****************************************************************************
procedure ComPortDSRChange(PortNum : Integer; OnOff : Boolean);
begin
  if not OnOff then
  begin
    CallTimer[PortNum] := 0;
    AnswerCall[PortNum] := 0;
    if (ModemType[PortNum] <> MT_NONE) and (TerminateCall[PortNum] = 0) then
    begin
      LogPutLine(2, IntToStr(PortNum)+'> Modem not ready');
      Form1.ShowStatus(PortNum, STA_NOT_READY);
    end;
  end;
end;

// ****************************************************************************
procedure ComPortDCDChange(PortNum : Integer; OnOff : Boolean);
begin
  if not OnOff then
  begin
    CallTimer[PortNum] := 0;
    AnswerCall[PortNum] := 0;
    TransmitReady[PortNum] := 0;
    if ModemReady[PortNum] and (ModemType[PortNum] <> MT_NONE) then
    begin
      LogPutLine(1, IntToStr(PortNum)+'> Call Dropped RxC='+IntToStr(ReceiveCounter[PortNum])+' TxC='+IntToStr(TransmitCounter[PortNum]));
      Form1.ShowStatus(PortNum, STA_WAITING);
//      Form1.ShowStatus(PortNum, STA_DROPPED);
    end;
    ModemResponse[PortNum] := '';
    CallConnected[PortNum] := False;
  end;
end;

// ****************************************************************************
procedure ComPortReceive(PortNum : Integer; Count : Integer; Buffer : Array of Byte);
begin
  if ModemReady[PortNum] then
  begin
    if (ModemType[PortNum] = MT_ANALOG) and not CallConnected[PortNum] then
      ReceiveResponse(PortNum, Count, Buffer)
    else
      Form1.ReceiveMessage(PortNum, 0, Count, Buffer);
  end
  else
    ReceiveResponse(PortNum, Count, Buffer);
end;

// ****************************************************************************
function TForm1.DetermineRoute(Host : Integer) : Integer;
var
  i,n : Integer;
begin
  Result := 0;
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
        Result := RoutingIndex[Host];
        break;
      end;
    end;
  end;
end;

// ****************************************************************************
procedure TForm1.QueueDownstream(Channel : Integer; Count : Integer; Data : Pointer);
var
  RetVal : Integer;
  Item : TItem2;
begin
  Item.OwnerID := Channel;
  if Count <= ITEM_BUFFER_SIZE then
    Item.Size := Count
  else
    Item.Size := ITEM_BUFFER_SIZE;
  if (Channel > 0) and (Channel <= MAX_CHANNELS) then
  begin
    MoveMemory(@Item.Buffer, Data, Count); // no header
    if not channelFIFO[Channel].AddItem(Item) then
      AddLog(2, Channel, 0, 'RSP: Channel '+IntToStr(Channel)+' FIFO overflow');
  end
  else
      AddLog(2, Channel, 0, 'ERR: QueuDownstream, invalid channel number '+IntToStr(Channel));
end;

// ****************************************************************************
function TForm1.QueueUpstream(LinkNumber,Channel : Integer; Data : Array of Byte; Count : Integer) : Integer;
var
  Item : TItem;
  RetVal : Integer;
begin
  Result := -1;
  if Count > FIFOList.ITEM_BUFFER_SIZE then
  begin
    Result := ERR_OVERFLOW;
    Exit;
  end;
  if Count <= 0 then
  begin
    Result := ERR_UNDERFLOW;
    Exit;
  end;
  if (LinkNumber < 1) or (LinkNumber > 8) then
  begin
    Result := ERR_INVALPARM;
    Exit;
  end;
  if upFIFO[LinkNumber] = nil then
  begin
    Result := ERR_NOTINITIALISED;
    Exit;
  end;

  if LinkNumber = 1 then
  begin
//    if not UpstreamConnected(LinkNumber) then
    if not IdTCPUpstream1.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[1] = CON_READY then
      begin
        AddLog(2, Channel, 1, 'ERR: Upstream link 1 not connected');
        UpstreamDisconnect(1);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 2 then
  begin
    if not IdTCPUpstream2.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[2] = CON_READY then
      begin
        AddLog(2, Channel, 2, 'ERR: Upstream link 2 not connected');
        UpstreamDisconnect(2);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 3 then
  begin
    if not IdTCPUpstream3.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[3] = CON_READY then
      begin
        AddLog(2, Channel, 3, 'ERR: Upstream link 3 not connected');
        UpstreamDisconnect(3);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 4 then
  begin
    if not IdTCPUpstream4.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[4] = CON_READY then
      begin
        AddLog(2, Channel, 4, 'ERR: Upstream link 4 not connected');
        UpstreamDisconnect(4);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 5 then
  begin
    if not IdTCPUpstream5.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[5] = CON_READY then
      begin
        AddLog(2, Channel, 5, 'ERR: Upstream link 5 not connected');
        UpstreamDisconnect(5);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 6 then
  begin
    if not IdTCPUpstream6.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[6] = CON_READY then
      begin
        AddLog(2, Channel, 6, 'ERR: Upstream link 6 not connected');
        UpstreamDisconnect(6);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 7 then
  begin
    if not IdTCPUpstream7.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[7] = CON_READY then
      begin
        AddLog(2, Channel, 7, 'ERR: Upstream link 7 not connected');
        UpstreamDisconnect(7);
      end;
      Exit;
    end;
  end;
  if LinkNumber = 8 then
  begin
    if not IdTCPUpstream8.Connected then
    begin
      Result := ERR_NOTCONNECTED;
      if LinkConState[8] = CON_READY then
      begin
        AddLog(2, Channel, 8, 'ERR: Upstream link 8 not connected');
        UpstreamDisconnect(8);
      end;
      Exit;
    end;
  end;

  // frame data to be send
  RetVal := BuildTransmitFrame(True, Data, Item.Buffer, Count, Sizeof(Item.Buffer));
  if RetVal < 0 then
  begin
    Result := RetVal;
    Exit;
  end;

  // cache framed data in output FIFO
  Item.OwnerID := Channel;
  Item.Size := RetVal;
  Result := ERR_LISTFULL;
  if upFIFO[LinkNumber].AddItem(Item) then
  begin
    UpstreamThread.Resume;
    Result := 0;
  end;
end;

// ****************************************************************************
procedure TForm1.BouncePort(PortNum : Integer);
begin
  if Iniread('PortNumbers', 'Port'+IntToStr(PortNum), 'None') <> 'None' then
  begin
    ControlDTR(PortNum, False);
    try
      case PortNum of
        1: ComPort1.ClearBuffer(True, True);
        2: ComPort2.ClearBuffer(True, True);
        3: ComPort3.ClearBuffer(True, True);
        4: ComPort4.ClearBuffer(True, True);
        5: ComPort5.ClearBuffer(True, True);
        6: ComPort6.ClearBuffer(True, True);
        7: ComPort7.ClearBuffer(True, True);
        8: ComPort8.ClearBuffer(True, True);
      else
        Exit;
      end;
      case PortNum of
        1: ComPort1.Close;
        2: ComPort2.Close;
        3: ComPort3.Close;
        4: ComPort4.Close;
        5: ComPort5.Close;
        6: ComPort6.Close;
        7: ComPort7.Close;
        8: ComPort8.Close;
      else
        Exit;
      end;
    except
      if Iniread('PortNumbers', 'Port'+IntToStr(PortNum), 'None') <> 'None' then
        ShowStatus(PortNum, STA_ERROR);
    end;

    TransmitReady[PortNum] := 0;
    FrameLength[PortNum] := 0;
    TerminateCall[PortNum] := 0;
    CallTimer[PortNum] := 0;
    AnswerCall[PortNum] := 0;
    ChannelLink[PortNum] := 0;

    try
      case PortNum of
        1: ComPort1.Open;
        2: ComPort2.Open;
        3: ComPort3.Open;
        4: ComPort4.Open;
        5: ComPort5.Open;
        6: ComPort6.Open;
        7: ComPort7.Open;
        8: ComPort8.Open;
      end;
    except
      LogToFile(True, 'STARTUP> Port'+IntToStr(PortNum)+' failed to open');
      ShowStatus(PortNum, STA_ERROR);
    end;
  end;
end;

// ****************************************************************************
procedure TForm1.FlushTransmitter(PortNum : Integer);
begin
 if (PortNum >= Low(FrameLength)) and (PortNum <= High(FrameLength)) then
   FrameLength[PortNum] := 0;
end;

// ****************************************************************************
function TForm1.ReceiveMessage(PortNum, Timer, Count : Integer; Buffer : Array of Byte) : Boolean;
var
  i : Integer;
  RetVal : Integer;
  str : String;
begin
  Result := True;
  Inc(ReceiveCounter[PortNum], Count); // accumulate number of bytes received in session

  if DebugMode > 2 then
  begin
    str := 'RX Term ['+IntToStr(Count)+'] ';
    if DebugMode > 3 then
    begin
      RetVal := Count;
      if RetVal > 250 then
        RetVal := 250;
      for i := 0 to RetVal-1 do
        str := str + IntToHex(Buffer[i],2);
      if Count > RetVal then
        str := str + '...';
    end;
    AddLog(0, PortNum, 0, str);
  end;

  if (PortNum < 0) or (PortNum > MAX_CHANNELS) then
    Exit;

  if ReceiveState[PortNum].State < 4 then
  begin
    // terminal starting GPRS connection but already connected?
    if ((Count = 4) and (ArrStr(Buffer, 3) = 'ATZ')) or
       ((Count = 5) and (Buffer[0] = $10) and (ArrStr(Buffer[1], 3) = 'CLR')) then
    begin
      if FrameLength[PortNum] = 0 then
      begin
        // GRPS modem or RadioPAD
        // respond with 'READY' string so that terminal can detect that it is connected
        if Count = 4 then
          AddLog(0, PortNum, 0, 'Resuming GPRS connection ('+IntToStr(Timer)+')')
        else
          AddLog(0, PortNum, 0, 'Resuming RadioPAD connection ('+IntToStr(Timer)+')');
        StrArr(#10+'READY'+#10, FrameBuffer[PortNum], 7);
        FrameLength[PortNum] := 7;
//        AcceptReceiveFrame(ReceiveState[PortNum]);
        Exit;
      end;
    end;
  end;

  for i := 0 to Count-1 do
  begin
    RetVal := DecodeReceiveStream(True, Buffer[i], ReceiveState[PortNum], ReceiveBuffer[PortNum], 1000);
    if Retval > 0 then
    begin
      Result := HandleMessage(PortNum, RetVal, ReceiveBuffer[PortNum]);
      AcceptReceiveFrame(ReceiveState[PortNum]);
//      if Result then
//        Inc(TransmitReady[PortNum], 2);
    end;
  end;
end;

// ****************************************************************************
function TForm1.TransmitMessage(PortNum : Integer) : Integer;
var
  Attempts,RetVal,Actual,Count : Integer;
  str : String;
  i : Integer;
begin
  Result := 0;
  if (PortNum < 1) or (PortNum > MAX_CHANNELS) then
    Exit;

  RetVal := BuildTransmitFrame(True, TransmitBuffer[PortNum], FrameBuffer[PortNum], TransmitLength[PortNum], Sizeof(FrameBuffer[PortNum]));
  if RetVal < 0 then
  begin
    Result := RetVal;
    Exit;
  end;

  if DebugMode > 2 then
  begin
    str := 'TX Term ['+IntToStr(RetVal)+'] ';
    if DebugMode > 3 then
    begin
      Count := RetVal;
      if Count > DebugMode*50 then
        Count := DebugMode*50;
      for i := 0 to Count-1 do
        str := str + IntToHex(FrameBuffer[PortNum][i],2);
      if RetVal > Count then
        str := str + '...';
    end;
    AddLog(0, PortNum, 0, str);
  end;

  if PortNum > 8 then
  begin
    // indication to socket thread to transmit message
    FrameLength[PortNum] := RetVal;
    Exit;
  end;

  // following lines only for serial ports
  FrameLength[PortNum] := 0;
  Actual := 0;
  Attempts := 0;
  while Actual < RetVal do
  begin
    Count := RetVal - Actual;
    if Count > 1500 then
      Count := 1500;
    case PortNum of
      1: Actual := Actual + ComPort1.Write(FrameBuffer[PortNum][Actual], Count);
      2: Actual := Actual + ComPort2.Write(FrameBuffer[PortNum][Actual], Count);
      3: Actual := Actual + ComPort3.Write(FrameBuffer[PortNum][Actual], Count);
      4: Actual := Actual + ComPort4.Write(FrameBuffer[PortNum][Actual], Count);
      5: Actual := Actual + ComPort5.Write(FrameBuffer[PortNum][Actual], Count);
      6: Actual := Actual + ComPort6.Write(FrameBuffer[PortNum][Actual], Count);
      7: Actual := Actual + ComPort7.Write(FrameBuffer[PortNum][Actual], Count);
      8: Actual := Actual + ComPort8.Write(FrameBuffer[PortNum][Actual], Count);
      else
        begin
          Result := ERR_INVALPARM;
          Exit;
        end;
    end;
    Inc(Attempts);
    if Attempts > 15 then
    begin
      Inc(TransmitCounter[PortNum], Actual);
      Result := ERR_OVERFLOW;
      Exit;
    end;
  end;
  Inc(TransmitCounter[PortNum], Actual);
end;

// ****************************************************************************
procedure TForm1.ShowStatus(PortNum : Integer; Status : TPortStatus);
var
  cl : TColor;
  sCaption : String;
begin
  case Status of
  STA_DISABLED:
    begin
      cl := clSilver;
      sCaption := 'Disabled';
    end;
  STA_ERROR:
    begin
      cl := clRed;
      sCaption := 'ERROR';
    end;
  STA_NOT_READY:
    begin
      cl := $002040ff;
      sCaption := 'NOT READY';
    end;
  STA_CONNECTING:
    begin
      cl := clYellow;
      sCaption := 'Connecting';
    end;
  STA_CONNECTED:
    begin
      cl := clLime;
      sCaption := 'Connected';
    end;
  STA_HANGUP:
    begin
      cl := clBlue;
      sCaption := 'Hangup';
    end;
  STA_DROPPED:
    begin
      cl := clAqua;
      sCaption := 'Disconnected';
    end;
  STA_WAITING:
    begin
      cl := clGreen;
      sCaption := 'Waiting';
    end;
  else
    begin
      cl := clWhite;
      sCaption := 'Unknown';
    end;
  end;

  case PortNum of
  1001:
    begin
      staUpstream1.Brush.Color := cl;
      staUpstream1.Caption.Caption := sCaption;
    end;
  1002:
    begin
      staUpstream2.Brush.Color := cl;
      staUpstream2.Caption.Caption := sCaption;
    end;
  1003:
    begin
      staUpstream3.Brush.Color := cl;
      staUpstream3.Caption.Caption := sCaption;
    end;
  1004:
    begin
      staUpstream4.Brush.Color := cl;
      staUpstream4.Caption.Caption := sCaption;
    end;
  1005:
    begin
      staUpstream5.Brush.Color := cl;
      staUpstream5.Caption.Caption := sCaption;
    end;
  1006:
    begin
      staUpstream6.Brush.Color := cl;
      staUpstream6.Caption.Caption := sCaption;
    end;
  1007:
    begin
      staUpstream7.Brush.Color := cl;
      staUpstream7.Caption.Caption := sCaption;
    end;
  1008:
    begin
      staUpstream8.Brush.Color := cl;
      staUpstream8.Caption.Caption := sCaption;
    end;
  1:
    begin
      staPort1.Brush.Color := cl;
      staPort1.Caption.Caption := sCaption;
    end;
  2:
    begin
      staPort2.Brush.Color := cl;
      staPort2.Caption.Caption := sCaption;
    end;
  3:
    begin
      staPort3.Brush.Color := cl;
      staPort3.Caption.Caption := sCaption;
    end;
  4:
    begin
      staPort4.Brush.Color := cl;
      staPort4.Caption.Caption := sCaption;
    end;
  5:
    begin
      staPort5.Brush.Color := cl;
      staPort5.Caption.Caption := sCaption;
    end;
  6:
    begin
      staPort6.Brush.Color := cl;
      staPort6.Caption.Caption := sCaption;
    end;
  7:
    begin
      staPort7.Brush.Color := cl;
      staPort7.Caption.Caption := sCaption;
    end;
  8:
    begin
      staPort8.Brush.Color := cl;
      staPort8.Caption.Caption := sCaption;
    end;
  end;
end;

// ****************************************************************************
procedure TForm1.FormCreate(Sender: TObject);
var
  i : Integer;
  str : String;

  procedure HandleError(s1 : String);
  begin
    MessageDlg('Directory '+s1+' does not exist.'+#13+'Application Terminating', mtError, [mbOk], 0);
    Application.Terminate;
  end;

begin
  Randomize;
  IniInitialize;
  LogInitialize;
  Clients := TThreadList.Create;
  RoutingLines := TStringList.Create;

//DecodeMessage(185, Msg1);
//DecodeMessage(185, Msg2);
//DecodeMessage(185, Msg3);
//DecodeMessage(185, Msg4);
//DecodeMessage(185, Msg5);

  for i:=1 to MAX_CHANNELS do
  begin
    channelFIFO[i] := TFIFOList2.Create;
    channelFIFO[i].Startup;
  end;

  try
    UpstreamThread := TUpstreamThread.Create(True);
    UpstreamThread.FreeOnTerminate := True;
    UpstreamThread.Resume;
  except
    on E: Exception do
    begin
      MessageDlg ('Error creating Upstream thread'+#13+E.Message, mtError, [mbOk], 0);
      Application.Terminate;
      Exit;
    end;
  end;

  try
    ResponseThread := TResponseThread.Create(True);
    ResponseThread.FreeOnTerminate := True;
    ResponseThread.Resume;
  except
    on E: Exception do
    begin
      MessageDlg ('Error creating Response thread'+#13+E.Message, mtError, [mbOk], 0);
      Application.Terminate;
      Exit;
    end;
  end;

  try
    ReceiveThread := TReceiveThread.Create(True);
    ReceiveThread.FreeOnTerminate := True;
    ReceiveThread.Priority := tpLower;
//    ReceiveThread.Resume;
  except
    on E: Exception do
    begin
      MessageDlg ('Error creating Receive thread'+#13+E.Message, mtError, [mbOk], 0);
      Application.Terminate;
      Exit;
    end;
  end;

  IniSection('UpstreamRouting', RoutingLines);
  BuildRoutingTable;

  i := StrToIntDef(Iniread('Setup', 'MaxChannels', '48'), 48);
  if (i > 8) and (i <= MAX_CHANNELS) then
    MaxChannels := i;

  i := StrToIntDef(Iniread('Setup', 'FormWidth', '0'), 0);
  if i >= 600 then
    Form1.Width := i;
  i := StrToIntDef(Iniread('Setup', 'FormHeight', '0'), 0);
  if i >= 300 then
    Form1.Height := i;

  InstanceName := Iniread('Setup', 'InstanceName', 'UpLink');
  if InstanceName <> '' then
    InstanceName := InstanceName + ' ';

  Form1.Caption := InstanceName + 'Communication Server, V'+VERSION_NUMBER;

  str :=  'Version='+VERSION_NUMBER+' Channels='+IntToStr(MaxChannels);
  LogToFile(True, 'STARTUP> '+str);

  DebugMode := StrToIntDef(Iniread('Setup', 'DebugMode', '0'), 0);
  AnswerDelay := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('Setup', 'AnswerDelay', '20'), 20); // 50ms units
  if AnswerDelay >= 30*TICKSPERSECOND then
    AnswerDelay := 20*TICKSPERSECOND;
  MaxCallDuration := TICKSPERSECOND * StrToIntDef(Iniread('Setup', 'MaxCallDuration', '60'), 60);
  KeepAliveCount := StrToIntDef(Iniread('Setup', 'KeepAlive', '20'), 20);
  if KeepAliveCount < 4 then KeepAliveCount := 4;

  ComPort1.Port := Iniread('PortNumbers', 'Port1', 'COM1');
  ComPort2.Port := Iniread('PortNumbers', 'Port2', 'COM2');
  ComPort3.Port := Iniread('PortNumbers', 'Port3', 'COM3');
  ComPort4.Port := Iniread('PortNumbers', 'Port4', 'COM4');
  ComPort5.Port := Iniread('PortNumbers', 'Port5', 'COM5');
  ComPort6.Port := Iniread('PortNumbers', 'Port6', 'COM6');
  ComPort7.Port := Iniread('PortNumbers', 'Port7', 'COM7');
  ComPort8.Port := Iniread('PortNumbers', 'Port8', 'COM8');

  lblPort1.Caption := Comport1.Port;
  lblPort2.Caption := Comport2.Port;
  lblPort3.Caption := Comport3.Port;
  lblPort4.Caption := Comport4.Port;
  lblPort5.Caption := Comport5.Port;
  lblPort6.Caption := Comport6.Port;
  lblPort7.Caption := Comport7.Port;
  lblPort8.Caption := Comport8.Port;

  ComPort1.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port1', '9600'), 9600);
  ComPort2.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port2', '9600'), 9600);
  ComPort3.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port3', '9600'), 9600);
  ComPort4.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port4', '9600'), 9600);
  ComPort5.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port5', '9600'), 9600);
  ComPort6.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port6', '9600'), 9600);
  ComPort7.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port7', '9600'), 9600);
  ComPort8.CustomBaudRate := StrToIntDef(Iniread('BitsPerSecond', 'Port8', '9600'), 9600);

  for i := 1 to 8 do
  begin
    AnswerCall[i] := 0;
    CallConnected[i] := False;
    ModemType[i] := MT_NONE;
    ModemReady[i] := True;
  end;

  if Iniread('Modem', 'Port1', 'No') = 'Yes' then
  begin
    ModemType[1] := MT_ANALOG;
    ModemReady[1] := False;
  end;

  if Iniread('Modem', 'Port2', 'No') = 'Yes' then
  begin
    ModemType[2] := MT_ANALOG;
    ModemReady[2] := False;
  end;

  if Iniread('Modem', 'Port3', 'No') = 'Yes' then
  begin
    ModemType[3] := MT_ANALOG;
    ModemReady[3] := False;
  end;

  if Iniread('Modem', 'Port4', 'No') = 'Yes' then
  begin
    ModemType[4] := MT_ANALOG;
    ModemReady[4] := False;
  end;

  if Iniread('Modem', 'Port5', 'No') = 'Yes' then
  begin
    ModemType[5] := MT_ANALOG;
    ModemReady[5] := False;
  end;

  if Iniread('Modem', 'Port6', 'No') = 'Yes' then
  begin
    ModemType[6] := MT_ANALOG;
    ModemReady[6] := False;
  end;

  if Iniread('Modem', 'Port7', 'No') = 'Yes' then
  begin
    ModemType[7] := MT_ANALOG;
    ModemReady[7] := False;
  end;

  if Iniread('Modem', 'Port8', 'No') = 'Yes' then
  begin
    ModemType[8] := MT_ANALOG;
    ModemReady[8] := False;
  end;

  Protocol.Startup;

  if Iniread('PortNumbers', 'Port1', 'None') <> 'None' then
  begin
    try
      ComPort1.Open;
    except
      LogToFile(True, 'STARTUP> Port1 failed to open');
      ShowStatus(1, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port2', 'None') <> 'None' then
  begin
    try
      ComPort2.Open;
    except
      LogToFile(True, 'STARTUP> Port2 failed to open');
      ShowStatus(2, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port3', 'None') <> 'None' then
  begin
    try
      ComPort3.Open;
    except
      LogToFile(True, 'STARTUP> Port3 failed to open');
      ShowStatus(3, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port4', 'None') <> 'None' then
  begin
    try
      ComPort4.Open;
    except
      LogToFile(True, 'STARTUP> Port4 failed to open');
      ShowStatus(4, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port5', 'None') <> 'None' then
  begin
    try
      ComPort5.Open;
    except
      LogToFile(True, 'STARTUP> Port5 failed to open');
      ShowStatus(5, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port6', 'None') <> 'None' then
  begin
    try
      ComPort6.Open;
    except
      LogToFile(True, 'STARTUP> Port6 failed to open');
      ShowStatus(6, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port7', 'None') <> 'None' then
  begin
    try
      ComPort7.Open;
    except
      LogToFile(True, 'STARTUP> Port7 failed to open');
      ShowStatus(7, STA_ERROR);
    end;
  end;
  if Iniread('PortNumbers', 'Port8', 'None') <> 'None' then
  begin
    try
      ComPort8.Open;
    except
      LogToFile(True, 'STARTUP> Port8 failed to open');
      ShowStatus(8, STA_ERROR);
    end;
  end;

  TickCounter := 0;
  pbAlive.Position := 100;

  ledSessions.Enabled := False;
  UseListener := False;
//  Server1.MaxConnections := MAX_CHANNELS - 8;
  Server1.Bindings.Clear;
{
  if Iniread('TerminalServer', 'Enable', 'No') = 'Yes' then
  begin
    ledSessions.Hint := 'Port ' + IntToStr(Server1.Bindings.DefaultPort);
    ledSessions.ShowHint := True;
    SrvrTimer := 2;
  end
  else
    SrvrTimer := 0;
  Server1.Bindings.DefaultPort := StrToIntDef(Iniread('TerminalServer', 'Port', '1025'), 1025);
  IdleTimeout := TICKSPERSECOND * StrToIntDef(Iniread('TerminalServer', 'IdleTimeout', '30'), 30);
  if IdleTimeout < 5*TICKSPERSECOND then
    IdleTimeout := 5*TICKSPERSECOND;
  DisconnectTimeout := TICKSPERSECOND * StrToIntDef(Iniread('TerminalServer', 'DisconnectTimeout', '1'), 1);
  if DisconnectTimeout < TICKSPERSECOND then
    DisconnectTimeout := TICKSPERSECOND;}

  str := Iniread('SocketListener', 'Enable', '');
  if str <> '' then
     SectionName := 'SocketListener'
  else
     SectionName := 'TerminalServer';

  Server1.Bindings.DefaultPort := StrToIntDef(Iniread(SectionName, 'Port', '1025'), 1025);
  IdleTimeout := TICKSPERSECOND * StrToIntDef(Iniread(SectionName, 'IdleTimeout', '30'), 30);
  if IdleTimeout < 5*TICKSPERSECOND then
    IdleTimeout := 5*TICKSPERSECOND;
  DisconnectTimeout := TICKSPERSECOND * StrToIntDef(Iniread(SectionName, 'DisconnectTimeout', '1'), 1);
  if DisconnectTimeout < TICKSPERSECOND then
    DisconnectTimeout := TICKSPERSECOND;

  if Iniread(SectionName, 'Enable', 'No') = 'Yes' then
  begin
    ledSessions.Hint := 'Port ' + IntToStr(Server1.Bindings.DefaultPort);
    ledSessions.ShowHint := True;
    SrvrTimer := 2;
  end
  else
    SrvrTimer := 0;

  IdTCPUpstream1.Host := Iniread('UpstreamLink1', 'Address', '127.0.0.1');
  IdTCPUpstream1.Port := StrToIntDef(Iniread('UpstreamLink1', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink1', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream1.Hint := IdTCPUpstream1.Host + ':' + IntToStr(IdTCPUpstream1.Port);
    staUpstream1.ShowHint := True;
    LinkConState[1] := CON_STARTUP;
    LinkTimer[1] := 11*TICKSPERSECOND;
    UseUpstream[1] := True;
  end
  else
  begin
    LinkConState[1] := CON_DISABLED;
    LinkTimer[1] := 0;
    UseUpstream[1] := False;
  end;
  ResponseTime[1] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink1', 'ResponseTime', '5'), 5); //  5 seconds
  ReconnectTimeout[1] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink1', 'ReconnectTimeout', '30'), 30); // in seconds
  PingTime[1] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink1', 'PingTime', '0'), 0); // 50ms units
  PingType[1] := Iniread('UpstreamLink1', 'PingType', 'C');

  IdTCPUpstream2.Host := Iniread('UpstreamLink2', 'Address', '127.0.0.1');
  IdTCPUpstream2.Port := StrToIntDef(Iniread('UpstreamLink2', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink2', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream2.Hint := IdTCPUpstream2.Host + ':' + IntToStr(IdTCPUpstream2.Port);
    staUpstream2.ShowHint := True;
    LinkConState[2] := CON_STARTUP;
    LinkTimer[2] := 12*TICKSPERSECOND;
    UseUpstream[2] := True;
  end
  else
  begin
    LinkConState[2] := CON_DISABLED;
    LinkTimer[2] := 0;
    UseUpstream[2] := False;
  end;
  ResponseTime[2] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink2', 'ResponseTime', '5'), 5);
  ReconnectTimeout[2] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink2', 'ReconnectTimeout', '30'), 30);
  PingTime[2] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink2', 'PingTime', '0'), 0);
  PingType[2] := Iniread('UpstreamLink2', 'PingType', 'C');
  if Iniread('UpstreamLink2', 'SuspendRoute', 'No') = 'Yes' then
    SuspendRoute[2] := True;

  IdTCPUpstream3.Host := Iniread('UpstreamLink3', 'Address', '127.0.0.1');
  IdTCPUpstream3.Port := StrToIntDef(Iniread('UpstreamLink3', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink3', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream3.Hint := IdTCPUpstream3.Host + ':' + IntToStr(IdTCPUpstream3.Port);
    staUpstream3.ShowHint := True;
    LinkConState[3] := CON_STARTUP;
    LinkTimer[3] := 13*TICKSPERSECOND;
    UseUpstream[3] := True;
  end
  else
  begin
    LinkConState[3] := CON_DISABLED;
    LinkTimer[3] := 0;
    UseUpstream[3] := False;
  end;
  ResponseTime[3] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink3', 'ResponseTime', '5'), 5);
  ReconnectTimeout[3] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink3', 'ReconnectTimeout', '30'), 30);
  PingTime[3] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink3', 'PingTime', '0'), 0);
  PingType[3] := Iniread('UpstreamLink3', 'PingType', 'C');

  IdTCPUpstream4.Host := Iniread('UpstreamLink4', 'Address', '127.0.0.1');
  IdTCPUpstream4.Port := StrToIntDef(Iniread('UpstreamLink4', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink4', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream4.Hint := IdTCPUpstream4.Host + ':' + IntToStr(IdTCPUpstream4.Port);
    staUpstream4.ShowHint := True;
    LinkConState[4] := CON_STARTUP;
    LinkTimer[4] := 14*TICKSPERSECOND;
    UseUpstream[4] := True;
  end
  else
  begin
    LinkConState[4] := CON_DISABLED;
    LinkTimer[4] := 0;
    UseUpstream[4] := False;
  end;
  ResponseTime[4] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink4', 'ResponseTime', '5'), 5);
  ReconnectTimeout[4] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink4', 'ReconnectTimeout', '30'), 30);
  PingTime[4] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink4', 'PingTime', '0'), 0);
  PingType[4] := Iniread('UpstreamLink4', 'PingType', 'C');

  IdTCPUpstream5.Host := Iniread('UpstreamLink5', 'Address', '127.0.0.1');
  IdTCPUpstream5.Port := StrToIntDef(Iniread('UpstreamLink5', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink5', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream5.Hint := IdTCPUpstream5.Host + ':' + IntToStr(IdTCPUpstream5.Port);
    staUpstream5.ShowHint := True;
    LinkConState[5] := CON_STARTUP;
    LinkTimer[5] := 15*TICKSPERSECOND;
    UseUpstream[5] := True;
  end
  else
  begin
    LinkConState[5] := CON_DISABLED;
    LinkTimer[5] := 0;
    UseUpstream[5] := False;
  end;
  ResponseTime[5] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink5', 'ResponseTime', '5'), 5);
  ReconnectTimeout[5] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink5', 'ReconnectTimeout', '30'), 30);
  PingTime[5] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink5', 'PingTime', '0'), 0);
  PingType[5] := Iniread('UpstreamLink5', 'PingType', 'C');

  IdTCPUpstream6.Host := Iniread('UpstreamLink6', 'Address', '127.0.0.1');
  IdTCPUpstream6.Port := StrToIntDef(Iniread('UpstreamLink6', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink6', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream6.Hint := IdTCPUpstream6.Host + ':' + IntToStr(IdTCPUpstream6.Port);
    staUpstream6.ShowHint := True;
    LinkConState[6] := CON_STARTUP;
    LinkTimer[6] := 16*TICKSPERSECOND;
    UseUpstream[6] := True;
  end
  else
  begin
    LinkConState[6] := CON_DISABLED;
    LinkTimer[6] := 0;
    UseUpstream[6] := False;
  end;
  ResponseTime[6] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink6', 'ResponseTime', '5'), 5);
  ReconnectTimeout[6] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink6', 'ReconnectTimeout', '30'), 30);
  PingTime[6] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink6', 'PingTime', '0'), 0);
  PingType[6] := Iniread('UpstreamLink6', 'PingType', 'C');

  IdTCPUpstream7.Host := Iniread('UpstreamLink7', 'Address', '127.0.0.1');
  IdTCPUpstream7.Port := StrToIntDef(Iniread('UpstreamLink7', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink7', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream7.Hint := IdTCPUpstream7.Host + ':' + IntToStr(IdTCPUpstream7.Port);
    staUpstream7.ShowHint := True;
    LinkConState[7] := CON_STARTUP;
    LinkTimer[7] := 17*TICKSPERSECOND;
    UseUpstream[7] := True;
  end
  else
  begin
    LinkConState[7] := CON_DISABLED;
    LinkTimer[7] := 0;
    UseUpstream[7] := False;
  end;
  ResponseTime[7] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink7', 'ResponseTime', '5'), 5);
  ReconnectTimeout[7] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink7', 'ReconnectTimeout', '30'), 30);
  PingTime[7] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink7', 'PingTime', '0'), 0);
  PingType[7] := Iniread('UpstreamLink7', 'PingType', 'C');

  IdTCPUpstream8.Host := Iniread('UpstreamLink8', 'Address', '127.0.0.1');
  IdTCPUpstream8.Port := StrToIntDef(Iniread('UpstreamLink8', 'Port', '11236'), 11236);
  if Iniread('UpstreamLink8', 'Enable', 'No') = 'Yes' then
  begin
    staUpstream8.Hint := IdTCPUpstream8.Host + ':' + IntToStr(IdTCPUpstream8.Port);
    staUpstream8.ShowHint := True;
    LinkConState[8] := CON_STARTUP;
    LinkTimer[8] := 18*TICKSPERSECOND;
    UseUpstream[8] := True;
  end
  else
  begin
    LinkConState[8] := CON_DISABLED;
    LinkTimer[8] := 0;
    UseUpstream[8] := False;
  end;
  ResponseTime[8] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink8', 'ResponseTime', '5'), 5);
  ReconnectTimeout[8] := TICKSPERSECOND * StrToIntDef(Iniread('UpstreamLink8', 'ReconnectTimeout', '30'), 30);
  PingTime[8] := (TICKSPERSECOND div 20) * StrToIntDef(Iniread('UpstreamLink8', 'PingTime', '0'), 0);
  PingType[8] := Iniread('UpstreamLink8', 'PingType', 'C');

  AliveCounter := 0;

  Timer1.Enabled := True;
  Timer2.Enabled := True;
  Timer3.Enabled := True;
end;

// ****************************************************************************
procedure TForm1.FormDestroy(Sender: TObject);
var
  ndx  : Integer;
begin
  Timer1.Enabled := False;
  Timer2.Enabled := False;
  Timer3.Enabled := False;
  UpstreamThread.Terminate;
  ResponseThread.Terminate;
  ReceiveThread.Terminate;

  ComPort1.Close;
  ComPort2.Close;
  ComPort3.Close;
  ComPort4.Close;
  ComPort5.Close;
  ComPort6.Close;
  ComPort7.Close;
  ComPort8.Close;

  for ndx:=1 to 8 do
  begin
    if upFIFO[ndx] <> nil then
    begin
      upFIFO[ndx].Shutdown;
      upFIFO[ndx].Free;
    end;
    if downFIFO[ndx] <> nil then
    begin
      downFIFO[ndx].Shutdown;
      downFIFO[ndx].Free;
    end;
  end;
  for ndx:=1 to MAX_CHANNELS do
  begin
    if channelFIFO[ndx] <> nil then
    begin
      channelFIFO[ndx].Shutdown;
      channelFIFO[ndx].Free;
    end;
  end;
  if IdTCPUpstream1.Connected then
    IdTCPUpstream1.Disconnect;
  if IdTCPUpstream2.Connected then
    IdTCPUpstream2.Disconnect;
  if IdTCPUpstream3.Connected then
    IdTCPUpstream3.Disconnect;
  if IdTCPUpstream4.Connected then
    IdTCPUpstream4.Disconnect;
  if IdTCPUpstream5.Connected then
    IdTCPUpstream5.Disconnect;
  if IdTCPUpstream6.Connected then
    IdTCPUpstream6.Disconnect;
  if IdTCPUpstream7.Connected then
    IdTCPUpstream7.Disconnect;
  if IdTCPUpstream8.Connected then
    IdTCPUpstream8.Disconnect;

  Server1.Active := False;
  Server1.Bindings.Clear;

  RoutingLines.Free;
  Clients.Free;

  LogToFile(True, 'SHUTDOWN');
  LogShutdown;
  IniShutdown;
end;

// ****************************************************************************
procedure TForm1.Timer1Timer(Sender: TObject);
var
  i : Integer;
begin

  Inc(AliveCounter);
  if AliveCounter > 99999999 then
    AliveCounter := 0;

  for i := 1 to 8 do
  begin
    // look for incoming calls and answer them by sending "ATA" to the modem
    if AnswerCall[i] > 0 then
    begin
      Inc(AnswerCall[i]);
      if AnswerCall[i] = AnswerDelay then
      begin
        ComPortSendString(i, 'ATA'+#13+#10);
      end;
      if AnswerCall[i] > 30*TICKSPERSECOND then // 30 seconds for modem connection
      begin
        AnswerCall[i] := 0;
        LogPutLine(0, IntToStr(i)+'> Answer time-out');
        ShowStatus(i, STA_WAITING);
      end;
    end;
  end;

  for i := 1 to MaxChannels do
  begin
    // look for call completion indication from message handler
    if TerminateCall[i] > 1 then
    begin
      if TerminateCall[i] < DisconnectTimeout then
      begin
        Inc(TerminateCall[i]);
        if i <= 8 then
        begin
          // modem connection
          if TerminateCall[i] = 5 then
          begin
            ShowStatus(i, STA_HANGUP);
            AnswerCall[i] := 0;
          end;
          if TerminateCall[i] = 10 then
          begin
            ControlDTR(i, False);
            CallConnected[i] := False;
            AddLog(1, i, 0, 'Hang Up');
          end;
          if TerminateCall[i] = TICKSPERSECOND then
          begin
            ShowStatus(i, STA_WAITING);
            ControlDTR(i, True);
            TerminateCall[i] := 0;
          end;
        end;
      end;
    end;
  end;


  for i := 1 to 8 do
  begin
    if LinkTimer[i] > 0 then
    begin
      Dec(LinkTimer[i]);
      if LinkTimer[i] = 0 then
      begin
        case LinkConState[i] of
        CON_CONNECTING:
          begin
            AddLog(2, 0, i, 'Upstream link '+IntToStr(i)+' connection time-out');
            if UpstreamConnected(i) then
              UpstreamDisconnect(i);
            LinkTimer[i] := 20*TICKSPERSECOND;
          end;
        CON_DISCONNECTED:
          begin
            LinkConState[i] := CON_CONNECT;
          end;
        CON_READY:
          begin
            if (PingTime[i] > 0) then
            begin
              AddLog(2, 0, i, 'Upstream Server '+IntToStr(i)+' response time-out');
              UpstreamDisconnect(i);
            end;
          end;
        end;
      end;
    end;

    case LinkConState[i] of
    CON_STARTUP:
      begin
        if upFIFO[i] = nil then
          upFIFO[i] := TFIFOList.Create;
        upFIFO[i].Startup;
        if downFIFO[i] = nil then
          downFIFO[i] := TFIFOList.Create;
        downFIFO[i].Startup;
        LinkConState[i] := CON_CONNECT;
      end;
    CON_CONNECT:
      begin
        upFIFO[i].Flush;
        downFIFO[i].Flush;
        ShowStatus(1000+i, STA_CONNECTING);
        LinkConState[i] := CON_CONNECTING;
        AcceptReceiveFrame(LinkReceiveState[i]);
        UpstreamConnect(i);
      end;
    CON_READY:
      begin
        ServiceUpstreamLink(i);
      end;
    end;
  end;


  // handle session and transmit timers
//  for i := 1 to MaxChannels do
  for i := 1 to 8 do
  begin
    if TransmitReady[i] > 0 then
    begin
      Dec(TransmitReady[i]);
      if TransmitReady[i] = 0 then
        BuildMessage(i); // ship frame to terminal
    end;
    if CallTimer[i] > 0 then
    begin
      Dec(CallTimer[i]);
      if CallTimer[i] = 0 then
      begin
        if TerminateCall[i] < 2 then
          TerminateCall[i] := 2;
        AddLog(1, i, 0, 'Session exceeding duration limit');
      end;
    end;
  end;

end;

// ****************************************************************************
procedure TForm1.Timer2Timer(Sender: TObject);
var
  cntr : Integer;
  str : String;
  lines : String;
begin
  str := LogGetLine(0);
  lines := str;
  cntr := 0;
  while str <> '' do
  begin
    Inc(cntr);
    if cntr = 10 then
      Memo1.Visible := False; // stop repainting all these changes
    if Memo1.Lines.Count > 500 then
      Memo1.Lines.Delete(0);
    Memo1.Lines.Append(str);
    str := LogGetLine(0);
    if str <> '' then
    begin
      if Length(lines) + Length(str) >= 9999 then
      begin
        LogToFile(False, lines);
        lines := str;
      end
      else
      begin
        lines := lines + #13+#10 + str;
      end;
    end;
  end;
  if cntr >= 10 then
      Memo1.Visible := True;
  if lines <> '' then
    LogToFile(False, lines);

  if UseListener then
  begin
    str := IntToStr(ConnectedClients);
    if Length(str) = 1 then
      str := '0' + str
    else
      if Length(str) > 2 then
        str := 'XX';
    ledSessions.Caption := str;
  end;

  Inc(TickCounter);
  if TickCounter > 100 then
    TickCounter := 0;
  pbAlive.Position := TickCounter;
end;

// ****************************************************************************
procedure TForm1.Timer3Timer(Sender: TObject);
begin
  if SrvrTimer > 0 then
  begin
    Dec(SrvrTimer);
    if SrvrTimer = 0 then
    begin
      if not Server1.Active then
      begin
        SrvrTimer := 0;
        try
          Server1.Active := True;
          ledSessions.Enabled := True;
          UseListener := True;
          ConnectedClients := 0;
          AddLog(3, 0, 0, 'Listening on port '+IntToStr(Server1.Bindings.DefaultPort)+'...');
          GroupBox4.Color := clBtnFace;
        except
        on E:Exception do
          begin
            AddLog(3, 0, 0, 'Server Open Exception: '+E.Message);
            SrvrTimer := 120;
          end;
        end;
      end;
    end;
  end;
end;

// ****************************************************************************
procedure TForm1.ComPort1AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '1> '+ComPort1.Port+' Open');
  ComPort1.ClearBuffer(True, True);
  ComPortInit(1);
end;

procedure TForm1.ComPort1Ring(Sender: TObject);
begin
  ComPortRing(1);
end;

procedure TForm1.ComPort1RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(1, OnOff);
end;

procedure TForm1.ComPort1DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(1, OnOff);
end;

procedure TForm1.ComPort1RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort1.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(1, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort2AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '2> '+ComPort2.Port+' Open');
  ComPort2.ClearBuffer(True, True);
  ComPortInit(2);
end;

procedure TForm1.ComPort2Ring(Sender: TObject);
begin
  ComPortRing(2);
end;

procedure TForm1.ComPort2RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(2, OnOff);
end;

procedure TForm1.ComPort2DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(2, OnOff);
end;

procedure TForm1.ComPort2RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort2.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(2, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort3AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '3> '+ComPort3.Port+' Open');
  ComPort3.ClearBuffer(True, True);
  ComPortInit(3);
end;

procedure TForm1.ComPort3Ring(Sender: TObject);
begin
  ComPortRing(3);
end;

procedure TForm1.ComPort3RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(3, OnOff);
end;

procedure TForm1.ComPort3DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(3, OnOff);
end;

procedure TForm1.ComPort3RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort3.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(3, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort4AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '4> '+ComPort4.Port+' Open');
  ComPort4.ClearBuffer(True, True);
  ComPortInit(4);
end;

procedure TForm1.ComPort4Ring(Sender: TObject);
begin
  ComPortRing(4);
end;

procedure TForm1.ComPort4RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(4, OnOff);
end;

procedure TForm1.ComPort4DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(4, OnOff);
end;

procedure TForm1.ComPort4RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort4.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(4, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort5AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '5> '+ComPort5.Port+' Open');
  ComPort5.ClearBuffer(True, True);
  ComPortInit(5);
end;

procedure TForm1.ComPort5DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(5, OnOff);
end;

procedure TForm1.ComPort5Ring(Sender: TObject);
begin
  ComPortRing(5);
end;

procedure TForm1.ComPort5RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(5, OnOff);
end;

procedure TForm1.ComPort5RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort5.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(5, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort6AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '6> '+ComPort6.Port+' Open');
  ComPort6.ClearBuffer(True, True);
  ComPortInit(6);
end;

procedure TForm1.ComPort6DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(6, OnOff);
end;

procedure TForm1.ComPort6Ring(Sender: TObject);
begin
  ComPortRing(6);
end;

procedure TForm1.ComPort6RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(6, OnOff);
end;

procedure TForm1.ComPort6RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort6.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(6, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort7AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '7> '+ComPort7.Port+' Open');
  ComPort7.ClearBuffer(True, True);
  ComPortInit(7);
end;

procedure TForm1.ComPort7DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(7, OnOff);
end;

procedure TForm1.ComPort7Ring(Sender: TObject);
begin
  ComPortRing(7);
end;

procedure TForm1.ComPort7RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(7, OnOff);
end;

procedure TForm1.ComPort7RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort7.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(7, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.ComPort8AfterOpen(Sender: TObject);
begin
  LogPutLine(0, '8> '+ComPort8.Port+' Open');
  ComPort8.ClearBuffer(True, True);
  ComPortInit(8);
end;

procedure TForm1.ComPort8DSRChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDSRChange(8, OnOff);
end;

procedure TForm1.ComPort8Ring(Sender: TObject);
begin
  ComPortRing(8);
end;

procedure TForm1.ComPort8RLSDChange(Sender: TObject; OnOff: Boolean);
begin
  ComPortDCDChange(8, OnOff);
end;

procedure TForm1.ComPort8RxChar(Sender: TObject; Count: Integer);
var
  Buffer : Array[0..1000] of Byte;
begin
  Count := ComPort8.Read(Buffer, Min(Count, Sizeof(Buffer)));
  ComPortReceive(8, Count, Buffer);
end;

// ****************************************************************************
procedure TForm1.staPort1DblClick(Sender: TObject);
begin
  BouncePort(1);
end;

procedure TForm1.staPort2DblClick(Sender: TObject);
begin
  BouncePort(2);
end;

procedure TForm1.staPort3DblClick(Sender: TObject);
begin
  BouncePort(3);
end;

procedure TForm1.staPort4DblClick(Sender: TObject);
begin
  BouncePort(4);
end;

procedure TForm1.staPort5DblClick(Sender: TObject);
begin
  BouncePort(5);
end;

procedure TForm1.staPort6DblClick(Sender: TObject);
begin
  BouncePort(6);
end;

procedure TForm1.staPort7DblClick(Sender: TObject);
begin
  BouncePort(7);
end;

procedure TForm1.staPort8DblClick(Sender: TObject);
begin
  BouncePort(8);
end;

// ****************************************************************************
procedure TForm1.staUpstream1DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[1] then
  begin
    AddLog(2, 0, 1, 'Upstream Link 1 reconnect');
    UpstreamDisconnect(1);
  end;
end;

procedure TForm1.staUpstream1Click(Sender: TObject);
begin
  TestSession(1);
end;

procedure TForm1.staUpstream2DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[2] then
  begin
    AddLog(2, 0, 2, 'Upstream Link 2 reconnect');
    UpstreamDisconnect(2);
  end;
end;

procedure TForm1.staUpstream2Click(Sender: TObject);
begin
  TestSession(2);
end;

procedure TForm1.staUpstream3DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[3] then
  begin
    AddLog(2, 0, 3, 'Upstream Link 3 reconnect');
    UpstreamDisconnect(3);
  end;
end;

procedure TForm1.staUpstream3Click(Sender: TObject);
begin
  TestSession(3);
end;

procedure TForm1.staUpstream4DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[4] then
  begin
    AddLog(2, 0, 4, 'Upstream  Link 4 reconnect');
    UpstreamDisconnect(4);
  end;
end;

procedure TForm1.staUpstream4Click(Sender: TObject);
begin
  TestSession(4);
end;

procedure TForm1.staUpstream5DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[5] then
  begin
    AddLog(2, 0, 5, 'Upstream  Link 5 reconnect');
    UpstreamDisconnect(5);
  end;
end;

procedure TForm1.staUpstream5Click(Sender: TObject);
begin
  TestSession(5);
end;

procedure TForm1.staUpstream6DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[6] then
  begin
    AddLog(2, 0, 6, 'Upstream reconnect');
    UpstreamDisconnect(6);
  end;
end;

procedure TForm1.staUpstream6Click(Sender: TObject);
begin
  TestSession(6);
end;

procedure TForm1.staUpstream7DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[7] then
  begin
    AddLog(2, 0, 7, 'Upstream reconnect');
    UpstreamDisconnect(7);
  end;
end;

procedure TForm1.staUpstream7Click(Sender: TObject);
begin
  TestSession(7);
end;

procedure TForm1.staUpstream8DblClick(Sender: TObject);
begin
  // disconnect and reconnect
  if UseUpstream[8] then
  begin
    AddLog(2, 0, 8, 'Upstream reconnect');
    UpstreamDisconnect(8);
  end;
end;

procedure TForm1.staUpstream8Click(Sender: TObject);
begin
  TestSession(8);
end;


// ****************************************************************************
procedure TForm1.IdTCPUpstream1Connected(Sender: TObject);
begin
  AddLog(3, 0, 1, 'Upstream Link 1 Connected');
  ShowStatus(1001, STA_CONNECTED);
  LinkConState[1] := CON_READY;
  LinkTimer[1] := 0;
  LinkIdle[1] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream1Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 1, 'Upstream Link 1 Disconnect');
  ShowStatus(1001, STA_DROPPED);
  LinkConState[1] := CON_DISCONNECTED;
  LinkTimer[1] := 50;
//  if upFIFO[1] <> nil then
//    upFIFO[1].Flush;
end;

//procedure TForm1.IdTCPUpstream1Status(ASender: TObject;
//  const AStatus: TIdStatus; const AStatusText: String);
//begin
//  case AStatus of
//  hsResolving: AddLog(1, 1001, '@Resolving');
//  hsConnecting: AddLog(1, 1001, '@Connecting');
//  hsConnected: AddLog(1, 1001, '@Connected');
//  hsDisconnecting: AddLog(1, 1001, '@Disconnecting');
//  hsDisconnected: AddLog(1, 1001, '@Disconnected');
//  else
//    AddLog(1, 1001, '@Else');
//  end;
//end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream2Connected(Sender: TObject);
begin
  AddLog(3, 0, 2, 'Upstream Link 2 Connected');
  ShowStatus(1002, STA_CONNECTED);
  LinkConState[2] := CON_READY;
  LinkTimer[2] := 0;
  LinkIdle[2] := 0;
  if SuspendRoute[2] then
  begin
    // activate socket listener
    if not Server1.Active and (SrvrTimer = 0) then
      SrvrTimer := 20;
  end;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream2Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 2, 'Upstream Link 2 Disconnect');
  ShowStatus(1002, STA_DROPPED);
  LinkConState[2] := CON_DISCONNECTED;
  LinkTimer[2] := 50;
  if SuspendRoute[2] then
  begin
    // deactivate socket listener when upstream connection lost
    Server1.Active := False;
    SrvrTimer := 0;
    GroupBox4.Color := clPurple;
  end;
//  if upFIFO[2] <> nil then
//    upFIFO[2].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream3Connected(Sender: TObject);
begin
  AddLog(3, 0, 3, 'Upstream Link 3 Connected');
  ShowStatus(1003, STA_CONNECTED);
  LinkConState[3] := CON_READY;
  LinkTimer[3] := 0;
  LinkIdle[3] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream3Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 3, 'Upstream Link 3 Disconnect');
  ShowStatus(1003, STA_DROPPED);
  LinkConState[3] := CON_DISCONNECTED;
  LinkTimer[3] := 50;
//  if upFIFO[3] <> nil then
//    upFIFO[3].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream4Connected(Sender: TObject);
begin
  AddLog(3, 0, 4, 'Upstream Link 4 Connected');
  ShowStatus(1004, STA_CONNECTED);
  LinkConState[4] := CON_READY;
  LinkTimer[4] := 0;
  LinkIdle[4] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream4Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 4, 'Upstream Link 4 Disconnect');
  ShowStatus(1004, STA_DROPPED);
  LinkConState[4] := CON_DISCONNECTED;
  LinkTimer[4] := 50;
//  if upFIFO[4] <> nil then
//    upFIFO[4].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream5Connected(Sender: TObject);
begin
  AddLog(3, 0, 5, 'Upstream Link 5 Connected');
  ShowStatus(1005, STA_CONNECTED);
  LinkConState[5] := CON_READY;
  LinkTimer[5] := 0;
  LinkIdle[5] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream5Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 5, 'Upstream Link 5 Disconnect');
  ShowStatus(1005, STA_DROPPED);
  LinkConState[5] := CON_DISCONNECTED;
  LinkTimer[5] := 50;
//  if upFIFO[5] <> nil then
//    upFIFO[5].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream6Connected(Sender: TObject);
begin
  AddLog(3, 0, 6, 'Upstream Link 6 Connected');
  ShowStatus(1006, STA_CONNECTED);
  LinkConState[6] := CON_READY;
  LinkTimer[6] := 0;
  LinkIdle[6] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream6Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 6, 'Upstream Link 6 Disconnect');
  ShowStatus(1006, STA_DROPPED);
  LinkConState[6] := CON_DISCONNECTED;
  LinkTimer[6] := 50;
//  if upFIFO[6] <> nil then
//    upFIFO[6].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream7Connected(Sender: TObject);
begin
  AddLog(3, 0, 7, 'Upstream Link 7 Connected');
  ShowStatus(1007, STA_CONNECTED);
  LinkConState[7] := CON_READY;
  LinkTimer[7] := 0;
  LinkIdle[7] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream7Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 7, 'Upstream Link 7 Disconnect');
  ShowStatus(1007, STA_DROPPED);
  LinkConState[7] := CON_DISCONNECTED;
  LinkTimer[7] := 50;
//  if upFIFO[7] <> nil then
//    upFIFO[7].Flush;
end;

// ****************************************************************************
procedure TForm1.IdTCPUpstream8Connected(Sender: TObject);
begin
  AddLog(3, 0, 8, 'Upstream Link 8 Connected');
  ShowStatus(1008, STA_CONNECTED);
  LinkConState[8] := CON_READY;
  LinkTimer[8] := 0;
  LinkIdle[8] := 0;
  ReceiveThread.Resume;
end;

procedure TForm1.IdTCPUpstream8Disconnected(Sender: TObject);
begin
  AddLog(3, 0, 8, 'Upstream Link 8 Disconnect');
  ShowStatus(1008, STA_DROPPED);
  LinkConState[8] := CON_DISCONNECTED;
  LinkTimer[8] := 50;
//  if upFIFO[8] <> nil then
//    upFIFO[8].Flush;
end;

// ****************************************************************************
procedure TForm1.Server1Connect(AThread: TIdPeerThread);
var
  NewClient : PServerClient;
  ndx : Integer;
  vacant : Boolean;
  str : String;
begin
  GetMem(NewClient, SizeOf(TServerClient));

  if ConnectCounter = 0 then
    ConnectCounter := 8;
  vacant := False;
  for ndx:=9 to MaxChannels do
  begin
    Inc(ConnectCounter);
    if ConnectCounter > MaxChannels then
      ConnectCounter := 9;
    if not ChannelInUse[ConnectCounter] then
    begin
      vacant := True;
      break;
    end;
  end;
  if not vacant then
  begin
    LogPutLine(2, IntToStr(ConnectCounter)+'> WARNING: All channels in use');
    NewClient.ConnectNumber := MaxChannels + 1; // Server1Execute will detect this and ignore connection
  end
  else
    NewClient.ConnectNumber := ConnectCounter;

  NewClient.Thread := AThread;
  NewClient.ConnectTimer := 0;

  AThread.Data := TObject(NewClient);

  try
    Clients.LockList.Add(NewClient);
  finally
    Clients.UnlockList;
  end;

  // update LED dsiplay
  Inc(ConnectedClients);

  if vacant and (ConnectedClients <= MaxChannels-8) then
  begin
    LogPutLine(1, IntToStr(ConnectCounter)+'> ClientConnect - '+AThread.Connection.Socket.Binding.PeerIP+' ('+IntToStr(ConnectedClients)+')');
    AcceptReceiveFrame(ReceiveState[ConnectCounter]);
    // initialise session variables
    TerminalConnected(ConnectCounter);
    ReceiveCounter[ConnectCounter] := 0;
    TransmitCounter[ConnectCounter] := 0;
    EmptyCounter1[ConnectCounter] := 0;
    EmptyCounter2[ConnectCounter] := 0;
    ChannelInUse[ConnectCounter] := True;
  end;

//  if DebugMode > 1 then
//  begin
    str := '';
    for ndx:=9 to MaxChannels do
    begin
      if ChannelInUse[ndx] then
        str := str + 'O'
      else
        str := str + '.'
    end;
    LogPutLine(1, IntToStr(ConnectCounter)+'> '+str);
//  end;
end;

// ****************************************************************************
procedure TForm1.Server1Disconnect(AThread: TIdPeerThread);
var
  ActClient: PServerClient;
  txt : String;
begin
  ActClient := PServerClient(AThread.Data);

  if TerminateCall[ActClient.ConnectNumber] >= DisconnectTimeout then
    txt := 'DroppingConnection'
  else
    txt := 'ClientDisconnect';

  if (ActClient.ConnectNumber >= Low(TransmitReady)) and (ActClient.ConnectNumber <= High(TransmitReady)) then
  begin
    TransmitReady[ActClient.ConnectNumber] := 0;
    AddLog(1, ActClient.ConnectNumber, 0, txt+' RxC='+IntToStr(ReceiveCounter[ActClient.ConnectNumber])+' TxC='+IntToStr(TransmitCounter[ActClient.ConnectNumber]));
    ConnectedTerminal[ActClient.ConnectNumber] := '';
    ConnectedSerial[ActClient.ConnectNumber] := '';
    ChannelInUse[ActClient.ConnectNumber] := False;
  end
  else
    AddLog(1, ActClient.ConnectNumber, 0, txt+' (' + IntToStr(ActClient.ConnectNumber) + ')');

  try
    Clients.LockList.Remove(ActClient);
  finally
    Clients.UnlockList;
  end;
  FreeMem(ActClient);
  AThread.Data := nil;

  if ConnectedClients > 0 then
    Dec(ConnectedClients);
end;

// ****************************************************************************
procedure TForm1.Server1Execute(AThread: TIdPeerThread);
var
  cnt : Integer;
  buf : Array[0..999] of Byte;
  ActClient : PServerClient;
  str : String;
  i : Integer;
begin
  if AThread.Terminated or not AThread.Connection.Connected then
    Exit;

  ActClient := PServerClient(AThread.Data);

  if (ActClient.ConnectNumber < 8) or (ActClient.ConnectNumber > MaxChannels) then
  begin
    AddLog(1, ActClient.ConnectNumber, 0, 'ERR: Invalid ConnectNumber '+InttoStr(ActClient.ConnectNumber));
    AThread.Connection.Disconnect;
    Exit;
  end;
  if TerminateCall[ActClient.ConnectNumber] >= DisconnectTimeout then
  begin
    AddLog(1, ActClient.ConnectNumber, 0, 'Terminating Connection');
    AThread.Connection.Disconnect;
    Exit;
  end;

  with AThread.Connection do
  begin
    if InputBuffer.Size = 0 then
    begin
      // 10ms time-out on read
      if (ReadFromStack(True, 10, False) <= 0) then
      begin
        // check idle time > inactivity value set in .ini file
        Inc(ActClient.ConnectTimer);
        if (ActClient.ConnectTimer > IdleTimeout) then
        begin
          AddLog(1, ActClient.ConnectNumber, 0, 'Inactivity time-out ('+IntToStr(ActClient.ConnectTimer)+')');
          Disconnect;
          Exit;
        end;
      end;
    end;

    if InputBuffer.Size > 0 then
    begin
      ActClient.ConnectTimer := 0;
      cnt := InputBuffer.Size;
      if cnt > Sizeof(Buf) then
        cnt := Sizeof(Buf);
      // Copy it to the callers buffer
      Move(InputBuffer.Memory^, buf, cnt);
      // Remove used data from buffer
      InputBuffer.Remove(cnt);
      // Discard data if TerminateCall[] set
//      if TerminateCall[ActClient.ConnectNumber] > 1 then
//      begin
        // Pump data through receive-state-machine
        if not ReceiveMessage(ActClient.ConnectNumber, ActClient.ConnectTimer, cnt, buf) then
        begin
          AddLog(1, ActClient.ConnectNumber, 0, 'ERR: Exit on ReceiveMessage()');
          Disconnect;
          Exit;
        end;
//      end
//      else
//        AddLog(1, ActClient.ConnectNumber, 0, 'discarding data... ');
    end;
  end;

  if TransmitLength[ActClient.ConnectNumber] = 0 then
  begin
    if TransmitReady[ActClient.ConnectNumber] = 1 then
    begin
      TransmitReady[ActClient.ConnectNumber] := 0;
      // grab paylod from ChannelFIFO and build transnmit frame in FrameBuffer
      BuildMessage(ActClient.ConnectNumber);
    end;
  end;

  if FrameLength[ActClient.ConnectNumber] > 0 then
  begin
//    if DebugMode > 2 then
//    begin
//      str := 'TX Term ['+IntToStr(FrameLength[ActClient.ConnectNumber])+'] ';
//      if DebugMode > 3 then
//      begin
//        for i := 0 to FrameLength[ActClient.ConnectNumber]-1 do
//          str := str + IntToHex(FrameBuffer[ActClient.ConnectNumber][i],2);
//      end;
//      AddLog(0, ActClient.ConnectNumber, 0, str);          +' '+IntToStr(TerminateCall[PortNum])
//    end;
//AddLog(0, ActClient.ConnectNumber, 0, '...shipping...on...'+IntToStr(ActClient.ConnectNumber)+' '+IntToStr(TerminateCall[ActClient.ConnectNumber]));

    Inc(TransmitCounter[ActClient.ConnectNumber], FrameLength[ActClient.ConnectNumber]);
    AThread.Connection.WriteBuffer(FrameBuffer[ActClient.ConnectNumber], FrameLength[ActClient.ConnectNumber], True);
    FlushTransmitter(ActClient.ConnectNumber);
  end;

end;

// ****************************************************************************
procedure TForm1.Server1ListenException(AThread: TIdListenerThread;
  AException: Exception);
begin
  AddLog(2, 0, 0, 'TCP Listen Exception: '+AException.Message);
end;

procedure TForm1.Server1Exception(AThread: TIdPeerThread;
  AException: Exception);
begin
  // 'SOCKET>TCP Server Exception: Connection Closed Gracefully.'
  if AException.Message <> 'Connection Closed Gracefully.' then
    AddLog(2, 0, 0, 'TCP Server Exception: '+AException.Message);
end;


// ****************************************************************************
begin
  MaxChannels := 48;
  AnswerDelay := 0;
  ConnectCounter := 0;
  ConnectedClients := 0;
  DebugMode := 0;
  PingTime[1] := 0;
  PingTime[2] := 0;
  PingTime[3] := 0;
  PingTime[4] := 0;
  PingTime[5] := 0;
  PingTime[6] := 0;
  PingTime[7] := 0;
  PingTime[8] := 0;
  upFIFO[1] := nil;
  upFIFO[2] := nil;
  upFIFO[3] := nil;
  upFIFO[4] := nil;
  upFIFO[5] := nil;
  upFIFO[6] := nil;
  upFIFO[7] := nil;
  upFIFO[8] := nil;
  downFIFO[1] := nil;
  downFIFO[2] := nil;
  downFIFO[3] := nil;
  downFIFO[4] := nil;
  downFIFO[5] := nil;
  downFIFO[6] := nil;
  downFIFO[7] := nil;
  downFIFO[8] := nil;
  SuspendRoute[1] := False;
  SuspendRoute[2] := False;
  SuspendRoute[3] := False;
  SuspendRoute[4] := False;
  SuspendRoute[5] := False;
  SuspendRoute[6] := False;
  SuspendRoute[7] := False;
  SuspendRoute[8] := False;
end.

