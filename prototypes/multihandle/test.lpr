{
  Proof of concept test app for multi-handle GUI widgets.
  Graeme Geldenhuys
}

program test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes
  ,gui2Base
  ,gfxbase
  ,fpgfx
  ;
  
  
type

  { TMainWindow }

  TMainWindow = class(TForm)
    procedure btnCancelClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPopupClick(Sender: TObject);
  private
    btnClose: TButton;
    btnCancel: TButton;
    btnPopup: TButton;
    lblWelcome: TLabel;
    edEdit: TEdit;
  public
    constructor Create; override;
    destructor  Destroy; override;
  end;
  
  
  TMyPopup = class(TPopupWindow)
  public
    constructor Create; override;
  end;

{ TMyPopup }

constructor TMyPopup.Create;
begin
  inherited Create;
  SetClientSize(Size(150, 320));
end;

{ TMainWindow }

procedure TMainWindow.btnCancelClick(Sender: TObject);
begin
  Writeln('You click Cancel');
end;

procedure TMainWindow.btnCloseClick(Sender: TObject);
begin
  Writeln('You click Close');
  GFApplication.Quit;
end;

procedure TMainWindow.btnPopupClick(Sender: TObject);
var
  frm: TMyPopup;
begin
  frm := TMyPopup.Create;
  frm.FParent := self;

  GFApplication.AddWindow(frm);
  frm.Show;
  frm.SetPosition(Point(0, btnPopup.Height));
end;

constructor TMainWindow.Create;
begin
  inherited Create;
  Title := 'fpGUI multi-handle example';
  SetClientSize(Size(320, 200));

  btnClose := TButton.Create(self, Point(20, 150));
  btnClose.Caption := 'Close';
  btnClose.OnClick := @btnCloseClick;

  btnCancel := TButton.Create(self, Point(150, 150));
  btnCancel.Caption := 'Cancel';
  btnCancel.OnClick := @btnCancelClick;
  
  btnPopup := TButton.Create(self, Point(80, 80));
  btnPopup.Caption := 'Popup';
  btnPopup.OnClick := @btnPopupClick;

  lblWelcome := TLabel.Create(self, Point(10, 10));
  lblWelcome.Caption := 'So what do you think?';
  
  edEdit := TEdit.Create(self, Point(65, 110));
  edEdit.Text := 'Multi-Handle widgets';
end;

destructor TMainWindow.Destroy;
begin
  btnClose.Free;
  btnCancel.Free;
  btnPopup.Free;
  lblWelcome.Free;
  inherited Destroy;
end;


var
  MainWindow: TMainWindow;
begin
  GFApplication.Initialize;
  MainWindow := TMainWindow.Create;
  GFApplication.AddWindow(MainWindow);
  MainWindow.Show;
  GFApplication.Run;
end.

