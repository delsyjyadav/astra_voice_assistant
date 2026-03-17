import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main(){
  runApp(const AstraApp());

}

class AstraApp extends StatelessWidget{

  const AstraApp({super.key});


  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'ASTRA Voice Assistant',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: AppColors.neonPink,
      fontFamily: 'Poppins',
    );
  }
}



class AppColors {
  static const neonPink = Color(0xFF1457FF);
  static const lightPink = Color(0xFF68C0E6);

  static Color neonPinkWithOpacity(double opacity) => neonPink.withOpacity(opacity);
  static Color lightPinkWithOpacity(double opacity) => lightPink.withOpacity(opacity);
}