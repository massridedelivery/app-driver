/// Query parameters for GET /api/driver/earnings/transactions
class TransactionQuery {
  final int limit;
  final int offset;
  final String? type;
  final String? status;
  final String? startDate; // YYYY-MM-DD
  final String? endDate;   // YYYY-MM-DD

  const TransactionQuery({
    this.limit = 20,
    this.offset = 0,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'limit': limit,
      'offset': offset,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
  }

  TransactionQuery copyWith({
    int? limit,
    int? offset,
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) {
    return TransactionQuery(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Returns the next page query (increments offset by limit).
  TransactionQuery nextPage() => copyWith(offset: offset + limit);

  /// Returns to the first page.
  TransactionQuery firstPage() => copyWith(offset: 0);
}
