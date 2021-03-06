import 'dart:html';

import 'package:angular2/core.dart';
import 'package:angular_components/angular_components.dart';

import 'google_drive.dart';

@Component(selector: 'add-record', templateUrl: "add_record.html", directives: const [materialDirectives, materialInputDirectives], styleUrls: const ['common.css'])
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
  bool showAddRecordModal = false;

  String newCar = "";

  namedCar(String inputText) {
    newCar = inputText;
  }

  createNewCar() async {
    await drive.createNewCar(newCar);
    await loadCars();
  }

  FormElement get addRecordForm => (querySelector("#recordForm") as FormElement);

  HtmlElement get addRecordButton => (querySelector("#addButton") as HtmlElement);

  showAddForm() async {
    selectFirstCarIfNotSelected();
    showAddRecordModal = true;
    drive.ga.sendEvent("all", "showModal");
    getInput(odometer)
      ..type = "number"
      ..pattern = "[0-9]*";

//    getInput(totalPrice).type = "number";
//    getInput(litres).type = "number";
  }

  InputElement getInput(MaterialInputComponent c) => c.inputRef.nativeElement as InputElement;

  hideAddForm() {
    showAddRecordModal = false;
    addRecordForm.reset();
  }

  @override
  ngOnInit() async {
    await loadCars();
    selectFirstCarIfNotSelected();
  }

  selectFirstCarIfNotSelected() async {
    if (!carOptions.isNotEmpty) {
      await loadCars();
    }
    if (carOptions.isNotEmpty && selectedCar.isEmpty) {
      selectedCar.select(carOptions.optionsList.first);
    }
  }

  loadCars() async {
    carOptions = new StringSelectionOptions(await drive.listCars());
  }

  String odoValue;
  String priceValue;
  String lValue;

  String error;

  addRecord() async {
    try {
      var rec = new Record(
        odo: int.parse(odoValue),
        litres: double.parse(lValue),
        totalPrice: double.parse(priceValue),
        car: selectedCar.selectedValues.first,
      );
      await drive.addRecord(rec);
      hideAddForm();

      error = "";
    } catch (e) {
      error =
      "Vytvoření záznamu se nezdařilo. Ujistěte se, že stav tachometru je celé číslo, počet litrů a cena může být desetinné a že máte vybrané auto.";
    }
  }

}