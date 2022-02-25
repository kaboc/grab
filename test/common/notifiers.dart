import 'package:flutter/foundation.dart';

class TestChangeNotifier extends ChangeNotifier {
  TestChangeNotifier();

  int intValue = 0;
  String stringValue = '';

  void updateIntValue(int value) {
    intValue = value;
    notifyListeners();
  }

  void updateStringValue(String value) {
    stringValue = value;
    notifyListeners();
  }
}

class TestValueNotifier extends ValueNotifier<TestState> {
  TestValueNotifier() : super(const TestState());

  void updateIntValue(int v) {
    value = TestState(intValue: v, stringValue: value.stringValue);
  }

  void updateStringValue(String v) {
    value = TestState(intValue: value.intValue, stringValue: v);
  }
}

class TestState {
  const TestState({this.intValue = 0, this.stringValue = ''});

  final int intValue;
  final String stringValue;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is TestState &&
          intValue == other.intValue &&
          stringValue == other.stringValue;

  @override
  int get hashCode => Object.hashAll([intValue, stringValue]);
}

class FlagNotifier extends ValueNotifier<bool> {
  FlagNotifier() : super(false);

  void toggle() {
    value = !value;
  }
}
