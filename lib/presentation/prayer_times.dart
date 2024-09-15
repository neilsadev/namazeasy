import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:quran/quran.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

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
  DateTime currentPrayerStartTime = DateTime.now();
  DateTime currentPrayerEndTime = DateTime.now();

  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();

  late Timer _timer;
  String _remainingTime = "";

  int remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchPrayerTimes();
    _fetchRandomVerse();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animation = Tween(begin: 0.0, end: 0.0).animate(_animationController!);
  }

  void _startTimer() {
    // Start a timer that updates the remaining time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = getRemainingTime(currentPrayerEndTime);

        // Stop the timer when time is up
        if (_remainingTime == "$currentPrayer 00:00:00") {
          _timer.cancel();
        }
      });
    });
  }

  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  @override
  void dispose() {
    _locationStreamController.close();
    _timer.cancel();
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
    print("currentPrayer: ${prayerTimes!.fajrEndTime}");
    if (prayerTimes != null) {
      if (now.isAfter(prayerTimes!.fajrStartTime!) &&
          now.isBefore(prayerTimes!.sunrise!)) {
        currentPrayer = 'Fajr';
        currentPrayerStartTime = prayerTimes!.fajrStartTime!;
        currentPrayerEndTime = prayerTimes!.sunrise!;
      } else if (now.isAfter(prayerTimes!.dhuhrStartTime!) &&
          now.isBefore(prayerTimes!.asrStartTime!)) {
        currentPrayer = 'Dhuhr';
        currentPrayerStartTime = prayerTimes!.dhuhrStartTime!;
        currentPrayerEndTime = prayerTimes!.asrStartTime!;
      } else if (now.isAfter(prayerTimes!.asrStartTime!) &&
          now.isBefore(prayerTimes!.maghribStartTime!)) {
        currentPrayer = 'Asr';
        currentPrayerStartTime = prayerTimes!.asrStartTime!;
        currentPrayerEndTime = prayerTimes!.maghribStartTime!
            .subtract(const Duration(minutes: 23));
      } else if (now.isAfter(prayerTimes!.maghribStartTime!) &&
          now.isBefore(prayerTimes!.ishaStartTime!)) {
        currentPrayer = 'Maghrib';
        currentPrayerStartTime = prayerTimes!.maghribStartTime!;
        currentPrayerEndTime = prayerTimes!.ishaStartTime!;
      } else if (now.isAfter(prayerTimes!.ishaStartTime!)) {
        currentPrayer = 'Isha';
        currentPrayerStartTime = prayerTimes!.ishaStartTime!;
        currentPrayerEndTime =
            prayerTimes!.ishaStartTime!.add(const Duration(hours: 4));
      } else {
        currentPrayer = 'Duha'; // Default to none if no current prayer is found
      }
    }
  }

  double? notifyValue;

  String getRemainingTime(DateTime endTime) {
    // Calculate the difference between end time and now
    Duration remaining = endTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return "$currentPrayer 00:00:00";
    }
    int hours = remaining.inHours;
    int minutes = remaining.inMinutes.remainder(60);
    int seconds = remaining.inSeconds.remainder(60);
    remainingMinutes = remaining.inMinutes;

    notifyValue = (getTimeDifferenceInHours(
                currentPrayerStartTime, currentPrayerEndTime) -
            remainingMinutes)
        .toDouble();

    // Format the hours and minutes with leading zeroes
    return "Remaining $currentPrayer \n${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  int getTimeDifferenceInHours(DateTime startTime, DateTime endTime) {
    // Get the difference between endTime and startTime
    Duration difference = endTime.difference(startTime);

    // Convert the duration to hours as a double value

    return difference.inMinutes; // 3600 seconds = 1 hour
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(
                child: Icon(Icons.error),
              );
            }

            if (snapshot.data!) {
              return QiblahCompass();
            } else {
              return QiblahMaps();
            }
          },
        ),
        title: Text(
          "Salat al-$currentPrayer",
          style: TextStyle(
            color: Color(0xFF3CDAF7),
            fontSize: 30,
            fontWeight: FontWeight.bold,
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
      body: Column(
        children: [
          newDashboardWidget(),
          Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (randomVerse !=
                      null) // Display the random verse if available
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
                            startTime:
                                formatTime(prayerTimes!.maghribStartTime!),
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
        ],
      ),
    );
  }

  Widget newDashboardWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
        ),
        Center(
          child: CircleAvatar(
            backgroundImage: const AssetImage("assets/clock_bg.png"),
            radius: 150,
            child: SimpleCircularProgressBar(
              size: 350,
              maxValue: getTimeDifferenceInHours(
                      currentPrayerStartTime, currentPrayerEndTime)
                  .toDouble(),
              valueNotifier: ValueNotifier(notifyValue!),
              progressStrokeWidth: 20,
              backStrokeWidth: 5,
              mergeMode: true,
              fullProgressColor: Colors.amber,
              progressColors: const [
                Colors.blue,
                Colors.green,
                Colors.amberAccent,
                Colors.redAccent,
              ],
              backColor: Colors.blueGrey,
              onGetText: (double value) {
                return Text(
                  getRemainingTime(currentPrayerEndTime),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        ),
        Container(
          width: 300.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFF1F2633),
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Above Sleep Goal (>=8) 😇",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _timeWidget(
              'BedTime',
              _inBedTime,
              Icon(
                Icons.power_settings_new_outlined,
                size: 25.0,
                color: Color(0xFF3CDAF7),
              ),
            ),
            _timeWidget(
              'WakeUp',
              _outBedTime,
              Icon(
                Icons.notifications_active_outlined,
                size: 25.0,
                color: Color(0xFF3CDAF7),
              ),
            ),
          ],
        ),
        Text(
          validRange == true
              ? "Working hours ${intl.NumberFormat('00').format(_disabledInitTime.h)}:${intl.NumberFormat('00').format(_disabledInitTime.m)} to ${intl.NumberFormat('00').format(_disabledEndTime.h)}:${intl.NumberFormat('00').format(_disabledEndTime.m)}"
              : "Please schedule according working time!",
          style: TextStyle(
            fontSize: 16.0,
            color: validRange == true ? Colors.white : Colors.red,
          ),
        ),
      ],
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
