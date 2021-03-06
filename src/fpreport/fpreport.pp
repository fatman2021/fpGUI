{
    This file is part of the Free Component Library.
    Copyright (c) 2008 Michael Van Canneyt, member of the Free Pascal development team
    Portions (c) 2016 WISA b.v.b.a.

    GUI independent reporting engine core

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit fpreport;

{$mode objfpc}{$H+}
{$inline on}

{.$define gdebug}

interface

uses
  Classes,
  SysUtils,
  Variants,
  contnrs,
  fpCanvas,
  fpImage,
  fpreportstreamer,
{$IF FPC_FULLVERSION>=30101}
  fpexprpars,
{$ELSE}
  fprepexprpars,
{$ENDIF}
  fpReportHTMLParser;

type

  // Do not use other types than the ones below in fpreport.
  TFPReportString = string;
  TFPReportUnits  = single; // Units are defined as Millimetres
  TFPReportScale  = single;
  TFPReportColor  = type UInt32;

  // A position in report units
  TFPReportPoint = record
    Top: TFPReportUnits;
    Left: TFPReportUnits;
  end;

  // A rectangle in report units (measures)

  { TFPReportRect }

  TFPReportRect = object  // not a class for static allocations. Not a record because we want methods
    Top: TFPReportUnits;
    Left: TFPReportUnits;
    Width: TFPReportUnits;
    Height: TFPReportUnits;
    procedure SetRect(aleft, atop, awidth, aheight: TFPReportUnits);
    Procedure OffsetRect(aLeft,ATop : TFPReportUnits);
    Function IsEmpty : Boolean;
    function Bottom: TFPReportUnits;
    function Right: TFPReportUnits;
    function AsString : String;
  end;


  // Scaling factors (mostly for zoom/resize)
  TFPReportScales = record
    Vertical: TFPreportScale;
    Horizontal: TFPreportScale;
  end;


  // Forward declarations
  TFPReportElement        = class;
  TFPCustomReport         = class;
  TFPReportCustomBand     = class;
  TFPReportCustomPage     = class;
  TFPReportCustomGroupFooterBand = class;
  TFPReportData           = class;
  TFPReportFrame          = class;
  TFPReportCustomMemo     = class;
  TFPReportChildBand      = class;
  TFPReportCustomDataBand = class;
  TFPReportCustomDataHeaderBand = class;
  TFPReportCustomDataFooterBand = class;
  TFPReportCustomGroupHeaderBand = class;
  TFPReportExporter       = class;
  TFPReportTextAlignment  = class;
  TBandList = class;

  TFPReportElementClass   = class of TFPReportElement;
  TFPReportBandClass      = class of TFPReportCustomBand;

  TFPReportState          = (rsDesign, rsLayout, rsRender);
  TFPReportPaperOrientation = (poPortrait, poLandscape);
  TFPReportVertTextAlignment = (tlTop, tlCenter, tlBottom);
  TFPReportHorzTextAlignment = (taLeftJustified, taRightJustified, taCentered, taWidth);
  TFPReportShapeType      = (stEllipse, stCircle, stLine, stSquare, stTriangle, stRoundedRect{, stArrow});  // rectangle can be handled by Frame
  TFPReportOrientation    = (orNorth, orNorthEast, orEast, orSouthEast, orSouth, orSouthWest, orWest, orNorthWest);
  TFPReportFrameLine      = (flTop, flBottom, flLeft, flRight);
  TFPReportFrameLines     = set of TFPReportFrameLine;
  TFPReportFrameShape     = (fsNone, fsRectangle, fsRoundedRect, fsDoubleRect, fsShadow);
  TFPReportFieldKind      = (rfkString, rfkBoolean, rfkInteger, rfkFloat, rfkDateTime, rfkStream);
  TFPReportStretchMode    = (smDontStretch, smActualHeight, smMaxHeight);
  TFPReportHTMLTag        = (htRegular, htBold, htItalic);
  TFPReportHTMLTagSet     = set of TFPReportHTMLTag;
  TFPReportColumnLayout   = (clVertical, clHorizontal);
  TFPReportFooterPosition = (fpAfterLast, fpColumnBottom);
  TFPReportVisibleOnPage  = (vpAll, vpFirstOnly, vpLastOnly, vpFirstAndLastOnly, vpNotOnFirst, vpNotOnLast, vpNotOnFirstAndLast);
  // For color coding
  TFPReportBandType       = (btUnknown,btPageHeader,btReportTitle,btColumnHeader,btDataHeader,btGroupHeader,btDataband,btGroupFooter,
                             btDataFooter,btColumnFooter,btReportSummary,btPageFooter,btChild);
  TFPReportMemoOption     = (
            moSuppressRepeated,
            moHideZeros,
            moDisableExpressions,
            moAllowHTML,
            moDisableWordWrap,
            moNoResetAggregateOnPrint,
            moResetAggregateOnGroup,
            moResetAggregateOnPage,
            moResetAggregateOnColumn
            );
  TFPReportMemoOptions    = set of TFPReportMemoOption;

const
  { The format is always RRGGBB (Red, Green, Blue) - no alpha channel }
  clNone          = TFPReportColor($80000000);  // a special condition: $80 00 00 00
  { commonly known colors }
  clAqua          = TFPReportColor($00FFFF);
  clBlack         = TFPReportColor($000000);
  clBlue          = TFPReportColor($0000FF);
  clCream         = TFPReportColor($FFFBF0);
  clDkGray        = TFPReportColor($A9A9A9);
  clFuchsia       = TFPReportColor($FF00FF);
  clGray          = TFPReportColor($808080);
  clGreen         = TFPReportColor($008000);
  clLime          = TFPReportColor($00FF00);
  clLtGray        = TFPReportColor($C0C0C0);
  clMaroon        = TFPReportColor($800000);
  clNavy          = TFPReportColor($000080);
  clOlive         = TFPReportColor($808000);
  clPurple        = TFPReportColor($800080);
  clRed           = TFPReportColor($FF0000);
  clDkRed         = TFPReportColor($C00000);
  clSilver        = TFPReportColor($C0C0C0);
  clTeal          = TFPReportColor($008080);
  clWhite         = TFPReportColor($FFFFFF);
  clYellow        = TFPReportColor($FFFF00);
  { some common alias colors }
  clCyan          = clAqua;
  clMagenta       = clFuchsia;

const
  { Some color constants used throughout the demos, designer and documentation. }
  clPageHeaderFooter    = TFPReportColor($E4E4E4);
  clReportTitleSummary  = TFPReportColor($63CF80);
  clGroupHeaderFooter   = TFPReportColor($FFF1D7);
  clColumnHeaderFooter  = TFPReportColor($FF8E62);
  clDataHeaderFooter    = TFPReportColor($CBD5EC);
  clDataBand            = TFPReportColor($89B7EA);
  clChildBand           = TFPReportColor($B4DFFF);


  DefaultBandColors : Array[TFPReportBandType] of TFPReportColor = (
    clNone,                 // Unknown
    clPageHeaderFooter,     // Page header
    clReportTitleSummary,   // Report Title
    clColumnHeaderFooter,   // Column header
    clDataHeaderFooter,     // Data header
    clGroupHeaderFooter,    // Group header
    clDataBand,             // Databand
    clGroupHeaderFooter,    // Group footer
    clDataHeaderFooter,     // Data footer
    clColumnHeaderFooter,   // Column footer
    clReportTitleSummary,   // Report summary
    clPageHeaderFooter,     // Page footer
    clChildBand             // Child
  );

  clDarkMoneyGreen = TFPReportColor($A0BCA0);

  { These are default values, but replaced with darker version of DefaultBandColors[] }
  DefaultBandRectangleColors : Array[TFPReportBandType] of TFPReportColor = (
    clNone,              // Unknown
    clDarkMoneyGreen,    // Page header
    cldkGray,            // Report Title
    clDarkMoneyGreen,    // Column header
    clDarkMoneyGreen,    // Data header
    clDarkMoneyGreen,    // Group header
    clBlue,              // Databand
    clDarkMoneyGreen,    // Group footer
    clDarkMoneyGreen,    // Data footer
    clDarkMoneyGreen,    // Column footer
    clDarkMoneyGreen,    // Report summary
    clDarkMoneyGreen,    // Page footer
    clDkGray             // Child
  );

const
  cMMperInch = 25.4;
  cCMperInch = 2.54;
  cMMperCM = 10;
  DefaultBandNames : Array[TFPReportBandType] of string
    = ('Unknown','Page Header','Report Title','Column Header', 'Data Header','Group Header','Data','Group Footer',
       'Data Footer','Column Footer','Report Summary','PageFooter','Child');

type
  // Event handlers
  TFPReportGetEOFEvent      = procedure(Sender: TObject; var IsEOF: boolean) of object;
  TFPReportGetValueEvent    = procedure(Sender: TObject; const AValueName: string; var AValue: variant) of object;
  TFPReportBeginReportEvent = procedure of object;
  TFPReportEndReportEvent   = procedure of object;
  TFPReportGetValueNamesEvent = procedure(Sender: TObject; List: TStrings) of object;
  TFPReportBeforePrintEvent = procedure(Sender: TFPReportElement) of object;


  TFPReportExporterConfigHandler = Procedure (Sender : TObject; AExporter : TFPReportExporter; var Cancelled : Boolean) of object;

  { TFPReportExporter }

  TFPReportExporter = class(TComponent)
  private
    FAutoRun: Boolean;
    FBaseFileName: string;
    FPReport: TFPCustomReport;
    procedure SetFPReport(AValue: TFPCustomReport);
  protected
    procedure SetBaseFileName(AValue: string); virtual;
    Procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoExecute(const ARTObjects: TFPList); virtual; abstract;
    // Override this to render an image on the indicated position. If AImage is non-nil on return, it will be freed by caller.
    Procedure RenderImage(aPos : TFPReportRect; var AImage: TFPCustomImage) ; virtual;
    Procedure RenderUnknownElement(aBasePos : TFPReportPoint; AElement : TFPReportElement; ADPI : Integer);
    Class function DefaultConfig : TFPReportExporterConfigHandler; virtual;
  public
    procedure Execute;
    // Descendents can treat this as a hint to set the filename.
    Procedure SetFileName(Const aFileName : String);virtual;
    Class Procedure RegisterExporter;
    Class Procedure UnRegisterExporter;
    Class Function Description : String; virtual;
    Class Function Name : String; virtual;
    // DefaultExtension should return non-empty if output is file based.
    // Must contain .
    Class Function DefaultExtension : String; virtual;
    Function ShowConfig : Boolean;
  Published
    Property AutoRun : Boolean Read FAutoRun Write FAutoRun;
    property Report: TFPCustomReport read FPReport write SetFPReport;
  end;
  TFPReportExporterClass = Class of TFPReportExporter;


  // Width & Height are in portrait position, units: millimetres.
  TFPReportPaperSize = class(TObject)
  private
    FWidth: TFPReportUnits;
    FHeight: TFPReportUnits;
  public
    constructor Create(const AWidth, AHeight: TFPReportUnits);
    property Width: TFPReportUnits read FWidth;
    property Height: TFPReportUnits read FHeight;
  end;


  TFPReportFont = class(TPersistent)
  private
    FFontName: string;
    FFontSize: integer;
    FFontColor: TFPReportColor;
    procedure   SetFontName(const avalue: string);
    procedure   SetFontSize(const avalue: integer);
    procedure   SetFontColor(const avalue: TFPReportColor);
  public
    constructor Create; virtual;
    procedure   Assign(Source: TPersistent); override;
    property    Name: string read FFontName write SetFontName;
    { value is in font Point units }
    property    Size: integer read FFontSize write SetFontSize default 10;
    property    Color: TFPReportColor read FFontColor write SetFontColor default clBlack;
  end;


  TFPReportComponent = class(TComponent)
  private
    FReportState: TFPReportState;
  protected
    // called when the layouter starts its job on the report.
    procedure StartLayout; virtual;
    // called when the layouter ends its job on the report.
    procedure EndLayout; virtual;
    // called when the renderer starts its job on the report.
    procedure StartRender; virtual;
    // called when the renderer ends its job on the report.
    procedure EndRender; virtual;
  public
    procedure WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); virtual;
    procedure ReadElement(AReader: TFPReportStreamer); virtual;
    property ReportState: TFPReportState read FReportState;
  end;




  // The Memo text is prepared as one or more TFPTextBlock objects for the report renderers
  TFPTextBlock = class(TObject)
  public
    Pos: TFPReportPoint;
    Width: TFPReportUnits;
    Height: TFPReportUnits;
    Descender: TFPReportUnits;
    Text: TFPReportString;
    FontName: string;
    FGColor: TFPReportColor;
    BGColor: TFPReportColor;
  end;

  // Extension of TFPTextBlock with support to hold URL information
  TFPHTTPTextBlock = class(TFPTextBlock)
  private
    FURL: String;
  public
    property URL: string read FURL write FURL;
  end;


  TFPTextBlockList = class(TFPObjectList)
  protected
    function GetItem(AIndex: Integer): TFPTextBlock; reintroduce;
    procedure SetItem(AIndex: Integer; AObject: TFPTextBlock); reintroduce;
  public
    property Items[AIndex: Integer]: TFPTextBlock read GetItem write SetItem; default;
  end;


  TFPReportDataField = class(TCollectionItem)
  private
    FDisplayWidth: integer;
    FFieldKind: TFPReportFieldKind;
    FFieldName: string;
  public
    function GetValue: variant; virtual;
    procedure Assign(Source: TPersistent); override;
  published
    property FieldName: string read FFieldName write FFieldName;
    property FieldKind: TFPReportFieldKind read FFieldKind write FFieldKind;
    property DisplayWidth: integer read FDisplayWidth write FDisplayWidth;
  end;


  TFPReportDataFields = class(TCollection)
  private
    FReportData: TFPReportData;
    function GetF(AIndex: integer): TFPReportDataField;
    procedure SetF(AIndex: integer; const AValue: TFPReportDataField);
  public
    function AddField(AFieldName: string; AFieldKind: TFPReportFieldKind): TFPReportDataField;
    function IndexOfField(const AFieldName: string): integer;
    function FindField(const AFieldName: string): TFPReportDataField; overload;
    function FindField(const AFieldName: string; const AFieldKind: TFPReportFieldKind): TFPReportDataField; overload;
    function FieldByName(const AFieldName: string): TFPReportDataField;
    property ReportData: TFPReportData read FReportData;
    property Fields[AIndex: integer]: TFPReportDataField read GetF write SetF; default;
  end;


  { TFPReportData }

  TFPReportData = class(TFPReportComponent)
  private
    FDataFields: TFPReportDataFields;
    FOnClose: TNotifyEvent;
    FOnFirst: TNotifyEvent;
    FOnGetEOF: TFPReportGetEOFEvent;
    FOnNext: TNotifyEvent;
    FOnOpen: TNotifyEvent;
    FRecNo: integer;
    FIsOpened: boolean; // tracking the state
    function GetFieldCount: integer;
    function GetFieldName(Index: integer): string;
    function GetFieldType(AFieldName: string): TFPReportFieldKind;
    function GetFieldValue(AFieldName: string): variant;
    function GetFieldWidth(AFieldName: string): integer;
    procedure SetDataFields(const AValue: TFPReportDataFields);
  protected
    function CreateDataFields: TFPReportDataFields; virtual;
    procedure DoGetValue(const AFieldName: string; var AValue: variant); virtual;
    // Fill Datafields Collection. Should not change after Open.
    procedure DoInitDataFields; virtual;
    procedure DoOpen; virtual;
    procedure DoFirst; virtual;
    procedure DoNext; virtual;
    procedure DoClose; virtual;
    function  DoEOF: boolean; virtual;
    property DataFields: TFPReportDataFields read FDataFields write SetDataFields;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Navigation
    procedure InitFieldDefs;
    procedure Open;
    procedure First;
    procedure Next;
    procedure Close;
    function EOF: boolean;
    //  Public access methods
    procedure GetFieldList(List: TStrings);
    Function IndexOfField (const AFieldName: string): Integer;
    function HasField(const AFieldName: string): boolean;
    property FieldNames[Index: integer]: string read GetFieldName;
    property FieldValues[AFieldName: string]: variant read GetFieldValue; default;
    property FieldWidths[AFieldName: string]: integer read GetFieldWidth;
    property FieldTypes[AFieldName: string]: TFPReportFieldKind read GetFieldType;
    property FieldCount: integer read GetFieldCount;
    property RecNo: integer read FRecNo;
    property IsOpened: boolean read FIsOpened;
  published
    property OnOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnFirst: TNotifyEvent read FOnFirst write FOnFirst;
    property OnNext: TNotifyEvent read FOnNext write FOnNext;
    property OnGetEOF: TFPReportGetEOFEvent read FOnGetEOF write FOnGetEOF;
  end;


  TFPReportUserData = class(TFPReportData)
  private
    FOnGetValue: TFPReportGetValueEvent;
    FOnGetNames: TFPReportGetValueNamesEvent;
  protected
    procedure DoGetValue(const AFieldName: string; var AValue: variant); override;
    procedure DoInitDataFields; override;
  published
    property DataFields;
    property OnGetValue: TFPReportGetValueEvent read FOnGetValue write FOnGetValue;
    property OnGetNames: TFPReportGetValueNamesEvent read FOnGetNames write FOnGetNames;
  end;

  { TFPReportDataItem }

  TFPReportDataItem = Class(TCollectionItem)
  private
    FData: TFPReportData;
    procedure SetData(AValue: TFPReportData);
  Protected
    Function GetDisplayName: string; override;
  Public
    Procedure Assign(Source : TPersistent); override;
  Published
    property Data : TFPReportData Read FData Write SetData;
  end;


  { TFPReportDataCollection }

  TFPReportDataCollection = Class(TCollection)
  private
    function GetData(AIndex : Integer): TFPReportDataItem;
    procedure SetData(AIndex : Integer; AValue: TFPReportDataItem);
  Public
    Function IndexOfReportData(AData : TFPReportData) : Integer;
    Function IndexOfReportData(Const ADataName : String) : Integer;
    Function FindReportDataItem(AData : TFPReportData) : TFPReportDataItem;
    Function FindReportDataItem(Const ADataName : String) : TFPReportDataItem;
    Function FindReportData(Const ADataName : String) : TFPReportData;
    function AddReportData(AData: TFPReportData): TFPReportDataItem;
    Property Data[AIndex : Integer] : TFPReportDataItem Read GetData Write SetData; default;
  end;

  // The frame around each printable element.
  TFPReportFrame = class(TPersistent)
  private
    FColor: TFPReportColor;
    FFrameLines: TFPReportFrameLines;
    FFrameShape: TFPReportFrameShape;
    FPenStyle: TFPPenStyle;
    FReportElement: TFPReportElement;
    FWidth: integer;
    FBackgroundColor: TFPReportColor;
    procedure SetColor(const AValue: TFPReportColor);
    procedure SetFrameLines(const AValue: TFPReportFrameLines);
    procedure SetFrameShape(const AValue: TFPReportFrameShape);
    procedure SetPenStyle(const AValue: TFPPenStyle);
    procedure SetWidth(const AValue: integer);
    procedure SetBackgrounColor(AValue: TFPReportColor);
  protected
    procedure Changed; // Called whenever the visual properties change.
  public
    constructor Create(AElement: TFPReportElement);
    procedure Assign(ASource: TPersistent); override;
    procedure WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportFrame = nil); virtual;
    procedure ReadElement(AReader: TFPReportStreamer); virtual;
    function Equals(AFrame: TFPReportFrame): boolean; reintroduce;
    property ReportElement: TFPReportElement read FReportElement;
  published
    { Lines are only drawn if Shape = fsNone }
    property Lines: TFPReportFrameLines read FFrameLines write SetFrameLines;
    property Shape: TFPReportFrameShape read FFrameShape write SetFrameShape default fsNone;
    { The pen color used for stroking of shapes or for lines. }
    property Color: TFPReportColor read FColor write SetColor default clNone;
    { The fill color for shapes - where applicable. }
    property BackgroundColor: TFPReportColor read FBackgroundColor write SetBackgrounColor default clNone;
    property Pen: TFPPenStyle read FPenStyle write SetPenStyle default psSolid;
    { The width of the pen. }
    property Width: integer read FWidth write SetWidth;
  end;


  TFPReportTextAlignment = class(TPersistent)
  private
    FReportElement: TFPReportElement;
    FHorizontal: TFPReportHorzTextAlignment;
    FVertical: TFPReportVertTextAlignment;
    FTopMargin: TFPReportUnits;
    FBottomMargin: TFPReportUnits;
    FLeftMargin: TFPReportUnits;
    FRightMargin: TFPReportUnits;
    procedure   SetHorizontal(AValue: TFPReportHorzTextAlignment);
    procedure   SetVertical(AValue: TFPReportVertTextAlignment);
    procedure   SetTopMargin(AValue: TFPReportUnits);
    procedure   SetBottomMargin(AValue: TFPReportUnits);
    procedure   SetLeftMargin(AValue: TFPReportUnits);
    procedure   SetRightMargin(AValue: TFPReportUnits);
  protected
    procedure   Changed; // Called whenever the visual properties change.
  public
    constructor Create(AElement: TFPReportElement);
    procedure   Assign(ASource: TPersistent); override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportTextAlignment = nil); virtual;
    procedure   ReadElement(AReader: TFPReportStreamer); virtual;
  published
    property    Horizontal: TFPReportHorzTextAlignment read FHorizontal write SetHorizontal;
    property    Vertical: TFPReportVertTextAlignment read FVertical write SetVertical;
    property    TopMargin: TFPReportUnits read FTopMargin write SetTopMargin default 0;
    property    BottomMargin: TFPReportUnits read FBottomMargin write SetBottomMargin default 0;
    property    LeftMargin: TFPReportUnits read FLeftMargin write SetLeftMargin default 1.0;
    property    RightMargin: TFPReportUnits read FRightMargin write SetRightMargin default 1.0;
  end;


  // Position/Size related properties - this class doesn't notify FReportElement about property changes

  { TFPReportCustomLayout }

  TFPReportCustomLayout = class(TPersistent)
  private
    FPos: TFPReportRect;
    function    GetHeight: TFPreportUnits;
    function    GetWidth: TFPreportUnits;
    procedure   SetLeft(const AValue: TFPreportUnits);
    procedure   SetTop(const AValue: TFPreportUnits);
    procedure   SetWidth(const AValue: TFPreportUnits);
    procedure   SetHeight(const AValue: TFPreportUnits);
    function    GetLeft: TFPreportUnits;
    function    GetTop: TFPreportUnits;
  protected
    FReportElement: TFPReportElement;
    procedure   Changed; virtual; abstract;// Called whenever the visual properties change.
    property    Height: TFPreportUnits read GetHeight write SetHeight;
    property    Left: TFPreportUnits read GetLeft write SetLeft;
    property    Top: TFPreportUnits read GetTop write SetTop;
    property    Width: TFPreportUnits read GetWidth write SetWidth;
  public
    constructor Create(AElement: TFPReportElement);
    procedure   Assign(Source: TPersistent); override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportCustomLayout = nil); virtual;
    procedure   ReadElement(AReader: TFPReportStreamer); virtual;
    function    Equals(ALayout: TFPReportCustomLayout): boolean; reintroduce;
    procedure   GetBoundsRect(Out ARect: TFPReportRect);
    { a convenience function to set all four values in one go }
    procedure   SetPosition(aleft, atop, awidth, aheight: TFPReportUnits);
    procedure   SetPosition(Const ARect: TFPReportRect);
    property    ReportElement: TFPReportElement read FReportElement;
  end;


  // Position/Size related properties. Also notifies FReportElement about property changes
  TFPReportLayout = class(TFPReportCustomLayout)
  protected
    procedure Changed; override;
  published
    property  Height;
    property  Left;
    property  Top;
    property  Width;
  end;


  { Anything that must be drawn as part of the report descends from this. }
  TFPReportElement = class(TFPReportComponent)
  private
    FFrame: TFPReportFrame;
    FLayout: TFPReportLayout;
    FParent: TFPReportElement;
    FUpdateCount: integer;
    FVisible: boolean;
    FRTLayout: TFPReportLayout;
    FOnBeforePrint: TFPReportBeforePrintEvent;
    FStretchMode: TFPReportStretchMode;
    FVisibleExpr: String;
    function GetReport: TFPCustomReport;
    procedure SetFrame(const AValue: TFPReportFrame);
    procedure SetLayout(const AValue: TFPReportLayout);
    procedure SetVisible(const AValue: boolean);
    procedure SetVisibleExpr(AValue: String);
  protected
    function GetDateTimeFormat: String; virtual;
    function ExpandMacro(const s: String; const AIsExpr: boolean): TFPReportString; virtual;
    function GetReportBand: TFPReportCustomBand; virtual;
    function GetReportPage: TFPReportCustomPage; virtual;
    Procedure SaveDataToNames; virtual;
    Procedure RestoreDataFromNames; virtual;
    function CreateFrame: TFPReportFrame; virtual;
    function CreateLayout: TFPReportLayout; virtual;
    procedure CreateRTLayout; virtual;
    procedure SetParent(const AValue: TFPReportElement); virtual;
    procedure Changed; // Called whenever the visual properties change.
    procedure DoChanged; virtual; // Called when changed and changecount reaches zero.
    procedure PrepareObject; virtual;
    { descendants can add any extra properties to output here }
    procedure DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    { triggers OnBeforePrint event }
    procedure BeforePrint; virtual;
    function EvaluateExpression(const AExpr: String; out Res: TFPExpressionResult): Boolean;
    function EvaluateExpressionAsText(const AExpr: String): String;
    { this is run against the runtime (RT) version of this element, and before BeforePrint is called. }
    procedure RecalcLayout; virtual; abstract;
    property  StretchMode: TFPReportStretchMode read FStretchMode write FStretchMode default smDontStretch;
    property  OnBeforePrint: TFPReportBeforePrintEvent read FOnBeforePrint write FOnBeforePrint;
    property Page: TFPReportCustomPage read GetReportPage;
    property Band: TFPReportCustomBand read GetReportBand;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    Function CreatePropertyHash : String; virtual;
    function Equals(AElement: TFPReportElement): boolean; virtual; reintroduce;
    procedure WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure ReadElement(AReader: TFPReportStreamer); override;
    procedure Assign(Source: TPersistent); override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function EvaluateVisibility : boolean;
    property Parent: TFPReportElement read FParent write SetParent;
    Property Report : TFPCustomReport read GetReport;
    { Runtime Layout - populated when layouting of report is calculated. }
    property  RTLayout: TFPReportLayout read FRTLayout write FRTLayout; // TOOD: Maybe we should rename this to PrintLayout?
  published
    property Layout: TFPReportLayout read FLayout write SetLayout;
    property Frame: TFPReportFrame read FFrame write SetFrame;
    property Visible: boolean read FVisible write SetVisible;
    property VisibleExpr: String read FVisibleExpr write SetVisibleExpr;
  end;


  TFPReportElementWithChildren = class(TFPReportElement)
  private
    FChildren: TFPList;
    function GetChild(AIndex: integer): TFPReportElement;
    function GetChildCount: integer;
  protected
    Procedure SaveDataToNames; override;
    Procedure RestoreDataFromNames; override;
    procedure RemoveChild(const AChild: TFPReportElement); virtual;
    procedure AddChild(const AChild: TFPReportElement); virtual;
    procedure PrepareObjects; virtual;
    { This should run against the runtime version of the children }
    procedure RecalcLayout; override;
  public
    destructor  Destroy; override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    function    Equals(AElement: TFPReportElement): boolean; override;
    property    Child[AIndex: integer]: TFPReportElement read GetChild;
    property    ChildCount: integer read GetChildCount;
  end;


  TFPReportMargins = class(TPersistent)
  private
    FTop: TFPReportUnits;
    FBottom: TFPReportUnits;
    FLeft: TFPReportUnits;
    FRight: TFPReportUnits;
    FPage: TFPReportCustomPage;
    procedure   SetBottom(const AValue: TFPReportUnits);
    procedure   SetLeft(const AValue: TFPReportUnits);
    procedure   SetRight(const AValue: TFPReportUnits);
    procedure   SetTop(const AValue: TFPReportUnits);
  protected
    procedure   Changed; virtual;
  public
    constructor Create(APage: TFPReportCustomPage);
    procedure   Assign(Source: TPersistent); override;
    function    Equals(AMargins: TFPReportMargins): boolean; reintroduce;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportMargins = nil); virtual;
    procedure   ReadElement(AReader: TFPReportStreamer); virtual;
    property    Page: TFPReportCustomPage read FPage;
  published
    property    Top: TFPReportUnits read FTop write SetTop;
    property    Bottom: TFPReportUnits read FBottom write SetBottom;
    property    Left: TFPReportUnits read FLeft write SetLeft;
    property    Right: TFPReportUnits read FRight write SetRight;
  end;


  TFPReportPageSize = class(TPersistent)
  private
    FHeight: TFPReportUnits;
    FPage: TFPReportCustomPage;
    FPaperName: string;
    FWidth: TFPReportUnits;
    procedure SetHeight(const AValue: TFPReportUnits);
    procedure SetPaperName(const AValue: string);
    procedure SetWidth(const AValue: TFPReportUnits);
  protected
    procedure CheckPaperSize;
    procedure Changed; virtual;
  public
    constructor Create(APage: TFPReportCustomPage);
    procedure Assign(Source: TPersistent); override;
    property Page: TFPReportCustomPage read FPage;
  published
    property PaperName: string read FPaperName write SetPaperName;
    property Width: TFPReportUnits read FWidth write SetWidth;
    property Height: TFPReportUnits read FHeight write SetHeight;
  end;


  { Layout is relative to the page.
    That means that top/left equals top/left margin
     Width/Height is equals to page height/width minus margins
     Page orientation is taken into consideration. }
  TFPReportCustomPage = class(TFPReportElementWithChildren)
  private
    FData: TFPReportData;
    FDataName : String;
    FFont: TFPReportFont;
    FMargins: TFPReportMargins;
    FOrientation: TFPReportPaperOrientation;
    FPageSize: TFPReportPageSize;
    FReport: TFPCustomReport;
    FBands: TFPList;
    FColumnLayout: TFPReportColumnLayout;
    FColumnCount: Byte;
    FColumnGap: TFPReportUnits;
    function GetBand(AIndex: integer): TFPReportCustomBand;
    function GetBandCount: integer;
    function BandWidthFromColumnCount: TFPReportUnits;
    procedure ApplyBandWidth(ABand: TFPReportCustomBand);
    procedure SetFont(AValue: TFPReportFont);
    procedure SetMargins(const AValue: TFPReportMargins);
    procedure SetOrientation(const AValue: TFPReportPaperOrientation);
    procedure SetPageSize(const AValue: TFPReportPageSize);
    procedure SetReport(const AValue: TFPCustomReport);
    procedure SetReportData(const AValue: TFPReportData);
    procedure SetColumnLayout(AValue: TFPReportColumnLayout);
    procedure SetColumnCount(AValue: Byte);
    procedure SetColumnGap(AValue: TFPReportUnits);
  protected
    function GetReportPage: TFPReportCustomPage; override;
    function GetReportBand: TFPReportCustomBand; override;
    Procedure SaveDataToNames; override;
    Procedure RestoreDataFromNames; override;
    procedure RemoveChild(const AChild: TFPReportElement); override;
    procedure AddChild(const AChild: TFPReportElement); override;
    procedure MarginsChanged; virtual;
    procedure PageSizeChanged; virtual;
    procedure RecalcLayout; override;
    procedure CalcPrintPosition; virtual;
    procedure PrepareObjects; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    Function    PageIndex : Integer;
    procedure   Assign(Source: TPersistent); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    function    FindBand(ABand: TFPReportBandClass): TFPReportCustomBand;
    property    PageSize: TFPReportPageSize read FPageSize write SetPageSize;
    property    Margins: TFPReportMargins read FMargins write SetMargins;
    property    Report: TFPCustomReport read FReport write SetReport;
    property    Bands[AIndex: integer]: TFPReportCustomBand read GetBand;
    property    BandCount: integer read GetBandCount;
    property    Orientation: TFPReportPaperOrientation read FOrientation write SetOrientation;
    property    Data: TFPReportData read FData write SetReportData;
    property    ColumnCount: Byte read FColumnCount write SetColumnCount default 1;
    property    ColumnGap: TFPReportUnits read FColumnGap write SetColumnGap default 0;
    property    ColumnLayout: TFPReportColumnLayout read FColumnLayout write SetColumnLayout default clVertical;
    property    Font: TFPReportFont read FFont write SetFont;
  end;
  TFPReportCustomPageClass = Class of TFPReportCustomPage;


  TFPReportPage = class(TFPReportCustomPage)
  published
    property ColumnCount;
    property ColumnGap;
    property ColumnLayout;
    property Data;
    property Font;
    property Margins;
    property PageSize;
    property Orientation;
  end;


  TFPReportCustomBand = class(TFPReportElementWithChildren)
  private
    FChildBand: TFPReportChildBand;
    FUseParentFont: boolean;
    FVisibleOnPage: TFPReportVisibleOnPage;
    FFont: TFPReportFont;
    function    GetFont: TFPReportFont;
    function    IsStringValueZero(const AValue: string): boolean;
    procedure   SetChildBand(AValue: TFPReportChildBand);
    procedure   ApplyStretchMode;
    procedure   SetFont(AValue: TFPReportFont);
    procedure   SetUseParentFont(AValue: boolean);
    procedure   SetVisibleOnPage(AValue: TFPReportVisibleOnPage);
  protected
    function    GetReportPage: TFPReportCustomPage; override;
    function    GetReportBandName: string; virtual;
    function    GetData: TFPReportData; virtual;
    procedure   SetDataFromName(AName : String); virtual;
    procedure   SetParent(const AValue: TFPReportElement); override;
    procedure   CreateRTLayout; override;
    procedure   PrepareObjects; override;
    { this is normally run against the runtime version of the Band instance. }
    procedure   RecalcLayout; override;
    procedure   BeforePrint; override;
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    property    ChildBand: TFPReportChildBand read FChildBand write SetChildBand;
    property    Font: TFPReportFont read GetFont write SetFont;
    property    UseParentFont: boolean read FUseParentFont write SetUseParentFont;
    property    VisibleOnPage: TFPReportVisibleOnPage read FVisibleOnPage write SetVisibleOnPage;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Assign(Source: TPersistent); override;
    Class Function ReportBandType : TFPReportBandType; virtual;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
  end;
  TFPReportCustomBandClass = Class of TFPReportCustomBand;


  { TFPReportCustomBandWithData }

  TFPReportCustomBandWithData = class(TFPReportCustomBand)
  private
    FData: TFPReportData;
    FDataName : String;
    procedure ResolveDataName;
    procedure   SetData(const AValue: TFPReportData);
  protected
    Procedure SaveDataToNames; override;
    Procedure RestoreDataFromNames; override;
    function    GetData: TFPReportData; override;
    Procedure SetDataFromName(AName: String); override;
    procedure   Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property    Data: TFPReportData read GetData write SetData;
  end;
  TFPReportCustomBandWithDataClass = Class of TFPReportCustomBandWithData;


  TFPReportCustomDataBand = class(TFPReportCustomBandWithData)
  private
    FHeaderBand: TFPReportCustomDataHeaderBand;
    FFooterBand: TFPReportCustomDataFooterBand;
    FMasterBand: TFPReportCustomDataBand;
    FDisplayPosition: Integer;
  protected
    property    DisplayPosition: Integer read FDisplayPosition write FDisplayPosition default 0;
    property    FooterBand: TFPReportCustomDataFooterBand read FFooterBand write FFooterBand;
    property    HeaderBand: TFPReportCustomDataHeaderBand read FHeaderBand write FHeaderBand;
    property    MasterBand: TFPReportCustomDataBand read FMasterBand write FMasterBand;
  public
    constructor Create(AOwner: TComponent); override;
  end;
  TFPReportCustomDataBandClass = Class of TFPReportCustomDataBand;


  { Master data band. The report loop happens on this band. }
  TFPReportDataBand = class(TFPReportCustomDataBand)
  protected
    function    GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  published
    property    ChildBand;
    property    DisplayPosition;
    property    Font;
    property    FooterBand;
    property    HeaderBand;
    property    MasterBand;
    property    StretchMode;
    property    UseParentFont;
    property    VisibleOnPage;
    property    OnBeforePrint;
  end;


  TFPReportCustomChildBand = class(TFPReportCustomBandWithData)
  protected
    function GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportChildBand = class(TFPReportCustomChildBand)
  published
    property    ChildBand;
    property    Font;
    property    StretchMode;
    property    UseParentFont;
    property    VisibleOnPage;
    property    OnBeforePrint;
  end;


  TFPReportCustomPageFooterBand = class(TFPReportCustomBand)
  protected
    function    GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportPageFooterBand = class(TFPReportCustomPageFooterBand)
  published
    property    Font;
    property    UseParentFont;
    property    VisibleOnPage;
    property    OnBeforePrint;
  end;


  TFPReportCustomPageHeaderBand = class(TFPReportCustomBand)
  protected
    function GetReportBandName: string; override;
  public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportPageHeaderBand = class(TFPReportCustomPageHeaderBand)
  published
    property    Font;
    property    UseParentFont;
    property    VisibleOnPage;
    property    OnBeforePrint;
  end;


  TFPReportCustomColumnHeaderBand = class(TFPReportCustomBandWithData)
  protected
    function GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportColumnHeaderBand = class(TFPReportCustomColumnHeaderBand)
  published
    property    Data;
    property    Font;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  TFPReportCustomColumnFooterBand = class(TFPReportCustomBandWithData)
  private
    FFooterPosition: TFPReportFooterPosition;
    procedure   SetFooterPosition(AValue: TFPReportFooterPosition);
  protected
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    function    GetReportBandName: string; override;
    property    FooterPosition: TFPReportFooterPosition read FFooterPosition write SetFooterPosition default fpColumnBottom;
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Assign(Source: TPersistent); override;
    Class Function ReportBandType : TFPReportBandType; override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
  end;


  TFPReportColumnFooterBand = class(TFPReportCustomColumnFooterBand)
  published
    property    Font;
    property    FooterPosition;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  { TFPReportCustomGroupHeaderBand }

  TFPReportCustomGroupHeaderBand = class(TFPReportCustomBandWithData)
  private
    FConditionValue: string;
    FGroupHeader: TFPReportCustomGroupHeaderBand;
    FChildGroupHeader: TFPReportCustomGroupHeaderBand;
    FGroupFooter: TFPReportCustomGroupFooterBand;
    FCondition: string;
    procedure   SetGroupHeader(AValue: TFPReportCustomGroupHeaderBand);
  protected
    function    GetReportBandName: string; override;
    Procedure   CalcGroupConditionValue;
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   Notification(AComponent: TComponent; Operation: TOperation); override;
    { This property defines the hierarchy of nested groups. For the top most group, this property will be nil. }
    property    GroupHeader: TFPReportCustomGroupHeaderBand read FGroupHeader write SetGroupHeader;
    { Indicates related GroupFooter band. This will automatically be set by the GroupFooter. }
    property    GroupFooter: TFPReportCustomGroupFooterBand read FGroupFooter;
    { can be a field name or an expression }
    property    GroupCondition: string read FCondition write FCondition;
    { Run-time calculated value }
    property    GroupConditionValue : string read FConditionValue write FConditionValue;
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Assign(Source: TPersistent); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    function    Evaluate: string;
    Class Function ReportBandType : TFPReportBandType; override;
    property    ChildGroupHeader: TFPReportCustomGroupHeaderBand read FChildGroupHeader;
  end;


  TFPReportGroupHeaderBand = class(TFPReportCustomGroupHeaderBand)
  public
    property    GroupFooter;
  published
    property    Font;
    property    GroupCondition;
    property    GroupHeader;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  { Report title band - prints once at the beginning of the report }
  TFPReportCustomTitleBand = class(TFPReportCustomBand)
  protected
    function GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportTitleBand = class(TFPReportCustomTitleBand)
  published
    property    Font;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  { Report summary band - prints once at the end of the report }
  TFPReportCustomSummaryBand = class(TFPReportCustomBand)
  private
    FStartNewPage: boolean;
  protected
    function    GetReportBandName: string; override;
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    property    StartNewPage: boolean read FStartNewPage write FStartNewPage default False;
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Assign(Source: TPersistent); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportSummaryBand = class(TFPReportCustomSummaryBand)
  published
    property    Font;
    property    StartNewPage;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  TFPReportCustomGroupFooterBand = class(TFPReportCustomBandWithData)
  private
    FGroupHeader: TFPReportCustomGroupHeaderBand;
    procedure SetGroupHeader(const AValue: TFPReportCustomGroupHeaderBand);
  protected
    function  GetReportBandName: string; override;
    procedure DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    property  GroupHeader: TFPReportCustomGroupHeaderBand read FGroupHeader write SetGroupHeader;
  public
    procedure ReadElement(AReader: TFPReportStreamer); override;
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportGroupFooterBand = class(TFPReportCustomGroupFooterBand)
  published
    property    Font;
    property    GroupHeader;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  TFPReportCustomDataHeaderBand = class(TFPReportCustomBandWithData)
  protected
    function GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportDataHeaderBand = class(TFPReportCustomDataHeaderBand)
  published
    property    Font;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  TFPReportCustomDataFooterBand = class(TFPReportCustomBandWithData)
  protected
    function GetReportBandName: string; override;
  Public
    Class Function ReportBandType : TFPReportBandType; override;
  end;


  TFPReportDataFooterBand = class(TFPReportCustomDataFooterBand)
  published
    property    Font;
    property    UseParentFont;
    property    OnBeforePrint;
  end;


  TFPReportImageItem = class(TCollectionItem)
  private
    FImage: TFPCustomImage;
    FOwnsImage: Boolean;
    FStreamed: TBytes;
    FWidth: Integer;
    FHeight: Integer;
    function    GetHeight: Integer;
    function    GetStreamed: TBytes;
    function    GetWidth: Integer;
    procedure   SetImage(AValue: TFPCustomImage);
    procedure   SetStreamed(AValue: TBytes);
    procedure   LoadPNGFromStream(AStream: TStream);
  public
    constructor Create(ACollection: TCollection); override;
    destructor  Destroy; override;
    procedure   CreateStreamedData;
    function    WriteImageStream(AStream: TStream): UInt64; virtual;
    function    Equals(AImage: TFPCustomImage): boolean; reintroduce;
    procedure   WriteElement(AWriter: TFPReportStreamer);
    procedure   ReadElement(AReader: TFPReportStreamer);
    property    Image: TFPCustomImage read FImage write SetImage;
    property    StreamedData: TBytes read GetStreamed write SetStreamed;
    property    OwnsImage: Boolean read FOwnsImage write FOwnsImage default True;
    property    Width: Integer read GetWidth;
    property    Height: Integer read GetHeight;
  end;


  { TFPReportImages }

  TFPReportImages = class(TOwnedCollection)
  private
    function    GetImg(AIndex: Integer): TFPReportImageItem;
    function GetReportOwner: TFPCustomReport;
  protected
  public
    constructor Create(AOwner: TFPCustomReport; AItemClass: TCollectionItemClass);
    function    AddImageItem: TFPReportImageItem;
    function    AddFromStream(const AStream: TStream; Handler: TFPCustomImageReaderClass; KeepImage: Boolean = False): Integer;
    function    AddFromFile(const AFileName: string; KeepImage: Boolean = False): Integer;
    function    AddFromData(const AImageData: Pointer; const AImageDataSize: LongWord): integer;
    function    GetIndexFromID(const AID: integer): integer;
    Function    GetImageFromID(const AID: integer): TFPCustomImage;
    Function    GetImageItemFromID(const AID: integer): TFPReportImageItem;
    property    Images[AIndex: Integer]: TFPReportImageItem read GetImg; default;
    property    Owner: TFPCustomReport read GetReportOwner;
  end;

  { TFPReportVariable }

  TFPReportVariable = Class(TCollectionItem)
  private
    FName: String;
    FValue: TFPExpressionResult;
    FSavedValue: TFPExpressionResult;
    procedure CheckType(aType: TResultType);
    function GetAsBoolean: Boolean;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: TexprFloat;
    function GetAsInteger: Int64;
    function GetAsString: String;
    function GetDataType: TResultType;
    function GetER: TFPExpressionResult;
    function GetValue: String;
    procedure SetAsBoolean(AValue: Boolean);
    procedure SetAsDateTime(AValue: TDateTime);
    procedure SetAsFloat(AValue: TExprFloat);
    procedure SetAsInteger(AValue: Int64);
    procedure SetAsString(AValue: String);
    procedure SetDataType(AValue: TResultType);
    procedure SetER(AValue: TFPExpressionResult);
    procedure SetName(AValue: String);
    procedure SetValue(AValue: String);
    Procedure SaveValue; virtual;
    Procedure RestoreValue; virtual;
  Protected
    Procedure GetRTValue(Var Result : TFPExpressionResult; ConstRef AName : ShortString); virtual;
  Public
    Procedure Assign(Source : TPersistent); override;
    Property AsExpressionResult : TFPExpressionResult Read GetER Write SetER;
    Property AsString : String Read GetAsString Write SetAsString;
    Property AsInteger : Int64 Read GetAsInteger Write SetAsInteger;
    Property AsBoolean : Boolean Read GetAsBoolean Write SetAsBoolean;
    Property AsFloat : TExprFloat Read GetAsFloat Write SetAsFloat;
    Property AsDateTime : TDateTime Read GetAsDateTime Write SetAsDateTime;
  Published
    Property Name : String Read FName Write SetName;
    Property DataType : TResultType Read GetDataType Write SetDataType;
    property Value : String Read GetValue Write SetValue;
  end;

  { TFPReportVariables }

  TFPReportVariables = Class(TOwnedCollection)
  private
    function GetV(aIndex : Integer): TFPReportVariable;
    procedure SetV(aIndex : Integer; AValue: TFPReportVariable);
  Protected
  public
    Function IndexOfVariable(aName : String)  : Integer;
    Function FindVariable(aName : String)  : TFPReportVariable;
    Function AddVariable(aName : String)  : TFPReportVariable;
    Property Variable[aIndex : Integer] : TFPReportVariable Read GetV Write SetV; default;
  end;

  { TFPCustomReport }

  TFPCustomReport = class(TFPReportComponent)
  private
    FPages: TFPList;
    FOnBeginReport: TFPReportBeginReportEvent;
    FOnEndReport: TFPReportEndReportEvent;
    FReportData: TFPReportDataCollection;
    FRTObjects: TFPList;  // see property
    FRTCurPageIdx: integer; // RTObjects index reference to current page being layout
    FRTCurBand: TFPReportCustomBand;  // current band being layout
    FExpr: TFPexpressionParser;
    FTitle: string;
    FAuthor: string;
    FPageNumber: integer;
    FPageCount: integer; // requires two-pass reporting
    FPageNumberPerDesignerPage: integer; // page number per report designer pages
    FDateCreated: TDateTime;
    FReferenceList: TStringList;
    FImages: TFPReportImages;
    FOnBeforeRenderReport: TNotifyEvent;
    FOnAfterRenderReport: TNotifyEvent;
    FTwoPass: boolean;
    FIsFirstPass: boolean;
    FPageData: TFPReportData;
    FPerDesignerPageCount: array of UInt32;
    FVariables : TFPReportVariables;
    function GetPage(AIndex: integer): TFPReportCustomPage;
    function GetPageCount: integer; { this is designer page count }
    function GetRenderedPageCount: integer;
    procedure BuiltinExprRecNo(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    procedure BuiltinGetPageNumber(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    procedure BuiltinGetPageNoPerDesignerPage(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    procedure BuiltinGetPageCount(var Result: TFPExpressionResult; const Args: TExprParameterArray);
    { checks if children are visble, removes children if needed, and recalc Band.Layout bounds }
    procedure RecalcBandLayout(ABand: TFPReportCustomBand);
    procedure EmptyRTObjects;
    procedure ClearDataBandLastTextValues(ABand: TFPReportCustomBandWithData);
    procedure ProcessAggregates(const APageIdx: integer; const AData: TFPReportData);

    { these three methods are used to resolve references while reading a report from file. }
    procedure ClearReferenceList;
    procedure AddReference(const AParentName, AChildName: string);
    procedure FixupReferences;

    procedure DoBeforeRenderReport;
    procedure DoAfterRenderReport;
    procedure DoProcessTwoPass;
    procedure DoGetExpressionVariableValue(var Result: TFPExpressionResult; constref AName: ShortString);
    procedure SetReportData(AValue: TFPReportDataCollection);
    procedure SetVariables(AValue: TFPReportVariables);
  protected
    FBands: TBandList;
    function CreateVariables: TFPReportVariables; virtual;
    function CreateImages: TFPReportImages; virtual;
    function CreateReportData: TFPReportDataCollection; virtual;

    procedure RestoreDefaultVariables; virtual;
    procedure DoPrepareReport; virtual;
    procedure DoBeginReport; virtual;
    procedure DoEndReport; virtual;
    procedure InitializeDefaultExpressions; virtual;
    procedure InitializeExpressionVariables(const AData: TFPReportData); virtual;
    procedure CacheMemoExpressions(const APageIdx: integer; const AData: TFPReportData); virtual;
    procedure StartRender; override;
    procedure EndRender; override;
    // stores object instances for and during layouting
    property  RTObjects: TFPList read FRTObjects;
    property Images: TFPReportImages read FImages;
    property Pages[AIndex: integer]: TFPReportCustomPage read GetPage;
    property PageCount: integer read GetPageCount;
    property IsFirstPass: boolean read FIsFirstPass write FIsFirstPass default False;
    property OnBeginReport: TFPReportBeginReportEvent read FOnBeginReport write FOnBeginReport;
    property OnEndReport: TFPReportEndReportEvent read FOnEndReport write FOnEndReport;
    property OnBeforeRenderReport: TNotifyEvent read FOnBeforeRenderReport write FOnBeforeRenderReport;
    property OnAfterRenderReport: TNotifyEvent read FOnAfterRenderReport write FOnAfterRenderReport;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    Procedure   SaveDataToNames;
    Procedure   RestoreDataFromNames;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    procedure   AddPage(APage: TFPReportCustomPage);
    procedure   RemovePage(APage: TFPReportCustomPage);
    function    FindRecursive(const AName: string): TFPReportElement;
    procedure   RunReport;
    procedure   RenderReport(const AExporter: TFPReportExporter);
    Property Variables : TFPReportVariables Read FVariables Write SetVariables;
    {$IFDEF gdebug}
    function DebugPreparedPageAsJSON(const APageNo: Byte): string;
    {$ENDIF}
    property Author: string read FAuthor write FAuthor;
    property DateCreated: TDateTime read FDateCreated write FDateCreated;
    property Title: string read FTitle write FTitle;
    property TwoPass: boolean read FTwoPass write FTwoPass default False;
    Property ReportData : TFPReportDataCollection Read FReportData Write SetReportData;
  end;


  TFPReport = class(TFPCustomReport)
  public
    property Pages;
    property PageCount;
    property Images;
  published
    property Author;
    property Title;
    property TwoPass;
    property ReportData;
    property OnAfterRenderReport;
    property OnBeforeRenderReport;
    property OnBeginReport;
    property OnEndReport;
  end;


  EReportError = class(Exception);
  EReportExportError = class(EReportError);
  EReportFontNotFound = class(EReportError);


  TFPReportPaperManager = class(TComponent)
  private
    FPaperSizes: TStringList;
    function GetPaperCount: integer;
    function GetPaperHeight(AIndex: integer): TFPReportUnits;
    function GetPaperHeightByName(AName: string): TFPReportUnits;
    function GetPaperName(AIndex: integer): string;
    function GetPaperWidth(AIndex: integer): TFPReportUnits;
    function GetPaperWidthByName(AName: string): TFPReportUnits;
  protected
    function FindPaper(const AName: string): TFPReportPaperSize;
    function GetPaperByname(const AName: string): TFPReportPaperSize;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure RegisterPaper(const AName: string; const AWidth, AHeight: TFPReportUnits);
    procedure RegisterStandardSizes;
    { assign registered names to AList - useful to populate ComboBoxes etc }
    procedure GetRegisteredSizes(var AList: TStringList);
    function IndexOfPaper(const AName: string): integer;
    property PaperNames[AIndex: integer]: string read GetPaperName;
    property PaperHeight[AIndex: integer]: TFPReportUnits read GetPaperHeight;
    property PaperWidth[AIndex: integer]: TFPReportUnits read GetPaperWidth;
    property HeightByName[AName: string]: TFPReportUnits read GetPaperHeightByName;
    property WidthByName[AName: string]: TFPReportUnits read GetPaperWidthByName;
    property PaperCount: integer read GetPaperCount;
  end;


  TExprNodeInfoRec = record
    Position: UInt32;
    ExprNode: TFPExprNode;
  end;

  TFPReportCustomMemo = class(TFPReportElement)
  private
    FText: TFPReportString;
    FIsExpr: boolean;
    FTextAlignment: TFPReportTextAlignment;
    FTextLines: TStrings;
    FLineSpacing: TFPReportUnits;
    FCurTextBlock: TFPTextBlock;
    FTextBlockList: TFPTextBlockList;
    FParser: THTMLParser;
    { These six fields are used by PrepareTextBlocks() }
    FTextBlockState: TFPReportHTMLTagSet;
    FTextBlockXOffset: TFPReportUnits;
    FTextBlockYOffset: TFPReportUnits;
    FLastURL: string;
    FLastBGColor: TFPReportColor;
    FLastFGColor: TFPReportColor;
    FLinkColor: TFPReportColor;
    FOptions: TFPReportMemoOptions;
    FLastText: string; // used by moSuppressRepeated
    FOriginal: TFPReportCustomMemo;
    ExpressionNodes: array of TExprNodeInfoRec;
    FFont: TFPReportFont;
    FUseParentFont: Boolean;
    function    GetFont: TFPReportFont;
    procedure   SetText(AValue: TFPReportString);
    procedure   SetUseParentFont(AValue: Boolean);
    procedure   WrapText(const AText: String; var ALines: TStrings; const ALineWidth: TFPReportUnits; out AHeight: TFPReportUnits);
    procedure   ApplyStretchMode(const AHeight: TFPReportUnits);
    procedure   ApplyHorzTextAlignment;
    procedure   ApplyVertTextAlignment;
    function    GetTextLines: TStrings;
    procedure   SetLineSpacing(AValue: TFPReportUnits);
    procedure   HTMLOnFoundTag(NoCaseTag, ActualTag: string);
    procedure   HTMLOnFoundText(Text: string);
    function    PixelsToMM(APixels: single): single; inline;
    function    mmToPixels(mm: single): integer; inline;
    { Result is in millimeters. }
    function    TextHeight(const AText: string; out ADescender: TFPReportUnits): TFPReportUnits;
    { Result is in millimeters. }
    function    TextWidth(const AText: string): TFPReportUnits;
    procedure   SetLinkColor(AValue: TFPReportColor);
    procedure   SetTextAlignment(AValue: TFPReportTextAlignment);
    procedure   SetOptions(const AValue: TFPReportMemoOptions);
    procedure   ParseText;
    procedure   ClearExpressionNodes;
    procedure   AddSingleTextBlock(const AText: string);
    procedure   AddMultipleTextBlocks(const AText: string);
    function    IsExprAtArrayPos(const APos: integer): Boolean;
    procedure   SetFont(const AValue: TFPReportFont);
  protected
    function    CreateTextAlignment: TFPReportTextAlignment; virtual;
    function    GetExpr: TFPExpressionParser; virtual;
    procedure   PrepareObject; override;
    procedure   RecalcLayout; override;
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   ExpandExpressions;
    property    Text: TFPReportString read FText write SetText;
    property    Font: TFPReportFont read GetFont write SetFont;
    property    TextAlignment: TFPReportTextAlignment read FTextAlignment write SetTextAlignment;
    property    LineSpacing: TFPReportUnits read FLineSpacing write SetLineSpacing default 1;
    property    LinkColor: TFPReportColor read FLinkColor write SetLinkColor default clBlue;
    { The moUsesHTML enables supports for <b>, <i>, <font color=yxz bgcolor=xyz> and <a href="..."> tags.
      NOTE: The FONT tag's color attribute will override the FontColor property. }
    property    Options: TFPReportMemoOptions read FOptions write SetOptions default [];
    { Used by Runtime Memos - this is a reference back to the original design memo. }
    property    Original: TFPReportCustomMemo read FOriginal write FOriginal;
    property    UseParentFont: Boolean read FUseParentFont write SetUseParentFont default True;
  protected
    // *****************************
    //   This block is made Protected simply for Unit Testing purposes.
    //   Interfaces would have worked nicely for this.
    // *****************************

    // --------------->  Start <-----------------
    function    CreateTextBlock(const IsURL: boolean): TFPTextBlock;
    { HtmlColorToFPReportColor() supports RRGGBB, #RRGGBB and #RGB color formats. }
    function    HtmlColorToFPReportColor(AColorStr: string; ADefault: TFPReportColor = clBlack): TFPReportColor;
    procedure   PrepareTextBlocks;
    { Extract a sub-string within defined delimiters. If AIndex is > 0 then extract the
      AIndex'th sub-string. AIndex uses 1-based numbering. The AStartPos returns the position
      of the returned sub-string in ASource. }
    function    SubStr(const ASource, AStartDelim, AEndDelim: string; AIndex: integer; out AStartPos: integer): string;
    { Count the number of blocks of text in AValue separated by AToken }
    function    TokenCount(const AValue: string; const AToken: string = '['): integer;
    { Return the n-th token defined by APos. APas is 1-based. }
    function    Token(const AValue, AToken: string; const APos: integer): string;
    // --------------->  End  <-----------------

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Assign(Source: TPersistent); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    { Only returns the internal FTextLines if StretchMode <> smDontStretch, otherwise it returns nil. Don't free the TStrings result. }
    property    TextLines: TStrings read GetTextLines;
    { after layouting, this contains all the memo text and positions they should be displayed at. }
    property    TextBlockList: TFPTextBlockList read FTextBlockList;
  end;


  TFPReportMemo = class(TFPReportCustomMemo)
  published
    property  Font;
    property  LineSpacing;
    property  LinkColor;
    property  Options;
    property  StretchMode;
    property  Text;
    property  TextAlignment;
    property  UseParentFont;
    property  OnBeforePrint;
  end;


  { TFPReportCustomShape }

  TFPReportCustomShape = class(TFPReportElement)
  private
    FColor: TFPReportColor;
    FShapeType: TFPReportShapeType;
    FOrientation: TFPReportOrientation;
    FCornerRadius: TFPReportUnits;
    procedure   SetShapeType(AValue: TFPReportShapeType);
    procedure   SetOrientation(AValue: TFPReportOrientation);
    procedure   SetCornerRadius(AValue: TFPReportUnits);
  protected
    procedure   PrepareObject; override;
    Procedure   RecalcLayout; override;
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    property    ShapeType: TFPReportShapeType read FShapeType write SetShapeType default stEllipse;
    property    Orientation: TFPReportOrientation read FOrientation write SetOrientation default orNorth;
    property    CornerRadius: TFPReportUnits read FCornerRadius write SetCornerRadius;
    Property    Color : TFPReportColor Read FColor Write FColor default clBlack;
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Assign(Source: TPersistent); override;
    Function CreatePropertyHash: String; override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
  end;


  TFPReportShape = class(TFPReportCustomShape)
  published
    property    ShapeType;
    property    Orientation;
    property    CornerRadius;
    property    Color;
  end;


  { TFPReportCustomImage }

  TFPReportCustomImage = class(TFPReportElement)
  private
    FImage: TFPCustomImage;
    FStretched: boolean;
    FFieldName: TFPReportString;
    FImageID: integer;
    procedure   SetImage(AValue: TFPCustomImage);
    procedure   SetStretched(AValue: boolean);
    procedure   SetFieldName(AValue: TFPReportString);
    procedure   LoadDBData(AData: TFPReportData);
    procedure   SetImageID(AValue: integer);
    function    GetImage: TFPCustomImage;
  protected
    procedure   DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   PrepareObject; override;
    Procedure   RecalcLayout; override;
    property    Image: TFPCustomImage read GetImage write SetImage;
    property    ImageID: integer read FImageID write SetImageID;
    property    Stretched: boolean read FStretched write SetStretched;
    property    FieldName: TFPReportString read FFieldName write SetFieldName;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    Function    GetRTImageID : Integer;
    Function    GetRTImage : TFPCustomImage;
    procedure   Assign(Source: TPersistent); override;
    procedure   ReadElement(AReader: TFPReportStreamer); override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    procedure   LoadFromFile(const AFileName: string);
    procedure   LoadPNGFromStream(AStream: TStream);
    procedure   LoadImage(const AImageData: Pointer; const AImageDataSize: LongWord);
  end;


  TFPReportImage = class(TFPReportCustomImage)
  published
    property    Image;
    property    ImageID;
    property    Stretched;
    property    FieldName;
    property    OnBeforePrint;
  end;


  { TFPReportCustomCheckbox }

  TFPReportCustomCheckbox = class(TFPReportElement)
  private
    FExpression: TFPReportString;
    FFalseImageID: Integer;
    FTrueImageID: Integer;
    procedure   SetExpression(AValue: TFPReportString);
    function    LoadImage(const AImageData: Pointer; const AImageDataSize: LongWord): TFPCustomImage; overload;
    function    LoadImage(AStream: TStream): TFPCustomImage; overload;
  protected
    Class Var
      ImgTrue: TFPCustomImage;
      ImgFalse: TFPCustomImage;
  Protected
    FTestResult: Boolean;
    Procedure   RecalcLayout; override;
    procedure   PrepareObject; override;
    property    Expression: TFPReportString read FExpression write SetExpression;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    GetDefaultImage(Checked: Boolean): TFPCustomImage;
    Function    GetImage(Checked: Boolean) : TFPCustomImage;
    Function    GetRTResult : Boolean;
    Function    GetRTImage : TFPCustomImage;
    Function    CreatePropertyHash: String; override;
    procedure   Assign(Source: TPersistent); override;
    procedure   WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement = nil); override;
    Property    TrueImageID : Integer Read FTrueImageID Write FTrueImageID;
    Property    FalseImageID : Integer Read FFalseImageID Write FFalseImageID;
  end;


  TFPReportCheckbox = class(TFPReportCustomCheckbox)
  published
    property    Expression;
    Property    TrueImageID ;
    Property    FalseImageID ;
  end;

  { TFPReportElementEditor }

  TFPReportElementEditor = Class(TComponent)
  private
    FElement: TFPReportElement;
  Protected
    procedure SetElement(AValue: TFPReportElement); virtual;
  Public
    Class function DefaultClass : TFPReportElementClass; virtual;
    Class Procedure RegisterEditor;
    Class Procedure UnRegisterEditor;
    Function Execute: Boolean; virtual; abstract;
    Property Element : TFPReportElement Read FElement Write SetElement;
  end;
  TFPReportElementEditorClass = Class of TFPReportElementEditor;

  { A class to hold the TFPReportElement class mappings. The factory maintains
    a list of these and uses the ReportElementClass property to create the objects. }

  { TFPReportClassMapping }

  TFPReportImageRenderCallBack = Procedure(aElement : TFPReportElement; aImage: TFPCustomImage);
  TFPReportElementExporterCallBack = Procedure(aPos : TFPReportPoint; aElement : TFPReportElement; AExporter : TFPReportExporter; ADPI: Integer);

  TFPReportElementRenderer = Record
    aClass : TFPReportExporterClass;
    aCallback : TFPReportElementExporterCallBack;
  end;
  TFPReportElementRendererArray = Array of TFPReportElementRenderer;

  TFPReportClassMapping = class(TObject)
  private
    FEditorClass: TFPReportElementEditorClass;
    FImageRenderCallBack: TFPReportImageRenderCallBack;
    FMappingName: string;
    FReportElementClass: TFPReportElementClass;
    FRenderers : TFPReportElementRendererArray;
  public
    Function IndexOfExportRenderer(AClass : TFPReportExporterClass) : Integer;
    constructor Create(const AMappingName: string; AElementClass: TFPReportElementClass);
    Function AddRenderer(aExporterClass : TFPReportExporterClass; aCallback : TFPReportElementExporterCallBack) : TFPReportElementExporterCallBack;
    Function FindRenderer(aClass : TFPReportExporterClass) : TFPReportElementExporterCallBack;
    property MappingName: string read FMappingName;
    Property ImageRenderCallback : TFPReportImageRenderCallBack Read FImageRenderCallBack Write FImageRenderCallBack;
    property ReportElementClass: TFPReportElementClass read FReportElementClass;
    property EditorClass : TFPReportElementEditorClass Read FEditorClass Write FEditorClass;
  end;


  { Factory pattern - Create a descendant of the TFPReportElement at runtime. }

  { TFPReportElementFactory }

  TFPReportElementFactory = class(TObject)
  private
    FList: TFPObjectList;
    function GetM(Aindex : integer): TFPReportClassMapping;
  Protected
    function IndexOfElementClass(const AElementClass: TFPReportElementClass): Integer;
    Function IndexOfElementName(const AElementName: string) : Integer;
    Property Mappings[Aindex : integer] : TFPReportClassMapping read GetM;
  public
    constructor Create;
    destructor  Destroy; override;
    Function    FindRenderer(aClass : TFPReportExporterClass; AElement : TFPReportElementClass) : TFPReportElementExporterCallBack;
    Function    FindImageRenderer(AElement : TFPReportElementClass) : TFPReportImageRenderCallBack;
    Function    RegisterImageRenderer(AElement : TFPReportElementClass; ARenderer : TFPReportImageRenderCallBack) : TFPReportImageRenderCallBack;
    Function    RegisterElementRenderer(AElement : TFPReportElementClass; ARenderClass: TFPReportExporterClass; ARenderer : TFPReportElementExporterCallBack) : TFPReportElementExporterCallBack;
    procedure   RegisterEditorClass(const AElementName: string; AEditorClass: TFPReportElementEditorClass);
    procedure   RegisterEditorClass(AReportElementClass: TFPReportElementClass; AEditorClass: TFPReportElementEditorClass);
    procedure   UnRegisterEditorClass(const AElementName: string; AEditorClass: TFPReportElementEditorClass);
    procedure   UnRegisterEditorClass(AReportElementClass: TFPReportElementClass; AEditorClass: TFPReportElementEditorClass);
    procedure   RegisterClass(const AElementName: string; AReportElementClass: TFPReportElementClass);
    function    CreateInstance(const AElementName: string; AOwner: TComponent): TFPReportElement; overload;
    Function    FindEditorClassForInstance(AInstance : TFPReportElement) : TFPReportElementEditorClass;
    Function    FindEditorClassForInstance(AClass : TFPReportElementClass) : TFPReportElementEditorClass ;
    procedure   AssignReportElementTypes(AStrings: TStrings);
  end;

  { TFPReportBandFactory }

  TFPReportBandFactory = class(TObject)
  Private
    FBandTypes : Array[TFPReportBandType] of TFPReportCustomBandClass;
    FPageClass: TFPReportCustomPageClass;
    function getBandClass(aIndex : TFPReportBandType): TFPReportCustomBandClass;
  Public
    Constructor Create;
    Function RegisterBandClass(aBandType : TFPReportBandType; AClass : TFPReportCustomBandClass) : TFPReportCustomBandClass;
    Function RegisterPageClass(aClass : TFPReportCustomPageClass) : TFPReportCustomPageClass;
    Property BandClasses [aIndex : TFPReportBandType] : TFPReportCustomBandClass read getBandClass;
    Property PageClass : TFPReportCustomPageClass Read FPageClass;
  end;
  { keeps track of interested bands. eg: a list of page header like bands etc. }
  TBandList = class(TObject)
  private
    FList: TFPList;
    function    GetCount: Integer;
    function    GetItems(AIndex: Integer): TFPReportCustomBand;
    procedure   SetItems(AIndex: Integer; AValue: TFPReportCustomBand);
  public
    constructor Create;
    destructor  Destroy; override;
    function    Add(AItem: TFPReportCustomBand): Integer;
    procedure   Clear;
    procedure   Delete(AIndex: Integer);
    function    Find(ABand: TFPReportBandClass): TFPReportCustomBand; overload;
    function    Find(ABand: TFPReportBandClass; out AResult: TFPReportCustomBand): Integer; overload;
    procedure   Sort(Compare: TListSortCompare);
    property    Count: Integer read GetCount;
    property    Items[AIndex: Integer]: TFPReportCustomBand read GetItems write SetItems; default;
  end;


  { TFPReportExportManager }

  TFPReportExportManager = Class(TComponent)
  Private
    Flist : TFPObjectList;
    FOnConfigCallBack: TFPReportExporterConfigHandler;
    function GetExporter(AIndex : Integer): TFPReportExporterClass;
    function GetExporterCount: Integer;
  Protected
    Procedure RegisterExport(AClass : TFPReportExporterClass); virtual;
    Procedure UnRegisterExport(AClass : TFPReportExporterClass); virtual;
    Function ConfigExporter(AExporter : TFPReportExporter) : Boolean; virtual;
  Public
    Constructor Create(AOwner : TComponent);override;
    Destructor Destroy; override;
    Procedure Clear;
    Function IndexOfExporter(Const AName : String) : Integer;
    Function IndexOfExporter(Const AClass : TFPReportExporterClass) : Integer;
    Function FindExporter(Const AName : String) : TFPReportExporterClass;
    Function ExporterConfigHandler(Const AClass : TFPReportExporterClass) : TFPReportExporterConfigHandler;
    Procedure RegisterConfigHandler(Const AName : String; ACallBack : TFPReportExporterConfigHandler);
    Property Exporter[AIndex : Integer] : TFPReportExporterClass Read GetExporter;
    Property ExporterCount : Integer Read GetExporterCount;
    // GLobal one, called when no specific callback is configured
    Property OnConfigCallBack : TFPReportExporterConfigHandler Read FOnConfigCallBack Write FOnConfigCallBack;
  end;


procedure ReportError(Msg: string); inline;
procedure ReportError(Fmt: string; Args: array of const);
function  HorzTextAlignmentToString(AEnum: TFPReportHorzTextAlignment): string; inline;
function  StringToHorzTextAlignment(AName: string): TFPReportHorzTextAlignment; inline;
function  VertTextAlignmentToString(AEnum: TFPReportVertTextAlignment): string; inline;
function  StringToVertTextAlignment(AName: string): TFPReportVertTextAlignment; inline;
{ Converts R, G, B color channel values into the TFPReportColor (RRGGBB format) type. }
function RGBToReportColor(R, G, B: Byte): TFPReportColor;
{ Base64 encode stream data }
function FPReportStreamToMIMEEncodeString(const AStream: TStream): string;
{ Base64 decode string to a stream }
procedure FPReportMIMEEncodeStringToStream(const AString: string; const AStream: TStream);

function PaperManager: TFPReportPaperManager;

// The ElementFactory is a singleton
function gElementFactory: TFPReportElementFactory;
function gBandFactory : TFPReportBandFactory;

Function ReportExportManager : TFPReportExportManager;

implementation

uses
  strutils,
  typinfo,
  FPReadPNG,
  FPWritePNG,
  base64,
  fpTTF;

resourcestring
  { this should probably be more configurable or flexible per platform }
  cDefaultFont = 'Helvetica';
  cPageCountMarker = '~PC~';

  SErrInvalidLineWidth   = 'Invalid line width: %d';
  SErrInvalidParent      = '%s cannot be used as a parent for %s';
  SErrInvalidChildIndex  = 'Invalid child index : %d';
  SErrInvalidPageIndex   = 'Invalid page index : %d';
  SErrNotAReportPage     = '%s (%s) is not a TFPReportCustomPage.';
  SErrDuplicatePaperName = 'Paper name %s already exists';
  SErrUnknownPaper       = 'Unknown paper name : "%s"';
  SErrUnknownField       = '%s: No such field : "%s"';
  SErrInitFieldsNotAllowedAfterOpen =
    'Calling InitDataFields to change the Datafields collection after Open() is not allowed.';
  SErrUnknownMacro       = '**unknown**';
  SErrNoFileFound        = 'No file found: "%s"';
  SErrChildBandCircularReference = 'ChildBand circular reference detected and not allowed.';
  SErrFontNotFound       = 'Font not found: "%s"';

  SErrRegisterEmptyExporter     = 'Attempt to register empty exporter';
  SErrRegisterDuplicateExporter = 'Attempt to register duplicate exporter: "%s"';
  SErrRegisterUnknownElement = 'Unable to find registered report element <%s>.';
  SErrUnknownExporter = 'Unknown exporter: "%s"';
  SErrMultipleDataBands = 'A report page may not have more than one master databand.';
  SErrCantAssignReportFont = 'Can''t Assign() report font - Source is not TFPReportFont.';
  SErrNoStreamInstanceWasSupplied = 'No valid TStream instance was supplied.';
  SErrIncorrectDescendant = 'AElement is not a TFPReportElementWithChildren descendant.';

  SErrUnknownResultType = 'Unknown result type: "%s"';
  SErrInvalidFloatingPointValue = '%s is not a valid floating point value';
  SErrResultTypeMisMatch = 'Result type is %s, expected %s';
  SErrDuplicateVariable = 'Duplicate variable name : %s';
  SErrInvalidVariableName = 'Invalid variable name: "%s"';
  SErrUnknownBandType = 'Unknown band type : %d';
  SErrInInvalidISO8601DateTime = '%s is an invalid ISO datetime value';
  SErrCouldNotGetDefaultBandType = 'Could not get default band class for type '
    +'%s';
  SErrBandClassMustDescendFrom = 'Band class for band type %s must descend '
    +'from %s';
  SErrPageClassMustDescendFrom = 'Page class for must descend from %s';
  SErrCannotRegisterWithoutDefaultClass = 'Cannot register/unregister editor without default element class.';
  SErrUnknownElementName = 'Unknown element name : %s';
  SErrUnknownElementClass = 'Unknown element class : %s';

{ includes Report Checkbox element images }
{$I fpreportcheckbox.inc}

var
  uPaperManager: TFPReportPaperManager;
  uElementFactory: TFPReportElementFactory;
  uBandFactory : TFPReportBandFactory;

{ Auxiliary routines }

procedure ReportError(Msg: string); inline;
begin
  raise EReportError.Create(Msg);
end;

procedure ReportError(Fmt: string; Args: array of const);
begin
  raise EReportError.CreateFmt(Fmt, Args);
end;

function PaperManager: TFPReportPaperManager;
begin
  if uPaperManager = nil then
    uPaperManager := TFPReportPaperManager.Create(nil);
  Result := uPaperManager;
end;

function gElementFactory: TFPReportElementFactory;
begin
  if uElementFactory = nil then
    uElementFactory := TFPReportElementFactory.Create;
  Result := uElementFactory;
end;

function gBandFactory: TFPReportBandFactory;
begin
  if uBandFactory = nil then
    uBandFactory := TFPReportBandFactory.Create;
  Result := uBandFactory;
end;

Var
  EM : TFPReportExportManager;

function ReportExportManager: TFPReportExportManager;
begin
  If EM=Nil then
    EM:=TFPReportExportManager.Create(Nil);
  Result:=EM;
end;

// TODO: See if the following generic function can replace the multiple enum-to-string functions
//generic function EnumValueAsName<T>(v: T): String;
//begin
//  Result := GetEnumName(TypeInfo(T), LongInt(v));
//end;

function HorzTextAlignmentToString(AEnum: TFPReportHorzTextAlignment): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportHorzTextAlignment), Ord(AEnum));
end;

function StringToHorzTextAlignment(AName: string): TFPReportHorzTextAlignment; inline;
begin
  Result := TFPReportHorzTextAlignment(GetEnumValue(TypeInfo(TFPReportHorzTextAlignment), AName));
end;

function VertTextAlignmentToString(AEnum: TFPReportVertTextAlignment): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportVertTextAlignment), Ord(AEnum));
end;

function StringToVertTextAlignment(AName: string): TFPReportVertTextAlignment; inline;
begin
  Result := TFPReportVertTextAlignment(GetEnumValue(TypeInfo(TFPReportVertTextAlignment), AName));
end;

function RGBToReportColor(R, G, B: Byte): TFPReportColor;
begin
  Result := (R shl 16) or (G shl 8) or B;
end;

function StretchModeToString(AEnum: TFPReportStretchMode): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportStretchMode), Ord(AEnum));
end;

function StringToStretchMode(AName: string): TFPReportStretchMode; inline;
begin
  Result := TFPReportStretchMode(GetEnumValue(TypeInfo(TFPReportStretchMode), AName));
end;

function ShapeTypeToString(AEnum: TFPReportShapeType): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportShapeType), Ord(AEnum));
end;

function StringToShapeType(AName: string): TFPReportShapeType; inline;
begin
  Result := TFPReportShapeType(GetEnumValue(TypeInfo(TFPReportShapeType), AName));
end;

function FrameShapeToString(AEnum: TFPReportFrameShape): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportFrameShape), Ord(AEnum));
end;

function StringToFrameShape(AName: string): TFPReportFrameShape; inline;
begin
  Result := TFPReportFrameShape(GetEnumValue(TypeInfo(TFPReportFrameShape), AName));
end;

function FramePenToString(AEnum: TFPPenStyle): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPPenStyle), Ord(AEnum));
end;

function StringToFramePen(AName: string): TFPPenStyle; inline;
begin
  Result := TFPPenStyle(GetEnumValue(TypeInfo(TFPPenStyle), AName));
end;

function OrientationToString(AEnum: TFPReportOrientation): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportOrientation), Ord(AEnum));
end;

function StringToOrientation(AName: string): TFPReportOrientation; inline;
begin
  Result := TFPReportOrientation(GetEnumValue(TypeInfo(TFPReportOrientation), AName));
end;

function PaperOrientationToString(AEnum: TFPReportPaperOrientation): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportPaperOrientation), Ord(AEnum));
end;

function StringToPaperOrientation(AName: string): TFPReportPaperOrientation; inline;
begin
  Result := TFPReportPaperOrientation(GetEnumValue(TypeInfo(TFPReportPaperOrientation), AName));
end;

function ColumnFooterPositionToString(AEnum: TFPReportFooterPosition): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportFooterPosition), Ord(AEnum));
end;

function StringToColumnFooterPosition(AName: string): TFPReportFooterPosition; inline;
begin
  Result := TFPReportFooterPosition(GetEnumValue(TypeInfo(TFPReportFooterPosition), AName));
end;

function VisibleOnPageToString(AEnum: TFPReportVisibleOnPage): string; inline;
begin
  result := GetEnumName(TypeInfo(TFPReportVisibleOnPage), Ord(AEnum));
end;

function StringToVisibleOnPage(AName: string): TFPReportVisibleOnPage; inline;
begin
  Result := TFPReportVisibleOnPage(GetEnumValue(TypeInfo(TFPReportVisibleOnPage), AName));
end;

function StringToMemoOptions(const AValue: string): TFPReportMemoOptions;
var
  lList: TStrings;
  lIndex: integer;
begin
  Result := [];
  lList := nil;
  lList := TStringList.Create;
  try
    lList.Delimiter := ',';
    lList.DelimitedText := AValue;
    for lIndex := 0 to lList.Count - 1 do
      Include(Result, TFPReportMemoOption(GetEnumValue(TypeInfo(TFPReportMemoOption), lList[lIndex])));
  finally
    lList.Free;
  end;
end;

function MemoOptionsToString(const AValue: TFPReportMemoOptions): String;
var
  lIndex: integer;
begin
  Result := '';
  for lIndex := Ord(Low(TFPReportMemoOption)) to Ord(High(TFPReportMemoOption)) do
  begin
    if TFPReportMemoOption(lIndex) in AValue then
    begin
      if Result = '' then
        Result := GetEnumName(TypeInfo(TFPReportMemoOption), lIndex)
      else
        Result := Result + ',' + GetEnumName(TypeInfo(TFPReportMemoOption), lIndex);
    end;
  end;
end;

function FPReportStreamToMIMEEncodeString(const AStream: TStream): string;
var
  OutStream: TStringStream;
  b64encoder: TBase64EncodingStream;
  LPos: integer;
begin
  if not Assigned(AStream) then
    ReportError(SErrNoStreamInstanceWasSupplied);
  LPos:= AStream.Position;
  try
    OutStream := TStringStream.Create('');
    try
      AStream.Position := 0;

      b64encoder := TBase64EncodingStream.Create(OutStream);
      b64encoder.CopyFrom(AStream, AStream.Size);
    finally
      b64encoder.Free;
      result := OutStream.DataString;
      OutStream.Free;
    end;
  finally
    AStream.Position:= LPos;
  end;
end;

procedure FPReportMIMEEncodeStringToStream(const AString: string; const AStream: TStream);
var
  InputStream: TStringStream;
  b64decoder: TBase64DecodingStream;
begin
  if not Assigned(AStream) then
    ReportError(SErrNoStreamInstanceWasSupplied);
  InputStream:= TStringStream.Create(AString);
  try
    AStream.Size := 0;
    b64decoder := TBase64DecodingStream.Create(InputStream, bdmMIME);
    try
      AStream.CopyFrom(b64decoder, b64decoder.Size);
      AStream.Position:=0;
    finally
      b64decoder.Free;
    end;
  finally
    InputStream.Free;
  end;
end;

procedure FillMem(Dest: pointer; Size: longint; Data: Byte );
begin
  FillChar(Dest^, Size, Data);
end;

function SortDataBands(Item1, Item2: Pointer): Integer;
begin
  if TFPReportCustomDataBand(Item1).DisplayPosition < TFPReportCustomDataBand(Item2).DisplayPosition then
    Result := -1
  else if TFPReportCustomDataBand(Item1).DisplayPosition > TFPReportCustomDataBand(Item2).DisplayPosition then
    Result := 1
  else
    Result := 0;
end;

Type

  { TFPReportReg }

  TFPReportExportReg = Class(TObject)
  private
    FClass: TFPReportExporterClass;
    FonConfig: TFPReportExporterConfigHandler;
  Public
    Constructor Create(AClass : TFPReportExporterClass);
    Property TheClass : TFPReportExporterClass Read FClass;
    Property OnConfig : TFPReportExporterConfigHandler Read FonConfig Write FOnConfig;
  end;

{ TFPReportBandFactory }

Function GetDefaultBandType(AType : TFPReportBandType) : TFPReportCustomBandClass;

begin
  Case AType of
    btUnknown       : Result:=Nil;
    btPageHeader    : Result:=TFPReportPageHeaderBand;
    btReportTitle   : Result:=TFPReportTitleBand;
    btColumnHeader  : Result:=TFPReportColumnHeaderBand;
    btDataHeader    : Result:=TFPReportDataHeaderBand;
    btGroupHeader   : Result:=TFPReportGroupHeaderBand;
    btDataband      : Result:=TFPReportDataBand;
    btGroupFooter   : Result:=TFPReportGroupFooterBand;
    btDataFooter    : Result:=TFPReportDataFooterBand;
    btColumnFooter  : Result:=TFPReportColumnFooterBand;
    btReportSummary : Result:=TFPReportSummaryBand;
    btPageFooter    : Result:=TFPReportPageFooterBand;
    btChild         : Result:=TFPReportChildBand;
  else
    raise EReportError.CreateFmt(SErrUnknownBandType, [Ord(AType)]);
  end;
end;

const
  { Summary of ISO 8601  http://www.cl.cam.ac.uk/~mgk25/iso-time.html }
  ISO8601DateFormat = 'yyyymmdd"T"hhnnss';    // for storage

function DateTimeToISO8601(const ADateTime: TDateTime): string;
begin
  Result := FormatDateTime(ISO8601DateFormat,ADateTime);
  if Pos('18991230', Result) = 1 then
    begin
    Delete(Result,1,8);
    Result:='00000000'+Result;
    end;
end;

function ISO8601ToDateTime(const AValue: string): TDateTime;
var
  lY, lM, lD, lH, lMi, lS: Integer;
begin
  if Trim(AValue) = '' then
  begin
    Result := 0;
    Exit; //==>
  end;

    //          1         2
    // 12345678901234567890123
    // yyyymmddThhnnss
  if not (TryStrToInt(Copy(AValue, 1, 4),lY)
      and TryStrToInt(Copy(AValue, 5, 2),lM)
      and TryStrToInt(Copy(AValue, 7, 2),lD)
      and TryStrToInt(Copy(AValue, 10, 2),lH)
      and TryStrToInt(Copy(AValue, 12, 2),lMi)
      and TryStrToInt(Copy(AValue, 14, 2),lS)) then
      raise EConvertError.CreateFmt(SErrInInvalidISO8601DateTime, [AValue]);

  { Cannot EncodeDate if any part equals 0. EncodeTime is okay. }
  if (lY = 0) or (lM = 0) or (lD = 0) then
    Result := EncodeTime(lH, lMi, lS, 0)
  else
    Result := EncodeDate(lY, lM, lD) + EncodeTime(lH, lMi, lS, 0);
end;

{ TFPReportElementEditor }

procedure TFPReportElementEditor.SetElement(AValue: TFPReportElement);
begin
  if FElement=AValue then Exit;
  FElement:=AValue;
end;

class function TFPReportElementEditor.DefaultClass: TFPReportElementClass;
begin
  Result:=Nil;
end;

class procedure TFPReportElementEditor.RegisterEditor;

Var
  C : TFPReportElementClass;

begin
  C:=DefaultClass;
  If C=Nil then
    Raise EReportError.Create(SErrCannotRegisterWithoutDefaultClass);
  gElementFactory.RegisterEditorClass(C,Self);
end;

class procedure TFPReportElementEditor.UnRegisterEditor;
Var
  C : TFPReportElementClass;

begin
  C:=DefaultClass;
  If C=Nil then
    Raise EReportError.Create(SErrCannotRegisterWithoutDefaultClass);
  gElementFactory.UnRegisterEditorClass(C,Self);
end;

{ TFPReportDataCollection }

function TFPReportDataCollection.GetData(AIndex : Integer): TFPReportDataItem;
begin
  Result:=Items[Aindex] as TFPReportDataItem;
end;

procedure TFPReportDataCollection.SetData(AIndex : Integer;
  AValue: TFPReportDataItem);
begin
  Items[Aindex]:=AValue;
end;

function TFPReportDataCollection.IndexOfReportData(AData: TFPReportData
  ): Integer;
begin
  Result:=Count-1;
  While (Result>=0) and (GetData(Result).Data<>AData) do
    Dec(Result);
end;

function TFPReportDataCollection.IndexOfReportData(const ADataName: String
  ): Integer;
begin
  Result:=Count-1;
  While (Result>=0) and ((GetData(Result).Data=Nil) or (CompareText(GetData(Result).Data.Name,ADataName)<>0)) do
    Dec(Result);
end;

function TFPReportDataCollection.FindReportDataItem(const ADataName: String): TFPReportDataItem;

Var
  I : Integer;

begin
  I:=IndexOfReportData(ADataName);
  if I=-1 then
    Result:=Nil
  else
    Result:=GetData(I);
end;

function TFPReportDataCollection.FindReportDataItem(AData: TFPReportData): TFPReportDataItem;
Var
  I : Integer;
begin
  I:=IndexOfReportData(AData);
  if I=-1 then
    Result:=Nil
  else
    Result:=GetData(I);
end;

function TFPReportDataCollection.FindReportData(const ADataName: String): TFPReportData;
Var
  I : TFPReportDataItem;
begin
  I:=FindReportDataItem(aDataName);
  If Assigned(I) then
    Result:=I.Data
  else
    Result:=Nil;
end;

function TFPReportDataCollection.AddReportData(AData: TFPReportData ): TFPReportDataItem;
begin
  Result:=Add as TFPReportDataItem;
  Result.Data:=AData;
end;

{ TFPReportDataItem }

procedure TFPReportDataItem.SetData(AValue: TFPReportData);
begin
  if FData=AValue then Exit;
  FData:=AValue;
end;

function TFPReportDataItem.GetDisplayName: string;
begin
  if Assigned(Data) then
    Result:=Data.Name
  else
    Result:=inherited GetDisplayName;
end;

procedure TFPReportDataItem.Assign(Source: TPersistent);
begin
  if Source is TFPReportDataItem then
    FData:=TFPReportDataItem(Source).Data
  else
    inherited Assign(Source);
end;

{ TFPReportVariables }

function TFPReportVariables.GetV(aIndex : Integer): TFPReportVariable;
begin
  Result:=Items[aIndex] as TFPReportVariable;
end;

procedure TFPReportVariables.SetV(aIndex : Integer; AValue: TFPReportVariable);
begin
  Items[aIndex]:=AValue;
end;

function TFPReportVariables.IndexOfVariable(aName: String): Integer;
begin
  Result:=Count-1;
  While (Result>=0) and (CompareText(getV(Result).Name,aName)<>0) do
    Dec(Result);
end;

function TFPReportVariables.FindVariable(aName: String): TFPReportVariable;

Var
  I : Integer;

begin
  I:=IndexOfVariable(aName);
  if I=-1 then
    Result:=nil
  else
    Result:=getV(I);
end;

function TFPReportVariables.AddVariable(aName: String): TFPReportVariable;
begin
  if (IndexOfVariable(aName)<>-1) then
    raise EReportError.CreateFmt(SErrDuplicateVariable, [aName]);
  Result:=add as TFPReportVariable;
  Result.Name:=aName;
  Result.DataType:=rtString;
  Result.AsString:='';
end;

{ TFPReportVariable }

procedure TFPReportVariable.SetValue(AValue: String);

Var
  C : Integer;
  f : TExprFloat;

begin
  if GetValue=AValue then
    Exit;
  if (AValue<>'') then
    Case DataType of
      rtBoolean  : AsBoolean:=StrToBool(AValue);
      rtInteger  : AsInteger:=StrToInt(AValue);
      rtFloat    : begin
                   Val(AValue,F,C);
                   if C<>0 then
                     raise EConvertError.CreateFmt(
                       SErrInvalidFloatingPointValue, [AValue]);
                   ASFloat:=F;
                   end;
      rtDateTime : asDateTime:=ISO8601ToDateTime(AValue);
      rtString   : AsString:=AValue;
    else
      raise EConvertError.CreateFmt(SErrUnknownResultType, [GetEnumName(TypeInfo
        (TResultType), Ord(DataType))])
    end;
end;

procedure TFPReportVariable.GetRTValue(Var Result: TFPExpressionResult; ConstRef AName: ShortString);
begin
  if (Result.ResultType=Self.DataType) then
    Result:=FValue;
end;

procedure TFPReportVariable.SaveValue;
begin
  FSavedValue:=FValue;
end;

procedure TFPReportVariable.RestoreValue;
begin
  FValue:=FSavedValue;
end;



function TFPReportVariable.GetValue: String;
begin
  Case DataType of
    rtBoolean  : Result:=BoolToStr(AsBoolean,True);
    rtInteger  : Result:=IntToStr(AsInteger);
    rtFloat    : Str(AsFloat,Result);
    rtDateTime : Result:=DateTimeToISO8601(AsDateTime);
    rtString   : Result:=AsString
  else
    Raise EConvertError.CreateFmt(SErrUnknownResultType,[GetEnumName(TypeInfo(TResultType),Ord(DataType))])
  end;
end;

function TFPReportVariable.GetER: TFPExpressionResult;

begin
  Result:=FValue;
end;

procedure TFPReportVariable.CheckType(aType: TResultType);
begin
  if DataType<>aType then
    raise EConvertError.CreateFmt(SErrResultTypeMisMatch, [
       GetEnumName(TypeInfo(TResultType),Ord(DataType)),
       GetEnumName(TypeInfo(TResultType),Ord(aType))
    ]);
end;

function TFPReportVariable.GetAsInteger: Int64;
begin
  CheckType(rtInteger);
  Result:=FValue.ResInteger;
end;

function TFPReportVariable.GetAsBoolean: Boolean;
begin
  CheckType(rtBoolean);
  Result:=FValue.Resboolean;
end;

function TFPReportVariable.GetAsDateTime: TDateTime;
begin
  CheckType(rtDateTime);
  Result:=FValue.ResDateTime;
end;

function TFPReportVariable.GetAsFloat: TexprFloat;
begin
  CheckType(rtFloat);
  Result:=FValue.ResFloat;
end;

function TFPReportVariable.GetAsString: String;
begin
  CheckType(rtString);
  Result:=FValue.ResString;
end;

function TFPReportVariable.GetDataType: TResultType;
begin
  Result:=FValue.ResultType;
end;

procedure TFPReportVariable.SetAsInteger(AValue: Int64);
begin
  DataType:=rtinteger;
  FValue.ResInteger:=AValue;
end;

procedure TFPReportVariable.SetAsString(AValue: String);
begin
  DataType:=rtString;
  FValue.resString:=AValue;
end;

procedure TFPReportVariable.SetAsBoolean(AValue: Boolean);
begin
  FValue.ResultType:=rtBoolean;
  FValue.resBoolean:=AValue;
end;

procedure TFPReportVariable.SetAsDateTime(AValue: TDateTime);
begin
  FValue.ResultType:=rtDateTime;
  FValue.ResDateTime:=AValue;
end;

procedure TFPReportVariable.SetAsFloat(AValue: TExprFloat);
begin
  FValue.ResultType:=rtFloat;
  FValue.ResFloat:=AValue;
end;

procedure TFPReportVariable.SetDataType(AValue: TResultType);
begin
  if FValue.ResultType=AValue then
    exit;
  if FValue.ResultType=rtString then
    FValue.resString:='';
  FValue.ResultType:=AValue;
end;

procedure TFPReportVariable.SetER(AValue: TFPExpressionResult);

begin
  FValue:=AValue;
end;

procedure TFPReportVariable.SetName(AValue: String);
begin
  if FName=AValue then Exit;
  {$IF FPC_FULLVERSION < 30002}
  if Not IsValidIdent(aValue) then
  {$ELSE}
  if Not IsValidIdent(aValue,True,true) then
  {$ENDIF}
    raise EReportError.CreateFmt(SErrInvalidVariableName, [aValue]);
  if (Collection is TFPReportVariables) then
    If ((Collection as TFPReportVariables).FindVariable(AValue)<>Nil) then
      raise EReportError.CreateFmt(SErrDuplicateVariable, [aValue]);

  FName:=AValue;
end;

procedure TFPReportVariable.Assign(Source: TPersistent);

Var
  V : TFPReportVariable;

begin
  if Source is TFPReportVariable then
    begin
    V:=Source as TFPReportVariable;
    FName:=V.Name;
    FValue:=V.FValue;
    end
  else
    inherited Assign(Source);
end;

function TFPReportBandFactory.getBandClass(aIndex : TFPReportBandType
  ): TFPReportCustomBandClass;
begin
  Result:=FBandTypes[aIndex];
end;

constructor TFPReportBandFactory.Create;

Var
  T : TFPReportBandType;

begin
  FPageClass:=TFPReportPage;
  for T in TFPReportBandType do
    begin
    FBandTypes[T]:=GetDefaultBandType(T);
    end;
end;

function TFPReportBandFactory.RegisterBandClass(aBandType: TFPReportBandType;
  AClass: TFPReportCustomBandClass): TFPReportCustomBandClass;

Var
  D : TFPReportCustomBandClass;
  N : String;


begin
  D:=GetDefaultBandType(aBandtype);
  N:=GetEnumName(TypeInfo(TFPReportBandType),Ord(ABandType));
  if (D=Nil) then
    raise EReportError.CreateFmt(SErrCouldNotGetDefaultBandType, [N]);
  If Not AClass.InheritsFrom(D) then
    raise EReportError.CreateFmt(SErrBandClassMustDescendFrom, [N, D.ClassName]
      );
  Result:=FBandTypes[aBandType];
  FBandTypes[aBandType]:=AClass;
end;

function TFPReportBandFactory.RegisterPageClass(aClass: TFPReportCustomPageClass
  ): TFPReportCustomPageClass;
begin
  Result := nil;  // TODO: Why is this a function if no Result is ever returned?
  If Not AClass.InheritsFrom(TFPReportCustomPage) then
    raise EReportError.CreateFmt(SErrPageClassMustDescendFrom, [
      TFPReportCustomPageClass.ClassName]);
  FPageClass:=AClass;
end;

{ TFPReportExportReg }

constructor TFPReportExportReg.Create(AClass: TFPReportExporterClass);
begin
  FCLass:=AClass;
end;


{ TFPReportExportManager }


function TFPReportExportManager.GetExporter(AIndex : Integer
  ): TFPReportExporterClass;
begin
  Result:=TFPReportExportReg(FList.Items[AIndex]).TheClass;
end;

function TFPReportExportManager.GetExporterCount: Integer;

begin
  Result:=FList.Count;
end;

procedure TFPReportExportManager.RegisterExport(AClass: TFPReportExporterClass);
begin
  if AClass=Nil then
    Raise EReportError.Create(SErrRegisterEmptyExporter);
  If IndexOfExporter(AClass.Name)<>-1 then
    Raise EReportError.CreateFmt(SErrRegisterDuplicateExporter,[AClass.Name]);
  FList.Add(TFPReportExportReg.Create(AClass));
end;

procedure TFPReportExportManager.UnRegisterExport(AClass: TFPReportExporterClass);

Var
  I : Integer;

begin
  I:=IndexOfExporter(AClass);
  if I<>-1 then
    FList.Delete(i);
end;

function TFPReportExportManager.ConfigExporter(AExporter: TFPReportExporter): Boolean;
Var
  H : TFPReportExporterConfigHandler;
begin
  H:=ExporterConfigHandler(TFPReportExporterClass(AExporter.ClassType));
  if (H=Nil) then
    H:=AExporter.DefaultConfig;
  if H=Nil then
    H:=OnConfigCallBack;
  Result:=False;
  If Assigned(H) then
    H(Self,AExporter,Result);
  Result:=Not Result;
end;

constructor TFPReportExportManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList:=TFPObjectList.Create(True);
end;

destructor TFPReportExportManager.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TFPReportExportManager.Clear;
begin
  FList.Clear;
end;

function TFPReportExportManager.IndexOfExporter(const AName: String): Integer;
begin
  Result:=ExporterCount-1;
  While (Result>=0) and (CompareText(AName,Exporter[Result].Name)<>0) do
    Dec(Result);
end;

function TFPReportExportManager.IndexOfExporter(
  const AClass: TFPReportExporterClass): Integer;
begin
  Result:=ExporterCount-1;
  While (Result>=0) and (AClass<>Exporter[Result]) do
    Dec(Result);
end;

function TFPReportExportManager.FindExporter(const AName: String): TFPReportExporterClass;

Var
  I : Integer;

begin
  I:=IndexOfExporter(AName);
  If I<>-1 then
    Result:=Exporter[i]
  else
    Result:=Nil;
end;

function TFPReportExportManager.ExporterConfigHandler(
  const AClass: TFPReportExporterClass): TFPReportExporterConfigHandler;

Var
  I : Integer;

begin
  I:=IndexOfExporter(AClass);
  if I<>-1 then
    Result:=TFPReportExportReg(FList[i]).OnConfig
  else
    Result:=nil;
end;

procedure TFPReportExportManager.RegisterConfigHandler(const AName: String;
  ACallBack: TFPReportExporterConfigHandler);

Var
  I : integer;

begin
  I:=IndexOfExporter(AName);
  If (I=-1) Then
    Raise EReportError.CreateFmt(SErrUnknownExporter,[AName]);
  TFPReportExportReg(FList[i]).OnConfig:=ACallBack;
end;

{ TBandList }

function TBandList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TBandList.GetItems(AIndex: Integer): TFPReportCustomBand;
begin
  Result := TFPReportCustomBand(FList.Items[AIndex]);
end;

procedure TBandList.SetItems(AIndex: Integer; AValue: TFPReportCustomBand);
begin
  FList.Items[AIndex] := AValue;
end;

constructor TBandList.Create;
begin
  FList := TFPList.Create;
end;

destructor TBandList.Destroy;
begin
  FList.Clear;
  FreeAndNil(FList);
  inherited Destroy;
end;

function TBandList.Add(AItem: TFPReportCustomBand): Integer;
begin
  Result := -1;
  if Assigned(AItem) then
    if FList.IndexOf(AItem) = -1 then { we don't add duplications }
      Result := FList.Add(AItem);
end;

procedure TBandList.Clear;
begin
  FList.Clear;
end;

procedure TBandList.Delete(AIndex: Integer);
begin
  FList.Delete(AIndex);
end;

function TBandList.Find(ABand: TFPReportBandClass): TFPReportCustomBand;
begin
  Find(ABand, Result);
end;

function TBandList.Find(ABand: TFPReportBandClass; out AResult: TFPReportCustomBand): Integer;
var
  i: integer;
begin
  AResult := nil;
  Result := -1;
  for i := 0 to Count-1 do
  begin
    if Items[i] is ABand then
    begin
      Result := i;
      AResult := Items[i];
      Break;
    end;
  end;
end;

procedure TBandList.Sort(Compare: TListSortCompare);
begin
  FList.Sort(Compare);
end;

{ TFPReportCustomMemo }

procedure TFPReportCustomMemo.SetText(AValue: TFPReportString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  Changed;
end;

function TFPReportCustomMemo.GetFont: TFPReportFont;
begin
  if UseParentFont then
  begin
    if Assigned(Owner) then
      Result := TFPReportCustomBand(Owner).Font
    else
    begin
      if not Assigned(FFont) then
        FFont := TFPReportFont.Create;
      Result := FFont;
    end;
  end
  else
    Result := FFont;
end;

procedure TFPReportCustomMemo.SetUseParentFont(AValue: Boolean);
begin
  if FUseParentFont = AValue then
    Exit;
  FUseParentFont := AValue;
  if FUseParentFont then
    FreeAndNil(FFont)
  else
  begin
    FFont := TFPReportFont.Create;
    if Assigned(Owner) then
      FFont.Assign(TFPReportCustomBand(Owner).Font);
  end;
  Changed;
end;

procedure TFPReportCustomMemo.WrapText(const AText: String; var ALines: TStrings; const ALineWidth: TFPReportUnits; out
  AHeight: TFPReportUnits);
var
  maxw: single; // value in pixels
  n: integer;
  s: string;
  c: char;
  lWidth: single;
  lFC: TFPFontCacheItem;
  lDescenderHeight: single;
  lHeight: single;

  // -----------------
  { All = True) indicates that if the text is split over multiple lines the last
    line must also be processed before continuing. If All = False, then double
    CR can be ignored. }
  procedure AddLine(all: boolean);
  var
    w: single;
    m: integer;
    s2, s3: string;
  begin
    s2  := s;
    w   := lFC.TextWidth(s2, Font.Size);
    if (Length(s2) > 1) and (w > maxw) then
    begin
      while w > maxw do
      begin
        m := Length(s);
        repeat
          Dec(m);
          s2  := Copy(s,1,m);
          w   := lFC.TextWidth(s2, Font.Size);
        until w <= maxw;

        s3 := s2; // we might need the value of s2 later again

        // are we in the middle of a word. If so find the beginning of word.
        while (m > 0) and (Copy(s2, m, m+1) <> ' ') do
        begin
          Dec(m);
          s2  := Copy(s,1,m);
        end;

        if s2 = '' then
        begin
          s2 := s3;
          m := Length(s2);
          { We reached the beginning of the line without finding a word that fits the maxw.
            So we are forced to use a longer than maxw word. We were in the middle of
            a word, so now find the end of the current word. }
          while (m < Length(s)) and (Copy(s2, m, m+1) <> ' ') do
          begin
            Inc(m);
            s2  := Copy(s,1,m);
          end;
        end;
        ALines.Add(s2);
        s   := Copy(s, m+1, Length(s));
        s2  := s;
        w   := lFC.TextWidth(s2, Font.Size);
      end; { while }
      if all then
      begin
        if s2 <> '' then
          ALines.Add(s2);
        s := '';
      end;
    end
    else
    begin
      if s2 <> '' then
        ALines.Add(s2);
      s := '';
    end; { if/else }
  end;

begin
  if AText = '' then
    Exit;

  if ALineWidth = 0 then
    Exit;

  { We are doing a PostScript Name lookup (it contains Bold, Italic info) }
  lFC := gTTFontCache.Find(Font.Name);
  if not Assigned(lFC) then
    raise EReportFontNotFound.CreateFmt(SErrFontNotFound, [Font.Name]);
  { result is in pixels }
  lWidth := lFC.TextWidth(Text, Font.Size);
  lHeight := lFC.TextHeight(Text, Font.Size, lDescenderHeight);
  { convert pixels to mm as our Reporting Units are defined as mm. }
  AHeight := PixelsToMM(lHeight+lDescenderHeight);

  s := '';
  ALines.Clear;
  n := 1;
  maxw := mmToPixels(ALineWidth - TextAlignment.LeftMargin - TextAlignment.RightMargin);
  { Do we really need to do text wrapping? There must be no linefeed characters and lWidth must be less than maxw. }
  if ((Pos(#13, AText) = 0) and (Pos(#10, AText) = 0)) and (lWidth <= maxw) then
  begin
    ALines.Add(AText);
    Exit;
  end;

  { We got here, so wrapping is needed. First process line wrapping as indicated
    by LineEnding characters in the text. }
  while n <= Length(AText) do
  begin
    c := AText[n];
    if (c = #13) or (c = #10) then
    begin
      { See code comment of AddLine() for the meaning of the True argument. }
      AddLine(true);
      if (c = #13) and (n < Length(AText)) and (AText[n+1] = #10) then
        Inc(n);
    end
    else
      s := s + c;
    Inc(n);
  end; { while }

  { Now wrap lines that are longer than ALineWidth }
  AddLine(true);
end;

procedure TFPReportCustomMemo.ApplyStretchMode(const AHeight: TFPReportUnits);
var
  j: TFPReportUnits;
begin
  if Assigned(RTLayout) then
  begin
    j :=((AHeight + LineSpacing) * TextLines.Count) + TextAlignment.TopMargin + TextAlignment.BottomMargin;
    if j > RTLayout.Height then { only grow height if needed. We don't shrink. }
      RTLayout.Height := j;
  end;
end;

{ this affects only X coordinate of text blocks }
procedure TFPReportCustomMemo.ApplyHorzTextAlignment;
var
  i: integer;
  tb: TFPTextBlock;
  lList: TFPList;
  lLastYPos: TFPReportUnits;

  procedure ProcessLeftJustified;
  var
    idx: integer;
    b: TFPTextBlock;
    lXOffset: TFPReportUnits;
  begin
    if TextAlignment.LeftMargin = 0 then
      exit;
    { All the text blocks must move by LeftMargin to the right. }
    lXOffset := TextAlignment.LeftMargin;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Left := lXOffset + b.Pos.Left
    end;
  end;

  procedure ProcessRightJustified;
  var
    idx: integer;
    b: TFPTextBlock;
    lXOffset: TFPReportUnits;
  begin
    lXOffset := Layout.Width - TextAlignment.RightMargin;
    for idx := lList.Count-1 downto 0 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Left := lXOffset - b.Width;
      lXOffset := b.Pos.Left;
    end;
  end;

  procedure ProcessCentered;
  var
    idx: integer;
    b: TFPTextBlock;
    lXOffset: TFPReportUnits;
    lTotalWidth: TFPReportUnits;
  begin
    lTotalWidth := 0;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      lTotalWidth := lTotalWidth + b.Width;
    end;
    lXOffset := (Layout.Width - lTotalWidth) / 2;
    if lXOffset < 0.0 then { it should never be, but lets play it safe }
      lXOffset := 0.0;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Left := lXOffset;
      lXOffset := lXOffset + b.Width;
    end;
  end;

  procedure ProcessWidth;
  var
    idx: integer;
    b: TFPTextBlock;
    lXOffset: TFPReportUnits;
    lSpace: TFPReportUnits;
    lTotalWidth: TFPReportUnits;
  begin
    lTotalWidth := 0;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      lTotalWidth := lTotalWidth + b.Width;
    end;
    lSpace := (Layout.Width - TextAlignment.LeftMargin - TextAlignment.RightMargin - lTotalWidth) / (lList.Count-1);
    { All the text blocks must move by LeftMargin to the right. }
    lXOffset := TextAlignment.LeftMargin;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Left := lXOffset;
      lXOffset := lXOffset + b.Width + lSpace;
    end;
  end;

begin
  lList := TFPList.Create;
  lLastYPos := 0;
  for i := 0 to FTextBlockList.Count-1 do
  begin
    tb := FTextBlockList[i];
    if tb.Pos.Top = lLastYPos then // still on the same text line
      lList.Add(tb)
    else
    begin
      { a new line has started - process what we have collected in lList }
      case TextAlignment.Horizontal of
        taLeftJustified:   ProcessLeftJustified;
        taRightJustified:  ProcessRightJustified;
        taCentered:        ProcessCentered;
        taWidth:           ProcessWidth;
      end;
      lList.Clear;
      lLastYPos := tb.Pos.Top;
      lList.Add(tb)
    end; { if..else }
  end; { for i }

  { process the last text line's items }
  if lList.Count > 0 then
  begin
    case TextAlignment.Horizontal of
      taLeftJustified:   ProcessLeftJustified;
      taRightJustified:  ProcessRightJustified;
      taCentered:        ProcessCentered;
      taWidth:           ProcessWidth;
    end;
  end;
  lList.Free;
end;

{ this affects only Y coordinate of text blocks }
procedure TFPReportCustomMemo.ApplyVertTextAlignment;
var
  i: integer;
  tb: TFPTextBlock;
  lList: TFPList;
  lLastYPos: TFPReportUnits;
  lTotalHeight: TFPReportUnits;
  lYOffset: TFPReportUnits;

  procedure ProcessTop;
  var
    idx: integer;
    b: TFPTextBlock;
  begin
    if lList.Count = 0 then
      Exit;
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Top := lYOffset;
    end;
    lYOffset := lYOffset + LineSpacing + b.Height + b.Descender;
  end;

  procedure ProcessCenter;
  var
    idx: integer;
    b: TFPTextBlock;
  begin
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Top := lYOffset;
    end;
    lYOffset := lYOffset + LineSpacing + b.Height + b.Descender;
  end;

  procedure ProcessBottom;
  var
    idx: integer;
    b: TFPTextBlock;
  begin
    for idx := 0 to lList.Count-1 do
    begin
      b := TFPTextBlock(lList[idx]);
      b.Pos.Top := lYOffset;
    end;
    lYOffset := lYOffset - LineSpacing - b.Height - b.Descender;
  end;

begin
  if FTextBlockList.Count = 0 then
    Exit;
  lList := TFPList.Create;
  try
  lLastYPos := FTextBlockList[FTextBlockList.Count-1].Pos.Top;  // last textblock's Y coordinate
  lTotalHeight := 0;

  if TextAlignment.Vertical = tlTop then
  begin
    if TextAlignment.TopMargin = 0 then
      Exit; // nothing to do
    lYOffset := TextAlignment.TopMargin;
    for i := 0 to FTextBlockList.Count-1 do
    begin
      tb := FTextBlockList[i];
      if tb.Pos.Top = lLastYPos then // still on the same text line
        lList.Add(tb)
      else
      begin
        { a new line has started - process what we have collected in lList }
        ProcessTop;

        lList.Clear;
        lLastYPos := tb.Pos.Top;
        lList.Add(tb)
      end; { if..else }
    end; { for i }
  end

  else if TextAlignment.Vertical = tlBottom then
  begin
    lYOffset := Layout.Height;
    for i := FTextBlockList.Count-1 downto 0 do
    begin
      tb := FTextBlockList[i];
      if i = FTextBlockList.Count-1 then
        lYOffset := lYOffset - tb.Height - tb.Descender - TextAlignment.BottomMargin;  // only need to do this for one line
      if tb.Pos.Top = lLastYPos then // still on the same text line
        lList.Add(tb)
      else
      begin
        { a new line has started - process what we have collected in lList }
        ProcessBottom;

        lList.Clear;
        lLastYPos := tb.Pos.Top;
        lList.Add(tb)
      end; { if..else }
    end; { for i }
  end

  else if TextAlignment.Vertical = tlCenter then
  begin
    { First, collect the total height of all the text lines }
    lTotalHeight := 0;
    lLastYPos := 0;
    for i := 0 to FTextBlockList.Count-1 do
    begin
      tb := FTextBlockList[i];
      if i = 0 then  // do this only for the first block
        lTotalHeight := tb.Height + tb.Descender;
      if tb.Pos.Top = lLastYPos then // still on the same text line
        Continue
      else
      begin
        { a new line has started - process what we have collected in lList }
        lTotalHeight := lTotalHeight + LineSpacing + tb.Height + tb.Descender;
      end; { if..else }
      lLastYPos := tb.Pos.Top;
    end; { for i }

    { Now process them line-by-line }
    lList.Clear;
    lYOffset := (Layout.Height - lTotalHeight) / 2;
    lLastYPos := 0;
    for i := 0 to FTextBlockList.Count-1 do
    begin
      tb := FTextBlockList[i];
      if tb.Pos.Top = lLastYPos then // still on the same text line
        lList.Add(tb)
      else
      begin
        { a new line has started - process what we have collected in lList }
        ProcessCenter;

        lList.Clear;
        lLastYPos := tb.Pos.Top;
        lList.Add(tb)
      end; { if..else }
    end; { for i }
  end;

  { process the last text line's items }
  if lList.Count > 0 then
  begin
    case TextAlignment.Vertical of
      tlTop:     ProcessTop;
      tlCenter:  ProcessCenter;
      tlBottom:  ProcessBottom;
    end;
  end;

  finally
    lList.Free;
  end;
end;

{ package the text into TextBlock objects. We don't apply Memo Margins here - that
  gets done in the Apply*TextAlignment() methods. }
procedure TFPReportCustomMemo.PrepareTextBlocks;
var
  i: integer;
begin
  { blockstate is cleared outside the FOR loop because the font state could
    roll over to multiple lines. }
  FTextBlockState := [];
  FTextBlockYOffset := 0;
  FLastURL := '';
  FLastFGColor := clNone;
  FLastBGColor := clNone;

  for i := 0 to FTextLines.Count-1 do
  begin
    FTextBlockXOffset := 0;
    if Assigned(FCurTextBlock) then
      FTextBlockYOffset := FTextBlockYOffset + FCurTextBlock.Height + FCurTextBlock.Descender + LineSpacing;

    if moAllowHTML in Options then
    begin
      FParser := THTMLParser.Create(FTextLines[i]);
      try
        FParser.OnFoundTag := @HTMLOnFoundTag;
        FParser.OnFoundText := @HTMLOnFoundText;
        FParser.Exec;
      finally
        FParser.Free;
      end;
    end
    else
    begin
      if TextAlignment.Horizontal <> taWidth then
        AddSingleTextBlock(FTextLines[i])
      else
        AddMultipleTextBlocks(FTextLines[i]);
    end;
  end; { for i }
end;

function TFPReportCustomMemo.GetTextLines: TStrings;
begin
  if StretchMode <> smDontStretch then
    Result := FTextLines
  else
    Result := nil;
end;

procedure TFPReportCustomMemo.SetLineSpacing(AValue: TFPReportUnits);
begin
  if FLineSpacing = AValue then
    Exit;
  FLineSpacing := AValue;
  Changed;
end;

procedure TFPReportCustomMemo.HTMLOnFoundTag(NoCaseTag, ActualTag: string);
var
  v: string;
begin
  if NoCaseTag = '<B>' then
    Include(FTextBlockState, htBold)
  else if NoCaseTag = '</B>' then
    Exclude(FTextBlockState, htBold)
  else if NoCaseTag = '<I>' then
    Include(FTextBlockState, htItalic)
  else if NoCaseTag = '</I>' then
    Exclude(FTextBlockState, htItalic)
  else if (FParser.GetTagName(NoCaseTag) = 'A') then
    FLastURL := FParser.GetVal(ActualTag, 'href')
  else if (FParser.GetTagName(NoCaseTag) = '/A') then
    FLastURL := ''
  else if FParser.GetTagName(NoCaseTag) = 'FONT' then
  begin
    { process the opening tag }
    v := FParser.GetVal(NoCaseTag, 'color');
    if v <> '' then
      FLastFGColor := HtmlColorToFPReportColor(v);
    v := FParser.GetVal(NoCaseTag, 'bgcolor');
    if v <> '' then
      FLastBGColor := HtmlColorToFPReportColor(v);
  end
  else if FParser.GetTagName(NoCaseTag) = '/FONT' then
  begin
    { process the closing tag }
    FLastFGColor := clNone;
    FLastBGColor := clNone;
  end;
end;

procedure TFPReportCustomMemo.HTMLOnFoundText(Text: string);
var
  lNewFontName: string;
  lDescender: TFPReportUnits;
  lHasURL: boolean;
begin
  lHasURL := FLastURL <> '';

  FCurTextBlock := CreateTextBlock(lHasURL);
  if lHasURL then
  begin
    TFPHTTPTextBlock(FCurTextBlock).URL := FLastURL;
    FCurTextBlock.FGColor := LinkColor;
  end;

  try
    FCurTextBlock.Text := Text;

    if FLastFGColor <> clNone then
      FCurTextBlock.FGColor := FLastFGColor;
    if FLastBGColor <> clNone then
      FCurTextBlock.BGColor := FLastBGColor;

    lNewFontName := Font.Name;
    if [htBold, htItalic] <= FTextBlockState then // test if it is a sub-set of FTextBlockState
      lNewFontName := lNewFontName + '-BoldItalic'
    else if htBold in FTextBlockState then
      lNewFontName := lNewFontName + '-Bold'
    else if htItalic in FTextBlockState then
      lNewFontName := lNewFontName + '-Italic';
    FCurTextBlock.FontName := lNewFontName;

    FCurTextBlock.Width := TextWidth(FCurTextBlock.Text);
    FCurTextBlock.Height := TextHeight(FCurTextBlock.Text, lDescender);
    FCurTextBlock.Descender := lDescender;

    // get X offset from previous textblocks
    FCurTextBlock.Pos.Left := FTextBlockXOffset;
    FCurTextBlock.Pos.Top := FTextBlockYOffset;
    FTextBlockXOffset := FTextBlockXOffset + FCurTextBlock.Width;
  except
    on E: EReportFontNotFound do
    begin
      FCurTextBlock.Free;
      raise;
    end;
  end;
  FTextBlockList.Add(FCurTextBlock);
end;

function TFPReportCustomMemo.PixelsToMM(APixels: single): single;
begin
  Result := (APixels * cMMperInch) / gTTFontCache.DPI;
end;

function TFPReportCustomMemo.mmToPixels(mm: single): integer;
begin
  Result := Round(mm * (gTTFontCache.DPI / cMMperInch));
end;

function TFPReportCustomMemo.TextHeight(const AText: string; out ADescender: TFPReportUnits): TFPReportUnits;
var
  lHeight: single;
  lDescenderHeight: single;
  lFC: TFPFontCacheItem;
begin
  // TODO: FontName might need to change to TextBlock.FontName.
  lFC := gTTFontCache.Find(Font.Name); // we are doing a PostScript Name lookup (it contains Bold, Italic info)
  if not Assigned(lFC) then
    raise EReportFontNotFound.CreateFmt(SErrFontNotFound, [Font.Name]);
  { Both lHeight and lDescenderHeight are in pixels }
  lHeight := lFC.TextHeight(AText, Font.Size, lDescenderHeight);

  { convert pixels to mm. }
  ADescender := PixelsToMM(lDescenderHeight);
  Result := PixelsToMM(lHeight);
end;

function TFPReportCustomMemo.TextWidth(const AText: string): TFPReportUnits;
var
  lWidth: single;
  lFC: TFPFontCacheItem;
begin
  // TODO: FontName might need to change to TextBlock.FontName.
  lFC := gTTFontCache.Find(Font.Name); // we are doing a PostScript Name lookup (it contains Bold, Italic info)
  if not Assigned(lFC) then
    raise EReportFontNotFound.CreateFmt(SErrFontNotFound, [Font.Name]);
  { result is in pixels }
  lWidth := lFC.TextWidth(AText, Font.Size);

  { convert pixels to mm. }
  Result := PixelsToMM(lWidth);
end;

procedure TFPReportCustomMemo.SetLinkColor(AValue: TFPReportColor);
begin
  if FLinkColor = AValue then
    Exit;
  FLinkColor := AValue;
  Changed;
end;

procedure TFPReportCustomMemo.SetTextAlignment(AValue: TFPReportTextAlignment);
begin
  if FTextAlignment = AValue then
    Exit;
  BeginUpdate;
  try
    FTextAlignment.Assign(AValue);
  finally
    EndUpdate;
  end;
end;

procedure TFPReportCustomMemo.SetOptions(const AValue: TFPReportMemoOptions);
begin
  if FOptions = AValue then
    Exit;
  FOptions := AValue;
  { If Options conflicts with StretchMode, then remove moDisableWordWrap from Options. }
  if StretchMode <> smDontStretch then
    Exclude(FOptions, moDisableWordWrap);
  Changed;
end;

function TFPReportCustomMemo.SubStr(const ASource, AStartDelim, AEndDelim: string; AIndex: integer; out
  AStartPos: integer): string;
var
  liStart : integer;
  liEnd  : integer;
  i: integer;
begin
  liStart := 0;
  if AIndex < 1 then
    AIndex := 1;
  for i := 1 to AIndex do
    liStart := PosEx(AStartDelim, ASource, liStart+1);

  result := '';
  AStartPos := -1;

  if liStart <> 0 then
    liStart := liStart + Length(AStartDelim);

  liEnd := PosEx(AEndDelim, ASource, liStart);
  if liEnd <> 0 then
    liEnd := liEnd - 1;

  if (liStart = 0) or (liEnd = 0) then
    Exit; //==>

  result := Copy(ASource, liStart, liEnd - liStart + 1);
  AStartPos := liStart;
end;

procedure TFPReportCustomMemo.ParseText;
var
  lCount: integer;
  n: TFPExprNode;
  i: integer;
  str: string;
  lStartPos: integer;
begin
  { clear array and then set the correct array size }
  ClearExpressionNodes;
  if Pos('[', Text) > 0 then
    lCount := TokenCount(Text)-1
  else
    exit;

  SetLength(ExpressionNodes, lCount);

  str := '';
  n := nil;
  for i := 1 to lCount do
  begin
    str := SubStr(Text, '[', ']', i, lStartPos);
    if str <> '' then
    begin
      GetExpr.Expression := str;
      GetExpr.ExtractNode(n);
      if n.HasAggregate then
        n.InitAggregate;
      ExpressionNodes[i-1].Position := lStartPos;
      ExpressionNodes[i-1].ExprNode := n;
    end;
  end;
end;

procedure TFPReportCustomMemo.ClearExpressionNodes;
var
  i: integer;
begin
  for i := 0 to Length(ExpressionNodes)-1 do
    ExpressionNodes[i].ExprNode.Free;
  SetLength(ExpressionNodes, 0);
end;

procedure TFPReportCustomMemo.AddSingleTextBlock(const AText: string);
var
  lDescender: TFPReportUnits;
begin
  if AText = '' then
    Exit;  //==>
  FCurTextBlock := CreateTextBlock(false);
  try
    FCurTextBlock.Text := AText;
    FCurTextBlock.FontName := Font.Name;
    FCurTextBlock.Width := TextWidth(FCurTextBlock.Text);
    FCurTextBlock.Height := TextHeight(FCurTextBlock.Text, lDescender);
    FCurTextBlock.Descender := lDescender;

    // get X offset from previous textblocks
    FCurTextBlock.Pos.Left := FTextBlockXOffset;
    FCurTextBlock.Pos.Top := FTextBlockYOffset;
    FTextBlockXOffset := FTextBlockXOffset + FCurTextBlock.Width;
  except
    on E: EReportFontNotFound do
    begin
      FCurTextBlock.Free;
      raise;
    end;
  end;
  FTextBlockList.Add(FCurTextBlock);
end;

procedure TFPReportCustomMemo.AddMultipleTextBlocks(const AText: string);
var
  lCount: integer;
  i: integer;
begin
  lCount := TokenCount(AText, ' ');
  for i := 1 to lCount do
    AddSingleTextBlock(Token(AText, ' ', i));
end;

function TFPReportCustomMemo.TokenCount(const AValue: string; const AToken: string): integer;
var
  i, iCount : integer;
  lsValue : string;
begin
  Result := 0;
  if AValue = '' then
    Exit; //==>

  iCount := 0;
  lsValue := AValue;
  i := pos(AToken, lsValue);
  while i <> 0 do
  begin
    delete(lsValue, i, length(AToken));
    inc(iCount);
    i := pos(AToken, lsValue);
  end;
  Result := iCount+1;
end;

function TFPReportCustomMemo.Token(const AValue, AToken: string; const APos: integer): string;
var
  i, iCount, iNumToken: integer;
  lsValue: string;
begin
  result := '';

  iNumToken := TokenCount(AValue, AToken);
  if APos = 1 then
  begin
    if pos(AToken, AValue) = 0 then
      result := AValue
    else
      result := copy(AValue, 1, pos(AToken, AValue)-1);
  end
  else if (iNumToken < APos-1) or (APos<1) then
  begin
    result := '';
  end
  else
  begin
    { Remove leading blocks }
    iCount := 1;
    lsValue := AValue;
    i := pos(AToken, lsValue);
    while (i<>0) and (iCount<APos) do
    begin
      delete(lsValue, 1, i + length(AToken) - 1);
      inc(iCount);
      i := pos(AToken, lsValue);
    end;

    if (i=0) and (iCount=APos) then
      result := lsValue
    else if (i=0) and (iCount<>APos) then
      result := ''
    else
      result := copy(lsValue, 1, i-1);
  end;
end;

function TFPReportCustomMemo.IsExprAtArrayPos(const APos: integer): Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to Length(Original.ExpressionNodes)-1 do
  begin
    if Original.ExpressionNodes[i].Position = APos then
    begin
      if Original.ExpressionNodes[i].ExprNode <> nil then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

procedure TFPReportCustomMemo.SetFont(const AValue: TFPReportFont);
begin
  if UseParentFont then
    UseParentFont := False;
  FFont.Assign(AValue);
  Changed;
end;

function TFPReportCustomMemo.CreateTextAlignment: TFPReportTextAlignment;
begin
  Result := TFPReportTextAlignment.Create(self);
end;

function TFPReportCustomMemo.GetExpr: TFPExpressionParser;
begin
  Result := TFPReportCustomBand(Parent).Page.Report.FExpr;
end;

function TFPReportCustomMemo.CreateTextBlock(const IsURL: boolean): TFPTextBlock;
begin
  if IsURL then
    result := TFPHTTPTextBlock.Create
  else
    result := TFPTextBlock.Create;
  result.FontName := Font.Name;
  result.FGColor := Font.Color;
  result.BGColor := clNone;
end;

function TFPReportCustomMemo.HtmlColorToFPReportColor(AColorStr: string; ADefault: TFPReportColor): TFPReportColor;
var
  N1, N2, N3: integer;
  i: integer;
  Len: integer;

  function IsCharWord(ch: char): boolean;
  begin
    Result := ch in ['a'..'z', 'A'..'Z', '_', '0'..'9'];
  end;

  function IsCharHex(ch: char): boolean;
  begin
    Result := ch in ['0'..'9', 'a'..'f', 'A'..'F'];
  end;

begin
  Result := ADefault;
  Len := 0;
  if (AColorStr <> '') and (AColorStr[1] = '#') then
    Delete(AColorStr, 1, 1);
  if (AColorStr = '') then
    exit;

  //delete after first nonword char
  i := 1;
  while (i <= Length(AColorStr)) and IsCharWord(AColorStr[i]) do
    Inc(i);
  Delete(AColorStr, i, Maxint);

  //allow only #rgb, #rrggbb
  Len := Length(AColorStr);
  if (Len <> 3) and (Len <> 6) then
    Exit;

  for i := 1 to Len do
    if not IsCharHex(AColorStr[i]) then
      Exit;

  if Len = 6 then
  begin
    N1 := StrToInt('$'+Copy(AColorStr, 1, 2));
    N2 := StrToInt('$'+Copy(AColorStr, 3, 2));
    N3 := StrToInt('$'+Copy(AColorStr, 5, 2));
  end
  else
  begin
    N1 := StrToInt('$'+AColorStr[1]+AColorStr[1]);
    N2 := StrToInt('$'+AColorStr[2]+AColorStr[2]);
    N3 := StrToInt('$'+AColorStr[3]+AColorStr[3]);
  end;

  Result := RGBToReportColor(N1, N2, N3);
end;

procedure TFPReportCustomMemo.PrepareObject;
var
  lBand: TFPReportCustomBand;
  lMemo: TFPReportCustomMemo;
begin
  if not self.EvaluateVisibility then
    Exit;
  if Parent is TFPReportCustomBand then
  begin
    // find reference to the band we are layouting
    lBand := TFPReportCustomBand(Parent).Page.Report.FRTCurBand;
    lMemo := TFPReportCustomMemo.Create(lBand);
    lMemo.Assign(self);
    lMemo.CreateRTLayout;
  end;
  //inherited PrepareObject;
end;

procedure TFPReportCustomMemo.RecalcLayout;
var
  h: TFPReportUnits;
begin
  FTextBlockList.Clear;
  FCurTextBlock := nil;
  if not Assigned(FTextLines) then
    FTextLines := TStringList.Create
  else
    FTextLines.Clear;

  if not (moDisableWordWrap in Options) then
    WrapText(Text, FTextLines, Layout.Width, h)
  else
    FTextLines.Add(Text);

  if StretchMode <> smDontStretch then
    ApplyStretchMode(h);

  PrepareTextBlocks;
  ApplyVertTextAlignment;
  ApplyHorzTextAlignment;
end;

procedure TFPReportCustomMemo.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteString('Text', Text);

  AWriter.WriteBoolean('UseParentFont', UseParentFont);
  if not UseParentFont then
  begin
    AWriter.WriteString('FontName', Font.Name);
    AWriter.WriteInteger('FontSize', Font.Size);
    AWriter.WriteInteger('FontColor', Font.Color);
  end;

  AWriter.WriteFloat('LineSpacing', LineSpacing);
  AWriter.WriteInteger('LinkColor', LinkColor);
  AWriter.WriteString('Options', MemoOptionsToString(Options));
end;

procedure TFPReportCustomMemo.ExpandExpressions;
var
  lCount: integer;
  str: string;
  n: TFPExprNode;
  i: integer;
  lStartPos: integer;
  lResult: string;
  s: string;
begin
  lCount := TokenCount(Text);
  if lCount = 0 then
    Exit;
  lResult := Text;
  str := '';
  n := nil;
  for i := 0 to lCount-1 do
  begin
    str := SubStr(Text, '[', ']', i+1, lStartPos);
    if str <> '' then
    begin
      if IsExprAtArrayPos(lStartPos) then
      begin
        n := Original.ExpressionNodes[i].ExprNode;
        case n.NodeValue.ResultType of
          rtString  : s := n.NodeValue.ResString;
          rtInteger : s := IntToStr(n.NodeValue.ResInteger);
          rtFloat   : s := FloatToStr(n.NodeValue.ResFloat);
          rtBoolean : s := BoolToStr(n.NodeValue.ResBoolean, True);
          rtDateTime : s := FormatDateTime('yyyy-mm-dd', n.NodeValue.ResDateTime);
        end;
        lResult := StringReplace(lResult, '[' + str + ']', s, [rfReplaceAll]);
      end;
    end;
  end;
  Text := lResult;
end;

constructor TFPReportCustomMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsExpr := False;
  FLinkColor := clBlue;
  FTextAlignment := CreateTextAlignment;
  FTextLines := TStringList.Create;
  FLineSpacing := 1; // millimeters
  FTextBlockList := TFPTextBlockList.Create;
  FOptions := [];
  FOriginal := nil;
  FUseParentFont := True;
  FFont := nil
end;

destructor TFPReportCustomMemo.Destroy;
begin
  FreeAndNil(FTextLines);
  FreeAndNil(FTextBlockList);
  FreeAndNil(FTextAlignment);
  ClearExpressionNodes;
  FreeAndNil(FFont);
  inherited Destroy;
end;

procedure TFPReportCustomMemo.Assign(Source: TPersistent);
var
  E: TFPReportCustomMemo;
begin
  inherited Assign(Source);
  if (Source is TFPReportCustomMemo) then
  begin
    E := Source as TFPReportCustomMemo;
    Text := E.Text;
    UseParentFont := E.UseParentFont;
    if not UseParentFont then
      Font.Assign(E.Font);
    LineSpacing := E.LineSpacing;
    LinkColor := E.LinkColor;
    TextAlignment.Assign(E.TextAlignment);
    Options := E.Options;
    Original := E;
  end;
end;

procedure TFPReportCustomMemo.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
begin
  inherited ReadElement(AReader);
  E := AReader.FindChild('TextAlignment');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      FTextAlignment.ReadElement(AReader);
    finally
      AReader.PopElement;
    end;
  end;
  FText := AReader.ReadString('Text', '');
  FUseParentFont := AReader.ReadBoolean('UseParentFont', UseParentFont);
  if not FUseParentFont then
  begin
    Font.Name := AReader.ReadString('FontName', Font.Name);
    Font.Size := AReader.ReadInteger('FontSize', Font.Size);
    Font.Color := AReader.ReadInteger('FontColor', Font.Color);
  end;
  FLineSpacing := AReader.ReadFloat('LineSpacing', LineSpacing);
  FLinkColor := AReader.ReadInteger('LinkColor', LinkColor);
  Options := StringToMemoOptions(AReader.ReadString('Options', ''));
  Changed;
end;

procedure TFPReportCustomMemo.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
var
  T: TFPReportTextAlignment;
begin
  AWriter.PushElement('Memo');
  try
    inherited WriteElement(AWriter, AOriginal);
    if (AOriginal <> nil) then
      T := TFPReportCustomMemo(AOriginal).TextAlignment
    else
      T := nil;
    AWriter.PushElement('TextAlignment');
    try
      FTextAlignment.WriteElement(AWriter, T);
    finally
      AWriter.PopElement;
    end;
  finally
    AWriter.PopElement;
  end;
end;

{ TFPReportCustomShape }

procedure TFPReportCustomShape.SetShapeType(AValue: TFPReportShapeType);
begin
  if FShapeType = AValue then
    Exit;
  FShapeType := AValue;
  Changed;
end;

procedure TFPReportCustomShape.SetOrientation(AValue: TFPReportOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  Changed;
end;

procedure TFPReportCustomShape.SetCornerRadius(AValue: TFPReportUnits);
begin
  if FCornerRadius = AValue then
    Exit;
  FCornerRadius := AValue;
  Changed;
end;

procedure TFPReportCustomShape.PrepareObject;
var
  lBand: TFPReportCustomBand;
  lShape: TFPReportCustomShape;
begin
  if not self.EvaluateVisibility then
    Exit;
  if Parent is TFPReportCustomBand then
    begin
    // find reference to the band we are layouting
    lBand := TFPReportCustomBand(Parent).Page.Report.FRTCurBand;
    lShape := TFPReportCustomShape.Create(lBand);
    lShape.Parent := lBand;
    lShape.Assign(self);
    lShape.CreateRTLayout;
    end;
  //inherited PrepareObject;
end;

procedure TFPReportCustomShape.RecalcLayout;
begin
  // Do nothing
end;

procedure TFPReportCustomShape.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteString('ShapeType', ShapeTypeToString(ShapeType));
  AWriter.WriteString('Orientation', OrientationToString(Orientation));
  AWriter.WriteFloat('CornerRadius', CornerRadius);
  AWriter.WriteInteger('Color', Color);
end;

constructor TFPReportCustomShape.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOrientation := orNorth;
  FCornerRadius := 5.0;
  FShapeType := stEllipse;
  FColor:=clBlack;
end;

procedure TFPReportCustomShape.Assign(Source: TPersistent);

Var
  S :  TFPReportCustomShape;

begin
  inherited Assign(Source);
  if Source is TFPReportCustomShape then
    begin
    S:=Source as TFPReportCustomShape;
    FOrientation:=S.Orientation;
    FCornerRadius:=S.CornerRadius;
    FShapeType:=S.ShapeType;
    FColor:=S.Color;
    end;
end;

function TFPReportCustomShape.CreatePropertyHash: String;
begin
  Result:=inherited CreatePropertyHash;
  Result:=Result+'-'+IntToStr(Ord(ShapeType))
                +'-'+IntToStr(Ord(Orientation))
                +'-'+IntToStr(Color)
                +'-'+FormatFloat('000.###',CornerRadius);
end;

procedure TFPReportCustomShape.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  AWriter.PushElement('Shape');
  try
    inherited WriteElement(AWriter, AOriginal);
  finally
    AWriter.PopElement;
  end;
end;

{ TFPReportCustomImage }

procedure TFPReportCustomImage.SetImage(AValue: TFPCustomImage);
begin
  if FImage = AValue then
    Exit;
  if Assigned(FImage) then
    FImage.Free;
  FImage := AValue;
  if Assigned(FImage) then
    FImageID := -1; { we are not using the global Report.Images here }
  Changed;
end;

procedure TFPReportCustomImage.SetStretched(AValue: boolean);
begin
  if FStretched = AValue then
    Exit;
  FStretched := AValue;
  Changed;
end;

procedure TFPReportCustomImage.SetFieldName(AValue: TFPReportString);
begin
  if FFieldName = AValue then
    Exit;
  FFieldName := AValue;
  Changed;
end;

procedure TFPReportCustomImage.LoadDBData(AData: TFPReportData);
var
  s: string;
  lStream: TMemoryStream;
begin
  s := AData.FieldValues[FFieldName];
  lStream := TMemoryStream.Create;
  try
    FPReportMIMEEncodeStringToStream(s, lStream);
    LoadPNGFromStream(lStream)
  finally
    lStream.Free;
  end;
end;

procedure TFPReportCustomImage.SetImageID(AValue: integer);
begin
  if FImageID = AValue then
    Exit;
  FImageID := AValue;
  Changed;
end;

function TFPReportCustomImage.GetImage: TFPCustomImage;
var
  c: integer;
  i: integer;
  img: TFPReportImageItem;
begin
  Result := nil;
  if ImageID = -1 then { images comes from report data }
    result := FImage
  else
  begin { image comes from global report.images list }
    c := Report.Images.Count-1;
    for i := 0 to c do
    begin
      img := Report.Images[i];
      if ImageID = img.ID then
      begin
         Result := TFPCustomImage(img.FImage);
         Exit;
      end;
    end; { for i }
  end;
end;

procedure TFPReportCustomImage.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
var
  idx: integer;
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  { Even though we work with CollectionItem ID values, write the CollectionItem
    Index value instead. Why? Because when we read the report back, the Index
    and ID values will match. }
  idx := TFPReportCustomBand(Parent).Page.Report.Images.GetIndexFromID(ImageID);
  AWriter.WriteInteger('ImageIndex', idx);
  AWriter.WriteBoolean('Stretched', Stretched);
  AWriter.WriteString('FieldName', FieldName);
end;

procedure TFPReportCustomImage.PrepareObject;
var
  lBand: TFPReportCustomBand;
  lImage: TFPReportCustomImage;
begin
  if not self.EvaluateVisibility then
    Exit;
  if Parent is TFPReportCustomBand then
  begin
    // find reference to the band we are layouting
    lBand := TFPReportCustomBand(Parent).Page.Report.FRTCurBand;
    lImage := TFPReportCustomImage.Create(lBand);
    lImage.Parent := lBand;
    lImage.Assign(self);
    lImage.CreateRTLayout;
  end;
end;

procedure TFPReportCustomImage.RecalcLayout;
begin
  // Do nothing
end;

constructor TFPReportCustomImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImage := nil;
  FStretched := False;
  FImageID := -1;
end;

destructor TFPReportCustomImage.Destroy;
begin
  FImage.Free;
  inherited Destroy;
end;

function TFPReportCustomImage.GetRTImageID: Integer;
begin
  Result:=ImageID;
end;

function TFPReportCustomImage.GetRTImage: TFPCustomImage;
begin
  Result:=Image;
end;

procedure TFPReportCustomImage.Assign(Source: TPersistent);
var
  i: TFPReportCustomImage;
begin
  inherited Assign(Source);
  if Source is TFPReportCustomImage then
  begin
    i := (Source as TFPReportCustomImage);
    if Assigned(i.Image) then
    begin
      if not Assigned(FImage) then
        FImage := TFPCompactImgRGBA8Bit.Create(0, 0);
      FImage.Assign(i.Image);
    end;
    FStretched := i.Stretched;
    FFieldName := i.FieldName;
    FImageID := i.ImageID;
  end;
end;

procedure TFPReportCustomImage.ReadElement(AReader: TFPReportStreamer);
begin
  inherited ReadElement(AReader);
  { See code comments in DoWriteLocalProperties() }
  ImageID := AReader.ReadInteger('ImageIndex', -1);
  Stretched := AReader.ReadBoolean('Stretched', Stretched);
  FieldName := AReader.ReadString('FieldName', FieldName);
end;

procedure TFPReportCustomImage.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  AWriter.PushElement('Image');
  try
    inherited WriteElement(AWriter, AOriginal);
  finally
    AWriter.PopElement;
  end;
end;

procedure TFPReportCustomImage.LoadFromFile(const AFileName: string);

var
  R : TFPCustomReport;
  i : integer;
begin
  R:=Report;
  I:=R.Images.AddFromFile(AFileName,True);
  ImageID:=R.Images[I].ID;
end;

procedure TFPReportCustomImage.LoadPNGFromStream(AStream: TStream);

var
  R : TFPCustomReport;
  i : integer;

begin
  R:=Report;
  I:=R.Images.AddFromStream(AStream,TFPReaderPNG,true);
  ImageID:=R.Images[I].ID;
end;

procedure TFPReportCustomImage.LoadImage(const AImageData: Pointer; const AImageDataSize: LongWord);

var
  s: TMemoryStream;

begin
  s := TMemoryStream.Create;
  try
    s.Write(AImageData^, AImageDataSize);
    s.Position := 0;
    LoadPNGFromStream(s);
  finally
    s.Free;
  end;
end;

{ TFPReportCustomCheckbox }

procedure TFPReportCustomCheckbox.SetExpression(AValue: TFPReportString);
begin
  if FExpression = AValue then
    Exit;
  FExpression := AValue;
  Changed;
end;

function TFPReportCustomCheckbox.LoadImage(const AImageData: Pointer; const AImageDataSize: LongWord): TFPCustomImage;
var
  s: TMemoryStream;
begin
  s := TMemoryStream.Create;
  try
    s.Write(AImageData^, AImageDataSize);
    Result := LoadImage(s);
  finally
    s.Free;
  end;
end;

function TFPReportCustomCheckbox.LoadImage(AStream: TStream): TFPCustomImage;
var
  img: TFPCompactImgRGBA8Bit;
  reader: TFPReaderPNG;
begin
  Result := nil;
  if AStream = nil then
    Exit;

  img := TFPCompactImgRGBA8Bit.Create(0, 0);
  try
    try
      AStream.Position := 0;
      reader := TFPReaderPNG.Create;
      img.LoadFromStream(AStream, reader); // auto sizes image
      Result := img;
    except
      on e: Exception do
      begin
        Result := nil;
      end;
    end;
  finally
    reader.Free;
  end;
end;

procedure TFPReportCustomCheckbox.RecalcLayout;
begin
  // Do nothing
end;

procedure TFPReportCustomCheckbox.PrepareObject;
var
  lBand: TFPReportCustomBand;
  lCB: TFPReportCustomCheckbox;
begin
  if not self.EvaluateVisibility then
    Exit;
  if Parent is TFPReportCustomBand then
  begin
    // find reference to the band we are layouting
    lBand := TFPReportCustomBand(Parent).Page.Report.FRTCurBand;
    lCB := TFPReportCustomCheckbox.Create(lBand);
    lCB.Parent := lBand;
    lCB.Assign(self);
    lCB.CreateRTLayout;
  end;
end;

constructor TFPReportCustomCheckbox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  { 3x3 millimeters }
  Layout.Width := 3;
  Layout.Height := 3;
  FTrueImageID:=-1;
  FFalseImageID:=-1;
end;

destructor TFPReportCustomCheckbox.Destroy;
begin
  inherited Destroy;
end;

function TFPReportCustomCheckbox.GetImage(Checked: Boolean): TFPCustomImage;

begin
  Result:=nil;
  if Checked then
    Result:=Report.Images.GetImageFromID(TrueImageID)
  else
    Result:=Report.Images.GetImageFromID(FalseImageID);
  if (Result=Nil) then
    Result:=GetDefaultImage(Checked);
end;

function TFPReportCustomCheckbox.GetRTResult: Boolean;
begin
  Result:=FTestResult;
end;

function TFPReportCustomCheckbox.GetRTImage: TFPCustomImage;
begin
  Result:=GetImage(GetRTResult);
end;

function TFPReportCustomCheckbox.GetDefaultImage(Checked: Boolean): TFPCustomImage;

begin
  if Checked then
    begin
    if (ImgTrue=Nil) then
      ImgTrue:=LoadImage(@fpreport_checkbox_true, SizeOf(fpreport_checkbox_true));
    Result:=ImgTrue;
    end
  else
    begin
    if (ImgFalse=Nil) then
      ImgFalse:=LoadImage(@fpreport_checkbox_false, SizeOf(fpreport_checkbox_false));
    Result:=ImgFalse;
    end;
end;

function TFPReportCustomCheckbox.CreatePropertyHash: String;
begin
  Result:=inherited CreatePropertyHash;
  Result:=Result+IntToStr(TrueImageID)+IntToStr(FalseImageID);
  Result:=Result+IntToStr(Ord(GetRTResult));
end;

procedure TFPReportCustomCheckbox.Assign(Source: TPersistent);
var
  cb: TFPReportCustomCheckbox;
begin
  inherited Assign(Source);
  if Source is TFPReportCustomCheckbox then
  begin
    cb := (Source as TFPReportCustomCheckbox);
    FTrueImageID:=cb.FTrueImageID;
    FFalseImageID:=cb.FFalseImageID;
    FExpression := cb.Expression;
  end;
end;

procedure TFPReportCustomCheckbox.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  AWriter.PushElement('Checkbox');
  try
    inherited WriteElement(AWriter, AOriginal);
  finally
    AWriter.PopElement;
  end;
end;


{ TFPReportUserData }

procedure TFPReportUserData.DoGetValue(const AFieldName: string; var AValue: variant);
begin
  inherited DoGetValue(AFieldName, AValue);
  if Assigned(FOnGetValue) then
    FOnGetValue(Self, AFieldName, AValue);
end;

procedure TFPReportUserData.DoInitDataFields;
var
  sl: TStringList;
  i: integer;
begin
  inherited DoInitDataFields;

  if Assigned(FOnGetNames) then
  begin
    sl := TStringList.Create;
    FOnGetNames(self, sl);
    for i := 0 to sl.Count-1 do
      if (Datafields.IndexOfField(sl[i])=-1) then
        DataFields.AddField(sl[i], rfkString);
    sl.Free;
  end;
end;


{ TFPReportCustomDataBand }

constructor TFPReportCustomDataBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisplayPosition := 0;
end;

{ TFPReportDataBand }

function TFPReportDataBand.GetReportBandName: string;
begin
  Result := 'DataBand';
end;

class function TFPReportDataBand.ReportBandType: TFPReportBandType;
begin
  Result:=btDataband;
end;

{ TFPReportCustomChildBand }

function TFPReportCustomChildBand.GetReportBandName: string;
begin
  Result := 'ChildBand';
end;

class function TFPReportCustomChildBand.ReportBandType: TFPReportBandType;
begin
  Result:=btChild;
end;

{ TFPReportCustomPageFooterBand }

function TFPReportCustomPageFooterBand.GetReportBandName: string;
begin
  Result := 'PageFooterBand';
end;

class function TFPReportCustomPageFooterBand.ReportBandType: TFPReportBandType;
begin
  Result:=btPageFooter;
end;

{ TFPReportCustomPageHeaderBand }

function TFPReportCustomPageHeaderBand.GetReportBandName: string;
begin
  Result := 'PageHeaderBand';
end;

class function TFPReportCustomPageHeaderBand.ReportBandType: TFPReportBandType;
begin
  Result:=btPageHeader;
end;

{ TFPReportCustomColumnHeaderBand }

function TFPReportCustomColumnHeaderBand.GetReportBandName: string;
begin
  Result := 'ColumnHeaderBand';
end;

class function TFPReportCustomColumnHeaderBand.ReportBandType: TFPReportBandType;
begin
  Result:=btColumnHeader;
end;

{ TFPReportCustomColumnFooterBand }

procedure TFPReportCustomColumnFooterBand.SetFooterPosition(AValue: TFPReportFooterPosition);
begin
  if FFooterPosition = AValue then
    Exit;
  FFooterPosition := AValue;
end;

procedure TFPReportCustomColumnFooterBand.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteString('FooterPosition', ColumnFooterPositionToString(FFooterPosition));
end;

function TFPReportCustomColumnFooterBand.GetReportBandName: string;
begin
  Result := 'ColumnFooterBand';
end;

constructor TFPReportCustomColumnFooterBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFooterPosition := fpColumnBottom;
end;

procedure TFPReportCustomColumnFooterBand.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  FFooterPosition := TFPReportCustomColumnFooterBand(Source).FooterPosition;
end;

class function TFPReportCustomColumnFooterBand.ReportBandType: TFPReportBandType;
begin
  Result:=btColumnFooter;
end;

procedure TFPReportCustomColumnFooterBand.ReadElement(AReader: TFPReportStreamer);
begin
  inherited ReadElement(AReader);
  FFooterPosition := StringToColumnFooterPosition(AReader.ReadString('FooterPosition', 'fpColumnBottom'));
end;

{ TFPReportCustomGroupHeaderBand }

procedure TFPReportCustomGroupHeaderBand.SetGroupHeader(AValue: TFPReportCustomGroupHeaderBand);
begin
  if FGroupHeader = AValue then
    Exit;
  if Assigned(FGroupHeader) then
  begin
    FGroupHeader.FChildGroupHeader := nil;
    FGroupHeader.RemoveFreeNotification(Self);
  end;
  FGroupHeader := AValue;
  if Assigned(FGroupHeader) then
  begin
    FGroupHeader.FChildGroupHeader := Self;
    FGroupHeader.FreeNotification(Self);
  end;
end;

function TFPReportCustomGroupHeaderBand.GetReportBandName: string;
begin
  Result := 'GroupHeaderBand';
end;

procedure TFPReportCustomGroupHeaderBand.CalcGroupConditionValue;
begin
  GroupConditionValue:=Evaluate;
end;

procedure TFPReportCustomGroupHeaderBand.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteString('GroupCondition', FCondition);
end;

procedure TFPReportCustomGroupHeaderBand.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FChildGroupHeader) then
    FChildGroupHeader := nil;
  inherited Notification(AComponent, Operation);
end;

constructor TFPReportCustomGroupHeaderBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGroupHeader := nil;
  FChildGroupHeader := nil;
  FGroupFooter := nil;
end;

procedure TFPReportCustomGroupHeaderBand.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  FCondition := TFPReportCustomGroupHeaderBand(Source).GroupCondition;
end;

procedure TFPReportCustomGroupHeaderBand.ReadElement(AReader: TFPReportStreamer);
begin
  inherited ReadElement(AReader);
  FCondition := AReader.ReadString('GroupCondition', '');
end;

function TFPReportCustomGroupHeaderBand.Evaluate: string;
begin
  Result := EvaluateExpressionAsText(GroupCondition);
end;

class function TFPReportCustomGroupHeaderBand.ReportBandType: TFPReportBandType;
begin
  Result:=btGroupHeader;
end;

{ TFPReportCustomTitleBand }

function TFPReportCustomTitleBand.GetReportBandName: string;
begin
  Result := 'ReportTitleBand';
end;

class function TFPReportCustomTitleBand.ReportBandType: TFPReportBandType;
begin
  Result:=btReportTitle;
end;

{ TFPReportCustomSummaryBand }

function TFPReportCustomSummaryBand.GetReportBandName: string;
begin
  Result := 'ReportSummaryBand';
end;

procedure TFPReportCustomSummaryBand.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteBoolean('StartNewPage', StartNewPage);
end;

constructor TFPReportCustomSummaryBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStartNewPage := False;
end;

procedure TFPReportCustomSummaryBand.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TFPReportCustomSummaryBand then
    FStartNewPage := TFPReportCustomSummaryBand(Source).StartNewPage;
end;

procedure TFPReportCustomSummaryBand.ReadElement(AReader: TFPReportStreamer);
begin
  inherited ReadElement(AReader);
  FStartNewPage := AReader.ReadBoolean('StartNewPage', False);
end;

class function TFPReportCustomSummaryBand.ReportBandType: TFPReportBandType;
begin
  Result:=btReportSummary;
end;

{ TFPReportComponent }

procedure TFPReportComponent.StartLayout;
begin
  FReportState := rsLayout;
end;

procedure TFPReportComponent.EndLayout;
begin
  FReportState := rsDesign;
end;

procedure TFPReportComponent.StartRender;
begin
  FReportState := rsRender;
end;

procedure TFPReportComponent.EndRender;
begin
  FReportState := rsDesign;
end;

procedure TFPReportComponent.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  AWriter.WriteString('Name', Name);
end;

procedure TFPReportComponent.ReadElement(AReader: TFPReportStreamer);
begin
  Name := AReader.ReadString('Name', 'UnknownName');
end;

{ TFPReportRect }

procedure TFPReportRect.SetRect(aleft, atop, awidth, aheight: TFPReportUnits);
begin
  Left   := aleft;
  Top    := atop;
  Width  := awidth;
  Height := aheight;
end;

procedure TFPReportRect.OffsetRect(aLeft, ATop: TFPReportUnits);
begin
  Left:=Left+ALeft;
  Top:=Top+ATop;
end;

function TFPReportRect.IsEmpty: Boolean;
begin
  Result:=(Width=0) and (Height=0);
end;

function TFPReportRect.Bottom: TFPReportUnits;
begin
  Result := Top + Height;
end;

function TFPReportRect.Right: TFPReportUnits;
begin
  Result := Left + Width;
end;

function TFPReportRect.AsString: String;
begin
  Result:=Format('(x: %5.2f, y: %5.2f, w: %5.2f, h: %5.2f)',[Left,Top,Width,Height]);
end;

{ TFPReportFrame }

procedure TFPReportFrame.SetColor(const AValue: TFPReportColor);
begin
  if FColor = AValue then
    Exit;
  FColor := AValue;
  Changed;
end;

procedure TFPReportFrame.SetFrameLines(const AValue: TFPReportFrameLines);
begin
  if FFrameLines = AValue then
    Exit;
  FFrameLines := AValue;
  Changed;
end;

procedure TFPReportFrame.SetFrameShape(const AValue: TFPReportFrameShape);
begin
  if FFrameShape = AValue then
    Exit;
  FFrameShape := AValue;
  Changed;
end;

procedure TFPReportFrame.SetPenStyle(const AValue: TFPPenStyle);
begin
  if FPenStyle = AValue then
    Exit;
  FPenStyle := AValue;
  Changed;
end;

procedure TFPReportFrame.SetWidth(const AValue: integer);
begin
  if FWidth = AValue then
    Exit;
  if (AValue < 0) then
    ReportError(SErrInvalidLineWidth, [AValue]);
  FWidth := AValue;
  Changed;
end;

procedure TFPReportFrame.SetBackgrounColor(AValue: TFPReportColor);
begin
  if FBackgroundColor = AValue then
    Exit;
  FBackgroundColor := AValue;
  Changed;
end;

procedure TFPReportFrame.Changed;
begin
  if Assigned(FReportElement) then
    FReportElement.Changed;
end;

constructor TFPReportFrame.Create(AElement: TFPReportElement);
begin
  inherited Create;
  FReportElement := AElement;
  FPenStyle := psSolid;
  FWidth := 1;
  FColor := clNone;
  FBackgroundColor := clNone;
  FFrameShape := fsNone;
end;

procedure TFPReportFrame.Assign(ASource: TPersistent);
var
  F: TFPReportFrame;
begin
  if (ASource is TFPReportFrame) then
  begin
    F := (ASource as TFPReportFrame);
    FFrameLines := F.FFrameLines;
    FFrameShape := F.FFrameShape;
    FColor := F.FColor;
    FBackgroundColor := F.BackgroundColor;
    FPenStyle := F.FPenStyle;
    FWidth := F.FWidth;
    Changed;
  end
  else
    inherited Assign(ASource);
end;

function TFPReportFrame.Equals(AFrame: TFPReportFrame): boolean;
begin
  Result := (AFrame = Self) or ((Color = AFrame.Color) and (Pen = AFrame.Pen) and
    (Width = AFrame.Width) and (Shape = AFrame.Shape) and (Lines = AFrame.Lines) and
    (BackgroundColor = AFrame.BackgroundColor));
end;


procedure TFPReportFrame.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportFrame);
var
  I, J: integer;
begin
  if (AOriginal = nil) then
  begin
    AWriter.WriteInteger('Color', Color);
    AWriter.WriteString('Pen', FramePenToString(Pen));
    AWriter.WriteInteger('Width', Ord(Width));
    AWriter.WriteString('Shape', FrameShapeToString(Shape));
    //TODO Write out the enum values instead of the Integer value.
    I := integer(Lines);
    AWriter.WriteInteger('Lines', I);
    AWriter.WriteInteger('BackgroundColor', BackgroundColor);
  end
  else
  begin
    AWriter.WriteIntegerDiff('Color', Color, AOriginal.Color);
    AWriter.WriteStringDiff('Pen', FramePenToString(Pen), FramePenToString(AOriginal.Pen));
    AWriter.WriteIntegerDiff('Width', Ord(Width), AOriginal.Width);
    AWriter.WriteStringDiff('Shape', FrameShapeToString(Shape), FrameShapeToString(AOriginal.Shape));
    I := integer(Lines);
    J := integer(Aoriginal.Lines);
    AWriter.WriteIntegerDiff('Lines', I, J);
    AWriter.WriteIntegerDiff('BackgroundColor', BackgroundColor, AOriginal.BackgroundColor);
  end;
end;

procedure TFPReportFrame.ReadElement(AReader: TFPReportStreamer);
var
  I: integer;
begin
  Color := AReader.ReadInteger('Color', Color);
  Pen := StringToFramePen(AReader.ReadString('Pen', 'psSolid'));
  Width := AReader.ReadInteger('Width', Ord(Width));
  Shape := StringToFrameShape(AReader.ReadString('Shape', 'fsNone'));
  I := integer(Lines);
  Lines := TFPReportFrameLines(AReader.ReadInteger('Lines', I));
  BackgroundColor := AReader.ReadInteger('BackgroundColor', BackgroundColor);
end;

{ TFPReportTextAlignment }

procedure TFPReportTextAlignment.SetHorizontal(AValue: TFPReportHorzTextAlignment);
begin
  if FHorizontal = AValue then
    Exit;
  FHorizontal := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.SetVertical(AValue: TFPReportVertTextAlignment);
begin
  if FVertical = AValue then
    Exit;
  FVertical := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.SetTopMargin(AValue: TFPReportUnits);
begin
  if FTopMargin = AValue then
    Exit;
  FTopMargin := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.SetBottomMargin(AValue: TFPReportUnits);
begin
  if FBottomMargin = AValue then
    Exit;
  FBottomMargin := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.SetLeftMargin(AValue: TFPReportUnits);
begin
  if FLeftMargin = AValue then
    Exit;
  FLeftMargin := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.SetRightMargin(AValue: TFPReportUnits);
begin
  if FRightMargin = AValue then
    Exit;
  FRightMargin := AValue;
  Changed;
end;

procedure TFPReportTextAlignment.Changed;
begin
  if Assigned(FReportElement) then
    FReportElement.Changed;
end;

constructor TFPReportTextAlignment.Create(AElement: TFPReportElement);
begin
  inherited Create;
  FReportElement := AElement;
  FHorizontal := taLeftJustified;
  FVertical := tlTop;
  FLeftMargin := 1.0;
  FRightMargin := 1.0;
  FTopMargin := 0;
  FBottomMargin := 0;
end;

procedure TFPReportTextAlignment.Assign(ASource: TPersistent);
var
  F: TFPReportTextAlignment;
begin
  if (ASource is TFPReportTextAlignment) then
  begin
    F := (ASource as TFPReportTextAlignment);
    FHorizontal   := F.Horizontal;
    FVertical     := F.Vertical;
    FLeftMargin   := F.LeftMargin;
    FRightMargin  := F.RightMargin;
    FTopMargin    := F.TopMargin;
    FBottomMargin := F.BottomMargin;
    Changed;
  end
  else
    inherited Assign(ASource);
end;

procedure TFPReportTextAlignment.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportTextAlignment);
begin
  if (AOriginal = nil) then
  begin
    AWriter.WriteString('Horizontal', HorzTextAlignmentToString(Horizontal));
    AWriter.WriteString('Vertical', VertTextAlignmentToString(Vertical));
    AWriter.WriteFloat('LeftMargin', LeftMargin);
    AWriter.WriteFloat('RightMargin', RightMargin);
    AWriter.WriteFloat('TopMargin', TopMargin);
    AWriter.WriteFloat('BottomMargin', BottomMargin);
  end
  else
  begin
    AWriter.WriteStringDiff('Horizontal', HorzTextAlignmentToString(Horizontal), HorzTextAlignmentToString(AOriginal.Horizontal));
    AWriter.WriteStringDiff('Vertical', VertTextAlignmentToString(Vertical), VertTextAlignmentToString(AOriginal.Vertical));
    AWriter.WriteFloatDiff('LeftMargin', LeftMargin, AOriginal.LeftMargin);
    AWriter.WriteFloatDiff('RightMargin', RightMargin, AOriginal.RightMargin);
    AWriter.WriteFloatDiff('TopMargin', TopMargin, AOriginal.TopMargin);
    AWriter.WriteFloatDiff('BottomMargin', BottomMargin, AOriginal.BottomMargin);
  end;
end;

procedure TFPReportTextAlignment.ReadElement(AReader: TFPReportStreamer);
begin
  Horizontal := StringToHorzTextAlignment(AReader.ReadString('Horizontal', 'taLeftJustified'));
  Vertical := StringToVertTextAlignment(AReader.ReadString('Vertical', 'tlTop'));
  LeftMargin := AReader.ReadFloat('LeftMargin', LeftMargin);
  RightMargin := AReader.ReadFloat('RightMargin', RightMargin);
  TopMargin := AReader.ReadFloat('TopMargin', TopMargin);
  BottomMargin := AReader.ReadFloat('BottomMargin', BottomMargin);
end;

{ TFPReportCustomLayout }

function TFPReportCustomLayout.GetWidth: TFPreportUnits;
begin
  Result := FPos.Width;
end;

function TFPReportCustomLayout.GetHeight: TFPreportUnits;
begin
  Result := FPos.Height;
end;

procedure TFPReportCustomLayout.SetLeft(const AValue: TFPreportUnits);
begin
  if (AValue = FPos.Left) then
    Exit;
  FPos.Left := AValue;
  Changed;
end;

procedure TFPReportCustomLayout.SetTop(const AValue: TFPreportUnits);
begin
  if (AValue = FPos.Top) then
    Exit;
  FPos.Top := AValue;
  Changed;
end;

procedure TFPReportCustomLayout.SetWidth(const AValue: TFPreportUnits);
begin
  if (AValue = FPos.Width) then
    Exit;
  FPos.Width := AValue;
  Changed;
end;

procedure TFPReportCustomLayout.SetHeight(const AValue: TFPreportUnits);
begin
  if (AValue = FPos.Height) then
    Exit;
  FPos.Height := AValue;
  Changed;
end;

function TFPReportCustomLayout.GetLeft: TFPreportUnits;
begin
  Result := FPos.Left;
end;

function TFPReportCustomLayout.GetTop: TFPreportUnits;
begin
  Result := FPos.Top;
end;

constructor TFPReportCustomLayout.Create(AElement: TFPReportElement);
begin
  FReportElement := AElement;
end;

procedure TFPReportCustomLayout.Assign(Source: TPersistent);
var
  l: TFPReportCustomLayout;
begin
  if Source is TFPReportCustomLayout then
  begin
    l := (Source as TFPReportCustomLayout);
    FPos.Height := l.Height;
    FPos.Left := l.Left;
    FPos.Top := l.Top;
    FPos.Width := l.Width;
  end
  else
    inherited Assign(Source);
end;

procedure TFPReportCustomLayout.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportCustomLayout);
begin
  if (AOriginal = nil) then
  begin
    AWriter.WriteFloat('Top', Top);
    AWriter.WriteFloat('Left', Left);
    AWriter.WriteFloat('Width', Width);
    AWriter.WriteFloat('Height', Height);
  end
  else
  begin
    AWriter.WriteFloatDiff('Top', Top, AOriginal.Top);
    AWriter.WriteFloatDiff('Left', Left, AOriginal.Left);
    AWriter.WriteFloatDiff('Width', Width, AOriginal.Width);
    AWriter.WriteFloatDiff('Height', Height, AOriginal.Height);
  end;
end;

procedure TFPReportCustomLayout.ReadElement(AReader: TFPReportStreamer);
begin
  FPos.Top := AReader.ReadFloat('Top', Top);
  FPos.Left := AReader.ReadFloat('Left', Left);
  FPos.Width := AReader.ReadFloat('Width', Width);
  FPos.Height := AReader.ReadFloat('Height', Height);
  Changed;
end;

function TFPReportCustomLayout.Equals(ALayout: TFPReportCustomLayout): boolean;
begin
  Result := (ALayout = Self) or ((ALayout.FPos.Top = FPos.Top) and (ALayout.FPos.Left = FPos.Left) and
    (ALayout.FPos.Right = FPos.Right) and (ALayout.FPos.Bottom = FPos.Bottom));
end;

procedure TFPReportCustomLayout.GetBoundsRect(out ARect: TFPReportRect);
begin
  ARect := FPos;
end;

procedure TFPReportCustomLayout.SetPosition(aleft, atop, awidth, aheight: TFPReportUnits);
begin
  FPos.SetRect(aleft,aTop,aWidth,aHeight);
  Changed;
end;

procedure TFPReportCustomLayout.SetPosition(const ARect: TFPReportRect);
begin
  FPos.SetRect(ARect.Left,ARect.Top,ARect.Width,ARect.Height);
  Changed;
end;

{ TFPReportLayout }

procedure TFPReportLayout.Changed;
begin
  if Assigned(FReportElement) then
    FReportElement.Changed;
end;

{ TFPReportElement }

procedure TFPReportElement.SetFrame(const AValue: TFPReportFrame);
begin
  if FFrame = AValue then
    Exit;
  BeginUpdate;
  try
    FFrame.Assign(AValue);
  finally
    EndUpdate;
  end;
end;

function TFPReportElement.GetReport: TFPCustomReport;

Var
  El : TFpReportElement;

begin
  Result:=Nil;
  El:=Self;
  While Assigned(El) and not El.InheritsFrom(TFPReportCustomPage) do
    El:=El.Parent;
  if Assigned(El) then
    Result:=TFPReportCustomPage(el).Report;
end;

function TFPReportElement.GetReportBand: TFPReportCustomBand;
begin
  if (Self is TFPReportCustomBand) then
    Result := Self as TFPReportCustomBand
  else if (Parent is TFPReportCustomBand) then
    Result := Parent as TFPReportCustomBand
  else
    Result := nil;
end;

function TFPReportElement.EvaluateVisibility: boolean;

var
  Res : TFPExpressionResult;

begin
  Result := Visible;
  if Result and (FVisibleExpr <> '') then 
    begin
    if EvaluateExpression(FVisibleExpr,res) then
      if (res.ResultType=rtBoolean) then // We may need to change this.
        Result:= Res.ResBoolean;
    {$ifdef gdebug}
    writeln('TFPReportElement.EvaluateVisibility: VisibleExpr=' , FVisibleExpr , '=' , Res.ResultType,' : ',Res.ResBoolean);
    {$endif}
    end;
end;

procedure TFPReportElement.SetLayout(const AValue: TFPReportLayout);
begin
  if FLayout = AValue then
    Exit;
  BeginUpdate;
  try
    FLayout.Assign(AValue);
  finally
    EndUpdate;
  end;
end;

procedure TFPReportElement.SetParent(const AValue: TFPReportElement);
begin
  if FParent = AValue then
    Exit;
  if (AValue <> nil) and not (AValue is TFPReportElementWithChildren) then
    ReportError(SErrInvalidParent, [AValue.Name, Self.Name]);
  if Assigned(FParent) then
    TFPReportElementWithChildren(FParent).RemoveChild(Self);
  FParent := AValue;
  if Assigned(FParent) then
  begin
    TFPReportElementWithChildren(FParent).AddChild(Self);
    FParent.FreeNotification(self);
  end;
  Changed;
end;

procedure TFPReportElement.SetVisible(const AValue: boolean);
begin
  if FVisible = AValue then
    Exit;
  FVisible := AValue;
  Changed;
end;

procedure TFPReportElement.SetVisibleExpr(AValue: String);
begin
  if FVisibleExpr=AValue then Exit;
  FVisibleExpr:=AValue;
  Changed;
end;

function TFPReportElement.ExpandMacro(const s: String; const AIsExpr: boolean): TFPReportString;

var
  pstart: integer;
  pend: integer;
  len: integer;
  m: string;  // macro
  mv: string; // macro value
  r: string;
  lFoundMacroInMacro: boolean;

begin
  r := s;
  lFoundMacroInMacro := False;
  pstart := Pos('[', r);
  while (pstart > 0) or lFoundMacroInMacro do
  begin
    if lFoundMacroInMacro then
    begin
      pstart := Pos('[', r);
      lFoundMacroInMacro := False;
    end;
    len := Length(r);
    pend := pstart + 2;
    while pend < len do
    begin
      if r[pend] = '[' then  // a macro inside a macro
      begin
        lFoundMacroInMacro := True;
        pstart := pend;
      end;
      if r[pend] = ']' then
        break
      else
        inc(pend);
    end;

    m := Copy(r, pstart, (pend-pstart)+1);
    if (m = '[PAGECOUNT]') and Page.Report.TwoPass and Page.Report.IsFirstPass then
    begin
      // replace macro with a non-marco marker. We'll replace the marker in the second pass of the report.
      r := StringReplace(r, m, cPageCountMarker, [rfReplaceAll, rfIgnoreCase]);
      // look for more macros
      pstart := Pos('[', r);
      Continue;
    end;

    len := Length(m);
    try
      if Assigned(Band.GetData) then
      begin
        try
          mv := Band.GetData.FieldValues[Copy(m, 2, len-2)];
        except
          on e: EVariantTypeCastError do  // maybe we have an expression not data field
          begin
            mv := EvaluateExpressionAsText(Copy(m, 2, len-2));
          end;
        end;
      end
      else
      begin // No Data assigned, but maybe we have an expression
        mv := EvaluateExpressionAsText(Copy(m, 2, len-2));
      end;
    except
      on e: EVariantTypeCastError do    // ReportData.OnGetValue did not handle all macros, so handle this gracefully
        mv := SErrUnknownMacro+': '+copy(m,2,len-2);
      on e: EExprParser do
        mv := SErrUnknownMacro+': '+copy(m,2,len-2);
    end;
    r := StringReplace(r, m, mv, [rfReplaceAll, rfIgnoreCase]);
    // look for more macros
    pstart := PosEx('[', r,PStart+Length(mv));
  end;
  { This extra check is mostly for ReportGroupHeader expression processing }
  if (pstart = 0) and Assigned(Band.GetData) and AIsExpr then
  begin
    try
      r := EvaluateExpressionAsText(r);
    except
      on E: Exception do
      begin
        { $ifdef gdebug}
        writeln('ERROR in expression: ', E.Message);
        { $endif}
        // do nothing - move on as we probably handled the expression a bit earlier in this code
      end;
    end;
  end;
  Result := r;
end;

function TFPReportElement.GetReportPage: TFPReportCustomPage;
begin
  Result := Band.Page;
end;

procedure TFPReportElement.SaveDataToNames;
begin
  // Do nothing
end;

procedure TFPReportElement.RestoreDataFromNames;
begin
  // Do nothing
end;

function TFPReportElement.CreateFrame: TFPReportFrame;
begin
  Result := TFPReportFrame.Create(Self);
end;

function TFPReportElement.CreateLayout: TFPReportLayout;
begin
  Result := TFPReportLayout.Create(Self);
end;

procedure TFPReportElement.CreateRTLayout;
begin
  FRTLayout := TFPReportLayout.Create(self);
  FRTLayout.Assign(FLayout);
end;

procedure TFPReportElement.Changed;
begin
  if (FUpdateCount = 0) then
    DoChanged;
end;

procedure TFPReportElement.DoChanged;
begin
  // Do nothing
end;

procedure TFPReportElement.PrepareObject;
var
  lBand: TFPReportCustomBand;
  EL : TFPReportElement;

begin
  if not self.EvaluateVisibility then
    Exit;
  if Parent is TFPReportCustomBand then
    begin
    // find reference to the band we are layouting
    lBand := TFPReportCustomBand(Parent).Page.Report.FRTCurBand;
    EL:=TFPReportElementClass(Self.ClassType).Create(lBand);
    EL.Assign(self);
    el.CreateRTLayout;
    end;
end;

procedure TFPReportElement.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  // will be implemented by descendant classes
end;

constructor TFPReportElement.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLayout := CreateLayout;
  FFrame := CreateFrame;
  FVisible := True;
  FStretchMode := smDontStretch;
  if AOwner is TFPReportElement then
    Parent := TFPReportElement(AOwner);
end;

destructor TFPReportElement.Destroy;
begin
  FreeAndNil(FLayout);
  FreeAndNil(FFrame);
  if Assigned(FParent) then
    (FParent as TFPReportElementWithChildren).RemoveChild(Self);
  FreeAndNil(FRTLayout);
  inherited Destroy;
end;

function TFPReportElement.CreatePropertyHash: String;

Var
  L : TFPReportCustomLayout;

begin
  if Assigned(RTLayout) then
    L:=RTLayout
  else
    L:=Layout;
  if Assigned(L) then
    Result:=Format('%6.3f%6.3f',[L.Width,L.Height]);
end;

procedure TFPReportElement.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FParent then
      FParent := nil;
  end;
  inherited Notification(AComponent, Operation);
end;

procedure TFPReportElement.BeforePrint;
begin
  if Assigned(FOnBeforePrint) then
    FOnBeforePrint(self);
end;

function TFPReportElement.EvaluateExpression(const AExpr: String; Out Res: TFPExpressionResult) : Boolean;

var
  lExpr: TFPExpressionParser;

begin
  Result:=Assigned(Report);
  if not Result then
    exit;
  lExpr := Report.FExpr;
  lExpr.Expression := AExpr;
  Res:=lExpr.Evaluate;
end;

Function TFPReportElement.GetDateTimeFormat : String;

begin
  Result:='yyyy-mm-dd';
end;

function TFPReportElement.EvaluateExpressionAsText(const AExpr: String): String;

Var
  Res : TFPExpressionResult;

begin
  Result:='';
  if EvaluateExpression(AExpr,Res) then
    case Res.ResultType of
      rtString  : Result := Res.ResString;
      rtInteger : Result := IntToStr(Res.ResInteger);
      rtFloat   : Result := FloatToStr(Res.ResFloat);
      rtBoolean : Result := BoolToStr(Res.resBoolean, True);
      rtDateTime : Result := FormatDateTime(GetDateTimeFormat, Res.resDateTime);
    end;
end;


function TFPReportElement.Equals(AElement: TFPReportElement): boolean;
begin
  Result := (AElement = Self) or ((AElement.ClassType = AElement.ClassType) and
    (AElement.Frame.Equals(Self.Frame)) and (AElement.Layout.Equals(Self.Layout))
    and (AElement.Visible = Self.Visible) and (AElement.VisibleExpr = Self.VisibleExpr));
end;

procedure TFPReportElement.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
var
  L: TFPReportCustomLayout;
  F: TFPReportFrame;
begin
  inherited WriteElement(AWriter, AOriginal);
  if (AOriginal <> nil) then
  begin
    L := AOriginal.Layout;
    F := AOriginal.Frame;
  end
  else
  begin
    F := nil;
    L := nil;
  end;
  // Always write Layout.
  AWriter.PushElement('Layout');
  try
    FLayout.WriteElement(AWriter, L);
  finally
    AWriter.PopElement;
  end;
  // now for the Frame
  if (not Assigned(F)) or (not F.Equals(FFrame)) then
  begin
    AWriter.PushElement('Frame');
    try
      FFrame.WriteElement(AWriter, F);
    finally
      AWriter.PopElement;
    end;
  end;
  AWriter.WriteBoolean('Visible', FVisible);
  AWriter.WriteString('VisibleExpr', FVisibleExpr);
  AWriter.WriteString('StretchMode', StretchModeToString(StretchMode));
  DoWriteLocalProperties(AWriter, AOriginal);
end;

procedure TFPReportElement.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
begin
  inherited ReadElement(AReader);
  E := AReader.FindChild('Layout');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      FLayout.ReadElement(AReader);
    finally
      AReader.PopElement;
    end;
  end;
  E := AReader.FindChild('Frame');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      FFrame.ReadElement(AReader);
    finally
      AReader.PopElement;
    end;
  end;
  FVisible := AReader.ReadBoolean('Visible', Visible);
  FVisibleExpr := AReader.ReadString('VisibleExpr', FVisibleExpr);
  FStretchMode := StringToStretchMode(AReader.ReadString('StretchMode', 'smDontStretch'));
  // TODO: implement reading OnBeforePrint information
end;

procedure TFPReportElement.Assign(Source: TPersistent);
var
  E: TFPReportElement;
begin
  { Don't call inherited here. }
//  inherited Assign(Source);
  if (Source is TFPReportElement) then
  begin
    E := Source as TFPReportElement;
    Frame.Assign(E.Frame);
    Layout.Assign(E.Layout);
    FParent := E.Parent;
    Visible := E.Visible;
    VisibleExpr := VisibleExpr;
    StretchMode := E.StretchMode;
    OnBeforePrint := E.OnBeforePrint;
  end;
end;

procedure TFPReportElement.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TFPReportElement.EndUpdate;
begin
  if (FUpdateCount > 0) then
    Dec(FUpdateCount);
  if (FUpdateCount = 0) then
    DoChanged;
end;

{ TFPReportElementWithChildren }

function TFPReportElementWithChildren.GetChild(AIndex: integer): TFPReportElement;
begin
  if Assigned(FChildren) then
    Result := TFPReportElement(FChildren[AIndex])
  else
    ReportError(SErrInvalidChildIndex, [0]);
end;

function TFPReportElementWithChildren.GetChildCount: integer;
begin
  if Assigned(FChildren) then
    Result := FChildren.Count
  else
    Result := 0;
end;

procedure TFPReportElementWithChildren.SaveDataToNames;

Var
  I :Integer;

begin
  inherited SaveDataToNames;
  For I:=0 to ChildCount-1 do
    Child[i].SaveDataToNames;
end;

procedure TFPReportElementWithChildren.RestoreDataFromNames;

Var
  I :Integer;
begin
  inherited RestoreDataFromNames;
  For I:=0 to ChildCount-1 do
    Child[i].RestoreDataFromNames;
end;

procedure TFPReportElementWithChildren.RemoveChild(const AChild: TFPReportElement);
begin
  if Assigned(FChildren) then
  begin
    FChildren.Remove(AChild);
    if FChildren.Count = 0 then
      FreeAndNil(FChildren);
  end;
  if not (csDestroying in ComponentState) then
    Changed;
end;

procedure TFPReportElementWithChildren.AddChild(const AChild: TFPReportElement);
begin
  if not Assigned(FChildren) then
    FChildren := TFPList.Create;
  FChildren.Add(AChild);
  if not (csDestroying in ComponentState) then
    Changed;
end;

procedure TFPReportElementWithChildren.PrepareObjects;
var
  i: integer;
begin
  for i := 0 to ChildCount - 1 do
  begin
    Child[i].PrepareObject;
  end;
end;

procedure TFPReportElementWithChildren.RecalcLayout;
var
  i: integer;
begin
  if Assigned(FChildren) then
  begin
    for i := 0 to FChildren.Count -1 do
      Child[i].RecalcLayout;
  end;
end;

destructor TFPReportElementWithChildren.Destroy;
//var
//  i: integer;
begin
  if Assigned(FChildren) then
  begin
//    for i := 0 to FChildren.Count - 1 do
//      Child[i].FParent := nil;
    FreeAndNil(FChildren);
  end;
  inherited Destroy;
end;

procedure TFPReportElementWithChildren.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
var
  i: integer;
begin
  inherited WriteElement(AWriter, AOriginal);
  if Assigned(FChildren) then
  begin
    AWriter.PushElement('Children');
    try
      for i := 0 to FChildren.Count-1 do
      begin
        AWriter.PushElement(IntToStr(i)); // use child index as identifier
        try
          TFPReportElement(FChildren[i]).WriteElement(AWriter, AOriginal);
        finally
          AWriter.PopElement;
        end;
      end;
    finally
      AWriter.PopElement;
    end;
  end;
end;

procedure TFPReportElementWithChildren.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
  i: integer;
  c: TFPReportElement;
  lName: string;
begin
  inherited ReadElement(AReader);
  E := AReader.FindChild('Children');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    for i := 0 to AReader.ChildCount-1 do
    begin
      E := AReader.GetChild(i);

      AReader.PushElement(E); // child index is the identifier
      try
        lName := AReader.CurrentElementName;
        c := gElementFactory.CreateInstance(lName, self);
        c.ReadElement(AReader);
      finally
        AReader.PopElement;
      end;
    end;  { for i }
    AReader.PopElement;
  end; { children }
end;

function TFPReportElementWithChildren.Equals(AElement: TFPReportElement): boolean;
var
  lRE: TFPReportElementWithChildren;
  i: integer;
begin
  if not (AElement is TFPReportElementWithChildren) then
    ReportError(SErrIncorrectDescendant);
  lRE := TFPReportElementWithChildren(AElement);
  Result := inherited Equals(lRE);
  if Result then
  begin
    Result := ChildCount = lRe.ChildCount;
    if Result then
    begin
      for i := 0 to ChildCount-1 do
      begin
        Result := self.Child[i].Equals(lRE.Child[i]);
        if not Result then
          Break;
      end;
    end;
  end;
end;

{ TFPReportCustomPage }

procedure TFPReportCustomPage.SetReport(const AValue: TFPCustomReport);
begin
  if FReport = AValue then
    Exit;
  if Assigned(FReport) then
  begin
    FReport.RemoveFreeNotification(self);
    FReport.RemovePage(Self);
  end;
  FReport := AValue;
  if Assigned(FReport) then
  begin
    FReport.AddPage(Self);
    FReport.FreeNotification(Self);
  end;
end;

procedure TFPReportCustomPage.SetReportData(const AValue: TFPReportData);
begin
  if FData = AValue then
    Exit;
  if Assigned(FData) then
    FData.RemoveFreeNotification(Self);
  FData := AValue;
  if Assigned(FData) then
    FData.FreeNotification(Self);
end;

procedure TFPReportCustomPage.SetColumnLayout(AValue: TFPReportColumnLayout);
begin
  if FColumnLayout = AValue then
    Exit;
  FColumnLayout := AValue;
end;

procedure TFPReportCustomPage.SetColumnCount(AValue: Byte);
begin
  if FColumnCount = AValue then
    Exit;
  if AValue < 1 then
    FColumnCount := 1
  else
    FColumnCount := AValue;
  RecalcLayout;
end;

procedure TFPReportCustomPage.SetColumnGap(AValue: TFPReportUnits);
begin
  if FColumnGap = AValue then
    Exit;
  if AValue < 0 then
    FColumnGap := 0
  else
    FColumnGap := AValue;
  RecalcLayout;
end;

function TFPReportCustomPage.GetReportPage: TFPReportCustomPage;
begin
  Result := nil;
end;

function TFPReportCustomPage.GetReportBand: TFPReportCustomBand;
begin
  Result := nil;
end;

procedure TFPReportCustomPage.SaveDataToNames;
begin
  inherited ;
  If Assigned(Data) then
    FDataName:=Data.Name;
end;

procedure TFPReportCustomPage.RestoreDataFromNames;
begin
  Inherited;
  if FDataName<>'' then
    Data:=Report.ReportData.FindReportData(FDataName)
  else
    Data:=Nil;
end;

procedure TFPReportCustomPage.RemoveChild(const AChild: TFPReportElement);
begin
  inherited RemoveChild(AChild);
  if (AChild is TFPReportCustomBand) and Assigned(FBands) then
  begin
    FBands.Remove(AChild);
    if (FBands.Count = 0) then
      FreeAndNil(FBands);
  end;
end;

procedure TFPReportCustomPage.AddChild(const AChild: TFPReportElement);
var
  lBand: TFPReportCustomBand;
begin
  inherited AddChild(AChild);
  if (AChild is TFPReportCustomBand) then
  begin
    lBand := TFPReportCustomBand(AChild);
    if not Assigned(FBands) then
      FBands := TFPList.Create;
    FBands.Add(lBand);
    ApplyBandWidth(lBand);
    if (AChild is TFPReportCustomBandWithData) then
      TFPReportCustomBandWithData(AChild).Data := self.Data;
  end;
end;

procedure TFPReportCustomPage.RecalcLayout;
var
  W, H: TFPReportunits;
  b: integer;
begin
  if (Pagesize.Width = 0) and (Pagesize.Height = 0) then
    Exit;
  case Orientation of
    poPortrait:
    begin
      W := PageSize.Width;
      H := PageSize.Height;
    end;
    poLandscape:
    begin
      W := PageSize.Height;
      H := PageSize.Width;
    end;
  end;
  BeginUpdate;
  try
    Layout.Left := Margins.Left;
    Layout.Width := W - Margins.Left - Margins.Right;
    Layout.Top := Margins.Top;
    Layout.Height := H - Margins.Top - Margins.Bottom;

    for b := 0 to BandCount-1 do
      ApplyBandWidth(Bands[b]);
  finally
    EndUpdate;
  end;
end;

procedure TFPReportCustomPage.CalcPrintPosition;
var
  i: integer;
  b: TFPReportCustomBand;
  ly: TFPReportUnits;
begin
  if not Assigned(RTLayout) then
    exit;
  ly := Layout.Top;
  for i := 0 to BandCount - 1 do
  begin
    b := Bands[i];
    b.RTLayout.Top := ly;
    ly := ly + b.Layout.Height;
  end;
end;

procedure TFPReportCustomPage.PrepareObjects;
var
  lPage: TFPReportCustomPage;
begin
  lPage := TFPReportCustomPage.Create(nil);
  lPage.Assign(self);
  lPage.CreateRTLayout;
  Report.FRTCurPageIdx := Report.RTObjects.Add(lPage);
end;

procedure TFPReportCustomPage.MarginsChanged;
begin
  RecalcLayout;
end;

procedure TFPReportCustomPage.PageSizeChanged;
begin
  RecalcLayout;
end;

constructor TFPReportCustomPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TFPReportMargins.Create(Self);
  FPageSize := TFPReportPageSize.Create(Self);
  if AOwner is TFPCustomReport then
    Report := AOwner as TFPCustomReport;
  FColumnCount := 1;
  FColumnLayout := clVertical;
  FFont := TFPReportFont.Create;
end;

destructor TFPReportCustomPage.Destroy;
begin
  Report := nil;
  FreeAndNil(FMargins);
  FreeAndNil(FPageSize);
  FreeAndNil(FBands);
  FreeAndNil(FFont);
  inherited Destroy;
end;

procedure TFPReportCustomPage.Assign(Source: TPersistent);
var
  E: TFPReportCustomPage;
begin
  if (Source is TFPReportCustomPage) then
  begin
    E := Source as TFPReportCustomPage;
    PageSize.Assign(E.PageSize);
    Orientation := E.Orientation;
    Report := E.Report;
    Font.Assign(E.Font);
  end;
  inherited Assign(Source);
end;

procedure TFPReportCustomPage.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
begin
  inherited ReadElement(AReader);
  E := AReader.FindChild('Margins');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      FMargins.ReadElement(AReader);
    finally
      AReader.PopElement;
    end;
  end;
  Orientation := StringToPaperOrientation(AReader.ReadString('Orientation', 'poPortrait'));
  Pagesize.PaperName := AReader.ReadString('PageSize.PaperName', 'A4');
  Pagesize.Width := AReader.ReadFloat('PageSize.Width', 210);
  Pagesize.Height := AReader.ReadFloat('PageSize.Height', 297);
  Font.Name := AReader.ReadString('FontName', Font.Name);
  Font.Size := AReader.ReadInteger('FontSize', Font.Size);
  Font.Color := AReader.ReadInteger('FontColor', Font.Color);
  FDataName:=AReader.ReadString('Data','');
  if FDataName<>'' then
    RestoreDataFromNames;
end;

function TFPReportCustomPage.FindBand(ABand: TFPReportBandClass): TFPReportCustomBand;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to BandCount-1 do
  begin
    if Bands[i] is ABand then
    begin
      Result := Bands[i];
      Break;
    end;
  end;
end;

procedure TFPReportCustomPage.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) then
    if (AComponent = FReport) then
      FReport := nil
    else if (AComponent = FData) then
      FData := nil;
  inherited Notification(AComponent, Operation);
end;

procedure TFPReportCustomPage.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteString('Orientation', PaperOrientationToString(Orientation));
  AWriter.WriteString('PageSize.PaperName', PageSize.PaperName);
  AWriter.WriteFloat('PageSize.Width', PageSize.Width);
  AWriter.WriteFloat('PageSize.Height', PageSize.Height);
  AWriter.WriteString('FontName', Font.Name);
  AWriter.WriteInteger('FontSize', Font.Size);
  AWriter.WriteInteger('FontColor', Font.Color);
  if Assigned(FData) then
    AWriter.WriteString('Data',FData.Name);
  AWriter.PushElement('Margins');
  try
    FMargins.WriteElement(AWriter, nil);
  finally
    AWriter.PopElement;
  end;
end;

function TFPReportCustomPage.PageIndex: Integer;
begin
  Result:=-1;
  If (Owner<>Nil) then
    Result:=ComponentIndex;
end;

function TFPReportCustomPage.GetBand(AIndex: integer): TFPReportCustomBand;
begin
  if Assigned(FBands) then
    Result := TFPReportCustomBand(FBands[AIndex]);
end;

function TFPReportCustomPage.GetBandCount: integer;
begin
  if Assigned(FBands) then
    Result := FBands.Count
  else
    Result := 0;
end;

function TFPReportCustomPage.BandWidthFromColumnCount: TFPReportUnits;
var
  lTotalColumnGap: TFPReportUnits;
begin
  if ColumnCount = 1 then
    Result := Layout.Width
  else
  begin
    if ColumnGap > 0.0 then
      lTotalColumnGap := ColumnGap * (ColumnCount-1)
    else
      lTotalColumnGap := 0.0;
    Result := (1 / ColumnCount) * (Layout.Width - lTotalColumnGap);
  end;
end;

procedure TFPReportCustomPage.ApplyBandWidth(ABand: TFPReportCustomBand);
begin
  { set Band Width appropriately - certain bands are not affected by ColumnCount }
  if (ABand is TFPReportCustomTitleBand)
      or (ABand is TFPReportCustomSummaryBand)
      or (ABand is TFPReportCustomPageHeaderBand)
      or (ABand is TFPReportCustomPageFooterBand) then
    ABand.Layout.Width := Layout.Width
  else
    ABand.Layout.Width := BandWidthFromColumnCount;
end;

procedure TFPReportCustomPage.SetFont(AValue: TFPReportFont);
begin
  if Assigned(FFont) then
    FreeAndNil(FFont);
  FFont := AValue;
  Changed;
end;

procedure TFPReportCustomPage.SetMargins(const AValue: TFPReportMargins);
begin
  if FMargins = AValue then
    Exit;
  FMargins.Assign(AValue);
end;

procedure TFPReportCustomPage.SetOrientation(const AValue: TFPReportPaperOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  RecalcLayout;
end;

procedure TFPReportCustomPage.SetPageSize(const AValue: TFPReportPageSize);
begin
  if FPageSize = AValue then
    Exit;
  FPageSize.Assign(AValue);
end;

{ TFPCustomReport }

function TFPCustomReport.GetPage(AIndex: integer): TFPReportCustomPage;
begin
  if Assigned(FPages) then
    Result := TFPReportCustomPage(FPages[AIndex])
  else
    ReportError(SErrInValidPageIndex, [AIndex]);
end;

function TFPCustomReport.GetPageCount: integer;
begin
  if Assigned(FPages) then
    Result := FPages.Count
  else
    Result := 0;
end;

function TFPCustomReport.GetRenderedPageCount: integer;
var
  i: integer;
begin
  Result := 0;
  for i := Low(FPerDesignerPageCount) to High(FPerDesignerPageCount) do
    inc(Result, FPerDesignerPageCount[i]);
end;

procedure TFPCustomReport.BuiltinExprRecNo(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.ResInteger := FPageData.RecNo;
end;

procedure TFPCustomReport.BuiltinGetPageNumber(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.ResInteger := FPageNumber;
end;

procedure TFPCustomReport.BuiltinGetPageNoPerDesignerPage(var Result: TFPExpressionResult;
  const Args: TExprParameterArray);
begin
  Result.ResInteger := FPageNumberPerDesignerPage;
end;

procedure TFPCustomReport.BuiltinGetPageCount(var Result: TFPExpressionResult; const Args: TExprParameterArray);
begin
  Result.ResInteger := FPageCount;
end;

procedure TFPCustomReport.RecalcBandLayout(ABand: TFPReportCustomBand);
var
  i: integer;
  e: TFPReportElement;
begin
  for i := ABand.ChildCount-1 downto 0 do
  begin
    e := ABand.Child[i];
    if not e.EvaluateVisibility then
    begin
      ABand.RemoveChild(e);
      FreeAndNil(e);
    end;
  end;
end;

procedure TFPCustomReport.EmptyRTObjects;
begin
  while RTObjects.Count > 0 do
  begin
    TFPReportElement(RTObjects[0]).Free;
    RTObjects.Delete(0);
  end;
end;

procedure TFPCustomReport.ClearDataBandLastTextValues(ABand: TFPReportCustomBandWithData);
var
  i: integer;
  m: TFPReportCustomMemo;
begin
  for i := 0 to ABand.ChildCount-1 do
  begin
    if ABand.Child[i] is TFPReportCustomMemo then
    begin
      m := TFPReportCustomMemo(ABand.Child[i]);
      m.FLastText := '';
    end;
  end;
end;

procedure TFPCustomReport.ProcessAggregates(const APageIdx: integer; const AData: TFPReportData);
var
  b: integer;
  c: integer;
  i: integer;
  m: TFPReportCustomMemo;
begin
  for b := 0 to Pages[APageIdx].BandCount-1 do
  begin
    if Pages[APageIdx].Bands[b] is TFPReportCustomBandWithData then
    begin
      if TFPReportCustomBandWithData(Pages[APageIdx].Bands[b]).Data <> AData then
        Continue;  // band is from a different data-loop
    end;
    for c := 0 to Pages[APageIdx].Bands[b].ChildCount-1 do
      if Pages[APageIdx].Bands[b].Child[c] is TFPReportCustomMemo then
      begin
        m := TFPReportCustomMemo(Pages[APageIdx].Bands[b].Child[c]);
        for i := 0 to Length(m.ExpressionNodes)-1 do
        begin
          if Assigned(m.ExpressionNodes[i].ExprNode) then
          begin
            if m.ExpressionNodes[i].ExprNode.HasAggregate then
              m.ExpressionNodes[i].ExprNode.UpdateAggregate;
          end;
        end;  { for ... }
      end; { children of band }
  end; { bands }
end;

procedure TFPCustomReport.ClearReferenceList;
begin
  if not Assigned(FReferenceList) then
    FReferenceList := TStringList.Create
  else
    FReferenceList.Clear;
end;

procedure TFPCustomReport.AddReference(const AParentName, AChildName: string);
begin
  FReferenceList.Values[AParentName] := AChildName;
end;

procedure TFPCustomReport.FixupReferences;
var
  i: integer;
  p: TFPReportElement;
  c: TFPReportElement;
begin
  if FReferenceList.Count = 1 then
    Exit;
  for i := 0 to FReferenceList.Count-1 do
  begin
    p := FindRecursive(FReferenceList.Names[i]);
    if not Assigned(p) then
      Continue; // failded to find the Parent
    c := FindRecursive(FReferenceList.ValueFromIndex[i]);
    if not Assigned(c) then
      Continue; // failded to find the Child
    if not (c is TFPReportCustomChildBand) then
      Continue; // wrong type - unexpected
    if p is TFPReportCustomBand then
      TFPReportCustomBand(p).ChildBand := TFPReportChildBand(c)
    else if p is TFPReportCustomChildBand then
      TFPReportCustomChildBand(p).ChildBand := TFPReportChildBand(c);
  end;
end;

procedure TFPCustomReport.DoBeforeRenderReport;
begin
  if Assigned(FOnBeforeRenderReport) then
    FOnBeforeRenderReport(self);
end;

procedure TFPCustomReport.DoAfterRenderReport;
begin
  if Assigned(FOnAfterRenderReport) then
    FOnAfterRenderReport(self);
end;

procedure TFPCustomReport.DoProcessTwoPass;
var
  p, b, m: integer; // page, band, memo
  i: integer;
  rpage: TFPReportCustomPage;
  rband: TFPReportCustomBand;
  rmemo: TFPReportCustomMemo;
  txtblk: TFPTextBlock;
begin
  for p := 0 to RTObjects.Count-1 do  // page
  begin
    rpage := TFPReportPage(RTObjects[p]);
    for b := 0 to rpage.BandCount-1 do
    begin
      rband := rpage.Bands[b];
      for m := 0 to rband.ChildCount-1 do // band
      begin
        if rband.Child[m] is TFPReportCustomMemo then // memo
        begin
          rmemo := TFPReportCustomMemo(rband.Child[m]);
          for i := 0 to rmemo.TextBlockList.Count-1 do
          begin
            txtblk := rmemo.TextBlockList[i];
            txtblk.Text := StringReplace(txtblk.Text, cPageCountMarker, IntToStr(FPageCount), [rfReplaceAll, rfIgnoreCase]);
          end;
        end;
      end; { m }
    end; { b }
  end;
end;

procedure TFPCustomReport.DoGetExpressionVariableValue(var Result: TFPExpressionResult; constref AName: ShortString);
var
  p: integer;
  b: integer;
  lBand: TFPReportCustomDataBand;
  lDataName: string;
  lFieldName: string;
  lField: TFPReportDataField;

  procedure SetResultValue(const AData: TFPReportData);
  begin
    case FExpr.Identifiers.FindIdentifier(AName).ResultType of
      rtBoolean:    Result.ResBoolean   := AData.FieldValues[lFieldName];
      rtInteger:    Result.ResInteger   := AData.FieldValues[lFieldName];
      rtFloat:      Result.ResFloat     := AData.FieldValues[lFieldName];
      rtDateTime:   Result.ResDateTime  := AData.FieldValues[lFieldName];
      rtString:     Result.ResString    := AData.FieldValues[lFieldName];
    end;
  end;

begin
  {$ifdef gdebug}
  writeln('TFPCustomReport.DoGetExpressionVariableValue():  AName = ' + AName);
  {$endif}
  Result.ResString := '';
  lDataName := '';
  lFieldName := AName;
  lField := nil;
  p := Pos('.', lFieldName);
  if p > 0 then
  begin
    lDataName := Copy(AName, 1, p-1);
    lFieldName := Copy(AName, p+1, Length(AName));
  end;

  { look for data bands }
  for p := 0 to PageCount-1 do
  begin
    for b := 0 to Pages[p].BandCount-1 do
    begin
      if Pages[p].Bands[b] is TFPReportCustomDataBand then
      begin
        lBand := TFPReportCustomDataBand(Pages[p].Bands[b]);
        if (lDataName = '') then // try every databand
        begin
          lField := lBand.Data.DataFields.FindField(lFieldName);
        end
        else
        begin // try only databands where Name is a match
          if lBand.Data.Name = lDataName then
            lField := lBand.Data.DataFields.FindField(lFieldName);
        end;
        if lField <> nil then
        begin
          SetResultValue(lBand.Data);
          Exit;
        end;
      end; { databand types only }
    end; { band count }
  end; { page count }
end;

procedure TFPCustomReport.SetReportData(AValue: TFPReportDataCollection);
begin
  if FReportData=AValue then Exit;
  FReportData.Assign(AValue);
end;

procedure TFPCustomReport.SetVariables(AValue: TFPReportVariables);
begin
  if FVariables=AValue then Exit;
  FVariables.Assign(AValue);
end;

procedure TFPCustomReport.DoPrepareReport;
var
  lPageIdx: integer;
  b: integer;
  s: string;
  lNewPage: boolean;  // indicates if a new ReportPage needs to be created - used if DataBand spans multiple pages for example
  lNewColumn: boolean;
  lNewGroupHeader: boolean;
  lDsgnBand: TFPReportCustomBand;
  lLastDsgnDataBand: TFPReportCustomDataBand;
  lRTPage: TFPReportCustomPage;
  lRTBand: TFPReportCustomBand;
  lSpaceLeft: TFPReportUnits;
  lLastYPos: TFPReportUnits;
  lLastXPos: TFPReportUnits;
  lPageFooterYPos: TFPReportUnits;
  lOverflowed: boolean;
  lLastGroupCondition: string;
  lFoundDataBand: boolean;
  lHasGroupBand: boolean;
  lHasGroupFooter: boolean;
  lHasReportSummaryBand: boolean;
  lDataHeaderPrinted: boolean;
  lCurrentColumn: UInt8;
  lMultiColumn: boolean;
  lHeaderList: TBandList;
  lFooterList: TBandList;
  lNewRTColumnFooterBand: TFPReportCustomColumnFooterBand;
  lDataLevelStack: UInt8;
  lPassCount: UInt8;
  lPassIdx: UInt8;

  procedure RemoveTitleBandFromHeaderList;
  var
    idx: integer;
    lBand: TFPReportCustomBand;
  begin
    idx := lHeaderList.Find(TFPReportCustomTitleBand, lBand);
    if idx > -1 then
      lHeaderList.Delete(idx);
  end;

  procedure RemoveColumnFooterFromFooterList;
  var
    idx: integer;
    lBand: TFPReportCustomBand;
  begin
    idx := lFooterList.Find(TFPReportCustomColumnFooterBand, lBand);
    if idx > -1 then
      lFooterList.Delete(idx);
  end;

  procedure UpdateSpaceRemaining(const ABand: TFPReportCustomBand; const AUpdateYPos: boolean = True);
  begin
    lSpaceLeft := lSpaceLeft - ABand.RTLayout.Height;
    if AUpdateYPos then
      lLastYPos := lLastYPos + ABand.RTLayout.Height;
  end;

  procedure CommonRuntimeBandProcessing(const ADsgnBand: TFPReportCustomBand);
  begin
    ADsgnBand.PrepareObjects;
    lRTBand := FRTCurBand;
    lRTBand.RecalcLayout;
    lRTBand.BeforePrint;
    lRTBand.RTLayout.Top := lLastYPos;
    lRTBand.RTLayout.Left := lLastXPos;
  end;

  { Result of True means ADsgnBand must be skipped. Result of False means ADsgnBand
    must be rendered (ie: not skipped).  }
  function DoVisibleOnPageChecks(const ADsgnBand: TFPReportCustomBand): boolean;
  begin
    Result := True;
    if ADsgnBand.VisibleOnPage = vpAll then
    begin
      // do nothing special
    end
    else if (FPageNumberPerDesignerPage = 1) then
    begin // first page rules
      if (ADsgnBand.VisibleOnPage in [vpFirstOnly, vpFirstAndLastOnly]) then
      begin
        // do nothing special
      end
      else if (ADsgnBand.VisibleOnPage in [vpNotOnFirst, vpLastOnly, vpNotOnFirstAndLast]) then
        Exit; // user asked to skip this band
    end
    else if (FPageNumberPerDesignerPage > 1) then
    begin  // multi-page rules
      if ADsgnBand.VisibleOnPage in [vpFirstOnly] then
        Exit  // user asked to skip this band
      else if ADsgnBand.VisibleOnPage in [vpNotOnFirst] then
      begin
        // do nothing special
      end
      else if (not IsFirstPass) then
      begin // last page rules
        if (ADsgnBand.VisibleOnPage in [vpLastOnly, vpFirstAndLastOnly]) and (FPageNumberPerDesignerPage < FPerDesignerPageCount[lPageIdx]) then
          Exit
        else if (ADsgnBand.VisibleOnPage in [vpNotOnLast, vpFirstOnly, vpNotOnFirstAndLast]) and (FPageNumberPerDesignerPage = FPerDesignerPageCount[lPageIdx]) then
          Exit; // user asked to skip this band
      end;
    end;
    Result := False;
  end;

  { Result of True means ADsgnBand must be skipped. Result of False means ADsgnBand
    must be rendered (ie: not skipped).  }
  function ShowPageHeaderBand(const ADsgnBand: TFPReportCustomBand): boolean;
  begin
    Result := True;
    if not (ADsgnBand is TFPReportCustomPageHeaderBand) then
      Exit;

    if DoVisibleOnPageChecks(ADsgnBand as TFPReportCustomPageHeaderBand) then
      Exit;

    CommonRuntimeBandProcessing(ADsgnBand);
    Result := False;
  end;

  function ShowColumnHeaderBand(const ADsgnBand: TFPReportCustomBand): boolean;
  var
    lBand: TFPReportCustomBand;
  begin
    Result := False;
    CommonRuntimeBandProcessing(ADsgnBand);
    { Only once we show the first column header do we take into account
      the column footer. }
    lBand := Pages[lPageIdx].FindBand(TFPReportCustomColumnFooterBand);
    lFooterList.Add(lBand);
    if Assigned(lBand) then
      lSpaceLeft := lSpaceLeft - lBand.Layout.Height;
  end;

  function LayoutColumnFooterBand(APage: TFPReportCustomPage; ABand: TFPReportCustomColumnFooterBand): TFPReportCustomColumnFooterBand;
  var
    lBandCount: integer;
    lOverflowBand: TFPReportCustomBand;
  begin
    lBandCount := lRTPage.BandCount - 1;
    lOverflowBand := lRTPage.Bands[lBandCount]; { store reference to band that caused the new column }

    CommonRuntimeBandProcessing(ABand);
    Result := TFPReportCustomColumnFooterBand(lRTBand);

    if lPageFooterYPos = -1 then
      lRTBand.RTLayout.Top := (APage.RTLayout.Top + APage.RTLayout.Height) - lRTBand.RTLayout.Height
    else
      lRTBand.RTLayout.Top := lPageFooterYPos - lRTBand.RTLayout.Height;
    if Result.FooterPosition = fpAfterLast then
    begin
      if lNewColumn or lOverflowed then
        { take height of overflowed band into account }
        lRTBand.RTLayout.Top := lLastYPos - lOverflowBand.RTLayout.Height
      else
        lRTBand.RTLayout.Top := lLastYPos;
    end;
  end;

  function NoSpaceRemaining: boolean;
  begin
    if lSpaceLeft <= 0 then
    begin
      Result := True;
      if lMultiColumn and (lCurrentColumn < Pages[lPageIdx].ColumnCount) then
      begin
        lNewColumn := True;
      end
      else
      begin
        lOverflowed := True;
        lNewPage := True;
      end;
    end
    else
      Result := False;
  end;

  procedure StartNewColumn;
  var
    lIdx: integer;
    lBandCount: integer;
    lBand: TFPReportCustomBand;
    lOverflowBand: TFPReportCustomBand;
  begin
    if Assigned(lLastDsgnDataBand) then
      ClearDataBandLastTextValues(lLastDsgnDataBand);

    if lMultiColumn and (lFooterList.Find(TFPReportCustomColumnFooterBand) <> nil) then
      lBandCount := lRTPage.BandCount - 2  // skip over the ColumnFooter band
    else
      lBandCount := lRTPage.BandCount - 1;
    lOverflowBand := lRTPage.Bands[lBandCount]; { store reference to band that caused the new column }
    lSpaceLeft := Pages[lPageIdx].Layout.Height; // original designer page
    lRTPage := TFPReportCustomPage(RTObjects[FRTCurPageIdx]);

    lLastYPos := lRTPage.RTLayout.Top;
    lLastXPos := lLastXPos + lOverflowBand.RTLayout.Width + Pages[lPageIdx].ColumnGap;

    { Adjust starting Y-Pos based on bands in lHeaderList. }
    for lIdx := 0 to lHeaderList.Count-1 do
    begin
      lBand := lHeaderList[lIdx];

      if lBand is TFPReportCustomPageHeaderBand then
      begin
        if DoVisibleOnPageChecks(lBand) then
          Continue;
      end
      else if lBand is TFPReportCustomColumnHeaderBand then
      begin
        if ShowColumnHeaderBand(lBand) then
          Continue;
      end;

      lSpaceLeft := lSpaceLeft - lBand.Layout.Height;
      lLastYPos := lLastYPos + lBand.Layout.Height;
    end;

    inc(lCurrentColumn);

    { If footer band exists, reduce available space }
    lBand := lRTPage.FindBand(TFPReportCustomPageFooterBand);
    if Assigned(lBand) then
      UpdateSpaceRemaining(lBand, False);

    if NoSpaceRemaining then
      Exit;

    { Fix position of last band that caused the new column }
    lOverflowBand.RTLayout.Left := lLastXPos;
    lOverflowBand.RTLayout.Top := lLastYPos;
    { Adjust the next starting point of the next data band. }
    UpdateSpaceRemaining(lOverflowBand);

    lNewColumn := False;
  end;

  procedure HandleOverflowed;
  var
    lPrevRTPage: TFPReportCustomPage;
    lOverflowBand: TFPReportCustomBand;
    lBandCount: integer;
  begin
    lOverflowed := False;
    lPrevRTPage := TFPReportCustomPage(RTObjects[FRTCurPageIdx-1]);
    if lMultiColumn and (lFooterList.Find(TFPReportCustomColumnFooterBand) <> nil) then
      lBandCount := lPrevRTPage.BandCount - 2  // skip over the ColumnFooter band
    else
      lBandCount := lPrevRTPage.BandCount - 1;
    lOverflowBand := lPrevRTPage.Bands[lBandCount]; // get the last band - the one that didn't fit
    lPrevRTPage.RemoveChild(lOverflowBand);
    lRTPage.AddChild(lOverflowBand);

    { Fix position of last band that caused the overflow }
    lOverflowBand.RTLayout.Top := lLastYPos;
    lOverflowBand.RTLayout.Left := lLastXPos;
    UpdateSpaceRemaining(lOverflowBand);
  end;

  procedure LayoutFooterBand;
  var
    lBand: TFPReportCustomPageFooterBand;
  begin
    lPageFooterYPos := -1;
    if not (lDsgnBand is TFPReportCustomPageFooterBand) then
      Exit;

    lBand := TFPReportCustomPageFooterBand(lDsgnBand);
    if DoVisibleOnPageChecks(lBand) then
      Exit;

    lDsgnBand.PrepareObjects;
    lRTBand := FRTCurBand;
    lRTBand.RecalcLayout;
    lRTBand.BeforePrint;
    lRTBand.RTLayout.Top := (lRTPage.RTLayout.Top + lRTPage.RTLayout.Height) - lRTBand.RTLayout.Height;
    lPageFooterYPos := lRTBand.RTLayout.Top;
    // We don't adjust lLastYPos because this is a page footer
    UpdateSpaceRemaining(lRTBand, False);
  end;

  procedure PopulateHeaderList(APage: TFPReportCustomPage);
  begin
    lHeaderList.Clear;
    lHeaderList.Add(APage.FindBand(TFPReportCustomPageHeaderBand));
    lHeaderList.Add(APage.FindBand(TFPReportCustomTitleBand));
    if lMultiColumn then
      lHeaderList.Add(Pages[lPageIdx].FindBand(TFPReportColumnHeaderBand));
  end;

  procedure PopulateFooterList(APage: TFPReportCustomPage);
  begin
    lFooterList.Clear;
    lFooterList.Add(APage.FindBand(TFPReportCustomPageFooterBand));
  end;

  procedure StartNewPage;
  var
    lIdx: integer;
  begin
    if Assigned(lLastDsgnDataBand) then
      ClearDataBandLastTextValues(lLastDsgnDataBand);
    lSpaceLeft := Pages[lPageIdx].Layout.Height; // original designer page
    Pages[lPageIdx].PrepareObjects;  // creates a new page object
    FRTCurPageIdx := RTObjects.Count-1;
    lRTPage := TFPReportCustomPage(RTObjects[FRTCurPageIdx]);
    lLastYPos := lRTPage.RTLayout.Top;
    lLastXPos := lRTPage.RTLayout.Left;
    Inc(FPageNumber);
    lCurrentColumn := 1;
    lNewColumn := False;

    if IsFirstPass then
      FPerDesignerPageCount[lPageIdx] := FPerDesignerPageCount[lPageIdx] + 1;

    if (FPageNumberPerDesignerPage = 1) then
      RemoveTitleBandFromHeaderList;
    inc(FPageNumberPerDesignerPage);

    { Show all header bands }
    for lIdx := 0 to lHeaderList.Count - 1 do
    begin
      lDsgnBand := lHeaderList[lIdx];
      if lDsgnBand is TFPReportCustomPageHeaderBand then
      begin
        if ShowPageHeaderBand(lDsgnBand) then
          Continue;
      end
      else if lDsgnBand is TFPReportCustomColumnHeaderBand then
      begin
        if ShowColumnHeaderBand(lDsgnBand) then
          Continue;
      end
      else
        CommonRuntimeBandProcessing(lDsgnBand);
      UpdateSpaceRemaining(lRTBand);
    end;

    { Show footer band if it exists }
    lDsgnBand := lFooterList.Find(TFPReportCustomPageFooterBand);
    if Assigned(lDsgnBand) then
      LayoutFooterBand;

    lNewPage := False;
  end;

  procedure ShowDataBand(const ADsgnBand: TFPReportCustomDataBand);
  var
    lDsgnChildBand: TFPReportChildBand;
    lLastDataBand: TFPReportCustomBand;
  begin
    lLastDsgnDataBand := ADsgnBand;
    CommonRuntimeBandProcessing(ADsgnBand);
    if lRTBand.EvaluateVisibility then
    begin
      lLastDataBand := lRTBand;
      RecalcBandLayout(lRTBand);
      UpdateSpaceRemaining(lRTBand);
      if NoSpaceRemaining then
      begin
        { Process ColumnFooterBand as needed }
        if lMultiColumn then
        begin
          lNewRTColumnFooterBand := TFPReportCustomColumnFooterBand(lFooterList.Find(TFPReportCustomColumnFooterBand));
          if Assigned(lNewRTColumnFooterBand) then
            LayoutColumnFooterBand(lRTPage, lNewRTColumnFooterBand);
        end;

        if lNewColumn then
          StartNewColumn;

        if lNewPage then
          StartNewPage;

        { handle overflowed bands. Remove from old page, add to new page }
        if lOverflowed then
          HandleOverflowed;
      end;
      { process any child bands off of DataBand }
      lDsgnChildBand := lLastDataBand.ChildBand;
      while lDsgnChildBand <> nil do
      begin
        CommonRuntimeBandProcessing(lDsgnChildBand);
        if lRTBand.EvaluateVisibility then
        begin
          RecalcBandLayout(lRTBand);
          UpdateSpaceRemaining(lRTBand);
          if NoSpaceRemaining then
          begin
            { Process ColumnFooterBand as needed }
            if lMultiColumn then
            begin
              lNewRTColumnFooterBand := TFPReportCustomColumnFooterBand(lFooterList.Find(TFPReportCustomColumnFooterBand));
              if Assigned(lNewRTColumnFooterBand) then
                LayoutColumnFooterBand(lRTPage, lNewRTColumnFooterBand);
            end;

            if lNewColumn then
              StartNewColumn;

            if lNewPage then
              StartNewPage;

            { handle overflowed bands. Remove from old page, add to new page }
            if lOverflowed then
              HandleOverflowed;
          end;
        end
        else
        begin
          // remove invisible band
          lRTPage.RemoveChild(lRTBand);
          FreeAndNil(lRTBand);
        end;
        lDsgnChildBand := lDsgnChildBand.ChildBand;
      end;  { while ChildBand <> nil }
    end
    else
    begin
      // remove invisible band
      lRTPage.RemoveChild(lRTBand);
      FreeAndNil(lRTBand);
    end;
  end;

  procedure ShowDataHeaderBand(const ADsgnBand: TFPReportCustomDataHeaderBand);
  begin
    if lDataHeaderPrinted then
      Exit; // nothing further to do

    CommonRuntimeBandProcessing(ADsgnBand);
    if lRTBand.EvaluateVisibility then
    begin
      lDataHeaderPrinted := True;
      UpdateSpaceRemaining(lRTBand);
      if NoSpaceRemaining then
      begin
        { Process ColumnFooterBand as needed }
        if lMultiColumn then
        begin
          lNewRTColumnFooterBand := TFPReportCustomColumnFooterBand(lFooterList.Find(TFPReportCustomColumnFooterBand));
          if Assigned(lNewRTColumnFooterBand) then
            LayoutColumnFooterBand(lRTPage, lNewRTColumnFooterBand);
        end;

        if lNewColumn then
          StartNewColumn;

        if lNewPage then
          StartNewPage;

        { handle overflowed bands. Remove from old page, add to new page }
        if lOverflowed then
          HandleOverflowed;
      end; { no space remaining }
    end
    else
    begin
      // remove invisible band
      lRTPage.RemoveChild(lRTBand);
      FreeAndNil(lRTBand);
    end;
  end;

  procedure ShowDataFooterBand(const ADsgnBand: TFPReportCustomDataFooterBand);
  begin
    CommonRuntimeBandProcessing(ADsgnBand);
    if lRTBand.EvaluateVisibility then
    begin
      UpdateSpaceRemaining(lRTBand);
      if NoSpaceRemaining then
      begin
        if lNewPage then
          StartNewPage;

        { handle overflowed bands. Remove from old page, add to new page }
        if lOverflowed then
          HandleOverflowed;
      end; { no space remaining }
    end
    else
    begin
      // remove invisible band
      lRTPage.RemoveChild(lRTBand);
      FreeAndNil(lRTBand);
    end;
  end;

  procedure ShowDetailBand(const AMasterBand: TFPReportCustomDataBand);
  var
    lDsgnDetailBand: TFPReportCustomDataBand;
    lDetailBandList: TBandList;
    lDetailBand: TFPReportCustomBand;
    lData: TFPReportData;
    i: integer;
  begin
    if AMasterBand = nil then
      Exit;
    lDsgnDetailBand := nil;
    lDetailBandList := TBandList.Create;
    try
      { collect bands of interest }
      for i := 0 to Pages[lPageIdx].BandCount-1 do
      begin
        lDetailBand := Pages[lPageIdx].Bands[i];
        if (lDetailBand is TFPReportCustomDataBand)
          and (TFPReportCustomDataBand(lDetailBand).MasterBand = AMasterBand)
          and (TFPReportCustomDataBand(lDetailBand).Data <> nil) then
            lDetailBandList.Add(lDetailBand);
      end;
      if lDetailBandList.Count = 0 then
        exit;  // nothing further to do
      lDetailBandList.Sort(@SortDataBands);

      { process Detail bands }
      for i := 0 to lDetailBandList.Count-1 do
      begin
        lDsgnDetailBand := TFPReportCustomDataBand(lDetailBandList[i]);
        lData := lDsgnDetailBand.Data;
        if not lData.IsOpened then
        begin
          lData.Open;
          InitializeExpressionVariables(lData);
          CacheMemoExpressions(lPageIdx, lData);
        end;
        lData.First;

        if (not lData.EOF) and (lDsgnDetailBand.HeaderBand <> nil) then
          ShowDataHeaderBand(lDsgnDetailBand.HeaderBand);
        while not lData.EOF do
        begin
          ProcessAggregates(lPageIdx, lData);
          inc(lDataLevelStack);
          ShowDataBand(lDsgnDetailBand);
          ShowDetailBand(lDsgnDetailBand);
          dec(lDataLevelStack);
         lData.Next;
        end;  { while not lData.EOF }
        lDataHeaderPrinted := False;

        if lNewPage then
          StartNewPage;

        { handle overflowed bands. Remove from old page, add to new page }
        if lOverflowed then
          HandleOverflowed;

        // only print if we actually had data
        if (lData.RecNo > 1) and (lDsgnDetailBand.FooterBand <> nil) then
          ShowDataFooterBand(lDsgnDetailBand.FooterBand);

        lDsgnDetailBand := nil;
      end;
    finally
      lDetailBandList.Free;
    end;
  end;

begin
  EmptyRTObjects;
  lHeaderList := Nil;
  lFooterList := Nil;
  FBands := Nil;
  try
    lHeaderList := TBandList.Create;
    lFooterList := TBandList.Create;
    FBands := TBandList.Create;
    SetLength(FPerDesignerPageCount, PageCount);



  if TwoPass then
    lPassCount := 2
  else
    lPassCount := 1;

  for lPassIdx := 1 to lPassCount do
  begin
    IsFirstPass := lPassIdx = 1;
    lHeaderList.Clear;
    lFooterList.Clear;
    FBands.Clear;
    FRTCurPageIdx := -1;
    lOverflowed := False;
    lHasGroupBand := False;
    lHasGroupFooter := False;
    lHasReportSummaryBand := False;
    lDataHeaderPrinted := False;
    lLastGroupCondition := '';
    FPageNumber := 0;
    FPageCount := 0;
    lDataLevelStack := 0;

  for lPageIdx := 0 to PageCount-1 do
  begin
    lNewPage := True;
    lNewGroupHeader := True;
    lCurrentColumn := 1;
    lMultiColumn := Pages[lPageIdx].ColumnCount > 1;
    lNewColumn := False;
    lPageFooterYPos := -1;
    FPageData := Pages[lPageIdx].Data;
    FPageNumberPerDesignerPage := 0;
    lFoundDataBand := False;
    lLastDsgnDataBand := nil;

    if Assigned(FPageData) then
    begin
      if not FPageData.IsOpened then
        FPageData.Open;
      InitializeExpressionVariables(FPageData);
      CacheMemoExpressions(lPageIdx, FPageData);

      FPageData.First;

      // Create a list of band that need to be printed as page headers
      PopulateHeaderList(Pages[lPageIdx]);

      // Create a list of bands that need to be printed as page footers
      PopulateFooterList(Pages[lPageIdx]);

      // find Bands of interest
      FBands.Clear;
      for b := 0 to Pages[lPageIdx].BandCount-1 do
      begin
        lDsgnBand := Pages[lPageIdx].Bands[b];
        if (lDsgnBand is TFPReportCustomDataBand) then
        begin
          if TFPReportCustomDataBand(lDsgnBand).Data = FPageData then
          begin
            { Do a quick sanity check - we may not have more than one master data band }
            if lFoundDataBand then
              ReportError(SErrMultipleDataBands);
            FBands.Add(lDsgnBand);
            lFoundDataBand := True;
          end
          else
            continue; // it's a databand but not for the current data loop
        end
        else
        begin
          if (lDsgnBand is TFPReportCustomGroupHeaderBand) and (TFPReportCustomGroupHeaderBand(lDsgnBand).GroupHeader <> nil) then
            continue; // this is not the toplevel GroupHeader Band.
          if lDsgnBand is TFPReportCustomGroupFooterBand then
            continue; // we will get the Footer from the GroupHeaderBand.FooterBand property
          FBands.Add(Pages[lPageIdx].Bands[b]);  { all non-data bands are of interest }
        end;

        if lDsgnBand is TFPReportCustomGroupHeaderBand then
        begin
          lHasGroupBand := True;
          if Assigned(TFPReportCustomGroupHeaderBand(lDsgnBand).GroupFooter) then
            lHasGroupFooter := True;
        end
        else if lDsgnBand is TFPReportCustomSummaryBand then
          lHasReportSummaryBand := True;
      end;

      while not FPageData.EOF do
      begin
        ProcessAggregates(lPageIdx, FPageData);

        if lNewColumn then
          StartNewColumn;

        if lNewPage then
          StartNewPage;

        { handle overflowed bands. Remove from old page, add to new page }
        if lOverflowed then
          HandleOverflowed;

        if lHasGroupBand then
        begin
          if lLastGroupCondition = '' then
            lNewGroupHeader := True
          else
          begin
            { Do GroupHeader evaluation }
            for b := 0 to FBands.Count-1 do
            begin
              lDsgnBand := TFPReportCustomBand(FBands[b]);
              { group header }
              if lDsgnBand is TFPReportCustomGroupHeaderBand then
              begin
                // Writeln('Found group with expr: ',TFPReportCustomGroupHeaderBand(lDsgnBand).GroupCondition);
                s := TFPReportCustomGroupHeaderBand(lDsgnBand).Evaluate;
                // Writeln('Group new ? "',lLastGroupCondition,'" <> "', s,'"');
                if (lLastGroupCondition <> s) then
                begin
                  lNewGroupHeader := True;
                  { process group footer }
                  if Assigned(TFPReportCustomGroupHeaderBand(lDsgnBand).GroupFooter) then
                  begin
                    lDsgnBand := TFPReportCustomGroupHeaderBand(lDsgnBand).GroupFooter;
                    CommonRuntimeBandProcessing(lDsgnBand);
                    UpdateSpaceRemaining(lRTBand);
                    if NoSpaceRemaining then
                      Break;
                  end; { group footer }
                end;
              end; { group header }
            end;  { bands for loop }
          end;  { if/else }

          if lNewGroupHeader then
          begin
            for b := 0 to FBands.Count-1 do
            begin
              lDsgnBand := TFPReportCustomBand(FBands[b]);
              { group header }
              if lDsgnBand is TFPReportCustomGroupHeaderBand then
              begin
                if Assigned(lLastDsgnDataBand) then
                  ClearDataBandLastTextValues(lLastDsgnDataBand);

                CommonRuntimeBandProcessing(lDsgnBand);
                lLastGroupCondition := TFPReportGroupHeaderBand(lRTBand).GroupConditionValue;
                if lDsgnBand.EvaluateVisibility = False then
                begin
                  lRTPage.RemoveChild(lRTBand);
                  lRTBand.Free;
                  Continue; // process next band
                end;
                UpdateSpaceRemaining(lRTBand);
                if NoSpaceRemaining then
                  Break;  { break out of FOR loop }
              end;
            end;
            lNewGroupHeader := False;
            lDataHeaderPrinted := False;
          end;  { lNewGroupHeader = True }
        end;  { if lHasGroupBand }

        { handle overflow possibly caused by Group Band just processed. }
        if lOverflowed then
          Continue;

        for b := 0 to FBands.Count-1 do
        begin
          lDsgnBand := TFPReportCustomBand(FBands[b]);

          { Process Master DataBand }
          if (lDsgnBand is TFPReportCustomDataBand) then
          begin
            inc(lDataLevelStack);
            if TFPReportCustomDataBand(lDsgnBand).HeaderBand <> nil then
              ShowDataHeaderBand(TFPReportCustomDataBand(lDsgnBand).HeaderBand);
            ShowDataBand(lDsgnBand as TFPReportCustomDataBand);
            ShowDetailBand(TFPReportCustomDataBand(lDsgnBand));
            dec(lDataLevelStack);
          end;
        end; { Bands for loop }

        FPageData.Next;
      end;  { while not FPageData.EOF }

      if lNewColumn then
        StartNewColumn;

      if lNewPage then
        StartNewPage;

      { handle overflowed bands. Remove from old page, add to new page }
      if lOverflowed then
        HandleOverflowed;

      // only print if we actually had data
      if (FPageData.RecNo > 1) then
      begin
        for b := 0 to FBands.Count-1 do
        begin
          lDsgnBand := TFPReportCustomBand(FBands[b]);
          if lDsgnBand is TFPReportCustomDataBand then
            if TFPReportCustomDataBand(lDsgnBand).FooterBand <> nil then
              ShowDataFooterBand(TFPReportCustomDataBand(lDsgnBand).FooterBand);
        end;
      end;

      { Process ColumnFooterBand as needed }
      if lMultiColumn then
      begin
        lNewRTColumnFooterBand := TFPReportCustomColumnFooterBand(lFooterList.Find(TFPReportCustomColumnFooterBand));
        if Assigned(lNewRTColumnFooterBand) then
        begin
          LayoutColumnFooterBand(lRTPage, lNewRTColumnFooterBand);
        end;
      end;

      { ColumnFooter could have caused a new column or page }
      if lNewColumn then
        StartNewColumn;

      if lNewPage then
        StartNewPage;

      { handle overflowed bands. Remove from old page, add to new page }
      if lOverflowed then
        HandleOverflowed;

      if lHasGroupFooter then
      begin
        for b := 0 to FBands.Count-1 do
        begin
          lDsgnBand := TFPReportCustomBand(FBands[b]);
          if lDsgnBand is TFPReportCustomGroupFooterBand then
          begin
            { We are allowed to use design Layout.Height instead of RTLayout.Height
              because this band appears outside the data loop, thus memos will not
              grow. Height of the band is as it was at design time. }
            if lDsgnBand.Layout.Height > lSpaceLeft then
              StartNewPage;
            CommonRuntimeBandProcessing(lDsgnBand);
            UpdateSpaceRemaining(lRTBand);
            Break;
          end;
        end; { for FBands }
      end;  { lHasGroupFooter }

      FPageData.Close;

    end;  { if Assigned(FPageData) }

    if lHasReportSummaryBand then
    begin
      for b := 0 to FBands.Count-1 do
      begin
        lDsgnBand := TFPReportCustomBand(FBands[b]);
        if lDsgnBand is TFPReportCustomSummaryBand then
        begin
          { We are allowed to use design Layout.Height instead of RTLayout.Height
            because this band appears outside the data loop, thus memos will not
            grow. Height of the band is as it was at design time. }
          if (TFPReportCustomSummaryBand(lDsgnBand).StartNewPage) or (lDsgnBand.Layout.Height > lSpaceLeft) then
            StartNewPage;
          { Restore reference to lDsgnBand and SummaryBand, because StartNewPage
            could have changed the value of lDsgnBand. }
          lDsgnBand := TFPReportCustomBand(FBands[b]);
          CommonRuntimeBandProcessing(lDsgnBand);
          UpdateSpaceRemaining(lRTBand);
        end;
      end;
    end;  { lHasReportSummaryBand }

  end; { for ... pages }

  if TwoPass and (lPassIdx = 1) then
  begin
    FPageCount := RTObjects.Count;
    EmptyRTObjects;
  end;

  end; { for ... lPassCount }

  if TwoPass then
    DoProcessTwoPass;

  finally
    FreeAndNil(lHeaderList);
    FreeAndNil(lFooterList);
    FreeAndNil(FBands);
    SetLength(FPerDesignerPageCount, 0);
  end;
end;

procedure TFPCustomReport.DoBeginReport;
begin
  if Assigned(FOnBeginReport) then
    FOnBeginReport;
end;

procedure TFPCustomReport.DoEndReport;
begin
  if Assigned(FOnEndReport) then
    FOnEndReport;
end;

procedure TFPCustomReport.RestoreDefaultVariables;

Var
  I : Integer;

begin
  For I:=0 to FVariables.Count-1 do
    FVariables[i].RestoreValue;
end;

procedure TFPCustomReport.InitializeDefaultExpressions;

Var
  I : Integer;
  V : TFPReportVariable;

begin
  FExpr.Clear;
  FExpr.Identifiers.Clear;
  FExpr.BuiltIns := [bcStrings,bcDateTime,bcMath,bcBoolean,bcConversion,bcData,bcVaria,bcUser,bcAggregate];
  FExpr.Identifiers.AddDateTimeVariable('TODAY', Date);
  FExpr.Identifiers.AddStringVariable('AUTHOR', Author);
  FExpr.Identifiers.AddStringVariable('TITLE', Title);
  FExpr.Identifiers.AddFunction('RecNo', 'I', '', @BuiltinExprRecNo);
  FExpr.Identifiers.AddFunction('PageNo', 'I', '', @BuiltinGetPageNumber);
  FExpr.Identifiers.AddFunction('PageCount', 'I', '', @BuiltinGetPageCount);
  FExpr.Identifiers.AddFunction('PageNoPerDesignerPage', 'I', '', @BuiltInGetPageNoPerDesignerPage);
  For I:=0 to FVariables.Count-1 do
    begin
    V:=FVariables[i];
    V.SaveValue;
    FExpr.Identifiers.AddVariable(V.Name,V.DataType,@V.GetRTValue);
    end;
end;

procedure TFPCustomReport.InitializeExpressionVariables(const AData: TFPReportData);
var
  i: Integer;
  f: string;
  r: TResultType;
  d: string;

  function ReportKindToResultType(const AType: TFPReportFieldKind): TResultType;
  begin
    case AType of
      rfkString:      Result := rtString;
      rfkBoolean:     Result := rtBoolean;
      rfkInteger:     Result := rtInteger;
      rfkFloat:       Result := rtFloat;
      rfkDateTime:    Result := rtDateTime;
      rfkStream:      Result := rtString; //  TODO:  What do we do here?????
      else
        Result := rtString;
    end;
  end;


begin
  {$ifdef gdebug}
  writeln('********** TFPCustomReport.InitializeExpressionVariables');
  {$endif}
  F:='';
  For I:=0 to FExpr.Identifiers.Count-1 do
    f:=f+FExpr.Identifiers[i].Name+'; ';
  for i := 0 to AData.DataFields.Count-1 do
  begin
    d := AData.Name;
    f := AData.DataFields[i].FieldName;
    r := ReportKindToResultType(AData.DataFields[i].FieldKind);
    if d <> '' then
    begin
      {$ifdef gdebug}
      writeln('registering (dotted name)... '+ d+'.'+f);
      {$endif}
      FExpr.Identifiers.AddVariable(d+'.'+f, r, @DoGetExpressionVariableValue);
    end
    else
    begin
      {$ifdef gdebug}
      writeln('registering... '+ f);
      {$endif}
      FExpr.Identifiers.AddVariable(f, r, @DoGetExpressionVariableValue);
    end;
  end;
end;

procedure TFPCustomReport.CacheMemoExpressions(const APageIdx: integer; const AData: TFPReportData);
var
  b: integer;
  c: integer;
  m: TFPReportCustomMemo;
begin
  for b := 0 to Pages[APageIdx].BandCount-1 do
  begin
    if Pages[APageIdx].Bands[b] is TFPReportCustomBandWithData then
    begin
      if TFPReportCustomBandWithData(Pages[APageIdx].Bands[b]).Data <> AData then
        Continue;  // band is from a different data-loop
    end;

    for c := 0 to Pages[APageIdx].Bands[b].ChildCount-1 do
      if Pages[APageIdx].Bands[b].Child[c] is TFPReportCustomMemo then
      begin
        m := TFPReportCustomMemo(Pages[APageIdx].Bands[b].Child[c]);
        m.ParseText;
      end;
  end; { bands }
end;

constructor TFPCustomReport.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FReportData:=CreateReportData;
  FRTObjects := TFPList.Create;
  FImages := CreateImages;
  FVariables:=CreateVariables;
  FRTCurPageIdx := -1;
  FDateCreated := Now;
  FTwoPass := False;
  FIsFirstPass := False;
end;

function TFPCustomReport.CreateImages: TFPReportImages;

begin
  Result:=TFPReportImages.Create(self, TFPReportImageItem);
end;

function TFPCustomReport.CreateVariables: TFPReportVariables;

begin
  Result:=TFPReportVariables.Create(Self,TFPReportVariable);
end;

function TFPCustomReport.CreateReportData : TFPReportDataCollection;

begin
  Result:=TFPReportDataCollection.Create(TFPReportDataItem);
end;

destructor TFPCustomReport.Destroy;
begin
  EmptyRTObjects;
  FreeAndNil(FReportData);
  FreeAndNil(FRTObjects);
  FreeAndNil(FPages);
  FreeAndNil(FExpr);
  FreeAndNil(FReferenceList);
  FreeAndNil(FImages);
  FreeAndNil(FVariables);
  inherited Destroy;
end;

procedure TFPCustomReport.SaveDataToNames;

Var
  I : Integer;

begin
  For I:=0 to PageCount-1 do
    Pages[i].SaveDataToNames;
end;

procedure TFPCustomReport.RestoreDataFromNames;
Var
  I : Integer;

begin
  For I:=0 to PageCount-1 do
    Pages[i].RestoreDataFromNames;
end;

procedure TFPCustomReport.AddPage(APage: TFPReportCustomPage);
begin
  if not Assigned(FPages) then
  begin
    FPages := TFPList.Create;
    FPages.Add(APage);
  end
  else if FPages.IndexOf(APage) = -1 then
    FPages.Add(APage);
end;

procedure TFPCustomReport.RemovePage(APage: TFPReportCustomPage);
begin
  if Assigned(FPages) then
    FPages.Remove(APage);
end;

procedure TFPCustomReport.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
var
  i: integer;
begin
  // ignore AOriginal here as we don't support whole report diffs, only element diffs
  AWriter.PushElement('Report');
  try
    inherited WriteElement(AWriter, AOriginal);
    // local properties
    AWriter.WriteString('Title', Title);
    AWriter.WriteString('Author', Author);
    AWriter.WriteDateTime('DateCreated', DateCreated);
    // now the design-time images
    AWriter.PushElement('Images');
    try
      for i := 0 to Images.Count-1 do
      begin
        AWriter.PushElement(IntToStr(i)); // use image index as identifier
        try
          Images[i].WriteElement(AWriter);
        finally
          AWriter.PopElement;
        end;
      end;
    finally
      AWriter.PopElement;
    end;
    // now the pages
    AWriter.PushElement('Pages');
    try
      for i := 0 to PageCount - 1 do
      begin
        AWriter.PushElement(IntToStr(i)); // use page index as identifier
        try
          Pages[i].WriteElement(AWriter);
        finally
          AWriter.PopElement;
        end;
      end;
    finally
      AWriter.PopElement;
    end;
  finally
    AWriter.PopElement;
  end;
  // TODO: Implement writing OnRenderReport, OnBeginReport, OnEndReport
end;

procedure TFPCustomReport.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
  i: integer;
  p: TFPReportPage;
  lImgItem: TFPReportImageItem;
begin
  ClearReferenceList;
  E := AReader.FindChild('Report');
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      inherited ReadElement(AReader);
      FTitle := AReader.ReadString('Title', Title);
      FAuthor := AReader.ReadString('Author', Author);
      FDateCreated := AReader.ReadDateTime('DateCreated', Now);

      E := AReader.FindChild('Images');
      if Assigned(E) then
      begin
        AReader.PushElement(E);
        for i := 0 to AReader.ChildCount-1 do
        begin
          E := AReader.GetChild(i);
          AReader.PushElement(E); // child index is the identifier
          try
            lImgItem := Images.AddImageItem;
            lImgItem.ReadElement(AReader);
          finally
            AReader.PopElement;
          end;
        end; { for i }
        AReader.PopElement;
      end;  { images }

      E := AReader.FindChild('Pages');
      if Assigned(E) then
      begin
        AReader.PushElement(E);
        for i := 0 to AReader.ChildCount-1 do
        begin
          E := AReader.GetChild(i);
          AReader.PushElement(E); // child index is the identifier
          try
            p := TFPReportPage.Create(self);
            p.ReadElement(AReader);
            AddPage(p);
          finally
            AReader.PopElement;
          end;
        end;  { for i }
        AReader.PopElement;
      end; { pages }

      // TODO: Implement reading OnRenderReport, OnBeginReport, OnEndReport
    finally
      AReader.PopElement;
    end;
  end;
  FixupReferences;
end;

procedure TFPCustomReport.StartRender;
begin
  inherited StartRender;
  DoBeforeRenderReport;
end;

procedure TFPCustomReport.EndRender;
begin
  inherited EndRender;
  DoAfterRenderReport;
end;

function TFPCustomReport.FindRecursive(const AName: string): TFPReportElement;
var
  p, b, c: integer;
begin
  Result := nil;
  if AName = '' then
    Exit;
  for p := 0 to PageCount-1 do
  begin
    for b := 0 to Pages[p].BandCount-1 do
    begin
      if SameText(Pages[p].Bands[b].Name, AName) then
        Result := Pages[p].Bands[b];
      if Assigned(Result) then
        Exit;

      for c := 0 to Pages[p].Bands[b].ChildCount-1 do
      begin
        if SameText(Pages[p].Bands[b].Child[c].Name, AName) then
          Result := Pages[p].Bands[b].Child[c];
        if Assigned(Result) then
          Exit;
      end;
    end;
  end;
end;

procedure TFPCustomReport.RunReport;
begin
  DoBeginReport;

  StartLayout;
  FExpr := TFPexpressionParser.Create(nil);
  try
    InitializeDefaultExpressions;
    DoPrepareReport;
  finally
    RestoreDefaultVariables;
    FreeAndNil(FExpr);
  end;
  EndLayout;

  DoEndReport;
end;

procedure TFPCustomReport.RenderReport(const AExporter: TFPReportExporter);
begin
  if not Assigned(AExporter) then
    Exit;
  StartRender;
  try
    AExporter.Report := self;
    AExporter.Execute;
  finally
    EndRender;
  end;
end;

{$IFDEF gdebug}
function TFPCustomReport.DebugPreparedPageAsJSON(const APageNo: Byte): string;
var
  rs: TFPReportStreamer;
begin
  if APageNo > RTObjects.Count-1 then
    Exit;
  rs := TFPReportJSONStreamer.Create(nil);
  try
    TFPReportCustomPage(RTObjects[APageNo]).WriteElement(rs);
    Result := TFPReportJSONStreamer(rs).JSON.FormatJSON;
  finally
    rs.Free;
  end;
end;
{$ENDIF}

{ TFPReportMargins }

procedure TFPReportMargins.SetBottom(const AValue: TFPReportUnits);
begin
  if FBottom = AValue then
    Exit;
  FBottom := AValue;
  Changed;
end;

procedure TFPReportMargins.SetLeft(const AValue: TFPReportUnits);
begin
  if FLeft = AValue then
    Exit;
  FLeft := AValue;
  Changed;
end;

procedure TFPReportMargins.SetRight(const AValue: TFPReportUnits);
begin
  if FRight = AValue then
    Exit;
  FRight := AValue;
  Changed;
end;

procedure TFPReportMargins.SetTop(const AValue: TFPReportUnits);
begin
  if FTop = AValue then
    Exit;
  FTop := AValue;
  Changed;
end;

procedure TFPReportMargins.Changed;
begin
  if Assigned(FPage) then
    FPage.MarginsChanged;
end;

constructor TFPReportMargins.Create(APage: TFPReportCustomPage);
begin
  inherited Create;
  FPage := APage;
end;

procedure TFPReportMargins.Assign(Source: TPersistent);
var
  S: TFPReportMargins;
begin
  if Source is TFPReportMargins then
  begin
    S := Source as TFPReportMargins;
    FTop := S.Top;
    FBottom := S.Bottom;
    FLeft := S.Left;
    FRight := S.Right;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TFPReportMargins.Equals(AMargins: TFPReportMargins): boolean;
begin
  Result := (AMargins = Self)
    or ((Top = AMargins.Top) and (Left = AMargins.Left) and
        (Right = AMargins.Right) and (Bottom = AMargins.Bottom));
end;

procedure TFPReportMargins.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportMargins);
begin
  if (AOriginal = nil) then
  begin
    AWriter.WriteFloat('Top', Top);
    AWriter.WriteFloat('Left', Left);
    AWriter.WriteFloat('Bottom', Bottom);
    AWriter.WriteFloat('Right', Right);
  end
  else
  begin
    AWriter.WriteFloatDiff('Top', Top, AOriginal.Top);
    AWriter.WriteFloatDiff('Left', Left, AOriginal.Left);
    AWriter.WriteFloatDiff('Bottom', Bottom, AOriginal.Bottom);
    AWriter.WriteFloatDiff('Right', Right, AOriginal.Right);
  end;
end;

procedure TFPReportMargins.ReadElement(AReader: TFPReportStreamer);
begin
  Top := AReader.ReadFloat('Top', Top);
  Left := AReader.ReadFloat('Left', Left);
  Bottom := AReader.ReadFloat('Bottom', Bottom);
  Right := AReader.ReadFloat('Right', Right);
end;

{ TFPReportCustomBand }

function TFPReportCustomBand.GetReportPage: TFPReportCustomPage;
begin
  Result := Parent as TFPReportCustomPage;
end;

function TFPReportCustomBand.GetFont: TFPReportFont;
begin
  if UseParentFont then
  begin
    if Assigned(Owner) then
      Result := TFPReportCustomPage(Owner).Font
    else
    begin
      FFont := TFPReportFont.Create;
      Result := FFont;
    end;
  end
  else
    Result := FFont;
end;

function TFPReportCustomBand.IsStringValueZero(const AValue: string): boolean;
var
  lIntVal: integer;
  lFloatVal: double;
begin
  Result := False;
  if TryStrToInt(AValue, lIntVal) then
  begin
    if lIntVal = 0 then
      Result := True;
  end
  else if TryStrToFloat(AValue, lFloatVal) then
  begin
    if lFloatVal = 0 then
      Result := True;
  end;
end;

procedure TFPReportCustomBand.SetChildBand(AValue: TFPReportChildBand);
var
  b: TFPReportCustomBand;
begin
  if FChildBand = AValue then
    Exit;
  FChildBand := AValue;
  b := FChildBand;
  while b <> nil do
  begin
    b := b.ChildBand;
    if b = self then
      raise EReportError.Create(SErrChildBandCircularReference);
  end;
end;

procedure TFPReportCustomBand.ApplyStretchMode;
var
  h: TFPReportUnits;
  c: TFPReportElement;
  i: integer;
begin
  h := RTLayout.Height;
  for i := 0 to ChildCount-1 do
  begin
    c := Child[i];
    if c.RTLayout.Top + c.RTLayout.Height > h then
      h := c.RTLayout.Top + c.RTLayout.Height;
  end;
  RTLayout.Height := h;
end;

procedure TFPReportCustomBand.SetFont(AValue: TFPReportFont);
begin
  if UseParentFont then
    UseParentFont := False;
  FFont.Assign(AValue);
  Changed;
end;

procedure TFPReportCustomBand.SetUseParentFont(AValue: boolean);
begin
  if FUseParentFont = AValue then
    Exit;
  FUseParentFont := AValue;
  if FUseParentFont then
    FreeAndNil(FFont)
  else
  begin
    FFont := TFPReportFont.Create;
    if Assigned(Owner) then
      FFont.Assign(TFPReportCustomPage(Owner).Font);
  end;
  Changed;
end;

procedure TFPReportCustomBand.SetVisibleOnPage(AValue: TFPReportVisibleOnPage);
begin
  if FVisibleOnPage = AValue then
    Exit;
  FVisibleOnPage := AValue;
  Changed;
end;

function TFPReportCustomBand.GetReportBandName: string;
begin
  Result := 'FPCustomReportBand';
end;

function TFPReportCustomBand.GetData: TFPReportData;
begin
  result := nil;
end;

procedure TFPReportCustomBand.SetDataFromName(AName: String);
begin
  // Do nothing
end;

procedure TFPReportCustomBand.SetParent(const AValue: TFPReportElement);
begin
  if not ((AValue = nil) or (AValue is TFPReportCustomPage)) then
    ReportError(SErrNotAReportPage, [AValue.ClassName, AValue.Name]);
  inherited SetParent(AValue);
end;

procedure TFPReportCustomBand.CreateRTLayout;
begin
  inherited CreateRTLayout;
  FRTLayout.Left := Page.Layout.Left;
end;

procedure TFPReportCustomBand.PrepareObjects;

var
  lRTPage: TFPReportCustomPage;
  i: integer;
  m: TFPReportMemo;
  cb: TFPReportCheckbox;
  img: TFPReportCustomImage;
  s: string;
  c: integer;
  n: TFPExprNode;
  nIdx: integer;

begin
  i := Page.Report.FRTCurPageIdx;
  if Assigned(Page.Report.RTObjects[i]) then
  begin
    lRTPage := TFPReportCustomPage(Page.Report.RTObjects[i]);
    { Thanks to the factory, create the correct [band type] runtime instance }
    Page.Report.FRTCurBand := gElementFactory.CreateInstance(self.GetReportBandName, lRTPage) as TFPReportCustomBand;
    Page.Report.FRTCurBand.Assign(self);
    Page.Report.FRTCurBand.CreateRTLayout;
  end;
  inherited PrepareObjects;

  if self is TFPReportGroupHeaderBand then
    TFPReportGroupHeaderBand(Page.Report.FRTCurBand).CalcGroupConditionValue;

  if Assigned(FChildren) then
  begin
    for c := 0 to Page.Report.FRTCurBand.ChildCount-1 do
    begin
      if TFPReportElement(Page.Report.FRTCurBand.Child[c]) is TFPReportCustomMemo then
      begin
        m := TFPReportMemo(Page.Report.FRTCurBand.Child[c]);
        if moDisableExpressions in m.Options then
          Continue; // nothing further to do
        m.ExpandExpressions;
        // visibility handling
        if moHideZeros in m.Options then
        begin
          if IsStringValueZero(m.Text) then
          begin
            m.Visible := False;
            Continue;
          end;
        end;
        if moSuppressRepeated in m.Options then
        begin
          if m.Original.FLastText = m.Text then
          begin
            m.Visible := False;
            Continue;
          end
          else
            m.Original.FLastText := m.Text;
        end;
        // aggregate handling
        for nIdx := 0 to Length(m.Original.ExpressionNodes)-1 do
        begin
          n := m.Original.ExpressionNodes[nIdx].ExprNode;
          if not Assigned(n) then
            Continue;
          if n.HasAggregate then
          begin
            if moNoResetAggregateOnPrint in m.Options then
            begin
              // do nothing
            end
                 // apply memo.Options rules if applicable
            else if ((self is TFPReportCustomPageHeaderBand) and (moResetAggregateOnPage in m.Options))
                  or ((self is TFPReportCustomColumnHeaderBand) and (moResetAggregateOnColumn in m.Options))
                  or ((self is TFPReportCustomGroupHeaderBand) and (moResetAggregateOnGroup in m.Options)) then
                n.InitAggregate
                 // apply Page/Column/Group/Data footer rule
            else if (self is TFPReportCustomPageFooterBand)
                  or (self is TFPReportCustomColumnFooterBand)
                  or (self is TFPReportCustomGroupFooterBand)
                  or (self is TFPReportCustomDataFooterBand) then
                n.InitAggregate
            else
              // default rule - reset on print. applies to all memos
              n.InitAggregate;
          end;
        end;
      end
      else if TFPReportElement(Page.Report.FRTCurBand.Child[c]) is TFPReportCustomCheckbox then
      begin
        cb := TFPReportCheckbox(Page.Report.FRTCurBand.Child[c]);
        s := ExpandMacro(cb.Expression, True);
        cb.FTestResult := StrToBoolDef(s, False);
      end
      else if TFPReportElement(Page.Report.FRTCurBand.Child[c]) is TFPReportCustomImage then
      begin
        img := TFPReportCustomImage(Page.Report.FRTCurBand.Child[c]);
        if (img.FieldName <> '') and Assigned(GetData) then
          img.LoadDBData(GetData);
      end;
    end; { for c := 0 to ... }
  end;  { if Assigned(FChildren) ... }
end;

procedure TFPReportCustomBand.RecalcLayout;
begin
  inherited RecalcLayout;
  if StretchMode <> smDontStretch then
    ApplyStretchMode;
end;

procedure TFPReportCustomBand.Assign(Source: TPersistent);
var
  E: TFPReportCustomBand;
begin
  inherited Assign(Source);
  if Source is TFPReportCustomBand then
  begin
    E := TFPReportCustomBand(Source);
    FChildBand := E.ChildBand;
    FStretchMode := E.StretchMode;
    FVisibleOnPage := E.VisibleOnPage;
    UseParentFont := E.UseParentFont;
    if not UseParentFont then
      Font.Assign(E.Font);
  end;
end;

class function TFPReportCustomBand.ReportBandType: TFPReportBandType;
begin
  Result:=btUnknown;
end;

procedure TFPReportCustomBand.BeforePrint;
var
  i: integer;
  c: TFPReportElement;
begin
  inherited BeforePrint;
  if Visible = false then
    exit;
  if Assigned(FChildren) then
  begin
    for i := 0 to FChildren.Count-1 do
    begin
      c := Child[i];
      c.BeforePrint;
    end;
  end;
end;

procedure TFPReportCustomBand.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  AWriter.WriteBoolean('UseParentFont', UseParentFont);
  if not UseParentFont then
  begin
    AWriter.WriteString('FontName', Font.Name);
    AWriter.WriteInteger('FontSize', Font.Size);
    AWriter.WriteInteger('FontColor', Font.Color);
  end;
end;

constructor TFPReportCustomBand.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVisibleOnPage := vpAll;
  FUseParentFont := True;
  FFont := nil
end;

destructor TFPReportCustomBand.Destroy;
begin
  FreeAndNil(FFont);
  inherited Destroy;
end;

procedure TFPReportCustomBand.WriteElement(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  AWriter.PushElement(GetReportBandName);
  try
    inherited WriteElement(AWriter, AOriginal);
    if Assigned(ChildBand) then
      AWriter.WriteString('ChildBand', ChildBand.Name);
    if Assigned(GetData) then
      AWriter.WriteString('Data', GetData.Name);
    AWriter.WriteString('VisibleOnPage', VisibleOnPageToString(FVisibleOnPage));
  finally
    AWriter.PopElement;
  end;
end;

procedure TFPReportCustomBand.ReadElement(AReader: TFPReportStreamer);
var
  E: TObject;
  s: string;
begin
  E := AReader.FindChild(GetReportBandName);
  if Assigned(E) then
  begin
    AReader.PushElement(E);
    try
      inherited ReadElement(AReader);
      s := AReader.ReadString('ChildBand', '');
      if s <> '' then
        Page.Report.AddReference(self.Name, s);
//        Page.Report.AddReference(self, 'ChildBand', s);
      FVisibleOnPage := StringToVisibleOnPage(AReader.ReadString('VisibleOnPage', 'vpAll'));
      FUseParentFont := AReader.ReadBoolean('UseParentFont', UseParentFont);
      if not FUseParentFont then
      begin
        Font.Name := AReader.ReadString('FontName', Font.Name);
        Font.Size := AReader.ReadInteger('FontSize', Font.Size);
        Font.Color := AReader.ReadInteger('FontColor', Font.Color);
      end;

      // TODO: Read Data information
      S:=AReader.ReadString('Data','');
      if (S<>'') then
        SetDataFromName(S);
    finally
      AReader.PopElement;
    end;
  end;
end;

{ TFPReportCustomBandWithData }

procedure TFPReportCustomBandWithData.SetData(const AValue: TFPReportData);
begin
  if FData = AValue then
    Exit;
  if Assigned(FData) then
    FData.RemoveFreeNotification(Self);
  FData := AValue;
  if Assigned(FData) then
    FData.FreeNotification(Self);
end;

procedure TFPReportCustomBandWithData.SaveDataToNames;
begin
  inherited SaveDataToNames;
  if Assigned(FData) then
    FDataName:=FData.Name
  else
    FDataName:='';
end;

procedure TFPReportCustomBandWithData.ResolveDataName;

begin
  if (FDataName<>'') then
    Data:=Report.ReportData.FindReportData(FDataName)
  else
    Data:=Nil;
end;
procedure TFPReportCustomBandWithData.RestoreDataFromNames;

begin
  inherited RestoreDataFromNames;
  ResolveDataName;
end;

function TFPReportCustomBandWithData.GetData: TFPReportData;
begin
  Result := FData;
end;

procedure TFPReportCustomBandWithData.SetDataFromName(AName: String);
begin
  FDataName:=AName;
  ResolveDataName;
end;

procedure TFPReportCustomBandWithData.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
  begin
    if AComponent = FData then
      FData := nil;
  end;
  inherited Notification(AComponent, Operation);
end;

constructor TFPReportCustomBandWithData.Create(AOwner: TComponent);
begin
  FData := nil;
  inherited Create(AOwner);
end;

{ TFPReportCustomGroupFooterBand }

procedure TFPReportCustomGroupFooterBand.SetGroupHeader(const AValue: TFPReportCustomGroupHeaderBand);
begin
  if FGroupHeader = AValue then
    Exit;
  if Assigned(FGroupHeader) then
  begin
    FGroupHeader.FGroupFooter := nil;
    FGroupHeader.RemoveFreeNotification(Self);
  end;
  FGroupHeader := AValue;
  if Assigned(FGroupHeader) then
  begin
    FGroupHeader.FGroupFooter := Self;
    FGroupHeader.FreeNotification(Self);
  end;
end;

function TFPReportCustomGroupFooterBand.GetReportBandName: string;
begin
  Result := 'GroupFooterBand';
end;

procedure TFPReportCustomGroupFooterBand.DoWriteLocalProperties(AWriter: TFPReportStreamer; AOriginal: TFPReportElement);
begin
  inherited DoWriteLocalProperties(AWriter, AOriginal);
  if Assigned(GroupHeader) then
    AWriter.WriteString('GroupHeader', GroupHeader.Name);
end;

procedure TFPReportCustomGroupFooterBand.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FGroupHeader) then
    FGroupHeader := nil;
  inherited Notification(AComponent, Operation);
end;

procedure TFPReportCustomGroupFooterBand.ReadElement(AReader: TFPReportStreamer);
var
  s: string;
//  c: TFPReportElement;
begin
//  c := nil;
  inherited ReadElement(AReader);
  s := AReader.ReadString('GroupHeader', '');
  if s = '' then
    Exit;
  // TODO: recursively search Page.Report for the GroupHeader
  //c := Page.Report.FindComponent(s);
  //if Assigned(c) then
  //  FGroupHeader := TFPReportCustomGroupHeaderBand(c);
end;

class function TFPReportCustomGroupFooterBand.ReportBandType: TFPReportBandType;
begin
  Result:=btGroupFooter;
end;


{ TFPReportImageItem }

function TFPReportImageItem.GetHeight: Integer;
begin
  If Assigned(FImage) then
    Result:=FImage.Height
  else
    Result:=FHeight;
end;

function TFPReportImageItem.GetStreamed: TBytes;
begin
  if Length(FStreamed)=0 then
    CreateStreamedData;
  Result:=FStreamed;
end;

function TFPReportImageItem.GetWidth: Integer;
begin
  If Assigned(FImage) then
    Result:=FImage.Width
  else
    Result:=FWidth;
end;

procedure TFPReportImageItem.SetImage(AValue: TFPCustomImage);
begin
  if FImage=AValue then Exit;
  FImage:=AValue;
  SetLength(FStreamed,0);
end;

procedure TFPReportImageItem.SetStreamed(AValue: TBytes);
begin
  If AValue=FStreamed then exit;
  SetLength(FStreamed,0);
  FStreamed:=AValue;
end;

procedure TFPReportImageItem.LoadPNGFromStream(AStream: TStream);
var
  PNGReader: TFPReaderPNG;
begin
  if not Assigned(AStream) then
    Exit;

  { we use Image property here so it frees any previous image }
  if Assigned(FImage) then
    FreeAndNil(FImage);
  FImage := TFPCompactImgRGBA8Bit.Create(0, 0);
  try
    PNGReader := TFPReaderPNG.Create;
    try
      FImage.LoadFromStream(AStream, PNGReader); // auto size image
    finally
      PNGReader.Free;
    end;
  except
    FreeAndNil(FImage);
  end;
end;

constructor TFPReportImageItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FOwnsImage := True;
end;

destructor TFPReportImageItem.Destroy;
begin
  if FOwnsImage then
    FreeAndNil(FImage);
  inherited Destroy;
end;

procedure TFPReportImageItem.CreateStreamedData;
Var
  X, Y: Integer;
  C: TFPColor;
  MS: TMemoryStream;
  Str: TStream;
  CWhite: TFPColor; // white color
begin
  FillMem(@CWhite, SizeOf(CWhite), $FF);
  FWidth:=Image.Width;
  FHeight:=Image.Height;
  Str := nil;
  MS := TMemoryStream.Create;
  try
    Str := MS;
    for Y:=0 to FHeight-1 do
      for X:=0 to FWidth-1 do
        begin
        C:=Image.Colors[x,y];
        if C.alpha < $FFFF then // remove alpha channel - assume white background
          C := AlphaBlend(CWhite, C);

        Str.WriteByte(C.Red shr 8);
        Str.WriteByte(C.Green shr 8);
        Str.WriteByte(C.blue shr 8);
        end;
    if Str<>MS then
      Str.Free;
    Str := nil;
    SetLength(FStreamed, MS.Size);
    MS.Position := 0;
    if MS.Size>0 then
      MS.ReadBuffer(FStreamed[0], MS.Size);
  finally
    Str.Free;
    MS.Free;
  end;
end;

function TFPReportImageItem.WriteImageStream(AStream: TStream): UInt64;
var
  Img: TBytes;
begin
  Img := StreamedData;
  Result := Length(Img);
  AStream.WriteBuffer(Img[0],Result);
end;

function TFPReportImageItem.Equals(AImage: TFPCustomImage): boolean;
var
  x, y: Integer;
begin
  Result := True;
  for x := 0 to Image.Width-1 do
    for y := 0 to Image.Height-1 do
      if Image.Pixels[x, y] <> AImage.Pixels[x, y] then
      begin
        Result := False;
        Exit;
      end;
end;

procedure TFPReportImageItem.WriteElement(AWriter: TFPReportStreamer);
var
  ms: TMemoryStream;
  png: TFPWriterPNG;
begin
  if Assigned(Image) then
  begin
    ms := TMemoryStream.Create;
    try
      png := TFPWriterPNG.create;
      png.Indexed := False;
      Image.SaveToStream(ms, png);
      ms.Position := 0;
      AWriter.WriteStream('ImageData', ms);
    finally
      png.Free;
      ms.Free;
    end;
  end;
end;

procedure TFPReportImageItem.ReadElement(AReader: TFPReportStreamer);
var
  ms: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  try
    if AReader.ReadStream('ImageData', ms) then
    begin
      ms.Position := 0;
      LoadPNGFromStream(ms);
    end;
  finally
    ms.Free;
  end;
end;

{ TFPReportImages }

function TFPReportImages.GetImg(AIndex: Integer): TFPReportImageItem;
begin
  Result := Items[AIndex] as TFPReportImageItem;
end;

function TFPReportImages.GetReportOwner: TFPCustomReport;
begin
  Result:=Owner as TFPCustomReport;
end;


constructor TFPReportImages.Create(AOwner: TFPCustomReport; AItemClass: TCollectionItemClass);
begin
  inherited Create(aOwner,AItemClass);
end;

function TFPReportImages.AddImageItem: TFPReportImageItem;
begin
  Result := Add as TFPReportImageItem;
end;

function TFPReportImages.AddFromStream(const AStream: TStream;
    Handler: TFPCustomImageReaderClass; KeepImage: Boolean): Integer;
var
  I: TFPCustomImage;
  IP: TFPReportImageItem;
  Reader: TFPCustomImageReader;
begin
  IP := AddImageItem;
  I := TFPCompactImgRGBA8Bit.Create(0,0);
  Reader := Handler.Create;
  try
    I.LoadFromStream(AStream, Reader);
  finally
    Reader.Free;
  end;
  IP.Image := I;
  if Not KeepImage then
  begin
    IP.CreateStreamedData;
    IP.FImage := Nil; // not through property, that would clear the image
    I.Free;
  end;
  Result := Count-1;
end;

function TFPReportImages.AddFromFile(const AFileName: string; KeepImage: Boolean): Integer;

  {$IF NOT (FPC_FULLVERSION >= 30101)}
  function FindReaderFromExtension(extension: String): TFPCustomImageReaderClass;
  var
    s: string;
    r: integer;
  begin
    extension := lowercase (extension);
    if (extension <> '') and (extension[1] = '.') then
      system.delete (extension,1,1);
    with ImageHandlers do
    begin
      r := count-1;
      s := extension + ';';
      while (r >= 0) do
      begin
        Result := ImageReader[TypeNames[r]];
        if (pos(s,{$if (FPC_FULLVERSION = 20604)}Extentions{$else}Extensions{$endif}[TypeNames[r]]+';') <> 0) then
          Exit;
        dec (r);
      end;
    end;
    Result := nil;
  end;

  function FindReaderFromFileName(const filename: String): TFPCustomImageReaderClass;
  begin
    Result := FindReaderFromExtension(ExtractFileExt(filename));
  end;
  {$ENDIF}

var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := AddFromStream(FS,
      {$IF (FPC_FULLVERSION >= 30101)}TFPCustomImage.{$ENDIF}FindReaderFromFileName(AFileName), KeepImage);
  finally
    FS.Free;
  end;
end;

function TFPReportImages.AddFromData(const AImageData: Pointer; const AImageDataSize: LongWord): integer;
var
  s: TMemoryStream;
begin
  s := TMemoryStream.Create;
  try
    s.Write(AImageData^, AImageDataSize);
    s.Position := 0;
    Result := AddFromStream(s, TFPReaderPNG, True);
  finally
    s.Free;
  end;
end;

function TFPReportImages.GetIndexFromID(const AID: integer): integer;
var
  i: integer;
begin
  result := -1;
  if AID<0 then
    exit;
  for i := 0 to Count-1 do
  begin
    if Images[i].ID = AID then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TFPReportImages.GetImageFromID(const AID: integer): TFPCustomImage;

Var
  II : TFPReportImageItem;

begin
  II:=GetImageItemFromID(AID);
  if II<>Nil then
    Result:=II.Image
  else
    Result:=Nil;
end;

function TFPReportImages.GetImageItemFromID(const AID: integer): TFPReportImageItem;

Var
  I : Integer;
begin
  I:=GetIndexFromID(AID);
  if I<>-1 then
    Result:=Images[I]
  else
    Result:=Nil;
end;

{ TFPReportPageSize }

procedure TFPReportPageSize.SetHeight(const AValue: TFPReportUnits);
begin
  if FHeight = AValue then
    Exit;
  FHeight := AValue;
  Changed;
end;

procedure TFPReportPageSize.CheckPaperSize;
var
  i: integer;
begin
  I := PaperManager.IndexOfPaper(FPaperName);
  if (I <> -1) then
  begin
    FWidth := PaperManager.PaperWidth[I];
    FHeight := PaperManager.PaperHeight[I];
    Changed;
  end;
end;

procedure TFPReportPageSize.SetPaperName(const AValue: string);
begin
  if FPaperName = AValue then
    Exit;
  FPaperName := AValue;
  if (FPaperName <> '') then
    CheckPaperSize;
end;

procedure TFPReportPageSize.SetWidth(const AValue: TFPReportUnits);
begin
  if FWidth = AValue then
    Exit;
  FWidth := AValue;
  Changed;
end;

procedure TFPReportPageSize.Changed;
begin
  if Assigned(FPage) then
    FPage.PageSizeChanged;
end;

constructor TFPReportPageSize.Create(APage: TFPReportCustomPage);
begin
  FPage := APage;
end;

procedure TFPReportPageSize.Assign(Source: TPersistent);
var
  S: TFPReportPageSize;
begin
  if Source is TFPReportPageSize then
  begin
    S := Source as TFPReportPageSize;
    FPaperName := S.FPaperName;
    FWidth := S.FWidth;
    FHeight := S.FHeight;
    Changed;
  end
  else
    inherited Assign(Source);
end;

{ TFPReportExporter }

procedure TFPReportExporter.SetFPReport(AValue: TFPCustomReport);
begin
  if FPReport = AValue then
    Exit;
  if Assigned(FPReport) then
    FPReport.RemoveFreeNotification(Self);
  FPReport := AValue;
  if Assigned(FPReport) then
    FPReport.FreeNotification(Self);
end;

procedure TFPReportExporter.SetBaseFileName(AValue: string);
begin
  if FBaseFileName=AValue then Exit;
  FBaseFileName:=AValue;
end;

procedure TFPReportExporter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation=opRemove) and (AComponent=FPReport) then
    FPReport:=Nil;
end;

procedure TFPReportExporter.RenderImage(aPos: TFPReportRect; var AImage: TFPCustomImage);
begin
  // Do nothing
end;

TYpe

  { TMyFPCompactImgRGBA8Bit }

  TMyFPCompactImgRGBA8Bit = Class(TFPCompactImgRGBA8Bit)
    procedure SetInternalColor (x, y: integer; const Value: TFPColor); override;
  end;

{ TMyFPCompactImgRGBA8Bit }

procedure TMyFPCompactImgRGBA8Bit.SetInternalColor(x, y: integer; const Value: TFPColor);
begin
  if (X<0) or (Y<0) or (X>=Width) or (Y>=Height) then
    Writeln('(',X,',',Y,') not in (0,0)x(',Width-1,',',Height-1,')')
  else
    inherited SetInternalColor(x, y, Value);
end;

procedure TFPReportExporter.RenderUnknownElement(aBasePos: TFPReportPoint;
  AElement: TFPReportElement; ADPI: Integer);

Var
  C : TFPReportElementExporterCallBack;
  IC : TFPReportImageRenderCallBack;
  Img : TFPCustomImage;
  H,W : Integer;
  R : TFPReportRect;

begin
  // Actually, this could be cached using propertyhash...
  C:=gElementFactory.FindRenderer(TFPReportExporterClass(self.ClassType),TFPReportElementClass(aElement.ClassType));
  if (C<>Nil) then
    // There is a direct renderer
    C(aBasePos, aElement,Self,aDPI)
  else
    begin
    // There is no direct renderer, try rendering to image
    IC:=gElementFactory.FindImageRenderer(TFPReportElementClass(aElement.ClassType));
    if Assigned(IC) then
      begin
      H := Round(aElement.RTLayout.Height * (aDPI / cMMperInch));
      W := Round(aElement.RTLayout.Width * (aDPI / cMMperInch));
      Img:=TFPCompactImgRGBA8Bit.Create(W,H);
      try
        IC(aElement,Img);
        R.Left:=aBasePos.Left+AElement.RTLayout.Left;
        R.Top:=aBasePos.Top+AElement.RTLayout.Top;
        R.Width:=AElement.RTLayout.Width;
        R.Height:=AElement.RTLayout.Height;
        RenderImage(R,Img);
      finally
        Img.Free;
      end;
      end;
    end;
end;


class function TFPReportExporter.DefaultConfig: TFPReportExporterConfigHandler;
begin
  Result:=Nil;
end;

procedure TFPReportExporter.Execute;
begin
  if (FPReport.RTObjects.Count=0) and AutoRun then
    FPreport.RunReport;
  if FPReport.RTObjects.Count > 0 then
    DoExecute(FPReport.RTObjects);
end;

procedure TFPReportExporter.SetFileName(const aFileName: String);
begin
  // Do nothing
end;

class procedure TFPReportExporter.RegisterExporter;
begin
  ReportExportManager.RegisterExport(Self);
end;

class procedure TFPReportExporter.UnRegisterExporter;
begin
  ReportExportManager.UnRegisterExport(Self);
end;

class function TFPReportExporter.Description: String;
begin
  Result:='';
end;

class function TFPReportExporter.Name: String;
begin
  Result:=ClassName;
end;

class function TFPReportExporter.DefaultExtension: String;
begin
  Result:='';
end;

function TFPReportExporter.ShowConfig: Boolean;
begin
  Result:=ReportExportManager.ConfigExporter(Self);
end;

{ TFPReportPaperSize }

constructor TFPReportPaperSize.Create(const AWidth, AHeight: TFPReportUnits);
begin
  FWidth := AWidth;
  FHeight := AHeight;
end;

{ TFPReportFont }

procedure TFPReportFont.SetFontName(const avalue: string);
begin
  FFontName := AValue;
end;

procedure TFPReportFont.SetFontSize(const avalue: integer);
begin
  FFontSize := AValue;
end;

procedure TFPReportFont.SetFontColor(const avalue: TFPReportColor);
begin
  FFontColor := AValue;
end;

constructor TFPReportFont.Create;
begin
  inherited Create;
  FFontName := cDefaultFont;
  FFontColor := clBlack;
  FFontSize := 10;
end;

procedure TFPReportFont.Assign(Source: TPersistent);
var
  o: TFPReportFont;
begin
  //inherited Assign(Source);
  if (Source = nil) or not (Source is TFPReportFont) then
    ReportError(SErrCantAssignReportFont);
  o := TFPReportFont(Source);
  FFontName := o.Name;
  FFontSize := o.Size;
  FFontColor := o.Color;
end;

{ TFPReportPaperManager }

function TFPReportPaperManager.GetPaperHeight(AIndex: integer): TFPReportUnits;
begin
  Result := TFPReportPaperSize(FPaperSizes.Objects[AIndex]).Height;
end;

function TFPReportPaperManager.GetPaperHeightByName(AName: string): TFPReportUnits;
begin
  Result := GetPaperByName(AName).Height;
end;

function TFPReportPaperManager.GetPaperCount: integer;
begin
  Result := FPaperSizes.Count;
end;

function TFPReportPaperManager.GetPaperName(AIndex: integer): string;
begin
  Result := FPaperSizes[AIndex];
end;

function TFPReportPaperManager.GetPaperWidth(AIndex: integer): TFPReportUnits;
begin
  Result := TFPReportPaperSize(FPaperSizes.Objects[AIndex]).Width;
end;

function TFPReportPaperManager.GetPaperWidthByName(AName: string): TFPReportUnits;
begin
  Result := GetPaperByName(AName).Width;
end;

function TFPReportPaperManager.FindPaper(const AName: string): TFPReportPaperSize;
var
  I: integer;
begin
  I := IndexOfPaper(AName);
  if (I = -1) then
    Result := nil
  else
    Result := TFPReportPaperSize(FPaperSizes.Objects[i]);
end;

function TFPReportPaperManager.GetPaperByname(const AName: string): TFPReportPaperSize;
begin
  Result := FindPaper(AName);
  if Result = nil then
    ReportError(SErrUnknownPaper, [AName]);
end;

constructor TFPReportPaperManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPaperSizes := TStringList.Create;
  FPaperSizes.Sorted := True;
end;

destructor TFPReportPaperManager.Destroy;
var
  I: integer;
begin
  if Assigned(FPaperSizes) then
  begin
    for I := 0 to FPaperSizes.Count - 1 do
      FPaperSizes.Objects[i].Free;
    FreeAndNil(FPaperSizes);
  end;
  inherited Destroy;
end;

procedure TFPReportPaperManager.Clear;
var
  i: integer;
begin
  for i := 0 to FPaperSizes.Count-1 do
    if Assigned(FPaperSizes.Objects[i]) then
      FPaperSizes.Objects[i].Free;
  FPaperSizes.Clear;
end;

function TFPReportPaperManager.IndexOfPaper(const AName: string): integer;
begin
  if not Assigned(FPaperSizes) then
    Result := -1
  else
    Result := FPaperSizes.IndexOf(AName);
end;

procedure TFPReportPaperManager.RegisterPaper(const AName: string; const AWidth, AHeight: TFPReportUnits);
var
  I: integer;
  S: TFPReportPaperSize;
begin
  I := FPaperSizes.IndexOf(AName);
  if (I = -1) then
  begin
    S := TFPReportPaperSize.Create(AWidth, AHeight);
    FPaperSizes.AddObject(AName, S);
  end
  else
    ReportError(SErrDuplicatePaperName, [AName]);
end;

{ Got details from Wikipedia [https://simple.wikipedia.org/wiki/Paper_size] }
procedure TFPReportPaperManager.RegisterStandardSizes;
begin
  // As per TFPReportUnits, size is specified in millimetres.
  RegisterPaper('A3', 297, 420);
  RegisterPaper('A4', 210, 297);
  RegisterPaper('A5', 148, 210);
  RegisterPaper('Letter', 216, 279);
  RegisterPaper('Legal', 216, 356);
  RegisterPaper('Ledger', 279, 432);
  RegisterPaper('DL',	220, 110);
  RegisterPaper('B5',	176, 250);
  RegisterPaper('C5',	162, 229);
end;

procedure TFPReportPaperManager.GetRegisteredSizes(var AList: TStringList);
var
  i: integer;
begin
  if not Assigned(AList) then
    Exit;
  AList.Clear;
  for i := 0 to FPaperSizes.Count - 1 do
    AList.Add(PaperNames[i]);
end;

procedure DoneReporting;
begin
  if Assigned(uPaperManager) then
    FreeAndNil(uPaperManager);
  TFPReportCustomCheckbox.ImgFalse.Free;
  TFPReportCustomCheckbox.ImgTrue.Free;
end;

{ TFPTextBlockList }

function TFPTextBlockList.GetItem(AIndex: Integer): TFPTextBlock;
begin
  Result := TFPTextBlock(inherited GetItem(AIndex));
end;

procedure TFPTextBlockList.SetItem(AIndex: Integer; AObject: TFPTextBlock);
begin
  inherited SetItem(AIndex, AObject);
end;

{ TFPReportDataField }

function TFPReportDataField.GetValue: variant;
begin
  Result := Null;
  if Assigned(Collection) then
    TFPReportDatafields(Collection).ReportData.DoGetValue(FieldName, Result);
end;

procedure TFPReportDataField.Assign(Source: TPersistent);
var
  F: TFPReportDataField;
begin
  if Source is TFPReportDataField then
  begin
    F := Source as TFPReportDataField;
    FDisplayWidth := F.FDisplayWidth;
    FFieldKind := F.FFieldKind;
    FFieldName := F.FFieldName;
  end
  else
    inherited Assign(Source);
end;

{ TFPReportDataFields }

function TFPReportDataFields.GetF(AIndex: integer): TFPReportDataField;
begin
  Result := TFPReportDataField(Items[AIndex]);
end;

procedure TFPReportDataFields.SetF(AIndex: integer; const AValue: TFPReportDataField);
begin
  Items[AIndex] := AValue;
end;

function TFPReportDataFields.AddField(AFieldName: string; AFieldKind: TFPReportFieldKind): TFPReportDataField;
begin
  Result := Add as TFPReportDataField;
  try
    Result.FieldName := AFieldName;
    Result.FieldKind := AFieldKind;
  except
    Result.Free;
    raise;
  end;
end;

function TFPReportDataFields.IndexOfField(const AFieldName: string): integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (CompareText(AFieldName, GetF(Result).FieldName) <> 0) do
    Dec(Result);
end;

function TFPReportDataFields.FindField(const AFieldName: string): TFPReportDataField;
var
  I: integer;
begin
  I := IndexOfField(AFieldName);
  if (I = -1) then
    Result := nil
  else
    Result := GetF(I);
end;

function TFPReportDataFields.FindField(const AFieldName: string; const AFieldKind: TFPReportFieldKind): TFPReportDataField;
var
  lIndex: integer;
begin
  lIndex := Count - 1;
  while (lIndex >= 0) and (not SameText(AFieldName, GetF(lIndex).FieldName)) and (GetF(lIndex).FieldKind <> AFieldKind) do
      Dec(lIndex);

  if (lIndex = -1) then
    Result := nil
  else
    Result := GetF(lIndex);
end;

function TFPReportDataFields.FieldByName(const AFieldName: string): TFPReportDataField;
begin
  Result := FindField(AFieldName);
  if (Result = nil) then
  begin
    if Assigned(ReportData) then
      ReportError(SErrUnknownField, [ReportData.Name, AFieldName])
    else
      ReportError(SErrUnknownField, ['', AFieldName]);
  end;
end;

{ TFPReportData }

procedure TFPReportData.SetDataFields(const AValue: TFPReportDataFields);
begin
  if (FDataFields = AValue) then
    Exit;
  FDataFields.Assign(AValue);
end;

function TFPReportData.GetFieldCount: integer;
begin
  Result := FDatafields.Count;
end;

function TFPReportData.GetFieldName(Index: integer): string;
begin
  Result := FDatafields[Index].FieldName;
end;

function TFPReportData.GetFieldType(AFieldName: string): TFPReportFieldKind;
begin
  Result := FDatafields.FieldByName(AFieldName).FieldKind;
end;

function TFPReportData.GetFieldValue(AFieldName: string): variant;
begin
  Result := varNull;
  DoGetValue(AFieldName, Result);
end;

function TFPReportData.GetFieldWidth(AFieldName: string): integer;
begin
  Result := FDataFields.FieldByName(AFieldName).DisplayWidth;
end;

function TFPReportData.CreateDataFields: TFPReportDataFields;
begin
  Result := TFPReportDataFields.Create(TFPReportDataField);
end;

procedure TFPReportData.DoGetValue(const AFieldName: string; var AValue: variant);
begin
  AValue := Null;
end;

procedure TFPReportData.DoInitDataFields;
begin
  // Do nothing.
end;

procedure TFPReportData.DoOpen;
begin
  // Do nothing
end;

procedure TFPReportData.DoFirst;
begin
  // Do nothing
end;

procedure TFPReportData.DoNext;
begin
  // Do nothing
end;

procedure TFPReportData.DoClose;
begin
  // Do nothing
end;

function TFPReportData.DoEOF: boolean;
begin
  Result := False;
end;

constructor TFPReportData.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDatafields := CreateDataFields;
  FDatafields.FReportData := Self;
end;

destructor TFPReportData.Destroy;
begin
  FreeAndNil(FDatafields);
  inherited Destroy;
end;

procedure TFPReportData.InitFieldDefs;
begin
  if FIsOpened then
    ReportError(SErrInitFieldsNotAllowedAfterOpen);
  DoInitDataFields;
end;

procedure TFPReportData.Open;
begin
  if Assigned(FOnOpen) then
    FOnOpen(Self);
  DoOpen;
  InitFieldDefs;
  FIsOpened := True;
  FRecNo := 1;
end;

procedure TFPReportData.First;
begin
  if Assigned(FOnFirst) then
    FOnFirst(Self);
  DoFirst;
  FRecNo := 1;
end;

procedure TFPReportData.Next;
begin
  Inc(FRecNo);
  if Assigned(FOnNext) then
    FOnNext(Self);
  DoNext;
end;

procedure TFPReportData.Close;
begin
  if Assigned(FOnClose) then
    FOnClose(Self);
  DoClose;
  FIsOpened := False;
  FRecNo := -1;
end;

function TFPReportData.EOF: boolean;
begin
  Result := False;
  if Assigned(FOnGetEOF) then
    FOnGetEOF(Self, Result);
  if not Result then
    Result := DoEOF;
end;

procedure TFPReportData.GetFieldList(List: TStrings);
var
  I: integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    for I := 0 to FDataFields.Count - 1 do
      List.add(FDataFields[I].FieldName);
  finally
    List.EndUpdate;
  end;
end;

function TFPReportData.IndexOfField(const AFieldName: string): Integer;
begin
  Result:=  FDataFields.IndexOfField(AFieldName);
end;

function TFPReportData.HasField(const AFieldName: string): boolean;
begin
  Result := FDataFields.IndexOfField(AFieldName) <> -1;
end;


{ TFPReportClassMapping }

function TFPReportClassMapping.IndexOfExportRenderer(
  AClass: TFPReportExporterClass): Integer;
begin
  Result:=Length(FRenderers)-1;
  While (Result>=0) and (FRenderers[Result].aClass<>AClass) do
    Dec(Result);
end;

constructor TFPReportClassMapping.Create(const AMappingName: string; AElementClass: TFPReportElementClass);
begin
  FMappingName :=  AMappingName;
  FReportElementClass := AElementClass;
end;

function TFPReportClassMapping.AddRenderer(aExporterClass: TFPReportExporterClass; aCallback: TFPReportElementExporterCallBack ): TFPReportElementExporterCallBack;

Var
  I : Integer;

begin
  Result:=nil;
  I:=IndexOfExportRenderer(aExporterClass);
  if (I=-1) then
    begin
    I:=Length(FRenderers);
    SetLength(FRenderers,I+1);
    FRenderers[i].aClass:=aExporterClass;
    FRenderers[i].aCallback:=Nil;
    end;
  Result:=FRenderers[i].aCallback;
  FRenderers[i].aCallback:=aCallback;
end;

function TFPReportClassMapping.FindRenderer(aClass: TFPReportExporterClass): TFPReportElementExporterCallBack;

Var
  I : Integer;

begin
  I:=IndexOfExportRenderer(aClass);
  if I<>-1 then
    Result:=FRenderers[I].aCallback
  else
    Result:=Nil;
end;

{ TFPReportElementFactory }

function TFPReportElementFactory.GetM(Aindex : integer): TFPReportClassMapping;
begin
  Result:=TFPReportClassMapping(FList[AIndex]);
end;

function TFPReportElementFactory.IndexOfElementName(const AElementName: string): Integer;

begin
  Result:=Flist.Count-1;
  While (Result>=0) and not SameText(Mappings[Result].MappingName, AElementName) do
    Dec(Result);
end;

function TFPReportElementFactory.IndexOfElementClass(const AElementClass: TFPReportElementClass): Integer;

begin
  Result:=Flist.Count-1;
  While (Result>=0) and (Mappings[Result].ReportElementClass<>AElementClass) do
    Dec(Result);
end;

constructor TFPReportElementFactory.Create;
begin
  FList := TFPObjectList.Create;
end;

destructor TFPReportElementFactory.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TFPReportElementFactory.FindRenderer(aClass: TFPReportExporterClass;
  AElement: TFPReportElementClass): TFPReportElementExporterCallBack;

Var
  I : Integer;

begin
  Result:=nil;
  I:=IndexOfElementClass(aElement);
  if I<>-1 then
    Result:=Mappings[i].FindRenderer(aClass);
end;

function TFPReportElementFactory.FindImageRenderer(
  AElement: TFPReportElementClass): TFPReportImageRenderCallBack;
Var
  I : Integer;

begin
  Result:=nil;
  I:=IndexOfElementClass(aElement);
  if I<>-1 then
    Result:=Mappings[i].ImageRenderCallback;
end;

function TFPReportElementFactory.RegisterImageRenderer(AElement: TFPReportElementClass; ARenderer: TFPReportImageRenderCallBack
  ): TFPReportImageRenderCallBack;
Var
  I : Integer;
begin
  Result:=nil;
  I:=IndexOfElementClass(aElement);
  if I<>-1 then
    begin
    Result:=Mappings[i].ImageRenderCallback;
    Mappings[i].ImageRenderCallback:=ARenderer;
    end;
end;

function TFPReportElementFactory.RegisterElementRenderer(AElement: TFPReportElementClass; ARenderClass: TFPReportExporterClass;
  ARenderer: TFPReportElementExporterCallBack): TFPReportElementExporterCallBack;
Var
  I : Integer;
begin
  Result:=nil;
  I:=IndexOfElementClass(aElement);
  if (I<>-1) then
    Result:=Mappings[i].AddRenderer(aRenderClass,ARenderer);
end;

procedure TFPReportElementFactory.RegisterEditorClass(const AElementName: string; AEditorClass: TFPReportElementEditorClass);

Var
  I : integer;

begin
  I:=IndexOfElementName(aElementName);
  if I<>-1 then
    Mappings[i].EditorClass:=AEditorClass
  else
    Raise EReportError.CreateFmt(SErrUnknownElementName,[AElementName]);
end;

procedure TFPReportElementFactory.RegisterEditorClass(AReportElementClass: TFPReportElementClass;
  AEditorClass: TFPReportElementEditorClass);

Var
  I : integer;

begin
  I:=IndexOfElementClass(aReportElementClass);
  if I<>-1 then
    Mappings[i].EditorClass:=AEditorClass
  else
    if AReportElementClass<>Nil then
      Raise EReportError.CreateFmt(SErrUnknownElementClass,[AReportElementClass.ClassName])
    else
      Raise EReportError.CreateFmt(SErrUnknownElementClass,['Nil']);
end;

procedure TFPReportElementFactory.UnRegisterEditorClass(const AElementName: string; AEditorClass: TFPReportElementEditorClass);

Var
  I : integer;

begin
  I:=IndexOfElementName(aElementName);
  if I<>-1 then
    if Mappings[i].EditorClass=AEditorClass then
      Mappings[i].EditorClass:=nil;
end;

procedure TFPReportElementFactory.UnRegisterEditorClass(AReportElementClass: TFPReportElementClass;
  AEditorClass: TFPReportElementEditorClass);
Var
  I : integer;

begin
  I:=IndexOfElementClass(aReportElementClass);
  if I<>-1 then
    if Mappings[i].EditorClass=AEditorClass then
      Mappings[i].EditorClass:=nil;
end;

procedure TFPReportElementFactory.RegisterClass(const AElementName: string; AReportElementClass: TFPReportElementClass);
var
  i: integer;
begin
  I:=IndexOfElementName(AElementName);
  if I<>-1 then exit;
  FList.Add(TFPReportClassMapping.Create(AElementName, AReportElementClass));
end;

function TFPReportElementFactory.CreateInstance(const AElementName: string; AOwner: TComponent): TFPReportElement;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FList.Count - 1 do
  begin
    if SameText(Mappings[I].MappingName, AElementName) then
    begin
      Result := Mappings[I].ReportElementClass.Create(AOwner);
      Break; //==>
    end;
  end;
  if Result = nil then
    ReportError(SErrRegisterUnknownElement, [AElementName]);
end;

function TFPReportElementFactory.FindEditorClassForInstance(AInstance: TFPReportElement): TFPReportElementEditorClass;
begin
  if AInstance<>Nil then
    Result:=FindEditorClassForInstance(TFPReportElementClass(Ainstance.ClassType))
  else
    Result:=Nil;
end;

function TFPReportElementFactory.FindEditorClassForInstance(AClass: TFPReportElementClass): TFPReportElementEditorClass;

Var
  I : Integer;

begin
  I:=IndexOfElementClass(AClass);
  if I<>-1 then
    Result:=Mappings[I].EditorClass
  else
    Result:=nil;
end;

procedure TFPReportElementFactory.AssignReportElementTypes(AStrings: TStrings);
var
  i: integer;
begin
  AStrings.Clear;
  for i := 0 to FList.Count - 1 do
    AStrings.Add(Mappings[I].MappingName);
end;

{ TFPReportCustomDataHeaderBand }

function TFPReportCustomDataHeaderBand.GetReportBandName: string;
begin
  Result := 'DataHeaderBand';
end;

class function TFPReportCustomDataHeaderBand.ReportBandType: TFPReportBandType;
begin
  Result:=btDataHeader;
end;

{ TFPReportCustomDataFooterBand }

function TFPReportCustomDataFooterBand.GetReportBandName: string;
begin
  Result := 'DataFooterBand';
end;

class function TFPReportCustomDataFooterBand.ReportBandType: TFPReportBandType;
begin
  Result:=btDataFooter;
end;

{ A function borrowed from fpGUI Toolkit. }
function fpgDarker(const AColor: TFPReportColor; APercent: Byte): TFPReportColor;

  function GetRed(const c: TFPReportColor): Byte; inline;
  begin
    Result := (c shr 16) and $FF;
  end;

  function GetGreen(const c: TFPReportColor): Byte; inline;
  begin
    Result := (c shr 8) and $FF;
  end;

  function GetBlue(const c: TFPReportColor): Byte; inline;
  begin
    Result := c and $FF;
  end;

var
  r, g, b: Byte;
begin
  r := GetRed(AColor);
  g := GetGreen(AColor);
  b := GetBlue(AColor);

  r := Round(r*APercent/100);
  g := Round(g*APercent/100);
  b := Round(b*APercent/100);

  Result := b or (g shl 8) or (r shl 16);
end;


{ Defines colors that can be used by a report designer or demos. }
procedure SetupBandRectColors;
var
  i: TFPReportBandType;
begin
  for i := Low(TFPReportBandType) to High(TFPReportBandType) do
    DefaultBandRectangleColors[i] := fpgDarker(DefaultBandColors[i], 70);
end;


initialization
  uElementFactory := nil;
  gElementFactory.RegisterClass('ReportTitleBand', TFPReportTitleBand);
  gElementFactory.RegisterClass('ReportSummaryBand', TFPReportSummaryBand);
  gElementFactory.RegisterClass('GroupHeaderBand', TFPReportGroupHeaderBand);
  gElementFactory.RegisterClass('GroupFooterBand', TFPReportGroupFooterBand);
  gElementFactory.RegisterClass('DataBand', TFPReportDataBand);
  gElementFactory.RegisterClass('ChildBand', TFPReportChildBand);
  gElementFactory.RegisterClass('PageHeaderBand', TFPReportPageHeaderBand);
  gElementFactory.RegisterClass('PageFooterBand', TFPReportPageFooterBand);
  gElementFactory.RegisterClass('DataHeaderBand', TFPReportDataHeaderBand);
  gElementFactory.RegisterClass('DataFooterBand', TFPReportDataFooterBand);
  gElementFactory.RegisterClass('ColumnHeaderBand', TFPReportColumnHeaderBand);
  gElementFactory.RegisterClass('ColumnFooterBand', TFPReportColumnFooterBand);
  gElementFactory.RegisterClass('Memo', TFPReportMemo);
  gElementFactory.RegisterClass('Image', TFPReportImage);
  gElementFactory.RegisterClass('Checkbox', TFPReportCheckbox);
  gElementFactory.RegisterClass('Shape', TFPReportShape);
  SetupBandRectColors;

finalization
  DoneReporting;
  uBandFactory.Free;
  uElementFactory.Free;
  EM.Free;

end.
