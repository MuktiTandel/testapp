import 'package:flutter/material.dart';
import 'package:testapp/core/elements/custom_dropdown.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  final List<String> items = [
    'Male',
    'Female',
    'Other',
  ];

  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: DropdownButtonHideUnderline(
            child: CustomDropdwon(
              isExpanded: true,
              buttonPadding: EdgeInsets.only(left: 10),
              hint: Text('Choose Gender',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black
                ),
              ),
              items: items.map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e)
              )).toList(),
              value: selectedValue,
              onChanged: (val){
                setState(() {
                  selectedValue = val;
                });
              },
              dropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              buttonDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}