// Copyright (c) 2017, ziizii. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'dart:html';
import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:fuelly_gdocs/add_record.dart';
import 'package:fuelly_gdocs/all_records.dart';
import 'package:fuelly_gdocs/google_drive.dart';
import 'package:fuelly_gdocs/indicator.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css', 'common.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, AddRecordComponent, AllRecordsComponent, Indicator],
  providers: const [materialProviders],
)
class AppComponent implements OnInit {

  GoogleSheetsService drive;

  AppComponent(this.drive);

  @ViewChild("login")
  MaterialButtonComponent loginButton;

  @override
  ngOnInit() async {
    await drive.initialized;
  }
}
