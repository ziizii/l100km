// Copyright (c) 2017, ziizii. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:html';

import 'package:angular2/core.dart';
import 'package:angular2_components/angular2_components.dart';
import 'package:usage/usage_html.dart';

import 'add_record.dart';
import 'all_records.dart';
import 'google_drive.dart';
import 'indicator.dart';

@Component(
  selector: 'my-app',
  styleUrls: const ['app_component.css', 'common.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, AddRecordComponent, AllRecordsComponent, Indicator],
  providers: const [materialProviders],
)
class AppComponent implements OnInit {

  @ViewChild("addRecord")
  AddRecordComponent addRecord;

  @ViewChild("allRecords")
  AllRecordsComponent allRecords;

  GoogleSheetsService drive;

  AppComponent(this.drive);

  bool githubVisible = false;

  @override
  ngOnInit() async {
    _computeGithubVisible();
    window.onResize.listen(_computeGithubVisible);

    drive.ga.sendScreenView("main");
    await drive.initialized;
  }

  static const bodyMaxWidth = 700;
  static const githubRibbonWidth = 180;
  _computeGithubVisible([_]) {
    githubVisible = querySelector("html").clientWidth > bodyMaxWidth + 2 * githubRibbonWidth;
  }
}
