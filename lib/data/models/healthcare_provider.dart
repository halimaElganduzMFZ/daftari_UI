import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HealthcareSpecialty {
  const HealthcareSpecialty({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final String subtitle;
  final FaIconData icon;
  final Color accent;
}

class HealthcareProvider {
  const HealthcareProvider({
    required this.id,
    required this.specialtyId,
    required this.name,
    required this.summary,
    required this.address,
    required this.phone,
    required this.hours,
    this.mapUrl,
    this.services = const [],
  });

  final String id;
  final String specialtyId;
  final String name;
  final String summary;
  final String address;
  final String phone;
  final String hours;
  final String? mapUrl;
  final List<String> services;
}
