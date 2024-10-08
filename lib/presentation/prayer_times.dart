import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';
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
  //For New
  ClockTimeFormat _clockTimeFormat = ClockTimeFormat.twentyFourHours;
  ClockIncrementTimeFormat _clockIncrementTimeFormat =
      ClockIncrementTimeFormat.fiveMin;

  PickedTime _inBedTime = PickedTime(h: 0, m: 0);
  PickedTime _outBedTime = PickedTime(h: 8, m: 0);
  PickedTime _intervalBedTime = PickedTime(h: 0, m: 0);

  PickedTime _disabledInitTime = PickedTime(h: 12, m: 0);
  PickedTime _disabledEndTime = PickedTime(h: 20, m: 0);

  double _sleepGoal = 8.0;
  bool _isSleepGoal = false;
  bool? validRange = true;

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

    //New UI
    _isSleepGoal = (_sleepGoal >= 8.0) ? true : false;
    _intervalBedTime = formatIntervalTime(
      init: _inBedTime,
      end: _outBedTime,
      clockTimeFormat: _clockTimeFormat,
      clockIncrementTimeFormat: _clockIncrementTimeFormat,
    );

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
    print("currentPrayer: ${prayerTimes!.fajrEndTime}");
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
        currentPrayer = 'Duha'; // Default to none if no current prayer is found
      }
    }

    print("currentPrayer: $currentPrayer");
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time); // Format time as 08:45 PM
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
      body: newDashboardWidget(),

      // Container(
      //   decoration: const BoxDecoration(color: Colors.black),
      //   child: Padding(
      //     padding: const EdgeInsets.all(16.0),
      //     child:
      //
      //     Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         if (randomVerse != null) // Display the random verse if available
      //           GestureDetector(
      //             onTap: () {
      //               _fetchRandomVerse();
      //             },
      //             child: Container(
      //               padding: const EdgeInsets.all(12.0),
      //               margin: const EdgeInsets.only(bottom: 16.0),
      //               decoration: BoxDecoration(
      //                 color: Colors.white.withOpacity(0.9),
      //                 borderRadius: BorderRadius.circular(12),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Colors.black.withOpacity(0.1),
      //                     blurRadius: 8,
      //                     spreadRadius: 1,
      //                   ),
      //                 ],
      //               ),
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text(
      //                     randomVerse!,
      //                     style: const TextStyle(
      //                         fontSize: 16,
      //                         fontWeight: FontWeight.bold,
      //                         color: Colors.black),
      //                   ),
      //                   const SizedBox(height: 8),
      //                   Text(
      //                     "${randomVerseTranslation!} ( $verseNumber:$surahNumber )",
      //                     style: const TextStyle(
      //                         fontSize: 14, color: Colors.black87),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           ),
      //         if (prayerTimes != null)
      //           Expanded(
      //             child: ListView(
      //               padding: EdgeInsets.zero,
      //               children: [
      //                 PrayerTile(
      //                   title: 'Fajr',
      //                   startTime: formatTime(prayerTimes!.fajrStartTime!),
      //                   endTime: formatTime(prayerTimes!.sunrise!),
      //                   isCurrent: currentPrayer == 'Fajr',
      //                 ),
      //                 PrayerTile(
      //                   title: 'Dhuhr',
      //                   startTime: formatTime(prayerTimes!.dhuhrStartTime!),
      //                   endTime: formatTime(prayerTimes!.asrStartTime!),
      //                   isCurrent: currentPrayer == 'Dhuhr',
      //                 ),
      //                 PrayerTile(
      //                   title: 'Asr',
      //                   startTime: formatTime(prayerTimes!.asrStartTime!),
      //                   endTime: formatTime(prayerTimes!.maghribStartTime!),
      //                   isCurrent: currentPrayer == 'Asr',
      //                 ),
      //                 PrayerTile(
      //                   title: 'Maghrib',
      //                   startTime: formatTime(prayerTimes!.maghribStartTime!),
      //                   endTime: formatTime(prayerTimes!.ishaStartTime!),
      //                   isCurrent: currentPrayer == 'Maghrib',
      //                 ),
      //                 PrayerTile(
      //                   title: 'Isha',
      //                   startTime: formatTime(prayerTimes!.ishaStartTime!),
      //                   endTime: 'Midnight',
      //                   isCurrent: currentPrayer == 'Isha',
      //                 ),
      //               ],
      //             ),
      //           ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget newDashboardWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TimePicker(
          initTime: _inBedTime,
          endTime: _outBedTime,
          disabledRange: DisabledRange(
            initTime: _disabledInitTime,
            endTime: _disabledEndTime,
            disabledRangeColor: Colors.grey,
            errorColor: Colors.red,
          ),
          height: 260.0,
          width: 260.0,
          onSelectionChange: _updateLabels,
          onSelectionEnd: (start, end, isDisableRange) => print(
              'onSelectionEnd => init : ${start.h}:${start.m}, end : ${end.h}:${end.m}, isDisableRange: $isDisableRange'),
          primarySectors: _clockTimeFormat.value,
          secondarySectors: _clockTimeFormat.value * 2,
          decoration: TimePickerDecoration(
            baseColor: Color(0xFF1F2633),
            pickerBaseCirclePadding: 15.0,
            sweepDecoration: TimePickerSweepDecoration(
              pickerStrokeWidth: 30.0,
              pickerColor: _isSleepGoal ? Color(0xFF3CDAF7) : Colors.white,
              showConnector: true,
            ),
            initHandlerDecoration: TimePickerHandlerDecoration(
              color: Color(0xFF141925),
              shape: BoxShape.circle,
              radius: 12.0,
              icon: Icon(
                Icons.power_settings_new_outlined,
                size: 20.0,
                color: Color(0xFF3CDAF7),
              ),
            ),
            endHandlerDecoration: TimePickerHandlerDecoration(
              color: Color(0xFF141925),
              shape: BoxShape.circle,
              radius: 12.0,
              icon: Icon(
                Icons.notifications_active_outlined,
                size: 20.0,
                color: Color(0xFF3CDAF7),
              ),
            ),
            primarySectorsDecoration: TimePickerSectorDecoration(
              color: Colors.white,
              width: 1.0,
              size: 4.0,
              radiusPadding: 25.0,
            ),
            secondarySectorsDecoration: TimePickerSectorDecoration(
              color: Color(0xFF3CDAF7),
              width: 1.0,
              size: 2.0,
              radiusPadding: 25.0,
            ),
            clockNumberDecoration: TimePickerClockNumberDecoration(
              defaultTextColor: Colors.white,
              defaultFontSize: 12.0,
              scaleFactor: 2.0,
              showNumberIndicators: true,
              clockTimeFormat: _clockTimeFormat,
              clockIncrementTimeFormat: _clockIncrementTimeFormat,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(62.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${intl.NumberFormat('00').format(_intervalBedTime.h)}Hr ${intl.NumberFormat('00').format(_intervalBedTime.m)}Min',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: _isSleepGoal ? Color(0xFF3CDAF7) : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              _isSleepGoal
                  ? "Above Sleep Goal (>=8) 😇"
                  : 'below Sleep Goal (<=8) 😴',
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

  void _updateLabels(PickedTime init, PickedTime end, bool? isDisableRange) {
    _inBedTime = init;
    _outBedTime = end;
    _intervalBedTime = formatIntervalTime(
      init: _inBedTime,
      end: _outBedTime,
      clockTimeFormat: _clockTimeFormat,
      clockIncrementTimeFormat: _clockIncrementTimeFormat,
    );
    _isSleepGoal = validateSleepGoal(
      inTime: init,
      outTime: end,
      sleepGoal: _sleepGoal,
      clockTimeFormat: _clockTimeFormat,
      clockIncrementTimeFormat: _clockIncrementTimeFormat,
    );
    setState(() {
      validRange = isDisableRange;
    });
  }

  Widget _timeWidget(String title, PickedTime time, Icon icon) {
    return Container(
      width: 150.0,
      decoration: BoxDecoration(
        color: Color(0xFF1F2633),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Text(
              '${intl.NumberFormat('00').format(time.h)}:${intl.NumberFormat('00').format(time.m)}',
              style: TextStyle(
                color: Color(0xFF3CDAF7),
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              '$title',
              style: TextStyle(
                color: Color(0xFF3CDAF7),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            icon,
          ],
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
