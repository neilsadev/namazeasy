import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:intl/intl.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:quran/quran.dart';

import 'compass_view/loading_indicator.dart';
import 'compass_view/qiblah_compass.dart';
import 'compass_view/qiblah_maps.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

Animation<double>? animation;
AnimationController? _animationController;
double begin = 0.0;

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with SingleTickerProviderStateMixin {
  final List<String> madhabs = ['Hanafi', 'Shafi'];
  String selectedMadhab = 'Hanafi';
  PrayerTimes? prayerTimes;
  int? verseNumber;
  int? surahNumber;
  String? randomVerse;
  String? randomVerseTranslation;
  String currentPrayer = '';

  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
    _fetchRandomVerse();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animation = Tween(begin: 0.0, end: 0.0).animate(_animationController!);
  }

  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  void _fetchPrayerTimes() {
    final coordinates = Coordinates(23.8103, 90.4125); // Dhaka, Bangladesh
    PrayerCalculationParameters params =
        PrayerCalculationMethod.muslimWorldLeague();
    params.madhab =
        selectedMadhab == 'Hanafi' ? PrayerMadhab.hanafi : PrayerMadhab.shafi;

    prayerTimes = PrayerTimes(
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
      locationName: 'Asia/Dhaka',
    );

    _determineCurrentPrayer();
    setState(() {});
  }

  void _fetchRandomVerse() {
    RandomVerse random = RandomVerse();
    randomVerse = random.verse;
    randomVerseTranslation = random.translation;
    verseNumber = random.verseNumber;
    surahNumber = random.surahNumber;
    setState(() {});
  }

  void _determineCurrentPrayer() {
    DateTime now = DateTime.now();
    if (prayerTimes != null) {
      if (now.isAfter(prayerTimes!.fajrStartTime!) &&
          now.isBefore(prayerTimes!.sunrise!)) {
        currentPrayer = 'Fajr';
      } else if (now.isAfter(prayerTimes!.dhuhrStartTime!) &&
          now.isBefore(prayerTimes!.asrStartTime!)) {
        currentPrayer = 'Dhuhr';
      } else if (now.isAfter(prayerTimes!.asrStartTime!) &&
          now.isBefore(prayerTimes!.maghribStartTime!)) {
        currentPrayer = 'Asr';
      } else if (now.isAfter(prayerTimes!.maghribStartTime!) &&
          now.isBefore(prayerTimes!.ishaStartTime!)) {
        currentPrayer = 'Maghrib';
      } else if (now.isAfter(prayerTimes!.ishaStartTime!)) {
        currentPrayer = 'Isha';
      } else {
        currentPrayer = ''; // Default to none if no current prayer is found
      }
    }
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time); // Format time as 08:45 PM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );
            }

            if (snapshot.data!) {
              return QiblahCompass();
            } else {
              return QiblahMaps();
            }
          },
        ),
        title: const Text(
          'Prayer Times',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onSelected: (value) {
              // Handle the selection here
              print('Selected: $value');
            },
            itemBuilder: (BuildContext context) {
              return {'Theme', 'Notification', 'Sound'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (randomVerse != null) // Display the random verse if available
                GestureDetector(
                  onTap: () {
                    _fetchRandomVerse();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          randomVerse!,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${randomVerseTranslation!} ( $verseNumber:$surahNumber )",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              if (prayerTimes != null)
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      PrayerTile(
                        title: 'Fajr',
                        startTime: formatTime(prayerTimes!.fajrStartTime!),
                        endTime: formatTime(prayerTimes!.sunrise!),
                        isCurrent: currentPrayer == 'Fajr',
                      ),
                      PrayerTile(
                        title: 'Dhuhr',
                        startTime: formatTime(prayerTimes!.dhuhrStartTime!),
                        endTime: formatTime(prayerTimes!.asrStartTime!),
                        isCurrent: currentPrayer == 'Dhuhr',
                      ),
                      PrayerTile(
                        title: 'Asr',
                        startTime: formatTime(prayerTimes!.asrStartTime!),
                        endTime: formatTime(prayerTimes!.maghribStartTime!),
                        isCurrent: currentPrayer == 'Asr',
                      ),
                      PrayerTile(
                        title: 'Maghrib',
                        startTime: formatTime(prayerTimes!.maghribStartTime!),
                        endTime: formatTime(prayerTimes!.ishaStartTime!),
                        isCurrent: currentPrayer == 'Maghrib',
                      ),
                      PrayerTile(
                        title: 'Isha',
                        startTime: formatTime(prayerTimes!.ishaStartTime!),
                        endTime: 'Midnight',
                        isCurrent: currentPrayer == 'Isha',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerTile extends StatelessWidget {
  final String title;
  final String startTime;
  final String endTime;
  final bool isCurrent; // Added to indicate if it is the current prayer

  const PrayerTile({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: Colors.deepOrange, width: 3)
            : BorderSide.none, // Golden border for the current prayer
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(
          'Start: $startTime\nEnd: $endTime',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        leading: Icon(Icons.access_time, color: Colors.black),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
      ),
    );
  }
}
