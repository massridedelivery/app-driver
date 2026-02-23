extension StringTruncation on String {
  String truncateTo(int maxLength) {
    if (length <= maxLength) {
      return this;
    }
    return substring(0, maxLength);
  }
}
