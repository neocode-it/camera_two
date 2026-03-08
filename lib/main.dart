import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:outtake/core/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize intl package for German locale formatting
  await initializeDateFormatting('de_DE', null);
  
  runApp(MainApp());
}
