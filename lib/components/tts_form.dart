import 'package:flutter/material.dart';
import 'package:gender_picker/gender_picker.dart';
import 'package:gender_picker/source/enums.dart';
import 'package:numberpicker/numberpicker.dart';

/// Form that allows user to modify Text to Speech Speed Narration Settings.
class TextToSpeechSettingsForm extends StatelessWidget {
  const TextToSpeechSettingsForm({
    required this.isTTSActive,
    required this.isTTSFemale,
    required this.currentDuration,
    required this.currentLanguage,
    required this.currentSpeechRate,
    required this.activeSetter,
    required this.femaleSetter,
    required this.durationSetter,
    required this.languageSetter,
    required this.speechRateSetter,
    Key? key,
  }) : super(key: key);

  final bool isTTSActive;
  final bool isTTSFemale;
  final Duration? currentDuration;
  final String currentLanguage;
  final double currentSpeechRate;

  final void Function(bool) activeSetter;
  final void Function(bool) femaleSetter;
  final void Function(int) durationSetter;
  final void Function(String) languageSetter;
  final void Function(double) speechRateSetter;

  static const Map<String, String> _supportedLanguages = {
    'id-ID': 'Indonesia (id-ID)',
    'en-US': 'English US (en-US)',
    'en-GB': 'English UK (en-GB)',
    'ms-MY': 'Melayu (ms-MY)',
    'ja-JP': '日本語 (ja-JP)',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 20, left: 25, right: 25),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFF252222),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Switch Aktifkan TTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Narrate the Speed:  ',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Switch(
                value: isTTSActive,
                onChanged: (bool newIsActive) => activeSetter(newIsActive),
                activeColor: const Color(0xFFE9A246),
              ),
            ],
          ),

          const Divider(color: Colors.white24),

          // 2. Pengaturan Bahasa TTS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bahasa TTS:',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                DropdownButton<String>(
                  value: _supportedLanguages.containsKey(currentLanguage)
                      ? currentLanguage
                      : 'id-ID',
                  dropdownColor: const Color(0xFF333030),
                  style: const TextStyle(
                    color: Color(0xFFE9A246),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  underline: Container(
                    height: 1,
                    color: const Color(0xFFE9A246),
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      languageSetter(newValue);
                    }
                  },
                  items: _supportedLanguages.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 3. Pengaturan Kecepatan Bicara (Speech Rate)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kecepatan Suara:',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      '${currentSpeechRate.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Color(0xFFE9A246),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: currentSpeechRate.clamp(0.2, 1.0),
                  min: 0.2,
                  max: 1.0,
                  divisions: 16,
                  activeColor: const Color(0xFFE9A246),
                  inactiveColor: Colors.white24,
                  onChanged: (double value) => speechRateSetter(value),
                ),
              ],
            ),
          ),

          // 4. Tombol Frekuensi Pengucapan (Interval)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TextButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xFFD68822)),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                ),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: const Color(0xFF252222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Center(
                    child: Text(
                      'Choose Minutes : Seconds',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                  content: TimeForm(
                    currentMinutes: (currentDuration?.inMinutes ?? 0) % 60,
                    currentSeconds: (currentDuration?.inSeconds ?? 3) % 60,
                    durationSetter: durationSetter,
                  ),
                ),
              ),
              child: const Text(
                'Update Narration Frequency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 5. Pilihan Gender Suara
          GenderPickerWithImage(
            verticalAlignedText: false,
            selectedGender: (isTTSFemale) ? Gender.Female : Gender.Male,
            unSelectedGenderTextStyle: const TextStyle(color: Colors.white),
            onChanged: (Gender? gender) =>
                femaleSetter(gender == Gender.Female),
            equallyAligned: true,
            animationDuration: const Duration(milliseconds: 300),
            isCircular: true,
            opacityOfGradient: 0.4,
            padding: const EdgeInsets.all(3),
            size: 65,
          ),
        ],
      ),
    );
  }
}

/// Pop up form that allows user to change Frequency of Speed Narration when button pressed.
class TimeForm extends StatefulWidget {
  const TimeForm({
    required int currentSeconds,
    required int currentMinutes,
    required this.durationSetter,
    Key? key,
  })  : _currentMinutes = currentMinutes,
        _currentSeconds = currentSeconds,
        super(key: key);

  final int _currentSeconds, _currentMinutes;
  final void Function(int) durationSetter;

  @override
  _TimeFormState createState() => _TimeFormState();
}

class _TimeFormState extends State<TimeForm> {
  late int _currentSeconds;
  late int _currentMinutes;

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget._currentMinutes;
    _currentSeconds = widget._currentSeconds;
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle selectedTextStyle = TextStyle(
      color: Color(0xFFE9A246),
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );
    const TextStyle unselectedTextStyle =
        TextStyle(color: Colors.white38, fontSize: 20);
    return SizedBox(
      height: 230,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<Object>(
                  stream: null,
                  builder: (context, snapshot) {
                    return NumberPicker(
                      zeroPad: true,
                      selectedTextStyle: selectedTextStyle,
                      textStyle: unselectedTextStyle,
                      itemWidth: 65,
                      value: _currentMinutes,
                      minValue: 0,
                      maxValue: 59,
                      onChanged: (value) => setState(
                        () {
                          _currentMinutes = value;
                          if (value == 0 && _currentSeconds < 3) {
                            _currentSeconds = 3;
                          }
                        },
                      ),
                    );
                  }),
              const Text(
                ':',
                style: TextStyle(fontSize: 25, color: Colors.white24),
              ),
              NumberPicker(
                zeroPad: true,
                selectedTextStyle: selectedTextStyle,
                textStyle: unselectedTextStyle,
                itemWidth: 65,
value: _currentSeconds,
minValue: _currentMinutes > 0 ? 0 : 3,
maxValue: 59,
onChanged: (value) => setState(
() => _currentSeconds =
_currentMinutes > 0 || value >= 3 ? value : 3,
),
),
],
),
Container(
margin: const EdgeInsets.all(10),
child: TextButton(
style: ButtonStyle(
backgroundColor:
MaterialStateProperty.all(const Color(0xFF086624)),
padding: MaterialStateProperty.all(const EdgeInsets.all(15)),
),
onPressed: () {
ScaffoldMessenger.of(context).hideCurrentSnackBar();
final int convertedTime =
_currentMinutes * 60 + _currentSeconds;
if (convertedTime <= 0) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please enter postive time!')),
);
} else if (convertedTime < 3) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Minimum time should be 3 seconds to avoid overlap!',
),
),
);
} else {
widget.durationSetter(convertedTime);
Navigator.of(context).pop();
}
},
child: const Text(
'Update Frequency',
style: TextStyle(color: Colors.white, fontSize: 18),
),
),
),
],
),
);
}
}
