import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    debugPrint('Firebase nao inicializado: $error');
  }

  runApp(const TaFeitoApp());
}
