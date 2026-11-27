import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:speed_ometer/components/speedometer.dart';
import 'package:speed_ometer/components/tts_form.dart';

class DashScreen extends StatefulWidget {
  const DashScreen({this.unit = 'm/s', Key? key}) : super(key: key);

  final String unit;

  @override
  _DashScreenState createState() => _DashScreenState();
}

class _DashScreenState extends State<DashScreen> {
  SharedPreferences? _sharedPreferences;
  late FlutterTts _ttsService;
  StreamSubscription? _ttsCallback;

  // Variabel status GPS yang ditampilkan di atas layar
  String _gpsStatus = "Mencari sinyal GPS...";

  /// String that the tts will read aloud, Speed + Expanded Unit (Rounded & Localized)
  String get speakText {
    String unitText;
    final bool isIndo =
        _ttsLanguage.startsWith('id') || _ttsLanguage.startsWith('ms');

    switch (widget.unit) {
      case 'km/h':
        unitText = isIndo ? 'kilometer per jam' : 'kilometers per hour';
        break;

      case 'miles/h':
        unitText = isIndo ? 'mil per jam' : 'miles per hour';
        break;

      case 'm/s':
      default:
        unitText = isIndo ? 'meter per detik' : 'meters per second';
        break;
    }

    final String speedFormatted =
        convertedVelocity(_velocity)!.round().toString();
    return '$speedFormatted $unitText';
  }

  Future<void> _startTTS() async {
    await _ttsService.setLanguage(_ttsLanguage);
    await _ttsService.setSpeechRate(_ttsSpeechRate);

    if (_ttsLanguage == 'en-US') {
      if (!_isTTSFemale) {
        await _ttsService
            .setVoice({'name': 'en-us-x-tpd-local', 'locale': 'en-US'});
      } else {
        await _ttsService
            .setVoice({'name': 'en-US-language', 'locale': 'en-US'});
      }
    } else {
      await _ttsService.setPitch(_isTTSFemale ? 1.1 : 0.85);
    }

    _ttsCallback?.cancel();

    if (_isTTSActive) _ttsService.speak(speakText);
    _ttsCallback = Stream.periodic(
      (_ttsDuration ?? const Duration(seconds: 3)) + const Duration(seconds: 1),
    ).listen(
      (event) {
        if (_isTTSActive) _ttsService.speak(speakText);
      },
    );
  }

  /// Should TTS be talking
  bool _isTTSActive = true;
  void setIsActive(bool isActive) => setState(
        () {
          _isTTSActive = isActive;
          _sharedPreferences?.setBool('isTTSActive', _isTTSActive);
          if (isActive) {
            _startTTS();
          } else {
            _ttsCallback?.cancel();
            _ttsService.stop();
          }
        },
      );

  /// TTS gender
  bool _isTTSFemale = true;
  void setIsFemale(bool isFemale) => setState(
        () {
          _isTTSFemale = isFemale;
          _sharedPreferences?.setBool('isTTSFemale', _isTTSFemale);
          if (_isTTSActive) _startTTS();
        },
      );

  /// TTS talk duration
  Duration? _ttsDuration;
  void setDuration(int seconds) => setState(
        () {
          _ttsDuration = _secondsToDuration(seconds);
          _sharedPreferences?.setInt('ttsDuration', seconds);
          if (_isTTSActive) _startTTS();
        },
      );

  /// TTS Language
  String _ttsLanguage = 'id-ID';
  void setLanguage(String newLang) => setState(
        () {
          _ttsLanguage = newLang;
          _sharedPreferences?.setString('ttsLanguage', _ttsLanguage);
          if (_isTTSActive) _startTTS();
        },
      );

  /// TTS Speech Rate (0.2 to 1.0)
  double _ttsSpeechRate = 0.55;
  void setSpeechRate(double newRate) => setState(
        () {
          _ttsSpeechRate = newRate;
          _sharedPreferences?.setDouble('ttsSpeechRate', _ttsSpeechRate);
          if (_isTTSActive) _startTTS();
        },
      );

  /// Utility function to deserialize saved Duration
  Duration _secondsToDuration(int seconds) {
    int minutes = (seconds / 60).floor();
    return Duration(minutes: minutes, seconds: seconds % 60);
  }

  // For velocity Tracking
  GeolocatorPlatform locator = GeolocatorPlatform.instance;
  late StreamController<double?> _velocityUpdatedStreamController;

  double? _velocity;
  double? _highestVelocity;

  double mpstokmph(double mps) => mps * 18 / 5;
  double mpstomilesph(double mps) => mps * 85 / 38;

  double? convertedVelocity(double? velocity) {
    velocity = velocity ?? _velocity;

    if (widget.unit == 'm/s') {
      return velocity;
    } else if (widget.unit == 'km/h') {
      return mpstokmph(velocity!);
    } else if (widget.unit == 'miles/h') {
      return mpstomilesph(velocity!);
    }
    return velocity;
  }

    StreamSubscription<Position>? _positionStream;
  Timer? _fallbackGpsTimer;

  @override
  void initState() {
    super.initState();
    _velocityUpdatedStreamController = StreamController<double?>.broadcast();

    // 1. Gunakan LocationSettings standar (Fused Location seperti Google Maps)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _gpsStatus =
                "GPS Aktif (Akurasi: ${position.accuracy.toStringAsFixed(0)}m)";
          });
        }
        _onAccelerate(position.speed);
      },
      onError: (e) {
        if (mounted) {
          setState(() => _gpsStatus = "Stream Error: $e");
        }
      },
    );

    // 2. Timer cadangan setiap 2 detik untuk menjaga chip GPS tetap hidup
    _fallbackGpsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 2),
        );
        if (mounted) {
          setState(() {
            _gpsStatus =
                "GPS Aktif (Akurasi: ${pos.accuracy.toStringAsFixed(0)}m)";
          });
        }
        _onAccelerate(pos.speed);
      } catch (_) {
        // Abaikan jika timeout sementara
      }
    });

    _velocity = 0.0;
    _highestVelocity = 0.0;
    _ttsDuration = const Duration(seconds: 3);

    _ttsService = FlutterTts();

    SharedPreferences.getInstance().then(
      (SharedPreferences prefs) {
        _sharedPreferences = prefs;
        setState(() {
          _isTTSActive = prefs.getBool('isTTSActive') ?? true;
          _isTTSFemale = prefs.getBool('isTTSFemale') ?? true;
          _ttsDuration = _secondsToDuration(prefs.getInt('ttsDuration') ?? 3);
          _ttsLanguage = prefs.getString('ttsLanguage') ?? 'id-ID';
          _ttsSpeechRate = prefs.getDouble('ttsSpeechRate') ?? 0.55;
        });
        _startTTS();
      },
    );
  }

  void _onAccelerate(double speed) {
    final double validSpeed = speed < 0 ? 0.0 : speed;
    if (mounted) {
      setState(() {
        _velocity = validSpeed;
        if (_velocity! > _highestVelocity!) {
          _highestVelocity = _velocity;
        }
      });
      _velocityUpdatedStreamController.add(_velocity);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double gaugeBegin = 0, gaugeEnd = 200;

    return ListView(
      scrollDirection: Axis.vertical,
      children: <Widget>[
        // Indikator Status Koneksi GPS
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Center(
            child: Text(
              _gpsStatus,
              style: const TextStyle(
                color: Color(0xFFE9A246),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        StreamBuilder<Object?>(
          stream: _velocityUpdatedStreamController.stream,
          builder: (context, snapshot) {
            return Speedometer(
              gaugeBegin: gaugeBegin,
              gaugeEnd: gaugeEnd,
              velocity: convertedVelocity(_velocity),
              maxVelocity: convertedVelocity(_highestVelocity),
              velocityUnit: widget.unit,
            );
          },
        ),
        TextToSpeechSettingsForm(
          isTTSActive: _isTTSActive,
          isTTSFemale: _isTTSFemale,
          currentDuration: _ttsDuration,
          currentLanguage: _ttsLanguage,
          currentSpeechRate: _ttsSpeechRate,
          activeSetter: setIsActive,
          femaleSetter: setIsFemale,
          durationSetter: setDuration,
          languageSetter: setLanguage,
          speechRateSetter: setSpeechRate,
        ),
      ],
    );
  }

   @override
  void dispose() {
    _positionStream?.cancel();
    _fallbackGpsTimer?.cancel();
    _velocityUpdatedStreamController.close();
    _ttsCallback?.cancel();
    _ttsService.stop();
    super.dispose();
  }

