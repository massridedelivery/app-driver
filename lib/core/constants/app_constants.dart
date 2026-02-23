import 'package:flutter/material.dart';
import 'package:massdrive/core/configs/environment_config.dart';

const constSpacing1 = SizedBox(height: 4);
const constSpacing2 = SizedBox(height: 8);
const constSpacing3 = SizedBox(height: 16);
const constSpacing4 = SizedBox(height: 32);
const constSpacing5 = SizedBox(height: 64);
const constSpacing6 = SizedBox(height: 24);
const constSpacing7 = SizedBox(height: 28);
const constSpacing8 = SizedBox(height: 38);
const constSpacing9 = SizedBox(height: 12);
const constSpacing10 = SizedBox(height: 74);
const constSpacing11 = SizedBox(height: 52);
const constSpacing12 = SizedBox(height: 67);
const constSpacing13 = SizedBox(height: 20);
const constSpacing14 = SizedBox(height: 14);
const constSpacing15 = SizedBox(height: 45);

class Constant {
  static const String languageCode = 'language_code';
  static const String countryCode = 'country_code';
}

class NumberFormatConstant {
  static const String defaultCurrency = '#,##0.00';
  static const String shortCurrency = '#,##0.##';
  static const String separator = '#,###';
  static const String separatorWith2Decimal = '#,###.00';
}

class PaymentConstant {
  static final String confirmUrl =
      '${EnvironmentConfig.hostUrl}/payment-confirmation';
}
