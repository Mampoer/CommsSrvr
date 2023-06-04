unit FIFOList2;

{$MODE Delphi}

interface
  uses StdCtrls, Classes, SysUtils, LCLIntf, LCLType, LMessages, SyncObjs;

  const
    ITEM_BUFFER_SIZE = 8192;

  type
    TItem2 = record
      OwnerID : Int64;
      Buffer : array[0..ITEM_BUFFER_SIZE+1] of Byte;
      Size : Integer;
    end;

    PFIFOList2 = ^TFIFOList2;
    TFIFOList2 = class
      private
        csList : TCriticalSection;  // Critical section for this unit.
        Head : Integer;
        Tail : Integer;
        List : Array[0..7] of TItem2;
      public
        constructor Create;
        procedure Startup;
        procedure Shutdown;
        procedure Flush;
        function AddItem(var Item : TItem2) : Boolean;
        function RemoveItem(var Item : TItem2) : Boolean;
        function ReadItem(var Item : TItem2) : Boolean;
        function DropItem : Boolean;
        function ItemCount : Integer;
      end;

implementation

// ***********************************************
constructor TFIFOList2.Create;
begin
  csList := nil;
end;

// ***********************************************
procedure TFIFOList2.Startup;
begin
  Head := 0;
  Tail := 0;
  if csList = nil then
    csList := TCriticalSection.Create;
end;

// ***********************************************
procedure TFIFOList2.Shutdown;
begin
  if csList <> nil then
  begin
    csList.Free;
    csList := nil;
  end;
end;

// ***********************************************
procedure TFIFOList2.Flush;
begin
  Head := 0;
  Tail := 0;
end;

// ***********************************************
function TFIFOList2.AddItem(var Item : TItem2) : Boolean;
var
  NewHead : Integer;
begin
  Result := False;
  if csList = nil then
    Exit;
  // prevent buffer overflow
  if Item.Size >= ITEM_BUFFER_SIZE then
    Exit;
  // only one thread at a time can add entry to list
  csList.Enter;
  try
    NewHead := Head + 1;
    if NewHead >= High(List) then NewHead := 0;
    // only add if list not full
    if NewHead <> Tail then
    begin
      List[Head].OwnerID := Item.OwnerID;
      Move(Item.Buffer, List[Head].Buffer, Item.Size);
      List[Head].Size := Item.Size;
      Head := NewHead;
      Result := True;
    end;
  finally
    csList.Leave;
  end;
end;

// ***********************************************
function TFIFOList2.RemoveItem(var Item : TItem2) : Boolean;
begin
  Result := False;
  if csList = nil then
    Exit;
  csList.Enter;
  try
    // do nothing if list empty and return False
    if Tail <> Head then
    begin
      Item.OwnerID := List[Tail].OwnerID;
      Item.Size := List[Tail].Size;
      Move(List[Tail].Buffer, Item.Buffer, Item.Size);
      Inc(Tail);
      if Tail >= High(List) then Tail := 0;
      Result := True;
    end;
  finally
    csList.Leave;
  end;
end;

// ***********************************************
function TFIFOList2.ReadItem(var Item : TItem2) : Boolean;
begin
  Result := False;
  if csList = nil then
    Exit;
  csList.Enter;
  try
    // do nothing if list empty and return False
    if Tail <> Head then
    begin
      Item.OwnerID := List[Tail].OwnerID;
      Item.Size := List[Tail].Size;
      Move(List[Tail].Buffer, Item.Buffer, Item.Size);
      Result := True;
    end;
  finally
    csList.Leave;
  end;
end;

// ***********************************************
function TFIFOList2.DropItem : Boolean;
begin
  Result := False;
  if csList = nil then
    Exit;
  csList.Enter;
  try
    // do nothing if list empty and return False
    if Tail <> Head then
    begin
      Inc(Tail);
      if Tail >= High(List) then Tail := 0;
      Result := True;
    end;
  finally
    csList.Leave;
  end;
end;

// ***********************************************
function TFIFOList2.ItemCount : Integer;
var
  i : Integer;
begin
  Result := 0;
  if csList = nil then
    Exit;
  csList.Enter;
  try
    i := Tail;
    while (i <> Head) do
    begin
      Inc(i);
      if i >= High(List) then i := 0;
      Inc(Result);
    end;
  finally
    csList.Leave;
  end;
end;

end.
