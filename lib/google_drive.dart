import 'dart:async';

import 'dart:convert';
import 'dart:html';
import 'package:angular2/core.dart';
import 'package:fuelly_gdocs/constants.dart' as constants;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:intl/intl.dart';

@Injectable()
class GoogleSheetsService {

  static const scopes = const [sheets.SheetsApi.SpreadsheetsScope, drive.DriveApi.DriveReadonlyScope];
  sheets.SheetsApi _sheetsApi;
  drive.DriveApi _driveApi;
  bool isLoggedIn = false;
  Future initialized;

  auth.ClientId get id => new auth.ClientId(constants.clientId, null);

  GoogleSheetsService() {
    initialized = login(withPopup: false);
  }

  Future<auth.AutoRefreshingAuthClient> authorizedClient({immediate: true}) async {
    var flow = await auth.createImplicitBrowserFlow(id, scopes);
    var client = flow.clientViaUserConsent(immediate: immediate);
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

      await findSheetId();
    }
  }

  String _sheetId;
  Future<String> findSheetId() async {
    if (_sheetId != null) {
      return _sheetId;
    }

    var allFiles = await _driveApi.files.list(q: "trashed != true and name = '${constants.spreadsheetName}'");
    var fuelSheetList = allFiles.files.where((f)=>f.name == constants.spreadsheetName);
    fuelSheetList.forEach((f)=>print(f.toJson()));

    if (fuelSheetList.isEmpty) {
      print("Creating new sheet");
      var newSpreadsheet = new sheets.Spreadsheet();
      newSpreadsheet.sheets = [_createFuelupsSheet(), _createCarsSheet()];

      newSpreadsheet.properties = new sheets.SpreadsheetProperties();
      newSpreadsheet.properties..title = constants.spreadsheetName
        ..defaultFormat = (new sheets.CellFormat()..backgroundColor = (new sheets.Color()..blue=0.1 ..green=0.1 ..red=0.1 ..alpha=0.1));

      print(newSpreadsheet.properties.toJson());
      var createdSheet = await _sheetsApi.spreadsheets.create(newSpreadsheet);

      _sheetId = createdSheet.spreadsheetId;
    } else {
      _sheetId = fuelSheetList.first.id;
    }

    return _sheetId;
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
      constants.FuelUps.headerLocation,
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
    var id = await findSheetId();
    var range = "'${constants.Cars.sheetName}'!A:A";
    sheets.ValueRange carsColumn = await _sheetsApi.spreadsheets.values.get(id, range, majorDimension: "COLUMNS");

    var allRows = carsColumn.values.first;
    return allRows.skip(1).toList();
  }

  createNewCar(String newCarName) async {
    var id = await findSheetId();

    var valueRange = new sheets.ValueRange();
    valueRange.values = [[newCarName]];
    
    _sheetsApi.spreadsheets.values.append(valueRange, id, "'${constants.Cars.sheetName}'!A:A", valueInputOption: "USER_ENTERED");
  }

  Future<List<Record>> loadAllRecords() async {
    var id = await findSheetId();

    var values = await _sheetsApi.spreadsheets.values.get(id, "'${constants.FuelUps.sheetName}'!A:F");
    print(values.values.first);
    var locationIndex = values.values.first.indexOf(constants.FuelUps.headerLocation);
//    var l100kmIndex = values.values.first.indexOf(constants.FuelUps.headerL100km);
    var odoIndex = values.values.first.indexOf(constants.FuelUps.headerOdo);
    var priceIndex = values.values.first.indexOf(constants.FuelUps.headerPrice);
    var litresIndex = values.values.first.indexOf(constants.FuelUps.headerLitres);
    var dateIndex = values.values.first.indexOf(constants.FuelUps.headerDate);
    var carIndex = values.values.first.indexOf(constants.FuelUps.headerCar);

    var dateFormat = new DateFormat("y-M-d H:m:s");

    var records = values.values.skip(1).map((List row) {
      var location = row.length >= locationIndex + 1 ? row[locationIndex] : null;
      return new Record(
          location: location,
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


  /*
      constants.FuelUps.headerCar,
      constants.FuelUps.headerDate,
      constants.FuelUps.headerLitres,
      constants.FuelUps.headerPrice,
      constants.FuelUps.headerOdo,
      constants.FuelUps.headerL100km,
      constants.FuelUps.headerLocation,
   */
  addRecord(Record record) async {
    var timeout = new Duration(seconds: 5);
    var maxAge = new Duration(minutes: 10);

    var location;
    var currentPositionFuture = window.navigator.geolocation.getCurrentPosition(enableHighAccuracy: false, timeout: timeout, maximumAge: maxAge);
    
    try {
      location = await currentPositionFuture;
    } catch (e) {
      print(e);
    }


    var id = await findSheetId();

    var valueRange = new sheets.ValueRange();
    valueRange.values = [[
      record.car,
      record.date.toLocal().toString(),
      record.litres,
      record.totalPrice / record.litres,
      record.odo,
      location?.coords != null ? "${location.coords.latitude},${location.coords.longitude}" : null
    ]];

    _sheetsApi.spreadsheets.values.append(valueRange, id, "'${constants.FuelUps.sheetName}'!A:G", valueInputOption: "USER_ENTERED");

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