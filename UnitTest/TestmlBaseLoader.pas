unit TestmlBaseLoader;

interface

uses
  TestFramework,
  Windows,
  Classes,
  SysUtils,
  mlBaseLoader,
  mlTypes,
  TestConstants;

type
  // Test methods for class TSingleLoader
  TestTMlBaseLoader = class(TTestCase)
  private
    fMemStream: TMemoryStream;
    fMlBaseLoader: TMlBaseLoader;
    procedure LoadHelper(aPath: String);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLoadFromStreamValid;
    procedure TestLoadFromStreamInvalid;
    procedure TestLoadFromStreamEmpty;
    procedure TestGetFunctionAddressValid;
    procedure TestGetFunctionAddressInvalidName;
    procedure TestFindResourceValid;
    procedure TestFindResourceNonExistingName;
    procedure TestFindResourceNonExistingType;
    procedure TestLoadResourceValid;
    procedure TestLoadResourceValidCompareToWinapi;
    procedure TestLoadResourceInvalidByZeroHandle;
    procedure TestLoadResourceInvalidByWrongHandle;
    procedure TestSizeOfResourceValid;
    procedure TestSizeOfResourceValidCompareToWinapi;
    procedure TestSizeOfResourceInvalidByZeroHandle;
    procedure TestSizeOfResourceInvalidByWrongHandle;
  end;

implementation

procedure TestTMlBaseLoader.LoadHelper(aPath: String);
begin
  fMemStream.LoadFromFile(aPath);
  fMlBaseLoader.LoadFromStream(fMemStream);
end;

procedure TestTMlBaseLoader.SetUp;
begin
  fMemStream := TMemoryStream.Create;
  fMlBaseLoader := TMlBaseLoader.Create;
end;

procedure TestTMlBaseLoader.TearDown;
begin
  fMemStream.Free;
  fMlBaseLoader.Free;
end;

procedure TestTMlBaseLoader.TestLoadFromStreamValid;
begin
  fMemStream.LoadFromFile(DLL_PATH);
  fMlBaseLoader.LoadFromStream(fMemStream);
end;

procedure TestTMlBaseLoader.TestLoadFromStreamInvalid;
var
  I: Cardinal;
begin
  // Try to load from an invalid stream filled with some data
  fMemStream.Size := 100000;
  Randomize;
  for I := 0 to fMemStream.Size - 1 do
    PByte(Cardinal(fMemStream.Memory) + I)^ := Byte(I);
  ExpectedException := EMlLibraryLoadError;
  fMlBaseLoader.LoadFromStream(fMemStream);
end;

procedure TestTMlBaseLoader.TestLoadFromStreamEmpty;
begin
  // Try to load from an empty strem
  fMemStream.Clear;
  ExpectedException := EMlLibraryLoadError;
  fMlBaseLoader.LoadFromStream(fMemStream);
end;

procedure TestTMlBaseLoader.TestGetFunctionAddressValid;
var
  ReturnValue: Pointer;
begin
  LoadHelper(DLL_PATH);
  ReturnValue := fMlBaseLoader.GetFunctionAddress(TEST_FUNCTION_NAME);
  CheckMethodIsNotEmpty(ReturnValue);
end;

procedure TestTMlBaseLoader.TestGetFunctionAddressInvalidName;
begin
  LoadHelper(DLL_PATH);
  ExpectedException := EMlProcedureError;
  fMlBaseLoader.GetFunctionAddress('Some invalid function name');
end;

procedure TestTMlBaseLoader.TestFindResourceValid;
var
  ResourceFound: HRSRC;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_RES_TYPE);
  CheckNotEquals(0, ResourceFound);
end;

procedure TestTMlBaseLoader.TestFindResourceNonExistingName;
var
  ResourceFound: HRSRC;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource('Res name that doesn''t exist in the lib', TEST_RES_TYPE);
  CheckEquals(0, ResourceFound);
end;

procedure TestTMlBaseLoader.TestFindResourceNonExistingType;
var
  ResourceFound: HRSRC;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_NONEXISTING_RES_TYPE);
  CheckEquals(0, ResourceFound);
end;

procedure TestTMlBaseLoader.TestLoadResourceValid;
var
  ResourceFound: HRSRC;
  ResourcePointer: THandle;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_RES_TYPE);
  ResourcePointer := fMlBaseLoader.LoadResource(ResourceFound);
  CheckNotEquals(0, ResourcePointer);
end;

procedure TestTMlBaseLoader.TestLoadResourceValidCompareToWinapi;
var
  LibWin: THandle;
  ResourceFound, ResourceWin: HRSRC;
  ResourceHandle, ResourceHandleWin: THandle;
  ResourceSize: DWORD;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_RES_TYPE);
  ResourceHandle := fMlBaseLoader.LoadResource(ResourceFound);
  ResourceSize := fMlBaseLoader.SizeOfResource(ResourceFound);

  LibWin := LoadLibrary(DLL_PATH);
  ResourceWin := FindResource(LibWin, TEST_RES_NAME, TEST_RES_TYPE);
  ResourceHandleWin := LoadResource(LibWin, ResourceWin);

  CheckTrue(CompareMem(Pointer(ResourceHandle), Pointer(ResourceHandleWin), ResourceSize),
    'The raw resource content in memory should be the same as from the WinAPI');
end;

procedure TestTMlBaseLoader.TestLoadResourceInvalidByZeroHandle;
begin
  LoadHelper(DLL_PATH);
  ExpectedException := EMlResourceError;
  fMlBaseLoader.LoadResource(0);
end;

procedure TestTMlBaseLoader.TestLoadResourceInvalidByWrongHandle;
begin
  LoadHelper(DLL_PATH);
  ExpectedException := EMlResourceError;
  fMlBaseLoader.LoadResource(TEST_WRONG_RES_HANDLE);
end;

procedure TestTMlBaseLoader.TestSizeOfResourceValid;
var
  ResourceFound: HRSRC;
  ResourceSize: DWORD;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_RES_TYPE);
  ResourceSize := fMlBaseLoader.SizeOfResource(ResourceFound);
  CheckEquals(TEST_RES_SIZE, ResourceSize);
end;

procedure TestTMlBaseLoader.TestSizeOfResourceValidCompareToWinapi;
var
  LibWin: THandle;
  ResourceFound, ResourceWin: HRSRC;
  ResourceSize, ResourceSizeWin: DWORD;
begin
  LoadHelper(DLL_PATH);
  ResourceFound := fMlBaseLoader.FindResource(TEST_RES_NAME, TEST_RES_TYPE);
  ResourceSize := fMlBaseLoader.SizeOfResource(ResourceFound);

  LibWin := LoadLibrary(DLL_PATH);
  ResourceWin := FindResource(LibWin, TEST_RES_NAME, TEST_RES_TYPE);
  ResourceSizeWin := SizeofResource(LibWin, ResourceWin);

  CheckEquals(ResourceSizeWin, ResourceSize, 'Windows API returned a different resource size');
end;

procedure TestTMlBaseLoader.TestSizeOfResourceInvalidByZeroHandle;
begin
  LoadHelper(DLL_PATH);
  ExpectedException := EMlResourceError;
  fMlBaseLoader.SizeOfResource(0);
end;

procedure TestTMlBaseLoader.TestSizeOfResourceInvalidByWrongHandle;
begin
  LoadHelper(DLL_PATH);
  ExpectedException := EMlResourceError;
  fMlBaseLoader.SizeOfResource(TEST_WRONG_RES_HANDLE);
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTMlBaseLoader.Suite);

end.

