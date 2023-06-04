program CommSrvr;

{$MODE Delphi}

uses
  Forms, Interfaces,
  Unit1 in 'Unit1.pas' {Form1},
  INIFile in 'INIFile.pas',
  Frames in 'Frames.pas',
  CalcCRC in 'CalcCrc.pas',
  SysDef in 'SysDef.pas',
  LogList in 'LogList.pas',
  FIFOList in 'FIFOList.pas',
  Upstream in 'Upstream.pas',
  Protocol in 'Protocol.pas',
  md5 in 'md5.pas',
  FIFOList2 in 'FIFOList2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
