import 'package:flutter/material.dart';

class Account {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final String currency;

  const Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.currency = 'CLP',
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'colorValue': colorValue,
    'currency': currency,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
    colorValue: json['colorValue'],
    currency: json['currency'] ?? 'CLP',
  );

  Account copyWith({String? name, String? icon, int? colorValue}) => Account(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    currency: currency,
  );
}
