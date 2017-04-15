// Copyright (c) 2017, ziizii. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:angular2/platform/browser.dart';

import 'package:fuelly_gdocs/app_component.dart';
import 'package:fuelly_gdocs/google_drive.dart';

void main() {
  bootstrap(AppComponent, [
    GoogleSheetsService
  ]);
}
