import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:fuelly_gdocs/google_drive.dart';

@Component(selector: "indicator")
@View(templateUrl: 'indicator.html', directives: const [materialDirectives])
class Indicator implements OnInit {

  GoogleSheetsService _rest;
  int requestCounter = 0;

  Indicator(this._rest);

  @override
  ngOnInit() {
    hide();

    _rest.onRequestStart.listen((r){
      requestCounter++;
      print("Start: $requestCounter");
      runIn100ms(showIndicatorIfNeeded);
    });

    _rest.onRequestEnd.listen((r){
      requestCounter--;
      print("End: $requestCounter");

      runIn100ms(hideIndicatorIfNeeded);
    });
  }

  hideIndicatorIfNeeded() {
    if (requestCounter <= 0) {
      requestCounter = 0;
      hide();
    }
  }

  showIndicatorIfNeeded() {
    if (requestCounter > 0) {
      show();
    }
  }

  bool hidden = true;

  hide() {
    hidden = true;
  }

  show() {
    hidden = false;
  }

  Element get overlay => querySelector(".indicatorWrapper");

  runIn100ms(method()) => runAfter(method, duration: new Duration(milliseconds: 100));
  runIn200ms(method()) => runAfter(method, duration: new Duration(milliseconds: 200));

  runAfter(method(), {Duration duration}) => new Future.delayed(duration).whenComplete(method);

}