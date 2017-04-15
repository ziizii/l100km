import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:fuelly_gdocs/google_drive.dart';
import 'package:fuelly_gdocs/pipes.dart';
import 'dart:math';

@Component(selector: 'all-records')
@View(templateUrl: 'all_records.html',
    directives: const [materialDirectives],
    pipes: const [CurrencyPipe, DistancePipe, DatePipe],
    styleUrls: const ['all_records.css']
)
class AllRecordsComponent implements OnInit {
  GoogleSheetsService drive;

  List<Record> allRecords = [];

  AllRecordsComponent(this.drive);

  @override
  ngOnInit() async {
    allRecords = await drive.loadAllRecords();
  }

  int get totalKm {
    var maxOdo = allRecords.map((r)=>r.odo).reduce(max);
    var minOdo = allRecords.map((r)=>r.odo).reduce(min);

    return maxOdo - minOdo;
  }

  double get totalLitres => allRecords.map((r)=>r.litres).reduce(sum);
  double get totalPrice => allRecords.map((r)=>r.litres*r.price).reduce(sum);
  double get totall100Km => totalLitres / totalKm * 100;
  double get lastl100Km => allRecords.first.l100Km;
  double get bestl100Km => allRecords.map((r)=> r.l100Km == null ? 999999999 : r.l100Km ).reduce(min);
  double get avgPricePerKm => totalPrice / totalKm;

  double sum(num a, num b) => a.toDouble() + b.toDouble();
}