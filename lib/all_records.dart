import 'dart:math';

import 'package:angular2/core.dart';
import 'package:angular_components/angular_components.dart';

import 'google_drive.dart';
import 'pipes.dart';

@Component(selector: 'all-records', templateUrl: 'all_records.html',
    directives: const [materialDirectives],
    pipes: const [CurrencyPipe, DistancePipe, DatePipe, LitresPipe],
    styleUrls: const ['all_records.css', 'common.css']
)
class AllRecordsComponent implements OnInit {
  GoogleSheetsService drive;

  List<Record> allRecords = [];

  AllRecordsComponent(this.drive);

  @override
  ngOnInit() async {
    drive.onRecord.listen((records)=>allRecords = records);
    drive.loadAllRecords();
  }

  int get totalKm {
    var maxOdo = allRecords.map((r)=>r.odo).reduce(max);
    var minOdo = allRecords.map((r)=>r.odo).reduce(min);

    return maxOdo - minOdo;
  }

  Record get firstFuelup => allRecords.last;
  double get totalLitres => allRecords.map((r)=>r.litres).reduce(sum);
  double get totalPrice => allRecords.map((r)=>r.litres*r.price).reduce(sum);
  double get lastl100Km => allRecords.first.l100Km;
  double get bestl100Km => allRecords.map((r)=> r.l100Km == null ? double.INFINITY : r.l100Km ).reduce(min);

  double get totall100Km => (totalLitres - firstFuelup.litres) / totalKm * 100;
  double get avgPricePerKm => (totalPrice - firstFuelup.price*firstFuelup.litres) / totalKm;

  double sum(num a, num b) => a.toDouble() + b.toDouble();
}