import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayers_times/prayers_times.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

class PrayersList extends StatefulWidget {
  final String currentPrayer;
  const PrayersList({super.key, required this.currentPrayer});

  @override
  State<PrayersList> createState() => _PrayersListState();
}

class _PrayersListState extends State<PrayersList> {
  final List<String> madhabs = ['Hanafi', 'Shafi'];
  String selectedMadhab = 'Hanafi';
  PrayerTimes? prayerTimes;

  @override
  void initState() {
    _fetchPrayerTimes();
    // TODO: implement initState
    super.initState();
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

    setState(() {});
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time); // Format time as 08:45 PM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Prayers"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prayerTimes != null)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    PrayerTile(
                      title: 'Fajr',
                      startTime: formatTime(prayerTimes!.fajrStartTime!),
                      endTime: formatTime(prayerTimes!.sunrise!),
                      isCurrent: widget.currentPrayer == 'Fajr',
                    ),
                    PrayerTile(
                      title: 'Dhuhr',
                      startTime: formatTime(prayerTimes!.dhuhrStartTime!),
                      endTime: formatTime(prayerTimes!.asrStartTime!),
                      isCurrent: widget.currentPrayer == 'Dhuhr',
                    ),
                    PrayerTile(
                      title: 'Asr',
                      startTime: formatTime(prayerTimes!.asrStartTime!),
                      endTime: formatTime(prayerTimes!.maghribStartTime!),
                      isCurrent: widget.currentPrayer == 'Asr',
                    ),
                    PrayerTile(
                      title: 'Maghrib',
                      startTime: formatTime(prayerTimes!.maghribStartTime!),
                      endTime: formatTime(prayerTimes!.ishaStartTime!),
                      isCurrent: widget.currentPrayer == 'Maghrib',
                    ),
                    PrayerTile(
                      title: 'Isha',
                      startTime: formatTime(prayerTimes!.ishaStartTime!),
                      endTime: 'Midnight',
                      isCurrent: widget.currentPrayer == 'Isha',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PrayerTile extends StatefulWidget {
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
  State<PrayerTile> createState() => _PrayerTileState();
}

class _PrayerTileState extends State<PrayerTile> {
  bool _notification = false;
  bool _alarm = false;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.isCurrent
              ? const BorderSide(color: Colors.deepOrange, width: 3)
              : BorderSide.none, // Golden border for the current prayer
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircleAvatar(
                  backgroundImage: const AssetImage("assets/clock_bg.png"),
                  radius: 500,
                  child: SimpleCircularProgressBar(
                    size: 350,
                    maxValue: 100,
                    startAngle: 100,
                    valueNotifier: ValueNotifier(80),
                    progressStrokeWidth: 5,
                    backStrokeWidth: 3,
                    mergeMode: true,
                    fullProgressColor: Colors.amber,
                    progressColors: const [
                      Colors.blue,
                      Colors.green,
                      Colors.amberAccent,
                      Colors.redAccent,
                    ],
                    onGetText: (double value) {
                      return Text(
                        widget.title == "Fajr"
                            ? "الفجر"
                            : widget.title == "Dhuhr"
                                ? "الظهر"
                                : widget.title == "Asr"
                                    ? "العصر"
                                    : widget.title == "Maghrib"
                                        ? "المغرب"
                                        : widget.title == "Isha"
                                            ? "العشاء"
                                            : "الصلاة",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                    backColor: Colors.blueGrey,
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    'Start: ${widget.startTime}\nEnd: ${widget.endTime}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _notification = !_notification;
                      });
                      print(_notification);
                    },
                    icon: Icon(
                      _notification
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          _alarm = !_alarm;
                        });
                      },
                      icon: Icon(_alarm
                          ? Icons.alarm_outlined
                          : Icons.alarm_off_outlined)),
                ],
              ),
            ],
          ),
        ));
  }
}
