enum WidgetType {
  mainBanner,
  icons,
  specialCollection,
  productList,
  categoryHighlight,
  galleryCard,
  banner,
}

extension WidgetTypeExtension on WidgetType {
  int get value {
    switch (this) {
      case WidgetType.mainBanner:
        return 1;
      case WidgetType.icons:
        return 2;
      case WidgetType.specialCollection:
        return 4;
      case WidgetType.productList:
        return 5;
      case WidgetType.categoryHighlight:
        return 6;
      case WidgetType.galleryCard:
        return 7;
      case WidgetType.banner:
        return 8;
    }
  }
}
