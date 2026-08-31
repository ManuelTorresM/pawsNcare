import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../theme/app_theme.dart';

/// Real-world Address Autocomplete & Location Search Widget powered by
/// `flutter_typeahead` and OpenStreetMap Nominatim search engine.
class TypeAheadAddressField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final String label;

  const TypeAheadAddressField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    this.label = 'Address / Location',
  });

  @override
  State<TypeAheadAddressField> createState() => _TypeAheadAddressFieldState();
}

class _TypeAheadAddressFieldState extends State<TypeAheadAddressField> {
  static const List<Map<String, String>> _fallbackSuggestions = [
    {
      'displayName': '742 Evergreen Terrace, Springfield, OR 97477, USA',
      'street': '742 Evergreen Terrace',
      'city': 'Springfield',
      'state': 'Oregon',
      'country': 'United States',
    },
    {
      'displayName': '123 Main St, Apt 4B, New York, NY 10001, USA',
      'street': '123 Main St',
      'city': 'New York',
      'state': 'New York',
      'country': 'United States',
    },
    {
      'displayName': 'Via Roma 10, 00187 Roma, RM, Italy',
      'street': 'Via Roma 10',
      'city': 'Roma',
      'state': 'Lazio',
      'country': 'Italy',
    },
    {
      'displayName': 'Av. Corrientes 1234, C1043 CABA, Argentina',
      'street': 'Av. Corrientes 1234',
      'city': 'Buenos Aires',
      'state': 'CABA',
      'country': 'Argentina',
    },
    {
      'displayName': '459 Ocean Avenue, Santa Monica, CA 90402, USA',
      'street': '459 Ocean Avenue',
      'city': 'Santa Monica',
      'state': 'California',
      'country': 'United States',
    },
  ];

  Future<List<Map<String, String>>> _fetchRealAddressSuggestions(
    String query,
  ) async {
    if (query.trim().length < 3) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=6',
      );

      final request = await HttpClient().getUrl(url);
      request.headers.set('User-Agent', 'PawsNCareApp/1.0 (flutter_typeahead)');

      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List<dynamic> results = jsonDecode(body);

        final suggestions = <Map<String, String>>[];
        for (final item in results) {
          final address = item['address'] ?? {};
          final road =
              address['road'] ?? address['pedestrian'] ?? address['house_number'] ?? '';
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              '';
          final state = address['state'] ?? address['region'] ?? '';
          final country = address['country'] ?? '';
          final displayName = item['display_name'] ?? '';

          suggestions.add({
            'displayName': displayName,
            'street': road.isNotEmpty ? road.toString() : query,
            'city': city.toString(),
            'state': state.toString(),
            'country': country.toString(),
          });
        }
        if (suggestions.isNotEmpty) return suggestions;
      }
    } catch (_) {}

    // Fallback to local structured pattern search if offline or timeout
    final lowerQuery = query.toLowerCase();
    return _fallbackSuggestions.where((item) {
      final name = item['displayName']!.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final cardBg =
        widget.isDark
            ? AppTheme.darkSurface
            : AppTheme.surfaceContainerLowest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: widget.textSecondary,
              ),
            ),
            if (widget.enabled)
              Text(
                'Type Street, City, State or Country',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: primaryColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TypeAheadField<Map<String, String>>(
          controller: widget.controller,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search street, city, province, country...',
                hintStyle: TextStyle(
                  color: widget.textSecondary.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: primaryColor,
                ),
                suffixIcon:
                    widget.enabled && widget.controller.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: widget.textSecondary,
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() {});
                          },
                        )
                        : null,
                filled: true,
                fillColor:
                    widget.enabled
                        ? (widget.isDark
                            ? const Color(0xFF2C2A29)
                            : Colors.white)
                        : Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        widget.isDark
                            ? const Color(0xFF383634)
                            : AppTheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        widget.isDark
                            ? const Color(0xFF383634)
                            : AppTheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            if (!widget.enabled || pattern.trim().isEmpty) return [];
            return await _fetchRealAddressSuggestions(pattern);
          },
          itemBuilder: (context, suggestion) {
            final displayName = suggestion['displayName'] ?? '';
            final city = suggestion['city'] ?? '';
            final state = suggestion['state'] ?? '';
            final country = suggestion['country'] ?? '';

            final locationDetails = [
              city,
              state,
              country,
            ].where((s) => s.isNotEmpty).join(', ');

            return ListTile(
              tileColor: cardBg,
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.place, size: 16, color: primaryColor),
              ),
              title: Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.textPrimary,
                ),
              ),
              subtitle:
                  locationDetails.isNotEmpty
                      ? Text(
                        'Details: $locationDetails',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.textSecondary,
                        ),
                      )
                      : null,
            );
          },
          onSelected: (suggestion) {
            widget.controller.text = suggestion['displayName'] ?? '';
          },
        ),
      ],
    );
  }
}
