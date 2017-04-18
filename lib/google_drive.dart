import 'dart:async';

import 'package:angular2/core.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis_auth/auth_browser.dart';
import 'package:intl/intl.dart';

import 'constants.dart' as constants;
import 'package:usage/usage_html.dart';

@Injectable()
class GoogleSheetsService {

  static final StreamController _requestStart = new StreamController.broadcast();
  static final StreamController _requestEnd = new StreamController.broadcast();

  Stream get onRequestStart => _requestStart.stream;
  Stream get onRequestEnd => _requestEnd.stream;

  static const scopes = const [sheets.SheetsApi.SpreadsheetsScope, drive.DriveApi.DriveReadonlyScope];
  sheets.SheetsApi _sheetsApi;
  drive.DriveApi _driveApi;
  bool isLoggedIn = null;

  auth.ClientId get id => new auth.ClientId(constants.clientId, null);

  Future<BrowserOAuth2Flow> _flowFuture;
  BrowserOAuth2Flow _flow;
  var ga = new AnalyticsHtml("UA-56265300-1", "l100km", "1.0");

  GoogleSheetsService() {
    init();
  }

  init() async {
    _flowFuture = auth.createImplicitBrowserFlow(id, scopes);
    _flowFuture.then((f){
      _flow = f;
      login(withPopup: false);
    });
  }

  Future get initialized => _flowFuture;

  Future<auth.AutoRefreshingAuthClient> authorizedClient({immediate: true}) async {
    var client = (_flow).clientViaUserConsent(immediate: immediate);
    client
        .then((_) => isLoggedIn = true)
        .catchError((e) => print(e));
    return client;
  }

  login({withPopup: true}) async {
    var client = await authorizedClient(immediate: !withPopup);

    if (isLoggedIn) {
      _sheetsApi = new sheets.SheetsApi(client);
      _driveApi = new drive.DriveApi(client);

      findSheetId();
      loadAllRecords().then((records)=>recordStreamController.add(records));
    }
  }

  static Completer<String> _sheetCompleter = new Completer();
  Future<String> _sheetId = _sheetCompleter.future;

  findSheetId() async {
    var allFiles = await indicator(_driveApi.files.list(q: "trashed != true and name = '${constants.spreadsheetName}'"));
    var fuelSheetList = allFiles.files.where((f)=>f.name == constants.spreadsheetName);

    if (fuelSheetList.isEmpty) {
      var newSpreadsheet = new sheets.Spreadsheet();
      newSpreadsheet.sheets = [_createFuelupsSheet(), _createCarsSheet()];

      newSpreadsheet.properties = new sheets.SpreadsheetProperties();
      newSpreadsheet.properties..title = constants.spreadsheetName;

      var createdSheet = await indicator(_sheetsApi.spreadsheets.create(newSpreadsheet));
      _sheetCompleter.complete(createdSheet.spreadsheetId);
    } else {
      _sheetCompleter.complete(fuelSheetList.first.id);
    }
  }

  Future indicator(Future future) {
    startRequest();
    return future.whenComplete(endRequest);
  }

  void endRequest() {
    _requestEnd.add(new DateTime.now());
  }

  void startRequest() {
    _requestStart.add(new DateTime.now());
  }

  sheets.Sheet _createCarsSheet() {
    var carsSheet = _createSheet(constants.Cars.sheetName);
    _addHeaders(carsSheet, [
      constants.Cars.headerName,
    ]);
    return carsSheet;
  }

  sheets.Sheet _createFuelupsSheet() {
    var fuelupsSheet = _createSheet(constants.FuelUps.sheetName);
    _addHeaders(fuelupsSheet, [
      constants.FuelUps.headerCar,
      constants.FuelUps.headerDate,
      constants.FuelUps.headerLitres,
      constants.FuelUps.headerPrice,
      constants.FuelUps.headerOdo,
    ]);
    return fuelupsSheet;
  }

  List<sheets.CellData> _createStringCells(Iterable<String> texts) {
    List<sheets.CellData> ret = [];
    for (String text in texts) {
      ret.add(_createStringCell(text));
    }
    return ret;
  }

  sheets.CellData _createStringCell(String text) {
    var cellData = new sheets.CellData();

    cellData.userEnteredValue = new sheets.ExtendedValue()
      ..stringValue = text;

    return cellData;
  }

  sheets.Sheet _createSheet(String title) {
    var sheet = new sheets.Sheet();
    sheet.properties = new sheets.SheetProperties()
      ..title = title
      ..gridProperties = (new sheets.GridProperties()..frozenRowCount = 1);
    return sheet;
  }

  void _addHeaders(sheets.Sheet sheet, List<String> headers) {

    var gridData = new sheets.GridData()
      ..startColumn = 0
      ..startRow = 0
      ..rowData = [
        new sheets.RowData()..values = _createStringCells(headers)
      ];

    sheet.data = [gridData];
  }

  Future<List<String>> listCars() async {
    var id = await _sheetId;
    var range = "'${constants.Cars.sheetName}'!A:A";
    sheets.ValueRange carsColumn = await indicator(_sheetsApi.spreadsheets.values.get(id, range, majorDimension: "COLUMNS"));

    var allRows = carsColumn.values.first;
    return allRows.skip(1).toList();
  }

  createNewCar(String newCarName) async {
    var id = await _sheetId;

    var valueRange = new sheets.ValueRange();
    valueRange.values = [[newCarName]];
    await indicator(_sheetsApi.spreadsheets.values.append(valueRange, id, "'${constants.Cars.sheetName}'!A:A", valueInputOption: "USER_ENTERED"));
  }

  static final StreamController<List<Record>> recordStreamController = new StreamController<List<Record>>.broadcast();
  Stream<List<Record>> get onRecord => recordStreamController.stream;

  Future<List<Record>> loadAllRecords() async {
    var id = await _sheetId;

    var values = await indicator(_sheetsApi.spreadsheets.values.get(id, "'${constants.FuelUps.sheetName}'!A:F"));
    print(values.values.first);
    var odoIndex = values.values.first.indexOf(constants.FuelUps.headerOdo);
    var priceIndex = values.values.first.indexOf(constants.FuelUps.headerPrice);
    var litresIndex = values.values.first.indexOf(constants.FuelUps.headerLitres);
    var dateIndex = values.values.first.indexOf(constants.FuelUps.headerDate);
    var carIndex = values.values.first.indexOf(constants.FuelUps.headerCar);

    var dateFormat = new DateFormat("y-M-d H:m:s");

    var records = values.values.skip(1).map((List row) {
      return new Record(
          odo: int.parse(row[odoIndex]),
          price: double.parse(row[priceIndex]),
          litres: double.parse(row[litresIndex]),
          date: dateFormat.parse(row[dateIndex]),
          car: row[carIndex]
      );
    }).toList();

    int lastOdo;
    for (Record r in records) {
      if (lastOdo != null) {
        r.l100Km = r.litres / (r.odo-lastOdo) * 100;
      }
      lastOdo = r.odo;
    }

    return records.reversed.toList();
  }

  addRecord(Record record) async {
    var id = await _sheetId;

    var valueRange = new sheets.ValueRange();
    valueRange.values = [[
      record.car,
      record.date.toLocal().toString(),
      record.litres,
      record.totalPrice / record.litres,
      record.odo
    ]];
    ga.sendEvent("all", "addRecord");
    await indicator(_sheetsApi.spreadsheets.values.append(valueRange, id, "'${constants.FuelUps.sheetName}'!A:G", valueInputOption: "USER_ENTERED"));
    loadAllRecords().then((records)=>recordStreamController.add(records));
  }
    
}

class Record {
  String location;
  double l100Km;
  int odo;
  double price;
  double totalPrice ;
  double litres;
  DateTime date;
  String car;

  Record({this.location, this.l100Km, this.odo, this.price, this.litres, this.date, this.car, this.totalPrice}) {
    if (date == null) {
      date = new DateTime.now();
    }
  }

  @override
  String toString() {
    return 'Record{location: $location, l100Km: $l100Km, odo: $odo, price: $price, litres: $litres, date: $date, car: $car}';
  }
}