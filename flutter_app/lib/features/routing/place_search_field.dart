import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/place.dart';
import '../../models/route.dart';
import '../../services/places/places_service.dart';

/// Place search card and autocomplete input matching React PlaceSearchInput.tsx.
class PlaceSearchField extends StatefulWidget {
  final RouteEndpointType endpointType;
  final String label;
  final String tagLetter;
  final String placeholder;
  final SelectedLocation? value;
  final ValueChanged<SelectedLocation> onSelect;
  final VoidCallback onClear;
  final bool isActiveTarget;
  final VoidCallback onActivateTarget;

  const PlaceSearchField({
    super.key,
    required this.endpointType,
    required this.label,
    required this.tagLetter,
    required this.placeholder,
    required this.value,
    required this.onSelect,
    required this.onClear,
    required this.isActiveTarget,
    required this.onActivateTarget,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late final PlacesService _placesService;

  Timer? _debounceTimer;
  bool _isLoading = false;
  List<PlaceSuggestion> _remoteSuggestions = [];
  List<PlaceSuggestion> _fallbackSuggestions = [];
  bool _isCuratedFallback = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.label ?? '');
    _placesService = PlacesService();

    _focusNode.addListener(() {
      setState(() {
        if (_focusNode.hasFocus && _controller.text.isEmpty) {
          _showDropdown = true;
          _fallbackSuggestions = popularLandmarks.map((l) => l.toSuggestion()).toList();
          _isCuratedFallback = true;
        } else if (!_focusNode.hasFocus) {
          _showDropdown = false;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value != null && widget.value!.label != _controller.text) {
        _controller.text = widget.value!.label;
      } else if (widget.value == null) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();

    if (clean.length < 2) {
      setState(() {
        _isLoading = false;
        _remoteSuggestions = [];
        if (clean.isEmpty && _focusNode.hasFocus) {
          _fallbackSuggestions = popularLandmarks.map((l) => l.toSuggestion()).toList();
          _isCuratedFallback = true;
          _showDropdown = true;
        } else {
          _showDropdown = false;
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await _placesService.searchPlaces(clean);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _remoteSuggestions = res.results;
            _isCuratedFallback = false;
          });
        }
      } catch (err) {
        if (mounted) {
          // Fallback to local curated Navi Mumbai landmarks
          final localMatches = searchCuratedLandmarks(clean, limit: 4);
          setState(() {
            _isLoading = false;
            _remoteSuggestions = [];
            _fallbackSuggestions = localMatches.map((l) => l.toSuggestion()).toList();
            _isCuratedFallback = true;
          });
        }
      }
    });
  }

  void _selectPlace(PlaceSuggestion place) {
    widget.onSelect(
      SelectedLocation(
        label: place.name,
        coordinates: place.coordinates,
        placeId: place.id,
        formattedAddress: place.formattedAddress,
        source: place.source,
        category: place.category,
        locality: place.locality,
        landmarkId: place.source == 'curated' ? place.id : null,
      ),
    );
    _controller.text = place.name;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
  }

  void _clearInput() {
    _controller.clear();
    widget.onClear();
    setState(() {
      _showDropdown = false;
      _remoteSuggestions = [];
      _fallbackSuggestions = [];
    });
  }

  Color get _badgeColor => widget.endpointType == RouteEndpointType.origin
      ? AppColors.originGreen
      : AppColors.destinationPurple;

  @override
  Widget build(BuildContext context) {
    final activeSuggestions = _remoteSuggestions.isNotEmpty
        ? _remoteSuggestions
        : _fallbackSuggestions;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActiveTarget ? AppColors.amber : AppColors.borderSubtle,
          width: widget.isActiveTarget ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Badge & "Pick on Map" Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.tagLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onActivateTarget,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isActiveTarget
                        ? AppColors.amberLight.withAlpha(51)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isActiveTarget ? AppColors.amber : AppColors.borderInteractive,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 13,
                        color: widget.isActiveTarget ? AppColors.amberText : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isActiveTarget ? 'Target Active' : 'Pick on Map',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.isActiveTarget ? AppColors.amberText : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search Text Input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.placeholder,
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: _clearInput,
                    ),
                ],
              ),
            ),
          ),

          // Autocomplete Dropdown List
          if (_showDropdown) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      _controller.text.isEmpty
                          ? 'Popular Navi Mumbai Transit Hubs'
                          : _isCuratedFallback
                              ? 'Curated Local Landmarks (Fallback)'
                              : 'Search Results (Geoapify)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          'Searching places via Geoapify...',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else if (activeSuggestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'No matching places found. Tap "Pick on Map" to pin coordinates.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    )
                  else
                    ...activeSuggestions.map((place) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        leading: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                        title: Text(
                          place.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          place.formattedAddress,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: place.source == 'curated'
                                ? AppColors.amberLight.withAlpha(38)
                                : AppColors.routePrimary.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            place.source == 'curated' ? 'Curated' : 'Geoapify',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: place.source == 'curated' ? AppColors.amberText : AppColors.routePrimary,
                            ),
                          ),
                        ),
                        onTap: () => _selectPlace(place),
                      );
                    }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Footer: Coordinate Info & Source Tag
          if (widget.value != null)
            Row(
              children: [
                Text(
                  '${widget.value!.coordinates.latitude.toStringAsFixed(4)}° N, ${widget.value!.coordinates.longitude.toStringAsFixed(4)}° E',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    widget.value!.source == 'geoapify'
                        ? 'Geoapify Place'
                        : widget.value!.source == 'curated'
                            ? 'Curated Landmark'
                            : 'Pinned Coordinate',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            )
          else
            Text(
              widget.isActiveTarget
                  ? '🎯 Tap map to set ${widget.label.toLowerCase()} coordinates'
                  : 'Type to search or tap "Pick on Map"',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
