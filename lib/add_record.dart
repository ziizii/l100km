import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:fuelly_gdocs/google_drive.dart';

@Component(selector: 'add-record')
@View(templateUrl: "add_record.html", directives: const [materialDirectives], styleUrls: const ['common.css'])
class AddRecordComponent implements OnInit {
  GoogleSheetsService drive;

  AddRecordComponent(this.drive);

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

  String odoValue;
  String priceValue;
  String lValue;

  String error;

  addRecord() async {
    try {
      var rec = new Record(
        odo: int.parse(odoValue),
        litres:  double.parse(lValue),
        totalPrice: double.parse(priceValue),
        car: selectedCar.selectedValues.first,
      );
      drive.addRecord(rec);
      error = "";
    } catch (e) {
      error = "Vytvoření záznamu se nezdařilo. Ujistěte se, že stav tachometru je celé číslo, počet litrů a cena může být desetinné a že máte vybrané auto.";
    }
  }

}