class AnnouncementVariant {
  final bool isShowBorder;
  final bool isShowShadow;
  final bool isFullWidth;

  const AnnouncementVariant({
    required this.isShowBorder,
    required this.isShowShadow,
    required this.isFullWidth,
  });

  AnnouncementVariant copyWith({
    bool? isShowBorder,
    bool? isShowShadow,
    bool? isFullWidth,
  }) {
    return AnnouncementVariant(
      isShowBorder: isShowBorder ?? this.isShowBorder,
      isShowShadow: isShowShadow ?? this.isShowShadow,
      isFullWidth: isFullWidth ?? this.isFullWidth,
    );
  }
}
