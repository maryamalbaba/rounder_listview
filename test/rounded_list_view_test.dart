import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rounded_list_view/Rounded_List_View.dart';

void main() {
  List<String>numbers=["1","5","11","20","1","5","11","20","1","5","11","20"];
  test('', () {
    final mycircle =CircleListScrollView(itemExtent: 100, children: List.generate(numbers.length, (index) => Container(
  width: 150,
  height: 100,
  //color: Colors.pink,
  child: Center(child: Text(numbers[index],style: TextStyle(fontWeight: FontWeight.w600),),),)),);
  
  });
}
