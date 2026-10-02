// One-time seed script — run this once against your emulator or real
// Firestore to create the initial `causes` documents.
//
// Run with: dart run lib/scripts/seed_causes.dart
// (adjust the import path to wherever you place this file)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> seedCausesToFirestore() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If testing against the emulator, uncomment:
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

  final causes = {
    'health': {
      'title': 'Health Support',
      'tag': 'HEALTHCARE',
      'description':
      'Bringing timely care to those who need it most through medicine assistance, general health check-ups, and diagnostic tests.',
      'imagePath': 'assets/images/health_checkup.jpg',
      'goalAmount': 5000.0,
      'totalRaised': 0.0,
    },
    'education': {
      'title': 'Education Support',
      'tag': 'KNOWLEDGE',
      'description':
      'Opening doors for the next generation through scholarships, school supplies, and literacy programs.',
      'imagePath': 'assets/images/education_support.jpg',
      'goalAmount': 10000.0,
      'totalRaised': 0.0,
    },
    'women': {
      'title': 'Women Empowerment',
      'tag': 'EMPOWERMENT',
      'description':
      'Strengthening families through hygiene kits, skill development, and livelihood support.',
      'imagePath': 'assets/images/women_empowerment.jpg',
      'goalAmount': 4000.0,
      'totalRaised': 0.0,
    },
    'environment': {
      'title': 'Environment',
      'tag': 'PLANET',
      'description':
      'Protecting our shared home through reforestation, cleanup initiatives, and climate education.',
      'imagePath': 'assets/images/tree_plantation.jpeg',
      'goalAmount': 3000.0,
      'totalRaised': 0.0,
    },
  };

  final collection = FirebaseFirestore.instance.collection('causes');

  for (final entry in causes.entries) {
    await collection.doc(entry.key).set(entry.value, SetOptions(merge: true));

  }


}