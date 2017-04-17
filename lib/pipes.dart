import 'package:angular2/core.dart';
import 'package:intl/intl_browser.dart';
import 'package:intl/intl.dart';

@Pipe("currency")
class CurrencyPipe extends PipeTransform {
  String transform(dynamic value) {
    if (value == null) return "";
    return new NumberFormat("###,###,##0.00", "cs").format(value);
//    return new NumberFormat.currency(name: "", locale: "cs", symbol: "", decimalDigits: 2).format(value);
  }
}

@Pipe("km")
class DistancePipe extends PipeTransform {
  String transform(dynamic value) {
    if (value == null) return "";
    return new NumberFormat("###,###,##0", "cs").format(value);
  }
}




@Pipe("litres")
class LitresPipe extends PipeTransform {
  String transform(dynamic value) {
    if (value == null) return "";
    return new NumberFormat("###,###,##0.0", "cs").format(value);
  }
}




@Pipe("date")
class DatePipe extends PipeTransform {
  String transform(dynamic value) {
    if (value == null) return "";
    return new DateFormat("dd.MM.yyyy").format(value);
  }
}