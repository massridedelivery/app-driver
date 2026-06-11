extension StringTruncation on String {
  String truncateTo(int maxLength) {
    if (length <= maxLength) {
      return this;
    }
    return substring(0, maxLength);
  }
}

extension StringBlinding on String {
  String blindName() {
    if (isEmpty) return this;
    
    final parts = split(RegExp(r'\s+'));
    final maskedParts = parts.map((part) {
      String prefix = "";
      String content = part;
      if (part.startsWith('(') && part.contains(')')) {
        final idx = part.indexOf(')');
        prefix = part.substring(0, idx + 1);
        content = part.substring(idx + 1);
      }
      
      if (content.length <= 2) {
        return prefix + content + '*' * content.length;
      }
      
      final visible = content.substring(0, 2);
      final maskedLength = content.length - 2;
      return prefix + visible + '*' * (maskedLength > 6 ? 6 : maskedLength);
    }).toList();
    
    return maskedParts.join(' ');
  }

  String blindPhone() {
    if (isEmpty) return this;
    
    final cleaned = replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+66')) {
      if (cleaned.length >= 10) {
        final start = cleaned.substring(0, 5);
        final end = cleaned.substring(cleaned.length - 4);
        return "${start.substring(0, 3)} ${start.substring(3)}***$end";
      }
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length >= 9) {
        final start = cleaned.substring(0, 3);
        final end = cleaned.substring(cleaned.length - 4);
        return "$start***$end";
      }
    }
    
    if (length <= 4) return this;
    return substring(0, 2) + '*' * (length - 4) + substring(length - 2);
  }

  String blindPlate() {
    if (isEmpty) return this;
    if (length <= 3) {
      return substring(0, 1) + '*' * (length - 1);
    }
    final visible = substring(0, 3);
    return visible + '*' * (length - 3);
  }

  String blindEmailOrUuid() {
    if (isEmpty) return this;
    
    if (contains('@')) {
      final parts = split('@');
      final local = parts[0];
      final domain = parts[1];
      if (local.length <= 2) {
        return "${local[0]}*@$domain";
      }
      return "${local.substring(0, 2)}***@$domain";
    }
    
    if (length <= 8) {
      return substring(0, 2) + '*' * (length - 4) + substring(length - 2);
    }
    return "${substring(0, 4)}***${substring(length - 4)}";
  }
}
