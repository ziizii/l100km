import 'dart:async';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:fuelly_gdocs/google_drive.dart';

@Component(selector: 'add-record')
@View(templateUrl: "add_record.html", directives: const [materialDirectives])
class AddRecordComponent implements OnInit {
  GoogleSheetsService drive;

  AddRecordComponent(this.drive);

  @ViewChild("odometer")
  MaterialInputComponent odometer;

  @ViewChild("totalPrice")
  MaterialInputComponent totalPrice;

  @ViewChild("litres")
  MaterialInputComponent litres;

  StringSelectionOptions<String> carOptions = new StringSelectionOptions([]);
  SelectionModel<String> selectedCar = new SelectionModel.withList(selectedValues: []);
  String get carSelectButtonText => selectedCar.selectedValues.isEmpty ? "Vyberte auto" : selectedCar.selectedValues.first;

  String newCar = "";
  namedCar(String inputText) {
    newCar = inputText;
  }

  createNewCar() async {
    await drive.createNewCar(newCar);
    await loadCars();
  }

  @override
  ngOnInit() async {
    await loadCars();

    if (carOptions.isNotEmpty) {
      selectedCar.select(carOptions.optionsList.first);
    }

  }

  loadCars() async {
    carOptions = new StringSelectionOptions(await drive.listCars());
  }

  int odoValue;
  double priceValue;
  double lValue;

  addRecord() async {
    var rec = new Record(
      odo: odoValue,
      litres:  lValue,
      totalPrice: priceValue,
      car: selectedCar.selectedValues.first,
    );

    drive.addRecord(rec);
  }

}