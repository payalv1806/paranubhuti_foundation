import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paranubhutifoundation/core/theme/app_colors.dart';

/// Represents a document in Firestore's `causes` collection:
///   { title, tag, description, imagePath, totalRaised, goalAmount }
///
/// `icon` and `badgeColor` are NOT stored in Firestore — Firestore can't
/// hold a Flutter IconData/Color — so they're derived locally from the
/// cause's document id via `_iconFor` / `_colorFor` below. If you add a new
/// cause in Firestore, add a matching case there too, or it'll fall back to
/// a generic icon/color.
class CauseModel {
  final String id;
  final String title;
  final String tag;
  final String? description;
  final String? imagePath;
  final double totalRaised;
  final double goalAmount;
  final IconData icon;
  final Color badgeColor;

  const CauseModel({
    required this.id,
    required this.title,
    required this.tag,
    this.description,
    this.imagePath,
    required this.totalRaised,
    required this.goalAmount,
    required this.icon,
    required this.badgeColor,
  });

  factory CauseModel.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CauseModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Cause',
      tag: data['tag'] as String? ?? '',
      description: data['description'] as String?,
      imagePath: data['imagePath'] as String?,
      totalRaised: (data['totalRaised'] as num?)?.toDouble() ?? 0,
      goalAmount: (data['goalAmount'] as num?)?.toDouble() ?? 0,
      icon: _iconFor(doc.id),
      badgeColor: _colorFor(doc.id),
    );
  }

  static IconData _iconFor(String causeId) {
    switch (causeId) {
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'women':
        return Icons.groups_rounded;
      case 'environment':
        return Icons.eco_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  static Color _colorFor(String causeId) {
    switch (causeId) {
      case 'health':
        return AppColors.primaryContainer;
      case 'education':
        return AppColors.secondaryContainer;
      case 'women':
        return AppColors.tertiaryContainer;
      case 'environment':
        return AppColors.inversePrimary;
      default:
        return AppColors.surfaceContainerHigh;
    }
  }
}