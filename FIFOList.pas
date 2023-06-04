unit FIFOList;

{$MODE Delphi}

interface
  uses StdCtrls, Classes, SysUtils, LCLIntf, LCLType, LMessages, SyncObjs;

  const
    ITEM_BUFFER_SIZE = 8192;

  type
    TItem = record
      OwnerID : Int64;
      Buffer : array[0..ITEM_BUFFER_SIZE+1] of Byte;
      Size : Integer;
    end;

    PFIFOList = ^TFIFOList;
    TFIFOList = class
      private
        csList : TCriticalSection;  // Critical section for this unit.
        Head : Integer;
        Tail : Integer;
        List : Array[0..98] of TItem;
      public
        constructor Create;
        procedure Startup;
        procedure Shutdown;
        procedure Flush;
        function AddItem(var Item : TItem) : Boolean;
        function RemoveItem(var Item : TItem) : Boolean;
        function ReadItem(var Item : TItem) : Boolean;
        function DropItem : Boolean;
        function ItemCount : Integer;
      end;

implementation

// ***********************************************
constructor TFIFOList.Create;
begin
  csList := nil;
end;

// ***********************************************
procedure TFIFOList.Startup;
begin
  Head := 0;
  Tail := 0;
  if csList = nil then
    csList := TCriticalSection.Create;
end;

// ***********************************************
procedure TFIFOList.Shutdown;
begin
  if csList <> nil then
  begin
    csList.Free;
    csList := nil;
  end;
end;

// ***********************************************
procedure TFIFOList.Flush;
begin
  Head := 0;
  Tail := 0;
end;

// ***********************************************
function TFIFOList.AddItem(var Item : TItem) : Boolean;
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
function TFIFOList.RemoveItem(var Item : TItem) : Boolean;
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
function TFIFOList.ReadItem(var Item : TItem) : Boolean;
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
function TFIFOList.DropItem : Boolean;
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
function TFIFOList.ItemCount : Integer;
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